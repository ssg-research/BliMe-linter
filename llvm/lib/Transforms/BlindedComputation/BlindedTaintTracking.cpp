#include "llvm/Transforms/BlindedComputation/BlindedTaintTracking.h"

using namespace llvm;

// TODO: maybe we can have more information for transformer to handle
// TODO: maybe we need to also add blinded ptr metadata
// Current solution is to leave the task of differentiating different
// cases to the validate/transform

void TaintResult::clearResults() {
	BlndBr.clear();
	BlndMemOp.clear();
	BlndGep.clear();
	BlndSelect.clear();
	TaintedValues.clear();
	BlindedPtrArg.clear();
}

void BlindedTaintTracking::clearResults() {
	TResult.clearResults();
	TaintSource.clear();
}

void BlindedTaintTracking::buildSVFG(Module &M) {
	SVF::SVFModule* svfModule = SVF::LLVMModuleSet::getLLVMModuleSet()->buildSVFModule(M);
	SVF::PAGBuilder pagBuilder;
	pag = pagBuilder.build(svfModule);
	ander = new SVF::Andersen(pag);
	ander->analyze();
	SVF::SVFGBuilder svfBuilder(true);
	svfg = svfBuilder.buildFullSVFGWithoutOPT(ander);
}

void BlindedTaintTracking::releaseSVFG() {
	SVF::LLVMModuleSet::releaseLLVMModuleSet();
	SVF::PAG::releasePAG();
}

bool BlindedTaintTracking::hasViolation(Module& M) {
	markInstrsForConversion();
	return !(TResult.BlndBr.empty() && TResult.BlndMemOp.empty());
}

bool BlindedTaintTracking::addTaintedValue(const Value* V) {
	if (TResult.TaintedValues.count(V)) {
		return false;
	}
	TResult.TaintedValues.insert(V);
	if (const Instruction* vInstr = dyn_cast<Instruction>(V)) {

		LLVMContext &cont = vInstr->getContext();
		MDNode *N = MDNode::get(cont, ConstantAsMetadata::get(ConstantInt::get(cont, APInt(sizeof(long)*8, true, true))));
		const_cast<Instruction*>(vInstr)->setMetadata("my.md.blindedNTT", N);
	}
	return true;
	// errs() << "While handling value: " << V << "\n"; 
	// assert(false && "Trying give a non-instr blinded attribute\n");
}


