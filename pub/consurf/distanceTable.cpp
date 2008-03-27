#include "distanceTable.h"

void giveDistanceTable(distanceMethod* dis,
					   const sequenceContainer1G& sc,
					   VVdouble& res,
					   vector<string>& names,
					   const vector<MDOUBLE> * weights){
	res.resize(sc.numberOfSequences());
	for (int z=0; z< sc.numberOfSequences();++z) res[z].resize(sc.numberOfSequences(),0.0);

	for (int i=0; i < sc.numberOfSequences();++i) {
		for (int j=i+1; j < sc.numberOfSequences();++j) {
			res[i][j] = dis->giveDistance(sc[i],sc[j],weights,NULL);
			cerr<<"res["<<i<<"]["<<j<<"] ="<<res[i][j]<<endl;
		}
		names.push_back(sc[i].name());
	}
}
