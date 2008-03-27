#include "brLenOpt.h"
//#include "printCoOccor.h"
#include "computeUpAlg.h"
#include "computeDownAlg.h"
#include "computePijComponent.h"
#include "logFile.h"
#include "likelihoodComputation.h"
#include <cmath>
using namespace treeInterface;
using namespace likelihoodComputation;

void compute_dltk_d2ltk2(computePijGam& pij0,
						   computePijGam& pij1,
						   computePijGam& pij2,
						   sequenceContainer1G& sc,
						 stochasticProcess& sp,
						const Vdouble * weights,
						 const int nodeId,
								   const suffStatGlobalGam& cup,
								   const suffStatGlobalGam& cdown,
								   MDOUBLE& ltk,
								   MDOUBLE& dltk,
								   MDOUBLE& d2ltk2) {
	MDOUBLE sum0=0.0;
	MDOUBLE sum1=0.0;
	MDOUBLE sum2=0.0;
	MDOUBLE rate=0.0;
	for (int pos=0; pos < sc.seqLen(); ++pos){
		if ((weights!=NULL) && ((*weights)[pos]==0)) continue;

		MDOUBLE exp0=0.0;
		MDOUBLE exp1=0.0;
		MDOUBLE exp2=0.0;
		MDOUBLE tmp = 0.0;
		for (int alph1=0; alph1 <sc.alphabetSize(); ++alph1){
			for (int alph2=0; alph2 <sc.alphabetSize(); ++alph2){
				for (int rateCategor = 0; rateCategor<sp.categories(); ++rateCategor) {
					rate = sp.rates(rateCategor);

					tmp = sp.ratesProb(rateCategor)*
						cup.get(pos,rateCategor,nodeId,alph1)*
						cdown.get(pos,rateCategor,nodeId,alph2)*
						sp.freq(alph1);

//					without the tpijs...
//					exp0+= tmp * sp.Pij_t(alph1,alph2,dist*rate);
//					exp1+= tmp *sp.dPij_dt(alph1,alph2,dist*rate)*rate;
//					exp2+= tmp *sp.d2Pij_dt2(alph1,alph2,dist*rate)*rate*rate;

//					
					exp0+= tmp *  pij0.getPij(rateCategor,nodeId,alph1,alph2); 
					exp1+= tmp *  pij1.getPij(rateCategor,nodeId,alph1,alph2)*rate;
					exp2+= tmp *  pij2.getPij(rateCategor,nodeId,alph1,alph2)*rate*rate;
						

				}
			}
		}

		if (exp0 == 0.0) errorMsg::reportError(" div by zero in function compute_dltk_d2ltk2");
		if (exp0 < 0.0) errorMsg::reportError(" negative log in function compute_dltk_d2ltk2");

		if (weights==NULL) {
			sum0+=log(exp0);
			sum1+= exp1/exp0;
			sum2+= (exp0*exp2-exp1*exp1)/(exp0*exp0);
		}
		else {
			MDOUBLE factor = (*weights)[pos];
			sum0+=(log(exp0)*(factor));
			sum1+= exp1/exp0*(factor);
			sum2+= ((exp0*exp2-exp1*exp1)/(exp0*exp0))*(factor);
		}

	}
	ltk=sum0;
	dltk = sum1;
	d2ltk2 = sum2;

//	LOG(5,<<endl);
//	LOG(5,<<" dltk = "<<dltk<<endl);
//	LOG(5,<<" d2ltk2 = "<<d2ltk2<<endl);

}	


MDOUBLE computeLtkCheck(sequenceContainer1G& sc,
						stochasticProcess& sp,
						const Vdouble * weights,
						const int nodeId,
								   const suffStatGlobalGam& cup,
								   const suffStatGlobalGam& cdown,
								   MDOUBLE newDist) {

// THIS IS USED TO CHECK THE LIKELIHOOD AFTER A CHANGE IN ONE BRANCH.

	MDOUBLE sum0=0.0;
	MDOUBLE rate=0.0;

	for (int pos=0; pos < sc.seqLen(); ++pos){
		if ((weights!=NULL) && ((*weights)[pos]==0)) continue;
		MDOUBLE exp0=0.0;
		//MDOUBLE exp1=0.0;
		//MDOUBLE exp2=0.0;
		MDOUBLE tmp = 0.0;
		for (int alph1=0; alph1 < sc.alphabetSize(); ++alph1){
			for (int alph2=0; alph2 < sc.alphabetSize(); ++alph2){
				for (int rateCategor = 0; rateCategor<sp.categories(); ++rateCategor) {
					rate = sp.rates(rateCategor);

					tmp = sp.ratesProb(rateCategor)*
						cup.get(pos,rateCategor,nodeId,alph1)*
						cdown.get(pos,rateCategor,nodeId,alph2)*
						sp.freq(alph1);

//					without the tpijs...
					exp0+= tmp * sp.Pij_t(alph1,alph2,newDist*rate);
				}
			}
		}
		if (exp0 <= 0.0) {
			cerr<<" position is: "<<pos<<endl;
			errorMsg::reportError(" negative log in function computeLtkCheck");
		}
		sum0 += log(exp0)* (weights?(*weights)[pos]:1);
	}
	return sum0;
}	



