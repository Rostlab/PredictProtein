//#include <strstream> //oldVersion
#include <sstream>
#include <cassert>
#include "readDatMatrix.h"
#include "errorMsg.h"

//#define VERBOS

void normalizeQ(VVdouble& q, const Vdouble& freq) {
	MDOUBLE sum =0;
	int i=0,j=0;
	for (i=0; i < q.size(); ++i) {
		sum += q[i][i]*freq[i];
	}
	assert(sum!=0);
	MDOUBLE oneDividedBySum = -1.0/sum; // to avoid many divisions.

	for (i=0; i < q.size(); ++i) {
		for (j=0; j < q.size(); ++j) {
			q[i][j] = q[i][j]*oneDividedBySum;
		}
	}
}

void readDatMatrixFromFile(const string & matrixFileName,
						   VVdouble & subMatrix,
						   Vdouble & freq) {
	int i=0,j=0; //indices
	ifstream in(matrixFileName.c_str());
	if (!in) {
		errorMsg::reportError("unable to open matrix data file");
	}
	subMatrix.resize(20);
	for ( i=0; i < 20; ++i) subMatrix[i].resize(20,0.0);
	freq.resize(20,0.0);

	for (i=1; i < 20; ++i) {
		for (j=0; j <i;++j) {
			in>>subMatrix[i][j];
			subMatrix[j][i] = subMatrix[i][j];
		}
	}
	for (i=0; i < 20; ++i) {
		in>>freq[i];
	}
	in.close();

	//check:
	//cerr<<" priting the 5*5 top part of the sub matrix: "<<endl;
	//for (i=0; i < 5; ++i) {
	//	for (j=0; j <5;++j) {
	//		cerr<<subMatrix[i][j]<<" ";
	//	}
	//	cerr<<endl;
	//}
	//cerr<<"the 5 last freqs: "<<endl;
	//for (i=15; i < 20; ++i) {
	//	cerr<<freq[i]<<" ";
	//}
}

void readDatMatrixFromString(const string & matrixFileString,
			     VVdouble & subMatrix,
			     Vdouble & freq) {
	int i=0,j=0; //indices	
	stringstream in(matrixFileString.c_str());
	//istrstream in(matrixFileString.c_str()); // OLD VERSION
	if (!in) {
		errorMsg::reportError("unable to open matrix data buffer");
	}
	subMatrix.resize(20);
	for ( i=0; i < 20; ++i) subMatrix[i].resize(20,0.0);
	freq.resize(20,0.0);

	for (i=1; i < 20; ++i) {
		for (j=0; j <i;++j) {
			in>>subMatrix[i][j];
			subMatrix[j][i] = subMatrix[i][j];
		}
	}
	for (i=0; i < 20; ++i) {
		in>>freq[i];
	}
}


#include "fromQtoPt.h"
#include "definitions.h"

#include <iostream>
using namespace std;

void pupAll::fillMatricesFromFile(const string & dataFileString) {
	VVdouble sMatrix;
	readDatMatrixFromFile(dataFileString,sMatrix,_freq);
	//	readDatMatrixFromString(dataFileString,sMatrix,_freq);
	VVdouble qMatrix = fromWagSandFreqToQ(sMatrix,_freq);
	
	q2pt q2pt1;
	q2pt1.fillFromRateMatrix(_freq,qMatrix);
	_leftEigen = q2pt1.getLeftEigen();
	_rightEigen = q2pt1.getRightEigen();
	_eigenVector = q2pt1.getEigenVec();
}
void pupAll::fillMatricesFromFile(const string & dataFileString, const Vdouble & freq) {
#ifdef VERBOS
	cerr<<"dataFileString = "<<dataFileString<<endl;
#endif

	VVdouble sMatrix;
	readDatMatrixFromFile(dataFileString,sMatrix,_freq);
	_freq=freq;
	VVdouble qMatrix = fromWagSandFreqToQ(sMatrix,_freq);
	
	q2pt q2pt1;
	q2pt1.fillFromRateMatrix(_freq,qMatrix);
	_leftEigen = q2pt1.getLeftEigen();
	_rightEigen = q2pt1.getRightEigen();
	_eigenVector = q2pt1.getEigenVec();
}

