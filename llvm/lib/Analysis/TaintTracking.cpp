//===- TaintTracking.cpp --------------------------------------------------===//
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

void TaintedRegisters::explicitlyTaint(Value *Value) {
  ExplicitlyMarkedTainted.insert(Value);
  propagateTaintedRegisters(Value, AST.get(), true);
}

const TaintedRegisters::ConstValueSet &
TaintedRegisters::getTaintedRegisters(AAResults *AA) {
  if (TaintedRegisterSet.empty()) {
    AST = buildAliasSetTracker(AA);
    // AST->dump();

   // int useKey(__attribute__((blinded)) int idx) {
    errs() << F.getName() << "begins\n"; 
    for (auto Arg = F.arg_begin(); Arg < F.arg_end(); ++Arg) {
      if (Arg->hasAttribute(Attribute::Blinded)) {
        if (Arg->getType()->isPointerTy()){
          propagateTaintedRegisters(Arg, AST.get(), false);
        }
        else {
          propagateTaintedRegisters(Arg, AST.get(), true);
        }
      }
    }
    errs() << "analysis on args ends\n";

    if (Module *M = F.getParent()) {
      errs() << "analysis on GV \n";
      Module::GlobalListType &GL = M->getGlobalList();
      for (auto I = GL.begin(), E = GL.end(); I != E; ++I) {
        GlobalVariable &GV = *I;
        if (GV.hasAttribute(Attribute::Blinded)){
          propagateTaintedRegisters(&GV, AST.get(), false);
        }
      }
    }

    errs() << "analysis on GV ends\n";
    for (Value *Val : ExplicitlyMarkedTainted) {
      errs() << "analysis on Explicit\n";
      errs() << Val->getName();
      propagateTaintedRegisters(Val, AST.get(), true);
    }
    errs() << "end of analysis...\n\n";
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

void TaintedRegisters::propagateTaintedRegisters(Value *TaintedArg,
                                                 AliasSetTracker *AST, bool mode) {
  SmallVector<std::pair<Value *, bool>, 64> Worklist;

  Worklist.push_back(std::pair<Value*, bool>(TaintedArg, mode));

  while (!Worklist.empty()) {
    std::pair<Value*, bool> CurrentPair = Worklist.pop_back_val();
    Value *CurrentVal = CurrentPair.first;
    bool isBlindedData = CurrentPair.second;

    if (isBlindedData){
      if (TaintedRegisterSet.contains(CurrentVal))
        continue;
      else
        TaintedRegisterSet.insert(CurrentVal);
    }
    else{
      if (PtrBlindedSet.contains(CurrentVal))
        continue;
      else
        PtrBlindedSet.insert(CurrentVal);
    }
    
    // insert current blinded arg
    // TaintedRegisterSet.insert(CurrentVal);

    if (Instruction *currentInst = dyn_cast<Instruction>(CurrentVal)) {
      if (TaintedRegisterSet.contains(CurrentVal)){
        LLVMContext &cont = currentInst->getContext();
        MDNode *N = MDNode::get(cont, MDString::get(cont, "blindedTag"));
        currentInst->setMetadata("my.md.blindedMD", N);
      }
      else{
        LLVMContext &cont = currentInst->getContext();
        MDNode *N = MDNode::get(cont, MDString::get(cont, "blindedPtrTag"));
        currentInst->setMetadata("my.md.blindedPtr", N);
      }

    }

//    if (const GetElementPtrInst *GEP = dyn_cast<GetElementPtrInst>(UInst)) {
      // TODO: Should we *really* blind the operand(s) of a blinded GEP??? (It's not really right - proper alias analysis would be better)
//    }

    // Check all the users
    for (User *U : CurrentVal->users()) {

      // We can define more fine tuned propagation rules here
      // We can cast to specific instruction subclasses and handle
      // each case

      if (const BinaryOperator *BinOp = dyn_cast<BinaryOperator>(U)) {
        if (isMultiplicationByZero(BinOp)) continue;
      }

      if (Instruction *UInst = dyn_cast<Instruction>(U)) {
        if (UInst->getFunction() != &F) {
          // dbgs() << "\n---outsideFunc---\n";
          // dbgs() << "Function: " << F.getName() << "\n";
          // dbgs() << "CurrentVal: ";
          // CurrentVal->dump();
          // dbgs() << "External user: ";
          // UInst->dump();
          continue; // TODO FIXME Should we really ignore these??
        }

        if (const StoreInst *SI = dyn_cast<StoreInst>(UInst)) {
          const Value *PO = SI->getPointerOperand();
          if (!TaintedRegisterSet.contains(CurrentVal))
            continue;
          // if the pointer was allocated on the stack or is a global, then we can handle it
          // if (isa<AllocaInst>(PO)) {
          //   // FIXME: Does not handle all cases!
          //   // For example, the Use might be a GEP based on the source Alloca!
            
          // } else
          if (const auto *GV = dyn_cast<GlobalVariable>(PO)) {
            if (!GV->hasAttribute(Attribute::Blinded))
              assert(false && "Invalid storage of blinded data in non-blinded memory!");
          } else {
            auto &AS = AST->getAliasSetFor(MemoryLocation::get(SI));
            for (AliasSet::iterator ASI = AS.begin(), E = AS.end(); ASI != E; ++ASI) {
              // dbgs() << "\t" << ASI.getPointer()->getName() << "\n";
              if (!PtrBlindedSet.contains(ASI.getPointer())) {
                Worklist.push_back(std::pair<Value*, bool>(ASI.getPointer(), 0));
              }
            }
          }
        } else if (const CallBase *CB = dyn_cast<CallBase>(UInst)) {
          if (Function *CF = CB->getCalledFunction()) {
            if (CF->hasFnAttribute(Attribute::Blinded))
              Worklist.push_back(std::pair<Value*, bool>(UInst, 1));
          } else {
            // assume return value from indirect function call is tainted
              Worklist.push_back(std::pair<Value*, bool>(UInst, 1));
          }
        } else if (const LoadInst *LI = dyn_cast<LoadInst>(UInst)){
          const Value *PO = LI->getPointerOperand();
          if (PtrBlindedSet.contains(PO)){
            Worklist.push_back(std::pair<Value*, bool>(UInst, 1));
          }
        } else {
          if (TaintedRegisterSet.contains(CurrentVal)) {
            Worklist.push_back(std::pair<Value*, bool>(UInst, 1));
          }
          else if (PtrBlindedSet.contains(CurrentVal)){
            if (const GetElementPtrInst *GEP = dyn_cast<GetElementPtrInst>(UInst)) {
              Worklist.push_back(std::pair<Value*, bool>(UInst, 0));
            }
          }
        }
      } 
      // else if (GlobalVariable *GV = dyn_cast<GlobalVariable>(U)) {
      //   U->print(errs());
      //   if(GV->getType()->isPointerTy() && GV->getType()->getContainedType(0)->isPointerTy()){
      //     errs() << "not in worklist!\n";
      //     continue;
      //   }

      //   errs() << "\n";
      //   errs() << "try to print tainted GV...\n";
      //   Worklist.push_back(std::pair<Value*, bool>(GV, 0));
      // }
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
  TR.print(OS);

  PreservedAnalyses PA;
  PA.preserve<CFLSteensAA>();

  return PA;
}
