#------------------------------------------------------------------------------#
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
    $okFormIn=   "hssp,dssp,fssp,msf,saf,fastamul,pirmul,fasta,pir,gcg,phdrdb,swiss";
                             @okFormOut=split(/,/,$okFormOut);@okFormIn=split(/,/,$okFormIn);
                             $okFormOutOr=join('|',@okFormOut);$okFormInOr=join('|',@okFormIn);
    $scrHelpTxt= "Formats supported: \n";
    $scrHelpTxt.="  * Input:   ".  $okFormOut."\n";
    $scrHelpTxt.="  * Output:  ".  $okFormIn ."\n";
    $scrHelpTxt.="    \n";
    $scrHelpTxt.="Several ways to run the script:\n";
    $scrHelpTxt.="in: 'file.msf file.hssp'  -> convert MSF to HSSP (assigned according to extensions)\n"; # 
    $scrHelpTxt.="in: '*.msf hssp'          -> all input MSF files converted to HSSP\n";
    $scrHelpTxt.="in: 'file.list hssp list' -> all files listed in 'file.list' converted to HSSP\n";
    $scrHelpTxt.="                             NOTE: the keyword 'list' makes things easier for me...\n";
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

    ($Lok,$msg)=  &ini;		# initialise variables
    if (! $Lok){print "*** ERROR $scrName after ini\n",$msg,"\n";
		die '--> ERROR during initialising $scrName   ';}

#-------------------------------------------------------------------------------
# do the job (here we go)
#-------------------------------------------------------------------------------
                                # general assignments to reduce typing
    $formIn= $par{"formatIn"};  $extIn= $par{"ext_$formIn"};
    $formOut=$par{"formatOut"}; $extOut=$par{"ext_$formOut"};
    $fh="STDOUT" if ($Lverb);
    $fh=$fhTrace if (! $Lverb);
                                # --------------------------------------------------
                                # alignments
                                # --------------------------------------------------
                                # ------------------------------
    if    ($formIn eq "hssp"){	# in: HSSP
	foreach $itFile (1..$#fileIn){
	    print $fh "--- \t $formIn -> $formOut: $fileIn[$itFile] -> $fileOutDef[$itFile]\n" 
		if ($par{"verbose"});
	    ($Lok,$msg)=
		&convHsspGen($fileIn[$itFile],$chainIn[$itFile],$fileOutDef[$itFile],$formOut,$extOut,
			     $par{"exeConvertSeq"},$par{"exeConvHssp2saf"},
			     $par{"doExpand"},$par{"frag"},$par{"extr"},
			     $par{"fileOutScreen"},$par{"dirWork"},$fhTrace);
	    print $fh "*** ERROR $scrName after convHsspGen\n","*** $msg\n" if (! $Lok || $Lok==2);}}
                                # ------------------------------
    elsif ($formIn eq "fssp"){	# in: FSSP
	foreach $itFile (1..$#fileIn){
	    print $fh "--- \t $formIn -> $formOut: $fileIn[$itFile] -> $fileOutDef[$itFile]\n" 
		if ($par{"verbose"});
	    ($Lok,$msg)=
		&convFsspGen($fileIn[$itFile],$fileOutDef[$itFile],$formOut,$extOut,$par{"exeFssp2daf"},
			     $par{"fileInclProt"},$par{"dirDssp"},$par{"dirWork"},$fhTrace);
	    print $fh "*** ERROR $scrName after convFsspGen\n","*** $msg\n" if (! $Lok || $Lok==2);}}
                                # ------------------------------
                                # in: MSF|SAF|FASTAmul
    elsif ($formIn eq "msf" || $formIn eq "saf" || $formIn eq "fastamul"){
	foreach $itFile (1..$#fileIn){
	    print $fh "--- \t $formIn -> $formOut:  $fileIn[$itFile] -> $fileOutDef[$itFile]\n" 
		if ($par{"verbose"});
	    ($Lok,$msg)=
		&convAliGen($fileIn[$itFile],$fileOutDef[$itFile],$formIn,$formOut,$extOut,
			    $par{"exeConvertSeq"},$par{"fileMatGcg"},$par{"doCompress"},
			    $par{"frag"},$par{"extr"},$par{"fileOutScreen"},$par{"dirWork"},$fhTrace);
	    print $fh "*** ERROR $scrName after convAliGen\n","*** $msg\n" if (! $Lok || $Lok==2);}}
				# ------------------------------
    elsif ($formIn eq "pirmul"){ # in: PIRMUL
	foreach $itFile (1..$#fileIn){
	    print $fh "--- \t $formIn -> $formOut:  $fileIn[$itFile] -> $fileOutDef[$itFile]\n" 
		if ($par{"verbose"});
	    ($Lok,$msg)=
		&convPirmulGen($fileIn[$itFile],$fileOutDef[$itFile],$formOut,$extOut,
			       $par{"frag"},$par{"extr"},$par{"dirWork"},$fhTrace);
	    print $fh "*** ERROR $scrName after convPirmulGen\n","*** $msg\n" if (! $Lok || $Lok==2);}}

                                # --------------------------------------------------
                                # sequences
                                # --------------------------------------------------
                                # ------------------------------
                                # in: FASTA, SWISS, PIR, GCG
    elsif ($formIn eq "fasta" || $formIn eq "swiss" || $formIn eq "pir"  || $formIn eq "gcg"){
	foreach $itFile (1..$#fileIn){ # 
	    print $fh "--- \t $formIn -> $formOut:  $fileIn[$itFile] -> $fileOutDef[$itFile]\n" 
		if ($par{"verbose"});
				# out: ali
	    if ($formOut eq "hssp"){
		($Lok,$msg)=
		    &convAliGen($fileIn[$itFile],$fileOutDef[$itFile],$formIn,$formOut,$extOut,
				$par{"exeConvertSeq"},$par{"fileMatGcg"},$par{"doCompress"},
				$par{"frag"},$par{"extr"},$par{"fileOutScreen"},$par{"dirWork"},$fhTrace);
		print $fh "*** ERROR $scrName after convAliGen\n","*** $msg\n" if (! $Lok || $Lok==2); }

				# out: sequence
	    else {
		($Lok,$msg)=
		    &convSeqGen($fileIn[$itFile],$fileOutDef[$itFile],$formIn,$formOut,$extOut,
				$par{"exeConvertSeq"},$par{"frag"},$par{"fileOutScreen"},
				$par{"dirWork"},$fhTrace);
		print $fh "*** ERROR $scrName after convSeqGen\n","*** $msg\n" if (! $Lok || $Lok==2);}}}
                                # ------------------------------
    elsif ($formIn eq "dssp"){	# in: DSSP
	if ($formOut !~ /^(fasta|pir|saf|msf|hssp)/){   # 
	    print $fh "*** ERROR $scrName supported only DSSP -> FASTA|PIR|MSF|SAF2\n";
	    die ' sorry ';}         # 
	foreach $itFile (1..$#fileIn){
	    $chainIn=0;
	    $chainIn=$chainIn[$itFile] if (defined $chainIn[$itFile]);
	    print $fh "--- \t $formIn -> $formOut:  $fileIn[$itFile] -> $fileOutDef[$itFile]\n" 
		if ($par{"verbose"});
	    ($Lok,$msg)=
		&convDsspGen($fileIn[$itFile],$chainIn,$fileOutDef[$itFile],$formOut,$extOut,
			     $par{"exeConvertSeq"},$par{"fileMatGcg"},
			     $par{"frag"},$par{"fileOutScreen"},$par{"dirWork"},$fhTrace);
	    print $fh "*** ERROR $scrName after convDsspGen\n","*** $msg\n" if (! $Lok || $Lok==2);}}
    else {
	print "*** ERROR $scrName input format $formIn not supported\n";
	die '  sorry ... ';}

