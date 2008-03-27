#include "allTreesSeparateModel.h"
#include "brLenOptEM.h"
#include <algorithm>
#include <iostream>

#include "someUtil.h"

using namespace brLenOptEM;
using namespace std;
#define VERBOS

allTreesSeparateModel::allTreesSeparateModel(){
	_bestScore = VERYSMALL;
}

void allTreesSeparateModel::recursiveFind(	const vector<sequenceContainer1G>* sc,
								const vector<stochasticProcess>* sp,
								const vector<Vdouble* > * weights,
								const int maxIterations,
								const MDOUBLE epsilon){
	tree starT;
	vector<int> ids;
	get3seqTreeAndIdLeftVec(&(*sc)[0],starT,ids);
	recursiveFind(starT,*sp,*sc,ids,weights,maxIterations,epsilon);
}

void allTreesSeparateModel::recursiveFind(tree et,
							 const vector<stochasticProcess>& sp,
							 const vector<sequenceContainer1G>& sc,
							 vector<int> idLeft,
							 const vector<Vdouble* > * weights,
							 const int maxIterations,
							 const MDOUBLE epsilon) {

	if (idLeft.empty()) {
		//static int k=1;	k++;
		MDOUBLE treeScore = evalTree(et,sp,sc,maxIterations,epsilon,weights);
		//cerr<<"tree: "<<k<<" l= "<<treeScore<<endl;
		cerr<<".";
		if (treeScore > _bestScore) {
			//cerr<<"new Best score!"<<endl;
			_bestTree = et;
			_bestScore = treeScore;
			_treeVecBest = _treeVecTmp; // keep the seperate trees too.
		}
	} else {
		et.create_names_to_internal_nodes();
		treeIterTopDown tIt(et);
		tree::nodeP mynode = tIt.first();
		mynode = tIt.next(); // skipping the root
		for (; mynode != tIt.end(); mynode = tIt.next()) {
			int NameToAdd = idLeft[idLeft.size()-1]; 
			tree newT = getAnewTreeFrom(et,mynode,idLeft,sc[0][NameToAdd].name());
			recursiveFind(newT,sp,sc,idLeft,weights,maxIterations,epsilon);
			idLeft.push_back(NameToAdd);
		}
	}
}

MDOUBLE allTreesSeparateModel::evalTree(	tree& et,
							const vector<stochasticProcess>& sp,
							const vector<sequenceContainer1G>& sc,
							const int maxIterations,
							const MDOUBLE epsilon,
							const vector<Vdouble* > * weights) {
	MDOUBLE res = 0;
	vector<tree> tVec;
	for (int k=0; k < sc.size(); ++k ) tVec.push_back(et);
	res = brLenOptEM::optimizeBranchLengthNG_EM_SEP(tVec,sc,sp,weights,maxIterations,epsilon);
	_treeVecTmp = tVec;
	return res;
}	




