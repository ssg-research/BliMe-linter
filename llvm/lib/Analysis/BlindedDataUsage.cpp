//===- BlindedDataUsage.cpp -----------------------------------------------===//
//
// Under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// Author: Eric Liu <e34liu@uwaterloo.ca>
//         Hans Liljestrand <hans@liljestrand.dev>
//
// Copyright: Secure System Group, University of waterloo
//
//===----------------------------------------------------------------------===//

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
      // FIXME: Don't use assert here!
      assert(false && "Invalid use of blinded data as operand of BranchInst!");
    }

    if (GetElementPtrInst *GEP = dyn_cast<GetElementPtrInst>(&Inst)) {
      for (auto Idx = GEP->idx_begin(); Idx != GEP->idx_end(); ++Idx) {
        if (TRSet.contains(*Idx)) {
          // FIXME: Don't use assert here!
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

PreservedAnalyses BlindedDataUsagePrinterPass::run(Function &F, FunctionAnalysisManager &AM) {
  auto &TaintedRegs = AM.getResult<BlindedDataUsageAnalysis>(F);

  // TODO: Print out the results
  //
  // Note, for this to work, the BlindedDataUsageAnalysis must first be updated
  // such that it doesn't immediately crash on failures, but instead returns
  // a list/set/data-structure with the violating instructions.
  OS << __FUNCTION__ << " isn't done yet!\n";
  llvm_unreachable("unimplemented");

  PreservedAnalyses PA;
  PA.preserve<BlindedDataUsageAnalysis>();
  return PA;
}