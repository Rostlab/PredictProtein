#include "Par.h"
#include "Seq.h"

using namespace std;


//This algorithm finds a path ensemble which is defined as
//a set of paths all having the same 2-state reduction
//The path ensemble with the highest probability is found
struct ts{
	bool beta,non;
};

void InitRV(Seq&,Par&);
void InductRV(Seq&,Par&,uint,vector<ts>&);
bool TermRV(Seq&,Par&);
void TracebackRV(Seq&,Par&,vector<ts>&,bool);
//helper functions only used within ReducedViterbi


void Par::ReducedViterbi(Seq& S){
	uint t,T=S.scl.Seqlen;
	vector<ts>trace(T);
	bool last_state; //used logically as M.trel[T][end].a_aux_(b|n)

	//Initialization
	InitRV(S,*this);

	//Induction
 	for (t=1;t<T;t++) InductRV(S,*this,t,trace);
// 	for (t=1;t<50;t++) InductRV(S,*this,t,trace);

	//Termination
	last_state=TermRV(S,*this);
// 	last_state=false;

	//Traceback
	TracebackRV(S,*this,trace,last_state);
}


void InitRV(Seq& S,Par& M){
	//Initializes alpha and scale variables for one
	//run of the ReducedViterbi algorithm
	uint t,T=S.scl.Seqlen,ian;
	double sum_raw;
	//allocate and initialize M.trellis variables
	M.trel.resize(T);
	
	for (t=0;t<T;t++){
		M.trel[t].resize(Par::NumA);
		for (ian=0;ian<Par::NumA;ian++)
			M.trel[t][ian]=mat();
	}
	//a) initialize a(0,ian) for all ian
	for (ian=0;ian<Par::NumA;ian++)
		M.trel[0][ian].a=M.Pi[ian]*(S.*S.pReturn)(0,ian,M);

	//b) calculate c(0)
	sum_raw=0;
	for (ian=0;ian<Par::NumA;ian++)	sum_raw+=M.trel[0][ian].a;
	S.row[0].c=sum_raw;

	//c) initialize a_scl(0,ian) for all ian
	for (ian=0;ian<Par::NumA;ian++)
		M.trel[0][ian].a_scl=M.trel[0][ian].a/S.row[0].c;

	//d) initialize C_log(0)
	S.row[0].C_log=log(S.row[0].c);
// 	cout<<"RVinit: C_log(0)="<<S.row[0].C_log<<endl;

}


