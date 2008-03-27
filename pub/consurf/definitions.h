// version 1.00
// last modified 2 Nov 2002

#ifndef ___SOME_DEFS
#define ___SOME_DEFS

#include <vector>
using namespace std;

#define MDOUBLE double
//#define MDOUBLE float

typedef vector<MDOUBLE> Vdouble;
typedef vector<int> Vint;
typedef vector<char> Vchar;
typedef vector<Vdouble> VVdouble;
typedef vector<VVdouble> VVVdouble;
typedef vector<VVVdouble> VVVVdouble;
typedef vector<Vint> VVint;

const MDOUBLE VERYSMALL = static_cast<MDOUBLE>(-1.7E+23);
const MDOUBLE VERYBIG = static_cast<MDOUBLE>(1.7E+23);
const MDOUBLE EPSILON = static_cast<MDOUBLE>(1E-23);

#endif
  

