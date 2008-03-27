#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="returns list of proteins with HTM in SWISS-PROT\n".
#    "     \t \n".
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
      'dirSwiss', "/data/swissprot/current/",
      '', "",			# 
      );
@kwd=sort (keys %par);
$Ldebug=0;
$Lverb= 0;
				# ------------------------------
if ($#ARGV<1){			# help
    print  "goal: $scrGoal\n";
    print  "use:  '$scrName swissprot-id|file|list-thereof'\n";
    print  "opt:  \n";
				#      'keyword'   'value'    'description'
    printf "%5s %-15s=%-20s %-s\n","","fileOut", "x",       "name of output file";
#    printf "%5s %-15s=%-20s %-s\n","","dirOut",  "x",       "directory of output files";
    printf "%5s %-15s %-20s %-s\n","","list",    "no value","is list of files OR ids";

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
    elsif ($arg=~/^list$/)                { $LisList=        1;}
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

$fileIn=$fileIn[1];
die ("missing input $fileIn\n") if (! -e $fileIn);
if (! defined $fileOut){
    $tmp=$fileIn;$tmp=~s/^.*\///g;
#    $fileOut="Out-".$tmp;
    foreach $kwd ("htm","not","id","cause"){
	$fileOut{$kwd}="Out$kwd-".$tmp;}}
else {
    foreach $kwd ("htm","not","id","cause"){
	if ($kwd eq "htm"){
	    $fileOut{$kwd}=$fileOut;}
	else {
	    $fileOut{$kwd}=$fileOut."-$kwd";}}}


				# ------------------------------
				# (0) digest file (list?)
				# ------------------------------
$#fileTmp=0;
foreach $fileIn (@fileIn){
    if ( ($#fileIn==1 && ! $LisList) && $fileIn !~/\.list/) {
	push(@fileTmp,$fileIn);
	next;}
    ($Lok,$msg,$file)=
	&fileListRd($fileIn);   if (! $Lok){ print "*** ERROR $scrName: after input list\n",$msg,"\n";
					     exit; }
    push(@fileTmp,split(/,/,$file));}
@fileIn= @fileTmp;
$#fileTmp=0;			# slim-is-in
				# ------------------------------
				# (1) read file(s)
				# ------------------------------
$#fileFound=$#fileNot=0;
$ct=0;
foreach $fileIn (@fileIn){
    ++$ct;
				# perhaps id
    if (! -e $fileIn && 
	$fileIn =~/^[a-z0-9]+\_[a-z0-9]+$/i){
	$id=$fileIn;
	$id=~tr/[A-Z]/[a-z]/;
	$tmp=$id; $tmp=~s/^[^\_]+\_(.).*$/$1/g;
	$fileIn=$par{"dirSwiss"}.$tmp."/".$id;}
				# no id no existing, no nothing!
    if (! -e $fileIn){
	print "-*- WARN $scrName: no fileIn=$fileIn\n";
	next;}
#    print "--- $scrName: working on '$fileIn'\n";
    printf "--- $scrName: working on %-25s %4d (%4.1f perc of job)\n",$fileIn,$ct,(100*$ct/$#fileIn);
    open($fhin,$fileIn) || die "*** $scrName ERROR opening file $fileIn";
    $Lfound=0;
    while (<$fhin>) {
	chop;
	last if ($_=~/^SQ/);
	next if ($_!~/^FT\s+TRANSMEM/);
	$cause{$fileIn}=$_;
	$Lfound=1;
    }
    close($fhin);
    push(@fileFound,$fileIn)    if ($Lfound);
    push(@fileNot,$fileIn)      if (! $Lfound);
}
				# ------------------------------
				# (2) write output
				# ------------------------------
foreach $kwd ("htm","not","id","cause"){
    $fileOut=$fileOut{$kwd};
    open($fhout,">".$fileOut) || warn "*** $scrName ERROR creating $kwd fileOut=$fileOut";
    if ($kwd eq "htm"){		# write list of files with HTM
	foreach $file (@fileFound){
	    print $fhout $file,"\n";
	}}
    elsif ($kwd eq "not"){	# write list of files with NO HTM
	foreach $file (@fileNot){
	    print $fhout $file,"\n";
	}}
    elsif ($kwd eq "id"){	# write list of ids with HTM
	foreach $file (@fileFound){
	    $id=$file;
	    $id=~s/^.*\///g; 
	    print $fhout $id,"\n";
	}}
    elsif ($kwd eq "cause"){	# write FT line
	foreach $file (@fileFound){
	    print $fhout $file,"\t",$cause{$file},"\n";
	}}
    close($fhout);}

print "--- ids with HTM      ".sprintf("%5s"," ").": ".$fileOut{"id"}."\n" if (-e $fileOut{"id"});
print "--- FT lines with HTM ".sprintf("%5s"," ").": ".$fileOut{"cause"}."\n" if (-e $fileOut{"cause"});
print "--- files with HTM    ".sprintf("%5d",$#fileFound).": ".$fileOut{"htm"}."\n" if (-e $fileOut{"htm"});
print "--- files with NO HTM ".sprintf("%5d",$#fileNot)  .": ".$fileOut{"not"}."\n" if (-e $fileOut{"not"});
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
    local($fileInLoc,$fhErrSbr) = @_ ;
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
				# ------------------------------
				# open file
    open($fhinLoc,$fileInLoc) ||
	return(0,"*** ERROR $sbrName: fileIn=$fileInLoc, not opened\n",0);

    $tmpFile="";		# ------------------------------
    while (<$fhinLoc>) {	# read list
	$_=~s/\n|\s//g; 
	next if (length($_)==0);
	$tmpFile.="$_,";
    }close($fhinLoc);
    $tmpFile=~s/^,*|,*$//g;
    return(1,"ok $sbrName",$tmpFile);
}				# end of fileListRd


