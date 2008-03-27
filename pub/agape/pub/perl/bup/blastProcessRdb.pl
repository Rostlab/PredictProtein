#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0; $scrName=~s/^.*\/|\.pl//g;
$scrGoal=    "read BLAST.rdb and spits out list of uniq id1 and uniq id2, list of pairs asf";
$scrIn=      "*blastRdb";
$scrNarg=    1;                  # minimal number of input arguments
$scrHelpTxt= "(1) just extracts two lists of unique_id1 + unique_id2 \n";
$scrHelpTxt.="    from BLAST.rdb (id1,id2,lali,pide,dist)\n";
$scrHelpTxt.="(2) writes list of pairs for 'uniqueList.pl'\n";
$scrHelpTxt.="    \n";
$scrHelpTxt.="    \n";
$scrHelpTxt.="(3) mirrors the RDB file adding length (kwd=len) and resolution (kwd=pdb)\n";
$scrHelpTxt.="    and excludes self (kwd=noself)\n";
$scrHelpTxt.="    \n";
$scrHelpTxt.="NOTE: input file expected to have column: id1,id2,lali,pide,dist \n";
$scrHelpTxt.="      change \$ptr\{\} in iniDef to adopt to other files!\n";
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

				# ------------------------------
($Lok,$msg)=			# initialise variables
    &ini;			# 
if (! $Lok) { print "*** ERROR $scrName after ini\n",$msg,"\n";
	      die '*** during initialising $scrName   ';}

				# ------------------------------
				# variables
				# ------------------------------

$wrt1=$wrt2="";
undef %id1; undef %id2; undef %pairs;
$#id1All=$#id2All=$#pairs=0;
$#fin=0; $nprot=0;		# final rdb for option: mirror 
				#    protein mue, column it (see %ptr defined in iniDef)
				#    $fin[$mue][$it] mue=1..nprot
$#ptr_this2fin=0;		#    $ptr_this2fin[$itrow]=$mue for particular file the
				#        row $itrow points to the final counting (@fin) mue
undef %finRes;			# final resolution $finRes{"$id1"}
undef %finLen;			# final length $finRes{"$id1"}
$#finDist=0;			# final distances $finDist[$mue]
$#finTake=0;			# final : take or not?

				# --------------------------------------------------
				# process file(s)
				# --------------------------------------------------
foreach $fileIn (@fileIn){
    if (! -e $fileIn){print "-*- WARN $scrName: no fileIn=$fileIn\n";
		      next;}
    print "--- $scrName: working on '$fileIn'\n" if ($par{"verbose"});
				# out GLOBAL: $rd[itrow][itcol]
				#             $ncol, $nrow
    ($Lok,$msg)=&fileRdLoc($fileIn);
    if (! $Lok) { print "*** ERROR $scrName: failed on reading $fileIn\n",$msg,"\n";
		  exit; }
				# in  GLOBAL: $rd[itrow][itcol], $ncol, $nrow, %par
				# out GLOBAL: $Ltake[1..$nrow]
    ($Lok,$msg)=&filterLoc();
    if (! $Lok) { print "*** ERROR $scrName: failed on filtering $fileIn\n",$msg,"\n";
		  exit; }
				# ------------------------------
				# get lists of unique identifiers
    				#     to take (write)
				# in  GLOBAL: $rd[itrow][itcol], $ncol, $nrow, $Ltake[1..$nrow]
				# out GLOBAL: $id1[1..$nrow], $id2[1..$nrow], 
    ($Lok,$msg)=&uniqIdLoc();
    if (! $Lok) { print "*** ERROR $scrName: failed on getting list of ids $fileIn\n",$msg,"\n";
		  exit; }
				# write uniq ids
#    $wrt1.=    "# $fileIn\n";
    foreach $id1 (@id1) {
	$wrt1.="$id1\n"; }
#    $wrt2.=    "# $fileIn\n";
    foreach $id2 (@id2) {
	$wrt2.="$id2\n"; }
    printf "--- stat: unique id1=%5d id2=%5d\n",$#id1,$#id2 if ($par{"verbose"});
    push(@id1All,@id1); push(@id2All,@id2); 

    next if (! $par{"doPairs"});
				# ------------------------------
				# do pairs
				# in  GLOBAL:             @Ltake, @rd, @dist, $nrow, %ptr, $resMax
				# out GLOBAL:             $pairs{$id1,"res"}= resolution of id1
				# out GLOBAL:             $pairs{$id1,"len"}= length of id1            
				# out GLOBAL:             $pairs{$id1}=       "a, b, c"                
				# out GLOBAL:             $pairs{$id1,"dist"}="Da,Db,Dc"               
				# out GLOBAL:             @pairs=           array of all uniq first ids
    ($Lok,$msg)=&getPairsLoc();
    if (! $Lok) { print "*** ERROR $scrName: failed on getting pairs for $fileIn\n",$msg,"\n";
		  exit; }
}
				# ------------------------------
				# (3) write output
				# ------------------------------
