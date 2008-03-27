#include <vector>
#include <unistd.h>
#include <string>
#include <iostream>
#include <iomanip>
#include <cmath>
#include <cstdio>
#include "Par.h"
#include "TrainSeq.h"
#include "Load.h"
#include "Output.h"
#include "HMMOutput.h"
#include "Tools.h"
#include "opt.h"
#include "Eval.h"
#include "Zscore.h"

// extern "C" {
// #include "config.h"
// #include "postprob.h"
// #include "funcs.h"		/* function declarations                */
// #include "squid.h"		/* general sequence analysis library    */
// #include "config.h"		/* compile-time configuration constants */
// #include "structs.h"		/* data structures, macros, #define's   */
// #include "globals.h"		/* alphabet global variables            */
// }

using namespace std;

//global argument variables
char *LLmap,*LAmap,*AEmap,*Seqs,*ReduxDecode,*ReduxEval;
char *Arch,*OutPrefix,*Dir,*AllSeqs,*ClassDesc;
char *BGComp,*Alphabet;
char **PosCat,**Include;
double MinDelta;
int ValidPath;
int NPosCat,NInclude,DBSize;
int ZWindow=500;
double ZMax=2.0;

// double SwissProt[]=
// 	{0.0761,0.0163,0.0526,0.0644,0.0409,
// 	 0.0686,0.0224,0.0584,0.0597,0.0950,
// 	 0.0237,0.0438,0.0490,0.0394,0.0519,
// 	 0.0709,0.0560,0.0661,0.0121,0.0316};

void PrintGlobals(ostream& out){
	out<<"OutPrefix: "<<OutPrefix<<endl;
	out<<"LLmap: "<<LLmap<<endl;
	out<<"LAmap: "<<LAmap<<endl;
	out<<"Seqs: "<<Seqs<<endl;
	out<<"Arch: "<<Arch<<endl;
	out<<"ReduxDecode: "<<ReduxDecode<<endl;
	out<<"ReduxEval: "<<ReduxEval<<endl;
	out<<"MinDelta: "<<MinDelta<<endl;
	out<<"ValidPath: "<<(bool)ValidPath<<endl;
	out<<"AllSeqs: "<<AllSeqs<<endl;
	out<<"ClassDesc: "<<ClassDesc<<endl;
	out<<"PosCats: ";
	for (int i=0;i<NPosCat-1;i++) out<<PosCat[i]<<", ";
	if (NPosCat>=1) {out<<PosCat[NPosCat-1]<<endl;}
	else {out<<"--none defined--"<<endl;}
	out<<"Background: "<<BGComp<<endl;
}


