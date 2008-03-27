#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="compiles statistics for best HTM";
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
      'minVal', 0.8,		# minimal average NETout for HTM
      'minLen', 18,		# length of minimal HTM
      'doStat', 1,		# do statistics
      '', "",			# 
      );
@kwd=sort (keys %par);
$sep="\t";
				# ------------------------------
if ($#ARGV<1){			# help
    print  "goal: $scrGoal\n";
    print  "use:  '$scrName *.rdbHtm'\n";
    print  "opt:  \n";
				#      'keyword'   'value'    'description'
    printf "      %-15s= %-20s %-s\n","fileOut",  "x",       "";
    printf "      %-15s  %-20s %-s\n","len",      "x",       "length of best helix";
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
#$fhin="FHIN";
$fhout="FHOUT";
$#fileIn=0;
				# ------------------------------
				# read command line
foreach $arg (@ARGV){
#    next if ($arg eq $ARGV[1]);
    if    ($arg=~/^fileOut=(.*)$/)        { $fileOut=$1;}
    elsif ($arg=~/^len=(.*)$/)            { $par{"minLen"}=$1;}
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
    $tmp=$fileIn;$tmp=~s/^.*\/|\..*$//g;$fileOut="Out-".$par{"minLen"}."-".$tmp.".dat";}

&open_file("$fhout",">$fileOut"); 
printf $fhout 
    "%-s$sep%-6s$sep%-5s$sep%-5s$sep%-5s$sep%-6s$sep%-2s\n",
    "id","val","pos","len","nhtm","aveLenH","is";

				# ------------------------------
$ct=0;				# (1) read file(s)
foreach $fileIn (@fileIn){
    ++$ct;
    if (! -e $fileIn){print "-*- WARN $scrName: no fileIn=$fileIn\n";
		      next;}
    printf "--- $scrName: working on %-25s %4d (%4.1f perc of job)\n",$fileIn,$ct,(100*$ct/$#fileIn);
    $id=$fileIn;$id=~s/^.*\/|\..*$//g;

    ($Lok,$msg,$LisHtm,%tmp)=
	&phdHtmIsit($fileIn,$par{"minVal"},$par{"minLen"},$par{"doStat"});

    if (! $Lok) { print "*** ERROR $scrName: after phdHtmisit ($fileIn)\n",$msg,"\n";
		  exit;}

    printf $fhout 
	"%-s$sep%6.2f$sep%5d$sep%5d$sep%5d$sep%6.2f$sep%1d\n",
	$id,$tmp{"valBest"},$tmp{"posBest"},$tmp{"len"},
	$tmp{"nhtm"},$tmp{"aveLenHtm"},$LisHtm;

}

close($fhout);

print "--- output in $fileOut\n" if (-e $fileOut);
exit;
