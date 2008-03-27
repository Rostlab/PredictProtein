#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="sometimes the file from fastaMerge.pl seems to have : \n".
    "     \t \n".
    "     \t >id\n".
    "     \t A\n".
    "     \t F\n".
    "     \t F\n".
    "     \t H\n".
    "     \t \n".
    "     \t i.e. one residue per line\n".
    "     \t THIS is corrected here!";
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
    print  "goal: $scrGoal\n";
    print  "use:  '$scrName '\n";
    print  "opt:  \n";
				#      'keyword'   'value'    'description'
    printf "%5s %-15s= %-20s %-s\n","","fileOut",  "x",       "";
    printf "%5s %-15s  %-20s %-s\n","","noScreen", "no value","";
#    printf "%5s %-15s  %-20s %-s\n","","",   "x", "";
#    printf "%5s %-15s  %-20s %-s\n","","",   "no value","";
    if (defined %par && $#kwd > 0){
	$tmp= sprintf("%5s %-15s  %-20s %-s\n","","-" x 15 ,"-" x 20,"-" x 30);
	$tmp.=sprintf("%5s %-15s  %-20s %-s\n","","other:","default settings: "," ");
	$tmp2="";
	foreach $kwd (@kwd){
	    next if (! defined $par{"$kwd"} || length($par{"$kwd"})<1 );
	    if    ($par{"$kwd"}=~/^\d+$/){
		$tmp2.=sprintf("      %-15s= %10d %9s %-s\n","",$kwd,$par{"$kwd"}," ","(def)");}
	    elsif ($par{"$kwd"}=~/^[0-9\.]+$/){
		$tmp2.=sprintf("%5s %-15s= %10.3f %9s %-s\n","",$kwd,$par{"$kwd"}," ","(def)");}
	    else {
		$tmp2.=sprintf("%5s %-15s= %-20s %-s\n","",$kwd,$par{"$kwd"},"(def)");} 
	} 
	print $tmp, $tmp2       if (length($tmp2)>1);
    }
    exit;}
				# initialise variables
$fhin="FHIN";$fhout="FHOUT";
$fileIn=$ARGV[1];
				# ------------------------------
				# read command line
foreach $arg (@ARGV){
    next if ($arg eq $ARGV[1]);
    if    ($arg=~/^fileOut=(.*)$/)        { $fileOut=$1;}
#    elsif ($arg=~/^=(.*)$/){ $=$1;}
    elsif (-e $arg)                       { push(@fileIn,$arg); }
    elsif (defined %par && $#kwd>0)       { 
	$Lok=0; 
	foreach $kwd (@kwd){ if ($arg =~ /^$kwd=(.+)$/){$Lok=1;$par{"$kwd"}=$1;
							last;}}
	if (! $Lok){ print "*** wrong command line arg '$arg'\n";
		     exit;}}
    else { print "*** wrong command line arg '$arg'\n"; 
	   exit;}}

die ("missing input $fileIn\n") if (! -e $fileIn);
if (! defined $fileOut){
    $tmp=$fileIn;$tmp=~s/^.*\///g;$fileOut="Out-".$tmp;}


&open_file("$fhin", "$fileIn") || die '*** $scrName ERROR opening file $fileIn';
&open_file("$fhout",">$fileOut"); 

$seq=0; $tmpseq=""; 
while (<$fhin>) {
    $_=~s/\n//g;
    if ($_=~/^\s*>/) {
				# print previous
	print $fhout "$seq\n" if ($seq && length($seq) > 0);
	    
	print $fhout "$_\n";
	$seq="";

	$tmpseq=~s/\s//g;
#	printf "xx: %-10s len=%5d\n",$_,length($tmpseq) if (length($tmpseq) > 500);

	$tmpseq="";
	next; }
    if (length($seq) > 50){
	print $fhout "$seq\n";
	$seq="";}

    $tmp=$_; 

    $tmpseq.=$tmp;		# xx

    if (length($tmp)==1) {
	$seq.=$tmp; }
    else {
	print $fhout "$tmp\n";}}
close($fhin);
print $fhout "$seq\n"           if ($seq && length($seq) > 0);
close($fhout);


print "--- output in $fileOut\n" if (-e $fileOut);
exit;
