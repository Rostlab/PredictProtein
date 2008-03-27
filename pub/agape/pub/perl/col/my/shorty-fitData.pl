#!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="read surface data (as output by phdRdbAcc2Stat.pl) and fits surface";
#  
#
$[ =1 ;
				# include libraries
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
require "ctime.pl";
require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
				# ------------------------------
				# defaults
$minLen=     30;		# minimal length
$maxLen=    100;		# maximal length
$maxLen=    200;		# maximal length
$maxAdd=      2;
$nfitAdd=   100;
$nfitFac=   100;
#$nfitAdd=    10;
#$nfitFac=    10;
$itrvlAdd=1/$nfitAdd;
$itrvlFac=1/$nfitFac;
				# ------------------------------
if ($#ARGV<1){			# help
    print "goal:\t $scrGoal\n";
    print "use: \t '$scrName file-dot-dat' (from ranSeqAccOfPhdRdb)\n";
    print "opt: \t maxLen=$maxLen  \t: maximal length for picks \n";
    print "     \t minLen=$minLen  \t: minimal length for picks \n";
    print "     \t fileOut=x\n";
#    print "     \t \n";
    exit;}
				# initialise variables
$fhin="FHIN";$fhout="FHOUT";
				# ------------------------------
				# read command line
$fileIn=$ARGV[1];
$tmp=$fileIn;$tmp=~s/^.*\///g;$fileOut="Outfit-".$tmp;

foreach $_(@ARGV){
    next if ($_ eq $ARGV[1]);
    if   ($_=~/^fileOut=(.*)$/)    {$fileOut=$1;}
    elsif($_=~/^maxLen=(.*)$/)     {$maxLen=$1;}
    elsif($_=~/^minLen=(.*)$/)     {$minLen=$1;}
#    elsif($_=~/^=(.*)$/){$=$1;}
    else {print"*** wrong command line arg '$_'\n";
	  die;}}
$fileOutTmp=$fileOut;$fileOutTmp=~s/\..*/\.dynamic/;

				# ------------------------------
				# (1) read file
&open_file("$fhin", "$fileIn");
$#id=$it=0;
while (<$fhin>) {
    next if ($_=~/^\#|^id|^No[\s\t]+|^4N/); # skip comments, names
    $_=~s/\n//g;		# id, len, n16P, n16O
    @tmp=split(/\t/,$_);
    if ($#tmp<7){print "*** ERROR $scrName line=$_\n";
		 die;}
    foreach $tmp(@tmp){$tmp=~s/\s//g;}
    next if ( ($tmp[2]>$maxLen)||($tmp[2]<$minLen) );
    ++$it;
    $rd{"$it","id"}=  $tmp[1];push(@id,$tmp[1]);
    $rd{"$it","len"}= $tmp[2];
    $rd{"$it","n16o"}=$tmp[4];
    $rd{"$it","n16p"}=$tmp[5];
#    $rd{"$it","n9o"}= $tmp[6];
#    $rd{"$it","n9p"}= $tmp[7];
}close($fhin);
$nprot=$it;

                         	# ------------------------------
				# (2) do fit 
&open_file("$fhout",">$fileOutTmp"); 
print $fhout "add\tfac\tfit2\tfit0\n";
foreach $it1 (1..$nfitAdd*$maxAdd){
    $tmp=($it1*$itrvlAdd);
    $fito_16{"$it1"}=0;		# ini
    foreach $it2 (1..$nfitFac){
	$tmpAdd=($it1*$itrvlAdd);
	$tmpFac=($it2*$itrvlFac);
	$fit2_16{"$it1","$it2"}=0; # ini
	foreach $it (1..$nprot){ # loop over all proteins
	    if ($it2 == 1){
		$fito_16{"$it1"}+=
		    &funcErr($rd{"$it","n16o"} - &funcNsurfaceFit1($rd{"$it","len"},$tmp));}
	    $fit2_16{"$it1","$it2"}+=
		&func_absolute(&funcErr($rd{"$it","n16p"} - 
					&funcNsurfaceFit2($rd{"$it","len"},$tmpAdd,$tmpFac)));
	}
	print $fhout "$it1\t$it2\t",$fit2_16{"$it1","$it2"},"\t",$fito_16{"$it1"},"\n";
    }}close($fhout);
				# ------------------------------
				# (3) find minima
$mino_16=$fito_16{"1"};$min2_16=$fit2_16{"1","1"};
foreach $it1 (1..$nfitAdd*$maxAdd){
    if ($fito_16{"$it1"}<$mino_16){$mino_16=$fito_16{"$it1"};$poso_16=$it1;}
    foreach $it2 (1..$nfitFac){
	if ($fit2_16{"$it1","$it2"}<$min2_16){
	    $min2_16=$fit2_16{"$it1","$it2"};$pos2_16=$it1;$pos2fac_16=$it2;}}}
	    
$addo_16=$itrvlAdd*$poso_16;$add2_16=$itrvlAdd*$pos2_16;$fac2_16=$itrvlFac*$pos2fac_16;
#$addo_9= $itrvlAdd*$poso_9; $add2_9= $itrvlAdd*$pos2_9; $fac2_9=$itrvlFac*$pos2fac_9;

				# ------------------------------
				# (5) output
printf 
    "# min fitO:16=%6.2f it1=%3d     %3s -> add=%6.2f\n",($mino_16/$nprot),$poso_16," ",$addo_16;
printf 
    "# min fit2:16=%6.2f it1=%3d it2=%3d -> add=%6.2f fac=%6.2f\n",
    ($min2_16/$nprot),$pos2_16,$pos2fac_16,$add2_16,$fac2_16;

print "it1\t val\t fito16 \t fito 9\t fit2:16\t fit2: 9\n";
foreach $it1 (1..$nfitAdd*$maxAdd){
    printf 
	"%4d\t%6.2f\t%6.2f\n",
	$it1,$itrvlAdd*$it1,($fito_16{"$it1"}/$nprot);}
if(0){
    foreach $it1 (1..$nfitAdd*$maxAdd){
	foreach $it2 (1..$nfitFac){
	    printf 
		"%4d\t%4d\t%6.2f\t%6.2f\t%6.2f\n",
		$it1,$it2,$itrvlAdd*$it1,$itrvlFac*$it2,
		($fit2_16{"$it1","$it2"}/$nprot);}}
}

printf 
    "# min fitO:16=%6.2f it1=%3d     %3s -> add=%6.2f\n",($mino_16/$nprot),$poso_16," ",$addo_16;
printf 
    "# min fit2:16=%6.2f it1=%3d it2=%3d -> add=%6.2f fac=%6.2f\n",
    ($min2_16/$nprot),$pos2_16,$pos2fac_16,$add2_16,$fac2_16;
				# ------------------------------
				# write output
&open_file("$fhout",">$fileOut"); 
printf $fhout 
    "# min fitO:16=%6.2f it1=%3d     %3s -> add=%6.2f\n",($mino_16/$nprot),$poso_16," ",$addo_16;
printf $fhout 
    "# min fit2:16=%6.2f it1=%3d it2=%3d -> add=%6.2f fac=%6.2f\n",
    ($min2_16/$nprot),$pos2_16,$pos2fac_16,$add2_16,$fac2_16;

print $fhout "it1\t val\t fit0:16\t fit2:16\n";
foreach $it1 (1..$nfitAdd*$maxAdd){
    printf $fhout 
	"%4d\t%6.2f\t%6.2f\n",
	$it1,$itrvlAdd*$it1,($fito_16{"$it1"}/$nprot);}
$ct=0;
foreach $it1 (1..$nfitAdd*$maxAdd){
    foreach $it2 (1..$nfitFac){
	++$ct;
	printf $fhout 
	    "%4d\t%4d\t%4d\t%6.2f\t%6.2f\n",$ct,
	    $it1,$it2,$itrvlAdd*$it1,$itrvlFac*$it2,
	    ($fit2_16{"$it1","$it2"}/$nprot);
    }}
close($fhout);

print "--- output in $fileOut\n";
exit;
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
sub funcErr {
    local($err) = @_ ;local($tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
    $err=$err**2;
    return($err);
}				# end of funcErr

