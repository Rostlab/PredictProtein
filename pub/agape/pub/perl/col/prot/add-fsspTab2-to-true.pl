#!/usr/sbin/perl -w
#
#  takes the list as produced by fssp_ide_ali (Id..)
#  and adds the content of TABLE2 in FSSP
#
$[ =1 ;

				# include libraries
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
require "ctime.pl";
require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
				# initialise variables

if ($#ARGV<1){print"goal:   takes the list as produced by fssp_ide_ali (Id..)\n";
	      print"        and adds missing close homologues from  TABLE2 in FSSP\n";
	      print"usage:  \n";
	      exit;}
$fileIn=$ARGV[1];
$fhin="FHIN";$fhout="FHOUT";
$fileOut="Out-".$fileIn;
$dirFssp="/data/fssp/";
$fileTable=$dirFssp."TABLE2";

$#id=0;
&open_file("$fhin", "$fileIn");	# first list from fssp_ide_ali.pl
while (<$fhin>) {$_=~s/\n//g;$_=~s/^\s*|\s*$//g;
		 ($tmp1,$tmp2)=split(/\s+/,$_);
		 $tmp1=~s/[-_]//g;$tmp2=~s/[-_]//g;$tmp2=~s/^,*|,*$//g;
		 push(@id,$tmp1);
		 $rd{"$tmp1"}=$tmp2;}close($fhin);

&open_file("$fhin", "$fileTable");	# now fssp table2
while (<$fhin>) {$_=~s/\n//g;
		 last if (/^PDBid/);}
while (<$fhin>) {$_=substr($_,1,14);$_=~s/\s*$//g;
		 ($tmp1,$tmp2)=split(/\s+/,$_);
		 $tmp1=~s/[-_]//g;$tmp2=~s/[-_]//g;
		 if (defined $rd{"$tmp1"}){
		     $rd{"$tmp1"}.=",".$tmp2;}}close($fhin);

&open_file("$fhout", ">$fileOut");	# first list from fssp_ide_ali.pl
foreach $id(@id){
    $rd{"$id"}=~s/^,+|,*$//g;
    print $fhout "$id\t",$rd{"$id"},"\n";
    print  "$id\t",$rd{"$id"},"\n";}
close($fhout);


print "--- output in file $fileOut\n";
exit;
