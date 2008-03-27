#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="\n".
    "     \t ";
#  
#
$[ =1 ;
				# ------------------------------
foreach $arg(@ARGV){		# include libraries
    last if ($arg=~/dirLib=(.*)$/);}
$dir=$1 || "/home/rost/perl/" || $ENV{'PERLLIB'}; 
$dir.="/" if (-d $dir && $dir !~/\/$/);
$dir= ""  if (! defined $dir || ! -d $dir);
foreach $lib("lib-ut.pl","lib-br.pl"){
    require $dir.$lib ||
	die("*** $scrName: failed to require perl library '$lib' (dir=$dir)\n");}
				# ------------------------------
				# defaults
%par=(
      '', "",			# 
      );
@kwd=sort (keys %par);
				# ------------------------------
if ($#ARGV<1){			# help
    print  "goal:\t $scrGoal\n";
    print  "use: \t '$scrName '\n";
    print  "opt: \t \n";
    print  "     \t fileOut=x\n";
				#      'keyword'   'value'    'description'
    printf "     \t %-15s= %-20s %-s\n","fileOut",  "x",       "";
    printf "     \t %-15s  %-20s %-s\n","noScreen", "no value","";
#    printf "     \t %-15s  %-20s %-s\n","",   "","";
#    printf "     \t %-15s  %-20s %-s\n","",   "no value","";
    if (defined %par){
	printf "     \t %-15s  %-20s %-s\n","-" x 15 ,"-" x 20,"-" x 30;
	printf "     \t %-15s  %-20s %-s\n","other:","default settings: "," ";
	foreach $kwd (@kwd){
	    if    ($par{"$kwd"}!~/\D/){
		printf "     \t %-15s= %10d %9s %-s\n",$kwd,$par{"$kwd"}," ","(def)";}
	    elsif ($par{"$kwd"}!~/[0-9\.]/){
		printf "     \t %-15s= %10.3f %9s %-s\n",$kwd,$par{"$kwd"}," ","(def)";}
	    else {
		printf "     \t %-15s= %-20s %-s\n",$kwd,$par{"$kwd"},"(def)";} } }
    exit;}
				# initialise variables
$fhin="FHIN";$fhout="FHOUT";
				# ------------------------------
$#fileIn=$#chainIn=0;		# read command line
foreach $arg (@ARGV){
    if    ($arg=~/^fileOut=(.*)$/)        { $fileOut=$1;}
#    elsif ($arg=~/^=(.*)$/){ $=$1;}
    elsif (-e $arg)                       { push(@fileIn,$arg); push(@chainIn,"*");}
    elsif ($arg=~/^(\.hssp)\_([A-Z0-9])/) { push(@fileIn,$1);   push(@chainIn,$2);}
    elsif (defined %par && $#kwd>0)       { 
	$Lok=0; 
	foreach $kwd (@kwd){
	    if ($arg =~ /^$kwd=(.+)$/){$Lok=1;$par{"$kwd"}=$1;
				       last;}}
	if (! $Lok){ print "*** wrong command line arg '$arg'\n";
		     die;}}
    else { print "*** wrong command line arg '$arg'\n"; 
	   die;}}

$fileIn=$fileIn[1];
die ("missing input $fileIn\n") if (! -e $fileIn);
if (! defined $fileOut){
    $tmp=$fileIn;$tmp=~s/^.*\///g;$fileOut="Out-".$tmp;}
				# ------------------------------
				# (1) read file(s)
foreach $fileIn(@fileIn){
    if (! -e $fileIn){print "-*- WARN $scrName: no fileIn=$fileIn\n";
		      next;}
    print "--- $scrName: working on '$fileIn'\n";
    &open_file("$fhin", "$fileIn") || die '*** $scrName ERROR opening file $fileIn';
#    if (! $Lok){print "*** $scrName: failed to open fileIn=$fileIn\n";
#		next;}
    while (<$fhin>) {
	$_=~s/\n//g;
	$_=~s/^.*\///g;
    }
    close($fhin);
}
				# ------------------------------
				# (2) 
				# ------------------------------
				# (2) 

				# ------------------------------
				# write output
&open_file("$fhout",">$fileOut"); 
close($fhout);

print "--- output in $fileOut\n";
exit;
