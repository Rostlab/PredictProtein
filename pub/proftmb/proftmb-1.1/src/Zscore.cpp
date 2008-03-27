//calculate Z-scores using:

//Krogh, Brown, Mian, Sjolander, Haussler, 1994
//JMB 235:1501-1531

//Algorithm pseudocode:
//1.  Given a set of points Raw(length, score), calculate for each
//minimum length window containing at least 500 proteins, average
//length, average score, and SD of score. Stats(ave_length,ave_score,
//sd_score).
//2.  using linear interpolation, calculate the mean and sd of 
//each integral length based on points StatsIntegral(int_length,ave_score,
//sd_score).
//3.  using linear regression (least squares?) calculate mean and sd
//of each integral length less than the minimum ave_length in Stats
//or greater than the maximum length in Stats
//4.  Calculate all Z-scores of points in Raw as (score-ave_score)/sd_score
//5.  remove from Raw, all points having a z-score > 2 or < -2
//6.  repeat 1-5 until no more outliers are found in 5.

//Data:  set<int,float>Raw, set<triplet>Stats,
//vector<pair<float,float> >IntStats
//l_min,
#include "Zscore.h"
#include <gsl/gsl_errno.h>
#include <gsl/gsl_spline.h>
#include <gsl/gsl_fit.h>
#include <gsl/gsl_statistics_double.h>
#include <gsl/gsl_statistics_int.h>
#include <sstream>

vector<pair<double,double> > Z_Calibrate(set<pair<int,double> >& Raw,
			int windowsize,double zmax) throw (string&){

	ostringstream errs;
	
	//copy all x's and y's of Raw into raw_x and raw_y
	vector<int>raw_x;
	vector<double>raw_y;
	set<pair<int,double> >::iterator cur_rit;
	for (cur_rit=Raw.begin();cur_rit!=Raw.end();cur_rit++){
		raw_x.push_back(cur_rit->first);
		raw_y.push_back(cur_rit->second);
	}
	
	if ((int)raw_x.size()<windowsize + 1) {
		errs<<"Z_Calibrate: "<<raw_x.size()
			<<" samples is too few to estimate Z-scores."
			<<" Need at least "<<windowsize<<endl;
		throw errs.str();
	}

	set<pair<double,pair<double,double> > >stats;

	vector<pair<double,double> >integral_stats;
	while (1){ //loop broken when no outliers found
		//in these, the order of lengths in raw_x are
		//supposed to by ascending, and where tied,
		//ascending in raw_y

		//compute (mean_x,mean_y,sd) from raw values
		stats=ComputeStats(raw_x,raw_y,windowsize);
		cout<<"Min stats: "<<stats.begin()->first
			<<", Max stats: "<<(--stats.end())->first<<endl;

		//compute integral_stats within ranges covered in the windows
		integral_stats=InterpolateValues(stats);

		//discard outliers from raw_x and raw_y.  returns false if no outliers found
		if (! DiscardOutliers(raw_x,raw_y,integral_stats,zmax)) break;
	}
	return integral_stats;
}


									  
set<pair<double,pair<double,double> > >
ComputeStats(vector<int>& raw_x,vector<double>& raw_y,int windowsize){
	//compile statistics (mean_x,mean_y,sd) for all windows
	int ind_lo,ind_hi,prev_lo; //indices defining window boundary
	int cur_lo,cur_hi;
	int numpoints=(int)raw_x.size();
	int lastind=numpoints-1;
	double mean_x,mean_y,sd;
	set<pair<double,pair<double,double> > >stats;

	//find initial ind_lo and ind_hi
	ind_lo=0;
	prev_lo=raw_x[ind_lo]; //part of initialization of loop
	ind_hi=ind_lo+windowsize;
	cur_hi=raw_x[ind_hi];
	while (ind_hi<numpoints && raw_x[ind_hi]==cur_hi) ind_hi++;
	ind_hi--;

 	//do linear regression on the first window
 	double c0_min[1], c1_min[1],junk[4];
	vector<double>raw_xd(raw_x.size());
	for (int ind=0;ind<numpoints;ind++) raw_xd[ind]=(double)raw_x[ind];

  	gsl_fit_linear (&raw_xd[ind_lo],1,&raw_y[ind_lo],1,ind_hi-ind_lo+1,c0_min,c1_min,
  					&junk[0],&junk[1],&junk[2],&junk[3]);


	//compute statistics for window and find new one.
	while (1){ //break when we run out of windows
 		mean_x=gsl_stats_int_mean(&raw_x[ind_lo],1,ind_hi-ind_lo+1);
 		mean_y=gsl_stats_mean(&raw_y[ind_lo],1,ind_hi-ind_lo+1);
 		sd=gsl_stats_sd(&raw_y[ind_lo],1,ind_hi-ind_lo+1);
		stats.insert(make_pair(mean_x,make_pair(mean_y,sd)));

		while (raw_x[ind_lo]==prev_lo) ind_lo++; //find new ind_lo
		prev_lo=raw_x[ind_lo];
		ind_hi=ind_lo+windowsize;
		if (ind_hi>numpoints) break; //we are done with windows
		cur_hi=raw_x[ind_hi];
		while (ind_hi<numpoints && raw_x[ind_hi]==cur_hi) ind_hi++;
		ind_hi--;
	}

	//find final ind_lo and ind_hi
	ind_lo=lastind-windowsize;
	cur_lo=raw_x[ind_lo];
	while (ind_lo>0 && raw_x[ind_lo]==cur_lo) ind_lo--;
	ind_lo++;

	//do linear regression on the last window
	double c0_max[1], c1_max[1];
	gsl_fit_linear (&raw_xd[ind_lo],1,&raw_y[ind_lo],1,lastind-ind_lo+1,c0_max,c1_max,
					&junk[0],&junk[1],&junk[2],&junk[3]);



	//but add one regression point at the max
	
	//add mean_y according to linear regression line, but take
	//sd from closest point (raw_x[0]);
	cur_lo=raw_x[0];
	mean_y=*c0_min+(*c1_min * cur_lo); //linear regression line
	sd=stats.begin()->second.second; //just take the sd from the shortest stat
	stats.insert(make_pair((double)cur_lo,make_pair(mean_y,sd)));

	//what is max_length
	int max_length=raw_x[lastind];
	mean_y=*c0_max+(*c1_max * max_length);
	sd=(--stats.end())->second.second;
	stats.insert(make_pair((double)max_length,make_pair(mean_y,sd)));
	return stats;
}


