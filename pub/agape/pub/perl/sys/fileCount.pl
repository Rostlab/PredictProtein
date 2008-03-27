#!/usr/bin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="count number of files in directories";
#  
#
$[ =1 ;

if ($#ARGV<1){
    print "goal:\t $scrGoal\n";
    print "use: \t '$scrName dir*'\n";
    print "opt: \t pat=xx   (count only files with xx)\n";
    print "     \t fileOut=x\n";
#    print "     \t \n";
    exit;}
				# initialise variables
$fhin="FHIN";$fhout="FHOUT";
				# read command line
$dirIn=$ARGV[1];
#$tmp=$fileIn;$tmp=~s/^.*\///g;$fileOut="Out-".$tmp;
$#dirIn=0;push(@dirIn,$dirIn);
foreach $_(@ARGV){
    next if ($_ eq $ARGV[1]);
    if   ($_=~/^fileOut=(.*)$/){$fileOut=$1;}
    elsif($_=~/^pat=(.*)$/)    {$pat=$1;}
    elsif(-d $_)               {push(@dirIn,$_);}
    else {print"*** wrong command line arg '$_'\n";
	  die;}}
				# ------------------------------
				# (1) count files
foreach $dirIn(@dirIn){
    @files=`ls -1 $dirIn`;
    if (defined $pat){
	$ct=0;
	foreach $file(@files){
	    ++$ct               if ($file=~/$pat/);}
	$res{"$dirIn"}=$ct;}
    else             {
	$res{"$dirIn"}=$#files;}}
				# ------------------------------
				# (2) write
foreach $dirIn (@dirIn){
    printf "--- %8d %-s\n",$res{"$dirIn"},$dirIn;}

print "--- $scrName finished\n";
exit;
				# help

				# ------------------------------
				# (2) 

				# ------------------------------
				# write output
open("$fhout",">$fileOut"); 
close($fhout);

print "--- output in $fileOut\n";
exit;
