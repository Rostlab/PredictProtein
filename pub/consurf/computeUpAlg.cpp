#include "computeUpAlg.h"
#include "definitions.h"
#include "seqContainerTreeMap.h"
#include <iostream>
#include <cassert>
using namespace std;

void computeUpAlg::fillComputeUp(const tree& et,
				   const sequenceContainer& sc,
				   const int pos,
				   const computePijHom& pi,
				   suffStatGlobalHomPos& ssc) {

	seqContainerTreeMap sctm(sc,et);

	ssc.allocatePlace(et.iNodes(),pi.alphabetSize());
	treeIterDownTopConst tIt(et);
	for (tree::nodeP mynode = tIt.first(); mynode != tIt.end(); mynode = tIt.next()) {
		int letter;
		if (mynode->sons.empty()) {// leaf
			for(letter=0; letter<pi.alphabetSize();letter++) {
				const int seqID = sctm.seqIdOfNodeI(mynode->id());
				MDOUBLE val = sc.getAlphabet(pos)->relations(sc[seqID][pos],letter);
				//cerr<<"val =" << val <<" "; // REMOVE!
				//cerr<<"_pi->data(mynode->id(),pos)= "<<_pi->data(mynode->id(),pos)<<" ";//REMOVE
				ssc.set(mynode->id(),letter,val);
			}
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
				ssc.set(mynode->id(),letter,total_prob);
			}
		}
	}
}

void computeUpAlg::fillComputeUp(const tree& et,
				   const sequenceContainer& sc,
				   const int pos,
				   const stochasticProcess& sp,
				   suffStatGlobalHomPos& ssc) {

	seqContainerTreeMap sctm(sc,et);

	ssc.allocatePlace(et.iNodes(),sp.alphabetSize());
	treeIterDownTopConst tIt(et);
	for (tree::nodeP mynode = tIt.first(); mynode != tIt.end(); mynode = tIt.next()) {
		int letter;
		if (mynode->sons.empty()) {// leaf
			for(letter=0; letter<sp.alphabetSize();letter++) {
				const int seqID = sctm.seqIdOfNodeI(mynode->id());
				MDOUBLE val = sc.getAlphabet(pos)->relations(sc[seqID][pos],letter);
				//cerr<<"val =" << val <<" "; // REMOVE!
				//cerr<<"_sp->data(mynode->id(),pos)= "<<_sp->data(mynode->id(),pos)<<" ";//REMOVE
				ssc.set(mynode->id(),letter,val);
			}
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
		}
	}
}

void computeUpAlg::fillComputeUpSpecificGlobalRate(const tree& et,
				   const sequenceContainer& sc,
				   const int pos,
				   const stochasticProcess& sp,
				   suffStatGlobalHomPos& ssc,
				   const MDOUBLE gRate) {
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
