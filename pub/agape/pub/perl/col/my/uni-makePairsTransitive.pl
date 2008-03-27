#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="read file pairs.rdb, makes it transitive: \n".
    "     \t d(1,2)=d(2,1)=: max ( d(1,2) , d(2,1) )\n".
    "     \t note: column number where to find id1, res, id2, dis in file pairs defined in \%ptr\n";
#  
#

$[ =1 ;
				# ------------------------------
				# defaults
%par=(
      'ptrId1',    1,		# column in file pairs.rdb where the id is expected
      'ptrLen',    2,		# column in file pairs.rdb where the length
      'ptrRes',    3,		# column in file pairs.rdb where the resolution is expected
      'ptrId2',    4,		# column in file pairs.rdb where the pair list is expected
      'ptrDis',    5,		# column in file pairs.rdb where the distance list is expected
      '', "",			# 
      );
@kwd=sort (keys %par);
				# ------------------------------
if ($#ARGV<1){			# help
    print  "goal: $scrGoal\n";
    print  "use:  '$scrName pairs.rdb'\n";
    print  "opt:  \n";
				#      'keyword'   'value'    'description'
    printf "%5s %-15s=%-20s %-s\n","","fileOut",  "x",       "";
#    printf "%5s %-15s %-20s %-s\n","","",   "x", "";
#    printf "%5s %-15s %-20s %-s\n","","",   "no value","";

    printf "%5s %-15s %-20s %-s\n","","list",     "no value","if input file is list of FASTA files".
	                                                     " note: automatic if extension *.list!!";

#    printf "%5s %-15s %-20s %-s\n","","noScreen", "no value","";
#    printf "%5s %-15s %-20s %-s\n","","",   "x", "";
#    printf "%5s %-15s %-20s %-s\n","","",   "no value","";
    if (defined %par && $#kwd > 0){
	$tmp= sprintf("%5s %-15s  %-20s %-s\n","","-" x 15 ,"-" x 20,"-" x 30);
	$tmp.=sprintf("%5s %-15s  %-20s %-s\n","","other:","default settings: "," ");
	$tmp2="";
	foreach $kwd (@kwd){
	    next if (! defined $par{"$kwd"} || length($par{"$kwd"})<1 );
	    if    ($par{"$kwd"}=~/^\d+$/){
		$tmp2.=sprintf("%5s %-15s= %10d %9s %-s\n","",$kwd,$par{"$kwd"}," ","(def)");}
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
$#fileIn=0;
$SEP="\t";
				# ------------------------------
				# read command line
foreach $arg (@ARGV){
#    next if ($arg eq $ARGV[1]);
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

$fileIn=$fileIn[1];
die ("missing input $fileIn\n") if (! -e $fileIn);
if (! defined $fileOut){
    $tmp=$fileIn;$tmp=~s/^.*\///g;$fileOut="Out-".$tmp;}


				# ------------------------------
				# (1) read file pairs
				# ------------------------------
print "--- $scrName: working on '$fileIn'\n";

open("$fhin","$fileIn") || die '*** $scrName ERROR opening file $fileIn';
$#idFound=0;
undef %dis; undef %rd;
$LdoDis=0;

$#hdr1=$#hdr2=0;

while (<$fhin>) {
    $_=~s/\n//g;
    if ($_=~/^\#/) { push(@hdr1,$_);
		     next; }
    if ($_=~/^id/) { push(@hdr2,$_);
		     next; }
    
    @tmp=split(/[\s\t]+/,$_);  foreach $tmp (@tmp){$tmp=~s/\s//g;}
    $id1=           $tmp[$par{"ptrId1"}];
    push(@idFound,$id1);
    $rd{$id1,"id2"}=     $tmp[$par{"ptrId2"}];
    $rd{$id1,"len"}=     $tmp[$par{"ptrLen"}];
    $rd{$id1,"res"}=     $tmp[$par{"ptrRes"}]   if (defined $tmp[$par{"ptrRes"}]);
    $rd{$id1,"dis"}=     $tmp[$par{"ptrDis"}]   if (defined $tmp[$par{"ptrDis"}]);

    
    $#id2=$#dis=0;
    @id2=split(/,/, $tmp[$par{"ptrId2"}]) if (defined $tmp[$par{"ptrId2"}]);
    @dis=split(/,/, $tmp[$par{"ptrDis"}]) if (defined $tmp[$par{"ptrDis"}]);
    $num{$id1}=     $#id2;

    $LdoDis=1                   if (@dis && ! $LdoDis);

    foreach $it (1..$#id2) {
	if (! @dis) {		# no distance defined -> 1
	    $dis{$id1,$id2[$it]}=1; }
	else {
	    $dis{$id1,$id2[$it]}=$dis[$it]; } }

} close($fhin);
				# --------------------------------------------------
				# (2) d(1,2)=d(2,1)=: max ( d(1,2) , d(2,1) )
				# --------------------------------------------------
%numNew=%num;

foreach $it1 ( 1 .. $#idFound) {
    next if ($num{$idFound[$it1]} < 1);
    $id1=$idFound[$it1];
    foreach $it2 (($it1+1) .. $#idFound) {
	$id2=$idFound[$it2];
	
				# none of the two
	next if (! defined $dis{$id1,$id2} && ! defined $dis{$id2,$id1});

				# D(1,2) yes, D(2,1) not
	if (defined $dis{$id1,$id2} && ! defined $dis{$id2,$id1}) {
	    ++$numNew{$id2};
	    $dis{$id2,$id1}=$dis{$id1,$id2};
	    next; }
				# D(1,2) not, D(2,1) yes
	if (! defined $dis{$id1,$id2} && defined $dis{$id2,$id1}) {
	    ++$numNew{$id1};
	    $dis{$id1,$id2}=$dis{$id2,$id1};
	    next; }

	next if ($dis{$id1,$id2} == $dis{$id2,$id1});

				# D(1,2) > D(2,1) 
	if ($dis{$id1,$id2} > $dis{$id2,$id1}) {
	    $dis{$id2,$id1}=$dis{$id1,$id2}; 
	    next; }
				# D(1,2) < D(2,1) 
	if ($dis{$id1,$id2} < $dis{$id2,$id1}) {
	    $dis{$id1,$id2}=$dis{$id2,$id1};
	    next; }
    }
}
				# ------------------------------
				# (3) write new output
				# ------------------------------
open("$fhout",">$fileOut") || warn '*** $scrName ERROR creating file $fileOut';
foreach $hdr (@hdr1) {
    print $fhout "$hdr\n"; }
print $fhout "# \n","# NOTE: changed such that D(1,2)=D(2,1)=: max ( D(1,2) , D(2,1) )\n","# \n";
foreach $hdr (@hdr2) {
    print $fhout "$hdr\n"; }

				# data
foreach $it1 ( 1 .. $#idFound) {
    $id1=$idFound[$it1];

				# corrections necessary: add transitive
    if ($num{$id1} != $numNew{$id1}) {
	undef %ok;		# old
	if (defined $rd{$id1,"id2"}) {
	    @id2=split(/,/,$rd{$id1,"id2"});
	    $ok{$id1}=1;
	    foreach $id2 (@id2) {
		$ok{$id2}=1; }}
	else {
	    $rd{$id1,"id2"}="";
	    $rd{$id1,"dis"}="";}

				# new
	$#id2Add=$#disAdd=0;
	foreach $it2 (($it1+1) .. $#idFound) {
	    $id2=$idFound[$it2];
	    next if (! defined $dis{$id1,$id2});
	    next if (defined $ok{$id2});
	    push(@id2Add,$id2);
	    push(@disAdd,$dis{$id1,$id2}); }

				# add new
	$rd{$id1,"id2"}.=",".join(',',@id2Add) if ($#id2Add > 0);
	$rd{$id1,"dis"}.=",".join(',',@disAdd) if ($#id2Add > 0); 

	$rd{$id1,"id2"}=~s/^,*|,*$//g; $rd{$id1,"id2"}=~s/^,,+/,/g; 
	$rd{$id1,"dis"}=~s/^,*|,*$//g; $rd{$id1,"dis"}=~s/^,,+/,/g; }

    $id2=$rd{$id1,"id2"}        if (defined $rd{$id1,"id2"});
    $id2=""                     if (! defined $rd{$id1,"id2"});
    $dis=$rd{$id1,"dis"}        if (defined $rd{$id1,"dis"});
    $dis=""                     if (! defined $rd{$id1,"dis"});


				# write 
    print $fhout $id1,$SEP,$rd{$id1,"len"};
    print $fhout $SEP,$rd{$id1,"res"} if (defined $rd{$id1,"res"});
    print $fhout $SEP,$id2;
    print $fhout $SEP,$dis if ($LdoDis);
    print $fhout "\n"; 
}
close($fhout);

print "--- output in $fileOut\n" if (-e $fileOut);
exit;



