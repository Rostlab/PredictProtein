#!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="draws subsets of proteins (seq + acc)\n".
    "     \t length distribution supplied in file";
#  
#
$[ =1 ;
				# ------------------------------
				# include libraries
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
require "ctime.pl";
require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
				# ------------------------------
				# defaults
$minLen=     30;		# minimal length
$maxLen=    200;		# maximal length
#$maxLen=    100;		# maximal length
$minCov=      0.7;		# minimal coverage (i.e. dont pick if lenPick > 0.7 lenProt)
$blowup=       5;		# number of random picks = $blowup * number_observed_from_file
#$blowup=     20;		# number of random picks = $blowup * number_observed_from_file
#$blowup=      2;		# number of random picks = $blowup * number_observed_from_file
#$blowup=      0.05;		# number of random picks = $blowup * number_observed_from_file
#$maxPerProt=  0.1;		# maximally pick $maxPerProt*len samples per protein
$maxPerProt=   0.1;		# maximally pick $maxPerProt*len samples per protein
#$maxPerProt= 10;		# maximally pick $maxPerProt*len samples per protein
$exposed=    16;		# cut-off in relative accessibility
#$exposed=     9;		# cut-off in relative accessibility
$Lrestr2caps=  0;		# restricts random picks to caps
$fracap=       0.3;		# fraction of protein length fragments accepted to be off caps

if ($maxLen<=100){
#    $fit1Ave=-1.0;$fit1Sig=6.9;$fit1Add=0.97;
				# fit2 : 
    $fit2Ave= 0.1;$fit2Sig=6.2;$fit2Add=0.41;$fit2Fac=0.64;
				# fit observed:
    $fitOAve= 0.3;$fitOSig=6.4;$fitOAdd=1.16;
}else{
#    $fit1Ave=-1.3;$fit1Sig=8.2;$fit1Add=1.07;
				# fit2 : 
    $fit2Ave= 1.4;$fit2Sig= 9.9;$fit2Add=0.78;$fit2Fac=0.84;
				# fit observed:
    $fitOAve= 1.1;$fitOSig=10.5;$fitOAdd=1.14;
}
$fhin="FHIN";$fhout="FHOUT";

				# ------------------------------
if ($#ARGV<1){			# help
    print "goal:\t $scrGoal\n";
    print "use: \t '$scrName file-with-histogram files*.rdb \n";
    print " eg: \t '$scrName His-hsspAll.dat \`cat phdSingle.list\`'\n";
    print " or: \t '$scrName His-hsspAll.dat phdSingle.list'\n";
    print "opt: \t restr2caps      \t: restricts random picks to caps\n";
    print "     \t fracap=$fracap  \t: fraction of prot len fragments accepted to be off caps\n";
    print "     \t maxLen=$maxLen  \t: maximal length for picks \n";
    print "     \t minLen=$minLen  \t: minimal length for picks \n";
    print "     \t minCov=$minCov  \t: minimal coverage, no pick if lenPick > 0.7 lenProt\n";
    print "     \t blowup=$blowup  \t: no of random picks = $blowup*no_obs_from_file\n";
    print "     \t maxPerProt=$maxPerProt \t: maximally pick $maxPerProt*len samples per protein\n";
    print "     \t noran           \t: skips the random (stat on real)\n";
    print "     \t \n";
    print "     \t fileOut=x\n";
    print "note:\t for input files \t: NO list accepted at moment'\n";
#    print "     \t \n";
    exit;}
				# ------------------------------
				# read command line
$fileHis=$ARGV[1];
if    ($maxLen<=100){$fileOut="RanDom100.dat";}
elsif ($maxLen<=200){$fileOut="RanDom200.dat";
		     if ($ARGV[2]=~/list/){
			 $tmp=$ARGV[2];$tmp=~s/^.*\///g;$tmp=~s/\.list|\-phd\w*//g;
			 $fileOut="RanDom200".$tmp.".dat";}}
else                {$fileOut="RanDomAll.dat";}

$#fileRdb=$Lnoran=0;
foreach $_(@ARGV){
    next if ($_ eq $ARGV[1]);
    if   ($_=~/^fileOut=(.*)$/)    {$fileOut=$1;}
    elsif($_=~/^maxLen=(.*)$/)     {$maxLen=$1;}
    elsif($_=~/^minLen=(.*)$/)     {$minLen=$1;}
    elsif($_=~/^minCov=(.*)$/)     {$minCov=$1;}
    elsif($_=~/^blowup=(.*)$/)     {$blowup=$1;}
    elsif($_=~/^noran/)            {$Lnoran=1;}
    elsif($_=~/^restr2/)           {$Lrestr2caps=1;}
    elsif($_=~/^fracap=(.*)$/i)    {$fracap=$1;}
    elsif($_=~/^maxPerProt=(.*)$/) {$maxPerProt=$1;}
    elsif(-e $_)                   {push(@fileRdb,$_);}
    else {print"*** wrong command line arg '$_'\n";
	  die;}}
				# ------------------------------
				# error check
if (!-e $fileRdb[1]){print "*** missing input rdb file $fileRdb[1]\n";
		     exit;}
if (!-e $fileHis)   {print "*** missing input rdb file $fileHis\n";
		     exit;}
				# ------------------------------
				# (1) read file with histogram
$#his=$#hisPtr=$#hisMin=$#hisMax=$sumHis=0;
&open_file("$fhin", "$fileHis");
while (<$fhin>) {next if ($_=~/^\#|^[^\d]/); # skip comments, names
		 $_=~s/\n|^\s*|\s*$//g;
		 ($ct,$min,$max,$his)=split(/\t/,$_);
		 print "xx ct=$ct, his=$his,\n";
		 last if ($min > $maxLen);
		 foreach $it ($min..$max){
		     $hisPtr[$it]=$ct;}
		 $hisMin[$ct]=$min;
		 $hisMax[$ct]=$max; $hisMax[$ct]=$maxLen if ($max>$maxLen);
		 $his[$ct]=$his;}close($fhin);
				# ------------------------------
foreach $ct (1..$#his){		# blow up
    $sumHis+=$his;
    $his[$ct]=$blowup * $his[$ct];}

if (0){				# xx
    foreach $len (1..1000){
	next if (! defined $hisPtr[$len]);
	$ctHis=$hisPtr[$len];
	print "xx len=$len, it=$ctHis, his=$his[$ctHis], $hisMin[$ctHis]-$hisMax[$ctHis]\n";}
#    exit;
    print "xx in total sumHis=$sumHis,\n";
}				# xx

				# ------------------------------
$fileRdb=$fileRdb[1];		# (2) PHD list-of-files or *.rdb?
if (0){				# currently not Perl-RDB in header!!!
    if ($#fileRdb==1 && (! &is_rdb($fileRdb))){
	print "xx here(file=$fileRdb)\n";
	&open_file("$fhin", "$fileRdb[1]"); print "--- reading   \t '$fileRdb[1]'\n";
	$#fileRdb=0;
	while (<$fhin>) {next if ($_=~/^\#/); # skip comments, names
			 $_=~s/\s//g;
			 if (-e $_){push(@fileRdb,$_);}}close($fhin);}
}				# end of hack
				# ------------------------------
				# is list of files or single?
if ($#fileRdb==1 && ($fileRdb[1]!~/rdb/)){
    $Lok=&open_file("$fhin", "$fileRdb[1]"); print "--- reading   \t '$fileRdb[1]'\n";
    $#fileRdb=0;
    while (<$fhin>) {$_=~s/\s//g;
		     push(@fileRdb,$_) if (-e $_);}close($fhin);}
				# --------------------------------------------------
undef %rd;$ctFile=0;		# (3) reading all PHD.rdb files
foreach $fileRdb(@fileRdb){	#     ignore if: no accO, too short, purge after chain break
    $Lignore=0;
    $Lok=&open_file("$fhin", "$fileRdb"); print "--- reading   \t '$fileRdb'\n";
    next if (!$Lok);
    ++$ctFile;$ctRes=$ctExp=0;
    $id=$fileRdb;$id=~s/^.*\///g;$id=~s/\..*$//g;$rd{"$ctFile","id"}=$id;
    while (<$fhin>) {
	next if ($_=~/^\#|^No[\s\t]+|^4N/); # skip comments, names
	$_=~s/\n//g;@tmp=split(/\t/,$_);
	next if ($#tmp<5);foreach $tmp(@tmp){$tmp=~s/\s//g;}
	if ($tmp[6] =~/[^0-9]/){
	    print "xx ignore id=$id, file=$fileRdb, as no obs acc\n";
	    $Lignore=1;
	    last;}		# ignore strange cases without obs acc
	last if ($tmp[2] eq "!"); # ignore after chain break
	++$ctRes;
#	$rd{"$ctFile","$ctRes","seq"}=$tmp[2];$rd{"$ctFile","$ctRes","seq"}=~s/\s//g;
	if ($tmp[6] =~/[^0-9]/){$rd{"$ctFile","$ctRes","accP"}=$tmp[4];}
	else                   {$rd{"$ctFile","$ctRes","accO"}=$tmp[5];
				$rd{"$ctFile","$ctRes","accP"}=$tmp[6];}
	++$ctExp if ($rd{"$ctFile","$ctRes","accP"}>$exposed);}close($fhin);
    if ($ctRes<$minLen && ! $Lignore){
	print "xx ignore id=$id, too short (is $ctRes min=$minLen)\n";
	$Lignore=1;
	--$ctFile;
	next;}
    $rd{"$ctFile","len"}=$ctRes;
    $rd{"$ctFile","nexp"}=$ctExp;
    $rd{"$ctFile","Ddom"}=
	($rd{"$ctFile","nexp"} - 
	 &funcNsurfaceFit2($rd{"$ctFile","len"},$fit2Add,$fit2Fac)) - $fit2Ave ;
}
$nprot=$ctFile;
				# ------------------------------
				# (4) prepare no of random picks
$#ranStack=$#ranDone=0;		# will give '1,1,2,2,2,2' if prot 1 is half as long as 2
				# this array used to bias the probability
foreach $it(1..$nprot){
    if ($Lnoran){
	push(@ranStack,$it);
	next;}
    $max=int($rd{"$it","len"}*$maxPerProt);
    $max=1 if ($max<1);
    foreach $tmp(1..$max){
	push(@ranStack,$it);push(@ranDone,0)}}
				# --------------------------------------------------
if ($Lnoran){			# (5a) dont do the random (just analyse real ones)
    foreach $it(1..$nprot){
	$ran{"$it","pos"}=$it;
	$ran{"$it","len"}=$rd{"$it","len"};
	$ran{"$it","beg"}=1;}
    $ranDoneSum=$nprot;}
				# --------------------------------------------------
else {				# (5b) random picks
    $ranDoneSum=0;
    undef %ran;
    foreach $itProt(1..$nprot){
	$maxPick=int($rd{"$itProt","len"}*$maxPerProt);
	$maxPick=int(rand($rd{"$itProt","len"}*$maxPerProt));
	$maxPick=1 if ($maxPick<1);
	foreach $tmp(1..$maxPick){
				# ------------------------------
				# randomly select length of fragment in @his
	    $max=$maxLen;
	    $max=int($minCov*$rd{"$itProt","len"}) if ($minCov*$rd{"$itProt","len"} < $maxLen);
	    next if ($max<$minLen);
	    $lenFrag=&ranSelectLen($max,$rd{"$itProt","len"});
	    next if ($lenFrag == 0) ;
	    die 'lenFrag> max' if ($lenFrag > $max);
				# ------------------------------
				# randomly select begin of fragment
	    $begFrag=&ranSelectBeg($lenFrag,$rd{"$itProt","len"});
	    next if ($begFrag<1);
	    print 
		"xx itPr=$itProt tmp=$tmp, beg=$begFrag, len=$lenFrag, ",
		"maxNow=$max, minCov=$minCov, maxLen=$maxLen, lenOrig=",
		$rd{"$itProt","len"},",\n";
				# now the fragment is defined
	    ++$ranDoneSum;
	    $ran{"$ranDoneSum","pos"}=$itProt;
	    $ran{"$ranDoneSum","len"}=$lenFrag;
	    $ran{"$ranDoneSum","beg"}=$begFrag;
	    die 'beg < 1' if ($begFrag<1);	# end of random pick
	}
    }
}
				# --------------------------------------------------
				# (6) compile statistics
undef %res;			# --------------------------------------------------
$sumOut1sigFit2=$sumOut2sigFit2=$sumOut3sigFit2=
    $sumOut1sigFitO=$sumOut2sigFitO=$sumOut3sigFitO=$sumO=$sumP=0;
$#ok=0;
foreach $it(1..$ranDoneSum){
    $posProt=$ran{"$it","pos"};
    $lenProt=$ran{"$it","len"};
    $begProt=$ran{"$it","beg"};
    next if (! defined $posProt ||  ! defined $lenProt ||  ! defined $begProt);
    if (0){print 
	       "xx $it posProt=$posProt (id=",$rd{"$posProt","id"},
	       "), lenProt=$lenProt (of=",$rd{"$posProt","len"},"), begProt=$begProt\n";
    }
				# get number of exposed residues of fragment
    $nexp=&getSumAcc   ($posProt,$lenProt,$begProt,$exposed);
    $nobs=&getSumAccObs($posProt,$lenProt,$begProt,$exposed);
				# get fit for observed acc in 'real' proteins
    $fit2=&funcNsurfaceFit2($lenProt,$fit2Add,$fit2Fac);$dif2=$nexp-$fit2;
    $fitO=&funcNsurfaceFit1($lenProt,$fitOAdd);         $difO=$nobs-$fitO;

    $out1sigFit2=$out2sigFit2=$out3sigFit2=0;
    $out1sigFit2=1 if (($dif2<($fit2Ave-  $fit2Sig))||($dif2>($fit2Ave+  $fit2Sig)));
    $out2sigFit2=1 if (($dif2<($fit2Ave-2*$fit2Sig))||($dif2>($fit2Ave+2*$fit2Sig)));
    $out3sigFit2=1 if (($dif2<($fit2Ave-3*$fit2Sig))||($dif2>($fit2Ave+3*$fit2Sig)));
    
				# find most globular random fragment
    if (! defined $ok[$posProt]){
	$ok[$posProt]="";}
    $ok[$posProt].="$it,";
				# store results
    $res{"$it","id"}=         $rd{"$posProt","id"};
    $res{"$it","ptr"}=        $posProt;
    $res{"$it","nexp"}=       $nexp;
    $res{"$it","nobs"}=       $nobs;
    $res{"$it","len"}=        $lenProt;
    $res{"$it","fit2"}=       $fit2;
    $res{"$it","fitO"}=       $fitO;
    $res{"$it","dif2"}=       $dif2;
    $res{"$it","out1sigFit2"}=$out1sigFit2;$res{"$it","out2sigFit2"}=$out2sigFit2;
    $res{"$it","out3sigFit2"}=$out3sigFit2;
    $res{"$it","Dran"}=       $dif2-$fit2Ave;

    ++$sumP;
    $sumOut1sigFit2+=$out1sigFit2;$sumOut2sigFit2+=$out2sigFit2;$sumOut3sigFit2+=$out3sigFit2;
    if ($nobs>0){		# observed
	if (! defined $sumO){$sumO=1;}else{++$sumO;}
	$difO=$nobs-$fitO;
	$res{"$it","difO"}=$difO;
	$out1sigFitO=$out2sigFitO=$out3sigFitO=0;
	$out1sigFitO=1 if (($difO<($fitOAve-  $fitOSig))||($difO>($fitOAve+  $fitOSig)));
	$out2sigFitO=1 if (($difO<($fitOAve-2*$fitOSig))||($difO>($fitOAve+2*$fitOSig)));
	$out3sigFitO=1 if (($difO<($fitOAve-3*$fitOSig))||($difO>($fitOAve+3*$fitOSig)));
	$sumOut1sigFitO+=$out1sigFitO;$res{"$it","out1sigFitO"}=$out1sigFitO;
	$sumOut2sigFitO+=$out2sigFitO;$res{"$it","out2sigFitO"}=$out2sigFitO;
	$sumOut3sigFitO+=$out3sigFitO;$res{"$it","out3sigFitO"}=$out3sigFitO;}
}
				# --------------------------------------------------
				# (7) find most globular random fragment
$ctRanWinProt=$ctRanWinTot=0;	# --------------------------------------------------
foreach $it(1..$nprot){
    if ($Lnoran) {$res{"$it","ranWin"}=0;
		  next;}
    next if (! defined $ok[$it]);
    @tmp=split(/,/,$ok[$it]);$LranWin=0;
    foreach $itRan(@tmp){
	if ( &func_absolute($res{"$itRan","Dran"})<&func_absolute($rd{"$it","Ddom"})){
	    $res{"$itRan","ranWin"}=1;$LranWin=1;
	    ++$ctRanWinTot;}
	else {$res{"$itRan","ranWin"}=0;}}
    ++$ctRanWinProt if ($LranWin);}
				# --------------------------------------------------
				# (8) write output sequences and statistics
				# --------------------------------------------------
&open_file("$fhout",">$fileOut"); 
print $fhout "\# Perl-RDB\n# \n","# generated by $scrName\n","# ACCexposed : $exposed\n";
foreach $fh ("STDOUT","$fhout"){
    printf $fh 
	"# fit2 ran better Nprot=%5d (of %5d) perc=%6.1f Ntot=%5d perc=%6.1f\n",
	$ctRanWinProt,$nprot,100*($ctRanWinProt/$nprot),
	$ctRanWinTot,100*($ctRanWinTot/$ranDoneSum);
    printf $fh 
	"# fit2 ave=%5.2f sig=%5.2f f=N-%4.2f * (N^1/3-%4.2f)^3\n",
	$fit2Ave,$fit2Sig,$fit2Fac,$fit2Add;
    printf $fh 
	"# fitO ave=%5.2f sig=%5.2f f=N-(N^1/3-%4.2f)^3\n",$fitOAve,$fitOSig,$fitOAdd;
    printf $fh 
	"# %-10s %-6s %-6s %-6s %-6s %-6s %-6s\n",
	"fit","n1Off","n2Off","n3Off","p1Off","p2Off","p3Off";
    printf $fh
	"# %-10s %6d %6d %6d %6.1f %6.1f %6.1f\n","fit2",
	$sumOut1sigFit2,$sumOut2sigFit2,$sumOut3sigFit2,100*($sumOut1sigFit2/$sumP),
	100*($sumOut2sigFit2/$sumP),100*($sumOut3sigFit2/$sumP);
    printf $fh
	"# %-10s %6d %6d %6d %6.1f %6.1f %6.1f\n","fitO",
	$sumOut1sigFitO,$sumOut2sigFitO,$sumOut3sigFitO,100*($sumOut1sigFitO/$sumO),
	100*($sumOut2sigFitO/$sumO),100*($sumOut3sigFitO/$sumO);
}
printf $fhout 
    "%-s\t%-s\t%-s\t%-s\t%-s\t%-s\t%-s\t%-s\t%-s\t%-s\t%-s\t%-s\t%-s\t%-s\t%-s\n",
    "id","len","n".$exposed."P","n".$exposed."O","nfit2","p-fit2",
#    "nfit1(N-(N^1/3-1.017)^3)","nfit2(N-0.5972*(N^1/3-0.3334)^3)","nfitO",
    "nfitO","o-fitO","ranWin","f2s1","f2s2","f2s3","fOs1","fOs2","fOs3";

foreach $it(1..$ranDoneSum){
    next if (! defined $res{"$it","id"});
    $idTmp=$res{"$it","id"};$idTmp.="_$it" if (! $Lnoran);

    printf $fhout 
	"%-s\t%4d\t%4d\t",$idTmp,$res{"$it","len"},$res{"$it","nexp"};
    if (defined $res{"$it","nobs"}){
	printf $fhout  "%4d\t",$res{"$it","nobs"};}
    else { printf $fhout  "%4s\t"," ";}

    foreach $fh ("STDOUT","$fhout"){
#	if (!defined $res{"$it","difO"}){$difO="";}else{$difO=$res{"$it","difO"};}
	printf $fh
	    "%6.1f\t%6.1f\t%6.1f\t%6.1f\t",
	    $res{"$it","fit2"},$res{"$it","dif2"},$res{"$it","fitO"},$res{"$it","difO"};
	printf $fh
	    "%1d\t%1d\t%1d\t%1d\t%1d\t%1d\t%1d\n",
	    $res{"$it","ranWin"},
	    $res{"$it","out1sigFit2"},$res{"$it","out2sigFit2"},$res{"$it","out3sigFit2"},
	    $res{"$it","out1sigFitO"},$res{"$it","out2sigFitO"},$res{"$it","out3sigFitO"};}
}
close($fhout);

print "--- output in $fileOut\n";
exit;

#===============================================================================
sub funcNsurface {
    local($lenIn) = @_ ;
    local($tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   funcNsurface                length to number of surface molecules
#                               assuming cubes   = N - (N ^ 1/3 - 2) ^ 3
#                               assuming spheres = N - 0.797 * (N ^ 1/3 - 2) ^ 3
#       in:                     len
#       out:                    nsurface
#-------------------------------------------------------------------------------
#    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
#    $sbrName="$tmp"."funcNsurface";
    $cubes=$lenIn - ($lenIn**(1/3) - 2)**3;
    $spheres=0.797*$cubes;
    return($cubes,$spheres);
}				# end of funcNsurface

#===============================================================================
sub funcNsurfaceFit1 {
    local($lenIn,$add) = @_ ;local($tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
    return($lenIn - (($lenIn**(1/3)) - $add)**3);
}				# end of funcNsurfaceFit1
#===============================================================================
sub funcNsurfaceFit2 {
    local($lenIn,$add,$fac) = @_ ;local($tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
    return($lenIn - $fac*(($lenIn**(1/3)) - $add)**3);
}				# end of funcNsurfaceFit2

#===============================================================================
sub funcNsurfacePhdFit1 {
    local($lenIn) = @_ ;local($tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   funcNsurfacePhdFit1         length to number of surface molecules
#                               assuming spheres/cubes, fitted to PHD error
#                               out=(N ^ 1/3 - 1.017) ^ 3
#       in:                     len
#       out:                    NsurfacePhdFit1
#-------------------------------------------------------------------------------
    return($lenIn - (($lenIn**(1/3)) - 1.017)**3);
}				# end of funcNsurfacePhdFit1

#===============================================================================
sub funcNsurfacePhdFit2 {
    local($lenIn) = @_ ;local($tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   funcNsurfacePhdFit2         length to number of surface molecules
#                               assuming spheres/cubes, fitted to PHD error
#                               out=(N ^ 1/3 - 2) ^ 3
#       in:                     len
#       out:                    NsurfacePhdFit2
#-------------------------------------------------------------------------------
    return($lenIn - 0.5972*(($lenIn**(1/3)) - 0.3334)**3);
}				# end of funcNsurfacePhdFit2

#===============================================================================
sub subx {
    local($fileInLoc,$fhErrSbr) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   subx                       
#                               c
#       in:                     
#         $fhoutLoc             file handle print output
#         A                     A
#       out:                    
#         A                     A
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."subx";$fhinLoc="FHIN"."$sbrName";

    $Lok=       &open_file("$fhinLoc","$fileInLoc");
    if (! $Lok){print $fhErrSbr "*** ERROR $sbrName: '$fileInLoc' not opened\n";
		return(0);}
    while (<$fhinLoc>) {
	$_=~s/\n//g;
	next if (length($_)==0);
    } close($fhinLoc);

}				# end of subx

#===============================================================================
sub ranSelectBeg {
    local($lenFragLoc,$lenProtLoc)=@_;
    $[ =1 ;
#-------------------------------------------------------------------------------
#   ranSelectBeg                random selection of begin from length
#       in / out GLOBAL:                     
#-------------------------------------------------------------------------------
    $pos=int(rand($lenProtLoc-$lenFragLoc))+1; # 1 <= pos <= (length Protein - length fragment)
    if ($Lrestr2caps){		# off the caps?
				# not close enough to N-term
	if    (($pos>($lenProtLoc*$fracap)) && ($pos<($lenProtLoc-($lenProtLoc*$fracap)))){
	    while ($pos>($lenProtLoc*$fracap)){	# reduce
		--$pos;
		last if ($pos==0);}
	    return(0) if (! $pos);} # none found!
				# not close enough  to C-term
	elsif (($pos>($lenProtLoc*$fracap)) && ($pos<($lenProtLoc-($lenProtLoc*$fracap)))){
	    while ($pos<($lenProtLoc-($lenProtLoc*$fracap))){ # reduce
		--$pos;}}}
    $pos=1 if ($pos<1);
    if ($Lrestr2caps){		# off the caps?
	$pos=($lenProtLoc-$lenFragLoc-($lenProtLoc*$fracap)) 
	    if (($pos+$lenFragLoc)>$lenProtLoc);}
    else {
	$pos=($lenProtLoc-$lenFragLoc) if (($pos+$lenFragLoc)>$lenProtLoc);}
    return($pos);
}				# end of ranSelectBeg

#===============================================================================
sub ranSelectLen {
    local($maxLoc,$lenProtLoc)=@_;
    $[ =1 ;
#-------------------------------------------------------------------------------
#   ranSelectLen                random selection of length of protein from @his
#       in / out GLOBAL:                     
#-------------------------------------------------------------------------------
    $pos=int(rand($maxLoc-$minLen));	# 1 <= pos <= $maxLen
    if ($Lrestr2caps){		# off the caps?
	while ($pos>($lenProtLoc-2*$fracap)){
	    --$pos}}
    $pos=$minLen if ($pos<$minLen);
    $pos=$maxLoc if ($pos>$maxLoc);
    $ctHis=$hisPtr[$pos];	# get respective interval
    ++$ctHis while (! defined $ctHis || length($ctHis) < 1 || $ctHis<1);
    $ctHisOrig=$ctHis;
#    print "xx ranlen 1: ctHis=$ctHis, pos=$pos, maxLoc=$maxLoc, \n";
    $ctHisTmp=			# (1) check whether unused
	&ranSelectLenLoop($ctHis);
				# 
    if (! $ctHisTmp){		# (2) is over-used => search forward
	while (! $ctHisTmp && $ctHis<$#his){ # forward
	    ++$ctHis;
	    $ctHisTmp=&ranSelectLenLoop($ctHis);
	    $ctHisTmp=0 if ($ctHisTmp !=0 && ($hisMin[$ctHisTmp]>$maxLoc)); # watch length!
	}}
    if (! $ctHisTmp){		# (3) is over-used => search backward
	$ctHis=1;
	while (! $ctHisTmp && $ctHis<$#his){
	    ++$ctHis;
	    $ctHisTmp=&ranSelectLenLoop($ctHis);
	    $ctHisTmp=0 if ($ctHisTmp !=0 && ($hisMin[$ctHisTmp]>$maxLoc)); # watch length!
	}}
    if (!$ctHisTmp){		# never found anything 
        return(0);
	print "*** ERROR ranSelectLen could not find appropriate length ctHis=$ctHis\n";
	print "*** so far ranDoneSum=$ranDoneSum, sumHis=$sumHis\n";
	exit;}
    if ($ctHisTmp!=$ctHisOrig){	# get length for new interval
	$pos=int(rand($hisMax[$ctHisTmp]-$hisMin[$ctHisTmp]+1))+1;}
    if    ($pos>$maxLoc)   {$pos=$maxLoc;}
    elsif ($pos>$maxLen)   {$pos=$maxLen;}
    elsif ($pos<$minLen)   {$pos=$minLen;}
    if ($Lrestr2caps){		# off the caps?
	$pos=0 if ($pos>($lenProtLoc-2*$fracap));}
    return($pos);
}				# end of ranSelectLen

#===============================================================================
sub ranSelectLenLoop {
    local($ctHisLoop)=@_;
    $[ =1 ;
#-------------------------------------------------------------------------------
#   ranSelectLenLoop            loop over random selection of length of protein 
#       in / out GLOBAL:                     
#-------------------------------------------------------------------------------
				# (1) find next if no slot in histogram
    $ctHisLoop=1 if (! defined $ctHisLoop);
    while (! defined $his[$ctHisLoop]){
	++$ctHisLoop;}
				# (2) length not used, yet 
    if    (! defined $hisDone[$ctHisLoop]){
	$hisDone[$ctHisLoop]=1;
	return($ctHisLoop);}
				# (3) length used, but not over-used
    elsif (defined $hisDone[$ctHisLoop] && ($hisDone[$ctHisLoop] < $blowup*$his[$ctHisLoop])){
	++$hisDone[$ctHisLoop];
	return($ctHisLoop);}
				# (4) length over-used => take next
    elsif (defined $hisDone[$ctHisLoop] && ($hisDone[$ctHisLoop] >= $blowup*$his[$ctHisLoop])){
	return(0);}
    else {
	print "*** ERROR in ranSelectLenLoop ctHisLoop=$ctHisLoop\n";
	exit;}
}				# end of ranSelectLenLoop

#===============================================================================
sub ranSelectProt {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   ranSelectProt               random selection of protein from @ranStack
#       in / out GLOBAL:                     
#-------------------------------------------------------------------------------
    $pos=int(rand($#ranStack))+1; # 1 <= pos <= $#ranStack
    if   ($pos>$#ranStack){$pos=$#ranStack ;}
    elsif($pos<1)         {$pos=1;}
    if ($ranDone[$pos]){	# search forward
	while ($ranDone[$pos] && $pos<$#ranStack){
	    ++$pos;}}		# jump 1 position
    if ($ranDone[$pos]){	# search backward
	while ($ranDone[$pos] && $pos>1){
	    --$pos;}}		# jump 1 position
    if ($ranDone[$pos]){
#	print "*** ERROR itPick=$itPick, could not find free protein slot in ranStack\n";
	print "*** found so far=$ranDoneSum proteins, slots=",$#ranStack,"\n";
	exit;}
    $ranDone[$pos]=1;
    return($ranStack[$pos]);
}				# end of ranSelectProt

#===============================================================================
sub getSumAcc {
    local($pos,$len,$beg,$exp) = @_ ;
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getSumAcc                   sums number of exposed residues in fragment
#       in / out GLOBAL:                     
#-------------------------------------------------------------------------------
    $sum=0;
    foreach $ctRes($beg..($beg+$len-1)){
	++$sum if ($rd{"$posProt","$ctRes","accP"}>=$exp);}
    return($sum);
}				# end of getSumAcc

#===============================================================================
sub getSumAccObs {
    local($pos,$len,$beg,$exp) = @_ ;
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getSumAccObs                sums number of exposed residues in fragment
#       in / out GLOBAL:                     
#-------------------------------------------------------------------------------
    $sum=0;
    foreach $ctRes($beg..($beg+$len-1)){
	return(0) if (! defined $rd{"$posProt","$ctRes","accO"});
	++$sum if ($rd{"$posProt","$ctRes","accO"}>=$exp);}
    return($sum);
}				# end of getSumAcc

#===============================================================================
sub getSeq {
    local($pos,$len,$beg,$exp) = @_ ;
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getSeq                   sums number of exposed residues in fragment
#       in / out GLOBAL:                     
#-------------------------------------------------------------------------------
    
}				# end of getSeq

