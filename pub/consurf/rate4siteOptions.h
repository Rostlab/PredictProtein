#if !defined ___RATEFPRSITE__OPTION__T__
#define ___RATEFPRSITE__OPTION__T__

#ifndef __STDC__
#define __STDC__ 1
#include "getopt.h"
#undef __STDC__
#else
#include "getopt.h"
#endif

#include <string>
#include <fstream>
using namespace std;

class rate4siteOptions{
public:
	string treefile;
	string seqfile;
	string logFile;
	string referenceSeq; // the results are printed with this seq in each positions.
	int logValue;
	string outFile;
	string outFileNotNormalize;
	string treeOutFile;
	enum SeqFileFormat {mase,clustal,fasta,molphy,phylip};
	SeqFileFormat seqInputFormat;
	
	enum modelNameType {rev,jtt,day,aajc,nucjc,wag,cprev};
	modelNameType modelName;
	
	enum treeSearchAlgType {njJC,njML,MLfromManyNJ,njJCOLD};
	treeSearchAlgType treeSearchAlg;
	
	int alphabet_size;
	enum distributionNameType {hom,gam};// new
	distributionNameType distributionName; // new
//  unsigned long randseed;
  string splitName;
  bool removeGaps;
private:
  ostream* outPtr;
  ofstream out_f;

  //ostream* outPtrNotNormalize;
  //ofstream out_fNotNormalize;


public:
  ostream& out() const {
	  return *outPtr;
  };
  //ostream& outNotNormalize() const {
//	  return *outPtrNotNormalize;
  //};
  explicit rate4siteOptions(int& argc, char *argv[]);
};


#endif
