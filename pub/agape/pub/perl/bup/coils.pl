#!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="runs the program COILS from Lupas";
#  
#
$[ =1 ;
				# include libraries
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
# require "ctime.pl"; 
require "lib-ut.pl"; require "lib-br.pl";
# require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";

				# defaults
if (defined $ENV{'ARCH'}){$ARCH=$ENV{'ARCH'};}
else { print "*** ERROR define cpu arch 'setenv ARCH SGI64|ALPHA'\n";
       die;}
$exeCoils= "/home/phd/bin/".$ARCH."/coils";
$metric=   "MTK";		# metric 1
#$metric=   "MTIDK";		# metric 2
#$optOut=   "row";		# row-wise output (probabilities projected)
#$optOut=   "cutoff";		# user defined cut-off for reporting prob
#$optOut=   "winsize";		# size of window def = 14, 21, 28
$optOut=   "col";		# column-wise output (probabilities)
$minProb=  0.5;			# minimal probability to report coiled-coils

				# help
if ($#ARGV<1){
    print "goal:\t $scrGoal\n";
    print "use: \t '$scrName file'\n";
    print "opt: \t exe=$exeCoils   (default)\n";
    print "     \t fileOut=x\n";
    print "     \t metr=$metric    (possible = MTK|MTIDK)\n";
    print "     \t opt=$optOut     (possible = col|row|winsize=|cutoff=)\n";
    print "     \t =x\n";
#    print "     \t \n";
    exit;}
				# initialise variables
#$fhin="FHIN";$fhout="FHOUT";
				# read command line
$fileIn=$ARGV[1];
$tmp=$fileIn;$tmp=~s/^.*\///g;$fileOut=$tmp;$fileOut=~s/\..*$//g;$fileOut.=".coils";

foreach $_(@ARGV){
    next if ($_ eq $ARGV[1]);
    if   ($_=~/^fileOut=(.*)$/){$fileOut=$1;}
    elsif($_=~/^exe=(.*)$/)    {$exeCoils=$1;}
    elsif($_=~/^metr=(.*)$/)   {$metric=$1;}
    elsif($_=~/^opt=(.*)$/)    {$optOut=$1;}
#    elsif($_=~/^=(.*)$/){$=$1;}
    else {print"*** wrong command line arg '$_'\n";
	  die;}}

if (! -e $fileIn)  {print "*** ERROR missing input file $fileIn\n";
		    die;}
if (! -e $exeCoils){print "*** ERROR missing coils exe $exeCoils\n";
		    die;}

				# run
($Lok,$err)=
    &coilsRun($fileIn,$fileOut,$exeCoils,$metric,$optOut,"STDOUT");
die("*** $scrName: coilsRun ($fileIn,$fileOut,$exeCoils,$metric,$optOut) failed: $err\n") 
    if (! $Lok);
				# ------------------------------
$fileTmp=$fileOut."_2";		# analyse results
($Lok,$err)=
    &coilsRd($fileOut,$fileTmp,$minProb,"STDOUT");

if    ($Lok == 2){		# below threshold
    $fileTmp=~s/\..*$/\.notCoils/g;
    system("echo 'no coiled-coil above $minProb' >> $fileTmp");}
elsif ($Lok == 1){		# may be coiled-coil
    $fileTmp2=$fileTmp;$fileTmp2=~s/\..*$/\.coilsSyn/g;
    system("\\mv $fileTmp $fileTmp2");
    print "--- is coiled coil $fileOut (syn=$fileTmp2)\n";}
elsif ($Lok == 0){		# not coiled-coil
    unlink($fileTmp);
    print "--- no coiled coil $fileOut\n";}
exit;

