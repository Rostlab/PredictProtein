#include "Par.h"
#include "Tools.h"
#include "Load.h"
#include <sstream>
#include <iostream>
#include <fstream>
#include <cmath>
#include <iomanip>
#include <cstdio>
                               // i=int,s=string,d=double
map<char,uint> Par::AminoMap;        // Aminomap[sam]=iam;
map<uint,char> Par::AminoMapRev;
map<string,uint>Par::SLNmap,Par::SANmap,Par::SENmap; //SLNmap[sln]=iln
map<uint,string>Par::SLNrev,Par::SANrev,Par::SENrev;
map<string,string>Par::L2Lmap; //L2Lmap[sln_old]=sln_new
map<uint,set<uint> >Par::Connect;
vector<vector<bool> >Par::LA; //LA[iln][ian]=bool
vector<bool>Par::TwoState; //TwoState[ian]=bool
vector<int>Par::ReduxDecode,Par::ReduxEval; //ReduxStates[ian]=istate
uint Par::NDecode,Par::NEval; //Number of decode or eval states
vector<string>Par::StatesDecode,Par::StatesEval; //StatesDecode[istate]=sstate
map<string,int>Par::RevEval; //RevEval[sstate]=istate
vector<uint>Par::A2E; //A2E[ian]=ien
uint Par::NumE,Par::NumA,Par::NumL;
uint Par::NLProf,Par::NGProf;
vector<double>Par::ProfMult;      // ProfMult[ind]=multiplier
vector<gproftriple>Par::EmitProfG; //EmitProfG[ev].H.E or H.nonE etc
uint Par::NUMAMINO;
double Par::Slope,Par::Intercept;
vector<double>Par::AAComp; //AAComp[c]=double
vector<pair<double,double> >Par::Zcurve;

void Par::Clear(){
	//erases all static data in class Par
	EmitProfG.clear();
	Connect.clear();
	AminoMap.clear();
	AminoMapRev.clear();
	A2E.clear();
 	SLNmap.clear();
 	SANmap.clear();
 	SENmap.clear();
	SLNrev.clear();
 	SANrev.clear();
 	SENrev.clear();
 	L2Lmap.clear();
	LA.clear();
	TwoState.clear();
	ReduxDecode.clear();
	ReduxEval.clear();
	StatesDecode.clear();
	StatesEval.clear();
	RevEval.clear();
	ProfMult.clear();
	AAComp.clear();
	Zcurve.clear();
	NDecode=NEval=NumE=NumA=NumL=0;
	NGProf=NLProf=0;
	NUMAMINO=0;
	Slope=0;
	Intercept=0;
}

// void Par::Init(char* l2lfile,char* l2afile,
// 			   char* a2efile,char* redux,char* confile,
// 			   const char *abet){
// 	//initializes all static variables for Par, using a single
// 	//redux file for both decoding and evaluation
// 	//(if it ever evaluates anyway...)
// 	Clear();
// 	InitAbet(abet);
// 	InitMaps(l2lfile,l2afile,a2efile,confile,redux,redux);
// }


void Par::Init(char* l2lfile,char* l2afile,char* a2efile,
			   char* rdfile,char* refile,char* confile,
			   const char *abet){
	//initializes all static variables for Par
	Clear();
	//	InitConst(s,i);
	InitAbet(abet);
	InitMaps(l2lfile,l2afile,a2efile,confile,rdfile,refile);
}


// void Par::Init(char* l2lfile,char* l2afile,
// 			   char* a2efile,char* rdfile,
// 			   char* refile,char* confile,
// 			   char* prof,double* tmult,uint nlprof,
// 			   uint ngprof,const char*){
// 	Init(l2lfile,l2afile,a2efile,rdfile,refile,confile);
// 	InitConst(nlprof,ngprof,tmult);
// }


void Par::InitConst(double s,double i){
	Slope=s;
	Intercept=i;
}


void Par::Init(const char *abet){
	InitAbet(abet);
}


Par::Par(){}


Par::Par(vector<TrainSeq>&tsq,char* cf,string& ex,bool profQ){
	//must call Init before calling Par, and in this order
	this->Allocate(NumA,NumE);
	this->TallyA(tsq,ex);
	this->TallyE(tsq,ex);
	if (profQ) this->TallyP(tsq,ex);
	this->InitArchRev();
	this->InitArchSize();
}


void Par::InitAbet(const char *abet){
	//initialize AminoMap and NUMAMINO and AAComp
	string aa=abet;
	//this is a requirement for the symbols
	NUMAMINO=aa.length();
	AAComp.resize(NUMAMINO);
	for (uint i=0;i<NUMAMINO;i++){
		AminoMap[aa[i]]=i;
		AminoMapRev[i]=aa[i];
		AAComp[i]=0;
	}
}	


