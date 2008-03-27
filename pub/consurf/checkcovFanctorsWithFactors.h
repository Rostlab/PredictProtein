#ifndef ____CHECKCOV__FANCTORS_WITH_FACTORS
#define ____CHECKCOV__FANCTORS_WITH_FACTORS

#include "likelihoodComputation.h"
#include "likelihoodComputationFactors.h" //<-new.
using namespace likelihoodComputation;

#include "definitions.h"
#include "sequenceContainer.h"
#include "treeInterface.h"
#include "stochasticProcess.h"
using namespace treeInterface;

//#define VERBOS
#ifdef VERBOS
#include <iostream>
using namespace std;
#endif

// USING FACTORS: THE IDEA HERE IS THAT WHEN WE HAVE TOO MANY SEQUENCES,
// WE MUST TAKE SPECIAL CARE TO USE "FACTORS" AT INTERNAL NODES, TO AVOID UNDERFLOW.
// HERE WE ALSO RETURN LOG LIKELIHOOD OF A POSITION AND NOT THE LIKELIHOOD ITSELF.
class Cevaluate_LOG_L_given_r{
public:
  explicit Cevaluate_LOG_L_given_r(	const sequenceContainer& sd,
								const tree& t1,
								const stochasticProcess& sp,
								const int pos)
			:_sd(sd),_pos(pos), _sp(sp) ,_t1(t1){}
private:
	const sequenceContainer& _sd;
	const tree& _t1;
	const int _pos;
	const stochasticProcess& _sp;
public:
	MDOUBLE operator() (const MDOUBLE r) {
		
		MDOUBLE tmp1= getLOG_LofPos(_pos,_t1,_sd,_sp,r);
		#ifdef VERBOS
			cerr<<" r = "<<r<<" l = "<<tmp1<<endl;
		#endif
		return -tmp1;
	}
};

#endif


