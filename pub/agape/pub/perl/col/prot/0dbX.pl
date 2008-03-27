#!/usr/bin/perl
#!/usr/sbin/perl -w
#----------------------------------------------------------------------
# aqua
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# usage: 	dbX.pl fileList options
#
# task:		extracting info for NN from databases (H/D/FSSP, PDB, SWISS-PROT)
# 		
# subroutines   (internal):  
#               x
#                                  y
# 		
#
#----------------------------------------------------------------------#
#	Burkhard Rost		       August,          1996           #
#			changed:       .	,    	1996           #
#	EMBL			       Version 0.1                     #
#	Meyerhofstrasse 1                                              #
#	D-69117 Heidelberg		(rost@EMBL-Heidelberg.DE)      #
#----------------------------------------------------------------------#
				# sets array count to start at 1, not at 0
$[ =1 ;
				# include libraries
push (@INC, "/home/rost/perl","/u/rost/") ;
require "ctime.pl";		# require "rs_ut.pl" ;
require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
$Lembl=1;			# switch EBI/EMBL

				# initialise variables
&iniDbX;

# --------------------------------------------------------------------------------
# do the job (here we go)
# --------------------------------------------------------------------------------

&open_file("$fhin", "$fileIn");

while (<$fhin>) {
    $tmp=$_;$tmp=~s/\n//g;
    if (length($tmp)==0) { next; }
}
close($fhin);

# --------------------------------------------------------------------------------
# work done
# --------------------------------------------------------------------------------
if ($Lscreen) { &myprt_empty; &myprt_line; &myprt_txt(" $script_name has ended fine .. -:\)"); 
		&myprt_empty; &myprt_txt(" output in file: \t $fileOut"); }

exit;

#==========================================================================================
sub iniDbX {
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
    $PWD=                       $ENV{'PWD'};
    $ARCH=                      $ENV{'ARCH'};

    &iniHelp;

    &iniDefaults;               # first settings for parameters (may be overwritten by
				# default file and command line input)

    &iniRdDefManager;		# get stuff from default file
    
    $fileIn=       $ARGV[1];	# file with ids

    &iniGetArg;			# read command line input

    &iniChangePar;

    @fileDel=       ($par{"fileDbg"});

    if ($Lscreen) { &myprt_line; &myprt_txt("$script_goal"); &myprt_empty; 
		    print "---\n--- end of '"."$script_name"."'_ini settings are:\n"; 
		    &myprt_txt("fileIn: \t \t $fileIn"); 
		    &myprt_txt("fileOut:\t \t $fileOut"); 
		    foreach $des (@desDef) {
			printf "--- %-20s '%-s'\n",$des,$par{"$des"};}&myprt_line;}

    # ------------------------------------------------------------
    # check existence of file
    # ------------------------------------------------------------
    if ( (length($fileIn)>0) && (! -e $fileIn) ) {
	&myprt_empty;&myprt_txt("ERROR $script_name:\t fileIn '$fileIn' does not exist");exit;}

}				# end of ini

#==========================================================================================
sub iniHelp {
    $[ =1 ;
#--------------------------------------------------------------------------------
#   iniHelp                       
#--------------------------------------------------------------------------------
    # ------------------------------------------------------------
    # about script
    # ------------------------------------------------------------
    $script_name=   "dbX";
    $script_input=  "fileList options";
    $script_goal=   "extracting info for NN from databases (H/D/FSSP, PDB, SWISS-PROT)";
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
    @script_opt_key=(" ",
		     " ",
		     " ",
		     "title=",
		     " ",
		     "not_screen",
		     "dirIn=",
		     "dirOut=",
		     "dirWork=",
		     );
    @script_opt_keydes= 
	            (" ",
		     " ",
		     " ",
		     "title of output files",
		     " ",
		     " ",
		     "no information written onto screen",
		     "input directory        default: local",
		     "output directory       default: local",
		     );

    if ( $ARGV[1]=~/^help|^man|^-h|^-m/ ) { 
	print "-" x 80, "\n", "--- \n"; &myprt_txt("Perl script"); 
	foreach $txt (@script_goal) {if($txt !~ /Done:/){&myprt_txt("$txt");}} 
	&myprt_empty;&myprt_txt("Optional:");
	for ($it=1; $it<=$#script_opt_key; ++$it) {
	    printf "--- %-12s %-s \n",$script_opt_key[$it],$script_opt_keydes[$it]; }
	&myprt_empty; print "-" x 80, "\n"; exit; }
    elsif ( $#ARGV < $script_narg ) {
	print "-" x 80, "\n", "--- \n";&myprt_txt("Perl script "); 
	foreach $txt (@script_goal){if($txt !~ /Done:/){&myprt_txt("$txt");}}
	foreach $txt (@script_help){&myprt_txt("$txt");}
	&myprt_empty;print"-" x 80,"\n";exit;}
}				# end of iniHelp

#==========================================================================================
sub iniDefaults {
    $[ =1 ;
#--------------------------------------------------------------------------------
#    iniDefaults                       
#         c
#       in:
#         A                     A
#       out:
#         A                     A
#--------------------------------------------------------------------------------
    # ------------------------------------------------------------
    # defaults 
    # ------------------------------------------------------------
				# --------------------
				# directories
    $par{"dirIn"}=             "";
    $par{"dirOut"}=            "";
    $par{"dirWork"}=           "";
				# --------------------
				# files
    $par{"title"}=              "unk";
    $par{"fileOut"}=            "unk";
				# file extensions
    $par{"preDbg"}=             "DebugDbX_";
    $par{"extDbg"}=             ".tmp";
    $par{"preOut"}=             "DbX_";
    $par{"extOut"}=             ".rdb";
				# file handles
    $fhout=                     "FHOUT";
    $fhoutDbg=                  "FHOUT_DbgDbX";
    $fhin=                      "FHIN";
				# --------------------
				# further
				# computing Alignment Shift
				# databases read
    $par{"dbRead"}=             "HSSP,";   

				# --------------------
				# logicals
    $Lscreen=                   1;   # blabla on screen
				# --------------------
				# executables

				# ------------------------------
				# a.a descriptors 
				# allowed in default file
				# ------------------------------
    @desDef=     ("dirIn","dirOut","dirWork",
		  "dirHssp","dirDssp","dirFssp","dirPdb","dirSwiss",
		  "title","fileOut","preDbg","extDbg","preOut","extOut",
		  "dbRead",
		  "",
		   );
    @desFileOut= ("fileOut");
    @desFileIn=  ("fileOut");
    @desFileWork=("fileOut");
}				# end of iniDefaults

#==========================================================================================
sub iniRdDefManager {
    $[ =1 ;
#--------------------------------------------------------------------------------
#    iniRdDefManager            manages reading the default file
#--------------------------------------------------------------------------------
    $Lok=0;
				# ------------------------------
    foreach $_(@ARGV){		# default file given on command line?
	if  (/^fileDefaults=/){
	    $fileDefaults=$_;$fileDefaults=~s/^fileDefaults=|\s|\n//g;
	    if (! -e $fileDefaults) {
		print "*** ERROR in iniRdDefManager: you gave the default file by '$_'\n";
		print "***                           but file '$fileDefaults' not existing!\n";
		exit;}
	     $Lok=1;
	     last;}}
				# ------------------------------
				# search default file
    if (! defined $fileDefaults) { # search file with defaults
	foreach $dir ("","$dirWork","$dirIn","/sander/purple1/rost/topits/dbX/"){
	    $dir=&complete_dir($dir);
	    $fileDefaults="$dir"."dbX.defaults";
	    if  (-e $tmp) {
		print "--- iniRdDefManager: defaults taken from file '$fileDefaults'\n";}}}
				# ------------------------------
    if (-e $fileDefaults) { 	# now read the default file
	($desRdDef,%defaults)= 
		&iniRdDef($fileDefaults,$Lscreen_det); 

	&iniRdDefCheckKeys($desRdDef,$fileDefaults);

	print "-*- WARNING content of '$fileDefaults' may overwrite hard coded parameters\n";
        foreach $des (@desDef) {
	    if (defined $defaults{"$des"}) {
	    	if ($des !~ /exe/) {$par{"$des"}=$defaults{"$des"};} 
	    	else               {$exe{"$des"}=$defaults{"$des"};} }}}
    else {
	if ($Lscreen) { print "-*- WARNING no default file found\n";}}
}				# end of iniRdDefManager

#==========================================================================================
sub iniRdDef {
    local ($fileLoc,$Lscreen)=@_;
    local ($fhin,$tmp,@tmp,%defaults);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    IniRdDef     reads defaults for initialsing dbX parameters
#       in:                     file_default
#       out:
#         $defaults{"des"}=val  if in default file: 
#                               "des1"    val1
#                               "des2"    val2
#--------------------------------------------------------------------------------
    if ($Lscreen){
	print "-" x 80,"\n","--- \n","--- Reading default file \t '$fileLoc'\n","--- \n";}
    $fhin="FHIN_DEFAULTS";
    %defaults=0;
    undef @desRdDef;
    &open_file("$fhin","$fileLoc");
    while (<$fhin>){
	if ((length($_)<3)||(/^\#/)) {	# ignore lines beginning with '#'
 	    next;}
	@tmp=split(/[ \t]+/);
	foreach $tmp (@tmp) { 
	    $tmp=~s/[ \n]*$//g;	# purge end blanks
	}
	$desRdDef.="$tmp[1]".",";
				# push with blanks
	if (defined $defaults{"$tmp[1]"}) {
	    $defaults{"$tmp[1]"}.="  " . $tmp[2]; }
	else {
	    $defaults{"$tmp[1]"}=$tmp[2]; }
	if ($Lscreen){printf "--- read: %-22s (%s)\n",$tmp[1],$tmp[2];}
    }
    close($fhin);
    return ($desRdDef,%defaults);
}				# end of iniRdDef

#==========================================================================================
sub iniRdDefCheckKeys {
    local ($desRdDef,$fileDefaults) = @_ ;
    $[ =1 ;
#--------------------------------------------------------------------------------
#   iniRdDefCheckKeys           checks whether all keys found in default file
#				are comprehensible
#--------------------------------------------------------------------------------
    $desRdDef=~s/^,|,$//g;
    @tmp=split(/,/,$desRdDef);
    $Lokall=0;
    foreach $desRd(@tmp){
	$Lok=0;
	foreach $desWant(@desDef){
	    if ($desRd eq $desWant){
		$Lok=1;$Lokall=1;
		last;}}
	if ($Lok){
    	    print "*** iniiRdDefCheckKeys: default file contains unrecognised key '$desRd'\n";}}
    if ($Lokall){
	print "*** the default file that was read is '$fileDefaults'\n";
	exit;}
}				# end of iniRdDefCheckKeys

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
    $Lokdef=0;
    for($it=($script_narg+1);$it<=$#ARGV;++$it) {
	$_=$ARGV[$it];
	if ( /not_screen/ ) {    $Lscreen=0; }
	else {
	    $Lok=0;
	    foreach $des (@desDef){
		if (/^$des=/){
		    $_=~s/\s|\n|^.*$des=//g;
		    if ($des=~/^exe/){$par{"$des"}=$_; }
		    else             {$exe{"$des"}=$_; }
		    $Lok=1;$Lokdef=1;
		    last;}}
	    if (! $Lok){print "*** iniGetArg: unrecognised argument: $_\n";
			exit;}}}
				# ------------------------------
				# process input
    foreach $arg (@ARGV){
    }
    if ($Lokdef) {
	print "-*- WARNING iniGetArg: command line arguments overwrite '$fileDefaults'\n";}
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
    if ((! defined $par{"fileDbg"})||($par{"fileDbg"} eq "unk")){
	$tmp=$fileIn;$tmp=~/^.*\/|\..*$//g;
	$fileDbg=$par{"fileDbg"}=$par{"dirWork"}.$par{"preDbg"}.$tmp.$par{"extDbg"};}

    if ( (! defined $fileOut) || ($fileOut eq "unk") || (length($fileOut) < 1) ) {
	$pre=$ext="";
	if ( (defined $par{"preOut"}) && ($par{"preOut"} ne "unk") ){
	    $pre=$par{"preOut"};}
	if ( (defined $par{"extOut"}) && ($par{"extOut"} ne "unk") ){
	    $ext=$par{"extOut"};}
	if ( (defined $title) && ($title ne "unk") ) {
	    $fileOut="$pre"."$title"."$ext";}}

    if (length($par{"dirIn"})>1) {   
	$par{"dirIn"}=&complete_dir($par{"dirIn"});
	$fileIn=$par{"dirIn"}."$fileIn";}
    if (length($par{"dirOut"})>1) {  
	$par{"dirOut"}=&complete_dir($par{"dirOut"});
	$fileOut=$par{"dirOut"}."$fileOut";}
    if (length($par{"dirWork"})>1) { 
	$par{"dirWork"}=&complete_dir($par{"dirWork"}); }

}				# end of iniChangePar

#==========================================================================================
sub subx {
#    local ($fileIn, $chain_in, $skip) = @_ ;
    $[ =1 ;
#--------------------------------------------------------------------------------
#    subx                       
#         c
#       in:
#         A                     A
#       out:
#         A                     A
#--------------------------------------------------------------------------------

}				# end of subx


