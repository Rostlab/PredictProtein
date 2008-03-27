#!/usr/pub/bin/perl -w
#
#  
#
$[ =1 ;
				# include libraries
require "/home/phd/ut/perl/ctime.pl";
require "/home/phd/ut/perl/lib-prot.pl";
require "/home/phd/ut/perl/lib-ut.pl";
require "/home/phd/ut/perl/lib-comp.pl";

$dirPred="/home/phd/server/pred/";
opendir(X,$dirPred);@FL=readdir(X);closedir(X);$maxhours=0;
$ct=0;
if($#FL>2){
    for $f (@FL) {
	next if ($f=~/^\./);
	++$ct;
	$hours=24.0*(-C "$dirPred/$f");
	print "xx maxhour=$maxhours, hours=$hours,\n";
	$maxhours=$hours if $hours>$maxhours;
	$req++;}$maxhours=~s/\s|\n//g;
    printf  "--- %-35s %-3.1f\n","Estimated time in queue (hours)",($maxhours+($ct/10)*0.1);}
exit;

				# help
if ($#ARGV<1){print "goal:    \n";
	      print "usage:   script \n";
	      print "options: \n";
	      print "         fileOut=x\n";
	      print "         \n";
	      print "         \n";
	      exit;}
				# initialise variables
$fhin="FHIN";$fhout="FHOUT";
				# read command line
$fileIn=$ARGV[1];
$fileOut="Out-".$fileIn;

foreach $_(@ARGV){
    if   ($_=~/^fileOut=(.*)$/){$fileOut=$1;}
    elsif($_=~/^fileOut2=(.*)$/){$fileOut=$1;}
    else {print"*** wrong command line arg '$_'\n";
	  die;}}


&open_file("$fhin", "$fileIn");
while (<$fhin>) {
    $_=~s/\n//g;
}
close($fhin);

&open_file("$fhout",">$fileOut"); close($fhout);

print "--- output in $fileOut\n";
exit;
