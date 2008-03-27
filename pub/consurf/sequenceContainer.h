#ifndef ___SEQUENCE_CONTAINER
#define ___SEQUENCE_CONTAINER

#include "sequence.h"

class sequenceContainer {
public:

	class taxaIterator;
	friend class taxaIterator;
	class constTaxaIterator;
	friend class constTaxaIterator;

//------------------------------------------------------------
//constructors:
    explicit sequenceContainer(){} ;
	virtual ~sequenceContainer(){};

	//questions only:
	const int seqLen() const {return _seqDataVec.empty()? 0 : _seqDataVec[0].size();}
	const int numberOfSequences() const {return _seqDataVec.size();}
	const int alphabetSize() const {return _seqDataVec.empty()? 0 : _seqDataVec[0].getAlphabet()->size();}
	const vector<string>& getGeneralFileRemarks() const {return _GeneralRemarks;}
	const int makeSureAllSeqAreSameLengthAndGetLen() const;
	const int getId(const string &seqName, bool issueWarninInNotFound=true) const;//return -1 if not found...
	sequence& operator[](const int id) {return _seqDataVec[id2place[id]];}
	const sequence& operator[](const int id) const {return _seqDataVec[id2place[id]];}

//make changes:
	void resize(int t) {_seqDataVec.resize(t);}
	void add(const sequence& inSeq);
	void addGeneralRemark(const string& inRemark) {_GeneralRemarks.push_back(inRemark);}
	//string * getSeqNamePtrNonConst(const int id, bool issueWarninInNotFound);
	//string * getSeqRemarkPtrNonConst(const int id, bool issueWarninInNotFound);
	void changeGapsToMissingData();
	void removeGapPositions();
	void changeDotsToGoodCharacters();
	const alphabet* getAlphabet(const int pos=0) const {return _seqDataVec[0].getAlphabet();}
	//sequence* getSeqPtr(const int id, bool issueWarninInNotFound);
	//const sequence* getSeqPtr(const int id, bool issueWarninInNotFound) const;

public: 
	sequence::Iterator begin(const int id){//iterface to sequence iterator
		sequence::Iterator temp;
		temp.begin(_seqDataVec[id]);
		return temp;
	}
	sequence::Iterator end(const int id){//iterface to sequence iterator
		sequence::Iterator temp;
		temp.end(_seqDataVec[id]);
		return temp;
	}

	class taxaIterator {
	public:
		explicit taxaIterator(){};
		~taxaIterator(){};
		void begin(sequenceContainer & inSeqCont){
			_pointer = inSeqCont._seqDataVec.begin();
		}
	    void end(sequenceContainer & inSeqCont){
			_pointer = inSeqCont._seqDataVec.end();
		}
		sequence& operator* ()  {return *_pointer;}
		sequence const &  operator* () const {return *_pointer;}
		sequence *  operator-> ()  {return &*_pointer;} //MATAN- CHECK!!!
		sequence const *  operator-> () const {return &* _pointer;} // MATAN - CHECK!!!

		void operator ++() {++_pointer;}
	    void operator --() { --_pointer; }
	    bool operator != (const taxaIterator& rhs){return (_pointer != rhs._pointer);}
	    bool operator == (const taxaIterator& rhs){return (_pointer == rhs._pointer);}
	private:
		vector<sequence>::iterator _pointer;
	};//end if class taxaIterator


	class constTaxaIterator {
	public:
		explicit constTaxaIterator(){};
		~constTaxaIterator(){};
	    void begin(const sequenceContainer & inSeqCont){
			_pointer = inSeqCont._seqDataVec.begin();
		}
		void end(const sequenceContainer & inSeqCont){
			_pointer = inSeqCont._seqDataVec.end();
		}
		sequence const &  operator*() const {return *_pointer;}
		sequence const *  operator->() const {return &*_pointer;}// MATAN - CHECK!!!

		void operator ++() {++_pointer;}
		void operator --() { --_pointer; }
		bool operator != (const constTaxaIterator& rhs) {
		  return (_pointer != rhs._pointer);
		}

		bool operator == (const constTaxaIterator& rhs) {
		  return (_pointer == rhs._pointer);
		}
	private:
		vector<sequence>::const_iterator _pointer;
	};

	public: // interfaces to iterators
	taxaIterator taxaBegin(const int id=0){// interface to taxaIterator
		taxaIterator temp;
		temp.begin(*this);
		return temp;
	}

	taxaIterator taxaEnd(){// interface to taxaIterator
		taxaIterator temp;
		temp.end(*this);
		return temp;
	}

	constTaxaIterator constTaxaBegin() const{ //interface to const taxaIter
		constTaxaIterator temp;
		temp.begin(*this);
		return temp;
	}
	constTaxaIterator constTaxaEnd() const{
		constTaxaIterator temp;
		temp.end(*this);
		return temp;
	  }

	protected:
	vector<sequence> _seqDataVec;
	vector<string> _GeneralRemarks;
	vector<int> id2place;
};

#endif

