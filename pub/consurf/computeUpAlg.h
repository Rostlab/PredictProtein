#ifndef ___COMPUTE_UP_ALG
#define ___COMPUTE_UP_ALG

#include "suffStatComponent.h"
#include "sequenceContainer.h"
#include "treeInterface.h"
#include "computePijComponent.h"

using namespace treeInterface;

class computeUpAlg {
public: 
	void fillComputeUp(const tree& et,
					   const sequenceContainer& sc,
					   const int pos,
					   const computePijHom& pi,
					   suffStatGlobalHomPos& ssc);

	void fillComputeUp(const tree& et,
					   const sequenceContainer& sc,
					   const int pos,
					   const stochasticProcess& sp,
					   suffStatGlobalHomPos& ssc);

	/*void fillComputeUp(const tree& et, // not to be used, accept for debuging (very slow func.)
					   const sequenceContainer& sc,
					   const stochasticProcess& sp,
					   suffStatGlobalGam& ssc);*/

	void fillComputeUpSpecificGlobalRate(const tree& et,
				   const sequenceContainer& sc,
				   const int pos,
				   const stochasticProcess& sp,
				   suffStatGlobalHomPos& ssc,
				   const MDOUBLE gRate);

// my attemp to add factors
	void fillComputeUpWithFactors(const tree& et,
				   const sequenceContainer& sc,
				   const int pos,
				   const computePijHom& pi,
				   suffStatGlobalHomPos& ssc,
				   vector<MDOUBLE>& factors);
	void fillComputeUpWithFactors(const tree& et,
				   const sequenceContainer& sc,
				   const int pos,
				   const stochasticProcess& sp,
				   suffStatGlobalHomPos& ssc,
				   vector<MDOUBLE>& factors);
	void computeUpAlg::fillComputeUpSpecificGlobalRateFactors(const tree& et,
				   const sequenceContainer& sc,
				   const int pos,
				   const stochasticProcess& sp,
				   suffStatGlobalHomPos& ssc,
				   const MDOUBLE gRate,
				   vector<MDOUBLE>& factors);
};
#endif


