#!/usr/sbin/perl -w
#
$scriptName=$0;$scriptName=~s/^.*\/|\.pl//g;
#  
#  histograms from all det(T|F) files from (hsspHdrRdb2stat.pl) and 
#
$[ =1 ;
				# include libraries
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
require "ctime.pl";
require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
				# help
if ($#ARGV<1){
    print "goal:    histograms from all det(T|F) files from (hsspHdrRdb2stat.pl) and \n";
    print "usage:   script det*      (note must have T or F in name to recognise true/false)\n";
    print "options: \n";
    print "         title=x\n";
    print "         \n";
    print "         \n";
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

$laliMin=10;
@kwdP=("pide","psim","dold","dide","dsim");@kwdE=("ener");@kwdZ=("zsco");@kwdEnorm=("enerNorm");
# expected header
# id1T,id2T,pideT,psimT,laliT,ngapT,lgapT,len1T,len2T,energyT,zscoreT,doldT,dIdeT,dSimT,enerNewT
#   1    2    3     4     5     6     7     8     9      10     11      12    13    14 , 15
				# --------------------------------------------------
				# (1) read files
$#zsco=$#ener=$#enerNorm=0;undef %zsco;undef %ener;undef %enerNorm;
foreach $fileIn (@fileIn){
    &open_file("$fhin", "$fileIn"); print "--- reading $fileIn";
    if ($fileIn =~/detT/){$Ltrue=1;$txt="T";}else{$Ltrue=0;$txt="F";} 
    if ($Ltrue){print " is true?\n";}else{print " is false?\n";}
    while (<$fhin>) {
	undef %tmp;
	$_=~s/\n//g;$_=~s/\t$//g;
	next if (/^id/);@tmp=split(/[\t\s]+/,$_);
	next if ($tmp[5]< $laliMin); # leave out too short stretches
	$tmp{"pide"}=&fRound($tmp[3]); 
	$tmp{"psim"}=&fRound($tmp[4]);
	$ener=$tmp{"ener"}=&fRound($tmp[10]);
	$zsco=$tmp{"zsco"}=(int(10*$tmp[11]))/10; 
	if    (!defined $Lnorm && ($#tmp>14)){
	    $Lnorm=1;}
	elsif (!defined $Lnorm && ($#tmp==14)){
	    $Lnorm=0;}
	if ($Lnorm){
	    $enerNorm=$tmp{"enerNorm"}=(int(10*$tmp[15]))/10;}
	$tmp{"dold"}=&fRound($tmp[12]); 
	$tmp{"dide"}=&fRound($tmp[13]);
	$tmp{"dsim"}=&fRound($tmp[14]);
	foreach $kwd ("dold","dide","dsim"){ # limit to analog of 100
	    if ($tmp{"$kwd"}<-25){$tmp{"$kwd"}=-25;}}
	if (! defined $ener{"$ener"})    {$ener{"$ener"}=1;    push(@ener,$ener);}
	if (! defined $zsco{"$zsco"})    {$zsco{"$zsco"}=1;    push(@zsco,$zsco);}
	if ($Lnorm){
	    if (! defined $ener{"$enerNorm"}){$ener{"$enerNorm"}=1;push(@enerNorm,$enerNorm);}
	    @tmp=(@kwdP,@kwdE,@kwdZ,@kwdEnorm);}
	else {
	    @tmp=(@kwdP,@kwdE,@kwdZ);}
	
	foreach $kwd(@tmp){
	    $tmp=$tmp{"$kwd"};
	    if (! defined $res{"n"."$txt"."$kwd","$tmp"}){$res{"n"."$txt"."$kwd","$tmp"}=1;}
	    else {++$res{"n"."$txt"."$kwd","$tmp"};}}
	if ($tmp{"psim"} > $tmp{"pide"}){
	    $kwd="dsGi";$tmp=$tmp{"dide"};
	    if (! defined $res{"n"."$txt"."$kwd","$tmp"}){$res{"n"."$txt"."$kwd","$tmp"}=1;}
	    else {++$res{"n"."$txt"."$kwd","$tmp"};}}
    }close($fhin);
}
				# --------------------------------------------------
				# (2) get sums and cumulative
@sortEner=    sort bynumber_high2low(@ener);
@sortZsco=    sort bynumber_high2low(@zsco);
if ($Lnorm){
    @sortEnerNorm=sort bynumber_high2low(@enerNorm);}
				# ------------------------------
foreach $kwd(@kwdP,"dsGi"){	# percentage stuff
    $sum{"$kwd"}=0;}
foreach $dist (0..125){		# total sum true
    $dist=100-$dist;
    foreach $kwd(@kwdP,"dsGi"){if (defined $res{"nT"."$kwd","$dist"}){
	$sum{"$kwd"}+=$res{"nT"."$kwd","$dist"};
#	if ($kwd =~ /^d/){print "d=$dist, r=",$res{"nT"."$kwd","$dist"},", s=",$sum{"$kwd"},",\n";}
    }}}
foreach $kwd(@kwdP,"dsGi"){print "xx sum for $kwd=",$sum{"$kwd"},"\n";} # xx

foreach $kwd(@kwdP,"dsGi"){	# cumulative 
    $cumT{"$kwd"}=$cumF{"$kwd"}=0;}
foreach $dist (1..125){
    $dist=100-$dist;
    foreach $kwd(@kwdP,"dsGi"){
	if (defined $res{"nT"."$kwd","$dist"}){$cumT{"$kwd"}+=$res{"nT"."$kwd","$dist"};}
	$res{"ncT"."$kwd","$dist"}=$cumT{"$kwd"};
	if (defined $res{"nF"."$kwd","$dist"}){$cumF{"$kwd"}+=$res{"nF"."$kwd","$dist"};}
	$res{"ncF"."$kwd","$dist"}=$cumF{"$kwd"};}}
				# ------------------------------
$kwd="ener";			# energy
$sum{"$kwd"}=0;$cumT=$cumF=0;
foreach $dis (@sortEner){	# total sums: energy
    if (defined $res{"nT"."$kwd","$dis"}){$sum{"$kwd"}+=$res{"nT"."$kwd","$dis"};}}
print "xx sum for $kwd=",$sum{"$kwd"},"\n";
foreach $dis (@sortEner){	# cumulative values
    if (defined $res{"nT"."$kwd","$dis"}){$cumT+=$res{"nT"."$kwd","$dis"};}
    if (defined $res{"nF"."$kwd","$dis"}){$cumF+=$res{"nF"."$kwd","$dis"};}
    $res{"ncT"."$kwd","$dis"}=$cumT;$res{"ncF"."$kwd","$dis"}=$cumF;}
				# ------------------------------
$kwd="zsco";			# zscore
$sum{"$kwd"}=$cumT=$cumF=0;
foreach $dis (@sortZsco){	# total sums: energy
    if (defined $res{"nT"."$kwd","$dis"}){$sum{"$kwd"}+=$res{"nT"."$kwd","$dis"};}}
print "xx sum for $kwd=",$sum{"$kwd"},"\n";
foreach $dis (@sortZsco){	# cumulative values
    if (defined $res{"nT"."$kwd","$dis"}){$cumT+=$res{"nT"."$kwd","$dis"};}
    if (defined $res{"nF"."$kwd","$dis"}){$cumF+=$res{"nF"."$kwd","$dis"};}
    $res{"ncT"."$kwd","$dis"}=$cumT;$res{"ncF"."$kwd","$dis"}=$cumF;}
				# ------------------------------
$kwd="enerNorm";		# normalised energy
if ($Lnorm){
    $sum{"$kwd"}=0;$cumT=$cumF=0;
    foreach $dis (@sortEnerNorm){ # total sums: energy
	if (defined $res{"nT"."$kwd","$dis"}){$sum{"$kwd"}+=$res{"nT"."$kwd","$dis"};}}
    print "xx sum for $kwd=",$sum{"$kwd"},"\n";
    foreach $dis (@sortEnerNorm){	# cumulative values
	if (defined $res{"nT"."$kwd","$dis"}){$cumT+=$res{"nT"."$kwd","$dis"};}
	if (defined $res{"nF"."$kwd","$dis"}){$cumF+=$res{"nF"."$kwd","$dis"};}
	$res{"ncT"."$kwd","$dis"}=$cumT;$res{"ncF"."$kwd","$dis"}=$cumF;}
}
				# --------------------------------------------------
				# (3) write output
$sep="\t";
if (defined $title){$fileOut="hisP-".$title.".dat";}else{$fileOut="hisP-max.dat";}
&open_file("$fhout",">$fileOut"); 
print $fhout "Di,s|i,s","$sep";
@kwdP2=(@kwdP,"dsGi");
#@kwdP2=("pide");		# xx
foreach $kwd(@kwdP2){
    foreach $kwd2("PcT=ncT/nc","PcF=ncF/nc","PaT=ncT/allT","%T=nT/nF"){
	print $fhout $kwd2.$kwd,"$sep";}}
foreach $kwd(@kwdP2){
    foreach $kwd2("nT","nF","ncT","ncF"){
	print $fhout $kwd2.$kwd,"$sep";}}print $fhout "\n";

foreach $kwd(@kwdP2){foreach $kwd2("ncT","ncF"){
    $store{"$kwd2"."$kwd"}=0;}}
				# 
foreach $dist (0..125){
    $dist=100-$dist;$tmp=0;
    foreach $kwd(@kwdP2){
	foreach $kwd2("nT","nF"){
	    if (defined $res{"$kwd2"."$kwd","$dist"}){$tmp+=$res{"$kwd2"."$kwd","$dist"};}}}
    next if ($tmp<1);		# none found for current distance -> skip
    printf $fhout "%6d",$dist;
    foreach $kwd(@kwdP2){
	if (! defined $res{"nT"."$kwd","$dist"}) {$nT=0;} else{$nT=$res{"nT"."$kwd","$dist"};}
	if (! defined $res{"nF"."$kwd","$dist"}) {$nF=0;} else{$nF=$res{"nF"."$kwd","$dist"};}
	$ncT=$res{"ncT"."$kwd","$dist"};
	$ncF=$res{"ncF"."$kwd","$dist"};
	if    (! defined $ncT || ! defined $ncF){
	    printf $fhout "$sep%5s$sep%5s$sep%5s"," "," "," ";}
	elsif (($ncT+$ncF)>0){
	    printf $fhout 
		"$sep%5.1f$sep%5.1f$sep%5.1f",
		100*($ncT/($ncT+$ncF)),100*($ncF/($ncT+$ncF)),100*($ncT/$sum{"$kwd"});}
	else {printf $fhout 
		  "$sep%5.1f$sep%5.1f$sep%5.1f",0,0,100*($ncT/$sum{"$kwd"});}
	if(($nT+$nF)>0){$tmp=100*($nT/($nT+$nF));}else{$tmp=0;}
	printf $fhout "$sep%5.1f",$tmp;}
    foreach $kwd(@kwdP2){
	foreach $kwd2("nT","nF","ncT","ncF"){
	    if (defined $res{"$kwd2"."$kwd","$dist"}){
		$tmp=$res{"$kwd2"."$kwd","$dist"};}
	    else {$tmp=0;}
	    printf $fhout "$sep%6d",$tmp;}}
    print $fhout "\n";
} close($fhout);
				# ------------------------------
				# energy
if (defined $title){$fileOut="hisE-".$title.".dat";}else{$fileOut="hisE-max.dat";}
&open_file("$fhout",">$fileOut"); 
$kwd="ener";$des="-E";
print $fhout "energy","$sep";
foreach $kwd2("PcT=ncT/nc","PcF=ncF/nc","PaT=ncT/allT","%T=nT/nF"){
    print $fhout $kwd2.$des,"$sep";}

foreach $kwd2("nT","nF","ncT","ncF"){print $fhout $kwd2.$des,"$sep";}print $fhout "\n";

foreach $kwd2("ncT","ncF"){$store{"$kwd2"."$kwd"}=0;}
foreach $dist (@sortEner){
    $tmp=0;foreach $kwd2("nT","nF"){
	if (defined $res{"$kwd2"."$kwd","$dist"}){$tmp+=$res{"$kwd2"."$kwd","$dist"};}}
    next if ($tmp<1);

    if (! defined $res{"nT"."$kwd","$dist"}) {$nT=0;} else{$nT=$res{"nT"."$kwd","$dist"};}
    if (! defined $res{"nF"."$kwd","$dist"}) {$nF=0;} else{$nF=$res{"nF"."$kwd","$dist"};}
    if (! defined $res{"ncT"."$kwd","$dist"}){$ncT=$store{"ncT"."$kwd"};}
    else{$ncT=$res{"ncT"."$kwd","$dist"};$store{"ncT"."$kwd"}=$ncT;}
    if (! defined $res{"ncF"."$kwd","$dist"}){$ncT=$store{"ncF"."$kwd"};}
    else{$ncF=$res{"ncF"."$kwd","$dist"};$store{"ncF"."$kwd"}=$ncF;}
    next if (($ncF+$ncT)<1);

    printf $fhout "%6.1f",$dist;
    printf $fhout 
	"$sep%5.1f$sep%5.1f$sep%5.1f",
	100*($ncT/($ncT+$ncF)),100*($ncF/($ncT+$ncF)),100*($ncT/$sum{"$kwd"});
    if(($nT+$nF)>0){$tmp=100*($nT/($nT+$nF));}else{$tmp=0;}
    printf $fhout "$sep%5.1f",$tmp;
    
    foreach $kwd2("nT","nF","ncT","ncF"){
	if (defined $res{"$kwd2"."$kwd","$dist"}){
	    $tmp=$res{"$kwd2"."$kwd","$dist"};}
	else {$tmp=0;}
	print $fhout "$sep",$tmp;}
    print $fhout "\n";
} close($fhout);
				# ------------------------------
				# zscore
if (defined $title){$fileOut="hisZ-".$title.".dat";}else{$fileOut="hisZ-max.dat";}
&open_file("$fhout",">$fileOut"); 
$kwd="zsco";$des="-Z";
print $fhout "zscore","$sep";
foreach $kwd2("PcT=ncT/nc","PcF=ncF/nc","PaT=ncT/allT","%T=nT/nF"){
    print $fhout $kwd2.$des,"$sep";}
foreach $kwd2("nT","nF","ncT","ncF"){print $fhout $kwd2.$des,"$sep";}print $fhout "\n";

foreach $kwd2("ncT","ncF"){$store{"$kwd2"."$kwd"}=0;}
foreach $dist (@sortZsco){
    $tmp=0;foreach $kwd2("nT","nF"){
	if (defined $res{"$kwd2"."$kwd","$dist"}){$tmp+=$res{"$kwd2"."$kwd","$dist"};}}
    next if ($tmp<1);

    if (! defined $res{"nT"."$kwd","$dist"}) {$nT=0;} else{$nT=$res{"nT"."$kwd","$dist"};}
    if (! defined $res{"nF"."$kwd","$dist"}) {$nF=0;} else{$nF=$res{"nF"."$kwd","$dist"};}
    if (! defined $res{"ncT"."$kwd","$dist"}){$ncT=$store{"ncT"."$kwd"};}
    else{$ncT=$res{"ncT"."$kwd","$dist"};$store{"ncT"."$kwd"}=$ncT;}
    if (! defined $res{"ncF"."$kwd","$dist"}){$ncT=$store{"ncF"."$kwd"};}
    else{$ncF=$res{"ncF"."$kwd","$dist"};$store{"ncF"."$kwd"}=$ncF;}
    next if (($ncF+$ncT)<1);

    printf $fhout "%6.2f",$dist;
    printf $fhout 
	"$sep%5.1f$sep%5.1f$sep%5.1f",
	100*($ncT/($ncT+$ncF)),100*($ncF/($ncT+$ncF)),100*($ncT/$sum{"$kwd"});
    if(($nT+$nF)>0){$tmp=100*($nT/($nT+$nF));}else{$tmp=0;}
    printf $fhout "$sep%5.1f",$tmp;
    
    foreach $kwd2("nT","nF","ncT","ncF"){
	if (defined $res{"$kwd2"."$kwd","$dist"}){
	    $tmp=$res{"$kwd2"."$kwd","$dist"};}
	else {$tmp=0;}
	print $fhout "$sep",$tmp;}
    print $fhout "\n";
} close($fhout);
				# ------------------------------
				# normalised energy
if ($Lnorm){
    if (defined $title){$fileOut="hisEn-".$title.".dat";}else{$fileOut="hisEn-max.dat";}
    &open_file("$fhout",">$fileOut"); 
    $kwd="enerNorm";$des="-EN";
    print $fhout "energyNorm","$sep";
    foreach $kwd2("PcT=ncT/nc","PcF=ncF/nc","PaT=ncT/allT","%T=nT/nF"){
	print $fhout $kwd2.$des,"$sep";}
    
    foreach $kwd2("nT","nF","ncT","ncF"){print $fhout $des.$kwd,"$sep";}print $fhout "\n";
    
    foreach $kwd2("ncT","ncF"){$store{"$kwd2"."$kwd"}=0;}
    foreach $dist (@sortEnerNorm){
	$tmp=0;foreach $kwd2("nT","nF"){
	    if (defined $res{"$kwd2"."$kwd","$dist"}){$tmp+=$res{"$kwd2"."$kwd","$dist"};}}
	next if ($tmp<1);

	if (! defined $res{"nT"."$kwd","$dist"}) {$nT=0;} else{$nT=$res{"nT"."$kwd","$dist"};}
	if (! defined $res{"nF"."$kwd","$diwc -l detF-st"}) {$nF=0;} else{$nF=$res{"nF"."$kwd","$dist"};}
	if (! defined $res{"ncT"."$kwd","$dist"}){$ncT=$store{"ncT"."$kwd"};}
	else{$ncT=$res{"ncT"."$kwd","$dist"};$store{"ncT"."$kwd"}=$ncT;}
	if (! defined $res{"ncF"."$kwd","$dist"}){$ncT=$store{"ncF"."$kwd"};}
	else{$ncF=$res{"ncF"."$kwd","$dist"};$store{"ncF"."$kwd"}=$ncF;}
	next if (($ncF+$ncT)<1);

	printf $fhout "%6.1f",$dist;
	printf $fhout 
	    "$sep%5.1f$sep%5.1f$sep%5.1f",
	    100*($ncT/($ncT+$ncF)),100*($ncF/($ncT+$ncF)),100*($ncT/$sum{"$kwd"});
	if(($nT+$nF)>0){$tmp=100*($nT/($nT+$nF));}else{$tmp=0;}
	printf $fhout "$sep%5.1f",$tmp;
	
	foreach $kwd2("nT","nF","ncT","ncF"){
	    if (defined $res{"$kwd2"."$kwd","$dist"}){
		$tmp=$res{"$kwd2"."$kwd","$dist"};}
	    else {$tmp=0;}
	    print $fhout "$sep",$tmp;}
	print $fhout "\n";
    } close($fhout);}
print "--- output in $fileOut\n";
exit;
