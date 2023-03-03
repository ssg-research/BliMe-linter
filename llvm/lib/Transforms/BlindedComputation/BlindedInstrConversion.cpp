#include "llvm/Transforms/BlindedComputation/BlindedInstrConversion.h"
#include <llvm/IR/DebugLoc.h>
#include <llvm/IR/DebugInfoMetadata.h>
#include "llvm/Analysis/ScalarEvolutionExpressions.h"

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

// returns 0 if we cannot stride this array
// else the total stride number
static uint64_t getTotalStride(Value* TaintedIdx,
                               GetElementPtrInst *GEP,
                               int& ValidForTrans,
                               FunctionAnalysisManager& FAM,
                               Function &F) {
  int GEPIdxPos = -1;
  SmallVector<Value *, 4> NewIndices;
  for (auto Idx = GEP->idx_begin(); Idx != GEP->idx_end(); ++Idx) {
    if (*Idx == TaintedIdx) {
      GEPIdxPos = Idx - GEP->idx_begin();
      break;
    }
    else {
      NewIndices.push_back(*Idx);
    }
  }
  if (NewIndices.size() == 0) {
    // errs() << GEP->getFunction()->getName() << "\n";
    // const llvm::DebugLoc &debugInfo = GEP->getDebugLoc();
    // llvm::StringRef directory = debugInfo->getDirectory();
    // llvm::StringRef filePath = debugInfo->getFilename();
    // int line = debugInfo->getLine();
    // int column = debugInfo->getColumn();
    // errs() << "DEBUG INFO:" << "\n";
    // errs() << "FilePath: " << filePath << "\n";
    // errs() << "line: " << line << "\n";
    // errs() << "column: " << column << "\n";
    // assert(false && "need to check this special case");
  }
  // assert(GEPIdxPos != -1 && "GetTotalStride: GEPIdxPos == -1: cannot find tainted idx in the GEP");
  // errs() << "GEPIdxPos: " << GEPIdxPos << "\n";

  Type* arrType = GetElementPtrInst::getIndexedType(GEP->getSourceElementType(), NewIndices);

  // TODO: currently we only consider the array size.

  if (arrType->isArrayTy()) {
    const uint64_t ArrSize = cast<ArrayType>(arrType)->getNumElements();
    ValidForTrans = 1;
    return ArrSize;
  }
  else {
    errs() << GEP->getFunction()->getName() << "\n";
    // assert(false && "unable to handle this type for expansion");
  }

  // const Function& F = GEP->getFunction()->getFunction();
  // Function& NF = const_cast<Function&>(F);
  // auto SCEVResult = FAM.getResult<ScalarEvolutionAnalysis>(NF);

  ValidForTrans = 0;
  return 0;
}

