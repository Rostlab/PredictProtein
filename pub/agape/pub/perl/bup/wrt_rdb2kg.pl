#!/usr/sbin/perl -w

#
# reads file and converts all tabs to commata, and deletes RDB
#       header and format line
#
# 
#
$[ =1 ;

push (@INC, "/home/rost/perl") ;
# require "ctime.pl";		# require "rs_ut.pl" ;	require "lib-ut.pl"; require "lib-br.pl";
# require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";	
require "lib-ut.pl"; require "lib-br.pl";

if (($#ARGV<1)||($ARGV[1]=~/help|man|-h/)){
    print "--- converts tabs to commata and deletes header and format lines\n";
    print "--- input:   file (or list of file)\n";
    print "--- output:  files(s) with .kg \n";
#    print "--- options:\n";
#    print "---          excl=  exclude columns: ('n1-n2' 'n1,n2' 'n1-*' 'name1,name2' \n";
#    print "---          incl=  exclude columns: ('n1-n2' 'n1,n2' 'n1-*' 'name1,name2' \n";
}

				# defaults
$#excl=$#incl=0;
foreach $_(@ARGV){
    if (/^excl=/){@excl=&get_arg_range($_);}
    if (/^incl=/){@incl=&get_arg_range($_);}
}

if (($#incl+$#excl)>0){print "options excl, incl not working yet\n";exit;}

$fhin="FHIN";$fhout="FHOUT";
foreach $arg (@ARGV){
    if ($arg =~ /^excl=|^incl=/){
	next;}
    $file_in=$arg;
    $file_out=$file_in;$file_out=~s/^.*\///g;$file_out=~s/\.[^.]*$/\.kg/g;

    &open_file("$fhin", "$file_in");
    &open_file("$fhout", ">$file_out");
    $ct=0;
    while (<$fhin>) {
	$Lok=0;
	if (/^\#/){next;}
	++$ct;
	if ($ct==2){
	    if (! /\d+N\t|\d+\.\d+F\t|\d+\t/){$Lok=1;}} # exclude format line
	else {$Lok=1;}
	if ($Lok){
	    $_=~s/\t/,/g;~s/\n//g;
	    $_=~s/^\s*|\s*$//g;~s/\s*,/,/g;~s/,\s*/,/g;
	    print $fhout "$_\n";}}close($fhin);close($fhout);
    print "--- output in $file_out\n";
}
exit;

#==========================================================================================
sub get_arg_range {
    local ($arg) = @_ ;
    $[ =1 ;
#--------------------------------------------------------------------------------
#    get_arg_range              extracts two values or an array separated by tabs
#       in:                     excl=1-5 or so
#--------------------------------------------------------------------------------
    $arg=~s/^excl=|^incl=//g;$#res=$#tmp=0;
    if   ($arg=~/,/){@tmp=split(/,/,$arg);}
    else            {@tmp=($arg);}
    foreach $x (@tmp) {
	if ($x=~/[0-9*]-[0-9*]/){
	    ($beg,$end)=split(/-/,$x);
	    if ( ($beg eq "*") || ($end eq "*") ) {push(@res,$beg,$end);}
	    else {foreach $it($beg..$end){push(@res,$it);}}}
	elsif ($x !~/-/){
	    push(@res,$x);}}
    return(@res);
}				# end of get_arg_range

