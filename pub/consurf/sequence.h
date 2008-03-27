#ifndef ___SEQUENCE
#define ___SEQUENCE

#include "errorMsg.h"
#include "alphabet.h"
#include <iostream>
using namespace std;

class sequence;
typedef sequence* sequencePtr;
typedef const sequence* constSeqPtr;
typedef int LETTER;

class sequence {


public:
	class Iterator;
	friend class Iterator;
	class constIterator;
	friend class constIterator;

	explicit sequence(const string& str,
					const string& name,
					const string& remark,
					const int id,
					const alphabet* inAlph);

	sequence(const sequence& other) :_vec(other._vec),
         _alphabet(other._alphabet),_remark(other._remark),_name(other._name),_id(other._id) {};
	explicit sequence() {};
	virtual ~sequence(){}
	string toString() const;
	string toString(const int pos) const;
	//char toChar(const int pos) const {return _alphabet->fromInt(_vec[pos]);}
	void addFromString(const string& str);
	LETTER& operator[](const int i) {return _vec[i];}
	const LETTER& operator[](const int i) const {return _vec[i];}
	int size() const {return _vec.size();}
	int seqLen() const {return _vec.size();}
	void resize(const int k, const int val = -2) {_vec.resize(k,val);}
	void push_back(int p) {_vec.push_back(p);}
	const string& name() const {return _name;}
	const string& remark() const {return _remark;}
	const int id() const {return _id;}
	string* namePtr() {return &_name;} // sequence from outside sequenceDatum...
	string* remarkPtr() {return &_remark;}
  	int* idPtr() {return &_id;}
	inline sequence& operator=(const sequence& other);
	inline sequence& operator+=(const sequence& other);
	void setAlphabet(const alphabet* inA) {_alphabet = inA;}
	const alphabet* getAlphabet() const {return _alphabet;}
	void removePositions(const vector<int> & parCol);
private: 
	vector<LETTER> _vec;	
	const alphabet* _alphabet;
	string _remark;
	string _name;
	int _id;


public:
	class Iterator {
	public:
		explicit Iterator(){};
		~Iterator(){};
		void begin(sequence& seq){_pointer = seq._vec.begin();}
		void end(sequence& seq){_pointer = seq._vec.end();}
		LETTER& operator* (){return *_pointer;}
		LETTER const &operator* () const {return *_pointer;}
		void operator ++() {++_pointer;}
		void operator --() { --_pointer; }
		bool operator != (const Iterator& rhs){return (_pointer != rhs._pointer);}
		bool operator == (const Iterator& rhs){return (_pointer == rhs._pointer);}
	private:
		vector<LETTER>::iterator _pointer;
  };

	class constIterator {
	public:
		explicit constIterator(){};
		~constIterator(){};
		void begin(const sequence& seq){_pointer = seq._vec.begin();}
		void end(const sequence& seq){_pointer = seq._vec.end();}
		LETTER const &operator* () const {return *_pointer;}
		void operator ++(){++_pointer;}
		void operator --(){--_pointer;}
		bool operator != (const constIterator& rhs) {
		  return (_pointer != rhs._pointer);
		}
		bool operator == (const constIterator& rhs) {
		  return (_pointer == rhs._pointer);
		}
	private:
		vector<LETTER>::const_iterator _pointer;
	};


} ;

inline sequence& sequence::operator=(const sequence& other) {
	_vec = other._vec;
	_alphabet = other._alphabet;
	return *this;
}

inline sequence& sequence::operator+=(const sequence& other) {
	for (int i=0; i <other._vec.size();++i) { 
		_vec.push_back(other._vec[i]);
	}
	return *this;
}


inline ostream & operator<<(ostream & out, const sequence &Seq){
    out<< Seq.toString();
    return out;
}


#endif

