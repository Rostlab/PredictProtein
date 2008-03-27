#!/usr/sbin/perl -w
# converts a  list of PDB'ids(1pdbC) to H/F/D/ssp (/data/hssp/1pdb.hssp_C)
#
$[ =1 ;

push (@INC, "/home/rost/perl") ;
# require "ctime.pl";		# require "rs_ut.pl" ; 
require "lib-ut.pl"; require "lib-br.pl";
# require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";

@opt=("dssp","hssp","fssp","dir","ext");
if ($#ARGV<1){print"goal :  converts list of id's 1pdbC into '/data/hssp/1pdb.hssp_C'\n";
	      print"usage:  'script file' \n";
	      print"option: (default hssp) ";&myprt_array(",",@opt);
	      exit;}

$file_in=$ARGV[1];$fileOut=$file_in."_out";
$fhin="FHIN";$fhout="FHOUT";
$par{"mode"}="hssp";
$par{"dir"}= "unk";
$par{"ext"}= "unk";
				# read online arguments
foreach $arg(@ARGV){
    if ($arg=~/^[hdf]ssp/){
	$arg=~s/^([dhf]ssp).*$/$1/g;$par{"mode"}=$arg;}
    else {
	foreach $opt(@opt){if ($arg =~/^$opt=/){$arg=~s/^$opt=//g;$par{"$opt"}=$arg;
						 last;}}}}
				# process input
if ($par{"dir"} eq "unk"){$par{"dir"}="/data/".$par{"mode"}."/";}
if ($par{"ext"} eq "unk"){$par{"ext"}=".".$par{"mode"};}

&open_file("$fhin", "$file_in");&open_file("$fhout", ">$fileOut");
while (<$fhin>) {$_=~s/\n|\s//g;$_=~s/_//g;
		 if (length($_)>4){$id=substr($_,1,4);$chain=substr($_,5,1);}
		 else {$id=$_;$chain="";}
		 if ($par{"mode"}=~/^[dh]ssp/){
		     $file=$par{"dir"}.$id.$par{"ext"};
		     if (length($chain)>0){$fileX=$file."_"."$chain";}else{$fileX=$file;}}
		 else {
		     $file=$fileX=$par{"dir"}.$id.$chain.$par{"ext"};}
			 
		 if (-e $file){print $fhout $fileX,"\n";}else {print"*** missing $fileX\n";}}
			       
close($fhin);close($fhout);

print"output in $fileOut\n";
exit;
