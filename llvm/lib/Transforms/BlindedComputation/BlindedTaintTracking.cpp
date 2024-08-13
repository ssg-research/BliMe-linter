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
	TaintedPointers.clear();
	TaintedObjectsIDs.clear();
	TTGraph.clear();
	TaintedCallBases.clear();
	releaseSVFG();
}

void BlindedTaintTracking::clearResults() {
	TResult.clearResults();
	TaintSource.clear();
}

void TaintResult::backtrace(const Value* valueNode) {
	std::vector<std::string> result;
	std::queue<const SVF::VFGNode*> workList;

	SVF::PAGNode* pNode = pag->getPAGNode(pag->getValueNode(valueNode));
	const SVF::VFGNode* vfgNode = svfg->getDefSVFGNode(pNode);
	workList.push(vfgNode);
	int cnt = 1;
	std::set<const SVF::VFGNode*> visited;
	visited.insert(vfgNode);

	while (!workList.empty()) {
		const SVF::VFGNode* frt = workList.front();
		workList.pop();
		if (frt == nullptr) {
			break;
		}
		errs() << cnt++ << ". " << frt->toString() << "\n";
		assert(TTGraph.find(frt) != TTGraph.end() && "Cannot find node in TTGraph");
		for (auto vnode : TTGraph[frt]) {
			if (visited.count(vnode)) {
				continue;
			}
			else {
				workList.push(vnode);
				visited.insert(vnode);
			}
		}
	}
}

void BlindedTaintTracking::buildSVFG(Module &M) {
	// M.dump();
	std::cout << "Module name:\n" << M.getModuleIdentifier() << std::endl;
	// std::vector<std::string> modules;
	// modules.push_back(M.getModuleIdentifier());
	// SVF::SVFModule* svfModule = SVF::LLVMModuleSet::getLLVMModuleSet()->buildSVFModule(modules);
	SVF::SVFModule* svfModule = SVF::LLVMModuleSet::getLLVMModuleSet()->buildSVFModule(M);
	SVF::PAGBuilder pagBuilder;
	pag = pagBuilder.build(svfModule);
	ander = new SVF::Andersen(pag);
	ander->analyze();
	// steens = new SVF::Steensgaard(pag);
	// steens->analyze();
	std::time_t timestamp = std::time(nullptr);
    std::cout << std::asctime(std::localtime(&timestamp)) << "\n";
	std::cout << "Pointer analysis complete. Building SVFG...\n";
	SVF::SVFGBuilder svfBuilder(true);
	svfg = svfBuilder.buildFullSVFGWithoutOPT(ander);
	// svfg = svfBuilder.buildFullSVFGWithoutOPT(steens);
	// svfg->dump("svfg.dot");
}

void TaintResult::releaseSVFG() {
	if (ander == nullptr && steens == nullptr) {
		return;
	}
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

}

void BlindedTaintTracking::propagateTaintedPointers(const Value* pointerVal) {
	for (auto valUser : pointerVal->users()) {
		const Value* valUserVal = dyn_cast<Value>(valUser);
		Value* NValUserVal = const_cast<Value*>(valUserVal);
		// if user is a store inst, and storing the pointerVal to a pointer
		// then the pointer operand should be blinded pointer
		if (const StoreInst* SI = dyn_cast<const StoreInst>(valUserVal)) {
			const Value* valOp = SI->getValueOperand();
			if (valOp == pointerVal) {
				TResult.TaintedPointers.insert(SI->getPointerOperand());
			}
		}
		// For load, we will handle this later
		// For calbase: it is complicated
		else if (isa<Instruction>(NValUserVal) && !isa<LoadInst>(NValUserVal) && !isa<CallBase>(NValUserVal)) {
			TResult.TaintedPointers.insert(valUserVal);
		}
	}
}

