#include "allTrees.h"
#include "brLenOptEM.h"
#include <algorithm>
#include <iostream>

#include "someUtil.h"

using namespace brLenOptEM;
using namespace std;
#define VERBOS

allTrees::allTrees(bool keepAllTrees) : _keepAllTrees(keepAllTrees) {
	_bestScore = VERYSMALL;
}

void get3seqTreeAndIdLeftVec(const sequenceContainer1G* sc,
							 tree& starT,
							 vector<int>& idList){
	sequenceContainer1G::constTaxaIterator tIt;
	sequenceContainer1G::constTaxaIterator tItEnd;
	tIt.begin(*sc);
	tItEnd.end(*sc);
	while(tIt != tItEnd) {
		idList.push_back(tIt->id());
		++tIt;
	}
	if (sc->numberOfSequences()<3) errorMsg::reportError(" searching a tree for number of sequences < 3 ");
	starT.createRootNode();
	starT.createNode(starT.iRoot(),1);
	starT.createNode(starT.iRoot(),2);
	starT.createNode(starT.iRoot(),3);
	
	const string nameOfSeq1 = (*sc)[idList[idList.size()-1]].name();
	const string nameOfSeq2 = (*sc)[idList[idList.size()-2]].name();
	const string nameOfSeq3 = (*sc)[idList[idList.size()-3]].name();
	idList.pop_back();
	idList.pop_back();
	idList.pop_back();

	starT.iRoot()->sons[0]->setName(nameOfSeq1);
	starT.iRoot()->sons[1]->setName(nameOfSeq2);
	starT.iRoot()->sons[2]->setName(nameOfSeq3);
	starT.createFlatLengthMatrix();
}

void allTrees::recursiveFind(	const sequenceContainer1G* sc,
								const stochasticProcess* sp,
								const Vdouble * weights,
								const int maxIterations,
								const MDOUBLE epsilon){
	tree starT;
	vector<int> ids;
	get3seqTreeAndIdLeftVec(sc,starT,ids);
	recursiveFind(starT,*sp,*sc,ids,weights,maxIterations,epsilon);
}

tree getAnewTreeFrom(	const tree& et,
								tree::nodeP & mynode,
								vector<int> & idLeft,
								const string& nameToAdd) {
	tree newT = et;
	tree::nodeP mynodeInNewTree = findNodeByName(newT,mynode->name());
//	int NameToAdd = idLeft[idLeft.size()-1]; 
	idLeft.pop_back();
	tree::nodeP fatherNode = mynodeInNewTree->father();
	tree::nodeP newInternalNode = newT.createNode(fatherNode,newT.iNodes());
	mynodeInNewTree->setFather(newInternalNode);
	newInternalNode->sons.push_back(mynodeInNewTree);
	vector<tree::nodeP>::iterator vec_iter;
	vec_iter = remove(fatherNode->sons.begin(),fatherNode->sons.end(),mynodeInNewTree);
	fatherNode->sons.erase(vec_iter,fatherNode->sons.end()); // pg 1170, primer.
	tree::nodeP newOTU= newT.createNode(newInternalNode,newT.iNodes());;
	//string nameX = (*sc)[NameToAdd].name();
	newOTU->setName(nameToAdd);
	newOTU->setDisToFather(tree::FLAT_LENGTH_VALUE);
	newInternalNode->setDisToFather(tree::FLAT_LENGTH_VALUE);
	newT.create_names_to_internal_nodes();

	return newT;
}

void allTrees::recursiveFind(tree et,
							 const stochasticProcess& sp,
							 const sequenceContainer1G& sc,
							 vector<int> idLeft,
							 const Vdouble * weights,
							 const int maxIterations,
							 const MDOUBLE epsilon) {

	if (idLeft.empty()) {
		//static int k=1;	k++;
		MDOUBLE treeScore = evalTree(et,sp,sc,maxIterations,epsilon,weights);
		if (_keepAllTrees) {
			_allPossibleTrees.push_back(et);
			_allPossibleScores.push_back(treeScore);
		}
		cerr<<".";
		//cerr<<"tree: "<<k<<" l= "<<treeScore<<endl;
		if (treeScore > _bestScore) {
			//cerr<<"new Best score!"<<endl;
			_bestTree = et;
			_bestScore = treeScore;
		}
	} else {
		treeIterTopDown tIt(et);
		tree::nodeP mynode = tIt.first();
		mynode = tIt.next(); // skipping the root
		for (; mynode != tIt.end(); mynode = tIt.next()) {
			int NameToAdd = idLeft[idLeft.size()-1]; 
			tree newT = getAnewTreeFrom(et,mynode,idLeft,sc[NameToAdd].name());
			recursiveFind(newT,sp,sc,idLeft,weights,maxIterations,epsilon);
			idLeft.push_back(NameToAdd);
		}
	}
}

MDOUBLE allTrees::evalTree(	tree& et,
							const stochasticProcess& sp,
							const sequenceContainer1G& sc,
							const int maxIterations,
							const MDOUBLE epsilon,
							const Vdouble * weights) {
	MDOUBLE res = 0;
	res = brLenOptEM::optimizeBranchLength1G_EM(et,sc,sp,weights,maxIterations,epsilon);
	return res;
}	




