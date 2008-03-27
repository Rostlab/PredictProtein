#ifndef _Par
#define _Par

#include "structs.h"
#include <string>
#include <vector>
#include <map>
#include <set>
#include <utility> //for pair
#include <cmath>
#include <cassert>

using namespace std;

class TrainSeq;
class Seq;

struct mat {
	double a,a_scl,a_aux,b,b_scl,b_aux,cs,cs_log,as;
	double a_aux_b,a_aux_n;
	uint s_atom;
	//cumulative-score(for viterbi decoding)
	//alpha,scaled alpha,auxiliary alpha
	//beta, scaled beta,auxiliary beta
	//atomic score,source-atom
	//source set (which set (beta/non-beta) is the source set)
	mat():a(0),a_scl(0),a_aux(0),b(0),b_scl(0),b_aux(0),cs(0),
		 cs_log(-HUGE_VAL),as(0),a_aux_b(0),a_aux_n(0),s_atom(0){}
};


class Par {
	static void InitAbet(const char*);
	static void InitConst(uint,uint,double*);
	static void InitConst(double,double);
	static void InitMaps(char*,char*,char*,char*,char*,char*);
	static void LoadL2L(char*) throw (string&);
	static void LoadL2A(char*) throw (string&);
	static void LoadA2E(char*) throw (string&);
	static void LoadConnect(char*) throw (string&);
	static void LoadRedux(char*,char*) throw (string&);
	static void UpdateA(vector<vector<double> >&,uint,uint);
	static void UpdateA2(vector<vector<double> >&,uint,uint);


	//helper functions for construction
	void Allocate(uint,uint);
	void InitArchRev();
	void InitArchSize();
	
	void Maximization(bool); //updates parameters with normalized expectataions
	void BaumWelch(vector<TrainSeq>&,double,string&,bool,bool); //iterates EM until some cutoff
	void ComputeNormE(vector<TrainSeq>&,string&,bool);

 public:
	void IncrComp(Seq&);
	void Forward(Seq&,bool); //all paths
	void Backward(Seq&,bool); //all paths
	void ReducedViterbi(Seq&);
	Par(vector<TrainSeq>&,char*,string&,bool=false);
	Par();
	double Update(vector<TrainSeq>&,string&,bool,bool=false);
	void TallyA(vector<TrainSeq>&,string&);
	void TallyE(vector<TrainSeq>&,string&);
	void TallyP(vector<TrainSeq>&,string&);


	// i=int,s=string,d=double
	vector<vector<archpair> >Arch; // Arch[ian_src][n_for]=(node,score)
	vector<tarsrcpair>ArchSize; //ArchSize[ian]=<Arch[ian_src].size(),ArchRev[ian_targ].size()>
	vector<vector<revpair> >ArchRev; // ArchRev[ian_targ][n_rev]=pair<ian_src,n_for>
	vector<double>Pi; //Pi[ian]=begin->ian transition score
	vector<double>Ep; //Ep[ian]=ian->end transition score
	vector<vector<double> >A,C; //A[ian][ian] and C[ien][c] convenience vars
	vector<proftriple>P; //P[ien].H[ev] etc
	vector<vector<double> >EmitAmino; //EmitAmino[ien][c]=double
	vector<proftriple>EmitProf; //EmitProf[ian].H[ev] etc.
	vector<vector<mat> >trel; //trel[t][i]=double

	static vector<gproftriple> EmitProfG; //EmitProfG[ev].H.E .H.nonE, etc etc
	static map<uint,set<uint> >Connect;
	static map<char,uint> AminoMap;        // Aminomap[sam]=iam;
	static map<uint,char> AminoMapRev; //AminoMapRev[iam]=sam;
	static vector<uint>A2E; //A2E[ian]=ien;
	static map<string,uint>SLNmap,SANmap,SENmap; //SLNmap[sln]=iln
	static map<uint,string>SLNrev,SANrev,SENrev; //SLNrev[iln]=sln
	static map<string,string>L2Lmap; //L2Lmap[sln_old]=sln_new
	static vector<vector<bool> >LA; //LA[iln][ian]=bool
	static vector<bool>TwoState; //TwoState[ian]=betaQ
	static vector<int>ReduxDecode,ReduxEval; //ReduxDecode[ian]=istate
	static vector<string>StatesDecode,StatesEval; //StatesDecode[istate]=sstate
	static uint NDecode,NEval; //Number of decode and eval states
	static map<string,int>RevEval; //RevEval[sstate]=istate
	static uint NumE,NumA,NumL;
	static uint NGProf; //number of Prof events globally
	static uint NLProf; //number of Prof events locally
	static vector<double>ProfMult;      // ProfMult[ind]=multiplier
	static uint NUMAMINO;
	static vector<double>AAComp; //AAComp[c]=double (counts)
	static vector<pair<double,double> >Zcurve; //Z-score (mean,sd) points at integral values
	static double Slope,Intercept;
	static void Clear();
/* 	static void Init(char*,char*,char*,char*,char*,const char*); */
	static void Init(char*,char*,char*,char*,char*,char*,
					 const char*);
/* 	static void Init(char*,char*,char*,char*,char*,char*, */
/* 					 char*,double*,uint,uint,const char*); */
	static void Init(const char*);
	static void PrintZCurve(vector<pair<double,double> >&,char *);
	static void ReadZCurve(char *) throw (string &);
};

#endif
