#include "constants.h"
#include "Seq.h"
#include "Tools.h"
#include "Par.h"
#include <iomanip>
#include <sstream>
#include <cmath>
#include <cstdio>

Seq::labels Seq::lb;

Seq::ext Seq::func;

Seq::Seq (){}



Seq::Seq (multimap<string,string>&sdat,string id,
		  set<string>& posID,map<string,string>& cred) {
	//make this opportunistic, include threads
	//this does not initialize alpha or beta variables
	pReturn=&Seq::ReturnP;
	
	ostringstream errs;
	uint t; //time
	scl.Seqlen=sdat.find(lb.sq)->second.size(); //waah! messy
	scl.SeqID=id;
	scl.AASeq=sdat.find(lb.sq)->second;
	
	if (cred.find(id)!=cred.end()) scl.ClassDesc=cred[id];
	//else cout<<"Couldn't find classdescription for "<<id<<endl;
	if (posID.find(scl.ClassDesc)==posID.end()) scl.posQ=false;
	else scl.posQ=true;

	row.resize(scl.Seqlen);
	for (t=0;t<scl.Seqlen;t++) row[t]=vec();
	
	//resize CTable
	uint istate;
	CTable.resize(Par::NEval);
	for (istate=0;istate<Par::NEval;istate++) CTable[istate].resize(Par::NEval);
	
	//initialize label strings (sln)
	string sln_old,sln_new; //sln_new is the translated label
	sln_old.resize(2);
	for (t=0;t<scl.Seqlen;t++) {
		scl.labelQ=true; //assume a labelling
		if (sdat.find(lb.at)!=sdat.end() &&
			sdat.find(lb.mo)!=sdat.end()) {
			
			sln_old[0]=sdat.find(lb.mo)->second[t];
			sln_old[1]=sdat.find(lb.at)->second[t];
			
			if (Par::L2Lmap.find(sln_old)==Par::L2Lmap.end()){
				errs<<"E18: no l2l reduction for original label "
					<<sln_old.data();
				throw errs.str();
			}
			sln_new=Par::L2Lmap[sln_old];
			//cout<<sln_old<<"->"<<sln_new<<endl;
			row[t].cln[0]=sln_new[0];
			row[t].cln[1]=sln_new[1];
			
			if (Par::SLNmap.find(sln_new)==Par::SLNmap.end()){
				errs<<"E19: SLNmap doesn't contain "<<sln_new.data()<<".";
				throw errs.str();
			}
			row[t].iln=Par::SLNmap[sln_new];
		}
		else scl.labelQ=false; //if we fail even once to assign labelling,
		//labelQ is false
		//else iln and actbetaQ are left uninitialized
	}
	
	//initialize row[t].iaa for all t
	for (t=0;t<scl.Seqlen;t++) row[t].iaa=Par::AminoMap[scl.AASeq[t]];
	
	InitProfile(sdat,scl.Seqlen);
}	


Seq::Seq (const char *qfile,const char *id){

	pReturn=&Seq::ReturnP;

	//resize CTable
	scl.SeqID=id;
	uint istate;
	CTable.resize(Par::NEval);
	for (istate=0;istate<Par::NEval;istate++)
		CTable[istate].resize(Par::NEval);

	InitProfile(qfile); //this initializes Profile, AASeq, and scl.Seqlen

	//initialize row[t].iaa for all t
	uint t; //time
	row.resize(scl.Seqlen);
	for (t=0;t<scl.Seqlen;t++) row[t]=vec();
	for (t=0;t<scl.Seqlen;t++) row[t].iaa=Par::AminoMap[scl.AASeq[t]];
}	