void pupAll::fillMatrices(const string & dataFileString) {
	VVdouble sMatrix;
	readDatMatrixFromString(dataFileString,sMatrix,_freq);
	//	readDatMatrixFromString(dataFileString,sMatrix,_freq);
	VVdouble qMatrix = fromWagSandFreqToQ(sMatrix,_freq);
	
	q2pt q2pt1;
	q2pt1.fillFromRateMatrix(_freq,qMatrix);
	_leftEigen = q2pt1.getLeftEigen();
	_rightEigen = q2pt1.getRightEigen();
	_eigenVector = q2pt1.getEigenVec();
}
void pupAll::fillMatrices(const string & dataFileString, const Vdouble & freq) {
	VVdouble sMatrix;
	readDatMatrixFromString(dataFileString,sMatrix,_freq);
	_freq=freq;
	VVdouble qMatrix = fromWagSandFreqToQ(sMatrix,_freq);
	
	q2pt q2pt1;
	q2pt1.fillFromRateMatrix(_freq,qMatrix);
	_leftEigen = q2pt1.getLeftEigen();
	_rightEigen = q2pt1.getRightEigen();
	_eigenVector = q2pt1.getEigenVec();
}

const MDOUBLE pupAll::Pij_t(const int i, const int j, const MDOUBLE t) const {
	if (t<0) {
		cerr<<"negative length in routine Pij_t "<<endl;
		cerr<<" t = " <<t<<endl;
		errorMsg::reportError("negative length in routine Pij_t");
	}
//	if ((_freq[i] == 0.0) || (_freq[j] == 0.0)) return 0.0;
	MDOUBLE sum=0;
	for (int k=0 ; k<20 ; ++k) {
		sum+=( _leftEigen[i][k]*_rightEigen[k][j]*exp(_eigenVector[k]*t) );
	}
	if (currectFloatingPointProblems(sum)) return sum; 
//	LOG(1,<<"err Pij_t i="<<i<<" j= "<<j<<" dis= "<<t<<" res= "<<sum<<endl);//sum is not in [0,1]
	errorMsg::reportError("error in function pijt... ");return 0;
}

const MDOUBLE pupAll::dPij_dt(const int i,const  int j, const MDOUBLE t) const {
//	if ((_freq[i] == 0.0) || (_freq[j] == 0.0)) return 0.0;
	MDOUBLE sum=0;
	for (int k=0 ; k<20 ; ++k) {
		sum+=( _leftEigen[i][k]*_rightEigen[k][j]*exp(_eigenVector[k]*t)*_eigenVector[k]);
	}
	return sum;
}


const MDOUBLE pupAll::d2Pij_dt2(const int i,const int j, const MDOUBLE t) const {
//	if ((_freq[i] == 0.0) || (_freq[j] == 0.0)) return 0.0;
	MDOUBLE sum=0;;
	for (int k=0 ; k<20 ; ++k) {
		sum+=( _leftEigen[i][k]*_rightEigen[k][j]*exp(_eigenVector[k]*t)*_eigenVector[k]*_eigenVector[k]);
	}
	return sum;
}

bool pupAll::currectFloatingPointProblems(MDOUBLE& sum) const {
	if ((sum * (sum+err_allow_for_pijt_function))<0) sum=0;
	if (((sum-1) * (sum-1.0-err_allow_for_pijt_function))<0) sum=1;
	if ((sum>1) || (sum<0)) return false;
	return true;
}

VVdouble fromWagSandFreqToQ(const VVdouble & s,const Vdouble& freq){
	VVdouble q(s.size());
	for (int z=0; z < q.size(); ++z) q[z].resize(s.size(),0.0);
	int i,j;
	MDOUBLE sum;
	for ( i=0; i < s.size(); ++i) {
		sum =0;
		for (j=0; j < s.size(); ++j) {
			if (i!=j) q[i][j] = s[i][j]* freq[j];
			sum += q[i][j];
		}
		q[i][i] = -sum;
	}

	// normalizing q:
	normalizeQ(q,freq);


	// check:
	//sum =0;
	//for (i=0; i < s.size(); ++i){
	//	sum += q[i][i]*freq[i];
	//}
	//cerr<<" SUM OF DIAGOPNAL Q IS (should be -1) "<<sum<<endl;
	return q;

}

