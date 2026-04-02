#include "llvm/IR/Constants.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/GlobalVariable.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/PassManager.h"
#include "llvm/IR/Verifier.h"
#include "llvm/Passes/PassBuilder.h"
#if __has_include("llvm/Plugins/PassPlugin.h")
#include "llvm/Plugins/PassPlugin.h"
#else
#include "llvm/Passes/PassPlugin.h"
#endif
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/TargetParser/Triple.h"
#include "llvm/Transforms/Utils/ModuleUtils.h"
#include <algorithm>
#include <cstdlib>
#include <fstream>
#include <mutex>
#include <random>
#include <string>
#include <unordered_set>

using namespace llvm;

namespace {
static uint64_t fnv1a64(StringRef S) {
  uint64_t H = 1469598103934665603ULL;
  for (char C : S) {
    H ^= static_cast<unsigned char>(C);
    H *= 1099511628211ULL;
  }
  return H;
}

static uint64_t getEnvSeedOrDefault(StringRef Name, uint64_t Fallback) {
  if (const char *V = std::getenv("OBF_SEED")) {
    char *End = nullptr;
    unsigned long long Parsed = std::strtoull(V, &End, 10);
    if (End && *End == '\0')
      return static_cast<uint64_t>(Parsed);
  }
  return fnv1a64(Name) ^ Fallback;
}

static bool getEnvBoolOrDefault(const char *Name, bool Fallback) {
  const char *V = std::getenv(Name);
  if (!V || *V == '\0')
    return Fallback;
  return !(StringRef(V).equals_insensitive("0") ||
           StringRef(V).equals_insensitive("false") ||
           StringRef(V).equals_insensitive("off") ||
           StringRef(V).equals_insensitive("no"));
}

static bool shouldObfuscateFunction(const Function &F) {
  if (F.isDeclaration() || F.empty())
    return false;

  std::string Name = F.getName().str();

  if (Name.find("block_invoke") != std::string::npos ||
      Name.find("destruct") != std::string::npos ||
      Name.find("cxx") != std::string::npos ||
      Name.find(".cxx_") != std::string::npos ||
      Name.find("objc_msgSend") != std::string::npos ||
      StringRef(Name).starts_with("_dispatch") ||
      StringRef(Name).starts_with("objc_") ||
      StringRef(Name).starts_with("_objc_") ||
      StringRef(Name).starts_with("___lldb_unnamed_symbol")) {
    return false;
  }

  return true;
}

static void logPassHit(Function &F) {
  static std::mutex LogMu;
  static std::unordered_set<std::string> EmittedModules;

  Module *M = F.getParent();
  std::string ModuleName = "<unknown>";
  if (M) {
    if (!M->getSourceFileName().empty())
      ModuleName = M->getSourceFileName();
    else if (!M->getModuleIdentifier().empty())
      ModuleName = M->getModuleIdentifier();
  }

  std::lock_guard<std::mutex> Lock(LogMu);
  if (!EmittedModules.insert(ModuleName).second)
    return;

  if (getEnvBoolOrDefault("OBF_HIT_STDERR", true)) {
    errs() << "[simple-obf] HIT module: " << ModuleName << "\n";
  }

  if (const char *LogPath = std::getenv("OBF_HIT_LOG")) {
    std::ofstream OS(LogPath, std::ios::app);
    if (OS.is_open()) {
      OS << "HIT\t" << ModuleName << "\n";
    }
  }
}

static void verifyFunctionOrDie(Function &F, const char *Stage) {
  if (verifyFunction(F, &errs())) {
    errs() << "[SimpleObfPass] verifier failed after stage: "
           << Stage << " in function: " << F.getName() << "\n";
    report_fatal_error("Broken IR after SimpleObfPass");
  }
}

static void verifyModuleOrDie(Module &M, const char *Stage) {
  if (verifyModule(M, &errs())) {
    errs() << "[SimpleObfPass] module verifier failed after stage: "
           << Stage << "\n";
    report_fatal_error("Broken module after SimpleObfPass");
  }
}

class StringEncryptionPass : public PassInfoMixin<StringEncryptionPass> {
public:
  PreservedAnalyses run(Module &M, ModuleAnalysisManager &) {
    LLVMContext &Ctx = M.getContext();
    SmallVector<std::tuple<GlobalVariable *, uint8_t, uint64_t>, 32> Targets;

    for (GlobalVariable &GV : M.globals()) {
      if (!GV.hasInitializer())
        continue;
      if (!GV.isConstant())
        continue;
      if (!GV.hasPrivateLinkage())
        continue;
      if (GV.getSection().size() > 0)
        continue;
      if (!GV.hasGlobalUnnamedAddr())
        continue;
      if (!GV.getName().starts_with(".str"))
        continue;
      if (!GV.getValueType()->isArrayTy())
        continue;

      auto *Init = dyn_cast<ConstantDataSequential>(GV.getInitializer());
      if (!Init || !Init->isString())
        continue;
      if (GV.getName().starts_with("__obf_"))
        continue;

      StringRef Raw = Init->getRawDataValues();
      if (Raw.empty())
        continue;

      uint8_t Key = static_cast<uint8_t>((fnv1a64(GV.getName()) & 0xFFU) | 1U);
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
  static bool isObjCMethodName(StringRef Name) {
    return Name.starts_with("\x01-[") || Name.starts_with("\x01+[");
  }

  static bool isStructurallySafeForCFGObf(Function &F) {
    if (F.isDeclaration() || F.empty())
      return false;
    if (F.hasPersonalityFn())
      return false;

    StringRef N = F.getName();
    if (isObjCMethodName(N))
      return false;
    if (N.contains("block") || N.contains("Block"))
      return false;
    if (N.contains("destruct") || N.contains(".cxx_"))
      return false;
    if (N.starts_with("objc_") || N.starts_with("_objc_"))
      return false;
    if (N.starts_with("_dispatch"))
      return false;

    unsigned BBCount = 0;
    unsigned CallCount = 0;
    unsigned RetCount = 0;
    bool HasPHI = false;
    bool HasInvoke = false;
    bool HasSwitch = false;

    for (BasicBlock &BB : F) {
      ++BBCount;
      for (Instruction &I : BB) {
        if (isa<PHINode>(&I))
          HasPHI = true;
        if (isa<InvokeInst>(&I))
          HasInvoke = true;
        if (isa<SwitchInst>(&I))
          HasSwitch = true;
        if (isa<CallBase>(&I))
          ++CallCount;
        if (isa<ReturnInst>(&I))
          ++RetCount;
      }
    }

    if (HasPHI || HasInvoke || HasSwitch)
      return false;
    if (RetCount != 1)
      return false;
    if (BBCount < 3 || BBCount > 40)
      return false;
    if (CallCount > 12)
      return false;

    return true;
  }

  static bool canFlattenFunction(Function &F) {
    if (!isStructurallySafeForCFGObf(F))
      return false;

    BasicBlock *Entry = &F.getEntryBlock();
    auto *EntryBr = dyn_cast<BranchInst>(Entry->getTerminator());
    if (!EntryBr)
      return false;

    for (BasicBlock &BB : F) {
      auto *BI = dyn_cast<BranchInst>(BB.getTerminator());
      if (!BI)
        return false;
      for (unsigned I = 0; I < BI->getNumSuccessors(); ++I) {
        if (BI->getSuccessor(I) == Entry)
          return false;
      }
    }
    return true;
  }

  static bool canIndirectifyFunction(Function &F) {
    if (F.isDeclaration() || F.empty())
      return false;

    StringRef N = F.getName();
    if (isObjCMethodName(N))
      return false;
    if (N.contains("block") || N.contains("Block"))
      return false;
    if (N.contains("destruct") || N.contains(".cxx_"))
      return false;
    if (N.starts_with("objc_") || N.starts_with("_objc_"))
      return false;
    if (N.starts_with("_dispatch"))
      return false;

    return true;
  }

  static bool isSafeBlockForSplitOrBCF(BasicBlock &BB) {
    auto *Term = BB.getTerminator();
    if (!Term)
      return false;
    if (!isa<BranchInst>(Term))
      return false;
    if (BB.isEHPad() || BB.hasAddressTaken())
      return false;
    if (BB.size() < 8)
      return false;
    if (!BB.hasNPredecessors(1))
      return false;

    for (Instruction &I : BB) {
      if (isa<PHINode>(&I))
        return false;
      if (isa<InvokeInst>(&I))
        return false;
      if (isa<LandingPadInst>(&I))
        return false;
      if (isa<CallBase>(&I))
        return false;
    }

    return true;
  }

  static bool canUseExperimentalCFG(Function &F) {
    if (!isStructurallySafeForCFGObf(F))
      return false;

    for (BasicBlock &BB : F) {
      if (isSafeBlockForSplitOrBCF(BB))
        return true;
    }
    return false;
  }

  static Value *createOpaqueTrue(IRBuilder<> &Builder, Value *Cond) {
    Value *AsInt = Builder.CreateZExt(Cond, Builder.getInt8Ty(), "obf.cond.zext");
    Value *Flip = Builder.CreateXor(AsInt, Builder.getInt8(1), "obf.cond.flip");
    return Builder.CreateICmpEQ(Flip, Builder.getInt8(0), "obf.cond.opaque");
  }

  static Value *createMBAAdd(IRBuilder<> &Builder, Value *A, Value *B) {
    Value *Xor = Builder.CreateXor(A, B, "obf.mba.xor");
    Value *And = Builder.CreateAnd(A, B, "obf.mba.and");
    Value *Carry = Builder.CreateShl(
        And, ConstantInt::get(cast<IntegerType>(A->getType()), 1),
        "obf.mba.carry");
    return Builder.CreateAdd(Xor, Carry, "obf.mba.add");
  }

  static Value *createMBAXor(IRBuilder<> &Builder, Value *A, Value *B) {
    Value *Or = Builder.CreateOr(A, B, "obf.mba.or");
    Value *And = Builder.CreateAnd(A, B, "obf.mba.and");
    return Builder.CreateSub(Or, And, "obf.mba.xor");
  }

  static Value *createMBAAnd(IRBuilder<> &Builder, Value *A, Value *B) {
    Value *NotA = Builder.CreateNot(A, "obf.mba.not.a");
    Value *NotB = Builder.CreateNot(B, "obf.mba.not.b");
    Value *Or = Builder.CreateOr(NotA, NotB, "obf.mba.or");
    return Builder.CreateNot(Or, "obf.mba.and");
  }

  static Value *createMBAOr(IRBuilder<> &Builder, Value *A, Value *B) {
    Value *NotA = Builder.CreateNot(A, "obf.mba.not.a");
    Value *NotB = Builder.CreateNot(B, "obf.mba.not.b");
    Value *And = Builder.CreateAnd(NotA, NotB, "obf.mba.and");
    return Builder.CreateNot(And, "obf.mba.or");
  }

  static Value *createObfuscatedConst(IRBuilder<> &Builder, APInt C,
                                      uint64_t Seed) {
    APInt K = APInt(C.getBitWidth(), Seed, false, true);
    if (K.isZero())
      K = APInt(C.getBitWidth(), 0xA5A5A5A5ULL, false, true);
    Constant *CK = ConstantInt::get(Builder.getContext(), K);
    Constant *Masked = ConstantInt::get(Builder.getContext(), C ^ K);
    Value *Tmp = Builder.CreateXor(Masked, CK, "obf.const.masked");
    return Builder.CreateXor(Tmp, CK, "obf.const");
  }

  static bool indirectifyDirectCalls(Function &F) {
    if (!canIndirectifyFunction(F))
      return false;

    bool Changed = false;
    SmallVector<CallInst *, 16> Calls;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *CI = dyn_cast<CallInst>(&I);
        if (!CI)
          continue;
        if (CI->isInlineAsm() || CI->isMustTailCall())
          continue;
        Function *Callee = CI->getCalledFunction();
        if (!Callee || Callee->isIntrinsic() || Callee->isVarArg())
          continue;

        StringRef CN = Callee->getName();
        if (CN.starts_with("objc_") || CN.starts_with("_objc_"))
          continue;
        if (CN.starts_with("_dispatch"))
          continue;
        if (CN.contains("block") || CN.contains("Block"))
          continue;

        Calls.push_back(CI);
      }
    }

    for (CallInst *CI : Calls) {
      IRBuilder<> Builder(CI);
      Value *Callee = CI->getCalledOperand();
      IRBuilder<> EntryBuilder(&*F.getEntryBlock().getFirstInsertionPt());
      AllocaInst *Slot =
          EntryBuilder.CreateAlloca(Callee->getType(), nullptr, "obf.callee.slot");
      Builder.CreateStore(Callee, Slot);
      LoadInst *Loaded = Builder.CreateLoad(Callee->getType(), Slot, "obf.callee");
      Loaded->setVolatile(true);
      CI->setCalledOperand(Loaded);
      Changed = true;
    }
    return Changed;
  }

