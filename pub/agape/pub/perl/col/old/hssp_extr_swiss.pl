#!/usr/sbin/perl -w
#----------------------------------------------------------------------
# xscriptname
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# usage: 	xscriptname.pl xscriptin
#
# task:		xscripttask
# 		
#
#----------------------------------------------------------------------#
#	Burkhard Rost			August,	        1994           #
#			changed:		,      	1994           #
#	EMBL				Version 0.1                    #
#	Meyerhofstrasse 1                                              #
#	D-69117 Heidelberg		(rost@EMBL-Heidelberg.DE)      #
#----------------------------------------------------------------------#


#------------------------------
# sets array count to start at 1, not at 0
#------------------------------
$[ =1 ;
push (@INC, "/home/rost/perl") ;
require "ctime.pl"; require "rs_ut.pl" ;
require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";

#------------------------------
# number of arguments ok?
#------------------------------
if ($#ARGV < 2) {
    die "*** ERROR: \n*** usage: \t file_swiss_ids file_hssp\n"; exit; }

#----------------------------------------
# read input
#----------------------------------------
$file_swissid=$ARGV[1];
$file_hssp=$ARGV[2];
$fhin="FHIN";

#------------------------------
# defaults
#------------------------------

#----------------------------------------
# read list of swiss ids
#----------------------------------------
&open_file("$fhin", "$file_swissid");
while(<$fhin>) {
    $tmp=$_; $tmp=~s/\s|\n//g;
    push(@swissid,$tmp);
}
close($fhin);

#----------------------------------------
# set flags
#----------------------------------------
foreach $i (@swissid) { $lfound{$i}=0; }

#----------------------------------------
# read hssp file list foreach
#----------------------------------------
&open_file("$fhin", "$file_hssp");
while(<$fhin>) { last if (/^  NR\./);}
while(<$fhin>) { 
    last if (/^\#\#/);
    $ct=0;
    while ($ct<$#swissid) {
	++$ct;
	if (! $lfound{$swissid[$ct]}) { 
	    $tmp=$file_hssp;$tmp=~s/.*\///g; $tmpswiss=substr($_,9,10);$tmpswiss=~s/\s//g;
	    if ($tmpswiss=~/$swissid[$ct]/) {
		print "$tmp: $tmpswiss similar to:$swissid[$ct]\n"; 
		$lfound{$swissid[$ct]}=1;
	    }
	}
    }
}
close($fhin);
exit;