// TODO:
// Existing bug: need to implement DefUsePropagate function and use it as the condition.
// Currently, the propagation from blinded data param is seemingly a bug
void BlindedTaintTracking::buildTaintedSet(int iteration, Module& M) {
	clearResults();
	extractTaintSource(M);
	std::set<std::pair<const SVF::VFGNode*, const SVF::VFGNode*>> handledNodes;
	std::vector<std::pair<const SVF::VFGNode*, const SVF::VFGNode*>> vfgNodeWorkList;


	for (auto vfgNode : TaintSource) {
		vfgNodeWorkList.push_back({nullptr, vfgNode});
	}

	while (!vfgNodeWorkList.empty()) {
		auto backPair = vfgNodeWorkList.back();
		const SVF::VFGNode* vfgNode = backPair.second;
		const SVF::VFGNode* predVFGNode = backPair.first;
		bool propagateDefUse = false;

		vfgNodeWorkList.pop_back();
		errs() << "handling: " << vfgNode->toString() << "\n";

		if (handledNodes.count(backPair)) {
			continue;
		}
		handledNodes.insert(backPair);

		const Value* valNode = VFGNode2LLVMValue(vfgNode);
		const Value* predValNode = nullptr;
		if (predVFGNode != nullptr) {
		 predValNode = VFGNode2LLVMValue(predVFGNode);
		}
		// if (valNode == nullptr) {
		// 	errs() << "ValNode is nullptr " << "\n"; 
		// }
		// const Value* 
		if (SVF::SVFUtil::isa<SVF::ActualParmSVFGNode>(vfgNode)) {
			TResult.BlindedPtrArg.insert(valNode);
		}

		if (valNode != nullptr){
			propagateDefUse = true;
			if (const LoadInst* LI = dyn_cast<LoadInst>(valNode)) {
					const Value *PO = LI->getPointerOperand();

					// check if blinded ptr
					// PO <- blinded (what now?) <- policy violation? Detect later
					// LI <- blinded (NOW)       <- not violation
					// TODO: Write a test to see if it works
					// PO & LI simultaneously blinded
					//  %cmp3 = icmp sgt i32 %cond, 10, !dbg !43
 					//  %cond5 = select i1 %cmp3, i32* %arraydecay, i32* %arraydecay4
					//  %1 = load i32 %cond5 
					//  %cond5 is both a blinded data and pointer to blinded data
					//  b = arr[%1]

					const Value *predVal = VFGNode2LLVMValue(predVFGNode);	
					if (PO == predVal && TResult.TaintedValues.count(predVal)) {
						continue;
					}
					if (PO->getType()->isPointerTy() && PO->getType()->getContainedType(0)->isPointerTy()) {
						propagateDefUse = false;
					}
			}
			else if (SVF::SVFUtil::isa<SVF::FormalParmVFGNode>(vfgNode) && valNode->getType()->isPointerTy()) {
				propagateDefUse = false;
			}
			else if (isa<GlobalVariable>(valNode) && valNode->getType()->isPointerTy()) {
				propagateDefUse = false;
			}
			else if (predValNode != nullptr && !TResult.TaintedValues.count(predValNode)) {
				propagateDefUse = false;
			}
			if (propagateDefUse) {
				addTaintedValue(valNode);
				for (auto valUser : valNode->users()) {
					const Value* valUserVal = dyn_cast<Value>(valUser);
					Value* NValUserVal = const_cast<Value*>(valUserVal);
					if (isa<Instruction>(NValUserVal) 
							&& !isa<StoreInst>(NValUserVal) && !isa<ReturnInst>(NValUserVal) && !isa<CallBase>(NValUserVal)) {
						const SVF::VFGNode* userVFGNode = LLVMValue2VFGNode(NValUserVal);
						if (NValUserVal != nullptr) {
							if (!handledNodes.count({vfgNode, userVFGNode})) {
								vfgNodeWorkList.push_back({vfgNode, userVFGNode});
							}
						}
					}
				}
			}
    }

		for (auto it = vfgNode->OutEdgeBegin(), eit = vfgNode->OutEdgeEnd(); it != eit; ++it) {
			SVF::VFGEdge *edge = *it;
			SVF::VFGNode *dstNode = edge->getDstNode();

			if (!handledNodes.count({vfgNode, dstNode})) {
				vfgNodeWorkList.push_back({vfgNode, dstNode});
				// if (vfgNode->getNodeKind() == SVF::VFGNode::FParm) {
				// 	errs() << "VFGFParmNode: " << vfgNode->toString() << "\n" << dstNode->toString() << "\n";
				// }
			}
		}
	}
}

void BlindedTaintTracking::markInstrsForConversion(bool clear) {
	for (auto Val : TResult.TaintedValues) {
		for (auto U : Val->users()) {
			auto ValUser = dyn_cast<Instruction>(U);
			if (!ValUser) {
				continue;
			}
			if (const BranchInst *BrInst = dyn_cast<BranchInst>(ValUser)) {
				if (BrInst->isConditional() && TResult.TaintedValues.count(BrInst->getCondition())){
					TResult.BlndBr.push_back(BrInst);
				}
			}					
			else if (const LoadInst *LInst = dyn_cast<LoadInst>(ValUser)) {
				if (TResult.TaintedValues.count(LInst->getPointerOperand())) {
					TResult.BlndMemOp.push_back(LInst);
				}
			}
			else if (const StoreInst *SInst = dyn_cast<StoreInst>(ValUser)) {
				if (TResult.TaintedValues.count(SInst->getPointerOperand())) {
					TResult.BlndMemOp.push_back(SInst);
				}
			}
			else if (const GetElementPtrInst *GEPInst = dyn_cast<GetElementPtrInst>(ValUser)) {
				TResult.BlndGep.push_back(GEPInst);
			}
			else if (const SelectInst* SelInst = dyn_cast<SelectInst>(ValUser)) {
				TResult.BlndSelect.push_back(SelInst);
			}
		}
	}
	ResultCached = true;

}

void BlindedTaintTracking::extractTaintSource(Function &F) {
	errs() << F.getName() << "\n";
	for (auto Arg = F.arg_begin(); Arg < F.arg_end(); ++Arg) {
		if (Arg->hasAttribute(Attribute::Blinded)) {
			const SVF::VFGNode* taintedArg = LLVMValue2VFGNode(Arg);
			errs() << "Marking formal parameter: " << Arg->getName() << "\n";
			assert(taintedArg != nullptr && ("Failed to fetch VFGNode from taintedArg " + Arg->getName().str()).c_str());
			TaintSource.push_back(taintedArg);
			// if the formal parameter is a non-pointer type, it should also be a tainted value
			if (!Arg->getType()->isPointerTy()) {
				TResult.TaintedValues.insert(Arg);
			}
		}
	}

}