void Seq::InitProfile(const char *qfile){
	//initializes the profile for the calling Seq object
	//modifies variable Profile[t][c], where t is time (position)
	//, iam=integer amino acid.  also uses Par::AminoMap[sam]=iam;
	//assumes qfile is the name of a Blast Q formatted file
	string errmsg;
	char line[1000],A[20],QueryAmino; //we expect to take in 20 amino
	int C[20]; //C[i]=composition
	ifstream q(qfile);
	if (! q){
		errmsg="InitProfile:  I couldn't open Blast Q file ";
		errmsg+=qfile;
		throw errmsg;
	}
	int i;
	//prescan for the number of valid lines, set equal to Seqlen
	q.getline(line,1000); //blank line
	q.getline(line,1000); //Last position-specific scoring matrix...
	if (strncmp(line,"Last position-specific scoring matrix computed",46)){
		errmsg=qfile;
		errmsg+=" isn't a Blast Q file";
		throw errmsg;
	}
	q.ignore(1000,'\n'); //          A R N D C Q E ...
	int T=0,t;
	while (q.getline(line,1000)){
		if (line[0]=='\0') break;
		T++;
	}
	scl.Seqlen=T;
	q.seekg(ios::beg); //reset the read position to the beginning

	//Resize Profile
	Profile.resize(scl.Seqlen);
	scl.AASeq.resize(scl.Seqlen);

	q.ignore(1000,'\n');
	q.ignore(1000,'\n');
	q.getline(line,1000);
	sscanf(line," %*c %*c %*c %*c %*c %*c %*c %*c %*c %*c %*c %*c %*c %*c %*c %*c %*c %*c %*c %*c\
                  %c %c %c %c %c %c %c %c %c %c %c %c %c %c %c %c %c %c %c %c",
		   &A[0],&A[1],&A[2],&A[3],&A[4],&A[5],&A[6],&A[7],&A[8],&A[9],&A[10],
		   &A[11],&A[12],&A[13],&A[14],&A[15],&A[16],&A[17],&A[18],&A[19]);
	//
	t=0;
	while (q.getline(line,1000)){
		if (line[0]=='\0') break; //blank line signals end of the file
 		sscanf(line,"%*d %c %*d %*d %*d %*d %*d %*d %*d %*d %*d %*d %*d %*d %*d %*d %*d %*d %*d %*d %*d %*d\
                     %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d",
  			   &QueryAmino,
  			   &C[0],&C[1],&C[2],&C[3],&C[4],&C[5],&C[6],&C[7],&C[8],&C[9],&C[10],
  			   &C[11],&C[12],&C[13],&C[14],&C[15],&C[16],&C[17],&C[18],&C[19]);
		Profile[t].resize(Par::NUMAMINO);
		for (i=0;i<20;i++) Profile[t][Par::AminoMap[A[i]]]=(double)C[i];
		scl.AASeq[t]=QueryAmino;
		t++;
	}

	//normalize columns, using single sequence identity vector
	//in place of the profile column
	for (t=0;t<T;t++) 
		if (!BoolNormalize(&Profile[t][0],Par::NUMAMINO))
			Profile[t][Par::AminoMap[scl.AASeq[t]]]=1.0;

	//find sum more correctly here
	scl.S=7.40;
	
	//calculate Z_log
	double sum=0.0;
	for (i=1;i<=(int)Par::NUMAMINO;i++) sum+=log((double)i);
	scl.Z_log=Par::NUMAMINO*log(scl.S)-sum;

}


