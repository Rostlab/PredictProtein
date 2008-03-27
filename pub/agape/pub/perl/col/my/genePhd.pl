#!/bin/env perl
#------------------------------------------------------------------------------#
# other perl environments
# EMBL
##!/usr/sbin/perl4 -w
##!/usr/sbin/perl -w
# EBI
##!/usr/bin/perl -w
#------------------------------------------------------------------------------#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$scriptName=   "genePhd.pl";
$scriptIn=     "1st= auto (read hssp dir) or = list-hssp";
$scriptTask=   "runs PHD jobs for entire genome";
$scriptNarg=   1;
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# subroutines   (internal):  
#
#------------------------------------------------------------------------------#
#	Copyright				May,    	1997	       #
#	Burkhard Rost		rost@EMBL-Heidelberg.DE			       #
#	EMBL			http://www.embl-heidelberg.de/~rost/	       #
#	D-69012 Heidelberg						       #
#				version 0.1   	May,    	1997	       #
#				version 0.11   	Feb,    	1998	       #
#------------------------------------------------------------------------------#
				# sets array count to start at 1, not at 0
$[ =1 ;
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
require "ctime.pl";
require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
				# intermediate x.x

#@ARGV=split(/\s+/,&get_in_keyboard("command line"));	# x.x mac specific
#$ARGV[1]="spl1-ec9802-id.list";

				# ------------------------------
$Lok=&ini;			# initialise variables
if (! $Lok){ die; }

#-------------------------------------------------------------------------------
# do the job (here we go)
#-------------------------------------------------------------------------------
$LcleanUp=0; $LcleanUp=1 if (! $debug);
				# --------------------------------------------------
				# orientation what is there OR read seq ids
				# --------------------------------------------------

$Lok=&getIdList($ARGV[1]);	# recognise: auto, or file with ids
				# output: @id,@hssp,$res{"$id","hssp"}= isHssp/empty/..
				#         @hsspEmpty
				# wrong command line
if (!$Lok) {print "*** ERROR $scriptName first argument: file with sequences ids or 'auto'\n";
	    print "*** ERROR is '$ARGV[1]'\n";
	    die '*** wrong first argument ';}

if ($Lverb2){print "--- $scriptName \t wants to read id:\n";
	     foreach $id(@id){$tmp=$id;$tmp=~s/^.*\///g;print"$id,";}print"\n";}
				# --------------------------------------------------
				# do alignment (maxhom)
				# --------------------------------------------------
if ($par{"do"}=~/hssp/){
    $dirSeq= &complete_dir($par{"dirSeq"});$dirHssp=&complete_dir($par{"dirHssp"});
    $dirWork=&complete_dir($par{"dirWork"});
    foreach $id (@id){
	$fileSeq= $dirSeq. $id.$par{"extSeq"};$fileHssp=$dirHssp.$id.$par{"extHssp"};
	print "xx id=$id , hssp=$fileHssp,\n";
	next if (-e $fileHssp);	# HSSP already exists
	$#fileTmp=0;foreach $kwd ("fasta","blast","blastFil"){
	    $file{"$kwd"}=$dirWork."XMAX".$$."-".$id.".$kwd";push(@fileTmp,$file{"$kwd"});}
				# ------------------------------
	($Lok,$msg)=		# running maxhom
	    &maxhomRun($date,$par{"nice"},$LcleanUp,$fhTrace,$fileSeq,
		       $file{"fasta"},$file{"blast"},$file{"blastFil"},$fileHssp,
		       $par{"dirData"},$par{"dirSwiss"},$par{"dirPdb"},$par{"exeConvSeq"},
		       $par{"exeBlastp"},$par{"exeBlastpFilter"},$par{"exeMax"},
		       $par{"envBlastMat"},$par{"envBlastDb"},$par{"parBlastNhits"},
		       $par{"parBlastDb"},$par{"fileMaxDef"},$par{"fileMaxMat"},
		       $par{"parMaxProf"},$par{"parMaxThresh"},
		       $par{"parMaxSmin"},$par{"parMaxSmax"},
		       $par{"parMaxGo"},$par{"parMaxGe"},$par{"parMaxW1"},$par{"parMaxW2"},
		       $par{"parMaxI1"},$par{"parMaxI2"},$par{"parMaxNali"},
		       $par{"parMaxSort"},$par{"parMaxProfOut"},
		       $par{"parMaxStripOut"},$par{"parMinLaliPdb"},$par{"parMaxTimeOut"});
	if (! $Lok){print "*** ERROR in maxhomRun(lib-prot)\n***    msg=$msg\n";}
	if (! $debug){foreach $file(@fileTmp){unlink ($file) if (-e $file);}}}}
				# ------------------------------
				# correct for empty HSSP files
$#hsspSelf=0;			# ------------------------------
foreach $hsspEmpty(@hsspEmpty){

    ($Lok,$err,$hsspSelf)=
	&maxRunSelfLoc($hsspEmpty);
    if (-e $hsspSelf){
	print "xx ok self\n";
	push(@hsspSelf,$hsspSelf);}
    else {print "*** $scriptName failed to get HSSP ($hsspSelf) from seq=$seq\n";
	  print "***    reason: \n$err (from maxhomRunSelfLoc)\n";}}
				# --------------------------------------------------
				# run PHD for all files
				# --------------------------------------------------
foreach $hssp (@hssp,@hsspSelf){
    $id=$hssp;$id=~s/^.*\///g;$id=~s/\.hssp.*$//g;
				# ------------------------------
    if (! -e $hssp){		# no alignment
	print "*** hssp file '$hssp' missing\n";
	next;}
    if (&is_hssp_empty($hssp)){
	print "*** hssp file '$hssp' empty and was not detected\n";
	next;}
    print "--- trying to work on $id hssp=$hssp\n";
				# ------------------------------
                                # (1) runs PHDsec, PHDacc
    if ($par{"do"}=~/(phd|rdb)(Both|Acc|Sec)/){
	$Lok=&phdRunBoth;}
				# ------------------------------
				# (2) run PHDhtm
    foreach $val("07","08","def"){
	if ($par{"do"}=~/(phd|rdb)Htm$val/){
	    $Lok=&phdRunHtm($val);}}
				# ------------------------------
				# (3) to be continued
}
				# ------------------------------
foreach $type (@kwdTypeMan){	# now verify existence
    $ext=$kwd{"$type","ext"};$dir=$kwd{"$type","dir"};$typeTmp=$type;
    if ($type =~ /htmdef/i){
	$typeTmp=~s/def//g;$dir=~s/def//g;$ext=~s/def//g;}
    &analyseDirs($typeTmp,$dir,$ext,$Lverb,$Lverb2,$Lverb3);}
				# ------------------------------
				# write results
&wrtFin;

# -----------------------------------------------------------------------------
# fin
# -----------------------------------------------------------------------------
if ($Lverb2){ print "--- $scriptName finished its task\n";
	      print "--- \n--- Output files are:\n";$it=0;
	      while ($it<$#fileOut){printf "--- %-10s "," ";$it2=0;
				    while (($it2<3)&&(($it2+$it)<$#fileOut)){
					++$it2;$fileOut=$fileOut[$it2+$it];
					if (-e $fileOut){
					    printf "%-20s ",$fileOut;}}
				    print "\n"; $it+=$it2;}}
exit;

#===============================================================================
sub ini {
    local (@scriptTask,@scriptHelp,@scriptKwd,@scriptKwdDescr,$txt);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   ini                         initialises variables/arguments
#-------------------------------------------------------------------------------
    $jobid=$$;

    &iniEnv;			# sets environment (ARCH, PWD)
    
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
		foreach $kwd (@kwdDef) {
		    if (! defined $par{"$kwd"}){$tmp="!! UNDEF !!";}else{$tmp=$par{"$kwd"};}
		    if ((length($tmp)<1)||($tmp eq "unk")){
			next;}
		    if ($kwd=~/^fileOut/){
			next;}
		    printf "--- %-20s '%-s'\n",$kwd,$tmp;}
		print "--- \n--- Output files are:\n";$it=0;
		while ($it<$#fileOut){printf "--- %-10s "," ";$it2=0;
				      while (($it2<3)&&(($it2+$it)<$#fileOut)){
					  ++$it2;$fileOut=$fileOut[$it2+$it];
					  printf "%-20s ",$fileOut;}
				      print "\n"; $it+=$it2;}
		&myprt_line;}

    # ------------------------------------------------------------
    # check existence of file
    # ------------------------------------------------------------
    $Lmiss=0;
    foreach $kwd(@kwdDef){
	if ($kwd =~/^(fileIn|exe)/){
	    next if ((! defined  $par{"$kwd"})||(length($par{"$kwd"})<1));
	    if ($kwd=~/^fileIn/){$tmp1=$kwd;$tmp1=~s/fileIn/do/;
				 $tmp2=$kwd;$tmp2=~s/fileIn/read/;
				 next if ((! $par{"$tmp1"})&&(! $par{"$tmp2"}));}
	    if (! -e $par{"$kwd"}){
		printf "*** %-20s '%-s'\n","MISSING $kwd",$par{"$kwd"};$Lmiss=1;}}}
    if ($Lmiss){
	print "*** try to locate the missing files/executables before continuing!\n";
	print "*** left script '$scriptName' after ini date: $date\n";
	return(0);}
    return(1);
}				# end of ini

#===============================================================================
sub iniEnv {
    local($sbrName,$tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iniEnv                      sets environment (ARCH, PWD, asf)
#-------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";}$sbrName="$tmp"."iniEnv";

    if    (defined $ENV{'PPlib'}){ # Perl lib defined in environment?
	$tmp=$ENV{'PPlib'};$tmp=~s/\/$//g; $par{"dirPerlLib"}=$ENV{'PPlib'};}
    else {			# in command line?
	foreach $arg(@ARGV){
	    if ($arg=~/^dirPerlLib/){
		$arg=~s/^dirPerlLib=//g;$par{"dirPerlLib"}=$tmp=$arg;$tmp=~s/\/$//g;
		last;}}}
    if (-d $tmp){		# perl libraries found
	push(@INC,"$tmp");}
    else {			# else: defaults...
	foreach $dir ("/home/rost/perl","/home/rost/pub/phd/scr","/home/phd/ut/perl"){
	    if (-d $dir){
		push(@INC,$dir);
		last;}}}
				# include libraries
    require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
    require "ctime.pl"; 
#    require "/home/phd/ut/perl/lib-pp.pl";

#	$date is e.g.:		Thu Oct 14, 1993 13:06:47
#	@Date is e.g.:		Oct,14,13:06:47,1993
#	&ctime(time) is e.g.:	Thu Oct 14 13:06:47 1993
#
    @Date = split(' ',&ctime(time)) ; 
    $dateLong="$Date[1] $Date[2] $Date[3], $Date[6] ($Date[5]:$Date[4])"; 
    $date="$Date[2] $Date[3], $Date[6]"; 
    $PWD=                       $ENV{'PWD'}; $pwd=&complete_dir($PWD);
    $ARCH=                      $ENV{'ARCH'}; 
    if (!defined $ARCH)         {print "-*- WARNING \t no architecture defined\n";}

				# ------------------------------
				# setenv ARCH and CPUARC
				# ------------------------------
    if    (defined $ENV{'ARCH'})   { $ARCH=$ENV{'ARCH'} ; }
    elsif (defined $ENV{'CPUARC'}) { $ARCH=$ENV{'CPUARC'};}
    else                           { $ARCH="unk"; }
    foreach $_(@ARGV){		# ARCH passed?
	if ($_=~/^ARCH=(.+)$/){$ARCH=$1;}
    }
				# get local directory
    if (! defined $ENV{'PWD'}) {
	open(C,"/bin/pwd|");$PWD=<C>;close(C);}
    else {
	$PWD=$ENV{'PWD'};}
}				# end of iniEnv

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
    @scriptKwd=     ("do=",
		     "dirPhd/dirHssp/dirRdb/dirNotHtm=",
		     "title=",
		     " ",
		     "notScreen, verbose, verbose2",
		     "dirIn=",
		     "dirOut=",
		     "dirWork=",
		     );
    @scriptKwdDescr=("file types to search (default=".$par{"do"}.") ",
		     "directories with results ", 
		     "title of output files",
		     " ",
		     "no information written onto screen",
		     "input directory        default: local",
		     "output directory       default: local",
		     "working directory      default: local ",
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
				# scripts
    $par{"dirPhdHome"}=         "/home/rost/pub/phd/";
    $par{"dirPhdScr"}=          $par{"dirPhdHome"}."scr/";
    $par{"dirPhdBin"}=          $par{"dirPhdHome"}."bin/";
    $par{"dirMax"}=             "/home/rost/pub/max/";
    $par{"dirMaxBin"}=          $par{"dirMax"}.    "bin/";
    $par{"dirMaxCsh"}=          $par{"dirMax"}.    "csh/";
    $par{"dirMaxMat"}=          $par{"dirMax"}.    "mat/";
    $par{"dirMaxScr"}=          $par{"dirMax"}.    "scr/";
				# databases
    $par{"dirData"}=           "/data"; # dir of databases
    $par{"dirSwiss"}=          "/data/swissprot"; # Swissprot directory
    $par{"dirSwissSplit"}=     "/data/swissprot/current"; # SWISS-PROT split
    $par{"dirPdb"}=            "/data/pdb"; # 
				# output/input
#    $par{"dirSeq"}=             "/sander/purple1/rost/w/gene/ec9802/seq";
#    $par{"dirHssp"}=            "/sander/purple1/rost/w/gene/ec9802/hssp";
#    $par{"dirHsspSelf"}=        "/sander/purple1/rost/w/gene/ec9802/hsspSelf";
#    $par{"dirHsspSelf"}=        "/sander/purple1/rost/w/short/run/hsspSelf";
#    $par{"dirHssp"}=            "/sander/purple1/rost/w/short/run/hssp";
#    $par{"dirWork"}=            "/sander/purple1/rost/w/short/run/"; # working directory
    $par{"dirHssp"}=            "/sander/purple1/rost/w/short/hsspDom";
    $par{"dirHsspSelf"}=        "/sander/purple1/rost/w/short/hsspDom";

    $par{"dirWork"}=            "/sander/purple1/rost/w/short/"; # working directory
    $par{"dirPhd"}=             $par{"dirWork"}.    "phd";
    $par{"dirPhdDssp"}=         $par{"dirWork"}.    "phdDssp";
    $par{"dirPhdHtm"}=          $par{"dirWork"}.    "phdHtm";
#    $par{"dirPhdRdb"}=          $par{"dirWork"}.    "rdbPhd";
    $par{"dirPhdRdb"}=          $par{"dirWork"}.    "rdbPhdDom";
    $par{"dirPhdRdbHtm"}=       $par{"dirWork"}.    "rdbHtm";
    $par{"dirPhdNotHtm"}=       $par{"dirWork"}.    "notHtm";
				# --------------------
				# executables
    if ($ARCH =~/SGI/){
	$par{"exePhdPl"}=           $par{"dirPhdHome"}."phdPhenix.pl";
    }else{
	$par{"exePhdPl"}=           $par{"dirPhdHome"}."phd.pl";
    }
    $par{"exePhdFor"}=          $par{"dirPhdBin"}. "phd.".$ARCH;
    $par{"exePhd2Dssp"}=        $par{"dirPhdScr"}. "conv_phd2dssp.pl";
    $par{"exeConvSeq"}=         $par{"dirPhdBin"}. "convert_seq.".$ARCH;
    $par{"exeMax"}=             $par{"dirMaxBin"}. "maxhom.".$ARCH;
    $par{"exeMaxCsh"}=          $par{"dirMaxCsh"}. "max5-blastp.csh";
    $par{"exeBlastp"}=          "/home/phd/bin/".  $ARCH."/blastp";
    $par{"exeBlastpFilter"}=    $par{"dirMaxScr"}. "filter_blastp";
    $par{"exeHsspFilterFor"}=   $par{"dirMaxBin"}. "filter_hssp.".$ARCH,
    $par{"exeHsspFilter"}=      $par{"dirMaxScr"}. "hssp_filter.pl";
    $par{"exeHsspExtrHead"}=    $par{"dirMaxScr"}. "hssp_extr_header.pl";
    $par{"exeHssp2msf"}=        $par{"dirMaxScr"}. "conv_hssp2msf.pl";
    $par{"exeHssp2pir"}=        $par{"dirMaxScr"}. "hssp_extr_2pir.pl";
				# --------------------
				# files in / out
#    $par{"extSeq"}=             ".f";
    $par{"extSeq"}=             ".pir";
#    $par{"extSeq"}=             ".seq";
    $par{"extHssp"}=            ".hssp";
    $par{"extHsspSelf"}=        ".hsspSelf";
    $par{"extPhd"}=             ".phd";
    $par{"extPhdRdb"}=          ".rdbPhd";
    $par{"extPhdDssp"}=         ".dsspPhd";
    $par{"extPhdHtm"}=          ".phd";
    $par{"extPhdRdbHtm"}=       ".rdbHtm";
    $par{"extPhdNotHtm"}=       ".notHtm";

    $par{"extOut"}=             ".tmp";
    $par{"fileOut"}=            "";
    $par{"fileOut"}=            "";
				# file handles
    $fhout=                     "FHOUT";
    $fhin=                      "FHIN";
    $fhTrace=                   "STDOUT";
				# files parameter
    $par{"fileMaxDef"}=         $par{"dirMax"}.    "maxhom.default";
    $par{"fileMaxMat"}=         $par{"dirMaxMat"}. "Maxhom_GCG.metric";
    $par{"envBlastMat"}=        "/home/pub/molbio/blast/blastapp/matrix";
    $par{"envBlastDb"}=         "/data/db/";
                                # ----------------------------------------
				# MaxHom: parameters
    $par{"parBlastDb"}=         "swiss";     # database to run BLASTP against
    $par{"parBlastNhits"}=      "2000";
    $par{"parMaxThresh"}=       30;          # identity cut-off for Maxhom threshold of hits taken
    $par{"parMaxMaxNres"}=      "5000";      # maximal length of sequence
    $par{"parMaxProf"}=         "NO";
    $par{"parMaxSmin"}=        -0.5;         # standard job
    $par{"parMaxSmax"}=         1.0;         # standard job
    $par{"parMaxGo"}=           3.0;         # standard job
    $par{"parMaxGe"}=           0.1;         # standard job
    $par{"parMaxW1"}=           "YES";       # standard job
    $par{"parMaxW2"}=           "NO";        # standard job
    $par{"parMaxI1"}=           "YES";       # standard job
    $par{"parMaxI2"}=           "NO";        # standard job
    $par{"parMaxNali"}=       500;           # standard job
    $par{"parMaxSort"}=         "DISTANCE";  # standard job
    $par{"parMaxProfOut"}=      "NO";        # standard job
    $par{"parMaxStripOut"}=     "NO";        # standard job
    $par{"parMinLaliPdb"}=     30;           #
    $par{"parMaxTimeOut"}=  10000;           # secnd ~ 3hrs, then: send alarm MaxHom suicide!
#    $par{"exe"}=        ;
#    $par{"exe"}=        ;
				# --------------------
				# logicals
    $Lverb=                     1; # blabla on screen
    $Lverb2=                    1; # more verbose blabla
    $Lverb3=                    0; # more verbose blabla
    $debug=                     1;
#    $debug=                     0;
    $par{"verbose"}=$Lverb;$par{"verb2"}=$Lverb2;$par{"verb3"}=$Lverb3;
    $par{"nice"}=               " ";
				# drives which files to search (dirs= same names)
                                # convention: if rdbX -> no .phd files
    $par{"do"}=                 "phdBoth,phdHtmDef,phdDssp";
    $par{"do"}=                 "phdBoth,phdHtm07,phdHtm08,phdDssp";
    $par{"do"}=                 "phdHtm07,phdHtm08"; # xx
    $par{"do"}=                 "rdbHtm07,rdbHtm08"; # xx
#    $par{"do"}=                 "hssp,phdBoth,phdHtmdef"; # xx
#    $par{"do"}=                 "rdbBoth,rdbHtmdef"; # xx
    $par{"do"}=                 "rdbAcc"; # xx
				# 
				# ------------------------------
				# a.a descriptors 
				# allowed in default file
				# ------------------------------
    @kwdDef=     ("debug","verbose","verb2","verb3",
		  "dirIn","dirOut","dirWork","dirData","dirSwiss","dirSwissSplit","dirPdb",
		  "dirPhdHome","dirPhdScr","dirPhdBin",
		  "dirMax","dirMaxBin","dirMaxMat","dirMaxCsh","dirMaxScr",
		  "dirSeq","dirHssp","dirHsspSelf",
		  "dirPhd","dirPhdDssp","dirPhdRdb","dirPhdHtm","dirPhdRdbHtm","dirPhdNotHtm",
		  "exePhdPl","exePhdFor","exePhd2Dssp","exeConvSeq",
		  "exeMax","exeMaxCsh","exeBlastp","exeBlastpFilter",
		  "exeHsspFilterFor","exeHsspFilter","exeHsspExtrHead","exeHssp2msf","exeHssp2pir",
		  "extSeq","extHssp","extHsspSelf","extPhd","extPhdRdb","extPhdDssp",
		  "extPhdHtm","extPhdRdbHtm","extPhdNotHtm","extOut",
		  "fileOut",
		  "fileMaxDef","fileMaxMat",
		  "envBlastMat","envBlastDb","parBlastDb","parBlastNhits",
		  "parMaxThresh","parMaxMaxNres","parMaxProf","parMaxSmin","parMaxSmax",
		  "parMaxGo","parMaxGe","parMaxW1","parMaxW2","parMaxI1","parMaxI2",
		  "parMaxNali","parMaxSort","parMaxProfOut","parMaxStripOut",
		  "parMaxTimeOut","parMinLaliPdb",
		  "do",
		  "title","fileOutSyn","fileOutDo","fileOutOk","fileOutNohssp",
		  );
    @kwdStatus=  ("ok","notHtm","empty","none","twice");
}				# end of iniDefaults

#===============================================================================
sub iniGetArg {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iniGetArg                   read command line arguments
#-------------------------------------------------------------------------------
    $Lokdef=0; $#fileIn=$#tmp=0;
    foreach $arg (@ARGV){	# key word driven input
	if    ( $arg=~ /verb3/ )       { $Lverb3=1; }
	elsif ( $arg=~ /verb2/ )       { $Lverb2=1; }
	elsif ( $arg=~ /verbose/ )     { $Lverb=1; }
	elsif ( $arg=~ /not_verbose/ ) { $Lverb=0; }
	elsif ( $arg eq $ARGV[1]){ # skip first (evaluated later)
	    next;}
	else {			# general
	    $Lok=0;
	    foreach $kwd (@kwdDef){ # 
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
		print "xx still missing '$arg'\n";
		push(@tmp,$arg);}}}
    foreach $tmp (@tmp){	# check unrecognised input arguments
	$tmp1=$par{"dirIn"}.$tmp;
	if (-e "$tmp1"){push(@fileIn,$tmp1);}
	else { print "*** iniGetArg: unrecognised argument(2): '$tmp'\n";
	       return(0);}}	# 
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
    $#kwdDirMan=$#kwdExtMan=0;	# key words for extensions and dirs
    $par{"do"}=~s/^,|,$//g;
    @kwdTypeMan=split(/,/,$par{"do"});
    foreach $type(@kwdTypeMan){
	$par{"$type"}=1;
	if    ($type=~/htm/i){	# possible, e.g.: 'phdHtm,phdHtm07,rdbHtm07'
	    $dir=$par{"dir"."$type"}=$par{"dirPhdRdbHtm"};
	    if ($type=~/0(\d+)/){
		$dir.="0".$1;$par{"dir"."$type"}.="0".$1;
		$par{"dirNotHtm"."$type"}=$par{"dirPhdNotHtm"}."0".$1;}
	    else {
		$par{"dirNotHtm"."$type"}=$par{"dirPhdNotHtm"};}
	    $ext=$par{"ext"."$type"}=$par{"extPhdRdbHtm"};
	    if ($type=~/htmDef/i){
		$type2=$type;$type2=~s/def//ig;
		$par{"dirNotHtm"."$type2"}=$par{"dirNotHtm"."$type"};
		$par{"dir"."$type2"}=$par{"dirPhdRdbHtm"};
		$par{"ext"."$type2"}=$par{"extPhdRdbHtm"};}}
	elsif ($type=~/both/i){
	    $dir=$par{"dir"."$type"}=$par{"dirPhdRdb"};
	    $ext=$par{"ext"."$type"}=$par{"extPhdRdb"};}
	elsif ($type=~/phd/i){
	    $dir=$par{"dir"."$type"}=$par{"dirPhdRdb"};
	    $ext=$par{"ext"."$type"}=$par{"extPhdRdb"};}
	else {			# capitals in beginning (phdRdb-> extPhdRdb)
	    if ((! defined $par{"dir"."$type"})||($par{"dir"."$type"} eq "unk")||
		(length($par{"dir"."$type"})<1)){
		if    ($type =~ /phdHtm/)   {$par{"dir"."$type"}=$par{"dirPhdHtm"};}
		elsif ($type =~ /phdRdbHtm/){$par{"dir"."$type"}=$par{"dirPhdRdbHtm"};}
		elsif ($type =~ /phdNotHtm/){$par{"dir"."$type"}=$par{"dirPhdNotHtm"};}
		elsif ($type =~ /phdRdb/)   {$par{"dir"."$type"}=$par{"dirPhdRdb"};}
		elsif ($type =~ /rdbBoth/)  {$par{"dir"."$type"}=$par{"dirPhdRdb"};}
		elsif ($type =~ /rdbAcc/)   {$par{"dir"."$type"}=$par{"dirPhdRdb"};}
		elsif ($type =~ /rdbSec/)   {$par{"dir"."$type"}=$par{"dirPhdRdb"};}
		elsif ($type =~ /phdDssp/)  {$par{"dir"."$type"}=$par{"dirPhdDssp"};}
		elsif ($type =~ /phd/)      {$par{"dir"."$type"}=$par{"dirPhd"};}
		else                        {$par{"dir"."$type"}=$type;}}
	    $par{"dir"."$type"}=&complete_dir($par{"dir"."$type"});
	    if ((! defined $par{"ext"."$type"})||($par{"ext"."$type"} eq "unk")||
		(length($par{"ext"."$type"})<1)){
		if    ($type =~ /phdHtm/)   {$par{"ext"."$type"}=".phd";}
		elsif ($type =~ /phdRdbHtm/){$par{"ext"."$type"}=".rdb_phd";}
		elsif ($type =~ /phdNotHtm/){$par{"ext"."$type"}=".notHtm";}
		elsif ($type =~ /rdbBoth/)  {$par{"ext"."$type"}=".rdbPhd";}
		elsif ($type =~ /rdbAcc/)   {$par{"ext"."$type"}=".rdbPhd";}
		elsif ($type =~ /rdbSec/)   {$par{"ext"."$type"}=".rdbPhd";}
		elsif ($type =~ /phdDssp/)  {$par{"ext"."$type"}=".dssp_phd";}
		elsif ($type =~ /phdRdb/)   {$par{"ext"."$type"}=".rdb_phd";}
		elsif ($type =~ /phd/)      {$par{"ext"."$type"}=".phd";}
		else                        {$par{"ext"."$type"}=$type;}}}
	$par{"dir"."$type"}=&complete_dir($par{"dir"."$type"});
	$kwd{"$type","ext"}=$par{"ext"."$type"};
	$kwd{"$type","dir"}=$par{"dir"."$type"};}
				# ------------------------------
    foreach $kwd (@kwdDef){	# complete directories
	if ($kwd=~/^dir/){
	    if ((!defined $par{"$kwd"})||($par{"$kwd"} eq "unk")||(length($par{"$kwd"})<2)){
		print "*** undefeind for kwd=$kwd\n";
		next;}
	    $par{"$kwd"}=&complete_dir($par{"$kwd"}); # external lib-ut.pl
	}}
				# ------------------------------
				# add 'title' 'ext'
    if    (! defined $par{"title"} && $ARGV[1] ne "auto"){
	$par{"title"}=$ARGV[1];$par{"title"}=~s/^.*\///g;$par{"title"}=~s/\..*$//g;}
    elsif (! defined $par{"title"}){
	$par{"title"}="genePhd";}
    foreach $kwd (@kwdDef){
	next if ($kwd!~/^fileOut/);
	if ((!defined $par{"$kwd"})||($par{"$kwd"} eq "unk")||(length($par{"$kwd"})<2)){
	    $kwdExt=$kwd; $kwdExt=~s/file/ext/; 
	    if (defined $par{"$kwdExt"}){$ext=$par{"$kwdExt"};}else{$ext="";}
	    if ((! defined $par{"title"})||($par{"title"} eq "unk")){
		$par{"title"}=$scriptName;$par{"title"}=~s/\.pl//g;}
	    $par{"$kwd"}=$pre.$par{"title"}.$ext;}}
				# ------------------------------
    $#fileOut=0;		# add output directory
    if ((defined $par{"dirOut"})&&($par{"dirOut"} ne "unk")&&($par{"dirOut"} ne "local")&&
	(length($par{"dirOut"})>1)){
	if (! -d $par{"dirOut"}){ # make directory
	    ($Lok,$txt)=&dirMk($par{"dirOut"});  # external lib-ut.pl
	    $dirOut=&complete_dir($par{"dirOut"});}}
    else{$dirOut="";}
    foreach $kwd (@kwdDef){
	next if ($kwd!~/^fileOut/);
	$tmp=$kwd; $tmp=~s/^fileOut//g;
	if ((length($par{"dirOut"})>1) && ($par{"$kwd"} !~ /^$par{"dirOut"}/)){
	    if (defined $par{"$kwd"} && length($par{"$kwd"})>1){
		$par{"$kwd"}=$par{"dirOut"}.$par{"$kwd"};}
	    else {$par{"$kwd"}=$par{"dirOut"}.$tmp;}}
	else {$par{"$kwd"}=$par{"dirOut"}.$tmp;}
	$par{"$kwd"}.="-".$par{"title"};
	if (defined $par{"extOut"}){
	    $par{"$kwd"}.=$par{"extOut"};}
	else {$par{"$kwd"}.=".out";}
	push(@fileOut,$par{"$kwd"});}
				# ------------------------------
				# add working directory
    if ((defined $par{"dirWork"})&&($par{"dirWork"} ne "unk")&&($par{"dirWork"} ne "local")&&
	(length($par{"dirWork"})>1)){
	if (! -d $par{"dirWork"}){ # make directory
	    if ($verb){@tmp=("STDOUT",$par{"dirWork"});}else{@tmp=($par{"dirWork"});}
	    ($Lok,$txt)=&dirMk(@tmp); } # external lib-ut.pl
	foreach $kwd (@kwdDef){
	    next if (-e $par{"$kwd"});
	    if (($kwd=~/^file/)&&($kwd!~/^fileIn/)&&($kwd!~/^fileOut/)){
		if ($par{"$kwd"} !~ /^$par{"dirWork"}/){
		    $par{"$kwd"}=$par{"dirWork"}.$par{"$kwd"};}}}}
				# ------------------------------
				# array of Work files
    if (! defined @fileWork){$#fileWork=0;}
    foreach $kwd (@kwdDef){
	if (($kwd=~/^file/)&&($kwd!~/^fileIn/)&&($kwd!~/^fileOut/)){
	    push(@fileWork,$par{"$kwd"});}}
				# ------------------------------
    if (length($par{"dirWork"})<1){ # running directory
	$par{"dirWork"}=$pwd;}
				# ------------------------------
				# blabla
    if ((defined $par{"verbose"}) &&($par{"verbose"})) {$Lverb=1; }
    if ((defined $par{"verb2"})&&($par{"verb2"})){$Lverb2=1;}
    if ((defined $par{"verb3"})&&($par{"verb3"})){$Lverb3=0;}
				# ------------------------------
    foreach $kwd (@kwdDef){	# add directory to executables
	if (($kwd=~/^exe/)&&(defined $par{"$kwd"})&&(! -e $par{"$kwd"})){
	    $par{"$kwd"}=$par{"dirPerl"}.$par{"$kwd"};}}

    return(1);
}				# end of iniChangePar

#===============================================================================
sub subx {
#    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   subx                       
#                               c
#       in:                     
#         A                     A
#       out:                    
#         A                     A
#-------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";}
    $sbrName="$tmp"."subx";$fhinLoc="FHIN"."$sbrName";

    $Lok=       &open_file("$fhinLoc","$fileInLoc");
    if (! $Lok){print "*** ERROR $sbrName: '$fileInLoc' not opened\n";
		return(0);}
    while (<$fhinLoc>) {
	$_=~s/\n//g;
	next if (length($_)==0);
    } close($fhinLoc);

}				# end of subx

#===============================================================================
sub analyseDirs {
    local($typeLoc,$dirLoc,$extLoc,$LverbLoc,$Lverb2Loc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok,@fileLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   analyseDirs                 checks which files are there and ok
#-------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";}
    $sbrName="$tmp"."analyseDirs";$fhinLoc="FHIN"."$sbrName";
    if ($LverbLoc){ print "--- $sbrName ","-" x 50,"\n";
		    print "--- $sbrName analyse type=$typeLoc, \n";
		    print "--- $sbrName dir=$dirLoc, ext=$extLoc\n";}
				# ------------------------------
    $#fileLoc=0;		# list local
    $#fileLoc=0;$dir=$dirLoc; $dir=~s/\/$//g; # $dir=~s/^\///g; # purge leading slash
    @fileLoc=&fileLsAllTxt($dir); # external lib-ut.pl
    $#fileTmp=0;		# ------------------------------
    foreach $fileLoc(@fileLoc){	# correct extensions?
	if ($fileLoc=~/$extLoc$/){push(@fileTmp,$fileLoc);}}
    @fileLoc=@fileTmp;
				# ------------------------------
    %Lok=0;			# logicals for rapidity
    foreach $fileLoc(@fileLoc){$fileLoc=~s/^.*\///g;
			       $Lok{$fileLoc}=1;}
    $#fileWantLoc=0;		# now all we want
    foreach $id (@id){$tmp="$id"."$extLoc";
		      push(@fileWantLoc,$tmp);}
				# ------------------------------
				# is what you want, what you have?
    foreach $file(@fileWantLoc){
	$id=$file;$id=~s/\..*$//g;
	$fileLoc=$dirLoc.$file;
	if ($typeLoc=~/htm/i){
	    $fileNotHtm=$par{"dirNotHtm"."$typeLoc"}; $fileNotHtm=&complete_dir($fileNotHtm);
	    $fileNotHtm.=$id.$par{"extPhdNotHtm"};}
				# file existing?
	if    (! defined $Lok{$file}){
	    if (($typeLoc=~/htm/i)&&(-e $fileNotHtm)){
		print "--- $sbrName \t notHtm ($typeLoc) '$fileLoc'\n" if ($Lverb2Loc);
		$res{"$id","$typeLoc"}="$typeLoc notHtm";}
	    else {
		print "--- $sbrName \t none   ($typeLoc) '$fileLoc'\n" if ($Lverb2Loc);
		$res{"$id","$typeLoc"}="$typeLoc none";}}
	elsif (-z $fileLoc){	# empty file
	    print "--- $sbrName \t empty  ($typeLoc) '$fileLoc'\n" if ($Lverb2Loc);
	    $res{"$id","$typeLoc"}="$typeLoc empty";}
	else {
	    if (($typeLoc=~/htm/i)&&(-e $fileNotHtm)){
		print "--- $sbrName \t twice  ($typeLoc) '$fileLoc'\n" if ($Lverb2Loc);
		$res{"$id","$typeLoc"}="$typeLoc notHtm";}
	    else {
		print "--- $sbrName \t ok     ($typeLoc) '$fileLoc'\n" if ($Lverb2Loc);
		$res{"$id","$typeLoc"}="$typeLoc ok";}}}
}				# end of analyseDirs

#===============================================================================
sub getIdList {
    local($argIn) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getIdList                   digests first argument, gets ids to be managed
#-------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";}
    $sbrName="$tmp"."getIdList";$fhinLoc="FHIN"."$sbrName";

    $#id=0;
    if (-e $argIn){		# read file
	if ($Lverb2){ print "--- $sbrName \t reading input file '$argIn'\n";}
	$Lok=       &open_file("$fhinLoc","$argIn");
	if (! $Lok){print "*** ERROR $scriptName: '$argIn' not opened\n";
		    return(0);}
	while (<$fhinLoc>) {$_=~s/\s//g;
			    $_=~s/\.hssp.*$//g;	# purge extensions
#			    $_=~s/$par{"extSeq"}.*$//g; # 
#			    $_=~s/$par{"extHssp"}.*$//g; # purge extensions
			    next if (length($_)==0);
			    push(@id,$_);}close($fhinLoc);
				# get all HSSP files for ids
	$#tmp=$#hsspEmpty=0;
	foreach $id(@id){
	    $hssp=$par{"dirHssp"}.$id.$par{"extHssp"};
	    if    (! -e $hssp)           {$res{"$id","hssp"}="hssp none";}
	    elsif (&is_hssp_empty($hssp)){$res{"$id","hssp"}="hssp emtpy";
					  push(@hsspEmpty,$hssp);}
	    else                         {$res{"$id","hssp"}="hssp ok";
					  push(@tmp,$hssp);}}
	@hssp=@tmp;}
    elsif ($argIn =~/^auto/){	# list all HSSP files present
				# first move files from local/run dir to HSSP
	if ($Lverb2){ print "--- $sbrName \t sort into HSSP dir (",$par{"dirHssp"},")\n";}
	$Lok=
	    &sortIntoDirs($par{"dirHssp"},$par{"extHssp"},$par{"dirWork"},$Lverb,$Lverb2);
	if (!$Lok){print "*** ERROR $sbrName trouble sorting into '",$par{"dir"},"'\n";
		   die '*** after sortIntoDirs';}
	$#hssp=0;		# now listing all HSSP files
	$dir=$par{"dirHssp"};$dir=~s/^\///g; # purge leading slash
	@hssp=&fileLsAllTxt($dir); # external lib-ut.pl
	$#tmp=0;
	foreach $hssp (@hssp){
	    if ($hssp =~ /$par{"extHssp"}$/){
		$id=$hssp;$id=~s/$par{"extHssp"}$//g;$id=~s/^.*\///g;
		push(@id,$id);
		($Lok,$txt,$file)=&isHsspGeneral($hssp); # external lib-prot.pl
		$res{"$id","hssp"}=$txt;
		$txt="isHssp";	# xx
		if ($txt eq "isHssp"){push(@tmp,$file);}}}
	@hssp=@tmp;}
    else {
	return(0);}
    return(1);
}				# end of getIdList

#===============================================================================
sub maxRunSelfLoc {
    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   maxRunSelfLoc               writes HSSP file from sequence
#-------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";}
    $sbrName="$tmp"."maxRunSelfLoc";$fhinLoc="FHIN"."$sbrName";

    $id=$fileInLoc;$id=~s/^.*\///g;$id=~s/\.hssp.*$//g;
    $dirHsspSelf=$par{"dirHsspSelf"}; 
				# output hssp self
    $hsspSelf= $par{"dirHsspSelf"}; $hsspSelf=&complete_dir($hsspSelf); 
    $hsspSelf.=$id.$par{"extHsspSelf"};
    return(1,"ok $sbrName",$hsspSelf) if (-e $hsspSelf); # return if already existing

				# ------------------------------
    if (! -d $par{"dirSeq"}){	# is there a correponding sequence?
	print "*** ERROR $scriptName fileInLoc=$fileInLoc, no dir for sequence (dirSeq)\n";
	exit;}
    $seq=$par{"dirSeq"}; $seq=&complete_dir($seq);$seq.=$id.$par{"extSeq"};
    if (! -e $seq){
	return(0,
	       "*** ERROR $sbrName fileInLoc=$fileInLoc, no sequence=$seq (in dir=dirSeq)\n",
	       $hsspSelf);}
    $Ldel=0;			# ------------------------------
    if (! &isFasta($seq)){	# check input format (must be fasta)
	if (&isPir($seq)){
	    ($Lok,$idTmp,$seqLoc)=&pirRdSeq($seq);
	    $fastaTmp="FASTA-".$$.".f";$Ldel=1;
	    ($Lok,$err)=       &fastaWrt($fastaTmp,$id,$seqLoc);}
	else {
	    return(0,"*** ERROR $sbrName fileInLoc=$fileInLoc, seq=$seq, wrong format\n",
		   $hsspSelf)}}
    else {$fastaTmp=$seq;}
				# make directory if missing
    system("mkdir $dirHsspSelf") if (! -d $dirHsspSelf);
				# ------------------------------
				# run maxhom self
    $jobId=$$;
    ($Lok,$err)=
	&maxhomRunSelf(" ",$par{"exeMax"},$par{"fileMaxDef"},$jobId,$fastaTmp,
		       $hsspSelf,$par{"fileMaxMat"},"STDOUT");

    unlink($fastaTmp) if ($Ldel);
    return(0,"ERROR $sbrName err=$err",$hsspSelf) if (! $Lok);

    system("\\rm MAXHOM*$jobId*");

    return(1,"ok $sbrName",$hsspSelf);
}				# end of maxRunSelfLoc

#===============================================================================
sub phdRunBoth {
    $[ =1 ;
    local($sbrName,$tmp);
#-------------------------------------------------------------------------------
#   phdRunBoth                  runs PHDsec , PHDacc
#       in/out (GLOBAL):                    
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."phdRunBoth";

    $filePhd=$par{"dirWork"}.$id.$par{"extPhd"};
    $fileRdb=$par{"dirWork"}.$id.$par{"extPhdRdb"};
    $fileFinRdb=$par{"dirPhdRdb"}.$id.$par{"extPhdRdb"};
    $fileFinPhd=$par{"dirPhd"}.   $id.$par{"extPhd"};

    if (-e $fileFinPhd || -e $fileFinRdb){ # already existing dont repeat!
	print "--- $sbrName skip PHDboth, as existing:";
	print "$fileFinPhd,\n" if ($par{"do"}=~/phd/);
	print "$fileFinRdb,\n" if ($par{"do"}=~/rdb/);
	return(1);}

    if (-e $fileFinPhd || -e $fileFinRdb){ # existing in work -> move
	$tmp=$fileRdb;$fileRdb=~s/$par{"dirWork"}/$par{"dirPhdRdb"}/;
	($Lok,$err)=&fileMv($tmp,$fileRdb,"SDTOUT");
	if ($par{"do"}=~/phdBoth/){
	    $tmp=$filePhd;$filePhd=~s/$par{"dirWork"}/$par{"dirPhd"}/;
	    ($Lok,$err)=&fileMv($tmp,$filePhd,"SDTOUT");}
	print "--- $sbrName moved PHDboth, from local\n";
	return(1);}

    $exe=$par{"exePhdPl"};
    $arg= " $hssp fileOutPhd=$filePhd fileOutRdb=$fileRdb ARCH=$ARCH"; 
    if    ($par{"do"}=~/both/i){$arg.=" both";}
    elsif ($par{"do"}=~/acc/i) {$arg.=" acc";}
    elsif ($par{"do"}=~/sec/i) {$arg.=" sec";}
    else                       {$arg.=" both";}	# default = both (acc + sec)

    $arg.=" exePhd=".$par{"exePhdFor"}." ";
				# run PHD
    if ($Lverb){print "$sbrName sys \t '$exe $arg'\n"}
    # ======================
    system("$exe $arg");
    # ======================

    $Lok=1;			# --------------------
    if (! -e $fileRdb){		# check existence
	print "*** ERROR missing phdRdb=$fileRdb\n";$Lok=0;}
    else {$tmp=$fileRdb;$fileRdb=~s/$par{"dirWork"}/$par{"dirPhdRdb"}/;
	  ($Lok,$err)=&fileMv($tmp,$fileRdb,"SDTOUT");}
    if ($Lok && ! -e $filePhd){
	print "*** ERROR missing phd=$filePhd\n";$Lok=0;}
    elsif ($par{"do"}=~/phdBoth/){
        $tmp=$filePhd;$filePhd=~s/$par{"dirWork"}/$par{"dirPhd"}/;
	($Lok,$err)=&fileMv($tmp,$filePhd,"SDTOUT");}
    else {
	unlink($filePhd);}
    return($Lok);
}				# end of phdRunBoth

#===============================================================================
sub phdRunHtm {
    local($valLoc)=@_;
    local($sbrName,$tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   phdRunHtm                  runs PHDhtm
#       in/out (GLOBAL):                    
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."phdRunHtm";

    $filePhd=$par{"dirWork"}.$id.$par{"extPhdHtm"};
    $fileRdb=$par{"dirWork"}.$id.$par{"extPhdRdbHtm"};
    $fileNot=$par{"dirWork"}.$id.$par{"extPhdNotHtm"};

				# construct final output names
    if ($valLoc eq "def"){
	$fileFinRdb=$par{"dirPhdRdbHtm"}.$id.$par{"extPhdRdbHtm"};
	$fileFinNot=$par{"dirPhdNotHtm"}.$id.$par{"extPhdNotHtm"};}
    else {$dirRdb=$par{"dirPhdRdbHtm"};$dirRdb=~s/\/$/$valLoc\//;
	  $dirNot=$par{"dirPhdNotHtm"};$dirNot=~s/\/$/$valLoc\//;
	  $fileFinRdb=$dirRdb.$id.$par{"extPhdRdbHtm"};
	  $fileFinNot=$dirNot.$id.$par{"extPhdNotHtm"};}

    if (-e $fileFinRdb || -e $fileFinNot){ # already existing dont repeat!
	print "--- $sbrName skip PHDhtm, as existing:$fileFinRdb, or:$fileFinNot,\n";
	return(1);}

    if (-e $fileFinPhd || -e $fileFinRdb){ # existing in work -> move
	$tmp=$fileRdb;$fileRdb=~s/$par{"dirWork"}/$par{"dirPhdRdbHtm"}/;
	($Lok,$err)=&fileMv($tmp,$fileRdb,"SDTOUT");
	if ($par{"do"}=~/phdHtm/){
	    $tmp=$filePhd;$filePhd=~s/$par{"dirWork"}/$par{"dirPhdHtm"}/;
	    ($Lok,$err)=&fileMv($tmp,$filePhd,"SDTOUT");}
	print "--- $sbrName moved PHDhtm, from local\n";
	return(1);}

    $exe=$par{"exePhdPl"};
    $arg=" $hssp fileOutPhd=$filePhd fileOutRdb=$fileRdb fileNotHtm=$fileNot htm ARCH=$ARCH ";
    $arg.=" exePhd=".$par{"exePhdFor"};
    if    ($valLoc eq "07"){$arg.=" optHtmisitMin=0.7";}
    elsif ($valLoc eq "08"){$arg.=" optHtmisitMin=0.8";}
				# run PHD
    if ($Lverb){print "$sbrName sys \t '$exe $arg'\n"}

    # ======================
    system("$exe $arg");
    # ======================

    $Lok=1;			# --------------------
    if (-e $fileNot){		# if not HTM: remove all
	$tmp=$fileNot;$tmp=$valLoc;$tmp="" if ($valLoc eq "def");
	$tmpDir=$par{"dirPhdNotHtm"};$tmpDir=~s/\/$//g;
	$cmd="\\mv $fileNot ".$tmpDir.$tmp."/ ";
	print "--- $sbrName flag file 'no HTM' detected ($cmd)\n";
	system("$cmd");
	foreach $file ($filePhd,$fileRdb){ # remove unnessary files
	    unlink($file) if (-e $file);}}
    else {			# ------------------------------
	if (! -e $fileRdb){	# check existence and move
	    print "*** ERROR missing phdRdb(Htm)=$fileRdb\n";$Lok=0;}
	else {$tmp=$fileRdb;$tmp=$valLoc;$tmp="" if ($valLoc eq "def");
	      $tmpDir=$par{"dirPhdRdbHtm"};$tmpDir=~s/\/$//g;
	      $cmd="\\mv $fileRdb ".$tmpDir.$tmp."/ ";
	      print "--- $sbrName system \t '$cmd'\n";
	      system("$cmd");}
	if ($par{"do"}=~/rdbHtm/){ # dont keep *.phd file
	    unlink ($filePhd) if (-e $filePhd);}
	elsif ($Lok && ! -e $filePhd){
	    print "*** ERROR missing phd=$filePhd\n";$Lok=0;}
	else {$tmp=$filePhd;$tmp=$valLoc;$tmp="" if ($valLoc eq "def");
	      $tmpDir=$par{"dirPhdHtm"};$tmpDir=~s/\/$//g;
	      $cmd="\\mv $filePhd ".$tmpDir.$tmp."/ ";
	      system("$cmd");}}
    return($Lok);
}				# end of phdRunHtm

#===============================================================================
sub sortIntoDirs {
    local($dirOutLoc,$extLoc,$LverbLoc,$Lverb2Loc,$Lverb3Loc,@fileLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok,$dirInTxtLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   sortIntoDirs                moves all files with *extLoc from dirIn to dirOut
#-------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";}
    $sbrName="$tmp"."sortIntoDirs";$fhinLoc="FHIN"."$sbrName";
    return(1) if (! defined $fileLoc[1] || $#fileLoc<1);
				# ------------------------------
    if (! -d $dirOutLoc){	# make directory if not there
	$tmp=$dirOutLoc;$tmp=~s/\/$//g;	# purge slash
	if ($Lverb2Loc) { print "--- $sbrName \t making directory '$dirOutLoc'\n";}
	($Lok,$txt)=&dirMk($tmp);  # external lib-ut.pl
	if (! $Lok){print "*** $sbrName \t tried making directory '$txt'\n";
		    return(0);}}
    foreach $file(@fileLoc){
	if (-e $file){
	    $file=~s/^$pwd\///g;
	    next if (! -e $file);
	    if ($file=~/$extLoc$/){
		if ($Lverb2Loc)  {print "--- $sbrName system \t '\\mv $file $dirOutLoc'\n";}
		system("\\mv $file $dirOutLoc");}
	    elsif ($Lverb3Loc)  {print "--- $sbrName \t not ext=$extLoc in file=$file,\n";}}
	elsif ($Lverb2Loc)      {print "--- $sbrName \t missing '$file'\n";}}
    return(1);
}				# end of sortIntoDirs

#===============================================================================
sub wrtFin {
    local($sbrName,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   wrtFin                      writes the final reports
#-------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";}
    $sbrName="$tmp"."wrtFin";$fhoutLoc="FHOUT"."$sbrName";
    $fhoutOk=   "FHOUT_OK_"."$sbrName";$fhoutDo="FHOUT_DO_"."$sbrName";
    $fhoutTwice="FHOUT_TWICE_"."$sbrName";

    if ((defined $par{"fileOutSyn"})&&(length($par{"fileOutSyn"})>5)){
	$fileOutLoc=$par{"fileOutSyn"} ;}
    else {
	$fileOutLoc="OUT-PHD-MANY.tmp";}
    $Lok=       &open_file("$fhoutLoc",">$fileOutLoc");
    if (! $Lok){print "*** ERROR $sbrName: fileOutLoc=$fileOutLoc, not opened\n";
		return(0);}
				# --------------------------------------------------
				# loop over all file types
				# --------------------------------------------------
    foreach $type(@kwdTypeMan){
				# open files ok/do
	$tmp="fileOut".$par{"preOutDo"}.$type; 
	$fileDo=$par{"$tmp"};
	$fileDo="Do-".$par{"preOutDo"}.$type.".list" if (!defined $fileDo || length($fileDo)<5);
	$Lok=       &open_file("$fhoutDo",">$fileDo");
	if (! $Lok){print "*** ERROR $sbrName: fileDo=$fileDo, not opened\n";
		    return(0);}
	$tmp="fileOut".$par{"preOutOk"}.$type; $fileOk=$par{"$tmp"};
	$fileOk="Ok-".$par{"preOutDo"}.$type.".list" if (!defined $fileOk||length($fileOk)<5);
	$Lok=       &open_file("$fhoutOk",">$fileOk");
	if (! $Lok){print "*** ERROR $sbrName: fileOk=$fileOk, not opened\n";
		    return(0);}
	$tmp="fileOut".$par{"preOutOk"}.$type; $fileOk=$par{"$tmp"};
	$fileTwice="Twice-".$par{"preOutDo"}.$type.".list" 
	    if (!defined $fileTwice||length($fileTwice)<5);
	$Lok=       &open_file("$fhoutTwice",">$fileTwice");
	if (! $Lok){print "*** ERROR $sbrName: fileTwice=$fileTwice, not opened\n";
		    return(0);}
	$ctOk=$ctEmpty=$ctNone=$ctNotHtm=$ctTwice=0;
				# dir/ext for fileDo
	if ($type =~/hssp/){
	    $dirOk=$kwd{"$type","dir"};$extOk=$kwd{"$type","ext"};
	    $dirDo=$par{"dirSeq"}; $extDo=$par{"extSeq"};}
	else {
	    $dirDo=$par{"dirHssp"};$extDo=$par{"extHssp"};}
				# dir/ext for fileOk
	$dirOk=$kwd{"$type","dir"};$extOk=$kwd{"$type","ext"};
	$extOk=".".$extOk if ($extOk !~/^\./);
	$extDo=".".$extDo if ($extDo !~/^\./);
	$extOk=~s/def|[Bb]oth//g;
	$extDo=~s/def|[Bb]oth//g;
	print "xx type=$type, extOk=$extOk, dirOk=$dirOk,\n";
				# ------------------------------
	foreach $id (@id){	# loop over all ids
	    $Lok=0;
	    $type=~s/def//g;
	    if    ($res{"$id","$type"} eq "$type ok")     {++$ctOk;$Lok=1;}
	    elsif ($res{"$id","$type"} eq "$type empty")  {++$ctEmpty;}
	    elsif ($res{"$id","$type"} eq "$type none")   {++$ctNone; }
	    elsif ($res{"$id","$type"} eq "$type notHtm") {++$ctNotHtm; $Lok=1;}
	    elsif ($res{"$id","$type"} eq "$type twice")  {++$ctTwice; }
	    else  {print"*** $sbrName \t strange result id=$id, type=$type, res=",
		   $res{"$id","$type"},"\n";
		   next;}
				# write into file list
	    $fileOk=$dirOk.$id.$extOk;$fileDo=$dirDo.$id.$extDo;
	    if    ($Lok && (-e $fileOk)){ # file ok
		print $fhoutOk "$fileOk\n";}
	    elsif ($Lok){	# file do (strange)
		print "*** $sbrName \t $fileOk ($type) not there, lie?\n";}
	    else  {		# file do
		print $fhoutDo "$fileDo\n";}}
				# count 
	close($fhoutDo);close($fhoutOk);
	$res{"$type","ok"}=$ctOk;$res{"$type","empty"}=$ctEmpty;
	$res{"$type","none"}=$ctNone;$res{"$type","notHtm"}=$ctNotHtm;}
				# --------------------------------------------------
				# write overall statistics
				# --------------------------------------------------
    @fhLoc=("$fhoutLoc");if ($Lverb){push(@fhLoc,"STDOUT");}
    foreach $fh (@fhLoc){
	print $fh
	    "\# Perl-RDB\n","\# \n",
	    "\# DATA         --------------------------------------------------\n",
	    "\# DATA         Overall statistics\n",
	    "\# DATA         --------------------------------------------------\n",
	    "\# DATA         \n",
	    "\# DATA BEG SUMMARY\n";
	print $fh "\# DATA  file         ";
	foreach $kwd(@kwdStatus){printf $fh "%-10s ",$kwd;}print $fh "\n";
	
	foreach $type(@kwdTypeMan){
	    print $fh "\# DATA  $type"," " x (10-length($type))," : ";
	    foreach $kwd (@kwdStatus){
		if (! defined $res{"$type","$kwd"}){$tmp="";}else{$tmp=$res{"$type","$kwd"};}
		printf $fh "%-10s ",$tmp;}
	    print $fh "\n";}
	print $fh "\# DATA END SUMMARY\n";
    }
    print $fhoutLoc "id      ";	# names
    foreach $type (@kwdTypeMan){print $fhoutLoc "\t$type";}print $fhoutLoc "\n";
#    print $fhoutLoc "20S";	# formats
#    foreach $type (@kwdTypeMan){print $fhoutLoc "\t15S";}
    foreach $id (@id){
	print $fhoutLoc $id;
	foreach $type (@kwdTypeMan){
	    $tmp=$res{"$id","$type"};$tmp=~s/$type //g;
	    $tmp.=" " x (10 - length($tmp));
	    print $fhoutLoc "\t$tmp";}
	print $fhoutLoc "\n";}
    close($fhoutLoc);
				# ------------------------------
				# remove empty files
    $#tmp=0;
    foreach $file(@fileOut){if (-z $file){&fileRm($Lverb2,$file);}
			    else{push(@tmp,$file);}}
    @fileOut=@tmp;
}				# end of wrtFin

