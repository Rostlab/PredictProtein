#ifndef ___DISTANCE_TABLE
#define ___DISTANCE_TABLE

#include "distanceMethod.h"
#include "definitions.h"
#include "sequenceContainer1G.h"

void giveDistanceTable(distanceMethod* dis,
					   const sequenceContainer1G& sc,
					   VVdouble& res,
					   vector<string>& names,
					   const vector<MDOUBLE> * weights = NULL);


#endif
