#include <cmath>
#include <cstdlib>
#include <algorithm>
#include "Eval.h"
#include "Tools.h"
#include "Sov.h"
#include "gsl/gsl_statistics_double.h"

//evaluation functions for hmm's, taking the sequences as arguments



double Q2(Stats& cts){
	double q2;
	q2=(cts.P+cts.N)/(cts.P+cts.O+cts.U+cts.N);
	return q2;
}


double MCC(Stats& C){
	double sum,diags,sides,mcc;
	sum=C.P+C.O+C.U+C.N;
	diags=(C.P*C.N)-(C.O*C.U);
	sides=(C.P+C.U)*(C.P+C.O)*(C.N+C.U)*(C.N+C.O);
	if (sum==0.0) {
		mcc=0.0;
		cerr<<"MCC: sum equals zero"<<endl;
	}
	else if (diags==0.0) mcc=0.0;
	else mcc=diags/sqrt(sides);
	return mcc;
}


double MCC(vector<vector<int> >& ctab,int pind){
	//calculates the MCC collapsing the ctable
	//my merging all other categories other than pind
	int Size=(int)ctab.size();
	int row,col;
	double P=0.0,O=0.0,U=0.0,N=0.0,diags,sides,sum,mcc;
	for (row=0;row<Size;row++)
		for (col=0;col<Size;col++){
			if (row==pind && col==pind) P=ctab[row][col];
			else if (row==pind && col!=pind) O+=ctab[row][col];
			else if (row!=pind && col==pind) U+=ctab[row][col];
			else N+=ctab[row][col];
		}

	sum=P+O+U+N;
	diags=(P*N)-(O*U);
	sides=(P+U)*(P+O)*(N+U)*(N+O);
	if (sum==0.0) {
		mcc=0.0;
		cerr<<"MCC: sum equals zero"<<endl;
	}
	else if (diags==0.0) mcc=0.0;
	else mcc=diags/sqrt(sides);
	return mcc;

}



double Qpctpred(vector<vector<int> >& ctab,int row){
	//merges all categories in inds
	//returns the percent of rows {inds} which are also
	//columns {inds}
	double num=0.0,den=0.0; //numerator, denominator
	uint col;
	num=ctab[row][row];
	for (col=0;col<ctab.size();col++)
		den+=ctab[row][col];

	return num/den;
}


double Qpctobs(vector<vector<int> >& ctab,int col){
	//merges all categories in inds
	//returns the percent of rows {inds} which are also
	//columns {inds}
	double num=0.0,den=0.0; //numerator, denominator
	uint row;
	num=ctab[col][col];
	for (row=0;row<ctab.size();row++)
		den+=ctab[row][col];

	return num/den;
}


double Q(vector<vector<int> >& ctab){
	//compute QN (N=ctab.size()) of a contingency table
	double num=0.0,den=0.0;
	uint row,col;
	for (row=0;row<ctab.size();row++){
		for (col=0;col<ctab.size();col++){
			if (row==col) num+=ctab[row][col]; //diagonal cell
			den+=ctab[row][col];
		}
	}
	return num/den;
}




double Qnon(Stats& cts){return (double)cts.N/(cts.N+cts.O);}
double Qbeta(Stats& cts){return (double)cts.P/(cts.P+cts.U);}

double Qbetapred(Stats& cts){return (double)cts.P/(cts.P+cts.O);}
double Qbetaobs(Stats& cts){return (double)cts.P/(cts.P+cts.U);}

int more_eval(const void* arg1,const void* arg2){
	//compares two evaldat structures based on their
	//evalscore field
	double sco1=(*(evaldat**)arg1)->evalscore;
	double sco2=(*(evaldat**)arg2)->evalscore;
	if (sco1<sco2) return -1;
	else if (sco1 == sco2) return 0;
	else return 1;
}


