#! /usr/bin/perl -w
##! /usr/sbin/perl -w
##! /usr/pub/bin/perl -w
#------------------------------------------------------------------------------#
#	Copyright				June,    	1998	       #
#	Burkhard Rost		rost@LION-ag.de,rost@EMBL-heidelberg.de	       #
#	Wilckensstr. 15		http://www.embl-heidelberg.de/~rost/	       #
#	D-69120 Heidelberg						       #
#				version 0.4   	May,    	1998	       #
#------------------------------------------------------------------------------#
##
#   
#                               ---------------------
#   lib-br                      internal subroutines:
#                               ---------------------
#   aa3lett_to_1lett            converts AA 3 letter code into 1 letter
#   blast3Formatdb              formats a db for BLAST (blast 3 = new PSI blast)
#   blast3RunSimple             simply runs BLASTALL (blast3)
#   blastGetSummary             BLAST out -> summary: IDE,LALI,LEN,PROB,DISTANCE-to-hssp-curve
#   blastpExtrId                extracts only lines with particular id from BLAST
#   blastpRdHdr                 reads header of BLASTP output file
#   blastpRun                   runs BLASTP
#   blastpRunSimple             simply runs BLASTP (blast2)
#   blastpFormatdb              formats a db for BLASTP (blast 2)
#   blastSetenv                 sets environment for BLASTP runs
#   blastWrtSummary             writes summary for blast results (%ide,len,distance HSSP)
#   brIniErr                    error check for initial parameters
#   brIniGetArg                 standard reading of command line arguments
#   brIniHelp                   initialise help text
#   brIniHelpLoop               loop over help 
#   brIniHelpRdItself           reads the calling perl script (scrName),
#   brIniRdDef                  reads defaults for initialsing parameters
#   brIniRdDefWhere             searches for a default file
#   brIniSet                    changing parameters according to input arguments
#   brIniWrt                    write initial settings on screen
#   bynumber                    function sorting list by number
#   bynumber_high2low           function sorting list by number (start with high)
#   checkMsfFormat              basic checking of msf file format
#   coilsRd                     reads the column format of coils
#   coilsRun                    runs the COILS program from Andrei Lupas
#   convert_acc                 converts accessibility (acc) to relative acc
#   convert_sec                 converts 8 DSSP secondary str. into 3 (H,E,L)= default 
#   convert_secFine             takes an entire string ('HEL') and fine-tunes: ' EHH'-> '  HH'
#   convDssp2fasta              converts DSSP to FASTA format
#   convFasta2gcg               convert fasta format to GCG format
#   convFastamul2many           1
#   convFssp2Daf                converts an HSSP file into the DAF format
#   convGcg2fasta               converts GCG to FASTA format
#   convHssp2Daf                converts an HSSP file into the DAF format
#   convHssp2msf                runs convert_seq for HSSP -> MSF
#   convHssp2seq                converts HSSP file to PIR(mul), FASTA(mul)
#   convMsf2Hssp                converts the MSF into an HSSP file
#   convMsf2saf                 converts MSF into SAF format
#   convPhd2col                 writes the prediction in column format
#   convPir2fasta               converts PIR to FASTA format
#   convSaf2many                converts SAF into many formats: saf2msf, saf2fasta, saf2pir
#   convSwiss2fasta             converts SWISS-PROT to FASTA format
#   convSeq2fasta               convert all formats to fasta
#   convSeq2fastaPerl           convert all formats to fasta (no fortran)
#   convSeq2pir                 convert all sequence formats to PIR
#   convSeq2gcg                 convert all formats to gcg
#   convSeq2seq                 convert all sequence-only formats to sequence only
#   copf2fasta                  runs copf.pl converting all input files to FASTA
#   correlation                 between x and y
#   dafRdAli                    read alignments from DAF format
#   dafWrtAli                   writes a file in output format of DAF
#   dafWrtAliHeader             writes the header for DAF file
#   dsspGetChain                extracts all chains from DSSP
#   dsspGetFile                 searches all directories for existing DSSP file
#   dsspGetFileLoop             loops over all directories
#   dsspRdSeq                   extracts the sequence from DSSP
#   equal_tolerance             returns 0, if v1==v2 +- $tol
#   errSbr                      simply writes '*** ERROR $sbrName: $txtInLoc'
#   errSbrMsg                   simply writes '*** ERROR $sbrName: $txtInLoc\n'.$msg
#   evalsecTableqils2syn        greps the final summary from TABLEQILS (xevalsec.f)
#   evalseg_oneprotein          evaluates the pred accuracy as HTM segments
#   exposure_normalise_prepare  normalisation weights (maximal: Schneider, Dipl)
#   exposure_normalise          normalise DSSP accessibility with maximal values
#   exposure_project_1digit     1
#   extract_pdbid_from_hssp     extracts all PDB ids found in the HSSP 0 header
#   fastaRdGuide                reads first sequence in list of FASTA format
#   fastaRdMul                  reads many sequences in FASTA db
#   fastaRun                    runs FASTA
#   fastaWrt                    writes a sequence in FASTA format
#   fastaWrtMul                 writes a list of sequences in FASTA format
#   fctSeconds2time             converts seconds to hours:minutes:seconds
#   fileListArrayRd             returns array of HSSP files
#   fileListRd                  reads a list of files
#   fileListWrt                 writes a list of files
#   filter_hssp_curve           computes HSSP curve based on in:    ali length, seq ide
#   filter_oneprotein           reads .pred files
#   filter1_change              ??? (somehow to do with filter_oneprotein)
#   filter1_rel_lengthen        checks in N- and C-term, whether rel > cut
#   filter1_rel_shorten         checks in N- and C-term, whether rel > cut
#   form_perl2rdb               converts printf perl (d,f,s) into RDB format (N,F, ) 
#   form_rdb2perl               1
#   fRound                      returns the rounded integer of real input (7.6->8; 7.4->7)
#   fsspGetFile                 searches all directories for existing FSSP file
#   fsspGetFileLoop             loops over all directories
#   fsspRdSummary               read the summary table of an FSSP file
#   fssp_rd_ali                 reads one entire alignment for an open FSSP file
#   fssp_rd_one                 reads for a given FSSP file one particular ali+header
#   func_absolute               compiles the absolute value
#   func_faculty                compiles the faculty
#   func_n_over_k               compiles N over K
#   func_n_over_k_sum           compiles sum/i {N over i}
#   func_permut_mod             computes all possible permutations for $num, e.g. n=4:
#   func_permut_mod_iterate     repeats permutations (called by func_permut_mod)
#   funcAddMatdb2prof           combines profile read + db matrix (for nali < x)
#   funcInfoConditional         Fano information
#   funcLog                     converts the perl log (base e) to any log
#   funcNormMinMax              normalises numbers with (min1,max1) to a range of (min0,max0)
#   gcgRd                       reads sequence in GCG format
#   get_chain                   extracts a chain identifier from file name
#   get_hssp_file               searches all directories for existing HSSP file
#   get_id                      extracts an identifier from file name
#   get_in_keyboard             gets info from keyboard
#   get_in_database_files       reads command line, checks validity of format, returns array
#   get_max                     returns the maximum of all elements of @in
#   get_min                     returns the minimum of all elements of @in
#   get_pdbid                   extracts a valid PDB identifier from file name
#   get_range                   converts range=n1-n2 into @range (1,2)
#   get_rangeHyphen             reads 'n1-n2'  
#   get_secstr_segment_caps     returns positions of secondary str. segments in string
#   get_sum                     computes the sum over input data
#   get_zscore                  returns the zscore = (score-ave)/sigma
#   getDistanceHsspCurve        computes the HSSP curve for in:    ali length
#   getDistanceNewCurveIde      out= pide value for new curve
#   getDistanceNewCurveSim      out= psim value for new curve
#   getDistanceThresh           compiles the distance from a threshold
#   getFileFormat               returns format of file
#   getFileFormatQuick          quick scan for file format: assumptions
#   getPhdSubset                subset from string with PHDsec|acc|htm + rel index
#   globeOne                    1
#   globeFuncFit                length to number of surface molecules fitted to PHD error 
#   globeRdPhdRdb               read PHD rdb file with ACC
#   globeWrt                    writes output for GLOBE
#   hssp_fil_num2txt            translates a number for percentage sequence iden-
#   hssp_rd_header              reads the header of an HSSP file for numbers 1..$#num
#   hssp_rd_strip_one           reads the alignment for one sequence from a (new) strip file
#   hssp_rd_strip_one_correct1  correct for begin and ends
#   hssp_rd_strip_one_correct2  shorten indels for begin and ends
#   hsspChopProf                chops profiles from HSSP file
#   hsspfile_to_pdbid           extracts id from hssp file
#   hsspFilterGetPosExcl        flags positions (in pairs) to exclude
#   hsspFilterGetPosIncl        flags positions (in pairs) to include
#   hsspFilterGetIdeCurve       flags positions (in pairs) above identity threshold
#   hsspFilterGetIdeCurveMinMax flags positions (in pairs) above maxIde and below minIde
#   hsspFilterGetSimCurve       flags positions (in pairs) above similarity threshold
#   hsspFilterGetSimCurveMinMax flags positions (in pairs) above maxSim and below minSim
#   hsspFilterGetRuleBoth       flags all positions (in pairs) with:
#   hsspFilterGetRuleSgi        Sim > Ide, i.e. flags all positions (in pairs) with: 
#   hsspFilterMarkFile          marks the positions specified in command line
#   hsspGetChain                extracts all chain identifiers in HSSP file
#   hsspGetChainBreaks          extracts all chain breaks (if not labelled, or
#   hsspGetChainLength          extracts the length of a chain in an HSSP file
#   hsspGetChainNali            gets Nali for chain X (restricted to HSSP dist D)
#   hsspGetFile                 searches all directories for existing HSSP file
#   hsspGetFileLoop             loops over all directories
#   hsspRdAli                   reads and writes the sequence of HSSP + 70 alis
#   hsspRdHeader                reads a HSSP header
#   hsspRdHeader4topits         extracts the summary from HSSP header (for TOPITS)
#   hsspRdProfile               reads the HSSP profile from ifir to ilas
#   hsspRdSeqSecAcc             reads the HSSP seq/sec/acc from ifir to ilas
#   hsspRdSeqSecAccOneLine      reads begin of one HSSP line
#   hsspRdStrip4topits          reads the new strip file for PP
#   hsspRdStripAndHeader        reads the headers for HSSP and STRIP and merges them
#   hsspRdStripHeader           reads the header of a HSSP.strip file
#   hsspSkewProf                changes the HSSP profile for too few alignments
#   interpretSeqCol             extracts the column input format and writes it
#   interpretSeqFastalist       extracts the Fasta list input format
#   interpretSeqMsf             extracts the MSF input format
#   interpretSeqPirlist         extracts the PIR list input format
#   interpretSeqPP              suppose it is old PP format: write sequenc file
#   interpretSeqSaf             extracts the SAF input format
#   interpretSeqSafFillUp       fill up with dots if sequences shorter than guide
#   is_chain                    checks whether or not a PDB chain
#   is_dssp                     checks whether or not file is in DSSP format
#   is_dssp_list                checks whether or not file is a list of DSSP files
#   is_fssp                     checks whether or not file is in FSSP format
#   is_fssp_list                1
#   is_hssp                     checks whether or not file is in HSSP format
#   is_hssp_empty               checks whether or not HSSP file has NALIGN=0
#   is_hssp_list                checks whether or not file contains a list of HSSP files
#   is_list                     returns 1 if list of existing files
#   is_nndb_rdb                 
#   is_nninFor                  is input for FORTRAN input
#   is_odd_number               checks whether number is odd
#   is_pdbid                    checks whether or not id is a valid PDBid (number 3 char)
#   is_pdbid_list               checks whether id is list of valid PDBids (number 3 char)
#   is_ppcol                    checks whether or not file is in RDB format
#   is_rdb                      checks whether or not file is in RDB format
#   is_rdbf                     checks whether or not file is in RDB format
#   is_rdb_acc                  checks whether or not file is in RDB format from PHDacc
#   is_rdb_htm                  checks whether or not file is in RDB format from PHDhtm
#   is_rdb_htmref               checks whether or not file is RDB from PHDhtm_ref
#   is_rdb_htmtop               checks whether or not file is RDB from PHDhtm_top
#   is_rdb_nnDb                 checks whether or not file is in RDB format for NN.pl
#   is_rdb_sec                  checks whether or not file is RDB from PHDsec
#   is_strip                    checks whether or not file is in HSSP-strip format
#   is_strip_list               checks whether or not file contains a list of HSSPstrip files
#   is_strip_old                checks whether file is old strip format
#   is_swissprot                
#   is_swissid                  1
#   is_swissid_list             1
#   isDaf                       checks whether or not file is in DAF format
#   isDafGeneral                checks (and finds) DAF files
#   isDafList                   checks whether or not file is list of Daf files
#   isDsspGeneral               checks (and finds) DSSP files
#   isFasta                     checks whether or not file is in FASTA format 
#   isFastaMul                  checks whether more than 1 sequence in FASTA found
#   isFsspGeneral               checks (and finds) FSSP files
#   isGcg                       checks whether or not file is in Gcg format (/# SAF/)
#   isHelp                      returns 1 if : help,man,-h
#   isHsspGeneral               checks (and finds) HSSP files
#   isMsf                       checks whether or not file is in MSF format
#   isMsfGeneral                checks (and finds) MSF files
#   isMsfList                   checks whether or not file is list of Msf files
#   isPhdAcc                    checks whether or not file is in MSF format
#   isPhdHtm                    checks whether or not file is in MSF format
#   isPhdSec                    checks whether or not file is in MSF format
#   isPir                       checks whether or not file is in Pir format 
#   isPirMul                    checks whether or not file contains many sequences 
#   isRdb                       checks whether or not file is in RDB format
#   isRdbGeneral                checks (and finds) RDB files
#   isRdbList                   checks whether or not file is list of Rdb files
#   isSaf                       checks whether or not file is in SAF format (/# SAF/)
#   isSwiss                     checks whether or not file is in SWISS-PROT format (/^ID   /)
#   isSwissGeneral              checks (and finds) SWISS files
#   isSwissList                 checks whether or not file is list of Swiss files
#   maxhomCheckHssp             checks: (1) any ali? (2) PDB?
#   maxhomGetArg                gets the input arguments to run MAXHOM
#   maxhomGetArgCheck           performs some basic file-existence-checks
#   maxhomGetThresh             translates cut-off ide into text input for MAXHOM csh
#   maxhomGetThresh4PP          translates cut-off ide into text input for MAXHOM csh
#   maxhomMakeLocalDefault      build local maxhom default file, and set PATH!!
#   maxhomRun                   runs Maxhom (looping for many trials + self)
#   maxhomRunLoop               loops over a maxhom run (until paraTimeOutL = 3hrs)
#   maxhomRunSelf               runs a MaxHom: search seq against itself
#   metric_ini                  initialise the metric reading ($string_aa returned=)
#   metric_norm_minmax          converting profiles (min <0, max>0) to percentages (0,1)
#   metric_rd                   reads a Maxhom formatted sequence metric
#   metricRdbRd                 reads an RDB formatted substitution metric, e.g.
#   month2num                   converts name of month to number
#   msfBlowUp                   duplicates guide sequence for conversion to HSSP
#   msfCheckFormat              basic checking of msf file format
#   msfCountNali                counts the number of alignments in MSF file
#   msfRd                       reads MSF files input format
#   msfWrt                      writing an MSF formatted file of aligned strings
#   msfCheckNames               reads MSF file and checks consistency of names
#   myprt_array                 prints array ('sep',@array)
#   myprt_empty                 writes line with '--- \n'
#   myprt_line                  prints a line with 70 '-'
#   myprt_npoints               writes line with N dots of the form '....,....1....,....2' 
#   myprt_points80              1
#   myprt_txt                   adds '---' and '\n' for writing text
#   numerically                 function sorting list by number
#   open_file                   opens file, writes warning asf
#   pdbid_to_hsspfile           finds HSSP file for given id (old)
#   phdAliWrt                   converts PHD.rdb to SAF format (including ali)
#   phdHtmIsit                  returns best HTM
#   phdHtmGetBest               returns position (begin) and average val for best HTM
#   phdPredWrt                  writes into file readable by EVALSEC|ACC
#   phdRdbMerge                 manages merging two PHD *.rdb files ('name'= acc + sec + htm)
#   phdRdbMergeDef              sets defaults for phdRdbMerg
#   phdRdbMergeDo               merging two PHD *.rdb files ('name'= acc + sec)
#   phdRdbMergeHdr              writes the merged RDB header
#   phdRun                      runs all 3 FORTRAN programs PHD
#   phdRunIniFileNames          assigns names to intermediate files for FORTRAN PHD
#   phdRun1                     runs the FORTRAN program PHD once (sec XOR acc XOR htm) 
#   phdRunPost1                 
#   phdRunWrt                   merges 2-3 RDB files (sec,acc,htm?)
#   pirRdSeq                    reads the sequence from a PIR file
#   pirRdMul                    reads the sequence from a PIR file
#   pirWrtMul                   writes a list of sequences in PIR format
#   ppHsspRdExtrHeader          extracts the summary from HSSP header (for PP)
#   ppStripRd                   reads the new strip file generated for PP
#   ppTopitsHdWrt               writes the final PP TOPITS output file
#   printm                      print on multiple filehandles (in:$txt,@fh; out:print)
#   prodomRun                   runs a BLASTP against the ProDom db
#   prodomWrt                   write the PRODOM data + BLAST ali
#   profile_count               computes the profile for two sequences
#   ranPickFast                 selects succesion of numbers 1..$numSamLoc at 
#   ranPickGood                 selects succesion of numbers 1..$numSamLoc at 
#   rd_col_associative          reads the content of a comma separated file
#   rd_rdb_associative          reads the content of an RDB file into an associative
#   rdb2html                    convert an RDB file to HTML
#   rdbGenWrtHdr                writes a general header for an RDB file
#   rdbphd_to_dotpred           converts RDB files of PHDsec,acc,htm (both/3)
#   rdbphd_to_dotpred_getstring transform $rdb{"osec","1..n"} to $STRING{"osec"}
#   rdbphd_to_dotpred_getsubset assigns subsets:
#   rdbphd_to_dotpred_head_htmtop writes the header for htmtop
#   rdRdbAssociative            reads content of an RDB file into associative array
#   rdRdbAssociativeNum         reads from a file of Michael RDB format:
#   read_dssp_seqsecacc         reads seq, secondary str and acc from DSSP file
#   read_fssp                   reads the aligned fragment ranges from fssp files
#   read_hssp_seqsecacc         reads sequence, secondary str and acc from HSSP file
#   read_exp80                  reads a secondary structure 80lines file
#   read_rdb_num                reads from a file of Michael RDB format:
#   read_rdb_num2               reads from a file of Michael RDB format:
#   read_sec80                  reads a secondary structure 80lines file
#   safRd                       reads SAF format
#   safWrt                      writing an SAF formatted file of aligned strings
#   secstr_convert_dsspto3      converts DSSP 8 into 3
#   seqGenWrt                   writes protein sequence in various output formats
#   seqide_compute              returns pairwise seq identity between 2 strings
#   seqide_exchange             exchange matrix res type X in seq 1 -> res type Y in seq 2
#   seqide_weighted             1
#   sort_by_pdbid               sorts a list of ids by alphabet (first number opressed)
#   stat_avevar                 computes average and variance
#   stat2DarrayWrt              writes counts
#   swissGetFile                
#   swissGetKingdom             gets all species for given kingdom
#   swissGetLocation            searches in SWISS-PROT file for cell location           
#   swissGetRegexp              1
#   swissRdSeq                  reads the sequence from a SWISS-PROT file
#   topitsWrtOwn                writes the TOPITS format
#   topitsWrtOwnHdr             writes the HEADER for the TOPITS specific format
#   write80_data_prepdata       writes input into array called @write80_data
#   write80_data_preptext       writes input into array called @write80_data
#   write80_data_do             writes hssp seq + sec str + exposure
#   write_pir                   writes protein into PIR format
#   write_rdb_header            writes a header for an RDB file
#   write_rdb_line              writes one line of an RDB file
#   wrt_dssp_phd                writes DSSP format for
#   wrt_msf                     writing an MSF formatted file of aligned strings
#   wrt_phd_header2pp           header for phd2pp
#   wrt_phd_rdb2col             writes out the PP send format
#   wrt_phd_rdb2pp              writes out the PP send format
#   wrt_phd2msf                 converts HSSP to MSF and merges the PHD prediction
#   wrt_phdpred_from_string     write body of PHD.pred files from global array %STRING{}
#   wrt_phdpred_from_string_htm body of PHD.pred files from global array %STRING{} for HTM
#   wrt_phdpred_from_string_htm_header 
#   wrt_phdpred_from_string_htmHdr writes the header for PHDhtm ref and top
#   wrt_ppcol                   writes out the PP column format
#   wrt_strings                 writes several strings with numbers..
#   wrt_strip_pp2               writes the final PP output file
#   wrtHsspHeaderTopBlabla      writes header for HSSP RDB (or simlar) output file
#   wrtHsspHeaderTopData        write DATA for new header of HSSP (or simlar)
#   wrtHsspHeaderTopFirstLine   writes first line for HSSP+STRIP header (perl-rdb)
#   wrtHsspHeaderTopLastLine    writes last line for top of header (to recognise next)
#   wrtMsf                      writing an MSF formatted file of aligned strings
#   wrtRdb2HtmlHeader           write the HTML header
#   wrtRdb2HtmlBody             writes the body for a RDB->HTML file
#   wrtRdb2HtmlBodyColNames     writes the column names (called by previous)
#   wrtRdb2HtmlBodyAve          inserts a break in the table for the averages at end of
# 
# 
# -----------------------------------------------------------------------------# 
#                               ---------------------
#   lib-br                      external subroutines:
#                               ---------------------
# 
#   call from lib-ut:           complete_dir,fileCp,run_program,sysCpfile,sysDate,sysRunProg
# 
#   call from system:           $cmd 
#                               $exeConv $fileFssp $dirDsspLoc >> $fileDafTmp 
#                               $exePhd2Msf $arg
#                               \\rm MAX*$jobid
#                               setenv BLASTDB $tmp
# 
#   call from missing:          conv_fssp2daf_lh
#                               ctime
#                               localtime
#                               ctrlAlarm
#                               phd_htmfil
#                               phd_htmisit
#                               phd_htmref
#                               phd_htmtop
# 
# 
# 
##
#===============================================================================
#
# bb: BEGIN of library
#
#===============================================================================
sub aa3lett_to_1lett {
    local($aain) = @_; 
    local($tmpin,$tmpout);
    $[ =1;
#-------------------------------------------------------------------------------
#   aa3lett_to_1lett            converts AA 3 letter code into 1 letter
#       out GLOBAL:             $aa3lett_to_1lett
#-------------------------------------------------------------------------------
    $tmpin=$aain; $tmpin=~tr/[a-z]/[A-Z]/;
    if    ($tmpin eq "ALA") { $tmpout="A"; }
    elsif ($tmpin eq "CYS") { $tmpout="C"; }
    elsif ($tmpin eq "ASP") { $tmpout="D"; }
    elsif ($tmpin eq "GLU") { $tmpout="E"; }
    elsif ($tmpin eq "PHE") { $tmpout="F"; }
    elsif ($tmpin eq "GLY") { $tmpout="G"; }
    elsif ($tmpin eq "HIS") { $tmpout="H"; }
    elsif ($tmpin eq "ILE") { $tmpout="I"; }
    elsif ($tmpin eq "LYS") { $tmpout="K"; }
    elsif ($tmpin eq "LEU") { $tmpout="L"; }
    elsif ($tmpin eq "MET") { $tmpout="M"; }
    elsif ($tmpin eq "ASN") { $tmpout="N"; }
    elsif ($tmpin eq "PRO") { $tmpout="P"; }
    elsif ($tmpin eq "GLN") { $tmpout="Q"; }
    elsif ($tmpin eq "ARG") { $tmpout="R"; }
    elsif ($tmpin eq "SER") { $tmpout="S"; }
    elsif ($tmpin eq "THR") { $tmpout="T"; }
    elsif ($tmpin eq "VAL") { $tmpout="V"; }
    elsif ($tmpin eq "TRP") { $tmpout="W"; }
    elsif ($tmpin eq "TYR") { $tmpout="Y"; }
    elsif ($tmpin eq "UNK") { $tmpout="X"; }
    else { 
	print "*** ERROR in (lib-br) aa3lett_to_1lett:\n";
	print "***       AA in =$aain, doesn't correspond to known acid.\n";
	$tmpout="X";
    }
    $aa3lett_to_1lett=$tmpout;
}				# end of aa3lett_to_1lett 

#===============================================================================
sub blast3Formatdb {
    local($fileInLoc,$titleLoc,$exeFormatdbLoc,$fileOutScreenLoc,$fhSbrErr) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   blast3Formatdb              formats a db for BLAST (blast 3 = new PSI blast)
#                               NOTE: automatically sets environment !!!
#                                  syntax 'formatdb -t TITLE -i DIR/fasta-file -l logfile'
#                                  note:  files will be created in DIR !
#       in:                     $fileInLoc     : FASTAmul formatted db file
#       in:                     $fileOutLoc    : BLASTP output                if = 0: onto screen
#       in:                     $exeBlastLoc   : FORTRAN exe BLASTP           if = 0: default
#       in:                     $fileOutScreen : screen dumpb of system call  if = 0: 0 -> STDOUT
#       in:                     $fhSbrErr      : error file handle
#       out:                    1|0,msg,$title : name of formatted db
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."blast3Formatdb";$fhinLoc="FHIN_"."blast3Formatdb";
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
    return(&errSbr("miss in file '$fileInLoc'!"))  if (! -e $fileInLoc);
                                # ------------------------------
				# local defaults
    $exeFormatdbLocDef=            "/home/rost/pub/molbio/formatdb.$ARCH";
                                # ------------------------------
				# check arguments
    $titleLoc=0                 if (! defined $titleLoc);
    $exeFormatdbLoc=$exeFormatdbLocDef 
                                if (! defined $exeFormatdbLoc || ! $exeFormatdbLoc);

    $fhSbrErr="STDOUT"          if (! defined $fhSbrErr || ! $fhSbrErr);
    $fileOutScreenLoc=0         if (! defined $fileOutScreenLoc || ! $fileOutScreenLoc);

    $cmdSys="";
				# ------------------------------
				# title and setenv BLASTDB
    if (! $titleLoc)     {	# ------------------------------
	$titleLoc=$fileInLoc;
	$titleLoc=~s/^.*\///g;}
    $tmp=$fileInLoc; $tmp=~s/^(.*)\/.*$/$1/g;
    if (length($tmp)<1 && defined $ENV{'PWD'})  { 
	$tmp=$ENV{'PWD'};}
    if (length($tmp) > 1){
	$tmp=~s/\/$//g;
	system("setenv BLASTDB $tmp");}
				# ------------------------------
				# run formatdb (for BLASTP)
				# ------------------------------

                                # syntax 'formatdb -t TITLE -i DIR/fasta-file -l logfile'
                                # note:  files will be created in DIR !
    $cmd= $exeFormatdbLoc." -t $titleLoc -i".$fileInLoc;
    $cmd.="-l $fileOutScreenLoc" if ($fileOutScreenLoc);

    eval "\$cmdSys=\"$cmd\"";
    ($Lok,$msg)=
	&sysRunProg($cmdSys,$fileOutScreenLoc,$fhSbrErr);
    return(&errSbrMsg("failed to run FORMATDB on ($fileInLoc)",$msg)) 
        if (! $Lok || ($fileOutLoc && ! -e $fileOutLoc));

    return(1,"ok $sbrName",$titleLoc);
}				# end of blast3Formatdb

#===============================================================================
sub blast3RunSimple {
    local($fileInLoc,$fileOutLoc,$exeBlast3Loc,$dbBlastLoc,$parELoc,$parBLoc,
	  $fileOutScreenLoc,$fhSbrErr) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   blast3RunSimple             simply runs BLASTALL (blast3)
#                               NOTE: for security call &blastSetenv before running
#       in:                     $fileInLoc     : FASTA formatted input file
#       in:                     $fileOutLoc    : BLASTP output                if = 0: onto screen
#       in:                     $exeBlastLoc   : FORTRAN exe BLASTP           if = 0: default
#       in:                     $dbBlastLoc    : BLASTP db to run             if = 0: swiss
#       in:                     $parELoc       : BLASTP para E                if = 0: default
#       in:                     $parBLoc       : BLASTP para B                if = 0: default
#       in:                     $fileOutScreen : screen dumpb of system call  if = 0: 0 -> STDOUT
#       in:                     $fhSbrErr      : error file handle
#       out:                    1|0,msg,  implicit: file
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."blast3RunSimple";$fhinLoc="FHIN_"."blast3RunSimple";
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
    return(&errSbr("miss in file '$fileInLoc'!"))  if (! -e $fileInLoc);
                                # ------------------------------
				# local defaults
    $exeBlast3LocDef=           "/home/rost/pub/molbio/blastall.$ARCH";
    $dbBlastLocDef=             "swiss";
    $parELocDef=             1000;
    $parBLocDef=             2000;
                                # ------------------------------
				# check arguments
    $fileOutLoc=0               if (! defined $fileOutLoc);
    $exeBlast3Loc=$exeBlast3LocDef  if (! defined $exeBlast3Loc || ! $exeBlast3Loc);
    $dbBlastLoc=$dbBlastLocDef  if (! defined $dbBlastLoc || ! $dbBlastLoc);
    $parELoc=$parELocDef        if (! defined $parELoc || ! $parELoc);
    $parBLoc=$parBLocDef        if (! defined $parBLoc || ! $parBLoc);

    $fhSbrErr="STDOUT"          if (! defined $fhSbrErr || ! $fhSbrErr);
    $fileOutScreenLoc=0         if (! defined $fileOutScreenLoc || ! $fileOutScreenLoc);

    $cmdSys="";
				# ------------------------------
				# run BLAST
				# ------------------------------
                                    
    $cmd= $exeBlast3Loc." -i $fileInLoc -p blastp -d $dbBlastLoc -F F -e $parELoc -b $parBLoc";
    $cmd.=" -o $fileOutLoc"      if ($fileOutLoc);

    eval "\$cmdSys=\"$cmd\"";
    ($Lok,$msg)=
	&sysRunProg($cmdSys,$fileOutScreenLoc,$fhSbrErr);
    return(&errSbrMsg("failed to run BLAST3 on ($fileInLoc)",$msg)) 
        if (! $Lok || ($fileOutLoc && ! -e $fileOutLoc));

    return(1,"ok $sbrName");
}				# end of blast3RunSimple

#===============================================================================
sub blastGetSummary {
    local($fileInLoc,$minLaliLoc,$minDistLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok,%hdrLoc,@idtmp,%tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   blastGetSummary             BLAST out -> summary: IDE,LALI,LEN,PROB,DISTANCE-to-hssp-curve
#       in:                     $fileInLoc    : file with BLAST output
#       in:                     $minLaliLoc   : take those with LALI > x      (=0: all)
#       in:                     $minDistLoc   : take those with $pide>HSSP+X  (=0: all)
#       out:                    1|0,msg,$tmp{}, with
#                               $tmp{"NROWS"}     : number of pairs
#                               $tmp{"id",$it}    : name of protein it
#                               $tmp{"len",$it}   : length of protein it
#                               $tmp{"lali",$it}  : length of alignment for protein it
#                               $tmp{"prob",$it}  : BLAST probability for it
#                               $tmp{"score",$it} : BLAST score for it
#                               $tmp{"pide",$it}  : pairwise percentage sequence identity
#                               $tmp{"dist",$it}  : distance from HSSP-curve
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."blastGetSummary";$fhinLoc="FHIN_"."blastGetSummary";
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
    return(&errSbr("miss in file '$fileInLoc'!"))  if (! -e $fileInLoc);
                                # adjust
    $minLaliLoc=0               if (! defined $minLaliLoc || ! $minLaliLoc);
    $minDistLoc=-100            if (! defined $minDistLoc || ! $minDistLoc);
                                # ------------------------------
                                # read file
                                # ------------------------------
    undef %hdrLoc;
    ($Lok,$msg,%hdrLoc)=   
        &blastpRdHdr($fileInLoc);
    return(&errSbrMsg("failed reading blast header ($fileBlast)",$msg)) if (! $Lok);

    $hdrLoc{"id"}=~s/,*$//g;       # interpret
    @idtmp=split(/,/,$hdrLoc{"id"});
                                # ------------------------------
                                # loop over all pairs found
                                # ------------------------------
    undef %tmp; $ct=0;
    foreach $idtmp (@idtmp) {
        next if ($hdrLoc{"$idtmp","lali"} < $minLaliLoc);
                                # compile distance to HSSP threshold (new)
        ($pideCurve,$msg)= 
#            &getDistanceHsspCurve($hdrLoc{"$idtmp","lali"});
            &getDistanceNewCurveIde($hdrLoc{"$idtmp","lali"});
        return(&errSbrMsg("failed getDistanceNewCurveIde",$msg))  
            if ($msg !~ /^ok/);
            
        $dist=$hdrLoc{"$idtmp","ide"}-$pideCurve;
        next if ($dist < $minDistLoc);
                                # is ok -> TAKE it
        ++$ct;
        $tmp{"id","$ct"}=       $idtmp;
	foreach $kwd ("len","lali","prob","score"){
	    $tmp{"$kwd","$ct"}= $hdrLoc{"$idtmp","$kwd"}; }
        $tmp{"pide","$ct"}=     $hdrLoc{"$idtmp","ide"};
        $tmp{"dist","$ct"}=     $dist;
    } 
    $tmp{"NROWS"}=$ct;

    undef %hdrLoc;                 # slim-is-in !
    return(1,"ok $sbrName",%tmp);
}				# end of blastGetSummary

#===============================================================================
sub blastpExtrId {
    local($fileInLoc2,$fhoutLoc,@idLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok,$Lhead,$line,$Lread,$id);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   blastpExtrId                extracts only lines with particular id from BLAST
#       in:                     $fileBlast,$fileHANDLE_OUTPUTFILE,@id_to_read
#       in:                     NOTE: if $#id==0, all are read
#       out:                    (1,'ok') + written into FILE_HANDLE
#       err:                    (0,'msg')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."blastpExtrId";$fhinLoc="FHIN"."$sbrName";
				# ------------------------------
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc2!")     if (! defined $fileInLoc2);
    $fhoutLoc="STDOUT"                                if (! defined $fhoutLoc);
    return(0,"*** $sbrName: no in file=$fileInLoc2")  if (! -e $fileInLoc2);
				# ------------------------------
				# open BLAST output
    $Lok=       &open_file("$fhinLoc","$fileInLoc2");
    return(0,"*** ERROR $sbrName: old=$fileInLoc2, not opened\n") if (! $Lok);
				# ------------------------------
    $Lhead=1;			# read file
    while (<$fhinLoc>) {
	print $fhoutLoc $_;
	last if ($_=~/^Sequences producing High/i);}
				# ------------------------------
    while (<$fhinLoc>) {	# skip  header summary
	$_=~s/\n//g;$line=$_;
	if (length($_)<1 || $_ !~/\S/){	# skip empty line
	    print $fhoutLoc "\n";
	    next;}
	if ($_=~/^Parameters/){ # final
	    print $fhoutLoc "$_\n";
	    last;}
	$Lhead=0 if ($line=~/^\s*\>/); # now the alis start
				# --------------------
	if ($Lhead){		# .. but before the alis
	    $Lread=0;
	    foreach $id (@idLoc){ # id found?
		if ($line=~/^\s*$id/){$Lread=1;
				      last;}}
	    print $fhoutLoc "$line\n" if ($Lread);
	    next;}
				# --------------------
				# here the alis should have started
	if ($line=~/^\s*\>/){
	    $Lread=0;
	    foreach $id (@idLoc){ # id found?
		if ($line=~/^\s*\>$id/){$Lread=1;
					last;}}}
	print $fhoutLoc "$line\n" if ($Lread);}
    while(<$fhinLoc>){
	print $fhoutLoc $_;}
    close($fhinLoc);
    return(1,"ok $sbrName");
}				# end of blastpExtrId 

#===============================================================================
sub blastpRdHdr {
    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok,@idFoundLoc,
	  $Lread,$name,%hdrLoc,$Lskip,$id,$line);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   blastpRdHdr                 reads header of BLASTP output file
#       in:                     $fileBlast
#       out:                    (1,'ok',%hdrLoc)
#       out:                    $hdrLoc{"$id"}='id1,id2,...'
#       out:                    $hdrLoc{"$id","$kwd"} , with:
#                                  $kwd=(score|prob|ide|len|lali)
#       err:                    (0,'msg')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."blastpRdHdr";$fhinLoc="FHIN-blastpRdHdr";
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc!")    if (! defined $fileInLoc);
    return(0,"*** $sbrName: no in file=$fileInLoc") if (! -e $fileInLoc);
				# ------------------------------
				# open BLAST output
    open($fhinLoc,$fileInLoc) ||
	return(0,"*** ERROR $sbrName: '$fileInLoc' not opened\n");
				# ------------------------------
    $#idFoundLoc=$Lread=0;	# read file
    while (<$fhinLoc>) {
	last if ($_=~/^\s*Sequences producing /i);}
				# ------------------------------
				# skip header summary
    while (<$fhinLoc>) {
	$_=~s/\n//g;
	next if (length($_)<1 || $_ !~/\S/); # skip empty line
	$Lread=1 if (! $Lread && $_=~/^\s*>/);
	next if (! $Lread);
	last if ($_=~/^\s*Parameters/i); # final
				# ------------------------------
	$line=$_;		# read ali paras
				# id
	if    ($line=~/^\s*>\s*(.*)/){
	    $name=$1;$id=$name;$id=~s/^([\S]+)\s+.*$/$1/g;
	    if (length($id)>0){
		push(@idFoundLoc,$id);$Lskip=0;
		$hdrLoc{"$id","name"}=$name;}
	    else              {
		$Lskip=1;}}
				# length
	elsif (! $Lskip && ! defined $hdrLoc{"$id","len"} && 
	       ($line=~/^\s*Length = (\d+)/)) {
	    $hdrLoc{"$id","len"}=$1;}
				# sequence identity
	elsif (! $Lskip && ! defined $hdrLoc{"$id","ide"} &&
	       ($line=~/^\s* Identities = \d+\/(\d+) \((\d+)/) ) {
	    $hdrLoc{"$id","lali"}=$1;
	    $hdrLoc{"ide","$id"}=$hdrLoc{"$id","ide"}=$2;}
				# score + prob (blast3)
	elsif (! $Lskip && ! defined $hdrLoc{"$id","score"} &&
	       ($line=~/ Score = [\d\.]+ bits \((\d+)\).*, Expect = \s*([\d\-\.e]+)/) ) {
	    $hdrLoc{"$id","score"}=$1;
	    $hdrLoc{"$id","prob"}= $2;}
				# score + prob (blast2)
	elsif (! $Lskip && ! defined $hdrLoc{"$id","score"} &&
	       ($line=~/ Score = (\d+)\s+[^,]*, Expect = ([^,]+), .*$/) ) {
	    $hdrLoc{"$id","score"}=$1;
	    $hdrLoc{"$id","prob"}= $2;}}close($fhinLoc);
				# ------------------------------
    $hdrLoc{"id"}="";		# arrange to pass the result
    for $id(@idFoundLoc){
	$hdrLoc{"id"}.="$id,"; } $hdrLoc{"id"}=~s/,*$//g;

    $#idFoundLoc=0;		# save space
    return(1,"ok $sbrName",%hdrLoc);
}				# end of blastpRdHdr 

#===============================================================================
sub blastpRun {
    local($niceLoc,$dirData,$dirSwissSplit,$exeBlastp,$exeBlastpFil,$envBlastpMat,
	  $envBlastpDb,$nhits,$parBlastpDb,$fileInLoc,$fileOutLoc,$fileOutFilLoc,$fhTraceLoc)=@_;
    local($sbr,$command,$msg,$Lok);
#----------------------------------------------------------------------
#   blastpRun                   runs BLASTP
#       in:                     $niceLoc,$dirData,$dirSwissSplit,$exeBlastp,$exeBlastpFil,
#       in:                     $envBlastpMat,$envBlastpDb,$numHits,$parBlastpDb,
#       in:                     $fileInLoc,$fileOutLoc,$fileOutFilLoc,$fhTraceLoc
#       out:                    
#       err:                    ok=(1,'ok'), err=(0,'msg')
#----------------------------------------------------------------------
    $sbr="lib-br:blastpRun";
    $fhTraceLoc="STDOUT"                               if (! defined $fhTraceLoc);
    return(0,"*** $sbr: not def niceLoc!")          if (! defined $niceLoc);
    return(0,"*** $sbr: not def dirData!")          if (! defined $dirData);
    return(0,"*** $sbr: not def dirSwissSplit!")    if (! defined $dirSwissSplit);
    return(0,"*** $sbr: not def exeBlastp!")        if (! defined $exeBlastp);
    return(0,"*** $sbr: not def exeBlastpFil!")     if (! defined $exeBlastpFil);
    return(0,"*** $sbr: not def envBlastpMat!")     if (! defined $envBlastpMat);
    return(0,"*** $sbr: not def envBlastpDb!")      if (! defined $envBlastpDb);
    return(0,"*** $sbr: not def nhits!")            if (! defined $nhits);
    return(0,"*** $sbr: not def fileInLoc!")        if (! defined $fileInLoc);
    return(0,"*** $sbr: not def fileOutLoc!")       if (! defined $fileOutLoc);
    return(0,"*** $sbr: not def fileOutFilLoc!")    if (! defined $fileOutFilLoc);

    return(0,"*** $sbr: miss dir =$dirData!")       if (! -d $dirData);
    return(0,"*** $sbr: miss dir =$dirSwissSplit!") if (! -d $dirSwissSplit);
    return(0,"*** $sbr: miss dir =$envBlastpDb!")   if (! -d $envBlastpDb);
    return(0,"*** $sbr: miss dir =$envBlastpMat!")  if (! -d $envBlastpMat);

    return(0,"*** $sbr: miss file=$fileInLoc!")     if (! -e $fileInLoc);
    return(0,"*** $sbr: miss exe =$exeBlastp!")     if (! -e $exeBlastp);
    return(0,"*** $sbr: miss exe =$exeBlastpFil!")  if (! -e $exeBlastpFil);

				# ------------------------------
				# set environment needed for BLASTP
    $ENV{'BLASTMAT'}=$envBlastpMat;
    $ENV{'BLASTDB'}= $envBlastpDb;
                                # ------------------------------
                                # run BLASTP
                                # ------------------------------
    $command="$niceLoc $exeBlastp $parBlastpDb $fileInLoc B=$nhits > $fileOutLoc";
    $msg="--- $sbr '$command'\n";

    $Lok=
	&run_program("$command" ,"$fhTraceLoc","warn");
    if (!$Lok){
	return(0,"*** ERROR $sbr '$Lok'\n"."$msg");}
    if (! -e $fileOutLoc){
	return(0,"*** ERROR $sbr no output '$fileOutLoc'\n"."$msg");}
				# ------------------------------
				# extract hits from BLASTP-output
				# ------------------------------
    $dirSwissSplit=~s/\/$//g;
    $command="$niceLoc $exeBlastpFil $dirSwissSplit < $fileOutLoc > $fileOutFilLoc ";
    $msg.="--- $sbr '$command'\n";

    $Lok=
	&run_program("$command" ,"$fhTraceLoc","warn");
    if (!$Lok){
	return(0,"*** ERROR $sbr '$Lok'\n"."after $exeBlastpFil (returned 0)\n");}
    if (! -e $fileOutFilLoc){
	return(0,"*** ERROR $sbr after $exeBlastpFil no output '$fileOutFilLoc'\n");}
    return(1,"ok $sbr");
}				# end of blastpRun

#===============================================================================
sub blastpRunSimple {
    local($fileInLoc,$fileOutLoc,$exeBlastpLoc,$dbBlastLoc,$parELoc,$parBLoc,
	  $fileOutScreenLoc,$fhSbrErr) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   blastpRunSimple             simply runs BLASTP (blast2)
#                               NOTE: for security call &blastSetenv before running
#       in:                     $fileInLoc     : FASTA formatted input file
#       in:                     $fileOutLoc    : BLASTP output                if = 0: onto screen
#       in:                     $exeBlastLoc   : FORTRAN exe BLASTP           if = 0: default
#       in:                     $dbBlastLoc    : BLASTP db to run             if = 0: swiss
#       in:                     $parELoc       : BLASTP para E                if = 0: default
#       in:                     $parBLoc       : BLASTP para B                if = 0: default
#       in:                     $fileOutScreen : screen dumpb of system call  if = 0: 0 -> STDOUT
#       in:                     $fhSbrErr      : error file handle
#       out:                    1|0,msg,  implicit: file
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."blastpRunSimple";$fhinLoc="FHIN_"."blastpRunSimple";
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
    return(&errSbr("miss in file '$fileInLoc'!"))  if (! -e $fileInLoc);
                                # ------------------------------
				# local defaults
    $exeBlastpLocDef=           "/home/rost/pub/molbio/blastp.$ARCH";
    $dbBlastLocDef=             "swiss";
    $parELocDef=             1000;
    $parBLocDef=             2000;
                                # ------------------------------
				# check arguments
    $fileOutLoc=0               if (! defined $fileOutLoc);
    $exeBlastpLoc=$exeBlastpLocDef  if (! defined $exeBlastpLoc || ! $exeBlastpLoc);
    $dbBlastLoc=$dbBlastLocDef  if (! defined $dbBlastLoc || ! $dbBlastLoc);
    $parELoc=$parELocDef        if (! defined $parELoc    || ! $parELoc);
    $parBLoc=$parBLocDef        if (! defined $parBLoc    || ! $parBLoc);

    $fhSbrErr="STDOUT"          if (! defined $fhSbrErr   || ! $fhSbrErr);
    $fileOutScreenLoc=0         if (! defined $fileOutScreenLoc || 
				    ! $fileOutScreenLoc   ||
				    ! $fileOutLoc);

    $cmdSys="";
				# ------------------------------
				# run BLAST
				# ------------------------------
                                    
    $cmd= $exeBlastpLoc." ".$dbBlastLoc." ".$fileInLoc." E=$parELoc B=$parBLoc";
    $cmd.=" >> $fileOutLoc"     if ($fileOutLoc);

    eval "\$cmdSys=\"$cmd\"";
    ($Lok,$msg)=
	&sysRunProg($cmdSys,$fileOutScreenLoc,$fhSbrErr);
    return(&errSbrMsg("failed to run BLASTP on ($fileInLoc)",$msg)) 
	if (! $Lok || ($fileOutLoc && ! -e $fileOutLoc));

    return(1,"ok $sbrName");
}				# end of blastpRunSimple

#===============================================================================
sub blastpFormatdb {
    local($fileInLoc,$titleLoc,$exeFormatdbLoc,$fileOutScreenLoc,$fhSbrErr) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   blastpFormatdb              formats a db for BLASTP (blast 2)
#                               NOTE: automatically sets environment !!!
#       in:                     $fileInLoc     : FASTAmul formatted db file
#       in:                     $fileOutLoc    : BLASTP output                if = 0: onto screen
#       in:                     $exeBlastLoc   : FORTRAN exe BLASTP           if = 0: default
#       in:                     $fileOutScreen : screen dumpb of system call  if = 0: 0 -> STDOUT
#       in:                     $fhSbrErr      : error file handle
#       out:                    1|0,msg,$title : name of formatted db
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."blastpFormatdb";$fhinLoc="FHIN_"."blastpFormatdb";
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
    return(&errSbr("miss in file '$fileInLoc'!"))  if (! -e $fileInLoc);
                                # ------------------------------
				# local defaults
    $exeFormatdbLocDef=         "/home/rost/pub/molbio/setdb.$ARCH";
                                # ------------------------------
				# check arguments
    $titleLoc=0                 if (! defined $titleLoc);
    $exeFormatdbLoc=$exeFormatdbLocDef 
                                if (! defined $exeFormatdbLoc || ! $exeFormatdbLoc);

    $fhSbrErr="STDOUT"          if (! defined $fhSbrErr || ! $fhSbrErr);
    $fileOutScreenLoc=0         if (! defined $fileOutScreenLoc || ! $fileOutScreenLoc);

    $cmdSys="";
				# ------------------------------
				# title and setenv BLASTDB
    if (! $titleLoc)     {	# ------------------------------
	$titleLoc=$fileInLoc;
	$titleLoc=~s/^.*\///g;}
    $tmp=$fileInLoc; $tmp=~s/^(.*)\/.*$/$1/g;
    if (length($tmp)<1 && defined $ENV{'PWD'})  { 
	$tmp=$ENV{'PWD'};}
    if (length($tmp) > 1){
	$tmp=~s/\/$//g;
	system("setenv BLASTDB $tmp");}
				# ------------------------------
				# run setdb (for BLASTP)
				# ------------------------------

                                # syntax 'formatdb.SGI32 -t TITLE DIR/fasta-file'
                                # note:  files will be created in DIR !
    $cmd= $exeFormatdbLoc." -t $titleLoc -i ".$fileInLoc;
    $cmd.=" >> $fileOutScreenLoc"     if ($fileOutScreenLoc);

    eval "\$cmdSys=\"$cmd\"";
    ($Lok,$msg)=
	&sysRunProg($cmdSys,$fileOutScreenLoc,$fhSbrErr);
    return(&errSbrMsg("failed to run FORMATDB on ($fileInLoc)",$msg)) 
        if (! $Lok || ($fileOutLoc && ! -e $fileOutLoc));

    return(1,"ok $sbrName",$titleLoc);
}				# end of blastpFormatdb

#===============================================================================
sub blastSetenv {
    local($BLASTMATloc,$BLASTDBloc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   blastSetenv                 sets environment for BLASTP runs
#       in:                     $BLASTMAT,$BLASTDB (or default)
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."blastSetenv";$fhinLoc="FHIN_"."blastSetenv";
				# defaults
    $BLASTMATdef="/home/rost/oub/molbio/blast/blastapp/matrix";
    $BLASTDBdef= "/home/rost/pub/molbio/db";
				# check arguments
    $BLASTMATloc=$BLASTMATdef   if (! defined $BLASTMATloc);
    $BLASTDBloc=$BLASTDBdef     if (! defined $BLASTDBloc);
				# existence
    if (! -d $BLASTMATloc && ($BLASTMATloc ne $BLASTMATdef)){
	print "-*- WARN $sbrName: changed env BLASTMAT from $BLASTMATloc to $BLASTMATdef\n" x 5;
	$BLASTMATloc=$BLASTMATdef; }
    if (! -d $BLASTDBloc  && ($BLASTDBloc ne $BLASTDBdef)){
	print "-*- WARN $sbrName: changed env BLASTDB from $BLASTDBloc to $BLASTDBdef\n" x 5;
	$BLASTDBloc=$BLASTDBdef; }
    return(&errSbr("BLASTMAT $BLASTMATloc not existing")) if (! -d $BLASTMATloc);
    return(&errSbr("BLASTDB  $BLASTDBloc not existing"))  if (! -d $BLASTDBloc);
				# ------------------------------
				# set env
#    system("setenv BLASTMAT $BLASTMATloc"); # system call
    $ENV{'BLASTMAT'}=$BLASTMATloc;

#    system("setenv BLASTDB $BLASTDBloc"); # system call
    $ENV{'BLASTDB'}=$BLASTDBloc;

    return(1,"ok $sbrName");
}				# end of blastSetenv

#===============================================================================
sub blastWrtSummary {
    local($fileOutLoc,%tmp) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   blastWrtSummary             writes summary for blast results (%ide,len,distance HSSP)
#       in:                     $fileOutLoc   (if = 0, written to STDOUT)
#       in:                     $tmp{} :
#                    HEADER:
#                               $tmp{"para","expect"}='para1,para2' 
#                               $tmp{"para","paraN"}   : value for parameter paraN
#                               $tmp{"form","paraN"}   : output format for paraN (default '%-s')
#                    DATA gen:
#                               $tmp{"NROWS"}        : number of proteins (it1)
#                               
#                               $tmp{$it1}             : number of pairs for it1
#                               $tmp{"id",$it1}        : name of protein it1
#                    DATA rows:
#                               $tmp{$it1,"id",$it2}   : name of protein it2 aligned to it1
#                               $tmp{$it1,"len",$it2}  : length of protein it2
#                               $tmp{$it1,"lali",$it2} : alignment length for it1/it2
#                               $tmp{$it1,"pide",$it2} : perc sequence identity for it1/it2
#                               $tmp{$it1,"dist",$it2} : distance from HSSP-curve for it1/it2
#                               $tmp{$it1,"prob",$it2} : BLAST prob for it1/it2
#                               $tmp{$it1,"score",$it2}: BLAST score for it1/it2
#                               
#                               $tmp{"form",$kwd}    : perl format for keyword $kwd
#                               $tmp{"sep"}            : separator for output columns
#                               
#       out:                    1|0,msg,  implicit: file
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."blastWrtSummary";$fhoutLoc="FHOUT_"."blastWrtSummary";
				# ------------------------------
				# defaults
				# ------------------------------
    $form{"id"}=   "%-15s";
    $form{"len"}=  "%5d";
    $form{"lali"}= "%4d";
    $form{"pide"}= "%5.1f";
    $form{"dist"}= "%5.1f";
    $form{"prob"}= "%6.3f";
    $form{"score"}="%5.1f";
    $sepLoc="\t";
    $sepLoc=$tmp{"sep"}         if (defined $tmp{"sep"});
				# ------------------------------
				# what do we have?
				# ------------------------------
    $#kwdtmp=0;
    push(@kwdtmp,"id")          if (defined $tmp{"1","id","1"});
    push(@kwdtmp,"len")         if (defined $tmp{"1","len","1"});
    push(@kwdtmp,"lali")        if (defined $tmp{"1","lali","1"});
    push(@kwdtmp,"pide")        if (defined $tmp{"1","pide","1"});
    push(@kwdtmp,"dist")        if (defined $tmp{"1","dist","1"});
    push(@kwdtmp,"prob")        if (defined $tmp{"1","prob","1"});
    push(@kwdtmp,"score")       if (defined $tmp{"1","score","1"});
				# ------------------------------
                                # format defaults
                                # ------------------------------
    foreach $kwd (@kwdtmp){
        $form{"$kwd"}=$tmp{"form","$kwd"} if (defined $tmp{"form","$kwd"}); }

				# ------------------------------
				# header defaults
				# ------------------------------
    $tmp2{"nota","id1"}=        "guide sequence";
    $tmp2{"nota","id2"}=        "aligned sequence";
    $tmp2{"nota","len"}=        "length of aligned sequence";
    $tmp2{"nota","lali"}=       "alignment length";
    $tmp2{"nota","pide"}=       "percentage sequence identity";
    $tmp2{"nota","dist"}=       "distance from new HSSP curve";
    $tmp2{"nota","prob"}=       "BLAST probability";
    $tmp2{"nota","score"}=      "BLAST raw score";

    $tmp2{"nota","expect"}="";
    foreach $kwd (@kwdtmp) {
        $tmp2{"nota","expect"}.="$kwd,";}
    $tmp2{"nota","expect"}=~s/,*$//g;

    $tmp2{"para","expect"}= "";
    $tmp2{"para","expect"}.=$tmp{"para","expect"}  if (defined $tmp{"para","expect"});
    foreach $kwd (split(/,/,$tmp2{"para","expect"})){	# import
	$tmp2{"para","$kwd"}=$tmp{"para","$kwd"};}
    $tmp2{"para","expect"}.=",PROTEINS";
    $tmp2{"para","PROTEINS"}=""; $tmp2{"form","PROTEINS"}="%-s";
    foreach $it1 (1..$tmp{"NROWS"}) {
        $tmp2{"para","PROTEINS"}.=$tmp{"id","$it1"}.",";}
    $tmp2{"para","PROTEINS"}=~s/,*$//g;
                                # --------------------------------------------------
                                # now write it
                                # --------------------------------------------------
    
				# open file
    if (! $fileOutLoc || $fileOutLoc eq "STDOUT"){
	$fhoutLoc="STDOUT";}
    else { &open_file("$fhoutLoc",">$fileOutLoc") || 
               return(&errSbr("fileOutLoc=$fileOutLoc, not created")); }
	    
				# ------------------------------
				# write header
				# ------------------------------
    if ($fhoutLoc ne "STDOUT"){
        ($Lok,$msg)=
	    &rdbGenWrtHdr($fhoutLoc,%tmp2);
	return(&errSbrMsg("failed writing RDB header (lib-br:rdbGenWrtHdr)",$msg)) if (! $Lok); }
    undef %tmp2;                # slim-is-in!

				# ------------------------------
				# write names
				# ------------------------------

    $formid=$form{"id"};
    $fin=""; $form=$formid;   $form=~s/(\d+)\.*\d*[dfs].*/$1/;$form.="s";
    $fin.= sprintf ("$form$sepLoc","id1"); 
    foreach $kwd (@kwdtmp) {$form=$form{"$kwd"}; 
			    $form=~s/(\d+)\.*\d*[dfs].*/$1/;$form.="s";
			    $kwd2=$kwd;
			    $kwd2="id2" if ($kwd eq "id");
                            $fin.= sprintf ("$form$sepLoc",$kwd2); }
    $fin=~s/$sepLoc$//;
    print $fhoutLoc "$fin\n";
				# ------------------------------
                                # write data
				# ------------------------------
    foreach $it1 (1..$tmp{"NROWS"}){
        $fin1=         sprintf ( "$formid$sepLoc",$tmp{"id","$it1"}) 
	    if (defined $tmp{"id","$it1"});

				# none above threshold
        if (! defined $tmp{"$it1"} || $tmp{"$it1"} == 0) {
	    $fin=$fin1;
	    $fin.=     sprintf ("$formid$sepLoc","none"); 
            foreach $kwd (@kwdtmp) { 
		next if ($kwd eq $kwdtmp[1]);
                $form=$form{"$kwd"}; $form=~s/(\.\d+)[FND]$|d$//gi;$form.="s";
                $fin.= sprintf ("$form$sepLoc",""); }
	    print $fhoutLoc $fin,"\n";
	    next;}
				# loop over all above
	foreach $it2 (1..$tmp{"$it1"}){
	    $fin=$fin1;
            $Lerror=0;
            foreach $kwd (@kwdtmp) { 
                if (! defined $tmp{"$it1","$kwd","$it2"}) {
                    $Lerror=1;
                    last; }
                $form=$form{"$kwd"};
                $fin.= sprintf ("$form$sepLoc",$tmp{"$it1","$kwd","$it2"}); }
            next if ($Lerror);
            $fin=~s/$sepLoc$//;
            print $fhoutLoc $fin,"\n";}}

    close($fhoutLoc)            if ($fhoutLoc ne "STDOUT");
    undef %form; undef %tmp;    # slim-is-in!
    return(1,"ok $sbrName");
}				# end of blastWrtSummary

#===============================================================================
sub brIniErr {
    local($local)=@_;
    $[ =1 ;
#-------------------------------------------------------------------------------
#   brIniErr                    error check for initial parameters
#       in GLOBAL:              $par{},@ARGV
#       in:                     $exceptions = 'kwd1,kwd2'
#                                  key words not to check for file existence
#       out:                    ($Lok,$msg)
#-------------------------------------------------------------------------------
    $sbrName="$scrName:"."brIniErr";
    @kwd= keys (%par)       if (defined %par && %par);
				# ------------------------------
    undef %tmp; $#excl=0;	# exclude some keyword from check?
    @excl=split(/,/,$local) if (defined $local);
    if ($#excl>0){
	foreach $kwd(@excl){
	    $tmp{"$kwd"}=1;}}
    $msgHere="";
				# ------------------------------
    foreach $kwd (@kwd){	# file existence
	next if ($kwd =~ /^file(Out|Help|Def)/i);
	next if (defined $tmp{"$kwd"});
	if   ($kwd=~/^exe/) { 
	    $msgHere.="*** ERROR executable ($kwd) '".$par{"$kwd"}."' missing!\n"
		if (! -e $par{"$kwd"} && ! -l $par{"$kwd"});
	    $msgHere.="*** ERROR executable ($kwd) '".$par{"$kwd"}."' not executable!\n".
                "***       do the following \t 'chmod +x ".$par{"$kwd"}."'\n"
                    if (! -x $par{"$kwd"});}
	elsif($kwd=~/^file/){
	    next if ($par{"$kwd"} eq "unk" || length($par{"$kwd"})==0 || !$par{"$kwd"});
	    $msgHere.="*** ERROR file ($kwd) '".$par{"$kwd"}."' missing!\n"
		if (! -e $par{"$kwd"} && ! -l $par{"$kwd"});} # 
    }
    return(0,$msgHere) if ($msgHere=~/ERROR/);
    return(1,"ok $sbrName");
}				# end of brIniErr

#===============================================================================
sub brIniGetArg {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   brIniGetArg                 standard reading of command line arguments
#       in GLOBAL:              @ARGV,$defaults{},$par{}
#       out GLOBAL:             $par{},@fileIn
#       out:                    @arg_not_understood (i.e. returns 0 if everything ok!)
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."brIniGetArg";
    $#argUnk=0;                 # ------------------------------
				# (1) get input directory
    foreach $arg(@ARGV){	# search in command line
	if ($arg=~/^dirIn=(.+)$/){$par{"dirIn"}=$1;
				  last;}}
				# search in defaults
    if ((! defined $par{"dirIn"} || ! -d $par{"dirIn"}) && defined %defaults && %defaults){ # 
	if (defined $defaults{"dirIn"}){
	    $par{"dirIn"}=$defaults{"dirIn"};
	    $par{"dirIn"}=$PWD    
		if (defined $PWD && ($par{"dirIn"}=~/^(local|unk)$/ || length($par{"dirIn"})==0));}}
    $par{"dirIn"}.="/" if (defined $par{"dirIn"} && -d $par{"dirIn"} && $par{"dirIn"}!~/\/$/); #  slash
    $par{"dirIn"}=""   if (! defined $par{"dirIn"} || ! -d $par{"dirIn"}); # empty
                                # ------------------------------
    if (defined %par && %par){  # all keywords used in script
        @tmp=sort keys (%par);}
    else{
	$#tmp=0;}

    $Lverb3=0 if (! defined $Lverb3);
    $Lverb2=0 if (! defined $Lverb2);
    $#fileIn=0;                 # ------------------------------
    foreach $arg (@ARGV){	# (2) key word driven input
	if    ($arg=~/^verb\w*3=(\d)/)          {$par{"verb3"}=$Lverb3=$1;}
	elsif ($arg=~/^verb\w*3/)               {$par{"verb3"}=$Lverb3=1;}
	elsif ($arg=~/^verb\w*2=(\d)/)          {$par{"verb2"}=$Lverb2=$1;}
	elsif ($arg=~/^verb\w*2/)               {$par{"verb2"}=$Lverb2=1;}
	elsif ($arg=~/^verbose=(\d)/)           {$par{"verbose"}=$Lverb=$1;}
	elsif ($arg=~/^verbose/)                {$par{"verbose"}=$Lverb=1;}
	elsif ($arg=~/not_?([vV]er|[sS]creen)/) {$par{"verbose"}=$Lverb=0; }
	else  {$Lok=0;		# general
               if (-e $arg && ! -d $arg){ # is it file?
                   $Lok=1;push(@fileIn,$arg);}
               if (! $Lok && length($par{"dirIn"})>1 && -e $par{"dirIn"}.$arg){
                   $Lok=1;push(@fileIn,$par{"dirIn"}.$arg);}
               if (! $Lok){
                   foreach $kwd (@tmp){
                       if ($arg=~/^$kwd=(.+)$/){$Lok=1;$par{"$kwd"}=$1;
                                                last;}}}
               push(@argUnk,$arg) if (! $Lok);}}
    return(@argUnk);
}				# end of brIniGetArg

#===============================================================================
sub brIniHelp {
    local(%tmp)=@_;
    $[ =1 ;
#-------------------------------------------------------------------------------
#   brIniHelp                   initialise help text
#       out:                    \d,txt
#       err:                    0,$msg  -> error
#       err:                    1,'fin' -> wanted help, given help
#       err:                    1,$msg  -> continue, was just trying
#       in:                     $tmp{} with
#                               $tmp{sourceFile}=  name and path of calling script
#                               $tmp{scrName}=     name of calling script (no .pl)
#                               $tmp{scrIn}=       input arguments for script
#                               $tmp{scrGoal}=     what script does
#                               $tmp{scrNarg}=     number of argument needed for script
#                               $tmp{scrHelpTxt}=  long blabla about script
#                                   separate by '\n'
#                               $tmp{scrAddHelp}=  help option other than standard
#                                   e.g.: "help xyz     : explain .xyz "
#                                   many: '\n' separated
#                                   NOTE: this will be an entry to $tmp{$special},
#                                   -> $special =  'help xyz' will give explanation 
#                                      $tmp{$special}
#                               $tmp{special}=     'kwd1,kwd2,...' special keywords
#                               $tmp{$special}=    explanation for $special
#                                   syntax: print flat lines (or '--- $line'), separate by '\n'
#                               $tmp{scrHelpHints}= hints (tab separated)
#                               $tmp{scrHelpProblems}= known problems (tab separated)
#       in GLOBULAR:            @ARGV
#                               $par{fileHelpOpt}
#                               $par{fileHelpMan}
#                               $par{fileHelpHints}
#                               $par{fileHelpProblems}
#                               $par{fileDefautlts}
#       in unk:                 leave undefined, or give value = 'unk'
#-------------------------------------------------------------------------------
    $sbrName="lib-br:brIniHelp"; 
				# ------------------------------
				# check input
    if (0){
	foreach $kwd ("sourceFile","scrName","scrIn","scrGoal","scrNarg","scrAddHelp","special"){
	    print "--- input to $sbrName kwd=$kwd, val=",$tmp{"$kwd"},",\n";}
    }
    @scrTask=
        ("--- Task:  ".$tmp{"scrGoal"},
         "--- ",
         "--- Input: ".$tmp{"scrIn"},
         "---                 i.e. requires at least ".$tmp{"scrNarg"}.
	      " command line argument(s)",
         "--- ");
				# ------------------------------
				# additional help keywords?
				# ------------------------------
    $#tmpAdd=0;
    if (defined $tmp{"scrAddHelp"} && $tmp{"scrAddHelp"} ne "unk"){
	@tmp=split(/\n/,$tmp{"scrAddHelp"});$Lerr=0;
	foreach $tmp(@tmp){
	    push(@tmpAdd,$tmp{"scrName"}.".pl ".$tmp);
	    $tmp2=$tmp;$tmp2=~s/^(.+)\s+\:.*$/$1/;$tmp2=~s/\s*$//g;
	    if (!defined $tmp{"$tmp2"}){
		$Lerr=1;
		print "-*- WARN $sbrName: miss \$tmp{\$special}  for '$tmp2'\n";}}
	if ($Lerr){
	    print  
		"-*- " x 20,"\n","-*- WARN $sbrName: HELP on HELP\n",
		"-*-      if you provide special help in tmp{scrAddHelp}, then\n",
		"-*-      provide also the respective explanation in tmp{\$special},\n",
		"-*-      where \$special is e.g. 'help xyz' in \n",
		"-*-      scrAddHelp='help xyz : what to do'\n","-*- " x 20,"\n";}}
				# ------------------------------
				# build up help standard
				# ------------------------------
    @scrHelp=
	("--- Help:  For further information on input options type:",
	 "--- "." " x length($tmp{"scrName"}).
	 "              ........................................");
    @scrHelpLoop=
	($tmp{"scrName"}.".pl help          : lists all options",
	 $tmp{"scrName"}.".pl def           : writes default settings",
	 $tmp{"scrName"}.".pl def keyword   : settings for keyword",
	 $tmp{"scrName"}.".pl help keyword  : explain key, how for 'how' and 'howie'");
    push(@scrHelpLoop,
	 $tmp{"scrName"}.".pl problems      : known problems") 
	if (! defined $tmp{"s_k_i_p"} || $tmp{"s_k_i_p"} !~ /problems/);
    push(@scrHelpLoop,
	 $tmp{"scrName"}.".pl hints         : hints for users")
	if (! defined $tmp{"s_k_i_p"} || $tmp{"s_k_i_p"} !~ /hints/);
    push(@scrHelpLoop,
	 $tmp{"scrName"}.".pl manual        : will cat the entire manual (... MAY be it will)")
	if (! defined $tmp{"s_k_i_p"} || $tmp{"s_k_i_p"} !~ /manual/);
    push(@scrHelpLoop,@tmpAdd) if ($#tmpAdd>0);

    push(@scrHelp,@scrHelpLoop,
	 "--- "." " x length($tmp{"scrName"}).
	        "              ........................................");
				# ------------------------------
				# no input
				# ------------------------------
    if ($#ARGV < 1) {
	print "-" x 80, "\n"; print "--- Perl script $scrName.pl (",$tmp{"sourceFile"},")\n"; 
	foreach $txt (@scrTask) {print "$txt\n";}
	if (defined $tmp{"scrHelpTxt"}){@tmp=split(/\n/,$tmp{"scrHelpTxt"});
					foreach $txt (@tmp){
					    print "--- $txt\n";}}
	foreach $txt (@scrHelp) {
	    print "$txt\n";} 
	return(1,"fin");}
				# ------------------------------
				# help request
				# ------------------------------
    elsif ($#ARGV<2 && $ARGV[1] =~ /^(help|man|-m|-h)$/){
	print "-" x 80, "\n"; print "--- Perl script $scrName.pl (",$tmp{"sourceFile"},")\n"; 
	foreach $txt (@scrTask) {
	    print "$txt\n";}
	if (defined $tmp{"scrHelpTxt"}) {
	    @tmp=split(/\n/,$tmp{"scrHelpTxt"});
	    foreach $txt (@tmp){
		print "--- $txt\n";}}
	if (defined $tmp{"special"}) {
	    @kwdLoc=split(/,/,$tmp{"special"});
	    if ($#kwdLoc>1){
		print "-" x 80,"\n","---    'special' keywords:\n";
		foreach $kwd(@kwdLoc){$tmp=" "; $tmp=$tmp{"$kwd"} if (defined $tmp{"$kwd"});
				      printf "---   %-15s %-s\n",$kwd,$tmp;}}}
        if (defined %par) {
	    @kwdLoc=sort keys (%par);
	    if ($#kwdLoc>1){
		print 
		    "-" x 80,"\n",
		    "---    Syntax used to set parameters by command line:\n",
		    "---       'keyword=value'\n",
		    "---    where 'keyword' is one of the following keywords:\n";
		$ct=0;print "OPT \t ";
		foreach $kwd(@kwdLoc){++$ct;
				      printf "%-20s ",$kwd;
				      if ($ct==4){$ct=0;print "\nOPT \t ";}}print "\n";}
            print 
                "--- \n",
                "---    you may (or may not) get further explanations on a particular keyword\n",
                "---    by typing:\n",
                $tmp{"scrName"}.".pl help keyword\n",
                "---    this could explain the key.  Type 'how' for info on 'how,howie,show'.\n",
                "--- \n";}
        else { print "--- no other options enabled by \%par\n";}
	return(1,"fin loop?");}
				# ------------------------------
				# wants manual
				# ------------------------------
    elsif ($#ARGV<2  && $ARGV[1] eq "manual"){
	print "-" x 80, "\n"; print "--- Perl script $scrName.pl (",$tmp{"sourceFile"},")\n"; 
	if (defined $par{"fileHelpMan"} &&  -e $par{"fileHelpMan"}){
	    open("FHIN",$par{"fileHelpOpt"}) || 
		warn "*** $sbrName: could NOT open file".$par{"fileHelpOpt"};
	    while(<FHIN>){print $_;}close(FHIN);}
	else {
	    print "no manual in \%par{'fileHelpMan'}!!\n";}
	return(1,"fin");}
				# ------------------------------
				# wants hints
				# ------------------------------
    elsif ($#ARGV==1  && $ARGV[1] eq "hints"){
	print "-" x 80, "\n"; print "--- Perl script $scrName.pl (",$tmp{"sourceFile"},")\n"; 
	print "--- Hints for users:\n";$ct=0;
	if (defined $par{"fileHelpHints"} && -e $par{"fileHelpHints"}){
	    open("FHIN",$par{"fileHelpHints"}) || 
		warn "*** $sbrName: could NOT open file".$par{"fileHelpHints"};
	    while(<FHIN>){
		print $_; ++$ct;}close(FHIN);}
	if (defined $par{"scrHelpHints"}){
	    @tmp=split(/\n/,$par{"scrHelpHints"});
	    foreach $txt(@tmp){print "--- $txt\n";++$ct;}}
	if ($ct==0){
	    print "--- the only hint to give: try another help option!\n";
            print "---                        sorry ...\n";}
	return(1,"fin loop?");}
				# ------------------------------
				# wants problems
				# ------------------------------
    elsif ($#ARGV<2  && $ARGV[1] eq "problems"){
	print "-" x 80, "\n"; print "--- Perl script $scrName.pl (",$tmp{"sourceFile"},")\n"; 
	print "--- Known problems with script:\n";$ct=0;
	if (defined $par{"fileHelpProblems"} && -e $par{"fileHelpProblems"}){
	    open("FHIN",$par{"fileHelpProblems"}) || 
		warn "*** $sbrName: could NOT open file".$par{"fileHelpProblems"};
	    while(<FHIN>){
		print $_; ++$ct;}close(FHIN);}
	if (defined $par{"scrHelpProblems"}){
	    @tmp=split(/\n/,$par{"scrHelpProblems"});
	    foreach $txt(@tmp){print "--- $txt\n";++$ct;}}
	if ($ct==0){
	    print "--- One problem is: there is no problem annotated.\n";
            print "---                 sorry ...\n";}
	return(1,"fin loop?");}
				# ------------------------------
				# wants default settings
				# ------------------------------
    elsif ($#ARGV<2 && $ARGV[1] eq "def"){
	print "-" x 80, "\n"; print "--- Perl script $scrName.pl (",$tmp{"sourceFile"},")\n"; 
        if (defined %par){
            @kwdLoc=sort keys (%par);
            if ($#kwdLoc>1){
                print  "---    the default settings are:\n";
                printf "--- %-20s   %-s\n","." x 20,"." x 20;
                printf "--- %-20s = %-s\n","keyword","value";
                printf "--- %-20s   %-s\n","." x 20,"." x 20;
                foreach $kwd(@kwdLoc){
                    printf "--- %-20s = %-s\n",$kwd,$par{"$kwd"};}
                printf "--- %-20s   %-s\n","." x 20,"." x 20;
                print 
                    "--- \n",
                    "---    to get settings for particular keywords use:\n",
                    $scrName,".pl def keyword'\n \n";}}
        else { print "--- no setting defined in \%par\n";
	       print "---                       sorry...\n";}
	return(1,"fin loop?");}
				# ------------------------------
				# help for particular keyword
				# ------------------------------
    elsif ($#ARGV>=2 && $ARGV[1] eq "help"){
	print "-" x 80, "\n"; print "--- Perl script $scrName.pl (",$tmp{"sourceFile"},")\n"; 
	$kwdHelp=$ARGV[2]; 
	$tmp="help $kwdHelp";	# special?
	$tmp=~tr/[A-Z]/[a-z]/;	# make special keywords case independent 
        $tmp2=$tmp;$tmp2=~s/help //;
	$tmpSpecial=$tmp{"$tmp"}  if (defined $tmp{"$tmp"});
	$tmpSpecial=$tmp{"$tmp2"} if (! defined $tmp{"$tmp"} && defined $tmp{"$tmp2"});

        $#kwdLoc=$#expLoc=0;    # (1) get all respective keywords
        if (defined %par && $kwdHelp ne "special"){
            @kwdLoc=keys (%par);$#tmp=0;
            foreach $kwd (@kwdLoc){
                push(@tmp,$kwd) if ($kwd =~/$kwdHelp/i);}
            @kwdLoc=sort @tmp;}
                                # (2) is there a 'help option file' ?
        if (defined $par{"fileHelpOpt"} && -e $par{"fileHelpOpt"} && 
	    $kwdHelp ne "special"){
	    print 
		"-" x 80,"\n",
		"---    Syntax used to set parameters by command line:\n",
		"---       'keyword=value'\n",
		"---    where 'keyword' is one of the following keywords:\n";
	    open("FHIN",$par{"fileHelpOpt"}) || 
		warn "*** $sbrName: could NOT open file".$par{"fileHelpOpt"};
	    while(<FHIN>){
		next if ($_=~/^\#/);
		$line=$_;
		$tmp=$_;$tmp=~s/\s//g;
		next if (length($tmp)<2);
		next if ($_=~/^\s/ && ! $Lok);	   
		if    ($Lok && $_=~/^\s/){
		    print $_;
		    next;}
		elsif ($Lok && $_!~/^\s/){
		    $Lok=0;}
		if (! $Lok && $_ !~ /^[\s\t]+/){
		    $line=$_;
		    ($tmp1,$tmp2)=split(/[\s\t]+/,$_);
		    $Lok=1 if (length($tmp1)>1 && $tmp1 =~ /$kwdHelp/i);
		    print $line if ($Lok);}}close(FHIN);
	    print "-" x 80, "\n";}
                                # (3) is there a default file?
        elsif (defined $par{"fileDefaults"} && -e $par{"fileDefaults"} &&
	    $kwdHelp ne "special"){
	    ($Lok,$msg,%def)=&brIniRdDef($par{"fileDefaults"});
	    $def{"kwd"}="" if (! $Lok); # hack: short cut error
	    @kwdLoc=split(/,/,$def{"kwd"});$#tmp=0;
	    foreach $kwd (@kwdLoc){
		if ($kwd =~/$kwdHelp/i){
		    push(@tmp,$kwd); 
		    if (defined $def{"$kwd","expl"}){
			$def{"$kwd","expl"}=~s/\n/\n---                        /g;
			push(@expLoc,$def{"$kwd","expl"});}
		    else {push(@expLoc," ");}}}
	    @kwdLoc=@tmp;}
				# (4) else: read itself
        elsif ($kwdHelp ne "special"){
            ($Lok,$msg,%def)=
		&brIniHelpRdItself($tmp{"sourceFile"});
            die '.....   verrry sorry the option blew up ... ' if (! $Lok);
	    $def{"kwd"}="" if (! $Lok); # hack: short cut error
            @kwdLoc=split(/,/,$def{"kwd"});$#tmp=0;
            foreach $kwd (@kwdLoc){
                if ($kwd =~/$kwdHelp/i){
                    push(@tmp,$kwd); 
                    if (defined $def{"$kwd"}){
                        $def{"$kwd"}=~s/\n[\t\s]*/\n---                        /g;
                        push(@expLoc,$def{"$kwd"});}
                    else {push(@expLoc," ");}}}
            @kwdLoc=@tmp;}
	$Lerr=1;
        if ($#kwdLoc>0){        # (4) write the stuff
            printf "--- %-20s   %-s\n","." x 20,"." x 53;
            printf "--- %-20s   %-s\n","keyword","explanation";
            printf "--- %-20s   %-s\n","." x 20,"." x 53;
            foreach $it(1..$#kwdLoc){
                $tmp=" "; $tmp=$expLoc[$it] if (defined $expLoc[$it]);
                printf "--- %-20s   %-s\n",$kwdLoc[$it],$tmp;}
            printf "--- %-20s   %-s\n","." x 20,"." x 53;
            print "--- \n";$Lerr=0;}

				# (5) special help?
	if (defined $tmpSpecial){
            print  "---    Special help for '$kwdHelp':\n";
            foreach $txt (split(/\n/,$tmpSpecial)) { 
		print "--- $txt\n";}
	    $Lerr=0;}
	if ($kwdHelp eq "special" && defined $tmp{"special"}) {
	    @kwdLoc=split(/,/,$tmp{"special"});
	    if ($#kwdLoc>1){
		print "-" x 80,"\n","---    'special' keywords:\n";
		foreach $kwd(@kwdLoc){$tmp=" "; $tmp=$tmp{"$kwd"} if (defined $tmp{"$kwd"});
				      printf "---   %-15s %-s\n",$kwd,$tmp;}
		$Lerr=0;}}
	print "--- sorry, no explanations found for keyword '$kwdHelp'\n" if ($Lerr);
	return(1,"fin loop?");}
				# ------------------------------
				# wants settings for keyword
				# ------------------------------
    elsif ($#ARGV>=2  && $ARGV[1] eq "def"){
	$kwdHelp=$ARGV[2];
	print "-" x 80, "\n"; print "--- Perl script $scrName.pl (",$tmp{"sourceFile"},")\n"; 
        if (defined %par){
            @kwdLoc=sort keys (%par);
            if ($#kwdLoc>1){
                print  "---    the default settings are:\n";
                printf "--- %-20s   %-s\n","." x 20,"." x 53;
                printf "--- %-20s = %-s\n","keyword","value";
                printf "--- %-20s   %-s\n","." x 20,"." x 53;
                foreach $kwd(@kwdLoc){
                    next if ($kwd !~ /$kwdHelp/);
                    printf "--- %-20s = %-s\n",$kwd,$par{"$kwd"};}
                printf "--- %-20s   %-s\n","." x 20,"." x 53;
                print  " \n";}}
	else { print "--- sorry, no setting defined in \%par\n";}
	return(1,"fin loop?");}

    return(1,"ok $sbrName");
}				# end of brIniHelp

#===============================================================================
sub brIniHelpLoop {
    local($promptLoc,%tmp)=@_;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   brIniHelpLoop               loop over help 
#       in/out:                 see brIniHelp
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."brIniHelpLoop";$fhinLoc="FHIN_"."brIniHelpLoop";

    ($Lok,$msg)=		# want help?
	&brIniHelp(%tmp);       
                                return(&errSbrMsg("after brIniHelp",$msg)) if (! $Lok);
				# ------------------------------
				# loop over help
				# ------------------------------
    if ($msg =~ /^fin loop/) {
	$#tmp=0;
	foreach $txt (@scrHelpLoop) { $txt=~s/^.*\.pl\s*//g;
				      push(@tmp,$txt); }
	@scrHelpLoop2=@tmp;
	
	$Lquit=0; 
	$def="help"; 
	while (! $Lquit) {
	    printf "%-s %-s\n",      $promptLoc,"-" x (79 - length($promptLoc));
	    printf "%-s %-15s %-s\n",$promptLoc,"",              "Interactive help";
	    printf "%-s %-15s %-s\n",$promptLoc,"OPTIONS","";
	    foreach $txt (@scrHelpLoop2) { 
		printf "%-s %-15s %-s\n",$promptLoc," ",$txt; }
	    printf "%-s %-15s %-s\n",$promptLoc,"","";
	    printf "%-s %-15s %-s\n",$promptLoc,"ABBREVIATIONS", "h=help, d=def (e.g. 'h kwd')";
	    printf "%-s %-15s %-s\n",$promptLoc,"ENOUGH ?",      "[quit|q|e|exit] to end";

	    $def="$ARGV[1]"     if (defined $def);   # take previous
		
	    $ansr=
		&get_in_keyboard("type",$def,$promptLoc);

				# <--- QUIT
	    $tmp=$ansr;$tmp=~s/\s//g;
	    if ($ansr=~/^[q|quit|e|exit]$/) { 
		$Lquit=1; 
		last; }
				# redefine @ARGV
	    @ARGV=split(/\s+/,$ansr);
	    $ARGV[1]="help"     if ($ARGV[1] eq "h" || $ARGV[1] eq "H");
	    $ARGV[1]="def"      if ($ARGV[1] eq "d" || $ARGV[1] eq "D");

	    $txt1="start again with(";
	    $txt2=join(' ',@ARGV);
	    $lenfin=80 - 6 - (length($txt1) + length($txt2));
	    print "--- ","-" x length($txt1),"#" x length($txt2),"--", "-" x $lenfin,"\n";
	    print "--- ",$txt1,$txt2,")\n";
	    print "--- ","-" x length($txt1),"#" x length($txt2),"--", "-" x $lenfin,"\n";

				# call again
	    ($Lok,$msg)=
		&brIniHelp(%tmp); return(&errSbrMsg("after brIniHelp",$msg)) if (! $Lok);
				# <--- QUIT
	    $Lquit=1            if ($msg eq "fin");
	} 
	$msg="fin";
    }
    return(1,$msg);
}				# end of brIniHelpLoop

#===============================================================================
sub brIniHelpRdItself {
    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   brIniHelpRdItself           reads the calling perl script (scrName),
#                               searches for 'sub\siniDef', and gets comment lines
#       in:                     perl-script-source
#       out:                    (Lok,$msg,%tmp), with:
#                               $tmp{"kwd"}   = 'kwd1,kwd2'
#                               $tmp{"$kwd1"} = explanations for keyword 1
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."brIniHelpRdItself";$fhinLoc="FHIN_"."brIniHelpRdItself";

    $Lok=       &open_file("$fhinLoc","$fileInLoc");
    return(0,"*** ERROR $sbrName: old '$fileInLoc' not opened\n") if (! $Lok);
                                # read file
    while (<$fhinLoc>) {        # search for initialising subroutine
        last if ($_=/^su[b] iniDef.* \{/);}
    $Lis=0;undef %tmp; $#tmp=0;
    while (<$fhinLoc>) {        # read lines with '   %par{"kwd"}= $val  # comment '
        $_=~s/\n//g;
        last if ($_=~/^su[b] .*\{/ && $_!~/^su[b] iniDef.* \{/);
        if    ($_=~/[\s\t]+\$par\{[\"\']?([^\"\'\}]+)[\"\']?\}[^\#]* \# (.*)$/){
            $Lis=1;$kwd=$1; push(@tmp,$kwd);$tmp{"$kwd"}=$2 if (defined $2);}
        elsif ($Lis && defined $tmp{"$kwd"} && $_=~/^[\s\t]+\# ?\-+/){
            $Lis=0;}
        elsif ($Lis && defined $tmp{"$kwd"} && $_=~/^[\s\t]*\# (.*)$/){
            $tmp{"$kwd"}.="\n".$1;}
        elsif ($Lis){
            $Lis=0;}}close($fhinLoc);
    $tmp{"kwd"}=join(',',@tmp);
    return(1,"ok $sbrName",%tmp);
}				# end of brIniHelpRdItself

#===============================================================================
sub brIniRdDef {
    local ($fileLoc)=@_;
    $[ =1 ;
#-------------------------------------------------------------------------------
#   brIniRdDef                  reads defaults for initialsing parameters
#       in GLOBAL:              $par{},@ARGV
#       out GLOBAL:             $par{} (i.e. changes settings automatically)
#       in:                     file_default
#       out:                    ($Lok,$msg,%defaults) with:
#                               $defaults{"kwd"}=         'kwd1,kwd2,...,'
#                               $defaults{"$kwd1"}=       val1
#                               $defaults{"$kwd1","expl"}=explanation for kwd1
#                               note: long explanations split by '\n'
#-------------------------------------------------------------------------------
    $sbrName="lib-br:brIniRdDef"; $fhin="FHIN_brIniRdDef";

    &open_file("$fhin","$fileLoc") ||
	return(0,"*** ERROR $sbrName: failed to open in '$fileLoc'\n");

    undef %defaults; $#kwd=0; $Lis=0;
				# ------------------------------
    while (<$fhin>){		# read file
	next if (length($_)<3 || $_=~/^\#/ || $_!~/\t/); # ignore lines beginning with '#'
	$_=~s/\n//g;
	$line=$_;
	$tmp=$line; $tmp=~s/[\s\#\-\*\.\=\t]//g;
	next if (length($tmp)<1); # ignore lines with only spaces or '-|#|*|='
	$line=~s/^[\s\t]*|[\s\t]*$//g; # purge leading blanks and tabs
				# ------------------------------
				# (1) case 'kwd  val  # comment'
	if    ($line=~/^([^\s\t]+)[\s\t]+([^\s\t]+)[\s\t]+\# ?(.*)$/){
	    $kwd=$1; push(@kwd,$kwd); $defaults{"$kwd"}=$2; 
            $defaults{"$kwd","expl"}=$3 if (defined $3 && length($3)>1); $Lis=1;}
				# (2) case 'kwd  val'
	elsif ($line=~/^([^\s\t]+)[\s\t]+([^\s\t]+)[\s\t]*$/){
	    $kwd=$1; $defaults{"$kwd"}=$2; $Lis=1; $defaults{"$kwd","expl"}=""; }
				# (3) case '          # ----'
	elsif ($Lis && $line =~ /^\#\s*[\-\=\_\.\*]+/){
	    $Lis=0;}
	elsif ($Lis && defined $defaults{"$kwd","expl"} && $line =~ /^\#\s*(.*)$/){
	    $defaults{"$kwd","expl"}.="\n".$1;}}
    close($fhin);
				# ------------------------------
    foreach $kwd (@kwd){        # fill in wild cards
        $defaults{"$kwd"}=$ARCH if ($defaults{"$kwd"}=~/ARCH/);}
                                # ------------------------------
    foreach $kwd (@kwd){        # complete it
	$defaults{"$kwd","expl"}=" " if (! defined $defaults{"$kwd","expl"});}
    $defaults{"kwd"}=join(',',@kwd);
				# ------------------------------
				# check the defaults read
				# AND OVERWRITE $par{} !!
    @kwdDef=keys %par; foreach $kwd (@kwdDef){ $tmp{$kwd}=1;}
    $Lok=1;
    foreach $kwd (@kwd){
	if (! defined $tmp{$kwd}){
	    $Lok=0;
	    print 
		"*** ERROR $sbrName: wrong keyword ($kwd) in defaults file ",$par{"fileDefaults"},"\n";}
				# ******************************
	else {			# overwrite
				# ******************************
	    $par{"$kwd"}=$defaults{"$kwd"};}}
    return(0,"*** ERROR $sbrName failed finishing to read defaults file\n");

    return(1,"ok $sbrName",%defaults);
}				# end of brIniRdDef

#===============================================================================
sub brIniRdDefWhere {
    local($scrName,$sourceFileLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   brIniRdDefWhere             searches for a default file
#       in:                     $scrName = 'script' , $sourceName = 'dir/script.pl'
#       out:                    name of default file, or 0
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."brIniRdDefWhere";$fhinLoc="FHIN"."$sbrName";

    foreach $_(@ARGV){		# default file given on command line?
	if ($_=~/^fileDefaults=(.+)$/){
	    $fileDefaultsLoc=$1;
	    return(0,"*** ERROR $sbrName: default file '",$fileDefaultsLoc,"' missing\n") 
		if (! -e $fileDefaultsLoc);
	    last;}}
    return($fileDefaultsLoc) if (defined $fileDefaultsLoc && -e $fileDefaultsLoc);
				# search in local dir
    $fileDefaultsLoc=$scrName.".defaults" if (defined $scrName);
    return($fileDefaultsLoc) if (defined $fileDefaultsLoc && -e $fileDefaultsLoc);
				# search in original dir
    if (defined $sourceFileLoc){
	$tmp=$sourceFileLoc;$tmp=~s/\.pl//g;
	$fileDefaultsLoc=$tmp.".defaults"; } # script dir
    return($fileDefaultsLoc) if (defined $fileDefaultsLoc && -e $fileDefaultsLoc);
				# any other idea where to search??
    return(0);
}				# end of brIniRdDefWhere

#===============================================================================
sub brIniSet {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   brIniSet                    changing parameters according to input arguments
#                               e.g. adding directories to file names asf
#-------------------------------------------------------------------------------
    $sbrName="lib-br:brIniSet";
    @kwd=sort keys(%par) if (defined %par && %par);
				# ------------------------------
    $#tmp=0;			# purge empty keywords
    foreach $kwd (@kwd){
        if (defined $kwd && length($kwd)>=1 && defined $par{"$kwd"}){
            push(@tmp,$kwd);}
	else { print "-*- WARN $sbrName: for kwd '$kwd', par{kwd} not defined!\n";}}
    @kwd=@tmp;
				# jobId
    $par{"jobid"}=$$ 
	if (! defined $par{"jobid"} || $par{"jobid"} eq 'jobid' || length($par{"jobid"})<1);
				# ------------------------------
				# add jobid
    foreach $kwd (@kwd){
	$par{"$kwd"}=~s/jobid/$par{"jobid"}/;}
                                # ------------------------------
                                # WATCH it for file lists: add dirIn
    if (defined $par{"dirIn"} && $par{"dirIn"} ne "unk" && $par{"dirIn"} ne "local" 
        && length($par{"dirIn"})>1){
	foreach $fileIn(@fileIn){
	    $fileIn=$par{"dirIn"}.$fileIn if (! -e $fileIn);
	    if (! -e $fileIn){ print "*** $sbrName: no fileIn=$fileIn, dir=",$par{"dirIn"},",\n";
			       return(0);}}} 
    $#kwdFileOut=0;		# ------------------------------
    foreach $kwd (@kwd){	# add 'pre' 'title' 'ext' to output files not specified
	next if ($kwd !~ /^fileOut/);
	push(@kwdFileOut,$kwd);
	next if (defined $par{"$kwd"} && $par{"$kwd"} ne "unk" && length($par{"$kwd"})>0);
	$kwdPre=$kwd; $kwdPre=~s/file/pre/;  $kwdExt=$kwd; $kwdExt=~s/file/ext/; 
	$pre="";$pre=$par{"$kwdPre"} if (defined $par{"$kwdPre"});
	$ext="";$ext=$par{"$kwdExt"} if (defined $par{"$kwdExt"});
	if (! defined $par{"title"} || $par{"title"} eq "unk"){
	    $par{"title"}=$scrName;$par{"title"}=~tr/[a-z]/[A-Z]/;} # capitalize title
	$par{"$kwd"}=$pre.$par{"title"}.$ext;}
				# ------------------------------
				# add output directory
    if (defined $par{"dirOut"} && $par{"dirOut"} ne "unk" && $par{"dirOut"} ne "local" 
        && length($par{"dirOut"})>1){
	if (! -d $par{"dirOut"}){ # make directory
	    print "--- $sbrName mkdir ",$par{"dirOut"},"\n" if ($par{"verb2"});
            $tmp=$par{"dirOut"};$tmp=~s/\/$// if ($tmp=~/\/$/);
	    $Lok= mkdir ($tmp,umask);
	    print "*** $sbrName failed making directory '",$par{"dirOut"},"'\n" if (! $Lok);}
	$par{"dirOut"}.="/" if (-d $par{"dirOut"} && $par{"dirOut"} !~/\/$/); # add slash
	foreach $kwd (@kwdFileOut){
	    next if ($par{"$kwd"} =~ /^$par{"dirOut"}/);
	    $par{"$kwd"}=$par{"dirOut"}.$par{"$kwd"} if (-d $par{"dirOut"});}}
				# ------------------------------
				# push array of output files
    $#fileOut=0 if (! defined @fileOut);
    foreach $kwd (@kwdFileOut){
	push(@fileOut,$par{"$kwd"});}
				# ------------------------------
				# temporary files: add work dir
    if (defined $par{"dirWork"} && $par{"dirWork"} ne "unk" && $par{"dirWork"} ne "local" 
	&& length($par{"dirWork"})>1) {
	if (! -d $par{"dirWork"}){ # make directory
	    print "--- $sbrName mkdir ",$par{"dirWork"},"\n" if ($par{"verb2"});
            $tmp=$par{"dirWork"};$tmp=~s/\/$// if ($tmp=~/\/$/);
	    $Lok= mkdir ($tmp,umask);
	    print "*** $sbrName failed making directory '",$par{"dirWork"},"'\n" if (! $Lok);}
	$par{"dirWork"}.="/" if (-d $par{"dirWork"} && $par{"dirWork"} !~/\/$/); # add slash
	foreach $kwd (@kwd){
	    next if ($kwd !~ /^file/);
	    next if ($kwd =~ /^file(In|Out|Help|Def)/i);
            $par{"$kwd"}=~s/jobid/$par{"jobid"}/ ;
	    next if ($par{"$kwd"} =~ /^$par{"dirWork"}/);
	    $par{"$kwd"}=$par{"dirWork"}.$par{"$kwd"};}}
				# ------------------------------
				# blabla
    $Lverb=1  if (defined $par{"verbose"} && $par{"verbose"});
    $Lverb2=1 if (defined $par{"verb2"}   && $par{"verb2"});
    $Lverb3=1 if (defined $par{"verb3"}   && $par{"verb3"});
				# ------------------------------
				# add ARCH
    if (defined $ARCH || defined $par{"ARCH"}){
	$ARCH=$par{"ARCH"}      if (! defined $ARCH &&   defined $par{"ARCH"});
	$par{"ARCH"}=$ARCH      if (  defined $ARCH && ! defined $par{"ARCH"});
	foreach $kwd (@kwd){	# add directory to executables
	    next if ($kwd !~ /^exe/);
	    next if ($par{"$kwd"} !~ /ARCH/);
	    $par{"$kwd"}=~s/ARCH/$ARCH/;}}

				# ------------------------------
    foreach $kwd (@kwd){	# add directory to executables
	next if ($kwd !~/^exe/);
	next if (-e $par{"$kwd"} || -l $par{"$kwd"});
				# try to add perl script directory
	next if (! defined $par{"dirPerl"} || ! -d $par{"dirPerl"});
	next if ($par{"$kwd"}=~/$par{"dirPerl"}/); # did already, no result
	$tmp=$par{"dirPerl"}; $tmp.="/" if ($tmp !~ /\/$/);
	$tmp=$tmp.$par{"$kwd"};
	next if (! -e $tmp && ! -l $tmp);
	$par{"$kwd"}=$tmp; }

				# ------------------------------
				# priority
    if (defined $par{"optNice"} && $par{"optNice"} ne " " && length($par{"optNice"})>0){
	$niceNum="";
	if    ($par{"optNice"}=~/nice\s*-/){
	    $par{"optNice"}=~s/nice-/nice -/;
	    $niceNum=$par{"optNice"};$niceNum=~s/\s|nice|\-|\+//g; }
	elsif ($par{"optNice"}=~/^\d+$/){
	    $niceNum=$par{"optNice"};}
	$niceNum=~s/\D//g;
	setpriority(0,0,$niceNum) if (length($niceNum)>0); }

    return(1);
}				# end of brIniSet

#===============================================================================
sub brIniWrt {
    local($exclLoc,$fhTraceLocSbr)=@_;
    $[ =1 ;
#-------------------------------------------------------------------------------
#   brIniWrt                    write initial settings on screen
#       in:                     $excl     : 'kwd1,kwd2,kw*' exclude from writing
#                                            '*' for wild card
#       in:                     $fhTrace  : file handle to write
#                                  = 0, or undefined -> STDOUT
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."brIniWrt";
    
    return(0,"*** $sbrName: no settings defined in %par\n") if (! defined %par || ! %par);
    $fhTraceLocSbr="STDOUT"    if (! defined $fhTraceLocSbr || ! $fhTraceLocSbr);

    print $fhTraceLocSbr "--- ","-" x 80, "\n";
    print $fhTraceLocSbr "--- Initial settings for $scrName ($0) on $Date:\n";
    @kwd= sort keys (%par);
				# ------------------------------
				# to exclude
    @tmp= split(/,/,$exclLoc)   if (defined $exclLoc);
    $#exclLoc=0; undef %exclLoc;
    foreach $tmp (@tmp) {
	if   ($tmp !~ /\*/) {	# exact match
	    $exclLoc{"$tmp"}=1; }
	else {			# wild card
	    $tmp=~s/\*//g;
	    push(@exclLoc,$tmp); } }
    if ($#exclLoc > 0) {
	$exclLoc2=join('|',@exclLoc); }
    else {
	$exclLoc2=0; }
	
    
	    
    $#kwd2=0;			# ------------------------------
    foreach $kwd (@kwd) {	# parameters
	next if (! defined $par{"$kwd"});
	next if ($kwd=~/expl$/);
	next if (length($par{"$kwd"})<1);
	if ($kwd =~/^fileOut/) {
	    push(@kwd2,$kwd);
	    next;}
	next if ($par{"$kwd"} eq "unk");
	next if (defined $exclLoc{"$kwd"}); # exclusion required
	next if ($exclLoc2 && $kwd =~ /$exclLoc2/);
	printf $fhTraceLocSbr "--- %-20s '%-s'\n",$kwd,$par{"$kwd"};}
				# ------------------------------
    if ($#kwd2>0){		# output files
	print $fhTraceLocSbr "--- \n","--- Output files:\n";
	foreach $kwd (@kwd2) {
	    next if ($par{"$kwd"} eq "unk"|| ! $par{"$kwd"});
	    next if (defined $exclLoc{"$kwd"}); # exclusion required
	    next if ($exclLoc2 && $kwd =~ /$exclLoc2/);
	    printf $fhTraceLocSbr "--- %-20s '%-s'\n",$kwd,$par{"$kwd"};}}
				# ------------------------------
				# input files
    if    (defined @fileIn && $#fileIn>1){
				# get dirs
	$#tmpdir=0; undef %tmpdir;
	foreach $file (@fileIn){
	    if ($file =~ /^(.*\/)[^\/]/){
		$tmp=$1;$tmp=~s/\/$//g;
		if (! defined $tmpdir{$tmp}){push(@tmpdir,$tmp);
					     $tmpdir{$tmp}=1;}}}
				# write
	print  $fhTraceLocSbr "--- \n";
	printf $fhTraceLocSbr "--- %-20s number =%6d\n","Input files:",$#fileIn;
	printf $fhTraceLocSbr "--- %-20s dirs   =%-s\n","Input dir:", join(',',@tmpdir) 
	    if ($#tmpdir == 1);
	printf $fhTraceLocSbr "--- %-20s dirs   =%-s\n","Input dirs:",join(',',@tmpdir) 
	    if ($#tmpdir > 1);
	for ($it=1;$it<=$#fileIn;$it+=5){
	    print $fhTraceLocSbr "--- IN: "; 
	    $it2=$it; 
	    while ( $it2 <= $#fileIn && $it2 < ($it+5) ){
		$tmp=$fileIn[$it2]; $tmp=~s/^.*\///g;
		printf $fhTraceLocSbr "%-18s ",$tmp;++$it2;}
	    print $fhTraceLocSbr "\n";}}
    elsif ((defined @fileIn && $#fileIn==1) || (defined $fileIn && -e $fileIn)){
	$tmp=0;
	$tmp=$fileIn    if (defined $fileIn && $fileIn);
	$tmp=$fileIn[1] if (! $tmp && defined @fileIn && $#fileIn==1);
	print $fhTraceLocSbr "--- \n";printf $fhTraceLocSbr "--- %-20s '%-s'\n","Input file:",$tmp;}
    print  $fhTraceLocSbr "--- \n";
    printf $fhTraceLocSbr "--- %-20s %-s\n","excluded from write:",$exclLoc 
	if (defined $exclLoc);
    print  $fhTraceLocSbr "--- \n","--- ","-" x 80, "\n","--- \n";
	
    return(1,"ok $sbrName");
}				# end of brIniWrt

#===============================================================================
sub bynumber { 
#-------------------------------------------------------------------------------
#   bynumber                    function sorting list by number
#-------------------------------------------------------------------------------
    $a<=>$b; 
}				# end of bynumber

#===============================================================================
sub bynumber_high2low { 
#-------------------------------------------------------------------------------
#   bynumber_high2low           function sorting list by number (start with high)
#-------------------------------------------------------------------------------
    $b<=>$a; 
}				# end of bynumber_high2low

#===============================================================================
sub checkMsfFormat {
    local ($fileMsf) = @_;
    local ($format,$tmp,$kw_msf,$kw_check,$ali_sec,$ali_des_sec,$valid_id_len,$fhLoc,
	   $uniq_id, $same_nb, $same_len, $nb_al, $seq_tmp, $seql, $ali_des_len);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   checkMsfFormat              basic checking of msf file format
#           - mandatory keywords and values (MSF: val, Check: val)
#           - alignment description start after "..", each line with the following structure:
#             Name: id Len: val Check: val Weight: val (and all ids diferents)
#           - alignment same number of line for each id (>0)
#       in:                     $fileMsf
#       out:                    return 1  if format seems OK, 0 else
#--------------------------------------------------------------------------------
    $sbrNameLoc="lib-br:checkMsfFormat";
                                # ----------------------------------------
                                # initialise the flags
                                # ----------------------------------------
    $fhLoc="FHIN_CHECK_MSF_FORMAT";
    $kw_msf=$kw_check=$ali_sec=$ali_des_sec=$ali_des_seq=$nb_al=0;
    $format=1;
    $valid_id_len=1;		# sequence name < 15 characters
    $uniq_id=1;			# id must be unique
    $same_nb=1;			# each seq must appear the same numb of time
    $same_len=1;		# each seq must have the same len
                                # ----------------------------------------
                                # read the file
                                # ----------------------------------------
    open ($fhLoc,$fileMsf)  || 
	return(0,"*** $sbrNameLoc cannot open fileMsf=$fileMsf\n");
    while (<$fhLoc>) {
	$_=~s/\n//g;
	$tmp=$_;$tmp=~ tr/a-z/A-Z/;
                                # MSF keyword and value
	$kw_msf=1    if (!$ali_des_seq && ($tmp =~ /MSF:\s*\d*\s/));
	next if (!$kw_msf);
                         	# CHECK keyword and value
	$kw_check=1  if (!$ali_des_seq && ($tmp =~ /CHECK:\s*\d*/));
	next if (!$kw_check);
                         	# begin of the alignment description section 
                         	# the line with MSF and CHECK must end with ".."
	if (!$ali_sec && $tmp =~ /MSF:\D*(\d*).*CHECK:.*\.\.\s*$/) {
	    $ali_des_len=$1;$ali_des_sec=1;}
                                # ------------------------------
                         	# the alignment description section
	if (!$ali_sec && $ali_des_sec) { 
            if ($tmp=~ /^\s*NAME:\s*(\S*).*LEN:.*\d.*CHECK:.*\d.*WEIGHT:.*\d.*/) {
		$id=$1;
		if (length($id) > 14) {	# is sequence name <= 14
		    $valid_id_len=0;}
		if ($SEQID{$id}) { # is the sequence unique?
		    $uniq_id=0;
		    last; }
		$SEQID{$id}= 1; # store seq ID
		$SEQL{$id}= 0;	# initialise seq len array
	    } }
                                # ------------------------------
                        	# begin of the alignment section
	$ali_sec=1    if ($ali_des_sec && $tmp =~ /\/\/\s*$/);
                                # ------------------------------
                        	# the alignment section
	if ($ali_sec) {
	    if ($tmp =~ /^\s*(\S+)\s+(.*)$/) {
		$id= $1;
		if ($SEQID{$id}) {++$SEQID{$id};
				  $seq_tmp= $2;$seq_tmp=~ s/\s|\n//g;
				  $seql= length($seq_tmp);
				  $SEQL{$id} += $seql; }}}
    }close($fhLoc);
                                # ----------------------------------------
                                # test if all sequences are present the 
				# same number of time with the same length
                                # ----------------------------------------
    foreach $id (keys %SEQID) {
	if (!$nb_al) {
	    $nb_al= $SEQID{$id};}
	if ($SEQID{$id} < 2 || $SEQID{$id} != $nb_al) {
	    $same_nb=0;
	    last; }}
				# TEST ALL THE FLAGS
    $msg="";
    $msg.="*** $sbrNameLoc ERROR: wrong MSF no keyword MSF\n"        if (!$kw_msf);
    $msg.="*** $sbrNameLoc ERROR: wrong MSF no keyword Check\n"      if (!$kw_check);
    $msg.="*** $sbrNameLoc ERROR: wrong MSF no ali descr section\n"  if (!$ali_des_sec);
    $msg.="*** $sbrNameLoc ERROR: wrong MSF no ali section\n"        if (!$ali_sec); 
    $msg.="*** $sbrNameLoc ERROR: wrong MSF id not unique\n"         if (!$uniq_id); 
    $msg.="*** $sbrNameLoc ERROR: wrong MSF seq name too long\n"     if (!$valid_id_len);
    $msg.="*** $sbrNameLoc ERROR: wrong MSF varying Nsequences\n"    if (!$same_nb);
    $msg.="*** $sbrNameLoc ERROR: wrong MSF varying length of seq\n" if (!$same_len);
    if (length($msg)>1){
	return(0,$msg);}
    return(1,"$sbrNameLoc ok");
}				# end checkMsfFormat

#===============================================================================
sub coilsRd {
    local($fileInLoc,$fileOutLoc,$probMinLoc,$fhErrSbr) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   coilsRd                     reads the column format of coils
#       in:                     $fileInLoc,$fileOutLoc,$probMinLoc,$fhErrSbr
#         $fileInLoc            file with COILS output (column format expected)
#         $probMinLoc           minimal probability (otherwise returns '2,$msg')
#       out:                    fileOut
#       err:                    (0,$err), (1,'ok '), (2,'info...') -> not Coils
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."coilsRd";$fhinLoc="FHOUT"."$sbrName";$fhoutLoc="FHOUT"."$sbrName";
				# ------------------------------
				# open COILS output
    $Lok=       &open_file("$fhinLoc","$fileInLoc");
    return(0,"*** ERROR $sbrName: '$fileInLoc' not opened\n") if (! $Lok);

    $seq=$win[1]=$win[2]=$win[3]="";
    $max[1]=$max[2]=$max[3]=0;
#    $sum[1]=$sum[2]=$sum[3]=0;
    $ptr[1]=14;$ptr[2]=21;$ptr[3]=28;
    while (<$fhinLoc>) {
	last if ($_=~/^\s*[\.]+/);}
    while (<$fhinLoc>) {
	$_=~s/\n//g;$_=~s/^\s*|\s*$//g; # 
	@tmp=split(/\s+/,$_);
	next if ($#tmp<11);
	$seq.="$tmp[2]";
#	$sum[1]+=$tmp[5]; $sum[2]+=$tmp[8];  $sum[3]+=$tmp[11];  
	$win[1].="$tmp[5],";  $max[1]=$tmp[5]  if ($tmp[5]> $max[1]);
	$win[2].="$tmp[8],";  $max[2]=$tmp[8]  if ($tmp[8]> $max[2]);
	$win[3].="$tmp[11],"; $max[3]=$tmp[11] if ($tmp[11]>$max[3]);
    }close($fhinLoc);
				# ------------------------------
				# none above threshold
    return (2,"maxProb ($ptr[1]=$max[1], $ptr[2]=$max[2], $ptr[3]=$max[3]) < $probMinLoc")
	if ( ($max[1]<$probMinLoc) && ($max[1]<$probMinLoc) && ($max[3]<$probMinLoc) );
				# ------------------------------
				# find ma
    ($max,$pos)=&get_max($max[1],$max[2],$max[3]);
    foreach $itw (1..3){
	@tmp=split(/,/,$win[$itw]);
	return(0,"*** ERROR $sbrName: couldnt read coils format $fileInLoc\n")
	    if ($#tmp>length($seq));
	$val[$itw]="";
	foreach $it(1..$#tmp){	# prob to 0-9
	    $tmp=int(10*$tmp[$it]); $tmp=9 if ($tmp>9);$tmp=0 if ($tmp<0);
	    $val[$itw].="$tmp";}}
				# ------------------------------
				# write new output file
    $Lok=       &open_file("$fhoutLoc",">$fileOutLoc");
    return(0,"*** ERROR $sbrName: new '$fileOutLoc' not opened\n") if (! $Lok);
    print $fhoutLoc  "\n";
    print $fhoutLoc  "--- COILS HEADER: SUMMARY\n";
    print $fhoutLoc  "--- best window has width of $ptr[$pos]\n";
    print $fhoutLoc  "--- \n";
    print $fhoutLoc  "--- COILS: SYMBOLS AND EXPLANATIONS ABBREVIATIONS\n";
    printf $fhoutLoc "--- %-12s : %-s\n","seq","one-letter amino acid sequence";
    printf $fhoutLoc 
	"--- %-12s : %-s\n","normWin14","window=14, normalised prob [0-9], 9=high, 0=low";
    printf $fhoutLoc 
	"--- %-12s : %-s\n","normWin21","window=21, normalised prob [0-9], 9=high, 0=low";
    printf $fhoutLoc 
	"--- %-12s : %-s\n","normWin28","window=28, normalised prob [0-9], 9=high, 0=low";
    print $fhoutLoc "--- \n";
    for ($it=1;$it<=length($seq);$it+=50){
	printf $fhoutLoc "COILS %-10s %-s\n","   ",  &myprt_npoints(50,$it);
	printf $fhoutLoc "COILS %-10s %-s\n","seq",  substr($seq,$it,50);
	foreach $itw(1..3){
	    printf $fhoutLoc
		"COILS %-10s %-s\n","normWin".$ptr[$itw],substr($val[$itw],$it,50);}}
    close($fhoutLoc);
    return(1,"ok $sbrName");
}				# end of coilsRd

#===============================================================================
sub coilsRun {
    local($fileInLoc,$fileOutLoc,$exeCoilsLoc,$metricLoc,$optOutLoc,$fhErrSbr) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   coilsRun                    runs the COILS program from Andrei Lupas
#       in:                     $fileIn,$exeCoils,$metric,$optOut,$fileOut,$fhErrSbr
#       in:                     NOTE if not defined arg , or arg=" ", then defaults
#       out:                    write into file (0,$err), (1,'ok ')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."coilsRun";$fhinLoc="FHIN"."$sbrName";

    return(0,"*** $sbrName: not def fileInLoc!")      if (! defined $fileInLoc);
    return(0,"*** $sbrName: not def fileOutLoc!")     if (! defined $fileOutLoc);
    return(0,"*** $sbrName: not def exeCoilsLoc!")    if (! defined $exeCoilsLoc);
    return(0,"*** $sbrName: not def metricLoc!")      if (! defined $metricLoc);
    return(0,"*** $sbrName: not def optOutLoc!")      if (! defined $optOutLoc);
    $fhErrSbr="STDOUT"                                if (! defined $fhErrSbr);

    return(0,"*** $sbrName: no in file $fileInLoc")   if (! -e $fileInLoc);
    $exeCoilsLoc="/home/phd/bin/".$ARCH."/coils"      if (! -e $exeCoilsLoc && defined $ARCH);
    $exeCoilsLoc="/home/phd/bin/SGI64/coils"          if (! -e $exeCoilsLoc && ! defined $ARCH); # HARD_CODED
    return(0,"*** $sbrName: no in exe  $exeCoilsLoc") if (! -e $exeCoilsLoc);
    $metricLoc=  "MTK"                                if (! -e $metricLoc); # metric 1
#    $metricLoc=  "MTIDK"                              if (! -e $metricLoc); # metric 2
    $optOutLoc=  "col"                                if (! -e $optOutLoc);
#    $optOutLoc=  "row"                                if (! -e $optOutLoc);
#    $optOutLoc=  "row"                                if (! -e $optOutLoc);

				# metric
    if    ($metricLoc eq "MTK")  {$met="1";}
    elsif ($metricLoc eq "MTIDK"){$met="2";}
    else  {
	return(0,"*** ERROR $scrName metric=$metricLoc, must be 'MTK' or 'MTIDK' \n");}
				# output option
    if    ($optOutLoc eq "col")  {$opt="p";}
    elsif ($optOutLoc eq "row")  {$opt="a";}
    elsif ($optOutLoc =~/cut/)   {
	$opt="b";
	return(0,"-*- ERROR $scrName optOut=$optOut, not yet implemented\n");}
    elsif ($optOutLoc =~/win/)   {
	$opt="c";
	return(0,"-*- ERROR $scrName optOut=$optOut, not yet implemented\n");}
    else {
	return(0,"*** ERROR $scrName optOut=$optOut no known\n");}
    $an=                       "N"; # no weight for position a & d
    $an=                       "Y"; # weight for position a & d

    eval "\$cmd=\"$exeCoilsLoc,$fileInLoc,$fileOutLoc,$met,$an,$opt\"";

    $Lok=&run_program("$cmd","$fhErrSbr","warn"); 
    if (! $Lok || ! -e $fileOutLoc){
	return(0,"$sbrName failed to create $fileOutLoc");}
    return(1,"ok $sbrName");
}				# end of coilsRun

#===============================================================================
sub convert_acc {
    local ($aa,$acc,$char,$mode) = @_ ;
    local (@tmp1,@tmp2,@tmp,$it,$tmpacc,$valreturn);
#--------------------------------------------------------------------------------
#    convert_acc                converts accessibility (acc) to relative acc
#                               default output is just relative percentage (char = 'unk')
#         in:                   AA, (one letter symbol), acc (Angstroem),char (unk or:
#                    note:      output is relative percentage, default if char empty or='unk'
#                                    ============
#                               char='15:100_b:e' -> returns symbols 
#                                    ============
#                                    b for relacc <15, e for relacc>=15
#                                    ===============
#                               char='4:15:100_b:i:e' -> returns symbols 
#                                    ===============
#                                    b for relacc <4, i: 4<=relacc<15, e for relacc>=15
#         in:                   .... $mode:
#                               mode=''=default, '3ang', '5ang', '07ang' -> different water
#                                    radius, 'RS' then X=0
#         out:                  converted (with return)
#--------------------------------------------------------------------------------

    &exposure_normalise_prepare($mode) if (! %NORM_EXP);
				# default (3 states)
    if ( ! defined $char || $char eq "unk") {
	$valreturn=  &exposure_normalise($acc,$aa);}
				# optional e.g. char='15:100_b:e'
    elsif ($char =~ /\d:\d/) {
	if (! %NORM_EXP ){print "*** ERROR in convert_acc: NORM_EXP empty \n*** please,",
			  print "    do initialise with exposure_normalise_prepare\n";
			  exit;}
	$tmpacc= &exposure_normalise($acc,$aa);

	@tmp=split(/_/,$char);@tmp1=split(/:/,$tmp[1]);@tmp2=split(/:/,$tmp[2]);
	if   ($tmpacc<$tmp1[1])      {
	    $valreturn=$tmp2[1];}
	elsif($tmpacc>=$tmp1[$#tmp1-1]){
	    $valreturn=$tmp2[$#tmp1];}
	else { 
	    for ($it=2;$it<$#tmp1;++$it) {
		if ( ($tmpacc>=$tmp1[$it-1]) && ($tmpacc<$tmp1[$it+1]) ) {
		    $valreturn=$tmp2[$it]; 
		    last; }}} }
    else {print "*** ERROR calling convert_acc (lib-br) \n";
	  print "***       acc=$acc, aa=$aa, char passed (eg. 15:100_b:4)=$char, not ok\n";
	  exit;}
    $valreturn=100 if ($valreturn>100);	# saturation (shouldnt happen, should it?)
    return $valreturn;
}				# end of convert_acc

#===============================================================================
sub convert_sec {
    local ($sec,$char) = @_ ;
#--------------------------------------------------------------------------------
#    convert_sec                converts 8 DSSP secondary str. into 3 (H,E,L)= default 
#                               char=HL    -> H=H,I,G  L=rest
#                               char=HELB  -> H=H,I,G  E=E, B=B, L=rest
#                               char=HELT  -> H=H,I,G  E=E,B  T=T, L=rest
#                               char=HELBT -> H=H,I,G  E=E, B=B, T=T, L=rest
#         default =             HEL
#         in:                   structure to convert
#         out:                  converted (with return)
#--------------------------------------------------------------------------------
				# default (3 states)
    if ( !defined $char || length($char)==0 || $char eq "HEL" || ! $char) {
	return "H" if ($sec=~/[HIG]/);
	return "E" if ($sec=~/[EB]/);
	return "L";}
				# optional
    elsif ($char eq "HL")    { return "H" if ($sec=~/[HIG]/);
			       return "L";}
    elsif ($char eq "HELT")  { return "H" if ($sec=~/[HIG]/);
			       return "E" if ($sec=~/[EB]/);
			       return "T" if ($sec=~/[T]/);
			       return "L";}
    elsif ($char eq "HELB")  { return "H" if ($sec=~/HIG/);
			       return "E" if ($sec=~/[E]/);
			       return "B" if ($sec=~/[B]/);
			       return "L";}
    elsif ($char eq "HELBT") { return "H" if ($sec=~/[HIG]/);
			       return "E" if ($sec=~/[EB]/);
			       return "B" if ($sec=~/[E]/);
			       return "T" if ($sec=~/[T]/);
			       return "L";}
    else { print "*** ERROR calling convert_sec (lib-br), sec=$sec, or char=$char, not ok\n";
	   return(0);}
}				# end of convert_sec

#===============================================================================
sub convert_secFine {
    local ($sec,$char) = @_ ;
#--------------------------------------------------------------------------------
#    convert_secFine            takes an entire string ('HEL') and fine-tunes: ' EHH'-> '  HH'
#                               char=HL    -> H=H,I,G  L=rest
#                               char=HELB  -> H=H,I,G  E=E, B=B, L=rest
#                               char=HELT  -> H=H,I,G  E=E,B  T=T, L=rest
#                               char=HELBT -> H=H,I,G  E=E, B=B, T=T, L=rest
#         default =             HEL
#         in:                   structure-string to convert
#         out:                  (1|0,$msg,converted)
#--------------------------------------------------------------------------------
				# default
    $char="HEL"                 if (! defined $char || ! $char);
				# unused
    if    ($char eq "HL")     { $sec=~s/[IG]/H/g;  $sec=~s/[EBTS !]/L/g;
				return(1,"ok",$sec); }
    elsif ($char eq "HEL")    { $sec=~s/[IG]/H/g;  $sec=~s/[TS !]/L/g;
				$sec=~s/B/E/g;
				$sec=~s/LEH/LLH/g; $sec=~s/HEL/HLL/g; # <-- fine
				return(1,"ok",$sec); }
    elsif ($char eq "HELT")   { $sec=~s/[IG]/H/g;  $sec=~s/[S !]/L/g;
				$sec=~s/B/E/g;
				$sec=~s/LEH/LLH/g; $sec=~s/HEL/HLL/g; # <-- fine
				return(1,"ok",$sec); }
    elsif ($char eq "HELB")   { $sec=~s/[IG]/H/g;  $sec=~s/[TS !]/L/g;
				return(1,"ok",$sec); }
    elsif ($char eq "HELBT")  { $sec=~s/[IG]/H/g;  $sec=~s/[S !]/L/g;
				return(1,"ok",$sec); }
    else { 
	return(&errSbr("char=$char, not recognised\n",0)); }
}				# end of convert_secFine

#===============================================================================
sub convDssp2fasta {
    local($fileInLoc,$fileOutLoc,$fragLoc,$chainLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   convDssp2fasta              converts DSSP to FASTA format
#       in:                     $fileInLoc,$fileOutLoc,$fragLoc,$chainLoc
#       in:                     $fragLoc=n-m    fragment to extract (optional)
#                               = 0 for no action
#       in:                     $chainLoc=[A-Z0-9] chain to extract
#                               = "*" for all
#       out:                    implicit: file out
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."convDssp2fasta";$fhinLoc="FHIN_"."convDssp2fasta";
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc!")          if (! defined $fileInLoc);
    return(0,"*** $sbrName: not def fileOutLoc!")         if (! defined $fileOutLoc);
    $fragLoc=0                                            if (! defined $fragLoc);
    $chainLoc="*"                                         if (! defined $chainLoc);

    return(0,"*** $sbrName: miss in file '$fileInLoc'!")  if (! -e $fileInLoc);

                                # ------------------------------
    ($Lok,$id,$seq)=            # read DSSP
        &dsspRdSeq($fileInLoc,$chainLoc);
    return(0,"*** ERROR $sbrName: failed to read DSSP ($fileInLoc)\n".
             "***                 found id=$id\n") 
        if (! $Lok || length($seq)<1);

    undef %tmp;
    $tmp{"id","1"}= $id;
    $tmp{"seq","1"}=$seq;
    $tmp{"NROWS"}=1;
                                # ------------------------------
                                # extract?
    if ($fragLoc){($beg,$end)=split(/-/,$frag);
                  foreach $it (1..$tmp{"NROWS"}){
                      $tmp{"seq","$it"}=substr($tmp{"seq","$it"},$beg,($end-$beg+1));}}
                                # ------------------------------
                                # write output
    ($Lok,$msg)=
        &fastaWrtMul($fileOutLoc,%tmp);
    return(0,"*** ERROR $sbrName: failed to write FASTAmul ($fileOutLoc)\n".
           "***                 msg=$msg\n") if (! $Lok);
    return(2,"-*- WARN $sbrName: wrong number written\n$msg\n") if ($Lok != 1);
    return(1,"ok $sbrName");
}				# end of convDssp2fasta

#===============================================================================
sub convFasta2gcg {
    local($exeConvSeqLoc,$file_in_loc,$file_out_loc,$fhTraceLoc)=@_;
    local($outformat,$an,$commandLoc);
#----------------------------------------------------------------------
#   convFasta2gcg               convert fasta format to GCG format
#       in:                     $exeConvSeqLoc,$file_in_loc,$file_out_loc,$fhTraceLoc
#       out:                    
#       err:                    ok=(1,'ok'), err=(0,'msg')
#----------------------------------------------------------------------
    $sbrName="convFasta2gcg";
    return(0,"*** $sbrName: not def file_in_loc!")    if (! defined $file_in_loc);
    return(0,"*** $sbrName: not def file_out_loc!")   if (! defined $file_out_loc);
    return(0,"*** $sbrName: not def exeConvSeqLoc!")  if (! defined $exeConvSeqLoc);
    $fhTraceLoc="STDOUT"                                       if (! defined $fhTraceLoc);
				# check existence of files
    return(0,"*** $sbrName: no file '$file_in_loc'!")   if (! -e $file_in_loc);
    return(0,"*** $sbrName: no exe  '$exeConvSeqLoc'!") if (! -e $exeConvSeqLoc);
				# ------------------------------
				# call FORTRAN program
    $outformat=                 "G";
    $an=                        "N";
    eval "\$commandLoc=\"$exeConvSeqLoc,$file_in_loc,$outformat,$an,$file_out_loc,$an,\"";
    $Lok=
	&run_program("$commandLoc" ,"$fhTraceLoc","warn"); 
    if (! $Lok){
	return(0,"*** $sbrName: couldnt run_program cmd=$commandLoc\n");}
    return(1,"ok $sbrName");
}				# end of convFasta2gcg

#===============================================================================
sub convFastamul2many {
    local($fileInLoc,$fileOutLoc,$formOutLoc,$fragLoc,$extrLoc,$fhErrSbr) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   convFastamul2msf            converts FASTAmul into many formats: FASTA,MSF,PIR,SAF,PIRmul
#       in:                     $fileInLoc,$fileOutLoc,$formOutLoc,$fragLoc,$extrLoc,$fhErrSbr
#       in:                     $formOutLoc     format MSF|FASTA|PIR
#       in:                     $fragLoc=n-m    fragment to extract (optional)
#       in:                     $extrLoc=i,j,k  take only sequences i,j,k from PIRmul
#       in:                     NOTE: to leave blank =0, e.g. 
#       in:                           'file.fastamul,file.f,0,5' would get fifth sequence
#       out:                    implicit: file written
#       err:                    (1,'ok'), (0,'message')
#       err:                    e: (1,msg) -> ok
#       err:                    a: (0,msg) -> some arguments missing/files not opened
#       err:                    b: (2,msg) -> no output file written 
#       err:                    b: (3,msg) -> ERROR from msfCheckFormat
#   specification of format     see interpretSeqFastamul
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."convFastamul2msf";$fhinLoc="FHIN_"."convFastamul2msf";
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc!")          if (! defined $fileInLoc);
    return(0,"*** $sbrName: not def fileOutLoc!")         if (! defined $fileOutLoc);
    return(0,"*** $sbrName: not def formOutLoc!")         if (! defined $formOutLoc);
    $fragLoc=0                                            if (! defined $fragLoc);
    $extrLoc=0                                            if (! defined $extrLoc);
    return(0,"*** $sbrName: miss in file '$fileInLoc'!")  if (! -e $fileInLoc);
                                # interpret input
    $formOutLoc=~tr/[A-Z]/[a-z]/;
    if ($fragLoc){$fragLoc=~s/\s//g;
		  return(0,"*** $sbrName: syntax of fragLoc ($fragLoc) must be :\n".
			 "    'ifir-ilas', where ifir,ilas are integers (or 1-*)\n")
		      if ($fragLoc && $fragLoc !~/[\d\*]\-[\d\*]/);}
    if ($extrLoc){$extrLoc=~s/\s//g;
		  return(0,"*** $sbrName: syntax of extrLoc ($extrLoc) must be :\n".
			 "    'n1,n2,n3-n4', where n* are integers\n")
		      if ($extrLoc && $extrLoc =~/[^0-9\-,]/);
		  @extr=&get_range($extrLoc); 
                  undef %take;
                  foreach $it(@extr){
                      $take{$it}=1;}}
				# open file
    &open_file("$fhinLoc","$fileInLoc") ||
	return(0,"*** ERROR $sbrName: fileIn=$fileInLoc, not opened\n");

                                # ------------------------------
    undef %fasta; $ct=$#id=0;   # read file
    while (<$fhinLoc>) {
	$_=~s/\n//g;
        if ($_=~/^\s*\>(.*)$/){ # is id
            $name=$1;$name=~s/[\s\t]+/ /g; # purge too many blanks
            $name=~s/^\s*|\s*$//g; # purge leading blanks
            $id=$name;$id=~s/^(\S+).*$/$1/; # shorter identifier
            ++$ct;
            $id="$ct" if (length($id)<1);
            push(@id,$id);
            $fasta{"id","$ct"}=$name;$fasta{"seq","$ct"}="";}
        else {                  # is sequence
            $_=~s/\s|\t//g;
            $fasta{"seq","$ct"}.=$_;}}
				# ------------------------------
    undef %tmp; $ctTake=0;	# store names for passing variables
    foreach $it (1..$#id){ 
        next if ($extrLoc && (! defined $take{$it} || ! $take{$it}));
        ++$ctTake; 
        $tmp{"id","$ctTake"}= $fasta{"id","$ct"};
        $tmp{"seq","$ctTake"}=$fasta{"seq","$ct"};}
    $tmp{"NROWS"}=$ctTake;
    %fasta=%tmp; undef %tmp;
				# ------------------------------
				# select subsets
				# ------------------------------
    if ($fragLoc){
	($beg,$end)=split('-',$fragLoc);$len=length($fasta{"seq","1"});
	$beg=1 if ($beg eq "*"); $end=$len if ($end eq "*");
	if ($len< ($end-$beg+1)){
	    print "-*- WARN $sbrName: $beg-$end not possible, as length of protein=$len\n";}
	else {
	    foreach $it (1..$fasta{"NROWS"}){
		$fasta{"seq","$it"}=substr($fasta{"seq","$it"},$beg,($end-$beg+1));}}}
				# --------------------------------------------------
				# write output
				# --------------------------------------------------
                                # ------------------------------
				# write an MSF formatted file
    if    ($formOutLoc eq "msf"){
        undef %tmp; undef %tmp2; 
        foreach $it (1..$fasta{"NROWS"}){
	    $name=        $fasta{"id","$ct"};$name=~s/^\s*|\s*$//g;$name=~s/^(\S+).*$/$1/g;
	    $name=substr($name,1,14) if (length($name)>14); # yy hack for convert_seq
	    if (defined $tmp2{$name}){ # avoid duplication
		$ct=0;while (defined $tmp2{$name}){
		    ++$ct;$name=substr($name,1,12).$ct;}}$tmp2{$name}=1;
	    $tmp{"$it"}=  $name;$tmp{"$name"}=$fasta{"seq","$ct"};}
	$tmp{"NROWS"}=$fasta{"NROWS"};
        $tmp{"FROM"}=$fileInLoc; 
        $tmp{"TO"}=  $fileOutLoc;
        $fhout="FHOUT_MSF_FROM_SAF";
        open("$fhout",">$fileOutLoc")  || # open file
            return(0,"*** $sbrName cannot open fileOutLoc=$fileOutLoc\n");
        $Lok=&msfWrt("$fhout",%tmp); # write the file
        close("$fhout");
        return(0,"*** ERROR $sbrName: failed in MSF format ($fileOutLoc)\n") if (! $Lok);}

                                # ------------------------------
				# write a SAF,PIR,FASTA, formatted file
    elsif ($formOutLoc eq "saf"   || $formOutLoc eq "fastamul" || $formOutLoc eq "pirmul" || 
	   $formOutLoc eq "fasta" || $formOutLoc eq "pir"){
        if    ($formOutLoc =~ /^fasta/){
            ($Lok,$msg)=&fastaWrtMul($fileOutLoc,%fasta);}
        elsif ($formOutLoc =~ /^pir/){
            ($Lok,$msg)=&pirWrtMul($fileOutLoc,%fasta);}
        elsif ($formOutLoc eq "saf"){
            ($Lok,$msg)=&safWrt($fileOutLoc,%fasta);}
        return(0,"*** ERROR $sbrName: failed in SAF format ($fileOutLoc)\n".$msg."\n") if (! $Lok);}
				# ------------------------------
				# file existing??
    return(2,"*** $sbrName ERROR after write, missing fileOutLoc=$fileOutLoc\n") 
	if (! -e $fileOutLoc);
				# ------------------------------
				# make a basic test of msf format
    if    ($formOutLoc eq "msf"){
        ($Lok,$msg)=
            &msfCheckFormat($fileOutLoc);
        return(3,"$msg"."*** $sbrName ERROR from msfCheckFormat fileOutLoc=$fileOutLoc\n") if (! $Lok);}
				# ------------------------------
    $#fasta=$#nameLoc=0;        # save space
    undef %fasta; undef %nameInBlock; undef %tmp;
    return(1,"$sbrName ok");
}				# end of convFastamul2many

#===============================================================================
sub convFssp2Daf {
    local ($fileFssp,$fileDaf,$fileDafTmp,$exeConv,$dirDsspLoc) = @_ ;
    local ($fhinLoc,$fhoutLoc,$tmp,@tmp);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   convFssp2Daf		converts an HSSP file into the DAF format
#         in:   		fileHssp, fileDaf, execonvFssp2Daf
#         out:   		1 if converted file in DAF and existing, 0 else
#--------------------------------------------------------------------------------
    $sbrName="lib-br:convFssp2Daf";
    return(0,"*** ERROR $sbrName: fileFssp=$fileFssp missing\n") 
        if (! defined $fileFssp || ! -e $fileFssp);
    $dirDsspLoc=""              if (! defined $dirDsspLoc || ! -d $dirDsspLoc);
				# ------------------------------
				# run via system call:
				# ------------------------------
    if ($exeConv=~/\.pl/){
	system("$exeConv $fileFssp $dirDsspLoc >> $fileDafTmp"); }
				# ------------------------------
				# include as package
				# ------------------------------
    else {
	&conv_fssp2daf_lh'conv_fssp2daf_lh($fileFssp,$dirDsspLoc,"fileOut=$fileDafTmp"); } # e.e' 

				# ------------------------------
				# as Liisa cannot do it: clean up!
    $fhinLoc= "FhInconvFssp2Daf"; $fhoutLoc="FhOutconvFssp2Daf";
    &open_file("$fhinLoc","$fileDafTmp") || 
	return(0,"*** ERROR $sbrName failed to open temp=$fileDafTmp (piped from $exeConv)\n");
    &open_file("$fhoutLoc",">$fileDaf")  ||
	return(0,"*** ERROR $sbrName failed to open new=$fileDaf\n");
				# ------------------------------
    while(<$fhinLoc>){		# header
	$tmp=$_;
	last if (/^\# idSeq/);print $fhoutLoc $tmp; }
    $tmp=~s/^\# //g;		# correct error 1 (names)
    $tmp=~s/\n//g;$tmp=~s/^[\t\s]*|[\t\s]*$//g;
    @tmp=split(/[\t\s]+/,$tmp); 
    foreach $tmp(@tmp){
	print $fhoutLoc "$tmp\t";}print $fhoutLoc "\n";
	
				# ------------------------------
    while(<$fhinLoc>){		# body
	$_=~s/\n//g;$_=~s/^[\s\t]*|[\s\t]*$//g;	# purge trailing blanks
	@tmp=split(/[\t\s]+/,$_);
	$seq=$tmp[$#tmp-1];$str=$tmp[$#tmp];
				# consistency
	return(0,"*** ERROR in $sbrName: lenSeq ne lenStr!\n".
	       "***       seq=$seq,\n","***       str=$str,\n","***       line=$_,\n")
	    if (length($seq) != length($str));

	$seqOut=$strOut="";	# expand small caps
	foreach $it (1..length($seq)){
	    $seq1=substr($seq,$it,1);$str1=substr($str,$it,1);
	    if    ( ($seq1=~/[a-z]/) && ($str1=~/[a-z]/) ){
		$seq1=~tr/[a-z]/[A-Z]/;$str1=~tr/[a-z]/[A-Z]/;$seqOut.=$seq1;$strOut.=$str1;}
	    elsif ($seq1=~/[a-z]/){
		$seq1=~tr/[a-z]/[A-Z]/;$seqOut.=$seq1;$strOut.=".";}
	    elsif ($str1=~/[a-z]/){
		$str1=~tr/[a-z]/[A-Z]/;$seqOut.=".";$strOut.=$str1;}
	    else {$seqOut.=$seq1;$strOut.=$str1;}}
				# print
	$tmp[$#tmp-1]=$seqOut;$tmp[$#tmp]=$strOut;
	foreach $tmp(@tmp){print $fhoutLoc "$tmp\t";}print $fhoutLoc "\n";
    } close($fhinLoc);close($fhoutLoc);

    return(1,"ok $sbrName") if ( (-e $fileDaf) && (&isDaf($fileDaf)));
    return(0,"*** ERROR $sbrName output $fileDaf missing or not DAF format\n");
}				# end of convFssp2Daf

#===============================================================================
sub convGcg2fasta {
    local($fileInLoc,$fileOutLoc,$fragLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   convGcg2fasta               converts GCG to FASTA format
#       in:                     $fileInLoc,$fileOutLoc,$fragLoc
#       in:                     $fragLoc=n-m    fragment to extract (optional)
#       out:                    implicit: file out
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."convGcg2fasta";$fhinLoc="FHIN_"."convGcg2fasta";
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc!")          if (! defined $fileInLoc);
    return(0,"*** $sbrName: not def fileOutLoc!")         if (! defined $fileOutLoc);
    $fragLoc=0                                            if (! defined $fragLoc);

    return(0,"*** $sbrName: miss in file '$fileInLoc'!")  if (! -e $fileInLoc);

                                # ------------------------------
    ($Lok,$id,$seq)=            # read GCG
        &gcgRd($fileInLoc);
    return(0,"*** ERROR $sbrName: failed to read SWISS ($fileInLoc)\n".
             "***                 found id=$id\n") 
        if (! $Lok || length($seq)<1);

    undef %tmp;
    $tmp{"id","1"}= $id;
    $tmp{"seq","1"}=$seq;
    $tmp{"NROWS"}=1;
                                # ------------------------------
                                # extract?
    if ($fragLoc){($beg,$end)=split(/-/,$frag);
                  foreach $it (1..$tmp{"NROWS"}){
                      $tmp{"seq","$it"}=substr($tmp{"seq","$it"},$beg,($end-$beg+1));}}
                                # ------------------------------
                                # write output
    ($Lok,$msg)=
        &fastaWrtMul($fileOutLoc,%tmp);
    return(0,"*** ERROR $sbrName: failed to write FASTAmul ($fileOutLoc)\n".
           "***                 msg=$msg\n") if (! $Lok);
    return(2,"-*- WARN $sbrName: wrong number written\n$msg\n") if ($Lok != 1);
    return(1,"ok $sbrName");
}				# end of convGcg2fasta

#===============================================================================
sub convHssp2Daf {
    local ($fileHssp,$fileDaf,$exeConv) = @_ ;local ($command,$an,$formOut);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   convHssp2Daf		converts an HSSP file into the DAF format
#       in:      		fileHssp, fileDaf, exeConvHssp2Daf
#       out:    		1 if converted file in DAF and existing, 0 else
#--------------------------------------------------------------------------------
    $formOut="d";
    $an=     "N";
    $command="";
				# run FORTRAN script
    eval "\$command=\"$exeConv,$fileHssp,$formOut,$an,$fileDaf,$an\"";
    &run_program("$command" ,"STDOUT","die");

    if ( (-e $fileDaf) && (&isDaf($fileDaf)) ){
	return (1);}
    else {
	return(0);}
}				# end of convHssp2Daf

#===============================================================================
sub convHssp2msf {
    local($exeConvLoc,$file_in_loc,$file_out_loc,$fhErrSbr)=@_;
    local($form_out,$an,$command);
#----------------------------------------------------------------------
#   convHssp2msf                runs convert_seq for HSSP -> MSF
#       in:                     $exeConvLoc,$file_in_loc,$file_out_loc,$fhErrSbr
#       in:                     FORTRAN file.hssp, file.msf (name output), errorHandle
#       out:                    fileHssp (written by convert_seq)
#       err:                    ok=(1,'ok'), err=(0,'msg')
#----------------------------------------------------------------------
    $sbrName="lib-br:convHssp2msf";
    $fhErrSbr="STDOUT"                                if (! defined $fhErrSbr);
    return(0,"*** $sbrName: not def exeConvLoc!")     if (! defined $exeConvLoc);
    return(0,"*** $sbrName: not def file_in_loc!")    if (! defined $file_in_loc);
    return(0,"*** $sbrName: not def file_out_loc!")   if (! defined $file_out_loc);
				# check existence of files
    return(0,"*** $sbrName: miss file=$file_in_loc!") if (! -e $file_in_loc);
    return(0,"*** $sbrName: miss exe =$exeConvLoc!")  if (! -e $exeConvLoc);
				# ------------------------------
				# input for fortran program
    $form_out= 	 "M";
    $an=         "N";
    $command=    "";
				# --------------------------------------------------
				# call fortran 
    eval "\$command=\"$exeConvLoc,$file_in_loc,$form_out,$an,$file_out_loc,$an,$an\"";
    $Lok=&run_program("$command" ,"$fhErrSbr","warn");

#    $command="echo '$file_in_loc\n".
#	"$form_out\n"."$an\n"."$file_out_loc\n"."$an\n"."$an\n".
#	    "' | $exeConvLoc";
#    $fhErrSbr=`$command`;

    return(0,"*** $sbrName ERROR: no output $file_out_loc ($exeConvLoc,$file_in_loc)\n")
	if (!$Lok || (! -e $file_out_loc));
    return(1,"$sbrName ok");
}				# end of convHssp2msf

#===============================================================================
sub convHssp2seq {
    local($fileInLoc,$chainInLoc,$fileOutLoc,$formOutLoc,$extOutLoc,
          $doExpand,$fragLoc,$extrLoc,$lenMin,$laliMin,$distMin,$pideMax,$fhErrSbr) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   convHssp2seq                converts HSSP file to PIR(mul), FASTA(mul)
#       in:                     $fileInLoc   file.hssp, file.out, format_of_output_file
#       in:                     $fileOutLoc  output file with converted sequence(s)
#       in:                     $formOut     output format (lower caps)
#                                 = 'fasta|pir' (or pirmul/fastamul)
#       in:                     $extOutLoc   extension of expected output 
#                                            (fragments into _beg_end$extension)
#       in:                     $doExpand    do expand the deletions? (only for MSF)
#       in:                     $frag        fragment e.g. '1-5','10-100'
#                                 = 0        for any
#                                            NOTE: only ONE fragment allowed, here
#       in:                     $extrIn      number of protein(s) to extract
#                                 = 'p1-p2,p3' -> extract proteins p1-p2,p3
#                                 = 0        for all
#                      NOTE:      = guide    to write only the guide sequence!!
#       in:                     $lenMin      minimal length of sequence to write 
#                                 = 0        for any
#       in:                     $laliMin     minimal alignment length (0 for wild card)
#                                 = 0        for any
#       in:                     $distMin     minimal distance from HSSP threshold
#                                 = 0        for any
#       in:                     $pideMAx !!  maximal sequence identity
#                                 = 0        for any
#       in:                     $fhSbr       ERRORs of convert_seq
#       out:                    1|0,msg,implicit: converted file
#       err:                    0,$msg -> unspecified error 
#       err:                    1,$msg -> ok
#       err:                    2,$msg -> conversion option not supported
#-------------------------------------------------------------------------------
    $sbrName="lib-br::"."convHssp2seq"; $fhinLoc="FHIN_"."convHssp2seq";
                                # ------------------------------
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc!")           if (! defined $fileInLoc);
    $chainInLoc="*"                                        if (! defined $chainInLoc);
    return(0,"*** $sbrName: not def fileOutLoc!")          if (! defined $fileOutLoc);
    return(0,"*** $sbrName: not def formOutLoc!")          if (! defined $formOutLoc);
    return(0,"*** $sbrName: not def extOutLoc!")           if (! defined $extOutLoc);
    return(0,"*** $sbrName: not def doExpand!")            if (! defined $doExpand);
    return(0,"*** $sbrName: not def fragLoc!")             if (! defined $fragLoc);
    return(0,"*** $sbrName: not def extrLoc!")             if (! defined $extrLoc);
    $lenMin=0                                              if (! defined $lenMin);
    $laliMin=0                                             if (! defined $laliMin);
    $distMin=0                                             if (! defined $distMin);
    $pideMax=0                                             if (! defined $pideMax);
    $fhErrSbr="STDOUT"                                     if (! defined $fhErrSbr);
				# existence of file
    return(0,"*** $sbrName: miss in file '$fileInLoc'!")   if (! -e $fileInLoc);

                                # ------------------------------
                                # supported output options
    return(&errSbr("output format $formOutLoc not supported by this sbr"))
	if ($formOutLoc !~ /^(pir|fasta)/);

				# ------------------------------
    if ($fragLoc) {		# fragment of proteins
	return(&errSbr("frag MUST be 'N1-N2', only ONE!")) if ($fragLoc !~/\d+\-\d+/);
	($ifirFrag,$ilasFrag)=split(/\-/,$fragLoc); }
    else {
	$ifirFrag=$ilasFrag=0; }

    $LextrGuideOnly=0;		# ------------------------------
    undef %extr;		# extraction of proteins
    if ($extrLoc eq "guide"){	# only guide
	$LextrGuideOnly=1;}
    elsif ($extrLoc) {		# get numbers to extract
	return(&errSbr("extr MUST be of the form:\n".
		       "'extr=n1-n2', or 'extr=n1,n2,n3-n4,n5'"))
	    if ($extr !~ /\d/);
	@extr=&get_range($extr);
	return(&errSbr("you gave the argument 'extr=$extr', not valid!\n".
		       "***   Ought to be of the form:\n".
		       "'extr=n1-n2', or 'extr=n1,n2,n3-n4,n5'\n")) if ($#extr==0);
	foreach $tmp (@extr) {
	    if ($tmp=~/\D/){ 
		return(&errSbr("you gave the argument 'extr=$extr', not valid!\n".
			       "***   Ought to be of the form:\n".
			       "'extr=n1-n2', or 'extr=n1,n2,n3-n4,n5'\n")); }
	    $extr{"$tmp"}=1; }}
				# ------------------------------
				# determine id
    $pdbid= $fileInLoc;$pdbid=~s/^.*\/|\.hssp//g; 
    $pdbid.="_".$chainInLoc     if ($chainInLoc ne "*");
    undef %tmp;			# ------------------------------
    if ($chainInLoc ne "*"){	# get chain positions
        ($Lok,%tmp)= 
	    &hsspGetChain($fileInLoc);
                                return(&errSbr("failed on getchain($fileInLoc)")) if (! $Lok);
	foreach $it (1..$tmp{"NROWS"}){
	    next if ($chainInLoc ne $tmp{"$it","chain"});
	    $ifirChain=$tmp{"$it","ifir"}; $ilasChain=$tmp{"$it","ilas"}; }}
    else {
	$ifirChain=$ilasChain=0;}
				# ------------------------------
    undef %tmp;			# read header of HSSP
    ($Lok,%tmp)=
	&hsspRdHeader($fileInLoc,"SEQLENGTH","ID","IDE","LALI","IFIR","ILAS");
                                return(&errSbr("failed on $fileInLoc")) if (! $Lok);
                                # ------------------------------
                                # too short -> skip
    return(1,"too short=".$tmp{"SEQLENGTH"})  if ($tmp{"SEQLENGTH"} < $lenMin);

    $#numTake=0;		# ------------------------------
				# process data

    if ($LextrGuideOnly){	# guide, only -> skip the following
	push(@numTake,1);
	$tmp{"NROWS"}=0; }

    foreach $it (1..$tmp{"NROWS"}){ # loop over all alis
				# not to include 
	next if ($extrLoc && ! defined $extr{"$it"});
				# not chain -> skip
	next if ($ifir && $ilas && 
		 ( ($tmp{"IFIR","$it"} > $ilas) || ($tmp{"ILAS","$it"} < $ifir) ));
				# lali too short
	next if ($laliMin > $tmp{"LALI","$it"} );
				# pide too high
	next if ($pideMax && $pideMax < 100*$tmp{"IDE","$it"} );
				# distance from threshold too high
	if ($distMin){
                                # compile distance to HSSP threshold (new)
	    ($pideCurve,$msg)= 
		&getDistanceNewCurveIde($tmp{"LALI","$it"});
	    next if ($msg !~ /^ok/);
	    $dist=100*$tmp{"IDE","$it"} - $pideCurve;
	    next if ($dist < $distMin); }

        push(@numTake,$it);     # ok -> take
    }
                                # ------------------------------
    undef %tmp;			# read alignments
    $kwdSeq="seqNoins";                         # default: read ali without insertions
    $kwdSeq="seqAli"            if ($doExpand);	# wanted:  read ali with insertions
	
    ($Lok,%tmp)=
	&hsspRdAli($fileInLoc,@numTake,$kwdSeq);
                                return(&errSbrMsg("failed reading alis for $fileInLoc, num=".
						  join(',',@numTake),$msg)) if (! $Lok);
    $nali=$tmp{"NROWS"};
    undef %tmp2;
				# ------------------------------
    if (defined $fragLoc){	# adjust for extraction (arg: frag=N1-n2)
				# additional complication if expand: change numbers
	if ($kwdSeq eq "seqAli"){ 
	    $seq=$tmp{"$kwdSeq","0"};
	    @tmp=split(//,$seq); $ct=0;
	    foreach $it (1..$#tmp){
		next if ($tmp[$it] eq ".");             # skip insertions
		++$ct;                                  # count no-insertions
		next if ($ct > $ifirFrag);              # outside of range to read
		next if ($ct < $ilasFrag);              # outside of range to read
		$ifirFrag=$it if ($ct == $ifirFrag);    # change begin !!  WARN  !!
		$ilasFrag=$it if ($ct == $ilasFrag);}}} # change end   !!  WARN  !!

				# ----------------------------------------
				# cut out non-chain, and not to read parts
				# ----------------------------------------
    foreach $it (0..$nali){
				# guide, only -> skip the following
	last if ($LextrGuideOnly && $it>0);
				# chain restricts reading
	if ($ifirChain && $ilasChain){
	    $tmp{"$kwdSeq","$it"}=
		substr($tmp{"$kwdSeq","$it"},$ifirChain,($ilasChain-$ifirChain+1));}
				# wanted fragment restricts reading
	if ($ifirFrag && $ilasFrag){
	    $len=length($tmp{"$kwdSeq","$it"});
	    return(&errSbr(" : sequence outside (f=$fileInLoc, c=$chainInLoc)\n".
			   "itNali=$it, ifirFrag=$ifirFrag, len=$len, kwdSeq=$kwdSeq,\n".
			   "seq=".$tmp{"$kwdSeq","$it"}))
		if ( $len < $ifirFrag);
	    $lenWrt=($ilasFrag-$ifirFrag+1);
	    $lenWrt=$len-$ifirFrag+1  if ($lenWrt < $len);
	    $tmp{"$kwdSeq","$it"}=
		substr($tmp{"$kwdSeq","$it"},$ifirFrag,$len); }
	$ct=$it+1;
	$tmp2{"seq","$ct"}=$tmp{"$kwdSeq","$it"};
	undef  $tmp{"$kwdSeq","$it"}; # slim-is-in !
	$tmp2{"id","$ct"}= $tmp{"$it"};}
    $tmp2{"NROWS"}=$nali+1;
    $tmp2{"NROWS"}=1            if ($LextrGuideOnly);
    undef %tmp;			# slim-is-in!
				# ------------------------------
    undef %tmp;			# slim-is-in !
    undef @numTake;		# slim-is-in !

				# --------------------------------------------------
				# write output file
				# --------------------------------------------------
    if ($formOutLoc =~ /^pir/){ # PIR, PIRmul
        ($Lok,$msg)=
            &pirWrtMul($fileOutLoc,%tmp2); }
    else {                      # FASTA, FASTAmul
        ($Lok,$msg)=
            &fastaWrtMul($fileOutLoc,%tmp2); }
        
    return(&errSbrMsg("failed writing out=$fileOutLoc, for in=$fileInLoc",$msg)) if (! $Lok);
    print $fhErrSbr		# warning if returned Lok==2
	"-*- WARN $sbrName: outformat=$formOutLoc, not enough written:\n",$msg,"\n" 
	    if ($Lok==2);
    undef %tmp2;		# slim-is-in !
    return(1,"ok $sbrName");
}				# end of convHssp2seq

#===============================================================================
sub convMsf2Hssp {
    local($fileMsfLoc,$fileHsspLoc,$fileCheck,$exeConvLoc,$matGCG,$fhErrSbrx) = @_ ;
    local($sbrName,$Lok,$fhinLoc,$form_out,$an,$command);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   convMsf2Hssp                converts the MSF into an HSSP file
#       in:                     fileMsf, fileHssp(output), exeConv (convert_seq), matGCG
#       out:                    fileHssp (written by convert_seq)
#       err:                    ok=(1,'ok'), err=(0,'msg')
#--------------------------------------------------------------------------------
    $sbrName="lib-br:convMsf2Hssp";$fhinLoc="FHIN"."$sbrName";
				# check definitions
    return(0,"*** $sbrName: not def fileMsfLoc!")  if (! defined $fileMsfLoc);
    return(0,"*** $sbrName: not def fileHsspLoc!") if (! defined $fileHsspLoc);
    return(0,"*** $sbrName: not def fileCheck!")   if (! defined $fileCheck);
    return(0,"*** $sbrName: not def exeConvLoc!")  if (! defined $exeConvLoc);
    return(0,"*** $sbrName: not def matGCG!")      if (! defined $matGCG);
    $fhErrSbrx="STDOUT"                            if (! defined $fhErrSbrx);
				# check existence of files
    return(0,"*** $sbrName: miss input file '$fileMsfLoc'!") if (! -e $fileMsfLoc);
    return(0,"*** $sbrName: miss input exe  '$exeConvLoc'!") if (! -e $exeConvLoc);
    return(0,"*** $sbrName: miss input file '$matGCG'!")     if (! -e $matGCG);
    $msgHere="";
				# ------------------------------
				# input for fortran program
    $form_out= "H";		# output format
    $an=       "N";		# answers: (1)=treat gaps? (2)=other formats
    $command=  "";		# the empty one: which one is guide (return for default)

				# --------------------------------------------------
				# call fortran 
    eval "\$command=\"$exeConvLoc, $fileMsfLoc, $form_out,$matGCG,$an,$fileHsspLoc, ,$an \"";
    $Lok=&run_program("$command" ,$fhErrSbrx,"die");

#    $command="echo '$fileMsfLoc\n$form_out\n$matGCG\n$an\n$fileHsspLoc\n \n$an\n' | $exeConvLoc";
#    $fhErrSbrx=`$command`;
				# --------------------------------------------------
    if (! -e $fileHsspLoc){	# check existence (and emptiness) of HSSP file
	$msg= "*** ERROR $sbrName \t '$fileHsspLoc' converted HSSP file missing\n";
	return(0,"$msg");}	# **************************************************
				# check existence (and emptiness) of HSSP file
    if (&is_hssp_empty($fileHsspLoc)){
	$msg="*** ERROR $sbrName \t '$fileHsspLoc' converted HSSP file empty\n";
	return(0,"$msg");}	# **************************************************

				# --------------------------------------------------
                                # reconvert MSF -> HSSP
				# --------------------------------------------------
    $msgHere.="$sbrName: reconverting HSSP ($fileHsspLoc) -> MSF for check\n";
    ($Lok,$msg)=
	&convHssp2msf($exeConvLoc,$fileHsspLoc,$fileCheck);

    if (!$Lok || (! -e $fileHsspLoc)){
	$msgHere.="$msg";
	return(0,"$msgHere");}	# **************************************************

				# --------------------------------------------------
                                # comparing the two files
    open(FILE1,$fileMsfLoc)  ||  warn "-*- $sbrName: cannot open 1 $fileMsfLoc: $!\n";
    open(FILE2,$fileCheck)   ||  warn "-*- $sbrName: cannot open 1 $fileCheck: $!\n";
    $#ali1=$#ali2=0;
                                # ----------------------------------------
    while( <FILE1> ) {		# read file1
	last if ($_=~/^.+\/\// ); }
    while( <FILE1> ) {
	if ($_=~/[a-zA-Z]/ ) {($litter,$alignment)= split (' ',$_,2);
			      $alignment=~ s/[\s]//g;
			      push (@ali1,$alignment); }}close (FILE1); 
                                # ----------------------------------------
    while( <FILE2> ) {		# read file2
	last if ($_=~/^.+\/\/+/ ); }
    while( <FILE2> ) {
	if ($_=~/[a-zA-Z]/ ) {($litter,$alignment)= split (' ',$_,2);
			      $alignment=~ s/[\s]//g; $alignment =~ s/\*/\./g;
			      push (@ali2,$alignment); } } close (FILE2);
    $iter=$count_error=0;	# ----------------------------------------
    foreach $i (@ali1) {	# compare line by line
	++$iter;
	$tmp1= substr($i,2,(length($i)-2));
	$tmp1=~ tr/\*/\./;
	if ( $tmp1 !~ /[^acdefghiklmnopqrstvwxyACDEFGHIKLMNOPQRSTVWXY]/ ) {
	    $tmp2= $ali2[$iter];
	    $tmp2=~ tr/\*/\./; $tmp2 =~ tr/\(|\)/ /;
	    $tmp2=~ s/(.*)$tmp1(.*)/$1$2/;
	    if ( length($tmp2) gt 3 ) {
		++$count_error;
		$msgHere.="*** $sbrName ERROR: during re-converting comparison\n".
		    "tmp2=$tmp2,count_error=$count_error\n";}}}
    if ( $count_error gt 3 ) {
	$msgHere.="conversion: MSF -> HSSP failed, \n".$msgHere;
	return(0,"$msgHere"); }
    return(1,"$sbrName ok");
}				# end convMsf2hssp

#===============================================================================
sub convMsf2saf {
    local($fileInLoc,$fileOutLoc) = @_ ;
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   convMsf2saf                 converts MSF into SAF format
#       in:                     fileMsf,fileSaf
#       out:                    0|1,$msg 
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:convMsf2saf";$fhinLoc="FHIN_"."convMsf2saf";$fhoutLoc="FHOUT_"."convMsf2saf";
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc!")          if (! defined $fileInLoc);
    return(0,"*** $sbrName: not def fileOutLoc!")         if (! defined $fileInLoc);
    return(0,"*** $sbrName: miss in file '$fileInLoc'!")  if (! -e $fileInLoc);

    &open_file("$fhinLoc","$fileInLoc") ||
	return(0,"*** ERROR $sbrName: fileIn=$fileInLoc, not opened\n");
    $#tmp=$ct=$Lname=$LMsf=$LSeq=0;
				# ------------------------------
    while (<$fhinLoc>) {	# read MSF file
	$_=~s/\n//g;
				# --------------------
				# find sequence
        if    (! $LSeq && $_=~/^\/\// && $Lname && $LMsf){
            $LSeq=1;}
				# --------------------
	elsif (! $LSeq){	# header
            $LMsf=1       if (! $LMsf  && $_=~/msf\s*of\s*\:/i);
            $Lname=1      if (! $Lname && $_=~/name\s*:/i);
	    push(@tmp,$_) if (! $Lname); } # store header
				# --------------------
        elsif ($LSeq){		# sequence
				# first open file
            if ($ct==0){&open_file("$fhoutLoc",">$fileOutLoc") || 
			    return(0,"*** ERROR $sbrName: failed opening new $fileOutLoc\n");
			print $fhoutLoc "# SAF (Simple Alignment Format)\n";
			foreach $tmp(@tmp){
			    print $fhoutLoc "# $tmp\n";}}
	    ++$ct;
	    print $fhoutLoc "$_\n";	# simply mirror file
	}} close($fhinLoc); close($fhoutLoc) if ($ct>0); 
    $#tmp=0;			# save memory
    return(0,"*** ERROR $sbrName: $fileInLoc no valid MSF file\n") if ($ct==0);
    return(1,"ok $sbrName");
}				# end of convMsf2saf

#===============================================================================
sub convPhd2col {
    local ($file_in,$file_out,$opt_phd_loc)=@_;
    local ($sbrName,@des,@des2,%rdcol,$Lis_rdbformat,$it,$ct,$des,$itdes);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    convPhd2col                writes the prediction in column format
#       in:                     $file_in,$file_out,$opt_phd_loc
#       out:                    result into file
#       err:                    err=(0,$err), ok=(1,ok) 
#--------------------------------------------------------------------------------
    $sbrName="lib-br:convPhd2col";
    if    ($opt_phd_loc =~/^3|^both/) {
	@des= ("AA","PSEC","RI_S","pH", "pE", "pL", "PACC","PREL","RI_A","Pbie");
	@des2=("AA","PHEL","RI_S","OtH","OtE","OtL","PACC","PREL","RI_A","Pbie"); }
    elsif ($opt_phd_loc eq "sec") {
	@des= ("AA","PSEC","RI_S","pH", "pE", "pL");
	@des2=("AA","PHEL","RI_S","OtH","OtE","OtL"); }
    elsif ($opt_phd_loc eq "acc") {
	@des= ("AA","PACC","PREL","RI_A","Pbie");
	@des2=("AA","PACC","PREL","RI_A","Pbie"); }
    elsif ($opt_phd_loc eq "htm") {
	@des= ("AA","PSEC","RI_H","pH", "pL");
	@des2=("AA","PFHL","RI_H","OtH","OtL"); }
#	@des2=("AA","PFHL","RI_S","OtH","OtL"); }
    elsif ($opt_phd_loc eq "htmtop") {
	@des= ("AA","PSEC","RI_H","pH", "pL");
	@des2=("AA","PFHL","RI_S","OtH","OtL"); }
#	@des2=("AA","PFHL","RI_H","OtH","OtL"); }
				# lib-br
    %rdcol=&rd_col_associative($file_in,@des2); 
				# format line included?
    $Lis_rdbformat=0;
    if ( defined $rdcol{"AA","1"} && $rdcol{"AA","1"} eq "1" ) {
	$Lis_rdbformat=1;; 
	foreach $it(2..$rdcol{"NROWS"}){
	    foreach $des(@des2){
		$ct=$it-1;
		$rdcol{"$des","$ct"}=$rdcol{"$des","$it"}; }}
	$rdcol{"NROWS"}=($rdcol{"NROWS"} - 1 ); }
				# rename
    foreach $it(1..$rdcol{"NROWS"}){
	foreach $itdes(1..$#des){
	    $rdcol{"$des[$itdes]","$it"}=$rdcol{"$des2[$itdes]","$it"}; }}
				# write PHD.rdb ->  PP output format
    &wrt_phd_rdb2col($file_out,%rdcol);
    undef %rdcol;		# slim-is-in !
    return(1,"ok $sbr");
}				# end of convPhd2col

#===============================================================================
sub convPir2fasta {
    local($fileInLoc,$fileOutLoc,$fragLoc,$extrLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   convPir2fasta               converts PIR to FASTA format
#       in:                     $fileInLoc,$fileOutLoc,$fragLoc,$extrLoc
#       in:                     $fragLoc=n-m    fragment to extract (optional)
#       in:                     $extrLoc=i,j,k  take only sequences i,j,k from PIRmul
#                               NOTE: to leave blank =0, e.g. 
#                               'file.pir,file.f,0,5' would get fifth sequence
#       out:                    implicit: file out
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."convPir2fasta";$fhinLoc="FHIN_"."convPir2fasta";
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc!")          if (! defined $fileInLoc);
    return(0,"*** $sbrName: not def fileOutLoc!")         if (! defined $fileOutLoc);
    $fragLoc=0                                            if (! defined $fragLoc);
    $extrLoc=0                                            if (! defined $extrLoc);

    return(0,"*** $sbrName: miss in file '$fileInLoc'!")  if (! -e $fileInLoc);

                                # interpret input
    $num=$extrLoc;# $num=1 if (! $extrLoc);
                                # ------------------------------
    ($Lok,$id,$seq)=            # read PIR
        &pirRdMul($fileInLoc,$num);

    return(0,"*** ERROR $sbrName: failed to read PIRmul ($fileInLoc,$num)\n".
             "***                 found id=$id\n") 
        if (! $Lok || length($seq)<1);
                                # ------------------------------
                                # interpret info
    @id=split(/\n/,$id);@seq=split(/\n/,$seq);
    return(0,"*** ERROR $sbrName: seq=$seq, and id=$id, not matching (differing number)\n") 
        if ($#id != $#seq);
    $tmp{"NROWS"}=$#id;
    foreach $it (1..$#id){$tmp{"id","$it"}= $id[$it];
                          $tmp{"seq","$it"}=$seq[$it];}
                                # ------------------------------
                                # extract?
    if ($fragLoc){($beg,$end)=split(/-/,$frag);
                  foreach $it (1..$tmp{"NROWS"}){
                      $tmp{"seq","$it"}=substr($tmp{"seq","$it"},$beg,($end-$beg+1));}}
                                # ------------------------------
                                # write output
    ($Lok,$msg)=
        &fastaWrtMul($fileOutLoc,%tmp);
    return(0,"*** ERROR $sbrName: failed to write FASTAmul ($fileOutLoc)\n".
           "***                 msg=$msg\n") if (! $Lok);
    return(2,"-*- WARN $sbrName: wrong number written\n$msg\n") if ($Lok != 1);
    return(1,"ok $sbrName");
}				# end of convPir2fasta

#===============================================================================
sub convSaf2many {
    local($fileInLoc,$fileOutLoc,$formOutLoc,$fragLoc,$extrLoc,$fhErrSbr) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   convSaf2many                converts SAF into many formats: saf2msf, saf2fasta, saf2pir
#       in:                     $fileInLoc,$fileOutLoc,$formOutLoc,$fragLoc,$extrLoc,$fhErrSbr
#       in:                     $formOutLoc     format MSF|FASTA|PIR
#       in:                     $fragLoc=n-m    fragment to extract (optional)
#       in:                     $extrLoc=i,j,k  take only sequences i,j,k from PIRmul
#       in:                     NOTE: to leave blank =0, e.g. 
#       in:                           'file.saf,file.f,0,5' would get fifth sequence
#       out:                    implicit: file written
#       err:                    (1,'ok'), (0,'message')
#       err:                    e: (1,msg) -> ok
#       err:                    a: (0,msg) -> some arguments missing/files not opened
#       err:                    b: (2,msg) -> no output file written 
#       err:                    b: (3,msg) -> ERROR from msfCheckFormat
#   specification of format     see interpretSeqSaf
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."convSaf2many";$fhinLoc="FHIN_"."convSaf2many";
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc!")          if (! defined $fileInLoc);
    return(0,"*** $sbrName: not def fileOutLoc!")         if (! defined $fileOutLoc);
    return(0,"*** $sbrName: not def formOutLoc!")         if (! defined $formOutLoc);
    $fragLoc=0                                            if (! defined $fragLoc);
    $extrLoc=0                                            if (! defined $extrLoc);
    return(0,"*** $sbrName: miss in file '$fileInLoc'!")  if (! -e $fileInLoc);
                                # interpret input
    $formOutLoc=~tr/[A-Z]/[a-z]/;
    if ($fragLoc){$fragLoc=~s/\s//g;
		  return(0,"*** $sbrName: syntax of fragLoc ($fragLoc) must be :\n".
			 "    'ifir-ilas', where ifir,ilas are integers (or 1-*)\n")
		      if ($fragLoc && $fragLoc !~/[\d\*]\-[\d\*]/);}
    if ($extrLoc){$extrLoc=~s/\s//g;
		  return(0,"*** $sbrName: syntax of extrLoc ($extrLoc) must be :\n".
			 "    'n1,n2,n3-n4', where n* are integers\n")
		      if ($extrLoc && $extrLoc =~/[^0-9\-,]/);
		  @extr=&get_range($extrLoc); 
                  undef %take;
                  foreach $it(@extr){
                      $take{$it}=1;}}
                                # ------------------------------
                                # read file
    ($Lok,$msg,%safIn)=
        &safRd($fileInLoc);

    @nameLoc=split(/,/,$safIn{"names"});
				# ------------------------------
    undef %tmp; $ctTake=0;	# store names for passing variables
    foreach $it (1..$#nameLoc){ 
        next if ($extrLoc && (! defined $take{$it} || ! $take{$it}));
        ++$ctTake; 
	$tmp{"id","$ctTake"}= $nameLoc[$it];
        $tmp{"seq","$ctTake"}=$safIn{"seq","$it"};}
    $tmp{"NROWS"}=$ctTake;
    %safIn=%tmp; undef %tmp;
				# ------------------------------
				# select subsets
				# ------------------------------
    if ($fragLoc){
	($beg,$end)=split("-",$fragLoc);$name=$safIn{"1"};$len=length($safIn{"$name"});
	$beg=1 if ($beg eq "*"); $end=$len if ($end eq "*");
	if ($len < ($end-$beg+1)){
	    print "-*- WARN $sbrName: $beg-$end not possible, as length of protein=$len\n";}
	else {
	    foreach $it (1..$safIn{"NROWS"}){
		$name=$safIn{"id","$it"};
		$safIn{"seq","$it"}=substr($safIn{"seq","$it"},$beg,($end-$beg+1));}}}
				# --------------------------------------------------
				# write output
				# --------------------------------------------------
				# write an MSF formatted file
    if    ($formOutLoc eq "msf"){
				# reconvert to what MSF wants...
	foreach $it (1..$safIn{"NROWS"}){$name=$safIn{"id","$it"};
					 $tmp{"$it"}=$name;
					 $tmp{"$name"}=$safIn{"seq","$it"};}
	$tmp{"NROWS"}=$safIn{"NROWS"};
        $tmp{"FROM"}= $fileInLoc; 
        $tmp{"TO"}=   $fileOutLoc;
        $fhout="FHOUT_MSF_FROM_SAF";
        open("$fhout",">$fileOutLoc")  || # open file
            return(0,"*** $sbrName cannot open fileOutLoc=$fileOutLoc\n");
        $Lok=&msfWrt("$fhout",%tmp); # write the file
        close("$fhout"); undef %tmp;}
				# write a FASTA or PIR formatted file
    elsif ($formOutLoc eq "fasta"  || $formOutLoc eq "fastamul" || $formOutLoc eq "saf" || 
	   $formOutLoc eq "pirmul" || $formOutLoc eq "pir"){
        if    ($formOutLoc =~ /^fasta/){
            ($Lok,$msg)=&fastaWrtMul($fileOutLoc,%safIn);}
        elsif ($formOutLoc =~ /^pir/){
            ($Lok,$msg)=&pirWrtMul($fileOutLoc,%safIn);}
        elsif ($formOutLoc eq "saf"){
            ($Lok,$msg)=&safWrt($fileOutLoc,%safIn);}
        return(0,"*** ERROR $sbrName: failed in $formOutLoc ($fileOutLoc)\n".$msg."\n") if (! $Lok);}
    else {
        return(0,"*** $sbrName: output format $formOutLoc not supported\n");}
				# ------------------------------
				# file existing??
    return(2,"*** $sbrName ERROR after write, missing fileOutLoc=$fileOutLoc\n") 
	if (! -e $fileOutLoc);
				# ------------------------------
				# make a basic test of msf format
    if    ($formOutLoc eq "msf"){
        ($Lok,$msg)=
            &msfCheckFormat($fileOutLoc);
        return(3,"$msg"."*** $sbrName ERROR from msfCheckFormat fileOutLoc=$fileOutLoc\n") if (! $Lok);}
				# ------------------------------
    $#safIn=$#nameLoc=0;        # save space
    undef %safIn; undef %nameInBlock; undef %tmp;
    return(1,"$sbrName ok");
}				# end of convSaf2many

#===============================================================================
sub convSwiss2fasta {
    local($fileInLoc,$fileOutLoc,$fragLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   convSwiss2fasta             converts SWISS-PROT to FASTA format
#       in:                     $fileInLoc,$fileOutLoc,$fragLoc
#       in:                     $fragLoc=n-m    fragment to extract (optional)
#       out:                    implicit: file out
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."convSwiss2fasta";$fhinLoc="FHIN_"."convSwiss2fasta";
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc!")          if (! defined $fileInLoc);
    return(0,"*** $sbrName: not def fileOutLoc!")         if (! defined $fileOutLoc);
    $fragLoc=0                                            if (! defined $fragLoc);

    return(0,"*** $sbrName: miss in file '$fileInLoc'!")  if (! -e $fileInLoc);

                                # ------------------------------
    ($Lok,$id,$seq)=            # read SWISS
        &swissRdSeq($fileInLoc);
    return(0,"*** ERROR $sbrName: failed to read SWISS ($fileInLoc)\n".
             "***                 found id=$id\n") 
        if (! $Lok || length($seq)<1);

    undef %tmp;
    $tmp{"id","1"}= $id;
    $tmp{"seq","1"}=$seq;
    $tmp{"NROWS"}=1;
                                # ------------------------------
                                # extract?
    if ($fragLoc){($beg,$end)=split(/-/,$frag);
                  foreach $it (1..$tmp{"NROWS"}){
                      $tmp{"seq","$it"}=substr($tmp{"seq","$it"},$beg,($end-$beg+1));}}
                                # ------------------------------
                                # write output
    ($Lok,$msg)=
        &fastaWrtMul($fileOutLoc,%tmp);
    return(0,"*** ERROR $sbrName: failed to write FASTAmul ($fileOutLoc)\n".
           "***                 msg=$msg\n") if (! $Lok);
    return(2,"-*- WARN $sbrName: wrong number written\n$msg\n") if ($Lok != 1);
    return(1,"ok $sbrName");
}				# end of convSwiss2fasta

#===============================================================================
sub convSeq2fasta {
    local($exeConvSeqLoc,$file_in_loc,$file_out_loc,$fhTraceLoc,$frag)=@_;
    local($outformat,$an,$commandLoc);
#----------------------------------------------------------------------
#   convSeq2fasta               convert all formats to fasta
#       in:                     $exeConvSeqLoc,$file_in_loc,$file_out_loc,$fhTraceLoc
#       in:                     $frage = 1-5, fragment from 1 -5 
#       out:                    
#       err:                    ok=(1,'ok'), err=(0,'msg')
#----------------------------------------------------------------------
    $sbrName="lib-br:convSeq2Fasta";
    return(0,"*** $sbrName: not def file_in_loc!")      if (! defined $file_in_loc);
    return(0,"*** $sbrName: not def file_out_loc!")     if (! defined $file_out_loc);
    return(0,"*** $sbrName: not def exeConvSeqLoc!")    if (! defined $exeConvSeqLoc);
    $fhTraceLoc="STDOUT"                                   if (! defined $fhTraceLoc);
    $frag=0                                             if (! defined $frag);
				# check existence of files
    return(0,"*** $sbrName: no file '$file_in_loc'!")   if (! -e $file_in_loc);
    return(0,"*** $sbrName: no exe  '$exeConvSeqLoc'!") if (! -e $exeConvSeqLoc);

    $frag=0 if ($frag !~ /\-/);
                                # ------------------------------
    if ($frag){                 # extract fragments?
        $frag=~s/\s//g;
        ($beg,$end)=split('-',$frag);
        $frag=0 if ($beg =~/\D/ || $end =~ /\D/);}
				# ------------------------------
				# call FORTRAN program
    $cmd=              "";      # eschew warnings
    $outformat=        "F";     # output format FASTA
    $an2=              "N";     # write another format?
    if ($frag){
        $an1=          "Y";     # do fragment
        $anF=          "$beg $end"; # answer for fragment
        eval "\$cmd=\"$exeConvSeqLoc,$file_in_loc,$outformat,$an1,$anF,$file_out_loc,$an2,\"";
        &run_program("$cmd" ,"$fhTraceLoc","warn"); }
    else {
        $an1=          "N";     # no fragment
        eval "\$cmd=\"$exeConvSeqLoc,$file_in_loc,$outformat,$an1,$file_out_loc,$an2,\"";
        &run_program("$cmd" ,"$fhTraceLoc","warn"); }

    return(0,"*** ERROR $sbrName: no output from FORTRAN convert_seq, couldnt run_program cmd=$cmd\n")
        if (! -e $file_out_loc);
    return(1,"ok $sbrName");
}				# end of convSeq2fasta

#===============================================================================
sub convSeq2fastaPerl {
    local($fileInLoc,$fileOutLoc,$formInLoc,$fragLoc)=@_;
    local($outformat,$an,$commandLoc);
#----------------------------------------------------------------------
#   convSeq2fastaPerl           convert all formats to fasta (no fortran)
#       in:                     $fileInLoc,$fileOutLoc,$formInLoc,$fragLoc
#       in:                     $formInLoc: pir, pirmul, gcg, swiss, dssp
#       in:                     $fragLoce = 1-5, fragment from 1 -5 
#       out:                    
#       err:                    ok=(1,'ok'), err=(0,'msg')
#----------------------------------------------------------------------
    $sbrName="lib-br:convSeq2fastaPerl";
    return(0,"*** $sbrName: not def fileInLoc!")      if (! defined $fileInLoc);
    return(0,"*** $sbrName: not def fileOutLoc!")     if (! defined $fileOutLoc);
    return(0,"*** $sbrName: not def formInLoc!")      if (! defined $formInLoc);
    $fragLoc=0                                        if (! defined $fragLoc);
				# check existence of files
    return(0,"*** $sbrName: no file '$fileInLoc'!")   if (! -e $fileInLoc);

    $fragLoc=0                  if ($fragLoc !~ /\-/);

				# ------------------------------
				# do conversion
				# ------------------------------
    if    ($formInLoc=~ /^pir/){   # PIR
	($Lok,$msg)=
	    &convPir2fasta($fileInLoc,$fileOutLoc,$fragLoc,1);}
    elsif ($formInLoc=~ /^swiss/){ # SWISS-PROT
	($Lok,$msg)=
	    &convSwiss2fasta($fileInLoc,$fileOutLoc,$fragLoc);}
    elsif ($formInLoc eq "gcg"){   # GCG
	($Lok,$msg)=
	    &convGcg2fasta($fileInLoc,$fileOutLoc,$fragLoc);}
    else {
	return(&errSbr("format $formInLoc to FASTA not supported"));}
    return(&errSbrMsg("failed converting format=$formInLoc ($fileInLoc,$fileOutLoc,$fragLoc)",
		      $msg))    if (! $Lok);

    return(1,"ok $sbrName");
}				# end of convSeq2fastaPerl

#===============================================================================
sub convSeq2pir {
    local($exeConvSeqLoc,$file_in_loc,$file_out_loc,$fhTraceLoc,$frag,$fileScreenLoc)=@_;
    local($outformat,$an,$commandLoc);
#----------------------------------------------------------------------
#   convSeq2pir                 convert all sequence formats to PIR
#       in:                     $exeConvSeqLoc,$file_in_loc,$file_out_loc,$fhTraceLoc
#       in:                     $frage = 1-5, fragment from 1 -5 
#       err:                    ok=(1,'ok'), err=(0,'msg')
#----------------------------------------------------------------------
    $sbrName="lib-br:convSeq2Pir";
    return(0,"*** $sbrName: not def file_in_loc!")      if (! defined $file_in_loc);
    return(0,"*** $sbrName: not def file_out_loc!")     if (! defined $file_out_loc);
    return(0,"*** $sbrName: not def exeConvSeqLoc!")    if (! defined $exeConvSeqLoc);
    $fhTraceLoc="STDOUT"                                   if (! defined $fhTraceLoc);
    $frag=0                                             if (! defined $frag);
    $fileScreenLoc=0                                    if (! defined $fileScreenLoc);
				# check existence of files
    return(0,"*** $sbrName: no file '$file_in_loc'!")   if (! -e $file_in_loc);
    return(0,"*** $sbrName: no exe  '$exeConvSeqLoc'!") if (! -e $exeConvSeqLoc);

    $frag=0 if ($frag !~ /\-/);
                                # ------------------------------
    if ($frag){                 # extract fragments?
        $frag=~s/\s//g;
        ($beg,$end)=split('-',$frag);
        $frag=0 if ($beg =~/\D/ || $end =~ /\D/);}
				# ------------------------------
				# call FORTRAN program
    $cmd=              "";      # eschew warnings
    $outformat=        "P";     # output format PIR
    $an2=              "N";     # write another format?
    if ($frag){
        $an1=          "Y";     # do fragment
        $anF=          "$beg $end"; # answer for fragment
        eval "\$cmd=\"$exeConvSeqLoc,$file_in_loc,$outformat,$an1,$anF,$file_out_loc,$an2,\"";
        ($Lok,$msg)=
            &sysRunProg($cmd,$fileScreenLoc,$fhTraceLoc);}
    else {
        $an1=          "N";     # no fragment
        eval "\$cmd=\"$exeConvSeqLoc,$file_in_loc,$outformat,$an1,$file_out_loc,$an2,\"";
        ($Lok,$msg)=
            &sysRunProg($cmd,$fileScreenLoc,$fhTraceLoc);}

    return(0,"*** ERROR $sbrName: no output from FORTRAN convert_seq, couldnt run_program cmd=$cmd\n".
           $msg."\n") if (! $Lok || ! -e $file_out_loc);
    return(1,"ok $sbrName");
}				# end of convSeq2pir

#===============================================================================
sub convSeq2gcg {
    local($exeConvSeqLoc,$file_in_loc,$file_out_loc,$fhTraceLoc,$frag,$fileScreenLoc)=@_;
    local($outformat,$an,$commandLoc);
#----------------------------------------------------------------------
#   convSeq2gcg               convert all formats to gcg
#       in:                     $exeConvSeqLoc,$file_in_loc,$file_out_loc,$fhTraceLoc
#       in:                     $frage = 1-5, fragment from 1 -5 
#       out:                    
#       err:                    ok=(1,'ok'), err=(0,'msg')
#----------------------------------------------------------------------
    $sbrName="lib-br:convSeq2Gcg";
    return(0,"*** $sbrName: not def file_in_loc!")      if (! defined $file_in_loc);
    return(0,"*** $sbrName: not def file_out_loc!")     if (! defined $file_out_loc);
    return(0,"*** $sbrName: not def exeConvSeqLoc!")    if (! defined $exeConvSeqLoc);
    $fhTraceLoc="STDOUT"                                   if (! defined $fhTraceLoc);
    $frag=0                                             if (! defined $frag);
    $fileScreenLoc=0                                    if (! defined $fileScreenLoc);
				# check existence of files
    return(0,"*** $sbrName: no file '$file_in_loc'!")   if (! -e $file_in_loc);
    return(0,"*** $sbrName: no exe  '$exeConvSeqLoc'!") if (! -e $exeConvSeqLoc);

    $frag=0 if ($frag !~ /\-/);
                                # ------------------------------
    if ($frag){                 # extract fragments?
        $frag=~s/\s//g;
        ($beg,$end)=split('-',$frag);
        $frag=0 if ($beg =~/\D/ || $end =~ /\D/);}
				# ------------------------------
				# call FORTRAN program
    $cmd=              "";      # eschew warnings
    $outformat=        "G";     # output format GCG
    $an2=              "N";     # write another format?
    if ($frag){
        $an1=          "Y";     # do fragment
        $anF=          "$beg $end"; # answer for fragment
        eval "\$cmd=\"$exeConvSeqLoc,$file_in_loc,$outformat,$an1,$anF,$file_out_loc,$an2,\"";
        ($Lok,$msg)=
            &sysRunProg($cmd,$fileScreenLoc,$fhTraceLoc);}
    else {
        $an1=          "N";     # no fragment
        eval "\$cmd=\"$exeConvSeqLoc,$file_in_loc,$outformat,$an1,$file_out_loc,$an2,\"";
        ($Lok,$msg)=
            &sysRunProg($cmd,$fileScreenLoc,$fhTraceLoc);}

    return(&errSbrMsg("no output from FORTRAN convert_seq, couldnt run_program cmd=$cmd",
		      $msg)) if (! $Lok || ! -e $file_out_loc);
    return(1,"ok $sbrName");
}				# end of convSeq2gcg

#===============================================================================
sub convSeq2seq {
    local($exeConvSeqLoc,$fileInLoc,$fileOutLoc,$formOutLoc,$frag,$fileScreenLoc,$fhTraceLoc)=@_;
    local($outformat,$an,$commandLoc);
#----------------------------------------------------------------------
#   convSeq2seq                 convert all sequence-only formats to sequence only
#       in:                     $exeConvSeq,$fileIn,$fileOut,$formOutLoc,$frag,$fileScreen,$fhTraceLoc
#       in:                     $formOutLoc=  'FASTA|GCG|PIR'
#       in:                     $frage = 1-5, fragment from 1 -5 
#       out:                    file
#       err:                    ok=(1,'ok'), err=(0,'msg')
#----------------------------------------------------------------------
    $sbrName="lib-br:convSeq2Seq";
    $allow="fasta|pir|gcg";
    return(0,"*** $sbrName: not def exeConvSeqLoc!")    if (! defined $exeConvSeqLoc);
    return(0,"*** $sbrName: not def fileInLoc!")        if (! defined $fileInLoc);
    return(0,"*** $sbrName: not def fileOutLoc!")       if (! defined $fileOutLoc);
    return(0,"*** $sbrName: not def formOutLoc!")       if (! defined $formOutLoc);
    $fileScreenLoc=0                                    if (! defined $fileScreenLoc);
    $frag=0                                             if (! defined $frag);
    $fhTraceLoc="STDOUT"                                   if (! defined $fhTraceLoc);
				# check existence of files
    return(0,"*** $sbrName: no exe  '$exeConvSeqLoc'!") if (! -e $exeConvSeqLoc);
    return(0,"*** $sbrName: no file '$fileInLoc'!")     if (! -e $fileInLoc);
                                # check format
    $formOutLoc=~tr/[A-Z]/[a-z]/;
    return(0,"*** $sbrName: output format $formOutLoc not supported\n")
        if ($formOutLoc !~ /$allow/);
    $anFormOut=substr($formOutLoc,1,1);$anFormOut=~tr/[a-z]/[A-Z]/;
    $frag=0 if ($frag !~ /\-/);
                                # ------------------------------
    if ($frag){                 # extract fragments?
        $frag=~s/\s//g;
        ($beg,$end)=split('-',$frag);
        $frag=0 if ($beg =~/\D/ || $end =~ /\D/);}
				# ------------------------------
				# call FORTRAN program
    $cmd=              "";      # eschew warnings
    $an2=              "N";     # write another format?
    if ($frag){
        $an1=          "Y";     # do fragment
        $anF=          "$beg $end"; # answer for fragment
        eval "\$cmd=\"$exeConvSeqLoc,$fileInLoc,$anFormOut,$an1,$anF,$fileOutLoc,$an2,\"";
        ($Lok,$msg)=
            &sysRunProg($cmd,$fileScreenLoc,$fhTraceLoc);}
    else {
        $an1=          "N";     # no fragment
        eval "\$cmd=\"$exeConvSeqLoc,$fileInLoc,$anFormOut,$an1,$fileOutLoc,$an2,\"";
        ($Lok,$msg)=
            &sysRunProg($cmd,$fileScreenLoc,$fhTraceLoc);}

    return(&errSbrMsg("no output from FORTRAN convert_seq, could not run_program cmd=$cmd\n",
		      $msg)) if (! $Lok || ! -e $fileOutLoc);
    return(1,"ok $sbrName");
}				# end of convSeq2seq

#===============================================================================
sub copf2fasta {
    local($exeCopfLoc,$exeConvertSeqLoc,$extrLoc,$titleLoc,$extLoc,$dirWorkLoc,
	  $fileOutScreenLoc,$fhSbrErr,@fileInLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   copf2fasta                  runs copf.pl converting all input files to FASTA
#       in:                     $exeCopf       : perl script copf.pl          if = 0: default
#       in:                     $exeConvertSeq : FORTRAN exe convert_seq
#       in:                     $extrLoc       : number of file to extract from FASTAmul ..
#                                                                             if = 0: 1
#       in:                     $titleLoc      : title for temporary files    if = 0: 'TMP-$$'
#       in:                     $extLoc        : extension of output files    if = 0: '.fasta'
#       in:                     $dirWorkLoc    : working dir (for temp files) if = 0: ''
#       in:                     $fileOutScreen : screen dumpb of system call  if = 0: 0 -> STDOUT
#       in:                     $fhSbrErr      : error file handle
#       in:                     @fileInLoc     : array of input files
#       out:                    1|0,msg,@fileWritten
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."copf2fasta";$fhinLoc="FHIN_"."copf2fasta";
                                # ------------------------------
				# local defaults
    $exeCopfLocDef=             "/home/rost/perl/scr/copf.pl";
    $exeConvLocDef=             "/home/rost/pub/bin/convert_seq98.$ARCH";
                                # ------------------------------
				# check arguments
    $exeCopfLoc=$exeCopfLocDef  if (! defined $exeCopfLoc || ! $exeCopfLoc);
    $exeConvertSeqLoc=$exeConvLocDef 
	                        if (! defined $exeConvertSeqLoc || ! $exeConvertSeqLoc);
    $extrLoc=1                  if (! defined $extrLoc || ! $extrLoc);
    $titleLoc=  "TMP-".$$       if (! defined $titleLoc && ! $titleLoc);
    $extLoc=  ".fasta"          if (! defined $extLoc && ! $extLoc);
    $dirWorkLoc=  ""            if (! defined $dirWorkLoc && ! $dirWorkLoc);
    $dirWorkLoc.="/"            if ($dirWorkLoc !~/\/$/ && length($dirWorkLoc)>=1);
    $fhSbrErr="STDOUT"          if (! defined $fhSbrErr || ! $fhSbrErr);
    $fileOutScreenLoc=0         if (! defined $fileOutScreenLoc || ! $fileOutScreenLoc);

    $#fileTmp=0;
    $cmdSys="";
				# ------------------------------
				# loop over input files
				# ------------------------------
    foreach $fileLoc (@fileInLoc) {
	if (! -e $fileLoc){	# file missing
	    print $fhSbrErr 
		"-*- WARN $sbrName: missing file=$fileLoc\n";
	    next; }
	if (($extrLoc && ! &isFastaMul($fileLoc)) ||
	    &isFasta($fileLoc)){ # already FASTA format
	    push(@fileTmp,$fileLoc);
	    next; }
	$idIn=$fileLoc;$idIn=~s/^.*\/|\..*$//g;
				# ------------------------------
				# ... else RUN copf
	$fileOutTmp=$dirWorkLoc.$titleLoc.$idIn.$extLoc;

	$cmd= $exeCopfLoc." $fileLoc fasta extr=$extrLoc"."exeConvertSeq=".$exeConvertSeqLoc;
	$cmd.=" fileOut=$fileOutTmp";
	eval "\$cmdSys=\"$cmd\"";
	($Lok,$msg)=
	    &sysRunProg($cmdSys,$fileOutScreenLoc,$fhSbrErr);
	return(&errSbrMsg("failed convert $fileIn to FASTA ($fileOutTmp)",$msg)) 
	    if (! $Lok || ! -e $fileOutTmp);
	push(@fileTmp,$fileOutTmp);
    }
    return(1,"ok $sbrName",@fileTmp);
}				# end of copf2fasta

#================================================================================
sub correlation {
    local($ncol, @data) = @_;
    local($it, $av1, $av2, $av11, $av22, $av12);
    local(@v1,@v2,@v11,@v12,@v22, $den, $dentmp, $nom);
    $[ =1;
#----------------------------------------------------------------------
#   correlation                 compiles the correlation between x and y
#       in:                     ncol,@data, where $data[1..ncol] =@x, rest @y
#       out:                    returned $COR=correlation
#       out GLOBAL:             COR, AVE, VAR
#----------------------------------------------------------------------

    $#v1=0;$#v2=0;
    for ($it=1;$it<=$#data;++$it) {
	if ($it<=$ncol) { push(@v1,$data[$it]); }
	else            { push(@v2,$data[$it]); }
    }
#   ------------------------------
#   <1> and <2>
#   ------------------------------
    $av1=&stat_avevar(@v1); 
    $av2=&stat_avevar(@v2);

#   ------------------------------
#   <11> and <22> and <12y>
#   ------------------------------
    for ($it=1;$it<=$#v1;++$it) { $v11[$it]=$v1[$it]*$v1[$it];} $av11=&stat_avevar(@v11);
    for ($it=1;$it<=$#v2;++$it) { $v22[$it]=$v2[$it]*$v2[$it];} $av22=&stat_avevar(@v22);
    for ($it=1;$it<=$#v1;++$it) { $v12[$it]=$v1[$it]*$v2[$it];} $av12=&stat_avevar(@v12);

#   --------------------------------------------------
#   nom = <12> - <1><2>
#   den = sqrt ( (<11>-<1><1>)*(<22>-<2><2>) )
#   --------------------------------------------------
    $nom=($av12-($av1*$av2));
    $dentmp=( ($av11 - ($av1*$av1)) * ($av22 - ($av2*$av2)) );
    if ($dentmp>0) {$den=sqrt($dentmp);} else {$den="NN"}
    if ( ($den ne "NN") && (($den<-0.00000000001)||($den>0.00000000001) ) ) {
	$COR=$nom/$den;
    } else { $COR="NN" }
    return($COR);
}				# end of correlation

#===============================================================================
sub dafRdAli {
    local ($fileInLoc,$desHeader,$desExpect) = @_ ;
    local ($fhin,$tmp,$des,$Lend_ok,$ctPairs,$tmp2,$tmp1,@tmp,$idSeq,$idStr,$idxLoc,
	   $it,%Ldone,@colNames,$col,@desExpect,@desHeader,@colNamesRd,%rdLoc);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   dafRdAli                    read alignments from DAF format
#       in:
#				desHeader="key1,key2,...,keyn", where 'keyn' is the
#				key of one of the parameters used in header of file,
#				i.e. in the '#' section
#				desExpect="key1,key2,...,keyn", where 'keyn' is the
#				key of the n'th column with predefined name (others
#				e.g. zscore optionally named by user)
#       out:
#         $rd{} des_header: 	information from Header of file
#               "SOURCE"        name of original file (e.g. /data/hssp/1atf.hssp)
#         	"NPAIRS"  	number of pairs
#		"ALISYM" 	symbols allowed in alignment
#               "NSEARCH"       number of search proteins
#               "RELKEYS"       name of z-scores (separated by blanks)
#               "RELHISTO"      values for z-score intevalls
#               "ADDKEYS"       other key-names
# 
#		"COLNAMES"	names of columns used (separated by commata):
#				idSeq, idStr, lenSeq, lenStr, lenAli, pide, zscore,
#				seq, str, weightSeq
#         	"$id1,$id2"=$idx identifier of pair (1=seq, 2=str)
#         	"$n"		n'th id pair (idx="idSeq,idStr")
#         	"nZscore"	number of zscore's used
#         	"$idx","zscore","$n": 	n'th zscore for idx
#         	"$idx","seq"	sequence of 'sequence' (object of prediction) pair idx
#         	"$idx","str"	sequence of 'structure'(target of prediction)
#         	"$idx","seqLen"	length of entire 'sequence' (object of prediction) pair idx
#         	"$idx","strLen"	length of entire 'structure'(target of prediction)
#--------------------------------------------------------------------------------
    $desHeader=~s/^,|,$//g;@desHeader=split(/,/,$desHeader);
    $desExpect=~s/^,|,$//g;@desExpect=split(/,/,$desExpect);

    $fhin="FH_dafRdAli";
    &open_file("$fhin", "$fileInLoc");
				# ------------------------------
				# scan header
    while(<$fhin>){
	if ( (! /^\#/) || (/^\# ALIGNMENTS/) ) {
	    last;}
	foreach $des (@desHeader){
	    $desLower=$des;$desLower=~tr/[A-Z]/[a-z]/;
	    $lineRead=$_;$lineRead=~tr/[A-Z]/[a-z]/;
	    if ($lineRead=~/^\# $desLower/){ 
		$_=~s/\n//g;
		$_=~s/^#\s*\w+[\s|\t]*\:?[\s|\t]*|[\s|\t]*$//g;
		$rdLoc{"$des"}=$_;}}}
				# ------------------------------
				# additional columns defined?
    if (defined $rdLoc{"ADDKEYS"}){$tmp=$rdLoc{"ADDKEYS"};$tmp=~s/^\s*|^\t*|\s*$|\t*$//g;
				@tmp=split(/,/,$tmp);
				push(@desExpect,@tmp);}
				# ------------------------------
				# zscores given?
    if (defined $rdLoc{"RELKEYS"}){$tmp=$rdLoc{"RELKEYS"};$tmp=~s/^\s*|^\t*|\s*$|\t*$//g;
				@tmp=split(/,/,$tmp);
				push(@desExpect,@tmp);}

				# ------------------------------
    while(<$fhin>){		# read keys for column names 
	$_=~s/\n//g;		# = first line after '# ALIGNMENTS'
	$_=~s/^\t|^\s|\t$|\s$//g; # trailing tabs at ends
	@colNamesRd=split(/\t+|\s+/,$_);
	foreach $col(@colNamesRd){$col=~s/\s|\n//g;} # cut blanks
	last;}

    $#colNames=$#notFound=0;	# ------------------------------
    foreach $col(@colNamesRd){	# names read -> names expected
	$Lok=0;
	foreach $des(@desExpect){ 
	    $col2=$col;$col2=~tr/[A-Z]/[a-z]/;$des2=$des;$des2=~tr/[A-Z]/[a-z]/;
	    if ($col2 eq $des2){
		$Lok=1;push(@colNames,$des);
		last;}}
	if (!$Lok){push(@notFound,$col);}}

    $rdLoc{"COLNAMES"}="";		# append into string (',' separated)
    foreach $_ (@colNames){$rdLoc{"COLNAMES"}.="$_".","};$rdLoc{"COLNAMES"}=~s/^,*|,*$//g;

    if ($#notFound>0){		# consistency: all names valid?
	print "-*- WARNING dafRdAli: unexpected column names:\n";
	print "-*-                   ";&myprt_array(",",@notFound);}

				# allowed alignment symbols
    if (defined $rdLoc{"ALISYM"}){$ali_sym=$rdLoc{"ALISYM"};}
    else {$ali_sym=$rdLoc{"ALISYM"}="ACDEFGHIKLMNPQRSTVWY.acdefghiklmnpqrstvwy";}

    $Lend_ok=$ctPairs=0;
    %Ldone=0;
    				# --------------------------------------------------
    while(<$fhin>){		# read main data
	if (/^\#/) {		# ignore comments
	    next;}
	$_=~s/^\t|^\s|\t$|\s$//g; # trailing tabs at ends
	$_=~s/\n//g;
	@tmp=split(/\t+|\s+/,$_);	# split columns
				# process identifiers (first 2 columns)
	$idSeq=$tmp[1];$idSeq=~s/\s//g;
	$idStr=$tmp[2];$idStr=~s/\s//g;
	$idxLoc="$idSeq".","."$idStr";
				# ignore second event of same pair
	if ((! defined $Ldone{"$idxLoc"}) || (! $Ldone{"$idxLoc"}) ) {
	    $Ldone{"$idxLoc"}=1;}
        else {
	    next;}
	++$ctPairs;
	$rdLoc{"$ctPairs"}="$idxLoc";
				# read columns 3 - all
	foreach $it (3..$#colNames) {
	    $tmp[$it]=~tr/[a-z]/[A-Z]/;	# lower case to upper case
	    if (defined $tmp[$it]) {
	    	$rdLoc{"$idxLoc","$colNames[$it]"}=$tmp[$it];}
	    else {
		$rdLoc{"$idxLoc","$colNames[$it]"}=$tmp[$it];}}
    }
    $rdLoc{"NPAIRS"}=$ctPairs;
    close($fhin);
#    @keys=keys %rdLoc;
    return (%rdLoc);
}				# end of dafRdAli

#===============================================================================
sub dafWrtAli {
    local ($file,$sep,$desHeader,$colNames,%wrt) = @_ ;
    local ($idSeq,$idStr,$idxLoc,@colNames,$fhout,$ct,$tmp);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   dafWrtAli                   writes a file in output format of DAF
#       in:
#         $wrt{}des_header: 	information from Header of file (passed "des1,des2")
#         	"NPAIRS"  	number of pairs
#		"ALISYM" 	symbols allowed in alignment
#               "NSEARCH"       number of search proteins
#               "RELKEYS"       name of z-scores (separated by blanks)
#               "RELHISTO"      values for z-score intevalls
#               "ADDKEYS"       other key-names
# 
#		"COLNAMES"	names of columns used (separated by commata):
#				idSeq, idStr, lenSeq, lenStr, lenAli, pide, zscore,
#				seq, str, weightSeq
#         	"$id1,$id2"=$idx identifier of pair (1=seq, 2=str)
#         	"$n"		n'th id pair (idx="idSeq,idStr")
#         	"nZscore"	number of zscore's used
#         	"$idx","zscore","$n": 	n'th zscore for idx
#         	"$idx","seq"	sequence of 'sequence' (object of prediction) pair idx
#         	"$idx","str"	sequence of 'structure'(target of prediction)
#         	"$idx","seqLen"	length of entire 'sequence' (object of prediction) pair idx
#         	"$idx","strLen"	length of entire 'structure'(target of prediction)
#--------------------------------------------------------------------------------
    $fhout="FH_dafWrtAli";	# ini
    &open_file("$fhout",">$file");

    @colNames=			# write header
    	&dafWrtAliHeader($fhout,$sep,$desHeader,$colNames);

    $ct=1;			# ----------------------------------------
    while (defined $wrt{"$ct"}){ # write all columns 
	$idxLoc=$wrt{"$ct"};
	($idSeq,$idStr)=split(/,/,$wrt{"$ct"});
	print $fhout "$idSeq$sep$idStr$sep";
	foreach $col (@colNames){
	    if (defined $wrt{"$idxLoc","$col"}){
		print $fhout $wrt{"$idxLoc","$col"};}
	    else {
		print $fhout "";}
	    if ($col eq $colNames[$#colNames]){ $tmp="\n";}else{$tmp=$sep;}
	    print $fhout $tmp;}
	++$ct;}
    print $fhout "\n";
    close($fhout);
}				# end of dafWrtAli

#===============================================================================
sub dafWrtAliHeader {
    local ($fhout,$sep,$desHeader,$colNames) = @_ ;
    local (@desHeader,@colNames);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   dafWrtAliHeader             writes the header for DAF file
#--------------------------------------------------------------------------------
    $desHeader=~s/^,|,$//g;	# process header
    @desHeader=split(/,/,$desHeader);
    $colNames=~s/^,|,$//g;	# process column names
    @colNames=split(/,/,$colNames);
				# variables
    print $fhout "# DAF (dirty alignment format for exchange with Aqua)\n# \n";
    foreach $des (@desHeader){
	if ($des =~ /^COLNAMES/) {
	    next;}
	printf $fhout "# %-8s: \t %-s\n",$des,$wrt{"$des"}; }
				# column names
    printf $fhout "# %-8s:\t %-s\n","COLNAMES",$colNames;
				# notations
    print $fhout 
 	"# \n",
	"# NOTATION:\t ALISYM  symbols allowed in alignments\n",
	"# NOTATION:\t NPAIRS  number of pairs aligned\n",
	"#\n",
	"# NOTATION:\t idSeq   identifier of 'Sequence', i.e. the search protein\n",
	"# NOTATION:\t idStr   identifier of 'Structure', i.e. the template which you aligned\n",
	"# NOTATION:\t lenSeq  length of protein (or chain, or domain) of 'Sequence'\n",
	"# NOTATION:\t lenStr  length of protein (or chain, or domain) of 'Structure'\n",
	"# NOTATION:\t lenAli  number of residues aligned\n",
	"# NOTATION:\t pide    percentage of sequence identity = Nidentical/Naligned residues\n",
	"# NOTATION:\t zscore  your score describing the significance of the hit \n",
	"# NOTATION:\t         (more than 1 column, and any key allowed)\n",
	"# NOTATION:\t seq     sequence of 'Sequence'\n",
	"# NOTATION:\t str     sequence of 'Structure'\n",
	"# NOTATION:\t weightSeq residue specific weight you may attach to the alignment\n",
	"# NOTATION:\t \n",
	"#\n";   
    print $fhout "# ALIGNMENTS\n";
    foreach $it(1..($#colNames-1)){ print $fhout $colNames[$it],"$sep";} 
    print $fhout $colNames[$#colNames],"\n";
    return(@colNames);
}				# end of dafWrtAliHeader

#===============================================================================
sub dsspGetChain {
    local ($fileIn,$chainIn,$begIn,$endIn) = @_ ;
    local ($Lread,$sbrName,$fhin,$aa,$aa2,$seq,$seqC,$chainRd,$pos);
    $[=1;
#----------------------------------------------------------------------
#   dsspGetChain                extracts all chains from DSSP
#       in:                     $file
#       out:                    $Lok,$tmp{"chains"}='C,D,...'
#       out:                         $tmp{"$chain","beg"},$tmp{"$chain","end"},
#----------------------------------------------------------------------
    $sbrName = "lib-br:dsspGetChain" ;$fhin="fhinDssp";
    &open_file("$fhin","$fileIn") ||
        return(0,"*** ERROR $sbrName: failed to open input $fileIn\n");
				#--------------------------------------------------
    while ( <$fhin> ) {		# read in file
	last if ( /^  \#  RESIDUE/ ); }	# skip anything before data...
    undef %tmp;
    $chainNow=$chains="";
    while ( <$fhin> ) {		# read chain
	$Lread=1;
	$chainRd=substr($_,12,1); $chainRd="*" if ($chainRd eq " ");
	$pos=    substr($_,7,5); $pos=~s/\s//g;
	if ($chainRd ne $chainNow){$chainNow=$chainRd;
				   $chains.=$chainRd.",";
				   $tmp{"$chainRd","beg"}=$pos;}
	else                      {$tmp{"$chainRd","end"}=$pos;}}close($fhin);
    $chains=~s/^,*|,*$//g;$tmp{"chains"}=$chains;
    return(1,%tmp);
}                               # end of: dsspGetChain 

#===============================================================================
sub dsspGetFile { 
    local ($fileInLoc,$Lscreen,@dir) = @_ ; 
    local ($fileDssp,$dir,$tmp,$chainLoc,@dir2,$idLoc);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   dsspGetFile                 searches all directories for existing DSSP file
#       in:                     $file,$Lscreen,@dir
#       out:                    returned file,chain ($dssp,$chain), (if chain in file)
#       watch:                  loop onto itself:
#                               1prcH.dssp not found -> try 1prc.dssp
#--------------------------------------------------------------------------------
    $#dir2=$Lok=0;
    return(0,"no input file")   if (! defined $fileInLoc);
    $chainLoc="";$idLoc=$fileInLoc;$idLoc=~s/^.*\///g;
    $#dir=0                     if (! defined @dir);
    $Lscreen=0                  if (! defined $Lscreen);
    if (-d $Lscreen) { 
	@dir=($Lscreen,@dir);
	$Lscreen=0;}
    $dsspFileTmp=$fileInLoc;$dsspFileTmp=~s/\s|\n//g;
				# ------------------------------
				# is DSSP ok
    return($dsspFileTmp," ")    if (-e $dsspFileTmp && &is_dssp($dsspFileTmp));

				# ------------------------------
				# purge chain?
    if ($dsspFileTmp=~/^(.*\.dssp)_?([A-Za-z0-9])$/){
	$file=$1; $chain=$2;
	return($file,$chain)    if (-e $file && &is_dssp($file)); }

				# ------------------------------
				# try adding directories

    foreach $dir(@dir){		# avoid endless loop when calling itself
	$Lok=1                  if ($dir =~ /\/data\/dssp/);
	push(@dir2,$dir);}
    @dir=@dir2;  push(@dir,"/data/dssp/") if (!$Lok); # give default

				# loop over all directories
    $fileDssp=
	&dsspGetFileLoop($dsspFileTmp,$Lscreen,@dir);

				# ------------------------------
    if ( ! -e $fileDssp ) {	# still not: dissect into 'id'.'chain'
	$tmp_file=$fileInLoc; $tmp_file=~s/^([A-Za-z0-9]+).*(\.dssp.*)$/$1$2/g;
	$fileDssp=
	    &dsspGetFileLoop($tmp_file,$Lscreen,@dir);}

				# ------------------------------
				# change version of file (1sha->2sha)
    if ( ! -e $fileDssp) {
	$tmp1=substr($idLoc,2,3);
	foreach $it (1..9) {
	    $tmp_file="$it"."$tmp1".".dssp";
	    $fileDssp=
		&dsspGetFileLoop($tmp_file,$Lscreen,@dir);}}
    return (0)                  if ( ! -e $fileDssp);

    return($fileDssp,$chainLoc);
}				# end of dsspGetFile

#===============================================================================
sub dsspGetFileLoop { 
    local ($fileInLoop,$Lscreen,@dir) = @_ ; 
    local ($fileOutLoop,$dir,$tmp);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   dsspGetFileLoop             loops over all directories
#       in:                     $file,$Lscreen,@dir
#       out:                    returned file
#--------------------------------------------------------------------------------
				# already ok 
    return($fileInLoop)         if (&is_dssp($fileInLoop));
				# missing extension
    $fileInLoop.=".dssp"        if ($fileInLoop !~ /\.dssp/);
				# already ok 
    return($fileInLoop)         if (&is_dssp($fileInLoop));
				# do NOT continue if starting with dir!!
    return(0)                   if ($fileInLoop =~ /^\//);

				# ------------------------------
    foreach $dir (@dir) {	# search through dirs
	$tmp=&complete_dir($dir) . $fileInLoop; # try directory
	print "--- dsspGetFileLoop: \t trying '$tmp'\n" if ($Lscreen);
	return($tmp)            if (-e $tmp && &is_dssp($tmp) );
    }
    return(0);			# none found
}				# end of dsspGetFileLoop

#===============================================================================
sub dsspRdSeq {
    local ($fileIn,$chainIn,$begIn,$endIn) = @_ ;
    local ($Lread,$sbrName,$fhin,$aa,$aa2,$seq,$seqC,$chainRd,$pos);
    $[=1;
#----------------------------------------------------------------------
#   dsspRdSeq                   extracts the sequence from DSSP
#       in:                     $file,$chain,$beg,$end
#       in:                     for wild cards beg="", end=""
#       out:                    $Lok,$seq,$seqC (second replaced a-z to C)
#----------------------------------------------------------------------
    $sbrName = "lib-br:dsspRdSeq" ;$fhin="fhinDssp";
    &open_file("$fhin","$fileIn") ||
        return(0,"*** ERROR $sbrName: failed to open input $fileIn\n");
				#----------------------------------------
				# extract input
    if (defined $chainIn && length($chainIn)>0 && $chainIn=~/[A-Z0-9]/){
	$chainIn=~s/\s//g;$chainIn =~tr/[a-z]/[A-Z]/; }else{$chainIn = "*" ;}
    $begIn = "*" if (! defined $begIn || length($begIn)==0); $begIn=~s/\s//g;;
    $endIn = "*" if (! defined $endIn || length($endIn)==0); $endIn=~s/\s//g;;
				#--------------------------------------------------
				# read in file
    while ( <$fhin> ) { 
	last if ( /^  \#  RESIDUE/ ); }	# skip anything before data...
    $seq=$seqC="";
    while ( <$fhin> ) {		# read sequence
	$Lread=1;
	$chainRd=substr($_,12,1); 
	$pos=    substr($_,7,5); $pos=~s/\s//g;

	next  if (($chainRd ne "$chainIn" && $chainIn ne "*" ) || # check chain
                  ($begIn ne "*"  && $pos < $begIn) || # check begin
                  ($endIn ne "*"  && $pos > $endIn)) ; # check end

	$aa=substr($_,14,1);
	$aa2=$aa;if ($aa2=~/[a-z]/){$aa2="C";}	# lower case to C
	$seq.=$aa;$seqC.=$aa2; } close ($fhin);
    return(1,$seq,$seqC) if (length($seq)>0);
    return(0);
}                               # end of: dsspRdSeq 

#===============================================================================
sub equal_tolerance { 
    local($v1,$v2,$tol)=@_; 
#-------------------------------------------------------------------------------
#   equal_tolerance             returns 0, if v1==v2 +- $tol
#-------------------------------------------------------------------------------
    return(0) if ( $v1 < ($v2-$tol) || $v1 > ($v2+$tol) );
    return(1);
}				# end of equal_tolerance

#===============================================================================
sub errSbr    {local($txtInLoc,$sbrNameLocy) = @_ ;
#-------------------------------------------------------------------------------
#   errSbr                      simply writes '*** ERROR $sbrName: $txtInLoc'
#-------------------------------------------------------------------------------
	       $sbrNameLocy=$sbrName if (! defined $sbrNameLocy);
	       $txtInLoc.="\n";
	       $txtInLoc=~s/\n\n+/\n/g;
	       return(0,"*** ERROR $sbrNameLocy: $txtInLoc");
}				# end of errSbr

#===============================================================================
sub errSbrMsg {local($txtInLoc,$msgInLoc,$sbrNameLocy) = @_ ;
#-------------------------------------------------------------------------------
#   errSbrMsg                   simply writes '*** ERROR $sbrName: $txtInLoc\n'.$msg
#-------------------------------------------------------------------------------
	       $sbrNameLocy=$sbrName if (! defined $sbrNameLocy);
	       $txtInLoc.="\n";
	       $txtInLoc=~s/\n\n+/\n/g;
	       $msgInLoc.="\n";
	       $msgInLoc=~s/\n\n+/\n/g;
	       return(0,"*** ERROR $sbrNameLocy: $txtInLoc".$msgInLoc);
}				# end of errSbrMsg

#===============================================================================
sub evalsecTableqils2syn {
    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   evalsecTableqils2syn        greps the final summary from TABLEQILS (xevalsec.f)
#       in:                     $fileInLoc
#       out:                    1|0,msg, $tmpWrt (sprintf)
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."evalsecTableqils2syn";$fhinLoc="FHIN_"."evalsecTableqils2syn";
				# ------------------------------
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
#    return(&errSbr("not def !"))          if (! defined $);

    return(&errSbr("miss in file '$fileInLoc'!"))  if (! -e $fileInLoc);
				# ------------------------------
				# open file
    &open_file("$fhinLoc","$fileInLoc") || return(&errSbr("fileInLoc=$fileInLoc, not opened"));
				# ------------------------------
    while (<$fhinLoc>) {	# read until ' --- \s for all '
	$tmp=$_;
	last if ($_=~/^ \-+\s+for all\s+/); }
				# build up wrt
    $tmpWrt1=      "$tmp";
				# ------------------------------
    while (<$fhinLoc>) {	# read until blank line
	last if ($_!~/^ [\+\|]/); 
	$tmpWrt1.= "$_"; }
				# ------------------------------
    while (<$fhinLoc>) {	# read until correlation
	$_=~s/\n//g; $rd=$_;
	if ($rd=~/^.*Q3mean =\s+([0-9\.]+)\s+/){
	    $aveProtQ3=$1;
	    next; }
	if ($rd=~/^.*sqrt\( Q3var \) =\s+([0-9\.]+)\s+/){
	    $aveProtSig=$1;
	    next; }
	$tmp=$rd; $tmp=~s/^\s\-+\s*//g;
	next if (length($tmp)<1);
	if ($rd=~/all.* contav .([HE])\s*=\s*([0-9\.]+)\s.*=\s*([0-9\.]+)/){
	    if    ($1 eq "H"){
		$contHdel=$2; $contHsig=$3; }
	    elsif ($1 eq "E"){
		$contEdel=$2; $contEsig=$3; }
	    next; }
	last if ($rd=~/Correlation coeffi/); }

    $tmpWrt2=      "$rd\n"; 
				# ------------------------------
    while (<$fhinLoc>) {	# read class
	$_=~s/\n//g; $rd=$_;
	$tmp=$rd; $tmp=~s/^\s\-+\s*//g;
	next if (length($tmp)<1);
	$tmpWrt2.= "$rd\n"; }
    close($fhinLoc);
				# ------------------------------
				# process
    $tmpWrt= $tmpWrt2;
    $tmpWrt.=$tmpWrt1;
				# overall table 
    @tmp=split(/\n/,$tmpWrt1);
    foreach $tmp (@tmp){
	if ($tmp =~ /\|                                    \|(.*)$/){
	    $tmp=$1;
	    $tmp=~s/\|                   \|.*$//g;
	    $tmp=~s/\|/ /g;
	    @num=split(/\s+/,$tmp);
	    @cor[1..3]=@num[1..3];
	    $q3=$num[4]; 
	    next; }
	if ($tmp =~ /^\s*\|\s*SOV\s*\|\s*(.+)$/){
	    $tmp=$1; $tmp=~s/\|/ /g;
	    $tmp=~s/^\s*|\s*$//g;
	    @num=split(/\s+/,$tmp);
	    $sovObs=$num[4];
	    $sovPrd=$num[8];
	    $info=$num[9]; $info=~s/\s([0-9\.]+)\s*.*$/$1/g;
	}}
				# class acc
    @tmp=split(/\n/,$tmpWrt2);
    foreach $tmp (@tmp){
	if ($tmp=~/.*SUM\s*\|\s*(.*)$/){
	    $tmp=$1; $tmp=~s/\|/ /g;
	    $tmp=~s/^\s*|\s*$//g;
	    @num=split(/\s+/,$tmp);
	    $classObs=$num[4]; $classPrd=$num[5];
	}
    }
				# sec str content
    $fcor= "%5.2f,%5.2f,%5.2f";
    $fcont="%5.1f,%5.1f";

    $tmpWrt.=sprintf("%-30s %5.1f,%5.1f\n",       "SYN Q4class  obs,prd:",$classObs,$classPrd);
    $tmpWrt.=sprintf("%-30s $fcont ($fcont)\n",   "SYN DcontH,E   (sig):",
		     $contHdel,$contEdel,$contHsig,$contEsig);
				# protein averages
    $tmpWrt.=sprintf("%-30s %6.2f %-4s ($fcor)\n","SYN I     (corH,E,L):",$info," ",@cor);
    $tmpWrt.=sprintf("%-30s %5.1f,%5.1f\n",       "SYN SOV      obs,prd:",$sovObs,$sovPrd);
    $tmpWrt.=sprintf("%-30s %5.1f %-5s (%5.1f)\n","SYN Q3prot     (sig):",$aveProtQ3," ",$aveProtSig);
    $tmpWrt.=sprintf("%-30s %5.1f \n",            "SYN Q3res           :",$q3);
		     
    return(1,"ok $sbrName",$tmpWrt);
}				# end of evalsecTableqils2syn 

#===============================================================================
sub evalseg_oneprotein {
    local ($sec,$prd)=@_;
    local ($ctseg, $ct, $tmp, $it, $it2, $sym, $symprev, $ctnotloop);
    local (@seg, @ptr, @segbeg);
    $[ =1;
#--------------------------------------------------
#   evalseg_oneprotein          evaluates the pred accuracy as HTM segments
#   GLOBAL:
#   out:   $NOBS, $NOBSH, $NOBSL, $NPRD, $NPRDH, $NPRDL
#          $NCP, $NCPH, $NCPL, $NUP, $NOP, $NLONG
#--------------------------------------------------

#   ----------------------------------------
#   extract segments into @seg
#   ----------------------------------------
    $ctseg=0; $symprev=")"; $#seg=$#ptr=$#segbeg=$ctnotloop=0;
    for($it=1;$it<=length($prd);++$it) {
        $sym=substr($prd,$it,1); 
        if ( $sym ne $symprev ) { 
            ++$ctseg; $symprev=$sym;
            $seg[$ctseg]=$sym; $ptr[$ctseg]="$it"."-"; $segbeg[$ctseg]=$it;
            if ($sym ne " ") { ++$ctnotloop; }}
	else { $seg[$ctseg].=$sym; $ptr[$ctseg].="$it"."-";}}

#   ----------------------------------------
#   count observed segments
#   ----------------------------------------
    @atmp1=split(/\s+/,$sec); @atmp2=split(/H+/,$sec);

#   --------------------
#   splice empty
    $#atmp=0;
    for($it=1;$it<=$#atmp1;++$it) {if (length($atmp1[$it])>=1) {push(@atmp,$atmp1[$it]);}}
    $#atmp1=0;@atmp1=@atmp;

    $#atmp=0;
    for($it=1;$it<=$#atmp2;++$it) {if (length($atmp2[$it])>=1) {push(@atmp,$atmp2[$it]);}}
    $#atmp2=0;@atmp2=@atmp;
	
#   --------------------
#   counts
    $NOBS=$NPRDL=0;		# satisfy -w
    $NOBSH=$#atmp1;$NOBSL=$#atmp2;  $NOBS=$NOBSH+$NOBSL;
    $NPRDH=$ctnotloop;$NPRD=$#seg;  $NPRDL=$NPRD-$NPRDH;

#   ----------------------------------------
#   count correct, over-, underprediction
#   and segments merged (n->1)
#   ----------------------------------------
    $NCP=$NUP=$NOP=$NLONG=$NCPH=$NCPL=0;
    for ($it=1;$it<=$#seg;++$it) {

#       ------------------------------
#       predicted helix
	if ($seg[$it]=~/H/) {
	    $tmp=substr($sec,$segbeg[$it],length($seg[$it]));
#           -------------------------
#           correctly predicted helix
	    if ( ($tmp=~/HHH/)&&($tmp!~/H+\s+H+/) ) {++$NCP;++$NCPH;}
		
#           -------------------------
#           too long helix correct 
	    elsif ( $tmp=~/H+\s+H+/ ) {++$NLONG;}

#           ---------------------
#           over-predicted helix
	    else {++$NOP;--$NCP;--$NCPL;} }

#       ------------------------------
#       predicted non-helix
	else {
	    $tmp=substr($sec,$segbeg[$it],length($seg[$it]));
#           ------------------------                   #----------------------
#           correctly predicted loop                   # under-predicted helix
	    if ($tmp!~/HHHHHHHHHHH/) {++$NCP;++$NCPL;} else{++$NUP;} }
    }
}                               # end of evalseg_oneprotein

#==========================================================================
sub exposure_normalise_prepare {
    local ($mode) = @_;
    $[=1;
#----------------------------------------------------------------------
#   exposure_normalise_prepare  normalisation weights (maximal: Schneider, Dipl)
#----------------------------------------------------------------------
#   --------------------------------------------------
#   Reinhard
#   --------------------------------------------------
    if ((!defined $mode)||(length($mode) <= 1)) {
	$NORM_EXP{"A"} =106;  $NORM_EXP{"B"} =160;         # D or N
	$NORM_EXP{"C"} =135;  $NORM_EXP{"D"} =163;  $NORM_EXP{"E"} =194;
	$NORM_EXP{"F"} =197;  $NORM_EXP{"G"} = 84;  $NORM_EXP{"H"} =184;
	$NORM_EXP{"I"} =169;  $NORM_EXP{"K"} =205;  $NORM_EXP{"L"} =164;
	$NORM_EXP{"M"} =188;  $NORM_EXP{"N"} =157;  $NORM_EXP{"P"} =136;
	$NORM_EXP{"Q"} =198;  $NORM_EXP{"R"} =248;  $NORM_EXP{"S"} =130;
	$NORM_EXP{"T"} =142;  $NORM_EXP{"V"} =142;  $NORM_EXP{"W"} =227;
	$NORM_EXP{"X"} =180;         # undetermined (deliberate)
	$NORM_EXP{"Y"} =222;  $NORM_EXP{"Z"} =196;         # E or Q

#   --------------------------------------------------
#   maximal 3 Angstrom water
#   --------------------------------------------------
    } elsif ($mode =~ /3ang/ ) {
	$NORM_EXP{"A"} =179;  $NORM_EXP{"B"} =255;         # D or N
	$NORM_EXP{"C"} = 99;  $NORM_EXP{"D"} =249;  $NORM_EXP{"E"} =279;
	$NORM_EXP{"F"} =199;  $NORM_EXP{"G"} =169;  $NORM_EXP{"H"} =219;
	$NORM_EXP{"I"} =189;  $NORM_EXP{"K"} =309;  $NORM_EXP{"L"} =209;
	$NORM_EXP{"M"} =189;  $NORM_EXP{"N"} =259;  $NORM_EXP{"P"} =189;
	$NORM_EXP{"Q"} =259;  $NORM_EXP{"R"} =299;  $NORM_EXP{"S"} =209;
	$NORM_EXP{"T"} =209;  $NORM_EXP{"V"} =189;  $NORM_EXP{"W"} =239;
	$NORM_EXP{"X"} =200;         # undetermined (deliberate)
	$NORM_EXP{"Y"} =239;  $NORM_EXP{"Z"} =269;         # E or Q

#   --------------------------------------------------
#   maximal 5 Angstrom water
#   --------------------------------------------------
    } elsif ($mode =~ /5ang/ ) {
	$NORM_EXP{"A"} =209;  $NORM_EXP{"B"} =295;         # D or N
	$NORM_EXP{"C"} =139;  $NORM_EXP{"D"} =289;  $NORM_EXP{"E"} =349;
	$NORM_EXP{"F"} =199;  $NORM_EXP{"G"} =219;  $NORM_EXP{"H"} =229;
	$NORM_EXP{"I"} =189;  $NORM_EXP{"K"} =399;  $NORM_EXP{"L"} =239;
	$NORM_EXP{"M"} =189;  $NORM_EXP{"N"} =299;  $NORM_EXP{"P"} =189;
	$NORM_EXP{"Q"} =309;  $NORM_EXP{"R"} =309;  $NORM_EXP{"S"} =259;
	$NORM_EXP{"T"} =239;  $NORM_EXP{"V"} =189;  $NORM_EXP{"W"} =259;
	$NORM_EXP{"X"} =230;         # undetermined (deliberate)
	$NORM_EXP{"Y"} =259;  $NORM_EXP{"Z"} =329;         # E or Q

#   --------------------------------------------------
#   maximal 0.7 Angstrom water
#   --------------------------------------------------
    } elsif ($mode =~ /07ang/ ) {
	$NORM_EXP{"A"} =119;  $NORM_EXP{"B"} =169;         # D or N
	$NORM_EXP{"C"} = 99;  $NORM_EXP{"D"} =169;  $NORM_EXP{"E"} =179;
	$NORM_EXP{"F"} =169;  $NORM_EXP{"G"} =109;  $NORM_EXP{"H"} =173;
	$NORM_EXP{"I"} =159;  $NORM_EXP{"K"} =206;  $NORM_EXP{"L"} =159;
	$NORM_EXP{"M"} =159;  $NORM_EXP{"N"} =169;  $NORM_EXP{"P"} =149;
	$NORM_EXP{"Q"} =169;  $NORM_EXP{"R"} =209;  $NORM_EXP{"S"} =139;
	$NORM_EXP{"T"} =149;  $NORM_EXP{"V"} =149;  $NORM_EXP{"W"} =169;
	$NORM_EXP{"X"} =230;         # undetermined (deliberate)
	$NORM_EXP{"Y"} =189;  $NORM_EXP{"Z"} =175;         # E or Q

#   --------------------------------------------------
#   RS (X=0, from Reinhard
#   --------------------------------------------------
    } elsif ($mode =~/RS/) {
	$NORM_EXP{"A"} =106;  $NORM_EXP{"B"} =157;         # D or N
	$NORM_EXP{"C"} =135;  $NORM_EXP{"D"} =163;  $NORM_EXP{"E"} =194;
	$NORM_EXP{"F"} =197;  $NORM_EXP{"G"} = 84;  $NORM_EXP{"H"} =184;
	$NORM_EXP{"I"} =169;  $NORM_EXP{"K"} =205;  $NORM_EXP{"L"} =164;
	$NORM_EXP{"M"} =188;  $NORM_EXP{"N"} =157;  $NORM_EXP{"P"} =136;
	$NORM_EXP{"Q"} =198;  $NORM_EXP{"R"} =248;  $NORM_EXP{"S"} =130;
	$NORM_EXP{"T"} =142;  $NORM_EXP{"V"} =142;  $NORM_EXP{"W"} =227;
	$NORM_EXP{"X"} =180;         # undetermined (deliberate)
	$NORM_EXP{"Y"} =222;  $NORM_EXP{"Z"} =194;         # E or Q

#   --------------------------------------------------
#   Reinhard
#   --------------------------------------------------
    } else {
	$NORM_EXP{"A"} =106;  $NORM_EXP{"B"} =160;         # D or N
	$NORM_EXP{"C"} =135;  $NORM_EXP{"D"} =163;  $NORM_EXP{"E"} =194;
	$NORM_EXP{"F"} =197;  $NORM_EXP{"G"} = 84;  $NORM_EXP{"H"} =184;
	$NORM_EXP{"I"} =169;  $NORM_EXP{"K"} =205;  $NORM_EXP{"L"} =164;
	$NORM_EXP{"M"} =188;  $NORM_EXP{"N"} =157;  $NORM_EXP{"P"} =136;
	$NORM_EXP{"Q"} =198;  $NORM_EXP{"R"} =248;  $NORM_EXP{"S"} =130;
	$NORM_EXP{"T"} =142;  $NORM_EXP{"V"} =142;  $NORM_EXP{"W"} =227;
	$NORM_EXP{"X"} =180;         # undetermined (deliberate)
	$NORM_EXP{"Y"} =222;  $NORM_EXP{"Z"} =196;         # E or Q
    }
}				# end of exposure_normalise_prepare 

#===============================================================================
sub exposure_normalise {
    local ($exp_in, $aa_in) = @_;
    $[=1;
#----------------------------------------------------------------------
#   exposure_normalise          normalise DSSP accessibility with maximal values
#                               (taken from Schneider)
#----------------------------------------------------------------------
    if ( $aa_in !~ /[ABCDEFGHIKLMNPQRSTUVWXYZ]/ ) {
	if ( $aa_in=~/[!.]/ ) { $aa_in = "X"; }
	else { print "*** ERROR in exposure_normalise: aa passed wrong: '$aa_in' \n";
	       exit; }}

    if ($NORM_EXP{$aa_in}>0) { $exp_normalise= 100 * ($exp_in / $NORM_EXP{$aa_in});}
    else { print "*** \n*** exposure_normalise, division by zero:aa=$aa_in,acc=$exp_in,norm=",
	   $NORM_EXP{$aa_in},"\n***\n";
	   $exp_normalise=$exp_in/1.8; # ugly ...
	   if ($exp_normalise>100){$exp_normalise=100;}}
    return $exp_normalise;
}				# end of exposure_normalise

#===============================================================================
sub exposure_project_1digit {
    local ($exp_in) = @_;
    local ($exp_out);
    $[=1;
#----------------------------------------------------------------------
#   exposure_project_1digi      project relative exposure (relative) onto numbers 0-9
#                               by: n = max ( 9 , int(sqrt (rel_exp)) )
#----------------------------------------------------------------------
    if ( $exp_in < 0 ) {        # check input
        print "*** ERROR exposure_project_1digit: exposure in = $exp_in \n"; 
	exit;}
    $exp_out = int ( sqrt ($exp_in) );
                                # limit to 9
    if ( $exp_out >= 10 ) { $exp_out = 9; }
    $exposure_project_1digit = $exp_out;
    return($exp_out);
}				# end of exposure_project_1digit

#===============================================================================
sub extract_pdbid_from_hssp {
    local ($idloc) = @_;
    local ($fhssp,$tmp,$id);
    $[=1;
#----------------------------------------------------------------------
#   extract_pdbid_from_hssp     extracts all PDB ids found in the HSSP 0 header
#                               note: existence of HSSP file assumed
#   GLOBAL
#   -  $PDBIDS_IN_HSSP "1acx,2bdy,3cez,"...
#----------------------------------------------------------------------
    $idloc=~tr/[A-Z]/[a-z]/;
    $fhssp="/data/hssp+0/"."$idloc".".hssp";
    if (!-e $fhssp) { 
	print "***  ERROR in sbr extract_pdbid_from_hssp:$fhssp, not existing\n"; exit;}
    &open_file("FHINTMP1", "$fhssp");
    while (<FHINTMP1>) { last if (/^  NR.    ID/); }

    while (<FHINTMP1>) { 
	last if (/^\#\# ALI/);
	$tmp=$_;$tmp=~s/\n//g;
	$id=substr($_,21,4); $id=~tr/[A-Z]/[a-z]/; $id=~s/\s//g;
	if (length($id)>0) {$PDBIDS_IN_HSSP.="$id".",";}
    }
    close (FHINTMP1);return($PDBIDS_IN_HSSP);
}				# end of extract_pdbid_from_hssp

#===============================================================================
sub fastaRdGuide {
    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   fastaRdGuide                reads first sequence in list of FASTA format
#       in:                     $fileInLoc,$fhErrSbr
#       out:                    0|1,$id,$seq
#       err:                    ok=(1,id,seq), err=(0,'msg',)
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."fastaRdGuide";$fhinLoc="FHIN"."$sbrName";

    $Lok=       &open_file("$fhinLoc","$fileInLoc");
    return(0,"*** ERROR $sbrName: old '$fileInLoc' not opened\n"," ") if (! $Lok);
    $ct=0;$seq="";
    while (<$fhinLoc>) {
	$_=~s/\n//g;
	if ($_=~/^\s*>\s*(.+)$/){
	    ++$ct;
	    last if ($ct>1);
	    $id=$1;$id=~s/[\s\t]+/ /g;
#	    $id=~s/^[^A-Za-z0-9]*|[^A-Za-z0-9]*$//g;
	    next;}
	$seq.="$_";}
    $seq=~s/\s//g;
    return(0,"*** ERROR $sbrName: no guide sequence found\n"," ") if (length($seq)<1);
    return(1,$id,$seq);
}				# end of fastaRdGuide

#===============================================================================
sub fastaRdMul {
    local($fileInLoc,$rd) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   fastaRdMul                  reads many sequences in FASTA db
#       in:                     $fileInLoc,$rd with:
#                               $rd = '1,5,6',   i.e. list of numbers to read
#                               $rd = 'id1,id2', i.e. list of ids to read
#                               NOTE: numbers faster!!!
#       out:                    1|0,$id,$seq (note: many ids/seq separated by '\n'
#       err:                    ok=(1,id,seq), err=(0,'msg')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:fastaRdMul";$fhinLoc="FHIN_"."$sbrName";

    &open_file("$fhinLoc","$fileInLoc") ||
	return(0,"*** ERROR $sbrName: old '$fileInLoc' not opened\n"," ");

    undef %tmp;
    if (! defined $rd) {
	$LisNumber=1;
	$rd=0;}
    elsif ($rd !~ /[^0-9\,]/){ 
	@tmp=split(/,/,$rd); 
	$LisNumber=1;
	foreach $tmp(@tmp){$tmp{$tmp}=1;}}
    else {$LisNumber=0;
	  @tmp=split(/,/,$rd); }
    
    $ct=$ctRd=0;
    while (<$fhinLoc>) {
	$_=~s/\n//g;
	if ($_=~/^\s*>\s*(.+)$/){ # line with id
	    ++$ct;$Lread=0;
	    last if ($rd && $ctRd==$#tmp); # fin if all found
	    next if ($rd && $LisNumber && ! defined $tmp{$ct});
	    $id=$1;$id=~s/\s\s*/ /g;$id=~s/^[^A-Za-z0-9]*|[^A-Za-z0-9]*$//g;
	    $Lread=1 if ( ($LisNumber && defined $tmp{$ct})
			 || $rd == 0);

	    if (! $Lread){	# go through all ids
		foreach $tmp(@tmp){
		    next if ($tmp !~/$id/);
		    $Lread=1;	# does match, so take
		    last;}}
	    next if (! $Lread);

	    ++$ctRd;
	    $tmp{"$ctRd","id"}=$id;
	    $tmp{"$ctRd","seq"}="";}
	elsif ($Lread) {	# line with sequence
	    $tmp{"$ctRd","seq"}.="$_";}}

    $seq=$id="";		# join to long strings
    foreach $it (1..$ctRd) { $id.= $tmp{"$it","id"}."\n";
			     $tmp{"$it","seq"}=~s/\s//g;
			     $seq.=$tmp{"$it","seq"}."\n";}
    $#tmp=0;undef %tmp;		# save memory
    return(0,"*** ERROR $sbrName: file=$fileInLoc, nali=$ct, wanted: (rd=$rd)\n"," ") 
        if (length($seq)<1);
    return(1,$id,$seq);
}				# end of fastaRdMul

#===============================================================================
sub fastaRun {
    local($niceLoc,$dirData,$exeFasta,$exeFastaFil,$envFastaLibs,$numHits,
	  $parFastaThresh,$parFastaScore,$parFastaSort,
	  $fileInLoc,$fileOutLoc,$fileOutFilLoc,$fhTraceLoc)=@_;
    local($sbr,$command,$msg,$Lok);
#----------------------------------------------------------------------
#   fastaRun                    runs FASTA
#       in:                     $niceLoc,$dirData,$exeFasta,$exeFastaFil,$envFastaLibs,
#       in:                     $numHits,$parFastaThresh,$parFastaScore,$parFastaSort,
#       in:                     $fileInLoc,$fileOutLoc,$fileOutFilLoc,$fhTraceLoc
#       out:                    
#       err:                    ok=(1,'ok'), err=(0,'msg')
#----------------------------------------------------------------------
    $sbr="lib-br:fastaRun";
    $fhTraceLoc="STDOUT"                              if (! defined $fhTraceLoc);
    return(0,"*** $sbr: not def niceLoc!")         if (! defined $niceLoc);
    return(0,"*** $sbr: not def dirData!")         if (! defined $dirData);
    return(0,"*** $sbr: not def exeFasta!")        if (! defined $exeFasta);
    return(0,"*** $sbr: not def exeFastaFil!")     if (! defined $exeFastaFil);
    return(0,"*** $sbr: not def envFastaLibs!")    if (! defined $envFastaLibs);
    return(0,"*** $sbr: not def numHits!")         if (! defined $numHits);
    return(0,"*** $sbr: not def parFastaThresh!")  if (! defined $parFastaThresh);
    return(0,"*** $sbr: not def parFastaScore!")   if (! defined $parFastaScore);
    return(0,"*** $sbr: not def parFastaSort!")    if (! defined $parFastaSort);
    return(0,"*** $sbr: not def fileInLoc!")       if (! defined $fileInLoc);
    return(0,"*** $sbr: not def fileOutLoc!")      if (! defined $fileOutLoc);
    return(0,"*** $sbr: not def fileOutFilLoc!")   if (! defined $fileOutFilLoc);

    return(0,"*** $sbr: miss dir =$dirData!")      if (! -d $dirData);

    return(0,"*** $sbr: miss file=$fileInLoc!")    if (! -e $fileInLoc);
    return(0,"*** $sbr: miss file=$envFastaLibs!") if (! -e $envFastaLibs);
    return(0,"*** $sbr: miss exe =$exeFasta!")     if (! -e $exeFasta);
    return(0,"*** $sbr: miss exe =$exeFastaFil!")  if (! -e $exeFastaFil);

				# ------------------------------
				# set environment needed for FASTA
    $ENV{'FASTLIBS'}=$envFastaLibs;
    $ENV{'LIBTYPE'}= "0";
                                # ------------------------------
                                # run FASTA
                                # ------------------------------
    eval "\$command=\"$niceLoc $exeFasta -b 500 -d 500 -o > $fileOutLoc ,
                       $fileInLoc , S , 1 , $fileOutLoc , $numHits , 0 , \"";
    $msg="--- $sbr '$command'\n";

    $Lok=
	&run_program("$command" ,"$fhTraceLoc","warn");
    if (!$Lok){
	return(0,"*** ERROR $sbr '$Lok'\n"."$msg");}
    if (! -e $fileOutLoc){
	return(0,"*** ERROR $sbr no output '$fileOutLoc'\n"."$msg");}
                                # ----------------------------------------
                                # extract possible hits from fasta-output
                                # ----------------------------------------
    eval "\$command=\"$niceLoc $exeFastaFil  ,$fileOutLoc,$fileOutFilLoc
                      $parFastaThresh,$parFastaScore,$parFastaSort, \"";
    $Lok=
	&run_program("$command" ,"$fhTraceLoc","warn");
    if (!$Lok){
	return(0,"*** ERROR $sbr '$Lok'\n"."$msg");}
    if (! -e $fileOutFilLoc){
	return(0,"*** ERROR $sbr no output '$fileOutFilLoc'\n"."$msg");}
    return(1,"ok $sbr");
}				# end of fastaRun

#===============================================================================
sub fastaWrt {
    local($fileOutLoc,$id,$seqLoc) = @_ ;
    local($sbrName,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   fastaWrt                    writes a sequence in FASTA format
#       in:                     $fileOut,$id,$seq (one string)
#       out:                    
#       err:                    ok=(1,'ok'), err=(0,'msg')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:fastaWrt";$fhoutLoc="FHOUT_"."$sbrName";
#    print "yy into write seq=$seqLoc,\n";

    &open_file("$fhoutLoc",">$fileOutLoc") ||
        return(0,"*** ERROR $sbrName: '$fileOutLoc' not opened for write\n");
    print $fhoutLoc ">$id\n";
    for($it=1;$it<=length($seqLoc);$it+=50){
	foreach $it2 (0..4){
	    last if (($it+10*$it2)>=length($seqLoc));
	    printf $fhoutLoc " %-10s",substr($seqLoc,($it+10*$it2),10);}
	print $fhoutLoc "\n";}
    close($fhoutLoc);
    return(1,"ok $sbrName");
}				# end of fastaWrt

#===============================================================================
sub fastaWrtMul {
    local($fileOutLoc,%tmp) = @_ ;
    local($sbrName,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   fastaWrtMul                 writes a list of sequences in FASTA format
#       in:                     $fileOut,$tmp{} with:
#       in:                     $tmp{"NROWS"}      number of sequences
#       in:                     $tmp{"id","$ct"}   id for sequence $ct
#       in:                     $tmp{"seq","$ct"}  seq for sequence $ct
#       out:                    file
#       err:                    err  -> 0,message
#       err:                    ok   -> 1,ok
#       err:                    warn -> 2,not enough written
#-------------------------------------------------------------------------------
    $sbrName="lib-br:fastaWrtMul";$fhoutLoc="FHOUT_"."$sbrName";

    return(0,"*** ERROR $sbrName: no tmp{NROWS} defined\n") if (! defined $tmp{"NROWS"});
    &open_file("$fhoutLoc",">$fileOutLoc") ||
        return(0,"*** ERROR $sbrName: '$fileOutLoc' not opened for write\n");

    $ctOk=0; 
    foreach $itPair (1..$tmp{"NROWS"}){
        next if (! defined $tmp{"id","$itPair"} || ! defined $tmp{"seq","$itPair"});
        ++$ctOk;
                                # some massage
        $tmp{"id","$itPair"}=~s/[\s\t\n]+/ /g;
        $tmp{"seq","$itPair"}=~s/[\s\t\n]+//g;
                                # write
        print $fhoutLoc ">",$tmp{"id","$itPair"},"\n";
	$lenHere=length($tmp{"seq","$itPair"});
        for($it=1; $it<=$lenHere; $it+=50){
	    $tmpWrt=      "";
            foreach $it2 (0..4){
		$itHere=($it + 10*$it2);
                last if ( $itHere >= $lenHere);
		$nchunk=10; 
		$nchunk=1+($lenHere-$itHere)  if ( (10 + $itHere) > $lenHere);
		$tmpWrt.= sprintf(" %-10s",substr($tmp{"seq","$itPair"},$itHere,$nchunk)); 
	    }
	    print $fhoutLoc $tmpWrt,"\n";
	}
    }
    close($fhoutLoc);
    return(0,"*** ERROR $sbrName: no sequence written\n")               
	if (! $ctOk);
    return(2,"-*- WARN $sbrName: wrote fewer sequences than expected\n") 
	if ($ctOk!=$tmp{"NROWS"});
    return(1,"ok $sbrName");
}				# end of fastaWrtMul

#===============================================================================
sub fctRunTimeLeft {
    local($timeBegLoc,$num_to_run,$num_did_run) = @_ ;
    local($sbrName);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   fctRunTimeLeft              estimates the time the job still needs to run
#       in:                     $timeBegLoc : time (time) when job began
#       in:                     $num_to_run : number of things to do
#       in:                     $num_did_run: number of things that are done, so far
#       out:                    $_string_time-still (hour:min:sec)
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."fctRunTimeLeft";

    $timeNow=time;
    $timeRun=$timeNow-$timeBegLoc;

    $percLoc=0;
    $percLoc=100*($num_did_run/$num_to_run) if ($num_to_run > 0);

    if ($percLoc) {
	$timeTot=100*($timeRun/$percLoc);
	$timeLeft=$timeTot-$timeRun;
	$estimateLoc=&fctSeconds2time($timeLeft); }
    else {
	$estimateLoc="?";}
    return($estimateLoc);
}				# end of fctRunTimeLeft

#===============================================================================
sub fctSeconds2time {
    local($secIn) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   fctSeconds2time             converts seconds to hours:minutes:seconds
#       in:                     seconds
#       out:                    05:13:50
#-------------------------------------------------------------------------------
    $sbrName="lib-comp:"."fctSeconds2time";$fhinLoc="FHIN"."$sbrName";
    $minTmp=  int($secIn/60);
    $seconds= ($secIn - $minTmp*60); $seconds=int($seconds);
    $hours=   int($minTmp/60);       $hours=  int($hours);
    $minutes= ($minTmp - $hours*60); $minutes=int($minutes);

    $seconds="0".$seconds if (length($seconds)==1);
    $minutes="0".$minutes if (length($minutes)==1);
    $hours=  "0".$hours   if (length($hours)==1);
    return("$hours".":".$minutes.":".$seconds);
}				# end of fctSeconds2time

#===============================================================================
sub fileListArrayRd {
    local($listFileInLoc,$extDbFileLoc,$extChainLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   fileListArrayRd             returns array of HSSP files
#       in:                     $extDbfile=     expected file extension (.hssp)
#                                  note:        necessary to purge chains!
#       in:                     $extChain=      expected chain extension (e.g. '_')
#       in:                     $listFileInLoc= list of files, e.g.:
#                                  '1ppt.hssp,list-of-hssp.files,1cse.hssp_E'
#       out:                    1|0,msg,$file(f1,f2,f3,..,),$chain(c1,c2,c3)
#                                  note:        chain '*' for no given chain
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."fileListArrayRd";$fhinLoc="FHIN_"."fileListArrayRd";
				# check arguments
    return(0,"*** $sbrName: not def listFileInLoc!",0)  if (! defined $listFileInLoc);
    return(0,"*** $sbrName: not def extDbFileLoc!",0)   if (! defined $extDbFileLoc);
    return(0,"*** $sbrName: not def extChainLoc!",0)    if (! defined $extChainLoc);
    $listFileInLoc=~s/^,*|,*$//g;
    @fileInLoc=split(/,/,$listFileInLoc);
    return(&errSbr("no file input ($listFileInLoc)"),0) if ($#fileInLoc == 0);

				# ------------------------------
				# loop over list
				# ------------------------------
    $#tmpf=$#tmpc=0;
    foreach $fileIn (@fileInLoc){
				# HSSP + chain
	if ($fileIn=~/^(.*$extDbFileLoc)$extChainLoc(.)$/ && $2 =~ /[A-Za-z0-9]/) {
	    $tmp=$rd; $tmp=~s/$extChainLoc.*$//g;       $file=$tmp;
	    $tmp=$rd; $tmp=~s/^.*$extChainLoc(.)$/$1/g; $chain=$tmp; 
	    push(@tmpf,$file); push(@tmpc,$chain); 
	    next; }
				# is e.g. HSSP (checked by extension)
	if ($fileIn=~/^(.*$extDbFileLoc)$/) {
	    push(@tmpf,$fileIn); push(@tmpc,"*"); 
	    next; }
				# is list?
	&open_file("$fhinLoc", "$fileIn") || return(&errSbr("fileIn=$fileIn"),0);
	while (<$fhinLoc>) {
	    $_=~s/\s|\n//g; $rd=$_; 
	    $file=$rd; $chain="*"; 
	    if ($rd =~ /.*$extDbFileLoc$extChainLoc(.)$/ && $1 =~ /[A-Za-z0-9]/){
		$tmp=$rd; $tmp=~s/$extChainLoc.*$//g;       $file=$tmp;
		$tmp=$rd; $tmp=~s/^.*$extChainLoc(.)$/$1/g; $chain=$tmp; }
	    return(&errSbr("file rd from list ($fileIn)=$file, not ext=$extDbFileLoc,"))
		if ($file !~ /$extDbFileLoc$/);
	    push(@tmpf,$file);push(@tmpc,$chain);} close($fhinLoc); 
    }
                                # ------------------------------
                                # ERROR
    return(&errSbr("no file found in ($listFileInLoc) with ".
                   "extDb=$extDbFileLoc, extChain=$extChainLoc"),0) if ($#tmpf<1);
				# ------------------------------
				# final lists
				# ------------------------------
    $file= join(',',@tmpf); $file =~s/,*$//g;
    $chain=join(',',@tmpc); $chain=~s/,*$//g;

    return(1,"ok $sbrName",$file,$chain);
}				# end of fileListArrayRd

#===============================================================================
sub fileListRd {
    local($fileInLoc,$fhErrSbr,$extForChain,$dirLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   fileListRd                  reads a list of files
#       in:                     file_list=     file with filenames
#       in:                     $fhErrSbr=     file handle to report missing files 
#                                              (0 to surpress warnings!)
#       in:                     $extForChain=  'ext1,ext2' : extensions to check for chains,
#                                              i.e. if not existing purge ext_[A-Z0-9]
#       in:                     $dirLoc=       'dir1,dir2' : directories to scan for file
#       out:                    1|0,msg
#       out:                    $list=         'file1,file2,...'
#       out:                    $chain=        'c1,c2,...' : if chains found
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."fileListRd";$fhinLoc="FHIN_"."fileListRd";
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc!",0)         if (! defined $fileInLoc);
    $fhErrSbr="STDOUT"                                     if (! defined $fhErrSbr);
    $extForChain=0                                         if (! defined $extForChain);
    return(0,"*** $sbrName: miss in file '$fileInLoc'!",0) if (! -e $fileInLoc);
    @extLoc=split(/,/,$extForChain)                        if ($extForChain);
    @dirLoc=split(/,/,$dirLoc)                             if ($dirLoc);
				# ------------------------------
				# open file
    &open_file("$fhinLoc","$fileInLoc") ||
	return(0,"*** ERROR $sbrName: fileIn=$fileInLoc, not opened\n",0);

    $tmpChain=$tmpFile="";	# ------------------------------
    while (<$fhinLoc>) {	# read list
	$_=~s/\n|\s//g; $file=$_;
	next if (length($_)==0);
	if    (-e $file) {
	    $tmpFile.="$file,";$tmpChain.="*,";} # file ok 
	else {$Lok=0;$chainTmp="unk";
	      foreach $ext (@extLoc){ # check chain
		  foreach $dir ("",@dirLoc){ # check dir (first: local!)
		      $fileTmp=$file; $dir.="/"  if (length($dir)>0 && $dir !~/\/$/);
		      $fileTmp=~s/^(.*$ext)\_([A-Z0-9])$/$1/;
		      $chainTmp=$2               if (defined $2);
		      $fileTmp=$dir.$fileTmp; 
		      $Lok=1  if (-e $fileTmp);
		      last if $Lok;}
		  last if $Lok;}
	      if ($Lok){$tmpFile.="$fileTmp,";
			$tmpChain.="*,"          if (! defined $chainTmp || $chainTmp eq "unk");
			$tmpChain.="$chainTmp,"  if (defined $chainTmp && $chainTmp ne "unk"); }
	      else { print $fhErrSbr "-*- WARN $sbrName missing file=$_,\n";}}
    }close($fhinLoc);
    $tmpFile=~s/^,*|,*$//g;$tmpChain=~s/^,*|,*$//g;
    return(1,"ok $sbrName",$tmpFile,$tmpChain);
}				# end of fileListRd

#===============================================================================
sub fileListWrt {
    local($fileOutLoc,$fhErrSbr,@listLoc) = @_ ;
    local($sbrName,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   fileListWrt                 writes a list of files
#       in:                     fileOut,$fhErrSbr (to report missing files),@list
#       out:                    1|0,msg : implicit: file
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."fileListWrt";$fhoutLoc="FHOUT_"."fileListWrt";
				# check arguments
    return(0,"*** $sbrName: not def fileOutLoc!")          if (! defined $fileOutLoc);
    return(0,"*** $sbrName: not def \@list!")              if (! defined @listLoc || ! @listLoc);
    $#tmp=0;                    # ------------------------------
    foreach $file (@listLoc){   # check existence
	if    (-e $file) {
	    push(@tmp,$file);}	# file ok
	elsif ($file=~/^(.*[hd]ssp\.*)_[0-9A-Z]$/ && -e $1){
	    push(@tmp,$file);}	# is chain
	else { print $fhErrSbr "-*- WARN $sbrName missing file=$file,\n";}}
    @listLoc=@tmp;

    return(0,"*** $sbrName: after check none in\@list!")   if (! defined @listLoc || ! @listLoc);
				# open file
    &open_file("$fhoutLoc",">$fileOutLoc") ||
	return(0,"*** ERROR $sbrName: fileNew=$fileOutLoc, not created\n",0);
    foreach $file (@listLoc){   # write
	print $fhoutLoc $file,"\n";}
    close($fhoutLoc);
    return(1,"ok $sbrName");
}				# end of fileListWrt

#===============================================================================
sub filter_hssp_curve {
    local ($lali,$ide,$thresh) = @_ ;
    local ($hssp_line);
    $[=1;
#--------------------------------------------------------------------------------
#   filter_hssp_curve           computes HSSP curve based on in:    ali length, seq ide
#       in:                     $lali,$ide,$thresh  
#                               note1: ide=percentage!
#                               note2: thresh=0 for HSSP, 5 for 30%, -5 for 20% ..
#       out GLOBAL:             $LABOVE_HSSP_CURVE =1 if ($ide,$lali)>HSSP-line +$thresh
#                               HSSP-curve  according to t(L)=(290.15 * L ** -0.562)
#--------------------------------------------------------------------------------
    if (length($thresh)==0) {$thresh=0;}
    $lali=~s/\s//g;
    if ($lali>80){$hssp_line=25.0;}else{ $hssp_line= 290.15*($lali **(-0.562) );}
    if ( $ide >= ($hssp_line+$thresh) ) {$LABOVE_HSSP_CURVE=1;}else{$LABOVE_HSSP_CURVE=0;}

    return ($LABOVE_HSSP_CURVE);
}				# end of filter_hssp_curve

#===============================================================================
sub filter_oneprotein {
    local ($cutshort,$cutshort_single,$cutrel_single,$cutrelav_single,
           $splitlong,$splitlong2,$splitrel,$splitmaxflip,$shorten_len,$shorten_rel,
	   $PRD,$REL)=@_;
				# called by phd_htmfil.pl only!
    local ($ctseg,$ct,$tmp,$it,$it2,$itsplit,$sym,$symprev,$ctnotloop,
	   @seg,@ptr,@segbeg,$Lsplit,$splitloc);
    $[=1;
#--------------------------------------------------------------------------------
#   filter_oneprotein           reads .pred files
#       in GLOBAL:              ($PRD, $REL)
#       out GLOBAL:             $LNOT_MEMBRANE, $FIL, $RELFIL,
#--------------------------------------------------------------------------------
				# --------------------------------------------------
    @symh=("H","T","M");	# extract segments
    foreach $symh (@symh){
	%seg=&get_secstr_segment_caps($PRD,$symh);
	if ($seg{"$symh","NROWS"}>=1) {$tmp=$symh;
				       last;}}
    $symh=$tmp;			# --------------------------------------------------
				# none found? 
    if ((defined $symh) && (defined $seg{"$symh","NROWS"})) {
	$nseg=$seg{"$symh","NROWS"};
	if ($nseg<1) {
	    return(1,$PRD,$REL);} }
    else {
	return(1,$PRD,$REL);}
    $nres=length($PRD);		# ini
    $#Lflip=0;foreach $it(1..$nres){$Lflip[$it]=0;}
				# --------------------------------------------------
				# first long helices with rel ="000" split!
    $prdnew=$PRD;
    foreach $ct (1..$nseg) {
	$len=$seg{"$symh","end","$ct"}-$seg{"$symh","beg","$ct"}+1;
	if ( $len > $splitlong2 ) {
	    foreach $it ($seg{"$symh","beg","$ct"} .. 
			 ($seg{"$symh","end","$ct"}-$splitlong) ) {
		if (substr($REL,$it,3) eq "000") {
		    foreach $it2 ($it .. ($it+2)) {
			$Lflip[$it2]=1;}
		    substr($prdnew,$it,3)="LLL";}}}}
    if ($prdnew ne $PRD) {	# redo
	%seg=&get_secstr_segment_caps($prdnew,$symh);}
    $nseg=$seg{"$symh","NROWS"};
				# --------------------------------------------------
				# delete all < 11 , store len
				# --------------------------------------------------
    $#ptr_ok=0;
    foreach $ct (1..$nseg) {
	$seg{"len","$ct"}=($seg{"$symh","end","$ct"}-$seg{"$symh","beg","$ct"}+1);
				# first shorten if < 17
	if (($nseg>1) && ($seg{"len","$ct"}<$cutshort_single)){
	    $Ncap=$seg{"$symh","beg","$ct"};
	    $Ccap=$seg{"$symh","end","$ct"};
	    ($Ntmp,$Ctmp)=
		&filter1_rel_shorten($REL,($shorten_rel-1),$Ncap,$Ccap,$shorten_len);
	    $len=$Ctmp-$Ntmp+1;
	    if ($len<$cutshort) {
		foreach $it2 ( $Ncap .. $Ccap ){
		    $Lflip[$it2]=1;}} 
	    else {
		push(@ptr_ok,$ct);}}
	elsif ($seg{"len","$ct"}>$cutshort){
	    push(@ptr_ok,$ct);}}
    if ($#ptr_ok<1){
	print "********* HTMfil: filter_one_protein: no region > $cutshort\n";
	return(1,$PRD,$REL);}
				# --------------------------------------------------
				# only one and < 17?
				# --------------------------------------------------
    if ($#ptr_ok == 1) {
	$pos=$ptr_ok[1];
	$len=$seg{"len","$pos"};
	if ($len<$cutshort_single){
	    $Ncap=$seg{"$symh","beg","$pos"};
	    $Ccap=$seg{"$symh","end","$pos"};
	    $ave=0;		# average reliability
	    foreach $it ( $Ncap .. $Ccap){$ave+=substr($REL,$it,1);}
	    $ave=$ave/$len;	# average reliability > thresh -> elongate
	    if ($ave>=$cutrelav_single) { # add no more than 2 = HARD coded
				# add to N and C-term
		($Ntmp,$Ctmp)=
		    &filter1_rel_lengthen($REL,$cutrel_single,$Ncap,$Ccap,2);
		$Lchange=
		    &filter1_change(); # all GLOBAL
#		    &filter1_change($pos); # all GLOBAL
		if ($Lchange){
		    $seg{"$symh","beg","$pos"}=$Ncap;
		    $seg{"$symh","end","$pos"}=$Ccap;}}
	    else {
		print "********* HTM: filter_one_protein: single region, too short ($len)\n";
		return(1,$PRD,$REL);} }}
				# --------------------------------------------------
				# too long segments: shorten, split, ..
				# --------------------------------------------------
    foreach $it (@ptr_ok){
	$len=$seg{"len","$it"};
	$Ncap=$seg{"$symh","beg","$it"};
	$Ccap=$seg{"$symh","end","$it"};
				# ----------------------------------------
				# is it too long ? -> first try to shorten
	if ( ($len > 2*$splitlong) || ($len >= $splitlong2) ) {
				# cut fro N and C-term
	    ($Ntmp,$Ctmp)=
		&filter1_rel_shorten($REL,$shorten_rel,$Ncap,$Ccap,$shorten_len);
	    $Lchange=
		&filter1_change(); # all GLOBAL
#		&filter1_change($it); # all GLOBAL
	    if ($Lchange) {
		$len=$Ccap-$Ncap+1;} 
	}
				# ----------------------------------------
                                # still too long ? -> now split 
	$Lsplit=0;
                                # direct
	if    ( $len > ($splitlong+$splitlong2) ) {
	    $Lsplit=1;$splitloc=$splitlong; }
                                # only two segments => different cut-off
	elsif ( $len > $splitlong2 ) {
	    $Lsplit=1;$splitloc=$len/2; }
				# ----------------------------------------
                                # do split the HAIR
	if ($Lsplit) {
	    $splitN=int($len/$splitloc);
				# correction 9.95: add if e.g. > 50+11, eg. 65->3 times
	    if ($len>($splitN*$splitloc)+$cutshort_single){++$splitN;} # 9.95
				# correction 9.95: one less eg. > 100 , 
				#                  now: =4 times, but 100< 3*25+36 -> 4->3
	    if ( ($splitN>3) && ($len<($splitN-2)*$splitlong+$splitlong2+17) ) {
		--$splitN;}
	    if ($splitN>1){
		$splitL=int($len/$splitN);
				# --------------------
                                # loop over all splits
				# --------------------
		foreach $itsplit (1..($splitN-1)) {
		    $pos=$Ncap+$itsplit*$splitL; 
		    $min=substr($REL,$pos,1);
                                # in area +/-3 around split lower REL?
		    foreach $it2 (($pos-3)..($pos+3)){
			if (substr($REL,$it2,1)<$min){$min=substr($REL,$it2,1);
						      $pos=$it2;}}	
                                # flip 1,2, or 3 residues?
		    foreach $it2 (($pos-$splitmaxflip)..($pos+$splitmaxflip)){
			if   ( ($it2==$pos-1)||($it2==$pos)||($it2==$pos+1)) { 
			    $Lflip[$it2]=1; }
			elsif(substr($REL,$it2,1)<$splitrel){
			    $Lflip[$it2]=1;}} 
		}}		# end loop over splits
	}
    }				# end of loop over all HTM's
				# ----------------------------------------
				# now join segments to filtered version
    $PRD=~s/ |E/L/g;
    $FIL="";
    foreach $it (1..$nres) {
	if (! $Lflip[$it]) { 
	    $FIL.=substr($PRD,$it,1);}
	else {
	    if (substr($PRD,$it,1) eq $symh){
		$FIL.="L";}
	    else {
		$FIL.=$symh;}}}
				# ----------------------------------------
				# correct reliability index
    $RELFIL="";
    for ($it=1;$it<=length($FIL);++$it) {
	if (substr($FIL,$it,1) ne substr($PRD,$it,1)) {$RELFIL.="0";}
	else {$RELFIL.=substr($REL,$it,1);} }

    return(0,$FIL,$RELFIL);
}                               # end of filter_oneprotein

#===============================================================================
sub filter1_change {
    $[ =1 ;
#--------------------------------------------------------------------------------
#   filter1_change              ??? (somehow to do with filter_oneprotein)
#--------------------------------------------------------------------------------
    $Lchanged=0;  
    if    ($Ntmp < $Ncap){ 
	$Lchanged=1;
	foreach $_( $Ntmp .. ($Ncap-1)){
	    $Lflip[$_]=1; } }
    elsif ($Ntmp > $Ncap){ 
	$Lchanged=1;
	foreach $_( $Ncap .. ($Ntmp-1) ){
	    $Lflip[$_]=1; } }
    if    ($Ctmp < $Ccap){ 
	$Lchanged=1;
	foreach $_( ($Ctmp+1) .. $Ccap ){
	    $Lflip[$_]=1; } }
    elsif ($Ctmp > $Ccap){ 
	$Lchanged=1;
	foreach $_( ($Ccap+1) .. $Ctmp){
	    $Lflip[$_]=1; } }
    if ($Lchanged)     {	# if changed update counters
	$Ncap=$Ntmp;
	$Ccap=$Ctmp;}
    return($Lchanged);
}				# end of filter1_change

#===============================================================================
sub filter1_rel_lengthen {
    local ($rel,$cut,$Ncap,$Ccap,$nmax) = @_ ; local ($num,$ct);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   filter1_rel_lengthen        checks in N- and C-term, whether rel > cut
#--------------------------------------------------------------------------------
    $ct=$Ncap-1;		# Ncap
    $num=0;
    while ((defined substr($rel,$ct,1)) && 
	   (substr($rel,$ct,1)<$cut)){
	++$num;
	$Ncap=$ct; 
	last if ($num==$nmax);	# not more than nmax changes
	--$ct;}
    $num=0;
    $ct=$Ccap+1;	# Ccap
    while ((defined substr($rel,$ct,1)) && 
	   (substr($rel,$ct,1)<$cut)){
	++$num;
	$Ccap=$ct; 
	last if ($num==$nmax);	# not more than nmax changes
	++$ct;}
    return($Ncap,$Ccap);
}				# end of filter1_rel_lengthen

#===============================================================================
sub filter1_rel_shorten {
    local ($rel,$cut,$Ncap,$Ccap,$nmax) = @_ ; local ($num,$ct);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   filter1_rel_shorten         checks in N- and C-term, whether rel > cut
#--------------------------------------------------------------------------------
    $ct=$Ncap;			# Ncap
    $num=0;
    while ((defined substr($rel,$ct,1)) && 
	   (substr($rel,$ct,1)<$cut)){
	++$num;
	$Ncap=($ct+1); 
	last if ($num==$nmax);	# not more than nmax changes
	++$ct;}
    $num=0;
    $ct=$Ccap;			# Ccap
    while ((defined substr($rel,$ct,1)) && 
	   (substr($rel,$ct,1)<$cut)){
	++$num;
	$Ccap=($ct-1); 
	last if ($num==$nmax);	# not more than nmax changes
	--$ct;}
    return($Ncap,$Ccap);
}				# end of filter1_rel_shorten

#===============================================================================
sub form_perl2rdb {
    local ($format) = @_ ;
#--------------------------------------------------------------------------------
#   form_perl2rdb               converts printf perl (d,f,s) into RDB format (N,F, ) 
#--------------------------------------------------------------------------------
    $format=~s/[%-]//g;$format=~s/f/F/;$format=~s/d/N/;$format=~s/s/S/;
    return $format;
}				# end of form_perl2rdb

#===============================================================================
sub form_rdb2perl {
    local ($format) = @_ ;
    local ($tmp);
#--------------------------------------------------------------------------------
#   form_perl2rdb               converts RDB (N,F, ) to printf perl format (d,f,s)
#--------------------------------------------------------------------------------
    $format=~tr/[A-Z]/[a-z]/;
    $format=~s/n/d/;$format=~s/(\d+)$/$1s/;
    if ($format =~ /[s]/){
	$format="%-".$format;}
    else {
	$format="%".$format;}
    return $format;
}				# end of form_rdb2perl

#===============================================================================
sub fRound {local ($num)=@_;local($signLoc,$tmp);
#----------------------------------------------------------------------
#   fRound                      returns the rounded integer of real input (7.6->8; 7.4->7)
#       in:                     $num
#       out:                    returned |$num|
#----------------------------------------------------------------------
	    if ($num<0){$signLoc=-1;}else{$signLoc=1;}
	    $num=&func_absolute($num);
	    if ($num-int($num)>=0.5){
		$tmp=int($num)+1;}
	    else {
		$tmp=int($num)+1;}
	    if ($tmp==0){
		return(0);}
	    else {
		return($signLoc*$tmp);}
}				# end of fRound

#===============================================================================
sub fsspGetFile { 
    local ($fileInLoc,$Lscreen,@dir) = @_ ; 
    local ($fileFssp,$dir,$tmp,$chain,@dir2,$idLoc,$fileHssp,$chainHssp,$it,@chainHssp);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   fsspGetFile                 searches all directories for existing FSSP file
#       in:                     $file,$Lscreen,@dir
#       out:                    returned file,chain ($fssp,$chain), (if chain in file)
#       watch:                  loop onto itself:
#                               1prcH.fssp not found -> try 1prc.fssp
#--------------------------------------------------------------------------------
    $#dir2=$Lok=0;$chain="";$idLoc=$fileInLoc;$idLoc=~s/^.*\///g;
    foreach $dir(@dir){		# avoid endless loop when calling itself
	if ($dir =~ /\/data\/fssp/) { $Lok=1;}
	push(@dir2,$dir);}
    @dir=@dir2;  if (!$Lok){push(@dir,"/data/fssp/");} # give default
    
    if    (! defined $Lscreen){$Lscreen=0;}
    elsif ($Lscreen !~ /[01]/){push(@dir,$Lscreen);$Lscreen=0;}
    $title=$fileInLoc;$title=~s/^.*\/|\.fssp.*$//g;
    $fsspFileTmp=$fileInLoc;$fsspFileTmp=~s/\s|\n//g;
				# loop over all directories
    $fileFssp=&fsspGetFileLoop($fsspFileTmp,$Lscreen,@dir);

    if ( ! -e $fileFssp ) {	# still not: cut non [A-Za-z0-9]
	$tmp_file=$fileInLoc; $tmp_file=~s/^([A-Za-z0-9]+).*(\.fssp.*)$/$1$2/g;
	$fileFssp=&fsspGetFileLoop($tmp_file,$Lscreen,@dir);}
    if ( ! -e $fileFssp ) {	# still not: assume = chain
	$tmp1=substr($fileInLoc,1,4);$chain=substr($fileInLoc,5,1);
	$tmp_file=$fileInLoc; $tmp_file=~s/^($tmp1).*(\.fssp.*)$/$1$2/;
	$fileFssp=&fsspGetFileLoop($tmp_file,$Lscreen,@dir);}
    if ( ! -e $fileFssp ) {	# still not: version up
	$tmp1=substr($idLoc,2,3);
	foreach $it(1..9){$tmp_file="$it"."$tmp1".".fssp";
			  $fileFssp=&fsspGetFileLoop($tmp_file,$Lscreen,@dir);}}
				# still not: try to add chain
    if ( (! -e $fileFssp) && (length($title)==4) ) {
	$fileHssp=$fileInLoc;$fileHssp=~s/\.fssp/\.hssp/;$fileHssp=~s/^.*\///g;
	$fileHssp= &hsspGetFile($fileHssp,0);
	$chainHssp=&hsspGetChain($fileHssp);$#chainHssp=0;
	if ($chainHssp ne " "){
	    foreach $it(1..length($chainHssp)){push(@chainHssp,substr($chainHssp,$it,1));}
	    foreach $chainHssp(@chainHssp){
		$tmp=$fileInLoc; $tmp=~s/\.fssp/$chainHssp\.fssp/;
		$fileFssp=&fsspGetFileLoop($tmp,$Lscreen,@dir); 
		last if (-e $fileFssp);}}}

    if ( ! -e $fileFssp) { return(0);}
    if (length($chain)>0) { return($fileFssp,$chain);}
    else                  { return($fileFssp);}
}				# end of fsspGetFile

#===============================================================================
sub fsspGetFileLoop { 
    local ($fileInLoop,$Lscreen,@dir) = @_ ; 
    local ($fileOutLoop,$dir,$tmp);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   fsspGetFileLoop             loops over all directories
#       in:                     $file,$Lscreen,@dir
#       out:                    returned file
#--------------------------------------------------------------------------------
    $fileOutLoop="unk";
    foreach $dir (@dir) {
	$dir=&complete_dir($dir); # add slash at end?
	$tmp="$dir"."$fileInLoop"; # try directory
	if ($Lscreen)           { print "--- fsspGetFileLoop: \t trying '$tmp'\n";}
	if (-e $tmp) { $fileOutLoop=$tmp;
		       last;}
	if ($tmp!~/\.fssp/) {	# missing extension?
	    $tmp.=".fssp";
	    if ($Lscreen)       { print "--- fsspGetFileLoop: \t trying '$tmp'\n";}
	    if (-e $tmp) { $fileOutLoop=$tmp;
			   last;}}}
    $fileOutLoop=~s/\s|\n//g;	# security..
    return($fileOutLoop);
}				# end of fsspGetFileLoop

#===============================================================================
sub fsspRdSummary {
    local ($fileLoc,$desLoc) = @_ ;local (%rdLoc);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   fsspRdSummary               read the summary table of an FSSP file
#       in:                     $fileLoc,$desLoc
#       des                     "header,desH1,desH2,body,desB1,desB2"
#       headers:		PDBID,HEADER,SOURCE,SEQLENGTH,NALIGN
#       body:			NR,STRID1,ST  RID2,Z,RMSD,LALI,LSEG2,%IDE,
#				REVERS,PERMUT,NFRAG,TOPO,PROTEIN
#       out:   		header  : $rd{"$des"}, body: %rd{"$des","$ct"}
#--------------------------------------------------------------------------------
				# ini
    $fhinLoc="FhFsspRdSummary";
				# read argument: desired keys
    @des=split(/,/,$desLoc);
    $#desHeader=$#desBody=0;
    foreach $_(@des){
	$_=~s/\n|\s//g;
	if   (/^header/){$Lheader=1;}
	elsif(/^body/)  {$Lheader=0;}
	elsif ($Lheader){push(@desHeader,$_);}
	else            {push(@desBody,$_);}}

    &open_file("$fhinLoc", "$fileLoc");
				#--------------------------------------------------
				# read header
    while(<$fhinLoc>){
	last if (/^\#\# SUMMARY/);
	$_=~s/\n//g;		# purge new line
    	foreach $des(@desHeader){
	    if (/^$des/){
		$_=~s/^$des\s+//g;
		$rdLoc{"$des"}=$_;
		last;}}}
				#--------------------------------------------------
				# read body
    $ctPairs=0;
    while(<$fhinLoc>){
	last if (/^\#\# ALIGNMENTS/);
	$_=~s/\n//g;		# purge new line
	$_=~s/^\s*|\s*$//g;	# trail leading blanks
				# ------------------------------
	if (/^\s*NR/){		# read names (first line)
	    @names=split(/\s+/,$_);
	    foreach $names(@names){$names=~s/\.//g;}
	    $ct=0;
	    foreach $it(1..$#names){foreach $des(@desBody){
		if ($des eq $names[$it]){ $point{"$des"}=$it;++$ct;
					  last;}}}
				# consistency check
	    if ( $ct != $#desBody ) {
		print "-*- WARNING fsspRdSummary: not all names found:\n";
		print "-*-         read (names)  :";&myprt_array(",",@names);
		print "-*-         want (desBody):";&myprt_array(",",@desBody);
		print "-*-         ok            :";
		foreach $des (@desBody){if (defined $point{"$des"}){print"$des,";}}
		print "\n";}
	    next;}
				# ------------------------------
	@tmp=split(/\s+/,$_);	# read rest
    	foreach $des(@desBody){
	    if (defined $point{"$des"}){
		$tmp=$point{"$des"};
		if   (($des eq $desBody[1])&&(defined $tmp[$tmp])){
		    ++$ctPairs;}
		elsif($des eq $desBody[1]){
		    last;}
		$rdLoc{"$des","$ctPairs"}=$tmp[$tmp]; } }
    }close($fhinLoc);
    $rdLoc{"NROWS"}=$rdLoc{"NPAIRS"}=$ctPairs;
    return(%rdLoc);
}				# end of fsspRdSummary

#===============================================================================
sub fssp_rd_ali {
    local($line_ali,@pos)=@_;
    local(%rd_ali,@des1,@des2,%ptr,%len,$des,$pos,@line,$tmp,$beg,$end,$Lok,$ptr,$postmp);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   fssp_rd_ali                 reads one entire alignment for an open FSSP file
#       in:
#         $line_ali             all lines with FSSP alis in one string (separated
#                               by newlines (\n) )
#         @pos                  positions to be read
#       out:
#         $rd{seq1},$rd{sec1},$rd{acc1},$rd{seq2,pos},$rd{sec2,pos}
#                               note: acc="n1,n2,"
#--------------------------------------------------------------------------------
    $#tmp=0;$Lis_old=0;
    foreach $pos(@pos){
	if ($pos=~/is_old/){
	    $Lis_old=1;}
	else {
	    push(@tmp,$pos);}}
				# ----------------------------------------
				# defaults (pointers to column numbers
				#           in FSSP)
				# ----------------------------------------
    @des1=("seq1","sec1","acc1");
    @des2=("seq2","sec2");
    $len{"seq1"}=1;$len{"sec1"}=1;$len{"acc1"}=3;$len{"seq2"}=1;$len{"sec2"}=1;
    if ($Lis_old){
	$ptr{"seq1"}=14;$ptr{"sec1"}=17;$ptr{"acc1"}=35;
	$ptr{"seq2"}=46;$ptr{"sec2"}=47;}
    else {
	$ptr{"seq1"}=13;$ptr{"sec1"}=16;$ptr{"acc1"}=35;
	$ptr{"seq2"}=43;$ptr{"sec2"}=44;}
				# initialise
    %rd_ali=$#line=0;
    foreach $des (@des1) { $rd_ali{"$des"}="";}
    foreach $des (@des2) { foreach $pos (@pos) { $rd_ali{"$des","$pos"}="";} }
    @line=split(/\n/,$line_ali);
				# ----------------------------------------
				# read the alis
				# ----------------------------------------
    foreach $_ (@line){
	if (/^\#\# ALIGNMENTS/) {
	    $tmp=$_;$tmp=~s/.*ALIGNMENTS\s*(\d+)\s*-\s*(\d+)/$1-$2/g;
	    ($beg,$end)=split(/-/,$tmp);
	    $Lok=0;
	    foreach $pos (@pos) {
		if ( ($pos>=$beg) && ($pos<=$end) ) { $Lok=1; last; }} }
				# ------------------------------
				# within range?
	if ($Lok) {
	    if (! /^\s*\d+/){next;}
				# read sequence 1 (guide)
	    foreach $des (@des1) {
		$rd_ali{"$des"}.=substr($_,$ptr{"$des"},$len{"$des"}); 
		if ($des=~/acc/){$rd_ali{"$des"}.=",";}}
				# read all aligned sequences
	    foreach $pos (@pos) {
		if ( ($pos>=$beg) && ($pos<=$end) ) { 
		    foreach $des (@des2) { 
			$postmp=$pos-($beg-1);
			$ptr=($postmp-1)*3+$ptr{"$des"};
			$rd_ali{"$des","$pos"}.=substr($_,$ptr,$len{"$des"});
			if ($des=~/acc/){$rd_ali{"$des","$pos"}.=",";}
		    } } } }
    }
				# upper case sec str for aligned
    foreach $pos (@pos){ $rd_ali{"sec2","$pos"}=~tr/[a-z]/[A-Z]/; }
    return %rd_ali;
}				# end of fssp_rd_ali

#===============================================================================
sub fssp_rd_one {
    local ($fileInLoc,$id_in,@des_in) = @_ ;
    local ($fhin,$tmpline,$tmp,@tmp,$tmp1,$it,$id2_col,$nr_col,$des,$id2,$nr_search,
	   %rdLoc,%rd_tmp,$Lread_alis,$nr1,$nr2,$line_ali,$Lok,@des,@des_ali);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   fssp_rd_one                 reads for a given FSSP file one particular ali+header
#       in:                     $fssp_file,$id_to_be_read,
#                               @des  = e.g. STRID2, i.e., FSSP column names for summary table
#                                       + seq,sec,acc (if all 3 to be returned)
#       out:                    returned:
#                               $rd{STRID2} ...
#                               $rd{seq1},$rd{sec1},$rd{acc1},$rd{seq2,pos},$rd{sec2,pos}
#                               note: acc="n1,n2,"
#--------------------------------------------------------------------------------
				# defaults
    $fhin="FHIN_FSSP";
    $Lread_alis=1;
    $#des=$#des_ali=0;
    foreach $des(@des_in){
	if ($des!~/seq|sec|acc/){
	    push(@des,$des);}
	else {
	    push(@des_ali,$des);}}
				# check existence
    if (! -e $fileInLoc){
	print "*** ERROR fssp_rd_one: fssp file '$fileInLoc' missing\n";
	exit;}
				# read file
    $Lis_old=0;
    &open_file("$fhin", "$fileInLoc");
    while ( <$fhin> ) { 
	if (/NOTATION/) {
	    $Lis_old=1;}
	last if (/^\#\# PROTEINS|^\#\# SUMMARY/); }
    while ( <$fhin> ) {
	$_=~s/^\s*//g;
	if ( (length($_)<2) || (/^\#\# ALI/) ) { # store and out
	    $tmpline=$_;
	    last;}
	if ( /^NR\./ ) { # read header
	    $tmp1=substr($_,1,70); 
	    $_=~s/^\s*|\s*$//g;	# purge leading blanks
	    $#tmp=0;
	    @tmp=split(/\s+/,$_);
	    $it=0;
	    foreach $tmp (@tmp){
		++$it;
		if ($tmp=~/STRID2|PDBID2/){ # search STRID2 (pdbid of 2nd protein)
		    $id2_col=$it;}
		if ($tmp=~/NR/){ # search column for number of hit
		    $nr_col=$it;}
		foreach $des (@des) {if ($tmp =~ /$des/) { $ptr_rd2des{"$des"}=$it; last; }}
	    } }
				# read protein info in header
	else {
	    $_=~s/^\s*|\:|\s*$//g;	# purge leading blanks
	    $#tmp=0;
	    @tmp=split(/\s+/,$_);
	    $id2=$tmp[$id2_col];
	    $id2=~s/-//g;	# correct chain
	    if ($id2=~/$id_in/) {
		$nr_search=$tmp[$nr_col];
		foreach $des (@des) {
		    if (defined $ptr_rd2des{"$des"}){
			$tmp=$ptr_rd2des{"$des"};
			$rdLoc{"$des"}=$tmp[$tmp];$rdLoc{"$des"}=~s/\s|://g;}
		    else {
			print "*-* WARNING: fssp_rd_one not defined des=$des,\n";} }
	    } }
    }
    if ($Lread_alis) {		# read alignments
	$Lok=0;$line_ali="";
	while ( <$fhin> ) {
	    last if ( /^\#\# EQUI/ );
	    if ( ($tmpline =~ /\#/) || (/\#/) ) { # extract range
		if ($Lok){
		    last;}
		if ($tmpline=~/\#/){
		    $tmp=$tmpline;
		    $tmpline=" ";}
		else {
		    $tmp=$_;}
		$tmp=~s/^.+ALIGNMENTS\s+//g;
		$tmp=~s/\s//g;
		$tmp=~s/(\d+)-(\d+)//g;
		$nr1=$1;$nr2=$2;
		if ( ($nr1<=$nr_search) && ($nr_search<=$nr2) ) { # correct range?
		    $Lok=1; } }
	    if ($Lok && (length($_)>3)) {
		$line_ali.="$_"; }
	}
	if (!$Lok){
	    print "*** ERROR fssp_rd_one: didn't read any ali\n";
	    print "***       desired id2=$id_in, nr=$nr_search,\n";
	    exit; }
	%rdLoc=0;
	if ($Lis_old){
	    %rd_tmp=&fssp_rd_ali($line_ali,$nr_search,"is_old");}
	else {
	    %rd_tmp=&fssp_rd_ali($line_ali,$nr_search);}
    }				# end of reading alignments
    close($fhin);
    foreach $des(@des_ali){
	$tmp=$des."1";
	$rdLoc{"$tmp"}=$rd_tmp{"$tmp"};
	$tmp=$des."2";
	$rdLoc{"$tmp"}=$rd_tmp{"$tmp","$nr_search"};}
    return(%rdLoc);
}				# end of fssp_rd_one

#===============================================================================
sub func_absolute {
    local ($num)=@_;local ($tmp);
#----------------------------------------------------------------------
#   func_absolute               compiles the absolute value
#       in:                     $num
#       out:                    returned |$num|
#----------------------------------------------------------------------
    if ($num>=0){
	return($num);}
    else {
	$tmp=(-1)*$num;
	return($tmp);}
}				# end of func_absolute

#===============================================================================
sub func_faculty {
    local ($num)=@_;
    local ($tmp,$it,$prd);
    $[ =1;
#----------------------------------------------------------------------
#   func_faculty                compiles the faculty
#       in:                     $num
#       out:                    returned $fac
#----------------------------------------------------------------------
    $prd=1;
    foreach $it (1..$num){
	$prd=$prd*$it; }
    return ($prd);
}				# end of func_faculty

#===============================================================================
sub func_n_over_k {
    local ($n,$k)=@_;
    local ($res,$t1,$t2,$t3);
#----------------------------------------------------------------------
#   func_n_over_k               compiles N over K
#       in:                     $n,$k
#       out:                    returned $res
#----------------------------------------------------------------------
    $res=1;
    if ($k==0){
	return(1);}
    elsif ($k==$n){
	return(1);}
    else {
	$t1=&func_faculty($n);
	$t2=&func_faculty($k);
	$t3=&func_faculty(($n-$k));
	$res=$t1/($t2*$t3); 
	return($res);}
}				# end of func_n_over_k

#===============================================================================
sub func_n_over_k_sum {
    local ($n)=@_;
    local ($sum,$it,$tmp);
#----------------------------------------------------------------------
#   func_n_over_k_sum           compiles sum/i {N over i}
#       in:                     $n,$k
#       out:                    returned $res
#----------------------------------------------------------------------
    $sum=0;
    foreach $it (1..$n){
	$tmp=&func_n_over_k($n,$it);
	$sum+=$tmp;
    }
    return($sum);
}				# end of func_n_over_k_sum

#===============================================================================
sub func_permut_mod {
    local ($num)=@_;
    local (@mod_out,@mod_in,@mod,$it,$tmp,$it2,@tmp); 
    $[=1;
#----------------------------------------------------------------------
#   func_permut_mod             computes all possible permutations for $num, e.g. n=4:
#                               output is : '1,2' '1,3' '1,4' '2,3' asf.
#       in:                     $num
#       out:                    @permutations (as text:'n,m,..')
#----------------------------------------------------------------------
    $#mod=$#mod_out=0;
    foreach $it (1..$num){
	if ($it==1) { 
	    foreach $it2 (1 .. $num) {
		$tmp="$it2"; 
		push(@mod,$tmp);} }
	else {
	    @mod_in=@mod;
	    @mod=&func_permut_mod_iterate($num,@mod_in); }
	push(@mod_out,@mod); }
    return(@mod_out);
}				# end of func_permut_mod

#===============================================================================
sub func_permut_mod_iterate {
    local ($num,@mod_in)=@_;
    local (@mod_out,$it,$tmp,@tmp); 
    $[=1;
#----------------------------------------------------------------------
#   func_permut_mod_iterate     repeats permutations (called by func_permut_mod)
#                               computes all possible permutations for $num 
#                               (e.g. =4) as maximum, and
#       input is :              '1,2' '1,3' '1,4' '2,3' asf.
#----------------------------------------------------------------------
    $#mod_out=0;
    foreach $it (1..$#mod_in){
	@tmp=split(/,/,$mod_in[$it]);
	foreach $it2 (($tmp[$#tmp]+1) .. $num) {
	    $tmp="$mod_in[$it]".","."$it2";
	    push(@mod_out,$tmp);}}
    return(@mod_out);
}				# end of func_permut_mod_iterate

#===============================================================================
sub funcAddMatdb2prof {
    local($profRdLoc,$profDbLoc,$naliLoc,$naliSatLoc) = @_ ;
    local($sbrName);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   funcAddMatdb2prof           combines profile read + db matrix (for nali < x)
#                               two cases:
#                               
#                               (1) nali >= naliSat:
#        NEWprof = READprof 
#                               
#                               (2) nali < naliSat
#                      1                                                       
#        NEWprof = ---------  * ( naliNorm * READprof + (naliSat - naliNorm) * DBprof )
#                   naliSat                                                 
#                               with naliNorm = nali - 1
#                               
#       in:                     $profRd       : the profile read in HSSP
#                                   ='R->V,R->L,R->I,...,R->D' 
#       in:                     $profDb       : one row of the substitution matrix
#                                   ='R->V,R->L,R->I,...,R->D' 
#       in:                     $naliLoc      : number of alignments (drives mixture)
#       in:                     $naliSatLoc   : number of alignments when no db taken
#       out:                    1|0,msg,$profNew
#                                   ='R->V,R->L,R->I,...,R->D' 
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."funcAddMatdb2prof"; 
				# ------------------------------
				# check arguments
    return(&errSbr("not def profRdLoc!"))            if (! defined $profRdLoc);
    return(&errSbr("not def profDbLoc!"))            if (! defined $profDbLoc);
    return(&errSbr("not def naliLoc!"))              if (! defined $naliLoc);
    return(&errSbr("not def naliSatLoc!"))           if (! defined $naliSatLoc);
    return(&errSbr("naliSatLoc=$naliSatLoc, b.s.!")) if ($naliSatLoc < 1);
	
#    return(&errSbr("not def !"))          if (! defined $);
				# ------------------------------
				# saturation
    return(1,"ok saturation",$profRdLoc) if ($naliLoc >= $naliSatLoc);
#    $naliNorm=$naliLoc - 1;  
#    $naliNorm=0                 if ($naliNorm < 0);
    $naliNorm=$naliLoc;  
    $naliNorm=1                 if ($naliNorm < 1);
				# ------------------------------
				# digest input
    $profRdLoc=~s/^,*|,*$//g;   @profRdLoc=split(/,/,$profRdLoc);
    $profDbLoc=~s/^,*|,*$//g;   @profDbLoc=split(/,/,$profDbLoc);

				# ------------------------------
				# mix
    $fac=(1/$naliSatLoc); $#tmp=0; 
    foreach $itTmp (1..$#profRdLoc) {
	$new=$fac * ( $naliNorm * $profRdLoc[$itTmp] +
		     ($naliSatLoc - $naliNorm) * $profDbLoc[$itTmp] ); 
	push(@tmp,$new); }
    $mix=join(',',@tmp); 
				# ------------------------------
				# output
    return(1,"ok $sbrName",$mix);
}				# end of funcAddMatdb2prof

#===============================================================================
sub funcInfoConditional {
    local($Lfano,$Lrobson,$Lbayes,%tmpLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   funcInfoConditional         Fano information
#                               R. Fano, Transmission of information, Wiley, New York, 1961
#                               
#                               S= state
#                               R= residue (feature)
#                               f= counts
#                               N= total number of residues, counts
#                               
#                               I (S;R) = log [ ( f(S,R) / f(R) ) / (f(S) / N) ]
#                               
#                               information difference:
#                               B. Robson, Biochem J., 141, 853 (1974)
#                               
#                               I (DelS;R)=I(S;R)-I(!S;R)=
#                                          log [ f(S,R)/f(!S,R) ] + log [ f(!S)/f(S) ]
#                               
#				Bayes
#				                P(S) * P(R|S)
#				P(S|R) =  -------------------------
#				          SUM/j { P(Sj) * P(R|Sj) }
#				           
#				P(S|R) = probability for state S, given res R
#                               
#       in:                     $Lfano=  1|0:    compile fano info
#       in:                     $Lrobson=1|0:    compile robsons info diff
#       in:                     $Lbayes= 1|0:    compile bayes prob
#       in:                     $tmp{}:
#                               $tmp{"S"}=       "s1,s2,.."
#                               $tmp{"R"}=       "r1,r2,.."
#                               $tmp{"$R","$S"}= count of the number of residues $res in state $S
#       out:                    1|0,msg,  $res{}
#                               $res{"Rsum","$r"}=              sum for res $r
#                               $res{"Ssum","$s"}=              sum for state $s
#                               $res{"sum"}=                    total sum
#                               $res{"fano","$r","$s"}=         Fano information
#                               $res{"robson","$r","$s"}=       Robson information difference
#                               $res{"bayes","$r","$s"}=        Bayes prob (S|R, i.e. given R->S)
#                               $res{"bayes","Rsum","$r"}=      Bayes sum over all states for res $r
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."funcInfoConditional";$fhinLoc="FHIN_"."funcInfoConditional";
				# ------------------------------
				# get states/features
    return(&errSbr("tmp{R} not defined")) if (! defined $tmpLoc{"R"});
    return(&errSbr("tmp{S} not defined")) if (! defined $tmpLoc{"S"});
    $tmpLoc{"R"}=~s/^,*|,*$//g;
    $tmpLoc{"S"}=~s/^,*|,*$//g;
    @resLoc=split(/,/,$tmpLoc{"R"});
    @secLoc=split(/,/,$tmpLoc{"S"});
    undef %tmp2;
				# ------------------------------
    $sum=0;			# compile sums
    foreach $r (@resLoc) {	# features
	$tmp2{"Rsum","$r"}=0; 
	foreach $s (@secLoc) { 
	    $tmp2{"Rsum","$r"}+=$tmpLoc{"$r","$s"}; }
	$sum+=$tmp2{"Rsum","$r"};}
    foreach $s (@secLoc) {	# states
	$tmp2{"Ssum","$s"}=0; 
	foreach $r (@resLoc) { 
	    $tmp2{"Ssum","$s"}+=$tmpLoc{"$r","$s"}; }}
    $tmp2{"sum"}=$sum;
	
				# --------------------------------------------------
				# info (fano)
				# --------------------------------------------------
    if ($Lfano){
	foreach $r (@resLoc) {
	    $nr=$tmp2{"Rsum","$r"};
	    foreach $s (@secLoc) { 
		$up=0;
		$up=$tmpLoc{"$r","$s"}/$nr                  if ($nr>0);
		$lo=$tmp2{"Ssum","$s"}/$sum;
		$info=0;
		if ($lo>0){$info=$up/$lo;
			   $info=log($info)                 if ($info!=0); } 

		$tmp2{"fano","$r","$s"}=$info;
	    } }
    }

				# --------------------------------------------------
				# info DIFF (robson)
				# I (DelS;R)=I(S;R)-I(!S;R)=
				#        log [ f(S,R)/f(!S,R) ] + log [ f(!S)/f(S) ]
				# --------------------------------------------------
    if ($Lrobson){
	foreach $r (@resLoc) {
	    foreach $s (@secLoc) { 
		$neg=0;
		foreach $s2 (@secLoc) { next if ($s2 eq $s);
					$neg+=$tmpLoc{"$r","$s2"}; }
		$one=0;
		$one=$tmpLoc{"$r","$s"}/$neg                if ($neg>0);
		$one=log($one)                              if ($one>0);
		
		$two=0;
		$two=($sum-$tmp2{"Ssum","$s"})
		    /$tmp2{"Ssum","$s"}                     if ($tmp2{"Ssum","$s"}>0);
		$two=log($two)                              if ($two>0);
	    
		$tmp2{"robson","$r","$s"}=$one+$two; 
	    }} 
    }
				# --------------------------------------------------
				# Bayes
				#                    P(S) * P(R|S)
				# P(S|R) =  -------------------------
				#           SUM/j { P(Sj) * P(R|Sj) }
				#           
				# P(S|R) = probability for state S, given res R
				# --------------------------------------------------
    if ($Lbayes){
				# (1) get P(S) = SUM/j { P(Rj) * P(S|Rj) }
	foreach $s (@secLoc) { 
	    $tmp2{"bayes","pS","$s"}=0;
	    $tmp2{"bayes","pS","$s"}=($tmp2{"Ssum","$s"}/$sum)   if ($sum > 0);
	}
				# (2) get P(R|S)
	foreach $r (@resLoc) {
	    foreach $s (@secLoc) { 
		$tmp2{"bayes","RS","$r","$s"}=0;
		$tmp2{"bayes","RS","$r","$s"}=
		    ($tmpLoc{"$r","$s"}/$tmp2{"Ssum","$s"}) if ($tmp2{"Ssum","$s"} > 0); 
	    } }

				# (3) get P(S|R) = Bayes
	foreach $s (@secLoc) { 
	    foreach $r (@resLoc) {
		$tmp=0;
		foreach $s2 (@secLoc) { 
		    $tmp+= ( $tmp2{"bayes","pS","$s2"} * $tmp2{"bayes","RS","$r","$s2"} ); }
		$tmp2{"bayes","$r","$s"}=0;
		$tmp2{"bayes","$r","$s"}=
		    ($tmp2{"bayes","pS","$s"}*$tmp2{"bayes","RS","$r","$s"}) / $tmp 
			if ($tmp > 0);
	    } }
	foreach $r (@resLoc) {	# (4) get sum P(S|R) over S
	    $tmp=0;
	    foreach $s (@secLoc) { 
		$tmp+=$tmp2{"bayes","$r","$s"}; }
	    $tmp2{"bayes","Rsum","$r"}=$tmp; }
    }
				# ------------------------------
    undef %tmpLoc;		# slim-is-in!

    return(1,"ok $sbrName",%tmp2);
}				# end of funcInfoConditional

#===============================================================================
sub funcLog {
    local ($numLoc,$baseLoc)=@_;
    $[ =1;
#----------------------------------------------------------------------
#   funcLog                    converts the perl log (base e) to any log
#       in:                     $num,$base
#       out:                    log($num)/log($base)
#----------------------------------------------------------------------
    if (($numLoc==0) || (! defined $numLoc)) {
	return "*** funcLog: log (0) not defined\n";}
    if (($baseLoc<=0)|| (! defined $baseLoc)) {
	return "*** funcLog: base must be > 0 is '$baseLoc'\n";}
    return (log($numLoc)/log($baseLoc));
}				# end of funcLog

#===============================================================================
sub funcNormMinMax {
    local($numLoc,$minNow,$maxNow,$minWant,$maxWant) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   funcNormMinMax              normalises numbers with (min1,max1) to a range of (min0,max0)
#                               
#                               N(new) = N(now) * S + ( Min(want) - Min(now) * S )
#                               
#                               with S:
#                                         Max(want) - Min(want)
#                               S      =  ---------------------
#                                         Max(now)  - Min(now)
#                               
#       in:                     $numLoc,$minNow,$maxNow,$minWant,$maxWant
#       out:                    1|0,msg,$numNew
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."funcNormMinMax";$fhinLoc="FHIN_"."funcNormMinMax";
    return(0,"no minNow")                           if (! defined $minNow);
    return(0,"no maxNow")                           if (! defined $maxNow);
    return(0,"no minWant")                          if (! defined $minWant);
    return(0,"no maxWant")                          if (! defined $maxWant);
    $diffNow=$maxNow-$minNow;
    return(0,"maxNow-minNow ($maxNow,$minNow)=0 !") if ($diffNow==0);
    $scale= ( $maxWant-$minWant ) / $diffNow;
    $new=   $numLoc * $scale + ($minWant - $minNow * $scale);
    return(1,"ok $sbrName",$new);
}				# end of funcNormMinMax

#===============================================================================
sub gcgRd {
    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   gcgRd                       reads sequence in GCG format
#       in:                     $fileInLoc
#       out:                    1|0,$id,$seq 
#       err:                    ok=(1,id,seq), err=(0,'msg')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:gcgRd";$fhinLoc="FHIN_"."$sbrName";

    &open_file("$fhinLoc","$fileInLoc") ||
	return(0,"*** ERROR $sbrName: old '$fileInLoc' not opened\n"," ");

    $seq="";
    while (<$fhinLoc>) {
	$_=~s/\n//g;$line=$_;
	if ($line=~/^\s*(\S+)\s*from\s*:/){
	    $id=$1;
	    next;}
	next if ($line !~ /^\s*\d+\s+(.*)$/);
	$tmp=$1;$tmp=~s/\s//g;
	$seq.=$tmp;}close($fhinLoc);

    return(0,"*** ERROR $sbrName: file=$fileInLoc, no sequence found\n") if (length($seq)<1);
    return(1,$id,$seq);
}				# end of gcgRd

#===============================================================================
sub get_chain { local ($file) = @_ ; local($chain);$[ =1 ;
#--------------------------------------------------------------------------------
#   get_chain                   extracts a chain identifier from file name
#                               note: assume: '_X' where X is the chain (return upper)
#       in:                     $file
#       out:                    $chain
#--------------------------------------------------------------------------------
		$chain=$file;
		$chain=~s/\n//g;
		$chain=~s/^.*_(.)$/$1/;
		$chain=~tr/[a-z]/[A-Z]/;
		return($chain);
}				# end of get_chain

#===============================================================================
sub get_hssp_file { 
    local($fileInLoc,$Lscreen,@dir) = @_ ; 
    local($hssp_file,$dir,$tmp,$chain,$Lis_endless,@dir2);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   get_hssp_file               searches all directories for existing HSSP file
#       in:                     $fileInLoc,$Lscreen,@dir
#       out:                    $file,$chain (sometimes)
#--------------------------------------------------------------------------------
    $#dir2=0;$Lis_endless=0;$chain="";
    foreach $dir(@dir){		# avoid endless loop when calling itself
	if ($dir !~ /is_endless/){push(@dir2,$dir);}else {$Lis_endless=1;}}
    @dir=@dir2;
    
    if ($Lscreen !~ /[01]/){push(@dir,$Lscreen);$Lscreen=0;}
    $hssp_file=$fileInLoc;$hssp_file=~s/\s|\n//g;
    foreach $dir (@dir) {
	$dir=&complete_dir($dir); # add slash at end?
	$tmp="$dir"."$hssp_file"; # try directory
	if ($Lscreen)           { print "--- get_hssp_file: \t trying '$tmp'\n";}
	if (-e $tmp) { $hssp_file=$tmp;
		       last;}
	if ($tmp!~/\.hssp/) {	# missing extension?
	    $tmp.=".hssp";
	    if ($Lscreen)       { print "--- get_hssp_file: \t trying '$tmp'\n";}
	    if (-e $tmp) { $hssp_file=$tmp;
			   last;}}}
    $hssp_file=~s/\s|\n//g;	# security..
    if ( (! -e $hssp_file) && (! $Lis_endless) ) { # still not: cut
	$tmp_file=$fileInLoc; $tmp_file=~s/^([A-Za-z0-9]+).*(\.hssp.*)$/$1$2/g;
	$hssp_file=&get_hssp_file($tmp_file,$Lscreen,"is_endless",@dir); }
    if ( (! -e $hssp_file) && (! $Lis_endless) ) { # still now assume = chain
	$tmp1=substr($fileInLoc,1,4);$chain=substr($fileInLoc,5,1);
	$tmp_file=$fileInLoc; $tmp_file=~s/^($tmp1).*(\.hssp.*)$/$1$2/;
	$hssp_file=&get_hssp_file($tmp_file,$Lscreen,"is_endless",@dir); }
    if (length($chain)>0) {
	return($hssp_file,$chain);}
    else {
	return($hssp_file);}
}				# end of get_hssp_file

#===============================================================================
sub get_id { local ($file) = @_ ; local($id);$[ =1 ;
#--------------------------------------------------------------------------------
#   get_id                      extracts an identifier from file name
#                               note: assume anything before '.' or '-'
#       in:                     $file
#       out:                    $id
#--------------------------------------------------------------------------------
	     $id=$file;$id=~s/\s|\n//g;$id=~s/.*\///g;$id=~s/\W*(\w+)[.-].*/$1/;
	     return($id);
}				# end of get_id

#===============================================================================
sub get_in_keyboard {
    local($des,$def,$pre,$Lmirror)=@_;local($txt);
#--------------------------------------------------------------------------------
#   get_in_keyboard             gets info from keyboard
#       in:                     $des :    keyword to get
#       in:                     $def :    default settings
#       in:                     $pre :    text string beginning screen output
#                                         default '--- '
#       in:                     $Lmirror: if true, the default is mirrored
#       out:                    $val : value obtained
#--------------------------------------------------------------------------------
    $pre= "---"                 if (! defined $pre);
    $Lmirror=0                  if (! defined $Lmirror || ! $Lmirror);
    $txt="";			# ini
    printf "%-s %-s\n",          $pre,"-" x (79 - length($pre));
    printf "%-s %-15s:%-s\n",    $pre,"type value for",$des; 
    if (defined $def){
	printf "%-s %-15s:%-s\n",$pre,"type RETURN to enter value, or to keep default";
	printf "%-s %-15s>%-s\n",$pre,"default value",$def;}
    else {
	printf "%-s %-15s>%-s\n",$pre,"type RETURN to enter value"; }

    $txt=$def                    if ($Lmirror);	# mirror it
    printf "%-s %-15s>%-s",      $pre,"type",$txt; 

    while(<STDIN>){
	$txt.=$_;
	last if ($_=~/\n/);}     $txt=~s/^\s+|\s+$//g;
    $txt=$def                   if (length($txt) < 1);
    printf "%-s %-15s>%-s\n",    $pre,"--> you chose",$txt;
    return ($txt);
}				# end of get_in_keyboard

#===============================================================================
sub get_in_database_files {
    local ($database,@argLoc) = @_ ;
    local ($fhinLoc,@fileLoc,$rd,$argLoc);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   get_in_database_files       reads command line, checks validity of format, returns array
#       in:                     $opt,@arg, : $opt="HSSP","DSSP","FSSP,"DAF","MSF","RDB",
#       out:                    @files
#--------------------------------------------------------------------------------
    $fhinLoc="FHIN_get_in_files";
    $#fileLoc=0;
    foreach $argLoc(@argLoc){
	$argLoc=~s/\n|\s//g;if (length($argLoc)<5){next;}if (! -e $argLoc){next;}
				# ------------------------------
				# HSSP or DSSP 
	if     (($database eq "HSSP")||($database eq "DSSP")){
	    if ((($database eq "HSSP")&&(&is_hssp_list($argLoc))) || 
		(($database eq "DSSP")&&(&is_dssp_list($argLoc)))){
		$file=$argLoc; &open_file("$fhinLoc","$file");
		while(<$fhinLoc>){$rd=$_;$rd=~s/\s|\n//g;
				  if (length($rd)<5){next;}$rdChain=$rd;
				  if(! -e $rd){$rd=~s/_.$//;} # purge chain
				  if (! -e $rd){next;}
				  push(@fileLoc,$rdChain);}close($fhin);}
	    elsif ((($database eq "HSSP")&&(&is_hssp($argLoc))) || 
		   (($database eq "DSSP")&&(&is_dssp($argLoc)))){
		push(@fileLoc,$tmp);}}
				# ------------------------------
				# FSSP
	elsif ($database eq "FSSP"){
	    if (&is_fssp_list($argLoc)){$file=$argLoc; &open_file("$fhinLoc","$file");
					while(<$fhinLoc>){
					    $rd=$_;$rd=~s/\s|\n//g;if (! -e $rd){next;}
					    push(@fileLoc,$rd);}close($fhin);}
	    elsif (&is_fssp($tmp))  {push(@fileLoc,$tmp);}}
	else {
	    print "*** ERROR get_in_database_files: database '$database' not digestable yet\n";
	    exit;}}
    return(@fileLoc);
}				# end of get_in_database_files

#===============================================================================
sub get_max { $[=1;local($ct,$pos,$max);$max=-1000000;$ct=$pos=0; 
#----------------------------------------------------------------------
#   get_max                     returns the maximum of all elements of @in
#       in:                     @in
#       out:                    returned $max,$pos (position of maximum)
#----------------------------------------------------------------------
	      foreach $_(@_){if(defined $_){
		  ++$ct; 
		  if($_>$max){$max=$_;$pos=$ct;}}}
	      return ($max,$pos); } # end of get_max

#===============================================================================
sub get_min { $[=1;local($ct,$pos,$min);$min=100000; $ct=0; 
#----------------------------------------------------------------------
#   get_min                     returns the minimum of all elements of @in
#       in:                     @in
#       out:                    returned $min,$pos (position of minimum)
#----------------------------------------------------------------------
	      foreach $_(@_){++$ct; if($_<$min){$min=$_;$pos=$ct;}}
	      return ($min,$pos); } # end of get_min

#===============================================================================
sub get_pdbid { local ($file) = @_ ; local($id);$[ =1 ;
#--------------------------------------------------------------------------------
#   get_pdbid                   extracts a valid PDB identifier from file name
#                               note: assume \w\w\w\w
#       in:                     $file
#       out:                    $id
#--------------------------------------------------------------------------------
		$id=$file;$id=~s/\s|\n//g;$id=~s/.*\///g;$id=~s/\W*(\w\w\w\w).*/$1/;
		return($id);
}				# end of get_pdbid

#===============================================================================
sub get_range {
    local ($range_txt,$nall) = @_;
    local (@range,@rangeLoc,$it,$range1,$range2);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   get_range                   converts range=n1-n2 into @range (1,2)
#       in:                     'n1-n2' NALL: e.g. incl=1-5,9,15 
#                               n1= begin, n2 = end, * for wild card
#                               NALL = number of last position
#       out:                    @takeLoc: begin,begin+1,...,end-1,end
#--------------------------------------------------------------------------------
    $#range=0;
    if (! defined $range_txt || length($range_txt)<1 || $range_txt eq "unk" 
	|| $range_txt !~/\d/ ) {
	print "*** ERROR in get_range: argument: range=$range_txt, nall=$nall, not digestable\n"; 
	return(0);}
    $range_txt=~s/\s//g;	# purge blanks
    $nall=0                     if (! defined $nall);
				# already only a number
    return($range_txt)          if ($range_txt !~/[^0-9]/);
    
    if ($range_txt !~/[\-,]/) {	# no range given
	print "*** ERROR in get_range: argument: '$range_txt,$nall' not digestable\n"; 
	return(0);}
				# ------------------------------
				# dissect commata
    if    ($range_txt =~ /\,/) {
	@range=split(/,/,$range_txt);}
				# ------------------------------
				# dissect hyphens
    elsif ($range_txt =~ /(\d*|\*)-(\d*|\*)/) { 
	@range=&get_rangeHyphen($range_txt,$nall);}

				# ------------------------------
				# process further elements with hyphens
    $#range2=0;
    foreach $range (@range){
	if ($range =~ /(\d*|\*)-(\d*|\*)/) {
	    push(@range2,&get_rangeHyphen($range,$nall));}
	else {
            push(@range2,$range);}}
    @range=@range2; $#range2=0;
				# ------------------------------
    if ($#range>1){		# sort
	@range=sort {$a<=>$b} @range;}
    return (@range);
}				# end of get_range

#===============================================================================
sub get_rangeHyphen {
    local ($range_txt,$nall) = @_ ;
    local (@rangeLoc,$it,$range1,$range2);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   get_rangeHyphen             reads 'n1-n2'  
#       in:                     'n1-n2', NALL (n1= begin, n2 = end, * for wild card)
#                               NALL = number of last position
#       out:                    begin,begin+1,...,end-1,end
#--------------------------------------------------------------------------------
    if ($range_txt =~ /(\d*|\*)-(\d*|\*)/) { 
	($range1,$range2)=split(/-/,$range_txt);
	if ($range1=~/\*/) {$range1=1;}
	if ($range2=~/\*/) {$range2=$nall;} 
	for($it=$range1;$it<=$range2;++$it) {push(@rangeLoc,$it);} }
    else { @rangeLoc=($range_txt);}
    return(@rangeLoc);
}				# end of get_rangeHyphen

#===============================================================================
sub get_secstr_segment_caps {
    local ($string,@des) = @_ ;
    local ($des,$it,@beg,@end,%segment);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   get_secstr_segment_caps     returns positions of secondary str. segments in string
#       out:                    $segment{"H","beg",1}= first residue in first helix
#                               $segment{"H","end",1}= last residue in first helix
#--------------------------------------------------------------------------------
				# convert vector to array (begin and end different)
    @aa=("#");push(@aa,split(//,$string)); push(@aa,"#");

    foreach $des (@des) {
	$#beg=$#end=0;		# loop over all residues
	foreach $it ( 2 .. $#aa ){ # note 1st and last ="#"
	    if   ( ($aa[$it] ne "$des") && ($aa[$it-1] eq "$des") ){
		push(@end,($it-2)); }
	    elsif( ($aa[$it] eq "$des") && ($aa[$it-1] ne "$des") ){
		push(@beg,($it-1)); }  }
	if ($#end != $#beg) {	# consistency check!
	    print "*** get_secstr_segment_caps: des=$des, Nend=",$#end,", Nbeg=",$#beg,",\n";
	    exit;}
	foreach $it (1..$#end){	# store segment begins (Ncap) and ends (Ccap)
	    $segment{"$des","beg","$it"}=$beg[$it];
	    $segment{"$des","end","$it"}=$end[$it]; } 
	$segment{"$des","NROWS"}=$#beg;
    }
    return(%segment);
}				# end of get_secstr_segment_caps

#===============================================================================
sub get_sum { local(@data)=@_;local($it,$ave,$var,$sum);$[=1;
#----------------------------------------------------------------------
#   get_sum                     computes the sum over input data
#       in:                     @data
#       out:                    $sum,$ave,$var
#----------------------------------------------------------------------
	      $sum=0;foreach $_(@_){if(defined $_){$sum+=$_;}}
	      ($ave,$var)=&stat_avevar(@data);
	      return ($sum,$ave,$var); } # end of get_sum

#===============================================================================
sub get_zscore { local ($score,@data) = @_ ; local ($ave,$var,$sig,$zscore);
		 $[ =1 ;
#--------------------------------------------------------------------------------
#   get_zscore                  returns the zscore = (score-ave)/sigma
#       in:                     $score,@data
#       out:                    zscore
#--------------------------------------------------------------------------------
		 ($ave,$var)=&stat_avevar(@data);
		 $sig=sqrt($var);
		 if ($sig != 0){ $zscore=($score-$ave)/$sig; }
		 else          { print"x.x get_zscore: sig=$sig,=0?\n";$zscore=0; }
		 return ($zscore);
}				# end of get_zscore

#===============================================================================
sub getDistanceHsspCurve {
    local ($laliLoc,$laliMaxLoc) = @_ ;
    $[=1;
#--------------------------------------------------------------------------------
#   getDistanceHsspCurve        computes the HSSP curve for in:    ali length
#       in:                     $lali,$lailMax
#                               note1: thresh=0 for HSSP, 5 for 30%, -5 for 20% ..
#                               note2: saturation at 100
#       out:                    value curve (i.e. percentage identity)
#                               HSSP-curve  according to t(L)=(290.15 * L ** -0.562)
#--------------------------------------------------------------------------------
    $sbrName="lib-br:getDistanceHsspCurve";
    return(0,"*** ERROR $sbrName: lali not defined \n") if (! defined $laliLoc);
    return(0,"*** ERROR $sbrName: '$laliLoc' = alignment length??\n") 
	if (length($laliLoc)<1 || $laliLoc=~/[^0-9.]/);
    $laliMaxLoc=100             if (! defined $laliMaxLoc);
    $laliLoc=~s/\s//g;

    $laliLoc=$laliMaxLoc        if ($laliLoc > $laliMaxLoc);	# saturation
    $val= 290.15*($laliLoc **(-0.562)); 
    $val=100                    if ($val > 100);
    $val=25                     if ($val < 25);
    return ($val,"ok $sbrName");
}				# end getDistanceHsspCurve

#===============================================================================
sub getDistanceNewCurveIde {
    local($laliLoc)=@_; local($expon,$loc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getDistanceNewCurveIde      out= pide value for new curve
#       in:                     $lali
#       out:                    $pide
#                               pide= 510 * L ^ { -0.32 (1 + e ^-(L/1000)) }
#-------------------------------------------------------------------------------
    $sbrName="lib-br:getDistanceNewCurveIde";
    return(0,"*** ERROR $sbrName: lali not defined \n") if (! defined $laliLoc);
    return(0,"*** ERROR $sbrName: '$laliLoc' = alignment length??\n") 
	if (length($laliLoc)<1 || $laliLoc=~/[^0-9.]/);

    $expon= - 0.32 * ( 1 + exp (-$laliLoc/1000) );
    $loc= 510 * $laliLoc ** ($expon);
    $loc=100 if ($loc>100);     # saturation
    return($loc,"ok $sbrName");
}				# end of getDistanceNewCurveIde

#===============================================================================
sub getDistanceNewCurveSim {
    local($laliLoc)=@_; local($expon,$loc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getDistanceNewCurveSim      out= psim value for new curve
#       in:                     $lali
#       out:                    $sim
#                               psim= 420 * L ^ { -0.335 (1 + e ^-(L/2000)) }
#-------------------------------------------------------------------------------
    $sbrName="lib-br:getDistanceNewCurveSim";
    return(0,"*** ERROR $sbrName: lali not defined \n") if (! defined $laliLoc);
    return(0,"*** ERROR $sbrName: '$laliLoc' = alignment length??\n") 
	if (length($laliLoc)<1 || $laliLoc=~/[^0-9.]/);

    $expon= - 0.335 * ( 1 + exp (-$laliLoc/2000) );
    $loc= 420 * $laliLoc ** ($expon);
    $loc=100 if ($loc>100);     # saturation
    return($loc,"ok $sbrName");
}				# end of getDistanceNewCurveSim

#===============================================================================
sub getDistanceThresh {
    local($modeLoc,$laliLoc,$pideLoc) = @_ ;
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getDistanceThresh           compiles the distance from a threshold
#       in:                     $modeLoc: which filter ('old|new|newIde|newSim')
#       in:                     $laliLoc: alignment length
#       in:                     $pideLoc: percentages sequence identity/similarity
#       out:                    1|0,msg,$dist
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR="lib-br:"."getDistanceThresh";$fhinLoc="FHIN_"."getDistanceThresh";
				# check arguments
    return(&errSbr("not def modeLoc!",$SBR))          if (! defined $modeLoc);
    return(&errSbr("not def laliLoc!",$SBR))          if (! defined $laliLoc);
    return(&errSbr("not def pideLoc!",$SBR))          if (! defined $pideLoc);

    return(&errSbr("mode must be 'old|new|newSim' is '$modeLoc'",$SBR))
	if ($modeLoc !~ /^(old|new|newIde|newSim)$/i);
    return(&errSbr("lali must be integer is '$laliLoc'",$SBR)) if ($laliLoc !~ /^\d+$/);
    return(&errSbr("pide must be number 0..100 is '$pideLoc'",$SBR)) 
	if ($pideLoc !~ /^[\d\.]+$/ || $pideLoc < 0 || $pideLoc > 100);
	
				# ------------------------------
				# distance from threshold:
    if    ($modeLoc eq "old"){
	($pideCurve,$msg)= 
	    &getDistanceHsspCurve($lali); 
	return(&errSbrMsg("failed getDistanceHsspCurve",$msg,$SBR))  if ($msg !~ /^ok/); }
    elsif ($modeLoc =~ /^newSim$/i){
	($pideCurve,$msg)= &getDistanceNewCurveSim($lali); 
	return(&errSbrMsg("failed getDistanceNewCurveSim",$msg,$SBR))  if ($msg !~ /^ok/); }
    else {
	($pideCurve,$msg)= &getDistanceNewCurveIde($lali); 
	return(&errSbrMsg("failed getDistanceNewCurveIde",$msg,$SBR))  if ($msg !~ /^ok/); }

    $dist=$pideLoc - $pideCurve;
    return(1,"ok $sbrName",$dist);
}				# end of getDistanceThresh

#===============================================================================
sub getFileFormat {
    local ($fileInLoc,$kwdLoc,@dirLoc) = @_ ;
    local ($sbrName,$fhinLoc,$tmp,@tmpFile,@tmpChain,
	   @formatLoc,@fileLoc,@chainLoc,%fileLoc,@fileRdLoc,$Lok,$txtLoc,$file);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getFileFormat               returns format of file
#       in:                     $file
#                               $kwd = any|HSSP|DSSP|FSSP|SWISS|DAF|MSF|RDB|FASTA|PIR
#                               @dir = directories to search for files
#       out:                    $Lok,$msg,%fileFound
#                               $fileFound{"NROWS"}=      number of files found
#                               $fileFound{"ct"}=         name-of-file-ct
#                               $fileFound{"format","ct"}=format
#                               $fileFound{"chain","ct"}= chain
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."getFileFormat";$fhinLoc="FHIN"."$sbrName";
    undef %fileLoc;
    if ($#dirLoc >0){$#tmp=0;	# include existing directories only
		     foreach $dirLoc(@dirLoc){
			 push(@tmp,$dirLoc) if (-d $dirLoc)}
		     @dirLoc=@tmp;}
				# check whether keyword understood
    if (! defined $kwdLoc){$kwdLoc="any";}
    if ($kwdLoc !~/^(any|HSSP|DSSP|SWISS|DAF|MSF|RDB|FASTA|PIR)/i){
	print 
	    "-*- WARNING $sbrName wrong input keyword, is=$kwdLoc, \n",
	    "-*-         must be any of: 'any|HSSP|DSSP|SWISS|DAF|RDB|FASTA|PIR'\n";
	return(0,"err","$kwdLoc, wrong keyword",%fileLoc);}

    $#fileLoc=$#chainLoc=$#formatLoc=0;
				# --------------------------------------------------
				# databases
				# --------------------------------------------------
				# ------------------------------
    if ($kwdLoc=~ /HSSP|any/i){	# HSSP
	($Lok,$txtLoc,@fileRdLoc)=
	    &isHsspGeneral($fileInLoc,1,@dirLoc);
	if ($Lok){
	    $#tmpFile=$#tmpChain=$Lchain=0;
	    if    ($txtLoc eq "isHsspList"){
		$Lchain=0;
		foreach $tmp (@fileRdLoc){
		    if   ($tmp eq "chain"){$Lchain=1;}
		    elsif(! $Lchain)      {push(@tmpFile,$tmp);
					   push(@formatLoc,"HSSP");}
		    else                  {push(@tmpChain,$tmp);}}}
				# is single file
	    elsif ($txtLoc eq "isHssp"){
		if ($#fileRdLoc>1){ # one file with chain
		    push(@tmpFile,$fileRdLoc[1]);
		    push(@formatLoc,"HSSP");
		    push(@tmpChain,$fileRdLoc[2]);}
		else {
		    push(@tmpFile,$fileRdLoc[1]);push(@formatLoc,"HSSP");}}
	    elsif ($txtLoc =~ /^no/){ #
		print "*** $sbrName ERROR in HSSP read\n";}
	    elsif ($txtLoc =~ /empty/){
		print "*** $sbrName HSSP read, $fileRdLoc[1] is empty\n";}
	    push(@fileLoc,@tmpFile);
	    push(@chainLoc,@tmpChain);}}

				# ------------------------------
    if ($kwdLoc=~ /DSSP|any/i){	# DSSP
	($Lok,$txtLoc,@fileRdLoc)=
	    &isDsspGeneral($fileInLoc,@dirLoc);
	if ($Lok){
	    $#tmpFile=$#tmpChain=$Lchain=0;
	    if    ($txtLoc eq "isDsspList"){
		$Lchain=0;
		foreach $tmp (@fileRdLoc){
		    if   ($tmp eq "chain"){$Lchain=1;}
		    elsif(! $Lchain)      {push(@tmpFile,$tmp);
					   push(@formatLoc,"DSSP");}
		    else                  {push(@tmpChain,$tmp);}}}
				# is single file
	    elsif ($txtLoc eq "isDssp"){
		if ($#fileRdLoc>1){ # one file with chain
		    push(@tmpFile,$fileRdLoc[1]);
		    push(@formatLoc,"DSSP");
		    push(@tmpChain,$fileRdLoc[2]);}
		else {
		    push(@tmpFile,$fileRdLoc[1]);push(@formatLoc,"DSSP");}}
	    elsif ($txtLoc =~ /^no/){ #
		print "*** $sbrName ERROR in DSSP read\n";}
	    elsif ($txtLoc =~ /empty/){
		print "*** $sbrName DSSP read, $fileRdLoc[1] is empty\n";}
	    push(@fileLoc,@tmpFile);
	    push(@chainLoc,@tmpChain);}}

				# ------------------------------
				# FSSP
    if (!$Lok && ($kwdLoc =~ /FSSP|any/i)){
	($Lok,$txtLoc,@fileRdLoc)=
	    &isFsspGeneral($fileInLoc,@dirLoc);
	if ($Lok){$#tmpFile=$#tmpChain=$Lchain=0;
		  if    ($txtLoc eq "isFsspList"){ # is list
		      $Lchain=0;
		      foreach $tmp (@fileRdLoc){
			  if   ($tmp eq "chain"){$Lchain=1;}
			  elsif(! $Lchain)      {push(@tmpFile,$tmp);push(@formatLoc,"FSSP");}
			  else                  {push(@tmpChain,$tmp);}}}
		  elsif ($txtLoc eq "isFssp"){ # is single
		      if ($#fileRdLoc>1){ # one file with chain
			  push(@tmpFile,$fileRdLoc[1]);push(@formatLoc,"FSSP");
			  push(@tmpChain,$fileRdLoc[2]);}
		      else {push(@tmpFile,$fileRdLoc[1]);push(@formatLoc,"FSSP");}}
		  elsif ($txtLoc =~ /^no/){print "*** $sbrName ERROR in FSSP read\n";}
		  push(@fileLoc,@tmpFile);
		  push(@chainLoc,@tmpChain);}}
				# --------------------------------------------------
				# sequence formats
				# --------------------------------------------------
    if (!$Lok && ($kwdLoc =~ /SWISS|any/i)){
	($Lok,$txtLoc,@fileRdLoc)=&isSwissGeneral($fileInLoc,@dirLoc);
	if ($Lok){push(@fileLoc,@fileRdLoc);
		  foreach (@fileRdLoc){push(@formatLoc,"SWISS");
				       push(@chainLoc," ");}}}
    if (!$Lok && ($kwdLoc =~ /PIR\w*|any/i)){
	($Lok,$txtLoc,@fileRdLoc)=&isPirMul($fileInLoc);
	if ($Lok){push(@fileLoc,@fileRdLoc);
		  foreach (@fileRdLoc){push(@formatLoc,"PIR_MUL");
				       push(@chainLoc," ");}}}
    if (!$Lok && ($kwdLoc =~ /PIR|any/i)){
	($Lok,$txtLoc,@fileRdLoc)=&isPir($fileInLoc);
	if ($Lok){push(@fileLoc,@fileRdLoc);
		  foreach (@fileRdLoc){push(@formatLoc,"PIR");
				       push(@chainLoc," ");}}}
    if (!$Lok && ($kwdLoc =~ /FASTA|any/i)){
	($Lok,$txtLoc,@fileRdLoc)=&isFastaMul($fileInLoc);
	if ($Lok){push(@fileLoc,@fileRdLoc);
		  foreach (@fileRdLoc){push(@formatLoc,"FASTA");
				       push(@chainLoc," ");}}}
    if (!$Lok && ($kwdLoc =~ /FASTA|any/i)){
	($Lok,$txtLoc,@fileRdLoc)=&isFasta($fileInLoc);
	if ($Lok){push(@fileLoc,@fileRdLoc);
		  foreach (@fileRdLoc){push(@formatLoc,"FASTA");
				       push(@chainLoc," ");}}}
				# --------------------------------------------------
				# RDB
				# --------------------------------------------------
    if (!$Lok && ($kwdLoc =~ /RDB|any/i)){
	($Lok,$txtLoc,@fileRdLoc)=&isRdbGeneral($fileInLoc,@dirLoc);
	if ($Lok){push(@fileLoc,@fileRdLoc);
		  foreach (@fileRdLoc){push(@formatLoc,"RDB");
				       push(@chainLoc," ");}}}
				# --------------------------------------------------
				# other alignment formats
				# --------------------------------------------------
    if (!$Lok && ($kwdLoc =~ /MSF|any/i)){
	($Lok,$txtLoc,@fileRdLoc)=&isMsfGeneral($fileInLoc,@dirLoc);
	if ($Lok){push(@fileLoc,@fileRdLoc);
		  foreach (@fileRdLoc){push(@formatLoc,"MSF");
				       push(@chainLoc," ");}}}
    if (!$Lok && ($kwdLoc =~ /DAF|any/i)){
	($Lok,$txtLoc,@fileRdLoc)=&isDafGeneral($fileInLoc,@dirLoc);
	if ($Lok){push(@fileLoc,@fileRdLoc);
		  foreach (@fileRdLoc){push(@formatLoc,"DAF");
				       push(@chainLoc," ");}}}
    if (!$Lok && ($kwdLoc =~ /SAF|any/i)){
	($Lok,$txtLoc,@fileRdLoc)=&isSaf($fileInLoc);
	if ($Lok){push(@fileLoc,@fileRdLoc);
		  foreach (@fileRdLoc){push(@formatLoc,"SAF");
				       push(@chainLoc," ");}}}
    
    return(0,"*** ERROR $sbrName: kwd=$kwdLoc, no file '$fileInLoc' found\n",%fileLoc)
	if (!$Lok || ($#fileLoc<1));

    foreach $it (1..$#fileLoc){
	$fileLoc{"$it"}=$fileLoc[$it];
	$fileLoc{"format","$it"}=$formatLoc[$it];
	if ((defined $chainLoc[$it])&&
	    (length($chainLoc[$it])>0)&&($chainLoc[$it]=~/[A-Za-z0-9]/)){
	    $fileLoc{"chain","$it"}=$chainLoc[$it];}}
    $fileLoc{"NROWS"}=$#fileLoc;
    return(1,"ok",%fileLoc);
}				# end of getFileFormat

#===============================================================================
sub getFileFormatQuick {
    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getFileFormatQuick          quick scan for file format: assumptions
#                               file exists
#                               file is db format (i.e. no list)
#       in:                     file
#       out:                    0|1,format
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."getFileFormatQuick";$fhinLoc="FHIN_"."getFileFormatQuick";
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc!")          if (! defined $fileInLoc);
    return(0,"*** $sbrName: miss in file '$fileInLoc'!")  if (! -e $fileInLoc);
                                # alignments (EMBL 1)
    return(1,"HSSP")         if (&is_hssp($fileInLoc));
    return(1,"STRIP")        if (&is_strip($fileInLoc));
#    return(1,"STRIPOLD")     if (&is_strip_old($fileInLoc));
    return(1,"DSSP")         if (&is_dssp($fileInLoc));
    return(1,"FSSP")         if (&is_fssp($fileInLoc));
                                # alignments (EMBL 1)
    return(1,"DAF")          if (&isDaf($fileInLoc));
    return(1,"SAF")          if (&isSaf($fileInLoc));
                                # alignments other
    return(1,"MSF")          if (&isMsf($fileInLoc));
    return(1,"FASTAMUL")     if (&isFastaMul($fileInLoc));
    return(1,"PIRMUL")       if (&isPirMul($fileInLoc));
                                # sequences
    return(1,"FASTA")        if (&isFasta($fileInLoc));
    return(1,"SWISS")        if (&isSwiss($fileInLoc));
    return(1,"PIR")          if (&isPir($fileInLoc));

    return(1,"GCG")          if (&isGcg($fileInLoc));
                                # PP
    return(1,"PPCOL")        if (&is_ppcol($fileInLoc));
				# NN
    return(1,"NNDB")         if (&is_rdb_nnDb($fileInLoc));
                                # PHD
    return(1,"PHDRDBACC")    if (&isPhdAcc($fileInLoc));
    return(1,"PHDRDBHTM")    if (&isPhdHtm($fileInLoc));
    return(1,"PHDRDBHTMREF") if (&is_rdb_htmref($fileInLoc));
    return(1,"PHDRDBHTMTOP") if (&is_rdb_htmtop($fileInLoc));
    return(1,"PHDRDBSEC")    if (&isPhdSec($fileInLoc));
                                # RDB
    return(1,"RDB")          if (&isRdb($fileInLoc));
    return(1,"unk");
}				# end of getFileFormatQuick

#===============================================================================
sub getPhdSubset {
    local($stringPhdLoc,$stringRelLoc,$relThreshLoc,$relSymLoc) = @_ ;
    local($sbrName);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getPhdSubset                subset from string with PHDsec|acc|htm + rel index
#       in:                     $stringPhdLoc : PHDsec|acc|htm
#       in:                     $stringRelLoc : reliability index (string of numbers [0-9])
#       in:                     $relThreshLoc : >= this -> write to 'subset' row
#       in:                     $relSymLoc    : use this symbol for 'not pred' in subset
#       out:                    1|0,msg,$subset
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."getPhdSubset";$fhinLoc="FHIN_"."getPhdSubset";
				# check arguments
    return(&errSbr("not def stringPhdLoc!"))      if (! defined $stringPhdLoc);
    return(&errSbr("not def stringRelLoc!"))      if (! defined $stringRelLoc);
    return(&errSbr("not def relThreshLoc!"))      if (! defined $relThreshLoc);
    return(&errSbr("not def relSymLoc!"))         if (! defined $relSymLoc);

    @tmpPhd=split(//,$stringPhdLoc);
    @tmpRel=split(//,$stringRelLoc);
    return(&errSbr("stringPhdLoc ne stringRelLoc\n".
		   "phd=$stringPhdLoc\n".
		   "rel=$stringRelLoc\n"))        if ($#tmpPhd != $#tmpRel);

				# ------------------------------
    $out="";			# loop over all residues
    foreach $it (1..$#tmpPhd) {
				# high reliability -> take
	if ($tmpRel[$it] >= $relThreshLoc ) {
	    $out.=$tmpPhd[$it];
	    next; }
	$out.=    $relSymLoc;	# low  reliability -> dot
    }

    $#tmpPhd=$#tmpRel=$#tmp=0;	# slim-is-in!
    return(1,"ok $sbrName",$out);
}				# end of getPhdSubset

#===============================================================================
sub globeOne {
    local($fileInLoc,$fhErrSbr,@passLoc)= @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   globe                       compiles the globularity for a PHD file
#       in:                     file.phdRdb, $fhErrSbr, (with ACC!!)
#       in:                     options as $kwd=value
#       in:                     logicals 'doFixPar', 'doReturn' will set the 
#       in:                        respective parameters to 1
#                               kwd=(lenMin|exposed|isPred|doFixPar
#                                    fit2Ave   |fit2Sig   |fit2Add   |fit2Fac|
#                                    fit2Ave100|fit2Sig100|fit2Add100|fit2Fac100)
#       out:                    1,'ok',len,nexp,nfit,diff,explanation
#       err:                    0,message
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."globe";$fhinLoc="FHIN"."$sbrName";
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc!")   if (! defined $fileInLoc);
    $fhErrSbr="STDOUT"                             if (! defined $fhErrSbr);
    return(0,"*** $sbrName: not def fileInLoc!")   if (! defined $fileInLoc);

				# ------------------------------
				# default settings
    $parSbr{"lenMin"}=   30;	$parSbr{"expl","lenMin"}=  "minimal length of protein";
    $parSbr{"exposed"}=  16;	$parSbr{"expl","exposed"}= "exposed if relAcc > this";
    $parSbr{"isPred"}=    1;	$parSbr{"expl","isPred"}=  "file without observed columns";

				# fit: (N- $fit2Fac*(N^1/3-$fit2Add)^3) 
    $parSbr{"fit2Ave"}=   1.4;	$parSbr{"expl","fit2Ave"}=  "average of fit for data base";
    $parSbr{"fit2Sig"}=   9.9;	$parSbr{"expl","fit2Sig"}=  "1 sigma of fit for data base";
    $parSbr{"fit2Add"}=   0.78; $parSbr{"expl","fit2Add"}=  "add of fit= 'N - fac*(N1/3-add)^3";
    $parSbr{"fit2Fac"}=   0.84;	$parSbr{"expl","fit2Fac"}=  "fac of fit= 'N - fac*(N1/3-add)^3";

    $parSbr{"fit2Ave100"}=0.1;
    $parSbr{"fit2Sig100"}=6.2;
    $parSbr{"fit2Add100"}=0.41;
    $parSbr{"fit2Fac100"}=0.64;
    $parSbr{"doFixPar"}=  0;	$parSbr{"expl","doFixPar"}=
	                                "do NOT change the fit para if length<100";
    @parSbr=("lenMin","exposed","isPred","doFixPar",
	     "fit2Ave",   "fit2Sig",   "fit2Add",   "fit2Fac",
	     "fit2Ave100","fit2Sig100","fit2Add100","fit2Fac100");
				# read command line
    foreach $_(@passLoc){
	$Lok=0;
	if   ($_=~/^isPred/)       {$parSbr{"isPred"}=  1;$Lok=1;}
	elsif($_=~/^fix/)          {$parSbr{"doFixPar"}=1;$Lok=1;}
	elsif($_=~/^[r]eturn/)     {$parSbr{"doReturn"}=1;$Lok=1;}
	foreach $kwd (@par){
	    if ($_=~/^$kwd=(.*)$/) {$parSbr{"$kwd"}=$1;$Lok=1;}}
	return(0,"*** $sbrName: wrong command line arg '$_'\n") if (! $Lok);}
    $exposed=$parSbr{"exposed"};
				# ------------------------------
				# (1) read file
    ($len,$numExposed)=
	&globeRdPhdRdb($fileInLoc,$fhErrSbr);
				# ERROR
    return(0,"*** ERROR $sbrName: $numExposed\n") 
	if (! $len || ! defined $numExposed || $numExposed =~/\D/);
    
				# ------------------------------
				# get the expected number of res
    if (! $parSbr{"doFixPar"} && ($len < 100)){
	$fit2Add=$parSbr{"fit2Add100"};$fit2Fac=$parSbr{"fit2Fac100"};}
    else {
	$fit2Add=$parSbr{"fit2Add"};   $fit2Fac=$parSbr{"fit2Fac"};}

    ($Lok,$numExpect)=
	&globeFuncFit($len,$fit2Add,$fit2Fac,$parSbr{"exposed"});
				# ------------------------------
				# evaluate the result
    $diff=$numExposed-$numExpect;
    if    ($diff > 20){
	$evaluation="your protein may be globular, but it is not as compact as a domain";}
    elsif ($diff > (-5)){
	$evaluation="your protein appears as compact, as a globular domain";}
    elsif ($diff > (-10)){
	$evaluation="your protein appears not as globular, as a domain";}
    else {
	$evaluation="your protein appears not to be globular";}
	
    return(1,"ok $sbrName",$len,$numExposed,$numExpect,$diff,"$evaluation");
}				# end of globeOne

#===============================================================================
sub globeFuncFit {
    local($lenIn,$add,$fac,$expLoc) = @_ ;local($tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   globeFuncFit                length to number of surface molecules fitted to PHD error 
#                               out=(N ^ 1/3 - 2) ^ 3
#       in:                     len, acc-cut-off (allowed: 9, 16)
#       out:                    1,NsurfacePhdFit2
#       err:                    0,'msg'
#-------------------------------------------------------------------------------
    $expLoc=16 if (! defined $expLoc); # default
    if   ($expLoc == 9) {
	return(1,$lenIn - $fac*(($lenIn**(1/3)) - $add)**3);}
    elsif($expLoc == 16) {
	return(1,$lenIn - $fac*(($lenIn**(1/3)) - $add)**3);}
    else{ 
	return(0,"*** ERROR in $scrName globeFuncFit only defined for exp=16 or 9\n");}
}				# end of globeFuncFit

#===============================================================================
sub globeRdPhdRdb {
    local($fileInLoc2,$fhErrSbr2) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok,@tmp,$msgErr,
	  $ctTmp,$Lboth,$Lsec,$len,$numExposed,$lenRd,$rel);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   globeRdPhdRdb               read PHD rdb file with ACC
#       in:                     $fileInLoc,$fhErrSbr2
#       out:                    $len,$numExposed
#       err:                    0,'msg'
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."globeRdPhdRdb";$fhinLoc="FHIN"."$sbrName";
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc2!")        if (! defined $fileInLoc2);
    $fhErrSbr2="STDOUT"                                  if (! defined $fhErrSbr);
    return(0,"*** $sbrName: no in file '$fileInLoc2'!")  if (! -e $fileInLoc2);

    $Lok=       &open_file("$fhinLoc","$fileInLoc2");
    if (! $Lok){print $fhErrSbr2 "*** ERROR $sbrName: '$fileInLoc2' not opened\n";
		return(0);}
				# reading file
    $ctTmp=$Lboth=$Lsec=$len=$numExposed=0;
    while (<$fhinLoc>) {
	++$ctTmp;
	if ($_=~/^\# LENGTH\s+\:\s*(\d+)/){
	    $lenRd=$1;}
	if ($ctTmp<3){if    ($_=~/^\# PHDsec\+PHDacc/){$Lboth=1;}
		      elsif ($_=~/^\# PHDacc/)        {$Lboth=0;}
		      elsif ($_=~/^\# PHDsec/)        {$Lsec=1;}}
				# ******************************
	last if ($Lsec);	# ERROR is not PHDacc, at all!!!
				# ******************************
	next if ($_=~/^\#|^No|^4N/); # skip comments and first line
	$_=~s/\n//g;
	@tmp=split(/\t/,$_);	# $id,$chain,$len,$nali,$seq,$sec,$acc,$rel
	
	return(0,"*** ERROR $sbrName: too few elements in id=$id, line=$_\n") 
	    if ($#tmp<6);

	foreach $tmp(@tmp){$tmp=~s/\s//g;} # skip blanks
	if    ($Lboth){		# PHDsec+acc
	    $pos=9; $pos=12 if (! $parSbr{"isPred"});} # correct for pred+obs
	else          {		# PHDacc
	    $pos=4; $pos=6  if (! $parSbr{"isPred"});} # correct for pred+obs
	$rel=$tmp[$pos];
	if ($rel =~/[^0-9]/){	# xx hack out, somewhere error
	    $msgErr="*** error rel=$rel, ";
	    if ($parSbr{"isPred"}){$msgErr.="isPred ";}else{$msgErr.="isPrd+Obs ";}
	    if ($Lboth)        {$msgErr.="isBoth ";}else{$msgErr.="isPHDacc ";}
	    $msgErr.="line=$_,\n";
	    close($fhinLoc);
	    return(0,$msgErr);}
	++$len;
	++$numExposed if ($rel>=$exposed);
	$_=~s/\n//g;
	next if (length($_)==0);
    } close($fhinLoc);
    return(0,"$sbrName some variables strange len=$len, numExposed=$numExposed\n")
	if (! defined $len || $len==0 || ! defined $numExposed || $numExposed==0);
    return($len,$numExposed);
}				# end of globeRdPhdRdb

#===============================================================================
sub globeWrt {
    local($fhoutTmp,$parLoc,%resLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok,@tmp,@idLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   globeWrt                    writes output for GLOBE
#       in:                     FILEHANDLE to print,$par=par1,par2,par3,%res
#       in:                     $res{"id"}          = 'id1,id2', i.e. list of names 
#       in:                     $res{"par1"}        = setting of parameter 1
#       in:                     $res{"expl","par1"} = explain meaning of parameter 1
#       in:                     $res{"$id","$kwd"}  = value for name $id
#       in:                         kwd=len|nexp|nfit|diff|interpret
#       out:                    write file
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."globeWrt";$fhinLoc="FHIN"."$sbrName";
				# interpret arguments
    if (defined $parLoc){
	$parLoc=~s/^,*|,*$//g;
	@tmp=split(/,/,$parLoc);}
    if (defined $resLoc{"id"}){
	$resLoc{"id"}=~s/^,*|,*$//g;
	@idLoc=split(/,/,$resLoc{"id"});}
				# ------------------------------
				# write header
    print $fhoutTmp
	"# Perl-RDB generated by:$scrName on:$date\n",
	"# --------------------------------------------------------------------------------\n",
	"# FORMAT   begin\n",
	"# FORMAT   general:    - lines starting with hashes contain comments or PARAMETERS\n",
	"# FORMAT   general:    - columns are delimited by tabs\n",
	"# FORMAT   parameters: '# PARA:tab     keyword =tab value tab (further-information)'\n",
	"# FORMAT   notation:   '# NOTATION:tab keyword tab explanation'\n",
	"# FORMAT   info:       '# INFO:tab     text'\n",
	"# FORMAT   blocks 0:   '# BLOCK        keyword'\n",
	"# FORMAT   blocks 1:    column names (tab delimited)\n",
	"# FORMAT   blocks n>1:  column data  (tab delimited)\n",
	"# FORMAT   file end:   '//' is the end of a complete file\n",
	"# FORMAT   end\n",
	"# --------------------------------------------------------------------------------\n";
				# ------------------------------
				# write parameters
    print $fhoutTmp
	"# PARA     begin\n",
	"# PARA     $scrName HEADER: PARAMETERS\n";
    foreach $des (@tmp){
	$expl="";$expl=$resLoc{"expl","$des"} if (defined $resLoc{"expl","$des"});
	next if ($des eq "doFixPar" && (! $resLoc{"doFixPar"}));
	printf $fhoutTmp 
	    "# PARA:\t%-10s =\t%-6s\t%-s\n",$des,$resLoc{"$des"},$expl;}
    print $fhoutTmp
	"# PARA     end\n",
	"# --------------------------------------------------------------------------------\n";
				# ------------------------------
				# explanations
    print $fhoutTmp
	"# NOTATION begin\n",
	"# NOTATION HEADER: ABBREVIATIONS COLUMN NAMES\n";
    printf $fhoutTmp 
	"# NOTATION:\t%-12s:\t%s\n","id",        "protein identifier";
    printf $fhoutTmp 
	"# NOTATION:\t%-12s:\t%s\n","len",       "length of protein";
    printf $fhoutTmp 
	"# NOTATION:\t%-12s:\t%s\n","nexp",      "number of predicted exposed residues (PHDacc)";
    printf $fhoutTmp 
	"# NOTATION:\t%-12s:\t%s\n","nfit",      "number of expected exposed res";
    printf $fhoutTmp 
	"# NOTATION:\t%-12s:\t%s\n","diff",      "nExposed - nExpect";
    printf $fhoutTmp 
	"# NOTATION:\t%-12s:\t%s\n","interpret",
	                            "comment about globularity predicted for your protein";
    print $fhoutTmp
	"# NOTATION end\n",
	"# --------------------------------------------------------------------------------\n";
    print $fhoutTmp
	"# COMMENTS begin\n",
	"# COMMENTS You may find a preliminary description of the method in the following\n",
	"# COMMENTS preprint:\n",
	"# COMMENTS    http://www.embl-heidelberg.de/~rost/Papers/98globe.html\n",
	"# COMMENTS \n",
	"# COMMENTS end\n",
	"# --------------------------------------------------------------------------------\n";
				# column names
    printf $fhoutTmp 
	"%-s\t%8s\t%8s\t%8s\t%8s\t%-s\n",
	"id","len","nexp","nfit","diff","interpret";

				# data
    foreach $id (@idLoc){
	printf $fhoutTmp 
	    "%-s\t%8d\t%8d\t%8.2f\t%8.2f\t%-s\n",
	    $id,$resLoc{"$id","len"},$resLoc{"$id","nexp"},$resLoc{"$id","nfit"},
	    $resLoc{"$id","diff"},$resLoc{"$id","interpret"};}
}				# end of globeWrt

#===============================================================================
sub hssp_fil_num2txt {
    local ($perc_ide) = @_ ;
    local ($txt,$tmp);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   hssp_fil_num2txt            translates a number for percentage sequence iden-
#                               tity into the input argument for MaxHom, e.g.,
#                               30% => 'FORMULA+5'
#       in:                     $perc_ide
#       out:                    $txt ("FORMULA+/-n")
#--------------------------------------------------------------------------------
    $txt="0";
    if    ($perc_ide>25) {
	$tmp=$perc_ide-25;
	$txt="FORMULA+"."$tmp"." "; }
    elsif ($perc_ide<25) {
	$tmp=25-$perc_ide;
	$txt="FORMULA-"."$tmp"." "; }
    else {
	$txt="FORMULA "; }
    return($txt);
}				# end of hssp_fil_num2txt

#===============================================================================
sub hssp_rd_header {
    local ($file_hssp,@num) = @_ ;
    local (@des1,@des2,%ptr,$ptr,$len_strid,$Lis_long_id,$fhin,$Lget_all,
	   %rdLoc,@tmp,$tmp,$beg,$mid,$end,$ct,$id,$strid,$des,$num,$Lok);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   hssp_rd_header              reads the header of an HSSP file for numbers 1..$#num
#       in:                     $file_hssp,@num  (numbers to read)
#       out:                    $rdLoc{} (0 for error)
#--------------------------------------------------------------------------------
				# defaults
    $fhin="FHIN_HSSP_HEADER";
    if ($#num==0){
	$Lget_all=1;}
    else {
	$Lget_all=1;}

    @des1=   ("IDE","WSIM","IFIR","ILAS","JFIR","JLAS","LALI","NGAP","LGAP","LEN2","ACCNUM");
    @des2=   ("STRID");
#    @des3=   ("LEN1");
				# note STRID, ID, NAME automatic
    $ptr{"IDE"}=1;$ptr{"WSIM"}=2;
    $ptr{"IFIR"}=3;$ptr{"ILAS"}=4;$ptr{"JFIR"}=5;$ptr{"JLAS"}=6;
    $ptr{"LALI"}=7;$ptr{"NGAP"}=8;$ptr{"LGAP"}=9;$ptr{"LEN2"}=10; $ptr{"ACCNUM"}=11;

    $len_strid=    4;		# minimal length to identify PDB identifiers

    if ( ! -e $file_hssp) {	# check existence
	return(0); }
				# ini
    $Lis_long_id=0;
				# read file
    &open_file("$fhin", "$file_hssp");
    while ( <$fhin> ) {		# is it HSSP file?
	if (! /^HSSP /) {
	    return(0); } 
	last; }
    while ( <$fhin> ) {		# length, lond-id
	last if (/^\#\# PROTEINS/); 
	if (/^PARAMETER  LONG-ID :YES/) {$Lis_long_id=1;}
	elsif (/^SEQLENGTH /) {$_=~s/\n|\s|SEQLENGTH//g;
			       $rdLoc{"LEN1"}=$_;
			       $rdLoc{"len1"}=$_; } }
    $ct_taken=0;
    while ( <$fhin> ) { 
	last if (/^\#\# ALIGNMENTS/); 
	if (/^  NR\./){next;}	# skip describtors
	if ($Lis_long_id){
	    $beg=substr($_,1,56);$end=substr($_,109);$mid=substr($_,57,115); }
	else {
	    $beg=substr($_,1,28);$end=substr($_,90);$mid=substr($_,29,90); }
	$end=~s/^\s*|\s*$|\n//g; # purge leading blanks
	$mid=~s/^\s*|\s*$//g;	# purge leading blanks

				# begin: counter and id
	$ct=$beg;$ct=~s/\s*(\d+)\s+\:.*/$1/;$ct=~s/\s//g;
				# ------------------------------
	$Lok=0;			# read it?
	if (! $Lget_all) {
	    foreach $num (@num) {if ($ct eq "$num"){
		$Lok=1;
		last;}}
	    if (! $Lok){
		next;} }
	$beg=~s/.+ \:\s*|\s*$//g;
	if (! $Lis_long_id) {
	    $id=$beg;$id=~s/(.+_\S+).*/$1/;
	    $strid=$beg;$strid=~s/$id|\s//g; }
	else {
	    $id=$beg;$id=~s/(.+_\S+).*/$1/;
	    $strid=substr($_,49,6);$strid=~s/\s//g; }
	$tmp=$len_strid-1;
	if ( (length($strid)<$len_strid) && 
	    ($id=~/^[0-9][A-Z0-9]{$tmp,$tmp}\s*/) ){
	    $strid=substr($id,1,$len_strid); }
	$rdLoc{"$ct","ID"}=$id;
	$rdLoc{"$ct","STRID"}=$strid;
	$rdLoc{"$ct","NAME"}=$end;
	++$ct_taken;
				# middle all info
	$#tmp=0;@tmp=split(/\s+/,$mid);
	foreach $_ (@tmp) {$_=~s/\s//g;}
	foreach $des (@des1){ 
	    if ( ! defined $ptr{"$des"}) {
		next; }
	    $ptr=$ptr{"$des"};
	    $rdLoc{"$ct","$des"}=$tmp[$ptr]; }
    }
    close($fhin);
    $rdLoc{"NROWS"}=$ct_taken;
    return(%rdLoc);
}				# end of hssp_rd_header

#===============================================================================
sub hssp_rd_strip_one {
    local ($fileInLoc,$pos_in,$Lscreen) = @_ ;
    local ($fhin,@des,$des,$Lok,@tmp,$tmp,$ct,$ct_guide,$ct_aligned,
	   $Ltake_it,$Lguide,$Laligned,$Lis_ali,$it,$id2,$seq2);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   hssp_rd_strip_one           reads the alignment for one sequence from a (new) strip file
#       in:                     $file, $position_of_protein_to_be_read, $Lscreen
#       out:                    %rd (returned)
#       out:                    $rd{"seq1"},$rd{"seq2"},$rd{"sec1"},$rd{"sec2"},
#       out:                    $rd{"id1"},$rd{"id2"},
#--------------------------------------------------------------------------------
				# settings
    $Lscreen=0 if (!defined $Lscreen);
    $fhin="FHIN_HSSP_RD_STRIP_ONE";

    @des=("seq1","seq2","sec1","sec2");
    foreach $des(@des){		# initialise
	$rdLoc{"$des"}="";}
    if (!-e $fileInLoc){
	print "*** ERROR hssp_rd_strip_one (lib-br): '$fileInLoc' strip file missing\n";
	exit;}
#    if (&is_strip_old($fileInLoc)){
#	print "*** ERROR hssp_rd_strip_one (lib-br): only with new strip format\n";
#	exit;}

    if ($pos_in=~/\D/){		# if PDBid given, search for position
	&open_file("$fhin","$fileInLoc");
	while(<$fhin>){last if (/=== ALIGNMENTS ===/); }
	while(<$fhin>){if (/$pos_in/){$tmp=$_;$tmp=~s/\n//g;
				      $tmp=~s/^\s+(\d+)\.\s+.+/$1/g;
				      $pos_in=$tmp;
				      last;}}
	close($fhin);}
    &open_file("$fhin","$fileInLoc");
				# header
    while (<$fhin>) {
	last if (/=== ALIGNMENTS ===/);}
				# ----------------------------------------
				# loop over all parts of the alignments
    $Lok=0;$#tmp=$ct=$ct_guide=$ct_aligned=0;$Ltake_it=$Lguide=$Laligned=0;
    while (<$fhin>) {
	next if (length($_)<2);	# ignore blank lines
	if (/=== ALIGNMENTS ===/ ){ # until next line with       "=== ALIGNMENTS ==="
	    &hssp_rd_strip_one_correct1; # correction for different beginning
	    $ct_guide=0;$Lis_ali=1;}
	elsif (/=======/){	# prepare end
	    &hssp_rd_strip_one_correct1; # correction for different beginning
	    last;}
	elsif ( /^\s*\d+ -\s+\d+ / ){ # first line for alis x-(x+100), i.e. guide
	    $Lguide=1;$Ltake_it=1;}
	elsif ( $Ltake_it && $Lguide) { # read five lines
	    ++$ct_guide; 
	    if ($ct_guide==1){	# guide sequence
		$tmp2=$_;
		$_=~s/^\s+(\S+)\s+(\S+)\s*.*\n?/$2/;
		$rdLoc{"id1"}=$1;
		$tmp=substr($tmp2,26,100);$tmp=~s/\n//g;
		$rdLoc{"seq1"}.=$tmp;}
	    elsif ($ct_guide==2){ # guide sec str
		$tmp=substr($_,26,100);$tmp=~s/\n//g;
		$tmp=~s/ /L/g;	# blank to loop
		$rdLoc{"sec1"}.=$tmp;}
	    elsif ($ct_guide>=4){
		$Lguide=0;$ct_guide=0;} }
	elsif ( /^\s*\d+\. /) { # aligned sequence: first line
	    $_=~s/\n//g;
	    $tmp2=$_;
	    $_=~s/^\s*|\s*$//g;	# purging leading blanks
	    $#tmp=0; @tmp=split(/\s+/,$_);
	    $it=  $tmp[1];$it=~s/\.//g;
	    $id2= $tmp[2];
	    $seq2=$tmp[4];
	    if ($it==$pos_in) {
		$Ltake_it=1; $Laligned=$Lok=1;
		$rdLoc{"id2"}=$id2;
		$tmp=substr($tmp2,26,100);$tmp=~s/\n//g;$tmp=~s/ /./g;
		$rdLoc{"seq2"}.=$tmp;} }
	elsif ( $Ltake_it && $Laligned) { # aligned sequence: other lines
	    $tmp=substr($_,26,100);$tmp=~s/\n//g;$tmp=~s/ /\./g;
	    $rdLoc{"sec2"}.=$tmp;
	    $Laligned=0;$ct_aligned=0;}
    }
    close($fhin);
#    &hssp_rd_strip_one_correct2;
				# ------------------------------
				# write onto screen?
    if ($Lscreen) { print"--- lib-br.pl:hssp_rd_strip_one \t read in from '$fileInLoc'\n";
		    foreach $des(@des){
			print "$des:",$rdLoc{"$des"},"\n";}}
    return (%rdLoc);
}				# end of hssp_rd_strip_one 

#===============================================================================
sub hssp_rd_strip_one_correct1 {
#-------------------------------------------------------------------------------
#   hssp_rd_strip_one_correct1  correct for begin and ends
#-------------------------------------------------------------------------------
    $diff=(length($rdLoc{"seq1"})-length($rdLoc{"seq2"}));
    if ($diff!=0){
	foreach $it (1..$diff){
	    $rdLoc{"seq2"}.=".";$rdLoc{"sec2"}.="."; }}
}				# end of hssp_rd_strip_one_correct1

#===============================================================================
sub hssp_rd_strip_one_correct2 {
#-------------------------------------------------------------------------------
#   hssp_rd_strip_one_correct2  shorten indels for begin and ends
#-------------------------------------------------------------------------------
    $tmp=$rdLoc{"seq2"};$tmp=~s/^\.*//; # N-term insertions
    $diff=(length($rdLoc{"seq2"})-length($tmp));
    if ($diff!=0){
	foreach $des(@des){ $tmp=substr($rdLoc{"$des"},($diff+1),length($tmp)); 
			    $rdLoc{"$des"}=$tmp; }}
    $tmp=$rdLoc{"seq2"};$tmp=~s/\.*$//; # C-term insertions
    $diff=(length($rdLoc{"seq2"})-length($tmp));
    if ($diff!=0){
	foreach $des(@des){ $tmp=substr($rdLoc{"$des"},1,length($tmp));
			    $rdLoc{"$des"}=$tmp;}}
}				# end of hssp_rd_strip_one_correct2
 
#===============================================================================
sub hsspChopProf {
    local($fileIn,$fileOut)=@_;
    local($sbr);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspChopProf                chops profiles from HSSP file
#       in:                     $fileIn,$fileOut
#       out:                    
#       err:                    ok=(1,'ok','blabla'), err=(0,errNumber,'msg')
#-------------------------------------------------------------------------------
    $sbr="lib-br:hsspChopProf";
    return(0,"*** $sbr: not def fileIn!")    if (! defined $fileIn);
    return(0,"*** $sbr: not def fileOut!")   if (! defined $fileOut);
    return(0,"*** $sbr: miss file=$fileIn!") if (! -e $fileIn);
#   --------------------------------------------------
#   open files
#   --------------------------------------------------
    open(FILEIN,$fileIn)  || 
	return(0,"*** $sbr: failed to open in=$fileIn");
    open(FILEOUT,"> $fileOut")  || 
	return(0,"*** $sbr: failed to open out=$fileOut");

#   --------------------------------------------------
#   write everything before "## SEQUENCE PROFILE"
#   --------------------------------------------------
    while( <FILEIN> ) {
	last if ( /^\#\# SEQUENCE PROFILE/ );
	print FILEOUT "$_"; }
    print FILEOUT "--- \n","--- Here, in HSSP files usually the profiles are listed. \n";
    print FILEOUT "--- We decided to chop these off in order to spare bytes. \n","--- \n";
    while( <FILEIN> ) {
	print FILEOUT "$_ "; 
				# changed br 20-02-97 (keep insertions)
#	last if ( /^\#\# INSERTION/ ); 
    }
    while( <FILEIN> ) {
	print FILEOUT "$_ "; }
    print FILEOUT "\n";
    close(FILEIN);close(FILEOUT);
    return(1,"ok $sbr: wrote $fileOut");
}				# end of hsspChopProf

#===============================================================================
sub hsspfile_to_pdbid {
    local ($name_in) = @_; local ($tmp);
#--------------------------------------------------------------------------------
#   hsspfile_to_pdbid           extracts id from hssp file
#--------------------------------------------------------------------------------
    $tmp=  "$name_in";$tmp=~s/\/data\/hssp\///g;$tmp=~s/\.hssp//g;$tmp=~s/\s//g;
    $hsspfile_to_pdbid = $tmp;
}				# end of hsspfile_to_pdbid

#===============================================================================
sub hsspFilterGetPosExcl {
    local($exclTxtLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok,@notLoc,@exclLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspFilterGetPosExcl        flags positions (in pairs) to exclude
#       in:                     e.g. excl=1-5,9,15 
#       out:                    @notLoc
#   GLOBAL in /out:             $rd{"NALIGN"},$rd{"NROWS"},$rd{"NR","$it"}
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."hsspFilterGetPosExcl";
				# text '1-5,7,12' to array (1,2,3,4,5,7,12)
    $#exclLoc=$#notLoc=0;
    if ($exclTxtLoc=~/\*$/){	# replace wild card
	$exclTxtLoc=~s/\*$/$rd{"NALIGN"}/;}
    @exclLoc=&get_range($exclTxtLoc);   # external lib-br.pl
				# all pairs
    foreach $it (1..$rd{"NROWS"}){
	foreach $i (@exclLoc) { 
	    if ($i == $rd{"NR","$it"}) { 
		$notLoc[$it]=1;
		last;}}}
    return(@notLoc);
}				# end of hsspFilterGetPosExcl

#===============================================================================
sub hsspFilterGetPosIncl {
    local($inclTxtLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok,@takeLoc,@inclLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspFilterGetPosIncl        flags positions (in pairs) to include
#       in:                     e.g. incl=1-5,9,15 
#       out:                    @takeLoc
#   GLOBAL in /out:             $rd{"NALIGN"},$rd{"NROWS"},$rd{"NR","$it"}
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."hsspFilterGetPosExIn";
				# text '1-5,7,12' to array (1,2,3,4,5,7,12)
    $#inclLoc=$#takeLoc=0;
    if ($inclTxtLoc=~/\*$/){	# replace wild card
	$inclTxtLoc=~s/\*$/$rd{"NALIGN"}/;}
    @inclLoc=&get_range($inclTxtLoc);  # external lib-br.pl
				# all pairs
    foreach $it (1..$rd{"NROWS"}){
	foreach $i (@inclLoc) { 
	    if ($i == $rd{"NR","$it"}) { 
		$takeLoc[$it]=1;
		last;}}}
    return(@takeLoc);
}				# end of hsspFilterGetPosIncl

#===============================================================================
sub hsspFilterGetIdeCurve {
    local($threshLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok,@takeLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspFilterGetIdeCurve       flags positions (in pairs) above identity threshold
#       in:                     $threshLoc= distance from HSSP (new ide) threshold
#       out:                    @takeLoc
#   GLOBAL in /out:             $rd{"NR","$it"},$rd{"LALI","$it"}
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."hsspFilterGetIdeCurve";
    $#takeLoc=0;
    foreach $it (1..$rd{"NROWS"}){ # loop over all pairs
	$dist=100*$rd{"IDE","$it"} - &getDistanceNewCurveIde($rd{"LALI","$it"});
	if ($dist >= $threshLoc){
	    $takeLoc[$it]=1;}
	else { 
	    $takeLoc[$it]=0;}}
    return(@takeLoc);
}				# end of hsspFilterGetIdeCurve

#===============================================================================
sub hsspFilterGetIdeCurveMinMax {
    local($minLoc,$maxLoc,$fhSbr) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok,@notLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspFilterGetIdeCurveMinMax flags positions (in pairs) above maxIde and below minIde
#       in:                     $minLoc,$maxLoc = distances from HSSP (new ide) threshold
#       in:                     $fhSbr: if not defined, no output written
#       out:                    @notLoc
#   GLOBAL in /out:             $rd{"NR","$it"},$rd{"LALI","$it"}
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."hsspFilterGetIdeCurveMinMax";
    $#notLoc=0;
    foreach $it (1..$rd{"NROWS"}){ # loop over all pairs
	$dist=100*$rd{"IDE","$it"} - &getDistanceNewCurveIde($rd{"LALI","$it"});
	if    ($dist > $maxLoc){
	    $notLoc[$it]=1;}
	elsif ($dist < $minLoc){
	    $notLoc[$it]=1;}
	else {
	    printf 
		"--- %3d: %5.2f < %5.2f < %5.2f i=%5.2f (%5d)\n",
		$it,$minLoc,$dist,$maxLoc,(100*$rd{"IDE","$it"}),$rd{"LALI","$it"}
	    if (defined $fhSbr);}
    }
    return(@notLoc);
}				# end of hsspFilterGetIdeCurveMinMax

#===============================================================================
sub hsspFilterGetSimCurve {
    local($threshLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok,@takeLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspFilterGetSimCurve       flags positions (in pairs) above similarity threshold
#       in:                     $threshLoc= distance from HSSP (new sim) threshold
#       out:                    @take
#   GLOBAL in /out:             @take,$rd{"NR","$it"}
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."hsspFilterGetSimCurve";
    $#takeLoc=0;
    foreach $it (1..$rd{"NROWS"}){ # loop over all pairs
	$dist=100*$rd{"WSIM","$it"} - &getDistanceNewCurveSim($rd{"LALI","$it"});
	if ($dist >= $threshLoc){
	    $takeLoc[$it]=1;}
	else { 
	    $takeLoc[$it]=0;}}
    return(@takeLoc);
}				# end of hsspFilterGetSimCurve

#===============================================================================
sub hsspFilterGetSimCurveMinMax {
    local($minLoc,$maxLoc,$fhSbr) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok,@notLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspFilterGetSimCurveMinMax flags positions (in pairs) above maxSim and below minSim
#       in:                     $minLoc,$maxLoc = distances from HSSP (new sim) threshold
#       in:                     $fhSbr: if not defined, no output written
#       out:                    @notLoc
#   GLOBAL in /out:             $rd{"NR","$it"}
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."hsspFilterGetSimCurveMinMax";
    $#notLoc=0;
    foreach $it (1..$rd{"NROWS"}){ # loop over all pairs
	$dist=100*$rd{"WSIM","$it"} - &getDistanceNewCurveSim($rd{"LALI","$it"});
	if    ($dist > $maxLoc){
	    $notLoc[$it]=1;}
	elsif ($dist < $minLoc){
	    $notLoc[$it]=1;}
	else {
	    printf 
                "--- %3d: %5.2f < %5.2f < %5.2f i=%5.2f (%5d)\n",
                $it,$minLoc,$dist,$maxLoc,(100*$rd{"WSIM","$it"}),$rd{"LALI","$it"}
	    if (defined $fhSbr);}
    }
    return(@notLoc);
}				# end of hsspFilterGetSimCurveMinMax

#===============================================================================
sub hsspFilterGetRuleBoth {
    local($threshLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok,@notLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspFilterGetRuleBoth       flags all positions (in pairs) with:
#                               ide > thresh, and  similarity > thresh
#       in:                     $threshLoc= distance from HSSP (new ide) threshold
#       out:                    @notLoc
#   GLOBAL in /out:             $rd{"NR","$it"},$rd{"LALI","$it"},$rd{"IDE","$it"},$rd{"WSIM","$it"}
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."hsspFilterGetRuleBoth";
    $threshLoc="-100" if (! defined $threshLoc);

    $#okLoc=0;
    foreach $it (1..$rd{"NROWS"}){ # loop over all pairs
	if ($threshLoc > -100){
	    $distSim=100*$rd{"WSIM","$it"} - 
		&getDistanceNewCurveSim($rd{"LALI","$it"}); # external lib-br
	    next if ($distSim < $threshLoc);
	    $distIde=100*$rd{"IDE","$it"}  - 
		&getDistanceNewCurveIde($rd{"LALI","$it"});	# external lib-br
	    next if ($distIde < $threshLoc);}
	push(@okLoc,$it);}
    return(@okLoc);
}				# end of hsspFilterGetRuleBoth

#===============================================================================
sub hsspFilterGetRuleSgi {
    local($threshLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok,@okLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspFilterGetRuleSgi        Sim > Ide, i.e. flags all positions (in pairs) with: 
#                                  sim > ide, and both above thresh (optional)
#       in:                     $threshLoc distance from HSSP (new) threshold (optional),
#       in:                     if not defined thresh -> take all
#       out:                    @okLoc
#   GLOBAL in /out:             $rd{"NR","$it"},$rd{"LALI","$it"},$rd{"IDE","$it"},$rd{"WSIM","$it"}
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."hsspFilterGetRuleBoth";
    $threshLoc="-100" if (! defined $threshLoc);

    $#okLoc=0;
    foreach $it (1..$rd{"NROWS"}){ # loop over all pairs
	$simLoc=$rd{"WSIM","$it"};$ideLoc=$rd{"IDE","$it"};
	next if ($simLoc < $ideLoc);
	if ($threshLoc > -100){ # threshold given
	    $distSim=100*$rd{"WSIM","$it"} - 
		&getDistanceNewCurveSim($rd{"LALI","$it"}); # external lib-br
	    next if ($distSim < $threshLoc);
	    $distIde=100*$rd{"IDE","$it"}  - 
		&getDistanceNewCurveIde($rd{"LALI","$it"});	# external lib-br
	    next if ($distIde < $threshLoc);}
	push(@okLoc,$it);}
    return(@okLoc);
}				# end of hsspFilterGetRuleSgi

#===============================================================================
sub hsspFilterMarkFile {
    local($fileInLoc,$fileOutLoc,@takeLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspFilterMarkFile          marks the positions specified in command line
#       in:                     $fileIn,$fileOut,@num = number to mark
#       out:                    implicit: fileMarked
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."hsspFilterMarkFile";$fhinLoc="FHIN_"."$sbrName";$fhoutLoc="FHOUT_"."$sbrName";
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc!")          if (! defined $fileInLoc);
    return(0,"*** $sbrName: not def fileOutLoc!")         if (! defined $fileOutLoc);
    return(0,"*** $sbrName: not def \@takeLoc!")          if (! defined @takeLoc || $#takeLoc<1);
    return(0,"*** $sbrName: miss in file '$fileInLoc'!")  if (! -e $fileInLoc);
				# open files
    &open_file("$fhinLoc","$fileInLoc") ||
	return(0,"*** ERROR $sbrName: in=$fileInLoc not opened\n");
    &open_file("$fhoutLoc", ">$fileOutLoc") ||
	return(0,"*** ERROR $sbrName: out=$fileOutLoc not opened\n");
				# ------------------------------
    while ( <$fhinLoc> ) {	# read/write HSSP header
	$tmp=$_;
	print $fhoutLoc $tmp;
	last if (/^  NR\./); }	# last when header info start
    $ct=0;			# ------------------------------
    while ( <$fhinLoc> ) {	# read/write each pair (header)
	$tmp=$_;$tmp=~s/\n//g; $tmpx=$tmp;$tmpx=~s/\s//g;
	$line=$_;
	next if ( length($tmpx)==0 );
	if (/^\#\#/) { 
	    print $fhoutLoc $line; 
	    last;}		# now alignments start 
	++$ct;
	$tmppos=substr($tmp,1,7);	# get first 7 characters of line
	$tmprest=$tmp;$tmprest=~s/$tmppos//g; # extract rest
	$pos=$tmppos;$pos=~s/\s|\://g;

	if    (defined $takeLoc[$ct] && $takeLoc[$ct]) { 
	    print $fhoutLoc $line;}
	elsif (defined $takeLoc[$ct] &&! $takeLoc[$ct]) { 
	    $tmppos=~s/ \:/\*\:/g; 
	    print $fhoutLoc "$tmppos","$tmprest\n"; }
	else { print "*** ERROR for ct=$ct, $tmppos","$tmprest\n"; }}
				# ------------------------------
    while ( <$fhinLoc> ) {	# read/write remaining file (alis asf)
        print $fhoutLoc $_;}
    close($fhinLoc);close($fhoutLoc);
    return(1,"ok $sbrName");
}				# end of hsspFilterMarkFile

#===============================================================================
sub hsspGetChain {
    local ($fileIn) = @_ ;
    local ($fhin,$ifirLoc,$ilasLoc,$tmp1,$tmp2,
	   $chainLoc,$posLoc,$posRd,$chainRd,@cLoc,@pLoc,%rdLoc);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   hsspGetChain                extracts all chain identifiers in HSSP file
#       in:                     $file
#       out:                    $chains (ABC) ,%rdLoc
#                      no chain -> $chains=' '
#       out                        $rdLoc{"NROWS"},$rdLoc{"$ct","chain"},
#       out                        $rdLoc{"$ct","ifir"},$rdLoc{"$ct","ilas"}
#--------------------------------------------------------------------------------
    $fhin="FhInHssp";
    return(0,"no file") if (! -e $fileIn);
    &open_file("$fhin","$fileIn");
    while(<$fhin>){		# until start of data
	last if ($_=~/^ SeqNo/);}
    $chainLoc=$posLoc="";
    while(<$fhin>){
	if ($_=~/^\#/ && (length($chainLoc)>1) ) {
	    $posLoc.="$ifirLoc-$ilasLoc".",";
	    last;}
	$chainRd=substr($_,13,1);
	$aaRd=   substr($_,15,1);
	$posRd=  substr($_,1,6);$posRd=~s/\s//g;
	next if ($aaRd eq "!") ;  # skip over chain break
	if ($chainLoc !~/$chainRd/){	# new chain?
	    $posLoc.=         "$ifirLoc-$ilasLoc"."," if (length($chainLoc)>1);
	    $chainLoc.=       "$chainRd".",";
	    $ifirLoc=$ilasLoc=$posRd;}
	else { 
	    $ilasLoc=$posRd;}
    }close($fhin);
    $chainLoc=~s/^,|,$//g;
    $posLoc=~s/\s//g;$posLoc=~s/^,|,$//g; # purge leading ','
				# now split chains read
    undef %rdLoc; $ctLoc=0;
    @cLoc=split(/,/,$chainLoc);
    @pLoc=split(/,/,$posLoc);

    foreach $itLoc(1..$#cLoc){
	($tmp1,$tmp2)=split(/-/,$pLoc[$itLoc]);
	next if ($tmp2 == $tmp1); # exclude chains of length 1
	++$ctLoc;
	$rdLoc{"NROWS"}=         $ctLoc;
	$rdLoc{"$ctLoc","chain"}=$cLoc[$itLoc];
	$rdLoc{"$ctLoc","ifir"}= $tmp1;
	$rdLoc{"$ctLoc","ilas"}= $tmp2;}
    $chainLoc=~s/,//g;
    return($chainLoc,%rdLoc);
}				# end of hsspGetChain

#===============================================================================
sub hsspGetChainBreaks {
    local ($fileInLoc) = @_ ;
    local ($fhinLoc,$ifirLoc,$ilasLoc,$tmp1,$tmp2,
	   $chainLoc,$posLoc,$posRd,$chainRd,@cLoc,@pLoc);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   hsspGetChainBreaks          extracts all chain breaks (if not labelled, or
#                               if within labelled chain: _a-z added to chain,
#                               e.g. 1a0i_abc, or 1cse_E_ab
#       in:                     $file
#       out:                    1|0,msg,$tmp{}
#       out:                       $tmp{"NROWS"}=        number of chains
#                                  $tmp{"chains"}=       $chains (a,b,Ea,Eb,c,d,Ia..) ,
#                                  $tmp{"chain","$ct"}   chain $ct
#                                  $tmp{"ifir","$ct"}    first residue for chain $ct
#                                  $tmp{"ilas","$ct"}    last for chain $ct
#       err:                    1|0, error message
#--------------------------------------------------------------------------------
    $sbrName="lib-br::hsspGetChainBreaks"; $fhinLoc="FHIN_hsspGetChainBreaks";
				# ------------------------------
				# checck existenc
    return(0,"no file ($fileInLoc)",0,0) if (! -e $fileInLoc);
				# ------------------------------
				# open file
    &open_file("$fhinLoc","$fileIn") || return(&errSbr("failed opening old=$fileInLoc,"));

				# ------------------------------
    while (<$fhinLoc>){		# until start of data
	last if ($_=~/^ SeqNo/);}

    $#chainLoc=$#ifirLoc=$#ilasLoc=0;
    $beg=$end=$chain=0;
				# ------------------------------
    while (<$fhinLoc>){		# read first sequence-ali section
	last if ($_=~/^\#/);	# fin when ali begins
	$chainRd=substr($_,13,1);
	$aaRd=   substr($_,15,1);
	$posRd=  substr($_,1,6);$posRd=~s/\s//g;
	$beg=$posRd             if (! $beg);
	$chain=$chainRd         if (! $chain);
	$chain="*"              if ($chain eq " ");
				# found a chain break
	if ($aaRd eq "!") {
	    $end=$posRd-1;
	    if (($end-$beg) > 1){ # take only those longer than 1 residue
		push(@chainLoc,$chain);
		push(@ifirLoc,$beg);    push(@ilasLoc,$end); }
	    $beg=$chain=0;	# reset
	}
    } close($fhinLoc);
				# ------------------------------
				# final one
    $end=$posRd;
    push(@chainLoc,$chain);push(@ifirLoc,$beg);push(@ilasLoc,$end); 
    
				# ------------------------------
				# set up new names
    $alphabet="abcdefghijklmnopqrstuvwxyz";
    @alphabet=split(//,$alphabet);
				# ------------------------------
				# process
				# ------------------------------
    undef %tmp; $tmp{"chains"}=""; $ct=0;
    foreach $it (1..$#chainLoc) {
	$chain=$chainLoc[$it];
	$chain.="1";
				# is unique -> add
	if (! defined $tmp{"$chain"}){
	    ++$ct;
	    $tmp{"$chain"}=$ct;               $tmp{"$ct"}=$chain;
	    $tmp{"ifir","$ct"}=$ifirLoc[$it]; $tmp{"ilas","$ct"}=$ilasLoc[$it]; 
	    next; }
				# is not -> add letters
	$ctalpha=1; $Lok=0;
	$chain=~s/(.)\d*/$1/;
	while (! $Lok){		# loop over alphabet
	    ++$ctalpha;
	    if ($ctalpha > 26){return(&errSbr("ctalpha > 26, for it=$it, ".
					      "chain=$chain (file=$fileInLoc)"));}
	    $chain2="$chain"."$ctalpha";
	    next if (defined $tmp{"$chain2"});
				# is new
	    $Lok=1;$chain=$chain2;
	    ++$ct;
	    $tmp{"$chain"}=$ct;               $tmp{"$ct"}=$chain;
	    $tmp{"ifir","$ct"}=$ifirLoc[$it]; $tmp{"ilas","$ct"}=$ilasLoc[$it]; 
	    last; }
    }

    $tmp{"NROWS"}= $ct;
				# ------------------------------
				# only one: fin
    if ($ct == 1){
	$tmp{"1"}=~s/(.)\d*/$1/; # remove number
	$tmp{"chains"}=$tmp{"1"}; 
	return(1,"ok $sbrName",%tmp); }
				# ------------------------------
				# final: remove '*' '1..26' -> 'a-z'
				# ------------------------------
    foreach $it (1..$ct) {
	$num=       substr($tmp{"$it"},2);
	$tmp{"$it"}=substr($tmp{"$it"},1,1).$alphabet[$num];
	$tmp{"chains"}.=$tmp{"$it"}.","; }

    $tmp{"chains"}=~s/,*$//g;

    return(1,"ok $sbrName",%tmp);
}				# end of hsspgetchainbreaks

#===============================================================================
sub hsspGetChainLength {
    local ($fileIn,$chainLoc) = @_ ;
    local ($file_hssp,$ct,$tmp,$beg,$end,$pos);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   hsspGetChainLength          extracts the length of a chain in an HSSP file
#       in:                     hssp_file,chain,
#       out:                    $length,$ifir,$ilas
#--------------------------------------------------------------------------------
    $fileIn=~s/\s//g;$fileIn=~s/\n//g;
    $file_hssp=$fileIn; $Lchain=1; 
    $Lchain=0                   if ($chainLoc eq "*" || ! &is_chain($chainLoc)); 
    if (! -e $file_hssp){
	print "*** ERROR hsspGetChainLength: no HSSP=$fileIn,\n"; 
	return(0,"*** ERROR hsspGetChainLength: no HSSP=$fileIn,");}
    &open_file("FHIN", "$file_hssp") ||
	return(0,"*** ERROR hsspGetChainLength: failed opening HSSP=$fileIn,");

    while ( <FHIN> ) { 
	last if (/^ SeqNo/); }
    $ct=$pos=0;
    while ( <FHIN> ) { 
	last if (/^\#\# /);
	++$pos;$tmp=substr($_,13,1);
	if    ( $Lchain && ($tmp eq $chainLoc) ) { ++$ct; }
	elsif ( ! $Lchain )                      { ++$ct; }
	elsif ( $ct>1 ) {
	    last;}
	$beg=$pos if ($ct==1); } close(FHIN);
    $end=$pos;
    return($ct,$beg,$end);
}				# end of hsspGetChainLength

#===============================================================================
sub hsspGetChainNali {
    local($fileInLoc,$chainInLoc,$distLoc,$distModeLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspGetChainNali            gets Nali for chain X (restricted to HSSP dist D)
#       in:                     $fileInLoc   : HSSP file
#       in:                     $chainInLoc  : chain to read
#                                   '*' for omitting the test
#       in:                     $distLoc     : limiting distance from HSSP (new Ide)
#                                   '0' in NEXT variable for omitting the test
#       in:                     $distModeLoc : mode of limit ('gt|ge|lt|le')
#                                              -> if mode=gt, all with dist>distLoc
#                                                  will be counted
#                                   '0' for omitting the test
#       out:                    1|0,msg,$num,$take:
#                               $take='n,m,..': list of pairs ok
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-nn:"."hsspGetChainNali";$fhinLoc="FHIN_"."hsspGetChainNali";
				# check arguments
    return(&errSbr("not def fileInLoc!"))                if (! defined $fileInLoc);
    return(&errSbr("not def chainInLoc!"))               if (! defined $chainInLoc);
    return(&errSbr("not def distLoc!"))                  if (! defined $distLoc);
    return(&errSbr("not def distModeLoc!"))              if (! defined $distModeLoc);
    return(&errSbr("miss in file '$fileInLoc'!"))        if (! -e $fileInLoc);
    $chainInLoc="*"                                      if (! &is_chain($chainInLoc));
    undef %tmp;
    $errMsg="\n*** ERROR $sbrName local in: f=$fileInLoc,c=$chainInLoc,".
	"dist=$distLoc,mode=$distModeLoc\n";
				# ------------------------------
				# get chain
				# ------------------------------
    if ($chainInLoc ne "*"){
	($len,$ifir,$ilas)=
	    &hsspGetChainLength($fileInLoc,$chainInLoc);
	return(&errSbrMsg("chain=$chainInLoc".$errMsg,$ifir),0,0) if (! $len);
	$ifirChain=$ifir;
	$ilasChain=$ilas; }
    else {
	$ifirChain=0;
	$ilasChain=0; }
				# ------------------------------
				# read HSSP header
				# ------------------------------
    ($Lok,%tmp)=
	&hsspRdHeader($fileInLoc,"IFIR","ILAS","LALI","IDE");
    return(&errSbr("hsspGetChainNali:hsspRdHeader no hdr for $fileInLoc,".$errMsg),0,0) 
	if (! $Lok);
    $take="";
 				# translate
    foreach $it (1..$tmp{"NROWS"}){
				# ------------------------------
				# (1) is it aligned to chain?
	next if ($ifirChain && $ilasChain &&
		 ( ($tmp{"IFIR","$it"} > $ilasChain) || ($tmp{"ILAS","$it"} < $ifirChain) ));
				# ------------------------------
				# (2) is it correct distance?
	if ($distModeLoc){
	    $lali=$tmp{"LALI","$it"}; $pide=100*$tmp{"IDE","$it"};
	    return(&errSbr("pair=$it, no lali|ide ($lali,$pide)".$errMsg),0,0) 
		if (! defined $lali || ! defined $pide);
                                # compile distance to HSSP threshold (new)
	    ($pideCurve,$msg)= 
		&getDistanceNewCurveIde($lali);
	    return(&errSbrMsg("hsspGetChainNali".$errMsg,$msg),0,0)            
		if (! $pideCurve && ($msg !~ /^ok/));
	    
	    $dist=$pide-$pideCurve;
				# mode
	    next if (($distModeLoc eq "gt" && $dist <= $distLoc) ||
		     ($distModeLoc eq "ge" && $dist <  $distLoc) ||
		     ($distModeLoc eq "lt" && $dist >= $distLoc) ||
		     ($distModeLoc eq "le" && $dist >  $distLoc)); }
				# ------------------------------
				# (3) ok, take it
	$take.="$it,"; }

    $take=~s/^,*|,*$//g;
    @tmp=split(/,/,$take);
    $num=$#tmp;

    undef %tmp;			# slim-is-in!
    undef @tmp;			# slim-is-in!

    return(1,"ok $sbrName",$num,$take);
}				# end of hsspGetChainNali

#===============================================================================
sub hsspGetFile { 
    local ($fileInLoc,$Lscreen,@dir) = @_ ; 
    local ($fileHssp,$dir,$tmp,$chainLoc,@dir2,$idLoc);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   hsspGetFile                 searches all directories for existing HSSP file
#       in:                     $file,$Lscreen,@dir
#       out:                    returned file,chain ($hssp,$chain), (if chain in file)
#       watch:                  loop onto itself:
#                               1prcH.hssp not found -> try 1prc.hssp
#--------------------------------------------------------------------------------
    $#dir2=$Lok=0;
    return(0,"no input file")   if (! defined $fileInLoc);
    $chainLoc="";$idLoc=$fileInLoc;$idLoc=~s/^.*\///g;
    $#dir=0                     if (! defined @dir);
    $Lscreen=0                  if (! defined $Lscreen);
				# passed dir instead of Lscreen
    if (-d $Lscreen) { @dir=($Lscreen,@dir);
		       $Lscreen=0;}
    $fileInLoc=~s/\s|\n//g;
				# ------------------------------
				# is HSSP ok
    return($fileInLoc," ")      if (-e $fileInLoc && &is_hssp($fileInLoc));

				# ------------------------------
				# purge chain?
    if ($fileInLoc=~/^(.*\.hssp)_?([A-Za-z0-9])$/){
	$file=$1; $chainLoc=$2;
	return($file,$chainLoc) if (-e $file && &is_hssp($file)); }

				# ------------------------------
				# try adding directories
    foreach $dir(@dir){		# avoid endless loop when calling itself
	$Lok=1                  if ($dir =~ /\/data\/hssp/);
	push(@dir2,$dir);}
    @dir=@dir2;  push(@dir,"/data/hssp/") if (!$Lok); # give default

				# ------------------------------
				# before trying: purge chain
    $file=$fileInLoc; $chainLoc=" ";
    $file=~s/^(.*\.hssp)_?([A-Za-z0-9])$/$1/; 
    $chainLoc=$2 if (defined $2);
				# loop over all directories
    $fileHssp=
	&hsspGetFileLoop($file,$Lscreen,@dir);
    return($fileHssp,$chainLoc) if (-e $fileHssp && &is_hssp($fileHssp));

				# ------------------------------
                                # still not: dissect into 'id'.'chain'
    $tmp_file=$fileInLoc; $tmp_file=~s/^([A-Za-z0-9]+).*(\.hssp.*)$/$1$2/g;
    $fileHssp=
        &hsspGetFileLoop($tmp_file,$Lscreen,@dir);
    return($fileHssp,$chainLoc)    if (-e $fileHssp && &is_hssp($fileHssp));

				# ------------------------------
				# change version of file (1sha->2sha)
    $tmp1=substr($idLoc,2,3);
    foreach $it (1..9) {
        $tmp_file="$it"."$tmp1".".hssp";
        $fileHssp=
            &hsspGetFileLoop($tmp_file,$Lscreen,@dir);
	last if ($fileHssp ne "0");}
    return (0)                  if ( ! -e $fileHssp || &is_hssp_empty($fileHssp));
    return($fileHssp,$chainLoc);
}				# end of hsspGetFile

#===============================================================================
sub hsspGetFileLoop { 
    local ($fileInLoop,$Lscreen,@dir) = @_ ; 
    local ($fileOutLoop,$dir,$tmp);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   hsspGetFileLoop             loops over all directories
#       in:                     $file,$Lscreen,@dir
#       out:                    returned file
#--------------------------------------------------------------------------------
				# already ok 
    return($fileInLoop)         if (&is_hssp($fileInLoop));
				# missing extension
    $fileInLoop.=".hssp"        if ($fileInLoop !~ /\.hssp/);
				# already ok 
    return($fileInLoop)         if (&is_hssp($fileInLoop));
				# do NOT continue if starting with dir!!
    return(0)                   if ($fileInLoop =~ /^\//);

				# ------------------------------
    foreach $dir (@dir) {	# search through dirs
	$tmp=&complete_dir($dir) . $fileInLoop; # try directory
	$tmp=~s/\/\//\//g;	# '//' -> '/'
	print "--- hsspGetFileLoop: \t trying '$tmp'\n" if ($Lscreen);
	return($tmp)            if (-e $tmp && &is_hssp($tmp) );
    }
    return(0);			# none found
}				# end of hsspGetFileLoop

#===============================================================================
sub hsspRdAli {
    local ($fileInLoc,@want) = @_ ;
    local ($sbrName,$fhinLoc,$tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspRdAli                   reads and writes the sequence of HSSP + 70 alis
#       in:                     $fileHssp (must exist), 
#         @des                  (1) =1, 2, ...,  i.e. number of sequence to be read
#                               (2) = swiss_id1, swiss_id2, i.e. identifiers to read
#                               (3) = all (or undefined)
#                               NOTE: you can give ids AND numbers ('1','paho_chick','2') ..
#                               
#                               furthermore:
#                               if @want = 'seq|seqAli|seqNoins'
#                                  only those will be returned (e.g. $tmp{"seq","$ct"})
#                               default: all 3!
#       out:                    1|0,$rd{} with: 
#       err:                    (0,$msg)
#                    overall:
#                               $rd{"NROWS"}=          : number of alis, i.e. $#want
#                               
#                               $rd{"NRES"}=N          : number of residues in guide
#                               $rd{"SWISS"}='sw1,sw2' : list of swiss-ids read
#                               $rd{"0"}='pdbid'       : id of guide sequence (in file header)
#                               $rd{"$it"}='sw$ct'     : swiss id of the it-th alignment
#                               $rd{"$id"}='$it'       : position of $id in final list
#                               $rd{"sec","$itres"}    : secondary structure for residue itres
#                               $rd{"acc","$itres"}    : accessibility for residue itres
#                               $rd{"chn","$itres"}    : chain for residue itres
#                    per prot:
#                               $rd{"seqNoins","$ct"}=sequences without insertions
#                               $rd{"seqNoins","0"}=  GUIDE sequence
#                               
#                               $rd{"seq","$ct"}=SEQW  : sequences, with all insertions
#                                                        but NOT aligned!!!
#                               $rd{"seqAli","$ct"}    : sequences, with all insertions,
#                                                        AND aligned (all, including guide
#                                                        filled up with '.' !!
#-------------------------------------------------------------------------------
    $sbrName="lib-br:hsspRdAli"; $fhinLoc="FHIN"."$sbrName"; $fhinLoc=~tr/[a-z]/[A-Z]/;
				# file existing?
    if ((! -e $fileInLoc) || (! &is_hssp($fileInLoc))){
	print "*** ERROR $sbrName no HSSP file '$fileInLoc'\n";
	return(0);}
				# ------------------------------
				# HSSP file format settings
    $regexpBegAli=        "^\#\# ALIGNMENTS"; # begin of reading
    $regexpEndAli=        "^\#\# SEQUENCE PROFILE"; # end of reading
    $regexpSkip=          "^ SeqNo"; # skip lines with pattern
    $nmaxBlocks=          100;	# maximal number of blocks considered (=7000 alis!)
    $regexpBegIns=        "^\#\# INSERTION LIST"; # begin of reading insertion list
    
    undef %tmp; undef @seqNo; undef %seqNo;
				# ------------------------------
				# pointers
    undef %ptr_id2num;		# $ptr{xyz}= N   : id=xyz is the Nth ali
    undef @ptr_num2id;		# $ptr[N]=   xyz : Nth ali has id= xyz
    undef @ptr_numWant2numFin;	# $ptr[N]=   M   : the Nth ali is the Mth one in the list
				#                  of all numbers wanted (i.e. = $want[M])
    undef @ptr_numFin2numWant;	# $ptr[M]=   N   : see previous, the other way around!

    $#want=0                    if (! defined @want);
    $LreadAll=0; 
				# ------------------------------
				# digest input
    $#tmp=0; undef %kwd;	# (1) detect keywords
    foreach $tmp (@want){
	if ($tmp=~/^(seq|seqAli|seqNoins)$/){
	    $kwd{$tmp}=1; 
	    next;}
	push(@tmp,$tmp);}

    if (($#want>0) && ($#want == $#tmp) ){ # default keyworkds
	foreach $des ("seq","seqAli","seqNoins"){
	    $kwd{"$des"}=1;}}
    @want=@tmp;
				# (2) all?
    $LreadAll=1                 if ( ! @want || ! $want[1] || ($want[1] eq "all"));
    if (! $LreadAll){		# (3) read some
	$#wantNum=$#wantId=0;
	foreach $want (@want) {
	    if ($want !~ /[^0-9]/){push(@wantNum,$want);} # is number
	    else                  {push(@wantId,$want);}}}  # is id
				# ------------------------------
				# get numbers/ids to read
    ($Lok,%rdHeader)=
	&hsspRdHeader($fileInLoc,"SEQLENGTH","PDBID","NR","ID");
    if (! $Lok){
	print "*** ERROR $sbrName reading header of HSSP file '$fileInLoc'\n";
	return(0);}
    $tmp{"NRES"}= $rdHeader{"SEQLENGTH"};$tmp{"NRES"}=~s/\s//g;
    $tmp{"0"}=    $rdHeader{"PDBID"};    $tmp{"0"}=~s/\s//g;
    $idGuide=     $tmp{"0"};

    $#locNum=$#locId=0;		# store the translation name/number
    foreach $it (1..$rdHeader{"NROWS"}){
	$num=$rdHeader{"NR","$it"}; $id=$rdHeader{"ID","$it"};
	push(@locNum,$num);push(@locId,$id);
	$ptr_id2num{"$id"}=$num;
	$ptr_num2id[$num]=$id;}
    push(@locNum,"1")           if ($#locNum==0); # nali=1
				# ------------------------------
    foreach $want (@wantId){	# CASE: input=list of names
	$Lok=0;			#    -> add to @wantNum
	foreach $loc (@locId){
	    if ($want eq $loc){$Lok=1;push(@wantNum,$ptr_id2num{"$loc"});
			       last;}}
	if (! $Lok){
	    print "-*- WARNING $sbrName wanted id '$want' not in '$fileInLoc'\n";}}
				# ------------------------------
				# NOW we have all numbers to get
				# sort the array
    @wantNum= sort bynumber (@wantNum);
				# too many wanted
    if (defined @wantNum && ($wantNum[$#wantNum] > $locNum[$#locNum])){
	$#tmp=0; 
	foreach $want (@wantNum){
	    if ($want <= $locNum[$#locNum]){
		push(@tmp,$want)}
	    else {
		print "-*- WARNING $sbrName no $want not in '$fileInLoc'\n";
		exit;
	    }}
	@wantNum=@tmp;}
		
    @wantNum=@locNum if ($LreadAll);
    if ($#wantNum==0){
	print "*** ERROR $sbrName nothing to read ???\n";
	return(0);}
				# sort the array, again
    @wantNum= sort bynumber (@wantNum);
				# ------------------------------
				# assign pointers to final output
    foreach $it (1..$#wantNum){
	$numWant=$wantNum[$it];
	$ptr_numWant2numFin[$numWant]=$it;
	$ptr_numFin2numWant[$it]=     $numWant;}

				# ------------------------------
				# get blocks to take
    $wantLast=$wantNum[$#wantNum];$#wantBlock=0;
    foreach $ctBlock (1..$nmaxBlocks){
	$beg=1+($ctBlock-1)*70;
	$end=$ctBlock*70;
	last if ($wantLast < $beg);
	$Ltake=0;
	foreach $num(@wantNum){
	    if ( ($beg<=$num)&&($num<=$end) ){
		$Ltake=1;
		last;}}
	if ($Ltake){
	    $wantBlock[$ctBlock]=1;}
	else{
	    $wantBlock[$ctBlock]=0;}}
				# writes ids read
    $tmp{"SWISS"}="";
    foreach $it (1..$#wantNum){ $num=$wantNum[$it];
				$tmp{"$it"}=   $ptr_num2id[$num];
				$tmp{"SWISS"}.="$ptr_num2id[$num]".",";} 
    $tmp{"SWISS"}=~s/,*$//g;
    $tmp{"NROWS"}=$#wantNum;

				# ------------------------------------------------------------
				#       
				# NOTATION: 
				#       $tmp{"0",$it}=  $it-th residue of guide sequnec
				#       $tmp{$itali,$it}=  $it-th residue of of ali $itali
				#       note: itali= same numbering as in 1..$#want
				#             i.e. NOT the position in the file
				#             $ptr_numFin2numWant[$itali]=5 may reveal that
				#             the itali-th ali was actually the fifth in the
				#             HSSP file!!
				#             
				# ------------------------------------------------------------

				# --------------------------------------------------
				# read the file finally
				# --------------------------------------------------
    $Lok=&open_file("$fhinLoc","$fileInLoc");
    if (! $Lok){print "*** ERROR $sbrName opening hssp file '$fileInLoc'\n";
		return(0);}
				# ------------------------------
				# move until first alis
				# ------------------------------
    $ctBlock=$Lread=$#takeTmp=0;
    while (<$fhinLoc>){ 
	last if ($_=~/$regexpEndAli/); # ending
	if ($_=~/$regexpBegAli/){ # this block to take?
	    ++$ctBlock;$Lread=0;
	    if ($wantBlock[$ctBlock]){
		$_=~s/^[^0-9]+(\d+) -\s+(\d+).*$//;
		$beg=$1;$end=$2;$Lread=1;
		$#wantTmp=0;	# local numbers
		foreach $num (@wantNum){
		    if ( ($beg<=$num) && ($num<=$end) ){
			$tmp=($num-$beg)+1; 
			print "*** $sbrName negative number $tmp,$beg,$end,\n" x 3 if ($tmp<1);
			push(@wantTmp,$tmp);}}
		next;}}
	next if (! $Lread);	# move on
	next if ($_=~/$regexpSkip/); # skip line
	$line=$_;
				# --------------------
	if (length($line)<52){	# no alis in line
	    $seqNo=substr($line,1,6);$seqNo=~s/\s//g;
	    if (! defined $seqNo{$seqNo}){
		$seqNo{$seqNo}=1;
		push(@seqNo,$seqNo);}
				# NOTE: $chn,$sec,$acc are returned per residue!
	    if (! defined $tmp{"0","$seqNo"}){
		($seqNo,$pdbNo,
		 $tmp{"chn","$seqNo"},$tmp{"0","$seqNo"},
		 $tmp{"sec","$seqNo"},$tmp{"acc","$seqNo"})=
		     &hsspRdSeqSecAccOneLine($line);}
		    
	    foreach $num(@wantTmp){ # add insertions if no alis
		$pos=                    $num+$beg-1; 
		$posFin=                 $ptr_numWant2numFin[$pos];
		$tmp{"$posFin","$seqNo"}="."; }
	    next;}
				# ------------------------------
				# everything fine, so read !
				# ------------------------------
				# --------------------
				# first the HSSP stuff
	$seqNo=substr($line,1,6);$seqNo=~s/\s//g;
	if (! defined $seqNo{$seqNo}){
	    $seqNo{$seqNo}=1;
	    push(@seqNo,$seqNo);}
				# NOTE: $chn,$sec,$acc are returned per residue!
	if (! defined $tmp{"0","$seqNo"}){
	    ($seqNo,$pdbNo,
	     $tmp{"chn","$seqNo"},$tmp{"0","$seqNo"},
	     $tmp{"sec","$seqNo"},$tmp{"acc","$seqNo"})=
		 &hsspRdSeqSecAccOneLine($line);}
				# --------------------
				# now the alignments
	$alis=substr($line,52); $alis=~s/\n//g;

				# NOTE: @wantTmp has the positions to read in current block,
				#       e.g. want no 75, block=71-90, => 75->4
	foreach $num (@wantTmp){
	    $pos=                        $num+$beg-1; # note: beg=71 in the example above
	    $id=                         $ptr_num2id[$pos];
	    $posFin=                     $ptr_numWant2numFin[$pos];
	    $tmp{"$posFin"}=             $id;
	    $takeTmp[$pos]=              1;
	    print "*** $sbrName neg number $pos,$beg,$num,\n" x 3 if ($pos<1);
	    $tmp{"seq","$posFin"}=       ""     if (! defined $tmp{"seq","$posFin"});
	    if (length($alis) < $num){
		$tmp{"seq","$posFin"}.=  ".";
		$tmp{"$posFin","$seqNo"}=".";}
	    else {
		$tmp{"seq","$posFin"}.=  substr($alis,$num,1);
		$tmp{"$posFin","$seqNo"}=substr($alis,$num,1);}}}
				# ------------------------------
    while (<$fhinLoc>){		# skip over profiles
        last if ($_=~/$regexpBegIns/); } # begin reading insertion list

				# ----------------------------------------
				# store sequences without insertions!!
				# ----------------------------------------
    if (defined $kwd{"seqNoins"} && $kwd{"seqNoins"}){
				# --------------------
	$seq="";		# guide sequence
	foreach $seqNo(@seqNo){
	    $seq.=$tmp{"0","$seqNo"};}
	$seq=~s/[a-z]/C/g;		# small caps to 'C'
	$tmp{"seqNoins","0"}=$seq;
				# --------------------
				# all others (by final count!)
	foreach $it (1..$#wantNum){
	    $seq="";
	    foreach $seqNo(@seqNo){
		$seq.=$tmp{"$it","$seqNo"};}
	    $seq=~s/\s/\./g;	    # fill up insertions
	    $seq=~tr/[a-z]/[A-Z]/;  # small caps to large
	    $tmp{"seqNoins","$it"}=$seq;}
    }
				# --------------------------------------------------
				# read insertion list
				# 
				# syntax of insertion list:  
				#    ....,....1....,....2....,....3....,....4
				#    AliNo  IPOS  JPOS   Len Sequence
				#         9    58    59     5 kQLGAEi
				# 
				# --------------------------------------------------
    undef @insMax;		# note: $insMax[$seqNo]=5 means at residue 'seqNo'
    foreach $seqNo (@seqNo){	#       the longest insertion was 5 residues
	$insMax[$seqNo]=0;}
    while (<$fhinLoc>){
	$rd=$_;
	last if ((! defined $kwd{"seqAli"} || ! $kwd{"seqAli"}) &&
		 (! defined $kwd{"seq"}    || ! $kwd{"seq"}) );
	next if ($rd =~ /AliNo\s+IPOS/);  # skip key
	last if ($rd =~ /^\//);	          # end
        next if ($rd !~ /^\s*\d+/);       # should not happen (see syntax)
        $rd=~s/\n//g; $line=$rd;
	$posIns=$rd;		# current insertion from ali $pos
	$posIns=~s/^\s*(\d+).*$/$1/;
				# takeTmp[$pos]=1 if $pos to be read
	next if (! defined $takeTmp[$posIns] || ! $takeTmp[$posIns]);
				# ok -> take
	$line=~s/^\s*|\s*$//g;	# purge leading blanks
	@tmp=split(/\s+/,$line);
	$iposIns=$tmp[2];	# residue position of insertion
	$seqIns= $tmp[5];	# sequence at insertion 'kQLGAEi'
	$nresIns=(length($seqIns) - 2); # number of residues inserted
	$posFin= $ptr_numWant2numFin[$posIns];
				# --------------------------------------------------
				# NOTE: here $tmp{"$it","$seqNo"} gets more than
				#       one residue assigned (ref=11)
				# --------------------------------------------------
				# change 'ACinK' -> 'ACINEWNK'
	$tmp{"$posFin","$iposIns"}=substr($seqIns,1,(length($seqIns)-1));
				# maximal number of insertions
	$insMax[$iposIns]=$nresIns if ($nresIns > $insMax[$iposIns]);
    } close($fhinLoc);
				# end of reading file
				# --------------------------------------------------
    
				# ------------------------------
				# final sequences (not aligned)
				# ------------------------------
    if (defined $kwd{"seq"} && $kwd{"seq"}){
	foreach $it (0..$tmp{"NROWS"}){
	    $seq="";
	    foreach $seqNo(@seqNo){
		$seq.=$tmp{"$it","$seqNo"};}
	    $seq=~s/[\s\.!]//g;	# replace insertions 
	    $seq=~tr/[a-z]/[A-Z]/; # all capitals
	    $tmp{"seq","$it"}=$seq; }}
				# ------------------------------
				# fill up insertions
				# ------------------------------
    if (defined $kwd{"seqAli"} && $kwd{"seqAli"}){
	undef %ali;		# temporary for storing sequences
	foreach $it (0..$tmp{"NROWS"}){
	    $ali{$it}="";}	# set for all alis
				# ------------------------------
	foreach $seqNo(@seqNo){	# loop over residues
	    $insMax=$insMax[$seqNo];
				# loop over all alis
	    foreach $it (0..$tmp{"NROWS"}){
				# (1) CASE: no insertion
		if    ($insMax==0){
		    $ali{$it}.=$tmp{"$it","$seqNo"};
		    next;}
				# (2) CASE: insertions
		$seqHere=$tmp{"$it","$seqNo"};
		$insHere=(1+$insMax-length($seqHere));
				# NOTE: dirty fill them in 'somewhere'
				# take first residue
		$ali{$it}.=substr($seqHere,1,1);
				# fill up with dots
		$ali{$it}.="." x $insHere ;
				# take remaining residues (if any)
		$ali{$it}.=substr($seqHere,2) if (length($seqHere)>1); }}
				# ------------------------------
				# now assign to final
	foreach $it (0..$tmp{"NROWS"}){
	    $ali{$it}=~s/\s/\./g; # replace ' ' -> '.'
	    $ali{$it}=~tr/[a-z]/[A-Z]/;	# all capital
	    $tmp{"seqAli","$it"}=$ali{$it};}
	undef %ali;		# slim-is-in! 
    }
				# ------------------------------
				# save memory
    foreach $it (0..$tmp{"NROWS"}){
	if ($it == 0){		# guide
	    $id=         $idGuide; }
	else {			# pairs
	    $posOriginal=$ptr_numFin2numWant[$it];
	    $id=         $ptr_num2id[$posOriginal]; }
	$tmp{"$id"}= $id;
        foreach $seqNo (@seqNo){
	    undef $tmp{"$it","$seqNo"};}}
    undef @seqNo;      undef %seqNo;      undef @takeTmp;    undef @idLoc;
    undef @want;       undef @wantNum;    undef @wantId;     undef @wantBlock; 
    undef %rdHeader;   undef %ptr_id2num; undef @ptr_num2id; 
    undef @ptr_numWant2numFin; undef @ptr_numFin2numWant;
    return(1,%tmp);
}				# end of hsspRdAli

#===============================================================================
sub hsspRdHeader {
    local ($fileInLoc,@kwdInLoc) = @_ ;
    local ($sbrName,$fhinLoc,$tmp,
	   @kwdDefHsspTopLoc,@kwdDefHsspHdrLoc,@kwdHsspTopLoc,@kwdHsspHdrLoc,@tmp,
	   $regexpBegHeader,$regexpEndHeader,$regexpLongId,$lenStrid,$LisLongId,
	   %ptr,$kwd,$Lok,$Lpdb,$des,$beg,$end,$mid,$ct,$id,$strid,$ptr,$tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspRdHeader                reads a HSSP header
#       in:                     $fileHssp (must exist), 
#         @kwdInLoc             = one of the default keywords 
#                               (@kwdLocHsspTop,@kwdLocHsspHeader)
#       in:                     'nopair' surpresses reading of pair information
#       out:                    for top  (e.g. NALIGN): $rd{"kwd"}
#                               for prot (e.g. LALI):   $rd{"kwd","$it"}
#                               note: for the later number of elements (it) in
#                                     $rd{"NROWS"}
#         special               ID=ID1, $rd{"kwd","$it"} existes for ID1 and ID2
#-------------------------------------------------------------------------------
    $sbrName="lib-br:hsspRdHeader";$fhinLoc="FHIN"."$sbrName";$fhinLoc=~tr/[a-z]/[A-Z]/;
				# file existing?
    if (! -e $fileInLoc || ! &is_hssp($fileInLoc) ){
	print "*** ERROR $sbrName no HSSP file '$fileInLoc'\n";
	return(0);}
				# ------------------------------
				# settings describing format
    @kwdDefHsspTopLoc= ("PDBID","DATE","SEQBASE","PARAMETER","THRESHOLD",
			"REFERENCE","HEADER","COMPND","SOURCE","AUTHOR",
			"SEQLENGTH","NCHAIN","KCHAIN","NALIGN");
    @kwdDefHsspHdrLoc= ("NR","ID","STRID","IDE","WSIM","IFIR","ILAS",
			"JFIR","JLAS","LALI","NGAP","LGAP","LSEQ2","ACCNUM","PROTEIN");
    $regexpBegHeader=   "^\#\# PROTEINS"; # begin of reading 
    $regexpEndHeader=   "^\#\# ALIGNMENTS"; # end of reading
    $regexpLongId=      "^PARAMETER  LONG-ID :YES"; # identification of long id

    $lenStrid=          4;	# minimal length to identify PDB identifiers
    $LisLongId=         0;	# long identifier names

    $ptr{"IDE"}=1;$ptr{"WSIM"}=2;$ptr{"IFIR"}=3;$ptr{"ILAS"}=4;$ptr{"JFIR"}=5;$ptr{"JLAS"}=6;
    $ptr{"LALI"}=7;$ptr{"NGAP"}=8;$ptr{"LGAP"}=9;$ptr{"LSEQ2"}=10; $ptr{"ACCNUM"}=11;

				# ------------------------------
				# check input arguments
    $#kwdHsspTopLoc=$#kwdHsspHdrLoc=$Lpdb=$LnoPair=0;
    foreach $kwd (@kwdInLoc){
	$Lok=0;
	if ($kwd eq "nopair"){
	    $LnoPair=1;
	    next;}
	$Lpdb=1 if (! $Lpdb && ($kwd =~/^PDBID/));
	foreach $des (@kwdDefHsspTopLoc)   {
	    if ($kwd eq $des){ $Lok=1; push(@kwdHsspTopLoc,$kwd);
			       last;}}
	next if ($Lok || $LnoPair);
	foreach $des (@kwdDefHsspHdrLoc){
	    if ($kwd eq $des){ $Lok=1; push(@kwdHsspHdrLoc,$kwd);
			       last;} }
	print "-*- WARNING $sbrName input kwd=$kwd, makes no sense??\n" if (! $Lok);}

				# force reading of NALI
    push(@kwdHsspTopLoc,"PDBID") if (! $Lpdb);
	
				# get column numbers to read
				# ------------------------------
				# now start to read
    $Lok=&open_file("$fhinLoc","$fileInLoc");
    if (! $Lok){print "*** ERROR $sbrName HSSP file could not be opened '$fileInLoc'\n";
		return(0);}
    undef %tmp;		# save space
				# ------------------------------
    while ( <$fhinLoc> ) {	# read top
	last if ($_ =~ /$regexpBegHeader/); 
	if ($_ =~ /$regexpLongId/) {
	    $LisLongId=1;}
	else{$_=~s/\n//g;$arg=$_;
	     foreach $des (@kwdHsspTopLoc){
		 if ($arg  =~ /^$des\s+(.+)$/){
		     if (defined $ok{"$des"}){ # multiple lines!
			 $tmp="$1"."\t";
			 if  (defined $tmp{"$des"}){
			     $tmp{"$des"}.=$tmp;}
			 else{$tmp{"$des"}=$tmp;}}
		     else {$ok{"$des"}=1;$tmp{"$des"}=$1;}
		     if ($des=~/SEQLENGTH|NCHAIN|KCHAIN|NALIGN/){
			 $tmp{"$des"}=~s/^(\d+)[^0-9]+.*$/$1/;} # purge blanks
		     last;}}}}
				# ------------------------------
    $ct=0;			# read header
    while ( <$fhinLoc> ) { 
	last if ($LnoPair);	# supress reading pair info
	last if ($_ =~ /$regexpEndHeader/); 
	next if ($_ =~ /^  NR\./); # skip descriptors
	if ($LisLongId){
	    $beg=substr($_,1,56);$end=substr($_,109);$mid=substr($_,57,115); }
	else {
	    $beg=substr($_,1,28);$end=substr($_,90);$mid=substr($_,29,90); }
	$end=~s/^\s*|\s*$|\n//g; # purge leading blanks
	$mid=~s/^\s*|\s*$//g;	# purge leading blanks
				# SWISS accession: hack because it may be empty!
	$accnum=substr($_,81,6); $accnum=~s/(\s)\s+/$1/g;
				# begin: counter and id
	$beg=~s/.+ \:\s*|\s*$//g;
	if (! $LisLongId) {$id=$beg;$id=~s/([^\s]+).*$/$1/;
			   $strid=$beg;$strid=~s/$id|\s//g; }
	else              {$id=$beg;$id=~s/(.+_\S+).*/$1/;
			   $strid=substr($_,49,6);$strid=~s/\s//g; }
	$tmp=$lenStrid-1;
	if ( (length($strid)<$lenStrid) && ($id=~/^[0-9][A-Z0-9]{$tmp,$tmp}\s*/)){
	    $strid=substr($id,1,$lenStrid); }
	++$ct;

	$tmp{"ID","$ct"}=$id;
	$tmp{"NR","$ct"}=$ct;
	$tmp{"STRID","$ct"}=$strid;
	$tmp{"PROTEIN","$ct"}=$end;
	$tmp{"ID1","$ct"}=$tmp{"PDBID"};
	$tmp{"ACCNUM","$ct"}=$accnum;
				# middle all info
	$#tmp=0;@tmp=split(/\s+/,$mid);
	foreach $_ (@tmp) {$_=~s/\s//g;}

	foreach $des (@kwdHsspHdrLoc){ 
	    next if ( ! defined $ptr{"$des"});
	    next if ( $des =~/^ACCNUM/);
	    $ptr=$ptr{"$des"};
	    $tmp{"$des","$ct"}=$tmp[$ptr]; }}close($fhinLoc);
    $tmp{"NROWS"}=$ct;
				# clean up
    $#kwdInLoc=$#kwdDefHsspHdrLoc=$#kwdHsspTopLoc=$#tmp=
	$#kwdDefHsspTopLoc=$#kwdHsspHdrLoc=0;
    undef %ptr;
    return(1,%tmp);
}				# end of hsspRdHeader

#===============================================================================
sub hsspRdHeader4topits {
    local ($file_in) = @_ ;
    local ($fhinLoc,$sbrName,$msg,$ct,$tmp,$tmp2,@tmp,$it,%rd_hssp);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   hsspRdHeader4topits         extracts the summary from HSSP header (for TOPITS)
#       in:                     $fileHssp 
#       out:                    $rd_hssp{"kwd","$ct"}, where :
#                                  $ct= number of protein
#                                  kwd= ide,ifir,jfir,ilas,jlas,lali,ngap,lgap,len2,id2
#                               number of proteins: $rd_hssp{"NROWS"}=$rd_hssp{"nali"}
#       err:                    ok=(1,'ok',$rd_hssp{}), err=(0,'msg',"error")
#--------------------------------------------------------------------------------
    $sbrName="hsspRdHeader4topits";$fhinLoc="FHIN"."$sbrName";

    return(0,"*** ERROR $sbrName: no HSSP file '$file_in'\n","error")
	if (! -e $file_in);
    $Lok=       &open_file("$fhinLoc","$file_in");
    return(0,"*** ERROR $sbrName: '$file_in' not opened\n","error")
	if (! $Lok);
    undef %rd_hssp;		# save space
				# ------------------------------
				# go off reading
    while(<$fhinLoc>){
	last if ($_=/^\#\# PROTEINS/);}	# end of header
    $ct=0;
    while(<$fhinLoc>){
	last if ($_=/^\#\# ALI/);
	next if ($_=~/^  NR/);
	next if (length($_)<27); # xx hack should not happen!!
	$tmp=substr($_,27);
	$tmp=~s/^\s*|\s$//g;	# purge leading blanks
	$#tmp=0;@tmp=split(/\s+/,$tmp);
	++$ct;
	$rd_hssp{"ide","$ct"}=$tmp[1];
	$rd_hssp{"ifir","$ct"}=$tmp[3];$rd_hssp{"jfir","$ct"}=$tmp[5];
	$rd_hssp{"ilas","$ct"}=$tmp[4];$rd_hssp{"jlas","$ct"}=$tmp[6];
	$rd_hssp{"lali","$ct"}=$tmp[7];
	$rd_hssp{"ngap","$ct"}=$tmp[8];$rd_hssp{"lgap","$ct"}=$tmp[9];
	$rd_hssp{"len2","$ct"}=$tmp[10];

	$tmp= substr($_,7,20);
	$tmp2=substr($_,20,6);
	$tmp3=$tmp2; $tmp3=~s/\s//g;
	if (length($tmp3)<3) {	# STRID empty
	    $tmp=substr($_,8,6);
	    $tmp=~s/\s//g;
	    $rd_hssp{"id2","$ct"}=$tmp;}
	else{$tmp2=~s/\s//g;
	     $rd_hssp{"id2","$ct"}=$tmp2;}}close($fhinLoc);
    $rd_hssp{"nali"}=$rd_hssp{"NROWS"}=$ct;
    return(1,"ok $sbrName",%rd_hssp);
}				# end of hsspRdHeader4topits

#===============================================================================
sub hsspRdProfile {
    local($fileInLoc,$ifirLoc,$ilasLoc,$chainLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$line,$seqNo,$pdbNo,$chainRd,$ifirRd,$ilasRd);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspRdProfile               reads the HSSP profile from ifir to ilas
#       in:                     file.hssp_C ifir ilas $chainLoc (* for all numbers and chain) 
#       out:                    %prof{"kwd","it"}
#                   @kwd=       ("seqNo","pdbNo","V","L","I","M","F","W","Y","G","A","P",
#				 "S","T","C","H","R","K","Q","E","N","D",
#				 "NOCC","NDEL","NINS","ENTROPY","RELENT","WEIGHT");
#-------------------------------------------------------------------------------
    $sbrName="lib-br:hsspRdProfile";$fhinLoc="FHIN"."$sbrName";
    undef %tmp;

    if (! -e $fileInLoc){print "*** $sbrName: HSSP file '$fileInLoc' missing\n";
			 return(0);}
    $chainLoc=0          if (! defined $chainLoc || ! &is_chain($chainLoc));
    $ifirLoc=0           if (! defined $ifirLoc || $ifirLoc eq "*" );
    $ilasLoc=0           if (! defined $ilasLoc || $ilasLoc eq "*" );
				# read profile
    &open_file("$fhinLoc","$fileInLoc") || return(0);
				# ------------------------------
    while (<$fhinLoc>) {	# skip before profile
	last if ($_=~ /^\#\# SEQUENCE PROFILE AND ENTROPY/);}
    $name=<$fhinLoc>;
    $name=~s/\n//g;$name=~s/^\s+|\s+$//g; # trailing blanks
    ($seqNo,$pdbNo,@name)=split(/\s+/,$name);
    $ct=0;			# ------------------------------
    while (<$fhinLoc>) {	# now the profile
	$line=$_; $line=~s/\n//g;
	last if ($_=~/^\#\#/);
	next if (length($line)<13);
	$seqNo=  substr($line,1,5);$seqNo=~s/\s//g;
	$pdbNo=  substr($line,6,5);$pdbNo=~s/\s//g;
	$chainRd=substr($line,12,1); # grep out chain identifier
	next if ( $chainLoc && ($chainRd ne $chainLoc));
	next if ( $ifirLoc  && ($seqNo < $ifirLoc));
	next if ( $ilasLoc  && ($seqNo > $ilasLoc));
	$line=substr($line,13);
	$line=~s/^\s+|\s+$//g; # trailing blanks
	@tmp=split(/\s+/,$line);
	++$ct;
	$tmp{"seqNo","$ct"}=$seqNo;
	$tmp{"pdbNo","$ct"}=$pdbNo;
	foreach $it (1..$#name){
	    $tmp{"$name[$it]","$ct"}=$tmp[$it]; }
	$tmp{"NROWS"}=$ct; }close($fhinLoc);
    return(1,%tmp);
}				# end of hsspRdProfile

#===============================================================================
sub hsspRdSeqSecAcc {
    local($fileInLoc,$ifirLoc,$ilasLoc,$chain,@kwdRd) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$line,$chainLoc,$seqNo,$pdbNo,$chainRd,$ifirRd,$ilasRd);
    $[=1;
#----------------------------------------------------------------------
#   hsspRdSeqSecAcc             reads the HSSP seq/sec/acc from ifir to ilas
#       in:                     file.hssp_C ifir ilas (* for all numbers, ' ' or '*' for chain)
#                               @kwdRd (which to read) = 0 for all
#       out:                    %rdLoc{"kwd","it"}
#                 @kwd=         ("seqNo","pdbNo","seq","sec","acc")
#                                'chain'
#----------------------------------------------------------------------
    $sbrName="lib-br:hsspRdSeqSecAcc";$fhinLoc="FHIN"."$sbrName";$fhinLoc=~tr/[a-z]/[A-Z]/;
				# file existing?
    $chainLoc=0;
    if    (defined $chain){
	$chainLoc=$chain;}
    elsif ($fileInLoc =~/\.hssp.*_(.)/){
	$chainLoc=$fileInLoc;$chainLoc=~s/^.+.hssp.*_(.)$/$1/;
	$fileInLoc=~s/^(.+.hssp.*)_(.)$/$1/;}

    if (! -e $fileInLoc){
	print "*** $sbrName: HSSP file '$fileInLoc' missing\n";
	return(0);}
    $ifirLoc=0  if (! defined $ifirLoc  || ($ifirLoc eq "*") );
    $ilasLoc=0  if (! defined $ilasLoc  || ($ilasLoc eq "*") );
    $chainLoc=0 if (! defined $chainLoc || ($chainLoc eq "*") );
    $#kwdRd=0   if (! defined @kwdRd);
    undef %tmp;
    if ($#kwdRd>0){
	foreach $tmp(@kwdRd){
	    $tmp{"$tmp"}=1;}}
				# ------------------------------
				# open file
    $Lok=&open_file("$fhinLoc","$fileInLoc");
    if (! $Lok){print "*** ERROR $sbrName could not open HSSP '$fileInLoc'\n";
		return(0);}
				# ------------------------------
    while (<$fhinLoc>) {	# header
	last if ( $_=~/^\#\# ALIGNMENTS/ ); }
    $tmp=<$fhinLoc>;		# skip 'names'
    $ct=0;
				# ------------------------------
				# read seq/sec/acc
    while (<$fhinLoc>) {
	$line=$_; $line=~s/\n//g;
	last if ( $_=~/^\#\# / ) ;
        $seqNo=  substr($line,1,6);$seqNo=~s/\s//g;
        $pdbNo=  substr($line,7,6);$pdbNo=~s/\s//g;
        $chainRd=substr($line,13,1);  # grep out chain identifier
	next if ( $chainLoc && ($chainRd ne $chainLoc));
	next if ( $ifirLoc  && ($seqNo < $ifirLoc));
	next if ( $ilasLoc  && ($seqNo > $ilasLoc));
	++$ct;$tmp{"NROWS"}=$ct;
        if (defined $tmp{"chain"}) { $tmp{"chain","$ct"}=$chainRd; }
        if (defined $tmp{"seq"})   { $tmp{"seq","$ct"}=  substr($_,15,1); }
	if (defined $tmp{"sec"})   { $tmp{"sec","$ct"}=  substr($_,18,1); }
	if (defined $tmp{"acc"})   { $tmp=               substr($_,37,3); $tmp=~s/\s//g;
				     $tmp{"acc","$ct"}=  $tmp; }
	if (defined $tmp{"seqNo"}) { $tmp{"seqNo","$ct"}=$seqNo; }
	if (defined $tmp{"pdbNo"}) { $tmp{"pdbNo","$ct"}=$pdbNo; }
    }
    close($fhinLoc);
            
    return(1,%tmp);
}                               # end of: hsspRdSeqSecAcc 

#===============================================================================
sub hsspRdSeqSecAccOneLine {
    local ($inLine) = @_ ;
    local ($sbrName,$fhinLoc,$seqNo,$pdbNo,$chn,$seq,$sec,$acc,$tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspRdSeqSecAccOneLine      reads begin of one HSSP line
#-------------------------------------------------------------------------------
    $sbrName="hsspRdSeqSecAccOneLine";

    $seqNo=substr($inLine,1,6);$seqNo=~s/\s//g;
    $pdbNo=substr($inLine,7,5);$pdbNo=~s/\s//g;
    $chn=  substr($inLine,13,1);
    $seq=  substr($inLine,15,1);
    $sec=  substr($inLine,18,1);
    $acc=  substr($inLine,36,4);$acc=~s/\s//g;
    return($seqNo,$pdbNo,$chn,$seq,$sec,$acc)
}				# end of hsspRdSeqSecAccOneLine

#===============================================================================
sub hsspRdStrip4topits {
    local ($file_in) = @_ ;
    local ($fhinLoc,$sbrName,$msg,@strip);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   hsspRdStrip4topits          reads the new strip file for PP
#       in:                     $fileHssp 
#       out:                    $rd_hssp{"kwd","$ct"}, where :
#       err:                    ok=(1,'ok',$rd_hssp{}), err=(0,'msg',"error")
#--------------------------------------------------------------------------------
    $sbrName="hsspRdStrip4topits";$fhinLoc="FHIN"."$sbrName";
    $Lok=       &open_file("$fhinLoc","$file_in");
    if (! $Lok){$msg="*** ERROR $sbrName: '$file_in' not opened\n";
		return(0,$msg,"error");}
    $#strip=0;
    while(<$fhinLoc>){
	push(@strip,$_);}close($fhinLoc);
    return(1,"ok $sbrName",@strip);
}				# end of hsspRdStrip4topits

#===============================================================================
sub hsspRdStripAndHeader {
    local($fileInHsspLoc,$fileInStripLoc,$fhErrSbr,@kwdInLocRd) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok,$LhsspTop,$LhsspPair,$LstripTop,$LstripPair,$kwd,$kwdRd,
	  @sbrKwdHsspTop,    @sbrKwdHsspPair,    @sbrKwdStripTop,     @sbrKwdStripPair, 
	  @sbrKwdHsspTopDo,  @sbrKwdHsspPairDo,  @sbrKwdStripTopDo,   @sbrKwdStripPairDo,
	  @sbrKwdHsspTopWant,@sbrKwdHsspPairWant,@sbrKwdStripTopWant, @sbrKwdStripPairWant,
	  %translateKwdLoc,%rdHsspLoc,%rdStripLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspRdStripAndHeader        reads the headers for HSSP and STRIP and merges them
#       in:                     $fileHssp,$fileStrip,$fhErrSbr,@keywords
#         $fhErrSbr             FILE-HANDLE to report errors
#         @keywords             "hsspTop",  @kwdHsspTop,
#                               "hsspPair", @kwdHsspPairs,
#                               "stripTop", @kwdStripTop,
#                               "stripPair",@KwdStripPair,
#                               i.e. the key words of the variables to read
#                               following translation:
#         HsspTop:              pdbid1   -> PDBID     (of fileHssp, 1pdb_C -> 1pdbC)
#                               date     -> DATE      (of file)
#                               db       -> SEQBASE   (database used for ali)
#                               parameter-> PARAMETER (lines giving the maxhom paramters)
#             NOTE:                         multiple lines separated by tabs!
#                               threshold-> THRESHOLD (i.e. which threshold was used)
#                               header   -> HEADER
#                               compnd   -> COMPND    
#                               source   -> SOURCE
#                               len1     -> SEQLENGTH (i.e. length of guide seq)
#                               nchain   -> NCHAIN    (number of chains in protein)
#                               kchain   -> KCHAIN    (number of chains in file)
#                               nali     -> NALIGN    (number of proteins aligned in file)
#         HsspPair:             pos      -> NR        (number of pair)
#                               id2      -> ID        (id of aligned seq, 1pdb_C -> 1pdbC)
#                               pdbid2   -> STRID     (PDBid of aligned seq, 1pdb_C -> 1pdbC)
#                               pide     -> IDEN      (seq identity, returned as int Perce!!)
#                               wsim     -> WSIM      (weighted simil., ret as int Percentage)
#                               ifir     -> IFIR      (first residue of guide seq in ali)
#                               ilas     -> ILAS      (last residue of guide seq in ali)
#                               jfir     -> JFIR      (first residue of aligned seq in ali)
#                               jlas     -> JLAS      (last residue of aligned seq in ali)
#                               lali     -> LALI      (number of residues aligned)
#                               ngap     -> NGAP      (number of gaps)
#                               lgap     -> LGAP      (length of all gaps, number of residues)
#                               len2     -> LSEQ2     (length of aligned sequence)
#                               swissAcc -> ACCNUM    (SWISS-PROT accession number)
#         StripTop:             nali     -> alignments (number of alis)
#                               listName -> list name (alignment list)
#                               lastName -> last name was (last aligned id)
#                               sortMode -> sort-mode (ZSCORE/asf.)
#                               weight1  -> weights 1 (sequence weights for guide: (YES|NO))
#                               weight2  -> weights 2 (sequence weights for aligned: (YES|NO))
#                               smin     -> smin      (minimal value of scoring metric)
#                               smax     -> smax      (maximal value of scoring metric)
#                               gapOpen  -> gap_open  (gap open penalty)
#                               gapElon  -> gap_elongation  (gap elongation/extension penalty)
#                               indel1   -> INDEL in sec-struc of SEQ1 (YES|NO)
#                               indel2   -> INDEL in sec-struc of SEQ2 (YES|NO)
#         StripPair:            energy   -> VAL       (Smith-Waterman score)
#                               idel     -> 
#                               ndel     -> 
#                               zscore   -> ZSCORE
#                               strh     -> STRHOM    (secStr ide Q3, , ret as int Percentage)
#                               rmsd     -> RMS
#                               name     -> NAME      (name of protein)
#       out:                    %rdHdr{""}
#                               $rdHdr{"NROWS"}       (number of pairs read)
#                               $rdHdr{"$kwd"}        kwds, only for guide sequenc
#                               $rdHdr{"$kwd","$ct"}  all values for each pair ct
#       err:                    ok=(1,'ok',$rd_hssp{}), err=(0,'msg',"error")
#-------------------------------------------------------------------------------
    $sbrName="lib-br:hsspRdStripAndHeader";$fhinLoc="FHIN"."$sbrName";
				# files existing?
    return(0,"error","*** ERROR ($sbrName) no HSSP  '$fileInHsspLoc'\n")
	if (! defined $fileInHsspLoc || ! -e $fileInHsspLoc);
	
    return(0,"error","*** ERROR ($sbrName) no STRIP '$fileInStripLoc'\n")
	if (! defined $fileInStripLoc || ! -e $fileInStripLoc);
				# ------------------------------
    @sbrKwdHsspTop=		# defaults
	("PDBID","DATE","SEQBASE","PARAMETER","THRESHOLD","HEADER","COMPND","SOURCE",
	 "SEQLENGTH","NCHAIN","KCHAIN","NALIGN");
#		   "REFERENCE","AUTHOR",
    @sbrKwdHsspPair= 
	("NR","ID","STRID","IDE","WSIM","IFIR","ILAS",
	 "JFIR","JLAS","LALI","NGAP","LGAP","LSEQ2","ACCNUM","PROTEIN");
    @sbrKwdStripPair= 
	("NR","VAL","LALI","IDEL","NDEL","ZSCORE","IDE","STRHOM","LEN2","RMSD","SIGMA","NAME");
    @sbrKwdStripTop= 
	("nali","listName","lastName","sortMode","weight1","weight2","smin","smax",
	 "gapOpen","gapElon","indel1","indel2");
    %translateKwdLoc=		# hssp top
	('id1',"ID1", 'pdbid1',"PDBID", 'date',"DATE", 'db',"SEQBASE",
	 'parameter',"PARAMETER", 'threshold',"THRESHOLD",
	 'header',"HEADER", 'compnd',"COMPND", 'source',"SOURCE",
	 'len1',"SEQLENGTH", 'nchain',"NCHAIN", 'kchain',"KCHAIN", 'nali',"NALIGN",
				# hssp pairs
	 'pos',"NR", 'id2',"ID", 'pdbid2',"STRID", 'pide',"IDE", 'wsim',"WSIM",
	 'ifir',"IFIR", 'ilas',"ILAS", 'jfir', "JFIR", 'jlas',"JLAS",
	 'lali',"LALI", 'ngap', "NGAP", 'lgap',"LGAP", 'len2',"LSEQ2", 'swissAcc',"ACCNUM",
				# strip top
				# non all as they come!
				# strip pairs
	 'energy',"VAL", 'zscore',"ZSCORE", 'rmsd',"RMSD", 'name',"NAME", 'strh',"STRHOM",
	 'idel',"IDEL", 'ndel',"NDEL", 'lali',"LALI", 'pos', "NR",'sigma',"SIGMA"
	 );
    @sbrKwdHsspTopDo=  @sbrKwdHsspTopWant=  @sbrKwdHsspTop;
    @sbrKwdHsspPairDo= @sbrKwdHsspPairWant= @sbrKwdHsspPair;
    @sbrKwdStripTopDo= @sbrKwdStripTopWant= @sbrKwdStripTop;
    @sbrKwdStripPairDo=@sbrKwdStripPairWant=@sbrKwdStripPair;
				# ------------------------------
				# process keywords
    if ($#kwdInLocRd>1){
				# ini
	$#sbrKwdHsspTopDo=$#sbrKwdHsspPairDo=$#sbrKwdStripTopDo=$#sbrKwdStripPairDo=
	    $#sbrKwdHsspTopWant=$#sbrKwdHsspPairWant=
		$#sbrKwdStripTopWant=$#sbrKwdStripPairWant=0;
	$LhsspTop=$LhsspPair=$LstripTop=$LstripPair=0;
	foreach $kwd (@kwdInLocRd){
	    next if ($kwd eq "id1"); # will be added manually
	    next if (length($kwd)<1);
	    if    ($kwd eq "hsspTop") {$LhsspTop=1; }
	    elsif ($kwd eq "hsspPair"){$LhsspPair=1; $LhsspTop=0;}
	    elsif ($kwd eq "stripTop"){$LstripTop=1; $LhsspTop=$LhsspPair=0;}
	    elsif ($kwd =~ /strip/)   {$LstripPair=1;$LhsspTop=$LhsspPair=$LstripTop=0;}
	    elsif ($LhsspTop){
		if (! defined $translateKwdLoc{"$kwd"}){
		    print $fhErrSbr "*** ERROR $sbrName HSSPtop kwd=$kwd, not understood\n";}
		else {
		    push(@sbrKwdHsspTopWant,$kwd);
		    push(@sbrKwdHsspTopDo,$translateKwdLoc{"$kwd"});}}
	    elsif ($LhsspPair){
		if (! defined $translateKwdLoc{"$kwd"}){
		    print $fhErrSbr "*** ERROR $sbrName HSSPpair kwd=$kwd, not understood\n";}
		else {
		    push(@sbrKwdHsspPairWant,$kwd);
		    push(@sbrKwdHsspPairDo,$translateKwdLoc{"$kwd"});}}
	    elsif ($LstripTop){
		if (! defined $translateKwdLoc{"$kwd"} || $kwd eq "nali"){
		    push(@sbrKwdStripTopWant,$kwd);
		    push(@sbrKwdStripTopDo,$kwd);}
		else {
		    push(@sbrKwdStripTopWant,$kwd);
		    push(@sbrKwdStripTopDo,$translateKwdLoc{"$kwd"});}}
	    elsif ($LstripPair){
		if (! defined $translateKwdLoc{"$kwd"}){
		    print $fhErrSbr "*** ERROR ($sbrName) STRIP keyword  '$kwd' not understood\n";}
		else {
		    push(@sbrKwdStripPairWant,$kwd);
		    push(@sbrKwdStripPairDo,$translateKwdLoc{"$kwd"});}}}}

    undef %tmp; undef %rdHsspLoc; undef %rdStripLoc; # save space
				# ------------------------------
				# read HSSP header
    ($Lok,%rdHsspLoc)=
	&hsspRdHeader($fileInHsspLoc,@sbrKwdHsspTopDo,@sbrKwdHsspPairDo);
    return(0,"error","*** ERROR $sbrName: hsspRdHeader erred on $fileInHsspLoc\n")
	if (! $Lok);
				# ------------------------------
				# read STRIP header
    %rdStripLoc=
	&hsspRdStripHeader($fileInStripLoc,"unk","unk","unk","unk","unk",
			   @sbrKwdStripTopDo,@sbrKwdStripPairDo);
    return(0,"error","*** ERROR $sbrName: hsspRdHeader erred on $fileInHsspLoc\n")
	if (! %rdStripLoc);
				# security check
    if ($rdStripLoc{"NROWS"} != $rdHsspLoc{"NROWS"}){
	$txt="*** ERROR ($sbrName) number of pairs differ\n".
	    "*** HSSP  =".$rdHsspLoc{"NROWS"}."\n".
		"*** STRIP =".$rdStripLoc{"NROWS"}."\n";
	return(0,"error",$txt);}
				# ------------------------------
				# merge the two
    $tmp{"NROWS"}=$rdHsspLoc{"NROWS"}; 
				# --------------------
				# hssp info guide (top)
    foreach $kwd (@sbrKwdHsspTopWant){
	$kwdRd=$translateKwdLoc{"$kwd"};
	if (! defined $rdHsspLoc{"$kwdRd"}){
	    print $fhErrSbr "-*- WARNING ($sbrName) rdHsspLoc-Top not def for $kwd->$kwdRd\n";}
	else {
	    $tmp{"$kwd"}=$rdHsspLoc{"$kwdRd"};}}
				# --------------------
				# hssp info pairs
    foreach $it (1..$rdHsspLoc{"NROWS"}){
	$tmp{"id1","$it"}= $tmp{"pdbid1"}; # add identifier for each pair
	$tmp{"len1","$it"}=$tmp{"len1"}; # add identifier for each pair
	foreach $kwd (@sbrKwdHsspPairWant){
	    $kwdRd=$translateKwdLoc{"$kwd"};
	    if (! defined $rdHsspLoc{"$kwdRd","$it"}){
		print $fhErrSbr "-*- WARNING ($sbrName) HsspLoc not for $kwd->$kwdRd ($it)\n";}
	    else {
		$tmp{"$kwd","$it"}=$rdHsspLoc{"$kwdRd","$it"};}}}
				# --------------------
				# strip pairs
    foreach $kwd (@sbrKwdStripPairWant){
	$kwdRd=$translateKwdLoc{"$kwd"};
	foreach $it (1..$rdStripLoc{"NROWS"}){
	    if (! defined $rdStripLoc{"$kwdRd","$it"}){
		print $fhErrSbr "-*- WARNING ($sbrName) StripLoc not for $kwd->$kwdRd ($it)\n";}
	    else {
		$tmp{"$kwd","$it"}=$rdStripLoc{"$kwdRd","$it"};}}}
				# --------------------
				# purge blanks
    foreach $kwd (@sbrKwdHsspPairWant,@sbrKwdStripPairWant){
	next if ($kwd =~/^name$|^protein/);
	foreach $it (1..$tmp{"NROWS"}){
	    $tmp{"$kwd","$it"}=~s/\s//g;}}
				# correction for 'pide','wsim'
    foreach $it (1..$rdHsspLoc{"NROWS"}){
	$tmp{"pide","$it"}*=100   if (defined $tmp{"pide","$it"});
	$tmp{"wsim","$it"}*=100   if (defined $tmp{"wsim","$it"});
	$tmp{"strh","$it"}*=100   if (defined $tmp{"strh","$it"});
	$tmp{"id1","$it"}=~s/_//g if (defined $tmp{"id1","$it"});
	$tmp{"id2","$it"}=~s/_//g if (defined $tmp{"id2","$it"});
    }
				# --------------------
    undef @kwdInLocRd;		# save space!
    undef @sbrKwdHsspTop;     undef @sbrKwdHsspPair;     undef @sbrKwdStripPair; 
    undef @sbrKwdHsspTopDo;   undef @sbrKwdHsspPairDo;   undef @sbrKwdStripPairDo; 
    undef @sbrKwdHsspTopWant; undef @sbrKwdHsspPairWant; undef @sbrKwdStripPairWant; 
    undef %rdHsspLoc; undef %rdStripLoc; undef %translateKwdLoc; 
    return(1,"ok $sbrName",%tmp);
}				# end of hsspRdStripAndHeader

#===============================================================================
sub hsspRdStripHeader {
    local($fileInLoc,$exclTxt,$inclTxt,$minZ,$lowIde,$upIde,@kwdInStripLoc)=@_ ;
    local($sbrName,$fhinLoc,$Lok,$tmp,@excl,@incl,$nalign,$des,$kwd,$kwdRd,$info,
	  @kwdDefStripTopLoc,@kwdDefStripHdrLoc,%ptr,$posIde,$posZ,$ct,$i,
	  @kwdStripTopLoc,@kwdStripHdrLoc,%LtakeLoc,$rdBeg,$rdEnd,$Ltake);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   hsspRdStripHeader           reads the header of a HSSP.strip file
#       in:                     fileStrip
#                               exclTxt="n1-n2", or "*-n2", or "n1,n3,...", or 'none|all'
#                               inclTxt="n1-n2", or "*-n2", or "n1,n3,...", or 'none|all'
#                               minimal Z-score; minimal and maximal seq ide
#         neutral:  'unk'       for all non-applicable variables!
#         @kwdInLoc             = one of the default keywords 
#                               (@kwdLocHsspTop,@kwdLocHsspHeader)
#       out:                    for top  (e.g. NALIGN): $rd{"kwd"}
#                               for prot (e.g. LALI):   $rd{"kwd","$it"}
#                               note: for the later number of elements (it) in
#                                     $rd{"NROWS"}
#                               $rd{"$des","$ct"} = column $des for pair no $ct
#                               $des=
#                                   IAL,VAL,LEN1,IDEL,NDEL,ZSCORE,IDE,STRHOM,LEN2,RMS,NAME
#                               -------------------------------
#                               ALTERNATIVE keywords for HEADER
#                               -------------------------------
#                               nali     -> alignments (number of alis)
#                               listName -> list name (alignment list)
#                               lastName -> last name was (last aligned id)
#                               sortMode -> sort-mode (ZSCORE/asf.)
#                               weight1  -> weights 1 (sequence weights for guide: (YES|NO))
#                               weight2  -> weights 2 (sequence weights for aligned: (YES|NO))
#                               smin     -> smin      (minimal value of scoring metric)
#                               smax     -> smax      (maximal value of scoring metric)
#                               gapOpen  -> gap_open  (gap open penalty)
#                               gapElon  -> gap_elongation  (gap elongation/extension penalty)
#                               indel1   -> INDEL in sec-struc of SEQ1 (YES|NO)
#                               indel2   -> INDEL in sec-struc of SEQ2 (YES|NO)
#--------------------------------------------------------------------------------
    $sbrName="lib-br:hsspRdStripHeader";$fhinLoc="FHIN"."$sbrName";
				# ------------------------------
				# defaults
    @kwdDefStripTopLoc=("test sequence","list name","last name was","seq_length",
			"alignments","sort-mode","weights 1","weights 1","smin","smax",
			"maplow","maphigh","epsilon","gamma",
			"gap_open","gap_elongation",
			"INDEL in sec-struc of SEQ 1","INDEL in sec-struc of SEQ 2",
			"NBEST alignments","secondary structure alignment");
    @kwdDefStripHdrLoc=("NR","VAL","LALI","IDEL","NDEL",
			"ZSCORE","IDE","STRHOM","LEN2","RMSD","SIGMA","NAME");
    $ptr{"IAL"}= 1;$ptr{"VAL"}= 2;$ptr{"LALI"}= 3;$ptr{"IDEL"}= 4;$ptr{"NDEL"}= 5;
    $ptr{"ZSCORE"}=6;$ptr{"IDE"}=7;$ptr{"STRHOM"}=8;
    $ptr{"LEN2"}=9;$ptr{"RMSD"}=10;$ptr{"SIGMA"}=11;$ptr{"NAME"}=12;
    $posIde=$ptr{"IDE"};$posZ=$ptr{"ZSCORE"};

    @kwdOutTop=("nali","listName","lastName","sortMode","weight1","weight2","smin","smax",
		"gapOpen","gapElon","indel1","indel2");

    %translateKwdStripTop=	# strip top
	('nali',"alignments",
	 'listName',"list name",'lastName',"last name was",'sortMode',"sort-mode",
	 'weight1',"weights 1",'weight2',"weights 2",'smin',"smin",'smax',"smax",
	 'gapOpen',"gap_open",'gapElon',"gap_elongation",
	 'indel1',"INDEL in sec-struc of SEQ 1",'indel2',"INDEL in sec-struc of SEQ 2");
	 
				# ------------------------------
				# check input arguments
    undef %addDes;
    $#kwdStripTopLoc=$#kwdStripHdrLoc=0;
    foreach $kwd (@kwdInStripLoc){
	$Lok=0;
	foreach $des (@kwdDefStripHdrLoc)   {
	    if ($kwd eq $des){ $Lok=1; push(@kwdStripHdrLoc,$kwd);
			       last;}}
	next if ($Lok);
	foreach $des (@kwdDefStripTopLoc){
	    if ($kwd eq $des){ $Lok=1; push(@kwdStripTopLoc,$kwd);
			       foreach $desOut(@kwdOutTop){
				   if ($kwd eq $translateKwdStripTop{"$desOut"}){
				       $addDes{"$des"}=$desOut;
				       last;}}
			       last;} }
	next if ($Lok);
	if (defined $translateKwdStripTop{"$kwd"}){
	    $addDes=$translateKwdStripTop{"$kwd"};
	    $Lok=1; push(@kwdStripTopLoc,$addDes);
	    $addDes{"$addDes"}=$kwd;}
	next if ($Lok);
	print "-*- WARNING $sbrName input kwd=$kwd, makes no sense??\n" 
	    if (! $Lok);}
    undef %LtakeLoc;		# logicals to decide what to read
    foreach $kwd (@kwdStripTopLoc){
	$LtakeLoc{$kwd}=1;}	# 
				# force reading of NALI
    if (! defined $LtakeLoc{"alignments"}){push(@kwdStripTopLoc,"alignments");
					   $LtakeLoc{"alignments"}=1;}

    $#excl=$#incl=0;		# set zero
				# --------------------------------------------------
				# now start to read
				# open file
    $Lok=       &open_file("$fhinLoc","$fileInLoc");
    if (! $Lok){print "*** ERROR $sbrName: '$fileInLoc' not opened\n";
		return(0);}
				# --------------------------------------------------
				# file type:
				# '==========  MAXHOM-STRIP  ==========='
    $_=<$fhinLoc>;		# first line
    if ($_!~/^[= ]+MAXHOM-STRIP[= ]+/){ # file recognised?
	print "*** ERROR ($sbrName) not maxhom.STRIP file! (?)\n";
	return(0);}
    undef %tmp;		# save space
				# --------------------------------------------------
    while (<$fhinLoc>) {	# read file TOP (global info)
				# stop if next key:
				# '============= SUMMARY ==============='
	last if ($_ =~/^[= ]+SUMMARY[= ]+/);
	$_=~s/\n//g;$_=~s/^\s*|\s*$//g;
	next if ($_ !~ /\:/);	# skip if ':' missing (=> error!)
	($kwdRd,$info)=split(/:/,$_);
	if ($kwdRd=~/seq_length/){
	    $len1=$info;$len1=~s/\D//g;}
	$kwdRd=~s/\s*$//g;	# purge blanks at end
	if ($LtakeLoc{$kwdRd}){	# want the info?
	    $info=~s/^\s*|\s*$//g;
	    $tmp{"$kwdRd"}=$info;
				# add short names for header
	    if (defined $addDes{"$kwdRd"}){
		$kwdRdAdd=$addDes{"$kwdRd"};
		$tmp{"$kwdRdAdd"}=$info;}
	    next;}}
    $nalign=$tmp{"alignments"};
				# ------------------------------
				# get range to be in/excluded
    if ($inclTxt ne "unk"){ @incl=&get_range($inclTxt,$nalign);} 
    if ($exclTxt ne "unk"){ @excl=&get_range($exclTxt,$nalign);} 
    $ct=0;			# --------------------------------------------------
    while (<$fhinLoc>) {	# read PAIR information
				# '=========== ALIGNMENTS =============='
	last if ($_ =~ /^[= ]+ALIGNMENTS[= ]+/);
	next if ($_ =~ /^\s*IAL\s+VAL/); # skip line with names
	$_=~s/\n//g; 
	next if (length($_)<5);	# another format error if occurring

	$rdBeg=substr($_,1,69);$rdBeg=~s/^\s*|\s*$//g;
	$rdEnd=substr($_,70);  $rdEnd=~s/^\s*|\s*$//g;
	$rdEnd=~s/(\s)\s*/$1/g; # 2 blank to 2

	@tmp=(split(/\s+/,$rdBeg),"$rdEnd");

	$pos=$tmp[1];		# ------------------------------
	$Ltake=1;		# exclude pair because of RANK?
	if ($#excl>0){foreach $i (@excl){if ($i eq $pos){$Ltake=0;
							 last;}}}
	if (($#incl>0)&&$Ltake){ 
	    $Ltake=0; foreach $i (@incl){if ($i eq $pos){$Ltake=1; 
							 last;}}}
	next if (! $Ltake);	# exclude
				# exclude because of identity?
	next if ((( $upIde ne "unk") && (100*$tmp[$posIde]>$upIde))||
		 (($lowIde ne "unk") && (100*$tmp[$posIde]<$lowIde)));
				# exclude because of zscore?
	next if ((  $minZ  ne "unk") && ($tmp[$posZ]<$minZ));

	++$ct;
#....,....1....,....2....,....3....,....4....,....5....,....6....,....7....,....8
# IAL    VAL   LEN IDEL NDEL  ZSCORE   %IDEN  STRHOM  LEN2   RMS SIGMA NAME

	$tmp{"LEN1","$ct"}=$len1;
	foreach $kwd (@kwdStripHdrLoc){
	    $pos=$ptr{"$kwd"};
	    if (($pos>$#tmp)||($pos<1)){
		print "*** ERROR in $sbrName ct=$ct, kwd=$kwd, pos should be $pos\n";
		print "***          however \@tmp not defined for that\n";
		return(0);}
	    if ($kwd eq "IDE"){$tmp=100*$tmp[$pos];}else{$tmp=$tmp[$pos];}
	    $tmp{"$kwd","$ct"}=$tmp;}
    } close($fhinLoc);
    $tmp{"NROWS"}=$ct;
				# clean up
    undef @kwdInLoc;undef @kwdDefStripTopLoc;undef @kwdDefStripHdrLoc;undef %ptr; 
    undef @kwdStripTopLoc; undef @kwdStripHdrLoc; undef %LtakeLoc;
    
    return (%tmp);
}				# end of hsspRdStripHeader

#===============================================================================
sub hsspSkewProf {
    local($fileInLoc,$chainInLoc,$fileOutLoc,$fileMatdbLoc,$naliSatLoc,$distLoc,$distMode) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspSkewProf                changes the HSSP profile for too few alignments
#       in:                     $fileInLoc    : HSSP file (chain ignored!)
#       in:                     $chainInLoc   : chain to read
#                                   '*' for omitting the test
#       in:                     $fileOutLoc   : HSSP file with skewed profiles to write
#       in:                     $fileMatdbLoc : RDB file with substitution matrix to skew
#       in:                     $naliSatLoc   : number of alignments when no db taken
#       in:                     $distLoc      : limiting distance from HSSP (new Ide)
#                                   '0' in NEXT variable for omitting the test
#       in:                     $distModeLoc  : mode of limit ('gt|ge|lt|le')
#                                              -> if mode=gt, all with dist>distLoc
#                                                 will be counted
#                                   '0' for omitting the test
#       out:                    1|0,msg,  implicit: file
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."hsspSkewProf"; 
    $fhinLoc="FHIN_"."hsspSkewProf"; $fhoutLoc="FHOUT_"."hsspSkewProf";
				# ------------------------------
				# check arguments
    return(&errSbr("not def fileInLoc!"))             if (! defined $fileInLoc);
    return(&errSbr("not def chainInLoc!"))            if (! defined $chainInLoc);
    return(&errSbr("not def fileOutLoc!"))            if (! defined $fileOutLoc);
    return(&errSbr("not def fileMatdbLoc!"))          if (! defined $fileMatdbLoc);
    return(&errSbr("not def naliSatLoc!"))           if (! defined $naliSatLoc);
    return(&errSbr("not def distLoc!"))               if (! defined $distLoc);
    return(&errSbr("not def distMode!"))              if (! defined $distMode);
#    return(&errSbr("not def !"))            if (! defined $);

    return(&errSbr("miss in file '$fileInLoc'!"))     if (! -e $fileInLoc);
    return(&errSbr("miss in file '$fileMatdbLoc'!"))  if (! -e $fileMatdbLoc);
    $errMsg="*** ERROR $sbrName in local: f=$fileInLoc, c=$chainInLoc, fileout=$fileOutLoc,".
	"fileMat=$fileMatdbLoc, dist=$distLoc, mode=$distMode\n";

    @aaLoc= split(//,"VLIMFWYGAPSTCHRKQEND"); # note: IS HSSP succession
    undef %aaLoc;
    foreach $tmp (@aaLoc){
	$aaLoc{"$tmp"}=1; }	# logical array of all known amino acids

				# ------------------------------
				# read substitution matrix
    if (! defined %matdb) {	# (only if not defined to save time)
	($Lok,$msg,%matdb)=
	    &metricRdbRd($fileMatdbLoc);
	                        return(&errSbrMsg("skew prof failed reading metri".
						  $errMsg,$msg)) if (! $Lok); 
	foreach $aa1 (@aaLoc){	# dissect into lists ( $prof{R}='R->V,R->L,R->I,...,R->D' )
	    $tmp=""; 
	    foreach $aa2 (@aaLoc){ 
		$tmp.=$matdb{"$aa1","$aa2"}.","; }
	    $profTmp{"$aa1"}=$tmp; } }

				# ------------------------------
    ($Lok,$msg,$nali,$tmp)=	# find number of alis in HSSP header
	&hsspGetChainNali($fileInLoc,$chainInLoc,$distLoc,$distMode);
                                return(&errSbrMsg("failed on hsspGetChainNali".
						  $errMsg,$msg)) if (! $Lok);
				# ------------------------------
				# simple copy if saturation
    if ($nali >= $naliSatLoc) {
	($Lok,$msg)=
	    &sysCpfile($fileInLoc,$fileOutLoc);
	                        return(&errSbrMsg("failed system 'cp $fileInLoc $fileOutLoc'".
						  $errMsg,$msg)) if (! $Lok);
				 # ******************************
	return(1,"ok $sbrName"); # DONE
    }				 # ******************************

				# --------------------------------------------------
				# read and write
				# --------------------------------------------------
				# open file (old)
    &open_file("$fhinLoc","$fileInLoc")    || return(&errSbr("fileInLoc=$fileInLoc, not opened"));
				# open file (new)
    &open_file("$fhoutLoc",">$fileOutLoc") || return(&errSbr("fileOut=$fileOutLoc, not created"));
	
    $LrdAli=$LrdFin=0; $seq="";
				# ------------------------------
    while (<$fhinLoc>) {	# all before prof: no change
	print $fhoutLoc $_; $rd=$_;
	last if ($_ =~ /^\#\# SEQUENCE PROFILE AND ENTROPY/); 
				# the following to read sequence
	if (! $LrdAli && ($_=~/^\#\# ALI/) ) {
	    $LrdAli=1;		# start of 1st ali section
	    next; }
	if ($LrdAli   && ($_=~/^\#\# ALI/) ) {
	    $LrdFin=1;
	    next; }
	next if (! $LrdAli);	# not started, yet
	next if ($LrdAli && $LrdFin); # finished sequence
	next if ($LrdAli && $_=~/^ Seq/); # skip 
	$seqRd=substr($rd,15,1);
	$seqRd=~s/[a-z]/C/;	# cysteins
	$seq.=$seqRd; 
    }
    @seq=split(//,$seq);	# HSSP sequence

    $ctres=0;			# ------------------------------
    while (<$fhinLoc>) {	# PROFILE => change
	$rd=$_;
	if ($_=~/^(\/|\#)/){	# FINAL
	    print $fhoutLoc $rd;
	    last; }
	if ($_=~/^ SeqNo/) {	# NAMES 
	    print $fhoutLoc $rd;
	    next; }
	++$ctres;		# count residues
	$res=$seq[$ctres];
				# aa = unk: take prof read
	if (! defined $aaLoc{"$res"}){ 
	    print $fhoutLoc $rd; 
	    next; }
				# --------------------
	$rd=~s/\n//g;		# profiles
	$begLine=substr($rd,1, 12);
	$midLine=substr($rd,13,80); $midLine=~s/^\s*|\s*$//g; # purge leading blanks
	$endLine=substr($rd,93);    
	@tmpLine=split(/\s+/,$midLine);
	$prof=join(',',@tmpLine[1..20]);

	($Lok,$msg,$profNew)=
	    &funcAddMatdb2prof($prof,$profTmp{"$res"},$nali,$naliSatLoc);
	                        return(&errSbrMsg("failed on new prof ($prof,".$profTmp{"$res"}
						  .") nali=$nali, sat=$naliSatLoc".
						  $errMsg,$msg)) if (! $Lok);
	$new=      sprintf("%-s",$begLine);
	foreach $tmp (split(/,/,$profNew)) {
	    $new.= sprintf("%4d",int($tmp)); }
	$new.=     sprintf("%-s\n",$endLine);
	print $fhoutLoc $new;
    }
				# ------------------------------
    while (<$fhinLoc>) {	# all after prof (ins): no change
	print $fhoutLoc $; }
    close($fhinLoc);close($fhoutLoc);

				# ------------------------------
				# slim-is-in !
    undef %tmp; undef @tmp;
    return(1,"ok $sbrName");
}				# end of hsspSkewProf

#===============================================================================
sub interpretSeqCol {
    local ($fileOutLoc,$fileOutGuideLoc,$nameFileIn,$Levalsec,$fhErrSbr,@seqIn) = @_ ;
    local ($sbrName,$Lok,$msg,$tmp,@tmp,$fhout,$fhout2,$LfirstLine,$Lhead,$ct,$ctok,
	   $it,$des,$Lptr,$Lguide,$seqGuide,$nameGuide,@des_column_format,@des_evalsec,
	   $sec,$acc,$itx,%rd,%ptrkey2,%ptr2rd);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   interpretSeqCol             extracts the column input format and writes it
#       in:                     $fileOutLoc,$fileOutGuideLoc,$nameFileIn,$Levalsec,
#       in:                     $fhErrSbr,@seqIn
#       out:                    either write for EVALSEC or DSSP format and guide in FASTA
#       in/out GLOBAL:          @NUM,@SEQ,@SEC(HE ),@ACC,@RISEC,@RIACC (for wrt_dssp_phd)
#       err:                    e: (1,msg) -> ok
#       err:                    a: (0,msg) -> some arguments missing/files not opened
#       err:                    b: (2,msg) -> ERROR while writing output
#       err:                    c: (3,msg) -> guide sequence not written
#--------------------------------------------------------------------------------
    $sbrName="interpretSeqCol";
    return(0,"*** $sbrName: not def fileOutLoc!") if (! defined $fileOutLoc);
    return(0,"*** $sbrName: not def fileOutGuideLoc!") if (! defined $fileOutGuideLoc);
    return(0,"*** $sbrName: not def nameFileIn!") if (! defined $nameFileIn);
    return(0,"*** $sbrName: not def Levalsec!")   if (! defined $Levalsec);
    return(0,"*** $sbrName: not def fhErrSbr!")   if (! defined $fhErrSbr);
    return(0,"*** $sbrName: not def seqIn[1]!")   if (! defined $seqIn[1]);
				# desired column names for COLUMN format (make non-local)
#    @des_column_all=("AA","PHEL","OHEL","RI_S","OTH","OTE","OTL","PACC","PREL","RI_A","PBIE",
#		     "OT0","OT1","OT2","OT3","OT4","OT5","OT6","OT7","OT8","OT9","NAME");

    @des_column_format=("AA","PHEL","RI_S","PACC","RI_A","OHEL","NAME");
    @des_evalsec=      ("NAME","AA","PHEL","OHEL");
    %ptrkey2=('AA',   "AA",     'NAME', "NAME",
	      'PHEL', "PSEC",   'OHEL', "OSEC",   'PACC', "PACC", 
	      'RI_S', "RI_SEC", 'RI_A', "RI_ACC");
    $fhout="FHOUT_".$sbrName;$fhout2="FHOUT2_".$sbrName;
    $ct=0;			# initialise arrays asf
    $#SEQ=$#SEC=$#ACC=$#RISEC=$#RIACC=$#OSEC=$#NAME=0; # GLOBAL for wrt_dssp_phd
                                # ----------------------------------------
                                # continue reading open file
                                # ----------------------------------------
    foreach $_(@seqIn){
	next if (/^\#/);	# ignore second hash, br: 10-9-96
	next if (length($_)==0);
	$tmp=$_;$tmp=~s/\n//g;
	$tmp=~tr/[a-z]/[A-Z]/;	# lower to upper
	++$ct;
	last if ($_ !~/[\s\t]*\d+/ && $ct>1);
	$tmp=~s/^[ ,\t]*|[ ,\t]*$//g; # purge leading blanks begin and end
	$#tmp=0;@tmp=split(/[\s\t,]+/,$tmp); # split spaces, tabs, or commata
	if ($ct==1){		# first line: check identifiers passed
	    undef %ptr2rd;$ctok=$Lok=0;
	    foreach $des (@des_column_format){
		foreach $it (1..$#tmp) {
		    if ($des eq $tmp[$it]) {
			++$ctok;$Lok=1;$ptr2rd{"$des"}=$it; 
			last; }
				# alternative key?
		    elsif ((defined $ptrkey2{"$des"})&&($ptrkey2{"$des"} eq $tmp[$it])) {
			++$ctok;$Lok=1;$ptr2rd{"$des"}=$it; 
			last; } }
		if (! $Lok) {
		    if ($des=~/AA|PHEL|PACC/){$ctok=0;
					      last;}
		    print $fhErrSbr
			"*** $sbrName ERROR: names in columns, des=$des, not found\n";} }
	    $Lptr=1 if ($ctok>=3);} # at least 3 found?
	elsif($ct>1) {		# for all others read
	    if (! $Lptr){	# stop if no amino acid
		print $fhErrSbr "*** $sbrName ERROR: not Lptr error? (30.6.95) \n";
		next;}
	    if(defined $ptr2rd{"AA"})  {$tmp=$tmp[$ptr2rd{"AA"}];
					if ($tmp !~ /[ABCDEFGHIKLMNPQRSTUVWXYZ\.\- ]/){
					    $Lptr=0;
					    last;}
					push(@SEQ,  $tmp[$ptr2rd{"AA"}]);}
	    if(defined $ptr2rd{"PHEL"}){push(@SEC,  $tmp[$ptr2rd{"PHEL"}]);}
	    if(defined $ptr2rd{"PACC"}){push(@ACC,  $tmp[$ptr2rd{"PACC"}]);}
	    if(defined $ptr2rd{"OHEL"}){push(@OSEC, $tmp[$ptr2rd{"OHEL"}]);}
	    if(defined $ptr2rd{"RI_S"}){push(@RISEC,$tmp[$ptr2rd{"RI_S"}]);}
	    if(defined $ptr2rd{"RI_A"}){push(@RIACC,$tmp[$ptr2rd{"RI_A"}]);}
	    if(defined $ptr2rd{"NAME"}){push(@NAME, $tmp[$ptr2rd{"NAME"}]);}}}
                                # ----------------------------------------
				# error checks
                                # ----------------------------------------
    $Lok=1;
    foreach $sec(@SEC){
	if ($sec=~/[^HEL \.]/){
	$Lok=0;			# wrong secondary structure symbol
	$msg="wrong secStr: allowed H,E,L ($sec)";print $fhErrSbr "*** $sbrName ERROR: $msg\n";
	last;}}
    if ($Lok && ($#ACC>0)){foreach $acc(@ACC){if (($acc=~/[^0-9]/) || (int($acc)>500) ){
	$Lok=0;		# wrong values for accessibility
	$msg="wrong acc: allowed 0-500 ($acc)";print $fhErrSbr "*** $sbrName ERROR: $msg\n";
	last;}}}
    if ($Lok && ($#SEQ<1)){
	$Lok=0;			# not enough sequences
	$msg="sequence array empty";print $fhErrSbr "*** $sbrName ERROR: $msg\n";}
    if ($Lok && ( $Levalsec && ($#OSEC<1))){
	$Lok=0;			# EVALSEC: must have observed sec str
	$msg="for EVALSEC OSEC must be defined\n";print $fhErrSbr "*** $sbrName ERROR: $msg\n";}
				# ******************************
				# error: read/write col format
    return(0,"*** $sbrName ERROR $msg") if (!$Lok);
				# ******************************

                                # ----------------------------------------
				# write output file
                                # ----------------------------------------
				# added br may 96, as noname crushed!
    $itx=0;			# to avoid warnings
    if ($#NAME==0){foreach $itx(1..$#SEC){push(@NAME,"unk");}}
				# open file
    open("$fhout",">$fileOutLoc")  || 
	return(0,"*** $sbrName cannot open fileOutLoc=$fileOutLoc\n");
				# ------------------------------
    if ($Levalsec){		# write PP2dotpred format 
	undef %rd;
	$rd{"des"}="";		# convert to global
	foreach $des(@des_evalsec){
	    $rd{"des"}.="$des"."  ";
	    if   ($des=~/AA/)  {foreach $it(1..$#SEQ){$rd{"$des","$it"}=$SEQ[$it];}}
	    elsif($des=~/PHEL/){foreach $it(1..$#SEC){$rd{"$des","$it"}=$SEC[$it];}}
	    elsif($des=~/OHEL/){foreach $it(1..$#OSEC){$rd{"$des","$it"}=$OSEC[$it];}}
	    elsif($des=~/NAME/){foreach $it(1..$#NAME){$rd{"$des","$it"}=$NAME[$it];} }}
	($Lok,$msg)=
	    &wrt_ppcol("$fhout",%rd); }
				# ------------------------------
    else {			# write DSSP file
	foreach $it (1..$#SEQ){push(@NUM,$it);}	# convert to global
	$Lok=
	    &wrt_dssp_phd("$fhout",$nameFileIn);}
    close("$fhout");
				# ------------------------------
				# file existing??
    return(2,"*** $sbrName ERROR after write, missing fileOutLoc=$fileOutLoc\n")
	if (! -e $fileOutLoc);
				# ******************************
				# error: read/write col format
    return(2,"*** $sbrName internal error while writing fileOutLoc=$fileOutLoc\n")
	if (! $Lok);
				# ------------------------------
				# write guide sequence in FASTA
    if (! $Levalsec){
	if (defined $NAME[1]){$nameGuide=$NAME[1];}
	else {$nameGuide=$fileOutGuideLoc;$nameGuide=~s/^.*\/|\..*$//g;}
	$seqGuide="";foreach $tmp(@seq){$seqGuide.="$tmp";}
	$seqGuide=~s/[^ABCDEFGHIKLMNPQRSTVWXYZ]//g; # delete non amino acid characters!
	($Lok,$msg)=
	    &fastaWrt($fileOutGuideLoc,$nameGuide,$seqGuide);
	return(3,"*** $sbrName cannot write fasta of guide\n".
	       "*** fileout=$fileOutGuideLoc, id=$nameGuide, seq=$seqGuide\n".
	       "*** ERROR message: $msg\n") if (! $Lok || ! -e $fileOutGuideLoc);}
				# ------------------------------
    undef %rd; $#seqIn=0;	# save space
    $#SEQ=$#SEC=$#ACC=$#RISEC=$#RIACC=$#OSEC=$#NAME=0;
    $seqGuide="";		# save space

    return(1,"$sbrName ok");
}				# end of interpretSeqCol

#===============================================================================
sub interpretSeqFastalist {
    local ($fileOutLocGuide,$fileOutLocOther,$lenMinLoc,$fhErrSbr,@seqIn)=@_;
    local (@seq,$ct,$ctprot,$fhout_guide,$fhout_other,$sbrName,$name,@name,%seq,%name);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   interpretSeqFastalist       extracts the Fasta list input format
#       in:                     $fileOutLocGuide,$fileOutLocOther,$lenMinLoc,$fhErrSbr,@seqIn
#       out:                    writes 2 Fasta files for guide and to-be-aligned
#       err:                    a: (0,msg) -> some arguments missing/files not opened
#       err:                    b: (2,msg) -> wrong format 
#       err:                    c: (3,msg) -> too few alis 
#       err:                    d: (4,msg) -> seq too short
#       err:                    e: (1,msg) -> ok
#--------------------------------------------------------------------------------
    $sbrName="interpretSeqFastalist";
    return(0,"*** $sbrName: not def fileOutLocGuide!") if (! defined $fileOutLocGuide);
    return(0,"*** $sbrName: not def fileOutLocOther!") if (! defined $fileOutLocOther);
    return(0,"*** $sbrName: not def fhErrSbr!")        if (! defined $fhErrSbr);
    return(0,"*** $sbrName: not def lenMinLoc!")       if (! defined $lenMinLoc);
    return(0,"*** $sbrName: not def seqIn[1]!")        if (! defined $seqIn[1]);

    $fhout_guide="FILEFASTALIST_GUIDE";
    $fhout_other="FILEFASTALIST_OTHER";
    $ct=$#name=0; undef %seq; undef %name;
				# --------------------------------------------------
    while(@seqIn) {		# first: check format by correctness of first tag '>'
	$_ = shift @seqIn;
	next if ($_=~/^\#/);	# ignore second hash, br: 10-9-96
	next if ($_!~/^\s*\>/);	# search first '>' = guide sequence
	$_=~s/\n//g;
	$_=~s/^\s*\>\s*//g;$_=~s/\s*$//g; # purge blanks asf
	$_=~s/\s|\./_/g;	# blanks, dots to '_'
	$_=~s/^\_|\_$//g;	# purge off leading '_'
	$_=~s/^.*\|//g;		# purge all before first '|'
	$_=~s/,.*$//g;		# purge all after comma
	$name=substr($_,1,15);	# shorten
	$name=~s/__/_/g;	# '__' -> '_'
	$name=~s/,//g;		# purge comma
	last;}
    return(2,"*** $sbrName ERROR no tag '>' found\n") if (length($name)<2 || ! defined $name);

    $name{"$name"}=1;push(@name,$name);$seq{"$name"}=""; # for guide sequence
    $ctprot=0;			# --------------------------------------------------
    while(@seqIn) {		# now extract the guide sequence, and all others
	$_ = shift @seqIn;$_=~s/\n//g;
				# ------------------------------
	if ($_=~/^\s*\>/ ) {	# name
	    ++$ctprot;$ct=1;$#seq=0;
	    $_=~s/^\s*\>\s*//g;$_=~s/\s*$//g; # purge blanks asf
	    $_=~s/\s|\./_/g;	# blanks, dots to '_'
	    $_=~s/^\_|\_$//g;	# purge off leading '_'
	    $_=~s/^.*\|//g;	# purge all before first '|'
	    $_=~s/,.*$//g;	# purge all after comma
	    $name=substr($_,1,14); # shorten
	    $name=~s/__/_/g;	# '__' -> '_'
	    $name=~s/,//g;	# purge comma
	    if (defined $name{"$name"}){
		$ctTmp=1;$name=substr($name,1,13); # shorten further
		while(defined $name{"$name"."$ctTmp"}){
		    $name=substr($name,1,12) if ($ctTmp==9);
		    ++$ctTmp;}
		$name.=$ctTmp;}
	    $name{"$name"}=1;
	    $name.=$tmp."_$ctprot" if (length($name)<5);
	    $seq{"$name"}="";push(@name,$name);}
				# ------------------------------
	else {			# sequence
	    $_=~s/^[\d\s]*(.)/$1/g; # purge leading blanks/numbers
	    $_=~s/\s//g;	# purge all blanks
	    $_=~tr/a-z/A-Z/;	# upper case
	    if (! /[^ABCDEFGHIKLMNPQRSTVWXYZ]/) {
		$seq{"$name"}.=$_ . "\n";}}
    }				# end of loop over input array
				# --------------------------------------------------
				# print new file in FASTA format
				# ------------------------------
				# guide sequence in FASTA format
    open("$fhout_guide",">$fileOutLocGuide") ||
	return(0,"*** $sbrName cannot open new fileOutLocGuide=$fileOutLocGuide\n");
    print $fhout_guide ">$name[1]\n".$seq{"$name[1]"}."\n" ;
    close($fhout_guide);
				# ------------------------------
				# others in FASTA format (as list)
#********************************************************************************x.1
#   set to 1, 2 ... if you want to allow alignments with at least 2, 3, .. sequences
#********************************************************************************x.1
    if ( $#name < 1) {		# too few alis
	return(3,"*** ERROR $sbrName wrong format in seq to pir list (too few alis)!\n");}
    if ( length($seq{"$name[1]"}) <= $lenMinLoc) { # seq too short
	$len=length($seq{"$name[1]"});
	return(4,"*** ERROR $sbrName len=$len, i.e. too few residues in $name[1]!\n");}

    open("$fhout_other",">$fileOutLocOther") ||
	return(0,"*** ERROR $sbrName cannot open new fileOutLocOther=$fileOutLocOther\n");
    foreach $it (1..$#name){
	print $fhout_other ">$name[$it]\n",$seq{"$name[$it]"};
	print $fhout_other "\n" if ($seq{"$name[$it]"} !~/\n$/);}
    close($fhout_other);
    return(1,"$sbrName ok");
}				# end of interpretSeqFastalist

#===============================================================================
sub interpretSeqMsf {
    local ($fileOutLoc,$fileOutGuideLoc,$fhErrSbr,@seqIn) = @_ ;
    local ($sbrName,$Lok,$msg,$tmp,$fhout,$LfirstLine,$Lhead,
	   $Lguide,$seqGuide,$nameGuide);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   interpretSeqMsf             extracts the MSF input format
#       in:                     $fileOutLoc,$fileOutGuideLoc,$fhErrSbr,@seqIn
#       out:                    write alignment in MSF format and guide seq in FASTA
#       err:                    e: (1,msg) -> ok
#       err:                    a: (0,msg) -> some arguments missing/files not opened
#       err:                    b: (2,msg) -> chechMsfFormat returned ERROR
#       err:                    c: (3,msg) -> guide sequence not written
#--------------------------------------------------------------------------------
    $sbrName="interpretSeqMsf";
    return(0,"*** $sbrName: not def fileOutLoc!")      if (! defined $fileOutLoc);
    return(0,"*** $sbrName: not def fileOutGuideLoc!") if (! defined $fileOutGuideLoc);
    return(0,"*** $sbrName: not def fhErrSbr!")        if (! defined $fhErrSbr);
    return(0,"*** $sbrName: not def seqIn[1]!")        if (! defined $seqIn[1]);
				# open output files
    $fhout="FHOUT_".$sbrName;
    open("$fhout",">$fileOutLoc")  || 
	return(0,"*** $sbrName cannot open new fileOutLoc=$fileOutLoc\n");
    $Lhead=1;
    $LfirstLine=0;		# hack 2-98: add first line 'MSF of: xyz from: 1 to: 600'
    $Lguide=0;$seqGuide="";	# for extracting guide sequence

    $ctName=$LisAli=0;		# hack 98-05 to prevent only one protein
				# goebel= error if only one in MSF!!
				# ------------------------------
    foreach $_(@seqIn){		# write MSF
				# yet another hack around Goebel, 9-95, br
	next if ($_=~/^\#/);	# ignore second hash, br: 10-9-96
				# allow for 'PileUp' asf before first line
	if ($_=~/\s*MSF.*\:.*heck|\s*MSF\s*of\s*\:/){
	    $Lhead=0;}
	next if ($Lhead);	# skip all before line with 'MSF .*:'
	if    ($_=~/\sMSF\s*of\s*\:\s*.*from\s*\:\s*\d/){
	    $LfirstLine=1;}
	elsif (($_=~/\s+MSF\s*\:\s*(\d+).*[cC]heck\:/)&&! $LfirstLine){
	    $_="MSF of: yyy from: 1 to: $1\n".$_;}
	$tmp=$_;
	$tmp=~tr/[A-Z]/[a-z]/;	# and another (\t -> '  ') ; 3-96 br
	$tmp=~s/\t/   /g;	# tab to '   '
	if ($tmp=~ /name\:/){
	    $tmp=~s/name\:/Name\:/;$tmp=~s/len\:/Len\:/;$tmp=~s/check\:/Check\:/;
	    ++$ctName;		# hack 98-05
				# only to extract guide sequence
	    if (!$Lguide){$nameGuide=$tmp;$nameGuide=~s/\s*Name\:\s*(\S+)\s.*$/$1/g;
			  $Lguide=1;}
	    $nameRemember=$tmp;$nameRemember=~s/$nameGuide/117REPEAT/;
	    $_=$tmp;}
	$_=~s/[~-]/\./g;	# '~' and '-' to '.' for insertions
	last if ($_=~/^[^a-zA-Z0-9\.\*\_\- \n\b\\\/]/);
				# hack 98-05: if only one repeat!!
	if    ($_=~/\/\// && $ctName==1){ # now repeat name
	    print $fhout "$nameRemember\n";}
	elsif ($LisAli && $ctName==1){ # now repeat sequence part
	    $tmp2=$_;$tmp2=~s/$nameGuide/117REPEAT/i;
	    print $fhout "$tmp2\n";}
				# end hack 98-05: if only one repeat!!

	print $fhout "$_\n";  
	print $fhout " \n" if ($LisAli && $ctName==1); # hack 98-05 security additional column

	$LisAli=1 if ($_=~/\/\//); # for hack 98-05: if only one repeat!!

				# only to extract guide sequence
	next if (! $Lguide || $_=~/name|\/\//i || $_!~/^\s*$nameGuide/i);
	$_=~s/$nameGuide//ig;$_=~s/\s//g;$seqGuide.="$_";
    }
    print $fhout "\n";
    close("$fhout");
    $#seqIn=0;			# save space
				# ------------------------------
    return(0,"*** $sbrName ERROR after write, missing fileOutLoc=$fileOutLoc\n") 
	if (! -e $fileOutLoc);	# file existing??
				# ------------------------------
				# make a basic test of msf format
    ($Lok,$msg)=
	&msfCheckFormat($fileOutLoc);
    return(2,"$msg"."*** $sbrName ERROR from msfCheckFormat fileOutLoc=$fileOutLoc\n") 
	if (! $Lok);
				# ------------------------------
				# write guide sequence in FASTA
    $seqGuide=~s/[^ABCDEFGHIKLMNPQRSTVWXYZ]//g; # delete non amino acid characters!
    ($Lok,$msg)=
	&fastaWrt($fileOutGuideLoc,$nameGuide,$seqGuide);
    $seqGuide="";		# save space
    
    return(3,"*** $sbrName cannot write fasta of guide\n".
	   "*** fileout=$fileOutGuideLoc, id=$nameGuide, seq=$seqGuide\n".
	   "*** ERROR message: $msg\n") if (! $Lok || (! -e $fileOutGuideLoc));
    return(1,"$sbrName ok");
}				# end of interpretSeqMsf

#===============================================================================
sub interpretSeqPirlist {
    local ($fileOutLocGuide,$fileOutLocOther,$lenMinLoc,$fhErrSbr,@seqIn)=@_;
    local (@seq,$ct,$ctprot,$fhout_guide,$fhout_other,$sbrName,$name,@name,%seq,%name);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   interpretSeqPirlist         extracts the PIR list input format
#       in:                     $fileOutLocGuide,$fileOutLocOther,$lenMinLoc,$fhErrSbr,@seqIn
#       out:                    writes 2 PIR files for guide and to-be-aligned
#       err:                    a: (0,msg) -> some arguments missing/files not opened
#       err:                    b: (2,msg) -> wrong format 
#       err:                    c: (3,msg) -> too few alis 
#       err:                    d: (4,msg) -> seq too short
#       err:                    e: (1,msg) -> ok
#--------------------------------------------------------------------------------
    $sbrName="interpretSeqPirlist";
    return(0,"*** $sbrName: not def fileOutLocGuide!") if (! defined $fileOutLocGuide);
    return(0,"*** $sbrName: not def fileOutLocOther!") if (! defined $fileOutLocOther);
    return(0,"*** $sbrName: not def fhErrSbr!")        if (! defined $fhErrSbr);
    return(0,"*** $sbrName: not def lenMinLoc!")       if (! defined $lenMinLoc);
    return(0,"*** $sbrName: not def seqIn[1]!")        if (! defined $seqIn[1]);

    $fhout_guide="FILEPIRLIST_GUIDE";
    $fhout_other="FILEPIRLIST_OTHER";
    $ct=$#name=0; undef %seq; undef %name;
				# --------------------------------------------------
    while (@seqIn){		# first: check format by correctness of first tag 'P1;'
	$_ = shift @seqIn;
	next if ($_=~/^\#/);	# ignore second hash, br: 10-9-96
	$_=~s/\n//g;$_=~tr/a-z/A-Z/; # upper case
	return(2,"*** $sbrName ERROR first tag not '>P1\;' but ($_)\n") 
	    if ($_!~ /P.?\;/ ); # wrong format
	$_=~ s/\>.*P.*\;//;
	return(2,"*** $sbrName ERROR first tag not '>P1\;' but ($_)\n") 
	    if ($_=~/\S/ );	# wrong format
	last;}
    
    $ct=1;$ctprot=0;		# --------------------------------------------------
    while(@seqIn) {		# now extract the guide sequence, and all others
	$_ = shift @seqIn;$_=~s/\n//g;
	if ($_=~/\>.*P1.*\;|\>.*p1.*\;/ ) {
	    ++$ctprot;$ct=1; $#seq=0;
	    next;}
	++$ct;
	if  ($ct==2) {		# 2nd: name (1st = tag, ignored here)
	    $_=~s/\s+/_/g;	# replace spaces by '_'
	    $_=~s/^\_|\_$//g;	# purge off leading blanks
	    $tmp=substr($_,1,15); # extr first 15
	    $name="$tmp";
	    if (defined $name{"$name"}){
		$ctTmp=1;
		while(defined $name{"$name"."$ctTmp"}){
		    ++$ctTmp;}
		$name.=$ctTmp;}
	    $name{"$name"}=1;
	    if (length($name)<5){
		$name.=$tmp."_$ctprot"; }
	    $seq{"$name"}="";push(@name,$name);}
	elsif ($ct> 2){
	    $_=~s/^\s(.)/$1/g;
	    $_=~s/\s//g;	# purge blanks
	    $_=~tr/a-z/A-Z/;	# upper case
	    if (! /[^ABCDEFGHIKLMNPQRSTVWXYZ]/) {
		$seq{"$name"}.=$_ . "\n";} }
    }				# end of loop over input array
				# --------------------------------------------------
				# print new file in FASTA format
				# ------------------------------
				# guide sequence in FASTA format
    open("$fhout_guide",">$fileOutLocGuide") ||
	return(0,"*** $sbrName cannot open new fileOutLocGuide=$fileOutLocGuide\n");
    print $fhout_guide ">$name[1]\n".$seq{"$name[1]"}."\n" ;
    close($fhout_guide);
				# ------------------------------
				# others in FASTA format (as list)
#********************************************************************************x.1
#   set to 1, 2 ... if you want to allow alignments with at least 2, 3, .. sequences
#********************************************************************************x.1
    if ( $#name < 1) {		# too few alis
	return(3,"*** ERROR $sbrName wrong format in seq to pir list (too few alis)!\n");}
    if ( length($seq{"$name[1]"}) <= $lenMinLoc) { # seq too short
	$len=length($seq{"$name[1]"});
	return(4,"*** ERROR $sbrName len=$len, i.e. too few residues in $name[1]!\n");}

    open("$fhout_other",">$fileOutLocOther") ||
	return(0,"*** ERROR $sbrName cannot open new fileOutLocOther=$fileOutLocOther\n");
    foreach $it (1..$#name){
	print $fhout_other ">$name[$it]\n",$seq{"$name[$it]"};
	print $fhout_other "\n" if ($seq{"$name[$it]"} !~/\n$/);}
    close($fhout_other);
    return(1,"$sbrName ok");
}				# end of interpretSeqPirlist

#===============================================================================
sub interpretSeqPP {
    local($fileOutLoc,$nameLoc,$charPerLine,$lenMinLoc,$lenMaxLoc,$geneLoc,@seqIn) = @_ ;
    local($sbrName,$seq,$len,$ct);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   interpretSeqPP              suppose it is old PP format: write sequenc file
#       in:                     $fileOutLoc,$nameLoc,$charPerLine,
#       in:                     $lenMinLoc,$lenMaxLoc,$geneLoc,@seqIn
#       out:                    err:   0,msg
#       out:                    short: 2,msg
#       out:                    long:  3,msg
#       out:                    gene:  4,msg
#       out:                    ok:    1,ok
#-------------------------------------------------------------------------------
    $sbrName="interpretSeqPP";
    return(0,"*** $sbrName: not def fileOutLoc!")  if (! defined $fileOutLoc);
    return(0,"*** $sbrName: not def nameLoc!")     if (! defined $nameLoc);
    return(0,"*** $sbrName: not def lenMinLoc!")   if (! defined $lenMinLoc);
    return(0,"*** $sbrName: not def lenMaxLoc!")   if (! defined $lenMaxLoc);
    return(0,"*** $sbrName: not def geneLoc!")     if (! defined $geneLoc);
    return(0,"*** $sbrName: not def charPerLine!") if (! defined $charPerLine);
    return(0,"*** $sbrName: not def seqIn[1]!")    if (! defined $seqIn[1]) ;
				# ------------------------------
				# read sequence
    $seq="";$Lswiss=0;
    foreach $_ (@seqIn){
				# allow for SWISS-PROT files
	if ($_=~/^ID\s+[A-Z0-9]+_/){ # recognise SWISS-PROT by 'ID  PAHO_CHICK' in 1st line
	    $Lswiss=1;$Lread=0;
	    next;}
	elsif ($Lswiss && ($_=~/^SQ\s+/)){
	    $Lread=1;		# start reading after line 'SQ  SEQUENCE'
	    next;}
	next if ($Lswiss && (! $Lread));
				# ------------------------------
				# normal sequence now?
	$_=~ tr/a-z/A-Z/;	# lower case -> upper
	$_=~ s/^[\s\d]+//g;	# purge numbers and leading blanks
	$_=~ s/[\s]//g;		# purge off blanks *!*
	$_=~ s/[\.]//g;		# purge dots (may be insertions)
	$_=~ s/\*$|^\*//g;	# purge leading / ending star
	last if ( /[^ABCDEFGHIKLMNPQRSTVWXYZ]/ );
	$seq.= $_; }
    $len=length($seq);
				# ******************************
    if ($len < $lenMinLoc ) {	# exit : too short
	return(2,"*** $sbrName ERROR: too short  len=$len, min=$lenMinLoc");}
				# ******************************
    if ($len > $lenMaxLoc ) {	# exit : too long
	return(3,"*** $sbrName ERROR: too long   len=$len, min=$lenMaxLoc");}
				# ******************************
				# exit : gene sequence
    $tmp=$seq; $tmp=~ s/[^ACTG]//g;
    $tmp=100*(length($tmp)/length($seq));
    if ( $tmp > $geneLoc ) {
	return(4,"*** $sbrName ERROR: too ACGT   ratio=$tmp, maxGCGT=$geneLoc");}

				# ------------------------------
				# appears fine -> write file in pir
    $fhout="FHOUT_SEQ_PP";
    open("$fhout","> $fileOutLoc") ||
	return(0,"*** $sbrName cannot open fileOutLoc=$fileOutLoc\n");
    print $fhout ">prot (#) $nameLoc\n";
    for($ct=1; $ct<=length($seq); $ct+=$charPerLine){
	print $fhout substr($seq,$ct,$charPerLine), "\n"; 
    }
    close("$fhout");
    return(1,"$sbrName ok");
}				# end of interpretSeqPP

#===============================================================================
sub interpretSeqSaf {
    local ($fileOutLoc,$fileOutGuideLoc,$fhErrSbr,@safIn) = @_ ;
    local ($sbrName,$Lok,$msg,$tmp,$fhout,$fhout2,$LfirstLine,$Lhead,
	   $name,$seq,$nameFirst,$lenFirstBeforeThis,
	   %nameInBlock,$ctBlocks,$line,$Lguide,$seqGuide,$nameGuide);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   interpretSeqSaf             extracts the SAF input format
#       in:                     $fileOutLoc,$fileOutGuideLoc,$fhErrSbr output file (for MSF),
#       in:                     @safInLoc=lines read from file
#       out:                    write alignment in MSF format
#       in/out GLOBAL:          $safIn{"$name"}=seq, @nameLoc: names (first is guide)
#       err:                    e: (1,msg) -> ok
#       err:                    a: (0,msg) -> some arguments missing/files not opened
#       err:                    b: (2,msg) -> no output file written (msfWrt)
#       err:                    b: (3,msg) -> ERROR from msfCheckFormat
#       err:                    c: (3,msg) -> guide sequence not written
#   
#   specification of format
#   ------------------------------
#   EACH ROW
#   ------------
#   two columns: 1. name (protein identifier, shorter than 15 characters)
#                2. one-letter sequence (any number of characters)
#                   insertions: dots (.), or hyphens (-)
#   ------------
#   EACH BLOCK
#   ------------
#   rows:        1. row must be guide sequence (i.e. always the same name,
#                   this implies, in particular, that this sequence shold
#                   not have blanks
#                2, ..., n the aligned sequences
#
#   comments:    *  rows beginning with a '#' will be ignored
#                *  rows containing only blanks, dots, numbers will also be ignored
#                   (in particular numbering is possible)
#   
#   unspecified: *  order of sequences 2-n can differ between the blocks,
#                *  not all 2-n sequences have to occur in each block,
#                *  
#                *  BUT: whenever a sequence is present, it should have
#                *       dots for insertions rather than blanks
#                *  
#   ------------
#   NOTE
#   ------------
#                The 'freedom' of this format has various consequences:
#                *  identical names in different rows of the same block
#                   are not identified.  Instead, whenever this applies,
#                   the second, (third, ..) sequences are ignored.
#                   e.g.   
#                      t2_11751 EFQEDQENVN 
#                      name-1   ...EDQENvk
#                      name-1   GGAPTLPETL
#                   will be interpreted as:
#                      t2_11751 EFQEDQENVN 
#                      name-1   ...EDQENvk
#                   wheras:
#                      t2_11751 EFQEDQENVN 
#                      name-1   ...EDQENvk
#                      name_1   GGAPTLPETL
#                   has three different names.
#   ------------
#   EXAMPLE 1
#   ------------
#     t2_11751 EFQEDQENVN PEKAAPAQQP RTRAGLAVLR AGNSRGAGGA PTLPETLNVA
#     name_1   EFQEDQENVN PEKAAPAQQP RTRAGLAVLR AGNSRGAGGA PTLPETLNVA
#     name_2   ...EDQENvk PEKAAPAQQP RTRAGLAVLR AGNSRG.... ...PETLNV.
#     name_22  ...EDQENvk PEKAAPAQQP RTRAGLAVLR AGNSRG.... ...PETLNV.
#
#     t2_11751 GGAPTLPETL NVAGGAPTLP ETLNVAGGAP TLPETLNV
#     name_1   GGAPTLPETL NVAGGAPTLP ETLNVAGGAP TLPETLNV
#   
#   ------------
#   EXAMPLE 2
#   ------------
#                         10         20         30         40         
#     t2_11751 EFQEDQENVN PEKAAPAQQP RTRAGLAVLR AGNSRGAGGA PTLPETLNVA
#     name_1   EFQEDQENVN PEKAAPAQQP RTRAGLAVLR AGNSRGAGGA PTLPETLNVA
#     name_2   ...EDQENvk PEKAAPAQQP RTRAGLAVLR AGNSRG.... ...PETLNV.
#     name_22  ...EDQENvk PEKAAPAQQP RTRAGLAVLR AGNSRG.... ...PETLNV.
#
#              50         60         70         80         90
#
#     t2_11751 GGAPTLPETL NVAGGAPTLP ETLNVAGGAP TLPETLNV
#     name_22  .......... .......... .......... ........
#     name_1   GGAPTLPETL NVAGGAPTLP ETLNVAGGAP TLPETLNV
#     name_2   .......... NVAGGAPTLP 
#   
#--------------------------------------------------------------------------------
    $sbrName="interpretSeqSaf";
    return(0,"*** $sbrName: not def fileOutLoc!") if (! defined $fileOutLoc);
    return(0,"*** $sbrName: not def fileOutGuideLoc!") if (! defined $fileOutGuideLoc);
    return(0,"*** $sbrName: not def fhErrSbr!")   if (! defined $fhErrSbr);
    return(0,"*** $sbrName: not def safIn[1]!")   if (! defined $safIn[1]);
				# ------------------------------
				# extr blocks
    $#nameLoc=0;$ctBlocks=0;undef %safIn;
    foreach $_(@safIn){
	next if ($_=~/\#/);	# ignore comments
	last if ($_!~/\#/ && $_=~/^\s*[\-\_]+\s*$/); # stop when address
	$line=$_;
	$tmp=$_;$tmp=~s/[^A-Za-z]//g;
	next if (length($tmp)<1); # ignore lines with numbers, blanks, points only
	$line=~s/^\s*|\s*$//g;	# purge leading blanks
	$name=$line;$name=~s/^\s*([^\s\t]+)\s+.*$/$1/;
	$name=substr($name,1,14); # maximal length: 14 characters (because of MSF2Hssp)
#	$seq=$line;$seq=~s/^\s*//;$seq=~s/^$name//;$seq=~s/\s//g;
	$seq=$line;$seq=~s/^\s*//;$seq=~s/^[^\s\t]+//;$seq=~s/\s//g;
# 	next if ($seq =~/^ACDEFGHIKLMNPQRSTVWXYZ/i);  # check this!!
#	print "--- interpretSeqSaf: name=$name, seq=$seq,\n";
	$nameFirst=$name if ($#nameLoc==0);	# detect first name
	if ($name eq "$nameFirst"){ # count blocks
	    ++$ctBlocks; undef %nameInBlock;
	    if ($ctBlocks==1){$lenFirstBeforeThis=0;}
	    else{$lenFirstBeforeThis=length($safIn{"$nameFirst"});}
	    &interpretSeqSafFillUp if ($ctBlocks>1);} # manage proteins that did not appear
	next if (defined $nameInBlock{"$name"}); # avoid identical names
	if (! defined ($safIn{"$name"})){
	    push(@nameLoc,$name);
#	    print "--- interpretSeqSaf: new name=$name,\n";
	    if ($ctBlocks>1){	# fill up with dots
#		print "--- interpretSeqSaf: file up for $name, with :$lenFirstBeforeThis\n";
		$safIn{"$name"}="." x $lenFirstBeforeThis;}
	    else{
		$safIn{"$name"}="";}}
	$seq=~s/[^A-Za-z]/\./g; # any non-character to dot
	$seq=~tr/[a-z]/[A-Z]/;
	$safIn{"$name"}.=$seq;
	$nameInBlock{"$name"}=1; # avoid identical names
    } 
    &interpretSeqSafFillUp;	# fill up ends
				# store names for passing variables
    foreach $it (1..$#nameLoc){
	$safIn{"$it"}=$nameLoc[$it];}
    $safIn{"NROWS"}=$#nameLoc;

    $safIn{"FROM"}="PP_"."$nameLoc[1]";
    $safIn{"TO"}=$fileOutLoc;
				# ------------------------------
				# write an MSF formatted file
    $fhout="FHOUT_MSF_FROM_SAF";
    open("$fhout",">$fileOutLoc")  || # open file
	return(0,"*** $sbrName cannot open fileOutLoc=$fileOutLoc\n");
    $Lok=
	&msfWrt("$fhout",%safIn); # write the file
    close("$fhout");
				# ------------------------------
				# file existing??
    return(2,"*** $sbrName ERROR after write, missing fileOutLoc=$fileOutLoc\n") 
	if (! -e $fileOutLoc);
				# ------------------------------
				# make a basic test of msf format
    ($Lok,$msg)=
	&msfCheckFormat($fileOutLoc);
    return(3,"$msg"."*** $sbrName ERROR from msfCheckFormat fileOutLoc=$fileOutLoc\n")
	if (! $Lok);
				# ------------------------------
				# write guide sequence in FASTA
    if (defined $nameLoc[1]){$nameGuide=$nameLoc[1];}
    else {$nameGuide=$fileOutGuideLoc;$nameGuide=~s/^.*\/|\..*$//g;}
    $seqGuide=$safIn{"$nameGuide"};
    $seqGuide=~s/[^ABCDEFGHIKLMNPQRSTVWXYZ]//g; # delete non amino acid characters!
    ($Lok,$msg)=
	&fastaWrt($fileOutGuideLoc,$nameGuide,$seqGuide);
    return(4,"*** $sbrName cannot write fasta of guide\n".
	   "*** fileout=$fileOutGuideLoc, id=$nameGuide, seq=$seqGuide\n".
	   "*** ERROR message: $msg\n") if (! $Lok || ! -e $fileOutGuideLoc);
				# ------------------------------
    $#safIn=$#nameLoc=0;			# save space
    undef %safIn; undef %nameInBlock;
    
    return(1,"$sbrName ok");
}				# end of interpretSeqSaf

#===============================================================================
sub interpretSeqSafFillUp {
    local($tmpName,$lenLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   interpretSeqSafFillUp       fill up with dots if sequences shorter than guide
#     all GLOBAL
#       in GLOBAL:              $safIn{"$name"}=seq
#                               @nameLoc: names (first is guide)
#       out GLOBAL:             $safIn{"$name"}
#-------------------------------------------------------------------------------
    foreach $tmpName(@nameLoc){
	if ($tmpName eq "$nameLoc[1]"){ # guide sequence
	    $lenLoc=length($safIn{"$tmpName"});
	    next;}
	$safIn{"$tmpName"}.="." x ($lenLoc-length($safIn{"$tmpName"}));
    }
}				# end of interpretSeqSafFillUp

#===============================================================================
sub is_chain {
    local($tmp) = @_ ;
#-------------------------------------------------------------------------------
#   is_chain                    checks whether or not a PDB chain
#       in:                     character
#       out:                    1,0
#-------------------------------------------------------------------------------
    return(0) if (! defined $tmp);
    return(1) if ($tmp=~/[A-Z0-9]/);
    return(0);
}				# end of is_chain

#===============================================================================
sub is_dssp {
    local ($fileInLoc) = @_ ;
    local ($fh,$Lis);
#--------------------------------------------------------------------------------
#   is_dssp                     checks whether or not file is in DSSP format
#       in:                     $file
#       out:                    1 if is dssp; 0 else
#--------------------------------------------------------------------------------
    return (0) if (! defined $fileInLoc || ! -e $fileInLoc);
    $fh="FHIN_CHECK_DSSP";&open_file("$fh","$fileInLoc");
    while ( <$fh> ) {
	if (/SECONDARY STRUCTURE DEFINITION BY THE PROGRAM DSSP/i){$Lis=1;}else{$Lis=0;}
	last; }close($fh);
    return $Lis;
}				# end of is_dssp

#===============================================================================
sub is_dssp_list {
    local ($fileInLoc) = @_ ;local ($fh,$Lis);
#--------------------------------------------------------------------------------
#   is_dssp_list                checks whether or not file is a list of DSSP files
#       in:                     $file
#       out:                    1 if is dssp; 0 else
#--------------------------------------------------------------------------------
    if (! -e $fileInLoc) {
	return (0);}
    $fh="FHIN_CHECK_DSSP_LIST";&open_file("$fh", "$fileInLoc");
    while ( <$fh> ) {$tmp=$_;$tmp=~s/\s|\n//g;
		     if (length($tmp)<5){next;}
		     if (! -e $tmp)     {$tmp=~s/_.$//;} # purge chain
		     if ( -e $tmp )     { # is existing file?
			 if (&is_dssp($tmp)) {$Lis=1; }
			 else { $Lis=0; } }
		     else {$Lis=0; } 
		     last; } close($fh);
    return $Lis;
}				# end of is_dssp_list

#===============================================================================
sub is_fssp {
    local ($fileInLoc) = @_ ;
#--------------------------------------------------------------------------------
#   is_fssp                     checks whether or not file is in FSSP format
#       in:                     $file
#       out:                    1 if is fssp; 0 else
#--------------------------------------------------------------------------------
    return(0)                   if (! defined $fileInLoc || ! -e $fileInLoc);
    $fh="FHIN_CHECK_FSSP";
    &open_file($fh, "$fileInLoc") || return(0);
    $tmp=<$fh> ;close($fh);
    return(1)                   if (defined $tmp && $tmp=~/^FSSP/);
    return(0);
}				# end of is_fssp

#===============================================================================
sub is_fssp_list {
    local ($fileInLoc) = @_ ;
    local ($fh,$Lis);
#--------------------------------------------------------------------------------
#   is_fssp_lis                 checks whether or not file is a list of FSSP files
#       in:                     $file
#       out:                    1 if is list of fssp files; 0 else
#--------------------------------------------------------------------------------
    return (0)                  if (! defined $fileInLoc || ! -e $fileInLoc);
    $fh="FHIN_CHECK_FSSP_LIST";
    &open_file("$fh", "$fileInLoc") || return(0);
    $Lis=0;
    while ( <$fh> ) {$_=~s/\s|\n//g;
		     if ( -e $_ ) { # is existing file?
			 $Lis=1 if (&is_fssp($_));
			 last; } } close($fh);
    return $Lis;
}				# end of is_fssp_list

#===============================================================================
sub is_hssp {
    local ($fileInLoc) = @_ ;local ($fh,$Lis);
#--------------------------------------------------------------------------------
#   is_hssp                     checks whether or not file is in HSSP format
#       in:                     $file
#       out:                    1 if is hssp; 0 else
#--------------------------------------------------------------------------------
    return (0)                  if (! defined $fileInLoc || ! -e $fileInLoc) ;
    $fh="FHIN_CHECK_HSSP";
    &open_file("$fh", "$fileInLoc") || return(0);
    $Lis=0;
    while ( <$fh> ) {$Lis=1 if (/^HSSP/) ; 
		     last; }close($fh);
    return $Lis;
}				# end of is_hssp

#===============================================================================
sub is_hssp_empty {
    local ($fileInLoc) = @_ ;local ($fh,$Lis);
#--------------------------------------------------------------------------------
#   is_hssp_empty               checks whether or not HSSP file has NALIGN=0
#       in:                     $file
#       out:                    1 if is empty; 0 else
#--------------------------------------------------------------------------------
    return (0)                  if (! defined $fileInLoc || ! -e $fileInLoc);
    $fh="FHIN_CHECK_HSSP";
    &open_file("$fh", "$fileInLoc") || return(0);
    while ( <$fh> ) {
	if ($_=~/^NALIGN\s+(\d+)/){
	    if ($1 eq "0"){
		close($fh); return(1);}
	    last; }}close($fh); 
    return 0;
}				# end of is_hssp_empty

#===============================================================================
sub is_hssp_list {
    local ($fileInLoc) = @_ ;local ($fh,$Lis,$fileRd,$fileLoc,$chainLoc,$LscreenLoc);
#--------------------------------------------------------------------------------
#   is_hssp_list                checks whether or not file contains a list of HSSP files
#       in:                     $file
#       out:                    returns 1 if is HSSP list, 0 else
#--------------------------------------------------------------------------------
    $LscreenLoc=0;
    return (0)                  if (! defined $fileInLoc || ! -e $fileInLoc);
    $fh="FHIN_CHECK_HSSP_LIST";
    &open_file("$fh", "$fileInLoc") || return(0);
    $Lis=0;
    while ( <$fh> ) {$fileRd=$_;$fileRd=~s/\s|\n//g;
		     next if (length($fileRd)<5);
		     ($fileLoc,$chainLoc)= 
			 &hsspGetFile($fileRd,$LscreenLoc);
		     $Lis=1 if (&is_hssp($fileLoc));
		     last; } close($fh);
    return $Lis;
}				# end of is_hssp_list

#===============================================================================
sub is_list {
    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   is_list                     returns 1 if list of existing files
#       in:                     $fileInLoc
#       out:                    1|0,msg,$LisList
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."is_list"; $fhinLoc="FHIN_"."is_list";
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
    return(&errSbr("miss in file '$fileInLoc'!"))  if (! -e $fileInLoc);
				# open file
    &open_file("$fhinLoc","$fileInLoc") || 
	return(&errSbr("fileInLoc=$fileInLoc, not opened"));
    $ct=$LisList=0;		# ------------------------------
    while (<$fhinLoc>) {	# read file
	$_=~s/\n|\s//g;
	next if ($_=~/^\#/);
	++$ct;
	$LisList=1              if (-e $_);
	last if ($LisList || $ct==2); # 2 not existing files -> say NO!
	$tmp=$_; $tmp=~s/_?[A-Z0-9]$//g; # purge chain
	$LisList=1              if (-e $tmp);
    } close($fhinLoc);
    return(1,"ok $sbrName",$LisList);
}				# end of is_list

#===============================================================================
sub is_nndb_rdb { return(&is_rdb_nnDb(@_)); } # alias

#===============================================================================
sub is_nninFor {
    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   is_nninFor                  is input for FORTRAN input
#       in:                     $fileInLoc
#       out:                    1|0,msg,$Lis_nninFor
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."is_nninFor";$fhinLoc="FHIN_"."is_nninFor";
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
    return(&errSbr("miss in file '$fileInLoc'!"))  if (! -e $fileInLoc);
				# open file
    &open_file("$fhinLoc","$fileInLoc") || 
	return(&errSbr("fileInLoc=$fileInLoc, not opened"));
    $Lis=0;
    $lineFirst=<$fhinLoc>;
    close($fhinLoc);
    $Lis=1 if ($lineFirst =~/NNin_in/i);
    return(1,"ok $sbrName",$Lis);
}				# end of is_nninFor

#===============================================================================
sub is_odd_number {
    local($num)=@_ ;
#--------------------------------------------------------------------------------
#   is_odd_number               checks whether number is odd
#       in:                     number
#       out:                    returns 1 if is odd, 0 else
#--------------------------------------------------------------------------------
    return 0 if (int($num/2) == ($num/2));
    return 1;
}				# end of is_odd_number

#===============================================================================
sub is_pdbid {
    local ($id) = @_ ;
#--------------------------------------------------------------------------------
#   is_pdbid                    checks whether or not id is a valid PDBid (number 3 char)
#       in:                     $file
#       out:                    1 if is DBid, 0 else
#--------------------------------------------------------------------------------
    if (length($id) <= 6){
	if ($id=~/^[0-9][0-9a-z]{3,3}[^0-9a-z]?/){
	    return 1;}}
    return 0;
}				# end of is_pdbid

#===============================================================================
sub is_pdbid_list {
    local ($fileInLoc) = @_ ;local ($fh,$Lis);
#--------------------------------------------------------------------------------
#   is_pdbid_list               checks whether id is list of valid PDBids (number 3 char)
#       in:                     $file
#       out:                    1 if is DBid, 0 else
#--------------------------------------------------------------------------------
    if (! -e $fileInLoc) {
	return (0);}
    $fh="FHIN_CHECK_PDBID_LIST";&open_file("$fh", "$fileInLoc");
    while ( <$fh> ) {$tmp=$_;$tmp=~s/\s|\n//g;
		     if (length($tmp)<5){next;}
		     if (! -e $tmp)     {$tmp=~s/_.$//;} # purge chain
		     if ( -e $tmp )     { # is existing file?
			 if (&is_pdbid($_)) {$Lis=1; }
			 else { $Lis=0; } }
		     else {$Lis=0; } 
		     last; } close($fh);
    return $Lis;
}				# end of is_pdbid_list

#===============================================================================
sub is_ppcol {
    local ($fileInLoc) = @_ ;
    local ($fh,$Lis);
#--------------------------------------------------------------------------------
#   is_ppcol                    checks whether or not file is in RDB format
#       in:                     $file
#       out:                    1 if is ppcol, 0 else
#--------------------------------------------------------------------------------
    if (! -e $fileInLoc) {
	return (0);}
    $fh="FHIN_CHECK_HSSP";&open_file("$fh", "$fileInLoc");
    while ( <$fh> ) {$_=~tr/[A-Z]/[a-z]/;
		     if (/^\# pp.*col/) {$Lis=1;}else{$Lis=0;}last; }
    close($fh);
    return $Lis;
}				# end of is_ppcol

#===============================================================================
sub is_rdb {
    local ($fh_in) = @_ ;
#--------------------------------------------------------------------------------
#   is_rdb                      checks whether or not file is in RDB format
#       in:                     filehandle
#       out (GLOBAL):           $LIS_RDB
#--------------------------------------------------------------------------------
    if (! -e $file_in) {
	return (0);}
    while ( <$fh_in> ) {
	if (/^\# Perl-RDB/) {$LIS_RDB=1;}else{$LIS_RDB=0;}
	last;
    }
    return $LIS_RDB ;
}				# end of is_rdb

#===============================================================================
sub is_rdbf {
    local ($file_in) = @_ ;
    local ($fh,$Lis);
#--------------------------------------------------------------------------------
#   is_rdbf                     checks whether or not file is in RDB format
#       in:                     file
#       out:                    returns 1 if is RDB, 0 else
#--------------------------------------------------------------------------------
    if (! -e $file_in) {
	return (0);}
    $fh="FHIN_CHECK_RDB";&open_file("$fh", "$file_in");
    while ( <$fh> ) {if (/^\# Perl-RDB/) {$Lis=1;}else{$Lis=0;}last; }close($fh);
    return $Lis;
}				# end of is_rdbf

#===============================================================================
sub is_rdb_acc {
    local ($fileInLoc) = @_ ;
    local ($fh,$Lisrdb,$Lisacc);
#--------------------------------------------------------------------------------
#   is_rdb_acc                  checks whether or not file is in RDB format from PHDacc
#       in:                     $file
#       out:                    1 if is rdb_acc; 0 else
#--------------------------------------------------------------------------------
    if (! -e $fileInLoc) {
	return (0);}
    $fh="FHIN_CHECK_RDB_PHDACC";$Lisrdb=$Lisacc=0;
    &open_file("$fh", "$fileInLoc");
    while ( <$fh> ) {if (/^\# Perl-RDB/) {$Lisrdb=1;}
		     if (! $Lisrdb) {last;}
		     if (/^\# PHD\s*acc/){$Lisacc=1;last;}
		     if (! /^\#/) {last;} }
    close($fh);
    return ($Lisacc);
}				# end of is_rdb_acc

#===============================================================================
sub is_rdb_htm {
    local ($fileInLoc) = @_ ;
    local ($fh,$Lisrdb,$Lishtm);
#--------------------------------------------------------------------------------
#   is_rdb_htm                  checks whether or not file is in RDB format from PHDhtm
#       in:                     $file
#       out:                    1 if is .; 0 else
#--------------------------------------------------------------------------------
    if (! -e $fileInLoc) {
	return (0);}
    $fh="FHIN_CHECK_RDB_PHDHTM";$Lisrdb=$Lishtm=0;
    &open_file("$fh", "$fileInLoc");
    $ct=$Lishtm=0;
    while ( <$fh> ) { ++$ct;
		      $Lisrdb=1       if (/^\# Perl-RDB/);
		      last if (! $Lisrdb);
		      $Lishtm=1       if (/^\#\s*PHD\s*htm\:/);
		      last if ($Lishtm);
		      last if ($_ !~/^\#/);
		      last if ($ct > 5); }close($fh);
    return ($Lishtm);
}				# end of is_rdb_htm

#===============================================================================
sub is_rdb_htmref {
    local ($fileInLoc) = @_ ;local ($fh,$Lisrdb,$Lishtm);
#--------------------------------------------------------------------------------
#   is_rdb_htmref               checks whether or not file is RDB from PHDhtm_ref
#       in:                     $file
#       out:                    1 if is .; 0 else
#--------------------------------------------------------------------------------
    if (! -e $fileInLoc) {
	return (0);}
    $fh="FHIN_CHECK_RDB_PHDHTM_REF";$Lisrdb=$Lishtm=0;
    &open_file("$fh", "$fileInLoc") || return(0); 
    $ct=$Lishtm=0;
    while ( <$fh> ) { ++$ct;
		      $Lisrdb=1       if (/^\# Perl-RDB/);
		      last if (! $Lisrdb);
		      $Lishtm=1       if (/^\#\s*PHD\s*htm.*ref\:/);
		      last if ($Lishtm);
		      last if ($_ !~/^\#/);
		      last if ($ct > 5); }close($fh);
    return ($Lishtm);
}				# end of is_rdb_htmref

#===============================================================================
sub is_rdb_htmtop {
    local ($fileInLoc) = @_ ;local ($fh,$Lisrdb,$Lishtm);
#--------------------------------------------------------------------------------
#   is_rdb_htmtop               checks whether or not file is RDB from PHDhtm_top
#       in:                     $file
#       out:                    1 if is .; 0 else
#--------------------------------------------------------------------------------
    if (! -e $fileInLoc) {
	return (0);}
    $fh="FHIN_CHECK_RDB_PHDHTM_TOP";$Lisrdb=$Lishtm=0;
    &open_file("$fh", "$fileInLoc") || return(0); 
    $ct=$Lishtm=0;
    while ( <$fh> ) { ++$ct;
		      $Lisrdb=1       if (/^\# Perl-RDB/);
		      last if (! $Lisrdb);
		      $Lishtm=1       if (/^\#\s*PHD\s*htm.*top\:/);
		      last if ($Lishtm);
		      last if ($_ !~/^\#/);
		      last if ($ct > 5); }close($fh);
    return ($Lishtm);
}				# end of is_rdb_htmtop

#===============================================================================
sub is_rdb_nnDb {
    local ($fileInLoc) = @_ ;
    local ($fh,$Lisrdb,$Lisacc);
#--------------------------------------------------------------------------------
#   is_rdb_nnDb                 checks whether or not file is in RDB format for NN.pl
#       in:                     $file
#       out:                    1 if is rdb_nn; 0 else
#--------------------------------------------------------------------------------
    return (0)                  if (! -e $fileInLoc);
    $fh="FHIN_CHECK_RDB_RDBNN";
    &open_file("$fh", "$fileInLoc") || return(0);
    $tmp=(<$fh>);close($fh);
    return(1)                   if (defined $tmp && $tmp=~/^\# Perl-RDB.*NNdb/i);
    return (0);
}				# end of is_rdb_nnDb

#===============================================================================
sub is_rdb_sec {
    local ($fileInLoc) = @_ ;
    local ($fh,$Lisrdb,$Lissec);
#--------------------------------------------------------------------------------
#   is_rdb_sec                  checks whether or not file is RDB from PHDsec
#       in:                     $file
#       out:                    1 if is .; 0 else
#--------------------------------------------------------------------------------
    if (! -e $fileInLoc) {
	return (0);}
    $fh="FHIN_CHECK_RDB_PHDSEC";$Lisrdb=$Lissec=0;
    &open_file("$fh", "$fileInLoc");
    while ( <$fh> ) {if (/^\# Perl-RDB/) {$Lisrdb=1;}
		     if (! $Lisrdb) {last;}
		     if (/^\# PHD\s*sec/){$Lissec=1;last;}
		     if (! /^\#/) {last;} }
    close($fh);
    return ($Lissec);
}				# end of is_rdb_sec

#===============================================================================
sub is_strip {
    local ($fileInLoc) = @_ ;
    local ($fh,$Lis);
#--------------------------------------------------------------------------------
#   is_strip                    checks whether or not file is in HSSP-strip format
#       in:                     $file
#       out:                    1 if is strip; 0 else
#--------------------------------------------------------------------------------
    if (! -e $fileInLoc) {
	return (0);}
    $fh="FHIN_CHECK_STRIP";&open_file("$fh", "$fileInLoc");
    while ( <$fh> ) {if (/===  MAXHOM-STRIP  ===/) {$Lis=1;}else{$Lis=0;}last; }close($fh);
    return $Lis;
}				# end of is_strip

#===============================================================================
sub is_strip_list {
    local ($fileInLoc) = @_ ;local ($fh,$Lis,$fileRd,$fileLoc,$chainLoc,$LscreenLoc);
#--------------------------------------------------------------------------------
#    is_strip_list              checks whether or not file contains a list of HSSPstrip files
#       in:                     $file
#       out:                    1 if is .; 0 else
#--------------------------------------------------------------------------------
    $LscreenLoc=0;
    if (! -e $fileInLoc) {
	return (0);}
    $fh="FHIN_CHECK_STRIP_LIST";&open_file("$fh", "$fileInLoc");
    while ( <$fh> ) {$fileRd=$_;$fileRd=~s/\s|\n//g;
		     if (length($fileRd)<5){
			 next;}
		     if (&is_strip($fileLoc)){$Lis=1;}else { $Lis=0;}
		     last; } close($fh);
    return $Lis;
}				# end of is_strip_list

#===============================================================================
sub is_strip_old {
    local ($fileInLoc)= @_ ;
    local ($fh,$Lis);
#--------------------------------------------------------------------------------
#   is_strip_old                checks whether file is old strip format
#                               (first SUMMARY, then ALIGNMENTS)
#       in:                     $file
#       out:                    1 if is strip; 0 else
#--------------------------------------------------------------------------------
    if (! -e $fileInLoc) {
	return (0);}
    $fh="FHIN_CHECK_STRIP_OLD";
    &open_file("$fh", "$fileInLoc");
    $#tmp=0;
    while(<$fh>){if (/=== ALIGNMENTS ===/){$Lok_ali=1;
					   push(@tmp,"ALIGNMENTS");}
		 elsif (/=== SUMMARY ===/){$Lok_sum=1;
					   push(@tmp,"SUMMARY");}
		 last if ($Lok_ali && $Lok_sum) ;}
    close($fh);
    if ($tmp[1] =~/ALIGNMENTS/){
	$Lis=1;}
    else {
	$Lis=0;}
    return $Lis;
}				# end of is_strip_old

#===============================================================================
sub is_swissprot {return(&isSwiss(@_));} # alias

#===============================================================================
sub is_swissid {
    local ($id) = @_ ;
#--------------------------------------------------------------------------------
#    sub: is_pdbid              checks whether id is a valid SWISSid (char{3,5}_char{3,5})
#                               note: letters have to be lower case
#         input:                id
#         output:               returns 1 if is SWISSid, 0 else
#--------------------------------------------------------------------------------
    if (length($id) <= 12){
	if ($id=~/^[0-9a-z]{3,5}_[0-9a-z]{3,5}/){
	    return 1;}}
    return 0;
}				# end of is_swissid

#===============================================================================
sub is_swissid_list {
    local ($fileLoc) = @_ ;
    local ($fhLoc);
#--------------------------------------------------------------------------------
#    sub: is_swissid_list       checks whether list of valid SWISSid's (char{3,5}_char{3,5})
#         input:                file
#         output:               returns 1 if is Swissid, 0 else
#--------------------------------------------------------------------------------
    if (! -e $fileLoc) {
	return (0);}
    $fhLoc="FHIN_CHECK_SWISSID_LIST";
    &open_file("$fhLoc", "$fileLoc") || return(0);
    while ( <$fhLoc> ) {
	$tmp=$_;$tmp=~s/\s|\n//g; $tmp=~s/^.*\///g; # purge directories
	next if (length($tmp)<5);
	if (&is_swissid($tmp)){ close($fhLoc);
				return(1);}}close($fhLoc);
    return(0);
}				# end of is_swissid_list

#===============================================================================
sub isDaf {local ($fileLoc) = @_ ; local ($Lok);
#--------------------------------------------------------------------------------
#   isDaf                       checks whether or not file is in DAF format
#				(i.e. the dirty ali format used for aqua)
#       in:                     $file
#       out:                    1 if is DAF; 0 else
#--------------------------------------------------------------------------------
	    &open_file("FHIN_DAF","$fileLoc");
	    while (<FHIN_DAF>){	if (/^\# DAF/){$Lok=1;}
				else            {$Lok=0;}
				last;}close(FHIN_DAF);
	    return($Lok);
}				# end of isDaf

#===============================================================================
sub isDafGeneral {
    local ($fileInLoc,@dirLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok,@tmp,$file,$chain);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   isDafGeneral                checks (and finds) DAF files
#       in:                     $file,@dir (to search)
#       out:                    $Lok,$txt,@files
#           txt='not found|empty|not open|none in list|not daf|isDaf|isDafList'
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."isDafGeneral";$fhinLoc="FHIN"."$sbrName";
				# ------------------------------
    if (&isDaf($fileInLoc))    { # file is daf
	return(1,"isDaf",$fileInLoc); } 
				# ------------------------------
    elsif (&isDafList($fileInLoc)) { # file is daf list
	$Lok=&open_file("$fhinLoc","$fileInLoc");$#tmp=0;
	if (! $Lok){print "*** ERROR $sbrName input file=$fileInLoc, not opened\n";
		    return(0,"not open",$fileInLoc);}
	while (<$fhinLoc>) {$_=~s/\n//g;$tmp=$_;
			    if (length($_)==0) { 
				next;}
			    if    ((-e $tmp) && &isDaf($tmp)) { 
				push(@tmp,$tmp);}}close($fhinLoc);
	if ($#tmp==0){return(0,"none in list",$fileInLoc);}
	else         {return(1,"isDafList",@tmp);}}
    else{
	return(0,"not daf",$fileInLoc);}
}				# end of isDafGeneral

#===============================================================================
sub isDafList {
    local ($fileLoc) = @_ ; local ($Lok,$fhinLoc,$fileTmp);
#--------------------------------------------------------------------------------
#   isDafList                   checks whether or not file is list of Daf files
#       in:                     $file
#       out:                    1 if is DAF; 0 else
#--------------------------------------------------------------------------------
    $fhinLoc="FhIn_DafList";$Lok=0;
    &open_file("$fhinLoc","$fileLoc");
    while (<$fhinLoc>){	$fileTmp=~s/\n|\s//g;
			if (&isDaf($fileTmp)){$Lok=1;}
			last;}close($fhinLoc);
    return($Lok);
}				# end of isDafList

#===============================================================================
sub isDsspGeneral {
    local ($fileInLoc,@dirLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok,@tmpFile,@tmpChain,@tmp,$file,$chain);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   isDsspGeneral               checks (and finds) DSSP files
#       in:                     $file,@dir (to search)
#       out:                    $Lok,$txt,@files (if chains: file1,file2,chain,chain1,chain2)
#           txt='not found|empty|not open|none in list|not dssp|isDssp|isDsspList'
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."isDsspGeneral";$fhinLoc="FHIN"."$sbrName";
				# ------------------------------
    if (! -e $fileInLoc){	# search for DSSP
	($file,$chain)=
	    &dsspGetFile($fileInLoc,@dirLoc);
	return(1,"isDssp",$file,$chain) if ((-e $file) && &is_dssp($file));
	return(0,"not dssp",$fileInLoc); }
				# ------------------------------
    if (&is_dssp($fileInLoc)){	# file is dssp
	return(1,"isDssp",$fileInLoc); } 	
				# ------------------------------
				# file is dssp list
    elsif (&is_dssp_list($fileInLoc)) {
	$Lok=&open_file("$fhinLoc","$fileInLoc");$#tmp=0;
	if (! $Lok){print "*** ERROR $sbrName input file=$fileInLoc, not opened\n";
		    return(0,"not open",$fileInLoc);}
	undef @tmpFile; undef @tmpChain;
	while (<$fhinLoc>) {
	    $_=~s/\n|\s//g;$rd=$_;
	    next if (length($_)==0);
				# file exists ...
	    if    (-e $rd) {
		if (&is_dssp($rd)) { # ... and is DSSP       -> bingo
		    push(@tmpFile,$rd); 
		    push(@tmpChain," "); }
		next; }		     # ... may just be empty -> skip
				# file does NOT exist (chain? dir?)
	    ($file,$chain)=	# search again
		&dsspGetFile($rd,1,@dirLoc);
				# ... bingo
	    if    (-e $file && &is_dssp($file)) { 
		push(@tmpFile,$file);
		push(@tmpChain,$chain); }
	    next;		# GIVE UP ...
	} close($fhinLoc);
				# ... none in list ??
	return(0,"none in list",$fileInLoc) if ($#tmpFile==0);
				# ok -> go home
	return(1,"isDsspList",@tmpFile,"chain",@tmpChain);}
    
				# ------------------------------
    else {			# search for DSSP
	($file,$chain)=
	    &dsspGetFile($fileInLoc,@dirLoc);
	return(1,"isDssp",$file,$chain)     if (-e $file && &is_dssp($file));
	return(0,"not dssp",$fileInLoc); 
    }
}				# end of isDsspGeneral

#===============================================================================
sub isFasta {
    local ($fileLoc) = @_ ; local ($Lok);
#--------------------------------------------------------------------------------
#   isFasta                     checks whether or not file is in FASTA format 
#                               (first line /^>\w/, second (non white) = AA
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
    $fhinLoc2="FHIN_FASTA";
    &open_file("$fhinLoc2","$fileLoc") || return(0);
    $one=(<$fhinLoc2>);
    $two=(<$fhinLoc2>);
    $two=~s/\s|\n//g            if (defined $two);
    close($fhinLoc2);
    return(0)                   if (! defined $two || ! defined $one);
    return(1)                   if (($one =~ /^\s*>\s*\w+/) && 
				    ($two !~/[^ABCDEFGHIKLMNPQRSTVWXYZ\.~_!]/));
    return(0);
}				# end of isFasta

#===============================================================================
sub isFastaMul {
    local ($fileLoc) = @_ ; local ($Lok);
#--------------------------------------------------------------------------------
#   isFastaMul                  checks whether more than 1 sequence in FASTA found
#                               (first line /^>\w/, second (non white) = AA *2 
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
    $fhinLoc2="FHIN_FASTA";
    &open_file("$fhinLoc2","$fileLoc") || return(0);
    $one=(<$fhinLoc2>);
    $two=(<$fhinLoc2>);
    $two=~s/\s//g               if (defined $two);

    return (0)                  if (! defined $two || ! defined $one);
    return (0)                  if (($one !~ /^\s*\>\s*\w+/) || 
				    ($two =~ /[^ABCDEFGHIKLMNPQRSTVWXYZ\.~_!]/i));
    $Lok=0;
    while (<$fhinLoc2>) {next if ($_ !~ /^\s*>\s*\w+/);
			 $Lok=1;
			 last;}close($fhinLoc2);
    return($Lok);
}				# end of isFastaMul

#===============================================================================
sub isFsspGeneral {
    local ($fileInLoc,@dirLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok,@tmp,$file,$chain);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   isFsspGeneral               checks (and finds) FSSP files
#       in:                     $file,@dir (to search)
#       out:                    $Lok,$txt,@files
#           txt='not found|empty|not open|none in list|not fssp|isFssp|isFsspList'
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."isFsspGeneral";$fhinLoc="FHIN"."$sbrName";
				# ------------------------------
    if (&is_fssp($fileInLoc))    { # file is fssp
	return(1,"isFssp",$fileInLoc); } 
				# ------------------------------
    elsif (&is_fssp_list($fileInLoc)) { # file is fssp list
	$Lok=&open_file("$fhinLoc","$fileInLoc");$#tmp=0;
	if (! $Lok){print "*** ERROR $sbrName input file=$fileInLoc, not opened\n";
		    return(0,"not open",$fileInLoc);}
	while (<$fhinLoc>) {$_=~s/\n//g;if (length($_)==0)             { next;}
			    $tmp=$_;
			    if    ((-e $tmp) && &is_fssp($tmp))        { push(@tmp,$tmp);}
			    else { # search for valid FSSP file
				($file,$chain)=&fsspGetFile($fileInLoc,@dirLoc);
				if    ((-e $file) && &is_fssp($file))        { push(@tmp,$file);}
				next;}}close($fhinLoc);
	if ($#tmp==0){return(0,"none in list",$fileInLoc);}
	else         {return(1,"isFsspList",@tmp);}}
				# ------------------------------
    else {			# search for FSSP
	($file,$chain)=&fsspGetFile($fileInLoc,@dirLoc);
	if    ((-e $file) && &is_fssp($file))        { 
	    return(1,"isFssp",$file); } 
	else {
	    return(0,"not fssp",$fileInLoc); }}
}				# end of isFsspGeneral

#===============================================================================
sub isGcg {local ($fileLoc) = @_ ; $[ =1 ;
#--------------------------------------------------------------------------------
#    isGcg                      checks whether or not file is in Gcg format (/# SAF/)
#       in:                     $file
#       out:                    1 if is yes; 0 else
# EXA: paho_chick from:    1 to:   80
# EXA: PANCREATIC HORMONE PRECURSOR (PANCREATIC POLYPEPTIDE) (PP).
# EXA:  paho_chick.gcg          Length:   80   31-May-98  Check: 8929 ..
# EXA:        1  MPPRWASLLL LACSLLLLAV PPGTAGPSQP TYPGDDAPVE DLIRFYNDLQ
# EXA:       51  QYLNVVTRHR YGRRSSSRVL CEEPMGAAGC
#--------------------------------------------------------------------------------
           return(0) if (! defined $fileLoc || ! -e $fileLoc);
           $fhinLoc="FHIN_GCG";
           &open_file("$fhinLoc","$fileLoc") || return(0);
           @tmp=<$fhinLoc>; 
           close("$fhinLoc");
           $ctFlag=0;
           foreach $tmp(@tmp){
	       last if ($tmp=~/^\#/); # avoid being too friendly to GCG!
               if   ($tmp =~ /from\s*:\s*\d+\s*to:\s*\d+/i){++$ctFlag;}
               elsif($tmp =~ /length\s*:\s*\d+/i)          {++$ctFlag;}
               elsif($tmp =~ /[\s\t]*\d+\s+[A-Z]+/i)       {++$ctFlag;}
               last if ($ctFlag==3);}
           return(1) if ($ctFlag==3);
           return(0) ;
}				# end of isGcg

#===============================================================================
sub isHelp {
    local ($argLoc) = @_ ;$[ =1 ;
#--------------------------------------------------------------------------------
#   isHelp		        returns 1 if : help,man,-h
#       in:                     argument
#       out:                    returns 1 if is help, 0 else
#--------------------------------------------------------------------------------
    if ( ($argLoc eq "help") || ($argLoc eq "man") || ($argLoc eq "-h") ){
	return(1);}else{return(0);}
}				# end of isHelp

#===============================================================================
sub isHsspGeneral {
    local ($fileInLoc,@dirLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok,@tmpFile,@tmpChain,@tmp,$file,$chain);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   isHsspGeneral               checks (and finds) HSSP files
#       in:                     $file,@dir (to search)
#       out:                    $Lok,$txt,@files (if chains: file1,file2,chain,chain1,chain2)
#           txt='not found|empty|not open|none in list|not hssp|isHssp|isHsspList'
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."isHsspGeneral";$fhinLoc="FHIN"."$sbrName";
				# ------------------------------
    if (! -e $fileInLoc){	# search for HSSP
	($file,$chain)=
	    &hsspGetFile($fileInLoc,@dirLoc);
	return(1,"isHssp",$file,$chain) if ((-e $file) && &is_hssp($file));
	return(0,"empty", $file)    	if ((-e $file) && &is_hssp_empty($file));
	return(0,"not hssp",$fileInLoc); }
				# ------------------------------
    if (&is_hssp($fileInLoc)){	# file is hssp
	return(0,"empty hssp",$fileInLoc)
	    if (&is_hssp_empty($fileInLoc));
	return(1,"isHssp",$fileInLoc); } 
				# ------------------------------
				# file is hssp list
    elsif (&is_hssp_list($fileInLoc)) {
	$Lok=&open_file("$fhinLoc","$fileInLoc");$#tmp=0;
	if (! $Lok){print "*** ERROR $sbrName input file=$fileInLoc, not opened\n";
		    return(0,"not open",$fileInLoc);}
	undef @tmpFile; undef @tmpChain;
	while (<$fhinLoc>) {
	    $_=~s/\n|\s//g;$rd=$_;
	    next if (length($_)==0);
				# file exists ...
	    if    (-e $rd) {
		if (&is_hssp($rd)) { # ... and is HSSP       -> bingo
		    push(@tmpFile,$rd); 
		    push(@tmpChain," "); }
		next; }		     # ... may just be empty -> skip
				# file does NOT exist (chain? dir?)
	    ($file,$chain)=	# search again
		&hsspGetFile($rd,1,@dirLoc);
				# ... bingo
	    if    (-e $file && &is_hssp($file)) { 
		push(@tmpFile,$file);
		push(@tmpChain,$chain); }
	    next;		# GIVE UP ...
	} close($fhinLoc);
				# ... none in list ??
	return(0,"none in list",$fileInLoc) if ($#tmpFile==0);
				# ok -> go home
	return(1,"isHsspList",@tmpFile,"chain",@tmpChain);}
    
				# ------------------------------
    else {			# search for HSSP
	($file,$chain)=
	    &hsspGetFile($fileInLoc,@dirLoc);
	return(1,"isHssp",$file,$chain)     if (-e $file && &is_hssp($file));
	return(0,"empty" ,$file,"err")      if (-e $file && &is_hssp_empty($file));
	return(0,"not hssp",$fileInLoc); 
    }
}				# end of isHsspGeneral

#===============================================================================
sub isMsf {local ($fileLoc) = @_ ; local ($Lok);
#--------------------------------------------------------------------------------
#   isMsf                       checks whether or not file is in MSF format
#				(i.e. the dirty ali format used for aqua)
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
	   &open_file("FHIN_MSF","$fileLoc");
	   while (<FHIN_MSF>){ if (/^\s*MSF/){$Lok=1;}
			       else          {$Lok=0;}
			       last;}close(FHIN_MSF);
	   return($Lok);
}				# end of isMsf

#===============================================================================
sub isMsfGeneral {
    local ($fileInLoc,@dirLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok,@tmp,$file,$chain);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   isMsfGeneral                checks (and finds) MSF files
#       in:                     $file,@dir (to search)
#       out:                    $Lok,$txt,@files
#           txt='not found|empty|not open|none in list|not msf|isMsf|isMsfList'
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."isMsfGeneral";$fhinLoc="FHIN"."$sbrName";
    if (! -e $fileInLoc){
	return(0,"not existing",$fileInLoc);}
				# ------------------------------
    if (&isMsf($fileInLoc))    { # file is msf
	return(1,"isMsf",$fileInLoc); } 
				# ------------------------------
    elsif (&isMsfList($fileInLoc)) { # file is msf list
	$Lok=&open_file("$fhinLoc","$fileInLoc");$#tmp=0;
	if (! $Lok){print "*** ERROR $sbrName input file=$fileInLoc, not opened\n";
		    return(0,"not open",$fileInLoc);}
	while (<$fhinLoc>) {$_=~s/\n//g;$tmp=$_;
			    if (length($_)==0) { 
				next;}
			    if    ((-e $tmp) && &isMsf($tmp)) { 
				push(@tmp,$tmp);}}close($fhinLoc);
	if ($#tmp==0){return(0,"none in list",$fileInLoc);}
	else         {return(1,"isMsfList",@tmp);}}
    else{
	return(0,"not msf",$fileInLoc);}
}				# end of isMsfGeneral

#===============================================================================
sub isMsfList {
    local ($fileLoc) = @_ ; local ($Lok,$fhinLoc,$fileTmp);
#--------------------------------------------------------------------------------
#   isMsfList                   checks whether or not file is list of Msf files
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
    $fhinLoc="FhIn_MsfList";$Lok=0;
    &open_file("$fhinLoc","$fileLoc");
    while (<$fhinLoc>){	$fileTmp=$_;$fileTmp=~s/\n|\s//g;
			if (&isMsf($fileTmp)&&(-e $fileTmp)){$Lok=1;}
			last;}close($fhinLoc);
    return($Lok);
}				# end of isMsfList

#===============================================================================
sub isPhdAcc {
    local ($fileLoc) = @_ ; local ($Lok);
#--------------------------------------------------------------------------------
#   isPhdAcc                    checks whether or not file is in MSF format
#				(i.e. the dirty ali format used for aqua)
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
    &open_file("FHIN_RDB_PHDACC","$fileLoc");
    $ct=0;
    while (<FHIN_RDB_PHDACC>){ $_=~s/^[\#\s]//g;
                               if (length($_)<5){
                                   next;}
			       ++$ct;
			       last if ($ct>3);
                               if   (($ct==1)&& /^\s*Perl-RDB/){$Lok=1;}
                               elsif ($ct==1) { close(FHIN_RDB_PHDACC); 
                                                return(0);}
			       elsif (/PHDacc/){close(FHIN_RDB_PHDACC); 
                                                return(1);}}close(FHIN_RDB_PHDACC);
    return(0);
}				# end of isPhdAcc

#===============================================================================
sub isPhdHtm {
    local ($fileLoc) = @_ ; local ($Lok);
#--------------------------------------------------------------------------------
#   isPhdHtm                    checks whether or not file is in MSF format
#				(i.e. the dirty ali format used for aqua)
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
    &open_file("FHIN_RDB_PHDHTM","$fileLoc");
    $ct=0;
    while (<FHIN_RDB_PHDHTM>){ $_=~s/^[\#\s]//g;
                               if (length($_)<5){
                                   next;}
			       ++$ct;
			       last if ($ct>3);
                               if   (($ct==1)&& /^\s*Perl-RDB/){$Lok=1;}
                               elsif ($ct==1) { close(FHIN_RDB_PHDHTM); 
                                                return(0);}
			       elsif (/PHDhtm/){close(FHIN_RDB_PHDHTM); 
                                                return(1);}}close(FHIN_RDB_PHDHTM);
    return(0);
}				# end of isPhdHtm

#===============================================================================
sub isPhdSec {
    local ($fileLoc) = @_ ; local ($Lok);
#--------------------------------------------------------------------------------
#   isPhdSec                    checks whether or not file is in MSF format
#				(i.e. the dirty ali format used for aqua)
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
    &open_file("FHIN_RDB_PHDSEC","$fileLoc");
    $ct=0;
    while (<FHIN_RDB_PHDSEC>){ $_=~s/^[\#\s]//g;
                               if (length($_)<5){
                                   next;}
			       ++$ct;
			       last if ($ct>3);
                               if   (($ct==1)&& /^\s*Perl-RDB/){$Lok=1;}
                               elsif ($ct==1) { close(FHIN_RDB_PHDSEC); 
                                                return(0);}
			       elsif (/PHDsec/){close(FHIN_RDB_PHDSEC); 
                                                return(1);}}close(FHIN_RDB_PHDSEC);
    return(0);
}				# end of isPhdSec

#===============================================================================
sub isPir {
    local ($fileLoc) = @_ ; local ($Lok);
#--------------------------------------------------------------------------------
#    isPir                    checks whether or not file is in Pir format 
#                               (first line /^>P1\;/, second (non white) = AA
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
    &open_file("FHIN_PIR","$fileLoc") || return(0);
    $one=(<FHIN_PIR>);close(FHIN_PIR);
    return(1)                   if (defined $one && $one =~ /^\>P1\;/i);
    return(0);
}				# end of isPir

#===============================================================================
sub isPirMul {
    local ($fileLoc) = @_ ; local ($Lok);
#--------------------------------------------------------------------------------
#   isPirMul                    checks whether or not file contains many sequences 
#                               in PIR format 
#                               more than once: first line /^>P1\;/
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
    &open_file("FHIN_PIR","$fileLoc") || return(0);
    $ct=0;
    while(<FHIN_PIR>){++$ct if ($_=~/^>P1\;/i);
                      last if ($ct>1);}close(FHIN_PIR);
    return(1)                   if ($ct>1);
    return(0);
}				# end of isPirMul

#===============================================================================
sub isRdb {local ($fileInLoc) = @_ ;local ($fh);
#--------------------------------------------------------------------------------
#   isRdb                       checks whether or not file is in RDB format
#       in:                     file
#       out:                    returns 1 if is RDB, 0 else
#--------------------------------------------------------------------------------
	   return (0) if (! -e $fileInLoc);$fh="FHIN_CHECK_RDB";
	   &open_file("$fh", "$fileInLoc") || return(0);
	   $tmp=<$fh>;close($fh);
	   return(1)            if (defined $tmp && $tmp =~/^\# .*RDB/);
	   return 0; }	# end of isRdb

#===============================================================================
sub isRdbGeneral {
    local ($fileInLoc,@dirLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok,@tmp,$file,$chain);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   isRdbGeneral                checks (and finds) RDB files
#       in:                     $file,@dir (to search)
#       out:                    $Lok,$txt,@files
#           txt='not found|empty|not open|none in list|not rdb|isRdb|isRdbList'
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."isRdbGeneral";$fhinLoc="FHIN"."$sbrName";
				# ------------------------------
    if (&isRdb($fileInLoc))    { # file is rdb
	return(1,"isRdb",$fileInLoc); } 
				# ------------------------------
    elsif (&isRdbList($fileInLoc)) { # file is rdb list
	$Lok=&open_file("$fhinLoc","$fileInLoc");$#tmp=0;
	if (! $Lok){print "*** ERROR $sbrName input file=$fileInLoc, not opened\n";
		    return(0,"not open",$fileInLoc);}
	while (<$fhinLoc>) {$_=~s/\n//g;$tmp=$_;
			    if (length($_)==0) { 
				next;}
			    if    ((-e $tmp) && &isRdb($tmp)) { 
				push(@tmp,$tmp);}}close($fhinLoc);
	if ($#tmp==0){return(0,"none in list",$fileInLoc);}
	else         {return(1,"isRdbList",@tmp);}}
    else{
	return(0,"not rdb",$fileInLoc);}
}				# end of isRdbGeneral

#===============================================================================
sub isRdbList {local ($fileInLoc) = @_ ; local ($Lok,$fhinLoc,$fileTmp);
#--------------------------------------------------------------------------------
#   isRdbList                   checks whether or not file is list of Rdb files
#       in:                     file
#       out:                    returns 1 if is RDB, 0 else
#--------------------------------------------------------------------------------
	       return(0) if (! -e $fileInLoc); $fhinLoc="FHIN_RDBLIST";$Lok=0;
	       $Lok=&open_file("$fhinLoc","$fileInLoc");
	       if (! $Lok){ print "*** ERROR in lib-br.pl:isRdbList, opening '$fileInLoc'\n";
			    return(0);}
	       while (<$fhinLoc>){ 
                   $_=~s/\s|\n//g;
                   if ($_=~/^\#/ || ! -e $_){close($fhinLoc);
                                             return(0);}
                   $fileTmp=$_;
                   if (&isRdb($fileTmp)&&(-e $fileTmp)){
                       close($fhinLoc);
                       return(1);}
                   last;}close($fhinLoc);
	       return(0); }	# end of isRdbList

#===============================================================================
sub isSaf {local ($fileLoc) = @_ ; 
#--------------------------------------------------------------------------------
#    isSaf                      checks whether or not file is in SAF format (/# SAF/)
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
           return(0)            if (! defined $fileLoc || ! -e $fileLoc);
	   $fhinLoc="FHIN_SAF";
           &open_file("$fhinLoc","$fileLoc") || return (0);
           $tmp=<$fhinLoc>; close("$fhinLoc");
           return(1)            if (defined $tmp && $tmp =~ /^\#.*SAF/);
           return(0);
}				# end of isSaf

#===============================================================================
sub isSwiss {local ($fileLoc) = @_ ; local ($Lok);
#--------------------------------------------------------------------------------
#    isSwiss                    checks whether or not file is in SWISS-PROT format (/^ID   /)
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
             $fhinLoc="FHIN_SWISS";
	     &open_file("$fhinLoc","$fileLoc");
	     while (<$fhinLoc>){ if (/^ID   /){$Lok=1;}else{$Lok=0;}
                                 last;}close($fhinLoc);
	     return($Lok);
}				# end of isSwiss

#===============================================================================
sub isSwissGeneral {
    local ($fileInLoc,@dirLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok,@tmp,$file,$chain);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   isSwissGeneral              checks (and finds) SWISS files
#       in:                     $file,@dir (to search)
#       out:                    $Lok,$txt,@files
#           txt='not found|empty|not open|none in list|not swiss|isSwiss|isSwissList'
#-------------------------------------------------------------------------------
    $sbrName="lib-br:isSwissGeneral";$fhinLoc="FHIN"."$sbrName";
    return(1,"isSwiss",$fileInLoc) if (&isSwiss($fileInLoc)) ;  # file is swiss
				# ------------------------------
    if (&isSwissList($fileInLoc)) { # file is swiss list
	$Lok=&open_file("$fhinLoc","$fileInLoc");$#tmp=0;
	if (! $Lok){print "*** ERROR $sbrName input file=$fileInLoc, not opened\n";
		    return(0,"not open",$fileInLoc);}
	while (<$fhinLoc>) {$_=~s/\n//g;	    
			    next if (length($_)==0);
			    $tmp=$_;
			    if    ((-e $tmp) && &isSwiss($tmp))        { 
				push(@tmp,$tmp);}
			    else {		# search for valid SWISS file
				($file,$chain)=&swissGetFile($fileInLoc,@dirLoc);
				if    ((-e $file) && &isSwiss($file))        { 
				    push(@tmp,$file);}
				next;}}close($fhinLoc);
	if ($#tmp==0){return(0,"none in list",$fileInLoc);}
	else         {return(1,"isSwissList",@tmp);}}
				# ------------------------------
    else {			# search for SWISS
	($file,$chain)=
	    &swissGetFile($fileInLoc,@dirLoc);
	return(1,"isSwiss",  $file) if ((-e $file) && &isSwiss($file));
	return(0,"not swiss",$fileInLoc);}
}				# end of isSwissGeneral

#===============================================================================
sub isSwissList {
    local ($fileLoc) = @_ ; local ($Lok,$fhinLoc,$fileTmp);
#--------------------------------------------------------------------------------
#   isSwissList                 checks whether or not file is list of Swiss files
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
    $fhinLoc="FhIn_SwissList";$Lok=0;
    &open_file("$fhinLoc","$fileLoc");
    while (<$fhinLoc>){	$fileTmp=$_;$fileTmp=~s/\n|\s//g;
			if (! -e $fileTmp){return(0);}
			if (&isSwiss($fileTmp)&&(-e $fileTmp)){$Lok=1;}
			last;}close($fhinLoc);
    return($Lok);
}				# end of isSwissList

#===============================================================================
sub maxhomCheckHssp {
    local ($file_in,$laliPdbMin)=@_;
    local ($sbrName,$len_strid,$Llong_id,$msgHere,$tmp,$found,$posPdb,$posLali,$pdb,$len);
    $[ =1;
#----------------------------------------------------------------------
#   maxhomCheckHssp             checks: (1) any ali? (2) PDB?
#       in:                     $fileHssp,$laliMin (minimal ali length to report PDB)
#       out:                    $Lok,$LisEmpty,$LisSelf,$IsIlyaPdb,$pdbidFound
#       out:                    1 error: (0,'error','error message')
#       out:                    1 ok   : (1,'ok',   'message')
#       out:                    2 empty: (2,'empty','message')
#       out:                    3 self : (3,'self', 'message')
#       out:                    4 pdbid: (4,'pdbid','message')
#----------------------------------------------------------------------
    $sbrName="lib-br:maxhomCheckHssp";
    return(0,"error","*** $sbrName: not def file_in!")            if (! defined $file_in);
    return(0,"error","*** $sbrName: not def laliPdbMin!")         if (! defined $laliPdbMin);
    return(0,"error","*** $sbrName: miss input file '$file_in'!") if (! -e $file_in);
				# defaults for reading
    $len_strid= 4;		# minimal length to identify PDB identifiers
    $Llong_id=  0;

    $msgHere="--- $sbrName \t in=$file_in\n";
				# open HSSP file
    open(FILEIN,$file_in)  || 
	return(0,"error","*** $sbrName cannot open '$file_in'\n");
				# ----------------------------------------
				# skip everything before "## PROTEINS"
    $Lempty=1;			# ----------------------------------------
    while( <FILEIN> ) {
	if ($_=~/^PARAMETER  LONG-ID :YES/) { # is long id?
	    $Llong_id=1;}
	if ($_=~/^\#\# PROTEINS/ ) {
	    $Lempty=0;
	    last;}}

    if ($Lempty){		# exit if no homology found
	$msgHere.="no homologue found in $file_in!";
	close(FILEIN);
	return(1,"empty",$msgHere); }
				# ----------------------------------------
				# now search for PDB identifiers
				# ----------------------------------------
    if ($Llong_id){ $posPdb=47; $posLali=86;} else { $posPdb=21; $posLali=60;}
    $found="";
    while ( <FILEIN> ) {
	next if ($_ !~ /^\s*\d+ \:/);
	$pdb=substr($_,$posPdb,4);  $pdb=~ s/\s//g;
	$len=substr($_,$posLali,4); $len=~ s/\s//g;
	if ( (length($pdb) > 1) && ($len>$laliPdbMin) ) { # global parameter
	    $found.=$pdb.", ";} 
	last if ($_=~ /\#\# ALIGNMENT/ ); }
    close(FILEIN);

    if (length($found) > 2) {
	return(1,"pdbid","pdbid=".$found."\n$msgHere"); }

    return(1,"ok",$msgHere);
}				# end of maxhomCheckHssp

#===============================================================================
sub maxhomGetArg {
    local($niceLoc,$exeMaxLoc,$fileDefaultLoc,$jobid,$fileMaxIn,$fileMaxList,$Lprofile,
	  $fileMaxMetric,$paraMaxSmin,$paraMaxSmax,$paraMaxGo,$paraMaxGe,
	  $paraMaxWeight1,$paraMaxWeight2,$paraMaxIndel1,$paraMaxIndel2,
	  $paraMaxNali,$paraMaxThresh,$paraMaxSort,$fileHsspOut,$dirMaxPdb,
	  $paraMaxProfileOut,$fileStripOut)=@_;
    local ($command);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   maxhomGetArg                gets the input arguments to run MAXHOM
#       in:                     
#         $niceLoc              level of nice (nice -n)
#         $exeMaxLoc            fortran executable for MaxHom
#         $fileDefaultLoc       local copy of maxhom default file
#         $jobid                number which will be added to files :
#                               MAXHOM_ALI.jobid, MAXHOM.LOG_jobid, maxhom.default_jobid
#                               filter.list_jobid, blast.x_jobid
#         $fileMaxIn            query sequence (should be FASTA, here)
#         $fileMaxList          list of db to align against
#         $Lprofile             NO|YES
#         $fileMaxMetric        metric
#         $paraMaxSmin          minimal value of metric (typical -0.5)
#         $paraMaxSmax          maximal value of metric (typical  1.0)
#         $paraMaxGo            gap open penalty        (typical  3.0)
#         $paraMaxGe            gap extension/elongation penalty (typ 
#         $paraMaxWeight1       YES|NO                  (typ yes)
#         $paraMaxWeight2       YES|NO                  (typ NO)
#         $paraMaxIndel1        YES|NO                  (typ yes)
#         $paraMaxIndel2        YES|NO                  (typ yes)
#         $paraMaxNali          maximal number of alis reported (was 500)
#         $paraMaxThresh              
#         $paraMaxSort          DISTANCE|    
#         $fileHsspOut          NO|name of output file (.hssp)
#         $dirMaxPdb            path of PDB directory
#         $paraMaxProfileOut    NO| ?
#         $fileStripOut         NO|file name of strip file
#       out:                    $command
#--------------------------------------------------------------------------------
    $tmpNice=$niceLoc;
    if ($tmpNice =~ /\d/ || $tmpNice eq "nice"){
	$tmpNice=~s/nice|[ -]//g; 
	$tmpNice=19 if (length($tmpNice)<1);
	if ($exeMaxLoc =~/ALPHA/){$tmpNice="nice -".$tmpNice;}
	else                     {$tmpNice="nice -".$tmpNice;}}
    eval "\$command=\"$tmpNice $exeMaxLoc -d=$fileDefaultLoc -nopar ,
         COMMAND NO ,
         BATCH ,
         PID:          $jobid ,
         SEQ_1         $fileMaxIn ,      
         SEQ_2         $fileMaxList ,
         PROFILE       $Lprofile ,
         METRIC        $fileMaxMetric ,
         NORM_PROFILE  DISABLED , 
         MEAN_PROFILE  0.0 ,
         FACTOR_GAPS   0.0 ,
         SMIN          $paraMaxSmin , 
         SMAX          $paraMaxSmax ,
         GAP_OPEN      $paraMaxGo ,
         GAP_ELONG     $paraMaxGe ,
         WEIGHT1       $paraMaxWeight1 ,
         WEIGHT2       $paraMaxWeight2 ,
         WAY3-ALIGN    NO ,
         INDEL_1       $paraMaxIndel1,
         INDEL_2       $paraMaxIndel2,
         RELIABILITY   NO ,
         FILTER_RANGE  10.0,
         NBEST         1,
         MAXALIGN      $paraMaxNali ,
         THRESHOLD     $paraMaxThresh ,
         SORT          $paraMaxSort ,
         HSSP          $fileHsspOut ,
         SAME_SEQ_SHOW YES ,
         SUPERPOS      NO ,
         PDB_PATH      $dirMaxPdb ,
         PROFILE_OUT   $paraMaxProfileOut ,
         STRIP_OUT     $fileStripOut ,
         DOT_PLOT      NO ,
         RUN ,\"";
    return ($command);
}				# end maxhomGetArg

#===============================================================================
sub maxhomGetArgCheck {
    local($exeMaxLoc,$fileDefLoc,$fileMaxIn,$fileMaxList,$fileMaxMetric)=@_;
    local($msg,$warn,$pre);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   maxhomGetArgCheck           performs some basic file-existence-checks
#                               before Maxhom arguments are built up
#       in:                     $exeMaxLoc,$fileDefLoc,$fileMaxIn,$fileMaxList,$fileMaxMetric
#       out:                    msg,warn
#--------------------------------------------------------------------------------
    $msg="";$warn="";$pre="*** maxhomGetArgCheck missing ";
    if    (! -e $exeMaxLoc)    {$msg.="$pre"."$exeMaxLoc=    for exe\n";}
    elsif (! -e $fileDefLoc)   {$msg.="$pre"."$fileDefLoc=   default file\n";}
    elsif (! -e $fileMaxIn)    {$msg.="$pre"."$fileMaxIn=    query seq\n";}
    elsif (! -e $fileMaxList)  {$msg.="$pre"."$fileMaxList=  ali DB\n";}
    elsif (! -e $fileMaxMetric){$msg.="$pre"."$fileMaxMetric=metric\n";}
    return ($msg,$warn);
}				# end maxhomGetArgCheck

#===============================================================================
sub maxhomGetThresh {
    local($ideIn)=@_;
    local($tmp,$thresh_txt);
    $[ =1 ;
#----------------------------------------------------------------------
#   maxhomGetThresh             translates cut-off ide into text input for MAXHOM csh
#       in:                     $ideIn (= distance to FORMULA, old)
#       out:                    $txt 'FORMULA+/-n'
#----------------------------------------------------------------------
				# final txt for MAXHOM cshell (FORMULA,FORMULA-n,FORMULA+n)
    if   ($ideIn>25) {
	$tmp=$ideIn-25;
	$thresh_txt="FORMULA+"."$tmp"; }
    elsif($ideIn<25) {
	$tmp=25-$ideIn;
	$thresh_txt="FORMULA-"."$tmp"; }
    else {
	$thresh_txt="FORMULA"; }
    return($thresh_txt);
}				# end of maxhomGetThresh

#===============================================================================
sub maxhomGetThresh4PP {
    local($LisExpert,$expertMinIde,$minIde,$minIdeRd)=@_;
    local($thresh_now,$thresh_up,$tmp,$thresh_txt);
    $[ =1 ;
#----------------------------------------------------------------------
#   maxhomGetThresh4PP          translates cut-off ide into text input for MAXHOM csh
#       note:                   special for PP, as assumptions about upper/lower
#       in:                     ($LisExpert,$expertMinIde,$minIde,$minIdeRd
#       out:                    $txt 'FORMULA+/-n'
#----------------------------------------------------------------------
    if ($LisExpert) { # upper seq ide
	$thresh_up=$expertMinIde; }
    else { 
	$thresh_up=$minIde; }
                                # value passed ('maxhom expert number')?
    if ( (defined $minIdeRd) && ($minIdeRd>=$thresh_up) ) {
	$thresh_now=$minIdeRd;}
    else { 
	$thresh_now=$thresh_up;}
				# final txt for MAXHOM cshell (FORMULA,FORMULA-n,FORMULA+n)
    if   ($thresh_now>25) {$tmp=$thresh_now-25;
			   $thresh_txt="FORMULA+"."$tmp"; }
    elsif($thresh_now<25) {$tmp=25-$thresh_now;
			   $thresh_txt="FORMULA-"."$tmp"; }
    else                  {$thresh_txt="FORMULA"; }
    return($thresh_txt);
}				# end of maxhomGetThresh4PP

#===============================================================================
sub maxhomMakeLocalDefault {
    local($fileInDef,$fileLocDef,$dirWorkLoc)=@_;
    local($sbrName);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   maxhomMakeLocalDefault      build local maxhom default file, and set PATH!!
#       in:                     $fileInDef,$fileLocDef,$dirWorkLoc
#       out:                    
#       err:                    ok=(1,'ok'), err=(0,'msg')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:maxhomMakeLocDef";
				#---------------------------------------------------------
				# build local maxhom default file, set COREPATH=Dir_work
				#---------------------------------------------------------
    open(MAX_DEF,  "$fileInDef")   || 
	return(0,"*** $sbrName: cannot open input file '$fileInDef'!");
    open(MAX_N_DEF,">$fileLocDef") || 
	return(0,"*** $sbrName: cannot open output file '$fileLocDef'!");
    while (<MAX_DEF>) {
	chop;
	next if ($_=~/^\#/);
	if    ($_=~/COREPATH/ && $_ !~ /$dirWorkLoc/){
	    $_="COREPATH                  :   ".$dirWorkLoc;}
	elsif ($_=~/COREFILE/ && $_ =~ /$dirWorkLoc/){
	    $_="COREFILE                  :   MAXHOM_ALI.";}
#	    $_="COREFILE                  :   $dirWorkLoc/MAXHOM_ALI.";}
	print MAX_N_DEF "$_\n"; }
    close (MAX_DEF) ;
    close (MAX_N_DEF) ;
    return(1,"ok $sbrName");
}				# end of maxhomMakeLocalDefault

#===============================================================================
sub maxhomRun {
    local($date,$nice,$LcleanUpLoc,$fhErrSbr,
	  $fileSeqLoc,$fileSeqFasta,$fileBlast,$fileBlastFil,$fileHssp,
	  $dirData,$dirSwiss,$dirPdb,$exeConvSeq,$exeBlastp,$exeBlastpFil,$exeMax,
	  $envBlastpMat,$envBlastpDb,$parBlastpNhits,$parBlastpDb,
	  $fileMaxDef,$fileMaxMetr,$Lprof,$parMaxThresh,$parMaxSmin,$parMaxSmax,
	  $parMaxGo,$parMaxGe,$parMaxW1,$parMaxW2,$parMaxI1,$parMaxI2,$parMaxNali,
	  $parMaxSort,$parMaxProfOut,$parMaxStripOut,$parMinLaliPdb,$parMaxTimeOut)=@_;
    local($sbrName,$tmp,$Lok,$jobid,$msgHere,$msg,$thresh,@fileTmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   maxhomRun                   runs Maxhom (looping for many trials + self)
#       in:                     give 'def' instead of argument for default settings
#       out:                    (0,'error','txt') OR (1,'ok','name')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."maxhomRun";

    if (! defined $date){
	@Date = split(' ',&ctime(time)) ; $date="$Date[2] $Date[3], $Date[6]";}
    $nice=" "                                              if (! defined $nice || $nice eq "def");
    $fhTraceLoc="STDOUT"                                      if (! defined $fhTraceLoc);
    return(0,"*** $sbrName: not def GLOBAL: ARCH!")        if (! defined $ARCH);
				# ------------------------------
				# input file names
    return(0,"*** $sbrName: not def fileSeqLoc!")          if (! defined $fileSeqLoc);
    return(0,"*** $sbrName: not def LcleanUpLoc!")         if (! defined $LcleanUpLoc);
				# ------------------------------
				# temporary files (defaults)
    $jobid=$$;$id=$fileSeqLoc;$id=~s/^.*\///g;$id=~s/\..*$//g;$id=~s/\s//g;
    $fileSeqFasta="MAX-".$jobid."-".$id.".seqFasta"
	                              if (! defined $fileSeqFasta   || $fileSeqFasta   eq "def");
    $fileBlast=   "MAX-".$jobid."-".$id.".blast"
	                              if (! defined $fileBlast      || $fileBlast      eq "def");
    $fileBlastFil="MAX-".$jobid."-".$id.".blastFil"
	                              if (! defined $fileBlastFil   || $fileBlastFil   eq "def");
    $fileHssp=    "MAX-".$jobid."-".$id.".hssp"
	                              if (! defined $fileHssp       || $fileHssp       eq "def");
				# ------------------------------
				# default settings
    $dirData=       "/data"           if (! defined $dirData        || $dirData        eq "def");
    $dirSwiss=      "/data/swissprot" if (! defined $dirSwiss       || $dirSwiss       eq "def");
    $dirPdb=        "/data/pdb"       if (! defined $dirPdb         || $dirPdb         eq "def");
    $exeConvSeq=    "/home/rost/pub/phd/bin/convert_seq.".$ARCH 
	                              if (! defined $exeConvSeq     || $exeConvSeq     eq "def");
    $exeBlastp=     "/home/phd/bin/".  $ARCH."/blastp"
	                              if (! defined $exeBlastp      || $exeBlastp      eq "def");
    $exeBlastpFil=  "/home/rost/pub/max/scr/filter_blastp" 
                                      if (! defined $exeBlastpFil   || $exeBlastpFil   eq "def");
    $exeMax=        "/home/rost/pub/max/bin/maxhom.".$ARCH
                                      if (! defined $exeMax         || $exeMax         eq "def");
    $envBlastpMat=  "/home/pub/molbio/blast/blastapp/matrix"  
                                      if (! defined $envBlastpMat   || $envBlastpMat   eq "def");
    $envBlastpDb=   "/data/db/"       if (! defined $envBlastpDb    || $envBlastpDb    eq "def");
    $parBlastpNhits="2000"            if (! defined $parBlastpNhits || $parBlastpNhits eq "def");
    $parBlastpDb=   "swiss"           if (! defined $parBlastpDb    || $parBlastpDb    eq "def");
    $fileMaxDef=    "/home/rost/pub/max/maxhom.default" 
	                              if (! defined $fileMaxDef     || $fileMaxDef     eq "def");
    $fileMaxMetr=   "/home/rost/pub/max/mat/Maxhom_GCG.metric" 
	                              if (! defined $fileMaxMetr    || $fileMaxMetr    eq "def");
    $Lprof=         "NO"              if (! defined $Lprof          || $Lprof          eq "def");
    $parMaxThresh= 30                 if (! defined $parMaxThresh   || $parMaxThresh   eq "def");
    $parMaxSmin=   -0.5               if (! defined $parMaxSmin     || $parMaxSmin     eq "def");
    $parMaxSmax=    1.0               if (! defined $parMaxSmax     || $parMaxSmax     eq "def");
    $parMaxGo=      3.0               if (! defined $parMaxGo       || $parMaxGo       eq "def");
    $parMaxGe=      0.1               if (! defined $parMaxGe       || $parMaxGe       eq "def");
    $parMaxW1=      "YES"             if (! defined $parMaxW1       || $parMaxW1       eq "def");
    $parMaxW2=      "NO"              if (! defined $parMaxW2       || $parMaxW2       eq "def");
    $parMaxI1=      "YES"             if (! defined $parMaxI1       || $parMaxI1       eq "def");
    $parMaxI2=      "NO"              if (! defined $parMaxI2       || $parMaxI2       eq "def");
    $parMaxNali=  500                 if (! defined $parMaxNali     || $parMaxNali     eq "def");
    $parMaxSort=    "DISTANCE"        if (! defined $parMaxSort     || $parMaxSort     eq "def");
    $parMaxProfOut= "NO"              if (! defined $parMaxProfOut  || $parMaxProfOut  eq "def");
    $parMaxStripOut="NO"              if (! defined $parMaxStripOut || $parMaxStripOut eq "def");
    $parMinLaliPdb=30                 if (! defined $parMinLaliPdb  || $parMinLaliPdb  eq "def");
    $parMaxTimeOut= "50000"           if (! defined $parMaxTimeOut  || $parMaxTimeOut  eq "def");
				# ------------------------------
				# check existence of files/dirs
    return(0,"*** $sbrName: miss in dir '$dirData'!")      if (! -d $dirData);
    return(0,"*** $sbrName: miss in dir '$dirSwiss'!")     if (! -d $dirSwiss);
    return(0,"*** $sbrName: miss in dir '$dirPdb'!")       if (! -d $dirPdb);
    return(0,"*** $sbrName: miss in dir '$envBlastpMat'!") if (! -d $envBlastpMat);
    return(0,"*** $sbrName: miss in dir '$envBlastpDb'!")  if (! -d $envBlastpDb);
    return(0,"*** $sbrName: miss in file '$fileSeqLoc'!")  if (! -e $fileSeqLoc);
    return(0,"*** $sbrName: miss in file '$exeConvSeq'!")  if (! -e $exeConvSeq);
    return(0,"*** $sbrName: miss in file '$exeBlastp'!")   if (! -e $exeBlastp);
    return(0,"*** $sbrName: miss in file '$exeBlastpFil'!")if (! -e $exeBlastpFil);
    return(0,"*** $sbrName: miss in file '$fileMaxDef'!")  if (! -e $fileMaxDef);
    return(0,"*** $sbrName: miss in file '$fileMaxMetr'!") if (! -e $fileMaxMetr);

    $msgHere="--- $sbrName started\n";
    $#fileTmp=0;
				# ------------------------------
    $Lok=			# security check: is FASTA?
	&isFasta($fileSeqLoc);
				# ------------------------------
    if (!$Lok){			# not: convert_seq -> FASTA
	$msgHere.="\n--- $sbrName \t call fortran convert_seq ($exeConvSeq,".
	    $fileSeqLoc.",".$fileSeqFasta.",$fhErrSbr)\n";
	($Lok,$msg)=		# call FORTRAN shit to convert to FASTA
	    &convSeq2fasta($exeConvSeq,$fileSeqLoc,$fileSeqFasta,$fhErrSbr);
				# conversion failed!
	if    ( ! $Lok || ! -e $fileSeqFasta){
	    return(0,"wrong conversion (convSeq2fasta)\n".
		   "*** $sbrName: fault in convert_seq ($exeConvSeq)\n$msg\n"."$msgHere");}
	elsif ($LcleanUpLoc) {
	    push(@fileTmp,$fileSeqFasta);}}
    else {
	($Lok,$msg)=
	    &fileCp($fileSeqLoc,$fileSeqFasta,$fhErrSbr);}
    if (! $Lok){
	return(0,"*** ERROR $sbrName '&fileCp($fileSeqLoc,$fileSeqFasta,$fhErrSbr)'\n".
	       "*** $sbrName: fault in convert_seq ($exeConvSeq)\n"."$msg\n"."$msgHere");}
				# --------------------------------------------------
                                # pre-filter to speed up MaxHom (BLAST)
				# --------------------------------------------------
    $msgHere.="\n--- $sbrName \t run BLASTP ($dirData,$dirSwiss,$exeBlastp,$exeBlastpFil,".
	"$envBlastpMat,$envBlastpDb,$parBlastpNhits,$parBlastpDb,".
	    $fileSeqLoc.",".$fileBlast.",".$fileBlastFil.",$fhErrSbr)\n";
    ($Lok,$msg)=
	&blastpRun($nice,$dirData,$dirSwiss,$exeBlastp,$exeBlastpFil,
		   $envBlastpMat,$envBlastpDb,$parBlastpNhits,$parBlastpDb,
		   $fileSeqFasta,$fileBlast,$fileBlastFil,$fhErrSbr);
    if (! $Lok || ! -e $fileBlastFil){
	return(0,"*** $sbrName: after blastpRun $msg"."\n"."$msgHere");}
    push(@fileTmp,$fileBlast,$fileBlastFil) if ($LcleanUpLoc);

				# --------------------------------------------------
				# now run MaxHom
				# --------------------------------------------------
    $thresh=&maxhomGetThresh($parMaxThresh);	# get the threshold
				# ------------------------------
				# get the arguments for the MAXHOM csh
#    $msgHere.="\n--- $sbrName \t run maxhomRunLoop($date,$nice,$exeMax,$fileMaxDef,$jobid,".
    $msgHere2="\n--- $sbrName \t run maxhomRunLoop($date,$nice,$exeMax,$fileMaxDef,$jobid,".
	"$jobid,$fileSeqLoc,$fileBlastFil,$fileHssp,$fileMaxMetr,$dirPdb,$Lprof,$parMaxSmin,".
	    "$parMaxSmax,$parMaxGo,$parMaxGe,$parMaxW1,$parMaxW2,$parMaxI1,$parMaxI2,".
		"$parMaxNali,$thresh,$parMaxSort,$parMaxProfOut,$parMaxStripOut,".
		    "$parMinLaliPdb,parMaxTimeOut,$fhErrSbr)\n";
				# ------------------------------------------------------------
				# now run it (will also run Self if missing output
				# note: if pdbidFound = 0, then none found!
    ($Lok,$pdbidFound)=
	&maxhomRunLoop($date,$nice,$exeMax,$fileMaxDef,$jobid,$fileSeqLoc,$fileBlastFil,$fileHssp,
		       $fileMaxMetr,$dirPdb,$Lprof,$parMaxSmin,$parMaxSmax,$parMaxGo,$parMaxGe,
		       $parMaxW1,$parMaxW2,$parMaxI1,$parMaxI2,$parMaxNali,$thresh,$parMaxSort,
		       $parMaxProfOut,$parMaxStripOut,$parMinLaliPdb,parMaxTimeOut,$fhErrSbr);
				# enf of Maxhom
				# ------------------------------------------------------------
    if (! $Lok){
	return(0,"error","*** ERROR $sbrName maxhomRunLoop failed, pdbidFound=$pdbidFound\n".
	       $msgHere2."\n");}
    if (! -e $fileHssp){
	return(0,"error",
	       "*** ERROR $sbrName maxhomRunLoop no $fileHssp, pdbidFound=$pdbidFound\n");}
    if ($LcleanUpLoc){
	foreach $file(@fileTmp){
	    next if (! -e $file);
	    unlink ($file) ; $msgHere.="--- $sbrName: unlink($file)\n";}
	system("\\rm MAX*$jobid");
	$msgHere.="--- $sbrName: system '\\rm MAX*$jobid'\n" ;}
    return(1,"ok","$sbrName\n".$msgHere);
}				# end of maxhomRun

#===============================================================================
sub maxhomRunLoop {
    local ($date,$niceL,$exeMaxL,$fileMaxDefL,$fileJobIdL,
	   $fileHsspInL,$fileHsspAliListL,$fileHsspOutL,$fileMaxMetricL,$dirMaxPdbL,
	   $LprofileL,$paraSminL,$paraSmaxL,$paraGoL,$paraGeL,$paraW1L,$paraW2L,
	   $paraIndel1L,$paraIndel2L,$paraNaliL,$paraThreshL,$paraSortL,$paraProfOutL,
	   $fileStripOutL,$fileFlagNoHsspL,$paraMinLaliPdbL,$paraTimeOutL,$fhTraceLoc)=@_;
    local ($maxCmdL,$start_at,$alarm_sent,$alarm_timer,$thresh_txt);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   maxhomRunLoop               loops over a maxhom run (until paraTimeOutL = 3hrs)
#       in:                     see program...
#       out:                    (0,'error message',0), (1,'error in pdbid',1), 
#       out:                    (1,0|pdbidFound,0|1) last arg=0 if self, =1 if ali
#       err:                    ok=(1,'ok|pdbid',0|1), err=(0,'msg',0)
#--------------------------------------------------------------------------------
    $sbrName="maxhomRunLoop";
    return(0,"*** $sbrName: not def niceL!",0)            if (! defined $niceL);
    return(0,"*** $sbrName: not def exeMaxL!",0)          if (! defined $exeMaxL);
    return(0,"*** $sbrName: not def fileMaxDefL!",0)      if (! defined $fileMaxDefL);
    return(0,"*** $sbrName: not def fileJobIdL!",0)       if (! defined $fileJobIdL);
    return(0,"*** $sbrName: not def fileHsspInL!",0)      if (! defined $fileHsspInL);
    return(0,"*** $sbrName: not def fileHsspAliListL!",0) if (! defined $fileHsspAliListL);
    return(0,"*** $sbrName: not def fileHsspOutL!",0)     if (! defined $fileHsspOutL);
    return(0,"*** $sbrName: not def fileMaxMetricL!",0)   if (! defined $fileMaxMetricL);
    return(0,"*** $sbrName: not def dirMaxPdbL!",0)       if (! defined $dirMaxPdbL);
    return(0,"*** $sbrName: not def LprofileL!",0)        if (! defined $LprofileL);
    return(0,"*** $sbrName: not def paraSminL!",0)        if (! defined $paraSminL);
    return(0,"*** $sbrName: not def paraSmaxL!",0)        if (! defined $paraSmaxL);
    return(0,"*** $sbrName: not def paraGoL!",0)          if (! defined $paraGoL);
    return(0,"*** $sbrName: not def paraGeL!",0)          if (! defined $paraGeL);
    return(0,"*** $sbrName: not def paraW1L!",0)          if (! defined $paraW1L);
    return(0,"*** $sbrName: not def paraW2L!",0)          if (! defined $paraW2L);
    return(0,"*** $sbrName: not def paraIndel1L!",0)      if (! defined $paraIndel1L);
    return(0,"*** $sbrName: not def paraIndel2L!",0)      if (! defined $paraIndel2L);
    return(0,"*** $sbrName: not def paraNaliL!",0)        if (! defined $paraNaliL);
    return(0,"*** $sbrName: not def paraThreshL!",0)      if (! defined $paraThreshL);
    return(0,"*** $sbrName: not def paraSortL!",0)        if (! defined $paraSortL);
    return(0,"*** $sbrName: not def paraProfOutL!",0)     if (! defined $paraProfOutL);
    return(0,"*** $sbrName: not def fileStripOutL!",0)    if (! defined $fileStripOutL);
    return(0,"*** $sbrName: not def fileFlagNoHsspL!",0)  if (! defined $fileFlagNoHsspL);
    return(0,"*** $sbrName: not def paraMinLaliPdbL!",0)  if (! defined $paraMinLaliPdbL);

    return(0,"*** $sbrName: not def paraTimeOutL!",0)     if (! defined $paraTimeOutL);
    $fhTraceLoc="STDOUT"                                     if (! defined $fhTraceLoc);
				# check existence of files
    return(0,"*** $sbrName: miss input file '$fileHsspInL'!",0)      if (! -e $fileHsspInL);
    return(0,"*** $sbrName: miss input exe  '$exeMaxL'!",0)          if (! -e $exeMaxL);
    return(0,"*** $sbrName: miss input file '$fileMaxDefL'!",0)      if (! -e $fileMaxDefL);
    return(0,"*** $sbrName: miss input file '$fileHsspAliListL'!",0) if (! -e $fileHsspAliListL);
    return(0,"*** $sbrName: miss input file '$fileMaxMetricL'!",0)   if (! -e $fileMaxMetricL);
    $pdbidFound="";
    $LisSelf=0;			# is PDBid in HSSP? / are homologues?

				# ------------------------------
				# set the elapse time in seconds before an alarm is sent
#    $paraTimeOutL= 10000;	# ~ 3 heures
    $msgHere="";
				# ------------------------------
				# (1) build up MaxHom input
    ($msg,$warn)=		# check existence of files asf
	&maxhomGetArgCheck($exeMaxL,$fileMaxDefL,$fileHsspInL,$fileHsspAliListL,
			   $fileMaxMetricL);
    if (length($msg)>1){
	return(0,"$msg",0);} $msgHere.="--- $sbrName $warn\n";
    
    $maxCmdL=			# get command line argument for starting MaxHom
	&maxhomGetArg($niceL,$exeMaxL,$fileMaxDefL,$fileJobIdL,$fileHsspInL,$fileHsspAliListL,
		      $LprofileL,$fileMaxMetricL,$paraSminL,$paraSmaxL,$paraGoL,$paraGeL,
		      $paraW1L,$paraW2L,$paraIndel1L,$paraIndel2L,$paraNaliL,$paraThreshL,
		      $paraSortL,$fileHsspOutL,$dirMaxPdbL,$paraProfOutL,$fileStripOutL);
				# --------------------------------------------------
				# the thing that does IT!
				# --------------------------------------------------
    while ( ! -f $fileHsspOutL ) { 
	$msgHere.="--- $sbrName \t first trial to get $fileHsspOutL\n";
	$Lok=
	    &run_program("$maxCmdL",$fhTraceLoc); # its running!
#	if (! $Lok){
#	    return(0,"*** $sbrName no maxhom on \n$maxCmdL\n"."$msgHere",0);} 
				# ------------------------------
				# no HSSP file -> loop
	if ( ! -f $fileHsspOutL ) {
	    if (!$start_at) {	# switch a timer on
		$start_at= time(); }
				# test if an alarm is needed
	    if (!$alarm_sent && (time() - $start_at) > $paraTimeOutL) {
				# **************************************************
				# NOTE this SBR is PP specific
				# **************************************************
		&ctrlAlarm("SUICIDE: In max_loop for more than $alarm_timer... (killer!)".
			   "$msgHere");
		$alarm_sent=1;
		return(0,"maxhom SUICIDE on $fileHsspOutL".$msgHere,0); }
				# create a trace file
	    open("NOHSSP","> $fileFlagNoHsspL") || 
		warn "-*- $sbrName WARNING cannot open $fileFlagNoHsspL: $!\n";
	    print NOHSSP " problem with maxhom ($fileHsspOutL)\n"," $date\n";
	    print NOHSSP `ps -ela`;
	    sleep 10;
	    close(NOHSSP);
	    unlink ($fileFlagNoHsspL); }
    }				# end of loop 

				# --------------------------------------------------
    if (-e $fileHsspOutL){	# is HSSP file -> check
	($Lok,$kwd,$msg)=
	    &maxhomCheckHssp($fileHsspOutL,$paraMinLaliPdbL);
	return(0,"*** $sbrName ERROR after 'maxhomCheckHssp: ".
	       "kwd=$kwd, msg=$msg'\n".$msgHere,0) if (! $Lok);}
    else {return(0,"*** $sbrName ERROR after loop: no HSSP $fileHsspOutL".
		 $msgHere,0);}
				# --------------------------------------------------
				# maxhom against itself (no homologues found)
    if ($kwd eq "empty") {	# => no ali
	$LisSelf=1;$LisPdb=0;$pdbidFound=" ";
	($Lok,$msg)=
	    &maxhomRunSelf($niceL,$exeMaxL,$fileMaxDefL,$fileJobIdL,$fileHsspInL,
			   $fileMaxMetricL,$fileHsspOutL,$fhTraceLoc);
	return(0,"*** ERROR $sbrName 'maxhomRunSelf' wrong".
	       $msg."\n".$msgHere,0) if (! $Lok || ! -e $fileHsspOutL);}
    elsif ($kwd eq "self"){ # is self already
	$LisSelf=1;$LisPdb=0;$pdbidFound=" ";}
    elsif ($kwd eq "pdbid"){
	$tmp=$msg;$tmp=~s/^pdbid=([^\n]*)\n.*$/$1/;
	$LisSelf=0;$LisPdb=1;$pdbidFound=$tmp;}
    elsif ($kwd eq "ok"){
	$LisSelf=0;$LisPdb=0;$pdbidFound=" ";}
    else {
	return(0,"*** $sbrName ERROR after 'maxhomCheckHssp: kwd=$kwd, unclear\n".
	       "msg=$msg\n".$msgHere,0) if (! $Lok);}

    if    ($LisPdb){
	if    (! defined $pdbidFound || length($pdbidFound)<4){
	    return(1,"error in pdbid",0);} # error
	elsif (defined $pdbidFound && length($pdbidFound)>4 && ! $LisSelf){
	    return(1,"$pdbidFound",0);}	# PDBid + ali
	return(1,"$pdbidFound",1);} # appears to be PDB but no ali
    elsif ($LisSelf){
	return(1,0,1);}		# no ali
    return(1,0,0);		# ok
}				# end maxhomRunLoop

#===============================================================================
sub maxhomRunSelf {
    local($niceLoc,$exeMaxLoc,$fileMaxDefLoc,$fileJobIdLoc,$fileHsspInLoc,
	  $fileHsspOutLoc,$fileMaxMetrLoc,$fhTraceLoc)=@_;
    local($sbrName,$msgHere,$msg,$tmp,$Lok,$LprofileLoc,$dirMaxPdbLoc,$paraMaxProfOutLoc,
	  $paraMaxSminLoc,$paraMaxSmaxLoc,$paraMaxGoLoc,$paraMaxGeLoc,
	  $paraMaxW1Loc,$paraMaxW2Loc,$paraMaxIndel1Loc,$paraMaxIndel2Loc,
	  $paraMaxNaliLoc,$paraMaxThreshLoc,$paraMaxSortLoc,$fileStripOutLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   maxhomRunSelf               runs a MaxHom: search seq against itself
#                               NOTE: needs to run convert_seq to make sure
#                                     that 'itself' is in FASTA format
#       in:                     many
#       out:                    
#       err:                    ok=(1,'ok'), err=(0,'msg')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:maxhomRunSelf";
    return(0,"*** $sbrName: not def niceLoc!")            if (! defined $niceLoc);
    return(0,"*** $sbrName: not def exeMaxLoc!")          if (! defined $exeMaxLoc);
    return(0,"*** $sbrName: not def fileMaxDefLoc!")      if (! defined $fileMaxDefLoc);
    return(0,"*** $sbrName: not def fileJobIdLoc!")       if (! defined $fileJobIdLoc);
    return(0,"*** $sbrName: not def fileHsspInLoc!")      if (! defined $fileHsspInLoc);
    return(0,"*** $sbrName: not def fileHsspOutLoc!")     if (! defined $fileHsspOutLoc);
    return(0,"*** $sbrName: not def fileMaxMetrLoc!")     if (! defined $fileMaxMetrLoc);
    $fhTraceLoc="STDOUT"                                  if (! defined $fhTraceLoc);
				# check existence of files
    return(0,"*** $sbrName: miss input file '$fileHsspInLoc'!")  if (! -e $fileHsspInLoc);
    return(0,"*** $sbrName: miss input exe  '$exeMaxLoc'!")      if (! -e $exeMaxLoc);
    return(0,"*** $sbrName: miss input file '$fileMaxDefLoc'!")  if (! -e $fileMaxDefLoc);
    return(0,"*** $sbrName: miss input file '$fileMaxMetrLoc'!") if (! -e $fileMaxMetrLoc);
    $msgHere="";
				# ------------------------------
				# security check: is FASTA?
#    $Lok=&isFasta($fileHsspInLoc);
#    if (!$Lok){
#	return(0,"*** $sbrName: input must be FASTA '$fileHsspInLoc'!");}
				# ------------------------------
				# prepare MaxHom
    ($msg,$warn)=		# check existence of files asf
	&maxhomGetArgCheck($exeMaxLoc,$fileMaxDefLoc,$fileHsspInLoc,$fileHsspInLoc,
			   $fileMaxMetrLoc);
    if (length($msg)>1){
	return(0,"$msg");} $msgHere.="--- $sbrName $warn\n";

    $LprofileLoc=      "NO";	# build up argument
    $paraMaxSminLoc=   "-0.5";     $paraMaxSmaxLoc=   "1";
    $paraMaxGoLoc=     "3.0";      $paraMaxGeLoc=     "0.1";
    $paraMaxW1Loc=     "YES";      $paraMaxW2Loc=     "NO";
    $paraMaxIndel1Loc= "NO";       $paraMaxIndel2Loc= "NO";
    $paraMaxNaliLoc=   "5";        $paraMaxThreshLoc= "ALL";
    $paraMaxSortLoc=   "DISTANCE"; $dirMaxPdbLoc=     "/data/pdb/";
    $paraMaxProfOutLoc="NO";       $fileStripOutLoc=  "NO";
				# --------------------------------------------------
    $maxCmdLoc=			# get command line argument for starting MaxHom
	&maxhomGetArg($niceLoc,$exeMaxLoc,$fileMaxDefLoc,$fileJobIdLoc,
		      $fileHsspInLoc,$fileHsspInLoc,$LprofileLoc,$fileMaxMetrLoc,
		      $paraMaxSminLoc,$paraMaxSmaxLoc,$paraMaxGoLoc,$paraMaxGeLoc,
		      $paraMaxW1Loc,$paraMaxW2Loc,$paraMaxIndel1Loc,$paraMaxIndel2Loc,
		      $paraMaxNaliLoc,$paraMaxThreshLoc,$paraMaxSortLoc,
		      $fileHsspOutLoc,$dirMaxPdbLoc,$paraMaxProfOutLoc,$fileStripOutLoc);
				# --------------------------------------------------
    $Lok=			# run maxhom self
	&run_program("$maxCmdLoc",$fhTraceLoc,"warn");
    if (! $Lok || ! -e $fileHsspOutLoc){ # output file missing
	return(0,"*** $sbrName: fault in maxhom ($exeMaxLoc)\n");}
    return(1,"ok $sbrName");
}				# end of maxhomRunSelf

#===============================================================================
sub metric_ini {
#--------------------------------------------------------------------------------
#   metric_ini                  initialise the metric reading ($string_aa returned=)
#--------------------------------------------------------------------------------
    $string_aa="VLIMFWYGAPSTCHRKQENDBZ";
    return $string_aa;
}				# end of metric_ini

#===============================================================================
sub metric_norm_minmax {
    local ($min_out,$max_out,$aa,%metric) = @_ ;
    local (@key,$key,$min,$max,$fac,$sub,$Lscreen,%metricnorm,$Lerr,$aa1,$aa2,@aa);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   metric_norm_minmax          converting profiles (min <0, max>0) to percentages (0,1)
#--------------------------------------------------------------------------------
    $Lscreen=0;
    @aa=split(//,$aa);
				# ------------------------------
				# figuring out current min/max
				# ------------------------------
    $min=$max=0;
    foreach $aa1(@aa){foreach $aa2(@aa){
	if    ($metric{"$aa1","$aa2"} < $min) { $min=$metric{"$aa1","$aa2"};}
	elsif ($metric{"$aa1","$aa2"} > $max) { $max=$metric{"$aa1","$aa2"};}
    }}
				# ------------------------------
				# normalising
				# x' = D*x - ( D*xmax - maxout ), D=(maxout-minout)/(xmax-xmin)
				# ------------------------------
    $fac= ($max_out-$min_out) / ($max-$min);
    $sub= ($fac*$max) - $max_out;
    if ($Lscreen) { print  "--- in get_metricnorm\t ";
		    printf "min=%5.2f, max=%5.2f, desired min_out=%5.2f, max_out=%5.2f\n",
		    $min,$max,$min_out,$max_out;
		    print  "--- normalise by: \t x' = f * x - ( f * xmax -max_out ) \n";
		    printf "--- where: \t \t fac=%5.2f, and (f*xmax-max_out)=%5.2f\n",$fac,$sub; }

    $min=$max=0;		# for error check
    foreach $aa1(@aa){foreach $aa2(@aa){
	$metricnorm{"$aa1","$aa2"}=($fac*$metric{"$aa1","$aa2"}) - $sub;
	if    ($metricnorm{"$aa1","$aa2"}<$min) {$min=$metricnorm{"$aa1","$aa2"};}
	elsif ($metricnorm{"$aa1","$aa2"}>$max) {$max=$metricnorm{"$aa1","$aa2"};}
    }}
				# --------------------------------------------------
				# error check
				# --------------------------------------------------
    $Lerr=0;
    if ( ! &equal_tolerance($min,$min_out,0.0001) ){$Lerr=1;
		     print"*** ERROR get_metricnorm: after min=$min, but desired is=$min_out,\n";}
    if ( ! &equal_tolerance($max,$max_out,0.0001) ){$Lerr=1;
		     print"*** ERROR get_metricnorm: after max=$max, but desired is=$max_out,\n";}
    if ($Lerr) {exit;}
    return %metricnorm;
}				# end of metric_norm_minmax

#===============================================================================
sub metric_rd {
    local ($file_metric) = @_ ;
    local (@tmp,$aa1,$aa2,$fhin,$tmp,$string_aa,@aa,%metric);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   metric_rd                   reads a Maxhom formatted sequence metric
#--------------------------------------------------------------------------------
    $fhin="FHIN_RD_METRIC";
    $string_aa=&metric_ini;
    if (-e $file_metric){
	&open_file("$fhin","$file_metric");
	while(<$fhin>){$tmp=$_;last if (/^AA /);}
				# ------------------------------
				# read acid symbol
	$tmp=~s/\n//g;
	$tmp=~s/^\s*|\s*$//g;	# deleting leading blanks
	$#tmp=0;@tmp=split(/\s+/);
	$#aa=0;
	foreach $it (4 .. $#tmp){
	    push(@aa,$tmp[$it]);
	}
	while(<$fhin>){
	    $_=~s/\n//g;
	    $_=~s/^\s*|\s*$//g;	# deleting leading blanks
	    $#tmp=0;@tmp=split(/\s+/);
	    foreach $it (1 .. $#aa){
		$metric{"$tmp[1]","$aa[$it]"}=$tmp[$it+1];
	    }
	}
	close($fhin);}
    else {
	print"*** ERROR in metric_rd (lib-br): '$file_metric' missing\n"; }
				# ------------------------------
				# identity metric
    if (0){
	@tmp=split(//,$string_aa);
	foreach $aa1 (@tmp){ foreach $aa2 (@tmp){ 
	    if ($aa1 eq $aa2){ $metric{"$aa1","$aa2"}=1;}
	    else {$metric{"$aa1","$aa2"}=0;}
	}}
    }
    return(%metric);
}				# end of metric_rd

#===============================================================================
sub metricRdbRd {
    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   metricRdbRd                 reads an RDB formatted substitution metric, e.g.
#                               written by: lib-br:stat2DarrayWrt
#       in:                     $fileInLoc
#       out:                    1|0,msg,$tmp{}
#                               $tmp{"aa1","aa2"} = mat for aa1 -> aa2
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."metricRdbRd";$fhinLoc="FHIN_"."metricRdbRd";
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
#    return(&errSbr("not def !"))          if (! defined $);

    return(&errSbr("miss in file '$fileInLoc'!"))  if (! -e $fileInLoc);

    undef %tmp; undef %ptrLoc;
    @aaLoc=split(//,"VLIMFWYGAPSTCHRKQEND");
				# ------------------------------
				# open file
    &open_file("$fhinLoc","$fileInLoc") || return(&errSbr("fileInLoc=$fileInLoc, not opened"));
    $ct=0;			# ------------------------------
    while (<$fhinLoc>) {	# read file
	$_=~s/\n//g;
	next if ($_ =~ /^\#/);	# skip comments
				# names
	if (! defined %ptrLoc){ $_=~s/^\s*|\s*$//g;	# purge leading blanks
				@tmp=split(/[\s\t]+/,$_);
				foreach $it (1..$#tmp) {
				    next if ($tmp[$it] !~ /^aa$/ && $tmp[$it] !~ /^[A-Z]$/);
				    if ($tmp[$it] =~ /^aa$/) { $ptrLoc{"aa"}=$it;
							       next; }
				    $ptrLoc{"$tmp[$it]"}=$it; } # amino acid pointer
				next; }
				# formats, if so: skip
	next if (! $ct && $_ =~ /\d+[NSF][\t]|[\t]\d+[NSF]/);
				# --------------------
				# now data
	$_=~s/^\s*|\s*$//g;	# purge leading blanks
	@tmp=split(/[\s\t]+/,$_);
	$res=$tmp[$ptrLoc{"aa"}];
	foreach $it (1..20)  {  $ptr=$ptrLoc{"$aaLoc[$it]"}; # from aa to column number
				$tmp[$ptr]=~s/\s//g; # purge blanks from number
				$tmp{"$res","$aaLoc[$it]"}=$tmp[$ptr]; } # now get into final
    } close($fhinLoc);

    return(1,"ok $sbrName",%tmp);
}				# end of metricRdbRd


#===============================================================================
sub month2num {
    local($nameIn) = @_ ;
    local($sbrName,%tmp);
#-------------------------------------------------------------------------------
#   month2num                   converts name of month to number
#       in:                     Jan (or january)
#       out:                    1
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."month2num";$fhinLoc="FHIN"."$sbrName";
    return(0) if (! defined $nameIn);
    $nameIn=~tr/[A-Z]/[a-z]/;	# all small letters
    $nameIn=substr($nameIn,1,3);
    %tmp=('jan',1,'feb',2,'mar',3,'apr', 4,'may', 5,'jun',6,
	  'jul',7,'aug',8,'sep',9,'oct',10,'nov',11,'dec',12);
    return($tmp{"$nameIn"});
}				# end of month2num

#===============================================================================
sub msfBlowUp {
    local($fileInLoc,$fileOutLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   msfBlowUp                   duplicates guide sequence for conversion to HSSP
#       in:                     $fileInLoc,$fileOutLoc
#       out:                    1|0, msg, 
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."msfBlowUp";
    $fhinLoc="FHIN_"."msfBlowUp";$fhoutLoc="FHOUT_"."msfBlowUp";
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc!")          if (! defined $fileInLoc);
    return(0,"*** $sbrName: not def fileOutLoc!")         if (! defined $fileOutLoc);

    return(0,"*** $sbrName: miss in file '$fileInLoc'!")  if (! -e $fileInLoc);

    ($Lok,$msg,%msfIn)=&msfRd($fileInLoc);
    return(0,"*** ERROR $sbrName: msfRd \n".$msg."\n") if (! $Lok);
    
    &open_file("$fhoutLoc",">$fileOutLoc") ||
	return(0,"*** ERROR $sbrName: fileNew=$fileOutLoc, not opened\n");

    $name=$msfIn{"id","1"};
    $namex=substr($name,1,(length($name)-1))."x";
    $tmp{"1"}=$name;
    $tmp{"2"}=$namex;
    $tmp{$name}=    $msfIn{"seq","1"};
    $tmp{$namex}=   $msfIn{"seq","1"};
    $tmp{"NROWS"}=  2;
    $tmp{"FROM"}=   $fileInLoc;
    $tmp{"TO"}=     $fileOutLoc;
    undef %msfIn;		# save memory
				# write msf
    open ("$fhoutLoc",">$fileOutLoc") ||
        return(0,"*** ERROR $sbrName: failed opening new '$fileOutLoc'\n") ;
    ($Lok,$msg)=&msfWrt($fhoutLoc,%tmp);close($fhoutLoc);

    return(0,"*** ERROR $sbrName: failed to write $fileOutLoc, \n".$msg."\n") 
	if (! $Lok || ! -e $fileOutLoc);
    return(1,"ok $sbrName");
}				# end of msfBlowUp

#===============================================================================
sub msfCheckFormat {
    local ($fileMsf) = @_;
    local ($format,$tmp,$kw_msf,$kw_check,$ali_sec,$ali_des_sec,$valid_id_len,$fhLoc,
	   $uniq_id, $same_nb, $same_len, $nb_al, $seq_tmp, $seql, $ali_des_len);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   msfCheckFormat              basic checking of msf file format
#           - mandatory keywords and values (MSF: val, Check: val)
#           - alignment description start after "..", each line with the following structure:
#             Name: id Len: val Check: val Weight: val (and all ids diferents)
#           - alignment same number of line for each id (>0)
#       in:                     $fileMsf
#       out:                    return 1  if format seems OK, 0 else
#--------------------------------------------------------------------------------
    $sbrNameLoc="msfCheckFormat";
                                # ----------------------------------------
                                # initialise the flags
                                # ----------------------------------------
    $fhLoc="FHIN_CHECK_MSF_FORMAT";
    $kw_msf=$kw_check=$ali_sec=$ali_des_sec=$ali_des_seq=$nb_al=0;
    $format=1;
    $valid_id_len=1;		# sequence name < 15 characters
    $uniq_id=1;			# id must be unique
    $same_len=1;		# each seq must have the same len
    $lenok=1;			# length in header and of sequence differ
                                # ----------------------------------------
                                # read the file
                                # ----------------------------------------
    open ($fhLoc,$fileMsf)  || 
	return(0,"*** $sbrNameLoc cannot open fileMsf=$fileMsf\n");
    while (<$fhLoc>) {
	$_=~s/\n//g;
	$tmp=$_;$tmp=~ tr/a-z/A-Z/;
                                # MSF keyword and value
	$kw_msf=1    if (!$ali_des_seq && ($tmp =~ /MSF:\s*\d*\s/));
	next if (!$kw_msf);
                         	# CHECK keyword and value
	$kw_check=1  if (!$ali_des_seq && ($tmp =~ /CHECK:\s*\d*/));
	next if (!$kw_check);
                         	# begin of the alignment description section 
                         	# the line with MSF and CHECK must end with ".."
	if (!$ali_sec && $tmp =~ /MSF:\D*(\d*).*CHECK:.*\.\.\s*$/) {
	    $ali_des_len=$1;$ali_des_sec=1;}
                                # ------------------------------
                         	# the alignment description section
	if (!$ali_sec && $ali_des_sec) { 
            if ($tmp=~ /^\s*NAME:\s*(\S*).*LEN:.*\d.*CHECK:.*\d.*WEIGHT:.*\d.*/) {
		$id=$1;
		$valid_id_len=0 if (length($id) > 14);	# is sequence name <= 14
		if ($SEQID{$id}) { # is the sequence unique?
		    $uniq_id=0; $ali_sec=1;
		    last; }
		$lenRd=$tmp;$lenRd=~s/^.*LEN\:\s*(\d+)\s*CHEC.*$/$1/;
		$SEQID{$id}=1; # store seq ID
		$SEQL{$id}= 0;	# initialise seq len array
	    } }
                                # ------------------------------
                        	# begin of the alignment section
	$ali_sec=1    if ($ali_des_sec && $tmp =~ /\/\/\s*$/);
                                # ------------------------------
                        	# the alignment section
	if ($ali_sec) {
	    if ($tmp =~ /^\s*(\S+)\s+(.*)$/) {
		$id= $1;
		if ($SEQID{$id}) {++$SEQID{$id};
				  $seq_tmp= $2;$seq_tmp=~ s/\s|\n//g;
				  $SEQL{$id}+= length($seq_tmp);}}}
    }close($fhLoc);
                                # ----------------------------------------
                                # test if all sequences are present the 
				# same number of time with the same length
                                # ----------------------------------------
    if ($kw_msf && $kw_check && $ali_des_sec && $uniq_id && $valid_id_len){
	foreach $id (keys %SEQID) {
	    $nb_al= $SEQID{$id} if (!$nb_al);
	    if ($SEQID{$id} < 2 || $SEQID{$id} != $nb_al) {
		$same_len=0;
		last; }
	    if ($SEQL{$id} != $lenRd){
		$lenok=0;
		last;}}}
				# TEST ALL THE FLAGS
    $msg="";
    $msg.="*** $sbrNameLoc wrong MSF: no keyword MSF!\n"               if (!$kw_msf);
    $msg.="*** $sbrNameLoc wrong MSF: no keyword Check!\n"             if (!$kw_check);
    $msg.="*** $sbrNameLoc wrong MSF: no ali descr section!\n"         if (!$ali_des_sec);
    $msg.="*** $sbrNameLoc wrong MSF: no ali section!\n"               if (!$ali_sec); 
    $msg.="*** $sbrNameLoc wrong MSF: id not unique!\n"                if (!$uniq_id); 
    $msg.="*** $sbrNameLoc wrong MSF: seq name too long!\n"            if (!$valid_id_len);
    $msg.="*** $sbrNameLoc wrong MSF: varying length of seq!\n"        if (!$same_len);
    $msg.="*** $sbrNameLoc wrong MSF: length given and real differ!\n" if (!$lenok);
    return(0,$msg) if (length($msg)>1);
    return(1,"$sbrNameLoc ok");
}				# end msfCheckFormat


#===============================================================================
sub msfCountNali {
    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   msfCountNali                counts the number of alignments in MSF file
#       in:                     file
#       out:                    $nali,$msg if error
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."msfCountNali";$fhinLoc="FHIN_"."msfCountNali";
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc!")          if (! defined $fileInLoc);
    return(0,"*** $sbrName: miss in file '$fileInLoc'!")  if (! -e $fileInLoc);

    &open_file("$fhinLoc","$fileInLoc") ||
	return(0,"*** ERROR $sbrName: fileIn=$fileInLoc, not opened\n");

    $ct=0;                      # ------------------------------
    while (<$fhinLoc>) {        # read MSF
        ++$ct if ($_=~ /^\s*NAME:\s*(\S*).*LEN:.*\d.*CHECK:.*\d.*WEIGHT:.*\d.*/i);
        last if ($_=~/^\s*\//);
        next;} close($fhinLoc);
    return($ct);
}				# end of msfCountNali

#===============================================================================
sub msfRd {
    local ($fileInLoc) = @_ ;
    local ($sbrName,$Lok,$msg,$tmp,$fhout,$LfirstLine,$Lhead,
	   $Lguide,$seqGuide,$nameGuide);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   msfRd                       reads MSF files input format
#       in:                     $fileInLoc
#       out:                    ($Lok,$msg,$msfIn{}) with:
#       out:                    $msfIn{"NROWS"}  number of alignments
#       out:                    $msfIn{"id", "$it"} name for $it
#       out:                    $msfIn{"seq","$it"} sequence for $it
#       err:                    ok-> 1,ok | error -> 0,message
#-------------------------------------------------------------------------------
    $sbrName="lib-br:msfRd"; $fhinLoc="FHIN_"."msfRd";
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc!")          if (! defined $fileInLoc);
    return(0,"*** $sbrName: miss in file '$fileInLoc'!")  if (! -e $fileInLoc);

    &open_file("$fhinLoc","$fileInLoc") ||
	return(0,"*** ERROR $sbrName: fileIn=$fileInLoc, not opened\n");

    undef %msfIn;               # ------------------------------
    while (<$fhinLoc>) {	# read file
        last if ($_=~/^\s*\//); # skip everything before ali sections
    } undef %tmp;$ct=0;
    while (<$fhinLoc>) {	# read file
	$_=~s/\n//g;
        $_=~s/^\s*|\s*$//g;     # purge leading blanks
        $tmp=$_;$tmp=~s/\d//g;
        next if (length($tmp)<1); # skip lines empty or with numbers, only
                                # --------------------
				# from here on: 'id sequence'
        $id= $_; $id =~s/^\s*(\S+)\s*.*$/$1/;
        $seq=$_; $seq=~s/^\s*(\S+)\s+(\S.*)$/$2/;
        $seq=~s/\s//g;
        if (! defined $tmp{$id}){ # new
            ++$ct;$tmp{$id}=$ct;
            $msfIn{"id","$ct"}= $id;
            $msfIn{"seq","$ct"}=$seq;}
        else {
            $ptr=$tmp{$id};
            $msfIn{"seq","$ptr"}.=$seq;}}close($fhinLoc);

    $msfIn{"NROWS"}=$ct;
    return(1,"ok $sbrName",%msfIn);
}				# end of msfRd

#===============================================================================
sub msfWrt {
    local($fhoutLoc,%input) = @_ ;
    local(@nameLoc,@stringLoc,$tmp,$sbrName,$Lok);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   msfWrt                      writing an MSF formatted file of aligned strings
#         in:                   $fileMsf,$input{}
#                               $input{"NROWS"}  number of alignments
#                               $input{"FROM"}   name of input file
#                               $input{"TO"}     name of output file
#                               $input{"$it"}    sequence identifier ($name)
#                               $input{"$name"}  sequence for $name
#--------------------------------------------------------------------------------
    $sbrName="msfWrt";
				# ------------------------------
    $#nameLoc=$#tmp=0;		# process input
    foreach $it (1..$input{"NROWS"}){
	$name=$input{"$it"};
	push(@nameLoc,$name);	# store the names
	push(@stringLoc,$input{"$name"}); } # store sequences

    $FROM=$input{"FROM"}        if (defined $input{"FROM"});
    $TO=  $input{"TO"}          if (defined $input{"TO"});

				# ------------------------------
				# write into file
    print $fhoutLoc 
	"MSF of: ",$FROM," from:    1 to:   ",length($stringLoc[1])," \n",
	$TO," MSF: ",length($stringLoc[1]),
	"  Type: N  November 09, 1918 14:00 Check: 1933 ..\n \n \n";

    foreach $it (1..$#stringLoc){
	printf 
	    $fhoutLoc "Name: %-20s Len: %-5d Check: 2222 Weight: 1.00\n",
	    $nameLoc[$it],length($stringLoc[$it]); 
    }
    print $fhoutLoc " \n","\/\/\n"," \n";

    for($it=1;$it<=length($stringLoc[1]);$it+=50){
	foreach $it2 (1..$#stringLoc){
	    printf $fhoutLoc "%-20s",$nameLoc[$it2];
	    foreach $it3 (1..5){
		last if (length($stringLoc[$it2])<($it+($it3-1)*10));
		printf $fhoutLoc 
		    " %-10s",substr($stringLoc[$it2],($it+($it3-1)*10),10);}
	    print $fhoutLoc "\n";}
	print $fhoutLoc "\n"; }
    print $fhoutLoc "\n";
    close($fhoutLoc);
    $#nameLoc=$#stringLoc=0;	# save space
    return(1);
}				# end of msfWrt

#===============================================================================
sub msfCheckNames {
    local($fileInLoc,$fhErrSbr) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   msfCheckNames               reads MSF file and checks consistency of names
#       in:                     $fileMsf
#       out:                    (0,err=list of wrong names)(1,"ok")
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."msfCheckNames";$fhinLoc="FHIN"."$sbrName";

    $Lok=       &open_file("$fhinLoc","$fileInLoc");
    if (! $Lok){print $fhErrSbr "*** ERROR $sbrName: '$fileInLoc' not opened\n";
		return(0);}
    undef %name; $Lerr=$#name=0;
				# ------------------------------
    while (<$fhinLoc>) {	# read header
	$_=~s/\n//g;
				# read names in header
	if ($_=~/^\s*name\:\s*(\S+)/i){
	    $name{$1}=1;push(@name,$1);
				# ******************************
	    if (length($1)>=15){ # current GOEBEL limit!!!
		print "*** ERROR name must be shorter than 15 characters ($1)\n";
		print "***       it is ",length($1),"\n";
		$Lerr=1;}
	    if (! defined $len){ # sequence length
		$len=$_;$len=~s/^\s*[Nn]ame:\s*\S+\s+[Ll]en:\s*(\d+)\D.*$/$1/;}
	    next;}
	last if ($_=~/\/\//);}
    $ctBlock=0;undef %ctRes;	# ------------------------------
    while (<$fhinLoc>) {	# read body
	$_=~s/\n//g;$tmp=$_;$tmp=~s/\s//g;
	next if (length($tmp)<3);
	if ($_=~/^\s+\d+\s+/ && ($_!~/[A-Za-z]/)){
	    ++$ctBlock;$ctName=0; undef %ctName;
	    next;}
	$name=$_;$name=~s/^\s*(\S+)\s*.*$/$1/;
	$seq= $_;$seq =~s/^\s*\S+\s+//;$seq=~s/\s//g;
	$ctRes{$name}+=length($seq); # sequence length
	if (! defined $name{$name}){
	    print "*** block $ctBlock, name=$name not used before\n";
	    $Lerr=1;}
	else {
	    ++$ctName; 
	    if (! defined $ctName{$name} ){
		$ctName{$name}=1;} # 
	    else {print "*** block $ctBlock, name=$name more than once\n";
		  $Lerr=1;}}}close($fhinLoc);
    foreach $name(@name){
	if ($ctRes{$name} != $len){
	    print 
		"*** name=$name, wrong no of residues, is=",
		$ctRes{$name},", should be=$len\n";
	    $Lerr=1;}}
    return (1,1) if (! $Lerr);
    return (1,0) if ($Lerr);
}				# end of msfCheckNames

#===============================================================================
sub myprt_array {
    local($sep,@A)=@_;$[=1;local($a);
#   myprt_array                 prints array ('sep',@array)
    foreach $a(@A){print"$a$sep";}
    print"\n" if ($sep ne "\n");
}				# end of myprt_array

#===============================================================================
sub myprt_empty {
    local($fhx)=@_;
#   myprt_empty                 writes line with '--- \n'
    $fhx="STDOUT" if (! defined $fhx);print $fhx "--- \n"; 
}				# end of myprt_empty

#===============================================================================
sub myprt_line  {
    local($fhx)=@_;
#   myprt_line                  prints a line with 70 '-'
    $fhx="STDOUT" if (! defined $fhx);print $fhx "-" x 70,"\n","--- \n";
}				# end of myprt_line
		 
#===============================================================================
sub myprt_npoints {
    local ($npoints,$num_in) = @_; 
    local ($num,$beg,$ctprev,$ct,$numprev, $tmp,$tmp1,$tmp2, $out, $ct, $i);
    $[=1;
#-------------------------------------------------------------------------------
#   myprt_npoints               writes line with N dots of the form '....,....1....,....2' 
#       in:                     $number_of_points_per_line,$number_to_end_with
#       out:                    $line
#------------------------------------------------------------------------------
    if ( int($npoints/10)!=($npoints/10) ) {
	print "*** ERROR in myprt_npoints (lib-br.pl): \n";
	print "***       number of points should be multiple of 10 (is $npoints)!\n"; 
	return(" "); }
    $ct=int(($num_in-1)/$npoints);
    $beg=$ct*$npoints; $num=$beg;
    for ($i=1;$i<=($npoints/10);++$i) {
	$numprev=$num; $num=$beg+($i*10);
	$ctprev=$numprev/10;
	if    ( $i==1 )                        {
	    $tmp=substr($num,1,1); $out="....,....".$tmp; }
	elsif ( $ctprev<10 )                   {
	    $tmp=substr($num,1,1); $out.="....,....".$tmp; }
	elsif ($i==($npoints/10) && $ctprev>=9){
	    $tmp1=substr($ctprev,2);$tmp2="." x (4-length($tmp1));
	    $out.=$tmp1.$tmp2.",....".substr(($num/10),1); }
	else                                   {
	    $tmp1=substr($ctprev,2);$tmp2="." x (4-length($tmp1));
	    $out.=$tmp1.$tmp2.",....".substr($num,1,1); }}
    $myprt_npoints=$out;
    return ($out);
}				# end of myprt_npoints

#===============================================================================
sub myprt_points80 {
   local ($num_in) = @_; 
   local ($tmp9, $tmp8, $tmp7, $tmp, $out, $ct, $i);
   $[=1;

   $tmp9 = "....,...."; $tmp8 =  "...,...."; $tmp7 =   "..,....";
   $ct   = (  int ( ($num_in -1 ) / 80 )  *  8  );
   $out  = "$tmp9";
   if    ( $ct == 0 ) {for( $i=1; $i<8; $i++ )  {$out .= "$i" . "$tmp9" ;}
		       $out .= "8";}
   elsif ( $ct == 8 ) {$out .= "9" . "$tmp9";
		       for( $i=2; $i<8; $i++ )  {$tmp = $ct+$i;
						 $out .= "$tmp" . "$tmp8" ;}
		       $out .= "16";}
   elsif (($ct>8) && 
	  ($ct<96) )  {for( $i=1; $i<8; $i++ )  {$tmp = $ct+$i;
						 $out .= "$tmp" . "$tmp8" ;}
		       $tmp = $ct+8;
		       $out .= "$tmp";}
   elsif ( $ct == 96) {for( $i=1; $i<=3; $i++ ) {$tmp = $ct+$i;
						 $out .= "$tmp" . "$tmp8" ;}
		       for( $i=4; $i<8; $i++ )  {$tmp = $ct+$i;
						 $out .= "$tmp" . "$tmp7" ;}
		       $tmp = $ct+8;
		       $out .= "$tmp" ;}
   else               {for( $i=1; $i<8 ; $i++ ) {$tmp = $ct+$i;
						 $out .= "$tmp" . "$tmp7" ;}
		       $tmp = $ct+8;
		       $out .= "$tmp" ;}
   $myprt_points80=$out;
}				# end of myprt_points80

#===============================================================================
sub myprt_txt  {
    local($tmp,$fhx)=@_; 
#-------------------------------------------------------------------------------
#   myprt_txt                   adds '---' and '\n' for writing text
#-------------------------------------------------------------------------------
    $fhx="STDOUT" if(! defined $fhx);
    print $fhx "--- $tmp \n"; 
}				# end of myprt_txt
		 
#===============================================================================
sub numerically { 
#-------------------------------------------------------------------------------
#   numerically                 function sorting list by number
#-------------------------------------------------------------------------------
    $a<=>$b; 
}				# end of numerically

#===============================================================================
sub open_file {
    local ($file_handle,$file_name,$log_file) = @_ ;
    local ($temp_name) ;
#-------------------------------------------------------------------------------
#   open_file                  opens file, writes warning asf
#-------------------------------------------------------------------------------
    $temp_name = $file_name ;
    $temp_name =~ s/^>>|^>//g ;
    if ( ($file_name =~ /^>>/ ) && ( ! -e $temp_name ) ) {
	print "*** INFO (open_file): append file=$temp_name, does not exist-> create it\n" ;
	open ($file_handle, ">$temp_name") || ( do {
	    warn "***\t Cannot create new file: $temp_name\n" ;
	    if ( $log_file ) {
		print $log_file "***\t Cannot create new file: $temp_name\n" ;}
	    return (0);
	} );
	close ("$file_handle") ;}
  
    open ($file_handle, "$file_name") || ( do {
	warn "*** ERROR lib-br:open_file: Cannot open file '$file_name'\n" ;
	if ( $log_file ) {
	    print $log_file "*** lib-br:open_file: Cannot create new file '$file_name'\n" ;}
	return(0);
    } );
    return(1);
}				# end of open_file

#===============================================================================
sub pdbid_to_hsspfile {
    local ($name_in,$dir_hssp,$ext_hssp) = @_; 
    local ($tmp);
    $[=1;
#--------------------------------------------------------------------------------
#   pdbid_to_hsspfile           finds HSSP file for given id (old)
#--------------------------------------------------------------------------------
    if    (length($dir_hssp)==0){ $tmp = "/data/hssp/"; }
    elsif ($dir_hssp =~ /here/) { $tmp = ""; }
    else                        { $tmp = "$dir_hssp"; $tmp=~s/\s|\n//g; }
    if (length($ext_hssp)==0)   { $ext_hssp=".hssp"; }
    $name_in =~ s/\s//g;
    $pdbid_to_hsspfile = "$tmp" . "$name_in" . "$ext_hssp";
}				# end of pdbid_to_hsspfile 

#==============================================================================
sub phdAliWrt {
    local ($fileInHsspLoc,$chainInLoc,$fileInPhdLoc,$fileOutLoc,$formOutLoc,
	   $LoptExpandLoc,$riSecLoc,$riAccLoc,$riSymLoc,$charPerLineLoc) = @_ ;
    local($sbrName,$fhinLoc,$fhoutLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   phdAliWrt                 converts PHD.rdb to SAF format (including ali)
#       in:                     $fileInHssp  : HSSP file
#       in:                     $chainIn     : chain identifier ([0-9A-Z])
#       in:                     $fileInPhd   : PHD.rdb file
#       in:                     $fileOutLoc  : output *.msf file
#       in:                     $formOutLoc  : format of output file (msf|saf)
#       in:                     $LoptExpand  : do expand insertions in HSSP ?
#       in:                     $riSecLoc    : >= this -> write sec|htm to 'subset' row
#       in:                     $riAccLoc    : >= this -> write acc to 'subset' row
#       in:                     $riSymLoc    : use this symbol for 'not pred' in subset
#       in:                     $charPerLine : number of residues per line of output
#       in:                     $  :
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."phdAliWrt"; 
    $fhinLoc="FHIN_phdAliWrt";  $fhoutLoc="FHOUT_phdAliWrt"; 
				# ------------------------------
				# check arguments
    return(&errSbr("not def fileInHsspLoc!"))          if (! defined $fileInHsspLoc);
    return(&errSbr("not def chainInLoc!"))             if (! defined $chainInLoc);
    return(&errSbr("not def fileInPhdLoc!"))           if (! defined $fileInPhdLoc);
    return(&errSbr("not def fileOutLoc!"))             if (! defined $fileOutLoc);
    return(&errSbr("not def formOutLoc!"))             if (! defined $formOutLoc);
    return(&errSbr("not def LoptExpandLoc!"))          if (! defined $LoptExpandLoc);
    return(&errSbr("not def riSecLoc!"))               if (! defined $riSecLoc);
    return(&errSbr("not def riAccLoc!"))               if (! defined $riAccLoc);
    return(&errSbr("not def riSymLoc!"))               if (! defined $riSymLoc);
    return(&errSbr("not def charPerLineLoc!"))         if (! defined $charPerLineLoc);
				# ------------------------------
				# file existence
    return(&errSbr("miss in hssp=$fileInHsspLoc!"))    if (! -e $fileInHsspLoc);
    return(&errSbr("not HSSP format=$fileInHsspLoc!")) if (! &is_hssp($fileInHsspLoc));
    return(&errSbr("empty HSSP=$fileInHsspLoc!"))      if (&is_hssp_empty($fileInHsspLoc));
	
    return(&errSbr("miss in phd=$fileInPhdLoc!"))      if (! -e $fileInPhdLoc);
    return(&errSbr("not PHD.rdb=$fileInPhdLoc!"))      if (! &is_rdbf($fileInPhdLoc));
				# ------------------------------
				# syntax
    $formOutLoc=~tr/[A-Z]/[a-z]/;
    return(&errSbr("now only MSF|SAF ($formOutLoc)"))  if ($formOutLoc !~/^(msf|saf)$/);
    $LoptExpandLoc=0            if ($LoptExpandLoc !~ /^[01]$/);
    $chainInLoc="*"             if ($chainInLoc !~ /^[A-Za-z0-9]$/);
    $kwdSeq="seqNoins";
    $kwdSeq="seqAli"            if ($LoptExpandLoc); # do expand
				# --------------------------------------------------
				# defaults
				# @kwdPhd: keywords read + written
				# - not read but written: SUBsec, SUBacc
				# - explicit surpressor towards end for
				#   "OBSacc","PHDacc"
				# - 
				# note: @kwdPhdRd and @kwdPhdOut 
				#       correspond in that:
				# --------------------------------------------------
    @kwdPhd=
	("AA",    
	 "OHEL",  "PHEL",  "RI_S",  "SUBsec",
	 "Obie",  "Pbie",  "RI_A",  "SUBacc",   "OREL",   "PREL", 
	 "OHL",   "PHL",            "PFHN",     "PRHN",   "PiTo",   
	 "OTN",   "PTN",   "PRTN", # security
	                   "RI_H",  "PFTN",     
	 );
    $kwdAli=  "ALIGNMENT:";
    $kwdPhd=  "PHD:";
    $symEmpty=" ";
    %ptr=
	('AA',   "AApred",
	 'OHEL', "OBSsec", 'PHEL', "PHDsec", 'RI_S', "RELsec", 
	 'Obie', "O_3acc", 'Pbie', "P_3acc", 'RI_A', "RELacc",
	 'OTN',  "OBShtm", 'PTN',  "PHDhtm", 'RI_H', "RELhtm",
	 'OHL',  "OBShtm", 'PHL',  "PHDhtm", # security
	 'PFTN', "PHDhtmfil", 'PRTN', "PHDhtmref", 'PiTo', "PHDhtmtop",
	 'PFHL', "PHDhtmfil", 'PRHL', "PHDhtmref", 'PiTo', "PHDhtmtop",
	 );
				# explain subset
    $tmp="# NOTATION "." " x 10 ."   ";
    @tmpSec=
	(     "subset of the prediction, for all residues with an expected\n",
	 $tmp."average accuracy > 82% (tables in header)\n",
	 $tmp."NOTE: '$riSymLoc' means that for this residue the reliabilty\n",
	 $tmp."      was below a value of Rel=$riSecLoc.");
    @tmpAcc=
	(     "a subset of the prediction, for all residues with an expected\n",
	 $tmp."average correlation > 0.69 (tables in header)\n",
	 $tmp."NOTE: '$riSymLoc' means that for this residue the reliabilty\n",
	 $tmp."      was below a value of Rel=$riAccLoc.");
    $notationSubsec=join('',@tmpSec);
    $notationSubacc=join('',@tmpAcc);

    $warnMsg="";
    $errMsg= "*** ERROR $sbrName: \n";
    $errMsg.="in: hssp=$fileInHsspLoc, chain=$chainInLoc, phdrdb=$fileInPhdLoc, \n";
    $errMsg.="in: out=$fileOutLoc, form=$formOutLoc, expand=$LoptExpandLoc, \n";
    $errMsg.="in: riSec=$riSecLoc, riAcc=$riAccLoc, sym=$riSymLoc, per=$charPerLineLoc\n";
				# ------------------------------
				# read HSSP alignments
				# ------------------------------
    ($Lok,%tmp)=
	&hsspRdAli($fileInHsspLoc,$kwdSeq);
    return(&errSbr("after hsspRdAli ($fileInHsspLoc,$kwdSeq)".$errMsg)) if (! $Lok);
    return(&errSbr("after hsspRdAli ($fileInHsspLoc,NRES < 1)".$errMsg))
	if (! defined $tmp{"NRES"} || $tmp{"NRES"} < 1);
				# --------------------------------------------------
				# rename -> 
				#    $fin{"seq","1"}=  ... numbers
				#    $fin{"seq","2"}=  guide sequence
				#    $fin{"seq","it"}= pair it-2
				#    $fin{"id","it"}=  identifier for it
				# --------------------------------------------------
    undef %fin;			
    $beg=$end=0;		# find chain
    foreach $itres (1..$tmp{"NRES"}) {
	next if ($chainInLoc ne "*" && $tmp{"chn","$itres"} ne $chainInLoc);
	$beg=$itres             if (! $beg);
	$end=$itres; }
    return(&errSbr("after hsspRdAli beg=$beg, end=$end".$errMsg)) 
	if ($beg < 0 || $beg > length($tmp{"$kwdSeq","0"}) || 
	    $end < 0 || $end > length($tmp{"$kwdSeq","0"}));
				# guide sequence
    $fin{"seq","2"}=         substr($tmp{"$kwdSeq","0"},$beg,(1+$end-$beg)); # sequence
    $fin{"id","2"}=          $tmp{"0"};                 # name

    $ctali=2;			# first 2 = emtpy + guide
				# loop over all pairs
    foreach $itpair (1..$tmp{"NROWS"}) {
	$seq=substr($tmp{"$kwdSeq","$itpair"},$beg,(1+$end-$beg));
	$tmp=$seq;$tmp=~s/\.//g; # delete insertions
				# skip pairs not aligned to chain
	next if (length($tmp) < 1);
	++$ctali;
	$fin{"seq","$ctali"}=$seq;            # sequence
	$fin{"id","$ctali"}= $tmp{"$itpair"}; # name
    }
				# empty line
    $len=length($fin{"seq","2"}); $numpoints=10*(int($len/10))+10;
    $line=&myprt_npoints($numpoints,$len); 
    $fin{"id","1"}= $kwdAli;
    $fin{"seq","1"}=$line;
				# ------------------------------
				# read PHD rdb file
				# ------------------------------
    undef %tmp; undef %tmp2;
    %tmp=
	&rdRdbAssociative($fileInPhdLoc,"not_screen","body",@kwdPhd);

    return(&errSbr("after rdRdbAssociative ($fileInPhdLoc), no NROWS".$errMsg))
	if (! defined $tmp{"NROWS"});
    
				# --------------------------------------------------
				# digest the stuff read
				# * $tmp2{"kwd"} = strings with kwd = @kwdPhdOut
				# --------------------------------------------------
    $len=0;			# all keywords of PHD to write
    foreach $kwd (@kwdPhd) {
				# skip if no READ_RDB for key word 
	next if (! defined $tmp{"$kwd","1"});
	$tmp2{"$kwd"}=          "";
				# loop over all residues (strings from array)
	foreach $itres (1..$tmp{"NROWS"}){ # 
	    $tmp2{"$kwd"}.=     $tmp{"$kwd","$itres"}; }
	$len=length($tmp2{"$kwd"})  if (! $len);
	if ($kwd=~/^[OP]HEL/) {	# convert 'L' -> ' '
	    $tmp2{"$kwd"}=~s/L/L/g ;
	    next; }
	if ($kwd=~/^[PO]bie/){	# convert 'i' -> ' '
	    $tmp2{"$kwd"}=~s/i/i/g;
	    next; }		# convert HTM
	if ($kwd=~/^[PO]H[LN]/ || $kwd=~/^P[RF]H[LN]/){
	    $tmp2{"$kwd"}=~s/H/T/g;
	    $tmp2{"$kwd"}=~s/L/L/g;
	    next; } 
    }
				# ------------------------------
				# check identity HSSP / PHD seq
    $ctres=$ctsum=$ctok=0;	# ------------------------------
    $guideAli=$fin{"seq","2"}; 
    $guidePhd=$tmp2{"AA"};
    while (($ctres < length($guideAli)) && ($ctres < length($guidePhd))) {
	++$ctres;
				# skip non aa 
	$aliRes=substr($guideAli,$ctres,1);
	$phdRes=substr($guidePhd,$ctres,1);
	next if ($aliRes !~ /[A-Za-z]/);  # ali
	next if ($phdRes !~ /[A-Za-z]/);  # phd
				# count identical
	++$ctok                 if ($aliRes eq $phdRes);
	++$ctsum; }		# count all
    if ($ctsum < $ctok) { $warnMsg.="*** WARN $sbrName (hssp=$fileInHsspLoc,chn=$chainInLoc,".
			      "phd=$fileInPhdLoc) not identical seq(hssp) and seq(phd) ".
				  "tot=$ctsum, ok=$ctok\n";
			  $warnMsg.="hssp seq=".$guideAli.",\n";
			  $warnMsg.="phd  seq=".$guidePhd. ",\n"; }

				# ------------------------------
				# add the 'subset' stuff
    foreach $kwd ("SUBsec","SUBacc"){
	if    ($kwd=~/sec/) { $kwdPred="PHEL"; 
			      $kwdRi="RI_S";
			      $riThresh=$riSecLoc; }
	elsif ($kwd=~/acc/) { $kwdPred="Pbie"; 
			      $kwdRi="RI_A";
			      $riThresh=$riAccLoc; }
	next if (! defined $tmp2{"$kwdPred"} || length($tmp2{"$kwdPred"})<1);

	($Lok,$msg,$tmp)=	# get subset
	    &getPhdSubset($tmp2{"$kwdPred"},$tmp2{"$kwdRi"},$riThresh,$riSymLoc);
	return(&errSbrMsg("failed writing subset from\n".$errMsg.$warnMsg,$msg)) if (! $Lok);
	$tmp2{"$kwd"}=$tmp;  }

				# empty line
    $ctkwd=$ctali;		# ctali = number of HSSP alis
    ++$ctkwd;
    $fin{"id","$ctkwd"}=        $kwdPhd;
    $fin{"seq","$ctkwd"}=       $symEmpty x $len;
    
    undef %Lok;			# ------------------------------
    foreach $kwd (@kwdPhd) {	# final correction: 
	next if (! defined $tmp2{"$kwd"});
				# hack: explicit surpressor for "OBSacc","PHDacc"
	next if ($kwd =~/^[OP]REL$/);
	++$ctkwd;
	$fin{"seq","$ctkwd"}=   $tmp2{"$kwd"}; # $tmp2{$kwd} -> $fin{'seq','$it'}
				# rename rows
	$kwdOut=$kwd;
	$kwdOut=$ptr{"$kwd"}    if (defined $ptr{"$kwd"});
	$fin{"id","$ctkwd"}=    $kwdOut;       # $kwd        -> $fin{'id','$it'}
	$Lok{"$kwd"}=           $ctkwd;
    }
    $fin{"NROWS"}=              $ctkwd;
    $fin{"PER_LINE"}=           $charPerLineLoc;
				# ------------------------------
				# read header/notation
    if ($formOutLoc eq "saf"){
				# open file
	$Lok=&open_file("$fhinLoc","$fileInPhdLoc");
	if ($Lok){		# read file
	    $tmpWrt="";
	    while (<$fhinLoc>) {
		$_=~s/\n//g;
		next if ($_ !~/\#.*NOTATION/);
		last if ($_ !~/\#/);
		$kwd=$_; $rd=$_;
		$kwd=~s/^\#.*NOTATION\s*(\S+)\s*:\s*(.*)$/$1/;
		$txt=$2;
		next if (! defined $Lok{"$kwd"});
		next if (! defined $ptr{"$kwd"});
		$kwdOut=$ptr{"$kwd"};
		$tmpWrt.=       sprintf("# NOTATION %-10s : %-s\n",$kwdOut,$txt); 
	    } close($fhinLoc);
				# add for subsets
	    $tmpWrt.=           sprintf("# NOTATION %-10s : %-s\n",
					"SUBsec",$notationSubsec) 
		if ($Lok{"PHEL"} && $Lok{"RI_S"} );
	    $tmpWrt.=           sprintf("# NOTATION %-10s : %-s\n",
					"SUBacc",$notationSubacc) 
		if ($Lok{"Pbie"} && $Lok{"RI_A"} );
	    $fin{"HEADER"}=$tmpWrt."\# \n";
	} }
				# --------------------------------------------------
				# finally write PHD + Ali
				# --------------------------------------------------
    if ($formOutLoc eq "msf") {	# MSF
	undef %tmp;		# build up anew
	$tmp{"NROWS"}=$fin{"NROWS"};
	$tmp{"FROM"}= $fileInHsspLoc;
	$tmp{"TO"}=   $fileOutLoc;
	foreach $it (1..$fin{"NROWS"}) {
	    $id=        $fin{"id","$it"};
	    $tmp{"$it"}=$id;
	    $tmp{"$id"}=$fin{"seq","$it"}; }
                                # open new file
	&open_file("$fhoutLoc",">$fileOutLoc") ||
	    return(0,"*** ERROR $sbrName: failed opening fileOut=$fileOutLoc\n"); 
				# call
	($Lok)=
	    &msfWrt($fhoutLoc,%tmp);
	close($fhoutLoc);

	return(&errSbr("failed writing MSF from PHD".$errMsg.$warnMsg)) if (! $Lok); }
				# ------------------------------
    else {			# SAF = default
	($Lok,$msg)=
	    &safWrt($fileOutLoc,%fin);
	return(&errSbrMsg("failed writing SAF".$errMsg.$warnMsg,$msg)) if (! $Lok); }

				# ------------------------------
				# clean up
    undef %tmp; undef %tmp2; undef %fin; undef %Lok; undef %ptr; # slim-is-in!

    return(&errSbrMsg("failed writing output".$errMsg.$warnMsg,$msg)) 
	if (! -e $fileOutLoc);
    
    return(1,"ok $sbrName");
}				# end of phdAliWrt

#===============================================================================
sub phdHtmIsit {
    local($fileInLoc,$minValLoc,$minLenLoc,$doStatLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   phdHtmIsit                  returns best HTM
#       in:                     $fileInLoc        : PHD rdb file
#       in:                     $minValLoc        : average value of minimal helix (0.8)
#                                  undefined|0    -> defaults
#       in:                     $minLenLoc        : length of best helix (18)
#                                  undefined|0    -> defaults
#       in:                     $doStatLoc        : compute further statistics
#                                  undefined|0    -> defaults
#       out:                    1|0,msg,$LisMembrane (1=yes, 0=no),%tmp:
#                               $tmp{"valBest"}   : value of best HTM
#                               $tmp{"posBest"}   : first residue of best HTM
#                   if doStat:
#                               $tmp{"len"}       : length of protein
#                               $tmp{"nhtm"}      : number of membrane helices
#                               $tmp{"seqHtm"}    : sequence of all HTM (string)
#                               $tmp{"seqHtmBest"}: sequence of best HTM (string) 
#                                            (note: may be shorter than minLenLco)
#                               $tmp{"aveLenHtm"} : average length of HTM
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."phdHtmIsit";$fhinLoc="FHIN_"."phdHtmIsit";
				# ------------------------------
				# defaults
    $minValDefLoc= 0.8;		# average value of best helix (required)
    $minLenDefLoc= 18;		# length of best helix (18)
    $doStatDefLoc=0;		# compile further statistics on residues, avLength asf

				# ------------------------------
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
    $minValLoc=$minValDefLoc                       if (! defined $minValLoc || $minValLoc == 0);
    $minLenLoc=$minLenDefLoc                       if (! defined $minLenLoc || $minLenLoc == 0);
    $doStatLoc=$doStatDefLoc                       if (! defined $doStatLoc);

    $kwdNetHtm="OtH";		# name of column with network output for helix (0..100)
    $kwdPhdHtm="PHL";		# name of column with final prediction
    $kwdSeq=   "AA";		# name of column with sequence

    return(&errSbr("miss in file '$fileInLoc'!"))  if (! -e $fileInLoc);
    return(&errSbr("not RDB (htm) '$fileInLoc'!")) if (! &is_rdbf($fileInLoc));

    undef %tmp;
				# ------------------------------
				# read RDB file
    @kwdLoc=($kwdNetHtm);
    push(@kwdLoc,$kwdPhdHtm,$kwdSeq)    if ($doStatLoc);

    %tmp=
	&rdRdbAssociative($fileInLoc,"not_screen","header","PDBID","body",@kwdLoc); 
    return(&errSbr("failed reading $fileInLoc (rd_rdb_associative), kwd=".
		   join(',',@kwdLoc))) if (! defined $tmp{"NROWS"} || ! $tmp{"NROWS"});

				# ------------------------------
				# get network output values
    $#htm=0; 
    foreach $it (1..$tmp{"NROWS"}) {
	push(@htm,$tmp{"$kwdNetHtm","$it"}); }
				# ------------------------------
				# get best
    ($Lok,$msg,$valBest,$posBest)=
	&phdHtmGetBest($minLenLoc,@htm);
    return(&errSbrMsg("failed getting best HTM ($fileInLoc, minLenLoc=$minLenLoc,\n".
		      "htm=".join(',',@htm,"\n"),$msg)) if (! $Lok);
				# ------------------------------
				# IS or IS_NOT, thats the question
    $LisMembrane=0;
    $LisMembrane=1              if ($valBest >= $minValLoc);

    undef @htm;			# slim-is-in!

    undef %tmp2;
    $tmp2{"valBest"}=    $valBest;
    $tmp2{"posBest"}=    $posBest;

				# ------------------------------
				# no statics -> this is ALL!!
    if (! $doStatLoc) {		# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
	undef %tmp;
	return(1,"ok $sbrName",$LisMembrane,%tmp2);
    }				# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


				# --------------------------------------------------
				# now: do statistics
				# --------------------------------------------------
    $lenProt=$tmp{"NROWS"}; 
				# prediction -> string
    $seqHtm=$seqHtmBest=$phd="";
    foreach $it (1..$tmp{"NROWS"}) {
	$phd.=       $tmp{"$kwdPhdHtm","$it"}; 
				# subset of residues in HTM
	next if ($tmp{"$kwdPhdHtm","$it"} ne "H");
	$seqHtm.=    $tmp{"$kwdSeq","$it"};
				# subset of residues for best HTM
	next if ($posBest > $it || $it >  ($posBest + $minLenLoc));
	$seqHtmBest.=$tmp{"$kwdSeq","$it"};
    }
	
				# ------------------------------
				# average length
    $tmp=$phd;
    $tmp=~s/^[^H]*|[^H]$//g;	# purge non-HTM begin and end
    @tmp=split(/[^H]+/,$tmp);
    $nhtm=$#tmp;		# number of helices
    $htm=join('',@tmp);		# only helices
    $nresHtm=length($htm);	# total number of residues in helices

    $aveLenHtm=0;
    $aveLenHtm=($nresHtm/$nhtm) if ($nhtm > 0);


    $tmp2{"len"}=        $lenProt;
    $tmp2{"nhtm"}=       $nhtm;
    $tmp2{"seqHtm"}=     $seqHtm;
    $tmp2{"seqHtmBest"}= $seqHtmBest;
    $tmp2{"aveLenHtm"}=  $aveLenHtm;

				# ------------------------------
				# temporary write to file xxx
    if (0){			# xx
	$id=$tmp{"PDBID"};$id=~tr/[A-Z]/[a-z]/;
	$tmpWrt= sprintf("%-s\t%6.2f\t%5d\t%5d\t%5d\t%6.1f",
			 $id,$tmp2{"valBest"},$tmp2{"posBest"},
		     $tmp2{"len"},$tmp2{"nhtm"},$tmp2{"aveLenHtm"});
#	system("echo '$tmpWrt' >> stat-htm-glob.tmp");
#	system("echo '$tmpWrt' >> stat-htm-htm.tmp");
    }

    undef %tmp;			# slim-is-in

    return(1,"ok $sbrName",$LisMembrane,%tmp2);
}				# end of phdHtmIsit


#===============================================================================
sub phdHtmGetBest {
    local($minLenLoc,@tmp) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   phdHtmGetBest               returns position (begin) and average val for best HTM
#       in:                     $minValLoc        : average value of minimal helix (0.8)
#                                  = 0    -> defaults (18)
#       in:                     @tmp=             network output HTM unit (0 <= OtH <= 100)
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."phdHtmGetBest";$fhinLoc="FHIN_"."phdHtmGetBest";
				# check arguments
    return(&errSbr("no input!")) if (! defined @tmp || $#tmp==0);
    $minLenLoc=18                if ($minLenLoc == 0);

    $max=0;
				# loop over all residues
    foreach $it (1 .. ($#tmp + 1 - $minLenLoc)) {
				# loop over minLenLoc adjacent residues
	$htm=0;
	foreach $it2 ($it .. ($it + $minLenLoc - 1 )) {
	    $htm+=$tmp[$it2];}
				# store 
	if ($max < $htm) { $pos=$it;
			   $max=$htm; } }
				# normalise
    $val=$max/$minLenLoc;
    $val=$val/100;		# network written to 0..100

    return(1,"ok $sbrName",$val,$pos);
}				# end of phdHtmGetBest

#==========================================================================================
sub phdPredWrt {
    local ($fileOutLoc,$idvec,$desvec,$opt_phd,$nres_per_row,%all) = @_ ;
    local ($fh,@des,@id,$tmp,@tmp,$id,$it);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    phdPredWrt                 writes into file readable by EVALSEC|ACC
#       in:                     $fileOutLoc:     output file name
#                  alternative: STDOUT           -> write to STDOUT
#       in:                     $idvec:          'id1,id2,..' i.e. all ids to write
#       in:                     $desvec:         'AA,OHEL,PHEL,RI_S'
#       in:                     $opt_phd:        sec|acc|htm|?
#       in:                     $nres_per_row:   number of residues per row (80!)
#       in:                     $all{} with
#                               $all{'$id','NROWS'}= number of residues of protein $id
#                               $all{'$id','$des'}=  string for $des=
#                                   sec: AA|OHEL|PHEL|RI_S
#                                   acc: AA|OHEL|OREL|PREL|RI_A
#                                   htm: AA|OHL|PHL|PFHL|PRHL|PR2HL|RI_S|H
#       out:                    1|0,msg ; implicit: file_out
#       err:                    (1,'ok'), (0,'message')
#--------------------------------------------------------------------------------
    $sbrName="lib-br:"."phdPredWrt";$fh="FHOUT_"."phdPredWrt";
				# ------------------------------
				# check arguments
    return(0,"*** $sbrName: not def fileOutLoc!")       if (! defined $fileOutLoc);
    return(0,"*** $sbrName: not def idvec!")            if (! defined $idvec);
    return(0,"*** $sbrName: not def desvec!")           if (! defined $desvec);
    return(0,"*** $sbrName: not def opt_phd!")          if (! defined $opt_phd);
    return(0,"*** $sbrName: not def nres_per_row!")     if (! defined $nres_per_row);
				# ------------------------------
				# vector to array
    @des=split(/[\t,]/,$desvec);
    @id= split(/[\t,]/,$idvec);
    %translate=
	# sequence       observed struc   predicted struc    reliability
	('AA_sec',"AA", 'OHEL_sec',"DSP", 'PHEL_sec', "PRD", 'RI_S_sec',"Rel", # sec
	 'AA_acc',"AA", 'OHEL_acc',"SS", 
	                'OREL_acc',"Obs", 'PREL_acc', "Prd", 'RI_A_acc',"Rel", # acc
	 'AA_htm',"AA", 'OHL_htm', "OBS", 'PHL_htm',  "PHD", 'RI_H_htm',"Rel", # htm
	                'OTN_htm', "OBS", 'PTN_htm',  "PHD", 'RI_S_htm',"Rel",
	                                  'PfhL_htm', "FIL",
	                                  'PRHL_htm', "PHD",
	                                  'PR2HL_htm',"PHD");

                                # ------------------------------
                                # open file
    if ($fileOutLoc eq "STDOUT"){
	$fh="STDOUT";}
    else {
	&open_file($fh, ">$fileOutLoc") || return(&errSbr("fileOut=$fileOutLoc, not created"));}

				# ------------------------------
				# write header
    print $fh  "* PHD_DOTPRED_8.95 \n"; # recognised key word!
    print $fh  "*" x 80, "\n","*"," " x 78, "*\n";
    if   ($opt_phd eq "sec"){$tmp="PHDsec: secondary structure prediction by neural network";}
    elsif($opt_phd eq "acc"){$tmp="PHDacc: solvent accessibility prediction by neural network";}
    elsif($opt_phd eq "htm"){$tmp="PHDhtm: helical transmembrane prediction by neural network";}
    else                    {$tmp="PHD   : Profile prediction by system of neural networks";}
    printf $fh "*    %-72s  *\n",$tmp;
    printf $fh "*    %-72s  *\n","~" x length($tmp);
    printf $fh "*    %-72s  *\n"," ";
    if   ($desvec =~/PRHL/) {$tmp="VERSION: REFINE: best model";}
    elsif($desvec =~/PR2HL/){$tmp="VERSION: REFINE: 2nd best model";}
    elsif($desvec =~/PFHL/ ){$tmp="VERSION: FILTER: old stupid filter of HTM";}
    elsif($desvec =~/PHL/ ) {$tmp="VERSION: probably no HTM filter, just network";}
    printf $fh "*    %-72s  *\n",$tmp;
    print  $fh "*"," " x 78, "*\n";
    @tmp=("Burkhard Rost, EMBL, 69012 Heidelberg, Germany",
	  "(Internet: rost\@EMBL-Heidelberg.DE)");
    foreach $tmp (@tmp) {
	printf $fh "*    %-72s  *\n",$tmp;}
    print  $fh "*"," " x 78, "*\n";
    $tmp=&sysDate();
    printf $fh "*    %-72s  *\n",substr($tmp,1,70);
    print  $fh "*"," " x 78, "*\n";
    print  $fh "*" x 80, "\n";
				# numbers
    $tmp=$#id;
    printf $fh "num %4d\n",$tmp;
    if ($opt_phd eq "acc"){print $fh "nos(ummary)\n";}
				# --------------------------------------------------
				# loop over all proteins
    foreach $it (1..$#id) {     # --------------------------------------------------
	$id=  $id[$it];
        $nres=$all{"$id","NROWS"};
                                # ------------------------------
				# header (name, length)
        printf $fh "    %-6s %5d\n",substr($id,1,6),$nres   if ($opt_phd eq "acc");
        printf $fh "    %10d %-s\n",$nres,$id               if ($opt_phd ne "acc");
                                # ------------------------------
				# phd/obs for each protein
        for ($itres=1; $itres<=$nres; $itres+=$nres_per_row) {
                                # points
            printf $fh "%-3s %-s\n"," ",&myprt_npoints($nres_per_row,$itres);
            foreach $des (@des) {
                                # translate description
		$desTranslate= $des."_".substr($opt_phd,1,3);
		$txt=          $translate{"$desTranslate"};
                                # skip if shorter than current
                next if (! defined $all{"$id","$des"}  || length($all{"$id","$des"})<$it);
                                # finally: write the shit
                printf $fh 
                    "%-3s|%-s|\n",$txt,substr($all{"$id","$des"},$itres,$nres_per_row); }
        }                       # end of loop over all residues
    }                           # end of loop over all proteins
    print $fh "END\n"; 
    close($fh)                  if ($fh ne "STDOUT");

    undef %all;			# slim-is-in!

    return(1,"ok $sbrName");
}				# end of phdPredWrt

#===============================================================================
sub phdRdbMerge {
    local ($fileOutRdbLoc,$fileAbbrRdb,@fileRdbLoc) = @_ ;
    local ($SBR1,$fhoutLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   phdRdbMerge                 manages merging two PHD *.rdb files ('name'= acc + sec + htm)
#       in:                     $fileOutRdbLoc : name of RDB output
#       in:                     $fileAbbrRdb   : file explaining the abbreviations in RDB file
#       in:                     @fileRdbLoc=
#       in:                        $fileSec    : PHD rdb with sec output
#       in:                        $fileAcc    : PHD rdb with acc output
#       in:                        $fileHtm    : PHD RDB with HTM output
#       out:                    1|0,$ERROR_msg|$WARNING_MESSAGE  implicit: file
#       err:                    (1,'ok warning message'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR1="lib-br:phdRdbMerge"; $fhoutLoc="FHOUT_".$SBR1;
				# ------------------------------
				# arguments given ?
    return(&errSbr("not def fileOutRdbLoc!",$SBR1))  if (! defined $fileOutRdbLoc);
    return(&errSbr("not def fileAbbrRdb!",$SBR1))    if (! defined $fileAbbrRdb);
				# ------------------------------
				# syntax check
    return(&errSbr("too few files (<2):".join(',',@fileRdbLoc),$SBR1))
	if ($#fileRdbLoc < 2);
				# ------------------------------
				# input files existing ?
    foreach $it (1..$#fileRdbLoc){
        return(&errSbr("no file($it)=$fileRdbLoc[$it]!",$SBR1)) 
            if (! -e $fileRdbLoc[$it]); }

                                # ------------------------------
				# set defaults
    &phdRdbMergeDef;
				# --------------------------------------------------
				# merge files (immediately write)
				# --------------------------------------------------
    &open_file("$fhoutLoc", ">$fileOutRdbLoc");
    ($Lok,$msg)=
        &phdRdbMergeDo($fileAbbrRdb,$fhoutLoc,@fileRdbLoc);
    close($fhoutLoc);
    return(&errSbrMsg("failed on phdRdbMergeDo (fh=$fhoutLoc,ARRAY=".
                      join(',',@fileRdbLoc),$msg,$SBR1))
        if (! $Lok);

    return(1,"ok $SBR1\n"."warn message from phdRdbMergeDo (into $SBR1):\n".$msg);

}				# end of phdRdbMerge

#===============================================================================
sub phdRdbMergeDef {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   phdRdbMergeDef              sets defaults for phdRdbMerg
#       in/out GLOBAL:          all
#-------------------------------------------------------------------------------
    @desSec=
        ("No","AA","OHEL","PHEL","RI_S","pH","pE","pL","OtH","OtE","OtL");
    @desAcc=
        ("OACC","PACC","OREL","PREL","RI_A","Obie","Pbie");
    for $it (0..9){
        push(@desAcc,"Ot".$it); }
    @desHtm=
        ("OHL","PHL","PFHL","PRHL","PiTo","RI_H","pH","pL","OtH","OtL");

    @desOutG=
        ("No","AA","OHEL","PHEL","RI_S","OtH","OtE","OtL",
         "OACC","PACC","OREL","PREL","RI_A","Obie","Pbie");
    @formOut=
        ("4N","1" ,"1"   ,"1"   ,"1N",  "3N", "3N", "3N",
         "3N"  ,"3N"  ,"3N",  "3N",  "1N",  "1",   "1");
    for $it (0..9){
        push(@desOutG,"Ot".$it); 
        push(@formOut,"3N");}
    push(@desOutG, 
         "OTN","PTN","PFTN","PRTN","PiTo","RI_H","OtT","OtN");
    push(@formOut,
         "1"  ,"1"  ,"1"   ,"1"   ,"1"   ,"1N"  ,"3N" ,"3N");

    foreach $it (1..$#desOutG){
        $tmp=$formOut[$it];
        if   ($tmp=~/N$/) {$tmp=~s/N$/d/;$formOutPrintf{"$desOutG[$it]"}=$tmp;}
        elsif($tmp=~/F$/) {$tmp=~s/F$/f/;$formOutPrintf{"$desOutG[$it]"}=$tmp;}
        else              {$tmp.="s";    $formOutPrintf{"$desOutG[$it]"}=$tmp;} }
    $sep="\t";                  # separator

}				# end of phdRdbMergeDef

#===============================================================================
sub phdRdbMergeDo {
    local ($fileAbbrRdb,$fhoutLoc,@fileRdbLoc) = @_ ;
    local ($fhinLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   phdRdbMergeDo               merging two PHD *.rdb files ('name'= acc + sec)
#       in GLOBAL:              @desSec,@desAcc,@headerHtm,@desHtm
#       in:                     $fileAbbrRdb   : file explaining the abbreviations in RDB file
#       in:                     $fhoutLoc      : file handle for RDB output file
#       in:                     @fileRdbLoc=
#       in:                        $fileSec    : PHD rdb with sec output
#       in:                        $fileAcc    : PHD rdb with acc output
#       in:                        $fileHtm    : PHD RDB with HTM output
#       out:                    1|0,$ERROR_msg|$WARNING_MESSAGE  implicit: file
#       err:                    (1,'ok warning message'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR2="lib-br:phdRdbMerge"; $fhinLoc="FHIN_".$SBR2;
                                # --------------------------------------------------
                                # reading files
                                # --------------------------------------------------
    $LisAccLoc=$LisHtmLoc=$LisSecLoc=
        $#headerSec=$#headerAcc=$#headerHtm=0;
    foreach $file (@fileRdbLoc){
				# secondary structure
	if    (&is_rdb_sec($file)){
            &open_file("$fhinLoc", "$file") || return(&errSbr("sec failed in=$file",$SBR2));
	    while (<$fhinLoc>){
                $rd=$_;
                push(@headerSec,$rd) if (($rd=~/^\#/) && ($rd !~ /^\# NOTATION/));
                last if ($rd !~ /^\#/);}
	    close($fhinLoc);$LisSecLoc=1;
	    %rdSec=
                &rd_rdb_associative($file,"not_screen","body",@desSec); }
				# accessibility
	elsif (&is_rdb_acc($file)){
            &open_file("$fhinLoc", "$file") || return(&errSbr("acc failed in=$file",$SBR2));
	    while(<$fhinLoc>){
                $rd=$_;
                push(@headerAcc,$rd) if (($rd=~/^\#/) && ($rd !~ /^\# NOTATION/));
                last if ($rd !~ /^\#/);}
	    close($fhinLoc);$LisAccLoc=1;
	    %rdAcc=
                &rd_rdb_associative($file,"not_screen","body",@desAcc);}
				# htm
	elsif (&is_rdb_htmtop($file) || &is_rdb_htmref($file) || &is_rdb_htm($file) ){ 
	    &open_file("$fhinLoc", "$file") || return(&errSbr("htm failed in=$file",$SBR2));
	    while(<$fhinLoc>){
                $rd=$_;
                push(@headerHtm,$rd) if (($rd=~/^\#/) && ($rd !~ /^\# NOTATION/));
                last if ($rd !~ /^\#/);}
	    close($fhinLoc);$LisHtmLoc=1;
	    %rdHtm=
                &rd_rdb_associative($file,"not_screen","body",@desHtm);
	    foreach $ct (1..$rdHtm{"NROWS"}){
		$rdHtm{"OTN","$ct"}= $rdHtm{"OHL","$ct"};
		$rdHtm{"PTN","$ct"}= $rdHtm{"PHL","$ct"};
		$rdHtm{"PFTN","$ct"}=$rdHtm{"PFHL","$ct"};
		$rdHtm{"PRTN","$ct"}=$rdHtm{"PRHL","$ct"};
		$rdHtm{"OtT","$ct"}= $rdHtm{"OtH","$ct"};
		$rdHtm{"OtN","$ct"}= $rdHtm{"OtL","$ct"};} }
	else {
	    return(&errSbr("file=$file not recognised format",$SBR2));} 
    }                           # end of all 2-3 input files

                                # ------------------------------
				# decide when to break the line
    if ($LisHtmLoc){
        $desNewLine="OtN";}
    else{
        $desNewLine="Ot9";}
				# ------------------------------
				# read abbreviations
				# ------------------------------
    $#header=0;
    if (defined $fileAbbrRdb && $fileAbbrRdb && -e $fileAbbrRdb){
	&open_file("$fhinLoc", "$fileAbbrRdb")  || 
	    return(&errSbr("abbr failed in=$fileAbbrRdb",$SBR2));
	while(<$fhinLoc>){
	    $rd=$_;$rd=~s/\n//g;
	    push(@header,$rd)   if($rd=~/^\# NOTATION/);}
	close($fhinLoc); }
				# --------------------------------------------------
				# write header into file
				# --------------------------------------------------
    $warnMsg=
        &phdRdbMergeHdr($fhoutLoc);
				# --------------------------------------------------
				# write selected columns
				# --------------------------------------------------
                                # names
    foreach $des (@desOutG) {
        if (defined $rdSec{"$des","1"} || defined $rdAcc{"$des","1"} || 
	    defined $rdHtm{"$des","1"}) {
	    $sep_tmp=$sep; 
            $sep_tmp="\n"       if ($des eq $desNewLine);
            print $fhoutLoc "$des","$sep_tmp"; }}
                                # ------------------------------
                                # formats
    foreach $it (1..$#format_out) {
        if (defined $rdSec{"$desOutG[$it]","1"} || defined $rdAcc{"$desOutG[$it]","1"} ||
	    defined $rdHtm{"$desOutG[$it]","1"}) {
	    $sep_tmp=$sep; 
            $sep_tmp="\n"       if ($desOutG[$it] eq $desNewLine);
            print $fhoutLoc "$format_out[$it]","$sep_tmp"; } }
                                # ------------------------------
                                # data
    foreach $mue (1..$rdSec{"NROWS"}){
                                # sec
        foreach $des("No","AA","OHEL","PHEL","RI_S","OtH","OtE","OtL") {
            next if (! defined $rdSec{"$des","$mue"} );
            $tmp="%".$formOutPrintf{"$des"};
            $rd=$rdSec{"$des","$mue"};
            $rd=~s/\s|\n//g;
            printf $fhoutLoc "$tmp$sep",$rd; }
                                # acc
        foreach $des("OACC","PACC","OREL","PREL","RI_A","Obie","Pbie",
                   "Ot0","Ot1","Ot2","Ot3","Ot4","Ot5","Ot6","Ot7","Ot8","Ot9") {
            next if (! defined $rdAcc{"$des","$mue"});
            $tmp="%".$formOutPrintf{"$des"};
	    $sep_tmp=$sep; 
            $sep_tmp="\n"       if ($des eq $desNewLine);
            $rd=$rdAcc{"$des","$mue"};
            $rd=~s/\s|\n//g;
            printf $fhoutLoc "$tmp$sep_tmp",$rd; }
	next if (! $LisHtmLoc);
                                # htm
        foreach $des ("OTN","PTN","PFTN","PRTN","PiTo","RI_H","OtT","OtN"){
            next if (! defined $rdHtm{"$des","$mue"});
            $tmp="%".$formOutPrintf{"$des"};
	    $sep_tmp=$sep; 
            $sep_tmp="\n"       if ($des eq $desNewLine);
            $rd=$rdHtm{"$des","$mue"};
            $rd=~s/\s|\n//g;
            printf $fhoutLoc "$tmp$sep_tmp",$rd; }
    }
				# all fine
    return(1,"ok $SBR2")        if (! defined $warnMsg || ! $warnMsg ||
				    $warnMsg !~ /WARN/);
				# warning in hdr
    return(1,"ok $SBR2 warn=\n".$warnMsg."\n");
}				# end of phdRdbMergeDo

#===============================================================================
sub phdRdbMergeHdr {
    local($fhoutLoc) = @_ ;
    local($SBR3);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   phdRdbMergeHdr              writes the merged RDB header
#-------------------------------------------------------------------------------
    $SBR3="lib-br:phdRdbMergHdr";
                                # ------------------------------
                                # keyword
    print $fhoutLoc "\# Perl-RDB\n";
    if ($LisSecLoc && $LisAccLoc && $LisHtmLoc){ 
	print  $fhoutLoc 
	    "\# PHDsec+PHDacc+PHDhtm\n",
	    "\# Prediction of secondary structure, accessibility, and transmembrane helices\n";}
    elsif ($LisSecLoc && $LisAccLoc){ 
	print  $fhoutLoc 
	    "\# PHDsec+PHDacc\n",
	    "\# Prediction of secondary structure, and accessibility\n";}
                                # ------------------------------
				# special information from header
    foreach $rd (@headerSec){
        $tmp=$rd;$tmp=~s/^\# ([A-Za-z0-9_]+).*$/$1/g;
        next if ($rd =~/^\# (NOTATION|Perl|PHD)/i);
        $Lok{"$tmp"}=1;         # to avoid duplication of information
        print $fhoutLoc $rd;}
    foreach $rd (@headerAcc){
        $tmp=$rd;$tmp=~s/^\# ([A-Za-z0-9_]+).*$/$1/g;
        next if ($rd =~/^\# (NOTATION|Perl|PHD)/i);
        next if (defined $Lok{"$tmp"});
        $Lok{"$tmp"}=1;         # to avoid duplication of information
        print $fhoutLoc $rd;}
    foreach $rd (@headerHtm){
        $tmp=$rd;$tmp=~s/^\# ([A-Za-z0-9_]+).*$/$1/g;
        next if ($rd =~/^\# (NOTATION|Perl|PHD)/i);
        next if (defined $Lok{"$tmp"});
        $Lok{"$tmp"}=1;         # to avoid duplication of information
        print $fhoutLoc $rd;}
                                # ------------------------------
    foreach $desOut(@desOutG){	# notation
	$Lok=0;
                                # special case accessibility net out (skip 1-9)
	next if ($desOut =~ /^Ot[1-9]/);
                                # special case accessibility net out (write 0)
	if ($desOut =~ /^Ot0/){
	    foreach $rd(@header){
		next if ($rd !~/^Ot\(n\)/);
                $Lok=1;
                print $fhoutLoc "$rd\n";
                last; }
	    next;}
	foreach $rd (@header){
	    next if ($rd !~/$desOut/);
            $Lok=1;
            print $fhoutLoc "$rd\n";
            last; } 
        $errMsg3="-*- WARNING rdbMergeDo \t missing description for desOut=$desOut\n"
            if (! $Lok); }
    print $fhoutLoc "\# \n";

    return($errMsg3);
}				# end of phdRdbMergeHdr

#===============================================================================
sub phdRun {                    # input files/modes
    local ($fileHssp,$chainHssp,$fileParaSec,$fileParaAcc,$fileParaHtm,$fileAbbrRdb,
           $optPhd3,$optRdbLoc,
                                # executables
           $exePhdLoc,$exeHtmfilLoc,$exeHtmisitLoc,$exeHtmrefLoc,$exeHtmtopLoc,
                                # modes FORTRAN
	   $optMachLoc,$optKgLoc,$useridLoc,$optIsDecLoc,$optNiceInLoc,
                                # modes HTM post
           $optDoHtmfilLoc,$optDoHtmisitLoc,$optHtmisitMinLoc,$optDoHtmrefLoc,$optDoHtmtopLoc,
                                # output files
	   $fileOutPhdLoc,$fileOutRdbLoc,$fileOutNotLoc,
                                # temporary stuff
	   $dirLib,$dirWorkLoc,$titleTmpLoc,$jobidLoc,
           $LdebugLoc,$fileOutScreenLoc,$fhSbrErr) = @_;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   phdRun                      runs all 3 FORTRAN programs PHD
#                               
#            input files/modes
#       in:                     $fileHssp      : HSSP file to run it on
#       in:                     $chainHssp     : name of chain
#       in:                     $filePara*     : name of file with phd.f network parameters
#                                                for modes sec,acc,htm
#                                   = 0          to surpress
#       in:                     $optPhd3       : mode = 3|both|sec|acc|htm  (else -> ERROR)
#       in:                     $optRdbLoc     : write RDB, or not (ancient)
#       in:                     $fileAbbrRdb   : file explaining the abbreviations in RDB file
#                               
#            executables
#       in:                     $exePhd        : FORTRAN executable for PHD
#       in:                     $exeHtmfilLoc  : Perl executable for HTMfil
#       in:                     $exeHtmisitLoc : Perl executable for HTMisit
#       in:                     $exeHtmrefLoc  : Perl executable for HTMref
#       in:                     $exeHtmtopLoc  : Perl executable for HTMtop
#                               
#            modes FORTRAN
#       in:                     $optMachLoc    : for tim
#       in:                     $optKgLoc      : for KG format
#       in:                     $useridLoc     : user name         (for PP/non-pp)
#       in:                     $optIsDecLoc   : machin is DEC     (ancient)
#                               
#            modes HTM
#       in:                     $optDoHtmfil   : 1|0 do or do NOT run
#       in:                     $optDoHtmisit  : 1|0 do or do NOT run
#       in:                     $optHtmisitMin : strength of minimal HTM (default 0.8|0.7)
#                                   = >0 && <1 , real
#       in:                     $optDoHtmref   : 1|0 do or do NOT run
#       in:                     $optDoHtmtop   : 1|0 do or do NOT run
#                               
#            output files
#       in:                     $fileOutPhdLoc : human readable file
#       in:                     $fileOutRdbLoc : RDB formatted output
#       in:                     $fileOutNotLoc : file flagging that no HTM was detected
#                               
#            PERL libraries
#       in:                     $dirLib        : directory of PERL libs
#                                   = 0          to surpress (and believe scripts will run...)
#                               
#            temporary stuff
#       in:                     $dirWork       : working dir
#       in:                     $titleTmpLoc   : temporary files 'dirWork.titleTmp.jobid.extX'
#       in:                     $jobidLoc      : temporary files 'dirWork.titleTmp.jobid.extX'
#       in:                     $LdebugLoc     : =1 -> keep temporary files, =0 -> delete them
#       in:                     $fileOutScreen : screen dumpb of system call  if = 0: 0 -> STDOUT
#       in:                     $fhSbrErr      : error file handle
#                NOTE:              = 0          to surpress writing
#                               
#       out:                    1|0,msg,%tmpFiles(list='f1,f2,f3')  implicit: files
#       out:                    
#       out:                    $fileTmp{$kwd} : with
#                               $fileTmp{kwd}= 'kwd1,kwd2,kwd3,...'
#                               $fileTmp{$kwd}  file, e.g.:
#                               $fileTmp{"sec|acc|htm|both|3","phd|rdb"}
#                NOTE:                  tmpFiles='' if ! debug (all deleted, already)
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."phdRun";
				# ------------------------------
				# arguments given ?
    return(&errSbr("not def fileHssp!"))             if (! defined $fileHssp);
    return(&errSbr("not def chainHssp!"))            if (! defined $chainHssp);
    return(&errSbr("not def fileParaSec!"))          if (! defined $fileParaSec);
    return(&errSbr("not def fileParaAcc!"))          if (! defined $fileParaAcc);
    return(&errSbr("not def fileParaHtm!"))          if (! defined $fileParaHtm);
    return(&errSbr("not def optPhd3!"))              if (! defined $optPhd3);
    return(&errSbr("not def optRdbLoc!"))            if (! defined $optRdbLoc);
    return(&errSbr("not def fileAbbrRdb!"))          if (! defined $fileAbbrRdb);

    return(&errSbr("not def exePhdLoc!"))            if (! defined $exePhdLoc);
    return(&errSbr("not def exeHtmfilLoc!"))         if (! defined $exeHtmfilLoc);
    return(&errSbr("not def exeHtmisitLoc !"))       if (! defined $exeHtmisitLoc);
    return(&errSbr("not def exeHtmrefLoc!"))         if (! defined $exeHtmrefLoc);
    return(&errSbr("not def exeHtmtopLoc!"))         if (! defined $exeHtmtopLoc);

    return(&errSbr("not def optMachLoc!"))           if (! defined $optMachLoc);
    return(&errSbr("not def optKgLoc!"))             if (! defined $optKgLoc);
    return(&errSbr("not def useridLoc!"))            if (! defined $useridLoc);
    return(&errSbr("not def optIsDecLoc!"))          if (! defined $optIsDecLoc);
    return(&errSbr("not def optNiceInLoc!"))         if (! defined $optNiceInLoc);

    return(&errSbr("not def optDoHtmfilLoc!"))       if (! defined $optDoHtmfilLoc);
    return(&errSbr("not def optDoHtmisitLoc!"))      if (! defined $optDoHtmisitLoc);
    return(&errSbr("not def optHtmisitMinLoc!"))     if (! defined $optHtmisitMinLoc);
    return(&errSbr("not def optDoHtmrefLoc!"))       if (! defined $optDoHtmrefLoc);
    return(&errSbr("not def optDoHtmtopLoc!"))       if (! defined $optDoHtmtopLoc);

    return(&errSbr("not def fileOutPhdLoc!"))        if (! defined $fileOutPhdLoc);
    return(&errSbr("not def fileOutRdbLoc!"))        if (! defined $fileOutRdbLoc);
    return(&errSbr("not def fileOutNotLoc!"))        if (! defined $fileOutNotLoc);

    return(&errSbr("not def dirLib!"))               if (! defined $dirLib);

    return(&errSbr("not def dirWorkLoc!"))           if (! defined $dirWorkLoc);
    return(&errSbr("not def titleTmpLoc!"))          if (! defined $titleTmpLoc);
    return(&errSbr("not def jobidLoc!"))             if (! defined $jobidLoc);
    return(&errSbr("not def LdebugLoc!"))            if (! defined $LdebugLoc);
#    return(&errSbr("not def !"))           if (! defined $);
				# ------------------------------
				# input files existing ?
    return(&errSbr("miss in file '$fileHssp'!"))     if (! -e $fileHssp);
    return(&errSbr("not HSSP file '$fileHssp'!"))    if (! &is_hssp($fileHssp));
    return(&errSbr("empty HSSP file '$fileHssp'!"))  if (&is_hssp_empty($fileHssp));
                                # ------------------------------
                                # executables ok?
    foreach $exe ($exePhdLoc,$exeHtmfilLoc,$exeHtmisitLoc,$exeHtmrefLoc,$exeHtmtopLoc){
        return(&errSbr("miss in file '$exe'!"))      if (! -e $exe && ! -l $exe);
        return(&errSbr("not executable '$exe'!"))    if (! -x $exePhdLoc ); }
				# ------------------------------
				# syntax check
    return(&errSbr("ini: FORTRAN PHD optPhd ($optPhd3) has to be '3|both|sec|acc|htm'"))
	if ($optPhd3 !~ /^(3|both|sec|acc|htm)$/);
    return(&errSbr("ini: PHD parameter (sec) file=$fileParaSec, missing"))
	if ($fileParaSec && ! -e $fileParaSec);
    return(&errSbr("ini: PHD parameter (acc) file=$fileParaAcc, missing"))
	if ($fileParaAcc && ! -e $fileParaAcc);
    return(&errSbr("ini: PHD parameter (acc) file=$fileParaAcc, missing"))
	if ($fileParaAcc && ! -e $fileParaAcc);

				# ------------------------------
				# other input
    $fhSbrErr="STDOUT"          if (! defined $fhSbrErr);
    $fileOutScreenLoc=0         if (! defined $fileOutScreenLoc || ! $fileOutScreenLoc);

    $errMsg= "*** ERROR $sbrName: in:\n";

    undef %Lok;                 # for results from PHD
    foreach $des ("sec","acc","htm") {
        $Lok{$des}=1; }
                                # ------------------------------
                                # temporary files
                                # ------------------------------
    &phdRunIniFileNames($optPhd3,$dirWorkLoc,$titleTmpLoc,$jobidLoc);
    return(&errSbr("ini: build up of temporary files (phdRunIniFileNames) failed\n"))
        if (! defined $fileTmp{"kwd"} || length($fileTmp{"kwd"}) < 3);

                                # --------------------------------------------------
                                # running all 3 FORTRAN programs
                                # --------------------------------------------------

                                 # ------------------------------
    if ($optPhd3=~/sec|3|both/){ # running PHDsec
                                 # ------------------------------
	$optPhd="sec";
	($Lok{"sec"},$msg)=
	    &phdRun1($fileHssp,$chainHssp,$par{"exePhd"},$optPhd,$fileParaSec,$optRdbLoc,
                     $optMachLoc,$optKgLoc,$useridLoc,$optIsDecLoc,$optNiceInLoc,
                     $fileTmp{"$optPhd","phd"},$fileTmp{"$optPhd","rdb"},
                     $dirWorkLoc,$fileOutScreenLoc,$fhSbrErr);
        $errMsg.=$msg."\n"      if (! $Lok{"$optPhd"}); }

                                 # ------------------------------
    if ($optPhd3=~/acc|3|both/){ # running PHDacc
                                 # ------------------------------
	$optPhd="acc";
	($Lok{"acc"},$msg)=
	    &phdRun1($fileHssp,$chainHssp,$par{"exePhd"},$optPhd,$fileParaAcc,$optRdbLoc,
                     $optMachLoc,$optKgLoc,$useridLoc,$optIsDecLoc,$optNiceInLoc,
                     $fileTmp{"$optPhd","phd"},$fileTmp{"$optPhd","rdb"},
                     $dirWorkLoc,$fileOutScreenLoc,$fhSbrErr);
        $errMsg.=$msg."\n"      if (! $Lok{"$optPhd"}); }

				# ------------------------------
    if ($optPhd3=~/htm|3/){     # running PHDhtm
                                # ------------------------------
	$optPhd="htm";          # FORTRAN
	($Lok{"htm"},$msg)=
	    &phdRun1($fileHssp,$chainHssp,$par{"exePhd"},$optPhd,$fileParaHtm,$optRdbLoc,
                     $optMachLoc,$optKgLoc,$useridLoc,$optIsDecLoc,$optNiceInLoc,
                     $fileTmp{"$optPhd","phd"},$fileTmp{"$optPhd","rdb"},
                     $dirWorkLoc,$fileOutScreenLoc,$fhSbrErr);
        $errMsg.=$msg."\n"      if (! $Lok{"$optPhd"}); 
                                # ------------------------------
				# post-processing PHDhtm
        if (-e $fileTmp{"htm","phd"} &&
            ($optDoHtmisitLoc || $optDoHtmrefLoc || $optDoHtmtopLoc || $optDoHtmfilLoc) ) {

                                # delete FLAG file if existing
            if (-e $fileOutNotLoc){
                unlink ($fileOutNotLoc);
                print $fhSbrErr 
                    "*** WATCH! flag file '$fileOutNotLoc' (flag for NOT htm) existed!\n"
                        if ($fhSbrErr); }

            ($Lok{"$optPhd"},$msg,$LisHtm)=
                &phdRunPost1($fileHssp,$chainHssp,$fileTmp{"htm","rdb"},$dirLib,$optNiceInLoc,
			     $exeHtmfilLoc,$exeHtmisitLoc,$exeHtmrefLoc,$exeHtmtopLoc,
			     $optDoHtmfilLoc,$optDoHtmisitLoc,$optHtmisitMinLoc,
			     $optDoHtmrefLoc,$optDoHtmtopLoc,
			     $fileOutNotLoc,$fileTmp{"htmfin","rdb"},
			     $fileTmp{"htmfil","rdb"},
			     $fileTmp{"htmref","rdb"},$fileTmp{"htmtop","rdb"},
			     $fileOutScreenLoc,$fhSbrErr);
            $errMsg.=$msg."\n"  if (! $Lok{"$optPhd"}); }
                                # skip post-processing
        elsif (-e $fileTmp{"htm","phd"}) {
            $LisHtm=1;
            $fileTmp{"htmfin","rdb"}=$fileTmp{"htm","rdb"}; } 
        else {
            $LisHtm=0; } }
				# -------------------------------------------------
				# error check
				# -------------------------------------------------
    $Lerr=0;
    foreach $des("sec","acc","htm"){
	if (! $Lok{"$des"}){ 
	    $Lerr=1;
	    $errMsg.="*** ERROR $scrName: PHD$des: no pred file (in=$fileHssp)\n";}}
    return(&errSbrMsg("after all 3",$errMsg)) if ($Lerr);
                
				# -------------------------------------------------
				# now writing output for one file
				# -------------------------------------------------
    if ($optPhd3 =~/^(3|both)$/){
	$optPhd3Tmp=$optPhd3;
        if ($optPhd3 eq "both" || ! $LisHtm){
				# reduce mode if NOT htm
            $optPhd3Tmp="both";
				# dummy
            $fileTmp{"htmfin","rdb"}=0; }

                                # ------------------------------
                                # call writer
                                # 
                                # ++++++++++++++++++++++++++++++
                                # NOTE: not writing file.phd, yet yy
                                # ++++++++++++++++++++++++++++++
        ($Lok,$msg)=
            &phdRunWrt($optPhd3Tmp,$optRdbLoc,$fileAbbrRdb,$fileTmp{"sec","rdb"},
                       $fileTmp{"acc","rdb"},$fileTmp{"htmfin","rdb"},
                       $fileOutPhdLoc,$fileOutRdbLoc);
        return(&errSbrMsg("phdRunWrt failed",$msg)) if (! $Lok);
        print $fhSbrErr "-*- WARN $sbrName: phdRunWrt returned warn:\n",$msg,"\n"
            if ($fhSbrErr && $msg =~ /WARN/); }
                                # ------------------------------
    else {                      # simply copy
        foreach $des("sec","acc","htm"){
            next if ($optPhd3 ne $des);
	    $desrdb=$des;
	    $desrdb="htmfin"   if ($des eq "htm"); # take refined one!
            $filePhd=$fileTmp{"$des","phd"};
            $fileRdb=$fileTmp{"$desrdb","rdb"}; 
            last; }
	($Lok,$msg)=
            &sysCpfile($filePhd,$fileOutPhdLoc) if (-e $filePhd);
        return(&errSbr("fin: failed copy ($filePhd->$fileOutPhdLoc)")) if (! $Lok);
        ($Lok,$msg)=
            &sysCpfile($fileRdb,$fileOutRdbLoc) if (-e $fileRdb);
        return(&errSbr("fin: failed copy ($fileRdb->$fileOutRdbLoc)")) if (! $Lok); }

				# -------------------------------------------------
                                # clean up?
				# -------------------------------------------------
    if (! $LdebugLoc){
        @tmp=split(/,/,$fileTmp{"kwd"});
        foreach $file (@tmp){
            next if (! -e $file);
            unlink($file);
            print $fhSbrErr "--- $sbrName: rm temp file '$file'\n" if ($fhSbrErr); }
        $fileTmp{"kwd"}=0; }

    return(1,"ok $sbrName",%fileTmp);
}				# end of phdRun

#===============================================================================
sub phdRunIniFileNames {
    local($optPhdLoc,$dirWorkLoc,$titleTmpLoc,$jobidLoc)=@_;
    $[ =1 ;
#-------------------------------------------------------------------------------
#   phdRunIniFileNames          assigns names to intermediate files for FORTRAN PHD
#       in:                     $optPhdLoc     : mode = 3|both|sec|acc|htm
#       in:                     $dirWork       : working dir
#       in:                     $titleTmpLoc   : temporary files 'dirWork.titleTmp.jobid.extX'
#       in:                     $jobidLoc      : temporary files 'dirWork.titleTmp.jobid.extX'
#       out:                    $fileTmp{$kwd} : with
#                               $fileTmp{kwd}= 'kwd1,kwd2,kwd3,...'
#                               $fileTmp{$kwd}  file, e.g.:
#                               $fileTmp{"sec|acc|htm|both|3","phd|rdb"}
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    undef %fileTmp;
				# ------------------------------
				# intermediate files
				# ------------------------------
    if ($optPhdLoc=~/sec|both|3/){
	$fileTmp{"sec","phd"}=   $dirWorkLoc.$titleTmpLoc.$jobidLoc.".phdSec";
	$fileTmp{"sec","rdb"}=   $dirWorkLoc.$titleTmpLoc.$jobidLoc.".rdbSec"; }
    if ($optPhdLoc=~/acc|both|3/){
	$fileTmp{"acc","phd"}=   $dirWorkLoc.$titleTmpLoc.$jobidLoc.".phdAcc";    
	$fileTmp{"acc","rdb"}=   $dirWorkLoc.$titleTmpLoc.$jobidLoc.".rdbAcc"; }
    if ($optPhdLoc=~/htm|3/){
	$fileTmp{"htm","phd"}=   $dirWorkLoc.$titleTmpLoc.$jobidLoc.".phdHtm";    
	$fileTmp{"htm","rdb"}=   $dirWorkLoc.$titleTmpLoc.$jobidLoc.".rdbHtm";    
	$fileTmp{"htmfin","rdb"}=$dirWorkLoc.$titleTmpLoc.$jobidLoc.".rdbHtmfin"; 
	$fileTmp{"htmfil","rdb"}=$dirWorkLoc.$titleTmpLoc.$jobidLoc.".rdbHtmfil"; 
	$fileTmp{"htmref","rdb"}=$dirWorkLoc.$titleTmpLoc.$jobidLoc.".rdbHtmref"; 
	$fileTmp{"htmtop","rdb"}=$dirWorkLoc.$titleTmpLoc.$jobidLoc.".rdbHtmtop"; }
    if  ($optPhdLoc=~/both|3/){ # note 3 also both for the case that no HTM detected!
	$fileTmp{"both","phd"}=  $dirWorkLoc.$titleTmpLoc.$jobidLoc.".phdBoth";   
	$fileTmp{"both","rdb"}=  $dirWorkLoc.$titleTmpLoc.$jobidLoc.".rdbBoth"; }
    if  ($optPhdLoc=~/3/){
	$fileTmp{"3","phd"}=     $dirWorkLoc.$titleTmpLoc.$jobidLoc.".phdAll3";   
	$fileTmp{"3","rdb"}=     $dirWorkLoc.$titleTmpLoc.$jobidLoc.".rdbAll3"; }
    @tmp=sort keys %fileTmp;
    $fileTmp{"kwd"}=join(',',@tmp);
    $fileTmp{"kwd"}=~s/,*$//g;
}				# phdRunIniFileNames

#===============================================================================
sub phdRun1 {
    local ($fileHssp,$chainIn,$exePhdLoc,$optPhdLoc,$optParaLoc,$optRdbLoc,
	   $optMachLoc,$optKgLoc,$useridLoc,$optIsDecLoc,$optNiceInLoc,
	   $fileOutPhdLoc,$fileOutRdbLoc,$dirWorkLoc,$fileOutScreenLoc,$fhSbrErr) = @_;
    local ($tmp,$fileHssp_loc,$optPath_work_loc,$optPhd_loc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   phdRun1                     runs the FORTRAN program PHD once (sec XOR acc XOR htm) 
#       in:                     $fileHssp      : HSSP file to run it on
#       in:                     $chainIn       : name of chain
#       in:                     $exePhd        : FORTRAN executable for PHD
#       in:                     $optPhd        : mode = sec|acc|htm  (else -> ERROR)
#       in:                     $optPara       : name of file with phd.f network parameters
#       in:                     $optRdbLoc     : write RDB, or not (ancient)
#       in:                     $optMachLoc    : for tim
#       in:                     $optKgLoc      : for KG format
#       in:                     $useridLoc     : user name         (for PP/non-pp)
#       in:                     $optIsDecLoc   : machin is DEC     (ancient)
#       in:                     $fileOutPhdLoc : human readable file
#       in:                     $fileOutRdbLoc : RDB formatted output
#       in:                     $dirWork       : working dir
#       in:                     $
#       in:                     $fileOutScreen : screen dumpb of system call  if = 0: 0 -> STDOUT
#       in:                     $fhSbrErr      : error file handle
#                NOTE:              = 0          to surpress writing
#       out:                    1|0,msg, implicit: files
#       err:                    ok -> (1,"ok sbr"), err -> (0,"msg")
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."phdRun1";
				# ------------------------------
				# arguments given ?
    return(&errSbr("not def fileHssp!"))             if (! defined $fileHssp);
    return(&errSbr("not def chainIn!"))              if (! defined $chainIn);
    return(&errSbr("not def exePhdLoc!"))            if (! defined $exePhdLoc);
    return(&errSbr("not def optPhdLoc!"))            if (! defined $optPhdLoc);
    return(&errSbr("not def optParaLoc!"))           if (! defined $optParaLoc);
    return(&errSbr("not def optRdbLoc!"))            if (! defined $optRdbLoc);
    return(&errSbr("not def optMachLoc!"))           if (! defined $optMachLoc);
    return(&errSbr("not def optKgLoc!"))             if (! defined $optKgLoc);
    return(&errSbr("not def useridLoc!"))            if (! defined $useridLoc);
    return(&errSbr("not def optIsDecLoc!"))          if (! defined $optIsDecLoc);
    return(&errSbr("not def optNiceInLoc!"))         if (! defined $optNiceInLoc);
    return(&errSbr("not def fileOutPhdLoc!"))        if (! defined $fileOutPhdLoc);
    return(&errSbr("not def fileOutRdbLoc!"))        if (! defined $fileOutRdbLoc);
    return(&errSbr("not def dirWorkLoc!"))           if (! defined $dirWorkLoc);
				# ------------------------------
				# input files existing ?
    return(&errSbr("miss in file '$fileHssp'!"))     if (! -e $fileHssp);
    return(&errSbr("miss in file '$exePhdLoc'!"))    if (! -e $exePhdLoc && ! -l $exePhdLoc);
    return(&errSbr("not executable '$exePhdLoc'!"))  if (! -x $exePhdLoc );

				# ------------------------------
				# syntax check
    return(&errSbr("ini: FORTRAN PHD optPhd has to be 'sec,acc,htm', is=$optPhdLoc,"))
	if ($optPhdLoc !~ /^(sec|acc|htm)$/);
    return(&errSbr("ini: PHD parameter file=$optParaLoc, missing"))
	if ( ! -e $optParaLoc);
				# ------------------------------
				# other input
    $fhSbrErr="STDOUT"          if (! defined $fhSbrErr);
    $fileOutScreenLoc=0         if (! defined $fileOutScreenLoc || ! $fileOutScreenLoc);

				# ------------------------------
				# build up input arguments
				# ------------------------------
				# working directory
    $optPath_work_loc=$dirWorkLoc;
    if ( length($dirWorkLoc)<3 || $dirWorkLoc eq "unk" ){
        if ( defined $PWD && length($PWD)>1 ) { 
	    $optPath_work_loc=$PWD;  }
        else {
	    $optPath_work_loc="no"; }}

    $optPhd_loc= $optPhdLoc;	# run option
    $optPhd_loc= "exp"          if ($optPhdLoc eq "acc"); # correct acc->exp

    $optUserPhd= 0;		# PP option
    $optUserPhd= 1              if ($useridLoc eq "phd");

    @arg=($optMachLoc,		# for tim
	  $optKgLoc,		# for KG format
	  $optPhd_loc,		# mirror            (acc -> exp)
	  $optUserPhd,		# user name         (for PP/non-pp)
	  $optParaLoc,		# Para-file
	  $optRdbLoc,		# write RDB, or not (ancient)
	  $optIsDecLoc,		# machin is DEC     (ancient)
	  $optPath_work_loc,	# working dir
	  $fileOutPhdLoc);	# human readable file

    push(@arg,$fileOutRdbLoc)	# write RDB file ?
	if ($optRdbLoc !~ /no/ && defined $fileOutRdbLoc && $fileOutRdbLoc ne "unk");

				# ------------------------------
				# massage input HSSP file
    $fileHssp_loc=$fileHssp;
				# add dir
    $fileHssp_loc=$optPath_work_loc."/".$fileHssp
	if ($fileHssp=~/\// && $fileHssp !~/^\// && -d $optPath_work_loc);
				# add chain
    $fileHssp_loc.="_\!_".$chainIn
	if ($chainIn ne "unk" && length($chainIn)>0 && $chainIn ne " ");

				# ------------------------------
				# which option for nice? (job priority)
    if    ($optNiceInLoc =~ /no/)   { 
	$optNice_loc="";}
    elsif ($optNiceInLoc =~ /nice/) { 
	$optNice_loc=$optNiceInLoc; 
	$optNice_loc=~s/\s//g;
	$optNice_loc=~s/.*nice.*(-\d+)$/nice $1/; }
    else                              { 
	$optNice_loc="";}

    $cmd=$cmdSys="";		# avoid warnings

				# --------------------------------------------------
				# now run it
				# --------------------------------------------------

    # *************************
    $arg=join(' ',@arg);	# final argument to run
    $cmd=$optNice_loc." ".	# final command
	$exePhdLoc." ".
	    $fileHssp_loc." ".$arg;
    eval  "\$cmdSys=\"$cmd\"";
    # *************************

    print $fhSbrErr "--- run PHD\n$cmd\n" if ($fhSbrErr);

#   ************************************************************

    ($Lok,$msg)=&sysRunProg($cmdSys,$fileOutScreenLoc,$fhSbrErr); # system call PHD

#   ************************************************************

				# ------------------------------
				# system ERROR
    return(&errSbrMsg("failed on PHDfor ($exePhdLoc):",$msg)) if (! $Lok);

				# ------------------------------
				# ok !
    return(1,"ok $sbrName") 
	if (($optRdbLoc !~/no/ && -e $fileOutRdbLoc && -e $fileOutPhdLoc) ||
	    ($optRdbLoc =~/no/ && -e $fileOutPhdLoc) );

				# ------------------------------
				# other ERRORS:
    $msg= "*** ERROR $sbrName: failed on system call to FORTRAN ($exePhdLoc):";
    $msg.="***                 no pred file ',".$fileOutPhdLoc."'\n"
	if (! -e $fileOutPhdLoc);
    $msg.="***                 no RDB  file ',".$fileOutRdbLoc."'\n"
	if ($optRdbLoc !~ /no/ && ! -e $fileOutRdbLoc);

    print $fhSbrErr "$msg"      if ($fhSbrErr);

    return(0,$msg);
}				# end of phdRun1

#==============================================================================
sub phdRunPost1 {
    local($fileHssp,$chainHssp,$fileInRdbLoc,$dirLib,$optNiceInLoc,
	  $exeHtmfilLoc,$exeHtmisitLoc,$exeHtmrefLoc,$exeHtmtopLoc,
          $LdoHtmfilLoc,$LdoHtmisitLoc,$optHtmMinValLoc,$LdoHtmrefLoc,$LdoHtmtopLoc,
          $fileOutNotLoc,$fileOutRdbLoc,$fileTmpFil,$fileTmpRef,$fileTmpTop,
	  $fileOutScreenLoc,$fhSbrErr) = @_;
    local($SBR);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   phdRunPost1                       
#       in:                     $fileHssp      : HSSP file to run it on
#       in:                     $chainHssp     : name of chain
#       in:                     $fileInRdbLoc  : RDB file from PHD fortran
#       in:                     $dirLib        : directory of PERL libs
#                                   = 0          to surpress
#       in:                     $optNiceLoc    : priority 'nonice|nice|nice-n'
#       in:                     $exeHtmfilLoc  : Perl executable for HTMfil
#       in:                     $exeHtmisitLoc : Perl executable for HTMisit
#       in:                     $exeHtmrefLoc  : Perl executable for HTMref
#       in:                     $exeHtmtopLoc  : Perl executable for HTMtop
#       in:                     $LdoHtmfil     : 1|0 do or do NOT run
#       in:                     $LdoHtmisit    : 1|0 do or do NOT run
#       in:                     $optHtmMinVal  : strength of minimal HTM (default 0.8|0.7)
#                                   = >0 && <1 , real
#       in:                     $LdoHtmref     : 1|0 do or do NOT run
#       in:                     $LdoHtmtop     : 1|0 do or do NOT run
#       in:                     $fileOutNotLoc : file flagging that no HTM was detected
#       in:                     $fileOutRdbLoc : final RDB file
#       in:                     $fileTmpFil    : temporary file from htmfil
#       in:                     $fileTmpIsit   : temporary file from htmfil
#       in:                     $fileTmpRef    : temporary file from htmfil
#       in:                     $fileTmpTop    : temporary file from htmfil
#       in:                     $LdebugLoc     : =1 -> keep temporary files, =0 -> delete them
#       in:                     $fileOutScreen : screen dumpb of system call  if = 0: 0 -> STDOUT
#       in:                     $fhSbrErr      : error file handle
#                NOTE:              = 0          to surpress writing
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR="lib-br:"."phdRunPost1"; 
    $fhinLoc="FHIN_"."$SBR"; $fhoutLoc="FHOUT_".$SBR;
				# ------------------------------
				# arguments given ?
    return(&errSbr("not def fileHssp!",$SBR))             if (! defined $fileHssp);
    return(&errSbr("not def chainHssp!",$SBR))            if (! defined $chainHssp);
    return(&errSbr("not def fileInRdbLoc!",$SBR))         if (! defined $fileInRdbLoc);
    return(&errSbr("not def dirLib!",$SBR))               if (! defined $dirLib);
    return(&errSbr("not def optNiceInLoc!",$SBR))         if (! defined $optNiceInLoc);

    return(&errSbr("not def exeHtmfilLoc!",$SBR))         if (! defined $exeHtmfilLoc);
    return(&errSbr("not def exeHtmisitLoc !",$SBR))       if (! defined $exeHtmisitLoc);
    return(&errSbr("not def exeHtmrefLoc!",$SBR))         if (! defined $exeHtmrefLoc);
    return(&errSbr("not def exeHtmtopLoc!",$SBR))         if (! defined $exeHtmtopLoc);

    return(&errSbr("not def LdoHtmfilLoc!",$SBR))         if (! defined $LdoHtmfilLoc);
    return(&errSbr("not def LdoHtmisitLoc!",$SBR))        if (! defined $LdoHtmisitLoc);
    return(&errSbr("not def optHtmisitMinLoc!",$SBR))     if (! defined $optHtmisitMinLoc);
    return(&errSbr("not def LdoHtmrefLoc!",$SBR))         if (! defined $LdoHtmrefLoc);
    return(&errSbr("not def LdoHtmtopLoc!",$SBR))         if (! defined $LdoHtmtopLoc);

    return(&errSbr("not def fileOutNotLoc!",$SBR))        if (! defined $fileOutNotLoc);
    return(&errSbr("not def fileOutRdbLoc!",$SBR))        if (! defined $fileOutRdbLoc);
    return(&errSbr("not def fileTmpFil!",$SBR))           if (! defined $fileTmpFil);
    return(&errSbr("not def fileTmpRef!",$SBR))           if (! defined $fileTmpRef);
    return(&errSbr("not def fileTmpTop!",$SBR))           if (! defined $fileTmpTop);
				# ------------------------------
				# input files existing ?
#    return(&errSbr("miss in file '$fileHssp'!"))     if (! -e $fileHssp);
#    return(&errSbr("not HSSP file '$fileHssp'!"))    if (! &is_hssp($fileHssp));
#    return(&errSbr("empty HSSP file '$fileHssp'!"))  if (! &is_hssp_empty($fileHssp));
    return(&errSbr("no rdb '$fileInRdbLoc'!",$SBR))   if (! -e $fileInRdbLoc);

                                # ------------------------------
                                # executables ok?
    foreach $exe ($exeHtmfilLoc,$exeHtmisitLoc,$exeHtmrefLoc,$exeHtmtopLoc){
        return(&errSbr("miss in exe '$exe'!",$SBR))      if (! -e $exe && ! -l $exe);
        return(&errSbr("not executable '$exe'!",$SBR))   if (! -x $exePhdLoc ); }

				# ------------------------------
				# defaults

				# xx
				# xx PASS!!!!
				# xx 
    
    $minLenDefLoc= 18;		# length of best helix (18)
    $doStatDefLoc=1;		# compile further statistics on residues, avLength asf

				# ------------------------------
				# other input
    $fhSbrErr="STDOUT"          if (! defined $fhSbrErr);
    $fileOutScreenLoc=0         if (! defined $fileOutScreenLoc || ! $fileOutScreenLoc);

				# xx
				# xx PASS!!!!
				# xx 
    
    $minLenLoc=$minLenDefLoc    if (! defined $minLenLoc || $minLenLoc == 0);
    $doStatLoc=$doStatDefLoc    if (! defined $doStatLoc);


				# ------------------------------
				# which option for nice? (job priority)
    if    ($optNiceInLoc =~ /no/)   { 
	$optNiceTmp="";}
    elsif ($optNiceInLoc =~ /nice/) { 
	$optNiceTmp=$optNiceInLoc; 
	$optNiceTmp=~s/\s//g;
	$optNiceTmp=~s/.*nice.*(-\d+)$/nice $1/; }
    else                              { 
	$optNiceTmp="";}

				# --------------------------------------------------
                                # is HTM ?
    if ($LdoHtmisitLoc) {       # --------------------------------------------------


	($Lok,$msg,$LisHtm,%tmp)=
	    &phdHtmIsit($fileInRdbLoc,$optHtmMinValLoc,$minLenLoc,$doStatLoc);
	return(&errSbrMsg("failed on phdHtmIsit (file=$fileInRdbLoc,".
			  "minVal=$optHtmMinValLoc,, minLen=$minLenLoc, ".
			  "stat=$doStatLoc",$msg,$SBR)) if (! $Lok);
                                # copy to final RDB
        ($Lok,$msg)=
            &sysCpfile($fileInRdbLoc,$fileOutRdbLoc);
	return(&errSbrMsg("htmisit copy",$msg,$SBR),0)  if (! $Lok);

	if (! $LisHtm){
	    &open_file("$fhoutLoc",">$fileOutNotLoc") ||
		return(&errSbr("failed creating flag file '$fileOutNotLoc'",$SBR));
	    print $fhoutLoc
		"value of best=",$tmp{"valBest"},
		", min=$optHtmMinValLoc, posBest=",$tmp{"posBest"},",\n";
	    close($fhoutLoc); 
                                # **********************
				# NOT MEMBRANE -> return
	    return(1,"none after htmisit ($SBR)",0); }}

				# --------------------------------------------------
    if ($LdoHtmfilLoc) {        # old hand waving filter ?
				# --------------------------------------------------
                                # build up argument
        @tmp=($fileInRdbLoc,$fileTmpFil,$fileOutNotLoc);
        push(@tmp,"dirLib=".$dirLib)                       if ($dirLib && -d $dirLib);
        push(@tmp,"not_screen")                            if (! $fhSbrErr && 
							       $fhSbrErr ne "STDOUT");
        $arg=join(' ',@tmp); 
                                # run system call
        if ($exeHtmfilLoc =~ /\.pl/) {
            $cmd="$optNiceTmp $exeHtmfilLoc $arg";
            eval "\$command=\"$cmd\"";
	    ($Lok,$msg)=
                &sysRunProg($command,$fileOutScreenLoc,$fhSbrErr);
	    return(&errSbrMsg("htmfil=$exeHtmfilLoc, msg=",$msg,$SBR)) if (! $Lok); }
        else {                  # include package
            &phd_htmfil'phd_htmfil(@tmp);                        # e.e'
            $tmp=$exeHtmfilLoc;$tmp=~s/\.pm/\.pl/; $cmd="$tmp $arg";
            print $fhSbrErr "$cmd\n"                       if ($fhSbrErr); }
        print $fhSbrErr "--- ","-" x 50,"\n"               if ($fhSbrErr);
                                # copy to final RDB
        ($Lok,$msg)=
            &sysCpfile($fileTmpFil,$fileOutRdbLoc)         if (-e $fileTmpFil);}
                
				# --------------------------------------------------
    if ($LdoHtmrefLoc) {        # do refinement ?
				# --------------------------------------------------
                                # build up argument
        @tmp=($fileInRdbLoc,"nof file_out=$fileTmpRef");
        push(@tmp,"dirLib=".$dirLib)                       if ($dirLib && -d $dirLib);
        push(@tmp,"not_screen")                            if (! $fhSbrErr && 
							       $fhSbrErr ne "STDOUT");
        $arg=join(' ',@tmp);
                                # run system call
        if ($exeHtmrefLoc=~/\.pl/){
            $cmd="$optNiceTmp $exeHtmrefLoc $fileInRdbLoc $arg";
            eval "\$command=\"$cmd\"";
	    ($Lok,$msg)=
                &sysRunProg($command,$fileOutScreenLoc,$fhSbrErr);
	    return(&errSbrMsg("htmref=$exeHtmrefLoc, msg=",$msg,$SBR),0) if (! $Lok); }
        else {                  # include package
            &phd_htmref'phd_htmref(@tmp);                        # e.e'
            $tmp=$exeHtmrefLoc;$tmp=~s/\.pm/\.pl/; $cmd="$tmp $arg";
            print $fhSbrErr "$cmd\n"                       if ($fhSbrErr); }
        print $fhSbrErr "--- ","-" x 50,"\n"               if ($fhSbrErr);
        return(&errSbr("after htmref=$exeHtmrefLoc, no out=$fileTmpRef",$SBR),0) 
            if (! -e $fileTmpRef);
        ($Lok,$msg)=            # copy to final RDB
            &sysCpfile($fileTmpRef,$fileOutRdbLoc);
	return(&errSbrMsg("htmref copy",$msg,$SBR),0)      if (! $Lok); }

				# --------------------------------------------------
    if ($LdoHtmtopLoc) {        # do the topology prediction ?
				# --------------------------------------------------
                                # build up argument
	if    (-e $fileTmpRef){ $file_tmp=$fileTmpRef;   $arg=" ref"; }
	elsif (-e $fileTmpFil){ $file_tmp=$fileTmpFil;   $arg=" fil"; }
        else                  { $file_tmp=$fileInRdbLoc; $arg=" nof"; }
	$tmp= "file_out=$fileTmpTop file_hssp=$fileHssp";
	$tmp.="_".$chainHssp                               if (defined $chainHssp && 
                                                               $chainHssp=~/^[0-9A-Z]$/);
	@tmp=($file_tmp,$tmp);
        push(@tmp,"dirLib=".$dirLib)                       if ($dirLib && -d $dirLib);
        push(@tmp,"not_screen")                            if (! $fhSbrErr && 
							       $fhSbrErr ne "STDOUT");
        $arg=join(' ',@tmp);
                                # run system call
        if ($exeHtmtopLoc=~/\.pl/){
            $cmd="$optNiceTmp $exeHtmtopLoc $arg";
            eval "\$command=\"$cmd\"";
	    ($Lok,$msg)=
                &sysRunProg($command,$fileOutScreenLoc,$fhSbrErr);
	    return(&errSbrMsg("htmtop=$exeHtmtopLoc, msg=",$msg,$SBR),0) if (! $Lok); }
        else {                  # include package
            &phd_htmtop'phd_htmtop(@tmp);                        # e.e'
            $tmp=$exeHtmtopLoc;$tmp=~s/\.pm/\.pl/; $cmd="$tmp $arg";
            print $fhSbrErr "$cmd\n"                       if ($fhSbrErr); }
        print $fhSbrErr "--- ","-" x 50,"\n"               if ($fhSbrErr);
	return(&errSbr("after htmtop=$exeHtmtopLoc, no out=$fileTmpTop",$SBR),0) 
            if (! -e $fileTmpTop);
        ($Lok,$msg)=            # copy to final RDB
            &sysCpfile($fileTmpTop,$fileOutRdbLoc);
	return(&errSbrMsg("htmtop copy",$msg,$SBR),0)      if (! $Lok); }
    
    return(1,"ok $SBR",1);
}				# end of phdRunPost1

#===============================================================================
sub phdRunWrt {
    local($optPhd3Loc,$optRdbLoc,$fileAbbrRdb,$fileTmpSec,$fileTmpAcc,$fileTmpHtm,
          $fileOutPhdLoc,$fileOutRdbLoc) = @_ ;
    local($SBR);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   phdRunWrt                   merges 2-3 RDB files (sec,acc,htm?)
#
                                # ++++++++++++++++++++++++++++++
                                # NOTE: not writing file.phd, yet yy
                                # ++++++++++++++++++++++++++++++
#
#       in:                     $optPhd3       : mode = 3|both|sec|acc|htm  (else -> ERROR)
#       in:                     $optRdbLoc     : write RDB, or not (ancient)
#       in:                     $fileAbbrRdb   : file explaining the abbreviations in RDB file
#       in:                     $fileTmpSec    : PHD rdb with sec output
#       in:                     $fileTmpAcc    : PHD rdb with acc output
#       in:                     $fileTmpHtm    : PHD RDB with HTM output
#                                  = 0           if mode 'both' !!
#       in:                     $fileOutPhdLoc : name of ouptput file for human readable stuff
#       in:                     $fileOutRdbLoc : name of RDB output
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR="lib-br:"."phdRunWrt"; $fhinLoc="FHIN_".$SBR;$fhoutLoc="FHOUT_".$SBR;
    $errMsg="*** ERROR $SBR: \n".
	"in: opt=$optPhd3Loc,rdb=$optRdbLoc,fileAbbr=$fileAbbrRdb,\n".
	    "in: sec=$fileTmpSec,acc=$fileTmpAcc,htm=$fileTmpHtm,\n".
		"in: outPhd=$fileOutPhdLoc,outRdb=$fileOutRdbLoc,\n";
				# ------------------------------
				# arguments given ?
    return(&errSbr("not def optPhd3Loc!\n".$errMsg,$SBR))    if (! defined $optPhd3Loc);
    return(&errSbr("not def optRdbLoc!\n".$errMsg,$SBR))     if (! defined $optRdbLoc);
    return(&errSbr("not def fileAbbrRdb!\n".$errMsg,$SBR))   if (! defined $fileAbbrRdb);
    return(&errSbr("not def fileTmpSec!\n".$errMsg,$SBR))    if (! defined $fileTmpSec);
    return(&errSbr("not def fileTmpAcc!\n".$errMsg,$SBR))    if (! defined $fileTmpAcc);
    return(&errSbr("not def fileTmpHtm!\n".$errMsg,$SBR))    if (! defined $fileTmpHtm);
    return(&errSbr("not def fileOutPhdLoc!\n".$errMsg,$SBR)) if (! defined $fileOutPhdLoc);
    return(&errSbr("not def fileOutRdbLoc!\n".$errMsg,$SBR)) if (! defined $fileOutRdbLoc);
				# ------------------------------
				# syntax check
    return(&errSbr("ini: FORTRAN PHD optPhd ($optPhd3) has to be '3|both'\n".$errMsg))
	if ($optPhd3Loc !~ /^(3|both)$/);
				# ------------------------------
				# input files existing ?
    return(&errSbr("not def fileTmpSec!\n".$errMsg,$SBR))    if (! defined $fileTmpSec);
    return(&errSbr("not def fileTmpAcc!\n".$errMsg,$SBR))    if (! defined $fileTmpAcc);
    return(&errSbr("not def fileTmpHtm!\n".$errMsg,$SBR))    if (! defined $fileTmpHtm);

				# --------------------------------------------------
                                # RDB -> .phd files
				# --------------------------------------------------

                                # ++++++++++++++++++++++++++++++
                                # NOTE: not writing file.phd, yet yy
                                # ++++++++++++++++++++++++++++++

    if (0){                     # NOTE ONE DAY TO ADD!!!
        &open_file("$fhoutLoc",">$fileOutPhdLoc") || 
            return(&errSbr("could not open new=$fileOutPhdLoc\n".$errMsg,$SBR));
    }

				# --------------------------------------------------
				# now merge RDB files
				# --------------------------------------------------
                                # merge 3 (sec, acc, htm)
    if    ($optPhd3Loc eq "3" && $fileTmpHtm) {
        @fileTmp=($fileTmpSec,$fileTmpAcc,$fileTmpHtm); }
                                # merge 2 (sec,acc)
    else {
        @fileTmp=($fileTmpSec,$fileTmpAcc); }
                                # ------------------------------
                                # do merge
    ($Lok,$msg)=
        &phdRdbMerge($fileOutRdbLoc,$fileAbbrRdb,@fileTmp);

    return(&errSbrMsg("after phdRdbMerg on:".join(',',@fileTmp)." to $fileOutRdbLoc\n".
                      $errMsg,$msg,$SBR)) if (! $Lok);

    return(1,"ok $SBR");
}				# end of phdRunWrt

#===============================================================================
sub pirRdSeq {
    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc,$msg,$Lok,$seq,$id);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   pirRdSeq                    reads the sequence from a PIR file
#       in:                     file
#       out:                    (1,name,sequence in one string)
#       err:                    ok=(1,'ok'), err=(0,'msg')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:pirRdSeq";$fhinLoc="FHIN"."$sbrName";

    $Lok=       &open_file("$fhinLoc","$fileInLoc");
    if (! $Lok){$msg="*** ERROR $sbrName: '$fileInLoc' not opened\n";
		return(0,$msg,"error");}
    $seq=$id="";$ct=0;
    while (<$fhinLoc>) {$_=~s/\n//g;++$ct;
			if   ($ct==1){
			    $id=$_;$id=~s/^\s*\>\s*P1\s*\;\s*(\S+)[\s\n]*.*$/$1/g;}
			elsif($ct==2){$id.=", $_";}
			else {$_=~s/[\s\*]//g;
			      $seq.="$_";}}close($fhinLoc);
    $seq=~s/\s//g;$seq=~s/\*$//g;
    return(1,$id,$seq);
}				# end of pirRdSeq

#===============================================================================
sub pirRdMul {
    local($fileInLoc,$extr) = @_ ;
    local($sbrName,$fhinLoc,$msg,$Lok,$seq,$id);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   pirRdMul                    reads the sequence from a PIR file
#       in:                     file,$extr with:
#                               $extr = '1,5,6',   i.e. list of numbers to read
#       out:                    1|0,$id,$seq (note: many ids/seq separated by '\n'
#       err:                    ok=(1,'ok'), err=(0,'msg')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:pirRdMul";$fhinLoc="FHIN_"."$sbrName";

    &open_file("$fhinLoc","$fileInLoc") ||
        return(0,"*** ERROR $sbrName: fileIn=$fileInLoc not opened\n");

    $extr=~s/\s//g  if (defined $extr);
    $extr=0         if (! defined $extr || $extr =~ /[^0-9\,]/);
    if ($extr){@tmp=split(/,/,$extr); undef %tmp;
	       foreach $tmp(@tmp){
		   $tmp{$tmp}=1;}}

    $ct=$ctRd=$ctProt=0;        # ------------------------------
    while (<$fhinLoc>) {        # read the file
	$_=~s/\n//g;
	if ($_ =~ /^\s*>/){	# (1) = id (>P1;)
            $Lread=0;
	    ++$ctProt;
	    $id=$_;$id=~s/^\s*>\s*P1?\s*\;\s*//g;$id=~s/(\S+)[\s\n]*.*$/$1/g;$id=~s/^\s*|\s*$//g;
	    $id.="_";

	    $id.=<$fhinLoc>;	# (2) still id in second line
	    $id=~s/[\s\t]+/ /g;
	    $id=~s/_\s*$/g/;
	    $id=~s/^[\s\t]*|[\s\t]*$//g;
            if (! $extr || ($extr && defined $tmp{$ctProt} && $tmp{$ctProt})){
                ++$ctRd;$Lread=1;
		$tmp{"$ctRd","id"}=$id;
		$tmp{"$ctRd","seq"}="";}}
        elsif($Lread){		# (3+) sequence
            $_=~s/[\s\*]//g;
            $tmp{"$ctRd","seq"}.="$_";}}close($fhinLoc);
                                # ------------------------------
    $seq=$id="";		# join to long strings
    if ($ctRd > 1) {
	foreach $it(1..$ctRd){
	    $id.= $tmp{"$it","id"}."\n";
	    $tmp{"$it","seq"}=~s/\s//g;$tmp{"$it","seq"}=~s/\*$//g;
	    $seq.=$tmp{"$it","seq"}."\n";} }
    else { $it=1;
	   $id= $tmp{"$it","id"};
	   $tmp{"$it","seq"}=~s/\s//g;$tmp{"$it","seq"}=~s/\*$//g;
	   $seq=$tmp{"$it","seq"}; }
	
    $#tmp=0;undef %tmp;		# save memory
    return(0,"*** ERROR $sbrName: file=$fileInLoc, nali=$ct, wanted: (rd=$rd)\n"," ") 
        if (length($seq)<1);
    return(1,$id,$seq);
}				# end of pirRdMul

#===============================================================================
sub pirWrtMul {
    local($fileOutLoc,%tmp) = @_ ;
    local($sbrName,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   pirWrtMul                   writes a list of sequences in PIR format
#       in:                     $fileOut,$tmp{} with:
#       in:                     $tmp{"NROWS"}      number of sequences
#       in:                     $tmp{"id","$ct"}   id for sequence $ct
#       in:                     $tmp{"seq","$ct"}  seq for sequence $ct
#       out:                    file
#       err:                    err  -> 0,message
#       err:                    ok   -> 1,ok
#       err:                    warn -> 2,not enough written
#-------------------------------------------------------------------------------
    $sbrName="lib-br:pirWrtMul";$fhoutLoc="FHOUT_"."$sbrName";

    return(0,"*** ERROR $sbrName: no tmp{NROWS} defined\n") if (! defined $tmp{"NROWS"});
    &open_file("$fhoutLoc",">$fileOutLoc") ||
        return(0,"*** ERROR $sbrName: '$fileOutLoc' not opened for write\n");

    $ctOk=0;
    foreach $itPair (1..$tmp{"NROWS"}){
        next if (! defined $tmp{"id","$itPair"} || ! defined $tmp{"seq","$itPair"});
        ++$ctOk;
                                # some massage
        $tmp{"id","$itPair"}=~s/[\s\t\n]+/ /g;
        $tmp{"seq","$itPair"}=~s/[\s\t\n]+//g;
                                # write
        print $fhoutLoc ">P1\; ",$tmp{"id","$itPair"},"\n";
        print $fhoutLoc $tmp{"id","$itPair"},"\n";
        $tmp{"seq","$itPair"}.="*";
	$lenHere=length($tmp{"seq","$itPair"});
        for($it=1; $it<=$lenHere; $it+=50){
	    $tmpWrt=      "";
            foreach $it2 (0..4){
		$itHere=($it + 10*$it2);
                last if ( $itHere >= $lenHere);
		$nchunk=10; 
		$nchunk=1+($lenHere-$itHere)  if ( (10 + $itHere) > $lenHere);
		$tmpWrt.= sprintf(" %-10s",substr($tmp{"seq","$itPair"},$itHere,$nchunk)); 
	    }
	    print $fhoutLoc $tmpWrt,"\n";
	}
    }
    close($fhoutLoc);
    return(0,"*** ERROR $sbrName: no sequence written\n")               
	if (! $ctOk);
    return(2,"-*- WARN $sbrName: wrote fewere sequences than expected\n") 
	if ($ctOk!=$tmp{"NROWS"});
    return(1,"ok $sbrName");
}				# end of pirWrtMul

#===============================================================================
sub ppHsspRdExtrHeader {
    local ($file_in) = @_ ;
    local ($fhinLoc,$sbrName,$msg,$ct,$tmp,$tmp2,@tmp,$it);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   ppHsspRdExtrHeader          extracts the summary from HSSP header (for PP)
#       out (GLOBAL):           $rd_hssp{} (for ppTopitsHdWrt!!!)
#--------------------------------------------------------------------------------
    $sbrName="ppHsspRdExtrHeader";$fhinLoc="FHIN"."$sbrName";

    $Lok=       &open_file("$fhinLoc","$file_in");
    if (! $Lok){$msg="*** ERROR $sbrName: '$file_in' not opened\n";
		return(0,$msg,"error");}

    while(<$fhinLoc>){
	last if ($_=/^\#\# PROTEINS/);}
    $ct=0;
    while(<$fhinLoc>){
	last if ($_=/^\#\# ALI/);
	next if ($_=~/^  NR/);
	next if (length($_)<27); # xx hack should not happen!!
	$tmp=substr($_,27);
	$tmp=~s/^\s*|\s$//g;	# purge leading blanks
	$#tmp=0;@tmp=split(/\s+/,$tmp);
	++$ct;
	$rd_hssp{"ide","$ct"}=$tmp[1];
	$rd_hssp{"ifir","$ct"}=$tmp[3];$rd_hssp{"jfir","$ct"}=$tmp[5];
	$rd_hssp{"ilas","$ct"}=$tmp[4];$rd_hssp{"jlas","$ct"}=$tmp[6];
	$rd_hssp{"lali","$ct"}=$tmp[7];
	$rd_hssp{"ngap","$ct"}=$tmp[8];$rd_hssp{"lgap","$ct"}=$tmp[9];
	$rd_hssp{"len2","$ct"}=$tmp[10];

	$tmp= substr($_,7,20);
	$tmp2=substr($_,20,6);
	$tmp3=$tmp2; $tmp3=~s/\s//g;
	if (length($tmp3)<3) {	# STRID empty
	    $tmp=substr($_,8,6);
	    $tmp=~s/\s//g;
	    $rd_hssp{"id2","$ct"}=$tmp;}
	else{$tmp2=~s/\s//g;
	     $rd_hssp{"id2","$ct"}=$tmp2;}}close($fhinLoc);
    $rd_hssp{"nali"}=$ct;
    return(1,"ok $sbrName",%rd_hssp);
}				# end of ppHsspRdExtrHeader

#===============================================================================
sub ppStripRd {
    local ($file_in) = @_ ;
    local ($fhinLoc,$sbrName,$msg,@strip);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    ppStripRd                   reads the new strip file generated for PP
#--------------------------------------------------------------------------------
    $sbrName="ppStripRd";$fhinLoc="FHIN"."$sbrName";

    $Lok=       &open_file("$fhinLoc","$file_in");
    if (! $Lok){$msg="*** ERROR $sbrName: '$file_in' not opened\n";
		return(0,$msg,"error");}

    $#strip=0;
    while(<$fhinLoc>){
	push(@strip,$_);}close($fhinLoc);
    return(1,"ok $sbrName",@strip);
}				# end of ppStripRd

#===============================================================================
sub ppTopitsHdWrt {
    local ($file_in,$mixLoc,@strip) = @_ ;
    local ($sbrName,$msg,$fhout,$Lwatch,$Lrest,$strip,$it);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    ppTopitsHdWrt              writes the final PP TOPITS output file
#       in:                     $file_in,$mixLoc,@strip
#       in:                     output file, ratio str/seq (100=only struc), 
#       in:                        content of strip file
#       out:                    file written ($file_in)
#       err:                    (0,$err) (1,'ok')
#--------------------------------------------------------------------------------
    $sbrName="ppStripRd";$fhout="FHOUT"."$sbrName";

    $Lok=       &open_file("$fhout",">$file_in");
    if (! $Lok){$msg="*** ERROR $sbrName: '$file_in' not opened (output file)\n";
		return(0,$msg);}

    $Lwatch=$Lrest=0;
    foreach $strip (@strip) {
	$strip=~s/\n//g;
	if ( $Lrest ) {
	    print $fhout "$strip\n"; }
	elsif ( $Lwatch && ($strip=~/^---/) ){
	    print $fhout "--- \n";
	    print $fhout "--- TOPITS ALIGNMENTS HEADER: PDB_POSITIONS FOR ALIGNED PAIR\n";
	    printf 
		$fhout "%5s %4s %4s %4s %4s %4s %4s %4s %-6s\n",
		"RANK","PIDE","IFIR","ILAS","JFIR","JLAS","LALI","LEN2","ID2";
	    foreach $it (1 .. $rd_hssp{"nali"}){
		printf 
		    $fhout "%5d %4d %4d %4d %4d %4d %4d %4d %-6s\n",
		    $it,int(100*$rd_hssp{"ide","$it"}),
		    $rd_hssp{"ifir","$it"},$rd_hssp{"ilas","$it"},
		    $rd_hssp{"jfir","$it"},$rd_hssp{"jlas","$it"},
		    $rd_hssp{"lali","$it"},$rd_hssp{"len2","$it"},
		    $rd_hssp{"id2","$it"};
	    }
	    $Lrest=1; 
	    print $fhout "$strip\n"; }
	elsif ($strip =~ /^--- .* SUMMARY/){ 
	    $Lwatch=1; 
	    print $fhout "$strip\n"; }
	elsif ($strip =~ /^--- NAME2/) { # abbreviations
	    print $fhout "$strip\n";
	    print $fhout "--- IFIR         : position of first residue of search sequence\n";
	    print $fhout "--- ILAS         : position of last residue of search sequence\n";
	    print $fhout "--- JFIR         : PDB position of first residue of remote homologue\n";
	    print $fhout "--- JLAS         : PDB position of last residue of remote homologue\n";}
	elsif ($strip =~ /^--- .* PARAMETER/) { # parameter
	    print $fhout "$strip\n";
				# hack br 98-05 do clean some day!
	    if (! defined $mixLoc){ print "-*- WARN $sbrName mixLoc not defined \n";
				    $mixLoc=50;}
	    $mixLoc=~s/\D//g; $mixLoc=50 if (length($mixLoc)<1); # hack br 98-05 
	    printf $fhout 
		"--- str:seq= %3d : structure (sec str, acc)=%3d\%, sequence=%3d\%\n",
		int($mixLoc),int($mixLoc),int(100-$mixLoc);
	} else {print $fhout "$strip\n"; }
    }
    close($fhout);
    return(1,"ok $sbrName");
}				# end of ppTopitsHdWrt

#===============================================================================
sub printm { 
    local ($txt,@fh) = @_ ;local ($fh);$[ =1 ;
#--------------------------------------------------------------------------------
#   printm                      print on multiple filehandles (in:$txt,@fh; out:print)
#       in:                     $txt,@fh,
#       out:                    print on all @fh
#--------------------------------------------------------------------------------
    foreach $fh (@fh) { 
	print $fh $txt if (! eof($fh) || $fh eq "STDOUT" ); }
}				# end of printm

#===============================================================================
sub prodomRun {
    local($fileInLoc,$fileOutTmpLoc,$fileOutLoc,$fhErrSbr,$niceLoc,
	  $exeBlast,$envBlastDb,$envBlastMat,$parBlastDb,$parBlastN,$parBlastE,$parBlastP)=@_;
    local($sbrName,$fhinLoc,$tmp,$Lok,$dbTmp,$cmd,$msg,%head,@idRd,@idTake);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   prodomRun                   runs a BLASTP against the ProDom db
#       in:                     many
#       out:                    (1,'ok',$nhits_below_threshold)
#       err:                    (0,'msg')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:prodomRun";$fhinLoc="FHIN"."$sbrName";
				# ------------------------------
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc!")          if (! defined $fileInLoc);
    return(0,"*** $sbrName: not def fileOutTmpLoc!")      if (! defined $fileOutTmpLoc);
    return(0,"*** $sbrName: not def fileOutLoc!")         if (! defined $fileOutLoc);
    $fhErrSbr=   "STDOUT"                                 if (! defined $fhErrSbr);
    $niceLoc=    " "                                      if (! defined $niceLoc);
    $exeBlast=   "/usr/pub/bin/molbio/blastp"             if (! defined $exeBlast);
    $envBlastDb= "/home/rost/pub/ncbi/db/"                if (! defined $envBlastDb);
    $envBlastMat="/home/pub/molbio/blast/blastapp/matrix" if (! defined $envBlastMat);
    $parBlastDb= "/home/rost/pub/ncbi/db/prodom"          if (! defined $parBlastDb);
    $parBlastN=  "500"                                    if (! defined $parBlastN);
    $parBlastE=    "0.1"                                  if (! defined $parBlastE);
    $parBlastP=    "0.1"                                  if (! defined $parBlastP);
    
    return(0,"*** $sbrName: no in file '$fileInLoc'!")    if (! -e $fileInLoc);
				# ------------------------------
				# set env
    $ENV{'BLASTMAT'}=$envBlastMat;
    $ENV{'BLASTDB'}= $envBlastDb;
				# ------------------------------
				# run BLAST
    $dbTmp=$parBlastDb;$dbTmp=~s/\/$//g;
    $cmd=  "$niceLoc $exeBlast $dbTmp $fileInLoc E=$parBlastE B=$parBlastN >> $fileOutTmpLoc ";
    $cmd=  "$exeBlast $dbTmp $fileInLoc E=$parBlastE B=$parBlastN >> $fileOutTmpLoc ";
    system("$cmd");
				# ------------------------------
				# read BLAST header
    ($Lok,$msg,%head)=
	&blastpRdHdr($fileOutTmpLoc,$fhErrSbr);

    return(0,"*** ERROR $sbrName: after blastpRdHdr msg=$msg") if (! $Lok);
    return(0,"*** ERROR $sbrName: after blastpRdHdr no id head{id} defined") 
	if (! defined $head{"id"} || length($head{"id"})<2);
				# ------------------------------
				# select id below threshold
    @idRd=split(/,/,$head{"id"});$#idTake=0;
    foreach $id (@idRd){
	push(@idTake,$id) if (defined $head{"$id","prob"} && 
			      $head{"$id","prob"} <= $parBlastP);}
    undef %head; $#idRd=0;	# save space
    return(0,"--- $sbrName: no hit below threshold P=".$parBlastP."\n",0)
	if ($#idTake==0);
				# ------------------------------
				# write PRODOM output
    $ctOk=$#idTake;
    ($Lok,$msg)=
	&prodomWrt($fileOutTmpLoc,$fileOutLoc,@idTake);
    return(0,"*** ERROR $sbrName: after prodomWrt msg=$msg") if (! $Lok);
    return(1,"ok $sbrName",$ctOk);
}				# end of prodomRun

#===============================================================================
sub prodomWrt {
    local($fileInLoc,$fileOutLoc,@idTake) = @_ ;
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   prodomWrt                   write the PRODOM data + BLAST ali
#       in:                     $fileBlast,$fileHANDLE_OUTPUTFILE,@id_to_read
#       in:                     NOTE: if $#id==0, none written!
#       out:                    (1,'ok') + written into FILE_HANDLE
#       err:                    (0,'msg')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."prodomWrt";$fhinLoc="FHIN"."$sbrName";$fhoutLoc="FHOUT"."$sbrName";
				# ------------------------------
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc!")        if (! defined $fileInLoc);
    return(0,"*** $sbrName: not def fileOutLoc!")       if (! defined $fileOutLoc);
    return(0,"*** $sbrName: no in file '$fileInLoc'!")  if (! -e $fileInLoc);
				# ------------------------------
				# open file and write header
    $Lok=       &open_file("$fhoutLoc",">$fileOutLoc");
    return(0,"*** ERROR $sbrName: new=$fileOutLoc not opened\n") if (! $Lok);
    print $fhoutLoc 
	"--- ------------------------------------------------------------\n",
	"--- Results from running BLAST against PRODOM domains\n",
	"--- \n",
	"--- PLEASE quote: \n",
	"---       F Corpet, J Gouzy, D Kahn (1998).  The ProDom database\n",
	"---       of protein domain families. Nucleic Ac Res 26:323-326.\n",
	"--- \n",
	"--- BEGIN of BLASTP output\n";
				# ------------------------------
				# extract those below threshold
    ($Lok,$msg)=
	&blastpExtrId($fileOutTmpLoc,$fhoutLoc,@idTake);

    return(0,"*** ERROR $sbrName: after blastpExtrId msg=$msg") if (! $Lok);
				# ------------------------------
				# links to ProDom
    print $fhoutLoc 
	"--- END of BLASTP output\n",
	"--- ------------------------------------------------------------\n",
	"--- \n",
	"--- Again: these results were obtained based on the domain data-\n",
	"--- base collected by Daniel Kahn and his coworkers in Toulouse.\n",
	"--- \n",
	"--- PLEASE quote: \n",
	"---       F Corpet, J Gouzy, D Kahn (1998).  The ProDom database\n",
	"---       of protein domain families. Nucleic Ac Res 26:323-326.\n",
	"--- \n",
	"--- The general WWW page is on:\n",
	"----      ---------------------------------------\n",
	"---       http://www.toulouse.inra.fr/prodom.html\n",
	"----      ---------------------------------------\n",
	"--- \n",
	"--- For WWW graphic interfaces to PRODOM, in particular for your\n",
	"--- protein family, follow the following links (each line is ONE\n",
	"--- single link for your protein!!):\n",
	"--- \n";
				# ------------------------------
				# define keywords
    $txt1a="http://www.toulouse.inra.fr/prodom/cgi-bin/ReqProdomII.pl?id_dom1=";
    $txt1b=" ==> multiple alignment, consensus, PDB and PROSITE links of domain ";
    $txt2a="http://www.toulouse.inra.fr/prodom/cgi-bin/ReqProdomII.pl?id_dom2=";
    $txt2b=" ==> graphical output of all proteins having domain ";
				# ------------------------------
				# establish links
    foreach $id (@idTake){$id=~s/\s//g;
			  next if ($id =~/\D/ || length($id)<1);
			  print $fhoutLoc "$txt1a".$id."$txt1b".$id."\n";
			  print $fhoutLoc "$txt2a".$id."$txt2b".$id."\n";}
    print $fhoutLoc
	"--- \n",
	"--- NOTE: if you want to use the link, make sure the entire line\n",
	"---       is pasted as URL into your browser!\n",
	"--- \n",
	"--- END of PRODOM\n",
	"--- ------------------------------------------------------------\n";
    close($fhoutLoc);
    return(1,"ok $sbrName");
}				# end of prodomWrt

#===============================================================================
sub profile_count {
    local ($s1,$s2)=@_;
    local ($aa1,$aa2,$string_aa,@aa);
    $[=1;
#--------------------------------------------------------------------------------
#   profile_count               computes the profile for two sequences
#--------------------------------------------------------------------------------
				# initialise profile counts
    $string_aa=&metric_ini;
    @aa=split(//,$string_aa);
    foreach $aa1(@aa){ foreach $aa2(@aa){
	$profile{"$aa1","$aa2"}=0;
    }}
				# get minimum length
    if (length($s1)>length($s2)){$len=length($s2);}else{$len=length($s1);}
    foreach $it (1..$len){
	$aa1=substr($s1,$it,1);
	$aa2=substr($s2,$it,1);
	++$profile{"$aa1","$aa2"};
    }
    return(%profile);
}				# end of profile_count

#===============================================================================
sub ranPickFast {
    local($numPicksLoc,$numSamLoc,$maxNumPerSamLoc,$minNumPerSamLoc)=@_;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   ranPickFast                 selects succesion of numbers 1..$numSamLoc at 
#                               random (faster than ranPickGood)
#       in:                     $numPicks        = number of total picks
#       in:                     $numSamLoc       = number of samples to pick from (pool)
#       in:                     $maxNumPerSamLoc = maximal number of picks per pattern
#       in:                     $minNumPerSamLoc = minimal number of picks per pattern
#       out:                    1|0,msg,@ransuccession
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."ranPickFast";$fhinLoc="FHIN_"."ranPickFast";
				# ------------------------------
				# random numbers
    srand(time|$$);             # seed random
#    srand(100010);             # seed random
				# ------------------------------
    foreach $it (1..$numSamLoc){ # initialise sample counts
	$ct[$it]=0;}
    
    $ct=0;$fin="";		# --------------------------------------------------
    while ($ct < $numPicksLoc){	# loop over counts
#        $it=int(rand($numSamLoc-1))+1;                # randomly select sample 
        $it=int(rand($numSamLoc))+1;                # randomly select sample 
	$it=$numSamLoc          if ($it> $numSamLoc); # upper bound (security)
	$it=1                   if ($it<=1);          # upper/lower bounds (security)
				# ------------------------------
	$Lfound=0;		# (1) not often -> take it
        if    ($ct[$it] < $maxNumPerSamLoc){ 
	    ++$ct;++$ct[$it];$fin.="$it,";$Lfound=1;}
				# ------------------------------
				# (2) too often -> count up
	while ($it < $numSamLoc && ! $Lfound) {
	    ++$it;
	    if ($ct[$it] < $maxNumPerSamLoc){ 
		++$ct;++$ct[$it];$fin.="$it,";$Lfound=1;}}
				# ------------------------------
	$it=0;			# (3) too often -> restart count up
	while ($it < $numSamLoc && ! $Lfound) {
	    ++$it;
	    if ($ct[$it] < $maxNumPerSamLoc){ 
		++$ct;++$ct[$it];$fin.="$it,";$Lfound=1;}}
	if (! $Lfound && $ct < $numPicksLoc){
            $#tmp=0;foreach $it (1..$numSamLoc){
		$tmp=sprintf ("itSam=%4d occ=%4d\n",$it,$ct[$it]);push(@tmp,$tmp);}
            return(&errSbr("none found, but ct too small=$ct (numSam=$numSamLoc)\n".
                           $fin."\n"."statistics\n".join("\n",@tmp)."\n"),0);}}
                                # --------------------------------------------------
    if ($minNumPerSamLoc){	# correct those that did not reach minimal number
        $max=0;$minSam="";
				# --------------------
				# find those with low counts
        foreach $it (1..$numSamLoc){
	    if    ($ct[$it] < $minNumPerSamLoc) {
		$minSam.="$it," x ($minNumPerSamLoc-$ct[$it]); }
	    elsif ($ct[$it] > $max) {
		$max=$ct[$it];} }
	$minSam=~s/,$//g; @min=split(/,/,$minSam); $#max=0;
				# --------------------
	if ($#min > 1){		# do indeed correct

	    while ($#max < $#min){ # 'end'less loop over all samples
		++$it;
		if ($it > $numSamLoc){ # start again (reduce max)
		    $it=1; --$max;
				# end: max = min!
		    if ($max < $minNumPerSamLoc){
			$#tmp=0;
			foreach $it (1..$numSamLoc){
			    $tmp=sprintf ("itSam=%4d occ=%4d\n",$it,$ct[$it]);
			    push(@tmp,$tmp);}
			return(&errSbr("max=$max, too small already...\n".
				       "so far maxSam=".join(',',@max).
				       " min=".join(',',@min)."\nstatistics\n".
				       join("\n",@tmp)."\n"),0);}}
				# candidate for max
		if ($ct[$it] == $max){ 
		    push(@max,$it);
		    --$ct[$it];}}
				# --------------------
				# now correct
	    $fin=",".$fin.",";
	    foreach $itTmp (1..$#min){ 
		++$ct[$min[$itTmp]];
		$fin=~s/\,$max[$itTmp]\,/\,$min[$itTmp]\,/; }
	    $sum=$#tmp=0;
	    foreach $it (1..$numSamLoc){
		$sum+=$ct[$it];
		$tmp=sprintf ("itSam=%4d occ=%4d\n",$it,$ct[$it]);
		push(@tmp,$tmp);}
				# you may print @tmp here
	    return(&errSbr("sum after correction=$sum, but numpick=$numPicksLoc"))
		if ($sum != $numPicksLoc);
	}}
    $fin=~s/^,*|,*$//g;$fin=~s/,,*/,/g;
    return(1,"ok $sbrName",$fin);
}				# end of ranPickFast

#===============================================================================
sub ranPickGood {
    local($numPicksLoc,$numSamLoc,$maxNumPerSamLoc,$minNumPerSamLoc)=@_;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   ranPickGood                 selects succesion of numbers 1..$numSamLoc at 
#                               random  (slower but more Gaussian than ranPickFast)
#       in:                     $numPicks        = number of total picks
#       in:                     $numSamLoc       = number of samples to pick from (pool)
#       in:                     $maxNumPerSamLoc = maximal number of picks per pattern
#       in:                     $minNumPerSamLoc = minimal number of picks per pattern
#       out:                    1|0,msg,@ransuccession
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."ranPickGood";$fhinLoc="FHIN_"."ranPickGood";
				# ------------------------------
				# random numbers
    srand(time|$$);             # seed random
				# ------------------------------
    foreach $it (1..$numSamLoc){ # initialise sample counts
	$ct[$it]=0;}
    
    $ct=0;$fin="";		# --------------------------------------------------
    while ($ct < $numPicksLoc){	# loop over counts
        $it=int(rand($numSamLoc))+1;                  # randomly select sample 
	$it=$numSamLoc          if ($it> $numSamLoc); # upper bound (security)
	$it=1                   if ($it<=1);          # upper/lower bounds (security)
				# ------------------------------
	$Lfound=0;		# (1) not often -> take it
        if    ($ct[$it] < $maxNumPerSamLoc){ 
	    ++$ct;++$ct[$it];$fin.="$it,";$Lfound=1;}
    }
                                # --------------------------------------------------
    if ($minNumPerSamLoc){	# correct those that didnt reach minimal number
        $max=0;$minSam="";
        foreach $it (1..$numSamLoc){$minSam.="$it,"     if ($ct[$it] < $minNumPerSamLoc);
				    $max=$ct[$it]       if ($ct[$it] > $max);}
	if (length($minSam)>1){	# to correct
	    $maxSam="";$it=0;
	    while (length($maxSam) < length($minSam)){
		++$it;
		if ($it > $numSamLoc){
		    $it=1; --$max;
		    if ($max<$minNumPerSamLoc){
			$#tmp=0;foreach $it (1..$numSamLoc){
			    $tmp=sprintf ("itSam=%4d occ=%4d\n",$it,$ct[$it]);push(@tmp,$tmp);}
			return(&errSbr("max=$max, too small already...\n".
				       "so far maxSam=$maxSam, minSam=$minSam\n"."statistics\n".
				       join("\n",@tmp)."\n"),0);}}
		if ($ct[$it] == $max){ $maxSam.="$it,";
				       --$ct[$it];}}
				# now correct
	    $maxSam=~s/,$//g;$minSam=~s/,$//g;
	    @min=split(/,/,$minSam);@max=split(/,/,$maxSam);
	    $fin=",".$fin.",";
	    foreach $itTmp (1..$#min){ ++$ct[$min[$itTmp]];
				       $fin=~s/\,$max[$itTmp]\,/\,$min[$itTmp]\,/;}}}
    $fin=~s/^,*|,*$//g;$fin=~s/,,*/,/g;
    return(1,"ok $sbrName",$fin);
}				# end of ranPickGood

#===============================================================================
sub rd_col_associative {
    local ($file_in,@des_in) = @_ ;
    local ($sbr_name,$fhin,$it,@tmp,$tmp,$des_in,%ptr,%rdcol);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    rd_col_associative         reads the content of a comma separated file
#       in:                     Names used for columns in perl file, e.g.,
#--------------------------------------------------------------------------------
				# avoid warning
    $READHEADER="";
				# set some defaults
    $fhin="FHIN_COL";
    $sbr_name="rd_col_associative";
    undef %rdcol; undef %ptr;
				# --------------------------------------------------
				# read RDB file
				# --------------------------------------------------
    &open_file("$fhin","$file_in");
    $ct=0;
    while(<$fhin>){
	$_=~s/\n//g;
	next if (/^\#/);	# ignore RDB header
	++$ct;			# delete leading blanks, commatas and tabs
	$_=~s/^\s*|\s*$|^,|,$|^\t|\t$//g;
	$#tmp=0;@tmp=split(/[,\t ]+/,$_);
	if ($ct==1){
	    $Lok=0;
	    foreach $des (@des_in) {
		foreach $it (1..$#tmp) {
		    if ($des =~ /$tmp[$it]/){
			$ptr{$des}=$it;
			$Lok=1;
			last;}}}
	    if (!$Lok){print"*** ERROR in reading col format ($sbr_name), none found\n";
		       exit;}}
	else {
	    foreach $des (@des_in){
		if (defined $ptr{$des}){
		    $tmp=$ct-1;
		    $rdcol{"$des","$tmp"}=$tmp[$ptr{$des}];}}}
    }close($fhin);
    $rdcol{"NROWS"}=$ct-1;
    return (%rdcol);
}				# end of rd_col_associative

#===============================================================================
sub rd_rdb_associative {
    local ($file_in,@des_in) = @_ ;
    local ($sbr_name,$fhin,$Lhead,$Lbody,$Lfound,$it,$itrd,@tmp,$tmp,$des_in,$rd,
	   @des_head,@des_headin,@des_bodyin,@des_body,%ptr_rd2des,$nrow_rd,%rdrdb,
	   $Lscreen);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   rd_rdb_associative          reads the content of an RDB file into an associative
#                               array
#       in:                     Names used for columns in perl file, e.g.,
#                               "header,NALIGN,body,POS,NPROT" as arguments passed
#                               would result in:
#                               reading anything in file header using the keyword 'NALIGN'
#                               reading the columns named POS and NPROT
#                       ALL:    'head,body'
#       out:                    rdrdb{"NALIGN"},rdrdb{"POS","ct"},rdrdb{"NPROT","ct"},
#                               where ct counts the rows read,
#                               rdrdb{"NROWS"} returns the numbers of rows read
#                       HEADER: rdrdb{"header"}
#                       NAMES:  rdrdb{"names"} 
#--------------------------------------------------------------------------------
				# avoid warning
    $READHEADER="";
    $Lscreen=1;
				# set some defaults
    $fhin="FHIN_RDB";
    $sbr_name="rd_rdb_associative";
				# get input
    $Lhead=$Lbody=$Lhead_all=$Lbody_all=$#des_headin=$#des_bodyin=0;
    foreach $des_in(@des_in){
	if   ($des_in=~/^not_screen/)        {$Lscreen=0;}
	elsif((!$Lhead) && ($des_in=~/head/)){$Lhead=1;$Lhead_all=1;}
	elsif((!$Lbody) && ($des_in=~/body/)){$Lbody=1;$Lhead=0; $Lbody_all=1;}
	elsif($Lhead)                        {push(@des_headin,$des_in); $Lhead_all=0;}
	elsif($Lbody)                        {$des_in=~s/\n|\s//g;; $Lbody_all=0;
					      push(@des_bodyin,$des_in);}
	else {print "*** WARNING $sbr_name: input '$des_in' not recognised.\n";} }
    if ($Lscreen) { print "--- $sbr_name: header \t ";
		    foreach $it (@des_headin){print"$it,";}print"\n"; 
		    print "--- $sbr_name: body   \t ";
		    foreach $it (@des_bodyin){print"$it,";}print"\n"; }
				# --------------------------------------------------
				# read RDB file
				# --------------------------------------------------
    &open_file("$fhin","$file_in");
				# out: $READHEADER :whole header, one string
				#      @READCOL    : all columns
				#      @READNAME   :names of columns
    &read_rdb_num2($fhin,0);
    close($fhin);
				# ------------------------------
				# process header
    $#des_head=0;
    @tmp=split(/\#\s?/,$READHEADER);
    if ($#des_headin>=1){
	foreach $des_in (@des_headin) {
	    $Lfound=0;
	    foreach $rd (@tmp){
		if ($rd =~ /^$des_in[ :,\;]/){
		    $tmp=$rd;$tmp=~s/\n|\s$//g;
		    $tmp=~s/$des_in//g;$tmp=~s/^\s*//g;
		    if (defined $rdrdb{"$des_in"}){
			$rdrdb{"$des_in"}.="\t".$tmp;}
		    else {
			$rdrdb{"$des_in"}=$tmp;}
		    push(@des_head,$des_in);
		    $Lfound=1;} }
	    if(!$Lfound && $Lscreen){
		print"--- $sbr_name: \t expected to find in header key word:\n";
		print"---            \t '$des_in', but not in file '$file_in'\n";}
	}}
    elsif ($Lhead_all) {		# whole header into $rdrdb{"header"}
	$rdrdb{"header"}="";
	foreach $rd (@tmp) { 
	    $rd=~s/^\s?|\n//g;
	    $rdrdb{"header"}.="# ".$rd."\n"; }}
				# ------------------------------
				# get column numbers to be read
    $#des_body=0;
    if (! $Lbody_all){
	foreach $des_in (@des_bodyin) {
	    $Lfound=0;
	    for($it=1;$it<=$#READNAME;++$it) {
		$rd=$READNAME[$it];
		if ($rd eq $des_in) {$ptr_rd2des{"$des_in"}=$it;push(@des_body,$des_in);
				     $Lfound=1;last;} }
	    if((!$Lfound) && $Lscreen){
		print"--- $sbr_name: \t expected to find column name:\n";
		print"---            \t '$des_in', but not in file '$file_in'\n";}}}
    else {
	foreach $it(1..$#READNAME){
	    $name=$READNAME[$it];$ptr_rd2des{"$name"}=$it;
	    push(@des_body,$name);}}
				# ------------------------------
				# get format
    foreach $des_in(@des_bodyin) {
	$it=$ptr_rd2des{"$des_in"};
	if ( (defined $it) && (defined $READFORMAT[$it]) ) {
	    $rdrdb{"$des_in","format"}=$READFORMAT[$it];}
	else {
	    $rdrdb{"$des_in","format"}="8";}}

    $nrow_rd=0;$names="";
    foreach $des_in(@des_body) {
	$itrd=$ptr_rd2des{"$des_in"};
	@tmp=split(/\t/,$READCOL[$itrd]);
	if ($nrow_rd==0){
	    $nrow_rd=$#tmp;}
	elsif($nrow_rd!=$#tmp){
	    print "*** WARNING $sbr_name: different number of rows\n";
	    print "*** WARNING in RDB file '$file_in' for rows with ".
		  "key= $des_in and previous column no=$itrd,\n";}
	$names.="$des_in".",";
	for($it=1;$it<=$#tmp;++$it){
	    $rdrdb{"$des_in","$it"}=$tmp[$it];}
    }
    $rdrdb{"NROWS"}=$nrow_rd;
    $names=~s/,$//g;$rdrdb{"names"}=$names;
    return (%rdrdb);
}				# end of rd_rdb_associative

#===============================================================================
sub rdb2html {
    local ($fileRdb,$fileHtml,$fhout,$Llink,$scriptName) = @_ ;
    local (@headerRd,$tmp,@tmp,@colNames,$colNames,%body,$des,$ct,$fhin);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   rdb2html                    convert an RDB file to HTML
#       in:		        $fileRdb,$fileHtml,$fhout,$Llink 
#                               (Llink=1 -> links from column names to Notation in header)
#       ext                     open_file, 
#       ext                     wrtRdb2HtmlHeader,wrtRdb2HtmlBody
#       ext GLOBULAR:           wrtRdb2HtmlBodyColNames,wrtRdb2HtmlBodyAve
#--------------------------------------------------------------------------------
    $fhin="FHinRdb2html";
    &open_file("$fhin", "$fileRdb");

    $#headerRd=0;
				# ------------------------------
    while (<$fhin>) {		# read header of RDB file
	$tmp=$_;
	$_=~s/\n//g;
	last if (! /^\#/);
	push(@headerRd,$_);}
				# ------------------------------
				# get column names
    $tmp=~s/\n//g;$tmp=~s/^\t*|\t*$//g;
    @colNames=split(/\t/,$tmp);

    $body{"COLNAMES"}="";
    foreach $des (@colNames){	# store column names
	$body{"COLNAMES"}.="$des".",";}
	
				# ------------------------------
    while (<$fhin>) {		# skip formats
	$tmp=$_;
	last;}
				# ------------------------------
				# read body
    $ct=0;$Lave=0;
    while (<$fhin>) {
	$_=~s/\n//g;
	$_=~s/^\t*|\t*$//g;
	if (length($_)<1){
	    next;}
	@tmp=split(/\t/,$_);
	++$ct;
	foreach $it (1..$#tmp){	# store body
	    $key=$colNames[$it];
	    $body{"$ct","$key"}=$tmp[$it];}
	if ($tmp[1] =~ "^ave"){$Lave=1;}
    }
    
    $body{"NROWS"}=$ct;
				# end of reading RDB file
				# ------------------------------

				# ------------------------------
				# write output file
    if ($fhout ne "STDOUT"){
	&open_file("$fhout", ">$fileHtml");}

    @tmp=			# write header
	&wrtRdb2HtmlHeader($fhout,$scriptName,$fileRdb,$Llink,$Lave,$body{"COLNAMES"},@headerRd);
				# mark keys to be linked
    foreach $col (@colNames){
	$body{"link","$col"}=0;}
    foreach $col (@tmp){
	$body{"link","$col"}=1;}
				# write body
    &wrtRdb2HtmlBody($fhout,$Llink,%body);

				# add icons
    print $fhout 
	"<P><P><HR><P><P>\n",
	"<A HREF=\"http:\/\/www.embl-heidelberg.de\/\">",
              "<IMG ALIGN=MIDDLE SRC=",
	      "\"http:\/\/www.embl-heidelberg.de\/icons\/embl_home.gif\" ",
	      "ALT=\"EMBL Home\"><\/A>\n",
	"<A HREF=\"http:\/\/www.sander.embl-heidelberg.de\/descr\/\">",
              "<IMG ALIGN=MIDDLE SRC=",
	      "\"http:\/\/www.sander.embl-heidelberg.de\/sander-icon.gif\" ",
	      "ALT=\"Sander Group\"><\/A>\n",
	"<A HREF=\"http:\/\/www.embl-heidelberg.de\/~rost\/\">",
              "<IMG ALIGN=MIDDLE SRC=",
	      "\"http:\/\/www.embl-heidelberg.de\/~rost\/Dfig\/icon-br-home.gif\" ",
	       "ALT=\"Rost Home\"><\/A>\n",
	"<A HREF=\"mailto\:rost\@embl-heidelberg.de\">",
              "<IMG ALIGN=MIDDLE SRC=",
	      "\"http:\/\/www.embl-heidelberg.de\/~rost\/Dfig\/icon-br-home-mail.gif\" ",
	       "ALT=\"Mail to Rost\"><\/A>\n",
	"<A HREF=\"http:\/\/www.embl-heidelberg.de\/predictprotein\/\">",
              "<IMG ALIGN=MIDDLE SRC=",
	      "\"http:\/\/www.embl-heidelberg.de\/~rost\/Dfig\/icon-pp.gif\" ",
	      "ALT=\"PredictProtein\"><\/A>\n",
	"<\/BODY>\n","<\/HTML>\n";
    print $fhout "\n";
    close($fhin);close($fhout);
}				# end of rdb2html

#===============================================================================
sub rdbGenWrtHdr {
    local($fhoutLoc2,%tmpLoc)= @_ ;
    local($sbrName,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   rdbGenWrtHdr                writes a general header for an RDB file
#       in:                     $file_handle_for_out
#       in:                     $tmp2{}
#                               $tmp2{"name"}    : name of program/format/.. eg. 'NNdb'
#                notation:     
#                               $tmp2{"nota","expect"}='name1,name2,...,nameN'
#                                                : column names listed
#                               $tmp2{"nota","nameN"}=
#                                                : description for nameN
#                               
#                               additional notations:
#                               $tmp2{"nota",$ct}='kwd'.'\t'.'explanation'  
#                                                : the column name kwd (e.g. 'num'), and 
#                                                  its description, 
#                                                  e.g. 'is the number of proteins'
#                parameters:           
#                               $tmp2{"para","expect"}='para1,para2' 
#                               $tmp2{"para","paraN"}=
#                                                : value for parameter paraN
#                               $tmp2{"form","paraN"}=
#                                                : output format for paraN (default '%-s')
#       out:                    implicit: written onto handle
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."rdbGenWrtHdr";
                                # defaults, read
    $name="";        $name=$tmpLoc{"name"}." "   if (defined $tmpLoc{"name"});
    $#colNamesTmp=0; @colNamesTmp=split(/,/,$tmpLoc{"nota","expect"})
                                                 if (defined $tmpLoc{"nota","expect"});
    $#paraTmp=0;     @paraTmp=    split(/,/,$tmpLoc{"para","expect"})
                                                 if (defined $tmpLoc{"para","expect"});

    print $fhoutLoc2 
	"# Perl-RDB  $name"."format\n",
	"# --------------------------------------------------------------------------------\n",
	"# FORM  beg          $name\n",
	"# FORM  general:     - lines starting with hashes contain comments or PARAMETERS\n",
	"# FORM  general:     - columns are delimited by tabs\n",
	"# FORM  format:      '# FORM  SPACE keyword SPACE further-information'\n",
	"# FORM  parameters:  '# PARA: SPACE keyword SPACE=TAB value TAB (further-info)'\n",
	"# FORM  notation:    '# NOTA: SPACE keyword SPACE=TAB explanation'\n",
	"# FORM  1st row:     column names  (tab delimited)\n",
	"# FORM  2nd row (may be): column format (tab delimited)\n",
	"# FORM  rows 2|3-N:  column data   (tab delimited)\n",
        "# FORM  end          $name\n",
	"# --------------------------------------------------------------------------------\n";
                                # ------------------------------
				# explanations
                                # ------------------------------
    if ($#colNamesTmp>0 || defined $tmpLoc{"nota","1"}){
        print  $fhoutLoc2 
            "# NOTA  begin        $name"."ABBREVIATIONS\n",
            "# NOTA               column names \n";
        foreach $kwd (@colNamesTmp) { # column names
            next if (! defined $kwd);
            next if (! defined $tmpLoc{"nota","$kwd"});
            printf $fhoutLoc2 "# NOTA: %-12s =\t%-s\n",$kwd,$tmpLoc{"nota","$kwd"}; }
        print  $fhoutLoc2 
            "# NOTA               parameters\n";
        foreach $it (1..1000){      # additional info
            last if (! defined $tmpLoc{"nota","$it"});
            ($kwd,$expl)=split(/\t/,$tmpLoc{"nota","$it"});
            next if (! defined $kwd);
            $expl="" if (! defined $expl);
            printf $fhoutLoc2 "# NOTA: %-12s =\t%-s\n",$kwd,$expl; }
        print $fhoutLoc2 
            "# NOTA  end          $name"."ABBREVIATIONS\n",
            "# --------------------------------------------------------------------------------\n"; }

                                # ------------------------------
				# parameters
                                # ------------------------------
    if ($#paraTmp > 0) {
        print $fhoutLoc2
            "# PARA  beg          $name\n";
        foreach $kwd (@paraTmp){
	    next if (! defined $tmpLoc{"para","$kwd"});
            $tmp="%-s";
            $tmp=$tmpLoc{"form","$kwd"} if (defined $tmpLoc{"form","$kwd"});
	    printf $fhoutLoc2
		"# PARA: %-12s =\t$tmp\n",$kwd,$tmpLoc{"para","$kwd"}; }
        print $fhoutLoc2 
            "# PARA  end          $name\n",
            "# --------------------------------------------------------------------------------\n"; }

}				# end of rdbGenWrtHdr

#===============================================================================
sub rdbphd_to_dotpred {
    local($Lscreen,$nres_per_row,$thresh_acc,$thresh_htm,$thresh_sec,
	  $opt_phd,$file_out,$protname,$Ldo_htmref,$Ldo_htmtop,@file) = @_ ;
    local($fhin,@des,@des_rd,@des_sec,@des_rd_sec,@des_acc,@des_rd_acc,@des_htm,@des_rd_htm,
	  %rdb_rd,%rdb,$file,$it,$ct,$mode_wrt,$fhout);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   rdbphd_to_dotpred           converts RDB files of PHDsec,acc,htm (both/3)
#                               to .pred files as used for PP server
#--------------------------------------------------------------------------------
    $fhin= "FHIN_RDBPHD_TO_DOTPRED";
    $fhout="FHOUT_RDBPHD_TO_DOTPRED";
				# note: @des same succession as @des_rd !!
    @des_rd_0 =     ("No", "AA");
    @des_0=         ("pos","aa");
    @des_rd_acc=    ("Obie","Pbie","OREL","PREL","RI_A");
    @des_acc=       ("obie","pbie","oacc","pacc","riacc");
				# horrible hack 20-01-98
    $fhinLoc="FHIN_rdbphd_to_dotpred";
    &open_file("$fhinLoc",$file[1]);
				# get RI for first file
    while(<$fhinLoc>){
	next if ($_=~/^\#/);
	if    ($_=~/RI\_S/){$riTmp="RI_S";}
	elsif ($_=~/RI\_H/){$riTmp="RI_H";}
	elsif ($_=~/RI\_A/){$riTmp="RI_A";}
	else  {print "*** '$_'\n";print "*** ERROR in RDB header $file[1]\n";}
	last;}close($fhinLoc);
	
    if    ($Ldo_htmref && $Ldo_htmtop) {
	@des_rd_htm=("OHL", "PHL", "RI_H", "pH",    "pL"    ,"PFHL", "PRHL", "PiTo" );
	@des_htm=   ("ohtm","phtm","rihtm",  "prHhtm","prLhtm","pfhtm","prhtm","pthtm");}
    elsif ($Ldo_htmref) {
	@des_rd_htm=("OHL", "PHL", "RI_H", "pH",    "pL"    ,"PFHL", "PRHL");
	@des_htm=   ("ohtm","phtm","rihtm",  "prHhtm","prLhtm","pfhtm","prhtm");}
    elsif ($Ldo_htmtop) {
	@des_rd_htm=("OHL", "PHL", "RI_H", "pH",    "pL"    ,"PFHL" ,"PiTo" );
	@des_htm=   ("ohtm","phtm","rihtm",  "prHhtm","prLhtm","pfhtm","pthtm");}
    else {
	@des_rd_htm=("OHL", "PHL", "$riTmp", "pH",    "pL"    ,"PFHL" );
	@des_htm=   ("ohtm","phtm","rihtm",  "prHhtm","prLhtm","pfhtm");}
    @des_rd_sec=    ("OHEL","PHEL","$riTmp", "pH",    "pE",    "pL");
    @des_sec=       ("osec","psec","risec",  "prHsec","prEsec","prLsec");
				# headers
    @deshd_rd_0=  ();
    if    ($Ldo_htmref && $Ldo_htmtop) {
	@deshd_rd_htm=("NHTM_BEST","NHTM_2ND_BEST",
#		       "REL_BEST","REL_BEST_DIFF",
		       "REL_BEST_DPROJ","MODEL","MODEL_DAT",
		       "HTMTOP_PRD","HTMTOP_RID","HTMTOP_RIP");}
    elsif ($Ldo_htmref) {
	@deshd_rd_htm=("NHTM_BEST","NHTM_2ND_BEST",
		       "REL_BEST_DPROJ","MODEL","MODEL_DAT");}
    elsif ($Ldo_htmtop) {
	@deshd_rd_htm=("HTMTOP_PRD","HTMTOP_RID","HTMTOP_RIP");}
    else {
	$#deshd_rd_htm=0;}
				# ------------------------------
				# read RDB files
				# ------------------------------
    $ct=0;
    foreach $file (@file){
	next if (! -e $file);
	++$ct;
	undef %rdb_rd;
	if ($ct==1) {
	    @des_rd=@des_rd_0;@des=@des_0;@deshd_rd=@deshd_rd_0;}
	else {
	    $#des_rd=$#des=$#deshd_rd=0;}
				# find out whether from PHDsec, PHDacc, or PHDhtm
	if   (&is_rdb_sec($file)){
	    $phd="sec";push(@des_rd,@des_rd_sec);push(@des,@des_sec);}
	elsif(&is_rdb_acc($file)){
	    $phd="acc";push(@des_rd,@des_rd_acc);push(@des,@des_acc);}
	elsif(&is_rdb_htmtop($file) || &is_rdb_htmref($file) || &is_rdb_htm($file)){
	    $phd="htm";push(@des,@des_htm);
	    push(@des_rd,@des_rd_htm);push(@deshd_rd,@deshd_rd_htm);}
	else {
	    print "*** ERROR rdbphd_to_dotpred: no RDB format recognised (file=$file)\n";
	    die; }
#	print "--- rdbphd_to_dotpred reading '$file' (phd=$phd)\n";
	%rdb_rd=
	    &rd_rdb_associative($file,"not_screen","header",@deshd_rd,"body",@des_rd); 
				# rename data (separate for PHDsec,acc,htm)
	foreach $it (1 .. $#des_rd) {
	    $ct=1;
	    while (defined $rdb_rd{"$des_rd[$it]","$ct"}) {
		$rdb{"$des[$it]","$ct"}=$rdb_rd{"$des_rd[$it]","$ct"}; 
		++$ct; }}
	foreach $deshdr (@deshd_rd){ # rename header
	    $rdb{"$deshdr"}="UNK";
	    $rdb{"$deshdr"}=$rdb_rd{"$deshdr"} if (defined $rdb_rd{"$deshdr"});}
    }
				# ------------------------------
				# now transform to strings
				# ------------------------------
    &rdbphd_to_dotpred_getstring(@des_0,@des_sec,@des_acc,@des_htm);
				# now subsets
    &rdbphd_to_dotpred_getsubset;
				# convert symbols
    $STRING{"osec"}=~s/L/ /g    if (defined $STRING{"osec"});
    $STRING{"psec"}=~s/L/ /g    if (defined $STRING{"psec"});
    $STRING{"obie"}=~s/i/ /g    if (defined $STRING{"obie"});
    $STRING{"pbie"}=~s/i/ /g    if (defined $STRING{"pbie"});
    if (defined $STRING{"ohtm"}) { 
	$STRING{"ohtm"}=~s/L/ /g;  
	if ($opt_phd !~ /htm/){
	    $STRING{"ohtm"}=~s/H/T/g;$STRING{"ohtm"}=~s/E/ /g; }}
    if (defined $STRING{"phtm"}) { 
	$STRING{"phtm"}=~s/L/ /g;  
	if ($opt_phd !~ /htm/){
	    $STRING{"phtm"}=~s/H/T/g;$STRING{"phtm"}=~s/E/ /g; }}
    if (defined $STRING{"pfhtm"}) { 
	$STRING{"pfhtm"}=~s/L/ /g; 
	if ($opt_phd !~ /htm/){
	    $STRING{"pfhtm"}=~s/H/T/g;$STRING{"pfhtm"}=~s/E/ /g; }}
    if (defined $STRING{"prhtm"}) { 
	$STRING{"prhtm"}=~s/L/ /g; 
	if ($opt_phd !~ /htm/){
	    $STRING{"prhtm"}=~s/H/T/g;$STRING{"prhtm"}=~s/E/ /g; }}

    @des_wrt=@des_0;
    $#htm_header=0;
    if    ( (length($STRING{"psec"})>3) && (length($STRING{"pacc"})>3) && 
	    (length($STRING{"phtm"})>3) ) { 
	push(@des_wrt,@des_sec,"subsec",@des_acc,"subacc",@des_htm,"subhtm"); 
	$mode_wrt="3";}
    elsif ( (length($STRING{"psec"})>3) && (length($STRING{"pacc"})>3) ) {
	push(@des_wrt,@des_sec,"subsec",@des_acc,"subacc"); 
	$mode_wrt="both"; }
    elsif ( length($STRING{"psec"})>3 ) { 
	push(@des_wrt,@des_sec,"subsec");                   
	$mode_wrt="sec"; }
    elsif ( length($STRING{"pacc"})>3 ) { 
	push(@des_wrt,@des_acc,"subacc");                   
	$mode_wrt="acc"; }
    elsif ( length($STRING{"phtm"})>3 ) { 
	push(@des_wrt,"ohtm","phtm","rihtm","prHhtm","prLhtm","subhtm","pfhtm");
	push(@des_wrt,"prhtm")  if ($Ldo_htmref);
	push(@des_wrt,"pthtm")  if ($Ldo_htmtop);
	$mode_wrt="htm"; 
	@htm_header=
	    &rdbphd_to_dotpred_head_htmtop(@deshd_rd_htm)
		if ($Ldo_htmref || $Ldo_htmtop); }
    else {
	print "*** ERROR rdbphd_to_dotpred: no \%STRING defined recognised\n";
	exit; }

    if ($Lscreen) {
	print "--- rdbphd_to_dotpred read from conversion:\n";
	&wrt_phdpred_from_string("STDOUT",$nres_per_row,$mode_wrt,$Ldo_htmref,
				 @des_wrt,"header",@htm_header); }
    &open_file("$fhout",">$file_out");
    &wrt_phdpred_from_string($fhout,$nres_per_row,$mode_wrt,$Ldo_htmref,
			     @des_wrt,"header",@htm_header); 
    close($fhout);
				# --------------------------------------------------
				# now collect for final file
				# --------------------------------------------------
    foreach $des ("aa","osec","psec","risec","oacc","pacc","riacc",
		  "ohtm","phtm","pfhtm","rihtm","prhtm","pthtm") {
	if (defined $STRING{"$des"}) {
	    if   ($des eq "aa") { 
		$nres=length($STRING{"$des"}); }
	    elsif(($des=~/^p/)&&(length($STRING{"$des"})>$nres)){
		$nres=length($STRING{"$des"}); }
	    $phd_fin{"$protname","$des"}=$STRING{"$des"}; }}
    $phd_fin{"$protname","nres"}=$nres;
				# ------------------------------
				# save memory
    undef %STRING; undef %rdb_rd; undef %rdb;
    return(%phd_fin);
}				# end of rdbphd_to_dotpred

#===============================================================================
sub rdbphd_to_dotpred_getstring {
    local (@des) = @_ ;
    local ($des,$ct);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   rdbphd_to_dotpred_getstring transform $rdb{"osec","1..n"} to $STRING{"osec"}
#       in::                     file
#       in / out GLOBAL:         %STRING, %rdb,$thresh_*,
#--------------------------------------------------------------------------------
    foreach $des (@des) {
	$STRING{"$des"}="";$ct=1;
	if ($des !~ /oacc|pacc/ ){
	    while (defined $rdb{"$des","$ct"}) {
		$STRING{"$des"}.=$rdb{"$des","$ct"};
		++$ct; } }
	else {
	    while (defined $rdb{"$des","$ct"}) {
		$STRING{"$des"}.=&exposure_project_1digit($rdb{"$des","$ct"});
		++$ct; } } }
}				# end of rdbphd_to_dotpred_getstring

#===============================================================================
sub rdbphd_to_dotpred_getsubset {
    local ($des,$ct,$desout,$thresh,$kwdPhd,$desrel);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   rdbphd_to_dotpred_getsubset assigns subsets:
#       in:                     file
#       in / out GLOBAL:        %STRING, %rdb,$thresh_*,
#--------------------------------------------------------------------------------
    foreach $des ("sec","acc","htm"){
				# assign thresholds
	if    ($des eq "sec") { $thresh=$thresh_sec; }
	elsif ($des eq "acc") { $thresh=$thresh_acc; }
	elsif ($des eq "htm") { $thresh=$thresh_htm; }

	$desphd="p"."$des";
				# note: for PHDacc subset on three states (b,e,i)
	$desphd="p"."bie"       if ($des eq "acc");
				# ignore different modes, than existing
	next if (! defined $rdb{"$desphd","1"});
	$desout="sub"."$des";
	$desrel="ri"."$des";
	$STRING{"$desout"}="";$ct=1; # initialise

	while ( defined $rdb{"$desphd","$ct"}) {
	    if ($rdb{"$desrel","$ct"} >= $thresh) {
		$STRING{"$desout"}.=$rdb{"$desphd","$ct"}; }
	    else {
		$STRING{"$desout"}.=".";}
	    ++$ct; }
    }
}				# end of rdbphd_to_dotpred_getsubset

#===============================================================================
sub rdbphd_to_dotpred_head_htmtop {
    local (@des)= @_ ;  local ($des,$tmp,@tmp,@out);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   rdbphd_to_dotpred_head_htmtop writes the header for htmtop
#--------------------------------------------------------------------------------
    $#out=0;
    foreach $des (@des){
	if (defined $rdb_rd{"$des"}){
	    $tmp=$rdb_rd{"$des"};$tmp=~s/^:*|:*$//g;
	    if ($tmp=~/\:/){
		$#tmp=0;@tmp=split(/:/,$tmp);} else {@tmp=("$tmp");}
	    if ($des !~/MODEL/){ # purge blanks and comments
		foreach $tmp (@tmp) {$tmp=~s/\(.*//g;$tmp=~s/\s//g;}}
	    foreach $tmp (@tmp) {
		push(@out,"$des:$tmp");}}}
    return(@out);
}				# end of rdbphd_to_dotpred_head_htmtop

#===============================================================================
sub rdRdbAssociative {
    local ($fileInLoc,@des_in) = @_ ;
    local ($sbr_name,$fhinLoc,$Lhead,$Lbody,$Lfound,$it,$itrd,@tmp,$tmp,$des_in,$rd,
	   @des_head,@des_headin,@des_bodyin,@des_body,%ptr_rd2des,$nrow_rd,%rdrdb,
	   $Lscreen);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   rdRdbAssociative            reads content of an RDB file into associative array
#       in:                     Names used for columns in perl file, e.g.,
#                               "header,NALIGN,body,POS,NPROT" as arguments passed
#                               would result in:
#                               reading anything in file header using the keyword 'NALIGN'
#                               reading the columns named POS and NPROT
#       out:                    rdrdb{"NALIGN"},rdrdb{"POS","ct"},rdrdb{"NPROT","ct"},
#                               where ct counts the rows read,
#                               rdrdb{"NROWS"} returns the numbers of rows read
#--------------------------------------------------------------------------------
				# avoid warning
    $READHEADER="";
    $Lscreen=1;
				# set some defaults
    $fhinLoc="FHIN_RDB";$sbr_name="rdRdbAssociative";
				# get input
    $Lhead=$Lbody=$#des_headin=$#des_bodyin=0;
    foreach $des_in (@des_in){
	if   ($des_in=~/^not_screen/)        {$Lscreen=0;}
	elsif((!$Lhead) && ($des_in=~/head/)){$Lhead=1;$Lhead_all=1;}
	elsif((!$Lbody) && ($des_in=~/body/)){$Lbody=1;$Lhead=0; }
	elsif($Lhead)                        {push(@des_headin,$des_in);}
	elsif($Lbody)                        {$des_in=~s/\n|\s//g;;
					      push(@des_bodyin,$des_in);}
	else {
	    print "*** WARNING $sbr_name: input '$des_in' not recognised.\n";} }
    if ($Lscreen) { print "--- $sbr_name: header \t ";
		    foreach $it (@des_headin){print"$it,";}print"\n"; 
		    print "--- $sbr_name: body   \t ";
		    foreach $it (@des_bodyin){print"$it,";}print"\n"; }
				# --------------------------------------------------
				# read RDB file
				# --------------------------------------------------
    &open_file("$fhinLoc","$fileInLoc");
				# out: $READHEADER :whole header, one string
				#      @READCOL    : all columns
				#      @READNAME   :names of columns
    &rdRdbAssociativeNum($fhinLoc,0);
    close($fhinLoc);
				# ------------------------------
    $#des_head=0;		# process header
    @tmp=split(/\#\s?/,$READHEADER);
    if ($#des_headin>=1){
	foreach $des_in (@des_headin) {
	    $Lfound=0;
	    foreach $rd (@tmp){
		if ($rd =~ /^(PARA\s*:?\s*)?$des_in\s*[ :,\;=]/){
		    $tmp=$rd;$tmp=~s/\n|\s$//g;$tmp=~s/^.*$des_in//g;$tmp=~s/^\s*//g;
		    $tmp=~s/^[\s:\t]*//g;
		    if (defined $rdrdb{"$des_in"}){
			$rdrdb{"$des_in"}.="\t".$tmp;}
		    else {
			$rdrdb{"$des_in"}=$tmp;}
		    push(@des_head,$des_in);$Lfound=1;} }
	    print
		"--- $sbr_name: \t expected to find in header key word:\n",
		"---            \t '$des_in', but not in file '$fileInLoc'\n"
		    if (!$Lfound && $Lscreen); }}
    elsif ($Lhead_all) {		# whole header into $rdrdb{"header"}
	$rdrdb{"header"}="";
	foreach $rd (@tmp) { $rd=~s/^\s?|\n//g;
			     $rdrdb{"header"}.="# ".$rd."\n"; }}
				# ------------------------------
    $#des_body=0;		# get column numbers to be read
    foreach $des_in (@des_bodyin) {
	$Lfound=0;
	for($it=1; $it<=$#READNAME; ++$it) {
	    $rd=$READNAME[$it];$rd=~s/\s//g;
	    if ($rd eq $des_in) {
		$ptr_rd2des{"$des_in"}=$it;push(@des_body,$des_in);$Lfound=1;
		last;} }
	if((!$Lfound) && $Lscreen){
	    print"--- $sbr_name: \t expected to find column name:\n";
	    print"---            \t '$des_in', but not in file '$fileInLoc'\n";}}
				# ------------------------------
				# get format
    foreach $des_in(@des_bodyin) {
	$it=$ptr_rd2des{"$des_in"};
	if ( defined $it && defined $READFORMAT[$it] ) {
	    $rdrdb{"$des_in","format"}=$READFORMAT[$it];}
	else {
	    $rdrdb{"$des_in","format"}="8";}}
    $nrow_rd=0;
    foreach $des_in(@des_body) {
	$itrd=$ptr_rd2des{"$des_in"};
	@tmp=split(/\t/,$READCOL[$itrd]);
	if   ($nrow_rd==0)    {$nrow_rd=$#tmp;}
	elsif($nrow_rd!=$#tmp){print "*** WARNING $sbr_name: different number of rows\n";
			       print "***         in RDB file '$fileInLoc' for rows with ".
				   "key=$des_in, column=$itrd, prev=$nrow_rd, now=$#tmp,\n";}
	for ($it=1; $it<=$#tmp; ++$it){
	    $rdrdb{"$des_in","$it"}=$tmp[$it];
	    $rdrdb{"$des_in","$it"}=~s/\s//g;}
    }
    $rdrdb{"NROWS"}=$rdrdb{"NROWS"}=$nrow_rd;
				# ------------------------------
				# safe memory
    $READHEADER=""; $#READCOL=$#READNAME=$#READFORMAT=0;
    $#des_headin=$#des_body=$#tmp=$#des_head=0;
    undef %ptr_rd2des;
    $#des_in=0;                 # slim_is_in !
    
    return (%rdrdb);
}				# end of rdRdbAssociative

#===============================================================================
sub rdRdbAssociativeNum {
    local ($fhLoc2,@readnum) = @_ ;
    local ($ctLoc, @tmpar, $it, $ipos, $tmp);
    $[ =1 ;
#----------------------------------------------------------------------
#   rdRdbAssociativeNum         reads from a file of Michael RDB format:
#       in:                     $fhLoc,@readnum,$readheader,@readcol,@readname,@readformat
#         $fhLoc:               file handle for reading
#         @readnum:             vector containing the number of columns to be read, if empty,
#                               then all columns will be read!
#         $READHEADER:          returns the complete header as one string
#         @READCOL:             returns all columns to be read (tab separated)
#         @READNAME:            returns the names of the columns
#         @READFORMAT:          returns the format of each column
#----------------------------------------------------------------------
    $READHEADER=""; $#READCOL=$#READNAME=$#READFORMAT=0;
    for ($it=1; $it<=$#readnum; ++$it) { $READCOL[$it]=""; }
    $ctLoc= 0;
    $tmpct=0;
    while ( <$fhLoc2> ) {	# ------------------------------
	++$tmpct;		# header  
	if ( /^\#/ ) { 
	    $READHEADER.= "$_";
	    next; }
	$rd=$_;$rd=~s/^\s+|\s+$//g;
	next if (length($rd)<2);
	++$ctLoc;		# count non-comment
				# ------------------------------
				# names
	if ($ctLoc==1){
	    $rd=$_;$rd=~s/^\t+|\t$//g;@tmpar=split(/\t/,$rd);
				# process wild card
	    if ($#readnum==0 || $readnum[1]==0 ||
		$readnum[1] !~ /[0-9]/ || ! defined $readnum[1] ) {
		foreach $it (1..$#tmpar){
		    $readnum[$it]=$it;$READCOL[$it]=""; }}
	    foreach $it (1..$#readnum){
		$tmp_name=$tmpar[$readnum[$it]];$tmp_name=~s/\s|\n//g;
		$READNAME[$it]="$tmp_name"; }
	    next; }
				# ------------------------------
				# skip format?
	if ($ctLoc==2 && $rd!~/\d+[SNF]\t|\t\d+[SNF]/){
	    ++$ctLoc; }
	if ($ctLoc==2) {	# read format
	    $rd=$_;$rd=~s/^\t+|\t$//g;@tmpar=split(/\t/,$rd);
	    foreach $it (1..$#readnum){
		$ipos=$readnum[$it];$tmp=$tmpar[$ipos]; $tmp=~s/\s//g;
		$READFORMAT[$it]=$tmp; }
	    next; }
				# ------------------------------
				# data
	$rd=$_;$rd=~s/^\t+|\t$//g;@tmpar=split(/\t/,$rd);
	foreach $it (1..$#readnum){
	    next if (! defined $tmpar[$readnum[$it]]); 
	    $READCOL[$it].=$tmpar[$readnum[$it]] . "\t"; }
    }
				# ------------------------------
				# massage FORMAT/COL/NAME
    foreach $it (1..$#READCOL){
	$READFORMAT[$it]=~ s/^\s+//g   if (defined $READFORMAT[$it]);
	$READFORMAT[$it]=~ s/\t$|\n//g if (defined $READFORMAT[$it]);
	$READNAME[$it]=~ s/^\s+//g     if ($#READNAME>0);
	$READNAME[$it]=~s/\t|\n//g;
	$READNAME[$it]=~s/\n//g        if ($#READNAME>0); 
	$READCOL[$it] =~ s/\t$|\n//g;  # correction: last not return!
    }
}				# end of rdRdbAssociativeNum

#===============================================================================
sub read_dssp_seqsecacc {
    local ($fh_in, $chain_in, $beg_in, $end_in ) = @_ ;
    local ($Lread, $sbrName);
    local ($tmpchain, $tmpseq, $tmpsecstr, $tmpexp, $tmppospdb, $tmpseq2, $tmpsecstr2);
    $[=1;
#----------------------------------------------------------------------
#   read_dssp_seqsecacc         reads seq, secondary str and acc from DSSP file
#                               (file expected to be open handle = $fh_in).  
#                               The reading is restricted by:
#                                  chain_in, beg_in, end_in, 
#                               which are passed in the following manner:
#                               (say chain = A, begin = 2 (PDB pos), end = 10 (PDB pos):
#                                  "A 2 10"
#                               Wild cards allowed for any of the three.
#       in:                     file_handle, chain, begin, end
#       out:                    SEQDSSP, SECDSSP, ACCDSSP, PDBPOS
#       in / out GLOBAL:        all output stuff is assumed to be global
#----------------------------------------------------------------------
    $sbrName = "read_dssp_seqsecacc" ;

#----------------------------------------
#   setting to zero
#----------------------------------------
    $#SEQDSSP=0; $#SECDSSP=0; $#ACCDSSP=0; $#PDBPOS=0; 

#----------------------------------------
#   extract input
#----------------------------------------
    if ( length($chain_in) == 0 ) { $chain_in = "*" ; }
    else { $chain_in =~tr/[a-z]/[A-Z]/; }

    if ( length($beg_in) == 0 )   { $beg_in = "*" ; }
    if ( length($end_in) == 0 )   { $end_in = "*" ; }
    $fh_in=~s/\s//g; $chain_in=~s/\s//g; $beg_in=~s/\s//g; $end_in=~s/\s//g; 

#--------------------------------------------------
#   read in file
#--------------------------------------------------

#----------------------------------------
#   skip anything before data...
#----------------------------------------
    while ( <$fh_in> ) { last if ( /^  \#  RESIDUE/ ); }
 
#----------------------------------------
#   read sequence
#----------------------------------------
    while ( <$fh_in> ) {
	$Lread=1;
	$tmpchain = substr($_,12,1); 
	$tmppospdb= substr($_,7,5); $tmppospdb=~s/\s//g;

#     check chain
	if ( ($tmpchain ne "$chain_in") && ($chain_in ne "*") ) { $Lread=0; }
#     check begin
	if ( $beg_in ne "*" ) {
	    if ( $tmppospdb < $beg_in ) { $Lread=0; } }
#     check end
	if ( $end_in ne "*" ) {
	    if ( $tmppospdb > $end_in ) { $Lread=0; } }

	if ($Lread) {
	    $tmpseq    = substr($_,14,1);
	    $tmpsecstr = substr($_,17,1);
	    $tmpexp    = substr($_,36,3);

#        lower case letter to C
	    $tmpseq2 = $tmpseq;
	    if ($tmpseq2 =~ /[a-z]/) { $tmpseq2 = "C"; }

#        convert secondary structure to 3
	    &secstr_convert_dsspto3($tmpsecstr);
	    $tmpsecstr2= $secstr_convert_dsspto3;

#        consistency check
	    if ( ($tmpseq2 !~ /[A-Z]/) && ($tmpseq2 !~ /!/) ) { 
		print "*** $sbrName: ERROR: $fileInLoc \n";
		print "*** small cap sequence: $tmpseq2 ! exit 15-11-93b \n" , "$_"; 
		exit; }
	    push(@SEQDSSP,$tmpseq); push(@SECDSSP,$tmpsecstr2); push(@ACCDSSP,$tmpexp);
	    push(@PDBPOS,$tmppospdb); }}
}                               # end of: read_dssp_seqsecacc 

#===============================================================================
sub read_fssp {
    local ($fileInLoc, $Lreversed) = @_ ;
    local ($Lexit, $tmp, $nalign, $it, $it2, $aain, $Lprint);
   $[=1;
#--------------------------------------------------
#   read_fssp                   reads the aligned fragment ranges from fssp files
#       in /out GLOBAL:         @ID1/2, POSBEG1/2, POSEND1/2, SEQBEG1/2, SEQEND1/2
#--------------------------------------------------
    if (length($Lreversed)==0) { $Lreversed=1;}
    &open_file("FILE_FSSP", "$fileInLoc");
#   ----------------------------------------
#   skip everything before "## FRAGMENTS"
#   plus: read NALIGN
#   ----------------------------------------
    $Lexit=0;
    while ( <FILE_FSSP> ) {
	if ( /^NALIGN/ ) {$tmp=$_; $tmp=~s/\n|NALIGN|\s//g;
			  $nalign=$tmp;}
	if ($Lexit) { last if (/^  NR/); }
	if (/^\#\# FRAGMENTS/) { $Lexit=1; } }

#   ----------------------------------------
#   read in fragment ranges
#   ----------------------------------------
    $it=0;
    while ( <FILE_FSSP> ) {
	$Lprint =0;
	$tmp=substr($_,1,4); $tmp=~s/\s//g; 
	if ( (($_=~/REVERSED/)||($_=~/PERMUTED/)) && $Lreversed && ($tmp<=$nalign) ) { $Lprint = 1; }
	elsif ( ($_!~/REVERSED/) && ($_!~/PERMUTED/) && ($tmp<=$nalign) ) { $Lprint = 1; }
	
	if ( $Lprint ) {
#           ------------------------------
#           new pair?
#           ------------------------------
	    if ($tmp != $it) { 
		$it=$tmp;
		$SEQBEG1[$it]=""; $SEQEND1[$it]=""; $SEQBEG2[$it]=""; $SEQEND2[$it]=""; 
		$POSBEG1[$it]=""; $POSEND1[$it]=""; $POSBEG2[$it]=""; $POSEND2[$it]=""; 
#               ------------------------------
#               extract IDs and ranges
#               ------------------------------
		$ID1[$it]=substr($_,7,6);$ID1[$it]=~s/\s//g;$ID1[$it]=~s/(\w\w\w\w)-(\w)/$1_$2/;
		$ID2[$it]=substr($_,14,6);$ID2[$it]=~s/\s//g;$ID2[$it]=~s/(\w\w\w\w)-(\w)/$1_$2/;
	    }

	    $tmp=$_;$tmp=~s/.*:\s*(.*)\s*\n/$1/; $tmp=~s/  / /g;$tmp=~s/    +//g;

#           ------------------------------
#           extract 1st and last residues
#           ------------------------------
#                                  ---------------------
#                                  convert 3 letter to 1
	    $aain=substr($_,25,3); &aa3lett_to_1lett($aain); 
	    $SEQBEG1[$it].="$aa3lett_to_1lett".",";
	    $aain=substr($_,42,3); &aa3lett_to_1lett($aain); 
	    $SEQEND1[$it].="$aa3lett_to_1lett".",";
	    $aain=substr($_,62,3); &aa3lett_to_1lett($aain); 
	    $SEQBEG2[$it].="$aa3lett_to_1lett".",";
	    $aain=substr($_,79,3); &aa3lett_to_1lett($aain); 
	    $SEQEND2[$it].="$aa3lett_to_1lett".",";

#           ------------------------------
#           extract ranges
#           ------------------------------
	    $tmp=substr($_,30,4); $tmp=~s/\s//g; $POSBEG1[$it].="$tmp".",";
	    $tmp=substr($_,47,4); $tmp=~s/\s//g; $POSEND1[$it].="$tmp".",";
	    $tmp=substr($_,67,4); $tmp=~s/\s//g; $POSBEG2[$it].="$tmp".",";
	    $tmp=substr($_,84,4); $tmp=~s/\s//g; $POSEND2[$it].="$tmp".",";
	} else {
	    $tmp=$_;$tmp=~s/.*:\s*(.*)\s*\n/$1/; $tmp=~s/  / /g;$tmp=~s/    +//g;
	}

    }
    close(FILE_FSSP);
}				# end of read_fssp

#===============================================================================
sub read_hssp_seqsecacc {
    local ($fh_in, $chain_in, $beg_in, $end_in, $length ) = @_ ;
    local ($Lread, $sbrName);
    local ($tmpchain, $tmpseq, $tmpsecstr, $tmpexp, $tmppospdb, $tmpseq2, $tmpsecstr2);
    $[=1;
#----------------------------------------------------------------------
#   read_hssp_seqsecacc          reads sequence, secondary str and acc from HSSP file
#                               (file expected to be open handle = $fh_in).  
#                               The reading is restricted by:
#                                  chain_in, beg_in, end_in, 
#                               which are passed in the following manner:
#                               (say chain = A, begin = 2 (PDB pos), end = 10 (PDB pos):
#                                  "A 2 10"
#                               Wild cards allowed for any of the three.
#       in:                     file_handle, chain, begin, end
#       out:                    SEQHSSP, SECHSSP, ACCHSSP, PDBPOS
#       out GLOBAL:             all output stuff is assumed to be global
#----------------------------------------------------------------------
    $sbrName = "read_hssp_seqsecacc" ;

#----------------------------------------
#   setting to zero
#----------------------------------------
    $#SEQHSSP=$#SECHSSP=$#ACCHSSP=$#PDBPOS=0; 

#----------------------------------------
#   extract input
#----------------------------------------
    if ( ! defined $chain_in ){$chain_in="*";}else{$chain_in=~tr/[a-z]/[A-Z]/;}
    if ( ! defined $beg_in )  {$beg_in= "*" ; }
    if ( ! defined $end_in )  {$end_in= "*" ; }
    $fh_in=~s/\s//g; $chain_in=~s/\s//g; $beg_in=~s/\s//g; $end_in=~s/\s//g; 
#--------------------------------------------------
#   read in file
#--------------------------------------------------

#   skip anything before data...
    while ( <$fh_in> ) { last if ( /^\#\# ALIGNMENTS/ ); }
#   read sequence
    $Lfirst=1;
    while ( <$fh_in> ) {
	$Lread=0;
	if ( ! / SeqNo / ) { 
	    $Lread=1;
	    last if ( /^\#\# / ) ;
	    $tmpchain = substr($_,13,1); 
	    $tmppospdb= substr($_,8,4); $tmppospdb=~s/\s//g;
#        check chain
	    if ( ($tmpchain ne "$chain_in") && ($chain_in ne "*") ) { $Lread=0; }
#        check begin
	    if ( $beg_in ne "*" ) {
		if ( $tmppospdb < $beg_in ) { $Lread=0; } }
	    elsif ( $Lfirst && ($end_in eq "*") && (defined $length) ) {
		$end_in=($tmppospdb+$length);}
	    $Lfirst=0;
#        check end
	    if ( $end_in ne "*" ) {
		if ( $tmppospdb > $end_in ) { $Lread=0; }}}
	if ($Lread) {
	    $tmpseq    = substr($_,15,1);
	    $tmpsecstr = substr($_,18,1);
	    $tmpexp    = substr($_,37,3);
#        lower case letter to C
	    $tmpseq2 = $tmpseq;
	    if ($tmpseq2 =~ /[a-z]/) { $tmpseq2 = "C"; }

#        convert secondary structure to 3
	    &secstr_convert_dsspto3($tmpsecstr);
	    $tmpsecstr2= $secstr_convert_dsspto3;
#        consistency check
	    if ( ($tmpseq2 !~ /[A-Z]/) && ($tmpseq2 !~ /!/) ) { 
		print "*** $sbrName: ERROR: $fileInLoc \n";
		print "*** small cap sequence: $tmpseq2 ! exit 15-11-93b \n" , "$_"; 
		exit; }
	    push(@SEQHSSP,$tmpseq); push(@SECHSSP,$tmpsecstr2); push(@ACCHSSP,$tmpexp);
	    push(@PDBPOS,$tmppospdb);}}
}                               # end of: read_hssp_seqsecacc 

#===============================================================================
sub read_exp80 {
    local ($fileInLoc,$des_seq,$Lseq,$des_sec,$Lsec,
	   $des_exp,$Lexp,$des_phd,$Lphd,$des_rel,$Lrel)=@_ ;
    local ($tmp,$id);
    $[=1;
#--------------------------------------------------------------------------------
#   read_exp80                  reads a secondary structure 80lines file
#
#       in:                     $fileInLoc: input file
#                               $des_seq, *sec, *phd, *rel: 
#                               descrip for seq, obs sec str, pred sec str reliability index
#                               e.g. "AA ", "Obs", "Prd", "Rel"
#                               $Lseq/sec/phd/rel: flags =0/1 read or don't read stuff
#       out GLOBAL:             @NAME, %SEQ, %SEC, %EXP, %PHDEXP, %RELEXP (key = name)
#          
#          
#--------------------------------------------------------------------------------
    $#NAME=$#SEQ=$#EXP=$#SEC=$#PHDEXP=$#RELEXP=0;

    &open_file("FHIN", "$fileInLoc");
    while ( <FHIN> ) {		# jump to first protein
	last if ( /^nos/ ); }
    while ( <FHIN> ) {
	$tmp=$_;$tmp=~s/\n//g;
	last if ($tmp=~/^END/);
	if (length($tmp)>0) {
				# ------------------------------
				# protein name, length
	    if ( $tmp =~ /^. . \w/ )  { 
		$tmp=~s/^....(\w+) *\d.*/$1/g; $tmp=~s/\n|\s//g;
		$id=$tmp;
		$SEQ{$id}=$SEC{$id}=$EXP{$id}=$PHDEXP{$id}=$RELEXP{$id}="";
		push(@NAME,$tmp); }
				# ------------------------------
				# sequence
	    elsif ( $Lseq && ($tmp =~ /^$des_seq/) ) {
		$tmp=~s/^$des_seq\s?\|//g; $tmp=~s/\s*\|$//g;
		$SEQ{$id}.=$tmp; }
				# ------------------------------
				# observed sec str
	    elsif ( $Lsec && ($tmp =~ /^$des_sec/) ) {
		$tmp=~s/^$des_sec\s?\|//g; $tmp=~s/\s*\|$//g;
		$SEC{$id}.=$tmp; }
				# ------------------------------
				# observed accessibility
	    elsif ( $Lexp && ($tmp =~ /^$des_exp/) ) {
		$tmp=~s/^$des_exp\|//g; $tmp=~s/\s*\|$//g;
		$EXP{$id}.=$tmp; }
				# ------------------------------
				# predicted accessibility
	    elsif ( $Lphd && ($tmp =~ /^$des_phd/) ) {
		$tmp=~s/^$des_phd\|//g; $tmp=~s/\s*\|$//g;
		$PHDEXP{$id}.=$tmp; }
				# ------------------------------
				# observed sec str
	    elsif ( $Lrel && ($tmp =~ /^$des_rel/) ) {
		$tmp=~s/^$des_rel\|//g; $tmp=~s/\s*\|$//g;
		$RELEXP{$id}.=$tmp; }
	}
    }
    close(FHIN);
}				# end of read_exp80

#===============================================================================
sub read_rdb_num {
    local ($fh, @readnum) = @_ ;
    local ($ct, @tmpar, $it, $ipos, $tmp);
    $[=1 ; 
#----------------------------------------------------------------------
#   read_rdb_num                reads from a file of Michael RDB format:
#       in:                     $fh,@readnum,$readheader,@readcol,@readname,@readformat
#         $fh:                  file handle for reading
#         @readnum:             vector containing the number of columns to be read
#         $readheader:          returns the complete header as one string
#         @readcol:             returns all columns to be read
#         @readname:            returns the names of the columns
#         @readformat:          returns the format of each column
#----------------------------------------------------------------------
    $readheader = ""; $#readcol = 0; $#readname = 0; $#readformat = 0;

    for ($it=1; $it<=$#readnum; ++$it) { 
	$readcol[$it]=""; $readname[$it]=""; $readformat[$it]=""; }

    $ct = 0;
    while ( <$fh> ) {
	if ( /^\#/ ) {		              # header  
	    $readheader .= "$_"; }
	else {		              # rest:
	    ++$ct;
	    if ( $ct >= 3 ) {	              # col content
		@tmpar= split(/\t/);
		for ($it=1; $it<=$#readnum; ++$it) {
                    if (defined $tmpar[$readnum[$it]]){
                        $readcol[$it].= $tmpar[$readnum[$it]] . " ";}}}
	    elsif ( $ct == 1 ) {              # col name
		@tmpar= split(/\t/);
		for ($it=1; $it<=$#readnum; ++$it) {
                    if (defined $tmpar[$readnum[$it]]){
                        $readname[$it].= $tmpar[$readnum[$it]];}} }
	    elsif ( $ct == 2 ) {	      # col format
		@tmpar= split(/\t/);
		for ($it=1; $it<=$#readnum; ++$it) {
		    $ipos= $readnum[$it];
                    if (defined $tmpar[$readnum[$ipos]]){
                        $tmp= $tmpar[$ipos]; $tmp =~ s/\s//g;
                        $readformat[$it].= $tmp . " ";}}}
	}
    } 
    for ($it=1; $it<=$#readname; ++$it) {
	$readcol[$it] =~ s/^\s+//g;	      # correction, if first characters blank
	$readformat[$it] =~ s/^\s+//g; $readname[$it] =~ s/^\s+//g;
	$readcol[$it] =~ s/\n//g;	      # correction: last not return!
	$readformat[$it] =~ s/\n//g; $readname[$it] =~ s/\n//g; 
    }
}				# end of read_rdb_num

#===============================================================================
sub read_rdb_num2 {
    local ($fh, @readnum) = @_ ;
    local ($ct, @tmpar, $it, $ipos, $tmp);
    $[ =1 ;
#----------------------------------------------------------------------
#   read_rdb_num2               reads from a file of Michael RDB format:
#       in:                     $fh,@readnum,$readheader,@readcol,@readname,@readformat
#         $fh:                  file handle for reading
#         @readnum:             vector containing the number of columns to be read, if empty,
#                               then all columns will be read!
#         $READHEADER:          returns the complete header as one string
#         @READCOL:             returns all columns to be read
#         @READNAME:            returns the names of the columns
#         @READFORMAT:          returns the format of each column
#----------------------------------------------------------------------
    $READHEADER=""; $#READCOL=$#READNAME=$#READFORMAT= 0;
    for ($it=1; $it<=$#readnum; ++$it) { $READCOL[$it]=""; }
    $ct = 0;
    while ( <$fh> ) {
	if ( /^\#/ ) {$READHEADER.= "$_"; # header  
		      next;}
	++$ct;			# rest
	if ( $ct >= 3 ) {	              # col content
	    @tmpar=split(/\t/);
	    for ($it=1; $it<=$#readnum; ++$it) {
		if (defined $tmpar[$readnum[$it]]) {
		    $READCOL[$it].=$tmpar[$readnum[$it]] . "\t"; }} }
	elsif ( $ct==1 ) {	      # col name
	    $_=~s/\t$//g;@tmpar=split(/\t/);
				# care about wild card
	    if ( ($#readnum==0)||($readnum[1]==0) ) {
		for ($it=1;$it<=$#tmpar;++$it) {$readnum[$it]=$it;}
		for ($it=1;$it<=$#tmpar;++$it) {$READCOL[$it]=""; } }
	    
	    for ($it=1; $it<=$#readnum; ++$it) {$tmp_name=$tmpar[$readnum[$it]];
						$tmp_name=~s/\s|\n//g;
						$READNAME[$it]="$tmp_name";} }
	elsif ( $ct==2 ) {	      # col format
	    if ($_=~/\t\d+[NSF]|\d+[NSF]\t/){
		@tmpar=split(/\t/);
		for ($it=1; $it<=$#readnum; ++$it) {
		    $ipos=$readnum[$it];$tmp=$tmpar[$ipos]; $tmp=~s/\s//g;
		    $READFORMAT[$it]=$tmp;}}
	    else {		# no format given, read line
		@tmpar=split(/\t/);
		for ($it=1; $it<=$#readnum; ++$it) {
		    if (defined $tmpar[$readnum[$it]]) {
			$READCOL[$it].=$tmpar[$readnum[$it]] . "\t";}}}}
    }
    for ($it=1; $it<=$#READNAME; ++$it) {
	if (!defined $READFORMAT[$it]){
	    print "-*- WARN lib-br.pl:read_rdb_num2: READFORMAT for it=$it not defined\n";
	    $READFORMAT[$it]=" ";}
	$READFORMAT[$it]=~ s/^\s+//g;
	if ($#READNAME>0) { $READNAME[$it]=~ s/^\s+//g;}
	$READCOL[$it] =~ s/\t$|\n//g;	      # correction: last not return!
	$READFORMAT[$it]=~ s/\t$|\n//g;$READNAME[$it]=~s/\t|\n//g;
	if ($#READNAME>0) { $READNAME[$it]=~s/\n//g; }
    }
}				# end of read_rdb_num2

#===============================================================================
sub read_sec80 {
    local ($fileInLoc,$des_seq,$Lseq,$des_sec,$Lsec,$des_phd,$Lphd,$des_rel,$Lrel) = @_ ;
    local ($tmp,$id);
    $[=1;
#--------------------------------------------------------------------------------
#   read_sec80                  reads a secondary structure 80lines file
#       in:                     $fileInLoc: input file
#                               $des_seq, *sec, *phd, *rel: 
#                               descr for seq, obs sec str, pred sec str reliability index
#                               e.g. "AA ", "Obs", "Prd", "Rel"
#                               $Lseq/sec/phd/rel: flags =0/1 read or don't read stuff
#       out GLOBAL:             @NAME, %SEQ, %SEC, %PHD, %REL (key = name)
#--------------------------------------------------------------------------------
    $#NAME=$#SEQ=$#SEC=$#PHDSEC=$#RELSEC=0;

    &open_file("FHIN", "$fileInLoc");
    while ( <FHIN> ) {		# jump to first protein
	last if ( /^nos/ );}
    while ( <FHIN> ) {
	$tmp=$_;$tmp=~s/\n//g;
	last if ($tmp=~/^END/);
	if (length($tmp)>0) {
				# ------------------------------
				# protein name, length
	    if ( $tmp =~ /^. . \w/ )  { 
		$tmp=~s/^....(\w+) *\d.*/$1/g; $tmp=~s/\n|\s//g;
		$id=$tmp;
		$SEQ{$id}=$SEC{$id}=$PHDSEC{$id}=$RELSEC{$id}="";
		push(@NAME,$tmp); }
				# ------------------------------
				# sequence
	    elsif ( $Lseq && ($tmp =~ /^$des_seq/) ) {
		$tmp=~s/^$des_seq\s?\|//g; $tmp=~s/\s*\|$//g;
		$SEQ{$id}.=$tmp; }
				# ------------------------------
				# observed sec str
	    elsif ( $Lsec && ($tmp =~ /^$des_sec/) ) {
		$tmp=~s/^$des_sec\|//g; $tmp=~s/\|$//g;
		$SEC{$id}.=$tmp; }
				# ------------------------------
				# predicted sec str
	    elsif ( $Lphd && ($tmp =~ /^$des_phd/) ) {
		$tmp=~s/^$des_phd\|//g; $tmp=~s/\|$//g;
		$PHDSEC{$id}.=$tmp; }
				# ------------------------------
				# observed sec str
	    elsif ( $Lrel && ($tmp =~ /^$des_rel/) ) {
		$tmp=~s/^$des_rel\|//g; $tmp=~s/\s*\|$//g;
		$RELSEC{$id}.=$tmp; }
	}
    }
    close(FHIN);

}				# end of read_sec80

#===============================================================================
sub safRd {
    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   safRd                       reads SAF format
#       in:                     $fileOutLoc,
#       out:                    ($Lok,$msg,$tmp{}) with:
#       out:                    $tmp{"NROWS"}  number of alignments
#       out:                    $tmp{"id", "$it"} name for $it
#       out:                    $tmp{"seq","$it"} sequence for $it
#       err:                    ok-> 1,ok | error -> 0,message
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."safRd";$fhinLoc="FHIN_"."safRd";
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc!")          if (! defined $fileInLoc);
    return(0,"*** $sbrName: miss in file '$fileInLoc'!")  if (! -e $fileInLoc);

    $LverbLoc=0;

    &open_file("$fhinLoc","$fileInLoc") ||
	return(0,"*** ERROR $sbrName: fileIn=$fileInLoc, not opened\n");

    $ctBlocks=$ctRd=$#nameLoc=0;  undef %nameInBlock; 
    undef %tmp;			# --------------------------------------------------
				# read file
    while (<$fhinLoc>) {	# --------------------------------------------------
	$_=~s/\n//g;
	next if ($_=~/\#/);	# ignore comments
	last if ($_!~/\#/ && $_=~/^\s*[\-\_]+\s*$/); # stop when address
	$line=$_;
				# ignore lines with numbers, blanks, points only
	$tmp=$_; $tmp=~s/[^A-Za-z]//g;
	next if (length($tmp)<1);

	$line=~s/^\s*|\s*$//g;	# purge leading blanks
				# ------------------------------
				# names
	$name=$line; $name=~s/^([^\s\t]+)[\s\t]+.*$/$1/;
				# maximal length: 14 characters (because of MSF2Hssp)
	$name=substr($name,1,14);
				# ------------------------------
				# sequences
	$seq=$line;$seq=~s/^\s*//;$seq=~s/^[^\s\t]+//;$seq=~s/\s//g;
# 	next if ($seq =~/^ACDEFGHIKLMNPQRSTVWXYZ/i);  # check this!!
	print "--- $sbrName: name=$name, seq=$seq,\n" if ($LverbLoc);
				# ------------------------------
				# guide sequence: determine length
				# NOTE: no 'left-outs' allowed here
				# ------------------------------
	$nameFirst=$name        if ($#nameLoc==0);	# detect first name
	if ($name eq "$nameFirst"){
	    ++$ctBlocks;	# count blocks
	    undef %nameInBlock;
	    if ($ctBlocks == 1){
		$lenFirstBeforeThis=0;}
	    else {
		$lenFirstBeforeThis=length($tmp{"seq","1"});}

	    if ($ctBlocks>1) {	# manage proteins that did not appear
		$lenLoc=length($tmp{"seq","1"});
		foreach $itTmp (1..$#nameLoc){
		    $tmp{"seq","$itTmp"}.="." x ($lenLoc-length($tmp{"seq","$itTmp"}));}
	    }}
				# ------------------------------
				# ignore 2nd occurence of same name
	next if (defined $nameInBlock{"$name"}); # avoid identical names

				# ------------------------------
				# new name
	if (! defined ($tmp{"$name"})){
	    push(@nameLoc,$name); ++$ctRd;
	    $tmp{"$name"}=$ctRd; $tmp{"id","$ctRd"}=$name;
	    print "--- $sbrName: new name=$name,\n"   if ($LverbLoc);

	    if ($ctBlocks>1){	# fill up with dots
		print "--- $sbrName: file up for $name, with :$lenFirstBeforeThis\n" if ($LverbLoc);
		$tmp{"seq","$ctRd"}="." x $lenFirstBeforeThis;}
	    else{
		$tmp{"seq","$ctRd"}="";}}
				# ------------------------------
				# finally store
	$seq=~s/[^A-Za-z]/\./g; # any non-character to dot
	$seq=~tr/[a-z]/[A-Z]/;
	$ptr=$tmp{"$name"};    
	$tmp{"seq","$ptr"}.=$seq;
	$nameInBlock{"$name"}=1; # avoid identical names
    } close($fhinLoc);
				# ------------------------------
				# fill up ends
    $lenLoc=length($tmp{"seq","1"});
    foreach $itTmp (1..$#nameLoc){
	$tmp{"seq","$itTmp"}.="." x ($lenLoc-length($tmp{"seq","$itTmp"}));}
    $tmp{"NROWS"}=$ctRd;
    $tmp{"names"}=join (',',@nameLoc);  $tmp{"names"}=~s/^,*|,*$//;

    $#nameLoc=0; undef %nameInBlock;

    return(1,"ok $sbrName",%tmp);
}				# end of safRd

#===============================================================================
sub safWrt {
    local($fileOutLoc,%tmp) = @_ ;
    local(@nameLoc,@stringLoc,$tmp,$sbrName,$Lok);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   safWrt                      writing an SAF formatted file of aligned strings
#       in:                     $fileOutLoc       output file
#                                   = "STDOUT"    -> write to screen
#       in:                     $tmp{"NROWS"}     number of alignments
#       in:                     $tmp{"id", "$it"} name for $it
#       in:                     $tmp{"seq","$it"} sequence for $it
#       in:                     $tmp{"PER_LINE"}  number of res per line (def=50)
#       in:                     $tmp{"HEADER"}    'line1\n,line2\n'..
#                                   with line1=   '# NOTATION ..'
#       out:                    1|0,msg implicit: file
#       err:                    ok-> 1,ok | error -> 0,message
#--------------------------------------------------------------------------------
    $sbrName="lib-br:safWrt"; $fhoutLoc="FHOUT_safWrt";
                                # check input
    return(0,"*** ERROR $sbrName: no acceptable output file ($fileOutLoc) defined\n") 
        if (! defined $fileOutLoc || length($fileOutLoc)<1 || $fileOutLoc !~/\w/);
    return(0,"*** ERROR $sbrName: no input given (or not input{NROWS})\n") 
        if (! defined %tmp || ! %tmp || ! defined $tmp{"NROWS"} );
    return(0,"*** ERROR $sbrName: tmp{NROWS} < 1\n") 
        if ($tmp{"NROWS"} < 1);
    $tmp{"PER_LINE"}=50         if (! defined $tmp{"PER_LINE"});
    $fhoutLoc="STDOUT"          if ($fileOutLoc eq "STDOUT");
                                # ------------------------------
                                # open new file
    if ($fhoutLoc ne "STDOUT") {
	&open_file("$fhoutLoc",">$fileOutLoc") ||
	    return(0,"*** ERROR $sbrName: failed opening fileOut=$fileOutLoc\n"); }
				# ------------------------------
				# write header
				# ------------------------------
    print $fhoutLoc "# SAF (Simple Alignment Format)\n","\# \n";
    print $fhoutLoc $tmp{"HEADER"} if (defined $tmp{"HEADER"});

				# ------------------------------
				# write data into file
				# ------------------------------
    for($itres=1; $itres<=length($tmp{"seq","1"}); $itres+=$tmp{"PER_LINE"}){
	foreach $itpair (1..$tmp{"NROWS"}){
	    printf $fhoutLoc "%-20s",$tmp{"id","$itpair"};
				# chunks of $tmp{"PER_LINE"}
	    $chunkEnd=$itres + ($tmp{"PER_LINE"} - 1);
	    foreach $itchunk ($itres .. $chunkEnd){
		last if (length($tmp{"seq","$itpair"}) < $itchunk);
		print $fhoutLoc substr($tmp{"seq","$itpair"},$itchunk,1);
				# add blank every 10
		print $fhoutLoc " " 
		    if ($itchunk != $itres && (int($itchunk/10)==($itchunk/10)));
	    }
	    print $fhoutLoc "\n"; }
	print $fhoutLoc "\n"; }
    
    print $fhoutLoc "\n";
    close($fhoutLoc);
    $#nameLoc=$#stringLoc=0;	# save space

    return(0,"*** ERROR $sbrName: failed to write file $fileOutLoc\n") if (! -e $fileOutLoc);
    return(1,"ok $sbrName");
}				# end of safWrt

#===============================================================================
sub secstr_convert_dsspto3 {
    local ($sec_in) = @_;
    local ($sec_out);
    $[=1;
#----------------------------------------------------------------------
#   secstr_convert_dsspto3      converts DSSP 8 into 3
#----------------------------------------------------------------------

    if ( $sec_in eq "T" ) { $sec_out = " "; }
    elsif ( $sec_in eq "S" ) { $sec_out = " "; }
    elsif ( $sec_in eq " " ) { $sec_out = " "; }
    elsif ( $sec_in eq "B" ) { $sec_out = " "; } 
#    elsif ( $sec_in eq "B" ) { $sec_out = "B"; }
    elsif ( $sec_in eq "E" ) { $sec_out = "E"; }
    elsif ( $sec_in eq "H" ) { $sec_out = "H"; } 
    elsif ( $sec_in eq "G" ) { $sec_out = "H"; }
    elsif ( $sec_in eq "I" ) { $sec_out = "H"; }
    else { $sec_out = " "; } 
    if ( length($sec_out) == 0 ) { 
	print "*** ERROR in sub: secstr_convert_dsspto3, out: -$sec_out- \n";
	exit;}
    $secstr_convert_dsspto3 = $sec_out;
}				# end of secstr_convert_dsspto3 

#===============================================================================
sub seqGenWrt {
    local($seqInLoc,$idInLoc,$formOutLoc,$fileOutLoc,$fhErrSbr) = @_ ;
    local($sbrName,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   seqGenWrt                   writes protein sequence in various output formats
#       in:                     $seq,$id,$formOut,$fileOut,$fhErrSbr
#       out:                    implicit: fileOut
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="lib-br:"."seqGenWrt"; $fhoutLoc="FHOUT_"."seqGenWrt";
				# check arguments
    return(0,"*** $sbrName: not def seqInLoc!")         if (! defined $seqInLoc);
    return(0,"*** $sbrName: not def idInLoc!")          if (! defined $idInLoc);
    return(0,"*** $sbrName: not def formOutLoc!")       if (! defined $formOutLoc);
    return(0,"*** $sbrName: not def fileOutLoc!")       if (! defined $fileOutLoc);
    $fhErrSbr="STDOUT"                                  if (! defined $fhErrSbr);

    return(0,"*** $sbrName: sequence missing")          if (length($seqInLoc)<1);

    undef %tmp;
				# ------------------------------
    $tmp{"seq","1"}=$seqInLoc;	# intermediate variable for seq
    $tmp{"NROWS"}=  1;
    $tmp{"id","1"}= $idInLoc;
    $Lok=0;
				# ------------------------------
				# write output
    if    ($formOutLoc =~ /^fasta/){ ($Lok,$msg)=&fastaWrtMul($fileOutLoc,%tmp);}
    elsif ($formOutLoc =~ /^pir/)  { ($Lok,$msg)=&pirWrtMul($fileOutLoc,%tmp);}
    elsif ($formOutLoc eq "saf")   { ($Lok,$msg)=&safWrt($fileOutLoc,%tmp);}
    elsif ($formOutLoc eq "msf")   { $tmp{"FROM"}="unk";$tmp{"TO"}=$fileOutLoc;
				     $tmp{"1"}=$idInLoc;$tmp{"$idInLoc"}=$seqInLoc;
				     &open_file("$fhoutLoc",">$fileOutLoc") ||
					 return(&errSbr("failed creating $fileOutLoc"));
				     $Lok=
					 &msfWrt($fhoutLoc,%tmp);
				     close($fhoutLoc);
				     return(&errSbr("failed writing msf=$fileOutLoc (msfWrt)"))
					 if (! $Lok);}
    else {
	return(0,"*** ERROR $sbrName output format $formOutLoc not supported\n");}

    return(0,"*** ERROR $sbrName: failed to write $formOutLoc into $fileOutLoc\n")
	if (! $Lok || ! -e $fileOutLoc);

    return(1,"ok $sbrName");
}				# end of seqGenWrt

#===============================================================================
sub seqide_compute {
    local ($s1,$s2) = @_ ;
    local ($ide,$len,$len2,$it);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   seqide_compute              returns pairwise seq identity between 2 strings
#                               (identical length, if not only identity of the first N,
#                               where N is the length of the shorter string, returned)
#       in:                     string1,string2
#       out:                    identity,length
#--------------------------------------------------------------------------------
				# get minimum length
    if (length($s1)>length($s2)){$len=length($s2);}else{$len=length($s1);}
    $ide=$len2=0;		# sum identity
    foreach $it (1..$len){
	$aa1=substr($s1,$it,1);$aa2=substr($s2,$it,1);
				# exclude insertions
	if ( ($aa1=~/[A-Z]/) && ($aa2=~/[A-Z]/) ) {
	    ++$len2;
	    if ($aa1 eq $aa2) {
		++$ide;}}
    }
    return($ide,$len2);
}				# end of seqide_compute

#===============================================================================
sub seqide_exchange {
    local ($s1,$s2,$aa) = @_ ;
    local ($ide,$len,$len2,$it,$aa1,$aa2,%mat);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   seqide_exchange             exchange matrix res type X in seq 1 -> res type Y in seq 2
#       in:                     string1,string2
#       out:                    matrix
#--------------------------------------------------------------------------------
    $#aa=0;@aa=split(//,$aa);
    foreach $it1(@aa){		# ini
	foreach $it2(@aa){
	    $mat{"$it1","$it2"}=0;}}
				# get minimum length
    if (length($s1)>length($s2)){$len=length($s2);}else{$len=length($s1);}
    $ide=$len2=0;		# sum identity
    foreach $it (1..$len){
	$aa1=substr($s1,$it,1);$aa2=substr($s2,$it,1);
				# exclude insertions
	if ( ($aa1=~/[A-Z]/) && ($aa2=~/[A-Z]/) ) {
	    ++$len2;
	    ++$mat{"$aa1","$aa2"}; }}
    return(%mat);
}				# end of seqide_exchange

#===============================================================================
sub seqide_weighted {
    local ($s1,$s2,%metric)=@_;
    local ($aa1,$aa2,$ide,$it,$len,$len2);
    $[=1;
#--------------------------------------------------------------------------------
#   profile_count               computes the weighted similarity
#--------------------------------------------------------------------------------
				# get minimum length
    if (length($s1)>length($s2)){$len=length($s2);}else{$len=length($s1);}
    $ide=$len2=0;
    foreach $it (1..$len){
	$aa1=substr($s1,$it,1);
	$aa2=substr($s2,$it,1);
	next if (! defined $metric{"$aa1","$aa2"});
	if ( ($aa1=~/[A-Z]/) && ($aa2=~/[A-Z]/) ) {
	    ++$len2;
	    $ide+=$metric{"$aa1","$aa2"};}}
    return($ide,$len2);
}				# end of seqide_weighted

#===============================================================================
sub sort_by_pdbid {
    local (@id) = @_ ;
    local ($id,$t1,$t2,$des,%id);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   sort_by_pdbid               sorts a list of ids by alphabet (first number opressed)
#--------------------------------------------------------------------------------
    foreach $id (@id) {
	$des=substr($id,2).substr($id,1,1);
	$id{"$des"}=$id; }
    $#id=0;
    foreach $keyid (sort keys(%id)){
	push(@id,$id{"$keyid"});}
    return (@id);
}				# end of sort_by_pdbid

#===============================================================================
sub stat_avevar {
    local(@data)=@_;
    local($i, $ave, $var);
    $[=1;
#----------------------------------------------------------------------
#   stat_avevar                 computes average and variance
#       in:                     @data (vector)
#       out:                    $AVE, $VAR
#          GLOBAL:              $AVE, $VAR (returned as list)
#----------------------------------------------------------------------
    $ave=$var=0;
    foreach $i (@data) { $ave+=$i; } 
    if ($#data > 0) { $AVE=($ave/$#data); } else { $AVE="0"; }
    foreach $i (@data) { $tmp=($i-$AVE); $var+=($tmp*$tmp); } 
    if ($#data > 1) { $VAR=($var/($#data-1)); } else { $VAR="0"; }
    return ($AVE,$VAR);
}				# end of stat_avevar

#===============================================================================
sub stat2DarrayWrt {
    local($sepL,$Lnum,$Lperc,$Lcperc,$Lfano,$Lrobson,$Lbayes,%tmp) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   stat2DarrayWrt               writes counts
#       in:                     $sep        :    symbol for separating columns
#       in:                     $Lnum=   1|0:    write simple counts
#       in:                     $Lperc=  1|0:    write percentages (of total sum)
#       in:                     $Lcperc= 1|0:    write row percentages (of sum over rows)
#       in:                     $Lfano=  1|0:    write fano info
#       in:                     $Lrobson=1|0:    write robsons info diff
#       in:                     $Lbayes= 1|0:    write bayes prob
#       in:                     $tmp{}:
#                               $tmp{"S"}=       "s1,s2,.."
#                               $tmp{"R"}=       "r1,r2,.."
#                               $tmp{"$R","$S"}= number of residues $res in state $S
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."stat2DarrayWrt";$fhinLoc="FHIN_"."stat2DarrayWrt";

				# ------------------------------
				# get states/features
    return(&errSbr("tmp{R} not defined")) if (! defined $tmp{"R"});
    return(&errSbr("tmp{S} not defined")) if (! defined $tmp{"S"});
    $tmp{"R"}=~s/^,*|,*$//g;
    $tmp{"S"}=~s/^,*|,*$//g;
    @rloc=split(/,/,$tmp{"R"});
    @sloc=split(/,/,$tmp{"S"});
    undef %tmp2;
				# ------------------------------
				# get info
    ($Lok,$msg,%tmp2)=
	&funcInfoConditional($Lfano,$Lrobson,$Lbayes,%tmp);
    return(&errSbrMsg("stat2DarrayWrt: failed on info",$msg)) if (! $Lok);

				# --------------------------------------------------
				# build up to write
				# --------------------------------------------------
    $tmpWrt="";
				# ------------------------------
				# numbers
    $des="num";			# ------------------------------
    if ($Lnum){
	$f0="%-6s";
	$f2="%8d";$f1=$f2;$f1=~s/(\d+)\.?\d*[df]/$1/;$f1.="s";$d1=$f1;$d1=~s/\D//g;
				# header
	$tmpWrt.=               sprintf("$f0$sepL$f1",$des,"aa");
	foreach $sloc (@sloc){
	    $tmpWrt.=           sprintf("$sepL$f1",   $sloc); }
	$tmpWrt.=               sprintf("$sepL$f1",   "sum");
	$tmpWrt.=               "\n";
				# data
	foreach $rloc (@rloc) {
	    $tmpWrt.=           sprintf("$f0$sepL$f1",$des,"$rloc");
	    foreach $sloc (@sloc) {
		$tmpWrt.=       sprintf("$sepL$f2",   $tmp{"$rloc","$sloc"}); }
	    $tmpWrt.=           sprintf("$sepL$f2",   $tmp2{"Rsum","$rloc"});
	    $tmpWrt.=           "\n"; }
				# sum
	$tmpWrt.=               sprintf("$f0$sepL$f1",$des,"sum");
	foreach $sloc (@sloc) {
	    $tmpWrt.=           sprintf("$sepL$f2",   $tmp2{"Ssum","$sloc"}); }
	$tmpWrt.=               sprintf("$sepL$f2",   $tmp2{"sum"});
	$tmpWrt.=               "\n"; 
    }
				# ------------------------------
				# percentages (over total counts)
    $des="perc";		# ------------------------------
    if ($Lperc){
	$f0="%-6s";
	$f2="%5.1f";$f1=$f2;$f1=~s/(\d+)\.?\d*[df]/$1/;$f1.="s";$d1=$f1;$d1=~s/\D//g;
				# header
	$tmpWrt.=               sprintf("$f0$sepL$f1",$des,"aa");
	foreach $sloc (@sloc){
	    $tmpWrt.=           sprintf("$sepL$f1",   $sloc); }
	$tmpWrt.=               sprintf("$sepL$f1",   "sum");
	$tmpWrt.=               "\n";
				# data
	foreach $rloc (@rloc) {
	    $tmpWrt.=           sprintf("$f0$sepL$f1",$des,"$rloc");
	    foreach $sloc (@sloc) {
		$tmpWrt.=       sprintf("$sepL$f2",   100*($tmp{"$rloc","$sloc"}/$tmp2{"sum"}));}
	    $tmpWrt.=           sprintf("$sepL$f2",   100*($tmp2{"Rsum","$rloc"}/$tmp2{"sum"}));
	    $tmpWrt.=           "\n"; }
				# sum
	$tmpWrt.=               sprintf("$f0$sepL$f1",$des,"sum");
	foreach $sloc (@sloc) {
	    $tmpWrt.=           sprintf("$sepL$f2" ,  100*($tmp2{"Ssum","$sloc"}/$tmp2{"sum"}));}
	$tmpWrt.=               sprintf("$sepL$f2",   100);
	$tmpWrt.=               "\n";
    }
				# ------------------------------
				# c-percentages (row counts)
    $des="cperc";		# ------------------------------
    if ($Lcperc){
	$f0="%-6s";
	$f2="%5.1f";$f1=$f2;$f1=~s/(\d+)\.?\d*[df]/$1/;$f1.="s";$d1=$f1;$d1=~s/\D//g;
				# header
	$tmpWrt.=               sprintf("$f0$sepL$f1",$des,"aa");
	foreach $sloc (@sloc){
	    $tmpWrt.=           sprintf("$sepL$f1",   $sloc); }
	$tmpWrt.=               sprintf("$sepL$f1",   "sum");
	$tmpWrt.=               "\n";
				# data
	foreach $rloc (@rloc) {
	    $tmpWrt.=           sprintf("$f0$sepL$f1",$des,"$rloc");
	    $tmp=0;
	    foreach $sloc (@sloc) {
		$cperc=0;$cperc=100*($tmp{"$rloc","$sloc"}/$tmp2{"Rsum","$rloc"})
		    if ($tmp2{"Rsum","$rloc"}>0);
		$tmp+=$cperc;
		$tmpWrt.=       sprintf("$sepL$f2",   $cperc); }
	    $tmpWrt.=           sprintf("$sepL$f2",   $tmp);
	    $tmpWrt.=           "\n"; }
    }
				# ------------------------------
				# Fano information
    $des="fano";		# ------------------------------
    if ($Lfano){
	$f0="%-6s";
	$f2="%6.2f";$f1=$f2;$f1=~s/(\d+)\.?\d*[df]/$1/;$f1.="s";$d1=$f1;$d1=~s/\D//g;
				# header
	$tmpWrt.=               sprintf("$f0$sepL$f1",$des,"aa");
	foreach $sloc (@sloc){
	    $tmpWrt.=           sprintf("$sepL$f1",   $sloc); }
	$tmpWrt.=               "\n";
				# data
	foreach $rloc (@rloc) {
	    $tmpWrt.=           sprintf("$f0$sepL$f1",$des,"$rloc");
	    foreach $sloc (@sloc) {
		$tmpWrt.=       sprintf("$sepL$f2",   $tmp2{"fano","$rloc","$sloc"}); }
	    $tmpWrt.=           "\n"; }
    }
				# ------------------------------
				# Robson information
    $des="robson";		# ------------------------------
    if ($Lrobson){
	$f0="%-6s";
	$f2="%6.2f";$f1=$f2;$f1=~s/(\d+)\.?\d*[df]/$1/;$f1.="s";$d1=$f1;$d1=~s/\D//g;
				# header
	$tmpWrt.=               sprintf("$f0$sepL$f1",$des,"aa");
	foreach $sloc (@sloc){
	    $tmpWrt.=           sprintf("$sepL$f1",   $sloc); }
	$tmpWrt.=               "\n";
				# data
	foreach $rloc (@rloc) {
	    $tmpWrt.=           sprintf("$f0$sepL$f1",$des,"$rloc");
	    foreach $sloc (@sloc) {
		$tmpWrt.=       sprintf("$sepL$f2",   $tmp2{"robson","$rloc","$sloc"}); }
	    $tmpWrt.=           "\n"; }
    }
				# ------------------------------
				# Bayes prob
    $des="bayes";		# ------------------------------
    if ($Lbayes){
	$f0="%-6s";$f2="%5.1f";$f1=$f2;$f1=~s/(\d+)\.?\d*[df]/$1/;$f1.="s";$d1=$f1;$d1=~s/\D//g;
				# header
	$tmpWrt.=               sprintf("$f0$sepL$f1",$des,"aa");
	foreach $sloc (@sloc){
	    $tmpWrt.=           sprintf("$sepL$f1",   $sloc); }
	$tmpWrt.=               sprintf("$sepL$f1",   "sum");
	$tmpWrt.=               "\n";
				# data
	foreach $rloc (@rloc) {
	    $tmpWrt.=           sprintf("$f0$sepL$f1",$des,"$rloc");
	    foreach $sloc (@sloc) {
		$tmpWrt.=       sprintf("$sepL$f2",   100*$tmp2{"bayes","$rloc","$sloc"}); }
	    $tmpWrt.=           sprintf("$sepL$f2",   100*$tmp2{"bayes","Rsum","$rloc"});
	    $tmpWrt.=           "\n"; }
    }
				# ------------------------------
    undef %tmp; undef %tmp2;	# slim-is-in!
    return(1,"ok $sbrName",$tmpWrt);
}				# end of stat2DarrayWrt

#===============================================================================
sub swissGetFile { 
    local ($idLoc,$LscreenLoc,@dirLoc) = @_ ; 
    local ($fileLoc,$dirLoc,$tmp,@dirSwissLoc);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   swissprotGetFile           returns SWISS-PROT file for given filename
#        in:                   $id,$LscreenLoc,@dirLoc
#        out:                  $file  (id or 0 for error)
#--------------------------------------------------------------------------------
    return($idLoc) if (-e $idLoc); # already existing directory
    $#dirLoc=0 if (! defined @dirLoc);
    if    (! defined $Lscreen){$Lscreen=0;}
    elsif (-d $Lscreen)       {@dirLoc=($Lscreen,@dirLoc);$Lscreen=0;}
    @dirSwissLoc=("/data/swissprot/current/"); # swiss dir's
#===============================================================================
				# add species sub directory
    foreach $dirLoc(@dirSwissLoc){
	next if (! defined $dirLoc || ! -d $dirLoc || $dirLoc !~/current/);
	$dirCurrent=$dirLoc;
	last;}
    $tmp=$idLoc;$tmp=~s/^[^_]+_(.).+$/$1/g;
    $dirSpecies=&complete_dir($dirCurrent)."$tmp"."/" if (defined $dirCurrent && -d $dirCurrent);
    push(@dirSwissLoc,$dirSpecies) if (defined $dirSpecies && -d $dirSpecies);
				# go through all directories
    foreach $dirLoc(@dirSwissLoc){
	next if (! defined $dirLoc);
	next if (! -d $dirLoc);	# directory not existing
	$fileLoc=&complete_dir($dirLoc)."$idLoc";
	return($fileLoc) if (-e $fileLoc);
	$tmp=$idLoc;$tmp=~s/^.*\///g; # purge directory
	$tmp=~s/^.*_(.).*$/$1/;$tmp=~s/\n//g; # get species
	$fileLoc=&complete_dir($dirLoc).$tmp."/"."$idLoc";
	return($fileLoc) if (-e $fileLoc);}
    return(0);
}				# end of swissGetFile

#===============================================================================
sub swissGetKingdom {
    local($fileLoc,$kingdomLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,@specLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   swissGetKingdom             gets all species for given kingdom
#       in:                     $kingdom (all,euka,proka,virus,archae)
#       out:                    @species
#-------------------------------------------------------------------------------
    $sbrName="swissKingdom2Species";$fhinLoc="FHIN"."$sbrName";$fhinLoc=~tr/[a-z]/[A-Z]/;
				# assign search pattern
    if    ($kingdomLoc eq "all")   { $tmp="EPAV";}
    elsif ($kingdomLoc eq "euka")  { $tmp="E";}
    elsif ($kingdomLoc eq "proka") { $tmp="P";}
    elsif ($kingdomLoc eq "virus") { $tmp="V";}
    elsif ($kingdomLoc eq "archae"){ $tmp="A";}
				# read SWISS-PROT file (/data/swissprot/speclist.txt)
    $#specLoc=0;
    $Lok=&open_file("$fhinLoc","$fileLoc");
    if ($Lok){			# notation 'SPECIES V|P|E|A\d+ ..'
	while (<$fhinLoc>) {last if /^Code  Taxon: N=Official name/;}
	while (<$fhinLoc>) {if (! /^[A-Z].*[$tmp][0-9a-z:]+ /){next;}
			    @tmp=split(/\s+/,$_);
			    $tmp[1]=~tr/[A-Z]/[a-z]/;
			    push(@specLoc,$tmp[1]);}close($fhinLoc);}
    else {
	return(@specLoc,"file missing");}
    return(@specLoc);

}				# end of swissGetKingdom

#===============================================================================
sub swissGetLocation {
    local ($regexpLoc,$fhLoc,@fileInLoc) = @_ ;
    local($sbrName,$fhoutLoc,$LverbLoc,@outLoc,@rdLoc);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   swissGetLocation            searches in SWISS-PROT file for cell location           
#       in:                     $regexp,$handle,@file
#                               $regexp e.g. = "^CC .*SUBCELLULAR LOCATION:"
#                               $fhLoc  = 0,1,FHOUT (file handle for blabla)
#                               @file   = swissprot files to read
#       out:                    @lines_with_expression
#--------------------------------------------------------------------------------
    $sbrName="swissGetLocation";$fhinLoc="FHIN_$sbrName";
    if    ($fhLoc eq "0"){$fhoutLoc=0;$LverbLoc=0;}	# file handle
    elsif ($fhLoc eq "1"){$fhoutLoc="STDOUT";$LverbLoc=0;}
    else                 {$fhoutLoc=$fhLoc;$LverbLoc=0;}
				# ------------------------------
				# read swiss-prot files
    $#finLoc=0;
    foreach $fileTmp (@fileInLoc){
	if (! -e $fileTmp){
	    next;}
	&open_file("$fhinLoc", "$fileTmp");$Lok=$Lfin=0;$loci="";
	while (<$fhinLoc>) {$_=~s/\n//g;
			    if (/$regexpLoc/) {	# find first line (CC )
				$_=~s/$regexpLoc//g; # purge keywords
				$Lok=1;$loci="$_"." ";}
			    elsif ($Lok && /^[^C]|^CC\s+-\!-/){	# end if new expression
				$Lfin=1;}
			    elsif ($Lok){
				$_=~s/^CC\s+//;
				$loci.="$_"." ";}
			    last if ($Lfin);}close($fhinLoc);
	if (length($loci)<5){
	    next;}
	$loci=~s/\t+/\s/g; 
	if ($LverbLoc){print $fhoutLoc "--- '$regexpLoc' in $fileTmp:$loci\n";}
	$id=$fileTmp;$id=~s/^.*\///g;$id=~s/\n|\s//g;
	$tmp="$loci"."\t"."$id";
	push(@finLoc,"$tmp");}
    return(@finLoc);
}				# end of swissGetLocation

#===============================================================================
sub swissGetRegexp {
    local ($fileLoc,$regexpLoc) = @_ ;
    local($sbrName,$fhinLoc,@outLoc);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   swissGetregexp              searches in SWISS-PROT file for regular expression           
#       in:                     file name
#       out:                    @lines_with_expression
#--------------------------------------------------------------------------------
    $sbrName="swissGetregexp";$fhinLoc="FHIN"."$sbrName";
    &open_file("$fhinLoc", "$fileLoc");
    while (<$fhinLoc>) {
	$_=~s/\n//g;
	if (/$regexpLoc/){
	    push(@outLoc,$_);}}close($fhinLoc);
    if ($#outLoc>0){
	return(@outLoc);}
    else {
	return(0);}
}				# end of swissGetRegexp

#===============================================================================
sub swissRdSeq {
    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc,$msg,$Lok,$seq,$id);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   swissRdSeq                  reads the sequence from a SWISS-PROT file
#       in:                     file
#       out:                    (1,name,sequence in one string)
#-------------------------------------------------------------------------------
    $sbrName="swissRdSeq";$fhinLoc="FHIN"."$sbrName";

    $Lok=       &open_file("$fhinLoc","$fileInLoc");
    if (! $Lok){$msg="*** ERROR $sbrName: '$fileInLoc' not opened\n";
		return(0,$msg,"error");}
    $seq="";
    while (<$fhinLoc>) {$_=~s/\n//g;
			if ($_=~/^ID\s+(\S*)\s*.*$/){
			    $id=$1;}
			last if ($_=~/^\/\//);
			next if ($_=~/^[A-Z]/);
			$seq.="$_";}close($fhinLoc);
    $seq=~s/\s//g;
    return(1,$id,$seq);
}				# end of swissRdSeq

#===============================================================================
sub topitsWrtOwn {
    local($fileHsspLoc,$fileStripLoc,$fileOutLoc,$mix,$fhErrSbr) = @_ ;
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok,$txt,$kwd,$it,$wrtTmp,$wrtTmp2,
	  %rdHdr,@kwdLoc,@kwdOutTop2,@kwdOutSummary2,%wrtLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   topitsWrtOwn                writes the TOPITS format
#       in:                     $fileHsspLoc,$fileStripLoc,$fileOutLoc,$mix,$fhErrSbr
#       out:                    file written ($fileOutLoc)
#       err:                    ok=(1,'ok'), err=(0,'msg')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."topitsWrtOwn";
    $fhinLoc= "FHIN". "$sbrName";
    $fhoutLoc="FHOUT"."$sbrName";
    $sep="\t";
				# ------------------------------
				# check arguments
    return(0,"*** $sbrName: not def fileHsspLoc!")          if (! defined $fileHsspLoc);
    return(0,"*** $sbrName: not def fileStripLoc!")         if (! defined $fileStripLoc);
    return(0,"*** $sbrName: not def fileOutLoc!")           if (! defined $fileOutLoc);
    $fhErrSbr="STDOUT"                                      if (! defined $fhErrSbr);
    return(0,"*** $sbrName: miss in file '$fileHsspLoc'!")  if (! -e $fileHsspLoc);
    return(0,"*** $sbrName: miss in file '$fileStripLoc'!") if (! -e $fileStripLoc);
    @kwdOutTop2=
	("len1","nali","listName","sortMode","weight1","weight2",
	 "smin","smax","gapOpen","gapElon","indel1","indel2","threshold");
    @kwdOutSummary2=
	("id2","pide","lali","ngap","lgap","len2",
	 "Eali","Zali","strh","ifir","ilas","jfir","jlas","name");
				# ------------------------------
				# set up keywords
    @kwdLoc=
	 (
	  "hsspTop",   "threshold","len1",
	  "hsspPair",  "id2","pdbid2","pide","ifir","ilas","jfir","jlas",
	               "lali","ngap","lgap","len2",
	  "stripTop",  "nali","listName","sortMode","weight1","weight2",
	               "smin","smax","gapOpen","gapElon","indel1","indel2",
	  "stripPair", "energy","zscore","strh","name");

    $des_expl{"mix"}=      "weight structure:sequence";
    $des_expl{"nali"}=     "number of alignments in file";
    $des_expl{"listName"}= "fold library used for threading";
    $des_expl{"sortMode"}= "mode of ranking the hits";
    $des_expl{"weight1"}=  "YES if guide sequence weighted by residue conservation";
    $des_expl{"weight2"}=  "YES if aligned sequence weighted by residue conservation";
    $des_expl{"smin"}=     "minimal value of alignment metric";
    $des_expl{"smax"}=     "maximal value of alignment metric";
    $des_expl{"gapOpen"}=  "gap open penalty";
    $des_expl{"gapElon"}=  "gap elongation penalty";
    $des_expl{"indel1"}=   "YES if insertions in sec str regions allowed for guide seq";
    $des_expl{"indel2"}=   "YES if insertions in sec str regions allowed for aligned seq";
    $des_expl{"len1"}=     "length of search sequence, i.e., your protein";
    $des_expl{"threshold"}="hits above this threshold included (ALL means no threshold)";

    $des_expl{"rank"}=     "rank in alignment list, sorted according to sortMode";
    $des_expl{"Eali"}=     "alignment score";
    $des_expl{"Zali"}=     "alignment zcore;  note: hits with z>3 more reliable";
    $des_expl{"strh"}=     "secondary str identity between guide and aligned protein";
    $des_expl{"pide"}=     "percentage of pairwise sequence identity";
    $des_expl{"lali"}=     "length of alignment";
    $des_expl{"lgap"}=     "number of residues inserted";
    $des_expl{"ngap"}=     "number of insertions";
    $des_expl{"len2"}=     "length of aligned protein structure";
    $des_expl{"id2"}=      "PDB identifier of aligned structure (1pdbC -> C = chain id)";
    $des_expl{"name"}=     "name of aligned protein structure";
    $des_expl{"ifir"}=     "position of first residue of search sequence";
    $des_expl{"ilas"}=     "position of last residue of search sequence";
    $des_expl{"jfir"}=     "pos of first res of remote homologue (e.g. DSSP number)";
    $des_expl{"jlas"}=     "pos of last res of remote homologue  (e.g. DSSP number)";
    $des_expl{""}=    "";

				# ------------------------------
    undef %rdHdr;		# read HSSP + STRIP header

    ($Lok,$txt,%rdHdr)=
	  &hsspRdStripAndHeader($fileHsspLoc,$fileStripLoc,$fhErrSbr,@kwdLoc);
    return(0,"$sbrName: returned 0\n$txt\n") if (! $Lok);
				# ------------------------------
				# write output in TOPITS format
    $Lok=&open_file("$fhoutLoc",">$fileOutLoc"); 
    return(0,"$sbrName: couldnt open new file $fileOut") if (! $Lok);
				# corrections
    $rdHdr{"threshold"}=~s/according to\s*\:\s*//g if (defined $rdHdr{"threshold"});
    foreach $it (1..$rdHdr{"NROWS"}){
	$rdHdr{"Eali","$it"}=$rdHdr{"energy","$it"} if (defined $rdHdr{"energy","$it"});
	$rdHdr{"Zali","$it"}=$rdHdr{"zscore","$it"} if (defined $rdHdr{"zscore","$it"});
    }
#    $rdHdr{"name","$it"}=$rdHdr{"zscore","$it"} if (defined $rdHdr{"zscore","$it"});
				# ------------------------------
    $wrtTmp=$wrtTmp2="";	# build up for communication with subroutine
    undef %wrtLoc;
    foreach $kwd(@kwdOutTop2){
	$wrtLoc{"$kwd"}=       $rdHdr{"$kwd"};
	$wrtLoc{"expl"."$kwd"}=$des_expl{"$kwd"};$wrtTmp.="$kwd,";}
    if (defined $mix && $mix ne "unk" && length($mix)>1){
	$kwd="mix";
	$wrtLoc{"$kwd"}=       $mix;
	$wrtLoc{"expl"."$kwd"}=$des_expl{"$kwd"};$wrtTmp.="$kwd,";}
    foreach $kwd(@kwdOutSummary2){
	$wrtLoc{"expl"."$kwd"}=$des_expl{"$kwd"};$wrtTmp2.="$kwd,";}
				# ------------------------------
				# write header
    ($Lok,$txt)=
	&topitsWrtOwnHdr($fhoutLoc,$wrtTmp,$wrtTmp2,%wrtLoc);
    undef %wrtLoc;
				# ------------------------------
				# write names of first block
    print $fhoutLoc 
	"# BLOCK    TOPITS HEADER: SUMMARY\n";
    printf $fhoutLoc "%-s","rank";
    foreach $kwd(@kwdOutSummary2){
#	$sepTmp="\n" if ($kwd eq $kwdOutTop2[$#kwdOutTop2]);
	printf $fhoutLoc "$sep%-s",$kwd;}
    print $fhoutLoc "\n";
				# ------------------------------
				# write first block of data
    foreach $it (1..$rdHdr{"NROWS"}){
	printf $fhoutLoc "%-s",$it;
	foreach $kwd(@kwdOutSummary2){
	    printf $fhoutLoc "$sep%-s",$rdHdr{"$kwd","$it"};}
	print $fhoutLoc "\n";
    }
				# ------------------------------
				# next block (ali)
#    print $fhoutLoc
#	"# --------------------------------------------------------------------------------\n",
#	;
				# ------------------------------
				# correct file end
    print $fhoutLoc "//\n";
    close($fhoutLoc);
    undef %rdHdr;		# read HSSP + STRIP header
    return(1,"ok $sbrName");
}				# end of topitsWrtOwn

#===============================================================================
sub topitsWrtOwnHdr {
    local($fhoutTmp,$desLoc,$desLoc2,%wrtLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   topitsWrtOwnHdr             writes the HEADER for the TOPITS specific format
#       in:                     FHOUT,"kwd1,kwd2,kwd3",%wrtLoc
#                               $wrtLoc{"$kwd"}=result of paramter
#                               $wrtLoc{"expl$kwd"}=explanation of paramter
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";$sbrName="$tmp"."topitsWrtOwnHdr";
				# ------------------------------
				# keywords to write
    $desLoc=~s/^,*|,*$//g;      $desLoc2=~s/^,*|,*$//g;
    @kwdHdr=split(/,/,$desLoc); @kwdCol=split(/,/,$desLoc2);
    
				# ------------------------------
				# begin
    print $fhoutTmp
	"# TOPITS (Threading One-D Predictions Into Three-D Structures)\n",
	"# --------------------------------------------------------------------------------\n",
	"# FORMAT   begin\n",
	"# FORMAT   general:    - lines starting with hashes contain comments or PARAMETERS\n",
	"# FORMAT   general:    - columns are delimited by tabs\n",
	"# FORMAT   general:    - the data are given in BLOCKS, each introduced by a line\n",
	"# FORMAT   general:      beginning with a hash and a keyword\n",
	"# FORMAT   parameters: '# PARA:tab     keyword =tab value tab (further-information)'\n",
	"# FORMAT   notation:   '# NOTATION:tab keyword tab explanation'\n",
	"# FORMAT   info:       '# INFO:tab     text'\n",
	"# FORMAT   blocks 0:   '# BLOCK        keyword'\n",
	"# FORMAT   blocks 1:    column names (tab delimited)\n",
	"# FORMAT   blocks n>1:  column data  (tab delimited)\n",
	"# FORMAT   file end:   '//' marks the end of a complete file\n",
	"# FORMAT   end\n",
	"# --------------------------------------------------------------------------------\n";
				# ------------------------------
				# write parameters
    print $fhoutTmp
	"# PARA     begin\n",
	"# PARA     TOPITS HEADER: PARAMETERS\n";
    foreach $des (@kwdHdr){
	next if (! defined $wrtLoc{"$des"});
	$tmp1=$wrtLoc{"expl"."$des"};$tmp2=length($tmp1);$tmp="$tmp2"."s";
	$wrtLoc{"$des"}=~s/\s//g; # purge blanks
	if ($des eq "mix"){
	    $mix=~s/\D//g;
	    printf $fhoutTmp 
		"# PARA:\t%-10s =\t%-6d\t(i.e. str=%3d%1s, seq=%3d%1s)\n",
		"str:seq",int($mix),int($mix),"%",int(100-$mix),"%";}
	else {
	    printf $fhoutTmp 
		"# PARA:\t%-10s =\t%-6s\n",$des,$wrtLoc{"$des"};}}
    print $fhoutTmp
	"# PARA     end\n",
	"# --------------------------------------------------------------------------------\n";
				# ------------------------------
				# explanations
    print $fhoutTmp
	"# NOTATION begin\n",
	"# NOTATION TOPITS HEADER: ABBREVIATIONS PARAMETERS\n";
    foreach $des (@kwdHdr){
	$tmp1=$wrtLoc{"expl"."$des"};$tmp2=length($tmp1);$tmp="$tmp2"."s";
	$tmp=length($wrtLoc{"expl"."$des"});$tmp.="s";
	$des2=$des;  # $des2=~tr/[a-z]/[A-Z]/;
	$des2="str:seq" if ($des2 eq "mix");
	printf $fhoutTmp "# NOTATION:\t%-12s:\t%-$tmp\n",$des2,$tmp1;}
    print $fhoutTmp
	"# NOTATION TOPITS HEADER: ABBREVIATIONS SUMMARY\n";
    foreach $des (@kwdCol){
	$tmp1=$wrtLoc{"expl"."$des"};$tmp2=length($tmp1);$tmp="$tmp2"."s";
	$tmp=length($wrtLoc{"expl"."$des"});$tmp.="s";
	$des2=$des;  # $des2=~tr/[a-z]/[A-Z]/;
	printf $fhoutTmp "# NOTATION:\t%-12s:\t%-$tmp\n",$des2,$tmp1;}
	
    print $fhoutTmp
	"# NOTATION end\n",
	"# --------------------------------------------------------------------------------\n";
				# ------------------------------
				# information about method
    print $fhoutTmp 
	"# INFO     begin\n",
	"# INFO     TOPITS HEADER: ACCURACY\n",
	"# INFO:\t Tested on 80 proteins, TOPITS found the correct remote homologue in about\n",
	"# INFO:\t 30%of the cases.  Detection accuracy was higher for higher z-scores:\n",
	"# INFO:\t ZALI>0   => 1st hit correct in 33% of cases\n",
	"# INFO:\t ZALI>3   => 1st hit correct in 50% of cases\n",
	"# INFO:\t ZALI>3.5 => 1st hit correct in 60% of cases\n",
	"# INFO     end\n",
	"# --------------------------------------------------------------------------------\n";
}				# end of topitsWrtOwnHdr

#===============================================================================
sub write80_data_prepdata {
    local ( @data_in) = @_;
    local ( $i);
    $[=1;
#----------------------------------------------------------------------
#   write80_data_prepdata       writes input into array called @write80_data
#----------------------------------------------------------------------
    $#write80_data = 0;
    for ( $i=1; $i <=$#data_in ; $i ++ ) {
	$write80_data[$i] = $data_in[$i];
    }
}				# end of: write80_data_prepare_data

#===============================================================================
sub write80_data_preptext {
    local (@data_in) = @_;
    local ( $i, $it2);
    $[=1;
#----------------------------------------------------------------------
#   write80_data_preptext       writes input into array called @write80_data
#----------------------------------------------------------------------
    $#write80_text = 0;
    for ( $i=1; $i <= $#data_in ; $i ++ ) {
	$write80_text[$i] = $data_in[$i];
    }
}				# end of: write80_data_prepare_data

#===============================================================================
sub write80_data_do {
    local ( $fh_out) = @_;
    local ( $seq_intmp, $i, $it2);
    $[=1;

#----------------------------------------------------------------------
#   write80_data_do             writes hssp seq + sec str + exposure
#                               (projected onto 1 digit) into 
#                               file with 80 characters per line
#----------------------------------------------------------------------
    $seq_intmp =  "$write80_data[1]";
    $seq_intmp =~ s/\s//g;
    if ( length($seq_intmp) != length($write80_data[1]) ) {
	print "*** ERROR in write_hssp_..: passed: sequence with spaces! \n";
	print "*** in: \t |$write80_data[1]| \n";
	exit;}

    for( $i=1; $i <= length($seq_intmp) ; $i += 80 ) {
	&myprt_points80 ($i);	
	print $fh_out "    $myprt_points80 \n";
	for ( $it2=1; $it2<=$#write80_data; $it2 ++) {
	    print $fh_out 
		"$write80_text[$it2]", "|", substr($write80_data[$it2],$i,80), "|\n";}}
}				# end of: write80_data_do

#===============================================================================
sub write_pir {
    local ($name,$seq,$file_handle,$seq_char_per_line) = @_;
    local ($i);
    $[=1;
#--------------------------------------------------
#   write_pir                   writes protein into PIR format
#--------------------------------------------------
    if ( length($seq_char_per_line) == 0 ) { $seq_char_per_line = 80; }
    if ( length($file_handle) == 0 ) { $file_handle = "STDOUT"; }

    print $file_handle ">P1\; \n"; print $file_handle "$name \n";
    for ( $i=1; $i < length($seq) ;$i += $seq_char_per_line){
	print $file_handle substr($seq,$i,$seq_char_per_line), "\n";}
}				# end of write_pir

#===============================================================================
sub write_rdb_header {
    local ($fh, @header) = @_ ;
    local ($i, $i2, @atmp, $Lisformat,@loc);

#----------------------------------------------------------------------
#   write_rdb_header            writes a header for an RDB file
#       in:                     $fhin,@header
#            @header=           'text1','text2',..,'
#                               col_name:col1,col2,coln','col_format:format1,format2')
#       out:                    header printed into fh
#                               @RDB_FORMAT
#       NOTE:                   format: 1N=I1; 1=A1; 3.2F=fortran format
#       GLOBAL:                 @RDB_FORMAT : automatically made from 'col_format:' line
#
#        out:                   everything into array @header, with:
#            "col_name:"        starting the column names given as: 
#                               "column_name:col1,col2,"
#            "col_format:"      starting the column format given as: 
#                               "column_format:col1,col2,"
#            $fh:               file handle for writing
#----------------------------------------------------------------------
    $[=1 ; 
    $#RDB_FORMAT=0;
#   ------------------------------
#   first line
#   ------------------------------
    print $fh "# Perl-RDB\n", "# \n";

#   --------------------------------------------------
#   loop over others
#   --------------------------------------------------
    for ($i=1;$i<=$#header;++$i) {
        if ( ($header[$i]!~/col_name/)&&($header[$i]!~/col_format/) ) {
            print $fh "# $header[$i]\n";}
	else {
            if ($header[$i]=~/col_format/) { $Lisformat=1;} else {$Lisformat=0;}
            $header[$i]=~s/col_format:|col_name://g;
            @atmp=split(/,/,$header[$i]);
            foreach $i2(@atmp) { print $fh "$i2\t"; } print $fh "\n";

            if ($Lisformat) {
                for ($i2=1;$i2<=$#atmp;++$i2) {
                    if ($atmp[$i2]=~/N/) {
                        $RDB_FORMAT[$i2]="%"."$atmp[$i2]"."d";$RDB_FORMAT[$i2]=~s/N//g;
                    } elsif ($atmp[$i2]=~/F/) {
                        $tw=$atmp[$i2];$tw=~s/(.+)\..*F/$1/g;
                        $tp=$atmp[$i2];$tp=~s/.+\.(.+)F/$1/g;
                        $RDB_FORMAT[$i2]="%"."$tw"."."."$tp"."f";
                    } else {
                        $RDB_FORMAT[$i2]="%-"."$atmp[$i2]"."s";
                    }}}}}
    @loc=@RDB_FORMAT;
    return(@loc);
}				# end of write_rdb_header

#===============================================================================
sub write_rdb_line {
    local ($fh, @data) = @_ ;
    local ($i,@dataLoc);
    $[=1 ; 
#----------------------------------------------------------------------
#   write_rdb_line              writes one line of an RDB file
#       in:                     everything into array @data
#         $fh:                  file handle for writing
#                               NOTE: pass " " as "space"
#       out GLOBAL:             @RDB_FORMAT   (passed from calling program)
#                               if string (=       n) 
#                                  -> printf %-ns, i.e. start with 1st character
#----------------------------------------------------------------------
    $LisFormat=$#dataLoc=0;
    foreach $_(@data){
	if    (/^format/){$#RDB_FORMAT=0;$LisFormat=1;}
	elsif (/^body/)  {$LisFormat=0;}
	elsif ($LisFormat){push(@RDB_FORMAT,$_);}
	else {push(@dataLoc,$_);}}
    @data=@dataLoc;
    for ($i=1;$i<=$#data;++$i) {
	$data[$i]=~s/\t$//g;
	if ($data[$i]=~/^space|^SPACE/){
	    print $fh " ";}
	else {
	    if (!defined $RDB_FORMAT[$i]){print $fh $data[$i];}
	    else {printf $fh "$RDB_FORMAT[$i]",$data[$i];}}
	if ($i==$#data) { printf $fh "\n";} else {printf $fh "\t";}
    }
}				# end of write_rdb_line

#===============================================================================
sub wrt_dssp_phd {
    local ($fhoutLoc,$id_in)=@_;
    local ($it);
    $[ =1 ;
#----------------------------------------------------------------------
#   wrt_dssp_phd                writes DSSP format for
#       in:                     $fhoutLoc,$id_in
#       in GLOBAL:              @NUM, @SEQ, @SEC(HE ), @ACC, @RISEC, @RIACC
#       out:                    1 if ok
#----------------------------------------------------------------------
    print $fhoutLoc 
	"**** SECONDARY STRUCTURE DEFINITION BY THE PROGRAM DSSP, here PHD prediction\n",
	"REFERENCE  ROST & SANDER,PROTEINS,19,1994,55-72; ".
	    "ROST & SANDER,PROTEINS,20,1994,216-26\n",
	    "HEADER     $id_in \n",
	    "COMPND        \n",
	    "SOURCE        \n",
	    "AUTHOR        \n",
	    "  \#  RESIDUE AA STRUCTURE BP1 BP2  ACC   N-H-->O  ".
		"O-->H-N  N-H-->O  O-->H-N    TCO  KAPPA ALPHA  PHI   ".
		    "PSI    X-CA   Y-CA   Z-CA  \n";
				# for security
    if (! defined $CHAIN){$CHAIN=" ";}
    for ($it=1; $it<=$#NUM; ++$it) {
	printf $fhoutLoc 
	    " %4d %4d %1s %1s  %1s           0   0  %3d    %1d  %1d\n",
	    $NUM[$it], $NUM[$it], $CHAIN, $SEQ[$it], $SEC[$it], 
	    $ACC[$it], $RISEC[$it], $RIACC[$it];}
    return(1);
}				# end wrt_dssp_phd

#===============================================================================
sub wrt_msf {
    local ($file_out,@string) = @_ ;
    $[ =1 ;
#--------------------------------------------------------------------------------
#   wrt_msf                     writing an MSF formatted file of aligned strings
#         in:                   $file_msf,@string,
#                               where file_msf is the name of the output MSF file,
#                               and @string contains all strings to be used (to pass
#                               the names, use first: des=name1, des=name2, string1, string2
#--------------------------------------------------------------------------------
    $fhout="FHOUT_WRT_MSF";
    $#name=$#tmp=0;
    foreach $it (1..$#string){
	if ($string[$it]=~ /des=/){
	    $string[$it]=~s/des=//g; push(@name,$string[$it]); }
	else {
	    push(@tmp,$string[$it]);}}
    if ($#name>1) {@string=@tmp;}
    else          {$#name=0;
		   foreach $it(1..$#string){$tmp="seq"."$it";
					    push(@name,$tmp);} }

    &open_file("$fhout",">$file_out");
    print $fhout 
	"MSF of: 1ppt.hssp from:    1 to:   ",length($string[1])," \n",
	"$file_out MSF: ",length($string[1]),
	"  Type: N  November 09, 1918 14:00 Check: 1933 ..\n \n \n";
    foreach $it (1..$#string){
	printf 
	    $fhout "Name: %-20s Len: %-5d Check: 2222 Weight: 1.00\n",
	    $name[$it],length($string[$it]); }
    print $fhout " \n//\n \n";
    for($it=1;$it<=length($string[1]);$it+=50){
	foreach $it2 (1..$#string){
	    printf 
		$fhout "%-20s %-10s %-10s %-10s %-10s %-10s\n",$name[$it2],
		substr($string[$it2],$it,10),substr($string[$it2],($it+10),10),
		substr($string[$it2],($it+20),10),substr($string[$it2],($it+30),10),
		substr($string[$it2],($it+40),10); }
	print $fhout "\n"; }
    print $fhout "\n";
    close($fhout);
}				# end of wrt_msf

#===============================================================================
sub wrt_phd_header2pp {
    local ($file_out) = @_ ;
    local ($fhout,$header,@header);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   wrt_phd_header2pp           header for phd2pp
#       in:                     $file_out, i.e. file to write header to
#       out:                    @header
#-------------------------------------------------------------------------------
    $#header=0;
    push(@header,
	 "--- \n",
	 "--- ------------------------------------------------------------\n",
	 "--- PHD  profile based neural network predictions \n",
	 "--- ------------------------------------------------------------\n",
	 "--- \n");
    if ( (defined $file_out) && ($file_out ne "STDOUT") ) {
	$fhout="FHOUT_PHD_HEADER2PP";
	open($fhout, ">$file_out") || warn "Can't open '$file_out' (wrt_phd_header2pp)\n"; 
	foreach $header(@header){
	    print $fhout "$header";}
	close($fhout);}
    else {
	return(@header);}
}				# end of wrt_phd_header2pp

#===============================================================================
sub wrt_phd_rdb2col {
    local ($file_out,%rdrdb) = @_ ;
    local (@des,@des2,$fhout,$itdes,$it,%string,$subsec,$subacc,$points,
	   $des,$desout,$tmp,$tmpf,$dessec,$desacc,%Lok);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    wrt_phd_rdb2col             writes out the PP send format
#--------------------------------------------------------------------------------
    @des= ("AA","PSEC","RI_S","pH","pE","pL","PACC","PREL","RI_A","Pbie");
                                # ----------------------------------------
                                # first converting OtH (output) to prH (probability)
                                # ----------------------------------------
    $Lis_E=$Lis_H=0;
    foreach $it (1..$rdrdb{"NROWS"}){
	if (defined $rdrdb{"pH","$it"}) { $pH=$rdrdb{"pH","$it"}; $Lis_H=1;} else {$pH=0;}
	if (defined $rdrdb{"pE","$it"}) { $pE=$rdrdb{"pE","$it"}; $Lis_E=1;} else {$pE=0;}
	if (defined $rdrdb{"pL","$it"}) { $pL=$rdrdb{"pL","$it"}; }          else {$pL=0;}
	$sum=$pH+$pE+$pL; 
	if ($sum>0){
	    ($rdrdb{"pH","$it"},$tmp)=&get_min(9,int(10*$pH/$sum));
	    ($rdrdb{"pE","$it"},$tmp)=&get_min(9,int(10*$pE/$sum));
	    ($rdrdb{"pL","$it"},$tmp)=&get_min(9,int(10*$pL/$sum)); }
	else {
	    $rdrdb{"pH","$it"}=$rdrdb{"pE","$it"}=$rdrdb{"pL","$it"}=0;}}
    
				# ------------------------------
				# check whether or not all there
    foreach $des (@des) {
	if (defined $rdrdb{"$des","1"}) {$Lok{"$des"}=1;}
	else {$Lok{"$des"}=0;} }

    $fhout="FHOUT_PHD_RDB2COL";
    open($fhout, ">$file_out") || warn "Can't open '$file_out' (wrt_phd_rdb2col)\n"; 
				# ------------------------------
				# header
    print $fhout "--- \n";
    print $fhout "--- PHD PREDICTION COLUMN FORMAT HEADER: ABBREVIATIONS\n";
    if ($Lok{"AA"}){
	printf $fhout "--- %-10s: %-s\n","AA","one-letter code for amino acid sequence"; }
    if ($Lok{"PSEC"}){
	printf $fhout "--- %-10s: %-s\n","PSEC","secondary structure prediction in 3 states:";
	printf $fhout "--- %-10s: %-s\n","    ","H=helix, E=extended (sheet), L=rest (loop)";
	printf $fhout "--- %-10s: %-s\n","RI_S","reliability of secondary structure prediction";
	printf $fhout "--- %-10s: %-s\n","    ","scaled from 0 (low) to 9 (high)";
	printf $fhout "--- %-10s: %-s\n","pH  ","'probability' for assigning helix";
	printf $fhout "--- %-10s: %-s\n","pE  ","'probability' for assigning strand";
	printf $fhout "--- %-10s: %-s\n","pL  ","'probability' for assigning rest";
	printf $fhout "--- %-10s: %-s\n","       ",
	"Note:   the 'probabilities' are scaled onto 0-9,";
	printf $fhout "--- %-10s: %-s\n","       ",
	"        i.e., prH=5 means that the value of the";
	printf $fhout "--- %-10s: %-s\n","       ","        first output unit is 0.5-0.6"; }
	
    if ($Lok{"PACC"}){
	printf $fhout "--- %-10s: %-s\n","PACC",
	"predicted solvent accessibility in square Angstrom";
	printf $fhout "--- %-10s: %-s\n","PREL","relative solvent accessibility in percent";
	printf $fhout "--- %-10s: %-s\n","RI_A","reliability of accessibility prediction (0-9)";
	printf $fhout "--- %-10s: %-s\n","Pbie","predicted relative accessibility in 3 states:";
	printf $fhout "--- %-10s: %-s\n","       ","b=0-9%, i=9-36%, e=36-100%"; }

    print $fhout "--- \n","--- PHD PREDICTION COLUMN FORMAT \n";
				# --------------------------------------------------
				# now the prediction in 60 per line
				# --------------------------------------------------
    printf $fhout "%4s","No"; 
    foreach $des (@des){
	if ($Lok{"$des"}) { printf $fhout "%4s ",$des;} }
    print $fhout "\n"; 
    foreach $it (1..$rdrdb{"NROWS"}){
	printf $fhout "%4d",$it;
	foreach $des (@des){
	    if ($Lok{"$des"}) { printf $fhout "%4s ",$rdrdb{"$des","$it"}; } }
	print $fhout "\n" }
    print $fhout "--- \n","--- PHD PREDICTION COLUMN FORMAT END\n","--- \n";
    close($fhout);
}				# end of wrt_phd_rdb2col

#===============================================================================
sub wrt_phd_rdb2pp {
    local ($file_out,$cut_subsec,$cut_subacc,$sub_symbol,%rdrdb) = @_ ;
    local (@des,@des2,$fhout,$itdes,$it,%string,$subsec,$subacc,$points,
	   $des,$desout,$tmp,$tmpf,$dessec,$desacc);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    wrt_phd_rdb2pp             writes out the PP send format
#--------------------------------------------------------------------------------
    @des= ("AA","PHEL","RI_S","OtH","OtE","OtL","PACC","PREL","RI_A","Pbie");
    @des2=("AA","PHD", "Rel", "prH","prE","prL","PACC","PREL","RI_A","Pbie");

    $fhout="FHOUT_PHD_RDB2PP";
    open($fhout, ">$file_out") || warn "Can't open '$file_out' (wrt_phd_rdb2pp)\n"; 
				# ------------------------------
				# header
    @header=&wrt_phd_header2pp();
    foreach $header(@header){
	print $fhout "$header"; }
    print $fhout "--- PHD PREDICTION HEADER: ABBREVIATIONS\n";
    printf $fhout "--- %-10s: %-s\n","AA","one-letter code for amino acid sequence";
    printf $fhout "--- %-10s: %-s\n","PHD sec","secondary structure prediction in 3 states:";
    printf $fhout "--- %-10s: %-s\n","       ","H=helix, E=extended (sheet), blank=rest (loop)";
    printf $fhout "--- %-10s: %-s\n","Rel sec","reliability of secondary structure prediction";
    printf $fhout "--- %-10s: %-s\n","SUB sec","subset of residues for which the reliability";
    printf $fhout "--- %-10s: %-s\n","       ","index (Rel sec) is >= 5";
    printf $fhout "--- %-10s: %-s\n","       ","Note 1: this corresponds to an expected pre-";
    printf $fhout "--- %-10s: %-s\n","       ","        diction accuracy > 82% ";
    printf $fhout "--- %-10s: %-s\n","       ","Note 2: 'L': is loop (for which above ' ' is used)";
    printf $fhout "--- %-10s: %-s\n","       ","        '.': means no prediction is made for this";
    printf $fhout "--- %-10s: %-s\n","       ","             residue, i.e., Rel sec < 5";
    printf $fhout "--- %-10s: %-s\n","prH sec","'probability' for assigning helix";
    printf $fhout "--- %-10s: %-s\n","prE sec","'probability' for assigning strand";
    printf $fhout "--- %-10s: %-s\n","prL sec","'probability' for assigning rest";
    printf $fhout "--- %-10s: %-s\n","       ","Note:   the 'probabilities' are scaled onto 0-9,";
    printf $fhout "--- %-10s: %-s\n","       ","        i.e., prH=5 means that the value of the";
    printf $fhout "--- %-10s: %-s\n","       ","        first output unit is 0.5-0.6";
    printf $fhout "--- %-10s: %-s\n","P_3 acc","predicted relative accessibility in 3 states:";
    printf $fhout "--- %-10s: %-s\n","       ","b=0-9%, blank=9-36%, e=36-100%";
    printf $fhout "--- %-10s: %-s\n","PHD acc","predicted solvent accessibility in 10 states:";
    printf $fhout "--- %-10s: %-s\n","       ","acc=n implies a relative accessibility of n*n%";
    printf $fhout "--- %-10s: %-s\n","Rel acc","reliability of accessibility prediction (0-9)";
    printf $fhout "--- %-10s: %-s\n","SUB acc","subset of residues for which the reliability";
    printf $fhout "--- %-10s: %-s\n","       ","index (Rel acc) is >= 4";
    printf $fhout "--- %-10s: %-s\n","       ","Note 1: this corresponds to an expected corre-";
    printf $fhout "--- %-10s: %-s\n","       ","        lation coeeficient > 0.69 ";
    printf $fhout "--- %-10s: %-s\n","       ","Note 2: 'I': is intermediate (for which above a";
    printf $fhout "--- %-10s: %-s\n","       ","             blank ' ' is used)";
    printf $fhout "--- %-10s: %-s\n","       ","        '.': means no prediction is made for this";
    printf $fhout "--- %-10s: %-s\n","       ","             residue, i.e., Rel acc < 4";
    printf $fhout "--- %-10s: %-s\n","       ","";
    printf $fhout "--- %-10s: %-s\n","       ","";
    print $fhout "--- \n";
    print $fhout "--- PHD PREDICTION \n";
                                # ----------------------------------------
                                # first converting OtH (output) to prH (probability)
                                # ----------------------------------------
    foreach $it (1..$rdrdb{"NROWS"}){
	$sum=$rdrdb{"OtH","$it"}+$rdrdb{"OtE","$it"}+$rdrdb{"OtL","$it"};
	($rdrdb{"prH","$it"},$tmp)=&get_min(9,int(10*$rdrdb{"OtH","$it"}/$sum));
	($rdrdb{"prE","$it"},$tmp)=&get_min(9,int(10*$rdrdb{"OtE","$it"}/$sum));
	($rdrdb{"prL","$it"},$tmp)=&get_min(9,int(10*$rdrdb{"OtL","$it"}/$sum));
    }
				# --------------------------------------------------
				# now the prediction in 60 per line
				# --------------------------------------------------
    foreach $itdes (1..$#des){
	$string{"$des2[$itdes]"}="";
	foreach $it (1..$rdrdb{"NROWS"}){
	    if   ($des[$itdes]=~/PREL/){
		$string{"$des2[$itdes]"}.=
		    &exposure_project_1digit($rdrdb{"$des[$itdes]","$it"}); }
	    elsif($des[$itdes]=~/Ot/) {
		$desout=$des[$itdes];$desout=~s/Ot/pr/;
		$string{"$desout"}.=$rdrdb{"$desout","$it"}; }
	    else {
		$string{"$des2[$itdes]"}.=$rdrdb{"$des[$itdes]","$it"}; }
	}
    }
				# correct symbols
    $string{"PHD"}=~s/L/ /g;
    $string{"PSEC"}=~s/L/ /g;
    $string{"Pbie"}=~s/i/ /g;
				# select subsets
    $subsec=$subacc="";
    foreach $it (1..$rdrdb{"NROWS"}){
				# sec
	if ($rdrdb{"RI_S","$it"}>$cut_subsec){$subsec.=$rdrdb{"PSEC","$it"};}
	else{$subsec.="$sub_symbol";}
				# acc
	if ($rdrdb{"RI_A","$it"}>$cut_subacc){$subacc.=$rdrdb{"Pbie","$it"};}
	else {$subacc.="$sub_symbol";}
    }

    $tmp=$string{"AA"};$nres=length($tmp); # length

    for($it=1;$it<=$nres;$it+=60){
	$points=&myprt_npoints (60,$it);	
	printf $fhout "%-16s  %-60s\n"," ",$points;
				# residues
	$des="AA";$desout="AA     ";
	$tmp=substr($string{"$des"},$it,60);$tmpf=length($tmp)."s";
	printf $fhout "%8s %-6s |%-$tmpf|\n"," ","$desout",$tmp;
				# secondary structure
	foreach $dessec("PHD","Rel","prH","prE","prL"){
	    $desout="$dessec sec ";
	    $tmp=substr($string{"$dessec"},$it,60);$tmpf=length($tmp)."s";
	    printf $fhout "%8s %-6s|%-$tmpf|\n"," ","$desout",$tmp;
	    if ($dessec=~/Rel/){
		printf $fhout " detail:\n";
	    }
	}
	printf $fhout "%15s|%-$tmpf|\n"," subset: SUB sec ",$tmp;
	printf $fhout " \n";
				# accessibility
	printf $fhout " ACCESSIBILITY\n";
	foreach $desacc("Pbie","PREL","RI_A"){
	    if ($desacc=~/Pbie/)   {$desout=" 3st:    P_3 acc ";}
	    elsif ($desacc=~/PREL/){$desout=" 10st:   PHD acc ";}
	    elsif ($desacc=~/RI_A/){$desout="         Rel acc ";}
	    $tmp=substr($string{"$desacc"},$it,60);$tmpf=length($tmp)."s";
	    printf $fhout "%-15s|%-$tmpf|\n","$desout",$tmp; }
	$tmp=substr($subacc,$it,60);$tmpf=length($tmp)."s";
	printf $fhout "%15s|%-$tmpf|\n"," subset: SUB acc ",$tmp;
	printf $fhout " \n";}
    print $fhout "--- \n";
    print $fhout "--- PHD PREDICTION END\n";
    print $fhout "--- \n";
    close($fhout);
}				# end of wrt_phd_rdb2pp

#===============================================================================
sub wrt_phd2msf {
    local ($fileHssp,$fileMsfTmp,$filePhdRdb,$fileOut,$exeConvSeq,$LoptExpand,
	   $exePhd2Msf,$riSecLoc,$riAccLoc,$riSymLoc,$charPerLine,$Lscreen,$Lscreen2) = @_ ;
#    local ($fileLog);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   wrt_phd2msf                 converts HSSP to MSF and merges the PHD prediction
#                               into the MSF file (Pred + Ali)
#       in:                     * existing HSSP file, 
#                               * to be written temporary MSF file (hssp->MSF)
#                               * existing PHD.rdb_phd file
#                               * name of output file (id.msf_phd)
#                               * executables for converting HSSP to MSF (fortran convert_seq)
#                               * $Lexpand =1 means insertions in HSSP will be filled in
#                               * perl hack to convert id.rdb_phd + id.msf to id.msf_phd
#                               * reliability index to choose SUBSET for secondary structure
#                                 prediction (taken: > riSecLoc)
#                               * reliability index for SUBacc
#                               * character used to mark regions with ri <= riSecLoc
#                               * number of characters per line of MSF file
#       out:                    writes file and reports status (0,$text), or (1," ")
#--------------------------------------------------------------------------------
				# ------------------------------
				# security checks
    if (!-e $fileHssp){
	return(0,"HSSP file '$fileHssp' missing (wrt_phd2msf)");}
    if (!-e $filePhdRdb){
	return(0,"phdRdb file '$filePhdRdb' missing (wrt_phd2msf)");}
    if ($LoptExpand){
	$optExpand="expand";}else{$optExpand=" ";}
				# ------------------------------
				# convert HSSP file to MSF format
    if ($Lscreen){ 
	print "--- wrt_phd2msf \t ";
	print "'\&convHssp2msf($fileHssp,$fileMsfTmp,$exeConvSeq,$optExpand,$Lscreen2)'\n";}
    $Lok=
	&convHssp2msf($fileHssp,$fileMsfTmp,$exeConvSeq,$optExpand,$Lscreen2);
    if (!$Lok){
	return(0,"conversion Hssp2Msf failed '$fileMsfTmp' missing (wrt_phd2msf)");}
				# ------------------------------
				# now merge PHD file into MSF
    $arg=  "$fileMsfTmp filePhd=$filePhdRdb fileOut=$fileOut ";
    $arg.= " riSec=$riSecLoc riAcc=$riAccLoc riSym=$riSymLoc charPerLine=$charPerLine ";
    if ($Lscreen2){$arg.=" verbose ";}else{$arg.=" not_screen ";}

    if ($Lscreen) {print "--- wrt_phd2msf \t 'system ($exePhd2Msf $arg)'\n";}

    system("$exePhd2Msf $arg");
    return(1," ");
}				# end of wrt_phd2msf

#===============================================================================
sub wrt_phdpred_from_string {
    local ($fh,$nres_per_row,$mode,$Ldo_htmref,@des) = @_ ;
    local (@des_loc,@header_loc,$Lheader);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   wrt_phdpred_from_string     write body of PHD.pred files from global array %STRING{}
#       in (GLOBAL)             %STRING, i.e., one line string with prediction,
#                               e.g., $STRING{"osec"} observed secondary structure
#--------------------------------------------------------------------------------
    if (! %STRING) { 
	print "*** ERROR wrt_phdpred_from_string: associative array \%STRING must be global\n";
	exit; }
    $#des_loc=$#header_loc=0;$Lheader=0;
    foreach $des(@des){
	if ($des eq "header"){ 
	    $Lheader=1;
	    next;}
	if (! $Lheader){push(@des_loc,$des);}
	else           {push(@header_loc,$des);}}
				# get length of proteins (number of residues)
    $des= $des_loc[2];		# hopefully always AA!
    $tmp= $STRING{"$des"};
    $nres=length($tmp);
				# --------------------------------------------------
				# now write out for 'both','acc','sec'
				# --------------------------------------------------
    if ($mode=~/3|both|sec|acc/){
	$nres_tmp=$nres;}
    else {
	$nres_tmp=0;}
    for($it=1;$it<=$nres_tmp;$it+=$nres_per_row) {
	print  $fh " \n \n";	# print empty before each PHD block
	$tmp=&myprt_npoints($nres_per_row,$it);
	printf $fh "%-17s %-s\n"," ",$tmp;
	foreach $_ (@des_loc) {
	    next if (! defined $STRING{"$_"});
	    next if (length($STRING{"$_"})<$it);
	    $tmp=substr($STRING{"$_"},$it,$nres_per_row);
	    next if (length($tmp)==0) ;
				# secondary structure
	    if   ($_=~/aa/)    {printf $fh "%8s %-7s |%-s|\n"," ","AA ",$tmp; }
	    elsif($_=~/osec/)  {printf $fh "%8s %-7s |%-s|\n"," ","OBS sec",$tmp; }
	    elsif($_=~/psec/)  {printf $fh "%8s %-7s |%-s|\n"," ","PHD sec",$tmp; }
	    elsif($_=~/risec/) {printf $fh "%8s %-7s |%-s|\n"," ","Rel sec",$tmp; }
	    elsif($_=~/prHsec/){print  $fh " detail: \n";
				printf $fh "%8s %-7s |%-s|\n"," ","prH sec",$tmp; }
	    elsif($_=~/prEsec/){printf $fh "%8s %-7s |%-s|\n"," ","prE sec",$tmp; }
	    elsif($_=~/prLsec/){printf $fh "%8s %-7s |%-s|\n"," ","prL sec",$tmp; }
	    elsif($_=~/subsec/){printf $fh "%-8s %-7s |%-s|\n"," subset:","SUB sec",$tmp;}
				# solvent accessibility
	    elsif($_=~/obie/)  {if($mode=~/both|3/){print $fh " accessibility: \n"; }
				printf $fh "%-8s %-7s |%-s|\n"," 3st:","O_3 acc",$tmp;}
	    elsif($_=~/pbie/)  {if (length($STRING{"obie"})>1){$txt=" ";} 
				else{if($mode=~/both|3/){print $fh " accessibility \n";}
				     $txt=" 3st: ";}
				printf $fh "%-8s %-7s |%-s|\n",$txt,"P_3 acc",$tmp; }
	    elsif($_=~/oacc/)  {printf $fh "%-8s %-7s |%-s|\n"," 10st:","OBS acc",$tmp;}
	    elsif($_=~/pacc/)  {if (length($STRING{"oacc"})>1){$txt=" ";}else{$txt=" 10st: ";}
				printf $fh "%-8s %-7s |%-s|\n",$txt,"PHD acc",$tmp; }
	    elsif($_=~/riacc/) {printf $fh "%8s %-7s |%-s|\n"," ","Rel acc",$tmp; }
	    elsif($_=~/subacc/){printf $fh "%-8s %-7s |%-s|\n"," subset:","SUB acc",$tmp; }
	}
    }
				# --------------------------------------------------
				# now write out for '3','htm'
				# --------------------------------------------------
    if ($mode=~/3|htm/){
	if ($mode=~/3/) {
	    $symh="T";
	    print $fh 
		" \n",
		"************************************************************\n",
		"*    PHDhtm Helical transmembrane prediction\n",
		"*           note: PHDacc and PHDsec are reliable for water-\n",
		"*                 soluble globular proteins, only.  Thus, \n",
		"*                 please take the  predictions above with \n",
		"*                 particular caution wherever transmembrane\n",
		"*                 helices are predicted by PHDhtm!\n",
		"************************************************************\n",
		" \n",
		" PHDhtm\n";
	} else {
	    $symh="H";}
	$nres_tmp=$nres;}
    else {
	$nres_tmp=0;}
				# ------------------------------
				# print header for topology asf
    if ($nres_tmp>0){
	if ($#header_loc>0){
	    &wrt_phdpred_from_string_htm_header($fh,@header_loc);}
	&wrt_phdpred_from_string_htm($fh,$nres_tmp,$nres_per_row,$symh,
				     $Ldo_htmref,@des_loc);}
}				# end of wrt_phdpred_from_string

#===============================================================================
sub wrt_phdpred_from_string_htm {
    local ($fh,$nres_tmp,$nres_per_row,$symh,$Ldo_htmref,@des_loc) = @_ ;
    local ($it,$tmp);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   wrt_phdpred_from_string_htm body of PHD.pred files from global array %STRING{} for HTM
#       in (GLOBAL)             %STRING, i.e., one line string with prediction,
#                               e.g., $STRING{"osec"} observed secondary structure
#--------------------------------------------------------------------------------
    @des=("AA");
    if (defined $STRING{"ohtm"}){
	$tmp=$STRING{"ohtm"}; $tmp=~s/L|\s//g;
	if (length($tmp)==0) {
	    $STRING{"ohtm"}="";}
	else {
	    push(@des,"OBS htm");}}
    push(@des,"PHD htm","Rel htm","detail","prH htm","prL htm",
	      "subset","SUB htm","other","PHDFhtm");
    if (defined $STRING{"prhtm"}){ push(@des,"PHDRhtm");}
    if (defined $STRING{"pthtm"}){ push(@des,"PHDThtm");}
    $sym{"AA"}=     "amino acid in one-letter code";
    $sym{"OBS htm"}="HTM's observed ($symh=HTM, ' '=not HTM)";
    $sym{"PHD htm"}="HTM's predicted by the PHD neural network\n".
	"---                system ($symh=HTM, ' '=not HTM)";
    $sym{"Rel htm"}="Reliability index of prediction (0-9, 0 is low)";
    $sym{"detail"}= "Neural network output in detail";
    $sym{"prH htm"}="'Probability' for assigning a helical trans-\n".
	"---                membrane region (HTM)";
    $sym{"prL htm"}="'Probability' for assigning a non-HTM region\n".
	"---          note: 'Probabilites' are scaled to the interval\n".
	"---                0-9, e.g., prH=5 means, that the first \n".
	"---                output node is 0.5-0.6";
    $sym{"subset"}= "Subset of more reliable predictions";
    $sym{"SUB htm"}="All residues for which the expected average\n".
	"---                accuracy is > 82% (tables in header).\n".
	"---          note: for this subset the following symbols are used:\n".
	"---             L: is loop (for which above ' ' is used)\n".
	"---           '.': means that no prediction is made for this,\n".
	"---                residue as the reliability is:  Rel < 5";
    $sym{"other"}=  "predictions derived based on PHDhtm";
    $sym{"PHDFhtm"}="filtered prediction, i.e., too long HTM's are\n".
	"---                split, too short ones are deleted";
    $sym{"PHDRhtm"}="refinement of neural network output ";
    $sym{"PHDThtm"}="topology prediction based on refined model\n".
	"---                symbols used:\n".
	"---             i: intra-cytoplasmic\n".
	"---             T: transmembrane region\n".
	"---             o: extra-cytoplasmic";
				# write symbols
    if ($Ldo_htmref) {
	print $fh "--- \n--- PhdTopology REFINEMENT AND TOPOLOGY PREDICTION: SYMBOLS\n";
	foreach $des(@des){
	    printf $fh "--- %-13s: %-s\n",$des,$sym{"$des"};}
	print $fh "--- \n--- PhdTopology REFINEMENT AND TOPOLOGY PREDICTION\n";}
    for($it=1;$it<=$nres_tmp;$it+=$nres_per_row) {
	$tmp=&myprt_npoints($nres_per_row,$it);
	printf $fh "%-17s %-s\n"," ",$tmp;
	foreach $_ (@des_loc) {
	    next if (length($STRING{"$_"})<$it);
	    $tmp=substr($STRING{"$_"},$it,$nres_per_row);
	    next if ((! defined $tmp) || (length($tmp)==0));
	    $format="%-".length($tmp)."s";$len=length($tmp);
				# helical transmembrane regions
	    if   ($_=~/aa/)    {printf $fh "%8s %-7s |%-s|\n"," ","AA ",$tmp; }
	    elsif($_=~/ohtm/)  {printf $fh "%8s %-7s |%-s|\n"," ","OBS htm",$tmp; }
	    elsif($_=~/phtm/)  {printf $fh "%8s %-7s |%-s|\n"," ","PHD htm",$tmp; }
	    elsif($_=~/pfhtm/) {printf $fh "%8s %-7s |%-s|\n"," ","other"," "; 
				printf $fh "%8s %-7s |%-s|\n"," ","PHDFhtm",$tmp; }
	    elsif($_=~/rihtm/) {printf $fh "%8s %-7s |%-s|\n"," ","Rel htm",$tmp; }
	    elsif($_=~/prHhtm/){print  $fh " detail: \n";
				printf $fh "%8s %-7s |%-s|\n"," ","prH htm",$tmp; }
	    elsif($_=~/prLhtm/){printf $fh "%8s %-7s |%-s|\n"," ","prL htm",$tmp; }
	    elsif($_=~/subhtm/){printf $fh "%-8s %-7s |%-s|\n"," subset:","SUB htm",$tmp;}

	    elsif($_=~/prhtm/) {printf $fh "%8s %-7s |%-s|\n"," ","PHDRhtm",$tmp; }
	    elsif($_=~/pthtm/) {printf $fh "%8s %-7s |%-s|\n"," ","PHDThtm",$tmp; }}}
    if ($Ldo_htmref) {
	print $fh
	    "--- \n",
	    "--- PhdTopology REFINEMENT AND TOPOLOGY PREDICTION END\n",
	    "--- \n";}
}				# end of wrt_phdpred_from_string

#===============================================================================
sub wrt_phdpred_from_string_htm_header {&wrt_phdpred_from_string_htmHdr(@_);} # alias

#===============================================================================
sub wrt_phdpred_from_string_htmHdr {
    local ($fh,@header) = @_ ;
    local ($header,$header_txt,$des,%txt,@des,%dat);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   wrt_phdpred_from_string_htmHdr writes the header for PHDhtm ref and top
#       in: header with (x1:x2), where x1 is the key and x2 the result
#--------------------------------------------------------------------------------
				# define notations
    $txt{"NHTM_BEST"}=     "number of transmembrane helices best model";
    $txt{"NHTM_2ND_BEST"}= "number of transmembrane helices 2nd best model";
    $txt{"REL_BEST_DPROJ"}="reliability of best model (0 is low, 9 high)";
    $txt{"MODEL"}=         "";
    $txt{"MODEL_DAT"}=     "";
    $txt{"HTMTOP_PRD"}=    "topology predicted ('in': intra-cytoplasmic)";
    $txt{"HTMTOP_RID"}=    "difference between positive charges";
    $txt{"HTMTOP_RIP"}=    "reliability of topology prediction (0-9)";
    $txt{"MOD_NHTM"}=      "number of transmembrane helices of model";
    $txt{"MOD_STOT"}=      "score for all residues";
    $txt{"MOD_SHTM"}=      "score for HTM added at current iteration step";
    $txt{"MOD_N-C"}=       "N  -  C  term of HTM added at current step";
    print  $fh			# first write header
	"--- \n",
	"--- ", "-" x 60, "\n",
	"--- PhdTopology prediction of transmembrane helices and topology\n",
	"--- ", "-" x 60, "\n",
	"--- \n",
	"--- PhdTopology REFINEMENT AND TOPOLOGY HEADER: ABBREVIATIONS\n",
	"--- \n";
				# ------------------------------
    $#des=0;			# extracting info
    foreach $header (@header_loc){
	($des,$header_txt)=split(/:/,$header);
	if ($des !~ /MODEL/){
	    push(@des,$des);
	    $dat{"$des"}=$header_txt;}}
				# writing notation
    foreach $des (@des,"MOD_NHTM","MOD_STOT","MOD_SHTM","MOD_N-C"){
	if ($des eq "MODEL_DAT") { # skip
	    next;}
	$tmp_des=$des;$tmp_des=~s/\_DPROJ//g;$tmp_des=~s/\s//g;
	printf $fh "--- %-13s: %-s\n",$tmp_des,$txt{"$des"};}
				# explaining algorithm
    print $fh 
	"--- \n",
	"--- ALGORITHM REF: The refinement is performed by a dynamic pro-\n",
	"--- ALGORITHM    : gramming-like procedure: iteratively the best\n",
	"--- ALGORITHM    : transmembrane helix (HTM) compatible with the\n",
	"--- ALGORITHM    : network output is added (starting from the  0\n",
	"--- ALGORITHM    : assumption, i.e.,  no HTM's  in the protein).\n",
	"--- ALGORITHM TOP: Topology is predicted by the  positive-inside\n",
	"--- ALGORITHM    : rule, i.e., the positive charges are compiled\n",
	"--- ALGORITHM    : separately  for all even and all odd  non-HTM\n",
	"--- ALGORITHM    : regions.  If the difference (charge even-odd)\n",
	"--- ALGORITHM    : is < 0, topology is predicted as 'in'.   That\n",
	"--- ALGORITHM    : means, the protein N-term starts on the intra\n",
	"--- ALGORITHM    : cytoplasmic side.\n",
	"--- \n";
    print $fh
	"--- PhdTopology REFINEMENT HEADER: SUMMARY\n";
				# writing info: first iteration
    printf $fh 
	" %-8s %-8s %-8s %-s \n","MOD_NHTM","MOD_STOT","MOD_SHTM","MOD_N-C";
    foreach $header (@header_loc){
	if ($header =~ /^MODEL_DAT/){
	    ($des,$header_txt)=split(/:/,$header);
	    @tmp=split(/,/,$header_txt);
	    printf $fh " %8d %8.3f %8.3f %-s\n",@tmp;}}
    print $fh
	"--- \n",
	"--- PhdTopology REFINEMENT AND TOPOLOGY HEADER: SUMMARY\n";
    foreach $des (@des){	# writing info: now rest
	if ($des ne "MODEL_DAT"){
	    $tmp_des=$des;$tmp_des=~s/_DPROJ|\s//g;
	    printf $fh "--- %-13s: %-s\n",$tmp_des,$dat{"$des"};}}
}				# end of wrt_phdpred_from_string_htmHdr

#===============================================================================
sub wrt_ppcol {
    local ($fhoutLoc,%rd)= @_ ;
    local (@des,$ct,$tmp,@tmp,$sep,$des,$des_tmp);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   wrt_ppcol                   writes out the PP column format
#       in:                     $fhoutLoc,%rd
#       out:                    1 or 0
#--------------------------------------------------------------------------------
    return(0,"error rd(des) not defined") if ( ! defined $rd{"des"});
    $tmp=$rd{"des"}; $tmp=~s/^\s*|\s*$//g; # purge leading blanks
    @des=split(/\s+/,$tmp);
    $sep="\t";                  # separator
				# ------------------------------
				# header
    print $fhoutLoc "# PP column format\n";
				# ------------------------------
    foreach $des (@des) {	# descriptor
	if ($des ne $des[$#des]) { 
	    print $fhoutLoc "$des$sep";}
	else {
	    print $fhoutLoc "$des\n";} }
				# ------------------------------
    $des_tmp=$des[1];		# now the prediction in 60 per line
    $ct=1;
    while (defined $rd{"$des_tmp","$ct"}) {
	foreach $des (@des) {
	    if ($des ne $des[$#des]) { 
		print $fhoutLoc $rd{"$des","$ct"},"$sep";}
	    else {
		print $fhoutLoc $rd{"$des","$ct"},"\n";}  }
	++$ct; }
    return(1,"ok");
}				# end of wrt_ppcol

#===============================================================================
sub wrt_strings {
    local ($fhout,$num_per_line,$Lspace,@string)=@_;
    $[ =1 ;
#--------------------------------------------------------------------------------
#   wrt_strings                 writes several strings with numbers..
#       in:                     $fhout,$num_per_line,$Lspace,@string , with:
#                               $string[1]= "descriptor 1"
#                               $string[2]= "string 1"
#       out:                    print onto filhandle
#--------------------------------------------------------------------------------
    $it=0;
    $nrows=int($#string/2);
    $len=  length($string[2]);
    while( $it <= $len ){
	$beg=$it+1;
	$it+=$num_per_line;
#	$end=$it;
	print $fhout " " x length($string[1])," ",&myprt_npoints($num_per_line,$beg),"\n";;
	foreach $row(1..$nrows){
	    print $fhout "$string[($row*2)-1]:",substr($string[$row*2],$beg,$num_per_line),"\n";}
	if ($Lspace){
	    print $fhout " \n";}
    }
}				# end of wrt_strings

#===============================================================================
sub wrt_strip_pp2 {
    local ($file_in,@strip) = @_ ;
    local ($fhout,$Lwatch,$Lrest,$strip,$it);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    wrt_strip_pp2              writes the final PP output file
#--------------------------------------------------------------------------------
    $fhout="FHOUT_STRIP_TOPITS";
    open($fhout, ">$file_in") || warn "Can't open '$file_in' (wrt_strip_pp2. lib-pp.pl)\n"; 
    $Lwatch=$Lrest=0;
    foreach $strip (@strip) {
	if ( $Lrest ) {
	    print $fhout "$strip\n"; }
	elsif ( $Lwatch && ($strip=~/^---/) ){
	    print $fhout "--- \n";
	    print $fhout "--- TOPITS ALIGNMENTS HEADER: PDB_POSITIONS FOR ALIGNED PAIR\n";
	    printf 
		$fhout "%5s %4s %4s %4s %4s %4s %4s %4s %-6s\n",
		"RANK","PIDE","IFIR","ILAS","JFIR","JLAS","LALI","LEN2","ID2";
	    foreach $it (1 .. $rd_hssp{"nali"}){
		printf 
		    $fhout "%5d %4d %4d %4d %4d %4d %4d %4d %-6s\n",
		    $it,int(100*$rd_hssp{"ide","$it"}),
		    $rd_hssp{"ifir","$it"},$rd_hssp{"ilas","$it"},
		    $rd_hssp{"jfir","$it"},$rd_hssp{"jlas","$it"},
		    $rd_hssp{"lali","$it"},$rd_hssp{"len2","$it"},
		    $rd_hssp{"id2","$it"};
	    }
	    $Lrest=1; 
	    print $fhout "$strip\n"; }
	elsif ($strip =~ /^--- .* SUMMARY/){ 
	    $Lwatch=1; 
	    print $fhout "$strip\n"; }
	elsif ($strip =~ /^--- NAME2/) { # abbreviations
	    print $fhout "$strip\n";
	    print $fhout "--- IFIR         : position of first residue of search sequence\n";
	    print $fhout "--- ILAS         : position of last residue of search sequence\n";
	    print $fhout "--- JFIR         : PDB position of first residue of remote homologue\n";
	    print $fhout "--- JLAS         : PDB position of last residue of remote homologue\n";
	} else {
	    print $fhout "$strip\n"; }
    }
    close($fhout);
}				# end of wrt_strip_pp2

#===============================================================================
sub wrtHsspHeaderTopBlabla {
    local ($fhoutLoc,$preLoc,$txtMode,$Lzscore,$Lenergy,$Lifir)=@_;
    $[ =1 ;
#--------------------------------------------------------------------------------
#   wrtHsspHeaderTopBlabla      writes header for HSSP RDB (or simlar) output file
#       in:                     $fhoutLoc,$preLoc,$txtMode,$Lzscore,$Lenergy,$Lifir
#         $fhErrSbr             FILE-HANDLE to report errors
#         $fhoutLoc             file handle print output
#         $preLoc               first letters to write
#         $txtMode = 'RDB'      write RDB file, note: by default #
#         $Lzscore              write zscore description
#         $Lenergy              write energy description
#         $Lifir                write ifir,ilas,jfir,jlas description
#--------------------------------------------------------------------------------
    if (defined $txtMode && ($txtMode  =~ /^rdb$/i)){
	$preLoc="\#".$preLoc;}

    print $fhoutLoc
	"$preLoc","------------------------------------------------------------\n",
	"$preLoc","MAXHOM multiple sequence alignment\n",
	"$preLoc","------------------------------------------------------------\n",
	"$preLoc","\n",
	"$preLoc","MAXHOM ALIGNMENT HEADER: ABBREVIATIONS FOR SUMMARY\n",
	"$preLoc","ID1          : identifier of guide (or search) protein\n",
	"$preLoc","ID2          : identifier of aligned (homologous) protein\n",
	"$preLoc","STRID        : PDB identifier (only for known structures)\n",
	"$preLoc","PIDE         : percentage of pairwise sequence identity\n",
	"$preLoc","WSIM         : percentage of weighted similarity\n";
    if ($Lenergy){		# use energy?
	print $fhoutLoc
	    "$preLoc","ENERGY       : value from Smith-Waterman algorithm\n";}
    if ($Lzscore){		# use zscore? 
	print $fhoutLoc
	    "$preLoc","ZSCORE       : zscore compiled from ENERGY\n";}
    print $fhoutLoc		# general points
	"$preLoc","LALI         : number of residues aligned\n",
	"$preLoc","LEN1         : length of guide (or search) sequence\n",
	"$preLoc","LEN2         : length of aligned sequence\n",
	"$preLoc","NGAP         : number of insertions and deletions (indels)\n",
	"$preLoc","LGAP         : number of residues in all indels\n";
    if ($Lifir){		# print beg and end of both sequences
	print $fhoutLoc
	    "$preLoc","IFIR         : position of first residue of search sequence\n",
	    "$preLoc","ILAS         : position of last residue of search sequence\n",
	    "$preLoc","JFIR         : PDB position of first residue of remote homologue\n",
	    "$preLoc","JLAS         : PDB position of last residue of remote homologue\n";}
    print $fhoutLoc
	"$preLoc","ACCNUM       : SwissProt accession number\n",
	"$preLoc","NAME         : one-line description of aligned protein\n",
	"$preLoc","\n";
}				# end of wrtHsspHeaderTopBlabla

#===============================================================================
sub wrtHsspHeaderTopData {
    local ($fhoutLoc,$preLoc,$txtMode,@dataLoc)=@_;
    $[ =1 ;
#--------------------------------------------------------------------------------
#  wrtHsspHeaderTopData         write DATA for new header of HSSP (or simlar)
#       in:                     $fhoutLoc,$prexLoc,$txtMode,@data:List:($kwd,$val)
#         $fhoutLoc             file handle print output
#         $preLoc               first letters to write
#         $txtMode = 'RDB'      write RDB file, note: by default #
#--------------------------------------------------------------------------------
    if (defined $txtMode && ($txtMode  =~ /^rdb$/i)){
	$preLoc="\#".$preLoc;}

    print $fhoutLoc
	"$preLoc","MAXHOM ALIGNMENT HEADER: INFORMATION ABOUT GUIDE SEQUENCE\n";
    while ($#dataLoc){
	$kwd=shift @dataLoc; $kwd=~tr/[a-z]/[A-Z]/;
	$val=shift @dataLoc;
	if ($kwd =~/^PARA/){@tmp=split(/\t/,$val);}else{@tmp=("$val");}
	foreach $tmp(@tmp){
	    printf $fhoutLoc "$preLoc"."%-12s : %-s\n",$kwd,$tmp;}}
    print $fhoutLoc
	"$preLoc","\n";
}				# end of wrtHsspHeaderTopData

#===============================================================================
sub wrtHsspHeaderTopFirstLine {
    local ($fhoutLoc,$preLoc,$txtMode)=@_;
    $[ =1 ;
#--------------------------------------------------------------------------------
#   wrtHsspHeaderTopFirstLine   writes first line for HSSP+STRIP header (perl-rdb)
#       in:                     $fhoutLoc,$txtMode
#         $fhoutLoc             file handle print output
#         $txtMode = 'RDB'      write RDB file, note: by default #
#--------------------------------------------------------------------------------
    if (defined $txtMode && ($txtMode =~ /^rdb$/i)){
	print $fhoutLoc 
	    "\# Perl-RDB      (HSSP_STRIP_MERGER)\n",
	    "\# \n";}
}				# end of wrtHsspHeaderTopFirstLine

#===============================================================================
sub wrtHsspHeaderTopLastLine {
    local ($fhoutLoc,$preLoc,$txtMode,@dataLoc)=@_;
    $[ =1 ;
#--------------------------------------------------------------------------------
#   wrtHsspHeaderTopLastLine    writes last line for top of header (to recognise next)
#       in:                     $fhoutLoc,$preLoc,$txtMode
#         $fhoutLoc             file handle print output
#         $preLoc               first letters to write
#         $txtMode = 'RDB'      write RDB file, note: by default #
#--------------------------------------------------------------------------------
    if (defined $txtMode && ($txtMode  =~ /^rdb$/i)){
	$preLoc="\#".$preLoc;}

    print $fhoutLoc
	"$preLoc","MAXHOM ALIGNMENT HEADER: INFORMATION ABOUT GUIDE SEQUENCE\n";
}				# end of wrtHsspTopLastLine

#===============================================================================
sub wrtMsf {
    local($fileOutMsfLoc,%input) = @_ ;
    local(@nameLoc,@stringLoc,$tmp,$fhoutLoc,$sbrName,$Lok);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   wrtMsf                      writing an MSF formatted file of aligned strings
#         in:                   $file_msf,$input{}
#                               $input{"NROWS"}  number of alignments
#                               $input{"FROM"}   name of input file
#                               $input{"TO"}     name of output file
#                               $input{"$it"}    sequence identifier ($name)
#                               $input{"$name"}  sequence for $name
#--------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";}
    $sbrName="$tmp"."wrtMsf";$fhoutLoc="FHOUT"."$sbrName";
				# open MSF file
    $Lok=       &open_file("$fhoutLoc",">$fileOutMsfLoc");
    if (! $Lok){print "*** ERROR $sbrName: '$fileOutMsfLoc' not opened\n";
		return(0);}
				# ------------------------------
				# process input
    $#nameLoc=$#tmp=0;
    foreach $it (1..$input{"NROWS"}){$name=$input{"$it"};
				     push(@nameLoc,$name);	# store the names
				     push(@stringLoc,$input{"$name"}); } # store sequences
				# ------------------------------
				# write into file
    print $fhoutLoc 
	"MSF of: ",$input{"FROM"}," from:    1 to:   ",length($stringLoc[1])," \n",
	$input{"TO"}," MSF: ",length($stringLoc[1]),
	"  Type: N  November 09, 1918 14:00 Check: 1933 ..\n \n \n";
    foreach $it (1..$#stringLoc){
	printf 
	    $fhoutLoc "Name: %-20s Len: %-5d Check: 2222 Weight: 1.00\n",
	    $nameLoc[$it],length($stringLoc[$it]); }
    print $fhoutLoc " \n";
    print $fhoutLoc "\/\/\n";
    print $fhoutLoc " \n";

    for($it=1;$it<=length($stringLoc[1]);$it+=50){
	foreach $it2 (1..$#stringLoc){
	    printf $fhoutLoc 
		"%-20s %-10s %-10s %-10s %-10s %-10s\n",$nameLoc[$it2],
		substr($stringLoc[$it2],$it,10),substr($stringLoc[$it2],($it+10),10),
		substr($stringLoc[$it2],($it+20),10),substr($stringLoc[$it2],($it+30),10),
		substr($stringLoc[$it2],($it+40),10); }
	print $fhoutLoc "\n"; }
    print $fhoutLoc "\n";
    close($fhoutLoc);
}				# end of wrtMsf

#===============================================================================
sub wrtRdb2HtmlHeader {
    local ($fhout,$scriptNameLoc,$fileLoc,$LlinkLoc,$LaveLoc,$colNamesLoc,@headerLoc) = @_ ;
    local (@colNamesLoc,$Lnotation,$LlinkHere,$col,@namesLink);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   wrtRdb2HtmlHeader		write the HTML header
#       in:	                $fhout,$fileLoc,$LlinkLoc,$colNamesLoc,@headerLoc
#                               where colName="name1,name2,"
#                               and @headerLoc contains all lines in header
#       out:                  @nameLinks : names of columns with links (i.e.
#                               found as NOTATION in header line
#--------------------------------------------------------------------------------
    $#namesLink=0;

    $colNamesLoc=~s/^,*|,*$//g;
    @colNamesLoc=split(/,/,$colNamesLoc);

    print $fhout 
	"<HTML>\n",
	"<TITLE>Extracted from $fileLoc </TITLE>\n",
	"<BODY>\n",
	"<H1>Results from $scriptNameLoc</H1>\n",
	"<H3>Extraction of data from RDB file '$fileLoc' </H3>\n",
	"<P><P>\n",
	"<UL>\n",
	"<LI><A HREF=\"\#HEADER\">RDB header<\/A>\n",
	"<LI><A HREF=\"\#BODY\">RDB table<\/A>\n";
    if ($LaveLoc){
	print $fhout "<LI><A HREF=\"\#AVERAGES\">Averages over columns<\/A>\n";}
	    
    print $fhout 
	"<\/UL>\n",
	"<P><P>\n",
	"<HR>\n",
	"<P><P>\n",
	"<A NAME=\"HEADER\"><H2>RDB header</H2><\/A>\n",
	"<P><P>\n";

    print $fhout "<PRE>\n";
    $Lnotation=0;
    foreach $_(@headerLoc){
	$LlinkHere=0;
	if (/NOTATION/){ $Lnotation=1;}
	if ($Lnotation){
	   foreach $col(@colNamesLoc){
		if (/^\#\s*$col\W/){ 
		    $colFound=$col;$LlinkHere=1;
		    push(@namesLink,$col);
		    last;}}
	   if ($LlinkLoc && $LlinkHere){ 
		print $fhout "<A NAME=\"$colFound\">";}}
	print $fhout "$_";
	if ($LlinkHere){
	   print $fhout "</A>";}
	print $fhout "\n";}
    print $fhout "\n</PRE>\n";
    print $fhout "<BR>\n";
    return(@namesLink);
}				# end of wrtRdb2HtmlHeader

#===============================================================================
sub wrtRdb2HtmlBody {
    local ($fhout,$LlinkLoc,%bodyLoc) = @_ ;
    $[ =1 ;
#--------------------------------------------------------------------------------
#   wrtRdb2HtmlBody		writes the body for a RDB->HTML file
#       in:	                $fhout,$LlinkLoc,%bodyLoc
#                               where $body{"it","colName"} contains the columns
#--------------------------------------------------------------------------------
    print $fhout 
	"<P><P><HR><P><P>\n\n",
	"<A NAME=\"BODY\"><H2>RDB table</H2><\/A>\n",
	"<P><P>\n";
				# get column names
    $bodyLoc{"COLNAMES"}=~s/^,*|,*$//g;
    @colNames=split(/,/,$bodyLoc{"COLNAMES"});

    print $fhout "<TABLE BORDER>\n";
				# ------------------------------
    				# write column names with links
    &wrtRdb2HtmlBodyColNames($fhout,@colNames);

				# ------------------------------
				# write body
    $LfstAve=0;
    foreach $it (1..$body{"NROWS"}){
	print $fhout "<TR>   ";
	foreach $itdes (1..$#colNames){
				# break for Averages
	    if ( ($itdes==1) && (! $LfstAve) &&
		($body{"$it","$colNames[1]"} =~ /^ave/) ){
		$LfstAve=1;
		&wrtRdb2HtmlBodyAve($fhout,@colNames);}
		    
	    if (defined $body{"$it","$colNames[$itdes]"}) {
	    	print $fhout "<TD>",$body{"$it","$colNames[$itdes]"};}
	    else {
		print $fhout "<TD>"," ";}}
	print $fhout "\n";}

    print $fhout "</TABLE>\n";
}				# end of wrtRdb2HtmlBody

#===============================================================================
sub wrtRdb2HtmlBodyColNames {
    local ($fhout,@colNames)=@_;
    $[ =1 ;
#--------------------------------------------------------------------------------
#   wrtRdb2HtmlBodyColNames     writes the column names (called by previous)
#       in GLOBAL:		%bodyLoc
#       in:                     $fhout,@colNames
#--------------------------------------------------------------------------------
    print $fhout "<TR>  ";
    foreach $des (@colNames){
	print $fhout "<TH>";
	if ($LlinkLoc && $bodyLoc{"link","$des"}){
	    print $fhout "<A HREF=\"\#$des\">";}
	print $fhout $des," ";
	if ($LlinkLoc && $bodyLoc{"link","$des"}){
	    print $fhout "</A>";}
    }
    print $fhout "\n";
}				# end of wrtRdb2HtmlBodyColNames

#===============================================================================
sub wrtRdb2HtmlBodyAve {
    local ($fhout,@colNames)=@_;
    $[ =1 ;
#--------------------------------------------------------------------------------
#   wrtRdb2HtmlBodyAve          inserts a break in the table for the averages at end of
#                               all rows
#       in:		        $fhout,@colNames
#--------------------------------------------------------------------------------
    foreach $_(@colNames){
	print $fhout "<TD>  ";}print $fhout "\n";
    print $fhout 
	"</TABLE>\n<P><HR><P>\n",
	"<P><P>\n",
	"<A NAME=\"AVERAGES\"><H4> Averages </H4><\/A><P>\n",
	"<TABLE BORDER>\n";

    &wrtRdb2HtmlBodyColNames($fhout,@colNames);
    print $fhout "<TR>   ";
}				# end of wrtRdb2HtmlBodyAve

1;
