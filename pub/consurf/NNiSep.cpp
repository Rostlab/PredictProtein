#include "NNiSep.h"
#include "brLenOptEM.h"
#include <algorithm>
#include <iostream>
#include <iomanip>

using namespace brLenOptEM;
using namespace std;

NNiSep::NNiSep(vector<sequenceContainer1G>& sc,
					 vector<stochasticProcess>& sp,
					const vector<Vdouble *> * weights,
					vector<char>* nodeNotToSwap): _nodeNotToSwap(nodeNotToSwap),
								_sc(sc),_sp(sp),_weights(weights) {
	_bestTrees.resize(sc.size());
	_bestScore=VERYSMALL;
	_treeEvaluated =-1;

}

void NNiSep::setOfstream(ostream* out) {
	_out = out;
}


vector<tree> NNiSep::NNIstep(vector<tree> et) {
	const int nGene = et.size();
	int z;
	for (z=0; z < nGene; ++z) {
		et[z].create_names_to_internal_nodes();
	}
	_bestTrees = et;
	_bestScore = evalTrees(_bestTrees);
	
	treeIterTopDown tIt(et[0]);

	vector<tree::nodeP> mynode(nGene);
	mynode[0] = tIt.first();
	for (z=1; z < nGene; ++z ) {
		mynode[z] = findNodeByName(et[z],mynode[0]->name());	
	}

	while (mynode[0] != tIt.end()) {
		bool haveToBeChecked = true;
		if ((isLeaf(mynode[0]) || mynode[0]->isRoot())) haveToBeChecked = false;
		if (_nodeNotToSwap) {
			if ((*_nodeNotToSwap)[mynode[0]->id()]) {
				haveToBeChecked = false;
			}
		}

		if (haveToBeChecked) { // swaping only internal nodes that are not "fixed"
			for (z=1; z < nGene; ++z ) {
				mynode[z] = findNodeByName(et[z],mynode[0]->name());	
			}
			
			vector<tree> newT1;	
			vector<tree> newT2;

			for (z=0; z < nGene; ++z ) {
				newT1.push_back(NNIswap1(et[z],mynode[z]));
				newT2.push_back(NNIswap2(et[z],mynode[z]));
			}
			MDOUBLE treeScore1 = evalTrees(newT1);
			if (treeScore1 > _bestScore) {
				_bestTrees = newT1;
				_bestScore = treeScore1;
				cerr<<"new Best Trees: "<<_bestScore<<endl;
				if (_out) (*_out)<<"new Best Tree: "<<_bestScore<<endl;
				if (_out) (*_out)<<"tree topology (of gene 1 in case of many genes): "<<endl;
				_bestTrees[0].output(*_out);
			}
			MDOUBLE treeScore2 = evalTrees(newT2);
			if (treeScore2 > _bestScore) {
				_bestTrees = newT2;
				_bestScore = treeScore2;
				cerr<<"new Best Trees: "<<_bestScore<<endl;
				if (_out) (*_out)<<"new Best Tree: "<<_bestScore<<endl;
				if (_out) (*_out)<<"tree topology (of gene 1 in case of many genes): "<<endl;
				_bestTrees[0].output(*_out);
			}
		}
		//nextloop:
		mynode[0] = tIt.next();
	}
	return _bestTrees;
}

tree NNiSep::NNIswap1(tree et,tree::nodeP mynode) {
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

tree NNiSep::NNIswap2(tree et,tree::nodeP mynode) {
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
#endif
	return et;

}





MDOUBLE NNiSep::evalTrees(vector<tree>& et) {
#ifdef VERBOS
	cerr<<"b4 bbl in alltrees"<<endl;
	et.output(cerr);
#endif
	MDOUBLE res = brLenOptEM::optimizeBranchLengthNG_EM_SEP(et,_sc,_sp,_weights);
	_treeEvaluated++;
	cerr.precision(5);
	_out->precision(5);

	
	if (_treeEvaluated) cerr<<"tree: "<<_treeEvaluated<< "score = "<<res<<endl;
	if ((_out)&&(_treeEvaluated)) (*_out)<<"tree: "<<_treeEvaluated<< "score = "<<res<<endl;
	return res;
}	




