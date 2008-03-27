#!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="deletes empty HSSP files";
#  
#
$[ =1 ;
				# include libraries
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
# require "ctime.pl"; 
require "lib-ut.pl"; require "lib-br.pl";
# require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
				# help
if ($#ARGV<1){
    print "goal:\t $scrGoal\n";
    print "use: \t '$scrName fileHssp (or *)'\n";
    exit;}
				# initialise variables
$#fileIn=0;			# read command line
foreach $_(@ARGV){
    next if (! -e $_);
    push(@fileIn,$_);}
				# ------------------------------
$ct=0;				# detect /delete
foreach $fileIn(@fileIn){
    if (&is_hssp_empty($fileIn)){
	++$ct;
	print "--- delete $fileIn\n";
	unlink($fileIn);}}
print "--- no of input files = $#fileIn, no of deleted files (as empty) = $ct\n";
exit;
