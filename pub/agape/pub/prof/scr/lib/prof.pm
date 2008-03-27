#------------------------------------------------------------------------------#
#	Copyright				Sep,    	1998	       #
#	Burkhard Rost		rost@LION-ag.de,rost@EMBL-heidelberg.de	       #
#	Wilckensstr. 15		http://www.embl-heidelberg.de/~rost/	       #
#	D-69120 Heidelberg						       #
#				version 1.0   	Aug,    	1998	       #
#				version 2.0   	Oct,    	1998	       #
#				version 2.1   	Dec,    	1999	       #
#				version 2.2   	Apr,    	2000	       #
#------------------------------------------------------------------------------#
#                                                                              # 
#                                                                              #
# description:                                                                 #
#    PERL library with routines needed to PROF                              #
#                                                                              #
#------------------------------------------------------------------------------#

package prof;

INIT: {
    $packName="prof";
}


#===============================================================================
sub full {
    ($par{"dirHome"},$par{"dirProf"},$par{"confProf"},$ARCH_DEFAULT,
     $scrName,$scrGoal,$scrIn,$scrNarg,$okFormIn,$scrHelpText,
     @ARGV)=@_;
    local($SBR01);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   full                       
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR01=$packName.":"."full";
				# --------------------------------------------------
				# check arguments
    $tmpErr= "";
    $tmpErr.="not def ".$par{"dirHome"}."!\n" if (! defined $par{"dirHome"});
    $tmpErr.="not def ".$par{"dirProf"}."!\n"  if (! defined $par{"dirProf"});
    $tmpErr.="not def ".$par{"confProf"}."!\n" if (! defined $par{"confProf"});
    $tmpErr.="not def ARCH_DEFAULT!\n"        if (! defined $ARCH_DEFAULT);

    $tmpErr.="missing dirHome=".$par{"dirHome"}."!\n" if (! -d $par{"dirHome"} && ! -l $par{"dirHome"});
    $tmpErr.="missing dirProf=". $par{"dirProf"}."!\n"  if (! -d $par{"dirProf"}  && ! -l $par{"dirProf"});
    $tmpErr.="missing confProf=".$par{"confProf"}."!\n" if (! -e $par{"confProf"} && ! -l $par{"confProf"});

    return(0,"*** ERROR $SBR01: errors=\n".$tmpErr) 
	if (length($tmpErr)>1);

				# --------------------------------------------------
				# initialise variables
    ($Lok,$msg)= &ini();        return(0,"*** ERROR $SBR01: failed initialising ($SBR01:ini)".
				       __LINE__."\n".$msg) if (! $Lok);

    #------------------------------------------------------------------------------
    # start the job
    #------------------------------------------------------------------------------

				# ------------------------------
				# (1) read parameter file
				#      GLOBAL in:  $par{} 
				#      GLOBAL out: $par{"para",*}
				# ------------------------------
    $whichPROF=$par{"optProf"};
    ($Lok,$msg,$whichPROF)=
	&fileParRd($whichPROF,
		   @filePar);   &assAbort("failed reading filePar! (&$SBR01:fileParRd)",
					  __LINE__,$msg) if (! $Lok);
				# xx hack for time being
    $whichPROF=$par{"optProf"} if ($par{"optProf"}=~ /^(3|htm)$/ && $whichPROF !~ /^(sec|acc)$/);

#    $par{"optProf"}=$whichPROF;	# correct mode to predict

				# ------------------------------
				# (2) build up first level arg
				#      GLOBAL in:  $par{} (in particular $par{"para"})
				#      GLOBAL out: $run{}
				# ------------------------------
    ($Lok,$msg)=
	&buildArg();            &assAbort("failed after &$SBR01:buildArg! ",
					  __LINE__,$msg) if (! $Lok);    
				# ------------------------------------------------------------
				# (3) loop over all db input files (i.e. all proteins)
				# ------------------------------------------------------------
    $ctfileIn=0; $nfileIn=$#fileIn;
    while (@fileIn) {
				# ------------------------------
				# time estimate
	$fileIn= shift @fileIn; 
	++$ctfileIn;
	$chainIn=$par{"symbolChainAny"};
	$chainIn=$chainIn[$ctfileIn] if (defined $chainIn[$ctfileIn]);
				# runtime estimate
	&assFctRunTimeLeft($timeBeg,$nfileIn,$ctfileIn,$fileIn,$chainIn);

				# ------------------------------
				# do all for one protein
	($Lok,$msg,$whichPROFout,$L3D_KNOWN,$rh_mode)=
	    &doOne($ctfileIn,$fileIn,$chainIn,$formatIn[$ctfileIn],$modeWrt,
		   $whichPROF);  &assAbort("failed $SBR01:doOne dbfile=$fileIn, chain=$chainIn!",
					  __LINE__,$msg) if (! $Lok);
    }
				# end of loop over all files
				# --------------------------------------------------

				# ------------------------------
				# (4)  compile prediction error
				# ------------------------------
    if ($L3D_KNOWN && $par{"doEval"}){
	($Lok,$msg)=
	    &errPrdFin($nfileIn,$par{"fileOutEval"},$whichPROFout,$rh_mode
		       );       &assAbort("failed $SBR01:errPrdFin dbfile=$fileIn, chain=$chainIn!",
					  __LINE__,$msg) if (! $Lok);
    }
    

    #-------------------------------------------------------------------------------
    # work done, go home
    #-------------------------------------------------------------------------------
                                # ------------------------------
                                # deleting intermediate files
    &assCleanUp(1,0)            if (! $par{"debug"}); 

                                # ------------------------------
				# final words
    if ($Lverb) {
	($Lok,$msg)=
	    &wrtScreenFoot($timeBeg,$par{"Date"},$nfileIn,$whichPROFout);
	print "*** ERROR while writing final words ... ($scrName:$SBR01):\n",$msg,"\n" if (! $Lok);
    }

    return(1,"ok $SBR01");
}				# end of full

