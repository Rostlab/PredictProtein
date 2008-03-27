#!/usr/sbin/perl -w
#
#  merges files id*.rdb
#
$[ =1 ;
				# include libraries
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
require "ctime.pl";
require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
				# help
if ($#ARGV<1){
    print "goal:    merges files id*.rdb\n";
    print "usage:   script *files\n";
    print "options: \n";
    print "         fileOut=x\n";
    print "         \n";
    print "         \n";
    exit;}
				# initialise variables
$fhin="FHIN";$fhout="FHOUT";
				# read command line
$fileOut="Out-merge.dat";
$#fileIn=0;
foreach $_(@ARGV){
    if   ($_=~/^fileOut=(.*)$/){$fileOut=$1;}
    elsif(-e $_){push(@fileIn,$_);}
    else {print"*** wrong command line arg '$_'\n";
	  die;}}
				# ------------------------------
				# (1) read files and write
if (-e $fileOut){$fileOut.=$$;}	# security: avoid overwriting
&open_file("$fhout",">$fileOut"); 
$names=$format=$ct=0;
foreach $fileIn(@fileIn){
    &open_file("$fhin", "$fileIn");
    while (<$fhin>) {$tmp=$_;	# first non comment: names
		     last if (/^pos/);
		     if (/^\# LEN1\s*:\s*(\d+)/){ $len1=$1;}}
    if ((!defined $names)||(! $names)){	# new name column (insert len1)
	$names=$tmp; $names=~s/\n//g;@tmp=split(/[\t\s]+/,$names);
	foreach $tmp(@tmp){$tmp=~s/\s//g; # purge blanks 
			   $tmp=~tr/[A-Z]/[a-z]/; # lower to upper
			   $tmp=~s/wsim/psim/;}
	$names="pos\t";		# IN: pos,id1,id2,pide,wsim,lali,ngap,lgap,len2
	foreach $it ( 2.. 6) {$names.="$tmp[$it]"."\t";} # -> lali
	$names.="$tmp[8]"."\t";$names.="$tmp[7]"."\t"; # change ngap,lgap -> lgap,ngap
	$names.="len1"."\t";$names.="$tmp[9]"; # do: len1,len2
	foreach $it (14..15) {$names.="\t"."$tmp[$it]";}
	print $fhout $names,"\n";
	$names=1;}
    $format=(<$fhin>);		# ignore formats
    while (<$fhin>) {$_=~s/\n//g;
		     next if (/^\#/);
		     next if (/^pos|^4[\s\t]+6S/); # continue to ignore names and formats
		     ++$ct;@tmp=split(/[\t\s]+/,$_);
		     print $fhout "$ct\t";
				# OUT: id1,id2,pide,psim,lali,lgap,ngap,len1,len2
		     foreach $it ( 2.. 6){print $fhout "$tmp[$it]"."\t";}
		     print $fhout "$tmp[8]","\t","$tmp[7]"."\t";
		     print $fhout "$len1","\t","$tmp[9]";
		     foreach $it (14..15){ # energy, zscore
			 print $fhout "\t"."$tmp[$it]";}
		     print $fhout "\n";} close($fhin);
}
close($fhout);

print "--- output in $fileOut\n";
exit;
				# ------------------------------
				# (2) 

				# ------------------------------
				# write output
&open_file("$fhout",">$fileOut"); 
close($fhout);

print "--- output in $fileOut\n";
exit;
