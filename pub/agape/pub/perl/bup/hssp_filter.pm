#------------------------------------------------------------------------------#
#	Copyright				        	1998	       #
#	Burkhard Rost		rost@EMBL-Heidelberg.DE			       #
#	Wilckensstr. 15		http://www.embl-heidelberg.de/~rost/	       #
#	D-69120 Heidelberg						       #
#				version 0.1   	May,    	1998	       #
#------------------------------------------------------------------------------#

package hssp_filter;

INIT: {
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    $scrName=$0; $scrName=~s/^.*\/|\.pl//g;
    $scrGoal=    "filters HSSP files\n";
    $scrIn=      "files (or list thereof, note: for lists give kwd 'list'";
    $scrNarg=    1;                  # minimal number of input arguments
    $scrHelpTxt= "You can specify the filtering in various ways:\n";
    $scrHelpTxt.="   - exclude by position (e.g. excl=1-5,7,9-11,30-*)\n";
    $scrHelpTxt.="   - include by position (e.g. incl=1-5,7,9-11,30-*)\n";
    $scrHelpTxt.="   - include by sequence identity|similarity (see help 'sim|ide|thresh|mode' \n";
    $scrHelpTxt.="   - exclude mutually too similar pairs (too redundant alis, red=80, see help red)\n";
    $scrHelpTxt.=" \n";
    $scrHelpTxt.=" \n";
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
}

