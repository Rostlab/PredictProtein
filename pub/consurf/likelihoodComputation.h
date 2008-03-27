#ifndef ___LIKELIHOOD_COMPUTATION
#define ___LIKELIHOOD_COMPUTATION

#include "treeInterface.h"
using namespace treeInterface;
#include "computePijComponent.h"
#include "sequenceContainer.h"
#include "suffStatComponent.h"

namespace likelihoodComputation {
	MDOUBLE getLofPos(const int pos,					// this function is used
					  const tree& et,					// when the br-len
					  const sequenceContainer& sc,		// are the same for all
					  const computePijHom& pi,			// positions.
					  const stochasticProcess& sp);
	MDOUBLE getLofPos(const int pos,					// this function is used
					  const tree& et,					// when the br-len
					  const sequenceContainer& sc,		// are NOT the same for all
					  const stochasticProcess& sp);
	MDOUBLE getLofPos(const int pos,					// this function is used
					  const tree& et,					// when gamma, and the br-len
					  const sequenceContainer& sc,		// are the same for all pos.
					  const computePijGam& pi,
					  const stochasticProcess& sp);
	MDOUBLE getLofPos(const int pos,					// with a site specific rate.
					  const tree& et,
					  const sequenceContainer& sc,
					  const stochasticProcess& sp,
					  const MDOUBLE gRate);

	MDOUBLE getTreeLikelihoodFromUp(const tree& et,
									const sequenceContainer& sc,
									const stochasticProcess& sp,
									const suffStatGlobalGam& cup,
									const Vdouble * weights =0 );
	MDOUBLE getTreeLikelihoodFromUp2(const tree& et,
						const sequenceContainer& sc,
						const stochasticProcess& sp,
						const suffStatGlobalGam& cup,
						Vdouble& posLike, // fill this vector with each position likelihood but without the weights.
						const Vdouble * weights=0);
	MDOUBLE getTreeLikelihoodAllPosAlphTheSame(const tree& et,
							const sequenceContainer& sc,
							const stochasticProcess& sp,
										const Vdouble * const weights=0);
	// fill this vector with each position posterior rate (p(r|D))
	// but without the weights.
	MDOUBLE getPosteriorOfRates(const tree& et,
						const sequenceContainer& sc,
						const stochasticProcess& sp,
						const suffStatGlobalGam& cup,
						VVdouble& posteriorLike, 
						const Vdouble * weights);
};



#endif

