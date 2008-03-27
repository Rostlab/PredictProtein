#!/usr/bin/perl -w
#
#  merges files into one long one
#
$[ =1 ;

				# initialise variables
$fileOut="Out-merge.tmp";
if ($#ARGV<1){print "goal:   merges files into one long one\n";
	      print "usage:  script files\n";
	      print "option: fileOut=x (default =$fileOut)\n";
	      exit;}
				# command line in
$#fileIn=0;
foreach $tmp(@ARGV){
    if   ($tmp =~/^fileOut=(.*)$/){$fileOut=$1;}
    elsif(-e $tmp){push(@fileIn,$tmp);}
    else          {print "*** unrecognised command line arg '$tmp'\n";
		   die;}}

$fhin="FHIN";$fhout="FHOUT";
open("$fhout",">$fileOut") || die "*** failed opening output file=$fileOut";

foreach $fileIn (@fileIn){
    open("$fhin", "$fileIn") || die "*** failed opening input file=$fileIn";
    while(<$fhin>){
	print $fhout $_;}
    close($fhin);
}
close($fhout);

print "--- output in: $fileOut\n";
exit;
