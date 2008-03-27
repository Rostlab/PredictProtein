#!/usr/sbin/perl -w
#
#  eat OutSwiss-hssp849.list (from hssp_extr_id.pl), ids -> numbers to save space
#
$[ =1 ;

				# include libraries
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
require "ctime.pl";
require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";

if (! defined $ENV{'PWD'}) {
    open(C,"/bin/pwd|");$PWD=<C>;close(C);}
else {
    $PWD=$ENV{'PWD'};}
$pwd=$PWD."/";$pwd=~s/\/\//\//g;
				# initialise variables
if ($#ARGV<1){print
		  "goal:   eat OutSwiss-hssp849.list (from hssp_extr_id.pl), ".
		  "ids -> numbers to save space\n";
	      print "usage:  script OutSwiss-hssp849.dat\n";
	      exit;}

$fileIn=$ARGV[1];
$fhin="FHIN";$fhout="FHOUT";
$fileOut=$fileIn;$fileOut=~s/[Oo]ut|[Ss]wiss//g;$fileOut="SwId2no-".$fileOut;
$fileOut=~s/\-+/-/g;$fileOut=~s/-\./\./g;
$fileOutRef="REF-".$fileOut;$fileOutRef=~s/\.dat/\.list/;
				# ------------------------------
				# read all ids 1st: extract ids
&open_file("$fhin", "$fileIn");
%ct=0;$#swiss=0;
while (<$fhin>) {$_=~s/\n//g;$_=~s/^\s*|\s*$//g;
		 next if (/^\#|^id/);
		 @tmp=split(/\s+/,$_);
		 $id1=$tmp[1];$swiss=$tmp[2];
		 next if (!defined $swiss);
		 @tmp=split(/,/,$swiss);
		 foreach $tmp (@tmp){
		     $tmp=~s/\s//g;
		     if (! defined $ct{"$tmp"}){$ct{"$tmp"}=1;
						push(@swiss,$tmp);}
		     else { ++$ct{"$tmp"};}}}close($fhin);
				# ------------------------------
@tmp = sort (@swiss);		# sort
$ct=0;$#swiss=0;
foreach $swiss (@tmp){		# only those with double count
    if ($ct{"$swiss"}>1){
#    if ($ct{"$swiss"}>0){
	++$ct;push(@swiss,$swiss);}}
foreach $it (1..$#swiss){	# ptr to array
    $swiss=$swiss[$it];
    $ptr{"$swiss"}=$it;}
				# ------------------------------
				# write reference file
&open_file("$fhout",">$fileOutRef"); 
print $fhout "NoRef\tidSwiss\n";
foreach $it (1..$#swiss){	# ptr to array
    $swiss=$swiss[$it];
    printf $fhout "%6d\t%-s\n",$it,$swiss;}
close($fhout);
				# ------------------------------
				# read all ids 2nd: rewrite
&open_file("$fhout",">$fileOut"); # write output
$tmp=$fileOutRef; if ($tmp!~/\//){$tmp=$pwd.$fileOutRef;}

print $fhout "\# REF numbers referenced in: $tmp\n";
print $fhout "id1\tidSwiss\n";
&open_file("$fhin", "$fileIn");
while (<$fhin>) {$_=~s/\n//g;$_=~s/^\s*|\s*$//g;
		 next if (/^\#|^id/);
		 @tmp=split(/\s+/,$_);
		 $id1=$tmp[1];$swiss=$tmp[2];
		 next if (!defined $swiss);
		 @tmp=split(/,/,$swiss);
		 $tmp="";
		 foreach $swiss (@tmp){$swiss=~s/\s//g;
				       if (defined $ptr{"$swiss"}){
					   $tmp.=$ptr{"$swiss"}.",";}}
		 $tmp=~s/,$//g;$swiss=$tmp;
		 if (length($swiss)>5){
		     printf $fhout "%-6s\t%-s\n",$id1,$swiss;}}close($fhin);

print "--- output in $fileOut, references in $fileOutRef\n";
exit;
