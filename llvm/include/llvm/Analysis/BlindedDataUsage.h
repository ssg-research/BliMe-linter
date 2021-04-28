#ifndef LLVM_ANALYSIS_BLINDEDDATAUSAGE_H
#define LLVM_ANALYSIS_BLINDEDDATAUSAGE_H

#include "llvm/IR/PassManager.h"
#include "llvm/Analysis/TaintTracking.h"

namespace llvm {

class BlindedDataUsage {
public:
  BlindedDataUsage(Function &F) : F(F) {}

  void validateBlindedData(TaintedRegisters &TR, AAManager::Result &AA);
private:
  /// The function whose blinded data we are validating.
  Function &F;
};

/// The analysis pass which yields a blinded data usage result
///
/// The blinded data usage result class has methods to check If blinded
/// data policies are violated, i.e. blinded data is used in a branch
/// instruction, then an assertion error is thrown
class BlindedDataUsageAnalysis : public AnalysisInfoMixin<BlindedDataUsageAnalysis> {
  friend AnalysisInfoMixin<BlindedDataUsageAnalysis>;
  static AnalysisKey Key;
public:
  using Result = BlindedDataUsage;
  Result run(Function &F, FunctionAnalysisManager &AM);
};

} // namespace llvm

#endif // LLVM_ANALYSIS_BLINDEDDATAUSAGE_H