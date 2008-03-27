#include <vector>
#include <dirent.h>
#include <sys/stat.h> //for stat(), checking whether file or directory
#include <string>
#include <iostream>
#include <sstream>
#include <cmath>
#include <iomanip>
#include <cstdio>
#include "Par.h"
#include "TrainSeq.h"
#include "Load.h"
#include "Output.h"
#include "HMMOutput.h"
#include "Tools.h"
#include "Zscore.h"
#include "opt.h"

using namespace std;

char *Dir="",*LLmap="",*LAmap="",*AEmap="",*Seqs="",*TestQName="",*TestQList="";
char *ReduxDecode="",*ReduxReport="",*Arch="",*OutPrefix="",*NullFreq="";
char *Alphabet="-|8X",*EmissionsFile=""; //global argument variables
char *Zfile="";

double Slope,Intercept,ScoreCutoff;
int UseLabelQ=1;

void PrintGlobals(ostream& out){
	out<<"OutPrefix: "<<OutPrefix<<endl;
	out<<"LLmap: "<<LLmap<<endl;
	out<<"LAmap: "<<LAmap<<endl;
	out<<"AEmap: "<<AEmap<<endl;
	out<<"Seqs: "<<Seqs<<endl;
	out<<"TestQName: "<<TestQName<<endl;
	out<<"TestQList: "<<TestQList<<endl;
	out<<"Arch: "<<Arch<<endl;
	out<<"ReduxDecode: "<<ReduxDecode<<endl;
	out<<"ReduxReport: "<<ReduxReport<<endl;
	out<<"NullFreq: "<<NullFreq<<endl;
	out<<"ZCurve: "<<Zfile<<endl;
}


