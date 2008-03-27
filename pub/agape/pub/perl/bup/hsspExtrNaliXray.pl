#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="greps 'NALIGN|SEQLENGTH' from HSSP file, and resolution from resp. PDB\n";
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
      'dirPdb', "/home/rost/data/pdb/",		# directory of PDB
      'extPdb', ".brk",		# extension of PDB
      '', "", 
      '', "", 
      );
$sep=" ";
$resMax=1107;
				# ------------------------------
if ($#ARGV<1){			# help
    print "goal:\t $scrGoal\n";
    print "use: \t '$scrName list.hssp (or *.hssp)'\n";
    print "opt: \t \n";
    print "     \t nali=(ge|gt|le|lt)x : only those with nali    >=,>,<=,< x\n";
    print "     \t len=(ge|gt|le|lt)x  : only those with length  >=,>,<=,< x\n";
    print "     \t res=(ge|gt|le|lt)x  : only those with respective X-ray resolution\n";
    print "     \t fileOut=x\n";
    print "     \t noali               -> don NOT look up NALIGN\n";
    print "     \t nolen               -> don NOT look up SEQLENGTH\n";
    print "     \t nores               -> don NOT look up PDB resolution\n";
#    print "     \t \n";
    if (defined %par){
	foreach $kwd (@kwd){
	    printf "     \t %-20s=%-s (def)\n",$par{"$kwd"};}}
    exit;}
				# initialise variables
$fhin="FHIN";$fhout="FHOUT";
$Lnoali=$Lnolen=$Lnores=0;
				# ------------------------------
$#fileIn=0;			# read command line
foreach $arg (@ARGV){
    if    ($arg=~/^fileOut=(.*)$/)            { $fileOut=$1;}
    elsif ($arg=~/^nali=([glet]+)(\d+)$/)     { $naliExcl=$2; $modeNali=$1;}
    elsif ($arg=~/^len=([glet]+)(\d+)$/)      { $lenExcl=$2;  $modeLen= $1;}
    elsif ($arg=~/^res=([glet]+)([\d\.]+)$/)  { $resExcl=$2;  $modeRes= $1;}
    elsif ($arg=~/^noali$/)                   { $Lnoali=1;}
    elsif ($arg=~/^nolen$/)                   { $Lnolen=1;}
    elsif ($arg=~/^nores$/)                   { $Lnores=1;}
#    elsif ($arg=~/^=(.*)$/) { $=$1;}
    else  {$Lok=0;
	   if (-e $arg){$Lok=1;
			push(@fileIn,$arg);}
	   if (! $Lok && defined %par){
	       foreach $kwd (keys %par){
		   if ($arg =~ /^$kwd=(.+)$/){$Lok=1;$par{"$kwd"}=$1;
					      last;}}}
	   if (! $Lok){print"*** wrong command line arg '$arg'\n";
		       die;}}}
$fileIn=$fileIn[1];
$par{"dirPdb"}.="/"               if ($par{"dirPdb"}!~/\/$/);
$par{"extPdb"}=".".$par{"extPdb"} if ($par{"extPdb"}!~/^\./);

die ("missing input $fileIn\n") if (! -e $fileIn);
				# ------------------------------
				# output file name
if (! defined $fileOut){
    $tmp=$fileIn;$tmp=~s/^.*\///g;
    $tmp2="";
    if (defined $naliExcl){$tmp2.="nali-";
			   $tmp2="gt".$naliExcl."-"  if ($modeNali eq "gt");
			   $tmp2="ge".$naliExcl."-"  if ($modeNali eq "ge");
			   $tmp2="lt".$naliExcl."-"  if ($modeNali eq "lt");
			   $tmp2="le".$naliExcl."-"  if ($modeNali eq "le"); }
    if (defined $lenExcl) {$tmp2.="len-";
			   $tmp2="gt".$lenExcl."-"  if ($modeLen eq "gt");
			   $tmp2="ge".$lenExcl."-"  if ($modeLen eq "ge");
			   $tmp2="lt".$lenExcl."-"  if ($modeLen eq "lt");
			   $tmp2="le".$lenExcl."-"  if ($modeLen eq "le"); }
    if (defined $resExcl) {$tmp2.="res-";
			   $tmp2="gt".$resExcl."-"  if ($modeRes eq "gt");
			   $tmp2="ge".$resExcl."-"  if ($modeRes eq "ge");
			   $tmp2="lt".$resExcl."-"  if ($modeRes eq "lt");
			   $tmp2="le".$resExcl."-"  if ($modeRes eq "le"); }
    $fileOut="Out-".$tmp2.$tmp;}

				# ------------------------------
				# read list (if list)
