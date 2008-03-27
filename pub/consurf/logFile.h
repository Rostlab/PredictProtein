#ifndef ___LOG
#define ___LOG


#include <string>
#include <iostream>
#include <fstream>

using namespace std;
			
class myLog {
public:
	static int LogLevel() { return _loglvl;}
	static ostream& LogFile(void) {
		if (_out == NULL) return cerr;
		return *_out;
	}

	static void setLogLvl(const int newLogLvl) {_loglvl = newLogLvl;}
	static void setLogOstream(ostream* out) {_out = out;}
private:
	static ostream* _out;
	static int _loglvl;
};

#ifdef LOG
#undef LOG
#endif
		

#define LOG(Lev, ex) { if( Lev <= myLog::LogLevel() ) myLog::LogFile() ex; }
#define LOGDO(Lev, ex) { if( Lev <= myLog::LogLevel() ) ex; }


#endif



