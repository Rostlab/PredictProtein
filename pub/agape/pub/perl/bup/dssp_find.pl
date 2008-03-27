#!/usr/sbin/perl -w
$[ =1 ;

# finds the DSSP files for a given list of ids or files (/data/x/*.dfhssp_A ignored)

push (@INC, "/home/rost/perl") ;
# require "ctime.pl";		# require "rs_ut.pl" ; 
require "lib-ut.pl"; require "lib-br.pl";
# require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";

if ( ($#ARGV<1) || &isHelp($ARGV[1])){
    print"goal:  find valid DSSP files (chain as: _C or fourth character\n";
    print"usage: 'script list_of_ids (or files)\n";
    exit;}

$file_in=$ARGV[1];

$fhin="FHIN";$fhoutOk="FHOUT_Ok";$fhoutNot="FHOUT_NOT";
$fileOutOk=$file_in."_ok";
$fileOutNot=$file_in."_not";
@dir=("/data/dssp/","/sander/purple1/rost/data/dssp/","/home/rost/dssp/");

&open_file("$fhin", "$file_in");
&open_file("$fhoutOk", ">$fileOutOk");&open_file("$fhoutNot", ">$fileOutNot");
$ctOk=$ctNot=0;
while (<$fhin>) {
    $_=~s/\n|\s//g;
    if (/_.$/){$chain=$_;$chain=~s/^.*_(\w)$/$1/;}else{$chain="";}
    $_=~s/^.*\///g;$_=~s/\..*$//g;$tmp=$_.".dssp";
    if ((length($chain)==0) && (length($_)==5) ){$chain=substr($_,5,1);}
    $file=&dsspGetFile($tmp,1,@dir);
    if (-e $file){
	++$ctOk;
	if (length($chain)>0){ $fileOut=$file."_"."$chain";}else{$fileOut=$file;}
	print $fhoutOk $fileOut,"\n";}
    else {
	++$ctNot;
	print $fhoutNot $tmp," (chain=$chain)\n";}
}
close($fhin);close($fhoutOk);close($fhoutNot);
print "ok=$ctOk ($fileOutOk)  , not=$ctNot ($fileOutNot)\n";
exit;
