#!/usr/sbin/perl -w
#
# excludes id's from RDB
#
$[ =1 ;

				# include libraries
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
require "ctime.pl";
require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
				# initialise variables

if ($#ARGV<1){print"goal:   excludes id's from RDB\n";
	      print"usage:  script file.rdb file_with_sw-ids\n";
	      exit;}

$fileInRdb=$ARGV[1];
$fileInSw=$ARGV[2];
$fhin="FHIN";
$fhout="FHOUT";
$fileOut="Out-".$fileInRdb;

$#rdb=$#sw=0;
&open_file("$fhin", "$fileInRdb");
while (<$fhin>) {push(@rdb,$_);}close($fhin);
&open_file("$fhin", "$fileInSw");
while (<$fhin>) {$_=~s/\s//g;
		 if (length($_)<3){
		     next;}
		 push(@sw,$_);}close($fhin);

&open_file("$fhout", ">$fileOut");
foreach $rdb(@rdb){
    $Lfound=0;
    foreach $sw (@sw){
#	print "xx sw=$sw, rdb=$rdb,\n";
	if ($rdb =~ /\t$sw/){
	    print "-- excluded $sw\n";
	    $Lfound=1;
	    last;}}
    if ($Lfound){
	next;}
    print $fhout $rdb;
}
close($fhout);
print"--- output in '$fileOut'\n";
exit;
