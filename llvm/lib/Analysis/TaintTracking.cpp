#include "llvm/Analysis/TaintTracking.h"

using namespace llvm;

const TaintedRegisters::ValueSet &TaintedRegisters::getTaintedRegisters() {
  if (TaintedRegisterSet.empty() && DefUseMap.empty()) {
    populateDefUseMap();
    for (auto arg = F.arg_begin(); arg < F.arg_end(); ++arg) {
      propagateTaintedRegisters(arg);
    }
  }
  return TaintedRegisterSet;
}

void TaintedRegisters::releaseMemory() {
  DefUseMap.clear();
  TaintedRegisterSet.clear();
}

void TaintedRegisters::print(raw_ostream &OS) const {

  OS << "All instructions:" << "\n";
  for (const BasicBlock &BB : F) {
    for (const Instruction &Inst : BB) {
      OS << Inst << "\n";
    }
  }

  OS << "Def-Use Map:" << "\n";
  for (const auto &Pair : DefUseMap) {
    OS << *Pair.first << " is used in instructions:\n";
    for (const auto *Inst : Pair.second) {
      OS << *Inst << "\n";
    }
  }

}

void TaintedRegisters::populateDefUseMap() {
  for (const BasicBlock &BB : F) {
    for (const Instruction &Inst : BB) {
      ConstValueSet &Users = DefUseMap[&Inst];
      for (const User *U : Inst.users()) {
        if (const Instruction *UInst = dyn_cast<Instruction>(U)) {
          Users.insert(UInst);
        }
      }
    }
  }
}

void TaintedRegisters::propagateTaintedRegisters(const Argument *Arg) {

}

AnalysisKey TaintTrackingAnalysis::Key;
TaintedRegisters TaintTrackingAnalysis::run(Function &F,
                                             FunctionAnalysisManager &AM) {
  return TaintedRegisters(F);
}

PreservedAnalyses TaintTrackingPrinterPass::run(Function &F,
                                                FunctionAnalysisManager &AM) {

  OS << "Taint Tracking for function: " << F.getName() << "\n";
  TaintedRegisters &TR = AM.getResult<TaintTrackingAnalysis>(F);
  TR.getTaintedRegisters();
  TR.print(OS);

  return PreservedAnalyses::all();
}