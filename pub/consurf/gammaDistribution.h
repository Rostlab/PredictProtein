// version 1.00
// last modified 3 Nov 2002

#ifndef ___GAMMA_DIST
#define ___GAMMA_DIST

#include "distribution.h"
class gammaDistribution : public distribution {

public:
	explicit gammaDistribution(MDOUBLE alpha=1,int in_number_of_categories=1);
	explicit gammaDistribution(const gammaDistribution& other);
	virtual ~gammaDistribution() {};
	const int categories() const {return _rates.size();}
	virtual const MDOUBLE rates(const int i) const {return _rates[i]*_globalRate;}
	virtual const MDOUBLE ratesProb(const int i) const {return _ratesProb[i];}
	virtual distribution* clone() const { return new gammaDistribution(*this); }
 	virtual void setGlobalRate(const MDOUBLE x) {_globalRate = x;}
 	virtual MDOUBLE getGlobalRate()const {return _globalRate;}
	virtual const MDOUBLE getCumulativeProb(const MDOUBLE x) const;
	void setAlpha(MDOUBLE newAlpha);
	MDOUBLE getAlpha() {return alpha;};
	void change_number_of_categories(int in_number_of_categories);
	void setGammaParameters(int numOfCategories=1 ,MDOUBLE alpha=1);
	MDOUBLE getBorder(const int i) const {return _bonderi[i];}	//return the ith border. Note:  _bonderi[0] = 0, _bondery[categories()] = infinite


private:	
	int feel_mean();
	int feel_bonderi();

	MDOUBLE alpha;
	vector<MDOUBLE> _bonderi;
	vector<MDOUBLE> _rates;
	vector<MDOUBLE> _ratesProb;
	MDOUBLE _globalRate;


};



#endif

