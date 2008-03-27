#!/usr/bin/perl
##!/usr/sbin/perl4 -w
##!/usr/bin/perl
#-------------------------------------------------------------------------------
# to be done : grep for yy
# 
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$scriptName=   "lociGetData";
$scriptIn=     "one argument (e.g. fileInHsspLoci=merge25-hssp-swiss.rdb)";
$scriptTask=   "extract files with locations (from SWISS, HSSP, ...)";
$scriptNarg=   1;
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# hierarchy of lists:
#
#    step 1     swiss kinglist:    in:     /data/swissprot/speclist.txt
#                                  format: ABIMA E0700: N=ACHROMOBACTER XYLOSOXIDANS
#                                  out:    'abima' if grepped for 'proka'
#    step 2     swiss speclist:    in:     flat-file-listing-species (out of previous)
#                                  format: abima
#                                          abpr
#                                  out:    all swissprot files of species 'achxy'
#                                  format: /data/swissprot/current/a/rbl_abima
#    step 3     swiss locilist:    in:     flat-file-listing-swissprot (out of previous)
#                                  out:    locations of files in speclist
#                                  format (RDB):
#                                          # Perl-RDB
#                                          lineNo  id              location 
#                                             5N   15              
#                                              1   rbl_abima       CHLOROPLAST.
#    INTER      NOW HAS to be      locations in @loci and @lociId (names)
#
#    INTER      restrict           e.g. to 'NUCLEAR.'
#    
#    step 4     hssp swiss-ids     in:     
#                                  returns all swiss-prot homologues
#               x
#                                  x
#               
# subroutines   (internal):  
#     ini                       initialises variables/arguments
#     iniHelp                   initialise help text
#     iniDefaults               initialise defaults
#     iniRdDefManager           manages reading the default file
#     iniRdDef                  reads defaults for initialsing parameters
#     iniRdDefCheckKwd          checks whether all keys found in default file
#     iniGetArg                 read command line arguments
#     iniChangePar              changing parameters according to input arguments
#     cleanUp                   deletes intermediate files
#     getHsspAlis               gets all statistics for all SWISS prot in HSSP
#     getHsspLoci               reads  HSSP header and SWISS-PROT loci
#     getHsspProf               gets HSSP profiles for best hits
#     getSwissKing              gets all species of given kingdom
#     getSwissLoci              gets all locations for given SWISS-PROT files
#     getSwissSpec              gets all files for given species
#     hsspManager               calls the readers for HSSP, compares what is
#     swissManager              calls all the readers for SWISS-PROT
#     wrtHsspProfHeader         write out statistics for profiles
#     wrtHsspProfOne            write out statistics for profiles
#     wrtSwissStat              write out statistics for Singiles
#     wrtSwissStatHeader        write out statistics for each homologue
# 		
#
#------------------------------------------------------------------------------#
#	Copyright				January,	1997	       #
#	Burkhard Rost		rost@EMBL-Heidelberg.DE			       #
#	EMBL			http://www.embl-heidelberg.de/~rost/	       #
#	D-69012 Heidelberg						       #
#				version 0.1   	January,	1997	       #
#------------------------------------------------------------------------------#
				# sets array count to start at 1, not at 0
