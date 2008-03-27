// version 1.00
// last modified 2 Nov 2002

#ifndef ___ERROR_MSG
#define ___ERROR_MSG

#include <string>
#include <vector>
using namespace std;

class errorMsg {
public:
	static void reportError(const vector<string>& textToPrint, const int exitCode=1);
	static void reportError(const string& textToPrint, const int exitCode=1);
	static void setErrorOstream(ostream* errorOut) {_errorOut = errorOut;}
private:
	static ostream* _errorOut;
};

#endif

