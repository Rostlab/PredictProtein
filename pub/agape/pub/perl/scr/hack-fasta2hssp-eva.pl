#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="produce final EVA hssp from fasta\n".
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
      'exeBlastpgp',      "/home/dudek/pub/blastpgp.pl",
      'exeFilterHssp',    "/home/rost/perl/scr/hssp_filter.pl",
      'exeFilterSaf',     "/home/rost/perl/scr/safFilterRed.pl",
      'exeCopf',          "/home/rost/perl/scr/copf.pl",
      'exeFilter',        "/home/rost/perl/scr/hssp_filter.pl",
      'exeDsspMerge',     "/home/rost/perl/scr/dsspMerge2hssp.pl",
      '',   "",
      'dirDssp',          "/data/dssp/",
      '',   "",

      'extDssp',          ".dssp",
      'extHssp',          ".hssp",
      'extHsspnostr',     ".hsspnostr",
      'extBlastpgp',      ".blastpgp",
      'extBlastmat',      ".blastmat",
      'extSaf',           ".saf",
      'extSaffil',        ".saffil",

      'fileErrBlast',     "MISS-blast",
      'fileErrSaf',       "MISS-saf",
      'fileErrSaffil',    "MISS-saffil",
      'fileErrHsspnostr', "MISS-hsspnostr",
      'fileErrHssp',      "MISS-hssp",
      'fileErrDssp',      "MISS-dssp",

      '',   "",
      );
@kwd=sort (keys %par);
$Ldebug=0;
$Lverb= 0;
				# ------------------------------
if ($#ARGV<1){			# help
    print  "goal: $scrGoal\n";
    print  "use:  '$scrName <*.f|fasta.list>'\n";
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
				# clean up old files
foreach $kwd ("Blast","Saf","Saffil",
	      "Hsspnostr","Hssp","Dssp"){
    $tmp="fileErr".$kwd;
    unlink($par{$tmp})          if (-e $par{$tmp});
}
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
foreach $kwd ("blastmat","blastpgp",
	      "saf","saffil",
	      "hsspnostr","hssp","dssp"){
    $ct{$kwd}=0;}
$ct=0;
foreach $fileIn (@fileIn){
    ++$ct;
    if (! -e $fileIn){print "-*- WARN $scrName: no fileIn=$fileIn\n";
		      next;}
#    print "--- $scrName: working on '$fileIn'\n";
    printf "--- $scrName: working on %-25s %4d (%4.1f perc of job)\n",$fileIn,$ct,(100*$ct/$#fileIn);
    $id=$fileIn; 
    $id=~s/^.*\///g;
    $id=~s/\..*$//g;
				# 1 blast
    $fileOutBlast=   $id.$par{"extBlastpgp"};
    $fileOutBlastMat=$id.$par{"extBlastmat"};
    $fileOutSaf=     $id.$par{"extSaf"};
    $cmd= $par{"exeBlastpgp"}." ".$fileIn;
    $cmd.=" fileOut=".$fileOutBlast." saf=".$fileOutSaf." mat=".$fileOutBlastMat;
    $cmd.=" red=80";
    print "--- system '$cmd'\n" if ($Lverb);
    system("$cmd") if (! -e $fileOutBlast);
    if (! -e $fileOutBlast){
	print "*** ERROR missing blast=$fileOutBlast\n","--- system call was '$cmd'\n";
	system("echo $fileIn >> ".$par{"fileErrBlast"});
	next; }
    ++$ct{"blastpgp"};
    ++$ct{"blastmat"}           if (-e $fileOutBlastMat);

				# 2 filter saf
    $fileOutSaffil=$id.$par{"extSaffil"};
    $cmd=$par{"exeFilterSaf"}." ".$fileOutSaf." fileOut=".$fileOutSaffil." red=80";
    if (! -e $fileOutSaf){
	print "*** ERROR missing saf=$fileOutSaf\n";
	system("echo $fileOutBlast >> ".$par{"fileErrSaf"});
	next; }
    ++$ct{"saf"};

    print "--- system '$cmd'\n" if ($Lverb);
    system("$cmd");
    if (! -e $fileOutSaffil){
	print "*** ERROR missing saffil=$fileOutSaflil\n","--- system call was '$cmd'\n";
	system("echo $fileOutSaf >> ".$par{"fileErrSaffil"});
	next; }
    ++$ct{"saffil"};
				# 3 convert to HSSp
    $fileOutHsspnostr=   $id.$par{"extHsspnostr"};
    $cmd=$par{"exeCopf"}." ".$fileOutSaffil." hssp fileOut=".$fileOutHsspnostr;
    print "--- system '$cmd'\n" if ($Lverb);
    system("$cmd");
    if (! -e $fileOutHsspnostr){
	print "*** ERROR missing hsspno=$fileOutHsspnostr\n","--- system call was '$cmd'\n";
	system("echo $fileOutSaffil >> ".$par{"fileErrHsspnostr"});
	next; }
    ++$ct{"hsspnostr"};
				# 4 merge with DSSP
    $fileOutHssp=   $id.$par{"extHssp"};
    $idnochn=$id; $idnochn=~s/[_:].//g if ($idnochn=~/[_:].$/);

    $fileDssp=      $par{"dirDssp"}.$idnochn.$par{"extDssp"};
    $cmd= $par{"exeDsspMerge"}." ".$fileOutHsspnostr;
    $cmd.=" dssp=".$fileDssp." fileOut=".$fileOutHssp;
    if (! -e $fileDssp){
	print "*** ERROR missing dssp=$fileDssp\n";
	system("echo $fileDssp >> ".$par{"fileErrDssp"});
	next; }
    ++$ct{"dssp"};
    print "--- system '$cmd'\n" if ($Lverb);
    system("$cmd");
    if (! -e $fileOutHssp){
	print "*** ERROR missing hsspfin=$fileOutHssp\n","--- system call was '$cmd'\n";
	system("echo $fileOutHssp >> ".$par{"fileErrHssp"});
	next; }
    ++$ct{"hssp"};
}
				# ------------------------------
				# final statistics
printf "--- ended fine on %-10s %5d\n","Nfasta",$#fileIn;
foreach $kwd ("blastmat","blastpgp",
	      "saf","saffil",
	      "hsspnostr","hssp","dssp"){
    printf "--- ended fine on %-10s %5d\n","N".$kwd,$ct{$kwd};
}

$err="";
foreach $kwd ("Blast","Saf","Saffil",
	      "Hsspnostr","Hssp","Dssp"){
    $tmp="fileErr".$kwd;
    if (-e $par{$tmp}){
	$err.=$kwd.",";}}

if (length($err)>1){
    $err=~s/,$//g;
    print "--- ERRORS in the following files: \n";
    @tmp=split(/,/,$err);
    foreach $tmp (@tmp){
	$kwd="fileErr".$tmp;
	print "--- $tmp file=",$par{$kwd},"\n";
    }}
else {
    print "--- no errors!\n";}
exit;


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