  static bool splitBasicBlocks(Function &F) {
    if (F.hasPersonalityFn())
      return false;

    bool Changed = false;
    SmallVector<BasicBlock *, 16> ToSplit;
    for (BasicBlock &BB : F) {
      if (!isSafeBlockForSplitOrBCF(BB))
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
      if (!isSafeBlockForSplitOrBCF(*BI->getParent()))
        continue;

      IRBuilder<> Builder(BI);
      if (BI->isConditional()) {
        continue; // 稳定增强版先不改 conditional branch 的 condition
      }

      BasicBlock *Src = BI->getParent();
      BasicBlock *Target = BI->getSuccessor(0);
      bool HasPHI = false;
      for (Instruction &I : *Target) {
        if (!isa<PHINode>(I))
          break;
        HasPHI = true;
      }
      Function *Fn = Src->getParent();
      BasicBlock *Bogus = BasicBlock::Create(Fn->getContext(), "obf.bogus", Fn, Target);
      IRBuilder<> BogusBuilder(Bogus);
      Value *A = BogusBuilder.getInt32(0x13579BDF);
      Value *B = BogusBuilder.getInt32(0x2468ACE0);
      Value *X = BogusBuilder.CreateXor(A, B, "obf.bcf.junk.x");
      Value *Y = BogusBuilder.CreateAdd(X, BogusBuilder.getInt32(7), "obf.bcf.junk.y");
      (void)BogusBuilder.CreateSub(Y, BogusBuilder.getInt32(7), "obf.bcf.junk.z");
      BogusBuilder.CreateBr(Target);

      Value *Opaque = createOpaqueTrue(Builder, Builder.getTrue());
      BranchInst::Create(Target, Bogus, Opaque, BI->getIterator());
      if (HasPHI) {
        for (Instruction &I : *Target) {
          auto *PN = dyn_cast<PHINode>(&I);
          if (!PN)
            break;
          int SrcIdx = PN->getBasicBlockIndex(Src);
          if (SrcIdx < 0)
            continue;
          PN->addIncoming(PN->getIncomingValue(SrcIdx), Bogus);
        }
      }
      BI->eraseFromParent();
      Changed = true;
    }
    return Changed;
  }