&open_file("$fhout",">$fileOutId1"); 
print $fhout $wrt1;
close($fhout);

&open_file("$fhout",">$fileOutId2"); 
print $fhout $wrt2;
close($fhout);

($Lok,$msg)=
    &wrtPairsLoc($fileOutPairs);
if (! $Lok){ print "*** ERROR $scrName: failed writing pairs to $fileOutPairs\n",$msg,"\n";}

($Lok,$msg)=
    &wrtMirrorLoc($fileOutMirror);
if (! $Lok){ print "*** ERROR $scrName: failed writing mirror to $fileOutMirror\n",$msg,"\n";}

if ($par{"verbose"}) { 
    print "--- $scrName ended fine .. -:\)\n";

    $timeEnd=time; # runtime , run time
    $timeRun=$timeEnd-$timeBeg;
    print 
	"--- date     \t \t $Date \n",
	"--- run time \t \t ",&fctSeconds2time($timeRun)," (hour:min:sec)\n";

    printf "--- output id1 (%5d) in %-s\n",$#id1All,$fileOutId1    if (-e $fileOutId1);
    printf "---        id2 (%5d) in %-s\n",$#id2All,$fileOutId2    if (-e $fileOutId2); 
    printf "---      pairs (%5d) in %-s\n",$#pairs, $fileOutPairs  if (-e $fileOutPairs); 
    printf "---     mirror (%5d) in %-s\n",$nprot,  $fileOutMirror if (-e $fileOutMirror); 
}
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
	next if ($arg=~/^(dirLib|PWD)=/);
	if    ($arg=~/^fileOutId1=(.*)$/)     { $fileOutId1=$1;}
	elsif ($arg=~/^fileOutId2=(.*)$/)     { $fileOutId2=$1;}
	elsif ($arg=~/^fileOutPairs=(.*)$/)   { $fileOutPairs=$1;}