bool BlindedInstrConversionPass::expandBlindedArrayAccess(Value *TaintedIdx,
                                     GetElementPtrInst *GEP,
                                     LoadInst *LI, vector<LoadInst*>& LoadWorkList,
                                     FunctionAnalysisManager& FAM,
                                     Function &F) {
  bool MadeChange = false;

  Type *GEPPtrType = GEP->getSourceElementType();
  auto GEPName = GEP->getPointerOperand()->getName();
  int canExpand = 0;
  const uint64_t ArrSize = getTotalStride(TaintedIdx, GEP, canExpand, FAM, F);
  errs() << "Can expand? " << canExpand << "\n";
  APInt ArrSizeAPInt = APInt(64, ArrSize);

  // if (!canExpand) {
  //   auto &SE = FAM.getResult<ScalarEvolutionAnalysis>(F);
  //   if (SE.isSCEVable(TaintedIdx->getType())) {
  //     const SCEV* SC = SE.getSCEV(TaintedIdx);
  //     APInt CR = SE.getUnsignedRange(SC).getSignedMax();
  //     errs() << "\nSigned Max: " << CR << "\n";
  //     if (CR == 0 || CR == INT_MAX) { return MadeChange; }
  //     canExpand = true;
  //   }
  // }


  if (canExpand) {
    // We generate IR that loops over all array elements, loading each
    // and selecting the element that matches the blinded index. To do
    // so we need to:
    // - Split the current basic block containing the GEP
    // - Remove the current basic block's terminator
    // - Create basic blocks for the loop header, body, and increment
    // - Add a new terminator that branches to the loop header

  // const Function& F = GEP->getFunction()->getFunction();
  // Function& NF = const_cast<Function&>(F);
  // auto SCEVResult = FAM.getResult<ScalarEvolutionAnalysis>(NF);
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
                                                GEP->getFunction(),
                                                AfterLoopBB);

    Builder.SetInsertPoint(LoopHeaderBB);

    // Load first element of array for use in loop body PHI
    Value *Zero = ConstantInt::get(Context, llvm::APInt(64, 0));
    auto GEPAddr = Builder.CreateGEP(GEPPtrType,
                                     GEP->getPointerOperand(),
                                     createGepIndexList(TaintedIdx, GEP, Zero),
                                     GEPName + ".element.zero");
    // Pointer bitcast
    // auto GEPPtrType = GEP->getResultElementType();
    auto LIResultType = LI->getType();
    Value* LoadAddr = GEPAddr;
    if (GEP->getResultElementType() != LIResultType) {
      // errs() << "IF TYPE MISMATCH:" << "\n";
      auto BitCastInst = Builder.CreateBitCast(LoadAddr, LI->getPointerOperandType());
      LoadAddr = BitCastInst;
    }
    // errs() << "LIPtrType: " << *LIResultType<< "\n";
    // errs() << "GEPPtrType: " << *(GEP->getResultElementType()) << "\n";
    // errs() << "LoadAddr: " << *LoadAddr << "\n";
    auto GEPLoad = Builder.CreateLoad(LIResultType, LoadAddr);
    LoadWorkList.push_back(static_cast<LoadInst*>(GEPLoad));

    // Insert an explicit fall through from the loop header to body.
    Builder.CreateBr(LoopBodyBB);

    // Populate the basic block for the loop body
    Builder.SetInsertPoint(LoopBodyBB);

    // Create PHI for loop induction variable
    auto InducVar = Builder.CreatePHI(TaintedIdx->getType(), 2, GEPName + ".induc.var");
    InducVar->addIncoming(Zero, LoopHeaderBB);

    // Create PHI for array element selection, set the initial value
    // as the element indexed at 0,..,0
    auto ArrElement = Builder.CreatePHI(LIResultType, 2, GEPName + ".cur.element");
    ArrElement->addIncoming(GEPLoad, LoopHeaderBB);

    // errs() << "GEPPtrType: " << *GEPPtrType << "\n";
    // errs() << "Pointer Operand: " << *(GEP->getPointerOperand()) << "\n";

    GEPAddr = Builder.CreateGEP(GEPPtrType,
                                GEP->getPointerOperand(),
                                createGepIndexList(TaintedIdx, GEP, InducVar),
                                GEPName + ".blinded.addr");
    LoadAddr = GEPAddr;
    if (GEP->getResultElementType() != LIResultType) {
      auto BitCastInst = Builder.CreateBitCast(LoadAddr, LI->getPointerOperandType());
      LoadAddr = BitCastInst;
    }
    GEPLoad = Builder.CreateLoad(LIResultType, LoadAddr);
    LoadWorkList.push_back(static_cast<LoadInst*>(GEPLoad));
    auto SelectCmp = Builder.CreateCmp(CmpInst::ICMP_EQ, InducVar, TaintedIdx);
    auto SelectRes = Builder.CreateSelect(SelectCmp, GEPLoad, ArrElement);
    ArrElement->addIncoming(SelectRes, LoopBodyBB);

    // increment induction variable
    Value *One = ConstantInt::get(Context, llvm::APInt(64, 1));
    auto AddRes = Builder.CreateNSWAdd(InducVar, One);
    InducVar->addIncoming(AddRes, LoopBodyBB);

    // Branch to end after we iterate over all array elements
    Value *ArrSizeVal = ConstantInt::get(Context, ArrSizeAPInt);
    auto LoopCondCmp = Builder.CreateCmp(CmpInst::ICMP_SLT, InducVar, ArrSizeVal);
    Builder.CreateCondBr(LoopCondCmp, LoopBodyBB, AfterLoopBB);

    // updateGEPAddrUsers(GEP, SelectRes);
    LI->replaceAllUsesWith(SelectRes);
    LI->eraseFromParent();
    if (GEP->user_empty()) {
      GEP->eraseFromParent();
    }
    MadeChange |= true;
  }

  return MadeChange;
}

