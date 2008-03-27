#ifndef ___TREE_UTIL
#define ___TREE_UTIL

#include "tree.h"
namespace libtree_v1_0_0 {

	vector<tree> getStartingTreeVecFromFile(string fileName);
	void getStartingTreeVecFromFile(string fileName,
												vector<tree>& vecT,
												vector<char>& constraintsOfT0);

	inline bool isSon(const tree::nodeP iFather, const tree::nodeP iSon) {
		return (iSon->father() == iFather);
	}

	inline int nSons(const tree::nodeP inNodeP) {
		return inNodeP->sons.size() ;
	}

	inline bool isLeaf(const tree::nodeP inNodeP) {
		return ((inNodeP->sons.empty()) || ((inNodeP->isRoot()) &&(inNodeP->sons.size()==1))) ;
	}

	inline bool isInternal(const tree::nodeP inNodeP) {
		return (!isLeaf(inNodeP));
	}

	void rootToUnrootedTree(tree& et);
	tree::nodeP findNodeByName(const tree& T,const string& nodeName);

//	bool sameRootedSpecificTreeTolopogy(const tree& t1, const tree&t2);
		// this function return TRUE only if the first son of the root of t1
		// is the same first son of the root of t2. I.e., if t1 and t2 have
		// the same topology, but the order of the sons are not the same - 
		// this function will return FALSE!

//	bool recursiveSameRootedSpecificTreeToplogy(const tree::nodeP& n1, const tree::nodeP& n2);
		// this function is the same as above, but can also be used for subtrees.

	bool sameTreeTolopogy(tree t1, tree t2);

	void cutTreeToTwo(tree bigTree,
				  const string& nameOfNodeToCut,
				  tree &small1,
				  tree &small2);
	tree::nodeP makeNodeBetweenTwoNodes(	tree& et,
											tree::nodeP nodePTR1,
											tree::nodeP nodePTR2,
											const string &interName);
	void cutTreeToTwoSpecial(const tree& source,
							tree::nodeP intermediateNode,
							tree &resultT1PTR,
							tree &resultT2PTR);
}

#endif