#-------------------------------------------------------------------------------
# work done, go home
#-------------------------------------------------------------------------------
                                # ------------------------------
                                # deleting intermediate files
    &cleanUp() if (! $par{"debug"}); 
                                # ------------------------------
                                # final words
    if ($Lverb) { $timeEnd=time; # runtime , run time
		  $timeRun=$timeEnd-$timeBeg;
		  print "--- $scrName ended on $Date (run time=",&fctSeconds2time($timeRun),")\n";
                                # ------------------------------
                                # output files
		  if    ($#fileOut==1){
		      printf "--- %-20s %-s\n","output file:",$fileOut[1];}
		  else {print "--- output files:";
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
    foreach $arg(@ARGV){	# highest priority arguments
	next if ($arg !~/=/);
	if    ($arg=~/dirLib=(.*)$/)   {$dir=$1;}
	elsif ($arg=~/ARCH=(.*)$/)     {$ARCH=$1;}
	elsif ($arg=~/PWD=(.*)$/)      {$PWD=$1;}
	elsif ($arg=~/^packName=(.*)/) { $par{"packName"}=$1; 
					 shift @ARGV if ($ARGV[1] eq $arg); }  }

    $ARCH=$ENV{'ARCH'}          if (! defined $ARCH && defined $ENV{'ARCH'});
    $PWD= $ENV{'PWD'}           if (! defined $PWD  && defined $ENV{'PWD'}); 
    $PWD=~s/\/$//               if (defined $PWD && $PWD=~/\/$/);
    $pwd= $PWD                  if (defined $PWD);
    $pwd.="/"                   if (defined $pwd && $pwd !~ /\/$/);

				# include perl libraries
    if (! defined $par{"dirPerl"} || ! -d $par{"dirPerl"}){
	$dir="/home/rost/perl/" if (! defined $dir || ! -d $dir);
	$dir=$ENV{'PERLLIB'}    if (defined $ENV{'PERLLIB'} || ! defined $dir || ! -d $dir);
	$dir.="/"               if ($dir !~/\/$/);
	$dir=""                 if (! -d $dir);}
    else {
	$dir=$par{"dirPerl"};}
    foreach $lib("lib-ut.pl","lib-br.pl"){
 	$Lok=require $dir.$lib;  
#	$Lok=require $lib; 
 	die("*** $scrName: failed to require perl library '$lib' (dir=$dir)\n") if (! $Lok);}

				# ------------------------------
    $timeBeg=     time;		# date and time
    $Date=        &sysDate;
				# ------------------------------
				# first settings for parameters 

    &iniDef;			# NOTE: may be overwritten by DEFAULT file!!!!

				# ------------------------------
				# HELP stuff

    &iniHelpLoc;

    ($Lok,$msg)=		# want help?
	&brIniHelpLoop($scrName,%tmp);
                                return(&errSbrMsg("after lib-ut:brIniHelpLoop",$msg,$SBR)) if (! $Lok);

    exit if ($msg eq "fin");
    
				# ------------------------------
				# read command line input
    $#fileIn=0;
    @argUnk=			# standard command line handler
	&brIniGetArg;
    foreach $arg (@argUnk){     # interpret specific command line arguments
	next if ($arg=~/^(dirLib|ARCH|PWD|packName)=/);
	if    ($arg=~/^verb\w*2/)      {$par{"verb2"}=$Lverb2=1;}
	elsif ($arg=~/^verbose/)       {$par{"verbose"}=$Lverb=1;}
	elsif ($arg=~/not_?([vV]er|[sS]creen)/ ) {$par{"verbose"}=$Lverb=0; }
        elsif ($arg=~/^expand$/i)      {$par{"doExpand"}=1;}
        elsif ($arg=~/^compress$/i)    {$par{"doCompress"}=1;}
        elsif ($arg=~/^list$/i)        {$par{"isList"}=1;}
        elsif ($arg=~/^debug$/i)       {$par{"debug"}=1;}
        elsif ($arg=~/^(hssp|msf|dssp|fssp|saf|daf|fastamul|pirmul|swiss|fasta|pir|gcg)$/){
            $par{"formatOut"}=$1;}
	elsif ($arg=~/^fileOut=(.+)$/) {$par{"fileOut"}=$fileOut=$1;}
                                # process chains (dssp)
	elsif ($arg=~/^(.*$par{"ext_dssp"})\_([A-Z0-9])/){
            return(0,"*** ERROR $sbrName: kwd=$arg not correct syntax (use:file.dssp_C)\n") 
                if (! defined $1 || ! -e $1);
            push(@fileIn,$1);push(@chainIn,$2);}
                                # process chains (hssp)
	elsif ($arg=~/^(.*$par{"ext_hssp"})\_([A-Z0-9])/){
            return(0,"*** ERROR $sbrName: kwd=$arg not correct syntax (use:file.hssp_C)\n") 
                if (! defined $1 || ! -e $1);
            push(@fileIn,$1);push(@chainIn,$2);}
        elsif ($arg eq $ARGV[2]){ # to enable calling by 'copf 1ppt.hssp 1ppt.daf'
	    next;}
	else  {
	    return(0,"*** ERROR $sbrName: kwd '$arg' not understood\n");}}
    $fileOut=$par{"fileOut"} if (defined $par{"fileOut"} && $par{"fileOut"} && 
				 $par{"fileOut"} ne "unk");

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
	    if (! -e $file){ print "-*- WARN $sbrName no file=$file, (ignored)\n" if ($par{"verbose"});
			     next;}
	    push(@fileIn,$file);push(@chainIn,$chain);}close($fhin);}
                                # ------------------------------
    ($Lok,$msg)=                # determine input format
        &getFileFormatQuick($fileIn[1]);
    return(0,"*** ERROR $sbrName: could not determine format for file list ($fileIn[1])\n") 
        if (! $Lok || $msg =~ /ERROR/ || length($msg)>10 || length($msg)<3);
    $par{"formatIn"}=$msg;$par{"formatIn"}=~tr/[A-Z]/[a-z]/;
                                # case FSSP : you must have DSSP directory
    if ($par{"formatIn"} eq "fssp"){
        @tmp=split(/,/,$par{"dirDssp"});$Lok=0;
        foreach $dir(@tmp){
            if (-d $dir){$Lok=1;$par{"dirDssp"}=$dir;$par{"dirDssp"}.="/" if ($dir !~/\/$/);
                         last;}}
        return(0,"*** ERROR $sbrName: for FSSP you must provide the directory for the DSSP\n".
               "***       database by the argument 'dirDssp=/home/data/dssp'\n") 
            if (!$Lok);}
                                # ------------------------------
                                # input format supported?
    return(0,"*** ERROR $sbrName: input format '".$par{"formatIn"}."' (of files in $fileIn[1]) unsupported\n")
        if ($par{"formatIn"} !~ /^($okFormInOr)$/);
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
	&brIniSet;              return(0,"*** ERROR $sbrName: after lib-ut:brIniSet\n") if (! $Lok);

    $#fileOut=0;                # reset output files
    $#fileOutDef=0;             # standard output names
    if (! defined $fileOut){
	$ct=0;
        foreach $fileIn (@fileIn){
            $formIn= $par{"formatIn"};  $extIn= $par{"ext_$formIn"};
            $formOut=$par{"formatOut"}; $extOut=$par{"ext_$formOut"};

            $fileOut=$fileIn; $fileOut=~s/^.*\///g;$fileOut=$par{"dirOut"}.$fileOut;
	    $fileOut=~s/$extIn(_.)?$/$extOut/;
	    $fileOut.="$extOut" if ($formIn eq "swiss");
	    ++$ct;
	    $fileOut=~s/$extOut$/$par{"ext_chain"}$chainIn[$ct]$extOut/
		if ($formIn =~/[hd]ssp/ && defined $chainIn[$ct] && $chainIn[$ct] =~/[A-Z0-9]/);
            push(@fileOutDef,$fileOut);}}
    else{push(@fileOutDef,$fileOut);}
				# correct settings for executables: add directories
    if (0){
	foreach $kwd (keys %par){
	    next if ($kwd !~/^exe/);
	    next if (-e $par{"$kwd"} || -l $par{"$kwd"});
	}
    }
    
    
				# ------------------------------
				# check errors
    $exclude=
	"exeFssp2daf,exeConvHssp2saf"; # yy to exclude from error check
    ($Lok,$msg)=		# 
        &brIniErr($exclude);    return(0,"*** ERROR $sbrName: after lib-ut:brIniErr\n".$msg) if (! $Lok);  


                                # xx
                                # xx add syntax check
                                # xx



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
    $par{"dirHome"}=            "/home/rost/pub/";

				# <<<<<<<<<<<<<<<<<<<<
				# normal
    $par{"dirSrc"}=             $par{"dirHome"}.   "lib/";   # all source except for binaries
    $par{"dirSrcMat"}=          $par{"dirSrc"}.    "mat/";   # general material
				                             # perl libraries
    $par{"dirPerl"}=            $par{"dirSrc"}.    "perl/" if (! defined $par{"dirPerl"});
    $par{"dirPerlScr"}=         $par{"dirPerl"}.   "scr/";   # perl scripts needed
    $par{"dirBin"}=             $par{"dirHome"}.   "bin/";   # FORTRAN binaries of programs needed

				# <<<<<<<<<<<<<<<<<<<<
				# for porting PHD asf
    $par{"dirSrcMat"}=          "/home/rost/pub/phd/". "mat/";   # general material
    $par{"dirPerl"}=            "/home/rost/pub/phd/". "scr/";   # perl libraries
    $par{"dirPerlScr"}=         "/home/rost/pub/phd/". "scr/";   # perl scripts needed
    $par{"dirBin"}=             "/home/rost/pub/phd/". "bin/";   # FORTRAN binaries of programs needed


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
    $par{"titleTmp"}=           "COPF-TMP";    # title used for temporary files
    
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

    $par{"ext_daf"}=            ".daf";
    $par{"ext_saf"}=            ".saf";
    $par{"ext_fastamul"}=       ".f";
    $par{"ext_pirmul"}=         ".pir";

    $par{"ext_pir"}=            ".pir";
    $par{"ext_fasta"}=          ".f";
    $par{"ext_swiss"}=          ""; # no extension, simply following structure 'id_species'
    $par{"ext_gcg"}=            ".gcg";
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
    $par{"frag"}=               0; # convert fragments, only?   Use the following notation:
                                   # '1-55,77-99' to get two fragments one from 1-55, the other from 77-99
                                   # NOTE: output files will be named xyz_1_55 and xyz_77_99
    $par{"extr"}=               0; # extract particular protein from alignment format? 
                                   # provide the number of the protein in the alignment for which you want
                                   # the sequence written into the output file
    $par{"fileInclProt"}=       0; # contains ids to include, syntax PDBids + chain 1pdbC (or h|f|dssp files)
                                   # note: used only for FSSP->DAF
    $par{"fileMatGcg"}=         $par{"dirSrcMat"}.    "Maxhom_GCG.metric";  # MAXHOM-GCG matrix
    $par{"fileMatGcg"}=         $par{"dirSrcMat"}.    "Maxhom_McLachlan.metric";  # MAXHOM-GCG matrix
