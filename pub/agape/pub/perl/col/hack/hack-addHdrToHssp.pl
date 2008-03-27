#!/usr/sbin/perl -w
#
$scriptName=$0;$scriptName=~s/^.*\/|\.pl//g;
#  
#  problem: rdb_max_cor (after hack-compareRdb.pl) has no header 
#  get it back in!
#
$[ =1 ;
				# include libraries
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
require "ctime.pl";
require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
				# help
$dir="../rdbMax/";
if ($#ARGV<1){
    print "goal:    problem: rdb_max_cor (after hack-compareRdb.pl) has no header \n";
    print "         get it back in! (run in dir with the to-be-corrected-ones!!!)\n";
    print "usage:   script id*rdb_max_cor (assumed the real header is in $dir *rdb_max)\n";
    print "options: \n";
    print "         fileOut=x\n";
    exit;}
				# initialise variables
$fhin="FHIN";$fhout="FHOUT";
				# read command line
$#fileIn=0;
foreach $_(@ARGV){
    if   ($_=~/^fileOut=(.*)$/){$fileOut=$1;}
    elsif(-e $_){push(@fileIn,$_);}
    else {print"*** wrong command line arg '$_'\n";
	  die;}}
				# ------------------------------
				# (1) read file with header
foreach $fileIn(@fileIn){
    $file1=$dir.$fileIn;$file1=~s/_cor//g;
    $fileOut=$fileIn."new";
    &open_file("$fhin", "$file1"); print "--- read with header $file1\n";
    $#hdr=0;
    while (<$fhin>) {push(@hdr,$_);
		     last if (/^4[\t\s]+6S/);}close($fhin);
    if ($#hdr<2){
	print "*** ERROR no header found in $file1\n";
	die;}
				# now new
    &open_file("$fhin", "$fileIn");print "--- read with header $fileIn, wrt to $fileOut\n";
    &open_file("$fhout",">$fileOut"); 
    foreach $hdr(@hdr){
	print $fhout $hdr;}
    while (<$fhin>) {print $fhout $_;}
    close($fhin);close($fhout);}

print "--- output in $fileOut\n";
exit;
