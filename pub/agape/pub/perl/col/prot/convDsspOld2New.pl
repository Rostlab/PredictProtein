#!/usr/sbin/perl -w
# converts the new DSSP format to the old one, readable by convert_seq
#
$[ =1 ;

				# include libraries
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
require "ctime.pl";
require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
				# initialise variables

if ($#ARGV<1){print"goal:   converts new DSSP format to old one, readable by convert_seq\n";
	      print"usage:  script file.dssp (or *.dssp)\n";
	      exit;}

$fhin="FHIN";
$fhout="FHOUT";
foreach $file (@ARGV){
    if (! -e $file){
	next;}
    $fileOld=$file."-old";
    &fileMv($file,$fileOld,"STDOUT");
    &open_file("$fhin", "$fileOld");
    &open_file("$fhout", ">$file");
    while (<$fhin>) {
	print $fhout 
	    "**** SECONDARY STRUCTURE DEFINITION BY THE PROGRAM DSSP, ",
	    "VERSION JUL. 1993 **** DATE=18-MAR-1994\n";
	last ;}
    while (<$fhin>) {print $fhout $_; }close($fhin);close($fhout);
}
exit;
