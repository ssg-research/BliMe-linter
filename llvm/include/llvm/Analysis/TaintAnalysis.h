#ifndef LLVM_ANALYSIS_TAINTANALYSIS_H
#define LLVM_ANALYSIS_TAINTANALYSIS_H

#include "llvm/IR/Instruction.h"
#include "llvm/IR/PassManager.h"

namespace llvm {

class TaintAnalysisPass : public PassInfoMixin<TaintAnalysisPass> {
public:
  PreservedAnalyses run(Function &F, FunctionAnalysisManager &AM);
};

} // namespace llvm

#endif // LLVM_ANALYSIS_TAINTANALYSIS_H