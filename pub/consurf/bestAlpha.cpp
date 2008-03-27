#include "bestAlpha.h"
#include <iostream>
using namespace std;

#include "brLenOptEM.h"
#include "numRec.h"

#define VERBOS
//void bestAlpha::checkAllocation() {
//	if (_pi->stocProcessFromLabel(0)->getPijAccelerator() == NULL) {
//		errorMsg::reportError(" error in function findBestAlpha");
//	}
//}
//
bestAlphaAndBBL::bestAlphaAndBBL(tree& et, //find Best Alpha and best BBL
					   const sequenceContainer1G& sc,
					   stochasticProcess& sp,
					   const Vdouble * weights,
					   const MDOUBLE upperBoundOnAlpha,
					   const MDOUBLE epsilonAlphaOptimization,
					   const MDOUBLE epsilonLikelihoodImprovment,
					   const int maxBBLIterations,
					   const int maxTotalIterations){
//	cerr<<"find Best Alpha and best BBL"<<endl;
//	cerr<<" 1. bestAlpha::findBestAlpha"<<endl;
//	brLenOpt br1(*et,*pi,weights);
	MDOUBLE oldL = VERYSMALL;
	MDOUBLE newL = VERYSMALL;
	const MDOUBLE bx=upperBoundOnAlpha*0.3;
	const MDOUBLE ax=0;
	const MDOUBLE cx=upperBoundOnAlpha;
//
	MDOUBLE bestA=0;
	int i=0;
	for (i=0; i < maxTotalIterations; ++i) {
		newL = -brent(ax,bx,cx,
		C_evalAlpha(et,sc,sp,weights),
		epsilonAlphaOptimization,
		&bestA);

#ifdef VERBOS
		cerr<<"new L = " << newL<<endl;
		cerr<<"new Alpha = " <<bestA<<endl;
#endif
		if (newL > oldL+epsilonLikelihoodImprovment) {
			oldL = newL;
		} else {
			_bestL = oldL;
			_bestAlpha= bestA;
			break;
		}

		(static_cast<gammaDistribution*>(sp.distr()))->setAlpha(bestA);
		newL =brLenOptEM::optimizeBranchLength1G_EM(et,sc,sp,NULL,maxBBLIterations,epsilonLikelihoodImprovment);//maxIterations=1000
#ifdef VERBOS
		cerr<<"new L = " << newL<<endl;
#endif

		if (newL > oldL+epsilonLikelihoodImprovment) {
			oldL = newL;
		}
		else {
			_bestL = oldL;
			_bestAlpha= bestA;
			break;
		}
	}
	if (i==maxTotalIterations) {
		_bestL = newL;
		_bestAlpha= bestA;
	}
}
		
bestAlphaFixedTree::bestAlphaFixedTree(const tree& et, //findBestAlphaFixedTree
					   const sequenceContainer1G& sc,
					   stochasticProcess& sp,
					   const Vdouble * weights,
					   const MDOUBLE upperBoundOnAlpha,
					   const MDOUBLE epsilonAlphaOptimization){
	//cerr<<"findBestAlphaFixedTree"<<endl;
	MDOUBLE bestA=0;
	const MDOUBLE cx=upperBoundOnAlpha;// left, midle, right limit on alpha
	const MDOUBLE bx=cx*0.3;
	const MDOUBLE ax=0;

	
	_bestL = -brent(ax,bx,cx,
		C_evalAlpha(et,sc,sp,weights),
		epsilonAlphaOptimization,
		&bestA);
	_bestAlpha= bestA;
}

