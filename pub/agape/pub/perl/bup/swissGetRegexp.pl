#!/usr/sbin/perl -w
#
# goal:   greps keywords from SWISS-PROT files
# usage:  'script file regexp'
#
$[ =1 ;
				# include libraries
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
# require "ctime.pl"; 
require "lib-ut.pl"; require "lib-br.pl";
# require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
				# initialise variables

if ($#ARGV<2){print "goal:   greps keywords from SWISS-PROT files\n";
	      print "usage:  'script regexp \@files (or id's)'\n";
	      print "        regular expression can be perl type\n";
	      print "output: array with matching lines (0 if none)\n";
	      print "option:\n";
	      print "        dir=x (directory of swissprot)\n";
	      print "        fileOut=x\n";
	      print "        verbose \n";
	      exit;}

$fhout="FHOUT_swissGetRegexp";
$Lscreen=1;			# write output onto screen?
				# command line
$regexp=$ARGV[1];		# input expression

$#tmp=0;
foreach $it (2..$#ARGV){
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
    else {			# search for existing
	$out=&swissGetFile($input,$Lscreen,$par{"dir"}); # external lib-ut.pl
	if (! $out){
	    next;}
	push(@file,$out);}}
				# ------------------------------
				# re-adjust defaults
if (! defined $par{"fileOut"}){
    $par{"fileOut"}="Out-"."swissGetRegexp".".tmp";}
$fileOut=$par{"fileOut"};

if ($Lscreen){print 
		  "--- end of ini settings:\n",
		  "--- regexp = \t '$regexp'\n","--- file out: \t '$fileOut'\n",
		  "--- dirSwiss: \t '",$par{"dir"},"'\n","--- swiss files: \n";
	      foreach $file (@file){print"--- \t $file\n";}}

				# ------------------------------
				# now do for list
$#fin=$#finId=0;
foreach $file (@file){
    @linesRd=&swissGetRegexp($file,$regexp);
    if ($Lscreen){		# print STDOUT
	print "--- '$regexp' in $file:\n";foreach $tmp(@linesRd){print "--- \t $tmp\n";}}
    push(@fin,@linesRd);	# 
    $id=$file;$id=~s/^.*\///g;$id=~s/\n|\s//g;
    foreach $it (1..$#linesRd){
	push(@finId,$id);}
}
				# ------------------------------
				# output file (RDB)
&open_file("$fhout", ">$fileOut");
print $fhout "\# Perl-RDB\n";
printf $fhout "%5s\t%-15s\t%-s\n","lineNo","id","match $regexp";
printf $fhout "%5s\t%-15s\t%-s\n","5N","15","";
foreach $it (1..$#fin){
    printf $fhout "%5d\t%-15s\t%-s\n",$it,$finId[$it],$fin[$it];
    printf "%5d\t%-15s\t%-s\n",$it,$finId[$it],$fin[$it];
}
close($fhout);
exit;

