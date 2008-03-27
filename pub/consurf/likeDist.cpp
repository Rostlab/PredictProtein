// version 1.00
// last modified 2 Nov 2002

#include "likeDist.h"
#include "numRec.h"

const MDOUBLE likeDist::giveDistance(	const countTableComponentGam& ctc,
										   MDOUBLE& resL,
										   const MDOUBLE initialGuess) const {
	//return giveDistanceNR(ctc,resL,initialGuess);
	return giveDistanceBrent(ctc,resL,initialGuess);
}

const MDOUBLE likeDist::giveDistanceBrent(	const countTableComponentGam& ctc,
										   MDOUBLE& resL,
										   const MDOUBLE initialGuess) const {
	const MDOUBLE ax=0,bx=initialGuess,cx=_maxPairwiseDistance,tol=_toll;
	MDOUBLE dist=-1.0;
	resL = -dbrent(ax,bx,cx,
		  C_evalLikeDist(ctc,_s1),
		  C_evalLikeDist_d(ctc,_s1),
		  tol,
		  &dist);
	return dist;
}

template <typename regF, typename dF>
MDOUBLE myNRmethod(MDOUBLE low, MDOUBLE current, MDOUBLE high, regF f,
	dF df, const MDOUBLE tol, const int max_it, int & zeroFound) { // finding zero of a function.
	zeroFound = 1;
	MDOUBLE currentF = f(current);
	if (fabs(currentF)<tol) return current;
	MDOUBLE lowF = f(low);
	MDOUBLE highF = f(high);
	if (((lowF>0) && (highF>0)) || ((lowF<0) && (highF<0))) {// unable to find a zero
		zeroFound = 0;
		return 0;
	}
	if (lowF>0) {// fixing things to be in the right order.
		MDOUBLE tmp = low;
		low = high;
		high = tmp;
		tmp = lowF;
		lowF = highF;
		highF = tmp;
	}
	if (currentF>0) {
		high = current;
		highF = currentF;
	} else {
		low = current;
		lowF = currentF;
	} // now the zero is between current and either low or high.

	MDOUBLE currentIntervalSize = fabs(low-high);
	MDOUBLE oldIntervalSize = currentIntervalSize;

	// we have to decide if we do NR or devide the interval by two:
	// we want to check if the next NR step is within our interval
	// recall the the next NR guess is Xn+1 = Xn - f(Xn) / f(Xn+1)
	// So we want (current - currentF/currentDF) to be between low and high
	for (int i=0 ; i < max_it; ++i) {
		MDOUBLE currentDF = df(current);
		MDOUBLE newGuess = current - currentF/currentDF;
		if ((newGuess<low && newGuess> high) || (newGuess>low && newGuess< high)) {
			// in this case we should do a NR step.
			current = newGuess;
			currentF = f(current);
			if (currentF > 0){
				high = current;
				highF = currentF;
			} else {
				low = current;
				lowF = currentF;
			}

			oldIntervalSize = currentIntervalSize;
			currentIntervalSize =fabs (high-low);
			if (currentIntervalSize < tol) {
				return current;
			}
			//cerr<<"NR: low= "<<low<<" high= "<<high<<endl;
		}
		else { // bisection
			oldIntervalSize = currentIntervalSize;
			currentIntervalSize /= 2.0;
			current = (low+high)/2.0;
			currentF = f(current);
			if (currentF > 0){
				high = current;
				highF = currentF;
			} else {
				low = current;
				lowF = currentF;
			}
			//cerr<<"BIS: low= "<<low<<" high= "<<high<<endl;
			if (currentIntervalSize < tol) {
				return current;
			}

		}
	}
	errorMsg::reportError("to many iterations in myNR function");
	return 0;
}

const MDOUBLE likeDist::giveDistanceNR(	const countTableComponentGam& ctc,
										   MDOUBLE& resL,
										   const MDOUBLE initialGuess) const {
	//change bx so that it will be the current branch length!
	const MDOUBLE ax=0,bx=initialGuess,cx=_maxPairwiseDistance,tol=_toll;
//	cerr<<"===================================================\n";
	MDOUBLE dist=-1.0;
	int zeroFound = 0;
	dist = myNRmethod(ax,bx,cx,
		  C_evalLikeDist_d(ctc,_s1),
		  C_evalLikeDist_d2(ctc,_s1),
		  tol,
		  100,
		  zeroFound);// max it for NR;
	if (zeroFound == 0) {// there was an error finding a zero
		dist = bx;
	}

	return dist;
}











/*




const MDOUBLE likeDist::giveDistance( // the NR version.
						const countTableComponentGam& ctc,
						MDOUBLE& resL) const {
	cerr<<"=============="<<endl;
	MDOUBLE oldGuess=0.05; // move to parameters.
	if (oldGuess<0) oldGuess=0.05; // move up.
	int max_it = 100;
	MDOUBLE oldDist =0;
	MDOUBLE currentDist =oldGuess;
	MDOUBLE newDer =VERYBIG;
	MDOUBLE oldDer =VERYBIG;
	//const MDOUBLE ax=0,bx=1.0,cx=_maxPairwiseDistance,tol=_toll;
	for (int i=0; i < max_it; ++i){
		MDOUBLE	sumDL=0.0;
		MDOUBLE	sumDL2=0.0;
		for (int alph1=0; alph1 <  ctc.alphabetSize(); ++alph1){
			for (int alph2=0; alph2 <  ctc.alphabetSize(); ++alph2){
				for (int rateCategor = 0; rateCategor<_s1.categories(); ++rateCategor) {
					MDOUBLE rate = _s1.rates(rateCategor);

					MDOUBLE pij= _s1.Pij_t(alph1,alph2,currentDist*rate);
					MDOUBLE dpij = _s1.dPij_dt(alph1,alph2,currentDist*rate);
					MDOUBLE dpij2 = _s1.d2Pij_dt2(alph1,alph2,currentDist*rate);
					if (pij==0) {
						pij = 0.000000001;
						dpij = 0.000000001;
					}
					sumDL+= ctc.getCounts(alph1,alph2,rateCategor)*dpij 
									*rate/pij;
					sumDL2+= ctc.getCounts(alph1,alph2,rateCategor)*rate*(pij*dpij2-dpij *dpij)
									/(pij*pij);
				}
			}
		}
		oldDer = newDer;
		newDer = sumDL;
		cerr<<"\ndistance = "<<currentDist<<endl;
		cerr<<"derivation = "<<sumDL<<endl;
		cerr<<"sec derivation = "<<sumDL2<<endl;
		oldDist = currentDist;
		if ((fabs(newDer) < fabs(oldDer)) && (sumDL2 < 0)) {
			currentDist = currentDist - newDer/sumDL2;
		}
		else {
			currentDist = currentDist / 2;
		}
		MDOUBLE epsilonForDeriv = 0.001;// move up
		if (fabs(newDer) < epsilonForDeriv) break;
		
	}

	return currentDist;
}*/
