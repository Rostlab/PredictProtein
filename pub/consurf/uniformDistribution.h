#ifndef ___FLAT_DIST
#define ___FLAT_DIST


#include "distribution.h"


class uniformDistribution : public distribution 
{

public:
	explicit uniformDistribution(const int numOfCategories, MDOUBLE lowerBound, MDOUBLE upperBound);
	explicit uniformDistribution(const uniformDistribution& other);
        
	virtual ~uniformDistribution() {};

	const int categories() const {return m_rates.size();}
	virtual const MDOUBLE rates(const int i) const {return m_rates[i]*m_globalRate;}
	virtual const MDOUBLE ratesProb(const int i) const {return m_ratesProb[i];}
	virtual distribution* clone() const { return new uniformDistribution(*this); }
 	virtual void setGlobalRate(const MDOUBLE x) {m_globalRate = x;}
 	virtual MDOUBLE getGlobalRate() const {return m_globalRate;}

	virtual const MDOUBLE getCumulativeProb(const MDOUBLE x) const;

	
	MDOUBLE getBorder(const int i) const ; 	//return the ith border. Note:  _bonderi[0] = m_lowerLimit, _bondery[categories()] = m_upperLimit



	void setUniformParameters(const int numOfCategories, MDOUBLE lowerBound, MDOUBLE upperBound);



private:	
	Vdouble m_rates;
	Vdouble m_ratesProb;
	MDOUBLE m_globalRate;

	MDOUBLE m_epsilon;
	MDOUBLE m_upperBound;
	MDOUBLE m_lowerBound;
};


#endif

