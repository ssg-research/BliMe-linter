#ifndef LLVM_TRANSFORMS_BLINDEDCOMPUTATION_BLINDEDINSTRCONVERSION_H
#define LLVM_TRANSFORMS_BLINDEDCOMPUTATION_BLINDEDINSTRCONVERSION_H

#include "llvm/IR/PassManager.h"
#include "llvm/ADT/SmallSet.h"
#include "llvm/Analysis/TaintTracking.h"
#include "llvm/Analysis/BasicAliasAnalysis.h"
#include "llvm/Analysis/BlindedDataUsage.h"

namespace llvm {

class BlindedInstrConversionPass : public PassInfoMixin<BlindedInstrConversionPass> {
public:
  PreservedAnalyses run(Module &M, ModuleAnalysisManager &AM);

private:
  PreservedAnalyses run(Function &F, FunctionAnalysisManager &AM,
                        SmallSet<Function *, 8> &VisitedFunctions);

  bool propagateBlindedArgumentFunctionCall(
      CallBase &CB, Function &F, ArrayRef<unsigned> ParamNos,
      FunctionAnalysisManager &AM, SmallSet<Function *, 8> &VisitedFunctions);

  void propagateBlindedArgumentFunctionCalls(
      Function &F, AAManager::Result &AA, TaintedRegisters &TR,
      FunctionAnalysisManager &AM, SmallSet<Function *, 8> &VisitedFunctions);

  bool linearizeSelectInstructions(Function &F);

  bool runImpl(Function &F, AAManager::Result &AA, TaintedRegisters &TR,
               BlindedDataUsage &BDU, FunctionAnalysisManager &AM,
               SmallSet<Function *, 8> &VisitedFunctions);
};

} // namespace llvm

#endif // LLVM_TRANSFORMS_BLINDEDCOMPUTATION_BLINDEDINSTRCONVERSION_H