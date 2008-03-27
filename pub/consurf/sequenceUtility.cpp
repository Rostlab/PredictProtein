
#include "sequenceUtility.h"

void makeSureAllSeqAreSameLength(sequenceContainer1G* seqDataPtr) {
	sequenceContainer1G::constTaxaIterator cti = seqDataPtr->constTaxaBegin();
	int len = cti->seqLen();
	++cti;
	while (cti != seqDataPtr->constTaxaEnd()) {
		if (cti->seqLen() != len) {errorMsg::reportError("not all seq are the same length...");}
		++cti;
	}
}
