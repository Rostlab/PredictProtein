#include "TrainSeq.h"

TrainSeq::TrainSeq (){}

TrainSeq::TrainSeq (multimap<string,string>&sdat,string id,
					set<string>& emptyset,map<string,string>& nomap)
	: Seq(sdat,id,emptyset,nomap){

	//initialize inherited members:

	//initialize own members 
	uint i;
	Pi.resize(Par::NumA);
	Ep.resize(Par::NumA);
	A.resize(Par::NumA);
	C.resize(Par::NumE);
	P.resize(Par::NumE);

	for (i=0;i<Par::NumA;i++) A[i].resize(Par::NumA);
	for (i=0;i<Par::NumE;i++) C[i].resize(Par::NUMAMINO);
	for (i=0;i<Par::NumE;i++) {
		P[i].H.resize(Par::NLProf);
		P[i].E.resize(Par::NLProf);
		P[i].L.resize(Par::NLProf);
	}
}	
