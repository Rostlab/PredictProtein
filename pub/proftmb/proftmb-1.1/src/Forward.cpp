#include "Par.h"
#include "HTools.h"
#include "Tools.h"
#include <cmath>
#include <iostream>


//see Bioinformatics: The Machine Learning Approach
//appendix D, online at http://library.books24x7.com
//variable names a=alpha,b=beta,c,C,D are used as in 
//this reference

using namespace std;

void ForwardInit(Seq&,Par&,bool);
void ForwardInduct(Seq&,Par&,bool);
void ForwardTerm(Seq&,Par&,bool);
void CalcDlog(Seq&);
double ForwardSum(Seq&,Par&,const uint,const uint,bool);
double CalcNulllog(Seq&,Par&);

void Par::Forward(Seq& S,bool validQ){
	//calculates a,a_aux,a_scl,c,C by induction
	//if validQ, only considers valid paths during the
	//calculation of the next a_aux

	//Initialization
	ForwardInit(S,*this,validQ);
	
	//Induction from t={1..T-1}
	ForwardInduct(S,*this,validQ);

	//Termination, to calculate a(T-1,end_state)
	ForwardTerm(S,*this,validQ);

	//Calculation of D for all t
	CalcDlog(S);

}


void ForwardInit(Seq& S,Par& M,bool validQ){
	//Initializes all alpha and scale variables for one
	//run of the forward algorithm
	uint ian,t,T=S.scl.Seqlen,NA=Par::NumA;
	double sum;

	//allocate and initialize trellis variables
	M.trel.resize(S.scl.Seqlen);
	for (ian=0;ian<S.scl.Seqlen;ian++) M.trel[ian].resize(NA);
	for (t=0;t<T;t++){
		S.row[t].init_vec();
		for (ian=0;ian<NA;ian++) M.trel[t][ian]=mat();
	}
	//a) initialize a_aux(0,i) for all ian

	for (ian=0;ian<NA;ian++){
		M.trel[0][ian].a_aux=M.Pi[ian]*(S.*S.pReturn)(0,ian,M);
		if (!TrelQ(0,ian,S,validQ)) continue;
// 		S.row[0].N_ext+=1; //count paths to position 0
	}

	//b) initialize c(0)
	sum=0.0;
	for (ian=0;ian<NA;ian++) sum+=M.trel[0][ian].a_aux;
	S.row[0].c=sum;
	assert(sum!=0.0);

	//c) initialize a_scl(0,ian) for all ian
	for (ian=0;ian<NA;ian++)
		M.trel[0][ian].a_scl=M.trel[0][ian].a_aux/S.row[0].c;

	//d) initialize C_log(0) and N_path_log
	S.row[0].C_log=log(S.row[0].c);
// 	S.row[0].N_path_log=log((double)S.row[0].N_ext);
	assert(!isnan(S.row[0].N_path_log));
 	//cout<<"ForInit: P_log(0)="<<S.row[0].C_log<<endl;
}


void ForwardInduct(Seq& S,Par& M,bool validQ){
	//performs the induction step of the forward algorithm
	uint t,ian,T=S.scl.Seqlen,NA=Par::NumA;
	double sum;

	for (t=1;t<T;t++){

		//a) calculate a_aux(ian,t) for all ian
// 		uint N_ext; //passed by reference to ForwardSum
		//count of the number of extensions used
		//to trellis point (t,ian)
		for (ian=0;ian<NA;ian++){
// 			N_ext=0;
			M.trel[t][ian].a_aux=ForwardSum(S,M,ian,t,validQ);
// 			S.row[t].N_ext+=N_ext;
		}

		//b) calculate c(t)
		sum=0.0;
		for (ian=0;ian<NA;ian++) sum+=M.trel[t][ian].a_aux;
		S.row[t].c=sum;

		if (sum==0.0) {
			cerr<<"At position "<<t<<" in "<<S.scl.SeqID.data()
				<<" sum of all nodes a_aux is zero. "<<endl;
			cerr<<"Transition from "<<S.row[t-1].cln
				<<" to "<<S.row[t].cln<<endl;
			cerr<<"Labeling window which has no legal paths:"<<endl;

			uint beg,end,ind;
			if (t-15<0) beg=0;
			else beg=t-15;
			if (t+15>S.scl.Seqlen-1) end=S.scl.Seqlen-1;
			else end=t+15;
			for (ind=beg;ind<end;ind++) cerr<<S.row[ind].cln[0];
			cerr<<endl;
			for (ind=beg;ind<end;ind++) cerr<<S.row[ind].cln[1];
			cerr<<endl;
		}
		assert(sum!=0.0);
		//cout<<"c("<<t<<")="<<S.row[t].c<<endl;

		//c) calculate a_scl for all ian
		for (ian=0;ian<NA;ian++){
			M.trel[t][ian].a_scl=M.trel[t][ian].a_aux/S.row[t].c;
		}

		//d) calculate C_log(t) and N_path_log(t)
		S.row[t].C_log=log(S.row[t].c)+S.row[t-1].C_log;
// 		S.row[t].N_path_log=
// 			log((double)S.row[t].N_ext)+S.row[t-1].N_path_log;
// 		assert(!isnan(S.row[t].N_path_log) and abs(S.row[t].N_path_log)!=HUGE_VAL);
	}
	//cout<<"c(1)="<<S.row[1].c<<endl;
}


