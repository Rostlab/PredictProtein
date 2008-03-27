#ifndef __Evaluate_Character_Freq_h
#define __Evaluate_Character_Freq_h

#include <iostream>
using namespace std;

#include "sequenceContainer1G.h"
#include "definitions.h"


vector<MDOUBLE> evaluateCharacterFreq(const sequenceContainer1G & sc);
VVdouble evaluateCharacterFreqOneForEachGene(const vector<sequenceContainer1G> & scVec);
vector<MDOUBLE> evaluateCharacterFreqBasedOnManyGenes(const vector<sequenceContainer1G> & scVec);

#endif
