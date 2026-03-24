#include "llvm/IR/Constants.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/PassManager.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Passes/PassPlugin.h"

using namespace llvm;

namespace {
class SimpleObfPass : public PassInfoMixin<SimpleObfPass> {
public:
  PreservedAnalyses run(Function &F, FunctionAnalysisManager &) {
    bool Changed = false;

    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *BinOp = dyn_cast<BinaryOperator>(&I);
        if (!BinOp) {
          continue;
        }

        IRBuilder<> Builder(BinOp);
        Value *LHS = BinOp->getOperand(0);
        Value *RHS = BinOp->getOperand(1);

        if (BinOp->getOpcode() == Instruction::Add) {
          Value *NegRHS = Builder.CreateNeg(RHS, "obf.negrhs");
          Value *Sub = Builder.CreateSub(LHS, NegRHS, "obf.add2sub");
          BinOp->replaceAllUsesWith(Sub);
          BinOp->eraseFromParent();
          Changed = true;
          break;
        }

        if (BinOp->getOpcode() == Instruction::Sub) {
          Value *NegRHS = Builder.CreateNeg(RHS, "obf.negrhs");
          Value *Add = Builder.CreateAdd(LHS, NegRHS, "obf.sub2add");
          BinOp->replaceAllUsesWith(Add);
          BinOp->eraseFromParent();
          Changed = true;
          break;
        }
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
