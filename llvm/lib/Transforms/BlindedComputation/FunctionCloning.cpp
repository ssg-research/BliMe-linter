#include "llvm/Transforms/BlindedComputation/FunctionCloning.h"

using namespace::llvm;

void BlindedTTFC::FuncCloning(Module &M, TaintResult& TR) {
  // SVF::SVFModule* svfModule = SVF::LLVMModuleSet::getLLVMModuleSet()->buildSVFModule(M);
	// SVF::PAGBuilder pagBuilder;
	// auto pag = pagBuilder.build(svfModule);
  // auto ander = new SVF::Andersen(pag);
	// ander->analyze();

  for (Function &F : M) {
    if (F.isDeclaration()) {
      continue;
    }
    // errs() << "Function cloning: checking..." << F.getName() << "\n";
    FuncCloning(F, TR, nullptr);
  }

  // SVF::LLVMModuleSet::releaseLLVMModuleSet();
	// SVF::PAG::releasePAG();

}

void BlindedTTFC::FuncCloning(Function &F, TaintResult& TR, SVF::Andersen* pta) {
  for (inst_iterator I = inst_begin(F), E = inst_end(F); I != E; ++I) {
    Instruction& Instr = *I;
    if (CallBase* CB = dyn_cast<CallBase>(&Instr)) {
      if (Function *CF = CB->getCalledFunction()) {
        SmallVector<unsigned, 8> ParamNos;
        for (auto &Arg : CB->args()) {
          unsigned n = Arg.getOperandNo();
          if (TR.TaintedValues.count(Arg)) {
            ParamNos.push_back(n);
          }
        }
        if (ParamNos.empty()) {
          continue;
        }
        propagateBlindedArgumentFunctionCall(*CB, *CF, ParamNos);
      }
    }
  }
}

bool BlindedTTFC::propagateBlindedArgumentFunctionCall(CallBase &CB, Function &F, ArrayRef<unsigned> ParamNos) {
  if (F.size() == 0) {
    // assume functions outside of this module will not return tainted values
    return false;
  }

  // Generate blinded identifier of type NAME.BITMAP, where the BITMAP has a 1
  // for the position (starting from right) of blinded arguments.
  Twine NewName = F.getName() + "." + Twine(arrToBitmap(ParamNos));

  SmallString<128> NameVec;
  auto *BlindedFunc = F.getParent()->getFunction(NewName.toStringRef(NameVec));


  if (!BlindedFunc) {
    // The function doesn't exist yet, let's create it then!
    BlindedFunc = generateBlindedCopy(NewName, F, ParamNos);
  }

  errs() << "BlindedCopy: " << BlindedFunc->getName() << "\n";
  errs() << "PrevFunc: " << CB << "\n\n";

  CB.setCalledFunction(BlindedFunc);


  return BlindedFunc->hasFnAttribute(Attribute::Blinded);
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

  // for (unsigned ParamNo : ParamNos)
  //   NewF->addParamAttr(ParamNo, Attribute::Blinded);

  return NewF;
}