#    $par{"fileMatGcg"}=         $par{"dirSrcMat"}.    "Maxhom_Blosum.metric";  # MAXHOM-GCG matrix
                                # needed for conversion into HSSP format!
				# --------------------
				# executables
    $par{"exeConvertSeq"}=      $par{"dirConvertSeq"}."convert_seq98".".".$ARCH;
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

				# missing stuff
    $tmp{"s_k_i_p"}=         "problems,manual,hints";

				# special help
    $tmp{"scrAddHelp"}=      "";
    $tmp{"special"}=         "expand".","."compress".","."list".",";
    $tmp{"special"}.=        "help saf-syn".",";
        
    $tmp{"expand"}=          "shortcut for doExpand=1,   i.e. do expand HSSP deletions (for conversion to MSF|SAF)";
    $tmp{"compress"}=        "shortcut for doCompress=1, i.e. do delete insertions in MASTER (for conversion to HSSP)";
    $tmp{"list"}=            "shortcut for isList=1,     i.e. input file is list of files";

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
    $tmp{"help phdrdb"}.=    "OUT: DSSP|MSF|PIR|FASTA|GCG|FASTAmul|PIRmul \n";
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
sub convAliGen {
    local($fileInLoc,$fileOutLoc,$formIn,$formOut,$extOutLoc,$exeConvSeq,$fileMatGcg,$doCompress,
          $frag,$extrLoc,$fileScreenLoc,$dirWork,$fhSbr) = @_ ;
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
        @tmp=split(/,/,$frag);$#beg=$#end=0;
        foreach $frag(@tmp){next if ($frag !~ /\-/);$frag=~s/\s//g;
                            ($beg,$end)=split('-',$frag);
                            next if ($beg =~/\D/ || $end =~ /\D/);push(@beg,$beg);push(@end,$end);}}

                                # ------------------------------
    $#kwdRmTmp=0;               # temporary files

                                # --------------------------------------------------
    if ($formOut eq "hssp"){    # HSSP output
        if ($#beg>1){
            print "-*- WARN $sbrName: for $formIn -> HSSP currently only one fragment at a time!!\n" x 2;}
                                # ------------------------------
                                # (1) convert all seq to FASTA
	if ($formIn =~ /^pir/ || $formIn eq "gcg" || $formIn eq "swiss" ){
            $kwd=$formIn."-".$formOut ;push(@kwdRmTmp,$kwd);
            $fileOutSeqTmp=$file{"$kwd"}=$dirWork.$par{"titleTmp"}.".fasta_tmp";
            $fragHere=0; $fragHere="$beg[1]-$end[1]" if ($#beg>0);
	    return(&errSbr("more than one fragment not supported for converting $formIn to $formOut"))
		if ($#beg>1);
	    ($Lok,$msg)=
		&convSeq2fastaPerl($fileInLoc,$fileOutSeqTmp,$formIn,$fragHere);
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
            $fileOutMsfTmp=$file{"$kwd"}=$dirWork.$par{"titleTmp"}.".msf_tmp";
            $fragHere=0; $fragHere="$beg[1]-$end[1]" if ($#beg>0);
	    if    ($formIn eq "saf"){
                ($Lok,$msg)=
                    &convSaf2many($fileOutSeqTmp,$fileOutMsfTmp,"msf",$fragHere,$extrLoc,$fhSbr);}
            elsif ($formIn =~ /^fasta/){
                ($Lok,$msg)=
                    &convFastamul2many($fileOutSeqTmp,$fileOutMsfTmp,"msf",$fragHere,$extrLoc,$fhSbr);}
            return(0,"*** ERROR $sbrName: failed to write msf ($fileOutMsfTmp) from $fileInLoc, ".
		   "to seq=$fileOutSeqTmp, for extr=$extrLoc".
		   $msg."\n") if (! $Lok || ! -e $fileOutMsfTmp);}
        elsif ($formIn eq "msf") {
            $fileOutMsfTmp=$fileOutSeqTmp;}
	else {
	    return(&errSbr("input format=$formIn -> output=$formOut, not supported\n"));}
	
                                # ------------------------------
                                # (3) blow up when single sequence
        if (&msfCountNali($fileOutMsfTmp) == 1){
            $kwd=$formIn."-".$formOut."-addSelf";push(@kwdRmTmp,$kwd);
            $fileOutMsfTmp2=$file{"$kwd"}=$dirWork.$par{"titleTmp"}.".msf_tmpSelf";
	    ($Lok,$msg)=
		&msfBlowUp($fileOutMsfTmp,$fileOutMsfTmp2);
            return(0,"*** ERROR $sbrName: failed to write msf2 ($fileOutMsfTmp2)".
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
        push(@fileOut,$fileOutTmp);}
                                # --------------------------------------------------
                                # MSF, FASTA, PIR, FASTAmul, PIRmul
    elsif ($formOut eq "msf" || $formOut eq "fasta" || $formOut eq "pir" || $formOut eq "saf" 
           || $formOut eq "fastamul" || $formOut eq "pirmul" ){
                                # --------------------
                                # (1) convert MSF to SAF
        if ($formIn eq "msf"){
            $kwd=$formOut."-SAF";push(@kwdRmTmp,$kwd);
            $fileOutSafTmp=$file{"$kwd"}=$dirWork.$par{"titleTmp"}.$kwd.$extOutLoc;
            ($Lok,$msg)=
                &convMsf2saf($fileInLoc,$fileOutSafTmp);
            return(0,"*** ERROR $sbrName: failed to write saf ($fileOutSafTmp) from $fileInLoc".$msg."\n")
                if (! $Lok || ! -e $fileOutSafTmp);}
        else {
            $fileOutSafTmp=$fileInLoc;}
                                # --------------------
        if ($#beg>0){           # (2a) loop over fragments
            foreach $it (1..$#beg){
                $fileOutTmp=$fileOutLoc;$fileOutTmp=~s/(\.$extOutLoc)/\_$beg[$it]\_$end[$it]$1/;
                $fragHere="$beg[$it]-$end[$it]";
                if    ($formIn eq "saf" || $formIn eq "msf"){
		    ($Lok,$msg)=
                        &convSaf2many($fileOutSafTmp,$fileOutTmp,$formOut,$fragHere,$extrLoc,$fhSbr);
                    return(0,"*** ERROR $sbrName: failed to convert $fileOutSafTmp to $formOut\n"."$msg\n") 
                        if (! $Lok);}
                elsif ($formIn =~ /^fasta/){
                    ($Lok,$msg)=
                        &convFastamul2many($fileInLoc,$fileOutTmp,$formOut,$fragHere,$extrLoc,$fhSbr);
                    return(0,"*** ERROR $sbrName: failed to convert $fileInLoc to $formOut\n"."$msg\n") if (! $Lok);}
                push(@fileOut,$fileOutTmp);}}
                                # --------------------
        else {$fragHere=0;      # (2b) no fragments
              if    ($formIn eq "saf" || $formIn eq "msf"){
                  ($Lok,$msg)=
                      &convSaf2many($fileOutSafTmp,$fileOutLoc,$formOut,$fragHere,$extrLoc,$fhSbr);
                  return(0,"*** ERROR $sbrName: failed to convert $fileOutSafTmp to $formOut\n"."$msg\n") 
                      if (! $Lok);}
              elsif ($formIn =~ /^fasta/){
                  ($Lok,$msg)=
                      &convFastamul2many($fileInLoc,$fileOutLoc,$formOut,$fragHere,$extrLoc,$fhSbr);
                  return(0,"*** ERROR $sbrName: failed to convert fasta to $formOut\n"."$msg\n") if (! $Lok);}
	      push(@fileOut,$fileOutLoc);}}
    else {
        return(2,"*** ERROR $sbrName: output option $formOut not supported\n");}
                                # ------------------------------
                                # remove temporary files
    foreach $kwd(@kwdRmTmp){
        if (-e $file{"$kwd"}){ 
            print "--- \t $sbrName: remove (",$file{"$kwd"},") \n" if (defined $par{"verb2"} && $par{"verb2"});
            unlink $file{"$kwd"};}}
    return(1,"ok $sbrName");
}				# end of convAliGen

#===============================================================================
sub convDsspGen {
    local($fileInLoc,$chainInLoc,$fileOutLoc,$formOut,$extOutLoc,$exeConvSeq,$fileMatGcg,
	  $frag,$fileScreenLoc,$dirWork,$fhSbr) = @_ ;
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
#       out:                    converted file
#       out GLOBAL:             @fileOut,@kwdRm,$file{"kwd"} files to remove
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
    return(0,"*** $sbrName: miss in file '$fileInLoc'!")  if (! -e $fileInLoc);

    $chainIn=$chainInLoc; $chainIn="*" if (! $chainInLoc || length($chainInLoc)!=1 || $chainInLoc !~/[A-Z0-9]/);
                                # ------------------------------
    $#kwdRmTmp=0;               # temporary files
    $fhSysRunProg=0;
    $fhSysRunProg="STDOUT"      if ($par{"verb2"});
    $fileScreenLoc=0            if ($par{"debug"});

				# ------------------------------
				# chain over-rules fragments
    if ($chainInLoc && $chainInLoc =~ /[A-Z0-9]/){
	($Lok,%tmp)=
	    &dsspGetChain($fileInLoc);
	return(0,"*** ERROR $sbrName: failed to extract chain from DSSP ($fileInLoc)\n") if (! $Lok);
	@tmp=split(/,/,$tmp{"chains"});
	foreach $it (1..$#tmp){
	    if ($tmp[$it] eq $chainInLoc){
		$frag=$tmp{"$chainInLoc","beg"}."-".$tmp{"$chainInLoc","end"};
		last;}}}
    $#beg=$#end=0;              # ------------------------------
    if ($frag){                 # extract fragments?
        @tmp=split(/,/,$frag);$#beg=$#end=0;
        foreach $frag(@tmp){next if ($frag !~ /\-/);$frag=~s/\s//g;
                            ($beg,$end)=split('-',$frag);
                            next if ($beg =~/\D/ || $end =~ /\D/);push(@beg,$beg);push(@end,$end);}}

                                # ------------------------------
				# FASTA/mul, PIR/mul, SAF/MSF
    if   ($formOut =~/^pir/ || $formOut =~/^fasta/ || $formOut =~/^msf/ || $formOut =~/^saf/ ){
				# read entire DSSP sequence
	($Lok,$seqSmallCap,$seqDssp)=
	    &dsspRdSeq($fileInLoc,$chainIn);
	return(0,"*** ERROR $sbrName: failed to read dssp sequence for chain $chainIn\n"."$seqSmallCap\n") 
	    if (! $Lok || length($seqDssp)<5); # security margin for chainbreaks

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
		    print "-*- WARN $sbrName: seq=$seqDsspTmp (beg=$beg[$it], end=$end[$it]) very short!\n";
		    next;}
		($Lok,$msg)=
		    &seqGenWrt($seqDsspTmp,$id,$formOut,$fileOutTmp,$fhSbr);
                return(0,"*** ERROR $sbrName: failed to write $formOut from DSSP\n"."$msg\n") 
                    if (! $Lok || ! -e $fileOutTmp);
                push(@fileOut,$fileOutTmp);}}
        else {$id=$fileInLoc;$id=~s/^.*\/|\..*$//g; # purge dir
	      $id.="_".$chainIn if (defined $chainIn && $chainIn && $chainIn ne "*" && length($chainIn)==1);
	      ($Lok,$msg)=
		  &seqGenWrt($seqDssp,$id,$formOut,$fileOutLoc,$fhSbr);
	      return(0,"*** ERROR $sbrName: failed to write $formOut from DSSP\n"."$msg\n") 
		  if (! $Lok || ! -e $fileOutLoc);
	      push(@fileOut,$fileOutLoc);}}

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
		    print "-*- WARN $sbrName: seq=$seqDsspTmp (beg=$beg[$it], end=$end[$it]) very short!\n";
		    next;}
				# (3a) convert to MSF
		$kwd="dssp-hssp"; push(@kwdRmTmp,$kwd);
		$fileOutMsf=$file{"$kwd"}=$dirWork.$par{"titleTmp"}.".msf_tmp";
		($Lok,$msg)=
		    &seqGenWrt($seqDsspTmp,$id,"msf",$fileOutMsf,$fhSbr);
                return(0,"*** ERROR $sbrName: failed to write MSF from DSSP\n"."$msg\n") 
                    if (! $Lok || ! -e $fileOutMsf);
				# (4a) blow up when single sequence
		if (&msfCountNali($fileOutMsf) == 1){
		    $kwd=$formIn."-".$formOut."-addSelf";push(@kwdRmTmp,$kwd);
		    $fileOutMsfTmp2=$file{"$kwd"}=$dirWork.$par{"titleTmp"}.".msf_tmpSelf";
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
	    $fileOutMsf=$file{"$kwd"}=$dirWork.$par{"titleTmp"}.".msf_tmp";
	    ($Lok,$msg)=
		&seqGenWrt($seqDssp,$id,"msf",$fileOutMsf,$fhSbr);
	    return(0,"*** ERROR $sbrName: failed to write MSF from DSSP\n"."$msg\n") 
		if (! $Lok || ! -e $fileOutMsf);
				# (4a) blow up when single sequence
	    if (&msfCountNali($fileOutMsf) == 1){
		$kwd=$formIn."-".$formOut."-addSelf";push(@kwdRmTmp,$kwd);
		$fileOutMsfTmp2=$file{"$kwd"}=$dirWork.$par{"titleTmp"}.".msf_tmpSelf";
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
        if (-e $file{"$kwd"}){ 
            print "--- \t $sbrName: remove (",$file{"$kwd"},") \n" 
		if (defined $par{"verb2"} && $par{"verb2"});
            unlink $file{"$kwd"};}}
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
	    &open_file("$fhinLoc","$fileIncl") ||
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
        print "--- \t $sbrName: remove ($fileDafTmp) \n" if (defined $par{"verb2"} && $par{"verb2"});
	unlink $fileDafTmp;
        push(@fileOut,$fileOutLoc);}
    else {
        return(2,"*** ERROR $sbrName: output option $formOut not supported for FSSP\n");}
    return(1,"ok $sbrName");
}				# end of convFsspGen

