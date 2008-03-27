#!/usr/bin/perl -w
##!/usr/bin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="comments ctime.pl and lib-comp.pl,  prot->br\n";
#  
#
$[ =1 ;
				# ------------------------------
				# defaults
%par=(
      '', "",			# 
      );
				# ------------------------------
if ($#ARGV<1){			# help
    print "goal:\t $scrGoal\n";
    print "use: \t '$scrName file*pl'\n";
    print "opt: \t \n";
    print "     \t fileOut=x\n";
    print "     \t dir=save     (dir to save original files)\n";
#    print "     \t \n";
    if (defined %par){
	foreach $kwd (keys %par){
	    print "     \t $kwd=",$par{"$kwd"}," (def)\n";}}
    exit;}
				# initialise variables
$fhin="FHIN";$fhout="FHOUT";
				# ------------------------------
$#fileIn=$#chainIn=0;		# read command line
foreach $arg (@ARGV){
    if    ($arg=~/^fileOut=(.*)$/)        { $fileOut=$1;}
    elsif ($arg=~/^dir=(.*)$/)            { $dirSave=$1;}
#    elsif($arg=~/^=(.*)$/){$=$1;}
    elsif (-e $arg)                       { push(@fileIn,$arg); push(@chainIn,"*");}
    elsif ($arg=~/^(\.hssp)\_([A-Z0-9])/) { push(@fileIn,$1);   push(@chainIn,$2);}
    elsif (defined %par && $#kwd>0)       { 
	$Lok=0; 
	foreach $kwd (@kwd){
	    if ($arg =~ /^$kwd=(.+)$/){$Lok=1;$par{"$kwd"}=$1;
				       last;}}
	if (! $Lok){ print "*** wrong command line arg '$arg'\n";
		     die;}}
    else { print "*** wrong command line arg '$arg'\n"; 
	   die;}}

$fileIn=$fileIn[1];
die ("missing input $fileIn\n") if (! -e $fileIn);
if (! defined $fileOut){
    $tmp=$fileIn;$tmp=~s/^.*\///g;$fileOut="Out-".$tmp;}
if (! defined $dirSave){
    $dirSave="Dsave"; }
if (! -d $dirSave){ ($Lok,$msg)=
			&sysMkdir($dirSave);
		    print "*** $scrName: mkdir dir ($dirSave), msg=",$msg,"\n" if (! $Lok);
		    if (! -d $dirSave){
			system("mkdir $dirSave");}}

				# ------------------------------
				# (1) read file(s)
foreach $fileIn(@fileIn){
    if (! -e $fileIn){print "-*- WARN $scrName: no fileIn=$fileIn\n";
		      next;}
    $fileNew="TMP-".$fileIn;
    print "--- $scrName: $fileIn (tmp=$fileNew)\n";
    open("$fhin", "$fileIn")    || die "*** $scrName ERROR opening filein=$fileIn";
    open("$fhout", ">$fileNew") || die "*** $scrName ERROR opening fileNew=$fileNew";
    $Lok=0;
    while (<$fhin>) {
	$_=~s/\n//g;$line=$_;
 	if    (! $Lok && $line=~/require/){
	    $line="# $line \n"; $Lok=1;
 	    $line.="require \"lib-ut\.pl\"\; require \"lib-br\.pl\"\;";}
 	elsif ($line=~/require/){
	    $line="# $line";}
	print $fhout "$line\n";
    }
    close($fhin); close($fhout);
				# move to save
    print "system 1 (\\mv $fileIn $dirSave)\n";
    system("\\mv $fileIn $dirSave");
    
#    $fileTmp=$fileIn;$fileTmp=~s/^(\.*\/)/$1$dir/;
#    ($Lok,$msg)= &sysMvfile($fileIn,$fileTmp);
    print "system 2 (\\mv $fileNew $fileIn)\n";
				# move new to old
    ($Lok,$msg)= &sysMvfile($fileNew,$fileIn);
    die ("failed moving $fileNew->$fileIn".$msg) if (! $Lok);
}
exit;

#===============================================================================
sub sysMkdir {
    local($argIn,$niceLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   sysMkdir                    system call 'mkdir'
#                               note: system call returns 0 if ok
#       in:                     directory, nice value (nice -19)
#       out:                    ok=(1,'mkdir a') , else=(0,msg)
#-------------------------------------------------------------------------------
    $sbrName="sysMkdir";
    $argIn=~s/\/$//   if ($argIn=~/\/$/);
    $niceLoc=""       if (! defined $niceLoc);
    $argIn=~s/\/$//g  if ($argIn =~/\/$/); # chop last '/'
    if (! -d $argIn){
	$Lok= mkdir ($argIn, "770");
	system("chmod u+rwx $argIn");
	system("chmod go+rx $argIn");
	return(0,"*** $sbrName: couldnt find or make dir '$argIn' ($Lok)!") if (! $Lok);}
    return(1,"$niceLoc mkdir $argIn");
}				# end of sysMkdir

#===============================================================================
sub sysMvfile {
    local($fileToCopy,$fileToCopyTo,$niceLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   sysMvfile                   system call '\\mv file'
#       in:                     $fileToCopy,$fileToCopyTo (or dir),$niceLoc
#       out:                    ok=(1,'mv a b') , else=(0,msg)
#-------------------------------------------------------------------------------
    $sbrName="sysMvfile";
    $niceLoc="" if (! defined $niceLoc);
    return(0,"*** $sbrName: missing input file '$fileToCopy'!") if (! -e $fileToCopy);
    return(0,"*** $sbrName: needs 2 arg 'fToCopy fToCopyTo'!")  if (! defined $fileToCopyTo);
    system("$niceLoc \\mv $fileToCopy $fileToCopyTo");
    if (! -e $fileToCopyTo){
	return(0,"*** $sbrName: couldnt copy '$fileToCopy -> $fileToCopyTo' ($Lok)!");}
    return(1,"$niceLoc \\mv $fileToCopy $fileToCopyTo");
}				# end of sysMvfile

