#!/usr/sbin/perl -w
#
# reads SWISS-PROT list, returns first residues and location
#
$[ =1 ;

				# include libraries
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
require "ctime.pl";
require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
				# initialise variables

if ($#ARGV<1){print"goal:   reads SWISS-PROT list, returns first residues and location\n";
	      print"usage:  statTranslocation.pl swiss-files (or list)\n";
	      exit;}

$fileIn=$ARGV[1];
$fhin="FHIN";$fhout="FHOUT";
$fileOut="Out-".$fileIn; if ($#ARGV>1){$fileOut="Out-translocation.tmp";}
@txtLoci=("CYTOPLASMIC","EXTRACELLULAR","NUCLEAR");
$outLoci{CYTOPLASMIC}="cyt";$outLoci{EXTRACELLULAR}="ext";$outLoci{NUCLEAR}="nuc";
$nresWrt=40;

$#file=0;
foreach $arg (@ARGV){
    if (! -e $arg){print "*** file '$arg' missing\n";
		   exit;}
    if (&isSwissList($arg)){&open_file("$fhin", "$arg");
			    while (<$fhin>) {$_=~s/\n//g;
					     if (-e $_){push(@file,$_);}}close($fhin);}
    elsif (&isSwiss($arg)){
	push(@file,$arg);}}

				# now loop over SWISS-PROT files
&open_file("$fhout", ">$fileOut");
foreach $file (@file){
    print "xx reading '$file'\n";
    &open_file("$fhin", "$file");
    $loc="unk";$seq="";
    while (<$fhin>) {$_=~s/\n//g;
		     if (/^.*SUBCELLULAR LOCATION:\s+(.+)$/){
			 $lineLoc=$_;
			 $loc=$1;}
		     elsif (/^\s+/){
			 $_=~s/\s//g;
			 $seq.=$_;}}close($fhin);
    $Lok=0;
    foreach $txt (@txtLoci){if ($loc =~/$txt/){$loc=$outLoci{$txt};
					       $Lok=1;
					       last;}}if (! $Lok){$loc="unk";}
    $id=$file;$id=~s/^.*\///g;
    print "xx id=$id, loc=$loc, line=$lineLoc,\n";
    print $fhout "$id\t$loc\t",substr($seq,1,$nresWrt),"\n";
    print "$id\t$loc\t",substr($seq,1,$nresWrt),"\n";
    
}close($fhout);
exit;
