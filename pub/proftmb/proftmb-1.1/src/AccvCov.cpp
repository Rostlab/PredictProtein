#include <iostream>
#include <sstream>
#include <set>
#include <cstdio>
#include "opt.h"
#include "Eval.h"
#include "Output.h"

//take in input files cd (ID   class description) and 
//score (ID    score) and create an accuracy vs. coverage plot

char *CD="",*SC="",*Plot="",**PosCat=0;
int DescendingQ=1,NPosCat=0;

int AccvCov(int argc,char** argv){

	//parse CD into map<string,string>CDmap
	char id[50],cdesc[256],line[256];
	map<string,string>CDmap;
	ifstream CDstream(CD);
	while (CDstream.getline(line,256)){
		sscanf(line,"%[^\t]\t%[^\t]\n",id,cdesc);
		CDmap[string(id)]=string(cdesc);
	}
	CDstream.close();

	//parse SC into map<string,float>SCmap
	float score;
	map<string,float>SCmap;
	ifstream SCstream(SC);
	while (SCstream.getline(line,256)){
		sscanf(line,"%s\t%f\n",id,&score);
		SCmap[string(id)]=score;
	}
	SCstream.close();

	//create set<string>PosCatSet from NPosCat
	set<string>PosCatSet;
	for (int i=0;i<NPosCat;i++)	PosCatSet.insert(string(PosCat[i]));

	//create vector<evaldat>ACdat using set<string>PosCatSet,CDmap, and SCmap
	vector<evaldat>ACdat;
	map<string,float>::iterator scit;
	bool posQ;
	string empty="",protID;
	
	for (scit=SCmap.begin();scit!=SCmap.end();scit++){
		if (CDmap.find(scit->first)==CDmap.end()){
			cerr<<"Couldn't find "<<scit->first<<" in class description file (option -c)"<<endl;
			exit(1);
		}

		if (PosCatSet.find(CDmap[scit->first])!=PosCatSet.end()){
			posQ=true;
			cout<<scit->first<<'\t'<<CDmap[scit->first]<<endl;
		}

		else posQ=false;
		protID=scit->first;
		ACdat.push_back(evaldat
						(empty,protID,CDmap[scit->first],posQ,0,
						 0.0,0.0,(double)scit->second));
	}

	//create vector<pair<string,vector<double> > >plot
	vector<pair<string,vector<double> > >plotdata=AccCov(ACdat);

	//print out gnuplot and kaleidagraph plot
	ostringstream fname;
	fname<<Plot<<".gnu";
	PrintGnuplot(fname.str().c_str(),plotdata,"linespoints");
	fname.str("");
	fname<<Plot<<".kg";
	PrintKaleida(fname.str().c_str(),plotdata);
	return 0;
}

int main(int argc,char** argv){
	OptRegister(&CD,OPT_STRING,'c',"class-description-file","rdb file containing id to class description mapping");
	OptRegister(&SC,OPT_STRING,'s',"score-file","rdb file with id to score mapping");
	OptRegister(&DescendingQ,OPT_BOOL,OPT_FLEXIBLE,'d',"descending-scores-true","true if higher scores are to be considered better");
	OptRegister(&Plot,OPT_STRING,'o',"output-file","output plot file with accuracy vs. coverage");
	optreg_array(&NPosCat,&PosCat,OPT_STRING,'p',"comma-separated list of positive categories");
	optMain(AccvCov);

	if (argc==1){
		char **myargv,*mybuf[2];
		mybuf[0]=argv[0];
		mybuf[1]="$";
		myargv=mybuf;
		int myargc=2;
		cout<<endl<<endl
			<<"Welcome to accvcov.  type '?' at the prompt for "
			<<"instructions on entering options."<<endl
			<<"----------------------------"<<endl<<endl;
		opt(&myargc,&myargv);
	}

	else opt(&argc,&argv);
	return AccvCov(argc,argv);
}
