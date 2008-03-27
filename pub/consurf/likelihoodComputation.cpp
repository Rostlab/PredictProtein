#include "computeUpAlg.h"
#include "likelihoodComputation.h"
#include <cmath>
#include <cassert>

using namespace treeInterface;
using namespace likelihoodComputation;

MDOUBLE likelihoodComputation::getLofPos(const int pos,
					  const tree& et,
					  const sequenceContainer& sc,
					  const computePijHom& pi,
					  const stochasticProcess& sp){

	computeUpAlg cup;
	suffStatGlobalHomPos ssc;
	cup.fillComputeUp(et,sc,pos,pi,ssc);

	MDOUBLE tmp = 0.0;
	for (int let = 0; let < sp.alphabetSize(); ++let) {
		MDOUBLE tmpLcat=
				ssc.get(et.iRoot()->id(),let)*
				sp.freq(let);
		assert(tmpLcat>=0);
		tmp+=tmpLcat;
	}
	return tmp;
}

MDOUBLE likelihoodComputation::getLofPos(const int pos,
					  const tree& et,
					  const sequenceContainer& sc,
					  const stochasticProcess& sp){
// using the pij of stochastic process rather than pre computed pij's...
	computeUpAlg cup;
	suffStatGlobalHomPos ssc;
	cup.fillComputeUp(et,sc,pos,sp,ssc);

	MDOUBLE tmp = 0.0;
	for (int let = 0; let < sp.alphabetSize(); ++let) {
		MDOUBLE tmpLcat=
				ssc.get(et.iRoot()->id(),let)*
				sp.freq(let);;
		tmp+=tmpLcat;
	}
	return tmp;
}

MDOUBLE likelihoodComputation::getLofPos(const int pos,
					  const tree& et,
					  const sequenceContainer& sc,
					  const stochasticProcess& sp,
					  const MDOUBLE gRate){ // when there is a global rate for this position
// using the pij of stochastic process rather than pre computed pij's...
	computeUpAlg cup;
	suffStatGlobalHomPos ssc;
	cup.fillComputeUpSpecificGlobalRate(et,sc,pos,sp,ssc,gRate);

	MDOUBLE tmp = 0.0;
	for (int let = 0; let < sp.alphabetSize(); ++let) {
		MDOUBLE tmpLcat=
				ssc.get(et.iRoot()->id(),let)*
				sp.freq(let);;
		assert(tmpLcat>=0);
		tmp+=tmpLcat;
	}
	return tmp;
}


MDOUBLE likelihoodComputation::getLofPos(const int pos,
					  const tree& et,
					  const sequenceContainer& sc,
					  const computePijGam& pi,
					  const stochasticProcess& sp){
//	with the pi already computed.
	MDOUBLE tmp=0;
	for (int i=0; i < sp.categories();++i) {
		tmp += getLofPos(pos,et,sc,pi[i],sp)*sp.ratesProb(i);
	}
	return tmp;
}

MDOUBLE likelihoodComputation::getTreeLikelihoodFromUp(const tree& et,
						const sequenceContainer& sc,
						const stochasticProcess& sp,
						const suffStatGlobalGam& cup,
						const Vdouble * weights) {
	MDOUBLE like = 0;
	//computing the likelihood from up:
	for (int pos = 0; pos < sc.seqLen(); ++pos) {
		MDOUBLE tmp=0;
		for (int categor = 0; categor < sp.categories(); ++categor) {
			MDOUBLE veryTmp =0;
			for (int let =0; let < sc.getAlphabet(pos)->size(); ++let) {
				veryTmp+=cup.get(pos,categor,et.iRoot()->id(),let) * sp.freq(let);
			}
			tmp += veryTmp*sp.ratesProb(categor);
		}
		like += log(tmp) * (weights?(*weights)[pos]:1);
	}
	return like;
}

MDOUBLE likelihoodComputation::getTreeLikelihoodFromUp2(const tree& et,
						const sequenceContainer& sc,
						const stochasticProcess& sp,
						const suffStatGlobalGam& cup,
						Vdouble& posLike, // fill this vector with each position likelihood but without the weights.
						const Vdouble * weights) {
	posLike.clear();
	MDOUBLE like = 0;
	//computing the likelihood from up:
	for (int pos = 0; pos < sc.seqLen(); ++pos) {
		MDOUBLE tmp=0;
		for (int categor = 0; categor < sp.categories(); ++categor) {
			MDOUBLE veryTmp =0;
			for (int let =0; let < sc.getAlphabet(pos)->size(); ++let) {
				veryTmp+=cup.get(pos,categor,et.iRoot()->id(),let) * sp.freq(let);
			}
			tmp += veryTmp*sp.ratesProb(categor);
		}
		assert(tmp>0);
		like += log(tmp) * (weights?(*weights)[pos]:1);
		posLike.push_back(tmp);
	}
	return like;
}

// fill the posteriorLike matrix with each position posterior rate (p(r|D))
// but without the weights.
MDOUBLE likelihoodComputation::getPosteriorOfRates(const tree& et,
						const sequenceContainer& sc,
						const stochasticProcess& sp,
						const suffStatGlobalGam& cup,
						VVdouble& posteriorLike, 
						const Vdouble * weights) {
	posteriorLike.clear();
	posteriorLike.resize(sc.seqLen());
	for (int z=0; z < posteriorLike.size(); ++z) posteriorLike[z].resize(sp.categories());
	MDOUBLE like = 0;
	//computing the likelihood from up:
	for (int pos = 0; pos < sc.seqLen(); ++pos) {
		MDOUBLE posProb=0;
		for (int categor = 0; categor < sp.categories(); ++categor) {
			MDOUBLE veryTmp =0;
			for (int let =0; let < sc.getAlphabet(pos)->size(); ++let) {
				veryTmp+=cup.get(pos,categor,et.iRoot()->id(),let) * sp.freq(let);
			}
			posProb += veryTmp*sp.ratesProb(categor);
			posteriorLike[pos][categor] += veryTmp*sp.ratesProb(categor);
		}
		like += log(posProb) * (weights?(*weights)[pos]:1);
		for (int categor1 = 0; categor1 < sp.categories(); ++categor1) {
			posteriorLike[pos][categor1] /= posProb;
		}
	}

	return like;
}

MDOUBLE likelihoodComputation::getTreeLikelihoodAllPosAlphTheSame(const tree& et,
							const sequenceContainer& sc,
							const stochasticProcess& sp,
							const Vdouble * const weights){
	computePijGam pi; //GAM
	pi.fillPij(et,sp,sc.getAlphabet()->size());
	MDOUBLE res =0;
	int k;
	for (k=0; k < sc.seqLen(); ++k) {
		res += log(likelihoodComputation::getLofPos(k,//pos,
			  et,//const tree& 
			  sc,// sequenceContainer& sc,
			  pi,//const computePijGam& ,
			  sp))* (weights?(*weights)[k]:1);;//const stochasticProcess& );
	}
	return res;
}
