#!/usr/sbin/perl -w
#
#  extracts values from .phd
#
$[ =1 ;

				# include libraries
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
require "ctime.pl";
require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
				# initialise variables

if ($#ARGV<1){print"goal:   extracts Q3 asf from *.phd files\n";
	      print"usage:  script *.phd\n";
	      exit;}

$#file=0;foreach $_(@ARGV){if (-e $_){push(@file,$_);}else{print"-*- missing '$_'\n";}}

$fhin="FHIN";$fhout="FHOUT";$fileOut="Out-grep-from-phd.dat";
$sep=" ";

&open_file("$fhout", ">$fileOut");
foreach $fh ("STDOUT",$fhout){
    printf $fh "%-15s$sep%4s$sep%5s$sep%5s$sep%-s\n","id","nali","Q3sec","Q2acc","Sec";}
    
$ct=0;$seq=$sec="";
foreach $fileIn (@file){
    $id=$fileIn;$id=~s/\.phd//g;
    ++$ct;$phd="";
    &open_file("$fhin", "$fileIn");
    while (<$fhin>) {
	$_=~s/\n//g;
	if    (/^\*\s+NALIGN\s+(\d+)/){$nali=$1;$nali=~s/\s//g;}
	elsif (/^ \|\s+\|0\.\d\d \|\d\.\d\d \|\d\.\d\d \|([ .0-9]+)\|/){$q3=$1;$q3=~s/\s//g;}
	elsif (/^ \| SOV\s+[^|]+/){$sovObs=substr($_,34,6);$sovObs=~s/\s//g;
				   $sovPrd=substr($_,63,6);$sovPrd=~s/\s//g;}
	elsif (/^ \|\w\w\w\w   \|([ .0-9]+) /){$q2=$1;$q2=~s/\s//g;}
	elsif (/^\s+PHD sec\s+\|([ A-Z]+)/){$phd.=$1;}
	else {
	    if ($ct>1){
		next;}
	    if    (/^\s+AA\s+\|([ A-Z]+)/){$seq.=$1;}
	    elsif (/^\s+OBS sec\s+\|([ A-Z]+)/){$sec.=$1;}}
    }
    close($fhin);
    if (0){
	printf 
	    "%-15s$sep%4d$sep%5.1f$sep%6.1f$sep%6.1f$sep%5.1f\n",
	    $id,$nali,$q3,$sovObs,$sovPrd,$q2;
    }
    foreach $fh ("STDOUT",$fhout){
	printf $fh
	    "%-15s$sep%4d$sep%5.1f$sep%5.1f$sep%-s\n",$id,$nali,$q3,$q2,$phd;}
}				# end of loop over files

foreach $fh ("STDOUT",$fhout){	# add sequence and observed
    printf $fh "%-15s$sep%4s$sep%5s$sep%5s$sep%-s\n","AA"," "," "," ",$seq;
    printf $fh "%-15s$sep%4s$sep%5s$sep%5s$sep%-s\n","OBS"," "," "," ",$sec;
}
close($fhout);
print"--- output in $fileOut\n";

exit;
