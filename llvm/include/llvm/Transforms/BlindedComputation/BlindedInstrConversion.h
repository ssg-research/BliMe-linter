#ifndef LLVM_TRANSFORMS_BLINDEDCOMPUTATION_BLINDEDINSTRCONVERSION_H
#define LLVM_TRANSFORMS_BLINDEDCOMPUTATION_BLINDEDINSTRCONVERSION_H

#include "llvm/IR/PassManager.h"

namespace llvm {

class BlindedInstrConversionPass : public PassInfoMixin<BlindedInstrConversionPass> {
public:
  PreservedAnalyses run(Function &F, FunctionAnalysisManager &AM);
};

} // namespace llvm

#endif // LLVM_TRANSFORMS_BLINDEDCOMPUTATION_BLINDEDINSTRCONVERSION_H