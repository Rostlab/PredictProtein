#ifndef _HMMOutput
#define _HMMOutput

#include "Seq.h"
#include "Par.h"

void PrintID(Seq&);
void PrintScore(ostream&,Seq&);
void PrintPaths(ostream&,Seq&);
void PrintLabel(ostream&,Seq&);
void PrintPred(ostream&,Seq&);
void PrintPred2(ostream&,Seq&);
void PrintRdb(ostream&,Seq&,bool);
void PrintPretty(ostream&,Seq&,bool);
void PrintArch(ostream&,Par&);
void PrintTrans(ostream&,Par&);
void DisplayArch(ostream&,Par&,uint,char* ="");
void PrintEmit(ostream&,Par&);
void PrintEmitLogOdds(ostream&,Par&,float);
void PrintEmit(ostream&,Par&,uint,char* ="");

#endif
