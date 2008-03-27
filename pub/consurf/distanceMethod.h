#ifndef ___DISTANCE_METHOD
#define ___DISTANCE_METHOD

#include "sequence.h"
#include "definitions.h"


class distanceMethod {
public:
	virtual const MDOUBLE giveDistance(	const sequence& s1,
										const sequence& s2,
										const vector<MDOUBLE> * weights,
										MDOUBLE* score=NULL) const=0;
};


#endif

