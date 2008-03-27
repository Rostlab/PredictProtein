#!/usr/bin/perl -w
##!/bin/env perl
##!/usr/bin/perl
#-------------------------------------------------------------------------------
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$scrName=$0; $scrName=~s/^.*\/|\.pl//g;
$scrGoal=    "runs TOPITS threadhing with different default parameters, and compares results\n";
$scrIn=      "list_of_dssp, or: *.dssp_phd, or: *.hssp_topits";            # 
$scrNarg=    1;                  # minimal number of input arguments
$scrHelpTxt= " \n";
$scrHelpTxt.=" \n";
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# comments
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# 
# 
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#
#------------------------------------------------------------------------------#
#	Copyright				Dec,       	1993	       #
#	Burkhard Rost		rost@EMBL-Heidelberg.DE			       #
#	Wilckensstr. 15		http://www.embl-heidelberg.de/~rost/	       #
#	D-69120 Heidelberg						       #
#				version 1.0   	Feb,    	1997	       #
#				version 1.2   	Oct,    	1998	       #
#------------------------------------------------------------------------------#
$[ =1 ;				# sets array count to start at 1, not at 0

				# ------------------------------
($Lok,$msg)=			# initialise variables
    &ini();			&errScrMsg("after ini",$msg,$scrName) if (! $Lok); 


&iniTopits();			# initialise arguments for TOPITS

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

$nfileIn= $#fileIn; 
$ctfileIn=0;

foreach $fileIn (@fileIn){
    $id=$fileIn;$id=~s/^.*\/|\.dssp.*$//g;
    ++$ctfileIn;
				# ------------------------------
				# estimate time
    $estimate=&fctRunTimeLeft($timeBeg,$nfileIn,$ctfileIn);
    $estimate="?"           if ($ctfileIn < 5);
    printf 
	"--- %-40s %4d (%4.1f%-1s), time left=%-s\n",
	$fileIn,$ctfileIn,(100*$ctfileIn/$nfileIn),"%",$estimate;
    
				# ------------------------------
    if ($fileIn=~/^.*\//){	# make local copy
	$fileTmp=$fileIn;$fileTmp=~s/^.*\///g;$fileTmp=$par{"dirWork"}."$fileTmp";
	($Lok,$txt)=
            &fileCp($fileIn,$fileTmp,$Lverb);
	if (! $Lok){
	    print "*** ERROR $scrName: could not copy $fileIn->$fileTmp\n";
	    next;}
	$fileIn=$fileTmp;
        push(@fileRm,$fileIn);}
				# --------------------------------------------------
                                # run TOPITS
                                # --------------------------------------------------
    if ($par{"doTopits"}){
	printf "--- %-20s %-s\n","topits for",$fileIn if ($Lverb);
                                # debug file for current job
	if (! $Lverb3){ $fileOutScreen=$par{"fileOutScreen"};
                        $fileOutScreen=~s/(\.tmp.*)$/$id$1/;
                        push(@fileRm,$fileOutScreen);}
				# ------------------------------
	foreach $job (@jobs){	# different parameter settings
	    if (! defined $jobs{"$job"}) {
		print "*** argument not defined for job=$job,\n";
                next; }
                                # ------------------------------
				# build up TOPITS input
            $command="";
            $command.=" nice ".$par{"topitsNice"}." "
                if ($par{"topitsNice"} ne "0");	# nice topits.pl ?
		    
				# 'exe file arguments'
            $command.=$par{"exeTopits"}." ".$fileIn." ".$jobs{"$job"};
                                # debug file
            $command.=" ".">> $fileOutScreen" if (! $Lverb3);
		    
				# ==============================
				# do run TOPITS
            &run_program("$command");
				# ==============================
            print "xx after topits \n";
	}
    }
}

#-------------------------------------------------------------------------------
# work done, go home
#-------------------------------------------------------------------------------
				# ------------------------------
				# deleting intermediate files
&cleanUp(@fileRm) if (! $par{"debug"});
    
                                # ------------------------------
                                # final words
if ($Lverb) { 
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
	if    ($arg=~/ARCH=(.*)$/) { $ARCH=$ENV{'ARCH'}=$1; }
	elsif ($arg=~/PWD=(.*)$/)  { $PWD=$ENV{'ARCH'}=$1; } }

    $PWD= $PWD  || $ENV{'PWD'}  || `pwd`; $pwd=$PWD; $pwd.="/";
    $ARCH=$ARCH || $ENV{'ARCH'} || "SGI32";

                                # ------------------------------
                                # warning
    print 
        "-*- WARNING \t no architecture defined\n",
        "-*- WARNING \t say 'setenv ARCH x'\n",
        "-*-         \t with x=SGI5|SGI64|ALPHA|SUNMP|SUN4SOL2\n" if (!defined $ARCH);

				# ------------------------------
    &iniDef();			# set general parameters

				# ------------------------------
    $timeBeg=     time;		# date and time
    $Date=        &sysDate();


				# ------------------------------
				# HELP stuff
    %tmp=&iniHelp();
    ($Lok,$msg)=		# want help?
	&brIniHelpLoop($scrName,
		       %tmp);   return(&errSbrMsg("after lib-br:brIniHelpLoop",$msg,$SBR)) if (! $Lok);
    exit if ($msg =~/^fin/); 

				# ------------------------------
				# read command line input
    @argUnk=			# standard command line handler
	&brIniGetArg;
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
    $par{"verbose"}=1           if ($par{"verb3"});
    $par{"verbose"}=1           if ($par{"verb2"});
	
    $Lverb= $par{"verbose"}     if (defined $par{"verbose"} && $par{"verbose"});
    $Lverb2=$par{"verb2"}       if (defined $par{"verb2"}   && $par{"verb2"});
    $Lverb3=$par{"verb3"}       if (defined $par{"verb3"}   && $par{"verb3"});

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
        print "--- \t open $fhTrace for trace file ",$par{"fileOutTrace"}," \n"  if ($Lverb2);
        &open_file("$fhTrace",">".$par{"fileOutTrace"}) || 
            return(&errSbr("failed to open new file for trace : ".$par{"fileOutTrace"},$SBR));}
    else {
	$fhTrace="STDOUT";}
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
				# output files
    $par{"title"}=              "unk"; # output files will be called 'Pre-title.ext'
    $par{"titleTmp"}=           "TOPITSjury_";                    # title for temporary files


    $par{"fileOutTrace"}=       $par{"titleTmp"}."TRACE"."jobid".".tmp";   # tracing some warnings and errors
    $par{"fileOutScreen"}=      $par{"titleTmp"}."SCREEN-"."jobid".".tmp"; # dumb out from system calls

    $par{"fileHelpMan"}=        "unk"; # file with manual
    $par{"fileHelpOpt"}=        "unk"; # file with options
    $par{"fileHelpHints"}=      "unk"; # file with hints, note: also passed as par{scrHelpHints}
    $par{"fileHelpProblems"}=   "unk"; # file with known problems, also passed as par{scrHelpProblems}
