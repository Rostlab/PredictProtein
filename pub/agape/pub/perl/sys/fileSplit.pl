#!/usr/bin/perl -w
#
#  splits a long file into shorter ones with N lines each
#
$[ =1 ;

				# initialise variables
if ($#ARGV<1){print"goal:   splits a long file into shorter ones with N lines each\n";
	      print"usage:  script file number-of-lines-after-which-to-split\n";
	      exit;}
				# command line in
foreach $_(@ARGV){
    if   (-e $_)   {$fileIn=$_;}
    elsif($_!~/\D/){$nsplit=$_;}
    else {
	print "*** ERROR '$_' neither file nor number\n";
	die;}}

if (! -e $fileIn){print"usage:  script file number-of-lines-after-which-to-split\n";
		  print" but:   file '$fileIn' missing\n";
		  die;}

$fhin="FHIN";$fhout="FHOUT";
				# count number of lines
$tmp=`wc -l $fileIn`;
$tmp=~s/\n//g;
$tmp=~s/^\s*(\d+)\s*.*$/$1/g;
$nlines_tot=$tmp;
$nlines_per=1+int($nlines_tot/$nsplit);
$digits=length("$nlines_per");

open("$fhin", "$fileIn") || die "*** failed opening input file=$fileIn";

$ctNew=0;$ctFile=1;

$#fileOut=0;
$fileName=$fileIn;$fileName=~s/^.*\///g;
$name="0" x ($digits-length("$ctFile")) . $ctFile;

$fileOut="spl".$name."-".$fileName;
if (-e $fileOut){$tmp="OLD".$fileOut;
		 print "-*- WARNING: file '$fileOut' exists mv to '$tmp'\n";
		 system("\\mv $fileOut $tmp");}
open("$fhout",">$fileOut") || die "*** failed opening output file=$fileOut";
push(@fileOut,$fileOut);

while (<$fhin>) {
    $line=$_;$_=~s/\n//g;
    if ($ctNew < $nsplit){
	print $fhout $line;
	++$ctNew;}
    else {
	close($fhout);
	++$ctFile;
	$ctNew=0;
	$name="0" x ($digits-length("$ctFile")) . $ctFile;
	$fileOut="spl".$name."-".$fileName;
	if (-e $fileOut){$tmp="OLD".$fileOut;
			 print "-*- WARNING: file '$fileOut' exists mv to '$tmp'\n";
			 system("\\mv $fileOut $tmp");}
	open("$fhout",">$fileOut") || die "*** failed opening output file=$fileOut";
	push(@fileOut,$fileOut); print "--- open $fileOut\n";
    }
}
close($fhin);
close($fhout);

print "--- output in:",join(',',@fileOut,"\n");
exit;
