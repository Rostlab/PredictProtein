// version 1.00
// last modified 3 Nov 2002

#include "Nni.h"
#include "brLenOptEM.h"
#include <algorithm>
#include <iostream>
using namespace brLenOptEM;
using namespace std;

NNI::NNI(const sequenceContainer1G& sc,
				   const stochasticProcess& sp,
				const Vdouble * weights): _sc(sc),_sp(sp),_weights(weights) {
	_bestScore = VERYSMALL;
}


tree NNI::NNIstep(tree et) {
	et.create_names_to_internal_nodes();
	treeIterTopDown tIt(et);
	for (tree::nodeP mynode = tIt.first(); mynode != tIt.end(); mynode = tIt.next()) {
		if (isLeaf(mynode) || mynode->isRoot()) continue; // swaping only internal nodes
		tree newT1 = NNIswap1(et,mynode);
		tree newT2 = NNIswap2(et,mynode);
		MDOUBLE treeScore1 = evalTree(newT1,_sc);
		MDOUBLE treeScore2 = evalTree(newT2,_sc);
		if (treeScore1 > _bestScore) {
			_bestTree = newT1;
			_bestScore = treeScore1;
			cerr<<"new Best Tree: "<<_bestScore<<endl;
			et.output(cerr);
		}
		if (treeScore2 > _bestScore) {
			_bestTree = newT2;
			_bestScore = treeScore2;
			cerr<<"new Best Tree: "<<_bestScore<<endl;
			et.output(cerr);
		}
	}
	return _bestTree;
}

tree NNI::NNIswap1(tree et,tree::nodeP mynode) {
	tree::nodeP mynodeInNewTree = findNodeByName(et,mynode->name());
#ifdef VERBOS
	cerr<<"b4 swap1"<<endl;
	et.output(cerr);i
#endif

	tree::nodeP fatherNode = mynodeInNewTree->father();
	tree::nodeP nodeToSwap1 = mynodeInNewTree->father()->sons[0];
	// it might be me
	if (nodeToSwap1 == mynodeInNewTree) nodeToSwap1 = mynodeInNewTree->father()->sons[1];
	tree::nodeP nodeToSwap2 = mynodeInNewTree->sons[0];

	et.removeNodeFromSonListOfItsFather(nodeToSwap1);
	et.removeNodeFromSonListOfItsFather(nodeToSwap2);
	nodeToSwap2->setFather(fatherNode);
	fatherNode->sons.push_back(nodeToSwap2);
	nodeToSwap1->setFather(mynodeInNewTree);
	mynodeInNewTree->sons.push_back(nodeToSwap1);
#ifdef VERBOS
	cerr<<"after swap1"<<endl;
	et.output(cerr);
#endif
	
	return et;
}

tree NNI::NNIswap2(tree et,tree::nodeP mynode) {
#ifdef VERBOS
	cerr<<"b4 swap2"<<endl;
	et.output(cerr);
#endif
	tree::nodeP mynodeInNewTree = findNodeByName(et,mynode->name());


	tree::nodeP fatherNode = mynodeInNewTree->father();
	tree::nodeP nodeToSwap1 = mynodeInNewTree->father()->sons[0];
	// it might be me
	if (nodeToSwap1 == mynodeInNewTree) nodeToSwap1 = mynodeInNewTree->father()->sons[1];
	tree::nodeP nodeToSwap2 = mynodeInNewTree->sons[1];
	et.removeNodeFromSonListOfItsFather(nodeToSwap1);
	et.removeNodeFromSonListOfItsFather(nodeToSwap2);
	nodeToSwap2->setFather(fatherNode);
	fatherNode->sons.push_back(nodeToSwap2);
	nodeToSwap1->setFather(mynodeInNewTree);
	mynodeInNewTree->sons.push_back(nodeToSwap1);
#ifdef VERBOS
	cerr<<"after swap2"<<endl;
	et.output(cerr);
#endif //VERBOS
	return et;

}





MDOUBLE NNI::evalTree(tree& et,const sequenceContainer1G& sc) {
#ifdef VERBOS
	cerr<<"b4 bbl in alltrees"<<endl;
	et.output(cerr);
#endif
	MDOUBLE res = brLenOptEM::optimizeBranchLength1G_EM(et,sc,_sp,_weights);
	return res;
}	




