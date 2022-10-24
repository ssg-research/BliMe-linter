#include "llvm/Transforms/BlindedComputation/BlindedTaintTracking.h"

using namespace llvm;


void BlindedTaintTracking::buildTaintedSet(int iteration, Module& M) {

	extractTaintSource(M);
	std::set<const SVF::VFGNode*> handledNodes;
	std::vector<const SVF::VFGNode*> vfgNodeWorkList;

	for (auto vfgNode : TaintSource) {
		vfgNodeWorkList.push_back(vfgNode);
	}

	while (!vfgNodeWorkList.empty()) {
		const SVF::VFGNode* vfgNode = vfgNodeWorkList.back();
		vfgNodeWorkList.pop_back();
		errs() << "handling: " << vfgNode->toString() << "\n";

		if (handledNodes.count(vfgNode)) {
			continue;
		}
		handledNodes.insert(vfgNode);

		const Value* valNode = VFGNode2LLVMValue(vfgNode);
		if (valNode == nullptr) {
			errs() << "ValNode is nullptr " << "\n"; 
		}

		if (vfgNode->getNodeKind() == SVF::VFGNode::VFGNodeK::Load) {
			if (const LoadInst* LI = dyn_cast<LoadInst>(valNode)) {
				const Value *PO = LI->getPointerOperand();
				// check if blinded ptr
				// PO <- blinded (what now?) <- policy violation? Detect later
				// LI <- blinded (NOW)       <- not violation			

				if (PO->getType()->isPointerTy() && !PO->getType()->getContainedType(0)->isPointerTy()) {
					if (TaintedValues.count(valNode)) {
						// TODO: not sure if it is the correct way.
						continue;
					}
					TaintedValues.insert(valNode);
					LLVMContext &cont = LI->getContext();
					MDNode *N = MDNode::get(cont, ConstantAsMetadata::get(ConstantInt::get(cont, APInt(sizeof(long)*8, true, true))));
					const_cast<LoadInst*>(LI)->setMetadata("my.md.blindedNTT", N);
        }
			}
		} 
		else if (valNode != nullptr){
			if (const Instruction* instr = dyn_cast<Instruction>(valNode)) {
				// if (const GetElementPtrInst* GEPInstr = dyn_cast<GetElementPtrInst>(instr)) {
				// 	// TODO: handle ptr
				// }
				if (const StoreInst* StoreInstr = dyn_cast<StoreInst>(instr)) {
					// TODO: handle ptr
				}
				else if (const AllocaInst* AllocaInstr = dyn_cast<AllocaInst>(instr)) {
					// TODO: handle ptr
				}
				else if (const CmpInst* CmpInstr = dyn_cast<CmpInst>(instr)) {
					TaintedValues.insert(valNode);
					LLVMContext &cont = instr->getContext();
        	MDNode *N = MDNode::get(cont, ConstantAsMetadata::get(ConstantInt::get(cont, APInt(sizeof(long)*8, true, true))));
        	const_cast<Instruction*>(instr)->setMetadata("my.md.blindedNTT", N);
					for (auto CmpUser : valNode->users()) {
						const Value* CmpUserVal = dyn_cast<Value>(CmpUser);
						Value* NCmpUserVal = const_cast<Value*>(CmpUserVal);
						const SVF::VFGNode* CmpVFGNode = LLVMValue2VFGNode(NCmpUserVal);
						if (CmpVFGNode != nullptr) {
							vfgNodeWorkList.push_back(CmpVFGNode);
						}
					}
				}
				else {
					TaintedValues.insert(valNode);
					LLVMContext &cont = instr->getContext();
        	MDNode *N = MDNode::get(cont, ConstantAsMetadata::get(ConstantInt::get(cont, APInt(sizeof(long)*8, true, true))));
        	const_cast<Instruction*>(instr)->setMetadata("my.md.blindedNTT", N);
				}
			}
    }

		for (auto it = vfgNode->OutEdgeBegin(), eit = vfgNode->OutEdgeEnd(); it != eit; ++it) {
			SVF::VFGEdge *edge = *it;
			SVF::VFGNode *dstNode = edge->getDstNode();

			if (!handledNodes.count(dstNode)) {
				vfgNodeWorkList.push_back(dstNode);
				if (vfgNode->getNodeKind() == SVF::VFGNode::FParm) {
					errs() << "VFGFParmNode: " << vfgNode->toString() << "\n" << dstNode->toString() << "\n";
				}
			}

		}
	}
	printInstrsForConversion();
}

void BlindedTaintTracking::markInstrsForConversion() {
	for (auto Val : TaintedValues) {
		for (auto U : Val->users()) {
			auto ValUser = dyn_cast<Instruction>(U);
			if (const BranchInst *BrInst = dyn_cast<BranchInst>(ValUser)) {
				if (BrInst->isConditional() && TaintedValues.count(BrInst->getCondition())){
					BranchInst* NBrInst = const_cast<BranchInst*>(BrInst);
					BlndBr.push_back(NBrInst);
				}
			}					
			else if (const LoadInst *LInst = dyn_cast<LoadInst>(ValUser)) {
				// Load using sensitive value
				// This is not handled yet. Current implementation actually handles GEP
				LoadInst* NLInst = const_cast<LoadInst*>(LInst);
				BlndMemOp.push_back(NLInst);
			}
			else if (const GetElementPtrInst *GEPInst = dyn_cast<GetElementPtrInst>(ValUser)) {
				GetElementPtrInst* NGEPInst = const_cast<GetElementPtrInst*>(GEPInst);
				BlndGep.push_back(NGEPInst);
			}
			else if (const StoreInst *SInst = dyn_cast<StoreInst>(ValUser)) {
				// Store using sensitive value
				// This is not handled yet. Current implementation actually handles GEP
				StoreInst* NSInst = const_cast<StoreInst*>(SInst);
				BlndMemOp.push_back(NSInst);
			}
		}
	}

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