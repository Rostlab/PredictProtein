#ifndef _Output
#define _Output

#include <iostream>
#include <fstream>
#include <vector>
#include <string>
#include <map>
#include <utility>

void PrintResults(ostream&,double,double,double,double,
				  double,double,double,double);
void PrintKaleida(const char*,map<string,vector<pair<double,double> > >&,
				  char*,char*);
void PrintKaleida(const char*,vector<pair<string,vector<double> > >&);
void PrintGnuplot(const char*,map<string,vector<pair<double,double> > >&,
				  char*,char*,char*);
void PrintGnuplot(const char*,vector<pair<string,vector<double> > >&,const char*);
void PrintTable(vector<vector<int> >&,vector<string>&,ofstream&);
void PrintTable(map<string,map<int,int> >&,char *);
multimap<uint,string> SortMap(map<string,vector<pair<double,double> > >&);
multimap<uint,string,greater<uint> > SortMapRev(map<string,vector<pair<double,double> > >&);

template<typename M,typename N> void PrintMap(ostream& of,map<M,N>& m){
	map<M,N>::iterator it;
	for (it=m.begin();it!=m.end();it++){
		of<<it->first<<'\t'<<it->second<<endl;
	}
}
//a workaround to the template instantiation problem: put
//the full definition in the header file
//this solution only works for templates where the entire
//code resides in one compilation unit


#endif
