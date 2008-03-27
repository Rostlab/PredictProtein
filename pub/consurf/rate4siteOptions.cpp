#include "rate4siteOptions.h"
#include "errorMsg.h"
#include <iostream>
using namespace std;

rate4siteOptions::rate4siteOptions(int& argc, char *argv[]):

// DEFAULTS VALUES:
referenceSeq("non"),
treefile(""),
seqfile(""),
logFile(""), //log.txt
logValue(3),
outFile("r4s.res"),
outFileNotNormalize("r4sOrig.res"),
treeOutFile("TheTree.txt"),
seqInputFormat(clustal),
modelName(jtt),
treeSearchAlg(njJC),
alphabet_size(20), // this is 20
distributionName(hom),
removeGaps(false), // default gaps = missing data.
outPtr(&cout) {


	//static struct option long_options[] =  {{0, 0, 0, 0}};
	int option_index = 0;
	int c=0;
	bool algo_set=false;

	out_f.open(outFile.c_str()); // default output file
	outPtr=&out_f; // default output file

	while (c >= 0) {
#ifdef WIN32
		c = getopt_long(argc, argv,"z:Z:x:X:y:Y:A:a:bBm:M:T:t:s:S:O:o:l:L:v:V:Q:q:DJRC:djrc:Hh?",NULL,&option_index);
#else
		c = getopt(argc, argv,"z:Z:x:X:y:Y:A:a:bBm:M:T:t:s:S:O:o:l:L:v:V:Q:q:DJRC:djrc:Hh?");
#endif
		switch (c) {

			// tree file, seqfile and sequence input file format.
			case 'a':case 'A': referenceSeq=optarg; break;
			case 'b':case 'B': removeGaps=true; break;
			case 'h':case 'H': case '?':
				cout <<"USAGE:	"<<argv[0]<<" [-options] "<<endl <<endl;
				cout <<"|/-------------------- +-----------------------+"<<endl;
				cout <<"|-t    tree file       |-Q    input seq format |"<<endl;
				cout <<"|-s    seq file        |-Qc   Clustal          |"<<endl;
				cout <<"|-l    logfile         |-Qf   Fasta            |"<<endl;
				cout <<"|-v    log level       |-Qm   Mase             |"<<endl;
				cout <<"|-o    out file        |-Qmo  Molphy           |"<<endl;
				cout <<"|-x    tree out file   |-Qp   Phylip           |"<<endl;
				cout <<"|-y    outfile for un-normalize rates          |"<<endl;
				cout <<"|----------------------|-----------------------|"<<endl;
				cout <<"|-M     model name                             |"<<endl;
				cout <<"|-Mj    JTT                                    |"<<endl;
				cout <<"|-Mr    REV (for mitochondrial genomes)        |"<<endl;
				cout <<"|-Md    DAY                                    |"<<endl;
				cout <<"|-Mw    WAG                                    |"<<endl;
				cout <<"|-MC    cpREV (for chloroplasts genomes)       |"<<endl;
				cout <<"|-Ma    JC amino acids                         |"<<endl;
				cout <<"|-Mn    JC nucleotides                         |"<<endl;
				cout <<"|-Mn    JC nucleotides                         |"<<endl;
				cout <<"|----------------------------------------------|"<<endl;
				cout <<"|-b remove positions with gaps                 |"<<endl;
				cout <<"|default: gaps are treated as missing data     |"<<endl;
				cout <<"|----------------------------------------------|"<<endl;
				cout <<"|-a		reference sequence                     |"<<endl;
				cout <<"|default: gaps are treated as missing data     |"<<endl;
				cout <<"|----------------------------------------------|"<<endl;
				cout <<"|-h or -? or -H     help                       |"<<endl;
				cout <<"|capital and no captial letters are ok         |"<<endl;
				cout <<"+----------------------+-----------------------+"<<endl;
				cout <<"|-z tree search algorithm:                     |"<<endl;
				cout <<"|-zj = JC,   -zn = NJ with ML distances        |"<<endl;
				cout <<"|-zl = ML tree based on many random NJ trees   |"<<endl;
				cout <<"|-zo = JC & gap-character is as a difference   |"<<endl;
				cout <<"|----------------------------------------------|"<<endl;
				cout<<endl;	cerr<<" please press 0 to exit "; int d; cin>>d;exit (0);
			case 'l':case 'L': logFile=optarg; break;
			case 'm':case 'M':	{
				switch (optarg[0]) {
					case 'd': case 'D':  modelName=day;alphabet_size=20; break;
					case 'j': case 'J':  modelName=jtt;alphabet_size=20; break;
					case 'r': case 'R':  modelName=rev;alphabet_size=20; break;
					case 'w': case 'W':  modelName=wag;alphabet_size=20; break;
					case 'c': case 'C':  modelName=cprev;alphabet_size=20; break;
					case 'a': case 'A':  modelName=aajc;alphabet_size=20; break;
					case 'n': case 'N':  modelName=nucjc;alphabet_size=4; break;
					default:modelName=jtt;alphabet_size=20;
					break;
				}
			} break;
			case 'o':case 'O': {
				out_f.close(); // closing the default
				outFile=optarg;
				out_f.open(outFile.c_str());
				if (out_f == NULL) errorMsg::reportError(" unable to open output file for writing. ");
				outPtr=&out_f;
			}; break;
			case 'q':case 'Q':	{
				switch (optarg[0]) {
					case 'C': case 'c':  seqInputFormat=clustal; break;
					case 'F': case 'f':  seqInputFormat=fasta; break;
					case 'M': case 'm': switch (optarg[1]) {
						case 'o': case 'O': seqInputFormat=molphy; break;
						default: seqInputFormat=mase;	break;
					} break;
					case 'P': case 'p':  seqInputFormat=phylip; break;
					default:seqInputFormat=mase;
					break;
				} // end of switch (optarg[0]) {
				
			}break; // end of case 'Q':
			case 's':case 'S': seqfile=optarg; break;
			case 't':case 'T': treefile=optarg; break;
			case 'v':case 'V': logValue=atoi(optarg); break;
			case 'x':case 'X': treeOutFile=optarg; break;
			case 'y':case 'Y': outFileNotNormalize=optarg; break;
			case 'z':case 'Z': {
				switch (optarg[0]) {
					case 'J': case 'j':  treeSearchAlg=njJC; break;
					case 'n': case 'N':  treeSearchAlg=njML; break;
					case 'L': case 'l':  treeSearchAlg=MLfromManyNJ; break;
					case 'O': case 'o':  treeSearchAlg=njJCOLD; break;
					default:treeSearchAlg=njJC;
					break;
				}
			} break;

		}
	}
}

