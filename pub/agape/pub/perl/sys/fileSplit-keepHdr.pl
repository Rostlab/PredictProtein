#!/usr/bin/perl -w
#
#  splits a long RDB (or whatever) file into N, repeats header
#
$[ =1 ;


if ($#ARGV<1){
    print"goal:   splits a long RDB (or whatever) file after N lines, repeats header\n";
    print"usage:  script file number-of-lines-after-which-to-split\n";
    exit;}

foreach $_(@ARGV){
    if   (-e $_)   {$fileIn=$_;}
    elsif($_!~/\D/){$nsplit=$_;}
    else {
	print "*** ERROR '$_' neither file nor number\n";
	die;}}

if (! -e $fileIn){print"usage:  script file number-of-lines-after-which-to-split\n";
		  print" but: file '$fileIn' missing\n";
		  die;}

$fhin="FHIN";$fhout="FHOUT";
$#header=0;
open("$fhin", "$fileIn") || die "*** failed opening input file=$fileIn";
$ct=$ctNew=0;$ctFile=1;

$#fileOut=0;
$fileName=$fileIn;$fileName=~s/^.*\///g;
$fileOut="spl0".$ctFile."-".$fileName;
if (-e $fileOut){$tmp="OLD".$fileOut;
		 print "-*- WARNING: file '$fileOut' exists mv to '$tmp'\n";
		 system("\\mv $fileOut $tmp");}
open("$fhout",">$fileOut") || die "*** failed opening output file=$fileOut";
push(@fileOut,$fileOut);
print "--- open $fileOut\n";

while (<$fhin>) {
    $line=$_;$_=~s/\n//g;
				# comments = header
    if ($_=~/^\#/){push(@header,$_);
		   print $fhout $line;
		   next;}
    ++$ct;			# first line = header
    if ($ct==1)   {push(@header,$_);
		   print $fhout $line;
		   next;}
				# 2nd line = RDB format?
    if (($ct==2)&&($_=~/\d[SNF][\t\n]/)){push(@header,$_);
					 print $fhout $line;
					 next;}
				# print header now
    if ($ctNew <= $nsplit){
	print $fhout $line;
	++$ctNew;}
    else {close($fhout);
	  ++$ctFile;$ctNew=0;
	  if ($ctFile<10){
	      $txt="0".$ctFile;}
	  else{
	      $txt="$ctFile";}
	  $fileOut="spl".$txt."-".$fileName;
	  if (-e $fileOut){$tmp="OLD".$fileOut;
			   print "-*- WARNING: file '$fileOut' exists mv to '$tmp'\n";
			   system("\\mv $fileOut $tmp");}
	  open("$fhout",">$fileOut") || die "*** failed opening output file=$fileOut";
	  push(@fileOut,$fileOut); 
	  print "--- open $fileOut\n";
	  print join("\n",@header,"\n");
	  foreach $header (@header){print $fhout "$header\n";}}
}close($fhin);close($fhout);

print "--- output in:",join(',',@fileOut,"\n");
exit;
