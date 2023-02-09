#include "llvm/Transforms/BlindedComputation/BlindedDataUsage.h"
#include "llvm/Analysis/BasicAliasAnalysis.h"
#include "llvm/Analysis/CFLSteensAliasAnalysis.h"
#include "llvm/IR/InstIterator.h"

using namespace llvm;

BlindedDataUsage::BlindedDataUsage(Module &M, ModuleAnalysisManager &AM) {
  auto TRS = AM.getResult<BlindedTaintTracking>(M);
  int statBranch = 0;

	for (auto Inst : TRS.BlndBr) {
		// errs() << "invalid use of blinded data as operand of branchInst!\n";
		// errs() << *Inst << "\n";
    statBranch++;
    // Inst->print(errs());
    std::pair<const Value *, StringRef> Violation_Instance(Inst, StringRef("Invalid use of blinded data as operand of BranchInst!"));
    Violations.insert(Violation_Instance);
	}
  int statStore = 0, statLoad = 0;
	for (auto Inst : TRS.BlndMemOp) {
		if (isa<LoadInst>(Inst)) {
			// errs() << "loadInstr with a blinded pointer!\n";
			// errs() << *Inst << "\n";
      statLoad++;
      // if (auto LI = dyn_cast<LoadInst>(Inst)) {
      //   const Value* lOperand = LI->getPointerOperand();
      //   TRS.backtrace(lOperand);
      // }
      // Inst->print(errs());
      std::pair<const Value *, StringRef> Violation_Instance(Inst, StringRef("LoadInst with a blinded pointer."));
      Violations.insert(Violation_Instance);
		}
		else if (isa<StoreInst>(Inst)) {
      // errs() << "storeInstr with a blinded pointer!\n";
			// errs() << *Inst << "\n";
      statStore++;
      // Inst->print(errs());
      std::pair<const Value *, StringRef> Violation_Instance(Inst, StringRef("StoreInst with a blinded pointer."));
      Violations.insert(Violation_Instance);
		}
	}
  errs() << "\n";
  errs() << "############stat info################" << "\n";
  errs() << "StoreInstr: " << statStore << "\n";
  errs() << "LoadInstr: " << statLoad << "\n";
  errs() << "BranchInstr: " << statBranch << "\n";
  errs() << "############stat info end###########" << "\n";


}

AnalysisKey BlindedDataUsageAnalysis::Key;
BlindedDataUsage BlindedDataUsageAnalysis::run(Module &M,
                                     ModuleAnalysisManager &AM) {
  return BlindedDataUsage(M, AM);
}

PreservedAnalyses BlindedDataUsagePrinterPass::run(Module &M,
                                     ModuleAnalysisManager &AM) {

  auto &BDU = AM.getResult<BlindedDataUsageAnalysis>(M);

  if (!BDU.violations().empty()) {
    // Got some violations, now pretty print them since we're a printer pass!
    for (auto &V : BDU.violations()) {
      if (V.first == nullptr) {
        OS << V.second << "\n\n"; continue;
      }

      const Instruction *Inst = dyn_cast<const Instruction>(V.first);
      Inst->getDebugLoc().print(OS);
      Inst->print(OS);
      OS << "\n";
      OS << "description: " << V.second << "\n\n";
    }
  }

  // Tell the pass manager we don't invalidate any of the used analyses
  PreservedAnalyses PA;
  PA.preserve<BlindedDataUsageAnalysis>();

  return PA;
}
