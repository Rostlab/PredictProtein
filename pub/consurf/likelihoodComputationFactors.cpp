#include "computeUpAlg.h"
#include "likelihoodComputationFactors.h"
#include <cmath>
#include <cassert>

using namespace treeInterface;
using namespace likelihoodComputation;

MDOUBLE likelihoodComputation::getLOG_LofPos(const int pos,
					  const tree& et,
					  const sequenceContainer& sc,
					  const stochasticProcess& sp,
					  const MDOUBLE gRate){ // when there is a global rate for this position
// using the pij of stochastic process rather than pre computed pij's...
	vector<MDOUBLE> factors;
	computeUpAlg cup;
	suffStatGlobalHomPos ssc;
	cup.fillComputeUpSpecificGlobalRateFactors(et,sc,pos,sp,ssc,gRate,factors);

	MDOUBLE tmp = 0.0;
	for (int let = 0; let < sp.alphabetSize(); ++let) {
		MDOUBLE tmpLcat=
				ssc.get(et.iRoot()->id(),let)*
				sp.freq(let);;
		assert(tmpLcat>=0);
		tmp+=tmpLcat;
	}
	return log(tmp)-factors[et.iRoot()->id()]*log(10.0);
}

