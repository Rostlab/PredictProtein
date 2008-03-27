#ifndef ___READ_TREE
#define ___READ_TREE

#define REMARK ';'
#define MAX_LENGTH_OF_NAME 20
#define MAX_FILE_SIZE 1000000
#define FATHER 0
#define LEFT 1
#define RIGHT 2

#define OPENING_BRACE '('
#define CLOSING_BRACE ')'
#define OPENING_BRACE2 '{'
#define CLOSING_BRACE2 '}'
#define COMMA ','
#define COLON ':'
#define SEMI_COLLON ';'
#define PERIOD '.'

#include "definitions.h"
#include <iostream>
using namespace std;


bool DistanceExists(vector<char>::const_iterator& p_itCurrent);
bool verifyChar(vector<char>::const_iterator &p_itCurrent, const char p_cCharToFind);
int GetNumberOfLeaves(const vector<char>& tree_contents);
int GetNumberOfInternalNodes(const vector<char>& tree_contents);
bool IsAtomicPart(const vector<char>::const_iterator p_itCurrent);
vector<char> PutTreeFileIntoVector(istream &in);

//template <class node>
//node*	ReadPart(string::const_iterator &p_itCurrent);

MDOUBLE getDistance(vector<char>::const_iterator &p_itCurrent);
bool DistanceExists(vector<char>::const_iterator& p_itCurrent); 

#endif

