#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="concatenates many htm.RDB files into one simpler\n".
    "     \t i.e. from one row=one residue to one row=one protein\n".
    "     \t input:  file.rdb|rdb.list\n".
    "     \t output: merger\n".
#    "     \t \n".
    "     \t ";
#  
# 
#------------------------------------------------------------------------------#
#	Copyright				        	2001	       #
#	Burkhard Rost		rost@columbia.edu			       #
#	CUBIC (Columbia Univ)	http://www.columbia.edu/~rost/   	       #
#       Dept Biochemistry & Molecular Biophysics			       #
#       630 West, 168 Street						       #
#	New York, NY 10032	http://www.columbia.edu/~rost/                 #
#				version 0.1   	Nov,    	2001	       #
#------------------------------------------------------------------------------#
#

$[ =1 ;				# count from one

				# ------------------------------
				# defaults
%par=(
      '', "",			# 
      );
@kwd=sort (keys %par);
$Ldebug=0;
$Lverb= 0;

$sep=   "\t";

@kwdWant=("AA",
	  "PHL"
	  );
$trans_kwd2out{"AA"}= "seq";
$trans_kwd2out{"PHL"}="htm";

				# ------------------------------
if ($#ARGV<1){			# help
    print  "goal: $scrGoal\n";
    print  "use:  '$scrName '\n";
    print  "opt:  \n";
				#      'keyword'   'value'    'description'
    printf "%5s %-15s=%-20s %-s\n","","fileOut", "x",         "name of output file";
    printf "%5s %-15s=%-20s %-s\n","","dirOut",  "x",         "directory of output files";
    printf "%5s %-15s %-20s %-s\n","","list",    "no value",  "is list of files";

#    printf "%5s %-15s %-20s %-s\n","","html|web","no value",  "also write simple HTML table";

    printf "%5s %-15s=%-20s %-s\n","","kwd",     "AA,PHL",    "keywords of columns to use";
    printf "%5s %-15s=%-20s %-s\n","","method",  "PHD07",     "name method";

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
$Lweb=0;
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

#    elsif ($arg=~/^(web|html)$/i)         { $Lweb=           1;}

    elsif ($arg=~/^kwd=(.*)$/)            { @kwdWant=        split(/,/,$1);}

    elsif ($arg=~/^method=(.*)$/)         { $methodForce=    $1;}

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
    if (defined $methodForce){
	$fileOut="Out-".$methodForce.".rdb";
    }
    else {
	$tmp=$fileIn;$tmp=~s/^.*\///g;$fileOut="Out-".$tmp;
	$fileOut=~s/\..*//g;
	$fileOut.=".rdb";
    }
}

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
#$#chainTmp=0;
foreach $fileIn (@fileIn){
    if ( ($#fileIn==1 && $LisList) || $fileIn =~/\.list/) {
	($Lok,$msg,$file,$tmp)=
	    &fileListRd($fileIn);if (! $Lok){ print "*** ERROR $scrName: input list\n",$msg,"\n";
					      exit; }
	@tmpf=split(/,/,$file); 
	push(@fileTmp, @tmpf);
	next;}
    push(@fileTmp, $fileIn);
}
@fileIn= @fileTmp;
$#fileTmp=0;			# slim-is-in

				# --------------------------------------------------
				# (1) read file(s)
				# --------------------------------------------------
$ctfile=0;
$#id=0;
undef %method;
foreach $fileIn (@fileIn){
    ++$ctfile;
    if (! -e $fileIn){print "-*- WARN $scrName: no fileIn=$fileIn\n";
		      next;}
#    print "--- $scrName: working on '$fileIn'\n";
    printf 
	"--- $scrName: working on %-25s %4d (%4.1f perc of job)\n",
	$fileIn,$ctfile,(100*$ctfile/$#fileIn);

    open($fhin,$fileIn) || die "*** $scrName ERROR opening fileIn=$fileIn";
#    if (! $Lok){print "*** $scrName: failed to open fileIn=$fileIn\n";
#		next;}
    $id=$fileIn;
    $id=~s/^.*\///g;
    if (! defined $methodForce){
	$method=$id;
	$method=~s/^.*\.rdb//g;
	$method=~s/^[_\-\.]//g;
	$method=~tr/[A-Z]/[a-z]/;}
    else {
	$method=$methodForce;}

    $id=~s/\..*$//g;
				# add database to id
    if    ($id=~/\d[a-z0-9][a-z0-9][a-z0-9][:_\-]?[a-z0-9A-Z]?$/){
	$id="PDB|".$id;
    }
    elsif ($id=~/^[a-z0-9][a-z0-9][a-z0-9]*_[a-z0-9][a-z0-9][a-z0-9]*$/i){
	$id=~tr/[A-Z]/[a-z]/;
	$id="SWISS|".$id;
    }
    else {
	print "*** $scrName id=$id, file=$fileIn could not assign database!\n";
	exit;}
				# get method
    if (! defined $method{$id}){
	$method{$id}=$method;
	push(@id,$id);}
    else {
	$method{$id}.=",".$method;
    }
				# header
    while (<$fhin>) {
	$_=~s/\n//g;
	if ($_=~/^\#\s*HTMTOP_PRD[\s\t]+:[\s\t]*(in|out)/i){
	    $topology=$1;
	    $topology=~tr/[A-Z]/[a-z]/;
	    $rd{$id,"topology"}=$topology;
	    next;
	}
	next if ($_=~/^\#/);
				# names
	@tmp=split(/\s*\t+\s*/,$_);  
	$line=$_;
	undef %ptr;
	foreach $it (1..$#tmp){
	    foreach $kwd (@kwdWant){
		if ($tmp[$it]=~/$kwd/){ 
		    $ptr{$kwd}=$it;
		    last;}}}
				# cross check
	$Lerr=0;
	foreach $kwd (@kwdWant){
	    if (! defined $ptr{$kwd}){
		print "*** kwd=$kwd not matched ($line)\n";
		$Lerr=1;
	    }}
	if ($Lerr){ print "*** $scrName serious problem for file=$fileIn\n";
		    exit;}
	last;
    }
				# body
    foreach $kwd (@kwdWant){
	$rd{$id,$kwd}="";
    }
    while (<$fhin>) {
	$_=~s/\n//g;
				# skip format line
	next if ($_=~/\dN\s*\t/ && $_=~/\dS\s*\t/);
	next if ($_=~/^\#/);
	next if ($_=~/^\s*$/);
				# columns
	@tmp=split(/\s*\t+\s*/,$_);  
	foreach $kwd (@kwdWant){
	    $rd{$id,$kwd}.=$tmp[$ptr{$kwd}];
	}
    }
    if ($Ldebug){
	print 
	    "--- id=$id\n",
	    "---    seq=",$rd{$id,"AA"},
	    "---    htm=",$rd{$id,"PHL"},"\n";
    }
    close($fhin);
}
				# ------------------------------
				# (2) open output file
				# ------------------------------
open($fhout,">".$fileOut) || warn "*** $scrName ERROR creating fileOut=$fileOut";
@kwdOut=("id","method","topology");
foreach $kwd (@kwdWant){
    $tmp=$kwd;
    $tmp=$trans_kwd2out{$kwd} if (defined $trans_kwd2out{$kwd});
    push(@kwdOut,$tmp);
}
$wrt=join("$sep",@kwdOut,"\n");
foreach $id (@id){
    @method=split(/,/,$method{$id});
    foreach $method (@method){
	$wrt.=$id;
	$wrt.=$sep.$method;
	$topo="unk";
	$topo=$rd{$id,"topology"} if (defined $rd{$id,"topology"});
	    
	$wrt.=$sep.$topo;
	foreach $kwd (@kwdWant){
	    if (! defined $rd{$id,$kwd}){
		print "xx missing $id,$kwd\n";die;
	    }
	    $wrt.=$sep.$rd{$id,$kwd};
	}
	$wrt.="\n";
    }
}
				# ------------------------------
				# (3) write output
				# ------------------------------
open($fhout,">".$fileOut) || warn "*** $scrName ERROR creating fileOut=$fileOut";
print $fhout
    $wrt;
close($fhout);

print $wrt if ($Lverb);
    
print "--- output in $fileOut\n" if (-e $fileOut);
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
sub fileListRdChain {
    local($fileInLoc,$fhErrSbr,$extForChain,$dirLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   fileListRdChain             reads a list of files (purging chains [_:] before
#                               verifying that files exist
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
    $sbrName="lib-br:"."fileListRdChain";$fhinLoc="FHIN_"."fileListRdChain";
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
	    $tmpFile.=$file.",";$tmpChain.="*,";} # file ok 
	else {$Lok=0;$chainTmp="unk";
	      foreach $ext (@extLoc){ # check chain
		  foreach $dir ("",@dirLoc){ # check dir (first: local!)
		      $fileTmp=$file; $dir.="/"  if (length($dir)>0 && $dir !~/\/$/);
		      $fileTmp=~s/^(.*$ext)[_:]([A-Z0-9])$/$1/;
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
}				# end of fileListRdChain

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
				# file ok 
	if    (-e $file) {
	    $tmpFile.="$file,";$tmpChain.="*,";
	    print "xx ok $file\n";
	    next;
	}
				# do something
	$Lok=0;$chainTmp="unk";

	foreach $ext ("",@extLoc){ # check chain
	    foreach $dir ("",@dirLoc){ # check dir (first: local!)
		$fileTmp=$file; $dir.="/"  if (length($dir)>0 && $dir !~/\/$/);
		$fileTmp=~s/^(.*$ext)[_:]([A-Z0-9])$/$1/;
		$chainTmp=$2               if (defined $2);
		$fileTmp=$dir.$fileTmp; 
		$Lok=1  if (-e $fileTmp);
		last if $Lok;}
	    last if $Lok;}
	if ($Lok){
	    $tmpFile.="$fileTmp,";
	    $tmpChain.="*,"          if (! defined $chainTmp || $chainTmp eq "unk");
	    $tmpChain.="$chainTmp,"  if (defined $chainTmp && $chainTmp ne "unk"); 
	}
	else { 
	    print $fhErrSbr "-*- WARN $sbrName missing file=$_,\n";
	}
    }
    close($fhinLoc);
    $tmpFile=~s/^,*|,*$//g;$tmpChain=~s/^,*|,*$//g;
    return(1,"ok $sbrName",$tmpFile,$tmpChain);
}				# end of fileListRd


