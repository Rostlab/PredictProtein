#include "numRec.h"
#include <cassert>



void validateSym(VVdouble & v) {
	const MDOUBLE epsilon = 0.00000001;
	for (int i=0; i < v.size(); ++i) {
		for (int j=i+1; j < v.size(); ++j) {
			if (v[i][j] - v[j][i]> epsilon) {
				cerr<<"v["<<i<<"]["<<j<<"]="<<v[i][j]<<endl;
				cerr<<"v["<<j<<"]["<<i<<"]="<<v[j][i]<<endl;

				errorMsg::reportError("trying to find eigen values to non-sym matrix");
			}
			else v[i][j] = v[j][i];
		}
	}
}

int MyJacobi(VVdouble &Insym, VVdouble &RightEigenV, Vdouble &EigenValues) {
  validateSym(Insym);
  const int MaxNumberOfSweeps = 10000;
  VVdouble& v = RightEigenV;
  VVdouble& a = Insym;
  Vdouble& d = EigenValues;
  //CheckSizeAndTypeAndResizeIfNessary();
  int i,j;
  const int size = v.size();
	
  // preparing V to be the indentity matrix
  for (i=0; i<size; ++i) {
    for (int j=0; j<size ; ++j) v[i][j]=0.0;
    v[i][i] = 1.0;
  }

	
  for (i=0 ; i<size; ++i ) {
    d[i] = a[i][i];
  }

  MDOUBLE sm = 0.0; // sm is the sum of the off-diagonal elements
  int ip, iq;
  for (i = 0; i< MaxNumberOfSweeps ; ++i) {
    sm = 0.0;
    for (ip = 0; ip<size ; ++ip) {
      for (iq = ip+1; iq <size; ++iq)
	sm +=fabs (a[ip][iq]);
    }
    if (sm == 0.0) return 0; // the program is suppose to return here, after some rounds of i.
    MDOUBLE tresh;
    if (i<3) tresh = 0.2 * sm / (size*size); else tresh = 0.0;

    MDOUBLE g;
    for (ip=0 ; ip<size; ++ip) {
      for (iq = ip+1 ; iq<size; ++iq) {
	g = 100.0*fabs(a[ip][ip]);
	if (	i>3 &&
		(fabs(d[ip]+g) == fabs(d[ip])) && 
		(fabs(d[iq]+g)==fabs(d[iq]))
		) a[ip][iq] = 0.0;
	else if (fabs(a[ip][iq]) > tresh) {
	  MDOUBLE h;
	  MDOUBLE t;
	  MDOUBLE theta;
	  h = d[iq]-d[ip];
	  assert(h!=0);
	  if (fabs(h) + g == fabs(h)) t = a[ip][iq] / h;
	  else {
	    theta = 0.5*h/(a[ip][iq]);
	    t = 1.0 / (fabs(theta)+sqrt(1.0+theta*theta));
	    if (theta<0.0) t = -t;
	  }
	  MDOUBLE c,s;
	  c = 1.0 / sqrt(1.0+t*t);
	  s = t*c;
	  MDOUBLE tau;
	  tau = s/ (1.0 + c);
	  h = t * a[ip][iq];

	  d[ip] = d[ip] - t * a[ip][iq];
	  d[iq] = d[iq] + t * a[ip][iq];
	  a[ip][iq]=0.0;
	  MDOUBLE tmp1, tmp2;
	  for (j = 0; j < ip; ++j) {
	    tmp1 = a[j][ip] - s*(a[j][iq]+a[j][ip]*tau); // updating the above element of a...
	    tmp2 = a[j][iq] + s*(a[j][ip]-a[j][iq]*tau);
	    a[j][ip] = tmp1; 
	    a[j][iq] = tmp2;
	  }
					
	  for (j = ip+1;j<iq; ++j) {
	    tmp1 = a[ip][j] - s*(a[j][iq]+a[ip][j]*tau); // updating the above element of a..
	    tmp2 = a[j][iq] + s*(a[ip][j]-a[j][iq]*tau);
	    a[ip][j] = tmp1;
	    a[j][iq] = tmp2;
	  }

	  for (j = iq+1; j< size ; ++j) {
	    tmp1 = a[ip][j] - s*(a[iq][j]+a[ip][j]*tau); // updating the above element of a..
	    tmp2 = a[iq][j] + s*(a[ip][j]-a[iq][j]*tau);
	    a[ip][j] = tmp1;
	    a[iq][j] = tmp2;
	  }
					
	  for (j = 0; j< size ; ++j) {
	    tmp1 = v[j][ip] - s*(v[j][iq]+v[j][ip]*tau); // updating v
	    tmp2 = v[j][iq] + s*(v[j][ip]-v[j][iq]*tau);
	    v[j][ip] = tmp1;
	    v[j][iq] = tmp2;
	  }
	} // end of "else if (fabs(a[ip][iq] > tresh)"
      } // end of for (iq = ...
    } // end of for (ip = ...
  } // end of for (i = 0; i< MaxNumberOfSweeps ; ++i) {
  vector<string> err;
  err.push_back("problems in function MyJacobi. more than MaxNumberOfSweeps were necesary.");
  errorMsg::reportError(err);

  return -1;
} //end of function

