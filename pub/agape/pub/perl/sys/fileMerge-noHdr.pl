#!/usr/bin/perl -w
#
#  merges files into one long one (header only once)
#
$[ =1 ;

$fileOut="Out-merge.tmp";
if ($#ARGV<1){print "goal:   merges files into one long one (header only once)\n";
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
				# get first header
$fileIn=$fileIn[1];$#hdr=0;
open("$fhin", "$fileIn") || die "*** failed opening input file=$fileIn";

$ct=0;
while(<$fhin>){$_=~s/\n//g;
	       if ($_=~/^\#/){push(@hdr,$_);
			      next;}
	       ++$ct;
	       if ($ct == 1){ push(@hdr,$_);
			      next;}
	       last if ($_ !~ /\d[NSD]\t|\d\.\dF\t/);}close($fhin);
foreach $hdr(@hdr){
    print $fhout "$hdr\n";
    print "--- header \t $hdr\n";}
				# now read all others, ignore header
foreach $fileIn (@fileIn){
    open("$fhin", "$fileIn") || die "*** failed opening input file=$fileIn";
    print "--- reading '$fileIn'\n";
    $ct=0;
    while(<$fhin>){next if ($_=~/^\#/);
		   ++$ct;
		   next if ($ct==1);
		   next if (($ct==2)&&($_ =~ /\d[NSD]\t|\d\.\dF\t/));
		   print $fhout $_;}close($fhin);
}
close($fhout);

print "--- output in: $fileOut\n";
exit;
