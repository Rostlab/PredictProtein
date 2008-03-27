#!/bin/env perl
##!/usr/sbin/perl -w
#------------------------------------------------------------------------------#
# other perl environments
# EMBL
##!/usr/sbin/perl4 -w
##!/usr/sbin/perl -w
# EBI
##!/usr/bin/perl -w
#----------------------------------------------------------------------
# htmisit_phd
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# usage: 	htmisit_phd.pl file_rdb_phd (or list of it)
#
# task:		scan for false positive:
#               1. minmal value of minimal helix 
#
#----------------------------------------------------------------------#
#	Burkhard Rost		       January,         1996           #
#			changed:       .	,    	1996           #
#	EMBL				Version 0.1                    #
#	Meyerhofstrasse 1                                              #
#	D-69117 Heidelberg		(rost@EMBL-Heidelberg.DE)      #
#----------------------------------------------------------------------#

$[ =1 ;				# sets array count to start at 1, not at 0

$tmp=$0; $tmp=~s/^\.\///g; 
if ($tmp=~/\//){ $tmp=~s/^(.*\/)(.*)$//; 
		 $pack=$1."pack/".$2; }
else           { $pack=   "pack/".$tmp; }
$pack=~s/\.pl/\.pm/;

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
    &phd_htmisit'phd_htmisit(@ARGV); # e.e '

print "*** package ($pack) returned ERROR:\n".$msg."\n" if (! $Lok);

exit;
