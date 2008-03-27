#ifndef ___BEST_ALPHA_MANY_TREES
#define ___BEST_ALPHA_MANY_TREES

#include "treeInterface.h"
#include "computePijComponent.h"
#include "sequenceContainer1G.h"
#include "sequenceContainerNG.h"
#include "brLenOptEM.h"
#include "gammaDistribution.h"
#include "likelihoodComputation.h"

using namespace likelihoodComputation;
using namespace brLenOptEM;
using namespace treeInterface;

//#define VERBOS
namespace bestAlpha {
/*	void optimizeAlpha1G_EM(	tree& et,
									const sequenceContainer1G& sc,
									const stochasticProcess& sp,
									const Vdouble * weights,
									MDOUBLE & bestAlpha,
									MDOUBLE & likelihoodScore,
									const int maxIterations=1000,
									const MDOUBLE epsilon=0.05);
*/
	void optimizeAlphaNG_EM_SEP(vector<tree>& et,
									vector<sequenceContainer1G>& sc,
									vector<stochasticProcess> &sp,
									const vector<Vdouble *> * weights,
									MDOUBLE & bestAlpha,
									MDOUBLE & likelihoodScore,
									const int maxIterations=1000,
									const MDOUBLE epsilon=0.05);
	void optimizeAlphaNG_EM_PROP(tree& et,// 1 alpha for all trees!
									vector<sequenceContainer1G>& sc,
									vector<stochasticProcess>& sp,
									const vector<Vdouble *> * weights,
									MDOUBLE & bestAlpha,
									MDOUBLE & likelihoodScore,
									const int maxIterations=1000,
									const MDOUBLE epsilon=0.05);
	void optimizeAlphaNG_EM_PROP_n_alpha(tree& et,// alpha for each trees!
									vector<sequenceContainer1G>& sc,
									vector<stochasticProcess>& sp,
									const vector<Vdouble *> * weights,
									vector<MDOUBLE> & bestAlpha,
									MDOUBLE & likelihoodScore,
									const int maxIterations=1000,
									const MDOUBLE epsilon=0.05);
};

#include <iostream>// for debugging
using namespace std; // for debugging

class C_evalAlphaManyTrees{
public:
  C_evalAlphaManyTrees(tree& et,
		vector<sequenceContainer1G>& sc,
		vector<stochasticProcess>& sp,
		const vector<Vdouble *> * weights)
    : _et(et),_sc(sc),_sp(sp),_weights(weights) {};
private:
	const tree& _et;
	const vector<sequenceContainer1G>& _sc;
	vector<stochasticProcess>& _sp;
	const vector<Vdouble *> * _weights;
public:
	MDOUBLE operator() (MDOUBLE alpha) {
		#ifdef VERBOS
			cerr<<"trying alpha: "<<alpha<<endl;
		#endif
		MDOUBLE res=0;
		for (int i=0; i < _sc.size();++i) {

			if (_sp[i].categories() == 1) {
				errorMsg::reportError(" one category when trying to optimize alpha");
			}
			(static_cast<gammaDistribution*>(_sp[i].distr()))->setAlpha(alpha);
			res += likelihoodComputation::getTreeLikelihoodAllPosAlphTheSame(_et,_sc[i],_sp[i],_weights?(*_weights)[i]:NULL);
		}
		#ifdef VERBOS
			cerr<<"likelihood = "<<-res<<endl;
		#endif
		return -res;
	}
};

class C_evalAlphaManyTreesSep{ // separate model, 1 gamma
public:
  C_evalAlphaManyTreesSep(vector<tree>& et,
		vector<sequenceContainer1G>& sc,
		vector<stochasticProcess>& sp,
		const vector<Vdouble *> * weights)
    : _et(et),_sc(sc),_sp(sp),_weights(weights) {};
private:
	const vector<tree>& _et;
	const vector<sequenceContainer1G>& _sc;
	vector<stochasticProcess>& _sp;
	const vector<Vdouble *> * _weights;
public:
	MDOUBLE operator() (MDOUBLE alpha) {
		//cerr<<"trying alpha: "<<alpha<<endl;
		MDOUBLE res=0;
		for (int i=0; i < _sc.size();++i) {

			if (_sp[i].categories() == 1) {
				errorMsg::reportError(" one category when trying to optimize alpha");
			}
			(static_cast<gammaDistribution*>(_sp[i].distr()))->setAlpha(alpha);
			res += likelihoodComputation::getTreeLikelihoodAllPosAlphTheSame(_et[i],_sc[i],_sp[i],_weights?(*_weights)[i]:NULL);
		}
//		LOG(5,<<" with alpha = "<<alpha<<" logL = "<<res<<endl);
		return -res;
	}
};








#endif


