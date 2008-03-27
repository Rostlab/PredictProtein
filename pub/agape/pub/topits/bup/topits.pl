#!/usr/bin/perl -w
##!/bin/env perl 
#------------------------------------------------------------------------------#
# other perl environments
# 
# EMBL:
##!/usr/bin/perl -w
##!/usr/bin/perl5.00404 -w
#----------------------------------------------------------------------
# topits
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# comments
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# 
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# text markers
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#  - 'xx'         : to do, error break
#  - 'yy'         : to do at later stage
#  - 'HARD_CODED' : explicit names
#  - 'br date'    : changed on date
#  - 'hack'       : some hack 
#  - 
#  
#  
#  - $par{"kwd"}  : global parameters, available on command line by 'kwd=value'
#                               
#------------------------------------------------------------------------------#
#	Copyright				Dec,       	1993	       #
#	Burkhard Rost		rost@EMBL-Heidelberg.DE			       #
#	Wilckensstr. 15		http://www.embl-heidelberg.de/~rost/	       #
#	D-69120 Heidelberg						       #
#				version 0.5   	December,	1993	       #
#				version 0.7   	June,   	1995	       #
#				version 0.8   	August, 	1995	       #
#				version 0.9   	October, 	1995	       #
#				version 1.0   	May,    	1996	       #
#				version 1.1   	February,	1997	       #
#				version 2.0   	Oct,    	1998	       #
#------------------------------------------------------------------------------#
#
# --------------------------------------------------
# change to port
				# directory where phd.tar asf is situated
				# before doing the install (e.g. /home/you/)
$par{"dirHome"}="/home/rost/pub/";
				# final directory with PHD (from phd.tar)
$par{"dirTopits"}= $par{"dirHome"}. "topits/";

$ARCH_DEFAULT=  "SGI32";	# architecture to run PHD (SGI(5|32|64)|ALPHA|SUNMP)
#
# see sbr iniDef for further parameters
# --------------------------------------------------
#
				# --------------------------------------------------
				# sets array count to start at 1, not at 0
				# --------------------------------------------------
