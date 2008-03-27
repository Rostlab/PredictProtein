#ifndef ____AMINO
#define ____AMINO

#include "errorMsg.h"
#include "alphabet.h"
#include "definitions.h"

//based on the amino-acid list found in http://www.dur.ac.uk/~dbl0www/Bioinformatics/aminoacids.htm
class amino : public alphabet {
public:
	explicit amino();
	virtual ~amino() {}
	virtual alphabet* clone() const { return new amino(*this); }
	int unknown() const  {return -2;}
	int size() const {return 20;}
	int stringSize() const {return 1;} // one letter code.
	int relations(const int charInSeq, const int charToCheck) const;
	int fromChar(const string& str, const int pos) const;
	int fromChar(const char s) const;
	string fromInt(const int in_id) const;

private:
	int relations_internal(const int charInSeq, const int charToCheck) const;
	VVint _relation;
};//end of class

#endif