void nwRafImprovIt0(sequenceContainer1G& sc,
						stochasticProcess& sp,
						const Vdouble * weights,
						tree::nodeP in_nodep,
									   const suffStatGlobalGam& cup,
									   const suffStatGlobalGam& cdown) {
	MDOUBLE res = 0.0;
	MDOUBLE oldDis2father = in_nodep->dis2father();
	MDOUBLE ltk = computeLtkCheck(sc,sp,weights,in_nodep->id(),cup,cdown,oldDis2father);

	Vdouble L(6);
	Vdouble R(6);
	R[0] = 0.0001;
	R[1] = 0.001;
	R[2] = 0.01;
	R[3] = 0.1;
	R[4] = 1;
	R[5] = 2;
	L[0] = computeLtkCheck(sc,sp,weights,in_nodep->id(),cup,cdown,R[0]);
	L[1] = computeLtkCheck(sc,sp,weights,in_nodep->id(),cup,cdown,R[1]);
	L[2] = computeLtkCheck(sc,sp,weights,in_nodep->id(),cup,cdown,R[2]);
	L[3] = computeLtkCheck(sc,sp,weights,in_nodep->id(),cup,cdown,R[3]);
	L[4] = computeLtkCheck(sc,sp,weights,in_nodep->id(),cup,cdown,R[4]);
	L[5] = computeLtkCheck(sc,sp,weights,in_nodep->id(),cup,cdown,R[5]);
	
	MDOUBLE maxV=VERYSMALL;
	for (int z=0; z< R.size(); ++z) {
		if (L[z]>maxV) {res = R[z]; maxV=L[z];}
	}
		
	MDOUBLE lAfterChange = computeLtkCheck(sc,sp,weights,in_nodep->id(),cup,cdown,res);
	if (lAfterChange > ltk) {
		in_nodep->setDisToFather(res);
	}
	//LOG(5,<<" old dis = "<<oldDis2father<< "new dis = "<<res<<" suppose to be"<<stamCheck<<endl);
	return;
}

