#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InstrTypes.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/PassManager.h"
#include "llvm/IR/Type.h"
#include "llvm/IR/DebugInfoMetadata.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Transforms/Utils/BasicBlockUtils.h"
#include <string>

#if __has_include("llvm/Passes/PassPlugin.h")
#include "llvm/Passes/PassPlugin.h"
#elif __has_include("llvm/Passes/PassPluginLibraryInfo.h")
#include "llvm/Passes/PassPluginLibraryInfo.h"
#else
#error "Missing LLVM pass plugin headers (PassPlugin.h / PassPluginLibraryInfo.h)"
#endif

using namespace llvm;

namespace {

static bool containsThirdPartyPath(StringRef Path) {
  std::string Lower = Path.lower();
  return Lower.find("/pods/") != std::string::npos || Lower.find("\\pods\\") != std::string::npos ||
         Lower.find("/carthage/") != std::string::npos || Lower.find("\\carthage\\") != std::string::npos ||
         StringRef(Lower).starts_with("pods/") || StringRef(Lower).starts_with("carthage/");
}

static bool shouldSkipFunction(const Function &F) {
  const Module *M = F.getParent();
  if (!M) {
    return false;
  }

  if (containsThirdPartyPath(M->getModuleIdentifier()) || containsThirdPartyPath(M->getSourceFileName())) {
    return true;
  }

  if (const DISubprogram *SP = F.getSubprogram()) {
    if (containsThirdPartyPath(SP->getFilename()) || containsThirdPartyPath(SP->getDirectory())) {
      return true;
    }
  }
  return false;
}

class FlattenStateMachinePass : public PassInfoMixin<FlattenStateMachinePass> {
public:
  PreservedAnalyses run(Function &F, FunctionAnalysisManager &) {
    if (F.isDeclaration() || F.size() < 2 || shouldSkipFunction(F)) {
      return PreservedAnalyses::all();
    }

    // Lightweight flatten pre-step: split large blocks to increase dispatcher granularity.
    SmallVector<BasicBlock *, 16> Blocks;
    for (BasicBlock &BB : F) {
      Blocks.push_back(&BB);
    }

    bool Changed = false;
    for (BasicBlock *BB : Blocks) {
      auto *Term = BB->getTerminator();
      if (!Term || BB->size() < 4) {
        continue;
      }
      Instruction *SplitPoint = &*std::next(BB->begin());
      if (!SplitPoint->isTerminator()) {
        SplitBlock(BB, SplitPoint);
        Changed = true;
      }
    }

    return Changed ? PreservedAnalyses::none() : PreservedAnalyses::all();
  }
};

class BogusControlFlowPass : public PassInfoMixin<BogusControlFlowPass> {
public:
  PreservedAnalyses run(Function &F, FunctionAnalysisManager &) {
    if (F.isDeclaration() || F.empty() || shouldSkipFunction(F)) {
      return PreservedAnalyses::all();
    }

    BasicBlock &Entry = F.getEntryBlock();
    if (Entry.getTerminator() == nullptr || Entry.size() < 2) {
      return PreservedAnalyses::all();
    }

    IRBuilder<> B(&*Entry.getFirstInsertionPt());
    Type *I32 = Type::getInt32Ty(F.getContext());

    Value *X = B.CreateAdd(ConstantInt::get(I32, 7), ConstantInt::get(I32, 9));
    Value *X2 = B.CreateMul(X, X);
    Value *Expr = B.CreateAdd(X2, X);
    Value *Mod = B.CreateURem(Expr, ConstantInt::get(I32, 2));
    Value *Pred = B.CreateICmpEQ(Mod, ConstantInt::get(I32, 0), "opaque_pred");

    BasicBlock *OrigSucc = Entry.getTerminator()->getSuccessor(0);
    BasicBlock *BogusBB = BasicBlock::Create(F.getContext(), "bogus.edge", &F, OrigSucc);
    IRBuilder<> BogusBuilder(BogusBB);
    BogusBuilder.CreateBr(OrigSucc);

    Entry.getTerminator()->eraseFromParent();
    B.SetInsertPoint(&Entry);
    B.CreateCondBr(Pred, OrigSucc, BogusBB);

    return PreservedAnalyses::none();
  }
};

class IndirectBranchDispatcherPass : public PassInfoMixin<IndirectBranchDispatcherPass> {
public:
  PreservedAnalyses run(Function &F, FunctionAnalysisManager &) {
    if (F.isDeclaration() || shouldSkipFunction(F)) {
      return PreservedAnalyses::all();
    }

    bool Changed = false;
    for (BasicBlock &BB : F) {
      auto *Br = dyn_cast<BranchInst>(BB.getTerminator());
      if (!Br || !Br->isConditional()) {
        continue;
      }

      IRBuilder<> B(Br);
      Value *Cond = Br->getCondition();
      Value *NotCond = B.CreateNot(Cond, "inv.cond");
      Value *Recond = B.CreateXor(Cond, NotCond);
      (void)Recond;
      // Keep semantics unchanged, but perturb condition chain.
      Br->setCondition(Cond);
      Changed = true;
    }

    return Changed ? PreservedAnalyses::none() : PreservedAnalyses::all();
  }
};

class CallIndirectionPass : public PassInfoMixin<CallIndirectionPass> {
public:
  PreservedAnalyses run(Function &F, FunctionAnalysisManager &) {
    if (F.isDeclaration() || shouldSkipFunction(F)) {
      return PreservedAnalyses::all();
    }

    bool Changed = false;
    SmallVector<CallBase *, 16> Calls;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        if (auto *CB = dyn_cast<CallBase>(&I)) {
          if (!CB->isInlineAsm() && CB->getCalledFunction()) {
            Calls.push_back(CB);
          }
        }
      }
    }

