#ifdef _HMMEval
#define _HMMEVal

#include "TrainSeq.h"
Stats EvalPred(vector<Seq>&,bool=false);
Stats EvalPred(vector<TrainSeq>&,bool=false);
float Sov1999(Seq&,int,char=0);

#endif
