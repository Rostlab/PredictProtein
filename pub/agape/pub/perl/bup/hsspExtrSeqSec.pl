#!/usr/sbin/perl -w
# 
# take list of hssp files (/data/hssp/1col.hssp_A
# extract seq and sec str into rows of 100
#
$[ =1 ;

push (@INC, "/home/rost/perl") ;
require "lib-ut.pl"; require "lib-br.pl";

#$ARGV[1]="xtmp.list";	#x.x
$par{"dirHssp"}=    "/home/rost/data/hssp/";
$par{"extHssp"}=    ".hssp";
$par{"nPerLine"}=   50;		# number of residues per row
$par{"inclAcc"}=    100;	# include residues with rel Acc < this
$par{"inclAccMode"}=">";	# (<=,<,>,>= mode of inclusion)
$par{"doStat"}=     0;		# compile per residue/ per sec str statistics

$formatName="%-6s";
$formatDes= "%-3s";

if ($#ARGV<1){
	print "goal:   extract seq and sec str into rows of 50\n";
	print "use:    'script file_list_hssp' (1col.hssp_A, or: 1colA,1ppt, or: *hssp)\n";
	print "opt:    nPerLine=50, dirHssp=x\n";
	print "        inclAcc=x     \n";
	print "        inclAccMode=< (incl relative acc <n)\n";
	print "        stat          (do statistics)\n";
	print "        fileOut=x\n";
	exit;}

$fileIn=$ARGV[1];@fileIn=("$fileIn");
$fhin="FHIN";$fhinHssp="FHIN_HSSP";$fhout="FHOUT";
$fileOut=$fileIn; 
$fileOut="OUT-"."$fileIn";$fileOut=~s/^.*\/|\..*$//g;$fileOut.=".txt";
				# ------------------------------
				# command line options
foreach $arg(@ARGV){
    next if ($arg eq $ARGV[1]);
    if    ($arg =~ /^dirHssp=(.+)/)    {$par{"dirHssp"}=    $1;}
    elsif ($arg =~ /^nPerLine=(.+)/)   {$par{"nPerLine"}=   $1;}
    elsif ($arg =~ /^inclAcc=(.+)/)    {$par{"inclAcc"}=    $1;}
    elsif ($arg =~ /^inclAccMode=(.+)/){$par{"inclAccMode"}=$1;}
    elsif ($arg =~ /^fileOut=(.+)/)    {$fileOut=           $1;}
    elsif ($arg =~ /^stat$/)           {$par{"doStat"}=     1;}
    elsif (-e $arg)                    {push(@fileIn,$arg);}
    else  {print "*** option $arg not digested\n";
	   die;}}
$#resId=$#resSeq=$#resSec=0;
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
foreach $fileIn (@fileIn){
    $chain=$fileIn; $chain=~s/^.*\.hssp//g;$chain=~s/^.*_(\w)$/$1/g; 
    $file=$fileIn;$file=~s/_\w$//g;$id=$file;$id=~s/^.*\///g;$id=~s/\.hssp.*$//g;
    ++$ct;
    if (length($chain)<1){$Lchain=0;}else{$Lchain=1;}
    if (! -e $file){$file=$par{"dirHssp"}.$file;}
    if (! -e $file){print "*** no hssp '$file'\n";
		    next;}
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
	$id.="$chain"            if ($Lchain);
	push(@resId,$id);push(@resSeq,$seq);push(@resSec,$sec);}
}
				# --------------------------------------------------
				# write output
@fh=("$fhout","STDOUT");
foreach $fh (@fh){
    &open_file("$fh", ">$fileOut") if ($fh ne "STDOUT");
    foreach $it (1..$#resId){
	printf $fh "$formatName $formatDes %6d\n",$resId[$it],"LEN",length($resSeq[$it]);
	for ($itRes=1;$itRes<=length($resSeq[$it]);$itRes+=$par{"nPerLine"}){
				# get substrings
	    $points=&myprt_npoints($par{"nPerLine"},$itRes);
	    $seq=substr($resSeq[$it],$itRes,$par{"nPerLine"});
	    $sec=substr($resSec[$it],$itRes,$par{"nPerLine"});
				# write
	    printf $fh "$formatName $formatDes %-s\n",$resId[$it]," ",$points;
	    printf $fh "$formatName $formatDes %-s\n",$resId[$it],"SEQ",$seq;
	    printf $fh "$formatName $formatDes %-s\n",$resId[$it],"SEC",$sec;}}
    if ($fh ne "STDOUT"){close($fh);}}
				# ------------------------------
				# do per residue statistics
