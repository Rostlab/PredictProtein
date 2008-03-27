#!/usr/sbin/perl -w
# converts an fssp list (/data/fssp/1pdbC.fssp) to Hssp (/data/hssp/1pdb.hssp_C)
#
$[ =1 ;

push (@INC, "/home/rost/perl") ;
require "ctime.pl";		# require "rs_ut.pl" ;
require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";

if ($#ARGV<1){print"goal : converts list with /data/fssp/1pdbC.fssp' to '/data/hssp/1pdb.hssp_C'\n";
	      print"usage: 'script file'\n";
	      exit;}

$file_in=$ARGV[1];$fileOut=$file_in."_out";
$fhin="FHIN";$fhout="FHOUT";
&open_file("$fhin", "$file_in");&open_file("$fhout", ">$fileOut");
while (<$fhin>) {$_=~s/\n|\s//g;
		 $hssp=$_;$fssp=$_;
		 $hssp=~s/fssp/hssp/g; 
		 if ($hssp=~/\w\w\w\w\w\.hssp/){
		     $hssp=~s/(\w\w\w\w)(\w)\.hssp/$1\.hssp_$2/g;}
		 print "in '$fssp' out '$hssp'\n";
		 $hsspNo=$hssp;$hsspNo=~s/_.$//g;
		 if (-e $hsspNo){
		     print $fhout $hssp,"\n";}
		 else {print"*** missing $hsspNo\n";}}
close($fhin);close($fhout);

print"--- output in '$fileOut'\n";

exit;
