#!/usr/sbin/perl4 -w
#
#  extract from BLASTP output
#
$[ =1 ;

				# include libraries
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
require "ctime.pl";
require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
				# initialise variables

if ($#ARGV<2){print"goal:   extract from BLASTP output (only those in restrict.list into RDB)\n";
	      print"usage:  script file restrict.list (pdb ids) \n";
	      print"option: fileOut=\n";
	      exit;}

$fileIn=   $ARGV[1];
$fileRestr=$ARGV[2];

$fhin="FHIN";$fhout="FHOUT";
if ($#ARGV>2){
    $ARGV[3]=~s/^fileOut//g;$fileOut=$ARGV[3];}
else {
    $fileOut="RestrBlast-".$fileIn;$fileOut=~s/\..*$//g;}

				# ------------------------------
				# read restriction file
&open_file("$fhin", "$fileRestr");$#id=0;
while (<$fhin>) {
    $_=~s/\n//g;
    $_=~s/^.*\///g;		# purge path
    $_=~s/_//g;			# purge _ chain
    $_=~s/\!//g;		# purge exclamation mark
    $_=~s/\.dssp//g;		# purge extension
    if (length($_)>=4){push(@id,$_);}}close($fhin);
foreach $id (@id){$id=~tr/[A-Z]/[a-z]/;
		  $ok{"$id"}=1;}
				# ------------------------------
				# read BLAST
&open_file("$fhin", "$fileIn");
$#idFound=0;
while (<$fhin>) {last if ($_=~/^Sequences producing /);}
				# header
$Lhead=0;
while (<$fhin>) {$_=~s/\n//g;$tmp=$_;
		 if (!$Lhead && ($_=~/^pdb/)){
		     $Lhead=1;}
		 last if (($_!~/^pdb/)&&($Lhead));
		 next;		# xx following skipped
		 $tmpId=$_;$tmpId=~s/pdb\|[^|]*\|//g;$tmpId=~s/-//g;$tmpId=~s/\s.*$//g;
		 $tmpId=~tr/[A-Z]/[a-z]/;
		 $tmp2=substr($_,61);$tmp2=~s/^\s*|\s*$//g;
		 @tmp=split(/\s+/,$tmp2);
		 if (defined $ok{"$tmpId"}){
		     push(@idFound,$tmpId);
		     $head{"score","$tmpId"}=$tmp[1];
		     $head{"prob","$tmpId"}=$tmp[2];
		 }}
				# now ali
$Lok=0;
while (<$fhin>) {$_=~s/\n//g;
		 last if ($_=~/^Parameters/);
		 $line=$_;
		 if ($line=~/^\>.*pdb/){
		     $tmpId=$line;$tmpId=~s/\>.*pdb\|[^|]*\|//g;$tmpId=~s/-//g;$tmpId=~s/\s.*$//g;
		     $tmpId=~tr/[A-Z]/[a-z]/;
		     if (defined $ok{"$tmpId"}){
			 push(@idFound,$tmpId);
			 $Lok=1;}else{$Lok=0;}}
		 next if (!$Lok);
		 next if ($line=~/^\>.*pdb/);
		 if    (($line=~/^\s*Length = (\d+)/)&&(! defined $head{"len","$tmpId"})){
		     $head{"len","$tmpId"}=$1;}
		 elsif (($line=~/ Identities = \d+\/\d+ \((\d+)/)&&
			(! defined $head{"ide","$tmpId"})){
		     print "xx ide=$1, line=$line\n";
		     $head{"ide","$tmpId"}=$1;}
		 elsif (($line=~/ Score = ([0-9.]+)\s+[^,]*, Expect = ([0-9.e-]+).*$/)&&
			(! defined $head{"score","$tmpId"})){
		     print "xx score=$1, prob=$2\n";
		     $head{"score","$tmpId"}=$1;
		     $head{"prob","$tmpId"}= $2;
		     print "xx id=$tmpId, score=$1, prob=$2, line=$line\n";
		 }
		 else {
		     next;}}close($fhin);

&open_file("$fhout",">$fileOut"); 
foreach $fh("$fhout","STDOUT"){
    print $fh "id\tide\tlen\tscore\tprob\n";
    foreach $id (@idFound){
	if (length($id)>4){
	    $id2=substr($id,1,4);$tmp=substr($id,5,1);$tmp=~tr/[a-z]/[A-Z]/;$id2.="_".$tmp;}
	else {
	    $id2=$id;}
	print $fh $id2;
	foreach $des ("ide","len","score","prob"){
	    print $fh "\t",$head{"$des","$id"};}print $fh "\n";}
}
close($fhout);

print "--- output in $fileOut\n";
exit;
