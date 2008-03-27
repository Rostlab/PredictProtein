#ifndef ___ALL_TREES_SEPARATE_MODEL
#define ___ALL_TREES_SEPARATE_MODEL

#include "treeInterface.h"
#include "sequenceContainer1G.h"
#include "definitions.h"
#include "stochasticProcess.h"
#include <vector>
using namespace treeInterface;
using namespace std;

void get3seqTreeAndIdLeftVec(const sequenceContainer1G* sc,
							 tree& starT,
							 vector<int>& idList);

	tree getAnewTreeFrom(	const tree& et,
							tree::nodeP & mynode,
							vector<int> & idLeft,
							const string& nameToAdd);


class allTreesSeparateModel {
public:
	explicit allTreesSeparateModel();
	MDOUBLE getBestScore() {return _bestScore;}
	tree getBestTree() {return _bestTree;}
	
	void recursiveFind(tree et,
							 const vector<stochasticProcess>& sp,
							 const vector<sequenceContainer1G>& sc,
							 vector<int> idLeft,
							 const vector<Vdouble* > * weights=NULL,
							 const int maxIterations=1000,
							 const MDOUBLE epsilon=0.05);

	void recursiveFind(	const vector<sequenceContainer1G>* sc,
								const vector<stochasticProcess>* sp,
								const vector<Vdouble* > * weights= NULL,
								const int maxIterations=1000,
								const MDOUBLE epsilon=0.05); // one tree.

	vector<tree> getTreeVecBest() {return _treeVecBest;}

private:
	tree _bestTree;
	MDOUBLE _bestScore;
	vector<tree> _treeVecTmp; // same tree topologies, diff branch lengths
	vector<tree> _treeVecBest;// same tree topologies, diff branch lengths


	MDOUBLE evalTree(	tree& et,
							const vector<stochasticProcess>& sp,
							const vector<sequenceContainer1G>& sc,
							const int maxIterations,
							const MDOUBLE epsilon,
							const vector<Vdouble* > * weights = NULL);

};
#endif

	//	const stochasticProcess* _sp;
	//const sequenceContainer1G* _sc;
	//const Vdouble * _weights;

	//vector<tree> getBestTreesSep() {return _bestSepTrees;}
	//vector<tree> _bestSepTrees;
	//vector<tree> _tmpSepTrees;
	//vector<tree> recursiveFindSep(const vector<sequenceContainer1G>* sc,
	//							const vector<stochasticProcess>* sp,
	//							const vector<Vdouble *> * weights,
	//							const int maxIterations=1000,
	//							const MDOUBLE epsilon=0.05); // sep model
	//const vector<sequenceContainer1G>* _scVec;
	//vector<stochasticProcess>* _spVec; // not const, so in proportional for example it can be changed.
	//const vector<Vdouble *> * _weightsVec;
