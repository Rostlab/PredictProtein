#!/usr/bin/perl -w
##!/usr/bin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="finds particular sbr in all libs (lib-br, lib-ut)";
#  
#
$[ =1 ;
				# ------------------------------
				# defaults
%par=(
      '', "",			# 
      '', "",			# 
      );
$lib=$dir."lib-ut.pl".",".$dir."lib-br.pl";
$Lnodes=0;

@kwd=sort (keys %par);
				# ------------------------------
if ($#ARGV<1){			# help
    print  "goal:\t $scrGoal\n";
    print  "use: \t '$scrName regexp' \n";
    print  "     \t                  *         for wild cards!\n";
    print  "     \t                  regexp    will match '^regexp'\n";
    print  "     \t                  '*regexp' will match 'regexp$'\n";
    print  "opt: \t \n";
    print  "     \t fileOut=x\n";
				#      'keyword'   'value'    'description'
    printf "     \t %-15s= %-20s %-s\n","fileOut",  "x",       "";
    printf "     \t %-15s  %-20s %-s\n","libadd",   "x",       "additional lib|scr to scan: 'scr1,scr2'";
    printf "     \t %-15s  %-20s %-s\n","lib",      "$lib",    "lib|scr to scan";
    printf "     \t %-15s  %-20s %-s\n","nodes|no", "no value","dont write description, just name";

#    printf "     \t %-15s  %-20s %-s\n","",      "x",       "";
#    printf "     \t %-15s  %-20s %-s\n","",   "no value","";
    if (defined %par){
	printf "     \t %-15s  %-20s %-s\n","-" x 15 ,"-" x 20,"-" x 30;
	printf "     \t %-15s  %-20s %-s\n","other:","default settings: "," ";
	foreach $kwd (@kwd){
	    if    ($par{"$kwd"}=~/^\d+$/){
		printf "     \t %-15s= %10d %9s %-s\n",$kwd,$par{"$kwd"}," ","(def)";}
	    elsif ($par{"$kwd"}=~/^[0-9\.]+$/){
		printf "     \t %-15s= %10.3f %9s %-s\n",$kwd,$par{"$kwd"}," ","(def)";}
	    else {
		printf "     \t %-15s= %-20s %-s\n",$kwd,$par{"$kwd"},"(def)";} } }
    exit;}
				# initialise variables
$fhin="FHIN";$fhout="FHOUT";
				# ------------------------------
				# read command line
$regexp=$ARGV[1];
foreach $arg (@ARGV){
    next if ($arg eq $ARGV[1]);
    if    ($arg=~/^fileOut=(.*)$/)        { $fileOut=$1;}
    elsif ($arg=~/^lib=(.*)$/)            { $lib=$1;}
    elsif ($arg=~/^libadd=(.*)$/)         { $libadd=$1;}
    elsif ($arg=~/^nodes$/)               { $Lnodes=1;}
    elsif ($arg=~/^no$/)                  { $Lnodes=1;}
#    elsif ($arg=~/^=(.*)$/){ $=$1;}
    elsif (defined %par && $#kwd>0)       { 
	$Lok=0; 
	foreach $kwd (@kwd){
	    if ($arg =~ /^$kwd=(.+)$/){$Lok=1;$par{"$kwd"}=$1;
				       last;}}
	if (! $Lok){ print "*** wrong command line arg '$arg'\n";
		     die;}}
    else { print "*** wrong command line arg '$arg'\n"; 
	   die;}}

$lib.=","."$libadd"             if (defined $libadd);
$lib=~s/,,/,/g;
$lib=~s/^,*|,*$//g;

$fileOut="Out-getInfoLib.tmp"   if (! defined $fileOut);
    

@lib=split(/,/,$lib);
$#tmp=0;
				# ------------------------------
				# process input argument (regexp)
$LbegWild=$LendWild=0;
if ($regexp=~/^\*/){
    $LbegWild=1; $regexp=~s/^\*//g; }        
if ($regexp=~/\*$/){
    $LendWild=1; $regexp=~s/\*$//g; }        
if (! $LbegWild && ! $LendWild){ # default 'regexp*' 
    $LendWild=1; }
if ($regexp=~/\*/){
    $regexp=~s/\*/.*/g;}

				# ------------------------------
				# (1) read file(s)
foreach $fileIn (@lib){
    if (! -e $fileIn){print "-*- WARN $scrName: no fileIn=$fileIn\n";
		      next;}
    $tmp="--- "; $tmp.="-" x 80; $tmp.="\n"."--- $fileIn\n";
    push(@tmp,$tmp);
    print "--- $scrName: working on '$fileIn'\n";
				# open
    open("$fhin", "$fileIn") || die '*** $scrName ERROR opening file $fileIn';

    $Ltake=0;			# read
    while (<$fhin>) {
	$_=~s/\n//g; $line=$_;
				# name
	next if (! $Ltake && $_ !~ /^sub /);
	if    (($LendWild && ($_ =~ /^sub\s+($regexp.?[\S]*)\s*\{\s*/i)) ||
	       ($LbegWild && ($_ =~ /^sub\s+([\S]*$regexp)\s*\{\s*/i))   ||
	       ($LbegWild && $LendWild && ($_ =~ /^sub\s+([\S]*$regexp.?[\S]*)\s*\{\s*/i))){
	    $Ltake=1;
	    next; }
				# description
	elsif ($Ltake){
	    next if ($line=~/^[\s\t]+(local|\$\[)/); # skip ' local |  $['
	    if ($line!~/^\#/) {                      # end if not comment
		$Ltake=0; 
		next; }
	    if ($Lnodes && $line=~/^\#[\s\t]+(GLOBAL|in|out|err)/){
		$Ltake=0; 
		next; }
	    next if ($line=~/\#\s*\-+/);             # skip '#----'
	    print $line,"\n"; push(@tmp,$line); }
    }
    close($fhin);
}
				# ------------------------------
				# (2) write output
				# ------------------------------
open("$fhout",">$fileOut") || die "*** failed opening output file=$fileOut";
foreach $tmp (@tmp){
    print $fhout $tmp,"\n"; }
close($fhout);

print "--- output in $fileOut\n";
exit;
