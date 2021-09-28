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
// XFAIL: *

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

    // we are only interested in blinded instructions
    if (!TRSet.contains(&Inst)) {
      continue;
    }

    if (isa<BranchInst>(&Inst)) {
      // TODO: Move to printer pass and pretty print the DebugLoc (if defined)
      // Inst.getDebugLoc().print(errs());

      // TODO: Add Instruction and explanation to Violations list
      // Violations.insert(...);
      std::pair<Instruction *, StringRef> Violation_Instance (&Inst, "Invalid use of blinded data as operand of BranchInst!");
      Violations.insert(Violation_Instance);

      // FIXME: Don't use assert here!
      
      // assert(false && "Invalid use of blinded data as operand of BranchInst!");
    }

    if (GetElementPtrInst *GEP = dyn_cast<GetElementPtrInst>(&Inst)) {
      for (auto Idx = GEP->idx_begin(); Idx != GEP->idx_end(); ++Idx) {
        if (TRSet.contains(*Idx)) {
          std::pair<Instruction *, StringRef> Violation_Instance (&Inst, StringRef("Invalid use of blinded data as index of varying-size array!"));
          Violations.insert(Violation_Instance);
          // FIXME: Don't use assert here!
          // assert(GEP->getSourceElementType()->isArrayTy() &&
          //        "Invalid use of blinded data as index of varying-size array!");
        }
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

PreservedAnalyses BlindedDataUsagePrinterPass::run(Function &F, FunctionAnalysisManager &AM) {
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

    // TODO: Print out the results
    // 
    // Note, for this to work, the BlindedDataUsageAnalysis validateBlindedData
    // function must first be updated such that it doesn't immediately crash on
    // failures. There is an initial Violations container for storing results,
    // but it can be adapted as needed.
    // 
    // Output should probably be silent for non-violating functions, and for
    // others start with saysing something like "Violations found for function"
    // and then listing violations. 
    // OS << "TRY!!!\n";
    // OS << __FUNCTION__ << " isn't done yet!\n";
    // llvm_unreachable("unimplemented");
    
    for (auto &V : BDU.violations()) { 
      // TODO: Print them out
      // 
      
      Instruction &Inst = *(V.first);
      Inst.getDebugLoc().print(OS);
      OS << "\n";
      OS << "description: " << V.second << "\n\n";
      // OS << Inst << "\n";
      // Each entry should contain some location indicator (if available, based
      // on a DebugLoc that points to the original source file) and an
      // explanation of why this is a violation. The explanation can be
      // essentially just the original string from the asserts.
    } }
    
  // Tell the pass manager we don't invalidate any of the used analyses
  PreservedAnalyses PA;
  PA.preserve<BlindedDataUsageAnalysis>();
  PA.preserve<TaintTrackingAnalysis>();
  PA.preserve<AAManager>();
  PA.preserve<BasicAA>();
  PA.preserve<CFLSteensAA>();

  return PA;
}