void Par::InitConst(uint nlprof,uint ngprof,double *tmult){
	//assumes 3 prof states, 'H', 'E', 'L' hard coded
	uint nstates=3;
	NLProf=nlprof;
	NGProf=ngprof;
	uint i;
	ProfMult.resize(nstates);
	for (i=0;i<nstates;i++) ProfMult[i]=tmult[i];
	Normalize(&ProfMult[0],nstates);
}


void Par::InitMaps(char* l2lfile,char* l2afile,
				   char* a2efile,char* confile,
				   char* rdfile,char* refile){
	//static wrapper function that calls four functions
	//in correct order
	LoadConnect(confile);
	cout<<"Loaded "<<confile<<endl;
	LoadL2L(l2lfile);
	cout<<"Loaded "<<l2lfile<<endl;
	LoadL2A(l2afile);
	cout<<"Loaded "<<l2afile<<endl;
	LoadA2E(a2efile);
	cout<<"Loaded "<<a2efile<<endl;
	LoadRedux(rdfile,refile);
	cout<<"Loaded "<<rdfile<<endl;
	cout<<"Loaded "<<refile<<endl;
}


void Par::LoadConnect(char* cf) throw (string&){
	ifstream cfile(cf);
	ostringstream errs;
	if (!cf) {
		errs<<"Fatal Error: Couldn't open Architecture file "
			<<cf<<" (option -r)";
		throw errs.str();
	}
	
	string s_san,t_san;
	uint s_ian,t_ian;
	uint ian_ctr=0;

	while (cfile>>s_san){
		if (SANmap.find(s_san)==SANmap.end()){
			SANmap[s_san]=ian_ctr;
			SANrev[ian_ctr]=s_san;
			ian_ctr++;
		}

		s_ian=SANmap[s_san];
		if (Connect.find(s_ian)!=Connect.end()) {
			errs<<"E1: repeat source "<<s_san.data()<<"found.";
			throw errs.str();
		}
		Connect[s_ian]=set<uint>();
		while (cfile.peek()!='\n') {
			cfile>>t_san;
			if (SANmap.find(t_san)==SANmap.end()){
				SANmap[t_san]=ian_ctr;
				SANrev[ian_ctr]=t_san;
				ian_ctr++;
			}
			
			t_ian=SANmap[t_san];
			Connect[s_ian].insert(t_ian);
		}
	}
	cfile.close();
	NumA=ian_ctr;
}
			

void Par::LoadL2L(char* l2lfile) throw (string&){
	//static function
	//loads SLNmap and SLNrev
	//parses l2lfile, which defines a strict
	//onto mapping (injection) from few labels
	//to many labels.
	//accepts a format of
	//newlabel oldlabel oldlabel oldlabel ...
	//newlabel oldlabel oldlabel ...
	//errors:  all labels must be two digits
	//no label can occur twice in the file
	//if a label is encountered in the training sequences
	//which isn't in the l2lmap, it is an error	
	ostringstream errs;
	ifstream lf(l2lfile);
	if (!lf) {
		errs<<"Couldn't open label-to-label file "<<l2lfile;
		throw errs.str();
	}
	string sln_new,sln_old;
	uint iln=0;
	uint cur_iln;
	map<string,string>l2l;
	set<string>seen_sln_old;
	while (lf>>sln_new){
		if (sln_new.size()==0){
			errs<<"E2: found blank line in "<<l2lfile;
			throw errs.str();
		}
		if (SLNmap.find(sln_new)!=SLNmap.end()){
			errs<<"E3: repeat sln_new found in "<<l2lfile<<": "<<sln_new.data();
			throw errs.str();
		}

		SLNmap[sln_new]=iln;
		SLNrev[iln]=sln_new;
		iln++;

		cur_iln=SLNmap[sln_new];

		while (lf.peek() != '\n' && lf.peek() != EOF){
			lf>>sln_old;
			if (sln_old.size()==0){
				errs<<"E4: new label has no old labels in "<<l2lfile;
				throw errs.str();
			}
			if (seen_sln_old.find(sln_old)!=seen_sln_old.end()){
				errs<<"E5: repeat sln_old found: "
					<<sln_old.data()<<" in "<<l2lfile;
				throw errs.str();
			}
			seen_sln_old.insert(sln_old);
			L2Lmap[sln_old]=sln_new;
		}
	}
	NumL=iln;
	lf.close();
}