if ($par{"doStat"}){
    foreach $it (1..$#resId){
	$seq=$resSeq[$it];
	$seq=~s/[a-z]/C/g;
	($Lok,$msg,$sec)=
	    &convert_secFine($resSec[$it],"HELT");
	if (! $Lok){
	    print "*** $0 failed to convert_secFine on it=$it, sec=$resSec[$it],\n",$msg,"\n";
	    die;}
	@seq=split(//,$seq);
	@sec=split(//,$sec);
	foreach $mue (1..$#seq) {
	    if (! defined $ct{"seq","$seq[$mue]"}){push(@aa, $seq[$mue]);
						   $ct{"seq","$seq[$mue]"}=0;}
	    if (! defined $ct{"sec","$sec[$mue]"}){push(@ss, $sec[$mue]);
						   $ct{"sec","$sec[$mue]"}=0;}
	    $ct{"$seq[$mue]","$sec[$mue]"}=0     if (! defined $ct{"$seq[$mue]","$sec[$mue]"});
	    ++$ct{"seq","$seq[$mue]"};
	    ++$ct{"sec","$sec[$mue]"};
	    ++$ct{"$seq[$mue]","$sec[$mue]"}; }}
    $sumSeq=0;
    foreach $aa (@aa){
	$sumSeq+=$ct{"seq",$aa};}
    $sumSec=0;
    foreach $ss (@ss){
	$sumSec+=$ct{"sec",$ss};}
    @ss=("H","E","T","L");
    $#tmp=$#tmp2=0;
    foreach $aa (@aa){
	if ($aa=~/[ACDEFGHIKLMNPQRSTVWY]/){
	    $tmp{$aa}=1;}
	else {
	    push(@tmp2,$aa);} }

    @aa2=split(//,"VLIMFWYGAPSTCHRKQEND");
    foreach $aa (@aa2) {
	next if (! defined $tmp{$aa});
	push(@tmp,$aa); }
    $#aa=0;
    push(@aa,@tmp2,@tmp);
				# --------------------------------------------------
				# compile log odds
				# simple Fano info (fano)
				# I (S;R) = log [ ( f(S,R) / f(R) ) / (f(S) / N) ]
				# 
				# where f= counts, S=state, R=residue, N=total count
				# 
				# info difference (robson)
				# I (DelS;R)=I(S;R)-I(!S;R)= 
				#       log [ f(S,R)/f(!S,R) ] + log [ f(!S)/f(S) ]
				# --------------------------------------------------
    $ct{"R"}=join(',',@aa);
    $ct{"S"}=join(',',@ss);
    $sep=" ";
    $Lnum=$Lperc=$Lfano=$Lrobson=$Lbayes=1;

    ($Lok,$msg,$tmpWrt)=
	&stat2DarrayWrt($sep,$Lnum,$Lperc,$Lfano,$Lrobson,$Lbayes,%ct);
				# ------------------------------
				# screen
    print "--- ","-" x 60,"\n";
    print "--- statistics:\n";
    print $tmpWrt;
    print "--- \n";
    print "--- sumSeq=$sumSeq, sumSec=$sumSec\n";
				# ------------------------------
				# file

    $fileOut2="stat-".$fileOut;
    &open_file("$fhout", ">$fileOut2");
    print $fhout $tmpWrt; 
    close($fhout);
}

print "--- output     in $fileOut\n"  if (-e $fileOut);
print "--- statistics in $fileOut2\n" if (defined $fileOut2 && -e $fileOut2);

exit;

