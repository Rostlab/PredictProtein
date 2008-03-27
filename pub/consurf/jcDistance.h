#ifndef ___JC_DISTANCE
#define ___JC_DISTANCE

#include "distanceMethod.h"
#include <cmath>

class jcDistance : public distanceMethod {
private:
	const int _alphabetSize;

public:
	explicit jcDistance(const int alphabetSize) : _alphabetSize(alphabetSize) {
	}

	const MDOUBLE giveDistance(	const sequence& s1,
								const sequence& s2,
								const vector<MDOUBLE>  * weights,
								MDOUBLE* score=NULL) const {//score is not used here
//		const MDOUBLE MAXDISTANCE=2.0;
		const MDOUBLE MAXDISTANCE=15;
		
		MDOUBLE p =0;
		MDOUBLE len=0.0;
		if (weights == NULL) {
			for (int i = 0; i < s1.size() ; ++i) {
				if (s1[i]<0 || s2[i]<0) continue; //gaps and missing data.
				len+=1.0;
				if (s1[i] != s2[i]) p++;
			}
			if (len==0) p=1;
			else p = p/len;
		} else {
			for (int i = 0; i < s1.size() ; ++i) {
				if (s1[i]<0 || s2[i]<0) continue; //gaps and missing data.
				len += (*weights)[i];
				if (s1[i] != s2[i])  p+=((*weights)[i]);
			}
			if (len==0) p=1;
			else {
				p = p/len;
			}
		}
		const MDOUBLE inLog = 1 - (MDOUBLE)_alphabetSize*p/(_alphabetSize-1.0);
		if (inLog<=0) {
//			LOG(6,<<" DISTANCES FOR JC DISTANCE ARE TOO BIG");
//			LOG(6,<<" p="<<p<<endl);
			return MAXDISTANCE;
		}
		MDOUBLE dis = -1.0 * (1.0 - 1.0/_alphabetSize) * log (inLog);
		return dis;
	}
};

class jcDistanceOLD : public distanceMethod {
// in this version, if you have
// a gap in front of a letter - it will be taken as a different
// and also the length of the pairwise comparison will be increased.
// in case of a gap-gap, it won't be a difference, but the length will
// be increase.

private:
	const int _alphabetSize;

public:
	explicit jcDistanceOLD(const int alphabetSize) : _alphabetSize(alphabetSize) {
	}

	const MDOUBLE giveDistance(	const sequence& s1,
								const sequence& s2,
								const vector<MDOUBLE>  * weights,
								MDOUBLE* score=NULL) const {//score is not used here
//		const MDOUBLE MAXDISTANCE=2.0;
		const MDOUBLE MAXDISTANCE=15;
		
		MDOUBLE p =0;
		MDOUBLE len=0.0;
		if (weights == NULL) {
			for (int i = 0; i < s1.size() ; ++i) {
				//if (s1[i]<0 || s2[i]<0) continue; //gaps and missing data.
				len+=1.0;
				if (s1[i] != s2[i]) p++;
			}
			if (len==0) p=1;
			else p = p/len;
		} else {
			for (int i = 0; i < s1.size() ; ++i) {
				//if (s1[i]<0 || s2[i]<0) continue; //gaps and missing data.
				len += (*weights)[i];
				if (s1[i] != s2[i])  p+=((*weights)[i]);
			}
			if (len==0) p=1;
			else {
				p = p/len;
			}
		}
		const MDOUBLE inLog = 1 - (MDOUBLE)_alphabetSize*p/(_alphabetSize-1.0);
		if (inLog<=0) {
//			LOG(6,<<" DISTANCES FOR JC DISTANCE ARE TOO BIG");
//			LOG(6,<<" p="<<p<<endl);
			return MAXDISTANCE;
		}
		MDOUBLE dis = -1.0 * (1.0 - 1.0/_alphabetSize) * log (inLog);
		return dis;
	}
};
#endif
