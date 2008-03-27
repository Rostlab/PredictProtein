#include "tree.h"
#include "treeIt.h"
#include "treeUtil.h"

namespace treeInterface {
	using libtree_v1_0_0::isInternal;
	using libtree_v1_0_0::tree;
	using libtree_v1_0_0::treeIterTopDown;
	using libtree_v1_0_0::treeIterTopDownConst;

	using libtree_v1_0_0::treeIterDownTopConst;
	using libtree_v1_0_0::isLeaf;
	using libtree_v1_0_0::isSon;
	using libtree_v1_0_0::nSons;

	using libtree_v1_0_0::rootToUnrootedTree;
	using libtree_v1_0_0::findNodeByName;
	using libtree_v1_0_0::getStartingTreeVecFromFile;

//	using libtree_v1_0_0::sameRootedSpecificTreeTolopogy; // see treeUtil.h for details
//	using libtree_v1_0_0::recursiveSameRootedSpecificTreeToplogy; // see treeUtil.h for details
	using libtree_v1_0_0::sameTreeTolopogy;

}

