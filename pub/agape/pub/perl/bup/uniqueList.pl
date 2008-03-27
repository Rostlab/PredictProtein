#!/usr/bin/perl -w
##!/bin/env perl
##!/usr/sbin/perl -w
##!/usr/pub/bin/perl -w
#-------------------------------------------------------------------------------
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$scrName=$0; $scrName=~s/^.*\/|\.pl//g;
$scrGoal=    "compiles a list of unique protein (pairs)\n".
    "      \t a la hobohm greedy!";
$scrIn=      "pair RDB";            # 
$scrNarg=    1;                  # minimal number of input arguments
$scrHelpTxt= "To generate the input file of pairs, do:\n";
$scrHelpTxt.="(1)  run BLAST on a list of fasta files, e.g.: \n";
$scrHelpTxt.="     > blastRun.pl file.list|*.f filter db=phd\n";
$scrHelpTxt.="(2)  run the post-processing on the output.rdb, e.g.: \n";
$scrHelpTxt.="     > blastProcessRdb.pl blast*.rdb pdb\n";
$scrHelpTxt.="(3)  run $scrName on the output of 2 (Outpairs*)\n";
$scrHelpTxt.=" \n";
$scrHelpTxt.="Explicitly ex|including proteins:\n";
$scrHelpTxt.="*    excluding file with:\n";
$scrHelpTxt.="        header: '# exclude' \n";
$scrHelpTxt.="        body:   'name\t anything' (anything = e.g. '# comment why'\n";
$scrHelpTxt.="*    including file with hierarchy:\n";
$scrHelpTxt.="        header: '# include 1' \n";
$scrHelpTxt.="        body:   'name  # comment why'\n";
$scrHelpTxt.="        header: '# include -1' \n";
$scrHelpTxt.="        body:   'name  # comment why'\n";
$scrHelpTxt.="        header: '# include -2' \n";
$scrHelpTxt.="        body:   'name  # comment why'\n";
$scrHelpTxt.="     -> HARD includ all after line '# include 1'\n";
$scrHelpTxt.="        then: all those with -1 , -2, ...\n";
$scrHelpTxt.="        That is: do cluster size within each class (1,-1,-2,...)\n";
$scrHelpTxt.="        this implies those with -1 even included if smaller family than\n";
$scrHelpTxt.="        those with -3! \n";
$scrHelpTxt.="     \n";
$scrHelpTxt.="     Note: the inclusion is hierarchical: first in file=higher priority\n";
$scrHelpTxt.="     \n";
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
#				version 0.1   	Aug,    	1998	       #
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

#-------------------------------------------------------------------------------
# do the job (here we go)
#-------------------------------------------------------------------------------
				# ------------------------------
				# global counters
				# ------------------------------
$ctId1=$ctId2=0;
				# pointers
undef %id1ptr; undef %id2ptr;	# $id1ptr{"$id"}= $ctId1    i.e. id to number
$#id1ptr=$#id2ptr=0;		# $id1ptr[$ctId1]=$id       i.e. number to id

				# data
$#len=0;			# $len[$ctId1] length of ctId1
$#res=0;			# $res[$ctId1] resolution of ctId1
$#num=0;			# $num[$ctId1] number of homologues to ctId1
undef $ra_family;		# $ra_family->[$ctId1] reference to @id2[1..$num[$ctId1]],
				#     i.e., all proteins homologous to ctId1
				#     note: $id2[it] gives the number referring to id2 
				#           id2=$id2ptr[$id2[it]]


				# ------------------------------
				# loop over all pairs: read
				# ------------------------------
foreach $fileIn (@fileIn) {
    print "--- read file $fileIn\n" if ($Lverb);
				# GLOBAL out: pointers %id12ptr,@id12ptr
				#             data     @len,@res,@num,$ra_family->[]
    ($Lok,$msg)=
	&filePairsRd($fileIn);  if (! $Lok) { print "*** ERROR $scrName: failed reading $fileIn\n";
					      exit; }
}
$nid1=$ctId1;

				# --------------------------------------------------
				# do the greedy optimisation
				# --------------------------------------------------
($Lok,$msg)=
    &greedy();                  if (! $Lok) { print "*** ERROR $scrName: failed greedy\n";
					      exit; }


($Lok,$msg)=
    &wrtDbgFin($fhTrace);       if (! $Lok) { print "*** ERROR $scrName: failed wrtDbgFin\n";
					      exit; }

				# ------------------------------
				# write output
				# ------------------------------
$fileOutOk="ok".$fileOut        if (! defined $fileOutOk);
&open_file("$fhout",">$fileOutOk"); 
foreach $idnum (1..$nid1) { next if (! defined $ok[$idnum] || ! $ok[$idnum]);
			    print $fhout $id1ptr[$idnum],"\n"; } close($fhout);
push(@fileOut,$fileOutOk)       if (-e $fileOutOk);

$fileOutNo="no".$fileOut        if (! defined $fileOutNo);
&open_file("$fhout",">$fileOutNo"); 
foreach $idnum (1..$nid1) { next if (! defined $ok[$idnum] || $ok[$idnum]);
			    print $fhout $id1ptr[$idnum],"\n"; } close($fhout);
