#!/usr/sbin/perl -w
#------------------------------------------------------------------------------#
# other perl environments
##!/bin/env perl
# EMBL
##!/usr/sbin/perl -w
# EBI
##!/usr/bin/perl -w
#----------------------------------------------------------------------
# dssp2fasta
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# usage: 	dssp2fasta.pl file_dssp
#
# task:		runs dssp2fasta without editor
# 		
#----------------------------------------------------------------------#
#	Burkhard Rost		       December	,       1997           #
#			changed:       .	,    	1998           #
#	EMBL				Version 0.1                    #
#	Meyerhofstrasse 1                                              #
#	D-69012 Heidelberg		(rost@EMBL-Heidelberg.DE)      #
#----------------------------------------------------------------------#
				# --------------------------------------------------
				# sets array count to start at 1, not at 0
				# --------------------------------------------------
$[ =1 ;
				# --------------------------------------------------
				# include libraries
				# --------------------------------------------------
push (@INC, "/home/rost/perl") ;
# require "ctime.pl";  # require "rs_ut.pl" ; 
require "lib-ut.pl"; require "lib-br.pl";
# require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
				# --------------------------------------------------
				# initialise variables
				# --------------------------------------------------
&ini;

# --------------------------------------------------------------------------------
# do the job (here we go)
# --------------------------------------------------------------------------------
				# digest format
($Lok,%fileFound)=
    &getFileFormat($fileInDssp,"DSSP",@dirDssp);

$nfiles=$fileFound{"NROWS"};
undef @fileDssp; undef @chainDssp;
foreach $it (1..$nfiles){
    $file=$fileFound{"$it"};$chain=$fileFound{"chain","$it"};
    if (-e $file){
	push(@fileDssp,$file);
	push(@chainDssp,$chain);
	print "--- found $file";if (defined $chain){print" ($chain)";}
	print "\n";}
    else {
	print "-*- $script_name DSSP: NOT found $file\n";}}
				# ------------------------------
				# determine name of output file
if ($#fileDssp>1){$id=$fileInDssp;$id=~s/^.*\///g;$id=~s/\..*$//g;
		  $fileOut=$dir_out."$id".".f";}
else             {$id=$fileInDssp;$id=~s/^.*\///g;$id=~s/\.dssp|_//g;
		  $fileOut=$dir_out."$id".".f";}
				# ------------------------------
				# open output file
$Lok=&open_file("$fhout",">$fileOut"); 
if (! $Lok){print "*** ERROR main: '$fileOut' not opened\n";
	    next;}
print "--- write output '$fileOut'\n"; 
				# --------------------------------------------------
				# loop over DSSP files
foreach $itFile(1..$#fileDssp){
    $file= $fileDssp[$itFile];
    $chain=$chainDssp[$itFile]; if (! defined $chain){$chain=" ";}
    $idLoc=$file;$idLoc=~s/^.*\///g;$idLoc=~s/\.dssp|_//g;$idLoc.="$chain";
				# read DSSP file
    if ($chain =~/[A-Z0-9]/){
	($Lok,$seq,$seqC)=&dsspRdSeq($file,$chain);}
    else {
	($Lok,$seq,$seqC)=&dsspRdSeq($file);}
    
				# write new files
    $len=length($seqC);$id2=substr($idLoc,1,4);
    print $fhout ">pdb|$id2|$idLoc  $len  aa";
    for ($it=1;$it<=$len;$it+=50){
	print $fhout "\n",substr($seqC,$it,50);}
    print $fhout "\n";
}
close($fhout);
system("cat $fileOut");exit;	# xx
# --------------------------------------------------------------------------------
# work done
# --------------------------------------------------------------------------------
if ($Lverb) { &myprt_txt(" $script_name has ended fine .. -:\)"); 
	      &myprt_txt(" output in files: "); 
	      foreach $fileOut(@fileOut){
		  if (-e $fileOut){print "$fileOut,";}}print"\n";}
exit;

#==========================================================================================
sub ini {
    local ($script_input,$script_goal,$script_narg,
	   @script_goal,@script_help,@script_opt_key,@script_opt_keydes,$txt,$it);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   initialises variables/arguments
#--------------------------------------------------------------------------------
#
#	$date is e.g.:		Oct:14:13:06:47:1993
#	@Date is e.g.:		Oct1413:06:471993
#	&ctime(time) is e.g.:	Thu Oct 14 13:06:47 1993
#
    @Date = split(' ',&ctime(time)) ; shift (@Date) ; 

    # ------------------------------------------------------------
    # about script
    # ------------------------------------------------------------
    $script_name=   "dssp2fasta";
    $script_input=  "file.dssp_C (chain, or list therof)";
    $script_goal=   "extracts sequences from DSSP file (list to fasta db)";
    $script_narg=   1;
    @script_goal=   (" ",
		     "Task: \t $script_goal",
		     " ",
		     "Input:\t $script_input",
		     " ",
		     "Done: \t ");
    @script_help=   ("Help: \t For further information on input options asf., please  type:",
		     "      \t '$script_name help'",
		     "      \t ............................................................",
		     );
    @script_opt_key=("not_screen",
		     "dir_in=",
		     "dir_out=",
		     "dir_work=",
		     );
    @script_opt_keydes= 
	            ("no information written onto screen",
		     "input dir name,   default: local",
		     "output dir name,  default: local",
		     "working dir name, default: local",
		     );

    if ( ($#ARGV<1)|| ($ARGV[1]=~/^help/) || ($ARGV[1]=~/^man/) ) { 
	print "-" x 80, "\n", "--- \n"; &myprt_txt("Perl script"); 
	foreach $txt (@script_goal) { &myprt_txt("$txt"); } &myprt_empty; 
	&myprt_txt("usage: \t $script_name $script_input"); 
	&myprt_empty;&myprt_txt("optional:");
	for ($it=1; $it<=$#script_opt_key; ++$it) {
	    printf"--- %-12s %-s\n",$script_opt_key[$it],$script_opt_keydes[$it]; }
	&myprt_empty; print "-" x 80, "\n"; exit; }
    elsif ( $#ARGV < $script_narg ) {
	print "-" x 80, "\n", "--- \n";&myprt_txt("Perl script "); 
	foreach $txt (@script_goal){&myprt_txt("$txt");}
	foreach $txt (@script_help){&myprt_txt("$txt");}
	&myprt_empty;print"-" x 80,"\n";exit;}
    
    # ------------------------------------------------------------
    # defaults 
    # ------------------------------------------------------------
    $ARCH=                      $ENV{'ARCH'};
    if (! defined $ARCH){
	foreach $_(@ARGV){
	    if ($_=~/ARCH=(.+)$/){$ARCH=$1;$ARCH=~s/\s//g;
				  last;}}}
    if (! defined $ARCH){
	$ARCH=                  "SGI64";}
				# --------------------
				# directories
    $dir_in=                    "";
    $dir_out=                   "";
    $dir_work=                  "";
    @dirDssp=                   ("/data/dssp/","/sander/purple1/rost/dssp/");
				# --------------------
				# files
				# file extensions
				# file handles
    $fhout=                     "FHOUT";
#    $fhin=                      "FHIN";

				# --------------------
				# logicals
    $Lverb=                     1;		# blabla on screen
    $Lclean=                    0;		# clean identical alis?

    # ------------------------------------------------------------
    # read input arguments
    # ------------------------------------------------------------
    $fileInDssp=               $ARGV[1];
				# output file
    $fileOut=                  $fileInDssp."_extr"; $fileOut=~s/^\/.*\///g;
    $fileOut_tmp=              "XDSSP2FASTA" .$$.".tmp"; 

    if ($#ARGV>$script_narg) {
	for($it=($script_narg+1);$it<=$#ARGV;++$it) {
	    $_=$ARGV[$it];
	    if    ( /not_?[Ss]creen/ ) { $Lverb=0; }
	    elsif ( /^verb/ )      { $Lverb=1; }
	    elsif ( /fileOut=/ ) {  $tmp=$ARGV[$it];$tmp=~s/\n|fileOut=//g; 
				     $fileOut=$tmp; }
	    elsif ( /dir_in=/ ) {    $tmp=$ARGV[$it];$tmp=~s/\n|dir_in=//g; 
				     $dir_in=$tmp; }
	    elsif ( /dir_out=/ ) {   $tmp=$ARGV[$it];$tmp=~s/\n|dir_out=//g; 
				     $dir_out=$tmp; }
	    elsif ( /dir_work=/ ) {  $tmp=$ARGV[$it];$tmp=~s/\n|dir_work=//g; 
				     $dir_work=$tmp; }
	    elsif ( /^clean/)       {$Lclean=1;}
	}}
				# ------------------------------
				# a.a to be read
				# ------------------------------
    # ------------------------------------------------------------
    # assignments dependent on input read
    # ------------------------------------------------------------
				# ------------------------------
				# interpret input
    if (length($dir_in)>1) {   &complete_dir($dir_in);$dir_in=$DIR;
			       $tmp=$fileInDssp; $fileInDssp="$dir_in"."$tmp";}
    if (length($dir_out)>1) {  &complete_dir($dir_out);$dir_out=$DIR;
			       $tmp=$fileOut; $fileOut="$dir_out"."$tmp";}
    if (length($dir_work)>1) { &complete_dir($dir_work);$dir_work=$DIR; 
			       $fileOut_tmp="$dir_work".$fileOut_tmp;}

    if ($Lverb) { &myprt_line; &myprt_txt("perl script that $script_goal"); 
		  &myprt_empty; &myprt_txt("fileInDssp: \t \t $fileInDssp"); 
		  &myprt_txt("fileOut: \t \t $fileOut");
		  &myprt_txt("end of setting up,\t let's work on it"); 
		  &myprt_empty; &myprt_line; &myprt_empty; }
}				# end of ini

#===============================================================================
sub subx {
#    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   subx                       
#                               c
#       in:                     
#         A                     A
#       out:                    
#         A                     A
#-------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";}
    $sbrName="$tmp"."subx";$fhinLoc="FHIN"."$sbrName";

    $Lok=       &open_file("$fhinLoc","$fileInLoc");
    if (! $Lok){print "*** ERROR $sbrName: '$fileInLoc' not opened\n";
		return(0);}
    while (<$fhinLoc>) {
	$_=~s/\n//g;
	next if (length($_)==0);
    } close($fhinLoc);

}				# end of subx

