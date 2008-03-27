#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="concetenates list of fast to fastMul (and changes id from 1pdb -> 1pdb_A)";
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
    print  "use:  '$scrName *.f '\n";
    print  "opt:  \n";
				#      'keyword'   'value'    'description'
    printf "      %-15s= %-20s %-s\n","fileOut",  "x",       "";
    printf "      %-15s  %-20s %-s\n","noScreen", "no value","";
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
$fhin="FHIN";$fhout="FHOUT";
$#fileIn=0;
				# ------------------------------
				# read command line
foreach $arg (@ARGV){
#    next if ($arg eq $ARGV[1]);
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


$fileOutTmp="TMP".$$.".tmp";
$#wrtMul=0;
				# ------------------------------
$ct=0;				# (1) read file(s)
foreach $fileIn(@fileIn){
    ++$ct;
    if (! -e $fileIn){print "-*- WARN $scrName: no fileIn=$fileIn\n";
		      next;}
    printf "--- $scrName: working on %-25s %4d (%4.1f perc of job)\n",$fileIn,$ct,(100*$ct/$#fileIn);

    $id=$fileIn; $id=~s/^.*\/|\..*$//g;

				# read FASTA
    &open_file("$fhin", "$fileIn") || die '*** $scrName ERROR opening file $fileIn';
    $#tmp=0;
    while (<$fhin>) {
	$_=~s/\n//g;
	next if (length($_) < 1);
	next if ($_=~/^\s*>/);	# ignore id
	push(@tmp,$_);		# get seq
    }
    close($fhin);
				# new FASTA
    $tmpWrt=">$id\n";
    foreach $seq (@tmp) { $seq=~s/^\s*|\s*$//g;
			  $tmpWrt.=$seq."\n";}
				# write FASTA
    &open_file("$fhout",">$fileOutTmp"); 
    print $fhout $tmpWrt;
    close($fhout);
				# move new to old
    ($Lok,$msg)=
	&sysMvfile($fileOutTmp,$fileIn);
    if (! $Lok) { print "*** ERROR $scrName: failed moving $fileOutTmp $fileIn\n";
		  print $msg,"\n";}

    
    push(@wrtMul,$tmpWrt);
}
				# ------------------------------
				# (3) write output
				# ------------------------------
&open_file("$fhout",">$fileOut"); 
foreach $tmp (@wrtMul) {
    print $fhout $tmp ; }
close($fhout);

print "--- output in $fileOut\n" if (-e $fileOut);
exit;
