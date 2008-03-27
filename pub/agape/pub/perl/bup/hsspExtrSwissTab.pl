#!/usr/sbin/perl -w
#
# reads /data/hssp/hssp_swissprot.table and extracts statistics: how many
# proteins with with pide>low and lenAli>lowLen ?
#
$[ =1 ;

push (@INC, "/home/rost/perl") ;
# require "ctime.pl";		# require "rs_ut.pl" ; 
require "lib-ut.pl"; require "lib-br.pl";
# require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";

				# defaults
$lowPide=30;
$lowLali=40;
$interv= 1;			# compute histogram for every 5 percentage points

if ($#ARGV<1){
    print"goal:   how many proteins with pide>low and lenAli>lowLen?\n";
    print"        extract from /data/hssp/hssp_swissprot.table\n";
    print"usage:  script hssp_swissprot.table (option low=90, len=50)\n";
    print"option: option low=90 (default=$lowPide), len=50 (default=$lowLali)\n";
    print"option: notExcl (don't exclude first hit, is for Hom Modelling statistics)\n";
    exit;}
				# defaults
$fileTable=$ARGV[1];
# $fileTable="/data/hssp/hssp_swissprot.table";

@intervRatio=("1","0.8","0.6","0.4","0.2","0");
$fhin="FHIN";$fhout="FHOUT";
$LexclSelf=1;
				# read input
foreach $_ (@ARGV){
    if   (/^low=/)  {$_=~s/^low=//g;$_=~s/\s//g;$lowPide=$_;}
    elsif(/^len=/)  {$_=~s/^len=//g;$_=~s/\s//g;$lowLali=$_;}
    elsif(/^notExcl/){$LexclSelf=0;}
}
print "--- low=$lowPide, len=$lowLali, ";
if(! $LexclSelf){print" don't excl self,";}print",\n";

$title=$fileTable;$title=~s/^.*\///g;$title=~s/\..*$//g;
$fileOut="Out-"."$title"."-pide"."$lowPide"."-len"."$lowLali";
$fileOutDet="OutDet-"."$title"."-pide"."$lowPide"."-len"."$lowLali";
$fileOutHis="OutHis-"."$title"."-pide"."$lowPide"."-len"."$lowLali";

#$fileOut="xxOut-"."$lowPide"."-"."$lowLali" ;$fileOutDet="xxOutDet-"."$lowPide"."-"."$lowLali";$fileOutHis="xxOutHis-"."$lowPide"."-"."$lowLali";


$idMemory="";
&open_file("$fhin", "$fileTable");

$ct=$ctRd=0;$ratioResCovered=0;
while (<$fhin>) {
    if (! /^ \d/){		# exclude header
	next;}
    $_=~s/\n//g;$tmp=$_;
    $idSeq=  substr($tmp,1,8);   $idSeq=~s/\s//g; 
    $idStr=  substr($tmp,19,10); $idStr=~s/([^\s]+) .*$/$1/g;
    $pide=   substr($tmp,39,4); 
    $lenAli= substr($tmp,69,8); $lenAli=~s/\s//g;
    $lenSeq2=substr($tmp,84,6); $lenSeq2=~s/\s//g;
    if    ($pide==1){ # exclude self
	$flag{"$idSeq"}=1; $idMemory=$idSeq; 
	if ($LexclSelf){
	    next;}}
    elsif ("$idMemory" ne "$idSeq"){ # exclude first hit <100 if none had 100
	$flag{"$idSeq"}=1; $idMemory=$idSeq; 
	if ($LexclSelf){
	    next;}}
    ++$ctRd;
    if (((100*$pide)>=$lowPide)&&($lenAli>$lowLali)){
	++$ct;$ratioResCovered+=($lenAli/$lenSeq2);
#	if ($ct>100){last;}	# x.x
	printf 
	    "%-15s %-15s %-5d %-5d %-6.2f\n",
	    $idSeq,$idStr,100*$pide,$lenAli,($lenAli/$lenSeq2);
				# store unique id's (avoid counting twice!)
	if (! defined $flag{"$idStr"}){
	    $flag{"$idStr"}=1;
	    push(@idFound,$idStr);
	    $res{"$idStr","idSeq"}=$idSeq;
	    $res{"$idStr","pide"} =(100*$pide);
	    $res{"$idStr","ratio"}=($lenAli/$lenSeq2);
	    $res{"$idStr","lenAli"}=$lenAli;}
	elsif ($flag{"$idStr"} && 
	       ((100*$pide)>$res{"$idStr","pide"})){ # replace if higher identity
	    $res{"$idStr","idSeq"}=$idSeq;
	    $res{"$idStr","pide"} =(100*$pide);
	    $res{"$idStr","ratio"}=($lenAli/$lenSeq2);
	    $res{"$idStr","lenAli"}=$lenAli;}}
}close($fhin);

print "number of id's (unique) found=",$#idFound,"\n";print "write output into $fileOut\n";
print "ratio covered=",($ratioResCovered/$ct),"\n";
				# ------------------------------
				# file with id's
&open_file("$fhout", ">$fileOut");
foreach $id(@idFound){
    print $fhout "$id\n";}
close($fhout);
				# ------------------------------
				# file with details
&open_file("$fhout", ">$fileOutDet");
printf $fhout "%-15s\t%-15s\t%-5d\t%-5s\t%-6s\n","idSeq","idStr","pide","lenAli","ali/l2";
foreach $id(@idFound){
    printf $fhout 
	"%-15s\t%-15s\t%-5d\t%-5d\t%-6.2f\n",
	$res{"$id","idSeq"},"$id",$res{"$id","pide"},$res{"$id","lenAli"},$res{"$id","ratio"};
}
close($fhout);

				# ------------------------------
				# file with histograms
				# ini histo
$tmp=$interv;$#interv=0;
while( (100-$tmp)>=$lowPide){push(@interv,(100-$tmp));$tmp+=$interv;}
foreach $tmp(@interv){foreach $des("all",@intervRatio){$his{"$des","$tmp"}=0;}}
				# compile histo
foreach $id(@idFound){
    foreach $pide(@interv){
	if ($res{"$id","pide"} >= $pide){
	    ++$his{"all","$pide"};
	    foreach $ratio(@intervRatio){
		if ($res{"$id","ratio"} >= $ratio){
		    ++$his{"$ratio","$pide"};
		    last;}}
	    last;}}
}
				# write file
&open_file("$fhout", ">$fileOutHis");
printf $fhout "%-6s\t","pide";	# header
foreach $des("all","allCum",@intervRatio){printf $fhout "%-6s\t",$des;}
print $fhout "\n";

$pideAll=0;			# x.x
foreach $des("all",@intervRatio){
    $sum{"$des"}=0;}
foreach $it(1..$#interv){		# body
    $pide=$interv[$#interv-$it+1];
    printf $fhout "%-6s\t",$pide;
    foreach $des("all","allCum",@intervRatio){
	if    ($des eq "all"){
	    $sum{"$des"}+=$his{"$des","$pide"};
	    printf $fhout "%-6d\t",$his{"$des","$pide"};}
	elsif ($des eq "allCum"){
	    printf $fhout "%-6d\t",$sum{"all"};}
	else {
	    $sum{"$des"}+=$his{"$des","$pide"};
	    printf $fhout "%-6d\t",$sum{"$des"};}}

    $pideAll+=$his{"all","$pide"}; # x.x
    print $fhout "\n";}
close($fhout);
print"x.x $pideAll,\n";
print "output in files:$fileOut,$fileOutDet,$fileOutHis,\n";

exit;