  static bool hasPHINodes(const Function &F) {
    for (const BasicBlock &BB : F)
      for (const Instruction &I : BB)
        if (isa<PHINode>(I))
          return true;
    return false;
  }

  static bool flattenControlFlow(Function &F) {
    if (F.size() < 3)
      return false;

    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        if (isa<PHINode>(&I))
          return false;
      }
    }

    BasicBlock *Entry = &F.getEntryBlock();
    auto *EntryBr = dyn_cast<BranchInst>(Entry->getTerminator());
    if (!EntryBr)
      return false;
    if (EntryBr->isConditional() &&
        (EntryBr->getSuccessor(0) == Entry || EntryBr->getSuccessor(1) == Entry))
      return false;

    SmallVector<BasicBlock *, 16> Blocks;
    for (BasicBlock &BB : F) {
      if (&BB != Entry)
        Blocks.push_back(&BB);
    }

    if (Blocks.empty())
      return false;

    for (BasicBlock *BB : Blocks) {
      auto *Term = BB->getTerminator();
      if (!Term || !isa<BranchInst>(Term))
        return false;
    }

    std::mt19937_64 RNG(getEnvSeedOrDefault(F.getName(), 0xF1A77EULL));
    SmallVector<uint32_t, 16> IDs;
    IDs.reserve(Blocks.size());
    for (size_t I = 0; I < Blocks.size(); ++I)
      IDs.push_back(static_cast<uint32_t>(I + 1));
    std::shuffle(IDs.begin(), IDs.end(), RNG);

