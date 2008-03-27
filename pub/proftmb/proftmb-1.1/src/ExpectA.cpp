#include "TrainSeq.h"
#include "Par.h"
#include <cmath>
#include "HTools.h"
#include "Tools.h"


//all of these algorithms depend on a_scl and b_scl.
//thus, if a_scl and b_scl are computed using only valid paths,
//the expected values will only represent use in valid paths.

void TrainSeq::ExpectationA(Par& M){
	this->ExpectationTrans(M);
	this->ExpectationPi(M);
	this->ExpectationEp(M);
}



void TrainSeq::ExpectationTrans(Par& M){
	//given a labelled training sequence
	//Architecture and emission parameters, calculate 
	//the expectations E[i_ian->j_ian|S] of a transition
	//allows for a given node to have zero expected transitions

	uint i_ian,j_ian,n,NA=Par::NumA;
	double ts;

	//initialize
	for (i_ian=0;i_ian<NA;i_ian++) 
		for (j_ian=0;j_ian<NA;j_ian++)
			this->A[i_ian][j_ian]=0.0;
	
	//calculate A(i,j) for all i,j such that j is a target of i
	//and normalize over j
	//we iterate in n rather than j
	for (i_ian=0;i_ian<NA;i_ian++){
		//fan out over all targets of i
		for (n=0;n<M.ArchSize[i_ian].ntar;n++){
			j_ian=M.Arch[i_ian][n].node;
			ts=M.Arch[i_ian][n].score;
			
			//calculate sum_S(E[i_ian->j_ian|S])
			this->A[i_ian][j_ian]=CalcACond(i_ian,j_ian,ts,M); //E[i->j|s]
		}
	}
}


double TrainSeq::CalcACond(const uint i,const uint j,double ts,Par& M){
	//calculates E[i_ian->j_ian|S] for a sequence
	//the expected number of transitions i_ian->j_ian given S
	//doesn't check whether 
	double ex_scl=0.0,ex_cond; //P_scl_hybrid=P(all paths)/C(valid paths)
	uint t,T=this->scl.Seqlen;
	//cout<<"CalcACond: i="<<i<<endl;
	for (t=0;t<T-1;t++){
		ex_scl+=M.trel[t][i].a_scl
			*ts //i->j transition score
			*M.trel[t+1][j].b_scl
			*(this->*this->pReturn)(t+1,j,M);
	}

	//ex_cond=ex_scl/this->scl.P_scl_h; //P_scl_hybrid this doesn't work
	ex_cond=ex_scl/this->scl.P_scl;
	assert(0!=this->scl.P_scl);
	assert(!isnan(ex_scl));
	return ex_cond;
}



void TrainSeq::ExpectationPi(Par& M){
	//calculates normalized expectations of begin
	//transitions Pi
	uint i,NA=Par::NumA;
	double ex_scl,ex_cond;
	for (i=0;i<NA;i++){
		ex_scl=M.trel[0][i].b_scl*
			M.Pi[i]*
			(this->*this->pReturn)(0,i,M);
		ex_cond=ex_scl/this->scl.P_scl;
		//ex_cond=ex_scl/this->scl.P_scl_h;
		this->Pi[i]=ex_cond;
	}
}


void TrainSeq::ExpectationEp(Par& M){
	//calculates normalized expectations of end
	//transitions Ep_ex
	uint i,NA=Par::NumA,T=this->scl.Seqlen;
	double ex_scl,ex_cond;

	for (i=0;i<NA;i++){
		ex_scl=M.trel[T-1][i].a_scl*
			M.Ep[i];
		ex_cond=ex_scl/this->scl.P_scl;
		//ex_cond=ex_scl/this->scl.P_scl_h;
		this->Ep[i]=ex_cond;
	}
}
