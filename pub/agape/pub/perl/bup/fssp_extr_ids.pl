#!/usr/sbin/perl -w
#
# extracts pdb'ids from FSSP file
#
$[ =1 ;

push (@INC, "/home/rost/perl", "/u/rost/perl") ;
# require "ctime.pl";		# require "rs_ut.pl" ; 
require "lib-ut.pl"; require "lib-br.pl";
# require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";

if ($#ARGV<1){print"goal:   extracts PDBid's from FSSP file\n";
	      print"usage:  script list-of-files (or as many arg's)\n";
	      print"option: get=id1,id2 (i.e. a list of id's to be grepped)\n";
	      exit;}
$fhin="FHIN";$fhout="FHOUT";
$par{"dirFssp"}="/data/fssp/";
$LnotScreen=0;

$fileIn=$ARGV[1];$#fileIn=0;
$fileOut=$fileIn; $fileOut=~s/^.*\///g;$fileOut="PDBid".$fileOut.".tmp";
$#idSearch=0;

foreach $arg(@ARGV){if    ($arg=~/^get=/){$arg=~s/^get=//g;@idSearch=split(/,/,$arg);
					  last;}
		    elsif ($arg=~/^not_screen|^notScreen/){$LnotScreen=1;
							   last;}}
if (&is_fssp_list($fileIn)){
    &open_file("$fhin", "$fileIn");
    while (<$fhin>) {$_=~s/\n//g;
		     if (! -e $_){next;}
		     push(@fileIn,$_);}close($fhin);}
else {
    foreach $arg(@ARGV){if ($arg=~/^get=/){next;}
			$tmp=$par{"dirFssp"}."$arg";
			if    (-e $arg){push(@fileIn,$arg);}
			elsif (-e $tmp){push(@fileIn,$tmp);}}}

				# read all
&open_file("$fhout", ">$fileOut");
foreach $fileIn (@fileIn){
    $#id=0;
    &open_file("$fhin", "$fileIn");
    while (<$fhin>) {last if (/^  NR\./);}
    while (<$fhin>) {$_=~s/\n//g;if ($_ !~/\S/){next;}
		     last if (/^\#\#/);
		     $id=substr($_,14,6);$id=~s/\s|-//g;
		     if ($#idSearch>0){
			 foreach $idSearch(@idSearch){
			     if ($idSearch eq $id){
				 push(@id,$id);
				 last;}}}
		     else{
			 push(@id,$id);}}close($fhin);
    print $fhout "for '$fileIn',",$#id," hits\n";
    foreach $id(@id){print $fhout "$id,";}print $fhout "\n"; 
    print "for '$fileIn',",$#id," hits\n";
    foreach $id(@id){print "$id,";}print "\n";
}close($fhout);

if (! $LnotScreen){ print "--- output in $fileOut\n"; }
exit;