    DenseMap<BasicBlock *, uint32_t> BlockID;
    for (size_t I = 0; I < Blocks.size(); ++I)
      BlockID[Blocks[I]] = IDs[I];

    for (BasicBlock *BB : Blocks) {
      auto *BI = dyn_cast<BranchInst>(BB->getTerminator());
      if (!BI)
        continue;
      for (unsigned I = 0; I < BI->getNumSuccessors(); ++I) {
        if (BI->getSuccessor(I) == Entry)
          return false;
      }
    }

    IRBuilder<> EntryBuilder(&*Entry->getFirstInsertionPt());
    AllocaInst *State =
        EntryBuilder.CreateAlloca(EntryBuilder.getInt32Ty(), nullptr, "obf.fla.state");
    BasicBlock *Dispatcher =
        BasicBlock::Create(F.getContext(), "obf.fla.dispatcher", &F);

    auto rewriteBranchToState = [&](BranchInst *BI, IRBuilder<> &Builder) -> bool {
      if (BI->isUnconditional()) {
        BasicBlock *Succ = BI->getSuccessor(0);
        auto It = BlockID.find(Succ);
        if (It == BlockID.end())
          return false;
        Builder.CreateStore(Builder.getInt32(It->second), State);
        Builder.CreateBr(Dispatcher);
        BI->eraseFromParent();
        return true;
      }

      BasicBlock *T = BI->getSuccessor(0);
      BasicBlock *Fls = BI->getSuccessor(1);
      auto ItT = BlockID.find(T);
      auto ItF = BlockID.find(Fls);
      if (ItT == BlockID.end() || ItF == BlockID.end())
        return false;
      Value *Sel = Builder.CreateSelect(BI->getCondition(), Builder.getInt32(ItT->second),
                                        Builder.getInt32(ItF->second), "obf.fla.next");
      Builder.CreateStore(Sel, State);
      Builder.CreateBr(Dispatcher);
      BI->eraseFromParent();
      return true;
    };

