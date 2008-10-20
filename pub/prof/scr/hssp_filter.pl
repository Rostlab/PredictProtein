#!/usr/bin/perl
##!/usr/bin/perl -w
##!/bin/env perl
##!/usr/bin/perl
##!/usr/pub/bin/perl -w
#------------------------------------------------------------------------------#
#	Copyright				        	1998	       #
#	Burkhard Rost		rost@EMBL-Heidelberg.DE			       #
#	Wilckensstr. 15		http://www.embl-heidelberg.de/~rost/	       #
#	D-69120 Heidelberg						       #
#				version 0.1   	May,    	1998	       #
#------------------------------------------------------------------------------#
				# sets array count to start at 1, not at 0
$[ =1 ;

$packDef=0;

$tmp= $0;
$tmp2=$tmp."hssp_filter.pm";
$packDef=$tmp2                 if (defined $tmp2 && 
				   (-e $tmp2 || -l $tmp2 || -x $tmp2));
if (! $packDef){
    $tmp2=$tmp;
    $tmp2=~s/$0//;
    $tmp2.="/"                 if (length($tmp2)>1 && $tmp2!~/\//);
    $tmp2.="pack/hssp_filter.pm";
}
if (! $packDef){
    $packDef = "$ENV{HOME}/server/pub/prof/";
    $packDef.=   "scr/pack/hssp_filter.pm";
}




$pack="";
$#tmp=0;
while (@ARGV) { 
    $_= shift @ARGV;
    if ($_=~/^pack=(.*)/) {
	$pack=$1; 
    }
    else {
	push(@tmp,$_); 
    }
} 
@ARGV=@tmp; 

$pack=$packDef   if (length($pack)<1);

if (! -e $pack){ $dir=$0; 
		 $dir=~s/\.\///g;
		 $dir=~s/^(.*\/).*$/$1/;
		 $pack=$dir.$pack; }

if (! -e $pack || -d $pack){
    die "*** pack is =".$pack.", but not existing"."\n".
	"*** give 'pack=directory_of_package_copf.pm' as argument on command line, missing ..." ;}

$Lok=require "$pack";

die "*** failed to require pack=".$pack." at startup" if (! $Lok);

				# ------------------------------
				# run
($Lok,$msg)=
    &hssp_filterPack::hssp_filterSbr("packName=$pack",@ARGV);

print "*** package ($pack) returned ERROR:\n".$msg."\n" if (! $Lok);

