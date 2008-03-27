#!/usr/sbin/perl -w
#
# remove chain name
#
$[ =1 ;

push (@INC, "/home/rost/perl") ;
# require "ctime.pl";		# require "rs_ut.pl" ; 
require "lib-ut.pl"; require "lib-br.pl";
# require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";

if ($#ARGV<1){print"goal:   remove chain name from 1801A.hssp \n";
	      print"usage:  script file (takes all capitals)\n";
	      print"option: out=hssp, out=dssp (replace ext -> hssp)\n";
	      exit;}

$fileIn=$ARGV[1];
$out="hssp";
foreach $arg(@ARGV){
    if ($arg =~/out=/){$out=$arg;$out=~s/^out=//g;}}

$fhin="FHIN";$fhout="FHOUT";
$fileOut="Out-".$fileIn;
&open_file("$fhin", "$fileIn");&open_file("$fhout", ">$fileOut");
while (<$fhin>) {
    $_=~s/\n//g;
    $_=~s/[A-Z]//g;$_=~s/(\/?....).?\./$1./;
    $_=~s/.ssp/$out/;
    print "new $_\n";
    print $fhout "$_\n";}
close($fhin);close($fhout);
exit;
