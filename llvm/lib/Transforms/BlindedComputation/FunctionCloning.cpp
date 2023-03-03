#include "llvm/Transforms/BlindedComputation/FunctionCloning.h"

using namespace::llvm;

void BlindedTTFC::FuncCloning(Module &M, ModuleAnalysisManager& AM) {

  bool changed = false;
  static int limit = 0;
  do {
    auto& TR = AM.getResult<BlindedTaintTracking>(M);
    changed = false;

    vector<Function*> WorkList;
    limit++;

    for (auto Instr : TR.TaintedCallBases) {
      const CallBase* CB = dyn_cast<CallBase>(Instr);
      assert(CB && "SVF inserted nullptr callbase");
      CallBase* NCB = const_cast<CallBase*>(CB);
      errs() << "\n callbase: " << *CB << "\n";
      if (NCB->isIndirectCall()) continue;
      if (NCB->isInlineAsm()) continue;
      if (!M.getFunction(NCB->getCalledFunction()->getName())) {
        continue;
      }
      if (NCB->getCalledFunction()->isDeclaration()) {
        continue;
      }
      changed |= callBaseCloning(NCB, TR);
    }

    AM.invalidate(M, PreservedAnalyses::none());
  } while (changed && limit <= 20);
  auto &TR = AM.getResult<BlindedTaintTracking>(M);

}

bool BlindedTTFC::callBaseCloning(CallBase *CB, TaintResult& TR) {
  bool changed = false;

  errs() << "\nCloning call base: " << *CB << "\n";
  if (Function *CF = CB->getCalledFunction()) {
    SmallVector<unsigned, 8> ParamNos;
    for (auto &Arg : CB->args()) {
      unsigned n = Arg.getOperandNo();
      bool paramBlinded = CF->hasParamAttribute(n, Attribute::Blinded);
      if (TR.TaintedValues.count(Arg)) {
        if (!paramBlinded) {
          changed = true;
        }
        ParamNos.push_back(n);
      }
      else if (Arg->getType()->isPointerTy()) {
        SVF::NodeID pNodeId = TR.ander->getPAG()->getValueNode(Arg);
        const SVF::NodeBS& pts = TR.ander->getPts(pNodeId);
        for (auto it = pts.begin(); it != pts.end(); it++) {
          errs() << "\nAnalyzing vfgNode: " << *it << "\n";
          // if (!TR.svfg->hasVFGNode(*it)) {
          //   errs() << "\nNo vfgNode for " << *it << "\n";
          //   continue;
          // }
          if (!TR.pag->hasGNode(*it)) {
            errs() << "\n No pag Node for " << *it << "\n";
            continue;
          }
          auto pagNode = TR.pag->getPAGNode(*it);
          if (SVF::SVFUtil::isa<SVF::DummyValPN>(pagNode)
              || pagNode->getNodeKind() == SVF::PAGNode::DummyValNode
              || pagNode->getNodeKind() == SVF::PAGNode::DummyObjNode) {
            errs() << "\n pagnode is dummyvalpn " << "*it" << "\n";
            continue;
          }
          errs() << "current pag: " << *pagNode->getValue() << "\n";
          if (TR.TaintedObjectsIDs.count(*it)) {
            errs() << "\nTainted Node" << "\n";
            if (!paramBlinded) {
              changed = true;
            }
            ParamNos.push_back(n);
            break;
          }
        }
      }
    }
    if (ParamNos.empty()) {
      return false;
    }
    propagateBlindedArgumentFunctionCall(*CB, *CF, ParamNos);
  }
  return changed;
}


void BlindedTTFC::FuncCloning(Function &F, TaintResult& TR, SVF::Andersen* pta, bool& changed) {

  // Analyze callbase
  for (inst_iterator I = inst_begin(F), E = inst_end(F); I != E; ++I) {
    Instruction& Instr = *I;
    if (CallBase* CB = dyn_cast<CallBase>(&Instr)) {
      changed |= callBaseCloning(CB, TR);
    }
  }

}

bool BlindedTTFC::propagateBlindedArgumentFunctionCall(CallBase &CB, Function &F, ArrayRef<unsigned> ParamNos) {
  if (F.size() == 0) {
    // assume functions outside of this module will not return tainted values
    return false;
  }

  string clonedPrefix = "_cloned_";

  bool retVal = false;
  bool startsWithClonedPrefix = F.getName().startswith(clonedPrefix);
  StringRef originalName = F.getName();

  if (startsWithClonedPrefix) {
    size_t clonedSuffix = F.getName().rfind(".");
    errs() << "ClonedSuffix: " << clonedSuffix << "\n";
    originalName = originalName.substr(8, clonedSuffix - 8);
  }
  errs() << "Original Name: " <<  originalName << "\n";


  // Generate blinded identifier of type NAME.BITMAP, where the BITMAP has a 1
  // for the position (starting from right) of blinded arguments.
  Twine NewName = clonedPrefix + originalName + "." + Twine(arrToBitmap(ParamNos));

  SmallString<128> NameVec;
  auto *BlindedFunc = F.getParent()->getFunction(NewName.toStringRef(NameVec));


  if (!BlindedFunc) {
    // The function doesn't exist yet, let's create it then!
    BlindedFunc = generateBlindedCopy(NewName, F, ParamNos);
    retVal = true;
  }

  errs() << "BlindedCopy: " << BlindedFunc->getName() << "\n";
  errs() << "PrevFunc: " << CB << "\n\n";

  CB.setCalledFunction(BlindedFunc);

  return retVal;
}

Function* BlindedTTFC::generateBlindedCopy(
    Twine &Name, Function &F, ArrayRef<unsigned> ParamNos) {

  ValueMap<const Value *, WeakTrackingVH> Map;

  const auto *const OrigFuncTy = F.getFunctionType();

  std::vector<Type *> ArgTypes;
  for (const Argument &I : F.args())
    ArgTypes.push_back(I.getType());

  auto *FTy = FunctionType::get(OrigFuncTy->getReturnType(), ArgTypes,
                                OrigFuncTy->isVarArg());

  auto *NewF = Function::Create(FTy, F.getLinkage(), F.getAddressSpace(), Name,
                                F.getParent());

  Function::arg_iterator DestI = NewF->arg_begin();
  for (const Argument &I : F.args()) {
    DestI->setName(I.getName());
    Map[&I] = &*DestI++;
  }

  SmallVector<ReturnInst *, 8> Returns;
  CloneFunctionInto(NewF, &F, Map, F.getSubprogram() != nullptr, Returns,
                    "", nullptr);

  for (unsigned ParamNo : ParamNos)
    NewF->addParamAttr(ParamNo, Attribute::Blinded);

  return NewF;
}
