#include "treeUtil.h"
#include "treeIt.h"
#include <fstream>
#include <iostream>
#include <cassert>
using namespace std;
using namespace libtree_v1_0_0;

vector<tree> libtree_v1_0_0::getStartingTreeVecFromFile(string fileName) {
	vector<tree> vecT;
	ifstream inputf(fileName.c_str());
	if (inputf == NULL) {
		errorMsg::reportError("unable to open tree file");
	}
	while (!inputf.eof()) {
		//inputf.eatwhite();// do not remove. Tal: 1.1.2003
		vector<char> myTreeCharVec = PutTreeFileIntoVector(inputf);
		if (myTreeCharVec.size() >0) {
			tree t1(myTreeCharVec);
			//t1.output(cerr);
			vecT.push_back(t1);
		}
	}
	return vecT;
}

void libtree_v1_0_0::getStartingTreeVecFromFile(string fileName,
												vector<tree>& vecT,
												vector<char>& constraintsOfT0) {
	ifstream inputf(fileName.c_str());
	if (inputf == NULL) {
		errorMsg::reportError("unable to open tree file");
	}
	//inputf.eatwhite();
	for (int i=0; !inputf.eof() ; ++i) {
//	while (!inputf.eof()) {
		vector<char> myTreeCharVec = PutTreeFileIntoVector(inputf);
		if (myTreeCharVec.size() >0) {
			if (i==0) {
				tree t1(myTreeCharVec,constraintsOfT0);
				vecT.push_back(t1);
			}
			else {
				tree t1(myTreeCharVec);
				vecT.push_back(t1);
			}

		}
	}
}

void claimSons(tree::nodeP fatherP){
	if (fatherP==NULL) return;
	for(int i=0;i<fatherP->sons.size();i++) {
		fatherP->sons[i]->setFather(fatherP);
	}
}

void libtree_v1_0_0::rootToUnrootedTree(tree& et) {
	if (et.iRoot()->sons.size() > 2) return; // tree is already unrooted!

	if (et.iRoot()->sons[0]->sons.empty()) {
		tree::nodeP toRemove = et.iRoot()->sons[1];
		et.iRoot()->sons[0]->setDisToFather(et.iRoot()->sons[1]->dis2father()+et.iRoot()->sons[0]->dis2father());
		et.iRoot()->sons[1] = toRemove->sons[0];
		for (int k=1; k < toRemove->sons.size(); ++k) {
			et.iRoot()->sons.push_back(toRemove->sons[k]);
		}
		delete toRemove;
		claimSons(et.iRoot());
	}
	else {
		tree::nodeP toRemove = et.iRoot()->sons[0];
		et.iRoot()->sons[1]->setDisToFather(et.iRoot()->sons[0]->dis2father()+et.iRoot()->sons[1]->dis2father());
		et.iRoot()->sons[0] = toRemove->sons[0];
		for (int k=1; k < toRemove->sons.size(); ++k) {
			et.iRoot()->sons.push_back(toRemove->sons[k]);
		}
		delete toRemove;
		claimSons(et.iRoot());
	}
}


tree::nodeP libtree_v1_0_0::findNodeByName(const tree& et,const string& nodeName){
	treeIterTopDownConst tIt(et);
	for (tree::nodeP mynode = tIt.first(); mynode != tIt.end(); mynode = tIt.next()) {
		if (mynode->name() == nodeName) return mynode;
	}
	return NULL;
}

/*
bool libtree_v1_0_0::recursiveSameRootedSpecificTreeToplogy(const tree::nodeP& n1, const tree::nodeP& n2){
	if (n1->name() != n2->name()) return false;
	else if (n1->sons.size() != n2->sons.size()) return false;
	for (int i=0; i < n1->sons.size(); ++i) {
		if (!recursiveSameRootedSpecificTreeToplogy(n1->sons[i],n2->sons[i])) {
			return false;
		}
	}
	return true;
}

bool libtree_v1_0_0::sameRootedSpecificTreeTolopogy(const tree& t1, const tree&t2){
	return recursiveSameRootedSpecificTreeToplogy(t1.iRoot(),t2.iRoot());
}*/

#include <algorithm>
using namespace std;

bool libtree_v1_0_0::sameTreeTolopogy(tree t1, tree t2){
	if (t1.iNodes() != t2.iNodes()) {
		errorMsg::reportError("error in function same tree topology (1)");
	}
	tree::nodeP x = t2.iRoot();
	while (x->sons.size() > 0) x= x->sons[0];
	t1.rootAt(findNodeByName(t1,x->name())->father()); // now they have the same root
	t2.rootAt(findNodeByName(t2,x->name())->father()); // now they have the same root
	vector<string> names1(t1.iNodes());
	treeIterDownTopConst tit1(t1);
	for (tree::nodeP nodeM = tit1.first(); nodeM != tit1.end(); nodeM = tit1.next()) {
		vector<string> nameOfChild;
		for (int i=0; i < nodeM->sons.size();++i) {
			nameOfChild.push_back(names1[nodeM->sons[i]->id()]);
		}
		if (nodeM->sons.size()==0) nameOfChild.push_back(nodeM->name());
		sort(nameOfChild.begin(),nameOfChild.end());
		string res = "(";
		for (int k=0; k < nameOfChild.size(); ++k) {
			res += nameOfChild[k];
		}
		res += ")";
		names1[nodeM->id()] = res;
	}

	vector<string> names2(t1.iNodes());
	treeIterDownTopConst tit2(t2);
	for (tree::nodeP nodeM2 = tit2.first(); nodeM2 != tit2.end(); nodeM2 = tit2.next()) {
		vector<string> nameOfChild;
		for (int i=0; i < nodeM2->sons.size();++i) {
			nameOfChild.push_back(names2[nodeM2->sons[i]->id()]);
		}
		if (nodeM2->sons.size()==0) nameOfChild.push_back(nodeM2->name());
		sort(nameOfChild.begin(),nameOfChild.end());
		string res = "(";
		for (int k=0; k < nameOfChild.size(); ++k) {
			res += nameOfChild[k];
		}
		res += ")";
		names2[nodeM2->id()] = res;
	}
	return names1[t1.iRoot()->id()] == names2[t2.iRoot()->id()];
	


}