bool BlindedInstrConversionPass::expandBlindedArrayAccess(Value *TaintedIdx,
                                     GetElementPtrInst *GEP,
                                     StoreInst *SI, vector<StoreInst*>& StoreWorkList) {
  bool MadeChange = false;

  Type *GEPPtrType = GEP->getSourceElementType();
  auto GEPName = GEP->getPointerOperand()->getName();
  errs() << "GEP: " << *GEP << "\n";
  errs() << "store: " << *SI << "\n";

  if (GEPPtrType->isArrayTy()) {
    // TODO: to 'real' element num
    const uint64_t ArrSize = cast<ArrayType>(GEPPtrType)->getNumElements();

    // We generate IR that loops over all array elements, loading each
    // and selecting the element that matches the blinded index. To do
    // so we need to:
    // - Split the current basic block containing the GEP
    // - Remove the current basic block's terminator
    // - Create basic blocks for the loop header, body, and increment
    // - Add a new terminator that branches to the loop header

    LLVMContext &Context = SI->getContext();
    BasicBlock *LoopHeaderBB = SI->getParent();
    Instruction *NextInst = SI->getNextNode();

    // ensures splitBasicBlock always works
    // assert(NextInst->getNextNode());
    assert(LoopHeaderBB->getTerminator());
    BasicBlock *AfterLoopBB = LoopHeaderBB->splitBasicBlock(NextInst,
                                                            GEPName + ".store.after.loop");

    // check we still have a terminator after split
    assert(LoopHeaderBB->getTerminator());
    LoopHeaderBB->getTerminator()->eraseFromParent();
    IRBuilder<> Builder(Context);

    BasicBlock *LoopBodyBB = BasicBlock::Create(Context,
                                                GEPName + ".store.loop.body",
                                                SI->getFunction(),
                                                AfterLoopBB);

    Builder.SetInsertPoint(LoopHeaderBB);

    // Load first element of array for use in loop body PHI
    Value *Zero = ConstantInt::get(Context, llvm::APInt(64, 0));
    auto GEPAddr = Builder.CreateGEP(GEPPtrType,
                                     GEP->getPointerOperand(),
                                     createGepIndexList(TaintedIdx, GEP, Zero),
                                     GEPName + ".store.element.zero");
    // Pointer bitcast
    // auto GEPPtrType = GEP->getResultElementType();
    auto SIValueType = SI->getOperand(0)->getType();
    Value* StoreAddr = GEPAddr;
    if (GEP->getResultElementType() != SIValueType) {
      // errs() << "IF TYPE MISMATCH:" << "\n";
      auto BitCastInst = Builder.CreateBitCast(StoreAddr, SI->getPointerOperandType());
      StoreAddr = BitCastInst;
    }
    // errs() << "LIPtrType: " << *LIResultType<< "\n";
    // errs() << "GEPPtrType: " << *(GEP->getResultElementType()) << "\n";
    // errs() << "LoadAddr: " << *LoadAddr << "\n";
    auto GEPLoad = Builder.CreateLoad(SIValueType, StoreAddr);
    auto SelectCmpStore = Builder.CreateCmp(CmpInst::ICMP_EQ, Zero, TaintedIdx);
    auto SelectResStore = Builder.CreateSelect(SelectCmpStore, SI->getOperand(0), GEPLoad);
    auto GEPStore = Builder.CreateStore(SelectResStore, StoreAddr);
    StoreWorkList.push_back(static_cast<StoreInst*>(GEPStore));

    // Insert an explicit fall through from the loop header to body.
    Builder.CreateBr(LoopBodyBB);

    // Populate the basic block for the loop body
    Builder.SetInsertPoint(LoopBodyBB);

    // Create PHI for loop induction variable
    auto InducVar = Builder.CreatePHI(TaintedIdx->getType(), 2, GEPName + ".store.induc.var");
    InducVar->addIncoming(Zero, LoopHeaderBB);

    // Create PHI for array element selection, set the initial value
    // as the element indexed at 0,..,0
    // auto ArrElement = Builder.CreatePHI(LIResultType, 2, GEPName + ".cur.element");
    // ArrElement->addIncoming(GEPLoad, LoopHeaderBB);


    GEPAddr = Builder.CreateGEP(GEPPtrType,
                                GEP->getPointerOperand(),
                                createGepIndexList(TaintedIdx, GEP, InducVar),
                                GEPName + ".store.blinded.addr");
    StoreAddr = GEPAddr;
    if (GEP->getResultElementType() != SIValueType) {
      // errs() << "IF TYPE MISMATCH:" << "\n";
      auto BitCastInst = Builder.CreateBitCast(StoreAddr, SI->getPointerOperandType());
      StoreAddr = BitCastInst;
    }
    // errs() << "LIPtrType: " << *LIResultType<< "\n";
    // errs() << "GEPPtrType: " << *(GEP->getResultElementType()) << "\n";
    // errs() << "LoadAddr: " << *LoadAddr << "\n";
    GEPLoad = Builder.CreateLoad(SIValueType, StoreAddr);
    SelectCmpStore = Builder.CreateCmp(CmpInst::ICMP_EQ, InducVar, TaintedIdx);
    SelectResStore = Builder.CreateSelect(SelectCmpStore, SI->getOperand(0), GEPLoad);
    GEPStore = Builder.CreateStore(SelectResStore, StoreAddr);
    // StoreWorkList.push_back(static_cast<StoreInst*>(GEPStore));

    // increment induction variable
    Value *One = ConstantInt::get(Context, llvm::APInt(64, 1));
    auto AddRes = Builder.CreateNSWAdd(InducVar, One);
    InducVar->addIncoming(AddRes, LoopBodyBB);

    // Branch to end after we iterate over all array elements
    Value *ArrSizeVal = ConstantInt::get(Context, llvm::APInt(64, ArrSize));
    auto LoopCondCmp = Builder.CreateCmp(CmpInst::ICMP_SLT, InducVar, ArrSizeVal);
    Builder.CreateCondBr(LoopCondCmp, LoopBodyBB, AfterLoopBB);

    // updateGEPAddrUsers(GEP, SelectRes);
    // SI->replaceAllUsesWith(SelectRes);
    SI->eraseFromParent();
    if (GEP->user_empty()) {
      GEP->eraseFromParent();
    }
    MadeChange |= true;
  }

  return MadeChange;
}