int WholeProtein(int argc,char** argv) {
	
	char fSeqs[256],fLLmap[256],fLAmap[256],fAEmap[256],
		fReduxDecode[256],fReduxEval[256],fArch[256],fOut[256],
		fClassDesc[256],fAS[256],
		fBGComp[256];

	Seq::InitSeq();

	//These are just buffers necessary for the function PrefixDir
	
	char *Seqspath=PrefixDir(Dir,Seqs,fSeqs);
	PrefixDir(Dir,LLmap,fLLmap);
	PrefixDir(Dir,LAmap,fLAmap);
	PrefixDir(Dir,AEmap,fAEmap);
	PrefixDir(Dir,ReduxDecode,fReduxDecode);
	PrefixDir(Dir,ReduxEval,fReduxEval);
	PrefixDir(Dir,Arch,fArch);
	OutPrefix=PrefixDir(Dir,OutPrefix,fOut);
	ClassDesc=PrefixDir(Dir,ClassDesc,fClassDesc);
	if (BGComp[0] != '\0') BGComp=PrefixDir(Dir,BGComp,fBGComp);
	char *AllSeqspath=PrefixDir(Dir,AllSeqs,fAS);
	char FileName[256]; //static but small

	strcpy(FileName,OutPrefix); //since OutPrefix is zero-terminated
	strcat(FileName,".sum"); //does this work?
	ofstream SumOut(FileName);
	if (!SumOut) Error ("Couldn't open ",FileName);
	PrintGlobals(SumOut);
	PrintGlobals(cout);

	
	try {Par::Init(fLLmap,fLAmap,fAEmap,fReduxDecode,fReduxEval,
				   fArch,Alphabet);}
	catch (string& errmsg){
		cerr<<errmsg<<endl;
		return 1;
	}


	//Load Training Sequences, Initialize Model
	cout<<"Initializing Model."<<endl;
	vector<TrainSeq> Trainvec;
	try{Trainvec=LoadTrainSeqs(Seqspath);}
	catch (string& errmsg){
		cerr<<errmsg<<endl;
		return 1;
	}
	string IDex="none";
	Par Model(Trainvec,Arch,IDex);
	///////////////////////////


	//Baum-Welch Training
	cout<<"Training Model."<<endl;
	double prev_score,cur_score=-HUGE_VAL,cur_delta=HUGE_VAL;
	vector<evaldat>wdat;
	double ROC_orig,ROC_mean,ROC_sd;

	//Baum-Welch training without whole-protein evaluation
	while (cur_delta>MinDelta){
		prev_score=cur_score;
		cur_score=0.0;
		cur_score+=Model.Update(Trainvec,IDex,ValidPath);
		cur_delta=abs(cur_score-prev_score);
		cout<<"current score: "<<cur_score<<endl;
	}
	/////////////////////


	//Load the category reduction file, pass CDesc to LoadOneSeq
	map<string,string>CDesc;
	ifstream CD(ClassDesc);
	if (!CD) Error ("Couldn't open ClassDescription File ",ClassDesc);
	string id,desc;
	char pdesc[1024];
	while (CD>>id) {
		GetUntilNot(CD," \t");
		CD.getline(pdesc,1024);
		desc=pdesc;
		CDesc[id]=desc;
	}
	CD.close();
	////////////////////////////


	//Load ClassCts;
	map<string,int> ClassCts;
	for (int i=0;i<NInclude;i++)
		ClassCts.insert(make_pair(string(Include[i]),0));
	///////////////////////////////						 
	

	//Load each Test Sequence and tabulate counts of total amino
	//acid composition, incrementing in M.AAComp
	//using a blank PosID
 	set<string> PosID;
 	Seq CurTestSeq;
 	ifstream TestIn;
	if (BGComp[0] == '\0'){
		TestIn.open(AllSeqspath);
		if (!TestIn) Error ("Couldn't open Test sequence file ",AllSeqs);
		while (TestIn.good()){
			CurTestSeq=LoadOneSeq(TestIn,PosID,CDesc);
			if (ClassCts.find(CurTestSeq.scl.ClassDesc)==
				ClassCts.end()) continue; //skips
			//cout<<CurTestSeq.scl.SeqID<<endl;
			Model.IncrComp(CurTestSeq);
		}
		TestIn.close();
	}

	else {
		char aa[1],line[35];
		float comp;
		ifstream BGIn;
		BGIn.open(BGComp);
		if (!BGIn) Error ("Couldn't open BGComp file",BGComp);
		while (BGIn.getline(line,35)){
			sscanf(line,"%c\t%f\n",aa,&comp);
			Model.AAComp[Model.AminoMap[aa[0]]]=(double)comp;
		}
	}
	////////////////////////////////////////////
	Normalize(&Model.AAComp[0],Par::NUMAMINO);

 	for (uint i=0;i<Par::NUMAMINO;i++) cout<<Model.AAComp[i]<<endl;

	
	

	//Load each Test Sequence and add it's score, length etc to wdat
	//print whole-protein predictions in Rdb format
// 	strcpy(FileName,OutPrefix); //since OutPrefix is zero-terminated
// 	strcat(FileName,".perres"); 
// 	ofstream Res(FileName);


	int NumPos=0;
	//class counts
	//number of proteins in that class
	cout<<"Decoding Test Sequences..."<<endl;
	for (int i=0;i<NPosCat;i++) PosID.insert(string(PosCat[i]));

	TestIn.open(AllSeqspath);
	if (!TestIn) Error ("Couldn't open Test sequence file ",AllSeqspath);
	while (TestIn.good()){
		CurTestSeq=LoadOneSeq(TestIn,PosID,CDesc);
		if (ClassCts.find(CurTestSeq.scl.ClassDesc)==
			ClassCts.end()) continue;
// 		cout<<"Tallying "<<CurTestSeq.scl.SeqID
// 			<<'\t'<<CurTestSeq.scl.Seqlen<<endl;
		ClassCts[CurTestSeq.scl.ClassDesc]++;
		Model.Forward(CurTestSeq,false); //simple decoding
		
		
 		if (CurTestSeq.scl.posQ) {
// 			CurTestSeq.Decode(Model);
// 			PrintRdb(Res,CurTestSeq,true); //print two-state prediction
 			NumPos++;
 		}


		wdat.push_back
			(evaldat
			 (CurTestSeq.scl.Set,
			  CurTestSeq.scl.SeqID,
			  CurTestSeq.scl.ClassDesc,
			  CurTestSeq.scl.posQ,
			  CurTestSeq.scl.Seqlen,
			  CurTestSeq.scl.Pbits,
			  0,
			  0));
	}
	//	Res.close();
	TestIn.close();
	////////////////////////////////////////

	//Create Z-curve and compute all z-scores from it.
	//store these scores by updating wdat
	set<pair<int,double> >RawScores;
	//	set<pair<int,double> >::iterator rit;
	int ind;
	for (ind=0;ind<(int)wdat.size();ind++){
		RawScores.insert(make_pair(wdat[ind].length,wdat[ind].pbits));
	}

	vector<pair<double,double> >Zcurve_data;
	strcpy(FileName,OutPrefix);
	strcat(FileName,".zcurve"); 

	try {
		Zcurve_data = Z_Calibrate(RawScores,ZWindow,ZMax);
		Par::PrintZCurve(Zcurve_data,FileName);
	}
	catch (string &errmsg){
		cerr<<errmsg<<endl;
		return 1;
	}

	//update wdat, create pdat and zdat
	vector<pair<double,string> >pdat(wdat.size()),zdat(wdat.size()); //Pair data used for Coverage Table
	for (ind=0;ind<(int)wdat.size();ind++){
		wdat[ind].zscore=CalcZScore(Zcurve_data,
									wdat[ind].length,
									wdat[ind].pbits);
		wdat[ind].evalscore=wdat[ind].zscore;
		pdat[ind].first=wdat[ind].pbits;
		pdat[ind].second=wdat[ind].cd;
		zdat[ind].first=wdat[ind].zscore;
		zdat[ind].second=wdat[ind].cd;
	}


	//append ClassCts[wdat[i].cd] to wdat[i].cd for all i
	string CDwithCts; //temporary for storing the classdesc with
	char Ctsbuf[10]; //buffer for holding the integer string of 
	for (uint i=0;i<wdat.size();i++){
		sprintf(Ctsbuf,"%d",ClassCts[wdat[i].cd]);
		wdat[i].cd+=' ';
		wdat[i].cd+=Ctsbuf;
	}
	///////////

	//print whole-protein scores
	map<string,vector<pair<double,double> > >pbits,zscore;
	for (uint i=0;i<wdat.size();i++){
		if (pbits.find(wdat[i].cd)==pbits.end()){
			pbits[wdat[i].cd]=vector<pair<double,double> >();
			zscore[wdat[i].cd]=vector<pair<double,double> >();
		}
 		pbits[wdat[i].cd].push_back
 			(make_pair(wdat[i].length,wdat[i].pbits));
 		zscore[wdat[i].cd].push_back
 			(make_pair(wdat[i].length,wdat[i].zscore));
	}

	strcpy(FileName,OutPrefix); //since OutPrefix is zero-terminated
	strcat(FileName,".pbits.gnu"); 
	PrintGnuplot(FileName,pbits,"Protein Length","Bits","points");

	strcpy(FileName,OutPrefix); //since OutPrefix is zero-terminated
	strcat(FileName,".zscore.gnu"); 
	PrintGnuplot(FileName,zscore,"Protein Length","Z-Score","points");

	strcpy(FileName,OutPrefix); //since OutPrefix is zero-terminated
	strcat(FileName,".pbits.txt"); 
	PrintKaleida(FileName,pbits,"Protein Length","Bits");

	map<string,map<int,int> >CT=CoverageTable(zdat);
	strcpy(FileName,OutPrefix); //since OutPrefix is zero-terminated
	strcat(FileName,".table.txt"); 
	PrintTable(CT,FileName);

	pbits.clear();
	zscore.clear();

	//print adjusted scores with sequence labels
	strcpy(FileName,OutPrefix); //since OutPrefix is zero-terminated
	strcat(FileName,".rdb"); 
	cout<<"Printing "<<FileName<<endl;
	ofstream Rdb(FileName);
	for (uint i=0;i<wdat.size();i++){
		Rdb<<wdat[i].id<<'\t'<<wdat[i].evalscore<<'\t'
		   <<wdat[i].cd<<endl;
	}
	Rdb.close();
	////////////////////////////////////////




	if (NumPos>0){
		int trunc=NumPos*2;
		//print roc curve with Darek's resampling w/ replacement
		vector<roc>rc=ROCResample(wdat,ROC_orig,ROC_mean,ROC_sd,1000);
		SumOut<<"ROC"<<trunc<<" Original: "<<ROC_orig<<", Mean: "<<ROC_mean<<" +/-"<<ROC_sd<<endl;
		cout<<"ROC"<<trunc<<" Original: "<<ROC_orig<<", Mean: "<<ROC_mean<<" +/-"<<ROC_sd<<endl;

		strcpy(FileName,OutPrefix); //since OutPrefix is zero-terminated
		strcat(FileName,".roc.txt"); //does this work?
		cout<<"Printing "<<FileName<<endl;
		ofstream RocOut(FileName);
		RocOut<<"False Positive Frequency (ROC"<<trunc
			  <<")\t"<<Seqs<<'/'<<AllSeqs<<" ROC_"<<trunc
			  <<" Original: "<<setprecision(3)<<100*ROC_orig
			  <<"; Resample: "<<setprecision(3)<<100*ROC_mean
			  <<" +/- "<<setprecision(3)<<100*ROC_sd<<"\r\n";
		for (uint i=0;i<rc.size();i++)
			RocOut<<rc[i].fpf<<'\t'<<rc[i].tpf<<"\r\n";
		RocOut.close();

		//print accuracy and coverage vs. score (bits)
		vector<pair<string,vector<double> > >AC(AccCov(wdat,true));
		strcpy(FileName,OutPrefix);
		strcat(FileName,".ac.txt");
		PrintKaleida(FileName,AC);
		strcpy(FileName,OutPrefix);
		strcat(FileName,".ac.gnu");
		PrintGnuplot(FileName,AC,"linespoints");
		//print score vs. coverage plot
 		map<string,vector<pair<double,double> > >svc=ScoCov(wdat);
 		strcpy(FileName,OutPrefix); //since OutPrefix is zero-terminated
 		strcat(FileName,".svc.gnu");
 		PrintGnuplot(FileName,svc,"Score","Coverage","linespoints");

 		strcpy(FileName,OutPrefix); //since OutPrefix is zero-terminated
 		strcat(FileName,".svc.txt"); //.txt is required for fucking MAC
 		PrintKaleida(FileName,svc,"Score","Coverage");
	}
	SumOut.close();

	return 0;
}


