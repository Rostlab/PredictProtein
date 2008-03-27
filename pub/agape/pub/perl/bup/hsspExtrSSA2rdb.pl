#!/usr/sbin/perl -w
# 
# take list of hssp files (/data/hssp/1col.hssp_A
# extract seq and sec and acc into RDB
#
$[ =1 ;

push (@INC, "/home/rost/perl") ;
# require "ctime.pl";		# require "rs_ut.pl" ; 
require "lib-ut.pl"; require "lib-br.pl";
# require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";

#$ARGV[1]="xtmp.list";	#x.x
$par{"dirHssp"}=    "/data/hssp/";
$par{"extHssp"}=    ".hssp";
#$par{"nPerLine"}=   50;		# number of residues per row
#$par{"inclAcc"}=    100;	# include residues with rel Acc < this
#$par{"inclAccMode"}=">";	# (<=,<,>,>= mode of inclusion)

#$formatName="%-6s";
#$formatDes= "%-3s";

if ($#ARGV<1){
	print"goal:   extract seq, sec, and acc (and rel acc) into RDB\n";
	print"usage:  'script file_list_hssp' (1col.hssp_A, or: 1colA,1ppt, or: *hssp)\n";
	print"option: dirHssp=x\n";
	print"option: many (each will give one HSSP file, default: one big!)\n";
#	print"option: inclAcc=n inclAccMode=< (incl relative acc <n)\n";
	exit;}

$fileIn=$ARGV[1];@fileIn=("$fileIn");
$fhin="FHIN";$fhinHssp="FHIN_HSSP";$fhout="FHOUT";
$fileOut=$fileIn; 
$fileOut="OUT-"."$fileIn";$fileOut=~s/^.*\/|\..*$//g;$fileOut.=".rdb";
				# ------------------------------
$Lmany=0;			# command line options
foreach $arg(@ARGV){
    next if ($arg eq $ARGV[1]);
    if    ($arg =~ /^dirHssp=(.+)/)    {$par{"dirHssp"}=$1;}
    elsif ($arg eq  "many")            {$Lmany=1;}
#    elsif ($arg =~ /^inclAcc=(.+)/)    {$par{"inclAcc"}=$1;}
#    elsif ($arg =~ /^inclAccMode=(.+)/){$par{"inclAccMode"}=$1;}
    elsif (-e $arg)                    {push(@fileIn,$arg);}
    else  {print "*** option $arg not digested\n";
	   die;}}
				# ------------------------------
				# file or list of files?
if (($#fileIn==1) && &is_hssp_list($fileIn)){
    print "--- reading $fileIn (claimed to be list of HSSP files)\n";
    &open_file("$fhin", "$fileIn");$#fileIn=0;
    while (<$fhin>) {$_=~s/\n|\s//g;
		     $chain=$_; $chain=~s/^.*\.hssp//g;$chain=~s/^.*_(\w)$/$1/g; 
		     $file=$_;$file=~s/_\w$//g;
		     if (! -e $file && ($file !~ /^\//)){
			 $file=$par{"dirHssp"}.$file;}
		     if (! -e $file){print"-*- missing '$file'\n";
				     next;}
		     if (length($chain)>0){$file.="_$chain";}
		     push(@fileIn,$file);}close($fhin);}
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

elsif ($#fileIn==1) {
    if (! -e $fileIn && ($file !~ /^\//)){
	$fileIn=$par{"dirHssp"}.$fileIn;}
    if (! -e $fileIn){print"-*- missing '$fileIn'\n";
		      die;}
    push(@fileIn,$fileIn);}
else {
    print "*** ERROR $0 no condition true to start with\n";
    exit;}
				# ------------------------------
				# read list of files
if (! $Lmany){
    &rdbWrtHdrHere;}
&exposure_normalise_prepare;	# initialise the normalisation of accessibility

foreach $fileIn (@fileIn){
    $chain=$fileIn; $chain=~s/^.*\.hssp//g;$chain=~s/^.*_(\w)$/$1/g; 
    $file=$fileIn;$file=~s/_\w$//g;$id=$file;$id=~s/^.*\///g;$id=~s/\.hssp.*$//g;
    ++$ct;
    if (length($chain)<1){$Lchain=0;}else{$Lchain=1;}
    if (! -e $file){$file=$par{"dirHssp"}.$file;}
    if (! -e $file){print "*** no hssp '$file'\n";
		    next;}
    if ($Lmany){$fileOut=$id.".rdb";
		$fileOut=~s/$id/$id$chain/ if $Lchain;
		&rdbWrtHdrHere;}
				# ------------------------------
				# read HSSP file
    print"--- reading '$file' ";if($Lchain){print" chain=$chain, ";}print"\n";
    if ( ! defined $chain || length($chain)==0 || $chain eq " "){
	$chainTmp="*";}
    else {$chainTmp=$chain;}

    &open_file("$fhinHssp", "$file");
    $fileRd[$ct]=$file; if ($Lchain){$fileRd[$ct].="_"."$chain";}
    while (<$fhinHssp>) { last if ($_=~/^ SeqNo/);
			  if ($_=~/^NALIGN\s+(\d+)/)   {$nali=$1;next;}
			  if ($_=~/^SEQLENGTH\s+(\d+)/){$len=$1;next;}}
    while (<$fhinHssp>) { 
	last if (/^\#\#/);
	next if ($Lchain && (substr($_,13,1) ne $chain));
				# filter accessibility
	$seq=substr($_,15,1);if ($seq eq " "){$seq="X";} elsif ($seq =~/[a-z]/){$seq="C";}
	$sec=&convert_sec(substr($_,18,1));
	$acc=substr($_,36,4);$acc=~s/\s//g;$aa= substr($_,15,1);
	$relAcc=&convert_acc($aa,$acc);
	&rdbWrtLineHere;
    }close($fhinHssp);
    close($fhout) if ($Lmany);
}
close($fhout) if (! $Lmany);

if (-e $fileOut){print "--- output in $fileOut\n";}
exit;

#===============================================================================
sub rdbWrtHdrHere {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   rdbWrtHdr                       
#-------------------------------------------------------------------------------
    &open_file("$fhout", ">$fileOut");
    print $fhout "\# Perl-RDB\n","\# Extract from HSSP file(s)\n";
    print $fhout 
	"id","\t","chain","\t","len","\t","nali","\t",
	"seq","\t","sec","\t","acc","\t","rel","\n";
}				# end of rdbWrtHdrHere

#===============================================================================
sub rdbWrtLineHere {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   rdbWrtLine                       
#-------------------------------------------------------------------------------
    printf $fhout 
	"%-s\t%-1s\t%4d\t%4d\t%1s\t%1s\t%4d\t%4d\n",
	$id,$chainTmp,$len,$nali,$seq,$sec,$acc,int($relAcc);
}				# end of rdbWrtLineHere