bool BlindedInstrConversionPass::expandBlindedArrayAccesses(Function &F,
                                       TaintResult &RT, FunctionAnalysisManager& FAM) {
// TODO: Add gep into worklist ->
  std::vector<LoadInst*> loadWorkList;
  std::vector<StoreInst*> storeWorkList;
  // std::set<StoreInst*> visited;

  // iterate through all the instructions in a function
  // until we reaches tainted instructions
  // everything's all the same
  for (inst_iterator I = inst_begin(F), E = inst_end(F); I != E; ++I) {
    Instruction* Inst = &*I;
    if (LoadInst *LI = dyn_cast<LoadInst>(Inst)) {
      if (RT.TaintedValues.count(LI->getPointerOperand())){
        loadWorkList.push_back(LI);
      }
    }
    else if (StoreInst *SI = dyn_cast<StoreInst>(Inst)) {
      if (RT.TaintedValues.count(SI->getPointerOperand())) {
        storeWorkList.push_back(SI);
      }
    }
  }

  while (!storeWorkList.empty()) {
    auto SI = storeWorkList.back();
    storeWorkList.pop_back();
    // if (visited.count(SI)) {
    //   continue;
    // }
    // visited.insert(SI);
    Value* PO = SI->getPointerOperand();

    if (GetElementPtrInst* GEPInstr = dyn_cast<GetElementPtrInst>(PO)) {
      for (auto Idx = GEPInstr->idx_begin(); Idx != GEPInstr->idx_end(); Idx++) {
        if (RT.TaintedValues.count(*Idx)) {
          GetElementPtrInst* NGEPInstr = const_cast<GetElementPtrInst*>(GEPInstr);
          expandBlindedArrayAccess(*Idx, NGEPInstr, SI, storeWorkList);
          break;
        }
      }
    }
  }
  int ctr = 0;
  while (!loadWorkList.empty())
  {
    auto LI = loadWorkList.back();
    loadWorkList.pop_back();
    Value* PO = LI->getPointerOperand();
    errs() << "ctr: " << ctr++ << " LI " << *LI << "\n";

    if (GetElementPtrInst* GEPInstr = dyn_cast<GetElementPtrInst>(PO)) {
      errs() << "GEP " << *GEPInstr << "\n";
      for (auto Idx = GEPInstr->idx_begin(); Idx != GEPInstr->idx_end(); Idx++) {
        // if (GEPInstr->getNumIndices() == 1) {
        //   const llvm::DebugLoc &debugInfo = LI->getDebugLoc();
        //   llvm::StringRef directory = debugInfo->getDirectory();
        //   llvm::StringRef filePath = debugInfo->getFilename();
        //   int line = debugInfo->getLine();
        //   int column = debugInfo->getColumn();
        //   errs() << "DEBUG INFO:" << "\n";
        //   errs() << "FilePath: " << filePath << "\n";
        //   errs() << "line: " << line << "\n";
        //   errs() << "column: " << column << "\n";
        //   RT.backtrace(GEPInstr);
        // }
        if (RT.TaintedValues.count(*Idx)) {
          int valft = 0;
          // if (getTotalStride(&*Idx, GEP, valft));
          errs() << "\t" << "Idx: " << *Idx << "\n";
          GetElementPtrInst* NGEPInstr = const_cast<GetElementPtrInst*>(GEPInstr);
          expandBlindedArrayAccess(*Idx, NGEPInstr, LI, loadWorkList, FAM, F);
          break;
        }
      }
    }
    else if (BitCastInst* BitCastInstr = dyn_cast<BitCastInst>(PO)) {
      errs() << "BitCast " << *BitCastInstr << "\n";
      Value* BCOp = BitCastInstr->getOperand(0);
      if (GetElementPtrInst* GEPInstr = dyn_cast<GetElementPtrInst>(BCOp)) {
        for (auto Idx = GEPInstr->idx_begin(); Idx != GEPInstr->idx_end(); Idx++) {
          if (RT.TaintedValues.count(*Idx)) {
            GetElementPtrInst* NGEPInstr = const_cast<GetElementPtrInst*>(GEPInstr);
            expandBlindedArrayAccess(*Idx, NGEPInstr, LI, loadWorkList, FAM, F);
          }
        }
      }
    }
  }

  return true;
}

