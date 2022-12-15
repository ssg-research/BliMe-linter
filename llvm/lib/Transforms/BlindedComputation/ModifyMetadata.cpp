#include "llvm/Transforms/BlindedComputation/ModifyMetadata.h"

using namespace llvm;

PreservedAnalyses ModifyMetadataPass::run(Module &M, ModuleAnalysisManager &AM) {
    auto &TTResult = AM.getResult<BlindedTaintTracking>(M);
    for (Function &F : M) {
    if (F.isDeclaration()) {
      continue;
    }
    else {

      for (auto Arg = F.arg_begin(); Arg < F.arg_end(); ++Arg) {
        if (Arg->hasAttribute(Attribute::Blinded)) {
            Arg->removeAttr(Attribute::Blinded);
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
  }
  PreservedAnalyses PA = PreservedAnalyses::all();
  return PA;

}
