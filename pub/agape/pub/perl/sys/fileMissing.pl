#!/usr/bin/perl -w
$[ =1 ;
# removes moves all files in input file, or by date
if ($#ARGV<1){ print "goal:    (1) returns list of missing files\n";
	       print "         (2) finds all files in DIR, compares to FILE, and\n";
	       print "             writes a file with all those from FILE missing in DIR\n";
	       print "note:    extensions ignored, i.e., 1ppt.hssp matches 1ppt.f\n";
	       print "usage:   'script FILE DIR'\n";
	       print "option:  fileOut=x  (default: new-FILE)\n";
	       print "         ext=dssp   (to keep the chain 1cse.dssp_!_A -> 1cseA)\n";
	       print "         \n";
	      exit;}
$file=$ARGV[1];
if ($#ARGV > 2 && -d $ARGV[2]){
    $dir= $ARGV[2]; if ($dir !~/\/$/){$dir.="/";} # add slash
} else { $dir=""; }

foreach $_(@ARGV){
    if    ($_=~/^fileOut=(.+)/){$fileOut=$1;}
    elsif ($_=~/^ext=(.+)/)    {$ext=$1;}
}
				# check command line
if (!defined $file || ! -e $file){
    print "*** you HAVE to give an existing file with the list-of-files (1st arg)\n";
    die;}
if (! defined $fileOut){
    $fileOut="new-".$file;}

print "--- --------------------------------------------------\n";
print "--- settings:\n";
print "--- dir     \t '$dir'\n";
print "--- file    \t '$file'\n";
print "--- ext     \t '$ext'\n" if (defined $ext);
print "--- fileOut \t '$fileOut'\n";
print "--- \n";
				# ------------------------------
$#fileIn=0;$fhin="FHIN";	# read wanted-list
open ("$fhin", "$file");
$ctWanted=0;
while (<$fhin>)      {
    $_=~s/\n//g; $_=~s/\s//g;
    ++$ctWanted;
#		      $_=~s/^.*\///g; # remove path
    push(@fileIn,$_);}close($fhin);

				# ------------------------------
				# (1) only check existence
				# ------------------------------
if (! defined $dir || length($dir) < 1 || ! -d $dir) {
    open (FHOUT, ">$fileOut");
    $ctMissing=0;
    foreach $file (@fileIn) {
	if (! -e $file) {
	    ++$ctMissing;
	    print FHOUT "$file\n";}}
    close(FHOUT);
    print "--- list of missing files in=$fileOut\n";
    print "--- files   wanted=$ctWanted\n";
    print "--- files  missing=$ctMissing\n";
    exit; }
				# ------------------------------
				# (2) check dir
				# ------------------------------

@list=`ls -1 $dir`;		# list all files in dir

foreach $list(@list) {
    $list=~s/\n//g; $list=~s/\s//g;
    $list=~s/^.*\///g; # remove path
    if (defined $ext && ($list =~ /$ext/)){ # keep chain
	$list=~s/\.$ext|[_!]*//g; }
    else{	# remove extensions
	$list=~s/\..*$//g;} 
    $ok{"$list"}=1;}
				# ------------------------------
				# now compare
open (FHOUT, ">$fileOut");
foreach $want(@fileIn){
    $tmp=$want;$tmp=~s/^.*\///g; # remove path
    if ((defined $ext) && ($tmp =~ /$ext/)){ # keep chain
	$tmp=~s/\.$ext|[_!]//g;}
    else{	# remove extensions
	$tmp=~s/\..*$//g;} 
    printf "xx %-8s  %-s\n",$tmp,$want;
    if (defined $ok{"$tmp"}){
	print "                 ok $want\n";
	next;}
    print FHOUT "$want\n";
#    print "xx again: $want\n";
}close(FHOUT);

print "--- list missing files in=$fileOut\n";
exit;
