#include "fromCountTableComponentToDistanceProp.h"
#include "likeDistProp.h"

fromCountTableComponentToDistanceProp::fromCountTableComponentToDistanceProp(
		const vector<countTableComponentGam>& ctc,
		const vector<stochasticProcess> &sp,
		const MDOUBLE toll,
		const MDOUBLE brLenIntialGuess ) : _sp(sp), _ctc(ctc) {
	_distance =brLenIntialGuess ;//0.03;
	_toll = toll;
}

void fromCountTableComponentToDistanceProp::computeDistance() {
	likeDistProp likeDist1(alphabetSize(),_sp,_toll);
	_distance = likeDist1.giveDistance(_ctc,_likeDistance);
}
