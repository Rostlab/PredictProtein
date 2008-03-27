#!/usr/bin/perl
##------------------------------------------------------------------------------#
#	Copyright				        	1998	       #
#	Burkhard Rost		rost@EMBL-Heidelberg.DE			       #
#	Wilckensstr. 15		http://www.embl-heidelberg.de/~rost/	       #
#	D-69120 Heidelberg						       #
#				version 0.1   	May,    	1998	       #
#------------------------------------------------------------------------------#

package copf;

INIT: {
#======================================================================
#   Read environment parameters
#======================================================================

    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    $scrName=$0; $scrName=~s/^.*\/|\.pl//g;
    $scrGoal=    "copff: converts protein file formats";
    $scrIn=      "toConvert toConvTo|files* format-out";			# 
    $scrNarg=    2;		# minimal number of input arguments
                                # additional information about script
    $okFormOut=  "hssp,dssp,msf,saf,daf,fastamul,pirmul,fasta,pir,gcg";
    $okFormIn=   "hssp,dssp,fssp,msf,saf,fastamul,pirmul,fasta,pir,gcg,phdrdb,swiss,pdb";
                             @okFormOut=split(/,/,$okFormOut);@okFormIn=split(/,/,$okFormIn);
                             $okFormOutOr=join('|',@okFormOut);$okFormInOr=join('|',@okFormIn);
    $scrHelpTxt= "Formats supported: \n";
    $scrHelpTxt.="  * Input:   ".  $okFormOut."\n";
    $scrHelpTxt.="  * Output:  ".  $okFormIn ."\n";
    $scrHelpTxt.="    \n";
    $scrHelpTxt.="Several ways to run the script:\n";
    $scrHelpTxt.="in: 'file.msf file.hssp'  -> convert MSF to HSSP (assigned according to extensions)\n"; # 
    $scrHelpTxt.="in: '*.msf hssp'          -> all input MSF files converted to HSSP\n";
    $scrHelpTxt.="in: 'file.listx hssp list'-> all files listed in 'file.list' converted to HSSP\n";
    $scrHelpTxt.="                             NOTE: the keyword 'list' makes things easier for me...\n";
    $scrHelpTxt.="                                   if file named *.list, list is assumed!!\n";
    $scrHelpTxt.="in: '*.f fastamul'        -> many FASTAs converted to one big FASTAmul (e.g. database)\n";
    $scrHelpTxt.="in: ''   -> \n";
    $scrHelpTxt.=" \n";
    $scrHelpTxt.="Note 1: if your alignment format is none of the above, I suggest you convert it  to\n";
    $scrHelpTxt.="        the SAF format (see 'help saf' and 'help saf-syn'), which is the simplest.\n";
    $scrHelpTxt.=" \n";
    $scrHelpTxt.="Note 2: Sorry for inconveniences, writing this 'shit' was boring and time consuming\n";
    $scrHelpTxt.="        -> for many conversions A -> B you will have to run the program repetively:\n";
    $scrHelpTxt.="           A -> A1 , A1 -> A2, A2 -> B  ...\n";
    $scrHelpTxt.=" \n";
    $scrHelpTxt.="Further options may be obtained by 'help FORMAT' ...\n";
    $scrHelpTxt.=" \n";
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
}

#===============================================================================
sub copf {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   copf                        package version of script
#-------------------------------------------------------------------------------
    $[ =1 ;			# sets array count to start at 1, not at 0

    @ARGV=@_;			# pass from calling

    ($Lok,$msg)=  &ini();	# initialise variables
    if (! $Lok){print "*** ERROR $scrName after ini\n",$msg,"\n";
		die "--> ERROR during initialising $scrName \nmsg=$msg\n";}

#-------------------------------------------------------------------------------
# do the job (here we go)
#-------------------------------------------------------------------------------
                                # general assignments to reduce typing
    $formIn= $par{"formatIn"};  $extIn= $par{"ext_$formIn"};
    $formOut=$par{"formatOut"}; $extOut=$par{"ext_$formOut"};
    $fh="STDOUT"                if ($Lverb);
    $fh=$fhTrace                if (! $Lverb);
    $nfileIn=$#fileIn;
    $itFile=0;
                                # --------------------------------------------------
                                # alignments
                                # --------------------------------------------------
                                # ------------------------------
    if    ($formIn eq "hssp"){	# in: HSSP
	while (@fileIn) {
	    ++$itFile; $fileIn=shift @fileIn; $fileOutDef=shift @fileOutDef;
	    next if (! $par{"doAgain"} && -e $fileOutDef);
	    &wrtLoc($fh)        if ($par{"verbose"});
	    ($Lok,$msg)=
		&convHsspGen($fileIn,$chainIn[$itFile],$fileOutDef,$formOut,$extOut,
			     $par{"exeConvertSeq"},$par{"exeConvHssp2saf"},
			     $par{"doExpand"},$par{"frag"},$par{"extr"},
			     $par{"fileOutScreen"},$par{"dirWork"},$fhTrace,$par{"doSplitChain"});
	    print $fh "*** ERROR $scrName after convHsspGen\n","*** $msg\n" if (! $Lok || $Lok==2);}}
                                # ------------------------------
    elsif ($formIn eq "fssp"){	# in: FSSP
	while (@fileIn) {
	    ++$itFile; $fileIn=shift @fileIn; $fileOutDef=shift @fileOutDef;
	    next if (! $par{"doAgain"} && -e $fileOutDef);
	    &wrtLoc($fh)        if ($par{"verbose"});
	    ($Lok,$msg)=
		&convFsspGen($fileIn,$fileOutDef,$formOut,$extOut,$par{"exeFssp2daf"},
			     $par{"fileInclProt"},$par{"dirDssp"},$par{"dirWork"},$fhTrace);
	    print $fh "*** ERROR $scrName after convFsspGen\n","*** $msg\n" if (! $Lok || $Lok==2);}}
                                # ------------------------------
                                # in: MSF|SAF|FASTAmul
    elsif ($formIn eq "msf"      || $formIn eq "saf" || 
	   $formIn eq "fastamul" || $formIn eq "pirmul"){
	while (@fileIn) {
	    ++$itFile; $fileIn=shift @fileIn; $fileOutDef=shift @fileOutDef;
	    next if (! $par{"doAgain"} && -e $fileOutDef);
	    &wrtLoc($fh)        if ($par{"verbose"});
	    ($Lok,$msg)=
		&convAliGen($fileIn,$fileOutDef,$formIn,$formOut,$extOut,
			    $par{"exeConvertSeq"},$par{"fileMatGcg"},$par{"doCompress"},
			    $par{"frag"},$par{"extr"},$par{"fileOutScreen"},$par{"dirWork"},$fhTrace);
	    print $fh "*** ERROR $scrName after convAliGen\n","*** $msg\n" if (! $Lok || $Lok==2);}}

# change br 99-03 : commented out, since included in previous!
#				# ------------------------------
#     elsif ($formIn eq "pirmul"){ # in: PIRMUL
# 	while (@fileIn) {
# 	    ++$itFile; $fileIn=shift @fileIn; $fileOutDef=shift @fileOutDef;
# 	    next if (! $par{"doAgain"} && -e $fileOutDef);
# 	    &wrtLoc($fh)        if ($par{"verbose"});
# 	    ($Lok,$msg)=
# 		&convPirmulGen($fileIn,$fileOutDef,$formOut,$extOut,
# 			       $par{"frag"},$par{"extr"},$par{"dirWork"},$fhTrace);
# 	    print $fh "*** ERROR $scrName after convPirmulGen\n","*** $msg\n" if (! $Lok || $Lok==2);}}

                                # --------------------------------------------------
                                # sequences
                                # --------------------------------------------------

                                # ------------------------------
                                # in: FASTA, SWISS, PIR, GCG
    elsif ($formIn eq "fasta" || $formIn eq "swiss" || $formIn eq "pir"  || $formIn eq "gcg"){
	while (@fileIn) {
	    ++$itFile; $fileIn=shift @fileIn; $fileOutDef=shift @fileOutDef;
	    next if (! $par{"doAgain"} && -e $fileOutDef);
	    &wrtLoc($fh)        if ($par{"verbose"});
				# out: ali
	    if ($formOut eq "hssp"){
		($Lok,$msg)=
		    &convAliGen($fileIn,$fileOutDef,$formIn,$formOut,$extOut,
				$par{"exeConvertSeq"},$par{"fileMatGcg"},$par{"doCompress"},
				$par{"frag"},$par{"extr"},$par{"fileOutScreen"},$par{"dirWork"},$fhTrace);
		print $fh "*** ERROR $scrName after convAliGen\n","*** $msg\n" if (! $Lok || $Lok==2); }

				# out: sequence
	    else {
		($Lok,$msg)=
		    &convSeqGen($fileIn,$fileOutDef,$formIn,$formOut,$extOut,
				$par{"exeConvertSeq"},$par{"frag"},$par{"fileOutScreen"},
				$par{"dirWork"},$fhTrace);
		print $fh "*** ERROR $scrName after convSeqGen\n","*** $msg\n" if (! $Lok || $Lok==2);}}}
                                # ------------------------------
                                # in: PDB
    elsif ($formIn eq "pdb"){
	if ($formOut !~ /^(fasta|pir|gcg)/){
	    print $fh "*** ERROR $scrName supported only PDB -> FASTA|PIR|GCG\n";
	    die ' sorry ';}
	while (@fileIn) {
	    ++$itFile; $fileIn=shift @fileIn; $fileOutDef=shift @fileOutDef;
	    next if (! $par{"doAgain"} && -e $fileOutDef);
	    $chainIn=0;
	    $chainIn=shift @chainIn if (@chainIn);
	    &wrtLoc($fh)        if ($par{"verbose"});
	    ($Lok,$msg)=
		&convPdbGen($fileIn,$chainIn,$fileOutDef,$formOut,$extOut,
			    $par{"exeConvertSeq"},$par{"frag"},$par{"dirWork"},$fhTrace);
	    print $fh "*** ERROR $scrName after convPdbGen\n","*** $msg\n" if (! $Lok || $Lok==2);}}
                                # ------------------------------
    elsif ($formIn eq "dssp"){	# in: DSSP
	if ($formOut !~ /^(fasta|pir|saf|msf|hssp)/){   # 
	    print $fh "*** ERROR $scrName supported only DSSP -> FASTA|PIR|MSF|SAF2\n";
	    die ' sorry ';}
	while (@fileIn) {
	    ++$itFile; $fileIn=shift @fileIn; $fileOutDef=shift @fileOutDef;
	    next if (! $par{"doAgain"} && -e $fileOutDef);
	    $chainIn=0;
	    $chainIn=shift @chainIn if (@chainIn);
	    &wrtLoc($fh)        if ($par{"verbose"});
	    ($Lok,$msg)=
		&convDsspGen($fileIn,$chainIn,$fileOutDef,$formOut,$extOut,
			     $par{"exeConvertSeq"},$par{"fileMatGcg"},
			     $par{"frag"},$par{"fileOutScreen"},$par{"dirWork"},$fhTrace,
			     $par{"doSplitChain"});
	    print $fh "*** ERROR $scrName after convDsspGen\n","*** $msg\n" if (! $Lok || $Lok==2);}}
                                # --------------------------------------------------
                                # PHD predictions
                                # --------------------------------------------------
                                # ------------------------------
                                # in: PHDrdb
    elsif ($formIn =~ /^phdrdb/) {
	while (@fileIn) {
	    ++$itFile; $fileIn=shift @fileIn; $fileOutDef=shift @fileOutDef;
	    next if (! $par{"doAgain"} && -e $fileOutDef);
	    $chainIn=0;
	    $chainIn=shift @chainIn if (@chainIn);
	    &wrtLoc($fh)        if ($par{"verbose"});
				# out: msf
	    if ($formOut =~ /^(saf|msf)$/) {
		print $fh "*** option PHD -> $formOut not implemented, yet!\n";
		die '  sorry ...'; }
				# out: DSSP, nicer, HTML, ..
	    else {
		($Lok,$msg)=
		    &convPhdGen($fileIn,$chainIn,$fileOutDef,$formIn,$formOut,$extOut,
				$par{"frag"},$par{"fileOutScreen"},$par{"dirWork"},$fhTrace);
		print $fh "*** ERROR $scrName after convPhdGen\n","*** $msg\n" if (! $Lok || $Lok==2); 
	    }}}
				# **************************************************
				# unrecognised input format
				# **************************************************
    else {
	print "*** ERROR $scrName input format $formIn not supported\n";
	die '  sorry ... ';}

#-------------------------------------------------------------------------------
# work done, go home
#-------------------------------------------------------------------------------
                                # ------------------------------
                                # deleting intermediate files
    &cleanUp()                  if (! $par{"debug"}); 
                                # ------------------------------
                                # final words
    if ($Lverb) { $timeEnd=time; # runtime , run time
		  $timeRun=$timeEnd-$timeBeg;
		  print 
		      "--- $scrName ended on $Date (run time=",&fctSeconds2time($timeRun),")\n";
                                # ------------------------------
                                # output files
		  if    ($#fileOut==1){
		      printf "--- %-20s %-s\n","output file:",$fileOut[1];}
		  elsif ($#fileOut > 10){
		      printf "--- %-20s %-s\n","output files:","";
		      foreach $file (@fileOut){
			  print "$file," if (-e $file);} 
		      print "\n"; }
		  elsif ($#fileOut > 0){
		      print "--- output files:";
		      foreach $_(@fileOut){
			  printf "--- %-20s %-s\n"," ",$_ if (-e $_);}}}
    return(1,"ok $sbrName");
}				# end of copf

#===============================================================================
sub ini {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   initialises variables/arguments
#-------------------------------------------------------------------------------
    $sbrName="$scrName".":ini";


				# ------------------------------
				# get user name
    $USERID=&sysGetUserLoc();

    if    (defined $USERID && $USERID=~/predictprotein|pp|phd/){
	$par{"dirHome"}=            "/home/".$USERID."/server/pub/prof/";
    }
    elsif (defined $USERID && $USERID=~/rost/){
	$par{"dirHome"}=            "/nfs/data5/users/ppuser/server/pub/";
    }
    elsif ($0=~/molbio\/maxhom/){
	$par{"dirHome"}=            "/usr/pub/molbio/maxhom/";
    }
    elsif ($0=~/maxhom/){
	$par{"dirHome"}=            "/nfs/data5/users/ppuser/server/pub/maxhom/";
    }
    else {
	$par{"dirHome"}=            "/usr/pub/molbio/prof/";
    }

				# ------------------------------
    foreach $arg(@ARGV){	# highest priority arguments
	next if ($arg !~/=/);
	if    ($arg=~/dirLib=(.*)$/)   { $dir=            $1;}
	elsif ($arg=~/dirHome=(.*)$/i) { $par{"dirHome"}= $1;}
	elsif ($arg=~/ARCH=(.*)$/)     { $ARCH=           $1;}
	elsif ($arg=~/PWD=(.*)$/)      { $PWD=            $1;}
	elsif ($arg=~/^packName=(.*)/) { $par{"packName"}=$1; 
					 shift @ARGV if ($ARGV[1] eq $arg); }  }


				# ******************************
				# ERROR
    return(&errSbrMsg("after $0:",
		      "missing dirHome, please add the command line option:\n".
		      "dirHome=THE_PATH_WHERE_THIS_SCRIPT_SITS",$SBR))
	if (! defined $par{"dirHome"} ||
	    ! $par{"dirHome"}         ||
	    (length($par{"dirHome"})<1));

				# ------------------------------
				# get architecture $ARCH=
    $ARCH=$ARCH || &getSysARCH();
    
    $PWD= $ENV{'PWD'}           if (! defined $PWD  && defined $ENV{'PWD'}); 
    $PWD=~s/\/$//               if (defined $PWD && $PWD=~/\/$/);
    $pwd= $PWD                  if (defined $PWD);
    $pwd.="/"                   if (defined $pwd && $pwd !~ /\/$/);

				# ------------------------------
    $timeBeg=     time;		# date and time
    $Date=        &sysDate();

				# ------------------------------
				# first settings for parameters 
    &iniDef();			# NOTE: may be overwritten by DEFAULT file!!!!

				# ------------------------------
				# HELP stuff
    &iniHelpLoc();

    ($Lok,$msg)=		# want help?
	&brIniHelpLoop($scrName,%tmp);
                                return(&errSbrMsg("after lib-ut:brIniHelpLoop",$msg,$SBR)) if (! $Lok);

    exit if ($msg eq "fin");
    
				# ------------------------------
				# read command line input
    $#fileIn=0;
    @argUnk=			# standard command line handler
	&brIniGetArg();

    $LuseBigConvertSeq=0;

    foreach $arg (@argUnk){     # interpret specific command line arguments
	next if ($arg=~/^(dirLib|ARCH|PWD|packName)=/);
	if    ($arg=~/^verb\w*2/)                {$par{"verb2"}=$Lverb2=   1;}
	elsif ($arg=~/^verbose/)                 {$par{"verbose"}=$Lverb=  1;}
	elsif ($arg=~/not_?([vV]er|[sS]creen)/ ) {$par{"verbose"}=$Lverb=  0; }
        elsif ($arg=~/^expand$/i)                {$par{"doExpand"}=        1;}
        elsif ($arg=~/^compress$/i)              {$par{"doCompress"}=      1;}
        elsif ($arg=~/^nocompr?e?s?s?$/i)        {$par{"doCompress"}=      0;}
        elsif ($arg=~/^list$/i)                  {$par{"isList"}=          1;}
        elsif ($arg=~/^skip$/i)                  {$par{"doAgain"}=         0;}

        elsif ($arg=~/^big$/i)                   {$LuseBigConvertSeq=      1;}

        elsif ($arg=~/^split$/i)                 {$par{"doSplitChain"}=    1;}

        elsif ($arg=~/^de?bu?g$/i)               {$par{"debug"}=           1;}

	elsif ($arg =~/^formatIn=(.*)$/)         {$par{"formatIn"}=$formIn=$1;}
	elsif ($arg =~/^formatOut=(.*)$/)        {$par{"formatOut"}=$formOut=$1;}

        elsif ($arg=~/^(hssp|msf|dssp|fssp|saf|daf|fastamul|pirmul|swiss|fasta|pir|gcg)$/i){
            $par{"formatOut"}=$1; $par{"formatOut"}=~tr/[A-Z]/[a-z]/;}
	elsif ($arg=~/^fileOut=(.+)$/)           {$par{"fileOut"}=$fileOut=$1;}
                                # process chains (PDB)
	elsif ($arg=~/^(.*)($par{"ext_pdb"}|\.brk)\_([A-Z0-9])/){
            return(0,"*** ERROR $sbrName: kwd=$arg not correct syntax (use:file.pdb_C)\n") 
                if (! defined $1 || ! -e $1);
	    next if (length($1)<2 || ! -e $1);
            push(@fileIn,$1);push(@chainIn,$2);}
                                # process chains (dssp)
	elsif ($arg=~/^(.*$par{"ext_dssp"})\_([A-Z0-9])/){
            return(0,"*** ERROR $sbrName: kwd=$arg not correct syntax (use:file.dssp_C)\n") 
                if (! defined $1 || ! -e $1);
		next if (length($1)<2 || ! -e $1);
            push(@fileIn,$1);push(@chainIn,$2);}
                                # process chains (hssp)
	elsif ($arg=~/^(.*$par{"ext_hssp"})\_([A-Z0-9])/){
            return(0,"*** ERROR $sbrName: kwd=$arg not correct syntax (use:file.hssp_C)\n") 
                if (! defined $1 || ! -e $1);
	    next if (length($1)<2 || ! -e $1);
            push(@fileIn,$1);push(@chainIn,$2);}
        elsif ($arg eq $ARGV[2]){ # to enable calling by 'copf 1ppt.hssp 1ppt.daf'
	    next;}
        elsif ($arg=~/^expand$/i)                {$par{"doExpand"}=        1;}
	else  {
	    return(0,"*** ERROR $sbrName: kwd '$arg' not understood\n");}}

				# ------------------------------
				# replace binary
    if ($LuseBigConvertSeq){
	$par{"exeConvertSeq"}=$par{"exeConvertSeqBig"};
	if (! -e $par{"exeConvertSeq"} && ! -l $par{"exeConvertSeq"}){
	    print 
		"*** you want the BIG for convert_seq.$ARCH(".
		    $par{"exeConvertSeq"}."), however none there!\n";
	    exit;}}
	
				# ------------------------------
				# output file given?
    $fileOut=$par{"fileOut"}    if (defined $par{"fileOut"} && $par{"fileOut"} && 
				    $par{"fileOut"} ne "unk");

				# ------------------------------
				# correct blabla levels
    $par{"verbose"}=$par{"verb2"}=1 if ($par{"debug"});

				# ------------------------------
				# require packages
				# ------------------------------
    foreach $exe ("exeConvHssp2saf","exeFssp2daf") {
	next if ($par{"$exe"}=~/\.pl/);
	if (! -e $par{"$exe"}){
	    print "*** WARN or ERROR (?) $scrName: failed to find package ",$par{"$exe"},"\n";
	    next; }
	$Lok= require $par{"$exe"};
 	die("*** $scrName: failed to require perl package '".$par{"$exe"}."'\n") if (! $Lok);}


                                # --------------------------------------------------
                                # digest input file formats
                                # --------------------------------------------------
    return(0,"*** ERROR $sbrName: no input file given!!\n") if ($#fileIn==0);
				# any file ending with 'list'?
    foreach $fileIn (@fileIn){
	if ($fileIn =~ /\.list/) {
	    $par{"isList"}=1;
	    last;}}
	
    if (defined $par{"isList"} && $par{"isList"} eq "1"){ # input is file list
        &open_file("$fhin","$fileIn[1]") ||
            return(0,"*** ERROR $sbrName: failed to open fileIn=$fileIn\n");
        $#fileIn=$#chainIn=$#dir=0;
        while (<$fhin>) {
	    $_=~s/\s|\n//g;$file=$_;
				# for DSSP and HSSP: digest chains
	    if ($file =~ /^(.*)($par{"ext_hssp"}|$par{"ext_dssp"})\_([A-Z0-9])$/){
		$file=$1.$2;$chain=$3;}
	    else {$chain="*";}
				# add dir if file not existing (hssp)
	    if    (! -e $file && $file =~ /^.*$par{"ext_hssp"}/){
		if (! $#dir){@tmp=split(/,/,$par{"dirHssp"});
			     foreach $tmp(@tmp){
				 push(@dir,&complete_dir($tmp)) if (-d $tmp);}}
		foreach $dir (@dir){ $tmp=$dir.$file;
				     if (-e $tmp){$file=$tmp;
						  last;}}}
				# add dir if file not existing (dssp)
	    elsif (! -e $file && $file =~ /^.*$par{"ext_dssp"}/){
		if (! $#dir){@tmp=split(/,/,$par{"dirDssp"});
			     foreach $tmp(@tmp){
				 push(@dir,&complete_dir($tmp)) if (-d $tmp);}}
		foreach $dir (@dir){ $tmp=$dir.$file;
				     if (-e $tmp){$file=$tmp;
						  last;}}}
	    if (! -e $file){ print 
				 "-*- WARN $sbrName no file=$file, (ignored)\n" if ($par{"verbose"});
			     next;}
	    push(@fileIn,$file);push(@chainIn,$chain);}close($fhin);}

				# --------------------------------------------------
				# watch chain if not provided in list!
    else {
	foreach $it (1..$#fileIn){
	    $chainIn[$it]="*"  if (! defined $chainIn[$it]);}}


                                # ------------------------------
    ($Lok,$msg)=                # determine input format
        &getFileFormatQuick($fileIn[1]);

    return(0,"*** ERROR $sbrName: could not determine format for file list ($fileIn[1])\n") 
        if (! $Lok || $msg =~ /ERROR/ || length($msg)>10 || length($msg)<3);
    $par{"formatIn"}=$msg;$par{"formatIn"}=~tr/[A-Z]/[a-z]/;
                                # case FSSP : you must have DSSP directory
    if ($par{"formatIn"} eq "fssp"){
        @tmp=split(/,/,$par{"dirDssp"});$Lok=0;
        foreach $dir (@tmp){
            if (-d $dir){$Lok=1;$par{"dirDssp"}=$dir;$par{"dirDssp"}.="/" if ($dir !~/\/$/);
                         last;}}
        return(0,"*** ERROR $sbrName: for FSSP you must provide the directory for the DSSP\n".
               "***       database by the argument 'dirDssp=/home/data/dssp'\n") 
            if (!$Lok);}
                                # ------------------------------
                                # input format supported?
    return(0,"*** ERROR $sbrName: input format '".$par{"formatIn"}.
	   "' (of files in $fileIn[1]) unsupported\n")
        if ($par{"formatIn"} !~ /^($okFormInOr)$/ &&
	    $par{"formatIn"} !~ /^phdrdb/i );
	    
                                # ------------------------------
    $#tmpx=0;                   # security: allow only files with same format as first
    foreach $file (@fileIn[2..$#fileIn]){
        ($Lok,$msg)=&getFileFormatQuick($file);
        next if ($msg !~/$par{"formatIn"}/i);
        next if (! defined $file);
        push(@tmpx,$file);}
    @fileIn=($fileIn[1],@tmpx);
                                # ------------------------------
                                # determine output format
                                # (1) not provided, but 2nd arg = file.WANTED_CONVERSION
    if (! defined $par{"formatOut"} || length($par{"formatOut"})<2 || $par{"formatOut"} eq "unk"){
        $fileOut=$ARGV[2];
        $par{"formatOut"}=$fileOut; $par{"formatOut"}=~s/^.*\.([^\.]+)$/$1/;
        $par{"formatOut"}=~tr/[A-Z]/[a-z]/;}
                                # ------------------------------
                                # output format supported?
    return(0,"*** ERROR $sbrName: output format '".$par{"formatOut"}."' unsupported\n")
        if ($par{"formatOut"} !~ /^($okFormOutOr)$/);

				# ------------------------------
				# final settings
    $Lok=			# standard settings
	&brIniSet();            return(0,"*** ERROR $sbrName: after lib-ut:brIniSet\n") if (! $Lok);

    $#fileOut=0;                # reset output files
    $#fileOutDef=0;             # standard output names

				# note: for single input file: name already assigned
    if (! defined $fileOut){
	$ct=0;
        foreach $fileIn (@fileIn){
            $formIn= $par{"formatIn"};  
				# special for Brookhaven:
	    if ($formIn eq "pdb" && $fileIn =~/\.brk/) {
		$extIn=".brk";}
	    else {
		$extIn= $par{"ext_$formIn"};}
            $formOut=$par{"formatOut"}; $extOut=$par{"ext_$formOut"};
	    $extOut= $par{"ext_dsspPhd"} if ($formIn=~/phdrdb/ && $formOut=~/^dssp/);

            $fileOut=$fileIn; 
				# purge dir
	    $fileOut=~s/^.*\///g;
				# replace extension
	    $fileOut=~s/(\.f(asta)?(mul)?|\.pirmul|$extIn(_.)?)$/$extOut/i;
				# add dirOut
	    $fileOut=$par{"dirOut"}.$fileOut;
	    ++$ct;
	    $fileOut=~s/$extOut$/$par{"ext_chain"}$chainIn[$ct]$extOut/
		if ($formIn =~/[hd]ssp/ && defined $chainIn[$ct] && $chainIn[$ct] =~/[A-Z0-9]/);
				# security
	    $fileOut.=".tmp"    if ($fileOut eq $fileIn);
            push(@fileOutDef,$fileOut);}}
    else{
	$formOut=$par{"formatOut"};
				# security
	$fileOut.=".tmp"        if (defined $fileIn && $fileOut eq $fileIn);
        push(@fileOutDef,$fileOut);}
				# correction for single: add file name
    $par{"fileOut"}=$fileOut    if ($#fileOutDef==1 && $par{"fileOut"} !~ $par{"ext_".$formOut});

				# correct settings for executables: add directories
    if (0){
	foreach $kwd (keys %par){
	    next if ($kwd !~/^exe/);
	    next if (-e $par{$kwd} || -l $par{$kwd});
	}
    }
    
    
				# ------------------------------
				# check errors
    $exclude=
	"exeFssp2daf,exeConvHssp2saf,exeConvertSeqBig"; # yy to exclude from error check
    
    ($Lok,$msg)=		# 
        &brIniErr($exclude);    return(0,"*** ERROR $sbrName: after lib-ut:brIniErr\n".$msg) if (! $Lok);  


                                # yy
                                # yy add syntax check
                                # yy

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
    $fhTrace="STDOUT"           if ($par{"debug"});

				# ------------------------------
				# write settings
				# ------------------------------
    if ($par{"verb2"}){
	$exclude="kwd,dir*,ext*"; # keyword not to write
	$fhloc="STDOUT";
	$fhloc=$fhTrace         if (! $par{"debug"});
	($Lok,$msg)=
	    &brIniWrt($exclude,$fhloc);
	                        return(&errSbrMsg("after lib-ut:brIniWrt",$msg,$SBR))  if (! $Lok); }

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
				# <<<<<<<<<<<<<<<<<<<<
				# normal
    $par{"dirSrc"}=             $par{"dirHome"}.   "lib/";   # all source except for binaries
    $par{"dirSrcMat"}=          $par{"dirSrc"}.    "mat/";   # general material
				                             # perl libraries
    $par{"dirPerl"}=            $par{"dirSrc"}.    "perl/" if (! defined $par{"dirPerl"});
    $par{"dirPerlScr"}=         $par{"dirPerl"}.   "scr/";   # perl scripts needed
    $par{"dirBin"}=             $par{"dirHome"}.   "bin/";   # FORTRAN binaries of programs needed

    if ($0=~/maxhom/){
	$par{"dirSrc"}=         $par{"dirHome"}.   "scr/";   # all source except for binaries
	$par{"dirSrcMat"}=      $par{"dirHome"}.   "mat/";   # general material
	$par{"dirPerl"}=        $par{"dirHome"}.   "scr/" if (! defined $par{"dirPerl"});
	$par{"dirPerlScr"}=     $par{"dirHome"}.   "scr/";   # perl scripts needed
    }
	
				# <<<<<<<<<<<<<<<<<<<<
				# for porting PHD asf
    if ($USERID !~/phd|pp|predictprotein/ &&
	$0=~/phd/){
	$par{"dirSrcMat"}=      "/nfs/data5/users/ppuser/server/pub/phd/". "mat/";   # general material
	$par{"dirPerl"}=        "/nfs/data5/users/ppuser/server/pub/phd/". "scr/";   # perl libraries
	$par{"dirPerlScr"}=     "/nfs/data5/users/ppuser/server/pub/phd/". "scr/";   # perl scripts needed
	$par{"dirBin"}=         "/nfs/data5/users/ppuser/server/pub/phd/". "bin/";   # FORTRAN binaries of programs needed
    }
    elsif ($USERID !~/phd|pp|predictprotein/ &&
	$0=~/prof/){
	$par{"dirSrcMat"}=      "/nfs/data5/users/ppuser/server/pub/prof/". "mat/";   # general material
	$par{"dirPerl"}=        "/nfs/data5/users/ppuser/server/pub/prof/". "scr/";   # perl libraries
	$par{"dirPerlScr"}=     "/nfs/data5/users/ppuser/server/pub/prof/". "scr/";   # perl scripts needed
	$par{"dirBin"}=         "/nfs/data5/users/ppuser/server/pub/prof/". "bin/";   # FORTRAN binaries of programs needed
    }

    $par{"dirPerlPack"}=        $par{"dirPerlScr"}."pack/";  # perl scripts needed
    $par{"dirConvertSeq"}=      $par{"dirBin"};

    $par{"dirOut"}=             ""; # directory for output files
    $par{"dirWork"}=            ""; # working directory
				# databases to search for files
    $par{"dirHssp"}=            "/home/rost/data/hssp/,/data/hssp/"; # dir for HSSP files
    $par{"dirDssp"}=            "/home/rost/data/dssp/,/data/dssp/"; # dir for DSSP files
    $par{"dirFssp"}=            "/home/rost/data/fssp/,/data/fssp/"; # dir for FSSP files
    $par{"dirSwiss"}=           "/home/rost/data/swissprot/current/,/data/swissprot/current/"; # 
				                                     # dir for SWISS-PROT files
				# additional user specified db
    $par{"dirMsf"}=             "unk";                               # dir for MSF files
				# additional user specified db
    $par{"dirMsf"}=             "unk";                               # dir for MSF files
    $par{"dirSaf"}=             "unk";                               # dir for SAF files
    $par{"dirDaf"}=             "unk";                               # dir for DAF files
    $par{"dirFastaMul"}=        "unk";                               # dir for FASTA files
    $par{"dirPirMul"}=          "unk";                               # dir for PIR files
    $par{"dirFasta"}=           "unk";
    $par{"dirGcg"}=             "unk";                               # dir for GCG files
                                # further on work
				# --------------------
				# files
    $par{"title"}=              "unk";         # output files will be called 'Pre-title.ext'
    $par{"titleTmp"}=           "COPF-tmp"."jobid";    # title used for temporary files
    
    $par{"fileOut"}=            "unk";

    $par{"fileOutTrace"}=       "COPF-TRACE-"."jobid".".tmp";  # file tracing some warnings and errors
    $par{"fileOutScreen"}=      "COPF-SCREEN-"."jobid".".tmp"; # file dumping the screen for convert_seq output

    $par{"fileHelpMan"}=        "unk"; # file with manual
    $par{"fileHelpOpt"}=        "unk"; # file with options
    $par{"fileHelpHints"}=      "unk"; # file with hints, note: also passed as par{scrHelpHints}
    $par{"fileHelpProblems"}=   "unk"; # file with known problems, also passed as par{scrHelpProblems}

				# file extensions
#    $par{"preOutTmp"}=          "Out-";
#    $par{"extOut"}=             ".tmp";

    $par{"ext_chain"}=          "_";   # for extraction of chain, output file will contain 'ext_chain'.chain
    $par{"ext_hssp"}=           ".hssp";
    $par{"ext_dssp"}=           ".dssp";
    $par{"ext_fssp"}=           ".fssp";
    $par{"ext_msf"}=            ".msf";

    $par{"ext_pdb"}=            ".pdb";

    $par{"ext_daf"}=            ".daf";
    $par{"ext_saf"}=            ".saf";
    $par{"ext_fasta"}=          ".f";
    $par{"ext_fastamul"}=       ".fasta";
    $par{"ext_pirmul"}=         ".pir";

    $par{"ext_pir"}=            ".pir";
    $par{"ext_fasta"}=          ".f";
    $par{"ext_swiss"}=          ""; # no extension, simply following structure 'id_species'
    $par{"ext_gcg"}=            ".gcg";
    
    $par{"ext_phdrdbboth"}=     ".rdbPhd";
    $par{"ext_dsspPhd"}=        ".dsspPhd";

    $par{"pre_id"}=             0; # additional information added to protein name,
				   #    e.g. 'pre_id=hssp|1ppt' 

				# file handles
    $fhin=                      "FHIN";
    $fhTrace=                   "FHTRACE";
                                # --------------------
                                # job control
    $par{"jobid"}=              "jobid"; # unique job identifier (set to $$ if not defined)
    $par{"debug"}=              0; # if 1 : keep (most) temporary files
    $par{"verbose"}=$Lverb=     1; # blabla on screen
    $par{"verb2"}=$Lverb2=      0; # more verbose blabla
				# --------------------
				# parameters
    $par{"doHsspStrip"}=        0; # also write the HSSP strip file
    $par{"doExpand"}=           0; # expand insertions in HSSP sequences?
    $par{"doCompress"}=         1; # delete insertions in guide sequence for conversion to HSSP?
    $par{"doSplitChain"}=       0; # split HSSP|DSSP|PDB files -> FASTA into chains
    $par{"frag"}=               0; # convert fragments, only?   Use the following notation:
                                   # '1-55,77-99' to get two fragments one from 1-55, the other from 77-99
                                   # NOTE: output files will be named xyz_1_55 and xyz_77_99
    $par{"extr"}=               0; # extract particular protein from alignment format? 
                                   # provide the number of the protein in the alignment for which you want
                                   # the sequence written into the output file
    $par{"doAgain"}=            1; # if 1: existing files overwritten!

    $par{"fileInclProt"}=       0; # contains ids to include, syntax PDBids + chain 1pdbC (or h|f|dssp files)
                                   # note: used only for FSSP->DAF
#    $par{"fileMatGcg"}=         $par{"dirSrcMat"}.    "Maxhom_GCG.metric";  # MAXHOM-GCG matrix
    $par{"fileMatGcg"}=         $par{"dirSrcMat"}.    "Maxhom_McLachlan.metric";  # MAXHOM-GCG matrix
#    $par{"fileMatGcg"}=         $par{"dirSrcMat"}.    "Maxhom_Blosum.metric";  # MAXHOM-GCG matrix
                                # needed for conversion into HSSP format!
				# --------------------
				# executables
    $par{"exeConvertSeq"}=      $par{"dirConvertSeq"}."convert_seq".".".$ARCH;
    $par{"exeConvertSeqBig"}=   $par{"dirConvertSeq"}."convert_seq_big".".".$ARCH;
#    $par{"exeFssp2daf"}=        $par{"dirPerlPack"}. "conv_fssp2daf_lh.pm";
    $par{"exeFssp2daf"}=        $par{"dirPerlScr"}.  "conv_fssp2daf_lh.pl";
    $par{"exeConvHssp2saf"}=    $par{"dirPerlPack"}. "conv_hssp2saf.pm";
#    $par{"exeConvHssp2saf"}=    $par{"dirPerlScr"}.  "conv_hssp2saf.pl";
}				# end of iniDef

#===============================================================================
sub iniHelpLoc {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iniHelpLoc                  initialising some variables
#-------------------------------------------------------------------------------
				# standard help
    $tmp=0;
    $tmp=$par{"packName"}       if (defined $par{"packName"});
    $tmp=$0                     if (! defined $tmp || ! $tmp); 
    $tmp=~s/^\.\///             if ($tmp=~/^\.\//);$tmpSource=$tmp;
    %tmp=('sourceFile', $tmp, 'scrName',$scrName, 'scrIn',$scrIn, 'scrGoal', $scrGoal, 'scrNarg',$scrNarg,
	  'scrHelpTxt', $scrHelpTxt);
    $tmp{"scrNameFull"}=$0;

				# missing stuff
    $tmp{"s_k_i_p"}=         "problems,manual,hints";

				# special help
    $tmp{"scrAddHelp"}=      "";
    $tmp{"special"}=         "expand,compress,nocompress,list,split,";
    $tmp{"special"}=         "skip,";
    $tmp{"special"}.=        "help saf-syn,";
    $tmp{"special"}.=        "big,";
        
    $tmp{"expand"}=          "OR doExpand=1,   do expand HSSP deletions (conversion to MSF|SAF)";
    $tmp{"compress"}=        "OR doCompress=1, do delete insertions in MASTER (conversion to HSSP)";
    $tmp{"nocompress"}=      "OR doCompress=0, do NOT delete insertions in MASTER (conversion to HSSP)";
    $tmp{"list"}=            "OR isList=1,     input file is list of files (extension *.list recognised!)";
    $tmp{"split"}=           "OR doSplitChain=1 split DSSP chains when converting to FASTA!";
    $tmp{"skip"}=            "OR doAgain=0,    no action if output file existing!";
    $tmp{"big"}=             "                 use BIG binaries for *->hssp!";

    undef %tmp2;
    foreach $form (@okFormIn,@okFormOut){
        next if (defined $tmp2{$form});$tmp2{$form}=1;$formTmp=$form;$formTmp=~tr/[a-z]/[A-Z]/;
        $tmp{"special"}.=    "help $form".",";
        $tmp{"scrAddHelp"}.=
            "help ".$form." " x (9-length($form)).": ".$formTmp." " x (10 -length($form))."format specific info\n";}
    $tmp{"special"}=~s/,*$//g;
    $tmp{"scrAddHelp"}.=    "help saf-syn  : specification of SAF format\n";
#    $tmp{"scrAddHelp"}= "help zzz      : all info on zzz format\n";
                                # ------------------------------
                                # alignment IN / OUT
    $tmp{"help hssp"}=       "DES: HSSP = Homology derived Secondary Structure of Proteins format (ali, IN | OUT)\n";
    $tmp{"help hssp"}.=      "OUT: MSF|DAF|SAF|FASTAmul|PIRmul|FASTA|PIR \n";
    $tmp{"help hssp"}.=      "OPT:     The following options are available\n";
    $tmp{"help hssp"}.=      "OPT: \n";
    $tmp{"help hssp"}.=      "OPT: expand    -> expand the deletion list when writing\n";
    $tmp{"help hssp"}.=      "OPT:                 * RESTRICT: for MSF and SAF output, only!!\n";
    $tmp{"help hssp"}.=      "OPT: extr=N    -> extract sequence of protein N\n";
    $tmp{"help hssp"}.=      "OPT:                 * RESTRICT: for single sequence output, only!\n";
    $tmp{"help hssp"}.=      "OPT:              default for HSSP->PIR/FASTA:  extract guide seq (N=1)!\n";
    $tmp{"help hssp"}.=      "OPT: frag=n-m  -> selects fragment from residues N-M\n";
    $tmp{"help hssp"}.=      "OPT:              type 'help frag' for more information on this one\n";
    $tmp{"help hssp"}.=      "OPT:                 * RESTRICT: NOT for DAF formatted output\n";
    $tmp{"help hssp"}.=      "OPT: \n";
    $tmp{"help hssp"}.=      "OPT: chain=A,B -> selects only the chains A and B\n";
    $tmp{"help hssp"}.=      "OPT:              NOTE: pass the identifier for chain C as \n";
    $tmp{"help hssp"}.=      "OPT:    file.hssp_C\n";
    $tmp{"help hssp"}.=      "OPT:                    providing a chain disables the option 'frag=N-M'\n";
#    $tmp{"help hssp"}.=      "OPT: split     -> split HSSP|DSSP|PDB files -> FASTA into chains\n";


    $tmp{"help pdb"}=        "DES: PDB\n";
    $tmp{"help pdb"}.=       "OUT: FASTAmul|FASTA|PIR|PIRmul|GCG \n";
    $tmp{"help pdb"}.=       "OPT:     The following options are available\n";
    $tmp{"help pdb"}.=       "OPT: chain=A,B -> selects only the chains A and B\n";
    $tmp{"help pdb"}.=       "OPT:              NOTE: pass the identifier for chain C as \n";
    $tmp{"help pdb"}.=       "OPT:              file.pdb_C\n";
    $tmp{"help pdb"}.=       "OPT:              providing a chain disables the option 'frag=N-M'\n";
    $tmp{"help pdb"}.=       "OPT: frag=n-m  -> selects fragment from residues N-M\n";
    $tmp{"help pdb"}.=       "OPT:              type 'help frag' for more information on this one\n";
    $tmp{"help pdb"}.=       "OPT:                 * RESTRICT: NOT for DAF formatted output\n";
#    $tmp{"help pdb"}.=       "OPT: split     -> split HSSP|DSSP|PDB files -> FASTA into chains\n";


    $tmp{"help msf"}=        "DES: MSF = Multiple Sequence Format                                 (ali, IN | OUT)\n";
    $tmp{"help msf"}.=       "OUT: HSSP|SAF|FASTAmul|FASTA \n";
    $tmp{"help msf"}.=       "OPT:     The following options are available\n";
    $tmp{"help msf"}.=       "OPT: compress  -> delete insertions in GUIDE sequence\n";
    $tmp{"help msf"}.=       "OPT:                 * RESTRICT: for HSSP output, only!!\n";
    $tmp{"help msf"}.=       "OPT: extr=N    -> extract sequence of protein N\n";
    $tmp{"help msf"}.=       "OPT:                 * RESTRICT: for single sequence output, only!\n";
    $tmp{"help msf"}.=       "OPT: frag=n-m  -> selects fragment from residues N-M\n";
    $tmp{"help msf"}.=       "OPT:              type 'help frag' for more information on this one\n";
    $tmp{"help msf"}.=       "OPT:                 * RESTRICT: NOT for DAF formatted output\n";


    $tmp{"help saf"}=        "DES: SAF = Simple Alignment Format                                 (ali, IN | OUT)\n";
    $tmp{"help saf"}.=       "DES:     resembles MSF, but less restrictive\n";
    $tmp{"help saf"}.=       "OUT: HSSP|MSF|FASTAmul|FASTA|PIRmul|PIR\n";
    $tmp{"help saf"}.=       "OPT:     The following options are available\n";
    $tmp{"help saf"}.=       "OPT: compress  -> delete insertions in GUIDE sequence\n";
    $tmp{"help saf"}.=       "OPT:                 * RESTRICT: for HSSP output, only!!\n";
    $tmp{"help saf"}.=       "OPT: extr=p1-p2,p3 -> extract sequence of proteins\n";
    $tmp{"help saf"}.=       "OPT:              any list ok, e.g., '1-5,7,19-20,35'\n";
    $tmp{"help saf"}.=       "OPT: frag=n-m  -> selects fragment from residues N-M\n";
    $tmp{"help saf"}.=       "OPT:              type 'help frag' for more information on this one\n";
    $tmp{"help saf"}.=       "OPT:                 * RESTRICT: NOT for DAF formatted output\n";
    $tmp{"help saf"}.=       " \n";
    $tmp{"help saf"}.=       "     To learn the detailed specifications about the SAF format , please typ:\n";
    $tmp{"help saf"}.=       "$tmpSource help saf-syn\n";
    $tmp{"help saf"}.=       " \n";

    $tmp{"help saf-syn"}=    "\n";
    $tmp{"help saf-syn"}.=   "============================================================\n";
    $tmp{"help saf-syn"}.=   "Specification of SAF (Simple Alignment Format)\n";
    $tmp{"help saf-syn"}.=   "============================================================\n";
    $tmp{"help saf-syn"}.=   "\n";
    $tmp{"help saf-syn"}.=   "NOTE: in principle SAF is like MSF ommitting the header, and\n";
    $tmp{"help saf-syn"}.=   "      not requiring the MSF stringency.\n";
    $tmp{"help saf-syn"}.=   "NEW:  Additional features are:\n";
    $tmp{"help saf-syn"}.=   "    * comment lines can be inserted anywhere (by '#')\n";
    $tmp{"help saf-syn"}.=   "    * unaligned regions do not have to be filled in\n";
    $tmp{"help saf-syn"}.=   "\n";
    $tmp{"help saf-syn"}.=   "------------------------------\n";
    $tmp{"help saf-syn"}.=   "EACH ROW\n";
    $tmp{"help saf-syn"}.=   "------------\n";
    $tmp{"help saf-syn"}.=   "two columns: 1. name (protein identifier, shorter than 15 characters)\n";
    $tmp{"help saf-syn"}.=   "             2. one-letter sequence (any number of characters)\n";
    $tmp{"help saf-syn"}.=   "                insertions: dots (.), or hyphens (-)\n";
    $tmp{"help saf-syn"}.=   "------------\n";
    $tmp{"help saf-syn"}.=   "EACH BLOCK\n";
    $tmp{"help saf-syn"}.=   "------------\n";
    $tmp{"help saf-syn"}.=   "rows:        1. row must be guide sequence (i.e. always the same name,\n";
    $tmp{"help saf-syn"}.=   "                this implies, in particular, that this sequence shold\n";
    $tmp{"help saf-syn"}.=   "                not have blanks\n";
    $tmp{"help saf-syn"}.=   "             2, ..., n the aligned sequences\n";
    $tmp{"help saf-syn"}.=   "  comments:  *  rows beginning with a '#' will be ignored\n";
    $tmp{"help saf-syn"}.=   "             *  rows containing only blanks, dots, numbers will also be ignored\n";
    $tmp{"help saf-syn"}.=   "                (in particular numbering is possible)\n";
    $tmp{"help saf-syn"}.=   "\n";
    $tmp{"help saf-syn"}.=   "unspecified: *  order of sequences 2-n can differ between the blocks,\n";
    $tmp{"help saf-syn"}.=   "             *  not all 2-n sequences have to occur in each block,\n";
    $tmp{"help saf-syn"}.=   "             *  \n";
    $tmp{"help saf-syn"}.=   "             *  BUT: whenever a sequence is present, it should have\n";
    $tmp{"help saf-syn"}.=   "             *       dots for insertions rather than blanks\n";
    $tmp{"help saf-syn"}.=   "             *  \n";
    $tmp{"help saf-syn"}.=   "------------\n";
    $tmp{"help saf-syn"}.=   "NOTE\n";
    $tmp{"help saf-syn"}.=   "------------\n";
    $tmp{"help saf-syn"}.=   "             The 'freedom' of this format has various consequences:\n";
    $tmp{"help saf-syn"}.=   "             *  identical names in different rows of the same block\n";
    $tmp{"help saf-syn"}.=   "                are not identified.  Instead, whenever this applies,\n";
    $tmp{"help saf-syn"}.=   "                the second, (third, ..) sequences are ignored.\n";
    $tmp{"help saf-syn"}.=   "                e.g.   \n";
    $tmp{"help saf-syn"}.=   "                   t2_11751 EFQEDQENVN \n";
    $tmp{"help saf-syn"}.=   "                   name-1   ...EDQENvk\n";
    $tmp{"help saf-syn"}.=   "                   name-1   GGAPTLPETL\n";
    $tmp{"help saf-syn"}.=   "                will be interpreted as:\n";
    $tmp{"help saf-syn"}.=   "                   t2_11751 EFQEDQENVN \n";
    $tmp{"help saf-syn"}.=   "                   name-1   ...EDQENvk\n";
    $tmp{"help saf-syn"}.=   "                wheras:\n";
    $tmp{"help saf-syn"}.=   "                   t2_11751 EFQEDQENVN \n";
    $tmp{"help saf-syn"}.=   "                   name-1   ...EDQENvk\n";
    $tmp{"help saf-syn"}.=   "                   name_1   GGAPTLPETL\n";
    $tmp{"help saf-syn"}.=   "                has three different names.\n";
    $tmp{"help saf-syn"}.=   "------------\n";
    $tmp{"help saf-syn"}.=   "EXAMPLE 1\n";
    $tmp{"help saf-syn"}.=   "------------\n";
    $tmp{"help saf-syn"}.=   "  t2_11751 EFQEDQENVN PEKAAPAQQP RTRAGLAVLR AGNSRGAGGA PTLPETLNVA\n";
    $tmp{"help saf-syn"}.=   "  name_1   EFQEDQENVN PEKAAPAQQP RTRAGLAVLR AGNSRGAGGA PTLPETLNVA\n";
    $tmp{"help saf-syn"}.=   "  name_2   ...EDQENvk PEKAAPAQQP RTRAGLAVLR AGNSRG.... ...PETLNV.\n";
    $tmp{"help saf-syn"}.=   "  name_22  ...EDQENvk PEKAAPAQQP RTRAGLAVLR AGNSRG.... ...PETLNV.\n";
    $tmp{"help saf-syn"}.=   "    t2_11751 GGAPTLPETL NVAGGAPTLP ETLNVAGGAP TLPETLNV\n";
    $tmp{"help saf-syn"}.=   "  name_1   GGAPTLPETL NVAGGAPTLP ETLNVAGGAP TLPETLNV\n";
    $tmp{"help saf-syn"}.=   "\n";
    $tmp{"help saf-syn"}.=   "------------\n";
    $tmp{"help saf-syn"}.=   "EXAMPLE 2\n";
    $tmp{"help saf-syn"}.=   "------------\n";
    $tmp{"help saf-syn"}.=   "                      10         20         30         40         \n";
    $tmp{"help saf-syn"}.=   "  t2_11751 EFQEDQENVN PEKAAPAQQP RTRAGLAVLR AGNSRGAGGA PTLPETLNVA\n";
    $tmp{"help saf-syn"}.=   "  name_1   EFQEDQENVN PEKAAPAQQP RTRAGLAVLR AGNSRGAGGA PTLPETLNVA\n";
    $tmp{"help saf-syn"}.=   "  name_2   ...EDQENvk PEKAAPAQQP RTRAGLAVLR AGNSRG.... ...PETLNV.\n";
    $tmp{"help saf-syn"}.=   "  name_22  ...EDQENvk PEKAAPAQQP RTRAGLAVLR AGNSRG.... ...PETLNV.\n";
    $tmp{"help saf-syn"}.=   "             50         60         70         80         90\n";
    $tmp{"help saf-syn"}.=   "    t2_11751 GGAPTLPETL NVAGGAPTLP ETLNVAGGAP TLPETLNV\n";
    $tmp{"help saf-syn"}.=   "  name_22  .......... .......... .......... ........\n";
    $tmp{"help saf-syn"}.=   "  name_1   GGAPTLPETL NVAGGAPTLP ETLNVAGGAP TLPETLNV\n";
    $tmp{"help saf-syn"}.=   "  name_2   .......... NVAGGAPTLP \n";
    $tmp{"help saf-syn"}.=   "  \n";
    $tmp{"help saf-syn"}.=   "  enough?\n";
    $tmp{"help saf-syn"}.=   "  \n";


    $tmp{"help fastamul"}=   "DES: FASTAmul = Multiple FASTA format                               (ali, IN | OUT)\n";
    $tmp{"help fastamul"}.=  "DES:     Simply many proteins each in FASTA format.\n";
    $tmp{"help fastamul"}.=  "DES:           \n";
    $tmp{"help fastamul"}.=  "DES:     ***********************************************************\n";
    $tmp{"help fastamul"}.=  "DES:     NOTE: for a correct conversion into alignment formats,  all\n";
    $tmp{"help fastamul"}.=  "DES:           sequences have to be aligned already.   This implies:\n";
    $tmp{"help fastamul"}.=  "DES:           that ALL  sequences have to have IDENTICAL  lengths!!\n";
    $tmp{"help fastamul"}.=  "DES:     ***********************************************************\n";
    $tmp{"help fastamul"}.=  "DES:           \n";
    $tmp{"help fastamul"}.=  "OUT: HSSP|MSF|SAF|FASTA|PIRmul|PIR \n";
    $tmp{"help fastamul"}.=  "OPT:     The following options are available\n";
    $tmp{"help fastamul"}.=  "OPT: compress  -> delete insertions in GUIDE sequence\n";
    $tmp{"help fastamul"}.=  "OPT:                 * RESTRICT: for HSSP output, only!!\n";
    $tmp{"help fastamul"}.=  "OPT: extr=N    -> extract sequence of protein N\n";
    $tmp{"help fastamul"}.=  "OPT:                 * RESTRICT: for single sequence output, only!\n";
    $tmp{"help fastamul"}.=  "OPT: frag=n-m  -> selects fragment from residues N-M\n";
    $tmp{"help fastamul"}.=  "OPT:              type 'help frag' for more information on this one\n";
    $tmp{"help fastamul"}.=  "OPT:                 * RESTRICT: NOT for DAF formatted output\n";

    $tmp{"help pirmul"}=     "DES: PIRmul = Multiple PIR format                                    (ali, IN | OUT)\n";
    $tmp{"help pirmul"}.=    "DES:     Simply many proteins each in PIR format.\n";
    $tmp{"help pirmul"}.=    "DES:           \n";
    $tmp{"help pirmul"}.=    "OUT: FASTAmul|FASTA \n";
    $tmp{"help pirmul"}.=    "OPT:     The following options are available\n";
    $tmp{"help pirmul"}.=    "OPT: extr=N    -> extract sequence of protein N\n";
    $tmp{"help pirmul"}.=    "OPT:                 * RESTRICT: for single sequence output (FASTA), only!\n";
    $tmp{"help pirmul"}.=    "OPT: frag=n-m  -> selects fragment from residues N-M\n";
    $tmp{"help pirmul"}.=    "OPT:              type 'help frag' for more information on this one\n";

                                # ------------------------------
                                # alignment IN
    $tmp{"help fssp"}=       "DES: FSSP = Definition of Secondary Structure for Proteins format   (ali, IN)\n";
    $tmp{"help fssp"}.=      "OUT: DAF\n";
    $tmp{"help fssp"}.=      "OPT:     The following options are available\n";
    $tmp{"help fssp"}.=      "OPT: frag=n-m  -> selects fragment from residues N-M\n";
    $tmp{"help fssp"}.=      "OPT:              type 'help frag' for more information on this one\n";
    $tmp{"help fssp"}.=      "OPT:                 * RESTRICT: NOT for DAF formatted output\n";

                                # ------------------------------
                                # alignment OUT
    $tmp{"help daf"}=        "DES: DAF = Dirty Alignment Format                                   (ali, OUT)\n";
    $tmp{"help daf"}.=       "OPT:     No options are available (output only HSSP|FSSP -> DAF)\n";

                                # ------------------------------
                                # sequence IN / OUT
    $tmp{"help dssp"}=       "DES: DSSP = Definition of Secondary Structure for Proteins format   (seq, IN | OUT)\n";
    $tmp{"help dssp"}.=      "OUT: FASTA|PIR|MSF|SAF\n";
    $tmp{"help dssp"}.=      "OPT:     The following options are available\n";
    $tmp{"help dssp"}.=      "OPT: frag=n-m  -> selects fragment from residues N-M\n";
    $tmp{"help dssp"}.=      "OPT:              type 'help frag' for more information on this one\n";
    $tmp{"help dssp"}.=      "OPT:              NOTE: if you extract chains,  these numbers refer\n";
    $tmp{"help dssp"}.=      "OPT:                    to the position in the extracted chain!!\n";    
    $tmp{"help dssp"}.=      "OPT: chain=A,B -> selects only the chains A and B\n";
    $tmp{"help dssp"}.=      "OPT:              NOTE: pass the identifier for chain C as \n";
    $tmp{"help dssp"}.=      "OPT:              file.dssp_C\n";
    $tmp{"help dssp"}.=      "OPT:                    providing a chain disables the option 'frag=N-M'\n";
    $tmp{"help dssp"}.=      "OPT: split     -> split HSSP|DSSP|PDB files -> FASTA into chains\n";


    $tmp{"help fasta"}=      "DES: FASTA format                                                   (seq, IN | OUT)\n";
    $tmp{"help fasta"}.=     "OUT: PIR|GCG\n";
    $tmp{"help fasta"}.=     "OPT:     The following options are available\n";
    $tmp{"help fasta"}.=     "OPT: frag=n-m  -> selects fragment from residues N-M\n";
    $tmp{"help fasta"}.=     "OPT:              type 'help frag' for more information on this one\n";
    $tmp{"help fasta"}.=     "OPT:                 * RESTRICT: NOT for DAF formatted output\n";

    $tmp{"help pir"}=        "DES: PIR = Protein Identification Resource format                   (seq, IN | OUT)\n";
    $tmp{"help pir"}.=       "OUT: FASTA|GCG \n";
    $tmp{"help pir"}.=       "OPT:     The following options are available\n";
    $tmp{"help pir"}.=       "OPT: frag=n-m  -> selects fragment from residues N-M\n";
    $tmp{"help pir"}.=       "OPT:              type 'help frag' for more information on this one\n";
    $tmp{"help pir"}.=       "OPT:                 * RESTRICT: NOT for DAF formatted output\n";

    $tmp{"help gcg"}=        "DES: GCG format                                                     (seq, IN | OUT)\n";
    $tmp{"help gcg"}.=       "OUT: PIR|FASTA|FASTAmul|PIRmul \n";
    $tmp{"help gcg"}.=       "OPT:     The following options are available\n";
    $tmp{"help gcg"}.=       "OPT: frag=n-m  -> selects fragment from residues N-M\n";
    $tmp{"help gcg"}.=       "OPT:              type 'help frag' for more information on this one\n";
    $tmp{"help gcg"}.=       "OPT:                 * RESTRICT: NOT for DAF formatted output\n";
                                # ------------------------------
                                # sequence IN
    $tmp{"help swiss"}=      "DES: SWISS = Homology derived Secondary Structure of Proteins format (alignment)\n";
    $tmp{"help swiss"}.=     "OUT: MSF|DAF|SAF|FASTAmul|PIRmul|PIR|FASTA|GCG \n";
    $tmp{"help swiss"}.=     "OPT:     The following options are available\n";
    $tmp{"help swiss"}.=     "OPT: expand    -> expand the deletion list when writing\n";
    $tmp{"help swiss"}.=     "OPT:                 * RESTRICT: for MSF output, only!!\n";
    $tmp{"help swiss"}.=     "OPT: extr=N    -> extract sequence of protein N\n";
    $tmp{"help swiss"}.=     "OPT:                 * RESTRICT: for single sequence output, only!\n";
    $tmp{"help swiss"}.=     "OPT: frag=n-m  -> selects fragment from residues N-M\n";
    $tmp{"help swiss"}.=     "OPT:              type 'help frag' for more information on this one\n";
    $tmp{"help swiss"}.=     "OPT:                 * RESTRICT: NOT for DAF formatted output\n";

    $tmp{"help phdrdb"}=     "DES: PHDrdb = PHD.rdb format                                        (seq, IN)\n";
    $tmp{"help phdrdb"}.=    "OUT: DSSP\n";
    $tmp{"help phdrdb"}.=    "OUT:     Converts PHD rdb file into DSSP formatted file.\n";
    $tmp{"help phdrdb"}.=    "OUT:     NOTE: you have to run PHD with the default or the\n";
    $tmp{"help phdrdb"}.=    "OUT:           option 'both' on the command line\n";
    $tmp{"help phdrdb"}.=    "OPT: \n";

    $tmp{"help phdrdb"}.=    "OUT: MSF|PIR|FASTA|GCG|FASTAmul|PIRmul \n";
    $tmp{"help phdrdb"}.=    "OPT:     NOT IMPLEMENTED, yet!\n";
    $tmp{"help phdrdb"}.=    "OPT: \n";

    $tmp{"help phdrdb"}.=    "OUT: MSF|PIR|FASTA|GCG|FASTAmul|PIRmul \n";
    $tmp{"help phdrdb"}.=    "OPT:     The following options are available\n";
    $tmp{"help phdrdb"}.=    "OPT: frag=n-m  -> selects fragment from residues N-M\n";
    $tmp{"help phdrdb"}.=    "OPT:              type 'help frag' for more information on this one\n";
    $tmp{"help phdrdb"}.=    "OPT:                 * RESTRICT: NOT for DAF formatted output\n";
    $tmp{"help phdrdb"}.=    "OPT: mergeAli  -> provide a valid HSSP file to merge the PHD output\n";
    $tmp{"help phdrdb"}.=    "OPT:              into that one.\n";
    $tmp{"help phdrdb"}.=    "OPT: \n";


#                            "------------------------------------------------------------\n";
    $tmp{"scrHelpProblems"}= "Maximal protein length:\n";
    $tmp{"scrHelpProblems"}.="   $scrName bases upon a  FORTRAN  program by Reinhard Schneider\n";
    $tmp{"scrHelpProblems"}.="   LION Heidelberg), and Ulrike Goebel (now Jena). That pro-\n";
    $tmp{"scrHelpProblems"}.="   gram restricts memory space by crashing  with proteins of\n";
    $tmp{"scrHelpProblems"}.="   more than 6,000 residues.   Recompile the FORTRAN program\n";
    $tmp{"scrHelpProblems"}.="   to change this feature.\n";
    $tmp{"scrHelpProblems"}.="   \n";
    $tmp{"scrHelpProblems"}.="   \n";
    $tmp{"scrHelpProblems"}.=" \n";
    $tmp{"scrHelpProblems"}.=" \n";
}				# end of iniHelpLoc



#==============================================================================
# library collected (begin) lll
#==============================================================================

#===============================================================================
sub amino_acid_convert_3_to_1 {
    local($three_letter_acid) = @_ ;
    local($sbrName3);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   amino_acid_convert_3_to_1   converts 3 letter alphabet to single letter alphabet
#       in:                     $three_letter_acid
#       out:                    1|0,msg,$one_letter_acid
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName3="amino_acid_convert_3_to_1";
    return(0,"no input to $sbrName3") if (! defined $three_letter_acid);
				# initialise translation table
    &amino_acid_convert_3_to_1_ini()  
	if (! defined %amino_acid_convert_3_to_1);
				# not found
    return(0,"no conversion for acid=$three_letter_acid!","unk") 
	if (! defined $amino_acid_convert_3_to_1{$three_letter_acid});
				# ok
    return(1,"ok",$amino_acid_convert_3_to_1{$three_letter_acid});
}				# end of amino_acid_convert_3_to_1

#===============================================================================
sub amino_acid_convert_3_to_1_ini {
#-------------------------------------------------------------------------------
#   amino_acid_convert_3_to_1_ini returns GLOBAL array with 3 letter acid -> 1 letter
#       out GLOBAL:             %amino_acid_convert_3_to_1
#-------------------------------------------------------------------------------
    %amino_acid_convert_3_to_1=
	(
				# amino
	 'ALA',"A",
	 'ARG',"R",
	 'ASN',"N",
	 'ASP',"D",
	 'CYS',"C",
	 'GLN',"Q",
	 'GLU',"E",
	 'GLY',"G",
	 'HIS',"H",
	 'ILE',"I",
	 'LEU',"L",
	 'LYS',"K",
	 'MET',"M",
	 'PHE',"F",
	 'PRO',"P",
	 'SER',"S",
	 'THR',"T",
	 'TRP',"W",
	 'TYR',"Y",
	 'VAL',"V",
				# nucleic
	 'A',  "A",
	 'C',  "C",
	 'G',  "G",
	 'T',  "T",
	 );
}				# end of amino_acid_convert3_to_1

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
	    $tmp{$kwd}=1;}}
    $msgHere="";
				# ------------------------------
    foreach $kwd (@kwd){	# file existence
	next if ($kwd =~ /^file(Out|Help|Def)/i);
	next if (defined $tmp{$kwd});
	if   ($kwd=~/^exe/) { 
	    $msgHere.="*** ERROR executable ($kwd) '".$par{$kwd}."' missing!\n"
		if (! -e $par{$kwd} && ! -l $par{$kwd});
	    $msgHere.="*** ERROR executable ($kwd) '".$par{$kwd}."' not executable!\n".
                "***       do the following \t 'chmod +x ".$par{$kwd}."'\n"
                    if (-e $par{$kwd} && ! -x $par{$kwd});}
	elsif($kwd=~/^file/){
	    next if ($par{$kwd} eq "unk" || length($par{$kwd})==0 || !$par{$kwd});
	    $msgHere.="*** ERROR file ($kwd) '".$par{$kwd}."' missing!\n"
		if (! -e $par{$kwd} && ! -l $par{$kwd});} # 
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
				# is it file?
               if ((-e $arg && ! -d $arg) ||
		   -l $arg){
                   $Lok=1;
		   push(@fileIn,$arg);}
               if (! $Lok && length($par{"dirIn"})>1 && -e $par{"dirIn"}.$arg){
                   $Lok=1;push(@fileIn,$par{"dirIn"}.$arg);}
				# any of the paras defined ?
               if (! $Lok && $arg=~/=/){
                   foreach $kwd (@tmp){
                       if ($arg=~/^$kwd=(.+)$/){$Lok=1;$par{$kwd}=$1;
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
	    print "--- input to $sbrName kwd=$kwd, val=",$tmp{$kwd},",\n";}
    }
    @scrTask=
        ("--- Task:  ".$tmp{"scrGoal"},
         "--- ",
         "--- Input: ".$tmp{"scrIn"},
#         "---                 i.e. requires at least ".$tmp{"scrNarg"}.
#	      " command line argument(s)",
         "--- ");
    $tmp{"scrNameFull"}=$0      if (! defined $tmp{"scrNameFull"});
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
		$tmp=" "; $tmp=$tmp{$kwd} if (defined $tmp{$kwd});
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
                    printf "--- %-20s = %-s\n",$kwd,$par{$kwd};}
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
		    if (defined $def{$kwd,"expl"}){
			$def{$kwd,"expl"}=~s/\n/\n---                        /g;
			push(@expLoc,$def{$kwd,"expl"});}
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
		if (defined $def{$kwd}){
		    $def{$kwd}=~s/\n[\t\s]*/\n---                        /g;
		    push(@expLoc,$def{$kwd});}
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
                    printf "--- %-20s = %-s\n",$kwd,$par{$kwd};}
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
	    $tmp{$kwd}=$2 if (defined $2);}
				# end if only '------' line
        elsif ($Lis && defined $tmp{$kwd} && $_=~/^[\s\t]+\# ?\-+/){
            $Lis=0;}
				# add to previous (only if it had an explanation)
        elsif ($Lis && defined $tmp{$kwd} && $_=~/^[\s\t]*\# (.*)$/){
            $tmp{$kwd}.="\n".$1;}
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
	    $kwd=$1; push(@kwd,$kwd); $defaults{$kwd}=$2; 
            $defaults{$kwd,"expl"}=$3 if (defined $3 && length($3)>1); $Lis=1;}
				# (2) case 'kwd  val'
	elsif ($line=~/^([^\s\t]+)[\s\t]+([^\s\t]+)[\s\t]*$/){
	    $kwd=$1; $defaults{$kwd}=$2; $Lis=1; $defaults{$kwd,"expl"}=""; }
				# (3) case '          # ----'
	elsif ($Lis && $line =~ /^\#\s*[\-\=\_\.\*]+/){
	    $Lis=0;}
	elsif ($Lis && defined $defaults{$kwd,"expl"} && $line =~ /^\#\s*(.*)$/){
	    $defaults{$kwd,"expl"}.="\n".$1;}}
    close($fhin);
				# ------------------------------
    foreach $kwd (@kwd){        # fill in wild cards
        $defaults{$kwd}=$ARCH if ($defaults{$kwd}=~/ARCH/);}
                                # ------------------------------
    foreach $kwd (@kwd){        # complete it
	$defaults{$kwd,"expl"}=" " if (! defined $defaults{$kwd,"expl"});}
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
	    $par{$kwd}=$defaults{$kwd};}}
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
        if (defined $kwd && length($kwd)>=1 && defined $par{$kwd}){
            push(@tmp,$kwd);}
	else { 
	    print "-*- WARN $sbrName: for kwd '$kwd', par{kwd} not defined!\n";}}
    @kwd=@tmp;
				# jobId
    $par{"jobid"}=$$ 
	if (! defined $par{"jobid"} || $par{"jobid"} eq 'jobid' || length($par{"jobid"})<1);
				# ------------------------------
				# add jobid
    foreach $kwd (@kwd){
	$par{$kwd}=~s/jobid/$par{"jobid"}/;}
                                # ------------------------------
                                # WATCH it for file lists: add dirIn
    if (defined $par{"dirIn"} && $par{"dirIn"} ne "unk" && $par{"dirIn"} ne "local" 
        && length($par{"dirIn"})>1){
	foreach $fileIn(@fileIn){
	    $fileIn=$par{"dirIn"}.$fileIn if (! -e $fileIn);
	    if (! -e $fileIn){ print 
				   "*** $sbrName: no fileIn=$fileIn, dir=",$par{"dirIn"},",\n";
			       return(0);}}} 
    $#kwdFileOut=0;		# ------------------------------
    foreach $kwd (@kwd){	# add 'pre' 'title' 'ext' to output files not specified
	next if ($kwd !~ /^fileOut/);
	push(@kwdFileOut,$kwd);
	next if (defined $par{$kwd} && $par{$kwd} ne "unk" && length($par{$kwd})>0);
	$kwdPre=$kwd; $kwdPre=~s/file/pre/;  $kwdExt=$kwd; $kwdExt=~s/file/ext/; 
	$pre="";$pre=$par{"$kwdPre"} if (defined $par{"$kwdPre"});
	$ext="";$ext=$par{"$kwdExt"} if (defined $par{"$kwdExt"});
	if (! defined $par{"title"} || $par{"title"} eq "unk"){
	    $par{"title"}=$scrName;$par{"title"}=~tr/[a-z]/[A-Z]/;} # capitalize title
	$par{$kwd}=$pre.$par{"title"}.$ext;}
				# ------------------------------
				# add output directory
    if (defined $par{"dirOut"} && $par{"dirOut"} ne "unk" && $par{"dirOut"} ne "local" 
        && length($par{"dirOut"})>1){
	if (! -d $par{"dirOut"}){ # make directory
	    print "--- $sbrName mkdir ",$par{"dirOut"},"\n" if ($par{"verb2"});
            $tmp=$par{"dirOut"};$tmp=~s/\/$// if ($tmp=~/\/$/);
	    $Lok= mkdir ($tmp,umask);
	    print 
		"*** $sbrName failed making directory '",
		$par{"dirOut"},"'\n" if (! $Lok);}
				# add slash
	$par{"dirOut"}.="/"     if (-d $par{"dirOut"} && $par{"dirOut"} !~/\/$/);
	foreach $kwd (@kwdFileOut){
	    next if ($par{$kwd} =~ /^$par{"dirOut"}/);
	    next if ($par{$kwd} eq "unk" || ! $par{$kwd});
	    $par{$kwd}=$par{"dirOut"}.$par{$kwd} if (-d $par{"dirOut"});}}
				# ------------------------------
				# push array of output files
    $#fileOut=0 if (! defined @fileOut);
    foreach $kwd (@kwdFileOut){
	push(@fileOut,$par{$kwd});}
				# ------------------------------
				# temporary files: add work dir
    if (defined $par{"dirWork"} && $par{"dirWork"} ne "unk" && $par{"dirWork"} ne "local" 
	&& length($par{"dirWork"})>1) {
	if (! -d $par{"dirWork"}){ # make directory
	    print "--- $sbrName mkdir ",$par{"dirWork"},"\n" if ($par{"verb2"});
            $tmp=$par{"dirWork"};$tmp=~s/\/$// if ($tmp=~/\/$/);
	    $Lok= mkdir ($tmp,umask);
	    print 
		"*** $sbrName failed making directory '",$par{"dirWork"},"'\n" if (! $Lok);}
	$par{"dirWork"}.="/" if (-d $par{"dirWork"} && $par{"dirWork"} !~/\/$/); # add slash
	foreach $kwd (@kwd){
	    next if ($kwd !~ /^file/);
	    next if ($kwd =~ /^file(In|Out|Help|Def)/i);
            $par{$kwd}=~s/jobid/$par{"jobid"}/ ;
	    next if ($par{$kwd} =~ /^$par{"dirWork"}/);
	    $par{$kwd}=$par{"dirWork"}.$par{$kwd};}}
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
	    next if ($par{$kwd} !~ /ARCH/);
	    $par{$kwd}=~s/ARCH/$ARCH/;}}

				# ------------------------------
    foreach $kwd (@kwd){	# add directory to executables
	next if ($kwd !~/^exe/);
	next if (-e $par{$kwd} || -l $par{$kwd});
				# try to add perl script directory
	next if (! defined $par{"dirPerl"} || ! -d $par{"dirPerl"});
	next if ($par{$kwd}=~/$par{"dirPerl"}/); # did already, no result
	$tmp=$par{"dirPerl"}; $tmp.="/" if ($tmp !~ /\/$/);
	$tmp=$tmp.$par{$kwd};
	next if (! -e $tmp && ! -l $tmp);
	$par{$kwd}=$tmp; }

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
	next if (! defined $par{$kwd});
	next if ($kwd=~/expl$/);
	next if (length($par{$kwd})<1);
	if ($kwd =~/^fileOut/) {
	    push(@kwd2,$kwd);
	    next;}
	next if ($par{$kwd} eq "unk");
	next if (defined $exclLoc{$kwd}); # exclusion required
	next if ($exclLoc2 && $kwd =~ /$exclLoc2/);
	printf $fhTraceLocSbr "--- %-20s '%-s'\n",$kwd,$par{$kwd};}
				# ------------------------------
    if ($#kwd2>0){		# output files
	print $fhTraceLocSbr "--- \n","--- Output files:\n";
	foreach $kwd (@kwd2) {
	    next if ($par{$kwd} eq "unk"|| ! $par{$kwd});
	    next if (defined $exclLoc{$kwd}); # exclusion required
	    next if ($exclLoc2 && $kwd =~ /$exclLoc2/);
	    printf $fhTraceLocSbr "--- %-20s '%-s'\n",$kwd,$par{$kwd};}}
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
sub bynumber { 
#-------------------------------------------------------------------------------
#   bynumber                    function sorting list by number
#-------------------------------------------------------------------------------
    $a<=>$b; 
}				# end of bynumber

#===============================================================================
sub bynumber_high2low { 
#-------------------------------------------------------------------------------
#   bynumber_high2low           function sorting list by number (start with high)
#-------------------------------------------------------------------------------
    $b<=>$a; 
}				# end of bynumber_high2low

#==============================================================================
sub complete_dir { return(&completeDir(@_)); } # alias


#===============================================================================
sub completeDir {local($DIR)=@_; $[=1 ; 
		 return(0) if (! defined $DIR);
		 return($DIR) if ($DIR =~/\/$/);
		 return($DIR."/");} # end of completeDir

#==============================================================================
sub convFastamul2many {
    local($fileInLoc,$fileOutLoc,$formOutLoc,$fragLoc,$extrLoc,$fhErrSbr,
	  $LdoCompressLoc,$LshortNamesLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   convFastamul2msf            converts FASTAmul into many formats: FASTA,MSF,PIR,SAF,PIRmul
#       in:                     $fileInLoc,$fileOutLoc,$formOutLoc,$fragLoc,$extrLoc,$fhErrSbr
#       in:                     $formOutLoc     format MSF|FASTA|PIR
#       in:                     $fragLoc=n-m    fragment to extract (optional)
#       in:                     $extrLoc=i,j,k  take only sequences i,j,k from PIRmul
#       in:                     NOTE: to leave blank =0, e.g. 
#       in:                           'file.fastamul,file.f,0,5' would get fifth sequence
#       in:                     $LdoCompressLoc delete insertions in master
#       in:                     $LshortNamesLoc: if 1 names <=15 characters
#       out:                    implicit: file written
#       err:                    (1,'ok'), (0,'message')
#       err:                    e: (1,msg) -> ok
#       err:                    a: (0,msg) -> some arguments missing/files not opened
#       err:                    b: (2,msg) -> no output file written 
#       err:                    b: (3,msg) -> ERROR from msfCheckFormat
#   specification of format     see interpretSeqFastamul
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."convFastamul2msf";$fhinLoc="FHIN_"."convFastamul2msf";
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc!")          if (! defined $fileInLoc);
    return(0,"*** $sbrName: not def fileOutLoc!")         if (! defined $fileOutLoc);
    return(0,"*** $sbrName: not def formOutLoc!")         if (! defined $formOutLoc);
    $fragLoc=0                                            if (! defined $fragLoc);
    $extrLoc=0                                            if (! defined $extrLoc);
    $LdoCompressLoc=0                                     if (! defined $LdoCompressLoc);
    $LshortNamesLoc=0                                     if (! defined $LshortNamesLoc);

    return(0,"*** $sbrName: miss in file '$fileInLoc'!")  if (! -e $fileInLoc);
                                # interpret input
    $formOutLoc=~tr/[A-Z]/[a-z]/;
    if ($fragLoc){
	$fragLoc=~s/\s//g;
	return(0,"*** $sbrName: syntax of fragLoc ($fragLoc) must be :\n".
	       "    'ifir-ilas', where ifir,ilas are integers (or 1-*)\n")
	    if ($fragLoc && $fragLoc !~/[\d\*]\-[\d\*]/);}
    if ($extrLoc){
	$extrLoc=~s/\s//g;
	return(0,"*** $sbrName: syntax of extrLoc ($extrLoc) must be :\n".
	       "    'n1,n2,n3-n4', where n* are integers\n")
	    if ($extrLoc && $extrLoc =~/[^0-9\-,]/);
	@extr=&get_range($extrLoc); 
	undef %take;
	foreach $it(@extr){
	    $take{$it}=1;}}
				# open file
    open($fhinLoc,$fileInLoc) ||
	return(0,"*** ERROR $sbrName: fileIn=$fileInLoc, not opened\n");

                                # ------------------------------
    undef %fasta; $ct=$#id=0;   # read file
    while (<$fhinLoc>) {
	$_=~s/\n//g;
        if ($_=~/^\s*\>\s*(.*)$/){ # is id
            $name=$1;$name=~s/[\s\t]+/ /g; # purge too many blanks
            $name=~s/^\s*|\s*$//g; # purge leading blanks
            $id=$name;$id=~s/^(\S+).*$/$1/; # shorter identifier
            ++$ct;
            $id="$ct"           if (length($id)<1);
            push(@id,$id);
            $fasta{"id",$ct}= $name;
	    $fasta{"seq",$ct}="";}
        else {                  # is sequence
            $_=~s/\s|\t//g;
            $fasta{"seq",$ct}.=$_;}}
				# ------------------------------
    undef %tmp; $ctTake=0;	# store names for passing variables
    foreach $it (1..$#id){ 
	next if ($extrLoc && (! defined $take{$it} || ! $take{$it}));
	++$ctTake; 
	$tmp{"id",$ctTake}= $fasta{"id",$it};
	$tmp{"seq",$ctTake}=$fasta{"seq",$it};}
    $tmp{"NROWS"}=$ctTake;
    %fasta=%tmp; 
    undef %tmp;
				# ------------------------------
				# compress
				# ------------------------------
    if ($LdoCompressLoc){
	$ctcleave=$ctres=0;
	$lenloc=length($fasta{"seq",1});
				# all 0
	foreach $itprot (1..$fasta{"NROWS"}){
	    $fasta{"new",$itprot}="";
	}
				# loop over all residues
	foreach $itres (1..$lenloc){
	    # is residue
	    if (substr($fasta{"seq",1},$itres,1)=~/^[A-Za-z]/){
		foreach $itprot (1..$fasta{"NROWS"}){
		    $fasta{"new",$itprot}.=substr($fasta{"seq",$itprot},$itres,1);
		}
		++$ctres;
		next;}
				# seems insertion
	    ++$ctcleave;
	}
				# check: sum ok?
	return(0,"*** $sbrName: failed at compressing ncleave=$ctcleave, nresnew=$ctres,".
	       " before=".$lenloc." file=$fileInLoc!")
	    if ($lenloc != ($ctcleave + $ctres));
				# replace by cleaved version
	foreach $itprot (1..$fasta{"NROWS"}){
	    $fasta{"seq",$itprot}=$fasta{"new",$itprot};
	}}
    $ctres=length($fasta{"seq",1});

				# ------------------------------
				# shorten names?
				# ------------------------------
    if ($LshortNamesLoc){
	undef %fasta2;
	foreach $it (1..$fasta{"NROWS"}){
	    if (length($fasta{"id",$it})<=15) {
		$fasta2{$fasta{"id",$it}}=1;
		next;}
				# too long
	    $id=$fasta{"id",$it};
	    $id=~s/^.*\|//g;	# purge paths
				# purge blanks
	    $id=~s/\s//g        if (length($id)>15);
				# purge extensions
	    $id=~s/\.[a-z]//g   if (length($id)>15);
				# cleave
	    if (length($id)>15){
		$id=substr($id,1,15);}
				# not unique
	    if (defined $fasta2{$id}){
		$id=substr($id,1,12);
		$ct=1;$idfasta=$id.$ct;
		while(defined $fasta2{$idfasta}){
		    ++$ct;
		    last if ($ct>999);}
		$id=$idfasta;}
	    return(0,"*** $sbrName: shoot id=$id, orig=",,", failed shortening\n")
		if (defined $fasta2{$id} || length($id)>15);
	    $fasta2{$id}=1;
	    $fasta{"id",$it}=$id;
	}
	undef %fasta2; }
				# ------------------------------
				# select subsets
				# ------------------------------
    if ($fragLoc){
	($beg,$end)=split('-',$fragLoc);$len=length($fasta{"seq","1"});
	$beg=1 if ($beg eq "*"); $end=$len if ($end eq "*");
	if ($len< ($end-$beg+1)){
	    print 
		"-*- WARN $sbrName: $beg-$end not possible, as length of protein=$len\n";}
	else {
	    foreach $it (1..$fasta{"NROWS"}){
		$fasta{"seq",$it}=substr($fasta{"seq",$it},$beg,($end-$beg+1));}}}
				# --------------------------------------------------
				# write output
				# --------------------------------------------------
                                # ------------------------------
				# write an MSF formatted file
    if    ($formOutLoc eq "msf"){
        undef %tmp; undef %tmp2; 
        foreach $it (1..$fasta{"NROWS"}){
	    $name=        $fasta{"id",$it};
	    $name=~s/^\s*|\s*$//g;$name=~s/^(\S+).*$/$1/g;
	    $name=substr($name,1,14) if (length($name)>14); # yy hack for convert_seq
	    if (defined $tmp2{$name}){ # avoid duplication
		$ct=0;while (defined $tmp2{$name}){
		    ++$ct;$name=substr($name,1,12).$ct;}}$tmp2{$name}=1;
	    $tmp{$it}=    $name;
	    $tmp{$name}=  $fasta{"seq",$it}; }
	$tmp{"NROWS"}=$fasta{"NROWS"};
        $tmp{"FROM"}=$fileInLoc; 
        $tmp{"TO"}=  $fileOutLoc;
        $fhout="FHOUT_MSF_FROM_SAF";
        open("$fhout",">$fileOutLoc")  || # open file
            return(0,"*** $sbrName cannot open fileOutLoc=$fileOutLoc\n");
        $Lok=
	    &msfWrt($fhout,%tmp); # write the file
        close("$fhout");
        return(0,"*** ERROR $sbrName: failed in MSF format ($fileOutLoc)\n") if (! $Lok);}

                                # ------------------------------
				# write a SAF,PIR,FASTA, formatted file
    elsif ($formOutLoc eq "saf"   || $formOutLoc eq "fastamul" || $formOutLoc eq "pirmul" || 
	   $formOutLoc eq "fasta" || $formOutLoc eq "pir" || $formOutLoc eq "gcg"){
        if    ($formOutLoc =~ /^fasta/){
            ($Lok,$msg)=&fastaWrtMul($fileOutLoc,%fasta);}
        elsif ($formOutLoc =~ /^pir/){
            ($Lok,$msg)=&pirWrtMul($fileOutLoc,%fasta);}
        elsif ($formOutLoc eq "saf"){
            ($Lok,$msg)=&safWrt($fileOutLoc,%fasta);}
        elsif ($formOutLoc eq "gcg"){
            ($Lok,$msg)=&gcgWrt($fileOutLoc,$fasta{"id","1"},$fasta{"seq","1"});}
        return(0,"*** ERROR $sbrName: failed in FASTA format ($fileOutLoc)\n".$msg."\n") 
	    if (! $Lok);}
				# ------------------------------
				# file existing??
    return(2,"*** $sbrName ERROR after write, missing fileOutLoc=$fileOutLoc\n") 
	if (! -e $fileOutLoc);
				# ------------------------------
				# make a basic test of msf format
    if    ($formOutLoc eq "msf"){
        ($Lok,$msg)=
            &msfCheckFormat($fileOutLoc);
        return(3,"$msg"."*** $sbrName ERROR from msfCheckFormat fileOutLoc=$fileOutLoc\n") if (! $Lok);}
				# ------------------------------
    $#fasta=$#nameLoc=0;        # save space
    undef %fasta; undef %nameInBlock; undef %tmp;
    return(1,"$sbrName ok");
}				# end of convFastamul2many

#==============================================================================
sub convFssp2Daf {
    local ($fileFssp,$fileDaf,$fileDafTmp,$exeConv,$dirDsspLoc) = @_ ;
    local ($fhinLoc,$fhoutLoc,$tmp,@tmp);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   convFssp2Daf		converts an HSSP file into the DAF format
#         in:   		fileHssp, fileDaf, execonvFssp2Daf
#         out:   		1 if converted file in DAF and existing, 0 else
#--------------------------------------------------------------------------------
    $sbrName="lib-br:convFssp2Daf";
    return(0,"*** ERROR $sbrName: fileFssp=$fileFssp missing\n") 
        if (! defined $fileFssp || ! -e $fileFssp);
    $dirDsspLoc=""              if (! defined $dirDsspLoc || ! -d $dirDsspLoc);
				# ------------------------------
				# run via system call:
				# ------------------------------
    if ($exeConv=~/\.pl/){
	system("$exeConv $fileFssp $dirDsspLoc >> $fileDafTmp"); }
				# ------------------------------
				# include as package
				# ------------------------------
    else {
	&conv_fssp2daf_lh'conv_fssp2daf_lh($fileFssp,$dirDsspLoc,"fileOut=$fileDafTmp"); } # e.e' 

				# ------------------------------
				# as Liisa cannot do it: clean up!
    $fhinLoc= "FhInconvFssp2Daf"; $fhoutLoc="FhOutconvFssp2Daf";
    &open_file("$fhinLoc","$fileDafTmp") || 
	return(0,"*** ERROR $sbrName failed to open temp=$fileDafTmp (piped from $exeConv)\n");
    &open_file("$fhoutLoc",">$fileDaf")  ||
	return(0,"*** ERROR $sbrName failed to open new=$fileDaf\n");
				# ------------------------------
    while(<$fhinLoc>){		# header
	$tmp=$_;
	last if (/^\# idSeq/);print $fhoutLoc $tmp; }
    $tmp=~s/^\# //g;		# correct error 1 (names)
    $tmp=~s/\n//g;$tmp=~s/^[\t\s]*|[\t\s]*$//g;
    @tmp=split(/[\t\s]+/,$tmp); 
    foreach $tmp(@tmp){
	print $fhoutLoc "$tmp\t";}print $fhoutLoc "\n";
	
				# ------------------------------
    while(<$fhinLoc>){		# body
	$_=~s/\n//g;$_=~s/^[\s\t]*|[\s\t]*$//g;	# purge trailing blanks
	@tmp=split(/[\t\s]+/,$_);
	$seq=$tmp[$#tmp-1];$str=$tmp[$#tmp];
				# consistency
	return(0,"*** ERROR in $sbrName: lenSeq ne lenStr!\n".
	       "***       seq=$seq,\n","***       str=$str,\n","***       line=$_,\n")
	    if (length($seq) != length($str));

	$seqOut=$strOut="";	# expand small caps
	foreach $it (1..length($seq)){
	    $seq1=substr($seq,$it,1);$str1=substr($str,$it,1);
	    if    ( ($seq1=~/[a-z]/) && ($str1=~/[a-z]/) ){
		$seq1=~tr/[a-z]/[A-Z]/;$str1=~tr/[a-z]/[A-Z]/;$seqOut.=$seq1;$strOut.=$str1;}
	    elsif ($seq1=~/[a-z]/){
		$seq1=~tr/[a-z]/[A-Z]/;$seqOut.=$seq1;$strOut.=".";}
	    elsif ($str1=~/[a-z]/){
		$str1=~tr/[a-z]/[A-Z]/;$seqOut.=".";$strOut.=$str1;}
	    else {$seqOut.=$seq1;$strOut.=$str1;}}
				# print
	$tmp[$#tmp-1]=$seqOut;$tmp[$#tmp]=$strOut;
	foreach $tmp(@tmp){print $fhoutLoc "$tmp\t";}print $fhoutLoc "\n";
    } close($fhinLoc);close($fhoutLoc);

    return(1,"ok $sbrName") if ( (-e $fileDaf) && (&isDaf($fileDaf)));
    return(0,"*** ERROR $sbrName output $fileDaf missing or not DAF format\n");
}				# end of convFssp2Daf

#==============================================================================
sub convGcg2fasta {
    local($fileInLoc,$fileOutLoc,$fragLoc,$LshortNamesLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   convGcg2fasta               converts GCG to FASTA format
#       in:                     $fileInLoc,$fileOutLoc,$fragLoc
#       in:                     $fragLoc=n-m    fragment to extract (optional)
#       in:                     $LshortNamesLoc: if 1 names <=15 characters
#       out:                    implicit: file out
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."convGcg2fasta";$fhinLoc="FHIN_"."convGcg2fasta";
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc!")          if (! defined $fileInLoc);
    return(0,"*** $sbrName: not def fileOutLoc!")         if (! defined $fileOutLoc);
    $fragLoc=0                                            if (! defined $fragLoc);
    $LshortNamesLoc=0                                     if (! defined $LshortNamesLoc);

    return(0,"*** $sbrName: miss in file '$fileInLoc'!")  if (! -e $fileInLoc);

                                # ------------------------------
    ($Lok,$id,$seq)=            # read GCG
        &gcgRd($fileInLoc);
    return(0,"*** ERROR $sbrName: failed to read SWISS ($fileInLoc)\n".
             "***                 found id=$id\n") 
        if (! $Lok || length($seq)<1);

    undef %tmp;
    $tmp{"id","1"}= $id;
    $tmp{"seq","1"}=$seq;
    $tmp{"NROWS"}=1;
                                # ------------------------------
                                # extract?
    if ($fragLoc){($beg,$end)=split(/-/,$frag);
                  foreach $it (1..$tmp{"NROWS"}){
                      $tmp{"seq",$it}=substr($tmp{"seq",$it},$beg,($end-$beg+1));}}

    $ctres=length($tmp{"seq",1});
				# ------------------------------
				# shorten names?
				# ------------------------------
    if ($LshortNamesLoc){
	undef %tmp2;
	foreach $it (1..$tmp{"NROWS"}){
	    if (length($tmp{"id",$it})<=15) {
		$tmp2{$tmp{"id",$it}}=1;
		next;}
				# too long
	    $id=$tmp{"id",$it};
	    $id=~s/^.*\|//g;	# purge paths
				# purge blanks
	    $id=~s/\s//g        if (length($id)>15);
				# purge extensions
	    $id=~s/\.[a-z]//g   if (length($id)>15);
				# cleave
	    if (length($id)>15){
		$id=substr($id,1,15);}
				# not unique
	    if (defined $tmp2{$id}){
		$id=substr($id,1,12);
		$ct=1;$idtmp=$id.$ct;
		while(defined $tmp2{$idtmp}){
		    ++$ct;
		    last if ($ct>999);}
		$id=$idtmp;}
	    return(0,"*** $sbrName: shoot id=$id, orig=",,", failed shortening\n")
		if (defined $tmp2{$id} || length($id)>15);
	    $tmp2{$id}=1;
	    $tmp{"id",$it}=$id;
	}
	undef %tmp2; }
                                # ------------------------------
                                # write output
    ($Lok,$msg)=
        &fastaWrtMul($fileOutLoc,%tmp);
    return(0,"*** ERROR $sbrName: failed to write FASTAmul ($fileOutLoc)\n".
           "***                 msg=$msg\n") if (! $Lok);
    return(2,"-*- WARN $sbrName: wrong number written\n$msg\n") if ($Lok != 1);
    return(1,"ok $sbrName");
}				# end of convGcg2fasta

#==============================================================================
sub convHssp2seq {
    local($fileInLoc,$chainInLoc,$fileOutLoc,$formOutLoc,$extOutLoc,
          $doExpand,$fragLoc,$extrLoc,$lenMin,$laliMin,$distMin,$pideMax,$fhErrSbr,
	  $doSplitChainLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   convHssp2seq                converts HSSP file to PIR(mul), FASTA(mul)
#       in:                     $fileInLoc   file.hssp, file.out, format_of_output_file
#       in:                     $fileOutLoc  output file with converted sequence(s)
#       in:                     $formOut     output format (lower caps)
#                                 = 'fasta|pir' (or pirmul/fastamul)
#       in:                     $extOutLoc   extension of expected output 
#                                            (fragments into _beg_end$extension)
#       in:                     $doExpand    do expand the deletions? (only for MSF)
#       in:                     $frag        fragment e.g. '1-5','10-100'
#                                 = 0        for any
#                                            NOTE: only ONE fragment allowed, here
#       in:                     $extrIn      number of protein(s) to extract
#                                 = 'p1-p2,p3' -> extract proteins p1-p2,p3
#                                 = 0        for all
#                      NOTE:      = guide    to write only the guide sequence!!
#       in:                     $lenMin      minimal length of sequence to write 
#                                 = 0        for any
#       in:                     $laliMin     minimal alignment length (0 for wild card)
#                                 = 0        for any
#       in:                     $distMin     minimal distance from HSSP threshold
#                                 = 0        for any
#       in:                     $pideMAx !!  maximal sequence identity
#                                 = 0        for any
#       in:                     $fhSbr       ERRORs of convert_seq
#       in:                     $doSplitChain split chains when converting to FASTA
#                               
#       in GLOBAL               $par{"pre_id"} -> id -> 'DB|id name'
#                               
#       out:                    1|0,msg,implicit: converted file
#                               
#       err:                    0,$msg -> unspecified error 
#       err:                    1,$msg -> ok
#       err:                    2,$msg -> conversion option not supported
#-------------------------------------------------------------------------------
    $sbrName="lib-br::"."convHssp2seq"; $fhinLoc="FHIN_"."convHssp2seq";
                                # ------------------------------
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc!")           if (! defined $fileInLoc);
    $chainInLoc="*"                                        if (! defined $chainInLoc);
    return(0,"*** $sbrName: not def fileOutLoc!")          if (! defined $fileOutLoc);
    return(0,"*** $sbrName: not def formOutLoc!")          if (! defined $formOutLoc);
    return(0,"*** $sbrName: not def extOutLoc!")           if (! defined $extOutLoc);
    return(0,"*** $sbrName: not def doExpand!")            if (! defined $doExpand);
    return(0,"*** $sbrName: not def fragLoc!")             if (! defined $fragLoc);
    return(0,"*** $sbrName: not def extrLoc!")             if (! defined $extrLoc);
    $lenMin=0                                              if (! defined $lenMin);
    $laliMin=0                                             if (! defined $laliMin);
    $distMin=0                                             if (! defined $distMin);
    $pideMax=0                                             if (! defined $pideMax);
    $fhErrSbr="STDOUT"                                     if (! defined $fhErrSbr);
    $doSplitChainLoc=0                                     if (! defined $doSplitChainLoc);
				# existence of file
    return(0,"*** $sbrName: miss in file '$fileInLoc'!")   if (! -e $fileInLoc);

                                # ------------------------------
                                # supported output options
    return(&errSbr("output format $formOutLoc not supported by this sbr"))
	if ($formOutLoc !~ /^(pir|fasta)/);

				# ------------------------------
    if ($fragLoc) {		# fragment of proteins
	return(&errSbr("frag MUST be 'N1-N2', only ONE!")) if ($fragLoc !~/\d+\-\d+/);
	($ifirFrag,$ilasFrag)=split(/\-/,$fragLoc); }
    else {
	$ifirFrag=$ilasFrag=0; }

    $LextrGuideOnly=0;		# ------------------------------
    undef %extr;		# extraction of proteins
    if ($extrLoc eq "guide"){	# only guide
	$LextrGuideOnly=1;}
    elsif ($extrLoc) {		# get numbers to extract
	return(&errSbr("extr MUST be of the form:\n".
		       "'extr=n1-n2', or 'extr=n1,n2,n3-n4,n5'"))
	    if ($extr !~ /\d/);
	@extr=&get_range($extr);
	return(&errSbr("you gave the argument 'extr=$extr', not valid!\n".
		       "***   Ought to be of the form:\n".
		       "'extr=n1-n2', or 'extr=n1,n2,n3-n4,n5'\n")) if ($#extr==0);
	foreach $tmp (@extr) {
	    if ($tmp=~/\D/){ 
		return(&errSbr("you gave the argument 'extr=$extr', not valid!\n".
			       "***   Ought to be of the form:\n".
			       "'extr=n1-n2', or 'extr=n1,n2,n3-n4,n5'\n")); }
	    $extr{"$tmp"}=1; }}
				# ------------------------------
				# determine id
    $pdbid= $fileInLoc;$pdbid=~s/^.*\/|\.hssp//g; 
    $pdbid.="_".$chainInLoc     if ($chainInLoc ne "*");
    undef %tmp;			# ------------------------------
    if ($chainInLoc ne "*"){	# get chain positions
        ($Lok,%tmp)= 
	    &hsspGetChain($fileInLoc);
                                return(&errSbr("failed on getchain($fileInLoc)")) if (! $Lok);
	foreach $it (1..$tmp{"NROWS"}){
	    next if ($chainInLoc ne $tmp{$it,"chain"});
	    $ifirChain=$tmp{$it,"ifir"}; $ilasChain=$tmp{$it,"ilas"}; }}
    else {
	$ifirChain=$ilasChain=0;}
				# ------------------------------
    undef %tmp;			# read header of HSSP
    ($Lok,%tmp)=
	&hsspRdHeader($fileInLoc,"HEADER","SEQLENGTH","ID","IDE","LALI","IFIR","ILAS");
                                return(&errSbr("failed on $fileInLoc")) if (! $Lok);
    $header="";
    $header=$tmp{"HEADER"}      if (defined $tmp{"HEADER"});
                                # ------------------------------
                                # too short -> skip
    return(1,"too short=".$tmp{"SEQLENGTH"})  if ($tmp{"SEQLENGTH"} < $lenMin);

    $#numTake=0;		# ------------------------------
				# process data

    if ($LextrGuideOnly){	# guide, only -> skip the following
	push(@numTake,1);
	$tmp{"NROWS"}=0; }

    foreach $it (1..$tmp{"NROWS"}){ # loop over all alis
				# not to include 
	next if ($extrLoc && ! defined $extr{$it});
				# not chain -> skip
	next if ($ifir && $ilas && 
		 ( ($tmp{"IFIR",$it} > $ilas) || ($tmp{"ILAS",$it} < $ifir) ));
				# lali too short
	next if ($laliMin > $tmp{"LALI",$it} );
				# pide too high
	next if ($pideMax && $pideMax < 100*$tmp{"IDE",$it} );
				# distance from threshold too high
	if ($distMin){
                                # compile distance to HSSP threshold (new)
	    ($pideCurve,$msg)= 
		&getDistanceNewCurveIde($tmp{"LALI",$it});
	    next if ($msg !~ /^ok/);
	    $dist=100*$tmp{"IDE",$it} - $pideCurve;
	    next if ($dist < $distMin); }

        push(@numTake,$it);     # ok -> take
    }
                                # ------------------------------
    undef %tmp;			# read alignments
    $kwdSeq="seqNoins";                         # default: read ali without insertions
    $kwdSeq="seqAli"            if ($doExpand);	# wanted:  read ali with insertions
	
    ($Lok,%tmp)=
	&hsspRdAli($fileInLoc,@numTake,$kwdSeq);
                                return(&errSbrMsg("failed reading alis for $fileInLoc, num=".
						  join(',',@numTake),$msg)) if (! $Lok);
    $nali=$tmp{"NROWS"};
    undef %tmp2;
				# ------------------------------
    if (defined $fragLoc){	# adjust for extraction (arg: frag=N1-n2)
				# additional complication if expand: change numbers
	if ($kwdSeq eq "seqAli"){ 
	    $seq=$tmp{$kwdSeq,"0"};
	    @tmp=split(//,$seq); $ct=0;
	    foreach $it (1..$#tmp){
		next if ($tmp[$it] eq ".");             # skip insertions
		++$ct;                                  # count no-insertions
		next if ($ct > $ifirFrag);              # outside of range to read
		next if ($ct < $ilasFrag);              # outside of range to read
		$ifirFrag=$it if ($ct == $ifirFrag);    # change begin !!  WARN  !!
		$ilasFrag=$it if ($ct == $ilasFrag);}}} # change end   !!  WARN  !!

				# ----------------------------------------
				# cut out non-chain, and not to read parts
				# ----------------------------------------
    foreach $it (0..$nali){
				# guide, only -> skip the following
	last if ($LextrGuideOnly && $it>0);
				# chain restricts reading
	if ($ifirChain && $ilasChain){
	    $tmp{$kwdSeq,$it}=
		substr($tmp{$kwdSeq,$it},$ifirChain,($ilasChain-$ifirChain+1));}
				# wanted fragment restricts reading
	if ($ifirFrag && $ilasFrag){
	    $len=length($tmp{$kwdSeq,$it});
	    return(&errSbr(" : sequence outside (f=$fileInLoc, c=$chainInLoc)\n".
			   "itNali=$it, ifirFrag=$ifirFrag, len=$len, kwdSeq=$kwdSeq,\n".
			   "seq=".$tmp{$kwdSeq,$it}))
		if ( $len < $ifirFrag);
	    $lenWrt=($ilasFrag-$ifirFrag+1);
	    $lenWrt=$len-$ifirFrag+1  if ($lenWrt < $len);
	    $tmp{$kwdSeq,$it}=
		substr($tmp{$kwdSeq,$it},$ifirFrag,$len); }
	$ct=$it+1;
	$tmp2{"seq",$ct}=$tmp{$kwdSeq,$it};
	undef  $tmp{$kwdSeq,$it}; # slim-is-in !
	$tmp2{"id",$ct}= $tmp{$it};
	$tmp2{"id",$ct}.="_".$chainInLoc if ($ct==1 && $chainInLoc ne "*");
				# add db asf
	$tmp2{"id",$ct}=
	    $par{"pre_id"}."|".$tmp2{"id",$ct}." ".$header
		if ($par{"pre_id"});
    }
    $tmp2{"NROWS"}=$nali+1;
    $tmp2{"NROWS"}=1            if ($LextrGuideOnly);
    undef %tmp;			# slim-is-in!
				# ------------------------------
    undef %tmp;			# slim-is-in !
    undef @numTake;		# slim-is-in !

				# --------------------------------------------------
				# write output file
				# --------------------------------------------------
    if ($formOutLoc =~ /^pir/){ # PIR, PIRmul
        ($Lok,$msg)=
            &pirWrtMul($fileOutLoc,%tmp2); }
    else {                      # FASTA, FASTAmul
        ($Lok,$msg)=
            &fastaWrtMul($fileOutLoc,%tmp2); }
        
    return(&errSbrMsg("failed writing out=$fileOutLoc, for in=$fileInLoc",$msg)) if (! $Lok);
    print $fhErrSbr		# warning if returned Lok==2
	"-*- WARN $sbrName: outformat=$formOutLoc, not enough written:\n",$msg,"\n" 
	    if ($Lok==2);
    undef %tmp2;		# slim-is-in !
    return(1,"ok $sbrName");
}				# end of convHssp2seq

#==============================================================================
sub convMsf2saf {
    local($fileInLoc,$fileOutLoc,$doCompressLoc) = @_ ;
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   convMsf2saf                 converts MSF into SAF format
#       in:                     fileMsf,fileSaf
#       out:                    0|1,$msg 
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:convMsf2saf";$fhinLoc="FHIN_"."convMsf2saf";$fhoutLoc="FHOUT_"."convMsf2saf";
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc!")          if (! defined $fileInLoc);
    return(0,"*** $sbrName: not def fileOutLoc!")         if (! defined $fileInLoc);
    return(0,"*** $sbrName: miss in file '$fileInLoc'!")  if (! -e $fileInLoc);
    $doCompressLoc=0            if (! defined $doCompressLoc ||
				    $doCompressLoc ne "1");

				# --------------------------------------------------
				# change br 2000-02: read and write & compress
				# --------------------------------------------------
    ($Lok,$msg,%tmp)=
	&msfRd($fileInLoc);     return(0,"*** $sbrName: failed on msfRd msg=\n".
				       $msg) if (! $Lok);

    return(0,"*** ERROR $sbrName: $fileInLoc no valid MSF file?\n") 
	if ($tmp{"NROWS"}==0);

				# cleave off insertions in guide sequence
    if ($doCompressLoc){
	$lenloc=length($tmp{"seq",1});
	$ctcleave=$ctres=0;
				# all 0
	foreach $itprot (1..$tmp{"NROWS"}){
	    $tmp{"new",$itprot}="";
	}
				# loop over all residues
	foreach $itres (1..$lenloc){
				# is residue
	    if (substr($tmp{"seq",1},$itres,1)=~/^[A-Za-z]/){
		foreach $itprot (1..$tmp{"NROWS"}){
		    $tmp{"new",$itprot}.=substr($tmp{"seq",$itprot},$itres,1);
		}
		++$ctres;
		next;}
				# seems insertion
	    ++$ctcleave;
	}
				# check: sum ok?
	return(0,"*** $sbrName: failed at compressing ncleave=$ctcleave, nresnew=$ctres,".
	       " before=".$lenloc." file=$fileInLoc!")
	    if ($lenloc != ($ctcleave + $ctres));
				# replace by cleaved version
	foreach $itprot (1..$tmp{"NROWS"}){
	    $tmp{"seq",$itprot}=$tmp{"new",$itprot};
	}
    }
				# ------------------------------
				# now write SAF
				# ------------------------------
    ($Lok,$msg)=
	&safWrt($fileOutLoc,
		%tmp);		return(0,"*** $sbrName: failed writing SAF=$fileOutLoc, in=".
				       $fileInLoc." err msg=\n".$msg) if (! $Lok);
    return(0,"*** $sbrName: failed writing SAF=$fileOutLoc, in=".
	   $fileInLoc)          if ( ! -e $fileOutLoc);

    undef %tmp;			# slim-is-in
    return(1,"ok $sbrName");
    

				# **************************************************
				# dead code before 2000-02
    open($fhinLoc,$fileInLoc) ||
	return(0,"*** ERROR $sbrName: fileIn=$fileInLoc, not opened\n");
    $#tmp=$ct=$Lname=$LMsf=$LSeq=0;
				# ------------------------------
    while (<$fhinLoc>) {	# read MSF file
	$_=~s/\n//g;
				# --------------------
				# find sequence
        if    (! $LSeq && $_=~/^\/\// && $Lname && $LMsf){
            $LSeq=1;}
				# --------------------
	elsif (! $LSeq){	# header
            $LMsf=1             if (! $LMsf  && $_=~/msf\s*of\s*\:|msf\:\s+\d+/i);
            $Lname=1            if (! $Lname && $_=~/name\s*:/i);
	    push(@tmp,$_)       if (! $Lname); } # store header
				# --------------------
        elsif ($LSeq){		# sequence
				# first open file
            if ($ct==0){
		open($fhoutLoc,">".$fileOutLoc) || 
		    return(0,"*** ERROR $sbrName: failed opening fileout (saf)=$fileOutLoc\n");
		print $fhoutLoc "# SAF (Simple Alignment Format)\n";
		foreach $tmp(@tmp){
		    print $fhoutLoc "# $tmp\n";
		}
	    }
	    ++$ct;
	    print $fhoutLoc "$_\n";	# simply mirror file
	}
    } 
    close($fhinLoc); close($fhoutLoc) if ($ct>0); 
    $#tmp=0;			# save memory
    return(0,"*** ERROR $sbrName: $fileInLoc no valid MSF file\n") if ($ct==0);
    return(1,"ok $sbrName");
}				# end of convMsf2saf

#==============================================================================
sub convPdb2seq {
    local($fileInLoc,$chainInLoc,$fileOutLoc,$formOutLoc,$frag,$fhTraceLoc)=@_;
    local($outformat,$an,$commandLoc);
#----------------------------------------------------------------------
#   convPdb2seq                 convert PDB to sequence only
#       in:                     $fileIn,$fileOut,$formOutLoc,$frag,$fhTraceLoc
#       in:                     $chainInLoc=  PDB chain
#                                  =  "*"     for any
#       in:                     $formOutLoc=  'FASTA|GCG|PIR'
#       in:                     $frag= 1-5, fragment from 1 -5 
#       out:                    file
#       err:                    ok=(1,'ok'), err=(0,'msg')
#----------------------------------------------------------------------
    $sbrName="convPdb2seq";
    $allow="fasta|pir|gcg";
    return(0,"*** $sbrName: not def fileInLoc!")        if (! defined $fileInLoc);
    return(0,"*** $sbrName: not def chainInLoc!")       if (! defined $chainInLoc);
    $chainInLoc="*"             if (length($chainInLoc) < 1 || $chainInLoc =~/\s/);
    return(0,"*** $sbrName: not def fileOutLoc!")       if (! defined $fileOutLoc);
    return(0,"*** $sbrName: not def formOutLoc!")       if (! defined $formOutLoc);
    $frag=0                                             if (! defined $frag);
    $fhTraceLoc="STDOUT"                                if (! defined $fhTraceLoc);
				# check existence of files
    return(0,"*** $sbrName: no file '$fileInLoc'!")     if (! -e $fileInLoc);
                                # check format
    $formOutLoc=~tr/[A-Z]/[a-z]/;
    return(0,"*** $sbrName: output format $formOutLoc not supported\n")
        if ($formOutLoc !~ /$allow/);
    $anFormOut=substr($formOutLoc,1,1);$anFormOut=~tr/[a-z]/[A-Z]/;
    $frag=0 if ($frag !~ /\-/);
                                # ------------------------------
    if ($frag){                 # extract fragments?
        $frag=~s/\s//g;
        ($beg,$end)=split('-',$frag);
        $frag=0 if ($beg =~/\D/ || $end =~ /\D/);}
				# ------------------------------
				# read PDB
    ($Lok,$msg,$rh_pdb)=
	&pdbExtrSequence($fileInLoc,$chainInLoc,1);

    return(0,"*** $sbrName: error in reading PDB $fileInLoc :\n".$msg."\n")
	if (! $Lok);
    
    return(2,"*** $sbrName: $fileInLoc is RNA DNA?\n")
	if ($Lok==2);

    return(0,"*** $sbrName: error in reading PDB $fileInLoc  (not defined pdb(chains)):\n".
	     $msg."\n")
	if (! defined $rh_pdb->{"chains"});

    @chainTmp=split(/,/,$rh_pdb->{"chains"});
				# ------------------------------
				# loop over all chains
				# ------------------------------
    $seq=$chain="";
    $name=0; 
    $id=$fileInLoc;$id=~s/^.*\/|\..*$//g;
    foreach $chainTmp (@chainTmp) {
	$chain.=$chainTmp       if ($chainTmp ne "none");
				# ------------------------------
				# id
				# first line: id
	if (! $name) {
	    $name=$id;
	    $name.=" ".$rh_pdb->{"header"} if (defined $rh_pdb->{"header"});
	    $name.=" ".$rh_pdb->{"compnd"} if (defined $rh_pdb->{"compnd"});
	    $name.=" source=".$rh_pdb->{"source"} if (defined $rh_pdb->{"source"});}
				# ------------------------------
				# next lines: sequence
	$seqRd=$rh_pdb->{$chainTmp};
	$seqRd=~s/\s//g;
				# add '!' as chain symbol
	$seq.="!"               if (length($seq)>0);
	$seq.=$seqRd; }
				# ******************************
				# not really found
    return(0,"*** $sbrName: seq=$seq, for file=$fileInLoc,$chainInLoc,$frag!")
	if (length($seq)<1);
				# ******************************

				# add all chains to name
    $name.=" chains=".join(',',split(//,$chain)) if (length($chain)>0);

				# ------------------------------
				# extract fragment
    if ($frag) {
	return(0,"*** ERROR $sbrName: $fileInLoc seqrd=".
	       $seq."***   however wanted to restrict to fragment from $beg-$end\n")
	    if (length($seq)<$beg);
	$seq=substr($seq,$beg);
	$lenWant=1+$end-$beg;
	if (length($seq)<$lenWant) {
	    print $fhTraceLoc 
		"-*- WARN $sbrName: $fileInLoc ($chainTmp) shorter than expected!\n",
		"-*-      wanted $beg-$end, but is ",length($seq)," residues long\n"; }
	else {
	    $seq=substr($seq,1,$lenWant);}}
				# ------------------------------
				# write out
    $Lok=0;
    if    ($formOutLoc =~ /^pir/){
	($Lok,$msg)=&pirWrtOne($fileOutLoc,$id,$seq); }
    elsif ($formOutLoc =~ /^fasta/){
	($Lok,$msg)=&fastaWrt($fileOutLoc,$id,$seq); }
    elsif ($formOutLoc =~ /^gcg/){
	($Lok,$msg)=&gcgWrt($fileOutLoc,$id,$seq); }
				# 
    return(0,"*** $sbrName: error in converting PDB $fileInLoc:\n".$msg."\n")
	if (! $Lok);

    return(1,"ok $sbrName");
}				# end of convPdb2seq

#===============================================================================
sub convPhd2dssp {
    local($fileInLoc,$fileOutLoc,$chainLoc,$fhErrSbr) = @_ ;
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   convPhd2dssp                converts PHDrdb format to DSSP format
#       in:                     $fileInLoc,$fileOutLoc,$chainLoc,
#       in:                     $chainLoc   chain name ([A-Z0-9 ])
#       in:                     $fhErrSbr   0 for no write
#       out:                    1|0,msg,  implicit: writes fileDSsp
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."convPhd2dssp";
    $fhinLoc="FHIN_"."convPhd2dssp";$fhoutLoc="FHOUT_"."convPhd2dssp";
				# ------------------------------
				# check arguments
    return(&errSbr("not def fileInLoc!"))    if (! defined $fileInLoc);
    return(&errSbr("not def fileOutLoc!"))   if (! defined $fileOutLoc);
    $chainLoc=" "                            if (! defined $chainLoc);
    $fhErrSbr="STDOUT"                       if (! defined $fhErrSbr);

#    return(&errSbr("not def !"))          if (! defined $);
#    return(&errSbr("not def !"))          if (! defined $);

    return(&errSbr("no fileIn=$fileInLoc!")) if (! -e $fileInLoc);

				# ------------------------------
				# defaults
				# keywords to read from RDB file
    @kwdLoc =("No","AA","PHEL","RI_S","PACC","RI_A");
    $idLoc=$fileInLoc;
    $idLoc=~s/^.*\///g;$idLoc=~s/\s|\n|\.rdb.*//g;

				# --------------------------------------------------
				# read RDB file
				# --------------------------------------------------
    undef %rd;
    %rd=
        &rdRdbAssociative($fileInLoc,"body",@kwdLoc); 
	
				# --------------------------------------------------
				# store into NUM, SEQ, SEC, RISEC, ACC, RIACC
				# --------------------------------------------------
    $#NUM=$#SEQ=$#SEC=$#RISEC=$#ACC=$#RIACC=0;
    foreach $kwd (@kwdLoc) {
	next                    if (! defined $rd{$kwd,"1"}) ;
	if    ($kwd eq "No") {
	    $ct=1; while(defined $rd{$kwd,$ct}){push(@NUM,$rd{$kwd,$ct});++$ct;}}
	elsif ($kwd eq "AA") {
	    $ct=1; while(defined $rd{$kwd,$ct}){push(@SEQ,$rd{$kwd,$ct});++$ct;}}
	elsif ($kwd eq "PHEL") {
	    $ct=1; while(defined $rd{$kwd,$ct}){push(@SEC,$rd{$kwd,$ct});++$ct;}}
	elsif ($kwd eq "RI_S") {
	    $ct=1; while(defined $rd{$kwd,$ct}){push(@RISEC,$rd{$kwd,$ct});++$ct;}}
	elsif ($kwd eq "PACC") {
	    $ct=1; while(defined $rd{$kwd,$ct}){push(@ACC,$rd{$kwd,$ct});++$ct;}}
	elsif ($kwd eq "RI_A") {
	    $ct=1; while(defined $rd{$kwd,$ct}){push(@RIACC,$rd{$kwd,$ct});++$ct;}}
    }
				# ------------------------------
				# convert L->' '
    foreach $it(1..$#SEC){
	$SEC[$it]=~s/L/ /;}
				# --------------------------------------------------
				# writing phd into DSSP format
				# --------------------------------------------------
    $CHAIN=$chainLoc;
    print $fhErrSbr
	"--- $sbrName: writing id=$idLoc, chain=$CHAIN, fileOut=$fileOutLoc\n"
	    if ($fhErrSbr);
				# NOTE: GLOBAL in: all $CHAIN,@NUM,@SEQ,@SEC,@ACC,@RI*
    ($Lok,$msg)=
	&dsspWrtFromPhd($fileOutLoc,$idLoc);

    if (! $Lok) { $msgErr="*** ERROR $scrName: failed writing $fileOutLoc\n".$msg;
		  print $msgErr,"\n";
		  die; }

    $#NUM=$#SEQ=$#SEC=$#RISEC=$#ACC=$#RIACC=0; # slim-is-in!
    undef %rd;			# slim-is-in!

    return(1,"ok $sbrName");
}				# end of convPhd2dssp

#===============================================================================
sub convPhd2seq {
    local($fileInLoc,$fileOutLoc,$formatOutLoc,$fhErrSbr) = @_ ;
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   convPhd2seq                 converts PHDrdb to SEQUENCE format || string
#       in:                     $fileIn   PHD rdb file
#       in:                     $fileOut  name of output file
#           note:                         string returned if =0 !
#       in:                     $formOut  PIR|GCG|FASTA|keyword
#           note:                         keyword determines which string is 
#                                         to be extracted:
#                 combine many by 'AA,PHEL,..'
#                                  AA    sequence
#                                  OHEL  observed sec str
#                                  OHL   observed HTM
#                                  OACC  observed accessibility (angstrom)
#                                  OREL  observed relative acc
#                                  
#                                  PHEL  predicted sec str
#                                  PHL   predicted HTM
#                                  PFHL  filtered HTM
#                                  PRHL  refined HTM
#                                  PiTo  topology HTM
#                                  PACC  predicted accessibility (angstrom)
#                                  PREL  predicted relative acc
#                                  Pbie  predicted accessibility in 3 states
#                                  
#                                  RI_S  reliability index sec str
#                                  RI_A  reliability index accessibility
#                                  RI_H  reliability index HTM
#                                  
#                                  pH    normalised output unit H
#                                  pE    normalised output unit E
#                                  pL    normalised output unit L
#                                  pb    normalised output unit b (buried)
#                                  pe    normalised output unit e (exposed)
#                                  
#                                  OtH   full output unit (0-100) H
#                                  OtE   full output unit (0-100) E
#                                  OtL   full output unit (0-100) L
#                                  Otb   full output unit (0-100) b (buried)
#                                  Ote   full output unit (0-100) e (exposed)
#                                  
#                                            
#       out:                    $string1,$string2, or implicit file!
#                               NOTE:  string1=that matching formatOut1
#                               NOTE2: residues separated by commata!
#       err:                    (1,'ok',@strings), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."convPhd2seq";
    $fhinLoc="FHIN_"."convPhd2seq";$fhoutLoc="FHOUT_"."convPhd2seq";
				# ------------------------------
				# check arguments
    return(&errSbr("not def fileInLoc!"))    if (! defined $fileInLoc);
    return(&errSbr("not def fileOutLoc!"))   if (! defined $fileOutLoc);
    return(&errSbr("not def formatOutLoc!")) if (! defined $formatOutLoc);
    $fhErrSbr="STDOUT"                       if (! defined $fhErrSbr);

#    return(&errSbr("not def !"))          if (! defined $);

    return(&errSbr("no fileIn=$fileInLoc!")) if (! -e $fileInLoc);

				# ------------------------------
				# defaults
				# keywords to read from RDB file
    $#kwdLoc=0;
    undef %translate;
    if ($formatOutLoc =~/^(PIR|FASTA|GCG)$/i) {
	push(@kwdLoc,"AA");}
    elsif ($formatOutLoc) {
	$formatOutLoc=~s/\s//g;
	push(@kwdLoc,split(/,/,$formatOutLoc)); }

				# --------------------------------------------------
				# read RDB file
				# --------------------------------------------------
    undef %rd;
    %rd=
        &rdRdbAssociative($fileInLoc,"body",@kwdLoc); 
				# --------------------------------------------------
				# extract strings (residues separated by commata)
				# --------------------------------------------------
    $#tmp=0;
    foreach $kwd (@kwdLoc) {
	next if (! defined $rd{$kwd,"1"});
	$string="";
	$it=1;
	while (defined $rd{$kwd,$it}) {
	    $string.=$rd{$kwd,$it}.","; 
	    ++$it; }
	$string=~s/\,$//g;	# purge final comma
	push(@tmp,$string);  }
    undef %rd;			# slim-is-in

				# ==================================================
				# <--- <--- <--- <--- <--- <--- 
				#      EARLY end: just return strings
    return(1,"ok",@tmp)
	if (! $fileOutLoc || $formatOutLoc !~ /^(PIR|FASTA|GCG)$/i);
				# <--- <--- <--- <--- <--- <--- 
				# ==================================================


				# --------------------------------------------------
				# writing phd into sequence file format
				# --------------------------------------------------
    $idLoc=$fileInLoc;$idLoc=~s/^.*\///g;
    print $fhErrSbr
	"--- $sbrName: writing id=$idLoc, fileOut=$fileOutLoc\n"
	    if ($fhErrSbr);
				# output PIR format
    if    ($formatOutLoc =~/^pir/) { # 
	foreach $it (1..$#kwdLoc) {
	    next if ($kwdLoc[$it] !~/^AA$/);
	    $seq=$tmp[$it];
	    $seq=~s/\,//g;	# purge commata
	    last; }
	$id=$fileInLoc;$id=~s/^.*\/|\..*$//g;
	($Lok,$msg)=
	    &pirWrtOne($fileOutLoc,$id,$seq);
	return(0,"*** ERROR $sbrName: failed converting PHDrdb to PIR\n".$msg)
	    if (! $Lok); }
				# output FASTA format
    elsif ($formatOutLoc =~/^fasta/) {
	foreach $it (1..$#kwdLoc) {
	    next if ($kwdLoc[$it] !~/^AA$/);
	    $seq=$tmp[$it];
	    $seq=~s/\,//g;	# purge commata
	    last; }
	$id=$fileInLoc;$id=~s/^.*\/|\..*$//g;
	($Lok,$msg)=
	    &fastaWrt($fileOutLoc,$id,$seq);
	return(0,"*** ERROR $sbrName: failed converting PHDrdb to FASTA\n")
	    if (! $Lok);}
				# output format unknown
    else {
	return(0,"*** ERROR $sbrName: output format $formatOutLoc unknown!\n");
    }

    $#tmp=0;			# slim-is-in!
    $#kwdLoc=0;			# slim-is-in!

    return(1,"ok $sbrName");
}				# end of convPhd2seq

#===============================================================================
sub convPhdGen {
    local($fileInLoc,$chainInLoc,$fileOutLoc,$formIn,$formOut,$extOutLoc,
	  $frag,$fileScreenLoc,$dirWork,$fhSbr) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   convPhdGen                  general converter for PHD predictions into -> x
#       in:                     for general info see 'convPhdGen'
#       out:                    converted file
#       out GLOBAL:             @fileOut,@kwdRm,$file{"kwd"} files to remove
#       err:                    0,$msg -> unspecified error 
#       err:                    1,$msg -> ok
#       err:                    2,$msg -> conversion option not supported
#-------------------------------------------------------------------------------
    $sbrName="$scrName:"."convPhdGen";$fhinLoc="FHIN"."$sbrName";
                                # ------------------------------
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc!")          if (! defined $fileInLoc);
    return(0,"*** $sbrName: not def chainInLoc!")         if (! defined $chainInLoc);
    return(0,"*** $sbrName: not def fileOutLoc!")         if (! defined $fileOutLoc);
    return(0,"*** $sbrName: not def formIn!")             if (! defined $formIn);
    return(0,"*** $sbrName: not def formOut!")            if (! defined $formOut);
    return(0,"*** $sbrName: not def extOutLoc!")          if (! defined $extOutLoc);
    return(0,"*** $sbrName: not def frag!")               if (! defined $frag);
    return(0,"*** $sbrName: not def fileScreenLoc!")      if (! defined $fileScreenLoc);
    return(0,"*** $sbrName: not def dirWork!")            if (! defined $dirWork);
    $fhSbr="STDOUT"                                       if (! defined $fhSbr);
    return(0,"*** $sbrName: miss in file '$fileInLoc'!")  if (! -e $fileInLoc);

    $chainIn=$chainInLoc; $chainIn="*" 
	if (! $chainInLoc || length($chainInLoc)!=1 || $chainInLoc !~/[A-Z0-9]/);


    $#beg=$#end=0;
				# ------------------------------
    if ($frag &&		# extract fragments? NOT for DSSP!
	($formOut eq "dssp" || $formOut =~ /^(pir|fasta)/)){
	print "-*- WARN $sbrName: fragments not supported for PHD-><DSSP|PIR|FASTA>\n";
	$frag=0; }

				# ------------------------------
    if ($frag){                 # extract fragments?
        @tmp=split(/,/,$frag);$#beg=$#end=0;
        foreach $frag(@tmp){next if ($frag !~ /\-/);$frag=~s/\s//g;
                            ($beg,$end)=split('-',$frag);
                            next if ($beg =~/\D/ || $end =~ /\D/);
			    push(@beg,$beg);push(@end,$end);}}
                                # ------------------------------
                                # DSSP out
    if    ($formOut eq "dssp") {
	($Lok,$msg)=
	    &convPhd2dssp($fileInLoc,$fileOutLoc,$chainLoc,$fhSbr);
	return(0,"*** ERROR $sbrName: failed to convert PHDrdb to $formOut\n".
	       $msg."\n") if (! $Lok);
	push(@fileOut,$fileOutLoc); }

                                # ------------------------------
				# convert to sequence formats
    elsif ($formOut =~ /^(pir|fasta)/){
	($Lok,$msg)=
	    &convPhd2seq($fileInLoc,$fileOutLoc,$formOut,$fhSbr);
	return(0,"*** ERROR $sbrName: failed to convert PHDrdb to $formOut\n".
	       $msg."\n") if (! $Lok);
	push(@fileOut,$fileOutLoc);}

                                # ------------------------------
				# convert to HTML
    elsif ($formOut eq "html"){
	print "xx html : working on it !\n";
	die "*** output format is HTML??? not yet in it!\n";
        if ($#beg>0){           # loop over fragments
            foreach $it (1..$#beg){
                $fileOutTmp=$fileOutLoc;$fileOutTmp=~s/(\.$extOutLoc)/\_$beg[$it]\_$end[$it]$1/;
		($Lok,$id,$seq)=&fastaRdGuide($fileInLoc);
		$tmp{"seq","1"}=substr($seq,$beg[$it],($end[$it]-$beg[$it]+1));
		$tmp{"NROWS"}=  1;$tmp{"id","1"}= $id;
                ($Lok,$msg)=&safWrt($fileOutTmp,%tmp);
                return(0,"*** ERROR $sbrName: failed to convert fasta to $formOut\n"."$msg\n") if (! $Lok);
                push(@fileOut,$fileOutTmp);}}
        else {$fragHere=0;
	      ($Lok,$id,$tmp{"seq","1"})=
		  &fastaRdGuide($fileInLoc);
	      return(0,"*** ERROR $sbrName: failed to convert fasta to $formOut\n"."$msg\n") if (! $Lok);
	      $id=~s/^(\S+).*$/$1/;
	      $tmp{"NROWS"}=  1;$tmp{"id","1"}= $id;
	      ($Lok,$msg)=&safWrt($fileOutLoc,%tmp);
              return(0,"*** ERROR $sbrName: failed to convert fasta to $formOut\n"."$msg\n") if (! $Lok);
	      push(@fileOut,$fileOutLoc);}}
    else {
        return(2,"*** ERROR $sbrName: output option $formOut not supported for $formIn\n");}
    return(1,"ok $sbrName");
}				# end of convPhdGen

#==============================================================================
sub convPir2fasta {
    local($fileInLoc,$fileOutLoc,$fragLoc,$extrLoc,$LshortNamesLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   convPir2fasta               converts PIR to FASTA format
#       in:                     $fileInLoc,$fileOutLoc,$fragLoc,$extrLoc
#       in:                     $fragLoc=n-m    fragment to extract (optional)
#       in:                     $extrLoc=i,j,k  take only sequences i,j,k from PIRmul
#                               NOTE: to leave blank =0, e.g. 
#                               'file.pir,file.f,0,5' would get fifth sequence
#       in:                     $LshortNamesLoc: if 1 names <=15 characters
#       out:                    implicit: file out
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."convPir2fasta";$fhinLoc="FHIN_"."convPir2fasta";
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc!")          if (! defined $fileInLoc);
    return(0,"*** $sbrName: not def fileOutLoc!")         if (! defined $fileOutLoc);
    $fragLoc=0                                            if (! defined $fragLoc);
    $extrLoc=0                                            if (! defined $extrLoc);
    $LshortNamesLoc=0                                     if (! defined $LshortNamesLoc);

    return(0,"*** $sbrName: miss in file '$fileInLoc'!")  if (! -e $fileInLoc);

                                # interpret input
    $num=$extrLoc;# $num=1 if (! $extrLoc);
                                # ------------------------------
    ($Lok,$id,$seq)=            # read PIR
        &pirRdMul($fileInLoc,$num);

    return(0,"*** ERROR $sbrName: failed to read PIRmul ($fileInLoc,$num)\n".
             "***                 found id=$id\n") 
        if (! $Lok || length($seq)<1);
                                # ------------------------------
                                # interpret info
    @id=split(/\n/,$id);@seq=split(/\n/,$seq);
    return(0,"*** ERROR $sbrName: seq=$seq, and id=$id, not matching (differing number)\n") 
        if ($#id != $#seq);
    $tmp{"NROWS"}=$#id;
    foreach $it (1..$#id){$tmp{"id",$it}= $id[$it];
                          $tmp{"seq",$it}=$seq[$it];}
                                # ------------------------------
                                # extract?
    if ($fragLoc){($beg,$end)=split(/-/,$frag);
                  foreach $it (1..$tmp{"NROWS"}){
                      $tmp{"seq",$it}=substr($tmp{"seq",$it},$beg,($end-$beg+1));}}
    $ctres=length($tmp{"seq",1});
				# ------------------------------
				# shorten names?
    if ($LshortNamesLoc){
	undef %tmp2;
	foreach $it (1..$tmp{"NROWS"}){
	    if (length($tmp{"id",$it})<=15) {
		$tmp2{$tmp{"id",$it}}=1;
		next;}
				# too long
	    $id=$tmp{"id",$it};
	    $id=~s/^.*\|//g;	# purge paths
				# purge blanks
	    $id=~s/\s//g        if (length($id)>15);
				# purge extensions
	    $id=~s/\.[a-z]//g   if (length($id)>15);
				# cleave
	    if (length($id)>15){
		$id=substr($id,1,15);}
				# not unique
	    if (defined $tmp2{$id}){
		$id=substr($id,1,12);
		$ct=1;$idtmp=$id.$ct;
		while(defined $tmp2{$idtmp}){
		    ++$ct;
		    last if ($ct>999);}
		$id=$idtmp;}
	    return(0,"*** $sbrName: shoot id=$id, orig=",,", failed shortening\n")
		if (defined $tmp2{$id} || length($id)>15);
	    $tmp2{$id}=1;
	    $tmp{"id",$it}=$id;
	}
	undef %tmp2; }
                                # ------------------------------
                                # write output
    ($Lok,$msg)=
        &fastaWrtMul($fileOutLoc,%tmp);
    return(0,"*** ERROR $sbrName: failed to write FASTAmul ($fileOutLoc)\n".
           "***                 msg=$msg\n") if (! $Lok);
    return(2,"-*- WARN $sbrName: wrong number written\n$msg\n") if ($Lok != 1);
    return(1,"ok $sbrName");
}				# end of convPir2fasta

#==============================================================================
sub convSaf2many {
    local($fileInLoc,$fileOutLoc,$formOutLoc,$fragLoc,$extrLoc,$fhErrSbr,
	  $LdoCompressLoc,$LshortNamesLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   convSaf2many                converts SAF into many formats: saf2msf, saf2fasta, saf2pir
#       in:                     $fileInLoc,$fileOutLoc,$formOutLoc,$fragLoc,$extrLoc,$fhErrSbr
#       in:                     $formOutLoc     format MSF|FASTA|PIR
#       in:                     $fragLoc=n-m    fragment to extract (optional)
#       in:                     $extrLoc=i,j,k  take only sequences i,j,k from PIRmul
#       in:                     NOTE: to leave blank =0, e.g. 
#       in:                           'file.saf,file.f,0,5' would get fifth sequence
#       in:                     $LdoCompressLoc delete insertions in master
#       in:                     $LshortNamesLoc: if 1 names <=15 characters
#       out:                    implicit: file written
#       err:                    (1,'ok'), (0,'message')
#       err:                    e: (1,msg) -> ok
#       err:                    a: (0,msg) -> some arguments missing/files not opened
#       err:                    b: (2,msg) -> no output file written 
#       err:                    b: (3,msg) -> ERROR from msfCheckFormat
#   specification of format     see interpretSeqSaf
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."convSaf2many";$fhinLoc="FHIN_"."convSaf2many";
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc!")          if (! defined $fileInLoc);
    return(0,"*** $sbrName: not def fileOutLoc!")         if (! defined $fileOutLoc);
    return(0,"*** $sbrName: not def formOutLoc!")         if (! defined $formOutLoc);
    $fragLoc=0                                            if (! defined $fragLoc);
    $extrLoc=0                                            if (! defined $extrLoc);
    $LdoCompressLoc=0                                     if (! defined $LdoCompressLoc);
    $LshortNamesLoc=0                                     if (! defined $LshortNamesLoc);

    return(0,"*** $sbrName: miss in file '$fileInLoc'!")  if (! -e $fileInLoc);
                                # interpret input
    $formOutLoc=~tr/[A-Z]/[a-z]/;
    if ($fragLoc){$fragLoc=~s/\s//g;
		  return(0,"*** $sbrName: syntax of fragLoc ($fragLoc) must be :\n".
			 "    'ifir-ilas', where ifir,ilas are integers (or 1-*)\n")
		      if ($fragLoc && $fragLoc !~/[\d\*]\-[\d\*]/);}
    if ($extrLoc){$extrLoc=~s/\s//g;
		  return(0,"*** $sbrName: syntax of extrLoc ($extrLoc) must be :\n".
			 "    'n1,n2,n3-n4', where n* are integers\n")
		      if ($extrLoc && $extrLoc =~/[^0-9\-,]/);
		  @extr=&get_range($extrLoc); 
                  undef %take;
                  foreach $it(@extr){
                      $take{$it}=1;}}
                                # ------------------------------
                                # read file
    ($Lok,$msg,%safIn)=
        &safRd($fileInLoc);

    @nameLoc=split(/,/,$safIn{"names"});
				# ------------------------------
    undef %tmp; $ctTake=0;	# store names for passing variables
    foreach $it (1..$#nameLoc){ 
        next if ($extrLoc && (! defined $take{$it} || ! $take{$it}));
        ++$ctTake; 
	$tmp{"id",$ctTake}= $nameLoc[$it];
        $tmp{"seq",$ctTake}=$safIn{"seq",$it};
    }
    $tmp{"NROWS"}=$ctTake;
    %safIn=%tmp; undef %tmp;
				# ------------------------------
				# compress
				# ------------------------------
    if ($LdoCompressLoc){
	$ctcleave=$ctres=0;
	$lenloc=length($safIn{"seq",1});
				# all 0
	foreach $itprot (1..$safIn{"NROWS"}){
	    $safIn{"new",$itprot}="";
	}
				# loop over all residues
	foreach $itres (1..$lenloc){
	    # is residue
	    if (substr($safIn{"seq",1},$itres,1)=~/^[A-Za-z]/){
		foreach $itprot (1..$safIn{"NROWS"}){
		    $safIn{"new",$itprot}.=substr($safIn{"seq",$itprot},$itres,1);
		}
		++$ctres;
		next;}
				# seems insertion
	    ++$ctcleave;
	}
				# check: sum ok?
	return(0,"*** $sbrName: failed at compressing ncleave=$ctcleave, nresnew=$ctres,".
	       " before=".$lenloc." file=$fileInLoc!")
	    if ($lenloc != ($ctcleave + $ctres));
				# replace by cleaved version
	foreach $itprot (1..$safIn{"NROWS"}){
	    $safIn{"seq",$itprot}=$safIn{"new",$itprot};
	}}

    $ctres=length($safIn{"seq",1});
				# ------------------------------
				# select subsets
				# ------------------------------
    if ($fragLoc){
	($beg,$end)=split("-",$fragLoc);$name=$safIn{"1"};$len=length($safIn{$name});
	$beg=1 if ($beg eq "*"); $end=$len if ($end eq "*");
	if ($len < ($end-$beg+1)){
	    print "-*- WARN $sbrName: $beg-$end not possible, as length of protein=$len\n";}
	else {
	    foreach $it (1..$safIn{"NROWS"}){
		$name=$safIn{"id",$it};
		$safIn{"seq",$it}=substr($safIn{"seq",$it},$beg,($end-$beg+1));
	    }
	}}
				# ------------------------------
				# shorten names?
				# ------------------------------
    if ($LshortNamesLoc){
	undef %safIn2;
	foreach $it (1..$safIn{"NROWS"}){
	    if (length($safIn{"id",$it})<=15) {
		$safIn2{$safIn{"id",$it}}=1;
		next;}
				# too long
	    $id=$safIn{"id",$it};
	    $id=~s/^.*\|//g;	# purge paths
				# purge blanks
	    $id=~s/\s//g        if (length($id)>15);
				# purge extensions
	    $id=~s/\.[a-z]//g   if (length($id)>15);
				# cleave
	    if (length($id)>15){
		$id=substr($id,1,15);}
				# not unique
	    if (defined $safIn2{$id}){
		$id=substr($id,1,12);
		$ct=1;$idsafIn=$id.$ct;
		while(defined $safIn2{$idsafIn}){
		    ++$ct;
		    last if ($ct>999);}
		$id=$idsafIn;}
	    return(0,"*** $sbrName: shoot id=$id, orig=",,", failed shortening\n")
		if (defined $safIn2{$id} || length($id)>15);
	    $safIn2{$id}=1;
	    $safIn{"id",$it}=$id;
	}
	undef %safIn2; }
				# --------------------------------------------------
				# write output
				# --------------------------------------------------
				# write an MSF formatted file
    if    ($formOutLoc eq "msf"){
				# reconvert to what MSF wants...
	foreach $it (1..$safIn{"NROWS"}){$name=$safIn{"id",$it};
					 $tmp{$it}=$name;
					 $tmp{$name}=$safIn{"seq",$it};}
	$tmp{"NROWS"}=$safIn{"NROWS"};
        $tmp{"FROM"}= $fileInLoc; 
        $tmp{"TO"}=   $fileOutLoc;
        $fhout="FHOUT_MSF_FROM_SAF";
        open("$fhout",">$fileOutLoc")  || # open file
            return(0,"*** $sbrName cannot open fileOutLoc=$fileOutLoc\n");
        $Lok=&msfWrt("$fhout",%tmp); # write the file
        close("$fhout"); undef %tmp;}
				# write a FASTA or PIR formatted file
    elsif ($formOutLoc eq "fasta"  || $formOutLoc eq "fastamul" || $formOutLoc eq "saf" || 
	   $formOutLoc eq "pirmul" || $formOutLoc eq "pir" || $formOutLoc eq "gcg"){
        if    ($formOutLoc =~ /^fasta/){
            ($Lok,$msg)=&fastaWrtMul($fileOutLoc,%safIn);}
        elsif ($formOutLoc =~ /^pir/){
            ($Lok,$msg)=&pirWrtMul($fileOutLoc,%safIn);}
        elsif ($formOutLoc eq "saf"){
            ($Lok,$msg)=&safWrt($fileOutLoc,%safIn);}
        elsif ($formOutLoc eq "gcg"){
            ($Lok,$msg)=&gcgWrt($fileOutLoc,$safIn{"id","1"},$safIn{"seq","1"});}
        return(0,"*** ERROR $sbrName: failed in $formOutLoc ($fileOutLoc)\n".$msg."\n") 
	    if (! $Lok);}
    else {
        return(0,"*** $sbrName: output format $formOutLoc not supported\n");}
				# ------------------------------
				# file existing??
    return(2,"*** $sbrName ERROR after write, missing fileOutLoc=$fileOutLoc\n") 
	if (! -e $fileOutLoc);
				# ------------------------------
				# make a basic test of msf format
    if    ($formOutLoc eq "msf"){
        ($Lok,$msg)=
            &msfCheckFormat($fileOutLoc);
        return(3,"$msg"."*** $sbrName ERROR from msfCheckFormat fileOutLoc=$fileOutLoc\n") if (! $Lok);}
				# ------------------------------
    $#safIn=$#nameLoc=0;        # save space
    undef %safIn; undef %nameInBlock; undef %tmp;
    return(1,"$sbrName ok");
}				# end of convSaf2many

#==============================================================================
sub convSeq2fastaPerl {
    local($fileInLoc,$fileOutLoc,$formInLoc,$fragLoc,$LshortNamesLoc)=@_;
    local($outformat,$an,$commandLoc);
#----------------------------------------------------------------------
#   convSeq2fastaPerl           convert all formats to fasta (no fortran)
#       in:                     $fileInLoc,$fileOutLoc,$formInLoc,$fragLoc
#       in:                     $formInLoc: pir, pirmul, gcg, swiss, dssp
#       in:                     $fragLoce = 1-5, fragment from 1 -5 
#       in:                     $LshortNamesLoc: if 1 names <=15 characters
#       out:                    
#       err:                    ok=(1,'ok'), err=(0,'msg')
#----------------------------------------------------------------------
    $sbrName="lib-br:convSeq2fastaPerl";
    return(0,"*** $sbrName: not def fileInLoc!")      if (! defined $fileInLoc);
    return(0,"*** $sbrName: not def fileOutLoc!")     if (! defined $fileOutLoc);
    return(0,"*** $sbrName: not def formInLoc!")      if (! defined $formInLoc);
    $fragLoc=0                                        if (! defined $fragLoc);
    $LshortNamesLoc=0                                 if (! defined $LshortNamesLoc);
				# check existence of files
    return(0,"*** $sbrName: no file '$fileInLoc'!")   if (! -e $fileInLoc);

    $fragLoc=0                  if ($fragLoc !~ /\-/);

				# ------------------------------
				# do conversion
				# ------------------------------
    if    ($formInLoc=~ /^pir/){   # PIR
	($Lok,$msg)=
	    &convPir2fasta($fileInLoc,$fileOutLoc,$fragLoc,$LshortNamesLoc);}
    elsif ($formInLoc=~ /^swiss/){ # SWISS-PROT
	($Lok,$msg)=
	    &convSwiss2fasta($fileInLoc,$fileOutLoc,$fragLoc,$LshortNamesLoc);}
    elsif ($formInLoc eq "gcg"){   # GCG
	($Lok,$msg)=
	    &convGcg2fasta($fileInLoc,$fileOutLoc,$fragLoc,$LshortNamesLoc);}
    else {
	return(&errSbr("format $formInLoc to FASTA not supported"));}
    return(&errSbrMsg("failed converting format=$formInLoc ($fileInLoc,$fileOutLoc,$fragLoc)",
		      $msg))    if (! $Lok);

    return(1,"ok $sbrName");
}				# end of convSeq2fastaPerl

#==============================================================================
sub convSeq2seq {
    local($fileInLoc,$formInLoc,$fileOutLoc,$formOutLoc,$frag,$fileScreenLoc,$fhTraceLoc)=@_;
    local($outformat,$an,$commandLoc);
#----------------------------------------------------------------------
#   convSeq2seq                 convert all sequence-only formats to sequence only
#       in:                     $exeConvSeq,$fileIn,$fileOut,$formOutLoc,$frag,$fileScreen,$fhTraceLoc
#       in:                     $formOutLoc=  'FASTA|GCG|PIR'
#       in:                     $frage = 1-5, fragment from 1 -5 
#       out:                    file
#       err:                    ok=(1,'ok'), err=(0,'msg')
#----------------------------------------------------------------------
    $sbrName="lib-br:convSeq2seq";
    $allow="fasta|pir|gcg";
    return(0,"*** $sbrName: not def fileInLoc!")        if (! defined $fileInLoc);
    return(0,"*** $sbrName: not def formInLoc!")        if (! defined $formInLoc);
    return(0,"*** $sbrName: not def fileOutLoc!")       if (! defined $fileOutLoc);
    return(0,"*** $sbrName: not def formOutLoc!")       if (! defined $formOutLoc);
    $fileScreenLoc=0                                    if (! defined $fileScreenLoc);
    $frag=0                                             if (! defined $frag);
    $fhTraceLoc="STDOUT"                                if (! defined $fhTraceLoc);
				# check existence of files
    return(0,"*** $sbrName: no file '$fileInLoc'!")     if (! -e $fileInLoc);
                                # check format
    $formInLoc=~tr/[A-Z]/[a-z]/;
    $formOutLoc=~tr/[A-Z]/[a-z]/;
    return(0,"*** $sbrName: output format $formOutLoc not supported\n")
        if ($formOutLoc !~ /$allow/);
    $anFormOut=substr($formOutLoc,1,1);$anFormOut=~tr/[a-z]/[A-Z]/;
    $frag=0 if ($frag !~ /\-/);
				# ------------------------------
				# get input
    $Lok=$id=0;
    if    ($formInLoc =~/swiss/) { ($Lok,$id,$seq)=&swissRdSeq($fileInLoc); }
    elsif ($formInLoc =~/fasta/) { ($Lok,$id,$seq)=&fastaRdMul($fileInLoc,1); }
    elsif ($formInLoc =~/pir/)   { ($Lok,$id,$seq)=&pirRdMul($fileInLoc,1); }
    elsif ($formInLoc =~/gcg/)   { ($Lok,$id,$seq)=&gcgRdMul($fileInLoc); }
    return(&errSbrMsg("input format=$formInLoc, not valid!\n"))
	if (! $Lok && ! $id);
    return(&errSbrMsg("problem reading input format=$formInLoc, file=$fileInLoc!\n"))
	if (! $Lok);
                                # ------------------------------
    if ($frag){                 # extract fragments?
        $frag=~s/\s//g;
        ($beg,$end)=split('-',$frag);
        if ($beg =~/^\d+$/ && $end =~ /^\d+$/) {
	    $seq=substr($seq,$beg,(1+$end-$beg));}}
	    
				# ------------------------------
				# write output
    $Lok=$msg=0;
    if    ($formOutLoc =~/fasta/) { ($Lok,$msg)=&fastaWrt($fileOutLoc,$id,$seq); }
    elsif ($formOutLoc =~/pir/)   { ($Lok,$msg)=&pirWrtOne($fileOutLoc,$id,$seq); }
    elsif ($formOutLoc =~/gcg/)   { ($Lok,$msg)=&gcgWrt($fileOutLoc,$id,$seq); }
    return(&errSbrMsg("output format=$formOutLoc not digested!\n".$id."\n"))
	if (! $Lok && ! $msg);
    return(&errSbrMsg("problem writing output format=$formOutLoc, file=$fileOutLoc!\n"))
	if (! $Lok);

    return(1,"ok $sbrName");
}				# end of convSeq2seq

#==============================================================================
sub convSeq2seqOld {
    local($exeConvSeqLoc,$fileInLoc,$fileOutLoc,$formOutLoc,$frag,$fileScreenLoc,$fhTraceLoc)=@_;
    local($outformat,$an,$commandLoc);
#----------------------------------------------------------------------
#   convSeq2seqOld                 convert all sequence-only formats to sequence only
#       in:                     $exeConvSeq,$fileIn,$fileOut,$formOutLoc,$frag,$fileScreen,$fhTraceLoc
#       in:                     $formOutLoc=  'FASTA|GCG|PIR'
#       in:                     $frage = 1-5, fragment from 1 -5 
#       out:                    file
#       err:                    ok=(1,'ok'), err=(0,'msg')
#----------------------------------------------------------------------
    $sbrName="lib-br:convSeq2seqOld";
    $allow="fasta|pir|gcg";
    return(0,"*** $sbrName: not def exeConvSeqLoc!")    if (! defined $exeConvSeqLoc);
    return(0,"*** $sbrName: not def fileInLoc!")        if (! defined $fileInLoc);
    return(0,"*** $sbrName: not def fileOutLoc!")       if (! defined $fileOutLoc);
    return(0,"*** $sbrName: not def formOutLoc!")       if (! defined $formOutLoc);
    $fileScreenLoc=0                                    if (! defined $fileScreenLoc);
    $frag=0                                             if (! defined $frag);
    $fhTraceLoc="STDOUT"                                   if (! defined $fhTraceLoc);
				# check existence of files
    return(0,"*** $sbrName: no exe  '$exeConvSeqLoc'!") if (! -e $exeConvSeqLoc);
    return(0,"*** $sbrName: no file '$fileInLoc'!")     if (! -e $fileInLoc);
                                # check format
    $formOutLoc=~tr/[A-Z]/[a-z]/;
    return(0,"*** $sbrName: output format $formOutLoc not supported\n")
        if ($formOutLoc !~ /$allow/);
    $anFormOut=substr($formOutLoc,1,1);$anFormOut=~tr/[a-z]/[A-Z]/;
    $frag=0 if ($frag !~ /\-/);
                                # ------------------------------
    if ($frag){                 # extract fragments?
        $frag=~s/\s//g;
        ($beg,$end)=split('-',$frag);
        $frag=0 if ($beg =~/\D/ || $end =~ /\D/);}

				# ------------------------------
				# call FORTRAN program
    $cmd=              "";      # eschew warnings
    $an2=              "N";     # write another format?
    if ($frag){
        $an1=          "Y";     # do fragment
        $anF=          "$beg $end"; # answer for fragment
        eval "\$cmd=\"$exeConvSeqLoc,$fileInLoc,$anFormOut,$an1,$anF,$fileOutLoc,$an2,\"";
        ($Lok,$msg)=
            &sysRunProg($cmd,$fileScreenLoc,$fhTraceLoc);}
    else {
        $an1=          "N";     # no fragment
        eval "\$cmd=\"$exeConvSeqLoc,$fileInLoc,$anFormOut,$an1,$fileOutLoc,$an2,\"";
        ($Lok,$msg)=
            &sysRunProg($cmd,$fileScreenLoc,$fhTraceLoc);}

    return(&errSbrMsg("no output from FORTRAN convert_seq, could not run_program cmd=$cmd\n",
		      $msg)) if (! $Lok || ! -e $fileOutLoc);
    return(1,"ok $sbrName");
}				# end of convSeq2seqOld

#==============================================================================
sub convSwiss2fasta {
    local($fileInLoc,$fileOutLoc,$fragLoc,$LshortNamesLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   convSwiss2fasta             converts SWISS-PROT to FASTA format
#       in:                     $fileInLoc,$fileOutLoc,$fragLoc
#       in:                     $fragLoc=n-m    fragment to extract (optional)
#       in:                     $LshortNamesLoc: if 1 names <=15 characters
#       out:                    implicit: file out
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."convSwiss2fasta";$fhinLoc="FHIN_"."convSwiss2fasta";
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc!")          if (! defined $fileInLoc);
    return(0,"*** $sbrName: not def fileOutLoc!")         if (! defined $fileOutLoc);
    $fragLoc=0                                            if (! defined $fragLoc);
    $LshortNamesLoc=0                                     if (! defined $LshortNamesLoc);

    return(0,"*** $sbrName: miss in file '$fileInLoc'!")  if (! -e $fileInLoc);

                                # ------------------------------
    ($Lok,$id,$seq)=            # read SWISS
        &swissRdSeq($fileInLoc);
    return(0,"*** ERROR $sbrName: failed to read SWISS ($fileInLoc)\n".
             "***                 found id=$id\n") 
        if (! $Lok || length($seq)<1);

    undef %tmp;
    $tmp{"id","1"}= $id;
    $tmp{"seq","1"}=$seq;
    $tmp{"NROWS"}=1;
                                # ------------------------------
                                # extract?
    if ($fragLoc){($beg,$end)=split(/-/,$frag);
                  foreach $it (1..$tmp{"NROWS"}){
                      $tmp{"seq",$it}=substr($tmp{"seq",$it},$beg,($end-$beg+1));}}

    $ctres=length($tmp{"seq",1});
				# ------------------------------
				# shorten names?
    if ($LshortNamesLoc){
	undef %tmp2;
	foreach $it (1..$tmp{"NROWS"}){
	    if (length($tmp{"id",$it})<=15) {
		$tmp2{$tmp{"id",$it}}=1;
		next;}
				# too long
	    $id=$tmp{"id",$it};
	    $id=~s/^.*\|//g;	# purge paths
				# purge blanks
	    $id=~s/\s//g        if (length($id)>15);
				# purge extensions
	    $id=~s/\.[a-z]//g   if (length($id)>15);
				# cleave
	    if (length($id)>15){
		$id=substr($id,1,15);}
				# not unique
	    if (defined $tmp2{$id}){
		$id=substr($id,1,12);
		$ct=1;$idtmp=$id.$ct;
		while(defined $tmp2{$idtmp}){
		    ++$ct;
		    last if ($ct>999);}
		$id=$idtmp;}
	    return(0,"*** $sbrName: shoot id=$id, orig=",,", failed shortening\n")
		if (defined $tmp2{$id} || length($id)>15);
	    $tmp2{$id}=1;
	    $tmp{"id",$it}=$id;
	}
	undef %tmp2; }
                                # ------------------------------
                                # write output
    ($Lok,$msg)=
        &fastaWrtMul($fileOutLoc,%tmp);
    return(0,"*** ERROR $sbrName: failed to write FASTAmul ($fileOutLoc)\n".
           "***                 msg=$msg\n") if (! $Lok);
    return(2,"-*- WARN $sbrName: wrong number written\n$msg\n") if ($Lok != 1);
    return(1,"ok $sbrName");
}				# end of convSwiss2fasta

#==============================================================================
sub dsspGetChain {
    local ($fileIn,$chainIn,$begIn,$endIn) = @_ ;
    local ($Lread,$sbrName,$fhin,$aa,$aa2,$seq,$seqC,$chainRd,$pos);
    $[=1;
#----------------------------------------------------------------------
#   dsspGetChain                extracts all chains from DSSP
#       in:                     $file
#       out:                    $Lok,$tmp{"chains"}='C,D,...'
#       out:                         $tmp{"$chain","beg"},$tmp{"$chain","end"},
#----------------------------------------------------------------------
    $sbrName = "lib-br:dsspGetChain" ;$fhin="fhinDssp";
    open($fhin,$fileIn) ||
        return(0,"*** ERROR $sbrName: failed to open input $fileIn\n");
				#--------------------------------------------------
    while ( <$fhin> ) {		# read in file
	last if ( /^  \#  RESIDUE/ ); }	# skip anything before data...
    undef %tmp;
    $chainNow=$chains="";
    while ( <$fhin> ) {		# read chain
	$Lread=1;
	$chainRd=substr($_,12,1); 
	$resRd=  substr($_,14,1); 
	next if ($resRd eq "!");
	$chainRd="*" if ($chainRd eq " ");
				# strange
	$pos=     substr($_,7,5); $pos=~s/\s//g;
	$posdssp= substr($_,1,5); $posdssp=~s/\s//g;

	if (defined $tmp{$chainRd} && 
	    $chainRd ne $chainNow){
	    print 
		"--- WARN $sbrName: problem: chainRd=$chainRd, ",
		"posPDB=$pos, posDSSP=$posdssp, res=$resRd, now=$chainNow, will be skipped\n";
	    next;}

	if ($chainRd ne $chainNow){
	    $tmp{$chainRd}=1;
	    $chainNow=     $chainRd;
	    $chains.=      $chainRd.",";
	    $tmp{$chainRd,"begpdb"}=$pos;
	    $tmp{$chainRd,"beg"}=   $posdssp;
	}
	else                      {
	    $tmp{$chainRd,"endpdb"}=$pos;
	    $tmp{$chainRd,"end"}=   $posdssp;
	}}
    close($fhin);
    $chains=~s/^,*|,*$//g;
				# clean up strange bits
    $tmp{"chains"}="";
    foreach $tmp (split(/,/,$chains)){
	next if (! defined $tmp{$tmp,"beg"});
	next if (! defined $tmp{$tmp,"end"});
				# too short
	next if ( ($tmp{$tmp,"end"} - $tmp{$tmp,"beg"}) < 5);
	$tmp{"chains"}.=$tmp.",";
    }

    $tmp{"chains"}=~s/,*$//g;

    return(1,%tmp);
}                               # end of: dsspGetChain 

#==============================================================================
sub dsspRdSeq {
    local ($fileIn,$chainIn,$begIn,$endIn) = @_ ;
    local ($Lread,$sbrName,$fhin,$aa,$aa2,$seq,$seqC,$chainRd,$pos);
    $[=1;
#----------------------------------------------------------------------
#   dsspRdSeq                   extracts the sequence from DSSP
#       in:                     $file,$chain,$beg,$end
#       in:                     for wild cards beg="", end=""
#       out:                    $Lok,$seq,$seqC (second replaced a-z to C)
#----------------------------------------------------------------------
    $sbrName = "lib-br:dsspRdSeq" ;$fhin="fhinDssp";
    &open_file("$fhin","$fileIn") ||
        return(0,"*** ERROR $sbrName: failed to open input $fileIn\n");
				#----------------------------------------
				# extract input
    if (defined $chainIn && length($chainIn)>0 && $chainIn=~/[A-Z0-9]/){
	$chainIn=~s/\s//g;$chainIn =~tr/[a-z]/[A-Z]/; }else{$chainIn = "*" ;}
    $begIn = "*" if (! defined $begIn || length($begIn)==0); $begIn=~s/\s//g;;
    $endIn = "*" if (! defined $endIn || length($endIn)==0); $endIn=~s/\s//g;;
				#--------------------------------------------------
				# read in file
    $ctline=0;
    while ( <$fhin> ) { 
	++$ctline;
	last if ( /^  \#  RESIDUE/ ); }	# skip anything before data...
    $seq=$seqC="";
    while ( <$fhin> ) {		# read sequence
	++$ctline;
	$Lread=1;
	if (length($_)<12){
	    print "*** fatal ERROR in $fileIn: line=$ctline:$_!\n";die;}
	$chainRd=substr($_,12,1); 
	$pos=    substr($_,7,5); $pos=~s/\s//g;

	next  if (($chainRd ne "$chainIn" && $chainIn ne "*" ) || # check chain
                  ($begIn ne "*"  && $pos < $begIn) || # check begin
                  ($endIn ne "*"  && $pos > $endIn)) ; # check end

	$aa=substr($_,14,1);
	$aa2=$aa;if ($aa2=~/[a-z]/){$aa2="C";}	# lower case to C
	$seq.=$aa;$seqC.=$aa2; } close ($fhin);
    return(1,$seq,$seqC) if (length($seq)>0);
    return(0);
}                               # end of: dsspRdSeq 

#===============================================================================
sub dsspWrtFromPhd {
    local ($fileOutLoc,$id_in)=@_;
    local ($it,$fhoutLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   dsspWrtFromPhd                       
#       in:                     $fileOutLoc
#       in GLOBAL:              @NUM, @SEQ, @SEC(HE ), @ACC, @RISEC, @RIACC
#       in GLOBAL:              $CHAIN
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."dsspWrtFromPhd"; $fhoutLoc="FHOUT_"."dsspWrtFromPhd";
    
				# ------------------------------
				# check arguments
    return(&errSbr("not def fileOutLoc!"))          if (! defined $fileOutLoc);
#    return(&errSbr("not def !"))          if (! defined $);
#    return(&errSbr("miss in file '$fileInLoc'!"))  if (! -e $fileInLoc);

				# chain identifier
    $CHAIN=" "                  if (! defined $CHAIN || 
				    length($CHAIN) != 1);

				# ------------------------------
				# open new file
    &open_file("$fhoutLoc",">$fileOutLoc") || 
	return(&errSbr("fileOutLoc=$fileOutLoc, not created"));

				# ------------------------------
				# DSSP header
    print $fhoutLoc 
	"**** SECONDARY STRUCTURE DEFINITION BY THE PROGRAM DSSP, here PHD prediction\n",
	"REFERENCE  BURKHARD ROST (1996) METHODS IN ENZYMOLOGY, 266, 525-539\n",
	"HEADER     $id_in \n",
	"COMPND        \n",
	"SOURCE        \n",
	"AUTHOR        \n",
	"  \#  RESIDUE AA STRUCTURE BP1 BP2  ACC   N-H-->O  O-->H-N  N-H-->O  O-->H-N    TCO  KAPPA ALPHA  PHI   PSI    X-CA   Y-CA   Z-CA  \n";

				# ------------------------------
				# body
				# ------------------------------
    for ($it=1; $it<=$#SEC; ++$it) {
				# defaults
	$num=$it; $riacc=0; $risec=0;
	$seq="U"; $sec="U"; $acc=999;
				# fill in
	$num=  $NUM[$it]        if (defined $NUM[$it]);
	$seq=  $SEQ[$it]        if (defined $SEQ[$it]);
	$sec=  $SEC[$it]        if (defined $SEC[$it]);
	$acc=  $ACC[$it]        if (defined $ACC[$it]);
	$risec=$RISEC[$it]      if (defined $RISEC[$it]);
	$riacc=$RIACC[$it]      if (defined $RIACC[$it]);
				# ERROR messages
	print "*** ERROR $sbrName: it=$it, SEQ not defined\n" if ($seq eq "U"  );
	print "*** ERROR $sbrName: it=$it, SEC not defined\n" if ($sec eq "U"  );
	print "*** ERROR $sbrName: it=$it, ACC not defined\n" if ($acc eq "999");
				# write it
	printf $fhoutLoc 
	    " %4d %4d %1s %1s  %1s           0   0  %3d    %1d  %1d\n",
	    $num, $num, $CHAIN, $seq, $sec, $acc, $risec, $riacc;
    }
    close($fhoutLoc);
    return(1,"ok");
}				# end of dsspWrtFromPhd

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

#==============================================================================
sub fastaRdGuide {
    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   fastaRdGuide                reads first sequence in list of FASTA format
#       in:                     $fileInLoc,$fhErrSbr
#       out:                    0|1,$id,$seq
#       err:                    ok=(1,id,seq), err=(0,'msg',)
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."fastaRdGuide";$fhinLoc="FHIN"."$sbrName";

    $Lok=       &open_file("$fhinLoc","$fileInLoc");
    return(0,"*** ERROR $sbrName: old '$fileInLoc' not opened\n"," ") if (! $Lok);
    $ct=0;$seq="";
    while (<$fhinLoc>) {
	$_=~s/\n//g;
	if ($_=~/^\s*>\s*(.+)$/){
	    ++$ct;
	    last if ($ct>1);
	    $id=$1;$id=~s/[\s\t]+/ /g;
#	    $id=~s/^[^A-Za-z0-9]*|[^A-Za-z0-9]*$//g;
	    next;}
	$seq.="$_";}
    $seq=~s/\s//g;
    return(0,"*** ERROR $sbrName: no guide sequence found\n"," ") if (length($seq)<1);
    return(1,$id,$seq);
}				# end of fastaRdGuide

#===============================================================================
sub fastaRdMul {
    local($fileInLoc,$rd) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   fastaRdMul                  reads many sequences in FASTA db
#       in:                     $fileInLoc,$rd with:
#                               $rd = '1,5,6',   i.e. list of numbers to read
#                               $rd = 'id1,id2', i.e. list of ids to read
#                               NOTE: numbers faster!!!
#       out:                    1|0,$id,$seq (note: many ids/seq separated by '\n'
#       err:                    ok=(1,id,seq), err=(0,'msg')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:fastaRdMul";$fhinLoc="FHIN_"."$sbrName";

    &open_file("$fhinLoc","$fileInLoc") ||
	return(0,"*** ERROR $sbrName: old '$fileInLoc' not opened\n"," ");

    undef %tmp;
    if (! defined $rd) {
	$LisNumber=1;
	$rd=0;}
    elsif ($rd !~ /[^0-9\,]/){ 
	@tmp=split(/,/,$rd); 
	$LisNumber=1;
	foreach $tmp(@tmp){$tmp{$tmp}=1;}}
    else {$LisNumber=0;
	  @tmp=split(/,/,$rd); }
    
    $ct=$ctRd=0;
    while (<$fhinLoc>) {
	$_=~s/\n//g;
	if ($_=~/^\s*>\s*(.+)$/){ # line with id
	    ++$ct;$Lread=0;
	    last if ($rd && $ctRd==$#tmp); # fin if all found
	    next if ($rd && $LisNumber && ! defined $tmp{$ct});
	    $id=$1;$id=~s/\s\s*/ /g;$id=~s/^[^A-Za-z0-9]*|[^A-Za-z0-9]*$//g;
	    $Lread=1 if ( ($LisNumber && defined $tmp{$ct})
			 || $rd == 0);

	    if (! $Lread){	# go through all ids
		foreach $tmp(@tmp){
		    next if ($tmp !~/$id/);
		    $Lread=1;	# does match, so take
		    last;}}
	    next if (! $Lread);

	    ++$ctRd;
	    $tmp{"$ctRd","id"}=$id;
	    $tmp{"$ctRd","seq"}="";}
	elsif ($Lread) {	# line with sequence
	    $tmp{"$ctRd","seq"}.="$_";}}

    $seq=$id="";		# join to long strings
    foreach $it (1..$ctRd) { $id.= $tmp{"$it","id"}."\n";
			     $tmp{"$it","seq"}=~s/\s//g;
			     $seq.=$tmp{"$it","seq"}."\n";}
    $#tmp=0;			# save memory
    undef %tmp;			# save memory
    return(0,"*** ERROR $sbrName: file=$fileInLoc, nali=$ct, wanted: (rd=$rd)\n"," ") 
        if (length($seq)<1);
    return(1,$id,$seq);
}				# end of fastaRdMul

#===============================================================================
sub fastaWrt {
    local($fileOutLoc,$id,$seqLoc) = @_ ;
    local($sbrName,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   fastaWrt                    writes a sequence in FASTA format
#       in:                     $fileOut,$id,$seq (one string)
#       out:                    
#       err:                    ok=(1,'ok'), err=(0,'msg')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:fastaWrt";$fhoutLoc="FHOUT_"."$sbrName";
#    print "yy into write seq=$seqLoc,\n";

    &open_file("$fhoutLoc",">$fileOutLoc") ||
        return(0,"*** ERROR $sbrName: '$fileOutLoc' not opened for write\n");
    print $fhoutLoc ">$id\n";
    for($it=1;$it<=length($seqLoc);$it+=50){
	foreach $it2 (0..4){
	    last if (($it+10*$it2)>=length($seqLoc));
	    printf $fhoutLoc " %-10s",substr($seqLoc,($it+10*$it2),10);}
	print $fhoutLoc "\n";}
    close($fhoutLoc);
    return(1,"ok $sbrName");
}				# end of fastaWrt

#==============================================================================
sub fastaWrtMul {
    local($fileOutLoc,%tmp) = @_ ;
    local($sbrName,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   fastaWrtMul                 writes a list of sequences in FASTA format
#       in:                     $fileOut,$tmp{} with:
#       in:                     $tmp{"NROWS"}      number of sequences
#       in:                     $tmp{"id",$ct}   id for sequence $ct
#       in:                     $tmp{"seq",$ct}  seq for sequence $ct
#       out:                    file
#       err:                    err  -> 0,message
#       err:                    ok   -> 1,ok
#       err:                    warn -> 2,not enough written
#-------------------------------------------------------------------------------
    $sbrName="lib-br:fastaWrtMul";$fhoutLoc="FHOUT_"."$sbrName";

    return(0,"*** ERROR $sbrName: no tmp{NROWS} defined\n") if (! defined $tmp{"NROWS"});
    &open_file("$fhoutLoc",">$fileOutLoc") ||
        return(0,"*** ERROR $sbrName: '$fileOutLoc' not opened for write\n");

    $ctOk=0; 
    foreach $itpair (1..$tmp{"NROWS"}){
        next if (! defined $tmp{"id",$itpair} || ! defined $tmp{"seq",$itpair});
        ++$ctOk;
                                # some massage
        $tmp{"id",$itpair}=~s/[\s\t\n]+/ /g;
        $tmp{"seq",$itpair}=~s/[\s\t\n]+//g;
                                # write
        print $fhoutLoc ">",$tmp{"id",$itpair},"\n";
	$lenHere=length($tmp{"seq",$itpair});
        for($it=1; $it<=$lenHere; $it+=50){
	    $tmpWrt=      "";
            foreach $it2 (0..4){
		$itHere=($it + 10*$it2);
                last if ( $itHere >= $lenHere);
		$nchunk=10; 
		$nchunk=1+($lenHere-$itHere)  if ( (10 + $itHere) > $lenHere);
		$tmpWrt.= sprintf(" %-10s",substr($tmp{"seq",$itpair},$itHere,$nchunk)); 
	    }
	    print $fhoutLoc $tmpWrt,"\n";
	}
    }
    close($fhoutLoc);
    return(0,"*** ERROR $sbrName: no sequence written\n")               
	if (! $ctOk);
    return(2,"-*- WARN $sbrName: wrote fewer sequences than expected\n") 
	if ($ctOk!=$tmp{"NROWS"});
    return(1,"ok $sbrName");
}				# end of fastaWrtMul

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
sub gcgRd {
    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   gcgRd                       reads sequence in GCG format
#       in:                     $fileInLoc
#       out:                    1|0,$id,$seq 
#       err:                    ok=(1,id,seq), err=(0,'msg')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:gcgRd";$fhinLoc="FHIN_"."$sbrName";

    &open_file("$fhinLoc","$fileInLoc") ||
	return(0,"*** ERROR $sbrName: old '$fileInLoc' not opened\n"," ");

    $seq="";
    while (<$fhinLoc>) {
	$_=~s/\n//g;$line=$_;
	if ($line=~/^\s*(\S+)\s*from\s*:/){
	    $id=$1;
	    next;}
	next if ($line !~ /^\s*\d+\s+(.*)$/);
	$tmp=$1;$tmp=~s/\s//g;
	$seq.=$tmp;}close($fhinLoc);

    return(0,"*** ERROR $sbrName: file=$fileInLoc, no sequence found\n") if (length($seq)<1);
    return(1,$id,$seq);
}				# end of gcgRd

#===============================================================================
sub gcgWrt {
    local($fileOutLoc,$idLoc,$seqLoc) = @_ ;
    local($sbrName,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   gcgWrt                      writes one sequence in GCG format
#       in:                     $fileOut,$id,$seq,
#       out:                    file
#       err:                    err  -> 0,message
#       err:                    ok   -> 1,ok
#-------------------------------------------------------------------------------
    $sbrName="lib-br:gcgWrt";$fhoutLoc="FHOUT_"."$sbrName";

    return(0,"*** ERROR $sbrName: no seq defined\n") if (! defined $seqLoc);
    &open_file("$fhoutLoc",">$fileOutLoc") ||
        return(0,"*** ERROR $sbrName: '$fileOutLoc' not opened for write\n");
#....,....1....,....2....,....3....,....4....,....5....,....6....,....7
#1ppt.f from:    1 to:   36
# 
#1ppt
# 1ppt.gcg          Length:   36   24-Feb-99  Check: 2818 ..
# 
#       1  GPSQPTYPGD DAPVEDLIRF YDNLQQYLNV VTRHRY
 

                                # some massage
    $idLoc=~s/[\s\t\n]+/ /g;
    $seqLoc=~s/[\s\t\n]+//g;
                                # write
    printf $fhoutLoc "%-s from: %5d to:%5d\n",$idLoc,1,length($seqLoc);
    print  $fhoutLoc "\n";
    print  $fhoutLoc $idLoc,"\n";
    printf $fhoutLoc 
	" %-s Length:%5d   11-Jul-99 Check: 2818 ..\n",$fileOutLoc,length($seqLoc);
    print  $fhoutLoc "\n";

				# ------------------------------
				# sequence
    $len=length($seqLoc);
    $num=1+int($len/50);
    $lenSub=10;
    foreach $it (1..$num) {
	$beg=($it-1)*50+1;
	$end=$it*50;
	last if ($beg > $len);
	printf $fhoutLoc "%8d ",$beg;
	foreach $it2 (1..5) {
	    $beg2=$beg+($it2-1)*10;
	    last if ($beg2 > $len);
	    $tmp=1+$len-$beg2;
	    $lenSub=$tmp        if ($tmp < 10);
	    print $fhoutLoc " ",substr($seqLoc,$beg2,$lenSub);
	    last if ($lenSub < 10); }
	print $fhoutLoc "\n\n"; }
    close($fhoutLoc);
    return(0,"*** ERROR $sbrName: no sequence written\n")               
	if (! -e $fileOutLoc);
    return(1,"ok $sbrName");
}				# end of gcgWrt

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
	print 
	    "*** ERROR in get_range: argument: range=$range_txt, nall=$nall, not digestable\n"; 
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

#==============================================================================
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

#==============================================================================
sub getDistanceNewCurveIde {
    local($laliLoc)=@_; local($expon,$loc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getDistanceNewCurveIde      out= pide value for new curve
#       in:                     $lali
#       out:                    $pide
#                               pide= 510 * L ^ { -0.32 (1 + e ^-(L/1000)) }
#-------------------------------------------------------------------------------
    $sbrName="lib-br:getDistanceNewCurveIde";
    return(0,"*** ERROR $sbrName: lali not defined \n") if (! defined $laliLoc);
    return(0,"*** ERROR $sbrName: '$laliLoc' = alignment length??\n") 
	if (length($laliLoc)<1 || $laliLoc=~/[^0-9.]/);

    $expon= - 0.32 * ( 1 + exp (-$laliLoc/1000) );
    $loc= 510 * $laliLoc ** ($expon);
    $loc=100 if ($loc>100);     # saturation
    return($loc,"ok $sbrName");
}				# end of getDistanceNewCurveIde

#==============================================================================
sub getFileFormatQuick {
    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getFileFormatQuick          quick scan for file format: assumptions
#                               file exists
#                               file is db format (i.e. no list)
#       in:                     file
#       out:                    0|1,format
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."getFileFormatQuick";$fhinLoc="FHIN_"."getFileFormatQuick";
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc!")          if (! defined $fileInLoc);
    return(0,"*** $sbrName: miss in file '$fileInLoc'!")  if (! -e $fileInLoc);
                                # alignments (EMBL 1)
    return(1,"HSSP")         if (&is_hssp($fileInLoc));
    return(1,"STRIP")        if (&is_strip($fileInLoc));
#    return(1,"STRIPOLD")     if (&is_strip_old($fileInLoc));
    return(1,"DSSP")         if (&is_dssp($fileInLoc));
    return(1,"FSSP")         if (&is_fssp($fileInLoc));
                                # alignments (EMBL 1)
    return(1,"DAF")          if (&isDaf($fileInLoc));
    return(1,"SAF")          if (&isSaf($fileInLoc));
                                # alignments other
    return(1,"MSF")          if (&isMsf($fileInLoc));
    return(1,"FASTAMUL")     if (&isFastaMul($fileInLoc));
    return(1,"PIRMUL")       if (&isPirMul($fileInLoc));
                                # sequences
    return(1,"FASTA")        if (&isFasta($fileInLoc));
    return(1,"SWISS")        if (&isSwiss($fileInLoc));
    return(1,"PIR")          if (&isPir($fileInLoc));
    return(1,"GCG")          if (&isGcg($fileInLoc));
    return(1,"PDB")          if (&isPdb($fileInLoc));
                                # PP
    return(1,"PPCOL")        if (&is_ppcol($fileInLoc));
				# NN
    return(1,"NNDB")         if (&is_rdb_nnDb($fileInLoc));
                                # PHD
    return(1,"PHDRDBBOTH")   if (&isPhdBoth($fileInLoc));
    return(1,"PHDRDBACC")    if (&isPhdAcc($fileInLoc));
    return(1,"PHDRDBHTM")    if (&isPhdHtm($fileInLoc));
    return(1,"PHDRDBHTMREF") if (&is_rdb_htmref($fileInLoc));
    return(1,"PHDRDBHTMTOP") if (&is_rdb_htmtop($fileInLoc));
    return(1,"PHDRDBSEC")    if (&isPhdSec($fileInLoc));
                                # RDB
    return(1,"RDB")          if (&isRdb($fileInLoc));
    return(1,"unk");
}				# end of getFileFormatQuick

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

#===============================================================================
sub hsspCorrectNali {
    local($fileInLoc,$fileTmpLoc,$fhErrSbr) = @_ ;
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspCorrectNali             convert_seq makes mistakes in NALI
#                               these are corrected here!
#       in:                     $fileInLoc
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."hsspCorrectNali";
    $fhinLoc="FHIN_"."hsspCorrectNali";$fhoutLoc="FHOUT_"."hsspCorrectNali";
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
    return(&errSbr("not def fileTmpLoc!"))         if (! defined $fileTmpLoc);
#    return(&errSbr("not def !"))          if (! defined $);

    return(&errSbr("no fileIn=$fileInLoc!"))  if (! -e $fileInLoc);


				# open file
    open($fhinLoc,$fileInLoc) || return(&errSbr("fileInLoc=$fileInLoc, not opened"));
				# ------------------------------
    while (<$fhinLoc>) {	# read file
	if    ($_=~/^NALIGN \s+(\d+)/){
	    $nalign=$1;
	}
	elsif ($_=~/^\s+(\d+)\s\:\s/){
	    $itali=$1;
	}
	elsif ($_=~/^\#\# ALIGNMENTS/){
	    last;
	}
    }
    close($fhinLoc);

				# ------------------------------
				# ok?
    if ($itali==$nalign){
	return(1,"ok $sbrName no change");
    }

				# change:
    print $fhErrSbr
	"--- file.hssp ($fileInLoc) NALI=$nalign, itali=$itali-> have to change it!\n"
	    if ($par{"debug"});

				# move files
    $cmd="\\mv ".$fileInLoc." ".$fileTmpLoc;
    ($Lok,$msg)=&sysRunProg($cmd,$fileScreenLoc,$fhSysRunProg);
    return(0,"*** ERROR $sbrName: failed to run system ($cmd)\n".$msg."\n")
	if (! $Lok || ! -e $fileTmpLoc);
    print $fhErrSbr
	"--- $sbrName system '$cmd'\n"
	    if ($par{"debug"});
				# now change
    open($fhinLoc,$fileTmpLoc) || return(&errSbr("in fileTmpLoc=$fileTmpLoc, not opened"));
    open($fhoutLoc,">".$fileInLoc) || return(&errSbr("out fileInLoc=$fileInLoc, not created"));
				# ------------------------------
    while (<$fhinLoc>) {	# read file
	if    ($_=~/^NALIGN \s+(\d+)/){
				# '....,....1....,'
				# 'NALIGN       64'
	    printf $fhoutLoc
		"NALIGN %8d\n",$itali;
	}
	else {
	    print $fhoutLoc $_;
	}
    }
    close($fhinLoc);
    close($fhoutLoc);

    return(1,"ok $sbrName");
}				# end of hsspCorrectNali

#==============================================================================
sub hsspGetChain {
    local ($fileIn) = @_ ;
    local ($fhin,$ifirLoc,$ilasLoc,$tmp1,$tmp2,
	   $chainLoc,$posLoc,$posRd,$chainRd,@cLoc,@pLoc,%rdLoc);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   hsspGetChain                extracts all chain identifiers in HSSP file
#       in:                     $file
#       out:                    $chains (ABC) ,%rdLoc
#                      no chain -> $chains=' '
#       out                        $rdLoc{"NROWS"},$rdLoc{"$ct","chain"},
#       out                        $rdLoc{"$ct","ifir"},$rdLoc{"$ct","ilas"}
#--------------------------------------------------------------------------------
    $fhin="FhInHssp";
    return(0,"no file") if (! -e $fileIn);
    &open_file("$fhin","$fileIn");
    while(<$fhin>){		# until start of data
	last if ($_=~/^ SeqNo/);}
    $chainLoc=$posLoc="";
    while(<$fhin>){
	if ($_=~/^\#/ && (length($chainLoc)>1) ) {
	    $posLoc.="$ifirLoc-$ilasLoc".",";
	    last;}
	$chainRd=substr($_,13,1);
	$aaRd=   substr($_,15,1);
	$posRd=  substr($_,1,6);$posRd=~s/\s//g;
	next if ($aaRd eq "!") ;  # skip over chain break
	if ($chainLoc !~/$chainRd/){	# new chain?
	    $posLoc.=         "$ifirLoc-$ilasLoc"."," if (length($chainLoc)>1);
	    $chainLoc.=       "$chainRd".",";
	    $ifirLoc=$ilasLoc=$posRd;}
	else { 
	    $ilasLoc=$posRd;}
    }close($fhin);
    $chainLoc=~s/^,|,$//g;
    $posLoc=~s/\s//g;$posLoc=~s/^,|,$//g; # purge leading ','
				# now split chains read
    undef %rdLoc; $ctLoc=0;
    @cLoc=split(/,/,$chainLoc);
    @pLoc=split(/,/,$posLoc);

    foreach $itLoc(1..$#cLoc){
	($tmp1,$tmp2)=split(/-/,$pLoc[$itLoc]);
	next if ($tmp2 == $tmp1); # exclude chains of length 1
	++$ctLoc;
	$rdLoc{"NROWS"}=         $ctLoc;
	$rdLoc{"$ctLoc","chain"}=$cLoc[$itLoc];
	$rdLoc{"$ctLoc","ifir"}= $tmp1;
	$rdLoc{"$ctLoc","ilas"}= $tmp2;}
    $chainLoc=~s/,//g;
    return($chainLoc,%rdLoc);
}				# end of hsspGetChain

#==============================================================================
sub hsspGetChainLength {
    local ($fileIn,$chainLoc) = @_ ;
    local ($file_hssp,$ct,$tmp,$beg,$end,$pos);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   hsspGetChainLength          extracts the length of a chain in an HSSP file
#       in:                     hssp_file,chain,
#       out:                    $length,$ifir,$ilas
#--------------------------------------------------------------------------------
    $fileIn=~s/\s//g;$fileIn=~s/\n//g;
    $file_hssp=$fileIn; $Lchain=1; 
    $Lchain=0                   if ($chainLoc eq "*" || ! &is_chain($chainLoc)); 
    if (! -e $file_hssp){
	print "*** ERROR hsspGetChainLength: no HSSP=$fileIn,\n"; 
	return(0,"*** ERROR hsspGetChainLength: no HSSP=$fileIn,");}
    &open_file("FHIN", "$file_hssp") ||
	return(0,"*** ERROR hsspGetChainLength: failed opening HSSP=$fileIn,");

    while ( <FHIN> ) { 
	last if (/^ SeqNo/); }
    $ct=$pos=0;
    while ( <FHIN> ) { 
	last if (/^\#\# /);
	++$pos;$tmp=substr($_,13,1);
	if    ( $Lchain && ($tmp eq $chainLoc) ) { ++$ct; }
	elsif ( ! $Lchain )                      { ++$ct; }
	elsif ( $ct>1 ) {
	    last;}
	$beg=$pos if ($ct==1); } close(FHIN);
    $end=$pos;
    return($ct,$beg,$end);
}				# end of hsspGetChainLength

#==============================================================================
sub hsspRdAli {
    local ($fileInLoc,@want) = @_ ;
    local ($sbrName,$fhinLoc,$tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspRdAli                   reads and writes the sequence of HSSP + 70 alis
#       in:                     $fileHssp (must exist), 
#         @des                  (1) =1, 2, ...,  i.e. number of sequence to be read
#                               (2) = swiss_id1, swiss_id2, i.e. identifiers to read
#                               (3) = all (or undefined)
#                               NOTE: you can give ids AND numbers ('1','paho_chick','2') ..
#                               furthermore:
#                               if @want = 'seq|seqAli|seqNoins'
#                                  only those will be returned (e.g. $tmp{"seq",$ct})
#                               default: all 3!
#       out:                    1|0,$rd{} with: 
#       err:                    (0,$msg)
#                    overall:
#                               $rd{"NROWS"}=          : number of alis, i.e. $#want
#                               $rd{"NRES"}=N          : number of residues in guide
#                               $rd{"SWISS"}='sw1,sw2' : list of swiss-ids read
#                               $rd{"0"}='pdbid'       : id of guide sequence (in file header)
#                               $rd{$it}='sw$ct'     : swiss id of the it-th alignment
#                               $rd{"$id"}='$it'       : position of $id in final list
#                               $rd{"sec","$itres"}    : secondary structure for residue itres
#                               $rd{"acc","$itres"}    : accessibility for residue itres
#                               $rd{"chn","$itres"}    : chain for residue itres
#                    per prot:
#                               $rd{"seqNoins",$ct}=sequences without insertions
#                               $rd{"seqNoins","0"}=  GUIDE sequence
#                               $rd{"seq",$ct}=SEQW  : sequences, with all insertions
#                                                        but NOT aligned!!!
#                               $rd{"seqAli",$ct}    : sequences, with all insertions,
#                                                        AND aligned (all, including guide
#                                                        filled up with '.' !!
#-------------------------------------------------------------------------------
    $sbrName="lib-br:hsspRdAli"; $fhinLoc="FHIN"."$sbrName"; $fhinLoc=~tr/[a-z]/[A-Z]/;
				# file existing?
    if ((! -e $fileInLoc) || (! &is_hssp($fileInLoc))){
	print "*** ERROR $sbrName no HSSP file '$fileInLoc'\n";
	return(0);}
				# ------------------------------
				# HSSP file format settings
    $regexpBegAli=        "^\#\# ALIGNMENTS"; # begin of reading
    $regexpEndAli=        "^\#\# SEQUENCE PROFILE"; # end of reading
    $regexpSkip=          "^ SeqNo"; # skip lines with pattern
    $nmaxBlocks=          100;	# maximal number of blocks considered (=7000 alis!)
    $regexpBegIns=        "^\#\# INSERTION LIST"; # begin of reading insertion list
    
    undef %tmp; undef @seqNo; undef %seqNo;
				# ------------------------------
				# pointers
    undef %ptr_id2num;		# $ptr{xyz}= N   : id=xyz is the Nth ali
    undef @ptr_num2id;		# $ptr[N]=   xyz : Nth ali has id= xyz
    undef @ptr_numWant2numFin;	# $ptr[N]=   M   : the Nth ali is the Mth one in the list
				#                  of all numbers wanted (i.e. = $want[M])
    undef @ptr_numFin2numWant;	# $ptr[M]=   N   : see previous, the other way around!

    $#want=0                    if (! defined @want);
    $LreadAll=0; 
				# ------------------------------
				# digest input
    $#tmp=0; undef %kwd;	# (1) detect keywords
    foreach $tmp (@want){
	if ($tmp=~/^(seq|seqAli|seqNoins)$/){
	    $kwd{$tmp}=1; 
	    next;}
	push(@tmp,$tmp);}

    if (($#want>0) && ($#want == $#tmp) ){ # default keyworkds
	foreach $des ("seq","seqAli","seqNoins"){
	    $kwd{"$des"}=1;}}
    @want=@tmp;
				# (2) all?
    $LreadAll=1                 if ( ! @want || ! $want[1] || ($want[1] eq "all"));
    if (! $LreadAll){		# (3) read some
	$#wantNum=$#wantId=0;
	foreach $want (@want) {
	    if ($want !~ /[^0-9]/){push(@wantNum,$want);} # is number
	    else                  {push(@wantId,$want);}}}  # is id
				# ------------------------------
				# get numbers/ids to read
    ($Lok,%rdHeader)=
	&hsspRdHeader($fileInLoc,"SEQLENGTH","PDBID","NR","ID");
    if (! $Lok){
	print "*** ERROR $sbrName reading header of HSSP file '$fileInLoc'\n";
	return(0);}
    $tmp{"NRES"}= $rdHeader{"SEQLENGTH"};$tmp{"NRES"}=~s/\s//g;
    $tmp{"0"}=    $rdHeader{"PDBID"};    $tmp{"0"}=~s/\s//g;
    $idGuide=     $tmp{"0"};

    $#locNum=$#locId=0;		# store the translation name/number
    foreach $it (1..$rdHeader{"NROWS"}){
	$num=$rdHeader{"NR",$it}; $id=$rdHeader{"ID",$it};
	push(@locNum,$num);push(@locId,$id);
	$ptr_id2num{"$id"}=$num;
	$ptr_num2id[$num]=$id;}
    push(@locNum,"1")           if ($#locNum==0); # nali=1
				# ------------------------------
    foreach $want (@wantId){	# CASE: input=list of names
	$Lok=0;			#    -> add to @wantNum
	foreach $loc (@locId){
	    if ($want eq $loc){$Lok=1;push(@wantNum,$ptr_id2num{"$loc"});
			       last;}}
	if (! $Lok){
	    print "-*- WARNING $sbrName wanted id '$want' not in '$fileInLoc'\n";}}
				# ------------------------------
				# NOW we have all numbers to get
				# sort the array
    @wantNum= sort bynumber (@wantNum);
				# too many wanted
    if (defined @wantNum && ($wantNum[$#wantNum] > $locNum[$#locNum])){
	$#tmp=0; 
	foreach $want (@wantNum){
	    if ($want <= $locNum[$#locNum]){
		push(@tmp,$want)}
	    else {
		print "-*- WARNING $sbrName no $want not in '$fileInLoc'\n";
		exit;
	    }}
	@wantNum=@tmp;}
		
    @wantNum=@locNum if ($LreadAll);
    if ($#wantNum==0){
	print "*** ERROR $sbrName nothing to read ???\n";
	return(0);}
				# sort the array, again
    @wantNum= sort bynumber (@wantNum);
				# ------------------------------
				# assign pointers to final output
    foreach $it (1..$#wantNum){
	$numWant=$wantNum[$it];
	$ptr_numWant2numFin[$numWant]=$it;
	$ptr_numFin2numWant[$it]=     $numWant;}

				# ------------------------------
				# get blocks to take
    $wantLast=$wantNum[$#wantNum];$#wantBlock=0;
    foreach $ctBlock (1..$nmaxBlocks){
	$beg=1+($ctBlock-1)*70;
	$end=$ctBlock*70;
	last if ($wantLast < $beg);
	$Ltake=0;
	foreach $num(@wantNum){
	    if ( ($beg<=$num)&&($num<=$end) ){
		$Ltake=1;
		last;}}
	if ($Ltake){
	    $wantBlock[$ctBlock]=1;}
	else{
	    $wantBlock[$ctBlock]=0;}}
				# writes ids read
    $tmp{"SWISS"}="";
    foreach $it (1..$#wantNum){ $num=$wantNum[$it];
				$tmp{$it}=     $ptr_num2id[$num];
				$tmp{"SWISS"}.=$ptr_num2id[$num].",";} 
    $tmp{"SWISS"}=~s/,*$//g;
    $tmp{"NROWS"}=$#wantNum;

				# ------------------------------------------------------------
				#       
				# NOTATION: 
				#       $tmp{"0",$it}=  $it-th residue of guide sequnec
				#       $tmp{$itali,$it}=  $it-th residue of of ali $itali
				#       note: itali= same numbering as in 1..$#want
				#             i.e. NOT the position in the file
				#             $ptr_numFin2numWant[$itali]=5 may reveal that
				#             the itali-th ali was actually the fifth in the
				#             HSSP file!!
				#             
				# ------------------------------------------------------------

				# --------------------------------------------------
				# read the file finally
				# --------------------------------------------------
    $Lok=&open_file("$fhinLoc","$fileInLoc");
    if (! $Lok){print "*** ERROR $sbrName opening hssp file '$fileInLoc'\n";
		return(0);}
				# ------------------------------
				# move until first alis
				# ------------------------------
    $ctBlock=$Lread=$#takeTmp=0;
    while (<$fhinLoc>){ 
	last if ($_=~/$regexpEndAli/); # ending
	if ($_=~/$regexpBegAli/){ # this block to take?
	    ++$ctBlock;$Lread=0;
	    if ($wantBlock[$ctBlock]){
		$_=~s/^[^0-9]+(\d+) -\s+(\d+).*$//;
		$beg=$1;$end=$2;$Lread=1;
		$#wantTmp=0;	# local numbers
		foreach $num (@wantNum){
		    if ( ($beg<=$num) && ($num<=$end) ){
			$tmp=($num-$beg)+1; 
			print 
			    "*** $sbrName negative number $tmp,$beg,$end,\n" x 3 if ($tmp<1);
			push(@wantTmp,$tmp);}}
		next;}}
	next if (! $Lread);	# move on
	next if ($_=~/$regexpSkip/); # skip line
	$line=$_;
				# --------------------
	if (length($line)<52){	# no alis in line
	    $seqNo=substr($line,1,6);$seqNo=~s/\s//g;
	    if (! defined $seqNo{$seqNo}){
		$seqNo{$seqNo}=1;
		push(@seqNo,$seqNo);}
				# NOTE: $chn,$sec,$acc are returned per residue!
	    if (! defined $tmp{"0","$seqNo"}){
		($seqNo,$pdbNo,
		 $tmp{"chn","$seqNo"},$tmp{"0","$seqNo"},
		 $tmp{"sec","$seqNo"},$tmp{"acc","$seqNo"})=
		     &hsspRdSeqSecAccOneLine($line);}
		    
	    foreach $num(@wantTmp){ # add insertions if no alis
		$pos=                    $num+$beg-1; 
		$posFin=                 $ptr_numWant2numFin[$pos];
		$tmp{"$posFin","$seqNo"}="."; }
	    next;}
				# ------------------------------
				# everything fine, so read !
				# ------------------------------
				# --------------------
				# first the HSSP stuff
	$seqNo=substr($line,1,6);$seqNo=~s/\s//g;
	if (! defined $seqNo{$seqNo}){
	    $seqNo{$seqNo}=1;
	    push(@seqNo,$seqNo);}
				# NOTE: $chn,$sec,$acc are returned per residue!
	if (! defined $tmp{"0","$seqNo"}){
	    ($seqNo,$pdbNo,
	     $tmp{"chn","$seqNo"},$tmp{"0","$seqNo"},
	     $tmp{"sec","$seqNo"},$tmp{"acc","$seqNo"})=
		 &hsspRdSeqSecAccOneLine($line);}
				# --------------------
				# now the alignments
	$alis=substr($line,52); $alis=~s/\n//g;

				# NOTE: @wantTmp has the positions to read in current block,
				#       e.g. want no 75, block=71-90, => 75->4
	foreach $num (@wantTmp){
	    $pos=                        $num+$beg-1; # note: beg=71 in the example above
	    $id=                         $ptr_num2id[$pos];
	    $posFin=                     $ptr_numWant2numFin[$pos];
	    $tmp{"$posFin"}=             $id;
	    $takeTmp[$pos]=              1;
	    print "*** $sbrName neg number $pos,$beg,$num,\n" x 3 if ($pos<1);
	    $tmp{"seq","$posFin"}=       ""     if (! defined $tmp{"seq","$posFin"});
	    if (length($alis) < $num){
		$tmp{"seq","$posFin"}.=  ".";
		$tmp{"$posFin","$seqNo"}=".";}
	    else {
		$tmp{"seq","$posFin"}.=  substr($alis,$num,1);
		$tmp{"$posFin","$seqNo"}=substr($alis,$num,1);}}}
				# ------------------------------
    while (<$fhinLoc>){		# skip over profiles
        last if ($_=~/$regexpBegIns/); } # begin reading insertion list

				# ----------------------------------------
				# store sequences without insertions!!
				# ----------------------------------------
    if (defined $kwd{"seqNoins"} && $kwd{"seqNoins"}){
				# --------------------
	$seq="";		# guide sequence
	foreach $seqNo(@seqNo){
	    $seq.=$tmp{"0","$seqNo"};}
	$seq=~s/[a-z]/C/g;		# small caps to 'C'
	$tmp{"seqNoins","0"}=$seq;
				# --------------------
				# all others (by final count!)
	foreach $it (1..$#wantNum){
	    $seq="";
	    foreach $seqNo(@seqNo){
		$seq.=$tmp{$it,"$seqNo"};}
	    $seq=~s/\s/\./g;	    # fill up insertions
	    $seq=~tr/[a-z]/[A-Z]/;  # small caps to large
	    $tmp{"seqNoins",$it}=$seq;}
    }
				# --------------------------------------------------
				# read insertion list
				# 
				# syntax of insertion list:  
				#    ....,....1....,....2....,....3....,....4
				#    AliNo  IPOS  JPOS   Len Sequence
				#         9    58    59     5 kQLGAEi
				# 
				# --------------------------------------------------
    undef @insMax;		# note: $insMax[$seqNo]=5 means at residue 'seqNo'
    foreach $seqNo (@seqNo){	#       the longest insertion was 5 residues
	$insMax[$seqNo]=0;}
    while (<$fhinLoc>){
	$rd=$_;
	last if ((! defined $kwd{"seqAli"} || ! $kwd{"seqAli"}) &&
		 (! defined $kwd{"seq"}    || ! $kwd{"seq"}) );
	next if ($rd =~ /AliNo\s+IPOS/);  # skip key
	last if ($rd =~ /^\//);	          # end
        next if ($rd !~ /^\s*\d+/);       # should not happen (see syntax)
        $rd=~s/\n//g; $line=$rd;
	$posIns=$rd;		# current insertion from ali $pos
	$posIns=~s/^\s*(\d+).*$/$1/;
				# takeTmp[$pos]=1 if $pos to be read
	next if (! defined $takeTmp[$posIns] || ! $takeTmp[$posIns]);
				# ok -> take
	$line=~s/^\s*|\s*$//g;	# purge leading blanks
	@tmp=split(/\s+/,$line);
	$iposIns=$tmp[2];	# residue position of insertion
	$seqIns= $tmp[5];	# sequence at insertion 'kQLGAEi'
	$nresIns=(length($seqIns) - 2); # number of residues inserted
	$posFin= $ptr_numWant2numFin[$posIns];
				# --------------------------------------------------
				# NOTE: here $tmp{$it,"$seqNo"} gets more than
				#       one residue assigned (ref=11)
				# --------------------------------------------------
				# change 'ACinK' -> 'ACINEWNK'
	$tmp{"$posFin","$iposIns"}=substr($seqIns,1,(length($seqIns)-1));
				# maximal number of insertions
	$insMax[$iposIns]=$nresIns if ($nresIns > $insMax[$iposIns]);
    } close($fhinLoc);
				# end of reading file
				# --------------------------------------------------
    
				# ------------------------------
				# final sequences (not aligned)
				# ------------------------------
    if (defined $kwd{"seq"} && $kwd{"seq"}){
	foreach $it (0..$tmp{"NROWS"}){
	    $seq="";
	    foreach $seqNo(@seqNo){
		$seq.=$tmp{$it,"$seqNo"};}
	    $seq=~s/[\s\.!]//g;	# replace insertions 
	    $seq=~tr/[a-z]/[A-Z]/; # all capitals
	    $tmp{"seq",$it}=$seq; }}
				# ------------------------------
				# fill up insertions
				# ------------------------------
    if (defined $kwd{"seqAli"} && $kwd{"seqAli"}){
	undef %ali;		# temporary for storing sequences
	foreach $it (0..$tmp{"NROWS"}){
	    $ali{$it}="";}	# set for all alis
				# ------------------------------
	foreach $seqNo(@seqNo){	# loop over residues
	    $insMax=$insMax[$seqNo];
				# loop over all alis
	    foreach $it (0..$tmp{"NROWS"}){
				# (1) CASE: no insertion
		if    ($insMax==0){
		    $ali{$it}.=$tmp{$it,"$seqNo"};
		    next;}
				# (2) CASE: insertions
		$seqHere=$tmp{$it,"$seqNo"};
		$insHere=(1+$insMax-length($seqHere));
				# NOTE: dirty fill them in 'somewhere'
				# take first residue
		$ali{$it}.=substr($seqHere,1,1);
				# fill up with dots
		$ali{$it}.="." x $insHere ;
				# take remaining residues (if any)
		$ali{$it}.=substr($seqHere,2) if (length($seqHere)>1); }}
				# ------------------------------
				# now assign to final
	foreach $it (0..$tmp{"NROWS"}){
	    $ali{$it}=~s/\s/\./g; # replace ' ' -> '.'
	    $ali{$it}=~tr/[a-z]/[A-Z]/;	# all capital
	    $tmp{"seqAli",$it}=$ali{$it};}
	undef %ali;		# slim-is-in! 
    }
				# ------------------------------
				# save memory
    foreach $it (0..$tmp{"NROWS"}){
	if ($it == 0){		# guide
	    $id=         $idGuide; }
	else {			# pairs
	    $posOriginal=$ptr_numFin2numWant[$it];
	    $id=         $ptr_num2id[$posOriginal]; }
	$tmp{"$id"}= $id;
        foreach $seqNo (@seqNo){
	    undef $tmp{$it,"$seqNo"};}}
    undef @seqNo;      undef %seqNo;      undef @takeTmp;    undef @idLoc;
    undef @want;       undef @wantNum;    undef @wantId;     undef @wantBlock; 
    undef %rdHeader;   undef %ptr_id2num; undef @ptr_num2id; 
    undef @ptr_numWant2numFin; undef @ptr_numFin2numWant;
    return(1,%tmp);
}				# end of hsspRdAli

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
#                               for prot (e.g. LALI):   $rd{"kwd",$it}
#                               note: for the later number of elements (it) in
#                                     $rd{"NROWS"}
#         special               ID=ID1, $rd{"kwd",$it} existes for ID1 and ID2
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

	$tmp{"ID",$ct}=     $id;
	$tmp{"NR",$ct}=     $ct;
	$tmp{"STRID",$ct}=  $strid;
				# correct for ID = PDBid
	$tmp{"STRID",$ct}=  $id if ($strid=~/^\s*$/ && &is_pdbid($id));
	    
	$tmp{"PROTEIN",$ct}=$end;
	$tmp{"ID1",$ct}=$tmp{"PDBID"};
	$tmp{"ACCNUM",$ct}=$accnum;
				# middle all info
	$#tmp=0;@tmp=split(/\s+/,$mid);
	foreach $_ (@tmp) {$_=~s/\s//g;}

	foreach $des (@kwdHsspHdrLoc){ 
	    next if ( ! defined $ptr{"$des"});
	    next if ( $des =~/^ACCNUM/);
	    $ptr=$ptr{"$des"};
	    $tmp{"$des",$ct}=$tmp[$ptr]; }}close($fhinLoc);
    $tmp{"NROWS"}=$ct;
				# clean up
    $#kwdInLoc=$#kwdDefHsspHdrLoc=$#kwdHsspTopLoc=$#tmp=
	$#kwdDefHsspTopLoc=$#kwdHsspHdrLoc=0;
    undef %ptr;
    return(1,%tmp);
}				# end of hsspRdHeader

#==============================================================================
sub hsspRdSeqSecAccOneLine {
    local ($inLine) = @_ ;
    local ($sbrName,$fhinLoc,$seqNo,$pdbNo,$chn,$seq,$sec,$acc,$tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspRdSeqSecAccOneLine      reads begin of one HSSP line
#-------------------------------------------------------------------------------
    $sbrName="hsspRdSeqSecAccOneLine";

    $seqNo=substr($inLine,1,6);$seqNo=~s/\s//g;
    $pdbNo=substr($inLine,7,5);$pdbNo=~s/\s//g;
    $chn=  substr($inLine,13,1);
    $seq=  substr($inLine,15,1);
    $sec=  substr($inLine,18,1);
    $acc=  substr($inLine,36,4);$acc=~s/\s//g;
    return($seqNo,$pdbNo,$chn,$seq,$sec,$acc)
}				# end of hsspRdSeqSecAccOneLine

#==============================================================================
sub isDaf {
    local ($fileLoc) = @_ ; local ($Lok);
#--------------------------------------------------------------------------------
#   isDaf                       checks whether or not file is in DAF format
#				(i.e. the dirty ali format used for aqua)
#       in:                     $file
#       out:                    1 if is DAF; 0 else
#--------------------------------------------------------------------------------
    open("FHIN_DAF","$fileLoc");
    while (<FHIN_DAF>){	if ($_=~/^\# DAF/){$Lok=1;}
			else            {$Lok=0;}
			last;}close(FHIN_DAF);
    return($Lok);
}				# end of isDaf

#===============================================================================
sub isFasta {
    local ($fileLoc) = @_ ; local ($Lok);
#--------------------------------------------------------------------------------
#   isFasta                     checks whether or not file is in FASTA format 
#                               (first line /^>\w/, second (non white) = AA
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
    $fhinLoc2="FHIN_FASTA";
    open($fhinLoc2,$fileLoc) || return(0);
    $one=(<$fhinLoc2>);
    $two=(<$fhinLoc2>);
    $two=~s/\s|\n//g            if (defined $two);
    close($fhinLoc2);

    return(0)                   if (! defined $two || ! defined $one);
    return(1)                   if ($one =~ /^\s*>\s*\w+/ && 
				    $two !~/[^ABCDEFGHIKLMNPQRSTVWXYZx\.~_!]/);
    return(0);
}				# end of isFasta

#==============================================================================
sub isFastaMul {
    local ($fileLoc) = @_ ; local ($Lok);
#--------------------------------------------------------------------------------
#   isFastaMul                  checks whether more than 1 sequence in FASTA found
#                               (first line /^>\w/, second (non white) = AA *2 
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
    $fhinLoc2="FHIN_FASTA";
    open($fhinLoc2,$fileLoc) || return(0);
    $one=(<$fhinLoc2>);
    $two=(<$fhinLoc2>);
    $two=~s/\s//g               if (defined $two);

    return (0)                  if (! defined $two || ! defined $one);
    return (0)                  if (($one !~ /^\s*\>\s*\w+/) || 
				    ($two =~ /[^ABCDEFGHIKLMNPQRSTVWXYZx\.~_!]/i));
    $Lok=0;
    while (<$fhinLoc2>) {
	next if ($_ !~ /^\s*>\s*\w+/);
	$Lok=1;
	last;}close($fhinLoc2);
    return($Lok);
}				# end of isFastaMul

#==============================================================================
sub isGcg {
    local ($fileLoc) = @_ ; $[ =1 ;
#--------------------------------------------------------------------------------
#    isGcg                      checks whether or not file is in Gcg format (/# SAF/)
#       in:                     $file
#       out:                    1 if is yes; 0 else
# EXA: paho_chick from:    1 to:   80
# EXA: PANCREATIC HORMONE PRECURSOR (PANCREATIC POLYPEPTIDE) (PP).
# EXA:  paho_chick.gcg          Length:   80   31-May-98  Check: 8929 ..
# EXA:        1  MPPRWASLLL LACSLLLLAV PPGTAGPSQP TYPGDDAPVE DLIRFYNDLQ
# EXA:       51  QYLNVVTRHR YGRRSSSRVL CEEPMGAAGC
#--------------------------------------------------------------------------------
    return(0) if (! defined $fileLoc || ! -e $fileLoc);
    $fhinLoc="FHIN_GCG";
    open($fhinLoc,$fileLoc) || do { warn "-*- isGcg failed opening=$fileLoc\n";
				    return(0); };
    $ctLocFlag=$#tmp=0;
    while(<$fhinLoc>){++$ctLocFlag;
		      push(@tmp,$_);
		      last if ($ctLocFlag==5);}
    close($fhinLoc);
    $ctLocFlag=$already_sequence=0;
    foreach $tmp (@tmp){
	last if ($tmp=~/^\#/); # avoid being too friendly to GCG!
	if   ($tmp=~/from\s*:\s*\d+\s*to:\s*\d+/i)          {
	    ++$ctLocFlag;}
	elsif($tmp=~/^\s*\w+\s+Length\s*:\s+\d+\s+\d\d\-/i) {
	    ++$ctLocFlag;}
	elsif(! $already_sequence && $tmp=~/[\s\t]*\d+\s+[A-Z]+/i) {
	    $already_sequence=1;
	    ++$ctLocFlag;}
	last if ($ctLocFlag==3);}
    return(1) if ($ctLocFlag==3);
    return(0) ;
}				# end of isGcg

#==============================================================================
sub isMsf {
    local ($fileLoc) = @_ ; local ($Lok);
#--------------------------------------------------------------------------------
#   isMsf                       checks whether or not file is in MSF format
#				(i.e. the dirty ali format used for aqua)
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
    open("FHIN_MSF","$fileLoc");
    $ct=0;
    while (<FHIN_MSF>){ $Lok=0;
			$Lok=1  if ($_=~/\s*MSF[\s:]+/ ||
				# new PileUp shit
				     $_=~/\s*PileUp|^\s*\!\!AA_MULTIPLE_ALIGNMENT/);
			last;} 
    close(FHIN_MSF);
    return($Lok);
}				# end of isMsf

#===============================================================================
sub isPdb { 
    local ($fileLoc) = @_ ; local ($Lok,$fhinLoc,$fileTmp);
#--------------------------------------------------------------------------------
#   isPdb                       checks whether or not file is PDB format
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
    $fhinLoc="FhIn_PDB";$Lok=0;
    open($fhinLoc,$fileLoc) || 
	do { warn "*** isPdb failed opening file=$fileLoc!\n";
	     return(0); };
    $tmp="";
    while(<$fhinLoc>){
	$tmp=$_; $tmp=~s/\n//g;
	last;}
    close($fhinLoc);
#HEADER    PANCREATIC HORMONE                      16-JAN-81   1PPT      1PPT   3
    return(1)
	if ($tmp=~/^HEADER\s+.*\d\w\w\w\s+\d+\s*$/);
    return(0);
}				# end of isPdb

#==============================================================================
sub isPhdAcc {
    local ($fileLoc) = @_ ; local ($Lok);
#--------------------------------------------------------------------------------
#   isPhdAcc                    checks whether or not file is in PHD.rdb_acc format
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
    open("FHIN_RDB_PHDACC",$fileLoc) || return(0);
    $ctLoc=0;
    while (<FHIN_RDB_PHDACC>){ 
	$_=~s/^[\#\s]//g;
	next if (length($_)<5);
	++$ctLoc;
	last if ($ctLoc>3);
	if    ($ctLoc==1 && $_=~/^\s*Perl-RDB/){
	    $Lok=1;}
	elsif ($ctLoc==1)                  { 
	    close(FHIN_RDB_PHDACC); 
	    return(0);}
	elsif ($_=~/PHDacc/)            { 
	    close(FHIN_RDB_PHDACC); 
	    return(1);}}
    close(FHIN_RDB_PHDACC);
    return(0);
}				# end of isPhdAcc

#===============================================================================
sub isPhdBoth {
    local ($fileLoc) = @_ ; local ($Lok);
#--------------------------------------------------------------------------------
#   isPhdBoth                   checks whether or not file is in PHD.rdb format 
#                               acc + sec
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
    open("FHIN_RDB_PHDBOTH",$fileLoc) || return(0);
    $ctLoc=0;
    while (<FHIN_RDB_PHDBOTH>){ 
	$_=~s/^[\#\s]//g;
	next if (length($_)<5);
	++$ctLoc;
	last if ($ctLoc>3);
	if    ($ctLoc==1 && $_=~/^\s*Perl-RDB/) { 
	    $Lok=1;}
	elsif ($ctLoc==1)                       { 
	    close(FHIN_RDB_PHDBOTH); 
	    return(0); }
	elsif ($_=~/PHDsec/ && $_=~/PHDacc/) { 
	    close(FHIN_RDB_PHDBOTH); 
	    return(1);}}
    close(FHIN_RDB_PHDBOTH);
    return(0);
}				# end of isPhdBoth

#==============================================================================
sub isPhdHtm {
    local ($fileLoc) = @_ ; local ($Lok);
#--------------------------------------------------------------------------------
#   isPhdHtm                    checks whether or not file is in PHD.rdb_htm format
#				(i.e. the dirty ali format used for aqua)
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
    open("FHIN_RDB_PHDHTM",$fileLoc) || return(0);
    $ctLoc=0;
    while (<FHIN_RDB_PHDHTM>){ 
	$_=~s/^[\#\s]//g;
	next if (length($_)<5);
	++$ctLoc;
	last if ($ctLoc>3);
	if    ($ctLoc==1 && $_=~/^\s*Perl-RDB/){
	    $Lok=1;}
	elsif ($ctLoc==1) { 
	    close(FHIN_RDB_PHDHTM); 
	    return(0);}
	elsif ($_=~/PHDhtm/){
	    close(FHIN_RDB_PHDHTM); 
	    return(1);}}
    close(FHIN_RDB_PHDHTM);
    return(0);
}				# end of isPhdHtm

#==============================================================================
sub isPhdSec {
    local ($fileLoc) = @_ ; local ($Lok);
#--------------------------------------------------------------------------------
#   isPhdSec                    checks whether or not file is in PHD.rdb_sec format
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
    open("FHIN_RDB_PHDSEC",$fileLoc) || return(0);
    $ctLoc=0;
    while (<FHIN_RDB_PHDSEC>){ 
	$_=~s/^[\#\s]//g;
	next if (length($_)<5);
	++$ctLoc;
	last if ($ctLoc>3);
	if    ($ctLoc==1 && $_=~/^\s*Perl-RDB/) { 
	    $Lok=1;}
	elsif ($ctLoc==1)                       { 
	    close(FHIN_RDB_PHDSEC); 
	    return(0); }
	elsif ($_=~/PHDsec/)                 { 
	    close(FHIN_RDB_PHDSEC); 
	    return(1);}}
    close(FHIN_RDB_PHDSEC);
    return(0);
}				# end of isPhdSec

#==============================================================================
sub isPir {
    local ($fileLoc) = @_ ; local ($Lok);
#--------------------------------------------------------------------------------
#    isPir                    checks whether or not file is in Pir format 
#                               (first line /^>P1\;/, second (non white) = AA
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
    open("FHIN_PIR",$fileLoc) || return(0);
    $one=(<FHIN_PIR>);close(FHIN_PIR);
    return(1)                   if (defined $one && $one =~ /^\>P1\;/i);
    return(0);
}				# end of isPir

#==============================================================================
sub isPirMul {
    local ($fileLoc) = @_ ; local ($Lok);
#--------------------------------------------------------------------------------
#   isPirMul                    checks whether or not file contains many sequences 
#                               in PIR format 
#                               more than once: first line /^>P1\;/
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
    open("FHIN_PIR",$fileLoc) || return(0);
    $ctLoc=0;
    while(<FHIN_PIR>){
	++$ctLoc if ($_=~/^>P1\;/i);
	last if ($ctLoc>1);}
    close(FHIN_PIR);
    return(1)                   if ($ctLoc>1);
    return(0);
}				# end of isPirMul

#==============================================================================
sub isRdb {
    local ($fileInLoc) = @_ ;local ($fh);
#--------------------------------------------------------------------------------
#   isRdb                       checks whether or not file is in RDB format
#       in:                     file
#       out:                    returns 1 if is RDB, 0 else
#--------------------------------------------------------------------------------
    return (0) if (! -e $fileInLoc);
    $fh="FHIN_CHECK_RDB";
    open("$fh", $fileInLoc) || return(0);
    $tmp=<$fh>;
    close($fh);
    return(1)            if (defined $tmp && $tmp =~/^\# .*RDB/);
    return 0; 
}				# end of isRdb

#==============================================================================
sub isSaf {
    local ($fileLoc) = @_ ; 
#--------------------------------------------------------------------------------
#    isSaf                      checks whether or not file is in SAF format (/# SAF/)
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
    return(0)            if (! defined $fileLoc || ! -e $fileLoc);
    $fhinLoc="FHIN_SAF";
    open("$fhinLoc",$fileLoc) || return (0);
    $tmp=<$fhinLoc>; 
    close("$fhinLoc");
    return(1)            if (defined $tmp && $tmp =~ /^\#.*SAF/);
    return(0);
}				# end of isSaf

#==============================================================================
sub isSwiss {
    local ($fileLoc) = @_ ; local ($Lok);
#--------------------------------------------------------------------------------
#    isSwiss                    checks whether or not file is in SWISS-PROT format (/^ID   /)
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
    $fhinLoc="FHIN_SWISS";
    open("$fhinLoc","$fileLoc"); $Lok=0;
    while (<$fhinLoc>){ 
	$Lok=1                  if ($_=~/^ID   /);
	last;}
    close($fhinLoc);
    return($Lok);
}				# end of isSwiss

#==============================================================================
sub is_chain {
    local($tmp) = @_ ;
#-------------------------------------------------------------------------------
#   is_chain                    checks whether or not a PDB chain
#       in:                     character
#       out:                    1,0
#-------------------------------------------------------------------------------
    return(0) if (! defined $tmp);
    return(1) if ($tmp=~/[A-Z0-9]/);
    return(0);
}				# end of is_chain

#==============================================================================
sub is_dssp {
    local ($fileInLoc) = @_ ;
    local ($fh,$Lis);
#--------------------------------------------------------------------------------
#   is_dssp                     checks whether or not file is in DSSP format
#       in:                     $file
#       out:                    1 if is dssp; 0 else
#--------------------------------------------------------------------------------
    return (0) if (! defined $fileInLoc || ! -e $fileInLoc);
    $fh="FHIN_CHECK_DSSP";
    open($fh,$fileInLoc) || return(0);
    $Lis=0;
    while ( <$fh> ) {
	$Lis=1
	    if ($_=~/SECONDARY STRUCTURE DEFINITION BY THE PROGRAM DSSP/i);
	last; }
    close($fh);
    return $Lis;
}				# end of is_dssp

#==============================================================================
sub is_fssp {
    local ($fileInLoc) = @_ ;
#--------------------------------------------------------------------------------
#   is_fssp                     checks whether or not file is in FSSP format
#       in:                     $file
#       out:                    1 if is fssp; 0 else
#--------------------------------------------------------------------------------
    return(0)                   if (! defined $fileInLoc || ! -e $fileInLoc);
    $fh="FHIN_CHECK_FSSP";
    open($fh, $fileInLoc) || return(0);
    $tmp=<$fh> ;
    close($fh);
    return(1)                   if (defined $tmp && $tmp=~/^FSSP/);
    return(0);
}				# end of is_fssp

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
    open($fh, $fileInLoc) || return(0);
    $Lis=0;
    while ( <$fh> ) {
	$Lis=1 if (/^HSSP/) ; 
	last; }
    close($fh);
    return $Lis;
}				# end of is_hssp

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
sub is_ppcol {
    local ($fileInLoc) = @_ ;
    local ($fh,$Lis);
#--------------------------------------------------------------------------------
#   is_ppcol                    checks whether or not file is in RDB format
#       in:                     $file
#       out:                    1 if is ppcol, 0 else
#--------------------------------------------------------------------------------
    return(0)                   if (! defined $fileInLoc || ! -e $fileInLoc);
    $fh="FHIN_CHECK_HSSP";
    open($fh, $fileInLoc);
    $Lis=0;
    while ( <$fh> ) {
	$_=~tr/[A-Z]/[a-z]/;
	$Lis=1 if ($_=~/^\# pp.*col/);
	last; }
    close($fh);
    return $Lis;
}				# end of is_ppcol

#==============================================================================
sub is_rdb_htmref {
    local ($fileInLoc) = @_ ;local ($fh,$Lisrdb,$Lishtm);
#--------------------------------------------------------------------------------
#   is_rdb_htmref               checks whether or not file is RDB from PHDhtm_ref
#       in:                     $file
#       out:                    1 if is .; 0 else
#--------------------------------------------------------------------------------
    return (0)                  if (! -e $fileInLoc);
    $fh="FHIN_CHECK_RDB_PHDHTM_REF";$Lisrdb=$Lishtm=0;
    open($fh, $fileInLoc) || return(0); 
    $ctLoc=$Lishtm=0;
    while ( <$fh> ) { 
	++$ctLoc;
	$Lisrdb=1       if ($_=~/^\# Perl-RDB/);
	last if (! $Lisrdb);
	$Lishtm=1       if ($_=~/^\#\s*PHD\s*htm.*ref\:/);
	last if ($Lishtm);
	last if ($_ !~/^\#/);
	last if ($ctLoc > 5); }
    close($fh);
    return ($Lishtm);
}				# end of is_rdb_htmref

#==============================================================================
sub is_rdb_htmtop {
    local ($fileInLoc) = @_ ;local ($fh,$Lisrdb,$Lishtm);
#--------------------------------------------------------------------------------
#   is_rdb_htmtop               checks whether or not file is RDB from PHDhtm_top
#       in:                     $file
#       out:                    1 if is .; 0 else
#--------------------------------------------------------------------------------
    return (0)                  if (! -e $fileInLoc);
	
    $fh="FHIN_CHECK_RDB_PHDHTM_TOP";$Lisrdb=$Lishtm=0;
    open($fh, $fileInLoc) || return(0); 
    $ctLoc=$Lishtm=0;
    while ( <$fh> ) { 
	++$ctLoc;
	$Lisrdb=1       if ($_=~/^\# Perl-RDB/);
	last if (! $Lisrdb);
	$Lishtm=1       if ($_=~/^\#\s*PHD\s*htm.*top\:/);
	last if ($Lishtm);
	last if ($_ !~/^\#/);
	last if ($ctLoc > 5); }
    close($fh);
    return ($Lishtm);
}				# end of is_rdb_htmtop

#==============================================================================
sub is_rdb_nnDb {
    local ($fileInLoc) = @_ ;
    local ($fh,$Lisrdb,$Lisacc);
#--------------------------------------------------------------------------------
#   is_rdb_nnDb                 checks whether or not file is in RDB format for NN.pl
#       in:                     $file
#       out:                    1 if is rdb_nn; 0 else
#--------------------------------------------------------------------------------
    return (0)                  if (! -e $fileInLoc);
    $fh="FHIN_CHECK_RDB_RDBNN";
    open($fh, $fileInLoc) || return(0);
    $tmp=(<$fh>);
    close($fh);
    return(1)                   if (defined $tmp && $tmp=~/^\# Perl-RDB.*NNdb/i);
    return (0);
}				# end of is_rdb_nnDb

#==============================================================================
sub is_strip {
    local ($fileInLoc) = @_ ;
    local ($fh,$Lis);
#--------------------------------------------------------------------------------
#   is_strip                    checks whether or not file is in HSSP-strip format
#       in:                     $file
#       out:                    1 if is strip; 0 else
#--------------------------------------------------------------------------------
    return (0)                  if (! -e $fileInLoc);
    $fh="FHIN_CHECK_STRIP";
    open($fh, $fileInLoc) || return(0);
    $Lis=0;
    while ( <$fh> ) {
	$Lis=1 if ($_=~/===  MAXHOM-STRIP  ===/);
	last; }
    close($fh);
    return $Lis;
}				# end of is_strip

#==============================================================================
sub msfBlowUp {
    local($fileInLoc,$fileOutLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   msfBlowUp                   duplicates guide sequence for conversion to HSSP
#       in:                     $fileInLoc,$fileOutLoc
#       out:                    1|0, msg, 
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."msfBlowUp";
    $fhinLoc="FHIN_"."msfBlowUp";$fhoutLoc="FHOUT_"."msfBlowUp";
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc!")          if (! defined $fileInLoc);
    return(0,"*** $sbrName: not def fileOutLoc!")         if (! defined $fileOutLoc);

    return(0,"*** $sbrName: miss in file '$fileInLoc'!")  if (! -e $fileInLoc);

    ($Lok,$msg,%msfIn)=&msfRd($fileInLoc);
    return(0,"*** ERROR $sbrName: msfRd \n".$msg."\n") if (! $Lok);
    
    open("$fhoutLoc",">$fileOutLoc") ||
	return(0,"*** ERROR $sbrName: fileNew=$fileOutLoc, not opened\n");

    $name=$msfIn{"id","1"};
    $namex=substr($name,1,(length($name)-1))."x";
    $namex.="x"                if ($name eq $namex);
    $tmp{"1"}=$name;
    $tmp{"2"}=$namex;
    $tmp{$name}=    $msfIn{"seq","1"};
    $tmp{$namex}=   $msfIn{"seq","1"};
    $tmp{"NROWS"}=  2;
    $tmp{"FROM"}=   $fileInLoc;
    $tmp{"TO"}=     $fileOutLoc;
    undef %msfIn;		# save memory
				# write msf
    open ("$fhoutLoc",">$fileOutLoc") ||
        return(0,"*** ERROR $sbrName: failed opening new '$fileOutLoc'\n") ;
    ($Lok,$msg)=
	&msfWrt($fhoutLoc,%tmp);
    close($fhoutLoc);

    return(0,"*** ERROR $sbrName: failed to write $fileOutLoc, \n".$msg."\n") 
	if (! $Lok || ! -e $fileOutLoc);
    return(1,"ok $sbrName");
}				# end of msfBlowUp

#==============================================================================
sub msfCheckFormat {
    local ($fileMsf) = @_;
    local ($format,$tmp,$kw_msf,$kw_check,$ali_sec,$ali_des_sec,$valid_id_len,$fhLoc,
	   $uniq_id, $same_nb, $same_len, $nb_al, $seq_tmp, $seql, $ali_des_len);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   msfCheckFormat              basic checking of msf file format
#           - mandatory keywords and values (MSF: val, Check: val)
#           - alignment description start after "..", each line with the following structure:
#             Name: id Len: val Check: val Weight: val (and all ids diferents)
#           - alignment same number of line for each id (>0)
#       in:                     $fileMsf
#       out:                    return 1  if format seems OK, 0 else
#--------------------------------------------------------------------------------
    $sbrNameLoc="msfCheckFormat";
                                # ----------------------------------------
                                # initialise the flags
                                # ----------------------------------------
    $fhLoc="FHIN_CHECK_MSF_FORMAT";
    $kw_msf=$kw_check=$ali_sec=$ali_des_sec=$ali_des_seq=$nb_al=0;
    $format=1;
    $valid_id_len=1;		# sequence name < 15 characters
    $uniq_id=1;			# id must be unique
    $same_len=1;		# each seq must have the same len
    $lenok=1;			# length in header and of sequence differ
                                # ----------------------------------------
                                # read the file
                                # ----------------------------------------
    open ($fhLoc,$fileMsf)  || 
	return(0,"*** $sbrNameLoc cannot open fileMsf=$fileMsf\n");
    while (<$fhLoc>) {
	$_=~s/\n//g;
	$tmp=$_;$tmp=~ tr/a-z/A-Z/;
                                # MSF keyword and value
	$kw_msf=1    if (!$ali_des_seq && ($tmp =~ /MSF:\s*\d*\s/));
	next if (!$kw_msf);
                         	# CHECK keyword and value
	$kw_check=1  if (!$ali_des_seq && ($tmp =~ /CHECK:\s*\d*/));
	next if (!$kw_check);
                         	# begin of the alignment description section 
                         	# the line with MSF and CHECK must end with ".."
	if (!$ali_sec && $tmp =~ /MSF:\D*(\d*).*CHECK:.*\.\.\s*$/) {
	    $ali_des_len=$1;$ali_des_sec=1;}
                                # ------------------------------
                         	# the alignment description section
	if (!$ali_sec && $ali_des_sec) { 
            if ($tmp=~ /^\s*NAME:\s*(\S*).*LEN:.*\d.*CHECK:.*\d.*WEIGHT:.*\d.*/) {
		$id=$1;
		$valid_id_len=0 if (length($id) > 14);	# is sequence name <= 14
		if ($SEQID{$id}) { # is the sequence unique?
		    $uniq_id=0; $ali_sec=1;
		    last; }
		$lenRd=$tmp;$lenRd=~s/^.*LEN\:\s*(\d+)\s*CHEC.*$/$1/;
		$SEQID{$id}=1; # store seq ID
		$SEQL{$id}= 0;	# initialise seq len array
	    } }
                                # ------------------------------
                        	# begin of the alignment section
	$ali_sec=1    if ($ali_des_sec && $tmp =~ /\/\/\s*$/);
                                # ------------------------------
                        	# the alignment section
	if ($ali_sec) {
	    if ($tmp =~ /^\s*(\S+)\s+(.*)$/) {
		$id= $1;
		if ($SEQID{$id}) {++$SEQID{$id};
				  $seq_tmp= $2;$seq_tmp=~ s/\s|\n//g;
				  $SEQL{$id}+= length($seq_tmp);}}}
    }close($fhLoc);
                                # ----------------------------------------
                                # test if all sequences are present the 
				# same number of time with the same length
                                # ----------------------------------------
    if ($kw_msf && $kw_check && $ali_des_sec && $uniq_id && $valid_id_len){
	foreach $id (keys %SEQID) {
	    $nb_al= $SEQID{$id} if (!$nb_al);
	    if ($SEQID{$id} < 2 || $SEQID{$id} != $nb_al) {
		$same_len=0;
		last; }
	    if ($SEQL{$id} != $lenRd){
		$lenok=0;
		last;}}}
				# TEST ALL THE FLAGS
    $msg="";
    $msg.="*** $sbrNameLoc wrong MSF: no keyword MSF!\n"               if (!$kw_msf);
    $msg.="*** $sbrNameLoc wrong MSF: no keyword Check!\n"             if (!$kw_check);
    $msg.="*** $sbrNameLoc wrong MSF: no ali descr section!\n"         if (!$ali_des_sec);
    $msg.="*** $sbrNameLoc wrong MSF: no ali section!\n"               if (!$ali_sec); 
    $msg.="*** $sbrNameLoc wrong MSF: id not unique!\n"                if (!$uniq_id); 
    $msg.="*** $sbrNameLoc wrong MSF: seq name too long!\n"            if (!$valid_id_len);
    $msg.="*** $sbrNameLoc wrong MSF: varying length of seq!\n"        if (!$same_len);
    $msg.="*** $sbrNameLoc wrong MSF: length given and real differ!\n" if (!$lenok);
    return(0,$msg) if (length($msg)>1);
    return(1,"$sbrNameLoc ok");
}				# end msfCheckFormat

#===============================================================================
sub msfCompress {
    local($fileInLoc,$fileOutLoc) = @_ ;
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   msfCompress                 deletes insertions in guide sequence
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."msfCompress";
    $fhinLoc="FHIN_"."msfCompress";$fhoutLoc="FHOUT_"."msfCompress";
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
    return(&errSbr("not def fileOutLoc!"))         if (! defined $fileOutLoc);

    return(&errSbr("no fileIn=$fileInLoc!"))       if (! -e $fileInLoc);
				# number of characters per line
    $nperlineLoc=60;
				# open MSF file
    open($fhinLoc,$fileInLoc) || return(&errSbr("fileInLoc=$fileInLoc, not opened"));

    $#tmp=0;
    undef %msfIn;               # ------------------------------
    while (<$fhinLoc>) {	# read file
	$_=~s/\n//g;
	push(@tmp,$_);
        last if ($_=~/^\s*\//); # skip everything before ali sections
    } 
    undef %tmp;$ct=0;

    while (<$fhinLoc>) {	# read file
	$_=~s/\n//g;
        $_=~s/^\s*|\s*$//g;     # purge leading blanks
	$rd=$_;
        $tmp=$_;
	$tmp=~s/^\s*\d+[\s\t\.\,\d]+$//g;
        next if (length($tmp)<1); # skip lines empty or with numbers, only
                                # --------------------
				# from here on: 'id sequence'
        $id= $rd; $id =~s/^\s*(\S+)\s*.*$/$1/;
        $seq=$rd; $seq=~s/^\s*(\S+)\s+(\S.*)$/$2/;
        $seq=~s/\s//g;
        if (! defined $tmp{$id}){ # new
            ++$ct;$tmp{$id}=$ct;
            $msfIn{"id",$ct}= $id;
            $msfIn{"seq",$ct}=$seq;}
        else {
            $ptr=$tmp{$id};
            $msfIn{"seq",$ptr}.=$seq;
	}
    }
    close($fhinLoc);
    $msfIn{"NROWS"}=$ct;

				# ------------------------------
				# now compress insertions in guide
				# ------------------------------
    $ctcleave=$ctres=0;
    $lenloc=length($msfIn{"seq",1});
				# all 0
    foreach $itprot (1..$msfIn{"NROWS"}){
	$msfIn{"new",$itprot}="";
    }
				# loop over all residues
    foreach $itres (1..$lenloc){
				# is residue
	if (substr($msfIn{"seq",1},$itres,1)=~/^[A-Za-z]/){
	    foreach $itprot (1..$msfIn{"NROWS"}){
		$msfIn{"new",$itprot}.=substr($msfIn{"seq",$itprot},$itres,1);
	    }
	    ++$ctres;
	    next;}
				# seems insertion
	++$ctcleave;
    }
				# check: sum ok?
    return(0,"*** $sbrName: failed at compressing ncleave=$ctcleave, nresnew=$ctres,".
	   " before=".$lenloc." file=$fileInLoc!")
	if ($lenloc != ($ctcleave + $ctres));
				# replace by cleaved version
    foreach $itprot (1..$msfIn{"NROWS"}){
	$msfIn{"seq",$itprot}=$msfIn{"new",$itprot};
    }

				# ------------------------------
				# write new MSF
				# ------------------------------
    open($fhoutLoc,">".$fileOutLoc) || 
	return(&errSbr("fileOutLoc=$fileOutLoc, not created"));
				# get longest name
    $maxlen=0;
    foreach $itprot (1..$msfIn{"NROWS"}){
	$maxlen=length($msfIn{"id",$itprot}) if (length($msfIn{"id",$itprot}) > $maxlen);
    }

				# header
    foreach $tmp (@tmp){
	$tmp=~s/$lenloc/$ctres/g; # replace old by new length
	print $fhoutLoc $tmp,"\n";
    }
				# body
    for($it=1;$it<=$ctres;$it+=$nperlineLoc){
	print $fhoutLoc 
	    "\n";
	printf $fhoutLoc 
	    "%-".$maxlen."s  %-s\n",
	    " ",$it." " x ($nperlineLoc-length($it)-length($it+$nperlineLoc)) .($it+$nperlineLoc);
	foreach $itprot (1..$msfIn{"NROWS"}){
	    printf $fhoutLoc
		"%-".$maxlen."s  %-s\n",
		$msfIn{"id",$itprot},substr($msfIn{"seq",$itprot},$it,$nperlineLoc),"\n";
	}
    }
    close($fhoutLoc);
    return(0,"*** $sbrName: no output file=$fileOutLoc!") 
	if (! -e $fileOutLoc);
				# clean up
    undef %msfIn; undef %tmp;	# slim-is-in
    $#tmp=0;
    
    return(1,"ok $sbrName");
}				# end of msfCompress

#==============================================================================
sub msfCountNali {
    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   msfCountNali                counts the number of alignments in MSF file
#       in:                     file
#       out:                    $nali,$msg if error
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."msfCountNali";$fhinLoc="FHIN_"."msfCountNali";
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc!")          if (! defined $fileInLoc);
    return(0,"*** $sbrName: miss in file '$fileInLoc'!")  if (! -e $fileInLoc);

    open("$fhinLoc","$fileInLoc") ||
	return(0,"*** ERROR $sbrName: fileIn=$fileInLoc, not opened\n");

    $ct=0;                      # ------------------------------
    while (<$fhinLoc>) {        # read MSF
        ++$ct if ($_=~ /^\s*NAME:\s*(\S*).*LEN:.*\d.*CHECK:.*\d.*WEIGHT:.*\d.*/i);
        last if ($_=~/^\s*\//);
        next;} close($fhinLoc);
    return($ct);
}				# end of msfCountNali

#==============================================================================
sub msfRd {
    local ($fileInLoc) = @_ ;
    local ($sbrName,$Lok,$msg,$tmp,$fhout,$LfirstLine,$Lhead,
	   $Lguide,$seqGuide,$nameGuide);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   msfRd                       reads MSF files input format
#       in:                     $fileInLoc
#       out:                    ($Lok,$msg,$msfIn{}) with:
#       out:                    $msfIn{"NROWS"}  number of alignments
#       out:                    $msfIn{"id", $it} name for $it
#       out:                    $msfIn{"seq",$it} sequence for $it
#       err:                    ok-> 1,ok | error -> 0,message
#-------------------------------------------------------------------------------
    $sbrName="lib-br:msfRd"; $fhinLoc="FHIN_"."msfRd";
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc!")          if (! defined $fileInLoc);
    return(0,"*** $sbrName: miss in file '$fileInLoc'!")  if (! -e $fileInLoc);

    open("$fhinLoc","$fileInLoc") ||
	return(0,"*** ERROR $sbrName: fileIn=$fileInLoc, not opened\n");

    undef %msfIn;               # ------------------------------
    while (<$fhinLoc>) {	# read file
        last if ($_=~/^\s*\//); # skip everything before ali sections
    } undef %tmp;$ct=0;
    while (<$fhinLoc>) {	# read file
	$_=~s/\n//g;
        $_=~s/^\s*|\s*$//g;     # purge leading blanks
	$rd=$_;
        $tmp=$_;
	$tmp=~s/^\s*\d+[\s\t\.\,\d]+$//g;
        next if (length($tmp)<1); # skip lines empty or with numbers, only
                                # --------------------
				# from here on: 'id sequence'
        $id= $rd; $id =~s/^\s*(\S+)\s*.*$/$1/;
        $seq=$rd; $seq=~s/^\s*(\S+)\s+(\S.*)$/$2/;
        $seq=~s/\s//g;
        if (! defined $tmp{$id}){ # new
            ++$ct;$tmp{$id}=$ct;
            $msfIn{"id",$ct}= $id;
            $msfIn{"seq",$ct}=$seq;}
        else {
            $ptr=$tmp{$id};
            $msfIn{"seq",$ptr}.=$seq;
	}
    }
    close($fhinLoc);

    $msfIn{"NROWS"}=$ct;
    return(1,"ok $sbrName",%msfIn);
}				# end of msfRd

#===============================================================================
sub msfShorten {
    local($fileInLoc,$fileOutLoc) = @_ ;
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   msfShorten                  shortens names to <= 15 characters
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."msfShorten";
    $fhinLoc="FHIN_"."msfShorten";$fhoutLoc="FHOUT_"."msfShorten";
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
    return(&errSbr("not def fileOutLoc!"))         if (! defined $fileOutLoc);

    return(&errSbr("no fileIn=$fileInLoc!"))       if (! -e $fileInLoc);
				# number of characters per line
    $nperlineLoc=60;
				# open MSF file
    open($fhinLoc,$fileInLoc) || return(&errSbr("fileInLoc=$fileInLoc, not opened"));

    $#tmp=0;
    undef %msfIn;               # ------------------------------
    while (<$fhinLoc>) {	# read file
	$_=~s/\n//g;
	push(@tmp,$_);
        last if ($_=~/^\s*\//); # skip everything before ali sections
    } 
    undef %tmp;$ct=0;

    while (<$fhinLoc>) {	# read file
	$_=~s/\n//g;
        $_=~s/^\s*|\s*$//g;     # purge leading blanks
	$rd=$_;
        $tmp=$_;
	$tmp=~s/^\s*\d+[\s\t\.\,\d]+$//g;
        next if (length($tmp)<1); # skip lines empty or with numbers, only
                                # --------------------
				# from here on: 'id sequence'
        $id= $rd; $id =~s/^\s*(\S+)\s*.*$/$1/;
        $seq=$rd; $seq=~s/^\s*(\S+)\s+(\S.*)$/$2/;
        $seq=~s/\s//g;
        if (! defined $tmp{$id}){ # new
            ++$ct;$tmp{$id}=$ct;
            $msfIn{"id",$ct}= $id;
            $msfIn{"seq",$ct}=$seq;}
        else {
            $ptr=$tmp{$id};
            $msfIn{"seq",$ptr}.=$seq;
	}
    }
    close($fhinLoc);
    $msfIn{"NROWS"}=$ct;

				# ------------------------------
				# now shorten names
				# ------------------------------
    undef %msfIn2;
    foreach $it (1..$msfIn{"NROWS"}){
	if (length($msfIn{"id",$it})<=15) {
	    $msfIn2{$msfIn{"id",$it}}=1;
	    next;}
				# too long
	$id=$msfIn{"id",$it};
	$id=~s/^.*\|//g;	# purge paths
				# purge blanks
	$id=~s/\s//g            if (length($id)>15);
				# purge extensions
	$id=~s/\.[a-z]//g       if (length($id)>15);
				# cleave
	$id=substr($id,1,15)    if (length($id)>15);
				# not unique
	if (defined $msfIn2{$id}){
	    $id=substr($id,1,12);
	    $ct=1;$idmsfIn=$id.$ct;
	    while(defined $msfIn2{$idmsfIn}){
		++$ct;
		last if ($ct>999);}
	    $id=$idmsfIn;}
	return(0,"*** $sbrName: shoot id=$id, orig=",,", failed shortening\n")
	    if (defined $msfIn2{$id} || length($id)>15);
	$msfIn2{$id}=1;
	$msfIn{"id",$it}=$id;
    }
    undef %msfIn2; 
				# ------------------------------
				# change header
    $#tmp2=$ct=0;
    foreach $tmp (@tmp){
	if ($tmp !~/[Nn]ame\s*:\s*(\S+)/){
	    push(@tmp2,$tmp);}
	else {
	    ++$ct;
	    $tmp=~s/([Nn]ame\s*:\s*)\S+/$1$msfIn{"id",$ct}/;
	    push(@tmp2,$tmp);}}
    @tmp=@tmp2; $#tmp2=0;
	
				# ------------------------------
				# write new MSF
				# ------------------------------
    $lenloc=length($msfIn{"seq",1});
    open($fhoutLoc,">".$fileOutLoc) || 
	return(&errSbr("fileOutLoc=$fileOutLoc, not created"));
				# get longest name
    $maxlen=0;
    foreach $itprot (1..$msfIn{"NROWS"}){
	$maxlen=length($msfIn{"id",$itprot}) if (length($msfIn{"id",$itprot}) > $maxlen);
    }
    $ctres=length($msfIn{"seq",1});
				# header
    foreach $tmp (@tmp){
	$tmp=~s/$lenloc/$ctres/g; # replace old by new length
	print $fhoutLoc $tmp,"\n";
    }
				# body
    for($it=1;$it<=$ctres;$it+=$nperlineLoc){
	print $fhoutLoc 
	    "\n";
	printf $fhoutLoc 
	    "%-".$maxlen."s  %-s\n",
	    " ",$it." " x ($nperlineLoc-length($it)-length($it+$nperlineLoc)) .($it+$nperlineLoc);
	foreach $itprot (1..$msfIn{"NROWS"}){
	    printf $fhoutLoc
		"%-".$maxlen."s  %-s\n",
		$msfIn{"id",$itprot},substr($msfIn{"seq",$itprot},$it,$nperlineLoc),"\n";
	}
    }
    close($fhoutLoc);
    return(0,"*** $sbrName: no output file=$fileOutLoc!") 
	if (! -e $fileOutLoc);
				# clean up
    undef %msfIn; undef %tmp;	# slim-is-in
    $#tmp=0;
    
    return(1,"ok $sbrName");
}				# end of msfShorten

#==============================================================================
sub msfWrt {
    local($fhoutLoc,%input) = @_ ;
    local(@nameLoc,@stringLoc,$tmp,$sbrName,$Lok);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   msfWrt                      writing an MSF formatted file of aligned strings
#         in:                   $fileMsf,$input{}
#                               $input{"NROWS"}  number of alignments
#                               $input{"FROM"}   name of input file
#                               $input{"TO"}     name of output file
#                               $input{$it}    sequence identifier ($name)
#                               $input{$name}  sequence for $name
#--------------------------------------------------------------------------------
    $sbrName="msfWrt";
				# ------------------------------
    $#nameLoc=$#tmp=0;		# process input
    foreach $it (1..$input{"NROWS"}){
	$name=$input{$it};
	push(@nameLoc,$name);	# store the names
	push(@stringLoc,$input{$name}); } # store sequences

    $FROM=$input{"FROM"}        if (defined $input{"FROM"});
    $TO=  $input{"TO"}          if (defined $input{"TO"});

				# ------------------------------
				# write into file
    print $fhoutLoc 
	"MSF of: ",$FROM," from:    1 to:   ",length($stringLoc[1])," \n",
	$TO," MSF: ",length($stringLoc[1]),
	"  Type: P  Jul-11-1961 14:00 Check: 1933 ..\n \n \n";

    foreach $it (1..$#stringLoc){
	printf 
	    $fhoutLoc "Name: %-20s Len: %-5d Check: 2222 Weight: 1.00\n",
	    $nameLoc[$it],length($stringLoc[$it]); 
    }
    print $fhoutLoc " \n","\/\/\n"," \n";

    for($it=1;$it<=length($stringLoc[1]);$it+=50){
	foreach $it2 (1..$#stringLoc){
	    printf $fhoutLoc "%-20s",$nameLoc[$it2];
	    foreach $it3 (1..5){
		last if (length($stringLoc[$it2])<($it+($it3-1)*10));
		printf $fhoutLoc 
		    " %-10s",substr($stringLoc[$it2],($it+($it3-1)*10),10);}
	    print $fhoutLoc "\n";}
	print $fhoutLoc "\n"; }
    print $fhoutLoc "\n";
    close($fhoutLoc);
    $#nameLoc=$#stringLoc=0;	# save space
    return(1);
}				# end of msfWrt

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
	print 
	    "*** INFO (open_file): append file=$temp_name, does not exist-> create it\n" ;
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

#===============================================================================
sub pdbExtrSequence {
    local($fileInLoc,$chainInLoc,$LskipNucleic) = @_ ;
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   pdbExtrSequence             reads the sequence in a PDB file
#       in:                     $fileInLoc=    PDB file
#       in:                     $chainInLoc=   chains to read ('A,B,C' for many)
#                                  ='*'        to read all
#       in:                     $LskipNucleic= skip if nucleic acids
#       out:                    1|0,msg,%pdb as implicit reference with:
#       out:                    $pdb{"chains"}="A,B" -> all chains found ('none' for not specified)
#                               $pdb{$chain}=  sequence for chain $chain 
#                                              (='none' for not specified chain)
#                               NOTE: 'X' used for hetero-atoms, or for symbol 'U'
#                               $pdb{"header"}
#                               $pdb{"compnd"}
#                               $pdb{"source"}
#                               $pdb{"percentage_strange"}= 
#                                              percentage (0-100) of 'strange' acids ('!X')
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."pdbExtrSequence";
    $fhinLoc="FHIN_"."pdbExtrSequence";$fhoutLoc="FHOUT_"."pdbExtrSequence";
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
    return(&errSbr("not def chainInLoc!"))         if (! defined $chainInLoc);
    return(&errSbr("not def LskipNucleic!"))       if (! defined $LskipNucleic);
    $chainInLoc="*"             if (length($chainInLoc) < 1 || $chainInLoc =~/\s/);
    return(&errSbr("no fileIn=$fileInLoc!"))  if (! -e $fileInLoc);

				# open file
    open($fhinLoc,$fileInLoc) || return(&errSbr("fileInLoc=$fileInLoc, not opened"));
    undef %pdb;			# security
    $#chainLoc=0;
    $ctLine=0;			# count lines in file (for error)
    $ctStrange=0;		# count amino acids (non ACGT)
    $ctRes=0;
    $Lflag=0;			# set to 1 as soon as sequence found

				# ------------------------------
    while (<$fhinLoc>) {	# read file
				# ------------------------------
	++$ctLine;
				# skip anything before sequence
	if ($_!~/^SEQRES/) {

#HEADER    HYDROLASE (SERINE PROTEINASE)           24-APR-89   1P06      1P06   3
	    if ($_=~/^HEADER\s+(.*)\d\d\-[A-Z][A-Z][A-Z]\-\d\d\s*\d\w\w\w\s+/){
		$pdb{"header"}=$1;
		$pdb{"header"}=~s/^\s*|\s*$//g;
		$pdb{"header"}=~s/^\s\s+|\s//g;
		next; }
#COMPND    ALPHA-LYTIC PROTEASE (E.C.3.4.21.12) COMPLEX WITH             1P06   4
#COMPND   2 METHOXYSUCCINYL-*ALA-*ALA-*PRO-*PHENYLALANINE BORONIC ACID   1P06   5
	    if ($_=~/^COMPND\s+(.*)\s+\d\w\w\w\s+\d+\s*$/) {
		$pdb{"compnd"}="" if (! defined $pdb{"compnd"});
		$pdb{"compnd"}.=$1;
		$pdb{"compnd"}=~s/^\s*|\s*$//g;
		$pdb{"compnd"}=~s/\s\s+/ /g; # purge many blanks
		next; }
#SOURCE    (LYSOBACTER $ENZYMOGENES 495)                                 1P06   6
	    if ($_=~/^SOURCE\s+(.*)\s+\d\w\w\w\s+\d+\s*$/) {
		$pdb{"source"}=$1; $pdb{"source"}=~s/[\(\)\$]//g;
		$pdb{"source"}=~s/^\s*|\s*$//g;
		$pdb{"source"}=~s/\s\s+/ /g; # purge many blanks
		next; }
	    last if ($Lflag);	# end after read
	    next; }
				# delete stuff at ends
#....,....1....,....2....,....3....,....4....,....5....,....6....,....7....,....8
#SEQRES   1 A  198  ALA ASN ILE VAL GLY GLY ILE GLU TYR SER ILE ASN ASN  1P06  74
	$Lflag=1;			# sequence found
	$_=~s/\n//g;
	$line=substr($_,11);
	$line=substr($line,1,60);
	$chainRd=$line; $chainRd=~s/^\s*(\D*)\d+.*$/$1/g; $chainRd=~s/\s//g;
	$chainRd="*"            if (! defined $chainRd || length($chainRd)<1);
				# skip if wrong chain
	next if ($chainInLoc ne "*" && $chainRd ne $chainInLoc);
				# rename chain for non-specified
	$chainRd="none"         if ($chainRd eq "*");

				# get sequence part
	$seqRd3= $line; $seqRd3=~s/^\D*\d+(\D+).*$/$1/g;
	$seqRd3=~s/^\s*|\s*$//g; # purge trailing spaces
				# strange
	next if (! defined $seqRd3 || length($seqRd3)<3);
				# split into array of 3-letter residues
	@tmp=split(/\s+/,$seqRd3);
				# ------------------------------
				# end if is nucleic that was NOT
				# wanted!
	return(2,"nucleic","")
	    if ($LskipNucleic && $tmp[1]=~/^[ACGT]$/);
				# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

	$seqRd1="";		# 3 letter to 1 letter
	foreach $tmp (@tmp) {
	    ($Lok,$msg,$oneletter)=&amino_acid_convert_3_to_1($tmp);
				# HETERO atom?
	    if    (! $Lok && $oneletter eq "unk") {
		print "-*- WARN $fileInLoc ($ctLine) residue =$tmp\n";
		$oneletter="X";}
	    elsif (! $Lok || $oneletter !~/^[A-Z]$/) { 
		$msgErr="*** $sbrName ($fileInLoc): line=$ctLine, problem with conversion to 1 letter:\n";
		return(0,$msgErr.$msg); }
	    $seqRd1.=$oneletter; }
				# first
	if (! defined $pdb{$chainRd}) {
	    push(@chainLoc,$chainRd);
	    $pdb{$chainRd}=""; }
				# append to current chain
	$pdb{$chainRd}.=$seqRd1;
				# count non ACGT
	@tmp=split(//,$seqRd1);
	$ctRes+=$#tmp;		# count residues
	foreach $tmp (@tmp) {
	    next if ($tmp!~/^[ABCDEFGHIKLMNPQRSTVWXYZ]$/); # exclude strange stuff
	    ++$ctStrange;}
    } close($fhinLoc);
    $pdb{"chains"}=join(',',@chainLoc);
    $pdb{"percentage_strange"}=0;
    $pdb{"percentage_strange"}=100*int($ctStrange/$ctRes) if ($ctStrange && $ctRes);
    return(1,"ok $sbrName",\%pdb);
}				# end of pdbExtrSequence

#==============================================================================
sub pirRdMul {
    local($fileInLoc,$extr) = @_ ;
    local($sbrName,$fhinLoc,$msg,$Lok,$seq,$id);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   pirRdMul                    reads the sequence from a PIR file
#       in:                     file,$extr with:
#                               $extr = '1,5,6',   i.e. list of numbers to read
#       out:                    1|0,$id,$seq (note: many ids/seq separated by '\n'
#       err:                    ok=(1,'ok'), err=(0,'msg')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:pirRdMul";$fhinLoc="FHIN_"."$sbrName";

    open("$fhinLoc","$fileInLoc") ||
        return(0,"*** ERROR $sbrName: fileIn=$fileInLoc not opened\n");

    $extr=~s/\s//g  if (defined $extr);
    $extr=0         if (! defined $extr || $extr =~ /[^0-9\,]/);
    if ($extr){@tmp=split(/,/,$extr); undef %tmp;
	       foreach $tmp(@tmp){
		   $tmp{$tmp}=1;}}

    $ct=$ctRd=$ctProt=0;        # ------------------------------
    while (<$fhinLoc>) {        # read the file
	$_=~s/\n//g;
	if ($_ =~ /^\s*>/){	# (1) = id (>P1;)
            $Lread=0;
	    ++$ctProt;
	    $id=$_;$id=~s/^\s*>\s*P1?\s*\;\s*//g;$id=~s/(\S+)[\s\n]*.*$/$1/g;$id=~s/^\s*|\s*$//g;
	    $id.="_";

	    $id.=<$fhinLoc>;	# (2) still id in second line
	    $id=~s/[\s\t]+/ /g;
	    $id=~s/_\s*$/g/;
	    $id=~s/^[\s\t]*|[\s\t]*$//g;
            if (! $extr || ($extr && defined $tmp{$ctProt} && $tmp{$ctProt})){
                ++$ctRd;$Lread=1;
		$tmp{"$ctRd","id"}=$id;
		$tmp{"$ctRd","seq"}="";}}
        elsif($Lread){		# (3+) sequence
            $_=~s/[\s\*]//g;
            $tmp{"$ctRd","seq"}.="$_";}}close($fhinLoc);
                                # ------------------------------
    $seq=$id="";		# join to long strings
    if ($ctRd > 1) {
	foreach $it(1..$ctRd){
	    $id.= $tmp{$it,"id"}."\n";
	    $tmp{$it,"seq"}=~s/\s//g;$tmp{$it,"seq"}=~s/\*$//g;
	    $seq.=$tmp{$it,"seq"}."\n";} }
    else { $it=1;
	   $id= $tmp{$it,"id"};
	   $tmp{$it,"seq"}=~s/\s//g;$tmp{$it,"seq"}=~s/\*$//g;
	   $seq=$tmp{$it,"seq"}; }
	
    $#tmp=0;undef %tmp;		# save memory
    return(0,"*** ERROR $sbrName: file=$fileInLoc, nali=$ct, wanted: (rd=$rd)\n"," ") 
        if (length($seq)<1);
    return(1,$id,$seq);
}				# end of pirRdMul

#==============================================================================
sub pirWrtMul {
    local($fileOutLoc,%tmp) = @_ ;
    local($sbrName,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   pirWrtMul                   writes a list of sequences in PIR format
#       in:                     $fileOut,$tmp{} with:
#       in:                     $tmp{"NROWS"}      number of sequences
#       in:                     $tmp{"id",$ct}   id for sequence $ct
#       in:                     $tmp{"seq",$ct}  seq for sequence $ct
#       out:                    file
#       err:                    err  -> 0,message
#       err:                    ok   -> 1,ok
#       err:                    warn -> 2,not enough written
#-------------------------------------------------------------------------------
    $sbrName="lib-br:pirWrtMul";$fhoutLoc="FHOUT_"."$sbrName";

    return(0,"*** ERROR $sbrName: no tmp{NROWS} defined\n") if (! defined $tmp{"NROWS"});
    open("$fhoutLoc",">$fileOutLoc") ||
        return(0,"*** ERROR $sbrName: '$fileOutLoc' not opened for write\n");

    $ctOk=0;
    foreach $itpair (1..$tmp{"NROWS"}){
        next if (! defined $tmp{"id",$itpair} || ! defined $tmp{"seq",$itpair});
        ++$ctOk;
                                # some massage
        $tmp{"id",$itpair}=~s/[\s\t\n]+/ /g;
        $tmp{"seq",$itpair}=~s/[\s\t\n]+//g;
                                # write
        print $fhoutLoc ">P1\; ",$tmp{"id",$itpair},"\n";
        print $fhoutLoc $tmp{"id",$itpair},"\n";
        $tmp{"seq",$itpair}.="*";
	$lenHere=length($tmp{"seq",$itpair});
        for($it=1; $it<=$lenHere; $it+=50){
	    $tmpWrt=      "";
            foreach $it2 (0..4){
		$itHere=($it + 10*$it2);
                last if ( $itHere >= $lenHere);
		$nchunk=10; 
		$nchunk=1+($lenHere-$itHere)  if ( (10 + $itHere) > $lenHere);
		$tmpWrt.= sprintf(" %-10s",substr($tmp{"seq",$itpair},$itHere,$nchunk)); 
	    }
	    print $fhoutLoc $tmpWrt,"\n";
	}
    }
    close($fhoutLoc);
    return(0,"*** ERROR $sbrName: no sequence written\n")               
	if (! $ctOk);
    return(2,"-*- WARN $sbrName: wrote fewere sequences than expected\n") 
	if ($ctOk!=$tmp{"NROWS"});
    return(1,"ok $sbrName");
}				# end of pirWrtMul

#===============================================================================
sub pirWrtOne {
    local($fileOutLoc,$idLoc,$seqLoc) = @_ ;
    local($sbrName,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   pirWrtOne                   writes one sequence in PIR format
#       in:                     $fileOut,$id,$seq,
#       out:                    file
#       err:                    err  -> 0,message
#       err:                    ok   -> 1,ok
#-------------------------------------------------------------------------------
    $sbrName="lib-br:pirWrtOne";$fhoutLoc="FHOUT_"."$sbrName";

    return(0,"*** ERROR $sbrName: no seq defined\n") if (! defined $seqLoc);
    open("$fhoutLoc",">$fileOutLoc") ||
        return(0,"*** ERROR $sbrName: '$fileOutLoc' not opened for write\n");

                                # some massage
    $idLoc=~s/[\s\t\n]+/ /g;
    $seqLoc=~s/[\s\t\n]+//g;
                                # write
    print $fhoutLoc ">P1\; ",$idLoc,"\n";
    print $fhoutLoc $idLoc,"\n";
    $seqLoc.="*";		# add star
    $lenHere=length($seqLoc);
    for($it=1; $it<=$lenHere; $it+=50){
	$tmpWrt=      "";
	foreach $it2 (0..4){
	    $itHere=($it + 10*$it2);
	    last if ( $itHere >= $lenHere);
	    $nchunk=10; 
	    $nchunk=1+($lenHere-$itHere)  if ( (10 + $itHere) > $lenHere);
	    $tmpWrt.= sprintf(" %-10s",substr($seqLoc,$itHere,$nchunk)); 
	}
	print $fhoutLoc $tmpWrt,"\n";
    }
    close($fhoutLoc);
    return(0,"*** ERROR $sbrName: no sequence written\n")               
	if (! -e $fileOutLoc);
    return(1,"ok $sbrName");
}				# end of pirWrtOne

#===============================================================================
sub rdRdbAssociative {
    local ($fileInLoc,@des_in) = @_ ;
    local ($sbr_name,$fhinLoc,$Lhead,$Lbody,$Lfound,$it,$itrd,@tmp,$tmp,$des_in,$rd,
	   @des_head,@des_headin,@des_bodyin,@des_body,%ptr_rd2des,$nrow_rd,%rdrdb,
	   $Lscreen);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   rdRdbAssociative            reads content of an RDB file into associative array
#       in:                     Names used for columns in perl file, e.g.,
#                               "header,NALIGN,body,POS,NPROT" as arguments passed
#                               would result in:
#                               reading anything in file header using the keyword 'NALIGN'
#                               reading the columns named POS and NPROT
#       out:                    rdrdb{"NALIGN"},rdrdb{"POS","ct"},rdrdb{"NPROT","ct"},
#                               where ct counts the rows read,
#                               rdrdb{"NROWS"} returns the numbers of rows read
#--------------------------------------------------------------------------------
				# avoid warning
    $READHEADER="";
    $Lscreen=1;
				# set some defaults
    $fhinLoc="FHIN_RDB";$sbr_name="rdRdbAssociative";
				# get input
    $Lhead=$Lbody=$#des_headin=$#des_bodyin=0;
    foreach $des_in (@des_in){
	if   ($des_in=~/^not_screen/)        {$Lscreen=0;}
	elsif((!$Lhead) && ($des_in=~/head/)){$Lhead=1;$Lhead_all=1;}
	elsif((!$Lbody) && ($des_in=~/body/)){$Lbody=1;$Lhead=0; }
	elsif($Lhead)                        {push(@des_headin,$des_in);}
	elsif($Lbody)                        {$des_in=~s/\n|\s//g;;
					      push(@des_bodyin,$des_in);}
	else {
	    print "*** WARNING $sbr_name: input '$des_in' not recognised.\n";} }
    if ($Lscreen) { print "--- $sbr_name: header \t ";
		    foreach $it (@des_headin){print"$it,";}print"\n"; 
		    print "--- $sbr_name: body   \t ";
		    foreach $it (@des_bodyin){print"$it,";}print"\n"; }
				# --------------------------------------------------
				# read RDB file
				# --------------------------------------------------
    open("$fhinLoc","$fileInLoc");
				# out: $READHEADER :whole header, one string
				#      @READCOL    : all columns
				#      @READNAME   :names of columns
    &rdRdbAssociativeNum($fhinLoc,0);
    close($fhinLoc);
				# ------------------------------
    $#des_head=0;		# process header
    @tmp=split(/\#\s?/,$READHEADER);
    if ($#des_headin>=1){
	foreach $des_in (@des_headin) {
	    $Lfound=0;
	    foreach $rd (@tmp){
		if ($rd =~ /^(PARA\s*:?\s*)?$des_in\s*[ :,\;=]/){
		    $tmp=$rd;$tmp=~s/\n|\s$//g;$tmp=~s/^.*$des_in//g;$tmp=~s/^\s*//g;
		    $tmp=~s/^[\s:\t]*//g;
		    if (defined $rdrdb{"$des_in"}){
			$rdrdb{"$des_in"}.="\t".$tmp;}
		    else {
			$rdrdb{"$des_in"}=$tmp;}
		    push(@des_head,$des_in);$Lfound=1;} }
	    print
		"--- $sbr_name: \t expected to find in header key word:\n",
		"---            \t '$des_in', but not in file '$fileInLoc'\n"
		    if (!$Lfound && $Lscreen); }}
    elsif ($Lhead_all) {		# whole header into $rdrdb{"header"}
	$rdrdb{"header"}="";
	foreach $rd (@tmp) { $rd=~s/^\s?|\n//g;
			     $rdrdb{"header"}.="# ".$rd."\n"; }}
				# ------------------------------
    $#des_body=0;		# get column numbers to be read
    foreach $des_in (@des_bodyin) {
	$Lfound=0;
	for($it=1; $it<=$#READNAME; ++$it) {
	    $rd=$READNAME[$it];$rd=~s/\s//g;
	    if ($rd eq $des_in) {
		$ptr_rd2des{"$des_in"}=$it;push(@des_body,$des_in);$Lfound=1;
		last;} }
	if((!$Lfound) && $Lscreen){
	    print"--- $sbr_name: \t expected to find column name:\n";
	    print"---            \t '$des_in', but not in file '$fileInLoc'\n";}}
				# ------------------------------
				# get format
    foreach $des_in(@des_bodyin) {
	$it=$ptr_rd2des{"$des_in"};
	if ( defined $it && defined $READFORMAT[$it] ) {
	    $rdrdb{"$des_in","format"}=$READFORMAT[$it];}
	else {
	    $rdrdb{"$des_in","format"}="8";}}
    $nrow_rd=0;
    foreach $des_in(@des_body) {
	$itrd=$ptr_rd2des{"$des_in"};
	@tmp=split(/\t/,$READCOL[$itrd]);
	if   ($nrow_rd==0)    {$nrow_rd=$#tmp;}
	elsif($nrow_rd!=$#tmp){print "*** WARNING $sbr_name: different number of rows\n";
			       print "***         in RDB file '$fileInLoc' for rows with ".
				   "key=$des_in, column=$itrd, prev=$nrow_rd, now=$#tmp,\n";}
	for ($it=1; $it<=$#tmp; ++$it){
	    $rdrdb{"$des_in",$it}=$tmp[$it];
	    $rdrdb{"$des_in",$it}=~s/\s//g;}
    }
    $rdrdb{"NROWS"}=$rdrdb{"NROWS"}=$nrow_rd;
				# ------------------------------
				# safe memory
    $READHEADER=""; $#READCOL=$#READNAME=$#READFORMAT=0;
    $#des_headin=$#des_body=$#tmp=$#des_head=0;
    undef %ptr_rd2des;
    $#des_in=0;                 # slim_is_in !
    
    return (%rdrdb);
}				# end of rdRdbAssociative

#===============================================================================
sub rdRdbAssociativeNum {
    local ($fhLoc2,@readnum) = @_ ;
    local ($ctLoc, @tmpar, $it, $ipos, $tmp);
    $[ =1 ;
#----------------------------------------------------------------------
#   rdRdbAssociativeNum         reads from a file of Michael RDB format:
#       in:                     $fhLoc,@readnum,$readheader,@readcol,@readname,@readformat
#         $fhLoc:               file handle for reading
#         @readnum:             vector containing the number of columns to be read, if empty,
#                               then all columns will be read!
#         $READHEADER:          returns the complete header as one string
#         @READCOL:             returns all columns to be read (tab separated)
#         @READNAME:            returns the names of the columns
#         @READFORMAT:          returns the format of each column
#----------------------------------------------------------------------
    $READHEADER=""; $#READCOL=$#READNAME=$#READFORMAT=0;
    for ($it=1; $it<=$#readnum; ++$it) { $READCOL[$it]=""; }
    $ctLoc= 0;
    $tmpct=0;
    while ( <$fhLoc2> ) {	# ------------------------------
	++$tmpct;		# header  
	if ( /^\#/ ) { 
	    $READHEADER.= "$_";
	    next; }
	$rd=$_;$rd=~s/^\s+|\s+$//g;
	next if (length($rd)<2);
	++$ctLoc;		# count non-comment
				# ------------------------------
				# names
	if ($ctLoc==1){
	    $rd=$_;$rd=~s/^\t+|\t$//g;@tmpar=split(/\t/,$rd);
				# process wild card
	    if ($#readnum==0 || $readnum[1]==0 ||
		$readnum[1] !~ /[0-9]/ || ! defined $readnum[1] ) {
		foreach $it (1..$#tmpar){
		    $readnum[$it]=$it;
		    $READCOL[$it]=""; }}
	    foreach $it (1..$#readnum){
		$tmp_name=$tmpar[$readnum[$it]];$tmp_name=~s/\s|\n//g;
		$READNAME[$it]="$tmp_name"; }
	    next; }
				# ------------------------------
				# skip format?
	if ($ctLoc==2 && $rd!~/\d+[SNF]\t|\t\d+[SNF]/){
	    ++$ctLoc; }
	if ($ctLoc==2) {	# read format
	    $rd=$_;$rd=~s/^\t+|\t$//g;@tmpar=split(/\t/,$rd);
	    foreach $it (1..$#readnum){
		$ipos=$readnum[$it];$tmp=$tmpar[$ipos]; $tmp=~s/\s//g;
		$READFORMAT[$it]=$tmp; }
	    next; }
				# ------------------------------
				# data
	$rd=$_;$rd=~s/^\t+|\t$//g;@tmpar=split(/\t/,$rd);
	foreach $it (1..$#readnum){
	    next if (! defined $tmpar[$readnum[$it]]); 
	    $READCOL[$it].=$tmpar[$readnum[$it]] . "\t"; }
    }
				# ------------------------------
				# massage FORMAT/COL/NAME
    foreach $it (1..$#READCOL){
	$READFORMAT[$it]=~ s/^\s+//g   if (defined $READFORMAT[$it]);
	$READFORMAT[$it]=~ s/\t$|\n//g if (defined $READFORMAT[$it]);
	$READNAME[$it]=~ s/^\s+//g     if ($#READNAME>0);
	$READNAME[$it]=~s/\t|\n//g;
	$READNAME[$it]=~s/\n//g        if ($#READNAME>0); 
	$READCOL[$it] =~ s/\t$|\n//g;  # correction: last not return!
    }
}				# end of rdRdbAssociativeNum

#===============================================================================
sub safCompress {
    local($fileInLoc,$fileOutLoc) = @_ ;
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   safCompress                 deletes insertions in guide sequence
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."safCompress";
    $fhinLoc="FHIN_"."safCompress";$fhoutLoc="FHOUT_"."safCompress";
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
    return(&errSbr("not def fileOutLoc!"))         if (! defined $fileOutLoc);

    return(&errSbr("no fileIn=$fileInLoc!"))       if (! -e $fileInLoc);
				# number of characters per line
    $nperlineLoc=60;

    ($Lok,$msg,%safIn)=
	&safRd($fileInLoc);     return(&errSbrMsg("safRd failed on fileInLoc=$fileInLoc!",
						  $msg)) if (! $Lok);
    
				# ------------------------------
				# now compress insertions in guide
				# ------------------------------
    $ctcleave=$ctres=0;
    $lenloc=length($safIn{"seq",1});
				# all 0
    foreach $itprot (1..$safIn{"NROWS"}){
	$safIn{"new",$itprot}="";
    }
				# loop over all residues
    foreach $itres (1..$lenloc){
				# is residue
	if (substr($safIn{"seq",1},$itres,1)=~/^[A-Za-z]/){
	    foreach $itprot (1..$safIn{"NROWS"}){
		$safIn{"new",$itprot}.=substr($safIn{"seq",$itprot},$itres,1);
	    }
	    ++$ctres;
	    next;}
				# seems insertion
	++$ctcleave;
    }
				# check: sum ok?
    return(0,"*** $sbrName: failed at compressing ncleave=$ctcleave, nresnew=$ctres,".
	   " before=".$lenloc." file=$fileInLoc!")
	if ($lenloc != ($ctcleave + $ctres));
				# replace by cleaved version
    foreach $itprot (1..$safIn{"NROWS"}){
	$safIn{"seq",$itprot}=$safIn{"new",$itprot};
    }

				# ------------------------------
				# write new SAF
				# ------------------------------
    open($fhoutLoc,">".$fileOutLoc) || 
	return(&errSbr("fileOutLoc=$fileOutLoc, not created"));
				# get longest name
    $maxlen=0;
    foreach $itprot (1..$safIn{"NROWS"}){
	$maxlen=length($safIn{$itprot}) if (length($safIn{$itprot}) > $maxlen);
    }
				# body
    for($it=1;$it<=$ctres;$it+=$nperlineLoc){
	print $fhoutLoc 
	    "\n";
	printf $fhoutLoc 
	    "%-".$maxlen."s  %-s\n",
	    " ",$it." " x ($nperlineLoc-length($it)-length($it+$nperlineLoc)) .($it+$nperlineLoc);
	foreach $itprot (1..$safIn{"NROWS"}){
	    printf $fhoutLoc
		"%-".$maxlen."s  %-s\n",
		$safIn{"id",$itprot},substr($safIn{"seq",$itprot},$it,$nperlineLoc),"\n";
	}
    }
    close($fhoutLoc);
    return(0,"*** $sbrName: no output file=$fileOutLoc!") 
	if (! -e $fileOutLoc);
				# clean up
    undef %safIn; undef %tmp;	# slim-is-in
    $#tmp=0;
    return(1,"ok $sbrName");
}				# end of safCompress

#==============================================================================
sub safRd {
    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   safRd                       reads SAF format
#       in:                     $fileOutLoc,
#       out:                    ($Lok,$msg,$tmp{}) with:
#       out:                    $tmp{"NROWS"}  number of alignments
#       out:                    $tmp{"id", $it} name for $it
#       out:                    $tmp{"seq",$it} sequence for $it
#       err:                    ok-> 1,ok | error -> 0,message
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."safRd";$fhinLoc="FHIN_"."safRd";
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc!")          if (! defined $fileInLoc);
    return(0,"*** $sbrName: miss in file '$fileInLoc'!")  if (! -e $fileInLoc);

    $LverbLoc=0;

    open("$fhinLoc","$fileInLoc") ||
	return(0,"*** ERROR $sbrName: fileIn=$fileInLoc, not opened\n");

    $ctBlocks=$ctRd=$#nameLoc=0;  undef %nameInBlock; 
    undef %tmp2;
    undef %tmp;			# --------------------------------------------------
				# read file
    while (<$fhinLoc>) {	# --------------------------------------------------
	$_=~s/\n//g;
	next if ($_=~/\#/);	# ignore comments
	last if ($_=~/^\s*[\-\_]+\s*$/); # stop when address
	$line=$_;
				# ignore lines with numbers, blanks, points only
	$tmp=$_; $tmp=~s/[^A-Za-z]//g;
	next if (length($tmp)<1);

	$line=~s/^\s*|\s*$//g;	# purge leading blanks
				# ------------------------------
				# names
	$nameRd=$line; $nameRd=~s/^([^\s\t]+)[\s\t]+.*$/$1/;
				# new name?
	if (! defined $tmp2{"ptr",$nameRd}){
				# maximal length: 14 characters (because of MSF2Hssp)
	    if (length($nameRd)<=14){
		$nameTake=$nameRd;}
	    else {
		$tmp=$nameRd;
		$tmp=~s/^.*\|//; # purge database
		$ct=0;		# make sure not too long
		while ((length($tmp)-$ct)>14){
		    ++$ct;
		    $tmp=substr($tmp,1,(length($tmp)-$ct));
		}
		$ct=0;		# make sure not too short
		while ((length($tmp)+$ct)<2){
				# nonsense name
		    $tmp.=substr($nameRd,$ct,1);
		}
				# security check
		$Lok=0;
		$Lok=1          if (length($tmp)>=2 && 
				    length($tmp)<14);
		return(0,"*** ERROR $sbrName: could NOT find name for name=$nameRd!\n")
		    if (! $Lok);
		$nameTake=$tmp;}
				# make sure that it name unique
	    if (! defined $tmp2{$nameTake}){
		$tmp2{$nameTake}=1;}
	    else {
		$nameNew=$nameTmp=substr($nameTake,1,12);
		$it=0;
		while (defined $tmp2{$nameTmp} &&
		       $it<99){
		    ++$it;
		    $nameTmp=$nameNew.$it; }
		if (defined $tmp2{$nameTmp}){
		    $nameNew=$nameTmp=substr($nameRd,1,10);
		    $it=0;
		    while (defined $tmp2{$nameTmp} &&
			   $it<9999){
			++$it;
			$nameTmp=$nameNew.$it; }
		}
		else {
		    $tmp2{$nameTmp}=1; }
		$nameTake=$nameTmp; 
		$tmp2{$nameTake}=1;}
				# store a pointer
	    $tmp2{"ptr",$nameRd}=$nameTake;
	}

	else {			# old name: translate
	    $nameTake=$tmp2{"ptr",$nameRd}; }
				# ------------------------------
				# sequences
	$seq=$line;$seq=~s/^\s*//;$seq=~s/^[^\s\t]+//;$seq=~s/\s//g;
# 	next if ($seq =~/^ACDEFGHIKLMNPQRSTVWXYZ/i);  # check this!!
	print "--- $sbrName: nameRd=$nameRd, nameTake=$nameTake, seq=$seq,\n" 
	    if ($LverbLoc);
				# ------------------------------
				# guide sequence: determine length
				# NOTE: no 'left-outs' allowed here
				# ------------------------------
	$nameFirst=$nameTake    if ($#nameLoc==0);	# detect first name
	if ($nameTake eq "$nameFirst"){
	    ++$ctBlocks;	# count blocks
	    undef %nameInBlock;
	    if ($ctBlocks == 1){
		$lenFirstBeforeThis=0;}
	    else {
		$lenFirstBeforeThis=length($tmp{"seq","1"});}

	    if ($ctBlocks>1) {	# manage proteins that did not appear
		$lenLoc=length($tmp{"seq","1"});
		foreach $itTmp (1..$#nameLoc){
		    $tmp{"seq",$itTmp}.="." x ($lenLoc-length($tmp{"seq",$itTmp}));}
	    }}
				# ------------------------------
				# ignore 2nd occurence of same name
	next if (defined $nameInBlock{$nameTake}); # avoid identical names

				# ------------------------------
				# new name
	if (! defined ($tmp{$nameTake})){
	    push(@nameLoc,$nameTake); ++$ctRd;
	    $tmp{$nameTake}=$ctRd; 
	    $tmp{"id","$ctRd"}=$nameTake;
	    print "--- $sbrName: new name=$nameTake,\n"   if ($LverbLoc);

	    if ($ctBlocks>1){	# fill up with dots
		print 
		    "--- $sbrName: file up for $nameTake, with :$lenFirstBeforeThis\n"
			if ($LverbLoc);
		$tmp{"seq","$ctRd"}="." x $lenFirstBeforeThis;}
	    else{
		$tmp{"seq","$ctRd"}="";}}
				# ------------------------------
				# finally store
	$seq=~s/[^A-Za-z]/\./g; # any non-character to dot
	$seq=~tr/[a-z]/[A-Z]/;
	$ptr=$tmp{$nameTake};    
	$tmp{"seq",$ptr}.=$seq;
	$nameInBlock{$nameTake}=1; # avoid identical names
    } close($fhinLoc);
				# ------------------------------
				# fill up ends
    $lenLoc=length($tmp{"seq","1"});
    foreach $itTmp (1..$#nameLoc){
	$tmp{"seq",$itTmp}.="." x ($lenLoc-length($tmp{"seq",$itTmp}));}
    $tmp{"NROWS"}=$ctRd;
    $tmp{"names"}=join (',',@nameLoc);  $tmp{"names"}=~s/^,*|,*$//;
    $#nameLoc=0; undef %nameInBlock;

    return(1,"ok $sbrName",%tmp);
}				# end of safRd

#==============================================================================
sub safWrt {
    local($fileOutLoc,%tmp) = @_ ;
    local(@nameLoc,@stringLoc,$tmp,$sbrName,$Lok);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   safWrt                      writing an SAF formatted file of aligned strings
#       in:                     $fileOutLoc       output file
#                                   = "STDOUT"    -> write to screen
#       in:                     $tmp{"NROWS"}     number of alignments
#       in:                     $tmp{"id", $it} name for $it
#       in:                     $tmp{"seq",$it} sequence for $it
#       in:                     $tmp{"PER_LINE"}  number of res per line (def=50)
#       in:                     $tmp{"HEADER"}    'line1\n,line2\n'..
#                                   with line1=   '# NOTATION ..'
#       out:                    1|0,msg implicit: file
#       err:                    ok-> 1,ok | error -> 0,message
#--------------------------------------------------------------------------------
    $sbrName="lib-br:safWrt"; $fhoutLoc="FHOUT_safWrt";
                                # check input
    return(0,"*** ERROR $sbrName: no acceptable output file ($fileOutLoc) defined\n") 
        if (! defined $fileOutLoc || length($fileOutLoc)<1 || $fileOutLoc !~/\w/);
    return(0,"*** ERROR $sbrName: no input given (or not input{NROWS})\n") 
        if (! defined %tmp || ! %tmp || ! defined $tmp{"NROWS"} );
    return(0,"*** ERROR $sbrName: tmp{NROWS} < 1\n") 
        if ($tmp{"NROWS"} < 1);
    $tmp{"PER_LINE"}=50         if (! defined $tmp{"PER_LINE"});
    $fhoutLoc="STDOUT"          if ($fileOutLoc eq "STDOUT");
                                # ------------------------------
                                # open new file
    if ($fhoutLoc ne "STDOUT") {
	open("$fhoutLoc",">$fileOutLoc") ||
	    return(0,"*** ERROR $sbrName: failed opening fileOut=$fileOutLoc\n"); }
				# ------------------------------
				# write header
				# ------------------------------
    print $fhoutLoc "# SAF (Simple Alignment Format)\n","\# \n";
    print $fhoutLoc $tmp{"HEADER"} if (defined $tmp{"HEADER"});

				# get longest name
    $maxlen=0;
    foreach $itprot (1..$tmp{"NROWS"}){
	$maxlen=length($tmp{"id",$itprot}) if (length($tmp{"id",$itprot}) > $maxlen);
    }

				# ------------------------------
				# write data into file
				# ------------------------------
    for($itres=1; $itres<=length($tmp{"seq","1"}); $itres+=$tmp{"PER_LINE"}){
	foreach $itpair (1..$tmp{"NROWS"}){
	    printf $fhoutLoc "%-".$maxlen."s ",$tmp{"id",$itpair};
				# chunks of $tmp{"PER_LINE"}
	    $chunkEnd=$itres + ($tmp{"PER_LINE"} - 1);
	    foreach $itchunk ($itres .. $chunkEnd){
		last if (length($tmp{"seq",$itpair}) < $itchunk);
		print $fhoutLoc substr($tmp{"seq",$itpair},$itchunk,1);
				# add blank every 10
		print $fhoutLoc " " 
		    if ($itchunk != $itres && (int($itchunk/10)==($itchunk/10)));
	    }
	    print $fhoutLoc "\n"; }
	print $fhoutLoc "\n"; }
    
    print $fhoutLoc "\n";
    close($fhoutLoc);
    $#nameLoc=$#stringLoc=0;	# save space

    return(0,"*** ERROR $sbrName: failed to write file $fileOutLoc\n") if (! -e $fileOutLoc);
    return(1,"ok $sbrName");
}				# end of safWrt

#==============================================================================
sub seqGenWrt {
    local($seqInLoc,$idInLoc,$formOutLoc,$fileOutLoc,$fhErrSbr) = @_ ;
    local($sbrName,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   seqGenWrt                   writes protein sequence in various output formats
#       in:                     $seq,$id,$formOut,$fileOut,$fhErrSbr
#       out:                    implicit: fileOut
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="lib-br:"."seqGenWrt"; $fhoutLoc="FHOUT_"."seqGenWrt";
				# check arguments
    return(0,"*** $sbrName: not def seqInLoc!")         if (! defined $seqInLoc);
    return(0,"*** $sbrName: not def idInLoc!")          if (! defined $idInLoc);
    return(0,"*** $sbrName: not def formOutLoc!")       if (! defined $formOutLoc);
    return(0,"*** $sbrName: not def fileOutLoc!")       if (! defined $fileOutLoc);
    $fhErrSbr="STDOUT"                                  if (! defined $fhErrSbr);

    return(0,"*** $sbrName: sequence missing")          if (length($seqInLoc)<1);

    undef %tmp;
				# ------------------------------
    $tmp{"seq","1"}=$seqInLoc;	# intermediate variable for seq
    $tmp{"NROWS"}=  1;
    $tmp{"id","1"}= $idInLoc;
    $Lok=0;
				# ------------------------------
				# write output
    if    ($formOutLoc =~ /^fasta/){ ($Lok,$msg)=&fastaWrtMul($fileOutLoc,%tmp);}
    elsif ($formOutLoc =~ /^pir/)  { ($Lok,$msg)=&pirWrtMul($fileOutLoc,%tmp);}
    elsif ($formOutLoc eq "saf")   { ($Lok,$msg)=&safWrt($fileOutLoc,%tmp);}
    elsif ($formOutLoc eq "msf")   { $tmp{"FROM"}="unk";$tmp{"TO"}=$fileOutLoc;
				     $tmp{"1"}=$idInLoc;$tmp{"$idInLoc"}=$seqInLoc;
				     open("$fhoutLoc",">$fileOutLoc") ||
					 return(&errSbr("failed creating $fileOutLoc"));
				     $Lok=
					 &msfWrt($fhoutLoc,%tmp);
				     close($fhoutLoc);
				     return(&errSbr("failed writing msf=$fileOutLoc (msfWrt)"))
					 if (! $Lok);}
    else {
	return(0,"*** ERROR $sbrName output format $formOutLoc not supported\n");}

    return(0,"*** ERROR $sbrName: failed to write $formOutLoc into $fileOutLoc\n")
	if (! $Lok || ! -e $fileOutLoc);

    return(1,"ok $sbrName");
}				# end of seqGenWrt

#==============================================================================
sub swissRdSeq {
    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc,$msg,$Lok,$seq,$id);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   swissRdSeq                  reads the sequence from a SWISS-PROT file
#       in:                     file
#       out:                    (1,name,sequence in one string)
#-------------------------------------------------------------------------------
    $sbrName="swissRdSeq";$fhinLoc="FHIN"."$sbrName";

    $Lok=       open("$fhinLoc","$fileInLoc");
    if (! $Lok){$msg="*** ERROR $sbrName: '$fileInLoc' not opened\n";
		return(0,$msg,"error");}
    $seq="";
    while (<$fhinLoc>) {$_=~s/\n//g;
			if ($_=~/^ID\s+(\S*)\s*.*$/){
			    $id=$1;}
			last if ($_=~/^\/\//);
			next if ($_=~/^[A-Z]/);
			$seq.="$_";}close($fhinLoc);
    $seq=~s/\s//g;
    return(1,$id,$seq);
}				# end of swissRdSeq

#==============================================================================
sub sysDate {
#    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   sysDate                     returns $Date
#       out:                    $Date (May 30, 1998 59:39:03)
#-------------------------------------------------------------------------------
    @tmp=("/home/rost/perl/ctime.pl","/nfs/data5/users/ppuser/server/pub/perl/ctime.pl");
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
    $sbrName="lib-sys:sysRunProg";
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
# library collected (end) lll
#==============================================================================


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
	    next if (! defined $file{$kwd} || ! -e $file{$kwd});
	    print "--- $sbrName unlink '",$file{$kwd},"'\n" if ($Lverb2);
	    unlink($file{$kwd});}}
    foreach $kwd ("fileOutTrace","fileOutScreen"){
        next if (! defined $par{$kwd} || ! -e $par{$kwd});
        print "--- $sbrName unlink '",$par{$kwd},"'\n" if ($Lverb2);
        unlink($par{$kwd});}
}				# end of cleanUp

#===============================================================================
sub convAliGen {
    local($fileInLoc,$fileOutLoc,$formIn,$formOut,$extOutLoc,$exeConvSeq,$fileMatGcg,
          $doCompress,$frag,$extrLoc,$fileScreenLoc,$dirWork,$fhSbr) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   convAliGen                  general converter for SAF|MSF|FASTAmul -> HSSP,SAF,MSF,FASTAmul,PIRmul
#       in:                     $fileInLoc,$fileOutLoc,$formIn,$formOut,$extOutLoc,$frag,$extrLoc,
#                                    + $fileScreenLoc,$dirWork,$fhSbr
#       in:                     $fileInLoc   file.Ali, file.out, format_of_output_file
#       in:                     $fileOutLoc  output file with converted sequence(s)
#       in:                                  NOTE: if many appended to @fileOut
#       in:                     $formOut     output format (lower caps)
#       in:                     $extOutLoc   extension of expected output (fragments into _beg_end$extension)
#       in:                     $exeConvSeq  FORTRAN program convert_seq
#       in:                     $fileMatGcg  Maxhom_GCG.metric (for converting to HSSP)
#       in:                     $doCompress  for conversion into HSSP : delete insertions in MASTER?
#       in:                     $frag        fragments e.g. '1-5,10-100'
#       in:                     $extrIn      number of protein to extract
#       in:                     $fileScreen  output file for system commands
#       in:                     $dirWork     directory for temporary files
#       in:                     $fhSbr       ERRORs of convert_seq
#       out:                    converted file
#       out GLOBAL:             @fileOut,@kwdRm,$file{"kwd"} files to remove
#       err:                    0,$msg -> unspecified error 
#       err:                    1,$msg -> ok
#       err:                    2,$msg -> conversion option not supported
#-------------------------------------------------------------------------------
    $sbrName="$scrName:"."convAliGen";$fhinLoc="FHIN"."$sbrName";
                                # ------------------------------
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc!")          if (! defined $fileInLoc);
    return(0,"*** $sbrName: not def fileOutLoc!")         if (! defined $fileOutLoc);
    return(0,"*** $sbrName: not def formIn!")             if (! defined $formIn);
    return(0,"*** $sbrName: not def formOut!")            if (! defined $formOut);
    return(0,"*** $sbrName: not def extOutLoc!")          if (! defined $extOutLoc);
    return(0,"*** $sbrName: not def exeConvSeq!")         if (! defined $exeConvSeq);
    return(0,"*** $sbrName: not def fileMatGcg!")         if (! defined $fileMatGcg);
    return(0,"*** $sbrName: not def doCompress!")         if (! defined $doCompress);
    return(0,"*** $sbrName: not def frag!")               if (! defined $frag);
    return(0,"*** $sbrName: not def extrLoc!")            if (! defined $extrLoc);
    return(0,"*** $sbrName: not def fileScreenLoc!")      if (! defined $fileScreenLoc);
    return(0,"*** $sbrName: not def dirWork!")            if (! defined $dirWork);
    $fhSbr="STDOUT"                                       if (! defined $fhSbr);
    return(0,"*** $sbrName: miss in file '$fileInLoc'!")  if (! -e $fileInLoc);
    return(0,"*** $sbrName: miss in file '$fileMatGcg'!") if (! -e $fileMatGcg);
    return(0,"*** $sbrName: miss exe '$exeConvSeq'!")     if (! -e $exeConvSeq && ! -l $exeConvSeq);

    $msgErr="";
    return(0,"*** $sbrName: input format $formIn not supported\n") 
	if ($formIn !~/pir|gcg|swiss|msf|saf|fasta/);
    $fhSysRunProg=0;
    $fhSysRunProg="STDOUT"      if ($par{"verbose"} || $par{"debug"});
    $fileScreenLoc=0            if ($par{"debug"});


    $#beg=$#end=0;              # ------------------------------
    if ($frag){                 # extract fragments?
        @tmp=split(/,/,$frag);
	$#beg=$#end=0;
        foreach $frag(@tmp){ next if ($frag !~ /\-/);$frag=~s/\s//g;
			     ($beg,$end)=split('-',$frag);
			     next if ($beg =~/\D/ || $end =~ /\D/);
			     push(@beg,$beg);push(@end,$end);}}

                                # ------------------------------
    $#kwdRmTmp=0;               # temporary files

                                # --------------------------------------------------
    if ($formOut eq "hssp"){    # HSSP output
        if ($#beg>1){
            print 
		"-*- WARN $sbrName: for $formIn -> HSSP currently only one fragment at a time!!\n" 
		    x 2;}
	$shortNames=1;		# for HSSP: names shorter than 15 characters!

                                # ------------------------------
                                # (1) convert all seq to FASTA
	if ($formIn =~ /^pir/ || $formIn eq "gcg" || $formIn eq "swiss" ){
            $kwd=$formIn."-".$formOut ;push(@kwdRmTmp,$kwd);
            $fileOutSeqTmp=$file{$kwd}=$dirWork.$par{"titleTmp"}.".fasta_tmp";
            $fragHere=0; $fragHere="$beg[1]-$end[1]" if ($#beg>0);
	    return(&errSbr("more than one fragment not supported for converting ".
			   "$formIn to $formOut")) if ($#beg>1);
	    ($Lok,$msg)=
		&convSeq2fastaPerl($fileInLoc,$fileOutSeqTmp,$formIn,$fragHere,$shortNames);
	    return(&errSbrMsg("failed converting seq ($formIn) to FASTA",$msg)) if (! $Lok); 
				# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
				# change input format
				# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	    $formIn="fasta";}
	else {
	    $fileOutSeqTmp=$fileInLoc;}

                                # ------------------------------
                                # (2) convert all to MSF
        if ($formIn eq "saf" || $formIn =~/^fasta/){
            $kwd=$formIn."-".$formOut;push(@kwdRmTmp,$kwd);
            $fileOutMsfTmp=$file{$kwd}=$dirWork.$par{"titleTmp"}.".msf_tmp";
            $fragHere=0; $fragHere="$beg[1]-$end[1]" if ($#beg>0);
	    if    ($formIn eq "saf"){
                ($Lok,$msg)=
                    &convSaf2many($fileOutSeqTmp,$fileOutMsfTmp,"msf",
				  $fragHere,$extrLoc,$fhSbr,$doCompress,$shortNames);}
            elsif ($formIn =~ /^fasta/){
                ($Lok,$msg)=
                    &convFastamul2many($fileOutSeqTmp,$fileOutMsfTmp,"msf",
				       $fragHere,$extrLoc,$fhSbr,$doCompress,$shortNames);}
            return(0,"*** ERROR $sbrName: failed to write msf ($fileOutMsfTmp) from $fileInLoc, ".
		   "to seq=$fileOutSeqTmp, for extr=$extrLoc".
		   $msg."\n") if (! $Lok || ! -e $fileOutMsfTmp);}
        elsif ($formIn eq "msf") {
				# shorten names
	    $kwd="msfShorten";  push(@kwdRmTmp,$kwd);
	    $fileOutMsfShorten=$file{$kwd}=$dirWork.$par{"titleTmp"}.".msf_shorten";
	    ($Lok,$msg)=
		&msfShorten
		    ($fileOutSeqTmp,$fileOutMsfShorten
		     );         return(&errSbrMsg("failed shortening names msf=$fileOutSeqTmp->".
						  $fileOutMsfShorten.",msg=",$msg)) if (! $Lok); 
				# convert too to make sure compressing works
	    if ($doCompress){
		$kwd=$formIn."-".$formOut; push(@kwdRmTmp,$kwd);
		$fileOutMsfTmp=$file{$kwd}=$dirWork.$par{"titleTmp"}.".msf_tmp";
		($Lok,$msg)=
		    &msfCompress
			($fileOutMsfShorten,$fileOutMsfTmp
			 );     return(&errSbrMsg("failed compressing MSF=$fileOutSeqTmp->".
						  $fileOutMsfTmp."! msg=",$msg)) if (! $Lok);}
	    else {
		$fileOutMsfTmp=$fileOutMsfShorten;}}
	else {
	    return(&errSbr("input format=$formIn -> output=$formOut, not supported\n"));}
                                # ------------------------------
                                # (3) blow up when single sequence
        if (&msfCountNali($fileOutMsfTmp) == 1){
            $kwd=$formIn."-".$formOut."-addSelf";push(@kwdRmTmp,$kwd);
            $fileOutMsfTmp2=$file{$kwd}=$dirWork.$par{"titleTmp"}.".msf_tmpSelf"; 
	    ($Lok,$msg)=
		&msfBlowUp
		    ($fileOutMsfTmp,$fileOutMsfTmp2
		     );         return(0,"*** ERROR $sbrName: failed to write msf2 ($fileOutMsfTmp2)".
				       $msg."\n") if (! $Lok);
	    $fileOutMsfTmp=$fileOutMsfTmp2;}
	
                                # ------------------------------
                                # (4) now convert_seq to write HSSP
        $cmd=           "";     # eschew warnings
        $an2=           "N";    # write another format?
                                # gaps in master sequence as insertions?
        $anIns=         "N";
        $anIns=         "Y" if ($doCompress);

        $anFormOut=     "H";    # output = HSSP
        $anId=          " ";    # specify id for master

                                # ------------------------------
                                # (5) convert to HSSP
        $fileOutTmp=$fileOutLoc;
        eval            "\$cmd=\"$exeConvSeq,$fileOutMsfTmp,$anFormOut,$fileMatGcg,$anIns,$fileOutTmp,$anId,$an2\"";
				# run FORTRAN script
#        ($Lok,$msg)=&sysRunProg($cmd,0,"STDOUT");
        ($Lok,$msg)=&sysRunProg($cmd,$fileScreenLoc,$fhSysRunProg);
        return(0,"*** ERROR $sbrName: failed to convert hssp to MSF\n".$msg."\n")
            if (! $Lok || ! -e $fileOutTmp);
				# ------------------------------
				# (6) verify NALI in HSSP
	$kwd=$formIn."-".$formOut."-correct";push(@kwdRmTmp,$kwd);
	$fileOutHsspTmp=$file{$kwd}=$dirWork.$par{"titleTmp"}.".hssp_error"; 
	($Lok,$msg)=&hsspCorrectNali($fileOutTmp,$fileOutHsspTmp,$fhSbr);
        push(@fileOut,$fileOutTmp);}
                                # --------------------------------------------------
                                # MSF, FASTA, PIR, FASTAmul, PIRmul
    elsif ($formOut eq "msf" || $formOut eq "fasta" || $formOut eq "pir" || $formOut eq "saf" 
           || $formOut eq "fastamul" || $formOut eq "pirmul" || $formOut eq "gcg"){
                                # --------------------
                                # (1) convert MSF to SAF
        if ($formIn eq "msf"){
            $kwd=$formOut."-SAF";push(@kwdRmTmp,$kwd);
            $fileOutSafTmp=$file{$kwd}=$dirWork.$par{"titleTmp"}.$kwd.$extOutLoc;
            ($Lok,$msg)=
                &convMsf2saf
		    ($fileInLoc,$fileOutSafTmp,$doCompress
		     );         return(0,"*** ERROR $sbrName: failed to write saf ($fileOutSafTmp) ".
				       "from $fileInLoc".$msg."\n") if (! $Lok || ! -e $fileOutSafTmp);
	    $fileInLoc2=$fileOutSafTmp;}
	else {
	    $fileInLoc2=$fileInLoc;}
                                # --------------------
        if ($#beg>0){           # (2a) loop over fragments
            foreach $it (1..$#beg){
                $fileOutTmp=$fileOutLoc;$fileOutTmp=~s/(\.$extOutLoc)/\_$beg[$it]\_$end[$it]$1/;
                $fragHere="$beg[$it]-$end[$it]";
                if    ($formIn eq "saf" || $formIn eq "msf"){
		    ($Lok,$msg)=
                        &convSaf2many
			    ($fileInLoc2,$fileOutTmp,$formOut,$fragHere,$extrLoc,
			     $fhSbr,$doCompress
			     ); return(0,"*** ERROR $sbrName: failed to convert $fileInLoc2 to ".
				       "$formOut\n"."$msg\n") if (! $Lok);}
                elsif ($formIn =~ /^fasta/){
                    ($Lok,$msg)=
                        &convFastamul2many
			    ($fileInLoc2,$fileOutTmp,$formOut,$fragHere,
			     $extrLoc,$fhSbr,$doCompress
			     ); return(0,"*** ERROR $sbrName: failed to convert $fileInLoc2 to ".
				       "$formOut\n"."$msg\n") if (! $Lok);}
                push(@fileOut,$fileOutTmp);}}
                                # --------------------
        else {$fragHere=0;      # (2b) no fragments
              if    ($formIn eq "saf" || $formIn eq "msf"){
                  ($Lok,$msg)=
                      &convSaf2many
			  ($fileInLoc2,$fileOutLoc,$formOut,$fragHere,
			   $extrLoc,$fhSbr,$doCompress
			   );   return(0,"*** ERROR $sbrName: failed to convert $fileInLoc2 to ".
				       "$formOut\n".$msg."\n") if (! $Lok);}
              elsif ($formIn =~ /^fasta/){
                  ($Lok,$msg)=
                      &convFastamul2many
			  ($fileInLoc2,$fileOutLoc,$formOut,$fragHere,
			   $extrLoc,$fhSbr,$doCompress
			   );   return(0,"*** ERROR $sbrName: failed to convert $fileInLoc2 (fasta) ".
				       "to $formOut\n"."$msg\n") if (! $Lok);}
	      push(@fileOut,$fileOutLoc);}
    }
    else {
        return(2,"*** ERROR $sbrName: output option $formOut not supported\n");}
                                # ------------------------------
                                # remove temporary files
    if (! $par{"debug"}){
	foreach $kwd(@kwdRmTmp){
	    if (-e $file{$kwd}){ 
		print 
		    "--- \t $sbrName: remove (",$file{$kwd},") \n" 
			if (defined $par{"verb2"} && $par{"verb2"});
		unlink $file{$kwd};}}}
    return(1,"ok $sbrName");
}				# end of convAliGen

#===============================================================================
sub convDsspGen {
    local($fileInLoc,$chainInLoc,$fileOutLoc,$formOut,$extOutLoc,$exeConvSeq,$fileMatGcg,
	  $frag,$fileScreenLoc,$dirWork,$fhSbr,$doSplitChainLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   convDsspGen                 general converter for all DSSP in -> x
#       in:                     for general info see 'convDsspGen'
#       in:                     $fileInLoc   file,dssp 
#       in:                     $chainLoc    chain to extract
#       in:                     $fileOut     
#       in:                     $formOut     format_of_output_file
#       in:                     $extOutLoc   extension of expected output (fragments into _beg_end$extension)
#       in:                     $exeConvSeq  FORTRAN program convert_seq
#       in:                     $fileMatGcg  Maxhom_GCG.metric (for converting to HSSP)
#       in:                     $frag        fragments e.g. '1-5,10-100'
#       in:                     $fileScreen  output file for system commands
#       in:                     $doSplitChain split chains when converting to FASTA
#                               
#       out:                    converted file
#                               
#       out GLOBAL:             @fileOut,@kwdRm,$file{"kwd"} files to remove
#                               
#       err:                    0,$msg -> unspecified error 
#       err:                    1,$msg -> ok
#       err:                    2,$msg -> conversion option not supported
#-------------------------------------------------------------------------------
    $sbrName="$scrName:"."convDsspGen";$fhinLoc="FHIN"."$sbrName";
                                # ------------------------------
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc!")          if (! defined $fileInLoc);
    return(0,"*** $sbrName: not def chainInLoc!")         if (! defined $chainInLoc);
    return(0,"*** $sbrName: not def fileOutLoc!")         if (! defined $fileOutLoc);
    return(0,"*** $sbrName: not def formOut!")            if (! defined $formOut);
    return(0,"*** $sbrName: not def extOutLoc!")          if (! defined $extOutLoc);
    return(0,"*** $sbrName: not def frag!")               if (! defined $frag);
    return(0,"*** $sbrName: not def dirWork!")            if (! defined $dirWork);
    $fhSbr="STDOUT"                                       if (! defined $fhSbr);
    $doSplitChainLoc=0                                    if (! defined $doSplitChainLoc);

    return(0,"*** $sbrName: miss in file '$fileInLoc'!")  if (! -e $fileInLoc);

    $chainIn=$chainInLoc; $chainIn="*" if (! $chainInLoc          || 
					   length($chainInLoc)!=1 || 
					   $chainInLoc !~/[A-Z0-9]/);
                                # ------------------------------
    $#kwdRmTmp=0;               # temporary files
    $fhSysRunProg=0;
    $fhSysRunProg="STDOUT"      if ($par{"verb2"});
    $fileScreenLoc=0            if ($par{"debug"});

				# ------------------------------
				# chain over-rules fragments
    if (($chainInLoc && $chainInLoc =~ /[A-Z0-9]/) ||
	$doSplitChainLoc){
	($Lok,%tmp)=
	    &dsspGetChain($fileInLoc);
	return(0,"*** ERROR $sbrName: failed to extract chain from DSSP ($fileInLoc)\n") 
	    if (! $Lok);
	@tmp=split(/,/,$tmp{"chains"});
	if ($doSplitChainLoc){
	    @chainLoc=@tmp;}
	else {
	    $#chainLoc=0;}
	undef %chainLoc;
	foreach $it (1..$#tmp){
	    if    (! $doSplitChainLoc && $tmp[$it] eq $chainInLoc){
		$frag=$tmp{$chainInLoc,"beg"}."-".$tmp{$chainInLoc,"end"};
		last;}
	    else {
		$chainLoc{$tmp[$it],"beg"}=$tmp{$tmp[$it],"beg"};
		$chainLoc{$tmp[$it],"end"}=$tmp{$tmp[$it],"end"};
	    }
	}}
    else {
	$#chainLoc=0;}

    $#beg=$#end=0;              # ------------------------------
    if ($frag){                 # extract fragments?
        @tmp=split(/,/,$frag);$#beg=$#end=0;
        foreach $frag (@tmp){
	    next if ($frag !~ /\-/);$frag=~s/\s//g;
	    ($beg,$end)=split('-',$frag);
	    next if ($beg =~/\D/ || $end =~ /\D/);
	    push(@beg,$beg);push(@end,$end);}}

                                # ------------------------------
				# FASTA/mul, PIR/mul, SAF/MSF
    if   ($formOut =~/^pir/ || $formOut =~/^fasta/ || $formOut =~/^msf/ || $formOut =~/^saf/ ){
				# read entire DSSP sequence
	($Lok,$seqSmallCap,$seqDssp)=
	    &dsspRdSeq($fileInLoc,$chainIn);
	return(0,"*** ERROR $sbrName: failed to read dssp sequence for chain $chainIn\n".
	       $seqSmallCap."\n") 
	    if (! $Lok || length($seqDssp)<5); # security margin for chainbreaks

				# ******************************
				# set fragment to zero!
	if    ($chainIn ne "*"){
	    $#beg=$#end=0 ;}
	elsif ($#beg && $beg[1] > length($seqDssp)){
	    $#beg=$#end=0 ;}
	elsif ($#beg && (1+$end[1]-$beg[1]) > length($seqDssp)){
	    $#beg=$#end=0 ;}

        if ($#beg>0){           # loop over fragments
            foreach $it (1..$#beg){
		if (defined $chainIn && $chainIn && $chainIn ne "*" && length($chainIn)==1) {
		    $fileOutTmp=$fileOutLoc;
		    $id=$fileInLoc;$id=~s/^.*\/|\..*$//g; # purge dir
		    $id.="_".$chainIn;}
		else {
		    $fileOutTmp=$fileOutLoc;$fileOutTmp=~s/($extOutLoc)/\_$beg[$it]\_$end[$it]$1/;
		    $id=$fileInLoc;$id=~s/^.*\/|\..*$//g;} # purge dir
		$seqDsspTmp=substr($seqDssp,$beg[$it],($end[$it]-$beg[$it]+1));
		if (length($seqDsspTmp)<5){
		    print 
			"-*- WARN $sbrName: seq=$seqDsspTmp (beg=$beg[$it], end=$end[$it]) very short!\n";
		    next;}
		($Lok,$msg)=
		    &seqGenWrt($seqDsspTmp,$id,$formOut,$fileOutTmp,$fhSbr);
                return(0,"*** ERROR $sbrName: failed to write $formOut from DSSP\n"."$msg\n") 
                    if (! $Lok || ! -e $fileOutTmp);
                push(@fileOut,$fileOutTmp);}}
				# loop over chains
	elsif ($doSplitChainLoc){
	    foreach $chaintmp (@chainLoc){

		$seqDsspTmp=
		    substr($seqDssp,
			   $chainLoc{$chaintmp,"beg"},
			   (1+$chainLoc{$chaintmp,"end"}-$chainLoc{$chaintmp,"beg"}));
				# avoid duplicating identical chains
		next if (defined $tmp{$seqDsspTmp});
		$tmp{$seqDsspTmp}=1;
		if (length($seqDsspTmp)<5){
		    print 
			"-*- WARN $sbrName:  seq=$seqDsspTmp (beg=",
			$chainLoc{$chaintmp,"beg"}," end=",$chainLoc{$chaintmp,"end"},") very short!\n";
		    next;}
		if ($chaintmp !~ /^( |\*)$/ && length($chaintmp)==1){
		    $fileOutTmp=$fileOutLoc;
		    $id=$fileInLoc;
		    $id=~s/^.*\/|\..*$//g; # purge dir
		    $idnochain=$id;
		    $id.="_".$chaintmp;
		    $fileOutTmp=~s/$idnochain/$id/;}
		else {
		    $fileOutTmp=$fileOutLoc;
		    $id=$fileInLoc;$id=~s/^.*\/|\..*$//g;} # purge dir
		($Lok,$msg)=
		    &seqGenWrt($seqDsspTmp,$id,$formOut,$fileOutTmp,$fhSbr);
                return(0,"*** ERROR $sbrName: failed to write $formOut from DSSP\n"."$msg\n") 
                    if (! $Lok || ! -e $fileOutTmp);
                push(@fileOut,$fileOutTmp);}}
	
        else {
	    $id=$fileInLoc;$id=~s/^.*\/|\..*$//g; # purge dir
	    $id.="_".$chainIn if (defined $chainIn && $chainIn && 
				  $chainIn ne "*" && length($chainIn)==1);
	    ($Lok,$msg)=
		&seqGenWrt($seqDssp,$id,$formOut,$fileOutLoc,$fhSbr);
	    return(0,"*** ERROR $sbrName: failed to write $formOut from DSSP\n"."$msg\n") 
		if (! $Lok || ! -e $fileOutLoc);
	    push(@fileOut,$fileOutLoc);}
    }

                                # ------------------------------
				# HSSP
    elsif ($formOut eq "hssp"){
				# (1) read entire DSSP sequence
	($Lok,$seqSmallCap,$seqDssp)=
	    &dsspRdSeq($fileInLoc,$chainIn);
	return(0,"*** ERROR $sbrName: failed to read dssp sequence for chain $chainIn\n".
	       "$seqSmallCap\n") 
	    if (! $Lok || length($seqDssp)<5); # security margin for chainbreaks

        if ($#beg>0){           # (2a) loop over fragments
            foreach $it (1..$#beg){
		if (defined $chainIn && $chainIn && $chainIn ne "*" && length($chainIn)==1) {
		    $fileOutTmp=$fileOutLoc;
		    $id=$fileInLoc;$id=~s/^.*\/|\..*$//g; # purge dir
		    $id.="_".$chainIn;}
		else {
		    $fileOutTmp=$fileOutLoc;$fileOutTmp=~s/($extOutLoc)/\_$beg[$it]\_$end[$it]$1/;
		    $id=$fileInLoc;$id=~s/^.*\/|\..*$//g;} # purge dir
		$seqDsspTmp=substr($seqDssp,$beg[$it],($end[$it]-$beg[$it]+1));
		if (length($seqDsspTmp)<5){
		    print 
			"-*- WARN $sbrName: seq=$seqDsspTmp (beg=$beg[$it], end=$end[$it]) very short!\n";
		    next;}
				# (3a) convert to MSF
		$kwd="dssp-hssp"; push(@kwdRmTmp,$kwd);
		$fileOutMsf=$file{$kwd}=$dirWork.$par{"titleTmp"}.".msf_tmp";
		($Lok,$msg)=
		    &seqGenWrt($seqDsspTmp,$id,"msf",$fileOutMsf,$fhSbr);
                return(0,"*** ERROR $sbrName: failed to write MSF from DSSP\n"."$msg\n") 
                    if (! $Lok || ! -e $fileOutMsf);
				# (4a) blow up when single sequence
		if (&msfCountNali($fileOutMsf) == 1){
		    $kwd=$formIn."-".$formOut."-addSelf";push(@kwdRmTmp,$kwd);
		    $fileOutMsfTmp2=$file{$kwd}=$dirWork.$par{"titleTmp"}.".msf_tmpSelf";
		    ($Lok,$msg)=
			&msfBlowUp($fileOutMsf,$fileOutMsfTmp2);
		    return(0,"*** ERROR $sbrName: failed to write msf2 ($fileOutMsfTmp2)".
			   $msg."\n") if (! $Lok);
		    $fileOutMsf=$fileOutMsfTmp2;}
				# (5a) now convert_seq to write HSSP
		$cmd=           ""; # eschew warnings
		$an2=           "N"; # write another format?
				# gaps in master sequence as insertions?
		$anIns=         "N";
		$anFormOut=     "H"; # output = HSSP
		$anId=          " "; # specify id for master

		eval            "\$cmd=\"$exeConvSeq,$fileOutMsf,$anFormOut,$fileMatGcg,$anIns,$fileOutTmp,$anId,$an2\"";
				# run FORTRAN script
		($Lok,$msg)=
		    &sysRunProg($cmd,$fileScreenLoc,$fhSysRunProg);
		return(0,"*** ERROR $sbrName: failed to convert DSSP -> MSF -> HSSP\n".$msg."\n")
		    if (! $Lok || ! -e $fileOutTmp);
                push(@fileOut,$fileOutTmp);} }
        else {
				# (2b) no loop
	    $id=$fileInLoc;$id=~s/^.*\/|\..*$//g; # purge dir
	    $id.="_".$chainIn if (defined $chainIn && $chainIn && $chainIn ne "*" && length($chainIn)==1);
				# (3a) convert to MSF
	    $kwd="dssp-hssp"; push(@kwdRmTmp,$kwd);
	    $fileOutMsf=$file{$kwd}=$dirWork.$par{"titleTmp"}.".msf_tmp";
	    ($Lok,$msg)=
		&seqGenWrt($seqDssp,$id,"msf",$fileOutMsf,$fhSbr);
	    return(0,"*** ERROR $sbrName: failed to write MSF from DSSP\n"."$msg\n") 
		if (! $Lok || ! -e $fileOutMsf);
				# (4a) blow up when single sequence
	    if (&msfCountNali($fileOutMsf) == 1){
		$kwd=$formIn."-".$formOut."-addSelf";push(@kwdRmTmp,$kwd);
		$fileOutMsfTmp2=$file{$kwd}=$dirWork.$par{"titleTmp"}.".msf_tmpSelf";
		($Lok,$msg)=
		    &msfBlowUp($fileOutMsf,$fileOutMsfTmp2);
		return(0,"*** ERROR $sbrName: failed to write msf2 ($fileOutMsfTmp2)".
		       $msg."\n") if (! $Lok);
		$fileOutMsf=$fileOutMsfTmp2;}
				# (5a) now convert_seq to write HSSP
	    $cmd=           ""; # eschew warnings
	    $an2=           "N"; # write another format?
				# gaps in master sequence as insertions?
	    $anIns=         "N";
	    $anFormOut=     "H"; # output = HSSP
	    $anId=          " "; # specify id for master

	    eval            "\$cmd=\"$exeConvSeq,$fileOutMsf,$anFormOut,$fileMatGcg,$anIns,$fileOutLoc,$anId,$an2\"";
				# run FORTRAN script
	    ($Lok,$msg)=
		&sysRunProg($cmd,$fileScreenLoc,$fhSysRunProg);
	    return(0,"*** ERROR $sbrName: failed to convert DSSP -> MSF -> HSSP\n".$msg."\n")
		if (! $Lok || ! -e $fileOutMsf);
	    push(@fileOut,$fileOutLoc);} }
				# ------------------------------
				# unsupported output
				# ------------------------------
    else {
        return(2,"*** ERROR $sbrName: output option $formOut not supported for FSSP\n");}
                                # ------------------------------
                                # remove temporary files
    foreach $kwd(@kwdRmTmp){
        if (-e $file{$kwd}){ 
            print "--- \t $sbrName: remove (",$file{$kwd},") \n" 
		if (defined $par{"verb2"} && $par{"verb2"});
            unlink $file{$kwd};}}
				# clean up
    undef %tmp;			# slim-is-in
    undef %chainLoc;		# slim-is-in
    $#chainLoc=0;		# slim-is-in
    return(1,"ok $sbrName");
}				# end of convDsspGen

#===============================================================================
sub convFsspGen {
    local($fileInLoc,$fileOutLoc,$formOut,$extOutLoc,$exeConvFssp2daf,$fileIncl,$dirDsspLoc,$dirWork,$fhSbr) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   convFsspGen                 general converter for all FSSP in -> x
#       in:                     for general info see 'convFsspGen'
#       in:                     special:
#       in:                     $fileIncl: contains ids to include, syntax PDBids + chain 1pdbC (or h|f|dssp files)
#       out:                    converted file
#       out GLOBAL:             @fileOut,@kwdRm,$file{"kwd"} files to remove
#       err:                    0,$msg -> unspecified error 
#       err:                    1,$msg -> ok
#       err:                    2,$msg -> conversion option not supported
#-------------------------------------------------------------------------------
    $sbrName="$scrName:"."convFsspGen";$fhinLoc="FHIN_"."$sbrName";
                                # ------------------------------
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc!")           if (! defined $fileInLoc);
    return(0,"*** $sbrName: not def fileOutLoc!")          if (! defined $fileOutLoc);
    return(0,"*** $sbrName: not def formOut!")             if (! defined $formOut);
    return(0,"*** $sbrName: not def extOutLoc!")           if (! defined $extOutLoc);
    return(0,"*** $sbrName: not def exeConvFssp2daf!")     if (! defined $exeConvFssp2daf);
    return(0,"*** $sbrName: not def fileIncl!")            if (! defined $fileIncl);
    return(0,"*** $sbrName: not def dirDsspLoc!")          if (! defined $dirDsspLoc);
    return(0,"*** $sbrName: not def dirWork!")             if (! defined $dirWork);
    $fhSbr="STDOUT"                                        if (! defined $fhSbr);
    return(0,"*** $sbrName: miss in file '$fileInLoc'!")   if (! -e $fileInLoc);
    return(0,"*** $sbrName: miss exe '$exeConvFssp2daf'!") if (! -e $exeConvFssp2daf && ! -l $exeConvFssp2daf);
    return(0,"*** $sbrName: miss in file '$fileIncl'!")    if ($fileIncl && ! -e $fileInLoc);
    return(0,"*** $sbrName: miss dssp dir '$dirDsspLoc'!") if (! -d $dirDsspLoc);
                                # ------------------------------
                                # supported output options

    $cmd=              "";      # eschew warnings
    $an2=              "N";     # write another format?

                                # ------------------------------
    if    ($formOut eq "daf"){  # 2 daf
				# --------------------
	$#incl=0;$incl="unk";   # read include file
	if ($fileIncl && -e $fileIncl){
	    open("$fhinLoc","$fileIncl") ||
                return(0,"*** $sbrName failed opening fileIn=$fileIncl\n");
            $incl="";
            while(<$fhinLoc>){next if (/^\#/);$_=~s/\n|\s//g;
                              next if (length($_)<3);
                              $_=~s/^.*\///g;$_=~s/\.[dhf]ssp[_!]*//g;
                              push(@incl,$_);$incl.="$_,";}close($fhinLoc);
            $incl=~s/,$//g;}
	$fileDafTmp=$dirWork.$par{"titleTmp"}."-fssp".$extOutLoc;
	$Lok=
	    &convFssp2Daf($fileInLoc,$fileOutLoc,$fileDafTmp,$exeConvFssp2daf,$dirDsspLoc);
        return(0,"*** ERROR $sbrName: failed to convert $fileInLoc to DAF $fileOutLoc, tmp=$fileDafTmp, ".
               "exe=$exeConvFssp2daf\n") if (! $Lok || ! -e $fileOutLoc);
        print 
	    "--- \t $sbrName: remove ($fileDafTmp) \n" if (defined $par{"verb2"} && $par{"verb2"});
	unlink $fileDafTmp;
        push(@fileOut,$fileOutLoc);}
    else {
        return(2,"*** ERROR $sbrName: output option $formOut not supported for FSSP\n");}
    return(1,"ok $sbrName");
}				# end of convFsspGen

#===============================================================================
sub convHsspGen {
    local($fileInLoc,$chainInLoc,$fileOutLoc,$formOut,$extOutLoc,$exeConvSeq,$exeConvHssp2saf,
          $doExpand,$frag,$extrIn,$fileScreenLoc,$dirWork,$fhSbr,$doSplitChainLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   convHsspGen                 general converter for all HSSP in -> x
#       in:                     $fileInLoc,$chainIn,$fileOutLoc,$formOut,$extOutLoc,$exeConvSeq,
#       in:                     $doExpand,$frag,$extrIn,$dirWork,$fileScreenLoc,$fhSbr
#       in:                     $fileInLoc   file.hssp, file.out, format_of_output_file
#       in:                     $fileOutLoc  output file with converted sequence(s)
#       in:                                  NOTE: if many appended to @fileOut
#       in:                     $formOut     output format (lower caps)
#       in:                     $extOutLoc   extension of expected output (fragments into _beg_end$extension)
#       in:                     $exeConvSeq  the good old FORTRAN convert_seq
#       in:                     $exeConvHssp2saf the new perl script doing it
#       in:                     $doExpand    do expand the deletions? (only for MSF)
#       in:                     $frag        fragments e.g. '1-5,10-100'
#       in:                     $extrIn      number of protein to extract
#       in:                     $dirWork     directory for temporary files
#       in:                     $fileScreen  file to dump convert_seq ..
#       in:                     $fhSbr       ERRORs of convert_seq
#       in:                     $doSplitChain split chains when converting to FASTA
#                               
#       out:                    converted file
#       out GLOBAL:             @fileOut,@kwdRm,$file{"kwd"} files to remove
#                               
#       err:                    0,$msg -> unspecified error 
#       err:                    1,$msg -> ok
#       err:                    2,$msg -> conversion option not supported
#-------------------------------------------------------------------------------
    $sbrName="$scrName:"."convHsspGen";$fhinLoc="FHIN"."$sbrName";
                                # ------------------------------
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc!")           if (! defined $fileInLoc);
    $chainInLoc="*"                                        if (! defined $chainInLoc);
    return(0,"*** $sbrName: not def fileOutLoc!")          if (! defined $fileOutLoc);
    return(0,"*** $sbrName: not def formOut!")             if (! defined $formOut);
    return(0,"*** $sbrName: not def extOutLoc!")           if (! defined $extOutLoc);
    return(0,"*** $sbrName: not def exeConvSeq!")          if (! defined $exeConvSeq);
    return(0,"*** $sbrName: not def exeConvHssp2saf!")     if (! defined $exeConvHssp2saf);
    return(0,"*** $sbrName: not def doExpand!")            if (! defined $doExpand);
    return(0,"*** $sbrName: not def frag!")                if (! defined $frag);
    return(0,"*** $sbrName: not def extrIn!")              if (! defined $extrIn);
    return(0,"*** $sbrName: not def fileScreenLoc!")       if (! defined $fileScreenLoc);
    return(0,"*** $sbrName: not def dirWork!")             if (! defined $dirWork);
    $fhSbr="STDOUT"                                        if (! defined $fhSbr);
    $doSplitChainLoc=0                                     if (! defined $doSplitChainLoc);

    return(0,"*** $sbrName: miss in file '$fileInLoc'!")   if (! -e $fileInLoc);
    return(0,"*** $sbrName: miss exe '$exeConvSeq'!")      if (! -e $exeConvSeq && ! -l $exeConvSeq);
    return(0,"*** $sbrName: miss exe '$exeConvHssp2saf'!") if (! -e $exeConvHssp2saf && ! -l $exeConvHssp2saf);
    $msgErr="";
    $fhSysRunProg=0;
    $fhSysRunProg="STDOUT"      if ($par{"verb2"});
    $fileScreenLoc=0            if ($par{"debug"});
                                # ------------------------------
                                # supported output options
    if ($frag && $formOut eq "daf"){
        print "-*- WARN $sbrName: fragment selection not supported for hssp->$formOut\n";
        $frag=0;}
    if ($doExpand && $formOut eq "daf"){
        print "-*- WARN $sbrName: expansion of HSSP automatic (?) for hssp->$formOut\n";
        $doExpand=0;}
				# ------------------------------
				# chain over-rules fragments
    if ($chainInLoc && $chainInLoc =~ /[A-Z0-9]/){
	($len,$ifir,$ilas)=
	    &hsspGetChainLength($fileInLoc,$chainInLoc);
				# ignore!!!! for output which read only chains!!
	if ($formOut !~ /^(pir|fasta)/){
	    $frag="$ifir-$ilas" if ($len>0); }
    }
    $#beg=$#end=0;              # ------------------------------
    if ($frag){                 # extract fragments?
        @tmp=split(/,/,$frag);$#beg=$#end=0;
        foreach $frag(@tmp){next if ($frag !~ /\-/);$frag=~s/\s//g;
                            ($beg,$end)=split('-',$frag);
                            next if ($beg =~/\D/ || $end =~ /\D/);push(@beg,$beg);push(@end,$end);}}
    $#kwdRmTmp=0;               # temporary files
    $cmd=              "";      # eschew warnings
    $an2=              "N";     # write another format?
    $anExpand=         "N";	# expand sequences (i.e. fill in insertion list)
    $anExpand=         "Y"      if ($doExpand);

                                # ------------------------------
    if    ($formOut eq "daf"){  # 2 daf
        $anFormOut=    "d";
        $an1=          "N";     # fragment? (if: prompted for two integers: beg end)
        eval           "\$cmd=\"$exeConvSeq,$fileInLoc,$anFormOut,$an1,$fileOutLoc,$an2\"";
				# run FORTRAN script
        ($Lok,$msg)=&sysRunProg($cmd,$fileScreenLoc,$fhSysRunProg);
        return(0,"*** ERROR $sbrName: failed to convert hssp to daf\n".$msg."\n") 
	    if (! $Lok || ! -e $fileOutLoc);
        push(@fileOut,$fileOutLoc);}
                                # ------------------------------
                                # MSF
    elsif ($formOut eq "msf") {
        $anFormOut=    "m";
        if ($#beg>0){           # loop over fragments
            foreach $it (1..$#beg){
                if ($formOut eq "saf"){
                    $kwd=$formOut.$it;
                    $fileOutTmp=$file{$kwd}=$dirWork.$par{"titleTmp"}.$kwd.$extOutLoc;
                    push(@kwdRmTmp,$kwd);}
                else                  {
                    $fileOutTmp=$fileOutLoc;$fileOutTmp=~s/(\.$extOutLoc)/\_$beg[$it]\_$end[$it]$1/;}
                $an1=   "Y";    # fragment? (if: prompted for two integers: beg end)
                $anF=   "$beg[$it] $end[$it]"; # answer for fragment
                eval    "\$cmd=\"$exeConvSeq,$fileInLoc,$anFormOut,$an1,$anF,$fileOutTmp,$anExpand,$an2\"";
				# run FORTRAN script
                ($Lok,$msg)=&sysRunProg($cmd,$fileScreenLoc,$fhSysRunProg);
                $msgErr.="*** ERROR $sbrName: failed to convert hssp to MSF frag $it \n".$msg."\n" 
                    if (! $Lok || ! -e $fileOutTmp);
                push(@fileOut,$fileOutTmp);}
            return(0,$msgErr) if ($msgErr =~ /ERROR/);}
        else {
            $an1=       "N";     # fragment? (if: prompted for two integers: beg end)
	    $fileOutTmp=$fileOutLoc;
            eval        "\$cmd=\"$exeConvSeq,$fileInLoc,$anFormOut,$an1,$fileOutTmp,$anExpand,$an2\"";
				# run FORTRAN script
            ($Lok,$msg)=&sysRunProg($cmd,$fileScreenLoc,$fhSysRunProg);
            return(0,"*** ERROR $sbrName: failed to convert hssp to MSF\n".$msg."\n")
                if (! $Lok || ! -e $fileOutTmp);
            push(@fileOut,$fileOutTmp);}}
                                # ------------------------------
                                # SAF
    elsif ($formOut eq "saf" ){
        if ($#beg>0){           # loop over fragments
            foreach $it (1..$#beg){
		$fileOutTmp=$fileOutLoc;$fileOutTmp=~s/(\.$extOutLoc)/\_$beg[$it]\_$end[$it]$1/;

		@tmp=($fileInLoc,"fileOut=$fileOutTmp");
		push(@tmp,"frag=$beg[$it]-$end[$it]");
		push(@tmp,"extr=$extrIn")      if (defined $extrIn && $extrIn);
		push(@tmp,"expand")            if ($doExpand);
		push(@tmp,"debug")             if (! $fileScreenLoc);
				# call package
		($Lok,$msg)=&conv_hssp2saf::conv_hssp2saf(@tmp);

                $msgErr.="*** ERROR $sbrName: failed to convert hssp to SAF frag $it \n".$msg."\n" 
                    if (! $Lok || ! -e $fileOutTmp);
                push(@fileOut,$fileOutTmp);}
            return(0,$msgErr) if ($msgErr =~ /ERROR/);}
        else {
            $fileOutTmp=$fileOutLoc;
	    @tmp=($fileInLoc,"fileOut=$fileOutTmp");
	    push(@tmp,"extr=$extrIn")      if (defined $extrIn && $extrIn);
	    push(@tmp,"expand")            if ($doExpand);
	    push(@tmp,"debug")             if (! $fileScreenLoc);
				# call package
	    ($Lok,$msg)=&conv_hssp2saf::conv_hssp2saf(@tmp);
            return(0,"*** ERROR $sbrName: failed to convert hssp to Saf\n".$msg."\n")
                if (! $Lok || ! -e $fileOutTmp);
            push(@fileOut,$fileOutTmp);}}
                                # ------------------------------
                                # FASTA/PIR mul
    elsif ($formOut eq "pirmul" || $formOut eq "fastamul"
	   || $formOut eq "fasta" || $formOut eq "pir" ){
        $anFormOut=     substr($formOut,1,1);
        $Lone=$extr=0;          # extract only some sequences?
        if ($formOut eq "fasta" || $formOut eq "pir" ){
            $Lone=1;$extr=$extrIn;$extr=1  if (! defined $extr || $extr < 1);}
	$extr="guide"           if ($Lone);
				# --------------------
        if ($#beg>0){           # loop over fragments
            foreach $it (1..$#beg){
                $fileOutTmp=$fileOutLoc;$fileOutTmp=~s/(\.$extOutLoc)/\_$beg[$it]\_$end[$it]$1/;
		$fragTmp=$beg[$it]."-".$end[$it];
				# sbr call
		($Lok,$msg)=
		    &convHssp2seq($fileInLoc,$chainInLoc,$fileOutTmp,$formOut,$extOutLoc,
				  $doExpand,$fragTmp,$extr,0,0,0,0,$fhSbr);
		return(&errSbrMsg("failed HSSP -> $formOut (sbr)",$msg)) if (! $Lok);
				# no output -> skip
                if (! -e $fileOutTmp){
		    $msgErr.="*** ERROR $sbrName: failed to convert hssp to $formOut frag $it\n";
		    next; }
                                # extract particular sequence
                push(@fileOut,$fileOutTmp); } }
				# --------------------
        else {                  # NO fragment
            $fileOutTmp=$fileOutLoc;
	    $fragTmp=0;
				# sbr call
	    ($Lok,$msg)=
		&convHssp2seq($fileInLoc,$chainInLoc,$fileOutTmp,$formOut,$extOutLoc,
			      $doExpand,$fragTmp,$extr,0,0,0,0,$fhSbr,$doSplitChainLoc);
	    return(&errSbrMsg("failed HSSP -> $formOut (sbr)",$msg)) if (! $Lok || ! -e $fileOutTmp);
                                # extract particular sequence
	    push(@fileOut,$fileOutTmp); } }
    else {
        return(2,"*** ERROR $sbrName: output option $formOut not supported for HSSP\n");}
                                # ------------------------------
                                # remove temporary files
    foreach $kwd(@kwdRmTmp){
        if (-e $file{$kwd}){ 
            print "--- \t $sbrName: remove (",$file{$kwd},") \n" 
		if (defined $par{"verb2"} && $par{"verb2"});
            unlink $file{$kwd};}}
    return(1,"ok $sbrName");
}				# end of convHsspGen

#===============================================================================
sub convPirmulGen {
    local($fileInLoc,$fileOutLoc,$formOut,$extOutLoc,$frag,$extrIn,$dirWork,$fhSbr) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   convPirmulGen               general converter for all PIRMUL in -> x
#       in:                     for general info see 'convPirmulGen'
#       out:                    converted file
#       out GLOBAL:             @fileOut,@kwdRm,$file{"kwd"} files to remove
#       err:                    0,$msg -> unspecified error 
#       err:                    1,$msg -> ok
#       err:                    2,$msg -> conversion option not supported
#-------------------------------------------------------------------------------
    $sbrName="$scrName:"."convPirmulGen";$fhinLoc="FHIN"."$sbrName";
                                # ------------------------------
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc!")          if (! defined $fileInLoc);
    return(0,"*** $sbrName: not def fileOutLoc!")         if (! defined $fileOutLoc);
    return(0,"*** $sbrName: not def formOut!")            if (! defined $formOut);
    return(0,"*** $sbrName: not def extOutLoc!")          if (! defined $extOutLoc);
    return(0,"*** $sbrName: not def frag!")               if (! defined $frag);
    return(0,"*** $sbrName: not def dirWork!")            if (! defined $dirWork);
    $fhSbr="STDOUT"                                       if (! defined $fhSbr);
    return(0,"*** $sbrName: miss in file '$fileInLoc'!")  if (! -e $fileInLoc);
                                # ------------------------------
    $#kwdRmTmp=0;               # temporary files

    $#beg=$#end=0;              # ------------------------------
    if ($frag){                 # extract fragments?
        @tmp=split(/,/,$frag);$#beg=$#end=0;
        foreach $frag(@tmp){next if ($frag !~ /\-/);$frag=~s/\s//g;
                            ($beg,$end)=split('-',$frag);
                            next if ($beg =~/\D/ || $end =~ /\D/);push(@beg,$beg);push(@end,$end);}}
                                # ------------------------------
                                # only to FASTA and FASTAmul
    if    ($formOut eq "fasta" || $formOut eq "fastamul" ){
        $Lone=$extr=0;          # extract only some sequences?
        if ($formOut eq "fasta"){
            $Lone=1;$extr=$extrIn;$extr=1 if (! defined $extr || $extr < 1);}
        if ($#beg>0){           # loop over fragments
            foreach $it (1..$#beg){
                $fileOutTmp=$fileOutLoc;$fileOutTmp=~s/(\.$extOutLoc)/\_$beg[$it]\_$end[$it]$1/;
                $fragHere="$beg[$it]-$end[$it]";
                ($Lok,$msg)=
                    &convPir2fasta($fileInLoc,$fileOutTmp,$fragHere,$extr);
                return(0,"*** ERROR $sbrName: failed to convert pirmul to $formOut\n"."$msg\n") if (! $Lok);
                push(@fileOut,$fileOutTmp);}}
        else {$fragHere=0;
              ($Lok,$msg)=
                  &convPir2fasta($fileInLoc,$fileOutLoc,$fragHere,$extr);
              return(0,"*** ERROR $sbrName: failed to convert pirmul to $formOut\n"."$msg\n") if (! $Lok);
	      push(@fileOut,$fileOutLoc);}}
    else {
        return(2,"*** ERROR $sbrName: output option $formOut not supported for FSSP\n");}
    return(1,"ok $sbrName");
}				# end of convPirmulGen

#===============================================================================
sub convSeqGen {
    local($fileInLoc,$fileOutLoc,$formIn,$formOut,$extOutLoc,
	  $exeConvSeq,$frag,$fileScreenLoc,$dirWork,$fhSbr) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   convSeqGen                  general converter for all sequence formats into -> x
#       in:                     for general info see 'convSeqGen'
#       out:                    converted file
#       out GLOBAL:             @fileOut,@kwdRm,$file{"kwd"} files to remove
#       err:                    0,$msg -> unspecified error 
#       err:                    1,$msg -> ok
#       err:                    2,$msg -> conversion option not supported
#-------------------------------------------------------------------------------
    $sbrName="$scrName:"."convSeqGen";$fhinLoc="FHIN"."$sbrName";
                                # ------------------------------
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc!")          if (! defined $fileInLoc);
    return(0,"*** $sbrName: not def fileOutLoc!")         if (! defined $fileOutLoc);
    return(0,"*** $sbrName: not def formIn!")             if (! defined $formIn);
    return(0,"*** $sbrName: not def formOut!")            if (! defined $formOut);
    return(0,"*** $sbrName: not def extOutLoc!")          if (! defined $extOutLoc);
    return(0,"*** $sbrName: not def exeConvSeq!")         if (! defined $exeConvSeq);
    return(0,"*** $sbrName: not def frag!")               if (! defined $frag);
    return(0,"*** $sbrName: not def fileScreenLoc!")      if (! defined $fileScreenLoc);
    return(0,"*** $sbrName: not def dirWork!")            if (! defined $dirWork);
    $fhSbr="STDOUT"                                       if (! defined $fhSbr);
    return(0,"*** $sbrName: miss in file '$fileInLoc'!")  if (! -e $fileInLoc);
    return(0,"*** $sbrName: miss exe '$exeConvSeq'!")     if (! -e $exeConvSeq && ! -l $exeConvSeq);


    $#beg=$#end=0;              # ------------------------------
    if ($frag){                 # extract fragments?
        @tmp=split(/,/,$frag);$#beg=$#end=0;
        foreach $frag(@tmp){
	    next if ($frag !~ /\-/);$frag=~s/\s//g;
	    ($beg,$end)=split('-',$frag);
	    next if ($beg =~/\D/ || $end =~ /\D/);push(@beg,$beg);push(@end,$end);}}
                                # ------------------------------
                                # only sequence formats
    if    ($formOut eq "fasta" || $formOut eq "pir" || $formOut eq "gcg"){
        if ($#beg>0){           # loop over fragments
            foreach $it (1..$#beg){
                $fileOutTmp=$fileOutLoc;$fileOutTmp=~s/(\.$extOutLoc)/\_$beg[$it]\_$end[$it]$1/;
                $fragHere="$beg[$it]-$end[$it]";
                ($Lok,$msg)=
		    &convSeq2seq($fileInLoc,$formIn,$fileOutTmp,$formOut,$fragHere,$fileScreenLoc,$fhSbr);
				 
#                ($Lok,$msg)=
#                    &convSeq2seqOld($exeConvSeq,$fileInLoc,$fileOutTmp,$formOut,$fragHere,$fileScreenLoc,$fhSbr);
                return(0,"*** ERROR $sbrName: failed to convert fasta to $formOut\n"."$msg\n") if (! $Lok);
                push(@fileOut,$fileOutTmp);}}
        else {$fragHere=0;
	      ($Lok,$msg)=
		  &convSeq2seq($fileInLoc,$formIn,$fileOutLoc,$formOut,$fragHere,$fileScreenLoc,$fhSbr);
#              ($Lok,$msg)=
#                  &convSeq2seqOld($exeConvSeq,$fileInLoc,$fileOutLoc,$formOut,$fragHere,$fileScreenLoc,$fhSbr);
              return(0,"*** ERROR $sbrName: failed to convert fasta to $formOut\n"."$msg\n") if (! $Lok);
	      push(@fileOut,$fileOutLoc);}}
                                # ------------------------------
				# convert to SAF
    elsif ($formOut eq "saf" && $formIn eq "fasta"){
        if ($#beg>0){           # loop over fragments
            foreach $it (1..$#beg){
                $fileOutTmp=$fileOutLoc;$fileOutTmp=~s/(\.$extOutLoc)/\_$beg[$it]\_$end[$it]$1/;
		($Lok,$id,$seq)=&fastaRdGuide($fileInLoc);
		$tmp{"seq","1"}=substr($seq,$beg[$it],($end[$it]-$beg[$it]+1));
		$tmp{"NROWS"}=  1;$tmp{"id","1"}= $id;
                ($Lok,$msg)=&safWrt($fileOutTmp,%tmp);
                return(0,"*** ERROR $sbrName: failed to convert fasta to $formOut\n"."$msg\n") if (! $Lok);
                push(@fileOut,$fileOutTmp);}}
        else {$fragHere=0;
	      ($Lok,$id,$tmp{"seq","1"})=
		  &fastaRdGuide($fileInLoc);
	      return(0,"*** ERROR $sbrName: failed to convert fasta to $formOut\n"."$msg\n") if (! $Lok);
	      $id=~s/^(\S+).*$/$1/;
	      $tmp{"NROWS"}=  1;$tmp{"id","1"}= $id;
	      ($Lok,$msg)=&safWrt($fileOutLoc,%tmp);
              return(0,"*** ERROR $sbrName: failed to convert fasta to $formOut\n"."$msg\n") if (! $Lok);
	      push(@fileOut,$fileOutLoc);}}
    else {
        return(2,"*** ERROR $sbrName: output option $formOut not supported for $formIn\n");}
    return(1,"ok $sbrName");
}				# end of convSeqGen

#===============================================================================
sub convPdbGen {
    local($fileInLoc,$chainInLoc,$fileOutLoc,$formOut,$extOutLoc,$frag,$dirWork,$fhSbr) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   convPdbGen                  general converter for all sequence formats into -> x
#       in:                     for general info see 'convPdbGen'
#       out:                    converted file
#       out GLOBAL:             @fileOut,@kwdRm,$file{"kwd"} files to remove
#       err:                    0,$msg -> unspecified error 
#       err:                    1,$msg -> ok
#       err:                    2,$msg -> conversion option not supported
#-------------------------------------------------------------------------------
    $sbrName="$scrName:"."convPdbGen";$fhinLoc="FHIN"."$sbrName";
                                # ------------------------------
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc!")          if (! defined $fileInLoc);
    return(0,"*** $sbrName: not def chainInLoc!")         if (! defined $chainInLoc);
    return(0,"*** $sbrName: not def fileOutLoc!")         if (! defined $fileOutLoc);
    return(0,"*** $sbrName: not def formOut!")            if (! defined $formOut);
    return(0,"*** $sbrName: not def extOutLoc!")          if (! defined $extOutLoc);
    return(0,"*** $sbrName: not def frag!")               if (! defined $frag);
    return(0,"*** $sbrName: not def dirWork!")            if (! defined $dirWork);
    $fhSbr="STDOUT"                                       if (! defined $fhSbr);
    return(0,"*** $sbrName: miss in file '$fileInLoc'!")  if (! -e $fileInLoc);

    $#beg=$#end=0;              # ------------------------------
    if ($frag){                 # extract fragments?
        @tmp=split(/,/,$frag);$#beg=$#end=0;
        foreach $frag(@tmp){
	    next if ($frag !~ /\-/);$frag=~s/\s//g;
	    ($beg,$end)=split('-',$frag);
	    next if ($beg =~/\D/ || $end =~ /\D/);push(@beg,$beg);push(@end,$end);}}
                                # ------------------------------
				# PDB
    return(2,"*** ERROR $sbrName: output option $formOut not supported for $formIn\n")
	if ($formOut !~/^(fasta|pir|gcg)/);

    if ($#beg>0){		# loop over fragments
	foreach $it (1..$#beg){
	    $fileOutTmp=$fileOutLoc;$fileOutTmp=~s/(\.$extOutLoc)/\_$beg[$it]\_$end[$it]$1/;
				# read sequence
		
	    ($Lok,$msg)=
		&convPdb2seq($fileInLoc,$chainInLoc,$fileOutTmp,$formOut,$fragHere,$fhSbr);
	    return(0,"*** ERROR $sbrName: failed to convert PDB to $formOut\n".
		   "$msg\n") if (! $Lok);
	    push(@fileOut,$fileOutTmp);}}
    else {
	$fragHere=0;
	($Lok,$msg)=
	    &convPdb2seq($fileInLoc,$chainInLoc,$fileOutLoc,$formOut,$fragHere,$fhSbr);
              return(0,"*** ERROR $sbrName: failed to convert PDB to $formOut\n".
		     "$msg\n") if (! $Lok);
	push(@fileOut,$fileOutLoc); }

    return(1,"ok $sbrName");
}				# end of convPdbGen

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
	    &fctRunTimeLeft($timeBeg,$nfileIn,$itFile);
	$estimate="?"           if ($itFile < 5);
	$tmp=  sprintf("%4d (%4.1f%-1s), time left=%-s",
		       $itFile,(100*$itFile/$nfileIn),"%",$estimate); }
    else {
	$tmp="file no=".$itFile; }
    $tmpWrt= "$formIn -> $formOut: $fileIn -> $fileOutDef ";
    $tmpWrt.=$tmp;
    print $fhLoc "$tmpWrt\n";
}				# end of wrtLoc

1;
