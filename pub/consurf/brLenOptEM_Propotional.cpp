#include "brLenOptEM.h"
#include "computeUpAlg.h"
#include "computeDownAlg.h"
#include "computePijComponent.h"
#include "logFile.h"
#include "likelihoodComputation.h"

#include "countTableComponent.h"
#include "computeCounts.h"
#include "fromCountTableComponentToDistanceProp.h"

#include <cmath>
using namespace treeInterface;
using namespace likelihoodComputation;

#define VERBOS


  void revaluateBranchLengthProp(
						vector<computePijGam>& pij0,
						const vector<sequenceContainer1G>& sc,
						const vector<stochasticProcess>& sp,
						const vector<Vdouble *> * weights,
						tree &et,
						const vector<suffStatGlobalGam>& cup,
						const vector<suffStatGlobalGam>& cdown,
						const vector<Vdouble>& posProbVec,
						MDOUBLE tollForPairwiseDist = 0.0001){
	vector< vector<countTableComponentGam> > vec; // for each node, for each gene
	const int numOfGenes = sc.size();
	vec.resize(et.iNodes());

	for (int k=0; k < vec.size(); ++k) {
		vec[k].resize(numOfGenes);
	}

	treeIterDownTopConst tIt(et);
	computeCounts cc;
	for (tree::nodeP mynode = tIt.first(); mynode != tIt.end(); mynode = tIt.next()) {
		for (int gene=0; gene < numOfGenes; ++gene) {
			cc.fillCountTableComponentGam(vec[mynode->id()][gene],sp[gene],sc[gene],
										pij0[gene],cup[gene],cdown[gene],
										(weights?(*weights)[gene]:NULL),
										mynode,posProbVec[gene]);
		}
		fromCountTableComponentToDistanceProp from1(vec[mynode->id()],sp,tollForPairwiseDist,mynode->dis2father());
		from1.computeDistance();
		mynode->setDisToFather(from1.getDistance());
	}
}

MDOUBLE brLenOptEM::optimizeBranchLengthNG_EM_PROP(
									tree& et,
									const vector<sequenceContainer1G>& sc,
									const vector<stochasticProcess>& sp,
									const vector<Vdouble *> * weights,
									const int maxIterations,
									const MDOUBLE epsilon,
									MDOUBLE tollForPairwiseDist){
	const int numberOfGenes = sc.size();
	MDOUBLE newL=VERYSMALL;
	int it;
	vector<Vdouble> posProb(numberOfGenes);
	vector<suffStatGlobalGam> cup(numberOfGenes);
	vector<suffStatGlobalGam> cdown(numberOfGenes);
	int i;
	for (i=0; i < cup.size(); ++i) {
		cup[i].allocatePlace(sc[i].seqLen(),sp[i].categories(),et.iNodes(),sc[i].alphabetSize());
		cdown[i].allocatePlace(sc[i].seqLen(),sp[i].categories(),et.iNodes(),sc[i].alphabetSize());
	}

	vector<computePijGam> pij0(numberOfGenes);
	for (i=0; i < pij0.size(); ++i) {
		pij0[i].fillPij(et,sp[i],sc[i].alphabetSize(),0);
	}

	computeUpAlg cupAlg;
	computeDownAlg cdownAlg;
	int pos = 0;
	int categor = 0;

	for (i=0; i < cup.size(); ++i) {
		for (pos = 0; pos < sc[i].seqLen(); ++pos) {
			for (categor = 0; categor < sp[i].categories(); ++categor) {
				cupAlg.fillComputeUp(et,sc[i],pos,pij0[i][categor],cup[i][pos][categor]);
				cdownAlg.fillComputeDown(et,sc[i],pos,pij0[i][categor],cdown[i][pos][categor],cup[i][pos][categor]);
			}
		}
	}

	MDOUBLE oldL = 0;
	for (i=0; i < cup.size(); ++i) {
		oldL += likelihoodComputation::getTreeLikelihoodFromUp2(et,sc[i],sp[i],cup[i],posProb[i],(weights?(*weights)[i]:NULL));
	}

	LOG(50,<<"(bbl) startingL= "<<oldL<<endl);
	#ifdef VERBOS
	cerr<<"(bbl) startingL= "<<oldL<<endl;
	#endif
	for (it = 0; it < maxIterations; ++it) {
		tree oldT = et;
		revaluateBranchLengthProp(pij0,sc,sp,weights,et,cup,cdown,posProb,tollForPairwiseDist);

		for (i=0; i < pij0.size(); ++i) {
			pij0[i].fillPij(et,sp[i],sc[i].alphabetSize(),0);
		}

		for (i=0; i < cup.size(); ++i) {
			for (pos = 0; pos < sc[i].seqLen(); ++pos) {
				for (categor = 0; categor < sp[i].categories(); ++categor) {
					cupAlg.fillComputeUp(et,sc[i],pos,pij0[i][categor],cup[i][pos][categor]);
					cdownAlg.fillComputeDown(et,sc[i],pos,pij0[i][categor],cdown[i][pos][categor],cup[i][pos][categor]);
				}
			}
		}

		newL =0;
		for (i=0; i < cup.size(); ++i) {
			newL += likelihoodComputation::getTreeLikelihoodFromUp2(et,sc[i],sp[i],cup[i],posProb[i],(weights?(*weights)[i]:NULL));
		}
		#ifdef VERBOS
		cerr<<"(bbl) newL= "<<newL<<endl;
		cerr<<"(bbl) oldL= "<<oldL<<endl;
		#endif	

		if ((newL < oldL + epsilon)  || (maxIterations == it)){
			if (newL < oldL) {
				et = oldT;
				return oldL;
			}
			else {
				return newL;
			}
		} 
		oldL = newL;
		LOG(50,<<"(bbl)y it= "<<it<<" newL = "<<newL<<endl);
		#ifdef VERBOS
		cerr<<"(bbl)y it= "<<it<<" newL = "<<newL<<endl;
		#endif
	}
	return newL;

}