vector<pair<double,double> >
InterpolateValues(const set<pair<double,pair<double,double> > >& stats){
	//compute interpolated values (mean_y and sd) at integral x-values
	//(stats is sorted low-to-hi by sit->first) (average length))
	vector<double>stats_len,stats_mean,stats_sd;
	set<pair<double,pair<double,double> > >::iterator sit;
	
	for (sit=stats.begin();sit!=stats.end();sit++){
		stats_len.push_back(sit->first);
		stats_mean.push_back(sit->second.first);
		stats_sd.push_back(sit->second.second);
	}
	int l_min=(int)ceil(stats_len[0]);
	int l_max=(int)floor(stats_len[stats_len.size()-1]);
	vector<pair<double,double> >integral_stats(l_max+1);

 	gsl_interp_accel *acc_mean = gsl_interp_accel_alloc ();
  	gsl_interp_accel *acc_sd = gsl_interp_accel_alloc ();
 	gsl_interp * interp_mean =
 		gsl_interp_alloc (gsl_interp_linear,stats_len.size());
 	gsl_interp * interp_sd =
 		gsl_interp_alloc (gsl_interp_linear,stats_len.size());
 	gsl_interp_init
 		(interp_mean, &stats_len[0], &stats_mean[0], stats_len.size());
 	gsl_interp_init
 		(interp_sd, &stats_len[0], &stats_sd[0], stats_len.size());
 	for (int len=l_min;len<=l_max;len++){
  		integral_stats[len].first=gsl_interp_eval
  			(interp_mean,&stats_len[0],&stats_mean[0],len,acc_mean);
 		integral_stats[len].second=gsl_interp_eval
 			(interp_sd,&stats_len[0],&stats_sd[0],len,acc_sd);
 	}
		
 	gsl_interp_free (interp_mean);
 	gsl_interp_free (interp_sd);
 	gsl_interp_accel_free (acc_mean);
	gsl_interp_accel_free (acc_sd);
	return integral_stats;
}


bool DiscardOutliers(vector<int>& raw_x, vector<double>& raw_y,
					 vector<pair<double,double> >& integral_stats,
					 double zmax){
	//iterates through each point (raw_x,raw_y) and discards it
	//if it is an outlier according to integral_stats and zmax
	//PRESERVES ORDER

	//build a list of outliers
	int ind;
	set<int>exclude;
	double zvalue;
	bool excludeQ=false;
	for (ind=0;ind<(int)raw_x.size();ind++){
		zvalue=(raw_y[ind]-integral_stats[raw_x[ind]].first)/
			integral_stats[raw_x[ind]].second;
		if (fabs(zvalue) > zmax) exclude.insert(ind);
	}

	if (exclude.size()>0) excludeQ=true;

	vector<int>newraw_x;
	vector<double>newraw_y;
	for (ind=0;ind<(int)raw_x.size();ind++){
		if (exclude.find(ind)==exclude.end()){ //not excluded
			newraw_x.push_back(raw_x[ind]);
			newraw_y.push_back(raw_y[ind]);
		}
	}

	set<int>::iterator eit;
	for (eit=exclude.begin();eit!=exclude.end();eit++)
		cout<<"Excluded point with length "<<raw_x[*eit]
			<<" and z-value "
			<<(raw_y[*eit]-integral_stats[raw_x[*eit]].first)/
			integral_stats[raw_x[*eit]].second<<endl;

	raw_x=newraw_x;
	raw_y=newraw_y; //what does this do?


	return excludeQ;
}


double CalcZScore(vector<pair<double,double> >& integral_stats,
				  int length,double raw_score) {
	ostringstream errs;

	if (length>(int)integral_stats.size()-1) {
 		errs<<"protein length: "<<length
			<<", longest protein during z-calibration: "
			<<integral_stats.size()-1;
		cerr<<errs.str()<<endl;
		return -10000.0;
	}
	else if (length<0) {
		errs<<"CalcZScore: Protein has a negative length: "
			<<length;
		cerr<<errs.str()<<endl;
		return -10000.0;
	}
	else if (integral_stats[length].second == 0.0){
		errs<<"CalcZScore: There is no calibration information for length "
			<<length<<" proteins.";
		cerr<<errs.str()<<endl;
		return -10000.0;
	}
	return (raw_score-integral_stats[length].first)/
		integral_stats[length].second;
}