void Seq::InitProfile(multimap<string,string>& sdat,uint T){
	uint t,c;
	ostringstream errs;
	char num[256],amino;
	Profile.resize(T);
	Profile.reserve(T);
	for (t=0;t<T;t++) Profile[t].resize(Par::NUMAMINO);
	for (t=0;t<T;t++) Profile[t].reserve(Par::NUMAMINO);
	multimap<string,string>::iterator it;

	//tally all profile lines
	for (it=sdat.begin();it!=sdat.end();it++){
		if (it->first!=lb.pr) continue;
		istringstream prline(it->second); //initialize profile line for reading
		prline>>amino; //read amino symbol
		if (Par::AminoMap.find(amino)==Par::AminoMap.end()){
			errs<<"E16: Par::AminoMap doesn't contain "<<amino;
			throw errs.str();
		}

		c=Par::AminoMap[amino];
		for (t=0;t<T;t++){
			if (!(prline>>num)) {
				errs<<"E17: not enough numbers in profile.";
				throw errs.str();
			}
			assert(c<Profile[t].size());
			Profile[t][c]=atof(num);
		}
	}
	
	//normalize columns, using single sequence identity vector
	//in place of the profile column
	for (t=0;t<T;t++) 
		if (!BoolNormalize(&Profile[t][0],Par::NUMAMINO))
			Profile[t][row[t].iaa]=1.0;


	//find sum more correctly here
	scl.S=7.40;
	
	//calculate Z_log
	double sum=0.0;
	uint i;
	for (i=1;i<=Par::NUMAMINO;i++) sum+=log((double)i);
	scl.Z_log=Par::NUMAMINO*log(scl.S)-sum;

}


void Seq::InitSeq(){
	lb.id="id";
	lb.at="annotatom";
	lb.mo="annotmotif";
	lb.sq="seqres";
	lb.ts="annot2state";
	lb.pr="profile";
	lb.H="Hnode";
	lb.E="Enode";
	lb.L="Lnode";
}
	

map<string,multimap<string,string> > Seq::Read(char* file){
	ifstream sf(file);
	ostringstream errs;
	if (!sf) {
		errs<<"Couldn't open "<<file;
		throw errs.str();
	}
	map<string,multimap<string,string> >dat;
	map<string,multimap<string,string> >::iterator idat;
	
	string id,label,line;
	
	//load data into dat
	while (sf>>id>>label){
		line="";
		while (sf.peek() == ' ' || sf.peek()=='\t') sf.get();
		while (sf.peek()!='\n') line += sf.get();
		dat[id].insert(make_pair(label,line));
		if (sf.peek()=='\n') sf.get();
	}
	sf.close();
	
	//check dat
	for (idat=dat.begin();idat!=dat.end();idat++)
		if (! CheckDat(idat->second,idat->first))
			cerr<<"Failed check on "<<idat->first<<endl;
	return dat;
}


pair<string,multimap<string,string> > Seq::ReadOne(ifstream& sf){
	//returns default data-structure if encounters eof
	if (! sf.good()) return pair<string,multimap<string,string> >();

	pair<string,multimap<string,string> >dat;
	string id="",label,line,prev_id="";
	int prev_pos=sf.tellg(); //used to keep track of ios::cur, the current position
	//load data into dat

	while (sf>>id>>label){
		line="";
		if ((id != prev_id) && (prev_id != "")) {
			sf.seekg(prev_pos);  //reset stream to previous position
			break;
		}
		while (sf.peek() == ' ' || sf.peek()=='\t') sf.get();
		while (sf.peek()!='\n') line += sf.get();
		dat.first=id;
		dat.second.insert(make_pair(label,line));
		if (sf.peek()=='\n') sf.get();
		prev_id=id;
		prev_pos=sf.tellg(); //remember current position
	}
		
	//check dat
	if (! CheckDat(dat.second,dat.first))
		cerr<<"Failed check on "<<dat.first<<endl;
	return dat;
}



