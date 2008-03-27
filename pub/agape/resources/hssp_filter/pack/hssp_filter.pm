#------------------------------------------------------------------------------#
#	Copyright				        	1998	       #
#	Burkhard Rost		rost@EMBL-Heidelberg.DE			       #
#	Wilckensstr. 15		http://www.embl-heidelberg.de/~rost/	       #
#	D-69120 Heidelberg						       #
#				version 1.0   	May,    	1998	       #
#				version 1.1   	Oct,    	1998	       #
#------------------------------------------------------------------------------#

package hssp_filterPack;

#my hack d.p.
$binAll=$0; $binAll=~s/^(.*\/).*/$1/; 
$binAll="" if(! defined $binAll);
$binAll.="support_bin/";

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
    $scrHelpTxt.="   - exclude too short alignments (e.g. minLen=40)\n";
    $scrHelpTxt.=" \n";
    $scrHelpTxt.="Example:\n";
    $scrHelpTxt.="   hssp_filter file.hssp red=80 threshSgi=-10 thresh=0 mode=ide\n";
#    $scrHelpTxt.=" \n";
    $scrHelpTxt.=" \n";
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
}

#===============================================================================
sub hssp_filterSbr {
#-------------------------------------------------------------------------------
#   hssp_filterSbr              package version of script
#-------------------------------------------------------------------------------
    $[ =1 ;			# sets array count to start at 1, not at 0

    @ARGV=@_;			# pass from calling

				# ------------------------------
				# initialise variables
#    @ARGV=split(/\s+/,&get_in_keyboard("command line"));	# x.x mac specific
				# ------------------------------
				# initialise variables
    ($Lok,$msg)=  
	&ini();                 if (! $Lok) { print "*** ERROR $scrName after ini\n",$msg,"\n";
					      die '*** during initialising $scrName   ';}

#-------------------------------------------------------------------------------
# do the job (here we go)
#-------------------------------------------------------------------------------
    $fh="STDOUT" if ($Lverb);
    $fh=$fhTrace if (! $Lverb);

    $#fileOutOk=0;		# --------------------------------------------------
    foreach $it (1..$#fileIn){	# loop over all input files
	
	print $fh "--- $scrName \t $fileIn[$it] -> $fileOut[$it]\n" if ($par{"verbose"});
	if ($par{"skipExisting"} && -e $fileOut[$it]){
	    print $fh "--- $scrName skipped since $fileOut[$it] existing\n";
	    next;}

	if    (! $par{"doTable"}) { 
	    $fileOutTable=0;}
	elsif (! defined $par{"fileOutTable"}  || $par{"fileOutTable"} eq "1" || 
	       length($par{"fileOutTable"})<=1 || $par{"fileOutTable"} eq "unk"){
	    $fileOutTable=1;}
	else{
	    $fileOutTable=$par{"fileOutTable"};}
	
	($Lok,$msg,@fileRm)=
	    &hsspFilter($fileIn[$it],$fileOut[$it],$par{"exeFilterHssp"},$par{"fileMatGcg"},
			$par{"inclPos"},$par{"exclPos"},$par{"minLen"},$par{"maxLen"},
                        $par{"minIde"},$par{"maxIde"},$par{"minSim"},$par{"maxSim"},
			$par{"thresh"},$par{"threshSgi"},$par{"threshBoth"},$par{"mode"},
                        $fileOutTable,$par{"redRed"},
			$par{"dirWork"},$par{"debug"},$par{"jobid"},$par{"fileOutScreen"},$fh);

	print $fh 
            "--- $scrName \t ok $fileOut[$it]\n" if ($par{"verbose"} && $Lok);
	print $fh 
            "*** ERROR $scrName: no $fileOut[$it] (from ".
                "$fileIn[$it])\n$msg\n"          if (! $Lok);
	push(@fileOutOk,$fileOut[$it])           if ($Lok);

				# ------------------------------
				# estimate time
	if ($#fileIn > 10 && $par{"verbose"} && $Lok) {
	    $estimate=
		&fctRunTimeLeft($timeBeg,$#fileIn,$it);
	    $estimate="?"           if ($it < 5);
	    printf $fh 
		"--- %-40s %4d (%4.1f%-1s), time left=%-s\n",
		$fileIn[$it],$it,(100*$it/$#fileIn),"%",$estimate; }
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
	print $fh "--- $scrName ended fine .. -:\)\n"    if ($#fileOutOk>0);
	print $fh "*** $scrName failed nicely .. -:\)\n" if ($#fileOutOk==0);
				# ------------------------------
	$timeEnd=time;		# runtime , run time
	$timeRun=$timeEnd-$timeBeg;
	print $fh
	    "--- date     \t \t $Date \n",
	    "--- run time \t \t ",&fctSeconds2time($timeRun)," (hour:min:sec)\n";
                                # ------------------------------
				# output files
	print $fh "--- \n";		# 
	print $fh "--- output file";print $fh "s" if ($#fileOut>1); print $fh ":\n";
	foreach $_(@fileOutOk){
	    printf $fh "--- %-20s %-s\n"," ",$_   if (-e $_);}}
    return(1,"ok $sbrName");	# 
}				# end of hssp_filterSbr

#===============================================================================
sub ini {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   initialises variables/arguments
#-------------------------------------------------------------------------------
    $sbrName="$scrName".":ini";
    $par{"dirPerl"}=            $binAll; # directory for perl scripts needed
				# ------------------------------
    foreach $arg (@ARGV){	# highest priority arguments
	next if ($arg !~/=/);
	if    ($arg=~/dirLib=(.*)$/)   { $dir=$1;}
	elsif ($arg=~/PWD=(.*)$/i)     { $PWD=$1;}
	elsif ($arg=~/^ARCH=(.*)$/i)   { $ARCH=$1;}
	elsif ($arg=~/^packName=(.*)/) { $par{"packName"}=$1; 
					 shift @ARGV if ($ARGV[1] eq $arg); }  }

    $ARCH=$ENV{'ARCH'}          if (! defined $ARCH && defined $ENV{'ARCH'});
    $ARCH=$ARCH || 0;
				# try to determine archictecture (ARCH)
    if (! $ARCH) {
	$ARCH=&getSysARCH(0);
	if (! $ARCH) {
	    $ARCH="SGI64";	# default ARCH

	    print "*** WARN $sbrName: failed to get machine architecture!\n";
	    print "***      please provide the following argument on the command line:\n";
	    print "***      ARCH=ARCHITECTURE\n";
	    print "***      where ARCHITECTURE is e.g. SGI64, SGI32, SUNMP, ALPHA\n";
	    print "*** DEFAULT taken:\n";
	    print "*** \n";
	    print "***      ARCH=$ARCH\n";
	    print "*** \n";
	    print "*** NOTE if this is wrong the program will not run correctly!\n"; }}
    
				# local dir
    if (! defined $PWD || ! -e $PWD) {
	$PWD=&sysGetPwd(); }
    $pwd= $PWD                  if (defined $PWD && -d $PWD);
    $pwd.="/"                   if (defined $pwd && $pwd !~ /\/$/);

				# ------------------------------
				# include perl libraries
#     if (! defined $par{"dirPerl"} || ! -d $par{"dirPerl"}){
# 	$dir=$ENV{'PERLLIB'}    if (defined $ENV{'PERLLIB'} || ! defined $dir || ! -d $dir);
# 	$dir="/home/rost/perl/" if (! defined $dir || ! -d $dir);
# 	$dir.="/"               if ($dir !~/\/$/);
# 	$dir=""                 if (! -d $dir);}
#     else {
# 	$dir=$par{"dirPerl"};}
#     foreach $lib("lib-ut.pl","lib-br.pl"){
#  	$Lok=require $dir.$lib;  
#  	die("*** $scrName: failed to require perl library '$lib' (dir=$dir)\n") if (! $Lok);}

				# ------------------------------
    $timeBeg=     time;		# date and time
    $Date=        &sysDate();
				# ------------------------------
				# first settings for parameters 
    &iniDef();			# NOTE: may be overwritten by DEFAULT file!!!!

				# ------------------------------
				# HELP stuff

				# standard help
    $tmp=0;
    $tmp=$par{"packName"}       if (defined $par{"packName"});
    $tmp=$0                     if (! defined $tmp || ! $tmp); 
    %tmp=('sourceFile', $tmp, 'scrName',$scrName, 'scrIn',$scrIn, 'scrGoal', $scrGoal, 'scrNarg',$scrNarg,
	  'scrHelpTxt', $scrHelpTxt);
    $tmp{"scrNameFull"}=$0;
				# special help
    $tmp{"scrAddHelp"}= "";
    $tmp{"special"}=    "table,list,red,curve,exe,minLen,len,skip,";

    $tmp{"skip"}=       "no job if output file existing";
    $tmp{"table"}=      "shortcut for doTable=1, write table of pairwise sequence ide (all-against-all)\n";
    $tmp{"list"}=       "shortcut for isList=1,  i.e. input file is list of files";
    $tmp{"red"}=        "=N : shortcut for redRed=N\n";
    $tmp{"minLen"}=     "<minLen|len>=INTEGER    -> all alignments shorter than this excluded\n";
    $tmp{"len"}=        $tmp{"minLen"};

    $tmp{"scrAddHelp"}.="help curve    : general info about the HSSP curves, distances, thresholds\n";
    $tmp=               "---                   ";
#    $tmp=               "---    ";
    $tmp{"exe"}=             "=x OR exeFilterHssp=x    -> FORTRAN executable";
#                            "------------------------------------------------------------\n";
    $tmp{"help curve"}=      "\n";
    $tmp=               "---                   ";
    $tmp{"help curve"}.=     "---    concept of filter (HSSP curve)\n";
    $tmp{"help curve"}.=$tmp."The general concept is to filter pairs that are not signifi-\n";
    $tmp{"help curve"}.=$tmp."cantly  sequence similar to the guide sequence to assure the\n";
    $tmp{"help curve"}.=$tmp."structural similarity between the aligned protein pair.  The\n";
    $tmp{"help curve"}.=$tmp."notion of  SIGNIFICANT  is taken from analysing a  large data\n";
    $tmp{"help curve"}.=$tmp."set of protein pairs of known structure.  For details see:\n";
    $tmp{"help curve"}.=$tmp."    http://www.embl-heidelberg.de/~rost/Papers/98curve.html\n";
    $tmp{"help curve"}.=$tmp."    -> well, soon you may access that site...\n";
    $tmp{"help curve"}.=$tmp."    (Meanwhile: Sander & Schneider, Proteins, 1991, 9, 56-68.)\n";
    $tmp{"help curve"}.=$tmp."    \n";
    $tmp{"help curve"}.=$tmp."All distances, and thresholds are compiled as distances from\n";
    $tmp{"help curve"}.=$tmp."an alignment-dependent cut-off for significant homology. \n";

#                            "------------------------------------------------------------\n";
    $tmp{"help curve"}.=     "---   thresh=I, with: -75 <= I <= 75  \n";
    $tmp{"help curve"}.=$tmp."All alignments further away from the threshold curve  than I\n";
    $tmp{"help curve"}.=$tmp."are excluded.  Three modes of curves are available:\n";

    $tmp{"help curve"}.=     "---   mode=[ide|sim|ruleBoth|ruleSgi|old]  \n";
    $tmp{"help curve"}.=$tmp."ide      -> filter with to new (1998) identity curve\n";
    $tmp{"help curve"}.=$tmp."sim      -> filter with to new (1999) similarity curve\n";
    $tmp{"help curve"}.=$tmp."old      -> filter with to old (1991) identity curve\n";
    $tmp{"help curve"}.=$tmp."ruleBoth :  see below\n";
    $tmp{"help curve"}.=$tmp."ruleBoth :  see below\n";

    $tmp{"help curve"}.=     "---   [ruleSgi|ruleBoth]  \n";
    $tmp{"help curve"}.=$tmp."Rules (ruleBoth, ruleSgi) implement simple rules-of-thumb to\n";
    $tmp{"help curve"}.=$tmp."increase the chance of structural similarity (in particular:\n";
    $tmp{"help curve"}.=$tmp."   ruleSgi = include all with similarity > identity\n";
    $tmp{"help curve"}.=$tmp."proved to be extremely powerful  (however, at the expense of\n";
    $tmp{"help curve"}.=$tmp."low coverage (i.e. not many pairs fulfill this  constraint).\n";

    $tmp{"help curve"}.=     "---   threshSgi=I, with: -75 <= I <= 75  \n";
    $tmp{"help curve"}.=$tmp."1. sets mode to 'ruleSgi',  i.e. all pairs with similarity >\n";
    $tmp{"help curve"}.=$tmp."   identity are included. \n";
    $tmp{"help curve"}.=$tmp."2. the minimal threshold for which the rule is applied is I \n";
#                            "------------------------------------------------------------\n";
    $tmp{"help curve"}.=     "---   red=I , with 0 < I <= 100  \n";
    $tmp{"help curve"}.=$tmp."The in-built reduction of redundancy ('help red') is crucial\n";
    $tmp{"help curve"}.=$tmp."to improve the accuracy of the current version of PHD. E.g.:\n";
    $tmp{"help curve"}.=$tmp."   redRed=80  \n";
    $tmp{"help curve"}.=$tmp."will exclude all pairs with more than 80%  pairwise sequence\n";
    $tmp{"help curve"}.=$tmp."identity. (Note: values of redRed=80-90 are highly recommen-\n";
    $tmp{"help curve"}.=$tmp."ded for running PHD.)\n";
#                            "------------------------------------------------------------\n";
    $tmp{"help curve"}.=     "---   [minLen|maxLen|minIde|maxIde|minSim|maxSim]=I\n";
    $tmp{"help curve"}.=$tmp."Maximal or minimal values for sequence length (Len), identi-\n";
    $tmp{"help curve"}.=$tmp."ty (Ide), and similarity (Sim).\n";
#                            "------------------------------------------------------------\n";
    $tmp{"help curve"}.=     "---    \\\\\\  Suggested for running PHD:                  ///\n";
    $tmp{"help curve"}.=     "---     ++>           red=90 thresh=-2 threshSgi=-10   <++\n";
    $tmp{"help curve"}.=     "---    ///                                              \\\\\\\n";
#    $tmp{"help curve"}.=$tmp."\n";
#                            "------------------------------------------------------------\n";

    $tmp{"curve"}=$tmp{"help curve"};

    $tmp{"s_k_i_p"}="manual,problems,hints";

    if ($#ARGV > 1 && "$ARGV[1] $ARGV[2]" eq "help curve") {
	($Lok,$msg)=
	    &brIniHelp(%tmp);   return(0,"*** ERROR $sbrName: after lib-ut:brIniHelp\n".
				       $msg) if (! $Lok);
	exit; }

    ($Lok,$msg)=		# want help?
	&brIniHelpLoop($scrName,
		       %tmp);   return(0,"*** ERROR $sbrName: after lib-ut:brIniHelp\n".
				       $msg) if (! $Lok);
    if ($msg eq "fin") {print 
			    "--- suggest \n".
				"$0 help curve\n";
			exit;}
				# ------------------------------
				# read command line input
    @argUnk=			# standard command line handler
	&brIniGetArg();

    $LruleBoth=$LruleSgi=0;

    foreach $arg (@argUnk){     # interpret specific command line arguments
	next if ($arg=~/^(dirLib|ARCH|PWD|packName)=/);
        if    ($arg=~/^list$/i)             { $par{"isList"}=       1;}
	elsif ($arg=~/^de?bu?g$/i)          { $par{"debug"}=        1;}
	elsif ($arg=~/^table$/i)            { $par{"doTable"}=      1;}
	elsif ($arg=~/^nice-(\d+)$/)        { $par{"optNice"}=      "nice -".$1;}
	elsif ($arg=~/^red=(\d+)/i)         { $par{"redRed"}=       $1;}
	elsif ($arg=~/^incl=(.*)/i)         { $par{"inclPos"}=      $1;}
	elsif ($arg=~/^excl=(.*)/i)         { $par{"exclPos"}=      $1;}
	elsif ($arg=~/^exe=(.*)/i)          { $par{"exeFilterHssp"}=$1; }
        elsif ($arg=~/^ide=(.*)/i)          { $par{"minIde"}=       $1; }

        elsif ($arg=~/^len=(.*)/i)          { $par{"minLen"}=       $1; }
        elsif ($arg=~/^minLen=(.*)/i)       { $par{"minLen"}=       $1; }
        elsif ($arg=~/^maxLen=(.*)/i)       { $par{"maxLen"}=       $1; }

        elsif ($arg=~/^ruleBoth/i)          { $LruleBoth=           1; }
        elsif ($arg=~/^ruleSgi/i)           { $LruleSgi=            1; }

        elsif ($arg=~/^skip$/)              { $par{"skipExisting"}= 1; }

	elsif ($arg=~/^fileOut=(.*)/i)      { $par{"fileOut"}=      $1; }
	elsif ($arg=~/^(ide|sim|both|sgi)$/){ $par{"mode"}=         $1; }
	elsif ($arg=~/^no[t]?_?scr[en]*$/i) { $Lverb=$Lverb2=
						  $par{"verbose"}=$par{"verb2"}=0; }
	elsif ($arg eq "nonice")            { $par{"optNice"}=      " ";}
	else  {
	    return(0,"*** ERROR $sbrName: kwd '$arg' not understood\n");}}
				# ------------------------------
                                # correct for modes
    $par{"mode"}=$par{"modeDef"}
        if (! $par{"mode"} && 
            (length($par{"thresh"}) > 0 || 
             length($par{"threshSgi"}) > 0 || length($par{"threshBoth"}) > 0));
    $par{"mode"}.=",ruleBoth"   if ($LruleBoth || length($par{"threshBoth"}) > 0);
    $par{"mode"}.=",ruleSgi"    if ($LruleSgi  || length($par{"threshSgi"}) > 0);
    
        
				# ------------------------------
				# hierarchy of blabla
    $par{"verb2"}=1             if ($par{"debug"});
    $par{"verbose"}=1           if ($par{"verb2"});
	
    $Lverb= $par{"verbose"}     if (defined $par{"verbose"} && $par{"verbose"});
    $Lverb2=$par{"verb2"}       if (defined $par{"verb2"}   && $par{"verb2"});

				# ------------------------------
				# directories: add '/'
    foreach $kwd (keys %par) {
	next if ($kwd !~/^dir/);
	next if (length($par{"$kwd"})==0 || $par{"$kwd"} eq "unk" );
	$par{"$kwd"}.="/"       if ($par{"$kwd"} !~ /\/$/);}

                                # --------------------------------------------------
                                # digest input file formats
                                # --------------------------------------------------
				# automatic list finding..
    $par{"isList"}=1            if ($fileIn[1] =~/\.list$/);
				# read list
    $#fileMissing=0;

    if (defined $par{"isList"} && $par{"isList"} eq "1"){ # input is file list
        &open_file("$fhin","$fileIn[1]") ||
            return(0,"*** ERROR $sbrName: failed to open fileIn=$fileIn\n");
        $#fileIn= 0 if ($#fileIn==1);
        while (<$fhin>) {
	    $_=~s/\s|\n//g;$file=$_;
	    if (-e $file){
		push(@fileIn,$file);}
	    else {		# search for it
		($fileOk,$tmp)=&hsspGetFile($file,"STDOUT",$par{"dirHssp"});
		if ($fileOk && -e $fileOk) {
		    push(@fileIn,$fileOk);
		    push(@fileMissing,$file);}
		else {
		    print "--- missing $file \n" if ($par{"verbose"});
		    push(@fileMissing,$file);}
	    }
	}close($fhin);
				# ------------------------------
				# write record of missing files
	if ($#fileMissing>=1){
	    $fileMissing="MISSING_FILES_".$scrName; $fileMissing=~s/\s|\..*$//g;
	    print "--- NOTE $sbrName: write file of missing files=$fileMissing\n";
#	    if ($par{"verbose"});
	    $fhout_miss=           "FHOUT_MISSING";
	    open($fhout_miss,">".$fileMissing) ||
		warn("*** ERROR $sbrName: failed opening fileMissing=$fileMissing!\n");
	    foreach $file (@fileMissing){
		print $fhout_miss "$file\n";}
	    close($fhout_miss);}
    }
				# ------------------------------
				# final settings
    $Lok=			# standard settings
	&brIniSet();            return(0,"*** ERROR $sbrName: after lib-ut:brIniSet\n") if (! $Lok);

    return(0,"*** ERROR $sbrName: no input file given!!\n") if ($#fileIn==0);

    $#fileOut=0;                # reset output files
    if    (defined $fileOut && $fileOut && length($fileOut) > 1){
	$par{"fileOut"}=$fileOut;}
    elsif (defined $par{"fileOut"} && $par{"fileOut"} ne "unk" && 
	   $par{"fileOut"} && length($par{"fileOut"}) > 1){
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
				# massage temporary files
    if ($par{"dirWork"} && $par{"dirWork"} ne "unk" && length($par{"dirWork"}) > 0) {
	$par{"fileOutTrace"}= $par{"dirWork"}.$par{"fileOutTrace"} 
	    if ($par{"fileOutTrace"} !~ /$par{"dirWork"}/ &&
		defined $par{"fileOutTrace"} && 
		$par{"fileOutTrace"} ne "unk" && length($par{"fileOutTrace"}) > 0);
	$par{"fileOutScreen"}=$par{"dirWork"}.$par{"fileOutScreen"}
	     if ($par{"fileOutScreen"} !~ /$par{"dirWork"}/ &&
		 defined $par{"fileOutScreen"} && 
		 $par{"fileOutScreen"} ne "unk" && length($par{"fileOutScreen"}) > 0);
    }

				# ------------------------------
                                # trace file
    if (defined $par{"fileOutTrace"} && 
        $par{"fileOutTrace"} ne "unk" && length($par{"fileOutTrace"}) > 0 &&
        ! $par{"debug"} ){
        print "--- \t open $fhTrace for trace file ",$par{"fileOutTrace"}," \n" if ($Lverb2);
        &open_file("$fhTrace",">".$par{"fileOutTrace"}) || 
            return(0,"*** ERROR $sbrName: failed to open new file for trace : ".
                   $par{"fileOutTrace"}."\n");}
    else {
	$fhTrace="STDOUT";}

				# ------------------------------
				# write settings
    if ($par{"verbose"}){
	($Lok,$msg)=
	    &brIniWrt($exclude,$fhTrace);
	                        return(0,"*** ERROR $sbrName: after lib-ut:brIniWrt\n".
                                       $msg) if (! $Lok);}

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
    $par{"dirHome"}=            $binAll;
    $par{"dirSrc"}=             $binAll; #$par{"dirHome"}. "lib/";   # all source except for binaries
    $par{"dirSrcMat"}=          $binAll; #$par{"dirSrc"}.  "mat/";   # general material
    $par{"dirPerl"}=            $binAll; #$par{"dirSrc"}.  "perl/"   # perl libraries
       # if (! defined $par{"dirPerl"});
    $par{"dirPerlScr"}=         $binAll; #$par{"dirPerl"}. "scr";    # perl scripts needed
    $par{"dirBin"}=             $$binAll; #par{"dirHome"}. "bin/";   # FORTRAN binaries of programs needed

				# <<<<<<<<<<<<<<<<<<<<
				# for porting PHD asf
    $par{"dirSrcMat"}=          $binAll; #"/home/rost/pub/phd/". "mat/";   # general material
    $par{"dirPerl"}=            $binAll; #"/home/rost/pub/phd/". "scr/";   # perl libraries
    $par{"dirPerlScr"}=         $binAll; #"/home/rost/pub/phd/". "scr/";   # perl scripts needed
    $par{"dirBin"}=             $binAll; #"/home/rost/pub/phd/". "bin/";   # FORTRAN binaries of programs needed

    $par{"dirConvertSeq"}=      $par{"dirBin"};

    $par{"dirOut"}=             ""; # directory for output files
    $par{"dirWork"}=            ""; # working directory
				# databases to search for files
    $par{"dirHssp"}=            $binAll; #"/home/rost/data/hssp/,/data/hssp/";
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
    $par{"skipExisting"}=       0; # skip if output file already there
    $par{"doTable"}=            0; # also write the distance table

    $par{"exclPos"}=            0; # exclude particular positions  = '1' | '1-5' | '1,3,7' | '1-5,7'
    $par{"inclPos"}=            0; # include particular positions  = '1' | '1-5' | '1,3,7' | '1-5,7'
    $par{"minLen"}=             0; # exclude alignments shorter than this
    $par{"maxLen"}=             0; # exclude alignments longer than this

    $par{"minIde"}=             0; # exclude if below minimal distance for thresholds on identity 
    $par{"maxIde"}=             0; # exclude if above maximal distance for thresholds on identity 
    $par{"minSim"}=             0; # exclude if below minimal distance for thresholds on similarity
    $par{"maxSim"}=             0; # exclude if above maximal distance for thresholds on similarity
    $par{"thresh"}=             ""; # include all above threshold (given as percentage distance from HSSP curves)
    $par{"threshSgi"}=          ""; # include if SIM > IDE and both above threshSgi
    $par{"threshBoth"}=         ""; # include if SIM and IDE both above threshBoth
    $par{"mode"}=               0; # specifies the mode of applying the thresholds 'thresh' and 'treshSgi':
                                   #     =  'ide|sim|ruleBoth|ruleSgi|old' (or combination separated by ' ')
                                   #     -  mode must be defined to use rule, or thresh, or threshSgi!!
                                   #     -   for additional filter on old threshold add 'old'
    $par{"modeDef"}=            "ide"; # default mode when keywords thresh|threshSgi used
#    $par{"modeDef"}=            "old"; # default mode when keywords thresh|threshSgi used
    $par{"redRed"}=             0; # reduce redundancy, i.e.,  exclude all pairs with pairwise sequence 
                                   #        identity higher than value given (integer for percenge seq ide!).
                                   #  note: exclusion in the order of appearance in the HSSP file
    $par{"fileMatGcg"}=         $par{"dirSrcMat"}.    "Maxhom_GCG.metric";  # MAXHOM-GCG matrix
#    $par{"fileMatGcg"}=         $par{"dirSrcMat"}.    "Maxhom_McLachlan.metric";  # MAXHOM-GCG matrix
#    $par{"fileMatGcg"}=         $par{"dirSrcMat"}.    "Maxhom_Blosum.metric";  # MAXHOM-GCG matrix
                                # needed for conversion into HSSP format!
				# --------------------
				# executables
#    $par{"exeConvertSeq"}=      $par{"dirBin"}.  "convert_seq".".".$ARCH;
    $par{"exeFilterHssp"}=      $par{"dirBin"}.  "filter_hssp".".".$ARCH; # FORTRAN excutable
#    $par{"exeFilterHssp"}=      "/home/rost/lion/src-lib/filter_hssp".".".$ARCH; # FORTRAN excutable
}				# end of iniDef

#==============================================================================
# library collected (begin)
#==============================================================================

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
	    push(@tmpAdd,$tmp{"scrNameFull"}." ".$tmp);
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
	 "--- "." " x length($tmp{"scrNameFull"}).
	 "              ........................................");
    @scrHelpLoop=
	($tmp{"scrNameFull"}." help          : lists all options",
	 $tmp{"scrNameFull"}." def           : writes default settings",
	 $tmp{"scrNameFull"}." def keyword   : settings for keyword",
	 $tmp{"scrNameFull"}." help keyword  : explain key, e.g. 'special', or how for 'how' and 'howie'");
    push(@scrHelpLoop,
	 $tmp{"scrNameFull"}." problems      : known problems") 
	if (! defined $tmp{"s_k_i_p"} || $tmp{"s_k_i_p"} !~ /problems/);
    push(@scrHelpLoop,
	 $tmp{"scrNameFull"}." hints         : hints for users")
	if (! defined $tmp{"s_k_i_p"} || $tmp{"s_k_i_p"} !~ /hints/);
    push(@scrHelpLoop,
	 $tmp{"scrNameFull"}." manual        : will cat the entire manual (... MAY be it will)")
	if (! defined $tmp{"s_k_i_p"} || $tmp{"s_k_i_p"} !~ /manual/);
    push(@scrHelpLoop,@tmpAdd) if ($#tmpAdd>0);

    push(@scrHelp,@scrHelpLoop,
	 "--- "." " x length($tmp{"scrNameFull"}).
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
                $tmp{"scrNameFull"}." help keyword\n",
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
                    $tmp{"scrNameFull"}," def keyword'\n \n";}}
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
				# new expression 
        if    ($_=~/[\s\t]+\$par\{[\"\']?([^\"\'\}]+)[\"\']?\}[^\#]*\#\s*(.*)$/){
            $Lis=1;$kwd=$1; push(@tmp,$kwd); 
	    $tmp{"$kwd"}=$2 if (defined $2);}
				# end if only '------' line
        elsif ($Lis && defined $tmp{"$kwd"} && $_=~/^[\s\t]+\# ?\-+/){
            $Lis=0;}
				# add to previous (only if it had an explanation)
        elsif ($Lis && defined $tmp{"$kwd"} && $_=~/^[\s\t]*\# (.*)$/){
            $tmp{"$kwd"}.="\n".$1;}
				# end if nothing followed
        elsif ($Lis){
            $Lis=0;}}close($fhinLoc);
    $tmp{"kwd"}=join(',',@tmp);
    return(1,"ok $sbrName",%tmp);
}				# end of brIniHelpRdItself

#==============================================================================
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
				# ignore lines with only spaces or '-|#|*|='
	next if (length($tmp)<1);
				# purge leading blanks and tabs
	$line=~s/^[\s\t]*|[\s\t]*$//g;
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
		"*** ERROR $sbrName: wrong keyword ($kwd) in defaults file ",
		$par{"fileDefaults"},"\n";}
				# ******************************
	else {			# overwrite
				# ******************************
	    $par{"$kwd"}=$defaults{"$kwd"};}}
    return(0,"*** ERROR $sbrName failed finishing to read defaults file\n") if (! $Lok);

    return(1,"ok $sbrName",%defaults);
}				# end of brIniRdDef

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
	    next if ($par{$kwd} =~ /^$par{"dirOut"}/);
	    next if ($par{$kwd} eq "unk" || ! $par{$kwd});
	    next if ($kwd =~ /screen|trace/i);
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
	    next if (-e $par{"$kwd"});
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

#===============================================================================
sub complete_dir { local($DIR)=@_; $[=1 ; 
		   return(0) if (! defined $DIR);
		   return($DIR) if ($DIR =~/\/$/);
		   return($DIR."/");} # end of complete_dir

#===============================================================================
sub completeDir  { local($DIR)=@_; $[=1 ; 
		   return(0) if (! defined $DIR);
		   return($DIR) if ($DIR =~/\/$/);
		   return($DIR."/");} # end of completeDir

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

#==============================================================================
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

#==============================================================================
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
sub getSysARCH {
    local($exePvmgetarch,@argLoc) = @_ ;
    local($sbrName,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getSysARCH                  tries to get the system architecture
#                               
#       in:                     $exePvmgetarch:  bin-shell script to get ARCH
#                                  = 0           to not execute that one..
#       in:                     @argLoc:         all arguments passed to program, checks
#                                                for one with:
#                                  ARCH=SGI64    .. or so
#       out:                    <0,$ARCH>
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";$sbrName=$tmp."getSysARCH";

    $archFound=0;
    $exePvmgetarch=0            if (! defined $exePvmgetarch);

				# ------------------------------
				# (1) find in arguments passed
				# ------------------------------
    if (defined @argLoc && $#argLoc > 0) {
	foreach $arg (@argLoc) {
	    if ($arg=~/^ARCH=(\S+)/i) {
		$archFound=$1;
				# archs are upper case: convert
		$archFound=~tr/[a-z]/[A-Z]/;
		last; }} }
    return($archFound)          if ($archFound);
	
				# ------------------------------
				# (2) try env asf
				# ------------------------------
    $archFound=$ENV{'ARCH'} || $ENV{'CPUARC'} || 0;
    return($archFound)          if ($archFound);

				# ------------------------------
				# (3) run bin shell script given
				# ------------------------------
    if ($exePvmgetarch && (-e $exePvmgetarch || -l $exePvmgetarch)) {
	$scr=$exePvmgetarch;
	$archFound=`$scr`;	# system call
	$archFound=~s/\s|\n//g; 
	$archFound=0            if (length($archFound < 3) || $archFound !~ /[A-Z][A-Z]/);}
    return($archFound)          if ($archFound);

				# ------------------------------
				# (4) search bin shell script 
				# ------------------------------
    foreach $possible ("/nfs/data5/users/ppuser/server/pub/phd/scr/pvmgetarch.sh",
		       "/home/rost/pub/phd/scr/pvmgetarch.sh",
		       "/home/rost/etc/pvmgetarch.sh") {
	if (-e $possible || -l $possible) {
	    $exePvmgetarch=$possible; 
	    last; }}
				# somewhere in relative paths
    if (! $exePvmgetarch) {
	$dirRelative=$0; $dirRelative=~s/\.\///g; $dirRelative=~s/^(.*\/).*$/$1/;
	foreach $possible ("scr/pvmgetarch.sh","scr/which_arch.sh",
			   "bin/pvmgetarch.sh","bin/which_arch.sh",
			   "etc/pvmgetarch.sh","etc/which_arch.sh",
			   "pvmgetarch.sh","which_arch.sh") {
	    if (-e $possible || -l $possible) {
		$exePvmgetarch=$possible; 
		last; }}}
				# ******************************
				# script not found
    return(0)                   if (! $exePvmgetarch);
				# ******************************
	
				# ------------------------------
				# (5) run bin shell script 
				# ------------------------------
    $scr=$exePvmgetarch;
    $archFound=`$scr`;		# system call
    $archFound=~s/\s|\n//g; 
    $archFound=0               if (length($archFound) < 3 || $archFound !~ /[A-Z][A-Z]/);
    return($archFound);
}				# end of getSysARCH

#==============================================================================
sub getYcurveIde {
    local($laliLoc)=@_; local($expon,$loc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getYcurveIde      out= pide value for new curve
#       in:                     $lali
#       out:                    $pide
#                               pide= 510 * L ^ { -0.32 (1 + e ^-(L/1000)) }
#-------------------------------------------------------------------------------
    $sbrName="lib-br:getYcurveIde";
    return(0,"*** ERROR $sbrName: lali not defined \n") if (! defined $laliLoc);
    return(0,"*** ERROR $sbrName: '$laliLoc' = alignment length??\n") 
	if (length($laliLoc)<1 || $laliLoc=~/[^0-9.]/);

    $expon= - 0.32 * ( 1 + exp (-$laliLoc/1000) );
#    $loc= 510 * $laliLoc ** ($expon);
    $loc= 480 * $laliLoc ** ($expon);
    $loc=100 if ($loc > 100);     # saturation
    return($loc,"ok $sbrName");
}				# end of getYcurveIde

#==============================================================================
sub getYcurveOld {
    local($laliLoc)=@_; local($expon,$loc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getYcurveOld      out= pide value for old curve
#       in:                     $lali
#       out:                    $pide
#                               pide= 510 * L ^ { -0.32 (1 + e ^-(L/1000)) }
#-------------------------------------------------------------------------------
    $sbrName="lib-br:getYcurveOld";
    return(0,"*** ERROR $sbrName: lali not defined \n") if (! defined $laliLoc);
    return(0,"*** ERROR $sbrName: '$laliLoc' = alignment length??\n") 
	if (length($laliLoc)<1 || $laliLoc=~/[^0-9.]/);

    $loc= 290.15 * $laliLoc ** (-0.562);
    $loc=100 if ($loc > 100);   # saturation
    $loc=25  if ($loc < 25);    # saturation
    return($loc,"ok $sbrName");
}				# end of getYcurveOld

#==============================================================================
sub getYcurveSim {
    local($laliLoc)=@_; local($expon,$loc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getYcurveSim      out= psim value for new curve
#       in:                     $lali
#       out:                    $sim
#                               psim= 420 * L ^ { -0.335 (1 + e ^-(L/2000)) }
#-------------------------------------------------------------------------------
    $sbrName="lib-br:getYcurveSim";
    return(0,"*** ERROR $sbrName: lali not defined \n") if (! defined $laliLoc);
    return(0,"*** ERROR $sbrName: '$laliLoc' = alignment length??\n") 
	if (length($laliLoc)<1 || $laliLoc=~/[^0-9.]/);

    $expon= - 0.335 * ( 1 + exp (-$laliLoc/2000) );
    $loc= 420 * $laliLoc ** ($expon);
    $loc=100 if ($loc>100);     # saturation
    return($loc,"ok $sbrName");
}				# end of getYcurveSim

#==============================================================================
sub hsspFilterGetCurveIde {
    local($threshLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok,@takeLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspFilterGetCurveIde       flags positions (in pairs) above identity threshold
#       in:                     $threshLoc= distance from HSSP (new ide) threshold
#       out:                    @takeLoc
#   GLOBAL in /out:             $rd{"NR","$it"},$rd{"LALI","$it"}
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."hsspFilterGetCurveIde";
    $LscreenTmp=0               if (! defined $LscreenTmp);

    $#takeLoc=0;
    foreach $it (1..$rd{"NROWS"}){ # loop over all pairs
	($newIdeThresh,$msg)=
	    &getYcurveIde($rd{"LALI","$it"});
	return(&errSbrMsg("failed getYcurveIde for it=$it, lali=".
			  $rd{"LALI","$it"}.", ide=".$rd{"IDE","$it"},
			  $msg)) if ($msg !~/^ok/);
	$dist=
	    100 * $rd{"IDE","$it"} - $newIdeThresh;
	if ($dist >= $threshLoc){
	    printf 
		"TMP: %3d +  d=%5.1f ide=%3d lali=%3d t=%3d\n",
		$it,$dist,int(100*$rd{"IDE","$it"}),$rd{"LALI","$it"},int($threshLoc) 
                    if ($LscreenTmp);
	    $takeLoc[$it]=1;}
	else { 
	    printf 
		"TMP: %3d  - d=%5.1f ide=%3d lali=%3d t=%3d\n",
		$it,$dist,int(100*$rd{"IDE","$it"}),$rd{"LALI","$it"},int($threshLoc) 
                    if ($LscreenTmp);
	    $takeLoc[$it]=0;}
    }
                                # control: plot curve
    if (0){
        for ($it=1; $it<=300; $it+=5){
            ($newIdeThresh,$msg)=&getYcurveIde($it);
            printf "%3d %8.2f\n",$it,$newIdeThresh;} }

    return(@takeLoc);
}				# end of hsspFilterGetCurveIde

#==============================================================================
sub hsspFilterGetCurveMinMaxIde {
    local($minLoc,$maxLoc,$fhSbr) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok,@notLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspFilterGetCurveMinMaxIde flags positions (in pairs) above maxIde and below minIde
#       in:                     $minLoc,$maxLoc = distances from HSSP (new ide) threshold
#       in:                     $fhSbr: if not defined, no output written
#       out:                    @notLoc
#   GLOBAL in /out:             $rd{"NR","$it"},$rd{"LALI","$it"}
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."hsspFilterGetCurveMinMaxIde";
    $#notLoc=0;
    foreach $it (1..$rd{"NROWS"}){ # loop over all pairs
	($newIdeThresh,$msg)=
	    &getYcurveIde($rd{"LALI","$it"});
	return(&errSbrMsg("failed getYcurveIde for it=$it, lali=".
			  $rd{"LALI","$it"}.", ide=".$rd{"IDE","$it"},
			  $msg)) if ($msg !~/^ok/);
	$dist=
	    100 * $rd{"IDE","$it"} - $newIdeThresh;
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
}				# end of hsspFilterGetCurveMinMaxIde

#==============================================================================
sub hsspFilterGetCurveOld {
    local($threshLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok,@takeLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspFilterGetCurveOld       flags positions (in pairs) above old identity threshold
#       in:                     $threshLoc= distance from HSSP (old ide) threshold
#       out:                    @takeLoc
#   GLOBAL in /out:             $rd{"NR","$it"},$rd{"LALI","$it"}
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."hsspFilterGetCurveOld";
    $LscreenTmp=0               if (! defined $LscreenTmp);

    $#takeLoc=0;
    foreach $it (1..$rd{"NROWS"}){ # loop over all pairs
	($oldIdeThresh,$msg)=
	    &getYcurveOld($rd{"LALI","$it"});
	return(&errSbrMsg("failed getYcurveOld for it=$it, lali=".
			  $rd{"LALI","$it"}.", ide=".$rd{"IDE","$it"},
			  $msg)) if ($msg !~/^ok/);
	$dist=
	    100 * $rd{"IDE","$it"} - $oldIdeThresh;
	if ($dist >= $threshLoc){
	    printf 
		"TMP: %3d +  d=%5.1f ide=%3d lali=%3d t=%3d\n",
		$it,$dist,int(100*$rd{"IDE","$it"}),$rd{"LALI","$it"},int($threshLoc) 
                    if ($LscreenTmp);
	    $takeLoc[$it]=1;}
	else { 
	    printf 
		"TMP: %3d  - d=%5.1f ide=%3d lali=%3d t=%3d\n",
		$it,$dist,int(100*$rd{"IDE","$it"}),$rd{"LALI","$it"},int($threshLoc)
                    if ($LscreenTmp);
	    $takeLoc[$it]=0;}
    }
                                # control: plot curve
    if (0){
        for ($it=1; $it<=100; $it+=5){
            ($ideThresh,$msg)=&getYcurveOld($it);
            printf "%3d %8.2f\n",$it,$ideThresh;} }

    return(@takeLoc);
}				# end of hsspFilterGetCurveOld

#==============================================================================
sub hsspFilterGetCurveSim {
    local($threshLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok,@takeLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspFilterGetCurveSim       flags positions (in pairs) above similarity threshold
#       in:                     $threshLoc= distance from HSSP (new sim) threshold
#       out:                    @take
#   GLOBAL in /out:             @take,$rd{"NR","$it"}
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."hsspFilterGetCurveSim";
    $#takeLoc=0;
    $LscreenTmp=0               if (! defined $LscreenTmp);

    foreach $it (1..$rd{"NROWS"}){ # loop over all pairs
	($newSimThresh,$msg)=
	    &getYcurveSim($rd{"LALI","$it"});
	return(&errSbrMsg("failed getYcurveSim for it=$it, lali=".
			  $rd{"LALI","$it"}.", ide=".$rd{"WSIM","$it"},
			  $msg)) if ($msg !~/^ok/);
	$dist=100 * $rd{"WSIM","$it"} - $newSimThresh;
	if ($dist >= $threshLoc){
	    printf 
		"TMP: %3d +  d=%5.1f sim=%3d lali=%3d t=%3d\n",
		$it,$dist,int(100*$rd{"WSIM","$it"}),$rd{"LALI","$it"},int($threshLoc) 
                    if ($LscreenTmp); 
	    $takeLoc[$it]=1; }
	else { 
	    printf 
		"TMP: %3d  - d=%5.1f sim=%3d lali=%3d t=%3d\n",
		$it,$dist,int(100*$rd{"WSIM","$it"}),$rd{"LALI","$it"},int($threshLoc) 
                    if ($LscreenTmp);
	    $takeLoc[$it]=0;}
    }
                                # control: plot curve
    if (0){
        for ($it=1; $it<=300; $it+=5){
            ($newSimThresh,$msg)=&getYcurveSim($it);
            printf "%3d %8.2f\n",$it,$newSimThresh;} }

    return(@takeLoc);
}				# end of hsspFilterGetCurveSim

#==============================================================================
sub hsspFilterGetCurveMinMaxSim {
    local($minLoc,$maxLoc,$fhSbr) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok,@notLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspFilterGetCurveMinMaxSim flags positions (in pairs) above maxSim and below minSim
#       in:                     $minLoc,$maxLoc = distances from HSSP (new sim) threshold
#       in:                     $fhSbr: if not defined, no output written
#       out:                    @notLoc
#   GLOBAL in /out:             $rd{"NR","$it"}
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."hsspFilterGetCurveMinMaxSim";
    $#notLoc=0;
    foreach $it (1..$rd{"NROWS"}){ # loop over all pairs

	($newSimThresh,$msg)=
	    &getYcurveSim($rd{"LALI","$it"});
	return(&errSbrMsg("failed getYcurveSim for it=$it, lali=".
			  $rd{"LALI","$it"}.", ide=".$rd{"WSIM","$it"},
			  $msg)) if ($msg !~/^ok/);
	$dist=100 * $rd{"WSIM","$it"} - $newSimThresh;

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
}				# end of hsspFilterGetCurveMinMaxSim

#==============================================================================
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
				# 
    @exclLoc=
	&get_range($exclTxtLoc);
				# all pairs
    foreach $it (1..$rd{"NROWS"}){
	$takeLoc[$it]=0;
	foreach $i (@exclLoc) { 
	    if ($i == $rd{"NR","$it"}) { 
		$notLoc[$it]=1;
		last;}}}
    return(@notLoc);
}				# end of hsspFilterGetPosExcl

#==============================================================================
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
    @inclLoc=
	&get_range($inclTxtLoc);
				# all pairs
    foreach $it (1..$rd{"NROWS"}){
	$takeLoc[$it]=0;
	foreach $i (@inclLoc) { 
	    if ($i == $rd{"NR","$it"}) {
		$takeLoc[$it]=1;
		last;}}}
    return(@takeLoc);
}				# end of hsspFilterGetPosIncl

#==============================================================================
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

    $#tmp=0;
    foreach $it (1..$rd{"NROWS"}){ # loop over all pairs
	$tmp[$it]=0;
	if ($threshLoc > -100){
	    ($newIdeThresh,$msg)=
		&getYcurveIde($rd{"LALI","$it"});
	    return(&errSbrMsg("failed getYcurveIde for it=$it, lali=".
			      $rd{"LALI","$it"}.", ide=".$rd{"IDE","$it"},
			      $msg)) if ($msg !~/^ok/);
	    ($newSimThresh,$msg)=
		&getYcurveSim($rd{"LALI","$it"});
	    return(&errSbrMsg("failed getYcurveIde for it=$it, lali=".
			      $rd{"LALI","$it"}.", ide=".$rd{"WSIM","$it"},
			      $msg)) if ($msg !~/^ok/);
	    $distSim=100 * $rd{"WSIM","$it"} - $newSimThresh;
	    next if ($distSim < $threshLoc);
	    $distIde=100 * $rd{"IDE","$it"}  - $newIdeThresh;
	    next if ($distIde < $threshLoc);}
	$tmp[$it]=1;
    }
    return(@tmp);
}				# end of hsspFilterGetRuleBoth

#==============================================================================
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
    $threshLoc="-100"           if (! defined $threshLoc);
    $LscreenTmp=0;

    $#tmp=0;
    foreach $it (1..$rd{"NROWS"}){ # loop over all pairs
	$tmp[$it]=0;
				# no threshold given
	next if ($threshLoc <= -100);

	$simLoc=$rd{"WSIM","$it"};$ideLoc=$rd{"IDE","$it"};
	print "TMP: $it not sim=$simLoc, ide=$ideLoc, \n" if ($LscreenTmp && $simLoc < $ideLoc);
				# similarity <= identity
	next if ($simLoc <= $ideLoc);
	print "TMP: $it sim=$simLoc, ide=$ideLoc, \n"     if ($LscreenTmp);

	($newSimThresh,$msg)=
	    &getYcurveSim($rd{"LALI","$it"});
	return(&errSbrMsg("failed getYcurveSim for it=$it, lali=".
			  $rd{"LALI","$it"}.", ide=".$rd{"WSIM","$it"},
			  $msg)) if ($msg !~/^ok/);
	($newIdeThresh,$msg)=
	    &getYcurveIde($rd{"LALI","$it"});
	return(&errSbrMsg("failed getYcurveIde for it=$it, lali=".
			  $rd{"LALI","$it"}.", ide=".$rd{"IDE","$it"},
			  $msg)) if ($msg !~/^ok/);
	print "TMP:     threshSim=$newSimThresh, \n"      if ($LscreenTmp);
	print "TMP:     threshIde=$newIdeThresh, \n"      if ($LscreenTmp);

	$distSim=100 * $rd{"WSIM","$it"} - $newSimThresh;
	print "TMP:     not dsim=$distSim < $threshLoc\n" if ($LscreenTmp && $distSim < $threshLoc);
	next if ($distSim < $threshLoc);
	$distIde=100 * $rd{"IDE","$it"}  - $newIdeThresh;

	print "TMP:     not dide=$distIde < $threshLoc\n" if ($LscreenTmp && $distIde < $threshLoc);
	next if ($distIde < $threshLoc);
	print "TMP:     take: dsim=$distSim, dide=$distIde, threshloc=$threshLoc\n" if ($LscreenTmp);

	$tmp[$it]=1;
    }
    return(@tmp);
}				# end of hsspFilterGetRuleSgi

#==============================================================================
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

#==============================================================================
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

#==============================================================================
sub hsspGetFileLoop { 
    local ($fileInLoop,$Lscreen,@dir) = @_ ; 
    local ($dir,$tmp);
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

#==============================================================================
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
	$_=~s/\n//g;
	$lenLine=length($_);
	if ($LisLongId){
	    $maxMid=115; $maxMid=($lenLine-56) if ($lenLine < 115);
	    $maxEnd=109; $maxEnd=$lenLine  if ($lenLine < 109);
	    $beg=substr($_,1,56);
	    $end=0; $end=substr($_,109)        if ($lenLine >=109);
	    $mid=substr($_,57,115); }
	else {
	    $maxMid= 62; $maxMid=($lenLine-28) if ($lenLine <  90);
	    $beg=substr($_,1,28);
	    $end=0; $end=substr($_,90)         if ($lenLine >=90);
	    $mid=substr($_,29,90); }
	$end=~s/^\s*|\s*$//g;   # purge leading blanks
	$mid=~s/^\s*|\s*$//g;	# purge leading blanks
				# SWISS accession: hack because it may be empty!
	if ($lenLine > 86) {
	    $accnum=substr($_,81,6); $accnum=~s/(\s)\s+/$1/g ; }
	else {
	    $accnum=0;}
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

	$tmp{"ID","$ct"}=     $id;
	$tmp{"NR","$ct"}=     $ct;
	$tmp{"STRID","$ct"}=  $strid;
				# correct for ID = PDBid
	$tmp{"STRID","$ct"}=  $id if ($strid=~/^\s*$/ && &is_pdbid($id));
	    
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

#==============================================================================
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

#==============================================================================
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

#==============================================================================
sub is_pdbid {
    local ($id) = @_ ;
#--------------------------------------------------------------------------------
#   is_pdbid                    checks whether or not id is a valid PDBid (number 3 char)
#       in:                     $file
#       out:                    1 if is DBid, 0 else
#--------------------------------------------------------------------------------
    return 1
	if ((length($id) <= 6) &&
	    ($id=~/^[0-9][0-9a-z]{3,3}[^0-9a-z]?/));
    return 0;
}				# end of is_pdbid

#==============================================================================
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
sub sysCpfile {
    local($fileToCopy,$fileToCopyTo,$niceLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   sysCpfile                   system call '\\cp file1 file2' (or to dir)
#       in:                     file1,file2 (or dir), nice value (nice -19)
#       out:                    ok=(1,'cp a b') , else=(0,msg)
#-------------------------------------------------------------------------------
    $sbrName="sysCpfile";
    $niceLoc="" if (! defined $niceLoc);
    return(0,"*** $sbrName: missing input file '$fileToCopy'!") if (! -e $fileToCopy);
    return(0,"*** $sbrName: needs 2 arg 'fToCopy fToCopyTo'!") if (! defined $fileToCopyTo);

    if (-d $fileToCopyTo){	# is directory
	if ($fileToCopyTo !~/\/$/){$fileToCopyTo.="/";}}

    $Lok= system("$niceLoc \\cp $fileToCopy $fileToCopyTo");
#    return(0,"*** $sbrName: fail copy '$fileToCopy -> $fileToCopyTo' ($Lok)!") if (! $Lok);
    if    (-d $fileToCopyTo){	# is directory
	$tmp=$fileToCopy;$tmp=~s/^.*\///g;$tmp=$fileToCopyTo.$tmp;
	$Lok=0 if (! -e $tmp);}
    elsif (! -e $fileToCopyTo){ $Lok=0; }
    elsif (-e $fileToCopyTo)  { $Lok=1; }
    return(0,"*** $sbrName: fail copy '$fileToCopy -> $fileToCopyTo' ($Lok)!") if (! $Lok);
    return(1,"$niceLoc \\cp $fileToCopy $fileToCopyTo");
}				# end of sysCpfile

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
	    @Date = split(' ',&ctime(time)) ; shift (@Date) ; 
	    $Date="$Date[2] $Date[3], $Date[$#Date]  $Date[4]";
	    return($Date);
	} }
				# ------------------------------
				# or get system time
    $localtime=`date`;
    @Date=split(/\s+/,$localtime);
    $Date="$Date[2] $Date[3], $Date[$#Date] $Date[4]";
    return($Date);
}				# end of sysDate

#===============================================================================
sub sysGetPwd {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   sysGetPwd                   returns local directory
#       out:                    $DIR (no slash at end!)
#-------------------------------------------------------------------------------
    $sbrName="lib-sys:"."sysGetPwd";

				# already defined or in ENV?
    $pwdLoc=  $PWD || $ENV{'PWD'} || 0;

    if ($pwdLoc && -d $pwdLoc) {
	$pwdLoc=~s/\/$//g;
	return($pwdLoc); }
				# read bin/pwd
    if ($pwdLoc && -d "/bin/pwd") {
	open(C,"/bin/pwd|");
	$pwdLoc=<C> || 0;
	close(C); 
	return($pwdLoc)         if ($pwdLoc && -d $pwdLoc); }

    if ($pwdLoc && -d $pwdLoc) {
	$pwdLoc=~s/\/$//g;
	return($pwdLoc); }
				# system call
    $pwdLoc=`pwd`; 
    $pwdLoc=~s/\s|\n//g;

    if (-d $pwdLoc) {
	$pwdLoc=~s/\/$//g;
	return($pwdLoc); }

    return(0);
}				# end of sysGetPwd

#==============================================================================
sub sysRunProg {
    local ($cmd,$fileScrLoc,$fhErrLoc) = @_ ;
    $[ =1;
#-------------------------------------------------------------------------------
#   sysRunProg                  pipes arguments into $prog, and cats the output
#                               from $prog into a file
#       in:                     $cmd,$fileScrLoc,$fhError
#       in:                     $cmd='prog,arg1,arg2' 
#       in:                          where prog is the program, e.g. 'wc -l, file1,file2'
#       in:                     $fileScrLoc     is the output file
#       in:                        NOTE: if not defined: buffered to STDOUT
#       in:                      = 0            to surpress writing
#       in:                     $fhError        filehandle for ERROR writing
#                                  NOTE: to STDOUT if not defined
#       in:                      = 0            to surpress writing
#       out:                    0|1,message
#       err:                    ok -> 1,ok | err -> 0,message
#-------------------------------------------------------------------------------
    $sbrName="lib-ut:sysRunProg";
    return(0,"*** ERROR $sbrName: argument program ($cmd) not defined\n") 
	if (! defined $cmd || length($cmd)<1);
    $fhErrLoc=0                 if (! defined $fhErrLoc);
    $fileScrLoc=0               if (! defined $fileScrLoc);

				# ------------------------------
				# dissect arguments
    ($prog,@arg)=split(/,/,$cmd);
    if    ($fhErrLoc && ! @arg) {
	print $fhErrLoc "-*- WARN $sbrName: no arguments to pipe into:\n$prog\n";
    }
    elsif ($fhErrLoc) {
	print $fhErrLoc 
	    "--- $sbrName: system cmd=\n$prog\n--- $sbrName: fileOut=$fileScrLoc cmd IN:\n$cmd\n";}
				# ------------------------------
				# pipe output into file?
    $Lpipe=0;
    $Lpipe=1                    if ($fileScrLoc);
				# hack br: 08-98 to avoid pipe pipe, i.e.
				#          prog="cmd > file" -> 'cmd > file | cat >> filescreen' fails
    $Lpipe=0                    if ($prog =~ /\s+>>?\s+\S+\s*$/);
    $prog.=" | cat >> $fileScrLoc " if ($Lpipe);
#    print "$cmd\n";exit;
				# ------------------------------
				# opens cmdtmp into pipe
    open (CMD, "|$prog") || 
	warn "*** $sbrName cannot run program '$prog $arg'";
				# get input arguments (< arg)
    foreach $tmp (@arg) {
	$tmp=~s/\n|^\s*|\s*$//; # delete end of line, and leading blanks 
	print CMD "$tmp\n" ;}
    close (CMD) ;		# upon closing: cmdtmp < @out_command executed    
    return(1,"ok $sbrName");
}				# end of sysRunProg


#==============================================================================
# library collected (end)
#==============================================================================

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
          $inclTxtIn,$exclTxtIn,$minLenIn,$maxLenIn,
	  $minIdeIn,$maxIdeIn,$minSimIn,$maxSimIn,
	  $threshIn,$threshSgiIn,$threshBothIn,$mode,$fileTable,$redRed,
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
#       in:                     $minLen      = minimal length of alignment (integer)
#       in:                     $maxLen      = maximal length of alignment (integer)
#       in:                     $minIde|Sim  = minimal ide|sim distance
#       in:                     $maxIde|Sim  = maximal ide|sim distance
#       in:                     $thresh      = threshold applied
#       in:                     $threshSgi   = threshold applied for rule 'similarity > identity'
#       in:                     $threshBoth  = threshold applied for rule 'sim AND ide > threshold'
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
    $LscreenTmp=0;
#    $LscreenTmp=1;
    
                                # ------------------------------
				# check arguments
    return(0,"*** $sbrNamex: not def fileInLoc!")              if (! defined $fileInLoc);
    return(0,"*** $sbrNamex: not def fileOutLoc!")             if (! defined $fileOutLoc);
    return(0,"*** $sbrNamex: not def exeFilterHssp!")          if (! defined $exeFilterHssp);
    return(0,"*** $sbrNamex: not def fileMatGcg!")             if (! defined $fileMatGcg);
    return(0,"*** $sbrNamex: not def inclTxtIn!")              if (! defined $inclTxtIn);
    return(0,"*** $sbrNamex: not def exclTxtIn!")              if (! defined $exclTxtIn);
    return(0,"*** $sbrNamex: not def minLenIn!")               if (! defined $minLenIn);
    return(0,"*** $sbrNamex: not def maxLenIn!")               if (! defined $maxLenIn);

    return(0,"*** $sbrNamex: not def minIdeIn!")               if (! defined $minIdeIn);
    return(0,"*** $sbrNamex: not def maxIdeIn!")               if (! defined $maxIdeIn);
    return(0,"*** $sbrNamex: not def minSimIn!")               if (! defined $minSimIn);
    return(0,"*** $sbrNamex: not def maxSimIn!")               if (! defined $maxSimIn);
    return(0,"*** $sbrNamex: not def threshIn!")               if (! defined $threshIn);
    return(0,"*** $sbrNamex: not def threshSgiIn!")            if (! defined $threshSgiIn);
    return(0,"*** $sbrNamex: not def threshBothIn!")           if (! defined $threshBothIn);
    return(0,"*** $sbrNamex: not def fileTable!")              if (! defined $fileTable);
    return(0,"*** $sbrNamex: not def redRed!")                 if (! defined $redRed);
    return(0,"*** $sbrNamex: not def dirWork!")                if (! defined $dirWork);
    return(0,"*** $sbrNamex: not def LdebugLoc!")              if (! defined $LdebugLoc);
    return(0,"*** $sbrNamex: not def jobidLoc!")               if (! defined $jobidLoc);
    return(0,"*** $sbrNamex: not def fileScreenLoc!")          if (! defined $fileScreenLoc);
    return(0,"*** $sbrNamex: not def fhSbr!")                  if (! defined $fhSbr);

				# ------------------------------
				# default settings
    $exeFilterHssp="/home/rost/pub/bin/filter_hssp98.".$ARCH   if ($exeFilterHssp eq "def");
    $fileMatGcg=   "/home/rost/pub/lib/mat/Maxhom_GCG.metric"  if ($fileMatGcg eq "def");

    return(0,"*** $sbrNamex: miss in file '$fileInLoc'!")      if (! -e $fileInLoc);
    return(0,"*** $sbrNamex: miss in file '$fileMatGcg'!")     if (! -e $fileMatGcg);
    return(0,"*** $sbrNamex: miss exe '$exeFilterHssp'!")      if (! -e $exeFilterHssp && ! -l $exeFilterHssp);

    return(0,"*** $sbrNamex: '$fileInLoc' not HSSP file!")     if (! &is_hssp($fileInLoc));
    return(0,"*** $sbrNamex: '$fileInLoc' empty HSSP file!")   if (&is_hssp_empty($fileInLoc));

				# ------------------------------
				# defaults
				# ------------------------------
    $minIde=       0;
    $maxIde=     100;
    $minSim=       0;
    $maxSim=     100;
    $thresh=    -100;
    $threshSgi= -100;
    $threshBoth=-100;

    $fhSysRunProg= 0;
				# ------------------------------
				# digest input
				# ------------------------------
    $minIde=    $minIdeIn       if ($minIdeIn);
    $maxIde=    $maxIdeIn       if ($maxIdeIn);
    $minSim=    $minSimIn       if ($minSimIn);
    $maxSim=    $maxSimIn       if ($maxSimIn);
    $thresh=    $threshIn       if (length($threshIn)    > 0);
    $threshSgi= $threshSgiIn    if (length($threshSgiIn) > 0);
    $threshBoth=$threshBothIn   if (length($threshBothIn) > 0);

    $fhSysRunProg="STDOUT"      if ($fhSbr eq "1");
    $fhSysRunProg=$fhSbr        if ($fhSbr && $fhSbr ne "1");
    $fhSysRunProg="STDOUT"      if ($LdebugLoc);
    $fileScreenLoc=0            if ($LdebugLoc);

    if (! $dirWork){
	$dirWork="";}
    elsif ($dirWork !~/\/$/) {
	$dirWork.="/"; }
	
    $fileTmp=                   $dirWork."HSSPFIL-".$jobidLoc.".tmp";
    push(@fileRm,$fileTmp);
    
    if ($fileTable eq "1"){	# name of file with pair ide table
	$tmp=$fileOutLoc;$tmp=~s/\.hssp.*$//g;
	$fileTable=$tmp.".dist_tab";}

				# ------------------------------
				# add full path to output file
				#    if not local
    if  ($fileOutLoc=~/\// && $fileOutLoc !~ /^\// ) {
				# local dir
	$pwdLoc=$PWD || &sysGetPwd();
	$fileOutLoc=$pwdLoc."/".$fileOutLoc;}

				# ------------------------------
				# defaults
    @kwdRdHdr=("NALIGN","NR","ID","STRID","IDE","WSIM","LALI");

    undef %rd;			# --------------------------------------------------
                                # read HSSP header
                                # out : $rd{"kwd","$it"}
    ($Lok,%rd)=
        &hsspRdHeader($fileInLoc,@kwdRdHdr);
                                return(0,"*** ERROR $sbrNamex: failed to read HSSP file ".
				       "'$fileInLoc' header\n") if (! $Lok);
				# --------------------------------------------------
				# marke those to be excluded
				# (written into temporary file)
    $#inclPos=$#inclIde=$#inclSim=$#inclBoth=$#inclSgi=$#exclPos=$#exclIde=$#exclSim=0;
				# label by number
    @inclPos= &hsspFilterGetPosIncl($inclTxtIn)             if ($inclTxtIn);
    @exclPos= &hsspFilterGetPosExcl($exclTxtIn)             if ($exclTxtIn);
				# label by max/min distance
    @exclOld= &hsspFilterGetCurveMinMaxOld($minIde,$maxIde) if (($mode && $mode=~/^old/) &&
                                                                ($maxSimIn || $minSimIn) );
    @exclIde= &hsspFilterGetCurveMinMaxIde($minIde,$maxIde) if (($mode && $mode=~/^ide/) &&
                                                                ($maxIdeIn || $minIdeIn) );
    @exclSim= &hsspFilterGetCurveMinMaxSim($minSim,$maxSim) if ($maxSimIn || $minSimIn);
				# label by thresholds
    @inclOld= &hsspFilterGetCurveOld($thresh)               if ($mode && $mode =~/^old/);
    @inclIde= &hsspFilterGetCurveIde($thresh)               if ($mode && $mode =~/^ide/);
    @inclSim= &hsspFilterGetCurveSim($thresh)               if ($mode && $mode =~/^sim/);
    @inclBoth=&hsspFilterGetRuleBoth($threshBoth)           if ($mode && $mode =~/ruleBoth/i);
    @inclSgi= &hsspFilterGetRuleSgi ($threshSgi)            if ($mode && $mode =~/ruleSgi/i ||
								$threshSgi > -100);

				# --------------------------------------------------
				# hierarchy
    $#incl=$ctNoAction=$ctIncl=0;
    foreach $it (1..$rd{"NROWS"}){
				# thresholds
				#              (1a) do NOT take IDE or SIM
	$incl[$it]=0 if ((defined $inclIde[$it] && ! $inclIde[$it]) ||
			 (defined $inclSim[$it] && ! $inclSim[$it]) ||
			 (defined $inclOld[$it] && ! $inclOld[$it]) );
				#              (2a) take IDE or SIM
	$incl[$it]=1 if ((defined $inclIde[$it] && $inclIde[$it]) ||
			 (defined $inclSim[$it] && $inclSim[$it]) ||
			 (defined $inclOld[$it] && $inclOld[$it]) );
				#              (2b) exclude overrides
	$incl[$it]=0 if ((defined $exclIde[$it] && $exclIde[$it]) ||
			 (defined $exclSim[$it] && $exclSim[$it]) ||
			 (defined $exclOld[$it] && $exclOld[$it]));

				# rules
				#              (3)  take from rules
	$incl[$it]=1 if ((defined $inclBoth[$it] && $inclBoth[$it]) || 
			 (defined $inclSgi[$it]  && $inclSgi[$it]));

				# length
	$incl[$it]=0 if (! $incl[$it] && 
                         ( ($minLenIn > 0 && $rd{"LALI",$it} < $minLenIn) ||
                           ($maxLenIn > 0 && $rd{"LALI",$it} > $maxLenIn) ) );

				# positions
				#              (4a) position specified ?
	$incl[$it]=1 if (defined $inclPos[$it] && $inclPos[$it]); 
				#              (4b) exclude overrides
	$incl[$it]=0 if (defined $exclPos[$it] && $exclPos[$it]);

				# ------------------------------
				# what to do if not?
	if (! defined $incl[$it]){
				# no wishes -> take it!
	    if (! @inclIde && ! @inclSim && ! @inclBoth && ! @inclSgi && ! @inclPos){
		$incl[$it]=1; ++$ctNoAction;}
	    else {		# there was a 'wish list' -> default is to exclude
		$incl[$it]=0;}}
	++$ctIncl if ($incl[$it]);
        if ($LscreenTmp) {
            printf "take %3d lali=%3d ide=%3d\n",$it,$rd{"LALI",$it},100*$rd{"IDE",$it} if ($incl[$it]);
            printf "  no %3d lali=%3d ide=%3d\n",$it,$rd{"LALI",$it},100*$rd{"IDE",$it} if (! $incl[$it]);}
    }
							
    $numProt=$rd{"NROWS"};          # store to clean memory
    undef %rd;                      # save memory

				# ------------------------------
				# security: if none survived get
				#    self, at least!
    if ($ctIncl == 0) {
	$incl[1]=1;
	$ctIncl=1;}
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
    return(0,"*** ERROR $sbrNamex: failed to make new=$fileTmp\n") if (! -e $fileTmp); 

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
    $anClean=      "YES"        if ($ctIncl > 1 && $redRed);
    $anRed=        " ";
    if ($ctIncl > 1 && $redRed && $redRed<100){ # reduce redundant pairs?
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
				# security: none found -> take
				#           self
    if (&is_hssp_empty($fileOutLoc)) {
				# all =0
	foreach $it (1..$#incl) { 
	    $incl[$it]=0;}
				# except first
	$incl[1]=1;
	($Lok,$msg)=
            &hsspFilterMarkFile($fileInLoc,$fileTmp,@incl);
        return(0,"*** ERROR $sbrNamex: failed to mark (2)=$fileInLoc, to new=$fileTmp\n") 
	    if (! $Lok);
	$anClean=      "NO";
	$anTable=      "NO"         if (! $fileTable);
	$anTable=      $fileTable   if ($fileTable);
				# ------------------------------
				# run filter_hssp
	eval "\$cmd=\"$exeFilterHssp,$fileTmp,$fileOutLoc,$fileMatGcg,$threshOld,$anRed,$anClean,$anTable \"";
	($Lok,$msg)=
	    &sysRunProg($cmd,$fileScreenLoc,$fhSysRunProg);

	return(0,"*** ERROR $sbrNamex: failed to filter hssp 2nd round ($fileTmp,$fileOutLoc)\n".$msg."\n")
	    if (! $Lok || ! -e $fileOutLoc || &is_hssp_empty($fileOutLoc));}

				# ------------------------------
                                # free memory
    $#inclPos=$#inclIde=$#inclSim=$#inclBoth=$#inclSgi=$#exclPos=$#exclIde=$#exclSim=$#incl=
	$ctNoAction=$ctIncl=0; undef %rd;
				# hack br: 98-10 change one day such that
				#          distance table name is input to FORTRAN!
    $fileOutTableTmp=$fileInLoc;
    $fileOutTableTmp=~s/\.hssp/_distance.table/;
				# ------------------------------
    $#tmp=0;                    # process temporary files
    foreach $file ($fileTmp,$fileScreenLoc){
	push(@tmp,$file) if (-e $file);}
    if (! $LdebugLoc){		# remove temporary files
	foreach $file(@tmp,$fileOutTableTmp){
	    print $fhSbr "--- $sbrNamex: remove $file\n" if ($fhSbr);
	    unlink($file);}
	return(1,"ok $sbrNamex");}
    else {
	return(1,"ok $sbrNamex",@tmp);}
}				# end of hsspFilter

1;
