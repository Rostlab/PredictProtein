#include "computeUpAlg.h"
#include "definitions.h"
#include "seqContainerTreeMap.h"
#include <iostream>
#include <cassert>
#include <cmath>
using namespace std;

void computeNodeFactorAndSetSsc(MDOUBLE & minFactor,suffStatGlobalHomPos& ssc, int nodeId, const int alphSize){
	// given a number = probability (val), it is changed to a new number which is 10 to the power of factor + val.
	// for example if val = 0.001, it is changed to 0.1 and factor 2.
	minFactor=100000;
	for (int i=0; i < alphSize; ++i) {
		MDOUBLE tmpfactor=0;
		MDOUBLE val = ssc.get(nodeId,i);
		if (val >0) {
			while (val < 0.1) {
				val *=10;
				tmpfactor++;
			}
		}
		else tmpfactor=minFactor;
		if (tmpfactor<minFactor) minFactor=tmpfactor;
	}
	for (int j=0; j < alphSize; ++j) {
		MDOUBLE tmp = ssc.get(nodeId,j);
		tmp = tmp * pow(10,minFactor);
		ssc.set(nodeId,j,tmp);
	}
}

void computeUpAlg::fillComputeUpWithFactors(const tree& et,
				   const sequenceContainer& sc,
				   const int pos,
				   const computePijHom& pi,
				   suffStatGlobalHomPos& ssc,
				   vector<MDOUBLE>& factors) {
	factors.resize(et.iNodes(),0.0);
	seqContainerTreeMap sctm(sc,et);

	ssc.allocatePlace(et.iNodes(),pi.alphabetSize());
	treeIterDownTopConst tIt(et);
	for (tree::nodeP mynode = tIt.first(); mynode != tIt.end(); mynode = tIt.next()) {
		int letter;
		if (mynode->sons.empty()) {// leaf
			for(letter=0; letter<pi.alphabetSize();letter++) {
				const int seqID = sctm.seqIdOfNodeI(mynode->id());
				MDOUBLE val = sc.getAlphabet(pos)->relations(sc[seqID][pos],letter);
				ssc.set(mynode->id(),letter,val);
			}
			computeNodeFactorAndSetSsc(factors[mynode->id()],ssc,mynode->id(),pi.alphabetSize());
		}
		else {
			for(letter=0; letter<pi.alphabetSize();letter++) {
				MDOUBLE total_prob=1.0;
				for(int i=0; i < mynode->sons.size();++i){				
					MDOUBLE prob=0.0;
					for(int letInSon=0; letInSon<pi.alphabetSize();letInSon++) {
						prob += ssc.get(mynode->sons[i]->id(),letInSon)*
							pi.getPij(mynode->sons[i]->id(),letter,letInSon);
					}
					total_prob*=prob;
				}
				MDOUBLE tmpF=0;
				ssc.set(mynode->id(),letter,total_prob);
			}
			computeNodeFactorAndSetSsc(factors[mynode->id()],ssc,mynode->id(),pi.alphabetSize());
			for(int k=0; k < mynode->sons.size();++k) {
				factors[mynode->id()]+=factors[mynode->sons[k]->id()];
			}
		}
	}
}

void computeUpAlg::fillComputeUpWithFactors(const tree& et,
				   const sequenceContainer& sc,
				   const int pos,
				   const stochasticProcess& sp,
				   suffStatGlobalHomPos& ssc,
				   vector<MDOUBLE>& factors) {
	factors.resize(et.iNodes(),0.0);
	seqContainerTreeMap sctm(sc,et);

	ssc.allocatePlace(et.iNodes(),sp.alphabetSize());
	treeIterDownTopConst tIt(et);
	for (tree::nodeP mynode = tIt.first(); mynode != tIt.end(); mynode = tIt.next()) {
		int letter;
		if (mynode->sons.empty()) {// leaf
			for(letter=0; letter<sp.alphabetSize();letter++) {
				const int seqID = sctm.seqIdOfNodeI(mynode->id());
				MDOUBLE val = sc.getAlphabet(pos)->relations(sc[seqID][pos],letter);
				ssc.set(mynode->id(),letter,val);
			}
			computeNodeFactorAndSetSsc(factors[mynode->id()],ssc,mynode->id(),sp.alphabetSize());
		}
		else {
			for(letter=0; letter<sp.alphabetSize();letter++) {
				MDOUBLE total_prob=1.0;
				for(int i=0; i < mynode->sons.size();++i){				
					MDOUBLE prob=0.0;
					for(int letInSon=0; letInSon<sp.alphabetSize();letInSon++) {
						prob += ssc.get(mynode->sons[i]->id(),letInSon)*
							sp.Pij_t(letter,letInSon,mynode->sons[i]->dis2father()*sp.getGlobalRate());// taking care of the glubal is new.
					}
					assert(prob>=0);
				total_prob*=prob;
				}
				ssc.set(mynode->id(),letter,total_prob);
			}
			computeNodeFactorAndSetSsc(factors[mynode->id()],ssc,mynode->id(),sp.alphabetSize());
			for(int k=0; k < mynode->sons.size();++k) {
				factors[mynode->id()]+=factors[mynode->sons[k]->id()];
			}
		}
	}
}

