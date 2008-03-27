#include "computePijComponent.h"
#include "logFile.h"

void computePijHomSpec::fillPij(const MDOUBLE dis,
					   const stochasticProcess& sp,
					   const int alphabetSize,
					   int derivationOrder) {
	resize(alphabetSize);
	int i,j;
	for (i=0; i<alphabetSize; i++) {
		if (derivationOrder==0)
			_V[i][i] = sp.Pij_t(i,i,dis);
		else if (derivationOrder==1)
			_V[i][i] = sp.dPij_dt(i,i,dis);
		else if (derivationOrder==2)
			_V[i][i] = sp.d2Pij_dt2(i,i,dis);

		for (j=i+1; j<alphabetSize; j++) {
			if (derivationOrder==0)
				_V[i][j] = sp.Pij_t(i,j,dis);
		else if (derivationOrder==1)
				_V[i][j] = sp.dPij_dt(i,j,dis);
		else if (derivationOrder==2)
				_V[i][j] = sp.d2Pij_dt2(i,j,dis);
			if (sp.freq(j) == 0.0) {
				//if (_V[i][j]!=0.0) {
					errorMsg::reportError("error in function fillPij");
				//}
				//_V[j][i] = 0.0;
			}
			else {
				_V[j][i] = _V[i][j]*
					sp.freq(i)/sp.freq(j);
			}
		}
	}
}


void computePijHom::fillPij(const tree& et, const stochasticProcess& sp,
		const int alphabetSize,int derivationOrder) {
	_V.resize(et.iNodes());
	treeIterTopDownConst tIt(et);
	tree::nodeP myNode = tIt.first();
	{// skipping the root, but allocating place for the root pij even if they are not use
	 // to maintain that all arrays have the same size.
		_V[myNode->id()].resize(alphabetSize);
	}
	LOGDO(50,et.output(myLog::LogFile(),tree::ANCESTOR));
	LOGDO(50,et.output(myLog::LogFile(),tree::PHYLIP));
	for (; myNode != tIt.end(); myNode = tIt.next()) {
	  if (!(myNode->isRoot()))
		  _V[myNode->id()].fillPij(myNode->dis2father()*sp.getGlobalRate(),sp,alphabetSize,derivationOrder);
//	  else
//	    myLog::LogFile()<<"ROOT IS "<<myNode->name()<<endl;
	}
}


void computePijGam::fillPij(const tree& et, const stochasticProcess& sp,
		const int alphabetSize,int derivationOrder) {
	_V.resize(sp.categories());
	for (int i=0; i < _V.size(); ++i) {
		tree cp = et;
		cp.multipleAllBranchesByFactor(sp.rates(i)/sp.getGlobalRate());// the global rate is taken care of in the hom pij.
		_V[i].fillPij(cp,sp,alphabetSize,derivationOrder);
	}
}
