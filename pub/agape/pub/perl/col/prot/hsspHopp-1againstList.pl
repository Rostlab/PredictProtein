#!/usr/sbin/perl -w
#
# reads id in 1 HSSP file, returns all similar ids in list of HSSP
#
$[ =1 ;

				# include libraries
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
require "ctime.pl";
require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
				# ------------------------------
				# defaults
#$par{"file"}="/home/rost/pub/data/hssp/hssp792Hopp.rdb";
$par{"dirHssp"}="/data/hssp/";
$par{"extHssp"}=".hssp";

$fhin="FHIN";$fhout="FHOUT";

if ($#ARGV<2){print"goal:   reads id in 1 HSSP file, returns all similar ids in list of HSSP\n";
	      print"usage:  script hssp1 others\n";
	      print"option: dirHssp=x\n";
	      exit;}
				# ------------------------------
				# first read families
#$fileIn=$par{"fileHopp"};
$fileIn=$ARGV[1];if (! -e $fileIn){$fileIn=$par{"dirHssp"}.$fileIn;}
if (! -e $fileIn){print"*** no $fileIn (file with HSSP families: id1\tswiss1,swiss2)\n";
		  die;}
				# ------------------------------
$#hsspList=0;			# read command line
foreach $arg (@ARGV) {next if ($arg eq $ARGV[1]);
		      $tmp=$par{"dirHssp"}.$arg;
		      if (! -e $arg && (-e $tmp)){
			  $arg=$tmp;}
		      if (-e $arg && (&is_hssp($arg))){
			  push(@hsspList,$arg);}
		      else{
			  print "*** command line '$arg' not digested\n";die;}}

				# --------------------------------------------------
$#id1=0;			# read all names in guide file
%rd=&hssp_rd_header($fileIn);
foreach $it (1..$rd{"NROWS"}){
    $rd{"$it","ID"}=~s/\s+.*$//g; # delete possible 'lyn_rat 1nyf' 
    $rd{"$it","ID"}=~s/\d[A-Z0-9][A-Z0-9][A-Z0-9].*$//g; # delete possible 'lck_human1CWD_?' 
    if (length($rd{"$it","ID"})>4){
	push(@id1,$rd{"$it","ID"});}}
foreach $id1(@id1){		# ini res
    $ok{"$id1"}=1;$res{"$id1"}="";}
print "--- ids read ($fileIn): ";foreach $id1(@id1){print "$id1,";}print"\n";

				# --------------------------------------------------
				# read all names in to-be-checked-files
foreach $fileIn2 (@hsspList){
    %rd=0;%rd=&hssp_rd_header($fileIn2);
    print "--- reading $fileIn2\n";
    $idFile2=$fileIn2;$idFile2=~s/^.*\///g;$idFile2=~s/\.hssp.*$//g;
    foreach $it (1..$rd{"NROWS"}){
	$rd{"$it","ID"}=~s/\s+.*$//g; # delete possible 'lyn_rat 1nyf' 
	$rd{"$it","ID"}=~s/\d[A-Z0-9][A-Z0-9][A-Z0-9].*$//g; # delete possible 'lck_human1CWD_?' 
	$id2=$rd{"$it","ID"};
	next if (length($rd{"$it","ID"})<4);	# wrong id
	next if (! $ok{"$id2"}); # not in HSSP1
	$res{"$id2"}.="$idFile2,";}}
				# --------------------------------------------------
				# print output
$fileOut="Out-".$fileIn;
foreach $id1(@id1){
    next if (length($res{"$id1"})<4);
    print "$id1\t",$res{"$id1"},"\n";}
exit;				# xx

&open_file("$fhout",">$fileOut"); close($fhout);

exit;
