//evaluation functions for 2-state statistics.
//Q2, MCC, sov(beta)

#include "structs.h"
#include <vector>
#include <utility>
#include <iostream>
#include <string>
#include <map>

using namespace std;


double Q2(Stats&);
double MCC(Stats&);
double MCC(vector<vector<int> >&,int);
double Qnon(Stats&);
double Qbeta(Stats&);
double Qbetapred(Stats&);
double Qbetaobs(Stats&);
double Qpctpred(vector<vector<int> >&,int);
double Qpctobs(vector<vector<int> >&,int);
double Q(vector<vector<int> >&);
vector<roc>ROCnCurve(vector<int>&,int);
/* double ROCn(vector<evaldat>&,uint n=0); */
/* double ROCn(vector<evaldat>&,uint n,double& sd); */
vector<int> ROCRaw(vector<evaldat>&,uint);
vector<int> ROCRaw(vector<evaldat*>&,uint);
vector<roc> ROCResample(vector<evaldat>&,double&,double&,double&,int);
template<class A> vector<A> Resample(vector<A>&,int);
double GigiIndex(double,uint);
void PrintHisto(char*,vector<double>&,int);
map<string,vector<pair<double,double> > > ScoCov(vector<evaldat>&);
vector<pair<string,vector<double> > >AccCov(vector<evaldat>&,bool dQ=false);
map<string,map<int,int> >CoverageTable(vector<pair<double,string> >&);