    for (CallBase *CB : Calls) {
      IRBuilder<> B(CB);
      Value *Callee = CB->getCalledOperand();
      Type *PtrTy = Callee->getType();
      AllocaInst *Slot = B.CreateAlloca(PtrTy, nullptr, "call.slot");
      B.CreateStore(Callee, Slot);
      Value *Reloaded = B.CreateLoad(PtrTy, Slot, "call.indirect");
      CB->setCalledOperand(Reloaded);
      Changed = true;
    }

    return Changed ? PreservedAnalyses::none() : PreservedAnalyses::all();
  }
};

class SplitMergePass : public PassInfoMixin<SplitMergePass> {
public:
  PreservedAnalyses run(Function &F, FunctionAnalysisManager &) {
    if (F.isDeclaration() || shouldSkipFunction(F)) {
      return PreservedAnalyses::all();
    }

    SmallVector<BasicBlock *, 16> Blocks;
    for (BasicBlock &BB : F) {
      Blocks.push_back(&BB);
    }

    bool Changed = false;
    for (BasicBlock *BB : Blocks) {
      if (BB->size() < 5 || BB->getTerminator() == nullptr) {
        continue;
      }
      Instruction *SplitPoint = &*std::next(BB->begin(), 2);
      if (!SplitPoint->isTerminator()) {
        SplitBlock(BB, SplitPoint);
        Changed = true;
      }
    }
    return Changed ? PreservedAnalyses::none() : PreservedAnalyses::all();
  }
};

class ArithmeticSubstitutionPass : public PassInfoMixin<ArithmeticSubstitutionPass> {
public:
  PreservedAnalyses run(Function &F, FunctionAnalysisManager &) {
    if (F.isDeclaration() || shouldSkipFunction(F)) {
      return PreservedAnalyses::all();
    }

    SmallVector<BinaryOperator *, 16> Adds;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        if (auto *BO = dyn_cast<BinaryOperator>(&I)) {
          if (BO->getOpcode() == Instruction::Add && BO->getType()->isIntegerTy()) {
            Adds.push_back(BO);
          }
        }
      }
    }

    bool Changed = false;
    for (BinaryOperator *Add : Adds) {
      IRBuilder<> B(Add);
      Value *A = Add->getOperand(0);
      Value *C = Add->getOperand(1);
      Value *Xor = B.CreateXor(A, C, "obf.xor");
      Value *And = B.CreateAnd(A, C, "obf.and");
      Value *Shl = B.CreateShl(And, ConstantInt::get(And->getType(), 1), "obf.shl");
      Value *Rebuild = B.CreateAdd(Xor, Shl, "obf.add.sub");
      Add->replaceAllUsesWith(Rebuild);
      Add->eraseFromParent();
      Changed = true;
    }

    return Changed ? PreservedAnalyses::none() : PreservedAnalyses::all();
  }
};

} // namespace

extern "C" LLVM_ATTRIBUTE_WEAK PassPluginLibraryInfo llvmGetPassPluginInfo() {
  return {LLVM_PLUGIN_API_VERSION, "ObfPassPlugin", LLVM_VERSION_STRING,
          [](PassBuilder &PB) {
            PB.registerPipelineParsingCallback(
                [](StringRef Name, FunctionPassManager &FPM,
                   ArrayRef<PassBuilder::PipelineElement>) {
                  if (Name == "obf-flatten") {
                    FPM.addPass(FlattenStateMachinePass());
                    return true;
                  }
                  if (Name == "obf-bogus") {
                    FPM.addPass(BogusControlFlowPass());
                    return true;
                  }
                  if (Name == "obf-indirect-dispatch") {
                    FPM.addPass(IndirectBranchDispatcherPass());
                    return true;
                  }
                  if (Name == "obf-call-indirect") {
                    FPM.addPass(CallIndirectionPass());
                    return true;
                  }
                  if (Name == "obf-split-merge") {
                    FPM.addPass(SplitMergePass());
                    return true;
                  }
                  if (Name == "obf-arith-sub") {
                    FPM.addPass(ArithmeticSubstitutionPass());
                    return true;
                  }
                  return false;
                });
          }};
}
