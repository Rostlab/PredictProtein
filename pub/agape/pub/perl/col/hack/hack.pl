#!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="".
    "     \t";
#  
#
$[ =1 ;
				# include libraries
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
require "ctime.pl";
require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
				# help
if ($#ARGV<1){
    print "goal:\t $scrGoal\n";
    print "use: \t '$scrName'\n";
    print "opt: \t \n";
    print "     \t fileOut=x\n";
#    print "     \t \n";
    exit;}
				# initialise variables
$fhin="FHIN";$fhout="FHOUT";
				# read command line
$fileIn=$ARGV[1];
$tmp=~s/^.*\///g;$fileOut="Out-".$tmp;

foreach $_(@ARGV){
    next if ($_ eq $ARGV[1]);
    if   ($_=~/^fileOut=(.*)$/){$fileOut=$1;}
    elsif($_=~/^=(.*)$/){$=$1;}
    else {print"*** wrong command line arg '$_'\n";
	  die;}}

				# ------------------------------
				# (1) read file
&open_file("$fhin", "$fileIn");
while (<$fhin>) {
    $_=~s/\n//g;
    $_=~s/^.*\///g;		# purge directory
}
close($fhin);

				# ------------------------------
				# (2) 

				# ------------------------------
				# write output
&open_file("$fhout",">$fileOut"); 
close($fhout);

print "--- output in $fileOut\n";
exit;
