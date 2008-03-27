#!/usr/bin/perl
##!/usr/bin/perl -w
##!/usr/pub/bin/perl -w
##!/bin/env perl
##!/usr/sbin/perl -w
##!/bin/env perl -w
#------------------------------------------------------------------------------#
#	Copyright				        	1998	       #
#	Burkhard Rost		rost@EMBL-Heidelberg.DE			       #
#	Wilckensstr. 15		http://www.embl-heidelberg.de/~rost/	       #
#	D-69120 Heidelberg						       #
#				version 0.1   	May,    	1998	       #
#------------------------------------------------------------------------------#
$[ =1 ;				# sets array count to start at 1, not at 0

$pack=   "/home/rost/perl/scr/pack/copf.pm";
$pack=   "pack/copf.pm";

if (! -e $pack){ $dir=$0; 
		 $dir=~s/\.\///g;
		 $dir=~s/^(.*\/).*$/$1/;
		 $pack=$dir.$pack; }
if (! -e $pack){ $#tmp=0;
		 while (@ARGV) { $_= shift @ARGV;
				 if ($_=~/^pack=(.*)/) {
				     $pack=$1; }
				 else {
				     push(@tmp,$_); }} @ARGV=@tmp; }
if (! -e $pack || -d $pack){
    die "*** pack is =".$pack.", but not existing"."\n".
	"*** give 'pack=directory_of_package_copf.pm' as argument on command line, missing ..." ;}

$Lok=require "$pack";

die "*** failed to require pack=".$pack." at startup" if (! $Lok);

				# ------------------------------
				# run

($Lok,$msg)=
    &copf'copf("packName=$pack",@ARGV); # e.e '

print "*** package ($pack) returned ERROR:\n".$msg."\n" if (! $Lok);

exit;
