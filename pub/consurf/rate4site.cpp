//#include "computeDistance.h"
//#include "likelihoodComputation.h"
#include "errorMsg.h"
#include "rate4site.h"
#include "nucleotide.h"
#include "amino.h"
#include "sequenceContainer1G.h"
#include "maseFormat.h"
#include "molphyFormat.h"
#include "clustalFormat.h"
#include "fastaFormat.h"
#include "phylipFormat.h"
#include "uniDistribution.h"
#include "readDatMatrix.h"
#include "chebyshevAccelerator.h"
#include "nucJC.h"
#include "aaJC.h"
#include "trivialAccelerator.h"
#include "jcDistance.h"
#include "distanceTable.h"
#include "nj.h"
#include "numRec.h"
#include "checkcovFanctors.h"
#include "someUtil.h"
#include "likeDist.h"
#include "fastStartTree.h"

#include "checkcovFanctorsWithFactors.h"

#include <iostream>
#include <cassert>
using namespace std;

rate4site::rate4site(int argc, char* argv[]) {

	fillOptionsParameters(argc,argv);
	printrate4siteInfo(cout);
	printOptionParameters();
	getStartingSequenceData();
	getStartingStochasticProcess();// must be b4 the tree!
	getStartingEvolTree();
	computeRate4site();
	vector<MDOUBLE> withoutGaps;
	vector<MDOUBLE> reliabilityWithoutGaps;
	removePositionInRateVectorWithGaps(withoutGaps,reliabilityWithoutGaps);
	ofstream outWithoutGap(_options->outFileNotNormalize.c_str());
	printRates(withoutGaps,reliabilityWithoutGaps,outWithoutGap);
	outWithoutGap.close();
	normalizeRates(withoutGaps);
	printRates(withoutGaps,reliabilityWithoutGaps,_options->out());
}

void rate4site::printrate4siteInfo(ostream& out) {
	out<<endl;
	out<<" ======================================================="<<endl;
	out<<" the rate for site project:                             "<<endl;
	out<<" Tal Pupko and his lab:     talp@post.tau.ac.il         "<<endl;
	out<<" Nir Ben-Tal and his lab:   bental@ashtoret.tau.ac.il   "<<endl;
	out<<" ======================================================="<<endl;
	out<<endl;
}

void rate4site::fillOptionsParameters(int argc, char* argv[]) {
	_options = new rate4siteOptions(argc, argv);
}

void rate4site::printOptionParameters() {
	cout<<"\n ---------------------- THE PARAMETERS ----------------------------"<<endl;
	if (_options->treefile.size()>0) cout<<"tree file is : "<<_options->treefile<<endl;
	if (_options->seqfile.size()>0) cout<<"seq file is : "<<_options->seqfile<<endl;
	if (_options->outFile.size()>0) cout<<"output file is : "<<_options->outFile<<endl;
	if 	(strcmp(_options->referenceSeq.c_str(),"non")!=0) cout<<"reference sequence : "<<_options->referenceSeq<<endl;
	switch (_options->modelName){
		case (rate4siteOptions::day): cout<< "probablistic_model = DAY" <<endl; break;
		case (rate4siteOptions::jtt): cout<< "probablistic_model = JTT" <<endl; break;
		case (rate4siteOptions::rev): cout<< "probablistic_model = REV" <<endl; break;
		case (rate4siteOptions::aajc): cout<< "probablistic_model = AAJC" <<endl; break;
		case (rate4siteOptions::nucjc): cout<< "probablistic_model = NUCJC" <<endl; break;
	}

	if (_options->removeGaps) {
		cout<<" positions with gaps were removed from the analysis."<<endl;
		cout<<" the number of each position in the results refers to the gapless alignment."<<endl;
	}
	else {
		cout<<"(gaps characters were treated as missing data.)"<<endl;
	}

	cout<<"\n -----------------------------------------------------------------"<<endl;
}

