#ifndef ___RATE_4_SITE____H
#define ___RATE_4_SITE____H

//#include "computeLgivenR.h"
#include "rate4siteOptions.h"
#include "definitions.h"
#include "alphabet.h"
#include "sequenceContainer1G.h"
#include "treeInterface.h"
#include "stochasticProcess.h"

using namespace treeInterface;
class rate4site {

public:
	explicit rate4site(int argc, char* argv[]);
	virtual ~rate4site() { delete _alph;}
private:
	MDOUBLE computeRate4site();
	MDOUBLE computeRate4sitePosterior();
	sequenceContainer1G _sd;
	tree _t1;
	stochasticProcess* _sp;

	void getStartingStochasticProcess();
	void getStartingEvolTree();

	void printrate4siteInfo(ostream& out);
	void fillOptionsParameters(int argc, char* argv[]);
	const rate4siteOptions* _options;
	void printOptionParameters();
	void getStartingSequenceData();
	MDOUBLE computePosReliability(const int pos);
	alphabet* _alph;

	// TREE SEARCH PART
	void getStartingNJtreeNjJC();
	void getStartingNJtreeNjJC_old(); // THIS IS THE OLD VERSION OF RATE4SITE.
	void getStartingTreeFromTreeFile();
	void getStartingTreeNJ_fromDistances(const VVdouble& disTab,const vector<string>& vNames);
	void getStartingNJtreeNjMLdis();
	void getStartingMLtreeFromManyNJtrees();
	
	void removePositionInRateVectorWithGaps(vector<MDOUBLE>& withoutGaps,vector<MDOUBLE>& reliaWithoutGaps);
	void normalizeRates(vector<MDOUBLE>& vecToNormalize);
	void printRates(const vector<MDOUBLE>& rate2prints,
		const vector<MDOUBLE>& reliaWithoutGaps,
		ostream& out);
	Vdouble _Lrate;
	Vdouble _rate;
	Vdouble _Lreliability;
};


#endif
