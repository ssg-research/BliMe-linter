//===- BlindedDataUsage.cpp -----------------------------------------------===//
//
// Under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// Author: Eric Liu <e34liu@uwaterloo.ca>
//         Hans Liljestrand <hans@liljestrand.dev>
//
// Copyright: Secure System Group, University of Waterloo
//
//===----------------------------------------------------------------------===//

#include "llvm/Analysis/BasicAliasAnalysis.h"
#include "llvm/Analysis/BlindedDataUsage.h"
#include "llvm/Analysis/CFLSteensAliasAnalysis.h"
#include "llvm/IR/InstIterator.h"

using namespace llvm;

bool BlindedDataUsage::validateBlindedData(TaintedRegisters &TR,
                                           AAManager::Result &AA) {
  if (IsDone)
    // we're fine if no violations have been found
    return Violations.empty();

  auto &TRSet = TR.getTaintedRegisters(&AA);

  for (inst_iterator I = inst_begin(F), E = inst_end(F); I != E; ++I) {
    Instruction &Inst = *I;

    if (BranchInst *BInst = dyn_cast<BranchInst>(&Inst)) {

      if (BInst->isConditional() && TRSet.contains(BInst->getCondition())){
        std::pair<Instruction *, StringRef> Violation_Instance(
            &Inst, "Invalid use of blinded data as operand of BranchInst!");
        Violations.insert(Violation_Instance);
      }
    }

    if (LoadInst *LInst = dyn_cast<LoadInst>(&Inst)){
      Value * LAddr = LInst->getPointerOperand();
      if (TRSet.contains(LAddr)){ 
//        std::pair<Instruction *, StringRef> Violation_Instance(
//          &Inst, LAddr->getValueName());
//        Inst.print(errs());
//        errs() << StringRef(LAddr->getName().str()) << "\n";
        std::pair<Instruction *, StringRef> Violation_Instance(
          &Inst, StringRef("LoadInst with a blinded pointer."));
        Violations.insert(Violation_Instance);           

      }
    }
    
    if (StoreInst *SInst = dyn_cast<StoreInst>(&Inst)){   
      Value * SAddr = SInst->getPointerOperand();

      if (TRSet.contains(SAddr)){ 
//        std::pair<Instruction *, StringRef> Violation_Instance(
//          &Inst, SAddr->getValueName());
//        errs() << StringRef(SAddr->getName().str()) << "\n";
        Inst.print(errs());
        std::pair<Instruction *, StringRef> Violation_Instance(
          &Inst, StringRef("StoreInst with a blinded pointer."));
        Violations.insert(Violation_Instance);           

      }    
    }
  }
  
  IsDone = true;
  
  return Violations.empty();
}

AnalysisKey BlindedDataUsageAnalysis::Key;
BlindedDataUsage BlindedDataUsageAnalysis::run(Function &F,
                                     FunctionAnalysisManager &AM) {
  return BlindedDataUsage(F);
}

PreservedAnalyses BlindedDataUsagePrinterPass::run(Function &F,
                                     FunctionAnalysisManager &AM) {
  // Get alias analysis results from the BasicAA and Steensgard's AA
  auto &BasicAAResult = AM.getResult<BasicAA>(F);
  auto &SteensAAResult = AM.getResult<CFLSteensAA>(F);
  // Create an AAResult to track the AA results
  auto &AAResult = AM.getResult<AAManager>(F);
  AAResult.addAAResult(SteensAAResult);
  AAResult.addAAResult(BasicAAResult);

  // Create our analysis objects for F
  auto &TRS = AM.getResult<TaintTrackingAnalysis>(F);
  auto &BDU = AM.getResult<BlindedDataUsageAnalysis>(F);

  if (!BDU.validateBlindedData(TRS, AAResult)) {
    // Got some violations, now pretty print them since we're a printer pass!
    for (auto &V : BDU.violations()) { 
      if (V.first == nullptr){OS << V.second << "\n\n"; continue; }
      Instruction &Inst = *(V.first);
      Inst.getDebugLoc().print(OS);
      Inst.print(OS);
      OS << "\n";
      OS << "description: " << V.second << "\n\n";
    }
  }
    
  // Tell the pass manager we don't invalidate any of the used analyses
  PreservedAnalyses PA;
  PA.preserve<BlindedDataUsageAnalysis>();
  PA.preserve<TaintTrackingAnalysis>();
  PA.preserve<AAManager>();
  PA.preserve<BasicAA>();
  PA.preserve<CFLSteensAA>();

  return PA;
}
