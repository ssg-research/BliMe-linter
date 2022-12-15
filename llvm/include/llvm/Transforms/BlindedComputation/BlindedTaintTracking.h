#ifndef LLVM_TRANSFORMS_BLINDEDCOMPUTATION_BLINDEDTAINTTRACKING_H
#define LLVM_TRANSFORMS_BLINDEDCOMPUTATION_BLINDEDTAINTTRACKING_H

#include "llvm/IR/PassManager.h"

#include "llvm/Analysis/SVF/Graphs/VFG.h"
#include "llvm/Analysis/SVF/WPA/WPAPass.h"
#include "llvm/Analysis/SVF/WPA/Andersen.h"
#include "llvm/Analysis/SVF/Util/SVFUtil.h"
#include "llvm/Analysis/SVF/Util/SVFModule.h"
#include "llvm/Analysis/SVF/SVF-FE/LLVMUtil.h"
#include "llvm/Analysis/SVF/SVF-FE/GEPTypeBridgeIterator.h"
#include "llvm/Analysis/SVF/SVF-FE/PAGBuilder.h"


#include <vector>
#include <unordered_map>
#include <set>


namespace llvm {

class TaintResult {
public:
	std::vector<const Value*> BlndBr;
	std::vector<const Value*> BlndGep;
	std::vector<const Value*> BlndMemOp;
	std::vector<const Value*> BlndSelect;
	std::set<const Value*> TaintedValues;
	std::set<const Value*> BlindedPtrArg;

	void clearResults();

};

class BlindedTaintTracking : public AnalysisInfoMixin<BlindedTaintTracking> {
	friend AnalysisInfoMixin<BlindedTaintTracking>;
	static AnalysisKey Key;
public:
	// Constructor(s): initializes SVF
	using Result = TaintResult;
	SVF::Andersen* ander;
	SVF::PAG* pag;
	SVF::SVFG* svfg;

	Result run(Module& M, ModuleAnalysisManager &AM);
	// void invalidate();

	// We assume the programmer will use these sets directly
	Result TResult = TaintResult();

private:

	bool ResultCached = false;
	// Store the tainted llvm value
	std::vector<const SVF::VFGNode*> TaintSource;

	bool addTaintedValue(const Value* V);

	// This function builds worklist to be propagated
	void extractTaintSource(Function &F);
	void extractTaintSource(Module &M);

	const SVF::VFGNode* LLVMValue2VFGNode(Value* value);
	const Value* VFGNode2LLVMValue(const SVF::SVFGNode* node);

	bool DefUsePropagate(const SVF::VFGNode* vfgNode);
	bool SVFGPropagate(const SVF::VFGNode* vfgNode);

	void buildSVFG(Module &M);
	// iteration: the max time of function cloning
	void buildTaintedSet(int iteration, Module& M);
	void clearResults();
	bool hasViolation(Module& M);
	void markInstrsForConversion(bool clear = false);
	void printInstrsForConversion();
	void printViolations();
	void releaseSVFG();
};

} // namespace llvm

#endif // LLVM_TRANSFORMS_BLINDEDCOMPUTATION_BLINDEDTAINTTRACKING_H