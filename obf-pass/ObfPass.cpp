#include "llvm/IR/Constants.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/GlobalVariable.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/PassManager.h"
#include "llvm/Passes/PassBuilder.h"
#if __has_include("llvm/Plugins/PassPlugin.h")
#include "llvm/Plugins/PassPlugin.h"
#else
#include "llvm/Passes/PassPlugin.h"
#endif
#include "llvm/ADT/Hashing.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/Transforms/Utils/ModuleUtils.h"

using namespace llvm;

namespace {
class StringEncryptionPass : public PassInfoMixin<StringEncryptionPass> {
public:
  PreservedAnalyses run(Module &M, ModuleAnalysisManager &) {
    LLVMContext &Ctx = M.getContext();
    SmallVector<std::tuple<GlobalVariable *, uint8_t, uint64_t>, 32> Targets;

    for (GlobalVariable &GV : M.globals()) {
      if (!GV.hasInitializer())
        continue;
      if (!GV.getValueType()->isArrayTy())
        continue;

      auto *Init = dyn_cast<ConstantDataSequential>(GV.getInitializer());
      if (!Init || !Init->isString())
        continue;
      if (GV.getName().startswith("__obf_"))
        continue;

      StringRef Raw = Init->getRawDataValues();
      if (Raw.empty())
        continue;

      uint8_t Key = static_cast<uint8_t>((hash_value(GV.getName()) & 0xFFU) | 1U);
      SmallVector<uint8_t, 128> Encoded;
      Encoded.reserve(Raw.size());
      for (char C : Raw)
        Encoded.push_back(static_cast<uint8_t>(C) ^ Key);

      GV.setInitializer(ConstantDataArray::get(Ctx, Encoded));
      GV.setConstant(false);
      Targets.emplace_back(&GV, Key, static_cast<uint64_t>(Raw.size()));
    }

    if (Targets.empty())
      return PreservedAnalyses::all();

    FunctionCallee DecodeDecl = M.getOrInsertFunction(
        "__obf_decode_all_strings",
        FunctionType::get(Type::getVoidTy(Ctx), false));
    Function *DecodeFn = cast<Function>(DecodeDecl.getCallee());
    DecodeFn->setLinkage(GlobalValue::InternalLinkage);

    if (!DecodeFn->empty())
      DecodeFn->deleteBody();

    BasicBlock *Entry = BasicBlock::Create(Ctx, "entry", DecodeFn);
    IRBuilder<> Builder(Entry);

    for (auto &[GV, Key, Len] : Targets) {
      Value *Base = Builder.CreateConstInBoundsGEP2_32(
          GV->getValueType(), GV, 0, 0, "obf.str.base");
      for (uint64_t I = 0; I < Len; ++I) {
        Value *Ptr =
            Builder.CreateInBoundsGEP(Builder.getInt8Ty(), Base, Builder.getInt64(I));
        LoadInst *B = Builder.CreateLoad(Builder.getInt8Ty(), Ptr, "obf.str.enc");
        Value *Dec = Builder.CreateXor(B, Builder.getInt8(Key), "obf.str.dec");
        Builder.CreateStore(Dec, Ptr);
      }
    }

    Builder.CreateRetVoid();
    appendToGlobalCtors(M, DecodeFn, 65535);
    return PreservedAnalyses::none();
  }
};

class SimpleObfPass : public PassInfoMixin<SimpleObfPass> {
  static Value *createOpaqueTrue(IRBuilder<> &Builder, Value *Cond) {
    // cond == (((zext(cond) ^ 1) == 0))
    Value *AsInt = Builder.CreateZExt(Cond, Builder.getInt8Ty(), "obf.cond.zext");
    Value *Flip = Builder.CreateXor(AsInt, Builder.getInt8(1), "obf.cond.flip");
    return Builder.CreateICmpEQ(Flip, Builder.getInt8(0), "obf.cond.opaque");
  }

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

  static bool indirectifyDirectCalls(Function &F) {
    bool Changed = false;
    SmallVector<CallInst *, 16> Calls;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *CI = dyn_cast<CallInst>(&I);
        if (!CI)
          continue;
        if (CI->isInlineAsm())
          continue;
        Function *Callee = CI->getCalledFunction();
        if (!Callee || Callee->isIntrinsic())
          continue;
        Calls.push_back(CI);
      }
    }

    for (CallInst *CI : Calls) {
      IRBuilder<> Builder(CI);
      Value *Callee = CI->getCalledOperand();
      AllocaInst *Slot = new AllocaInst(Callee->getType(), 0, "obf.callee.slot",
                                        &*F.getEntryBlock().getFirstInsertionPt());
      Builder.CreateStore(Callee, Slot);
      Value *Loaded = Builder.CreateLoad(Callee->getType(), Slot, "obf.callee");
      CI->setCalledOperand(Loaded);
      Changed = true;
    }
    return Changed;
  }

  static bool splitBasicBlocks(Function &F) {
    bool Changed = false;
    SmallVector<BasicBlock *, 16> ToSplit;
    for (BasicBlock &BB : F) {
      if (BB.getTerminator()->getNumSuccessors() == 0)
        continue;
      if (BB.size() < 6)
        continue;
      ToSplit.push_back(&BB);
    }

    for (BasicBlock *BB : ToSplit) {
      auto It = BB->getFirstInsertionPt();
      if (It == BB->end())
        continue;
      Instruction *SplitPt = &*It;
      for (int i = 0; i < 2 && SplitPt; ++i)
        SplitPt = SplitPt->getNextNode();
      if (!SplitPt || SplitPt == BB->getTerminator())
        continue;
      BB->splitBasicBlock(SplitPt, "obf.split");
      Changed = true;
    }
    return Changed;
  }

  static bool perturbBranches(Function &F) {
    bool Changed = false;
    SmallVector<BranchInst *, 16> Branches;
    for (BasicBlock &BB : F) {
      if (auto *BI = dyn_cast<BranchInst>(BB.getTerminator()))
        Branches.push_back(BI);
    }

    for (BranchInst *BI : Branches) {
      IRBuilder<> Builder(BI);
      if (BI->isConditional()) {
        Value *Cond = BI->getCondition();
        Value *ObfCond = createOpaqueTrue(Builder, Cond);
        BI->setCondition(ObfCond);
        Changed = true;
        continue;
      }

      BasicBlock *Src = BI->getParent();
      BasicBlock *Target = BI->getSuccessor(0);
      Function *Fn = Src->getParent();
      BasicBlock *Bogus = BasicBlock::Create(Fn->getContext(), "obf.bogus", Fn, Target);
      IRBuilder<> BogusBuilder(Bogus);
      BogusBuilder.CreateUnreachable();

      Value *Opaque = createOpaqueTrue(Builder, Builder.getTrue());
      BranchInst::Create(Target, Bogus, Opaque, BI);
      BI->eraseFromParent();
      Changed = true;
    }
    return Changed;
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

    // Additional control/data obfuscation layers.
    Changed |= indirectifyDirectCalls(F);
    Changed |= splitBasicBlocks(F);
    Changed |= perturbBranches(F);

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
                  MPM.addPass(StringEncryptionPass());
                  FunctionPassManager FPM;
                  FPM.addPass(SimpleObfPass());
                  MPM.addPass(createModuleToFunctionPassAdaptor(std::move(FPM)));
                });

            PB.registerPipelineParsingCallback(
                [](StringRef Name, ModulePassManager &MPM,
                   ArrayRef<PassBuilder::PipelineElement>) {
                  if (Name == "string-obf") {
                    MPM.addPass(StringEncryptionPass());
                    return true;
                  }
                  return false;
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
