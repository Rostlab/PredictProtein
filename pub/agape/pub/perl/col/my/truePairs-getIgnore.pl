#!/usr/sbin/perl -w
#
#  read two lists of true pairs and write an 'ignore' list for all only in list2
#
$[ =1 ;
				# include libraries
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
require "ctime.pl";
require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
				# help
$file1="/home/rost/pub/data/truePairs849Hand.dat";
$file2="/home/rost/pub/data/truePairs849Triangle.dat";

if ($#ARGV<1){
    print "goal:    read two lists of true pairs, writes 'ignore' list for all only in list2\n";
    print "reason:  may be that some are not found by FSSP, were regarded true\n";
    print "         by applying the 'triangle' but may be too relaxed now...\n";
    print "         \n";
    print "usage:   script def (or true1 true2)\n";
    print "         \n";
    print "note:    default files:\n";
    print "         1=$file1\n";
    print "         2=$file2\n";
    print "options: def \n";
    print "         fileOut=x\n";
    exit;}
				# initialise variables
$fhin="FHIN";$fhout="FHOUT";
				# read command line
$Ldef=0;
foreach $_(@ARGV){
    if   ($_=~/^fileOut=(.*)$/){$fileOut=$1;}
    elsif($_=~/^def\w*$/){$Ldef=1;}
    else {print"*** wrong command line arg '$_'\n";
	  die;}}
if (! $Ldef){
    $file1=$ARGV[1];
    $file2=$ARGV[2];}
if (! defined $fileOut){
    $fileOut="Out-ignore.dat";}
				# ------------------------------
				# read two files
$#id1=0;
foreach $fileTrue ($file1,$file2){
    if (! -e $fileTrue){
	print "*** ERROR blastHeaderRdb2stat: fileTrue '$fileTrue' missing\n";
	exit;}
    print "--- reading fileTrue \t $fileTrue\n";
    if ($fileTrue eq $file1){$num=1;}else{$num=2;}
    &open_file("$fhin", "$fileTrue"); # external lib-ut.pl
    while(<$fhin>){$_=~s/\n//g;
		   ($tmp1,$tmp2)=split(/\t/,$_);
		   $id1=substr($tmp1,1,4); # purge chains
		   $tmp2=~s/,$//g;
		   if (! defined $id{$id1}){
		       $id{$id1}=1;push(@id1,$id1);}
		   $true{"$id1","$num"}=$tmp2;}close($fhin);}
				# ------------------------------
				# go through all
$#ignore=0;
$ct1=$ct2=$ctnot=0;
foreach $id1 (@id1){
    if (defined $true{"$id1","1"} && defined $true{"$id1","2"}){
	$tmp1=$true{"$id1","1"};$tmp1=~s/^,*|,*$//g;$tmp1=~s/,,/,/g;
	$tmp2=$true{"$id1","2"};$tmp2=~s/^,*|,*$//g;$tmp2=~s/,,/,/g;
	@tmp1=split(/,/,$tmp1);
	@tmp2=split(/,/,$tmp2);
	undef %tmp; $not="";
	foreach $tmp (@tmp1){
	    ++$ct1;$tmp{$tmp}=1;}
	foreach $tmp (@tmp2){
	    ++$ct2;
	    if (! defined $tmp{$tmp}){
		++$ctnot;
		$not.="$tmp,";}}
	$not=~s/,*$//g;
	push(@ignore,"$id1\t$not");}
    elsif (defined $true{"$id1","2"}){
	$tmp2=$true{"$id1","2"};$tmp2=~s/^,*|,*$//g;$tmp2=~s/,,/,/g;
	push(@ignore,"$id1\t$tmp2");}}

&open_file("$fhout",">$fileOut"); 
foreach $ignore(@ignore){
    print $fhout "$ignore\n";
}
close($fhout);

printf "--- %10d = number of main\n",$#id1;
printf "--- %10d = number of 2nd in 1 ($file1)\n",$ct1;
printf "--- %10d = number of 2nd in 2 ($file2)\n",$ct2;
printf "--- %10d = number of 2nd to ignore\n",$ctnot;
print "--- output in $fileOut\n";
exit;