void computeUpAlg::fillComputeUpSpecificGlobalRateFactors(const tree& et,
				   const sequenceContainer& sc,
				   const int pos,
				   const stochasticProcess& sp,
				   suffStatGlobalHomPos& ssc,
				   const MDOUBLE gRate,
				   vector<MDOUBLE>& factors) {
	factors.resize(et.iNodes(),0.0);
	seqContainerTreeMap sctm(sc,et);

	ssc.allocatePlace(et.iNodes(),sp.alphabetSize());
	treeIterDownTopConst tIt(et);
	for (tree::nodeP mynode = tIt.first(); mynode != tIt.end(); mynode = tIt.next()) {
#ifdef VERBOS
		cerr<<endl<<endl<<"doing node: "<<mynode->name()<<endl;
#endif
		int letter;
		if (mynode->sons.empty()) {// leaf
			for(letter=0; letter<sp.alphabetSize();letter++) {
				const int seqID = sctm.seqIdOfNodeI(mynode->id());
				MDOUBLE val = sc.getAlphabet(pos)->relations(sc[seqID][pos],letter);
				ssc.set(mynode->id(),letter,val);
			}
			computeNodeFactorAndSetSsc(factors[mynode->id()],ssc,mynode->id(),sp.alphabetSize());
		}
		else {
			int letterWithTotalProbEqZero =0;
			for(letter=0; letter<sp.alphabetSize();letter++) {
				MDOUBLE total_prob=1.0;
				for(int i=0; i < mynode->sons.size();++i){				
					MDOUBLE prob=0.0;
					for(int letInSon=0; letInSon<sp.alphabetSize();letInSon++) {
						assert(ssc.get(mynode->sons[i]->id(),letInSon)>=0);
						assert(sp.Pij_t(letter,letInSon,mynode->sons[i]->dis2father()*gRate)>=0);
						prob += ssc.get(mynode->sons[i]->id(),letInSon)*
							sp.Pij_t(letter,letInSon,mynode->sons[i]->dis2father()*gRate);
					}
				assert(prob>=0);
				total_prob*=prob;
				}
				if (total_prob ==0) ++letterWithTotalProbEqZero;
				
				ssc.set(mynode->id(),letter,total_prob);
			} // end of else
			computeNodeFactorAndSetSsc(factors[mynode->id()],ssc,mynode->id(),sp.alphabetSize());
			for(int k=0; k < mynode->sons.size();++k) {
				factors[mynode->id()]+=factors[mynode->sons[k]->id()];
			}
			if (letterWithTotalProbEqZero == sp.alphabetSize() && (mynode->sons.empty()==false)) {
				cerr<<" total prob =0";
				for (int z=0; z <mynode->sons.size(); ++z) {
					cerr<<"son "<<z<<" is "<<mynode->sons[z]->name()<<endl;
					cerr<<"dis2father is "<<mynode->sons[z]->dis2father()<<endl;
					for(int letInSon=0; letInSon<sp.alphabetSize();letInSon++) {
						cerr<<"let = "<<letInSon<<endl;
						cerr<<"ssc.get(mynode->sons[z]->id(),letInSon) = "<<ssc.get(mynode->sons[z]->id(),letInSon)<<endl;
//						cerr<<"sp.Pij_t(letter,letInSon,mynode->sons[i]->dis2father()*gRate) = "<<sp.Pij_t(letter,letInSon,mynode->sons[i]->dis2father()*gRate)<<endl;
//						cerr<<"mynode->sons[i]->dis2father() = "<<mynode->sons[i]->dis2father()<<endl;

					
					
					
					
					}
				}
#ifdef WIN32
				system("PAUSE");
#endif
				exit(3);
			}
		}
	}
}
