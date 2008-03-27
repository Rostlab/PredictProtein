#include "TrainSeq.h"
#include "Par.h"
#include <cmath>

void TrainSeq::ExpectationP(Par& M){
	//allocate
	uint t,ev,ian,ien;
	uint NA=Par::NumA;
	uint NE=Par::NumE;
	double pathscore;
	vector<double> ex_sclH(Par::NLProf),ex_sclE(Par::NLProf),ex_sclL(Par::NLProf),
		ex_condH(Par::NLProf),ex_condE(Par::NLProf),ex_condL(Par::NLProf);

	//initialize
	for (ien=0;ien<NE;ien++)
		for (ev=0;ev<Par::NLProf;ev++){
			M.P[ien].H[ev]=0.0;
			M.P[ien].E[ev]=0.0;
			M.P[ien].L[ev]=0.0;
		}
	
	//calculate C_k(c) for all k,c and normalize over c
	for (ian=0;ian<NA;ian++){ //architectural state
		ien=Par::A2E[ian];
		for (ev=0;ev<Par::NLProf;ev++) {
			ex_sclH[ev]=0.0;
			ex_sclE[ev]=0.0;
			ex_sclL[ev]=0.0;
		}
		for (t=0;t<scl.Seqlen;t++){ //position
			pathscore=
				M.trel[t][ian].a_scl*
				M.trel[t][ian].b_scl*
				this->row[t].c;
			ex_sclH[this->row[t].lH]+=pathscore;
			ex_sclE[this->row[t].lE]+=pathscore;
			ex_sclL[this->row[t].lL]+=pathscore;
		}

		for (ev=0;ev<Par::NLProf;ev++){
			ex_condH[ev]=ex_sclH[ev]/this->scl.P_scl;
			ex_condE[ev]=ex_sclE[ev]/this->scl.P_scl;
			ex_condL[ev]=ex_sclL[ev]/this->scl.P_scl;
			assert(!isnan(ex_condH[ev]));
			assert(!isnan(ex_condE[ev]));
			assert(!isnan(ex_condL[ev]));
			// divide by P(d(s)|M)
			//this obviates the need for dividing by Z^T
			M.P[ien].H[ev]=ex_condH[ev];
			M.P[ien].E[ev]=ex_condE[ev];
			M.P[ien].L[ev]=ex_condL[ev];
		}
	}
}