int Run(int argc,char** argv) {
	uint i;

	Seq::InitSeq();

	char fSeqs[256],fLLmap[256],fLAmap[256],
		fAEmap[256],fReduxDecode[256],fReduxReport[256],fArch[256],
		fNullFreq[256],fEmissionsFile[256],fZfile[256];

	PrefixDir(Dir,Seqs,fSeqs);
	PrefixDir(Dir,LLmap,fLLmap);
	PrefixDir(Dir,LAmap,fLAmap);
	PrefixDir(Dir,AEmap,fAEmap);
	PrefixDir(Dir,ReduxDecode,fReduxDecode);
	PrefixDir(Dir,ReduxReport,fReduxReport);
	PrefixDir(Dir,Arch,fArch);
	PrefixDir(Dir,NullFreq,fNullFreq);
	PrefixDir(Dir,EmissionsFile,fEmissionsFile);
	PrefixDir(Dir,Zfile,fZfile);

	struct stat Qstat;

	if (stat(Dir,&Qstat) ||
		((Qstat.st_mode & S_IFMT) != S_IFDIR)) {
		cerr<<"Couldn't find "<<Dir<<" (option -d) or it wasn't a directory."<<endl;
		return 1;
	}

	if (stat(fNullFreq,&Qstat) ||
		((Qstat.st_mode & S_IFMT) != S_IFREG)) {
		cerr<<"Couldn't open null frequency file "<<fNullFreq<<" (option -n)."<<endl;
		return 1;
	}

	if (TestQList[0] != '\0' && stat(TestQList,&Qstat) ||
		((Qstat.st_mode & S_IFMT) != S_IFREG)) {
		cerr<<"Couldn't open Qlist file "<<TestQList<<" (option -v)."<<endl;
		return 1;
	}

	if (stat(fZfile,&Qstat) ||
		((Qstat.st_mode & S_IFMT) != S_IFREG)) {
		cerr<<"Couldn't open Z-curve file "<<fZfile<<" (option -z)."<<endl;
		return 1;
	}

	char line[256];
	ifstream fQList;
	set<string>QList;
	fQList.open(TestQList);
	while (fQList>>line) QList.insert(string(line));
	fQList.close();

	try {Par::Init(fLLmap,fLAmap,fAEmap,fReduxDecode,
				   fReduxReport,fArch,Alphabet);}
	catch (string& errmsg){
		cerr<<errmsg<<endl;
		return 1;
	}

	try { Par::ReadZCurve(fZfile); }
	catch (string& errmsg){
		cerr<<errmsg<<endl;
		return 1;
	}

	cout<<"Finished Init"<<endl;

	//load all sequences (to be used in jackknife procedure)
	vector<TrainSeq> Trainvec;
	try{Trainvec=LoadTrainSeqs(fSeqs);}
	catch (string& errmsg){
		cerr<<errmsg<<endl;
		return 1;
	}
	uint LengthSum=0;
	for (i=0;i<Trainvec.size();i++) LengthSum+=Trainvec[i].scl.Seqlen;
	cout<<"Finished Loading Training Sequences."<<endl;

	
	//create and initialize model
	string Empty="";
	Par Model(Trainvec,Arch,Empty);

	char aa[1];
	float comp;
	ifstream fNull;
	fNull.open(fNullFreq);

	while (fNull.getline(line,256)){
		sscanf(line,"%c\t%f\n",aa,&comp);
		Model.AAComp[Model.AminoMap[aa[0]]]=(double)comp;
	}
	Normalize(&Model.AAComp[0],Par::NUMAMINO);
	cout<<"Finished Initializing model."<<endl;


	//train model
	Model.Update(Trainvec,Empty,UseLabelQ);
	double cur_delta=HUGE_VAL,prev_score,cur_score=-HUGE_VAL;
	while (cur_delta>0.01){
		prev_score=cur_score;
		cur_score=Model.Update(Trainvec,Empty,UseLabelQ);
		cur_delta=abs(cur_score-prev_score);
	}
	cout<<"Finished Training Model."<<endl;

	//Print Emissions Parameters
	//ofstream EM(EmissionsFile);
	//PrintEmitLogOdds(EM,Model,-5.0);
	//EM.close();

	//Print Full Set of Parameters
	//PrintTrans(cout,Model);
	//PrintEmit(cout,Model);


	//Initialize Outstream

 	char FileName[256];
	strcpy(FileName,OutPrefix);
	ofstream TS(FileName);
	if (!TS) {
		cerr<<"Couldn't open Output file "<<FileName<<endl;
		return 1;
	}



	//Read in each Test Sequence, evaluate and print out results
	const char *Path; //for constructing the path
	Seq CurTestSeq;
	ostringstream sspath;  //can't use unistd.h chdir, not windows compatible...
	string spath;
	double zscore;

	if (stat(TestQName,&Qstat) || 
		(((Qstat.st_mode & S_IFMT) != S_IFREG) &&
		((Qstat.st_mode & S_IFMT) != S_IFDIR))) {
		cerr<<TestQName<<" (option -q) is not a regular file or a directory."<<endl;
		return 1;
	}

	if ((Qstat.st_mode & S_IFMT) == S_IFDIR){
		struct stat Dstat;
		DIR *Qdir;
		dirent *Qdirent;
		Qdir=opendir(TestQName);
		while ((Qdirent=readdir(Qdir))){
			if (TestQList[0] != '\0' &&
				QList.find(string(Qdirent->d_name))==QList.end()) continue;
			sspath.str(""); //reinitializes the buffer to empty
			sspath<<TestQName<<'/'<<Qdirent->d_name;
			spath=sspath.str();
			Path=spath.c_str();
			if (stat(Path,&Dstat))
				cout<<"Can't determine what "<<Path
					<<" is...skipping."<<endl;

			else if ((Dstat.st_mode & S_IFMT)==S_IFREG){
				try {
					CurTestSeq=Seq(Path,Qdirent->d_name);
					//cout<<"Loaded Profile file "<<Path<<"."<<endl;
					CurTestSeq.Decode(Model); //two-state decoding
					zscore=CalcZScore(Par::Zcurve,CurTestSeq.scl.Seqlen,
									  CurTestSeq.scl.Pbits);
					CurTestSeq.scl.Score=zscore;

					if (zscore>ScoreCutoff){
						PrintPretty(TS,CurTestSeq,true);
						//PrintRdb(TS,CurTestSeq,true);
					}
					else PrintPretty(TS,CurTestSeq,false);
				}
				catch (string& errmsg){
					cout<<"Skipping non-Profile file "<<Path<<"."<<endl;
				}
				catch (...){
					cout<<"Skipping non-parsable file "<<Path<<"."<<endl;
				}
			}
			else if ((Dstat.st_mode & S_IFMT)==S_IFDIR)
				cout<<"Skipping subdirectory "<<Qdirent->d_name<<"."<<endl;
			else cout<<"Skipping other type "<<Qdirent->d_name<<"."<<endl;
		}
		TS.close();
	}
	else if ((Qstat.st_mode & S_IFMT) == S_IFREG){
		try {CurTestSeq=Seq(TestQName,TestQName);}
		catch (...){
			cout<<TestQName<<" is not in psiblast format. "
				<<"Please check the format and try again."<<endl;
			return 1;
		}

		CurTestSeq.Decode(Model); //two-state decoding
		zscore=CalcZScore
			(Par::Zcurve,CurTestSeq.scl.Seqlen,CurTestSeq.scl.Pbits);
		CurTestSeq.scl.Score=zscore;

		if (zscore>ScoreCutoff){
			PrintPretty(TS,CurTestSeq,true);
			//PrintRdb(TS,CurTestSeq,true);
		}
		else PrintPretty(TS,CurTestSeq,false);
	}
	else { 
		cerr<<TestQName<<
			", (option -q) is neither a directory nor a regular file."<<endl;
		return 1;
	}

	cout<<"Successfully finished Prediction."<<endl;
	return 0;
}


