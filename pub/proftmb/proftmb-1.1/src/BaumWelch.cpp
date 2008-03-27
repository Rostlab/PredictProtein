#include "Par.h"
#include "TrainSeq.h"
#include "Tools.h"
#include "Output.h"
#include <cmath>
#include <iostream>


using namespace std;

void Par::Maximization(bool ProfQ){
	//update transitions: assign A values to Par::Arch
	uint c,ev,ian,ien,j,n,NA=Par::NumA,NE=Par::NumE;
	for (ian=0;ian<NA;ian++)
		for (n=0;n<this->ArchSize[ian].ntar;n++) {//j:j is target of i
			j=this->Arch[ian][n].node;
			assert(!isnan(this->A[ian][j]));
			this->Arch[ian][n].score=this->A[ian][j];
		}
	//update amino emissions: assign C values to this->EmitAmino
	for (ien=0;ien<NE;ien++)
		for (c=0;c<Par::NUMAMINO;c++){
			this->EmitAmino[ien][c]=this->C[ien][c];
			assert(!isnan(this->C[ien][c]));
		}

// 	for (c=0;c<NUMAMINO;c++)
// 		for (ien=0;ien<NumE;ien++)
// 			cout<<"sen "<<SENrev[ien]<<", "<<c<<"="
// 				<<EmitAmino[ien][c]<<endl;

	//update prof emissions: assign P values to this->EmitProf
	if (ProfQ)
		for (ien=0;ien<NE;ien++)
			for (ev=0;ev<NLProf;ev++)
				this->EmitProf[ien].H[ev]=this->P[ien].H[ev];
}



void Par::BaumWelch(vector<TrainSeq>& tsq,double min_delta,string& ex,bool validQ,bool ProfQ){
	//iterate the update cycle until total score 
	//changes by less than delta either way
	double prev_score,cur_score=-HUGE_VAL,cur_delta=HUGE_VAL;
	while (cur_delta>min_delta){
		prev_score=cur_score;
		cur_score=this->Update(tsq,ex,validQ,ProfQ);
		cur_delta=abs(cur_score-prev_score);
	}
}


//execute a single update cycle used in BaumWelch training
//this is a convenience function used individually only
//in the context of the jackknife-by-cycle test
//Normally, jackknifing is done at the end of Baum-Welch
//training using a standard cutoff

double Par::Update(vector<TrainSeq>&tsq,string& exclude,bool validQ,bool ProfQ){
	//one iteration of BaumWelch on training sequences,
	//excluding exclude, and considering only valid paths
	//if validQ is true

	uint s,D=tsq.size();
	double cur=0.0;
	
	//calculate Forward,Backward,Expectations
	for (s=0;s<D;s++) {
		if (tsq[s].scl.SeqID==exclude) continue;
		//this->Forward(tsq[s],false); //this gets us P_log_ap
		this->Forward(tsq[s],validQ);
		//tsq[s].scl.P_scl_h=
		//	exp(tsq[s].scl.P_log_ap-tsq[s].scl.C_log);
		this->Backward(tsq[s],validQ);
		tsq[s].ExpectationA(*this);
		tsq[s].ExpectationC(*this);
		if (ProfQ) tsq[s].ExpectationP(*this);
	}
	
	//sum and normalize expectations
	this->ComputeNormE(tsq,exclude,ProfQ);

	//assign normalized expectations to model params
	this->Maximization(ProfQ);

	//calculate new scores sum_S(log(P(S|M)))
	for (s=0;s<D;s++) {
		if (tsq[s].scl.SeqID==exclude) continue;
		cur+=tsq[s].scl.P_log;
	}

	return cur;
}


void Par::ComputeNormE(vector<TrainSeq>&tsq,string& ex,bool ProfQ){
	//computes the sum of conditional expectations
	//of all training sequences, excluding 'ex'
	//then, normalizes by target j(for A's) or 
	//symbol c(for C's)

	uint ian,ien,j,c,ev,s,D=tsq.size();
	double sum,sumH,sumE,sumL;
	for (ian=0;ian<NumA;ian++){

		//compute sums of A's, store in this->A,normalize over j
		for (j=0;j<NumA;j++){
			sum=0.0;
			for (s=0;s<D;s++){
				if (tsq[s].scl.SeqID==ex) continue;
				sum+=tsq[s].A[ian][j];
			}
			this->A[ian][j]=sum;
		}
		BoolNormalize(&this->A[ian][0],this->A[ian].size());
	}

	//compute sums of C's, store in this->C, normalize over c
	for (ien=0;ien<NumE;ien++){
		for (c=0;c<NUMAMINO;c++){
			sum=0.0;
			for (s=0;s<D;s++){
				if (tsq[s].scl.SeqID==ex) continue;
				sum+=tsq[s].C[ien][c];
			}
			this->C[ien][c]=sum;
		}
		BoolNormalize(&this->C[ien][0],this->C[ien].size());
	}

	//compute sums of P's, store in this->P, normalize over event
	if (ProfQ){
		for (ien=0;ien<NumE;ien++){
			for (ev=0;ev<NLProf;ev++){
				sumH=sumE=sumL=0.0;
				for (s=0;s<D;s++){
					if (tsq[s].scl.SeqID==ex) continue;
					sumH+=tsq[s].P[ien].H[ev];
					sumE+=tsq[s].P[ien].E[ev];
					sumL+=tsq[s].P[ien].L[ev];
				}
				this->P[ien].H[ev]=sumH;
				this->P[ien].E[ev]=sumE;
				this->P[ien].L[ev]=sumL;
			}
			BoolNormalize(&this->P[ien].H[0],NLProf);
			BoolNormalize(&this->P[ien].E[0],NLProf);
			BoolNormalize(&this->P[ien].L[0],NLProf);
		}
	}
}
