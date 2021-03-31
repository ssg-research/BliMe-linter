#include "llvm/Analysis/TaintTracking.h"
#include "llvm/Analysis/BasicAliasAnalysis.h"
#include "llvm/Analysis/CFLAndersAliasAnalysis.h"
#include "llvm/Analysis/CFLSteensAliasAnalysis.h"

using namespace llvm;

std::unique_ptr<AliasSetTracker>
TaintedRegisters::buildAliasSetTracker(AAResults *AA) {
  auto AST = std::make_unique<AliasSetTracker>(*AA);
  for (BasicBlock &BB : F) {
    for (Instruction &Inst : BB) {

      // Skip call instructions, they are currently beyond the
      // scope of this pass and can potentially greatly reduce
      // the accuracy of the AliasSets
      if (!(isa<CallInst>(Inst) || isa<InvokeInst>(Inst))) {
        AST->add(&Inst);
      }
    }
  }
  return AST;
}

const TaintedRegisters::ConstValueSet &
TaintedRegisters::getTaintedRegisters(AAResults *AA) {
  if (TaintedRegisterSet.empty()) {

    auto AST = buildAliasSetTracker(AA);
    AST->dump();

    for (auto Arg = F.arg_begin(); Arg < F.arg_end(); ++Arg) {
      if (Arg->hasAttribute(Attribute::Blinded)) {
        propagateTaintedRegisters(Arg, AST.get());
      }
    }
  }
  return TaintedRegisterSet;
}

void TaintedRegisters::releaseMemory() {
  TaintedRegisterSet.clear();
}

void TaintedRegisters::print(raw_ostream &OS) const {

  OS << "All instructions:" << "\n";
  for (const BasicBlock &BB : F) {
    for (const Instruction &Inst : BB) {
      OS << Inst << "\n";
    }
  }
  OS << "\n";

  OS << "Tainted Registers:" << "\n";
  for (const Value *Val : TaintedRegisterSet) {
    OS << "  " << *Val << "\n";
  }
  OS << "\n";

  OS << "Argument Users:" << "\n";
  for (auto Arg = F.arg_begin(); Arg < F.arg_end(); ++Arg) {
    OS << *Arg << " has users:\n";
    for (const User *U : Arg->users()) {
      OS << "  " << *U << "\n";
    }
  }
  OS << "\n";

  OS << "Tainted Function Arguments:" << "\n";
  for (auto Arg = F.arg_begin(); Arg < F.arg_end(); ++Arg) {
    if (Arg->hasAttribute(Attribute::Blinded)) {
      OS << "  " << *Arg << "\n";
    }
  }
  OS << "\n";
}

void TaintedRegisters::propagateTaintedRegisters(const Argument *TaintedArg,
                                                 AliasSetTracker *AST) {
  SmallVector<const Value *, 16> Worklist;
  Worklist.push_back(TaintedArg);

  while (!Worklist.empty()) {
    const Value *CurrentVal = Worklist.pop_back_val();
    TaintedRegisterSet.insert(CurrentVal);

    for (const User *U : CurrentVal->users()) {

      // We can define more fine tuned propagation rules here
      // We can cast to specific instruction subclasses and handle
      // each case

      if (const StoreInst *SI = dyn_cast<StoreInst>(U)) {

        // if the pointer was allocated on the stack, then we can handle it
        if (isa<AllocaInst>(SI->getPointerOperand())) {
          auto &AS = AST->getAliasSetFor(MemoryLocation::get(SI));
          for (AliasSet::iterator ASI = AS.begin(), E = AS.end(); ASI != E; ++ASI) {
            if (!TaintedRegisterSet.contains(ASI.getPointer())) {
              Worklist.push_back(ASI.getPointer());
            }
          }
        }
      }
      else if (const Instruction *UInst = dyn_cast<Instruction>(U)) {
        Worklist.push_back(UInst);
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
  auto &AA = AM.getResult<AAManager>(F);
  auto &SteensAA = AM.getResult<CFLSteensAA>(F);
  auto &TR = AM.getResult<TaintTrackingAnalysis>(F);

  // Add result of Steens AA to our AAManager
  AA.addAAResult(SteensAA);
  TR.getTaintedRegisters(&AA);
  TR.print(OS);

  PreservedAnalyses PA;
  PA.preserve<CFLSteensAA>();

  return PA;
}