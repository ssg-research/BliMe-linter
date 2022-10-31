#include "llvm/Transforms/BlindedComputation/BlindedTaintTracking.h"

using namespace llvm;

// TODO: maybe we can have more information for transformer to handle
// TODO: maybe we need to also add blinded ptr metadata
// Current solution is to leave the task of differentiating different
// cases to the validate/transform

void BlindedTaintTracking::clearResults() {
	clearInstrConvSet();
	TaintedValues.clear();
	TaintSource.clear();
	InstrsMarked = false;
}

void BlindedTaintTracking::clearInstrConvSet() {
	BlndBr.clear();
	BlndMemOp.clear();
	BlndGep.clear();
	BlndSelect.clear();
	InstrsMarked = false;
}

bool BlindedTaintTracking::hasViolation(Module& M) {
	markInstrsForConversion();
	return !(BlndBr.empty() && BlndMemOp.empty());
}

void BlindedTaintTracking::printViolations() {
	for (auto Inst : BlndBr) {
		errs() << "invalid use of blinded data as operand of branchInst!\n";
		errs() << *Inst << "\n";
	}
	for (auto Inst : BlndMemOp) {
		if (isa<LoadInst>(Inst)) {
			errs() << "loadInstr with a blinded pointer!\n";
			errs() << *Inst << "\n";
		}
		else if (isa<StoreInst>(Inst)) {
      errs() << "storeInstr with a blinded pointer!\n";
			errs() << *Inst << "\n";
		} 
	}
}


bool BlindedTaintTracking::addTaintedValue(const Value* V) {
	if (const Instruction* vInstr = dyn_cast<Instruction>(V)) {
		if (TaintedValues.count(V)) {
			return false;
		}
		TaintedValues.insert(V);
		LLVMContext &cont = vInstr->getContext();
		MDNode *N = MDNode::get(cont, ConstantAsMetadata::get(ConstantInt::get(cont, APInt(sizeof(long)*8, true, true))));
		const_cast<Instruction*>(vInstr)->setMetadata("my.md.blindedNTT", N);
		return true;
	}
	errs() << "While handling value: " << V << "\n"; 
	assert(false && "Trying give a non-instr blinded attribute\n");
}


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

		vfgNodeWorkList.pop_back();
		errs() << "handling: " << vfgNode->toString() << "\n";

		if (handledNodes.count(backPair)) {
			continue;
		}
		handledNodes.insert(backPair);

		const Value* valNode = VFGNode2LLVMValue(vfgNode);
		if (valNode == nullptr) {
			errs() << "ValNode is nullptr " << "\n"; 
		}

		if (valNode != nullptr){
			if (const Instruction* instr = dyn_cast<Instruction>(valNode)) {
				if (const LoadInst* LI = dyn_cast<LoadInst>(valNode)) {
					const Value *PO = LI->getPointerOperand();

					// check if blinded ptr
					// PO <- blinded (what now?) <- policy violation? Detect later
					// LI <- blinded (NOW)       <- not violation
					// TODO: Write a test to see if it works
					const Value *predVal = VFGNode2LLVMValue(predVFGNode);	
					if (PO == predVal && TaintedValues.count(predVal)) {
						continue;
					}

					if (PO->getType()->isPointerTy() && !PO->getType()->getContainedType(0)->isPointerTy()) {
						if (TaintedValues.count(valNode)) {
							continue;
						}
					}
				}
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
	InstrsMarked = false;
	printInstrsForConversion();
	markInstrsForConversion();
}

void BlindedTaintTracking::markInstrsForConversion(bool clear) {
	if (clear) {
		clearInstrConvSet();
	}
	else if (InstrsMarked) {
		return;
	}

	for (auto Val : TaintedValues) {
		for (auto U : Val->users()) {
			auto ValUser = dyn_cast<Instruction>(U);
			if (const BranchInst *BrInst = dyn_cast<BranchInst>(ValUser)) {
				if (BrInst->isConditional() && TaintedValues.count(BrInst->getCondition())){
					// BranchInst* NBrInst = const_cast<BranchInst*>(BrInst);
					BlndBr.push_back(BrInst);
				}
			}					
			else if (const LoadInst *LInst = dyn_cast<LoadInst>(ValUser)) {
				// Load using sensitive value
				// This is not handled yet. Current implementation actually handles GEP
				// LoadInst* NLInst = const_cast<LoadInst*>(LInst);
				BlndMemOp.push_back(LInst);
			}
			else if (const StoreInst *SInst = dyn_cast<StoreInst>(ValUser)) {
				// Store using sensitive value
				// This is not handled yet. Current implementation actually handles GEP
				// StoreInst* NSInst = const_cast<StoreInst*>(SInst);
				BlndMemOp.push_back(SInst);
			}
			// This is likely to be temporary. 
			// We will finally handle the memory access only based on l/s instrs
			// and the def of the pointer operand
			else if (const GetElementPtrInst *GEPInst = dyn_cast<GetElementPtrInst>(ValUser)) {
				// GetElementPtrInst* NGEPInst = const_cast<GetElementPtrInst*>(GEPInst);
				BlndGep.push_back(GEPInst);
			}
			else if (const SelectInst* SelInst = dyn_cast<SelectInst>(ValUser)) {
				BlndSelect.push_back(SelInst);
			}
		}
	}
	InstrsMarked = true;

}

void BlindedTaintTracking::printInstrsForConversion() {
	// print instructions that need transformation
	for (auto instr : TaintedValues) {
		errs() << *instr << "\n";
	}
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
				TaintedValues.insert(Arg);
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