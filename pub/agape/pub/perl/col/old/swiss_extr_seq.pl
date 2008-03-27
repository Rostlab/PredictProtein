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

$script_name      = "xscriptname";
$script_goal      = "xscripttask";
$script_input     = "xscriptin";
$script_opt_ar[1] = "2nd = executable";

push (@INC, "/home/rost/perl") ;
# require "ctime.pl"; require "rs_ut.pl" ; 
require "lib-ut.pl"; require "lib-br.pl";
# require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";

if ($#ARGV < 1) {
    die "*** ERROR: \n*** usage: \t $script_name $script_input \n";
    print "number of arguments:  \t$ARGV \n";
}

#----------------------------------------
# read input
#----------------------------------------
&myprt_empty;
$file_in	= $ARGV[1]; 	&myprt_txt("file in: \t \t $file_in"); 

#------------------------------
# defaults
#------------------------------
$dir_swiss="/data/swissprot/current/";

#------------------------------
# check existence of file
#------------------------------
if (! -e $file_in) {&myprt_empty; &myprt_txt("ERROR:\t file $file_in does not exist"); exit; }

#----------------------------------------
# read list
#----------------------------------------

&open_file("FILE_IN", "$file_in");

while ( <FILE_IN> ) {
    $tmp=$_;$tmp=~s/\n//g;$tmp=~s/\.dat//g;
    if ($tmp=~/_/) {
	($tmp1,$tmp2)=split(/_/,$tmp);
	$swiss_sub=substr($tmp2,1,1);
	$filetmp="$dir_swiss". "$swiss_sub". "/"."$tmp";
	if (-e $filetmp) { 
	    print "--- now: cp $filetmp $tmp\n";
	    system("\\cp $filetmp $tmp");
	} else { 
	    print "--- not existing file swiss:$filetmp,\n";
	}
	
    } else { print "---  Warning: no swissprot file id for:$tmp,\n";}
}
close(FILE_IN);

&myprt_empty; &myprt_line; &myprt_txt(" $script_name has ended fine .. -:\)"); 

exit;