#===============================================================================
sub convHsspGen {
    local($fileInLoc,$chainInLoc,$fileOutLoc,$formOut,$extOutLoc,$exeConvSeq,$exeConvHssp2saf,
          $doExpand,$frag,$extrIn,$fileScreenLoc,$dirWork,$fhSbr) = @_ ;
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
#       out:                    converted file
#       out GLOBAL:             @fileOut,@kwdRm,$file{"kwd"} files to remove
#       err:                    0,$msg -> unspecified error 
#       err:                    1,$msg -> ok
#       err:                    2,$msg -> conversion option not supported
#-------------------------------------------------------------------------------
    $sbrName="$scrName:"."convHsspGen";$fhinLoc="FHIN"."$sbrName";
                                # ------------------------------
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc!")           if (! defined $fileInLoc);
    $chainInLoc=0                                          if (! defined $chainInLoc);
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
                    $fileOutTmp=$file{"$kwd"}=$dirWork.$par{"titleTmp"}.$kwd.$extOutLoc;
                    push(@kwdRmTmp,$kwd);}
                else                  {
                    $fileOutTmp=$fileOutLoc;$fileOutTmp=~s/(\.$extOutLoc)/\_$beg[$it]\_$end[$it]$1/;}
                $an1=   "Y";    # fragment? (if: prompted for two integers: beg end)
                $anF=   "$beg[$it] $end[$it]"; # answer for fragment
                eval    "\$cmd=\"$exeConvSeq,$fileInLoc,$anFormOut,$an1,$anF,$fileOutTmp,$an2\"";
				# run FORTRAN script
                ($Lok,$msg)=&sysRunProg($cmd,$fileScreenLoc,$fhSysRunProg);
                $msgErr.="*** ERROR $sbrName: failed to convert hssp to MSF frag $it \n".$msg."\n" 
                    if (! $Lok || ! -e $fileOutTmp);
                push(@fileOut,$fileOutTmp);}
            return(0,$msgErr) if ($msgErr =~ /ERROR/);}
        else {
            $an1=       "N";     # fragment? (if: prompted for two integers: beg end)
	    $fileOutTmp=$fileOutLoc;
            eval        "\$cmd=\"$exeConvSeq,$fileInLoc,$anFormOut,$an1,$fileOutTmp,$an2\"";
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
			      $doExpand,$fragTmp,$extr,0,0,0,0,$fhSbr);
	    return(&errSbrMsg("failed HSSP -> $formOut (sbr)",$msg)) if (! $Lok || ! -e $fileOutTmp);
                                # extract particular sequence
	    push(@fileOut,$fileOutTmp); } }
    else {
        return(2,"*** ERROR $sbrName: output option $formOut not supported for HSSP\n");}
                                # ------------------------------
                                # remove temporary files
    foreach $kwd(@kwdRmTmp){
        if (-e $file{"$kwd"}){ 
            print "--- \t $sbrName: remove (",$file{"$kwd"},") \n" 
		if (defined $par{"verb2"} && $par{"verb2"});
            unlink $file{"$kwd"};}}
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
    local($fileInLoc,$fileOutLoc,$formIn,$formOut,$extOutLoc,$exeConvSeq,$frag,
	  $fileScreenLoc,$dirWork,$fhSbr) = @_ ;
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
        foreach $frag(@tmp){next if ($frag !~ /\-/);$frag=~s/\s//g;
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
                    &convSeq2seq($exeConvSeq,$fileInLoc,$fileOutTmp,$formOut,$fragHere,$fileScreenLoc,$fhSbr);
                return(0,"*** ERROR $sbrName: failed to convert fasta to $formOut\n"."$msg\n") if (! $Lok);
                push(@fileOut,$fileOutTmp);}}
        else {$fragHere=0;
              ($Lok,$msg)=
                  &convSeq2seq($exeConvSeq,$fileInLoc,$fileOutLoc,$formOut,$fragHere,$fileScreenLoc,$fhSbr);
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

1;
