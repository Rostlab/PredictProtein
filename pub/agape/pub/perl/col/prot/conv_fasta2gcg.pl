#!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="converts fasta formatted file into GCG format";
#
$[ =1 ;
				# include libraries
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
# require "ctime.pl"; 
require "lib-ut.pl"; require "lib-br.pl";
# require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";

if (defined $ENV{'ARCH'}){$ARCH=$ENV{'ARCH'};}
else { print "*** ERROR define cpu arch 'setenv ARCH SGI64|ALPHA'\n";
       die;}
$exeConvSeq="/home/rost/pub/phd/bin/convert_seq.".$ARCH;
				# help
if ($#ARGV<1){
    print "goal:\t $scrGoal\n";
    print "use: \t '$scrName file.fasta'\n";
    print "opt: \t fileOut=x  \n";
    print "     \t exeConvSeq=$exeConvSeq (default)\n";
#    print "     \t \n";
    exit;}
				# initialise variables
#$fhin="FHIN";$fhout="FHOUT";
				# read command line
$fileIn=$ARGV[1];
$tmp=$fileIn;$tmp=~s/^.*\///g;$fileOut=$tmp;$fileOut=~s/\..*$//g;$fileOut.=".gcg";

foreach $_(@ARGV){
    next if ($_ eq $ARGV[1]);
    if   ($_=~/^fileOut=(.*)$/){$fileOut=$1;}
#    elsif($_=~/^=(.*)$/){$=$1;}
    else {print"*** wrong command line arg '$_'\n";
	  die;}}
if (! -e $fileIn)    {print "*** ERROR missing input file $fileIn\n";
		      die;}
if (! -e $exeConvSeq){print "*** ERROR missing convert_seq $exeConvSeq\n";
		      die;}

				# ------------------------------
				# (1) read file
($Lok,$err)=
    &convFasta2gcg($exeConvSeq,$fileIn,$fileOut,"STDOUT");
if (! $Lok){print "*** missing output $fileOut \n";
	    print "*** ERROR : $err\n";}
else       {print "--- output in $fileOut\n";}
    
exit;