int less_eval(const void* arg1,const void* arg2){
	//compares two evaldat structures based on their
	//evalscore field
	double sco1=((evaldat*)arg1)->evalscore;
	double sco2=((evaldat*)arg2)->evalscore;
	if (sco1>sco2) return -1;
	else if (sco1 == sco2) return 0;
	else return 1;
}


int less_evalp(const void* arg1,const void* arg2){
	//compares two evaldat structures based on their
	//evalscore field
	double sco1=(*(evaldat**)arg1)->evalscore;
	double sco2=(*(evaldat**)arg2)->evalscore;
	if (sco1>sco2) return -1;
	else if (sco1 == sco2) return 0;
	else return 1;
}


int more_double(const void* arg1,const void* arg2){
	double sco1=*(double*)arg1;
	double sco2=*(double*)arg2;
	if (sco1<sco2) return -1;
	else if (sco1 == sco2) return 0;
	else return 1;
}	

int less_double(const void* arg1,const void* arg2){
	double sco1=*(double*)arg1;
	double sco2=*(double*)arg2;
	if (sco1>sco2) return -1;
	else if (sco1 == sco2) return 0;
	else return 1;
}	


double ROCarea(vector<int>& tvf,int T){
	//calculates the area under a ROC curve,
	//normalized to 1.  assumes tvf is sorted so that
	//the highest score is last
	int F=tvf.size(),sum=0,ind;
	double area;
	for (ind=0;ind<F;ind++) sum+=tvf[ind];
	area=(double)sum/(double)(T*F);
	return area;
}
	

vector<roc> ROCnCurve(vector<int>&raw,int T){
	//merely converts the raw into a real roc curve
	//assumes raw is sorted ascending in .first
	int F=raw.size();
	vector<roc> curve(F);
	for (int i=0;i<F;i++)
		curve[i]=roc((double)raw[i]/(double)T,
						   (double)i/(double)F);
	return curve;
}


vector<int> ROCRaw(vector<evaldat>&sco,uint n){
	vector<evaldat*>psco(sco.size());
	for (int i=0;i<(int)sco.size();i++) psco[i]=&sco[i];
	return ROCRaw(psco,n);
}


vector<int> ROCRaw(vector<evaldat*>&sco,uint n){
	/*
	  Truncated RocRaw curve
	  In the following, 'the data' means the entire set
	  of data, falling in two classes, 'true positives'
	  and 'false positives'.  the variable 'sco' represents
	  the entire set of data.  This is a bit misleading since
	  in other derivations of ROC, the terms 'true positives'
	  and 'false positives' are relative to a moving cutoff
	  Here, the cutoff is implicit in the ranking 'i'

	  computes Altschul's formula: (1/nT) sum_i,(1..n)[t_i]
	  n=number of false positives looked at
	  T=total number of true positives in all data
	  t_i, number of true positives ranked ahead
	  of the ith false positive
	*/
	

	qsort(&sco[0],sco.size(),sizeof(sco[0]),less_evalp);

	//calculate T and F, error check
	uint ind,T=0,F;
	for (ind=0;ind<sco.size();ind++) if (sco[ind]->posQ) T++;
	F=(uint)sco.size()-T;
	if (n==0) n=F; //meaning of default value
	vector<int>t(n);

	if (n>F) {
		//cerr<<"ROCn: Warning: n is greater than F.  using n=F";
		n=F;
	}
	if (T==0) {
		cerr<<"ROCn: warning: no true positives found.\n";
		return t;
	}
	//increment if true positive is found

	//calculate t_i for each i
	uint ntrue=0,i;
	ind=0;
	for (i=0;i<n;i++){
		while (sco[ind]->posQ) { //current record is a true pos
			ntrue++;
			ind++;
		}
		t[i]=ntrue;
		ind++; //increment ind
	}

	return t;
}


template<class A> vector<A> Resample(vector<A>& dat,int N){
	//generates a vector<A> of N resamplings from dat
	vector<A>resam(N);
	int pick;
	for (uint i=0;i<dat.size();i++){
		pick=(int)floor(((double)rand()-1/(double)RAND_MAX)*dat.size());
		resam[i]=dat[pick];
	}
	return resam;
}


