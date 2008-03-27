#ifndef ___FAST_START_TREE
#define ___FAST_START_TREE


#include "stochasticProcess.h"
#include "sequenceContainer1G.h"
#include "treeInterface.h"
#include <iostream>

using namespace std;
using namespace treeInterface;



tree getBestMLTreeFromManyNJtrees(sequenceContainer1G & allTogether,
								stochasticProcess& sp,
								const int numOfNJtrees,
								const MDOUBLE tmpForStartingTreeSearch,
								const MDOUBLE epslionWeights,
								ostream& out);


#endif