#===============================================================================
sub ini {
    $[=1;
    my($SBR);
#-------------------------------------------------------------------------------
#   ini                         initialises variables/arguments for nndb.rdb->vec
#-------------------------------------------------------------------------------
    $SBR=$packName.":"."ini";     
    if (! defined $sourceFile || ! $sourceFile) {
	$sourceFile=$0;$sourceFile=~s/^\.\///g;}

    $| = 1;			# autoflush output: no buffering

				# ------------------------------
				# avoid warning
    $#formatIn=$modeWrt=$filePar=0;

				# ------------------------------
				# set general parameters
    $Lok=require($par{"confProf"});

    return(0,"*** ERROR $SBR: failed to require par{'confProf'}=".$par{"confProf"}."!") 
	if (! $Lok);

    &iniDefProf($par{"dirHome"},$par{"dirProf"},$par{"confProf"},$ARCH_DEFAULT);

				# ------------------------------
				# now initialise PROF
				# ------------------------------
				# 
    if (! $scrName)   { $scrName=$0; $scrName=~s/^.*\/|\.p[lm]//g;}
    if (! $scrGoal)   { $scrGoal=    "neural network switching";}
    if (! $scrIn)     { $scrIn=      "list_of_files (or single file) parameter_file";}
    if (! $scrNarg)   { $scrNarg=    2;}
    if (! $okFormIn)  { $okFormIn=   "hssp,dssp,msf,saf,fastamul,pirmul,fasta,pir,gcg,swiss";}
    if (! $scrHelpTxt){ $scrHelpTxt= "Input file formats accepted: \n";
			$scrHelpTxt.="      ".  $okFormIn."\n";}
    @okFormIn=split(/,/,$okFormIn);
    $okFormInOr=join('|',@okFormIn);

    $par{"DONE","ini"}=         1;

				# ------------------------------
				# require perl libraries and sets
				#    CPU architecture
				#    errors abort
    &iniLib();
				# ------------------------------
    $timeBeg=     time;		# date and time
    $Date=        &sysDate();
    $date="??-??-????";		# ini
    ($Lok,$date)= &date_monthDayYear2num($Date);
    $par{"Date"}=               $Date;
    $par{"date"}=               $date;

				# ------------------------------
    %tmp=&iniHelpProf();		# HELP stuff
    $tmp{"itself"}=$par{"confProf"};
	
    ($Lok,$msg)=		# want help?
	&brIniHelpLoop($scrName,%tmp);   
                                return(&errSbrMsg("after lib-br:brIniHelpLoop",$msg,$SBR)) if (! $Lok);
    exit if ($msg =~/^fin/); 
    

				# --------------------------------------------------
				# (1) read command line
                                #      - command line arg -> $par{}
                                #      - info from $parNet{} -> $par{} (nnin)
                                #      - updates numin asf (iniInterpret)
                                #      - gets files tvtId/Translate
                                #      - completes $par{modeRunNet}
				# --------------------------------------------------
    ($Lok,$msg)=
	&iniRdCmdline();        return(&errSbrMsg("after rd cmd",$msg,$SBR)) if (! $Lok);
   
				# --------------------------------------------------
				# (2) include additional perl libraries
				# --------------------------------------------------
    if ($par{"doEval"})    { 
	$kwd="exeLibProfErr";    $lib=$par{$kwd};
	$Lok=require $lib;      &assAbort("failed to require perl library '$lib' (kwd=$kwd)".
					  __LINE__)     if (! $Lok);}
    if ($par{"doRetHtml"}) { 
	$kwd="exeLibProfHtml";   $lib=$par{$kwd};
	$Lok=require $lib;      &assAbort("failed to require perl library '$lib' (kwd=$kwd)".
					  __LINE__)     if (! $Lok);}
    if ($par{"doRetAscii"} || 
	$par{"doRetMsf"}   || $par{"doRetSaf"} || 
	$par{"doRetDssp"}  || $par{"doRetCasp"}) {
	$kwd="exeLibProfWrt";    $lib=$par{$kwd};
	$Lok=require $lib;      &assAbort("failed to require perl library '$lib' (kwd=$kwd)".
					  __LINE__)     if (! $Lok);}

				# --------------------------------------------------
				# (3) massage for all allowed formats
				# --------------------------------------------------
    foreach $tmp (@okFormIn){
	$tmp1=substr($tmp,1,1); $tmp1=~tr/[a-z]/[A-Z]/;
	$okFormIn{$tmp,"kwd","ext"}="ext".$tmp1.substr($tmp,2);
	$okFormIn{$tmp,"kwd","dir"}="dir".$tmp1.substr($tmp,2);
    }
				# --------------------------------------------------
                                # (4) final settings
                                #      - also sets priority
                                #      - checks errors
                                #      - writes to screen and opens fileTrace
				# --------------------------------------------------
    ($Lok,$msg)=
	&iniSetFinal();         return(&errSbrMsg("after setfinal",$msg,$SBR)) if (! $Lok);

				# set zero for reading HSSP files
    return(&errSbr("no input file given?",$SBR)) if ($#fileIn<1);

                                # ------------------------------
    undef %tmp;			# save memory
				# slim-is-in !
    $#argUnk=$#tmp=
	$#tmpFile=$#tmpChain=0;

    return(1,"ok $SBR");
}				# end of ini

#===============================================================================
sub iniLib {
    my($SBR2);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iniLib                      initialises libraries 
#-------------------------------------------------------------------------------
    $SBR2="$scrName:"."iniLib";
				# ------------------------------
    foreach $arg(@ARGV){	# highest priority arguments
	next if ($arg !~/=/);
	if    ($arg=~/dirScr=(.*)$/)           { $par{"dirScr"}=    $1;}

	elsif ($arg=~/exeLibProfCol=(.*)$/)     { $par{"exeLibProfCol"}=$1;}

	elsif ($arg=~/ARCH=(.*)$/)             { $ARCH=$ENV{'ARCH'}=   $1;}
	elsif ($arg=~/PWD=(.*)$/)              { $PWD=                 $1;}
    }

    $ENV{'ARCH'}=0              if (! defined $ENV{'ARCH'} ||
				    $ENV{'ARCH'}=~/UNK/i);

    $ARCH=$ENV{'ARCH'}          if (! defined $ARCH && defined $ENV{'ARCH'} && $ENV{'ARCH'});

				# ------------------------------
				# last attempt ARCH : hard coded
    if (! defined $ARCH){open (ARCHFILE, $par{"exePvmgetarch"}." |"); # HARD_CODED
			 while (<ARCHFILE>) { chop;$ARCH=$_; 
					      last;}
			 close(ARCHFILE);}

    $ARCH=$ARCH_DEFAULT         if (! defined $ARCH);

    &assAbort("***** you must defined ARCH by either \n"."> setenv ARCH SGI32\n".
	      "***** or on command line \n"."> $scrName.pl ARCH=SGI64\n"."***** ",
	      __LINE__)         if (! defined $ARCH);

    $PWD= $ENV{'PWD'}           if (! defined $PWD  && defined $ENV{'PWD'}); 
    if (! defined $PWD){
	$PWD=`pwd`;
	$PWD=~s/\s//g;}
    $PWD=~s/\/$//               if ($PWD=~/\/$/);
    $pwd= $PWD                  if (defined $PWD);
    $pwd.="/"                   if (defined $pwd && $pwd !~ /\/$/);
    $pwd=""                     if (! defined $pwd);

				# ------------------------------
				# get user
    $USERID=$USERID || $ENV{'USER'} || "unk";

				# ------------------------------
				# include perl libraries
    foreach $kwd (
		  "exeLibProfCol",
		  "exeLibProfMain",
#		  "exeLibProfNet"
		  ){
	next if ($kwd=~/exeLibProfErr/ && ! $par{"doEval"});
	$lib=$par{$kwd};
	$Lok=require $par{$kwd};
	&assAbort("failed to require perl library '$lib' (kwd=$kwd)".
		  __LINE__)     if (! $Lok);
    }
}				# end of iniLib

#===============================================================================
sub iniHelpProf {
    my($SBR2);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iniHelpProf                 specific help settings
#-------------------------------------------------------------------------------
    $SBR2="$scrName:"."iniHelpProf";
				# standard help
    $tmp=$0; $tmp=~s/^\.\/// if ($tmp=~/^\.\//);
    %tmp=('sourceFile', $tmp, 'scrName',$scrName, 'scrIn',$scrIn, 'scrGoal', $scrGoal, 'scrNarg',$scrNarg,
	  'scrHelpTxt', $scrHelpText);
				# continued lines
    $precontd="\n---                   ";

				# missing stuff
    $tmp{"s_k_i_p"}=         "problems,manual,hints,notation,txt,known,DONE,Date,date,aa,Lhssp,numaa";
    $tmp{"s_k_i_p"}.=        ",code";
#                            "------------------------------------------------------------\n";
				# special help
    $tmp{"scrAddHelp"}=      "";
    $tmp{"special"}=         "";
#    $tmp{"special"}.=        "3,both,acc,sec,htm,doHtmisit,doHtmfil,doHtmref";

#                            "------------------------------------------------------------\n";
				# run options
    $tmp{"3"}=               "predict sec + acc + htm          (see those 3 for more help)";
    $tmp{"both"}=            "predict secondary structure and solvent accessibility";
    $tmp{"acc"}=             "predict solvent accessibility, only";
    $tmp{"sec"}=             "predict secondary structure,   only";
    $tmp{"htm"}=             "predict transmembrane helices, only";
    $tmp{"tst"}=             "quick run through program, low accuracy";

    $tmp{"fast"}=            "PROF with lowest accuracy and highest speed";
    $tmp{"good"}=            "PROF with good accuracy and moderate speed";
    $tmp{"best"}=            "PROF with best accuracy and longest run-time";

    $tmp{"doHtmisit"}=       "DO check strength of predicted membrane helix      (default)";
    $tmp{"doHtmfil"}=        "DO filter the membrane prediction                  (default)";
    $tmp{"doHtmref"}=        "DO refine the membrane prediction                  (default)";
    $tmp{"doHtmtop"}=        "DO membrane helix topology                         (default)";
    $tmp{"notHtmisit"}=      "do NOT check whether or not membrane helix strong enough";
    $tmp{"notHtmfil"}=       "do NOT filter the membrane prediction";
    $tmp{"notHtmref"}=       "do NOT refine the membrane prediction";
    $tmp{"notHtmtop"}=       "do NOT membrane helix topology";
    $tmp{"htm"}=             "use: 'htm=<N|0.N>' gives minimal transmembrane helix detected ";
    $tmp{"htm"}.= $precontd. "default is 'htm=8' (resp. htm=0.8)";
    $tmp{"htm"}.= $precontd. "smaller numbers -> more false positives and fewer false negatives!";

				# input options
    $tmp{"list"}=            "<*|isList=1>             -> input file is list of files";

    $tmp{"filter"}=          "filter the input HSSP file       (excluding some pairs)";
    $tmp{"doFilterHssp"}=    "filter the input HSSP file       (excluding some pairs)";
    $tmp{"keepHssp"}=        "<*|doKeepHssp=1>         -> keep the intermediate HSSP file";
    $tmp{"keepFilter"}=      "<*|doKeepFilter=1>       -> keep the filtered HSSP file";
    $tmp{"keepNetDb"}=       "<*|doKeepNetDb=1>        -> keep the intermediate DbNet file(s)";
    $tmp{"skipMissing"}=     "-> do not abort if input file missing!";

				# run options
#                            "------------------------------------------------------------\n";
    $tmp{"arch"}=            "system architecture (e.g.: SGI64|SGI5|SGI32|SUNMP|ALPHA)";
    $tmp{"user"}=            "user name";
    $tmp{"nice"}=            "give 'nice-D' to set the nice value (priority) of the job";

    $tmp{"nonice"}=          "job will not be niced, i.e. not run with lower priority";

    $tmp{"debug"}=           "keep most intermediate files";

    $tmp{"silent"}=          "no information written to screen";

    $tmp{"keepConv"}=        "keep the conversion of the input file to HSSP format";
    $tmp{"noSearch"}=        "short for doSearchFile=0, i.e. no searching of DB files";
    $tmp{"test"}=            "is just a test (faster)";

				# output options
#                            "------------------------------------------------------------\n";
    $tmp{"doEval"}=          "DO evaluation for list (only for known structures and lists)";
    $tmp{"notEval"}=         "DO NOT check accuracy even when known structures";

    $tmp{"noProfHead"}=       "do NOT copy file with tables into local directory";

    $tmp{"ascii"}=           "write 'human-readable' PROF output file(s)";
    $tmp{"noascii"}=         "surpress writing ASCII (i.e. human readable) result files";
    $tmp{"ali"}=             "add alignment to 'human-readable' PROF output file(s)";
    $tmp{"graph"}=           "add ASCII graph to 'human-readable' PROF output file(s)";
    $tmp{"dssp"}=            "convert PROF into DSSP format";
    $tmp{"msf"}=             "convert PROF into MSF format";
    $tmp{"saf"}=             "convert PROF into SAF format";

    $tmp{"html"}=            "'hmtl' or 'html=<all|body|head>'-> write HTML format of prediction";
    $tmp{"html"}.= $precontd."'html' will result in that the PROF output is converted to HTML";
    $tmp{"html"}.= $precontd."'html=body' restricts HTML file to the HTML_BODY tag part";
    $tmp{"html"}.= $precontd."'html=head' restricts HTML file to the HTML_HEADER tag part";
    $tmp{"html"}.= $precontd."'html=all'  gives both HEADER and BODYn";

    $tmp{"nohtml"}=          "surpress writing HTML result files";

    $tmp{"data"}=            "data=<all|brief|normal|detail>     ";
    $tmp{"data"}.= $precontd."-> for HTML out: only those parts of predictions written";

#                            "------------------------------------------------------------\n";
    $tmp{"expand"}=          "expand insertions when converting output to MSF format";

#                            "------------------------------------------------------------\n";
    $tmp{"fileRdb"}=         "name of PROF output in RDB format               (file.rdbProf)";
    $tmp{"fileProf"}=        "name of PROF output in human readable format    (file.prof)";
    $tmp{"fileHtml"}=        "name of PROF output in HTML format              (file.htmlProf)";
    $tmp{"fileMsf"}=         "name of PROF output in MSF format               (file.msfProf)";
    $tmp{"fileSaf"}=         "name of PROF output in SAF format               (file.safProf)";
    $tmp{"fileCasp"}=        "name of PROF output in CASP format              (file.caspProf)";
    $tmp{"fileDssp"}=        "name of PROF output in DSSP format              (file.dsspProf)";
    $tmp{"fileNotHtm"}=      "name of file flagging that no membrane helix was found";
#                            "------------------------------------------------------------\n";

#    $tmp{""}=         "<*|=1> ->    ";


    foreach $kwd (sort keys %tmp){
	next if ($kwd eq "special");
        $tmp{$kwd}=     $tmp{$kwd};
        $tmp{"special"}.= $kwd.","; }

#                            "------------------------------------------------------------\n";
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
    $tmp{"help input"}.=     "  The following file formats may be handled by PROF at the moment:\n";
    $tmp{"help input"}.=     "     MSF|SAF|FASTAmul|FASTA|PIR|GCG|SWISS-PROT\n";
    $tmp{"help input"}.=     "  \n";
    $tmp{"help input"}.=     "-------------------------------------------------------------------\n";
    $tmp{"help input"}.=     "  -  For further  explanations, or for  other automatic  changes of\n";
    $tmp{"help input"}.=     "     file formats, please see the program copf:\n";
    $tmp{"help input"}.=     "     ".$par{"exeCopf"}."\n";
    $tmp{"help input"}.=     "  -  In particular, the most simple alignment format  SAF is speci-\n";
    $tmp{"help input"}.=     "     fied in detail in the copf help.\n";
    $tmp{"help input"}.=     "  \n";
    $tmp{"help input"}.=     "  To pass the input file to PROF, simply do:\n";

    $cmd1="$sourceFile YOUR_FILE";
    $cmd2="$sourceFile YOUR_FILE keepConv";
    $cmd3="$sourceFile YOUR_FILE debug";

    $tmp{"help input"}.=     "." x length($cmd1)."\n". "$cmd1\n". "." x length($cmd1)."\n";
    $tmp{"help input"}.=     "  *  NOTE: the automatic COnversion of Protein Formats (COPF) is not\n";
    $tmp{"help input"}.=     "           sufficiently tested, yet.  \n";
    $tmp{"help input"}.=     "           Thus, please cross-check the file generated. \n";
    $tmp{"help input"}.=     "  *  By default, PROF deletes most of the files it produces.\n";
    $tmp{"help input"}.=     "     To keep the files generated by COPF, do:\n";
    $tmp{"help input"}.=     "." x length($cmd2)."\n". "$cmd2\n". "." x length($cmd2)."\n";
    $tmp{"help input"}.=     "     \n";
    $tmp{"help input"}.=     "     To keep most intermediate files, and to obtain a detailed screen\n";
    $tmp{"help input"}.=     "     output, do:\n";
    $tmp{"help input"}.=     "." x length($cmd3)."\n". "$cmd3\n". "." x length($cmd3)."\n";
    $tmp{"help input"}.=     "  \n";
    $tmp{"help input"}.=     "";

    return(%tmp);
}				# end of iniHelpProf

#===============================================================================
sub iniRdCmdline {
    my($SBR2);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iniRdCmdline                reads the command line
#       in / out GLOBAL:        all
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR2="$scrName:"."iniRdCmdline";
				# --------------------------------------------------
				# (1) get input directory
				# --------------------------------------------------
    foreach $arg (@ARGV){
	if ($arg=~/^dirIn=(.+)$/){
	    $par{"dirIn"}=$1;
	    last;}}

    $par{"dirIn"}=$PWD    
	if (defined $PWD &&
	    (! defined $par{"dirIn"} || $par{"dirIn"}=~/^(local|unk)$/ || length($par{"dirIn"})==0));
    $par{"dirIn"}.="/" if (defined $par{"dirIn"} && -d $par{"dirIn"} && $par{"dirIn"}!~/\/$/); #  slash
    $par{"dirIn"}=""   if (! defined $par{"dirIn"} || ! -d $par{"dirIn"}); # empty

				# --------------------------------------------------
				# (2) get all keywords used in script
				# --------------------------------------------------
    if (defined %par && %par){
        @tmp=sort keys (%par);}
    else{
	$#tmp=0;}

    $Lverb3=0 if (! defined $Lverb3);
    $Lverb2=0 if (! defined $Lverb2);
    $#fileIn=0;

                                # --------------------------------------------------
				# (2) interpret specific command line arguments
                                # --------------------------------------------------
    foreach $arg (@ARGV){
	next if ($arg=~/^dirIn/);
	next if ($arg=~/^ARCH=/);
				# ------------------------------
				# screen messages, debug mode asf
	if    ($arg=~/^verb\w*3=(\d)/)    { $par{"verb3"}=  $Lverb3=  $1;}
	elsif ($arg=~/^verb\w*3/)         { $par{"verb3"}=  $Lverb3=  1;}
	elsif ($arg=~/^verb\w*2=(\d)/)    { $par{"verb2"}=  $Lverb2=  $1;}
	elsif ($arg=~/^verb\w*2/)         { $par{"verb2"}=  $Lverb2=  1;}
	elsif ($arg=~/^verbose=(\d)/)     { $par{"verbose"}=$Lverb=   $1;}
	elsif ($arg=~/^verbose/)          { $par{"verbose"}=$Lverb=   1;}
	elsif ($arg=~/^verb$/)            { $par{"verbose"}=$Lverb=   1;}
	elsif ($arg=~/^silent/)           { $par{"verbose"}=$Lverb=   0; }

        elsif ($arg=~/^list$/i)           { $par{"isList"}=           1; }
        elsif ($arg=~/^verbForVec/i)      { $par{"verbForVec"}=       1; }
        elsif ($arg=~/^verbForProt/i)     { $par{"verbForProt"}=      1; }
        elsif ($arg=~/^verbForSam/i)      { $par{"verbForSam"}=       1; }
        elsif ($arg=~/^verbForErr/i)      { $par{"verbForErr"}=       1; }
        elsif ($arg=~/^de?bu?gali/i)      { $par{"debugali"}=         1; }
        elsif ($arg=~/^de?bu?gfor/i)      { $par{"debugfor"}=         1; }
        elsif ($arg=~/^de?bu?g/)          { $par{"debug"}=            1; }
				# ------------------------------
				# job related
        elsif ($arg=~/^nonice*$/i)        { $par{"optNice"}=          "nonice"; 
					    $par{"optNiceDef"}=       " "; }
        elsif ($arg=~/^nice\-?(\d+)$/i)   { $par{"optNice"}=          "nice ".$1;
					    $par{"optNiceDef"}=       "nice ".$1; }
        elsif ($arg=~/^nice=\-?(\d+)$/i)  { $par{"optNice"}=          "nice ".$1;
					    $par{"optNiceDef"}=       "nice ".$1;}
				# ------------------------------
				# network coding
        elsif ($arg=~/^cor[a-z]*$/i)      { $par{"doCorSparse"}=      1; }
				# ------------------------------
				# network modes
        elsif ($arg=~/^2nd$/i)            { $par{"modenet"}=          $par{"modenet2nd"}; 
					    $par{"modein"}=           $par{"modein2nd"};}
        elsif ($arg=~/^add2nd$/i)         { $par{"doBuild2nd"}=       1; }
				# ------------------------------
				# input related
	elsif ($arg=~/^seq=([^\s]+)/)     { $sequenceIn=              $1; }

				# ------------------------------
				# PROF modes
	elsif ($arg eq "acc")             { $par{"optProf"}=           "acc"; }
	elsif ($arg eq "htm")             { $par{"optProf"}=           "htm"; }
	elsif ($arg eq "sec")             { $par{"optProf"}=           "sec"; }
	elsif ($arg eq "both"|$arg eq "acc+sec"|$arg eq "sec+acc")
	                                  { $par{"optProf"}=           "both";}
	elsif ($arg eq "3")               { $par{"optProf"}=           "3";}

	elsif ($arg eq "notHtmisit")      { $par{"optDoHtmisit"}=     0; }
	elsif ($arg eq "notHtmfil")       { $par{"optDoHtmfil"}=      0; }
	elsif ($arg eq "notHtmref")       { $par{"optDoHtmref"}=      0; }
	elsif ($arg eq "notHtmtop")       { $par{"optDoHtmtop"}=      0; }
	elsif ($arg eq "doHtmisit")       { $par{"optDoHtmisit"}=     1; }
	elsif ($arg eq "doHtmfil")        { $par{"optDoHtmfil"}=      1; }
	elsif ($arg eq "doHtmref")        { $par{"optDoHtmref"}=      1; }
	elsif ($arg eq "doHtmtop")        { $par{"optDoHtmtop"}=      1; }

	elsif ($arg =~ /^(fast|good|best)$/i) 
	                                  { $par{"optProfQuality"}=   $1;}
	elsif ($arg =~ /^phd$/i)          { $par{"optJury"}.=         ",usePHD" if ($par{"optJury"}!~/phd/i);}
	elsif ($arg =~ /^nophd$/i)        { $par{"optJury"}=~s/,usePHD//i if ($par{"optJury"}=~/phd/i);}

	elsif ($arg =~ /para(3|Both|Sec|Acc|Htm|CapH|CapE|CapHE)=(.*)/i)
	                                  { $par{"para".$1}=          $2; 
					    $par{"dirNet"}=           $2;
					    $par{"dirNet"}=~s/(\/)[^\/]*$/$1/g;
					    $par{"optJury"}=          "normal";}
	elsif ($arg =~ /para?=(.*)/)      { $par{"para"."opt"}=       $1; 
					    $par{"dirNet"}=           $1;
					    $par{"dirNet"}=~s/(\/)[^\/]*$/$1/g;
					    $par{"optJury"}=          "normal";}
	elsif ($arg =~ /jct=(.*)/)        { $par{"para"."opt"}=       $1; 
					    $par{"optJury"}=          "normal";}
	                               
				# ------------------------------
				# PROF filters asf
	elsif ($arg =~ /^htm=(\d)$/)      { $par{"optHtmisitMin"}=    "0.".$1;}
	elsif ($arg =~ /^htm=([0-9\.]+)$/){ $par{"optHtmisitMin"}=    $1;}


				# ------------------------------
				# process input
	elsif ($arg eq "filter")          { $par{"doFilterHssp"}=     1; }
	elsif ($arg eq "doFilterHssp")    { $par{"doFilterHssp"}=     1; }

	elsif ($arg =~ /^skip.*$/ &&
	          $arg !~ /^skipMiss.*/i) { $par{"doSkipExisting"}=   1; }
	elsif ($arg =~ /^skipMiss.*$/i)   { $par{"doSkipMissing"}=    1; }
	elsif ($arg =~ /^not?Search/i)    { $par{"doSearchFile"}=     0; }

	elsif ($arg=~/^user=(\S*)$/)      { $USERID=                  $1;}
	elsif ($arg=~/^Para/)             { $par{"optPara"}=          $arg;}

	elsif ($arg=~/^(psi|blast)/)      { $par{"modeAli"}=          "psi";}

				# ------------------------------
				# output related
	elsif ($arg =~ /^doEval/i)        { $par{"doEval"}=           1; }
	elsif ($arg =~ /^eval$/)          { $par{"doEval"}=           1; }
	elsif ($arg =~ /^not?eval$/i)     { $par{"doEval"}=           0; }
	
	elsif ($arg =~ /^not?ProfHead/i)  { $par{"doRetHeader"}=      0; }
	elsif ($arg eq "dssp")            { $par{"doRetDssp"}=        1; }
	elsif ($arg eq "casp")            { $par{"doRetCasp"}=        1; }
	elsif ($arg eq "msf")             { $par{"doRetMsf"}=         1; }
	elsif ($arg eq "saf")             { $par{"doRetSaf"}=         1; }
	elsif ($arg eq "ali")             { $par{"doRetAscii"}=       1; 
					    $par{"optOutAli"}=        1; }
	elsif ($arg eq "graph")           { $par{"doRetAscii"}=       1; 
					    $par{"optOutGraph"}=      1; }
	elsif ($arg =~ /^ascii?/i)        { $par{"doRetAscii"}=       1; }
	elsif ($arg =~ /^noascii?/i)      { $par{"doRetAscii"}=       0; }
	elsif ($arg eq "html")            { $par{"doRetHtml"}=        1; }
	elsif ($arg eq "nohtml")          { $par{"doRetHtml"}=        0; }
	elsif ($arg =~ /^html=(.*)/)      { $par{"optModeRetHtml"}=   "" if (! $par{"optModeRetHtml"});
					    $par{"optModeRetHtml"}.=  "html:".$1;
					    $par{"doRetHtml"}=        1; }
	elsif ($arg =~ /^data=(.*)/)      { $par{"optModeRetHtml"}=   "" if (! $par{"optModeRetHtml"});
					    $par{"optModeRetHtml"}.=  "data:".$1;
					    $par{"doRetHtml"}=        1; }
	elsif ($arg =~ /^(brief|all|normal|detail)$/){
	                                    $par{"optModeRetHtml"}=   "" if (! $par{"optModeRetHtml"});
					    $par{"optModeRetHtml"}.=  "data:".$1;
					    $par{"doRetHtml"}=        1; 
					    $tmp=$1;
					    $tmp1=substr($tmp,1,1); $tmp1=~tr/[a-z]/[A-Z]/;
					    $tmp2=substr($tmp,2); 
					    $tmp= $tmp1.$tmp2;
					    $par{"optOut".$tmp}=      1;}
	elsif ($arg =~ /^(notation|averages|header|subset|graph|ali)$/){
					    $tmp=$1;
					    $tmp1=substr($tmp,1,1); $tmp1=~tr/[a-z]/[A-Z]/;
					    $tmp2=substr($tmp,2); 
					    $tmp= $tmp1.$tmp2;
					    $par{"optOut".$tmp}=      1;}
	elsif ($arg eq "msf")             { $par{"doRetAli"}=         1; 
					    $par{"formatRetAli"}=     "msf";}
	elsif ($arg eq "saf")             { $par{"doRetAli"}=         1; 
					    $par{"formatRetAli"}=     "saf";}
	elsif ($arg eq "expand")          { $par{"doRetAli"}=         1;
					    $par{"doRetAliExpand"}=   1; }
	elsif ($arg =~/^(test|tst)$/)     { $par{"isTest"}=           1;
					    $par{"optProfQuality"}=   "tst";}
	elsif ($arg=~/^keepConv.*$/i)     { $par{"keepConvertHssp"}=  1; }
	elsif ($arg=~/^keepFil.*$/i)      { $par{"keepFilterHssp"}=   1; }
				# file names
	elsif ($arg=~/^fileProf=(\S*)$/i) { $par{"fileOutProf"}=    $1;
					    $par{"doRetAscii"}=     1; }
	elsif ($arg=~/^fileOut=(\S*)$/i)  { $par{"fileOutRdb"}=     $1;}
	elsif ($arg=~/^fileRdb=(\S*)$/i)  { $par{"fileOutRdb"}=     $1;}
	elsif ($arg=~/^fileOutNot.*=(\S*)$/i)
                                          { $par{"fileOutNotHtm"}=  $1;}
	elsif ($arg=~/^fileNot.*=(\S*)$/i){ $par{"fileOutNotHtm"}=  $1;}
	elsif ($arg=~/^fileOutDssp=(\S*)$/i) { $par{"fileOutDssp"}=    $1;
					    $par{"doRetDssp"}=      1; }
	elsif ($arg=~/^fileDssp=(\S*)$/i) { $par{"fileOutDssp"}=    $1;
					    $par{"doRetDssp"}=      1; }
	elsif ($arg=~/^fileCasp=(\S*)$/i) { $par{"fileOutCasp"}=    $1;
					    $par{"doRetCasp"}=      1; }
	elsif ($arg=~/^fileAli=(\S*)$/i)  { $par{"fileOutAli"}=     $1; 
					    $par{"doRetAli"}=       1; }
	elsif ($arg=~/^(fileHtml|fileOutHtml)=(\S*)$/i) 
	                                  { $par{"fileOutHtml"}=    $2; 
					    $par{"doRetHtml"}=      1; }
	elsif ($arg=~/^fileEval=(\S*)$/i) { $par{"fileOutEval"}=    $1; 
					    $par{"doEval"}=         1; }

                                # process chains (h|dssp)
	elsif ($arg!~/\=/ && $arg=~/(.+)$par{"extChain"}([A-Z0-9])$/){
	    $file=$1.$par{"extChain"}.$2;
	    if (defined $1 && -e $1) {
		push(@fileIn,$file);}
	    else {
		return(&errSbr("kwd=$arg not correct syntax (use:file.[hd]ssp_C)\n",$SBR2));}}

				# ------------------------------
				# go through paras
	else  { 
	    $Lok=0;
				# is it file?
	    if (-e $arg && ! -d $arg){
		$Lok=1;
		push(@fileIn,$arg);}
				# file again
	    if (! $Lok && length($par{"dirIn"})>1 && -e $par{"dirIn"}.$arg){
		$Lok=1;
		push(@fileIn,$par{"dirIn"}.$arg);}
				# any of the paras defined ?
	    if (! $Lok && $arg=~/=/){
		foreach $kwd (@tmp){
		    if ($arg=~/^$kwd=(.+)$/){
			$Lok=1;
			$par{$kwd}=$1;
			last;}
		}}
				# argument wrong
	    if (! $Lok){
		push(@argUnk,$arg);
		next; }}
    }				# end of loop over all arguments
				# --------------------------------------------------

				# any errors?
    if ($#argUnk > 0){
	$tmp="*** ERROR $scrName: some input arguments were not recognised:\n";
	foreach $argUnk(@argUnk){
	    $tmp.="$argUnk,";
	}
	$tmp.="\n";
	return(&errSbr("$tmp",$SBR2));}

				# ----------------------------------------
				# fill in parameter file if unspecified
    if (defined $par{"para"."opt"}){
	$tmp1=substr($par{"optProf"},1,1); $tmp1=~tr/[a-z]/[A-Z]/;
	$tmp2=substr($par{"optProf"},2);
	$tmp=$tmp1.$tmp2;
	$par{"para".$tmp}=$par{"para"."opt"};
    }

				# ------------------------------
				# hierarchy of blabla
    $par{"verb3"}=1             if ($par{"debug"});
    $par{"verbose"}=$par{"verb2"}=1 if ($par{"verb3"});
    $par{"verbose"}=1           if ($par{"verb2"});
    $Lverb= $par{"verbose"}     if (defined $par{"verbose"} && $par{"verbose"});
    $Lverb2=$par{"verb2"}       if (defined $par{"verb2"}   && $par{"verb2"});
    $Lverb3=$par{"verb3"}       if (defined $par{"verb3"}   && $par{"verb3"});

				# ------------------------------
				# html stuff
    $par{"optModeRetHtml"}=
	$par{"optModeRetHtmlDef"} if ($par{"doRetHtml"} && ! $par{"optModeRetHtml"});

				# ------------------------------
				# no PHD if para defined
    if (defined $par{"para"."opt"}){
	$par{"optJury"}=          "normal";
    }
    
				# --------------------------------------------------
				# syntax check: all necessary info there?
				# --------------------------------------------------
				# add some comments
    ($Lok,$msg)=
	&iniInterpret();        return(&errSbrMsg("failed updating parameters",
                                                  $msg,$SBR2)) if (! $Lok); 

				# hack
    @otherDistance=split(/,/,$par{"convOtherDistance"}) if (length($par{"convOtherDistance"})>0);
    return(1,"ok $SBR2");
}				# end of iniRdCmdline

#===============================================================================
sub iniInterpret {
    my($SBR2,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iniInterpret                interprets nn.defaults settings
#                               note: this should become the 'single' to touch
#                                 part for new training modes!
#       in/out GLOBAL:          all
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR2="$scrName:"."iniInterpret";
				# avoid warnings
    $#codeLen=$#codeNali=$#codeNfar=$#codeDisN=$#codeDisC=0;

				# ------------------------------
				# coding of global parameters
				# ------------------------------
    $par{"codeLen"}=~s/^,*|,*$//g;     @codeLen=    split(/,/,$par{"codeLen"});
    $par{"codeNali"}=~s/^,*|,*$//g;    @codeNali=   split(/,/,$par{"codeNali"});
    $par{"codeNfar"}=~s/^,*|,*$//g;    @codeNfar=   split(/,/,$par{"codeNfar"});
    $par{"codeDisN"}=~s/^,*|,*$//g;    @codeDisN=   split(/,/,$par{"codeDisN"});
    $par{"codeDisC"}=~s/^,*|,*$//g;    @codeDisC=   split(/,/,$par{"codeDisC"});


    return(1,"ok $SBR2");
}				# end of iniInterpret

#===============================================================================
sub iniSetFinal {
    my($SBR2);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iniSetFinal                 final parameter settings
#       in / out GLOBAL:        all
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR2="$scrName:"."iniSetFinal";$fhoutLoc="FHOUT_"."iniSetFinal";
				# ------------------------------
				# all output files to working dir
    $par{"dirOut"}=
	$par{"dirWork"}         if (&isName($par{"dirWork"}) && 
				    ! &isName($par{"dirOut"}));

				# ------------------------------
				# standard settings
    $Lok=			# 
	&brIniSet();            return(&errSbr("after brIniSet\n",$SBR2)) if (! $Lok);

				# --------------------------------------------------
				# input files
				# --------------------------------------------------
				# any input file given?
    if    ($#fileIn<1 && (! defined $sequenceIn || ! $sequenceIn)) {
	return(&errSbr("no file, no sequence??",$SBR2));}
    elsif ($#fileIn<1) {
	$formatIn=$formatIn[1]="fasta";
	$chainIn= $chainIn[1]= $par{"symbolChainAny"};
	$fileSeq= $par{"fileOutSeqTmp"};
	push(@FILE_REMOVE,$fileSeq);
	open($fhoutLoc,">".$fileSeq)||
	    &errSbr("failed to open file=$fileSeq! line=". __LINE__ ,$SBR2);
	print $fhoutLoc
	    ">sequence_given_on_command_line\n",
	    $sequenceIn,"\n";
	close($fhoutLoc);
	@fileIn=($fileSeq);}
    
    ($Lok,$msg)=
	&iniSetFinalFileIn();   return(&errSbrMsg("failed iniSetFinalFileIn:\n",
						  $msg,$SBR2)) if (! $Lok);
				# --------------------------------------------------
				# further corrections
				# --------------------------------------------------
				# title
    if (! &isName($par{"title"}) &&
        $par{"title"} ne "title") {
	$par{"titleTmp"}= $par{"title"}."tmp"
	    if (! &isName($par{"titleTmp"}));
				# correct trace files asf
	foreach $des ("fileOutTrace",
		      "fileOutScreen",    # log files
		      "fileOutErrorConv", # error during conversion
		      "fileOutError",     # output report
		      ){
				# skip if already having title
	    next if ($par{$des}=~/$par{"titleTmp"}/);
	    $tmp=$par{$des};
	    $par{$des}=~s/^(NN|$par{"titleIni"})?/$par{"titleTmp"}/g; 
	} }
				# ------------------------------
				# additional global output files
				# ------------------------------
    if (! defined $par{"fileOutEval"} || ! &isName($par{"fileOutEval"})){
	$par{"fileOutEval"}=$par{"dirOut"}.$par{"title"}.$par{"extOutEval"};
    }
				# ------------------------------
				# temporary files
				# ------------------------------
    foreach $kwd ("titleNetIn","titleNetOut"){
	if (! &isName($par{$kwd})){
	    $par{$kwd}=$par{"titleTmp"};
	    $par{$kwd}.="in"    if ($kwd eq "titleNetIn");
	    $par{$kwd}.="out"   if ($kwd eq "titleNetOut");
	}}

				# --------------------------------------------------
				# nice level, priority
				# --------------------------------------------------
    $par{"exeSysNice"}=
	$par{"exeSysNice","MAC"} if ($ARCH =~/^MAC/ && !-e $par{"exeSysNice"} && !-l $par{"exeSysNice"});
    
    $par{"optNice"}=$par{"optNiceDef"} if ($par{"optNice"} eq "nice");
    $par{"optNice"}=" "                if ($par{"optNice"} eq "nonice");
    if ($par{"optNice"} =~ /nice-|^[\-\d]+$/){
	$optNice=$par{"optNice"}; $par{"optNice"}=~s/nice\-/nice \-/;
	$optNice=~s/\s|nice|\-|\+//g;
        if    (length($optNice)>0 && setpriority(0,0,0)){
            $par{"optNice"}=" "; # avoid being too nice!
            setpriority(0,0,$optNice);}
        elsif (length($optNice)>0){
            $par{"optNice"}=$optNice;}}

				# secure that 'title' is given here
    $#fileOut=0;                # reset output files
    if (! &isName($fileOut) && $formatIn[1] ne "seq"){
        foreach $it (1..$#fileIn){
	    if ($#fileIn == 1               && 
		defined $par{"fileOutRdb"}  &&
		$par{"fileOutRdb"} ne "unk" && 
		length($par{"fileOutRdb"}) >= 2){
		$fileOut=$par{"fileOutRdb"};
		push(@fileOut,$fileOut);
		last; }

	    next if (! defined $fileIn[$it] ||
		     length($fileIn[$it])<1 ||
		     $fileIn[$it]=~/^unk$/);
            $tmp=   $fileIn[$it]; 
	    $tmp=~s/^.*\///g;
	    $tmp2=  substr($formatIn[$it],2);
	    $tmp3=  substr($formatIn[$it],1,1);
	    $tmp3=~tr/[a-z]/[A-Z]/;
	    $tmp4=  "";
	    $kwdExt="ext".$tmp3.$tmp2;
	    $ext=   $par{$kwdExt} if (defined $par{$kwdExt});
	    $tmp=~s/^.*\///g;$tmp=~s/$ext(.*)$//g;
	    $tmp4=  $1          if (defined $1 && length($1)>0);
	    $tmp.=$par{"extChain"}.$chainIn[$it]  
		if (defined $chainIn[$it] && 
		    $chainIn[$it] !~ /^[\*\s$par{"symbolChainAny"}]$/);
            $fileOut=$par{"dirOut"}.$tmp.$par{"extProfOut"}.$tmp4;
            push(@fileOut,$fileOut);}}
    elsif ($formatIn[1] ne "seq"){
	push(@fileOut,$fileOut);}

    if ($#fileOut<1 && defined $sequenceIn){
	$fileOut=$par{"dirOut"}."my_protein".$par{"extProfOut"};
	push(@fileOut,$fileOut);}
				# ------------------------------
				# output modes
				# ------------------------------
    $modeWrt="";
    $modeWrt.="ascii,"          if ($par{"doRetAscii"});
    $modeWrt.="dssp,"           if ($par{"doRetDssp"});
    $modeWrt.="msf,"            if ($par{"doRetMsf"});
    $modeWrt.="saf,"            if ($par{"doRetSaf"});
    $modeWrt.="casp,"           if ($par{"doRetCasp"});
    $modeWrt.="notation,"       if ($par{"optOutNotation"});
    $modeWrt.="averages,"       if ($par{"optOutAverages"});
    $modeWrt.="header,"         if ($par{"optOutHeader"});
    $modeWrt.="summary,"        if ($par{"optOutHeaderSum"});
    $modeWrt.="info,"           if ($par{"optOutHeaderInfo"});
    $modeWrt.="brief,"          if ($par{"optOutBrief"});
    $modeWrt.="normal,"         if ($par{"optOutNormal"});
    $modeWrt.="subset,"         if ($par{"optOutSubset"});
    $modeWrt.="detail,"         if ($par{"optOutDetail"});
    $modeWrt.="graph,"          if ($par{"optOutGraph"});
    $modeWrt.="ali,"            if ($par{"optOutAli"});

    $modeWrt.="html,"           if ($par{"doRetHtml"});
    $modeWrt=~s/\,$//g;
    $par{"modewrt"}=$modeWrt;
                                # --------------------------------------------------
                                # error check
                                # --------------------------------------------------
    $exclude= "exeHtmfil,exeHtmref,exeHtmtop,exeSysNice,exeSysNiceMAC,exePvmgetarch";
    $exclude.=",exeConvHssp2saf,";

    ($Lok,$msg)=                # standard
        &brIniErr($exclude);    return(&errSbrMsg("after lib-col:brIniErr",$msg,$SBR2))  if (! $Lok);  
                                # --------------------------------------------------
                                # trace file
                                # --------------------------------------------------
    if (&isName($par{"fileOutTrace"} && ! $par{"debug"})){
        print "--- \t open $FHTRACE for fileOutTrace=",$par{"fileOutTrace"},"\n"  if ($Lverb2);
	$FHTRACE2=  $FHTRACE;
	$FHPROT_ALI=$FHTRACE;
        open($FHTRACE2,">".$par{"fileOutTrace"}) || 
            return(&errSbr("failed to open new file for fileOutTrace=".$par{"fileOutTrace"},$SBR2));
	$FHTRACE= "STDOUT"      if ($par{"verbose"});
    }
    else {
				# 
	if ($par{"debugali"}){
	    $FHPROG_ALI="STDOUT";}
	else {			# still open trace for alignment programs
	    $FHPROG_ALI="FHPROG_ALI";
	    open($FHPROG_ALI,">".$par{"fileOutTrace"}) || 
		return(&errSbr("failed to open new file for fileOutTrace=".
			       $par{"fileOutTrace"},$SBR2));}
	$FHTRACE="STDOUT";
	$FHTRACE2=$FHTRACE;}
				# handle for writing output from programs called
    $FHPROG=  $FHTRACE2;
    $FHPROG=  "STDOUT"          if ($par{"debug"});

				# no screen file for debug mode
#    $par{"fileOutScreen"}=0     if ($par{"debug"});

				# list of temporary files to remove in the end
    $#FILE_REMOVE=0; $#FILE_REMOVE=0; # second to avoid warning!
    $#FILE_REMOVE_TMP=0; $#FILE_REMOVE_TMP=0; # second to avoid warning!
				# list of input files for which some serious errors happened
    $#FILE_ERROR= 0; $#FILE_ERROR= 0; # second to avoid warning!

                                # --------------------------------------------------
                                # error file
                                # --------------------------------------------------
    if ($FHERROR !~ /^(STDERR|STDOUT)$/ &&
	&isName($par{"fileOutError"})){
        print "--- \t open $FHERROR for error file ",$par{"fileOutError"}," \n"  if ($Lverb2);
        open($FHERROR,">>".$par{"fileOutError"}) || 
            return(&errSbr("failed to open new file for fileOutError=".$par{"fileOutError"},$SBR2));}

				# ------------------------------
				# write settings
				# ------------------------------
    $exclude="kwd,dir*,ext*";	# keyword not to write
    $exclude="kwd*,dir*,notation*,txt*,text*,known";	# keyword not to write
    $fhloc=$FHTRACE2;
    $fhloc=$FHTRACE             if ($par{"debug"});

    ($Lok,$msg)=
	&brIniWrt($exclude,$fhloc);

    return(&errSbrMsg("after lib-ut:brIniWrt",$msg,$SBR2))  if (! $Lok); 

    return(1,"ok $SBR2");
}				# end of iniSetFinal

#===============================================================================
sub iniSetFinalFileIn {
    my($SBR3);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iniSetFinalFileIn           digests input file(s)/format(s), gets ids asf
#       in / out GLOBAL:        all
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR3="$scrName:"."iniSetFinalFileIn";
				# --------------------------------------------------
				# loop over all input files
				# --------------------------------------------------
    $#filePar=0;
    $#tmpFile=$#tmpChain=0;     # separate db from list files and get list
    $#tmpFileMissing=0;

    foreach $fileIn (@fileIn){
				# ------------------------------
				# (1) for existing files:
	if (-e $fileIn){
				# (1a) parameter file?
	    if ($fileIn=~/$par{"extProfPar"}$/ || &isProf2Para($fileIn)){
		push(@filePar,$fileIn);
		next; }
				# (1a) junction file?
	    if ($fileIn=~/$par{"extProfJct"}$/ || &isProf2Jct($fileIn)){
		push(@filePar,$fileIn);
		next; }
				# (1b) list?
	    if ($fileIn =~/\.list/) {
		($Lok,$msg,$fileTmp,$chainTmp)=
		    &iniSetFinalFileInList($fileIn); 
		return(&errSbrMsg("after iniSetFinalFileInList ($fileIn)",
				  $msg,$SBR3)) if (! $Lok);
				#      dissect list
		push(@tmpFile, split(/,/,$fileTmp));
		push(@tmpChain,split(/,/,$chainTmp));
		next; }
				# (1c) ok as is
	    push(@tmpFile, $fileIn);
	    push(@tmpChain,$par{"symbolChainAny"});
	    next; }
				# ------------------------------
				# (2) chain?
	else {
	    if ($fileIn=~/$par{"extChain"}/){
		$fileTmp=$fileIn; 
		$fileTmp=~s/$par{"extChain"}(.)$//;
		$chainTmp=$1;
		if (-e $fileTmp){
		    push(@tmpFile, $fileTmp);
		    push(@tmpChain,$chainTmp);
		    next;}}}
	push(@tmpFileMissing,$fileIn);
    }
    @fileIn= @tmpFile; 
    @chainIn=@tmpChain;
    if ($#tmpFileMissing){
	@tmp=
	    ("--- the following files appear ok:\n",
	     "--- file :",join(',',@fileIn,"\n"),
	     "--- chain:",join(',',@chainIn,"\n"),
	     "*** \n",
	     "*** HOWEVER the following are missing:\n",
	     "*** file :",join(',',@fileIn,"\n"),
	     "*** sorry ..\n");
	&errSbr("missing files\n".join('',@tmp)."\n",$SBR3);}
				# --------------------------------------------------
				# (2a) no parameter file given AND NOT test:
				#      USE defaults
				# --------------------------------------------------
	
    @filePar=$par{"para"."opt"} if (defined $par{"para"."opt"});

    if (! @filePar){
	$err=0;
				# is test run
	if    ($par{"optProfQuality"} eq "tst" || $par{"isTest"}){
	    if    ($par{"optProf"} eq "3")    { push(@filePar,$par{"para3Tst"}); }
	    elsif ($par{"optProf"} eq "both") { push(@filePar,$par{"paraBothTst"}); }
	    elsif ($par{"optProf"} eq "acc")  { push(@filePar,$par{"paraAccTst"}); }
	    elsif ($par{"optProf"} eq "sec")  { push(@filePar,$par{"paraSecTst"}); }
	    else                              { $err=1; }}
				# is one of the preset 'fast|good|best'
	elsif ($par{"optProfQuality"} =~/^(fast|good|best)$/){
	    $quality=$1;
	    if    ($par{"optProf"} eq "3")    { push(@filePar,$par{"para3"."run".$quality}); }
	    elsif ($par{"optProf"} eq "both") { push(@filePar,$par{"paraBoth"."run".$quality}); }
	    elsif ($par{"optProf"} eq "acc")  { push(@filePar,$par{"paraAcc"."run".$quality}); }
	    elsif ($par{"optProf"} eq "sec")  { push(@filePar,$par{"paraSec"."run".$quality}); }
	    else                              { $err=1; }}
				# none of the above: use defaults
	else {
	    if    ($par{"optProf"} eq "3")    { push(@filePar,$par{"para3"}); }
	    elsif ($par{"optProf"} eq "both") { push(@filePar,$par{"paraBoth"}); }
	    elsif ($par{"optProf"} eq "acc")  { push(@filePar,$par{"paraAcc"}); }
	    elsif ($par{"optProf"} eq "sec")  { push(@filePar,$par{"paraSec"}); }
				# xx yyy
	    elsif ($par{"optProf"} eq "htm")  { push(@filePar,0);}
#	    elsif ($par{"optProf"} eq "htm")  { push(@filePar,$par{"paraHtm"}); }
#	    elsif ($par{"optProf"} eq "cap")  { push(@filePar,$par{"paraCap"}); }
	    else                              { $err=1;}}

	&errSbr("default for parameter file for mode=".$par{"optProf"}.", not implemented, yet!",
		$SBR3) if ($err);
    }
				# --------------------------------------------------
				# (2c) parameter file IS given:
				#      check whether the expected one there
				# --------------------------------------------------
    else {
	$Lerr=0;
	if    ($par{"optProf"} eq "sec"){
	    if ($#filePar==1)     { $par{"paraSec"}=$filePar[1]; } else { $Lerr="sec>1"; }}
	elsif ($par{"optProf"} eq "acc"){
	    if ($#filePar==1)     { $par{"paraAcc"}=$filePar[1]; } else { $Lerr="acc>1"; }}
	elsif ($par{"optProf"} eq "htm"){
	    if ($#filePar==1)     { $par{"paraHtm"}=$filePar[1]; } else { $Lerr="htm>1"; }}
	elsif ($par{"optProf"} eq "both"){
	    if    ($#filePar==2)  { $possec=1; $possec=2 if ($filePar[1] =~ /ACC/); 
				    $posacc=2; $posacc=1 if ($filePar[1] =~ /ACC/); 
				    $par{"paraSec"}=$filePar[$possec]; 
				    $par{"paraAcc"}=$filePar[$posacc]; }
	    elsif ($#filePar==1)  { $Lerr="both=1";}
	    else                  { $Lerr="both>2"; }}
	elsif ($par{"optProf"} eq "3"){
	    if    ($#filePar==3)  { $possec=1;$posacc=2;$poshtm=3; 
				    if    ($filePar[1] =~ /ACC/ && 
					   $filePar[3] =~ /HTM/) { $possec=2; $posacc=1; $poshtm=3; }
				    elsif ($filePar[1] =~ /ACC/ && 
					   $filePar[2] =~ /HTM/) { $possec=3; $posacc=1; $poshtm=2; }
				    elsif ($filePar[2] =~ /ACC/ && 
					   $filePar[1] =~ /HTM/) { $possec=3; $posacc=2; $poshtm=1; }
				    elsif ($filePar[3] =~ /ACC/ && 
					   $filePar[2] =~ /HTM/) { $possec=1; $posacc=3; $poshtm=2; }
				    elsif ($filePar[3] =~ /ACC/ && 
					   $filePar[1] =~ /HTM/) { $possec=2; $posacc=3; $poshtm=1; }
				    else { $Lerr="3none";} }
	    elsif ($#filePar <3)  { $Lerr="3<3"; }
	    elsif ($#filePar >3)  { $Lerr="3>3"; }
	    else                  { $Lerr="3?"; }}
	else {
	    &errSbrMsg("2c: optProf=".$par{"optProf"}.", trouble assigning filePar=".
		       join(',',@filePar),$SBR3);}
	if ($Lerr){
	    &errSbrMsg("2c: optProf=".$par{"optProf"}.", problem=$Lerr in assigning filePar=".
		       join(',',@filePar),$SBR3);}
    }

				# ------------------------------
				# (3) verify that format ok
    $#formatIn=0;
    foreach $fileIn (@fileIn){
				# get format
	($Lok,$msg)=
	    &getFileFormatQuicker($fileIn);
				# failed
	return(&errSbr("could not determine format for fileIn=$fileIn!\n",
		       $SBR3))
	    if (! $Lok || $msg =~ /ERROR/ || length($msg)>10 || length($msg)<3);
				# wrong format?
	$formatInLoc=$msg;$formatInLoc=~tr/[A-Z]/[a-z]/;
	return(&errSbr("input format '".$formatIn.
		       "' (of files in file=$fileIn) unsupported\n",$SBR3))
	    if ($formatInLoc !~ /^($okFormInOr)$/); 
				# store format
	push(@formatIn,$formatInLoc);
    }

    return(1,"ok $SBR3");
}				# end of iniSetFinalFileIn

#===============================================================================
sub iniSetFinalFileInList {
    local($fileInLoc)=@_;
    my($SBR4,$fhinLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iniSetFinalFileInList       reads the names in a list of files (e.g. nndb.rdb)
#       in / out GLOBAL:        all
#       out:                    1|0,msg,$format:  implicit:
#                               0 = ERROR
#                               1 = OK
#                               2 = format unsupported 
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR4="$scrName:"."iniSetFinalFileInList";
    $fhinLoc="FHIN_".$SBR4;
				# check arguments
    return(0,"*** $SBR4: not def fileInLoc!")            if (! defined $fileInLoc);
    return(0,"*** $SBR4: miss in fileInLoc=$fileInLoc!") if (! -e $fileInLoc);

				# open file
    open($fhinLoc,$fileInLoc) ||
	return(0,"*** ERROR $SBR4: fileIn=$fileInLoc, not opened\n");

				# ------------------------------
				# read list
    $stringChain=$stringFile="";
    $tmpMissing="";
    while (<$fhinLoc>) {
	$_=~s/\n|\s//g; 
	$file=$_;
	next if (length($_)==0);
				# --------------------
	if    (-e $file) {	# is existing
	    $stringFile.= $file.",";
	    $stringChain.=$par{"symbolChainAny"}.",";
	    next; }
				# --------------------
				# is not existing
	$Lok=0;$chainTmp=$par{"symbolChainAny"};

	foreach $form (@okFormIn){
	    $kwdExt= $okFormIn{$form,"kwd","ext"};
	    $ext=    "";
	    $ext=    $par{$kwdExt} if (defined $par{$kwdExt});
	    $kwdDir= $okFormIn{$form,"kwd","dir"};
	    @tmp=    split(/,/,$kwdDir);
	    @tmpDir=("");
				# find directories corresponding to different formats
	    foreach $kwd (@tmp){
		push(@tmpDir,$par{$kwd}) if (defined $par{$kwd});
	    }
				# check dir (first: local!)
	    foreach $dir (@tmpDir){
		next if (! -d $dir && ! -l $dir && length($dir)>0);
		$fileTmp=$file; 
		$dir.="/"       if (length($dir)>0 && $dir !~/\/$/);
		$fileTmp=~s/^(.*$ext)\_([A-Z0-9])$/$1/;
		$chainTmp=$2    if (defined $2);
		$fileTmp=$dir.$fileTmp; 
		$Lok=1          if (-e $fileTmp);
		last if ($Lok);
	    }
	    last if ($Lok);
	}
				# seems it found one
	if ($Lok){
	    $stringFile.=     $fileTmp.",";
	    if (! defined $chainTmp || $chainTmp eq $par{"symbolChainAny"}){
		$stringChain.=$par{"symbolChainAny"}.",";}
	    else {
		$stringChain.=$chainTmp.",";}}
				# seems it did NOT find one
	else { 
	    $tmpMissing.="-*- WARN $SBR4 missing file=$file,\n";}
    }
    close($fhinLoc);
    if (! $par{"doSkipMissing"}){
	return(&errSbrMsg("missing files:\n",$tmpMissing.
			  "-*- NOTE: to prevent abortion because of missing files use keyword:\n".
			  "skipMissing\n",$SBR4)) if (length($tmpMissing)>1); }
    else {
	print $tmpMissing;}

    $stringFile=~s/^,*|,*$//g;
    $stringChain=~s/^,*|,*$//g;

    return(&errSbrMsg("assumed it is a file_list but failed to read it (3)",$msg,$SBR4)) 
	if (! $Lok && length($stringFile) < 2);
				# ******************** <-------
				# will become final input file!
    push(@tmp2File, split(/,/,$stringFile)); 
    push(@tmp2Chain,split(/,/,$stringChain));

    return(&errSbrMsg("after file_list empty (3)",$msg,$SBR4)) if ($#tmp2File==0);

    $#tmp=$#tmp2File=
	$#tmp2Chain=0;		# slim-is-in
	
    return(1,"ok $SBR4",$stringFile,$stringChain);
}				# end of iniSetFinalFileInList

1;
