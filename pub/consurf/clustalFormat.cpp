#include "clustalFormat.h"
#include "someUtil.h"
#include "errorMsg.h"
#include "sequenceUtility.h"


sequenceContainer1G clustalFormat::read(istream &infile, const alphabet* alph) {
	sequenceContainer1G mySequenceData;

	vector<string> seqFileData;
	putFileIntoVectorStringArray(infile,seqFileData);
	if (seqFileData.empty()){
		errorMsg::reportError("unable to open file, or file is empty in clustal format");
	}


	vector<string>::const_iterator it1= seqFileData.begin();

	// make sure that the first 7 chars in the first line is clustal
	if (it1->size()<7) errorMsg::reportError("first word in clusltal sequence file format must be clustal",1);
	if (  (( (*it1)[0] != 'C') && ((*it1)[0] != 'c'))
		|| (((*it1)[1] != 'L') && ((*it1)[1] != 'l'))
		|| (((*it1)[2] != 'U') && ((*it1)[2] != 'u'))
		|| (((*it1)[3] != 'S') && ((*it1)[3] != 's'))
		|| (((*it1)[4] != 'T') && ((*it1)[4] != 't'))
		|| (((*it1)[5] != 'A') && ((*it1)[5] != 'a'))
		|| (((*it1)[6] != 'L') && ((*it1)[6] != 'l')) ) {
		errorMsg::reportError("first word in clusltal sequence file format must be clustal",1);
	}
	it1++;

	int localid=0;
	while (it1!= seqFileData.end()) {
		if (it1->empty()) {++it1;continue; }// empty line continue
		if ((it1->size() > 1) && ((*it1)[0]==' ')) {++it1;continue; }// remark line 
		string remark;
		string name;

//		getFromLineAnameAndAsequence;
		string name1;
		string stringSeq1;
		string::const_iterator it2 = (it1)->begin();
		for (; it2 != (it1)->end();++it2) {
			if ((*it2)==' ') break;
			else name1+=(*it2);
		}
		for (; it2 != (it1)->end();++it2) {
			if ((*it2)==' ') continue;
			else stringSeq1+=(*it2);
		}
		
		int id = mySequenceData.getId(name1,false);
		if (id==-1) { // new sequence.
			name = name1;
			mySequenceData.add(sequence(stringSeq1,name,remark,localid,alph));
			localid++;
		} else {// the sequence is already there...
			sequence tmp(stringSeq1,name,remark,id,alph);
			mySequenceData[id].operator += (tmp);
		}
		it1++;
	}

	makeSureAllSeqAreSameLength(&mySequenceData);
	return mySequenceData;
}

void clustalFormat::write(ostream &out, const sequenceContainer1G& sd) {
	// setting some parameters
	const int numOfPositionInLine = 60;
	int maxLengthOfSeqName =0;
	for (sequenceContainer1G::constTaxaIterator p=sd.constTaxaBegin(); p != sd.constTaxaEnd(); ++p ) {
		int nameLen = (*p).name().size();
		if (nameLen>maxLengthOfSeqName) maxLengthOfSeqName=nameLen;
	}
	if (maxLengthOfSeqName<15) maxLengthOfSeqName=16;
	else maxLengthOfSeqName=maxLengthOfSeqName+4; // all this maxLengthOfSeqName is the 

	out<<"CLUSTAL V"<<endl;
	           // num. of space after the name.
	int currentPosition = 0;
	while (currentPosition < sd.seqLen() ) {
		out<<endl<<endl;
		out.flush();
		//for (vector<const sequenceContainer1G::sequenceDatum*>::const_iterator it5= vec.begin(); it5!=vec.end(); ++ it5) {
		for (sequenceContainer1G::constTaxaIterator it5=sd.constTaxaBegin();it5!=sd.constTaxaEnd();++it5) {
			for (int iName = 0 ;iName<maxLengthOfSeqName; ++iName) {
				if (iName<(*it5).name().size()) {
					out<<(*it5).name()[iName];
					out.flush();
				}
				else out<<" ";
			}
			out.flush();
			out<<" ";
			
			if (it5->size()<numOfPositionInLine) out<<it5->toString()<<endl;
			else {
				for (int k=currentPosition; k < currentPosition+numOfPositionInLine; ++k) {
					if (k>=it5->size()) break;
					out<<it5->toString()[k];
				}
				out<<endl;
			}
		}
		currentPosition +=numOfPositionInLine;
		
	}

	return;
}

