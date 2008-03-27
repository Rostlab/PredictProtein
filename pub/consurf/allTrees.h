#ifndef ___ALL_TREES
#define ___ALL_TREES

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
class allTrees {
public:
	explicit allTrees(bool keepAllTrees = false);
	MDOUBLE getBestScore() {return _bestScore;}
	tree getBestTree() {return _bestTree;}

	void getAllTreesAndLikelihoods(vector<tree>& resTree,vector<MDOUBLE> & scores) {
		resTree = _allPossibleTrees;
		scores = _allPossibleScores;
	}

	void recursiveFind(	tree et,
						const stochasticProcess& sp,
						const sequenceContainer1G& sc,
						vector<int> idLeft,
						const Vdouble * weights = NULL,
						const int maxIterations=1000,
						const MDOUBLE epsilon=0.05);

	void recursiveFind(	const sequenceContainer1G* sc,
						const stochasticProcess* sp,
						const Vdouble * weights = NULL,
						const int maxIterations=1000,
						const MDOUBLE epsilon=0.05); // one tree.
	


private:
	tree _bestTree;
	MDOUBLE _bestScore;
	vector<tree> _allPossibleTrees;
	vector<MDOUBLE> _allPossibleScores;
	const bool _keepAllTrees;


	MDOUBLE evalTree(tree& et,
					const stochasticProcess& sp,
					const sequenceContainer1G& sc,
					const int maxIterations,
					const MDOUBLE epsilon,
					const Vdouble * weights = NULL);




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