#    $par{""}=                   "";

    $par{"fileOut"}=            "unk";
				# file extensions
    $par{"preOut"}=             "Out-";
    $par{"extOut"}=             ".tmp";
				# file handles
#    $fhout=                     "FHOUT";
    $fhin=                      "FHIN";
    $fhTrace=                   "FHTRACE";
				# --------------------
				# further
    $par{"topitsNhits"}=        100;   # number of selected hits in TOPITS output
    $par{"topitsKeepX"}=        0;     # keep the maxhom.x file?
				# run topits niced (set ="0" to avoid)
    $par{"topitsNice"}=         "0";
    $par{"topitsNice"}=         "-19";

                                # --------------------
                                # job control
    $par{"jobid"}=              "jobid"; # unique job identifier (set to $$ if not defined)
    $par{"debug"}=              0; # if 1 : keep (most) temporary files
    $par{"verbose"}=$Lverb=     1; # blabla on screen
    $par{"verb2"}=  $Lverb2=    0; # more verbose blabla
    $par{"verb2"}=  $Lverb3=    0; # more verbose blabla

    $par{"optNice"}=            "nice -15";

				# --------------------
				# logicals
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
}				# end of iniDef

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
    $tmp{"special"}.=        "list,verb,verb2,";
    $tmp{"special"}.=        ",";
        