    if (!rewriteBranchToState(EntryBr, EntryBuilder))
      return false;

    for (BasicBlock *BB : Blocks) {
      auto *BI = dyn_cast<BranchInst>(BB->getTerminator());
      if (!BI)
        continue;
      IRBuilder<> B(BI);
      if (!rewriteBranchToState(BI, B))
        return false;
    }

    IRBuilder<> DB(Dispatcher);
    LoadInst *Cur = DB.CreateLoad(DB.getInt32Ty(), State, "obf.fla.cur");
    SwitchInst *SW = DB.CreateSwitch(Cur, Blocks.front(), Blocks.size());
    for (BasicBlock *BB : Blocks)
      SW->addCase(DB.getInt32(BlockID[BB]), BB);

    return true;
  }

public:
  PreservedAnalyses run(Function &F, FunctionAnalysisManager &) {
    const bool TraceFunc = getEnvBoolOrDefault("OBF_TRACE_FUNC", false);
    if (TraceFunc) {
      errs() << "[SimpleObfPass] running on function: " << F.getName() << "\n";
    }

    if (!shouldObfuscateFunction(F)) {
      if (TraceFunc) {
        errs() << "[SimpleObfPass] skip function: " << F.getName()
               << " | reason=filter_runtime_or_risky\n";
      }
      return PreservedAnalyses::all();
    }

    if (F.getName() == "__obf_decode_all_strings")
      return PreservedAnalyses::all();

    bool Changed = false;
    unsigned ArithRewriteCount = 0;
    bool FlattenChanged = false;
    bool IndirectCallChanged = false;
    bool SplitChanged = false;
    bool BranchPerturbChanged = false;
    llvm::Triple TT(F.getParent()->getTargetTriple());
    const bool IsAppleMobile = TT.isiOS() || TT.isTvOS() || TT.isWatchOS();
    const bool IsSimulator = TT.isSimulatorEnvironment();
    (void)IsAppleMobile;
    (void)IsSimulator;
    const bool ConservativeDefault = false;
    const bool ConservativeMode =
        getEnvBoolOrDefault("OBF_CONSERVATIVE_MODE", ConservativeDefault);
    SmallVector<BinaryOperator *, 32> Worklist;

    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *BinOp = dyn_cast<BinaryOperator>(&I);
        if (!BinOp) {
          continue;
        }

        if (BinOp->getOpcode() != Instruction::Add &&
            BinOp->getOpcode() != Instruction::Sub &&
            BinOp->getOpcode() != Instruction::Xor &&
            BinOp->getOpcode() != Instruction::And &&
            BinOp->getOpcode() != Instruction::Or &&
            BinOp->getOpcode() != Instruction::Mul) {
          continue;
        }

        if (!BinOp->getType()->isIntegerTy()) {
          continue;
        }

        Worklist.push_back(BinOp);
      }
    }

    uint64_t SeedBase = fnv1a64(F.getName());
    uint64_t SeedIndex = 1;
    for (BinaryOperator *BinOp : Worklist) {
      IRBuilder<> Builder(BinOp);
      Value *LHS = BinOp->getOperand(0);
      Value *RHS = BinOp->getOperand(1);

      Value *NewValue = nullptr;
      if (BinOp->getOpcode() == Instruction::Add) {
        if (ConservativeMode) {
          Value *NegRHS = Builder.CreateNeg(RHS, "obf.negrhs");
          NewValue = Builder.CreateSub(LHS, NegRHS, "obf.add2sub");
        } else {
          uint64_t Seed = SeedBase ^ static_cast<uint64_t>(BinOp->getOpcode()) ^
                          (SeedIndex++ * 0x9e3779b97f4a7c15ULL);
          if (auto *CI = dyn_cast<ConstantInt>(RHS))
            RHS = createObfuscatedConst(Builder, CI->getValue(), Seed);
          if ((Seed & 1) == 0) {
            Value *NegRHS = Builder.CreateNeg(RHS, "obf.negrhs");
            NewValue = Builder.CreateSub(LHS, NegRHS, "obf.add2sub");
          } else {
            NewValue = createMBAAdd(Builder, LHS, RHS);
          }
        }
      } else if (BinOp->getOpcode() == Instruction::Sub) {
        if (ConservativeMode) {
          Value *NegRHS = Builder.CreateNeg(RHS, "obf.negrhs");
          NewValue = Builder.CreateAdd(LHS, NegRHS, "obf.sub2add");
        } else {
          uint64_t Seed = SeedBase ^ static_cast<uint64_t>(BinOp->getOpcode()) ^
                          (SeedIndex++ * 0x9e3779b97f4a7c15ULL);
          if (auto *CI = dyn_cast<ConstantInt>(RHS))
            RHS = createObfuscatedConst(Builder, CI->getValue(), Seed);
          if ((Seed & 1) == 0) {
            Value *NegRHS = Builder.CreateNeg(RHS, "obf.negrhs");
            NewValue = Builder.CreateAdd(LHS, NegRHS, "obf.sub2add");
          } else {
            Value *NegRHS = Builder.CreateNeg(RHS, "obf.negrhs");
            NewValue = createMBAAdd(Builder, LHS, NegRHS);
          }
        }
      } else if (BinOp->getOpcode() == Instruction::Xor) {
        if (ConservativeMode) {
          NewValue = createMBAXor(Builder, LHS, RHS);
        } else {
          uint64_t Seed = SeedBase ^ static_cast<uint64_t>(BinOp->getOpcode()) ^
                          (SeedIndex++ * 0x9e3779b97f4a7c15ULL);
          if (auto *CI = dyn_cast<ConstantInt>(RHS))
            RHS = createObfuscatedConst(Builder, CI->getValue(), Seed);
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
      } else if (BinOp->getOpcode() == Instruction::And) {
        if (ConservativeMode) {
          NewValue = createMBAAnd(Builder, LHS, RHS);
        } else {
          NewValue = createMBAAnd(Builder, LHS, RHS);
        }
      } else if (BinOp->getOpcode() == Instruction::Or) {
        if (ConservativeMode) {
          NewValue = createMBAOr(Builder, LHS, RHS);
        } else {
          NewValue = createMBAOr(Builder, LHS, RHS);
        }
      } else if (BinOp->getOpcode() == Instruction::Mul) {
        auto tryPow2 = [&](Value *X, Value *C) -> Value * {
          auto *CI = dyn_cast<ConstantInt>(C);
          if (!CI)
            return nullptr;
          const APInt &V = CI->getValue();
          if (!V.isPowerOf2())
            return nullptr;
          uint64_t Shift = V.logBase2();
          return Builder.CreateShl(X, ConstantInt::get(cast<IntegerType>(X->getType()), Shift),
                                   "obf.mul2shl");
        };
        NewValue = tryPow2(LHS, RHS);
        if (!NewValue)
          NewValue = tryPow2(RHS, LHS);
        if (!NewValue) {
          NewValue = nullptr;
        }
      }

      if (NewValue) {
        BinOp->replaceAllUsesWith(NewValue);
        BinOp->eraseFromParent();
        Changed = true;
        ++ArithRewriteCount;
      }
    }

    const bool SafeForAggressiveCFG = !F.hasPersonalityFn();
    const bool EnableStructuralCFG =
        getEnvBoolOrDefault("OBF_ENABLE_STRUCTURAL_CFG", true);
    const bool EnableFLA =
        getEnvBoolOrDefault("OBF_ENABLE_FLA", true);
    const bool EnableCallIndirect =
        getEnvBoolOrDefault("OBF_ENABLE_CALL_INDIRECT", true);
    const bool ExperimentalCFG =
        getEnvBoolOrDefault("OBF_ENABLE_EXPERIMENTAL_CFG", true);
    const bool HasPHI = hasPHINodes(F);
    const bool IsObjCMethod = isObjCMethodName(F.getName());
    const bool StructurallySafe = isStructurallySafeForCFGObf(F);

    if (EnableStructuralCFG && SafeForAggressiveCFG && StructurallySafe) {
      if (EnableFLA && canFlattenFunction(F)) {
        FlattenChanged = flattenControlFlow(F);
        if (FlattenChanged)
          verifyFunctionOrDie(F, "flatten");
      }

      if (EnableCallIndirect && canIndirectifyFunction(F)) {
        IndirectCallChanged = indirectifyDirectCalls(F);
        if (IndirectCallChanged)
          verifyFunctionOrDie(F, "call_indirect");
      }

      if (ExperimentalCFG && canUseExperimentalCFG(F)) {
        SplitChanged = splitBasicBlocks(F);
        if (SplitChanged)
          verifyFunctionOrDie(F, "split");

        BranchPerturbChanged = perturbBranches(F);
        if (BranchPerturbChanged)
          verifyFunctionOrDie(F, "bcf");
      }

      Changed |= FlattenChanged || IndirectCallChanged || SplitChanged ||
                 BranchPerturbChanged;
    }

    if (Changed)
      logPassHit(F);

    if (TraceFunc && Changed) {
      errs() << "[SimpleObfPass] changed function: " << F.getName()
             << " | arith_rewrites=" << ArithRewriteCount
             << " fla=" << (FlattenChanged ? 1 : 0)
             << " call_indirect=" << (IndirectCallChanged ? 1 : 0)
             << " split=" << (SplitChanged ? 1 : 0)
             << " bcf=" << (BranchPerturbChanged ? 1 : 0)
             << " fla_en=" << (EnableFLA ? 1 : 0)
             << " calli_en=" << (EnableCallIndirect ? 1 : 0)
             << " exp_cfg=" << (ExperimentalCFG ? 1 : 0)
             << " conservative=" << (ConservativeMode ? 1 : 0) << "\n";
    } else if (TraceFunc && !Changed) {
      errs() << "[SimpleObfPass] no-change function: " << F.getName()
             << " | safe_cfg=" << (SafeForAggressiveCFG ? 1 : 0)
             << " structural_cfg="
             << (EnableStructuralCFG ? 1 : 0)
             << " objc_method=" << (IsObjCMethod ? 1 : 0)
             << " has_phi=" << (HasPHI ? 1 : 0)
             << " fla_en=" << (EnableFLA ? 1 : 0)
             << " calli_en=" << (EnableCallIndirect ? 1 : 0)
             << " exp_cfg=" << (ExperimentalCFG ? 1 : 0)
             << " conservative=" << (ConservativeMode ? 1 : 0) << "\n";
    }

    if (Changed)
      verifyModuleOrDie(*F.getParent(), "SimpleObfPass");

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
