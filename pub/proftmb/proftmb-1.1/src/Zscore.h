#include <vector>
#include <utility>
#include <set>
#include <string>

vector<pair<double,double> >
Z_Calibrate(set<pair<int,double> >&,int,double) throw (string&);


set<pair<double,pair<double,double> > >
ComputeStats(vector<int>&, vector<double>&,int);


vector<pair<double,double> >
InterpolateValues(const set<pair<double,pair<double,double> > >&);

bool DiscardOutliers(vector<int>&, vector<double>&,
					 vector<pair<double,double> >&,double);

double CalcZScore(vector<pair<double,double> >&,int,double);
