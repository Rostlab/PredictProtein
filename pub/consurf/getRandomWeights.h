#ifndef __GET_RANDOM_WEIGHTS
#define __GET_RANDOM_WEIGHTS

#include "definitions.h"


class getRandomWeights {
public:
	static void randomWeights(Vdouble& weights,
				  const MDOUBLE tmp);

	static void randomWeightsGamma(Vdouble& weights,
				       const MDOUBLE tmp);

	static void standardBPWeights(Vdouble& weights);
};

#endif 