void ForwardTerm(Seq& S,Par& M,bool validQ){
	//calculate the full P_aux and P_scl as the full path
	//from begin_state to end_state
	double sum=0.0;
	uint ian,NA=Par::NumA,T=S.scl.Seqlen;
	for (ian=0;ian<NA;ian++) {
		if (!TrelQ(T-1,ian,S,validQ)) continue;
// 		assert(M.trel[T-1][ian].a_scl>0);
		sum+=M.trel[T-1][ian].a_scl*M.Ep[ian];
// 		N_last_ext++;
	}
	S.scl.P_scl=sum;
	//assert(sum!=0.0);
	//calculate P_log and Pnorm_log
	S.scl.P_log=log(S.scl.P_scl)+S.row[T-1].C_log;
	S.scl.C_log=S.row[T-1].C_log;
	S.scl.Pnorm_log=S.scl.P_log-(S.scl.Seqlen*S.scl.Z_log);
	S.scl.null_log=CalcNulllog(S,M);
	S.scl.Pbits=S.scl.P_log-S.scl.null_log;
	//S.scl.Score=S.scl.Pbits-(M.Slope*S.scl.Seqlen+M.Intercept);
//    	cout<<"For: P_log("<<S.scl.SeqID<<")="<<S.scl.P_log<<endl;
// 	S.scl.N_path_log=log((double)N_last_ext)+S.row[T-1].N_path_log;
// 	assert(!isnan(S.scl.N_path_log) and abs(S.scl.N_path_log)!=HUGE_VAL);
// 	S.scl.P_log_ave=S.scl.P_log-S.scl.N_path_log;
// 	cout<<"For: P_log_ave("<<S.scl.SeqID<<")="<<S.scl.P_log_ave<<endl;
}


void CalcDlog(Seq& S){
	//calculate D_log(t)=log(c(T-1))+log(c(T-2))+...log(c(t))
	uint T=S.scl.Seqlen;
	int t;
	S.row[T-1].D_log=log(S.row[T-1].c);
	for (t=T-2;t>=0;t--)
		S.row[t].D_log=S.row[t+1].D_log+log(S.row[t].c);
}


double ForwardSum(Seq& S,Par& M,const uint t_ian,const uint t,bool validQ){
	//calculates sum_i(a_scl(t-1,s_ian)*a(s_ian,t_ian)) * b(t_ian,O(t))
	//if validQ is true, only calculates those for which
	//trellis point (t-1,s_ian) is valid, and (t,t_ian) is valid
	//otherwise, calculates all s_ian
	//not all valid trellis points need have a nonzero score
	//but, at least one of the valid trellis points does.
	//in other words, the sum of a_scl over all states
	//must be nonzero
// 	N_ext=0;

	if (!TrelQ(t,t_ian,S,validQ)) return 0.0;

	//we have a valid trellis point to calculate

	uint n,s_ian,fn;
	double sum=0.0,aij;
	//cout<<"("<<t<<","<<t_ian<<") is valid"<<endl;
	//find all sources of t_ian, extend each to t_ian and sum them

	for (n=0;n<M.ArchSize[t_ian].nsrc;n++){

		s_ian=M.ArchRev[t_ian][n].src;
		fn=M.ArchRev[t_ian][n].index;
		//check if (s_ian,t-1) is a valid trellis point
		
		if (!TrelQ(t-1,s_ian,S,validQ)) continue;

		//fn is index of M.Arch whose target is t_ian
		aij=M.Arch[s_ian][fn].score;
		//aij is i->t_ian transition score


		sum+=M.trel[t-1][s_ian].a_scl*aij;
// 		N_ext++; //we are counting each time we add another path
		//to the forward sum
		assert(!isnan(sum));
	}

// 	if ((S.*S.pReturn)(t,t_ian,M)==0.0){
// 		cout<<Par::SANrev[t_ian]<<" has zero score with: "<<endl;
// 		cout<<"amino\tpar\tprofile"<<endl;
// 		for (uint i=0;i<Par::NUMAMINO;i++){
// 			cout<<i<<'\t'
// 				<<M.EmitAmino[Par::A2E[t_ian]][i]
// 				<<'\t'<<S.Profile[t][i]<<endl;
// 		}
// 		exit(1);
// 	}
//   	assert ((S.*S.pReturn)(t,t_ian,M)>0.0);
	
	//this assertion is only guaranteed to be true when
	//every emission parameter of t_ian is non-zero
	//what guarantees that the emission parameters be nonzero?
	//do we even want to make the assertion?
	
	sum*=(S.*S.pReturn)(t,t_ian,M);
	return sum;
}


double CalcNulllog(Seq& S,Par& M){
	double nl=0;
	for (uint t=0;t<S.scl.Seqlen;t++){
		nl+=log(DotP(&M.AAComp[0],&S.Profile[t][0],Par::NUMAMINO));
	}
	return nl;
}
