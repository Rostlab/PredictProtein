#!/usr/sbin/perl -w
#
# corrects error in MG HSSP files
# problem:        NALIGN = N
# but in reality:        = N-1
#
#
$[ =1 ;

push (@INC, "/home/rost/perl") ;
require "ctime.pl";		# require "rs_ut.pl" ;
require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";

if ($#ARGV<1){print"goal:   replaces 'NALIGN ' line in HSSP file by actual number\n";
	      print"usage:  script *hssp (star allowed)\n";
	      exit;}

$fhin="FHIN";$fhout="FHOUT";
foreach $fileIn (@ARGV){
    $fileOut=$fileIn."_out";
				# ------------------------------
				# read wrong HSSP 
    &open_file("$fhin", "$fileIn");
				# read NALIGN
    while (<$fhin>) {$_=~s/\n//g;
		     if (/^NALIGN/){
			 $nali=$_;$nali=~s/^NALIGN\s+//g;$nali=~s/\s//g;}
		     last if (/^  NR\./);}
				# read number actually there
    while (<$fhin>) {last if (/^\#\#/);
		     $naliRd=substr($_,1,5);}close($fhin);
    $naliRd=~s/\s//g;
				# ------------------------------
				# write new
    &open_file("$fhin", "$fileIn");&open_file("$fhout", ">$fileOut");
    while (<$fhin>) {
	if (/^NALIGN/){
	    print "x.x naliRd=$naliRd, nali=$nali,\n";
	    printf $fhout "%-10s %4d\n","NALIGN",$naliRd;}
	else {
	    print $fhout $_;}
    }close($fhin);close($fhout);
}
exit;
