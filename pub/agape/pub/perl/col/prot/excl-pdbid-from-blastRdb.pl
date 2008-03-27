#!/usr/sbin/perl -w
#
#  reads any file and excludes all lines containing a particular PDBid
#
$[ =1 ;
				# include libraries
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
require "ctime.pl";
require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
				# help
if ($#ARGV<1){
    print "goal:    reads any file and excludes all lines containing a particular PDBid\n";
    print "         in contrast to its brother (excl-pdbid-from-file) this is ONLY\n";
    print "         tailored to blast.rdb headers (ignoring names!!)\n";
    print "usage:   script file-with-ids-to-exclude * (any files)\n";
    print "note:    give exactly like to exclude      (e.g 1pdb_A or 1pdbA)\n";
    print "options: \n";
    exit;}
				# initialise variables
$fhin="FHIN";$fhout="FHOUT";
				# read command line
$fileExcl=$ARGV[1];
$#fileIn=0;
foreach $_(@ARGV){
    next if ($_ eq $fileExcl);
    if (-e $_){push(@fileIn,$_);}
    else {print"*** wrong command line arg '$_' (or not existing file)\n";
	  die;}}
				# ------------------------------
				# (1) read ids to exclude
&open_file("$fhin", "$fileExcl");
$excl="";undef %excl;
while (<$fhin>) {$_=~s/\n//g;
		 $excl{$_}=1;
		 $excl.="$_"."|";}close($fhin);$excl=~s/\|$//g;
if (length($excl)<3){
    print "*** excl=$excl, from $fileExcl, is that correct??? \n";
    die;}
				# ------------------------------
				# (2) loop over all files 

foreach $fileIn(@fileIn){
    &open_file("$fhin", "$fileIn");
    $tmp=$fileIn;$tmp=~s/^.*\///g;
    $fileOut=$tmp."_out";
#    $fileOut="out-".$tmp;
    &open_file("$fhout",">$fileOut"); 
    print "--- read '$fileIn' write $fileOut\n";
    while (<$fhin>) {
	if ($_=~/^\#|^id/){
	    print $fhout $_;
	    next;}
	@tmp=split(/[\t\s]+/,$_);
	$id=substr($tmp[2],1,4);
	if (defined $excl{$id}){
	    print "xx matching:$_";
	    next;}
	print $fhout $_;
    }
    close($fhin);close($fhout);
}

print "--- output in files: $fileOut\n";
exit;
