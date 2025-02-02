#ifndef INCLUDE_SVF_FE_GRAPH2JSON_H_
#define INCLUDE_SVF_FE_GRAPH2JSON_H_

#include "llvm/Analysis/SVF/Graphs/PAG.h"
#include "llvm/Analysis/SVF/Graphs/PAGEdge.h"
#include "llvm/Analysis/SVF/Graphs/PAGNode.h"
#include "llvm/Analysis/SVF/Graphs/ICFG.h"
#include "llvm/Analysis/SVF/Graphs/ICFGNode.h"
#include "llvm/Analysis/SVF/Graphs/ICFGEdge.h"
#include "llvm/Analysis/SVF/SVF-FE/LLVMUtil.h"

namespace SVF
{

class GraphWriter;
class ICFGPrinter : public ICFG
{
public:
    ICFGPrinter();

    void printICFGToJson(const std::string& filename);

    std::string getPAGNodeKindValue(int kind);

    std::string getPAGEdgeKindValue(int kind);

    std::string getICFGKind(const int kind);
};

} // End namespace SVF

#endif
