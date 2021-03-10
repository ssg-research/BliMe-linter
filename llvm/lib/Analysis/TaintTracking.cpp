#include "llvm/Analysis/TaintTracking.h"

using namespace llvm;

const TaintedRegisters::ConstValueSet &TaintedRegisters::getTaintedRegisters() {
  if (TaintedRegisterSet.empty() && DefUseMap.empty()) {
    populateDefUseMap();
    for (auto Arg = F.arg_begin(); Arg < F.arg_end(); ++Arg) {
      propagateTaintedRegisters(Arg);
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
      OS << "  " << *Inst << "\n";
    }
  }

  OS << "Argument Users:" << "\n";
  for (auto Arg = F.arg_begin(); Arg < F.arg_end(); ++Arg) {
    OS << *Arg << " has users:\n";
    for (const User *U : Arg->users()) {
      OS << "  " << *U << "\n";
    }
  }

  OS << "Tainted Registers:" << "\n";
  for (const Value *Val : TaintedRegisterSet) {
    OS << "  " << *Val << "\n";
  }

  OS << "Tainted Input:" << "\n";
  for (auto Arg = F.arg_begin(); Arg < F.arg_end(); ++Arg) {
    if (Arg->hasAttribute(Attribute::Blinded)) {
      OS << "  " << *Arg << "\n";
    }
  }
}

// Currently unused, probably unnecessary
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

void TaintedRegisters::propagateTaintedRegisters(const Argument *TaintedArg) {
  SmallVector<const Value *, 16> Worklist;
  Worklist.push_back(TaintedArg);

  while (!Worklist.empty()) {
    const Value *CurrentVal = Worklist.pop_back_val();
    TaintedRegisterSet.insert(CurrentVal);

    for (const User *U : CurrentVal->users()) {

      // We can define more fine tuned propagation rules here
      // We can cast to specific instruction subclasses and handle
      // each case

      if (const Value *UVal = dyn_cast<Value>(U)) {
        Worklist.push_back(UVal);
      }
    }
  }
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