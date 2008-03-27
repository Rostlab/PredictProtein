#include <vector>
#include <unistd.h>
#include <string>
#include <iostream>
#include <iomanip>
#include <cmath>
#include <sstream>
#include <dirent.h>
#include <sys/stat.h>
#include <cstdio>
#include "Seq.h"
#include "Par.h"
#include "Load.h"
#include "Output.h"
#include "opt.h"
#include "Tools.h"


using namespace std;

//global argument variables
char *TestQName;


int Composition(int argc,char** argv) {

	Par::Init("ACDEFGHIKLMNPQRSTVWXY");

	vector<float>AAComp(Par::NUMAMINO);

	//Read in each Test Sequence, evaluate and print out results
	struct stat Qstat;
	const char *Path; //for constructing the path
	Seq CurTestSeq;
	ostringstream sspath;  //can't use unistd.h chdir, not windows compatible...
	string spath;
	uint c,t;
	if (stat(TestQName,&Qstat)) {
		cerr<<"Couldn't stat() "<<TestQName<<" (option -q)."<<endl;
		return 1;
	}

	if ((Qstat.st_mode & S_IFMT) == S_IFDIR){
		struct stat Dstat;
		DIR *Qdir;
		dirent *Qdirent;
		Qdir=opendir(TestQName);
		while ((Qdirent=readdir(Qdir))){
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
					//increment composition
					for (t=0;t<CurTestSeq.scl.Seqlen;t++)
						for (c=0;c<Par::NUMAMINO;c++)
							AAComp[c]+=CurTestSeq.Profile[t][c];
				}
				catch (string& errmsg){
					cout<<"Skipping non-Profile file "<<Path<<"."<<endl;
				}
			}
			else if ((Dstat.st_mode & S_IFMT)==S_IFDIR)
				cout<<"Skipping subdirectory "<<Qdirent->d_name<<"."<<endl;
			else cout<<"Skipping other type "<<Qdirent->d_name<<"."<<endl;
		}
	}
	else if ((Qstat.st_mode & S_IFMT) == S_IFREG){
		CurTestSeq=Seq(TestQName,TestQName);
	}
	else { 
		cerr<<TestQName<<
			", (option -q) is neither a directory nor a regular file."<<endl;
		return 1;
	}

	////////////////////////////////////////////
	char aa[]="ACDEFGHIKLMNPQRSTVWY";

 	for (uint i=0;i<(sizeof(aa)/sizeof(char))-1;i++)
		cout<<aa[i]<<'\t'<<AAComp[i]<<endl;

	Normalize(&AAComp[0],Par::NUMAMINO);

 	for (uint i=0;i<(sizeof(aa)/sizeof(char))-1;i++)
		cout<<aa[i]<<'\t'<<AAComp[i]<<endl;


	return 0;
}


int main(int argc,char** argv){
	OptRegister(&TestQName,OPT_STRING,'q',"test-blastQ-file-or-dir","Q file or directory containing multiple Q files");
	optMain(Composition);
	opt(&argc,&argv);
	return Composition(argc,argv);
}
