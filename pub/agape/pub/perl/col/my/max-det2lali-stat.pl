#!/usr/sbin/perl -w
#
$scriptName=$0;$scriptName=~s/^.*\/|\.pl//g;
#  
#  takes files detT* (and detF* = separate) and makes grid for lali vs. ide
#
$[ =1 ;
				# include libraries
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
require "ctime.pl";
require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";

$gridLali=10;
$gridLali=5;

if ($#ARGV<1){			# help
    print "goal:    in: files detT* (and detF* = separate), makes grid for lali vs. ide,sim,E,Z\n";
    print "usage:   script detT|F*  (note must have T or F in name to recognise true/false)\n";
    print "options: \n";
    print "         title=x\n";
    print "         grid=$gridLali  (intervals for lali)\n";
    print "         \n";
    exit;}
				# initialise variables
$fhin="FHIN";$fhout="FHOUT";
$#fileIn=0;			# read command line
foreach $_(@ARGV){
    if   ($_=~/^title=(.*)$/){$title=$1;}
    elsif($_=~/^grid=(.*)$/){$gridLali=$1;}
    elsif(-e $_){push(@fileIn,$_);}
    else {print"*** wrong command line arg '$_'\n";
	  die;}}

$laliMin=10;

@kwd=("Ide","Sim","Ener","Zsco");
# expected header
# id1T,id2T,pideT,psimT,laliT,ngapT,lgapT,len1T,len2T,energyT,zscoreT,doldT,dIdeT,dSimT,
#   1    2    3     4     5     6     7     8     9      10     11      12    13    14
				# --------------------------------------------------
				# (1) read files
$#zsco=$#ener=$#pide=$#psim=$#lali=0;
undef %zsco; undef %ener; undef %pide;undef %psim; undef %lali;
foreach $fileIn (@fileIn){
    &open_file("$fhin", "$fileIn"); print "--- reading $fileIn";
    if ($fileIn =~/detT/){$Ltrue=1;$txt="T";}else{$Ltrue=0;$txt="F";} 
    if ($Ltrue){print " is true?\n";}else{print " is false? (DO NOT mix!)\n";}
    while (<$fhin>) {
	undef %tmp;
	$_=~s/\n//g;$_=~s/\t$//g;
	next if (/^id/);@tmp=split(/[\t\s]+/,$_);
	next if ($tmp[5]< $laliMin); # leave out too short stretches
	$pide=$tmp{"Ide"}= &fRound($tmp[3]); $pide=100 if ($pide>100);
	$psim=$tmp{"Sim"}= &fRound($tmp[4]); $psim=100 if ($psim>100);
	$ener=$tmp{"Ener"}=&fRound($tmp[10]);
	$zsco=$tmp{"Zsco"}=(int(5*$tmp[11]))/5; 
	$lali=$gridLali*int($tmp[5]/$gridLali);
	if (! defined $ener{"$ener"}){$ener{"$ener"}=1;push(@ener,$ener);}
	if (! defined $zsco{"$zsco"}){$zsco{"$zsco"}=1;push(@zsco,$zsco);}
	if (! defined $pide{"$pide"}){$pide{"$pide"}=1;push(@pide,$pide);}
	if (! defined $psim{"$psim"}){$psim{"$psim"}=1;push(@psim,$psim);}
	if (! defined $lali{"$lali"}){$lali{"$lali"}=1;push(@lali,$lali);}

	foreach $kwd (@kwd){	# now sum number of occurrences
	    $tmp=$tmp{"$kwd"}.$lali;
	    if (! defined $occ{"$kwd","$tmp"}){
		$occ{"$kwd","$tmp"}=1;}
	    else {
		++$occ{"$kwd","$tmp"};}}
    }close($fhin);
}
				# --------------------------------------------------
				# (2) get sums and cumulative
@enerS=sort bynumber_high2low(@ener);
@zscoS=sort bynumber_high2low(@zsco);
@pideS=sort bynumber_high2low(@pide);
@psimS=sort bynumber_high2low(@psim);
@laliS=sort bynumber_high2low(@lali);
				# --------------------------------------------------
				# (3) write output
$sep="\t";
foreach $kwd(@kwd){
    if (defined $title){$fileOut="lali".$kwd.$txt."-".$title.".dat";}
    else{$fileOut="lali".$kwd.$txt."-max.dat";}
    &open_file("$fhout",">$fileOut"); 

    print $fhout "$kwd",$sep,"lali",$sep,"nocc","\n";

    if    ($kwd eq "Ide") {@score=@pideS;}
    elsif ($kwd eq "Sim") {@score=@psimS;}
    elsif ($kwd eq "Ener"){@score=@enerS;}
    elsif ($kwd eq "Zsco"){@score=@zscoS;}

    foreach $score(@score){
	foreach $lali(@laliS){
	    next if (! defined $occ{"$kwd","$score"."$lali"});
	    printf $fhout "%6.2f$sep%6d$sep%6d\n",$score,$lali,$occ{"$kwd","$score"."$lali"};}
    }
    close($fhout);}
print "--- output in $fileOut\n";
exit;



