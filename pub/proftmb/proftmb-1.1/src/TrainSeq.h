#ifndef _TRAINSEQ
#define _TRAINSEQ

#include "structs.h"
#include "Seq.h"
#include "Par.h"

using namespace std;

class Par;
//class Seq;

class TrainSeq : public Seq {
 public:
	vector<vector<double> >A,C; //A[i][j] and C[i][c] and P[i][ev]
	vector<proftriple>P; // P[ien].H[ev] (or E, or L)
	vector<double>Pi; //Pi[ian]=begin->ian transition score
	vector<double>Ep; //Ep[ian]=ian->end transition score
	void ExpectationA(Par&);
	//umbrella function, executes all following functions
	
	void ExpectationTrans(Par&);
	//expectations of normal transitions i->j,
	
	void ExpectationPi(Par&);
	//expectations of begin->i transitions,
	//normalized over all i
	
	void ExpectationEp(Par&);
	//normalized expectations of i->end transitions
	
	double CalcACond(const uint,const uint,double,Par&);
	//Helper function for ExpectationTrans
	
	void ExpectationC(Par&); //expected values of emissions
	void ExpectationP(Par&); //expected values of emissions
	TrainSeq();
	TrainSeq(multimap<string,string>&,string,
			 set<string>&,map<string,string>&);
};

#endif