// TODO:
// Existing bug: need to implement DefUsePropagate function and use it as the condition.
// Currently, the propagation from blinded data param is seemingly a bug
void BlindedTaintTracking::buildTaintedSet(int iteration, Module& M) {
	clearResults();
	static int timer = 0;
	buildSVFG(M);
	TResult.ander = ander;
	TResult.steens = steens;
	TResult.pag = pag;
	TResult.svfg = svfg;
	timer++;

	int tempCtr = 0;
	extractTaintSource(M);
	std::set<std::pair<const SVF::VFGNode*, const SVF::VFGNode*>> handledNodes;
	std::queue<std::pair<const SVF::VFGNode*, const SVF::VFGNode*>> vfgNodeWorkList;
	std::queue<int> ActualInTimes;

	for (auto vfgNode : TaintSource) {
	#ifdef TRACKBACK_BLINDED
		TResult.TTGraph[vfgNode].push_back(nullptr);
	#endif
		handledNodes.insert({nullptr, vfgNode});
		vfgNodeWorkList.push({nullptr, vfgNode});
		ActualInTimes.push(0);
	}

	int printctr = 0;

	while (!vfgNodeWorkList.empty()) {
		auto backPair = vfgNodeWorkList.front();
		const SVF::VFGNode* vfgNode = backPair.second;
		const SVF::VFGNode* predVFGNode = backPair.first;
		int afterActualIn = ActualInTimes.front();

		bool propagateDefUse = false;
		bool propagatePointers = false;

		// if (timer >= 2) {
		// 	if (printctr <= 5000) {
		// 		printctr++;
		// 		if (predVFGNode != nullptr) {
		// 			llvm::outs() << "predVFGNode is: " << predVFGNode->toString() << "\n";
		// 		}
		// 		llvm::outs() << "currentVFGNode is: " << vfgNode->toString() << "\n\n";
		// 	}
		// }

		ActualInTimes.pop();
		vfgNodeWorkList.pop();
		// errs() << "handling: " << vfgNode->toString() << "\n";

		if (auto CB = SVF::SVFUtil::dyn_cast<SVF::ActualINSVFGNode>(vfgNode)) {
			if (!afterActualIn) {
				// errs() << "current CB: " << *CB << "\n";

				afterActualIn = 1;
				TResult.TaintedCallBases.push_back(CB->getCallSite()->getCallSite());
			}
		}
		else if (auto AP = SVF::SVFUtil::dyn_cast<SVF::ActualParmSVFGNode>(vfgNode)) {
			if (!afterActualIn) {
				afterActualIn = 1;
				// errs() << "current actual parameter: " << *(AP->getCallSite()->getCallSite()) << "\n";
				TResult.TaintedCallBases.push_back(AP->getCallSite()->getCallSite());
			}
		}

		const Value* valNode = VFGNode2LLVMValue(vfgNode);
		const Value* predValNode = nullptr;
		if (predVFGNode != nullptr) {
		 predValNode = VFGNode2LLVMValue(predVFGNode);
		}
		// if (valNode == nullptr) {
		// 	errs() << "ValNode is nullptr " << "\n";
		// }
		// const Value*
		// if (SVF::SVFUtil::isa<SVF::ActualParmSVFGNode>(vfgNode)) {
		// 	if (valNode->getType()->isPointerTy()) {
		// 		errs() << "adding blinded ptr arg...\n";
		// 		errs() << vfgNode->toString() << "\n\n";
		// 		TResult.BlindedPtrArg.insert(valNode);
		// 	}
		// }

		// We briefly handle def-use of blinded pointers here
		// If we store blinded data into a pointer, then this pointer also becomes blinded
		if (const SVF::StoreVFGNode* storeNode = dyn_cast<const SVF::StoreVFGNode>(vfgNode)) {
			const Value* Instr = storeNode->getPAGEdge()->getValue();
			assert(Instr && "Failed to retrieve value from storevfgnode!");
			if (const StoreInst* storeInstr = dyn_cast<const StoreInst>(Instr)) {
				if (TResult.TaintedValues.count(storeInstr->getValueOperand())) {
					// if (!afterActualIn) {
						TResult.TaintedPointers.insert(storeInstr->getPointerOperand());
						propagateTaintedPointers(storeInstr->getPointerOperand());
						propagatePointers = true;
					// }
				}
			}
		}
		// If we load from a multi-layer blinded pointer, the loaded value is also a blinded pointer (this case is handled later)
		// If we use use blinded pointer as arithmetic operand

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
						// if (!afterActualIn) {
							TResult.TaintedPointers.insert(LI);
							propagateTaintedPointers(LI);
						// }
						// propagatePointers = true;
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
			if (TResult.TaintedPointers.count(valNode) && valNode->getType()->isPointerTy()) {
				// if (!afterActualIn) {
					propagateTaintedPointers(valNode);
				// }
			}
			if (propagateDefUse) {
				addTaintedValue(valNode);
				tempCtr++;
				// if (tempCtr == 100) {
				// 	llvm::outs() << "propagate " << *valNode << "\n";
				// 	tempCtr -= 100;
				// }

				for (auto valUser : valNode->users()) {
					const Value* valUserVal = dyn_cast<Value>(valUser);
					Value* NValUserVal = const_cast<Value*>(valUserVal);
					// handle blinded data
					if (isa<Instruction>(NValUserVal)
							&& !isa<StoreInst>(NValUserVal) && !isa<ReturnInst>(NValUserVal) && !isa<CallBase>(NValUserVal)) {
						const SVF::VFGNode* userVFGNode = LLVMValue2VFGNode(NValUserVal);
						if (NValUserVal != nullptr) {
							if (!handledNodes.count({vfgNode, userVFGNode})) {
								handledNodes.insert({vfgNode, userVFGNode});
								vfgNodeWorkList.push({vfgNode, userVFGNode});
								ActualInTimes.push(afterActualIn);
								#ifdef TRACEBACK_BLINDED
								TResult.TTGraph[userVFGNode].push_back(vfgNode);
								#endif
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
				handledNodes.insert({vfgNode, dstNode});
				vfgNodeWorkList.push({vfgNode, dstNode});
				ActualInTimes.push(afterActualIn);
				#ifdef TRACEBACK_BLINDED
				TResult.TTGraph[dstNode].push_back(vfgNode);
				#endif

			}
		}
	}

	errs() << "Done processing vfgNodeWorkList\n";
}

void BlindedTaintTracking::markInstrsForConversion(bool clear) {
	for (auto Val : TResult.TaintedPointers) {
		if (Val == nullptr) {
			continue;
		}
		errs() << "Fetching pts for blinded pointers: " << *Val << "\n";
		SVF::NodeID pNodeId = (ander ? ander->getPAG() : steens->getPAG())->getValueNode(Val);
		const SVF::NodeBS& pts = (ander ? ander->getPts(pNodeId) : steens->getPts(pNodeId));
		for (auto it = pts.begin(); it != pts.end(); it++) {
			if (!pag->hasGNode(*it)) {
				// errs() << "\n No pag Node for " << *it << "\n";
				continue;
			}
			auto pagNode = pag->getPAGNode(*it);
			if (SVF::SVFUtil::isa<SVF::DummyValPN>(pagNode)
					|| pagNode->getNodeKind() == SVF::PAGNode::DummyValNode
					|| pagNode->getNodeKind() == SVF::PAGNode::DummyObjNode) {
				// errs() << "\n pagnode is dummyvalpn " << *it << "\n";
				continue;
			}
			// errs() << "Added element from pts: " << *it << "\n";
			TResult.TaintedObjectsIDs.insert(*it);
		}
	}

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
			else if (const SelectInst* SelInst = dyn_cast<SelectInst>(ValUser)) {
				TResult.BlndSelect.push_back(SelInst);
			}
		}
	}
}

void BlindedTaintTracking::extractTaintSource(Function &F) {
	// errs() << F.getName() << "\n";

	for (auto Arg = F.arg_begin(); Arg < F.arg_end(); ++Arg) {
		if (Arg->hasAttribute(Attribute::Blinded)) {
			const SVF::VFGNode* taintedArg = LLVMValue2VFGNode(Arg);
			errs() << "Marking formal parameter: " << Arg->getName() << "\n";
			assert(taintedArg != nullptr && ("Failed to fetch VFGNode from taintedArg " + Arg->getName().str()).c_str());
			TaintSource.push_back(taintedArg);
			// if the formal parameter is a non-pointer type, it should also be a tainted value
			if (!Arg->getType()->isPointerTy()) {
				errs() << "Added to tainted values\n";
				TResult.TaintedValues.insert(Arg);
			} else {
				errs() << "Added to tainted pointers\n";
				TResult.TaintedPointers.insert(Arg);
			}
		}
	}
}

void BlindedTaintTracking::extractTaintSource(Module &M) {
	Module::GlobalListType &GL = M.getGlobalList();
	for (auto I = GL.begin(), E = GL.end(); I != E; ++I) {
		GlobalVariable &GV = *I;
		if (GV.hasAttribute(Attribute::Blinded)) {
			const SVF::VFGNode* taintedGVNode = LLVMValue2VFGNode(&GV);
			errs() << "Marking global variable: " << GV.getName() << "\n";
			assert(taintedGVNode != nullptr && ("Failed to fetch VFGNode from taintedGlobal " + GV.getName().str()).c_str());
			TaintSource.push_back(taintedGVNode);
			TResult.TaintedPointers.insert(&(*I));
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
	// errs() << "converting: " << *value << "\n";
	SVF::PAGNode* pNode = pag->getPAGNode(pag->getValueNode(value));
	const SVF::VFGNode* vfgNode = svfg->getDefSVFGNode(pNode);
	return vfgNode;
}

// Directly copied from SVF/SABER/ProgSlice.cpp
// Just don't want to create object to use this method
const Value* BlindedTaintTracking::VFGNode2LLVMValue(const SVF::SVFGNode* node) {
   if(const SVF::StmtSVFGNode* stmt = SVF::SVFUtil::dyn_cast<SVF::StmtSVFGNode>(node)) {
			if (SVF::SVFUtil::isa<SVF::StoreSVFGNode>(stmt)) {
				// auto SNode = SVF::SVFUtil::dyn_cast<SVF::StoreSVFGNode>(stmt);
				// SNode->toString();
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
	// buildSVFG(M);

	// beware that buildTaintedSet will always clear the Result
	// and marked tainted values
	buildTaintedSet(0, M);
	markInstrsForConversion();

	errs() << "BlindedTaintTracking complete!\n";

	return TResult;

}
