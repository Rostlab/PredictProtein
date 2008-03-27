#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="splits big database into many FASTA files";
#  
#
#  
#------------------------------------------------------------------------------#
#	Copyright				        	1997	       #
#	Burkhard Rost		rost@columbia.edu			       #
#	Jinfeng Liu Rost	liu@dodo.cpmc.columbia.edu		       #
#	CUBIC (Columbia Univ)	http://www.columbia.edu/~rost/   	       #
#       Dept Biochemistry & Molecular Biophysics			       #
#       630 West, 168 Street						       #
#	New York, NY 10032	http://www.dodo.cpmc.columbia.edu/~rost/       #
#				version 0.1   	xxx,    	1997	       #
#				version 0.2   	Apr,    	1998	       #
#				version 0.21   	Jul,    	1999	       #
#------------------------------------------------------------------------------#
#

$[ =1 ;
				# ------------------------------
				# defaults
				# ------------------------------
if ($#ARGV<1){			# help
    print  "goal: $scrGoal\n";
    print  "use:  '$scrName fastaMul'\n";
    print  "               keyword 'list' to digest lists (or extension .list) !!\n";
    print  "opt:  \n";
				#      'keyword'   'value'    'description'
    printf "      %-15s= %-20s %-s\n","fileOut",  "x",       "";
    printf "      %-15s  %-20s %-s\n","list",   "no value",  "";
    printf "      %-15s  %-20s %-s\n","swiss",  "no value",  "split into: /split/o/prog_org";
    printf "      %-15s  %-20s %-s\n","trembl", "no value",  "split into: /split/a/af000_1";
#    printf "      %-15s  %-20s %-s\n","noScreen", "no value","";
#    printf "      %-15s  %-20s %-s\n","",   "","";
#    printf "      %-15s  %-20s %-s\n","",   "no value","";
    exit;}
				# initialise variables
$fhin="FHIN";$fhout="FHOUT";
$#fileIn=0;
$LisList=0;
$Lswiss=$Ltrembl=0;
				# ------------------------------
				# read command line
foreach $arg (@ARGV){
#    next if ($arg eq $ARGV[1]);
    if    ($arg=~/^fileOut=(.*)$/)        { $fileOut=  $1;}
    elsif ($arg=~/^swiss$/)               { $Lswiss=   1;}
    elsif ($arg=~/^trembl$/)              { $Ltrembl=  1;}
#    elsif ($arg=~/^=(.*)$/){ $=$1;}
    elsif (-e $arg)                       { push(@fileIn,$arg); }
    elsif ($arg=~/^list$/)                { $LisList=  1;}
    else { print "*** wrong command line arg '$arg'\n"; 
	   die;}}

$fileIn=$fileIn[1];
die ("missing input $fileIn\n") if (! -e $fileIn);
if (! defined $fileOut){
    $tmp=$fileIn;$tmp=~s/^.*\///g;$fileOut="Out-".$tmp;}
				# ------------------------------
				# (0) digest file (list?)
				# ------------------------------
$#fileTmp=0;
foreach $fileIn (@fileIn){
    if ($LisList || $fileIn=~/list$/){
	open("$fhin", "$fileIn") || die '*** $scrName ERROR opening file $fileIn';
	while (<$fhin>) {$_=~s/\n//g;
			 push(@fileTmp,$_); }
	close($fhin); }
    else {
	push(@fileTmp,$fileIn);} }

@fileIn= @fileTmp; 


$#fileOut=0;
				# ------------------------------
				# (1) read file(s)
$id=0;$ctFileOut=0;
foreach $fileIn (@fileIn){
    if (! -e $fileIn){print "-*- WARN $scrName: no fileIn=$fileIn\n";
		      next;}
    print "--- $scrName: working on '$fileIn'\n";

				# open db
    open($fhin,$fileIn) ||
	do { print "*** ERROR $scrName: old '$fileIn' not opened\n";
	     next; };

    $Lwrt=0;
				# ------------------------------
				# read db file
    while (<$fhin>){
				# write if not ID
	if ($Lwrt && $_!~/^\s*>/) {
	    print $fhout $_; 
	    next; }
				# new ID -> reset flag 
	$Lwrt=0;
	if ($_=~/^\s*>/) {
				# first close old
	    if ($id) {
		++$ctFileOut;
		close($fhout);}       

	    $idLong=$_; $idLong=~s/\n//g;
	    $id=$idLong;
	    $id=~s/^\s*>\s*(\S+).*$/$1/g;
	    $dbTmp=$id; $dbTmp=~s/^([^\|]*)\|.*$/$1/g;
            if ($id =~ /\|$/) {chop $id;} # only modification from the original
	    $id=~s/^.*\|//g; 
				# if PDB: shorten name
	    if (defined $dbTmp && length($dbTmp)>1 &&
		$dbTmp =~ /(hssp|dssp|pdb)/i) {
		$idLong=substr($idLong,1,80);}
				# convert CASE (upper to lower)
	    else {
		$id=~tr/[A-Z]/[a-z]/; }
	    $id=~s/\./_/g;

	    $fileOut=$id.".f";
	    $fileOut=~s/[\s\>]//g;
	    if    ($Lswiss) {
		$tmp=$id; $tmp=~s/^[^_]*_(\w).*$/$1/;
		$tmp=~tr/[A-Z]/[a-z]/;
		$subDir=$tmp;
		system("mkdir $subDir") if (! -d $subDir);
		$subDir.="/"; 
		$fileOut=$subDir.$fileOut;}
	    elsif ($Ltrembl) {
		$tmp=substr($id,1,1);
		$tmp=~tr/[A-Z]/[a-z]/;
		$subDir=$tmp;
		system("mkdir $subDir") if (! -d $subDir);
		$subDir.="/"; 
		$fileOut=$subDir.$fileOut;}
		
	    open($fhout,">".$fileOut) ||
		do { print "*** $scrName: failed opening fileout=$fileOut, for id=$id\n";
		     next; };
	    $Lwrt=1;
	    print $fhout $idLong,"\n"; }
    }
    close($fhin);
}
close($fhout);			# close last

print "--- number of output files=$ctFileOut\n";

exit;

