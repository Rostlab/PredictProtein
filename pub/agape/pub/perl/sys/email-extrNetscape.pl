#!/usr/bin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="reads the netscape address book and extracts email addresses";
#  
#
$[ =1 ;
				# include libraries
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
# require "ctime.pl"; 
require "lib-ut.pl"; require "lib-br.pl";
# require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
				# help
if ($#ARGV<1){
    print "goal:\t $scrGoal\n";
    print "use: \t '$scrName all' (or names as list name1,name2, )\n";
    print "opt: \t \n";
    print "     \t fileOut=x\n";
#    print "     \t \n";
    exit;}
				# initialise variables
$fhin="FHIN";$fhout="FHOUT";
				# read command line
$name=$ARGV[1];
$#name=0;
if ($name ne "all"){
    $name=~s/^,|,$//g;
    @name=split(/,/,$name);
    foreach $name(@name){$name{$name}=1;}}

$fileIn="/home/rost/.netscape/address-book.html";

$tmp=$fileIn;$tmp=~s/^.*\///g;$fileOut="Out-".$tmp; $fileOut=~s/\.html//g;

foreach $_(@ARGV){
    next if ($_ eq $ARGV[1]);
    if   ($_=~/^fileOut=(.*)$/){$fileOut=$1;}
#    elsif($_=~/^name=(.*)$/)   {$name=$1;}
    else {print"*** wrong command line arg '$_'\n";
	  die;}}

				# ------------------------------
$#email=$#nick=0;		# (1) read file
&open_file("$fhin", "$fileIn");
while (<$fhin>) {$_=~s/\n//g;
		 next if ($_!~/mailto:([^\"]+)\".*NICKNAME=\"([^\"]+)\".*$/);
		 next if (($#name>0)&&(! defined $name{$2}));
		 push(@email,$1);push(@nick,$2);
		 printf "xx email=%-40s nick=%-20s\n",$1,$2;
	     }close($fhin);
				# ------------------------------
				# (2) 
&open_file("$fhout",">$fileOut"); 
foreach $it(1..$#email){
    print $fhout "$email[$it]\n";
#    print $fhout "$email[$it]\t$nick[$it]\n";
}
close($fhout);

print "--- output in $fileOut\n";
exit;
