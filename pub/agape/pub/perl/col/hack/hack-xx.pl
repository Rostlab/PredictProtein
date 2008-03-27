#!/usr/sbin/perl -w
#
# 
#
$[ =1 ;

				# include libraries
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
require "ctime.pl";
require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
				# initialise variables

if ($#ARGV<1){print"goal:   \n";
	      print"usage:  \n";
	      exit;}

$fileIn=$ARGV[1];
$fhin="FHIN";$fhout="FHOUT";
$fileOut="Out-".$fileIn;

&open_file("$fhin", "$fileIn");
&open_file("$fhout", ">$fileOut");
$ct=0;
while (<$fhin>) {++$ct;
		 if ($ct>2){
		     $tmp=$_;$tmp=~s/\n//;
		     $tmp=~s/(\d+)\t(nuc|cyt|ext)/\n$1\t$2/g;
		     print $fhout "$tmp\n";}
		 else {
		     print $fhout $_;}}
close($fhin);
close($fhout);
print"--- output in '$fileOut'\n";
exit;
