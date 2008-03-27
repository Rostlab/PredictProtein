#ifndef ___SEQUENCE_CONTAINER_TREE_MAP
#define ___SEQUENCE_CONTAINER_TREE_MAP

#include "sequenceContainer.h"
#include "treeInterface.h"
using namespace treeInterface;

class seqContainerTreeMap {
public:
	explicit seqContainerTreeMap(const sequenceContainer& sc,
								const tree& et) {
		_V.resize(et.iNodes());
		treeIterTopDownConst tit(et);
		for (tree::nodeP myN = tit.first();myN!=tit.end(); myN = tit.next()) {
			_V[myN->id()] = sc.getId(myN->name(),false);
		}
	}
	int seqIdOfNodeI(const int nodeID) {
		return _V[nodeID];
	}

private:
	vector<int> _V;// _V[i] is the sequenceId of node I.
};

#endif
