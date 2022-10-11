#ifndef LLVM_TRANSFORMS_BLINDEDCOMPUTATION_BLINDEDTAINTTRACKING_H
#define LLVM_TRANSFORMS_BLINDEDCOMPUTATION_BLINDEDTAINTTRACKING_H

#include "llvm/IR/PassManager.h"
#include "llvm/Analysis/TaintTracking.h"
#include "llvm/Analysis/BasicAliasAnalysis.h"
#include "llvm/Analysis/BlindedDataUsage.h"

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

class BlindedTaintTracking {
public:
	// Constructor(s): initializes SVF
	SVF::Andersen* ander;
	SVF::PAG* pag;
	SVF::SVFG* svfg;

	BlindedTaintTracking(Module &M) {
		SVF::SVFModule* svfModule = SVF::LLVMModuleSet::getLLVMModuleSet()->buildSVFModule(M);
		SVF::PAGBuilder pagBuilder;
		pag = pagBuilder.build(svfModule);
		ander = new SVF::Andersen(pag);
		ander->analyze();
		SVF::SVFGBuilder svfBuilder(true);
		svfg = svfBuilder.buildFullSVFGWithoutOPT(ander);
	}

	// iteration: the max time of function cloning
	void buildTaintedSet(int iteration, Module& M);
	void markInstrsForConversion();
	void printInstrsForConversion();

private:

	// We expect VFGNodes to be converted to llvm values for transformation.
	std::set<const SVF::VFGNode*> TaintedVFGNodes;

	// Store the tainted llvm value
	std::vector<const SVF::VFGNode*> TaintSource;
	std::vector<Value*> TaintedValues;

	// This function builds worklist to be propagated
	void extractTaintSource(Function &F);
	void extractTaintSource(Module &M);

	const SVF::VFGNode* LLVMValue2VFGNode(Value* value);
	const Value* VFGNode2LLVMValue(SVF::SVFGNode* node); 


};

} // namespace llvm

#endif // LLVM_TRANSFORMS_BLINDEDCOMPUTATION_BLINDEDTAINTTRACKING_H