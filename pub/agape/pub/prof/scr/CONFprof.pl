#------------------------------------------------------------------------------#
#	Copyright				        	1998	       #
#	Burkhard Rost		rost@LION-ag.de,rost@columbia.edu	       #
#	Wilckensstr. 15		http://cubic.bioc.columbia.edu/ 	       #
#	D-69120 Heidelberg						       #
#				version 1.0   	Aug,    	1998	       #
#				version 2.0   	Oct,    	1998	       #
#				version 2.1   	Dec,    	1999	       #
#				version 2.2   	Apr,    	2000	       #
#------------------------------------------------------------------------------#
# 
# purpose: contains all configurations for running PROF
# 
#===============================================================================

sub iniDefProf {
    local($par{"dirHome"},$par{"dirProf"},$par{"confProf"},$ARCH_DEFAULT)=@_;

#-------------------------------------------------------------------------------
#   iniDefProf               sets defaults needed for PROF
#-------------------------------------------------------------------------------

    $[ =1 ;
				# --------------------------------------------------
				# note: already defined in calling program:
				#     $par{"dirHome"}
				#     $par{"dirProf"}
				#     $par{"confProf"}
				#     $ARCH_DEFAULT
				#     
				# --------------------------------------------------
				# keep trace of having called this 
    $par{"DONE","conf"}=        1;

				# ------------------------------
				# directories
    $par{"dirScr"}=             $par{"dirProf"}.  "scr/";      # directory with NN sources (programs)
    $par{"dirBin"}=             $par{"dirProf"}.  "bin/";      # directory for binaries
    $par{"dirMat"}=             $par{"dirProf"}.  "mat/";      # directory for additional material
    $par{"dirNet"}=		                               # directory with network parameters
	$par{"dirPar"}=         $par{"dirProf"}.  "net/";      # dir with junctions

    $par{"dirScrLib"}=          $par{"dirScr"}.   "lib/";     # directory with packages and libs
    $par{"dirEMBL"}=            $par{"dirProf"}.  "embl/";    # directory with EMBL PROF

    $par{"dirOut"}=             "";                          # directory for files output by FORTRAN 
				                             #    (written to dirWork, moved to dirOut!!)
    $par{"dirWork"}=            "";                          # working directory
				# databases to search for files
    $par{"dirData"}=            "data/";    # expects HSSP|Swiss-prot files here
				# input files (either dirIn, or dirHssp)
    $par{"dirHssp"}=            $par{"dirData"}. "hssp/";
    $par{"dirDssp"}=            $par{"dirData"}. "dssp/";
    $par{"dirFssp"}=            $par{"dirData"}. "fssp/";
    $par{"dirSwiss"}=           $par{"dirData"}. "swissprot/current/";
    $par{"dirDataBlastbin"}=    $par{"dirData"}. "blast/";

    
    $par{"dirBlastMat"}=        "/home/rost/data2/blastmatxx/";

				# ------------------------------
				# titles for output files
    $par{"title"}=              "PROF";          # title
				                # output files will be called: 'Pre-title.ext'
				                #    Note: overrides title_net if defined!
    $par{"titleTmp"}=           "PROF"."jobid"; # title for temporary files created on flight    
#    $par{"titleTmp"}=           "PROF";        # title for temporary files created on flight    
				                #    note: for the following 'NN' will be over-written
				                #          by $par{title} (if given on command line)
    $par{"titleIni"}=           "unk";          # temporary title (keyword to change)
                                                #    note: build up automatically

    $par{"titleNetIn"}=         0;              # title of NNIN_in  file (=0 -> auto assign with mode)
    $par{"titleNetOut"}=        0;              # title of NNIN_in  file (=0 -> auto assign with mode)

				# ------------------------------
				# file extensions
    $par{"preOut"}=             "Out-";
    $par{"extOutTmp"}=          ".tmp";

    $par{"extChain"}=           "_";            # to extract chain, out file will contain 'ext_chain'.chain
    $par{"extHssp"}=            ".hssp";
    $par{"extDssp"}=            ".dssp";
    $par{"extMsf"}=             ".msf";
    $par{"extSaf"}=             ".saf";
    $par{"extGcg"}=             ".gcg";
    $par{"extFastamul"}=        ".f";
    $par{"extPirmul"}=          ".pir";
    $par{"extPir"}=             ".pir";
    $par{"extFasta"}=           ".f";
    $par{"extSwiss"}=           "";             # no extension, simply following structure 'id_species'
    $par{"extHsspFil"}=         ".hsspFil";     # extension of filtered HSSP file
    $par{"extHssp4acc"}=        ".hssp4acc";    # extension of filtered HSSP file
    $par{"extHssp4htm"}=        ".hssp4htm";    # extension of filtered HSSP file

    $par{"extBlastMat"}=        ".blastmat";

    $par{"extNetIn"}=           ".dat";         # extension for input to NNfor
    $par{"extNetOut"}=          ".dat";         # extension for output from NNfor
    $par{"extProfPar"}=         ".par";	        # default extension for parameter files
    $par{"extProfJct"}=         ".jct";	        # default extension for network junction files
    $par{"extProfOut"}=         ".prof";        # extension of human readable output file
    $par{"extProfRdb"}=         ".rdbProf";     # extension of RDB output file
    $par{"extProfMsf"}=         ".msfProf";     # extension of prediction in MSF format
    $par{"extProfSaf"}=         ".safProf";     # extension of prediction in SAF format
    $par{"extProfDssp"}=        ".dsspProf";    # extension of prediction in DSSP format
    $par{"extNotHtm"}=          ".notHtm";      # extension of file flagging 'no HTM found'
    $par{"extProfHtml"}=        "_prof.html";   # extension of prediction in HTML format

    $par{"extOutEval"}=         ".acc";         # extension of file with prediction accuracy

				# ------------------------------
				# executables: perl
#    $par{"exeLibProfPack"}=     $par{"dirScrLib"}."prof.pm";      # the REAL stuff for running PROF
    $par{"exeLibProfMain"}=     $par{"dirScrLib"}."lib-prof.pl";   # the REAL stuff for running PROF
    $par{"exeLibProfCol"}=      $par{"dirScrLib"}."lib-col.pl";       # collected perl routines for PROF

    $par{"exeLibProfErr"}=      $par{"dirScrLib"}."lib-proferr.pl";    # perl subs for prediction error
    $par{"exeLibProfWrt"}=      $par{"dirScrLib"}."lib-profwrt.pl";    # perl subs for output writing
    $par{"exeLibProfHtml"}=     $par{"dirScrLib"}."lib-profhtml.pl";   # perl subs for output writing

    $par{"exeHtmfil"}=          $par{"dirScr"}. "tlprof_htmfil.pl";    # filter PROFhtm prediction
    $par{"exeHtmref"}=          $par{"dirScr"}. "tlprof_htmref.pl";    # refine PROFhtm prediction
    $par{"exeHtmtop"}=          $par{"dirScr"}. "tlprof_htmtop.pl";    # predict topology for PROFhtm

    $par{"exeCopf"}=            $par{"dirScr"}. "copf.pl";             # script converting formats
    $par{"exeCopfPack"}=        $par{"dirScr"}. "pack/copf.pm";	
    $par{"exeConvHssp2saf"}=    $par{"dirEMBL"}."scr/conv_hssp2saf.pl"; # only for PHD
    $par{"exeFilterHssp"}=      $par{"dirScr"}. "hssp_filter.pl";      # script filtering HSSP files
    $par{"exeFilterHsspPack"}=  $par{"dirScr"}. "pack/hssp_filter.pm"; # script filtering HSSP files

    $par{"exePhd1994"}=         $par{"dirEMBL"}."phd.pl";             # old PHD
				# ------------------------------
				# executables: binary
    $par{"exeConvertSeqFor"}=   $par{"dirBin"}. "convert_seq". ".ARCH";    # binary for format conversion
    $par{"exeFilterHsspFor"}=   $par{"dirBin"}. "filter_hssp". ".ARCH";    # binary for HSSP filtering
    $par{"exeProfFor"}=         $par{"dirBin"}. "prof".        ".ARCH";    # binary for neural network
    $par{"exePhd1994For"}=      $par{"dirBin"}. "phd1994".     ".ARCH";    # binary for neural network
#    $par{"exePhd1994For"}=      $par{"dirBin"}. "phd1994tiny". ".ARCH";    # binary for neural network
    $par{"exePhd1994For"}=      $par{"dirBin"}. "phd1994". ".ARCH";         # binary for neural network

				# ------------------------------
				# executables: other
    $par{"exePvmgetarch"}=      $par{"dirScr"}. "pvmgetarch.sh";           # shell program to get ARCH
    $par{"exeSysNice"}=         "/bin/nice";
    $par{"exeSysNice","MAC"}=   "/usr/sbin/nice";

				# ------------------------------
				# files
				# ------------------------------
				# headers (accuracy tables)
    $par{"headProf3"}=          $par{"dirMat"}. "headProf3.txt";
    $par{"headProfBoth"}=       $par{"dirMat"}. "headProfBoth.txt";
    $par{"headProfConcise"}=    $par{"dirMat"}. "headProfConcise.txt";
    $par{"headProfAcc"}=        $par{"dirMat"}. "headProfAcc.txt";
    $par{"headProfHtm"}=        $par{"dirMat"}. "headProfHtm.txt";
    $par{"headProfSec"}=        $par{"dirMat"}. "headProfSec.txt";

				# abbreviations
    $par{"abbrProf3"}=          $par{"dirMat"}. "abbrProf3.txt";
    $par{"abbrProfBoth"}=       $par{"dirMat"}. "abbrProfBoth.txt";
    $par{"abbrProfAcc"}=        $par{"dirMat"}. "abbrProfAcc.txt";
    $par{"abbrProfHtm"}=        $par{"dirMat"}. "abbrProfHtm.txt";
    $par{"abbrProfSec"}=        $par{"dirMat"}. "abbrProfSec.txt";
    $par{"abbrProfRdb"}=        $par{"dirMat"}. "abbrProfRdb3.txt";
				# help files
    $par{"fileHelpOpt"}=        $par{"dirMat"}. "help-options.txt";
    $par{"fileHelpMan"}=        $par{"dirMat"}. "help-manual.txt";
    $par{"fileHelpHints"}=      "unk";          # file with hints, note: also passed as par{scrHelpHints}
    $par{"fileHelpProblems"}=   "unk";          # file with known problems, also passed as par{scrHelpProblems}

				# prof parameters (giving architecture names)
				# from 2000-08
#    $par{"paraBoth"}=           $par{"dirPar"}. "PROFboth.par";   # parameter file for sec+acc
#    $par{"para3"}=              $par{"dirPar"}. "PROF.par";       # parameter file for sec+acc+htm
#    $par{"para3"}=              $par{"dirPar"}. "PROFboth.par";   # parameter file for sec+acc+htm
				# from 2000-12
    $par{"para3"}=              $par{"dirPar"}. "PROF.par";          # parameter file for sec+acc+htm
    $par{"para3"}=              $par{"dirPar"}. "PROFboth_best.par"; # parameter file for sec+acc+htm
    $par{"paraBoth"}=           $par{"dirPar"}. "PROFboth_best.par";

				# yyy to do!!
#    $par{"paraCap"}=            $par{"dirPar"}. "PROFcap.par";
#    $par{"paraCapH"}=           $par{"dirPar"}. "PROFcapH.par";
#    $par{"paraCapE"}=           $par{"dirPar"}. "PROFcapE.par";

				# default parameters (usually overwritten by $par{"optProfQuality"}
				# from 2000-08
#    $par{"paraAcc"}=            $par{"dirPar"}. "PROFacc_1st.par";    # parameter file for acc
#    $par{"paraSec"}=            $par{"dirPar"}. "PROFsec_2nd.par";    # parameter file for sec

				# from 2000-12
    $par{"paraAcc"}=            $par{"dirPar"}. "PROFacc_best.par" ;
    $par{"paraSec"}=            $par{"dirPar"}. "PROFsec_best.par" ;
    $par{"paraHtm"}=            $par{"dirPar"}. "unk";            # parameter file for htm

				# 
    $par{"para3Tst"}=           $par{"dirPar"}. "PROFboth_tst.par";
    $par{"paraBothTst"}=        $par{"dirPar"}. "PROFboth_tst.par";
    $par{"paraAccTst"}=         $par{"dirPar"}. "PROFacc_tst.jct" ;
    $par{"paraSecTst"}=         $par{"dirPar"}. "PROFsec_tst.jct" ;

    $par{"para3"."runfast"}=    $par{"dirPar"}. "PROFboth_fast.par";
    $par{"paraBoth"."runfast"}= $par{"dirPar"}. "PROFboth_fast.par";
    $par{"paraAcc"."runfast"}=  $par{"dirPar"}. "PROFacc_fast.par" ;
    $par{"paraSec"."runfast"}=  $par{"dirPar"}. "PROFsec_fast.par" ;

    $par{"para3"."rungood"}=    $par{"dirPar"}. "PROFboth_good.par";
    $par{"paraBoth"."rungood"}= $par{"dirPar"}. "PROFboth_good.par";
    $par{"paraAcc"."rungood"}=  $par{"dirPar"}. "PROFacc_good.par" ;
    $par{"paraSec"."rungood"}=  $par{"dirPar"}. "PROFsec_good.par" ;

    $par{"para3"."runbest"}=    $par{"dirPar"}. "PROFboth_best.par";
    $par{"paraBoth"."runbest"}= $par{"dirPar"}. "PROFboth_best.par";
    $par{"paraAcc"."runbest"}=  $par{"dirPar"}. "PROFacc_best.par" ;
    $par{"paraSec"."runbest"}=  $par{"dirPar"}. "PROFsec_best.par" ;

				# LOG files
    $par{"fileOutTrace"}=       $par{"titleTmp"}."trace". ".tmp"; # file tracing some warnings and errors
    $par{"fileOutScreen"}=      $par{"titleTmp"}."screen".".tmp"; # file for running system commands via: 
				                             #    'sysRunProg'
				# temporary file to write ptrGlob to reduce memory!
				# - set = 0 to avoit dumping the pointers!
				#    note: set to 0 if input is NNIN.final, i.e. final network input
    $par{"fileOutError"}=       "PROFerrors.tmp";            # file for error history written by nn.pl
    $par{"fileOutWarn"}=        "PROFwarnings.tmp";          # file with additional warnings
				                             #    only used by conv_prof2dssp at moment

    $par{"fileOutErrorChain"}=  $par{"titleTmp"}."errorChain".".tmp";     # errors with chains
    $par{"fileOutErrorConv"}=   $par{"titleTmp"}."errorConv".".list";     # list of input files that were not 
				                                          #    converted, correctly


    $par{"fileOutError"}=       "PROF_ERRORconv.tmp";
    $par{"fileOutErrorBlast"}=  "PROF_ERRORblast.tmp";
    $par{"fileOutTmp"}=         "PROF_".$$.".tmp"; # temporary file used by various parts
    $par{"fileOutSeqTmp"}=      "direct.f";        # temporary file used to write sequence

    $par{"aliMinLen"}=         20;              # minimal number of aligned residues to report
				                #    alignment
				                #    NOTE: only for prof2 html|ascii with mode ali!

                                # ------------------------------
                                # job control
    $USERID=                    0;

    $par{"jobid"}=              "jobid";        # unique job identifier (set to $$ if not defined)
    $par{"debug"}=              0;              # if 1: keep (most) temporary files
    $par{"debugali"}=           0;              # if 1: debug flag for alignment part on
    $par{"debugfor"}=           0;              # if 1: debug flag for PROF fortran part on
    $par{"verbose"}=$Lverb=     1;              # blabla on screen
    $par{"verb2"}=$Lverb2=      0;              # more verbose blabla
    $par{"verb3"}=$Lverb3=      0;              # more verbose blabla
    $par{"verbAli"}=            0;              # more verbose for alignment conversion
    $par{"verbForVec"}=         0;              # write input to FORTRAN to $FHTRACE (vectors)
    $par{"verbForProt"}=        0;              # write input to FORTRAN to $FHTRACE (protein data)
    $par{"verbForSam"}=         0;              # write input to FORTRAN to $FHTRACE (samples)
    $par{"verbForErr"}=         1;              # write output from FORTRAN to STDOUT (error)

    $par{"optNice"}=            "nonice";       # priority 'nonice|nice|nice-19' -> default (nice 15)
    $par{"optNice"}=            "nice";	        # priority 'nonice|nice|nice-19' -> default (nice 15)
    $par{"optNiceDef"}=         "nice-15";      # default priority (if optNice='nice'
#    $par{"optNiceDef"}=         " ";            # default priority (if optNice='nice'

				# ------------------------------
				# parameters: convert from db

				# BLAST stuff
    $par{"modeAli"}=            "hssp";	        # if "hssp" assume HSSP profiles
				                # if "psi|blast" assume PSI-BLAST profiles

#    $par{"modeAli"}=            "psi";	        # if "hssp" assume HSSP profiles
				                # if "psi|blast" assume PSI-BLAST profiles


    $par{"blastConvTemperature"}=0.42;          # temperature factor to convert PSI-blast prof
				                #    to profiles for network (0-1)
    $par{"blastConvTemperature"}=0.84;          # temperature factor to convert PSI-blast prof
				                #    to profiles for network (0-1)
    $par{"blastConvTemperature"}=0.69;          # temperature factor to convert PSI-blast prof
				                #    to profiles for network (0-1)
				                #    




    $par{"doFilter"}=           0;              # if 1: filter_hssp is run (all input formats converted
				                #        to HSSP first)
    $par{"doFilterAcc"}=        1;              # if 1: filter_hssp is run for ACC

#xx temporary switches off the acc filter!!!
    $par{"doFilterAcc"}=        0;              # if 1: filter_hssp is run for ACC
#xx temporary switches off the acc filter!!!

    $par{"optFilter"}=          "red=80";       # option for filtering input file 
                                                #       (see hssp_filter.pl for details)
    $par{"optFilterAcc"}=       "red=80  thresh=2 mode=ide";       # option for filtering input file 
#    $par{"optFilterAcc"}=       "";       # option for filtering input file 
                                                #       for PROFacc


    $par{"doKeepHssp"}=         1;              # if 1: the intermediate HSSP file is stored
    $par{"doKeepFilter"}=       1;              # if 1: the intermediate filtered HSSP file is stored
    $par{"doKeepNetDb"}=        1;              # if 1: the intermediate nnDb file is stored

    $par{"doKeepHssp"}=         0;              # if 1: the intermediate HSSP file is stored
    $par{"doKeepFilter"}=       0;              # if 1: the intermediate filtered HSSP file is stored

    $par{"modeObs"}=            0;              # if 0: assumed a 'real' prediction in absence of structural knowledge
    $par{"modeObs"}=            1;              # if 1: assumed that feature to be predicted is known
    $par{"modeSec"}=            "HELT";         # mode of converting DSSP -> N-states ('HL', 'HEL', 'HELT')
    $par{"modeSec"}=            "HEL";          # mode of converting DSSP -> N-states ('HL', 'HEL', 'HELT')

    $par{"modeSec6"}=           "HELBGT";       # mode of converting DSSP -> N-states ('HL', 'HEL', 'HELT')
    $par{"fileMatGcg"}=         $par{"dirMat"}. "Maxhom_GCG.metric";        # MAXHOM-GCG matrix
    $par{"fileMatMcLachlan"}=   $par{"dirMat"}. "Maxhom_McLachlan.metric";  # MAXHOM-McLachlan matrix
    $par{"fileMatBlosum62"}=    $par{"dirMat"}. "Maxhom_Blosum.metric";     # MAXHOM-Blosum matrix
    $par{"fileMatHsspFilter"}=  $par{"dirMat"}. "Maxhom_GCG.metric";        # matrix used to filter HSSP

    $par{"fileMatBlosum62psi"}= $par{"dirMat"}. "Blast_blosum62.metric";    # matrix used to set PSI-blast when no ali

    $par{"convPfar"}=          20;              # distance from HSSP-threshold to be considered:
				                #    'far' varied (and counted in *.rdb_nn header 'nfar')
				                # empty length to leave out!
    $par{"convOtherDistance"}=  "50,40,30,5";

    $par{"isList"}=             0;              # input is list of nndb files (not necessary to set)

				# ------------------------------
				# parameters for running PROF
    $par{"optProf"}=            "3";      # exp, sec, htm, exp+sec, 3
    $par{"optProfQuality"}=     "tst";    # will run test mode: fast
    $par{"optProfQuality"}=     "fast";   # will run fast prediction
    $par{"optProfQuality"}=     "good";   # will run good prediction, slower
    $par{"optProfQuality"}=     "best";   # will run best prediction, slowest

    $par{"optDoHtmfil"}=        0;        # filter the prediction?
    $par{"optDoHtmisit"}=       1;        # check the exclusion stuff by htmisit (if best helix
			                  # of more than 18 residues score < n => not membrane)
    $par{"optDoHtmref"}=        1;        # refine the PROFhtm prediction?
    $par{"optDoHtmtop"}=        1;        # predict topology for transmembrane proteins?

#    $par{"optHtmisitMin"}=      0.7;     # qualify as notHTM if best helix score < min_val
    $par{"optHtmisitMin"}=      0.8;      # qualify as notHTM if best helix score < min_val

				# ------------------------------
				# parameters: run net
    $par{"numresMin"}=          9;        # minimal number of residues to run network 
				          #    otherwise prd=symbolPrdShort
    $par{"symbolPrdShort"}=     "*";      # default prediction for too short sequences
				          #    NOTE: also taken if stretch between two chains too short!
    $par{"symbolChainAny"}=     "*";      # chain name if chain NOT specified!

    $par{"netlevelMax"}=        2;        # maximal number of network levels (1:seq-2-str,2:str-2-str,3:new)
    $par{"numwinMax"}=         13;        # maximal window length (used to compile spacers)
    $par{"windowUsed"}=         "13,17,21,25"; # some window lengths used (to speed up nnWrt)
    $par{"symbolResidueUnk"}=   "X";      # symbol used for unknown residue
#    $par{"modesGlobalHydro"}=   "eisen,ooi";

				# ------------------------------
				# parameters: run FORTRAN
    $par{"modeRunNet"}=         "tvt";    # mode to run nn.pl, possible 'trn|val|tst|tvt|conv'
    $par{"doCorSparse"}=        0;        # correct sparse profiles (e.g. single sequences -> read metric)
    $par{"modeFileIn"}=         0;        # describes mode of input files: 'nnin|nndb|db', will be assigned
                                          #    automatically by ini

				# ------------------------------
				# parameters for PROF output
    $par{"doSkipExisting"}=     0;        # generate new PROF files even if old ones exist
				          #    if = 0, PROF is not run if old result files exist
				          #    note: this option is for running PROF on a list of files
    $par{"doSkipMissing"}=      0;        # if = 1: missing input files will NOT force abort

    $par{"doEval"}=             0;        # include the analysis of accuracy if DSSP is known

    $par{"doRetAscii"}=         0;        # return human readable output formatted prediction
    $par{"doRetHtml"}=          0;        # return HTML formatted prediction
    $par{"doRetDssp"}=          0;        # return DSSP formatted prediction
    $par{"doRetMsf"}=           0;        # return MSF|SAF formatted prediction
    $par{"doRetSaf"}=           0;        # return MSF|SAF formatted prediction
    $par{"doRetCasp"}=          0;        # return CASP formatted prediction
    $par{"doRetRdb"}=           1;        # return RDB file (default output, note: if you set this
				          #    to 0 without changing any other option, you may never
				          #    see an output file, at all ...
    $par{"doRetPhd1994"}=       0;        # run old PHD

    $par{"riSubSec"}=           5;        # minimal RI for subset PROFsec
    $par{"riSubAcc"}=           4;        # minimal RI for subset PROFacc
    $par{"riSubHtm"}=           7;        # minimal RI for subset PROFhtm
    $par{"riSubSym"}=           ".";      # symbol for residues predicted with RI<SubSec/Acc
    $par{"riCapFlip"}=          6;        # if RI < this: the final report will flip 'cap' -> non-cap!
#    $par{"riCapFlip"}=          3;        # if RI < this: the final report will flip 'cap' -> non-cap!

    $par{"riAddNophd"}=         0;        # temporary hack: adds a reliability index for 'no jury'

    $par{"nresPerRow"}=        80;        # number of residues per line in human readable files
				          # written for each protein
    $par{"nresPerRowAli"}=     50;        # number of residues per line in MSF output
    $par{"nresPerRowHtml"}=     0;        # number of residues per line in HTML 
				          #    =0 -> endless line

    $par{"optOutNotation"}=     1;        # explain notation
    $par{"optOutAverages"}=     1;        # include information about AA composition and SS composition
    $par{"optOutHeader"}=       1;        # write information iin RDB header?
    $par{"optOutHeaderSum"}=    1;        # write statistics about protein for ASCII?
    $par{"optOutHeaderInfo"}=   1;        # write particular info about protein for ASCII?
    $par{"optOutBrief"}=        0;        # also give short version of prediction
    $par{"optOutNormal"}=       1;        # the typical OLD PROF output
    $par{"optOutSubset"}=       1;        # write line with subset ?
    $par{"optOutDetail"}=       1;        # write line with detail ?
    $par{"optOutGraph"}=        1;        # include ASCII graphics
    $par{"optOutAli"}=          1;        # include alignment in ASCII graphics
#    $par{"optOutAli"}=          0; # xx include alignment in ASCII graphics
    $par{"optOutBrief"}=        1; # xx also give short version of prediction

    $par{"optOutTxtPreRow"}=    "";       # each row will begin with '$pre'
    

    $par{"doRetHeader"}=        1;        # return text describing PROF accuracy
    $par{"doRetAliExpand"}=     0;        # expand MSF returned
#    $par{"formatRetAli"}=       "msf";    # format of the file of PROF + ali
    $par{"formatRetAli"}=       "saf";    # format of the file of PROF + ali
    $par{"nresPerLineAli"}=    50;        # number of characters used for MSF file
    $par{"optProf2msf"}=         0;        # =0|1|expand => expand insertions when HSSP -> MSF
    $par{"optHssp2msf"}=        0;        # =0|1, or e.g 'ARCH=SGI64 exe=convert_seq.SGI5 expand'
				          # add "expand " to expand insertions when HSSP -> MSF
    $par{"optModeRetHtmlDef"}=     
                     "html:all,data:all"; # controls the parts of the HTML file written
				          #    options:
				          #    html:<all|body|head>,data:<all|brief|normal|detail>
    $par{"optModeRetHtml"}=     0;
				          #      


    $par{"optAcc10Filter"}=     1;        # filter acc in 10 states: neighbour averages, BUT: keep 10 state!
#    $par{"optAcc10Filter1"}=    0;        # filter acc in 10 states: neighbour averages
    $par{"optAcc10Filter2"}=    0;        # filter acc in 10 states: cluster for 2,3 states
    $par{"optSecFilterH"}=      4;        # filter sec helix LHHL->LLLL|LHHH depending on reliabiity
				          #    NOTE: the actual value is the threshold for the
				          #          filter reliability (helix with > this taken)
    $par{"optSecFilterE"}=      2;        # filter sec strand LEL->LLL depending on reliabiity
				          #    NOTE: the actual value is the threshold for the
				          #          filter reliability (strand with > this taken)

    $par{"optJury"}=            "normal";
#    $par{"optJury"}=            "sigma,min2=3,min1=5";
#    $par{"optJury"}=            "best=5";
#    $par{"optJury"}=            "weight"; # compiles a weighted average over jurys
    $par{"optJury"}=            "normal,usePHD";
    

    $par{"rdbSep"}=             "\t";     # separator for columns of RDB file
    $par{"rdbHyphen"}=          80;       # hyphens separating NOTATIONS in RDB header
    $par{"rdbWhite"}=           10;       # white spaces used in header
    $par{"rdbHdrSimple"}=        0;       # if 1: the RDB file header will NOT have notations

				# ------------------------------
				# evaluation of accuracy
    $par{"errPrd_doq10"}=        1;
    $par{"errPrd_title"}=       "";       # to be used in output file (added to column names)
    $par{"errPrd_dori"}=         1;       # read and compile reliability index
    $par{"errPrd_doq2"}=         1;       # read and compile two state accuracy
    $par{"errPrd_doq3"}=         1;       # read and compile three state accuracy
    $par{"errPrd_doq10"}=        1;       # read and compile ten state accuracy
    $par{"errPrd_docorr"}=       1;       # read and compile correlation
    $par{"errPrd_dodetail"}=     1;       # compile e.g. Q2b%obs,Q2e%obs,Q2e%prd,Q2e%prd
    $par{"errPrd_domatthews"}=   1;       # compile Matthews correlation coefficient:
				          #    B W Matthews (1975) Biochim. Biophys. Acta 405, 442-451
				          #                 p(i)*n(i) - u(i)*o(i)
				          #    c(i) = ----------------------------------
				          #           sqrt{ (p(i)+u(i))*(p(i)+o(i))*(n(i)+u(i))*(n(i)+o(i)) }
				          #    
    $par{"errPrd_doinfo"}=       1;       # compile Rost information index:
		      		          #    B Rost & C Sander (1993) JMB, 232, 584-599
		      		          #    
		      		          #            SUM/i,1-3[PRDi*ln(PRDi)] - SUM/ij [Aij * ln Aij]
		      		          #    I = 1 - ------------------------------------------------
		      		          #                NRES*ln(NRES) - SUM/i [OBSi*ln(OBSi)
		      		          #    
		      		          #    with 
		      		          #    
		      		          #    PRDi = number of residues predicted in state i
		      		          #    OBSi = number of residues observed in state i
		      		          #    NRES = number of residues (protein length)
		      		          #    
		      		          #    note: I%obs and I%prd (PRD <-> OBS for the later)
		      		          #    
    $par{"errPrd_domatrix"}=     1;       # compile entire matrix of numbers: Aij=
		      		          #    Aij = residues observed in state i and predicted in j
		      		          #    note: sums for vector stored in Akj (k=4), and Ail (l=4)
		      		          #    
    $par{"errPrd_dosov"}=        0;       # compile segment score SOV 


				# ------------------------------
				# wrong HSSP FORMAT
    $par{"Lhssp_error_ndel_nins"}=1;
				# ------------------------------
				# parameters: compile error
				          #    
    $par{"acc2Thresh"}=         16;       # threshold for 2-state description of solvent accessibility, i.e.
				          #    acc <= acc2Thresh -> buried, acc > acc2Thresh -> exposed
				          #    note: with b <= 16, and e > 16  %b=53, %e=47
    $par{"thresh2acc"}=$par{"acc2Thresh"};
				          #    
				          #    
    $par{"acc2Symbol"}=         "b,e";    # symbols for buried and exposed state

				          #    
    $par{"acc3Thresh"}=         "9,36";   # threshold for 3-state description of solvent accessibility, i.e.
				          #    acc <= acc3Thresh -> buried, acc > acc3Thresh2 -> exposed 
				          #    note: with b <= 16, and e > 16  %b=53, %e=47
				          #    
    $par{"acc3Symbol"}=         "b,i,e";  # symbols for buried, intermediate, exposed
				          #    
    $par{"accBuriedSat"}=       0.85;     # for prediction of acc in 2- and 3-states:
				          #    low acc values set to 0:
				          #    Diff = 2*(outValWin-0.5)
				          #    acc= 16 (1 - Diff ) -> 0 if diff < accBuriedSat 
				          #    
    $par{"secCapNon1"}=         0.3;      # val for unit of non-struc bef|after cap: ->LHH  HHL<-
    $par{"secCapSeg1"}=         0.5;      # val for unit in structure after|bef cap:  LHH<-  ->HHL
    $par{"secCapSeg2"}=         0.3;      # val for unit in structure two after|bef: LHHH<-  ->HHHL
    $par{"secCapSym"}=          "P";      # symbol for caps
    $par{"secCapSym"."Hcap"}=   "h";      # symbol for Hcaps
    $par{"secCapSym"."Ecap"}=   "e";      # symbol for Ecaps
    $par{"secCapSym"."HEcap"}=  "p";      # symbol for HEcaps
    $par{"secCapSymNon"}=       "n";      # symbol for non-caps

				# ------------------------------
				# parameters for output text
    $par{"txt","copyright"}=    "Burkhard Rost, CUBIC NYC / LION Heidelberg";
    $par{"txt","contactEmail"}= "rost\@columbia.edu";
    $par{"txt","contactFax"}=   "+1-212-305 3773";
    $par{"txt","contactWeb"}=   "http://cubic.bioc.columbia.edu";
    $par{"txt","version"}=      "2000.02";
#    $par{"txt"}=       "";
    $par{"url","pp"}=           "http://cubic.bioc.columbia.edu/predictprotein/";

    $par{"srsPath"}=            "http://srs6.ebi.ac.uk/srs6bin/cgi-bin/wgetz?-e+";

    
    $par{"txt","modepred","sec"}=  "prediction of secondary structure";
    $par{"txt","modepred","cap"}=  "prediction of secondary structure caps";
    $par{"txt","modepred","acc"}=  "prediction of solvent accessibility";
    $par{"txt","modepred","htm"}=  "prediction of transmembrane helices";
    $par{"txt","modepred","loc"}=  "prediction of sub-cellular location";

    $par{"txt","quote","phd1994"}= "B Rost (1996) Methods in Enzymology, 266:525-539";
    $par{"txt","quote","prof"}=    "B Rost & C Sander (1993) J Mol Biol, 232:584-599";
    $par{"txt","quote","profsec"}= "B Rost & C Sander (1993) J Mol Biol, 232:584-599";
    $par{"txt","quote","profacc"}= "B Rost & C Sander (1994) Proteins, 20:216-226";
    $par{"txt","quote","profhtm"}= "B Rost, P Fariselli & R Casadio (1996) Prot Science, 7:1704-1718";
    $par{"txt","quote","globe"}=   "B Rost (1998) unpublished";
    $par{"txt","quote","topits"}=  "B Rost, R Schneider & C Sander (1997) J Mol Biol, 270:1-10";
    $par{"txt","quote","evalacc"}= "B Rost & C Sander (1994) Proteins, 20:216-226";
    $par{"txt","quote","evalsec"}= "B Rost & C Sander (1993) J Mol Biol, 232:584-599";
    $par{"txt","quote","evalsov"}= "A Zemla, C Venclovas, K Fidelis and B Rost (1999) Proteins, 34:220-223";
                                          


    $par{"notation","prot_id"}=    "identifier of protein [w]";
    $par{"notation","prot_name"}=  "name of protein [w]";
    $par{"notation","prot_nres"}=  "number of residues [d]";
    $par{"notation","prot_nali"}=  "number of proteins aligned in family [d]";
    $par{"notation","prot_nchn"}=  "number of chains (if PDB protein) [d]";
    $par{"notation","prot_kchn"}=  "PDB chains used [0-9A-Z!s]";
    $par{"notation","prot_nfar"}=  "number of distant relatives [d]";
    $par{"notation","prot_cut"}=   "flag indicating that insertions have been removed from your protein [w]";

    $par{"notation","ali_orig"}=   "input file";
    $par{"notation","ali_used"}=   "input file used";
    $par{"notation","ali_para"}=   "parameters used to filter input file";
    $par{"notation","ali_pide"}=   "percentage of identical residues";
    $par{"notation","ali_lali"}=   "number of aligned residues";

    $par{"notation","prof_fpar"}=   "name of parameter file, used [w]";
    $par{"notation","prof_nnet"}=   "number of networks used for prediction [d]";
    $par{"notation","prof_fnet"}=   "name of network architectures, used [w]";
    $par{"notation","prof_mode"}=   "mode of prediction [w]";
    $par{"notation","prof_version"}="version of PROF";

    $par{"notation","prof_skip"}=   "note: sequence stretches with less than ".$par{"numresMin"}.
	                           " are not predicted, the symbol '".$par{"symbolPrdShort"}.
				       "' is used!";

				# protein
    $par{"notation","No"}=         "counting residues [d]";
    $par{"notation","AA"}=         "amino acid one letter code [A-Z!a-z]";
    $par{"notation","CHN"}=        "protein chain [A-Z!a-z]";

				# secondary structure
    $par{"notation","OHEL"}=       "observed secondary structure: H=helix, E=extended (sheet), blank=other (loop)";
    $par{"notation","PHEL"}=       "PROF predicted secondary structure: ".
	                           "H=helix, E=extended (sheet), blank=other (loop)".
				       "\n"."PROF = PROF: Profile network prediction HeiDelberg";
    $par{"notation","RI_S"}=       "reliability index for PROFsec prediction (0=lo 9=high)".
	                           "\n"."Note: for the brief presentation strong predictions ".
				   "marked by '*'";

    $par{"notation","SUBsec"}=     "subset of the PROFsec prediction, for all residues with an ".
	                           "expected average accuracy > 82% (tables in header)\n".
				   "     NOTE: for this subset the following symbols are used:\n".
				   "  L: is loop (for which above ' ' is used)\n".
				   "  ".$par{"riSubSym"}.": means that no prediction is made \n".
				   "for this residue, as the reliability is:  Rel < ".$par{"riSubSec"};
    $par{"notation","pH"}=         "'probability' for assigning helix (1=high, 0=low)";
    $par{"notation","pE"}=         "'probability' for assigning strand (1=high, 0=low)";
    $par{"notation","pL"}=         "'probability' for assigning neither helix, nor strand (1=high, 0=low)";

    $par{"notation","OtH"}=        "actual neural network output from PROFsec for helix unit";
    $par{"notation","OtE"}=        "actual neural network output from PROFsec for strand unit";
    $par{"notation","OtL"}=        "actual neural network output from PROFsec for 'no-regular' unit";

				# solvent accessibility
    $par{"notation","OACC"}=       "observed solvent accessibility (acc) in square Angstroem (taken from DSSP: W Kabsch and C Sander, Biopolymers, 22, 2577-2637, 1983)";
    $par{"notation","PACC"}=       "PROF predicted solvent accessibility (acc) in square Angstroem";
    $par{"notation","OREL"}=       "observed relative solvent accessibility (acc) in 10 states: ".
	"a value of n (=0-9) corresponds to a relative acc. of between n*n % and (n+1)*(n+1) % ".
	    "(e.g. for n=5: 16-25%).";
    $par{"notation","PREL"}=       "PROF predicted relative solvent accessibility (acc) in 10 states: ".
	"a value of n (=0-9) corresponds to a relative acc. of between n*n % and (n+1)*(n+1) % ".
	    "(e.g. for n=5: 16-25%).";
    $par{"notation","Obe"}=        "observerd relative solvent accessibility (acc) in 2 states: ".
	"b = 0-".$par{"acc2Thresh"}."%, e = ".$par{"acc2Thresh"}."-100%.";
    $par{"notation","Obie"}=       "observerd relative solvent accessibility (acc) in 3 states: ".
	"b = 0-9%, i = 9-36%, e = 36-100%.";
    $par{"notation","Pbe"}=        "PROF predicted  relative solvent accessibility (acc) in 2 states: ".
	"b = 0-".$par{"acc2Thresh"}."%, e = ".$par{"acc2Thresh"}."-100%.";
    $par{"notation","Pbie"}=       "PROF predicted relative solvent accessibility (acc) in 3 states: ".
	"b = 0-9%, i = 9-36%, e = 36-100%.";
    $par{"notation","RI_A"}=       "reliability index for PROFacc prediction (0=low to 9=high)".
	"\n"."Note: for the brief presentation strong predictions marked by '*'";
    $par{"notation","SUBacc"}=     "subset of the PROFacc prediction, for all residues with an".
	" expected average correlation > 0.69 (tables in header)\n".
	    "     NOTE: for this subset the following symbols are used:\n".
		"  I: is intermediate (for which above ' ' is used)\n".
		    "  ".$par{"riSubSym"}.": means that no prediction is made for this ".
			"residue, as the reliability is:  Rel < ".$par{"riSubAcc"}."\n";
    $par{"notation","Ot4"}=        "actual neural network output from PROFsec for unit 0 coding for a relative solvent accessibility of 4*4 - 5*5 percent (16-25%). Note: OtN, with N=0-9 give the same information for the other output units!";


				# membrane helices
    $par{"notation","OMN"}=        "observed membrane helix: M=helical transmembrane region, ".
	"blank=non-membrane";
    $par{"notation","OMN"}=        "observed membrane helix: M=helical transmembrane region, ".
	"blank=non-membrane";
    $par{"notation","PMN"}=        "PROF predicted membrane helix: M=helical transmembrane region, ".
	"blank=non-membrane".
	    "\n"."PROF = PROF: Profile network prediction HeiDelberg";
    $par{"notation","PRMN"}=       "refined PROF prediction: M=helical transmembrane region, ".
	"blank=non-membrane";
    $par{"notation","PiTo"}=       "PROF prediction of membrane topology: T=helical transmem".
	"brane region, i=inside of membrane, o=outside of membrane";
    $par{"notation","RI_M"}=       "reliability index for PROFhtm prediction (0=low to 9=high)".
	"\n"."Note: for the brief presentation strong predictions marked by '*'";
    $par{"notation","SUBhtm"}=     "subset of the PROFhtm prediction, for all residues with an ".
	"expected average accuracy > 98% (tables in header)\n".
	    "     NOTE: for this subset the following symbols are used:\n".
		"  N: is non-membrane region (for which above ' ' is used)\n".
		    "  ".$par{"riSubSym"}.": means that no prediction is made for this ".
			"residue, as the reliability is:  Rel < ".$par{"riSubHtm"}."\n";
    $par{"notation","pM"}=         "'probability' for assigning transmembrane helix";
    $par{"notation","pN"}=         "'probability' for assigning globular region";


    $par{"notation",""}= "";


    $par{"map","HELBGT"}="HEL";	# describes mapping of NN output in mode HELBGT to
				#       final RDB in HEL
    $par{"maptrans","HELBGT"}="HGTEBL";
				# translation of mode, i.e. output unit 1=H, 2=G, 3=T ..

    $par{"map","HELBGT",1}=1;	# H -> H
    $par{"map","HELBGT",2}=1;	# G -> H
    $par{"map","HELBGT",3}=3;	# T -> L
    $par{"map","HELBGT",4}=2;	# E -> E
    $par{"map","HELBGT",5}=2;	# B -> E
    $par{"map","HELBGT",6}=3;	# L -> L

				# ------------------------------
				# fields for output
				# note: &interpretObs recognises '^O' 
				#           as keywords for observed stuff
				# NOTE: all others (such as 'pH', 'OtH' done on flight)
				#       by &interpretMode()
    %kwdGlob=
	(
	 'head'  => [
				# protein info
		     "prot_id","prot_name",
		     "prot_nres","prot_nali","prot_nchn","prot_kchn","prot_nfar",
				# alignment info
		     "ali_orig","ali_used","ali_para",
				# prof stuff
		     "prof_fpar","prof_nnet","prof_mode","prof_version","prof_skip",
				# HTM summary
		     "htm_nhtm_best","htm_nhtm_2nd_best",
		     "htm_rel_best","htm_rel_best_diff","htm_rel_best_dproj",
		     "htm_model","htm_model_dat",
		     "htm_htmtop_obs","htm_htmtop_prd",
		     "htm_htmtop_modprd","htm_htmtop_rid","htm_htmtop_rip",
		     ],
	 'gen'   => [
		     "No","AA"
		     ],
	 'ri'    => 
	 {
	     'acc'=>          "RI_A",
	     'htm'=>          "RI_M",
	     'htmfin'=>       "RI_M",
	     'sec'=>          "RI_S",
	     'htmHcap'=>      "RI_HcapH",
	     'htmEcap'=>      "RI_EcapH",
	     'htmHEcap'=>     "RI_HEcapH",
	     'secHcap'=>      "RI_HcapS",
	     'secEcap'=>      "RI_EcapS",
	     'secHEcap'=>     "RI_HEcapS"
	     },
	 'want'  =>
	 {
	     'sec'=>      ["OHEL","PHEL","RI_S"],
	     'acc'=>      ["OHEL","OACC","PACC","OREL","PREL","RI_A","Obe","Pbe","Obie","Pbie"],
	     'htm'=>      ["OMN","PMN","PRMN","PR2MN","PiMo","RI_M"],
	     'htmHcap'=>  ["OHcapH","PHcapH","RI_HcapH" ],
	     'htmEcap'=>  ["OEcapH","PEcapH","RI_EcapH" ],
	     'htmHEcap'=> ["OHcapH","PHcapH","RI_HEcapH"],
	     'secHcap'=>  ["OHcapS","PHcapS","RI_HcapS" ],
	     'secEcap'=>  ["OEcapS","PEcapS","RI_EcapS" ],
	     'secHEcap'=> ["OHcapS","PHcapS","RI_HEcapS"]
	     }
	 );
    $kwdGlob{"HELBGT","p"}= "p6";
    $kwdGlob{"HELBGT","Ot"}="Ot6";
				# succession for writing columns

    $kwdGlob{"succession"}= "No,AA,";
    $kwdGlob{"succession"}.="OHEL,PHEL,RI_S,";
    $kwdGlob{"succession"}.="OACC,PACC,OREL,PREL,RI_A,";
    $kwdGlob{"succession"}.="OMN,PMN,PRMN,PR2MN,PiMo,RI_M,";
    $kwdGlob{"succession"}.="OHcapH,PHcapH,RI_HcapH,";
    $kwdGlob{"succession"}.="pH,pE,pL,pM,pN,";
    $kwdGlob{"succession"}.="Obe,Pbe,Obie,Pbie,";
    $kwdGlob{"succession"}.="OtH,OtE,OtT,OtL,Ot0,Ot1,Ot2,Ot3,Ot4,Ot5,Ot6,Ot7,Ot8,Ot9,OtM,OtN";

    $kwdGlob{"succession","notation","sec"}="OHEL,PHEL,RI_S,pH,pE,pL,OtH,OtE,OtT,OtL,";
    $kwdGlob{"succession","notation","acc"}="OACC,PACC,OREL,PREL,RI_A,Obe,Pbe,Obie,Pbie,Ot4";
    $kwdGlob{"succession","notation","htm"}="OMN,PMN,PRMN,PR2MN,PiMo,RI_M,pM,pN,OtM,OtN,";

	

				# ------------------------------
				# translate old keywords
    %kwdTranslate=
	(
	 'RI_M', "RI_H",		# final 'RI_M' may be called 'RI_H'
	 'OMN',  "OHL",
	 'PMN',  "PHL",
	 'OtM',  "OtH",
	 'OtN',  "OtL",
	 'pM',   "pH",
	 'pN',   "pL",
	 'PRMN', "PRHL",
	 'PRMN2',"PRHL2",
	 '',"",
	 );
				# ------------------------------
				# ri for known ones
    $par{"known","HELsnd21uu.jct","ri_ave"}=4.763;
    $par{"known","HELsnd21uu.jct","ri_sig"}=1.133;
    $par{"known","HELsnd21ub.jct","ri_ave"}=4.750;
    $par{"known","HELsnd21ub.jct","ri_sig"}=1.099;
    $par{"known","HELsnd21bu.jct","ri_ave"}=4.659;
    $par{"known","HELsnd21bu.jct","ri_sig"}=1.111;
    $par{"known","HELsnd21bb.jct","ri_ave"}=4.825;
    $par{"known","HELsnd21bb.jct","ri_sig"}=1.161;
    $par{"known","HELsnd17uu.jct","ri_ave"}=4.678;
    $par{"known","HELsnd17uu.jct","ri_sig"}=1.043;
    $par{"known","HELsnd17ub.jct","ri_ave"}=4.566;
    $par{"known","HELsnd17ub.jct","ri_sig"}=1.187;
    $par{"known","HELsnd17bu.jct","ri_ave"}=4.833;
    $par{"known","HELsnd17bu.jct","ri_sig"}=1.093;
    $par{"known","HELsnd17bb.jct","ri_ave"}=4.453;
    $par{"known","HELsnd17bb.jct","ri_sig"}=1.147;
    
				# ------------------------------
				# for intermediate output
    $par{"aa"}=                 "VLIMFWYGAPSTCHRKQEND"; 
    @aa=split(//,$par{"aa"});
    $#aa21=$#aaXprof=$#aaXprofBig=0; # avoid warning
    @aa21=(@aa," ");		# for protein input unit unit 21=SPACER
				# profile for unknown AA
    @aaXprof=
	# V   L   I   M   F   W   Y   G   A   P   S   T   C   H   R   K   Q   E   N   D
	(6.9,8.5,5.5,2.1,4.0,1.5,3.6,7.7,8.4,4.7,6.0,5.7,1.6,2.3,4.8,5.9,3.9,6.3,4.6,5.9);

    @aaXprofBig=
	# V   L   I   M   F   W   Y   G   A   P   S   T   C   H   R   K   Q   E   N   D
	(7.0,8.6,5.8,2.1,4.1,1.3,3.5,7.8,7.9,4.4,6.3,5.7,2.0,2.3,4.8,6.1,3.7,6.4,4.4,5.8);

				# normalise to values < 1!
    $sum=0;
    foreach $tmp (@aaXprof) {
	$tmp=$tmp/100;
	$sum+=$tmp; 
    }
    $sum=0;
    foreach $tmp (@aaXprofBig) {
	$tmp=$tmp/100;
	$sum+=$tmp; 
    }

    foreach $tmp(@aa){$aa{$tmp}=1;}
    $aa=$par{"aa"};

    undef %nndbPtr;		# avoid warnings
    $Date=$timeBeg="";		# avoid warnings

    %nndbPtr=('nocc',   "NOCC",   
	      'ndel',   "NDEL",   
	      'nins',   "NINS",   
	      'entr',   "ENTROPY",
	      'rele',   "RELENT", 
	      'cons',   "WEIGHT",
	      'nfar',   "ndist",
	      );

				# hydrophobicity scales
    $#hydrophobicityScales=0;	# avoid warning
    @hydrophobicityScales=
	(
#	 "ges","kydo","heijne","htm",
	 "eisen",
	 "ooi"
	 );


				# ------------------------------
				# file handles
				# ------------------------------
#    $fhout=                     "FHOUT";
#    $fhin=                      "FHIN";
    $FHTRACE=                   "FHTRACE";
    $FHERROR=                   "STDERR";
    $SEP="";			# avoid warnings
    $SEP=                       "\t";


				# --------------------------------------------------
				# network stuff
				# --------------------------------------------------

				# ------------------------------
				# architecture, fixed
#    $par{"numlayers"}=          2;     # number of layers (2 = input:hidden:output)
    $par{"bitacc"}=	      100;     # accuracy of computation.   All done with integers,
				#    thus if BITACC = 100, then the output 0.117 equals
				#    that of 0.118 (for BITACC =1000 this is not true )
				#    e.g.: H,E,L ->   1,0,0 => bitacc=1  
				#    or:   H,E,L -> 100,0,0 => bitacc=100
#    $par{"threshout"}=		0.5;   # only used for single output units: 
				       #    binary = 0 if out< THRESHOUT, =1 else
    $par{"numaa"}=             $#aa+1; # number of amino acids (20 + SPACER + 'X')
#    $par{"numwin"}=	       17;     # window size, i.e., number of adjacent residues used for one example

    $par{"codeLen"}=            "60,120,240,400"; # :

				# ------------------------------
				# sequence length coded in given intervals (<n), + last= >n
    $par{"codeNali"}=           "2,5,10";      # code for number of sequences aligned
    $par{"codeNfar"}=           "2,5,10";      # code for number of sequences aligned that varied a lot
    $par{"codeDisN"}=           "10,20,30,40"; # code for distance to N-term
    $par{"codeDisC"}=           "10,20,30,40"; # code for distance to C-term

				# ------------------------------
				# format for FORTRAN
    $par{"formRepeat"}=         25;            # input for FORTRAN in with 25 numbers per line

				# ------------------------------
				# control FOR I/O
#     $par{"logi_rdparwrt"}=	1;              # write the parameters read?
#     $par{"logi_rdinwrt"}=	1;              # write the input vectors read?
#     $par{"logi_rdoutwrt"}=	1;              # write the output vectors read?
#     $par{"logi_rdjctwrt"}=	1;              # write the junctions read?
#     $par{"logi_rdparwrt"}=      1; # 
#     $par{"logi_rdinwrt"}=       1; # 
#     $par{"logi_rdoutwrt"}=      1; # 
#     $par{"logi_rdjctwrt"}=      1; # 

}				# end of iniDefProf

1;
