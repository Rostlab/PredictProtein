#include "sequence.h"
sequence::sequence(const string& str,
				   const string& name,
				   const string& remark,
				   const int id,
				   const alphabet* inAlph):
		_alphabet(inAlph),_remark(remark),_name(name),_id(id) {
	for (int k=0; k < str.size() ; k+=_alphabet->stringSize() ) {
		_vec.push_back(inAlph->fromChar(str,k));
	}
}

string sequence::toString() const{
	string tmp;
	for (int k=0; k < _vec.size() ; ++k ){
		string tmp2 = _alphabet->fromInt(_vec[k]);
		tmp+= tmp2;
	}
	return tmp;
}

string sequence::toString(const int pos) const{
	string tmp = _alphabet->fromInt(_vec[pos]);
	return tmp;
}	

void sequence::addFromString(const string& str) {
	for (int k=0; k < str.size() ; k+=_alphabet->stringSize()) {
		_vec.push_back(_alphabet->fromChar(str,k));
	}
}

class particip {
public:
	explicit particip()  {}
	bool operator()(int i) {
		return (i==-1);
	}
};

#include <algorithm>
using namespace std;
void sequence::removePositions(const vector<int> & posToRemove) {
	for (int k=0; k < posToRemove.size(); ++k) {
		if (posToRemove[k] == 1) _vec[k] = -1;
	}
	vector<int>::iterator vec_iter;
	vec_iter =  remove_if(_vec.begin(),_vec.end(),particip());
	_vec.erase(vec_iter,_vec.end()); // pg 1170, primer.
}
