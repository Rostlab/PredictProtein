#ifndef ___LIKELIHOOD_COMPUTATION_FACTORS
#define ___LIKELIHOOD_COMPUTATION_FACTORS

#include "treeInterface.h"
using namespace treeInterface;
#include "computePijComponent.h"
#include "sequenceContainer.h"
#include "suffStatComponent.h"

namespace likelihoodComputation {

	MDOUBLE getLOG_LofPos(const int pos, // with a site specific rate.
					  const tree& et,
					  const sequenceContainer& sc,
					  const stochasticProcess& sp,
					  const MDOUBLE gRate);

	// add all the other functions to use factors...


};



#endif

