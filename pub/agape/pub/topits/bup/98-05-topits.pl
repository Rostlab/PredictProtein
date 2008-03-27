#!/usr/sbin/perl -w
##!/bin/env perl 
#------------------------------------------------------------------------------#
# other perl environments
# 
# ----------
# EMBL
# ----------
##!/bin/env perl -w
##!/usr/sbin/perl -w
##!/usr/sbin/perl -w
##!/usr/sbin/perl4 -w
##!/usr/sbin/perl5 -w
# ----------
# EBI
# ----------
##!/usr/bin/perl -w
#----------------------------------------------------------------------
# topits
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# usage: 	topits.pl phd.rdb
#
# task:		run maxhom for the threading of secondary structure
#               and solvent accessibility (for one file or list of files)
#
# subs:         ini
# 
# external:     phd2dssp(                [perl/prot]
#               
#
#------------------------------------------------------------------------------#
#	Copyright				January,	1997	       #
#	Burkhard Rost		rost@EMBL-Heidelberg.DE			       #
#	EMBL			http://www.embl-heidelberg.de/~rost/	       #
#	D-69012 Heidelberg						       #
#				version 0.5   	December,	1993	       #
#				version 0.7   	June,   	1995	       #
#				version 0.8   	August, 	1995	       #
#				version 0.9   	October, 	1995	       #
#				version 1.0   	May,    	1996	       #
#				version 1.1   	February,	1997	       #
#------------------------------------------------------------------------------#
				# --------------------------------------------------
				# sets array count to start at 1, not at 0
				# --------------------------------------------------
