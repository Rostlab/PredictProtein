#!/usr/sbin/perl -w
# 
# generate file list
#
$[ =1 ;

push (@INC, "/home/rost/perl") ;
require "ctime.pl";		# require "rs_ut.pl" ;
require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";

if ($#ARGV<3){print"goal:   generate file list: HI0001, HI0002, ...\n";
	      print"usage:  'script num pre digits' (e.g. 1743 HI 4)\n";
	      exit;}

$num=$ARGV[1];$pre=$ARGV[2];$digits=$ARGV[3];
$fhout="FHOUT";$fileOut="Out-list.tmp";

&open_file("$fhout", ">$fileOut");
foreach $it (1..$num){
    $n0=$digits-length($it);
    $tmp="$pre"."0" x $n0."$it";
    print "x.x '$tmp', n0=$n0, it=$it, len=",length($it),",\n";
    print $fhout "$tmp\n";
}
close($fhout);
print "output in $fileOut\n";
exit;
