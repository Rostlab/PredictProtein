#include "likeDist.h"
#include "numRec.h"
#include "sequence.h"

class C_evalLikeDistDirect{
private:
	const stochasticProcess& _sp;
	const sequence& _s1;
	const sequence& _s2;
	const vector<MDOUBLE>  * _weights;
public:
	C_evalLikeDistDirect(const stochasticProcess& inS1,
		const sequence& s1,
		const sequence& s2,
		const vector<MDOUBLE>  * weights): _sp(inS1),_s1(s1),_s2(s2),_weights(weights) {};

	MDOUBLE operator() (MDOUBLE dist) {
		MDOUBLE sumL=0.0;
		MDOUBLE sumR = 0.0;
		for (int pos=0; pos < _s1.seqLen(); ++pos){
			if ((_s1[pos] == -2) && (_s2[pos] == -2)) {
				continue; // the case of two unknowns
			}
			sumR = 0;
			for (int rateCategor = 0; rateCategor<_sp.categories(); ++rateCategor) {
				MDOUBLE rate = _sp.rates(rateCategor);
				MDOUBLE pij= 0;
				if ((_s1[pos] >= 0) && (_s1[pos] < _sp.alphabetSize())
					&& (_s2[pos] >= 0) && (_s2[pos] < _sp.alphabetSize())) {
						// this is the simple case, where AA i is changing to AA j.
					pij= _sp.Pij_t(_s1[pos],_s2[pos],dist*rate);
					if (pij==0) {
						pij = 0.000000001;
					}
					sumR += pij * _sp.freq(_s1[pos])*_sp.ratesProb(rateCategor);
				}
				else if (
					((_s1[pos] == -2) && (_s2[pos] <_sp.alphabetSize())) ||
					((_s2[pos] == -2) && (_s1[pos] <_sp.alphabetSize()))
					)
					{ // this is the more complicated case, where one or both of the letters is ?
					   // but the other is not a combination like B for AA.
					sumR += ((_s1[pos] != -2)?_sp.freq(_s1[pos]):_sp.freq(_s2[pos]))*_sp.ratesProb(rateCategor);
				}
				else {// this is the most complicated case, when you have combinations of letters,
					  // for example B in one sequence and ? in the other.
					for (int iS1 =0; iS1< _sp.alphabetSize(); ++iS1) {
						for (int iS2 =0; iS2< _sp.alphabetSize(); ++iS2) {
							if ((_s1.getAlphabet()->relations(_s1[pos],iS1)) &&
								(_s2.getAlphabet()->relations(_s2[pos],iS2))) {
								sumR += _sp.freq(iS1)*_sp.Pij_t(iS1,iS2,dist*rate)*_sp.ratesProb(rateCategor);
							}
						}
					}
				}
			}
			assert(sumR!=0);
			sumL += log(sumR)*(_weights ? (*_weights)[pos]:1);
		}
		return -sumL;
	};
};

class C_evalLikeDistDirect_d{ // derivative.
private:
	const stochasticProcess& _sp;
	const sequence& _s1;
	const sequence& _s2;
	const vector<MDOUBLE>  * _weights;
public:
	C_evalLikeDistDirect_d(const stochasticProcess& inS1,
		const sequence& s1,
		const sequence& s2,
		const vector<MDOUBLE>  * weights): _sp(inS1),_s1(s1),_s2(s2),_weights(weights) {};

	MDOUBLE operator() (MDOUBLE dist) {
		MDOUBLE sumL=0.0;
		MDOUBLE sumR = 0.0;
		MDOUBLE sumR_d = 0.0;
		for (int pos=0; pos < _s1.seqLen(); ++pos){
			if ((_s1[pos] == -2) && (_s2[pos] == -2)) {	continue;} // two unknowns
			sumR = 0;
			sumR_d = 0;
			for (int rateCategor = 0; rateCategor<_sp.categories(); ++rateCategor) {
				MDOUBLE rate = _sp.rates(rateCategor);
				MDOUBLE pij= 0;
				MDOUBLE dpij=0;
				if ((_s1[pos] >= 0) && (_s1[pos] < _sp.alphabetSize())
				&& (_s2[pos] >= 0) && (_s2[pos] < _sp.alphabetSize())) {
					// normal case, no ? , B, Z and such.
					pij= _sp.Pij_t(_s1[pos],_s2[pos],dist*rate);
					dpij= _sp.dPij_dt(_s1[pos],_s2[pos],dist*rate)*rate;
					if (pij==0) {
						pij = 0.000000001;
					}
					MDOUBLE exp =  _sp.freq(_s1[pos])*_sp.ratesProb(rateCategor);
					sumR += pij *exp;
					sumR_d += dpij*exp;
				} else if (
					((_s1[pos] == -2) && (_s2[pos] <_sp.alphabetSize())) ||
					((_s2[pos] == -2) && (_s1[pos] <_sp.alphabetSize()))
					)
				{ // this is the more complicated case, where one or both of the letters is ?
				   // but the other is not a combination like B for AA.
					sumR = 1; // unknown pair with one.
					sumR_d =0; // actually, this is the important part, because after dividing we get 0...
				}
				else {// this is the most complicated case, when you have combinations of letters,
				  // for example B in one sequence and ? in the other.
					for (int iS1 =0; iS1< _sp.alphabetSize(); ++iS1) {
						for (int iS2 =0; iS2< _sp.alphabetSize(); ++iS2) {
							if ((_s1.getAlphabet()->relations(_s1[pos],iS1)) &&
								(_s2.getAlphabet()->relations(_s2[pos],iS2))) {
									MDOUBLE exp = _sp.freq(iS1)*_sp.ratesProb(rateCategor);
								sumR += exp* _sp.Pij_t(iS1,iS2,dist*rate);
								sumR_d += exp * _sp.dPij_dt(iS1,iS2,dist*rate)*rate;
							}
						}
					}
				}
			}// end of for rate categories
			assert(sumR!=0);
			sumL += (sumR_d/sumR)*(_weights ? (*_weights)[pos]:1);;
		}
		return -sumL;
	};
};

const MDOUBLE likeDist::giveDistance(const sequence& s1, const sequence& s2,
									 const MDOUBLE dis2evaluate) {
	C_evalLikeDistDirect Cev(_s1,s1,s2,NULL);
	return -Cev.operator ()(dis2evaluate);
}



const MDOUBLE likeDist::giveDistance2(const sequence& s1,
								const sequence& s2,
								const vector<MDOUBLE>  * weights,
								MDOUBLE* score) const {

	const MDOUBLE MAXDISTANCE=_maxPairwiseDistance;
//	const MDOUBLE PRECISION_TOLL=0.001;
	const MDOUBLE ax=0,bx=1.0,cx=MAXDISTANCE,tol=_toll;
	MDOUBLE dist=-1.0;
	MDOUBLE resL = -dbrent(ax,bx,cx,
		  C_evalLikeDistDirect(_s1,s1,s2,weights),
		  C_evalLikeDistDirect_d(_s1,s1,s2,weights),
		  tol,
		  &dist);
	if (score) *score = resL;
	return dist;
}
