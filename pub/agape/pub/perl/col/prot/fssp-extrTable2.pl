#!/usr/sbin/perl -w
#
#  extracts all triangles from TABLE2 in fssp:
#  1abr-A 1mrj
#  1apg-A 1mrj
#  -> 1mrj=1abrA,1apgA
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
$#id1=0;
&open_file("$fhin", "$fileIn");
while (<$fhin>) {last if ($_=~/^PDBid R/);}
while (<$fhin>) {next if ($_!~/^\d/);
		 $tmp=substr($_,1,14);
		 $tmp=~s/\s*$//g;
		 $tmp=~s/-//g;
		 ($id1,$id2)=split(/\s+/,$tmp);
		 if (! defined $ali{$id2}){
		     push(@id1,$id2);$ali{$id2}="$id1,";}
		 else {
		     $ali{$id2}.="$id1,";}}close($fhin);

$fileOut1="id-".$fileIn;
&open_file("$fhout",">$fileOut1"); 
foreach $id1(@id1){
    print $fhout "$id1\n";}
close($fhout);

$fileOut="pair-".$fileIn;
&open_file("$fhout",">$fileOut"); 
print $fhout "id1\ttable2-fssp\n";
foreach $id1(@id1){
    if (defined $ali{$id1}){$ali{$id1}=~s/,*$//g;}else{$ali{$id1}="";}
    print $fhout "$id1\t",$ali{$id1},"\n";}
close($fhout);

print "--- output in $fileOut1,$fileOut\n";
exit;
