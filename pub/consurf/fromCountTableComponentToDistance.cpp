#include "fromCountTableComponentToDistance.h"
#include "likeDist.h"
#include <cassert>

fromCountTableComponentToDistance::fromCountTableComponentToDistance(
		const countTableComponentGam& ctc,
		const stochasticProcess &sp,
		const MDOUBLE toll,
		const MDOUBLE brLenIntialGuess ) : _sp(sp), _ctc(ctc) {
	_distance =brLenIntialGuess ;//0.03;
	_toll = toll;
}

void fromCountTableComponentToDistance::computeDistance() {
	likeDist likeDist1(alphabetSize(),_sp,_toll);
	_distance = likeDist1.giveDistance(_ctc,_likeDistance,_distance);
	assert(_distance>=0);
}
