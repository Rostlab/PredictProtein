#include "Par.h"
#include "HTools.h"
#include <iostream>
#include <iomanip>

using namespace std;


bool TrelQ(uint t,uint ian,Seq& S,bool validQ){
 	//tells whether (t,i) is a valid trellis point
 	if (!validQ) return true;
 	return Par::LA[S.row[t].iln][ian];
}


void PrintFSum(Seq& S,Par& M,const uint j,const uint t,bool validQ){

	uint n,i,fn;
	double aij;

	cout<<"a_aux("<<t<<","<<j<<"("<<"))="<<endl;
	//find all sources of j, extend each to j and sum them
	for (n=0;n<M.ArchSize[j].nsrc;n++){

		i=M.ArchRev[j][n].src;
		fn=M.ArchRev[j][n].index;
		//check if (i,t-1) is a valid trellis point
		if (!TrelQ(t-1,i,S,validQ)) continue;
		
		//fn is index of M.Arch whose target is j
		aij=M.Arch[i][fn].score;
		//aij is i->j transition score
		cout<<M.trel[t-1][i].a_scl<<" * "<<aij
			<<"\t//a_scl("<<t-1<<","<<i<<") * a("<<i
			<<","<<j<<") + ..."<<endl;
	}

	cout<<"... * "<<(S.*S.pReturn)(t,j,M)
		<<"O("<<t<<","<<j<<")"<<endl<<endl;

}


