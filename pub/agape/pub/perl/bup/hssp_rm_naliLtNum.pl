#!/usr/sbin/perl -w
#
#  removes HSSP files with NALIGN < input
#
$[ =1 ;

push (@INC, "/home/rost/perl") ;
# require "ctime.pl";		# require "rs_ut.pl" ; 
require "lib-ut.pl"; require "lib-br.pl";
# require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";

if ($#ARGV<1){print"goal:   removes HSSP files with NALIGN < num\n";
	      print"usage:  'script num files'\n";
	      exit;}

$num=$ARGV[1];
foreach $it (2..$#ARGV){
    $_=$ARGV[$it];
    if (-e $_){
	push(@fileIn,$_);}}
$fhin="FHIN";
foreach $fileHssp(@fileIn){
    &open_file("$fhin", "$fileHssp");
    while (<$fhin>) {
	if (/^NALIGN/){
	    $_=~s/^NALIGN//g;$_=~s/\D//g;
	    if ($_ < $num){
		$Ldel=1;}
	    else { 
		$Ldel=0;}
	    last;}}close($fhin);
    if ($Ldel){
	print "--- system \t '\\rm $fileHssp'\n";
	system("\\rm $fileHssp");}
}
exit;
