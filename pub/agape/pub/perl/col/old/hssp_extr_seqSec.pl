#!/usr/bin/perl -w
##!/usr/sbin/perl -w
# 
# take list of hssp files (/data/hssp/1col.hssp_A
# extract seq and sec str into rows of 100
#
$[ =1 ;

push (@INC, "/home/rost/perl") ;
# require "ctime.pl";		# require "rs_ut.pl" ; 
require "lib-ut.pl"; require "lib-br.pl";
# require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";

#$ARGV[1]="xtmp.list";	#x.x
$par{"dirHssp"}=    "/data/hssp/";
$par{"extHssp"}=    ".hssp";
$par{"nPerLine"}=   50;		# number of residues per row
$par{"inclAcc"}=    100;	# include residues with rel Acc < this
$par{"inclAccMode"}=">";	# (<=,<,>,>= mode of inclusion)

$formatName="%-6s";
$formatDes= "%-3s";

if ($#ARGV<1){
	print"goal:   extract seq and sec str into rows of 50\n";
	print"usage:  'script file_list_hssp' (1col.hssp_A, or: 1colA,1ppt)\n";
	print"option: nPerLine=50, dirHssp=x\n";
	print"option: inclAcc=n inclAccMode=< (incl relative acc <n)\n";
	exit;}

$fileIn=$ARGV[1];
$fhin="FHIN";$fhinHssp="FHIN_HSSP";$fhout="FHOUT";
$fileOut=$fileIn; 
$fileOut="OUT-"."$fileIn";$fileOut=~s/^.*\/|\..*$//g;$fileOut.=".txt";
				# ------------------------------
				# command line options
foreach $arg(@ARGV){
    next if ($arg eq $ARGV[1]);
    if    ($arg =~ /^dirHssp=(.+)/) {$par{"dirHssp"}=$1;}
    elsif ($arg =~ /^nPerLine=(.+)/){$par{"nPerLine"}=$1;}
    elsif ($arg =~ /^inclAcc=(.+)/)    {$par{"inclAcc"}=$1;}
    elsif ($arg =~ /^inclAccMode=(.+)/){$par{"inclAccMode"}=$1;}
    else  {print "*** option $arg not digested\n";
	   die;}}
				# ------------------------------
				# file or list of files?
$#fileIn=$#resId=$#resSeq=$#resSec=0;
if (&is_hssp_list($fileIn)){
    &open_file("$fhin", "$fileIn");
    while (<$fhin>) {$_=~s/\n|\s//g;
		     $chain=$_; $chain=~s/^.*\.hssp//g;$chain=~s/^.*_(\w)$/$1/g; 
		     $file=$_;$file=~s/_\w$//g;
		     if (! -e $file && ($file !~ /^\//)){
			 $file=$par{"dirHssp"}.$file;}
		     if (! -e $file){print"-*- missing '$file'\n";
#				     ++$ctNot;
				     next;}
		     if (length($chain)>0){$file.="_$chain";}
		     push(@fileIn,$file);}
    close($fhin);}
elsif($fileIn=~/,/) {		# get list from comma delimited list
    $fileOut="OUT-extrSeqSec-".$$.".tmp";
    $#tmp=0;$fileIn=~s/^,*|,*$//g;@tmp=split(/,/,$fileIn);
    foreach $tmp (@tmp){
	$Lok=0;
	if ((length($tmp)>5)||(length($tmp)<4)){
	    print "*** to use the option '1pdbC,2dbxA' only pdb ids'(+chain)\n";
	    die;}
	if (length($tmp)==5){
	    $id=substr($tmp,1,4);$chain=substr($tmp,5,1);}
	else {
	    $id=$tmp;$chain="";}
	$file=$id.$par{"extHssp"};
	if (-e $file){
	    if (length($chain)>0){$file.="_".$chain;}
	    push(@fileIn,$file);$Lok=1;}
	next if ($Lok);
	if ($file !~/^\//){$file=$par{"dirHssp"}.$file;}
	if (-e $file){
	    if (length($chain)>0){$file.="_".$chain;}
	    push(@fileIn,$file);$Lok=1;}
	next if ($Lok);
	print "*-* missing hssp '$file'\n";}}
else {
    if (! -e $fileIn && ($file !~ /^\//)){
	$fileIn=$par{"dirHssp"}.$fileIn;}
    if (! -e $fileIn){print"-*- missing '$fileIn'\n";
		      die;}
    push(@fileIn,$fileIn);}
				# ------------------------------
				# read list of files
foreach $fileIn (@fileIn){
    $chain=$fileIn; $chain=~s/^.*\.hssp//g;$chain=~s/^.*_(\w)$/$1/g; 
    $file=$fileIn;$file=~s/_\w$//g;$id=$file;$id=~s/^.*\///g;$id=~s/\.hssp.*$//g;
    ++$ct;
    if (length($chain)<1){$Lchain=0;}else{$Lchain=1;}
				# ------------------------------
				# read HSSP file
    print"--- reading '$file' ";if($Lchain){print" chain=$chain, ";}print"\n";
    &open_file("$fhinHssp", "$file");
    $fileRd[$ct]=$file; if ($Lchain){$fileRd[$ct].="_"."$chain";}
    while (<$fhinHssp>) { last if (/^ SeqNo/);}
    $sec=$seq="";
    while (<$fhinHssp>) { 
	if ($Lchain){$chainRd=substr($_,13,1);
		     if ($chainRd ne $chain){
			 last;}}
	last if (/^\#\#/);
				# filter accessibility
	if ($par{"inclAcc"} != 100){
	    $Lincl=0;
	    $acc=substr($_,36,4);$acc=~s/\s//g;$aa= substr($_,15,1);
	    $relAcc=&convert_acc($aa,$acc);
	    if ((($par{"inclAccMode"} eq "<")  && ($relAcc <  $par{"inclAcc"}))||
		(($par{"inclAccMode"} eq "<=") && ($relAcc <= $par{"inclAcc"}))||
		(($par{"inclAccMode"} eq ">")  && ($relAcc >  $par{"inclAcc"}))||
		(($par{"inclAccMode"} eq ">=") && ($relAcc >= $par{"inclAcc"}))){
		$Lincl=1;}}
	else{$Lincl=1;}
	next if (! $Lincl);
	$seq.=substr($_,15,1);
	$sec.=substr($_,18,1);
    }close($fhinHssp);
    if ((length($seq)>0)&&(length($sec)>0)){
	push(@resId,$id);push(@resSeq,$seq);push(@resSec,$sec);}
}
				# --------------------------------------------------
				# write output
@fh=("$fhout","STDOUT");
foreach $fh (@fh){
    if ($fh ne "STDOUT"){&open_file("$fh", ">$fileOut");}	
    foreach $it (1..$#resId){
	printf $fh "$formatName $formatDes %6d\n",$resId[$it],"LEN",length($resSeq[$it]);
	for($itRes=1;$itRes<=length($resSeq[$it]);$itRes+=$par{"nPerLine"}){
				# get substrings
	    $points=&myprt_npoints($par{"nPerLine"},$itRes);
	    $seq=substr($resSeq[$it],$itRes,$par{"nPerLine"});
	    $sec=substr($resSec[$it],$itRes,$par{"nPerLine"});
				# write
	    printf $fh "$formatName $formatDes %-s\n",$resId[$it]," ",$points;
	    printf $fh "$formatName $formatDes %-s\n",$resId[$it],"SEQ",$seq;
	    printf $fh "$formatName $formatDes %-s\n",$resId[$it],"SEC",$sec;}}
    if ($fh ne "STDOUT"){close($fh);}}

if (-e $fileOut){print "--- output in $fileOut\n";}
exit;

