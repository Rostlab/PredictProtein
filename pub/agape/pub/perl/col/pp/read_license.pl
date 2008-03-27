#!/usr/pub/bin/perl4 -w
#----------------------------------------------------------------------
# read_license
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# usage: 	read_license.pl file_license
#
# task:		xscripttask
# 		
#
#----------------------------------------------------------------------#
#	Burkhard Rost			March,	        1994           #
#			changed:		,      	1994           #
#	EMBL				Version 0.1                    #
#	Meyerhofstrasse 1                                              #
#	D-69117 Heidelberg		(rost@EMBL-Heidelberg.DE)      #
#----------------------------------------------------------------------#


#------------------------------
# sets array count to start at 1, not at 0
#------------------------------
$[ =1 ;

$script_name      = "read_license";
$script_goal      = "xscripttask";
$script_input     = "file_license";

require "/home/phd/ut/perl/ctime.pl";
require "/home/phd/ut/perl/lib-prot.pl";
require "/home/phd/ut/perl/lib-ut.pl";
require "/home/phd/ut/perl/lib-comp.pl";

#------------------------------
# number of arguments ok?
#------------------------------
if ($#ARGV < 1) {
    die "*** ERROR: \n*** usage: \t $script_name $script_input \n";
    print "number of arguments:  \t$ARGV \n";
}

#----------------------------------------
# about script
#----------------------------------------
&myprt_line; &myprt_txt("perl script to $script_goal"); &myprt_empty;
&myprt_txt("usage: \t $script_name $script_input"); &myprt_txt("optional:");
for ($it=1; $it<=$#script_opt_ar; ++$it) {
    print"--- opt $it: \t $script_opt_ar[$it] \n"; 
} &myprt_empty; 

#----------------------------------------
# read input
#----------------------------------------
&myprt_empty;
$file_in	= $ARGV[1]; 	&myprt_txt("file in: \t \t $file_in"); 

$opt_passed = "";
for ( $it=1; $it <= $#ARGV; ++$it ) { $opt_passed .= " " . "$ARGV[$it]"; }
&myprt_txt("options passed: \t $opt_passed"); 

#------------------------------
# defaults
#------------------------------

#------------------------------
# check existence of file
#------------------------------
if ( ! -e $file_in ) {
    &myprt_empty; &myprt_txt("ERROR: \t file $file_in does not exist"); exit;
}

#----------------------------------------
# read list
#----------------------------------------

&open_file("FILE_IN", "$file_in");

while ( <FILE_IN> ) {
    @ar = split(/\t/,$_); 
    printf "%-40s, %-15s, %-12s, %10s, %10s",@ar;
}
close(FILE_IN);
&myprt_empty; &myprt_line; &myprt_txt(" $script_name has ended fine .. -:\)"); 

exit;