void rate4site::getStartingSequenceData(){
	if (_options->seqfile == "") {
		errorMsg::reportError("Please give a sequence file name in the command line");
	}
	ifstream in(_options->seqfile.c_str());
	int alphabetSize = _options->alphabet_size;
	if (alphabetSize==4) _alph = new nucleotide;
	else if (alphabetSize == 20) _alph = new amino;
	else errorMsg::reportError("no such alphabet in function rate4site::getStartingSequenceData");

	sequenceContainer1G original;
	switch (_options->seqInputFormat) {
	case rate4siteOptions::mase: 
			original= maseFormat::read(in,_alph);
			break;
	case rate4siteOptions::molphy: 
			original=molphyFormat::read(in,_alph);
			break;
	case rate4siteOptions::clustal: 
			original=clustalFormat::read(in,_alph);
			break;
	case rate4siteOptions::fasta: 
			original=fastaFormat::read(in,_alph);
			break;
	case rate4siteOptions::phylip: 
			original=phylipFormat::read(in,_alph);
			break;
	default: errorMsg::reportError(" format not implemented yet in this version... ",1);
	}

	if (_options->removeGaps) {
//		vector<int> parCol;
//		original.getParticiantColVecAccordingToGapCols(parCol);
//		_sd = new sequenceData(original,parCol);
		errorMsg::reportError("removeGaps currently not implemented");
	} else {
		original.changeGapsToMissingData();
		_sd = original;
	}
}

//	void makeSureTreeIsBiFurcatingAndUnrooted();
void rate4site::getStartingStochasticProcess() {
	distribution *dist = NULL;
	switch (_options->distributionName){
	case (rate4siteOptions::hom): dist =  new uniDistribution; break;
		default: errorMsg::reportError("this distribution name is not yet available");

	}

	replacementModel *probMod=NULL;
	pijAccelerator *pijAcc=NULL;
	switch (_options->modelName){
		case (rate4siteOptions::day):
			probMod=new pupAll(datMatrixHolder::dayhoff);pijAcc = new chebyshevAccelerator(probMod); break;
		case (rate4siteOptions::jtt):
			probMod=new pupAll(datMatrixHolder::jones); pijAcc = new chebyshevAccelerator(probMod); break;
		case (rate4siteOptions::rev):
			probMod=new pupAll(datMatrixHolder::mtREV24); pijAcc = new chebyshevAccelerator(probMod); break;
		case (rate4siteOptions::wag):
			probMod=new pupAll(datMatrixHolder::wag); pijAcc = new chebyshevAccelerator(probMod); break;
		case (rate4siteOptions::cprev):
			probMod=new pupAll(datMatrixHolder::cpREV45); pijAcc = new chebyshevAccelerator(probMod); break;
		case (rate4siteOptions::nucjc):
			probMod=new nucJC; pijAcc = new trivialAccelerator(probMod); break;
		case (rate4siteOptions::aajc):
			probMod=new aaJC; pijAcc = new trivialAccelerator(probMod); break;
		default:
			errorMsg::reportError("this probablistic model is not yet available");
	}
	_sp = new stochasticProcess(dist, pijAcc);


	if (probMod) delete probMod;
	if (pijAcc) delete pijAcc;
	if (dist) delete dist;}



void rate4site::getStartingEvolTree(){
	if (strcmp(_options->treefile.c_str(),"")==0) {
		switch (_options->treeSearchAlg){
			case (rate4siteOptions::njJC):
				getStartingNJtreeNjJC(); 
				break;
			case (rate4siteOptions::njJCOLD):
				getStartingNJtreeNjJC_old(); 
				break;
			case (rate4siteOptions::njML): {
					
					getStartingNJtreeNjMLdis();
				}
				break;
			case (rate4siteOptions::MLfromManyNJ): {
				cerr<<"computing the ML tree... "<<endl;
				getStartingMLtreeFromManyNJtrees();
				}break;
			default:
				errorMsg::reportError("this tree search mode is not yet available");
		}
	}
	else getStartingTreeFromTreeFile();
}

void rate4site::getStartingNJtreeNjJC() {
	jcDistance pd1(_options->alphabet_size);
	VVdouble disTab;
	vector<string> vNames;
	giveDistanceTable(&pd1,
					   _sd,
					   disTab,
					   vNames);
	getStartingTreeNJ_fromDistances(disTab,vNames);
} 

void rate4site::getStartingNJtreeNjJC_old() {
	jcDistanceOLD pd1(_options->alphabet_size);
	VVdouble disTab;
	vector<string> vNames;
	giveDistanceTable(&pd1,
					   _sd,
					   disTab,
					   vNames);
	getStartingTreeNJ_fromDistances(disTab,vNames);
} 

void rate4site::getStartingNJtreeNjMLdis() {
	likeDist pd1(_options->alphabet_size,*_sp,0.01);
	VVdouble disTab;
	vector<string> vNames;
	giveDistanceTable(&pd1,
					   _sd,
					   disTab,
					   vNames);
	getStartingTreeNJ_fromDistances(disTab,vNames);
}

