#ifndef ___NNI
#define ___NNI

#include "treeInterface.h"
#include "sequenceContainer1G.h"
#include "definitions.h"
#include "stochasticProcess.h"
#include <vector>
using namespace treeInterface;
using namespace std;

class NNI {
public:
	explicit NNI(const sequenceContainer1G& sc,
				   const stochasticProcess& sp,
				const Vdouble * weights);

	tree NNIstep(tree et);
	MDOUBLE bestScore(){ return _bestScore;} 

private:
	tree _bestTree;
	MDOUBLE _bestScore;
	const sequenceContainer1G& _sc;
	const stochasticProcess& _sp;
	const Vdouble * _weights;
	MDOUBLE evalTree(tree& et,const sequenceContainer1G& sd);
	tree NNIswap1(tree et,tree::nodeP mynode);
	tree NNIswap2(tree et,tree::nodeP mynode);
};
#endif