#    $tmp{""}=         "<*|=1> ->    ";
    $tmp{"list"}=            "<*|isList=1>     -> input file is list of files";

    $tmp{"verb"}=            "<*|verbose=1>    -> verbose output";
    $tmp{"verb2"}=           "<*|verb2=1>      -> very verbose output";
    $tmp{"verbDbg"}=         "<*|verbDbg=1>    -> detailed debug info (not automatic)";

    $tmp="---                      ";
    $tmp{"zz"}=              "expl             -> action\n";
    $tmp{"zz"}.=        $tmp."    expl continue\n";

    $tmp{"special"}=~s/,*$//g;
#                            "------------------------------------------------------------\n";
    return(%tmp);
}				# end of iniHelp

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
    $argAdd.=" opt_nice=".$par{"topitsNice"} if ($par{"topitsNice"} ne "0");

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
    $sbrName="$scrName:"."cleanUp";

    if ($#fileLoc>0){		# remove intermediate files
	if ($Lverb){@tmp=("STDOUT",@fileLoc);}else{@tmp=(@fileLoc);}
	($Lok,@tmp)=
	    &fileRm(@tmp);}	# external lib-ut.pl
}				# end of cleanUp

#==============================================================================
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

#==============================================================================
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
    foreach $arg (@ARGV){	# search in command line
	if ($arg=~/^dirIn=(.+)$/){$par{"dirIn"}=$1;
				  last;}}
				# search in defaults
    if ((! defined $par{"dirIn"} || ! -d $par{"dirIn"}) && 
 	defined %defaults && %defaults){
	if (defined $defaults{"dirIn"}){
	    $par{"dirIn"}=$defaults{"dirIn"};
	    $par{"dirIn"}=$PWD    
		if (defined $PWD &&
		    ($par{"dirIn"}=~/^(local|unk)$/ || length($par{"dirIn"})==0));}}
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
	if    ($arg=~/^verb\w*3=(\d)/)           {$par{"verb3"}=$Lverb3=$1;}
	elsif ($arg=~/^verb\w*3/)                {$par{"verb3"}=$Lverb3=1;}
	elsif ($arg=~/^verb\w*2=(\d)/)           {$par{"verb2"}=$Lverb2=$1;}
	elsif ($arg=~/^verb\w*2/)                {$par{"verb2"}=$Lverb2=1;}
	elsif ($arg=~/^verbose=(\d)/)            {$par{"verbose"}=$Lverb=$1;}
	elsif ($arg=~/^verbose/)                 {$par{"verbose"}=$Lverb=1;}
	elsif ($arg=~/^not_?([vV]er|[sS]creen)/) {$par{"verbose"}=$Lverb=0; }
	else  {$Lok=0;		# general
               if (-e $arg && ! -d $arg){ # is it file?
                   $Lok=1;push(@fileIn,$arg);}
               if (! $Lok && length($par{"dirIn"})>1 && -e $par{"dirIn"}.$arg){
                   $Lok=1;push(@fileIn,$par{"dirIn"}.$arg);}
				# any of the paras defined ?
               if (! $Lok && $arg=~/=/){
                   foreach $kwd (@tmp){
                       if ($arg=~/^$kwd=(.+)$/){$Lok=1;$par{"$kwd"}=$1;
                                                last;}}}
               push(@argUnk,$arg) if (! $Lok);}}
    return(@argUnk);
}				# end of brIniGetArg

