#!/usr/local/bin/perl -w
##!/usr/pub/bin/perl -w
#
#------------------------------------------------------------------------------#
#	Copyright				  Apr,    	 1998	       #
#	Burkhard Rost 		rost@EMBL-Heidelberg.DE			       #
#	EMBL			http://www.embl-heidelberg.de/~rost/	       #
#	D-69012 Heidelberg						       #
#			        v 1.0   	  Apr,           1998          #
#			        v 1.1   	  Oct,           1998          #
#			        v 1.2   	  Feb,           1999          #
#			        v 1.3   	  Nov,           1999          #
#------------------------------------------------------------------------------#
#
#    This script writes a single mail written by PROCMAIL into a file. 
# 
#    ------------------------------
#    command line argument(s)
#    ------------------------------
#      
#    NONE:  full file is 'cat' into STDIN by procmailPP.rc 
#      
#      
#    note 1: this script only write the info into a file HARD_CODED
#    note 2: no script is called, rather the file written by this
#            script will be processed further by procmailPP.pl
#
#----------------------------------------------------------------------#
				# ------------------------------
$this_file=$0;			# get the name of this file
$this_file=~s,.*/,,; $scrName=$this_file; $scrName=~s/\.pl//g;

				# ------------------------------
				# local parameters
				# ------------------------------
$dirHome=  "/home/$ENV{USER}/server/";	          # HARD_CODED
$dirWork=  $dirHome."xch/inProc/";        # HARD_CODED
$dirTrace= $dirHome."log/";               # HARD_CODED
$fileTrace=$dirTrace."procmail-in.log";   # HARD_CODED

$fileOut=  $dirWork. $$ . ".procmail-in"; # HARD_CODED
$fhout=    "FHOUT";

				# ------------------------------
				# make directories
				# ------------------------------
system("mkdir $dirWork")        if (! -d $dirWork);
system("mkdir $dirTrace")       if (! -d $dirTrace);

#system ("echo 'xx procmail2file output=$fileOut' >> /home/$ENV{USER}/server/scr/x.tmp");

				# --------------------------------------------------
				# read, and write information
				# --------------------------------------------------
$#line=0;
while (<>) {$_=~s/\n+$//g;
	    next if (! defined $_ || length($_)<1);
	    push(@line,$_);}
				# --------------------------------------------------
				# write output
				# --------------------------------------------------
open ($fhout,">".$fileOut) ||
    do {
	$date=`date`;
	$date=~s/\n|\s//g;
	$msg="*** ERROR $scrName: failed opening new fileOut=$fileOut! (date=$date)";
	system("echo $msg >> $fileTrace");
	die("$msg"); 
    };

foreach $_ (@line){
    next if (! defined $_);
#    system("echo 'xx in:$_' >> /home/$ENV{USER}/server/scr/x.tmp");
    print $fhout "$_\n";
}
close($fhout);

#xx 
#system("cp $fileOut /home/$ENV{USER}/server/bup/tmp-mail-in/");

if (! -e $fileOut){
    $date=`date`;
    $date=~s/\n|\s//g;
    $msg="*** ERROR $scrName: failed writing new fileOut=$fileOut! (date=$date)";
	    
    system("echo $msg >> $fileTrace");
    die("$msg");}

exit(1);


# ================================================================================
# garbage can
# ================================================================================
				# ------------------------------
				# rsh on tau
				# ------------------------------
#system("rsh $machine '$scrNext $fileOut' ");
system("$scrNext $fileOut");
				# trace
#system("echo 'procmail-stork.pl: rsh $machine $scrNext $fileOut' >> $fileTrace"); # xx
system("echo 'procmail-stork.pl: $scrNext $fileOut' >> $fileTrace"); # xx
exit;


#================================================================================ #
#                                                                                 #
#-------------------------------------------------------------------------------- #
# Predict Protein - a secondary structure prediction and sequence analysis system #
# Copyright (C) <2004> CUBIC, Columbia University                                 #
#                                                                                 #
# Burkhard Rost         rost@columbia.edu                                         #
# http://cubic.bioc.columbia.edu/~rost/                                           #
# Jinfeng Liu             liu@cubic.bioc.columbia.edu                             #
# Guy Yachdav         yachdav@cubic.bioc.columbia.edu                             #
#                                                                                 #
# This program is free software; you can redistribute it and/or modify it under   #
# the terms of the GNU General Public License as published by the Free Software   #
# Foundation; either version 2 of the License, or (at your option)                #
# any later version.                                                              #
#                                                                                 #
# This program is distributed in the hope that it will be useful,                 #
# but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY  #
# or FITNESS FOR A PARTICULAR PURPOSE.                                            #
# See the GNU General Public License for more details.                            #
#                                                                                 #
# You should have received a copy of the GNU General Public License along with    #
# this program; if not, write to the Free Software Foundation, Inc.,              #
# 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA                         #
#                                                                                 #
# Contact Information:                                                            #
#                                                                                 #
# predict_help@columbia.edu                                                       #
#                                                                                 #
# CUBIC   Columbia University                                                     #
# Department of Biochemistry & Molecular Biophysics                               #
# 630 West, 168 Street, BB217                                                     #
# New York, N.Y. 10032 USA                                                        #
# Tel +1-212-305 4018 / Fax +1-212-305 7932                                       #
#================================================================================ #
