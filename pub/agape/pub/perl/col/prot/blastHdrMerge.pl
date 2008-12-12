#!/usr/sbin/perl -w
#
#  merges a list of headers id.blastOut (generated by blast-runANDextr.pl)
#
$[ =1 ;

				# include libraries
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
require "ctime.pl";
require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
				# initialise variables

if ($#ARGV<1){print"goal:   merges list of headers id.blastOut (from: blast-runANDextr.pl)\n";
	      print"usage:  script *.blastOut \n";
	      exit;}

$fhin="FHIN";$fhout="FHOUT";
if ($#ARGV>1){
    @fileIn=@ARGV;}
$fileOut="Out-".$$.".tmp";

if (-e $fileOut){
    print "xx cannot write into $fileOut, as it exists => think twice!!\n";
    exit;}

&open_file("$fhout",">$fileOut"); 
print $fhout "id1\tid2\tide\tlali\tblScor\tblProb\n";

foreach $fileIn(@fileIn){
    if (! -e $fileIn){print "*** missing '$fileIn' \n";
		      die;}
    &open_file("$fhin", "$fileIn");
    while (<$fhin>) {
	next if ($_=~/^id/);
	print $fhout "$_";}close($fhin);
}
close($fhout);

print "--- output in $fileOut\n";
exit;