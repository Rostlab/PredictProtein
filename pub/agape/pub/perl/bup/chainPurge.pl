#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="purges chain from file name (expected to be at end)";
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
    print  "use:  '$scrName (file*)'\n";
    print  "               keyword 'list' to digest lists (or extension .list) !!\n";
    print  "opt:  \n";
				#      'keyword'   'value'    'description'
    printf "      %-15s= %-20s %-s\n","fileOut",  "x",       "";
    printf "      %-15s  %-20s %-s\n","list",   "no value","";
#    printf "      %-15s  %-20s %-s\n","noScreen", "no value","";
#    printf "      %-15s  %-20s %-s\n","",   "","";
#    printf "      %-15s  %-20s %-s\n","",   "no value","";
    if (defined %par && $#kwd > 0){
	$tmp= sprintf("      %-15s  %-20s %-s\n","-" x 15 ,"-" x 20,"-" x 30);
	$tmp.=sprintf("      %-15s  %-20s %-s\n","other:","default settings: "," ");
	$tmp2="";
	foreach $kwd (@kwd){
	    next if (! defined $par{"$kwd"} || length($par{"$kwd"})<1 );
	    if    ($par{"$kwd"}=~/^\d+$/){
		$tmp2.=sprintf("      %-15s= %10d %9s %-s\n",$kwd,$par{"$kwd"}," ","(def)");}
	    elsif ($par{"$kwd"}=~/^[0-9\.]+$/){
		$tmp2.=sprintf("      %-15s= %10.3f %9s %-s\n",$kwd,$par{"$kwd"}," ","(def)");}
	    else {
		$tmp2.=sprintf("      %-15s= %-20s %-s\n",$kwd,$par{"$kwd"},"(def)");} 
	} 
	print $tmp, $tmp2       if (length($tmp2)>1);
    }
    exit;}
				# initialise variables
$fhout="FHOUT";
$fhin= "FHIN";

$#fileIn=$#chainIn=0;
$LisList=0;
				# ------------------------------
				# read command line
foreach $arg (@ARGV){
#    next if ($arg eq $ARGV[1]);
    if    ($arg=~/^fileOut=(.*)$/)        { $fileOut=$1;}
    elsif ($arg=~/^list$/)                { $LisList=1;}
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
				# (0) digest file (list?)
				# ------------------------------
$#fileTmp=0;
foreach $fileIn (@fileIn){
    if ($LisList || $fileIn=~/list$/){
	&open_file("$fhin", "$fileIn") || die '*** $scrName ERROR opening file $fileIn';
	while (<$fhin>) {$_=~s/\n//g;
			 push(@fileTmp,$_); }
	close($fhin); }
    else {
	push(@fileTmp,$fileIn);} }

@fileIn= @fileTmp; 
				# ------------------------------
				# (1) read file(s)
undef %tmp;
&open_file("$fhout",">$fileOut"); 
foreach $fileIn(@fileIn){
    $fileIn=~s/\_.$//g;
				# avoid duplications
    if (! defined $tmp{$fileIn}){
	$tmp{$fileIn}=1;
	print $fhout $fileIn,"\n"; }
}
close($fhout);

print "--- output in $fileOut\n" if (-e $fileOut);
exit;