#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="adds SWISS-PROT HTM annotation (and topology) to HSSP files\n".
    "     \t \n".
    "     \t ";
#  
# 
#------------------------------------------------------------------------------#
#	Copyright				        	1999	       #
#	Burkhard Rost		rost@columbia.edu			       #
#	CUBIC (Columbia Univ)	http://www.columbia.edu/~rost/   	       #
#       Dept Biochemistry & Molecular Biophysics			       #
#       630 West, 168 Street						       #
#	New York, NY 10032	http://www.columbia.edu/~rost/                 #
#				version 0.1   	Dec,    	1999	       #
#------------------------------------------------------------------------------#
#

$[ =1 ;				# count from one

				# ------------------------------
				# defaults
%par=(
      'dirSwiss',      "/data/swissprot/current/", # directory of SWISS-PROT split
      'symbolHtm',     "H",	# symbol to write for HTM helix
      'symbolNot',     " ",	# symbol to write for non-HTM helix ('*' to leave as is!)

      'symbolHtm',     "H",	# symbol to write for HTM helix
      'symbolNot',     " ",	# symbol to write for non-HTM helix ('*' to leave as is!)
      'extOut',        ".hsspSwiss", # extension for output file
      '', "",			# 
      );

$fhout="FHOUT";

@kwd=sort (keys %par);
$Ldebug=0;
$Lverb= 0;
$Lskip= 0;
				# ------------------------------
if ($#ARGV<1){			# help
    print  "goal: $scrGoal\n";
    print  "use:  '$scrName file.hssp* (or list with extension .list)'\n";
    print  "note: files may also be SWISS-PROT files, if the following syntax is kept:\n";
    print  "      name      -> name of swissprot file\n";
    print  "      name.hssp -> name of HSSP file\n";
    print  "      \n";
    print  "opt:  \n";
				#      'keyword'   'value'    'description'
    printf "%5s %-15s=%-20s %-s\n","","dirOut",  "x",       "output dir (name: same as in)";
    printf "%5s %-15s=%-20s %-s\n","","fileOut", "x",       "name of output file";

    printf "%5s %-15s %-20s %-s\n","","skip",    "no value","do not write file if existing, already";

#    printf "%5s %-15s=%-20s %-s\n","","",   "x", "";
#    printf "%5s %-15s %-20s %-s\n","","",        "",         "continued";
#    printf "%5s %-15s %-20s %-s\n","","",   "no value","";

    printf "%5s %-15s %-20s %-s\n","","dbg",   "no value",   "debug mode";
    printf "%5s %-15s %-20s %-s\n","","silent|-s","no value","no screen output";
    printf "%5s %-15s %-20s %-s\n","","verb|-s",  "no value","verbose";
#    printf "%5s %-15s %-20s %-s\n","","noScreen", "no value","";
#    printf "%5s %-15s=%-20s %-s\n","","",   "x", "";
#    printf "%5s %-15s %-20s %-s\n","","",   "no value","";
    if (defined %par && $#kwd > 0){
	$tmp= sprintf("%5s %-15s  %-20s %-s\n","","-" x 15 ,"-" x 20,"-" x 30);
	$tmp.=sprintf("%5s %-15s  %-20s %-s\n","","other:","default settings: "," ");
	$tmp2="";
	foreach $kwd (@kwd){
	    next if (! defined $par{$kwd});
	    next if ($kwd=~/^\s*$/);
	    if    ($par{$kwd}=~/^\d+$/){
		$tmp2.=sprintf("%5s %-15s= %10d %9s %-s\n","",$kwd,$par{$kwd}," ","(def)");}
	    elsif ($par{$kwd}=~/^[0-9\.]+$/){
		$tmp2.=sprintf("%5s %-15s= %10.3f %9s %-s\n","",$kwd,$par{$kwd}," ","(def)");}
	    else {
		$tmp2.=sprintf("%5s %-15s= %-20s %-s\n","",$kwd,$par{$kwd},"(def)");} 
	} 
	print $tmp, $tmp2       if (length($tmp2)>1);
    }
    exit;}
				# initialise variables

$LisList=0;
$#fileIn=0;
$fileOut=$dirOut="";
				# ------------------------------
				# read command line
foreach $arg (@ARGV){
#    next if ($arg eq $ARGV[1]);
    if    ($arg=~/^fileOut=(.*)$/)        { $fileOut=        $1;}
    elsif ($arg=~/^dirOut=(.*)$/)         { $dirOut=        $1;}
    elsif ($arg=~/^de?bu?g$/)             { $Ldebug=         1;
					    $Lverb=          1;}
    elsif ($arg=~/^verb(ose)?$|^\-v$/)    { $Lverb=          1;}
    elsif ($arg=~/^silent$|^\-s$/)        { $Lverb=          0;}

    elsif ($arg=~/^(is)?list$/i)          { $LisList=        1;}

    elsif ($arg=~/^skip$/i)               { $Lskip=          1;}

#    elsif ($arg=~/^=(.*)$/){ $=$1;}
    elsif (-e $arg)                       { push(@fileIn,$arg); }
    else {
	$Lok=0; 
	if (defined %par && $#kwd>0) { 
	    foreach $kwd (@kwd){ 
		if ($arg =~ /^$kwd=(.+)$/){$Lok=1;$par{$kwd}=$1;
					   last;}}}
	if (! $Lok){ print "*** wrong command line arg '$arg'\n";
		     exit;}}}

foreach $dir ($par{"dirSwiss"},$dirOut){
    next if (! defined $dir || ! $dir || length($dir)<1 || $dir=~/^unk$/i);
    next if ($dir=~/\/$/);
    $dir.="/";
}

$fileIn=$fileIn[1];
die ("*** ERROR $scrName: missing input $fileIn\n") 
    if (! -e $fileIn);
				# ------------------------------
				# (0) digest file (list?)
				# ------------------------------
$#fileTmp=0;
foreach $fileIn (@fileIn){
    if ( ($#fileIn==1 && $LisList) || $fileIn =~/\.list/) {
	($Lok,$msg,$file,$tmp)=
	    &fileListRd($fileIn);if (! $Lok){ print "*** ERROR $scrName: input list\n",$msg,"\n";
					      exit; }
	@tmpf=split(/,/,$file); 
	push(@fileTmp,@tmpf);
	next;}
    push(@fileTmp,$fileIn);
}
@fileIn= @fileTmp;
$#fileTmp=0;			# slim-is-in

				# ------------------------------
				# (1) sort out swiss-prot files
				# ------------------------------
$#fileTmp=$#fileSwiss=0;
foreach $file (@fileIn){
    if (&isSwiss($file)){
	push(@fileSwiss,$file);
	next;}
    push(@fileTmp,$file);}
@fileIn=@fileTmp;
				# restore swiss-prot files by id
foreach $fileSwiss (@fileSwiss){
    $id=$fileSwiss;
    $id=~s/^.*\///g;		# purge path
    $fileSwiss{$tmp}=$fileSwiss;
}
				# ------------------------------
				# (1) read file(s)
				# ------------------------------
$ct=0;
$#error_nohtm=$#error_noswiss=
    $#error_nohssp=$#error_nothssp=$#error_emptyhssp=0;
    
foreach $fileIn (@fileIn){
    ++$ct;
				# file missing
    if (! -e $fileIn){
	print "-*- WARN $scrName: no fileIn=$fileIn\n";
	push(@error_nohssp,$fileIn);
	next;}
				# note: here it MUST be an HSSP file
    if (! &is_hssp($fileIn)){
	print "-*- WARN $scrName: file=$fileIn, expected to be HSSP format (not true?)!\n";
	push(@error_nothssp,$fileIn);
	next;}
				# empty HSSP
    if (&is_hssp_empty($fileIn)){
	print "-*- WARN $scrName: file=$fileIn, empty HSSP file?\n";
	push(@error_emptyhssp,$fileIn);
	next;}
				# get corresponding SWISS-PROT file
    
    $id=$fileIn;
    $id=~s/^.*\///g;		# purge path
    $id=~s/\.hssp.*$//g;	# purge extension

				# name output file
    if ($ct > 1 ||
	! $fileOut || length($fileOut)<1){
	$fileOut=$fileIn;
	$fileOut=~s/^.*\///g;	# purge path
	$fileOut=$dirOut.$fileOut;
	if ($fileOut eq $fileIn){
	    $ext=$par{"extOut"};
	    $fileOut=~s/(\.hssp.*)$/$ext/;}
	if ($fileOut eq $fileIn){
	    $fileOut=~s/^.*\///g;
	    $fileOut="Out-".$fileOut;}}

				# skip if output existing already
    next if ($Lskip && -e $fileOut);

    $fileSwiss=0;
				# first: try local
    $fileSwiss=$fileIn;
    $fileSwiss=~s/\.hssp.*$//g;
    if (! -e $fileSwiss && defined $fileSwiss{$id}){
	$fileSwiss=$fileSwiss{$id}; }
    if (! $fileSwiss){
	$tmp=$id; $tmp=~s/^[a-zA-Z0-9]+_(.).*$/$1/;
	$fileSwiss=$par{"dirSwiss"}.$tmp."/".$id; }
    if (! $fileSwiss  || ! -e $fileSwiss){
	print "-*- WARN $scrName: missing fileSwiss=$fileSwiss!\n";
	push(@error_noswiss,$fileSwiss);
	next;}

    printf 
	"--- $scrName: working on %-25s %4d (%4.1f perc of job) swiss=%-s\n",
	$fileIn,$ct,(100*$ct/$#fileIn),$fileSwiss if ($Lverb);

				# -----------------------------------------
				# now read swissprot (sequence and TM)
				# -----------------------------------------
    ($Lok,$msg,$htm,$topology,$seq)=
	&swissRdHtmTop($fileSwiss
		       );       &errScrMsg("failed reading swissprot=$fileSwiss!",
					   $msg) if (! $Lok);
    if ($htm!~/\d+\-\d+/){
	print "-*- WARN $scrName: no HTM in fileSwiss=$fileSwiss!\n";
	push(@error_nohtm,$fileSwiss);
	next;}
	
				# debug write
    print "dbg top=$topology, htm=$htm\n" if ($Ldebug);

				# -----------------------------------------
				# now read / and write HSSP
				# -----------------------------------------
				# now write
    ($Lok,$msg)=
	&hsspWrtHtm($fileIn,$fileOut,$htm,$topology,$seq,
		    $par{"symbolHtm"},$par{"symbolNot"}
		    );          &errScrMsg("failed writing hssp=$fileOut, from in=$fileIn!",
					   $msg) if (! $Lok);
	
}

				# ------------------------------
				# ERROR
if (@error_noswiss){
    $fileError="ERROR-swiss-missing.list";
    open($fhout,">".$fileError) || warn "*** WARN $scrName failed opening fileError=$fileError!";
    foreach $tmp (@error_noswiss){
	print $fhout $tmp,"\n";
    } close($fhout);
    print "-*- $scrName: ERRORs 'missing SWISS' listed in file=$fileError\n";}


if (@error_nohtm){
    $fileError="ERROR-swiss-nohtm.list";
    open($fhout,">".$fileError) || warn "*** WARN $scrName failed opening fileError=$fileError!";
    foreach $tmp (@error_nohtm){
	print $fhout $tmp,"\n";
    } close($fhout);
    print "-*- $scrName: ERRORs 'no HTM in swiss' listed in file=$fileError\n";}


if (@error_nohssp){
    $fileError="ERROR-hssp-missing.list";
    open($fhout,">".$fileError) || warn "*** WARN $scrName failed opening fileError=$fileError!";
    foreach $tmp (@error_nohssp){
	print $fhout $tmp,"\n";
    } close($fhout);
    print "-*- $scrName: ERRORs 'HSSP missing' listed in file=$fileError\n";}


if (@error_nothssp){
    $fileError="ERROR-hssp-not.list";
    open($fhout,">".$fileError) || warn "*** WARN $scrName failed opening fileError=$fileError!";
    foreach $tmp (@error_nothssp){
	print $fhout $tmp,"\n";
    } close($fhout);
    print "-*- $scrName: ERRORs 'not HSSP format' listed in file=$fileError\n";}


if (@error_emptyhssp){
    $fileError="ERROR-hssp-empty.list";
    open($fhout,">".$fileError) || warn "*** WARN $scrName failed opening fileError=$fileError!";
    foreach $tmp (@error_emptyhssp){
	print $fhout $tmp,"\n";
    } close($fhout);
    print "-*- $scrName: ERRORs 'HSSP empty' listed in file=$fileError\n";}




print "--- $scrName seems happy\n";
exit;



#==============================================================================
# library collected (begin) lll
#==============================================================================


#===============================================================================
sub errSbr    {local($txtInLoc,$sbrNameLocy) = @_ ;
#-------------------------------------------------------------------------------
#   errSbr                      simply writes '*** ERROR $sbrName: $txtInLoc'
#-------------------------------------------------------------------------------
	       $sbrNameLocy=$sbrName if (! defined $sbrNameLocy);
	       $txtInLoc.="\n";
	       $txtInLoc=~s/\n\n+/\n/g;
	       return(0,"*** ERROR $sbrNameLocy: $txtInLoc");
}				# end of errSbr

#===============================================================================
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
sub fileListRd {
    local($fileInLoc,$fhErrSbr,$extForChain,$dirLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   fileListRd                  reads a list of files
#       in:                     file_list=     file with filenames
#       in:                     $fhErrSbr=     file handle to report missing files 
#                                              (0 to surpress warnings!)
#       in:                     $extForChain=  'ext1,ext2' : extensions to check for chains,
#                                              i.e. if not existing purge ext_[A-Z0-9]
#       in:                     $dirLoc=       'dir1,dir2' : directories to scan for file
#       out:                    1|0,msg
#       out:                    $list=         'file1,file2,...'
#       out:                    $chain=        'c1,c2,...' : if chains found
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."fileListRd";$fhinLoc="FHIN_"."fileListRd";
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc!",0)         if (! defined $fileInLoc);
    $fhErrSbr="STDOUT"                                     if (! defined $fhErrSbr);
    $extForChain=0                                         if (! defined $extForChain);
    return(0,"*** $sbrName: miss in file '$fileInLoc'!",0) if (! -e $fileInLoc);
    @extLoc=split(/,/,$extForChain)                        if ($extForChain);
    @dirLoc=split(/,/,$dirLoc)                             if ($dirLoc);
				# ------------------------------
				# open file
    open($fhinLoc,$fileInLoc) ||
	return(0,"*** ERROR $sbrName: fileIn=$fileInLoc, not opened\n",0);

    $tmpChain=$tmpFile="";	# ------------------------------
    while (<$fhinLoc>) {	# read list
	$_=~s/\n|\s//g; $file=$_;
	next if (length($_)==0);
	if    (-e $file) {
	    $tmpFile.="$file,";$tmpChain.="*,";} # file ok 
	else {$Lok=0;$chainTmp="unk";
	      foreach $ext (@extLoc){ # check chain
		  foreach $dir ("",@dirLoc){ # check dir (first: local!)
		      $fileTmp=$file; $dir.="/"  if (length($dir)>0 && $dir !~/\/$/);
		      $fileTmp=~s/^(.*$ext)\_([A-Z0-9])$/$1/;
		      $chainTmp=$2               if (defined $2);
		      $fileTmp=$dir.$fileTmp; 
		      $Lok=1  if (-e $fileTmp);
		      last if $Lok;}
		  last if $Lok;}
	      if ($Lok){$tmpFile.="$fileTmp,";
			$tmpChain.="*,"          if (! defined $chainTmp || $chainTmp eq "unk");
			$tmpChain.="$chainTmp,"  if (defined $chainTmp && $chainTmp ne "unk"); }
	      else { print $fhErrSbr "-*- WARN $sbrName missing file=$_,\n";}}
    }close($fhinLoc);
    $tmpFile=~s/^,*|,*$//g;$tmpChain=~s/^,*|,*$//g;
    return(1,"ok $sbrName",$tmpFile,$tmpChain);
}				# end of fileListRd

#===============================================================================
sub is_hssp {
    local ($fileInLoc) = @_ ;local ($fh,$Lis,$tmp);
#--------------------------------------------------------------------------------
#   is_hssp                     checks whether or not file is in HSSP format
#       in:                     $file
#       out:                    1 if is hssp; 0 else
#--------------------------------------------------------------------------------
				# highest priority: has to exist
    return (0)                  if (! -e $fileInLoc);
    $fh="FHIN_CHECK_HSSP";
    open($fh, $fileInLoc) || 
	do { print "*** ERROR is_hssp $fileInLoc not opened to $fh\n";
	     return (0) ;};	# missing file -> 0
    $tmp=<$fh>;			# first line
    close($fh);
				# is HSSP
    return(1)                   if (defined $tmp && $tmp=~/^HSSP/);
    return(0);
}				# end of is_hssp

#===============================================================================
sub is_hssp_empty {
    local ($fileInLoc) = @_ ;local ($fh,$Lis);
#--------------------------------------------------------------------------------
#   is_hssp_empty               checks whether or not HSSP file has NALIGN=0
#       in:                     $file
#       out:                    1 if is empty; 0 else
#--------------------------------------------------------------------------------
    return (0)                  if (! defined $fileInLoc || ! -e $fileInLoc);
    $fh="FHIN_CHECK_HSSP";
    open($fh, $fileInLoc) || 
	do { print "*** ERROR is_hssp_empty: filein=$fileInLoc, not opened to $fh\n";
	     return (0) ;};	# missing file -> 0
    while ( <$fh> ) {
	next if ($_!~/^NALIGN\s+(\d+)/);
	if ($1 eq "0"){
	    close($fh); 
	    return(1);}
	else {
	    close($fh); 
	    return(0);}
    }
    return 0;
}				# end of is_hssp_empty

#==============================================================================
sub isSwiss {
    local ($fileLoc) = @_ ; local ($Lok);
#--------------------------------------------------------------------------------
#    isSwiss                    checks whether or not file is in SWISS-PROT format (/^ID   /)
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
    $fhinLoc="FHIN_SWISS";
    open($fhinLoc,$fileLoc) ||
	do { print "*** ERROR isSwiss: filein=$fileLoc, not opened to $fhinLoc\n";
	     return (0) ;};	# missing file -> 0
    while (<$fhinLoc>){ 
	$Lok=1                  if ($_=~/^ID   /);
	last;}
    close($fhinLoc);
    return($Lok);
}				# end of isSwiss



#==============================================================================
# library collected (end)   lll
#==============================================================================

#===============================================================================
sub swissGetTopology {
    local($domain1,$domain2) = @_ ;
    local($SBR5);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   swissGetTopology            returns topology (<IN|OUT|0>) based on the
#                               domain before and after the first membrane helix
#       in:                     $domain1: SWISS-PROT FT line keyword for 1st domain
#       in:                     $domain2: SWISS-PROT FT line keyword for 2nd domain
#       out:                    1|0,msg,$topology = 0 for undefined,
#                                        =<IN|OUT|IN_INTER_*|OUT_INTER_*|..>
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $SBR5=$tmp."swissGetTopology";
				# check arguments
    return(&errSbr("not def domain1!"),$SBR5)  if (! defined $domain1);
    return(&errSbr("not def domain2!"),$SBR5)  if (! defined $domain2);
    
				# default
    $topology=0;
				# extracellular
    if    ($domain1=~/EXTRACELLULAR/){
	$topology="OUT";}
    elsif ($domain2=~/EXTRACELLULAR/){
	$topology="IN";}
				# lumenal
    elsif ($domain1=~/LUMEN/){
	$topology="IN";}
    elsif ($domain2=~/LUMEN/){
	$topology="OUT";}
				# periplasmic
    elsif ($domain1=~/PERIPLASMIC/){
	$topology="IN";}
    elsif ($domain2=~/PERIPLASMIC/){
	$topology="OUT";}
				# mitochondrial intermembrane
    elsif ($domain1=~/MITOCHONDRIAL INTERMEMBRANE/){
	$topology="IN_INTER_MITOCHONDRIAL";}
    elsif ($domain2=~/MITOCHONDRIAL INTERMEMBRANE/){
	$topology="OUT_INTER_MITOCHONDRIAL";}
				# mitochondrial inner
    elsif ($domain1=~/MITOCHONDRIAL MATRIX/){
	$topology="IN_MITOCHONDRIAL";}
    elsif ($domain2=~/MITOCHONDRIAL MATRIX/){
	$topology="OUT_MITOCHONDRIAL";}
				# nuclear (?) intermembrane
    elsif ($domain1=~/INTERMEMBRANE/){
	$topology="IN_INTER";}
    elsif ($domain2=~/INTERMEMBRANE/){
	$topology="OUT_INTER";}
				# fully cytoplasmic
    elsif ($domain1=~/CYTOPLASMIC/ && $domain2=~/CYTOPLASMIC/){
	$topology="IN";}

				# vacular
    elsif ($domain1=~/CYTOPLASMIC/ && $domain2=~/VACUOLAR/){
	$topology="IN_VACUOLAR";}
    elsif ($domain1=~/VACUOLAR/ && $domain2=~/CYTOPLASMIC/){
	$topology="OUT_VACUOLAR";}

				# virus?
    elsif ($domain1=~/CISTERNAL/){
	$topology="IN_CISTERNAL";}
    elsif ($domain2=~/CISTERNAL/){
	$topology="OUT_CISTERNAL";}

				# second not given: single
    elsif (! $domain2 && $domain1=~/CYTOPLASMIC/){
	$topology="IN";}
	

    elsif ($domain2=~/INTERMEMBRANE/){
	$topology="OUT_INTER";}

    return(1,"ok $SBR5",$topology);
}				# end of swissGetTopology


#==========================================================================
sub swissRdHtmTop {
    local ($fileInLoc) = @_ ;
    $[ =1 ;
#-------------------------------------------------------------------------------
#   swissRdHtmTop               reads HTM, and Topology from SWISS-PROT file
#       in:                     $fileInLoc
#       out:                    1|0,msg,$htm,$TOPOLOGY,$SEQ
#                               with $htm='beg1-end1,beg2-end2,..'
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR3="swissRdHtmTop";
    $fhinLoc="FHIN_".$SBR3;

    open($fhinLoc,$fileInLoc) || 
	return(0,"*** ERROR $SBR3: failed opening file=$fileInLoc, to fh=$fhinLoc!\n");

    $#HTM_BEG=$#HTM_END=0;
    $SEQ="";
    $domain1=$domain2=0;
    while(<$fhinLoc>) {
	$line=$_;
				# read membrane region
	if ($_=~/^FT   TRANSMEM/) {
				# FT   TRANSMEM     23       47  
				# ....,....1....,....2....,....3.

	    $tmp1=substr($_,16,5);
	    $tmp1=~s/\s//g;
	    $tmp2=substr($_,23,8);$tmp2=~s/\s//g;$tmp2=~s/\D//g;
	    
	    if ( (length($tmp1)*length($tmp2)) > 0 ) {
		push(@HTM_BEG,$tmp1);push(@HTM_END,$tmp2);
	    }
	    next; }
				# read sequence
	if ($_=~/^     /) {
	    $tmp1=$_;$tmp1=~s/\s|\n//g;
	    $SEQ.=$tmp1;
	    next; }
				# get first domain name (before)
	if (! $domain1 && 
	    $_=~/^FT   DOMAIN \s+(\S+)\s+(\S+)\s+(\S+.*)$/){
	    $domain1=$3;
	    next; }
				# get first domain name (after)
	if (! $domain2 && $#HTM_BEG &&
	    $_=~/^FT   DOMAIN \s+(\S+)\s+(\S+)\s+(\S+.*)$/){
	    $domain2=$3;
	    next; }
    }
    close($fhinLoc);
				# ------------------------------
				# digest domain
    ($Lok,$msg,$TOPOLOGY)=
	&swissGetTopology($domain1,$domain2);

				# ------------------------------
				# digest domains
    $htm="";
    foreach $it (1..$#HTM_BEG){
	$htm.=$HTM_BEG[$it]."-".$HTM_END[$it].",";
				# hack: correct '>' and '<'
	$htm=~s/[><]//g         if ($htm=~/[><]/);
    }
    $htm=~s/,*$//g;
				# ------------------------------
				# clean up
    $#HTM_BEG=$#HTM_END=0;
				
    return(1,"ok",$htm,$TOPOLOGY,$SEQ);
}

#===============================================================================
sub hsspWrtHtm {
    local($fileInLoc,$fileOutLoc,$htmRegion,$topology,$seqSwiss,
	  $symbolHtm,$symbolNot) = @_ ;
    local($SBR3,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspWrtHtm                  writes topology and HTM regions into HSSP file
#                  note:        topology appended to 'HEADER' line 
#       in:                     $fileInLoc:  old HSSP file
#       in:                     $fileOutLoc: new HSSP file
#       in:                     $htmRegion:  begin-end of htm regions
#                                            many separated by commata
#       in:                     $topology:   <IN|OUT|UNK> topology (0 to ignore)
#       in:                     $seqSwiss:   sequence read from SWISS-PROT (for
#                                            control purposes)
#       in:                     $symbolHtm:  abbreviation used for HTM in HSSP
#       in:                     $symbolNot:  abbreviation used for NOT-HTM in HSSP
#                                            '*' -> keep (is default)
#       out:                    1|0,msg,  implicit: file
#                               
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $SBR3=$tmp."hsspWrtHtm";
    $fhinLoc="FHIN_"."hsspWrtHtm";$fhoutLoc="FHOUT_"."hsspWrtHtm";
				# check arguments
    return(&errSbr("not def fileInLoc!",$SBR3))  if (! defined $fileInLoc);
    return(&errSbr("not def fileOutLoc!",$SBR3)) if (! defined $fileOutLoc);
    return(&errSbr("not def htmRegion!",$SBR3))  if (! defined $htmRegion);
    $topology="UNK"                              if (! defined $topology || 
						     ! $topology);
    $seqSwiss=0                                  if (! defined $seqSwiss);
    $symbolHtm="H"                               if (! defined $symbolHtm);
    $symbolHtm="*"                               if (! defined $symbolNot);
#    return(&errSbr("not def !"))          if (! defined $);
				# ------------------------------
				# open file
    open($fhinLoc,$fileInLoc) || 
	return(&errSbr("fileInLoc=$fileInLoc, not opened",$SBR3));
    open($fhoutLoc,">".$fileOutLoc) || 
	return(&errSbr("fileOutLoc=$fileOutLoc, not created",$SBR3));

				# ------------------------------
				# get regions
    @tmp=   split(/,/,$htmRegion);
    $#htmLoc=0;
    $cthtm=0;
    foreach $tmp (@tmp){
	$tmp=~s/\s//g;		# purge blanks
				# check format
	return(&errSbr("region=$tmp, not of format 'beg-end'!\n",$SBR3))
	    if ($tmp!~/\d+\-\d+/);
	($beg,$end)=split(/\-/,$tmp);
	foreach $it ($beg..$end){
	    $htmLoc[$it]=1;
	}
	$cthtm+=$end-$beg+1;
    }
				# ------------------------------
				# any found?
    return(&errSbr("no region found in htmRegion=$htmRegion, not of format 'beg-end'?\n",
		   $SBR3))      if (! $#htmLoc || $cthtm < 10);

				# ------------------------------
				# read write HSSP file
    $Lchange=$Lwriteprof=$ctres=0;

    while (<$fhinLoc>) {
	$line=$_; $line=~s/\n//g;

				# before ali: just mirror
	if    ($_=~/^\#\# ALI/ )   { 
	    $Lchange=0;
	    $ctres=0; }
				# misuse header line
	elsif ($_=~/^HEADER/ ){ 
	    $Lchange=0;
	    $line.=" SWISS-PROT TOPOLOGY=".$topology;}
				# in ali: start profile
	elsif ($_=~/^\#\# SEQUENCE PROF/ ){ 
	    $Lchange=   0;
	    $Lwriteprof=1; }
				# in ali: start changing
	elsif ($_=~/^\#\# SEQ/ ){ 
	    $Lchange=    0;
	    $Lwriteprof= 0; }

				# ' SeqNo ' line
	if (! $Lwriteprof && $_=~/^ SeqNo/){
	    $Lchange=1;
	    print $fhoutLoc $line,"\n";
	    next;}

				# mirror
	if (! $Lchange) {
	    print $fhoutLoc $line,"\n";
	    next; }


				# change
	++$ctres;
	$tmp=    substr($line,15,4); 
	$aaHssp= substr($line,15,1); 
				# check similarity to SWISS-sequence
	if ($seqSwiss && ! $Lwriteprof){
	    $aaSwiss=substr($seqSwiss,$ctres,1);
	    return(&errSbr("ctres=$ctres, AAhssp=$aaHssp, not matching AAswiss=$aaSwiss\n".
			   "line=$line\n",
			   $SBR3)) if ($aaSwiss ne $aaHssp); }
				# ------------------------------
				# build up new line
				# is HTM
	if    (defined $htmLoc[$ctres]){
	    $structure=$symbolHtm;}
				# not HTM, but keep what you find
	elsif ($symbolNot eq "*" && 
	       substr($line,18,1) ne "U"){
	    $structure=substr($line,18,1);}
				# not HTM, replace by new symbol
	else {
	    $structure=$symbolNot;}

	$new=substr($line,1,17).$structure.substr($line,19);
	$tmp=substr($new,18,1);
	print "--- $SBR3: $fileInLoc strange structure '$tmp'\n" if ($tmp =~ /^u$/i);
#	die if ($tmp =~ /^u$/i);

				# now write
	print $fhoutLoc 
	    $new,"\n";
    } 
    close($fhinLoc);
    close($fhoutLoc);
				# clean up
    $#tmp=$#htmLoc=0;		# slim-is-in

    return(0,"*** ERROR $SBR3: failed producing output=$fileOutLoc!\n")
	if (! -e $fileOutLoc);
    return(1,"ok $SBR3");
}				# end of hsspWrtHtm


