#include "Tools.h"
#include <cassert>
#include <cmath>

using namespace std;

namespace Tools{

double DotP(double *vec1,double *vec2,int size) {
	double dotp=0.0;
	int i;
	for (i=0;i<size;i++) dotp+=vec1[i]*vec2[i];
	return dotp;
}


double DotP(float *vec1,double *vec2,int size) {
	double dotp=0.0;
	int i;
	for (i=0;i<size;i++) dotp+=vec1[i]*vec2[i];
	return dotp;
}


double DotP(double *vec1,float *vec2,int size) {
	double dotp=0.0;
	int i;
	for (i=0;i<size;i++) dotp+=vec1[i]*vec2[i];
	return dotp;
}


double DotP(float *vec1,float *vec2,int size) {
	double dotp=0.0;
	int i;
	for (i=0;i<size;i++) dotp+=vec1[i]*vec2[i];
	return dotp;
}



double DotPWarn(double *vec1,double *vec2,int size) {
	double dotp=0.0;
	int i;
	for (i=0;i<size;i++) dotp+=vec1[i]*vec2[i];
	if (dotp==0.0) {
		cout<<"dotp="<<dotp<<endl;
		for (i=0;i<size;i++) cout<<vec1[i]<<' ';
		cout<<endl;
		for (i=0;i<size;i++) cout<<vec2[i]<<' ';
		cout<<endl<<endl;
	}

	assert(dotp!=0.0);
	assert(!isnan(dotp));
	return dotp;
}

// void Error(const char* p1, const char* p2,const char* p3,
// 		   const char* p4, const char* p5,const char* p6){
// 	cerr<<p1<<' '<<p2<<' '<<p3<<' '<<p4<<' '<<p5<<' '<<p6<<endl;
// 	exit(0);
// }

void Normalize(double *vec,int size) {
	double sum=0;
	int i;
	for (i=0;i<size;i++) sum+=vec[i];
	assert(sum!=0);
	char p[]="Normalize: sum of distribution is zero\n";
	if (sum!=0) 
		for (i=0;i<size;i++) vec[i]/=sum;
	else Error(p);
}

void Normalize(float *vec,int size) {
	float sum=0;
	int i;
	for (i=0;i<size;i++) sum+=vec[i];
	assert(sum!=0);
	if (sum!=0) 
		for (i=0;i<size;i++) vec[i]/=sum;
	else Error("Normalize: sum of distribution is zero\n");
}


void NormalizeWarn(double *vec,int size) {
	double sum=0;
	int i;
	for (i=0;i<size;i++) sum+=vec[i];
	if (sum<50) cout<<"NormalizeWarn: sum="<<sum<<endl;
	for (i=0;i<size;i++){
		vec[i]/=sum;
		//assert(vec[i]>0.0000001 or vec[i]==0.0);
	}
}


void PseudoNormalize(double *vec,int size) {
	double sum=0;
	int i;
	for (i=0;i<size;i++) sum+=vec[i];
	if (sum!=0) for (i=0;i<size;i++) vec[i]/=sum;
	else cerr<<"PseudoNormalize: sum==0"<<endl;
}


void PseudoNormalize(float *vec,int size) {
	float sum=0;
	int i;
	for (i=0;i<size;i++) sum+=vec[i];
	if (sum!=0) for (i=0;i<size;i++) vec[i]/=sum;
	else cerr<<"PseudoNormalize: sum==0"<<endl;
}


bool BoolNormalize(double *vec,int size) {
	double sum=0;
	int i;
	for (i=0;i<size;i++) sum+=vec[i];
	if (sum!=0) {
		for (i=0;i<size;i++) vec[i]/=sum;
		return true;
	}
	else return false;
}


bool BoolNormalize(float *vec,int size) {
	float sum=0;
	int i;
	for (i=0;i<size;i++) sum+=vec[i];
	if (sum!=0) {
		for (i=0;i<size;i++) vec[i]/=sum;
		return true;
	}
	else return false;
}


void AddPrior(double *vec,double *pri,double mult,int max) {
	double sumvec=0,sumpri=0;
	int i;
	for (i=0;i<max;i++) {
		sumvec+=vec[i];
		sumpri+=pri[i];
	}
	for (i=0;i<max;i++) vec[i]+=pri[i]*mult;
}

double Average(double *vec,int max) {
	double ave=0;
	for (int i=0;i<max;i++) ave+=vec[i];
	ave/=(double)max;
	return ave;
}


string GetUntil(istream& is,char* delims){
	//continues reading from an open istream, advancing
	//the position beyond the first encountered
	//char in the char array delims
	if (is.eof()) Error("GetUntil: encountered eof\n");
	bool delimQ=false;
	string line;
	char ch=0;
	char* pd;
	while (1){
		ch=is.peek();
		for (pd=delims;*pd!=0;pd++) if (ch==*pd) delimQ=true;
		if (delimQ) break;
		line+=ch;
		is.get();
	}
	return line;
}


string GetUntilNot(istream& is,char* valids){
	//continues reading from an open istream, leaving
	//position between last valid and first invalid
	if (is.eof()) Error("GetUntil: encountered eof\n");
	bool validQ=true;
	string line;
	char ch=0;
	char* pd;
	while (1){
		ch=is.peek();
		validQ=false;
		for (pd=valids;*pd!=0;pd++) if (*pd==ch) validQ=true;
		if (!validQ) break;
		line+=ch;
		is.get();
	}
	return line;
}


bool PutString(istream& is,char* st,uint size){
	//puts back a whole string into an open istream
	//if size is nonzero, assumes st is zero-terminated,
	//and sets cur_st to the end of it	
	char* cur_st=st;
	if (size!=0) cur_st=st+size-1;
	else {
		while (*cur_st!=0) cur_st++;
		cur_st--; //we want it to point to the first non-null char
	}

	if (!is.good()) return false;
	for (;cur_st>=st;cur_st--) is.putback(*cur_st);
	return true;
}

char* PrefixDir(const char* root,const char* rel,char* full){
	//takes a rootpath (/home/bigelow/modnet/conf)
	//prepends it to the relpath (gen/ae)
	//and returns a pointer to the result:
	//(/home/bigelow/modnet/conf/gen/ae)
	//find the end,add a backslash if appropriate
	full[0]=0;
	strcpy(full,root);
	strcat(full,"/");
	strcat(full,rel);
	return full;
}


}
