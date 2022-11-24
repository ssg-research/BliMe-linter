#ifndef LLVM_TRANSFORMS_BLINDEDCOMPUTATION_FUNCTIONCLONING_H
#define LLVM_TRANSFORMS_BLINDEDCOMPUTATION_FUNCTIONCLONING_H

#include "llvm/IR/PassManager.h"
#include "llvm/ADT/SmallSet.h"
#include "llvm/Analysis/TaintTracking.h"
#include "llvm/Analysis/BasicAliasAnalysis.h"
#include "llvm/Transforms/BlindedComputation/BlindedDataUsage.h"
#include <vector>
#include <unordered_map>
#include "llvm/Transforms/BlindedComputation/BlindedTaintTracking.h"

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

class BlindedTTFC {
public:
  void FuncCloning(Module &M, TaintResult& TR);
  void FuncCloning(Function &F, TaintResult& TR, SVF::Andersen* pta);
  bool propagateBlindedArgumentFunctionCall(CallBase &CB, Function &F, ArrayRef<unsigned> ParamNos);
  Function* generateBlindedCopy(Twine &Name, Function &F, ArrayRef<unsigned> ParamNos);
private:
  unsigned arrToBitmap(ArrayRef<unsigned> &Arr) {
    unsigned Result = 0;
    for (unsigned n : Arr) {
      assert(n < UINT_WIDTH);
      Result |= (1 << n);
    }
    return Result;
  }
};
}

#endif