#    elsif ($arg=~/^=(.*)$/){ $=$1;}
	elsif ($arg=~/^(noself|skip)$/i)      { $par{"allowSelf"}=0; }
	elsif ($arg=~/^filter$/)              { $par{"doThresh"}=   1; }
	elsif ($arg=~/^nofil\w*$/)            { $par{"doThresh"}=   0; }
	elsif ($arg=~/^doThresh$/)            { $par{"doThresh"}=   1; }
	elsif ($arg=~/^pairs?$/)              { $par{"doPairs"}=1;}
	elsif ($arg=~/^doPairs$/i)            { $par{"doPairs"}=1;}
	elsif ($arg=~/^pdb$/i)                { $par{"doPairs"}=1;
						$par{"doCheckRes"}=1; }
	elsif ($arg=~/^mirror?$/)             { $par{"doMirror"}=1;}
	elsif ($arg eq "debug")               { $par{"debug"}=1;}
	else  {
	    return(0,"*** ERROR $SBR: kwd '$arg' not understood\n");}}
        
				# ------------------------------
				# hierarchy of blabla
    $par{"verb2"}=1             if ($par{"debug"});
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
	&brIniSet;              return(&errSbr("after lib:brIniSet\n")) if (! $Lok);
    return(0,"*** ERROR $SBR: no input file given!!\n") if ($#fileIn==0);
				# output files
    if (! defined $fileOut || ! $fileOut || length($fileOut)<1){
	$fileOut= $par{"dirOut"}.$par{"title"}."-xyz".  $par{"extOut"};}

				# list id1
    if    (! defined $fileOutId1 && $#fileIn>1){
	if ($fileOut=~/xyz/) { $fileOutId1=$fileOut; $fileOutId1=~s/xyz/id1/; }
	else                 { $fileOutId1="Outid1-".$fileOut;}}
    elsif (! defined $fileOutId1){
	$tmp=$fileIn[1];$tmp=~s/^.*\/|\..*$//g;$tmp.=".tmp"; 
	$fileOutId1="Outid1-".$tmp;}
				# list id1
    if    (! defined $fileOutId2 && $#fileIn>1){
	if ($fileOut=~/xyz/) { $fileOutId2=$fileOut; $fileOutId2=~s/xyz/id2/; }
	else                 { $fileOutId2="Outid2-".$fileOut;}}
    elsif (! defined $fileOutId2){
	$tmp=$fileIn[1];$tmp=~s/^.*\/|\..*$//g;$tmp.=".tmp"; 
	$fileOutId2="Outid2-".$tmp;}
				# pairs
    if    (! defined $fileOutPairs && $#fileIn>1){
	if ($fileOut=~/xyz/) { $fileOutPairs=$fileOut; $fileOutPairs=~s/xyz/pairs/; }
	else                 { $fileOutPairs="Outpairs-".$fileOut;}}
    elsif (! defined $fileOutPairs){
	$tmp=$fileIn[1];$tmp=~s/^.*\/|\..*$//g;$tmp.=".tmp"; 
	$fileOutPairs="Outpairs-".$tmp;}
				# mirror
    if    (! defined $fileOutMirror && $#fileIn>1){
	if ($fileOut=~/xyz/) { $fileOutMirror=$fileOut; $fileOutMirror=~s/xyz/mirror/; }
	else                 { $fileOutMirror="Outmirror-".$fileOut;}}
    elsif (! defined $fileOutMirror){
	$tmp=$fileIn[1];$tmp=~s/^.*\/|\..*$//g;$tmp.=".tmp"; 
	$fileOutMirror="Outmirror-".$tmp;}

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
        print "--- \t open $fhTrace for trace file ",$par{"fileOutTrace"}," \n"  if ($par{"verb2"});
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
                                # d.d
				# --------------------
				# directories
    $par{"dirHome"}=            "/home/rost/";
    $par{"dirPerl"}=            $par{"dirHome"}. "perl/" # perl libraries
        if (! defined $par{"dirPerl"});
    $par{"dirData"}=            "/home/rost/data/";

    $par{"dirPerlScr"}=         $par{"dirPerl"}. "scr/"; # perl scripts needed

    $par{"dirOut"}=             ""; # directory for output files
    $par{"dirWork"}=            ""; # working directory
#    $par{""}=                   "";

    $par{"dirDataPdb"}=         "/home/rost/data/pdb/";        # for grepping resolution
    $par{"dirDataOrigin"}=      "/home/rost/data/hsspFasta/";  # directory of files which were 
				                               #    originially run by BLAST
                                # further on work
				# --------------------
				# files
    $par{"title"}=              "POST-BLAST";                    # output files may be called 'Pre-title.ext'
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
    $par{"extOut"}=             ".dat";

    $par{"extPdb"}=             ".brk";
    $par{"extOrigin"}=          ".f";

    $par{"doThresh"}=           1; # if 1: extract BLAST hits according to HSSP threshold
    $par{"minLali"}=           30; # minimal alignment length to consider hit
    $par{"minDist"}=            3; # minimal distance from HSSP(new) curve (-3 -> at least 27%)
    $par{"modeFilter"}=         "old"; # filter according to old or new ide


    $par{"minDist"}=           -2; # minimal distance from HSSP(new) curve (-3 -> at least 27%)
    $par{"modeFilter"}=         "new"; # filter according to old or new ide

    $par{"doMirror"}=           0; # mirrors the same RDB file, applying filter/noself asf,
				   #    (and adding resolution/length for doPairs)
    $par{"doPairs"}=            0; # write list of pairs
    $par{"doCheckRes"}=         0; # check resolution for PDB
    $par{"resMax"}=          1107; # to put for resolution if none found

    $par{"allowSelf"}=          1; # if set to 1: also accepts columns with 1pdb-1pdb !
    

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

#    $par{""}=                   "";
				# --------------------
				# parameters

				# --------------------
				# executables
    $par{"exe"}=                "";
#    $par{""}=                   "";

				# ------------------------------
				# pointers to recognise correct
				#    columns in input file
				# ------------------------------
    %ptr=(
	  'id1',  1,		# position of 1st id (no of RDB col)
	  'id2',  2,		# position of 2nd id (no of RDB col)
	  'lali', 3,		# position of alignment length
	  'pide', 4,		# position of sequene identity
	  'dist', 5);

    $SEP="\t";			# separator for output files

}				# end of iniDef

