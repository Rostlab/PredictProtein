#include "fastStartTree.h"
#include "brLenOptEM.h"
#include "likeDist.h"
#include "likelihoodComputation.h"
#include "getRandomWeights.h"
#include "distanceTable.h"
#include "nj.h"

#include <algorithm>

using namespace std;
using namespace brLenOptEM;
using namespace likelihoodComputation;


vector<tree> eliminateHalf(vector<tree>& tVec,
						   sequenceContainer1G& orginal,
						   stochasticProcess& sp,
						   ostream& out,
						   const int maxIterEM){
	vector<MDOUBLE> likeScore(tVec.size(),0.0);
	int i;
	for (i=0; i < tVec.size(); ++i) {
		likeScore[i] = brLenOptEM::optimizeBranchLength1G_EM(
											tVec[i],orginal,sp,NULL,maxIterEM,0.01);
		cerr<<"~";
	}

	vector<MDOUBLE> sortedL = likeScore;
	sort(sortedL.begin(),sortedL.end());
	MDOUBLE median = sortedL[sortedL.size()/2];

	// printing the top ten with their scores;
//	int toPrint = sortedL.size()>10? 10 : sortedL.size();
//	MDOUBLE treshToPrint = sortedL[sortedL.size()-toPrint];
//	out<<"current best 10 (or less) trees: "<<endl;
//	for (int h=0; h < likeScore.size(); ++h) {
//		if (likeScore[h]>treshToPrint) {
//			out<<"likelihood of tree: "<<h<<" = "<<likeScore[h]<<endl;
//			tVec[h].output(out);
//		}
//	}

	for (int p=0; p < sortedL.size(); ++p ){
		out<<"L["<<p<<"]= "<<sortedL[p]<<endl;
	}
	out<<endl;

	vector<tree> newTreeVec;
	for (i=0;i < tVec.size(); ++i) {
		if (likeScore[i]>=median) newTreeVec.push_back(tVec[i]); // ok this is a heck to mark trees
	}
	if (newTreeVec.size() == 0 ) newTreeVec.push_back(tVec[0]); // in case for example that all have the same L
	return newTreeVec;
}



		





		
//------------------ get N starting different NJ trees --------------------

tree getBestMLTreeFromManyNJtrees(sequenceContainer1G & allTogether,
								stochasticProcess& sp,
								const int numOfNJtrees,
								const MDOUBLE tmpForStartingTreeSearch,
								const MDOUBLE epslionWeights,
								ostream& out) {


	likeDist pd1(allTogether.alphabetSize(),sp,0.01);
	vector<tree> tVec;
	int treeTries = 0;
	while (tVec.size() < numOfNJtrees) {
		++treeTries;
		if (treeTries == 5000) break;

		Vdouble startingTreeWeights(allTogether.seqLen(),1.0);
		if (treeTries>1) {// the first is the regular NJ tree
 			getRandomWeights::randomWeightsGamma(startingTreeWeights,
									tmpForStartingTreeSearch);
		}
		for (int p=0; p < startingTreeWeights.size(); ++p){
			if (startingTreeWeights[p]<epslionWeights) startingTreeWeights[p]=0.0;
		}
		#ifdef VERBOS
		if (treeTries ==2){ cerr<<" weights for the 25 positions"<<endl;
			for (int h=0; h < 25; ++h) cerr<<startingTreeWeights[h]<<" ";
		}
		#endif
		VVdouble disTab;
		vector<string> vNames;
		giveDistanceTable(&pd1,
						   allTogether,
						   disTab,
						   vNames,
						   &startingTreeWeights);
		NJalg nj1;
		tree et = nj1.computeNJtree(disTab,vNames);

		bool treeAlreadyThere = false;
		for (int z=0; z< tVec.size();++z) {
			if (sameTreeTolopogy(tVec[z],et)) treeAlreadyThere=true;
		}
		if (treeAlreadyThere == false) {
			tVec.push_back(et);
		}
	}
	cerr<<"from number of tree tried: "<<treeTries<<" got: "<<numOfNJtrees<<" trees"<<endl;
	out<<"from number of tree tried: "<<treeTries<<" got: "<<numOfNJtrees<<" trees"<<endl;

	int numOfTreesToPrint = tVec.size()<10?tVec.size():10;
	out<<"starting with: "<<tVec.size()<<" trees! "<<endl;
	for (int g=0; g < numOfTreesToPrint; ++g) tVec[g].output(out);

//------------------ chossing the ML tree from these NJ trees --------------------
	int maxIterEM=0;
	while (tVec.size() > 1) {
		cerr<<" current size = "<<tVec.size()<<endl;
		tVec = eliminateHalf(tVec,allTogether,sp,out,maxIterEM);
		maxIterEM=1; // first round without bbl at all.
	}
	cerr<<" final size = "<<tVec.size()<<endl;

	MDOUBLE res = brLenOptEM::optimizeBranchLength1G_EM(
											tVec[0],allTogether,sp,NULL,100,0.01);

	tVec[0].output(cerr);
	cerr<<"likelihood = "<<res<<endl;
	tVec[0].output(out);
	out<<"likelihood = "<<res<<endl;
	return tVec[0];
}
