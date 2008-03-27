#!/usr/sbin/perl -w
# 
# take list of hssp files (/data/hssp/1col.hssp_A
# extract secondary structure pattern HEEHEE
# and count
#
$[ =1 ;

push (@INC, "/home/rost/perl") ;
require "ctime.pl";		# require "rs_ut.pl" ;
require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";

#$ARGV[1]="xtmp.list";	#x.x

if ($#ARGV<1){
	print"goal:   extract secondary structure pattern (HEEHEE) from HSSP\n";
	print"usage:  'script file_list_hssp' (1col.hssp_A)\n";
	print"option: \@pattern (will generate statistics on that)\n";
	exit;}

$fileIn=$ARGV[1];
$fhin="FHIN";$fhinHssp="FHIN_HSSP";$fhout="FHOUT";
$fileOutFull=$fileOutStat=$fileIn; 
$fileOutFull="Full-"."$fileIn";$fileOutFull=~s/^.*\/|\..*$//g;$fileOutFull.=".txt";
$fileOutStat="Stat-"."$fileIn";$fileOutStat=~s/^.*\/|\..*$//g;$fileOutStat.=".txt";

@pattern=("HH","HEEHEE","HEEHEEHEEHEE");

				# ------------------------------
				# read list of files
&open_file("$fhin", "$fileIn");
$ct=$ctNot=$ctTurn=$ctRes=0;
while (<$fhin>) {
    $_=~s/\n|\s//g;
    $chain=$_; $chain=~s/^.*\.hssp//g;$chain=~s/^.*_(\w)$/$1/g; 
    $file=$_;$file=~s/_\w$//g;
    if (! -e $file){print"-*- missing '$file'\n";
		    ++$ctNot;
		    next;}
    ++$ct;
    if (length($chain)<1){$Lchain=0;}else{$Lchain=1;}
				# ------------------------------
				# read HSSP file
    print"--- reading '$file' ";if($Lchain){print" chain=$chain, ";}print"\n";
    &open_file("$fhinHssp", "$file");
    $fileRd[$ct]=$file; if ($Lchain){$fileRd[$ct].="_"."$chain";}
    while (<$fhinHssp>) { last if (/^ SeqNo/);}
    $sec="";
    while (<$fhinHssp>) { 
	if ($Lchain){$chainRd=substr($_,13,1);
		     if ($chainRd ne $chain){
			 last;}}
	$sec.=substr($_,18,1);
	last if (/^\#\#/);}close($fhinHssp);
				# count loops
    $turn=$sec;$turn=~s/[^T]//g;
#    print"x.x turn=$turn,\n";
    $ctTurn+=length($turn);
    $ctRes+=length($sec);
				# change sec str to 3 states
    $sec=~s/[ST ]/L/g;$sec=~s/B/E/g;$sec=~s/G/H/g;
    $rd[$ct]=$sec;}close($fhin);

				# ------------------------------
				# change to patterns
foreach $it (1..$#rd){$sec[$it]=$rd[$it];
				# segment to one symbol
		      $sec[$it]=~s/H+/H/g;$sec[$it]=~s/E+/E/g;$sec[$it]=~s/L+/L/g;
				# delete 'L'
		      $sec[$it]=~s/L//g; }
				# ------------------------------
				# compile statistics
foreach $pattern(@pattern){$res{"$pattern"}=$res{"$pattern","prot"}=0;}

foreach $pattern(@pattern){
    foreach $it (1..$#sec){
	$sec=$sec[$it];$sec=~s/$pattern/X/g;$sec=~s/[^X]//g;
	if (length($sec)>0){
	    print "x.x found for $it=$sec[$it], n=",length($sec),",\n";
	    ++$res{"$pattern","prot"};}
	$res{"$pattern"}+=length($sec);}}

@fh=("$fhout","STDOUT");
				# ------------------------------
				# write output file of full data read
foreach $fh(@fh){ if ($fh ne "STDOUT"){&open_file("$fh", ">$fileOutFull");}
		  &wrtFull($fh);
		  if ($fh ne "STDOUT"){close($fh);}}
		     
				# ------------------------------
				# write number of patterns
foreach $fh(@fh){ if ($fh ne "STDOUT"){&open_file("$fh", ">$fileOutStat");}
		  &wrtStat($fh);
		  if ($fh ne "STDOUT"){close($fh);}}

print "--- output in $fileOutFull,$fileOutStat\n";
exit;


# ==================================================
# write output file of full data read
# ==================================================
sub wrtFull {
    local($fhLoc)=@_;
    foreach $it (1..$#rd){
	printf $fhLoc "%-30s %-s\n",$fileRd[$it],$sec[$it];}
    print $fhLoc "Nfiles read    =$#fileRd\n";
    print $fhLoc "Nfiles missing =$ctNot\n";
    print $fhLoc "Nturns         =$ctTurn\n";
    print $fhLoc "Nresidues      =$ctRes\n";
}
# ==================================================
# write number of patterns
# ==================================================
sub wrtStat {
    local($fhLoc)=@_;
    printf $fhLoc "%-25s %6s %6s\n","pattern","nOcc","nProt";
    foreach $pattern(@pattern){
	printf $fhLoc "%-25s %6d %6d\n",$pattern,$res{"$pattern"},$res{"$pattern","prot"};}
}

