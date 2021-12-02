//===- llvm/Analysis/TaintTracking.h --------------------------------------===//
//
// Under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// Author: Eric Liu <e34liu@uwaterloo.ca>
//         Shazz Amin <me@shazz.me>
//         Hans Liljestrand <hans@liljestrand.dev>
//
// Copyright: Secure System Group, University of waterloo
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_ANALYSIS_TAINTTRACKING_H
#define LLVM_ANALYSIS_TAINTTRACKING_H

#include "llvm/ADT/DenseMap.h"
#include "llvm/IR/Instruction.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/PassManager.h"
#include "llvm/Analysis/AliasAnalysis.h"
#include "llvm/Analysis/AliasSetTracker.h"

namespace llvm {

class TaintedRegisters {
public:
  using ConstValueSet = SmallPtrSet<Value *, 4>;

  /// Construct an empty TaintedRegisters object.
  TaintedRegisters(Function &F) : F(F) {}

  /// Gets tainted registers in this function
  ///
  /// This returns the cached value if taint analysis has previously 
  /// been completed, otherwise it processes it first.
  const ConstValueSet &getTaintedRegisters(AAResults *AA, int mode=0);
  
  /// Explicitly marks value as tainted and propagates taint
  /// This marking is maintained even after `releaseMemory()` is called
  void explicitlyTaint(Value *Value);

  /// Free the memory used by this class.
  void releaseMemory();

  /// Print out the tainted values currently in the cache.
  void print(raw_ostream &OS) const;

private:
  /// The function we are performing taint analysis on.
  Function &F;

  std::unique_ptr<AliasSetTracker> AST;

  ConstValueSet ExplicitlyMarkedTainted;

  ConstValueSet TaintedRegisterSet;
  ConstValueSet BlindedDataSet;

  /// Assumes input is tainted and propagates taint to other values
  void propagateTaintedRegisters(Value *TaintedArg,
                                 AliasSetTracker *AST);

  std::unique_ptr<AliasSetTracker> buildAliasSetTracker(AAResults *AA);
};

/// The analysis pass which yields a TaintedRegisters
///
/// For now the analysis pass does nothing except return an empty 
/// TaintedRegesiters object
class TaintTrackingAnalysis : public AnalysisInfoMixin<TaintTrackingAnalysis> {
  friend AnalysisInfoMixin<TaintTrackingAnalysis>;
  static AnalysisKey Key;
public:
  using Result = TaintedRegisters;
  TaintedRegisters run(Function &F, FunctionAnalysisManager &AM);
};

/// A pass for printing the taint tracking analysis for a function.
///
/// This pass will print any tainted registers used in this function. Tainted
/// data is first propagated and stored in TaintedRegisters
class TaintTrackingPrinterPass : public PassInfoMixin<TaintTrackingPrinterPass> {
  raw_ostream &OS;
public:
  explicit TaintTrackingPrinterPass(raw_ostream &OS) : OS(OS) {}
  PreservedAnalyses run(Function &F, FunctionAnalysisManager &AM);
};

} // namespace llvm

#endif // LLVM_ANALYSIS_TAINTTRACKING_H
