#ifndef ___UNIFORM_DIST
#define ___UNIFORM_DIST

#include "distribution.h"

class uniDistribution : public distribution {

public:
	uniDistribution() {_rate=1;}
	const int categories() const { return 1;}
	const MDOUBLE rates(const int i) const { return _rate;};
	const MDOUBLE ratesProb(const int i) const { return 1.0;};
	virtual distribution* clone() const { return new uniDistribution(*this); }
 	virtual void setGlobalRate(const MDOUBLE x) {_rate = x;}
 	virtual MDOUBLE getGlobalRate() const{return _rate;}
	virtual const MDOUBLE getCumulativeProb(const MDOUBLE x) const 	{if (x<1.0) return 0.0;	else return 1.0;} 

	MDOUBLE _rate;
};

#endif


