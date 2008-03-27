#!/usr/sbin/perl -w
#----------------------------------------------------------------------
# xscriptname
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# usage: 	xscriptname.pl xscriptin
#
# task:		reads the FSSP table families
# 		
# subroutines   (internal):  
#               x
#                                  y
# 		
#
#----------------------------------------------------------------------#
#	Burkhard Rost		       April	,       1995           #
#			changed:       .	,    	1995           #
#	EMBL				Version 0.1                    #
#	Meyerhofstrasse 1                                              #
#	D-69117 Heidelberg		(rost@EMBL-Heidelberg.DE)      #
#----------------------------------------------------------------------#
				# sets array count to start at 1, not at 0
$[ =1 ;
				# include libraries
push (@INC, "/home/rost/perl") ;
# require "ctime.pl";		# require "rs_ut.pl" ; 
require "lib-ut.pl"; require "lib-br.pl";
# require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
                                # defaults
$fhin=    "FHIN";
$level=   1;                    # number of levels of tree read
$max_level=6;                   # maximal level in table

$fhout=   "FHOUT";$fhout2=  "FHOUT2";
$file_out=     "fssp-unique.list";
$fileDsspAll=  "dssp-all.list";
$fileDsspAllNo="dssp-all-noChain.list";
$fileHsspAll=  "hssp-all.list";
$fileHsspAllNo="hssp-all-noChain.list";
$fileHsspUni=  "hssp-uni.list";
$fileHsspUniNo="hssp-uni-noChain.list";

$file_in=$ARGV[1]; if ($#ARGV<1){print"input:   1 \t TABLE1 from /data/fssp \n";
                                 print"optional:2 \t n, take level n\n";
				 print"***        \t is a lie, not implemented!\n";
                                 exit;}
if ($#ARGV>1) { 
    $level=$ARGV[2];}

# --------------------------------------------------------------------------------
# do the job (here we go)
# --------------------------------------------------------------------------------

&open_file("$fhin", "$file_in");
while (<$fhin>) {               # read until "Family index"
    last if (/Family index/); }
$ct[$level]=$#idall=0;
while (<$fhin>) {
    if (! /^\s*\d*\./) {next;}
    $_=~s/^\s*|\s*\n$//g;          # purge leading blanks
                                # everything before SWISS name
    $tmp=$_;$tmp=~s/([\d\.]*\s+\S*).+/$1/;
    $name=$_;$name=~s/$tmp\s*//g; # SWISS name
    $name=~s/\(.+\)//g;$name=~s/\s\s+/ /g;   # purge (E.C. asf) and double blanks
    @tmp=split(/ +/,$tmp);      # seperate number and PDBID
    $num=$tmp[1];$num=~s/\s//g;
    $id=$tmp[2]; $id=~s/\s|[_-]//g;
    @num=split(/\./,$num);      # seperate levels
    $Lok=1;                     # take it if all counters > level =1
    foreach $i (($level+1)..$max_level) { if ($num[$i] != 1) {$Lok=0;last;} }
    if ( $Lok && ( ! defined $L1st{"$num[1]"} ) ) {
        $L1st{"$num[1]"}=1;
        ++$ct[$level];
        print"x.x $num,$ct[$level],id=$id,\n";
        $id{"$level","$ct[$level]"}=$id;
        $name{"$level","$ct[$level]"}=$name;}
    push(@idall,$id);
}
close($fhin);
                                # print info read
print "read:\n";
foreach $ct (1..$ct[$level]) {
    print"$ct\t",$id{"$level","$ct"},"\t",$name{"$level","$ct"},"\n";
}
				# --------------------------------------------------
				# write fssp
                                # sort fssp ids
$#tmp=0;
foreach $ct (1..$ct[$level]) {push(@tmp,$id{"$level","$ct"});}
@id=&sort_by_pdbid(@tmp);

foreach $id (@id){ print "$id,";}print"\n"; # 
				# ------------------------------
				# write into file: unique FSSP
&open_file("$fhout", ">$file_out");
foreach $id (@id){ 
    print $fhout "/data/fssp/$id",".fssp\n";}close($fhout);

				# --------------------------------------------------
				# write dssp
                                # sort dssp ids
@idUni=@id;
@id=&sort_by_pdbid(@idall);
foreach $id (@id){ print "$id,";}print"\n"; # 
				# ------------------------------
				# write into file : all DSSP
&open_file("$fhout", ">$fileDsspAll");&open_file("$fhout2", ">$fileDsspAllNo");
undef %tmp;
foreach $id (@id){ 
    $idx=substr($id,1,4);$tmp="$idx".".dssp";
    if (length($id)>4){$chainHere=substr($id,5,1);}else{$chainHere="unk";}
    ($file,$chainRd)=&dsspGetFile($tmp,1);
    if (($file ne "0")&&(defined $chainRd)&&
	(length ($chainRd)>0)&&($chainRd ne $chainHere)&&($chainHere ne "unk")){
	print "-?- \t from dsspGetFile: chainRd=$chainRd, local chainHere=$chainHere,\n";}
    if (-e $file){
	if (! defined $tmp{$file}){
	    $tmp{$file}=1;
	    print $fhout2 "$file\n";} # no chain
	if ($chainHere ne "unk"){$tmp2=$file."_"."$chainHere";}else{$tmp2=$file;}
	print $fhout $tmp2,"\n";}
    else {
	print "*   missing DSSP in=$tmp, out dsspGetFile=$file,\n";}}
close($fhout);close($fhout2);
				# ------------------------------
				# unique HSSP (write)
&open_file("$fhout", ">$fileHsspUni");&open_file("$fhout2", ">$fileHsspUniNo");
undef %tmp;
foreach $id (@idUni){ 
    $idx=substr($id,1,4);$tmp="$idx".".hssp";
    if (length($id)>4){$chainHere=substr($id,5,1);}else{$chainHere="unk";}
    ($file,$chainRd)=&hsspGetFile($tmp,1);
    if (($file ne "0")&&(length ($chainRd)>0)&&($chainRd ne $chainHere)&&($chainHere ne "unk")){
	print "-?- \t from hsspGetFile: chainRd=$chainRd, local chainHere=$chainHere,\n";}
    if (-e $file){
	if (! defined $tmp{$file}){
	    $tmp{$file}=1;
	    print $fhout2 "$file\n";} # no chain
	print $fhout2 "$file\n"; # no chain
	if ($chainHere ne "unk"){$tmp2=$file."_!_"."$chainHere";}else{$tmp2=$file;}
	print $fhout $tmp2,"\n";}
    else {
	print "*   missing HSSP in=$tmp, out hsspGetFile=$file,\n";}}close($fhout);close($fhout2);

				# ------------------------------
				# all HSSP (write)
&open_file("$fhout", ">$fileHsspAll");&open_file("$fhout2", ">$fileHsspAllNo");
foreach $id (@id){ 
    $idx=substr($id,1,4);$tmp="$idx".".hssp";
    if (length($id)>4){$chainHere=substr($id,5,1);}else{$chainHere="unk";}
    ($file,$chainRd)=&hsspGetFile($tmp,1);
    if (($file ne "0")&&(length ($chainRd)>0)&&($chainRd ne $chainHere)&&($chainHere ne "unk")){
	print "-?- \t from hsspGetFile: chainRd=$chainRd, local chainHere=$chainHere,\n";}
    if (-e $file){
	print $fhout2 "$file\n"; # no chain
	if ($chainHere ne "unk"){$tmp2=$file."_"."$chainHere";}else{$tmp2=$file;}
	print $fhout $tmp2,"\n";}}close($fhout);close($fhout2);

# --------------------------------------------------------------------------------
# work done
# --------------------------------------------------------------------------------
&myprt_txt(" ended fine .. -:\)"); 
&myprt_txt(" output in file: \t $file_out"); 
&myprt_txt(" dssp in file:   \t $fileDsspAll,$fileDsspAllNo"); 
&myprt_txt(" Hssp in files:  \t $fileHsspAll,$fileHsspAllNo,$fileHsspUni,$fileHsspUniNo"); 


exit;
