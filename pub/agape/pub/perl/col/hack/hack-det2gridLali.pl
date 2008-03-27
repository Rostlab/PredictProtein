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
# expected header
# id1T,id2T,pideT,psimT,laliT,ngapT,lgapT,len1T,len2T,energyT,zscoreT,doldT,dIdeT,dSimT,
#   1    2    3     4     5     6     7     8     9      10     11      12    13    14
				# --------------------------------------------------
				# (1) read files
$#zsco=$#ener=$#pide=$#psim=0;
undef %zsco; undef %ener; undef %pide;undef %psim;
foreach $fileIn (@fileIn){
    &open_file("$fhin", "$fileIn"); print "--- reading $fileIn";
    if ($fileIn =~/detT/){$Ltrue=1;$txt="T";}else{$Ltrue=0;$txt="F";} 
    if ($Ltrue){print " is true?\n";}else{print " is false? (DO NOT mix!)\n";}
    while (<$fhin>) {
	undef %tmp;
	$_=~s/\n//g;$_=~s/\t$//g;
	next if (/^id/);@tmp=split(/[\t\s]+/,$_);
	next if ($tmp[5]< $laliMin); # leave out too short stretches
	$pide=$tmp{"pide"}=&fRound($tmp[3]); 
	$psim=$tmp{"psim"}=&fRound($tmp[4]);
	$ener=$tmp{"ener"}=&fRound($tmp[10]);
	$zsco=$tmp{"zsco"}=(int(10*$tmp[11]))/10; 
	$lali=int($gridLali*$tmp[5])/$gridLali;
	if (! defined $ener{"$ener"}){$ener{"$ener"}=1;push(@ener,$ener);}
	if (! defined $zsco{"$zsco"}){$zsco{"$zsco"}=1;push(@zsco,$zsco);}
	if (! defined $zsco{"$pide"}){$pide{"$pide"}=1;push(@pide,$pide);}
	if (! defined $zsco{"$psim"}){$psim{"$psim"}=1;push(@psim,$psim);}
	
	foreach $kwd(@kwdP,@kwdE,@kwdZ){
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
@sortEner=sort bynumber_high2low(@ener);
@sortZsco=sort bynumber_high2low(@zsco);
				# ------------------------------
foreach $kwd(@kwdP){		# percentage stuff
    $sum{"$kwd"}=0;}
foreach $dist (1..200){		# total sum true
    $dist=100-$dist+1;
    foreach $kwd(@kwdP){if (defined $res{"nT"."$kwd","$dist"}){
	$sum{"$kwd"}+=$res{"nT"."$kwd","$dist"};
#	if ($kwd =~ /^d/){print "d=$dist, r=",$res{"nT"."$kwd","$dist"},", s=",$sum{"$kwd"},",\n";}
    }}}
foreach $kwd(@kwdP){print "xx sum for $kwd=",$sum{"$kwd"},"\n";} # xx

foreach $kwd(@kwdP){		# cumulative 
    $cumT{"$kwd"}=$cumF{"$kwd"}=0;}
foreach $dist (1..200){
    $dist=100-$dist+1;
    foreach $kwd(@kwdP){
	if (defined $res{"nT"."$kwd","$dist"}){$cumT{"$kwd"}+=$res{"nT"."$kwd","$dist"};}
	if (defined $res{"nF"."$kwd","$dist"}){$cumF{"$kwd"}+=$res{"nF"."$kwd","$dist"};}
	$res{"ncT"."$kwd","$dist"}=$cumT{"$kwd"};
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
				# --------------------------------------------------
				# (3) write output
$sep="\t";
if (defined $title){$fileOut="hisP-".$title.".dat";}else{$fileOut="hisP-max.dat";}
&open_file("$fhout",">$fileOut"); 
print $fhout "Di,s|i,s","$sep";
foreach $kwd(@kwdP){
    foreach $kwd2("PcT=ncT/nc","PcF=ncF/nc","PaT=ncT/allT","%T=nT/nF"){
	print $fhout $kwd2.$kwd,"$sep";}}
foreach $kwd(@kwdP){
    foreach $kwd2("nT","nF","ncT","ncF"){
	print $fhout $kwd2.$kwd,"$sep";}}print $fhout "\n";

foreach $dist (0..125){
    $dist=100-$dist;$tmp=0;
    foreach $kwd(@kwdP){
	foreach $kwd2("nT","nF"){
	if (defined $res{"$kwd2"."$kwd","$dist"}){$tmp+=$res{"$kwd2"."$kwd","$dist"};}}}
    next if ($tmp<1);
    printf $fhout "%6d",$dist;
    foreach $kwd(@kwdP){
	if (! defined $res{"nT"."$kwd","$dist"}){
	    $nT=$cumT=0;}
	else {$cumT=$res{"ncT"."$kwd","$dist"};$nT=$res{"nT"."$kwd","$dist"};}    
	if (! defined $res{"nF"."$kwd","$dist"}){
	    $nF=$cumF=0;}
	else {$cumF=$res{"ncF"."$kwd","$dist"};$nF=$res{"nF"."$kwd","$dist"};}
	if (($cumT+$cumF)>0){
	    printf $fhout 
		"$sep%5.1f$sep%5.1f$sep%5.1f$sep%5.1f",
		100*($cumT/($cumT+$cumF)),100*($cumF/($cumT+$cumF)),100*($cumT/$sum{"$kwd"});}
	else {printf $fhout 
		  "$sep%5.1f$sep%5.1f$sep%5.1f$sep%5.1f",0,0,100*($cumT/$sum{"$kwd"});}
	if(($nT+$nF)>0){$tmp=100*($nT/($nT+$nF));}else{$tmp=0;}
	printf $fhout "$sep%5.1f",$tmp;}
    foreach $kwd(@kwdP){
	foreach $kwd2("nT","nF","ncT","ncF"){
	    if (defined $res{"$kwd2"."$kwd","$dist"}){
		$tmp=$res{"$kwd2"."$kwd","$dist"};}
	    else {$tmp=0;}
	    printf $fhout "%6d$sep",$tmp;}}
    print $fhout "\n";
} close($fhout);
				# ------------------------------
				# energy
if (defined $title){$fileOut="hisE-".$title.".dat";}else{$fileOut="hisE-max.dat";}
&open_file("$fhout",">$fileOut"); 
$kwd="ener";
print $fhout "energy","$sep";
foreach $kwd2("PcT=ncT/nc","PcF=ncF/nc","PaT=ncT/allT","%T=nT/nF"){
    print $fhout $kwd2.$kwd,"$sep";}
foreach $kwd2("nT","nF","ncT","ncF"){printf $fhout $kwd2.$kwd,"$sep";}print $fhout "\n";

foreach $dist (@sortEner){
    $tmp=0;
    foreach $kwd2("nT","nF"){
	if (defined $res{"$kwd2"."$kwd","$dist"}){$tmp+=$res{"$kwd2"."$kwd","$dist"};}}
    next if ($tmp<1);

    if (! defined $res{"nT"."$kwd","$dist"}){
	$nT=$cumT=0;}
    else {$cumT=$res{"ncT"."$kwd","$dist"};$nT=$res{"nT"."$kwd","$dist"};}    
    if (! defined $res{"nF"."$kwd","$dist"}){
	$nF=$cumF=0;}
    else {$cumF=$res{"ncF"."$kwd","$dist"};$nF=$res{"nF"."$kwd","$dist"};}
    next if (($cumF+$cumT)<1);

    printf $fhout "%6.1f",$dist;
    printf $fhout 
	"$sep%5.1f$sep%5.1f$sep%5.1f$sep%5.1f",
	100*($cumT/($cumT+$cumF)),100*($cumF/($cumT+$cumF)),100*($cumT/$sum{"$kwd"});
    if(($nT+$nF)>0){$tmp=100*($nT/($nT+$nF));}else{$tmp=0;}
    printf $fhout "$sep%5.1f",$tmp;
    
    foreach $kwd2("nT","nF","ncT","ncF"){
	if (defined $res{"$kwd2"."$kwd","$dist"}){
	    $tmp=$res{"$kwd2"."$kwd","$dist"};}
	else {$tmp=0;}
	printf $fhout "%6d$sep",$tmp;}
    print $fhout "\n";
} close($fhout);
				# ------------------------------
				# zscore
if (defined $title){$fileOut="hisZ-".$title.".dat";}else{$fileOut="hisZ-max.dat";}
&open_file("$fhout",">$fileOut"); 
$kwd="zsco";
print $fhout "zscore","$sep";
foreach $kwd2("PcT=ncT/nc","PcF=ncF/nc","PaT=ncT/allT","%T=nT/nF"){
    print $fhout $kwd2.$kwd,"$sep";}
foreach $kwd2("nT","nF","ncT","ncF"){printf $fhout $kwd2.$kwd,"$sep";}print $fhout "\n";

foreach $dist (@sortZsco){
    $tmp=0;
    foreach $kwd2("nT","nF"){
	if (defined $res{"$kwd2"."$kwd","$dist"}){$tmp+=$res{"$kwd2"."$kwd","$dist"};}}
    next if ($tmp<1);

    if (! defined $res{"nT"."$kwd","$dist"}){
	$nT=$cumT=0;}
    else {$cumT=$res{"ncT"."$kwd","$dist"};$nT=$res{"nT"."$kwd","$dist"};}    
    if (! defined $res{"nF"."$kwd","$dist"}){
	$nF=$cumF=0;}
    else {$cumF=$res{"ncF"."$kwd","$dist"};$nF=$res{"nF"."$kwd","$dist"};}
    next if (($cumF+$cumT)<1);

    printf $fhout "%6.2f",$dist;
    printf $fhout 
	"$sep%5.1f$sep%5.1f$sep%5.1f$sep%5.1f",
	100*($cumT/($cumT+$cumF)),100*($cumF/($cumT+$cumF)),100*($cumT/$sum{"$kwd"});
    if(($nT+$nF)>0){$tmp=100*($nT/($nT+$nF));}else{$tmp=0;}
    printf $fhout "$sep%5.1f",$tmp;
    
    foreach $kwd2("nT","nF","ncT","ncF"){
	if (defined $res{"$kwd2"."$kwd","$dist"}){
	    $tmp=$res{"$kwd2"."$kwd","$dist"};}
	else {$tmp=0;}
	printf $fhout "%6d$sep",$tmp;}
    print $fhout "\n";
} close($fhout);
exit;
print "--- output in $fileOut\n";
exit;