void Par::LoadL2A(char* l2afile) throw (string&){
	//this is a static function
	// parses l2afile, format:
	// sln  san san san...
	// sln  san san san...
	//creates LA[iln][ian]=bool
	// assumes that any labels found in SLNmap but not
	// found in l2afile map to exactly one san
	// and it's an error if SANmap doesn't contain an san
	// by the same name in this case.
	// at the end, all sln's in SLNmap must be mapped
	// and all san's in SANmap must be mapped as well
	
	ostringstream errs;
	ifstream lf(l2afile);
	if (!lf) {
		errs<<"Couldn't open label2arch-map file "<<l2afile
			<<" (option -a).";
		throw errs.str();
	}
	string sln,san;
	uint iln,ian,cur_iln,cur_ian;
	map<uint,set<uint> > l2a;
	set<string> used_san;


	while (lf>>sln){
		if (sln.size()==0){
			errs<<"E2: Found blank line in "<<l2afile;
			throw errs.str();
		}

		if (SLNmap.find(sln)==SLNmap.end()){
			errs<<"E7: Label "<<sln.data()
				<<" found in "<<l2afile<<" but missing from L2Lfile.";
			throw errs.str();
		}

		cur_iln=SLNmap[sln];

		while (lf.peek() != '\n' && lf.good()){
			lf>>san;
			if (san.size()==0){
				errs<<"E8: label has no archnames in"<<l2afile;
				throw errs.str();
			}

			if (SANmap.find(san)==SANmap.end()){
				errs<<"E9: "<<san.data()<<" not found in arch file.";
				throw errs.str();
			}

			if (used_san.find(san)==used_san.end())
				used_san.insert(san);
			//it is okay to have repeat san's in explicit mapping
			
			cur_ian=SANmap[san];
			if (l2a.find(cur_iln)==l2a.end())
				l2a[cur_iln]=set<uint>();
			if (l2a[cur_iln].find(cur_ian)==l2a[cur_iln].end())
				l2a[cur_iln].insert(cur_ian);
		}
	}
	lf.close();

	//Achieve Implicit mapping, with error checks
	// Here we 
	map<string,uint>::iterator it;
	string test_san;
	for (it=SLNmap.begin();it!=SLNmap.end();it++){
		sln=it->first;
		cur_iln=it->second;
		if (l2a.find(cur_iln)!=l2a.end()) continue;
		//ensures only implicit (absent from l2afile) are treated

		test_san=sln; //we will test to see if it exists in SANmap
		if (SANmap.find(test_san)==SANmap.end()){
			errs<<"E10: "<<sln.data()<<" was found in sequence file "
				<<"but not in architecture file.";
			throw errs.str();
		}
		cur_ian=SANmap[test_san];

// 		if (used_san.find(test_san)!=used_san.end())
// 			cerr<<"LoadL2A: warning: implicitly mapped sln "<<sln
// 				<<" has a synonymous san which has been used "
// 				<<"in an explicit mapping"<<endl;
		l2a[cur_iln]=set<uint>();
		l2a[cur_iln].insert(cur_ian);
// 		cout<<"Creating implicit mapping between sln "<<SLNrev[cur_iln]
// 			<<" and san "<<SANrev[cur_ian]<<endl;
	}

	//Check that every iln and ian has at least one partner
	//that the mapping is onto in both directions

	bool ianQ;
	for (ian=0;ian<NumA;ian++){
		ianQ=false;
		for (iln=0;iln<NumL;iln++){
			if (l2a.find(iln)==l2a.end()){
				errs<<"E11: sln "<<SLNrev[iln].data()
					<<"not accounted for.";
				throw errs.str();
			}
			if (l2a[iln].find(ian)!=l2a[iln].end()) ianQ=true;
		}
		if (!ianQ) {
			errs<<"E12: san "<<SANrev[ian].data()
				<<" not accounted for.";
			throw errs.str();
		}
	}

			
	//set LA
	LA.resize(NumL);
	for (iln=0;iln<NumL;iln++){
		LA[iln].resize(NumA);
		for (ian=0;ian<NumA;ian++){
			if (l2a[iln].find(ian)!=l2a[iln].end()){ //we have a connection
				LA[iln][ian]=true;
				/*
				cout<<"sln "<<SLNrev[iln]<<" maps to san "
					<<SANrev[ian]<<endl;
				*/
			}
			else LA[iln][ian]=false;
		}
	}
}
	