if (! &is_hssp($fileIn)){
    print "--- $scrName: read list '$fileIn'\n";
    $#fileIn=0;
    &open_file("$fhin", "$fileIn") || die '*** $scrName ERROR opening file $fileIn';
    while (<$fhin>) {$_=~s/\n|\s//g;
		     next if (length($_)<5);
		     if ($_=~/\.hssp_[A-Z0-9]/){ # purge change 
			 $_=~s/(\.hssp)_[A-Z0-9]/$1/;}
		     push(@fileIn,$_); } close($fhin);}

				# --------------------------------------------------
				# (1) read file(s)
				# --------------------------------------------------
foreach $fileIn(@fileIn){
    if (! -e $fileIn){print "-*- WARN $scrName: no fileIn=$fileIn\n";
		      next;}
    $Lok=1;
				# ------------------------------
    if (! $Lnoali){             # grep NALIGN
	($Lok,$msg,$nali)=
	    &hsspGrepNali($fileIn,$naliExcl,$modeNali);
	return(&errSbrMsg("failed on grepping NALI from $fileIn",$msg)) if (! $Lok);
	$Lok=0                  if (! $nali); }
    next if (! $Lok);
				# ------------------------------
    if (! $Lnolen){             # grep SEQLENGTH
	($Lok,$msg,$len)=
	    &hsspGrepLen($fileIn,$lenExcl,$modeLen);
	return(&errSbrMsg("failed on grepping LEN from $fileIn",$msg)) if (! $Lok);
	$Lok=0                  if (! $len); }
    next if (! $Lok);
				# ------------------------------
    if (! $Lnores){             # grep PDB resolution
	$id=$fileIn;$id=~s/^.*\///g;$id=~s/\.hssp.*$//g;
	$filePdb=$par{"dirPdb"}.$id.$par{"extPdb"};
	if (! -e $filePdb) { print "*** file=$fileIn, pdb=$filePdb, (id=$id) missing\n";
			     exit;}
	($Lok,$msg,$res)=
	    &pdbGrepResolution($filePdb,$lenExcl,$modeLen,$resMax);
	return(&errSbrMsg("failed on grepping PDB resolution from $filePdb",$msg)) if (! $Lok);
	$Lok=0                  if (! $res); }
    next if (! $Lok);


    print "--- ok $fileIn ";
    if (! $Lnoali && defined $nali && $nali) { 
	$ok{"nali",$fileIn}=$nali;
	$tmp= " nali=$nali ";
	$tmp.=" ($modeNali $naliExcl), " if (defined $naliExcl);
	print "$tmp";}
    if (! $Lnolen && defined $len && $len) { 
	$ok{"len",$fileIn}=$len;
	$tmp= " nlen=$len ";
	$tmp.=" ($modeLen $lenExcl), "   if (defined $lenExcl);
	print "$tmp";}
    if (! $Lnores && defined $res && $res) { 
	$ok{"res",$fileIn}=$res;
	$tmp= " res=$res ";
	$tmp.=" ($modeRes $resExcl), "   if (defined $resExcl);
	print "$tmp";}
    print "\n";
}
				# ------------------------------
				# (2) write output
&open_file("$fhout",">$fileOut"); 
foreach $fileIn(@fileIn){
    next if (! defined $ok{"nali","$fileIn"} &&
	     ! defined $ok{"len","$fileIn"} &&
	     ! defined $ok{"res","$fileIn"});
    $tmp= sprintf("%-40s",$fileIn);
    $tmp.=sprintf("$sep%5d",$ok{"nali","$fileIn"})   if (! $Lnoali);
    $tmp.=sprintf("$sep%5d",$ok{"len","$fileIn"})    if (! $Lnolen);
    $tmp.=sprintf("$sep%8.2f",$ok{"res","$fileIn"})  if (! $Lnores);
    $tmp.="\n";
    
    print $tmp;
    printf $fhout $tmp; 
    
}
close($fhout);

print "--- output in $fileOut\n";
exit;
