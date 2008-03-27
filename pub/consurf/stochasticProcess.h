#ifndef ___STOCHASTIC_PROCESS
#define ___STOCHASTIC_PROCESS

#include "pijAccelerator.h"
#include "distribution.h"
#include <cassert>

class stochasticProcess{
public:
	explicit stochasticProcess(const distribution *in_distr,const pijAccelerator *inPijAccelerator);
	explicit stochasticProcess() {
		_distr=NULL; _pijAccelerator=NULL;
	}
	const int alphabetSize() const {return _pijAccelerator->alphabetSize();}

	stochasticProcess(const stochasticProcess& other); // explicit removed because of unix compilation problems.
	const int categories() const {return _distr->categories();}
	const MDOUBLE rates(const int i) const {return _distr->rates(i);}
	const MDOUBLE ratesProb(const int i) const {return _distr->ratesProb(i);}

	
	const MDOUBLE Pij_t(const int i, const int j, const MDOUBLE t) const {return _pijAccelerator->Pij_t(i,j,t);}

	const MDOUBLE freq(const int i) const {assert(i>=0);return _pijAccelerator->freq(i);}
	const MDOUBLE dPij_dt(const int i,const  int j,const MDOUBLE t) const {	return _pijAccelerator->dPij_dt(i,j,t);}
	const MDOUBLE d2Pij_dt2(const int i, const int j, const MDOUBLE t) const { return _pijAccelerator->d2Pij_dt2(i,j,t);}


	virtual distribution* distr() const {return _distr;}
	virtual pijAccelerator* getPijAccelerator() const {return _pijAccelerator;}

	stochasticProcess& operator=(const stochasticProcess &otherTree);
	virtual ~stochasticProcess();
 	void setGlobalRate(const MDOUBLE x) {_distr->setGlobalRate(x);}
 	MDOUBLE getGlobalRate() const {return _distr->getGlobalRate();}

private:
	distribution *_distr;
	pijAccelerator *_pijAccelerator;
};



#endif


