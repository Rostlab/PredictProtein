#!/usr/bin/perl
##!/bin/env perl
#------------------------------------------------------------------------------#
# other perl environments
# EMBL
##!/usr/sbin/perl4 -w
##!/usr/sbin/perl -w
# EBI
##!/usr/bin/perl -w
#------------------------------------------------------------------------------#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$scriptName=   "phd2hssp";
$scriptIn=     "id.rdb_phd id.hssp (or id)";
$scriptTask=   "write PHD output (from RDB) into HSSP file";
$scriptNarg=   1;
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# subroutines   (internal):  
#
#------------------------------------------------------------------------------#
#	Copyright				May,    	1997	       #
#	Burkhard Rost		rost@EMBL-Heidelberg.DE			       #
#	EMBL			http://www.embl-heidelberg.de/~rost/	       #
#	D-69012 Heidelberg						       #
#				version 0.1   	May,    	1997	       #
#------------------------------------------------------------------------------#
				# sets array count to start at 1, not at 0
$[ =1 ;
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
# require "ctime.pl"; 
require "lib-ut.pl"; require "lib-br.pl";
# require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
				# intermediate x.x

#@ARGV=split(/\s+/,&get_in_keyboard("command line"));	# x.x mac specific

				# ------------------------------
$Lok=&ini;			# initialise variables
if (! $Lok){ die; }

				# ------------------------------
				# file with list or list of files?
if (($#fileIn == 1)&&(! &isRdb($fileIn[1]))){
    $fileIn=$fileIn[1];
    $#fileIn=$Lerror=0;
    &open_file("$fhin","$fileIn");
    while(<$fhin>){$_=~s/\s//g;$file=$_;
		   if (! -e $file){$file=$_.$par{"extPhd"};}
		   if (! -e $file){$file=$_.$par{"extPhd"};}
		   if (! -e $file){
		       next;}
		   push(@fileIn,$file);}close($fhin);}

#-------------------------------------------------------------------------------
# do the job (here we go)
#-------------------------------------------------------------------------------
				# --------------------------------------------------
				# loop over all files
				# --------------------------------------------------
foreach $fileIn(@fileIn){
    $id=$fileIn;$id=~s/\/.*\///g;$id=~s/\s|\n|\.rdb.*$//g;$id=~s/^.*\///g;
				# read PHD.rdb file
    if ($Lverb) { print "--- reading PHD     \t $fileIn\n"; }
    $Lok=&rdPhdRdb($fileIn);
    if (! $Lok){print "*** ERROR ($scriptName): $fileIn (phd_rdb)\n";
		next;}
				# read HSSP file
    $fileInHssp=$par{"dirHssp"}.$id.$par{"extHssp"};
    if ($Lverb) { print "--- reading HSSP     \t $fileInHssp\n"; }
    $Lok=&rdHssp($fileInHssp);
    if (! $Lok){print "*** ERROR ($scriptName): $fileInHssp (HSSP)\n";
		next;}

    if ($Lverb) { print "--- writing          \t $fileOut\n"; }
    &wrtHsspPhd($fileOut);
}

if ($Lverb2){ print "--- $scriptName finished its task\n";}

#===============================================================================
sub ini {
    local (@scriptTask,@scriptHelp,@scriptKwd,@scriptKwdDescr,$txt);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   ini                         initialises variables/arguments
#-------------------------------------------------------------------------------
#	$date is e.g.:		Thu Oct 14, 1993 13:06:47
#	@Date is e.g.:		Oct,14,13:06:47,1993
#	&ctime(time) is e.g.:	Thu Oct 14 13:06:47 1993
#
    @Date = split(' ',&ctime(time)) ; 
    $dateLong="$Date[1] $Date[2] $Date[3], $Date[6] ($Date[5]:$Date[4])"; 
    $date="$Date[2] $Date[3], $Date[6]"; 
#    $PWD=                       $ENV{'PWD'}; $pwd=&complete_dir($PWD);
    $ARCH=                      $ENV{'ARCH'}; 
    if (!defined $ARCH)         {print "-*- WARNING \t no architecture defined\n";}

    &iniDefaults;               # first settings for parameters (may be overwritten by
				# default file and command line input)
    &iniHelp;

    $Lok=&iniGetArg;		# read command line input
    if (! $Lok){print "*** ini ($scriptName) ERROR in  iniGetArg\n";
		return(0);}

    $Lok=&iniChangePar;
    if (! $Lok){print "*** ini ($scriptName) ERROR in  iniChangePar\n";
		return(0);}

    if ($Lverb){&myprt_line; 
		print "--- Settings of $scriptName are:\n--- \n"; 
		if ($#fileIn==1) {printf "--- %-20s '%-s'\n","fileIn:",$fileIn[1]; }
		else {&myprt_txt("input files:  \t ");
		      foreach $_(@fileIn){printf "--- %-20s '%-s'\n"," ",$_;}}
		if ($#fileOut==1){printf "--- %-20s '%-s'\n","fileOut:",$fileOut[1]; }
		else {&myprt_txt("output files:  \t ");
		      foreach $_(@fileOut){if (!  $_){next;}
					   printf "--- %-20s '%-s'\n"," ",$_;}}
		foreach $kwd (@kwdDef) {
		    if ($kwd=~/^fileOut|^fileIn/){
			next;}
		    if (! defined $par{"$kwd"}){$tmp="!! UNDEF !!";}else{$tmp=$par{"$kwd"};}
		    if ((length($tmp)<1)||($tmp eq "unk")){
			next;}
		    printf "--- %-20s '%-s'\n",$kwd,$tmp;}&myprt_line;}

    # ------------------------------------------------------------
    # check existence of file
    # ------------------------------------------------------------
    $Lmiss=0;
    foreach $kwd(@kwdDef){
	if ($kwd =~/^(fileIn|exe)/){
	    if ((! defined  $par{"$kwd"})||(length($par{"$kwd"})<1)){
		next;}
	    if ($kwd=~/^fileIn/){$tmp1=$kwd;$tmp1=~s/fileIn/do/;
				 $tmp2=$kwd;$tmp2=~s/fileIn/read/;
				 if ((! $par{"$tmp1"})&&(! $par{"$tmp2"})){
				     next;}}
	    if (! -e $par{"$kwd"}){
		printf "*** %-20s '%-s'\n","MISSING $kwd",$par{"$kwd"};$Lmiss=1;}}}
    if ($Lmiss){
	print "*** try to locate the missing files/executables before continuing!\n";
	print "*** left script '$scriptName' after ini date: $date\n";
	return(0);}
    return(1);
}				# end of ini

#===============================================================================
sub iniHelp {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iniHelp                     initialise help text
#-------------------------------------------------------------------------------
    @scriptTask=   (" ",
		     "Task: \t $scriptTask",
		     " ",
		     "Input:\t $scriptIn",
		     " ",
		     "Done: \t ");
    @scriptHelp=   ("Help: \t For further information on input options asf., please  type:",
		     "      \t '$scriptName help'",
		     "      \t ............................................................");
    @scriptKwd=     (" ",
		     "title=",
		     " ",
		     "not_screen",
		     "dirIn=",
		     "dirOut=",
		     "dirWork=",
		     );
    @scriptKwdDescr=(" ", 
		     "title of output files",
		     " ",
		     "no information written onto screen",
		     "input directory        default: local",
		     "output directory       default: local",
		     "working directory      default: local ",
		     );

    if ( ($ARGV[1]=~/^help|^man|^-h/) ) { 
	print "-" x 80,"\n"; &myprt_txt("Perl script"); 
	foreach $txt (@scriptTask) {if($txt !~ /Done:/){&myprt_txt("$txt");}} 
	&myprt_txt("Optional:");
	foreach $kwdOpt(@kwdDef){
	    if (! defined $par{"$kwdOpt"}){$tmp="undef";}else{$tmp=$par{"$kwdOpt"};}
	    printf "--- %-12s=x \t (def:=%-s) \n",$kwdOpt,$tmp;}
	&myprt_empty; print "-" x 80,"\n"; die; }
    elsif ( $#ARGV < $scriptNarg ) {
	print "-" x 80,"\n"; &myprt_txt("Perl script"); 
	foreach $txt (@scriptTask) {if($txt !~ /Done:/){&myprt_txt("$txt");}} 
	&myprt_txt("Optional:");
	foreach $txt (@scriptHelp){&myprt_txt("$txt");}
	&myprt_empty;print"-" x 80,"\n";die;}
}				# end of iniHelp

#===============================================================================
sub iniDefaults {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iniDefaults                 initialise defaults
#-------------------------------------------------------------------------------
				# --------------------
				# directories
    $par{"dirIn"}=              ""; # directory with input files
    $par{"dirOut"}=             ""; # directory for output files
    $par{"dirWork"}=            ""; # working directory
				# databases
    $par{"dirHssp"}=            "";
    $par{"dirPhd"}=             "";
				# --------------------
				# files
    $par{"title"}=              "unk"; # output files will be called 'Pre-title.ext'
    $par{"extOut"}=             ".hssp_phd";
    $par{"extHssp"}=            ".hssp";
    $par{"extPhd"}=             ".rdb_phd";
    $par{"chain"}=              "";
    $par{"fileOut"}=            "";
				# file handles
    $fhout=                     "FHOUT";
    $fhin=                      "FHIN";
				# --------------------
				# logicals
    $Lverb=                     0; # blabla on screen
    $Lverb2=                    0; # more verbose blabla
    $par{"verbose"}=$Lverb;$par{"verbose2"}=$Lverb2;
				# ------------------------------
				# a.a descriptors 
				# allowed in default file
				# ------------------------------
    @kwdDef=     ("debug","verbose","verbose2",
		  "dirIn","dirOut","dirWork","dirHssp","dirPhd",
		  "title","extOut","extHssp","extPhd","fileOut","chain",
		  );
    @kwdRdb=     ("No","AA","PHEL","RI_S","PACC","RI_A");
}				# end of iniDefaults

#===============================================================================
sub iniGetArg {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iniGetArg                   read command line arguments
#-------------------------------------------------------------------------------
    $Lokdef=0; $#fileIn=$#tmp=0;
    foreach $arg (@ARGV){	# key word driven input
	if    ( $arg=~ /verbose3/ )    { $Lverb3=1; }
	elsif ( $arg=~ /verbose2/ )    { $Lverb2=1; }
	elsif ( $arg=~ /verbose/ )     { $Lverb=1; }
	elsif ( $arg=~ /not_verbose/ ) { $Lverb=0; }
	else {			# general
	    $Lok=0;
	    foreach $kwd (@kwdDef){ # 
		if ($arg=~/^$kwd=(.+)$/){$tmp=$1;$tmp=~s/\s//g;
					 if ($kwd =~/^dir/){ # add '/' at end of directories
					     $tmp=&complete_dir($tmp);}	# external lib-ut.pl
					 $par{"$kwd"}=$tmp; $Lok=1;$Lokdef=1;
					 last;}}
	    if    ((! $Lok)&&($arg=~/=/)){
		print "*** iniGetArg: unrecognised argument: $arg\n";
		return(0);}
	    elsif ((! $Lok)&&(-e "$arg")){ # input file?
		push(@fileIn,$arg);}
	    elsif (!$Lok){	# possibly add dirIn
		print "x.x still missing '$arg'\n";
		push(@tmp,$arg);}}}
    foreach $tmp (@tmp){	# check unrecognised input arguments
	$tmp1=$par{"dirIn"}.$tmp;
	if (-e "$tmp1"){push(@fileIn,$tmp1);}
	else { print "*** iniGetArg: unrecognised argument(2): '$tmp'\n";
	       return(0);}}	# 
    return(1);
}				# end of iniGetArg

#===============================================================================
sub iniChangePar {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iniChangePar                changing parameters according to input arguments
#                               e.g. adding directories to file names asf
#-------------------------------------------------------------------------------
    $#tmp=0;			# purge empty keywords
    foreach $kwd (@kwdDef){
	push(@tmp,$kwd) unless ((! defined $kwd)||(length($kwd)<1));}
    @kwdDef=@tmp;
				# ------------------------------
				# add input directory
    if ((defined $par{"dirIn"})&&($par{"dirIn"} ne "unk")&&($par{"dirIn"} ne "local")&&
	(length($par{"dirIn"})>1)){
	foreach $fileIn(@fileIn){
	    if (! -e "$fileIn"){
		$fileIn=$par{"dirIn"}.$fileIn;}
	    if (! -e "$fileIn"){
		print "*** iniChangePar: no in file=$fileIn, dirIn=",$par{"dirIn"},",\n";
		return(0);}}}
				# ------------------------------
    foreach $kwd (@kwdDef){	# add 'pre' 'title' 'ext'
	if ($kwd=~/^fileOut/){
	    if ((defined $par{"$kwd"})&&($par{"$kwd"} eq "no")){
		$par{"$kwd"}=0;
		next;}
	    if ((!defined $par{"$kwd"})||($par{"$kwd"} eq "unk")){
		$kwdPre=$kwd; $kwdPre=~s/file/pre/; 
		if (defined $par{"$kwdPre"}){$pre=$par{"$kwdPre"};}else{$pre="";}
		$kwdExt=$kwd; $kwdExt=~s/file/ext/; 
		if (defined $par{"$kwdExt"}){$ext=$par{"$kwdExt"};}else{$ext="";}
		if ((! defined $par{"title"})||($par{"title"} eq "unk")){
		    $par{"title"}=$scriptName;}
		$par{"$kwd"}=$pre.$par{"title"}.$ext;}}}
				# ------------------------------
				# add output directory
    if ((defined $par{"dirOut"})&&($par{"dirOut"} ne "unk")&&($par{"dirOut"} ne "local")&&
	(length($par{"dirOut"})>1)){
	if (! -d $par{"dirOut"}){ # make directory
	    if ($verb){@tmp=("STDOUT",$par{"dirOut"});}else{@tmp=($par{"dirOut"});}
	    ($Lok,$txt)=&dirMk(@tmp); } # external lib-ut.pl
	foreach $kwd (@kwdDef){
	    if ($kwd=~/^fileOut/){
		if ($par{"$kwd"} !~ /^$par{"dirOut"}/){
		    $par{"$kwd"}=$par{"dirOut"}.$par{"$kwd"};}}}}
				# ------------------------------
				# push array of output files
    if (! defined @fileOut){$#fileOut=0;}
    foreach $kwd (@kwdDef){
	if ($kwd=~/^fileOut/){
	    push(@fileOut,$par{"$kwd"});}}
				# ------------------------------
				# add working directory
    if ((defined $par{"dirWork"})&&($par{"dirWork"} ne "unk")&&($par{"dirWork"} ne "local")&&
	(length($par{"dirWork"})>1)){
	if (! -d $par{"dirWork"}){ # make directory
	    if ($verb){@tmp=("STDOUT",$par{"dirWork"});}else{@tmp=($par{"dirWork"});}
	    ($Lok,$txt)=&dirMk(@tmp); } # external lib-ut.pl
	foreach $kwd (@kwdDef){
	    if (($kwd=~/^file/)&&($kwd!~/^fileIn/)&&($kwd!~/^fileOut/)){
		if ($par{"$kwd"} !~ /^$par{"dirWork"}/){
		    $par{"$kwd"}=$par{"dirWork"}.$par{"$kwd"};}}}}
				# ------------------------------
				# array of Work files
    if (! defined @fileWork){$#fileWork=0;}
    foreach $kwd (@kwdDef){
	if (($kwd=~/^file/)&&($kwd!~/^fileIn/)&&($kwd!~/^fileOut/)){
	    push(@fileWork,$par{"$kwd"});}}
				# ------------------------------
				# blabla
    if ((defined $par{"verbose"}) &&($par{"verbose"})) {$Lverb=1; }
    if ((defined $par{"verbose2"})&&($par{"verbose2"})){$Lverb2=1;}
    if ((defined $par{"verbose3"})&&($par{"verbose3"})){$Lverb3=1;}
				# ------------------------------
				# add directory to executables
    foreach $kwd (@kwdDef){
	if (($kwd=~/^exe/)&&(defined $par{"$kwd"})&&(! -e $par{"$kwd"})){
	    $par{"$kwd"}=$par{"dirPerl"}.$par{"$kwd"};}}

    return(1);
}				# end of iniChangePar

#===============================================================================
sub cleanUp {
    local($sbrName,$fhinLoc,@tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#    cleanUp                    deletes intermediate files
#-------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";} $sbrName="$tmp"."cleanUp";
    if ($#fileWork>0){		# remove intermediate files
	if ($Lverb){@tmp=("STDOUT",@fileWork);}else{@tmp=(@fileWork);}
	($Lok,@tmp)=
	    &fileRm(@tmp);}	# external lib-ut.pl
}				# end of cleanUp

#===============================================================================
sub rdPhdRdb {
    local($fileInLoc)=@_;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   rdPhdRdb                    reads the PHDrdb file
#-------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";}
    $sbrName="$tmp"."rdPhdRdb";$fhinLoc="FHIN"."$sbrName";

    if (($par{"title"} ne "unk")&&(length($par{"title"})>1)){
	$title=$par{"title"};}else{$title="";}$dirOut=$par{"dirOut"};$extOut=$par{"extOut"};
    if ((length($dirOut)>1)&&(length($title)>1)){
	$fileOut="$dirOut"."$title".$par{"extOut"};}
    else {$fileOut=$fileInLoc;$fileOut=~s/\.rdb.*$|\.hssp.*$/$extOut/;}
    if (! -e $fileInLoc){
	print "*** $sbrName missing input '$fileInLoc'\n";
	return(0);}

    %rd=
	&rd_rdb_associative($fileInLoc,"body",@kwdRdb); # external lib-ut.pl
    if ((! defined $rd{"NROWS"})||(! %rd)){
	return(0);}
				# -------------------------------------------
				# store into NUM, SEQ, SEC, RISEC, ACC, RIACC
				# -------------------------------------------
    $#NUM=$#SEQ=$#SEC=$#RISEC=$#ACC=$#RIACC=0;
    foreach $des (@kwdRdb) {
	if (! defined $rd{"$des","1"}) {next;}
	if    ($des eq "No") {
	    $ct=1; while(defined $rd{"$des","$ct"}){push(@NUM,$rd{"$des","$ct"});++$ct;}}
	elsif ($des eq "AA") {
	    $ct=1; while(defined $rd{"$des","$ct"}){push(@SEQ,$rd{"$des","$ct"});++$ct;}}
	elsif ($des eq "PHEL") {
	    $ct=1; while(defined $rd{"$des","$ct"}){push(@SEC,$rd{"$des","$ct"});++$ct;}}
	elsif ($des eq "RI_S") {
	    $ct=1; while(defined $rd{"$des","$ct"}){push(@RISEC,$rd{"$des","$ct"});++$ct;}}
	elsif ($des eq "PACC") {
	    $ct=1; while(defined $rd{"$des","$ct"}){push(@ACC,$rd{"$des","$ct"});++$ct;}}
	elsif ($des eq "RI_A") {
	    $ct=1; while(defined $rd{"$des","$ct"}){push(@RIACC,$rd{"$des","$ct"});++$ct;}}
    }
				# convert L->' '
    foreach $it(1..$#SEC){$SEC[$it]=~s/L/ /;}
				# consistency check
    $Lerr=0;
    foreach $it (1..$#SEC){
	if (defined $SEQ[$it]){
	    $seq=$SEQ[$it];}
	else{$seq="U"; print "*** ERROR phd2dssp it=$it, SEQ not defined\n";$Lerr=1;}
	if (defined $SEC[$it]){
	    $sec=$SEC[$it];}
	else{$sec="U"; print "*** ERROR phd2dssp it=$it, SEC not defined\n";$Lerr=1;}
	if (defined $ACC[$it]){
	    $acc=$ACC[$it];}
	else{$acc="999";print "*** ERROR phd2dssp it=$it, ACC not defined\n";$Lerr=1;}}
    if ($Lerr){
	return(0);}
    else{
	return(1);}
}				# end of rdPhdRdb

#===============================================================================
sub rdHssp {
    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   rdHssp                      reads the HSSP file (all lines)
#-------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";}
    $sbrName="$tmp"."rdHssp";$fhinLoc="FHIN"."$sbrName";

    if (! -e $fileInLoc){
	print "*** $sbrName missing input '$fileInLoc'\n";
	return(0);}

    $Lok=       &open_file("$fhinLoc","$fileInLoc");
    if (! $Lok){print "*** ERROR $sbrName: '$fileInLoc' not opened\n";
		return(0);}
    $#HSSP=$kchain=0;
    while (<$fhinLoc>) {
	$_=~s/\n//g;
	if ($_=~/^SEQLENGTH/){	# store sequence length
	    $len=$_;$len=~s/^SEQLENGTH|\s//g;}
	elsif ($_=~/^KCHAIN/){	# store number of chains
	    $kchain=$_;$kchain=~s/^KCHAIN\s+(\d+)\s.*$/$1/;
	    if (($len+$kchain-1) != $#SEC){
		print"*** $sbrName: different length (HSSP=$len, kchain=$kchain,PHD=",$#SEC,")\n";
		close($fhinLoc); 
		return(0);}}
	push(@HSSP,$_);}close($fhinLoc);
    return(1);
}				# end of rdHssp

#==========================================================================
sub wrtHsspPhd {
    local ($fileOutLoc)=@_;
    local ($it);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   wrtHsspPhd                  writes the PHD prediction into HSSP format
#-------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";}
    $sbrName="$tmp"."wrtHsspPhd";$fhoutLoc="FHOUT"."$sbrName";

    $Lok=       &open_file("$fhoutLoc",">$fileOutLoc");
    if (! $Lok){print "*** ERROR $sbrName: '$fileOutLoc' not opened\n";
		return(0);}
				# ------------------------------
				# loop over HSSP 
    $ctHssp=0;
    foreach $hssp(@HSSP){
	++$ctHssp;
	if    ($hssp=~/^DATE/)     {$hssp=~s/on.*$//g;$hssp.="on $date (merged: PHD prediction)";}
	print $fhoutLoc "$hssp\n";
	last if ($hssp=~/^ SeqNo /);} # finish when alis start

    $ct=0;$LrdSeq=1;$LrdProf=0;
    foreach $itHssp(($ctHssp+1)..$#HSSP){
	$hssp=$HSSP[$itHssp];
				# ------------------------------
				# no sequence stuff
	if ($hssp =~ /^\#\# SEQUENCE/){
	    $LrdSeq=0;$LrdProf=1;}
	elsif ($hssp =~ /^\#\# ALIGNMENT/){
	    $LrdSeq=0;}
	elsif (($hssp=~/^ SeqNo /)&&(! $LrdProf)){
	    $ct=0;$LrdSeq=1;
	    print $fhoutLoc "$hssp\n"; 
	    next;}
	if (! $LrdSeq) { 
	    print $fhoutLoc "$hssp\n"; 
	    next;} # write last stuff (profiles + insertion)
				# ------------------------------
				# sequences
	$aaHssp=substr($hssp,15,1);
	++$ct;
	while (($ct<$#SEQ)&&($SEQ[$ct] ne $aaHssp)){
	    print "xx rd=$aaHssp, phd=$SEQ[$ct],\n";
	    &myprt_array("","xx phd seq=",@SEQ);
	    print "line=$hssp,\n";exit;
	    ++$ct;}
	$acc=$ACC[$ct]; while(length($acc)<3){$acc=" $acc";}
	$new=substr($hssp,1,17).$SEC[$ct].substr($hssp,19,18).$acc.substr($hssp,40);
	print $fhoutLoc "$new\n";
	if ($par{"verbose2"}){print "--- old  =",substr($hssp,1,45),"\n";
			      print "---   new=",substr($new,1,45),"\n";}
    }
    close($fhoutLoc);
}

