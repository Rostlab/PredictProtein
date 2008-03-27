#include "someUtil.h"
#include "errorMsg.h"
#include <cmath>
#include <ctime>
#include <iterator>
#include <algorithm>
#include <string>
using namespace std;

// for the _mkdir call
#ifdef WIN32
#include <direct.h>
#else
#include <sys/file.h>
#include <sys/dir.h>
#endif


MDOUBLE computeAverage(const vector<int>& vec) {
	MDOUBLE sum=0.0;
	for (int i=0; i < vec.size(); ++i) {
		sum+=static_cast<MDOUBLE>(vec[i]);
	}
	return sum/static_cast<MDOUBLE>(vec.size());
}

MDOUBLE computeAverage(const vector<MDOUBLE>& vec) {
	MDOUBLE sum=0.0;
	for (int i=0; i < vec.size(); ++i) sum+=vec[i];
	return sum/static_cast<MDOUBLE>(vec.size());
}

MDOUBLE computeStd(const vector<int>& vec) {// page 60, Sokal and Rohlf
	MDOUBLE sum=0.0;
	MDOUBLE sumSqr=0.0;
	MDOUBLE vecSize = static_cast<MDOUBLE>(vec.size());
	for (int i=0; i < vec.size(); ++i) {
		sum+=static_cast<MDOUBLE>(vec[i]);
		sumSqr+=(static_cast<MDOUBLE>(vec[i])*static_cast<MDOUBLE>(vec[i]));
	}
	MDOUBLE res= sumSqr-(sum*sum/vecSize);
	res /= (vecSize-1.0);
	res = sqrt(res);
	return res;
}

MDOUBLE computeStd(const vector<MDOUBLE>& vec) {// page 60, Sokal and Rohlf
	MDOUBLE sum=0.0;
	MDOUBLE sumSqr=0.0;
	MDOUBLE vecSize = static_cast<MDOUBLE>(vec.size());
	for (int i=0; i < vec.size(); ++i) {
		sum+=vec[i];
		sumSqr+=(vec[i]*vec[i]);
	}
	MDOUBLE res= sumSqr-(sum*sum/vecSize);
	res /= (vecSize-1.0);
	res = sqrt(res);
	return res;
}

bool allowCharSet(const string& allowableChars, const string& string2check) {
// this function check if all the character in string2check are made of characters from allowableChars
	for (int i=0; i < string2check.size(); ++i) {
		// now checking for string2check[i]
		int j;
		for (j=0; j < allowableChars.size(); ++j) {
			if (string2check[i] == allowableChars[j]) {
				break;
			}
		}
		if (j==allowableChars.size()) return false;
	}
	return true;
}

bool isCharInString(const string& stringToCheck, const char charToCheck) {
	for (int i=0; i < stringToCheck.size(); ++i ) {
		if (stringToCheck[i] == charToCheck) return true;
	}
	return false;
}

string int2string(const int num) {
// the input to this program is say 56
// the output is the string "56"
// this version of int2string is more portable 
// than sprintf like functions from c;
// or sstream of stl.

	string res;
	int i = num;
	if (i<0) {
		res="-";
		i=-num;
	}

	if (i == 0) return "0";
	
	
	int leftover;
	char k;
	while (i) {
		leftover = i%10;
		k = '0'+leftover;
		res = k+res;
		i/=10;
	}
	return res;
};

void printTime(ostream& out) {
	time_t ltime;
	time( &ltime );
	out<<"# the date is "<< ctime( &ltime )<<endl;
}

MDOUBLE string2double(const string& inString) {

	if (allowCharSet("0123456789.e+-",inString) == false) {
		errorMsg::reportError(" error in function string2double ");
	}
	
	// first decide if the format is like 0.00343 (regularFormat) or
	// if it is in the form of 0.34e-006 for example

	bool regularFormat = true;
	int i;
	for (i=0; i < inString.size(); ++i) {
		if (inString[i] == 'e' ) {
			regularFormat = false; 
			break;
		}
	}

	if (regularFormat) {
			MDOUBLE dDistance = atof(inString.c_str());
			return dDistance;
	}
	else {
		string b4TheExp;
		bool plusAfterTheExp = true;
		string afterTheExp;

		// b4 the exp
		for (i=0; i < inString.size(); ++i) {
			if (inString[i] != 'e' ) {
				b4TheExp += inString[i];
			}
			else break;
		}
		++i; //now standing after the exp;
		if (inString[i] == '-' ) {
			plusAfterTheExp = false;
			++i;
		}
		else if (inString[i] == '+' ) {
			plusAfterTheExp = true;
			++i;
		}
		else plusAfterTheExp = true; // the number is like 0.34e43

		for (; i < inString.size(); ++i) {
			afterTheExp += inString[i];
		}

		MDOUBLE res = 0.0;
		MDOUBLE dDistance = atof(b4TheExp.c_str());
		int exponentialFactor = atoi(afterTheExp.c_str());
		if (plusAfterTheExp) res = dDistance * pow(10.0,exponentialFactor);
		else res = dDistance * pow(10.0,-exponentialFactor);

		return res;
	}

	
}


bool checkThatFileExist(const string& fileName) {
	ifstream file1(fileName.c_str());
	if (file1==NULL) return false;
	file1.close();
	return true;
}

