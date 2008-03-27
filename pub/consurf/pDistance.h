#ifndef ___P_DISTANCE
#define ___P_DISTANCE

#include "distanceMethod.h"

class pDistance : public distanceMethod {
public:
	explicit pDistance{}
	const MDOUBLE giveDistance(	const sequence& s1,
								const sequence& s2,
								const vector<MDOUBLE>  * weights,
								MDOUBLE* score=NULL) const {//score is not used here
		MDOUBLE p =0;
		if (weights == NULL) {
			for (int i = 0; i < s1.size() ; ++i) if (s1[i] != s2[i]) p++;
			p = p/s1.size();
		} else {
			MDOUBLE len=0;
			for (int i = 0; i < s1.size() ; ++i) {
				len +=((*weights)[i]);
				if (s1[i] != s2[i]) p+=((*weights)[i]);
			}
			p = p/len;
		}
		return p;
	}
};

#endif