int main(int argc,char** argv){
	OptRegister(&Dir,OPT_STRING,'d',"directory-root","root path where all files reside");
	OptRegister(&Seqs,OPT_STRING,'s',"sequence-file","training/testing sequence file");
	OptRegister(&Arch,OPT_STRING,'r',"arch-file","file giving arch connections in sparse matrix form");
	OptRegister(&LLmap,OPT_STRING,'l',"label2label-map","label-to-label file");
	OptRegister(&LAmap,OPT_STRING,'a',"label2arch-map","label-to-arch file");
	OptRegister(&AEmap,OPT_STRING,'e',"arch-map","arch-to-emission file");
	OptRegister(&ReduxDecode,OPT_STRING,'t',"redux-decode","state reduction file for decoding");
	OptRegister(&ReduxEval,OPT_STRING,'u',"redux-eval","state reduction file for evaluation");
	OptRegister(&OutPrefix,OPT_STRING,'o',"outfile-prefix","file prefix to make output files");
	OptRegister(&MinDelta,OPT_DOUBLE,'i',"increment-min","minimum increment for Baum-Welch continuation");
	OptRegister(&ValidPath,OPT_BOOL,OPT_FLEXIBLE,'v',"validpath","if true, considers only valid paths during Baum-Welch");
	OptRegister(&AllSeqs,OPT_STRING,'w',"sequences-filename","file containing testing examples");
	OptRegister(&ClassDesc,OPT_STRING,'c',"class-description","file with protid->classdesc mapping");
	OptRegister(&BGComp,OPT_STRING,'n',"background-composition","file containing background rdb amino composition");
	OptRegister(&Alphabet,OPT_STRING,'x',"alphabet","sequence alphabet");
	optreg_array(&NPosCat,&PosCat,OPT_STRING,'p',"positive categories");
	optreg_array(&NInclude,&Include,OPT_STRING,'b',"categories to include in the analysis");
	optMain(WholeProtein);
	opt(&argc,&argv);
	return WholeProtein(argc,argv);
}