bool Seq::CheckDat(multimap<string,string>& dat,string id) throw (string&){
	//make this opportunistic: check data only if it exists
	//otherwise don't worry about it.  But, require the fields
	//sq

	ostringstream errs;
	bool gooddat=true; //innocent until proven guilty
	//check lengths

	assert(dat.find(lb.sq)!=dat.end());
	if (dat.find(lb.sq)==dat.end()) cerr<<"CheckDat: doesn't contain required field "<<lb.sq<<endl;
	string sq=dat.find(lb.sq)->second;

	if (dat.find(lb.at)!=dat.end() &&
		dat.find(lb.mo)!=dat.end() &&
		dat.find(lb.ts)!=dat.end()) {
		
		string at=dat.find(lb.at)->second,
			mo=dat.find(lb.mo)->second,
			ts=dat.find(lb.ts)->second;

		if (at.size() != mo.size() &&				
			at.size() != sq.size() &&				
			at.size() != ts.size()){				
			
			cerr<<"unequal lengths for "<<id<<endl;	
			cerr<<lb.at<<": "<<at.size()<<endl;		
			cerr<<lb.mo<<": "<<mo.size()<<endl;		
			cerr<<lb.sq<<": "<<sq.size()<<endl;		
			cerr<<lb.ts<<": "<<ts.size()<<endl;		
			gooddat=false;							
		}                                           
	}
	
 
	uint T=sq.size();
	if (T==0) {
		errs<<"E20: sequence length is zero";
		throw errs.str();
	}

	//Check Profile Field
	if (!CheckProfile(dat,T)) gooddat=false;


	
	string vals[]={lb.H,lb.E,lb.L};
	uint ctr;
	char num[256];

	//Check Secondary Structure Prediction fields if they exist
	if (dat.find(lb.H)!=dat.end() &&
		dat.find(lb.E)!=dat.end() &&
		dat.find(lb.L)!=dat.end()) {
		for (uint n=0;n<sizeof(vals)/sizeof(string);n++){
			ctr=0;
			istringstream thread(dat.find(vals[n])->second);
			while (thread>>num) ctr++;
			if (ctr != T){
				cerr<<"CheckDat: thread "<<vals[n]<<" contains "
					<<ctr<<" fields, should be "<<T<<endl;
				gooddat=false;
			}
		}
	}

	return gooddat;
}
 
 
bool Seq::CheckProfile(multimap<string,string>& dat,uint T){
	//check profile
	bool gooddat=true; //innocent until proven guilty
	char num[256],amino;
	uint ctr,numc=0;
	multimap<string,string>::iterator it;

	//iterate through all profile lines
	for (it=dat.begin();it!=dat.end();it++){
		if (it->first!=lb.pr) continue;
		istringstream profile(it->second);
		profile>>amino; //read in amino label
		numc++;
		if (Par::AminoMap.find(amino)==Par::AminoMap.end()){
			cerr<<"CheckProfile: Profile contains amino symbol "
			<<amino<<" not in AminoMap"<<endl;
			gooddat=false;
		}
		ctr=0;
		while (profile>>num) ctr++;
		if (ctr != T){
			cerr<<"CheckProfile: Profile contains "<<ctr
				<<" numbers, should be "<<T<<endl;
			gooddat=false;
		}
	}
	if (numc!=Par::NUMAMINO){
		cerr<<"CheckProfile: only "<<numc<<" symbols in profile, "
			<<"should be "<<Par::NUMAMINO<<endl;
		gooddat=false;
	}
	return gooddat;
}	 


void Seq::CalcCTable(Par& M){
	//tallies the CTable variable based on the labelling
	//using the act_istate and pred_istate variables
	uint NS=Par::NEval,istate1,istate2;
	uint T=scl.Seqlen,t,ian;

	for (t=0;t<T;t++)
		for (ian=0;ian<Par::NumA;ian++)
			if (Par::LA[row[t].iln][ian]){
				row[t].act_ian=ian;
				break;
			}

	for (istate1=0;istate1<NS;istate1++)
		for (istate2=0;istate2<NS;istate2++)
			CTable[istate1][istate2]=0;
	
	for (t=0;t<T;t++)
		CTable[Par::ReduxEval[row[t].pred_ian]][Par::ReduxEval[row[t].act_ian]]++;
}


inline double Seq::ReturnA(uint t,uint ian,Par& M){
	uint ien=Par::A2E[ian];
	assert(!isnan(M.EmitAmino[ien][row[t].iaa]));
	return M.EmitAmino[ien][row[t].iaa];
}


inline double Seq::ReturnP(uint t,uint ian,Par& M){
	return DotP(&M.EmitAmino[Par::A2E[ian]][0],
				&this->Profile[t][0],Par::NUMAMINO);
}

