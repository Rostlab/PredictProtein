#!/usr/sbin/perl -w
#
#
$[ =1 ;

				# include libraries
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
require "ctime.pl";
require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
				# initialise variables
@tmp=split(/,/,$ARGV[1]);

foreach $tmp(@tmp){
    system("grep $tmp /data/fssp/TABLE2");}

if ($#ARGV>1){
    @tmp=split(/,/,$ARGV[2]);
    foreach $tmp(@tmp){
	$tmp="/data/fssp/".$tmp.".fssp";
	if (! -e $tmp){
	    print "xx missing $tmp\n";
	    next;}
	system("/home/rost/perl/scr/fssp_extr_ids.pl $tmp");}}
exit;

if ($#ARGV<1){print"goal:   \n";
	      print"usage:  \n";
	      exit;}

$fileIn=$ARGV[1];
$fhin="FHIN";$fhout="FHOUT";
$fileOut="Out-".$fileIn;
&open_file("$fhin", "$fileIn");
while (<$fhin>) {
    $_=~s/\n//g;
}
close($fhin);

&open_file("$fhout",">$fileOut"); close($fhout);

exit;