bool BlindedInstrConversionPass::linearizeSelectInstructions(Function &F) {
  SmallVector<Instruction*,8> RemoveList;

  // so, we are converting all the select even if it is not tainted?
  for (Instruction &I : inst_range(inst_begin(F), inst_end(F))) {
    if (auto *S = dyn_cast<SelectInst>(&I)) {
      auto *const CondVal = S->getCondition();

      assert(CondVal->getType()->isIntegerTy() && "expected cond to be int");
      assert(1 == cast<IntegerType>(CondVal->getType())->getScalarSizeInBits()
          && "expected 1-bit cond value!");

      auto *const ResultType = S->getType();
      const bool ResultTypeIsPointer = ResultType->isPointerTy();
      auto ResultTypeSize =
          ResultTypeIsPointer
              ? F.getParent()->getDataLayout().getPointerSizeInBits()
              : ResultType->getPrimitiveSizeInBits();

      assert(ResultTypeSize > 0 && "Got non-positive size for the result");

      auto *MaskType = IntegerType::getIntNTy(F.getContext(), ResultTypeSize);

      // Insert new stuff before the select (which we will remove later)
      IRBuilder<> Builder(S);

      // Need to special case PointerType Values
      auto *TrueValue = ResultTypeIsPointer
              ? Builder.CreatePtrToInt(S->getTrueValue(), MaskType)
              : S->getTrueValue();
      auto *FalseValue = ResultTypeIsPointer
              ? Builder.CreatePtrToInt(S->getFalseValue(), MaskType)
              : S->getFalseValue();

      assert(TrueValue->getType() == FalseValue->getType() && "Type mismatch");

      // TrueValue->dump();
      if (!TrueValue->getType()->isIntegerTy()) {
        TrueValue = Builder.CreateBitCast(TrueValue,MaskType);
        FalseValue = Builder.CreateBitCast(FalseValue,MaskType);
      }

      assert(TrueValue->getType()->isIntegerTy() && "expected TrueValue to be int");

      // Based on <https://github.com/veorq/cryptocoding#solution-1>
      auto *NegCondVal = Builder.CreateNeg(CondVal);
      auto *MaskVal = Builder.CreateSExtOrBitCast(NegCondVal,MaskType);
      auto *TmpXor = Builder.CreateXor(TrueValue, FalseValue);
      auto *TmpXorMasked = Builder.CreateAnd(MaskVal, TmpXor);
      auto *TmpResVal = Builder.CreateXor(TmpXorMasked, FalseValue);
      auto *Result = TmpResVal;

      if (ResultTypeIsPointer)
        Result = Builder.CreateIntToPtr(TmpResVal, ResultType);
      else if (Result->getType() != S->getType())
        Result = Builder.CreateBitCast(Result,S->getType());

      S->replaceAllUsesWith(Result);
      RemoveList.push_back(S);
    }
  }

  for (auto I : RemoveList)
    I->eraseFromParent();

  return !RemoveList.empty();
}

