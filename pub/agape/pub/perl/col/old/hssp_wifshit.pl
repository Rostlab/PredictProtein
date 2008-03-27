#!/usr/sbin/perl -w
$[ =1 ;

push (@INC, "/home/rost/perl") ;
# require "ctime.pl";		# require "rs_ut.pl" ; 
require "lib-ut.pl"; require "lib-br.pl";
# require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";

if ($#ARGV<1){
    print "usage: script file_hssp (output = hssp_wifshit)\n";
    exit;}

$file_in=$ARGV[1];
$file_out=$file_in;
$file_out=~s/(\.hssp).*/$1_wifshit/;
$fhin="FHIN";$fhout="FHOUT";

&open_file("$fhin", "$file_in");
&open_file("$fhout", ">$file_out");
$Lok=0;
while (<$fhin>) {
    if (/^\#\# ALI/){
	$Lok=0;}
    elsif (/^\#\# PROTEINS/){
	$Lok=1;}
    elsif ($Lok && (! /^  NR/) ){
	$id=substr($_,9,4);
	$tmp1=substr($_,1,24);
	$tmp2=substr($_,1,20);
	$tmp3=$tmp2."$id";
	$_=~s/$tmp1/$tmp3/;}
    print $fhout $_;
}
close($fhin);close($fhout);	
exit;
