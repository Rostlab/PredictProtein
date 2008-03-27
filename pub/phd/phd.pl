#!/usr/bin/perl
##!/usr/bin/perl -w
##!/usr/sbin/perl -w
##!/bin/env perl
#------------------------------------------------------------------------------#
# LION:
#!/usr/sbin/perl -w
# EMBL:
##!/bin/env perl -w
##!/usr/pub/bin/perl -w
##!/usr/bin/perl -w
##!/usr/bin/perl4 -w
##!/usr/bin/perl5 -w
# EBI:
##!/usr/bin/perl -w
# UCSC:
##!/usr/bin/perl -w
#------------------------------------------------------------------------------#
#	Copyright				May,    	1998	       #
#	Burkhard Rost		rost@LION-ag.de,rost@EMBL-heidelberg.de	       #
#	Wilckensstr. 15		http://www.embl-heidelberg.de/~rost/	       #
#	D-69120 Heidelberg						       #
#				version 2.0   	Aug,    	1998	       #
#				version 2.1   	Oct,    	1998	       #
#------------------------------------------------------------------------------#
#
# ---------------------------------------------------------------------------- #
# change to port (install) program:                                            #
# ---------------------------------------------------------------------------- #
                                # -------------------------------------
				# directory where you find phd.tar
				# before doing the install 
				# e.g. /home/you/
$par{"dirHome"}=                "/nfs/data5/users/ppuser/server/pub/";
                                # -------------------------------------
				# final directory with PHD 
                                # resulting from 'tar -xvf phd.tar'
$par{"dirPhd"}=                 $par{"dirHome"}. "phd/";

				# hack br 2003-08-22
				# hack to account for differences with PROF
$LunderProf=0;
if ($0=~/prof/){
    $LunderProf=1;
    $par{"dirPhd"}=             "/nfs/data5/users/ppuser/server/pub/prof/" ;
}
                                # -------------------------------------
				# architecture to run PHD 
				# e.g. MAC|LINUX|SGI5|SGI32|SGI64|ALPHA|SUNMP
$ARCH_DEFAULT=                  "LINUX";
$ARCH_DEFAULT=                  "LINUX";
$ARCH_DEFAULT=                  "LINUX";
#$ARCH_DEFAULT=                  "SGI32";
#$ARCH_DEFAULT=                  "ALPHA";

#
# see sbr iniDef for further parameters
# --------------------------------------------------
#
#------------------------------------------------------------------------------#
				# --------------------------------------------------
				# sets array count to start at 1, not at 0
				# --------------------------------------------------
