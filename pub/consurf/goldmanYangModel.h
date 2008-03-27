#ifndef ___GOLDMAN_YANG_MODEL
#define ___GOLDMAN_YANG_MODEL

#include "replacementModel.h"
#include "fromQtoPt.h"
#include "granthamChemicalDistances.h"

class goldmanYangModel : public replacementModel {
public:
	const int alphabetSize() const {return 61;}
	virtual replacementModel* clone() const { return new goldmanYangModel(*this); }
	explicit goldmanYangModel(const MDOUBLE inV, const MDOUBLE inK){_v=inV;_k=inK;homogenousFreq();updateQ();};
	explicit goldmanYangModel(const MDOUBLE inV, const MDOUBLE inK, const Vdouble& freq) {_v=inV;_k=inK;_freq=freq;updateQ();};
	const MDOUBLE Pij_t(const int i,const int j, const MDOUBLE d) const {
		return _q2pt.Pij_t(i,j,d);
	}
	const MDOUBLE dPij_dt(const int i,const int j, const MDOUBLE d) const{
		return _q2pt.dPij_dt(i,j,d);
	}
	const MDOUBLE d2Pij_dt2(const int i,const int j, const MDOUBLE d) const{
		return _q2pt.d2Pij_dt2(i,j,d);
	}
	const MDOUBLE freq(const int i) const {return _freq[i];};
	void setK(const MDOUBLE newK) { _k = newK;updateQ();}
	void setV(const MDOUBLE newV) { _v = newV;updateQ();}
	void homogenousFreq(){ _freq.erase(_freq.begin(),_freq.end()),_freq.resize(61,1.0/61);}

	MDOUBLE getK() {return _k;}
	MDOUBLE getV() {return _v;}

private:
	Vdouble _freq;
	MDOUBLE _v; //selection factor.
	MDOUBLE _k; // Tr/Tv ratio.
	void updateQ();
	q2pt _q2pt;
	granthamChemicalDistances _gcd;
};


#endif
