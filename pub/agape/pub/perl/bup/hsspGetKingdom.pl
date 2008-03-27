#!/usr/sbin/perl -w
#
# extracts the kingdom for HSSP list
# 'script list fileHssp-swissId fileAllIdSwiss'
#
$[ =1 ;

				# include libraries
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
# require "ctime.pl"; 
require "lib-ut.pl"; require "lib-br.pl";
# require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
				# initialise variables

if ($#ARGV<3){print"goal:   extracts the kingdom for HSSP list\n";
	      print"usage:  'script list file1:hsspSwissId file2:allIdSwiss'\n";
	      print"        file1 contains 'pdbid\tswissId'\n";
	      print"              e.g.: ~/pub/data/hssp/hssp4951-swissId.list\n";
	      print"        file2 contains 'swissfile\tswissId\tkingdom'\n";
	      print"              e.g.: ~/pub/data/swiss/allId-swiss.list\n";
	      exit;}

$fileIn=         $ARGV[1];
$fileHssp2Swiss= $ARGV[2];
$fileSwissKing=  $ARGV[3];
$fhin="FHIN";$fhout="FHOUT";$fhoutTrace="FHOUT_TRACE";
$fileOut=$fileIn;$fileOut=~s/\..*$//g;$fileOut="Out-".$fileOut.".tmp";
$fileTrace=$fileOut; $fileTrace=~s/Out/Trace/;
$dirHssp="/data/hssp/";

				# ------------------------------
$#hssp=0;			# read the list
&open_file("$fhin", "$fileIn");
while (<$fhin>) {$_=~s/\s//g;$file=$_;
		 if (! -e $file){$file=$dirHssp."$_";}
		 if (! -e $file){print "*** no hssp '$file'\n";
				 next;}
		 push(@hssp,$file);}close($fhin);
				# ------------------------------
$#hsspId=0;			# extract ids
foreach $hssp(@hssp){
    $hssp=~s/^.*\///g;$hssp=~s/\..*$//g;
    $Lok{"$hssp"}=1;
    push(@hsspId,$hssp);}
				# ------------------------------
%hssp2swiss=0;			# read the HSSP to Swiss file
&open_file("$fhin", "$fileHssp2Swiss");
while (<$fhin>) {$_=~s/\n//g;
		 @tmp=split(/\t/,$_);
		 $id=$tmp[1];$id=~s/\s//g;
		 if (defined $Lok{"$id"}){
		     $idSwiss=$tmp[2];$idSwiss=~s/\s//g;
		     $Lok{"$idSwiss"}=1;
		     $hssp2swiss{"$id"}=$idSwiss;}}close($fhin);
				# ------------------------------
%swiss2king=0;			# read the Swiss kingdoms
&open_file("$fhin", "$fileSwissKing");
while (<$fhin>) {$_=~s/\n//g;
		 @tmp=split(/\t/,$_);
		 $id=$tmp[2];$id=~s/\s//g;
		 if (defined $Lok{"$id"}){
		     $king=$tmp[3];$king=~s/\s//g;
		     $swiss2king{"$id"}=$king;}}close($fhin);
				# write HSSP kingdom
&open_file("$fhout", ">$fileOut"); &open_file("$fhoutTrace", ">$fileTrace");
print $fhoutTrace "idHssp\tidSwiss\n";
print $fhout
    "# Perl-RDB\n",
    "# \n",
    "# kingdoms for HSSP files in $fileIn\n";
printf $fhout "%-6s\t%-15s\t%-10s\n","idHssp","idSwiss","kingdom";
printf $fhout "%-6s\t%-15s\t%-10s\n","6","15","10";

foreach $idHssp(@hsspId){
    $idSwiss=$hssp2swiss{"$idHssp"};
    if (defined $swiss2king{"$idSwiss"}){
	$king=$swiss2king{"$idSwiss"};
	printf "%-6s\t%-15s\t%-10s\n",$idHssp,$idSwiss,$king;
	printf $fhout "%-6s\t%-15s\t%-10s\n",$idHssp,$idSwiss,$king;
    }
    else {
	print $fhoutTrace "$idHssp\t$idSwiss\n";}
}
close($fhout);close($fhoutTrace);


print "--- fileOut=$fileOut, error in '$fileTrace'\n";
exit;