void BlindedInstrConversionPass::transform(Module& M, ModuleAnalysisManager& AM) {
  auto &TTResult = AM.getResult<BlindedTaintTracking>(M);
  FunctionAnalysisManager &FAM =
      AM.getResult<FunctionAnalysisManagerModuleProxy>(M).getManager();

  for (Function &F : M) {
    if (F.isDeclaration()) {
      continue;
    }
    expandBlindedArrayAccesses(F, TTResult, FAM);
    linearizeSelectInstructions(F);
  }
  for (auto I : TTResult.BlndBr) {
    if (const BranchInst* BrInst = dyn_cast<BranchInst>(I)) {
      BranchInst* NBrInst = const_cast<BranchInst*>(BrInst);
      LLVMContext &cont = NBrInst->getContext();
      MDNode *N = MDNode::get(cont, ConstantAsMetadata::get(ConstantInt::get(cont, APInt(sizeof(long)*8, true, true))));
      NBrInst->setMetadata("t", N);
    }
  }
  AM.invalidate(M, PreservedAnalyses::none());

}

void BlindedInstrConversionPass::validate(Module& M, ModuleAnalysisManager& AM) {
  auto &BDU = AM.getResult<BlindedDataUsageAnalysis>(M);
  // Verify our blinded data usage policies
  if(!BDU.violations().empty()){
      for (auto &V : BDU.violations()) {
        // V.first->print(errs());
        // const llvm::DebugLoc &debugInfo = ((llvm::Instruction*)(V.first))->getDebugLoc();
        // errs() << "\n" <<debugInfo->getDirectory() << "/" << debugInfo->getFilename() << ":" << debugInfo->getLine() << ":" << debugInfo->getColumn() << ":\n";
        // errs() << V.second.str().c_str() << "\n";
      }
      // llvm_unreachable("validateBlindedData returns 'false'");
  }

  auto &TTResult = AM.getResult<BlindedTaintTracking>(M);

  for (Function &F : M) {
    if (F.isDeclaration()) {
      continue;
    }

    for (auto Arg = F.arg_begin(); Arg < F.arg_end(); ++Arg) {
      if (Arg->hasAttribute(Attribute::Blinded)) {
          Arg->removeAttr(Attribute::Blinded);
      }
    }
  }
  for (auto I : TTResult.BlndBr) {
    if (const BranchInst* BrInst = dyn_cast<BranchInst>(I)) {
      BranchInst* NBrInst = const_cast<BranchInst*>(BrInst);
      LLVMContext &cont = NBrInst->getContext();
      MDNode *N = MDNode::get(cont, ConstantAsMetadata::get(ConstantInt::get(cont, APInt(sizeof(long)*8, true, true))));
      NBrInst->setMetadata("t", N);
    }
  }
  for (auto I : TTResult.BlndMemOp) {
    if (const Instruction* MemOpInstr = dyn_cast<Instruction>(I)) {
      Instruction* NMemOpInstr = const_cast<Instruction*>(MemOpInstr);
      LLVMContext &cont = NMemOpInstr->getContext();
      MDNode *N = MDNode::get(cont, ConstantAsMetadata::get(ConstantInt::get(cont, APInt(sizeof(long)*8, true, true))));
      NMemOpInstr->setMetadata("t", N);
    }
  }
}


