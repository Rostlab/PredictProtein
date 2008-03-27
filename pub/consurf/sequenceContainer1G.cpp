#include "sequenceContainer1G.h"
#include "logFile.h"

//void sequenceContainer1G::addFromSequenceContainer1G(sequenceContainer1G& seqToAdd){
//	if (_seqDataVec.empty()) { // first sequence to add
//		sequenceContainer::taxaIterator tit;
//		sequenceContainer::taxaIterator titEND;
//		tit.begin(seqToAdd);
//		titEND.end(seqToAdd);
//		while (tit!=titEND) {
//			_seqDataVec.push_back(*tit);
//
//		}
//	}
//	else {// now we are adding sequences to sequences that are already there.
//		sequenceContainer::taxaIterator tit;
//		sequenceContainer::taxaIterator titEND;
//		tit.begin(seqToAdd);
//		titEND.end(seqToAdd);
//		while (tit!=titEND) {
//			for (int i=0; i < _seqDataVec.size(); ++i) {
//				if (tit->name() == _seqDataVec[i].name()) {
//					_seqDataVec[i]+=(*tit);
//					break;
//				}
//			}
//			++tit;
//		}
//	}
//}

void sequenceContainer::changeGapsToMissingData() {

	for (int i = 0; i < seqLen();++i) {//going over al positions
		for (int j = 0; j < _seqDataVec.size();++j) {
			if (_seqDataVec[j][i] == -1){
				 _seqDataVec[j][i]=getAlphabet(j)->unknown(); // missing data
			}
		}
	}
}

const int sequenceContainer::getId(const string &seqName, bool issueWarningIfNotFound) const {
	int k;
	for (k=0 ; k < _seqDataVec.size() ; ++k) {
		if (_seqDataVec[k].name() == seqName) return (_seqDataVec[k].id());
	}
	if (k == _seqDataVec.size() && issueWarningIfNotFound) {
	// debuggin
	cerr<<"seqName = "<<seqName<<endl;
	for (k=0 ; k < _seqDataVec.size() ; ++k) {
		cerr<<"_seqDataVec["<<k<<"].name() ="<<_seqDataVec[k].name()<<endl;
	}
	//end dubug
		LOG(0,<<seqName<<endl);
		vector<string> err;
		err.push_back("Could not find a sequence that matches the sequence name  ");
		err.push_back(seqName);
		err.push_back("in function sequenceContainer::getSeqPtr ");
		err.push_back(" make sure that names in tree file match name in sequence file ");
		errorMsg::reportError(err,1); // also quit the program
	}
	return -1;
}

void sequenceContainer::add(const sequence& inSeq) {
	_seqDataVec.push_back(inSeq);
	if (id2place.size() < inSeq.id()+1) id2place.resize(inSeq.id()+100);
	id2place[inSeq.id()] = _seqDataVec.size()-1;
}

void sequenceContainer::removeGapPositions(){
	vector<int> posToRemove(seqLen(),0);
	bool gapCol;
	int i,j;
	for (i = 0; i < seqLen();++i) {//going over al positions
		gapCol = false;
		for (j = 0; j < _seqDataVec.size();++j) {
			if (_seqDataVec[j][i] == -1) posToRemove[i] = 1;
		}
	}

	for (int z = 0; z < _seqDataVec.size();++z) {
		_seqDataVec[z].removePositions(posToRemove);
	}
}




void sequenceContainer::changeDotsToGoodCharacters() {
	for (int i = 0; i < seqLen();++i) {//going over al positions
		int charInFirstSeq = _seqDataVec[0][i];
		if (charInFirstSeq == -3) {
			cerr<<" position is: "<<i<<endl;
			errorMsg::reportError(" the first line contains dots ");
		}
		for (int j = 1; j < _seqDataVec.size();++j) {
			
			if ((_seqDataVec[j][i] == -3)) {
				_seqDataVec[j][i] = charInFirstSeq; // missing data
			}
		}
	}
}