#===============================================================================
sub iniLib {
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
	elsif ($arg=~/PWD=(.*)$/)      {$PWD=$1;}
    }

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
    foreach $lib("lib-ut.pl","lib-br.pl","lib-br5.pl"){
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
    $tmp{"s_k_i_p"}=         "problems,manual,hints";
    $tmp=0;
    $tmp=$par{"packName"}       if (defined $par{"packName"});
    $tmp=$0                     if (! defined $tmp || ! $tmp); 
    %tmp=('sourceFile', $tmp, 'scrName',$scrName, 'scrIn',$scrIn, 'scrGoal', $scrGoal, 
	  'scrNarg',$scrNarg, 'scrHelpTxt', $scrHelpTxt);
				# special help
    $tmp{"scrAddHelp"}=      "";
    $tmp{"special"}=         "filter".",". "nofilter".",". "noself".",";
    $tmp{"special"}.=        "pairs".",". "pdb".",". "mirror".",";
    $tmp{"special"}.=        "verb".",". "verb2".",". "".",". "".",";
    $tmp{"special"}.=        "fileOutId1".",". "fileOutId2".",". "fileOutPairs".",";
    $tmp{"special"}.=        "fileOutMirror".",";
#    $tmp{"special"}.=        "".",". "".",". "".",". "".",";
        
    $tmp{"filter"}=          "OR doThresh=1,   i.e. redo the filtering procedure (HSSP threshold)";
    $tmp{"nofilter"}=        "OR doThresh=0,   i.e. NOT redo the filtering (HSSP threshold)";
    $tmp{"noself"}=          "OR allowSelf=0,  i.e. ignore hits of 1pdb onto 1pdb";
    $tmp{"pairs"}=           "OR doPairs=1,    i.e. write list of pairs (for uniqueList.pl)";
    $tmp{"pdb"}=             "OR doCheckRes=1, i.e. check resolution (sets also pairs!)";
    $tmp{"mirror"}=          "OR doMirror=1,   i.e. write RDB again including res/len, excl self";

    $tmp{"filOutId1"}=       "name for file with list of id1";
    $tmp{"filOutId2"}=       "name for file with list of id2";
    $tmp{"filOutPairs"}=     "name for file with list of pairs";
    $tmp{"filOutMirror"}=    "name for mirrored input file";
    $tmp{"verb"}=            "OR verbose=1,    i.e. verbose output";
    $tmp{"verb2"}=           "OR verb2=1,      i.e. very verbose output";
#                            "------------------------------------------------------------\n";
    return(%tmp);
}				# end of iniHelpNet

