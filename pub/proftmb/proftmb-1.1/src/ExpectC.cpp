#include "TrainSeq.h"
#include "Par.h"
#include <cmath>

using namespace std;

//calculates E[i,c|S,M]=E[i,c|M]/P(S|M), the expected quantity
//of emitted symbol c from state i, given sequence
//S is generated from model M


void TrainSeq::ExpectationC(Par& M){
	//allocate
	uint t,c,ian,ien;
	uint NA=Par::NumA;
	uint NE=Par::NumE;
	double ex_scl,ex_cond;

	//initialize
	for (ien=0;ien<NE;ien++)
		for (c=0;c<Par::NUMAMINO;c++)
			this->C[ien][c]=0.0;


	//calculate C_k(c) for all k,c and normalize over c
	
	for (ian=0;ian<NA;ian++){ //architectural state
		ien=Par::A2E[ian];
		for (c=0;c<Par::NUMAMINO;c++){ //symbol
			ex_scl=0.0;
			for (t=0;t<scl.Seqlen;t++){ //position
				ex_scl+=M.trel[t][ian].a_scl*
					M.trel[t][ian].b_scl*
					this->row[t].c*
					this->Profile[t][c];
			}
			ex_cond=ex_scl/this->scl.P_scl;
			//ex_cond=ex_scl/this->scl.P_scl_h;
			// divide by P(d(s)|M)
			//this obviates the need for dividing by Z^T
			assert(!isnan(ex_cond));
			this->C[ien][c]+=ex_cond;
		}
	}
}