void rate4site::getStartingMLtreeFromManyNJtrees() {
	 int numOfNJtrees = 30;
	 if (_sd.numberOfSequences() <4) numOfNJtrees = 1;
	 else if (_sd.numberOfSequences() <5) numOfNJtrees = 3;
	 else if (_sd.numberOfSequences() <6) numOfNJtrees = 15;
	 else if (_sd.numberOfSequences() <30) numOfNJtrees = 75;
	 else if (_sd.numberOfSequences() <50) numOfNJtrees = 15;
	 else numOfNJtrees = 5;

	 const MDOUBLE tmpForStartingTreeSearch = 1;
	 const MDOUBLE epslionWeights = 0.05;
	_t1 = getBestMLTreeFromManyNJtrees(_sd,
								*_sp,
								numOfNJtrees,
								tmpForStartingTreeSearch,
								epslionWeights,
								cerr);
	cerr<<"number of tree evaluated: "<<numOfNJtrees<<endl;
	ofstream f;
	string fileName1=_options->treeOutFile;
	f.open(fileName1.c_str());
	_t1.output(f);
	f.close();
	cout<<"The tree was written to a file name called "<<fileName1<<endl;
}

void rate4site::getStartingTreeNJ_fromDistances(const VVdouble& disTab,
	const vector<string>& vNames) {
	NJalg nj1;
	_t1= nj1.computeNJtree(disTab,vNames);
	ofstream f;
	string fileName1=_options->treeOutFile;
	f.open(fileName1.c_str());
	_t1.output(f);
	f.close();
	cout<<"The tree was written to a file name called "<<_options->treeOutFile<<endl;
}

void rate4site::getStartingTreeFromTreeFile(){
	_t1= tree(_options->treefile);
	if (!_t1.WithBranchLength()) _t1.createFlatLengthMatrix(0.05);
}

MDOUBLE rate4site::computeRate4site(){
	_rate.resize(_sd.seqLen());
	_Lrate.resize(_sd.seqLen());
	_Lreliability.resize(_sd.seqLen()); // how relialbe is each computation.
	MDOUBLE Lsum = 0.0;

//	computeLgiveR computeLgiveR1;
//	positionInfo pi(_sp,_t1,_sd);

	for (int pos=0; pos < _sd.seqLen(); ++pos) {
		cerr<<".";
		MDOUBLE ax=0.0f,bx=5.0f,cx=20.0f,tol=0.0001f;
		MDOUBLE maxR1=-1.0; // tree1
		//MDOUBLE LmaxR1=
		//	brent(ax,bx,cx,Cevaluate_L_given_r(_sd,_t1,*_sp,pos),tol,&maxR1);
		MDOUBLE LmaxR1=
			brent(ax,bx,cx,Cevaluate_LOG_L_given_r(_sd,_t1,*_sp,pos),tol,&maxR1);



		_Lrate[pos] = -LmaxR1;
		_rate[pos] = maxR1;
		Lsum += _Lrate[pos];
		_Lreliability[pos] = computePosReliability(pos);
		
		cerr<<" rate of pos: "<<pos<<" = "<<_rate[pos]<<endl;

	}
	cerr<<" number of sites: "<<_sd.seqLen()<<endl;
	return Lsum;
}

#include "likelihoodComputation.h"
using namespace likelihoodComputation;
MDOUBLE rate4site::computeRate4sitePosterior(){// new addition
	if (_sp->categories() == 1) {
		errorMsg::reportError("gamma distribution must be given in order to run this posterior version!");
	}
	_rate.resize(_sd.seqLen());
	_Lrate.resize(_sd.seqLen());
	_Lreliability.resize(_sd.seqLen()); // how relialbe is each computation.
	MDOUBLE Lsum = 0.0;


	for (int pos=0; pos < _sd.seqLen(); ++pos) {
		cerr<<".";
		MDOUBLE posteriorAverage=0.00;
		MDOUBLE check=0;
		for (int cat =0; cat < _sp->categories() ; ++cat) {
			MDOUBLE posteriorProbGivenRate = 
				likelihoodComputation::getLofPos(pos,_t1,_sd,*_sp,_sp->rates(cat));
			check += posteriorProbGivenRate;
			posteriorAverage += _sp->rates(cat) * posteriorProbGivenRate;
		}

		if (check != 1.0) {
			cerr<<" check that is suppose to be eq 1 is eq to: "<<check<<endl;
			errorMsg::reportError("error in function computeRate4sitePosterior - sum of posterior != 1");
		}
		_rate[pos] = posteriorAverage;
		_Lreliability[pos] = computePosReliability(pos);
		
		//cerr<<" rate of pos: "<<pos<<" = "<<_rate[pos]<<endl;

	}
	cerr<<" number of sites: "<<_sd.seqLen()<<endl;
	return Lsum;
}

