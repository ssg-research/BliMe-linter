#ifndef LLVM_TRANSFORMS_BLINDEDCOMPUTATION_BLINDEDDATAUSAGEVALIDATION_H
#define LLVM_TRANSFORMS_BLINDEDCOMPUTATION_BLINDEDDATAUSAGEVALIDATION_H

#include "llvm/IR/PassManager.h"
#include "llvm/Analysis/TaintTracking.h"
#include "llvm/Transforms/BlindedComputation/BlindedTaintTracking.h"

namespace llvm {

// FIXME: Needs to report multiple policy violations!
class BlindedDataUsage {
public:
  typedef DenseSet<std::pair<const Value *, StringRef>> Violations_t;
  typedef Violations_t::const_iterator Violations_iterator;
  typedef iterator_range<Violations_iterator> Violations_range;

  BlindedDataUsage(Module &M, ModuleAnalysisManager &AM);

  // bool validateBlindedData(TaintResult &TR, AAManager::Result &AA);
  Violations_range violations() { return Violations; }

private:
  bool IsDone = false;
  Violations_t Violations;

  /// The function whose blinded data we are validating.
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
  Result run(Module &M, ModuleAnalysisManager &AM);
};

class BlindedDataUsagePrinterPass
    : public PassInfoMixin<BlindedDataUsagePrinterPass> {
  raw_ostream &OS;

public:
  explicit BlindedDataUsagePrinterPass(raw_ostream &OS) : OS(OS) {}
  PreservedAnalyses run(Module &M, ModuleAnalysisManager &AM);
};

} // namespace llvm

#endif // LLVM_TRANSFORMS_BLINDEDCOMPUTATION_BLINDEDDATAUSAGEVALIDATION_H
