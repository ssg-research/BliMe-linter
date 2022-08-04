#include "llvm/Analysis/AddTaintMetadata.h"
#include "llvm/ADT/SetVector.h"
#include "llvm/ADT/APInt.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/ValueMap.h"
#include <llvm/IR/DebugLoc.h>
#include <llvm/IR/DebugInfoMetadata.h>
#include "llvm/Analysis/TaintTracking.h"
#include "llvm/Analysis/BasicAliasAnalysis.h"
#include "llvm/Analysis/BlindedDataUsage.h"
#include "llvm/Analysis/CFLSteensAliasAnalysis.h"
#include "llvm/Transforms/Utils/Cloning.h"
#include <llvm/IR/DebugLoc.h>
#include <llvm/IR/DebugInfoMetadata.h>

using namespace llvm;

PreservedAnalyses AddTaintMetadata::run(Function &F, 
                                        FunctionAnalysisManager &AM) {
  auto &BasicAAResult = AM.getResult<BasicAA>(F);
  auto &SteensAAResult = AM.getResult<CFLSteensAA>(F);
  // Create an AAResult to track the AA results
  auto &AAResult = AM.getResult<AAManager>(F);
  AAResult.addAAResult(SteensAAResult);
  AAResult.addAAResult(BasicAAResult);

  // Create our analysis objects for F
  auto &TRS = AM.getResult<TaintTrackingAnalysis>(F);
  auto &TRSet = TRS.getTaintedRegisters(&AAResult);

  for (inst_iterator I = inst_begin(F), E = inst_end(F); I != E; ++I) {
    Instruction &Inst = *I;

    if (BranchInst *BInst = dyn_cast<BranchInst>(&Inst)) {
      if (BInst->isConditional() && TRSet.contains(BInst->getCondition())){
        LLVMContext &cont = Inst.getContext();
        MDNode *N = MDNode::get(cont, ConstantAsMetadata::get(ConstantInt::get(cont, APInt(sizeof(long)*8, true, true))));
        Inst.setMetadata("t", N);
      }
    }

    if (LoadInst *LInst = dyn_cast<LoadInst>(&Inst)){
      Value * LAddr = LInst->getPointerOperand();
      if (TRSet.contains(LAddr)){  
        LLVMContext &cont = Inst.getContext();
        MDNode *N = MDNode::get(cont, ConstantAsMetadata::get(ConstantInt::get(cont, APInt(sizeof(long)*8, true, true))));
        Inst.setMetadata("t", N);        

      }
    }
    
    if (StoreInst *SInst = dyn_cast<StoreInst>(&Inst)){   
      Value * SAddr = SInst->getPointerOperand();
      if (TRSet.contains(SAddr)){  
        LLVMContext &cont = Inst.getContext();
        MDNode *N = MDNode::get(cont, ConstantAsMetadata::get(ConstantInt::get(cont, APInt(sizeof(long)*8, true, true))));
        Inst.setMetadata("t", N);        

      }    
    }
  }
      
  PreservedAnalyses PA;
  PA.preserve<BlindedDataUsageAnalysis>();
  PA.preserve<TaintTrackingAnalysis>();
  PA.preserve<AAManager>();
  PA.preserve<BasicAA>();
  PA.preserve<CFLSteensAA>();

  return PA;
}
