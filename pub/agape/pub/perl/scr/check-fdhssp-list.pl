#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
# checks for existence of F/D/HSSP files
# note: for D and HSSP chain will be deleted
#
#
$[ =1 ;

push (@INC, "/home/rost/perl", "/u/rost/perl") ;
# require "ctime.pl";		# require "rs_ut.pl" ; 
require "lib-ut.pl"; require "lib-br.pl";
# require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";

if ($#ARGV<1){print"goal:   checks for existence of F/D/HSSP files\n";
	      print"usage:  'script list' (option screen)\n";
	      print"note:   rather simple, for D and HSSP chain deleted\n";
	      exit;}

$fileIn=$ARGV[1];
$fhin="FHIN";$fhout="FHOUT";$fileOut=$fileIn."-ok";
$Lscreen=0;

foreach $_ (@ARGV){if (/screen/){$Lscreen=1;
				   last;}}
&open_file("$fhin", "$fileIn");
&open_file("$fhout", ">$fileOut");
$ct_missing=0;
while (<$fhin>) {
    $_=~s/\n|\s//g;$lineRd=$_;$Lfound=0;
    next if (length($lineRd)<5); # strange line
    if (-e $lineRd){	# existing file
	if (($lineRd=~/\.hssp/) && &is_hssp_empty($lineRd)){ # empty HSSP?
	    ($file,$chainRd)=&hsspGetFile($lineRd,1);
	    if ($file && (! &is_hssp_empty($lineRd))){
		$fileFound=$file; $Lfound=1;}}
	else {
	    $fileFound=$lineRd; $Lfound=1;}}
    $lineNow=$lineRd;
    if (! $Lfound && ($lineNow =~ /_/)){
	$lineNow=~s/_.//g;	# cut chain
	if (-e $lineNow){
	    $fileFound=$lineNow; $Lfound=1;}}
				# search alternative
    if (! $Lfound){
	if ($lineNow=~/dssp/){
	    ($file,$chainRd)=&dsspGetFile($lineNow,1);}
	elsif ($lineNow=~/hssp/){
	    ($file,$chainRd)=&hsspGetFile($lineNow,1);}
	elsif ($lineNow=~/fssp/){
	    ($file,$chainRd)=&fsspGetFile($lineNow,1);}
	$fileFound=$file; }
    if (-e $fileFound){
				# get chain back in
	$chain=$lineRd;
	if    ($chain=~/^.*(_\!_[A-Z0-9])$/){$chain=$1;}
	elsif ($chain=~/^.*(_[A-Z0-9])$/)   {$chain=$1;}
	else  {$chain="";}
	if ($Lscreen){print  "--- ok:$fileFound ($chain)\n";}
	print $fhout "$fileFound"."$chain\n";}
    else {
	print "*** missing:$lineRd,$lineNow,$fileFound,\n";++$ct_missing;}
}close($fhin);close($fhout);

print "--- $ct_missing files missing\n";
print "--- output in $fileOut\n";
exit;
