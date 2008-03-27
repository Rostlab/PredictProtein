#ifndef ___SEQUENCE_CONTAINERNG
#define ___SEQUENCE_CONTAINERNG


#include "sequence.h"
#include "sequenceContainer.h"
#include "sequenceContainer1G.h"

class sequenceContainerNG : public sequenceContainer {
public:


//------------------------------------------------------------
//constructors:
    explicit sequenceContainerNG(){} ;
	virtual ~sequenceContainerNG(){};

	//void addFromSequenceContainer1G(sequenceContainer1G& seqToAdd);
	const alphabet* getAlphabet(const int pos) const {return _alphabetTable.empty()?NULL: _alphabetTable[pos];}

	private:
	vector<alphabet* > _alphabetTable;
};//end of class sequenceContainerNG


#endif

