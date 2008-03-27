#!/usr/bin/perl -w
##!/usr/sbin/perl 
#----------------------------------------------------------------------
# extracts a chain from an HSSP file
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# usage: 	"hssp_extract_chain.pl file_hssp chain
#
# task:		extracting from an HSSP file one chain
#
#----------------------------------------------------------------------
#                                                                      #
#----------------------------------------------------------------------#
#	Burkhard Rost			August, 	1994           #
#			changed:		,      	1994           #
#	EMBL				Version 0.1                    #
#	Meyerhofstrasse 1                                              #
#	D-69117 Heidelberg		(rost@EMBL-Heidelberg.DE)      #
#----------------------------------------------------------------------#


#------------------------------
# sets array count to start at 1, not at 0
#------------------------------
$[ =1 ;

$script_name = "hssp_extract_chain.pl"; $script_input= "hssp_file chain";

push (@INC, "/home/rost/perl") ;
require "lib-ut.pl"; require "lib-br.pl";

#------------------------------
# number of arguments ok?
#------------------------------
if ($#ARGV < 2) {
   die "*** ERROR: \n*** usage: \t $script_name $script_input \n";
   print "number of arguments:  \t$ARGV \n";
}

#----------------------------------------
#  read input
#----------------------------------------

   				&myprt_empty;
   $file_hssp	= $ARGV[1]; 	&myprt_txt("file here: \t \t $file_hssp"); 
   $chain	= $ARGV[2]; 	&myprt_txt("chain :    \t \t $chain"); $chain=~s/\s//g;

#------------------------------
# defaults
#------------------------------
$file_out=$file_hssp;$file_out=~s/\s//g;$file_out=~s/.*\///g;$file_out=~s/\.hssp/_$chain.hssp/g;
$fhout="FHOUT";

#------------------------------
#  check existence of file
#------------------------------
if (! -e $file_hssp){&myprt_empty;&myprt_txt("ERROR: \t file $file_hssp does not exist");exit;}

#----------------------------------------
# read file
#----------------------------------------
&open_file("FHIN", "$file_hssp");
&open_file($fhout, ">$file_out");

while ( <FHIN> ) { print $fhout $_; last if (/^ SeqNo/); }
while ( <FHIN> ) { 
    if (substr($_,13,1) eq $chain) { print $fhout $_; print "x.x $_"; }
    if (/^\#\#/ || /^ Seq/ ) {print $fhout $_; print "****$_"; }
    last if (/^\#\# SEQUENCE PROFILE/);
}
while ( <FHIN> ) { 
    if (substr($_,12,1) eq $chain) { print $fhout $_; print "x.x $_"; }
    if (/^\#\#/ || /^ Seq/ ) {print $fhout $_; print "****$_"; }
    last if (/^\#\# INSER/);
}
while ( <FHIN> ) { print $fhout $_; } print $fhout "\/\/\n";
close(FHIN);close($fhout);
print"--- output in \t\t $file_out\n";
exit;


