#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="corrects mistake from copf (NALIGN=N+1 really IS N) and mistake in length (if any)\n".
    "     \t \n".
    "     \t ";
#  
# 
#------------------------------------------------------------------------------#
#	Copyright				        	2000	       #
#	Burkhard Rost		rost@columbia.edu			       #
#	CUBIC (Columbia Univ)	http://www.columbia.edu/~rost/   	       #
#       Dept Biochemistry & Molecular Biophysics			       #
#       630 West, 168 Street						       #
#	New York, NY 10032	http://www.columbia.edu/~rost/                 #
#				version 0.1   	Feb,    	2000	       #
#------------------------------------------------------------------------------#
#

$[ =1 ;				# count from one

				# ------------------------------
				# defaults
%par=(
      '', "",			# 
      );
@kwd=sort (keys %par);
$Ldebug=  0;
$Lverb=   0;
$Lreplace=0;
				# ------------------------------
if ($#ARGV<1){			# help
    print  "goal: $scrGoal\n";
    print  "use:  '$scrName '\n";
    print  "opt:  \n";
				#      'keyword'   'value'    'description'
    printf "%5s %-15s=%-20s %-s\n","","fileOut", "x",       "name of output file";
    printf "%5s %-15s=%-20s %-s\n","","dirOut",  "x",       "directory of output files";
#    printf "%5s %-15s=%-20s %-s\n","","",   "x", "";
#    printf "%5s %-15s %-20s %-s\n","","",   "no value","";

    printf "%5s %-15s %-20s %-s\n","","dbg",   "no value",   "debug mode";
    printf "%5s %-15s %-20s %-s\n","","silent|-s","no value","no screen output";
    printf "%5s %-15s %-20s %-s\n","","verb|-s",  "no value","verbose";
#    printf "%5s %-15s %-20s %-s\n","","noScreen", "no value","";
#    printf "%5s %-15s=%-20s %-s\n","","",   "x", "";
#    printf "%5s %-15s %-20s %-s\n","","",   "no value","";

    printf "%5s %-15s %-20s %-s\n","","nolen",    "no value","faster: will NOT check length";
    printf "%5s %-15s %-20s %-s\n","","replace",  "no value","will replace old with new";

    if (defined %par && $#kwd > 0){
	$tmp= sprintf("%5s %-15s  %-20s %-s\n","","-" x 15 ,"-" x 20,"-" x 30);
	$tmp.=sprintf("%5s %-15s  %-20s %-s\n","","other:","default settings: "," ");
	$tmp2="";
	foreach $kwd (@kwd){
	    next if (! defined $par{$kwd} || length($par{$kwd})<1 );
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
$fhin="FHIN";$fhout="FHOUT";
$LisList=0;
$#fileIn=0;
$Llen=   1;
				# ------------------------------
				# read command line
foreach $arg (@ARGV){
#    next if ($arg eq $ARGV[1]);
    if    ($arg=~/^fileOut=(.*)$/)        { $fileOut=        $1;}
    elsif ($arg=~/^dirOut=(.*)$/)         { $dirOut=         $1; 
					    $dirOut.=        "/" if ($dirOut !~/\/$/);}
    elsif ($arg=~/^de?bu?g$/)             { $Ldebug=         1;
					    $Lverb=          1;}
    elsif ($arg=~/^verb(ose)?$|^\-v$/)    { $Lverb=          1;}
    elsif ($arg=~/^silent$|^\-s$/)        { $Lverb=          0;}
    elsif ($arg=~/^(is)?list$/i)          { $LisList=        1;}

    elsif ($arg=~/^nolen$/i)              { $Llen=           0;}
    elsif ($arg=~/^no.*$/i)               { $Llen=           0;}
    elsif ($arg=~/^replace$/i)            { $Lreplace=       1;}

#    elsif ($arg=~/^=(.*)$/){ $=$1;}
    elsif (-e $arg)                       { push(@fileIn,$arg); 
					    $LisList=        1 if ($arg=~/\.list/);}
    else {
	$Lok=0; 
	if (defined %par && $#kwd>0) { 
	    foreach $kwd (@kwd){ 
		if ($arg =~ /^$kwd=(.+)$/){$Lok=1;$par{$kwd}=$1;
					   last;}}}
	if (! $Lok){ print "*** wrong command line arg '$arg'\n";
		     exit;}}}

$fileIn=$fileIn[1];
die ("missing input $fileIn\n") if (! -e $fileIn);
if (! defined $fileOut){
    $tmp=$fileIn;$tmp=~s/^.*\///g;$fileOut="Out-".$tmp;}

				# ------------------------------
				# directories: add '/'
foreach $kwd (keys %par) {
    next if ($kwd !~/^dir/);
    next if (length($par{$kwd})==0 || $par{$kwd} eq "unk" );
    $par{$kwd}.="/"          if ($par{$kwd} !~ /\/$/);}


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
				# (1) read file(s)
				# ------------------------------
$ctfile=0;
$fileTmp="HSSP_CORRECT.tmp";
foreach $fileIn (@fileIn){
    ++$ctfile;
    if (! -e $fileIn){print "-*- WARN $scrName: no fileIn=$fileIn\n";
		      next;}
    printf 
	"--- $scrName: working on %-25s %4d (%4.1f perc of job)\n",
	$fileIn,$ctfile,(100*$ctfile/$#fileIn);

				# ------------------------------
				# correct NALIGN mistakes
				#    NOTE: overwrite input file!
				# ------------------------------
    $fileOut=$fileIn;
    if (! $Lreplace){
	$fileOut=~s/^.*\///g;
	$fileOut=~s/(\.hssp)/-new$1/;}

    ($Lok,$msg)=
	&hsspCorrectNaliMistake
	    ($fileIn,$fileTmp,$fileOut
	     );                 return(&errSbrMsg("after call hsspCorrectNaliMistake",
						  $msg)) if (! $Lok);
    next if (! $Llen);
				# ------------------------------
				# check length
				# (a) get it
    open($fhin, $fileIn)     || die ("*** ERROR $scrName: failed to open in=$fileIn!\n");
    while (<$fhin>) {
	if    ($_ =~ /^SEQLENGTH\s+(\d+)/){
	    $lenhdr=$1;}
	last if ($_ =~ /^ SeqNo/);}
    $ctres=0;
    while (<$fhin>) {
	last if ($_ =~ /^\#/);
	++$ctres; }
    close($fhin);
    $lenrd=$ctres;

    if ($lenhdr == $lenrd){
	print "--- no length correction needed, $lenrd is ok!\n" if ($Lverb);
	next; }

				# (b) correct it
    open($fhin, $fileIn)      || die ("*** ERROR $scrName: failed to open in=$fileIn!\n");
    open($fhout,">".$fileTmp) || die ("*** ERROR $scrName: failed to open out=$fileTmp!\n");
				# before pairs
    while (<$fhin>) {
	if    ($_ =~ /^SEQLENGTH/){
	    printf $fhout "%-9s%6d\n","SEQLENGTH",$lenrd;
	    last; }
	print $fhout $_;}
    while (<$fhin>){
	print $fhout $_;
    }
    close($fhin);
    close($fhout);
    print "--- corrected $lenhdr to $lenrd\n" if ($Lverb);
    system("\\mv $fileTmp $fileOut");
    unlink($fileTmp)            if (-e $fileTmp && ! $Ldebug);
}

exit;


#===============================================================================
sub hsspCorrectNaliMistake {
    local($fileInLoc,$filetmp,$fileOutLoc) = @_ ;
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspCorrectNaliMistake      corrects mistake in NALIGN (is N+1 should be N)
#                               
#                               ==============================
#                         NOTE: overrides input file!
#                               ==============================
#                               
#       in:                     $fileInLoc: HSSP file
#       in:                     $filetmp:   temporary file
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."hsspCorrectNaliMistake";
    $fhinLoc="FHIN_"."hsspCorrectNaliMistake";$fhoutLoc="FHOUT_"."hsspCorrectNaliMistake";
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
    $filetmp="TMP_CORRECT_HSSP_".$$.".tmp"         if (! defined $filetmp);
#    return(&errSbr("not def !"))          if (! defined $);

    return(&errSbr("no fileIn=$fileInLoc!"))  if (! -e $fileInLoc);

				# ------------------------------
				# (1) check whether wrong or not
				# ------------------------------
    open($fhinLoc,$fileInLoc) || return(&errSbr("fileInLoc=$fileInLoc, not opened"));
    while (<$fhinLoc>) {	# read file
	last if ($_=~/^\#\# ALIGN/);
	if ($_=~/^NALIGN\s+(\d+)/){
	    $nalign=$1;
	    next; }
	if ($_ =~ /^\s+\d+ :/){
	    ++$ct;
	}
    }
    close($fhinLoc);
    $nalign_actual=$ct;
				# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
				# NOTHING to do, IS fine!
    return(1,"no action") 
	if ($nalign_actual == $nalign);
				# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

    print "--- $sbrName: IS mistake in HSSP=$fileInLoc hdr=$nalign, really $nalign_actual\n"
	if (defined $par{"debug"} && $par{"debug"});
				# ------------------------------
				# (2) CORRECT mistake
				# ------------------------------
    open($fhinLoc,$fileInLoc)    || return(&errSbr("fileInLoc=$fileInLoc, not opened"));
    open($fhoutLoc,">".$filetmp) || return(&errSbr("fileOutLoc=$filetmp, not created"));
    while (<$fhinLoc>) {	# BEFORE HEADER NALIGN
	if ($_=~/^NALIGN\s+(\d+)/){
	    $nalign=$1;
	    $tmp=sprintf("NALIGN %8d\n",
			 $nalign_actual);
	    print $fhoutLoc $tmp;
	    last; }
	print $fhoutLoc $_; 
    }
    while (<$fhinLoc>) {	# AFTER event
	print $fhoutLoc $_; }
    close($fhinLoc);
    close($fhoutLoc);
				# check existence of file
    return(&errSbr("missing output file=$filetmp!"))
	if (! -e $filetmp);
				# move old to new

    $cmd="\\mv $filetmp $fileOutLoc";
    system($cmd);
    print "--- $sbrName: system '$cmd'\n"
	if ((defined $par{"debug"}   && $par{"debug"}) ||
	    (defined $par{"verbose"} && $par{"verbose"}));
    
    return(2,"ok $sbrName");
}				# end of hsspCorrectNaliMistake


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


