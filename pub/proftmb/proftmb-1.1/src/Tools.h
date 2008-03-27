#ifndef _TOOLS
#define _TOOLS

#include <iostream>
#include <cstdlib>
#include <string>
typedef unsigned int uint;

using namespace std;

namespace Tools {

	double DotP(double *,double *,int);
	double DotP(float *,float *,int);
	double DotP(float *,double *,int);
	double DotP(double *,float *,int);
	double DotPWarn(double *,double *,int);
	void Normalize(double *,int);
	void Normalize(float *,int);
	void NormalizeWarn(double *,int);
	void NormalizeWarn(float *,int);
	bool BoolNormalize(double *,int);
	bool BoolNormalize(float *,int);
	void PseudoNormalize(double *,int);
	void PseudoNormalize(float *,int);
	void AddPrior(double*,double*,double,int);
	double Average(double*,int);
	string GetUntil(istream&,char*);
	string GetUntilNot(istream&,char*);
	bool PutString(istream&,char*,uint s=0);
	template<class A>
		void Error(const A p1){
		cerr<<p1<<endl;
		exit(53);
	}
	template<class A,class B>
		void Error(const A p1,const B p2){
		cerr<<p1<<' '<<p2<<endl;
		exit(53);
	}
	template<class A,class B,class C>
		void Error(const A p1,const B p2,const C p3){
		cerr<<p1<<' '<<p2<<' '<<p3<<endl;
		exit(53);
	}
	template<class A,class B,class C,class D>
		void Error(const A p1,const B p2,const C p3,
				   const D p4){
		cerr<<p1<<' '<<p2<<' '<<p3<<' '<<p4<<endl;
		exit(53);
	}
	template<class A,class B,class C,class D,class E>
		void Error(const A p1,const B p2,const C p3,
				   const D p4,const E p5){
		cerr<<p1<<' '<<p2<<' '<<p3<<' '<<p4<<' '<<p5<<endl;
		exit(53);
	}
	template<class A,class B,class C,class D,class E,class F>
		void Error(const A p1,const B p2,const C p3,
				   const D p4,const E p5,const F p6){
		cerr<<p1<<' '<<p2<<' '<<p3<<' '<<p4<<' '<<p5<<' '<<p6<<endl;
		exit(53);
	}


	char* PrefixDir(const char*,const char*,char*);

}


using namespace Tools;

#endif
