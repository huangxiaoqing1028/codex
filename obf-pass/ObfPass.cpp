#include "llvm/IR/Constants.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/PassManager.h"
#include "llvm/Passes/PassBuilder.h"
#if __has_include("llvm/Plugins/PassPlugin.h")
#include "llvm/Plugins/PassPlugin.h"
#else
#include "llvm/Passes/PassPlugin.h"
#endif
#include "llvm/ADT/Hashing.h"
#include "llvm/ADT/SmallVector.h"

using namespace llvm;

namespace {
class SimpleObfPass : public PassInfoMixin<SimpleObfPass> {
  static Value *createMBAAdd(IRBuilder<> &Builder, Value *A, Value *B) {
    // A + B == (A ^ B) + ((A & B) << 1)
    Value *Xor = Builder.CreateXor(A, B, "obf.mba.xor");
    Value *And = Builder.CreateAnd(A, B, "obf.mba.and");
    Value *Carry = Builder.CreateShl(
        And, ConstantInt::get(cast<IntegerType>(A->getType()), 1),
        "obf.mba.carry");
    return Builder.CreateAdd(Xor, Carry, "obf.mba.add");
  }

  static Value *createMBAXor(IRBuilder<> &Builder, Value *A, Value *B) {
    // A ^ B == (A | B) - (A & B)
    Value *Or = Builder.CreateOr(A, B, "obf.mba.or");
    Value *And = Builder.CreateAnd(A, B, "obf.mba.and");
    return Builder.CreateSub(Or, And, "obf.mba.xor");
  }

  static Value *createObfuscatedConst(IRBuilder<> &Builder, APInt C,
                                      uint64_t Seed) {
    // C == (C ^ K) ^ K
    APInt K = APInt(C.getBitWidth(), Seed).zextOrTrunc(C.getBitWidth());
    if (K.isZero())
      K = APInt(C.getBitWidth(), 0xA5A5A5A5ULL).zextOrTrunc(C.getBitWidth());
    Constant *CK = ConstantInt::get(Builder.getContext(), K);
    Constant *Masked = ConstantInt::get(Builder.getContext(), C ^ K);
    Value *Tmp = Builder.CreateXor(Masked, CK, "obf.const.masked");
    return Builder.CreateXor(Tmp, CK, "obf.const");
  }

public:
  PreservedAnalyses run(Function &F, FunctionAnalysisManager &) {
    bool Changed = false;
    SmallVector<BinaryOperator *, 32> Worklist;

    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *BinOp = dyn_cast<BinaryOperator>(&I);
        if (!BinOp) {
          continue;
        }

        if (BinOp->getOpcode() != Instruction::Add &&
            BinOp->getOpcode() != Instruction::Sub &&
            BinOp->getOpcode() != Instruction::Xor) {
          continue;
        }

        if (!BinOp->getType()->isIntegerTy()) {
          continue;
        }

        Worklist.push_back(BinOp);
      }
    }

    for (BinaryOperator *BinOp : Worklist) {
      IRBuilder<> Builder(BinOp);
      Value *LHS = BinOp->getOperand(0);
      Value *RHS = BinOp->getOperand(1);

      uint64_t Seed = hash_value(F.getName()) ^ hash_value(BinOp->getOpcode()) ^
                      hash_value(BinOp->getDebugLoc().getLine());

      if (auto *CI = dyn_cast<ConstantInt>(RHS)) {
        RHS = createObfuscatedConst(Builder, CI->getValue(), Seed);
      }

      Value *NewValue = nullptr;
      if (BinOp->getOpcode() == Instruction::Add) {
        if ((Seed & 1) == 0) {
          Value *NegRHS = Builder.CreateNeg(RHS, "obf.negrhs");
          NewValue = Builder.CreateSub(LHS, NegRHS, "obf.add2sub");
        } else {
          NewValue = createMBAAdd(Builder, LHS, RHS);
        }
      } else if (BinOp->getOpcode() == Instruction::Sub) {
        if ((Seed & 1) == 0) {
          Value *NegRHS = Builder.CreateNeg(RHS, "obf.negrhs");
          NewValue = Builder.CreateAdd(LHS, NegRHS, "obf.sub2add");
        } else {
          Value *NegRHS = Builder.CreateNeg(RHS, "obf.negrhs");
          NewValue = createMBAAdd(Builder, LHS, NegRHS);
        }
      } else if (BinOp->getOpcode() == Instruction::Xor) {
        if ((Seed & 1) == 0) {
          NewValue = createMBAXor(Builder, LHS, RHS);
        } else {
          Value *And = Builder.CreateAnd(LHS, RHS, "obf.xor.and");
          Value *TwoAnd = Builder.CreateShl(
              And, ConstantInt::get(cast<IntegerType>(LHS->getType()), 1),
              "obf.xor.twiceand");
          Value *Add = Builder.CreateAdd(LHS, RHS, "obf.xor.add");
          NewValue = Builder.CreateSub(Add, TwoAnd, "obf.xor.alt");
        }
      }

      if (NewValue) {
        BinOp->replaceAllUsesWith(NewValue);
        BinOp->eraseFromParent();
        Changed = true;
      }
    }

    return Changed ? PreservedAnalyses::none() : PreservedAnalyses::all();
  }
};
} // namespace

extern "C" LLVM_ATTRIBUTE_WEAK ::llvm::PassPluginLibraryInfo
llvmGetPassPluginInfo() {
  return {LLVM_PLUGIN_API_VERSION, "SimpleObfPass", LLVM_VERSION_STRING,
          [](PassBuilder &PB) {
            PB.registerPipelineStartEPCallback(
                [](ModulePassManager &MPM, OptimizationLevel) {
                  FunctionPassManager FPM;
                  FPM.addPass(SimpleObfPass());
                  MPM.addPass(createModuleToFunctionPassAdaptor(std::move(FPM)));
                });

            PB.registerPipelineParsingCallback(
                [](StringRef Name, FunctionPassManager &FPM,
                   ArrayRef<PassBuilder::PipelineElement>) {
                  if (Name == "simple-obf") {
                    FPM.addPass(SimpleObfPass());
                    return true;
                  }
                  return false;
                });
          }};
}