void BlindedTaintTracking::extractTaintSource(Module &M) {
	Module::GlobalListType &GL = M.getGlobalList();
	for (auto I = GL.begin(), E = GL.end(); I != E; ++I) {
		GlobalVariable &GV = *I;
		const SVF::VFGNode* taintedGVNode = LLVMValue2VFGNode(&GV);
		errs() << "Marking global variable: " << GV.getName() << "\n";
		assert(taintedGVNode != nullptr && ("Failed to fetch VFGNode from taintedGlobal " + GV.getName().str()).c_str());
		if (GV.hasAttribute(Attribute::Blinded)) {
			TaintSource.push_back(taintedGVNode);
		}
	}

  for (Function &F : M) {
    if (F.isDeclaration()) {
      continue;
    }
    extractTaintSource(F);
  }	
}

const SVF::VFGNode* BlindedTaintTracking::LLVMValue2VFGNode(Value* value) {
	errs() << "converting: " << *value << "\n";
	SVF::PAGNode* pNode = pag->getPAGNode(pag->getValueNode(value));
	const SVF::VFGNode* vfgNode = svfg->getDefSVFGNode(pNode);
	return vfgNode;
}

// Directly copied from SVF/SABER/ProgSlice.cpp
// Just don't want to create object to use this method
const Value* BlindedTaintTracking::VFGNode2LLVMValue(const SVF::SVFGNode* node) {
   if(const SVF::StmtSVFGNode* stmt = SVF::SVFUtil::dyn_cast<SVF::StmtSVFGNode>(node)) {
			if (SVF::SVFUtil::isa<SVF::StoreSVFGNode>(stmt)) {
				return nullptr;
			}            
			else if (stmt->getPAGDstNode()->hasValue()) {
				return stmt->getPAGDstNode()->getValue();
			}
    }
    else if(const SVF::PHISVFGNode* phi = SVF::SVFUtil::dyn_cast<SVF::PHISVFGNode>(node))
    {
			return phi->getRes()->getValue();
    }
    else if(const SVF::ActualParmSVFGNode* ap = SVF::SVFUtil::dyn_cast<SVF::ActualParmSVFGNode>(node))
    {
			return ap->getParam()->getValue();
    }
    else if(const SVF::FormalParmSVFGNode* fp = SVF::SVFUtil::dyn_cast<SVF::FormalParmSVFGNode>(node))
    {
			return fp->getParam()->getValue();
    }
    else if(const SVF::ActualRetSVFGNode* ar = SVF::SVFUtil::dyn_cast<SVF::ActualRetSVFGNode>(node))
    {
			return ar->getRev()->getValue();
    }
    else if(const SVF::FormalRetSVFGNode* fr = SVF::SVFUtil::dyn_cast<SVF::FormalRetSVFGNode>(node))
    {
			return fr->getRet()->getValue();
    }
		else if (const SVF::CmpVFGNode* cmpVFGNode = dyn_cast<SVF::CmpVFGNode>(node)) {
			return cmpVFGNode->getRes()->getValue();
		}
		else if (const SVF::BinaryOPVFGNode* binOpVFGNode = dyn_cast<SVF::BinaryOPVFGNode>(node)) {
			return binOpVFGNode->getRes()->getValue();
		}
		else if (const SVF::UnaryOPVFGNode* unaryOpVFGNode = dyn_cast<SVF::UnaryOPVFGNode>(node)) {
			const Value* unaryOpVal = unaryOpVFGNode->getRes()->getValue();
			if (isa<UnaryOperator>(unaryOpVal)) {
				return unaryOpVal;
			} 
			else {
				return nullptr;
			}
		}

    return nullptr;
}
AnalysisKey BlindedTaintTracking::Key;
TaintResult BlindedTaintTracking::run(Module& M, ModuleAnalysisManager &AM) {
	buildSVFG(M);

	// beware that buildTaintedSet will always clear the Result 
	// and marked tainted values
	buildTaintedSet(0, M);
	markInstrsForConversion();
	ResultCached = true;

	releaseSVFG();

	return TResult;

}
