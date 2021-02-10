#include "llvm/Analysis/TaintAnalysis.h"

using namespace llvm;

PreservedAnalyses TaintAnalysisPass::run(Function &F,
                                         FunctionAnalysisManager &AM) {
  errs() << F.getName() << "\n";
  return PreservedAnalyses::all();
}