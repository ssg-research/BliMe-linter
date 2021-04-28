#include "llvm/Analysis/BlindedDataUsage.h"
#include "llvm/IR/InstIterator.h"

using namespace llvm;

void BlindedDataUsage::validateBlindedData(TaintedRegisters &TR,
                                           AAManager::Result &AA) {
  auto &TRSet = TR.getTaintedRegisters(&AA);

  for (inst_iterator I = inst_begin(F), E = inst_end(F); I != E; ++I) {
    Instruction &Inst = *I;

    // we are only interested in blinded instructions
    if (!TRSet.contains(&Inst)) {
      continue;
    }

    if (isa<BranchInst>(&Inst)) {
      assert(false && "Invalid use of blinded data as operand of BranchInst!");
    }

    if (GetElementPtrInst *GEP = dyn_cast<GetElementPtrInst>(&Inst)) {
      for (auto Idx = GEP->idx_begin(); Idx != GEP->idx_end(); ++Idx) {
        if (TRSet.contains(*Idx)) {
          assert(GEP->getSourceElementType()->isArrayTy() &&
                 "Invalid use of blinded data as index of varying-size array!");
        }
      }
    }
  }
}

AnalysisKey BlindedDataUsageAnalysis::Key;
BlindedDataUsage BlindedDataUsageAnalysis::run(Function &F,
                                     FunctionAnalysisManager &AM) {
  return BlindedDataUsage(F);
}
