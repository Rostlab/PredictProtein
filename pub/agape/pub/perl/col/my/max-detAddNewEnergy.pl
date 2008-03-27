#!/usr/sbin/perl -w
#
$scriptName=$0;$scriptName=~s/^.*\/|\.pl//g;
#  
# adds len corrected energy to detT* or detF* files from hsspHdrRdb2stat.pl
#
$[ =1 ;
				# include libraries
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
require "ctime.pl";
require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";

$aveMetric=-0.966450407351641;	# smin = -0.05, smax=1
$sigMetric=2.09061052832112;
				# help
if ($#ARGV<1){
    print "goal:    add len corrected energy to detT* or detF* files from hsspHdrRdb2stat.pl\n";
    print "usage:   script det*      (default out: same but detX-newE)\n";
    print "options: title=x\n";
    print "         ave=             (<m> def=$aveMetric)\n";
    print "         sig=             (<m> def=$sigMetric)\n";
    exit;}
				# initialise variables
$fhin="FHIN";$fhout="FHOUT";
$#fileIn=0;			# read command line
foreach $_(@ARGV){
    if   ($_=~/^title=(.*)$/){$title=$1;}
#    elsif($_=~/^=(.*)$/){$=$1;}
    elsif(-e $_){push(@fileIn,$_);}
    else {print"*** wrong command line arg '$_'\n";
	  die;}}

# expected header
# id1T,id2T,pideT,psimT,laliT,ngapT,lgapT,len1T,len2T,energyT,zscoreT,doldT,dIdeT,dSimT,
#   1    2    3     4     5     6     7     8     9      10     11      12    13    14
				# --------------------------------------------------
				# (1) read files
$#zsco=$#ener=0;undef %zsco;undef %ener;
foreach $fileIn (@fileIn){
    if (!defined $title){$title="normE";}
    $fileOut=$fileIn;$fileOut=~s/([Dd]et[TF])-/$1-$title-/g;
    &open_file("$fhin", "$fileIn"); print "--- reading $fileIn";
    if ($fileIn =~/detT/){$Ltrue=1;$txt="T";}else{$Ltrue=0;$txt="F";} 
    if ($Ltrue){print " is true?  (out=$fileOut)\n";}else{print " is false?  (out=$fileOut)\n";}
    &open_file("$fhout",">$fileOut"); 
    while (<$fhin>) {
	$_=~s/\n//g; $line=$_;
	if (/^id/){
	    print $fhout "$_","\t","enerNorm"."$txt","\n";
	    next;}
	$tmp=$_;$tmp=~s/\t$//g;
	@tmp=split(/[\t\s]+/,$tmp);
	$lali=$tmp[5];
	$ener=$tmp[10];
	($Lok,$enerNew)=
	    &maxhomNormaliseEnergy($lali,$ener,$aveMetric,$sigMetric);

	if (! $Lok){print "*** error in maxhomNormaliseEnergy:\n";
		    print "*** $enerNew\n";
		    die;}
	print  $fhout "$line","\t";
	printf $fhout "%6.2f\n",$enerNew;
    }close($fhin);close($fhout);
}
exit;

#===============================================================================
sub maxhomNormaliseEnergy {
    local($laliLoc,$energyLoc,$aveMetric,$sigMetric) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   maxhomNormaliseEnergy       compiles the energy normalisation proposed by
#                               Alexandrov & Soloveyev
#                               
#                                       oldE - <m> * Len
#                               newE = ----------------------------
#                                         sigma * sqrt(Len)
#                               
#                               where <m> is the average metric ( = SUM(ij) p(i) p(j) m(ij))
#                               and sigma = sqrt ( SUM(ij) [ (m(ij) - <m>)**2 p(i) p(j) ] )
#                               
#       in:                     $lali,$energy,$aveMetric,$sigMetric
#       out:                    ($Lok,$newEnergy) 
#-------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";}
    $sbrName="$tmp"."maxhomNormaliseEnergy";$fhinLoc="FHIN"."$sbrName";

    return(0,"*** $sbrName not def laliLoc!\n")   if (! defined $laliLoc);
    return(0,"*** $sbrName not def energyLoc!\n") if (! defined $energyLoc);
    return(0,"*** $sbrName not def aveMetric!\n") if (! defined $aveMetric);
    return(0,"*** $sbrName not def sigMetric!\n") if (! defined $sigMetric);

    $top=$energyLoc - ($aveMetric * $laliLoc);
    $bot=$sigMetric * sqrt($laliLoc);
    return(0,"*** $sbrName division by zero!\n".
	   "*** in=($laliLoc,$energyLoc,$aveMetric,$sigMetric)\n") if ($bot==0);
    return(1,($top/$bot));
}				# end of maxhomNormaliseEnergy

