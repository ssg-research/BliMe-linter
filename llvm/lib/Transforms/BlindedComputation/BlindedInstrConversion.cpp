#include "llvm/Transforms/BlindedComputation/BlindedInstrConversion.h"
#include "llvm/Analysis/TaintTracking.h"
#include "llvm/Analysis/BasicAliasAnalysis.h"
#include "llvm/Analysis/CFLSteensAliasAnalysis.h"

using namespace llvm;

/// This is the entry point for all transforms.
static bool runImpl(Function &F, AAManager::Result &AA, TaintedRegisters &TR) {
  bool MadeChange = false;

  auto &TaintedRegs = TR.getTaintedRegisters(&AA);
  errs() << "Tainted Registers:" << "\n";
  for (const Value *Val : TaintedRegs) {
    errs() << "  " << *Val << "\n";
  }
  errs() << "\n";

  return MadeChange;
}

PreservedAnalyses BlindedInstrConversionPass::run(Function &F,
                                                  FunctionAnalysisManager &AM) {

  auto &AAResult = AM.getResult<AAManager>(F);
  auto &BasicAAResult = AM.getResult<BasicAA>(F);
  auto &SteensAAResult = AM.getResult<CFLSteensAA>(F);
  auto &TR = AM.getResult<TaintTrackingAnalysis>(F);

  // Add result of SteensAA and BasicAA to our AAManager
  AAResult.addAAResult(SteensAAResult);
  AAResult.addAAResult(BasicAAResult);

  if (runImpl(F, AAResult, TR)) {
    return PreservedAnalyses::all();
  }

  PreservedAnalyses PA;
  PA.preserve<AAManager>();
  PA.preserve<BasicAA>();
  PA.preserve<CFLSteensAA>();

  return PA;
}

