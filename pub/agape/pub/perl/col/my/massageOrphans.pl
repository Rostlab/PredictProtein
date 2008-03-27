#!/usr/sbin/perl -w
#
#
$[ =1 ;

push (@INC, "/home/rost/perl") ;
require "ctime.pl";		# require "rs_ut.pl" ;
require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";

if ($#ARGV<1){print"goal:   \n";
	      print"usage:  \n";
	      exit;}

@desRd=  ("z","ide","wsim","lali","ngap","lgap","len2","len1","id2","id1");
@desWrt= ("z","ide","lali","len2","len1","rali","ngap","lgap","id2","id1");
foreach $des("z","rali"){
    $form{"$des"}="4.1f";}
foreach $des("ide","wsim","lali","ngap","lgap","len2","len1"){
    $form{"$des"}="4d";}
foreach $des("id1","id2","id2"){
    $form{"$des"}="-8s";}
				# defaults
$par{"zLow"}=        2;
$par{"ideUp"}=      90;
$par{"raliLow"}=     0.5;
$par{"laliLow"}=    50;
$par{"hsspFormula"}="0";

$fhout="FHOUT";
$hsspFormula=$par{"hsspFormula"};

$fileIn=$ARGV[1];
$par{"fileOut"}=  "Res-z".$par{"zLow"}."-r".$par{"raliLow"}.
    "-hssp".$par{"hsspFormula"}."-".$fileIn; $par{"fileOut"}=~s/Out_|Dat74-|DatHom-//g;

if (0){foreach $it (1..16){foreach $ali(3..8){
    if (&filter_hssp_curve(($ali*10),($it*5),"-5")){
	print "ide=",$it*5,", ali=",$ali*10,", >\n";}}}exit;}



				# read the RDB file (generated by hssp_ZintoHeader.pl)
%rd=
    &rd_rdb_associative($fileIn,"header","body","nProt",@desRd); 

				# --------------------------------------------------
				# compile some scores
$ctProt=$ctProtBad=$ctBad=$#idExcl=$#txtExcl=0;
foreach $it (1..$rd{"NROWS"}){
    $id1=$rd{"id1","$it"};
    print "x.x read it=$it, id1=$id1, id2=",$rd{"id2","$it"},",\n";

    $ctProt=$rd{"nProt","$it"};$Lexcl=$LexclTrivial=0;
    if    ($rd{"ide","$it"}>$par{"ideUp"}){ # purge high sequencen identity
	$Lexcl=1;$LexclTrivial=1;$txt="ide  (".$rd{"ide","$it"}.")";}
    elsif ($rd{"z","$it"}  <$par{"zLow"}){	# purge low z-score
	$Lexcl=1;$txt="z    (".$rd{"z","$it"}.")";}
    elsif ($rd{"lali","$it"}  <$par{"laliLow"}){ # purge too short alignments
	$Lexcl=1;$txt="lali (".$rd{"lali","$it"}.")";}
    elsif (&filter_hssp_curve($rd{"lali","$it"},
			      $rd{"ide","$it"},"$hsspFormula")){ # filter hssp curve
	$Lexcl=1;$txt="hssp (".$rd{"lali","$it"}.",".$rd{"ide","$it"}.")";}
    if (! $Lexcl){
	$len1=$rd{"len1","$it"};$len2=$rd{"len2","$it"};$lali=$rd{"lali","$it"};
	$rali=((2*$lali)/($len1+$len2));
	if ($rali<$par{"raliLow"}){	# purge low ratio lali/l1+l2
	    $Lexcl=1;$txt="rali (".$rali.")";}}
    if ($Lexcl){
	print "--- excluded \t $txt\n";
	if ((! defined $flagExcl{"$id1"})&&(! $LexclTrivial)){ # count false proteins
	    $flagExcl{"$id1"}=1;
	    push(@idExcl,$id1);push(@txtExcl,$txt);}
	next;}
				# ------------------------------
				# survivor
    ++$ctBad;
    if (! defined $flag{"$id1"}){ # count false proteins
	$flag{"$id1"}=1;
	++$ctProtBad;}
    foreach $des(@desRd){
	$rd{"$des","$it"}=~s/\s//g;
	$res{"$ctBad","$des"}=$rd{"$des","$it"};}
    $res{"$ctBad","rali"}=$rali;
}

$nFiles=$ctProt;
$nBad=$ctBad;
$nProtBad=$ctProtBad;
				# write
&wrtRes("STDOUT",",",$nFiles,$nBad,$nProtBad,@desWrt);
				# file
$fileOut=$par{"fileOut"};
&open_file("$fhout", ">$fileOut");
&wrtRes($fhout,"\t",$nFiles,$nBad,$nProtBad,@desWrt);
close($fhout);

print "--- excluded: \n";
foreach $it(1..$#idExcl){
    $id1=$idExcl[$it];
    if (defined $flag{"$id1"}){ # ignore where one found
	next;}
    printf "%-10s (%-s)\n",$idExcl[$it],$txtExcl[$it];}
print "x.x output in '$fileOut'\n";

exit;

#==========================================================================================
sub wrtRes {
    local ($fhloc,$sep,$nFilesLoc,$nBadLoc,$nProtBadLoc,@desIn) = @_ ;
    $[ =1 ;
#--------------------------------------------------------------------------------
#    wrtCasp2                       
#--------------------------------------------------------------------------------

				# ------------------------------
				# header
    print $fhloc "# Perl-RDB\n# \n";
    printf $fhloc "# NProtTotal = %5d\n",$nFilesLoc;
    printf $fhloc "# NProtFalse = %5d\n",$nProtBadLoc;
    printf $fhloc "# NHitsFalse = %5d\n",$nBadLoc;
    printf $fhloc "# ACC (prot) = %5.2f\n",100*($nProtBadLoc/$nFilesLoc);
    print  $fhloc "# \n# EXCLUSION:\n";
    foreach $desTmp("ideUp","zLow","raliLow","laliLow","hsspFormula"){
	printf $fhloc "# %-10s = %5.1f\n",$desTmp,$par{"$desTmp"};}
				# header
    foreach $des(@desIn){
	$tmp="%".$form{"$des"};$tmp=~s/d/s/;$tmp=~s/\.\d+f/s/;
	if ($des eq $desIn[$#desIn]){$sepX="\n";}else{$sepX=$sep;}
	printf $fhloc "$tmp$sepX",$des;}
				# format
    foreach $des(@desIn){
	$tmp="%".$form{"$des"};$tmp=~s/d/s/;$tmp=~s/\.\d+f/s/;
	$tmpX=&form_perl2rdb($form{"$des"});
	if ($des eq $desIn[$#desIn]){$sepX="\n";}else{$sepX=$sep;}
	printf $fhloc "$tmp$sepX",$tmpX;}
				# ------------------------------
				# body
    
    foreach $it (1..$nBadLoc){
	foreach $des(@desIn) {
	    if (! defined $res{"$it","$des"}){
		$tmpX="xx";
		print "*** not defined: it=$it, des=$des,\n";}
	    else {$tmpX=$res{"$it","$des"};}
	    $tmp="%".$form{"$des"};
	    if ($des eq $desIn[$#desIn]){$sepX="\n";}else{$sepX=$sep;}
	    printf $fhloc "$tmp$sepX",$tmpX;
	}
    }
}				# end of wrtRes

