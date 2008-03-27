#!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="runs the dssp extract";
#  
#
$[ =1 ;
				# include libraries
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
# require "ctime.pl"; 
require "lib-ut.pl"; require "lib-br.pl";
# require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
				# ------------------------------
				# defaults
$par{"dirDsspData"}=        "/data/dssp/";
$par{"exeExtrDsspRange"}=   "/home/rost/perl/scr/dsspExtrRange.pl";
$par{"dirDsspLoc"}=         "dsspDom";
$par{"extDssp"}=            ".dssp";
				# ------------------------------
				# help
if ($#ARGV<1){
    print "goal:\t $scrGoal\n";
    print "use: \t '$scrName file-with-domains (from orengo-domain-rd.pl)'\n";
    print "opt: \t \n";
    print "     \t dirDsspData=x      (default: ",$par{"dirDsspData"},")\n";
    print "     \t exeExtrDsspRange=x (default: ",$par{"exeExtrDsspRange"},")\n";
    print "     \t dirDsspLoc=x       (default: ",$par{"dirDsspLoc"},")\n";
    print "     \t extDssp=x          (default: ",$par{"extDssp"},")\n";
#    print "     \t \n";
    exit;}
				# initialise variables
$fhin="FHIN";
				# read command line
$fileIn=$ARGV[1];
$tmp=$fileIn;$tmp=~s/^.*\///g;$fileOut="Out-".$tmp;

foreach $_(@ARGV){
    next if ($_ eq $ARGV[1]);
    if   ($_=~/^dirDsspData=(.*)$/)     {$par{"dirDsspData"}=$1;}
    elsif($_=~/^exeExtrDsspRange=(.*)$/){$par{"exeExtrDsspRange"}=$1;}
    elsif($_=~/^dirDsspLoc=(.*)$/)      {$par{"dirDsspLoc"}=$1;}
    elsif($_=~/^extDssp=(.*)$/)         {$par{"extDssp"}=$1;}
#    elsif($_=~/^=(.*)$/){$=$1;}
    else {print"*** wrong command line arg '$_'\n";
	  die;}}
$dirDsspData= &complete_dir($par{"dirDsspData"});
$dirDsspLoc=  &complete_dir($par{"dirDsspLoc"});
$exe=         $par{"exeExtrDsspRange"};

				# ------------------------------
				# (1) read file
$#fileOk=0;
&open_file("$fhin", "$fileIn");
while (<$fhin>) {
    $_=~s/\n//g;
    next if ($_=~/^no|^id/);
				# ------------------------------
				# get range, chain, asf
    @tmp=split(/\t/,$_);
    $idx=$tmp[2];$idx=~s/\*/0/g;$id=$tmp[4];
    $chain=$tmp[5];$chain=~s/\*/0/g;$range=$tmp[6];$len=$tmp[3];$len=~s/\s//g;
    $fileDssp=$dirDsspData.$id.$par{"extDssp"};
    $fileOut= $dirDsspLoc.$idx.$par{"extDssp"};
				# ------------------------------
				# check existence
    if (! -e $fileDssp){
	print "*** fileDssp '$fileDssp' missing\n";
	next;}
				# ------------------------------
				# call dsspExtrDsspRange
    $cmd="$exe $fileDssp $chain pdbNo=$range fileOut=$fileOut ";
    print "--- system \t '$cmd'\n";
    system("$cmd");		# external script

    next if (! -e $fileOut );
    push(@fileOk,$fileOut);
}close($fhin);
print "--- output files =";foreach $fileOk(@fileOk){print "$fileOk,";}print "\n";
exit;
