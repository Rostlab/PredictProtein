#ifndef ___BRANCH_LEN_OPT_EM
#define ___BRANCH_LEN_OPT_EM

#include "treeInterface.h"
using namespace treeInterface;
#include "computePijComponent.h"
#include "sequenceContainer1G.h"
#include "sequenceContainerNG.h"

namespace brLenOptEM {

	MDOUBLE optimizeBranchLength1G_EM(	tree& et,
									const sequenceContainer1G& sc,
									const stochasticProcess& sp,
									const Vdouble * weights,
									const int maxIterations=1000,
									const MDOUBLE epsilon=0.05,
									const MDOUBLE tollForPairwiseDist=0.0001);//
	MDOUBLE optimizeBranchLengthNG_EM_SEP(vector<tree>& et,
									const vector<sequenceContainer1G>& sc,
									const vector<stochasticProcess> &sp,
									const vector<Vdouble *> * weights,
									const int maxIterations=1000,
									const MDOUBLE epsilon=0.05,
									const MDOUBLE tollForPairwiseDist=0.0001);
	MDOUBLE optimizeBranchLengthNG_EM_PROP( // also for the CONCATANATE MODEL. DOESN'T CHANGE THE RATE OF EACH GENE!
									tree& et,
									const vector<sequenceContainer1G>& sc,
									const vector<stochasticProcess>& sp,
									const vector<Vdouble *> * weights = NULL,
									const int maxIterations=1000,
									const MDOUBLE epsilon=0.05,
									const MDOUBLE tollForPairwiseDist=0.0001);
};


#endif


