#!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="runs the dssp extract, do max stuff for domains";
#  
#
$[ =1 ;
				# include libraries
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
require "ctime.pl";
require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
				# ------------------------------
				# defaults
$par{"dirDssp"}=         "/data/dssp/";
$par{"dirHssp"}=         "/data/hssp/";
$par{"exeExtrDsspRange"}="dsspExtrRange.pl";
				# ------------------------------
				# help
if ($#ARGV<1){
    print "goal:\t $scrGoal\n";
    print "use: \t '$scrName file-with-domains (from orengo-domain-rd.pl)'\n";
    print "opt: \t \n";
    print "     \t fileOut=x\n";
#    print "     \t \n";
    exit;}
				# initialise variables
$fhin="FHIN";
				# read command line
$fileIn=$ARGV[1];
$tmp=$fileIn;$tmp=~s/^.*\///g;$fileOut="Out-".$tmp;

foreach $_(@ARGV){
    next if ($_ eq $ARGV[1]);
    if   ($_=~/^fileOut=(.*)$/){$fileOut=$1;}
#    elsif($_=~/^=(.*)$/){$=$1;}
    else {print"*** wrong command line arg '$_'\n";
	  die;}}

				# ------------------------------
				# (1) read file
$exe=$par{"exeExtrDsspRange"};$dirDssp=$par{"dirDssp"};$dirHssp=$par{"dirHssp"};
$#fileOk=0;
&open_file("$fhin", "$fileIn");
while (<$fhin>) {$_=~s/\n//g;
		 next if ($_=~/^no|^id/);
		 @tmp=split(/\t/,$_);
		 $idx=$tmp[2];$idx=~s/\*/0/g;$id=$tmp[4];
		 $chain=$tmp[5];$chain=~s/\*/0/g;$range=$tmp[6];
		 $fileDssp=$dirDssp.$id.".dssp";$fileHssp=$dirHssp.$id.".hssp";
		 $fileOut=$idx.".hssp";

		 $cmd="$exe $fileDssp $chain $range fileHssp=$fileHssp fileOut=$fileOut ";
		 print "--- system \t '$cmd'\n";
		 system("$cmd");
				# hssp self
		 if (! -e $fileOut || &is_hssp_empty($fileOut)){
		     print "--- running self out=$fileOut\n";
		     $Lok=$err=0;
		     ($Lok,$err)=
			 &maxhomRunSelf(" ",$par{"exeMax"},$par{"fileMaxDef"},$$,$fileDssp,
					$fileOut,$par{"fileMaxMat"},"STDOUT");}
		 if (-e $fileOut && ! &is_hssp_empty($fileOut)){
		     push(@fileOk,$fileOut);}}
close($fhin);
print "--- output files =";foreach $fileOk(@fileOk){print "$fileOk,";}print "\n";
exit;
