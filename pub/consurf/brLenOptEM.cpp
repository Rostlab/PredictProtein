#include "brLenOptEM.h"
//#include "printCoOccor.h"
#include "computeUpAlg.h"
#include "computeDownAlg.h"
#include "computePijComponent.h"
#include "logFile.h"
#include "likelihoodComputation.h"

#include "countTableComponent.h"
#include "computeCounts.h"
#include "fromCountTableComponentToDistance.h"

#include <cmath>
using namespace treeInterface;
using namespace likelihoodComputation;


//#define VERBOS



/*
void fillCountTableComponentGam(countTableComponentGam& ctcGam,
								const stochasticProcess& sp,
								const sequenceContainer1G& sc,
								computePijGam& pij0,
								const suffStatGlobalGam& cup,
								const suffStatGlobalGam& cdown,
								const Vdouble * weights,
								tree::nodeP nodeSon,
								const Vdouble& posProbVec) {
	ctcGam.countTableComponentAllocatePlace(sp.alphabetSize(),sp.categories());
	for (int rateCat =0; rateCat< sp.categories(); ++ rateCat) {
		fillCountTableComponentGamSpecRateCategor(rateCat,ctcGam[rateCat],sp,
													sc,pij0[rateCat],
													cup,cdown,weights,posProbVec,nodeSon);
	}
}*/
void revaluateBranchLength(computePijGam& pij0,
						   const sequenceContainer1G& sc,
						const stochasticProcess& sp,
						const Vdouble * weights,
						const tree& et,
						const suffStatGlobalGam& cup,
						const suffStatGlobalGam& cdown,
						const Vdouble& posProbVec,
						MDOUBLE tollForPairwiseDist){// = 0.001
	vector<countTableComponentGam> vec; // for each node.
	vec.resize(et.iNodes());
	treeIterDownTopConst tIt(et);
	computeCounts cc; // just container of functions;
	for (tree::nodeP mynode = tIt.first(); mynode != tIt.end(); mynode = tIt.next()) 
	  if (!tIt->isRoot()) {
		cc.fillCountTableComponentGam(vec[mynode->id()],sp,sc,pij0,cup,cdown,weights,mynode,posProbVec);
		fromCountTableComponentToDistance from1(vec[mynode->id()],sp,tollForPairwiseDist,mynode->dis2father());
		from1.computeDistance();
		mynode->setDisToFather(from1.getDistance());
	}
}

MDOUBLE brLenOptEM::optimizeBranchLength1G_EM(tree& et,
									const sequenceContainer1G& sc,
									const stochasticProcess& sp,
									const Vdouble * weights,
									const int maxIterations,
									const MDOUBLE epsilon,
									const MDOUBLE tollForPairwiseDist) {
  // MN - debug the segfoult down here
	LOG(150,<<"optimizeBranchLength1G_EM"<<endl);
	LOGDO(150,et.output(myLog::LogFile(),tree::ANCESTORID));
	LOG(150,<<"\n\n"<<endl);
	if (et.WithBranchLength() == false) et.createFlatLengthMatrix();
	MDOUBLE newL=VERYSMALL;
	int it;
	Vdouble posProb;
	suffStatGlobalGam cup;
	suffStatGlobalGam cdown;

	cup.allocatePlace(sc.seqLen(),sp.categories(),et.iNodes(),sc.alphabetSize());
	cdown.allocatePlace(sc.seqLen(),sp.categories(),et.iNodes(),sc.alphabetSize());

	computePijGam pij0;
//	computePijGam pij1;
//	computePijGam pij2;

	pij0.fillPij(et,sp,sc.alphabetSize(),0);
//	pij1.fillPij(et,sp,sc.alphabetSize(),1);
//	pij2.fillPij(et,sp,sc.alphabetSize(),2);

	computeUpAlg cupAlg;
	computeDownAlg cdownAlg;

	int pos = 0;
	int categor = 0;
	for (pos = 0; pos < sc.seqLen(); ++pos) {
		for (categor = 0; categor < sp.categories(); ++categor) {
			cupAlg.fillComputeUp(et,
				sc,
				pos,
				pij0[categor],
				cup[pos][categor]
				);
			cdownAlg.fillComputeDown(
				et,
				sc,
				pos,
				pij0[categor],
				cdown[pos][categor],
				cup[pos][categor]
				);
		}
	}


	MDOUBLE oldL = likelihoodComputation::getTreeLikelihoodFromUp2(et,sc,sp,cup,posProb,weights);
	if (maxIterations==0) 
	  {
	    //LOGDO(1000, printAllCC(sc,sp,weights,et,et.iRoot(),cup,cdown,myLog::LogFile()));
	    return oldL;
	  }
	LOG(50,<<"(bbl) startingL= "<<oldL<<endl);
#ifdef VERBOS
	cerr<<"(bbl) startingL= "<<oldL<<endl;
#endif
	for (it = 0; it < maxIterations; ++it) {

//		it =1; cerr<<"starting with the starting tree without it =0 !!!";

//		LOG(50,<<"(bbl)x it= "<<it<<" newL = "<<newL<<endl);
//
//		LOG(1,<<"tmp tree, bbl it:"<<it<<endl);
//		LOGDO(1,_et.output(myLog::LogFile(),tree::PHYLIP));
		
		tree oldT = et;
		revaluateBranchLength(pij0,sc,sp,weights,et,cup,cdown,posProb,tollForPairwiseDist);

		pij0.fillPij(et,sp,sc.alphabetSize(),0);
//		pij1.fillPij(et,sp,sc.alphabetSize(),1);
//		pij2.fillPij(et,sp,sc.alphabetSize(),2);

		for (int pos = 0; pos < sc.seqLen(); ++pos) {
			for (int categor = 0; categor < sp.categories(); ++categor) {
				cupAlg.fillComputeUp(et,sc,pos,pij0[categor],cup[pos][categor]);
				cdownAlg.fillComputeDown(et,sc,pos,pij0[categor],cdown[pos][categor],cup[pos][categor]);
			}
		}
		newL = likelihoodComputation::getTreeLikelihoodFromUp2(et,sc,sp,cup,posProb,weights);
#ifdef VERBOS
		cerr<<"(bbl) newL= "<<newL<<endl;
#endif

		if (((newL < oldL + epsilon) && (it>0)) || (maxIterations == it)){
			if (newL < oldL) {
				et = oldT;
				//LOGDO(1000, printAllCC(sc,sp,weights,et,et.iRoot(),cup,cdown,myLog::LogFile()));
				return oldL;
			}
			else {
				//LOGDO(1000, printAllCC(sc,sp,weights,et,et.iRoot(),cup,cdown,myLog::LogFile()));
				return newL;
			}
		} else {oldL = newL;}
		//LOG(50,<<"(bbl)y it= "<<it<<" newL = "<<newL<<endl);
#ifdef VERBOS
		cerr<<"(bbl)y it= "<<it<<" newL = "<<newL<<endl;
#endif
	}
	//LOGDO(1000, printAllCC(sc,sp,weights,et,et.iRoot(),cup,cdown,myLog::LogFile()));
	return newL;

}