$[=1 ;
				# --------------------------------------------------
				# initialise variables
				# --------------------------------------------------
$scrName=$0;$scrName=~s/^.*\/|\.pl//g; $sourceFile=$0;$sourceFile=~s/^\.\///g;
($Lok,$msg)=
    &ini();                     die ("*** ERROR $scrName: after ini\n".$msg) if (! $Lok);

				# --------------------------------------------------
				# looping over list
$#protname=0;			# --------------------------------------------------
$nfileIn=$#fileIn; $it=0;
                                # hack br 99-07
$USERID_tmp=$USERID;
$USERID_tmp="phd"               if (! $par{"optDoEval"});

while (@fileIn) {
    ++$it;
    $fileIn=      shift @fileIn;
    $chainHssp=   shift @fileInChain;
    $fileInFormat=shift @fileInFormat;
				# ------------------------------
				# convert format 
				# ------------------------------
    ($Lok,$msg,$fileHssp,$fileHsspHtm)=
	&getInputPhd($fileIn,$fileInFormat);
    if (! $Lok){	
	print "*-* after $scrName:getInputPhd: conversion failed\n" if ($par{"verb2"});
	next; }

    &wrtLoc("STDOUT")           if ($par{"verbose"});

                                # ------------------------------
				# cross-validation check
    $pdb_in="";			# ------------------------------
    $pdb_in=        
	&crossManager()         if ($par{"optIsCross"});
				# ----------------------------------------
				# ini PHD arguments
				# -> out GLOB: '$titleOne'
				# -> out GLOB: $FILE_PARA_SEC|ACC|HTM
				# -> out GLOB: $file{"fileOutPhd|Rdb"}
				# -> out GLOB: $file{"fileNotHtm"},
    ($Lok,$msg)=		# ----------------------------------------
	&getFiles1Phd($fileHssp,$chainHssp); 
                                &abortProg($msg) if (! $Lok);
				# ------------------------------
				# skip if output file existing
				# ------------------------------
    if (! $par{"doNew"} && -e $file{"fileOutRdb"}) {
	print 
	    ">>> ","* " x 30,"\n",">>> you choose doNew=0 -> existing files NOT over-written\n",
	    ">>> ",$file{"fileOutRdb"}," does exist! -> NO ACTION\n",">>> ","* " x 30,"\n";
	next; }
				# ******************************
				# RUN phd
				# ******************************
    if (defined $par{"LkeepExtIn"} && $par{"LkeepExtIn"}){
	$extadd=$fileHssp; $extadd=~s/^.*$par{"extHssp"}//g;
	foreach $kwd ("fileOutPhd","fileOutRdb","fileNotHtm"){
	    $file{$kwd}.=$extadd;
	}}
	
    ($Lok,$msg,%fileTmp)=    
	&phdRun($fileHssp,$fileHsspHtm,
		$chainHssp,$FILE_PARA_SEC,$FILE_PARA_ACC,$FILE_PARA_HTM,$par{"abbrPhdRdb"}, 
		$par{"optPhd"},$par{"optRdb"},$par{"exePhd"},
                $par{"exeHtmfil"},$par{"exeHtmref"},$par{"exeHtmtop"},
                $par{"optMach"},$par{"optKg"},$USERID_tmp,$par{"optIsDec"},$par{"optNice"},
                $par{"optDoHtmfil"},$par{"optDoHtmisit"},$par{"optHtmisitMin"},
                $par{"optDoHtmref"},$par{"optDoHtmtop"},
                $file{"fileOutPhd"},$file{"fileOutRdb"},$file{"fileNotHtm"},
                $par{"dirLib"},$par{"dirWork"},$par{"titleTmp"},$par{"jobid"},
                1,$par{"fileOutScreen"},$fhTrace2);
    print "--- output files: ",$file{"fileOutPhd"},",",$file{"fileOutRdb"},"\n"
        if ($USERID ne "rost" && $USERID ne "phd");
 
   if (! $Lok) {
#	&abortProg($msg); 
				# yy: make this a real file!!!
#	system("echo $fileHssp >> files-with-problems.list");
	
	print "-*- warning PHD failed on $fileHssp: \n","-*- $msg\n";
	next; }
    #           ^ keep debug = 1 in order to keep files for wrtRes1 !! (die one day yy)
				# temporary files
    if ((! $par{"debug"} || $#fileIn>1) && defined $fileTmp{"kwd"}) {
	foreach $kwdTmp (split(/,/,$fileTmp{"kwd"})){
	    $file{"$kwdTmp"}=$fileTmp{"$kwdTmp"}; push(@kwdRm,$kwdTmp); }}
				# ------------------------------
				# now writing output for one file
				# <-- ANCIENT, let it die out...
    ($Lok,$msg)=		#     ... one day (yy)
	&wrtRes1($titleOne);	# ------------------------------

    if (! $Lok) { print "*** ERROR in $scrName:wrtRes1 writing ",$titleOne,",for $fileHssp\n";
		  die ( "*** ERROR in $scrName:wrtRes1 writing ".$titleOne." for $fileHssp\n");}

				# ------------------------------
				# writing other PHD output formats
    ($Lok,$msg)= 
	&wrtRes1other()         if ($par{"doRetAli"} || $par{"doRetDssp"} || $par{"doRetHtml"} );
    print "-*- WARN $scrName: problem writing other (&wrtRes1other)\n".$msg."\n" if (! $Lok);
}				# --------------------------------------------------
				# end of loop over list
				# --------------------------------------------------

				# ------------------------------
				# final processing for list
&wrtList()                      if ($#fileIn > 1 && $par{"doPrepeval"});
				# ------------------------------
				# cleaning up
&cleanUp(@file_clean)           if (! $par{"debug"});

				# ------------------------------
				# final chatter and cleaning
$tmp=substr($par{"optPhd"},1,1); $tmp=~tr/[a-z]/[A-Z]/; $tmp.=substr($par{"optPhd"},2);
$des="headPhd".$tmp;

&wrtScreenFin($par{$des},$par{"fileOutPhd"}) 
    if ($USERID ne "phd");
    
exit;				# end of phd

#===============================================================================
#
#===============================================================================
sub ini {
    local ($txt,$it);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   ini                         initialises defaults and reads input arguments
#-------------------------------------------------------------------------------
    $sbrName="$scrName:"."ini";

    ($Lok,$msg)=		# set environment: @Date,$ARCH(LOC), $HOSTNAME, $USERID, $PATH
	&iniEnv();              return(0,"*** ERROR $sbrName: after iniEnv:\n".$msg) if (! $Lok);

    &iniDef();
				# ------------------------------
    %tmp=&iniHelpAdd();		# HELP stuff

	
    ($Lok,$msg)=		# want help?
	&iniHelpLoop($scrName,%tmp);   
                                return(&errSbrMsg("after ini:iniHelpLoop",$msg)) if (! $Lok);
    exit if ($msg eq "fin"); 

                                # ------------------------------
#    if ($USERID eq "phd"){	# PP specific reset
#	($Lok,$msg)=&iniDefPP();  return(&errSbrMsg("iniEnv",$msg))  if (! $Lok);}

                                # ------------------------------
				# security: libs
    $tmp=$0; $tmp=~s/phd\.pl.*//g;
    $tmp.="/"                   if ($tmp!~/\/$/);
    push(@INC,$tmp."scr",$tmp."scr/pack");

				# ------------------------------
				# include libraries
    foreach $lib ("exeLibCol","exeLibPhd"){
	return(0,"*** ERROR $sbrName: no perl library ".$par{"$lib"}," found\n".
               "--- PLEASE locate the library (supposedly in HOME_PHD/scr/\n".
               "--- and call PHD with:\n".
               "$scrName file.hssp $lib=PATH_OF_THE_LIB/LIBRARY\n".
               "--- or adjust the name in the program $scrName.pl (subroutine iniDef)\n")
            if (! -e $par{"$lib"});

	$Lok= require($par{"$lib"});

	return(0,"*** ERROR $sbrName: require lib $lib (".$par{"$lib"}.")\n".
	       "--- PLEASE locate the library (supposedly in HOME_PHD/scr/\n".
	       "--- and call PHD with:\n".
	       "$scrName file.hssp $lib=PATH_OF_THE_LIB/LIBRARY\n".
	       "--- or adjust the name in the program $scrName.pl (subroutine iniDef)\n")
	    if (! $Lok);}
                                # ------------------------------
                                # include packages
    foreach $exe ("exeHtmfil","exeHtmref","exeHtmtop",
#		  "exeHtmisit",
		  ) {
	next if ($par{"$exe"}=~/\.pl/);
	if (! -e $par{"$exe"}){
	    print "*** WARN or ERROR (?) $scrName: failed to find package ",$par{"$exe"},"\n";
	    next; }
	$Lok= require $par{"$exe"};
 	die("*** $scrName: failed to require perl package '".$par{"$exe"}."'\n") if (! $Lok); }

				# ------------------------------
    $timeBeg=     time;		# date and time
    $Date=        &sysDate();
				# ------------------------------
    ($Lok,$msg)=		# read command line input
	&iniRdCmdLine();        return(&errSbrMsg("iniRdCmdLine",$msg)) if (! $Lok);

    ($Lok,$msg)=		# correct settings (e.g. add directories)
	&iniSet();		return(&errSbrMsg("iniSet",$msg))       if (! $Lok);


    $exclude.="exeConvertSeqBig,";
    ($Lok,$msg)=		# error check for initial settings
	&iniError($exclude);	return(&errSbrMsg("iniError",$msg))     if (! $Lok);

				# security: add directory to temporary files
    $par{"fileOutTrace"}=
	$par{"dirWork"}.$par{"fileOutTrace"}  if (defined $par{"dirWork"} && $par{"dirWork"} &&
						  $par{"fileOutTrace"} !~ $par{"dirWork"});
    $par{"fileOutScreen"}=
	$par{"dirWork"}.$par{"fileOutScreen"} if (defined $par{"dirWork"} && $par{"dirWork"} &&
						  $par{"fileOutScreen"} !~ $par{"dirWork"});
                                # --------------------------------------------------
                                # trace file
                                # --------------------------------------------------
    if (defined $par{"fileOutTrace"} && $par{"fileOutTrace"} ne "unk" && 
        length($par{"fileOutTrace"}) > 0) {
        $fhTrace="FHTRACE_PHD";
        print "--- \t open $fhTrace for trace file ",$par{"fileOutTrace"}," \n" if ($par{"verb2"});
        &open_file("$fhTrace",">".$par{"fileOutTrace"}) || 
            return(&errSbr("failed to open new file for trace : ".$par{"fileOutTrace"}));}
    else {
	$fhTrace="STDOUT";}
    $fhTrace2=$fhTrace;
				# correct for debug mode
    if ($par{"debug"}){
	$par{"doCleanTrace"}=0;
	$fhTrace2="STDOUT";
	$par{"fileOutScreen"}=0; }
				# ------------------------------
    if ($par{"verbose"}){	# write initial settings 
	($Lok,$msg)=
	    &iniWrt();		return(&errSbrMsg("iniWrt",$msg))       if (! $Lok);}
    push(@file_clean,$par{"fileOutScreen"},$par{"fileOutTrace"})
	if ($par{"doCleanTrace"});

    return(1,"ok $sbrName");
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
    $sbrName="$scrName:"."iniEnv";
				# ------------------------------
    $USERID=&sysGetUserLoc();	# user

				# --------------------------------------------------
    $Lok=0;			# find perl libraries
				# Perl lib defined in environment?
    if    ($USERID eq "phd" && defined $ENV{'PPLIB'} && -d $ENV{'PPLIB'}){
	push(@INC,$ENV{'PPLIB'}); $par{"dirLib"}=$ENV{'PPLIB'};$Lok=1; }
				# Perl lib defined in environment?
    elsif ($USERID eq "rost" && defined $ENV{'PERLLIB'} && -d $ENV{'PERLLIB'}){ # 
	push(@INC,$ENV{'PERLLIB'}); $par{"dirLib"}=$ENV{'PERLLIB'};$Lok=1;}
				# in command line?
    foreach $arg(@ARGV){
	if ($arg=~/^dirLib/){$arg=~s/^dirLib=//g;$par{"dirLib"}=$tmp=$arg;$tmp=~s/\/$//g;
			     if (-d $tmp){ $Lok=1;
					   push(@INC,$tmp);}
			     last;}}
				# --------------------------------------------------
				# find perl libs (2)
    if (! $Lok){
	foreach $dir ("/home/rost/perl","/home/phd/ut/phd/scr"){
	    if (-d $dir){push(@INC,$dir);
			 last;}}}
				# --------------------------------------------------
				# find perl libs (3)
#    if (! $Lok && defined $USERID && $USERID eq "phd"){
#	foreach $dir ("/home/phd/ut/perl"){
#	    if (-d $dir){push(@INC,$dir);
#			 last;}}}
				# --------------------------------------------------
				# setenv ARCH 
				# --------------------------------------------------
    undef $ARCH;                # 
    foreach $arg (@ARGV) {      # given on command line?
        last if ($arg=~/^ARCH=(\S+)/i); }
    $ARCH=$1                    if (defined $1);
    $ARCH=~tr/[a-z]/[A-Z]/      if (defined $ARCH);	# lower to upper
    
    $ENV{'ARCH'}=0              if (! defined $ENV{'ARCH'} ||	
			    $ENV{'ARCH'}=~/UNK/i);

                                # given in local env ?
    $ARCH= $ARCH || $ENV{'ARCH'} || $ARCH_DEFAULT || 'unk';

				# --------------------------------------------------
				# only rost|phd|pp continue here !!!
				# --------------------------------------------------
                                # try to execute sh script
    if ($ARCH eq "unk") {
        $tmp=$0; $tmp=~s/\.\///g;$tmp=~s/^(.*\/).*$/$1/;
        $scr= $tmp              if (defined $tmp);
        $scr.="scr/which_arch.sh";
	$scr="/home/phd/ut/phd/scr/which_arch.sh" if (! -e $scr);
        if (-e $scr && -x $scr){ $ARCH=`$scr`; 
                                 $ARCH=~s/\s|\n//g; }}

                                # give in!!
    if (! defined $ARCH) {
        return(0,
	       "*** ERROR in $sbrName: GIVE the machine architecture by\n".
	       "$scrName file.hssp ARCH=ALPHA|SGI|SGI64|SUNMP\n"); }


				# get local directory
    if (! defined $ENV{'PWD'}) {
	open(C,"/bin/pwd|");$PWD=<C>;close(C);}
    else {
	$PWD=$ENV{'PWD'};}
				# path
#    $PATH=                      $ENV{'PATH'} ;
#    $ENV{'PATH'}=               "$PATH" . ":" . "/usr/local/bin/molbio" ;
#    $ENV{'FASTLIBS'}=           "/home/pub/molbio/fasta/fastgbs" ;
#    $ENV{'LIBTYPE'}=            "0" ;
    $PWD=                       $ENV{'PWD'};

    $ARCH=$ARCH || $ARCH_DEFAULT
	if ($USERID ne "rost" &&
	    $USERID ne "phd" &&
	    $USERID ne "pp");

    return(1,"ok $sbrName"); 
}				# end of iniEnv

#===============================================================================
sub iniDef {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iniDef                      sets defaults
#-------------------------------------------------------------------------------
    $sbrName="$scrName:"."iniDef";
				# d.d descriptors 
				# ------------------------------
				# directories

    $par{"dirData"}=            "/home/rost/data/"; # expects HSSP|Swiss-prot files here

				# ------------------------------
				# utility libraries (to be required)
				# PHD: scripts, executables
    $par{"dirMax"}=             $par{"dirPhd"};
#    $par{"dirMax"}=             $par{"dirHome"}.    "max/";

    $par{"dirLib"}=             $par{"dirPhd"}.     "scr/";
    $par{"dirPhdScr"}=          $par{"dirPhd"}.     "scr/";

    $par{"dirPhdPack"}=         $par{"dirPhdScr"}.  "pack/"; # directory with perl packages to include
    $par{"dirPhdBin"}=          $par{"dirPhd"}.     "bin/";
				# PHD: material
    $par{"dirPhdNet"}=          $par{"dirPhd"}.     "net/";
    $par{"dirPhdPara"}=         $par{"dirPhd"}.     "para/";
    $par{"dirPhdMat"}=          $par{"dirPhd"}.     "mat/";
    if ($LunderProf){
	$par{"dirLib"}=         $par{"dirPhd"}.     "embl/scr/";
	$par{"dirPhdScr"}=      $par{"dirPhd"}.     "embl/scr/";
	$par{"dirPhdScr2000"}=  $par{"dirPhd"}.     "scr/";
	$par{"dirPhdNet"}=      $par{"dirPhd"}.     "embl/net/";
#	$par{"dirPhdNetCross"}= $par{"dirPhdNet"}.  "embl/cross/";
	$par{"dirPhdPara"}=     $par{"dirPhd"}.     "embl/para/";
#	$par{"dirPhdParaCross"}=$par{"dirPhdPara"}. "embl/cross/";
	$par{"dirPhdMat"}=      $par{"dirPhd"}.     "embl/mat/";

    }
    $par{"dirPhdNetCross"}=     $par{"dirPhdNet"}.  "cross/";
    $par{"dirPhdParaCross"}=    $par{"dirPhdPara"}. "cross/";

				# input files (either dirIn, or dirHssp)
    $par{"dirHssp"}=            $par{"dirData"}.    "hssp/";
    $par{"dirDssp"}=            $par{"dirData"}.    "dssp/";
    $par{"dirSwiss"}=           $par{"dirData"}.    "swissprot/current/";
				# all data directories
    $#dirData=0; foreach $kwd("dirHssp","dirDssp","dirSwiss"){push(@dirData,$par{$kwd});}
				# maxhom stuff
    $par{"dirMaxMat"}=          $par{"dirMax"}.     "mat/";
				# input output directories
    $par{"dirIn"}=$par{"dirOut"}=$par{"dirWork"}=    
	                        "unk";
				# ------------------------------
				# executables
				# ------------------------------
				# binaries (fortran)
    $par{"exeHsspFilter"}=      $par{"dirPhdBin"}.  "filter_hssp.".     $ARCH;
    $par{"exeHsspFilter"}=      $par{"dirPhdBin"}.  "filter_hssp.".     $ARCH;
    $par{"exeConvertSeq"}=      $par{"dirPhdBin"}.  "convert_seq.".     $ARCH;
    $par{"exeConvertSeqBig"}=   $par{"dirPhdBin"}.  "convert_seq_big.". $ARCH;

				# hack
    $par{"exeConvertSeqBig"}=   
	$par{"exeConvertSeq"}   if (! -e $par{"exeConvertSeqBig"} &&
				    ! -l $par{"exeConvertSeqBig"});
    
    $par{"exePhd"}=             $par{"dirPhdBin"}.  "phd.".             $ARCH;
#    $par{"exePhd"}=             $par{"dirPhdBin"}.  "phd.".             $ARCH. "_big";
    if ($LunderProf){
	$par{"exePhd"}=         $par{"dirPhdBin"}.  "phd1994.".         $ARCH;
	$par{"exePhd"}=         $par{"dirPhdBin"}.  "phd1994_big.".     $ARCH;
    }
				# perl
    $par{"exePhd2msf"}=         $par{"dirPhdScr"}.  "conv_phd2msf.pl";
    $par{"exePhd2dssp"}=        $par{"dirPhdScr"}.  "conv_phd2dssp.pl";
    $par{"exePhd2html"}=        $par{"dirPhdScr"}.  "conv_phd2html.pl";

    $par{"exeHtmfil"}=          $par{"dirPhdScr"}.  "phd_htmfil.pl";
    $par{"exeHtmref"}=          $par{"dirPhdScr"}.  "phd_htmref.pl";
    $par{"exeHtmtop"}=          $par{"dirPhdScr"}.  "phd_htmtop.pl";
#    $par{"exeHtmisit"}=         $par{"dirPhdScr"}.  "phd_htmisit.pl";

#     $par{"exeHtmfil"}=          $par{"dirPhdPack"}. "phd_htmfil.pm";
#     $par{"exeHtmref"}=          $par{"dirPhdPack"}. "phd_htmref.pm";
#     $par{"exeHtmtop"}=          $par{"dirPhdPack"}. "phd_htmtop.pm";
#     $par{"exeHtmisit"}=         $par{"dirPhdPack"}. "phd_htmisit.pm";
    
    $par{"exeCopf"}=            $par{"dirPhdScr"}.  "copf.pl";          # executable for format conversion
    $par{"exeCopfPack"}=        $par{"dirPhdScr"}.  "pack/copf.pm";
    $par{"exeConvHssp2saf"}=    $par{"dirPhdScr"}.  "conv_hssp2saf.pl";	# converts HSSP 2 SAF
    $par{"exeHsspFilterPl"}=    $par{"dirPhdScr"}.  "hssp_filter.pl";   # filters HSSP files
    $par{"exeHsspFilterPack"}=  $par{"dirPhdScr"}.  "pack/hssp_filter.pm";   # filters HSSP files

    $par{"exePdbidSort"}=       $par{"dirPhdScr"}.  "pdbid_sort.pl";    # sorts by PDBid (ignore version no)
    $par{"exeRdb2pred"}=        $par{"dirPhdScr"}.  "conv_rdb2pred.pl";	# converts PHD.rdb to LIST.predre

    if ($LunderProf){
	$par{"exeCopf"}=          $par{"dirPhdScr2000"}.  "copf.pl";
	$par{"exeCopfPack"}=      $par{"dirPhdScr2000"}.  "pack/copf.pm";
	$par{"exeHsspFilterPl"}=  $par{"dirPhdScr2000"}.  "hssp_filter.pl";
	$par{"exeHsspFilterPack"}=$par{"dirPhdScr2000"}.  "pack/hssp_filter.pm";
    }
				# libraries
    $par{"exeLibCol"}=          $par{"dirLib"}.     "lib-col.pl";
    $par{"exeLibPhd"}=          $par{"dirPhdScr"}.  "lib-phd.pl";

				# ------------------------------
				# files
				# ------------------------------
				# input
    $fileIn=                    "unk";
    $chain=                     "unk";
    $par{"formatInput"}=        "HSSP|MSF|SAF|FASTA|PIR|SWISS";
				# headers (accuracy tables)
    $par{"headPhd3"}=           $par{"dirPhdMat"}.  "headPhd3.txt";
    $par{"headPhdBoth"}=        $par{"dirPhdMat"}.  "headPhdBoth.txt";
    $par{"headPhdConcise"}=     $par{"dirPhdMat"}.  "headPhdConcise.txt";
    $par{"headPhdAcc"}=         $par{"dirPhdMat"}.  "headPhdAcc.txt";
    $par{"headPhdHtm"}=         $par{"dirPhdMat"}.  "headPhdHtm.txt";
    $par{"headPhdSec"}=         $par{"dirPhdMat"}.  "headPhdSec.txt";
				# abbreviations
    $par{"abbrPhd3"}=           $par{"dirPhdMat"}.  "abbrPhd3.txt";
    $par{"abbrPhdBoth"}=        $par{"dirPhdMat"}.  "abbrPhdBoth.txt";
    $par{"abbrPhdAcc"}=         $par{"dirPhdMat"}.  "abbrPhdAcc.txt";
    $par{"abbrPhdHtm"}=         $par{"dirPhdMat"}.  "abbrPhdHtm.txt";
    $par{"abbrPhdSec"}=         $par{"dirPhdMat"}.  "abbrPhdSec.txt";
    $par{"abbrPhdRdb"}=         $par{"dirPhdMat"}.  "abbrPhdRdb3.txt";
				# help files
    $par{"fileHelpOpt"}=        $par{"dirPhdMat"}.  "help-options.txt";
    $par{"fileHelpMan"}=        $par{"dirPhdMat"}.  "help-manual.txt";
				# lists of cross-validation experiments
    $par{"fileListTrain"}=      $par{"dirPhdParaCross"}."list_trainlists_all";
    $par{"fileListTrainSecAcc"}=$par{"dirPhdParaCross"}."list_trainlists_secacc";
    $par{"fileListTrainHtm"}=   $par{"dirPhdParaCross"}."list_trainlists_htm";
				# phd parameters (giving architecture names)
    $par{"paraAcc"}=            $par{"dirPhdPara"}. "Para-exp152x-mar94.com";
#    $par{"paraAcc"}=            $par{"dirPhdPara"}. "Para-exp317-apr94.com";
    $par{"paraSec"}=            $par{"dirPhdPara"}. "Para-sec317-may94.com";
    $par{"paraHtm"}=            $par{"dirPhdPara"}. "Para-htm69-aug94.com";
				# undefine files with cross validation parameters
    foreach $des ("paraAccCross","paraHtmCross","paraSecCross"){
	$par{$des}=           "unk"; }
				# intermediate and output files
    $par{"jobid"}=              $$;
    $par{"title"}=              "unk";
				# title for temporary files
#    $par{"titleTmp"}=           "XPHD";
#    $par{"titleTmp"}=           "XPHD".$$;
    $par{"titleTmp"}=           "XPHD"."jobid";

    $par{"fileOutScreen"}=      $par{"titleTmp"}."-SCREEN.tmp";	# file dumping output from sys call
    $par{"fileOutTrace"}=       $par{"titleTmp"}."-TRACE.tmp";  # traces some of the PHD output

				# file extensions
    $par{"extPhd"}=             ".phd";
    $par{"extHssp"}=            ".hssp";
    $par{"extDssp"}=            ".dssp";
    $par{"extFasta"}=           ".fasta";
    $par{"extMsf"}=             ".msf";
    $par{"extSaf"}=             ".saf";
    $par{"extRdb"}=             ".rdbPhd";
    $par{"extRdbHtm"}=          ".rdbPhdHtm";
    $par{"extPhdMsf"}=          ".msfPhd";
    $par{"extPhdSaf"}=          ".safPhd";
    $par{"extPhdDssp"}=         ".dsspPhd";
    $par{"extNotHtm"}=          ".notHtm";
    $par{"extHtml"}=            "_phd.html";

    $par{"LkeepExtIn"}=         0;        # if 1: e.g. in = 1crn.hssp_fil -> out 1crn.phd_fil

				# ------------------------------------------------------------
				# further PHD parameters (default options)
				# ------------------------------------------------------------
				# PHD RUN
    $par{"optPhd"}=             "3";      # exp, sec, htm, exp+sec, 3

    $par{"optPara"}=            0;        # parameter file not passed as argument
    $par{"optPdbid"}=           "";       # PDBid to be excluded for cross-validation analysis
    $par{"optIsCross"}=         0;        # use best set, no cross-validation analysis

				# yy get out
    $par{"optHtmfin"}=          "fil";    # means final files (for lists) will contain filter
    $par{"optHtmfin"}=          "nof"; # means final files (for lists) will contain non filter
    $par{"optHtmfin"}=          "ref"; # means final files (for lists) will contain refined
				# yy get out end

    $par{"optDoHtmfil"}=        0;        # filter the prediction?
    $par{"optDoHtmisit"}=       1;        # check the exclusion stuff by htmisit (if best helix
			                  # of more than 18 residues score < n => not membrane)
    $par{"optDoHtmref"}=        1;        # refine the PHDhtm prediction?
    $par{"optDoHtmtop"}=        1;        # predict topology for transmembrane proteins?

#    $par{"optHtmisitMin"}=      0.7;     # qualify as notHTM if best helix score < min_val
    $par{"optHtmisitMin"}=      0.8;      # qualify as notHTM if best helix score < min_val

    $par{"doFilterHsspSafety"}= 1;        # filter large HSSP files to avoid crashes

    $par{"doFilterHssp"}=       0;        # filter the HSSP file for PHDacc by formula +5 (30%)

    $par{"doFilterHsspHtm"}=    1;        # filter the HSSP file for PHDhtm

				          # options for filter_hssp, see hssp_filter.pl for 
                                          # further details
    $par{"optFilterHssp"}=      "red=90 mode=ide";
    $par{"optFilterHsspHtm"}=   "red=90 mode=ide thresh=10";

    $par{"filterHsspVal"}=     30;        # i.e., filter HSSP file with formula+5
    $par{"filterHsspMetric"}=   $par{"dirMaxMat"}."Maxhom_GCG.metric"; # maxhom metric 
    $par{"keepFilterHssp"}=     0;        # if =1 the filtered HSSP file will not be deleted

    $par{"keepConvertHssp"}=    0;        # if =1 the converted HSSP file will not be deleted


				# output options
    $par{"optRdb"}=             "rdb";    # generate RDB file?
    $par{"optKg"}=              "no";     # generate file for KaleidaGraph?
    $par{"optUserPhd"}=         "no";     # for FORTRAN, if user = phd 'PHD'
    $par{"optMach"}=            "no";     # died out (machine readable)
    $par{"isTest"}=             0;        # use Para*test.com for test

    $par{"doRetDssp"}=          0;        # return DSSP formatted prediction
    $par{"doRetHtml"}=          0;        # return HTML formatted prediction

    $par{"riSubSec"}=           5;        # minimal RI for subset PHDsec
    $par{"riSubAcc"}=           4;        # minimal RI for subset PHDacc
    $par{"riSubHtm"}=           7;        # minimal RI for subset PHDhtm
    $par{"riSubSym"}=           ".";      # symbol for residues predicted with RI<SubSec/Acc
    $par{"nresPerRow"}=        60;        # number of residues per line in human readable files
				          # written for each protein
    $par{"nresPerRowAli"}=     50;        # number of residues per line in MSF output
    $par{"doRetHeader"}=        1;        # return text describing PHD accuracy
    $par{"doRetAli"}=           0;        # return MSF formatted prediction
    $par{"doRetAliExpand"}=     0;        # expand MSF returned
#    $par{"formatRetAli"}=       "msf";    # format of the file of PHD + ali
    $par{"formatRetAli"}=       "saf";    # format of the file of PHD + ali
    $par{"nresPerLineAli"}=    50;        # number of characters used for MSF file
    $par{"optPhd2msf"}=         0;        # =0|1|expand => expand insertions when HSSP -> MSF
    $par{"optHssp2msf"}=        0;        # =0|1, or e.g 'ARCH=SGI64 exe=convert_seq.SGI5 expand'
				          # add "expand " to expand insertions when HSSP -> MSF

    $par{"doPrepeval"}=         0;        # evaluation for list (only for known structures and lists)
				          #    if = 1, a list of RDB files is written and converted
				          #    to a file X.predrel
    $par{"doPrepevalSort"}=     1;        # sorts the final list X.predrel by PDBid (ignoring version no)
    $par{"doRdb2pred"}=         0;        # appends all RDB files into one long LIST.predrel

    $par{"doNew"}=              1;        # generate new PHD files even if old ones exist
				          #    if = 0, PHD is not run if old result files exist
				          #    note: this option is for running PHD on a list of files
    $par{"doSearchFile"}=       1;        # if =1, do search for database files
    $par{"doCleanTrace"}=       0;        # if =1, temporary files (OutScreen,OutTrace) deleted
    $par{"doCleanTrace"}=       1;        # if =1, temporary files (OutScreen,OutTrace) deleted
				# ------------------------------
				# general + logicals
				# ------------------------------
				# job control
    $par{"optNice"}=            "nice -15 ";
    $par{"optNice"}=            " ";
    $par{"verbose"}=            1; 
    $par{"verb2"}=              0;
    $par{"verb3"}=              0;
    $par{"debug"}=              0;        # if 1: keep intermediate files (some at least)
    $par{"optIsDec"}=           0;        # in case ARCH not set
    $par{"optDoEval"}=          0;        # include the analysis of accuracy if DSSP is known


       				# ------------------------------
       				# avoid maxhom overflow
       				# note: these are used to redundancy
       				#       filter too large alignments
       				# ------------------------------

    $par{"maxhomFortran_maxnali"}=    5000; # maximum number of alignments in HSSP file
    $par{"maxhomFortran_maxboth"}= 5000000; # maximum size of alignment (< length*number of alignments)

#    $par{"maxhomFortran_maxnali"}=    3000; # maximum number of alignments in HSSP file
#    $par{"maxhomFortran_maxboth"}= 2000000; # maximum size of alignment (< length*number of alignments)

				# ------------------------------
				# avoid warnings
				# ------------------------------
    $#kwdRm=$#protname=0;
    $Date=$timeBeg=$file_clean=$fileOutPhdOk=$fileOutRdbOk="";
    $FILE_PARA_SEC=$FILE_PARA_ACC=$FILE_PARA_HTM="";
				# ------------------------------
				# a.a descriptors 
				# allowed in default file
				# ------------------------------
#	 "---------------","---------------","---------------","---------------","---------------",
    @desDef=
	(
	 keys(%par)
	 );
#	 "---------------","---------------","---------------","---------------","---------------",
    @desFileOut=		# output files per protein
	("fileOutPhd",     "fileOutRdb",     "fileOutRdbHtm",  "fileNotHtm",    
	 "fileOutAli",     "fileOutDssp",    "fileOutHtml");
    @desFileOutCtrl=
	("fileOutScreen",  "fileOutTrace");
    @desFileOutList=
	("fileOutEvalsec", "fileOutEvalacc", "fileOutEvalhtm");
				# undefine output files
    foreach $des (@desFileOut){
	$par{$des}=           "unk"; }
    $#fileOutPhdOk=$#fileOutRdbOk=0;
}				# end of iniDef

#===============================================================================
sub iniDefPP {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iniDefPP                    sets defaults for user PP
#-------------------------------------------------------------------------------
    $sbrName="$scrName:"."iniDefPHD";
    $par{"dirPhd"}=             "/home/phd/ut/phd/";
    $par{"dirLib"}=             $par{"dirPhd"}.     "scr/";
    $par{"dirPhdScr"}=          $par{"dirPhd"}.     "scr/";
    $par{"dirPhdBin"}=          $par{"dirPhd"}.     "bin/";
				# PHD: material
    $par{"dirPhdNet"}=          $par{"dirPhd"}.     "net/";
    $par{"dirPhdNetCross"}=     $par{"dirPhdNet"}.  "cross/";
    $par{"dirPhdPara"}=         $par{"dirPhd"}.     "para/";
    $par{"dirPhdParaCross"}=    $par{"dirPhdPara"}. "cross/";
    $par{"dirPhdMat"}=          $par{"dirPhd"}.     "txt/";
				# input files (either dirIn, or dirHssp)
    $par{"dirHssp"}=            "/data/hssp/";
				# maxhom stuff
    $par{"dirMax"}=             "/home/phd/ut/max/";
    $par{"dirMaxMat"}=          $par{"dirMax"}.     "mat/";
				# fortran executables
    $par{"exeHsspFilter"}=      "/home/phd/bin/".$ARCH."/"."filter_hssp";
    $par{"exeConvertSeq"}=      "/home/phd/bin/".$ARCH."/"."convert_seq";
    $par{"exePhd"}=             "/home/phd/bin/".$ARCH."/"."phd";
				# perl scripts
    $par{"exePhd2msf"}=         $par{"dirPhdScr"}.  "conv_phd2msf.pl";
    $par{"exePhd2dssp"}=        $par{"dirPhdScr"}.  "conv_phd2dssp.pl";
    $par{"exeHtmfil"}=          $par{"dirPhdScr"}.  "phd_htmfil.pl";
    $par{"exeHtmref"}=          $par{"dirPhdScr"}.  "phd_htmref.pl";
    $par{"exeHtmtop"}=          $par{"dirPhdScr"}.  "phd_htmtop.pl";
#    $par{"exeHtmisit"}=         $par{"dirPhdScr"}.  "phd_htmisit.pl";
				# architectures used
    $par{"paraAcc"}=            $par{"dirPhdPara"}. "Para-exp152x-mar94.com";
    $par{"paraSec"}=            $par{"dirPhdPara"}. "Para-sec317-may94.com";
    $par{"paraHtm"}=            $par{"dirPhdPara"}. "Para-htm69-aug94.com";
}				# end of iniDefPP

#===============================================================================
sub iniHelpAdd {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iniHelpAdd                  initialise help text
#-------------------------------------------------------------------------------
    $sbrName="iniHelpAdd";

    $scrIn=      "HSSP|DSSP|MSF|SAF|PIR|FASTA|GCG|SWISS-PROT file";
    $scrGoal=    "runs PHDsec, PHDacc, PHDhtm";
    $scrNarg=    1;
    $scrHelpTxt="";		# for additional help texts

                                # ------------------------------
				# standard help
    $tmp=$0; $tmp=~s/^\.\///    if ($tmp=~/^\.\//);
    %tmp=('sourceFile', $tmp, 'scrName',$scrName, 'scrIn',$scrIn, 'scrGoal', $scrGoal, 
	  'scrNarg',$scrNarg, 'scrHelpTxt', $scrHelpTxt);

                                # ------------------------------
				# missing stuff
    $tmp{"s_k_i_p"}=         "problems,hints";

                                # ------------------------------
				# special help
#    $tmp{"scrAddHelp"}=      "";
    $tmp{"special"}=         "";


    undef %t;
#                            "------------------------------------------------------------\n";
    $t{"acc"}=               "predict solvent accessibility, only";
    $t{"sec"}=               "predict secondary structure,   only";
    $t{"htm"}=               "predict transmembrane helices, only";
    $t{"both"}=              "predict secondary structure and solvent accessibility";
    $t{"3"}=                 "predict sec + acc + htm          (see those 3 for more help)";
    $t{"cross"}=             "do cross-validation test         (NOT the best prediction!)";
    $t{"filter"}=            "filter the input HSSP file       (excluding some pairs)";
    $t{"doFilterHsspSafety"}="filter BIG HSSP files to prevent crash (excluding some pairs)";
    $t{"doFilterHssp"}=      "filter the input HSSP file         (excluding some pairs)";
    $t{"doFilterHsspHtm"}=   "filter the input HSSP file for PHDhtm (excluding some pairs, should be lower!)";

    $t{"notHtmisit"}=        "do NOT check whether or not membrane helix strong enough";
    $t{"notHtmfil"}=         "do NOT filter the membrane prediction";
    $t{"notHtmref"}=         "do NOT refine the membrane prediction";
    $t{"notHtmtop"}=         "do NOT membrane helix topology";

    $t{"noPhdHead"}=         "do NOT copy file with tables into local directory";

#                            "------------------------------------------------------------\n";
    $t{"doHtmisit"}=         "DO check strength of predicted membrane helix      (default)";
    $t{"doHtmfil"}=          "DO filter the membrane prediction                  (default)";
    $t{"doHtmref"}=          "DO refine the membrane prediction                  (default)";
    $t{"doHtmtop"}=          "DO membrane helix topology                         (default)";
    $t{"doEval"}=            "DO evaluation for list (only for known structures and lists)";

    $t{"dssp"}=              "convert PHD into DSSP format";
    $t{"msf"}=               "convert PHD into MSF format";
    $t{"saf"}=               "convert PHD into SAF format";
    $t{"expand"}=            "expand insertions when converting output to MSF format";
    $t{"html"}=              "convert PHD into HTML format";

    $t{"test"}=              "is just a test (faster)";

    $t{"keepConv"}=          "keep the conversion of the input file to HSSP format";

    $t{"noSearch"}=          "short for doSearchFile=0, i.e. no searching of DB files";

#                            "------------------------------------------------------------\n";
    $t{"filePhd"}=           "name of PHD output in human readable format    (file.phd)";
    $t{"fileRdb"}=           "name of PHD output in RDB format               (file.rdbPhd)";
    $t{"fileHtml"}=          "name of PHD output in HTML format              (file.htmlPhd)";
    $t{"fileRdbHtm"}=        "name of PHDhtm output in RDB format            (file.rdbPhd)";
    $t{"fileNotHtm"}=        "name of file flagging that no membrane helix was found";
#                            "------------------------------------------------------------\n";
    $t{"arch"}=              "system architecture (e.g.: SGI64|SGI5|SGI32|SUNMP|ALPHA)";
    $t{"user"}=              "user name";
    $t{"nice"}=              "give 'nice-D' to set the nice value (priority) of the job";

    $t{"nonice"}=            "job will not be niced, i.e. not run with lower priority";

    $t{"debug"}=             "keep most intermediate files";

    $t{"silent"}=            "no information written to screen";

    $t{"rdb2pred"}=          "for BR: append phd.RDB files into one long list.predrel ...";

    $t{"keepext"}=           "keep extension of input file, e.g. 1crn.hssp_fil -> 1crn.phd_fil";

#                            "------------------------------------------------------------\n";
#    $t{""}=              "";

    foreach $kwd (keys %t){
        $tmp{$kwd}=     $t{$kwd};
        $tmp{"special"}.= "$kwd".","; }

				# ------------------------------
				# help for input format
				# ------------------------------

    $tmp{"special"}.=        "help input".",";

#                            "------------------------------------------------------------\n";
    $tmp{"help input"}=      "\n";

    $tmp{"help input"}.=     "-" x 80 . "\n";
    $tmp{"help input"}.=     "   Syntax used to set parameters by command line:\n";
    $tmp{"help input"}.=     "     'keyword=value'\n";
    $tmp{"help input"}.=     "   to list all possible keywords, do:\n";

    $cmd1="$sourceFile help";
    $cmd2="$sourceFile help keyword";

    $tmp{"help input"}.=     "." x length($cmd1)."\n". "$cmd1\n". "." x length($cmd1)."\n";
    $tmp{"help input"}.=     "$cmd1\n"."    "."." x length($cmd1)."\n";
    $tmp{"help input"}.=     "  to get explanations about a particular keyword, do:\n";
    $tmp{"help input"}.=     "." x length($cmd2)."\n". "$cmd2\n". "." x length($cmd2)."\n";
    $tmp{"help input"}.=     "  \n";
    $tmp{"help input"}.=     "-------------------------------------------------------------------\n";
    $tmp{"help input"}.=     "  \n";
    $tmp{"help input"}.=     "  The following file formats may be handled by PHD at the moment:\n";
    $tmp{"help input"}.=     "     MSF|SAF|FASTAmul|FASTA|PIR|GCG|SWISS-PROT\n";
    $tmp{"help input"}.=     "  \n";
    $tmp{"help input"}.=     "-------------------------------------------------------------------\n";
    $tmp{"help input"}.=     "  -  For further  explanations, or for  other automatic  changes of\n";
    $tmp{"help input"}.=     "     file formats, please see the program copf:\n";
    $tmp{"help input"}.=     "     ".$par{"exeCopf"}."\n";
    $tmp{"help input"}.=     "  -  In particular, the most simple alignment format  SAF is speci-\n";
    $tmp{"help input"}.=     "     fied in detail in the copf help.\n";
    $tmp{"help input"}.=     "  \n";
    $tmp{"help input"}.=     "  To pass the input file to PHD, simply do:\n";

    $cmd1="$sourceFile YOUR_FILE";
    $cmd2="$sourceFile YOUR_FILE keepConv";
    $cmd3="$sourceFile YOUR_FILE debug";

    $tmp{"help input"}.=     "." x length($cmd1)."\n". "$cmd1\n". "." x length($cmd1)."\n";
    $tmp{"help input"}.=     "  *  NOTE: the automatic COnversion of Protein Formats (COPF) is not\n";
    $tmp{"help input"}.=     "           sufficiently tested, yet.  \n";
    $tmp{"help input"}.=     "           Thus, please cross-check the file generated. \n";
    $tmp{"help input"}.=     "  *  By default, PHD deletes most of the files it produces.\n";
    $tmp{"help input"}.=     "     To keep the files generated by COPF, do:\n";
    $tmp{"help input"}.=     "." x length($cmd2)."\n". "$cmd2\n". "." x length($cmd2)."\n";
    $tmp{"help input"}.=     "     \n";
    $tmp{"help input"}.=     "     To keep most intermediate files, and to obtain a detailed screen\n";
    $tmp{"help input"}.=     "     output, do:\n";
    $tmp{"help input"}.=     "." x length($cmd3)."\n". "$cmd3\n". "." x length($cmd3)."\n";
    $tmp{"help input"}.=     "  \n";
    $tmp{"help input"}.=     "";

    return(%tmp);
}				# end of iniHelpAdd

#===============================================================================
sub iniHelpLoop {
    local($promptLoc,%tmp)=@_;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iniHelpLoop                 loop over help 
#       in/out:                 see iniHelp
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="iniHelpLoop";$fhinLoc="FHIN_"."iniHelpLoop";

    ($Lok,$msg)=		# want help?
	&iniHelp(%tmp);       
                                return("*** ERROR$sbrName: after iniHelp\n",$msg,"\n") if (! $Lok);
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
	$ct=0;
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
		&get_in_keyboardLoc("type",$def,$promptLoc);

				# <--- QUIT
	    $tmp=$ansr;$tmp=~s/\s//g;
	    if ($ansr=~/^[q|quit|e|exit]$/) { 
		$Lquit=1; 
		last; }
				# redefine @ARGV
	    @ARGV=split(/\s+/,$ansr);
	    $ARGV[1]="help"     if ($ARGV[1] eq "h" || $ARGV[1] eq "H");
	    $ARGV[1]="def"      if ($ARGV[1] eq "d" || $ARGV[1] eq "D");

	    ++$ct;
				# add keyword help
	    if ($ct > 1 && $#ARGV < 2) {
		$ARGV[2]=$ARGV[1];
		$ARGV[1]="help";}
	    
	    $txt1="start again with(";
	    $txt2=join(' ',@ARGV);
	    $lenfin=80 - 6 - (length($txt1) + length($txt2));
	    print "--- ","-" x length($txt1),"#" x length($txt2),"--", "-" x $lenfin,"\n";
	    print "--- ",$txt1,$txt2,")\n";
	    print "--- ","-" x length($txt1),"#" x length($txt2),"--", "-" x $lenfin,"\n";

				# call again
	    ($Lok,$msg)=
		&iniHelp(%tmp); return("*** ERROR$sbrName: after iniHelp",$msg) if (! $Lok);
				# <--- QUIT
	    $Lquit=1            if ($msg eq "fin");
	} 
	$msg="fin";
    }
    return(1,$msg);
}				# end of iniHelpLoop

#===============================================================================
sub iniHelp {
    local(%tmp)=@_;
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iniHelp                     initialise help text
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
    $sbrName="iniHelp"; 
				# ------------------------------
				# check input
    if (0){
	foreach $kwd ("sourceFile","scrName","scrIn","scrGoal","scrNarg","scrAddHelp","special"){
	    print "--- input to $sbrName kwd=$kwd, val=",$tmp{$kwd},",\n";}
    }
    @scrTask=
        ("--- ",
	 "--- Task:  ".$tmp{"scrGoal"},
         "--- ",
         "--- =======". "=" x length($tmp{"scrIn"}),
         "--- Input: ".$tmp{"scrIn"},
         "--- =======". "=" x length($tmp{"scrIn"}),
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
	 $tmp{"scrName"}.".pl manual        : will cat the entire manua (.. may be it will)")
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
		foreach $kwd (@kwdLoc){$tmp=" "; $tmp=$tmp{$kwd} if (defined $tmp{$kwd});
				       printf "---   %-15s %-s\n",$kwd,$tmp;}}}
	print 
	    "-" x 80,"\n",
	    "---    Syntax used to set parameters by command line:\n",
	    "---       'keyword=value'\n",
	    "---    where 'keyword' is one of the following keywords:\n";
	if (-e $par{"fileHelpOpt"}){
	    open("FHIN",$par{"fileHelpOpt"}) || 
		warn "*** $sbrName: could NOT open file".$par{"fileHelpOpt"};
	    while(<FHIN>){
		next if ($_=~/^\#/);
		$line=$_;
		$tmp=$_;$tmp=~s/\s//g;
		next if (length($tmp)<2);
		print $line;}close(FHIN);
	    print
		"-" x 80,"\n",
		"--- REPEAT:\n",
		"---    Syntax used to set parameters by command line:\n",
		"---       'keyword=value'\n",
		"---    where 'keyword' is one of the above keywords.\n";}
	else {
            @kwdLoc=sort keys (%par);
            if ($#kwdLoc>1){
                $ct=0;
                print "OPT \t ";
                foreach $kwd(@kwdLoc){
                    ++$ct;
                    printf "%-20s ",$kwd;
                    if ($ct==4){$ct=0;print "\nOPT \t ";}}print "\n";}}
	print 
	    "--- \n",
	    "---    you may (or may not) get further explanations on a particular keyword by:\n \n",
	    $scrName.".pl help keyword\n \n",
	    "---    this could explain the key.  Type 'how' for info on 'how,howie,show'.\n",
	    "---    And 'com.*ated' for info on 'complicated,comated,commercially_inflated'\n",
	    "--- \n";
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
    elsif ($#ARGV<2  && $ARGV[1] eq "hints"){
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
                    printf "--- %-20s = %-s\n",$kwd,$par{$kwd};}
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
	$tmpSpecial=0;
	$tmpSpecial=$tmp{"$tmp"}  if (defined $tmp{"$tmp"});
	$tmpSpecial=$tmp{"$tmp2"} if (! defined $tmp{"$tmp"} && defined $tmp{"$tmp2"});

        $#kwdLoc=$#expLoc=0;    # (1) get all respective keywords
        if (defined %par){
            @kwdLoc=keys (%par);$#tmp=0;
            foreach $kwd (@kwdLoc){
                push(@tmp,$kwd) if ($kwd =~/$kwdHelp/i);}
            @kwdLoc=sort @tmp;}
                                # (2) is there a 'help option file' ?
	$Lerr=1;
        if (defined $par{"fileHelpOpt"} && -e $par{"fileHelpOpt"} ){
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
		    print $_; $Lerr=0;
		    next;}
		elsif ($Lok && $_!~/^\s/){
		    $Lok=0;}
		if (! $Lok && $_ !~ /^[\s\t]+/){
		    $line=$_;
		    ($tmp1,$tmp2)=split(/[\s\t]+/,$_);
		    $Lok=1      if (length($tmp1)>1 && $tmp1 =~ /$kwdHelp/i);
		    $Lerr=0     if ($Lok);
		    print $line if ($Lok);}}close(FHIN);
	    print "-" x 80, "\n";}
	if ($Lerr) {		# (3) else: read itself
            ($Lok,$msg,%def)=
		&iniHelpRdItself($0);
            die '.....   verrry sorry the option blew up ... ' if (! $Lok);
	    $def{"kwd"}=""      if (! $Lok); # hack: short cut error
            @kwdLoc=split(/,/,$def{"kwd"});$#tmp=0;
            foreach $kwd (@kwdLoc){
                if ($kwd =~/$kwdHelp/i){
                    push(@tmp,$kwd); 
                    if (defined $def{$kwd}){
                        $def{$kwd}=~s/\n[\t\s]*/\n---                        /g;
                        push(@expLoc,$def{$kwd});}
                    else {push(@expLoc," ");}}}
            @kwdLoc=@tmp; }
	$Lerr=1;
	if ($#kwdLoc>0){	# (4) write the stuff
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
	    foreach $txt (split(/\n/,$tmpSpecial)){
		$txtTmp="";
		foreach $txt2 (split(/,/,$txt)) {
		    $txtTmp.=$txt2.",";
		    if (length($txtTmp) > 60) {
			print "---       $txtTmp\n";
			$txtTmp="";}}
		print "--- $txtTmp\n"; }
	    $Lerr=0;} 
	print 
	    "--- \n",
	    "--- sorry, no explanations found for keyword '$kwdHelp'\n",
	    "--- \n" if ($Lerr);
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
                    printf "--- %-20s = %-s\n",$kwd,$par{$kwd};}
                printf "--- %-20s   %-s\n","." x 20,"." x 53;
                print  " \n";}}
	else { print "--- sorry, no setting defined in \%par\n";}
	return(1,"fin loop?");}

    return(1,"ok $sbrName");
}				# end of iniHelp

