// version 1.00
// last modified 2 Nov 2002

#include <iostream>
#include <cassert>
using namespace std;
#include "errorMsg.h"

ostream *errorMsg::_errorOut= NULL;

void errorMsg::reportError(const vector<string>& textToPrint, const int exitCode) {
	for (int i =0 ; i < textToPrint.size() ; ++i) {
		cerr<<textToPrint[i]<<endl;
		if (_errorOut != NULL && *_errorOut != cerr)  {
			(*_errorOut)<<textToPrint[i]<<endl;
		}
	}
	assert(exitCode ==0);
#ifdef WIN32	
	system("PAUSE");
#endif
	exit(exitCode);
}

void errorMsg::reportError(const string& textToPrint, const int exitCode) {
	cerr<<endl<<textToPrint<<endl;
	if (_errorOut != NULL && *_errorOut != cerr)  {
		(*_errorOut)<<textToPrint<<endl;
	}
#ifdef WIN32	
	system("PAUSE");
#endif
	exit(exitCode);
}


