#!/usr/sbin/perl -w
#
#
$[ =1 ;

				# include libraries
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
require "ctime.pl";
require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";

%ptr=  ('nTold', 2,'nFold', 3, 'nTide', 6,'nFide', 7, 
	'nTsim',10,'nFsim',11, 'nTsGi',14,'nFsGi',15);
@mode= ("old","ide","sim","sGi");
@kwd=  ("nT","nF");
				# initialise variables
if ($#ARGV<1){print"goal:   read the files OutDetF/T and add up all values\n";
	      print"usage:  hack-add-his.pl files (as OutHis*, or OutDis)\n";
	      exit;}
$fhin="FHIN";$fhout="FHOUT";

if    ($ARGV[1]=~/.*\/?[dD]is/){$fileOut="hisDis-max.dat";$mode="dist";}
elsif ($ARGV[1]=~/.*\/?[iI]de/){$fileOut="hisIde-max.dat";$mode="pide";}
elsif ($ARGV[1]=~/.*\/?[sS]im/){$fileOut="hisSim-max.dat";$mode="psim";}
else{print"xx for correct mode assignment file has to start with dis|ide|sim\n";
     exit;}
				# ------------------------------
foreach $fileIn (@ARGV){	# read files
    next if (! -e $fileIn);
    &open_file("$fhin", "$fileIn");
    while (<$fhin>) {
	next if (/^dist|^p|^e|^z/); # skip header
	$_=~s/\n//g;$_=~s/^\s+|\s+$//g;
	@tmp=split(/\s+/,$_);foreach $tmp(@tmp){$tmp=~s/\s//g;}
#	&myprt_array(",","xx tmp=",@tmp); exit;
	$dist=$tmp[1];
	foreach $mode(@mode){foreach $kwd (@kwd){
	    $ptr=$ptr{"$kwd"."$mode"};
	    $res{"$kwd"."$mode","$dist"}=$tmp[$ptr];
	}}
    }close($fhin);}
				# ------------------------------
foreach $mode(@mode){		# compile statistics
    $sum{$mode}=0;
    foreach $dis (1..200){	# (1) total sums
	$tmp=0;
	foreach $kwd("nT","nF"){if (defined $res{"$kwd"."$mode","$dist"}){
	    $tmp+=$res{"$kwd"."$mode","$dist"};}}
	$sum{$mode}+=$tmp;}
    print "xx sum for $mode=",$sum{$mode},"\n";
    $cumT=$cumF=0;
    foreach $dis (1..200){	# (2) cumulative values
	if (defined $res{"nT"."$mode","$dist"}){$cumT+=$res{"nT"."$mode","$dist"};}
	if (defined $res{"nF"."$mode","$dist"}){$cumF+=$res{"nF"."$mode","$dist"};}
	$res{"ncT"."$mode","$dist"}=$cumT;
	$res{"ncF"."$mode","$dist"}=$cumF;}}
				# ------------------------------
				# write new 

@mode=("old");			# xx
$sep=",";
&open_file("$fhout", ">$fileOut");
$txt="dist".$sep;
foreach $kwd("PcT=ncT/nc","PcF=ncF/nc","PaT=ncT/allT","%T=nT/nF"){
    foreach $mode(@mode){$txt.="$mode"."$kwd".$sep;}}
foreach $kwd("ncT","ncF","nT","nF"){
    foreach $mode(@mode){$txt.="$kwd"."$mode".$sep;}}
$txt=~s/$sep$//g;
print $fhout "$txt\n";
	
foreach $dis (1..200){
    $dis=100-$dis+1;$tmp=0;
    next if (int($dis/3) != ($dis/3)); # xx
    foreach $mode(@mode){
	$tmp+=$res{"ncT"."$mode","$dist"}+$res{"ncF"."$mode","$dist"};}
    next if (! $tmp);		# ignore empty
    print $fhout "$dis";
    foreach $mode (@mode){
	$cumT=$res{"ncT"."$mode","$dist"};
	$cumF=$res{"ncF"."$mode","$dist"};
	printf $fhout 
	    "$sep%5.1f$sep%5.1f$sep%5.1f$sep%5.1f",
	    100*($cumT/($cumT+$cumF)),100*($cumF/($cumT+$cumF)),100*($cumT/$sum{$mode});
	$nT=$res{"ncT"."$mode","$dist"};
	$nF=$res{"ncF"."$mode","$dist"};
	if(! ($nT+$nF)){$tmp=0;}else{$tmp=100*($nT/($nT+$nF));}
	printf $fhout "$sep%5.1f",$tmp;}
    foreach $mode (@mode){
	foreach $kwd("ncT","ncF","nT","nF"){
#	    if ($kwd eq "nF" && $mode eq $mode[$#mode]){$sepTmp="\n";}else{$sepTmp=$sep;}
	    $sepTmp=$sep;
	    print $fhout "$sepTmp",$res{"$kwd"."$mode","$dist"};}
	print $fhout "\n";
    }
}
print"output in $fileOut\n";

exit;
