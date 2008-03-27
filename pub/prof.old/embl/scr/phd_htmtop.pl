#!/usr/bin/perl
##!/usr/bin/perl -w
##!/usr/bin/perl -w
##!/bin/env perl
##!/usr/sbin/perl -w
#------------------------------------------------------------------------------#
# other perl environments
# EMBL
##!/usr/sbin/perl4 -w
##!/usr/sbin/perl -w
# EBI
##!/usr/bin/perl -w
#------------------------------------------------------------------------------#
# htmtop_phd
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# usage: 	htmtop_phd.pl file_rdb_phd (for profiles + file.hssp)
#
# task:		assigns the topology for a transmembrane protein
# 		
#
#------------------------------------------------------------------------------#
#	Copyright				        	1998	       #
#	Burkhard Rost		rost@EMBL-Heidelberg.DE			       #
#	Wilckensstr. 15		http://www.embl-heidelberg.de/~rost/	       #
#	D-69120 Heidelberg						       #
#	                previous:		Oct,            1995           #
#			changed:          	Jan,	      	1996           #
#			changed:        	Feb,      	1996           #
#			changed:        	Feb,      	1997           #
#				version 0.1   	May,    	1998	       #
#------------------------------------------------------------------------------#

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
	"*** give 'pack=directory_of_package_htmtop.pm' as argument on command line, missing ..." ;}

$Lok=require "$pack";

die "*** failed to require pack=".$pack." at startup" if (! $Lok);

				# ------------------------------
				# run
($Lok,$msg)=
    &phd_htmtop'phd_htmtop(@ARGV); # e.e '

print "*** package ($pack) returned ERROR:\n".$msg."\n" if (! $Lok);

exit;

