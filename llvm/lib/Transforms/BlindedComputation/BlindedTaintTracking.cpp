#include "llvm/Transforms/BlindedComputation/BlindedTaintTracking.h"

using namespace llvm;


void BlindedTaintTracking::buildTaintedSet(int iteration, Module& M) {

	extractTaintSource(M);
	std::set<const SVF::VFGNode*> handledNodes;
	std::vector<const SVF::VFGNode*> vfgNodeWorkList;
	std::vector<const Value*> llvmValueWorkList;

	for (auto vfgNode : TaintSource) {
		vfgNodeWorkList.push_back(vfgNode);
	}

	while (!(llvmValueWorkList.empty() && vfgNodeWorkList.empty())) {
		if (!vfgNodeWorkList.empty()) {
			const SVF::VFGNode* vfgNode = vfgNodeWorkList.back();
			vfgNodeWorkList.pop_back();
			if (vfgNode->getNodeKind() == SVF::VFGNode::VFGNodeK::Addr) {
          TaintedVFGNodes.insert(vfgNode);
      	}

			for (auto it = vfgNode->OutEdgeBegin(), eit = vfgNode->OutEdgeEnd(); it != eit; ++it) {
				SVF::VFGEdge *edge = *it;
				SVF::VFGNode *dstNode = edge->getDstNode();

					if (TaintedVFGNodes.find(dstNode) == TaintedVFGNodes.end()) {
							vfgNodeWorkList.push_back(dstNode);
							//visited.insert(dstNode);
					}
			}
		}
		
	}
}

void BlindedTaintTracking::markInstrsForConversion() {
	// mark instructions that need transformation with attribute

}

void BlindedTaintTracking::printInstrsForConversion() {
	// print instructions that need transformation

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

	if (Module *M = F.getParent()) {
		Module::GlobalListType &GL = M->getGlobalList();
		for (auto I = GL.begin(), E = GL.end(); I != E; ++I) {
			GlobalVariable &GV = *I;
			const SVF::VFGNode* taintedGVNode = LLVMValue2VFGNode(&GV);
			errs() << "Marking global variable: " << GV.getName() << "\n";
			assert(taintedGVNode != nullptr && ("Failed to fetch VFGNode from taintedGlobal " + GV.getName().str()).c_str());
			if (GV.hasAttribute(Attribute::Blinded)) {
				TaintSource.push_back(taintedGVNode);
			}
		}
	}
}


void BlindedTaintTracking::extractTaintSource(Module &M) {
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
const Value* BlindedTaintTracking::VFGNode2LLVMValue(SVF::SVFGNode* node) {
   if(const SVF::StmtSVFGNode* stmt = SVF::SVFUtil::dyn_cast<SVF::StmtSVFGNode>(node))
    {
        if(SVF::SVFUtil::isa<SVF::StoreSVFGNode>(stmt) == false)
        {
            if(stmt->getPAGDstNode()->hasValue())
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

    return nullptr;
}