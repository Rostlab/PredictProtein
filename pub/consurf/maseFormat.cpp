#include "maseFormat.h"
#include "someUtil.h"
#include "errorMsg.h"
#include "sequenceUtility.h"

sequenceContainer1G maseFormat::read(istream &infile, const alphabet* alph) {
	if (!infile) {
		errorMsg::reportError("unable to read mase format, could not open file");
	}
	sequenceContainer1G mySeqData;;

	vector<string> seqFileData;
	putFileIntoVectorStringArray(infile,seqFileData);

	vector<string>::const_iterator it1;
	for (it1 = seqFileData.begin(); it1!= seqFileData.end(); ++it1) {
		if (it1->empty()) continue; // empty line continue
		if (it1->size()>1) {
			if ( ((*it1)[0] == ';') && ((*it1)[1] == ';')) {// general file remarks
				mySeqData.addGeneralRemark(*it1);
			}
		}
	}
	int localid=0;
	for (it1 = seqFileData.begin(); it1!= seqFileData.end(); ) {
		if (it1->empty()) {++it1;continue; }// empty line continue
		if (it1->size()>1) {
			if ( ((*it1)[0] == ';') && ((*it1)[1] == ';')) {// general file remarks
				++it1;continue;
			}
		}
		
		string remark;
		string name;
		string seqStr;
		if ((*it1)[0] != ';') {
			LOG(5,<<"problem in line: "<<*it1<<endl);
			errorMsg::reportError("Error reading mase file, error finding sequence remark",1);
		}
		if ((*it1)[0] == ';') {remark += *it1;++it1;}
		while ((*it1)[0] == ';') {
			remark += "\n";
			remark += *it1;
			++it1;
		}
		while (it1->empty()) it1++; // empty line continue
		name = *it1;
		++it1;

		while (it1!= seqFileData.end()) {
			if ((*it1)[0] == ';') break;
			// the following lines are taking care of a format which is like "10 aact"
			// in mase format
			string	withoutNumberAndSpaces = 
				takeCharOutOfString("0123456789 ",*it1);
			seqStr+=withoutNumberAndSpaces;
			++it1;
		}
		mySeqData.add(sequence(seqStr,name,remark,localid,alph));
		localid++;
	}

	makeSureAllSeqAreSameLength(&mySeqData);
	return mySeqData;
}

void maseFormat::write(ostream &out, const sequenceContainer1G& sd) {
	vector<string> gfr = sd.getGeneralFileRemarks();

	if (gfr.empty()) out<<";;\n;;\n";
	for (vector<string>::const_iterator k=gfr.begin() ; k !=  gfr.end() ; ++k )
		out<<(*k)<<endl;
	for (sequenceContainer1G::constTaxaIterator it5=sd.constTaxaBegin();it5!=sd.constTaxaEnd();++it5) {
		if ((*it5).remark().size() > 0) out<<";"<<(*it5).remark()<<endl;
		else out<<";\n";
		out<<it5->name()<<endl;
		out<<it5->toString()<<endl;
	}
}