void nwRafImprov(computePijGam& pij0,
						   computePijGam& pij1,
						   computePijGam& pij2,
						   sequenceContainer1G& sc,
						stochasticProcess& sp,
						const Vdouble * weights,
						tree::nodeP in_nodep,
									   const suffStatGlobalGam& cup,
									   const suffStatGlobalGam& cdown) {
	MDOUBLE res = 0.0;
	MDOUBLE oldDis2father = in_nodep->dis2father();
	MDOUBLE ltk,dltk, d2ltk2;

	compute_dltk_d2ltk2(pij0,pij1,pij2,sc,sp,weights,in_nodep->id(),cup,cdown,ltk,dltk,d2ltk2);

//	checking the derivations!
/*	MDOUBLE delta = 0.00001;
	MDOUBLE checkik = computeLtkCheck(sc,sp,weights,in_nodep->id(),cup,cdown,in_nodep->dis2father());
	MDOUBLE checkikplus = computeLtkCheck(sc,sp,weights,in_nodep->id(),cup,cdown,in_nodep->dis2father()+delta);
	MDOUBLE evalderiv1 = (checkikplus-checkik)/delta;
	MDOUBLE checkikminus = computeLtkCheck(sc,sp,weights,in_nodep->id(),cup,cdown,in_nodep->dis2father()-delta);
	MDOUBLE evalderiv2 = (checkik-checkikminus)/delta;
	MDOUBLE evalsecDeriv = (evalderiv1-evalderiv2)/delta;
	
	cerr<<"node="<<in_nodep->name()<<endl;
	cerr<<"delta="<<delta<<endl;
	cerr<<"checkik="<<checkik<<endl;
	cerr<<"checkikplus="<<checkikplus<<endl;
	cerr<<"evalderiv1="<<evalderiv1<<endl;
	cerr<<"checkikminus="<<checkikminus<<endl;
	cerr<<"evalderiv2="<<evalderiv2<<endl;
	cerr<<"evalsecDeriv="<<evalsecDeriv<<endl;
	cerr<<"ltk == "<<ltk<<endl;
	cerr<<"dltk == "<<dltk<<endl;
	cerr<<"d2ltk2 == "<<d2ltk2<<endl;
	cerr<<"==============================="<<endl<<endl;
	int z; cin>>z;
	exit(434);
*/
//
//
//
//
//
//
//
//

//
//
//
//
//
//
//
//
//
//




	if (d2ltk2 == 0.0) res =  oldDis2father;
	else {
		res = oldDis2father - dltk / d2ltk2; // check num rec...
	}

	const MDOUBLE factor = 1.5;
	if (res > factor*oldDis2father) {
		res= factor*oldDis2father;
		MDOUBLE lAfterDoubling = computeLtkCheck(sc,sp,weights,in_nodep->id(),cup,cdown,res);
		if (lAfterDoubling > ltk) {
			in_nodep->setDisToFather(res);
		// CHECKING IF WE SHOULD DOUBLE AGAIN?
			MDOUBLE lAfterSecondDoubling = computeLtkCheck(sc,sp,weights,in_nodep->id(),cup,cdown,factor*res);
			if (lAfterSecondDoubling > ltk) {
				res = factor*res;
				in_nodep->setDisToFather(res);
			}
		}

	}
	if (res <oldDis2father/factor) {
		res= oldDis2father/factor;
		MDOUBLE lAfterDoubling = computeLtkCheck(sc,sp,weights,in_nodep->id(),cup,cdown,res);
		if (lAfterDoubling > ltk) {
			in_nodep->setDisToFather(res);
		// CHECKING IF WE SHOULD DOUBLE AGAIN?
			MDOUBLE lAfterSecondDoubling = computeLtkCheck(sc,sp,weights,in_nodep->id(),cup,cdown,res/factor);
			if (lAfterSecondDoubling > ltk) {
				res = res/factor;
				in_nodep->setDisToFather(res);
			}
		}

	}

	

	//reCheckAfterEachBrLenChange
	MDOUBLE lAfterChange = computeLtkCheck(sc,sp,weights,in_nodep->id(),cup,cdown,res);
	if (lAfterChange > ltk) {
		in_nodep->setDisToFather(res);
	}
	//LOG(5,<<" old dis = "<<oldDis2father<< "new dis = "<<res<<" suppose to be"<<stamCheck<<endl);
	if (in_nodep->dis2father() > 2.0) {
		in_nodep->setDisToFather(2.0);
	}
	else if (in_nodep->dis2father() <0.000001) {
		in_nodep->setDisToFather(0.000001);  ; // MIN value SAME AS PHYLIP...
		//res=oldDis2father*0.3; 
	}

	return;
}

void revaluateBranchLengthIt0(sequenceContainer1G& sc,
						stochasticProcess& sp,
						const Vdouble * weights,
						const tree& et,
						tree::nodeP in_nodep,
									   const suffStatGlobalGam& cup,
									   const suffStatGlobalGam& cdown) {
	for(int i=0; i<in_nodep->sons.size();i++) {
		revaluateBranchLengthIt0(sc,sp,weights,et,in_nodep->sons[i],cup,cdown);
	}
	if (in_nodep == et.iRoot()) return;
	nwRafImprovIt0(sc,sp,weights,in_nodep,cup,cdown);
}

void revaluateBranchLength(computePijGam& pij0,
						   computePijGam& pij1,
						   computePijGam& pij2,
						   sequenceContainer1G& sc,
						stochasticProcess& sp,
						const Vdouble * weights,
						const tree& et,
						tree::nodeP in_nodep,
									   const suffStatGlobalGam& cup,
									   const suffStatGlobalGam& cdown) {
	for(int i=0; i<in_nodep->sons.size();i++) {
		revaluateBranchLength(pij0,pij1,pij2,sc,sp,weights,et,in_nodep->sons[i],cup,cdown);
	}
	if (in_nodep == et.iRoot()) return;
	nwRafImprov(pij0,pij1,pij2,sc,sp,weights,in_nodep,cup,cdown);
}



