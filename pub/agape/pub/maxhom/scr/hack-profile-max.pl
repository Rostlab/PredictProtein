#!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="".
    "     \t";
#  
#
$[ =1 ;
				# include libraries
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
require "ctime.pl";
require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
				# help
if ($#ARGV<1){
    print "goal:\t $scrGoal\n";
    print "use: \t '$scrName'\n";
    print "opt: \t \n";
    print "     \t fileOut=x\n";
#    print "     \t \n";
    exit;}
				# initialise variables
$fhin="FHIN";$fhout="FHOUT";
				# read command line
$fileIn=$ARGV[1];
$tmp=$fileIn;$tmp=~s/^.*\///g;$fileOut="Out-".$tmp;

foreach $_(@ARGV){
    next if ($_ eq $ARGV[1]);
    if   ($_=~/^fileOut=(.*)$/){$fileOut=$1;}
#    elsif($_=~/^=(.*)$/){$=$1;}
    else {print"*** wrong command line arg '$_'\n";
	  die;}}

$exeMaxLoc="/home/rost/pub/max/bin/maxhom.SGI64";
$fileDefaultLoc="maxhom.default";
$niceLoc=" ";

$fileMaxIn="oxf.profile";
$fileMaxList="filter.list_11378";

$jobid=11378;

$paraMaxNali=  "1000";
$paraMaxThresh="FORMULA";
$paraMaxSort=  "DISTANCE";
$paraMax="";
$paraMax="";
$paraMax="";
$fileHsspOut="xx-out-prof.hssp";

$command=
    eval "\$command=\"$niceLoc $exeMaxLoc -d=$fileDefaultLoc -nopar ,
         COMMAND       NO ,
         BATCH ,
         PID:          $jobid ,
         SEQ_1         $fileMaxIn ,      
         SEQ_2         $fileMaxList ,
         PROFILE       ,
         NO       ,
         PROFILE       ,
         PROFILE       ,
         PROFILE       ,
         PROFILE       ,
         PROFILE       ,
         NO       ,
         NO       ,
         NO       ,
         NBEST         1,
         MAXALIGN      $paraMaxNali ,
         THRESHOLD     $paraMaxThresh ,
         SORT          $paraMaxSort ,
         HSSP          $fileHsspOut ,
         SAME_SEQ_SHOW YES ,
         SUPERPOS      NO ,
         PDB_PATH      /data/pdb ,
         PROFILE_OUT   NO ,
         STRIP_OUT     NO ,
         DOT_PLOT      NO ,
         RUN ,\"";

&run_program("$command","STDOUT");
exit;
				# ------------------------------
				# (1) read file
&open_file("$fhin", "$fileIn");
while (<$fhin>) {
    $_=~s/\n//g;
    $_=~s/^.*\///g;		# purge directory
}
close($fhin);

				# ------------------------------
				# (2) 

				# ------------------------------
				# write output
&open_file("$fhout",">$fileOut"); 
close($fhout);

print "--- output in $fileOut\n";
exit;
