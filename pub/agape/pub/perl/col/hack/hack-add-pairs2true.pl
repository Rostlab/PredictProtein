#!/usr/sbin/perl -w
#
#  take list output from blastHeaderStat and merge into truePairs
#  format (tab delimited): '1tuc	1prl_C	42	56	63	2.0e-09'
#
$[ =1 ;
				# include libraries
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
require "ctime.pl";
require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
				# help
if ($#ARGV<1){print "goal:    take list output from blastHeaderStat and merge into truePairs\n";
	      print "         format (tab delimited): '1tuc 1prl_C 42 56 63 2.0e-09'\n";
	      print "usage:   $0 pairs-from-blast true-pairs-to-merge-into\n";
	      print "options: \n";
	      print "         fileOut=x\n";
	      print "         \n";
	      print "         \n";
	      exit;}
				# initialise variables
$fhin="FHIN";$fhout="FHOUT";
				# read command line
$fileIn= $ARGV[1];
$fileIn2=$ARGV[2];
$fileOut="Out-".$fileIn2;

foreach $_(@ARGV){
    if ($_=~/^fileOut=(.*)$/){$fileOut=$1;}
}
				# read blast
&open_file("$fhin", "$fileIn");
undef %new;$#new=0;
while (<$fhin>) {$_=~s/\n//g;
		 next if (length($_)<10);
		 @tmp=split(/[\t\s]+/,$_);
#		 print "xx:$_\n";
		 $id1=$tmp[1];$id1=~s/[\s\_]//g;
		 $id2=$tmp[2];$id2=~s/[\s\_]//g;
		 if (! defined $new{"$id1"}){push(@new,$id1);
					     $new{"$id1"}="$id2,";}
		 else {$new{"$id1"}.="$id2,";}}close($fhin);
foreach $id(@new){$new{"$id"}=~s/^,|,$//g;}
				# read and write true pairs
&open_file("$fhin", "$fileIn2");
&open_file("$fhout",">$fileOut"); 
while (<$fhin>) {
    $line=$_;
    $_=~s/\n//g;
    ($id1,$tmp)=split(/\t/,$_);
    if (! defined $new{"$id1"}){
	print $fhout $line;}
    else {@old=split(/,/,$tmp); @newx=split(/,/,$new{"$id1"}); 
	  undef %tmp;$fin="";$ok{$id1}=1;
	  foreach $id(@old,@newx){
	      if (! defined $tmp{$id}){$fin.="$id,";$tmp{$id}=1;}}
	  print $fhout "$id1\t$fin\n";}}close($fhin);
foreach $new(@new){		# check : all new taken?
    if (! defined $ok{$new}){
	print $fhout "$new\t",$new{$new},"\n";
    }}

close($fhout);

print "--- output in $fileOut\n";
exit;