MDOUBLE brLenOpt::optimizeBranchLength1G(tree& et,
									sequenceContainer1G& sc,
									stochasticProcess& sp,
									const Vdouble * weights,
									const int maxIterations,
									const MDOUBLE epsilon) {
//	cerr<<" ENTERING2 optimizeBranchLengthPrivate"<<endl;
//	MDOUBLE CHECK = likelihoodComputation::getTreeLikelihood(_et,_pi,NULL);
//	cerr<<"CHECK in brLenOpt::optimizeBranchLengthPrivate= "<<CHECK<<endl;

	MDOUBLE newL=VERYSMALL;
	int it;
	suffStatGlobalGam cup;
	suffStatGlobalGam cdown;

	cup.allocatePlace(sc.seqLen(),sp.categories(),et.iNodes(),sc.alphabetSize());
	cdown.allocatePlace(sc.seqLen(),sp.categories(),et.iNodes(),sc.alphabetSize());

	computePijGam pij0;
	computePijGam pij1;
	computePijGam pij2;

	pij0.fillPij(et,sp,sc.alphabetSize(),0);
	pij1.fillPij(et,sp,sc.alphabetSize(),1);
	pij2.fillPij(et,sp,sc.alphabetSize(),2);

	computeUpAlg cupAlg;
	computeDownAlg cdownAlg;

	int pos = 0;
	int categor = 0;
	for (pos = 0; pos < sc.seqLen(); ++pos) {
		for (categor = 0; categor < sp.categories(); ++categor) {
			cupAlg.fillComputeUp(et,sc,pos,pij0[categor],cup[pos][categor]);
			cdownAlg.fillComputeDown(et,sc,pos,pij0[categor],cdown[pos][categor],cup[pos][categor]);
		}
	}


	MDOUBLE oldL = likelihoodComputation::getTreeLikelihoodFromUp(et,sc,sp,cup,weights);

	LOG(50,<<"(bbl) startingL= "<<oldL<<endl);
	cerr<<"(bbl) startingL= "<<oldL<<endl;
	for (it = 0; it < maxIterations; ++it) {

//		it =1; cerr<<"starting with the starting tree without it =0 !!!";

//		LOG(50,<<"(bbl)x it= "<<it<<" newL = "<<newL<<endl);
//
//		LOG(1,<<"tmp tree, bbl it:"<<it<<endl);
//		LOGDO(1,_et.output(myLog::LogFile(),tree::PHYLIP));
		
		tree oldT = et;
		if (it==0) {
			revaluateBranchLengthIt0(sc,sp,weights,et,et.iRoot(),cup,cdown);
		}
		else {
			revaluateBranchLength(pij0,pij1,pij2,sc,sp,weights,et,et.iRoot(),cup,cdown);
		}
		pij0.fillPij(et,sp,sc.alphabetSize(),0);
		pij1.fillPij(et,sp,sc.alphabetSize(),1);
		pij2.fillPij(et,sp,sc.alphabetSize(),2);

		for (int pos = 0; pos < sc.seqLen(); ++pos) {
			for (int categor = 0; categor < sp.categories(); ++categor) {
				cupAlg.fillComputeUp(et,sc,pos,pij0[categor],cup[pos][categor]);
				cdownAlg.fillComputeDown(et,sc,pos,pij0[categor],cdown[pos][categor],cup[pos][categor]);
			}
		}
		newL = likelihoodComputation::getTreeLikelihoodFromUp(et,sc,sp,cup,weights);
		cerr<<"(bbl) newL= "<<newL<<endl;
	

		if ((newL < oldL + epsilon) && (it>0)) {
		  if (newL < oldL) {
		    et = oldT;
		    //LOGDO(1000, printAllCC(sc,sp,weights,et,et.iRoot(),cup,cdown,myLog::LogFile()));
		    return oldL;
		  }
		  else {
		    //LOGDO(1000, printAllCC(sc,sp,weights,et,et.iRoot(),cup,cdown,myLog::LogFile()));
		    return newL;
		  }
		} else {oldL = newL;}
		LOG(50,<<"(bbl)y it= "<<it<<" newL = "<<newL<<endl);
		cerr<<"(bbl)y it= "<<it<<" newL = "<<newL<<endl;
	}
	errorMsg::reportError(" to many iterations in brLenOpt::optimizeBranchLength ");
	return newL;

}