$[ =1 ;
				# ------------------------------
				# include perl libraries
#push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
##require "ctime.pl";
#require "lib-ut.pl"; require "lib-br.pl";
				# intermediate x.x

#@ARGV=split(/\s+/,&get_in_keyboard("command line"));	# x.x mac specific

print "--- \n";			# avoid segmentation fault on phenix
print "--- \n";			# avoid segmentation fault on phenix

				# ------------------------------
$Lok=&ini();			# initialise variables
die if (! $Lok);

#-------------------------------------------------------------------------------
# do the job (here we go)
#-------------------------------------------------------------------------------
				# --------------------------------------------------
				# getting data from SWISS-PROT
				# --------------------------------------------------
				# GLOBAL out: @loci, @lociId, $loci{"id"}="location"
$Lok=&swissManager();
				# ------------------------------
				# getting HSSP data and merge
				# ------------------------------
$Lok=&hsspManager();
				# ------------------------------
				# write statistics for single
				# ------------------------------
&wrtSwissStatHeader();
&wrtSwissStat();

#-------------------------------------------------------------------------------
# work done, go home
#-------------------------------------------------------------------------------
if (! $par{"debug"}){		# deleting intermediate files
    &cleanUp();}
if ($Lverb) { &myprt_empty; &myprt_line; &myprt_txt("$scriptName ended fine .. -:\)"); 
	      &myprt_txt("output files  \t ");
	      foreach $_(@fileOut){
		  if (-e $_){
		      printf "--- %-20s %-s\n"," ",$_;}}}
exit;

#===============================================================================
sub ini {
    local (@scriptTask,@scriptHelp,@scriptKwd,@scriptKwdDescr,$txt);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   initialises variables/arguments
#-------------------------------------------------------------------------------
#	$date is e.g.:		Thu Oct 14, 1993 13:06:47
#	@Date is e.g.:		Oct,14,13:06:47,1993
#	&ctime(time) is e.g.:	Thu Oct 14 13:06:47 1993
#
#    @Date = split(' ',&ctime(time)) ; 
#    $date="$Date[1] $Date[2] $Date[3], $Date[5] $Date[4]"; shift (@Date) ; 
    
    $PWD=                       $ENV{'PWD'}; $pwd=&complete_dir($PWD);
    $ARCH=                      $ENV{'ARCH'}; 
    if (!defined $ARCH)         {print "-*- WARNING \t no architecture defined\n";}

    &iniDefaults();             # first settings for parameters (may be overwritten by
				# default file and command line input)
    &iniHelp();

    $Lok=&iniRdDefManager();	# get stuff from default file
    if (! $Lok){print "*** ini ($scriptName) ERROR in iniRdDefManager\n";
		return(0);}

    $Lok=&iniGetArg();		# read command line input
    if (! $Lok){print "*** ini ($scriptName) ERROR in  iniGetArg\n";
		return(0);}

    $Lok=&iniChangePar();
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
		    if (! defined $par{"$kwd"}){$tmp="!! UNDEF !!";}else{$tmp=$par{"$kwd"};}
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
		     "fileInExclPair=",
		     " ",
		     "title=",
		     " ",
		     "not_screen",
		     "dirIn=",
		     "dirOut=",
		     "dirWork=",
		     );
    @scriptKwdDescr=(" ", 
		     "file with ids to exclude, possible: Excl-glyco.list,Excl-strange.list ",
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
    $par{"dirIn"}=             ""; # directory with input files
    $par{"dirOut"}=            ""; # directory for output files
    $par{"dirWork"}=           ""; # working directory
				# databases
    $par{"dirHssp"}=           "/data/hssp/";
#    $par{"dirHssp"}=           "/sander/sander4/purple1/rost/work/loci/hssp/";
    $par{"dirSwissDoc"}=       "/data/swissprot/"; # SWISS-PROT documents
    $par{"dirSwissSeq"}=       "/data/swissprot/current/"; # SWISS-PROT sequences
				# mystuff
    $par{"dirDataSwiss"}=      "/home/rost/pub/data/swiss/"; # swiss prot related data lists
    $par{"dirDataHssp"}=       "/home/rost/pub/data/hssp/"; # HSSP related data lists
    $par{"dirPerl"}=           "/home/rost/perl/scr/";
				# --------------------
				# files
				# notation 'SPECIES V|P|E|A\d+ ..'
    $par{"fileInSwissKingdom"}=$par{"dirSwissDoc"}."speclist.txt"; # list of species/kingdoms
				# list of species for given kingdom (pre-compiled)
    $par{"fileInSwissKingList"}=$par{"dirDataSwiss"}."all-euka-species.list"; # 
				# list of swissprot files in kingdom (pre-compiled)
    $par{"fileInSwissSpecList"}=$par{"dirDataSwiss"}."all-euka.list";
				# all eukas with location ("^CC .*SUBCELLULAR LOCATION:")
    $par{"fileInSwissLoci"}=    $par{"dirDataSwiss"}."all-euka-with-loci.rdb";
				# list of HSSP files to read
    $par{"fileInHsspList"}=     $par{"dirDataHssp"}."hssp849-seqUnique-noChain.list";
				# swiss-prot homologues to HSSP files
    $par{"fileInHsspHeader"}=   $par{"dirDataHssp"}."Hssp849-pide40-95.rdb";
    $par{"fileInHsspHeader"}=   $par{"dirDataHssp"}."Hssp1515-pide50-95.rdb";
				# e.g. produced by running merge-hssp-swiss.pl
    $par{"fileInHsspLoci"}=     "Merge25-hssp-swiss.rdb";
    $par{"fileInHsspLoci"}=     "Merge95-hssp-swiss.rdb";
#    $par{"fileInHsspLoci"}=     "tmp-merge.rdb";
				# file with id's to exclude
				# list given by comma
                                # notation: PDBid,SWISSid (* for wild card)
    $par{"fileInExclPair"}=     "Excl-glyco.list,Excl-strange.list";

    $par{"title"}=              "unk"; # output files will be called 'Pre-title.ext'

    $par{"fileOutSwissKingList"}="no"; # list of all species in e.g. eukaryotes
    $par{"fileOutSwissSpecList"}="no"; # list of all species in e.g. eukaryotes
    $par{"fileOutSwissLoci"}=   "no"; # list of all files in e.g. eukaryotes
				# note: file needed, if 'no' here -> intermediate
    $par{"fileOutHsspHeader"}=  "Out-hsspHeader.rdb";
    $par{"fileOutHsspHeader"}=  "no";

    @tmp=@ARGV;
    foreach $_ (@tmp){if ($_ =~ /^preOut=/){$_=~s/^preOut=|\s//g;$par{"preOut"}=$_;
					    last;}}
    if (! defined $par{"preOut"}){
	$par{"preOut"}=             "x4-";
	$par{"preOut"}=             "y4-";
#	$par{"preOut"}=             "tx4-";
    }
    $par{"extOut"}=             ".dat";
    $par{"extOut"}=             ".rdb";
    $par{"fileOutHsspProfE"}=   $par{"preOut"}."profExp".$par{"extOut"}; # general
    $par{"fileOutHsspProfB"}=   $par{"preOut"}."profBur".$par{"extOut"}; # general
    $par{"fileOutHsspProfA"}=   $par{"preOut"}."profAll".$par{"extOut"}; # irrespective of acc
    $par{"fileOutHsspSingE"}=   $par{"preOut"}."singExp".$par{"extOut"}; # only AAs from pdb
    $par{"fileOutHsspSingB"}=   $par{"preOut"}."singBur".$par{"extOut"}; # only AAs from pdb
    $par{"fileOutHsspSingA"}=   $par{"preOut"}."singAll".$par{"extOut"}; # only AAs from pdb

    $par{"fileOutSwissE"}=      $par{"preOut"}."swissExp".$par{"extOut"}; # general
    $par{"fileOutSwissB"}=      $par{"preOut"}."swissBur".$par{"extOut"}; # general
    $par{"fileOutSwissA"}=      $par{"preOut"}."swissAll".$par{"extOut"}; # general

				# file extensions
    $par{"extOut"}=             ".tmp";
				# file handles
    $fhout=                     "FHOUT";
    $fhin=                      "FHIN";
				# --------------------
				# further
				# computing Alignment Shift

				# --------------------
				# logicals
    $par{"doSwissKingList"}=    0; # recompile list of files with all species (in e.g. euka)
    $par{"readSwissKingList"}=  0; # reads list of species from fileInSwissKinglist

    $par{"doSwissSpecList"}=    0; # recompile list of all SWISS-PROT files of @species
    $par{"readSwissSpecList"}=  0; # reads the list of all swiss-prot files of @species

    $par{"doSwissLoci"}=        0; # compile a list with locations for given SWISS files
    $par{"readSwissLoci"}=      0; # compile a list with locations for given SWISS files

    $par{"doHsspHeader"}=       0; # extract SWISS-PROT homologues from HSSP files
    $par{"readHsspHeader"}=     0; # read SWISS-PROT homologues from HSSP header
    
    $par{"readHsspLoci"}=       1; # reads the file containing HSSP header and loci

    $Lverb=                     1; # blabla on screen
    $Lverb2=                    0; # more verbose blabla
    $Lverb3=                    0; # more verbose blabla
				# --------------------
				# executables
    $par{"exeHsspExtrHeader"}=  $par{"dirPerl"}."hssp_extr_header.pl";
				# --------------------
				# other
    $par{"swissKing"}=          "euka";	# restrict to species (all,euka,proka,virus,archae)
				# regular expression to find files with locations
    $par{"swissLociRegexp"}=    "^CC .*SUBCELLULAR LOCATION:";
				# regular expression to restrict locations found
    $par{"swissLociRestrict"}=  "cytoplasmic\.|nuclear\.|extracellular\.";

    $par{"hsspLowPide"}=        40; # minimal percentage sequence identity
    $par{"hsspUpPide"}=		95; # maximal percentage sequence identity
    $par{"hsspLowR1A"}=         0.3; # minimal ratio len1/lenAli

    $par{"statExposed"}=        25; # acids with relative accessibility higher than that
				# regarded as exposed
    $par{"statMinLali"}=        40; # minimal length of protein
    $par{"statMinRatio"}=       0.0; # minimal length identity
#    $par{"statMinRatio"}=       0.5; # minimal length identity
				# ------------------------------
				# a.a descriptors 
				# allowed in default file
				# ------------------------------
    @kwdDef=     ("debug","verbose","verbose2","dirIn","dirOut","dirWork",
		  "dirSwissDoc","dirSwissSeq","dirHssp","dirPerl","dirDataSwiss","dirDataHssp",

		  "fileInSwissKingdom",
		  "fileInSwissKingList","fileInSwissSpecList","fileInSwissLoci",
		  "fileInHsspList","fileInHsspHeader","fileInHsspLoci",
		  "fileInExclPair",

		  "title","preOut","extOut","fileOutHsspHeader",
		  "fileOutSwissKingList","fileOutSwissSpecList","fileOutSwissLoci",
		  
		  "fileOutHsspProfE","fileOutHsspProfB","fileOutHsspProfA",
		  "fileOutHsspSingE","fileOutHsspSingB","fileOutHsspSingA",
		  "fileOutSwissE","fileOutSwissB","fileOutSwissA",

		  "exeHsspExtrHeader",
		  "swissKing","swissLociRegexp","swissLociRestrict",
		  "hsspLowPide","hsspUpPide","hsspLowR1A",
		  "statExposed","statMinLali","statMinRatio",

		  "doSwissKingList","doSwissSpecList","doSwissLoci",
		  "readSwissKingList","readSwissSpecList","readSwissLoci",
		  "doHsspHeader","readHsspHeader","readHsspLoci");

    @kwdRdHsspRdb=("ID1","ID2","STRID","IDE","WSIM","LEN1","LEN2","LALI","NGAP","LGAP",
		   "IFIR","ILAS","JFIR","JLAS");
    @aaNamesHssp= ("V","L","I","M","F","W","Y","G","A","P",
		   "S","T","C","H","R","K","Q","E","N","D");
#    @aaNamesAbcd= ("A","C","D","E","F","G","H","I","K","L",
#		   "M","N","P","Q","R","S","T","V","W","Y")
    $lociUnk=       "?";
    %lociInterpret= (
		     'cytoplasmic',  "cyt", 
		     'extracellular',"ext",
		     'nuclear',      "nuc",
		     'all-other',    "$lociUnk",
		     );
    %LlociInterpret=(
		     'cytoplasmic',  "1",
		     'extracellular',"1",
		     'nuclear',      "1",
		     );
    %Lloci=(
		     'cyt',  "1",
		     'ext',"1",
		     'nuc',      "1",
		     );
    @lociAbbrev=
	('cyt','ext','nuc');
}				# end of iniDefaults

#===============================================================================
sub iniRdDefManager {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iniRdDefManager             manages reading the default file
#-------------------------------------------------------------------------------
    $Lok=0;
				# ------------------------------
    foreach $_(@ARGV){		# default file given on command line?
	if    ($_=~/^verb\w*3/){$Lverb3=1;}
	elsif ($_=~/^verb\w*2/){$Lverb2=1;}
	elsif ($_=~/^verbose/) {$Lverb=1;}
	elsif ($_=~/^fileDefaults=(.+)$/){
	    $fileDefaults=$1;$fileDefaults=~s/\s//g;
	    if (! -e "$fileDefaults") {
		print "*** ERROR iniRdDefManager: you gave the default file by '$_'\n";
		print "***                        but file '$fileDefaults' not existing!\n";
		return(0);}
	    $Lok=1;
	    last;}}
				# ------------------------------
    foreach $_(@ARGV){		# input/work directory
	if ($_=~/^(dirIn|dirWork)=(.+)$/){$kwd=$1;$dir=$2;
					  $dir=&complete_dir($dir);	# external lib-ut.pl
					  $par{"$kwd"}=$dir;}}
				# ------------------------------
				# search default file
    if ((! defined $fileDefaults)||(! -e $fileDefaults)) { # search file with defaults
	if (defined $pwd){@tmpDir=("$pwd");}else{$#tmpDir=0;}
	foreach $des ("dirWork","dirIn"){
	    if ((defined $par{$des})&&(-d $par{$des})){push(@tmpDir,$par{$des});}}
				# local directory
	$fileDefaults=$scriptName.".defaults";
	    if  (-e $fileDefaults) {
		print "--- iniRdDefManager: defaults taken from file '$fileDefaults'\n";}
	foreach $dir (@tmpDir){
	    if ((! defined $dir)||(! -d "$dir")){ 
		next;}
	    $fileDefaults="$dir".$scriptName.".defaults";
	    if  (-e $fileDefaults) {
		print "--- iniRdDefManager: defaults taken from file '$fileDefaults'\n";}
	    last;}}
    if ((! defined $fileDefaults)||(! -e "$fileDefaults")){
	print "*** STRONG WARNING: no defaults file found\n" x 3 ;
	return(1);}
				# ------------------------------
    elsif (-e "$fileDefaults") { # now read the default file
	$kwdRdDef= 
		&iniRdDef($fileDefaults,$Lverb2); 

	$Lok=&iniRdDefCheckKwd($kwdRdDef,$fileDefaults);
	if (! $Lok){print "*** ini ($scriptName) ERROR in  iniRdDefManager:iniRdDefCheckKwd\n";
		    return(0);}

	print "-*- WARNING '$fileDefaults' may overwrite hard coded parameters\n";
        foreach $kwd (@kwdDef) {
	    if (defined $defaults{"$kwd"}) {
		$par{"$kwd"}=$defaults{"$kwd"};}}}
    return(1);
}				# end of iniRdDefManager

#===============================================================================
sub iniRdDef {
    local ($fileLoc,$Lverb)=@_;
    local ($fhin,$tmp,@tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   IniRdDef                    reads defaults for initialsing parameters
#       in:                     file_default
#       out:
#         $defaults{"kwd"}=val  if in default file: 
#                               "kwd1"    val1
#                               "kwd2"    val2
#-------------------------------------------------------------------------------
    if ($Lverb){
	print "-" x 80,"\n","--- \n","--- Reading default file \t '$fileLoc'\n","--- \n";}
    $fhin="FHIN_DEFAULTS";
    %defaults=0;		# setting zero
    undef @kwdRdDef; $kwdRdDef="";
    &open_file("$fhin","$fileLoc"); # external lib-ut.pl
    while (<$fhin>){
	if ((length($_)<3)||(/^\s*\#/)) { # ignore lines beginning with '#'
 	    next;}
	if (!/\w/){
	    next;}
	@tmp=split(/[ \t]+/);
	if ($#tmp<2){		# must find 2 arguments
	    next;}
	foreach $tmp (@tmp) { 
	    $tmp=~s/[ \n]*$//g; } # purge end blanks
	$kwdRdDef.="$tmp[1]"."," unless (defined $defaults{"$tmp[2]"}); 
	if ($tmp[2]=~/^(local|unk)$/){
	    next;}
	if ($tmp[1] =~/^dir/){	# add '/' at end of directories
	    $tmp[2]=&complete_dir($tmp[2]);} # external lib-ut.pl
	$defaults{"$tmp[1]"}=$tmp[2]; 
	if ($Lverb2){printf "--- read: %-22s (%s)\n",$tmp[1],$tmp[2];}
    }
    close($fhin);
    return ($kwdRdDef);
}				# end of iniRdDef

#===============================================================================
sub iniRdDefCheckKwd {
    local ($kwdRdDef,$fileDefaults) = @_ ;
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iniRdDefCheckKwd            checks whether all keys found in default file
#				are comprehensible
#-------------------------------------------------------------------------------
    $kwdRdDef=~s/^,|,$//g;
    @tmp=split(/,/,$kwdRdDef);
    $Lokall=0;
    foreach $kwdRd(@tmp){$Lok=0;
			 foreach $kwdDef (@kwdDef){
			     if ($kwdRd eq $kwdDef){
				 $Lok=1;$Lokall=1;
				 last;}}
			 if (! $Lok){
			     print "*** iniRdDefCheckKwd: def. file strange key:$kwdRd,\n";}}
    if ($Lokall){
	print "--- read default file '$fileDefaults'\n";}
    return(1);
}				# end of iniRdDefCheckKwd

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
	elsif ( $arg=~ /dbg/ )         { $par{"debug"}=0; }
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
    if ($Lokdef && $Lverb) {
	print "-*- WARNING iniGetArg: command line arguments overwrite '$fileDefaults'\n";}
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
    $#inExclPair=0;		# exclude some pairs file
    if ((defined $par{"fileInExclPair"})&&($par{"fileInExclPair"} ne "unk")){
	print "--- $sbrName exclude ids from ",$par{"fileInExclPair"},"\n" if ($Lverb);
	$#fileInExclPair=0;@fileInExclPair=split(/,/,$par{"fileInExclPair"});
	foreach $file (@fileInExclPair){
	    if (! -e $file){print"*** iniChangePar: no '$file'\n";
			    next;
			    return(0);}
	    &open_file("$fhin","$file"); # external lib-ut.pl
	    while (<$fhin>){next if (/^\#/);
			    $_=~s/\s//g;
			    push(@inExclPair,$_);}close($fhin);}}
	    
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

				# ------------------------------
				# multiple search directories for HSSP files
    $par{"dirHssp"}=~s/,$//g;
    @dirHssp=split(/,/,$par{"dirHssp"});
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
sub getHsspAlis {
    local($sbrName,$fhinLoc,$tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getHsspAlis                  gets all statistics for all SWISS prot in HSSP
#   variables are GLOBAL 
#-------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";}
    $sbrName="$tmp"."getHsspAlis";$fhinLoc="FHIN"."$sbrName";

    $#posAll=$#hssp=0;%Ldone=0;
    foreach $it (1..$rd{"NROWS"}){
	$hssp=$rd{"ID1",$it}; $hssp=~s/\s//g;
	$swiss=$rd{"ID2",$it};$swiss=~s/\s//g;
	next if (! defined $rd{"loci",$it});
	next if ($rd{"LALI",$it}<$par{"statMinLali"});
	next if ($rd{"LEN2",$it}==0);
	next if ($rd{"LEN1",$it}==0);
	next if (($rd{"LALI",$it}/$rd{"LEN1",$it}<$par{"statMinRatio"})||
		 ($rd{"LALI",$it}/$rd{"LEN2",$it}<$par{"statMinRatio"}));
	$loci=$rd{"loci",$it};$loci=~s/\s//g;
				# interpret location (class to take? or other)
	if ( (defined $Lloci{$loci}) && ($Lloci{$loci}) ){
	    $loci=$rd{"loci",$it}=$lociInterpret{$loci};}
	else {$loci=$rd{"loci",$it}=$lociUnk;}
	
	if (! defined $Ldone{$hssp}){
	    $Ldone{$hssp}=1;$homo{$hssp}="";push(@hssp,$hssp);$tmpHssp="$loci";}
	if (defined $lociHssp{$hssp}){ # for curiosity
	    $lociHssp{$hssp}.="$loci,";}else{$lociHssp{$hssp}="$loci,";}
				# exclude those with 2 different locations
	if ($tmpHssp ne $loci){print "xx $hssp has '$loci' and '$tmpHssp' excluded\n";
			       $tmpHssp="$loci";}
	else{
	    $rd{"ID2",$it}=~s/\s//g;$homo{$hssp}.=$rd{"ID2",$it}.",";
	    $res{$hssp,$swiss,"len1"}=$rd{"LEN1",$it};
	    $res{$hssp,$swiss,"len2"}=$rd{"LEN2",$it};
	    $res{$hssp,$swiss,"lali"}=$rd{"LALI",$it};
	    push(@posAll,$it);}}


    &exposure_normalise_prepare("RS"); # normalise accessibility external lib-prot.pl
    $ctProt=0;%done=0;
				# ------------------------------
    foreach $hssp (@hssp){	# read HSSP files
	@swiss=split(/,/,$homo{$hssp});
	$fileHsspLoc=$hssp . ".hssp";
	if (! -e $fileHsspLoc){
	    foreach $dirHssp (@dirHssp){
		$fileHsspLoc=$dirHssp . $hssp . ".hssp";
		last if (-e $fileHsspLoc);}}
	if (! -e $fileHsspLoc){
	    print "*** $sbrName \t no hssp file=$fileHsspLoc,\n;";
	    return(0);}

	if ($Lverb2) { print "--- $sbrName \t '\&hsspRdAli($fileHsspLoc @swiss)'\n";}
				# read alignments
				# out : $rd{"swiss_id","ct"}="X"
				#       $rd{"SWISS"}="swiss_id1,swiss_id2"
				#       $rd{"NRES"} = number or residues
	%rdAli=0;
	($Lok,%rdAli)=
	    &hsspRdAli($fileHsspLoc,"seqNoins",@swiss); # external lib-prot.pl
	if (!$Lok){print "*** ERROR $sbrName after reading '$fileHsspLoc' (hsspRdAli)\n";
		   return(0);}

	$ctProtOneHssp=0;
				# extract composition
	foreach $swiss (@swiss){ # all swissprot homologues in current HSSP
	    next if ( (defined $done{$hssp,$swiss})&&($done{$hssp,$swiss}) );

	    $Lexcl=0;		# exclude pairs
	    foreach $pair (@inExclPair){
		@tmp=split(/,/,$pair);
		if (($swiss=~/$tmp[2]/)&&(($tmp[1]=~/^\*/)||($hssp=~/^$tmp[1]/))){
		    $Lexcl=1;
		    last;}}
	    next if ($Lexcl);

	    $done{$hssp,$swiss}=1;

	    ++$ctProt;
	    ++$ctProtOneHssp;
	    $loci=$loci{$swiss};$loci=~s/\s//g;
	    $res{"loci",$ctProt}= $loci;
	    $res{"hssp",$ctProt}= $hssp;
	    $res{"swiss",$ctProt}=$swiss;

				# set zero
	    $res{"ctProfA",$ctProt}=$res{"ctProfE",$ctProt}=$res{"ctProfB",$ctProt}=0;
	    foreach $aa (@aaNamesHssp){
		$res{"ctProfA",$aa,$ctProt}=$res{"ctProfE",$aa,$ctProt}=
		    $res{"ctProfB",$aa,$ctProt}=0;}

	    @seq=split(//,$rdAli{"seqNoins",$ctProtOneHssp});
#	    foreach $it (1..$rdAli{"NRES"}){ # all residues
	    foreach $it (1..$#seq){ # all residues
		next if ($seq[$it] eq ".");
		$seq=$seq[$it];
		$seq=~tr/[a-z]/[A-Z]/; # lower to upper
		next if ($seq !~/[ACDEFGHIJKLMNPQRSTVWY]/);
		if ((! defined $rdAli{"acc",$it})||($rdAli{"acc",$it}=~/[^0-9]/)){
		    print "*** for hssp=$hssp, swiss=$swiss, it=$it, acc=",
		    $rdAli{"acc",$it},",\n";
		    next;}
		$aaSwiss=  $seq;
		$accSwiss= 
		    &convert_acc($aaSwiss,$rdAli{"acc",$it});	# external lib-prot.pl
		if    ($accSwiss >= $par{"statExposed"}){ # exposed residues
		    ++$res{"ctProfE",$ctProt};
		    ++$res{"ctProfE",$aaSwiss,$ctProt};}
		elsif ($accSwiss < $par{"statExposed"}){ # buried residues
		    ++$res{"ctProfB",$ctProt};
		    ++$res{"ctProfB",$aaSwiss,$ctProt};}
		++$res{"ctProfA",$ctProt};
		++$res{"ctProfA",$aaSwiss,$ctProt}; # all
	    }
	}
    }				# end of loop over HSSP files
    $res{"NROWS"}=$ctProt;
}				# end of getHsspAlis

#===============================================================================
sub getHsspLoci {
    local($sbrName,$fhinLoc,$tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getHsspLoci                 reads  HSSP header and SWISS-PROT loci
#                               and merges the two (or reads the merge)
#   variables are GLOBAL 
#-------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";}
    $sbrName="$tmp"."getHsspLoci";$fhinLoc="FHIN"."$sbrName";
				# ------------------------------
				# extract header
    if ($par{"doHsspHeader"}){
	if (! -e $par{"fileInHsspList"}){ # HSSP list existing?
	    print "*** ERROR $sbrName: doHsspHeader=1, but no list of HSSP files\n";
	    return(0);}
	$exe=$par{"exeHsspExtrHeader"};
				# construct input arguments
	$arg=" ".$par{"fileInHsspList"}." ";
	foreach $kwd ("hsspLowPide","hsspUpPide","hsspLowR1A"){
	    if (! defined $par{"$kwd"}){print "*** ERROR $sbrName: par for kwd=$kwd undefined\n";
					return(0);}
	    $par=$par{"$kwd"}; $tmp=$kwd;$tmp=~s/hssp//g;
	    $tmp1=substr($tmp,1,1); $tmp1=~tr/[A-Z]/[a-z]/; $tmp2=substr($tmp,2);
	    $arg.="$tmp1$tmp2"."=".$par." ";}
	$arg.=" wrtRdb notStat notVerbose fileOutRdb=".$par{"fileOutHsspHeader"}." ";
	&run_program("$exe $arg"); }
				# ------------------------------
				# read extracted header
    if ($par{"doHsspHeader"} || $par{"readHsspHeader"}){
	if    (-e $par{"fileInHsspHeader"}){ # HSSP header(RDB) existing?
	    $fileIn=$par{"fileInHsspHeader"};}
	elsif (-e $par{"fileOutHsspHeader"}){
	    $fileIn=$par{"fileOutHsspHeader"};}
	undef %rd;
	%rd=			# read RDB
	    &rd_rdb_associative($fileIn,"header","body",@kwdRdHsspRdb); # external lib-ut.pl
				# yy still work on it
				# ------------------------------
				# now compare two sets
	foreach $it (1..$rd{"NROWS"}){
	    next if (! defined $rd{"ID2",$it});
	    $swiss=$rd{"ID2", $it};
	    next if ($rd{"LALI",$it}<50);
	    $rd{"loci",$it}=$loci{$swiss} if (defined $loci{$swiss});}}
		
    elsif ($par{"readHsspLoci"}){ # note: this is fork for Merge25...*rdb
	$fileIn=$par{"fileInHsspLoci"};
	if (-e $fileIn){
	    undef %rd;
	    %rd=		# read RDB external lib-ut.pl # 
		&rd_rdb_associative($fileIn,"header","body",
				    "king","loci",@kwdRdHsspRdb);
				# --------------------------------------------------
				# store into hash , exclude double, interpret
	    %tmp=0;$#rdPos=0;
	    foreach $it (1..$rd{"NROWS"}){
		$loci= $rd{"loci",$it};$loci=~s/\s//g;
		$swiss=$rd{"ID2",$it};$swiss=~s/\s//g;
		$hssp= $rd{"ID1",$it};$hssp=~s/\s//g;
				# interpret location (class to take? or other)
		if (defined $lociInterpret{$loci}){
		    $lociInterpret=$lociInterpret{$loci};
		    if ($Lloci{$lociInterpret}){
			$loci{$swiss}=$loci=$rd{"loci",$it}=$lociInterpret;}
		    else {
			$loci{$swiss}=$loci=$rd{"loci",$it}=$lociUnk;}}
		else {
		    $loci{$swiss}=$loci=$rd{"loci",$it}=$lociUnk;}
		if (! defined $tmp{$hssp,$swiss}){ # exclude identical
		    $tmp{$hssp,$swiss}=1;
		    push(@rdPos,$it);}
	    }}
	else {
	    print "*** ERROR $sbrName missing hsspLoci '$fileIn'\n";
	    return(0);}}
    return(1);
}				# end of getHsspLoci

#===============================================================================
sub getHsspProf {
    local($sbrName,$fhinLoc,$tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getHsspProf                 gets HSSP profiles for best hits
#                               (i.e. only one per HSSP file)
#   variables are GLOBAL 
#-------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";}
    $sbrName="$tmp"."getHsspProf";$fhinLoc="FHIN"."$sbrName";

    %Ldone=0;$#posBest=0;
#    foreach $it (1..$rd{"NROWS"}){
    foreach $it (@rdPos){	# 
	$hssp=$rd{"ID1",$it};
	if (! defined $rd{"loci",$it}){
	    next;}
	if ($rd{"LALI",$it}<$par{"statMinLali"}){
	    next;}
	if ($rd{"LEN2",$it}==0){
	    next;}
	if ($rd{"LEN1",$it}==0){
	    next;}
	if (($rd{"LALI",$it}/$rd{"LEN1",$it}<$par{"statMinRatio"})||
	    ($rd{"LALI",$it}/$rd{"LEN2",$it}<$par{"statMinRatio"})){
	    next;}
	if (! defined $Ldone{$hssp}){
	    $Ldone{$hssp}=1;
	    push(@posBest,$it);}
    }
				# ------------------------------
				# yy inlcude other locations, define parameter
    $#tmp=0;			# resort (according to location), interpret location
    @lociTmp=@lociAbbrev;
    if ((defined $Lloci{"unk"})&&($Lloci{"unk"})){ # check class 'other'
	push(@lociTmp,"$lociUnk");}
    
    foreach $loci (@lociTmp){
	if ((! defined $Lloci{$loci})||(! $Lloci{$loci})){
	    next;}
	foreach $it (@posBest){
	    if    ($rd{"loci",$it} =~ /^$loci/){
		push(@tmp,$it);}}}

    @posBest=@tmp;
    &exposure_normalise_prepare("RS"); # normalise accessibility external lib-prot.pl
				# ------------------------------
				# write profile headers
    &wrtHsspProfHeader();
				# ------------------------------
    foreach $itPos (@posBest){	# read HSSP files
	$id1=      $rd{"ID1","$itPos"};  $id1=~s/\s//g;
	$id2=      $rd{"ID2","$itPos"};  $id2=~s/\s//g;
	$ifirLoc=  $rd{"IFIR","$itPos"}; $ifirLoc=~s/\s//g;
	$ilasLoc=  $rd{"ILAS","$itPos"}; $ilasLoc=~s/\s//g;
	$fileHsspLoc=$id1.".hssp";
	if (! -e $fileHsspLoc){
	    foreach $dirHssp (@dirHssp){
		$fileHsspLoc=$dirHssp . $id1 . ".hssp";
		last if (-e $fileHsspLoc);}}
	if (! -e $fileHsspLoc){
	    print "*** $sbrName \t no hssp file=$fileHsspLoc,\n;";
	    return(0);}

	$loci=     $rd{"loci","$itPos"}; 
	if (length($loci)>3){$loci3=substr($loci,1,3);}else{$loci3=$loci;}
	if ($Lverb) { 
	    print "--- $sbrName \t posBest=$itPos,$id1,$id2 ($ifirLoc-$ilasLoc) loci=$loci3,\n";}
				# read seq, sec, acc
                                #    out:   %rdLoc{"kwd","itPos"}
                                #    @kwd=  ("seqNo","pdbNo","seq","sec","acc")
	undef %rdHsspLoc;
	($Lok,%rdHsspLoc)=	# get acc for hssp
	    &hsspRdSeqSecAcc($fileHsspLoc,$ifirLoc,$ilasLoc,
			     "*","seq","acc"); # external lib-prot.pl

	$nres=$rdHsspLoc{"NROWS"};
	if ((!$Lok)||(! $rdHsspLoc{"NROWS"})){
	    print "-*- WARNING $sbrName ERROR calling hsspRdSeqSecAcc with \n";
	    print "-*-                  '$fileHsspLoc,$ifirLoc,$ilasLoc, id2=$id2'\n";
	    exit;
	    next;}
				# postprocess
	foreach $itRes (1..$nres){
	    $rdHsspLoc{"seq",$itRes}=~tr/[a-z]/C/; # lower cap to C
	    $rdHsspLoc{"relAcc",$itRes}=	# relative accessibility
		&convert_acc($rdHsspLoc{"seq",$itRes},$rdHsspLoc{"acc",$itRes},"unk","RS");}
				# read profiles
                                #   @kwd=("seqNo","pdbNo",
                                #	  "V","L","I","M","F","W","Y","G","A","P",
                                #	  "S","T","C","H","R","K","Q","E","N","D",
                                #	  "NINS","ENTROPY","RELENT","WEIGHT")
	undef %rdProfLoc;
	($Lok,%rdProfLoc)=
	    &hsspRdProfile($fileHsspLoc,$ifirLoc,$ilasLoc); # external lib-prot.pl

	if ((!$Lok)||(! $rdProfLoc{"NROWS"})){
	    print "-*- WARNING $sbrName ERROR calling hsspRdProfile with \n";
	    print "-*-                  '$fileHsspLoc,$ifirLoc,$ilasLoc'\n";
	    next;}

				# normalise profile by counts
	foreach $itRes (1..$nres){
	    foreach $aa (@aaNamesHssp){
		$profNocc{$aa,$itRes}=
		    int((1/100)*$rdProfLoc{$aa,$itRes}*$rdProfLoc{"NOCC",$itRes});
	    }
	}
	$nresProfE=$nresProfB=$nresProfA=0; # set zero
	foreach $aa (@aaNamesHssp){$ctProfE{$aa}=$ctProfB{$aa}=$ctProfA{$aa}=0;}
				# get protein averages
	foreach $itRes (1..$nres){
	    foreach $aa (@aaNamesHssp){
		if    ($rdHsspLoc{"relAcc",$itRes}<$par{"statExposed"}){ # buried
		    $nresProfB+=$profNocc{$aa,$itRes};
		    $ctProfB{$aa}+=$profNocc{$aa,$itRes};}
		else {		# exposed
		    $nresProfE+=$profNocc{$aa,$itRes};
		    $ctProfE{$aa}+=$profNocc{$aa,$itRes};}
		$nresProfA+=$profNocc{$aa,$itRes};
		$ctProfA{$aa}+=$profNocc{$aa,$itRes};}}
				# ------------------------------
				# write profiles
	&wrtHsspProfOne($itPos);
    }				# end of loop over all proteins in list (best hits)

    close($fhoutProfE);close($fhoutProfB);close($fhoutProfA);
}				# end of getHsspProf

#===============================================================================
sub getSwissKing {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getSwissKing                gets all species of given kingdom
#   variables are GLOBAL 
#-------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";}
    $sbrName="$tmp"."getSwiss";$fhinLoc="FHIN"."$sbrName";
				# ------------------------------
				# make list of species for kingdom
    if ($par{"doSwissKingList"}){
	@kingList=
	    &swissGetKingdom($par{"fileInSwissKingdom"},$par{"swissKing"}); # external lib-prot.pl
				# write output file
	$fileOut=$par{"fileOutSwissKingList"};
	if ((defined $fileOut)&&($fileOut ne "no")){
	    $Lok=&open_file("$fhout",">$fileOut"); # external lib-ut.pl
	    if ($Lok){
		foreach $spec (@kingList){$spec=~s/\s//g;
					   print $fhout "$spec\n";}close($fhout);}
	    else{print "*** PROBLEM to write into file '$fileOut' ($sbrName)\n";}}}
				# ------------------------------
				# read list of species for kingdom
    elsif($par{"readSwissKingList"}) {
	$fileLoc=$par{"fileInSwissKingList"};$#kingList=0;
	if ($Lverb){printf "--- %-20s %-s\n","getSwiss","swiss species read from '$fileLoc'";}
	$Lok=&open_file("$fhinLoc","$fileLoc");
	if ($Lok){
	    while (<$fhinLoc>) {$_=~s/\s//g;if (length($_)<3){next;}
				$_=~s/^(\w)+[\s]+.*$/$1/g; # purge second column
				push(@kingList,$_);}close($fhinLoc);}
	else {print "*** ERROR $sbrName missing file '$fileLoc' (swissKingList)\n";}}
}				# end of getSwissKing

#===============================================================================
sub getSwissLoci {
    local($sbrName,$fhinLoc,$tmp,$dirLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getSwissLoci                gets all locations for given SWISS-PROT files
#   variables are GLOBAL 
#-------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";}
    $sbrName="$tmp"."getSwissLoci";$fhinLoc="FHIN"."$sbrName";
				# ------------------------------
				# find files with annotation of location
    if ($par{"doSwissLoci"}){
	$#loci=$#lociId=0;
	@rdLoc=			# get files with location
	    &swissGetLocation($par{"swissLociRegexp"},$Lverb,@specList); # external lib-prot.pl
				# translate output ($rdLoc[1]="location"\t"id")
	foreach $rdLoc (@rdLoc){$rdLoc=~s/\n//g;
				($loci,$lociId)=split(/\t+/,$rdLoc);
				push(@loci,$loci);push(@lociId,$lociId);}
				# write output file (is RDB)
	$fileOut=$par{"fileOutSwissLoci"};
	if ((defined $fileOut)&&($fileOut ne "no")){
	    $Lok=&open_file("$fhout",">$fileOut"); # external lib-ut.pl
	    if ($Lok){print  $fhout "\# Perl-RDB\n";
		      printf $fhout "%5s\t%-15s\t%-s\n","lineNo","id","location ";
		      printf $fhout "%5s\t%-15s\t%-s\n","5N","15","";
		      foreach $it (1..$#loci){
			  printf $fhout "%5d\t%-15s\t%-s\n",$it,$lociId[$it],$loci[$it];
			  printf "%5d\t%-15s\t%-s\n",$it,$lociId[$it],$loci[$it];}close($fhout);}
	    else{print "*** PROBLEM to write into file '$fileOut' ($sbrName)\n";}}}
				# ------------------------------
    elsif ($par{"readSwissLoci"}){ # read list of locations 
	$fileLoc=$par{"fileInSwissLoci"};$#loci=$#lociId=0;
	if ($Lverb){printf "--- %-20s %-s\n","getSwissLoci:","species read from '$fileLoc'";}
	$Lok=&open_file("$fhinLoc","$fileLoc"); $ct=0;
	if ($Lok){
	    while (<$fhinLoc>) {if (/\#/){next;}
				++$ct; last if ($ct==2);}
	    while (<$fhinLoc>) {$_=~s/\n//g;
				($tmp,$name,$loci)=split(/\t/,$_);
				$loci=~tr/[A-Z]/[a-z]/;$name=~s/\s//g;
				push(@loci,$loci);push(@lociId,$name);}close($fhin);}
	else {print "*** ERROR $sbrName missing file '$fileLoc' (Swissloci)\n";}}
    return(1);
}				# end of getSwissLoci

#===============================================================================
sub getSwissSpec {
    local($sbrName,$fhinLoc,$tmp,$dirLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getSwissSpec                gets all files for given species
#   variables are GLOBAL 
#-------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";}
    $sbrName="$tmp"."getSwissSpec";$fhinLoc="FHIN"."$sbrName";

				# ------------------------------
				# make list of all files
    if ($par{"doSwissSpecList"}){
	%dirLoc=0;$#dirLoc=0;	# direcotries to search
	foreach $spec (@kingList){$sub=substr($spec,1,1);
				  if (! defined $dirLoc{$sub}){ $dirLoc{$sub}="";
								push(@dirLoc,$sub);}
				  $dirLoc{$sub}.="_"."$spec"."|";}
	$#specList=0;
	foreach $subDir (@dirLoc) { # search directories
	    $dirLoc=$par{"dirSwissSeq"}.$subDir."/";
	    $dirLoc{$subDir}=~s/^|||$//g; # purge trailing '|'
	    $tmp=$dirLoc{$subDir};
	    if ($Lverb){ printf "--- %-20s %-s\n","getSwissSpec",
			        "system 'find $dirLoc -print | '\n";}
	    open($fhinLoc,"find $dirLoc -print | "); # read dir
	    while (<$fhinLoc>){$_=~s/\s//g; 
			       if ((! -T $_)||($_ !~ /$tmp/)){
				   next;}
			       push(@specList,$_);}close($fhinLoc);}
				# write output file
	$fileOut=$par{"fileOutSwissSpecList"};
	if ((defined $fileOut)&&($fileOut ne "no")){
	    $Lok=&open_file("$fhout",">$fileOut"); # external lib-ut.pl
	    if ($Lok){
		foreach $file (@specList){$file=~s/\s//g;
					   print $fhout "$file\n";}close($fhout);}
	    else{print "*** PROBLEM to write into file '$fileOut' ($sbrName)\n";}}}
				# ------------------------------
				# read list of species for kingdom
    elsif($par{"readSwissSpecList"}) {
	$fileLoc=$par{"fileInSwissSpecList"};$#specList=0;
	if ($Lverb){printf "--- %-20s %-s\n","getSwissSpec:","species read from '$fileLoc'";}
	$Lok=&open_file("$fhinLoc","$fileLoc");
	if ($Lok){
	    while (<$fhinLoc>) {$_=~s/\s//g;if (length($_)<3){next;}
				push(@specList,$_);}close($fhinLoc);}
	else {print "*** ERROR $sbrName missing file '$fileLoc' (swissSpecList)\n";}}
				# check list (is it swissprot files?)
    if (! &isSwiss($specList[1])){
	print "*** ERROR getSwissSpec (script $scriptName) specList not in SWISS-PROT format\n";
	return(0);}
    return(1);
}				# end of getSwissSpec

#===============================================================================
sub hsspManager {
    local($sbrName,$fhinLoc,$tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspManager                 calls the readers for HSSP, compares what is
#                               found to the SWISS-PROT list, and gets sequences
#   variables are GLOBAL 
#-------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";}
    $sbrName="$tmp"."hsspManager";$fhinLoc="FHIN"."$sbrName";

				# --------------------------------------------------
				# compares SWISS-PROT location and HSSP headers
				# out: $rd{"loci",$it} + all HSSP stuff (@kwdRdHsspRdb)
    $Lok=&getHsspLoci();

    if (!$Lok){print "*** ERROR $sbrName after reading hssp- locations 'getHsspLoci'\n";
	       return(0);}
				# --------------------------------------------------
				# extract profiles for best hits and writes them
    # yy do implement a fork here: when wrong!!
    if (1){			# xx.x
	&getHsspProf();
    }

    
				# --------------------------------------------------
				# statistics for all SWISS-PROT sequences
    $Lok=&getHsspAlis();
    if (!$Lok){print "*** ERROR $sbrName after reading hssp- alis 'getHsspAlis'\n";
	       return(0);}
    return(1);
}				# end of hsspManager

#===============================================================================
sub swissManager {
    local($sbrName,$fhinLoc,$tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   swissManager                calls all the readers for SWISS-PROT
#   variables are GLOBAL 
#-------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";}
    $sbrName="$tmp"."swissManager";$fhinLoc="FHIN"."$sbrName";
				# --------------------------------------------------
				# out: @kingList , 
				#      i.e. all swiss files for given kingdom
    if ($par{"doSwissKingList"}||$par{"readSwissKingList"}){
	&getSwissKing();
	if ($Lverb2){printf "--- %-20s %-s\n","after getSwissKing list="," ";
		     foreach $_(@kingList){print "$_,";}print"\n";} }

				# --------------------------------------------------
				# out: @specList, 
                                #      generate list of all swiss files for @kingList
    if ($par{"doSwissSpecList"}||$par{"readSwissSpecList"}){
	$Lok= &getSwissSpec(); if (! $Lok){ die; }
	if ($Lverb2){printf "--- %-20s %-s\n","after getSwissSpec list="," ";
		     foreach $_(@specList){print "$_,";}print"\n";}}

				# --------------------------------------------------
				# out @loci, and @lociId list with locations
    if ($par{"doSwissLoc"}||$par{"readSwissLoc"}){
	$Lok= &getSwissLoci(); if (! $Lok){ die; }

	if ($#loci==0){		# here @loci has to exist!!!
	    print "*** ERROR in script $scriptName:$sbrName no array with locations!\n";
	    die;}
	if ($Lverb3){printf "--- %-20s %-s\n","after getSwissLoci list="," ";
		     foreach $it(1..$#loci){print "$loci[$it]($lociId[$it]),";}print"\n";}
				# ------------------------------
				# restrict to keywords
	@tmp=@loci;@tmpId=@lociId;$#loci=$#lociId=$#miss=0;
	foreach $it (1..$#tmp){
	    if ($tmp[$it] =~ /$par{"swissLociRestrict"}/i){
#	    print "x.x ok it=$it, loci=$tmp[$it],\n";
		$tmp[$it]=~s/^.*($par{"swissLociRestrict"}).*$/$1/ig;
		$tmp[$it]=~s/\.//g;
		$loci{"$tmpId[$it]"}="$tmp[$it]";
		push(@loci,$tmp[$it]);push(@lociId,$tmpId[$it]);}
	    else {
		push(@miss,$tmp[$it]);}}
	if ($#loci==0){
	    return(0);}}
    return(1);
}				# end of swissManager

#===============================================================================
sub wrtHsspProfHeader {
    local($sbrName,$fhinLoc,$tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   wrtHsspProfHeader           write out statistics for profiles
#-------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";}
    $sbrName="$tmp"."wrtHsspProfHeader";$fhinLoc="FHIN"."$sbrName";
				# file names/handles
    $fileOutProfE=$par{"fileOutHsspProfE"};$fhoutProfE="FHOUT_PROF_E";
    $fileOutProfB=$par{"fileOutHsspProfB"};$fhoutProfB="FHOUT_PROF_B";
    $fileOutProfA=$par{"fileOutHsspProfA"};$fhoutProfA="FHOUT_PROF_A";
				# open files
    &open_file("$fhoutProfB",">$fileOutProfB");
    &open_file("$fhoutProfE",">$fileOutProfE");
    &open_file("$fhoutProfA",">$fileOutProfA");

    $accExposed=$par{"statExposed"}; # RDB header

    foreach $fh ("$fhoutProfE","$fhoutProfB","$fhoutProfA"){
	print $fh "\# Perl-RDB\n","\# Profile-compositions for HSSP \n";
	if    ($fh =~ /$fhoutProfE/){
	    print $fh "\# PARAMETER Accessibility:  0 - $accExposed \% rel. accessibil.\n";}
	elsif ($fh =~ /$fhoutProfB/){
	    print $fh "\# PARAMETER Accessibility:  $accExposed - 100 \% rel. accessibil.\n";}
	elsif ($fh =~ /$fhoutProfA/){
	    print $fh "\# PARAMETER Accessibility:  0-100 \% rel. accessibility\n";}
	print $fh 
	    "\# NOTATION ------------------------------------------------------------\n",
	    "\# NOTATION COLUMN-NAMES\n",
	    "\# NOTATION loci:         sub-cellular locations taken from SWISS-PROT\n",
	    "\# NOTATION id1:          PDB identifier\n",
	    "\# NOTATION id2:          SWISS-PROT identifier\n",
	    "\# NOTATION len1:         length of PDB sequence\n",
	    "\# NOTATION len2:         length of SWISS-PROT sequence\n",
	    "\# NOTATION lali:         length of alignment\n",
	    "\# NOTATION nres:         number of residues used for composition\n",
	    "\# NOTATION AA:           percentage of amino acids per protein\n",
	    "\# NOTATION ------------------------------------------------------------\n",
	    "\# NOTATION ABBREVIATIONS\n";
	foreach $des(@lociAbbrev,"unk"){
	    if ((!defined $Lloci{$des})||(! $Lloci{$des})){
		next;}
	    print $fh "\# NOTATION loci $des:     ",$lociExplain{$des},"\n";}
	print $fh
	    "\# NOTATION ------------------------------------------------------------\n",
	    "\# \n";}

    foreach $fh ("$fhoutProfE","$fhoutProfB","$fhoutProfA"){
	printf $fh		# names
	    "%5s\t%-15s\t%-10s\t%-10s\t%6s\t%6s\t%6s\t%6s",
	    "no","loci","id1","id2","len1","len2","lali","nres";
	foreach $aa (@aaNamesHssp){
	    printf $fh "\t%5s",$aa;}
	printf $fh "\t%5s\n","sum";
	printf $fh		# formats
	    "%5s\t%-15s\t%-10s\t%-10s\t%6s\t%6s\t%6s\t%6s",
	    "5N","15S","10S","10S","6N","6N","6N","6N";
	foreach $it (1..20){
	    printf $fh "\t%5s","5.2F";}
	printf $fh "\t%5s\n","5.2F";}
}				# end of wrtHsspProfHeader

#===============================================================================
sub wrtHsspProfOne {
    local($itIn)=@_;
    local($sbrName,$fhinLoc,$tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   wrtHsspProfOne              write out statistics for profiles
#-------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";}
    $sbrName="$tmp"."wrtHsspProf";$fhinLoc="FHIN"."$sbrName";
				# ------------------------------
				# profiles
    $nresProf{"$fhoutProfE"}=$nresProfE;
    $nresProf{"$fhoutProfB"}=$nresProfB;
    $nresProf{"$fhoutProfA"}=$nresProfA;
    foreach $fhLoc("$fhoutProfE","$fhoutProfB","$fhoutProfA"){
	if (! $nresProf{"$fhLoc"}){
	    next;}
	printf $fhLoc	# RDB general
	    "%5d\t%-15s\t%-10s\t%-10s\t%6d\t%6d\t%6d\t%6d",
	    $itIn,$rd{"loci","$itIn"},$rd{"ID1","$itIn"},$rd{"ID2","$itIn"},
	    $rd{"LEN1","$itIn"},$rd{"LEN2","$itIn"},$rd{"LALI","$itIn"},$nresProf{"$fhLoc"};
	$sum=0;			# RDB per residue counts
	if    ($fhLoc eq "FHOUT_PROF_E"){ # exposed
	    foreach $aa (@aaNamesHssp){
		$sum+=100*($ctProfE{$aa}/$nresProf{"$fhLoc"});
		printf $fhLoc "\t%5.2f",100*($ctProfE{$aa}/$nresProf{"$fhLoc"});}}
	elsif ($fhLoc eq "FHOUT_PROF_B"){ # buried
	    foreach $aa (@aaNamesHssp){
		$sum+=100*($ctProfB{$aa}/$nresProf{"$fhLoc"});
		printf $fhLoc "\t%5.2f",100*($ctProfB{$aa}/$nresProf{"$fhLoc"});}}
	elsif ($fhLoc eq "FHOUT_PROF_A"){ # all
	    foreach $aa (@aaNamesHssp){ 
		$sum+=100*($ctProfA{$aa}/$nresProf{"$fhLoc"});
		printf $fhLoc "\t%5.2f",100*($ctProfA{$aa}/$nresProf{"$fhLoc"});}}
	printf $fhLoc "\t%5.2f\n",$sum;}
}				# end of wrtHsspProfOne

#===============================================================================
sub wrtSwissStat {
    local($sbrName,$fhinLoc,$tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   wrtSwissStat              write out statistics for Singles
#-------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";}
    $sbrName="$tmp"."wrtSwissStat";$fhinLoc="FHIN"."$sbrName";
    $sep="\t";
				# ------------------------------
    $#order=0;			# resort (interpret location)
    @lociTmp=@lociAbbrev;
    if ((defined $Lloci{"unk"})&&($Lloci{"unk"})){ # check class 'other'
	push(@lociTmp,"$lociUnk");}
    foreach $loci(@lociTmp){
	if ((! defined $Lloci{$loci})||(! $Lloci{$loci})){
	    next;}
	foreach $it (1..$res{"NROWS"}){
	    if ($res{"loci",$it}=~ /^$loci/){push(@order,$it);}}}
				# ------------------------------
				# loop over all proteins
    foreach $it (@order){	# process in sorted way
	$id1=$res{"hssp",$it};$Lsing=0;
	if (! defined $Lsing{$id1}){ # for single file : count once
	    $Lsing{$id1}=1;$Lsing=1;}
	if ($Lverb){ printf
			 "--- write %3d %-6s %-10s %-3s Nall=%5d Nexp=%5d\n",$it,
			 $res{"hssp",$it},$res{"swiss",$it},substr($res{"loci",$it},1,3),
			 $res{"ctProfA",$it},$res{"ctProfE",$it};}
	$hssp=$res{"hssp",$it};$swiss=$res{"swiss",$it};
				# RDB files: general
	foreach $des ("ctProfE","ctProfB","ctProfA"){
	    if    ($des eq "ctProfE"){ $fhoutProf=$fhoutE;$fhoutSing=$fhoutSingE;}
	    elsif ($des eq "ctProfB"){ $fhoutProf=$fhoutB;$fhoutSing=$fhoutSingB;}
	    elsif ($des eq "ctProfA"){ $fhoutProf=$fhoutA;$fhoutSing=$fhoutSingA;}
	    else { print "*** ERROR $sbrName des=$des, not understood\n";}

	    printf $fhoutProf
		"%5d$sep%-15s$sep%-6s$sep%-10s$sep%6d$sep%6d$sep%6d$sep%6d",
		$it,$res{"loci",$it},$res{"hssp",$it},$res{"swiss",$it},
		$res{$hssp,$swiss,"len1"},$res{$hssp,$swiss,"len2"},
		$res{$hssp,$swiss,"lali"},$res{$des,$it};
	    if ($Lsing){
		printf $fhoutSing
		    "%5d$sep%-15s$sep%-6s$sep%-10s$sep%6d$sep%6d$sep%6d$sep%6d",
		    $it,$res{"loci",$it},$res{"hssp",$it},$res{"swiss",$it},
		    $res{$hssp,$swiss,"len1"},$res{$hssp,$swiss,"len2"},
		    $res{$hssp,$swiss,"lali"},$res{$des,$it};}
	    $sum=0;
	    foreach $aa (@aaNamesHssp){
		if ($res{$des,$it}>0){
		    $tmp=100*($res{$des,$aa,$it}/$res{$des,$it});}else {$tmp=0;}
		$sum+=$tmp;
		printf $fhoutProf "$sep%5.2f",$tmp;
		if ($Lsing){
		    printf $fhoutSing "$sep%5.2f",$tmp;}}
	    printf $fhoutProf "$sep%5.2f\n",$sum; 
	    if ($Lsing){
		printf $fhoutSing "$sep%5.2f\n",$sum; }
	}
    }				# end of loop over all proteins
    close($fhoutE);close($fhoutB);close($fhoutA);
    close($fhoutSingE);close($fhoutSingB);close($fhoutSingA);
}				# end of wrtSwissStat

#===============================================================================
sub wrtSwissStatHeader {
    local($sbrName,$fhinLoc,$tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   wrtSwissStatHeader          write out statistics for each homologue
#-------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";}
    $sbrName="$tmp"."wrtSwissStatHeader";$fhinLoc="FHIN"."$sbrName";
				# file names
    $fileE=$par{"fileOutSwissE"};$fileOutSingE=$par{"fileOutHsspSingE"};
    $fileB=$par{"fileOutSwissB"};$fileOutSingB=$par{"fileOutHsspSingB"};
    $fileA=$par{"fileOutSwissA"};$fileOutSingA=$par{"fileOutHsspSingA"};
				# file handles
    $fhoutE="FHOUT_SWISS_EXP";$fhoutB="FHOUT_SWISS_BUR";$fhoutA="FHOUT_SWISS_ALL";
    $fhoutSingE="FHOUT_SING_E";$fhoutSingB="FHOUT_SING_B";$fhoutSingA="FHOUT_SING_A";
				# open files
    $Lok1a=&open_file("$fhoutE",">$fileE");&open_file("$fhoutSingE",">$fileOutSingE");
    $Lok1b=&open_file("$fhoutB",">$fileB");&open_file("$fhoutSingB",">$fileOutSingB");
    $Lok1c=&open_file("$fhoutA",">$fileA");&open_file("$fhoutSingA",">$fileOutSingA");

    $Lok=1;
    if (! $Lok1a){ print "*** ERROR $sbrName opening fileE    '$fileE'\n"; $Lok=0; }
    if (! $Lok1b){ print "*** ERROR $sbrName opening fileB    '$fileB'\n"; $Lok=0; }
    if (! $Lok1c){ print "*** ERROR $sbrName opening fileA    '$fileA'\n"; $Lok=0; }
    if (! $Lok){
	return(0);}
    
    $accExposed=$par{"statExposed"}; # RDB header

    foreach $fh ("$fhoutA","$fhoutE","$fhoutB",
		 "$fhoutSingE","$fhoutSingB","$fhoutSingA"){
	print $fh "\# Perl-RDB\n","\# \n","\# Swiss-composition from HSSP\n";
	if    ($fh =~ /$fhoutE|$fhoutSingB/){
	    print $fh "\# PARAMETER Accessibility:  0 - $accExposed \% rel. accessibil.\n";}
	elsif ($fh =~ /$fhoutB|$fhoutSingE/){
	    print $fh "\# PARAMETER Accessibility:  $accExposed - 100 \% rel. accessibil.\n";}
	elsif ($fh =~ /$fhoutA|$fhoutSingA/){
	    print $fh "\# PARAMETER Accessibility:  0-100 \% rel. accessibility\n";}
	print $fh 
	    "\# NOTATION ------------------------------------------------------------\n",
	    "\# NOTATION loci:         sub-cellular locations taken from SWISS-PROT\n",
	    "\# NOTATION id1:          PDB identifier\n",
	    "\# NOTATION id2:          SWISS-PROT identifier\n",
	    "\# NOTATION len1:         length of PDB sequence\n",
	    "\# NOTATION len2:         length of SWISS-PROT sequence\n",
	    "\# NOTATION lali:         length of alignment\n",
	    "\# NOTATION nres:         number of residues used for composition\n",
	    "\# NOTATION AA:           percentage of amino acids per protein\n",
	    "\# NOTATION ------------------------------------------------------------\n",
	    "\# NOTATION ABBREVIATIONS\n";
	foreach $des(@lociAbbrev,"unk"){
	    if ((!defined $Lloci{$des})||(! $Lloci{$des})){
		next;}
	    print $fh "\# NOTATION loci $des:     ",$lociExplain{$des},"\n";}
	print $fh
	    "\# NOTATION ------------------------------------------------------------\n",
	    "\# \n";}

    foreach $fh ("$fhoutE","$fhoutB","$fhoutA",
		 "$fhoutSingE","$fhoutSingB","$fhoutSingA"){
	printf $fh		# names
	    "%5s\t%-15s\t%-6s\t%-10s\t%6s\t%6s\t%6s\t%6s",
	    "no","loci","id1","id2","len1","len2","lali","nres";
	foreach $aa (@aaNamesHssp){
	    printf $fh "\t%5s",$aa;}
	printf  $fh "\t%5s\n","sum";
	printf $fh		# formats
	    "%5s\t%-15s\t%-6s\t%-10s\t%6s\t%6s\t%6s\t%6s",
	    "5N","15S","6S","10S","6N","6N","6N","6N";
	foreach $it (1..20){
	    printf $fh "\t%5s","5.2F";}
	printf $fh "\t%5s\n","5.2F";}
}				# end of wrtSwissStatHeader



#==============================================================================
# library collected (begin) lll
#==============================================================================


#===============================================================================
sub bynumber { 
#-------------------------------------------------------------------------------
#   bynumber                    function sorting list by number
#-------------------------------------------------------------------------------
    $a<=>$b; 
}				# end of bynumber

#===============================================================================
sub bynumber_high2low { 
#-------------------------------------------------------------------------------
#   bynumber_high2low           function sorting list by number (start with high)
#-------------------------------------------------------------------------------
    $b<=>$a; 
}				# end of bynumber_high2low

#==============================================================================
sub complete_dir { local($DIR)=@_; $[=1 ; 
		   return(0) if (! defined $DIR);
		   return($DIR) if ($DIR =~/\/$/);
		   return($DIR."/");} # end of complete_dir

#==============================================================================
sub convert_acc {
    local ($aa,$acc,$char,$mode) = @_ ;
    local (@tmp1,@tmp2,@tmp,$it,$tmpacc,$valreturn);
#--------------------------------------------------------------------------------
#    convert_acc                converts accessibility (acc) to relative acc
#                               default output is just relative percentage (char = 'unk')
#         in:                   AA, (one letter symbol), acc (Angstroem),char (unk or:
#                    note:      output is relative percentage, default if char empty or='unk'
#                                    ============
#                               char='15:100_b:e' -> returns symbols 
#                                    ============
#                                    b for relacc <15, e for relacc>=15
#                                    ===============
#                               char='4:15:100_b:i:e' -> returns symbols 
#                                    ===============
#                                    b for relacc <4, i: 4<=relacc<15, e for relacc>=15
#         in:                   .... $mode:
#                               mode=''=default, '3ang', '5ang', '07ang' -> different water
#                                    radius, 'RS' then X=0
#         out:                  converted (with return)
#--------------------------------------------------------------------------------

    &exposure_normalise_prepare($mode) if (! %NORM_EXP);
				# default (3 states)
    if ( ! defined $char || $char eq "unk") {
	$valreturn=  &exposure_normalise($acc,$aa);}
				# optional e.g. char='15:100_b:e'
    elsif ($char =~ /\d:\d/) {
	if (! %NORM_EXP ){print "*** ERROR in convert_acc: NORM_EXP empty \n*** please,",
			  print "    do initialise with exposure_normalise_prepare\n";
			  exit;}
	$tmpacc= &exposure_normalise($acc,$aa);

	@tmp=split(/_/,$char);@tmp1=split(/:/,$tmp[1]);@tmp2=split(/:/,$tmp[2]);
	if   ($tmpacc<$tmp1[1])      {
	    $valreturn=$tmp2[1];}
	elsif($tmpacc>=$tmp1[$#tmp1-1]){
	    $valreturn=$tmp2[$#tmp1];}
	else { 
	    for ($it=2;$it<$#tmp1;++$it) {
		if ( ($tmpacc>=$tmp1[$it-1]) && ($tmpacc<$tmp1[$it+1]) ) {
		    $valreturn=$tmp2[$it]; 
		    last; }}} }
    else {print "*** ERROR calling convert_acc (lib-br) \n";
	  print "***       acc=$acc, aa=$aa, char passed (eg. 15:100_b:4)=$char, not ok\n";
	  exit;}
    $valreturn=100 if ($valreturn>100);	# saturation (shouldnt happen, should it?)
    return $valreturn;
}				# end of convert_acc

#==============================================================================
sub dirMk  { 
    local($fhoutLoc,@dirLoc)=@_; local($tmp,@tmp,$Lok,$dirLoc);
    $[ =1 ;
    if   (! defined $fhoutLoc){ 
	$fhoutLoc=0;push(@dirLoc,$fhoutLoc);}
    elsif(($fhoutLoc!~/[^0-9]/)&&($fhoutLoc == 1)) { 
	$fhoutLoc="STDOUT";}
    $Lok=1;$#tmp=0;
    foreach $dirLoc(@dirLoc){
	if ((! defined $dirLoc)||(length($dirLoc)<1)){
	    $tmp="-*- WARNING 'lib-sys:dirMk' '$dirLoc' pretty useless";
	    if ($fhoutLoc){print $fhoutLoc "$tmp\n";}
	    push(@tmp,$tmp);
	    next;}
	if (-d $dirLoc){
	    $tmp="-*- WARNING 'lib-sys:dirMk' '$dirLoc' exists already";
	    if ($fhoutLoc){print $fhoutLoc "$tmp\n";}
	    push(@tmp,$tmp);
	    next;}
	$dirLoc=~s/\/$//g; # purge trailing '/'
	$tmp="'mkdir $dirLoc'"; push(@tmp,$tmp);
	printf $fhoutLoc "--- %-20s %-s\n","fct:","$tmp" if ($fhoutLoc);
	$Lok= mkdir ($dirLoc,umask);
	if (! -d $dirLoc){
	    $tmp="*** ERROR 'lib-sys:dirMk' '$dirLoc' not made";
	    if ($fhoutLoc){print $fhoutLoc "$tmp\n";}
	    $Lok=0; push(@tmp,$tmp);}}
    return($Lok,@tmp);
}				# end of dirMk

#==============================================================================
sub exposure_normalise {
    local ($exp_in, $aa_in) = @_;
    $[=1;
#----------------------------------------------------------------------
#   exposure_normalise          normalise DSSP accessibility with maximal values
#                               (taken from Schneider)
#----------------------------------------------------------------------
    if ( $aa_in !~ /[ABCDEFGHIKLMNPQRSTUVWXYZ]/ ) {
	if ( $aa_in=~/[!.]/ ) { $aa_in = "X"; }
	else { print "*** ERROR in exposure_normalise: aa passed wrong: '$aa_in' \n";
	       exit; }}

    if ($NORM_EXP{$aa_in}>0) { $exp_normalise= 100 * ($exp_in / $NORM_EXP{$aa_in});}
    else { print "*** \n*** exposure_normalise, division by zero:aa=$aa_in,acc=$exp_in,norm=",
	   $NORM_EXP{$aa_in},"\n***\n";
	   $exp_normalise=$exp_in/1.8; # ugly ...
	   if ($exp_normalise>100){$exp_normalise=100;}}
    return $exp_normalise;
}				# end of exposure_normalise

#==============================================================================
sub exposure_normalise_prepare {
    local ($mode) = @_;
    $[=1;
#----------------------------------------------------------------------
#    exposure_normalise_prepare normalisation weights (maximal: Schneider, Dipl)
#----------------------------------------------------------------------
#   --------------------------------------------------
#   Reinhard
#   --------------------------------------------------
    if ((!defined $mode)||(length($mode) <= 1)) {
	$NORM_EXP{"A"} =106;  $NORM_EXP{"B"} =160;         # D or N
	$NORM_EXP{"C"} =135;  $NORM_EXP{"D"} =163;  $NORM_EXP{"E"} =194;
	$NORM_EXP{"F"} =197;  $NORM_EXP{"G"} = 84;  $NORM_EXP{"H"} =184;
	$NORM_EXP{"I"} =169;  $NORM_EXP{"K"} =205;  $NORM_EXP{"L"} =164;
	$NORM_EXP{"M"} =188;  $NORM_EXP{"N"} =157;  $NORM_EXP{"P"} =136;
	$NORM_EXP{"Q"} =198;  $NORM_EXP{"R"} =248;  $NORM_EXP{"S"} =130;
	$NORM_EXP{"T"} =142;  $NORM_EXP{"V"} =142;  $NORM_EXP{"W"} =227;
	$NORM_EXP{"X"} =180;         # undetermined (deliberate)
	$NORM_EXP{"Y"} =222;  $NORM_EXP{"Z"} =196;         # E or Q

#   --------------------------------------------------
#   maximal 3 Angstrom water
#   --------------------------------------------------
    } elsif ($mode =~ /3ang/ ) {
	$NORM_EXP{"A"} =179;  $NORM_EXP{"B"} =255;         # D or N
	$NORM_EXP{"C"} = 99;  $NORM_EXP{"D"} =249;  $NORM_EXP{"E"} =279;
	$NORM_EXP{"F"} =199;  $NORM_EXP{"G"} =169;  $NORM_EXP{"H"} =219;
	$NORM_EXP{"I"} =189;  $NORM_EXP{"K"} =309;  $NORM_EXP{"L"} =209;
	$NORM_EXP{"M"} =189;  $NORM_EXP{"N"} =259;  $NORM_EXP{"P"} =189;
	$NORM_EXP{"Q"} =259;  $NORM_EXP{"R"} =299;  $NORM_EXP{"S"} =209;
	$NORM_EXP{"T"} =209;  $NORM_EXP{"V"} =189;  $NORM_EXP{"W"} =239;
	$NORM_EXP{"X"} =200;         # undetermined (deliberate)
	$NORM_EXP{"Y"} =239;  $NORM_EXP{"Z"} =269;         # E or Q

#   --------------------------------------------------
#   maximal 5 Angstrom water
#   --------------------------------------------------
    } elsif ($mode =~ /5ang/ ) {
	$NORM_EXP{"A"} =209;  $NORM_EXP{"B"} =295;         # D or N
	$NORM_EXP{"C"} =139;  $NORM_EXP{"D"} =289;  $NORM_EXP{"E"} =349;
	$NORM_EXP{"F"} =199;  $NORM_EXP{"G"} =219;  $NORM_EXP{"H"} =229;
	$NORM_EXP{"I"} =189;  $NORM_EXP{"K"} =399;  $NORM_EXP{"L"} =239;
	$NORM_EXP{"M"} =189;  $NORM_EXP{"N"} =299;  $NORM_EXP{"P"} =189;
	$NORM_EXP{"Q"} =309;  $NORM_EXP{"R"} =309;  $NORM_EXP{"S"} =259;
	$NORM_EXP{"T"} =239;  $NORM_EXP{"V"} =189;  $NORM_EXP{"W"} =259;
	$NORM_EXP{"X"} =230;         # undetermined (deliberate)
	$NORM_EXP{"Y"} =259;  $NORM_EXP{"Z"} =329;         # E or Q

#   --------------------------------------------------
#   maximal 0.7 Angstrom water
#   --------------------------------------------------
    } elsif ($mode =~ /07ang/ ) {
	$NORM_EXP{"A"} =119;  $NORM_EXP{"B"} =169;         # D or N
	$NORM_EXP{"C"} = 99;  $NORM_EXP{"D"} =169;  $NORM_EXP{"E"} =179;
	$NORM_EXP{"F"} =169;  $NORM_EXP{"G"} =109;  $NORM_EXP{"H"} =173;
	$NORM_EXP{"I"} =159;  $NORM_EXP{"K"} =206;  $NORM_EXP{"L"} =159;
	$NORM_EXP{"M"} =159;  $NORM_EXP{"N"} =169;  $NORM_EXP{"P"} =149;
	$NORM_EXP{"Q"} =169;  $NORM_EXP{"R"} =209;  $NORM_EXP{"S"} =139;
	$NORM_EXP{"T"} =149;  $NORM_EXP{"V"} =149;  $NORM_EXP{"W"} =169;
	$NORM_EXP{"X"} =230;         # undetermined (deliberate)
	$NORM_EXP{"Y"} =189;  $NORM_EXP{"Z"} =175;         # E or Q

#   --------------------------------------------------
#   RS (X=0, from Reinhard
#   --------------------------------------------------
    } elsif ($mode =~/RS/) {
	$NORM_EXP{"A"} =106;  $NORM_EXP{"B"} =157;         # D or N
	$NORM_EXP{"C"} =135;  $NORM_EXP{"D"} =163;  $NORM_EXP{"E"} =194;
	$NORM_EXP{"F"} =197;  $NORM_EXP{"G"} = 84;  $NORM_EXP{"H"} =184;
	$NORM_EXP{"I"} =169;  $NORM_EXP{"K"} =205;  $NORM_EXP{"L"} =164;
	$NORM_EXP{"M"} =188;  $NORM_EXP{"N"} =157;  $NORM_EXP{"P"} =136;
	$NORM_EXP{"Q"} =198;  $NORM_EXP{"R"} =248;  $NORM_EXP{"S"} =130;
	$NORM_EXP{"T"} =142;  $NORM_EXP{"V"} =142;  $NORM_EXP{"W"} =227;
	$NORM_EXP{"X"} =180;         # undetermined (deliberate)
	$NORM_EXP{"Y"} =222;  $NORM_EXP{"Z"} =194;         # E or Q

#   --------------------------------------------------
#   Reinhard
#   --------------------------------------------------
    } else {
	$NORM_EXP{"A"} =106;  $NORM_EXP{"B"} =160;         # D or N
	$NORM_EXP{"C"} =135;  $NORM_EXP{"D"} =163;  $NORM_EXP{"E"} =194;
	$NORM_EXP{"F"} =197;  $NORM_EXP{"G"} = 84;  $NORM_EXP{"H"} =184;
	$NORM_EXP{"I"} =169;  $NORM_EXP{"K"} =205;  $NORM_EXP{"L"} =164;
	$NORM_EXP{"M"} =188;  $NORM_EXP{"N"} =157;  $NORM_EXP{"P"} =136;
	$NORM_EXP{"Q"} =198;  $NORM_EXP{"R"} =248;  $NORM_EXP{"S"} =130;
	$NORM_EXP{"T"} =142;  $NORM_EXP{"V"} =142;  $NORM_EXP{"W"} =227;
	$NORM_EXP{"X"} =180;         # undetermined (deliberate)
	$NORM_EXP{"Y"} =222;  $NORM_EXP{"Z"} =196;         # E or Q
    }
}				# end of exposure_normalise_prepare 

#==============================================================================
sub fileRm  { local($fhoutLoc,@fileLoc)=@_; local($tmp,@tmp,$Lok,$fileLoc);
	      if (-e $fhoutLoc){push(@fileLoc,$fhoutLoc);$fhoutLoc=0;}
	      $Lok=1;$#tmp=0;
	      foreach $fileLoc(@fileLoc){
		  if (-e $fileLoc){
		      $tmp="'\\rm $fileLoc'"; push(@tmp,$tmp);
		      printf $fhoutLoc "--- %-20s %-s\n","unlink ","$tmp" if ($fhoutLoc);
                      unlink($fileLoc);}
		  if (-e $fileLoc){
		      $tmp="*** ERROR 'lib-sys:fileRm' '$fileLoc' not deleted";
		      if ($fhoutLoc){print $fhoutLoc "$tmp\n";}
		      $Lok=0; push(@tmp,$tmp);}}
	      return($Lok,@tmp);} # end of fileRm


#==============================================================================
sub hsspRdAli {
    local ($fileInLoc,@want) = @_ ;
    local ($sbrName,$fhinLoc,$tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspRdAli                   reads and writes the sequence of HSSP + 70 alis
#       in:                     $fileHssp (must exist), 
#         @des                  (1) =1, 2, ...,  i.e. number of sequence to be read
#                               (2) = swiss_id1, swiss_id2, i.e. identifiers to read
#                               (3) = all (or undefined)
#                               NOTE: you can give ids AND numbers ('1','paho_chick','2') ..
#                               furthermore:
#                               if @want = 'seq|seqAli|seqNoins'
#                                  only those will be returned (e.g. $tmp{"seq",$ct})
#                               default: all 3!
#       out:                    1|0,$rd{} with: 
#       err:                    (0,$msg)
#                    overall:
#                               $rd{"NROWS"}=          : number of alis, i.e. $#want
#                               $rd{"NRES"}=N          : number of residues in guide
#                               $rd{"SWISS"}='sw1,sw2' : list of swiss-ids read
#                               $rd{"0"}='pdbid'       : id of guide sequence (in file header)
#                               $rd{$it}='sw$ct'     : swiss id of the it-th alignment
#                               $rd{"$id"}='$it'       : position of $id in final list
#                               $rd{"sec",$itRes}    : secondary structure for residue itres
#                               $rd{"acc",$itRes}    : accessibility for residue itres
#                               $rd{"chn",$itRes}    : chain for residue itres
#                    per prot:
#                               $rd{"seqNoins",$ct}=sequences without insertions
#                               $rd{"seqNoins","0"}=  GUIDE sequence
#                               $rd{"seq",$ct}=SEQW  : sequences, with all insertions
#                                                        but NOT aligned!!!
#                               $rd{"seqAli",$ct}    : sequences, with all insertions,
#                                                        AND aligned (all, including guide
#                                                        filled up with '.' !!
#-------------------------------------------------------------------------------
    $sbrName="lib-br:hsspRdAli"; $fhinLoc="FHIN"."$sbrName"; $fhinLoc=~tr/[a-z]/[A-Z]/;
				# file existing?
    if ((! -e $fileInLoc) || (! &is_hssp($fileInLoc))){
	print "*** ERROR $sbrName no HSSP file '$fileInLoc'\n";
	return(0);}
				# ------------------------------
				# HSSP file format settings
    $regexpBegAli=        "^\#\# ALIGNMENTS"; # begin of reading
    $regexpEndAli=        "^\#\# SEQUENCE PROFILE"; # end of reading
    $regexpSkip=          "^ SeqNo"; # skip lines with pattern
    $nmaxBlocks=          100;	# maximal number of blocks considered (=7000 alis!)
    $regexpBegIns=        "^\#\# INSERTION LIST"; # begin of reading insertion list
    
    undef %tmp; undef @seqNo; undef %seqNo;
				# ------------------------------
				# pointers
    undef %ptr_id2num;		# $ptr{xyz}= N   : id=xyz is the Nth ali
    undef @ptr_num2id;		# $ptr[N]=   xyz : Nth ali has id= xyz
    undef @ptr_numWant2numFin;	# $ptr[N]=   M   : the Nth ali is the Mth one in the list
				#                  of all numbers wanted (i.e. = $want[M])
    undef @ptr_numFin2numWant;	# $ptr[M]=   N   : see previous, the other way around!

    $#want=0                    if (! defined @want);
    $LreadAll=0; 
				# ------------------------------
				# digest input
				# (1) detect keywords
    $#tmp=0; 
    undef %kwd;
    foreach $tmp (@want){
	if ($tmp=~/^(seq|seqAli|seqNoins)$/){
	    $kwd{$tmp}=1; 
	    next;}
	push(@tmp,$tmp);}

    if (($#want>0) && ($#want == $#tmp) ){ # default keyworkds
	foreach $des ("seq","seqAli","seqNoins"){
	    $kwd{$des}=1;}}
    @want=@tmp;
				# (2) all?
    $LreadAll=1                 if ( ! @want || ! $want[1] || ($want[1] eq "all"));
    if (! $LreadAll){		# (3) read some
	$#wantNum=$#wantId=0;
	foreach $want (@want) {
	    if ($want !~ /[^0-9]/){push(@wantNum,$want);} # is number
	    else                  {push(@wantId,$want);}}}  # is id
				# ------------------------------
				# get numbers/ids to read
    ($Lok,%rdHeader)=
	&hsspRdHeader($fileInLoc,"SEQLENGTH","PDBID","NR","ID");
    if (! $Lok){
	print "*** ERROR $sbrName reading header of HSSP file '$fileInLoc'\n";
	return(0);}
    $tmp{"NRES"}= $rdHeader{"SEQLENGTH"};$tmp{"NRES"}=~s/\s//g;
    $tmp{"0"}=    $rdHeader{"PDBID"};    $tmp{"0"}=~s/\s//g;
    $idGuide=     $tmp{"0"};

    $#locNum=$#locId=0;		# store the translation name/number
    foreach $it (1..$rdHeader{"NROWS"}){
	$num=$rdHeader{"NR",$it}; $id=$rdHeader{"ID",$it};
	push(@locNum,$num);push(@locId,$id);
	$ptr_id2num{"$id"}=$num;
	$ptr_num2id[$num]=$id;}
    push(@locNum,"1")           if ($#locNum==0); # nali=1
				# ------------------------------
    foreach $want (@wantId){	# CASE: input=list of names
	$Lok=0;			#    -> add to @wantNum
	foreach $loc (@locId){
	    if ($want eq $loc){
		$Lok=1;
		push(@wantNum,$ptr_id2num{"$loc"});
		last;}}
	if (! $Lok){
	    print "-*- WARNING $sbrName wanted id '$want' not in '$fileInLoc'\n";}}
				# ------------------------------
				# NOW we have all numbers to get
				# sort the array
    @wantNum= sort bynumber (@wantNum);
				# too many wanted
    if (defined @wantNum && ($wantNum[$#wantNum] > $locNum[$#locNum])){
	$#tmp=0; 
	foreach $want (@wantNum){
	    if ($want <= $locNum[$#locNum]){
		push(@tmp,$want)}
	    else {
		print "-*- WARNING $sbrName no $want not in '$fileInLoc'\n";
		exit;
	    }}
	@wantNum=@tmp;}
		
    @wantNum=@locNum if ($LreadAll);
    if ($#wantNum==0){
	print "*** ERROR $sbrName nothing to read ???\n";
	return(0);}
				# sort the array, again
    @wantNum= sort bynumber (@wantNum);
				# ------------------------------
				# assign pointers to final output
    foreach $it (1..$#wantNum){
	$numWant=$wantNum[$it];
	$ptr_numWant2numFin[$numWant]=$it;
	$ptr_numFin2numWant[$it]=     $numWant;}

				# ------------------------------
				# get blocks to take
    $wantLast=$wantNum[$#wantNum];$#wantBlock=0;
    foreach $ctBlock (1..$nmaxBlocks){
	$beg=1+($ctBlock-1)*70;
	$end=$ctBlock*70;
	last if ($wantLast < $beg);
	$Ltake=0;
	foreach $num(@wantNum){
	    if ( ($beg<=$num)&&($num<=$end) ){
		$Ltake=1;
		last;}}
	if ($Ltake){
	    $wantBlock[$ctBlock]=1;}
	else{
	    $wantBlock[$ctBlock]=0;}}
				# writes ids read
    $tmp{"SWISS"}="";
    foreach $it (1..$#wantNum){ $num=$wantNum[$it];
				$tmp{$it}=   $ptr_num2id[$num];
				$tmp{"SWISS"}.="$ptr_num2id[$num]".",";} 
    $tmp{"SWISS"}=~s/,*$//g;
    $tmp{"NROWS"}=$#wantNum;

				# ------------------------------------------------------------
				#       
				# NOTATION: 
				#       $tmp{"0",$it}=  $it-th residue of guide sequnec
				#       $tmp{$itali,$it}=  $it-th residue of of ali $itali
				#       note: itali= same numbering as in 1..$#want
				#             i.e. NOT the position in the file
				#             $ptr_numFin2numWant[$itali]=5 may reveal that
				#             the itali-th ali was actually the fifth in the
				#             HSSP file!!
				#             
				# ------------------------------------------------------------

				# --------------------------------------------------
				# read the file finally
				# --------------------------------------------------
    $Lok=&open_file("$fhinLoc","$fileInLoc");
    if (! $Lok){print "*** ERROR $sbrName opening hssp file '$fileInLoc'\n";
		return(0);}
				# ------------------------------
				# move until first alis
				# ------------------------------
    $ctBlock=$Lread=$#takeTmp=0;
    while (<$fhinLoc>){ 
	last if ($_=~/$regexpEndAli/); # ending
	if ($_=~/$regexpBegAli/){ # this block to take?
	    ++$ctBlock;$Lread=0;
	    if ($wantBlock[$ctBlock]){
		$_=~s/^[^0-9]+(\d+) -\s+(\d+).*$//;
		$beg=$1;$end=$2;$Lread=1;
		$#wantTmp=0;	# local numbers
		foreach $num (@wantNum){
		    if ( ($beg<=$num) && ($num<=$end) ){
			$tmp=($num-$beg)+1; 
			print "*** $sbrName negative number $tmp,$beg,$end,\n" x 3 if ($tmp<1);
			push(@wantTmp,$tmp);}}
		next;}}
	next if (! $Lread);	# move on
	next if ($_=~/$regexpSkip/); # skip line
	$line=$_;
				# --------------------
	if (length($line)<52){	# no alis in line
	    $seqNo=substr($line,1,6);$seqNo=~s/\s//g;
	    if (! defined $seqNo{$seqNo}){
		$seqNo{$seqNo}=1;
		push(@seqNo,$seqNo);}
				# NOTE: $chn,$sec,$acc are returned per residue!
	    if (! defined $tmp{"0","$seqNo"}){
		($seqNo,$pdbNo,
		 $tmp{"chn","$seqNo"},$tmp{"0","$seqNo"},
		 $tmp{"sec","$seqNo"},$tmp{"acc","$seqNo"})=
		     &hsspRdSeqSecAccOneLine($line);}
		    
	    foreach $num(@wantTmp){ # add insertions if no alis
		$pos=                    $num+$beg-1; 
		$posFin=                 $ptr_numWant2numFin[$pos];
		$tmp{"$posFin","$seqNo"}="."; }
	    next;}
				# ------------------------------
				# everything fine, so read !
				# ------------------------------
				# --------------------
				# first the HSSP stuff
	$seqNo=substr($line,1,6);$seqNo=~s/\s//g;
	if (! defined $seqNo{$seqNo}){
	    $seqNo{$seqNo}=1;
	    push(@seqNo,$seqNo);}
				# NOTE: $chn,$sec,$acc are returned per residue!
	if (! defined $tmp{"0","$seqNo"}){
	    ($seqNo,$pdbNo,
	     $tmp{"chn","$seqNo"},$tmp{"0","$seqNo"},
	     $tmp{"sec","$seqNo"},$tmp{"acc","$seqNo"})=
		 &hsspRdSeqSecAccOneLine($line);}
				# --------------------
				# now the alignments
	$alis=substr($line,52); $alis=~s/\n//g;

				# NOTE: @wantTmp has the positions to read in current block,
				#       e.g. want no 75, block=71-90, => 75->4
	foreach $num (@wantTmp){
	    $pos=                        $num+$beg-1; # note: beg=71 in the example above
	    $id=                         $ptr_num2id[$pos];
	    $posFin=                     $ptr_numWant2numFin[$pos];
	    $tmp{"$posFin"}=             $id;
	    $takeTmp[$pos]=              1;
	    print "*** $sbrName neg number $pos,$beg,$num,\n" x 3 if ($pos<1);
	    $tmp{"seq","$posFin"}=       ""     if (! defined $tmp{"seq","$posFin"});
	    if (length($alis) < $num){
		$tmp{"seq","$posFin"}.=  ".";
		$tmp{"$posFin","$seqNo"}=".";}
	    else {
		$tmp{"seq","$posFin"}.=  substr($alis,$num,1);
		$tmp{"$posFin","$seqNo"}=substr($alis,$num,1);}
	}
    }
				# ------------------------------
    while (<$fhinLoc>){		# skip over profiles
        last if ($_=~/$regexpBegIns/); } # begin reading insertion list

				# ----------------------------------------
				# store sequences without insertions!!
				# ----------------------------------------
    if (defined $kwd{"seqNoins"} && $kwd{"seqNoins"}){
				# --------------------
	$seq="";		# guide sequence
	foreach $seqNo(@seqNo){
	    $seq.=$tmp{"0","$seqNo"};}
	$seq=~s/[a-z]/C/g;		# small caps to 'C'
	$tmp{"seqNoins","0"}=$seq;
				# --------------------
				# all others (by final count!)
	foreach $it (1..$#wantNum){
	    $seq="";
	    foreach $seqNo(@seqNo){
		$seq.=$tmp{$it,"$seqNo"};}
	    $seq=~s/\s/\./g;	    # fill up insertions
	    $seq=~tr/[a-z]/[A-Z]/;  # small caps to large
	    $tmp{"seqNoins",$it}=$seq;
	}
    }
				# --------------------------------------------------
				# read insertion list
				# 
				# syntax of insertion list:  
				#    ....,....1....,....2....,....3....,....4
				#    AliNo  IPOS  JPOS   Len Sequence
				#         9    58    59     5 kQLGAEi
				# 
				# --------------------------------------------------
    undef @insMax;		# note: $insMax[$seqNo]=5 means at residue 'seqNo'
    foreach $seqNo (@seqNo){	#       the longest insertion was 5 residues
	$insMax[$seqNo]=0;}
    while (<$fhinLoc>){
	$rd=$_;
	last if ((! defined $kwd{"seqAli"} || ! $kwd{"seqAli"}) &&
		 (! defined $kwd{"seq"}    || ! $kwd{"seq"}) );
	next if ($rd =~ /AliNo\s+IPOS/);  # skip key
	last if ($rd =~ /^\//);	          # end
        next if ($rd !~ /^\s*\d+/);       # should not happen (see syntax)
        $rd=~s/\n//g; $line=$rd;
	$posIns=$rd;		# current insertion from ali $pos
	$posIns=~s/^\s*(\d+).*$/$1/;
				# takeTmp[$pos]=1 if $pos to be read
	next if (! defined $takeTmp[$posIns] || ! $takeTmp[$posIns]);
				# ok -> take
	$line=~s/^\s*|\s*$//g;	# purge leading blanks
	@tmp=split(/\s+/,$line);
	$iposIns=$tmp[2];	# residue position of insertion
	$seqIns= $tmp[5];	# sequence at insertion 'kQLGAEi'
	$nresIns=(length($seqIns) - 2); # number of residues inserted
	$posFin= $ptr_numWant2numFin[$posIns];
				# --------------------------------------------------
				# NOTE: here $tmp{$it,"$seqNo"} gets more than
				#       one residue assigned (ref=11)
				# --------------------------------------------------
				# change 'ACinK' -> 'ACINEWNK'
	$tmp{"$posFin","$iposIns"}=substr($seqIns,1,(length($seqIns)-1));
				# maximal number of insertions
	$insMax[$iposIns]=$nresIns if ($nresIns > $insMax[$iposIns]);
    } close($fhinLoc);
				# end of reading file
				# --------------------------------------------------
    
				# ------------------------------
				# final sequences (not aligned)
				# ------------------------------
    if (defined $kwd{"seq"} && $kwd{"seq"}){
	foreach $it (0..$tmp{"NROWS"}){
	    $seq="";
	    foreach $seqNo(@seqNo){
		$seq.=$tmp{$it,"$seqNo"};}
	    $seq=~s/[\s\.!]//g;	# replace insertions 
	    $seq=~tr/[a-z]/[A-Z]/; # all capitals
	    $tmp{"seq",$it}=$seq; }}
				# ------------------------------
				# fill up insertions
				# ------------------------------
    if (defined $kwd{"seqAli"} && $kwd{"seqAli"}){
	undef %ali;		# temporary for storing sequences
	foreach $it (0..$tmp{"NROWS"}){
	    $ali{$it}="";}	# set for all alis
				# ------------------------------
	foreach $seqNo(@seqNo){	# loop over residues
	    $insMax=$insMax[$seqNo];
				# loop over all alis
	    foreach $it (0..$tmp{"NROWS"}){
				# (1) CASE: no insertion
		if    ($insMax==0){
		    $ali{$it}.=$tmp{$it,"$seqNo"};
		    next;}
				# (2) CASE: insertions
		$seqHere=$tmp{$it,"$seqNo"};
		$insHere=(1+$insMax-length($seqHere));
				# NOTE: dirty fill them in 'somewhere'
				# take first residue
		$ali{$it}.=substr($seqHere,1,1);
				# fill up with dots
		$ali{$it}.="." x $insHere ;
				# take remaining residues (if any)
		$ali{$it}.=substr($seqHere,2) if (length($seqHere)>1); }}
				# ------------------------------
				# now assign to final
	foreach $it (0..$tmp{"NROWS"}){
	    $ali{$it}=~s/\s/\./g; # replace ' ' -> '.'
	    $ali{$it}=~tr/[a-z]/[A-Z]/;	# all capital
	    $tmp{"seqAli",$it}=$ali{$it};}
	undef %ali;		# slim-is-in! 
    }
				# ------------------------------
				# save memory
    foreach $it (0..$tmp{"NROWS"}){
	if ($it == 0){		# guide
	    $id=         $idGuide; }
	else {			# pairs
	    $posOriginal=$ptr_numFin2numWant[$it];
	    $id=         $ptr_num2id[$posOriginal]; }
	$tmp{"$id"}= $id;
        foreach $seqNo (@seqNo){
	    undef $tmp{$it,"$seqNo"};}}
    undef @seqNo;      undef %seqNo;      undef @takeTmp;    undef @idLoc;
    undef @want;       undef @wantNum;    undef @wantId;     undef @wantBlock; 
    undef %rdHeader;   undef %ptr_id2num; undef @ptr_num2id; 
    undef @ptr_numWant2numFin; undef @ptr_numFin2numWant;
    return(1,%tmp);
}				# end of hsspRdAli

#==============================================================================
sub hsspRdHeader {
    local ($fileInLoc,@kwdInLoc) = @_ ;
    local ($sbrName,$fhinLoc,$tmp,
	   @kwdDefHsspTopLoc,@kwdDefHsspHdrLoc,@kwdHsspTopLoc,@kwdHsspHdrLoc,@tmp,
	   $regexpBegHeader,$regexpEndHeader,$regexpLongId,$lenStrid,$LisLongId,
	   %ptr,$kwd,$Lok,$Lpdb,$des,$beg,$end,$mid,$ct,$id,$strid,$ptr,$tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspRdHeader                reads a HSSP header
#       in:                     $fileHssp (must exist), 
#         @kwdInLoc             = one of the default keywords 
#                               (@kwdLocHsspTop,@kwdLocHsspHeader)
#       in:                     'nopair' surpresses reading of pair information
#       out:                    for top  (e.g. NALIGN): $rd{"kwd"}
#                               for prot (e.g. LALI):   $rd{"kwd",$it}
#                               note: for the later number of elements (it) in
#                                     $rd{"NROWS"}
#         special               ID=ID1, $rd{"kwd",$it} existes for ID1 and ID2
#-------------------------------------------------------------------------------
    $sbrName="lib-br:hsspRdHeader";$fhinLoc="FHIN"."$sbrName";$fhinLoc=~tr/[a-z]/[A-Z]/;
				# file existing?
    if (! -e $fileInLoc || ! &is_hssp($fileInLoc) ){
	print "*** ERROR $sbrName no HSSP file '$fileInLoc'\n";
	return(0);}
				# ------------------------------
				# settings describing format
    @kwdDefHsspTopLoc= ("PDBID","DATE","SEQBASE","PARAMETER","THRESHOLD",
			"REFERENCE","HEADER","COMPND","SOURCE","AUTHOR",
			"SEQLENGTH","NCHAIN","KCHAIN","NALIGN");
    @kwdDefHsspHdrLoc= ("NR","ID","STRID","IDE","WSIM","IFIR","ILAS",
			"JFIR","JLAS","LALI","NGAP","LGAP","LSEQ2","ACCNUM","PROTEIN");
    $regexpBegHeader=   "^\#\# PROTEINS"; # begin of reading 
    $regexpEndHeader=   "^\#\# ALIGNMENTS"; # end of reading
    $regexpLongId=      "^PARAMETER  LONG-ID :YES"; # identification of long id

    $lenStrid=          4;	# minimal length to identify PDB identifiers
    $LisLongId=         0;	# long identifier names

    $ptr{"IDE"}=1;$ptr{"WSIM"}=2;$ptr{"IFIR"}=3;$ptr{"ILAS"}=4;$ptr{"JFIR"}=5;$ptr{"JLAS"}=6;
    $ptr{"LALI"}=7;$ptr{"NGAP"}=8;$ptr{"LGAP"}=9;$ptr{"LSEQ2"}=10; $ptr{"ACCNUM"}=11;

				# ------------------------------
				# check input arguments
    $#kwdHsspTopLoc=$#kwdHsspHdrLoc=$Lpdb=$LnoPair=0;
    foreach $kwd (@kwdInLoc){
	$Lok=0;
	if ($kwd eq "nopair"){
	    $LnoPair=1;
	    next;}
	$Lpdb=1 if (! $Lpdb && ($kwd =~/^PDBID/));
	foreach $des (@kwdDefHsspTopLoc)   {
	    if ($kwd eq $des){ $Lok=1; push(@kwdHsspTopLoc,$kwd);
			       last;}}
	next if ($Lok || $LnoPair);
	foreach $des (@kwdDefHsspHdrLoc){
	    if ($kwd eq $des){ $Lok=1; push(@kwdHsspHdrLoc,$kwd);
			       last;} }
	print "-*- WARNING $sbrName input kwd=$kwd, makes no sense??\n" if (! $Lok);}

				# force reading of NALI
    push(@kwdHsspTopLoc,"PDBID") if (! $Lpdb);
	
				# get column numbers to read
				# ------------------------------
				# now start to read
    $Lok=&open_file("$fhinLoc","$fileInLoc");
    if (! $Lok){print "*** ERROR $sbrName HSSP file could not be opened '$fileInLoc'\n";
		return(0);}
    undef %tmp;		# save space
				# ------------------------------
    while ( <$fhinLoc> ) {	# read top
	last if ($_ =~ /$regexpBegHeader/); 
	if ($_ =~ /$regexpLongId/) {
	    $LisLongId=1;}
	else{$_=~s/\n//g;$arg=$_;
	     foreach $des (@kwdHsspTopLoc){
		 if ($arg  =~ /^$des\s+(.+)$/){
		     if (defined $ok{$des}){ # multiple lines!
			 $tmp="$1"."\t";
			 if  (defined $tmp{$des}){
			     $tmp{$des}.=$tmp;}
			 else{$tmp{$des}=$tmp;}}
		     else {$ok{$des}=1;$tmp{$des}=$1;}
		     if ($des=~/SEQLENGTH|NCHAIN|KCHAIN|NALIGN/){
			 $tmp{$des}=~s/^(\d+)[^0-9]+.*$/$1/;} # purge blanks
		     last;}}}}
				# ------------------------------
    $ct=0;			# read header
    while ( <$fhinLoc> ) { 
	last if ($LnoPair);	# supress reading pair info
	last if ($_ =~ /$regexpEndHeader/); 
	next if ($_ =~ /^  NR\./); # skip descriptors
	$_=~s/\n//g;
	$lenLine=length($_);
	if ($LisLongId){
	    $maxMid=115; $maxMid=($lenLine-56) if ($lenLine < 115);
	    $maxEnd=109; $maxEnd=$lenLine  if ($lenLine < 109);
	    $beg=substr($_,1,56);
	    $end=0; $end=substr($_,109)        if ($lenLine >=109);
	    $mid=substr($_,57,115); }
	else {
	    $maxMid= 62; $maxMid=($lenLine-28) if ($lenLine <  90);
	    $beg=substr($_,1,28);
	    $end=0; $end=substr($_,90)         if ($lenLine >=90);
	    $mid=substr($_,29,90); }
	$end=~s/^\s*|\s*$//g;   # purge leading blanks
	$mid=~s/^\s*|\s*$//g;	# purge leading blanks
				# SWISS accession: hack because it may be empty!
	if ($lenLine > 86) {
	    $accnum=substr($_,81,6); $accnum=~s/(\s)\s+/$1/g ; }
	else {
	    $accnum=0;}
				# begin: counter and id
	$beg=~s/.+ \:\s*|\s*$//g;
	if (! $LisLongId) {$id=$beg;$id=~s/([^\s]+).*$/$1/;
			   $strid=$beg;$strid=~s/$id|\s//g; }
	else              {$id=$beg;$id=~s/(.+_\S+).*/$1/;
			   $strid=substr($_,49,6);$strid=~s/\s//g; }
	    $tmp=$lenStrid-1;
	if ( (length($strid)<$lenStrid) && ($id=~/^[0-9][A-Z0-9]{$tmp,$tmp}\s*/)){
	    $strid=substr($id,1,$lenStrid); }
	++$ct;

	$tmp{"ID",$ct}=     $id;
	$tmp{"NR",$ct}=     $ct;
	$tmp{"STRID",$ct}=  $strid;
				# correct for ID = PDBid
	$tmp{"STRID",$ct}=  $id if ($strid=~/^\s*$/ && 
				      $id=~/\d\w\w\w.?\w?$/);
	    
	$tmp{"PROTEIN",$ct}=$end;
	$tmp{"ID1",$ct}=$tmp{"PDBID"};
	$tmp{"ACCNUM",$ct}=$accnum;
				# middle all info
	$#tmp=0;@tmp=split(/\s+/,$mid);
	foreach $_ (@tmp) {$_=~s/\s//g;}

	foreach $des (@kwdHsspHdrLoc){ 
	    next if ( ! defined $ptr{$des});
	    next if ( $des =~/^ACCNUM/);
	    $ptr=$ptr{$des};
	    $tmp{$des,$ct}=$tmp[$ptr]; }}close($fhinLoc);
    $tmp{"NROWS"}=$ct;
				# clean up
    $#kwdInLoc=$#kwdDefHsspHdrLoc=$#kwdHsspTopLoc=$#tmp=
	$#kwdDefHsspTopLoc=$#kwdHsspHdrLoc=0;
    undef %ptr;
    return(1,%tmp);
}				# end of hsspRdHeader

#==============================================================================
sub hsspRdProfile {
    local($fileInLoc,$ifirLoc,$ilasLoc,$chainLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$line,$seqNo,$pdbNo,$chainRd,$ifirRd,$ilasRd);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspRdProfile               reads the HSSP profile from ifir to ilas
#       in:                     file.hssp_C ifir ilas $chainLoc (* for all numbers and chain) 
#       out:                    %prof{"kwd","it"}
#                   @kwd=       ("seqNo","pdbNo","V","L","I","M","F","W","Y","G","A","P",
#				 "S","T","C","H","R","K","Q","E","N","D",
#				 "NOCC","NDEL","NINS","ENTROPY","RELENT","WEIGHT");
#-------------------------------------------------------------------------------
    $sbrName="lib-br:hsspRdProfile";$fhinLoc="FHIN"."$sbrName";
    undef %tmp;

    if (! -e $fileInLoc){print "*** $sbrName: HSSP file '$fileInLoc' missing\n";
			 return(0);}
    $chainLoc=0          if (! defined $chainLoc || ! &is_chain($chainLoc));
    $ifirLoc=0           if (! defined $ifirLoc || $ifirLoc eq "*" );
    $ilasLoc=0           if (! defined $ilasLoc || $ilasLoc eq "*" );
				# read profile
    &open_file("$fhinLoc","$fileInLoc") || return(0);
				# ------------------------------
    while (<$fhinLoc>) {	# skip before profile
	last if ($_=~ /^\#\# SEQUENCE PROFILE AND ENTROPY/);}
    $name=<$fhinLoc>;
    $name=~s/\n//g;$name=~s/^\s+|\s+$//g; # trailing blanks
    ($seqNo,$pdbNo,@name)=split(/\s+/,$name);
    $ct=0;			# ------------------------------
    while (<$fhinLoc>) {	# now the profile
	$line=$_; $line=~s/\n//g;
	last if ($_=~/^\#\#/);
	next if (length($line)<13);
	$seqNo=  substr($line,1,5);$seqNo=~s/\s//g;
	$pdbNo=  substr($line,6,5);$pdbNo=~s/\s//g;
	$chainRd=substr($line,12,1); # grep out chain identifier
	next if ( $chainLoc && ($chainRd ne $chainLoc));
	next if ( $ifirLoc  && ($seqNo < $ifirLoc));
	next if ( $ilasLoc  && ($seqNo > $ilasLoc));
	$line=substr($line,13);
	$line=~s/^\s+|\s+$//g; # trailing blanks
	@tmp=split(/\s+/,$line);
	++$ct;
	$tmp{"seqNo",$ct}=$seqNo;
	$tmp{"pdbNo",$ct}=$pdbNo;
	foreach $it (1..$#name){
	    $tmp{"$name[$it]",$ct}=$tmp[$it]; }
	$tmp{"NROWS"}=$ct; }close($fhinLoc);
    return(1,%tmp);
}				# end of hsspRdProfile

#==============================================================================
sub hsspRdSeqSecAcc {
    local($fileInLoc,$ifirLoc,$ilasLoc,$chain,@kwdRd) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$line,$chainLoc,$seqNo,$pdbNo,$chainRd,$ifirRd,$ilasRd);
    $[=1;
#----------------------------------------------------------------------
#   hsspRdSeqSecAcc             reads the HSSP seq/sec/acc from ifir to ilas
#       in:                     file.hssp_C ifir ilas (* for all numbers, ' ' or '*' for chain)
#                               @kwdRd (which to read) = 0 for all
#       out:                    %rdLoc{"kwd","it"}
#                 @kwd=         ("seqNo","pdbNo","seq","sec","acc")
#                                'chain'
#----------------------------------------------------------------------
    $sbrName="lib-br:hsspRdSeqSecAcc";$fhinLoc="FHIN"."$sbrName";$fhinLoc=~tr/[a-z]/[A-Z]/;
				# file existing?
    $chainLoc=0;
    if    (defined $chain){
	$chainLoc=$chain;}
    elsif ($fileInLoc =~/\.hssp.*_(.)/){
	$chainLoc=$fileInLoc;$chainLoc=~s/^.+.hssp.*_(.)$/$1/;
	$fileInLoc=~s/^(.+.hssp.*)_(.)$/$1/;}

    if (! -e $fileInLoc){
	print "*** $sbrName: HSSP file '$fileInLoc' missing\n";
	return(0);}
    $ifirLoc=0  if (! defined $ifirLoc  || ($ifirLoc eq "*") );
    $ilasLoc=0  if (! defined $ilasLoc  || ($ilasLoc eq "*") );
    $chainLoc=0 if (! defined $chainLoc || ($chainLoc eq "*") );
    $#kwdRd=0   if (! defined @kwdRd);
    undef %tmp;
    if ($#kwdRd>0){
	foreach $tmp(@kwdRd){
	    $tmp{"$tmp"}=1;}}

				# ------------------------------
				# open file
    $Lok=&open_file("$fhinLoc","$fileInLoc");
    if (! $Lok){print "*** ERROR $sbrName could not open HSSP '$fileInLoc'\n";
		return(0);}
				# ------------------------------
    while (<$fhinLoc>) {	# header
	last if ( $_=~/^\#\# ALIGNMENTS/ ); }
    $tmp=<$fhinLoc>;		# skip 'names'
    $ct=0;
				# ------------------------------
				# read seq/sec/acc
    while (<$fhinLoc>) {
	$line=$_; $line=~s/\n//g;
	last if ( $_=~/^\#\# / ) ;
        $seqNo=  substr($line,1,6);$seqNo=~s/\s//g;
        $pdbNo=  substr($line,7,6);$pdbNo=~s/\s//g;
        $chainRd=substr($line,13,1);  # grep out chain identifier
	next if ( $chainLoc && ($chainRd ne $chainLoc));
	next if ( $ifirLoc  && ($seqNo < $ifirLoc));
	next if ( $ilasLoc  && ($seqNo > $ilasLoc));
	++$ct;$tmp{"NROWS"}=$ct;
        if (defined $tmp{"chain"}) { $tmp{"chain",$ct}=$chainRd; }
        if (defined $tmp{"seq"})   { $tmp{"seq",$ct}=  substr($_,15,1); }
	if (defined $tmp{"sec"})   { $tmp{"sec",$ct}=  substr($_,18,1); }
	if (defined $tmp{"acc"})   { $tmp=               substr($_,37,3); $tmp=~s/\s//g;
				     $tmp{"acc",$ct}=  $tmp; }
	if (defined $tmp{"seqNo"}) { $tmp{"seqNo",$ct}=$seqNo; }
	if (defined $tmp{"pdbNo"}) { $tmp{"pdbNo",$ct}=$pdbNo; }
    }
    close($fhinLoc);
            
    return(1,%tmp);
}                               # end of: hsspRdSeqSecAcc 

#==============================================================================
sub hsspRdSeqSecAccOneLine {
    local ($inLine) = @_ ;
    local ($sbrName,$fhinLoc,$seqNo,$pdbNo,$chn,$seq,$sec,$acc,$tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspRdSeqSecAccOneLine      reads begin of one HSSP line
#-------------------------------------------------------------------------------
    $sbrName="hsspRdSeqSecAccOneLine";

    $seqNo=substr($inLine,1,6);$seqNo=~s/\s//g;
    $pdbNo=substr($inLine,7,5);$pdbNo=~s/\s//g;
    $chn=  substr($inLine,13,1);
    $seq=  substr($inLine,15,1);
    $sec=  substr($inLine,18,1);
    $acc=  substr($inLine,36,4);$acc=~s/\s//g;
    return($seqNo,$pdbNo,$chn,$seq,$sec,$acc)
}				# end of hsspRdSeqSecAccOneLine

#==============================================================================
sub isSwiss {
    local ($fileLoc) = @_ ; local ($Lok);
#--------------------------------------------------------------------------------
#    isSwiss                    checks whether or not file is in SWISS-PROT format (/^ID   /)
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
    $fhinLoc="FHIN_SWISS";
    open("$fhinLoc","$fileLoc"); $Lok=0;
    while (<$fhinLoc>){ 
	$Lok=1                  if ($_=~/^ID   /);
	last;}
    close($fhinLoc);
    return($Lok);
}				# end of isSwiss

#==============================================================================
sub is_chain {
    local($tmp) = @_ ;
#-------------------------------------------------------------------------------
#   is_chain                    checks whether or not a PDB chain
#       in:                     character
#       out:                    1,0
#-------------------------------------------------------------------------------
    return(0) if (! defined $tmp);
    return(1) if ($tmp=~/[A-Z0-9]/);
    return(0);
}				# end of is_chain

#==============================================================================
sub is_hssp {
    local ($fileInLoc) = @_ ;local ($fh,$Lis,$tmp);
#--------------------------------------------------------------------------------
#   is_hssp                     checks whether or not file is in HSSP format
#       in:                     $file
#       out:                    1 if is hssp; 0 else
#--------------------------------------------------------------------------------
				# highest priority: has to exist
    return (0)                  if (! -e $fileInLoc);
    $fh="FHIN_CHECK_HSSP";
    open($fh, $fileInLoc) || 
	do { print "*** ERROR is_hssp $fileInLoc not opened to $fh\n";
	     return (0) ;};	# missing file -> 0
    $tmp=<$fh>;			# first line
    close($fh);
				# is HSSP
    return(1)                   if (defined $tmp && $tmp=~/^HSSP/);
    return(0);
}				# end of is_hssp

#==============================================================================
sub myprt_empty {
    local($fhx)=@_;
#   myprt_empty                 writes line with '--- \n'
    $fhx="STDOUT" if (! defined $fhx);print $fhx "--- \n"; 
}				# end of myprt_empty

#==============================================================================
sub myprt_line  {
    local($fhx)=@_;
#   myprt_line                  prints a line with 70 '-'
    $fhx="STDOUT" if (! defined $fhx);print $fhx "-" x 70,"\n","--- \n";
}				# end of myprt_line

#==============================================================================
sub myprt_txt  {
    local($tmp,$fhx)=@_; 
#-------------------------------------------------------------------------------
#   myprt_txt                   adds '---' and '\n' for writing text
#-------------------------------------------------------------------------------
    $fhx="STDOUT" if(! defined $fhx);
    print $fhx "--- $tmp \n"; 
}				# end of myprt_txt

#==============================================================================
sub open_file {
    local ($file_handle,$file_name,$log_file) = @_ ;
    local ($temp_name) ;
#-------------------------------------------------------------------------------
#   open_file                  opens file, writes warning asf
#-------------------------------------------------------------------------------
    $temp_name = $file_name ;
    $temp_name =~ s/^>>|^>//g ;
    if ( ($file_name =~ /^>>/ ) && ( ! -e $temp_name ) ) {
	print "*** INFO (open_file): append file=$temp_name, does not exist-> create it\n" ;
	open ($file_handle, ">$temp_name") || ( do {
	    warn "***\t Cannot create new file: $temp_name\n" ;
	    if ( $log_file ) {
		print $log_file "***\t Cannot create new file: $temp_name\n" ;}
	    return (0);
	} );
	close ("$file_handle") ;}
  
    open ($file_handle, "$file_name") || ( do {
	warn "*** ERROR lib-br:open_file: Cannot open file '$file_name'\n" ;
	if ( $log_file ) {
	    print $log_file "*** lib-br:open_file: Cannot create new file '$file_name'\n" ;}
	return(0);
    } );
    return(1);
}				# end of open_file

#==============================================================================
sub rd_rdb_associative {
    local ($file_in,@des_in) = @_ ;
    local ($sbr_name,$fhin,$Lhead,$Lbody,$Lfound,$it,$itrd,@tmp,$tmp,$des_in,$rd,
	   @des_head,@des_headin,@des_bodyin,@des_body,%ptr_rd2des,$nrow_rd,%rdrdb,
	   $Lscreen);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   rd_rdb_associative          reads the content of an RDB file into an associative
#                               array
#       in:                     Names used for columns in perl file, e.g.,
#                               "header,NALIGN,body,POS,NPROT" as arguments passed
#                               would result in:
#                               reading anything in file header using the keyword 'NALIGN'
#                               reading the columns named POS and NPROT
#                       ALL:    'head,body'
#       out:                    rdrdb{"NALIGN"},rdrdb{"POS","ct"},rdrdb{"NPROT","ct"},
#                               where ct counts the rows read,
#                               rdrdb{"NROWS"} returns the numbers of rows read
#                       HEADER: rdrdb{"header"}
#                       NAMES:  rdrdb{"names"} 
#--------------------------------------------------------------------------------
				# avoid warning
    $READHEADER="";
    $Lscreen=1;
				# set some defaults
    $fhin="FHIN_RDB";
    $sbr_name="rd_rdb_associative";
				# get input
    $Lhead=$Lbody=$Lhead_all=$Lbody_all=$#des_headin=$#des_bodyin=0;
    foreach $des_in(@des_in){
	if   ($des_in=~/^not_screen/)        {$Lscreen=0;}
	elsif((!$Lhead) && ($des_in=~/head/)){$Lhead=1;$Lhead_all=1;}
	elsif((!$Lbody) && ($des_in=~/body/)){$Lbody=1;$Lhead=0; $Lbody_all=1;}
	elsif($Lhead)                        {push(@des_headin,$des_in); $Lhead_all=0;}
	elsif($Lbody)                        {$des_in=~s/\n|\s//g;; $Lbody_all=0;
					      push(@des_bodyin,$des_in);}
	else {print "*** WARNING $sbr_name: input '$des_in' not recognised.\n";} }
    if ($Lscreen) { print "--- $sbr_name: header \t ";
		    foreach $it (@des_headin){print"$it,";}print"\n"; 
		    print "--- $sbr_name: body   \t ";
		    foreach $it (@des_bodyin){print"$it,";}print"\n"; }
				# --------------------------------------------------
				# read RDB file
				# --------------------------------------------------
    &open_file("$fhin","$file_in");
				# out: $READHEADER :whole header, one string
				#      @READCOL    : all columns
				#      @READNAME   :names of columns
    &read_rdb_num2($fhin,0);
    close($fhin);
				# ------------------------------
				# process header
    $#des_head=0;
    @tmp=split(/\#\s?/,$READHEADER);
    if ($#des_headin>=1){
	foreach $des_in (@des_headin) {
	    $Lfound=0;
	    foreach $rd (@tmp){
		if ($rd =~ /^$des_in[ :,\;]/){
		    $tmp=$rd;$tmp=~s/\n|\s$//g;
		    $tmp=~s/$des_in//g;$tmp=~s/^\s*//g;
		    if (defined $rdrdb{"$des_in"}){
			$rdrdb{"$des_in"}.="\t".$tmp;}
		    else {
			$rdrdb{"$des_in"}=$tmp;}
		    push(@des_head,$des_in);
		    $Lfound=1;} }
	    if(!$Lfound && $Lscreen){
		print"--- $sbr_name: \t expected to find in header key word:\n";
		print"---            \t '$des_in', but not in file '$file_in'\n";}
	}}
    elsif ($Lhead_all) {		# whole header into $rdrdb{"header"}
	$rdrdb{"header"}="";
	foreach $rd (@tmp) { 
	    $rd=~s/^\s?|\n//g;
	    $rdrdb{"header"}.="# ".$rd."\n"; }}
				# ------------------------------
				# get column numbers to be read
    $#des_body=0;
    if (! $Lbody_all){
	foreach $des_in (@des_bodyin) {
	    $Lfound=0;
	    for($it=1;$it<=$#READNAME;++$it) {
		$rd=$READNAME[$it];
		if ($rd eq $des_in) {$ptr_rd2des{"$des_in"}=$it;push(@des_body,$des_in);
				     $Lfound=1;last;} }
	    if((!$Lfound) && $Lscreen){
		print"--- $sbr_name: \t expected to find column name:\n";
		print"---            \t '$des_in', but not in file '$file_in'\n";}}}
    else {
	foreach $it(1..$#READNAME){
	    $name=$READNAME[$it];$ptr_rd2des{"$name"}=$it;
	    push(@des_body,$name);}}
				# ------------------------------
				# get format
    foreach $des_in(@des_bodyin) {
	$it=$ptr_rd2des{"$des_in"};
	if ( (defined $it) && (defined $READFORMAT[$it]) ) {
	    $rdrdb{"$des_in","format"}=$READFORMAT[$it];}
	else {
	    $rdrdb{"$des_in","format"}="8";}}

    $nrow_rd=0;$names="";
    foreach $des_in(@des_body) {
	$itrd=$ptr_rd2des{"$des_in"};
	@tmp=split(/\t/,$READCOL[$itrd]);
	if ($nrow_rd==0){
	    $nrow_rd=$#tmp;}
	elsif($nrow_rd!=$#tmp){
	    print "*** WARNING $sbr_name: different number of rows\n";
	    print "*** WARNING in RDB file '$file_in' for rows with ".
		  "key= $des_in and previous column no=$itrd,\n";}
	$names.="$des_in".",";
	for($it=1;$it<=$#tmp;++$it){
	    $rdrdb{"$des_in",$it}=$tmp[$it];}
    }
    $rdrdb{"NROWS"}=$nrow_rd;
    $names=~s/,$//g;$rdrdb{"names"}=$names;
    return (%rdrdb);
}				# end of rd_rdb_associative

#==============================================================================
sub read_rdb_num2 {
    local ($fh, @readnum) = @_ ;
    local ($ct, @tmpar, $it, $ipos, $tmp);
    $[ =1 ;
#----------------------------------------------------------------------
#   read_rdb_num2               reads from a file of Michael RDB format:
#       in:                     $fh,@readnum,$readheader,@readcol,@readname,@readformat
#         $fh:                  file handle for reading
#         @readnum:             vector containing the number of columns to be read, if empty,
#                               then all columns will be read!
#         $READHEADER:          returns the complete header as one string
#         @READCOL:             returns all columns to be read
#         @READNAME:            returns the names of the columns
#         @READFORMAT:          returns the format of each column
#----------------------------------------------------------------------
    $READHEADER=""; $#READCOL=$#READNAME=$#READFORMAT= 0;
    for ($it=1; $it<=$#readnum; ++$it) { $READCOL[$it]=""; }
    $ct = 0;
    while ( <$fh> ) {
	if ( /^\#/ ) {$READHEADER.= "$_"; # header  
		      next;}
	++$ct;			# rest
	if ( $ct >= 3 ) {	              # col content
	    @tmpar=split(/\t/);
	    for ($it=1; $it<=$#readnum; ++$it) {
		if (defined $tmpar[$readnum[$it]]) {
		    $READCOL[$it].=$tmpar[$readnum[$it]] . "\t"; }} }
	elsif ( $ct==1 ) {	      # col name
	    $_=~s/\t$//g;@tmpar=split(/\t/);
				# care about wild card
	    if ( ($#readnum==0)||($readnum[1]==0) ) {
		for ($it=1;$it<=$#tmpar;++$it) {$readnum[$it]=$it;}
		for ($it=1;$it<=$#tmpar;++$it) {$READCOL[$it]=""; } }
	    
	    for ($it=1; $it<=$#readnum; ++$it) {$tmp_name=$tmpar[$readnum[$it]];
						$tmp_name=~s/\s|\n//g;
						$READNAME[$it]="$tmp_name";} }
	elsif ( $ct==2 ) {	      # col format
	    if ($_=~/\t\d+[NSF]|\d+[NSF]\t/){
		@tmpar=split(/\t/);
		for ($it=1; $it<=$#readnum; ++$it) {
		    $ipos=$readnum[$it];$tmp=$tmpar[$ipos]; $tmp=~s/\s//g;
		    $READFORMAT[$it]=$tmp;}}
	    else {		# no format given, read line
		@tmpar=split(/\t/);
		for ($it=1; $it<=$#readnum; ++$it) {
		    if (defined $tmpar[$readnum[$it]]) {
			$READCOL[$it].=$tmpar[$readnum[$it]] . "\t";}}}}
    }
    for ($it=1; $it<=$#READNAME; ++$it) {
	if (!defined $READFORMAT[$it]){
	    print "-*- WARN lib-br.pl:read_rdb_num2: READFORMAT for it=$it not defined\n";
	    $READFORMAT[$it]=" ";}
	$READFORMAT[$it]=~ s/^\s+//g;
	if ($#READNAME>0) { $READNAME[$it]=~ s/^\s+//g;}
	$READCOL[$it] =~ s/\t$|\n//g;	      # correction: last not return!
	$READFORMAT[$it]=~ s/\t$|\n//g;$READNAME[$it]=~s/\t|\n//g;
	if ($#READNAME>0) { $READNAME[$it]=~s/\n//g; }
    }
}				# end of read_rdb_num2

#==============================================================================
sub run_program {
    local ($cmd,$fhLogFile,$action) = @_ ;
    local ($out_command,$cmdtmp);
    $[ =1;

    ($cmdtmp,@out_command)=split(",",$cmd) ;

    print "--- running command: \t $cmdtmp"  if ((! defined $Lverb)||$Lverb);
    print " do='$action'"                    if (defined $action); 
    print "\n" ;
				# opens cmdtmp into pipe
    open (TMP_CMD, "|$cmdtmp") || 
	(do {print $fhLogFile "Cannot run command: $cmdtmp\n" if ( $fhLogFile ) || 
		 warn "Cannot run command: '$cmdtmp'\n" ;
	     exec '$action' if (defined $action);
	 });

    foreach $command (@out_command) { # delete end of line, and leading blanks
	$command=~s/\n//; $command=~s/^\s*|\s*$//g;
	print TMP_CMD "$command\n" ;
    }
    close (TMP_CMD) ;		# upon closing: cmdtmp < @out_command executed
}				# end of run_program

#==============================================================================
sub swissGetKingdom {
    local($fileLoc,$kingdomLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,@specLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   swissGetKingdom             gets all species for given kingdom
#       in:                     $kingdom (all,euka,proka,virus,archae)
#       out:                    @species
#-------------------------------------------------------------------------------
    $sbrName="swissKingdom2Species";$fhinLoc="FHIN"."$sbrName";$fhinLoc=~tr/[a-z]/[A-Z]/;
				# assign search pattern
    if    ($kingdomLoc eq "all")   { $tmp="EPAV";}
    elsif ($kingdomLoc eq "euka")  { $tmp="E";}
    elsif ($kingdomLoc eq "proka") { $tmp="P";}
    elsif ($kingdomLoc eq "virus") { $tmp="V";}
    elsif ($kingdomLoc eq "archae"){ $tmp="A";}
				# read SWISS-PROT file (/data/swissprot/speclist.txt)
    $#specLoc=0;
    &open_file("$fhinLoc","$fileLoc") || return(0,"*** $sbrName: failed opening '$fileLoc'\n");
	
				# notation 'SPECIES V|P|E|A\d+ ..'
    while (<$fhinLoc>) {
	last if /^Code  Taxon: N=Official name/;}
    while (<$fhinLoc>) {
	next if (! /^[A-Z].*[$tmp][0-9a-z:]+ /);
	@tmp=split(/\s+/,$_);
	$tmp[1]=~tr/[A-Z]/[a-z]/;
	push(@specLoc,$tmp[1]);}
    close($fhinLoc);

    return(@specLoc);
}				# end of swissGetKingdom

#==============================================================================
sub swissGetLocation {
    local ($regexpLoc,$fhLoc,@fileInLoc) = @_ ;
    local($sbrName,$fhoutLoc,$LverbLoc,@outLoc,@rdLoc);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   swissGetLocation            searches in SWISS-PROT file for cell location           
#       in:                     $regexp,$handle,@file
#                               $regexp e.g. = "^CC .*SUBCELLULAR LOCATION:"
#                               $fhLoc  = 0,1,FHOUT (file handle for blabla)
#                               @file   = swissprot files to read
#       out:                    ($Lok,$msg,@lines_with_expression)
#--------------------------------------------------------------------------------
    $sbrName="swissGetLocation";$fhinLoc="FHIN_$sbrName";
    if    ($fhLoc eq "0"){$fhoutLoc=0;$LverbLoc=0;}	# file handle
    elsif ($fhLoc eq "1"){$fhoutLoc="STDOUT";$LverbLoc=0;}
    else                 {$fhoutLoc=$fhLoc;$LverbLoc=0;}

				# ------------------------------
				# read swiss-prot files
    $#finLoc=0;
    foreach $fileTmp (@fileInLoc){
	next if (! -e $fileTmp);
	open($fhinLoc, $fileTmp) ||
	    return(0,"*** ERROR could NOT openf fileIn=$fileTmp");
	;$Lok=$Lfin=0;$loci="";
	while (<$fhinLoc>) {
	    $_=~s/\n//g;
	    if ($_=~/$regexpLoc/) {	# find first line (CC )
		$_=~s/$regexpLoc//g; # purge keywords
		$Lok=1;
		$loci=$_." ";}
	    elsif ($Lok && $_=~/^CC\s+\-+\s*$/) { # end if new expression
		$Lfin=1;}
	    elsif ($Lok && $_=~/^[^C]|^CC\s+-\!-/) { # end if new expression
		$Lfin=1;}
	    elsif ($Lok){
		$_=~s/^CC\s+//;
		$loci.=$_." ";}
	    last if ($Lfin);}
	close($fhinLoc);
	next if (length($loci)<5);
	$loci=~s/\t+/\s/g; 
	print $fhoutLoc "--- '$regexpLoc' in $fileTmp:$loci\n"
	    if ($LverbLoc);
	$id=$fileTmp;
	$id=~s/^.*\///g;$id=~s/\n|\s//g;
	$tmp="$loci"."\t"."$id";
	push(@finLoc,"$tmp");}
    return(1,"ok",@finLoc);
}				# end of swissGetLocation



#==============================================================================
# library collected (end)   lll
#==============================================================================

