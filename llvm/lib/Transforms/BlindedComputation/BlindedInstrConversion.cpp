#include "llvm/Transforms/BlindedComputation/BlindedInstrConversion.h"
#include "llvm/ADT/SetVector.h"
#include "llvm/ADT/APInt.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Module.h"
#include "llvm/Analysis/TaintTracking.h"
#include "llvm/Analysis/BasicAliasAnalysis.h"
#include "llvm/Analysis/BlindedDataUsage.h"
#include "llvm/Analysis/CFLSteensAliasAnalysis.h"

using namespace llvm;

static SmallVector<Value *, 4> createGepIndexList(Value *TaintedIdx,
                                                  GetElementPtrInst *GEP,
                                                  Value *NewIdx) {
  SmallVector<Value *, 4> NewIndices;
  for (auto Idx = GEP->idx_begin(); Idx != GEP->idx_end(); ++Idx) {
    if (*Idx == TaintedIdx) {
      NewIndices.push_back(NewIdx);
    } else {
      NewIndices.push_back(*Idx);
    }
  }
  return NewIndices;
}

void updateGEPAddrUsers(GetElementPtrInst *GEP, Value *NewOperand) {
  // Iterate through all loads that use the GEP address as an operand
  // and iterate through all users of these loads. Replace these loads
  // with our blinded computation safe load
  SmallSetVector<Value *, 16> WorkList;
  for (User *GEPUser : GEP->users()) {
    for (User *U : GEPUser->users()) {
      for (unsigned int i = 0; i < U->getNumOperands(); ++i) {
        if (U->getOperand(i) == GEPUser) {
          U->setOperand(i, NewOperand);
        }
      }
      WorkList.insert(GEPUser);
    }
  }
  // delete old loads from the unsafe GEP
  for (Value *V : WorkList) {
    if (Instruction *I = dyn_cast<Instruction>(V)) {
      I->eraseFromParent();
    }
  }
}

static bool expandBlindedArrayAccess(Function &F,
                                     Value *TaintedIdx,
                                     GetElementPtrInst *GEP) {
  bool MadeChange = false;

  Type *GEPPtrType = GEP->getSourceElementType();
  auto GEPName = GEP->getPointerOperand()->getName();

  if (GEPPtrType->isArrayTy()) {
    const uint64_t ArrSize = cast<ArrayType>(GEPPtrType)->getNumElements();

    // We generate IR that loops over all array elements, loading each
    // and selecting the element that matches the blinded index. To do
    // so we need to:
    // - Split the current basic block containing the GEP
    // - Remove the current basic block's terminator
    // - Create basic blocks for the loop header, body, and increment
    // - Add a new terminator that branches to the loop header

    LLVMContext &Context = GEP->getContext();
    BasicBlock *LoopHeaderBB = GEP->getParent();
    Instruction *NextInst = GEP->getNextNode();

    // ensures splitBasicBlock always works
    assert(NextInst->getNextNode());
    assert(LoopHeaderBB->getTerminator());
    BasicBlock *AfterLoopBB = LoopHeaderBB->splitBasicBlock(NextInst,
                                                            GEPName + ".after.loop");

    // check we still have a terminator after split
    assert(LoopHeaderBB->getTerminator());
    LoopHeaderBB->getTerminator()->eraseFromParent();
    IRBuilder<> Builder(Context);

    BasicBlock *LoopBodyBB = BasicBlock::Create(Context,
                                                GEPName + ".loop.body",
                                                &F,
                                                AfterLoopBB);

    Builder.SetInsertPoint(LoopHeaderBB);

    // Load first element of array for use in loop body PHI
    Value *Zero = ConstantInt::get(Context, llvm::APInt(64, 0));
    auto GEPAddr = Builder.CreateGEP(GEPPtrType,
                                     GEP->getPointerOperand(),
                                     createGepIndexList(TaintedIdx, GEP, Zero),
                                     GEPName + ".element.zero");
    auto GEPLoad = Builder.CreateLoad(GEP->getResultElementType(), GEPAddr);

    // Insert an explicit fall through from the loop header to body.
    Builder.CreateBr(LoopBodyBB);

    // Populate the basic block for the loop body
    Builder.SetInsertPoint(LoopBodyBB);

    // Create PHI for loop induction variable
    auto InducVar = Builder.CreatePHI(TaintedIdx->getType(), 2, GEPName + ".induc.var");
    InducVar->addIncoming(Zero, LoopHeaderBB);

    // Create PHI for array element selection, set the initial value
    // as the element indexed at 0,..,0
    auto ArrElement = Builder.CreatePHI(GEP->getResultElementType(), 2, GEPName + ".cur.element");
    ArrElement->addIncoming(GEPLoad, LoopHeaderBB);

    GEPAddr = Builder.CreateGEP(GEPPtrType,
                                GEP->getPointerOperand(),
                                createGepIndexList(TaintedIdx, GEP, InducVar),
                                GEPName + ".blinded.addr");
    GEPLoad = Builder.CreateLoad(GEP->getResultElementType(), GEPAddr);
    auto SelectCmp = Builder.CreateCmp(CmpInst::ICMP_EQ, InducVar, TaintedIdx);
    auto SelectRes = Builder.CreateSelect(SelectCmp, GEPLoad, ArrElement);
    ArrElement->addIncoming(SelectRes, LoopBodyBB);

    // increment induction variable
    Value *One = ConstantInt::get(Context, llvm::APInt(64, 1));
    auto AddRes = Builder.CreateNSWAdd(InducVar, One);
    InducVar->addIncoming(AddRes, LoopBodyBB);

    // Branch to end after we iterate over all array elements
    Value *ArrSizeVal = ConstantInt::get(Context, llvm::APInt(64, ArrSize));
    auto LoopCondCmp = Builder.CreateCmp(CmpInst::ICMP_SLT, InducVar, ArrSizeVal);
    Builder.CreateCondBr(LoopCondCmp, LoopBodyBB, AfterLoopBB);

    updateGEPAddrUsers(GEP, ArrElement);

    GEP->eraseFromParent();
    MadeChange |= true;
  }

  return MadeChange;
}