PreservedAnalyses BlindedInstrConversionPass::run(Module &M,
                                                  ModuleAnalysisManager &AM) {
  FunctionAnalysisManager &FAM =
      AM.getResult<FunctionAnalysisManagerModuleProxy>(M).getManager();

  auto FC = BlindedTTFC();
  FC.FuncCloning(M, AM);
  AM.invalidate(M, PreservedAnalyses::none());

  PassInstrumentation PI = AM.getResult<PassInstrumentationAnalysis>(M);

  transform(M, AM);
  validate(M, AM);

  // errs() << "finished building TT...\n";

  PreservedAnalyses PA = PreservedAnalyses::all();
  // std::unordered_map<const Function*, SmallPtrSet<Value*, 4>> TaintInfo;

  // CallGraph CG = CallGraph(M);
  // FunctionWorkList.clear();

  // for (Function &F : M) {
  //   if (F.isDeclaration()) {
  //     continue;
  //   }
  //   FunctionWorkList.push_back(&F);
  //   std::vector<Function*> CallingFuncVec;
  //   DependentFunctions[&F] = CallingFuncVec;
  // }

  // for (auto ite = CG.begin(); ite != CG.end(); ite++) {
  //   CallGraphNode* CGN = ite->second.get();
  //   const Function* CallingFunc = ite->first;

  //   if (CallingFunc && !CallingFunc->isDeclaration()) {

  //     // errs() << "analyzing: " << CallingFunc->getName() << "\n";
  //     // errs() << CGN->size() << "\n\n";

  //     for (unsigned int i = 0; i < CGN->size(); i++) {
  //       Function* CurrentCalledFunc = ((*CGN)[i])->getFunction();
  //       if (!CurrentCalledFunc)
  //         continue;
  //       if (CurrentCalledFunc->isDeclaration())
  //         continue;
  //       // errs() << CurrentCalledFunc->getName() << "\n";
  //       DependentFunctions[CallingFunc].push_back(CurrentCalledFunc);
  //       TaintTrackingResult[CallingFunc] = -1;
  //     }
  //     // errs() << "\n\n";
  //   }
  // }

  // while (!FunctionWorkList.empty()) {
  //   Function *F = FunctionWorkList.back();
  //   FunctionWorkList.pop_back();

  //   if (F->isDeclaration())
  //     continue;

  //   if (!PI.runBeforePass<Function>(*this, *F))
  //     continue;

  //   PreservedAnalyses PassPA;
  //   {
  //     SmallSet<Function *, 8> VisitedFunctions;
  //     TimeTraceScope TimeScope(name(), F->getName());
  //     PassPA = run(*F, FAM, VisitedFunctions);
  //   }

  //   PI.runAfterPass(*this, *F);

  //   FAM.invalidate(*F, PassPA);
  //   PA.intersect(std::move(PassPA));
  // }

  return PA;

}