#===============================================================================
sub hssp_filter {
#-------------------------------------------------------------------------------
#   hssp_filter                 package version of script
#-------------------------------------------------------------------------------
    $[ =1 ;			# sets array count to start at 1, not at 0

    @ARGV=@_;			# pass from calling

				# ------------------------------
				# initialise variables
#    @ARGV=split(/\s+/,&get_in_keyboard("command line"));	# x.x mac specific
    
    ($Lok,$msg)=  &ini;		# initialise variables
    if (! $Lok){print "*** ERROR $scrName after ini\n",$msg,"\n";
		die '*** during initialising $scrName   ';}

#-------------------------------------------------------------------------------
# do the job (here we go)
#-------------------------------------------------------------------------------
    $fh="STDOUT" if ($Lverb);
    $fh=$fhTrace if (! $Lverb);

    $#fileOutOk=0;		# --------------------------------------------------
    foreach $it (1..$#fileIn){	# loop over all input files
	print $fh "--- $scrName \t $fileIn[$it] -> $fileOut[$it]\n"         if ($par{"verbose"});

	if    (! $par{"doTable"}) { 
	    $fileOutTable=0;}
	elsif (! defined $par{"fileOutTable"}  || $par{"fileOutTable"} eq "1" || 
	       length($par{"fileOutTable"})<=1 || $par{"fileOutTable"} eq "unk"){
	    $fileOutTable=1;}
	else{
	    $fileOutTable=$par{"fileOutTable"};}
	
	($Lok,$msg,@fileRm)=
	    &hsspFilter($fileIn[$it],$fileOut[$it],$par{"exeFilterHssp"},$par{"fileMatGcg"},
			$par{"inclPos"},$par{"exclPos"},$par{"minIde"},$par{"maxIde"},$par{"minSim"},
			$par{"maxSim"},$par{"thresh"},$par{"threshSgi"},$par{"mode"},
			$fileOutTable,$par{"redRed"},
			$par{"dirWork"},$par{"debug"},$par{"jobid"},$par{"fileOutScreen"},$fh);
	print $fh "--- $scrName \t ok $fileOut[$it]\n"                         if ($par{"verbose"} && $Lok);
	print $fh "*** ERROR $scrName: no $fileOut[$it] (from $fileIn[$it])\n" if (! $Lok);
	push(@fileOutOk,$fileOut[$it])                                         if ($Lok);
    }
    

#-------------------------------------------------------------------------------
# work done, go home
#-------------------------------------------------------------------------------
                                # ------------------------------
                                # deleting intermediate files
    &cleanUp($fh)               if (! $par{"debug"}); 
                                # ------------------------------
                                # final words
    if ($Lverb) { 
	print $fhLoc "--- $scrName ended fine .. -:\)\n"    if ($#fileOutOk>0);
	print $fhLoc "*** $scrName failed nicely .. -:\)\n" if ($#fileOutOk==0);
				# ------------------------------
	$timeEnd=time;		# runtime , run time
	$timeRun=$timeEnd-$timeBeg;
	print $fhLoc
	    "--- date     \t \t $Date \n",
	    "--- run time \t \t ",&fctSeconds2time($timeRun)," (hour:min:sec)\n";
                                # ------------------------------
				# output files
	print $fhLoc "--- \n";		# 
	print $fhLoc "--- output file";print $fhLoc "s" if ($#fileOut>1); print $fhLoc ":\n";
	foreach $_(@fileOutOk){
	    printf $fhLoc "--- %-20s %-s\n"," ",$_ if (-e $_);}}
    return(1,"ok $sbrName");	# 
}				# end of hssp_filter

#===============================================================================
sub ini {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   initialises variables/arguments
#-------------------------------------------------------------------------------
    $sbrName="$scrName".":ini";
    $par{"dirPerl"}=            "/home/rost/pub/phd/scr/"; # directory for perl scripts needed
				# ------------------------------
    foreach $arg(@ARGV){	# highest priority arguments
	next if ($arg !~/=/);
	if    ($arg=~/dirLib=(.*)$/)   { $dir=$1;}
	elsif ($arg=~/ARCH=(.*)$/)     { $ARCH=$1;}
	elsif ($arg=~/PWD=(.*)$/)      { $PWD=$1;}
	elsif ($arg=~/^packName=(.*)/) { $par{"packName"}=$1; 
					 shift @ARGV if ($ARGV[1] eq $arg); }  }

    $ARCH=$ENV{'ARCH'}      if (! defined $ARCH && defined $ENV{'ARCH'});
    $PWD= $ENV{'PWD'}       if (! defined $PWD  && defined $ENV{'PWD'}); $PWD=~s/\/$// if ($PWD=~/\/$/);
    $pwd= $PWD              if (defined $PWD);
    $pwd.="/"               if (defined $pwd && $pwd !~ /\/$/);

				# ------------------------------
				# include perl libraries
    if (! defined $par{"dirPerl"} || ! -d $par{"dirPerl"}){
	$dir=$ENV{'PERLLIB'}    if (defined $ENV{'PERLLIB'} || ! defined $dir || ! -d $dir);
	$dir="/home/rost/perl/" if (! defined $dir || ! -d $dir);
	$dir.="/"               if ($dir !~/\/$/);
	$dir=""                 if (! -d $dir);}
    else {
	$dir=$par{"dirPerl"};}
    foreach $lib("lib-ut.pl","lib-br.pl"){
 	$Lok=require $dir.$lib;  
 	die("*** $scrName: failed to require perl library '$lib' (dir=$dir)\n") if (! $Lok);}

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
    %tmp=('sourceFile', $tmp, 'scrName',$scrName, 'scrIn',$scrIn, 'scrGoal', $scrGoal, 'scrNarg',$scrNarg,
	  'scrHelpTxt', $scrHelpTxt);
				# special help
    $tmp{"scrAddHelp"}= "";
    $tmp{"special"}=    "table".","."list".","."red".",";
    $tmp{"table"}=      "shortcut for doTable=1, write table of pairwise sequence ide (all-against-all)\n";
    $tmp{"list"}=       "shortcut for isList=1,  i.e. input file is list of files";
    $tmp{"red"}=        "=N : shortcut for redRed=N\n";

    $tmp{"scrAddHelp"}.="help curve    : general info about the HSSP curves, distances, thresholds\n";

#                       "------------------------------------------------------------\n";
    $tmp{"help curve"}= "The general concept is to filter pairs that are not signifi-\n";
    $tmp{"help curve"}.="cantly  sequence similar to the guide sequence to assure the\n";
    $tmp{"help curve"}.="structural similarity between the aligned protein pair.  The\n";
    $tmp{"help curve"}.="notion of  SIGNIFICANT  is taken from analysing a  large data\n";
    $tmp{"help curve"}.="set of protein pairs of known structure.  For details see:\n";
    $tmp{"help curve"}.="    http://www.embl-heidelberg.de/~rost/Papers/98curve.html\n";
    $tmp{"help curve"}.="    -> well, soon you may access that site...\n";
    $tmp{"help curve"}.="    (Meanwhile: Sander & Schneider, Proteins, 1991, 9, 56-68.)\n";
    $tmp{"help curve"}.="    \n";
#                       "------------------------------------------------------------\n";
    $tmp{"help curve"}.="All distances, and thresholds are compiled as distances from\n";
    $tmp{"help curve"}.="an alignment-dependent cut-off for significance. \n";
    $tmp{"help curve"}.="homology\n";
    $tmp{"help curve"}.="\n";
    $tmp{"help curve"}.="Rules (ruleBoth, ruleSgi) implement simple rules-of-thumb to\n";
    $tmp{"help curve"}.="increase the chance of structural similarity (in particular:\n";
    $tmp{"help curve"}.="   ruleSgi = include all with similarity > identity\n";
    $tmp{"help curve"}.="proved to be extremely powerful  (however, at the expense of\n";
    $tmp{"help curve"}.="low coverage (i.e. not many pairs fulfill this  constraint).\n";
    $tmp{"help curve"}.="\n";
    $tmp{"help curve"}.="The in-built reduction of redundancy ('help red') is crucial\n";
    $tmp{"help curve"}.="to improve the accuracy of the current version of PHD. E.g.:\n";
    $tmp{"help curve"}.="   redRed=80  \n";
    $tmp{"help curve"}.="will exclude all pairs with more than 80%  pairwise sequence\n";
    $tmp{"help curve"}.="identity. (Note: values of redRed=80-90 are highly recommen-\n";
    $tmp{"help curve"}.="ded for running PHD.)\n";
    $tmp{"help curve"}.="\n";

    $tmp{"s_k_i_p"}="manual,problems,hints";

    ($Lok,$msg)=		# want help?
	&brIniHelpLoop($scrName,%tmp);
                                return(0,"*** ERROR $sbrName: after lib-ut:brIniHelp\n".$msg) if (! $Lok);
    print "--- suggest \n";
    die $scrName.'.pl help curve   ' if ($msg eq "fin");
    
				# ------------------------------
				# read command line input
    @argUnk=			# standard command line handler
	&brIniGetArg;

    foreach $arg (@argUnk){     # interpret specific command line arguments
	next if ($arg=~/^(dirLib|ARCH|PWD|packName)=/);
        if    ($arg=~/^list$/i)             { $par{"isList"}=1;}
	elsif ($arg=~/^table$/i)            { $par{"doTable"}=1;}
	elsif ($arg=~/^nice-(\d+)$/)        { $par{"optNice"}="nice -".$1;}
	elsif ($arg=~/^red=(\d+)/i)         { $par{"redRed"}=$1;}
	elsif ($arg=~/^incl=(.*)/i)         { $par{"inclPos"}=$1;}
	elsif ($arg=~/^excl=(.*)/i)         { $par{"exclPos"}=$1;}
	elsif ($arg=~/^exe=(.*)/i)          { $par{"exeFilterHssp"}=$1; }
	elsif ($arg=~/^fileOut=(.*)/i)      { $fileOut=$1; }
	elsif ($arg=~/^no[t]?_?scr[en]*$/i) { $Lverb=$Lverb2=$par{"verbose"}=$par{"verb2"}=0; }
	elsif ($arg eq "nonice")            { $par{"optNice"}=" ";}
	else  {
	    return(0,"*** ERROR $sbrName: kwd '$arg' not understood\n");}}
                                # --------------------------------------------------
                                # digest input file formats
                                # --------------------------------------------------
    if (defined $par{"isList"} && $par{"isList"} eq "1"){ # input is file list
        &open_file("$fhin","$fileIn[1]") ||
            return(0,"*** ERROR $sbrName: failed to open fileIn=$fileIn\n");
        $#fileIn= 0 if ($#fileIn==1);
        while (<$fhin>) {$_=~s/\s|\n//g;$file=$_;
			 if (-e $file){
			     push(@fileIn,$file);}
                         else { # search for it
                             ($fileOk,$tmp)=&hsspGetFile($file,"STDOUT",$par{"dirHssp"});
                             print "--- missing $file \n" if ($fileOk && ! -e $fileOk && $par{"verbose"});
                             push(@fileIn,$fileOk) if ($fileOk && -e $fileOk);}}close($fhin);}
				# ------------------------------
				# final settings
    $Lok=			# standard settings
	&brIniSet;              return(0,"*** ERROR $sbrName: after lib-ut:brIniSet\n") if (! $Lok);

    return(0,"*** ERROR $sbrName: no input file given!!\n") if ($#fileIn==0);
    $#fileOut=0;                # reset output files
    if    (defined $fileOut && $fileOut && length($fileOut) > 1){
	$par{"fileOut"}=$fileOut;}
    elsif (defined $par{"fileOut"} && $par{"fileOut"} && length($par{"fileOut"}) > 1){
	$fileOut=$par{"fileOut"}; }

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

    $exclude="exe,xyz";         # xyz to exclude from error check
				# ------------------------------
    ($Lok,$msg)=		# check errors
        &brIniErr($exclude);    return(0,"*** ERROR $sbrName: after lib-ut:brIniErr\n".$msg) if (! $Lok);  
				# ------------------------------
                                # trace file
    if (defined $par{"fileOutTrace"} && $par{"fileOutTrace"} ne "unk" && length($par{"fileOutTrace"})>0){
        print "--- \t open $fhTrace for trace file ",$par{"fileOutTrace"}," \n" if ($Lverb2);
        &open_file("$fhTrace",">".$par{"fileOutTrace"}) || 
            return(0,"*** ERROR $sbrName: failed to open new file for trace : ".$par{"fileOutTrace"}."\n");}
    else {
	$fhTrace="STDOUT";}

				# ------------------------------
				# write settings
    if ($par{"verbose"}){
	($Lok,$msg)=
	    &brIniWrt($exclude,$fhTrace);
	                        return(0,"*** ERROR $sbrName: after lib-ut:brIniWrt\n".$msg) if (! $Lok);}


    $optNice=$par{"optNice"};
    if ($optNice=~/nice\s*-/){$optNice=~s/nice-/nice -/;
                              $tmp=$optNice;$tmp=~s/\s|nice|\-|\+//g;
                              setpriority(0,0,$tmp) if (length($tmp)>0);}
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
				# --------------------
				# directories
    $par{"dirHome"}=            "/home/rost/pub/";
    $par{"dirSrc"}=             $par{"dirHome"}. "lib/";   # all source except for binaries
    $par{"dirSrcMat"}=          $par{"dirSrc"}.  "mat/";   # general material
    $par{"dirPerl"}=            $par{"dirSrc"}.  "perl/"   # perl libraries
        if (! defined $par{"dirPerl"});
    $par{"dirPerlScr"}=         $par{"dirPerl"}. "scr";    # perl scripts needed
    $par{"dirBin"}=             $par{"dirHome"}. "bin/";   # FORTRAN binaries of programs needed

				# <<<<<<<<<<<<<<<<<<<<
				# for porting PHD asf
    $par{"dirSrcMat"}=          "/home/rost/pub/phd/". "mat/";   # general material
    $par{"dirPerl"}=            "/home/rost/pub/phd/". "scr/";   # perl libraries
    $par{"dirPerlScr"}=         "/home/rost/pub/phd/". "scr/";   # perl scripts needed
    $par{"dirBin"}=             "/home/rost/pub/phd/". "bin/";   # FORTRAN binaries of programs needed

    $par{"dirConvertSeq"}=      $par{"dirBin"};

    $par{"dirOut"}=             ""; # directory for output files
    $par{"dirWork"}=            ""; # working directory
				# databases to search for files
    $par{"dirHssp"}=            "/home/rost/data/hssp/,/data/hssp/";
				# additional user specified db

                                # further on work
				# --------------------
				# files
#    $par{"title"}=              "unk"; # output files will be called 'Pre-title.ext'
    $par{"fileOut"}=            0;
    $par{"fileOutTable"}=       0;      # file with the table of the pairwise distances (you must activate the
				        # option by 'doTable=1' or 'table' on the command line
    $par{"fileOutTrace"}=       "HSSPFIL-TRACE-". "jobid".".tmp"; # file tracing some warnings and errors
    $par{"fileOutScreen"}=      "HSSPFIL-SCREEN-"."jobid".".tmp"; # file dumping the screen for convert_seq output

    $par{"fileHelpMan"}=        "unk"; # file with manual
    $par{"fileHelpOpt"}=        "unk"; # file with options
    $par{"fileHelpHints"}=      "unk"; # file with hints, note: also passed as par{scrHelpHints}
    $par{"fileHelpProblems"}=   "unk"; # file with known problems, also passed as par{scrHelpProblems}

				# file extensions
#    $par{"preOutTmp"}=          "Out-";
    $par{"extOut"}=             "-fil.hssp"; # extension added to output file name (extHssp in input file will be 
                                # replaced by extOut, chains added before that)
    $par{"extOutTable"}=        ".distance_tab";

    $par{"extHssp"}=            ".hssp"; # expected extension of HSSP file
				# file handles
    $fhin=                      "FHIN";
    $fhTrace=                   "FHTRACE";
                                # --------------------
                                # job control
    $par{"jobid"}=              "jobid"; # unique job identifier (set to $$ if not defined)
    $par{"debug"}=              0; # if 1 : keep (most) temporary files
    $par{"verbose"}=$Lverb=     1; # blabla on screen
    $par{"verb2"}=$Lverb2=      0; # more verbose blabla

    $par{"optNice"}=            "nice -15 ";

				# --------------------
				# parameters
    $par{"doTable"}=            0; # also write the distance table

    $par{"exclPos"}=            0; # exclude particular positions  = '1' | '1-5' | '1,3,7' | '1-5,7'
    $par{"inclPos"}=            0; # include particular positions  = '1' | '1-5' | '1,3,7' | '1-5,7'
    $par{"minIde"}=             0; # exclude if below minimal distance for thresholds on identity 
    $par{"maxIde"}=             0; # exclude if above maximal distance for thresholds on identity 
    $par{"minSim"}=             0; # exclude if below minimal distance for thresholds on similarity
    $par{"maxSim"}=             0; # exclude if above maximal distance for thresholds on similarity
    $par{"thresh"}=             0; # include all above threshold (given as percentage distance from HSSP curves)
    $par{"threshSgi"}=          0; # include if SIM > IDE and both above threshSgi
    $par{"mode"}=               0; # specifies the mode of applying the thresholds 'thresh' and 'treshSgi':
                                   #     =  'ide|sim|ruleBoth|ruleSgi|old' (or combination separated by ' ')
                                   #     -  mode must be defined to use rule, or thresh, or threshSgi!!
                                   #     -   for additional filter on old threshold add 'old'
    $par{"redRed"}=             0; # reduce redundancy, i.e.,  exclude all pairs with pairwise sequence 
                                   #        identity higher than value given (integer for percenge seq ide!).
                                   #  note: exclusion in the order of appearance in the HSSP file
    $par{"fileMatGcg"}=         $par{"dirSrcMat"}.    "Maxhom_GCG.metric";  # MAXHOM-GCG matrix
                                # needed for conversion into HSSP format!
				# --------------------
				# executables
#    $par{"exeConvertSeq"}=      $par{"dirBin"}.  "convert_seq98".".".$ARCH;
    $par{"exeFilterHssp"}=      $par{"dirBin"}.  "filter_hssp98".".".$ARCH;
}				# end of iniDef

#===============================================================================
sub cleanUp {
    local($fhLoc)=@_;
    local($sbrName,$fhinLoc,@tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#    cleanUp                    deletes intermediate files
#-------------------------------------------------------------------------------
    $fhLoc="STDOUT"             if (! defined $fhLoc || ! $fhLoc);

    if ($scrName){$tmp="$scrName".":";}else{$tmp="";} $sbrName="$tmp"."cleanUp";
    if ($#fileRm>0){		# remove intermediate files
	foreach $file (@fileRm){
	    next if (! -e $file);
	    print $fhLoc "--- $sbrName unlink '",$file,"'\n" if ($Lverb2);
	    unlink($file);}}
    foreach $kwd ("fileOutTrace","fileOutScreen"){
        next if (! defined $par{"$kwd"} || ! -e $par{"$kwd"});
        print $fhLoc "--- $sbrName unlink '",$par{"$kwd"},"'\n" if ($Lverb2);
        unlink($par{"$kwd"});}
}				# end of cleanUp

#===============================================================================
sub hsspFilter {
    local($fileInLoc,$fileOutLoc,$exeFilterHssp,$fileMatGcg,
          $inclTxtIn,$exclTxtIn,$minIdeIn,$maxIdeIn,$minSimIn,$maxSimIn,
	  $threshIn,$threshSgiIn,$mode,$fileTable,$redRed,
	  $dirWork,$LdebugLoc,$jobidLoc,$fileScreenLoc,$fhSbr) = @_ ;
    local($sbrNamex,$fhinLoc,$tmp,$Lok,@kwdRdHdr);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspFilter                  filters HSSP file
#       in:                     $fileIn,$fileOut,$exeFilterHssp,$fileMatGcg,
#       in NOTE:                give 'def' instead of argument for default settings
#                               of any of the above argument (except for files)
#       in NOTE:                for the following '=0' -> no action
#       in:                     $inclTxt     = '1' | '1-5' | '1,3,7' | '1-5,7'
#       in:                     $exclTxt     = '1' | '1-5' | '1,3,7' | '1-5,7'
#       in:                     $minIde|Sim  = minimal ide|sim distance
#       in:                     $maxIde|Sim  = maximal ide|sim distance
#       in:                     $thresh      = threshold applied
#       in:                     $threshSgi   = threshold applied for rule 'similarity > identity'
#       in:                     $mode        = 'ide|sim|ruleBoth|ruleSgi' (or combination separated by ' ')
#       in NOTE:                    mode must be defined to use rule, or thresh, or threshSgi!!
#       in NOTE:                    for additional filter on old threshold add 'old'
#       in:                     $fileTable   = table with pairwise levels of sequence identity
#       in NOTE:                =0  -> avoid writing a table
#       in NOTE:                =1  -> default name = out-filter.dist_tab
#       in:                     $redRed      = clean all pairs above this threshold (order of appearance!)
#       in NOTE:                    integer for percentage cut-off!
#       in:                     $dirWork -> directory in which temporary files are
#                                   written (if not existing: assume is file name)
#                               =0  -> local dir (files  HSSPFIL...)
#       in:                     $LdebugLoc   = 1 -> temporary files kept
#       in:                     $jobid       = additional qualifier for temporary files (if 0 =$$)
#       in:                     $fileScreen  = intermediat file for FORTRAN output (if 0 -> STDOUT)
#       in:                     $fhSbr       = file handle for info (if 0 -> none written)
#       out:                    implicit fileout
#       err:                    (1,'ok'), (0,'message')
#       GLOBAL:                 $rd{} used as GLOBAL for communication with sbr
#-------------------------------------------------------------------------------
    $sbrNamex="lib-prot:"."hsspFilter";$fhinLoc="FHIN_"."hsspFilter";
                                # ------------------------------
				# check arguments
    return(0,"*** $sbrNamex: not def fileInLoc!")              if (! defined $fileInLoc);
    return(0,"*** $sbrNamex: not def fileOutLoc!")             if (! defined $fileOutLoc);
    return(0,"*** $sbrNamex: not def exeFilterHssp!")          if (! defined $exeFilterHssp);
    return(0,"*** $sbrNamex: not def fileMatGcg!")             if (! defined $fileMatGcg);
    return(0,"*** $sbrNamex: not def inclTxtIn!")              if (! defined $inclTxtIn);
    return(0,"*** $sbrNamex: not def exclTxtIn!")              if (! defined $exclTxtIn);
    return(0,"*** $sbrNamex: not def minIdeIn!")               if (! defined $minIdeIn);
    return(0,"*** $sbrNamex: not def maxIdeIn!")               if (! defined $maxIdeIn);
    return(0,"*** $sbrNamex: not def minSimIn!")               if (! defined $minSimIn);
    return(0,"*** $sbrNamex: not def maxSimIn!")               if (! defined $maxSimIn);
    return(0,"*** $sbrNamex: not def threshIn!")               if (! defined $threshIn);
    return(0,"*** $sbrNamex: not def threshSgiIn!")            if (! defined $threshSgiIn);
    return(0,"*** $sbrNamex: not def fileTable!")              if (! defined $fileTable);
    return(0,"*** $sbrNamex: not def redRed!")                 if (! defined $redRed);
    return(0,"*** $sbrNamex: not def dirWork!")                if (! defined $dirWork);
    return(0,"*** $sbrNamex: not def LdebugLoc!")              if (! defined $LdebugLoc);
    return(0,"*** $sbrNamex: not def jobidLoc!")               if (! defined $jobidLoc);
    return(0,"*** $sbrNamex: not def fileScreenLoc!")          if (! defined $fileScreenLoc);
    return(0,"*** $sbrNamex: not def fhSbr!")                  if (! defined $fhSbr);

				# ------------------------------
				# default settings
    $exeFilterHssp="/home/rost/pub/bin/filter_hssp98.".$ARCH  if ($exeFilterHssp eq "def");
    $fileMatGcg=   "/home/rost/pub/lib/mat/Maxhom_GCG.metric" if ($fileMatGcg eq "def");

    return(0,"*** $sbrNamex: miss in file '$fileInLoc'!")      if (! -e $fileInLoc);
    return(0,"*** $sbrNamex: miss in file '$fileMatGcg'!")     if (! -e $fileMatGcg);
    return(0,"*** $sbrNamex: miss exe '$exeFilterHssp'!")      if (! -e $exeFilterHssp && ! -l $exeFilterHssp);

    return(0,"*** $sbrNamex: '$fileInLoc' not HSSP file!")     if (! &is_hssp($fileInLoc));
    return(0,"*** $sbrNamex: '$fileInLoc' empty HSSP file!")   if (&is_hssp_empty($fileInLoc));

				# ------------------------------
				# digest input
    $fileTmp=$dirWork      if ($dirWork && ! -d $dirWork);
    $minIde=0              if (! $minIdeIn);  
    $maxIde=100            if (! $maxIdeIn);  
    $minSim=0              if (! $minSimIn); 
    $maxSim=100            if (! $maxSimIn);
    $thresh=-100           if (! $threshIn);
    $threshSgi=-100        if (! $threshSgiIn);

    $jobidLoc=$$           if (! $jobidLoc);

    $fhSysRunProg=0;
    $fhSysRunProg="STDOUT" if ($fhSbr eq "1");
    $fhSysRunProg=$fhSbr   if ($fhSbr && $fhSbr ne "1");

    $fhSysRunProg="STDOUT" if ($LdebugLoc);
    $fileScreenLoc=0       if ($LdebugLoc);

    if (! $dirWork){
	$dirWork="";}
    else {$dirWork.="/"    if ($dirWork !~/\/$/);}
	
    $fileTmp=           $dirWork."HSSPFIL-".$jobidLoc.".tmp";
    
    if ($fileTable eq "1"){	# name of file with pair ide table
	$tmp=$fileOutLoc;$tmp=~s/\.hssp.*$//g;
	$fileTable=$tmp.".dist_tab";}
				# ------------------------------
				# defaults
    @kwdRdHdr=("NALIGN","NR","ID","STRID","IDE","WSIM","LALI");
    undef %rd;			# --------------------------------------------------
    ($Lok,%rd)=                 # read HSSP header
        &hsspRdHeader($fileInLoc,@kwdRdHdr);
    return(0,"*** ERROR $sbrNamex: failed to read HSSP file '$fileInLoc' header\n") if (! $Lok);

				# --------------------------------------------------
				# marke those to be excluded
				# (written into temporary file)
    $#inclPos=$#inclIde=$#inclSim=$#inclBoth=$#inclSgi=$#exclPos=$#exclIde=$#exclSim=0;
				# label by number
    @inclPos= &hsspFilterGetPosIncl($inclTxtIn)             if ($inclTxtIn);
    @exclPos= &hsspFilterGetPosExcl($exclTxtIn)             if ($exclTxtIn);
				# label by max/min distance
    @exclIde= &hsspFilterGetIdeCurveMinMax($minIde,$maxIde) if ($maxIdeIn || $minIdeIn);
    @exclSim= &hsspFilterGetSimCurveMinMax($minSim,$maxSim) if ($maxSimIn || $minSimIn);
				# label by thresholds
    @inclIde= &hsspFilterGetIdeCurve($thresh)               if ($mode && $mode =~/^ide/);
    @inclSim= &hsspFilterGetSimCurve($thresh)               if ($mode && $mode =~/^sim/);
    @inclBoth=&hsspFilterGetRuleBoth($threshSgi)            if ($mode && $mode =~/^ruleBoth/);
    @inclSgi= &hsspFilterGetRuleSgi ($threshSgi)            if ($mode && $mode =~/^ruleSgi/);
				# --------------------------------------------------
				# hierarchy
    $#incl=$ctNoAction=$ctIncl=0;
    foreach $it (1..$rd{"NROWS"}){
				# thresholds
	$incl[$it]=1 if (defined $inclIde[$it]  || defined $inclSim[$it]); # (1) take IDE or SIM
	$incl[$it]=0 if (defined $exclIde[$it]  || defined $exclSim[$it]); #     exclude overrides!
				# rules
	$incl[$it]=1 if (defined $inclBoth[$it] || defined $inclSgi[$it]); # (2) take from rules
				# positions
	$incl[$it]=1 if (defined $inclPos[$it]);                           # (3) position specified ?
	$incl[$it]=0 if (defined $exclPos[$it]);                           #     exclude overrides

				# ------------------------------
				# what to do if not?
	if (! defined $incl[$it]){
				# no wishes -> take it!
	    if (! @inclIde && ! @inclSim && ! @inclBoth && ! @inclSgi && ! @inclPos){
		$incl[$it]=1; ++$ctNoAction;}
	    else {		# there was a 'wish list' -> default is to exclude
		$incl[$it]=0;}}
	++$ctIncl if ($incl[$it]);
    }
							
    $numProt=$rd{"NROWS"};          # store to clean memory
    undef %rd;                      # save memory

				# ------------------------------
				# print onto screen
    if ($fhSbr){print  $fhSbr "--- $sbrNamex: take no:";
                foreach $it (1..$numProt){
                    print $fhSbr "$it," if ($incl[$it]);} print $fhSbr "\n";
                printf $fhSbr "--- $sbrNamex: -->    =%5d alignments\n",$ctIncl;}
				# ------------------------------
				# write new file
                                # no action, just copy
    if ($ctNoAction == $numProt && $ctIncl == $numProt){
	($Lok,$msg)=
            &sysCpfile($fileInLoc,$fileTmp);
        return(0,"*** ERROR $sbrNamex: failed to copy in=$fileInLoc, to new=$fileTmp\n") if (! $Lok);}
    else {                      # mark file
	($Lok,$msg)=
            &hsspFilterMarkFile($fileInLoc,$fileTmp,@incl);
        return(0,"*** ERROR $sbrNamex: failed to mark=$fileInLoc, to new=$fileTmp\n")    if (! $Lok);}
				# securtiy: check again for existence of file
    return(0,"*** ERROR $sbrNamex: failed to make neww=$fileTmp\n") if (! -e $fileTmp);

				# --------------------------------------------------
				# run FORTRAN 
				# ------------------------------
    $threshOld="ALL";		# correct threshold (formula+x)
    $threshOld=
	&maxhomGetThresh($thresh) if ($mode =~ /^old/ && $thresh);
				# ------------------------------
				# set up answers
    $cmd=          "";		# avoid warnings
    $anClean=      "NO";
    $anClean=      "YES"        if ($redRed);
    $anRed=        " ";
    if ($redRed && $redRed<100){ # reduce redundant pairs?
	$tmp=$redRed/100;
	$tmp=~s/(\.\d\d).*$/$1/; # only 2 digits
	$anRed=    "$tmp";}
    $anTable=      "NO"         if (! $fileTable);
    $anTable=      $fileTable   if ($fileTable);
				# ------------------------------
				# run filter_hssp
    eval "\$cmd=\"$exeFilterHssp,$fileTmp,$fileOutLoc,$fileMatGcg,$threshOld,$anRed,$anClean,$anTable \"";
    ($Lok,$msg)=
#	&sysRunProg($cmd,0,$fhSysRunProg); # xx
	&sysRunProg($cmd,$fileScreenLoc,$fhSysRunProg);

    return(0,"*** ERROR $sbrNamex: failed to filter hssp ($fileTmp,$fileOutLoc)\n".$msg."\n")
	if (! $Lok || ! -e $fileOutLoc);
				# ------------------------------
                                # free memory
    $#inclPos=$#inclIde=$#inclSim=$#inclBoth=$#inclSgi=$#exclPos=$#exclIde=$#exclSim=$#incl=
	$ctNoAction=$ctIncl=0; undef %rd;
				# ------------------------------
    $#tmp=0;                    # process temporary files
    foreach $file ($fileTmp,$fileScreenLoc){
	push(@tmp,$file) if (-e $file);}
    if (! $LdebugLoc){		# remove temporary files
	foreach $file(@tmp){
	    print $fhSbr "--- $sbrNamex: remove $file\n" if ($fhSbr);
	    unlink($file);}
	return(1,"ok $sbrNamex");}
    else {
	return(1,"ok $sbrNamex",@tmp);}
}				# end of hsspFilter

1;
