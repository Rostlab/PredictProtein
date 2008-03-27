#include "getRandomWeights.h"
#include "talRandom.h"



void swapRand(Vdouble& weights) {
	int j;
    int i = talRandom::giveIntRandomNumberBetweenZeroAndEntry(weights.size());
	do {
        j = talRandom::giveIntRandomNumberBetweenZeroAndEntry(weights.size());
	} while ( weights[j] <= 0 );

	weights[i]++;
    weights[j]--;
}

void getRandomWeights::randomWeights(Vdouble& weights,
								const MDOUBLE tmp) {
	int i;
	const double DefaultWeight = 1;
	for (i=0; i< weights.size(); ++i) weights[i] = DefaultWeight;

	for ( i = 0 ; i < tmp*weights.size() ; ++i ) {  // noise is not "precentege 
        swapRand(weights);							//of sites swaped" (matan)
	}
}

void getRandomWeights::standardBPWeights(Vdouble& weights) {
	int i;
	for (i=0; i< weights.size(); ++i) weights[i] = 0.0;
	for (i=0; i< weights.size(); ++i) {
	    int K = talRandom::giveIntRandomNumberBetweenZeroAndEntry(weights.size());
		weights[K]++;
	}
}

#define MIN_WEIGHT (0.00001)
void getRandomWeights::randomWeightsGamma(Vdouble& weights,
					  const MDOUBLE tmp) {
	int i;
	const double oneOverT = 1.0/tmp;
//	LOG(5,<<"1/T="<<oneOverT<<" ");
	for (i=0; i< weights.size(); ++i) {
		weights[i] = talRandom::SampleGamma(oneOverT,oneOverT);
		if (weights[i]<MIN_WEIGHT) {
			weights[i] = MIN_WEIGHT;
		}
	  //	  LOG(5,<<weights[i]<<" ");
	}
	LOG(40,<<"\n========================================="<<endl);
	LOG(40,<<"\temprature is"<<tmp<<endl);
	for (int p=0; p < weights.size();++p) {
		LOG(100,<<"weight["<<p<<"]="<<weights[p]<<endl);
	}
}