push(@fileOut,$fileOutNo)       if (-e $fileOutNo);


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
    $Date=        &sysDate();

				# ------------------------------
				# HELP stuff
    %tmp=&iniHelp();
    ($Lok,$msg)=		# want help?
	&brIniHelpLoop($scrName,%tmp);   
                                return(&errSbrMsg("after lib-br:brIniHelpLoop",$msg,$SBR)) if (! $Lok);

    exit if ($msg =~/^fin/); 

				# ------------------------------
				# read command line input
    @argUnk=			# standard command line handler
	&brIniGetArg;
    foreach $arg (@argUnk){     # interpret specific command line arguments
	next if ($arg=~/^(dirLib|ARCH|PWD|packName)=/);
        if    ($arg=~/^list$/i)               { $par{"isList"}=1;}

	elsif ($arg=~/^nodis$/i)              { $par{"do_dis"}=0; }
	elsif ($arg=~/^nores$/i)              { $par{"do_res"}=0; }
	elsif ($arg=~/^nolen$/i)              { $par{"do_len"}=0; }
	elsif ($arg=~/^dis$/i)                { $par{"do_dis"}=1; }
	elsif ($arg=~/^res$/i)                { $par{"do_res"}=1; }
	elsif ($arg=~/^len$/i)                { $par{"do_len"}=1; }

	elsif ($arg=~/^verbDbg$/i)            { $par{"verbDbg"}=1; }
	elsif ($arg=~/^nice-(\d+)$/)          { $par{"optNice"}="nice -".$1;}
	elsif ($arg eq "nonice")              { $par{"optNice"}=" ";}
	elsif ($arg eq "debug")               { $par{"debug"}=1;}
	else  {
	    return(0,"*** ERROR $SBR: kwd '$arg' not understood\n");}}
    print "-*- WARNING iniGetArg: command line arguments overwrite '".$par{"fileDefaults"}."\n" 
	if ($par{"verbose"} && defined %defaults && %defaults);
        
				# ------------------------------
				# hierarchy of blabla
    $par{"verbose"}=1           if ($par{"verb2"});
	
    $Lverb= $par{"verbose"}     if (defined $par{"verbose"} && $par{"verbose"});
    $Lverb2=$par{"verb2"}       if (defined $par{"verb2"}   && $par{"verb2"});

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
				# process input files
    $#fileInTmp=0;
    foreach $fileIn (@fileIn) {
	$tmp=`head -1 $fileIn`; $tmp=~s/\n//;
				# file with ids to exclude
	if ($tmp=~/^\#\s*.*exclude/i) {
	    $par{"fileExcl"}=$fileIn; # for later references
	    next; }
				# file with ids to include
	if ($tmp=~/^\#\s*.*include/i) {
	    $par{"fileIncl"}=$fileIn; # for later references
	    next; }
				# all others: take
	push(@fileInTmp,$fileIn); }
    @fileIn=@fileInTmp;
				# ------------------------------
				# read include
    if (defined $par{"fileExcl"} && -e $par{"fileExcl"}) {
	($Lok,$msg,$rh_excl)=
	    &fileExclRd($par{"fileExcl"});
	return(&errSbrMsg("failed reading exclude file=".$par{"fileExcl"},$msg)) if (! $Lok); }
				# ------------------------------
				# read include
    if (defined $par{"fileIncl"} && -e $par{"fileIncl"}) {
				# OUT: rh_incl{$id}=level (1,-1,...)
	($Lok,$msg,$rh_incl)=
	    &fileInclRd($par{"fileIncl"});
	return(&errSbrMsg("failed reading include file=".$par{"fileIncl"},$msg)) if (! $Lok); }


				# ------------------------------
				# directories: add '/'
    foreach $kwd (keys %par) {
	next if ($kwd !~/^dir/);
	next if (length($par{"$kwd"})==0 || $par{"$kwd"} eq "unk" );
	$par{"$kwd"}.="/"       if ($par{"$kwd"} !~ /\/$/);}

				# ------------------------------
				# final settings
    $Lok=			# standard settings
	&brIniSet;              return(&errSbr("after lib:brIniSet\n")) if (! $Lok);
    return(0,"*** ERROR $SBR: no input file given!!\n") if ($#fileIn==0);

    if (! defined $fileOut || ! $fileOut || length($fileOut)<1){
	$fileOut=$par{"dirOut"}.$par{"title"}.$par{"extOut"};
	push(@fileOut,$fileOut);
    }

				# ------------------------------
				# check errors
    $exclude="exe,fileDefaults"; # to exclude from error check
    ($Lok,$msg)=
        &brIniErr($exclude);    return(&errSbrMsg("after lib:brIniErr\n".$msg)) if (! $Lok);  

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
    $fhTrace2=$fhTrace;
    $fhTrace2="STDOUT"          if ($Lverb2 || $par{"debug"});
    $#kwdRm=0;
				# ------------------------------
				# write settings
				# ------------------------------
    $exclude="kwd,dir*,ext*";	# keyword not to write
    $fhloc="STDOUT";
    $fhloc=$fhTrace             if (! $par{"debug"} && ! $par{"verb2"});
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
    $par{"title"}=              "UNIQUE";                        # output files may be called 'Pre-title.ext'
    $par{"titleTmp"}=           "TMP-UNIQUE";                    # title for temporary files

    $par{"fileOut"}=            "unk";
#    $par{"fileOutTrace"}=       $par{"titleTmp"}."TRACE"."jobid".".tmp";  # tracing some warnings and errors
#    $par{"fileOutScreen"}=      $par{"titleTmp"}."SCREEN"."jobid".".tmp"; # dumb out from system calls
    $par{"fileOutTrace"}=       $par{"titleTmp"}."TRACE". ".tmp";  # tracing some warnings and errors
    $par{"fileOutScreen"}=      $par{"titleTmp"}."SCREEN".".tmp"; # dumb out from system calls

    $par{"fileHelpMan"}=        "unk"; # file with manual
    $par{"fileHelpOpt"}=        "unk"; # file with options
    $par{"fileHelpHints"}=      "unk"; # file with hints, note: also passed as par{scrHelpHints}
    $par{"fileHelpProblems"}=   "unk"; # file with known problems, also passed as par{scrHelpProblems}
#    $par{""}=                   "";

    $par{"fileIncl"}=           "unk"; # file with proteins to include (header '# include')
    $par{"fileExcl"}=           "unk"; # file with proteins to include (header '# exclude')

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
    $par{"verbDbg"}=            0; # debug write

    $par{"optNice"}=            "nice -15";
#    $par{""}=                   "";
				# --------------------
				# parameters
    $par{"do_len"}=             1; # check for length of protein   
				   #     NOTE: must be column in file pairs
    $par{"do_res"}=             1; # check for resolution of protein
				   #     NOTE: must be column in file pairs
    $par{"do_dis"}=             1; # check for distance (if 0: all pairs in file taken!!)
				   #     NOTE: must be column in file pairs
    $par{"minDis"}=             0; # minimal distance from HSSP(new) curve (-3 -> at least 27%)
    $par{"minDis"}=             2; # minimal distance from HSSP(new) curve (-3 -> at least 27%)
    $par{"minRes"}=           2.5; # if resolution below this, do NOT replace bigger cluster
				   #    with higher resolution by smaller cluster and lower res!
				   #    
    $par{"minLen"}=            50; # if length above this, do NOT replace bigger cluster
				   #    with shorter protein by smaller cluster with longer protein
				   #    
				   #    

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
    $tmp=$0; $tmp=~s/^\.\/// if ($tmp=~/^\.\//);
    %tmp=('sourceFile', $tmp, 'scrName',$scrName, 'scrIn',$scrIn, 
	  'scrGoal', $scrGoal, 'scrNarg',$scrNarg,
	  'scrHelpTxt', $scrHelpTxt);
				# missing stuff
    $tmp=0;
    $tmp=$par{"packName"}       if (defined $par{"packName"});
    $tmp=$0                     if (! defined $tmp || ! $tmp); 
    %tmp=('sourceFile', $tmp, 'scrName',$scrName, 'scrIn',$scrIn, 'scrGoal', $scrGoal, 
	  'scrNarg',$scrNarg, 'scrHelpTxt', $scrHelpTxt);


    $tmp{"s_k_i_p"}=         "problems,manual,hints";

				# special help

    $tmp{"scrAddHelp"}=      "";
    $tmp{"special"}=         "nodis".",". "nores".",". "nolen".",";
    $tmp{"special"}.=        "dis".",".   "res".",".   "len".",";
    $tmp{"special"}.=        "verb".",". "verb2".",". "verbDbg".",";
    $tmp{"special"}.=        "".",". "".",". "".",";
        
    $tmp{"nodis"}=           "OR do_dis=0,   i.e. no check of distance";
    $tmp{"dis"}=             "OR do_dis=1,   i.e. do check of distance";
    $tmp{"nolen"}=           "OR do_len=0,   i.e. no check of length";
    $tmp{"len"}=             "OR do_len=1,   i.e. do check of length";
    $tmp{"nores"}=           "OR do_res=0,   i.e. no check of resolution";
    $tmp{"res"}=             "OR do_res=1,   i.e. do check of resolution";

    $tmp{"verbDbg"}=         "OR verbDbg=1,  detailed debug info (not automatic)";
#                            "------------------------------------------------------------\n";
    return(%tmp);
}				# end of iniHelpNet

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
	    print "--- $SBR unlink '",$file{"$kwd"},"'\n" if ($Lverb2);
	    unlink($file{"$kwd"});}}
    foreach $kwd ("fileOutTrace","fileOutScreen"){
        next if (! defined $par{"$kwd"} || ! -e $par{"$kwd"});
        print "--- $SBR unlink '",$par{"$kwd"},"'\n" if ($Lverb2);
        unlink($par{"$kwd"});}
}				# end of cleanUp

