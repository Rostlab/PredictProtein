#!/usr/sbin/perl -w
#
#
$[ =1 ;
				# include libraries
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
require "ctime.pl";
require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
				# initialise variables

if ($#ARGV<1){print"goal:   creates HSSP0 curve\n";
	      print"usage:  script 0(or n=0+n)\n";
	      exit;}

$fhout="FHOUT";
$thresh=$ARGV[1];
$fileOut="Curve-hssp".$thresh.".dat";

&open_file("$fhout", ">$fileOut");
foreach $len (0..500){	# initialise
    $pide=&getDistanceHsspCurve($len,200);
    print "xx len=$len, pide=$pide,\n";
#    $pide+=$thresh;
    printf $fhout "%6d\t%6.1f\n",$len,$pide;}
close($fhout);

print"xx fileOut=$fileOut\n";
exit;
