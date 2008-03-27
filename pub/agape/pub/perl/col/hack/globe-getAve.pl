#!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="read surface data (from Ran..) and compiles averages";
#
$[ =1 ;
				# include libraries
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
require "ctime.pl";
require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
				# ------------------------------
				# defaults
$minLen=     30;		# minimal length
$maxLen=    200;		# maximal length
$maxLen=    100;		# maximal length
$fit1Add=     0.97;
$fitoAdd=     1.56;
$fit2Add=     0.02;
$fit2Fac=     0.46;
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
$fhin="FHIN"; # $fhout="FHOUT";
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

				# ------------------------------
				# (1) read file
&open_file("$fhin", "$fileIn");
$#id=$it=0;
$#dif1=$#dif2=$#difo=0;
while (<$fhin>) {
    next if ($_=~/^\#|^id|^No[\s\t]+|^4N/); # skip comments, names
    $_=~s/\n//g;		# id, len, n16P, n16O
    @tmp=split(/\t/,$_);foreach $tmp(@tmp){$tmp=~s/\s//g;}
    next if ( ($tmp[2]>$maxLen)||($tmp[2]<$minLen) );
    ++$it;
    $rd{"$it","id"}=  $tmp[1];push(@id,$tmp[1]);
    $rd{"$it","len"}= $tmp[2];
    $rd{"$it","n16p"}=$tmp[3];
    $rd{"$it","n16o"}=$tmp[4];
    push(@dif1,($tmp[3]-&funcNsurfaceFit1($tmp[2],$fit1Add)));
    push(@difo,($tmp[4]-&funcNsurfaceFit1($tmp[2],$fitoAdd)));
    push(@dif2,($tmp[3]-&funcNsurfaceFit2($tmp[2],$fit2Add,$fit2Fac)));
}close($fhin);
#$nprot=$it;
($ave1,$var1)=&stat_avevar(@dif1);$sig1=sqrt($var1);
($aveo,$varo)=&stat_avevar(@difo);$sigo=sqrt($varo);
($ave2,$var2)=&stat_avevar(@dif2);$sig2=sqrt($var2);

print "xx maxLen=$maxLen, minLen=$minLen\n";
printf "xx ave1=%6.3f sig1=%6.3f\n",$ave1,$sig1;
printf "xx ave2=%6.3f sig2=%6.3f\n",$ave2,$sig2;
printf "xx aveo=%6.3f sigo=%6.3f\n",$aveo,$sigo;

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

