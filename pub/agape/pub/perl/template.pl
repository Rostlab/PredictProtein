#!/usr/bin/perl
##!/usr/sbin/perl -w
##!/bin/env perl
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
#	Copyright				        	2000	       #
#	Burkhard Rost		rost@columbia.edu			       #
#	CUBIC (Columbia Univ)	http://www.columbia.edu/~rost/   	       #
#       Dept Biochemistry & Molecular Biophysics			       #
#       630 West, 168 Street						       #
#	New York, NY 10032	http://cubic.bioc.columbia.edu/                #
#				version 0.1   	Feb,    	2000	       #
#------------------------------------------------------------------------------#
$[ =1 ;				# sets array count to start at 1, not at 0
				# ------------------------------
				# initialise variables
#@ARGV=split(/\s+/,&get_in_keyboard("command line"));	# x.x mac specific

				# ------------------------------
($Lok,$msg)=			# initialise variables
    &ini();			&errScrMsg("after ini",$msg,$scrName) if (! $Lok); 

#-------------------------------------------------------------------------------
# do the job (here we go)
#-------------------------------------------------------------------------------
				# ------------------------------
				# setting 0
				# ------------------------------

				# ------------------------------
				# (1) process input files
				# ------------------------------
$nfileIn= $#fileIn; 
$ctfileIn=0;

while (@fileIn) {
    $fileIn=shift @fileIn; ++$ctfileIn;
				# ------------------------------
				# estimate time
    $estimate=&fctRunTimeLeft($timeBeg,$nfileIn,$ctfileIn);
    $estimate="?"           if ($ctfileIn < 5);
    printf 
	"--- %-40s %4d (%4.1f%-1s), time left=%-s\n",
	$fileIn,$ctfileIn,(100*$ctfileIn/$nfileIn),"%",$estimate;
}

	

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
if ($par{"verbose"}) { 
    print "--- $scrName ended fine .. -:\)\n";
    $timeEnd=time;		# runtime , run time
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
    $SBR="$scrName:"."ini";     
				# ------------------------------
    foreach $arg(@ARGV){	# highest priority ARCH
	if ($arg=~/ARCH=(.*)$/){
	    $ARCH=$ENV{'ARCH'}=$1; 
	    last;}}
    $ARCH=$ARCH || $ENV{'ARCH'} || "SGI32";
				# ------------------------------
    &iniDef();			# set general parameters

				# ------------------------------
    &iniLib();			# require perl libraries

				# ------------------------------
    $timeBeg=     time;		# date and time
    ($Date,$date)=&sysDate();


				# ------------------------------
				# HELP stuff
    %tmp=&iniHelp();
    ($Lok,$msg)=		# want help?
	&brIniHelpLoop($scrName,
		       %tmp);   return(&errSbrMsg("after lib-br:brIniHelpLoop",$msg,$SBR)) if (! $Lok);
    exit if ($msg =~/^fin/); 


				# ------------------------------
    undef %defaults;		# get stuff from default file
    if (! defined $par{"fileDefaults"} || ! -e $par{"fileDefaults"}) { # search default file
	$par{"fileDefaults"}=
	    &brIniRdDefWhere;}
    if (! defined $par{"fileDefaults"} || ! -e $par{"fileDefaults"}) {
	print "*** STRONG WARNING $SBR: no defaults file found\n" x 3;}
    else {			# seems fine, thus read
	($Lok,$msg,%defaults)=
	    &brIniRdDef($par{"fileDefaults"}); 
	return(&errSbrMsg("failed reading default file ".
			  $par{"fileDefaults"}.$msg)) if (! $Lok);
				# .......
				# warning
				# .......
        print 
            "\n","\n","\n","-*- WARN $SBR: content of '".$par{"fileDefaults"}.
                "' may overwrite hard coded parameters\n","\n","\n","\n" 
                    if (defined %defaults && %defaults);}

				# ------------------------------
				# read command line input
    @argUnk=			# standard command line handler
	&brIniGetArg();
    foreach $arg (@argUnk){     # interpret specific command line arguments
	next if ($arg=~/^(dirLib|ARCH|PWD|packName)=/);
        if    ($arg=~/^list$/i)               { $par{"isList"}=1;}
	elsif ($arg=~/^nice-(\d+)$/)          { $par{"optNice"}="nice -".$1;}
	elsif ($arg eq "nonice")              { $par{"optNice"}=" ";}
	elsif ($arg =~ /^de?bu?g$/)           { $par{"debug"}=1;}
	else  {
	    return(0,"*** ERROR $SBR: kwd '$arg' not understood\n");}}
    print "-*- WARNING iniGetArg: command line arguments overwrite '".$par{"fileDefaults"}."\n" 
	if ($par{"verbose"} && defined %defaults && %defaults);
        
				# ------------------------------
				# hierarchy of blabla
    $par{"verb3"}=1             if ($par{"debug"});
    $par{"verb2"}=1             if ($par{"verb3"});
    $par{"verbose"}=1           if ($par{"verb2"});
	
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

    if (defined $par{"isList"} && $par{"isList"} eq "1"){ # input is file list
        &open_file("$fhin","$fileIn[1]") ||
            return(&errSbr("failed to open fileIn=$fileIn\n"));
        $#fileIn=0 if ($#fileIn==1);
        while (<$fhin>) {$_=~s/\s|\n//g;
                         push(@fileIn,$_) if (-e $_);}close($fhin);}

				# ------------------------------
				# final settings
    $Lok=			# standard settings
	&brIniSet();            return(&errSbr("after lib:brIniSet\n")) if (! $Lok);
    return(0,"*** ERROR $SBR: no input file given!!\n") if ($#fileIn==0);
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
        &brIniErr($exclude);    return(&errSbrMsg("after lib:brIniErr\n",$msg)) if (! $Lok);  


                                # --------------------------------------------------
                                # trace file
                                # --------------------------------------------------
    if (defined $par{"fileOutTrace"} && $par{"fileOutTrace"} ne "unk" && 
        length($par{"fileOutTrace"}) > 0) {
        print "--- \t open $fhTrace for trace file ",$par{"fileOutTrace"}," \n"  if ($par{"verb2"});
        &open_file("$fhTrace",">".$par{"fileOutTrace"}) || 
            return(&errSbr("failed to open new file for trace : ".$par{"fileOutTrace"},$SBR));}
    else {
	$fhTrace="STDOUT";}
    $#kwdRm=0;
				# ------------------------------
				# write settings
				# ------------------------------
    $exclude="kwd,dir*,ext*";	# keyword not to write
    $fhloc="STDOUT";
    $fhloc=$fhTrace             if (! $par{"debug"});
    ($Lok,$msg)=
	&brIniWrt($exclude,$fhloc);
    return(&errSbrMsg("after lib-ut:brIniWrt",$msg,$SBR))  if (! $Lok); 

                                # ------------------------------
    undef %tmp;			# clean memory

    return(1,"ok $SBR");
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
    $par{"verbose"}=            1; # blabla on screen
    $par{"verb2"}=              0; # more verbose blabla
    $par{"verb3"}=              0; # more verbose blabla

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
sub iniLib {
#    local(%parLoc)=@_;
    my($SBR);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iniLib                       
#-------------------------------------------------------------------------------
    $SBR="$scrName:"."iniLib";
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

}				# end of iniLib

#===============================================================================
sub iniHelp {
    my($SBR);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iniHelpNet                  specific help settings
#-------------------------------------------------------------------------------
    $SBR="$scrName:"."iniHelp";
				# standard help
    $tmp=0;
    $tmp=$par{"packName"}       if (defined $par{"packName"});
    $tmp=$0                     if (! defined $tmp || ! $tmp); 
    %tmp=('sourceFile', $tmp, 'scrName',$scrName, 'scrIn',$scrIn, 'scrGoal', $scrGoal, 
	  'scrNarg',$scrNarg, 'scrHelpTxt', $scrHelpTxt);

    $tmp{"s_k_i_p"}=         "problems,manual,hints";

				# special help
    $tmp{"scrAddHelp"}=      "";

    $tmp{"special"}=         "";
    $tmp{"special"}.=        "list,verb,verb2,verbDbg,";
    $tmp{"special"}.=        ",";
        
#    $tmp{""}=         "<*|=1> ->    ";
    $tmp{"list"}=            "<*|isList=1>     -> input file is list of files";

    $tmp{"verbose"}=         "<*|verbose=1>    -> verbose output";
    $tmp{"verb2"}=           "<*|verb2=1>      -> very verbose output";
    $tmp{"verbDbg"}=         "<*|verbDbg=1>    -> detailed debug info (not automatic)";

    $tmp="---                      ";
    $tmp{"zz"}=              "expl             -> action\n";
    $tmp{"zz"}.=        $tmp."    expl continue\n";


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
    return(%tmp);
}				# end of iniHelp

#===============================================================================
sub cleanUp {
    local($SBR,$fhinLoc,@tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#    cleanUp                    deletes intermediate files
#-------------------------------------------------------------------------------
    if ($scrName){$tmp="$scrName".":";}else{$tmp="";} $SBR="$tmp"."cleanUp";
    if ($#kwdRm>0){		# remove intermediate files
	foreach $kwd (@kwdRm){
	    next if (! defined $file{"$kwd"} || ! -e $file{"$kwd"});
	    print "--- $SBR unlink '",$file{"$kwd"},"'\n" if ($par{"verb2"});
	    unlink($file{"$kwd"});}}
    foreach $kwd ("fileOutTrace","fileOutScreen"){
        next if (! defined $par{"$kwd"} || ! -e $par{"$kwd"});
        print "--- $SBR unlink '",$par{"$kwd"},"'\n" if ($par{"verb2"});
        unlink($par{"$kwd"});}
}				# end of cleanUp

#===============================================================================
sub subx {
#    local($fileInLoc,$fhErrSbr) = @_ ;
    local($SBR,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   subx                       
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $SBR="$tmp"."subx";
    $fhinLoc="FHIN_"."subx";$fhoutLoc="FHIN_"."subx";
				# check arguments
    return(&errSbr("not def fileInLoc!",$SBR))          if (! defined $fileInLoc);
#    return(&errSbr("not def !"))          if (! defined $);

    return(&errSbr("miss in file '$fileInLoc'!",$SBR)))  if (! -e $fileInLoc);
				# open file
    &open_file("$fhinLoc","$fileInLoc") || return(&errSbr("fileInLoc=$fileInLoc, not opened",$SBR)));
    &open_file("$fhoutLoc",">$fileOutLoc") || return(&errSbr("fileOutLoc=$fileOutLoc, not created",$SBR)));
				# ------------------------------
    while (<$fhinLoc>) {	# read file
	$_=~s/\n//g;
	next if (length($_)==0);
    } close($fhinLoc);
    return(1,"ok $SBR");
}				# end of subx

