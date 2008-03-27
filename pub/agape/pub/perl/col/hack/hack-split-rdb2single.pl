#!/usr/sbin/perl -w
#
#  reads spl*rdb and splits into single proteins (849)
#
$[ =1 ;
				# include libraries
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
require "ctime.pl";
require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
				# help
if ($#ARGV<1){print "goal:    reads spl*rdb and splits into single proteins (849)\n";
	      print "usage:   script *spl*rdb\n";
	      print "options: WATCH the output names!!\n";
	      exit;}
				# initialise variables
$fhin="FHIN";$fhout="FHOUT";
				# read command line
foreach $fileIn(@ARGV){
    next if (! -e $fileIn);
    print "--- reading $fileIn\n--- writing: ";
    $id0="";
    if    ($fileIn=~/bl.*2/){$ext=".rdb_bl2";}
    elsif ($fileIn=~/bl.*1/){$ext=".rdb_bl1";}
    else                    {$ext=$fileIn;$ext=~s/^.*\/|\..*$//g;}
    &open_file("$fhin", "$fileIn");
    while (<$fhin>) {
	$_=~s/\n//g;
	if (/^id/){$head="$_";}
	else {
	    $id=$_;$id=~s/^([\w\d]+)\t.*$/$1/g;
	    if ($id ne $id0){
		if (length($id0)>1){
		    close($fhout);}
		$id0=$id;
		$fileOut="$id".$ext;
		&open_file("$fhout",">$fileOut"); print "$fileOut, ";
		print $fhout "$head\n";}
	    print $fhout "$_\n";}}
    close($fhin);
    close($fhout);}
    print "\n";

print "--- output in $fileOut (asf)\n";
exit;
