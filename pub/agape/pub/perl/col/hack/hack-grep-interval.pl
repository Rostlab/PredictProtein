#!/usr/sbin/perl -w
#
# reads files detT-all.dat, greps ids in interval of threshold (20-35%)
#
$[ =1 ;

				# include libraries
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
require "ctime.pl";
require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
				# initialise variables
if ($#ARGV<1){print"goal:   reads files detT-all.dat, greps ids in interval (20-35%)\n";
	      print"usage:  script detT-all.dat (detF-all.dat)\n";
	      exit;}

$max=    10;
$min=    -5;
$maxNfam=20;			# less than 20 cases per family

$dirHssp="/data/hssp/";

$fileIn=$ARGV[1];
$fhin="FHIN";$fhout="FHOUT";
$fileOut="Out-".$fileIn;
				# ------------------------------
				# read file
&open_file("$fhin", "$fileIn");
%ok=0;$#found=0;$ct=$ct1=0;
while (<$fhin>) {$_=~s/\n//g;
		 ++$ct; if ($ct>50000){++$ct1;$ct=0;printf "--- line %8d\n",$ct1*50000;}
		 next if (/^id/);
		 @tmp=split(/[\t\s]+/,$_);
		 next if ($tmp[10]>$max);
		 next if ($tmp[10]<$min);
				# dont count twice (1crn = 2crn)
		 $tmp= "$tmp[1],$tmp[2]";
		 $tmp1=substr($tmp[1],2) . "," . substr($tmp[2],2);
		 $tmp2=substr($tmp[2],2) . "," . substr($tmp[1],2);
		 next if (defined $ok{"$tmp1"} || defined $ok{"$tmp2"});
		 $ok{"$tmp1"}=$ok{"$tmp2"}=1;
		 push(@found,$tmp);}close($fhin);
				# ------------------------------
				# restrict families
%ok=0;$#id=0;
foreach $found (@found){
    ($id1,$id2)=split(/,/,$found);
    if (!defined $ok{"$id1"}){
	$ok{"$id1"}=1;
	push(@id,$id1);
	$ct=0;}
    ++$ct;
    if ($ct<=$maxNfam){
	push(@id,$id2);}}
				# ------------------------------
				# write all ids
&open_file("$fhout",">$fileOut"); 
$ct=0;%ok=0;
foreach $id (@id){
    print "--- check id $id\n";
    $tmp=$id;$tmp=~s/_.//g;
    if ($id =~ /_(.)$/){$chain=$1;}else{$chain="";}
    $file= $dirHssp.$tmp.".hssp";
    $fileC=$dirHssp.$tmp.".hssp"; if (length($chain)>0){$fileC.="_".$chain;}
    if (! defined $ok{"$id"}){
	$ok{"$id"}=1;
	if (-e $file){
	    ++$ct;
	    print $fhout "$fileC\n";}
	else {
	    print "*** missing $file\n";}}}

close($fhout);
print "--- no ids found: $ct, output in $fileOut\n";

exit;
