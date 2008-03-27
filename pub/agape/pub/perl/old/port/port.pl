#!/bin/env perl
##!/usr/sbin/perl -w
##!/usr/bin/perl
#----------------------------------------------------------------------
# aqua
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# usage: 	port dirBup (directory to be backed up)
#
# task:		makes back up (tar, zip, asf)
# 		
# subroutines   (internal):  
#               x
#                                  y
# 		
#
#----------------------------------------------------------------------#
#	Burkhard Rost		       January,         1997           #
#			changed:       .	,    	1997           #
#	EMBL			       Version 0.1                     #
#	Meyerhofstrasse 1                                              #
#	D-69117 Heidelberg		(rost@EMBL-Heidelberg.DE)      #
#----------------------------------------------------------------------#
				# sets array count to start at 1, not at 0
$[ =1 ;
				# include libraries
push (@INC, "/home/rost/perl","/home/phd/ut/perl") ;
if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
require "lib-ut.pl"; require "lib-br.pl"; 

&ini;				# initialise variables

# --------------------------------------------------------------------------------
# do the job (here we go)
# --------------------------------------------------------------------------------
if (-d $par{"dirOut"}){
    print "-*- WARNING output directory exists '",$par{"dirOut"},"'\n";
    $par{"dirOut"}.=$$;}
$Lok=&mkDir($par{"dirOut"},$Lscreen);
if (! $Lok){
    exit;}
				# --------------------------------------------------
				# loop over all directories
				# --------------------------------------------------
$#allTar=0;
foreach $dirBup (@dirBup){
    $dirTmp=$dirHome.$dirBup;
    if ($Lscreen)             { print "--- \t \t \t working on '$dirTmp'\n";}
				# ------------------------------
    @allFiles=			# list all files
	&lsAllFiles($dirTmp);	# external lib-ut.pl
    print "x.x '$dirTmp' into all dir\n";
    @allDir=			# list all sub directories
	&lsAllDir($dirTmp);

    $dirOutWrt=$par{"dirOut"}.$dirBup;
    if ($dirBup=~/\//){
	$tmp=$dirBup;$tmp=~s/^\/|\/$//g;
	foreach $it (1..$#tmp){
	    $tmp.=$tmp[$it];
	    $Lok=&mkDir($tmp,$Lscreen);
	    if (! $Lok){
		exit;}}}
				# ------------------------------
    if ((-d $dirOutWrt)&&($par{"doTar"})){ # clean up if existing (only for bup)
	if ($dirOutWrt=~/$dirHome/){ # security: NOT in home
	    print "*** NO BACK-UP in home '$dirHome' (wants into",$par{"dirOut"},"\n";
	    exit;}
	if ($Lscreen) {         print "--- system \t \t '\\rm -r $dirOutWrt'\n";}
	#system("\\rm -r $dirOutWrt"); 
    }
				# ------------------------------
    foreach $dir (@allDir){	# make dir''s
	$dir=~s/$dirHome/$par{"dirOut"}/;
	$Lok=&mkDir($dir,$Lscreen);
	if (! $Lok){
	    exit;}}
    $#allFilesOut=0;		# ------------------------------
    foreach $file (@allFiles){ # copy to bup directory
	if (-d $file){
	    next;}
	$fileOut=$file;$fileOut=~s/$dirHome/$par{"dirOut"}/;
	$Lok=&cpFile($file,$fileOut,$Lscreen);
	if (! $Lok){
	    exit;}
	push(@allFilesOut,$fileOut);}
				# ------------------------------
    if ($par{"doZip"}){		# gzip,tar
	foreach $file(@allFilesOut){
	    system("gzip $file");}}
				# ------------------------------
    if ($par{"doTar"}){		# tar
	$tmp=$dirBup;$tmp=~s/^.*\///g;
	if ($par{"title"} ne "unk"){
	    $tarTmp=$par{"title"}."$tmp".".tar";}
	else {$tarTmp="$tmp".".tar";}
	push(@allTar,$tarTmp);
	$argTar=$tarTmp." ".$par{"dirOut"}."$dirBup"."/*";
	if ($Lscreen) {         print "--- system \t \t '$cmdTar $argTar'\n";}
	system("$cmdTar $argTar"); 
				# clean up intermediate
	if ($Lscreen) {         print "--- system \t \t 'rm -r $dirOutWrt'\n";}
	system("rm -r $dirOutWrt");}
}				# end of loop over all dirBup s
				# --------------------------------------------------

				# ------------------------------
				# now tar on tar's
if (($#allTar>1) && $par{"doTar"}){
    $tarFin=$par{"title"}.".tar";$argTar=$tarFin." @allTar";
    if ($Lscreen) {         print "--- system \t \t '$cmdTar $argTar'\n";}
    system("$cmdTar $argTar"); 
    next;			# x.x
				# clean up intermediate
    foreach $file(@allTar){ if ($Lscreen) { print "--- system \t \t 'rm $file'\n";}
			    system("\\rm $file");}}
elsif ( ($#allTar==1) && $par{"doTar"} && (-e $tarTmp)){
    $tarFin=$par{"title"}.".tar";
    $Lok=&mvFile($tarTmp,$tarFin,$Lscreen);}
else {$tarFin="";}
    

# --------------------------------------------------------------------------------
# work done
# --------------------------------------------------------------------------------
if ($Lscreen) { 
    &myprt_line; &myprt_txt(" $script_name has ended fine .. -:\)"); 
    &myprt_empty; &myprt_txt(" output in dir: \t ".$par{"dirOut"}); 
    if ($par{"doTar"}&&(-e $tarFin)){
	&myprt_txt(" output in file: \t $tarFin"); }}
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
#    $PWD=                       $ENV{'PWD'};
#    $ARCH=                      $ENV{'ARCH'};

    &iniDefaults;               # first settings for parameters (may be overwritten by
				# default file and command line input)
    &iniHelp;
				# ------------------------------
				# predefined key words
    $ARGV[1]=~s/dirBup=//g;
    if    ($ARGV[1] eq "sys"){
	$dirBup=$par{"dirBup"}="bin,emacs,etc";}
    else {
	$dirBup=$par{"dirBup"}=$ARGV[1];}

    &iniGetArg;			# read command line input

    &iniChangePar;

    if ($Lscreen) { &myprt_line; &myprt_txt("$script_goal"); &myprt_empty; 
		    print "---\n--- end of '"."$script_name"."'_ini settings are:\n"; 
		    foreach $des (@desDef) {
			printf "--- %-20s '%-s'\n",$des,$par{"$des"};}&myprt_line;}
}				# end of ini

#==========================================================================================
sub iniHelp {
    $[ =1 ;
#--------------------------------------------------------------------------------
#    iniHelp                       
#--------------------------------------------------------------------------------
    # ------------------------------------------------------------
    # about script
    # ------------------------------------------------------------
    $script_name=   "port";
    $script_input=  "pub/topits doZip=1 (dirBup=bin,emacs,etc)";
    $script_goal=   "makes back up (tar, zip, asf)";
    $script_narg=   1;
    @script_goal=   (" ",
		     "Task: \t $script_goal"," ",
		     "Input:\t $script_input dir"," ",
		     "Done: \t ");
    @script_help=   ("Help: \t For further information on input options asf., please  type:",
		     "      \t '$script_name help'",
		     "      \t ............................................................",
		     );
    @script_opt_key=("dirBup=",
		     "dirHome=",
		     " ",
		     "not_screen",
		     "dirOut=",
		     );
    @script_opt_keydes= 
	            ("directories to back up (pub/phd,pub/topits) ",
		     "home directory (default /home/rost/) ",
		     " ",
		     "no information written onto screen",
		     "output directory       default: local (files copied there!)",
		     );

    if ( ($#ARGV==0) || ($ARGV[1]=~/^help|^man|^-h/) ) { 
	print "-" x 80, "\n", "--- \n"; &myprt_txt("Perl script"); 
	foreach $txt (@script_goal) {if($txt !~ /Done:/){&myprt_txt("$txt");}} 
	&myprt_empty;&myprt_txt("Optional:");
	foreach $desOpt(@desDef){
	    if ( defined $par{"$desOpt"} ){
		printf "--- %-12s=x \t (def:=%-s) \n",$desOpt,$par{"$desOpt"};}}
	&myprt_empty; print "-" x 80, "\n"; exit; }
    elsif ( $#ARGV < $script_narg ) {
	print "-" x 80, "\n", "--- \n";&myprt_txt("Perl script "); 
	foreach $txt (@script_goal){if($txt !~ /Done:/){&myprt_txt("$txt");}}
	foreach $txt (@script_help){&myprt_txt("$txt");}
	&myprt_empty;print"-" x 80,"\n";exit;}
}				# end of iniHelp

#==========================================================================================
sub iniDefaults {
#    local ($fileIn, $chain_in, $skip) = @_ ;
    $[ =1 ;
#--------------------------------------------------------------------------------
#    iniDefaults                       
#--------------------------------------------------------------------------------
    # ------------------------------------------------------------
    # defaults 
    # ------------------------------------------------------------
				# --------------------
				# directories
    $par{"dirOut"}=             "";
    $par{"dirHome"}=$dirHome=   "/home/rost/";

				# --------------------
				# files
    $par{"title"}=              "unk"; # appended to tar file names
#    $par{"fileTransl"}=         "/home/rost/port/all-translation.table";
				# --------------------
				# further
				# give e.g. incl=pub/phd  for phd
    $par{"dirBup"}=             ""; # directories to be backed up ('dir1,dir2')
    $par{"cmdTar"}=$cmdTar=     "tar -cvf"; # tar command
				# optional: 
				#    dot, sys, pub, phd, topits, max, perl, for, 
				# --------------------
				# logicals
    $Lscreen=                   1;      # blabla on screen
    $par{"doZip"}=              0;      # files will be zipped
    $par{"doTar"}=              1;      # will be tared (if not: copy only)
				# ------------------------------
				# a.a descriptors 
				# allowed in default file
				# ------------------------------
    @desDef=     ("dirOut","title","dirHome","dirBup","cmdTar",
		  "doZip","doTar");
}				# end of iniDefaults

#==========================================================================================
sub iniGetArg {
#    local ($fileIn, $chain_in, $skip) = @_ ;
    $[ =1 ;
#--------------------------------------------------------------------------------
#    iniGetArg                  read command line arguments
#--------------------------------------------------------------------------------
    # ------------------------------------------------------------
    # read input arguments
    # ------------------------------------------------------------

    if ($#ARGV==$script_narg) {
	return;}
    for($it=($script_narg+1);$it<=$#ARGV;++$it) {
	$_=$ARGV[$it];
	print "x.x read '$_'\n";
	if ( /not_screen/ ) {    $Lscreen=0; }
	else {
	    $Lok=0;
	    foreach $des (@desDef){
		if (/^$des=/){$_=~s/\s|\n|^.*$des=//g;
			      $par{"$des"}=$_; $Lok=1;
			      last;}}
	    if (! $Lok){print "*** iniGetArg: unrecognised argument: $_\n";
			exit;}}
    }
}				# end of iniGetArg

#==========================================================================================
sub iniChangePar {
    $[ =1 ;
#--------------------------------------------------------------------------------
#    iniChangePar               changing some parameters according to input arguments
#                               e.g. adding directories to file names asf
#--------------------------------------------------------------------------------
    # ------------------------------------------------------------
    # assignments dependent on input read
    # ------------------------------------------------------------
    $dirHome=$par{"dirHome"}=
	&complete_dir($par{"dirHome"});
				# split dirBup
    @dirBup=split(/,/,$par{"dirBup"});

    foreach $des (@desDef){	# complete dir
	if (($des !~ /^dir/)||($des eq "dirBup")){
	    next;}
	$par{"$des"}=&complete_dir($par{"$des"});}
}				# end of iniChangePar

#==========================================================================================
sub mkDir { local($inLoc,$LscreenLoc)=@_;
	    $[ =1 ;
#--------------------------------------------------------------------------------
	    if ($LscreenLoc) { print "--- system \t \t 'mkdir $inLoc'\n";}
	    system("mkdir $inLoc"); 
	    if (! -d $inLoc){ 
		print "*** no dir=$inLoc,\n";
		return(0);}
	    return(1);}		# end of mkDir

#==========================================================================================
sub cpFile { local($inLoc1,$inLoc2,$LscreenLoc)=@_;
	     $[ =1 ;
#--------------------------------------------------------------------------------
	     if ($LscreenLoc) { print "--- system \t \t '\\cp $inLoc1 $inLoc2'\n";}
	     system("\\cp $inLoc1 $inLoc2"); 
	     if (! -e $inLoc2){ 
		 print "*** no file=$inLoc2,\n";
		 return(0);}
	     return(1);}		# end of cpFile

#==========================================================================================
sub mvFile { local($inLoc1,$inLoc2,$LscreenLoc)=@_;
	     $[ =1 ;
#--------------------------------------------------------------------------------
	     if ($LscreenLoc) { print "--- system \t \t '\\mv $inLoc1 $inLoc2'\n";}
	     system("\\mv $inLoc1 $inLoc2"); 
	     if (! -e $inLoc2){ 
		 print "*** no file=$inLoc2,\n";
		 return(0);}
	     return(1);}		# end of mvFile

