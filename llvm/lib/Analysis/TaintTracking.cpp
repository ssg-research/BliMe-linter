#include "llvm/Analysis/TaintTracking.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/Analysis/BasicAliasAnalysis.h"
#include "llvm/Analysis/CFLSteensAliasAnalysis.h"

using namespace llvm;

std::unique_ptr<AliasSetTracker>
TaintedRegisters::buildAliasSetTracker(AAResults *AA) {
  auto AST = std::make_unique<AliasSetTracker>(*AA);
  for (inst_iterator I = inst_begin(F), E = inst_end(F); I != E; ++I) {
    Instruction &Inst = *I;

    // Skip call instructions, they are currently beyond the
    // scope of this pass and can potentially greatly reduce
    // the accuracy of the AliasSets
    if (!(isa<CallInst>(Inst) || isa<InvokeInst>(Inst))) {
      AST->add(&Inst);
    }
  }
  return AST;
}

void TaintedRegisters::explicitlyTaint(const Value *Value) {
  ExplicitlyMarkedTainted.insert(Value);
  propagateTaintedRegisters(Value, AST.get());
}

const TaintedRegisters::ConstValueSet &
TaintedRegisters::getTaintedRegisters(AAResults *AA) {
  if (TaintedRegisterSet.empty()) {
    AST = buildAliasSetTracker(AA);
    // AST->dump();

    for (auto Arg = F.arg_begin(); Arg < F.arg_end(); ++Arg) {
      if (Arg->hasAttribute(Attribute::Blinded)) {
        propagateTaintedRegisters(Arg, AST.get());
      }
    }

    if (Module *M = F.getParent()) {
      Module::GlobalListType &GL = M->getGlobalList();
      for (auto I = GL.begin(), E = GL.end(); I != E; ++I) {
        GlobalVariable &GV = *I;
        if (GV.hasAttribute(Attribute::Blinded)) propagateTaintedRegisters(&GV, AST.get());
      }
    }

    for (const Value *Val : ExplicitlyMarkedTainted) {
      propagateTaintedRegisters(Val, AST.get());
    }
  }
  return TaintedRegisterSet;
}

void TaintedRegisters::releaseMemory() {
  TaintedRegisterSet.clear();
}

void TaintedRegisters::print(raw_ostream &OS) const {

  OS << "All instructions:" << "\n";
  for (inst_iterator I = inst_begin(F), E = inst_end(F); I != E; ++I) {
    OS << *I << "\n";
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

static bool isMultiplicationByZero(const BinaryOperator *BinOp) {
  Value *FirstOperand = BinOp->getOperand(0);
  Value *SecondOperand = BinOp->getOperand(1);
  // 17 and 18 correspond to Mul and FMul operations respectively
  if (BinOp->getOpcode() == 17) {
    if (ConstantInt *CI = dyn_cast<ConstantInt>(FirstOperand)) {
      if (CI->isZero()) {
        return true;
      }
    }
    if (ConstantInt *CI = dyn_cast<ConstantInt>(SecondOperand)) {
      if (CI->isZero()) {
        return true;
      }
    }
  }
  if (BinOp->getOpcode() == 18) {
    if (ConstantFP *CFP = dyn_cast<ConstantFP>(FirstOperand)) {
      if (CFP->isZero()) {
        return true;
      }
    }
    if (ConstantFP *CFP = dyn_cast<ConstantFP>(SecondOperand)) {
      if (CFP->isZero()) {
        return true;
      }
    }
  }
  return false;
}

void TaintedRegisters::propagateTaintedRegisters(const Value *TaintedArg,
                                                 AliasSetTracker *AST) {
  SmallVector<const Value *, 64> Worklist;
  Worklist.push_back(TaintedArg);

  while (!Worklist.empty()) {
    const Value *CurrentVal = Worklist.pop_back_val();
    if (TaintedRegisterSet.contains(CurrentVal)) {
      continue;
    }
    TaintedRegisterSet.insert(CurrentVal);

    for (const User *U : CurrentVal->users()) {

      // We can define more fine tuned propagation rules here
      // We can cast to specific instruction subclasses and handle
      // each case

      if (const BinaryOperator *BinOp = dyn_cast<BinaryOperator>(U)) {
        if (isMultiplicationByZero(BinOp)) continue;
      }

      if (const Instruction *UInst = dyn_cast<Instruction>(U)) {
        if (UInst->getFunction() != &F) continue;

        if (const StoreInst *SI = dyn_cast<StoreInst>(UInst)) {
          const Value *PO = SI->getPointerOperand();
          // if the pointer was allocated on the stack or is a global, then we can handle it
          if (isa<AllocaInst>(PO)) {
            auto &AS = AST->getAliasSetFor(MemoryLocation::get(SI));
            for (AliasSet::iterator ASI = AS.begin(), E = AS.end(); ASI != E; ++ASI) {
              if (!TaintedRegisterSet.contains(ASI.getPointer())) {
                Worklist.push_back(ASI.getPointer());
              }
            }
          } else if (const auto *GV = dyn_cast<GlobalVariable>(PO)) {
            if (!GV->hasAttribute(Attribute::Blinded))
              assert(false && "Invalid storage of blinded data in non-blinded memory!");
          }
        } else if (const CallBase *CB = dyn_cast<CallBase>(UInst)) {
          if (Function *CF = CB->getCalledFunction()) {
            if (CF->hasFnAttribute(Attribute::Blinded)) Worklist.push_back(UInst);
          } else {
            // assume return value from indirect function call is tainted
            Worklist.push_back(UInst);
          }
        } else {
          Worklist.push_back(UInst);
        }
      } else if (const GlobalVariable *GV = dyn_cast<GlobalVariable>(U)) {
        Worklist.push_back(GV);
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
  auto &AAResult = AM.getResult<AAManager>(F);
  auto &BasicAAResult = AM.getResult<BasicAA>(F);
  auto &SteensAAResult = AM.getResult<CFLSteensAA>(F);
  auto &TR = AM.getResult<TaintTrackingAnalysis>(F);

  // Add result of SteensAA and BasicAA to our AAManager
  AAResult.addAAResult(SteensAAResult);
  AAResult.addAAResult(BasicAAResult);
  TR.getTaintedRegisters(&AAResult);
  // TR.print(OS);

  PreservedAnalyses PA;
  PA.preserve<CFLSteensAA>();

  return PA;
}