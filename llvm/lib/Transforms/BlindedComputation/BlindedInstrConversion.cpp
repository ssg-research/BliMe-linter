#include "llvm/Transforms/BlindedComputation/BlindedInstrConversion.h"
#include "llvm/ADT/SetVector.h"
#include "llvm/ADT/APInt.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/ValueMap.h"
#include "llvm/Analysis/TaintTracking.h"
#include "llvm/Analysis/BasicAliasAnalysis.h"
#include "llvm/Analysis/BlindedDataUsage.h"
#include "llvm/Analysis/CFLSteensAliasAnalysis.h"
#include "llvm/Transforms/Utils/Cloning.h"

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

    updateGEPAddrUsers(GEP, SelectRes);

    GEP->eraseFromParent();
    MadeChange |= true;
  }

  return MadeChange;
}

static bool expandBlindedArrayAccesses(Function &F,
                                       AAManager::Result &AA,
                                       TaintedRegisters &TR) {
  auto &TRSet = TR.getTaintedRegisters(&AA);

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
    return false;
  }

  bool MadeChange = false;

  while (!WorkList.empty()) {
    GetElementPtrInst *I = WorkList.pop_back_val();
    Value *TaintedIdx = TaintedIndices.pop_back_val();
    MadeChange |= expandBlindedArrayAccess(F, TaintedIdx, I);
  }

  if (MadeChange) {
    // Invalidate the TaintedRegisters, the next analysis result
    // request will require re-running the analysis
    TR.releaseMemory();
  }

  return MadeChange;
}

/// Ensure CallBase calls a function with the ParamNos args blinded
///
/// This will potentially also generate a new copy of the called function F,
/// unless the function already conforms to the required blindedness properties.
bool BlindedInstrConversionPass::propagateBlindedArgumentFunctionCall(CallBase &CB,
                                                                      Function &F,
                                                                      ArrayRef<unsigned> ParamNos,
                                                                      FunctionAnalysisManager &AM,
                                                                      SmallSet<Function *, 8> &VisitedFunctions) {
  if (F.size() == 0) {
    // assume functions outside of this module will not return tainted values
    return false;
  }

  if (F.getFunctionType()->isVarArg()) {
    // assume that vararg functions will return tainted values
    // TODO: we can do something more sophisticated here
    return true;
  }

  unsigned BlindedParamIdentifier = 0;
  for (unsigned ParamNo : ParamNos) BlindedParamIdentifier |= 1 << ParamNo;
  Twine BlindedFunctionName = F.getName() + "." + Twine(BlindedParamIdentifier);

  SmallString<128> BlindedFunctionNameVector;
  Function *BlindedFunction = F.getParent()->getFunction(BlindedFunctionName.toStringRef(BlindedFunctionNameVector));

  if (VisitedFunctions.count(BlindedFunction)) {
    // we have a cycle, assume the return value from the function being called will be tainted
    return true;
  }

  if (!BlindedFunction) {
    // blinded function does not already exist, create it
    ValueMap<const Value *, WeakTrackingVH> Map;
    std::vector<Type*> ArgTypes;
    for (const Argument &I : F.args()) ArgTypes.push_back(I.getType());
    FunctionType *FTy = FunctionType::get(F.getFunctionType()->getReturnType(), ArgTypes, F.getFunctionType()->isVarArg());
    BlindedFunction = Function::Create(FTy, F.getLinkage(), F.getAddressSpace(), BlindedFunctionName, F.getParent());

    Function::arg_iterator DestI = BlindedFunction->arg_begin();
    for (const Argument &I : F.args()) {
      DestI->setName(I.getName());
      Map[&I] = &*DestI++;
    }

    SmallVector<ReturnInst *, 8> Returns;
    CloneFunctionInto(BlindedFunction, &F, Map, F.getSubprogram() != nullptr, Returns, "", nullptr);

    for (unsigned ParamNo : ParamNos) {
      BlindedFunction->addParamAttr(ParamNo, Attribute::Blinded);
    }

    AM.invalidate(*BlindedFunction, run(*BlindedFunction, AM, VisitedFunctions));
  }

  CB.setCalledFunction(BlindedFunction);

  return BlindedFunction->hasFnAttribute(Attribute::Blinded);
}

