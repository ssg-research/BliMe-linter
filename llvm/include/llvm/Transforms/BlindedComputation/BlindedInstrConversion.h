#ifndef LLVM_TRANSFORMS_BLINDEDCOMPUTATION_BLINDEDINSTRCONVERSION_H
#define LLVM_TRANSFORMS_BLINDEDCOMPUTATION_BLINDEDINSTRCONVERSION_H

#include "llvm/IR/PassManager.h"
#include "llvm/ADT/SmallSet.h"
#include "llvm/Analysis/TaintTracking.h"
#include "llvm/Analysis/BasicAliasAnalysis.h"
#include "llvm/Analysis/BlindedDataUsage.h"
#include <vector>
#include <unordered_map>

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

  bool checkAddDependentFunction(Function *F);

  bool runImpl(Function &F, AAManager::Result &AA, TaintedRegisters &TR,
               BlindedDataUsage &BDU, FunctionAnalysisManager &AM,
               SmallSet<Function *, 8> &VisitedFunctions);

  Function *generateBlindedCopy(Twine &NewName, Function &OrigFunc,
                                ArrayRef<unsigned> ParamNos);

  static inline unsigned arrToBitmap(ArrayRef<unsigned> &Arr) {
    unsigned Result = 0;
    for (unsigned n : Arr) {
      assert(n < UINT_WIDTH);
      Result |= (1 << n);
    }
    return Result;
  }
  std::vector<Function*> FunctionWorkList;
  std::unordered_map<const Function*, std::vector<Function*>> DependentFunctions;
  std::unordered_map<const Function*, int> TaintTrackingResult;


};

} // namespace llvm

#endif // LLVM_TRANSFORMS_BLINDEDCOMPUTATION_BLINDEDINSTRCONVERSION_H