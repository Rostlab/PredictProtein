#ifndef ____CODON
#define ____CODON

#include "errorMsg.h"
#include "alphabet.h"
#include "definitions.h"
#include <cassert>
class codon;


class codonUtility {
public:
	enum diffType {same=0, transition, transversion, different};
	static diffType codonDiff(const int c1, const int c2);
	static int aaOf(const int c1);
};


class codon : public alphabet {
public:
	explicit codon();
	virtual ~codon() {}
	virtual alphabet* clone() const { return new codon(*this); }
	int unknown() const  {return 64;}
	int size() const {return 61;} // 3 stop codon excluded
	int stringSize() const {return 3;} // 3 letter code.

	int fromChar(const string& s, const int pos) const;
	string fromInt(const int in_id) const;


	
  int relations(const int charInSeq, const int charToCheck) const{
		if (charInSeq == -1) {
			errorMsg::reportError("gaps in the sequences. Either change gaps to ? or remove gap positions");
		}
		else if (charInSeq == unknown()) return 1;
		else if (charInSeq == charToCheck) return 1;
		assert(charInSeq < 61);
		return 0;
	}
};




#endif