void Par::LoadA2E(char* a2efile) throw (string&){	
	// static function, parses A2Efile, producing:
	// A2Efile format:
	// sen  san  san  san  san
	// sen  san  san
	// etc.
	// SENmap[sen]=ien, SENrev[ien]=sen
	// A2E[ian]=ien
	// must be called after LoadL2A
	// requirements: sen's and san's must be unique in
	// the file.  the complete set of san's is already
	// there.  so, if we don't see an san, assume
	// it has no reduction.

	ostringstream errs;
	ifstream af(a2efile);
	if (!af) {
		errs<<"Couldn't open arch-to-emission map "<<a2efile
			<<" (option -e).";
		throw errs.str();
	}
	string san,sen;
	uint sen_ctr=0;
	uint ian,ien;

	A2E.resize(NumA);
	set<string>seen_san;

	while (af>>sen){
		if (sen.size()==0){
			errs<<"E2: found blank line in "<<a2efile;
			throw errs.str();
		}
		if (SENmap.find(sen)==SENmap.end()){
			SENmap[sen]=sen_ctr;
			SENrev[sen_ctr]=sen;
			sen_ctr++;
		}
		ien=SENmap[sen];
		
		while (af.peek() != '\n' && af.peek() != EOF){
			af>>san;
			if (san.size()==0){
				errs<<"E12: emission has no archnames in "<<a2efile;
				throw errs.str();
			}
			if (SANmap.find(san)==SANmap.end()){
				errs<<"E13: san "<<san.data()<<"not seen in l2afile.";
				throw errs.str();
			}
			ian=SANmap[san];
			A2E[ian]=ien;
			seen_san.insert(san);
			/*
			cout<<"san "<<SANrev[ian]<<" maps to sen "<<sen<<endl;
			*/
		}
	}
	af.close();

	//load the rest of SENmap and 
	map<string,uint>::iterator it;
	for (it=SANmap.begin();it!=SANmap.end();it++){
		san=it->first;
		if (seen_san.find(san)==seen_san.end()){
			sen=san;
			SENmap[sen]=sen_ctr;
			SENrev[sen_ctr]=sen;
			sen_ctr++;
			ian=SANmap[san];
			ien=SENmap[sen];
			A2E[ian]=ien;
		}
	}

	NumE=sen_ctr;
}


void Par::LoadRedux(char *rdfile,char* refile) throw (string&){
	//loads the redux decode and redux eval files
	ReduxDecode.resize(NumA);
	ReduxEval.resize(NumA);
	ostringstream errs;
	string san,sstate; //sstate is state of interest user sees
	uint ian;

	ifstream rdf(rdfile);
	if (!rdf) {
		errs<<"Couldn't open redux file "<<rdfile<<" (option -t)";
		throw errs.str();
	}
	while (rdf>>sstate){
		StatesDecode.push_back(sstate);
		while (rdf.peek()!='\n'){
			rdf>>san;
			if (SANmap.find(san)==SANmap.end()){
				errs<<"E14: "<<san.data()<<" not found in SANmap."; 
				throw errs.str();
			}
			ian=SANmap[san];
			assert(ian<ReduxDecode.size());
			ReduxDecode[ian]=StatesDecode.size()-1;
		}
	}
	rdf.close();
	NDecode=StatesDecode.size();

	ifstream ref(refile);
	if (!ref) {
		errs<<"Couldn't open Redux file "<<refile<<" (option -t)";
		throw errs.str();
	}
	while (ref>>sstate){
		StatesEval.push_back(sstate);
		RevEval[sstate]=StatesEval.size()-1;
		while (ref.peek()!='\n'){
			ref>>san;
			if (SANmap.find(san)==SANmap.end()){
				errs<<"E15: "<<san.data()<<" not found in SANmap."; 
				throw errs.str();
			}
			ian=SANmap[san];
			assert(ian<ReduxEval.size());
			ReduxEval[ian]=StatesEval.size()-1;
		}
	}
	ref.close();
	NEval=StatesEval.size();
}


void Par::IncrComp(Seq& S){
	//increments the amino acid composition stored in M
	//with the counts found in S
	for (uint t=0;t<S.scl.Seqlen;t++)
		for (uint c=0;c<Par::NUMAMINO;c++)
			AAComp[c]+=S.Profile[t][c];
}


void Par::PrintZCurve(vector<pair<double,double> >& integral_stats,char *ofile){
	//prints in tab delimited format, (mean, sd)
	//we assume integral_stats has entries starting at zero
	ofstream os(ofile);
	ostringstream errs;
	if (!os){
		errs<<"Couldn't open Zcurve output file "<<ofile<<" (option -z)";
		throw errs.str();
	}

	for (int ind=0;ind<(int)integral_stats.size();ind++){
		os<<integral_stats[ind].first<<'\t'
		  <<integral_stats[ind].second<<endl;
	}
	cout<<"Printed "<<ofile<<endl;
	os.close();
}


void Par::ReadZCurve(char *ifile) throw (string&){
	//assume we are reading a file created by PrintZCurve
	//which contains tab-separated lines (mean,sd)
	ifstream is(ifile);
	ostringstream errs;
	if (!is){
		errs<<"Couldn't open Zcurve file "<<ifile<<" (option -z)";
		throw errs.str();
	}

	char line[100];
	float mean,sd;
	while (is.getline(line,100)){
		if (line[0]=='\0') break;
		sscanf(line,"%f\t%f",&mean,&sd);
		Zcurve.push_back(make_pair(mean,sd));
	}
	is.close();
}