#===============================================================================
sub fileRdLoc {
    local($fileInLoc)=@_;
    $[ =1 ;
#-------------------------------------------------------------------------------
#   fileRdLoc                   reads RDB file
#       in/out GLOBAL:          all
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."fileRdLoc";$fhinLoc="FHIN_"."fileRdLoc";

    undef @rd; undef @ptr_this2fin;
    $ncol=$nrow=0; $ct=0; $it=0;
				# open file
    &open_file("$fhin", "$fileInLoc") || die '*** $scrName ERROR opening file $fileInLoc';
    while (<$fhin>) {
	next if ($_=~/^\#/);	# skip comments
	++$ct;
	next if ($ct==1);	# skip names
	next if ($ct==2 && $_=~/\d+[NFS]?[\s\t]+|[\s\t]+\d+[NFS]?/); # skip formats
	next if ($_=~/none/);	# skip empty
	++$it;
	$_=~s/\n//g;
	@tmp=split(/[\t\s]+/,$_);
	foreach $tmp (@tmp) {
	    $tmp=~s/\s//g; }
	$ncol=$#tmp            if ($#tmp > $ncol);
	
	if ($par{"doMirror"}) {
	    ++$nprot;
	    $ptr_this2fin[$it]=$nprot; }
	
	foreach $itcol (1..$#tmp){
	    $rd[$it][$itcol]=$tmp[$itcol];
				# add to final for mirroring option
	    $fin[$nprot][$itcol]=$tmp[$itcol] if ($par{"doMirror"});
	}
    }
    $nrow=$it;
    close($fhin);

    return(1,"ok $sbrName");
}				# end of fileRdLoc

#===============================================================================
sub filterLoc {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   filterLoc                   filters pairs
#       in/out GLOBAL:          all
#				$rd[itrow][itcol], $ncol, $nrow
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."filterLoc";$fhinLoc="FHIN_"."filterLoc";

				# --------------------------------------------------
				# loop over all pairs
				# --------------------------------------------------
    $#Ltake=0;
    foreach $itrow (1..$nrow){
				# ------------------------------
				# skip identical
	if (! $par{"allowSelf"} && $rd[$itrow][$ptr{"id1"}] eq $rd[$itrow][$ptr{"id2"}]){
	    $Ltake[$itrow]=0; 
	    next; }
				# wrong number of columns
	if (! $par{"doThresh"} || $ncol < 3) {
	    $Ltake[$itrow]=1; 
	    next; }
				# ------------------------------
				# length:
	$lali=$rd[$itrow][$ptr{"lali"}];
	if (! defined $lali){ print "*** ERROR: itrow=$itrow, col for lali (",$ptr{"lali"},") missing\n";
			      exit;} 
				# ---> too short
	next if ($lali < $par{"minLali"});

				# sequence identity
	$pide=$rd[$itrow][$ptr{"pide"}];
	if (! defined $pide){ print "*** ERROR: itrow=$itrow, col for pide (",$ptr{"pide"},") missing\n";
			      exit;} 
				# ------------------------------
				# distance from threshold:
	($Lok,$msg,$dist)=
	    &getDistanceThresh($par{"modeFilter"},$lali,$pide);
	return(&errSbrMsg("failed getDistanceThresh (lali=$lali, pide=$pide)",$msg))  if (! $Lok);
	$dist[$itrow]=$dist;
				# ---> too far
        next if ($dist <= $par{"minDist"});
#	print "xx lali=$lali, pide=$pide, dist=$dist,\n";
				# ------------------------------
				# take
	$Ltake[$itrow]=1;
    }
				# ------------------------------
				# store for mirroring
				# ------------------------------
    if ($par{"doMirror"}){
	foreach $itrow (1..$nrow){
	    $finTake[$ptr_this2fin[$itrow]]=$Ltake[$itrow];
	    next if (! $Ltake[$itrow]);
	    $finDist[$ptr_this2fin[$itrow]]=$dist[$itrow]; } }

    return(1,"ok $sbrName");
}				# end of filterLoc

#===============================================================================
sub getPairsLoc {
#    local($fileInLoc,$fhErrSbr) = @_ ;
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getPairsLoc                 all pairs into : %pairs, @pairs 
#       in  GLOBAL:             @Ltake, @rd, @dist, $nrow, %ptr, $resMax
#       out GLOBAL:             $pairs{$id1,"res"}= resolution of id1
#       out GLOBAL:             $pairs{$id1,"len"}= length of id1
#       out GLOBAL:             $pairs{$id1}=       "a, b, c"
#       out GLOBAL:             $pairs{$id1,"dist"}="Da,Db,Dc"
#       out GLOBAL:             @pairs=           array of all uniq first ids
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."getPairsLoc";$fhinLoc="FHIN_"."getPairsLoc";
    foreach $itrow (1..$nrow){
	$id1=$rd[$itrow][$ptr{"id1"}];
	if (! defined $pairs{$id1}){
	    push(@pairs,$id1);
	    $pairs{$id1}="";$pairs{"$id1","dist"}="";
				# ------------------------------
				# get length
	    $fileFasta=$par{"dirDataOrigin"}.$id1.$par{"extOrigin"};
	    return(&errSbr("original fasta ($fileFasta) missing"))   if (! -e $fileFasta);
	    return(&errSbr("original fasta ($fileFasta) not FASTA")) if (! &isFasta($fileFasta));
	    ($Lok,$id,$seq)=
		&fastaRdGuide($fileFasta);
	    return(&errSbrMsg("failed reading fasta ($fileFasta)",$id)) if (! $Lok);
	    $seq=~s/[^A-Za-z]//g;
	    $len=length($seq); 
	    $pairs{"$id1","len"}=$len;
				# mirror option
	    $finLen{"$id1"}=$len if ($par{"doMirror"});
				# ------------------------------
				# get resolution
	    if ($par{"doCheckRes"} && defined $par{"dirDataPdb"} && -d $par{"dirDataPdb"}){
		$idx=substr($id1,1,4);
		$filePdb=$par{"dirDataPdb"}.$idx.$par{"extPdb"};
		$res=$par{"resMax"};
		if (-e $filePdb){
		    ($Lok,$msg,$res)=
			&pdbGrepResolution($filePdb,0,0,$par{"resMax"});
		    return(&errSbrMsg("failed on grepping PDB resolution from $filePdb",
				      $msg)) if (! $Lok); }
		$pairs{"$id1","res"}=$res; 
				# mirror option
		$finRes{"$id1"}=$res if ($par{"doMirror"});
	    }
	}
				# skip?
	next if (! defined $Ltake[$itrow] || ! $Ltake[$itrow] );
	$id2=$rd[$itrow][$ptr{"id2"}];
	next if ($id2 eq $id1);	# skip self
	$pairs{$id1}.=$id2.",";
	return(&errSbr("itrow=$itrow, no distance defined ($id1,$id2)")) if (! defined $dist[$itrow]);
	$pairs{"$id1","dist"}.=sprintf("%-d,",int($dist[$itrow]));
    }

    return(1,"ok $sbrName");
}				# end of getPairsLoc

#===============================================================================
sub uniqIdLoc {
#    local($fileInLoc,$fhErrSbr) = @_ ;
    $[ =1 ;
#-------------------------------------------------------------------------------
#   uniqIdLoc                   get lists of unique identifiers to take (write)
#       in/out GLOBAL:          all
#                               $rd[itrow][itcol], $ncol, $nrow, $Ltake[1..$nrow]
#       out GLOBAL:             $id1[1..$nrow], $id2[1..$nrow]
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."uniqIdLoc";$fhinLoc="FHIN_"."uniqIdLoc";

    $#id1=$#id2=0;
    foreach $itrow (1..$nrow){
	next if (! defined $Ltake[$itrow] || ! $Ltake[$itrow] );

	$id1=$rd[$itrow][$ptr{"id1"}];
	return(&errSbr("no ptr id1 (itrow=$itrow)=".$ptr{"id1"}.", ?")) if (! defined $id1);
	$id2=$rd[$itrow][$ptr{"id2"}];
	return(&errSbr("no ptr id2 (itrow=$itrow)=".$ptr{"id2"}.", ?")) if (! defined $id2);
				# first 
	if (! defined $id1{$id1}) { 
	    push(@id1,$id1);
	    $id1{$id1}=$id2.",";}
	else                      { 
	    $id1{$id1}.=$id2.",";}
				# second
	if (! defined $id2{$id2}) { 
	    push(@id2,$id2);
	    $id2{$id2}=$id1.",";}
	else                      { 
	    $id2{$id2}.=$id1.",";}
	if ($par{"verb2"}){
	    $lali=$rd[$itrow][$ptr{"lali"}];
	    $pide=$rd[$itrow][$ptr{"pide"}];
	    $dist="?";
	    $dist=$dist[$itrow] if (defined $dist[$itrow]);
	    printf "%-6s %-6s %5d %5d %6.1f\n",$id1,$id2,$lali,$pide,$dist if ($dist ne "?");
	    printf "%-6s %-6s %5d %5d %6s\n",  $id1,$id2,$lali,$pide,$dist if ($dist eq "?");
	}
    }
    return(1,"ok $sbrName");
}				# end of uniqIdLoc

#===============================================================================
sub wrtMirrorLoc {
    local($fileOutLoc) = @_ ;
    $[ =1 ;
#-------------------------------------------------------------------------------
#   wrtMirrorLoc                mirror the input file with 
#       in/out GLOBAL:          all
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."wrtMirrorLoc";$fhoutLoc="FHOUT_"."wrtMirrorLoc";
				# check arguments
    return(&errSbr("not def fileOutLoc!"))          if (! defined $fileOutLoc);
				# open file
    &open_file("$fhoutLoc",">$fileOutLoc") 
	|| return(&errSbr("fileOutLoc=$fileOutLoc, not created"));
				# ------------------------------
				# header 
				# ------------------------------
    $expect=  "id1,id2,lali,pide,dist,len1";   $expect.=",res,"  if ($par{"doCheckRes"});
    $para=    "numProt,modeDist";              $para.=",maxRes"  if ($par{"doCheckRes"}); 
    $tmp{"name"}=           $scrName;
    $tmp{"nota","expect"}=  $expect;
    $tmp{"nota","id1"}=     "first identifier  (guide sequence)";
    $tmp{"nota","id2"}=     "second identifier (aligned sequence)";
    $tmp{"nota","lali"}=    "alignment length";
    $tmp{"nota","pide"}=    "percentage sequence identity";
    $tmp{"nota","dist"}=    "distance from HSSP (new) threshold";
    $tmp{"nota","len1"}=    "length of id1     (guide sequence)";
    $tmp{"nota","res"}=     "PDB resolution of id1 (resMax=".$par{"resMax"}.")";
    
    $tmp{"nota","1"}=       "numProt". "\t"."number of proteins (rows)";
    $tmp{"nota","2"}=       "modeDist"."\t"."threshold curve used: old=HSSP, new=newIde, newSim";
    $tmp{"nota","3"}=       "maxRes".  "\t"."resolution used if not provided in PDB";

    $tmp{"para","expect"}=  $para;
    $tmp{"para","numProt"}= $nprot;
    $tmp{"para","modeDist"}=$par{"modeFilter"};
    $tmp{"para","maxRes"}=  $par{"resMax"};
    $tmp{"form","numProt"}= "%6d";
    $tmp{"form","maxRes"}=  "%6d";

    ($Lok,$msg)=
	&rdbGenWrtHdr($fhoutLoc,%tmp);
    return(&errSbrMsg("failed writing RDB header for $fileOutLoc",$msg)) if (! $Lok);
				# ------------------------------
				# names
				# ------------------------------
    print $fhoutLoc "id1",$SEP,"id2",$SEP,"lali",$SEP,"pide",$SEP,"dist",$SEP,"len1";
    print $fhoutLoc $SEP,"res"     if ($par{"doCheckRes"});
    print $fhoutLoc "\n";
				# ------------------------------
				# data
				# ------------------------------
    foreach $it (1..$nprot){
				# skip if below thresholds
	next if (! defined $finTake[$it] || ! $finTake[$it]);

	$id1=$fin[$it][$ptr{"id1"}];

	$tmpWrt=     $id1;
	$tmpWrt.=    $SEP.$fin[$it][$ptr{"id2"}];
	$tmpWrt.=    sprintf ("$SEP%6d",  $fin[$it][$ptr{"lali"}]);
	$tmpWrt.=    sprintf ("$SEP%6d",  $fin[$it][$ptr{"pide"}]);
	$tmpWrt.=    sprintf ("$SEP%6.1f",$finDist[$it]);
	$tmpWrt.=    sprintf ("$SEP%6d",  $finLen{"$id1"});
	$tmpWrt.=    sprintf ("$SEP%6.2f",$finRes{"$id1"}) if ($par{"doCheckRes"});

	print $fhoutLoc $tmpWrt,"\n";
	print      $tmpWrt,"\n" if ($par{"verb2"});
    }
    close($fhoutLoc);
    return(1,"ok $sbrName");
}				# end of wrtMirrorLoc

#===============================================================================
sub wrtPairsLoc {
    local($fileOutLoc) = @_ ;
    $[ =1 ;
#-------------------------------------------------------------------------------
#   wrtPairsLoc                 writes RDB of all pairs
#       in/out GLOBAL:          all
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."wrtPairsLoc";$fhoutLoc="FHOUT_"."wrtPairsLoc";
				# check arguments
    return(&errSbr("not def fileOutLoc!"))          if (! defined $fileOutLoc);
				# open file
    &open_file("$fhoutLoc",">$fileOutLoc") 
	|| return(&errSbr("fileOutLoc=$fileOutLoc, not created"));
				# ------------------------------
				# header 
				# ------------------------------
    $expect=  "id1,len,";   $expect.="res," if ($par{"doCheckRes"}); $expect.="id2,dist";
    $para=    "numProt,modeDist,features"; $para.=",maxRes"  if ($par{"doCheckRes"}); 
    $features="len";                       $features.=",res" if ($par{"doCheckRes"}); 
    $tmp{"name"}=           $scrName;
    $tmp{"nota","expect"}=  $expect;
    $tmp{"nota","id1"}=     "first identifier";
    $tmp{"nota","len"}=     "length of id1";
    $tmp{"nota","res"}=     "PDB resolution of id1 (resMax=".$par{"resMax"}.")";
    $tmp{"nota","id2"}=     "second identifier     (list separated by ',')";
    $tmp{"nota","dist"}=    "distance between id1 and id2 from threshold (list separated by ',')";
    $tmp{"nota","1"}=       "numProt". "\t"."number of proteins (rows)";
    $tmp{"nota","2"}=       "modeDist"."\t"."threshold curve used: old=HSSP, new=newIde, newSim";
    $tmp{"nota","3"}=       "features"."\t"."list of features for id1 (e.g. 'len,res')";
    $tmp{"nota","4"}=       "maxRes".  "\t"."resolution used if not provided in PDB";

    $tmp{"para","expect"}=  $para;
    $tmp{"para","numProt"}= $#pairs;
    $tmp{"para","modeDist"}=$par{"modeFilter"};
    $tmp{"para","features"}=$features;
    $tmp{"para","maxRes"}=  $par{"resMax"};
    $tmp{"form","numProt"}= "%6d";
    $tmp{"form","maxRes"}=  "%6d";

    ($Lok,$msg)=
	&rdbGenWrtHdr($fhoutLoc,%tmp);
    return(&errSbrMsg("failed writing RDB header for $fileOutLoc",$msg)) if (! $Lok);
				# ------------------------------
				# names
				# ------------------------------
    print $fhoutLoc "id1",$SEP,"len";
    print $fhoutLoc $SEP,"res"     if ($par{"doCheckRes"});
    print $fhoutLoc $SEP,"id2",$SEP,"dist","\n";

				# ------------------------------
				# data
				# ------------------------------
    foreach $id1 (@pairs){
	$tmpWrt=     "$id1";
	$tmpWrt.=    $SEP.$pairs{"$id1","len"};
	$tmpWrt.=    $SEP.$pairs{"$id1","res"} if ($par{"doCheckRes"});
				# get id2 arrays
	$pairs{$id1}=~s/,*$//g;          @tmp_id2= split(/,/,$pairs{$id1});
	$pairs{"$id1","dist"}=~s/,*$//g; @tmp_dist=split(/,/,$pairs{"$id1","dist"});
	return(&errSbr("id1=$id1, arrays for id2 and dist differ:\n".
		       "id2 =".$pairs{$id1}."\n".
		       "dist=".$pairs{"$id1","dist"})) if ($#tmp_id2 != $#tmp_dist);
				# write id2,dist arrays
	$tmpWrt.=    $SEP.$pairs{$id1};
	$tmpWrt.=    $SEP.$pairs{"$id1","dist"};
	print $fhoutLoc $tmpWrt,"\n";
	print      $tmpWrt,"\n" if ($par{"verb2"});
    }
    close($fhoutLoc);
    return(1,"ok $sbrName");
}				# end of wrtPairsLoc

