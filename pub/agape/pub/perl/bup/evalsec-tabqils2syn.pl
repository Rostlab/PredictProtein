#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="mirrors summary from Tableqils files";
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
    print  "use: \t '$scrName Tableqils*'\n";
    print  "opt: \t \n";
    print  "     \t fileOut=x\n";
				#      'keyword'   'value'    'description'
    printf "     \t %-15s= %-20s %-s\n","fileOut",  "x",       "";
    printf "     \t %-15s  %-20s %-s\n","many",    "no value", "writes 'syn-' file for each input";
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
#$fhin="FHIN";
$fhout="FHOUT";
$#fileIn=$#chainIn=0;
				# ------------------------------
				# read command line
foreach $arg (@ARGV){
#    next if ($arg eq $ARGV[1]);
    if    ($arg=~/^fileOut=(.*)$/)        { $fileOut=$1;}
    elsif ($arg=~/^many$/)                { $Lmany=1;}
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
if    (! defined $fileOut && $#fileIn==1){
    $tmp=$fileIn;$tmp=~s/^.*\///g;$tmp=~s/Tableqils[\-\_]//g;$fileOut="syn-".$tmp;}
elsif (! defined $fileOut){
    $fileOut="Syn-many.tmp"; }
    
				# ------------------------------
				# (1) read file(s)
$#wrt=$#name=0;			# ------------------------------
foreach $fileIn(@fileIn){
    if (! -e $fileIn){print "-*- WARN $scrName: no fileIn=$fileIn\n";
		      next;}
    print "--- $scrName: working on '$fileIn'\n";

    ($Lok,$msg,$wrt)=
	&evalsecTableqils2syn($fileIn);

    if (! $Lok) { print "*** ERROR $scrName: failed reading table for $fileIn\n",$msg,"\n";
		  exit; }
    $tmp=$fileIn;$tmp=~s/^.*\///g;$tmp=~s/Tableqils[\-\_]//g;
    push(@wrt,$wrt); push(@name,$tmp);
				# ------------------------------
				# intermediate out
    if ($Lmany) {
	$fileOutLoc="syn-".$tmp;
	&open_file("$fhout",">$fileOutLoc"); 
	print $fhout $wrt;
	close($fhout); }
}
				# ------------------------------
$max=0;				# get longest name
if ($#fileIn>1){
    foreach $it (1..$#wrt){
	$max=length($name[$it]) if (length($name[$it]) > $max); }
    $form="%-".$max."s".":";  }
				# ------------------------------
				# (3) write output
				# ------------------------------
&open_file("$fhout",">$fileOut"); 
$#syn=0;
foreach $it (1..$#wrt){
    @wrtSin=split(/\n/,$wrt[$it]);
    $tmp=""; $tmp.=" " x $max ." "  if ($max>0);
    $tmp.="--- "."-" x 60 . "\n";   push(@syn,$tmp);
    foreach $wrtSin (@wrtSin){
	if ($#fileIn>1){
	    $wrt= sprintf ("$form%-s\n",$name[$it],$wrtSin); }
	else {
	    $wrt= sprintf ("%-s\n",$wrtSin); }
	print $fhout $wrt;
				# final synopsis
	push(@syn,$wrt)         if ($wrtSin =~/^\s*SYN/); }
}

foreach $syn (@syn){		# final synopsis
    print $fhout $syn; 
}
close($fhout);

foreach $syn (@syn){		# final synopsis : screen
    print $syn; 
}

print "--- output in $fileOut\n" if (-e $fileOut);
exit;