$[ =1 ;
				# --------------------------------------------------
				# initialise variables
				# --------------------------------------------------
&ini;

# --------------------------------------------------------------------------------
# do the job (here we go)
# --------------------------------------------------------------------------------
				# ------------------------------
				# is it a list
				# ------------------------------
$#fileIn=0;
if ($Lis_list) {$fhin="FHIN_LIST";
		&open_file("$fhin","$fileIn");
		while (<$fhin>){$tmp=$_;$tmp=~s/\n|\s//g;
				if (length($tmp)<1) {next;}
				push(@fileIn,$tmp);}
		close($fhin); }
else {push(@fileIn,$fileIn);}
				# ------------------------------
				# compute new metric file
if ($LmetricIn) {		# ------------------------------
    &doMakeMetric; }
elsif ($Lscreen) {              print "--- default metric:\t '",$par{"fileMetric"},"'\n"; }

				# ------------------------------------------------------------
				# loop over list
				# ------------------------------------------------------------
foreach $fileIn (@fileIn) {
				# get names for this file and execute PHD if input file
				# is in HSSP format
                                # ==========================================
                                # note executes PHD if no DSSP file found!!!
                                # ==========================================
    ($fileIn,$fileDsspPhd,$fileDsspPhdLoc,$idProt,$idTitle,$chainLoc,$LisDsspOrig)=
	&ini1($fileIn,$chain,$#fileIn,$par{"titleOut"});

    if ($fileIn eq "0") {print "ERROR in TOPITS(.pl), probably no PHD prediction\n";
			  &cleanUp;
			  die "topits: no PHD file"; }
#				# convert PHD to DSSP
    if ((!-e $fileDsspPhd)|| $LisRdb){ 
	$Lok=&runPhd2Dssp($fileIn,$fileDsspPhdLoc); }
    elsif(!$LisDsspOrig) {	# cp file
	if ($fileDsspPhd ne $fileDsspPhdLoc) {
	    &file_cp($fileDsspPhd,$fileDsspPhdLoc,$Lscreen);
	    push(@rm_files,$fileDsspPhdLoc); } # add to list of to_be_cleaned afterwards
	if (-e $fileDsspPhdLoc) {
	    $Lok=1;}
	if ($Lscreen) { print
			    "--- Note: \t \t '",$par{"exePhd2dssp"},"' not executed \n",
			    "---      \t \t '$fileDsspPhdLoc' is DSSP format!\n";} }
    elsif ($LisDsspOrig && (-e $fileIn)){
	$Lok=1;}

    if (!$Lok) {		# to avoid a crash: skip if does not exist
	print "*** ERROR topits file:$fileDsspPhdLoc, (PHD.dsspPhd does not exist)\n";
	next; }
				# --------------------------------------------------
				# maxhom threading!
				# --------------------------------------------------
    if ((-e $fileDsspPhdLoc) && $LmaxhomTopits ) {
				# ==============================
				# here it comes!
				# ==============================
	&runMaxhomTopits($fileDsspPhdLoc,$idProt,$idTitle,$#fileIn,
			$par{"titleOut"},$chainLoc);
				# ==============================
	if ($par{"nhitsSel"}>0) { # extract top nhitsSel hits
	    &doExtract($par{"nhitsSel"},$idProt,
		       $par{"exeHsspFilterFor"},$par{"fileMetricGCG"});}
				# ------------------------------
				# mv files adjust names
				# ------------------------------
	if ( (-e $par{"fileHsspTopits"}) && (-e $par{"fileHsspTopitsExtr"}) ) {
	    $tmp_old=$par{"fileHsspTopits"};
	    $tmp_new=$par{"fileHsspTopitsExtr"};
	    print "--- TOPITS: system: 'mv $tmp_new $tmp_old'\n";
	    system("\\mv $tmp_new $tmp_old");}

	if ( (-e $par{"fileStripTopits"}) && (-e $par{"fileStripTopitsExtr"}) ) {
	    $tmp_old=$par{"fileStripTopits"};
	    $tmp_new=$par{"fileStripTopitsExtr"};
	    print "--- TOPITS: system: 'mv $tmp_new $tmp_old'\n";
	    system("\\mv $tmp_new $tmp_old");}
    }				# end of execution of maxhomTopits for one file
				# --------------------------------------------------
    elsif (!$LmaxhomTopits) {	# no maxhomTopits
	if ($Lscreen){
	    print "--- \t \t '",$par{"exeMaxhomTopits"},"' is not executed \n";}}
    else{			# PHD convert to DSSP missing!
	print"*** ERROR topits:: no file:$fileDsspPhd, (for dssp conversion of PHD.rdb)\n";
	&cleanUp;
	die "topits: no PHD->DSSP"; }
				# ------------------------------
				# run WhatIf modelling
				# ------------------------------
    if ($par{"doWhatifModel"}) {
#	&doWhatif;
    }
}
				# end of loop over list
				# ------------------------------------------------------------
&cleanUp;			# clean up

&myprt_empty; &myprt_line; &myprt_txt(" topits has ended fine .. -:\)"); 


#==========================================================================
sub ini {
    local ($script_input,$script_goal,$script_narg,
	   @script_goal,@script_help,@script_opt_key,@script_opt_keydes,$txt,$it);
    $[ =1 ;
#----------------------------------------------------------------------
#   ini                         initialises defaults and reads input arguments
#----------------------------------------------------------------------
    &iniEnv;			# set environment: @Date,$ARCH(LOC), $HOSTNAME, $USERID, $PATH

    &iniHelp;			# script name and optional arguments

    &iniDefaults;		# set the default values

    &iniGetArg;			# read command line arguments (and default file)

    &iniChangePar;		# changing parameters according to input arguments

    &iniError;			# error check for initial parameters

				# ------------------------------
				# onto screen
				# ------------------------------
    if ($Lscreen) { &myprt_line; &myprt_txt("Welcome to TOPITS");
		    print "---\n--- end of '"."$script_name"."'_ini settings are:\n"; 
		    printf "--- %-20s '%-s'\n","input",$fileIn;
		    foreach $des (@ar_des) {
			$Lok{"$des"}=0;}
		    foreach $desSort ("dir","exe","file","."){
			foreach $des (@ar_des) {
			    if (($des !~/^$desSort/)||($des =~/whatif/i)||($Lok{"$des"})){
				next;}
			    if ((defined $par{"$des"})&&($par{"$des"} ne "unk")){
				$Lok{"$des"}=1;
				printf "--- %-20s '%-s'\n",$des,$par{"$des"};}}}
		    &myprt_empty; &myprt_line; }
}				# end of ini

#===============================================================================
sub iniEnv {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iniEnv                      initialises environment variables
#	$date is e.g.:		Oct:14:13:06:47:1993
#	@Date is e.g.:		Oct1413:06:471993
#	&ctime(time) is e.g.:	Thu Oct 14 13:06:47 1993
#-------------------------------------------------------------------------------
				# --------------------------------------------------
				# include libraries
				# --------------------------------------------------
    if (! defined $ENV{'PERLLIB'}){
	push(@INC,"/home/rost/perl");push(@INC,"/home/rost/pub/phd/scr");
	push(@INC,"/home/phd/ut/perl");
    }
    else {
	push(@INC,$ENV{'PERLLIB'});}
    require"lib-ut.pl";require"lib-prot.pl";require"lib-comp.pl";
    require "ctime.pl"; 
				# --------------------------------------------------
				# architecture for binaries
				# --------------------------------------------------
    if    (defined $ENV{'ARCH'})   { $ARCH=$ENV{'ARCH'} ; }
    elsif (defined $ENV{'CPUARC'}) { $ARCH=$ENV{'CPUARC'};}
    else                           { $ARCH="unk"; }
				# corrections
    if    (($ARCH=~/IRIS/i)&&($ENV{'HOSTNAME'}=~/phenix/) ) {
                                     $ARCHLOC="SGI64";}
    elsif ($ARCH=~/IRIS/i)         { $ARCHLOC="SGI";}
    elsif ($ARCH =~ /solaris/)     { $ARCHLOC="SUNMP";}
    else                           { $ARCHLOC=$ARCH;}
				# corrections 2
    if ((! defined $ARCHLOC)||($ARCHLOC eq "unk")||(length($ARCHLOC)<1)){
	$HOSTNAME=$ENV{'HOSTNAME'}; 
	if   ($HOSTNAME=~/phenix/)     {$ARCHLOC="SGI64";}
	elsif($HOSTNAME=~/hawk/)       {$ARCHLOC="SGI5";}
	elsif($HOSTNAME=~/nu/)         {$ARCHLOC="ALPHA";}
	elsif($HOSTNAME=~/blue|purple/){$ARCHLOC="SUNMP";} }
				# corrections 3
    if ((! defined $ARCHLOC)||($ARCHLOC eq "unk")||(length($ARCHLOC)<1)){
	$ARCHLOC=               "SGI5";}
				# get local directory
    if (! defined $ENV{'PWD'}) {open(C,"/bin/pwd|");$PWD=<C>;close(C);}
    else {$PWD=$ENV{'PWD'};}
    $PWD=~s/^\/tmp_mnt//;	# purge /tmp_mnt/  EMBL specific

    $USERID=                    $ENV{'USER'};
				
    @Date = split(' ',&ctime(time)) ; shift (@Date) ; 
}				# end of iniEnv

#===============================================================================
sub iniHelp {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iniHelp                     initialise help text
#-------------------------------------------------------------------------------
    $script_name=   "topits";
    $script_input=  "name of PHD file (.rdb or .dsspPhd)";
    $script_goal=   "performs the threading for one protein (or a list)";
    $script_narg=   1;
    @script_goal=   (" ",
		     "Task: \t $script_goal",
		     " ",
		     "Input:\t $script_input",
		     " ",
		     "Done: \t ");
    @script_help=   ("Help: \t For further information on input options asf., please  type:",
		     "      \t '$script_name help'",
		     "      \t ............................................................",
		     );
    @script_opt_key=("notMaxhomTopits",
		     "notPhd2dssp",
		     "aliList=",
		     "isAcc3st",
		     "fileRdb=",
		     "titleOut=",
		     "keepX=",
		     "titleIn=",
		     "fileMetric=",
		     "fileMetricIn=",
		     "str:seq= (or mixStrSeq=)",
		     "chain=",
		     "datamode=",
		     "go=n",
		     "ge=n",
		     "smin=n",
		     "smax=n",
		     "noins (or Lindel1=0)",
		     "exeMax=",
		     "nhitsSel=",
		     " ",
		     "extRdb= ",
		     "filePhdRdb= ",
		     "fileHsspTopits= ",
		     "fileStripTopits= ",
		     " ",
		     "keepDssp (keepDssp)",
		     "opt_nice= ",
		     "ARCH= ",
		     "not_screen",
		     "file_out=",
		     "dirIn=",
		     "dirOut=",
		     "dirWork=");
    @script_opt_keydes= 
                    ("\n--- \t \t maxhomTopits not started",
		     "assume that DSSP format of PHD prediction exists \n".
		           "--- \t \t already (ext=dsspPhd)",
		     "as alignment list the list of DSSP file 'x' is used",
		     "alignment based on accessibility in 3 states \n".
		           "--- \t \t (default = 2)",
		     "the RDB formatted PHD prediction is named 'x'",
		     "output files will be named, e.g., id.strip -> id\$title.strip",
		     "input files named id\$titleIn.rdbPhd",
		     "1 or 0, maxhom.x will be kept",
		     "metric for scoring the matches",
		     "generation of new metric file from input = x",
		     "ratio for match_str vs. match_seq, \n".
		           "--- \t \t for n =0, 10, ..,100 => str:seq=n:(100-n)\n".
		           "--- \t \t i.e. for e.g. mixStrSeq=30 -> 30% str , 70% seq",
		     "name for chain (used for comparison with FSSP)",
		     "datamode = 'phd' , 'pdb', or 'phdtrain'",
		     "gap open,       ",
		     "gap elongation, ",
		     "smin,           ",
		     "smax,           ",
		     "don't allow indels in guide (default: DO allow)",
		     "executable of maxhom",
		     "filter .hssp and .strip, extract nhitsSel first hits ",
		     " ",
		     "extention for PHD RDB file ",
		     "name for PHD rdb file ",
		     "name for resulting topits HSSP file ",
		     "name for resulting topits strip file  ",
		     " ",
		     "Dssp file not removed ",
		     "'nice-n',  'nice' (=-4), or simply 'n' ",
		     "to be on the save side give: SGI5/SGI64/SUNMP/ALPHA \n".
		     "--- \t \t or 'setenv ARCH x'",
		     "no information written onto screen",
		     "output file name",
		     "input dir name,   default: local",
		     "output dir name,  default: local",
		     "working dir name, default: local",);

    if ( $#ARGV < $script_narg ) {
	print "-" x 80, "\n", "--- \n";&myprt_txt("Perl script "); 
	foreach $txt (@script_goal){if($txt !~ /Done:/){&myprt_txt("$txt");}}
	foreach $txt (@script_help){&myprt_txt("$txt");}
	print "---\n--- note: \t you can give the path of executables in a local file called:\n";
	printf"--- \t \t 'Defaults.$script_name'\n";
	&myprt_empty;print"-" x 80,"\n";
	die 'TOPITS natural death'; }
    elsif ($ARGV[1]=~/^help|^man|-h|-m/){
	print "-" x 80, "\n", "--- \n"; &myprt_txt("Perl script"); 
	foreach $txt (@script_goal) { if($txt !~ /Done:/){&myprt_txt("$txt");}} &myprt_empty; 
	&myprt_txt("usage: \t $script_name $script_input"); 
	&myprt_empty;&myprt_txt("optional (command line overwrites default file!):");
	for ($it=1; $it<=$#script_opt_key; ++$it) {
	    printf "--- %-12s %-s \n",$script_opt_key[$it],$script_opt_keydes[$it]; }
	print "---\n--- note: \t you can give the path of executables in a local file called:\n";
	printf"--- \t \t 'Defaults.$script_name'\n";
	&myprt_empty; print "-" x 80, "\n"; 
	die 'TOPITS natural death'; }
}				# end of iniHelp

#===============================================================================
sub iniDefaults {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iniDefaults                 initialise defaults
#-------------------------------------------------------------------------------
				# ------------------------------
				# highest priority: CPUARCH,
				# and default file
				# ------------------------------
    $fileTopitsDefaults=        "unk"; # ini
    foreach $arg (@ARGV) {
	$arg=~s/\s|\n//g;
	if  ($arg=~/ARCH=(.+)/) { $ARCHLOC=$1;}
	elsif ($arg=~/^(topitsDefault.*=|default.?)=(.+)/) {$fileTopitsDefaults=$2;}}
    $tmp="Defaults.topits";
    if ( ($fileTopitsDefaults eq "unk")&&(-e $tmp) ){$fileTopitsDefaults=$tmp;}
    $ARCH_could_be="SGI64|SGI5|SGI|SUN4|ALPHA|SUNMP"; # hack
				# ARCH now defined? or in command line?
    if ( ($ARCHLOC eq "unk") || ($ARCH_could_be !~ /$ARCHLOC/) ){
	foreach $arg(@ARGV){
	    $arg=~s/\s|\n//g;
	    if ($arg=~/^ARCH=(.+)/){$ARCH=$ARCHLOC=$1;}}}
				# ARCH now defined? or in default file?
    if ( ($ARCHLOC eq "unk") || ($ARCH_could_be !~ /$ARCHLOC/) ){
	if (-e $fileTopitsDefaults){
	    &open_file("FHINDEF","$fileTopitsDefaults");
	    while (<FHINDEF>){$tmp=$_;$tmp=~s/\s|\n//g;
			      if ($tmp=~/^ARCH[\t\s]+(.+)/){
				  $ARCHLOC=$1;
				  last;}}close(FHINDEF);}}
				# still not defined: stop
    if ( ($ARCHLOC eq "unk") || ($ARCH_could_be !~ /$ARCHLOC/) ){
	print
	    "*** no CPUARC or ARCH defined\n",
	    "*** please use command line option 'ARCH=x' \n",
	    "*** where x could be '$ARCH_could_be'\n";
	die "topits: no machine type defined";}
				# ------------------------------
				# directories
				# ------------------------------
    $par{"dirTopits"}=          "/home/rost/pub/topits/";
				# maxhom executables
    $par{"dirExeMaxhom"}=       "/home/rost/pub/max/bin/";
				# metric asf.
    $par{"dirExeMaxhomTopits"}= "/home/rost/pub/topits/scr/";
    $par{"dirExeMetric"}=       "/home/rost/pub/topits/bin/";
    $par{"dirMetric"}=          "/home/rost/pub/topits/mat/";
				# PHD output to DSSP 
    $par{"dirExeScripts"}=      "/home/rost/pub/topits/scr/";
    $par{"dirExePhd"}=          "/home/rost/pub/phd/";
    $par{"dirExeMolbio"}=       "/home/rost/pub/phd/bin/";
				# list of pdb files to be aligned to
    $par{"dirAliList"}=         "/home/rost/pub/topits/mat/";
				# names to move result files into
    $dirStrip=$dirHssp=$dirPredOut=$dirPredIn=$dirIn=$dirOut=$dirWork="";
				# whatif stuff
    $dirExeWhatif=              "/home/rost/whatif/";
    $par{"dirPdb"}=             "/data/pdb/";
				# ------------------------------
    $datamode=                  "phd";		# used for file extentsions
    $chain=                     "";
				# ------------------------------
				# file extensions
				# ------------------------------
    $par{"titleOut"}=           "unk";
    $par{"titleIn"}=            "unk";
    $par{"extStrip"}=           ".strip_topits";
    $par{"extHssp"}=            ".hssp_topits";
    $par{"extRdb"}=             ".rdb";
    $par{"extDsspPhd"}=         ".dssp_phd";
				# ------------------------------
				# default files
				# ------------------------------
				# search Defaults.topits: hierarchy: local, dir_def, def, ..
    if( (! -e $fileTopitsDefaults) || ($fileTopitsDefaults eq "unk") ) { 
	$fileTopitsDefaults="Defaults.topits"; }
    if(! -e $fileTopitsDefaults){ $fileTopitsDefaults=$par{"dirTopits"}."Defaults.topits"; }
    if(! -e $fileTopitsDefaults){ $fileTopitsDefaults="/home/rost/pub/topits/Defaults.topits"; }

    if((! defined $ENV{'MAXHOM_DEFAULT'}) || (! -e $ENV{'MAXHOM_DEFAULT'}) ){
	if   (-e "maxhom.default") {$fileDefaultsMaxhom="maxhom.default"; }
	elsif(-e "Defaults.maxhom"){$fileDefaultsMaxhom="Defaults.maxhom"; }
	else                       {$fileDefaultsMaxhom=
					$par{"dirTopits"}."Defaults.maxhom"; }
	$ENV{'MAXHOM_DEFAULT'}=$fileDefaultsMaxhom; }
    else {
	$fileDefaultsMaxhom=$ENV{'MAXHOM_DEFAULT'}; }
				# ------------------------------
				# executables
				# ------------------------------
				# default executables
    $par{"exeMaxhom"}=         $par{"dirExeMaxhom"}.      "maxhom."      .$ARCHLOC;
    $par{"exeMaxhomTopits"}=   $par{"dirExeMaxhomTopits"}."maxhom_topits.csh";
    $par{"exeMakeMetric"}=     $par{"dirExeMetric"}.      "make_metr2st.".$ARCHLOC;
    $par{"exePhd2dssp"}=       $par{"dirExeScripts"}.     "phd2dssp.pl";
    $par{"exeHsspFilter"}=     $par{"dirExeScripts"}.     "hssp_filter.pl";
    $par{"exeHsspFilterFor"}=  $par{"dirExeMolbio"}.      "filter_hssp." .$ARCHLOC;
    $par{"exeHsspExtrStrip"}=  $par{"dirExeScripts"}.     "hssp_extr_strip.pl";
    $par{"exeWhatif"}=         $dirExeWhatif.             "whatif.pl";
    $par{"exewhatifModel"}=    $dirExeWhatif.             "wif_model.pl";
    $par{"exeHssp2pir"}=       $par{"dirExeScripts"}.     "hssp_extr_2pir.pl";
    $par{"exePhd"}=            $par{"dirExePhd"}.         "phd.pl";
    $par{"exePhdFor"}=         $par{"dirExePhd"}.         "/bin/phd.$ARCHLOC";
    $par{"defaultsPhd"}=       $par{"dirExePhd"}.         "Defaults.phd";
				# ------------------------------------------------------------
				# calling maxhom
				# input arg: 1=seq, 2=aliList, 3=metric_file, 
                                #            4=smin, 5=gap_open, 6=gap_elong, 7=maxhom_exe
				# ------------------------------------------------------------
    $opt_nice=                  "";
    $par{"smin"}=               -1;
    $par{"smax"}=               1;
    $par{"go"}=                 2;	# gap open
    $par{"ge"}=                 0.2;	# gap elongation
    $par{"Lindel1"}=            1;	# allow insertions in first sequence?
				# alignment list with PDB structures (DSSP files)
    $par{"aliList"}=            $par{"dirAliList"}.       "Topits_dssp438.list";
    $par{"aliList"}=            $par{"dirAliList"}.       "Topits_dssp438.list";
				# metric file (GIVE full path)
    if (length($PWD)>1) {$dir_tmp=$PWD."\/";} else {$dir_tmp="";}
    $par{"fileMetricLoc"}=     $dir_tmp."TOPITS_METRIC_".$$.".output";
    $par{"fileMetricInLoc"}=   $dir_tmp."TOPITS_METRIC_".$$.".input";
    $par{"fileMetricSeq"}=     $par{"dirMetric"}.         "Maxhom_McLachlan.metric";
    $par{"fileMetricGCG"}=     $par{"dirMetric"}.         "Maxhom_GCG.metric";
    $par{"mixStrSeq"}=         50;	# ratio STR:SEQ 10-0: 10=100% struc; 5=50:50 struc:seq

    $par{"nhitsSel"}=          20;	# number of hits to be selected by filter_hssp, extr_strip
    $par{"LrmsdMaxhom"}=       0;	# compute RMSD values from MaxHom?

    $par{"doWhatifModel"}=      0;	# generate whatif model
    $par{"doWhatifGrafic"}=     0;	# write whatif script to run graphics
    $par{"doWhatifModelSlow"}=  0;      # do the slow WhatIf modelling
				# further files (largely named automatically)
    @des_tmp=("fileHsspTopits","fileHsspTopitsExtr",
	      "fileStripTopits","fileStripTopitsExtr","fileHsspXTopits",
	      "filePhdRdb","filePhdDssp");
    foreach $des (@des_tmp){$par{"$des"}="unk";}
    $fileRdb=$filePhdRdb=$fileHsspTopits=$fileStripTopits="unk";
				# ------------------------------
				# general + logicals
				# ------------------------------
    $Lphd2dssp=         1;	# run conversion phd (.rdb) -> DSSP format?
    $LmaxhomTopits=     1;	# run maxhom?
    $Lacc3st=           0;	# align 3 accessibility states?
    $LmetricIn=         0;	# metric is not computed on flight but read
    $LmixStrSeq=        0;	# use a new ratio match_seq / match_str  ( (10-n) / n )
    $LkeepDssp=         0;	# if 1 the DSSP file is forced to be kept
    $par{"keepX"}=      0;	# if 1, Maxhom.x will be kept
    $Lscreen=1; $Lerror=0;
    $Lscreen_det=0;
    $par{"debug"}=      0;	# remove intermediate files (if 1 keep)
    $opt_nice=                  "";
    $Lgzip_out=0;		# directly gzip on output files?
				# ------------------------------
				# changing executables for 3state stuff
    if ($Lacc3st) { $par{"exeMaxhomTopits"}.="_3st"; }
    if ($Lacc3st) { $par{"fileMetricLoc"}.=  "_3st"; }
    if ($Lacc3st) { print "*** for 3 states i/o, adjust names of metric!!\n";
		     die "topits problems with metric";}
				# ------------------------------
				# a.a descriptors 
				# allowed in default file
				# ------------------------------
    @ar_des=      ("exeMaxhom",  "exeMaxhomTopits","exeMakeMetric",
		   "exePhd2dssp","exeHsspFilter",  "exeHsspExtrStrip",
		   "exeWhatif",  "exeWhatifModel", "exeHssp2pir",      
		   "exePhd","exePhdFor","defaultsPhd",
		   "dirTopits","dirExeMaxhom", "dirExeMaxhomTopits","dirExeMetric",
		   "dirMetric","dirExeScripts","dirExePhd","dirExeMolbio","dirAliList",
		   "smin","smax","go","ge","aliList","debug",
		   "fileMetric","fileMetricIn","fileMetricInLoc","fileMetricSeq",
		   "mixStrSeq","nhitsSel","LrmsdMaxhom","Lindel1",
		   "doWhatifModel","doWhatifModelSlow","doWhatifGrafic",
		   "extStrip","extHssp","extRdb","extDsspPhd",
		   "titleOut","titleIn","keepX",
		   "exeHsspFilterFor","fileMetricGCG","dirPdb",
		   );
    @ar_des_files=("fileHsspTopits", "fileHsspTopitsExtr",
		   "fileStripTopits","fileStripTopitsExtr",
		   "fileHsspXTopits","filePhdRdb","filePhdDssp");
    push(@ar_des,@ar_des_files);
}				# end of iniDefaults

#===============================================================================
sub iniGetArg {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iniGetArg                   read command line arguments
#-------------------------------------------------------------------------------
				# --------------------------------------
				# input file name (phd file = name.pred)
				# --------------------------------------
    $fileIn=$ARGV[1]; 
				# check input mode
    $Lis_list=$LisDssp=$LisRdb=$Lis_hssp=0;
    if ( (!-e $fileIn)&&($fileIn =~ /hssp_/) ) {
	$fileIn=~s/hssp_(.)/hssp/;
	$chain=$1;}
    elsif (! -e $fileIn){
	$fileInNoChain=$fileIn;
	$fileInNoChain=~s/_.$//g;	# chain?
	if (! -e $fileInNoChain){
	    print "*** ERROR topits: missing input file '$fileIn' or '$fileInNoChain'\n";
	    die "topits: missing input file";}
	elsif (&is_dssp($fileInNoChain)){
	    $LisDssp=1;}
	elsif (&is_hssp($fileInNoChain)){
	    $Lis_hssp=1;}
	else {
	    print "*** ERROR topits: '$fileIn' missing, '$fileInNoChain' unrecognised!\n"; # 
	    die "topits: missing input file";}}
    else {
	if    ( &is_dssp($fileIn) ) {$LisDssp=1;}
	elsif ( &is_rdbf($fileIn) ) {$LisRdb=1;}
	elsif ( &is_hssp($fileIn) ) {$Lis_hssp=1;}
	else  { $Lis_list=1; }}
				# ------------------------------
				# get stuff from default file
				# ------------------------------
    if (-e $fileTopitsDefaults) { 
	print "--- read defaults from file \t '$fileTopitsDefaults'\n";
	%defaults=&iniRdDef($fileTopitsDefaults,$Lscreen_det); }
    foreach $des (@ar_des) {
	if (defined $defaults{"$des"}) {
	    if ($defaults{"$des"}=~/\/ARCH|ARCH\/|$ARCH_could_be/){
		if ( (defined $ARCHLOC) && ($defaults{"$des"}!~/$ARCHLOC/) ) {
		    $defaults{"$des"}=~s/\/ARCH|ARCH\/|$ARCH_could_be/$ARCHLOC/g;}}
	    $par{"$des"}=$defaults{"$des"};
                                # corrections
	    if ($des=~/exe/)       {$par{"$des"}=~s/\/\//\//g;}
	    else                   {$par{"$des"}=~s/\/\//\//g;} }}
				# if file defined and exists then set logical
    if ( (defined $par{"fileMetricIn"}) && (-e $par{"fileMetricIn"}) ) {$LmetricIn=1;}
    if ( (defined $par{"mixStrSeq"}) && $LmetricIn ) {$LmixStrSeq=1;}
				# ------------------------------
				# read option key words
				# ------------------------------
    for($it=($script_narg+1);$it<=$#ARGV;++$it) {
	$arg=$ARGV[$it];$arg=~s/\n|\s//g;
				# convert new notation
	$arg=~s/^ali_l/aliL/;$arg=~s/^file_r/filePhdR/;$arg=~s/^file_metric_in/fileMetricIn/;
	$arg=~s/^title_out/titleOut/;$arg=~s/^title_in/titleIn/;
	$arg=~s/^(str\:seq|mix_strseq)/mixStrseq/;
	$arg=~s/^nhits_sel/nhitsSel/;$arg=~s/^ext_rdb/extRdb/;
	$arg=~s/^exe_maxhom_topits/exeMaxhomTopits/;$arg=~s/^exe_maxhom/exeMaxhom/;
	$arg=~s/^exe_make_metric/exeMakeMetric/;$arg=~s/^Lindel_1/Lindel1/;
	$arg=~s/^dir_in/dirIn/;$arg=~s/^dir_out/dirOut/;$arg=~s/^dir_work/dirWork/;
				# assign arguments
	if    ($arg=~/^keep_?[Dd]ssp/ )      {$LkeepDssp=1;}
	elsif ($arg=~/^keepX=0/ )            {$par{"keepX"}=0;}
	elsif ($arg=~/^keepX/ )              {$par{"keepX"}=1;}
	elsif ($arg=~/^debug/)               {$par{"debug"}=1;}
	elsif ($arg=~/^fileMetric=([^=]+)$/) {
	    $par{"fileMetric"}=$1;
	    if ($par{"fileMetric"} !~/$PWD/) {$par{"fileMetric"}=$PWD."/".$par{"fileMetric"};}}
	elsif ($arg=~/^fileMetricIn=([^=]+)$/){$par{"fileMetricIn"}=$1;$LmetricIn=1; }
	elsif ($arg=~/^mixStrseq=([^=]+)$/ ) {$tmp=$1;$tmp=~s/[^0-9.]//g;
					      $par{"mixStrSeq"}=int($tmp); $LmixStrSeq=1; }
	elsif ($arg=~/^datamode=([^=]\w+)$/ ){$datamode=$1;}
	elsif ($arg=~/^extRdb=([^=]+)$/ )    {$par{"extRdb"}=".".$1;}
	elsif ($arg=~/^go=([^=]+)$/ )        {$par{"go"}=$1;}
	elsif ($arg=~/^ge=([^=]+)$/ )        {$par{"ge"}=$1;}
	elsif ($arg=~/^smin=([^=]+)$/ )      {$par{"smin"}=$1;}
	elsif ($arg=~/^smax=([^=]+)$/ )      {$par{"smax"}=$1;}
	elsif ($arg=~/^chain=([^=]+)$/ )     {$chain=$1; }
	elsif ($arg=~/^not_?[Mm]axhom_?[Tt]opits/)  {$LmaxhomTopits=0;}
	elsif ($arg=~/^not_?[Pp]hd2dssp/)    {$Lphd2dssp=0;}
	elsif ($arg=~/^is_?[Aa]cc_?3st/)     {$Lacc3st=1;}
	elsif ($arg=~/^not_screen/ )         {$Lscreen=0; }
	elsif ($arg=~/^file_?[Oo]ut=([^=]+)$/)               {$fileHsspTopits=$1;}
	elsif ($arg=~/^file_?[Hh]ssp_?[Tt]opits=([^=]+)$/)   {$fileHsspTopits=$1;}
	elsif ($arg=~/^file_?[Ss]trip_?[Tt]opits=([^=]+)$/)  {$fileStripTopits=$1; }
	elsif ($arg=~/^file_?[Pp]hd_?[Rr]db=([^=]+)$/ )      {$filePhdRdb=$1; }
	elsif ($arg=~/^dirIn=([^=]+)$/ )     {$dirIn=$1; }
	elsif ($arg=~/^dirOut=([^=]+)$/ )    {$dirOut=$1; }
	elsif ($arg=~/^dirWork=([^=]+)$/)    {$dirWork=$1; }
	elsif ($arg=~/^dir_work=([^=]+)$/)   {$dirWork=$1; }
	elsif ($arg=~/^.*nice=/ )         {
	    $tmp=$ARGV[$it];$tmp=~s/opt_nice=//g; $tmp=~s/nice|-//g; 
	    if (length($tmp)>0){ $opt_nice="nice -$tmp"; }else { $opt_nice="nice ";}}
				# intermediate for PP
	elsif ($arg=~/^exe_phd2dssp=/)   {$_=~s/\s|^.+=//g; $par{"exePhd2dssp"}=$arg;}
	elsif ($arg=~/^exe_phd=/)        {$_=~s/\s|^.+=//g; $par{"exePhd"}=$arg;}
				# end of intermediate for PP
	else {
	    $Lok=0;
	    foreach $des (@ar_des){
		if ($arg=~/^$des=([^=]+)$/) { $par{"$des"}=$1; $Lok=1; 
					      last; }}
	}}
    if ( (defined $par{"defaultsMaxhom"}) && (-e $par{"defaultsMaxhom"}) ){
	$fileDefaultsMaxhom=$par{"defaultsMaxhom"};}
}				# end of iniGetArg

#===============================================================================
sub iniChangePar {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iniChangePar                changing parameters according to input arguments
#                               e.g. adding directories to file names asf
#-------------------------------------------------------------------------------
    $par{"titleOut"}=~s/.*\///g; # purge directories from title
    $par{"titleIn"}=~s/.*\///g; # purge directories from title
    if (length($dirIn)>1) {
	$dirIn=&complete_dir($dirIn);
	if ($fileIn !~ /$dirIn/){$tmp=$fileIn; $fileIn="$dirIn"."$tmp";}
	$fileIn=~s/\/\/|\n/\//g;}
    if (length($dirWork)>1) { 
	$dirWork=&complete_dir($dirWork);
	@des=("fileMetric","fileMetricLoc","fileMetricInLoc");
	foreach $des (@des){
	    $par{"$des"}=~s/\n//g;
	    if ($par{"$des"}!~/$dirWork/){$par{"$des"}=~s/.*\///g;
					   $par{"$des"}="$dirWork".$par{"$des"};}}}
    if ($filePhdRdb      ne "unk") {$par{"filePhdRdb"}=$filePhdRdb;}
    if ($fileHsspTopits  ne "unk") {$par{"fileHsspTopits"}=$fileHsspTopits;}
    if ($fileStripTopits ne "unk") {$par{"fileStripTopits"}=$fileStripTopits;}
				# check title out!
    if (($par{"titleOut"} eq "unk")||($par{"titleOut"} =~/^-/)){
	if ($par{"titleOut"} eq "unk") {$par{"titleOut"}="";}
	$tmp=$fileIn;$tmp=~s/\.hssp.*|\.dssp.*|\.rdb.*|\.list.*//g;
	$par{"titleOut"}=$tmp.$par{"titleOut"};
	$par{"titleOut"}=~s/^.*\///g;} # purge dirs
    if (($par{"titleIn"} eq "unk")||($par{"titleIn"} =~/^-/)){
	if ($par{"titleIn"} eq "unk") {$par{"titleIn"}="";}
	$tmp=$fileIn;$tmp=~s/\.hssp.*|\.dssp.*|\.rdb.*|\.list.*//g;
	$par{"titleIn"}=$tmp.$par{"titleIn"};
	$par{"titleIn"}=~s/^.*\///g;} # purge dirs
				# correct if read 'title'.hssp (in default file)
    foreach $des (@ar_des_files){
	if ( $par{"$des"} eq "unk" ) { # exception 
	    $des_ext=$des;$des_ext=~s/^file_?//g;
	    $des_ext=~s/Topits/_topits/g;$des_ext=~s/Extr/_extr/g;
	    $des_ext=~s/Rdb/_rdb/g;$des_ext=~s/Dssp/_dssp/g;
	    $des_ext=~s/Hssp/hssp/g;$des_ext=~s/Strip/strip/g;$des_ext=~s/Phd/phd/g;
	    if ($des =~/^filePhd/){ # for PHD files : no title
		$par{"$des"}=$dirWork.$par{"titleIn"}. ".".$des_ext; }
	    else {		# for HSSP title out
		$par{"$des"}=$dirWork.$par{"titleOut"}.".".$des_ext; }}
	elsif ( $par{"$des"}=~/^title/ ) {
	    if ($des =~/^filePhd/){ # for PHD files : no title
		$tmp1="$dirWork".$par{"titleIn"};
		$tmp2=$par{"$des"};$tmp2=~s/^.\/|title//g;
		$par{"$des"}="$tmp1"."$tmp2"; }
	    else{
		$tmp1="$dirWork".$par{"titleOut"};
		$tmp2=$par{"$des"};$tmp2=~s/^.\/|title//g;
		$par{"$des"}="$tmp1"."$tmp2"; }}
	$par{"$des"}=~s/\n//g; 
	if (($par{"$des"} !~ /^$dirOut|^$dirWork/)&&($par{"$des"} =~ /^\//)){
	    $par{"$des"}=~s/^.*\///g;}}
				# give a safe metric file if no argument chosen
    if ( (! $LmetricIn) && ((! defined $par{"fileMetric"})||(! -e $par{"fileMetric"})) ) { 
	if ($par{"mixStrSeq"}==100)  {
	    $par{"fileMetric"}=$par{"dirMetric"}."Topits_out.metric";}
	elsif ($par{"mixStrSeq"}==50){
	    $par{"fileMetric"}=$par{"dirMetric"}."Topits_50out.metric";}
	else { 
	    print"-*- WARNING \t \t no new metric generated\n",
	    "-*- WARNING \t \t mixStrSeq assumed to be =100 or =50, but is NOT!!\n";}
	print "-*- WARNING \t \t no metric file, take default:",$par{"fileMetric"},"\n";}
    elsif ($LmetricIn) {	# copy metric file to local name if to be generated
	$par{"fileMetric"}=$par{"fileMetricLoc"}; }
				# correct for missing dots in extensions
				# for output file names
    foreach $des ("extStrip","extHssp","extRdb","extDsspPhd"){
	if ($par{"$des"} !~ /\./){$tmp=".";$tmp.=$par{"$des"};$par{"$des"}=$tmp;}}
    $extStrip=   $par{"extStrip"};    
    $extHssp=    $par{"extHssp"};
    $extRdb=     $par{"extRdb"};
    $extDsspPhd= $par{"extDsspPhd"};
				# ------------------------------
				# correct for alpha
				# ------------------------------
    foreach $des (@ar_des) {
	if ($des =~ /whatif/i){
	    next;}
	if (defined $par{"$des"}) {
	    $par{"$des"}=~s/\s|\n//g;$par{"$des"}=~s/\/\//\//g;} }
}				# end of iniChangePar

#===============================================================================
sub iniError {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iniError                    error check for initial parameters
#-------------------------------------------------------------------------------
    if (!-e $fileDefaultsMaxhom){
	print "*** ERROR topits:: no '$fileDefaultsMaxhom'\n"; $Lerror=1;}
    if ((!-e $par{"exeMaxhomTopits"})&&(!-l $par{"exeMaxhomTopits"})){
	$par{"exeMaxhomTopits"}=$exe="$dirWork"."MaxhomTopits_CSH_".$$;
	system("cp /home/rost/pub/topits/maxhomTopits.csh $exe");}
    if ((!-e $par{"exeMaxhomTopits"})&&(!-l $par{"exeMaxhomTopits"})){
	print "*** ERROR topits: no '",$par{"exeMaxhomTopits"},"'\n"; $Lerror=1;}
    if ((!-e $par{"exeMaxhom"})&&(!-l $par{"exeMaxhom"})){
	print"*** ERROR topits: no '",$par{"exeMaxhom"},"'\n"; $Lerror=1;}
    if (!-e $par{"aliList"})  {
	print"*** ERROR topits: no '",$par{"aliList"},"'\n"; $Lerror=1;}
    if ($LmetricIn) {
	if (!-e $par{"fileMetricIn"})  { 
	    print "*** ERROR topits: no file metricIn=",$par{"fileMetricIn"},",\n";$Lerror=1;}
	if ((!-e $par{"exeMakeMetric"})&&(!-x $par{"exeMakeMetric"})){ 
	    print "*** ERROR topits: no exeMakeMetric=",$par{"exeMakeMetric"},",\n";
	    $Lerror=1;} }
    elsif (!-e $par{"fileMetric"}){
	print"*** ERROR topits: '",$par{"fileMetric"},"' missing\n"; 
				    $Lerror=1;}
    if ($par{"nhitsSel"}>0) {
	if ((!-e $par{"exeHsspFilter"})&&(!-l $par{"exeHsspFilter"})) { 
	    printf 
		"*** %-20s '%-s'\n","ERROR topits: no exeHsspFilter=",$par{"exeHsspFilter"};
	    $Lerror=1;}
	if ((!-e $par{"exeHsspExtrStrip"})&&(!-l $par{"exeHsspExtrStrip"})){
	    printf
		"*** %-20s '%-s'\n","ERROR topits: no exeHsspExtrStrip=",
		$par{"exeHsspExtrStrip"};
	    $Lerror=1;}}
    if ($Lerror) { print "*** left ini!\n";
		   &cleanUp;
		   die "topits: ERROR in initialisation phase";}
}				# end of iniError

#==========================================================================================
sub iniRdDef {
    local ($fileIn,$Lscreen)=@_;
    local ($fhin,$tmp,@tmp,%defaults);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   iniRdDef                    reads defaults for initialsing topits parameters
#       in:                     fileDefault
#       out:
#         $defaults{"des"}=val  if in default file: 
#                               "des1"    val1
#                               "des2"    val2
#--------------------------------------------------------------------------------
    if ($Lscreen){
	print "-" x 80,"\n","--- \n","--- Reading default file \t '$fileIn'\n","--- \n";}
    $fhin="FHIN_DEFAULTS";
    &open_file("$fhin","$fileIn");
    while (<$fhin>){
	if ((length($_)<3)||(/^\#/)) {next;}
	@tmp=split(/[ \t]+/);
	foreach $tmp (@tmp) { 
	    $tmp=~s/[ \n]*$//g;	# purge end blanks
	    if ($tmp=~/ARCH/) {$tmp=~s/ARCH/$ARCHLOC/;}	# get CPU architecture
	}
	if    ($tmp[1]=~/gap_open/)      {$tmp[1]="go";}
	elsif ($tmp[1]=~/gap_elongation/){$tmp[1]="ge";}
	$defaults{"$tmp[1]"}=$tmp[2];
	if ($Lscreen){printf "--- read: %-22s (%s)\n",$tmp[1],$tmp[2];}
    }
    close($fhin);
    if ($Lscreen){print "--- \n--- end reading defaults\n","-" x 80,"\n","--- \n";}
    return (%defaults);
}				# end of iniRdDef

#==========================================================================================
sub ini1 {
    local ($fileIn,$chain,$nFiles,$titleLoc) = @_ ;
    local ($fileDsspPhd,$fileDsspPhdLoc,$idLoc,$opt_nice_tmp,$titleMax,$tmpChain);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    ini1         assigns dependent variables for one run 
#                               (if input = list of files)
#    GLOBAL in:                 $title_out, $extRdb, $extDsspPhd
#    GLOBAL out:                $LisDssp, $LisRdb
#--------------------------------------------------------------------------------
    $LisRdb=$LisDssp=$LisDsspOrig=0;
				# chain id?
    if ($fileIn=~/\_\!\_/){
	$chain=$fileIn;$chain=~s/.*(\_\!\_.)/$1/;
	$fileIn=~s/\_\!\_.//g;}
#				# latest hack for recognising chains (20-11-96)
    elsif ($fileIn=~/_[A-Z0-9]$/){
	$chain=$fileIn;$chain=~s/^.*_(.)$/$1/;
	$fileIn=~s/_.//g;}
    elsif ( (!-e $fileIn)&&($fileIn =~ /hssp_/) ) {
	$fileIn=~s/hssp_(.)/hssp/;
	$chain=$1;}
    elsif ((! defined $chain) || ($chain!~/\w/)) {$chain="";}
				# directory to be added?
    if ( (! -e $fileIn) && (length($dirPredIn)>0) && ($dirPredIn!~/^unk/) ) {
	$tmp="$dirPredIn"."$fileIn";
	$fileIn=$tmp;}
    if (! -e $fileIn){		# purge output title
	$fileIn=~s/$titleLoc//;}
				# ------------------------------
				# get file phd.rdb -> phd.dsspPhd (i.e. DSSP format)
    if   ( &is_rdbf($fileIn) ) {
	$fileDsspPhd=$fileIn;$tmp=$par{"extRdb"};
	$fileRdb="$dirWork"."$titleLoc"."$tmp";
	&file_cp($fileIn,$fileRdb,$Lscreen);
	$tmp2=$par{"filePhdDssp"};
	if ( (defined $tmp2)&&($tmp2!~/^unk/)&&(length($tmp2)>1) ) {
	    $fileDsspPhd=$par{"filePhdDssp"};}
	else {$fileDsspPhd=$fileIn;
	      $fileDsspPhd=~s/$extRdb/$extDsspPhd/;}
	$LisRdb=1;}
    elsif( &is_hssp($fileIn) ){ 
	$fileHssp=$fileIn;
	if ($Lscreen) { print "--- is HSSP file \t -> run PHD !\n"; }
	if (length($opt_nice)<1){$opt_nice_tmp="unk";}
	else {$opt_nice_tmp=$opt_nice; $opt_nice_tmp=~s/\s//g;}
	$fileRdb=
	    &runPhd($fileHssp,$par{"exePhd"},$par{"exePhdFor"},$opt_nice_tmp,$chain);
	$fileIn=$fileRdb;
	$tmp2=$par{"filePhdDssp"};
	if ( (defined $tmp2)&&($tmp2!~/^unk/)&&(length($tmp2)>1) ) {
	    $fileDsspPhd=$par{"filePhdDssp"};}
	else {
	    $fileDsspPhd=$fileIn;
	    $fileDsspPhd=~s/\.hssp.*/$extDsspPhd/;}
	$par{"filePhdDssp"}=$fileDsspPhd;
	if (! -e $fileRdb){
	    print "*** ERROR in topits.pl after calling phd.pl\n";
	    print "***       RDB file (PHD result) '$fileRdb' missing\n";
	    return(0);}
	&file_cp($fileRdb,$par{"filePhdRdb"},$Lscreen);
	$LisRdb=1; }
    elsif( &is_dssp($fileIn) ){ 
	$fileDsspPhd=$fileIn; $LisDssp=1; $LisDsspOrig=1;}
    else { 
	print "*** ERROR in topits.pl ini1 fileIn=$fileIn, unrecognised format\n";
	return(0);}
				# ------------------------------
				# make local copy
#				# latest hack for recognising chains (20-11-96)
    $titleLocIn=$titleLoc;
    if ($LisDsspOrig){
	$file_tmp=$fileIn;$file_tmp=~s/^.*\///g;
	$file_tmp=~s/\.dssp/$chain\.dssp/;
	if ((defined $dirWork)&&(length($dirWork)>2)){
	    $file_tmp="$dirWork"."$file_tmp";}
	if ($file_tmp ne $fileIn){
	    &file_cp($fileIn,$file_tmp,$Lscreen);
	    push(@rm_files,$file_tmp);	} # add to list of to_be_cleaned afterwards
	$fileIn=$fileDsspPhdLoc=$fileDsspPhd=$file_tmp;
	$idLoc=$fileIn;$idLoc=~s/\.dssp.*$//g;$idLoc=~s/^.*\///g;
	$titleLocIn=$par{"titleIn"}=$idLoc;}
    elsif ($par{"filePhdDssp"}=~/^unk/){
	if ($fileIn =~/.*\//) { $file_tmp=$fileIn;$file_tmp=~s/.*\///g;
				 if ($file_tmp ne $fileIn){
				     &file_cp($fileIn,$file_tmp,$Lscreen);
				     push(@rm_files,$file_tmp);}
				 $fileIn=$file_tmp;}
				# ------------------------------
				# get id
	$idLoc=$fileIn;$idLoc=~s/^.*\/|$extRdb|$extDsspPhd//g;
				# ------------------------------
				# get new file name for phd.dsspPhd
	if ( (length($titleLoc)>0) && ($titleLoc!~/unk/) ) {
	    $fileDsspPhdLoc=$fileDsspPhd; 
				# from 1ppt.dsspPhd 1ppt_title.dsspPhd
	    $fileDsspPhdLoc=~s/(.+)$extDsspPhd$/$1_$titleLoc$extDsspPhd/g;
	    $idLoc=$idLoc."_$titleLoc"; }
	else { $fileDsspPhdLoc=$fileDsspPhd; }
	$fileDsspPhdLoc=~s/^.*\///g; } # put to current directory
    else { $fileDsspPhdLoc=$fileDsspPhd;
	   $idLoc=$fileDsspPhd;$idLoc=~s/^.*\/|$extRdb|$extDsspPhd//g;
	   if (!$LkeepDssp){push(@rm_files,$fileIn);}
	   if (! -e $fileDsspPhd){push(@rm_files,$fileDsspPhd);}}
    $idLoc=~s/\.dssp.*|\.rdb.*|\.hssp.*//g;
    if ($nFiles==1){		# name for single input file
	$titleMax=$titleLoc;}	# get name of input file
    else {
	$titleMax=$idLoc;	# get PDBID ..
	$tmpChain=$chain;$tmpChain=~s/[_\!]//g;
	if ((length($idLoc)==4)&&(length($tmpChain)>0)){
	    $titleMax.=$tmpChain;}
	if (($ARGV[1]!~/$titleLoc/)&&
	    (length($titleLoc)>0)){ # hack may96 (avoid to duplicat default and chosen title)
	    $titleMax.="_".$titleLoc;}}
				# hack 22-04-97
				# directory to be added?
    if ((defined $dirWork)&&(length($dirWork)>2)&&($fileDsspPhdLoc !~/^$dirWork/)){
	$file_tmp="$dirWork"."$fileDsspPhdLoc";
	&file_cp($fileDsspPhd,$file_tmp,$Lscreen);
	push(@rm_files,$file_tmp); # add to list of to_be_cleaned afterwards
	$fileDsspPhdLoc=$file_tmp;}
    return ($fileIn,$fileDsspPhd,$fileDsspPhdLoc,$idLoc,$titleMax,$chain,$LisDsspOrig);
}				# end of ini1

#==========================================================================================
sub cleanUp {
    local ($tmp,$old,$new);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    cleanUp                    removes and moves files
#--------------------------------------------------------------------------------
    if ($par{"debug"}){
	print "*** \n--- option debug on, no files removed\n*** \n";
	return;}
    if ($Lscreen) {             print "--- \n--- now clean up files:\n";}
    if ($par{"exeMaxhomTopits"}=~/^$dirWork/){
	push(@rm_files,$par{"exeMaxhomTopits"});}
    $tmp="MAXHOM.LOG_".$$."";push(@rm_files,$tmp);
    if (($#rm_files>0)&&(defined @rm_files)) {
	foreach $tmp (@rm_files) {
	    $tmp=~s/\n//g; $tmp=~s/\s//g; 
	    if ((!defined $tmp)||(! -e $tmp)){ next; }
	    if ($tmp =~/^($par{"dirTopits"}|$par{"dirExeMaxhom"}|$par{"dirExePhd"}|$par{"dirExeMolbio"})/){ # avoid deleting important stuff!!
		next;}
                                # security don't remove scripts asf!
	    if ( $tmp=~/^\/home\/.*\/topits/) {next;}
	    if ( $tmp eq $ARGV[1] ) { next; }
	    if ($Lscreen) {     printf "--- %-20s %-s\n","system","'\\rm $tmp'";}
	    system("\\rm $tmp");
	} }
    if (%mv_files) {foreach $tmp (@mv_files) {
	    $tmp=~s/\n|\s//g; if ( (length($tmp)<1)||(!defined $tmp) ) {next;}
	    $old=$tmp; $new=$mv_files{"$tmp"};
	    if ($Lscreen) {     printf "--- %-20s %-s\n","system","'\\mv $old $new'";}
	    system("\\mv $old $new");
	    if ($Lgzip_out) {
		if ($Lscreen) { printf "--- %-20s %-s\n","system","'gzip $new'";}
		system("gzip $new"); 
	    }}}
}				# end of cleanUp

#==========================================================================================
sub doExtract {
    local ($nhitsSel,$idLoc,$exeHsspFilterFor,$fileMetricGCG) = @_ ;
    local ($exe,$arg,$f_in,$f_out);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   doExtract                   extracts first nhitsSel hits from .hssp and .strip files
#--------------------------------------------------------------------------------
                                # ------------------------------
				# hssp
                                # ------------------------------
    if ($opt_nice=~/^\s*nice/){
	$exe="$opt_nice ".$par{"exeHsspFilter"};}else{$exe=$par{"exeHsspFilter"};}

    if ($par{"fileHsspTopits"} ne "unk"){
	$f_in=$par{"fileHsspTopits"}; }
    else {$f_in="$idLoc"."$extHssp";}
                                # hack : problems with Hawk, br 25-08-95
    if ((defined $par{"fileHsspTopitsExtr"})&&($par{"fileHsspTopitsExtr"} ne "unk") ){
	$f_out=$par{"fileHsspTopitsExtr"}; }
    else {$f_out=$par{"fileHsspTopits"}."_fil";}

    $arg="$f_in file_out="."$f_out"." incl=1-"."$nhitsSel"." not_screen" .
	" exe_filter_hssp=$exeHsspFilterFor" . " molbio_metric=$fileMetricGCG ";
    if ((defined $dirWork)&&(length($dirWork)>3)){
	$arg.="dir_work=$dirWork ";}
                                # end hack : problems with Hawk, br 25-08-95
    if ($Lscreen) {     print "--- system: \t \t '$exe $arg'\n";}
    # =================
    system("$exe $arg");
    # =================
                                # hack 2, br 25-08-95
    if ($USERID =~/phd/) {
	if ($Lscreen) {         print "--- system: \t \t 'mv $f_out $f_in'\n";}
	system("\\mv $f_out $f_in"); }
                                # end hack 2, br 25-08-95
                                # ------------------------------
				# strip
                                # ------------------------------
    $exe=$par{"exeHsspExtrStrip"};
    if ($par{"fileStripTopits"}!~/^unk/){
	$f_in=$par{"fileStripTopits"}; }
    else {
	$f_in="$idLoc"."$extStrip";}
    if ((defined $par{"fileStripTopitsExtr"})&&($par{"fileStripTopitsExtr"} ne "unk") ){
	$f_out=$par{"fileStripTopitsExtr"}; }
    else {
	$f_out=$par{"fileStripTopits"}."Extr";}
    $arg="$f_in file_out="."$f_out"." incl=1-"."$nhitsSel"." not_screen"; 
    if ($Lscreen) {     print "--- system: \t \t '$exe $arg'\n";}
    # =================
    system("$exe $arg");
    # =================
    if ($USERID =~/phd/) {
	if ($Lscreen) {     print "--- system: \t \t 'mv $f_out $f_in'\n";}
	system("\\mv $f_out $f_in"); }
}				# end of doExtract

#==========================================================================================
sub doMakeMetric {
    local ($arg,$exe,$tmp,$tmp_mix,$fileMetricInLoc);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   exeMakeMetric               executes make_metric
#   GLOBAL in/out              all
#--------------------------------------------------------------------------------
    if (-e $par{"fileMetricIn"}) {
	$fileMetricInLoc=$par{"fileMetricInLoc"};
				# cp to current directory
	&file_cp($par{"fileMetricIn"},$fileMetricInLoc,$Lscreen);
				# list of files to be deleted afterwards
	push(@rm_files,$fileMetricInLoc);
				# if metric file local, delete it!
	if ( $par{"fileMetric"} =~ /$PWD/ ){
	    push(@rm_files,$par{"fileMetric"}); }
	elsif ( $par{"fileMetric"} !~ /\//  ) {
	    print "*** ERROR for metric: please give FULL path, required in MaxHom!\n";}
	elsif ( $par{"fileMetric"} =~ /$$/  ) {
	    push(@rm_files,$par{"fileMetric"}); }
				# append new ratio (FAC_STR=dd) to default input file
	if ($LmixStrSeq) {
	    if    ($par{"mixStrSeq"}==100) { $tmp_mix="FAC_STR=10"; }
	    elsif ($par{"mixStrSeq"}==50) { $tmp_mix="FAC_STR= 5"; }
	    else { $tmp_mix="FAC_STR= ".int($par{"mixStrSeq"}/10); }
	    if ($Lscreen) {     $tmp=$fileMetricInLoc;$tmp=~s/$PWD\///g;;
				print "--- system: \t \t echo '$tmp_mix' >> $tmp\n";}
	    system("echo '$tmp_mix' >> $fileMetricInLoc");
	}
				# do it: make the new metric
	$exe=$par{"exeMakeMetric"};
	$arg="$fileMetricInLoc ".$par{"fileMetric"};
	if ( (defined $par{"fileMetricSeq"}) && (-e $par{"fileMetricSeq"}) ) {
	    $arg.=" ".$par{"fileMetricSeq"};}
	if ($Lscreen) {         $tmp=$arg;
				print "--- system: \t \t '$exe $tmp'\n"; }
	system("$exe $arg");

	if (!-e $par{"fileMetric"}) {
	    print "*** ERROR topits: missing: metric output=",$par{"fileMetric"},", why?\n";
	    print "    apparently the script $exe has not done its work.\n";
	    &cleanUp;
	    die "topits: no metric file given";}
	elsif ( ($par{"fileMetric"} !~ /home\/phd/)&&($par{"fileMetric"} !~ /home\/rost/) ){
	    push(@rm_files,$par{"fileMetric"})}
    } else {print "*** LmetricIn=1, i.e. fileMetricIn should exist, but doesn't!\n";
	    &cleanUp;
	    die "topits: no metric file provided";}
}				# end of doMakeMetric

#==========================================================================================
sub runMaxhomTopits {
    local ($fileDsspPhdLoc,$idProtLoc,$idTitleLoc,$nFiles,$titleOriginal,$chainLoc)=@_;
    local ($arg,$exe,@tmp,$tmp,$old,$new,$tmp_hssp,$tmp_strip,$file_tmpDssp);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   exeMaxhomTopits            executes maxhomTopits cshell
#   GLOBAL in/out              all
#--------------------------------------------------------------------------------
				# input arg: 1=seq, 2=aliList, 3=metric_file, 
				#            4=smin, 5=smax, 6=gap_open, 7=gap_elon, 
				#            8=maxhom_exe
    if ( ! defined $idTitleLoc ) { # cp to current directory
	$idTitleLoc=$fileDsspPhdLoc;$idTitleLoc=~s/\.[dhf]ssp.*$|\.rdb.*$//g; }
				# change file names
    if (($par{"fileHsspTopits"}!~/^\//)&&
	(($idTitleLoc =~ /$par{"titleOut"}/)||($par{"titleOut"}=~/unk/))) {
	$tmp_strip="$idTitleLoc"."$extStrip";
	$tmp_hssp= "$idTitleLoc"."$extHssp";}
    else {
	if ($nFiles==1){
	    $tmp_strip="$idTitleLoc"."_"."$titleOriginal"."$extStrip";
	    $tmp_hssp= "$idTitleLoc"."_"."$titleOriginal"."$extHssp";
	    if ($par{"fileHsspTopits"}  ne "unk") {$tmp_hssp= $par{"fileHsspTopits"};}
	    if ($par{"fileStripTopits"} ne "unk") {$tmp_strip=$par{"fileStripTopits"};} }
	else {
	    if (($par{"fileHsspTopits"} ne "unk")&&
		($par{"fileHsspTopits"} !~ /$titleOriginal/)) {
		$tmp_hssp=$par{"fileHsspTopits"};}
	    else{$tmp_hssp="$idTitleLoc"."$extHssp";}
	    if (($par{"fileStripTopits"} ne "unk")&&
		($par{"fileStripTopits"} !~ /$titleOriginal/)) {
		$tmp_strip=$par{"fileStripTopits"};}
	    else{$tmp_strip="$idTitleLoc"."$extStrip";}}}
    if ($par{"fileMetric"} !~ /\// ) {$tmp="$PWD/".$par{"fileMetric"};
				       $par{"fileMetric"}=$tmp;}
    $file_tmpDssp=$fileDsspPhdLoc;
    if (length($chainLoc)>0){	# append chain (comes as _!_A)
	if ($chainLoc !~ /\_\!\_/){$file_tmpDssp.="_!_";}
	$file_tmpDssp.=$chainLoc;}
				# compile RMSD?
    if(defined $par{"LrmsdMaxhom"} && $par{"LrmsdMaxhom"}){$tmp_Lrmsd=1;}else{$tmp_Lrmsd=0;}
    if(defined $par{"Lindel1"} && $par{"Lindel1"}){$tmp_Lindel=1;}else{$tmp_Lindel=0;}
				# get arguments for MaxHom
    $command=
	&maxhomGetArg($file_tmpDssp,$par{"aliList"},$tmp_hssp,$par{"dirPdb"},
		      $par{"fileMetric"},$par{"smin"},$par{"smax"},$par{"go"},$par{"ge"},
		      $tmp_Lindel,$tmp_Lrmsd,$tmp_strip,$fileDefaultsMaxhom,$opt_nice);

    if ($Lscreen) {             print"--- maxhom: \t \t '",$command,"'\n"; }
				# ==================================================
				# run maxhom
				# ==================================================
    &run_program("$command");

    print"---\n","--- ^\n","--- | \n","--- + comment from Dr. Maxhom\n","."x 50,"\n";
				# note: to be deleted (from Maxhom)
				# move maxhom.x
    if ($par{"keepX"}){
	$in1="$idTitleLoc".".x";$in2="$idProtLoc".".x";
	$out=$par{"fileHsspTopits"};$out=~s/\.hssp.*$/\.x/;
	if    (-e $in1){$in=$in1;}
	elsif (-e $in2){$in=$in2;}
	($Lok,$txt)=&fileMv($in,$out,"STDOUT");}
    else {
	$tmp="$idTitleLoc".".x";push(@rm_files,$tmp);
	$tmp="$idProtLoc".".x";push(@rm_files,$tmp);}
	
    if (length($dirStrip)>1) { $new="$dirStrip"."$idTitleLoc"."$extStrip";
			       $old="$idTitleLoc"."$extStrip";
			       push(@mv_files,$old); $mv_files{"$old"}=$new;}
    if (length($dirHssp)>1)  { $new="$dirHssp"."$idTitleLoc"."$extHssp";
			       $old="$idTitleLoc"."$extHssp";
			       push(@mv_files,$old); $mv_files{"$old"}=$new;}
    if (length($dirWork)>1) {	# make security copy
	if (! -e $par{"fileHsspTopits"}){
	    ($Lok,$txt)=&fileCp($tmp_hssp,$par{"fileHsspTopits"},"STDOUT");
	    if (! $Lok){print "*** ERROR topits: runMaxhomTopits no $tmp_hssp\n";}}
	if (! -e $par{"fileStripTopits"}){
	    ($Lok,$txt)=&fileCp($tmp_strip,$par{"fileStripTopits"},"STDOUT");
	    if (! $Lok){print "*** ERROR topits: runMaxhomTopits no $tmp_strip\n";}}}
}				# end of runMaxhomTopits

#==========================================================================================
sub runPhd {
    local ($fileHssp,$exePhd,$exePhdFor,$opt_niceLoc,$chain)=@_;
    local ($arg,$exe,$fileRdb,$file_pred,$file_log,$fhtmp,$tmp);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   runPhd                      runs the PHD prediction
#--------------------------------------------------------------------------------
    if (! -e $fileHssp) { return 0;}
				# output of PHD
    if ((defined $dirWork)&&(length($dirWork)>3)){
	$file_log="$dirWork"."TOPITS_PHDLOG_".$$.".tmp";}
    else {$file_log="TOPITS_PHDLOG_".$$.".tmp";}

    if ((defined $chain) && (length($chain)>0)){
	$fileHssp_tmp=$fileHssp."_".$chain; }
    else {$fileHssp_tmp=$fileHssp; }

    $tmp=$fileHssp; $tmp=~s/.*\/|\.hssp.*$//g;
    $fileRdb=  "$dirWork"."TOPITSPhd_".$$.".rdbPhd";
    $file_pred="$dirWork"."TOPITSPhd_".$$.".pred";

    $arg=" $fileHssp_tmp both ARCH=$ARCHLOC rdb fileOutRdb=$fileRdb ".
	"noPhdHeader fileOutPhd=$file_pred exePhd=$exePhdFor ";

    if ((defined $dirWork)&&(length($dirWork)>3)){
	$arg.="dirWork=$dirWork ";}
    if (-e $par{"defaultsPhd"}) {
	$arg.="defaults=".$par{"defaultsPhd"}." ";}

    if (($opt_niceLoc eq "unk") || (! defined $opt_niceLoc) ){
	$arg.=" nonice"; $opt_niceLoc="";}
    else {$arg.=" $opt_niceLoc";$opt_niceLoc=~s/-/ -/;
	  $tmp=$opt_niceLoc;$tmp=~s/\s*nice\s*//g;$tmp=~s/-//g;
	  $exePhd="nice -$tmp ".$exePhd;}

    if ($Lscreen) {         print "--- system \t \t '$exePhd $arg >> $file_log'\n"; }
    # =============================
    system("$exePhd $arg > $file_log");
    # =============================
    if (-e $fileRdb) {	        # remove LOG and prediction file (only if output exists)
	if ($Lscreen) {$fhtmp="STDOUT";}else{$fhtmp="";}
	&file_rm($fhtmp,$file_pred,$file_log);
    }
    return ("$fileRdb");
}				# end of runPhd

#==========================================================================================
sub runPhd2Dssp {
    local ($fileRdb,$fileDsspPhd)=@_;
    local ($arg,$exe,$old,$new);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   exePhd2dssp               executes conversion of phd.rdb -> phd.dsspRdb
#   GLOBAL in/out              all
#--------------------------------------------------------------------------------
    if (! -e $fileRdb) { return 0;}
    $arg=" $fileRdb file_out=$fileDsspPhd";
    $exe="$opt_nice ".$par{"exePhd2dssp"}." ";
    if ($Lscreen) {         print "--- system \t \t '$exe $arg'\n"; }
    system("$exe $arg");
    if (length($dirPredOut)>1){$new="$dirPredOut".$fileDsspPhdLoc;
				 $old=$fileDsspPhdLoc;
				 push(@mv_files,$old); $mv_files{"$old"}=$new;}
    return 1;
}				# end of runPhd2Dssp

#==========================================================================
sub maxhomGetArg {
    local($fileMaxIn,$fileMaxList,$fileHsspLoc,$dirPdbLoc,
	  $metricLoc,$sminLoc,$smaxLoc,$goLoc,$geLoc,
	  $LindelLoc,$LsuperposLoc,$fileStripLoc,$maxhomDefaultLoc,$opt_niceLoc)=@_;
    local ($command,$exeLoc,$tmp,$indel_txt,$superpos_txt);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   gets the input arguments to run MAXHOM
#--------------------------------------------------------------------------------
				# process of the arguments
    $exeMaxLoc=$par{"exeMaxhom"};
    if ((defined $opt_niceLoc) && ($exeMaxLoc !~/\s*nice\s+/)) {
	if ( $opt_niceLoc=~/^nice/ ){
	    $tmp=$opt_niceLoc; $tmp=~s/nice|-|\s//g;
	    $exeLoc=" nice -"."$tmp "."$exeMaxLoc";}
	elsif ($opt_niceLoc=~/\d/) {
	    $tmp=$opt_niceLoc; $tmp=~s/\D|-|\s//g;
	    $exeLoc=" nice -"."$tmp "."$exeMaxLoc";}
	else {
	    $exeLoc=$exeMaxLoc;} }
    else {
	$exeLoc=$exeMaxLoc;}
    if ($LindelLoc)    { $indel_txt="YES"; }    else { $indel_txt="NO";}
    if ($LsuperposLoc) { $superpos_txt="YES"; } else { $superpos_txt="NO";}
    if ($par{"keepX"}) { $x_txt="YES";}         else { $x_txt="NO";}

    eval "\$command=\"$exeLoc -d=$maxhomDefaultLoc -nopar ,
         COMMAND             NO ,
         BATCH ,
         PID:                $$ ,
         SEQ_1               $fileMaxIn ,      
         SEQ_2               $fileMaxList ,
         PROFILE             NO ,
         METRIC              $metricLoc ,
         NORM_PROFILE        DISABLED , 
         MEAN_PROFILE        ignored ,
         FACTOR_GAPS         ignored ,
         SMIN                $sminLoc,
         SMAX                $smaxLoc,
         GAP_OPEN            $goLoc,
         GAP_ELONG           $geLoc,
         WEIGHT1             NO ,
         WEIGHT2             NO ,
         WAY3-ALIGN          NO ,
         INDEL_1             $indel_txt,
         INDEL_2             NO,
         RELIABILITY         NO ,
         FILTER_RANGE        10.0,
         NBEST               1 ,
         MAXALIGN            500 ,
         THRESHOLD           ALL ,
         SORT                zscore ,
         HSSP                $fileHsspLoc ,
         SAME_SEQ_SHOW       YES ,
         SUPERPOS            $superpos_txt ,
         PDB_PATH            $dirPdbLoc ,
         PROFILE_OUT         NO ,
         STRIP_OUT           $fileStripLoc ,
         LONG_OUT            $x_txt ,
         DOT_PLOT            NO ,
         RUN ,\"";
    return ($command);
}				# end maxhomGetArg
# 

