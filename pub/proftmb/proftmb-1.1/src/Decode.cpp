#include "Seq.h"
#include "Par.h"
#include <iostream>
#include <cmath>


void CountPredStrands(Seq& S){
	//counts the number of predicted beta-strands of the given
	//sequence
	//traverse this->row[t].predbetaQ, finding each switch from
	//false to true, indicating the start of a strand
	S.scl.npredstrands=0;
	bool prevQ=false;
	//current truth value is this->row[t].predbetaQ
	//we start out false because the first strand may start at position 0
	for (int t=0;t<(int)S.scl.Seqlen;t++){
		if (S.row[t].predbetaQ && ! prevQ)	S.scl.npredstrands++;
		prevQ=S.row[t].predbetaQ;
	}
}


void Seq::Decode(Par& M){
	//compute multi-state reduction scores for each position t

	M.Forward(*this,false);
	M.Backward(*this,false);

	//Trace forward viterbi path using multi-state reduction
	//probability as the metric
	this->LogViterbiMulti(M);

	//Traceback
	this->Traceback(M);
 	CountPredStrands(*this); //counts number predicted strands
	if (scl.labelQ) this->CalcCTable(M);

}




void Seq::LogViterbiMulti(Par& M){
	//finds the viterbi path using ReduxDecode as the state-reduction
	//criterion, and the probability of being in one reduced state
	//as the metric
	//uses the viterbi algorithm
	uint n,ian,s_ian,t,fn,T=this->scl.Seqlen,NA=Par::NumA;
	uint ist;
	double tmpcs_log,aij_log;
	double total=0.0;

	//calculate relative state probabilities for
	//each final state, store in stateprobs[pos][istate]=prob
	vector<vector<double> >StateProbs(T);
	for (t=0;t<StateProbs.size();t++){
		StateProbs[t].resize(Par::NDecode);
		for (ist=0;ist<Par::NDecode;ist++) StateProbs[t][ist]=0.0;
		for (ian=0;ian<NA;ian++) {
			StateProbs[t][Par::ReduxDecode[ian]]
				+=M.trel[t][ian].a_scl * M.trel[t][ian].b_scl;
			total+=M.trel[t][ian].a_scl * M.trel[t][ian].b_scl;
		}
		for (ist=0;ist<Par::NDecode;ist++) StateProbs[t][ist]/=total;
	}

	//initialization
	for (t=0;t<T;t++)
		for (ian=0;ian<NA;ian++){
			M.trel[t][ian].cs=0.0;
			M.trel[t][ian].cs_log=-HUGE_VAL;
		}
	for (ian=0;ian<NA;ian++){
		M.trel[0][ian].cs_log=
			log(M.Pi[ian]) + 
			log(StateProbs[0][Par::ReduxDecode[ian]]);
	}


	//extension
	for (t=1;t<T;t++) {
		for (ian=0;ian<NA;ian++){
			for (n=0;n<M.ArchSize[ian].nsrc;n++) {
				s_ian=M.ArchRev[ian][n].src;
				fn=M.ArchRev[ian][n].index;
				aij_log=log(M.Arch[s_ian][fn].score);

				tmpcs_log=M.trel[t-1][s_ian].cs_log
					+aij_log
					+log(StateProbs[t][Par::ReduxDecode[ian]]);

				if (M.trel[t][ian].cs_log<tmpcs_log) {
					M.trel[t][ian].cs_log=tmpcs_log;
					M.trel[t][ian].s_atom=s_ian;
				}
			}
		}
	}

	//termination
	//update the cs_log(T-1,i) for all i
	for (ian=0;ian<NA;ian++)
		M.trel[T-1][ian].cs_log+=log(M.Ep[ian]);
	//possible error here, taking the log of zero?
}


void Seq::Traceback(Par& M){
	//traces back the viterbi path under multistate decoding
	uint ian,t,T=this->scl.Seqlen,NA=Par::NumA,cur_ian,maxi=0;
	double max_log=-HUGE_VAL;
	//initialization: find top-scoring last atom
	for (ian=0;ian<NA;ian++) {
		//cout<<"log P(T-1,"<<i<<")="<<M.trel[T-1][i].cs_log<<endl;
		if (M.trel[T-1][ian].cs_log>max_log) {
			max_log=M.trel[T-1][ian].cs_log;
			maxi=ian;
		}
	}
	
	//record RV_log, the total 'probability' of the Reduced Viterbi
	//path.  This is not a true probability, but it is in the spirit
	//of a Viterbi path
	this->scl.RV_log=max_log;
	this->scl.RVbits=this->scl.RV_log-this->scl.null_log;

	//initialize 
	cur_ian=maxi; //initialize traceback
	this->row[T-1].pred_ian=cur_ian; //initialize 

	//trace back by s_atom
	for (t=T-1;t>0;t--) {
		this->row[t-1].pred_ian=M.trel[t][cur_ian].s_atom;
		cur_ian=this->row[t-1].pred_ian;
	}

	//translate pred_ian's into cpn's and betaQ's using ?
	for (t=0;t<T;t++) {
		this->row[t].cpn[0]=Par::SANrev[this->row[t].pred_ian][0];
		this->row[t].cpn[1]=Par::SANrev[this->row[t].pred_ian][1];
		//warning: assigning char* to char[2]
		//this->row[t].pred_istate=Par::ReduxEval[this->row[t].pred_ian];
	}
}