#==============================================================================
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
	foreach $kwd ("sourceFile","scrName","scrIn","scrGoal",
		      "scrNarg","scrAddHelp","special"){
	    print "--- input to $sbrName kwd=$kwd, val=",$tmp{"$kwd"},",\n";}
    }
    @scrTask=
        ("--- Task:  ".$tmp{"scrGoal"},
         "--- ",
         "--- Input: ".$tmp{"scrIn"},
#         "---                 i.e. requires at least ".$tmp{"scrNarg"}.
#	      " command line argument(s)",
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
				# additional general information
				# ------------------------------
    $#scrHelpTxtLoc=0;
    if (defined $tmp{"scrHelpTxt"}){
	@tmp=split(/\n/,$tmp{"scrHelpTxt"});
				# '--- scrHelptTxt'
				# '> program'       i.e. use: '>' to ommitt '--- '
	foreach $txt (@tmp){
	    push(@scrHelpTxtLoc,"--- $txt\n") if ($txt !~ /^[>\%]/);
	    push(@scrHelpTxtLoc,"$txt\n")     if ($txt =~ /^[>\%]/); }}
				# ------------------------------
				# additional special info
				# ------------------------------
    $#scrSpecialLoc=0;
    if (defined $tmp{"special"}) {
	@kwdLoc=split(/,/,$tmp{"special"});
	if ($#kwdLoc>1){
	    foreach $kwd (@kwdLoc){
		$tmp=" "; $tmp=$tmp{"$kwd"} if (defined $tmp{"$kwd"});
		$tmp=~s/\n$//;
		$tmpWrt=sprintf ("---   %-15s %-s\n",$kwd,$tmp); 
		push(@scrSpecialLoc,$tmpWrt); } }}
				# ------------------------------
				# general:
				# ------------------------------
    $fstLineLoc= "-" x 80 . "\n";
    $fstLineLoc.="--- Perl script $scrName.pl (" . $tmp{"sourceFile"} . ")\n";
    $syntaxLoc=  "-" x 80 . "\n";
    $syntaxLoc.= "---    Syntax used to set parameters by command line:\n";
    $syntaxLoc.= "---       'keyword=value'\n";
    $syntaxLoc.= "---    where 'keyword' is one of the following keywords:\n";
	
				# ------------------------------
				# no input
    if ($#ARGV < 1) {		# ------------------------------
	print $fstLineLoc;
	print join("\n",@scrTask,"\n");
	print @scrHelpTxtLoc;
	print join("\n",@scrHelp); print "\n";
	return(1,"fin");}
				# ------------------------------
				# help request
				# ------------------------------
    elsif ($#ARGV < 2 && $ARGV[1] =~ /^(help|man|-m|-h)$/){
	print $fstLineLoc;
	print join("\n",@scrTask,"\n");
	print @scrHelpTxtLoc;
	if ($#scrSpecialLoc > 0) {
	    print "-" x 80,"\n"; 
	    print "---    'special' keywords:\n"; 
	    print @scrSpecialLoc,"\n"; }
        if (defined %par) {
	    @kwdLoc=sort keys (%par);
	    if ($#kwdLoc>1){
		print $syntaxLoc;
		$ct=0;print "OPT \t ";
		foreach $kwd(@kwdLoc){
		    ++$ct;
		    printf "%-20s ",$kwd;
		    if ($ct==4){
			$ct=0;print "\nOPT \t ";}}
		print "\n";}
            print 
                "--- \n",
                "---    you may get further explanations on a particular keyword\n",
                "---    by typing:\n",
                $tmp{"scrName"}.".pl help keyword\n",
                "---    this could explain the key.  Type 'how' for info on ".
		    "'how,howie,show'.\n",
		    "--- \n";}
        else { 
	    print "--- no other options enabled by \%par\n";}
	return(1,"fin loop?");}
				# ------------------------------
				# wants manual
				# ------------------------------
    elsif ($#ARGV<2  && $ARGV[1] eq "manual"){
	print $fstLineLoc;
	if (defined $par{"fileHelpMan"} &&  -e $par{"fileHelpMan"}){
	    open("FHIN",$par{"fileHelpOpt"}) || 
		warn "*** $sbrName: could NOT open file".$par{"fileHelpOpt"};
	    while(<FHIN>){
		print $_;}close(FHIN);}
	else {
	    print "no manual in \%par{'fileHelpMan'}!!\n";}
	return(1,"fin");}
				# ------------------------------
				# wants hints
				# ------------------------------
    elsif ($#ARGV==1  && $ARGV[1] eq "hints"){
	print $fstLineLoc;
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
	print $fstLineLoc;
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
	print $fstLineLoc;
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
    elsif ($#ARGV>=2 && $ARGV[1] eq "help" ||
	   $#ARGV==1 && $ARGV[1] eq "special"){
	print $fstLineLoc;
	$kwdHelp=$ARGV[2]         if ($#ARGV > 1); 
	$kwdHelp=$ARGV[1]         if ($#ARGV== 1); 
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
	    print $syntaxLoc;
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
		    else {
			push(@expLoc," ");}}}
	    @kwdLoc=@tmp;}
				# (4) else: read itself
        elsif ($kwdHelp ne "special"){
            ($Lok,$msg,%def)=
		&brIniHelpRdItself($tmp{"sourceFile"});
            die '.....   verrry sorry the option blew up ... ' if (! $Lok);
	    $def{"kwd"}="" if (! $Lok); # hack: short cut error
            @kwdLoc=split(/,/,$def{"kwd"});$#tmp=0;
            foreach $kwd (@kwdLoc){
                next if ($kwd !~/$kwdHelp/i && $kwdHelp !~ /$kwd/ );
		push(@tmp,$kwd); 
		if (defined $def{"$kwd"}){
		    $def{"$kwd"}=~s/\n[\t\s]*/\n---                        /g;
		    push(@expLoc,$def{"$kwd"});}
		else {push(@expLoc," ");}}
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
	if (defined $tmpSpecial || 
	    ($kwdHelp eq "special" && defined $tmp{"special"})){
            print  "---    Special help for '$kwdHelp':\n";
	    if ($kwdHelp eq "special"){
		print @scrSpecialLoc,"\n";}
	    else {
		foreach $scrSpecialLoc (@scrSpecialLoc) {
		    $scrSpecialLoc=~s/\n$//;
		    next if ($scrSpecialLoc !~ /$kwdHelp/);
		    print "$scrSpecialLoc";}
		print "\n";}
	    $Lerr=0;
	    return(1,"fin") if ($kwdHelp eq "special");}
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

#==============================================================================
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

#==============================================================================
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

#==============================================================================
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

    if (defined $Date) {
	$dateTmp=$Date; }
    else {
	$tmp=`date`; $tmp=~s/\n//g if (defined $tmp);
	$dateTmp=$tmp || "before year 2000"; }

    print $fhTraceLocSbr "--- ","-" x 80, "\n";
    print $fhTraceLocSbr "--- Initial settings for $scrName ($0) on $dateTmp:\n";
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
	print  $fhTraceLocSbr "--- \n";
	printf $fhTraceLocSbr "--- %-20s '%-s'\n","Input file:",$tmp;}
    print  $fhTraceLocSbr "--- \n";
    printf $fhTraceLocSbr "--- %-20s %-s\n","excluded from write:",$exclLoc 
	if (defined $exclLoc);
    print  $fhTraceLocSbr "--- \n","--- ","-" x 80, "\n","--- \n";
	
    return(1,"ok $sbrName");
}				# end of brIniWrt

#==============================================================================
sub errSbr    {local($txtInLoc,$sbrNameLocy) = @_ ;
#-------------------------------------------------------------------------------
#   errSbr                      simply writes '*** ERROR $sbrName: $txtInLoc'
#-------------------------------------------------------------------------------
	       $sbrNameLocy=$sbrName if (! defined $sbrNameLocy);
	       $txtInLoc.="\n";
	       $txtInLoc=~s/\n\n+/\n/g;
	       return(0,"*** ERROR $sbrNameLocy: $txtInLoc");
}				# end of errSbr

#==============================================================================
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
sub errScrMsg {local($txtInLoc,$msgInLoc,$scrNameLocy) = @_ ;
#-------------------------------------------------------------------------------
#   errScrMsg                   writes message and EXIT!!
#-------------------------------------------------------------------------------
	       $scrNameLocy=$scrName if (! defined $scrNameLocy);
	       $txtInLoc.="\n";
	       $txtInLoc=~s/\n\n+/\n/g;
	       if (defined $msgInLoc) {
		   $msgInLoc.="\n";
		   $msgInLoc=~s/\n\n+/\n/g;}
	       else {
		   $msgInLoc="";}
	       print "*** ERROR $scrNameLocy: $txtInLoc".$msgInLoc;
	       exit; 
}				# end of errScrMsg

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
	$timeTot=int(100*($timeRun/$percLoc));
	$timeLeft=$timeTot-$timeRun;
	$tmp=
	    &fctSeconds2time($timeLeft); 
	@tmp=split(/:/,$tmp); foreach $tmp (@tmp){$tmp=~s/^0//g;}
	$estimateLoc= "";
	$estimateLoc.=    $tmp[1]."h " if ($tmp[1] > 9);
	$estimateLoc.=" ".$tmp[1]."h " if (9 >= $tmp[1] && $tmp[1] > 0);
	$estimateLoc.=    $tmp[2]."m " if ($tmp[2] > 9);
	$estimateLoc.=" ".$tmp[2]."m " if (9 >= $tmp[2] && $tmp[2] > 0);
	$estimateLoc.=" "." ".    "  " if ($tmp[2] <= 0 && $tmp[1] > 0);
	$estimateLoc.=    $tmp[3]."s " if ($tmp[3] > 9);
	$estimateLoc.=" ".$tmp[3]."s " if (9 >= $tmp[3] && $tmp[3] > 0);
	$estimateLoc.=" "." ".    "  " if ($tmp[3] <= 0 && ($tmp[1] > 0 || $tmp[2] > 0));
	$estimateLoc= "done"        if (length($estimateLoc) < 1);}
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

#==============================================================================
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

#==============================================================================
sub fileRm  { local($fhoutLoc,@fileLoc)=@_; local($tmp,@tmp,$Lok,$fileLoc);
	      if (-e $fhoutLoc){push(@fileLoc,$fhoutLoc);$fhoutLoc=0;}
	      $Lok=1;$#tmp=0;
	      foreach $fileLoc(@fileLoc){
		  if (-e $fileLoc){
		      $tmp="'\\rm $fileLoc'"; push(@tmp,$tmp);
		      printf $fhoutLoc "--- %-20s %-s\n","unlink ","$tmp" if ($fhoutLoc);
                      unlink($fileLoc);}
		  if (-e $fileLoc){
		      $tmp="*** ERROR 'lib-ut:fileRm' '$fileLoc' not deleted";
		      if ($fhoutLoc){print $fhoutLoc "$tmp\n";}
		      $Lok=0; push(@tmp,$tmp);}}
	      return($Lok,@tmp);} # end of fileRm


#==============================================================================
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

#==============================================================================
sub sysDate {
#    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   sysDate                     returns $Date
#       out:                    $Date (May 30, 1998 59:39:03)
#-------------------------------------------------------------------------------
    @tmp=("/home/rost/perl/ctime.pl","/home/rost/pub/perl/ctime.pl");
				# ------------------------------
				# get function
    if (defined &localtime) {
	foreach $tmp(@tmp){
	    if (-e $tmp){$Lok=require("$tmp");
			 last;}}
	if (defined &ctime && &ctime && defined &localtime && &localtime){
#       	$date is e.g.:		Oct:14:13:06:47:1993
#       	@Date is e.g.:		Oct1413:06:471993
#        	&ctime(time) is e.g.:	Thu Oct 14 13:06:47 1993
#	    print "xx enter\n";
	    @Date = split(' ',&ctime(time)) ; shift (@Date) ; 
	    $Date="$Date[2] $Date[3], $Date[$#Date]  $Date[4]";
	    return($Date);}
    }
				# ------------------------------
				# or get system time
    $localtime=`date`;
    @Date=split(/\s+/,$localtime);
    $Date="$Date[2] $Date[3], $Date[$#Date] $Date[4]";
    return($Date);
}				# end of sysDate

