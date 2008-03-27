#!/usr/pub/bin/perl -w
$[ =1 ;

# extracts subroutine names and descriptions from a perl program
# input: program

push (@INC, "/home/rost/perl") ;
@lib=("lib-ut.pl","lib-prot.pl","lib-comp.pl");
require "ctime.pl";		# require "rs_ut.pl" ;
foreach $lib(@lib){require "$lib";}

if (($#ARGV<1)||(&isHelp($ARGV[1]))){
    print"usage: 'script program'\n";exit;}

$file_in=$ARGV[1];$fhin="FHIN";$fileOut="Out-".$file_in.".tmp";
$fhout="STDOUT";
				# first sweep: read internal
&open_file("$fhin", "$file_in");
print $fhout "\# subroutines   (internal):\n\# \n";
$name=$des="xxxxx";
%Lok=0;$#sys=0;
while (<$fhin>) {
    if (/^\s*sub/){
	$_=~s/\n//g;$_=~s/\{.*$//g;$_=~s/^\s*sub\s+(.+)\s+.*$/$1/g;$name=$_;}
    elsif (/\# .*$name/ && (! /end of $name/) ){
	$_=~s/\n//g;$_=~s/^.*$name\s+//g;$des=$_;
	printf $fhout "#     %-25s %-s\n",$name,$des;
	$Lok{$name}=1;$name=$des="xxxxx";}
    elsif ( /end of $name/ ){
	$_=~s/\n//g;$_=~s/^.*$name\s+//g;$des=$_;
	printf $fhout "#     %-25s\n",$name;
	$Lok{$name}=1;$name=$des="xxxxx";}
    elsif ( /system\(.+\)/){	# grep system calls
	$_=~s/\n//g;$_=~s/^.*system//g;$_=~s/[\(\)\"\}\;]//g;
	if ($_=~/[\\ ](mv|cp|rm|gzip|gunzip|cat|echo)/){
	    next;}
	push(@sys,$_);}}close($fhin);
				# read all libraries
%lib=0;
foreach $lib (@lib){$tmp="/home/rost/perl/".$lib;$#tmp=0;
		    &open_file("$fhin", "$tmp");
		    while (<$fhin>) {
			if ($_ !~ /^\s*sub /){
			    next;}
			$_=~s/^\s*sub\s+(.+)\s+.*$/$1/g;$_=~s/\;.*$|\{.*$//g;$_=~s/\s//g;
			$name=$_;
			push(@tmp,$name);
			$lib{$name}="$lib";}close($fhin);}
				# second sweep: list external
&open_file("$fhin", "$file_in");
print $fhout "\# \n\# subroutines   (external):\n\# \n";
$name=$des="xxxxx";foreach $lib (@lib){$ext{$lib}="";} $ext{unk}=""; # ini
while (<$fhin>) {
    if ($_ !~ /\&\w+/){
	next;}
    $_=~s/\s//g;
    $_=~s/^.*\&([^\(\;]+)\(.*$/$1/;$_=~s/^.+\&//g;$_=~s/^.*\&//g;$_=~s/\;.*$//g;
    if (length($_)<3){
	next;}
    $name=$_;
    if (! defined $Lok{$name}){
	$Lok{$name}=1;
	if (defined $lib{$name}){$lib=$lib{$name};$ext{$lib}.="$name".",";}
	else{$ext{unk}.="$name".",";}}}close($fhin);
				# unrecognised libraries
foreach $lib (@lib,"unk"){
    $ext{$lib}=~s/^,|,$//g;
    @ext=split(/,/,$ext{$lib});
    @ext=sort (@ext);
    if ($#ext<1){
	next;}
    printf $fhout "#     %-15s ",$lib;
    foreach $ext (@ext){print $fhout "$ext,";}
    print $fhout "\n";
}
				# print all system calls
if ($#sys>0){
    print $fhout "\# \n\# system calls:\n\# \n";
    foreach $sys(@sys){
	printf $fhout "#     %-s\n",$sys;}}

if ($fhout ne "STDOUT"){close($fhout);
			print "--- output in file=$fileOut\n";}
exit;
