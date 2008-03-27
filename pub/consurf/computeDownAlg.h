#ifndef ___COMPUTE_DOWN_ALG
#define ___COMPUTE_DOWN_ALG

#include "suffStatComponent.h"
#include "sequenceContainer.h"
#include "treeInterface.h"
#include "computePijComponent.h"

using namespace treeInterface;

class computeDownAlg {
public: 
	void fillComputeDown(const tree& et,
					   const sequenceContainer& sc,
					   const int pos,
					   const computePijHom& pi,
					   suffStatGlobalHomPos& ssc,
					   const suffStatGlobalHomPos& cup);
};
#endif
