#include "Par.h"
#include "HTools.h"
#include <cmath>
#include <iostream>

using namespace std;

//see Bioinformatics: The Machine Learning Approach
//appendix D, online at http://library.books24x7.com
//variable names a=alpha,b=beta,c,C,D are used as in 
//this reference

void BackwardInit(Seq&,Par&,bool);
void BackwardInduct(Seq&,Par&,bool);
double BackwardSum(Seq&,Par&,uint,uint,bool);


void Par::Backward(Seq& S,bool validQ){
	//initialize dynamic part of backward
	BackwardInit(S,*this,validQ);

	//induction
	BackwardInduct(S,*this,validQ);
	//there is no termination needed, since
	//we don't use b(begin_state,0)
}


void BackwardInit(Seq& S,Par& M,bool validQ){
	uint i,T=S.scl.Seqlen,NA=Par::NumA;

	//a) initialize b_aux(T-1,i) for all i
	for (i=0;i<NA;i++){
		if (!TrelQ(T-1,i,S,validQ)) continue;
		M.trel[T-1][i].b_aux=M.Ep[i];
	}
	
	//b) initialize b_scl(T-1,i) for all i
	for (i=0;i<NA;i++){
		M.trel[T-1][i].b_scl=M.trel[T-1][i].b_aux/S.row[T-1].c;
		//assert(FP_INFINITE != fpclassify(M.trel[T-1][i].b_scl));
		//assert(FP_NAN != fpclassify(M.trel[T-1][i].b_scl));
	}
}


void BackwardInduct(Seq& S,Par& M,bool validQ){
	//the induction step during backward algorithm
	//from T-2 to 0 (T-2 is 1 less than the maximum position)
	uint i,T=S.scl.Seqlen,NA=Par::NumA;
	int t;
	for (t=T-2;t>=0;t--){
		//a) calculate b_aux(t,i) for all i
		for (i=0;i<NA;i++)
			M.trel[t][i].b_aux=BackwardSum(S,M,i,t,validQ);

		//b) calculate b_scl(t,i) for all i
		for (i=0;i<NA;i++){
			M.trel[t][i].b_scl=M.trel[t][i].b_aux/S.row[t].c;
			/*if (M.trel[t][i].b_scl != 0)
				cout<<"b_scl("<<t<<","<<M.trel[t][i].b_scl<<
				", c("<<t<<")="<<S.row[t].c<<endl;
			*/
		}
	}
	//calculation of C and D are already done during forward
	//induction
}


double BackwardSum(Seq& S,Par& M,uint i,uint t,bool validQ){
	//calculates sum_j(b_scl(t+1,j)*a(i,j)*b(j,O(t+1)))
	//assert that beta(t,i)>0 if (t,i) is a valid point
	assert(t+1<S.scl.Seqlen);
	uint j,n;
	double sum=0.0;
	if (!TrelQ(t,i,S,validQ)) return sum;
	//cout<<"BackwardSum received i="<<i<<", t="<<t;

	for (n=0;n<M.ArchSize[i].ntar;n++){
		j=M.Arch[i][n].node;
		if (!TrelQ(t+1,j,S,validQ)) continue;
		/*cout<<"scaled_beta("<<t+1<<","<<j<<")="<<M.trel[t+1][j].b_scl
			<<", a("<<i<<","<<j<<")="<<M.Arch[i][n].score
			<<", b("<<j<<",O("<<t+1<<")="<<(S.*S.pReturn)(t+1,j)
			<<"="<<M.trel[t+1][j].b_scl
			*M.Arch[i][n].score
			*(S.*S.pReturn)(t+1,j)<<endl;
			*/
		sum+=M.trel[t+1][j].b_scl //scaled_beta(t+1,j)
			* M.Arch[i][n].score //a(i,j)
			*(S.*S.pReturn)(t+1,j,M); //b(j,O(t+1)) (Rabiner 92a)
	}

	//assert(!TrelQ(t,i,S) or 0<sum);
	//if (t,i) is valid point, sum must be greater than 0, or is this
	//not true?

	return sum;
}
