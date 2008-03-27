#ifndef _Load
#define _Load

#include "TrainSeq.h"
#include <vector>
#include <string>
#include <iostream>

vector<TrainSeq> LoadTrainSeqs(char*);
Seq LoadOneSeq(ifstream&);
Seq LoadOneSeq(ifstream&,set<string>&,map<string,string>&);

#endif
