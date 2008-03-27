#!/usr/sbin/perl -w
#
# extracts the keyword line for list of swiss-prot files
#
$[ =1 ;

				# include libraries
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
# require "ctime.pl"; 
require "lib-ut.pl"; require "lib-br.pl";
# require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
				# initialise variables

if ($#ARGV<1){print"goal:   extracts the keyword line for list of swiss-prot files \n";
	      print"usage:  script list_swiss (or file*)\n";
	      exit;}

$fileIn=$ARGV[1];
$fhin="FHIN";$fhout="FHOUT";
$fileOut="Out-keyword.tmp";

				# ------------------------------
				# extract command line
$#file=0;
if (&isSwissList($fileIn)){
    &open_file("$fhin", "$fileIn");
    while (<$fhin>) {$_=~s/\s//g;
		     if (-e $_){push(@file,$_);}}}
else {
    foreach $arg(@ARGV){
	if (-e $_){push(@file,$arg);}}}

				# ------------------------------
				# read swissprot files
foreach $file (@file){
    print "--- reading $file\n";
    &open_file("$fhin", "$file");$tmp="";$id=$file;$id=~s/^.*\///g;
    while (<$fhin>) {if ($_ =~ /^KW/){$_=~s/\n//g;$_=~s/^KW\s+//g;
				      $tmp.="$_ ";}}close($fhin);
    print "--- \t kw=$tmp\n";
    push(@kw,$tmp);push(@id,$id);}
				# ------------------------------
				# write id, keyword
&open_file("$fhout", ">$fileOut");
print $fhout "# Perl-RDB\n";
print $fhout "# extract from 'KW' line in SWISS-PROT\n";
print $fhout "swissId\tKW\n";
print $fhout "15S\tS\n";
foreach $it(1..$#kw){
    printf $fhout "%-15s\t%-s\n",$id[$it],$kw[$it];}
close($fhout);
print"--- output in '$fileOut'\n";
exit;
