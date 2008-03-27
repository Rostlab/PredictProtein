#!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="extract a range (and or chain) from HSSP file";
#  
#
$[ =1 ;
				# include libraries
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
require "ctime.pl";
require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
				# help
if ($#ARGV<2){
    print "goal:\t $scrGoal\n";
    print "use: \t '$scrName file_hssp chain ('0' for wild card)'\n";
    print "opt: \t range=1-5,8-100 (PDBno! ; note: default expects this as 3rd argument, no keywrd)\n";
    print "     \t \n";
    print "     \t fileOut=x\n";
#    print "     \t \n";
    exit;}
				# initialise variables
$fhin="FHIN";$fhout="FHOUT";
				# read command line
$fileIn=  $ARGV[1];
$chainIn= $ARGV[2];
$tmp=$fileIn;$tmp=~s/^.*\///g;$fileOut="Out-".$tmp;

foreach $_(@ARGV){
    next if ($_ eq $ARGV[1]);next if ($_ eq $ARGV[2]);
    if   ($_=~/^fileOut=(.*)$/){$fileOut=$1;}
    elsif($_=~/^range=(.*)$/){$rangeIn=$1;}
    else { if ($_ eq $ARGV[3]){ $rangeIn=$ARGV[3];
				next;}
	   print"*** wrong command line arg '$_'\n";
	   die;}}

				# ------------------------------
				# (1) get range
@tmp=split(/,/,$rangeIn);
foreach $it (1..10000){$ok[$it]=0;}
$nres=0;
foreach $tmp(@tmp){
    $tmp=~s/\s//g;
    @tmp2=split(/-/,$tmp);
    foreach $it ($tmp2[1]..$tmp2[2]){++$nres;
				     $ok[$it]=1;}
    $max=$tmp2[2];}
				# ------------------------------
				# (2) read file
&open_file("$fhin", "$fileIn");
$#rd=0;
while (<$fhin>) {push(@rd,$_);
		 last if ($_=~/^\#\# ALI/);}
while (<$fhin>) {if ($_=~/^(\#| Seq)/){push(@rd,$_) ;
				       $ctRes=0;
				       last if ($_=~/^\#\# SEQ/);
				       next;}
		 $line=$_;
		 $chain=substr($_,12,1);
		 $pdbNo=substr($_,7,6);$pdbNo=~s/\s//g;
		 next if ($chainIn ne "0" && $chain ne $chainIn);
		 next if (! $ok[$pdbNo]);
		 push(@rd,$line);
		 ++$ctRes; 
		 if ($ctRes > $nres){
		     print "*** $fileIn too many residues now $ctRes max=$max, nres=$nres,\n";
		     exit;}}
while (<$fhin>) {if ($_=~/^(\#| Seq)/){push(@rd,$_) ;
				       $ctRes=0;
				       last if ($_=~/^\#\# INS/);
				       next;}
		 $line=$_;
		 $chain=substr($_,12,1);
		 $pdbNo=substr($_,6,5);$pdbNo=~s/\s//g;
		 next if ($chainIn ne "0" && $chain ne $chainIn);
		 next if (! $ok[$pdbNo]);
		 push(@rd,$line);
		 ++$ctRes; 
		 if ($ctRes > $nres){
		     print "*** $fileIn too many residues now $ctRes max=$max, nres=$nres,\n";
		     exit;}}

while (<$fhin>) {push(@rd,$_);}close($fhin);
				# ------------------------------
				# (2) write output
&open_file("$fhout",">$fileOut"); 
foreach $rd(@rd){
    if ($rd =~/^SEQLENGTH/){
	printf $fhout "SEQLENGTH %5d\n",$nres;}
    else{
	print $fhout $rd;}}
close($fhout);

print "--- output in $fileOut\n";
exit;
