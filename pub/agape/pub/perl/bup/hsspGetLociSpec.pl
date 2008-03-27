#!/bin/env perl
#------------------------------------------------------------------------------#
# other perl environments
# EMBL
##!/usr/sbin/perl4 -w
##!/usr/sbin/perl -w
# EBI
##!/usr/bin/perl -w
#------------------------------------------------------------------------------#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$scriptName=   "hsspGetLociSpec";
$scriptIn=     "*.hssp (or list)";
$scriptTask=   "get SWISS-PROT data for HSSP file (e.g. location, species)";
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
$fileOut=$par{"fileOut"};
if (! $Lok){ die 'unwanted exit after ini'; }
				# ------------------------------
				# file with list or list of files?
if (($#fileIn == 1)&&(! &is_hssp($fileIn[1]))){
    $fileIn=$fileIn[1];
    $#fileIn=$Lerror=0;
    &open_file("$fhin","$fileIn");
    while(<$fhin>){$_=~s/\s//g;
		   if (! -e $_){
		       next;}
		   $file=$_;
		   ($Lok,$txt,$fileTmp,$chain)=&isHsspGeneral($file);
		   if ($txt eq "isHssp"){
		       push(@fileIn,$file);}
		   else {print "*** expected HSSP file '$file' txt=$txt (returned $fileTmp)\n";
			 $Lerror=1;}}close($fhin);
}

#-------------------------------------------------------------------------------
# do the job (here we go)
#-------------------------------------------------------------------------------
				# ------------------------------
if (length($par{"fileInSpecies"})>3){ # read species from file
    if ($Lverb){ print "--- reading species        \t ",$par{"fileInSpecies"},"\n";}
    $Lok=&rdSpecies($par{"fileInSpecies"});
    if (! $Lok){ print "*** ERROR $scriptName read locations ",$par{"fileInSpecies"},",\n";
		 die '*** unwanted after trying to read species';}}
				# ------------------------------
if (length($par{"fileInLoci"})>3){	# read locations from file
    if ($Lverb){ print "--- reading locations      \t ",$par{"fileInLoci"},"\n";}
    $Lok=&rdLoci($par{"fileInLoci"});
    if (! $Lok){ print "*** ERROR $scriptName read locations ",$par{"fileInLoci"},",\n";
		 die '*** unwanted after trying to read locations';}}
				# ------------------------------
if (length($par{"fileInGlyco"})>3){	# read glycosilated from file
    if ($Lverb){ print "--- reading glyco proteins \t ",$par{"fileInGlyco"},"\n";}
    $Lok=&rdLoci($par{"fileInGlyco"});
    if (! $Lok){ print "*** ERROR $scriptName read locations ",$par{"fileInGlyco"},",\n";
		 die '*** unwanted after trying to read glyco-proteins';}}
				# reduce
$ct=0;foreach $kwd(@kwdFeature){if (! defined $feature{"$kwd"}){++$ct;}}
$numFeature=($#kwdFeature-$ct);
				# ------------------------------
&wrtRdbHeader();		# will open all files

				# --------------------------------------------------
$ctOk=0;			# now read all HSSP files
foreach $fileIn (@fileIn){
    if ($Lverb){ print"--- now reading           \t $fileIn\n"; }
				# read one HSSP header
    %rd=&rdHsspHeader($fileIn);
    if (! %rd){print "*** ERROR no HSSP for '$fileIn'\n";
	       next;}
    if ($rd{"LEN1"}==0){	# error?
	print "*** ERROR for it=$it, len1=0, file=$fileIn,\n";
	next;}
				# store only file name, no path
    $id1=$fileIn;$id1=~s/^.*\///g;$id1=~s/\.hssp.*$//g;$rd{"ID1"}=$id1;
				# ------------------------------
    $ctFeatureOk=0;$idOk="";	# loop over aligned protein pairs
    foreach $kwd(@kwdFeature){$res{"$kwd"}=" ";} # ini
    foreach $itSeq (1..$rd{"NROWS"}){ # loop over all sequences
	$id2=$rd{"$itSeq","ID"};
	if ($Lverb){print "--- hssp=$id1, swiss=$id2, it=$itSeq, ct=$ctOk\n";}

	($Lincl,$txt)=&getExcl($itSeq);	# exclude SWISS (too short, pide, asf)
	if (! $Lincl){
	    if ($Lverb){print"--- excluded as: \t $txt\n";}
	    next;}
				# get SWISS-PROT features
	$ctTmp=  &getFeature($id2);
	$ctFeatureOk+=$ctTmp;
	if ($ctTmp>0){$idOk.="$id2,";}
	last if ($ctFeatureOk==$numFeature);
    }
    if ($ctFeatureOk==0){
	next;}
    $idOk=~s/,$//g;++$ctOk;
    &wrtRdbLine($fhout,"\t",$ctOk,$id1,$idOk); # all global
    &wrtRdbLine("STDOUT"," ",$ctOk,$id1,$idOk);
}				# end loop over proteins

if ($fhout ne "STDOUT"){close($fhout);} # close RDB file
    

if ($Lverb){ print "--- fin: number of id's (unique) found=$ctOk, output in $fileOut\n";}
    

exit;

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
		printf "--- %-20s '%-s'\n","fileOut:",$par{"fileOut"};
		foreach $kwd (@kwdDef) {
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
    @scriptKwd=     ("minLen1,minLali,minPide,maxPide,minR1A=",
		     "fileInLoci=",
		     "fileInSpecies=",
		     "fileInGlyco=",
		     " ",
		     "title=",
		     " ",
		     "not_screen",
		     "dirIn=",
		     "dirOut=",
		     "dirWork=",
		     );
    @scriptKwdDescr=("cut-offs to accept SWISS-PROT id ", 
		     "RDB file(s) with loci (comma for many: Euka2-allLociTransl.rdb,Proka2-.)", 
		     "flat file(s) with specy (commata for many: allSpec-archae.list,allSpec.)",
		     "flat file(s) with glycosilated proteins",
		     " ",
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
    $par{"dirLoci"}=            "/sander/purple1/rost/w/loci/data/";
    $par{"dirGlyco"}=           "/sander/purple1/rost/w/loci/data/";
    $par{"dirSpecies"}=         "/home/rost/pub/data/swiss/";
				# --------------------
				# files
				# file with locations (RDB: id\tlocation\tsource)
    $par{"fileInLoci"}=         "Euka3-allLociTransl.rdb";
				# file with species   (flat: species)
    $par{"fileInSpecies"}=      
	"allSpec-archae.list,allSpec-euka.list,allSpec-proka.list,allSpec-virus.list";
    $par{"fileInSpecies"}=      
	"allSpec-euka.list";	# xx
    $par{"fileInGlyco"}=        "Glyco-all.dat";
	

    $par{"title"}=              "unk"; # output files will be called 'Pre-title.ext'
    $par{"extOut"}=             ".rdb";
    $par{"extHssp"}=            ".hssp";
    $par{"fileOut"}=            "unk";
				# file handles
    $fhout=                     "FHOUT";
    $fhin=                      "FHIN";
				# --------------------
				# parameters
    $par{"minLen1"}=             30; # minimal length of guide sequence
    $par{"minLali"}=             30; # minimal alignment length to accept SWISS-PROT data
    $par{"minPide"}=             30; # minimal pairwise sequence identity to accept SW data
    $par{"maxPide"}=            100; # maximal pairwise sequence identity to accept SW data
    $par{"minR1A"}=               0.5; # minimal length overlap 

    $par{"glycoUnk"}=           "notG";
    $par{"lociUnk"}=            "unkL";
    $par{"speciesUnk"}=         "unkS";
				# --------------------
				# logicals
    $Lverb=                     1; # blabla on screen
    $Lverb2=                    1; # more verbose blabla
    $par{"verbose"}=$Lverb;$par{"verbose2"}=$Lverb2;
				# ------------------------------
				# a.a descriptors 
				# allowed in default file
				# ------------------------------
    @kwdDef=     ("debug","verbose","verbose2",
		  "dirIn","dirOut","dirWork","dirHssp","dirLoci","dirGlyco","dirSpecies",

		  "fileInLoci","fileInSpecies","fileInGlyco",

		  "title","extOut","extHssp","fileOut",

		  "minLen1","minLali","minPide","maxPide","minR1A",
		  );
				# column names to be read
    @kwdRd=       ("ID","STRID","IDE","WSIM","LALI","NGAP","LGAP","LEN2","ACCNUM","NAME",
		   "IFIR","ILAS","JFIR","JLAS");
    @kwdFeature=  ("loci","species","glyco");
}				# end of iniDefaults

#===============================================================================
sub iniGetArg {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iniGetArg                   read command line arguments
#-------------------------------------------------------------------------------
    $Lokdef=0; $#fileIn=$#tmp=0;
    foreach $arg (@ARGV){	# key word driven input
	if    ( $arg=~ /verbose3/ )     { $Lverb3=1; }
	elsif ( $arg=~ /verbose2/ )     { $Lverb2=1; }
	elsif ( $arg=~ /verbose/ )      { $Lverb=1; }
	elsif ( $arg=~ /not_verbose/ )  { $Lverb=0; }
	elsif ( $arg=~ /not_?[sS]creen/){ $Lverb=0; }
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
				# output file
    if ((!defined $par{"fileOut"})||($par{"fileOut"} eq "unk")||(length($par{"fileOut"})<1)){
	if (defined $par{"extOut"}){$ext=$par{"extOut"};}else{$ext="";}
	if ((! defined $par{"title"})||($par{"title"} eq "unk")){
	    $tmp="Out-".$ARGV[1]."$ext";$tmp=~s/\.list//g;
	    $par{"fileOut"}=$tmp;}
	else {
	    $par{"fileOut"}=$par{"title"}.$ext;}}
				# ------------------------------
				# blabla
    if ((defined $par{"verbose"}) &&($par{"verbose"})) {$Lverb=1; }
    if ((defined $par{"verbose2"})&&($par{"verbose2"})){$Lverb2=1;}
    if ((defined $par{"verbose3"})&&($par{"verbose3"})){$Lverb3=1;}
    return(1);
}				# end of iniChangePar

#===============================================================================
sub getExcl {
    local($itLoc)=@_;
    local($sbrName,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getExcl                     returns 0, if current should be excluded
#       all variables GLOBAL
#-------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";}
    $sbrName="$tmp"."getExcl";

    if ((100*$rd{"$itLoc","IDE"})<$par{"minPide"}){ # minimal percentage seq identity
	return(0,"minPide=".$rd{"$itLoc","IDE"});}
    if ((100*$rd{"$itLoc","IDE"})>$par{"maxPide"}){ # maximal percentage seq identity
	return(0,"maxPide=".$rd{"$itLoc","IDE"});}
    if ($rd{"$itLoc","LALI"}<=$par{"minLali"}){ # minimal length
	return(0,"minLali=".$rd{"$itLoc","LALI"});}
    if (($rd{"$itLoc","LEN2"}==0)||($rd{"$itLoc","LALI"}==0)){ # error?
	return(0,"LALI=".$rd{"$itLoc","LALI"}.", LEN2=".$rd{"$itLoc","LEN2"});}
				# ratio cut off?
    if (($par{"minR1A"}>0)&&(($rd{"len1"}/$rd{"$itLoc","LALI"})<$par{"minR1A"})){
	return(0,"minR1A=".$rd{"len1"});}
    return(1,"ok");
}				# end of getExcl

#===============================================================================
sub getFeature {
    local($id2Loc) = @_ ;
    local($sbrName,$tmp,$Lok,$idTmp,%tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getFeature                  returns the SWISS-PROT features
#       in:                     id2 (swiss-prot id)
#          GLOBAL               $feature{"feature","id2Loc"},@kwdFeature
#       out:                    $tmp{"loci"} ... (succession from @kwdFeature)
#-------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";}

    $sbrName="$tmp"."getFeature";
    $ctLoc=0;
    foreach $feature (@kwdFeature){
	if (! defined $feature{"$feature"}){
	    next;}
				# change id for species swiss_species -> species
	if ($feature eq "species"){$idTmp=$id2Loc;$idTmp=~s/^.*_//g;}else{$idTmp=$id2Loc;}
				# feature found
	if ((defined $feature{"$feature","$idTmp"})&&
	    ($feature{"$feature","$idTmp"} !~/^unk|^\?/)){
	    $here=$feature{"$feature","$idTmp"};
	    if ($res{"$feature"} =~ /^ |^unk|^not/){
		++$ctLoc;
#		print "xx wants to add $here, to ",$res{"$feature"},",\n";
		$res{"$feature"}=$here;}
	    else{
		@tmp=split(/,/,$res{"$feature"});
		foreach $tmp(@tmp){last if ($tmp eq $here);
				   $res{"$feature"}.=",".$here;}}}
	elsif ($res{"$feature"} eq " "){
	    $tmp="$feature"."Unk";
	    $res{"$feature"}=$par{"$tmp"};}
    }
    return($ctLoc);
}				# end of getFeature

#===============================================================================
sub rdGlyco {
    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   rdGlyco                     read file with glycosylated proteins
#-------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";}
    $sbrName="$tmp"."rdGlyco";$fhinLoc="FHIN"."$sbrName";

    $fileInLoc=~s/^,|,$//g;
    @fileInLoc=split(/,/,$fileInLoc);
    $Lok=0;			# loop over many files
    foreach $fileInLoc (@fileInLoc){
	if (! -e $fileInLoc){
	    $fileInLoc=$par{"dirGlyco"}.$fileInLoc;}
	if (! -e $fileInLoc){
	    next;}
	$Lok=       &open_file("$fhinLoc","$fileInLoc");
	if (! $Lok){print "*** ERROR $sbrName: '$fileInLoc' not opened\n";
		    return(0);}
	$tmp=$fileInLoc;$tmp=~s/^.*\///g;
	while (<$fhinLoc>) {$_=~s/\s//g; # xx
			    if (length($_)<2){next;}
			    $feature{"glyco"}=1;
			    $feature{"glyco","$_"}="glyco";}close($fhinLoc);
    }				# end of loop over many files
    return($Lok);
}				# end of rdGlyco

#==========================================================================================
sub rdHsspHeader {
    local ($fileHsspLoc,@num) = @_ ;
    local (@des1,@des2,%ptr,$ptr,$len_strid,$Lis_long_id,$fhin,$Lget_all,
	   %rdLoc,@tmp,$tmp,$beg,$mid,$end,$ct,$id,$strid,$des,$num,$Lok);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    rdHsspHeader               reads the header of an HSSP file for numbers 1..$#num
#--------------------------------------------------------------------------------
				# defaults
    $fhin="FHIN_HSSP_HEADER";
    $#des1=$#des2=0;
    foreach $des (@kwdRd){if ($des =~/^STRID/){push(@des2,$des);}
			  else                {push(@des1,$des);}}

    $ptr{"IDE"}=1;$ptr{"WSIM"}=2;
    $ptr{"IFIR"}=3;$ptr{"ILAS"}=4;$ptr{"JFIR"}=5;$ptr{"JLAS"}=6;
    $ptr{"LALI"}=7;$ptr{"NGAP"}=8;$ptr{"LGAP"}=9;$ptr{"LEN2"}=10; $ptr{"ACCNUM"}=11;

    $len_strid=    4;		# minimal length to identify PDB identifiers
    $Lis_long_id=0;		# 

				# ------------------------------
    if (! -e $fileHsspLoc){	# search for HSSP file
	($tmp,$chain)=&hsspGetFile($fileHsspLoc,$Lverb); # external lib-prot.pl
	if ((! $tmp)||(! -e $tmp)){
	    return(0);}
	elsif (! &is_hssp($tmp)){ # external lib-prot.pl		
	    return(0);}
	elsif (&is_hssp_empty($tmp)){ # external lib-prot.pl
	    return(0);}
	$fileHsspLoc=$tmp; }

    if ( ! -e $fileHsspLoc) {	# check existence
	return(0); }
				# ini
				# ------------------------------
				# read file
    &open_file("$fhin","$fileHsspLoc");
    while ( <$fhin> ) {		# length, lond-id
	last if (/^\#\# PROTEINS/); 
	if (/^PARAMETER  LONG-ID :YES/) {$Lis_long_id=1;}
	elsif (/^SEQLENGTH /) {$_=~s/\n|\s|SEQLENGTH//g;
			       $rdLoc{"len1"}=$rdLoc{"LEN1"}=$_; } }
    $ct_taken=0;
    while ( <$fhin> ) { 
	last if (/^\#\# ALIGNMENTS/); 
	if (/^  NR\./){next;}	# skip describtors
	if ($Lis_long_id){
	    $beg=substr($_,1,56);$end=substr($_,109);$mid=substr($_,57,115); }
	else {
	    $beg=substr($_,1,28);$end=substr($_,90);$mid=substr($_,29,90); }
	$end=~s/^\s*|\s*$|\n//g; # purge leading blanks
	$mid=~s/^\s*|\s*$//g;	# purge leading blanks

				# begin: counter and id
	$ct=$beg;$ct=~s/\s*(\d+)\s+\:.*/$1/;$ct=~s/\s//g;
				# ------------------------------
	$Lok=0;			# read it?
	$beg=~s/.+ \:\s*|\s*$//g;
	if (! $Lis_long_id) {
	    $id=$beg;$id=~s/(.+_\S+).*/$1/;
	    $strid=$beg;$strid=~s/$id|\s//g; }
	else {
	    $id=$beg;$id=~s/(.+_\S+).*/$1/;
	    $strid=substr($_,49,6);$strid=~s/\s//g; }
	$tmp=$len_strid-1;
	if ( (length($strid)<$len_strid) && 
	    ($id=~/^[0-9][A-Z0-9]{$tmp,$tmp}\s*/)){
	    $strid=substr($id,1,$len_strid); }
	$rdLoc{"$ct","ID"}=$id;
	$rdLoc{"$ct","STRID"}=$strid;
	$rdLoc{"$ct","NAME"}=$end;
	++$ct_taken;
				# middle all info
	$#tmp=0;@tmp=split(/\s+/,$mid);
	foreach $_ (@tmp) {$_=~s/\s//g;}
	foreach $des (@des1){ 
	    if ( ! defined $ptr{"$des"}) {
		next; }
	    $ptr=$ptr{"$des"};
	    $rdLoc{"$ct","$des"}=$tmp[$ptr]; }
    }close($fhin);
    $rdLoc{"NROWS"}=$ct_taken;
    return(%rdLoc);
}				# end of rdHsspHeader

#===============================================================================
sub rdLoci {
    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   rdLoci                      read file with locations
#-------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";}
    $sbrName="$tmp"."rdLoci";$fhinLoc="FHIN"."$sbrName";

    $fileInLoc=~s/^,|,$//g;
    @fileInLoc=split(/,/,$fileInLoc);
    $Lok=0;			# loop over many files
    foreach $fileInLoc (@fileInLoc){
	if (! -e $fileInLoc){
	    $fileInLoc=$par{"dirLoci"}.$fileInLoc;}
	if (! -e $fileInLoc){
	    next;}
	$Lok=       &open_file("$fhinLoc","$fileInLoc");
	if (! $Lok){print "*** ERROR $sbrName: '$fileInLoc' not opened\n";
		    return(0);}
	while (<$fhinLoc>) {if(/^\#|^\s*lineNo|^\s*5S/){next;}
			    $_=~s/\n//g;$_=~s/^\s*|\s*$//g;
			    @tmp=split(/\t/,$_);
			    $tmp[2]=~s/\s//g;$tmp[3]=~s/\s//g;
			    $tmp=$tmp[2];$feature{"loci"}=1;
			    $feature{"loci","$tmp"}=$tmp[3];}close($fhinLoc);
    }
    return($Lok);
}				# end of rdLoci

#===============================================================================
sub rdSpecies {
    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   rdSpecies                    read file with species
#-------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";}
    $sbrName="$tmp"."rdSpecies";$fhinLoc="FHIN"."$sbrName";

    $fileInLoc=~s/^,|,$//g;
    @fileInLoc=split(/,/,$fileInLoc);
				# loop over many files
    foreach $fileInLoc (@fileInLoc){
	if (! -e $fileInLoc){
	    $fileInLoc=$par{"dirSpecies"}.$fileInLoc;}
	if (! -e $fileInLoc){
	    next;}
	$Lok=       &open_file("$fhinLoc","$fileInLoc");
	if (! $Lok){print "*** ERROR $sbrName: '$fileInLoc' not opened\n";
		    return(0);}
	$tmp=$fileInLoc;$tmp=~s/^.*\///g;
	if    ($tmp=~/archa/){$species="archae";}
	elsif ($tmp=~/euka/) {$species="euka";}
	elsif ($tmp=~/proka/){$species="proka";}
	elsif ($tmp=~/virus/){$species="virus";}
	else                 {print "*** $sbrName no species recognised in '$fileInLoc'\n";
			      return(0);}

	while (<$fhinLoc>) {$_=~s/\s//g;
			    if (length($_)<2){next;}
			    $tmp=$_;$feature{"species"}=1;
			    $feature{"species","$tmp"}=$species;}close($fhinLoc);
    }				# end of loop over many files
    return(1);
}				# end of rdSpecies

#==========================================================================================
sub wrtRdbHeader {
    $[ =1 ;
#--------------------------------------------------------------------------------
#   wrtRdbHeader                write RDB header
#--------------------------------------------------------------------------------
    $Lok=       &open_file("$fhout",">$fileOut");
    if (! $Lok){print "*** ERROR $sbrName: '$fileOut' not opened\n";
		return(0);}
    
    print $fhout "\# Perl-RDB\n","\# SWISS-PROT features for HSSP files\n";

    print $fhout
	"\# NOTATION ------------------------------------------------------------\n",
	"\# NOTATION COLUMN-NAMES\n",
	"\# NOTATION id1:     PDB identifier\n",
	"\# NOTATION loci:    sub-cellular locations taken from SWISS-PROT\n",
	"\# NOTATION glyco:   glycosilated proteins (glyco,notG)\n",
	"\# NOTATION species: species               (euka,proka,archae,virus)\n",
	"\# NOTATION id2:     SWISS-PROT identifiers used to derive features\n",
	"\# NOTATION :   \n",
	"\# NOTATION ------------------------------------------------------------\n";
    printf $fhout		# names
	"%-6s\t%-6s\t%-15s\t%-10s\t%-6s\t%-30s\n","lineNo","id1","loci","species","glyco","id2";
    printf $fhout		# formats
	"%-6s\t%-6s\t%-15s\t%-10s\t%-6s\t%-30s\n","6N",    "6S", "15S", "10S",    "6S","30S";
}				# end of wrtRdbHeader

#==========================================================================================
sub wrtRdbLine {
    local($fhoutLoc,$sepLoc,$itLoc,$id1Loc,$id2Loc)=@_;
    $[ =1 ;
#--------------------------------------------------------------------------------
#   wrtRdbLine                  write the results
#--------------------------------------------------------------------------------
    printf $fhoutLoc 
	"%-6d$sepLoc%-6s$sepLoc%-15s$sepLoc%-10s$sepLoc%-6s$sepLoc%-30s\n",
	$itLoc,$id1Loc,$res{"loci"},$res{"species"},$res{"glyco"},$id2Loc;
}				# end of wrtRdbLine

