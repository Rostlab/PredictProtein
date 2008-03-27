#ifndef ___SIMULATE_TREE
#define ___SIMULATE_TREE

#include "treeInterface.h"
using namespace treeInterface;

#include "stochasticProcess.h"
#include "sequenceContainer1G.h"

//class sequenceData; // to be able to go to simulate data.

class simulateTree {
public:
	explicit simulateTree(const tree&  _inEt,const stochasticProcess& sp,
		const alphabet* alph);
	void generate_seq(int seqLength);
	void generate_seqWithRateVector(const vector<MDOUBLE>& rateVec, 
											  const int seqLength);	
	tree gettree() {return _et;}
	virtual ~simulateTree();
	sequenceContainer1G toSeqData();
	sequenceContainer1G toSeqDataWithoutInternalNodes();

private:
  void generateRootSeq(int seqLength);	
  void recursiveGenerateSpecificSeq(const vector<MDOUBLE> &rateVec,
				       const int seqLength,
				       tree::nodeP myNode);

  int giveRandomChar() const;
  int giveRandomChar(const int letterInFatherNode, const MDOUBLE length,const int pos) const;
  int getRandCategory(const int pos) const;

	vector<sequence> _simulatedSequences; // the sequences (nodes * seqLen)
	tree _et;
	const stochasticProcess& _sp;
	const alphabet* _alph;
};

#endif

