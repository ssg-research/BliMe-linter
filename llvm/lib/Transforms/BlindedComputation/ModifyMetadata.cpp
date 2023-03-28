#include "llvm/Transforms/BlindedComputation/ModifyMetadata.h"

using namespace llvm;

PreservedAnalyses ModifyMetadataPass::run(Module &M, ModuleAnalysisManager &AM) {
  auto &TTResult = AM.getResult<BlindedTaintTracking>(M);

  for (auto I : TTResult.BlndBr) {
    if (const BranchInst* BrInst = dyn_cast<BranchInst>(I)) {
      BranchInst* NBrInst = const_cast<BranchInst*>(BrInst);
      LLVMContext &cont = NBrInst->getContext();
      MDNode *N = MDNode::get(cont, ConstantAsMetadata::get(ConstantInt::get(cont, APInt(sizeof(long)*8, true, true))));
      NBrInst->setMetadata("t", N);
    }
  }
  for (Function &F : M) {
    if (F.isDeclaration()) {
      continue;
    }

    for (auto Arg = F.arg_begin(); Arg < F.arg_end(); ++Arg) {
      if (Arg->hasAttribute(Attribute::Blinded)) {
          Arg->removeAttr(Attribute::Blinded);
      }
    }

    for (inst_iterator I = inst_begin(F), E = inst_end(F); I != E; I++) {
        auto N = I->getMetadata("t");
        LLVMContext &cont = I->getContext();
        if (N == NULL) {
          N = MDNode::get(cont, ConstantAsMetadata::get(ConstantInt::get(cont, APInt(sizeof(long)*8, false, true))));
          I->setMetadata("t", N);
        }
    }
  }



  PreservedAnalyses PA = PreservedAnalyses::all();
  return PA;

}
