#!/usr/bin/perl
##!/usr/bin/perl -w
##!/bin/env perl
##!/usr/pub/bin/perl -w
##!/bin/env perl -w
##!/usr/bin/perl
##!/usr/pub/bin/perl -w
#------------------------------------------------------------------------------#
#	Copyright				        	1998	       #
#	Burkhard Rost		rost@EMBL-Heidelberg.DE			       #
#	Wilckensstr. 15		http://www.embl-heidelberg.de/~rost/	       #
#	D-69120 Heidelberg						       #
#				version 0.1   	May,    	1998	       #
#------------------------------------------------------------------------------#
$[ =1 ;				# sets array count to start at 1, not at 0

#$tmp=$0; $tmp=~s/^\.\///g; $tmp=~s/^(.*\/)(.*)$//;
#$pack=$1."pack/".$2; $pack=~s/\.pl/\.pm/;

$tmp=$0; $tmp=~s/^\.\///g; $tmp=~s/^(.*\/)//;
if (defined $1){
    $pack=$1."pack/"; }
else {
    $pack="pack/"; }
$tmp=~s/^.*\/(.*)$//;
if (defined $1){
    $pack.=$1; $pack=~s/\.pl/\.pm/;}
else {
    $pack.="conv_hssp2saf.pm";}
    
if (! -e $pack){ $#tmp=0;
		 while (@ARGV) { $_= shift @ARGV;
				 if ($_=~/^pack=(.*)/) {
				     $pack=$1; }
				 else {
				     push(@tmp,$_); }} @ARGV=@tmp; }
if (! -e $pack || -d $pack){
    die "*** pack is =".$pack.", but not existing"."\n".
	"*** give 'pack=directory_of_package_conv_hssp2saf.pm' as argument on command line, missing ..." ;}

$Lok=require "$pack";

die "*** failed to require pack=".$pack." at startup" if (! $Lok);

				# ------------------------------
				# run
($Lok,$msg)=
    &conv_hssp2saf'conv_hssp2saf("packName=$pack",@ARGV); # e.e '

print "*** package ($pack) returned ERROR:\n".$msg."\n" if (! $Lok);

exit;

