#ifndef LLVM_TRANSFORMS_BLINDEDCOMPUTATION_MODIFYMETADATA_H
#define LLVM_TRANSFORMS_BLINDEDCOMPUTATION_MODIFYMETADATA_H

#include "llvm/IR/PassManager.h"
#include "llvm/Transforms/BlindedComputation/BlindedDataUsage.h"
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

#include <llvm/IR/DebugLoc.h>
#include <llvm/IR/DebugInfoMetadata.h>
#include <unordered_map>


namespace llvm {

class ModifyMetadataPass : public PassInfoMixin<ModifyMetadataPass> {
public:
  PreservedAnalyses run(Module &M, ModuleAnalysisManager &AM);
};

} // namespace llvm

#endif // LLVM_TRANSFORMS_BLINDEDCOMPUTATION_MODIFYMETADATA_H