#===============================================================================
sub iniHelpRdItself {
    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iniHelpRdItself             reads the calling perl script (scrName),
#                               searches for 'sbr iniDef', and gets comment lines
#       in:                     perl-script-source
#       out:                    (Lok,$msg,%tmp), with:
#                               $tmp{"kwd"}   = 'kwd1,kwd2'
#                               $tmp{"$kwd1"} = explanations for keyword 1
#-------------------------------------------------------------------------------
    $sbrName="iniHelpRdItself";$fhinLoc="FHIN_"."iniHelpRdItself";

    open("$fhinLoc","$fileInLoc") ||
        return(0,"*** ERROR $sbrName: old '$fileInLoc' not opened\n");
                                # read file
    while (<$fhinLoc>) {        # search for initialising subroutine
        last if ($_=/^su[b] iniDef.* \{/);}
    $Lis=0;undef %tmp; $#tmp=0;
    while (<$fhinLoc>) {        # read lines with '   %par{"kwd"}= $val  # comment '
        $_=~s/\n//g;
        last if ($_=~/^su[b] .*\{/ && $_!~/^su[b] iniDef.* \{/);
        if    ($_=~/[\s\t]+\$par\{[\"\']?([^\"\'\}]+)[\"\']?\}[^\#]* \# (.*)$/){
            $Lis=1;$kwd=$1; push(@tmp,$kwd);$tmp{$kwd}=$2 if (defined $2);}
        elsif ($Lis && defined $tmp{$kwd} && $_=~/^[\s\t]+\# ?\-+/){
            $Lis=0;}
        elsif ($Lis && defined $tmp{$kwd} && $_=~/^[\s\t]*\# (.*)$/){
            $tmp{$kwd}.="\n".$1;}
        elsif ($Lis){
            $Lis=0;}}close($fhinLoc);
    $tmp{"kwd"}=join(',',@tmp);
    return(1,"ok $sbrName",%tmp);
}				# end of iniHelpRdItself

#===============================================================================
sub iniRdCmdLine {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iniRdCmdLine                gets all command line arguments
#-------------------------------------------------------------------------------
    $sbrName="$scrName:"."iniRdCmdLine";
				# ------------------------------
				# before input file!
				# ------------------------------
    foreach $_ (@ARGV){
	next if ($_=~/^ARCH=/);
	if ($_=~/^dirIn=(\S*)$/) { 
	    $par{"dirIn"}=$1; 
	    last;}}
				# --------------------------------------------------
				# interpret all input arguments
				# --------------------------------------------------
    foreach $_  (@ARGV){
	next if ($_=~/^ARCH=/);
				# ------------------------------
				# interpret special keywords
				# ------------------------------
	if   ($_ eq "acc")               { $par{"optPhd"}=         "acc"; }
	elsif($_ eq "htm")               { $par{"optPhd"}=         "htm"; }
	elsif($_ eq "sec")               { $par{"optPhd"}=         "sec"; }
	elsif($_ eq "both"|$_ eq "acc+sec"|$_ eq "sec+acc")
	                                 { $par{"optPhd"}=         "both";}
	elsif($_ eq "3")                 { $par{"optPhd"}=         "3";}
	elsif($_ eq "cross")             { $par{"optIsCross"}=     1; }
	elsif($_=~/^pdbid=(.*)$/)        { $par{"optIsCross"}=     1; 
					   $par{"optPdbid"}=       $1; 
					   $par{"optPdbid"}=~s/\s//g;}
					   
	elsif($_ =~/keepext\S*/i)        { $par{"LkeepExtIn"}=     1; }

	elsif($_ eq "filter")            { $par{"doFilterHssp"}=   1; }
	elsif($_ eq "doFilterHssp")      { $par{"doFilterHssp"}=   1; }
	elsif($_ eq "notHtmisit")        { $par{"optDoHtmisit"}=   0; }
	elsif($_ eq "notHtmfil")         { $par{"optDoHtmfil"}=    0; }
	elsif($_ eq "notHtmref")         { $par{"optDoHtmref"}=    0; }
	elsif($_ eq "notHtmtop")         { $par{"optDoHtmtop"}=    0; }
	elsif($_ eq "doHtmisit")         { $par{"optDoHtmisit"}=   1; }
	elsif($_=~/^min=([\d\.]+)$/)     { $par{"optDoHtmisit"}=   1; 
					   $par{"optHtmisitMin"}=  $1;
					   $par{"optHtmisitMin"}=  0  if ($1 < 0);
					   $par{"optHtmisitMin"}=  1  if ($1 > 1);}

	elsif($_ eq "doHtmfil")          { $par{"optDoHtmfil"}=    1; }
	elsif($_ eq "doHtmref")          { $par{"optDoHtmref"}=    1; }
	elsif($_ eq "doHtmtop")          { $par{"optDoHtmtop"}=    1; }

	elsif($_ =~ /^skip[A-Za-z]*$/)   { $par{"doNew"}=          0; }
	elsif($_ =~ /^noSearch/i)        { $par{"doSearchFile"}=   0; }

	elsif($_ =~ /^noPhdHead/i)       { $par{"doRetHeader"}=    0; }
	elsif($_ eq "dssp")              { $par{"doRetDssp"}=      1; }
	elsif($_ eq "html")              { $par{"doRetHtml"}=      1; }
	elsif($_ eq "msf")               { $par{"doRetAli"}=       1; 
					   $par{"formatRetAli"}=   "msf";}
	elsif($_ eq "saf")               { $par{"doRetAli"}=       1; 
					   $par{"formatRetAli"}=   "saf";}
	elsif($_ eq "expand")            { $par{"doRetAli"}=       1;
					   $par{"doRetAliExpand"}= 1; }
	elsif($_ eq "test")              { $par{"isTest"}=         1;}
	elsif($_ eq "tst")               { $par{"isTest"}=         1;}
	elsif($_ eq "rdb2pred")          { $par{"doPrepeval"}=     1;
					   $par{"doRdb2pred"}=     1; }
	elsif($_=~/^filePhd=(\S*)$/)     { $par{"fileOutPhd"}=     $1;}
	elsif($_=~/^fileRdb=(\S*)$/)     { $par{"fileOutRdb"}=     $1;}
	elsif($_=~/^fileRdbHtm=(\S*)$/)  { $par{"fileOutRdbHtm"}=  $1;}
	elsif($_=~/^fileNotHtm=(\S*)$/)  { $par{"fileNotHtm"}=     $1;}
	elsif($_=~/^fileDssp=(\S*)$/)    { $par{"fileOutDssp"}=    $1;
					   $par{"doRetDssp"}=      1; }
	elsif($_=~/^fileAli=(\S*)$/)     { $par{"fileOutAli"}=     $1; 
					   $par{"doRetAli"}=       1; }
	elsif($_=~/^fileHtml=(\S*)$/)    { $par{"fileOutHtml"}=    $1; 
					   $par{"doRetHtml"}=      1; }
	elsif($_=~/^user=(\S*)$/)        { $USERID=                $1;}
	elsif($_=~/^nice-(\d+)$/)        { $par{"optNice"}=        "nice -".$1;}
	elsif($_ eq "nonice")            { $par{"optNice"}=        " ";}
	elsif($_ =~/^de?bu?g$/i)         { $par{"debug"}=          1;}
	elsif($_ eq "debug")             { $par{"debug"}=          1;}
	elsif($_=~/^Para/)               { $par{"optPara"}=        $_;}

	elsif($_=~/^verb3/)              { $par{"verb3"}=          1; }
	elsif($_=~/^verb2/)              { $par{"verb2"}=          1; }
	elsif($_=~/^verb/)               { $par{"verbose"}=        1; }
	elsif($_=~/no.?Screen/i)         { $par{"verbose"}=        0; }
	elsif($_=~/silent/i)             { $par{"verbose"}=        0; }
	elsif($_=~/^keepConv[A-Za-z]*$/) { $par{"keepConvertHssp"}=1; }
	elsif($_=~/^keepFil[A-Za-z]*$/)  { $par{"keepFilterHssp"}= 1; }

	elsif($_=~/^exe=(\S+)$/)         { $par{"exePhd"}=         $1; }
	elsif($_=~/^exephd=(\S+)$/i)     { $par{"exePhd"}=         $1; }
	elsif($_=~/^exefor=(\S+)$/i)     { $par{"exePhd"}=         $1; }

	elsif($_=~/^(eval|accuracy)$/i)  { $par{"optDoEval"}=      1; }


				# ------------------------------
				# now all other options
				# ------------------------------
	else {
	    $Lok=0; $arg=$_;
	    foreach $des (@desFileOut,@desFileOutCtrl,@desDef){
		if ($arg=~/^$des=(.*)$/){ 
		    $par{$des}=$1; $Lok=1; 
		    last; }}
	    next if ($Lok);
				# no keyword: is it input file?
	    if (defined $par{"dirIn"} && -d $par{"dirIn"}){
		@tmp=($par{"dirIn"},@dirData); }
	    else{
		@tmp=@dirData; }
				# purge chains
	    $arg_nochain=$arg; $arg_nochain=~s/(\.[hd]ssp)_[A-Z0-9a-z]$/$1/g;
				# quick search for file format
	    $format=0;
				# no search
	    next if ((! -e $arg || ! -e $arg_nochain) && ! $par{"doSearchFile"});
	    if (-e $arg_nochain){
		($Lok,$msg)=
		    &getFileFormatQuick($arg_nochain);
		return(&errSbrMsg("$arg failed getting format",$msg)) 
		    if (! $Lok);
		$format=$msg;
		if ($format ne "unk"){
		    push(@fileIn,$arg_nochain); 
		    $chain=" ";
		    if ($arg_nochain ne $arg){
			$chain=$arg; $chain=~s/^.*\.[hd]ssp_([a-z0-9A-Z])$/$1/g; }
		    push(@fileInChain,$chain);
		    push(@fileInFormat,$msg);}
				# detailed file search
		if (! $format || $format eq "unk"){
		    push(@tmp,"noSearch") if (! $par{"doSearchFile"});
		    ($Lok,$msg,%fileIn)=
			&getFileFormat($arg,$par{"formatInput"},@tmp);
		    return(0,"*** ERROR $sbrName format of input file '$arg' not accepted\n".
			   " $msg\n")
			if (! $Lok);
		    foreach $it (1..$fileIn{"NROWS"}){
			next if (! -e $fileIn{"$it"});
			push(@fileIn,$fileIn{"$it"});
			$fileIn{"chain","$it"}=" " if (! defined $fileIn{"chain","$it"});
			push(@fileInFormat,$fileIn{"format","$it"});
			push(@fileInChain, $fileIn{"chain","$it"});}}}
	    return(0,"*** ERROR $sbrName unknown command line arg '$arg'\n") if (! $Lok);}
    }
				# ------------------------------
				# hierarchy of verbose
				# ------------------------------
    if    ($par{"debug"})    { $par{"verbose"}=$par{"verb"}=$par{"verb2"}=$par{"verb3"}=1; }
    elsif (! $par{"verbose"}){ $par{"verb"}=1; $par{"verb2"}=$par{"verb3"}=0; }
    elsif (! $par{"verb2"})  { $par{"verb3"}=0; }

				# ------------------------------
				# get input files
				# ------------------------------
    
    return(0,"*** ERROR $sbrName: input file not correctly processed (none found)\n") 
	if ($#fileIn == 0);
 
    undef %fileIn; $fileIn{"NROWS"}=$#fileIn;
    foreach $it (1..$#fileIn) { $fileIn{"$it"}=         $fileIn[$it];
				$fileIn{"chain","$it"}= $fileInChain[$it];
				$fileIn{"format","$it"}=$fileInFormat[$it]; }

				# skip non-existing
    $#fileIn=$#fileInFormat=$#fileInChain=0;
    foreach $it (1..$fileIn{"NROWS"}){
	next if (! -e $fileIn{"$it"});
	push(@fileIn,$fileIn{"$it"});
	$fileIn{"chain","$it"}=" " if (! defined $fileIn{"chain","$it"});
	push(@fileInFormat,$fileIn{"format","$it"});
	push(@fileInChain, $fileIn{"chain","$it"});}
    return(0,"*** ERROR $sbrName: no accepted input files\n") if ($#fileIn==0);
    return(1,"ok $sbrName");
}				# end of iniRdCmdLine

#===============================================================================
sub iniSet {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iniSet                      final correction of parameters
#-------------------------------------------------------------------------------
    $sbrName="$scrName:"."iniSet";
				# ------------------------------
				# default title for output files
    if (! defined $par{"title"} || ! $par{"title"} || $par{"title"} eq "unk"){
	if ($#fileIn>1){	# correct for input list (many input files)
	    $par{"title"}="ID";}
	else {
	    $file= $fileIn[1];
	    $chain=$fileIn{"chain","1"};
	    $id=&get_id($file); $id=~s/^unk//g;
	    if (defined $chain && length($chain)==1 && $chain ne " "){
		$par{"title"}=$id.$chain;}
	    else {
		$par{"title"}=$id;}}
				# security: purge extensions
	$par{"title"}=~s/^.*\/|\.(hssp|msf|pir|f|gcg|dssp|saf).*$//g;
	$par{"title"}=~s/unk\_/\_/;}

				# ------------------------------
				# correct jobid
    if (defined $par{"title"} && $par{"title"} && $par{"title"} ne "unk" &&
	$par{"title"}=~/jobid/) {
				# does already match
	if ($par{"title"}=~/$par{"jobid"}/) {
	    $par{"title"}=~s/jobid//g; }
	else {
	    $par{"title"}=~s/jobid/$par{"jobid"}/;}}

    if (defined $par{"titleTmp"} && $par{"titleTmp"} && $par{"titleTmp"} ne "unk" &&
	$par{"titleTmp"}=~/jobid/) {
				# does already match
	if ($par{"titleTmp"}=~/$par{"jobid"}/) {
	    $par{"titleTmp"}=~s/jobid//g; }
	else {
	    $par{"titleTmp"}=~s/jobid/$par{"jobid"}/; }}

				# ------------------------------
				# input, output, working  directory (default = local)
    foreach $dir ("dirIn","dirOut","dirWork"){
	if (! defined $par{$dir}  || $par{$dir} eq "unk"){
	    $par{$dir}="";}
	else {
	    $par{$dir}=&complete_dir($par{$dir});}}

				# ------------------------------
				# PHD run options
    $#optPhd=0;
    push(@optPhd,"sec","acc","htm") if ($par{"optPhd"} eq "3");
    push(@optPhd,"sec","acc")       if ($par{"optPhd"} eq "both");
    push(@optPhd,$par{"optPhd"})    if ($par{"optPhd"} eq "sec"|
					$par{"optPhd"} eq "acc"|
					$par{"optPhd"} eq "htm");
    undef %optPhd; 
    foreach $optPhd(@optPhd) {$optPhd{"$optPhd"}=1;}

    if ($par{"isTest"}){
	$par{"paraAcc"}=            $par{"dirPhdPara"}. "Para-exptest.com";
	$par{"paraSec"}=            $par{"dirPhdPara"}. "Para-test.com";
	$par{"paraHtm"}=            $par{"dirPhdPara"}. "Para-htmtest.com";}

				# correction for parameter (if passed)
    if ($#optPhd==1 && defined $par{"optPara"} && -e $par{"optPara"} ){
	$kwdPara=substr($par{"optPhd"},1,1);$kwdPara=~tr/[a-z]/[A-Z]/;
	$kwdPara="para".$kwdPara.substr($par{"optPhd"},2);
	$par{"$kwdPara"}=$par{"optPara"} 
	if ( (! defined $par{"$kwdPara"}) || ($par{"$kwdPara"} =~ /^no|^unk/) );}

				# add directories to parameters
    $dirPhdParaTmp=$par{"dirPhdPara"};$dirPhdParaTmp=~s/\/$//g;
    foreach $kwd ("paraSec","paraAcc","paraHtm"){
	$par{$kwd}=$par{"dirPhdPara"}.$par{$kwd} if (! -e $par{$kwd} && -d $par{"dirPhdPara"});
	return(0,"*** ERROR $sbrName missing parameter file $kwd=",$par{$kwd},",\n") 
	    if (! -e $par{$kwd});}

				# ------------------------------
				# final output file names
    $par{"fileOutRdbHtm"}=0     if ($par{"optPhd"}=~/^(htm|acc|sec|both|acc\+sec|sec\+acc)/);
    $par{"fileNotHtm"}=0        if ($par{"optPhd"}=~/^(acc|sec|both|acc\+sec|sec\+acc)/);
    $par{"fileOutAli"}=0        if (! $par{"doRetAli"});
    $par{"fileOutDssp"}=0       if (! $par{"doRetDssp"});

				# format
    $par{"formatRetAli"}=~tr/[A-Z]/[a-z]/;

				# ------------------------------
                                # output files per protein: 
                                #    build up file names
    foreach $des (@desFileOut){
	next if (! $par{$des});
				# only fill in if not given on command line
	next if ($par{$des} ne "unk" && length($par{$des})>1 && $par{$des}!~/title/);
	$kwdx=$des;$kwdx=~s/fileOut/ext/;
	$kwdx=~s/file/ext/      if ($des eq "fileNotHtm");
	$kwdx="extPhdMsf"       if ($des eq "fileOutAli" && $par{"formatRetAli"} eq "msf");
	$kwdx="extPhdSaf"       if ($des eq "fileOutAli" && $par{"formatRetAli"} ne "msf");
	$kwdx="extPhdDssp"      if ($des eq "fileOutDssp");
	return(0,"*** ERROR $sbrName extension $kwdx not defined\n") 
	    if (! defined $par{"$kwdx"} || $par{"$kwdx"} eq "unk");
	$par{$des}=$par{"title"}.$par{"$kwdx"};}

                                # temporary files
    foreach $des (@desFileOut){
	next if (! defined $par{$des}); # note: e.g. for MSF/DSSP
	next if ($par{$des}=~/$par{"dirWork"}/);
	next if (! $par{$des});
        $par{$des}=$par{"dirWork"}.$par{$des}; }

				# replace jobid
    foreach $des (@desFileOut,@desFileOutCtrl,@desFileOutList){
	next if (! defined $par{$des});
	next if ($par{$des} !~/jobid/);
	if ($par{$des}=~/$par{"jobid"}/) {
	    $par{$des}=~s/jobid//g;
	    next; }
	$par{$des}=~s/jobid/$par{"jobid"}/; }


				# add output directory
    if (defined $par{"dirOut"} && length($par{"dirOut"})>1 && $par{"dirOut"} ne "unk"){
				# make directory if missing
	if (! -d $par{"dirOut"}){
	    $tmp=$par{"dirOut"};$tmp=~s/\/$// if ($tmp=~/\/$/);
	    mkdir($tmp,umask);
	    return(&errSbr("could not make output dir=".$par{"dirOut"})) if (! $Lok);}
				# add output directory to file name (default = local)
	foreach $des (@desFileOut){
	    next if (! $par{$des});
	    next if ($par{$des}=~/$par{"dirOut"}/);
	    next if (! $par{$des});
	    $par{$des}=$par{"dirOut"} . $par{$des};
	}}
				# ------------------------------
                                # again correct // -> /, and \s \n
    foreach $des (@desFileOut){
	next if (! defined $par{$des} || ! $par{$des});
	next if ($par{$des} !~/[\s\n\/]/);
	$par{$des}=~s/\/\//\//g;
        $par{$des}=~s/\s|\n//g;}
    foreach $des (@desDef){
	next if (! defined $par{$des} || ! $par{$des});
	next if ($par{$des} !~/[\s\n\/]/);
	$par{$des}=~s/\/\//\//g;
        $par{$des}=~s/^\s*|\s*$|\n//g;}

				# ------------------------------
				# output files: overall
				# ------------------------------
    if ($par{"doPrepeval"}){
	$par{"fileOutEvalsec"}=$par{"dirOut"}.$par{"titleTmp"}.$par{"jobid"}.".predrel"
	    if (! defined $par{"fileOutEvalsec"} || ! $par{"fileOutEvalsec"} ||
		$par{"fileOutEvalsec"} eq "unk");
	$par{"fileOutEvalhtm"}=$par{"dirOut"}.$par{"titleTmp"}.$par{"jobid"}.".predrel"
	    if (! defined $par{"fileOutEvalhtm"} || ! $par{"fileOutEvalhtm"} ||
		$par{"fileOutEvalhtm"} eq "unk");
	$par{"fileOutEvalacc"}=$par{"dirOut"}.$par{"titleTmp"}.$par{"jobid"}.".exprel"
	    if (! defined $par{"fileOutEvalacc"} || ! $par{"fileOutEvalacc"} ||
		$par{"fileOutEvalacc"} eq "unk"); }

				# ------------------------------
				# further correction for user BR/PP
    if ($USERID =~ /^(rost|phd)/){
	$par{"doRetHeader"}=0;}

    $optNice=$par{"optNice"};
    if ($optNice=~/nice\s*-/) { $optNice=~s/nice-/nice -/;
				$tmp=$optNice;$tmp=~s/\s|nice|\-|\+//g;
				setpriority(0,0,$tmp) if (length($tmp)>0);}

    return(1,"ok $sbrName");
}				# end of iniSet

#===============================================================================
sub iniError {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iniError                    error check for initial parameters
#-------------------------------------------------------------------------------
    $sbrName="$scrName:"."iniError";
    $msgHere="";
				# --------------------------------------------------
				# check file existence
				# --------------------------------------------------
    foreach $arg (@desDef){
				# exclude some from check
	next if ($arg=~/^exeEval/);
	next if ($arg=~/^fileOut/);
	next if ($arg=~/para(Acc|Htm|Sec)Cross/);
				# executables
	if   ($arg=~/^exe/) { 
	    $msgHere.="*** ERROR executable ($arg) '".$par{"$arg"}."' missing!\n"
		if ((! -e $par{"$arg"}) && (! -l $par{"$arg"}));
	    $msgHere.="*** ERROR executable ($arg) '".$par{"$arg"}."' not executable!\n".
		      "***       do the following \t 'chmod +x ".$par{"$arg"}."'\n"
	        if (! -x $par{"$arg"});}
				# files
	elsif($arg=~/^file|^header|^abbrev/){
	    print "*** WARNING file ($arg) '",$par{"$arg"},"' missing!\n"
		if ((! -e $par{"$arg"})&&(! -l $par{"$arg"}) && $par{"verbose"});
	    $msgHere.="*** ERROR file ($arg) '".$par{"$arg"}."' missing!\n".
		      "*** \t needed for cross-validation\n"
		if ((! -e $par{"$arg"})&&(! -l $par{"$arg"}) && $par{"optIsCross"});}
				# parameter files
	elsif($arg=~/^para/) {
	    print "*** WARNING parameter file ($arg) '",$par{"$arg"},"' missing!\n"
		if (! -e $par{"$arg"} );
	    $msgHere.="*** ERROR parameter file ($arg) '".$par{"$arg"}."' missing!\n".
		      "*** \t needed for cross-validation\n"
	        if (! -e $par{"$arg"} && ($par{"optPara"} ne "no" || ! $par{"optPara"}));}
    }
				# ------------------------------
				# check names for input list 
    if ($#fileIn>1){
	foreach $kwd (@desFileOut){
	    next if (! defined $par{$kwd} || ! $par{$kwd});
	    if ($par{$kwd} !~ /ID/) {
		$par{$kwd}="ID";}

	    $msgHere.="*** ERROR for input list the output file names have to be given via the\n".
		      "*** \t option 'title=id' (names will add '-id' to the title\n" 
		if ($par{$kwd} !~ /ID/);}}
    return(0,$msgHere) if ($msgHere=~/ERROR/);
    return(1,"ok $sbrName");
}				# end of iniError

#===============================================================================
sub iniWrt {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iniWrt                      write initial settings on screen
#-------------------------------------------------------------------------------
    $sbrName="$scrName:"."iniWrt";
    if ($USERID !~ /^(rost|phd)/){
	print $fhTrace2
	    "--- ","-" x 80, "\n",
	    "--- ","==================================================\n",
	    "--- ","               Welcome to PHD\n",
	    "--- ","==================================================\n",
	    "--- \n";
    }

    print $fhTrace2 "--- The initial settings are:\n";
				# ------------------------------
    foreach $des (sort(@desDef)) {	# parameters
	next if (! defined $par{$des});
	next if ($des =~/^fileOut/); # last
	next if (($des =~ /^head|^abbr/)||($par{$des} =~ /^no|^unk/));
	next if (length($par{$des})<1);
	printf $fhTrace2 "--- %-20s '%-s'\n",$des,$par{$des};}
				# ------------------------------
				# output files
    foreach $des (sort(@desFileOut,@desFileOutList)) {
	next if (! defined $par{$des} || $par{$des} =~ /^no|^unk/ || ! $par{$des});
	printf $fhTrace2 "--- %-20s '%-s'\n",$des,$par{$des};}
    print $fhTrace2 
	"--- \n",
	"--- ","-" x 80, "\n",
	"--- \n";
				# ------------------------------
				# lots of blabla for others
				# ------------------------------
    if ($USERID !~ /^(rost|phd)/) {
	print $fhTrace2 
	    "--- \n",
	    "--- ","-" x 80, "\n",
	    "--- \n";
	&wrtScreenHeader;
	print $fhTrace2 
	    "--- \n",
	    "--- ","-" x 80, "\n",
	    "--- \n";}
    return(1,"ok $sbrName");
}				# end of iniWrt

#===============================================================================
sub abortProg {
    local($errorTxt)=@_;
    $[ =1 ;
#--------------------------------------------------------------------------------
#    abortProg                 soft exit: first deleting intermediate files
#--------------------------------------------------------------------------------
    $errorTxt="" if (!defined $errorTxt);
    &cleanUp() if (! $par{"debug"});
    print "*** WARNING: prediction aborted\n";
    die '*** unwanted exit '.$errorTxt;
}				# end of abortProg

#===============================================================================
sub cleanUp {
    local(@fileLoc)=@_;
    $[ =1 ;
#-------------------------------------------------------------------------------
#   cleanUp                     delete temporary files
#-------------------------------------------------------------------------------
    foreach $kwd (@kwdRm) {
	if (! defined $file{$kwd}){
	    print $fhTrace2 "*** cleanUp temporary file for keyword '$kwd' never defined\n";
	    next;}
	if (-e $file{$kwd}) {
	    print $fhTrace2 "--- cleanUp \t \t '\\rm ",$file{$kwd},"'\n";
	    unlink($file{$kwd});}}
    foreach $file (@fileLoc) {
	next if (! -e $file);
	unlink($file);}
}				# end of cleanUp

#===============================================================================
sub get_in_keyboardLoc {
    local($des,$def,$pre,$Lmirror)=@_;local($txt);
#--------------------------------------------------------------------------------
#   get_in_keyboardLoc          gets info from keyboard
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
}				# end of get_in_keyboardLoc

#===============================================================================
sub sysGetUserLoc {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   sysGetUserLoc               returns $USER (i.e. user name)
#       out:                    USER
#-------------------------------------------------------------------------------
    $sbrName="lib-ut:"."sysGetUserLoc";
    if (defined $ENV{'USER'}){
        return($ENV{'USER'});
    }
    $tmp=`whoami`;
    return($tmp) if (defined $tmp && length($tmp)>0);
    $tmp=`who am i`;            # SUNMP
    return($tmp) if (defined $tmp && length($tmp)>0);
    return(0);
}				# end of sysGetUserLoc

#===============================================================================
sub wrtLoc {
    local($fhLoc)=@_;
    $[ =1 ;
#-------------------------------------------------------------------------------
#   wrtLoc                      write onto screen where we are
#-------------------------------------------------------------------------------
				# for many files to convert: do time estimate
    if ($nfileIn > 10) {
	$estimate=
	    &fctRunTimeLeft($timeBeg,$nfileIn,$it);
	$estimate="?"           if ($it < 5);
	$tmp=  sprintf("%4d (%4.1f%-1s), time left=%-s",
		       $it,(100*$it/$nfileIn),"%",$estimate); }
    else {
	$tmp=$it; }
    $tmpWrt= "--- PHD for $fileHssp (chain=$chainHssp) ";
    $tmpWrt.=$tmp;
    print $fhLoc "$tmpWrt\n";
}				# end of wrtLoc
