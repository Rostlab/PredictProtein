#!/usr/sbin/perl4 -w
#
#  runs: 
#       lociGetData.pl fileInHsspLoci=Merge95-hssp-swiss.rdb statExposed=n preOut=y4x-n-
#
#  for n=5,7,9,12,16,20,25,30,40,50
#
$[ =1 ;

				# include libraries
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
require "ctime.pl";
require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
				# initialise variables

if ($#ARGV<1){print"goal:   loops:\n";
	      print"        lociGetData.pl n fileInHsspLoci=hssp-swiss.rdb statExposed=n preOut=y4x-n-\n";
	      print"        for n=5,7,9,12,16,20,25,30,40,50\n";
	      print"usage:  script n1,n2,..,\n";
	      exit;}

$exe=  "/sander/purple1/rost/w/loci/lociGetData.pl";
$file= "Merge95-hssp-swiss.rdb";
#$file= "tmp.rdb";

@acc=split(/,/,$ARGV[1]);

foreach $acc (@acc){
    $cmd= "$exe"." fileInHsspLoci=".$file." preOut=y4x-acc".$acc."-"." ";
    $cmd.=" statExposed=".$acc;
    print "--- system \t '$cmd'\n";
    system("$cmd");
}
exit;
