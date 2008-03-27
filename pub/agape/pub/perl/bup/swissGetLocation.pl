#!/usr/sbin/perl -w
#
# goal:   finds location in SWISS-PROT (nothing returned if not annotated)
# usage:  'script files '
#
$[ =1 ;
				# include libraries
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
# require "ctime.pl"; 
require "lib-ut.pl"; require "lib-br.pl";
# require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
				# initialise variables

if ($#ARGV<1){print "goal:   finds location in SWISS-PROT (nothing returned if not annotated)\n";
	      print "usage:  'script \@files (or id's)'\n";
	      print "output: array with matching lines (0 if none)\n";
	      print "option:\n";
	      print "        dir=x      (directory of swissprot)\n";
	      print "        fileOut=x  (RDB output, default 'Out-swissLoci.tmp')\n";
	      print "        verbose \n";
	      exit;}

$fhout="FHOUT_swissGetLocation";$fhin="FHIN_swissGetLocation";
$Lscreen=1;			# write output onto screen?
$regexp="^CC .*SUBCELLULAR LOCATION:";

				# ------------------------------
				# read command line
$#tmp=0;
foreach $it (1..$#ARGV){
    if ($ARGV[$it]=~/^dir=/){	# keyword (swissprot directory)
	$tmp=$ARGV[$it];$tmp=~s/^dir=//g;$par{"dir"}=&complete_dir($tmp);} # external lib-ut.pl
    elsif ($ARGV[$it]=~/^verbose/){
	$Lscreen=1;}
    elsif ($ARGV[$it]=~/^fileOut=/){ # output file name
	$tmp=$ARGV[$it];$tmp=~s/^fileOut=//g;$par{"fileOut"}=$tmp;}
    else {
	push(@tmp,$ARGV[$it]);}}
				# process input
$#file=0;
foreach $input(@tmp){
    if (-e $input){		# is existing file
	push(@file,$input);}
    if    (&isSwiss($input)){	# is SWISS-PROT file
	$file[1]=$input;}
    elsif (&isSwissList($input)){ # is list of SWISS-PROT files
	&open_file("$fhin", "$input");
	while (<$fhin>) {
	    $_=~s/\n//g;
	    if (-e $_){
		push(@file,$_);}}close($fhin);}
    else {			# search for existing
	$out=&swissGetFile($input,$Lscreen,$par{"dir"}); # external lib-ut.pl
	if (! $out){
	    next;}
	push(@file,$out);}}
				# ------------------------------
				# re-adjust defaults
if (! defined $par{"fileOut"}){
    $par{"fileOut"}="Out-"."swissLoci".".tmp";}
$fileOut=$par{"fileOut"};
if (!defined $par{"dir"}){$par{"dir"}="";}

if ($Lscreen){print 
		  "--- end of ini settings:\n",
		  "--- regexp = \t '$regexp'\n","--- file out: \t '$fileOut'\n",
		  "--- dirSwiss: \t '",$par{"dir"},"'\n","--- swiss files: \n";
	      foreach $file (@file){print"--- \t $file\n";}}

				# ------------------------------
				# now do for list
@out=
    &swissGetLocation($regexp,"STDOUT",@file); # external lib-prot.pl

$#fin=$#finId=0;
foreach $out (@out){$out=~s/\n//g;
		    ($fin,$finId)=split(/\t+/,$out);
		    push(@fin,$fin);push(@finId,$finId);}
				# ------------------------------
				# output file (RDB)
&open_file("$fhout", ">$fileOut");
print $fhout "\# Perl-RDB\n";
printf $fhout "%5s\t%-15s\t%-s\n","lineNo","id","location ";
printf $fhout "%5s\t%-15s\t%-s\n","5N","15","";
foreach $it (1..$#fin){
    printf $fhout "%5d\t%-15s\t%-s\n",$it,$finId[$it],$fin[$it];
    printf "%5d\t%-15s\t%-s\n",$it,$finId[$it],$fin[$it];
}
close($fhout);

print "--- finished out=$fileOut\n";
exit;