static bool expandBlindedArrayAccesses(Function &F,
                                       TaintedRegisters::ConstValueSet TRSet) {
  bool MadeChange = false;
  SmallVector<GetElementPtrInst *, 16> WorkList;
  SmallVector<Value *, 16> TaintedIndices;

  // Populate a worklist of GEPs so we do not invalidate our iterator
  for (inst_iterator I = inst_begin(F), E = inst_end(F); I != E; ++I) {
    Instruction &Inst = *I;

    // if we encounter a blinded GEP with a blinded index we
    // consider it for expansion. We must check if the index is blinded
    // as the GEP could be blinded by some other means
    // e.g. a GEP into a blinded structure
    if (GetElementPtrInst *GEP = dyn_cast<GetElementPtrInst>(&Inst)) {
      if (TRSet.contains(GEP)) {
        // look for a blinded index
        for (auto Idx = GEP->idx_begin(); Idx != GEP->idx_end(); ++Idx) {
          if (TRSet.contains(*Idx)) {
            WorkList.push_back(GEP);
            TaintedIndices.push_back(*Idx);
            break; // Will need to be changed to handle multiple blinded indices
          }
        }
      }
    }
  }

  // For now we only handle one tainted index per array, multidimensional
  // arrays with multiple blinded indices are not yet handled
  if (TaintedIndices.size() != WorkList.size()) {
    return MadeChange;
  }

  while (!WorkList.empty()) {
    GetElementPtrInst *I = WorkList.pop_back_val();
    Value *TaintedIdx = TaintedIndices.pop_back_val();
    MadeChange |= expandBlindedArrayAccess(F, TaintedIdx, I);
  }

  return MadeChange;
}

/// This is the entry point for all transforms.
static bool runImpl(Function &F,
                    AAManager::Result &AA,
                    TaintedRegisters &TR,
                    BlindedDataUsage &BDU) {
  bool MadeChange = false;
  auto &TaintedRegs = TR.getTaintedRegisters(&AA);

  MadeChange |= expandBlindedArrayAccesses(F, TaintedRegs);

  F.dump();

  if (MadeChange) {
    // Invalidate the TaintedRegisters, the next analysis result
    // request will require re-running the analysis
    TR.releaseMemory();
  }

  // Verify our blinded data usage policies
  BDU.validateBlindedData(TR, AA);

  return MadeChange;
}

PreservedAnalyses BlindedInstrConversionPass::run(Function &F,
                                                  FunctionAnalysisManager &AM) {

  auto &AAResult = AM.getResult<AAManager>(F);
  auto &BasicAAResult = AM.getResult<BasicAA>(F);
  auto &SteensAAResult = AM.getResult<CFLSteensAA>(F);
  auto &TR = AM.getResult<TaintTrackingAnalysis>(F);
  auto &BDU = AM.getResult<BlindedDataUsageAnalysis>(F);

  // Add result of SteensAA and BasicAA to our AAManager
  AAResult.addAAResult(SteensAAResult);
  AAResult.addAAResult(BasicAAResult);

  if (!runImpl(F, AAResult, TR, BDU)) {
    // No changes, all analyses are preserved.
    return PreservedAnalyses::all();
  }

  PreservedAnalyses PA;
  PA.preserve<AAManager>();
  PA.preserve<BasicAA>();
  PA.preserve<CFLSteensAA>();

  return PA;
}
