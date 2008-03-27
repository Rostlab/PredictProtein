#!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="removes sequence from HTML file of PHDhtm\n";
#  
#
$[ =1 ;
				# ------------------------------
				# include libraries
foreach $arg(@ARGV){
    if ($arg=~/dirLib=(.*)$/){$dir=$1;
			      last;}}
$dir=$ENV{'PERLLIB'}    if (defined $ENV{'PERLLIB'} || ! defined $dir || ! -d $dir);
$dir="/home/rost/perl/" if (! defined $dir || ! -d $dir);
$dir.="/"               if ($dir !~/\/$/);
$dir=""                 if (! -d $dir);
foreach $lib("lib-ut.pl","lib-prot.pl","lib-comp.pl"){
    $Lok=require $dir."lib-ut.pl"; 
    die("*** $scrName: failed to require perl library '$lib' (dir=$dir)\n") if (! $Lok);}
				# ------------------------------
				# defaults
				# ------------------------------
if ($#ARGV<1){			# help
    print "goal:\t $scrGoal\n";
    print "use: \t '$scrName file.html' (only one)\n";
    print "opt: \t \n";
    print "     \t fileOut=x\n";
#    print "     \t \n";
    exit;}
				# initialise variables
$fhin="FHIN";$fhout="FHOUT";
				# ------------------------------
$#fileIn=0;			# read command line
foreach $arg (@ARGV){
    if   ($arg=~/^fileOut=(.*)$/){$fileOut=$1;}
#    elsif($arg=~/^=(.*)$/){$=$1;}
    else {$Lok=0;
	  if (-e $arg){$Lok=1;
		       push(@fileIn,$arg);}
	  if (! $Lok){print"*** wrong command line arg '$arg'\n";
		      die;}}}
$fileIn=$fileIn[1];
die ("missing input $fileIn\n") if (! -e $fileIn);
$tmp=$fileIn;$tmp=~s/^.*\///g;$fileOut="Out-".$tmp;
				# ------------------------------
				# (1) read file(s)
foreach $fileIn(@fileIn){
    if (! -e $fileIn){print "-*- WARN $scrName: no fileIn=$fileIn\n";
		      next;}
    print "--- $scrName: working on '$fileIn'\n";
    if (! defined $fileOut){
	$tmp=$fileIn;$tmp=~s/^.*\///g;$fileOut="Out-".$tmp;}
    if ($fileOut eq $fileIn ){
	$fileOut="New-".$fileOut;}
    if (-e $fileOut){ $ct=0;
		      while(-e $fileOut){++$ct;
					 $fileOut.="$ct";}}
    $Lok=&open_file("$fhin", "$fileIn");
    if (! $Lok){print "*** $scrName: failed to open fileIn=$fileIn\n";
		next;}
    &open_file("$fhout",">$fileOut"); 
    $Ltable=0;
    while (<$fhin>) {
	$Ltable=1 if (! $Ltable && $_=~/^<TABLE BORDER/); # begin of table
	$Ltable=0 if ($Ltable && $_=~/^<\/TABLE>/); # end of table

	if (! $Ltable)           {print $fhout $_;
				  next;}
				# from here on: only for table
	if ($_ !~ /^<TR>[\s\t]+/){print $fhout $_; # no sequence in this line
				  next;}
	$_=~s/^(.*)<TD ALIGN=LEFT>[^<]+(<\/TD><\/TR>\n)/$1<TD ALIGN=LEFT> <A HREF=\"\.\.\/seq\/afSeq\.dat\"> all_sequences_here<\/A> $2/;
	print $fhout $_;}close($fhin);close($fhout);
    print "--- fileOut=$fileOut\n";
}
exit;