$[ =1 ;
				# --------------------------------------------------
				# initialise variables
				# --------------------------------------------------
$scrName=$0;$scrName=~s/^.*\/|\.pl//g; $sourceFile=$0;$sourceFile=~s/^\.\///g;
($Lok,$msg)=
    &ini;                       die ("*** ERROR $scrName: after ini\n".$msg) if (! $Lok);

# --------------------------------------------------------------------------------
# do the job (here we go)
# --------------------------------------------------------------------------------
				# ------------------------------
				# compute new metric file
				# ------------------------------
if ($par{"doReadMetricIn"}) {
    ($Lok,$msg,@tmp)=
	&topitsMakeMetric($par{"fileMetricIn"},$par{"fileMetricSeq"},$par{"fileMetric"},
			  $par{"mixStrSeq"},$par{"doMixStrSeq"},$par{"exeMakeMetric"},
			  $par{"dirWork"},$par{"titleTmp"},$par{"jobId"},$par{"debug"},
			  $par{"fileOutScreen"},$fhTrace);
                                return(&errScrMsg("failed on metric",$msg)) if (! $Lok);
    push(@rm_files,@tmp)        if ($#tmp > 0);}

print $fhTrace "--- default metric: '",$par{"fileMetric"},"'\n" 
    if ($Lscreen && ! $par{"doReadMetricIn"});
				# ------------------------------
				# check fold library
				# ------------------------------
if ($par{"doCheckAliList"}) {
    $fileAliList=$par{"dirWork"}.$par{"titleTmp"}."ALIlist_".".list";
    ($Lok,$msg,$Lmissing)=
	&topitsCheckLibrary($par{"aliList"},$fileAliList);
                                return(&errScrMsg("failed checking aliList",$msg)) if (! $Lok);

				# none are missing -> old list
    $fileAliList=$par{"aliList"} if (! $Lmissing);
				# some are missing -> new list
    push(@rm_files,$fileAliList) if ($Lmissing); }
else {
    $fileAliList=$par{"aliList"}; }


				# ------------------------------------------------------------
				# loop over list
				# ------------------------------------------------------------
$nfileIn=$#fileIn; $ctfileIn=0;
foreach $fileIn (@fileIn) {
    ++$ctfileIn;
				# ------------------------------
				# estimate time
    $estimate=&fctRunTimeLeft($timeBeg,$nfileIn,$ctfileIn);
    $estimate="?"           if ($ctfileIn < 5);
    printf 
	"--- %-40s %4d (%4.1f%-1s), time left=%-s\n",
	$fileIn,$ctfileIn,(100*$ctfileIn/$nfileIn),"%",$estimate;

				# --------------------------------------------------
				# get names for this file
				#     - exe PHD      if file is HSSP|MSF|SAF format
				#     - exe PHD2dssp if file is PHD.rdb
				#     - sets file names for MaxHom
				# $fileOut{$kwd}:
				#     topitsHssp | topitsHsspX | topitsStrip
				# 
				# --------------------------------------------------
    ($Lok,$msg,%fileOut)=
	&topitsPreprocess($fileIn,$idIn[$ctfileIn],$chainIn[$ctfileIn],$formatIn[$ctfileIn],
			  $ctfileIn,$par{"titleOut"},$par{"dirOut"},$par{"dirWork"},
			  $par{"extTopits"},$par{"extDsspPhd"},$par{"extRdb"},
			  $par{"extHssp"},$par{"extHsspX"},$par{"extStrip"},$par{"extExtr"}, # 
			  $par{"doKeepPhd"},$par{"exePhd"},$par{"exePhdFor"},$par{"optNice"},
			  $par{"doKeepDssp"},%fileOut);

				# --------------------------------------------------
				# no stop: give it a second chance...
				# --------------------------------------------------
				# (1) CASE: no output from preprocess
    if (! $Lok || ! -e $fileDsspPhd) {
	print 
	    "*** ERROR $scrName: preprocessing file=$fileIn failed:\n",
	    "***          topitsPreprocess($fileIn,$idIn[$ctfileIn],",
	    "$chainIn[$ctfileIn],$formatIn[$ctfileIn])\n",$msg,"\n","***>>>>> skipped!!!\n"; 
	next; }
				# (2) CASE: no maxhomTopits wanted
    if (! $par{"doMaxhomTopits"}) {
	print "--- \t \t '",$par{"exeMaxhomTopits"},"' is not executed \n" if ($Lscreen);
	next; }
				# --------------------------------------------------
				# maxhom threading!
				# --------------------------------------------------
    ($Lok,$msg)=
	&topitsRunMaxhom($fileDsspPhd,$fileOut{"topitsHssp"},
			 $fileOut{"topitsHsspX"},$fileOut{"topitsStrip"},
                         $par{"exeMaxhom"},$par{"fileMaxhomDefaults"},
                         $fileAliList,$par{"fileMetricSeq"},$par{"dirPdb"},$par{"LrmsdMaxhom"},
                         $par{"LprofIn2"},$par{"smin"},$par{"smax"},$par{"go"},$par{"ge"},
                         $par{"Lweight1"},$par{"Lweight2"},$par{"Lindel1"},$par{"Lindel2"},
                         $par{"nhitsMax"},$par{"threshold"},$par{"sortAlis"},$par{"LprofOut"},
                         $Date,$par{"optNice"},$par{"jobid"},$par{"fileOutScreen"},$fhTrace);
			 
                                &errScrMsg("failed threading for file=$fileDsspPhd".
					   ", in=$fileIn",$msg) if (! $Lok);
    if (! -e $fileOut{"topitsHssp"}) {
	print 
	    "*** $scrName: failed MaxHom Topits on fileIn=$fileDsspPhd, out=",
	    $fileOut{"topitsHssp"},"\n";
	next; }
				# del at end
    push(@rm_files,$fileOut{"topitsHsspX"}) if (! $par{"doKeepX"});


				# --------------------------------------------------
				# extract top nhitsSel hits
				#    - filter  HSSP
				#    - extract STRIP
				#    - write   TOPITS own
				# --------------------------------------------------
    ($Lok,$msg)=
	&topitsWrtHere();       return(&errScrMsg("failed final writing of TOPITS (ct=$ctfileIn)",
						  $msg)) if (! $Lok);

				# end of execution of maxhomTopits for one file
}
				# end of loop over list
				# ------------------------------------------------------------

&cleanUp if (! $par{"debug"});	# clean up

                                # ------------------------------
                                # final words
if ($Lverb) { 
    print "--- $scrName ended fine .. -:\)\n";
    $timeEnd=time;		# runtime , run time
    $timeRun=$timeEnd-$timeBeg;
    print 
	"--- date     \t \t $Date \n",
	"--- run time \t \t ",&fctSeconds2time($timeRun)," (hour:min:sec)\n";}


#==========================================================================
sub ini {
    $[ =1 ;
#----------------------------------------------------------------------
#   ini                         initialises defaults and reads input arguments
#----------------------------------------------------------------------

				# ------------------------------
    &iniDef();			# set general parameters

				# ------------------------------
    &iniEnv();			# set environment: @Date,$ARCH(LOC), $HOSTNAME, $USERID, $PATH

				# ------------------------------
    $timeBeg=     time;		# date and time
    $Date=        &sysDate();

				# ------------------------------
    %tmp=&iniHelpAdd();		# HELP stuff

	
    ($Lok,$msg)=		# want help?
	&brIniHelpLoop($scrName,
		     %tmp);     return(&errSbrMsg("after ini:iniHelpLoop",$msg)) if (! $Lok);
    exit if ($msg eq "fin"); 

				# ------------------------------
				# set the default values (PP specific)
				# ------------------------------
    &iniDefaultsPHD()           if ($LuserPHD);


				# --------------------------------------------------
				# get stuff from default file
				# --------------------------------------------------
    undef %defaults;
    if (! defined $par{"fileDefaults"} || ! -e $par{"fileDefaults"}) { # search default file
	$par{"fileDefaults"}=$par{"dirTopits"}."Defaults.topits"; 
	if (! -e $par{"fileDefaults"}){ 
	    $par{"fileDefaults"}="/home/rost/pub/topits/Defaults.topits"; }
	if (! defined $par{"fileDefaults"} || ! -e $par{"fileDefaults"}) {
	    print "*** STRONG WARNING $SBR: no defaults file found\n" x 3;} }
    if (defined $par{"fileDefaults"} &&  -e $par{"fileDefaults"}) {
	($Lok,$msg,%defaults)=
	    &brIniRdDef($par{"fileDefaults"}); 
	return(&errSbrMsg("failed reading default file ".$par{"fileDefaults"}..$msg)) if (! $Lok);
				# .......
				# warning
        print 
	    "-*- WARN $SBR: content of '",$par{"fileDefaults"},
	    "' may overwrite hard coded parameters\n" x 10 if (defined %defaults && %defaults);} 

				# ------------------------------
				# read command line arguments
				#    - check input file format
				#    - correct parameters
				# ------------------------------
    ($Lok,$msg)=
	&iniRdCmdLine();        return(&errSbrMsg("failed reading command line",$msg)) if (! $Lok);

				# ------------------------------
				# update executables
    foreach $kwd (keys %par){
	next if ($kwd !~ /^exe/);
	$par{$kwd}=~s/ARCH/$ARCH/; }

    
				# ------------------------------
				# error check for initial parameters
    ($Lok,$msg)=
	&iniError();		return(&errSbrMsg("failed error check",$msg)) if (! $Lok);

				# ------------------------------
				# nice level
    $opt_nice=$par{"optNice"};
    if ($opt_nice=~/nice-/){ $opt_nice=~s/nice-/nice -/;
			     $tmp=$opt_nice;$tmp=~s/\s|nice|\-|\+|no//g;
			     setpriority(0,0,$tmp)
				 if ($ARCH !~ /^SUNMP/ && length($tmp) > 0);}

                                # --------------------------------------------------
                                # trace file
                                # --------------------------------------------------
    if (defined $par{"fileOutTrace"} && $par{"fileOutTrace"} ne "unk" && 
        length($par{"fileOutTrace"}) > 0) {
        print "--- \t open $fhTrace for trace file ",$par{"fileOutTrace"}," \n"  if ($Lverb2);
        &open_file("$fhTrace",">".$par{"fileOutTrace"}) || 
            return(&errSbr("failed to open new file for trace : ".$par{"fileOutTrace"},$SBR));}
    else {
	$fhTrace="STDOUT";}
    $#kwdRm=0                   if (defined @kwdRm && $#kwdRm > 0);
				# ------------------------------
				# write settings
				# ------------------------------
    $exclude="kwd,dir*,ext*";	# keyword not to write
    $fhloc="STDOUT";
    $fhloc=$fhTrace             if (! $par{"debug"});
    ($Lok,$msg)=
	&brIniWrt($exclude,$fhloc);
                                return(&errSbrMsg("after lib-ut:brIniWrt",
						  $msg,$SBR))  if (! $Lok); 

                                # ------------------------------
    undef %tmp;			# clean memory

}				# end of ini

#===============================================================================
sub iniDef {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iniDef                      initialise defaults
#-------------------------------------------------------------------------------
                                # d.d
                                # ------------------------------
                                # default file
    $par{"fileDefaults"}=       "/home/rost/pub/topits/mat/Defaults.topits";
    $par{"fileMaxhomDefaults"}= "/home/rost/pub/topits/mat/Defaults.maxhom";

				# --------------------
				# directories
    $par{"dirHome"}=            "/home/rost/pub/";
    $par{"dirTopits"}=          $par{"dirHome"}.    "topits/";   # directory with all TOPITS scripts
    $par{"dirBin"}=             $par{"dirTopits"}.  "bin/";      # FORTRAN binaries of programs needed
    $par{"dirTopitsScr"}=       $par{"dirTopits"}.  "scr/";      # additional PERL and csh scripts
    $par{"dirTopitsMat"}=       $par{"dirTopits"}.  "mat/";      # additional material

    $par{"dirPerl"}=            $par{"dirTopitsScr"}             # perl libraries
        if (! defined $par{"dirPerl"});

				# PHD output to DSSP 
    $par{"dirPhd"}=             $par{"dirHome"}.    "phd/";      # dir with PHD stuff

				# data
    $par{"dirData"}=            "/home/rost/data/";
    $par{"dirPdb"}=             "/home/rost/data/pdb/";

    $par{"dirOut"}=             ""; # directory for output files
    $par{"dirWork"}=            ""; # working directory
#    $par{""}=                   "";
                                # further on work
				# --------------------
				# files
    $par{"title"}=              "unk";                           # output files may be called 'Pre-title.ext'
    $par{"titleOut"}=           "unk";                           # if given output file names will use
				                                 #    this title rather than the PDBid
    $par{"titleTmp"}=           "TOPITS_";                       # title for temporary files

    $par{"fileOut"}=            "unk";
    $par{"fileOutTrace"}=       $par{"titleTmp"}."TRACE"."jobid".".tmp";   # tracing some warnings and errors
    $par{"fileOutScreen"}=      $par{"titleTmp"}."SCREEN-"."jobid".".tmp"; # dumb out from system calls

    $par{"fileHelpMan"}=        "unk"; # file with manual
    $par{"fileHelpOpt"}=        "unk"; # file with options
    $par{"fileHelpHints"}=      "unk"; # file with hints, note: also passed as par{scrHelpHints}
    $par{"fileHelpProblems"}=   "unk"; # file with known problems, also passed as par{scrHelpProblems}
#    $par{""}=                   "";
				# file extensions
    $par{"preOut"}=             "Out-";
    $par{"extOut"}=             ".tmp";

    $par{"extStrip"}=           ".stripTopits";         # extension for MaxHom topits.strip output
    $par{"extHssp"}=            ".hsspTopits";	        # extension for MaxHom topits.hssp output 
    $par{"extHssp"}=            ".xTopits";	        # extension for MaxHom topits.hssp output 
    $par{"extTopits"}=          ".topits";              # extension for TOPITS own output
    $par{"extRdb"}=             ".rdbPhd";              # extension for PHD RDB files
    $par{"extDsspPhd"}=         ".dsspPhd";             # extension for PHD dssp file 
    $par{"extExtr"}=            "Extr";                 # extension added to extracted files

				# file handles
#    $fhout=                     "FHOUT";
#    $fhin=                      "FHIN";
    $fhTrace=                   "FHTRACE";

                                # --------------------
                                # job control
    $par{"jobid"}=              "jobid"; # unique job identifier (set to $$ if not defined)
    $par{"debug"}=              0; # if 1 : keep (most) temporary files
    $par{"verbose"}=$Lverb=     1; # blabla on screen
    $par{"verb2"}=$Lverb2=      0; # more verbose blabla

    $par{"optNice"}=            "nice -15";
#    $par{""}=                   "";

				# ------------------------------------------------------------
				# parameters: calling maxhom
				# ------------------------------------------------------------
    $par{"smin"}=              -1;      # minimal value of exchange metric
    $par{"smax"}=               1;      # maximal value of exchange metric
    $par{"go"}=                 2;	# gap open penalty
    $par{"ge"}=                 0.2;	# gap elongation penalty

    $par{"Lweight1"}=           0;      # weight guide sequence?
    $par{"Lweight2"}=           0;      # weight aligned sequence?

    $par{"Lindel1"}=            1;	# allow insertions in first sequence?
    $par{"Lindel2"}=            1;	# allow insertions in second sequence?

    $par{"aliList"}=                    # alignment list with PDB structures (DSSP files)
				        #    against which is searched
#	                        $par{"dirTopitsMat"}. "Topits_dssp438.list";
	                        $par{"dirTopitsMat"}. "Topits_dssp1213.list";


				# metric file (GIVE full path)
    $par{"fileMetricSeq"}=      $par{"dirTopitsMat"}. "Maxhom_McLachlan.metric"; # metric
                                        # sequence part (of the exchange metric)
    $par{"fileMetricGCG"}=      $par{"dirTopitsMat"}. "Maxhom_GCG.metric";       # metric
                                        # exchange metric used to compile conservation weights

    $par{"mixStrSeq"}=        50;	# ratio STR:SEQ 10-0: 10=100% struc; 5=50:50 struc:seq

    $par{"nhitsMax"}=        500;	# number of hits reported by MaxHom 
                                        #     note: too small values will corrupt the compilation
                                        #           of the final zscore!!!
                                        #     ->    rather use the parameter nhitsSel to reduce
                                        #           the final output file length!
    $par{"nhitsSel"}=         20;	# number of hits to be selected by filter_hssp, extr_strip
    $par{"LrmsdMaxhom"}=       0;	# compute RMSD values from MaxHom?
    $par{"threshold"}=         "ALL";   # apply MaxHom threshold? (do NOT!!)
    $par{"sortAlis"}=          "zscore"; # mode in which final alignments are sorted

    $par{"LprofOut"}=          0;       # MaxHom writes a profile (do NOT)
    $par{"LprofIn2"}=          0;       # second sequence is profile (do NOT)


				# further files (largely named automatically)
    foreach $des ("fileHsspTopits", "fileHsspTopitsExtr", "fileTopitsOwn",
		  "fileStripTopits","fileStripTopitsExtr","fileHsspXTopits",
		  "filePhdRdb","filePhdDssp") {
	$par{"$des"}=          "unk";}

				# ------------------------------
				# general + logicals
				# ------------------------------
    $par{"doConvPhd2dssp"}=     1;	# run conversion phd (.rdb) -> DSSP format?
    $par{"doMaxhomTopits"}=     1;	# run maxhom?
    $par{"doAcc3st"}=           0;	# align 3 accessibility states?
    $par{"doReadMetricIn"}=     0;	# metric is not computed on flight but read
    $par{"doMixStrSeq"}=        0;	# use a new ratio match_seq / match_str  ( (10-n) / n )
    $par{"doKeepDssp"}=         0;	# if 1 the DSSP file is forced kept
    $par{"doKeepPhd"}=          0;	# if 1 the PHD.rdb file is kept
    $par{"doKeepX"}=            0;	# if 1, Maxhom.x will be kept
    $par{"wrtOwn"}=             0;	# if 1, file.topits with header merging HSSP + sTRIP written
    $par{"doOutGzip"}=          0;      # directly gzip on output files?
    $par{"doCheckAliList"}=     1;      # if 1, then the fold library is checked,
				        #       i.e. a local version is run of those files that exist

				# ------------------------------
				# changing executables for 3state stuff
    if ($par{"doAcc3st"}) {     $par{"exeMaxhomTopits"}.="_3st"; }

				# --------------------
				# executables
    $par{"exeMaxhom"}=          $par{"dirBin"}.       "maxhom_big.".  "ARCH";
    $par{"exeMaxhomTopits"}=    $par{"dirTopitsScr"}. "maxhom_topits.csh";
    $par{"exeMakeMetric"}=      $par{"dirBin"}.       "make_metr2st."."ARCH";
    $par{"exePhd2dssp"}=        $par{"dirTopitsScr"}. "phd2dssp.pl";
    $par{"exeHsspFilter"}=      $par{"dirTopitsScr"}. "hssp_filter.pl";
    $par{"exeHsspFilterFor"}=   $par{"dirBin"}.       "filter_hssp." ."ARCH";
    $par{"exeHsspExtrStrip"}=   $par{"dirTopitsScr"}. "hssp_extr_strip.pl";
    $par{"exeHssp2pir"}=        $par{"dirTopitsScr"}. "hssp_extr_2pir.pl";
    $par{"exeTopitsWrtOwn"}=    $par{"dirTopitsScr"}. "topitsWrtOwn.pl";
    $par{"exePhd"}=             $par{"dirPhd"}.       "phd.pl";
    $par{"exePhdFor"}=          $par{"dirPhd"}.       "/bin/phd.".    "ARCH";
    $par{"defaultsPhd"}=        $par{"dirPhd"}.       "Defaults.phd";
#    $par{""}=                   "";
}				# end of iniDef

#===============================================================================
sub iniEnv {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iniEnv                      initialises environment variables
#	$date is e.g.:		Oct:14:13:06:47:1993
#	@Date is e.g.:		Oct1413:06:471993
#	&ctime(time) is e.g.:	Thu Oct 14 13:06:47 1993
#-------------------------------------------------------------------------------

				# ------------------------------
    $USERID=&sysGetUserHere();	# user

    $LuserPHD=0;
    $LuserPHD=1                 if (defined $USERID && $USERID eq "phd");

				# ------------------------------
    foreach $arg(@ARGV){	# highest priority ARCH
	if    ($arg=~/ARCH=(.*)$/)   {$ARCH=$ENV{'ARCH'}=$1;}
	elsif ($arg=~/PWD=(.*)$/)    {$PWD= $ENV{'PWD'}= $1;}
	elsif ($arg=~/dirLib=(.*)$/) {$dir=$1;} }
				
				# --------------------------------------------------
				# include libraries
				# --------------------------------------------------
    if ($USERID ne "phd"){
	$dir=$dir || "/home/rost/perl/" || $ENV{'PERLLIB'} || 
	    $par{"dirPerlLib"} || $par{"dirPerlLib"} || $par{"dirPerl"};
	$dir.="/"               if (-d $dir && $dir !~/\/$/);
	$dir= ""                if (! defined $dir || ! -d $dir); 

	foreach $lib("lib-ut.pl","lib-br.pl"){
	    require $dir.$lib ||
		die("*** $scrName: failed to require perl library '$lib' (dir=$dir)\n");}}
    else {
	push(@INC,$ENV{'PERLLIB'});

	require "/home/phd/ut/perl/lib-ut.pl";
	require "/home/phd/ut/perl/lib-prot.pl";
	require "/home/phd/ut/perl/lib-comp.pl";
	require "/home/phd/ut/perl/ctime.pl"; }

				# --------------------------------------------------
				# setenv ARCH 
				# --------------------------------------------------
    undef $ARCH;                # 
    foreach $arg (@ARGV) {      # given on command line?
        last if ($arg=~/^ARCH=(\S+)/i); }
    $ARCH=$1                    if (defined $1);
    $ARCH=~tr/[a-z]/[A-Z]/      if (defined $ARCH);	# lower to upper

                                # given in local env ?
    $ARCH=$ARCH || $ENV{'ARCH'} || $ARCH_DEFAULT;

				# ------------------------------
				# get local directory
    $PWD= $PWD || $ENV{'PWD'} || 
	do {open(C,"/bin/pwd|");$PWD=<C>;close(C);} || 
	    `pwd`;
    $PWD=~s/\/$//              if (defined $PWD && $PWD=~/\/$/);
    $PWD=~s/^\/tmp_mnt//;	# purge /tmp_mnt/  EMBL specific

    $pwd= $PWD                 if (defined $PWD);
    $pwd.="/"                  if (defined $pwd && $pwd !~ /\/$/);

}				# end of iniEnv

#===============================================================================
sub iniHelpAdd {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iniHelpAdd                  initialise help text
#-------------------------------------------------------------------------------
    $sbrName="iniHelpAdd";

    $scrIn=      "<DSSP|HSSP|MSF|SAF|PHD.rdb> (or <*.dssp_phd|file_dssp_phd.list>)";
    $scrGoal=    "runs TOPITS threading";
    $scrNarg=    1;
    $scrHelpTxt="";		# for additional help texts

                                # ------------------------------
				# standard help
    $tmp=$0; $tmp=~s/^\.\///    if ($tmp=~/^\.\//);
    %tmp=('sourceFile', $tmp, 'scrName',$scrName, 'scrIn',$scrIn, 'scrGoal', $scrGoal, 
	  'scrNarg',$scrNarg, 'scrHelpTxt', $scrHelpTxt);

                                # ------------------------------
				# missing stuff
    $tmp{"s_k_i_p"}=         "problems,manual,hints";

				# special help
    $tmp{"scrAddHelp"}=      "";

    $tmp{"special"}=         "";
    $tmp{"special"}.=        "list,verb,verb2,opt_nice,";
    $tmp{"special"}.=        "aliList,isAcc3st,";
    $tmp{"special"}.=        "check,"   if (! $par{"doCheckAliList"});
    $tmp{"special"}.=        "nocheck," if ($par{"doCheckAliList"});
    $tmp{"special"}.=        "fileMetric,fileMetricIn,aliList,";
    $tmp{"special"}.=        "str:seq,mixStrSeq,";
    $tmp{"special"}.=        "go,ge,smin,smax,noins,";
    $tmp{"special"}.=        "nhitsSel,";
    $tmp{"special"}.=        "keepX,keepDssp,keepPhd,wrtOwn";
    $tmp{"special"}.=        "fileRdb,titleOut,";
    $tmp{"special"}.=        "notMaxhomTopits,notPhd2dssp,";
    $tmp{"special"}.=        "exeMax,";
    $tmp{"special"}.=        ",";
        
    $tmp="---                      ";
#                            "------------------------------------------------------------\n";
    $tmp{"notMaxhomTopits"}= "<*|doMaxhomTopits=0> -> maxhomTopits not started";
    $tmp{"notPhd2dssp"}=     "<*|doConvPhd2dssp=0> -> assume DSSP format of PHD prediction exists";

    $tmp{"fileRdb"}=         "fileRdb=x        -> name of  RDB formatted PHD prediction";
    $tmp{"titleOut"}=        "titleOut=x       -> output files named: id.dssp_phd -> id\$title.strip";
    $tmp{"wrtOwn"}=          "<*|wrtOwn=1>     -> will write file.topits merging HSSP and STRIP header";

    $tmp{"aliList"}=         "aliList=x        -> as alignment list the list of DSSP file 'x' is used";
    $tmp{"isAcc3st"}=        "<*|doAcc3st=1    -> alignment based on accessibility in 3 states (def = 2)";
    $tmp{"check"}=           "<*|doCheckAliList=1> -> truncates fold library to existing files!";
    $tmp{"nocheck"}=         "<*|doCheckAliList=0> -> take fold library as is, no check!";

    $tmp{"fileMetric"}=      "fileMetric=x     -> metric for scoring the matches";
    $tmp{"fileMetricIn"}=    "fileMetricIn=x   -> generation of new metric file from input = x";

    $tmp{"keepX"}=           "<*|doKeepX=1>    -> 1 or 0, maxhom.x will be kept";
    $tmp{"keepDssp"}=        "<*|doKeepDssp=1> -> DSSP file not removed";
    $tmp{"keepPhd"}=         "<*|doKeepPhd=1>  -> PHD file not removed";

    $tmp{"str:seq"}=         "<str:seq=x|mixStrSeq=x> -> ratio for match_str vs. match_seq\n";
    $tmp{"str:seq"}.=   $tmp."       for n =0, 10, ..,100 => str:seq=n:(100-n)\n";
    $tmp{"str:seq"}.=   $tmp."       i.e. for e.g. mixStrSeq=30 -> 30% str , 70% seq\n";
    $tmp{"str:seq"}.=   $tmp."       \n";
    $tmp{"mixStrSeq"}=$tmp{"str:seq"};

    $tmp{"go"}=              "go=   REAL       -> gap open penalty";
    $tmp{"ge"}=              "ge=   REAL       -> gap elongation penalty";
    $tmp{"smin"}=            "smin= REAL       -> minimal value in comparison metric";
    $tmp{"smax"}=            "smax= REAL       -> maximal value in comparison metric";
    $tmp{"nhits"}=           "nhits=INT        -> extract nhitsSel first hits from output file";
    $tmp{"nhitsSel"}=        $tmp{"nhits"};
    $tmp{"noins"}=           "<*|Lindel1=0>    -> do NOT allow indels in guide (default: DO allow)";
    $tmp{"exeMax"}=          "exeMax=x         -> FORTRAN executable of MaxHom";

#    $tmp{""}=         "<*|=1> ->    ";

    $tmp{"opt_nice"}=        "<*|nice|optNice>=value  ->    'nice-n',  'nice' (=-4), or simply 'n'";
    $tmp{"list"}=            "<*|isList=1>     -> input file is list of files";
    $tmp{"verb"}=            "<*|verbose=1>    -> verbose output";
    $tmp{"verb2"}=           "<*|verb2=1>      -> very verbose output";

#                            "------------------------------------------------------------\n";

    $tmp{"zz"}=              "expl             -> action\n";
    $tmp{"zz"}.=        $tmp."    expl continue\n";

    $tmp{"special"}=~s/,*$//g;

#                            "------------------------------------------------------------\n";
    return(%tmp);
}				# end of iniHelpAdd

#===============================================================================
sub iniDefaultsPHD {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iniDefaultsPHD              initialise defaults (for PP)
#-------------------------------------------------------------------------------
    $par{"fileDefaults"}=       "/home/phd/ut/topits/Defaults.topits"
	if (! -e $par{"fileDefaults"});
    $par{"fileMaxhomDefaults"}= "/home/rost/ut/max/maxhom.defaults"
	if (! -e $par{"fileMaxhomDefaults"});

    $par{"dirTopits"}=          "/home/phd/ut/topits/";
    $par{"dirBin"}=             "/home/phd/bin/$ARCH/";
    $par{"dirBin"}=             "/home/phd/bin/$ARCH/";

    $par{"dirTopitsScr"}=       "/home/phd/ut/topits/scr/";
    $par{"dirTopitsMat"}=       "/home/phd/ut/topits/mat/";

    $par{"dirExeScripts"}=      "/home/phd/ut/perl/";
    $par{"dirExePhd"}=          "/home/phd/ut/phd/";

    $par{"exeMaxhom"}=          $par{"dirBin"}.       "maxhom_big";
    $par{"exeHsspFilterFor"}=   $par{"dirBin"}.       "filter_hssp";
    $par{"exePhdFor"}=          $par{"dirBin"}.       "phd";
    $par{"exeMakeMetric"}=      $par{"dirBin"}.       "make_metr2st";
    $par{"exeMaxhomTopits"}=    $par{"dirTopitsScr"}. "maxhom_topits.csh";

    $par{"exePhd2dssp"}=        $par{"dirTopitsScr"}. "phd2dssp.pl";
    $par{"exeHsspFilter"}=      $par{"dirTopitsScr"}. "hssp_filter.pl";
    $par{"exeHsspExtrStrip"}=   $par{"dirTopitsScr"}. "hssp_extr_strip.pl";

    $par{"exeHssp2pir"}=        $par{"dirTopitsScr"}. "hssp_extr_2pir.pl";
    $par{"exePhd"}=             $par{"dirExePhd"}.    "phd.pl";
    $par{"defaultsPhd"}=        $par{"dirExePhd"}.    "Defaults.phd";

#    $par{"aliList"}=            $par{"dirTopitsMat"}. "Topits_dssp438.list";
    $par{"aliList"}=            $par{"dirTopitsMat"}. "Topits_dssp849.list";
    $par{"fileMetricSeq"}=      $par{"dirTopitsMat"}. "Maxhom_McLachlan.metric";
    $par{"fileMetricGCG"}=      $par{"dirTopitsMat"}. "Maxhom_GCG.metric";

}				# end of iniDefaultsPHD

#===============================================================================
sub iniRdCmdLine {
    local($SBR);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iniRdCmdLine                read command line arguments
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR="iniRdCmdLine";
				# ------------------------------
				# read command line input
				# ------------------------------

    @argUnk=			# standard command line handler
	&brIniGetArg;
				# note: also returns @fileIn


				# ------------------------------
				# interpret specific command line arguments
    foreach $arg (@argUnk){	# ------------------------------

	next if ($arg=~/^(dirLib|ARCH|PWD|packName)=/);

				# convert new notation
	$arg=~s/^ali_l/aliL/;$arg=~s/^file_r/filePhdR/;$arg=~s/^file_metric_in/fileMetricIn/;
	$arg=~s/^title_out/titleOut/;$arg=~s/^title_in/titleIn/;
	$arg=~s/^(str\:seq|mix_strseq)/mixStrseq/;
	$arg=~s/^nhits_sel/nhitsSel/;$arg=~s/^ext_rdb/extRdb/;
	$arg=~s/^exe_maxhom_topits/exeMaxhomTopits/;$arg=~s/^exe_maxhom/exeMaxhom/;
	$arg=~s/^exe_make_metric/exeMakeMetric/;$arg=~s/^Lindel_1/Lindel1/;
	$arg=~s/^dir_in/dirIn/;$arg=~s/^dir_out/dirOut/;$arg=~s/^dir_work/dirWork/;

				# assign arguments
        if    ($arg=~/^list$/i)                   { $par{"isList"}=        1;}
	elsif ($arg=~/^nice-(\d+)$/)              { $par{"optNice"}=       "nice -".$1;}
	elsif ($arg eq "nonice")                  { $par{"optNice"}=       " ";}
	elsif ($arg =~ /^de?bu?g$/)               { $par{"debug"}=         1;}

	elsif ($arg=~/^(topitsDef.*|def.*)=(.+)/) {$par{"fileDefaults"}=$2;}

	elsif ($arg=~/^check$/i )                 { $par{"doCheckAliList"}=1;}
	elsif ($arg=~/^nocheck$/i )               { $par{"doCheckAliList"}=0;}

	elsif ($arg=~/^keep_?[Dd]ssp/ )           { $par{"doKeepDssp"}=    1;}
	elsif ($arg=~/^keepPhd/i )                { $par{"doKeepPhd"}=     1;}
	elsif ($arg=~/^keepX=0/ )                 { $par{"doKeepX"}=       0;}
	elsif ($arg=~/^keepX/ )                   { $par{"doKeepX"}=       1;}
	elsif ($arg=~/^wrtOwn/ )                  { $par{"wrtOwn"}=        1;}

	elsif ($arg=~/^fileMetric=([^=]+)$/)      { $par{"fileMetric"}=    $1;
						    $par{"fileMetric"}=    $PWD."/".$par{"fileMetric"}
						        if ($par{"fileMetric"} !~/$PWD/);}
	elsif ($arg=~/^fileMetricIn=([^=]+)$/)    { $par{"fileMetricIn"}=  $1;
						    $par{"doReadMetricIn"}=1; }
	elsif ($arg=~/^mixStrseq=([^=]+)$/ )      { $tmp=$1;$tmp=~s/[^0-9.]//g;
						    $par{"mixStrSeq"}=     int($tmp); 
						    $par{"doMixStrSeq"}=   1; }
	elsif ($arg=~/^extRdb=([^=]+)$/ )         { $par{"extRdb"}=".".    $1;}
	elsif ($arg=~/^go=([^=]+)$/ )             { $par{"go"}=            $1;}
	elsif ($arg=~/^ge=([^=]+)$/ )             { $par{"ge"}=            $1;}
	elsif ($arg=~/^smin=([^=]+)$/ )           { $par{"smin"}=          $1;}
	elsif ($arg=~/^smax=([^=]+)$/ )           { $par{"smax"}=          $1;}
	elsif ($arg=~/^noins$/i )                 { $par{""}=          $1;}

	elsif ($arg=~/^not_?[Mm]axhom_?[Tt]opits/){ $par{"doMaxhomTopits"}=0;}
	elsif ($arg=~/^not_?[Pp]hd2dssp/)         { $par{"doConvPhd2dssp"}=0;}
	elsif ($arg=~/^is_?[Aa]cc_?3st/)          { $par{"doAcc3st"}=      1;}
	elsif ($arg=~/^not_screen/ )              { $Lscreen=0; }
				# ------------------------------
				# output files
				# ------------------------------
	elsif ($arg=~/^file_?[Oo]ut=([^=]+)$/ ||
	       $arg=~/^fileOutTopitsHssp=(.+)$/i) { $fileOut{"topitsHssp"}= $1; }
	elsif ($arg=~/^file_?[Hh]ssp_?[Tt]opits=([^=]+)$/ ||
	       $arg=~/^fileOutTopitsHssp=(.+)$/i) { $fileOut{"topitsHssp"}= $1; }
	elsif ($arg=~/^file_?[Ss]trip_?[Tt]opits=([^=]+)$/ ||
	       $arg=~/^fileOutTopitsStrip=(.+)$/i){ $fileOut{"topitsStrip"}=$1; }
	elsif ($arg=~/^file_?[Pp]hd_?[Rr]db=([^=]+)$/ ||
	       $arg=~/^filePhdRdb=(.+)$/i)        { $fileOut{"phdRdb"}=     $1; }
	elsif ($arg=~/^file_?[Tt]opitsOwn=([^=]+)$/||
	       $arg=~/^fileOutTopitsOwn=(.+)$/i)  { $fileOut{"topitsOwn"}=  $1; }

				# ------------------------------
				# intermediate for PP
	elsif ($arg=~/^exe_phd2dssp=(.*)$/)       { $par{"exePhd2dssp"}=   $1;}
	elsif ($arg=~/^exe_phd=(.*)$/)            { $par{"exePhd"}=        $1;}
				# end of intermediate for PP
				# ------------------------------

	else  {
	    $Lok=0; 
	    $arg=~s/_[a-zA-Z0-9]$//g;
				# is chain
	    if (-e $arg) {
		push(@fileIn,$arg);
		$Lok=1;
		next; }
				# unrecognised argument
	    return(0,"*** ERROR $SBR: kwd '$arg' not understood\n");}}

    print "-*- WARNING iniGetArg: command line arguments overwrite '".$par{"fileDefaults"}."\n" 
	if ($par{"verbose"} && defined %defaults && %defaults);
        
				# ------------------------------
				# hierarchy of blabla
    $par{"verbose"}=1           if ($par{"verb2"});
	
    $Lverb= $par{"verbose"}     if (defined $par{"verbose"} && $par{"verbose"});
    $Lverb2=$par{"verb2"}       if (defined $par{"verb2"}   && $par{"verb2"});

    $Lscreen=    ! $par{"verbose"}; 

				# ------------------------------
				# directories: add '/'
    foreach $kwd (keys %par) {
	next if ($kwd !~/^dir/);
	next if (length($par{"$kwd"})==0 || $par{"$kwd"} eq "unk" );
	$par{"$kwd"}.="/"       if ($par{"$kwd"} !~ /\/$/);}

                                # --------------------------------------------------
                                # digest input file formats
                                # --------------------------------------------------
    return(0,"*** ERROR $SBR: no input file given!!\n") if ($#fileIn==0);

				# ------------------------------
				# (1) list ?
				# ------------------------------
    $#fileTmp=$#chainTmp=0;
    foreach $fileIn (@fileIn){
	if ($#fileIn==1 && ! $par{"isList"} || $fileIn !~/\.list/) {
	    push(@fileTmp,$fileIn);
	    push(@chainTmp,"*");
	    next; }
	($Lok,$msg,$file,$tmp)=
	    &fileListRd($fileIn);  
	if (! $Lok){ print "*** ERROR $scrName: after input list ($fileIn)\n",$msg,"\n";
		     exit; }

	@tmpf=split(/,/,$file); push(@fileTmp,@tmpf);
	@tmpc=split(/,/,$tmp);
	if ($#tmpc>0) { 
	    push(@chainTmp,@tmpc);}
	else { 
	    foreach $tmp (1..$#tmpf){
		push(@chainTmp,"*");}} }
    @fileIn= @fileTmp; @chainIn=@chainTmp; 
    $#fileTmp=$#chainTmp=0;	# slim-is-in

				# --------------------------------------
				# (2) purge chain
				# --------------------------------------
    foreach $fileIn (@fileIn) {
				# is chain id:  '1pdb.hssp_C'
	if ( ! -e $fileIn && $fileIn =~ /hssp_/) {
	    $fileIn=~s/hssp_(.)/hssp/;
	    $chain=$1;
	    push(@fileTmp,$fileIn); push(@chainTmp,$chain);
	    next; }
				# existing file
	elsif (-e $fileIn){
	    push(@fileTmp,$fileIn); push(@chainTmp,"*");
	    next; }
	else {
	    $fileInNoChain=$fileIn;
	    $fileInNoChain=~s/_(.)$//g;	# chain?
	    $chain=$1;
	    if (! -e $fileInNoChain){
		print "*** ERROR topits: missing input file '$fileIn' or '$fileInNoChain'\n";
		die "topits: missing input file";}
	    push(@fileTmp,$fileIn); push(@chainTmp,$chain); }}

    @fileIn= @fileTmp; @chainIn=@chainTmp; 
    $#fileTmp=$#chainTmp=0;	# slim-is-in

				# --------------------------------------
				# (3) input file format?
				# --------------------------------------
    $ct=0; $#formatIn=0;
    foreach $fileIn (@fileIn) {
	++$ct; $Lok=0;
	if    (&is_hssp  ($fileIn) ) { $formatIn="hssp"; $Lok=1; }
	elsif (&is_dssp  ($fileIn) ) { $formatIn="dssp"; $Lok=1; }
	elsif (&isMsf    ($fileIn) ) { $formatIn="msf";  $Lok=1; }
	elsif (&isSaf    ($fileIn) ) { $formatIn="saf";  $Lok=1; }
	elsif (&isPhdBoth($fileIn) ) { $formatIn="phd";  $Lok=1; } 
	if ($Lok && $formatIn eq "hssp" && &is_hssp_empty($fileIn)) {
	    print "*** WARN $SBR: empty HSSP file=$fileIn,\n";
	    next; }
				# file format unk
	return(&errSbr("can NOT handle format of fileIn=$fileIn",$SBR)) if (! $Lok);
				# ok
	push(@fileTmp,$fileIn); push(@chainTmp,$chainIn[$ct]); push(@formatIn,$formatIn); }

    @fileIn= @fileTmp; @chainIn=@chainTmp; 
    $#fileTmp=$#chainTmp=0;	# slim-is-in
    
				# --------------------------------------
				# (4) get id
				# --------------------------------------
    $#idIn=0;
    foreach $fileIn (@fileIn) {
	$id=$fileIn; $id=~s/^.*\/|\..*//g;
	push(@idIn,$id);}

				# --------------------------------------------------
				# correct settings
				# --------------------------------------------------

				# if file defined and exists then set logical
    $par{"doMixStrSeq"}=0       if (! defined $par{"fileMetricIn"} || ! -e $par{"fileMetricIn"});
    $par{"doMixStrSeq"}=1       if ( defined $par{"mixStrSeq"}    && $par{"doReadMetricIn"});

				# ------------------------------
				# MaxHom default file
				# ------------------------------
    $par{"fileMaxhomDefaults"}=
	$ENV{'MAXHOM_DEFAULT'}  if (! defined $par{"fileMaxhomDefaults"} || 
				    ! -e $par{"fileMaxhomDefaults"});
	
    if (! defined $par{"fileMaxhomDefaults"} || ! -e $par{"fileMaxhomDefaults"}) {
	if   (-e "maxhom.default") { $par{"fileMaxhomDefaults"}="maxhom.default";  }
	elsif(-e "Defaults.maxhom"){ $par{"fileMaxhomDefaults"}="Defaults.maxhom"; }
	else                       { $par{"fileMaxhomDefaults"}=
					 $par{"dirTopits"}."Defaults.maxhom"; } }
    if (! defined $par{"fileMaxhomDefaults"} || ! -e $par{"fileMaxhomDefaults"}) {
	$par{"fileMaxhomDefaults"}=  $par{"dirTopitsMat"}."Defaults.maxhom"; }

    return(&errSbr("no default file for maxhom found! (fileMaxhomDefaults=x",$SBR))
	if (! defined $par{"fileMaxhomDefaults"} || ! -e $par{"fileMaxhomDefaults"});
    
				# ------------------------------
				# give a safe metric file if no argument chosen
				# ------------------------------
    if ( ! $par{"doReadMetricIn"} && 
	(! defined $par{"fileMetric"} || ! -e $par{"fileMetric"}) ) { 
	if ($par{"mixStrSeq"}==100)  {
	    $par{"fileMetric"}=$par{"dirMetric"}."Topits_out.metric";}
	elsif ($par{"mixStrSeq"}==50){
	    $par{"fileMetric"}=$par{"dirMetric"}."Topits_50out.metric";}
	else { 
	    print"-*- WARNING \t \t no new metric generated\n",
	    "-*- WARNING \t \t mixStrSeq assumed to be =100 or =50, but is NOT!!\n";}
	print "-*- WARNING \t \t no metric file, take default:",$par{"fileMetric"},"\n";}

				# ------------------------------
				# correct for alpha
				# ------------------------------
    foreach $kwd (keys %par) {
	next if (! defined $par{"$kwd"});
	$par{"$kwd"}=~s/\s|\n//g;
	$par{"$kwd"}=~s/\/\//\//g; }

    return(1,"ok $SBR");
}				# end of iniRdCmdLine

#===============================================================================
sub iniError {
    local($SBR);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iniError                    error check for initial parameters
#-------------------------------------------------------------------------------
    $SBR="$scrName:"."iniError";
    $msg="";
				# ------------------------------
				# Maxhom default file
    $msg.= "*** ERROR topits:: no '".$par{"fileMaxhomDefaults"}."'\n"
	if (! -e $$par{"fileMaxhomDefaults"});
				# ------------------------------
				# MaxHom FORTRAN
    $msg.= "*** ERROR topits: no '".$par{"exeMaxhom"}."'\n"
	if (! -e $par{"exeMaxhom"} && ! -l $par{"exeMaxhom"});
				# ------------------------------
				# fold library
    $msg.= "*** ERROR topits: no '".$par{"aliList"}."'\n"
	if (! -e $par{"aliList"}) ;
				# ------------------------------
				# comparison metric
    if ($par{"doReadMetricIn"}) {
	$msg.= "*** ERROR topits: no file metricIn=".$par{"fileMetricIn"}.",\n"
	    if (! -e $par{"fileMetricIn"});
	$msg.= "*** ERROR topits: no exeMakeMetric=".$par{"exeMakeMetric"}.",\n"
	    if (! -e $par{"exeMakeMetric"} && ! -x $par{"exeMakeMetric"}); }

    elsif (! -e $par{"fileMetric"}){
	$msg.="*** ERROR topits: '".$par{"fileMetric"}."' missing\n"; }
				# ------------------------------
				# number of hits selected
    if ($par{"nhitsSel"} > 0) {
	$msg.= sprintf("*** %-20s '%-s'\n",
		       "ERROR topits: no exeHsspFilter=",$par{"exeHsspFilter"})
	    if (! -e $par{"exeHsspFilter"} && ! -l $par{"exeHsspFilter"});
	$msg.= sprintf("*** %-20s '%-s'\n",
		       "ERROR topits: no exeHsspExtrStrip=",
		       $par{"exeHsspExtrStrip"})
	    if (! -e $par{"exeHsspExtrStrip"} && ! -l $par{"exeHsspExtrStrip"}); }

				# ------------------------------
				# final message
				# ------------------------------
    return(&errSbrMsg("TOPITS failed during initialisation:",
		      $msg,$SBR)) if (length($msg) > 0);
    return(1,"ok");
}				# end of iniError

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
    print "--- \n--- now clean up files:\n" if ($Lscreen);

    push(@rm_files,$par{"exeMaxhomTopits"}) if ($par{"exeMaxhomTopits"}=~/^$par{"dirWork"}/);

    $tmp="MAXHOM.LOG_".$par{"jobid"};         push(@rm_files,$tmp);
    $tmp="MAXHOM_".    $par{"jobid"}.".temp"; push(@rm_files,$tmp);
    $tmp="MAXHOM_ALI.".$par{"jobid"};         push(@rm_files,$tmp);
    
    if ( $#rm_files > 0 && defined @rm_files) {
	foreach $tmp (@rm_files) {
	    $tmp=~s/\n//g; $tmp=~s/\s//g; 
	    next if ( ! defined $tmp || ! -e $tmp); 
				# avoid deleting important stuff!!
	    next if ($tmp =~/^($par{"dirTopits"}|$par{"dirBin"}|
			       $par{"dirExePhd"}|$par{"dirPerl"}|
			       $par{"dirData"}));
                                # security do NOT remove scripts asf!
	    next if ($tmp=~/^\/home\/.*\/topits/);

	    next if ( $tmp eq $ARGV[1] );

	    printf "--- %-20s %-s\n","system","'\\rm $tmp'"      if ($Lscreen);
	    unlink($tmp); }}
}				# end of cleanUp

#===============================================================================
sub sysGetUserHere {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   sysGetUserHere              returns $USER (i.e. user name)
#       out:                    USER
#-------------------------------------------------------------------------------
    $sbrName="lib-ut:"."sysGetUserHere";$fhinLoc="FHIN"."$sbrName";
    if (defined $ENV{'USER'}){
        return($ENV{'USER'});}
    $tmp=`whoami`;
    return($tmp) if (defined $tmp && length($tmp)>0);
    $tmp=`who am i`;            # SUNMP
    return($tmp) if (defined $tmp && length($tmp)>0);
    return(0);
}				# end of sysGetUserHere

#===============================================================================
sub topitsCheckLibrary {
    local($fileInLoc,$fileOutLoc) = @_ ;
    local($SBR,$fhinLoc,$fhoutLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   topitsCheckLibrary          truncates fold library to existing files
#       in:                     $fileInLoc:    current fold library
#       in:                     $fileOutLoc:   truncated version (if some missing)
#       out:                    1|0,$msg
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR="topitsCheckLibrary";  
    $fhinLoc="FHIN_"."topitsCheckLibrary";$fhoutLoc="FHOUT_"."topitsCheckLibrary";
    
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
    return(&errSbr("not def fileOutLoc!"))         if (! defined $fileOutLoc);

    return(&errSbr("miss in file '$fileInLoc'!"))  if (! -e $fileInLoc);
				# ------------------------------
				# open file
    &open_file("$fhinLoc","$fileInLoc") || 
	return(&errSbr("fileInLoc=$fileInLoc, not opened",$SBR));

    $#tmp=$ctMissing=0;
				# ------------------------------
    while (<$fhinLoc>) {	# read file
				# skip comments
	next if ($_=~/^[\s\t]*\#/);
	$_=~s/\n//g;
	next if (length($_)<1); # skip empty
				# purge chain
	$file=$_; $chain="";
	if ($_=~/(_?\!?_[A-Za-z0-9])/) {
	    $chain=$1;
	    $file=~s/$chain//g; } 
	if (! -e $file) {
	    ++$ctMissing;
	    print "-*- WARN $SBR: missing $file.$chain\n";
	    next; }
	push(@tmp,$file); 
    } close($fhinLoc);
				# ------------------------------
				# none missing?
    return(1,"ok $SBR",0);	# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

				# ------------------------------
				# some missing -> new file
				# ------------------------------
    &open_file("$fhoutLoc",">$fileOutLoc") || 
	return(&errSbr("fileOutLoc=$fileOutLoc, not created",$SBR));
    foreach $file (@tmp) {
	print $fhoutLoc "$file\n";}

    return(1,"ok $SBR",1);
}				# end of topitsCheckLibrary

#===============================================================================
sub topitsMakeMetric {
    local($fileMetricInLoc,$fileMetricInSeqLoc,$fileMetricOutLoc,
	  $mixStrSeqLoc,$doMixStrSeqLoc,$exeMakeMetricLoc,
	  $dirWorkLoc,$titleTmpLoc,$jobidLoc,$LdebugLoc,$fileOutScreenLoc,$fhTraceLoc) = @_ ;
    local($SBR);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   topitsMakeMetric            makes the BIG MaxHom metric to compare sequence
#                               and secondary structure
#                               
#       in:                     $fileMetricIn:       TOPITS metric (only structure)
#       in:                     $fileMetricInSeqLoc: MaxHom sequence metric (Blosum,McLachlan)
#       in:                     $fileMetricOutLoc:   final output metric
#       in:                     $mixStrSeqLoc:       integer percentage (0-100) 
#                                                    giving the ratio of structure to sequence:
#                               =100 -> structure, only
#                               = 50 -> half structure, half sequence
#                               =  0 -> sequence, only
#                               
#       in:                     $doMixStrSeqLoc:     redo the mix (default: take standard files)
#       in:                     $exeMakeMetricLoc:   FORTRAN executable to make metric
#       in:                     $dirWorkLoc:         working directory
#       in:                     $titleTmpLoc:        title for temporary files
#       in:                     $jobidLoc:           jobid
#       in:                     $LdebugLoc:          if 1: add temp files to-to-delete-array
#       in:                     $fileOutScreenLoc:   file getting output from system commands
#       in:                     $fhTraceLoc:         file handle to trace system errors
#                               
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR="topitsMakeMetric";
    $fhinLoc="FHIN_"."topitsMakeMetric";$fhoutLoc="FHIN_"."topitsMakeMetric";
				# ------------------------------
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
    return(&errSbr("not def fileMetricInSeqLoc!")) if (! defined $fileMetricInSeqLoc);
    return(&errSbr("not def fileMetricOutLoc!"))   if (! defined $fileMetricOutLoc);
    return(&errSbr("not def mixStrSeqLoc!"))       if (! defined $mixStrSeqLoc);
    return(&errSbr("not def doMixStrSeqLoc!"))     if (! defined $doMixStrSeqLoc);
    return(&errSbr("not def exeMakeMetricLoc!"))   if (! defined $exeMakeMetricLoc);
    return(&errSbr("not def dirWorkLoc!"))         if (! defined $dirWorkLoc);
    return(&errSbr("not def titleTmpLoc!"))        if (! defined $titleTmpLoc);
    return(&errSbr("not def jobidLoc!"))           if (! defined $jobidLoc);
    return(&errSbr("not def LdebugLoc!"))          if (! defined $LdebugLoc);
    return(&errSbr("not def fileOutScreenLoc!"))   if (! defined $fileOutScreenLoc);
    return(&errSbr("not def fhTraceLoc!"))         if (! defined $fhTraceLoc);
				# ------------------------------
				# file existence
    return(&errSbr("miss in file '$fileInLoc'!"))  if (! -e $fileInLoc);

    $screen="--- $SBR: came in with:\n";
				# ------------------------------
				# metric file (GIVE full path)
				# ------------------------------
    $pwdLoc.="/"                if ($pwdLoc !~ /\/$/);
    $fileMetricInLocTmp=  $dirWorkLoc.$titleTmpLoc."METRIC_".$jobIdLoc.".input";
    $fileMetricOutLocTmp= $dirWorkLoc.$titleTmpLoc."METRIC_".$jobIdLoc.".output";

				# ------------------------------
				# cp file to working directory
    ($Lok,$msg)=
	&sysCpfile($fileMetricInLoc,fileMetricInLocTmp);
		                return(&errSbrMsg("failed to copy: $fileMetricInLoc->".
						  "$fileMetricInLocTmp",$msg,$SBR)) if (! $Lok); 
				# ------------------------------
				# temporary files to delete
    @tmpFiles=($fileMetricInLocTmp,$fileMetricOutLocTmp) if (! $LdebugLoc);

				# --------------------------------------------------
				# append new ratio (FAC_STR=dd) to default input file
				# --------------------------------------------------
    if ($doMixStrSeqLoc) {
				# structure only
	if    ($mixStrSeqLoc==100) { 
	    $tmp_mix="FAC_STR=10"; }
				# sequence only
	elsif ($mixStrSeqLoc==50) { 
	    $tmp_mix="FAC_STR= 0"; }
				# half half
	elsif ($mixStrSeqLoc==50) { 
	    $tmp_mix="FAC_STR= 5"; }
				# somewhere in between
	else { 
	    $tmp_mix="FAC_STR= ".int($mixStrSeqLoc/10); }

				# ------------------------------
				# append new mix to temporary file
	($Lok,$msg,$tmp)=
	    &sysEchofile($tmp_mix,$fileMetricInLocTmp);
	                        return(&errSbrMsg("failed to echo ($tmp)",$msg)) if (! $Lok);
	$screen.=$tmp; }	# for screen message

	
				# --------------------------------------------------
				# do it: make the new metric
				# --------------------------------------------------
    $cmd=  $exeMakeMetricLoc." ".$fileMetricInLocTmp." ".$fileMetricOutLocTmp;
    $cmd.= " ".$fileMetricSeqLoc if ($fileMetricSeqLoc);
    $cmdEval="";		# avoid warnings
    eval      "\$cmdEval=\"$cmd\""; 

    ($Lok,$msg)=
	&sysRunProg($cmdEval,$fileOutScreenLoc,$fhTraceLoc);
                                 return(&errSbrMsg("failed making metric ($cmd)",
						   $msg,$SBR)) if (! $Lok); 

				# got it?
    return(&errSbrMsg("no metric $fileMetricOutLocTmp from system:\n".
		      $cmd."\n",$msg,$SBR)) if (! -e $fileMetricOutLocTmp);

				# --------------------------------------------------
				# keep or delete?
				# --------------------------------------------------
				# if metric file local, delete it in the end
    if (($fileMetricOutLoc !~ /home\/(phd|rost)/) &&
	$fileMetricOutLoc =~ /$dirWorkLoc/ ||
	$fileMetricOutLoc =~ /$jobIdLoc/){
	push(@tmpFiles,$fileMetricOutLoc); }
				# ------------------------------
				# cp file to working directory
    ($Lok,$msg)=
	&sysCpfile($fileMetricOutLocTmp,fileMetricOutLoc);
		                return(&errSbrMsg("failed to copy: $fileMetricOutLocTmp->".
						  "$fileMetricOutLoc",$msg,$SBR)) if (! $Lok); 
    return(1,"ok $SBR",@tmpFiles);
}				# end of topitsMakeMetric

#===============================================================================
sub topitsPreprocess {
    local ($fileInLoc,$idInLoc,$chainInLoc,$formatInLoc,$ctfileLoc,$titleOutLoc,$dirOutLoc,$dirWorkLoc,
	   $extTopitsLoc,$extDsspPhdLoc,$extRdbLoc,$extHsspLoc,$extHsspXLoc,$extStripLoc,$extExtrLoc,
	   $LdoKeepPhdLoc,$exePhdLoc,$exePhdForLoc,$optNiceLoc,$LdoKeepDsspLoc,%tmp) = @_ ;
    local ($SBR,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   topitsPreprocess            preprocesses the input files:
#                               (1) in = <HSSP|MSF|SAF> -> run PHD
#                               (2) in = <PHD.rdb>      -> run PHD2dssp
#                               (3) in = <DSSP>         -> nothing
#                               (4) assigns names of MaxHom output files
#                               
#       in:                     $fileInLoc :  input file (HSSP|MSF|SAF|DSSP|PHD)
#       in:                     $idInLoc:     PDBid of current protein
#       in:                     $chainInLoc:  chain identifier
#       in:                     $formatInLoc: file format (<hssp|msf|saf|dssp|phd>)
#       in:                     $ctfileLoc:   if > 1, write new names into %tmp whatever comes...
#       in:                     $titleOutLoc: title for output files
#                               
#       in:                     $dirOutLoc:   output dir
#       in:                     $dirWorkLoc:  working dir
#                               
#       in:                     $extTopitsLoc:  extension for final topits output
#       in:                     $extDsspPhdLoc: extension for DSSP
#       in:                     $extRdbLoc:   ext for PHD.rdb
#       in:                     $extHsspLoc:  ext for file.hssp
#       in:                     $extHsspXLoc: ext for file.x
#       in:                     $extStripLoc: ext for file.strip
#       in:                     $extExtrLoc:  ext added to extracted files
#                               
#       in:                     $LdoKeepPhdLoc:  
#       in:                     $exePhdLoc:  
#       in:                     $exePhdForLoc:  
#       in:                     $optNiceLoc:  
#       in:                     $LdoKeepDsspLoc:  
#                               
#       in:                     %tmp{'$kwd'}: names of MaxHom output files
#                               
#       out:                    1|0,msg,  implicit: %tmp{} names of output files
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR="topitsPreprocess";
				# check arguments
    return(&errSbr("not def fileInLoc!"))           if (! defined $fileInLoc);
    return(&errSbr("not def idInLoc!"))             if (! defined $idInLoc);
    return(&errSbr("not def chainInLoc!"))          if (! defined $chainInLoc);
    return(&errSbr("not def formatInLoc!"))         if (! defined $formatInLoc);
    return(&errSbr("not def titleOutLoc!"))         if (! defined $titleOutLoc);
    return(&errSbr("not def dirOutLoc!"))           if (! defined $dirOutLoc);
    return(&errSbr("not def dirWorkLoc!"))          if (! defined $dirWorkLoc);
    return(&errSbr("not def extTopitsLoc!"))        if (! defined $extTopitsLoc);
    return(&errSbr("not def extDsspPhdLoc!"))       if (! defined $extDsspPhdLoc);
    return(&errSbr("not def extRdbLoc!"))           if (! defined $extRdbLoc);
    return(&errSbr("not def extHsspLoc!"))          if (! defined $extHsspLoc);
    return(&errSbr("not def extHsspXLoc!"))         if (! defined $extHsspXLoc);
    return(&errSbr("not def extStripLoc!"))         if (! defined $extStripLoc);
    return(&errSbr("not def extExtrLoc!"))          if (! defined $extExtrLoc);
    return(&errSbr("not def LdoKeepPhdLoc!"))       if (! defined $LdoKeepPhdLoc);
    return(&errSbr("not def exePhdLoc!"))           if (! defined $exePhdLoc);
    return(&errSbr("not def exePhdForLoc!"))        if (! defined $exePhdForLoc);
    return(&errSbr("not def optNiceLoc!"))          if (! defined $optNiceLoc);
    return(&errSbr("not def LdoKeepDsspLoc!"))      if (! defined $LdoKeepDsspLoc);

#    return(&errSbr("not def !"))          if (! defined $);

    return(&errSbr("miss in file '$fileInLoc'!"))   if (! -e $fileInLoc);
    return(&errSbr("miss exe '$exePhdLoc'!"))       if (! -e $exePhdLoc && ! -l $exePhdLoc);
    return(&errSbr("miss exe '$exePhdForLoc'!"))    if (! -e $exePhdForLoc && 
							! -l $exePhdForLoc);

				# ------------------------------
				# output files wanted
				# ------------------------------
    @kwdFileOutLoc=
	("topitsHssp",     "topitsStrip",    "topitsHsspX",
	 "topitsHsspExtr", "topitsStripExtr","topitsOwn");

    $#tmpFiles=0;
				# ------------------------------
				# chain
    $chainInLoc="*"             if (length($chainInLoc) < 1 ||
				    length($chainInLoc) > 1 ||
				    $chainInLoc eq " ");

				# ------------------------------
				# these will change while we go...
    $fileInTmp=  $fileInLoc;
    $formatInTmp=$formatInLoc;
				# --------------------------------------------------
				# is <HSSP|MSF|SAF> -> do PHD
				# --------------------------------------------------
    if ($formatInTmp =~ /^(hssp|msf|saf)/) {
	$fileHssp=  $fileInTmp;
	if (defined $file{"filePhdRdb"} && $file{"filePhdRdb"} ne "unk" &&
	    $file{"filePhdRdb"} ne "0"  && $ctfileLoc < 2) {
	    $fileRdb=$file{"filePhdRdb"}; }
	else {
	    $fileRdb=   $dirWorkLoc.$idIn;
	    $fileRdb.=  $chainInLoc  if ($chainInLoc ne "*"); }
	push(@tmpFiles,$fileRdb) if (! $LdoKeepPhdLoc); 

	print "--- is <HSSP|MSF|SAF> ($fileInTmp) -> run PHD (out=$fileRdb)\n" if ($Lscreen);

	# ===============================================================================
	($Lok,$msg)=
	    &preRunPhd($fileHssp,$fileRdb,$exePhdLoc,$exePhdForLoc,$optNiceLoc);
	# ===============================================================================
	                        return(&errSbrMsg("failed to run phd (".$exePhdLoc.
						  " $fileHssp exe=$exePhdForLoc".
						  " chain=$chainInLoc",$msg,$SBR)) 
				    if (! $Lok || ! -e $fileRdb);
	$fileInTmp=  $fileRdb;
	$formatInTmp="phd";}

				# --------------------------------------------------
				# convert PHD.rdb to DSSP
				# --------------------------------------------------
    if ($formatInTmp =~ /^phd/) {
	$fileDssp=  $dirWorkLoc.$idIn;
	$fileDssp.= $chainInLoc   if ($chainInLoc ne "*");
	$fileDssp.= $extDsspPhdLoc;
	push(@tmpFiles,$fileDssp) if (! $LdoKeepDsspLoc); 

	($Lok,$msg)=
	    &preRunPhd2Dssp($fileRdb,$fileDssp); 
	                        return(&errSbrMsg("failed to convert phd.rdb=$fileRdb to ".
						  "dssp=$fileDssp",$msg,$SBR))
				    if (! $Lok || ! -e $fileDssp);
	$fileInTmp=  $fileDssp;
	$formatInTmp="dssp";}

				# --------------------------------------------------
				# everything fine?  should be DSSP by now
				# --------------------------------------------------
    return(&errSbr("failed to generate DSSP format from input=$fileInLoc, now=".
		   $fileInTmp,$SBR)) if ($formatInTmp !~/^dssp/);
    return(&errSbr("DSSP file missing from input=$fileInLoc, now=".
		   $fileInTmp,$SBR)) if (! -e $fileInTmp);

				# --------------------------------------------------
				# set file names for MaxHom output
				# --------------------------------------------------

    $titleTmp= $idInLoc;
    $titleTmp.="_".$chainInLoc  if ($chainInLoc ne "*");
    $titleTmp= $titleOutLoc     if (defined $titleOutLoc && $titleOutLoc ne "unk" &&
				    length($titleOutLoc) > 1 &&
				    $titleOutLoc ne "0");

				# ------------------------------
				# reset all output files if not
				#    defined 
				# ------------------------------
    foreach $kwd (keys %tmp) {
	$tmp{$kwd}=0            if ($ctfileLoc > 1       ||
				    ! defined $tmp{$kwd} ||
				    $tmp{$kwd} eq "unk"  ||
				    length($tmp{$kwd}) < 2); }

    foreach $kwd (@kwdFileOutLoc) {
				# defined name -> do not touch
	next if (defined $tmp{$kwd} && $tmp{$kwd});
				# not defined  -> name it
	$ext=$extStripLoc       if ($kwd =~ /strip/i);
	$ext=$extHsspXLoc       if ($kwd =~ /hsspX/i);
	$ext=$extHsspLoc        if ($kwd =~ /hssp/i);
	$ext=$extTopitsLoc      if ($kwd =~ /own/i);
	$ext.=$extExtrLoc       if ($kwd =~ /extr$/i);
	$ext=".".$ext           if ($ext !~ /^\./);
	
	$tmp{$kwd}=$dirOutLoc.$titleTmp.$ext; }

    return (1,"ok",%tmp);
}				# end of topitsPreprocess

#==========================================================================================
sub preRunPhd {
    local ($fileHssp,$fileRdb,$exePhd,$exePhdFor,$opt_niceLoc)=@_;
    local ($arg,$exe,$fileRdb,$filePhd,$filePhdLog,$tmp,$SBR);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   preRunPhd                   runs the PHD prediction
#--------------------------------------------------------------------------------
    $SBR="$scrName:"."preRunPhd";
				# input file existing?
    return(&errSbr("missing fileHssp=$fileHssp",$SBR)) if (! -e $fileHssp);

				# ------------------------------
				# build PHD output name
				# ------------------------------
    $filePhdLog=$par{"dirWork"}.$par{"titleTmp"}."PHDLOG_".$par{"jobid"}.".tmp";
    $tmp=$fileHssp; $tmp=~s/.*\/|\.hssp.*$//g;
    $filePhd=   $par{"dirWork"}.$par{"titleTmp"}."PHD_".$par{"jobid"}.".phd";

    $fileHssp_tmp= $fileHssp;
    $fileHssp_tmp.="_".$chain   if (defined $chain && length($chain)>0 && $chain ne "*");

				# ------------------------------
				# build up PHD input argument
				# ------------------------------

    $arg=  " $fileHssp_tmp both ARCH=$ARCH rdb fileOutRdb=$fileRdb";
    $arg.= " noPhdHeader fileOutPhd=$filePhd exePhd=$exePhdFor";
    $arg.= " jobId=".  $par{"jobid"};
    $arg.= " dirWork=".$par{"dirWork"} if (length($par{"dirWork"}) > 3 && 
					   $par{"dirWork"} !~ /^$pwd/);

				# do NOT run PHD niced
    if ($opt_niceLoc eq "unk" || ! defined $opt_niceLoc || $opt_niceLoc !~ /\d/) {
	$arg.= " nonice"; }
				# do run PHD nicely
    else {
	$arg.= " $opt_niceLoc";$opt_niceLoc=~s/-/ -/;
	  $tmp=$opt_niceLoc;$tmp=~s/\s*nice\s*//g;$tmp=~s/-//g;
				# change exe!!!
	  $exePhd="nice -$tmp ".$exePhd;}

				# ------------------------------
				# final command
    $cmd=$exePhd." ".$arg;
    $cmdEval="";		# avoid warning
    eval   "\$cmdEval=\"$cmd\""; 

    print "--- system '$exePhd $arg >> $filePhdLog'\n" if ($Lscreen);

				# ******************************
				# run PHD
    ($Lok,$msg)=
	&sysRunProg($cmdEval,$filePhdLog,$fhTrace);

                                return(&errSbr("failed PHD on $fileHssp ($fileHssp_tmp)\n".
					       $cmd."\n",$msg,$SBR))
				    if (! $Lok || ! -e $fileRdb); 
				# end of PHD
				# ******************************

				# ------------------------------
				# remove LOG and prediction file
				# ------------------------------
    if (! $par{"debug"}) {
	foreach $file ($filePhdLog,$filePhd) {
	    next if (! -e $file);
	    print "--- $SBR: remove $file\n" if ($Lscreen);
	    unlink($file);}}
    return (1,"ok");
}				# end of preRunPhd

#==========================================================================================
sub preRunPhd2Dssp {
    local ($fileRdb,$fileDsspPhd)=@_;
    local ($arg,$exe,$old,$new);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   preRunPhd2dssp             executes conversion of phd.rdb -> phd.dsspRdb
#   GLOBAL in/out              all
#--------------------------------------------------------------------------------
    return(0,"fileRdb=$fileRdb, missing\n") if (! -e $fileRdb);

				# ------------------------------
				# final command
    $cmd=  $par{"exePhd2dssp"}." $fileRdb file_out=$fileDsspPhd";
    $cmdEval="";		# avoid warning
    eval   "\$cmdEval=\"$cmd\""; 

    print "--- system '$cmd'\n" if ($Lscreen);

				# ------------------------------
				# run converter
    ($Lok,$msg)=
	&sysRunProg($cmdEval,$par{"fileOutScreen"},$fhTrace);

                                return(&errSbr("failed converting PHD.rdb=$fileRdb to $fileDsspPhd\n".
					       $cmd."\n",$msg,$SBR))
				    if (! $Lok || ! -e $fileDsspPhd); 
    return(1,"ok");
}				# end of preRunPhd2Dssp

#===============================================================================
sub topitsRunMaxhom {
    local ($fileHsspInLoc,$fileOutHssp,$fileOutStrip,$fileOutHsspX,
	   $exeMaxLoc,$fileMaxDefLoc,$fileAliListLoc,$fileMetricLoc,$dirPdbLoc,$paraSuperposLoc,
	   $LprofileLoc,$paraSminLoc,$paraSmaxLoc,$paraGoLoc,$paraGeLoc,$paraW1Loc,$paraW2Loc,
	   $paraIndel1Loc,$paraIndel2Loc,$paraNaliLoc,$paraThreshLoc,$paraSortLoc,$paraProfOutLoc,
	   $dateLoc,$niceLoc,$jobidLoc,$fileScreenLoc,$fhTraceLoc)=@_;
    local ($SBR,$maxCmd);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   topitsRunMaxhom             runs MaxHom in TOPITS fashion (no profile)
#                               
#       typical combinations:   
#                               Mc100: smin=-1.0, smax=3.0, go=3.0, ge=0.3
#                               Mc 50: smin=-1.0, smax=1.0, go=2.0, ge=0.2
#                               Mc  0: smin=-0.5, smax=1.0, go=3.0, ge=0.1
#                               
#                               Bl 50: smin=-1.0, smax=2.0, go=2.0, ge=0.2
#                               
#       in:                     $fileInLoc:     input file
#       in:                     $fileOutHssp:   output file.hssp
#       in:                     $fileOutStrip:  output file.strip
#                             =0  ->            no strip
#       in:                     $fileOutHsspX:  output file.x
#                             =0  ->            no X
#                               
#       in:                     $exeMaxLoc:     FORTRAN executable
#       in:                     $fileMaxDefLoc: maxhom defaults file
#       in:                     $fileAliList:   file with fold library (list of file names)
#                                               (now: must be DSSP format)
#       in:                     $fileMetricLoc: comparison metric
#       in:                     $dirPdbLoc:     PDB directory
#       in:                     $paraSuperpos:  compiles RMSd values
#                               
#       in:                     $LprofileLoc:   <1|0>                   (2nd is profile)
#       in:                     $paraSminLoc:   minimal value of metric (typical -1 )
#       in:                     $paraSmaxLoc:   maximal value of metric (typical  2 )
#                                               
#       in:                     $paraGoLoc:     gap open penalty        (typical  3.0)
#       in:                     $paraGeLoc:     gap extension/elongation penalty (typ 0.3)
#       in:                     $paraW1Loc:     weight seq 1            (typ yes)
#       in:                     $paraW2Loc:     weight seq 1            (typ yes)
#       in:                     $paraIndel1Loc: allow insertions/del in seq 1
#       in:                     $paraIndel2Loc: allow insertions/del in seq 1
#       in:                     $paraNaliLoc:   maximal number of alis reported (was 500)
#       in:                     $paraThreshLoc: thresholding reported alignments?
#       in:                     $paraSortLoc:   how to sort results
#       in:                     $paraProfOut:   
#       in:                     $dateLoc:       
#       in:                     $niceLoc:       
#       in:                     $jobidLoc:      number of current process
#       in:                     $fileScreenLoc: system calls dumped to this file
#       in:                     $fhTraceLoc:    handle for errors
#                               
#       out:                    <1|0>,$msg
#       err:                    ok=(1,'ok'), err=(0,'msg')
#--------------------------------------------------------------------------------

    $SBR="topitsRunMaxhom";
				# ------------------------------
				# check arguments
				# ------------------------------
    return(0,"*** $sbrName: not def fileInLoc!")        if (! defined $fileInLoc);
    return(0,"*** $sbrName: not def fileOutHssp!")      if (! defined $fileOutHssp);
    return(0,"*** $sbrName: not def fileOutStrip!")     if (! defined $fileOutStrip);
    return(0,"*** $sbrName: not def fileOutHsspX!")     if (! defined $fileOutHsspX);

    return(0,"*** $sbrName: not def exeMaxLoc!")        if (! defined $exeMaxLoc);
    return(0,"*** $sbrName: not def fileMaxDefLoc!")    if (! defined $fileMaxDefLoc);
    return(0,"*** $sbrName: not def fileAliListLoc!")   if (! defined $fileAliListLoc);
    return(0,"*** $sbrName: not def fileMetricLoc!")    if (! defined $fileMetricLoc);
    return(0,"*** $sbrName: not def dirPdbLoc!")        if (! defined $dirPdbLoc);
    return(0,"*** $sbrName: not def paraSuperposLoc!")  if (! defined $paraSuperposLoc);

    return(0,"*** $sbrName: not def LprofileLoc!")      if (! defined $LprofileLoc);
    return(0,"*** $sbrName: not def paraSminLoc!")      if (! defined $paraSminLoc);
    return(0,"*** $sbrName: not def paraSmaxLoc!")      if (! defined $paraSmaxLoc);
    return(0,"*** $sbrName: not def paraGoLoc!")        if (! defined $paraGoLoc);
    return(0,"*** $sbrName: not def paraGeLoc!")        if (! defined $paraGeLoc);
    return(0,"*** $sbrName: not def paraW1Loc!")        if (! defined $paraW1Loc);
    return(0,"*** $sbrName: not def paraW2Loc!")        if (! defined $paraW2Loc);
    return(0,"*** $sbrName: not def paraIndel1Loc!")    if (! defined $paraIndel1Loc);
    return(0,"*** $sbrName: not def paraIndel2Loc!")    if (! defined $paraIndel2Loc);
    return(0,"*** $sbrName: not def paraNaliLoc!")      if (! defined $paraNaliLoc);
    return(0,"*** $sbrName: not def paraThreshLoc!")    if (! defined $paraThreshLoc);
    return(0,"*** $sbrName: not def paraSortLoc!")      if (! defined $paraSortLoc);
    return(0,"*** $sbrName: not def paraProfOutLoc!")   if (! defined $paraProfOutLoc);

    return(0,"*** $sbrName: not def dateLoc!")          if (! defined $dateLoc);
    return(0,"*** $sbrName: not def niceLoc!")          if (! defined $niceLoc);
    return(0,"*** $sbrName: not def jobidLoc!")         if (! defined $jobidLoc);

    $fileScreenLoc=0                                      if (! defined $fileScreenLoc);
    $fhTraceLoc="STDOUT"                                  if (! defined $fhTraceLoc);
				# check existence of files
    return(0,"*** $sbrName: miss in file '$fileInLoc'!")      if (! -e $fileHsspInLoc);
    return(0,"*** $sbrName: miss in exe  '$exeMaxLoc'!")      if (! -e $exeMaxLoc);
    return(0,"*** $sbrName: miss in file '$fileMaxDefLoc'!")  if (! -e $fileMaxDefLoc);
    return(0,"*** $sbrName: miss in file '$fileAliListLoc'!") if (! -e $fileAliListLoc);
    return(0,"*** $sbrName: miss in file '$fileMetricLoc'!")  if (! -e $fileMetricLoc);

    $msgHere="--- $SBR: came to run TOPITS ($fileInLoc,$fileOutHssp)\n";
                                # --------------------------------------------------
                                # get command line argument for starting MaxHom
                                # --------------------------------------------------
    $maxCmd=
	&maxhomGetArg2($niceLoc,$exeMaxLoc,$fileMaxDefLoc,$jobidLoc,
		       $fileInLoc,$fileAliListLoc,$LprofileLoc,$fileMetricLoc,
		       $paraSminLoc,$paraSmaxLoc,$paraGoLoc,$paraGeLoc,
		       $paraW1Loc,$paraW2Loc,$paraIndel1Loc,$paraIndel2Loc,
		       $paraNaliLoc,$paraThreshLoc,$paraSortLoc,$paraProfOutLoc,$paraSuperposLoc,
		       $dirPdbLoc,$fileOutHssp,$fileOutStrip,$fileOutHsspX);
				# --------------------------------------------------
				# the thing that does IT!
				# --------------------------------------------------
    $msgHere.="--- $SBR: running MaxHom-Topits:\n".$maxCmd."\n";

    ($Lok,$msg)=
	&sysRunProg($maxCmd,$fileScreenLoc,$fhTraceLoc);
                                return(&errSbrMsg("failed on MaxHom \n".$maxCmd."\n".
						  "msgHere=\n".$msgHere."\n".
						  "*** msg from sys=",$msg,$SBR)) if (! $Lok);

    print "---\n","--- ^\n","--- | \n","--- + comment from Dr. Maxhom\n","."x 50,"\n";


				# ------------------------------
				# output ok?
				# ------------------------------
    return(&errSbr("failed making hssp $fileOutHssp, msgHere=\n".
		   $msgHere."\n",$SBR)) if (! -e $fileOutHssp);
    return(&errSbr("empty hssp $fileOutHssp, msgHere=\n".
		   $msgHere."\n",$SBR)) if (&is_hssp_empty($fileOutHssp));
    return(&errSbr("failed making strip $fileOutHssp, msgHere=\n".
		   $msgHere."\n",$SBR)) if (! -e $fileOutStrip);
    return(1,"ok $SBR");
}				# end topitsRunMaxhom


#===============================================================================
sub topitsWrtHere {
#    local($fileInLoc,$fhErrSbr) = @_ ;
    local($SBR,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   topitsWrtHere               gets final output files:
#                               (1) extract HSSP
#                               (2) extract STRIP
#                               (3) write TOPITS own
#                               
#       in|out GLOBAL:          all
#                               
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR="$scrName:"."topitsWrtHere";
    $fhinLoc="FHIN_"."topitsWrtHere";$fhoutLoc="FHOUT_"."topitsWrtHere";

				# --------------------------------------------------
				# extract hits
				# --------------------------------------------------
    if ($par{"nhitsSel"} > 0) {
	($Lok,$msg)=
	    &ass_extract();     $msg="*** ERROR $SBR: failed extracting from file ".
		                     "id=$idIn[$ctfileIn], in=$fileIn\n".$msg."\n" 
					 if (! $Lok);

				# mv files adjust names
	if ($Lok && ! $par{"doKeepOriginal"} &&
	    -e $fileOut{"topitsHssp"} && -e $fileOut{"topitsHsspExtr"}) {
	    print 
		"--- TOPITS: system 'mv ".$fileOut{"topitsHssp"}." ".$fileOut{"topitsHsspExtr"}."'\n"
		    if ($par{"verbose"});
	    ($Lok,$msg)=
		&sysMvfile($fileOut{"topitsHssp"},$fileOut{"topitsHsspExtr"});
	    $msg="*** ERROR $scrName: failed moving (ass_extract HSSP)\n".$msg."\n" if (! $Lok); }
	
	if (! $par{"doKeepOriginal"} &&
	    -e $fileOut{"topitsStrip"} && -e $fileOut{"topitsStripExtr"}) {
	    print 
		"--- TOPITS: system 'mv ".$fileOut{"topitsStrip"}." ".$fileOut{"topitsStripExtr"}."'\n"
		    if ($par{"verbose"});
	    ($Lok,$msg)=
		&sysMvfile($fileOut{"topitsStrip"},$fileOut{"topitsStripExtr"});
	    $msg.="*** ERROR $scrName: failed moving (ass_extract Strip)\n".$msg."\n" if (! $Lok); } 
    }

				# --------------------------------------------------
				# write TOPITS specific output
				# --------------------------------------------------
    if ($par{"wrtOwn"}){
	$Lok=1;
	if (! -e $fileOut{"topitsHssp"}){
	    print "*** TOPITS wanted to write format TOPITS, but no HSSP '".
		$fileOut{"topitsHssp"}."'\n"; $Lok=0;}
	if (! -e $fileOut{"topitsStrip"}){
	    print "*** TOPITS wanted to write format TOPITS, but no STRIP '".
		$fileOut{"topitsStrip"}."'\n"; $Lok=0;}
	if ($Lok){
	    if (! defined $fileOut{"topitsOwn"}){
		$fileOut{"topitsOwn"}=$fileOut{"topitsHssp"};
		$fileOut{"topitsOwn"}=~s/$par{"extHssp"}/$par{"extTopits"}/;}
	    
	    ($Lok,$msg)=
		&topitsWrtOwn($fileOut{"topitsHssp"},$fileOut{"topitsStrip"},
			      $fileOut{"topitsOwn"},$par{"mixStrSeq"},"STDOUT");
	    print "*** TOPITS failed to write its own:\n$msg\n" if (! $Lok); }
    }

    return(1,"ok $sbrName");
}				# end of topitsWrtHere

#==========================================================================================
sub ass_extract {
#    local ($nhitsSel,$idLoc,$exeHsspFilterFor,$fileMetricGCG) = @_ ;
    local ($SBR2);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   ass_extract                 extracts first nhitsSel hits from .hssp and .strip files
#                               
#       in|out GLOBAL:          all
#                               
#       err:                    (1,'ok'), (0,'message')
#--------------------------------------------------------------------------------
    $SBR2="$SBR:ass_extract";

    $cmdEval="";		# avoid warning

                                # ------------------------------
				# hssp
                                # ------------------------------
    if ($fileOut{"topitsHssp"}) {
				# build up command
	$cmd=  $par{"exeHsspFilter"}." ".$fileOut{"topitsHssp"};
	$cmd.= " fileOut=".$fileOut{"topitsHsspExtr"};
	$cmd.= " incl=1-".$nhitsSel;
	$cmd.= " not_screen"     if (! $par{"debug"} && ! $par{"verb2"});
	$cmd.= " exeFilterHssp=".$par{"exeHsspFilterFor"};
	$cmd.= " fileMatGcg=".   $par{"fileMetricGCG"};
	$cmd.= " dirWork=".      $par{"dirWork"} if (defined $par{"dirWork"}     && 
						     length($par{"dirWork"}) > 3 &&
						     $par{"dirWork"} !~ /$pwd/);
	eval   "\$cmdEval=\"$cmd\""; 
	print "--- system '$cmd'\n" if ($Lscreen);
				# run converter
	($Lok,$msg)=
	    &sysRunProg($cmdEval,$par{"fileOutScreen"},$fhTrace);
                                return(&errSbr("failed extracting HSSP\n".
					       $cmd."\n",$msg,$SBR2))
				    if (! $Lok || ! -e $fileOut{"topitsHsspExtr"}); 
	
                                # hack 2, br 25-08-95
	if ($USERID =~/phd/ && -e $fileOut{"topitsHsspExtr"}) {
	    $cmd="\\mv ".$fileOut{"topitsHsspExtr"}." ".$fileOut{"topitsHssp"};
	    print "--- system: \t \t '$cmd'\n" if ($Lscreen);
	    system("$cmd"); }}
                                # end hack 2, br 25-08-95

                                # ------------------------------
				# strip
                                # ------------------------------
    if ($fileOut{"topitsStrip"}) {
				# build up command
	$cmd=  $par{"exeHsspExtrStrip"}." ".$fileOut{"topitsStrip"};
	$cmd.= " fileOut=".$fileOut{"topitsStripExtr"};
	$cmd.= " incl=1-".$nhitsSel;
	$cmd.= " not_screen"     if (! $par{"debug"} && ! $par{"verb2"});
	$cmd.= " mix=".          $par{"mixStrSeq"} if ($USERID =~/phd/);
	$cmd.= " dirWork=".      $par{"dirWork"} if (defined $par{"dirWork"}     && 
						     length($par{"dirWork"}) > 3 &&
						     $par{"dirWork"} !~ /$pwd/);
	eval   "\$cmdEval=\"$cmd\""; 
	print "--- system '$cmd'\n" if ($Lscreen);
				# run converter
	($Lok,$msg)=
	    &sysRunProg($cmdEval,$par{"fileOutScreen"},$fhTrace);
                                return(&errSbr("failed extracting STRIP\n".
					       $cmd."\n",$msg,$SBR2))
				    if (! $Lok || ! -e $fileOut{"topitsStripExtr"}); 
	
                                # hack 2, br 25-08-95
	if ($USERID =~/phd/ && -e $fileOut{"topitsStripExtr"}) {
	    $cmd="\\mv ".$fileOut{"topitsStripExtr"}." ".$fileOut{"topitsStrip"};
	    print "--- system: \t \t '$cmd'\n" if ($Lscreen);
	    system("$cmd"); }}
                                # end hack 2, br 25-08-95
    return(1,"ok");
}				# end of ass_extract

