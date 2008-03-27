#ifndef _SEQ
#define _SEQ

#include "structs.h" //for small structures like proftriple
#include <cmath>
#include <vector>
#include <map>
#include <string>
#include <set>
#include <fstream>

using namespace std;

class Par; //Forward declaration


struct vec {
	uint iln,iaa,lH,lE,lL,gH,gE,gL; //local and global prof
	uint act_ian,pred_ian; //actual istate
	char cpn[2],cln[2];
	double fbs; 
	double b,c,n,C_log,D_log,N_path_log;
	uint N_ext;
	bool predbeta_atomQ,predbetaQ,actbetaQ;
	//c(t)=auxiliary scale factor =sum_i(alpha_auxiliary(i,t))
	//C=forward scale factor =c(0)*c(1)*...*c(t)
	//D=backward scale factor = c(T-1)*c(T-2)*...*c(t)
	//labeled state signature
	//forward-backward-sum, an intermediate variable used in the calculation
	//N_path_log=log of # paths

	void init_vec(){
		fbs=b=c=n=0.0;
		C_log=D_log=N_path_log=-HUGE_VAL;
		N_ext=0;
	}
	vec():fbs(0),b(0),c(0),n(0),C_log(-HUGE_VAL),
		 D_log(-HUGE_VAL),N_path_log(-HUGE_VAL),N_ext(0){}
	//warning: calling vec() seems to initialize other things
	//like actbetaQ that we don't want initialized
};


class Seq {
 public:
	static struct labels {string id,at,mo,sq,ts,pr,H,E,L;} lb;
	struct SeqData {
		uint Seqlen;
		string SeqID,AASeq,Set,ClassDesc,ReducedDesc; //dataset the sequence is from
		double P_log,RV_log,P_log_ave,P_scl,C_log,P_log_vp,
			P_log_ap,P_scl_h,Z_log,S,Pnorm_log,null_log,
			Pbits,Score,RVbits,N_path_log,evalue,pvalue;
		//Pbits=P_log - null_log
		//RVbits=RV_log - null_log
		//ap 'all path' vp, 'valid path'
		//S is sum of profile column
		//RVbits is the reduced viterbi bits score = 
		bool posQ; //true if this sequence is in the positive set
		bool labelQ; //true if sequence has labelling
		int npredstrands;//number of predicted beta-strands for this
		//sequence
	} scl;

	vector<vec>row;
	vector<vector<float> >Profile; //Profile[t][c]=double
	vector<vector<int> >CTable; //CTable[pred][act]=count
	static bool CheckDat(multimap<string,string>&,string) throw (string&);
	static bool CheckProfile(multimap<string,string>&,uint);
	//void IncrAtom(double (*) (uint,uint));
	void InitProfile(multimap<string,string>&,uint);
	void InitProfile(const char*);

	void LogViterbi(Par&);
	void LogViterbiMulti(Par&);
	void Traceback(Par&);
	void Decode(Par&);
	void TallyStates(uint,Par&);
	void CalcCTable(Par&);

	static struct ext {
		enum {A,P,AGProf,ALProf,PGProf,PLProf,Null}; //these are hard-coded names to correspond with
		//functions ReturnA, ReturnP, etc. in class Seq
	} func;
	Seq();
	Seq(const char*,const char*);
	Seq(multimap<string,string>&,string,
		set<string>&,map<string,string>&);
	double (Seq::*pReturn)(uint,uint,Par&); //decides which return function to be used
	double ReturnA(uint,uint,Par&);
	double ReturnP(uint,uint,Par&);

	static void InitSeq();
	static map<string,multimap<string,string> > Read(char*);
	static pair<string,multimap<string,string> > ReadOne(ifstream&);
};

#endif
