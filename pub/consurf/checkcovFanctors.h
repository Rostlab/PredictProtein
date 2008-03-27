#ifndef ____CHECKCOV__FANCTORS
#define ____CHECKCOV__FANCTORS

#include "likelihoodComputation.h"
using namespace likelihoodComputation;

#include "definitions.h"
#include "sequenceContainer1G.h"
#include "treeInterface.h"
#include "stochasticProcess.h"
using namespace treeInterface;

#include <cmath>

//#define VERBOS

#ifdef VERBOS
#include <iostream>
using namespace std;
#endif

class Cevaluate_L_given_r{
public:
  explicit Cevaluate_L_given_r(	const sequenceContainer& sd,
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
		
		MDOUBLE tmp1= getLofPos(_pos,_t1,_sd,_sp,r);
		#ifdef VERBOS
			cerr<<" r = "<<r<<" l = "<<tmp1<<endl;
		#endif
		return -tmp1;
	}
};

// THIS FUNCTION IS USED ONLY BY ITAY MAYROSE AND ONLY HE KNOWS WHAT IS INSIDE...
// ONE DAY HE WILL WRITE .DOC FILES...
class Cevaluate_Posterior_given_r {
public:
  explicit Cevaluate_Posterior_given_r(	const sequenceContainer& seqContainer,
								const tree& t1,
								const stochasticProcess& sp,
								const MDOUBLE alpha,
								const int pos)
			:m_seqContainer(seqContainer),m_tree(t1), m_pos(pos), m_sp(sp), m_alpha(alpha) {}
public:
	MDOUBLE operator() (const MDOUBLE r) 
	{
		
		MDOUBLE l= getLofPos(m_pos, m_tree, m_seqContainer, m_sp, r);
		#ifdef VERBOS
			cerr<<" r = "<<r<<" l = "<<l<<endl;
		#endif
		MDOUBLE prior = exp((-m_alpha) * r) * pow(r, m_alpha - 1);
		return -(l * prior);
	}

private:
	const sequenceContainer& m_seqContainer;
	const MDOUBLE m_alpha;
	const tree& m_tree;
	const int m_pos;
	const stochasticProcess& m_sp;

};

// WHEN YOU WANT TWO TREE TO HAVE THE SAME RATE AT A SPECIFIC POSITION.
class Cevaluate_L_sum_given_r{
public:
	explicit Cevaluate_L_sum_given_r(const stochasticProcess& sp,
									 const sequenceContainer1G& sd,
									 const tree &inLTree1,
									 const tree &inLTree2,
									 const int pos)
			:_sp(sp), _sd(sd), _tree1(inLTree1),_tree2(inLTree2), _pos(pos){};

private:
	const stochasticProcess _sp;
	const sequenceContainer1G _sd;
	const tree& _tree1;
	const tree& _tree2;
	const int _pos;
public:
	MDOUBLE operator() (const MDOUBLE r) {
		MDOUBLE tmp1= getLofPos(_pos,_tree1,_sd,_sp,r);
		MDOUBLE tmp2= getLofPos(_pos,_tree2,_sd,_sp,r);
		MDOUBLE tmp= tmp1*tmp2;
		return -tmp;
	}
};

#endif