void putFileIntoVectorStringArray(istream &infile,vector<string> &inseqFile){
	inseqFile.clear();
	string tmp1;
	while (getline(infile,tmp1, '\n' ) ) {
		if (tmp1.size() > 10000) {
			vector<string> err;
			err.push_back("Unable to read file. It is required that each line is no longer than");
			err.push_back("10000 characters. ");
			errorMsg::reportError(err,1); 
		}
		if (tmp1[tmp1.size()-1]=='\r') {// in case we are reading a dos file 
			tmp1.erase(tmp1.size()-1);
		}// remove the traling carrige-return
		inseqFile.push_back(tmp1);
	}
}

bool fromStringIterToInt(string::const_iterator & it, // ref must be here
						const string::const_iterator endOfString,
						int& res) {// the ref is so that we can use the it after the func.
	while (it != endOfString) {
		if ((*it == ' ') || (*it == '\t')) ++it;else break; // skeeping white spaces.
	}
	if (it != endOfString) {
		if (isdigit(*it)){
			int k = atoi(&*it);
			for (int numDig = k; numDig>0; numDig/=10) ++it;
			res = k;
			return true;
		}
		else return false; //unable to read int From String
	}
	return false; //unable to read int From String
	
}

string* searchStringInFile(const string& string2find,
						   const int index,
						   const string& inFileName) {
	ifstream f;
	f.open(inFileName.c_str());
	if (f==NULL) {
		string tmp = "Unable to open file name: "+inFileName+" in function searchStringInFile"; 
		errorMsg::reportError(tmp);
	}

	string numm = int2string(index);
	string realString2find = string2find+numm;

	istream_iterator<string> is_string(f);
	istream_iterator<string> end_of_stream;

	is_string = find(is_string,end_of_stream,realString2find);
	if(is_string == end_of_stream) {f.close();return NULL;}
	else {
		is_string++;
		if(is_string == end_of_stream) {f.close();return NULL;};
		string* s = new string(*is_string);
		f.close();
		return s;
	}
	f.close();
	return NULL;
}
string* searchStringInFile(const string& string2find,
						   const string& inFileName) {// return the string that is AFTER the string to search.
	ifstream f;
	f.open(inFileName.c_str());
	if (f==NULL) {
		string tmp = "Unable to open file name: "+inFileName+" in function searchStringInFile"; 
		errorMsg::reportError(tmp);
	}
	string realString2find = string2find;

	istream_iterator<string> is_string(f);
	istream_iterator<string> end_of_stream;

	is_string = find(is_string,end_of_stream,realString2find);
	if(is_string == end_of_stream) {f.close();return NULL;}
	else {
		is_string++;
		if(is_string == end_of_stream) {f.close();return NULL;};
		string* s = new string(*is_string);
		f.close();
		return s;
	}
	f.close();
	return NULL;
}
bool doesWordExistInFile(const string& string2find,const string& inFileName) {
	ifstream f;
	f.open(inFileName.c_str());
	if (f==NULL) {
		string tmp = "Unable to open file name: "+inFileName+" in function searchStringInFile"; 
		errorMsg::reportError(tmp);
	}

	istream_iterator<string> is_string(f);
	istream_iterator<string> end_of_stream;

	is_string = find(is_string,end_of_stream,string2find);
	if(is_string == end_of_stream) return false;
	else return true;
}

string takeCharOutOfString(const string& charsToTakeOut, const string& fromString) {
	string finalString;
	for (int i=0; i<fromString.size(); ++i) {
		bool goodChar = true;
		for (int j=0; j < charsToTakeOut.size(); ++j) {
			if (fromString[i]== charsToTakeOut[j]) goodChar = false;
		}
		if (goodChar) finalString+=fromString[i];
	}
	return finalString;
}

bool DEQUAL(const MDOUBLE x1, const MDOUBLE x2, MDOUBLE epsilon/*1.192092896e-07F*/) {
	return (fabs(x1-x2)<epsilon);
}

bool DBIG_EQUAL(const MDOUBLE x1, const MDOUBLE x2, MDOUBLE epsilon/*1.192092896e-07F*/){
	return ((x1 > x2) || DEQUAL(x1, x2,epsilon));
}


bool DSMALL_EQUAL(const MDOUBLE x1, const MDOUBLE x2, MDOUBLE epsilon/*1.192092896e-07F*/){ 
	return ((x1 < x2) || DEQUAL(x1, x2,epsilon));
}

void createDir(const string & curDir, const string & dirName){// COPYRIGHT OF ITAY MAYROSE.
	string newDir = curDir + string("\\") + dirName;
#ifdef WIN32
	if( _mkdir(newDir.c_str()) == 0 ){
		cerr << "Directory " <<newDir<<" was successfully created"<<endl;
    }else{
		if (errno == EEXIST) {
			cerr<<"Directory already exist";
			return;
		} else {
		string err = "Problem creating directory " + newDir + " \n";
		cerr << err << endl;
		errorMsg::reportError(err);
		}
	}
#else
	DIR * directory = opendir(newDir.c_str());
	if (directory == NULL) {
		string err = "Problem creating directory " + newDir + "was successfully created\n";
		errorMsg::reportError(err);
	}
	else{
		//if (errno == EEXIST) {
		//	cerr<<"Directory already exist";
		//	return;
		//} else {
		string err = "Problem creating directory " + newDir + " \n";
		cerr << err << endl;
		errorMsg::reportError(err);
		
	}
#endif
}
