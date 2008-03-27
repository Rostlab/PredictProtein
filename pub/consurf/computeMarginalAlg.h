#ifndef ___COMPUTE_MARGINAL_ALG
#define ___COMPUTE_MARGINAL_ALG

#include "suffStatComponent.h"
#include "sequenceContainer.h"
#include "treeInterface.h"
#include "computePijComponent.h"

using namespace treeInterface;

class computeMarginalAlg {
public: 
	void fillComputeMarginal(const tree& et,
					   const sequenceContainer& sc,
					   const stochasticProcess& sp,
					   const int pos,
					   const computePijHom& pi,
					   suffStatGlobalHomPos& ssc,
					   const suffStatGlobalHomPos& cup,
					   const suffStatGlobalHomPos& cdown,
					   MDOUBLE & posProb);
};
#endif
