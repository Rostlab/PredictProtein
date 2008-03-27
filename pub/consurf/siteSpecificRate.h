#ifndef ___SITE_SPECIFIC_RATE
#define ___SITE_SPECIFIC_RATE

#include "definitions.h"
#include "sequenceContainer1G.h"
#include "stochasticProcess.h"
#include "treeInterface.h"
using namespace treeInterface;

MDOUBLE computeML_siteSpecificRate(Vdouble & ratesV,
								   Vdouble & likelihoodsV,
								   Vdouble & reliabilityV,
								   const sequenceContainer1G& sd,
								   const stochasticProcess& sp,
								   const tree& et,
								   const MDOUBLE maxRate=20.0f,
								   const MDOUBLE tol=0.0001f);

MDOUBLE computePosReliability(const sequenceContainer1G sd,const int pos);

#endif

