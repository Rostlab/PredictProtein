#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="reads pairs.rdb, returns resolution of all pairs\n".
    "     \t also only for those input from file_include (excerpt from UNIQUE-res.dat)\n".
    "     \t note: column number where to find id1, res, id2, dis in file pairs defined in \%ptr\n".
    "     \t \n".
    "     \t also returns list sorted by res (if incl)\n";
#  
#

$[ =1 ;
				# ------------------------------
				# defaults
%par=(
      'ptrId1',    1,		# column in file pairs.rdb where the id is expected
      'ptrRes',    3,		# column in file pairs.rdb where the resolution is expected
      'ptrId2',    4,		# column in file pairs.rdb where the pair list is expected
      'ptrDis',    5,		# column in file pairs.rdb where the distance list is expected
      '', "",			# 
      );
@kwd=sort (keys %par);
				# ------------------------------
if ($#ARGV<1){			# help
    print  "goal: $scrGoal\n";
    print  "use:  '$scrName pairs.rdb'\n";
    print  "opt:  \n";
				#      'keyword'   'value'    'description'
    printf "%5s %-15s=%-20s %-s\n","","fileOut",  "x",       "";
    printf "%5s %-15s %-20s %-s\n","","incl",     "x",       "file with ids to get (first column ids)";
#    printf "%5s %-15s %-20s %-s\n","","",   "x", "";
#    printf "%5s %-15s %-20s %-s\n","","",   "no value","";

#    printf "%5s %-15s %-20s %-s\n","","noScreen", "no value","";
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
$fhin="FHIN";$fhout="FHOUT";
$LisList=0;
$#fileIn=0;$fileIncl=0;
$SEP="\t";
				# ------------------------------
				# read command line
foreach $arg (@ARGV){
#    next if ($arg eq $ARGV[1]);
    if    ($arg=~/^fileOut=(.*)$/)        { $fileOut=$1;}
    elsif ($arg=~/^incl=(.*)$/)           { $fileIncl=$1;}
#    elsif ($arg=~/^=(.*)$/){ $=$1;}
    elsif ($arg=~/^list$/i)               { $LisList=        1;}
    elsif (-e $arg)                       { push(@fileIn,$arg); 
					    # automatic detection of list
					    $LisList=        1 if ($arg =~ /\.list/); }
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
    $tmp=$fileIn;$tmp=~s/^.*\///g;$fileOut="Out-".$tmp;}

				# ------------------------------
				# directories: add '/'
foreach $kwd (keys %par) {
    next if ($kwd !~/^dir/);
    next if (length($par{"$kwd"})==0 || $par{"$kwd"} eq "unk" );
    $par{"$kwd"}.="/"          if ($par{"$kwd"} !~ /\/$/);}

				# ------------------------------
				# (0) ids to include?
				# ------------------------------
print "--- $scrName: working on file to include '$fileIncl'\n";
undef %incl;
$ctWant=0;

open("$fhin","$fileIncl") || die '*** $scrName ERROR opening file $fileIncl';
while (<$fhin>) {
    $_=~s/\n//g;
    $_=~s/^.*\///g;

    next if ($_=~/^\#/); # skip comments
    next if ($_=~/^id/); # skip names

    $_=~s/^(\S+)[\s\t]*.*$//;
    $id=$1;
    $incl{$id}=1;
    ++$ctWant;
} close($fhin);

				# ------------------------------
				# (1) read file pairs
				# ------------------------------
print "--- $scrName: working on '$fileIn'\n";

undef %res; undef %dis; undef %id2;
$#idFound=0;

$ctGot=0;
open("$fhin","$fileIn") || die '*** $scrName ERROR opening file $fileIn';
while (<$fhin>) {
    $_=~s/\n//g;
    $_=~s/^.*\///g;

    next if ($_=~/^\#/); # skip comments
    next if ($_=~/^id/); # skip names

    @tmp=split(/[\s\t]+/,$_);  foreach $tmp (@tmp){$tmp=~s/\s//g;}
    $id=      $tmp[$par{"ptrId1"}];
    $res=     $tmp[$par{"ptrRes"}];
    $res{$id}=$res;
				# take it?
    next if (%incl && ! defined $incl{$id});

    ++$ctGot;
    push(@idFound,$id);
    $dis= $tmp[$par{"ptrDis"}]; 
    $id2= $tmp[$par{"ptrId2"}];
    $dis{$id}=$dis;
    $id2{$id}=$id2; 
} close($fhin);

				# ------------------------------
				# (2) write sorted res
				# ------------------------------
$fileOutSort=$fileOut."_sorted";
open("$fhout",">$fileOutSort") || warn '*** $scrName ERROR creating fileOutSort=$fileOutSort';
printf $fhout "%-s$SEP%6s\n","id1","res";
$#tmp=0;undef %tmp;
foreach $id1 (@idFound) {
    if (! defined $tmp{$res{$id1}}){
	push(@tmp,$res{$id1});
	$tmp{$res{$id1}}=$id1."\t";}
    else {
	$tmp{$res{$id1}}.=$id1."\t";}
}
foreach $res (sort @tmp){
    $tmp{$res}=~s/\t$//g;
}

foreach $res (sort @tmp){
    @id=split(/\t/,$tmp{$res});
    
    foreach $id1 (@id) {
	$tmpWrt=sprintf("%-s$SEP%6.1f\n",$id1,$res);
	print $fhout $tmpWrt;
	print $tmpWrt;
    }
}
close($fhout);

				# ------------------------------
				# (3) process ids found
				# ------------------------------
open("$fhout",">$fileOut") || warn '*** $scrName ERROR creating file $fileOut';
printf $fhout 
    "%-s$SEP%6s$SEP%-s$SEP%6s$SEP%4s\n",
    "id1","res1","id2","res2","dist";
    
foreach $id1 (@idFound) {
    next if (! defined $id2{$id1});
				# find all homologues
    
    @id2= split(/,/,$id2{$id1}); 
    next if ($#id2 == 0);	# none found
    @dis= split(/,/,$dis{$id1}); 

				# loop over all homologues
    foreach $it (1..$#id2) {
	$id2=$id2[$it];
				# skip if no resolution defined for 2nd
	next if (! defined $res{$id2});	

	next if ($res{$id2} > 3); # hack
	
	$tmpWrt=sprintf("%-s$SEP%6.1f$SEP%-s$SEP%6.1f$SEP%4d\n",
			$id1,$res{$id1},$id2,$res{$id2},$dis[$it]);
	print $fhout $tmpWrt;
	print $tmpWrt;
    }
    
}
close($fhout);

print "--- output in $fileOut\n" if (-e $fileOut);
print "---    sorted=$fileOutSort\n" if (-e $fileOutSort);
print "--- wanted $ctWant, got $ctGot\n";
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
    &open_file("$fhinLoc","$fileInLoc") ||
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
sub open_file {
    local ($file_handle,$file_name,$log_file) = @_ ;
    local ($temp_name) ;
#-------------------------------------------------------------------------------
#   open_file                  opens file, writes warning asf
#-------------------------------------------------------------------------------
    $temp_name = $file_name ;
    $temp_name =~ s/^>>|^>//g ;
    if ( ($file_name =~ /^>>/ ) && ( ! -e $temp_name ) ) {
	print "*** INFO (open_file): append file=$temp_name, does not exist-> create it\n" ;
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

