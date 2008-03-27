// version 1.00
// last modified 2 Nov 2002

#ifndef ___LIKE_DIST
#define ___LIKE_DIST

#include "definitions.h"
#include "countTableComponent.h"
#include "stochasticProcess.h"
#include "distanceMethod.h"
#include <cmath>
#include <iostream> // for debugging only.
using namespace std;

class likeDist : public distanceMethod
{
private:
	const int _alphabetSize;
	const stochasticProcess& _s1;
	const MDOUBLE _toll;
	const MDOUBLE _maxPairwiseDistance;
	const MDOUBLE giveDistanceBrent(	const countTableComponentGam& ctc,
								MDOUBLE& resL,
								const MDOUBLE initialGuess= 0.03) const; // initial guess
	const MDOUBLE giveDistanceNR(	const countTableComponentGam& ctc,
								MDOUBLE& resL,
								const MDOUBLE initialGuess= 0.03) const; // initial guess

public:
	const MDOUBLE giveDistance(	const countTableComponentGam& ctc,
								MDOUBLE& resL,
								const MDOUBLE initialGuess= 0.03) const; // initial guess

	explicit likeDist(const int alphabetSize,
							const stochasticProcess& s1,
							const MDOUBLE toll,
							const MDOUBLE maxPairwiseDistance = 2.0) : _alphabetSize(alphabetSize), _s1(s1) ,_toll(toll),_maxPairwiseDistance(maxPairwiseDistance) {
	}


	const MDOUBLE giveDistance(const sequence& s1, const sequence& s2,
		const MDOUBLE dis2evaluate);

	const MDOUBLE giveDistance(	const sequence& s1,
								const sequence& s2,
								const vector<MDOUBLE>  * weights,
								MDOUBLE* score=NULL) const {
		return giveDistance2(s1,s2,weights,score);
	}

	const MDOUBLE giveDistance2(	const sequence& s1,
								const sequence& s2,
								const vector<MDOUBLE>  * weights,
								MDOUBLE* score=NULL) const;

	const MDOUBLE giveDistance1(	const sequence& s1,
								const sequence& s2,
								const vector<MDOUBLE>  * weights,
								MDOUBLE* score=NULL) const {
		// only in the case of homogenous model - work through pairwise EM like
		countTableComponentGam ctc;
		if (_s1.categories() != 1) {
			errorMsg::reportError("this function only work for homogenous model.");
		}
		ctc.countTableComponentAllocatePlace(s1.getAlphabet()->size(),1);
		for (int i=0; i<s1.seqLen(); ++i) {
			ctc.addToCounts(s1[i],s2[i],0,1);
		}
		MDOUBLE resL =0;
		return giveDistance(ctc,resL);
	}







};


class C_evalLikeDist{
private:
	const countTableComponentGam& _ctc;
	const stochasticProcess& _sp;
public:
	C_evalLikeDist(const countTableComponentGam& ctc,
					const stochasticProcess& inS1):_ctc(ctc), _sp(inS1) {};

	MDOUBLE operator() (MDOUBLE dist) {
		MDOUBLE sumL=0.0;
		for (int alph1=0; alph1 < _ctc.alphabetSize(); ++alph1){
			for (int alph2=0; alph2 <  _ctc.alphabetSize(); ++alph2){
				for (int rateCategor = 0; rateCategor<_sp.categories(); ++rateCategor) {
					MDOUBLE rate = _sp.rates(rateCategor);
					MDOUBLE pij= _sp.Pij_t(alph1,alph2,dist*rate);
					if (pij==0) {
						pij = 0.000000001;
					}
					sumL += _ctc.getCounts(alph1,alph2,rateCategor)*(log(pij)-log(_sp.freq(alph2)));//*_sp.ratesProb(rateCategor);; ! REMOVING:, CODE_RED: 
				}
			}
		}
		return -sumL;
	};
};

class C_evalLikeDist_d{ // derivative.
public:
  C_evalLikeDist_d(const countTableComponentGam& ctc,
				 const stochasticProcess& inS1)    : _ctc(ctc), _sp(inS1) {};
private:
	const  countTableComponentGam& _ctc;
	const stochasticProcess& _sp;
public:
	MDOUBLE operator() (MDOUBLE dist) {
		MDOUBLE	sumDL=0.0;
		for (int alph1=0; alph1 <  _ctc.alphabetSize(); ++alph1){
			for (int alph2=0; alph2 <  _ctc.alphabetSize(); ++alph2){
				for (int rateCategor = 0; rateCategor<_sp.categories(); ++rateCategor) {
					MDOUBLE rate = _sp.rates(rateCategor);

					MDOUBLE pij= _sp.Pij_t(alph1,alph2,dist*rate);
					MDOUBLE dpij = _sp.dPij_dt(alph1,alph2,dist*rate);
					if (pij==0) {
						pij = 0.000000001;
						dpij = 0.000000001;
					}
					sumDL+= _ctc.getCounts(alph1,alph2,rateCategor)*dpij //*_sp.ratesProb(rateCategor) : removed CODE_RED
									*rate/pij;
				}
			}
		}//cerr<<"derivation = "<<-sumDL<<endl;
		return -sumDL;
	};
};

class C_evalLikeDist_d2{ // second derivative.
public:
  C_evalLikeDist_d2(const countTableComponentGam& ctc,
				 const stochasticProcess& inS1)    : _ctc(ctc), _sp(inS1) {};
private:
	const  countTableComponentGam& _ctc;
	const stochasticProcess& _sp;
public:
	MDOUBLE operator() (MDOUBLE dist) {
		MDOUBLE	sumDL=0.0;
		for (int alph1=0; alph1 <  _ctc.alphabetSize(); ++alph1){
			for (int alph2=0; alph2 <  _ctc.alphabetSize(); ++alph2){
				for (int rateCategor = 0; rateCategor<_sp.categories(); ++rateCategor) {
					MDOUBLE rate = _sp.rates(rateCategor);

					MDOUBLE pij= _sp.Pij_t(alph1,alph2,dist*rate);
					MDOUBLE dpij = _sp.dPij_dt(alph1,alph2,dist*rate);
					MDOUBLE d2pij = _sp.d2Pij_dt2(alph1,alph2,dist*rate);
					if (pij==0) {
						pij = 0.000000001;
						dpij = 0.000000001;
					}
					sumDL+= rate*_ctc.getCounts(alph1,alph2,rateCategor)*
						(pij*d2pij - dpij *dpij )/(pij*pij);
				}
			}
		}//cerr<<"derivation = "<<-sumDL<<endl;
		return -sumDL;
	};
};

#endif