vector<roc> ROCResample (vector<evaldat>& wdat,double& ROC_orig,
					   double& ROC_mean,double& ROC_sd,int S){
	//resample with replacement from wdat S times,
	//generating a ROCn curve and ROCn score for each resampling,
	//returning the roc curve and score with sd for each point
	//use n=2*T, T=# of positives in resample
	vector<vector<int> >tvf_sam_fp(S);
	//vector<vector<double> >roc_fp_sam(n); //tp collections each of S points
	vector<double>rocdist(S);
	vector<int>T(S);

	//sam=sampling number, tp=# true positives,fp=# false positives
	//tvf_fp_sam[fp][sam]=tp
	//tvf_sam_fp[sam][fp]=tp
	//curve_sd[fp]=sd, tp_sd=tp std. deviation, calculated from 
	//rocdist[sam]=ROC, ROC is ROC score for particular curve
	//ROC_sd, std. deviation of roc scores
	
	//for each of S samplings, compile rocraw, store in tvf*
	//sam is the sampling run number, inum is the index number
	int sam,inum,I=wdat.size();
	vector<int>indices(I); //a vector holding the indices
	vector<evaldat*>psam(I);
	int pick;

	//create S roc curves
	for (sam=0;sam<S;sam++){
		T[sam]=0;
		for (inum=0;inum<I;inum++) {
			pick=(int)floor(((double)(rand()-1)/(double)RAND_MAX) * I);
			psam[inum]=&wdat[pick];
			if (psam[inum]->posQ) T[sam]++;
		}
		tvf_sam_fp[sam]=ROCRaw(psam,T[sam]*2); //here we use n=2 * T
		rocdist[sam]=ROCarea(tvf_sam_fp[sam],T[sam]);
	}

	//compute sd of S ROC scores
	ROC_sd=gsl_stats_sd(&rocdist[0],1,S);
	ROC_mean=gsl_stats_mean(&rocdist[0],1,S);
	//create tvf_fp_sam for easy tallying of curve_sd

// 	for (fp=0;fp<n;fp++) roc_fp_sam[fp].resize(S);
// 	for (sam=0;sam<S;sam++){
// 		//if n is the same, shouldn't T also be the same?
// 		T=tvf_sam_fp[sam][n-1]; //these are all sorted ascending
// 		for (fp=0;fp<n;fp++)
// 			roc_fp_sam[fp][sam]=(double)(tvf_sam_fp[sam][fp]+1)/(double)T;
// 	}

// 	//compute sd's of each fp in the curve
// 	for (fp=0;fp<n;fp++)
// 		curve_sd[fp]=gsl_stats_sd(&roc_fp_sam[fp][0],1,n);
	
	//calculate original ROC curve
	int T_orig=0;
	for (inum=0;inum<I;inum++) if (wdat[inum].posQ) T_orig++;
	vector<int>orig_raw=ROCRaw(wdat,T_orig*2);
	ROC_orig=ROCarea(orig_raw,T_orig);


	vector<roc>orig_curve=ROCnCurve(orig_raw,T_orig);

	return orig_curve;
}

		
double GigiIndex(double raw,uint len){
	double adj=raw-(20.0/2000.0)*(double)len;
 	cout<<"GigiIndex: raw="<<raw<<", len="<<len
 		<<", returning"<<adj<<endl;
	return adj;
}


