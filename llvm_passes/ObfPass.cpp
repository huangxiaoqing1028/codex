#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/DenseMap.h"
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
#include <algorithm>
#include <cstdint>
#include <random>
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

static uint32_t functionSeed(const Function &F) {
  uint32_t H = 2166136261u;
  for (char C : F.getName()) {
    H ^= static_cast<uint8_t>(C);
    H *= 16777619u;
  }
  return H ? H : 1u;
}

static bool containsPHINodes(const Function &F) {
  for (const BasicBlock &BB : F) {
    if (isa<PHINode>(BB.begin())) {
      return true;
    }
  }
  return false;
}

class FlattenStateMachinePass : public PassInfoMixin<FlattenStateMachinePass> {
public:
  PreservedAnalyses run(Function &F, FunctionAnalysisManager &) {
    if (F.isDeclaration() || F.size() < 3 || shouldSkipFunction(F) || containsPHINodes(F)) {
      return PreservedAnalyses::all();
    }

    SmallVector<BasicBlock *, 32> Blocks;
    for (BasicBlock &BB : F) {
      if (&BB == &F.getEntryBlock()) {
        continue;
      }
      if (isa<ReturnInst>(BB.getTerminator())) {
        continue;
      }
      Blocks.push_back(&BB);
    }
    if (Blocks.size() < 2) {
      return PreservedAnalyses::all();
    }

    std::mt19937 Rng(functionSeed(F));
    std::shuffle(Blocks.begin(), Blocks.end(), Rng);

    LLVMContext &Ctx = F.getContext();
    Type *I32 = Type::getInt32Ty(Ctx);
    BasicBlock *Entry = &F.getEntryBlock();
    Instruction *EntryTerm = Entry->getTerminator();
    if (!EntryTerm) {
      return PreservedAnalyses::all();
    }

    IRBuilder<> EntryBuilder(EntryTerm);
    AllocaInst *State = EntryBuilder.CreateAlloca(I32, nullptr, "obf.state");

    DenseMap<BasicBlock *, uint32_t> StateMap;
    for (size_t I = 0; I < Blocks.size(); ++I) {
      StateMap[Blocks[I]] = static_cast<uint32_t>(I);
    }

    EntryBuilder.CreateStore(ConstantInt::get(I32, StateMap[Blocks.front()]), State);
    BasicBlock *Dispatcher = BasicBlock::Create(Ctx, "obf.dispatcher", &F);
    EntryTerm->eraseFromParent();
    BranchInst::Create(Dispatcher, Entry);

    IRBuilder<> DispatchBuilder(Dispatcher);
    Value *LoadedState = DispatchBuilder.CreateLoad(I32, State, "obf.state.ld");
    BasicBlock *NoiseA = BasicBlock::Create(Ctx, "obf.noise.a", &F);
    BasicBlock *NoiseB = BasicBlock::Create(Ctx, "obf.noise.b", &F);
    BasicBlock *DefaultCase = BasicBlock::Create(Ctx, "obf.default", &F);
    SwitchInst *Sw = DispatchBuilder.CreateSwitch(LoadedState, DefaultCase, Blocks.size());
    for (BasicBlock *BB : Blocks) {
      Sw->addCase(ConstantInt::get(I32, StateMap[BB]), BB);
    }

    IRBuilder<> NA(NoiseA);
    NA.CreateStore(ConstantInt::get(I32, StateMap[Blocks.front()]), State);
    NA.CreateBr(NoiseB);
    IRBuilder<> NB(NoiseB);
    NB.CreateBr(DefaultCase);
    IRBuilder<> Def(DefaultCase);
    Def.CreateBr(Dispatcher);

    bool Changed = true;
    for (BasicBlock *BB : Blocks) {
      TerminatorInst *Term = BB->getTerminator();
      if (!Term) {
        continue;
      }
      if (auto *Br = dyn_cast<BranchInst>(Term)) {
        IRBuilder<> B(Br);
        if (Br->isUnconditional()) {
          BasicBlock *Succ = Br->getSuccessor(0);
          auto It = StateMap.find(Succ);
          if (It != StateMap.end()) {
            B.CreateStore(ConstantInt::get(I32, It->second), State);
            Br->eraseFromParent();
            B.CreateBr(Dispatcher);
          }
          continue;
        }
        BasicBlock *TrueBB = BasicBlock::Create(Ctx, "obf.state.t", &F, Dispatcher);
        BasicBlock *FalseBB = BasicBlock::Create(Ctx, "obf.state.f", &F, Dispatcher);
        IRBuilder<> BT(TrueBB);
        IRBuilder<> BF(FalseBB);
        BasicBlock *TSucc = Br->getSuccessor(0);
        BasicBlock *FSucc = Br->getSuccessor(1);
        uint32_t TState = StateMap.count(TSucc) ? StateMap[TSucc] : StateMap[Blocks.front()];
        uint32_t FState = StateMap.count(FSucc) ? StateMap[FSucc] : StateMap[Blocks.front()];
        BT.CreateStore(ConstantInt::get(I32, TState), State);
        BT.CreateBr(Dispatcher);
        BF.CreateStore(ConstantInt::get(I32, FState), State);
        BF.CreateBr(Dispatcher);
        Value *Cond = Br->getCondition();
        Br->eraseFromParent();
        B.CreateCondBr(Cond, TrueBB, FalseBB);
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
    std::mt19937 Rng(functionSeed(F) ^ 0xB0B0u);
    uint32_t Mode = Rng() % 3;
    Value *Pred = nullptr;
    if (Mode == 0) {
      Value *X = B.CreateAdd(ConstantInt::get(I32, 7), ConstantInt::get(I32, 9));
      Value *X2 = B.CreateMul(X, X);
      Value *Expr = B.CreateAdd(X2, X);
      Value *Mod = B.CreateURem(Expr, ConstantInt::get(I32, 2));
      Pred = B.CreateICmpEQ(Mod, ConstantInt::get(I32, 0), "opaque_pred.mod");
    } else if (Mode == 1) {
      Value *Seed = ConstantInt::get(I32, static_cast<uint32_t>(functionSeed(F)));
      Value *L = B.CreateXor(Seed, ConstantInt::get(I32, 0x5A5A5A5A));
      Value *R = B.CreateXor(ConstantInt::get(I32, 0x5A5A5A5A), Seed);
      Pred = B.CreateICmpEQ(L, R, "opaque_pred.data");
    } else {
      Value *Dep = ConstantInt::get(I32, 0);
      if (!F.arg_empty() && F.arg_begin()->getType()->isIntegerTy()) {
        Dep = B.CreateZExtOrTrunc(&*F.arg_begin(), I32, "opaque.arg");
      }
      Value *T = B.CreateXor(Dep, ConstantInt::get(I32, 0x1234));
      Value *R = B.CreateXor(T, ConstantInt::get(I32, 0x1234));
      Pred = B.CreateICmpEQ(R, Dep, "opaque_pred.arg");
    }
    if (!Pred) {
      return PreservedAnalyses::all();
    }

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

      // Multi-level trampoline: slot0 -> slot1 -> table[index]
      AllocaInst *Slot0 = B.CreateAlloca(PtrTy, nullptr, "call.slot0");
      AllocaInst *Slot1 = B.CreateAlloca(PtrTy, nullptr, "call.slot1");
      B.CreateStore(Callee, Slot0);
      Value *Reload0 = B.CreateLoad(PtrTy, Slot0, "call.reload0");
      B.CreateStore(Reload0, Slot1);
      Value *Reload1 = B.CreateLoad(PtrTy, Slot1, "call.reload1");

      ArrayType *TblTy = ArrayType::get(PtrTy, 2);
      AllocaInst *Tbl = B.CreateAlloca(TblTy, nullptr, "call.tbl");
      Value *I0 = ConstantInt::get(Type::getInt32Ty(F.getContext()), 0);
      Value *I1 = ConstantInt::get(Type::getInt32Ty(F.getContext()), 1);
      Value *Ptr0 = B.CreateInBoundsGEP(TblTy, Tbl, {I0, I0});
      Value *Ptr1 = B.CreateInBoundsGEP(TblTy, Tbl, {I0, I1});
      B.CreateStore(Reload1, Ptr0);
      B.CreateStore(Callee, Ptr1);

      Value *IdxSeed = B.CreateXor(ConstantInt::get(Type::getInt32Ty(F.getContext()), functionSeed(F)),
                                   ConstantInt::get(Type::getInt32Ty(F.getContext()), 0x9E37));
      Value *Idx = B.CreateAnd(IdxSeed, ConstantInt::get(Type::getInt32Ty(F.getContext()), 1));
      Value *DynPtr = B.CreateInBoundsGEP(TblTy, Tbl, {I0, Idx}, "call.tbl.gep");
      Value *Reloaded = B.CreateLoad(PtrTy, DynPtr, "call.indirect");
      CB->setCalledOperand(B.CreateBitCast(Reloaded, PtrTy));
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
