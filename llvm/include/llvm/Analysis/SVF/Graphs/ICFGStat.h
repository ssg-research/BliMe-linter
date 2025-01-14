//===- ICFGStat.h ----------------------------------------------------------//
//
//                     SVF: Static Value-Flow Analysis
//
// Copyright (C) <2013-2018>  <Yulei Sui>
//

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//
//===----------------------------------------------------------------------===//
/*
 * ICFGStat.h
 *
 *  Created on: 12Sep.,2018
 *      Author: yulei
 */

#ifndef INCLUDE_UTIL_ICFGSTAT_H_
#define INCLUDE_UTIL_ICFGSTAT_H_

#include "llvm/Analysis/SVF/MemoryModel/PTAStat.h"
#include "llvm/Analysis/SVF/Graphs/ICFG.h"
#include <iomanip>

namespace SVF
{

class ICFGStat : public PTAStat
{

private:
    ICFG *icfg;
    int numOfNodes;
    int numOfCallNodes;
    int numOfRetNodes;
    int numOfEntryNodes;
    int numOfExitNodes;
    int numOfIntraNodes;

    int numOfEdges;
    int numOfCallEdges;
    int numOfRetEdges;
    int numOfIntraEdges;

public:
    typedef Set<const ICFGNode *> ICFGNodeSet;

    ICFGStat(ICFG *cfg) : PTAStat(nullptr), icfg(cfg)
    {
        numOfNodes = 0;
        numOfCallNodes = 0;
        numOfRetNodes = 0;
        numOfEntryNodes = 0;
        numOfExitNodes = 0;
        numOfIntraNodes = 0;

        numOfEdges = 0;
        numOfCallEdges = 0;
        numOfRetEdges = 0;
        numOfIntraEdges = 0;

    }

    void performStat()
    {

        countStat();

        PTNumStatMap["ICFGNode"] = numOfNodes;
        PTNumStatMap["IntraBlockNode"] = numOfIntraNodes;
        PTNumStatMap["CallBlockNode"] = numOfCallNodes;
        PTNumStatMap["RetBlockNode"] = numOfRetNodes;
        PTNumStatMap["FunEntryBlockNode"] = numOfEntryNodes;
        PTNumStatMap["FunExitBlockNode"] = numOfExitNodes;

        PTNumStatMap["ICFGEdge"] = numOfEdges;
        PTNumStatMap["CallCFGEdge"] = numOfCallEdges;
        PTNumStatMap["RetCFGEdge"] = numOfRetEdges;
        PTNumStatMap["IntraCFGEdge"] = numOfIntraEdges;

        printStat("ICFG Stat");
    }

    void performStatforIFDS()
    {

        countStat();
        PTNumStatMap["ICFGNode(N)"] = numOfNodes;
        PTNumStatMap["CallBlockNode(Call)"] = numOfCallNodes;
        PTNumStatMap["ICFGEdge(E)"] = numOfEdges;
        printStat("IFDS Stat");
    }

    void countStat()
    {
        ICFG::ICFGNodeIDToNodeMapTy::iterator it = icfg->begin();
        ICFG::ICFGNodeIDToNodeMapTy::iterator eit = icfg->end();
        for (; it != eit; ++it)
        {
            numOfNodes++;

            ICFGNode *node = it->second;

            if (SVFUtil::isa<IntraBlockNode>(node))
                numOfIntraNodes++;
            else if (SVFUtil::isa<CallBlockNode>(node))
                numOfCallNodes++;
            else if (SVFUtil::isa<RetBlockNode>(node))
                numOfRetNodes++;
            else if (SVFUtil::isa<FunEntryBlockNode>(node))
                numOfEntryNodes++;
            else if (SVFUtil::isa<FunExitBlockNode>(node))
                numOfExitNodes++;


            ICFGEdge::ICFGEdgeSetTy::iterator edgeIt =
                it->second->OutEdgeBegin();
            ICFGEdge::ICFGEdgeSetTy::iterator edgeEit =
                it->second->OutEdgeEnd();
            for (; edgeIt != edgeEit; ++edgeIt)
            {
                const ICFGEdge *edge = *edgeIt;
                numOfEdges++;
                if (edge->isCallCFGEdge())
                    numOfCallEdges++;
                else if (edge->isRetCFGEdge())
                    numOfRetEdges++;
                else if (edge->isIntraCFGEdge())
                    numOfIntraEdges++;
            }
        }
    }

    void printStat(string statname)
    {

        std::cout << "\n************ " << statname << " ***************\n";
        std::cout.flags(std::ios::left);
        unsigned field_width = 20;
        for(NUMStatMap::iterator it = PTNumStatMap.begin(), eit = PTNumStatMap.end(); it!=eit; ++it)
        {
            // format out put with width 20 space
            std::cout << std::setw(field_width) << it->first << it->second << "\n";
        }
        PTNumStatMap.clear();
        std::cout.flush();
    }
};

} // End namespace SVF

#endif /* INCLUDE_UTIL_ICFGSTAT_H_ */

