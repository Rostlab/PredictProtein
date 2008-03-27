#! /usr/bin/perl -w
##!/usr/bin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="reads directory (writes into file dir.index)";
# 
#------------------------------------------------------------------------------#
#	Copyright				        	1999	       #
#	Burkhard Rost		rost@EMBL-Heidelberg.DE			       #
#	CUBIC (Columbia Univ)	http://www.embl-heidelberg.de/~rost/	       #
#       Dep Biochemistry & Molecular Biophysics				       #
#       630 West, 168 Street						       #
#	New York, NY 10032	http://www.dodo.cpmc.columbia.edu/~rost/       #
#				version 0.1   	Apr,    	1999	       #
#------------------------------------------------------------------------------#
#

$[ =1 ;
				# ------------------------------
if ($#ARGV<1){			# help
    print "xx came here\n";
    print  "goal: $scrGoal\n";
    print  "use:  '$scrName dir'\n";
    print  "opt:  \n";
				#      'keyword'   'value'    'description'
    printf "%5s %-15s=%-20s %-s\n","","fileOut", "x",       "name of output file";
    printf "%5s %-15s=%-20s %-s\n","","purge",   "/data/x", "purge /data/x from output file name";
#    printf "%5s %-15s=%-20s %-s\n","","dirOut",  "x",       "directory of output files";
#    printf "%5s %-15s=%-20s %-s\n","","",   "x", "";
#    printf "%5s %-15s %-20s %-s\n","","",   "no value","";

#    printf "%5s %-15s %-20s %-s\n","","dbg",   "no value",   "debug mode";
#    printf "%5s %-15s %-20s %-s\n","","silent|-s","no value","no screen output";
#    printf "%5s %-15s %-20s %-s\n","","verb|-s",  "no value","verbose";
    exit;}
				# initialise variables
$fhout="FHOUT";
				# ------------------------------
				# read command line
$#dirIn=0; $purge=0;
foreach $arg (@ARGV){
    if    ($arg=~/^fileOut=(.*)$/)        { $fileOut=        $1;}
    elsif ($arg=~/^dirOut=(.*)$/)         { $dirOut=         $1; 
					    $dirOut.=        "/" if ($dirOut !~/\/$/);}
    elsif ($arg=~/^purge=(.*)$/)          { $purge=          $1;}
#    elsif ($arg=~/^de?bu?g$/)             { $Ldebug=         1;}
#    elsif ($arg=~/^verb(ose)?$|^\-v$/)    { $Lverb=          1;}
#    elsif ($arg=~/^silent$|^\-s$/)        { $Lverb=          0;}
#    elsif ($arg=~/^=(.*)$/){ $=$1;}
    elsif  (-d $arg)                       { push(@dirIn,$arg); }
    else {
	print "*** wrong command line arg '$arg'\n";
	exit; }}

$dirIn=$dirIn[1];
die ("missing dir=$dirIn\n") if (! -d $dirIn);
if (! defined $fileOut){
    $tmp=$dirIn;$tmp=~s/^.*\///g; 
    $tmp="Out" if (length($tmp)<1); # correct
    $fileOut="INDEX.".$tmp;}

				# ------------------------------
				# open output file
if ($fileOut) {
    open($fhout,">".$fileOut) || 
	do { $fhout="STDOUT";
	     warn "*** $scrName ERROR creating file $fileOut"; };}
else {
    $fhout="STDOUT";}

				# ------------------------------
				# (1) read file(s)
				# ------------------------------
$#file=0;
foreach $dirIn (@dirIn) {
    opendir(DIR,$dirIn) || 
	die ("-*- ERROR $scrName: failed opening dirIn=$dirIn!\n");
#    print "xx rd dir=$dirIn,\n";
    @tmp=readdir(DIR);
    closedir(DIR); 
#    print "xx found n=",$#tmp,", files\n";

    $dirWrt=$dirIn;
    $dirWrt=~s/$purge//g        if ($purge);
    $dirWrt.="/"                if ($dirWrt !~/\/$/ && length($dirWrt)>=1);
    foreach $tmp (@tmp) {
	next if ($tmp=~/^\./);
	push(@file,$dirWrt.$tmp);
    }
}

$ct=0;
foreach $tmp (sort @file) {
    next if (-d $purge.$tmp);
#    next if (! -e $purge.$tmp);
    ++$ct;
    print $fhout "$tmp\n";
}
close($fhout)                   if ($fhout ne "STDOUT");

print "--- output in $fileOut\n" if (-e $fileOut);
print "--- nfiles=$ct\n";
exit;


