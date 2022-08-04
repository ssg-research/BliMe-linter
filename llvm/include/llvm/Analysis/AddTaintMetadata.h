#ifndef LLVM_ANALYSIS_ADDTAINTMETADATA_H
#define LLVM_ANALYSIS_ADDTAINTMETADATA_H

#include "llvm/IR/PassManager.h"
#include "llvm/ADT/SmallSet.h"
#include "llvm/Analysis/TaintTracking.h"
#include "llvm/Analysis/BasicAliasAnalysis.h"
#include "llvm/Analysis/BlindedDataUsage.h"

namespace llvm {

class AddTaintMetadata : public PassInfoMixin<AddTaintMetadata> {
public:
  PreservedAnalyses run(Function &F, FunctionAnalysisManager &AM);

};

} // namespace llvm
#endif