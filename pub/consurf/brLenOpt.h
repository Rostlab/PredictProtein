#ifndef ___BRANCH_LEN_OPT
#define ___BRANCH_LEN_OPT

#include "treeInterface.h"
using namespace treeInterface;
#include "computePijComponent.h"
#include "sequenceContainer1G.h"

namespace brLenOpt {

	MDOUBLE optimizeBranchLength1G(	tree& et,
									sequenceContainer1G& sc,
									stochasticProcess& sp,
									const Vdouble * weights,
									const int maxIterations=1000,
									const MDOUBLE epsilon=0.0001);
/*



private:
	MDOUBLE optimizeBranchLengthPrivate(const int maxIterations,
									   const MDOUBLE epsilon);

	void revaluateBranchLengthIt0(tree::nodeP in_nodep,
									   const suffStatComponent& cup,
									   const suffStatComponent& cdown);
	
	
	void nwRafImprovIt0(tree::nodeP in_nodep,
									   const suffStatComponent& cup,
									   const suffStatComponent& cdown);
	
	bool reCheckAfterEachBrLenChange;
	void revaluateBranchLength(tree::nodeP in_nodep,
									   const suffStatComponent& cup,
									   const suffStatComponent& cdown);

	void nwRafImprov(tree::nodeP in_nodep,
									   const suffStatComponent& cup,
									   const suffStatComponent& cdown);

	void compute_dltk_d2ltk2(const int nodeId,
							const suffStatComponent& cup,
							const suffStatComponent& cdown,
							MDOUBLE& ltk,
							MDOUBLE& dltk,
							MDOUBLE& d2ltk2);
	MDOUBLE computeLtkCheck(const int nodeId,
								   const suffStatComponent& cup,
								   const suffStatComponent& cdown,
								   MDOUBLE newDist);
	int _alphabetSize;
	int _seqLen;
	tree& _et;
	positionInfo &_pi; //notice that the pij value information if changing.
	const Vdouble* _weightsPtr;
*/
};


#endif