#===============================================================================
sub fileExclRd {
    local($fileInLoc) = @_ ;
    local($SBR,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   fileExclRd                  reads file with names to ex|include
#       in:                     $fileInLoc
#       out:                    1|0,msg,$rh_array->{id}=position
#                               i.e. the position (line number) of id in the file
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $SBR="$tmp"."fileExclRd";
    $fhinLoc="FHIN_"."fileExclRd";$fhoutLoc="FHIN_"."fileExclRd";
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
    return(&errSbr("miss in file '$fileInLoc'!"))  if (! -e $fileInLoc);
				# 
    undef %tmp;
				# open file
    &open_file("$fhinLoc","$fileInLoc") || return(&errSbr("fileInLoc=$fileInLoc, not opened"));
    $ct=0;			# ------------------------------
    while (<$fhinLoc>) {	# read file
				# skip comments
	next if ($_=~/^[\s\t]*\#/);
	$_=~s/\n//g;
	next if (length($_)==0); # skip empty
	++$ct;			# count ok lines
				# read only first column
	$_=~s/^(\S+)[\s\t]*.*$/$1/g;
	$id=$_;
	$tmp{$id}=$ct;
    } close($fhinLoc);
    return(1,"ok $SBR",\%tmp);
}				# end of fileExclRd

#===============================================================================
sub fileInclRd {
    local($fileInLoc) = @_ ;
    local($SBR,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   fileInclRd                  reads file with names to include
#                FORMAT:        
#                               # include 1
#                               # BLABLA
#                               idA     # comment
#                               idB     # comment
#                               # include -1 (after 1)
#                               # BLABLA
#                               idA     # comment
#                               idB     # comment
#                               # include -2 (after -1)
#                               # BLABLA
#                               idA     # comment
#                               idB     # comment
#
#       in:                     $fileInLoc
#       out:                    1|0,msg,$rh_level{id}= level of inclusion (1,0=exclude,-1,-2...)
#                  dormant      $rh_array->{id}=position (line number) of id in the file
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $SBR="$tmp"."fileInclRd";
    $fhinLoc="FHIN_"."fileInclRd";$fhoutLoc="FHIN_"."fileInclRd";
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
    return(&errSbr("miss in file '$fileInLoc'!"))  if (! -e $fileInLoc);
				# 
    undef %tmp;
				# open file
    &open_file("$fhinLoc","$fileInLoc") || return(&errSbr("fileInLoc=$fileInLoc, not opened"));
    $ct=0;			# 
    $level=1;			# default: if no level given: =1
				# ------------------------------
    while (<$fhinLoc>) {	# read file
	$_=~s/\n//g;
				# digest level
	if ($_=~/^\# incl[a-z]*[\s\t]+.*([\-\d]+)/){
	    $level=$1;
	    print "xx level =$level ($_)\n";
	    next;}
				# skip other comments
	next if ($_=~/^[\s\t]*\#/);
	next if (length($_)==0); # skip empty

	++$ct;			# count ok lines
	
	$_=~s/\#.*$//g;		# skip comments in line
				# read only first column
	$_=~s/^(\S+)[\s\t]*.*$/$1/g;
	$id=$_;
#	$tmp{$id}=$ct;		# hierarchy: first = higher priority
	$tmp{$id}=$level;	# level
    } close($fhinLoc);
    return(1,"ok $SBR",\%tmp);
}				# end of fileInclRd

#===============================================================================
sub filePairsRd {
    local($fileInLoc) = @_ ;
    local($SBR,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   filePairsRd                 read all the pair information
#       in:                     $fileInLoc
#       out GLOBAL:
#                   pointers                                   
#                               $id1ptr{"$id"}= $ctId1    i.e. id to number
#                               $id1ptr[$ctId1]=$id       i.e. number to id
#                       data                                                    
#                               $len[$ctId1] length of ctId1                            
#                               $res[$ctId1] resolution of ctId1                        
#                               $num[$ctId1] number of homologues to ctId1              
#                               $ra_family->[$ctId1] reference to @id2[1..$num[$ctId1]],
#                                   i.e., all proteins homologous to ctId1
#                                   note: $id2[it] gives the number referring to id2 
#                                         id2=$id2ptr[$id2[it]]
#                               
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $SBR="$tmp"."filePairsRd";
    $fhinLoc="FHIN_"."filePairsRd";$fhoutLoc="FHIN_"."filePairsRd";
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
    return(&errSbr("miss in file '$fileInLoc'!"))  if (! -e $fileInLoc);

    undef %ptr;
				# open file
    &open_file("$fhinLoc","$fileInLoc") || return(&errSbr("fileInLoc=$fileInLoc, not opened"));
				# --------------------------------------------------
    while (<$fhinLoc>) {	# read file
				# --------------------------------------------------
				# skip comments
	next if ($_=~/^[\s\t]*\#/);
	$_=~s/\n//g;
	next if (length($_)==0); # skip empty
				# ------------------------------
				# names
				# ------------------------------
	if ($_=~/^id/){ @tmp=split(/[\t\s]+/,$_); 
			foreach $tmp(@tmp){$tmp=~s/\s//g;} # purge blanks
			foreach $it (1..$#tmp){
			    if    ($tmp[$it]=~/^id1/){ $ptr{"id1"}=$it; }
			    elsif ($tmp[$it]=~/^id2/){ $ptr{"id2"}=$it; }
			    elsif ($tmp[$it]=~/^len/){ $ptr{"len"}=$it; }
			    elsif ($tmp[$it]=~/^res/){ $ptr{"res"}=$it; }
			    elsif ($tmp[$it]=~/^dis/){ $ptr{"dis"}=$it; } }
			next; }
				# ------------------------------
				# data
				# ------------------------------
	$rd=$_;
	@tmp=split(/[\t\s]+/,$_); 
	foreach $tmp(@tmp){$tmp=~s/\s//g;} # purge blanks

				# --------------------
				# get columns

	$id1=$tmp[$ptr{"id1"}];	# 1st name
	return(&errSbr("filePairs=$fileInLoc, no id1 line=",$rd,"\n")) if (! defined $id1);

				# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
				# skip if id1 to exclude
	next if (defined $rh_excl->{"$id1"});
				# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

				# 2nd name (list)
	undef $id2List;		# (may be empty)
	$id2List=$tmp[$ptr{"id2"}];

	if ($par{"do_len"}){	# length
	    $len=$tmp[$ptr{"len"}];
	    return(&errSbr("filePairs=$fileInLoc, no len line=",$rd,"\n")) if (! defined $len);}
	if ($par{"do_res"}){	# resolution
	    $res=$tmp[$ptr{"res"}];
	    return(&errSbr("filePairs=$fileInLoc, no res line=",$rd,"\n")) if (! defined $res);}
	if ($par{"do_dis"}){	# distance from threshold
	    undef $disList;	# (may be empty)
	    $disList=$tmp[$ptr{"dis"}]; }

				# --------------------
				# build up arrays
	if (! defined $id1ptr{"$id1"}){
	    ++$ctId1;
	    $id1ptr{"$id1"}=$ctId1; # pointer: id to number
	    $id1ptr[$ctId1]=$id1;   # pointer: number to id
	    $len[$ctId1]=$len   if ($par{"do_len"});
	    $res[$ctId1]=$res   if ($par{"do_res"}); }

				# --------------------
				# now: go through list
	$#tmp_id2=$#tmp_dis=$#tmp_ok=0;
	if (defined $id2List){
	    $id2List=~s/,*$//g; @tmp_id2=split(/,/,$id2List); }
	if ($par{"do_dis"} && defined $disList){
	    $disList=~s/,*$//g; @tmp_dis=split(/,/,$disList); }
	foreach $it (1..$#tmp_id2) {
	    $id2=$tmp_id2[$it];
				# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
				# skip if id2 to exclude
	    next if (defined $rh_excl->{"$id2"});
				# check for distance
	    if ($par{"do_dis"}){
		$dis=$tmp_dis[$it];
		exit if (! defined $dis);
				# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
				# skip if too far away
		next if ($dis < $par{"minDis"}); }
				# --------------------
				# build up array for 2
	    if (! defined $id2ptr{"$id2"}) {
		++$ctId2;
		$id2ptr{"$id2"}=$ctId2; # pointer: id to number
		$id2ptr[$ctId2]=$id2; }	# pointer: number to id
	    push(@tmp_ok,$id2ptr{"$id2"}); }

				# ******************************
				# the real big data comes!!!
	my @tmp=@tmp_ok;
	$num[$ctId1]=$#tmp_ok;
	$ra_family[$ctId1]=\@tmp;
				# ******************************

    } close($fhinLoc);
    return(1,"ok $SBR");
}				# end of filePairsRd

#===============================================================================
sub greedy {
#    local($fileInLoc,$fhErrSbr) = @_ ;
    my($SBR,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   greedy                      does the greedy search for largest subset
#       Hierarchy: (1) biggest clusters
#                  (2) 
#                  (2) 
#                  (2) 
#       in/out GLOBAL:          all
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $SBR="$tmp"."greedy";$fhinLoc="FHIN_"."greedy";$fhoutLoc="FHIN_"."greedy";

				# set 0
    $#sort=0;			# $sort[1]=$idnum -> take idnum first
    $#ok=0;			# $ok[$idnum]     -> idnum already in @sort

				# ------------------------------
				# (1) explicitly include hierarcy
				#     out/in GLOBAL: @sort, @ok
				# ------------------------------

				# xx 
				# xx watch for label 1 !
				# xx 
    ($Lok,$msg)=
	&greedy_inclHierarchy(); return(&errSbrMsg("failed on explicit include",
						  $msg,$SBR)) if (! $Lok);
				# ------------------------------
				# (2) sorting by family size
				#     out/in GLOBAL: @sort, @ok
				# ------------------------------

				# xx 
				# xx loop over labels:
				# xx hierarchy -1, -2, -3 (for ok,nmr,no)
				# xx 
    ($Lok,$msg)=
	&greedy_sortFamilySize();return(&errSbrMsg("failed on explicit include",
						  $msg,$SBR)) if (! $Lok);

				# all there?
    ($Lok,$msg)=
	&greedy_sortAllThere(); return(&errSbrMsg("not all there after family size!",
						  $msg,$SBR)) if (! $Lok);

				# ------------------------------
				# start all over again
    $#ok=0;			# $ok[$idnum]     -> idnum already in @sort
    
				# ------------------------------
				# finally do the stuff
				# ------------------------------

    ($Lok,$msg)=
	&greedy_do1();          return(&errSbrMsg("failed on do_it_1",$msg,$SBR)) if (! $Lok);


    ($Lok,$msg)=
	&wrtDbgFin($fhTrace2);  return(&errSbrMsg("failed on wrtDbgFin 1",$msg,$SBR)) if (! $Lok);

    ($Lok,$msg)=
	&greedy_check1("STDOUT");  return(&errSbrMsg("failed on check_1",$msg,$SBR)) if (! $Lok);


				# xx
    return(1,"ok $SBR");

				# xx

				# ------------------------------
				# 
				# ------------------------------

#    ($Lok,$msg)=&xx(); return(&errSbrMsg("failed on ",$msg,$SBR)) if (! $Lok);
	

				# ------------------------------
				# 
				# ------------------------------

    return(1,"ok $SBR");
}				# end of greedy

#===============================================================================
sub greedy_check1 {
    my($fhSbr) = @_ ;
    my($SBR,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   greedy_check1               checks whether all ok after do1
#       in/out GLOBAL:          all
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $SBR="$tmp"."greedy_check1";$dbg=$SBR;$dbg=~s/$tmp//g;
    $fhinLoc="FHIN_"."greedy_check1";$fhoutLoc="FHIN_"."greedy_check1";


				# --------------------------------------------------
				# loop over all proteins:
				#    largest clusters (or explicitly include) first
				# --------------------------------------------------

    $errWrt=$warnWrt="";

    foreach $idnum (1..$nid1){
	next if (! $ok[$idnum]);

	foreach $it (1..$num[$idnum]) {
	    $id2num=$ra_family[$idnum]->[$it];
	    $id2=$id2ptr[$id2num];
				# not in list of ID1 -> ignore
	    next if (! defined $id1ptr{"$id2"});
				# pointer of id1 corresponding to homologue
	    $idnumFrom2=$id1ptr{"$id2"};
				# already treated!
	    next if (! $ok[$idnumFrom2]);
	    $id1=$id1ptr[$idnum];
				# different threshold here?
	    if ($par{"do_dis"}) {
		$warnWrt.= sprintf("-*- WARN check1: 1=%-6s (%5d) 2=%-6s (%5d) both ok dis??\n",
				   $id1,$idnum,$id2,$idnumFrom2);
		next; }
				# ******************************
				# ERROR overlap but twice ok!
				# ******************************
	    $errWrt.=      sprintf("*** check1: id1=%-6s (%5d) id2=%-6s (%5d) both ok!\n",
				   $id1,$idnum,$id2,$idnumFrom2);
	}
    }
    print $errWrt               if (length($errWrt)>1);	# xx

    print $fhSbr $warnWrt       if (length($warnWrt)>1);
    return(0,$errWrt)           if (length($errWrt)>1);
    return(1,"ok $SBR");
}				# end of greedy_check1

#===============================================================================
sub greedy_do1 {
#    local($fileInLoc,$fhErrSbr) = @_ ;
    my($SBR,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   greedy_do1                     
#       in/out GLOBAL:          all
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $SBR="$tmp"."greedy_do1";    $dbg=$SBR;$dbg=~s/$tmp//g;
    $fhinLoc="FHIN_"."greedy_do1";$fhoutLoc="FHIN_"."greedy_do1";

    $len=$lenBest=0;
    $res=$resBest=0;
				# --------------------------------------------------
				# loop over all proteins:
				#    largest clusters (or explicitly include) first
				# --------------------------------------------------
    
    print "--- dbg $dbg: \n"                                   if ($par{"verbDbg"});
    foreach $idnum (@sort) {
				# ------------------------------
	$tmpWrt="";		# already taken: ERASE all homos!
	if (defined $ok[$idnum]) {
	    &ass1_eraseAll(0);	# also writes  to debug
	    next; }
				# ------------------------------
				# no homologues
	if (! $num[$idnum]) {
#	    print "--- dbg $dbg: take it, none to ERASE\n"     if ($par{"verbDbg"});
				# <<<<<<<<<< + + + + + + + + + +
	    $ok[$idnum]=1;	# TAKE id1
	    next; }		# <<<<<<<<<< + + + + + + + + + +

				# ------------------------------
				# any homologue taken?
	$num= &ass1_oneAlready();
	if ($num) {
	    &ass1_eraseAll($num);
				# <<<<<<<<<< - - - - - - - - - -
	    $ok[$idnum]=0;	# ERASE id1
	    next; }

				# ------------------------------
				# check length and other features
				# ------------------------------
	print 
	    "--- ","-" x 60,"\n","--- dbg $dbg: working on idnum=$idnum, id1=",
	    $id1ptr[$idnum],"\n"                               if ($par{"verbDbg"});

	$len=$len[$idnum]       if ($par{"do_res"} && $len[$idnum] < $par{"minLen"});
	$res=$res[$idnum]       if ($par{"do_res"} && $res[$idnum] > $par{"minRes"});
	$lenBest=$len; $resBest=$res;  $lenBestPos=$resBestPos=$best=0;
	$#tmp=0;		# will hold the numbers (id2num) to re-consider in 
				#    round (2)

				# ------------------------------
				# round (1) get length + res for 
				#           all homologues to this protein
				# ------------------------------
	foreach $it (1..$num[$idnum]) {
	    $id2num=$ra_family[$idnum]->[$it];
	    $id2=$id2ptr[$id2num];
				# not in list of ID1 -> ignore
	    next if (! defined $id1ptr{"$id2"});
	    print "--- dbg $dbg: round 1 it=$it id2=$id2,\n"   if ($par{"verbDbg"});
				# pointer of id1 corresponding to homologue
	    $idnumFrom2=$id1ptr{"$id2"};
				# already treated!
	    next if (defined $ok[$idnumFrom2]);

	    $len2=$res2=$len2ok=$len2ok=0;
				# id2 better res     -> see round 2
	    if ($res && 
		($res[$idnumFrom2] < $par{"minRes"} || $res[$idnumFrom2] < $res )){
		$res2=  $res[$idnumFrom2]; }
				# id2 longer         -> see round 2
	    if ($len && $len[$idnumFrom2] > $par{"minLen"}){
		$len2=  $len[$idnumFrom2]; 
				# only if res ok
		$len2ok=1 if (($res && $res2) || ! $par{"do_res"} || 
			      ($par{"do_res"} && $res[$idnumFrom2] < $par{"minRes"})); }
	    if ($res2 || $len2ok){
		print "--- dbg $dbg: round 1 GOOD len2=$len2 res2=$res2 ($idnumFrom2)\n" 
		    if ($par{"verbDbg"});
		if ($len2 > $lenBest) { $lenBest=$len2; $lenBestPos=$idnumFrom2;}
		if ($res2 < $resBest) { $resBest=$res2; $resBestPos=$idnumFrom2;}
		push(@tmp,$idnumFrom2);
		next ; }
	    print "--- dbg $dbg: round 1 ERASEn=$idnumFrom2\n" if ($par{"verbDbg"});
				# <<<<<<<<<< - - - - - - - - - -
	    $ok[$idnumFrom2]=0; }	# ERASE id2 !!

				# ******************************
	if ($#tmp==0){		# no round (2) !!
	    print "--- dbg $dbg: round 2 none Good, take=$idnum\n" if ($par{"verbDbg"});
				# <<<<<<<<<< + + + + + + + + + +
	    $ok[$idnum]=1;	# TAKE id1
				# <<<<<<<<<< + + + + + + + + + +
	    next; }

				# ------------------------------
				# round (2) get the best resolved, 
				#           longest homologue, instead!
				# ------------------------------
				# hierarchy of best
	if    (  $resBestPos && ! $lenBestPos) { # simple 1: best = highest resolution
	    $best=$resBestPos; }
	elsif (! $resBestPos &&   $lenBestPos) { # simple 2: best = longest
	    $best=$lenBestPos; }
	elsif (  $resBestPos &&   $lenBestPos) { # decision: best = highest resolution
	    $best=$resBestPos; }
	    
	foreach $idnumFrom2 (@tmp) {
	    next if ($idnumFrom2 == $best);
	    print "--- dbg $dbg: round 2 ERASE=$idnumFrom2\n"  if ($par{"verbDbg"});
				# <<<<<<<<<< - - - - - - - - - -
	    $ok[$idnumFrom2]=0;	# ERASE id2 !!
	}

				# ------------------------------
				# DECLARE final winner
	if (! $best){		# <<<<<<<<<< + + + + + + + + + +
	    $ok[$idnum]=1;	# TAKE id1
	    next; }
				# ERASE original (with larger family)
				# <<<<<<<<<< + + + + + + + + + +
	$ok[$best]=1;		# TAKE id2                 !!!!! 

				# <<<<<<<<<< - - - - - - - - - -
	$ok[$idnum]=0;		# ERASE id1           !!!!!!!!!!

	print "--- dbg $dbg: round 3 take 2=$idnumFrom2 !!\n"  if ($par{"verbDbg"});
	print "--- dbg $dbg: round 3 ERASE1=$idnum   !!!!!\n"  if ($par{"verbDbg"});
    }

    return(1,"ok $SBR");
}				# end of greedy_do1

#===============================================================================
sub ass1_eraseAll {
    local($idnumFrom2_excl) = @_ ;
    my($SBR,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   ass1_eraseAll               erase all homologues
#       in:                     $idnumFrom2 = 0 -> really all
#                                           = N -> all except for N!
#       in/out GLOBAL:          all
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $SBR="$tmp"."ass1_eraseAll";

    $tmpWrt="";
    
    foreach $it (1..$num[$idnum]) {
	$id2num=$ra_family[$idnum]->[$it];
	$id2=$id2ptr[$id2num];
				# not in list of ID1 -> ignore
	next if (! defined $id1ptr{"$id2"});
				# pointer of id1 corresponding to homologue
	$idnumFrom2=$id1ptr{"$id2"};
				# already treated!
	next if (defined $ok[$idnumFrom2]);
	next if ($idnumFrom2_excl && $idnumFrom2 == $idnumFrom2_excl);
	$tmpWrt.="$idnumFrom2,"                            if ($par{"verbDbg"});
				# <<<<<<<<<< - - - - - - - - - -
	$ok[$idnumFrom2]=0;	# ERASE id2 !!
    }
				# debug write
    if ($par{"verbDbg"} && length($tmpWrt) > 0) {
	print 
	    "--- ","-" x 60,"\n",
	    "--- dbg $dbg: working on idnum=$idnum, id1=",$id1ptr[$idnum],"\n";
	print "--- dbg $dbg: $idnum already ok=$ok[$idnum] -> ERASE all: $tmpWrt\n"
	    if (! $idnumFrom2_excl);
	print "--- dbg $dbg: ERASE all (except $idnumFrom2_excl):$tmpWrt,$idnum\n"
	    if ($idnumFrom2_excl); }
}				# end of ass1_eraseAll

#===============================================================================
sub ass1_oneAlready {
#    local($fileInLoc,$fhErrSbr) = @_ ;
    my($SBR,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   ass1_oneAlready             erase all homologues
#       in/out GLOBAL:          all
#       out:                    idnumFrom2 of the one already ok
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $SBR="$tmp"."ass1_oneAlready";

    foreach $it (1..$num[$idnum]) {
	$id2num=$ra_family[$idnum]->[$it];
	$id2=$id2ptr[$id2num];
				# not in list of ID1 -> ignore
	next if (! defined $id1ptr{"$id2"});
				# pointer of id1 corresponding to homologue
	$idnumFrom2=$id1ptr{"$id2"};
				# already treated!
	if (defined $ok[$idnumFrom2] && $ok[$idnumFrom2]) {
	    $tmpWrt.="$idnumFrom2,"                        if ($par{"verbDbg"});
	    return($idnumFrom2); }}
    return(0);
}				# end of ass1_oneAlready

#===============================================================================
sub greedy_inclHierarchy {
#    local($fileInLoc,$fhErrSbr) = @_ ;
    my($SBR,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   greedy_inclHierarchy        marks all those to be explicitly included
#       in/out GLOBAL:          all
#       out GLOBAL:             @sort[1] = idnum : idnumber (id1) of protein
#                                    to take first
#                               @ok[$idnum]=1    : if idnum added to array sortSize
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $SBR="$tmp"."greedy_inclHierarchy";
    foreach $idnum (1..$nid1) {
	$id1=$id1ptr[$idnum];
	next if (! defined $rh_incl->{"$id1"});
	push(@sort,$idnum); 
	$ok[$idnum]=1; }

    return(1,"ok $SBR");
}				# end of greedy_inclHierarchy

#===============================================================================
sub greedy_sortAllThere {
#    local($fileInLoc,$fhErrSbr) = @_ ;
    my($SBR,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   greedy_sortAllThere                     
#       in/out GLOBAL:          all
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $SBR="$tmp"."greedy_sortAllThere";
    $fhinLoc="FHIN_"."greedy_sortAllThere";$fhoutLoc="FHIN_"."greedy_sortAllThere";

    return(1,"ok $SBR") if ($#sort == $#ok && $#sort == $nid1);

    if ($#sort != $#ok) {
	$errWrt="ARRAY_sort not same number (".$#sort.") as ARRAY_ok (".$#ok.")\n";}
    else {
	$errWrt="ARRAY_sort not all proteins (".$#sort."), want=$nid1\n";}
	
    foreach $idnum (1..$nid1) {
	next if ($ok[$idnum]);
	$errWrt.="missing idnum=$idnum, id=".$id1ptr[$idnum].",\n"; }
    return(0,$errWrt);
}				# end of greedy_sortAllThere

#===============================================================================
sub greedy_sortFamilySize {
#    local($fileInLoc,$fhErrSbr) = @_ ;
    my($SBR,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   greedy_sortFamilySize       sorts those not included so far by family size
#       in/out GLOBAL:          all
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $SBR="$tmp"."greedy_sortFamilySize"; $dbg=$SBR;$dbg=~s/$tmp//g;
    $fhinLoc="FHIN_"."greedy_sortFamilySize";$fhoutLoc="FHIN_"."greedy_sortFamilySize";

    $#size=0;			# just the family size (uniq numbers)
    $#ptr=0;			# for $size[it]=N, $ptr[N]=number_of_proteins_with_size_N
				#                  $ptr[N][mue]=idnum, the mue-th element 
				#                      from protein idnum
    $#ptrlist=0;

				# ------------------------------
				# get family sizes for all ids
				# ------------------------------
    foreach $idnum (1..$nid1) {
	$num=$num[$idnum]; 
	$numArray=$num+1;	# num may be zero -> for array count +1
	print $fhTrace "--- dbg $dbg: \t idnum=$idnum, num=$num,\n" 
	    if ($par{"verbDbg"});
	if (! defined $ptr[$numArray]){
	    push(@size,$num);
	    $ptr[$numArray]=1; $tmp=1;
	    $ptrlist[$numArray][$tmp]=$idnum;}
	else {
	    ++$ptr[$numArray]; $tmp=$ptr[$numArray]; 
	    $ptrlist[$numArray][$tmp]=$idnum; } }

				# ------------------------------
				# sort family sizes
				# ------------------------------
    @size=sort bynumber_high2low (@size);
    print $fhTrace "--- ","-" x 60,"\n","--- dbg $dbg: sizes sorted:",join(',',@size,"\n") 
	if ($par{"verbDbg"});

				# ------------------------------
				# get family succession
				# ------------------------------
    foreach $size (@size) {
	$index=$size+1;
	$num=$ptr[$index];
	print $fhTrace "--- dbg $dbg: on size=$size num=$num:" if ($par{"verbDbg"});
	    
				# for all proteins of that size
	foreach $it (1..$num){
	    
	    $idnum=$ptrlist[$index][$it];
				# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
				# skip if already in @sort
	    next if (defined $ok[$idnum]);
	    print $fhTrace "$idnum,"                            if ($par{"verbDbg"});
	    push(@sort,$idnum);
	    $ok[$idnum]=1; } 
	print $fhTrace "\n"                                     if ($par{"verbDbg"});
    }

    undef @size; undef @ptr;	# slim-is-in

    return(1,"ok $SBR");
}				# end of greedy_sortFamilySize


#===============================================================================
sub subx {
#    local($fileInLoc,$fhErrSbr) = @_ ;
    my($SBR,$fhinLoc,$fhoutLoc,$tmp,$Lok);
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
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
#    return(&errSbr("not def !"))          if (! defined $);

    return(&errSbr("miss in file '$fileInLoc'!"))  if (! -e $fileInLoc);
				# open file
    &open_file("$fhinLoc","$fileInLoc") || return(&errSbr("fileInLoc=$fileInLoc, not opened"));
    &open_file("$fhoutLoc",">$fileOutLoc") || return(&errSbr("fileOutLoc=$fileOutLoc, not created"));
				# ------------------------------
    while (<$fhinLoc>) {	# read file
				# skip comments
	next if ($_=~/^[\s\t]*\#/);
	$_=~s/\n//g;
	next if (length($_)==0); # skip empty

    } close($fhinLoc);
    return(1,"ok $SBR");
}				# end of subx

#===============================================================================
sub subxloc {
#    local($fileInLoc,$fhErrSbr) = @_ ;
    my($SBR,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   subxloc                     
#       in/out GLOBAL:          all
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $SBR="$tmp"."subxloc";
    $fhinLoc="FHIN_"."subxloc";$fhoutLoc="FHIN_"."subxloc";

    return(1,"ok $SBR");
}				# end of subxloc

#===============================================================================
sub wrtDbgFin {
    my($fhSbr) = @_ ;
    my($SBR,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   wrtDbgFin                   debug write of final stuff
#       in/out GLOBAL:          all
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $SBR="$tmp"."wrtDbgFin";$dbg=$SBR;$dbg=~s/$tmp//g;
    $fhinLoc="FHIN_"."wrtDbgFin";$fhoutLoc="FHIN_"."wrtDbgFin";

				# ------------------------------
				# all ok
				# ------------------------------
    foreach $idnum (1..$nid1){
	next if (! defined $ok[$idnum] || ! $ok[$idnum]);
	printf $fhSbr "--- dbg: ok  %-6s %5d\n",$id1ptr[$idnum],$idnum; }

    foreach $idnum (1..$nid1){
	next if (! defined $ok[$idnum] || $ok[$idnum]);
	printf $fhSbr "--- dbg: not %-6s %5d\n",$id1ptr[$idnum],$idnum; }

    foreach $idnum (1..$nid1){
	next if (defined $ok[$idnum]);
	printf $fhSbr "--- dbg: ERR %-6s %5d\n",$id1ptr[$idnum],$idnum; }

    return(1,"ok $SBR");
}				# end of wrtDbgFin

