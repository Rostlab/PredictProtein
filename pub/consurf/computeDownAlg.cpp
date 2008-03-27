#include "computeDownAlg.h"

void computeDownAlg::fillComputeDown(const tree& et,
					   const sequenceContainer& sc,
					   const int pos,
					   const computePijHom& pi,
					   suffStatGlobalHomPos& ssc,
					   const suffStatGlobalHomPos& cup){
	ssc.allocatePlace(et.iNodes(),pi.alphabetSize());
	treeIterTopDownConst tIt(et);
	for (tree::nodeP mynode = tIt.first(); mynode != tIt.end(); mynode = tIt.next()) {
		int letter,letterInFather,bro,letterInSon;
		if (mynode->father()==NULL) {// if root
			for(letter=0; letter<pi.alphabetSize();letter++) {
				ssc.set(mynode->id(),letter,1.0);
			}
			mynode = tIt.next(); //continue
		}
		tree::nodeP fatherNode=mynode->father();
		const int n_bro=fatherNode->sons.size();
		for(letter=0; letter<pi.alphabetSize();letter++) {//alpha
			MDOUBLE totalProb=1.0;
			MDOUBLE fatherTerm=0;
			if (fatherNode->father()!=NULL) {
				for(letterInFather=0; letterInFather<pi.alphabetSize();letterInFather++)
					fatherTerm += pi.getPij(fatherNode->id(),letter,letterInFather)*
					ssc.get(fatherNode->id(),letterInFather);
			}
			else {
				fatherTerm=1.0;
			}
				MDOUBLE brotherTerm=1.0;
			for(bro=0;bro<n_bro;bro++) {
				tree::nodeP brother=fatherNode->sons[bro];
				if (brother != mynode) {
					MDOUBLE tmp_bro=0.0;
					for(letterInSon=0; letterInSon<pi.alphabetSize();letterInSon++) {
						tmp_bro+=pi.getPij(fatherNode->sons[bro]->id(),letter,letterInSon)*
						cup.get(brother->id(),letterInSon);
					}
					brotherTerm *=tmp_bro;
				}
			}
			totalProb = fatherTerm * brotherTerm;
			ssc.set(mynode->id(),letter,totalProb);
		}
	}
}