void libtree_v1_0_0::cutTreeToTwo(tree bigTree,
				  const string& nameOfNodeToCut,
				  tree &small1,
				  tree &small2){// cutting above the NodeToCut.
	// we want to cut the tree in two.
	// first step: we make a new node between the two nodes that have to be splited,
	tree::nodeP node2splitOnNewTree = bigTree.fromName(nameOfNodeToCut);
	string interNode = "interNode";
	assert(node2splitOnNewTree->father() != NULL);
	tree::nodeP tmp = makeNodeBetweenTwoNodes(bigTree,node2splitOnNewTree->father(),node2splitOnNewTree, interNode);
	bigTree.rootAt(tmp);
	cutTreeToTwoSpecial(bigTree,tmp, small1,small2);
	tree::nodeP toDel1 = small1.fromName(interNode);
	small1.removeLeaf(toDel1);
	tree::nodeP toDel2 = small2.fromName(interNode);
	small2.removeLeaf(toDel2);
	// this part fix the ids.
	treeIterTopDown tIt(small1);
	int newId =0;
	for (tree::nodeP mynode = tIt.first(); mynode != tIt.end(); mynode = tIt.next()) {
		mynode->setID(newId);
		newId++;
	}
	treeIterTopDown tIt2(small2);
	int newId2 =0;
	for (tree::nodeP mynode2 = tIt2.first(); mynode2 != tIt2.end(); mynode2 = tIt2.next()) {
		mynode2->setID(newId2);
		newId2++;
	}

};


void libtree_v1_0_0::cutTreeToTwoSpecial(const tree& source,
											 tree::nodeP intermediateNode,
											tree &resultT1PTR,
											tree &resultT2PTR) {
// pre-request:
// the intermediateNode is the root.
// and it has two sons.
// resultT1PTR & resultT2PTR are empty tree (root=NULL);
// make sure that you got two empty trees:
	if (resultT1PTR.iRoot() != NULL) errorMsg::reportError("got a non empty tree1 in function cutTreeToTwoSpecial"); 
	else if (resultT2PTR.iRoot() != NULL) errorMsg::reportError("got a non empty tree2 in function cutTreeToTwoSpecial"); 

// make sure the the intermediateNode is really an intermediate Node;
	if ((intermediateNode->sons.size() !=2 ) || (source.iRoot() != intermediateNode)) {
		errorMsg::reportError("intermediateNode in function cutTreeToTwoSpecial, is not a real intermediate node ");
	}

	resultT1PTR.createRootNode();
	resultT1PTR.iRoot()->setName(intermediateNode->name());

	resultT2PTR.createRootNode();
	resultT2PTR.iRoot()->setName(intermediateNode->name());

	
	resultT1PTR.recursiveBuildTree(resultT1PTR.iRoot(),intermediateNode->sons[0]);
	resultT1PTR.recursiveBuildTree(resultT2PTR.iRoot(),intermediateNode->sons[1]);
	resultT1PTR.updateNumberofNodesANDleaves();
	resultT2PTR.updateNumberofNodesANDleaves();

}



tree::nodeP libtree_v1_0_0::makeNodeBetweenTwoNodes(	tree& et,
											tree::nodeP fatherNode,
											tree::nodeP sonNode,
											const string &interName){
	//	first we make sure that fatherNode is indeed the father and sonNode is the son.
	if (fatherNode->father()	 == sonNode) {
		tree::nodeP tmp = fatherNode;
		fatherNode = sonNode;
		sonNode = tmp;
	}
	else if (sonNode->father() != fatherNode) {
		errorMsg::reportError("Error in function 'cut_tree_in_two'. the two nodes are not neighbours ");
	}
	// now fatherNode is the father and sonNode is the son.

	tree::nodeP theNewNodePTR = new tree::TreeNode(et.iNodes());// the new node that will be in the middle.

	// here we fix the tree information for the new node.
	theNewNodePTR->setName(interName);
	MDOUBLE tmpLen = sonNode->dis2father()*0.5;
	theNewNodePTR->setDisToFather(tmpLen);
	theNewNodePTR->setFather(fatherNode);
	theNewNodePTR->sons.clear();
	theNewNodePTR->sons.push_back(sonNode);

	// here we fix the tree information for the father node.
	for (int k=0; k<fatherNode->sons.size(); ++k) {
		if (fatherNode->sons[k] == sonNode) {
			fatherNode->sons[k] = theNewNodePTR;
			break;
		}
	}

	// here we fix the tree information for the sonNode.
	sonNode->setFather(theNewNodePTR);
	sonNode->setDisToFather(tmpLen);
	return theNewNodePTR;
}

