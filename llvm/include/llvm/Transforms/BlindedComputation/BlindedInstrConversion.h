#ifndef LLVM_TRANSFORMS_BLINDEDCOMPUTATION_BLINDEDINSTRCONVERSION_H
#define LLVM_TRANSFORMS_BLINDEDCOMPUTATION_BLINDEDINSTRCONVERSION_H

#include "llvm/IR/PassManager.h"
#include "llvm/ADT/SmallSet.h"
#include "llvm/Analysis/TaintTracking.h"
#include "llvm/Analysis/BasicAliasAnalysis.h"
#include "llvm/Transforms/BlindedComputation/BlindedDataUsage.h"
#include <vector>
#include <unordered_map>
#include "llvm/Transforms/BlindedComputation/BlindedTaintTracking.h"
#include "llvm/Transforms/BlindedComputation/FunctionCloning.h"


#include "llvm/ADT/SetVector.h"
#include "llvm/ADT/APInt.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/ValueMap.h"
#include <llvm/IR/DebugLoc.h>
#include <llvm/IR/DebugInfoMetadata.h>
#include "llvm/Analysis/TaintTracking.h"
#include "llvm/Analysis/BasicAliasAnalysis.h"
#include "llvm/Analysis/CFLSteensAliasAnalysis.h"
#include "llvm/Transforms/Utils/Cloning.h"
#include "llvm/Analysis/CallGraph.h"
#include <llvm/IR/DebugLoc.h>
#include <llvm/IR/DebugInfoMetadata.h>
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

  PreservedAnalyses taintTrackingAll(Module& M, ModuleAnalysisManager &AM);
  PreservedAnalyses runAnalysis(Function &F, FunctionAnalysisManager &AM,
                        SmallSet<Function *, 8> &VisitedFunctions);

  bool linearizeSelectInstructions(Function &F);

  bool checkAddDependentFunction(Function *F, SmallSet<Function *, 8> &VisitedFunctions);

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

  void transform(Module& M, ModuleAnalysisManager &AM);
  void validate(Module &M, ModuleAnalysisManager &AM);

  std::vector<Function*> FunctionWorkList;
  std::unordered_map<Function*, SmallPtrSet<Value*, 4>> TaintInfo;
  std::unordered_map<const Function*, std::vector<Function*>> DependentFunctions;
  std::unordered_map<const Function*, int> TaintTrackingResult;

};

} // namespace llvm

#endif // LLVM_TRANSFORMS_BLINDEDCOMPUTATION_BLINDEDINSTRCONVERSION_H