void InductRV(Seq& S,Par& M,uint t,vector<ts>& tr){
	uint ian,s_ian,t_ian,n,fn;
	double aij,b2b,b2n,n2b,n2n,sum_b,sum_n;

	//a) calculate a_aux_b and a_aux_n
	for (t_ian=0;t_ian<Par::NumA;t_ian++){
		sum_b=sum_n=0.0;
		for (n=0;n<M.ArchSize[t_ian].nsrc;n++){
			s_ian=M.ArchRev[t_ian][n].src;
			fn=M.ArchRev[t_ian][n].index;
			aij=M.Arch[s_ian][fn].score;
			assert(M.Arch[s_ian][fn].node==t_ian);
				
			if (Par::TwoState[s_ian])
 				sum_b+=M.trel[t-1][s_ian].a_scl*aij;
			else
 				sum_n+=M.trel[t-1][s_ian].a_scl*aij;
		}
		M.trel[t][t_ian].a_aux_b=sum_b*(S.*S.pReturn)(t,t_ian,M);
		M.trel[t][t_ian].a_aux_n=sum_n*(S.*S.pReturn)(t,t_ian,M);
	}
	//b) find out which source set (beta,t-1) or (non,t-1) gives
	//the greater total target set for (beta,t) and (non,t)

	b2b=n2b=b2n=n2n=0.0;
	//these are 
	for (ian=0;ian<Par::NumA;ian++){
		if (Par::TwoState[ian]){
			b2b+=M.trel[t][ian].a_aux_b;
			n2b+=M.trel[t][ian].a_aux_n;
		}
		else {
			b2n+=M.trel[t][ian].a_aux_b;
			n2n+=M.trel[t][ian].a_aux_n;
		}
	}

	// set trace[t].beta
	if (b2b>n2b) tr[t].beta=true;
	else tr[t].beta=false;

	// set trace[t].non
	if (b2n>n2n) tr[t].non=true;
	else tr[t].non=false;

	double sum_aux=0.0;
	for (ian=0;ian<Par::NumA;ian++){
		
		//for all beta nodes
		if (Par::TwoState[ian]){
			if (b2b>n2b)
 				M.trel[t][ian].a_aux=M.trel[t][ian].a_aux_b;
 			else M.trel[t][ian].a_aux=M.trel[t][ian].a_aux_n;
			assert(!isnan(M.trel[t][ian].a));
		}


		//for all non-beta nodes
		else{
			if (b2n>n2n)
 				M.trel[t][ian].a_aux=M.trel[t][ian].a_aux_b;
 			else M.trel[t][ian].a_aux=M.trel[t][ian].a_aux_n;
			assert(!isnan(M.trel[t][ian].a));
			assert(!Par::TwoState[ian]);
		}

		//find the sum of all auxiliary vars at time t
 		sum_aux+=M.trel[t][ian].a_aux;
	}
	S.row[t].c=sum_aux;

	//c) calculate a_scl for all ian
	for (ian=0;ian<Par::NumA;ian++)
		M.trel[t][ian].a_scl=M.trel[t][ian].a_aux/S.row[t].c;

	//d) calculate C_log(t)
	S.row[t].C_log=log(S.row[t].c)+S.row[t-1].C_log;

// 	if (t==11){
// 		for (uint t_cur=0;t_cur<3;t_cur++){
// 			for (ian=0;ian<Par::NumA;ian++){
// // 				if (Par::TwoState[ian]!=S.row[t_cur].actbetaQ) continue;
// 				cout<<"RVinduct: a_log("<<t_cur<<","
// 					<<ian<<"="<<Par::SANrev[ian]<<")="
// 					<<log(M.trel[t_cur][ian].a_scl)+
// 					S.row[t_cur].C_log<<endl;
// 			}
// 			cout<<endl<<endl;
// 		}
// 	}
//  	cout<<"RV: a_log(0,"<<t<<")="<<log(M.trel[t][0].a_scl)+
//  		S.row[t].C_log<<endl;
	assert(!isnan(S.row[t].C_log));
}		


bool TermRV(Seq& S,Par& M){
	//terminates the reduced-viterbi algorithm using M.Ep
	uint ian,T=S.scl.Seqlen;
	bool ls; //last state
	double end_aux_b=0,end_aux_n=0;
	for (ian=0;ian<Par::NumA;ian++){
		if (Par::TwoState[ian])
 			end_aux_b+=M.trel[T-1][ian].a_scl*M.Ep[ian];
		else
			end_aux_n+=M.trel[T-1][ian].a_scl*M.Ep[ian];
	}
	if (end_aux_b>end_aux_n) {
		ls=true;
		S.scl.P_scl=end_aux_b;
	}

	else {
		ls=false;
		S.scl.P_scl=end_aux_n;
	}

	S.scl.P_log=log(S.scl.P_scl)+S.row[T-1].C_log;
	cout<<"RV: P_log("<<S.scl.SeqID<<")="<<S.scl.P_log<<endl;
	return ls;
}
	

void TracebackRV(Seq& S,Par& M,vector<ts>& tr,bool ls){
	uint t,T=S.scl.Seqlen;
	bool new_state; //true means beta, false means non-beta
	//initialization: find highest scoring last state set
	S.row[T-1].predbetaQ=ls;
 	S.row[T-1].actbetaQ=ls;
	
 	for (t=T-1;t>0;t--){
		if (S.row[t].predbetaQ) new_state=tr[t].beta;
		else new_state=tr[t].non;
		S.row[t-1].predbetaQ=new_state;
 		S.row[t-1].actbetaQ=new_state; //this put in so we can use
	}
}
