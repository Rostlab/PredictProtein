#include "bestHKYparam.h"
#include <iostream>
using namespace std;

#include "brLenOptEM.h"
#include "numRec.h"

bestHkyParamAndBBL::bestHkyParamAndBBL(tree& et, //find Best HkyParam and best BBL
					   const sequenceContainer1G& sc,
					   stochasticProcess& sp,
					   const Vdouble * weights,
					   const MDOUBLE upperBoundOnHkyParam,
					   const MDOUBLE epsilonHkyParamOptimization,
					   const MDOUBLE epsilonLikelihoodImprovment,
					   const int maxBBLIterations,
					   const int maxTotalIterations){
	cerr<<"find Best HkyParam and best BBL"<<endl;
//	cerr<<" 1. bestHkyParam::findBestHkyParam"<<endl;
//	brLenOpt br1(*et,*pi,weights);
	MDOUBLE oldL = VERYSMALL;
	MDOUBLE newL = VERYSMALL;
	const MDOUBLE bx=upperBoundOnHkyParam*0.3;
	const MDOUBLE ax=0;
	const MDOUBLE cx=upperBoundOnHkyParam;
//
	MDOUBLE bestA=0;
	for (int i=0; i < maxTotalIterations; ++i) {
		newL = -brent(ax,bx,cx,
		C_evalHkyParam(et,sc,sp,weights),
		epsilonHkyParamOptimization,
		&bestA);

		if (newL > oldL+epsilonLikelihoodImprovment) {
			oldL = newL;
		} else {
			_bestL = oldL;
			_bestHkyParam= bestA;
			break;
		}

		(static_cast<hky*>(sp.getPijAccelerator()->getReplacementModel()))->changeTrTv(bestA);
		newL =brLenOptEM::optimizeBranchLength1G_EM(et,sc,sp,NULL,maxBBLIterations,epsilonLikelihoodImprovment);//maxIterations=1000

		if (newL > oldL+epsilonLikelihoodImprovment) {
			oldL = newL;
		}
		else {
			_bestL = oldL;
			_bestHkyParam= bestA;
			break;
		}
	}
}
		
bestHkyParamFixedTree::bestHkyParamFixedTree(const tree& et, //findBestHkyParamFixedTree
					   const sequenceContainer1G& sc,
					   stochasticProcess& sp,
					   const Vdouble * weights,
					   const MDOUBLE upperBoundOnHkyParam,
					   const MDOUBLE epsilonHkyParamOptimization){
	cerr<<"findBestHkyParamFixedTree"<<endl;
	MDOUBLE bestA=0;
	const MDOUBLE cx=upperBoundOnHkyParam;// left, midle, right limit on HkyParam
	const MDOUBLE bx=cx*0.3;
	const MDOUBLE ax=0;

	
	_bestL = -brent(ax,bx,cx,
		C_evalHkyParam(et,sc,sp,weights),
		epsilonHkyParamOptimization,
		&bestA);
	_bestHkyParam= bestA;
}

