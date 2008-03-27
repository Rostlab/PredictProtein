#!/usr/bin/perl
##!/usr/bin/perl -w
##!/usr/sbin/perl
##!/bin/env perl
#------------------------------------------------------------------------------#
# other perl environments
# EMBL
##!/usr/sbin/perl4 -w
##!/usr/sbin/perl -w
# EBI
##!/usr/bin/perl -w
#----------------------------------------------------------------------
# htmfil_phd
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# usage: 	htmfil_phd.pl .pred file from PHD
#
# task:		filters the transmembrane regions for PHD file
# 		
#
#------------------------------------------------------------------------------#
#	Copyright				        	1999	       #
#	Burkhard Rost		rost@EMBL-Heidelberg.DE			       #
#	Wilckensstr. 15		http://www.embl-heidelberg.de/~rost/	       #
#	D-69120 Heidelberg						       #
#	                previous:		Aug,            1994           #
#			changed:          	Jan,	      	1996           #
#			changed:        	Feb,      	1996           #
#			changed:        	Feb,      	1997           #
#				version 1.1   	May,    	1998	       #
#				version 1.2   	Jan,    	1999	       #
#------------------------------------------------------------------------------#

$[ =1 ;				# sets array count to start at 1, not at 0

$tmp=$0; $tmp=~s/^\.\///g; 
if ($tmp=~/\//){ $tmp=~s/^(.*\/)(.*)$//; 
		 $pack=$1."pack/".$2; }
else           { $pack=   "pack/".$tmp; }
$pack=~s/\.pl/\.pm/;

if (! -e $pack){
    $tmp=$0; $tmp=~s/^\.\///g; $tmp=~s/^(.*\/)//;
    if (defined $1){
	$pack=$1."pack/"; }
    else {
	$pack="pack/"; }
    $tmp=~s/^.*\/(.*)$//;
    if (defined $1){
	$pack.=$1; $pack=~s/\.pl/\.pm/;}
    else {
	$pack.="phd_htmfil.pm";} }
    

if (! -e $pack){ $#tmp=0;
		 while (@ARGV) { $_= shift @ARGV;
				 if ($_=~/^pack=(.*)/) {
				     $pack=$1; }
				 else {
				     push(@tmp,$_); }} @ARGV=@tmp; }
if (! -e $pack || -d $pack){
    die "*** pack is =".$pack.", but not existing"."\n".
	"*** give 'pack=directory_of_package_htmfil.pm' as argument on command line, missing ..." ;}

$Lok=require "$pack";

die "*** failed to require pack=".$pack." at startup" if (! $Lok);

				# ------------------------------
				# run
($Lok,$msg)=
    &phd_htmfil'phd_htmfil(@ARGV); # e.e '

print "*** package ($pack) returned ERROR:\n".$msg."\n" if (! $Lok);

exit;

