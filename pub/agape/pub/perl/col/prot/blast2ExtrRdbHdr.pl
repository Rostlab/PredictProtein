#!/usr/sbin/perl4 -w
#
#  extract from BLASTP2 output
#
$[ =1 ;

				# include libraries
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
require "ctime.pl";
require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
				# initialise variables

if ($#ARGV<2){
    print"goal:   extract from BLASTP2 output (only those in restrict.list into RDB)\n";
    print"usage:  script file restrict.list (pdb ids, e.g. FullDssp.list) \n";
    print"option: fileOut=\n";
    die;}

$fileIn=   $ARGV[1];
$fileRestr=$ARGV[2];

$fhin="FHIN";$fhout="FHOUT";
if ($#ARGV>2){$ARGV[3]=~s/^fileOut=(\S+)//g;$fileOut=$1;}
else         {$fileOut="RestrBlast-".$fileIn;$fileOut=~s/\..*$//g;}

				# ------------------------------
$#id=0;				# read restriction file
&open_file("$fhin", "$fileRestr");
while (<$fhin>) {
    $_=~s/\n//g;
    $_=~s/^.*\///g;		# purge path
    $_=~s/_//g;			# purge _ chain
    $_=~s/\!//g;		# purge exclamation mark
    $_=~s/\..*$//g;		# purge extension
    if (length($_)>=4){
	push(@id,$_);}}close($fhin);

foreach $id (@id){$id=~tr/[A-Z]/[a-z]/;
		  $ok{"$id"}=1;} # store as logicals

				# ------------------------------
&open_file("$fhin", "$fileIn");	# read BLAST2 output
&open_file("$fhout",">$fileOut"); # write RDB file
print $fhout "id\tide\tlen\tscore\tprob\n";

$#idFound=0;
while (<$fhin>) {
    last if ($_=~/^Sequences producing /);}
				# --------------------
$Lhead=0;			# header
				# leaving with first line ' ' after those with 'pdb|..'
while (<$fhin>) {$_=~s/\n//g;$tmp=$_;
		 if (!$Lhead && ($_=~/^pdb/)){
		     $Lhead=1;}
		 last if (($_!~/^pdb/)&&($Lhead));
		 next;}		# xx following skipped

				# --------------------
$Lok=0;				# now ali
$ctId=$ctOk=0;			# xx
while (<$fhin>) {
    $_=~s/\n//g;
    last if ($_=~/^Parameters/);
    $line=$_;
    if ($line=~/^\>.*pdb\|/){
	$tmpId=$line;$tmpId=~s/\>.*pdb\|[^|]*\|//g;
	$tmpId=~s/-//g;$tmpId=~s/\s.*$//g;
	$tmpId=~tr/[A-Z]/[a-z]/;
	undef %res;
	if (defined $ok{"$tmpId"}){
	    $resId=$tmpId;
	    if (length($resId)>4){
		$id2=substr($resId,1,4);$tmp=substr($resId,5,1);
		$tmp=~tr/[a-z]/[A-Z]/;$id2.="_".$tmp;}
	    else {
		$id2=$resId;}
	    $resId=$id2;
	    push(@idFound,$tmpId);++$ctOk;
	    $Lok=1;}else{$Lok=0;}
	print "xx 1 id=$tmpId, $Lok, $line,\n";++$ctId;
    }
    next if (!$Lok);
    next if ($line=~/^\>.*pdb/);
    if    (($line=~/^\s*Length = (\d+)/)&&
	   (! defined $res{"len"})){
	$res{"len"}=$1;}
    elsif (($line=~/^\s*Score = ([0-9.]+)\s+[^,]*, Expect = ([0-9.e-]+).*$/)&&
	   (! defined $res{"score"})){
	$res{"score"}=$score=$1;$res{"prob"}=$prob=$2;}
				# is the last line to get for current ID
    elsif (($line=~/^\s*Identities = \d+\/\d+ \((\d+)/)&&
	   (! defined $res{"ide"})){
	$res{"ide"}=$1; 
	print "xx 2 id=$tmpId, score=$score, prob=$prob, line=$line\n";
				# ------------------------------
				# write the new output line
				# ------------------------------
	foreach $fh ("$fhout","STDOUT"){
	    print $fh $resId;
	    foreach $des ("ide","len","score","prob"){
		print $fh "\t",$res{"$des"};}print $fh "\n";}}
    else {
	next;}
}close($fhin);close($fhout);

print "--- output in $fileOut\n";
print "xx ctid=$ctId, ok=$ctOk,\n";
exit;
