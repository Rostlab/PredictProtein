#!/usr/sbin/perl -w
#
#  reads a list of fasta formatted files, and a comparison matric and then
#  computes:
#              <m>   = SUMij  m(ij) * p(i) * p(j)
#
#            sigma   = SUMij  (m(ij)-<m>) * p(i) * p(j)
#
#                        E - <m> * L
#            ->  E' = -------------------
#                        sig * sqrt (L)
#
# 
#  i.e. the length dependent renormalisation of the alignment score
#  
#--------------------------------------------------------------------------------
#
#
$[ =1 ;
				# include libraries
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
require "ctime.pl";
require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";

$smin=-0.05;$smax=1;
$aaString="ACDEFGHIKLMNPQRSTVWY";@aaDef=split('',$aaString);
				# initialise variables
$fhin="FHIN";$fhout="FHOUT";
				# help
if ($#ARGV<1){print "goal:    reads a list of fasta formatted files, \n";
	      print "         and a comparison matric and then computes: <m>, sig\n";
	      print "usage:   script metric *.f\n";
	      print "options: smin=$smin, smax=$smax  (scale min/max of metric)\n";
	      print "         fileOut=x\n";
	      print "         \n";
	      print "         \n";
	      exit;}
				# read command line
$fileMet=$ARGV[1];
$fileOut="Out-".$fileMet;

foreach $_(@ARGV){
    next if ($_ eq $fileMet);
    if   ($_=~/^fileOut=(.*)$/) {$fileOut=$1;}
    elsif($_=~/^fileOut2=(.*)$/){$fileOut=$1;}
    elsif(-e $_)                {push(@fileIn,$_);}
    else {print"*** wrong command line arg '$_'\n";
	  die;}}

$seq="";
foreach $file(@fileIn){
    &open_file("$fhin", "$file");
    while (<$fhin>) {$_=~s/\n//g;
		     next if (/[^A-Z\s]/);
		     $_=~s/[^ACDEFGHIKLMNPQRSTVWY]//g;
		     $seq.="$_";}close($fhin);}
@aaDef=split('',$aaString);
$ctall=0;
foreach $tmp(@aaDef){$res{"$tmp"}= $seq=~s/$tmp//g;
		     $ctall+=$res{"$tmp"};}

printf "%5s\t%6s\t%6s\n","aa","Nocc","%";
$sum=0;
foreach $tmp(@aaDef){$pi{"$tmp"}=$res{"$tmp"}/$ctall;$sum+=$pi{"$tmp"};
		     printf "%5s\t%6d\t%6.3f\n",$tmp ,$res{"$tmp"}, $pi{"$tmp"};}
printf "%5s\t%6d\t%6.3f\n","all" ,$ctall, $sum;

				# ------------------------------
print "--- now metric\n";	# now read the metric
&metricRd;
				# ------------------------------
				# scale metric
print "--- scaling with min=$smin, max=$smax,\n";
&metricScaleSminSmax($smin,$smax);
print "xx unnormalised\n";
foreach $aa1 (@aaDef){
    foreach $aa2 (@aaDef){
	printf "%5.1f ",$mij{"$aa1"."$aa2"}}
    print "\n";
}
print "xx normalised\n";
foreach $aa1 (@aaDef){
    foreach $aa2 (@aaDef){
	printf "%5.1f ",$mijs{"$aa1"."$aa2"}}
    print "\n";
}

				# ------------------------------
				# compute average m
$#m=0;$ave=0;
foreach $aa1 (@aaDef){
    foreach $aa2 (@aaDef){
	$tmp=$mij{"$aa1"."$aa2"}*$pi{"$aa1"}*$pi{"$aa2"};
	push(@m,$tmp);
	$ave+=$tmp;}}
print "xx ave=$ave\n";

$var=0;$#v=0;
foreach $aa1 (@aaDef){
    foreach $aa2 (@aaDef){
	$tmp=($mij{"$aa1"."$aa2"}-$ave)**2;
	$tmp*=$pi{"$aa1"}*$pi{"$aa2"};
	push(@v,$tmp);
	$var+=$tmp;}}
$sig=sqrt($var);

print " var=$var, sig=$sig, ave=$ave\n";


&open_file("$fhout",">$fileOut"); 
print $fhout "# ave=$ave, sig=$sig, var=$var,\n";
foreach $fh ("$fhout","STDOUT"){
    print $fh "len";
    for ($energy=10;$energy<200;$energy+=10){
	print $fh "\tE$energy";}print $fh "\n";
    foreach $it(1..50){
	$len=20*$it;
	print $fh "$len";
	for ($energy=10;$energy<200;$energy+=10){
	    $new=&aliScoreNormalise($energy,$len,$sig,$ave);
	    printf $fh "\t%7.2f",$new;}
	print $fh "\n";}}
close($fhout);

print "--- output in $fileOut\n";
exit;

sub aliScoreNormalise{
    local($score,$len,$sig,$ave)=@_;
    $new=($score - $ave*$len)/($sig*sqrt($len));
    return($new);
}

sub metricRd{			# ------------------------------
    &open_file("$fhin", "$fileMet");
    while (<$fhin>) {
	if (/^AA STR I\/O\s+(V.*)$/){
	    $tmp=$1;$tmp=~s/\s//g;
	    last;}}
    @aaRd=split('',$tmp);
    &myprt_array(",","aard=",@aaRd);
    while (<$fhin>) {
	$_=~s/\n//g;
	$_=~s/^\s+|\s+$//g;
	($aa,@tmp)=split(/\s+/,$_);
	foreach $it (1..$#tmp){
	    $mij{"$aa"."$aaRd[$it]"}=$tmp[$it];}}close($fhin);
}

sub metricScaleSminSmax{
    local($smin,$smax)=@_;
    $max=-100;$min=100;		# find max/min values
    foreach $aa1 (@aaDef){foreach $aa2 (@aaDef){
	if   ($mij{"$aa1"."$aa2"}<$min){$min=$mij{"$aa1"."$aa2"};}
	elsif($mij{"$aa1"."$aa2"}>$max){$max=$mij{"$aa1"."$aa2"};}}}
    print "smax=$smax, smin=$smin, max=$max, min=$min,\n";
    foreach $aa1 (@aaDef){foreach $aa2 (@aaDef){
	$mijs{"$aa1"."$aa2"}=
	    (($smax-$smin)/($max-$min))*$mij{"$aa1"."$aa2"} + ($smax - ($max/($max-$min)));
    }} 
}
