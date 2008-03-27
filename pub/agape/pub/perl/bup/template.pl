#!/usr/sbin/perl -w
##!/bin/env perl
##!/usr/bin/perl
##!/usr/pub/bin/perl -w
#-------------------------------------------------------------------------------
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$scrName=$0; $scrName=~s/^.*\/|\.pl//g;
$scrGoal=    "\n".
    "      \t ";
$scrIn=      "input";            # 
$scrNarg=    1;                  # minimal number of input arguments
$scrHelpTxt= " \n";
$scrHelpTxt.=" \n";
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
#	Copyright				        	1998	       #
#	Burkhard Rost		rost@EMBL-Heidelberg.DE			       #
#	Wilckensstr. 15		http://www.embl-heidelberg.de/~rost/	       #
#	D-69120 Heidelberg						       #
#				version 0.1   	May,    	1998	       #
#------------------------------------------------------------------------------#
$[ =1 ;				# sets array count to start at 1, not at 0
				# ------------------------------
				# initialise variables
#@ARGV=split(/\s+/,&get_in_keyboard("command line"));	# x.x mac specific

				# ------------------------------
($Lok,$msg)=			# initialise variables
    &ini;			# 
if (! $Lok) { print "*** ERROR $scrName after ini\n",$msg,"\n";
	      die '*** during initialising $scrName   ';}

die 'ok after ini';
#-------------------------------------------------------------------------------
# do the job (here we go)
#-------------------------------------------------------------------------------

$Lok=&open_file("$fhin","$fileIn");
if ($Lok){
    while (<$fhin>) {
	$_=~s/\n//g;
	next if (length($_)==0);
    }
    close($fhin);}
else{}


				# ------------------------------
				# write output
&open_file("$fhout",">$fileOut"); 
close($fhout);


#-------------------------------------------------------------------------------
# work done, go home
#-------------------------------------------------------------------------------
                                # ------------------------------
                                # deleting intermediate files
&cleanUp() if (! $par{"debug"}); 
                                # ------------------------------
                                # final words
if ($Lverb) { print "--- $scrName ended fine .. -:\)\n";
                                # ------------------------------
              $timeEnd=time;    # runtime , run time
              $timeRun=$timeEnd-$timeBeg;
              print 
                  "--- date     \t \t $Date \n",
                  "--- run time \t \t ",&fctSeconds2time($timeRun)," (hour:min:sec)\n";
                                # ------------------------------
              print "--- \n";   # output files
              print "--- output file";print "s" if ($#fileOut>1); print ":\n";
	      foreach $_(@fileOut){
		  printf "--- %-20s %-s\n"," ",$_ if (-e $_);}}
exit;

#===============================================================================
sub ini {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   initialises variables/arguments
#-------------------------------------------------------------------------------
    $sbrName="$scrName".":ini";
    $par{"dirPerl"}=            "/home/rost/perl/"; # directory for perl scripts needed
    $dir=0;			# ------------------------------
    foreach $arg(@ARGV){	# highest priority arguments
	next if ($arg !~/=/);
	if    ($arg=~/dirLib=(.*)$/)   {$dir=$1;}
	elsif ($arg=~/ARCH=(.*)$/)     {$ARCH=$1;}
	elsif ($arg=~/PWD=(.*)$/)      {$PWD=$1;}
	elsif ($arg=~/^packName=(.*)/) { $par{"packName"}=$1; 
					 shift @ARGV if ($ARGV[1] eq $arg); }  }

    $ARCH=$ENV{'ARCH'}         if (! defined $ARCH && defined $ENV{'ARCH'});
    $PWD= $ENV{'PWD'}          if (! defined $PWD  && defined $ENV{'PWD'}); 
    $PWD=~s/\/$//              if ($PWD=~/\/$/);
    $pwd= $PWD                 if (defined $PWD);
    $pwd.="/"                  if (defined $pwd && $pwd !~ /\/$/);
    $dir=$dir || "/home/rost/perl/" || $ENV{'PERLLIB'} || 
	$par{"dirPerlLib"} || $par{"dirPerlLib"} || $par{"dirPerl"};
    $dir.="/"                  if (-d $dir && $dir !~/\/$/);
    $dir= ""                   if (! defined $dir || ! -d $dir);
				# ------------------------------
				# include perl libraries
    foreach $lib("lib-ut.pl","lib-br.pl"){
	require $dir.$lib ||
	    die("*** $scrName: failed to require perl library '$lib' (dir=$dir)\n");}

				# ------------------------------
    $timeBeg=     time;		# date and time
    $Date=        &sysDate;
				# ------------------------------
				# first settings for parameters 
    &iniDef;			# NOTE: may be overwritten by DEFAULT file!!!!

				# ------------------------------
				# HELP stuff

				# standard help
    $tmp=0;
    $tmp=$par{"packName"}       if (defined $par{"packName"});
    $tmp=$0                     if (! defined $tmp || ! $tmp); 
    %tmp=('sourceFile', $tmp, 'scrName',$scrName, 'scrIn',$scrIn, 'scrGoal', $scrGoal, 
	  'scrNarg',$scrNarg, 'scrHelpTxt', $scrHelpTxt);
				# special help
    $tmp{"scrAddHelp"}=      "";
    $tmp{"special"}=         "expand".","."compress".","."list".",";
    $tmp{"special"}.=        "help saf-syn".",";
        
    $tmp{"expand"}=          "shortcut for doExpand=1,   i.e. do expand HSSP deletions (for conversion to MSF|SAF)";
    $tmp{"compress"}=        "shortcut for doCompress=1, i.e. do delete insersions in MASTER (for conversion to HSSP)";
    $tmp{"list"}=            "shortcut for isList=1,     i.e. input file is list of files";

    undef %tmp2;
    foreach $form (@okFormIn,@okFormOut){
        next if (defined $tmp2{$form});$tmp2{$form}=1;$formTmp=$form;$formTmp=~tr/[a-z]/[A-Z]/;
        $tmp{"special"}.=    "help $form".",";
        $tmp{"scrAddHelp"}.=
            "help ".$form." " x (9-length($form)).": ".$formTmp." " x (10 -length($form))."format specific info\n";}
    $tmp{"special"}=~s/,*$//g;
    $tmp{"scrAddHelp"}.=    "help saf-syn  : specification of SAF format\n";
    $tmp{"scrAddHelp"}= "help zzz      : all info on zzz format\n";
    $tmp{"scrAddHelp"}.="help zzz2     : all info on zzz2 format\n";
    foreach $special ("zz3"){
        $tmp{"special"}.=    "help $special".",";
        $tmp{"scrAddHelp"}.=
            "help ".$special." " x (9-length($special)).": ".$special." " x (10 -length($special))."specific info\n";}
    $tmp{"special"}=~s/,*$//g;
    $tmp{"help hssp"}=       "DES: HSSP = Homology derived Secondary Structure of Proteins format (ali, IN | OUT)\n";
#                            "------------------------------------------------------------\n";

    ($Lok,$msg)=		# want help?
	&brIniHelp(%tmp);       return(&errSbrMsg("after lib:brIniHelp".$msg)) if (! $Lok);
    die '-:)  satisfied, or want more info?     ' if ($msg eq "fin");
    
				# ------------------------------
    undef %defaults;		# get stuff from default file
    if (! defined $par{"fileDefaults"} || ! -e $par{"fileDefaults"}) { # search default file
	$par{"fileDefaults"}=
	    &brIniRdDefWhere;}
    if (! defined $par{"fileDefaults"} || ! -e $par{"fileDefaults"}) {
	print "*** STRONG WARNING $sbrName: no defaults file found\n" x 3;}
    else {			# seems fine, thus read
	($Lok,$msg,%defaults)=
	    &brIniRdDef($par{"fileDefaults"}); 
	return(&errSbrMsg("failed reading default file ".$par{"fileDefaults"}..$msg)) if (! $Lok);
				# warning
        print 
	    "-*- WARN $sbrName: content of '",$par{"fileDefaults"},
	    "' may overwrite hard coded parameters\n" x 10 
		if (defined %defaults && %defaults);}

				# ------------------------------
				# read command line input
    @argUnk=			# standard command line handler
	&brIniGetArg;
    foreach $arg (@argUnk){     # interpret specific command line arguments
        if    ($arg=~/^list$/i)               { $par{"isList"}=1;}
	elsif ($arg=~/^nice-(\d+)$/)          { $par{"optNice"}="nice -".$1;}
	elsif ($arg eq "nonice")              { $par{"optNice"}=" ";}
	elsif ($arg eq "debug")               { $par{"debug"}=1;}
	else  {
	    return(0,"*** ERROR $sbrName: kwd '$arg' not understood\n");}}
    print "-*- WARNING iniGetArg: command line arguments overwrite '".$par{"fileDefaults"}."\n" 
	if ($par{"verbose"} && defined %defaults && %defaults);
        
                                # --------------------------------------------------
                                # digest input file formats
                                # --------------------------------------------------
    return(0,"*** ERROR $sbrName: no input file given!!\n") if ($#fileIn==0);

    if (defined $par{"isList"} && $par{"isList"} eq "1"){ # input is file list
        &open_file("$fhin","$fileIn[1]") ||
            return(&errSbr("failed to open fileIn=$fileIn\n"));
        $#fileIn=0 if ($#fileIn==1);
        while (<$fhin>) {$_=~s/\s|\n//g;
                         push(@fileIn,$_) if (-e $_);}close($fhin);}

				# ------------------------------
				# final settings
    $Lok=			# standard settings
	&brIniSet;              return(&errSbr("after lib:brIniSet\n")) if (! $Lok);
    return(0,"*** ERROR $sbrName: no input file given!!\n") if ($#fileIn==0);
    $#fileOut=0;                # reset output files
    if (! defined $fileOut || ! $fileOut || length($fileOut)<1){
        foreach $it (1..$#fileIn){
            $tmp=$fileIn[$it]; $tmp=~s/^.*\///g;$tmp=~s/$par{"extHssp"}//g;
            $fileOut=$par{"dirOut"}.$tmp.$par{"extOut"};
            push(@fileOut,$fileOut);}}
    else{
	push(@fileOut,$fileOut);}

				# correct settings for executables: add directories
    if (0){
	foreach $kwd (keys %par){
	    next if ($kwd !~/^exe/);
	    next if (-e $par{"$kwd"} || -l $par{"$kwd"});
	}
    }


				# ------------------------------
				# check errors
    $exclude="exe,fileDefaults"; # to exclude from error check
    ($Lok,$msg)=
        &brIniErr($exclude);    return(&errSbrMsg("after lib:brIniErr\n".$msg)) if (! $Lok);  
				# ------------------------------
				# write settings
    if ($par{"verbose"}){
	($Lok,$msg)=
	    &brIniWrt;		return(&errSbrMsg("after lib:brIniWrt\n".$msg)) if (! $Lok); }

				# ------------------------------
                                # trace file
    if (defined $par{"fileOutTrace"} && $par{"fileOutTrace"} ne "unk" && 
	length($par{"fileOutTrace"})>0 &&
	! $par{"debug"}){
        print "--- \t open $fhTrace for trace file ",$par{"fileOutTrace"}," \n" if ($Lverb2);
        &open_file("$fhTrace",">".$par{"fileOutTrace"}) || 
            return(&errSbr("failed to open new file for trace : ".$par{"fileOutTrace"}));}
    else { $fhTrace="STDOUT";
	   $par{"fileOutScreen"}=0;}

                                # ------------------------------
    undef %tmp;			# clean memory

    return(1,"ok $sbrName");
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
#    $par{"fileDefaults"}=       "/home/rost/nn/src/nn.defaults";
#    $par{"fileDefaults"}=       ""; # file with defaults
				# --------------------
				# directories
    $par{"dirHome"}=            "/home/rost/";
    $par{"dirPerl"}=            $par{"dirHome"}. "perl/" # perl libraries
        if (! defined $par{"dirPerl"});
    $par{"dirPerlScr"}=         $par{"dirPerl"}. "scr/"; # perl scripts needed
    $par{"dirBin"}=             "/home/rost/pub/phd/bin/"; # FORTRAN binaries of programs needed

    $par{"dirOut"}=            ""; # directory for output files
    $par{"dirWork"}=           ""; # working directory
#    $par{""}=                   "";
                                # further on work
				# --------------------
				# files
    $par{"title"}=              "unk";                           # output files may be called 'Pre-title.ext'
    $par{"titleTmp"}=           "TMP-BLAST-";                    # title for temporary files

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
				# file handles
    $fhout=                     "FHOUT";
    $fhin=                      "FHIN";
    $fhTrace=                   "FHTRACE";
                                # --------------------
                                # job control
    $par{"jobid"}=              "jobid"; # unique job identifier (set to $$ if not defined)
    $par{"debug"}=              0; # if 1 : keep (most) temporary files
    $par{"verbose"}=$Lverb=     1; # blabla on screen
    $par{"verb2"}=$Lverb2=      0; # more verbose blabla
    $par{"verb3"}=$Lverb3=      0; # more verbose blabla

    $par{"optNice"}=            "nice -15";
#    $par{""}=                   "";
				# --------------------
				# parameters

				# --------------------
				# executables
    $par{"exe"}=                "";
#    $par{""}=                   "";
}				# end of iniDef

#===============================================================================
sub cleanUp {
    local($sbrName,$fhinLoc,@tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#    cleanUp                    deletes intermediate files
#-------------------------------------------------------------------------------
    if ($scrName){$tmp="$scrName".":";}else{$tmp="";} $sbrName="$tmp"."cleanUp";
    if ($#kwdRm>0){		# remove intermediate files
	foreach $kwd (@kwdRm){
	    next if (! defined $file{"$kwd"} || ! -e $file{"$kwd"});
	    print "--- $sbrName unlink '",$file{"$kwd"},"'\n" if ($Lverb2);
	    unlink($file{"$kwd"});}}
    foreach $kwd ("fileOutTrace","fileOutScreen"){
        next if (! defined $par{"$kwd"} || ! -e $par{"$kwd"});
        print "--- $sbrName unlink '",$par{"$kwd"},"'\n" if ($Lverb2);
        unlink($par{"$kwd"});}
}				# end of cleanUp

#===============================================================================
sub subx {
#    local($fileInLoc,$fhErrSbr) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   subx                       
#                               c
#       in:                     
#         $fhoutLoc             file handle print output
#         A                     A
#       out:                    
#         A                     A
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."subx";$fhinLoc="FHIN_"."subx";
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc!")          if (! defined $fileInLoc);

    return(0,"*** $sbrName: miss in file '$fileInLoc'!")  if (! -e $fileInLoc);

    &open_file("$fhinLoc","$fileInLoc") ||
	return(0,"*** ERROR $sbrName: fileIn=$fileInLoc, not opened\n");

    while (<$fhinLoc>) {
	$_=~s/\n//g;
	next if (length($_)==0);
    } close($fhinLoc);
    return(1,"ok $sbrName");
}				# end of subx

