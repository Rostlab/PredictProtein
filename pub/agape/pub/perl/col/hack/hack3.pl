#!/usr/sbin/perl -w
#
# fileTrue: extract unique
#
$[ =1 ;
				# include libraries
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
require "ctime.pl";
require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
				# initialise variables

if ($#ARGV<1){print"goal:   fileTrue: extract unique\n";
	      print"usage:  \n";
	      exit;}

$fileIn=$ARGV[1];
$fhin="FHIN";$fhout="FHOUT";
$fileOut="Out-".$fileIn;
&open_file("$fhin", "$fileIn");
&open_file("$fhout", ">$fileOut");
while (<$fhin>) {$_=~s/\n//g;
		 ($id1,$tmp)=split(/\t/,$_);
		 $tmp=~s/^,|,$//g;
		 @id2=split(/,/,$tmp);%ok=0;$ok="";
		 foreach $id2(@id2){
		     if (! defined $ok{$id2}){$ok.="$id2,";$ok{$id2}=1;}}
		 $ok=~s/,$//g;
		 print $fhout "$id1\t$ok\n";
		 print "$id1\t$ok\n";}close($fhin);close($fhout);

print"file out=$fileOut\n";
exit;
