#include "Load.h"
#include "Tools.h"
#include "Seq.h"


vector<TrainSeq> LoadTrainSeqs(char* tf){
	//call Read, then iterate through the map,
	//call Seq, push_back to the vector
	vector<TrainSeq>seqs;
	set<string>emptyset;
	map<string,string>nomap;
	map<string,multimap<string,string> >dat(Seq::Read(tf));
	map<string,multimap<string,string> >::iterator idat;

	for (idat=dat.begin();idat!=dat.end();idat++){
		//cout<<"Loading "<<idat->first<<endl;
		seqs.push_back
			(TrainSeq(idat->second,idat->first,emptyset,nomap));
	}
	return seqs;
}



Seq LoadOneSeq(ifstream& ifile,set<string>& posID,
			   map<string,string>& cred){
	//call ReadOne, make a Seq and return it.
	if (! ifile.good()) return Seq();
	pair<string,multimap<string,string> >one(Seq::ReadOne(ifile));
	return Seq(one.second,one.first,posID,cred);
}
