#ifndef ___SOME_UTIL_H
#define ___SOME_UTIL_H

#include "logFile.h"
#include "definitions.h"
#include <string>
using namespace std;

// STATISTICAL UTILITIES:

MDOUBLE computeAverage(const vector<int>& vec);
MDOUBLE computeAverage(const vector<MDOUBLE>& vec);
MDOUBLE computeStd(const vector<MDOUBLE>& vec);// page 60, Sokal and Rohlf
MDOUBLE computeStd(const vector<int>& vec);// page 60, Sokal and Rohlf

// TIME UTILITIES
void printTime(ostream& out);

// TEXT UTILITIES
string int2string(const int i);
MDOUBLE string2double(const string& inString);
bool allowCharSet(const string& allowableChars, const string& string2check);
bool isCharInString(const string& stringToCheck, const char charToCheck);
void putFileIntoVectorStringArray(istream &infile,vector<string> &inseqFile);

bool fromStringIterToInt(string::const_iterator & it,
						 const string::const_iterator endOfString,
						 int& res);

string takeCharOutOfString(const string& charsToTakeOut, const string& fromString);

// FILE UTILITIES
bool checkThatFileExist(const string& fileName); 
string* searchStringInFile(const string& string2find,
						   const int index,
						   const string& inFileName);
string* searchStringInFile(const string& string2find,
						   const string& inFileName);
bool doesWordExistInFile(const string& string2find,const string& inFileName);
void createDir(const string& curDir,const string& dirName);


//BIT UTILITIES
//void nextBit(bitset<64> &cur);

//ARITHMETIC UTILITIES
//DEQUAL: == UP TO EPSILON
//DBIG_EQUAL: >= UP TO EPSILON
//DSMALL_EQUAL: <= UP TO EPSILON
bool DEQUAL(const MDOUBLE x1, const MDOUBLE x2, const MDOUBLE epsilon = 1.192092896e-07F); // epsilon taken from WINDOW'S FILE FLOAT.H
bool DBIG_EQUAL(const MDOUBLE x1, const MDOUBLE x2, const MDOUBLE epsilon = 1.192092896e-07F); 
bool DSMALL_EQUAL(const MDOUBLE x1, const MDOUBLE x2, const MDOUBLE epsilon = 1.192092896e-07F); // {return ((x1 < x2) || DEQUAL(x1, x2));}

#endif