MDOUBLE rate4site::computePosReliability(const int pos) {
	MDOUBLE numOfNonCharPos = _sd.numberOfSequences();
	for (int i=0; i < _sd.numberOfSequences(); ++i) {
		if (_sd[i][pos] <0) --numOfNonCharPos;
	}
	return numOfNonCharPos;
}

void rate4site::normalizeRates(vector<MDOUBLE>& vecToNormalize) {


	MDOUBLE ave = computeAverage(vecToNormalize);
	MDOUBLE std = computeStd(vecToNormalize);
//	for (int z=0; z < vecToNormalize.size(); ++z) {
//		cerr<<vecToNormalize[z]<<"   ";
//	}
//	cerr<<" ave =  "<<ave<<endl;
//	cerr<<" std = " <<std<<endl; 
//	exit(0);
	int i=0;
	if (std==0) errorMsg::reportError(" std = 0 in function normalizeRates",1);
	for (i=0;i<vecToNormalize.size();++i) {
		vecToNormalize[i]=(vecToNormalize[i]-ave)/std;
	}
}

void rate4site::removePositionInRateVectorWithGaps(vector<MDOUBLE>& withoutGaps,
												   vector<MDOUBLE>& reliaWithoutGaps) {
	assert(withoutGaps.size() == 0);
	int i;
	const sequence* s = NULL;
	if (strcmp(_options->referenceSeq.c_str(),"non")==0) {
		s = &(_sd[0]);
	}
	else {
		int id1 = _sd.getId(_options->referenceSeq,true);
		s = (&_sd[id1]);
	}
	for (i=0; i < _rate.size(); ++i) {
		if ((*s)[i]!=s->getAlphabet()->unknown()) {// gap position
			withoutGaps.push_back(_rate[i]);
			reliaWithoutGaps.push_back(_Lreliability[i]);

		}
	}
}

void rate4site::printRates(const vector<MDOUBLE>& rate2prints,
						   const vector<MDOUBLE>& reliaWithoutGaps,
						   ostream& out) {
	const sequence* s = NULL;
	if (strcmp(_options->referenceSeq.c_str(),"non")==0) {
		s = (&_sd[0]);
	}
	else {
		int id1 = _sd.getId(_options->referenceSeq,true);
		s = (&_sd[id1]);
	}
	
	int posInBigSeq=-1;

	//cerr<<" size = "<< rate2prints.size(); exit(0);

	for (int i=0; i < rate2prints.size(); ++i) {
		posInBigSeq++;
		//_options->out()<<i+1;
		out<<i+1;
			
//		_options->out()<<" ";
		out<<" ";
		while ((*s)[posInBigSeq] == s->getAlphabet()->unknown()) {
			posInBigSeq++;
		}

		out<<s->getAlphabet()->fromInt((*s)[posInBigSeq]);
//		_options->out()<<s->getAlphabet()->fromInt((*s)[posInBigSeq]);
		for (int k=0; k < 3; ++k) out<<" ";
//		for (int k=0; k < 3; ++k) _options->out()<<" ";
		MDOUBLE tmpRate = rate2prints[i];
//		if (tmpRate<1e-9) tmpRate=0;
//		_options->out()<<tmpRate<<endl; // note position start from 1.
		out<<tmpRate<<"\t"<<reliaWithoutGaps[i]<<"/"<<_sd.numberOfSequences()<<endl; // note position start from 1.
//		_options->out()<<tmpRate<<"\t"<<reliaWithoutGaps[i]<<"/"<<_sd.numberOfSequences()<<endl; // note position start from 1.
	}
	MDOUBLE ave = computeAverage(rate2prints);
	MDOUBLE std = computeStd(rate2prints);
	if (((ave<1e-9)) && (ave>(-(1e-9)))) ave=0;
	if ((std>(1-(1e-9))) && (std< (1.0+(1e-9)))) std=1.0;
	//_options->out()<<"Average = "<<ave<<endl;
	//_options->out()<<"Standard Deviation = "<<std<<endl;
	out<<"Average = "<<ave<<endl;
	out<<"Standard Deviation = "<<std<<endl;
}

		




