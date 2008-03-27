#ifndef _Structs
#define _Structs

#include <string>
#include <vector>
#include <iostream>

typedef unsigned int uint;

using namespace std;

struct names {
	uint iln,ian,ien;
	string sln,san;
	char cln[2];
	bool betaQ;
	friend ostream& operator<<(ostream&,names&);
	names(){}
	names(uint l,uint a,uint e,string sln,string san,bool b):
		iln(l),ian(a),ien(e),sln(sln),san(san),betaQ(b){
		cln[0]=sln[0];
		cln[1]=sln[1];
	}
};


struct tarsrcpair { //used for ArchSize
	uint ntar,nsrc;
	tarsrcpair(uint t,uint s):ntar(t),nsrc(s){}
	tarsrcpair():ntar(0),nsrc(0){}
};

struct archpair { //used for Arch
	uint node;
	double score;
	archpair(uint n,double s):node(n),score(s){}
};

struct revpair { //used for ArchRev
	uint src,index;
	revpair(uint s,uint i):src(s),index(i){}
};


struct proftriple { //used for EmitProf
	vector<double> H,E,L;
};

struct gproftriple {
	struct profpair {double E,nonE;};
	profpair H,E,L;
};

class evaldat {
 public:
	string cl,id,cd; //class, id, classdesc
	int cdct; //cd counts (number of proteins in this class
	bool posQ;
	uint length;
	double pbits,zscore,evalscore; //evalscore used by scocov and acccov
	friend ostream& operator<<(ostream&,evaldat&);
	evaldat(string& c,string& i,string& cd,bool p,uint l,
			double pb,double z,double e):
		cl(c),id(i),cd(cd),posQ(p),length(l),
		pbits(pb),zscore(z),evalscore(e){}
};


class triplet {
	string cl;
	double sco,cov;	
 public:
	friend ostream& operator<<(ostream&,triplet&);
	triplet(string,double,double);
};


struct scpair {
	double sco,cov;
	scpair(double s,double c):sco(s),cov(c){}
};


struct roc {
	double tpf,fpf,tpf_sd;
	double sco;
	roc(double tpf=0.0,double fpf=0.0,double tpf_sd=0.0,
		double sco=0) :
		tpf(tpf),fpf(fpf),tpf_sd(tpf_sd),sco(sco){}
};


struct Stats{
	double P,O,U,N;
	Stats():P(0.0),O(0.0),U(0.0),N(0.0){}
};

#endif
