#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#----------------------------------------------------------------------
# hssp_make_SwissTable
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# usage: 	hssp_make_SwissTable.pl file_hssp
#
# task:		extracts the header of an HSSP file
# 		
# subroutines   hssp_rd_header_loc
#
#----------------------------------------------------------------------#
#	Burkhard Rost		       November,        1996           #
#			changed:       .	,    	1996           #
#	EMBL				Version 0.1                    #
#	Meyerhofstrasse 1                                              #
#	D-69117 Heidelberg		(rost@EMBL-Heidelberg.DE)      #
#----------------------------------------------------------------------#

$[ =1 ;				# sets array count to start at 1, not at 0
if ($#ARGV<1){			# error if insufficient input argument
    print "*** input ERROR, call with 'hssp_make_SwissTable file_hssp' (or *hssp, or hssp.list)\n";
    exit;}

$fhin="FHIN_HSSP_HEADER";	# defaults

if ($#ARGV == 1 && 
    $ARGV[1]=~/list$/){
    open($fhin,$ARGV[1]) || die"*** failed to open filein(expected list)=$ARGV[1]!\n";
    while(<$fhin>){
	$_=~s/\s|\n//g;
	push(@fileIn,$_);
    }
    close($fhin);}
else{
    @fileIn=@ARGV;}
				# --------------------------------------------------
				# call reader
				# --------------------------------------------------

				# read file
for $file (@fileIn){
    if ( ! -e $file) {		# check existence
	print "*** missing file=$file\n";
	return(0); }
    open ($fhin, $file) || 
	(do {warn "*** hssp_make_SwissTable: Can't create new file: $file\n"; });
    $id=$file; 
    $id=~s/^.*\///g;
    $id=~s/\..*$//g;
    while ( <$fhin> ) {		# is it HSSP file?
	if (! /^HSSP /) {
	    return(0); } 
	last; }
    while ( <$fhin> ) {		# length, lond-id
	last if (/^\#\# PROTEINS/);} 
    while ( <$fhin> ) { 
	last if (/^\#\# ALIGNMENTS/); 
	next if (/^  NR\./);	# skip describtors
	printf "%-8s  ",$id;
	print $_;
    }
    close($fhin);
}
exit;