int main(int argc,char** argv){
	OptRegister(&Dir,OPT_STRING,'d',"directory-root","root path where files (options -s,-r,-l,-a,-e,-t,-u,-z,-n) reside");
	OptRegister(&Seqs,OPT_STRING,'s',"sequence-file","labelled training sequence file");
	OptRegister(&Arch,OPT_STRING,'r',"arch-file","architecture file");
	OptRegister(&LLmap,OPT_STRING,'l',"label2label-map","label-to-label file");
	OptRegister(&LAmap,OPT_STRING,'a',"label2arch-map","label-to-arch file");
	OptRegister(&AEmap,OPT_STRING,'e',"arch-map","arch-to-emission file");
	OptRegister(&ReduxDecode,OPT_STRING,'t',"reduction-state-decode","state reduction for decoding");
	OptRegister(&ReduxReport,OPT_STRING,'u',"reduction-state-report","state reduction for reporting");
	OptRegister(&Zfile,OPT_STRING,'z',"z-curve-file","file containing means and sd's at integral length values");
	OptRegister(&NullFreq,OPT_STRING,'n',"null-frequency","background frequency file");
	OptRegister(&Alphabet,OPT_STRING,'p',"alphabet","sequence alphabet");
	OptRegister(&TestQName,OPT_STRING,'q',"test-blastQ-file-or-dir","psiblast profile (-Q) or directory (full pathname or relative to current directory) with many profiles");
	OptRegister(&TestQList,OPT_STRING,'v',"list-blastQ-files","list of psiblast files to process in directory (leave blank to process all files)");
	OptRegister(&ScoreCutoff,OPT_DOUBLE,'b',"minimum-score-cutoff","minimum z-score for per-residue prediction");
	OptRegister(&OutPrefix,OPT_STRING,'o',"outfile-prefix","output file prefix");

	optMain(Run);

	if (argc==1){
		char **myargv,*mybuf[2];
		mybuf[0]=argv[0];
		mybuf[1]="$";
		myargv=mybuf;
		int myargc=2;
		cout<<endl<<endl
			<<"Welcome to ProfTMB.  type '?' at the prompt for "
			<<"instructions on entering options."<<endl
			<<"----------------------------"<<endl<<endl;
		opt(&myargc,&myargv);
	}

	else opt(&argc,&argv);
	return Run(argc,argv);
}
