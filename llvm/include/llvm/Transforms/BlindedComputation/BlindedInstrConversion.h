#ifndef LLVM_TRANSFORMS_BLINDEDCOMPUTATION_BLINDEDINSTRCONVERSION_H
#define LLVM_TRANSFORMS_BLINDEDCOMPUTATION_BLINDEDINSTRCONVERSION_H

#include "llvm/IR/PassManager.h"
#include "llvm/Analysis/TaintTracking.h"
#include "llvm/Analysis/BasicAliasAnalysis.h"
#include "llvm/Analysis/BlindedDataUsage.h"

namespace llvm {

class BlindedInstrConversionPass : public PassInfoMixin<BlindedInstrConversionPass> {
public:
  PreservedAnalyses run(Module &M, ModuleAnalysisManager &AM);

private:
  PreservedAnalyses run(Function &F, FunctionAnalysisManager &AM);
  void propagateBlindedArgumentFunctionCall(CallBase &CB, Function &F, ArrayRef<unsigned> ParamNos, FunctionAnalysisManager &AM);
  void propagateBlindedArgumentFunctionCalls(Function &F, AAManager::Result &AA, TaintedRegisters &TR, FunctionAnalysisManager &AM);
  bool runImpl(Function &F, AAManager::Result &AA, TaintedRegisters &TR, BlindedDataUsage &BDU, FunctionAnalysisManager &AM);
};

} // namespace llvm

#endif // LLVM_TRANSFORMS_BLINDEDCOMPUTATION_BLINDEDINSTRCONVERSION_H