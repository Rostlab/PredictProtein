#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="reads column in RDB file and writes histogram";
#  
#
$[ =1 ;
				# include libraries
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
require "lib-ut.pl"; require "lib-br.pl";
				# defaults
$nhisto=100;
				# help
if ($#ARGV<1){
    print "goal:\t $scrGoal\n";
    print "use: \t '$scrName file'\n";
    print "opt: \t col=COLUMN-No   (default: all)\n";
    print "     \t fileOut=x\n";
    print "     \t nhisto=         (default: $nhisto) : number of bins\n";
#    print "     \t \n";
    exit;}
				# initialise variables
$fhin="FHIN";$fhout="FHOUT";
				# read command line
$fileIn=$ARGV[1];
$tmp=$fileIn;$tmp=~s/^.*\///g;$fileOut="Out-".$tmp;

foreach $_(@ARGV){
    next if ($_ eq $ARGV[1]);
    if   ($_=~/^fileOut=(.*)$/) {$fileOut=$1;}
    elsif($_=~/^col=(.*)$/)     {$colIn=$1;}
    elsif($_=~/^nhisto=(.*)$/)  {$nhisto=$1;}
#    elsif($_=~/^=(.*)$/){$=$1;}
    else {print"*** wrong command line arg '$_'\n";
	  die;}}
				# ------------------------------
				# (1) read file
$#col=0;
@col=split(/,/,$colIn)          if (defined $colIn);

&open_file("$fhin", "$fileIn");
$#READCOL=0;
&rdRdbAssociativeNum($fhin,@col) if ($#col >0);
&rdRdbAssociativeNum($fhin,0)    if ($#col==0);

close($fhin);

				# ------------------------------
$ctCol=0;undef %res;		# (2) compile histogram
foreach $col (@READCOL){
    ++$ctCol;
    @tmp=split(/\t/,$col);foreach $tmp(@tmp){$tmp=~s/\s//g;}
    ($min,$pos)=&get_min(@tmp);
    ($max,$pos)=&get_max(@tmp);

    $itrvl=int(($max-$min)/$nhisto);
				# scale values if interval == 0
    $scale=1;
    while ($itrvl==0) { ++$scale;
			$itrvl=int($scale*($max-$min)/$nhisto); }
	
	
#    print "xx intv=$itrvl, min=$min, max=$max, nhisto=$nhisto,\n";

				# sort it
    @sortTmp= sort bynumber (@tmp);

    $ct=1;$#tmp=0;
    foreach $tmp (@sortTmp){
	while ($scale*$tmp > ($scale*$min + $itrvl*$ct) ){
	    ++$ct;}
	next if  ( $scale*$tmp > ($scale*$min + $itrvl*$ct) );
	if ($scale*$tmp < ($scale*$min + $itrvl*($ct-1) )){
	    print 
		"*** ERROR scale=$scale, tmp=$tmp, ct=$ct, min=",($scale*$min+$itrvl*($ct-1))/$scale,
		", max=",($scale*$min+$itrvl*($ct))/$scale,",\n";
	    exit;}
	if (0){			# xx
	    print 
		"xx tmp=$tmp, scale=$scale, ct=$ct, minHere=",
		($scale*$min + $itrvl*($ct-1))/$scale,", maxHere=",($scale*$min+$itrvl*($ct))/$scale,
		", int=$itrvl / $scale\n";}

	if (defined $tmp[$ct]){
	    ++$tmp[$ct];}
	else{
	    $tmp[$ct]=1;}
    }

    $nhistoMax=$ct;		# store maximal count (may be higher than nhisto)
    ($res{"$ctCol","ave"},$res{"$ctCol","var"})=
	&stat_avevar(@sortTmp);
    
    $res{"$ctCol","min"}=$min;
    $res{"$ctCol","max"}=$max;
    $res{"$ctCol","scale"}=$scale;
    $res{"$ctCol","itrvl"}=$itrvl;

#    print "xx nhistoMax=$nhistoMax,\n";
				# write
    $sum=0;
    foreach $it (1..$nhistoMax){
	next if ($#READCOL == 1 && ! defined $tmp[$it]);
	if (! defined $tmp[$it]){
	    $res{"$ctCol","$it"}="";}
	else {
	    $sum+=$tmp[$it];
	    $res{"$ctCol","$it"}=$tmp[$it];}}
#    print "xx sum = $sum, number of elements=",$#sortTmp,", min=$min, max=$max\n";
#    exit;
}
				# ------------------------------
                                # (3) write output
&open_file("$fhout",">$fileOut"); 
				# header
print $fhout "\# Perl-RDB\n\#\n";
				# names
foreach $it (1..$#READCOL){
    printf $fhout 
	"\# COL %5d ave=%6.1f var=%6.1f sig=%6.1f min=%6.1f max=%6.1f\n",
	$it,$res{"$ctCol","ave"},$res{"$ctCol","var"},sqrt($res{"$ctCol","var"}),
	$res{"$ctCol","min"},$res{"$ctCol","max"};}

$tmpWrt="";
foreach $ctCol (1..$#READCOL){
    if ($ctCol > 1) {
	$tmpWrt.= sprintf("%5s\t%8s\t%8s\t%-s\t",
			  "n".$ctCol,"min".$ctCol,"max".$ctCol,"his".$ctCol);}
    else {
	$tmpWrt.= sprintf("%5s\t%8s\t%8s\t%-s\t","n","min","max","his");}
}
$tmpWrt=~s/\t$//g;
print $fhout "$tmpWrt\n";
				# ------------------------------
				# data
foreach $it (1 .. $nhistoMax){
    $tmpWrt=          "";
    $Lok=0;
    foreach $ctCol (1..$#READCOL){
	next if (! defined $res{"$ctCol","$it"} && $#READCOL==1) ;

	if (! defined $res{"$ctCol","$it"}){
	    $tmpWrt.= sprintf("%5d\t%8.2f\t%8.2f\t%-s\t",$it,
			      ($min+ ($res{"$ctCol","itrvl"}*($it-1)/$res{"$ctCol","scale"})),
			      ($min+ ($res{"$ctCol","itrvl"}*  $it  /$res{"$ctCol","scale"})),
			      "");}
	else {
	    $Lok=1;
	    $tmpWrt.= sprintf("%5d\t%8.2f\t%8.2f\t%-s\t",$it,
			      ($min+ ($res{"$ctCol","itrvl"}*($it-1)/$res{"$ctCol","scale"})),
			      ($min+ ($res{"$ctCol","itrvl"}*  $it  /$res{"$ctCol","scale"})),
			      $res{"$ctCol","$it"});}
    }
    next if (! $Lok);
    $tmpWrt=~s/\t$//g;
    print $fhout "$tmpWrt\n";
}close($fhout);

print "--- output in $fileOut\n";
exit;
