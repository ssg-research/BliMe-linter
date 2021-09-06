//===- llvm/Analysis/BlindedDataUsage.h -----------------------------------===//
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

#ifndef LLVM_ANALYSIS_BLINDEDDATAUSAGE_H
#define LLVM_ANALYSIS_BLINDEDDATAUSAGE_H

#include "llvm/IR/PassManager.h"
#include "llvm/Analysis/TaintTracking.h"

namespace llvm {

class BlindedDataUsage {
public:
  BlindedDataUsage(Function &F) : F(F) {}

  void validateBlindedData(TaintedRegisters &TR, AAManager::Result &AA);
private:
  /// The function whose blinded data we are validating.
  Function &F;
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
  Result run(Function &F, FunctionAnalysisManager &AM);
};

} // namespace llvm

#endif // LLVM_ANALYSIS_BLINDEDDATAUSAGE_H