#!/usr/sbin/perl -w
##!/usr/bin/perl
#-------------------------------------------------------------------------------
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$scriptName=   "topits-jury";	# name of script
$scriptIn=     "list_of_dssp, or: *.dssp_phd, or: *.hssp_topits";		# input
$scriptTask=   "runs topits with different parameters, and compares results";	# task
$scriptNarg=   1;		# minimal number of input arguments
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# 		
# subroutines   (internal):  
#               x
#                                  y
# 		
#
#------------------------------------------------------------------------------#
#	Copyright				January,	1997	       #
#	Burkhard Rost		rost@EMBL-Heidelberg.DE			       #
#	EMBL			http://www.embl-heidelberg.de/~rost/	       #
#	D-69012 Heidelberg						       #
#				version 0.1   	January,	1997	       #
#------------------------------------------------------------------------------#
				# sets array count to start at 1, not at 0
$[ =1 ;
				# ------------------------------
				# include perl libraries
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
require "ctime.pl";
require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
				# ------------------------------
				# initialise variables
#@ARGV=split(/\s+/,&get_in_keyboard("command line"));	# x.x mac specific

$Lok=&ini;			# initialise variables
if (! $Lok){ die; }
&iniTopits;			# initialise arguments for TOPITS

#-------------------------------------------------------------------------------
# do the job (here we go)
#-------------------------------------------------------------------------------
				# ------------------------------
				# loop over all files
@fileIn=("$ARGV[1]");		# xx
@jobs=  ("Bl50",
	 "Mc50",
	 "Mc0",
	 "Mc100");
				# --------------------------------------------------
				# loop over all input files
				# --------------------------------------------------
foreach $fileIn (@fileIn){
    $id=$fileIn;$id=~s/^.*\/|\.dssp.*$//g;
				# ------------------------------
    if ($fileIn=~/^.*\//){	# make local copy
	$fileTmp=$fileIn;$fileTmp=~s/^.*\///g;$fileTmp=$par{"dirWork"}."$fileTmp";
	($Lok,$txt)=&fileCp($fileIn,$fileTmp,$Lverb); # external lib-ut.pl
	if (! $Lok){
	    print "*** ERROR $scriptName: couldnot copy $fileIn->$fileTmp\n";
	    next;}
	$fileIn=$fileTmp;push(@fileRm,$fileIn);}
				# --------------------------------------------------
    if ($par{"doTopits"}){	# run TOPITS
	if ($Lverb){ printf "--- %-20s %-s\n","topits for",$fileIn; }
	if (! $Lverb3){		# debug file for current job
	    $fileDebug=$par{"fileDebug"};$fileDebug=~s/(\.tmp.*)$/$id$1/;
	    push(@fileRm,$fileDebug);}
				# ------------------------------
	foreach $job (@jobs){	# different parameter settings
	    if (defined $jobs{"$job"}){
				# build up TOPITS input
		$command="";
		if ($par{"topitsNice"} ne "0"){	# nice topits.pl ?
		    $command.=" nice ".$par{"topitsNice"}." ";}
				# 'exe file arguments'
		$command.=$par{"exeTopits"}." ".$fileIn." ".$jobs{"$job"};
		if (! $Lverb3){	# debug file
		    $command.=" ".">> $fileDebug";}
#		print "xx:    \t$command";
				# ==============================
				# do run TOPITS
		&run_program("$command");
				# ==============================
		print "xx after topits \n";
	    }
	    else {
		print "*** argument not defined for job=$job,\n";}
	}
    }
}

#-------------------------------------------------------------------------------
# work done, go home
#-------------------------------------------------------------------------------
if (! $par{"debug"}){		# deleting intermediate files
    &cleanUp(@fileRm);}
if ($Lverb) { &myprt_empty; &myprt_line; &myprt_txt("$scriptName ended fine .. -:\)"); 
	      &myprt_txt("output files  \t ");
	      foreach $_(@fileOut){
		  if (-e $_){
		      printf "--- %-20s %-s\n"," ",$_;}}}

exit;

#===============================================================================
sub ini {
    local (@scriptTask,@scriptHelp,@scriptKwd,@scriptKwdDescr,$txt);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   initialises variables/arguments
#-------------------------------------------------------------------------------
#	$date is e.g.:		Thu Oct 14, 1993 13:06:47
#	@Date is e.g.:		Oct,14,13:06:47,1993
#	&ctime(time) is e.g.:	Thu Oct 14 13:06:47 1993
#
    @Date = split(' ',&ctime(time)) ; 
    $date="$Date[1] $Date[2] $Date[3], $Date[5] $Date[4]"; shift (@Date) ; 
    
    $PWD=                       $ENV{'PWD'}; $pwd=&complete_dir($PWD);
    $ARCH=                      $ENV{'ARCH'}; 
    if (!defined $ARCH) {	# search in command line
	foreach $_(@ARGV){if (/^ARCH=(\w+)$/){$ARCH=$1;$ARCH=~s/\n|\s//g;
					      last;}}}
    if (!defined $ARCH)       { print 
				    "-*- WARNING \t no architecture defined\n",
				    "-*- WARNING \t say 'setenv ARCH x'\n",
				    "-*-         \t with x=SGI5|SGI64|ALPHA|SUNMP|SUN4SOL2\n";}
    &iniDefaults;               # first settings for parameters (may be overwritten by
				# default file and command line input)
    &iniHelp;

    $Lok=&iniGetArg;		# read command line input
    if (! $Lok){print "*** ini ($scriptName) ERROR in  iniGetArg\n";
		return(0);}

    $Lok=&iniChangePar;
    if (! $Lok){print "*** ini ($scriptName) ERROR in  iniChangePar\n";
		return(0);}

    if ($Lverb){&myprt_line; 
		print "--- Settings of $scriptName are:\n--- \n"; 
		if ($#fileIn==1) {printf "--- %-20s '%-s'\n","fileIn:",$fileIn[1]; }
		else {&myprt_txt("input files:  \t ");
		      foreach $_(@fileIn){printf "--- %-20s '%-s'\n"," ",$_;}}
		if ($#fileOut==1){printf "--- %-20s '%-s'\n","fileOut:",$fileOut[1]; }
		else {&myprt_txt("output files:  \t ");
		      foreach $_(@fileOut){printf "--- %-20s '%-s'\n"," ",$_;}}
		foreach $kwd (@kwdDef) {
		    if (! defined $par{"$kwd"}){$tmp="!! UNDEF !!";}else{$tmp=$par{"$kwd"};}
		    printf "--- %-20s '%-s'\n",$kwd,$tmp;}&myprt_line;}

    # ------------------------------------------------------------
    # check existence of file
    # ------------------------------------------------------------
    $Lmiss=0;
    foreach $kwd(@kwdDef){
	if ($kwd =~/^(fileIn|exe)/){
	    if ((! -e $par{"$kwd"})&&(! -l $par{"$kwd"})){
		printf "*** %-20s '%-s'\n","MISSING $kwd",$par{"$kwd"};$Lmiss=1;}}}
    if ($Lmiss){
	print "*** try to locate the missing files/executables before continuing!\n";
	print "*** left script '$scriptName' after ini date: $date\n";
	return(0);}
    $#fileRm=0;			# intermediate files
    return(1);
}				# end of ini

#===============================================================================
sub iniHelp {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iniHelp                     initialise help text
#-------------------------------------------------------------------------------
    @scriptTask=   (" ",
		     "Task: \t $scriptTask",
		     " ",
		     "Input:\t $scriptIn",
		     " ",
		     "Done: \t ");
    @scriptHelp=   ("Help: \t For further information on input options asf., please  type:",
		     "      \t '$scriptName help'",
		     "      \t ............................................................");
    @scriptKwd=     (" ",
		     " ",
		     "title=",
		     " ",
		     "not_screen (verbose,verb2,verb3)",
		     "dirIn=",
		     "dirOut=",
		     "dirWork=",
		     );
    @scriptKwdDescr=(" ", 
		     " ",
		     " ",
		     "title of output files",
		     " ",
		     " ",
		     "no information written onto screen (NOTE avoid debug file with verb3!!)",
		     "input directory        default: local",
		     "output directory       default: local",
		     );

    if ( ($ARGV[1]=~/^help|^man|^-h/) ) { 
	print "-" x 80,"\n"; &myprt_txt("Perl script"); 
	foreach $txt (@scriptTask) {if($txt !~ /Done:/){&myprt_txt("$txt");}} 
	&myprt_txt("Optional:");
	foreach $kwdOpt(@kwdDef){
	    if (! defined $par{"$kwdOpt"}){$tmp="undef";}else{$tmp=$par{"$kwdOpt"};}
	    printf "--- %-12s=x \t (def:=%-s) \n",$kwdOpt,$tmp;}
	&myprt_empty; print "-" x 80,"\n"; die; }
    elsif ( $#ARGV < $scriptNarg ) {
	print "-" x 80,"\n"; &myprt_txt("Perl script"); 
	foreach $txt (@scriptTask) {if($txt !~ /Done:/){&myprt_txt("$txt");}} 
	&myprt_txt("Optional:");
	foreach $txt (@scriptHelp){&myprt_txt("$txt");}
	&myprt_empty;print"-" x 80,"\n";die;}
}				# end of iniHelp

#===============================================================================
sub iniDefaults {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iniDefaults                 initialise defaults
#-------------------------------------------------------------------------------
				# --------------------
				# directories
    $par{"dirIn"}=              ""; # directory with input files
    $par{"dirOut"}=             ""; # directory for output files
    $par{"dirWork"}=            ""; # working directory

    $par{"dirTopits"}=          "/home/rost/pub/topits/";        # topits central
    $par{"dirTopitsBin"}=       "/home/rost/pub/topits/bin/";    # binaries (metric asf)
    $par{"dirTopitsMat"}=       "/home/rost/pub/topits/mat/";    # material (metric asf)
    $par{"dirTopitsScripts"}=   "/home/rost/pub/topits/scr/"; # scripts (maxhom.csh)
    $par{"dirMaxhom"}=          "/home/rost/pub/max/";           # maxhom central
    $par{"dirMaxhomBin"}=       "/home/rost/pub/max/bin/";       # maxhom central
    $par{"dirMaxhomMat"}=       "/home/rost/pub/max/mat/";       # maxhom central
				# --------------------
				# input files
#    $par{"fileTopitsAliList"}=  $par{"dirTopitsMat"}     ."tmp.list";
#    $par{"fileTopitsAliList"}=  $par{"dirTopitsMat"}     ."Topits_dssp849.list";
    $par{"fileTopitsAliList"}=  $par{"dirTopitsMat"}     ."Topits_dssp1213.list";

    $par{"fileTopitsMetricMc"}= $par{"dirTopitsMat"}     ."Maxhom_McLachlan.metric";
    $par{"fileTopitsMetricBl"}= $par{"dirTopitsMat"}     ."Maxhom_Blosum.metric";
    $par{"fileTopitsMetricIn"}= $par{"dirTopitsMat"}     ."Topits_m3c_in.metric";
				# intermediate files
    $par{"fileDebug"}=          "TOPITS-JURY".$$.".tmp";
				# output files
    $par{"title"}=              "unk"; # output files will be called 'Pre-title.ext'
    $par{"fileOut"}=            "unk";
				# file extensions
    $par{"preOut"}=             "Out-";
    $par{"extOut"}=             ".tmp";
				# file handles
    $fhout=                     "FHOUT";
    $fhin=                      "FHIN";
				# --------------------
				# further
    $par{"topitsNhits"}=        100;   # number of selected hits in TOPITS output
    $par{"topitsKeepX"}=        0;     # keep the maxhom.x file?
				# run topits niced (set ="0" to avoid)
    $par{"topitsNice"}=         "0";
    $par{"topitsNice"}=         "-19";
    $par{""}=    

				# --------------------
				# logicals
    $Lverb=                     1; # blabla on screen
    $Lverb2=                    0; # more verbose blabla
    $Lverb3=                    0; # more verbose blabla
    $par{"debug"}=              0; # if 1, debug file(s) not deleted
    $par{"doTopits"}=           0; # if 1, topits is executed
    $par{"doTopits"}=           1; # if 1, topits is executed
				# --------------------
				# executables
    $par{"exeTopits"}=          $par{"dirTopits"}        ."topits.pl";
    $par{"exeTopitsMetric"}=    $par{"dirTopitsBin"}     ."make_metr2st".".".$ARCH;

    $par{"exeHsspFilter"}=      $par{"dirTopitsScripts"} ."hssp_filter.pl";
    $par{"exeHsspFilterBin"}=   $par{"dirTopitsBin"}     ."filter_hssp" .".".$ARCH;
    $par{"exeStripExtr"}=       $par{"dirTopitsScripts"} ."hssp_extr_strip.pl";

    $par{"exeMaxhomCsh"}=       $par{"dirTopitsScripts"} ."maxhom_topits.csh";
    $par{"exeMaxhomBin"}=       $par{"dirMaxhomBin"}     ."maxhom_big"  .".".$ARCH;
#    $par{"exeMaxhomBin"}=       $par{"dirMaxhomBin"}     ."maxhom"      .".".$ARCH;
				# ------------------------------
				# a.a descriptors 
				# allowed in default file
				# ------------------------------
    @kwdDef=     ("debug","verbose","verbose2","verbose3","dirIn","dirOut","dirWork",
		  "dirTopits","dirTopitsBin","dirTopitsMat","dirTopitsScripts",
		  "dirMaxhom","dirMaxhomBin","dirMaxhomMat",
		  "title","fileOut","preOut","extOut",
		  "exeTopits","exeTopitsMetric","exeMaxhomCsh","exeMaxhomBin",
		  "exeHsspFilter","exeHsspFilterBin","exeStripExtr","exeStripExtr",
		  "doTopits","fileTopitsAliList",
		  "fileTopitsMetricMc","fileTopitsMetricBl","fileTopitsMetricIn",
		  "topitsNhits","topitsKeepX","topitsNice",
		  "fileDebug",
		  "",
		   );
}				# end of iniDefaults

#===============================================================================
sub iniGetArg {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iniGetArg                   read command line arguments
#-------------------------------------------------------------------------------
    $Lokdef=0; $#fileIn=$#tmp=0;
    foreach $arg (@ARGV){	# key word driven input
	if    ($arg=~/^verb\w*3/){$Lverb3=1;}
	elsif ($arg=~/^verb\w*2/){$Lverb2=1;}
	elsif ($arg=~/^verbose/) {$Lverb=1;}
	elsif ($arg=~/not_(ver|screen)/ ) {$Lverb=0; }
	else {			# general
	    $Lok=0;
	    foreach $kwd (@kwdDef){
		if ($arg=~/^$kwd=(.+)$/){$tmp=$1;$tmp=~s/\s//g;
					 if ($kwd =~/^dir/){ # add '/' at end of directories
					     $tmp=&complete_dir($tmp);}	# external lib-ut.pl
					 $par{"$kwd"}=$tmp; $Lok=1;$Lokdef=1;
					 last;}}
	    if    ((! $Lok)&&($arg=~/=/)){
		print "*** iniGetArg: unrecognised argument: $arg\n";
		return(0);}
	    elsif ((! $Lok)&&(-e "$arg")){ # input file?
		push(@fileIn,$arg);}
	    elsif (!$Lok){	# possibly add dirIn
		print "x.x still missing '$arg'\n";
		push(@tmp,$arg);}}}
    foreach $tmp (@tmp){	# check unrecognised input arguments
	$tmp1=$par{"dirIn"}.$tmp;
	if (-e "$tmp1"){push(@fileIn,$tmp1);}
	else { print "*** iniGetArg: unrecognised argument(2): '$tmp'\n";
	       return(0);}}
    return(1);
}				# end of iniGetArg

#===============================================================================
sub iniChangePar {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iniChangePar                changing parameters according to input arguments
#                               e.g. adding directories to file names asf
#-------------------------------------------------------------------------------
    $#tmp=0;			# purge empty keywords
    foreach $kwd (@kwdDef){
	push(@tmp,$kwd) unless ((! defined $kwd)||(length($kwd)<1));}
    @kwdDef=@tmp;
				# ------------------------------
				# add input directory
    if ((defined $par{"dirIn"})&&($par{"dirIn"} ne "unk")&&($par{"dirIn"} ne "local")&&
	(length($par{"dirIn"})>1)){
	foreach $fileIn(@fileIn){
	    if (! -e "$fileIn"){
		$fileIn=$par{"dirIn"}.$fileIn;}
	    if (! -e "$fileIn"){
		print "*** iniChangePar: no in file=$fileIn, dirIn=",$par{"dirIn"},",\n";
		return(0);}}} 
				# ------------------------------
    foreach $kwd (@kwdDef){	# add 'pre' 'title' 'ext'
	if ($kwd=~/^fileOut/){
	    if ((!defined $par{"$kwd"})||($par{"$kwd"} eq "unk")){
		$kwdPre=$kwd; $kwdPre=~s/file/pre/; 
		if (defined $par{"$kwdPre"}){$pre=$par{"$kwdPre"};}else{$pre="";}
		$kwdExt=$kwd; $kwdExt=~s/file/ext/; 
		if (defined $par{"$kwdExt"}){$ext=$par{"$kwdExt"};}else{$ext="";}
		if ((! defined $par{"title"})||($par{"title"} eq "unk")){
		    $par{"title"}=$scriptName;}
		$par{"$kwd"}=$pre.$par{"title"}.$ext;}}}
				# ------------------------------
				# add output directory
    if ((defined $par{"dirOut"})&&($par{"dirOut"} ne "unk")&&($par{"dirOut"} ne "local")&&
	(length($par{"dirOut"})>1)){
	if (! -d $par{"dirOut"}){ # make directory
	    if ($verb){@tmp=("STDOUT",$par{"dirOut"});}else{@tmp=($par{"dirOut"});}
	    ($Lok,$txt)=&dirMk(@tmp); } # external lib-ut.pl
	foreach $kwd (@kwdDef){
	    if ($kwd=~/^fileOut/){
		if ($par{"$kwd"} !~ /^$par{"dirOut"}/){
		    $par{"$kwd"}=$par{"dirOut"}.$par{"$kwd"};}}}}
				# ------------------------------
				# push array of output files
    if (! defined @fileOut){$#fileOut=0;}
    foreach $kwd (@kwdDef){
	if ($kwd=~/^fileOut/){
	    push(@fileOut,$par{"$kwd"});}}
				# ------------------------------
				# add working directory
    if ((defined $par{"dirWork"})&&($par{"dirWork"} ne "unk")&&($par{"dirWork"} ne "local")&&
	(length($par{"dirWork"})>1)){
	if (! -d $par{"dirWork"}){ # make directory
	    if ($verb){@tmp=("STDOUT",$par{"dirWork"});}else{@tmp=($par{"dirWork"});}
	    ($Lok,$txt)=&dirMk(@tmp); } # external lib-ut.pl
	foreach $kwd (@kwdDef){
	    if ($kwd=~/^fileDebug/){
#	    if (($kwd=~/^file/)&&($kwd!~/^fileIn/)&&($kwd!~/^fileOut/)){
		if ($par{"$kwd"} !~ /^$par{"dirWork"}/){
		    $par{"$kwd"}=$par{"dirWork"}.$par{"$kwd"};}}}}
				# ------------------------------
				# array of Work files
    if (! defined @fileWork){$#fileWork=0;}
    foreach $kwd (@kwdDef){
	if ($kwd=~/^fileDebug/){
	    push(@fileWork,$par{"$kwd"});}}
				# ------------------------------
				# blabla
    if ((defined $par{"verbose"}) &&($par{"verbose"})) {$Lverb=1; }
    if ((defined $par{"verbose2"})&&($par{"verbose2"})){$Lverb2=1;}
    if ((defined $par{"verbose3"})&&($par{"verbose3"})){$Lverb3=1;}
				# ------------------------------
				# add directory to executables
    foreach $kwd (@kwdDef){
	if (($kwd=~/^exe/)&&(defined $par{"$kwd"})&&(! -e $par{"$kwd"})&&(! -l $par{"$kwd"})){
	    $par{"$kwd"}=$par{"dirPerl"}.$par{"$kwd"};}}
    return(1);
}				# end of iniChangePar

#===============================================================================
sub iniTopits {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iniTopits                   initialises the arguments to run TOPITS
#       GLOBAL in/out:                 
#-------------------------------------------------------------------------------
				# parameters for TOPITS
    %jobs=  
	("Bl50"   => "go=2 ge=0.2 Lindel1=0 smin=-1 smax=2 mixStrseq=50 ".
	             " fileMetricSeq=".$par{"fileTopitsMetricBl"}.
	             " fileMetricIn=".$par{"fileTopitsMetricIn"}." ",
	 "Mc50"   => "go=2 ge=0.2 Lindel1=1 smin=-1 smax=2 mixStrseq=50 ".
	             " fileMetricSeq=".$par{"fileTopitsMetricMc"}.
	             " fileMetricIn=".$par{"fileTopitsMetricIn"}." ",
	 "Mc0"    => "go=3 ge=0.1 Lindel1=0 smin=-0.5 smax=1 mixStrseq=0 ".
	             " fileMetricSeq=".$par{"fileTopitsMetricMc"}.
	             " fileMetricIn=".$par{"fileTopitsMetricIn"}." ",
	 "Mc100"  => "go=2 ge=0.2 Lindel1=1 smin=-1 smax=3 mixStrseq=100 ".
	             " fileMetricSeq=".$par{"fileTopitsMetricMc"}.
	             " fileMetricIn=".$par{"fileTopitsMetricIn"}." "
	 );
				# additional arguments (common to all)
    $argAdd= 
	"exe_make_metric=".$par{"exeTopitsMetric"}." ".
	    "exe_maxhom_topits=".$par{"exeMaxhomCsh"}." ".
		"exe_maxhom=".$par{"exeMaxhomBin"}." " .
		    "ali_list=".$par{"fileTopitsAliList"}." ".
			"nhits_sel=".$par{"topitsNhits"}." ".
			    "keepX=".$par{"topitsKeepX"}." ".
				"dir_out=".$par{"dirWork"}." ".
				    "not_screen";
    if ($par{"topitsNice"} ne "0"){
	$argAdd.=" opt_nice=".$par{"topitsNice"};}

    @keys=keys %jobs;
    foreach $key (@keys){
	$jobs{"$key"}=$argAdd." ".$jobs{"$key"}." "."titleOut=-$key";}
}				# end of iniTopits

#===============================================================================
sub cleanUp {
    local(@fileLoc)=@_;
    local($sbrName,$fhinLoc,@tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#    cleanUp                    deletes intermediate files
#-------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";} $sbrName="$tmp"."cleanUp";
    if ($#fileWork>0){		# remove intermediate files
	if ($Lverb){@tmp=("STDOUT",@fileLoc);}else{@tmp=(@fileLoc);}
	($Lok,@tmp)=
	    &fileRm(@tmp);}	# external lib-ut.pl
}				# end of cleanUp

#===============================================================================
sub subx {
#    local ($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   subx                       
#         c
#       in:                     
#         A                     A
#       out:                    
#         A                     A
#-------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";}
    $sbrName="$tmp"."subx";$fhinLoc="FHIN"."$sbrName";

    $Lok=&open_file("$fhinLoc","$fileInLoc");
    if ($Lok){
	while (<$fhinLoc>) {
	    $_=~s/\n//g;
	    if (length($_)==0){
		next;}
	}
	close($fhinLoc);}

}				# end of subx