/// Check calls in F to make sure they call blinded permutations of the callee
///
/// When necessary, this will also automatically create the necessary new
/// function permutations.
void BlindedInstrConversionPass::propagateBlindedArgumentFunctionCalls(
    Function &F, AAManager::Result &AA, TaintedRegisters &TR,
    FunctionAnalysisManager &AM, SmallSet<Function *, 8> &VisitedFunctions) {
  while (true) {
    bool KeepGoing = false;
    const auto *TRSet = &TR.getTaintedRegisters(&AA);

    for (inst_iterator I = inst_begin(F), E = inst_end(F); I != E; ++I) {
      Instruction &Inst = *I;

      // Check all calls in the function
      if (CallBase *CB = dyn_cast<CallBase>(&Inst)) {
        if (Function *CF = CB->getCalledFunction()) {
          // look for blinded arguments going to non-blinded paramaters
          SmallVector<unsigned, 8> BlindedParams;

          for (auto &Arg : CB->args()) {
            unsigned n = Arg.getOperandNo();
            if (TRSet->contains(Arg) &&
                !CF->hasParamAttribute(n, Attribute::Blinded)) {
              BlindedParams.push_back(n);
            }
          }

          bool IsReturnBlinded = (BlindedParams.empty()
                   ? CF->hasFnAttribute(Attribute::Blinded)
                   : propagateBlindedArgumentFunctionCall(
                         *CB, *CF, BlindedParams, AM, VisitedFunctions));

          if (TRSet->contains(CB) && !IsReturnBlinded) {
            TR.releaseMemory();
            KeepGoing = true;
            break;
          } else if (!TRSet->contains(CB) && IsReturnBlinded) {
            TR.explicitlyTaint(CB);
            KeepGoing = true;
            break;
          }
        } else {
          dbgs() << "Skipping indirect function call.\n";
        }
      } // if (Callbase...
    } // for (inst_iterator...

    if (!KeepGoing) break;
  }
}

static bool changeBlindedFunctionAttr(Function &F, const bool newVal) {
  const bool wasSet = F.hasFnAttribute(Attribute::Blinded);

  if (wasSet != newVal) {
    if (newVal) {
      F.addFnAttr(Attribute::Blinded);
    } else {
      F.removeFnAttr(Attribute::Blinded);
    }
  }

  return wasSet != newVal;
}

static bool markBlindedIfNecessary(Function &F, AAManager::Result &AA, TaintedRegisters &TR) {
  auto &TRSet = TR.getTaintedRegisters(&AA);
  for (inst_iterator I = inst_begin(F), E = inst_end(F); I != E; ++I) {
    Instruction &Inst = *I;
    if (isa<ReturnInst>(&Inst) && TRSet.contains(&Inst)) {
      return changeBlindedFunctionAttr(F, true);
    }
  }
  return changeBlindedFunctionAttr(F, false);
}

/// This is the entry point for all transforms.
bool BlindedInstrConversionPass::runImpl(Function &F,
                    AAManager::Result &AA,
                    TaintedRegisters &TR,
                    BlindedDataUsage &BDU,
                    FunctionAnalysisManager &AM,
                    SmallSet<Function *, 8> &VisitedFunctions) {
  VisitedFunctions.insert(&F);

  bool MadeChange = false;

  MadeChange |= expandBlindedArrayAccesses(F, AA, TR);
  propagateBlindedArgumentFunctionCalls(F, AA, TR, AM, VisitedFunctions);
  MadeChange |= expandBlindedArrayAccesses(F, AA, TR);
  MadeChange |= markBlindedIfNecessary(F, AA, TR);

  // Verify our blinded data usage policies
  BDU.validateBlindedData(TR, AA);

  VisitedFunctions.erase(&F);

  return MadeChange;
}

PreservedAnalyses BlindedInstrConversionPass::run(Function &F,
                                                  FunctionAnalysisManager &AM,
                                                  SmallSet<Function *, 8> &VisitedFunctions) {
  auto &AAResult = AM.getResult<AAManager>(F);
  auto &BasicAAResult = AM.getResult<BasicAA>(F);
  auto &SteensAAResult = AM.getResult<CFLSteensAA>(F);
  auto &TR = AM.getResult<TaintTrackingAnalysis>(F);
  auto &BDU = AM.getResult<BlindedDataUsageAnalysis>(F);

  // Add result of SteensAA and BasicAA to our AAManager
  AAResult.addAAResult(SteensAAResult);
  AAResult.addAAResult(BasicAAResult);

  if (!runImpl(F, AAResult, TR, BDU, AM, VisitedFunctions)) {
    // No changes, all analyses are preserved.
    return PreservedAnalyses::all();
  }

  PreservedAnalyses PA;
  PA.preserve<AAManager>();
  PA.preserve<BasicAA>();
  PA.preserve<CFLSteensAA>();

  return PA;
}

PreservedAnalyses BlindedInstrConversionPass::run(Module &M,
                                                  ModuleAnalysisManager &AM) {
  FunctionAnalysisManager &FAM =
      AM.getResult<FunctionAnalysisManagerModuleProxy>(M).getManager();

  PassInstrumentation PI = AM.getResult<PassInstrumentationAnalysis>(M);

  PreservedAnalyses PA = PreservedAnalyses::all();

  SmallVector<Function *, 8> WorkList;
  for (Function &F : M) {
    WorkList.push_back(&F);
  }

  while (!WorkList.empty()) {
    Function *F = WorkList.pop_back_val();

    if (F->isDeclaration())
      continue;

    if (!PI.runBeforePass<Function>(*this, *F))
      continue;

    PreservedAnalyses PassPA;
    {
      SmallSet<Function *, 8> VisitedFunctions;
      TimeTraceScope TimeScope(name(), F->getName());
      PassPA = run(*F, FAM, VisitedFunctions);
    }

    PI.runAfterPass(*this, *F);

    FAM.invalidate(*F, PassPA);
    PA.intersect(std::move(PassPA));
  }

  return PA;
}
