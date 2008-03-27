#!/usr/bin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="repeat statistics on PHD stat (generated by phdRdbAcc2Stat.pl)\n".
    "     \t i.e. sorts according to len and compiles fit";
#  
#
$[ =1 ;
				# include libraries
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
#require "ctime.pl";
require "lib-ut.pl"; require "lib-br.pl";
				# ------------------------------
				# defaults
$lenMin=   30;			# minimal length of proteins considered
$fhin="FHIN";$fhout="FHOUT";
				# ------------------------------
if ($#ARGV<1){			# help
    print "goal:\t $scrGoal\n";
    print "use: \t '$scrName file-with-id.rdb-list'\n";
    print "opt: \t len=$lenMin     (minimal length of protein taken)\n";
    print "     \t lenMax=lenMax   (maximal length of protein taken)\n";
    print "     \t fileOut=x\n";
    print "     \t isPred          (for prediction without observed, automatic if file Pred*)\n";
    print "     \t fileProb=x      (if defined: read probabilities for globularity)\n";
    print "     \t                 automatic if file passed named Prob*\n";
    print "     \t isSorted        (read other column if run on output of this script)\n";
    print "     \t                 automatic if file passed named *sort*\n";
    print "     \t isRan           (for the file from ranSeqAccOfPhdRdb.pl)\n";
    print "     \t                 automatic if file passed named Ran*\n";
#    print "     \t \n";
    exit;}

				# ------------------------------
$fileIn=$ARGV[1];		# read command line
$tmp=$fileIn;$tmp=~s/^.*\///g;$fileOut="Out-".$tmp;$fileOut=~s/\.list/\.dat/;

foreach $_(@ARGV){
    next if ($_ eq $ARGV[1]);
    if   ($_=~/^fileOut=(.*)$/)  {$fileOut=$1;}
    elsif($_=~/^len=(.*)$/)      {$lenMin=$1;}
    elsif($_=~/^lenMax=(.*)$/)   {$lenMax=$1;}
    elsif($_=~/^isPred/)         {$LisPred=1;}
    elsif($_=~/^isSorted/)       {$LisSorted=1;}
    elsif($_=~/^isRan/)          {$LisRan=1;}
    elsif($_=~/^fileProb=(.*)$/) {$LdoProb=1;$fileProb=$1;}
    elsif(-e $_ && $_=~/prob/i)  {$LdoProb=1;$fileProb=$_;}
    else {print"*** wrong command line arg '$_'\n";
	  die;}}
die 'missing hsspRdb'.$fileIn  if (! -e $fileIn);
$LisRan=1    if ($fileIn =~ /ran/i); # automatic recognition of file from ranSeqAccOfPhdRdb.pl
$LisSorted=1 if ($fileIn =~ /sort/i); # automatic recognition of file from this script
$LisRan=0    if (! defined $LisRan);
$LisPred=0   if (! defined $LisPred);
$LisSorted=0 if (! defined $LisSorted);
				# ------------------------------
				# (1) read file with statistics
&open_file("$fhin", "$fileIn");
undef %rd; $#len=0;
while (<$fhin>) {
    next if ($_=~/^\#|^id/);	# skip comments and first line
    $_=~s/\n//g;
    $tmp=$_;$tmp=~s/^[^\t]+\t([^\t]+)\t.+$/$1/;	# grep len
    if (! defined $rd{"$tmp"}){
	$rd{"$tmp"}=$_; push(@len,$tmp)}
    else{
	$rd{"$tmp"}.="\n".$_;}}close($fhin);
@sortLen=sort bynumber (@len);	# sort length
				# ------------------------------
				# (2) assign averages for fits
				# ------------------------------
				# (3) read probabilities
if (defined $fileProb && -e $fileProb){
    &open_file("$fhin", "$fileProb");
    $#probHis=$#probVal=0;
    while (<$fhin>) {
	next if ($_=~/^n|^\#/);	# skip comments and first line
	$_=~s/\n//g;
	@tmp=split(/\t/,$_);
	push(@probHis,$tmp[2]);push(@probVal,$tmp[4]);}close($fhin);}


$#sortLine=0;			# ------------------------------
foreach $len(@sortLen){		# (4) sort the lines further
    next if ($len < $lenMin);
    last if (defined $lenMax && $len > $lenMax);
    @tmp=split(/\n/,$rd{"$len"});undef %n16o; $#n16o=0;
    foreach $tmp(@tmp){
	@tmp2=split(/\t/,$tmp);
	if (! $LisPred && !$LisSorted){	# sort by observed (accRel>16%)
	    $n16o=$tmp2[4];}
	elsif ($LisSorted){
	    $n16o=$tmp2[3];}
	else {			# sort by predicted
	    $n16o=$tmp2[5]; }
	if (! defined $n16o{"$n16o"}){
	    $n16o{"$n16o"}=$tmp;push(@n16o,$n16o);}
	else {$n16o{"$n16o"}.="\n".$tmp;}}
    @sortN16o=sort bynumber (@n16o);
    foreach $n16o(@sortN16o){
	push(@sortLine,split(/\n/,$n16o{"$n16o"}));}}
$it=$#fit2_16=$#fito_16=0;
				# ------------------------------
foreach $line(@sortLine){	# (5) get 'fit' statistics
    @tmp=split(/\t/,$line);
    foreach $tmp(@tmp){$tmp=~s/\s//g;}
    next if ($#tmp<8);
    ++$it;
    $res{"$it","id"}=       $tmp[1];
    $res{"$it","len"}=      $tmp[2];
#    $res{"$it","lenRd"}=    $tmp[3];
    if    ($LisPred && ! $LisSorted){
	$res{"$it","n16o"}=     $tmp[5];
	$res{"$it","n16p"}=     $tmp[5];}
    elsif ($LisPred && $LisSorted){
	$res{"$it","n16o"}=     $tmp[4];
	$res{"$it","n16p"}=     $tmp[5];}
    elsif ($LisSorted){
	$res{"$it","n16o"}=     $tmp[3];
	$res{"$it","n16p"}=     $tmp[4];}
    else {
	$res{"$it","n16o"}=     $tmp[4];
	$res{"$it","n16p"}=     $tmp[5];}

    $res{"$it","fit2_16"}=  &funcNsurfacePhdFit2($tmp[2],$fit2Add,$fit2Fac,16);
    $res{"$it","fito_16"}=  &funcNsurfacePhdFito($tmp[2],$fitOAdd,16);
    $res{"$it","p-fit2_16"}=$res{"$it","n16p"}-$res{"$it","fit2_16"};
    $res{"$it","o-fito_16"}=$res{"$it","n16o"}-$res{"$it","fito_16"};
    push(@fit2_16,$res{"$it","p-fit2_16"});
    push(@fito_16,$res{"$it","o-fito_16"});
    if ($LisRan){
	$res{"$it","n16o"}=$res{"$it","fito_16"}=$res{"$it","o-fito_16"}=0;}
}
$nfound=$it;
($ave2{16},$var2{16})= &stat_avevar(@fit2_16);$sig2{16}=sqrt($var2{16});
($aveo{16},$varo{16})= &stat_avevar(@fito_16);$sigo{16}=sqrt($varo{16});
				# ------------------------------
				# (6) count 2 std deviations off
$offp{"1","16"}=$offp{"2","16"}=$offp{"3","16"}=
    $offo{"1","16"}=$offo{"2","16"}=$offo{"3","16"}=0;
foreach $it(1..$nfound){
    foreach $itOff(1..3){
	++$offp{"$itOff","16"} if ($res{"$it","p-fit2_16"}<$ave2{16}-$itOff*$sig2{16} ||
				   $res{"$it","p-fit2_16"}>$ave2{16}+$itOff*$sig2{16});
	if (! $LisRan){
	    ++$offo{"$itOff","16"} if ($res{"$it","o-fito_16"}<$aveo{16}-$itOff*$sigo{16} ||
				       $res{"$it","o-fito_16"}>$aveo{16}+$itOff*$sigo{16});}
    }}
				# ------------------------------
				# (7) get probabilites (read from file)
if ($LdoProb){
    foreach $it(1..$nfound){
	$Lok=0;
	foreach $itHis(1..($#probHis-1)){ # loop over all prob histogram values
	    if (($res{"$it","p-fit2_16"}<=$probHis[$itHis]) && 
		($res{"$it","p-fit2_16"}>$probHis[$itHis+1])){
		$Lok=1;$res{"$it","prob"}=$probVal[$itHis];
#		print "xx it=$it, p=$probVal[$itHis],\n";
		last;}}
	if (! $Lok){		# smaller or larger than histogram of prob -> extreme values
	    if    ($res{"$it","p-fit2_16"}>$probHis[1]){
		$Lok=1;$res{"$it","prob"}=$probVal[1];}
	    elsif ($res{"$it","p-fit2_16"}<$probHis[$#probHis]){
		$Lok=1;$res{"$it","prob"}=$probVal[$#probHis];}}
	if (! $Lok){
	    print "xx none found for it=$it, p-f=",$res{"$it","p-fit2_16"},",\n";
	    die;}}}
				# ------------------------------
				# (8) write statistics
&open_file("$fhout",">$fileOut"); 
foreach $fh ("STDOUT","$fhout"){
    printf $fh 
	"#                                   %-6s %-6s %-4s %-4s %-4s %-4s %-5s %-5s %-5s\n",
	"ave","sig","nTot","n1Off","n2Off","n3Off","p1","p2","p3";
    printf $fh
	"# fit2_16 (N-".substr($fit2Fac,1,4)."*(N^1/3-".substr($fit2Add,1,4).")^3) ".
	    "%6.2f %6.2f %4d %4d %4d %4d %5.1f %5.1f %5.1f\n",
	    $ave2{16},sqrt($var2{16}),$nfound,
	    $offp{"1","16"},$offp{"2","16"},$offp{"3","16"},100*($offp{"1","16"}/$nfound),
	    100*($offp{"2","16"}/$nfound),100*($offp{"3","16"}/$nfound);
    printf $fh
	"# fito_16 (N-     (N^1/3-".substr($fitOAdd,1,4).")^3) ".
	    "%6.2f %6.2f %4d %4d %4d %4d %5.1f %5.1f %5.1f\n",
	    $aveo{16},sqrt($varo{16}),$nfound,
	    $offo{"1","16"},$offo{"2","16"},$offo{"3","16"},100*($offo{"1","16"}/$nfound),
	    100*($offo{"2","16"}/$nfound),100*($offo{"3","16"}/$nfound);

    printf $fh
	"%-s\t%-s\t%-s\t%-s\t%-s\t%-s\t%-s\t%-s",
	"id","len","n16O","n16P","nfit2_16","p-fit2_16","nfito_16","o-fito_16";
    if ($LdoProb){
	print $fh "\t","prob";}
    print $fh "\n";

    foreach $it(1..$nfound){
	printf $fh
	    "%-s\t%4d\t%4d\t%4d\t",$res{"$it","id"},
	    $res{"$it","len"},$res{"$it","n16o"},$res{"$it","n16p"};
	printf $fh
	    "%6.1f\t%6.1f\t%6.1f\t%6.1f",
	    $res{"$it","fit2_16"},$res{"$it","p-fit2_16"},
	    $res{"$it","fito_16"},$res{"$it","o-fito_16"};
	if ($LdoProb){
	    printf $fh "\t%8.3f",$res{"$it","prob"};}
	print $fh "\n";}
    close($fh) if ($fh ne "STDOUT");
}

print "--- output in $fileOut\n";
exit;

#===============================================================================
sub funcNsurfacePhdFit2 {
    local($lenIn,$add,$fac,$expLoc) = @_ ;local($tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   funcNsurfacePhdFit2_16      length to number of surface molecules
#                               fitted to PHD error 
#                               out=(N ^ 1/3 - 2) ^ 3
#       in:                     len, acc-cut-off (allowed: 9, 16)
#       out:                    NsurfacePhdFit2
#-------------------------------------------------------------------------------
    $expLoc=16 if (! defined $expLoc); # default
    if   ($expLoc == 9) {
	return($lenIn - $fac*(($lenIn**(1/3)) - $add)**3);}
    elsif($expLoc == 16) {
	return($lenIn - $fac*(($lenIn**(1/3)) - $add)**3);}
    else{ print "*** ERROR in $scrName funcNsurfacePhdFit2 only defined for exp=16 or 9\n";
	  die;}
}				# end of funcNsurfacePhdFit2

#===============================================================================
sub funcNsurfacePhdFito {
    local($lenIn,$add,$expLoc) = @_ ;local($tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   funcNsurfacePhdFito         length to number of surface molecules
#                               fitted to DSSP
#                               out=(N ^ 1/3 - 2) ^ 3
#       in:                     len, acc-cut-off (allowed: 9, 16)
#       out:                    NsurfacePhdFito
#-------------------------------------------------------------------------------
    $expLoc=9 if (! defined $expLoc); # default
    if   ($expLoc == 9) {
	return($lenIn - (($lenIn**(1/3)) - $add)**3);}
    elsif($expLoc == 16) {
	return($lenIn - (($lenIn**(1/3)) - $add)**3);}
    else{ print "*** ERROR in $scrName funcNsurfacePhdFito only defined for exp=16 or 9\n";
	  die;}
}				# end of funcNsurfacePhdFito

