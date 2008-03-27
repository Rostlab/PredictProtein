#!/usr/sbin/perl4 -w
##!/usr/sbin/perl -w
#
# convert hssp_topits to CASP2 format
#
#
$[ =1 ;

push (@INC, "/home/rost/perl") ;
require "ctime.pl";		# require "rs_ut.pl" ;
require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";

@des=  ("fileLib","exeExtrDsspSeq","exeExtrHsspSeq","exeConvHssp2Daf",
	"fileDssp","fileHsspX","fileHssp","fileStrip","fileOut","naliWrt");

				# ------------------------------
				# help
if ($#ARGV<1){print"goal:   convert to CASP2 format\n";
	      print"usage:  'script t000x.hssp_topits (t000x.x, MaxHom .x file must exist!)'\n";
	      print"option: fileLib=x (or lib=x, fold library default Topits_dssp723.list)\n";
	      &myprt_array(",",@des);
	      exit;}
				# ------------------------------
				# defaults
$par{"fileLib"}=        "/home/rost/pub/topits/Topits_dssp723.list";
#$par{"fileLib"}=        "tmp.list";
$par{"exeExtrDsspSeq"}= "/home/rost/perl/scrs/dssp_extr.pl";
$par{"exeExtrHsspSeq"}= "/home/rost/perl/scrs/hssp_extr_2pir.pl";
$par{"exeConvHssp2Daf"}="/home/rost/perl/scrs/conv_hssp2daf.pl";
$par{"naliWrt"}=        6;
$par{"naliWrt"}=        8;
#$par{"naliWrt"}=        2;

$fhout="FHOUT";$fhin="FHIN";
$fileTmp="x$$.tmp";
$nalign=$par{"naliWrt"};

#$numOfSubmission=1;		# number of predictions submitted before

				# ------------------------------
				# read input
$fileHssp=$par{"fileHssp"}=$ARGV[1];
foreach $_(@ARGV){
    if (/^lib=/){$_=~s/^lib=|\s//g;$par{"fileLib"}=$_;}
    else {
	foreach $des(@des){
	    if (/^$des=/){$_=~s/^$des=|\s//g;$par{"$des"}=$_;
			  last;}}}
}
				# ------------------------------
				# adjust defaults
$fileHssp=$par{"fileHssp"};
$nameShort=substr($fileHssp,1,5); 
$name=$fileHssp;$name=~s/\.hssp.*$//g;
$extIn=$fileHssp;$extIn=~s/^.*\.hssp//g;

if ($name !~/^t/){print"*** name should be 't0005'\n";}
if (! defined $par{"fileDssp"})  { $par{"fileDssp"}= $name.".dssp_phd";}
if (! defined $par{"fileHsspX"}) { 
    if (length($extIn)==0){$par{"fileHsspX"}=$name.".x";}else{$par{"fileHsspX"}=$name.".x$extIn";}}
if (! defined $par{"fileStrip"}) { 
    if (length($extIn)==0){$par{"fileStrip"}=$name.".strip_topits";}
    else{$par{"fileStrip"}=$name.".strip$extIn";}}
$par{"fileOut"}=  $nameShort.".frv1_casp2";
$nameShort=~s/^t/T/;

				# ------------------------------
				# read fold library
$#libId=$#libChain=0;$file=$par{"fileLib"};
&open_file("$fhin","$file");
while(<$fhin>){
    $_=~s/\s|\n//g;$_=~s/^.*\///g;$_=~s/\.[dhf]ssp//g;
    if (length($_)<4){
	next;}
    $id=substr($_,1,4);
    if (length($_)>4){$chain=substr($_,length($_),1);}
    else{$chain="-";}
    push(@libId,$id);push(@libChain,$chain);}close($fhin);
$numLib=$#libId;
				# ------------------------------
                                # read sequence
				# extract DSSP sequence
$exe=$par{"exeExtrDsspSeq"};$fileDssp=$par{"fileDssp"};
print "--- system \t '$exe $fileDssp fileOut=$fileTmp aa not_screen'\n";
system("$exe $fileDssp fileOut=$fileTmp aa not_screen");
				# read output (DSSP sequence)
&open_file("$fhin","$fileTmp");
$seqDssp="";while(<$fhin>){$_=~s/\s|\n//g;$seqDssp.=$_;}close($fhin);

# &wrtCasp2("STDOUT",$name,$numLib,$seqDssp);
				# extract HSSP sequence
$exe=$par{"exeExtrHsspSeq"};
print "--- system \t '$exe $fileHssp fileOut=$fileTmp incl=1-2 not_screen'\n";
system("$exe $fileHssp fileOut=$fileTmp incl=1-2 not_screen");

&open_file("$fhin","$fileTmp");
$seqHssp="";$ct=0;
while(<$fhin>){++$ct;if (/^\>|^$nameShort/ || ($ct<=2)){ next;}
	       $_=~s/\s|\n//g;$seqHssp.=$_;}close($fhin);
				# check identity of sequences
if ($seqHssp ne $seqDssp){
    print "*** different sequences in $fileDssp and $fileHssp\n";
    print "DSSP=$seqDssp\n";
    print "HSSP=$seqHssp\n";
    exit;}

&rdStripHack($par{"fileStrip"},20); # read strip file (for security first 20)

foreach $it (1..$par{"naliWrt"}){
    &rdHsspXHack($par{"fileHsspX"},$ali{"$it","id"},$it);	# read X file (alis)
}

$fileOut=$par{"fileOut"};
print "x.x before write into=$fileOut,\n";
&open_file("$fhout", ">$fileOut");
&wrtCasp2($fhout,$nameShort,$nalign,$numLib,$seqDssp,$par{"naliWrt"});
close($fhout);

print "--- output in '$fileOut'\n";
exit;

#==========================================================================================
sub rdStripHack {
    local ($fileLoc,$numExtr) = @_ ;
    local ($fhinLoc);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    rdStripHack                reads zscore and id from strip file
#       in:                     file.strip_topits number_of_ids_to_extract
#       out:                    $ali{"ct","x"} x = 'id' and 'z'
#--------------------------------------------------------------------------------
    $fhinLoc="FHIN_RDSTRIP";
    &open_file("$fhinLoc","$fileLoc");
    while(<$fhinLoc>){last if (/^ IAL/);}
    $ct=0;
    while(<$fhinLoc>){
	++$ct;
	last if ($ct>$numExtr);
	$z= substr($_,30,8);$z=~s/\s//g;
	$id=substr($_,71,8);$id=~s/\s//g;
	$ali{"$ct","id"}=$id;
	$ali{"$ct","z"}=$z;
    }
    close($fhinLoc);
}				# end of rdStripHack

#==========================================================================================
sub rdHsspXHack {
    local ($fileLoc,$idIn,$posIn) = @_ ;
    local ($fhinLoc);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    rdStripHack                reads alignments from maxhom.x file
#       in:                     file.x number_of_ids_to_extract
#       out:                    $ali{"ct","x"} x = 'id' and 'z'
#--------------------------------------------------------------------------------
    $fhinLoc="FHIN_RdHsspX";$#posSeq=$#posX=$#posStr=0;
    &open_file("$fhinLoc","$fileLoc");
    while(<$fhinLoc>){last if (/^\s+No/);}
    $ct=0;$Lfst=$Lali=0;
    while(<$fhinLoc>){
	if    (/^\s+No/){
	    if ($Lali){
		last;}
	    $Lfst=0;$ctLine=0;}
	elsif (! $Lfst) {$Lfst=1;++$ct;$ctLine=0;}
	if ($Lfst)   {++$ctLine;}
	if ($ctLine==9){
	    if ($idRd eq $idIn){$Lali=1;print"x.x id ok=$idRd, want=$idIn,\n";}
#	    else{print"x.x not ok idRd=$idRd, idIn=$idIn,\n";}
	}
	elsif ($ctLine==2){  # previously (x.x VERY STRANGE!!!)
#	elsif ($ctLine==1){
	    $_=~s/\n//g;$_=~s/\s+$//g;
	    print"x.x $_'\n";
	    $idRd=substr($_,(length($_)-20));
	    print"x.x idRd1=$idRd'\n";
	    $idRd=~s/\.dssp//g;$idRd=~s/^.*\///g;$idRd=~s/_\!//g;}
	if ($Lali){
	    if (/^\s+0/){	# 
		print "x.x says 0 '$_'\n";
		next;}		# 
	    $_=~s/\n//g;
	    $_=~s/^\s*|\s*$//g;
	    $_=~s/[A-Z]//g;	# hack July 15, to avoid problems with 35B (in PDB number)
	    if (length($_)==0){
		next;}
	    if ($_ !~/\d+\s+\d+/){
		print "x.x says no dd '$_'\n";
		next;}
	    ($posSeq,$posStr)=split(/\s+/,$_);
	    print "x.x $idRd, extr posSeq=$posSeq, posStr=$posStr,\n";
	    push(@posX,"$posSeq,$posStr");}
    }
    close($fhinLoc);
    $ct=$Lfst=$ctFrag=0;
    print "x.x rdHsspXHack: posX=",$#posX,",\n";
    foreach $it(1..$#posX){
	$pos=$posX[$it];
	($pos1,$pos2)=split(/,/,$pos);
	if (($pos1 eq "0")||($pos2 eq "0")){
	    next;}
	if (!$Lfst){$beg1=$pos1;$beg2=$pos2;$Lfst=1;}else{++$ct;}
	print"x.x 1=$pos1 ($beg1), 2=$pos2 ($beg2),\n";

	if (($beg1+$ct<$pos1)||($beg2+$ct<$pos2)){
	    ++$ctFrag;$end1=$beg1+$ct-1;$end2=$beg2+$ct-1;
	    $posSeq{"$posIn","$ctFrag"}="$beg1,$end1";$posStr{"$posIn","$ctFrag"}="$beg2,$end2";
	    $beg1=$pos1;$beg2=$pos2;$ct=0; }
	elsif ($it==$#posX){ # last
	    ++$ctFrag;$end1=$pos1;$end2=$pos2;
	    $posSeq{"$posIn","$ctFrag"}="$beg1,$end1";$posStr{"$posIn","$ctFrag"}="$beg2,$end2";}
    }
    $posSeq{"$posIn","NROWS"}=$ctFrag;
    foreach $it(1..$posSeq{"$posIn","NROWS"}){
	print "x.x $it=> seq=",$posSeq{"$posIn","$ctFrag"}," str=",$posStr{"$posIn","$ctFrag"},",\n";
    }
}				# end of rdHsspXHack


#==========================================================================================
sub wrtCasp2 {
    local ($fhloc,$name,$nalign,$numLib,$seqIn,$naliWrt) = @_ ;
    $[ =1 ;
#--------------------------------------------------------------------------------
#    wrtCasp2                       
#--------------------------------------------------------------------------------

				# --------------------------------------------------
				# email
    print $fhloc 
	"From: rost\@EMBL-Heidelberg.DE\n",
	"To: submit\@sb7.llnl.gov\n",
	"Subject: prediction ABF1 ($name)\n",
	"FCC: /sander/purple1/rost/mail/OUT_CASP2\n",
	"--text follows this line--\n";
				# --------------------------------------------------
				# header
    print $fhloc 
	"PFRMAT FRV1\n",
	"TARGET $name\n",
	"AUTHOR 1252-9708-9879, Rost, EMBL, rost\@","embl-heidelberg.de \n",
	"REMARK ============================================================\n",
	"REMARK Method:\n",
	"REMARK    Automatic usage of PHDthreader (TOPITS).\n",
	"REMARK Fold library:\n",
	"REMARK    Fold library comprised $numLib protein chains.\n",
	"REMARK Scores:\n",
	"REMARK    Scores reflect the opinion that the scheme used would\n",
	"REMARK    be optimal to account for the specific way of evaluating\n",
	"REMARK    accuracy.  Thus, the values given are not related to zscores.\n",
	"REMARK \n";
    print $fhloc 
	"REMARK ============================================================\n";
				# --------------------------------------------------
				# sequence
    for ($it=1;$it<=length($seqIn);$it+=50){
	$tmp=substr($seqIn,$it,50);
	printf $fhloc "SEQRES %-5s %-s\n",$name,$tmp;
    }
    print $fhloc "REMARK ============================================================\n";
    print $fhloc "REMARK first $nalign hits of search\n";
    print $fhloc "REMARK ============================================================\n";
				# --------------------------------------------------
				# scores
    $ct=0;
    foreach $it (1..$nalign){
#	$idx=$idPred[$it];  # old
	$idx=$ali{"$it","id"};	# new
	if ($ct>10){
	    last;}
#	($tmp,$idStr)=split(/,/,$idx); # old
#	$id=substr($idStr,1,4);	# old
#	if (length($idStr)>4){$chain=substr($idStr,length($idStr),1);}else{$chain="-";}	# old
	if (length($idx)>4){
	    $id=substr($idx,1,4);
	    $chain=substr($idx,length($idx),1);}
	else{$id=$idx;$chain="-";}	# new
	$idxx="$id" . "$chain";
	if ($it <= $naliWrt){$idStr[$it]=$id;$chain[$it]=$chain;}

	if (defined $flag{"$idxx"}){
	    next;}
	$flag{"$idxx"}=1;
	++$ct;

	if($ct==1){$conf=0.90;}elsif($ct==2){$conf=0.05;}else{$conf=0.05/($nalign-2);}
#	if($ct==1){$conf=0.90;}elsif($ct==2){$conf=0.1;}else{$conf=0.0;}
	$id=~tr/[a-z]/[A-Z]/;
	$chain=~tr/[a-z]/[A-Z]/;
	printf $fhloc "TSCORE %-5s %2d %5.3f  %-4s %-1s %2d\n",$name,0,$conf,$id,$chain,0;}
				# --------------------------------------------------
				# library
    print $fhloc "REMARK ============================================================\n";
    print $fhloc "REMARK rest of fold library in alphabetical order\n";
    print $fhloc "REMARK ============================================================\n";
    foreach $it (1..$#libId){
	$idTmp=$libId[$it].$libChain[$it];
	if (defined $flag{"$idTmp"}){
	    next;}
	$id=$libId[$it];$id=~tr/[a-z]/[A-Z]/; # to capital
	$chain=$libChain[$it];$chain=~tr/[a-z]/[A-Z]/;
	printf $fhloc "TSCORE %-5s %2d %5.3f  %-4s %-1s %2d\n",
	$name,0,0,$id,$chain,0;
    }

    print $fhloc "REMARK ============================================================\n";
    print $fhloc "REMARK Alignment for first hits only\n";
    print $fhloc "REMARK ============================================================\n";
				# --------------------------------------------------
				# ali 1
    print "x.x number of alis=$naliWrt\n";
    print "idstr=",$#idStr,"\n";
    foreach $itAli (1 .. $naliWrt){ 
	print "xx.x it=$itAli, idStr=$idStr[$itAli], chain=$chain[$itAli], nseq=",$posSeq{"$itAli","NROWS"},",\n";
	$idStr[$itAli]=~tr/[a-z]/[A-Z]/;$chain[$itAli]=~s/[a-z]/[A-Z]/;
	foreach $it (1..$posSeq{"$itAli","NROWS"}){
	    ($begSeq,$endSeq)=split(/,/,$posSeq{"$itAli","$it"});
	    ($begStr,$endStr)=split(/,/,$posStr{"$itAli","$it"});
	    printf $fhloc "TALIGN %-5s %2d %5d %5d      %-4s %-1s  0   %6s %6s    1.0    1\n",
	    $name,0,$begSeq,$endSeq,$idStr[$itAli],$chain[$itAli],$begStr,$endStr;
	}}
}				# end of wrtCasp2

#==========================================================================================
sub subx {
#    local ($fileIn, $chain_in, $skip) = @_ ;
    $[ =1 ;
#--------------------------------------------------------------------------------
#    subx                       
#         c
#       in:
#         A                     A
#       out:
#         A                     A
#--------------------------------------------------------------------------------

}				# end of subx