map<string,vector<pair<double,double> > > ScoCov(vector<evaldat>& dat){
	//generates score vs. coverage as a vector of points
	//using sco.evalscore as the score

	uint i;
	string label;
	//get counts and scores of every protein in each class
	map<string,vector<double> >scores;
	for (uint i=0;i<dat.size();i++){
		if (scores.find(dat[i].cd)==scores.end())
			scores[dat[i].cd]=vector<double>();
		scores[dat[i].cd].push_back(dat[i].evalscore);
	}
	
	//sort each vector
	map<string,vector<double> >::iterator sit;
	for (sit=scores.begin();sit!=scores.end();sit++){
		label=sit->first;
		qsort(&scores[label][0],scores[label].size(),
			  sizeof(scores[label][0]),less_double); //comparison function?
	}

	//duplicate it in a Hash-of_arrays_of_pairs
	//and compute coverage
	map<string,vector<pair<double,double> > >svc;
	uint numpts;
	for (sit=scores.begin();sit!=scores.end();sit++){
		label=sit->first;
		numpts=scores[label].size();
		svc[label]=vector<pair<double,double> >(numpts);
		for (i=0;i<numpts;i++){
			svc[label][i].first=scores[label][i]; //duplicate first
			//svc[label][i].second=(double)i/(double)numpts; //compute cov
			svc[label][i].second=(double)i;
		}
	}
	return svc;
}


vector<pair<string,vector<double> > >AccCov(vector<evaldat>& dat,bool descendingQ){
	//generates score vs. accuracy and score vs. coverage
	//using sco.evalscore as the score

	//calculate Ptotal
	int ind,Ptotal=0,p=0; //# negative samples, # Positive samples
	for (ind=0;ind<(int)dat.size();ind++) if (dat[ind].posQ) Ptotal++;

	//sort all data by evalscore
	//sort(dat.begin(),dat.end()); //need to provide operator< for this to work
	qsort(&dat[0],dat.size(),sizeof(evaldat),less_eval);
	if (! descendingQ) reverse(dat.begin(),dat.end());

	//create a skeleton data structure
	vector<pair<string,vector<double> > >acccov(4);
	acccov[0]=make_pair(string("Bits"),vector<double>());
	acccov[1]=make_pair(string("Accuracy"),vector<double>());
	acccov[2]=make_pair(string("Bits"),vector<double>());
	acccov[3]=make_pair(string("Coverage"),vector<double>());

	//traverse the sorted data, tallying the output as we go
	for (ind=0;ind<(int)dat.size();ind++){
		if (dat[ind].posQ) p++;
		acccov[0].second.push_back(dat[ind].evalscore);
		acccov[1].second.push_back((double)p/(double)(ind+1));
		acccov[2].second.push_back(dat[ind].evalscore);
		acccov[3].second.push_back((double)p/(double)Ptotal);
	}

	return acccov;
}


int MoreFirst(const void *p1,const void *p2){
	//compares two pair<double,string>'s by their .first
	//member
	pair<double,string> *pd1=(pair<double,string> *)p1;
	pair<double,string> *pd2=(pair<double,string> *)p2;
	if (pd1->first > pd2->first) return 1;
	else if (pd1->first == pd2->first) return 0;
	else return -1;
}


map<string,map<int,int> >CoverageTable(vector<pair<double,string> >&pdat){
	//produces a coverage table, rows labelled by pdat[i].second,
	//columns labelled by integer cutoff.  the entries in the table
	//are number of entries in pdat with score above the cutoff
	//in the column in their category

	int size=(int)pdat.size(),ind,col;
	
	string curcat;
	map<string,map<int,int> >table; //table to be returned

	qsort(&pdat[0],size,sizeof(pair<double,string>),&MoreFirst);
	//descending sort
	int min=(int)floor(pdat[0].first);
	int max=(int)floor(pdat[size-1].first);
	cout<<"min="<<min<<", max="<<max<<endl;
	for (ind=0;ind<size;ind++){
		curcat=pdat[ind].second;
				
		if (table.find(curcat)==table.end()){
			table[curcat]=map<int,int>();
			for (ind=min;ind<=max;ind++) {
				table[curcat][ind]=0;
				table["Total"][ind]=0;
			}
		}
		for (col=min;(double)col<pdat[ind].first;col++) {
			table[curcat][col]++;
			table["Total"][col]++;
		}
	}

	return table;
}
