#include "siteSpecificRate.h"
#include "numRec.h"
#include "checkcovFanctors.h"

MDOUBLE computeML_siteSpecificRate(Vdouble & ratesV,
								   Vdouble & likelihoodsV,
								   Vdouble & reliabilityV,
								   const sequenceContainer1G& sd,
								   const stochasticProcess& sp,
								   const tree& et,
								   const MDOUBLE maxRate,//20.0f
								   const MDOUBLE tol){//=0.0001f;
	ratesV.resize(sd.seqLen());
	likelihoodsV.resize(sd.seqLen());
	reliabilityV.resize(sd.seqLen()); // how relialbe is each computation.
	MDOUBLE Lsum = 0.0;

	for (int pos=0; pos < sd.seqLen(); ++pos) {
		cerr<<".";
		MDOUBLE ax=0.0f,bx=5.0f,cx=maxRate;
		MDOUBLE maxR1=0.0;
		MDOUBLE LmaxR1=
			brent(ax,bx,cx,Cevaluate_L_given_r(sd,et,sp,pos),tol,&maxR1);
		likelihoodsV[pos] = -LmaxR1;
		ratesV[pos] = maxR1;
		Lsum += likelihoodsV[pos];
		reliabilityV[pos] = computePosReliability(sd,pos);
		cerr<<" rate of pos: "<<pos<<" = "<<ratesV[pos]<<endl;
	}
	cerr<<" number of sites: "<<sd.seqLen()<<endl;
	return Lsum;
}

// this function doesn't computes the "reliability" of each position.
// it just counts the number of participating character in each positions.
MDOUBLE computePosReliability(const sequenceContainer1G sd,const int pos) {
	MDOUBLE numOfNonCharPos = sd.numberOfSequences();
	for (int i=0; i < sd.numberOfSequences(); ++i) {
		if (sd[i][pos] <0) --numOfNonCharPos;
	}
	return numOfNonCharPos;
}

