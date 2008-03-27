#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="sorts PDB files by resolution (command line 'nosort' -> just grep resolution)";
#  
#

$[ =1 ;
				# ------------------------------
				# defaults
%par=(
      'dirPdb',     "/home/rost/data/pdb/",
      'extPdb',     ".brk",

      'dirPdb',     "/data/pdb/",
      'extPdb',     ".pdb",
      'maxRes',     1107,	# filled it if no resolution found
      '', "",			# 
      );
@kwd=sort (keys %par);

$minRes=$par{"maxRes"};
$LnoSort=0;
				# ------------------------------
if ($#ARGV<1){			# help
    print  "goal: $scrGoal\n";
    print  "use:  '$scrName *file (or list automatically recognised by *.list)'\n";
    print  "opt:  \n";
				#      'keyword'   'value'    'description'
    printf "%5s %-15s= %-20s %-s\n","","fileOut",  "x",       "";
    printf "%5s %-15s  %-20s %-s\n","","excl",     "file",    "file with names to exclude from search";
    printf "%5s %-15s  %-20s %-s\n","","res",      "min",     "minimal resolution to consider";
#    printf "%5s %-15s  %-20s %-s\n","","",   "x", "";
    printf "%5s %-15s  %-20s %-s\n","","list",     "no value","if input file is list of FASTA files".
	                                                      " note: automatic if extension *.list!!";
    printf "%5s %-15s  %-20s %-s\n","","nosort",   "no value","will not sort resolution, simply get it!";

#    printf "%5s %-15s  %-20s %-s\n","","",   "x", "";
#    printf "%5s %-15s  %-20s %-s\n","","",   "no value","";
#    printf "%5s %-15s  %-20s %-s\n","","noScreen", "no value","";
    if (defined %par && $#kwd > 0){
	$tmp= sprintf("%5s %-15s  %-20s %-s\n","","-" x 15 ,"-" x 20,"-" x 30);
	$tmp.=sprintf("%5s %-15s  %-20s %-s\n","","other:","default settings: "," ");
	$tmp2="";
	foreach $kwd (@kwd){
	    next if (! defined $par{"$kwd"} || length($par{"$kwd"})<1 );
	    if    ($par{"$kwd"}=~/^\d+$/){
		$tmp2.=sprintf("%5s %-15s= %10d %9s %-s\n","",$kwd,$par{"$kwd"}," ","(def)");}
	    elsif ($par{"$kwd"}=~/^[0-9\.]+$/){
		$tmp2.=sprintf("%5s %-15s= %10.3f %9s %-s\n","",$kwd,$par{"$kwd"}," ","(def)");}
	    else {
		$tmp2.=sprintf("%5s %-15s= %-20s %-s\n","",$kwd,$par{"$kwd"},"(def)");} 
	} 
	print $tmp, $tmp2       if (length($tmp2)>1);
    }
    exit;}
				# initialise variables
$fhin="FHIN";
$fhout="FHOUT"; $fhoutId="FHOUTID"; $fhoutFile="FHOUT_FILE";
$LisList=0;
$#fileIn=0;
$Lverb=  1;
				# ------------------------------
				# read command line
foreach $arg (@ARGV){
#    next if ($arg eq $ARGV[1]);
    if    ($arg=~/^fileOut=(.*)$/)        { $fileOut= $1;}
    elsif ($arg=~/^dbg$/i)                { $Lverb=   1;}

    elsif ($arg=~/^res=(.*)$/)            { $minRes=  $1;}
    elsif ($arg=~/^excl=(.*)$/)           { $fileExcl=$1;}
    elsif ($arg=~/^nosort$/i)             { $LnoSort= 1;}
    elsif ($arg=~/^no$/i)                 { $LnoSort= 1;}
    elsif ($arg=~/^(\-s|silent)$/)        { $Lverb=   0;}
#    elsif ($arg=~/^=(.*)$/){ $=$1;}
    elsif ($arg=~/^list$/i)               { $LisList=        1;}
    elsif (-e $arg)                       { push(@fileIn,$arg); 
					    # automatic detection of list
					    $LisList=        1 if ($arg =~ /\.list/);}
    elsif (defined %par && $#kwd>0)       { 
	$Lok=0; 
	foreach $kwd (@kwd){ if ($arg =~ /^$kwd=(.+)$/){$Lok=1;$par{"$kwd"}=$1;
							last;}}
	if (! $Lok){ print "*** wrong command line arg '$arg'\n";
		     exit;}}
    else { print "*** wrong command line arg '$arg'\n"; 
	   exit;}}

$fileIn=$fileIn[1];
die ("missing input $fileIn\n") if (! -e $fileIn);
if (! defined $fileOut){
    $tmp=$fileIn;$tmp=~s/^.*\/|\..*$//g;$fileOut="Out-".$tmp.".tmp";
    $fileOutId=  "Out-sorted-id-".  $tmp.".list";
    $fileOutFile="Out-sorted-file-".$tmp.".list"; }
else {
    $fileOutId=  $fileOut."-sorted-id.list";
    $fileOutFile=$fileOut."-sorted-file.list"; }

				# ------------------------------
				# directories: add '/'
foreach $kwd (keys %par) {
    next if ($kwd !~/^dir/);
    next if (length($par{"$kwd"})==0 || $par{"$kwd"} eq "unk" );
    $par{"$kwd"}.="/"          if ($par{"$kwd"} !~ /\/$/);}


				# ------------------------------
				# (0) digest file (list?)
				# ------------------------------
$#fileTmp=0;
foreach $fileIn (@fileIn){
    if ( ($#fileIn==1 && $LisList) || $fileIn =~/\.list/) {
	($Lok,$msg,$file,$tmp)=
	    &fileListRd($fileIn,"STDOUT",$par{"extPdb"},$par{"dirPdb"});
	if (! $Lok){ print "*** ERROR $scrName: input list\n",$msg,"\n";
		     exit; }
	@tmpf=split(/,/,$file); 
	push(@fileTmp,@tmpf);
	next;}
    push(@fileTmp,$fileIn);
}
				# add PDB directory to ids
foreach $fileIn (@fileTmp){
    if (! -e $fileIn){
	if ($fileIn !~ /^\//){
	    $tmp=$par{"dirPdb"}.$fileIn;
	}
	if (-e $tmp){
	    $fileIn=$tmp;
	} 
	else {
	    $tmp.=$par{"extPdb"};
	}
	if (-e $tmp){
	    $fileIn=$tmp;
	} 
    }
    next if (! -e $fileIn);
}
@fileIn= @fileTmp;

$#fileTmp=0;			# slim-is-in

$ct=0; $#res=0; undef %id; undef %res; 

				# ------------------------------
				# (1) read file(s) to exclude
				# ------------------------------
if (defined $fileExcl) {
    die "*** missing file to exclude $fileExcl\n" if (! -e $fileExcl);
    print "--- $scrName: excluding names in '$fileExcl'\n";

    open($fhin, $fileExcl) ||
	die '*** $scrName ERROR opening file $fileExcl';

    while (<$fhin>) {$_=~s/\n//g;
		     $_=~s/^.*\/|\..*$//g;
		     $_=substr($_,1,4);	# store only PDB identifiers!
		     $id{$_}=1; }
    close($fhin); }
   
				# ------------------------------
				# (2) process file(s)
				# ------------------------------
$ctfileMain=0;
foreach $fileIn (@fileIn){
    if (! -e $fileIn){
	print "-*- WARN $scrName: no fileIn=$fileIn\n" if ($Lverb);
	next;}
    $id=$fileIn; $id=~s/^.*\/|\..*$//g;
    ++$ctfileMain;

				# chain to purge?
    $id=substr($id,1,4);
				# avoid duplications
    next                        if (defined $id{$id});
    $id{$id}=$ct;

    printf 
	"--- $scrName: working on %-10s %4d (%4.1f%1s)\n",
	$id,$ctfileMain,(100*$ctfileMain/$#fileIn),"%"
	    if ($Lverb);

    ($Lok,$msg,$res)=
	&pdbGrepResolution($fileIn,0,0,$par{"resMax"});
    if (! $Lok) { print "*** $scrName: failed on grepping PDB resolution from $fileIn\n",$msg,"\n"
		      if ($Lverb);
#		  exit;
		  next ; }

    next if ($res > $minRes);	# to exclude?

				# unique resolution
    if (! defined $res{$res}){
	push(@res,$res); 
	$res{$res}=""; }
    $res{$res}.="$id,";

}
				# ------------------------------
				# (3) sort
				# ------------------------------
@res=sort bynumber (@res)       if (! $LnoSort);

open($fhout,    ">".$fileOut);    print $fhout "id"."\t"."resolution (max=".$minRes.")\n";
if (! $LnoSort){
    open($fhoutId,  ">".$fileOutId);   
    open($fhoutFile,">".$fileOutFile); 
}

$ct=0;
foreach $res (@res) {
    $res{$res}=~s/,*$//g;
    @tmp=split(/,/,$res{$res});
    foreach $tmp (@tmp) {
	$file=$par{"dirPdb"}.$tmp.$par{"extPdb"};
	++$ct;
	printf "xx %-s\t%8.1f\n",$tmp,$res
		      if ($Lverb);
	printf $fhout     "%-s\t%8.1f\n",$tmp,$res; 
	if (! $LnoSort){
	    print  $fhoutId   "$tmp\n";
	    print  $fhoutFile "$file\n"; }
    }
}

if ($Lverb) {
    print "--- output in: \n";
    print "                  all info: $fileOut\n"     if (-e $fileOut);
    if (! $LnoSort){
	print "                sorted ids: $fileOutId\n"   if (-e $fileOutId);
	print "              sorted files: $fileOutFile\n" if (-e $fileOutFile);
    }
    print "--- number of proteins    : $ct\n";
    print "--- excluded were names in: $fileExcl\n"    if (defined $fileExcl);
    print "--- minimal resolution was: $minRes\n"      if ($minRes < $par{"maxRes"});
}

exit;

#===============================================================================
sub bynumber { 
#-------------------------------------------------------------------------------
#   bynumber                    function sorting list by number
#-------------------------------------------------------------------------------
    $a<=>$b; 
}				# end of bynumber

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
	if    (-e $file) {	# file ok 
	    $tmpFile.="$file,";$tmpChain.="*,";
	    next; }
				# file NOT ok
	$Lok=0;
	$chainTmp="unk";
	foreach $ext ("",@extLoc){ # check chain
	    foreach $dir ("",@dirLoc){ # check dir (first: local!)
		$fileTmp=$file; 
		$fileTmp.=$ext;
		$dir.="/"  if (length($dir)>0 && $dir !~/\/$/);
		$fileTmp=~s/^(.*$ext)\_([A-Z0-9])$/$1/
		    if ($fileTmp=~/^(.*$ext)\_([A-Z0-9])$/);
		$chainTmp=$2               if (defined $2);
		$fileTmp=$dir.$fileTmp; 
		$Lok=1  if (-e $fileTmp);
		last if $Lok;
	    }
	    last if $Lok;
	}
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

#===============================================================================
sub is_list {
    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   is_list                     returns 1 if list of existing files
#       in:                     $fileInLoc
#       out:                    1|0,msg,$LisList
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."is_list"; $fhinLoc="FHIN_"."is_list";
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
    return(&errSbr("miss in file '$fileInLoc'!"))  if (! -e $fileInLoc);
				# open file
    open($fhinLoc,$fileInLoc) || 
	return(&errSbr("fileInLoc=$fileInLoc, not opened"));
    $ct=$LisList=0;		# ------------------------------
    while (<$fhinLoc>) {	# read file
	$_=~s/\n|\s//g;
	next if ($_=~/^\#/);
	++$ct;
	$LisList=1              if (-e $_);
	last if ($LisList || $ct==2); # 2 not existing files -> say NO!
	$tmp=$_; $tmp=~s/_?[A-Z0-9]$//g; # purge chain
	$LisList=1              if (-e $tmp);
    } close($fhinLoc);
    return(1,"ok $sbrName",$LisList);
}				# end of is_list

#===============================================================================
sub pdbGrepResolution {
    local($fileInLoc,$exclLoc,$modeLoc,$resMaxLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   pdbGrepResolution           greps the 'RESOLUTION' line from PDB files
#       in:                     $fileInLoc=  file
#       in:                     $exclLoc=    limit for RESOLUTION  (0 to avoid checkin)
#       in:                     $modeLoc=    mode of to exclude 'gt|ge|lt|le'  (0 to avoid checkin)
#       in:                     $resMaxLoc=  resolution assigned if none found
#       out:                    1|0,msg,$res (0 if condition not fulfilled)
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."pdbGrepResolution";$fhinLoc="FHIN_"."pdbGrepResolution";
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
    return(&errSbr("miss in file '$fileInLoc'!"))  if (! -e $fileInLoc);
    $exclLoc=$modeLoc=0                            if (! defined $exclLoc || ! defined $modeLoc);
    $resMaxLoc=1107                                if (! defined $resMaxLoc);
				# ------------------------------
				# system call
				# ------------------------------
    $tmp=`grep 'RESOLUTION\. ' $fileInLoc`; 
				# process output
    $tmp=~s/\n//g;
    if ($tmp=~/^.*RESOLUTION\.\s*([\d\.]+) .*$/){
	$tmp=~s/^.*RESOLUTION\.\s*([\d\.]+) .*$/$1/g; $tmp=~s/\n|\s//g;}
    else {
	$tmp=$resMaxLoc;}
    $Lok=1;
				# restrict?
    if (defined $exclLoc && $exclLoc) { 
	$Lok=0  if (($modeLoc eq "gt")  && ($tmp <= $exclLoc) );
	$Lok=0  if (($modeLoc eq "ge")  && ($tmp <  $exclLoc) );
	$Lok=0  if (($modeLoc eq "lt")  && ($tmp >= $exclLoc) );
	$Lok=0  if (($modeLoc eq "le")  && ($tmp >  $exclLoc) ); }
    $tmp=0                      if (! $Lok);
    return(1,"ok $sbrName",$tmp);
}				# end of pdbGrepResolution

