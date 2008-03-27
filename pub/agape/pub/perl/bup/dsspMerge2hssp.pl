#!/usr/bin/perl -w
#
# takes sec and acc and writes from DSSP file into HSSP file
#
$[ =1 ;

				# include libraries
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
require "lib-ut.pl"; require "lib-br.pl"; 
				# initialise variables

if ($#ARGV<1){print"goal:   takes sec and acc and writes from DSSP file into HSSP file\n";
	      print"usage:  file.dssp (or *dssp)\n";
	      print"note:   expect: file.dssp and file.hssp\n";
	      exit;}

$fhin="FHIN";$fhout="FHOUT";
				# read DSSP and HSSP (and write new HSSP)
foreach $fileDssp (@ARGV){
    if (!-e $fileDssp){
	next;}
    $fileHssp=$fileDssp;       $fileHssp=~s/dssp/hssp/;
    $fileOut= $fileDssp."-new";$fileOut=~s/dssp/hssp/;
    $#dssp=$#hssp=0;
    print "--- reading DSSP '$fileDssp'\n";
    &open_file("$fhin", "$fileDssp");
    while (<$fhin>) {last if /^\s+\#\s+RESIDUE/; } # skip everything before sequence
    while (<$fhin>) {$_=~s/\n//g;
		     push(@dssp,$_);}close($fhin);
#    &myprt_array("\n","dssp",@dssp);exit;

    print "--- reading HSSP '$fileHssp'\n";
    &open_file("$fhin", "$fileHssp");
    while (<$fhin>) {$_=~s/\n//g;
		     push(@hssp,$_);}close($fhin);

    &open_file("$fhout", ">$fileOut");
    $Lhead=1;$Lbottom=0;
    foreach $hssp (@hssp){
	print "xx read '$hssp'\n";
	if ($hssp=~/^ SeqNo/){
	    $Lhead=0;$ct=0;
	    print $fhout "$hssp\n";}
	elsif ($hssp=~/^\#\# SEQUENCE/){
	    $Lbottom=1;
	    print $fhout "$hssp\n";}
	elsif ($Lhead)   {
	    print $fhout "$hssp\n";}
	elsif ($Lbottom) {
	    print $fhout "$hssp\n";}
	else {
	    ++$ct;
	    $begHssp=substr($hssp,1,17);
	    $begDssp=substr($hssp,1,17);
	    if ($begHssp ne $begDssp){
		print "*** difference ct=$ct, \n*** dssp=$begDssp\n*** hssp=$begHssp\n";
		exit;}
	    $dssp=substr($dssp[$ct],17,22);
	    $hsspN=substr($hssp,1,17).$dssp.substr($hssp,40);
	    print $fhout "$hsspN\n";
	}
    }
    close($fhout);
}
exit;
