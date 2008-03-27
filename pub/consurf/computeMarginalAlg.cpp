#include "computeMarginalAlg.h"
#include <iostream>
#include <cassert>
using namespace std;
/*void computeMarginalAlg::fillMarginalForNodeAndPos(
					const int pos,
					const tree::nodeP& mynode){


	for (int let=0; let < _pi->alphabetSize(); ++let) {
		for (int rate = 0; rate< _pi->categories(); ++rate) {
			if (mynode->sons.empty()) {
				MDOUBLE val=(let==_pi->data(mynode->id(),pos))?1.0:0.0;
				(*_ssc)[mynode->id()].set(pos,rate,let,val);
			} else {
				MDOUBLE val = _cexact->get(mynode->id(),pos,rate,let)/_cProbOfEachPos->getProb(pos);
				(*_ssc)[mynode->id()].set(pos,rate,let,val);
			}
		}
	}
}*/

/*
void computeExactAlg::fillExactNodePos(const tree::nodeP& mynode,
									 const int pos) {	
	int letter;
	for (int rateCategor = 0; rateCategor<_pi->categories(); ++rateCategor) {
		for(letter=0; letter<_pi->alphabetSize();letter++) {
			MDOUBLE prob=0.0;
			for(int letter_in_f=0; letter_in_f<_pi->alphabetSize();letter_in_f++) {
				prob +=_cdown->get(mynode->id(),pos,rateCategor,letter_in_f)*
					_pi->pij(pos)->getPij(mynode->id(),letter,letter_in_f,rateCategor);
			}
			if (mynode->father()==NULL) prob=1.0; // special case of the root.
			prob = prob*_pi->stocProcessFromPos(pos)->freq(letter)*
				_cup->get(mynode->id(),pos,rateCategor,letter);
			(*_ssc)[mynode->id()].set(pos,rateCategor,letter,prob);
		}
	}
}
*/

void computeMarginalAlg::fillComputeMarginal(const tree& et,
					   const sequenceContainer& sc,
					   const stochasticProcess& sp,
					   const int pos,
					   const computePijHom& pi,
					   suffStatGlobalHomPos& ssc,
					   const suffStatGlobalHomPos& cup,
					   const suffStatGlobalHomPos& cdown,
					   MDOUBLE & posProb){

	// filling the exact probs.
	tree::nodeP mynode = NULL;
	ssc.allocatePlace(et.iNodes(),pi.alphabetSize());
	treeIterTopDownConst tIt(et);
	for (mynode = tIt.first(); mynode != tIt.end(); mynode = tIt.next()) {
		assert (mynode != NULL);
		int letter;
		if (mynode->sons.empty()) {
			for(letter=0; letter<pi.alphabetSize();letter++) {
				MDOUBLE val=cup.get(mynode->id(),letter)?1.0:0.0;
				ssc.set(mynode->id(),letter,val);
			}
			continue;
		}
		MDOUBLE sumProb =0;
		for(letter=0; letter<pi.alphabetSize();letter++) {
			MDOUBLE prob=0.0;
			if (mynode->father()==NULL) prob=1.0; // special case of the root.
			else {
				for(int letter_in_f=0; letter_in_f<pi.alphabetSize();letter_in_f++) {
					prob +=cdown.get(mynode->id(),letter_in_f)*
					pi.getPij(mynode->id(),letter,letter_in_f);
				}
			}
			
			prob = prob*sp.freq(letter)*
				cup.get(mynode->id(),letter);
			ssc.set(mynode->id(),letter,prob);
			sumProb += prob;
		}
		for(letter=0; letter<pi.alphabetSize();letter++) {
			MDOUBLE getV = ssc.get(mynode->id(),letter);
			ssc.set(mynode->id(),letter,getV/sumProb);
		}

	

		// CHECKING:
/*		cerr<<" checking marginal of node: "<<mynode->name()<<endl;
		MDOUBLE SSum =0;
		for (int u=0; u < pi.alphabetSize(); ++u) {
			cerr<<ssc.get(mynode->id(),u)<<" ";
			SSum +=ssc.get(mynode->id(),u);
		}
		cerr<<"\nsum of marginals = "<<SSum<<endl;
*/		
	if (mynode->isRoot()) posProb = sumProb;
	}
}




/*
if (val>1) {
					cerr<<"x val = " << val<<endl;
					cerr<<" my node = " << mynode->name()<<endl;
					cerr<<" let = " << let << endl;
					cerr<<" up = " << cup.get(mynode->id(),let);
					cerr<< "pos prob = " << posProb<<endl;
					cerr<<" root of tree = " << et.iRoot()->name()<<endl;
					errorMsg::reportError(" error in compute marginal >1 ");
				}
if (val>1) {
					cerr<<" val = " << val<<endl;
					cerr<<" pos = " << pos<<endl;
					cerr<<" my node = " << mynode->name()<<endl;
					cerr<<" let = " << let << endl;
					cerr<<" up = " << cup.get(mynode->id(),let)<<endl;
					cerr<<" down[sameLetter] = " << cdown.get(mynode->id(),let)<<endl;
					cerr<<" pij[sameLetter] = " << pi.getPij(mynode->id(),let,let)<<endl;
					cerr<< "pos prob = " << posProb<<endl;
					cerr<<" root of tree = " << et.iRoot()->name()<<endl;
					cerr<<"sp.freq(letter) = "<<sp.freq(let)<<endl;
					errorMsg::reportError(" error in compute marginal >1 ");
				}


  */

