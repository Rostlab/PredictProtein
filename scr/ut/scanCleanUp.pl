#!/usr/bin/perl -w #Linux compatibility
##!/usr/local/bin/perl -w
##!/usr/pub/bin/perl5 -w
##!/usr/pub/bin/perl4 -w
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
#
# UNIX:     cleans up /home/$ENV{USER}/work/
# 
# NOTE:     input date (day!): 
#           EVERYTHING differing from date number will be deleted
#
$[ =1 ;

print "xx old program !!! \n";
print "take cleanUpPP.pl\n";
exit;

$dirRun=     "/home/$ENV{USER}/server/work/";    # HARD_CODED
$dirRunErr=  "/home/$ENV{USER}/server/err/"; # HARD_CODED
$dirTrash=   "/home/$ENV{USER}/server/trash/";   # HARD_CODED

if ($#ARGV<1) {
    print "UNIX:   remove all files in $dirRun (def)\n";
    print "\n";
    print "in:  date (e.g. jan-1, or day=1,..,31 month=Jan)\n";

    print "opt: \n";
    print "     'screen'  to print onto screen\n";
    print "     dirRun   =$dirRun   (def)\n";
    print "     dirRunErr=$dirRunErr   (def)\n";
    print "     dirTrash =$dirTrash   (def)\n";
    exit; }

if ($ARGV[1] eq "auto"){
    $date=`date`;		# system
    @Date=split(' ',$date);
    $dateIn=$Date[2]." ".$Date[3];
    print "NOW:    ==========================\n";
    print "NOW:    TAKE as default today =$dateIn\n";
    print "NOW:    ==========================\n";
    sleep (10);			# sleep to make this message visible
} else{
    $dateIn=$ARGV[1];}

$Lscreen=0;
foreach $_ (@ARGV){
    if    ($_=~/^screen|^de?bu?g$/i) { $Lscreen=   1;}
    elsif ($_=~/^dirRun=(.*)/)       { $dirRun=    $1;}
    elsif ($_=~/^dirRunErr=(.*)/)    { $dirRunErr= $1;}
    elsif ($_=~/^dirTrash=(.*)/)     { $dirTrash=  $1;}
}
	

if (! -d $dirRun) {
    print "*** $scrName: input directory (resp default=$dirRun) missing!!\n";
    exit(1); }

				# make missing trash dir
foreach $dir ($dirRunErr,$dirTrash) {
    next if (-d $dir);
    system("mkdir $dir");}

$fileLog=$dirRun.$$.".tmp";	# HARD_CODED
$fhin="FHIN";
				# ------------------------------
				# list files
print "--- system \t 'ls -l $dirRun >> $fileLog'\n"      if ($Lscreen);
system("ls -l $dirRun >> $fileLog");

print "--- system \t 'ls -l $dirRunErr >> $fileLog'\n" if ($Lscreen);

system("ls -l $dirRunErr >> $fileLog");
	    
open($fhin, $fileLog) || do { $msg="*** ERROR $scrName failed opening old=$fileLog\n";
			      print $msg;
			      die("$msg");};
while (<$fhin>) {
    $_=~s/\n//g;
    @tmp=split(/\s+/,$_);
    $month=$tmp[6];$day=$tmp[7];$file=$tmp[9];
    next if ( ! defined $month || ! defined $day || ! defined $file);
    printf "--- reading: %-3s %3d %-s\n",$month, $day,$file if ($Lscreen);
	
    if    (($dateIn =~/[A-Z][a-z][a-z]/)&&($month eq $dateIn)){
	$fileDel=$dirUnix."$file";
	$fileDel=$dirUnixError."$file" if (! -e $fileDel);
	next if (-d $fileDel); # skip if directory
	if (-e $fileDel){
	    print "--- system \t '\\rm $fileDel'\n" if ($Lscreen);
	    system("\\rm $fileDel");}}
    elsif (($dateIn =~/\d+/)&&($day != $dateIn)){
	$fileDel=$dirUnix."$file";
	$fileDel=$dirUnixError."$file" if (! -e $fileDel);
	next if (-d $fileDel); # skip if directory
	if (-e $fileDel){
	    print "--- system \t '\\rm $fileDel'\n" if ($Lscreen);
	    system("\\rm $fileDel");}}
    else {
	print "--- keep \t '$file' (from today)\n"  if ($Lscreen);
    }
}
close($fhin);

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
