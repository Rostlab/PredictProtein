#!/usr/sbin/perl -w
##!/bin/env perl -w
##!/usr/bin/perl
#-------------------------------------------------------------------------------
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$scriptName=   "port-bupHome";	# name of script
$scriptIn=     "auto (or: rost.tar defaults.port-bupHome)";		# input
$scriptTask=   "backups the enire home directory (and mail), auto = automatically all into rost.tar"; # task
$scriptNarg=   1;		# minimal number of input arguments
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# 		
# subroutines   (internal):  
#               x
#                                  y
# 		
#
#------------------------------------------------------------------------------#
#	Copyright				November,	1997	       #
#	Burkhard Rost		rost@EMBL-Heidelberg.DE			       #
#	EMBL			http://www.embl-heidelberg.de/~rost/	       #
#	D-69012 Heidelberg						       #
#				version 0.1   	November,	1997	       #
#------------------------------------------------------------------------------#
				# sets array count to start at 1, not at 0
$[ =1 ;

$Lok=&ini;			# initialise variables
if (! $Lok){ die '*** after initialisation'; }

$dirHome=$par{"dirHome"};
$dirMail=$par{"dirMail"};
#$dirPub= $par{"dirPub"};
$dirDot= $par{"dirDot"};

$fileLog=$par{"fileLog"};

#-------------------------------------------------------------------------------
# do the job (here we go)
#-------------------------------------------------------------------------------
&open_file("$fhoutLog",">$fileLog"); # log file
				# ------------------------------
				# first local tar version
&printm("--- -------------------------------------------------------\n","$fhoutLog","STDOUT");
&printm("--- $scriptName \t make bup tar file\n","$fhoutLog","STDOUT");
&printm("--- -------------------------------------------------------\n","$fhoutLog","STDOUT");
foreach $kwd("dirHome","dirMail"){
    $file="$kwd".".tar";
    $dir=$par{"$kwd"};
    if (! -d $dir){
	print $fhoutLog "*** WARNING (generate tar in $scriptName) missing directory '$dir'\n";
	next;}
    &systemMy("tar -cvf $file $dir","$fhoutLog"); # tars the directory
}
				# ------------------------------
				# now untar and move
&printm("--- -------------------------------------------------------\n","$fhoutLog","STDOUT");
&printm("--- $scriptName \t untar and move\n","$fhoutLog","STDOUT");
&printm("--- -------------------------------------------------------\n","$fhoutLog","STDOUT");
foreach $kwd("dirHome","dirMail"){
    $file="$kwd".".tar";
    $dir=$par{"$kwd"};
    if (! -e $file){	# skip if missing
	&printm("--- $scriptName \t missing file=$file,\n","$fhoutLog","STDOUT");
	next;}
    &systemMy("tar -xvf $file","$fhoutLog"); # untars the directory-file
    $Lok=&fileRm("$fhoutLog",$file); # removes tar file

    $dir=~s/^\///g;		# relative path!
    $dir2=$dir;$dir2=~s/\/$//g;	# removes last slash
    if (! -d $dir){	# skip if missing
	&printm("--- $scriptName \t missing dir=$dir,\n","$fhoutLog","STDOUT");
	next;}
    &systemMy("\\mv $dir2/* .","$fhoutLog"); # moves everything to local
    &systemMy("\\mv $dir2/.[a-z]* .","$fhoutLog"); # also dot files!
    &systemMy("rmdir $dir","$fhoutLog");	# removes the - hopefully empty - path name
}
				# ------------------------------
				# now make partial tar files
&printm("--- -------------------------------------------------------\n","$fhoutLog","STDOUT");
&printm("--- $scriptName \t make partial tar files\n","$fhoutLog","STDOUT");
&printm("--- -------------------------------------------------------\n","$fhoutLog","STDOUT");
foreach $kwd ("dirPerl","dirEtc","dirDiv","dirBin","dirPort","dirEmacs","dirMail","dirPub"){
    $dir=$par{"$kwd"};
    $dir2=$dir;$dir2=~s/$dirHome//g;
    if (! -d $dir2){	# skip if missing
	&printm("--- $scriptName \t missing dir=$dir2,\n","$fhoutLog","STDOUT");
	next;}
    if    ($dir =~/^$dirMail/){
	$dir=~s/^.*\///g;}
    elsif ($dir =~/^$dirHome/){
	$dir=~s/^$dirHome//g;}
    else {
	print "*** trying to re-tar: unrecognised directory $dir\n";
	die;}
    $file=$kwd;$file=~s/dir//g; $file.=".tar";	# tared file name
    &systemMy("tar -cvf $file $dir","$fhoutLog"); # tar (e.g. /home/rost/pub -> Pub.tar)
    &systemMy("gzip $file","$fhoutLog");	# gzip (add '.gz')
    &systemMy("\\rm -r $dir","$fhoutLog"); # delete all files which were tared and zipped
}
				# finally remove local version of home
$dir=$dirHome;$dir=~s/^\///g;$dir2=$dir;$dir2=~s/\/.*$//g;
&systemMy("\\rm -r $dir","$fhoutLog");
&systemMy("\\rm -r $dir2","$fhoutLog");
				# ------------------------------
				# tar for dot files
&printm("--- -------------------------------------------------------\n","$fhoutLog","STDOUT");
&printm("--- $scriptName \t tar for dot files\n","$fhoutLog","STDOUT");
&printm("--- -------------------------------------------------------\n","$fhoutLog","STDOUT");
# special "dirDot",
$dirDotLoc=$dirDot;$dirDotLoc=~s/$dirHome//g;$dirDotLoc=~s/\.$//g;$dirDotLoc=~s/\/$//g;
if (-d $dirDotLoc){$dirDotLoc.=$$;}
&systemMy("mkdir $dirDotLoc","$fhoutLog");	# make new directory 'Dot'
&systemMy("\\cp \.[a-z]* $dirDotLoc/","$fhoutLog"); # copy dot files to local dot directory
				# special for netscape
$dirNetscape=".netscape/";
if (-d $dirNetscape){
    $dir3=$dirDotLoc."/.netscape";
    &systemMy("mkdir $dir3","$fhoutLog");	# make new directory 'Dot/.netscape'
    &systemMy("\\cp $dirNetscape/* $dir3","$fhoutLog");} # copy netscape files
    
&systemMy("tar -cvf Dot.tar $dirDotLoc/","$fhoutLog");	# tar dot dir
&systemMy("gzip Dot.tar","$fhoutLog"); # compress dot dir
&systemMy("\\rm \.[a-z]*/*","$fhoutLog");	# remove local dot files in dot dirs
&systemMy("\\rm \.[a-z]*","$fhoutLog");	# remove local dot files
&systemMy("\\rmdir \.[a-z]*","$fhoutLog"); # remove local dot dirs
&systemMy("\\rm -r $dirDotLoc","$fhoutLog"); # remove temporary dot dir

				# ------------------------------
				# now all to one big tar file
if (!defined $fileBup){$fileBup="rost.tar";}

&systemMy("tar -cvf $fileBup *z","$fhoutLog"); # tar all zipped files
&systemMy("\\rm *z","$fhoutLog");	# remove all zipped files
&systemMy("gzip *tar","$fhoutLog"); # finally zip the tared final

close($fhoutLog);

#-------------------------------------------------------------------------------
# work done, go home
#-------------------------------------------------------------------------------
if ($Lverb) { &myprt_empty; &myprt_line; &myprt_txt("\n$scriptName ended fine .. -:\)"); 
	      &myprt_txt("logfile      \t $fileLog ");
	      &myprt_txt("output file  \t $fileBup (\.gz?)");}

exit;

#===============================================================================
sub ini {
    local (@scriptTask,@scriptHelp,@scriptKwd,@scriptKwdDescr,$txt);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   initialises variables/arguments
#-------------------------------------------------------------------------------
    $PWD=                       $ENV{'PWD'}; $pwd=&complete_dir($PWD);
    $ARCH=                      $ENV{'ARCH'}; 
    if (!defined $ARCH)         {print "-*- WARNING \t no architecture defined\n";}

    &iniDefaults;               # first settings for parameters (may be overwritten by
				# default file and command line input)
    &iniHelp;

    $Lok=&iniRdDefManager;	# get stuff from default file
    if (! $Lok){print "*** ini ($scriptName) ERROR in iniRdDefManager\n";
		$Lok=&iniAskDefaults; # xx write 
		if (! $Lok){print "*** ini ($scriptName) ERROR in iniAskDefaults\n";
			    return(0);}}

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
		      foreach $_(@fileOut){printf "--- %-20s '%-s'\n"," ",$_;}}
		foreach $kwd (@kwdDef) {
		    if (! defined $par{"$kwd"}){$tmp="!! UNDEF !!";}else{$tmp=$par{"$kwd"};}
		    printf "--- %-20s '%-s'\n",$kwd,$tmp;}&myprt_line;}

    # ------------------------------------------------------------
    # check existence of file
    # ------------------------------------------------------------
    $Lmiss=0;
    foreach $kwd(@kwdDef){
	if ($kwd =~/^(fileIn|exe)/){
	    if ((! -e $par{"$kwd"})&&(! -l $par{"$kwd"})){
		printf "*** %-20s '%-s'\n","MISSING $kwd",$par{"$kwd"};$Lmiss=1;}}}
    if ($Lmiss){
	print "*** try to locate the missing files/executables before continuing!\n";
	print "*** left script '$scriptName' after ini \n";
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
		     );
    @scriptKwdDescr=(" ", 
		     );

    if ( $#ARGV < $scriptNarg ) {
	print "-" x 80,"\n"; &myprt_txt("Perl script"); 
	foreach $txt (@scriptTask) {if($txt !~ /Done:/){&myprt_txt("$txt");}} 
	&myprt_txt("Optional:");
	foreach $txt (@scriptHelp){&myprt_txt("$txt");}
	&myprt_empty;print"-" x 80,"\n";die;}
    elsif ( ($ARGV[1]=~/^help|^man|^-h/) ) { 
	print "-" x 80,"\n"; &myprt_txt("Perl script"); 
	foreach $txt (@scriptTask) {if($txt !~ /Done:/){&myprt_txt("$txt");}} 
	&myprt_txt("Optional:");
	foreach $kwdOpt(@kwdDef){
	    if (! defined $par{"$kwdOpt"}){$tmp="undef";}else{$tmp=$par{"$kwdOpt"};}
	    printf "--- %-12s=x \t (def:=%-s) \n",$kwdOpt,$tmp;}
	&myprt_empty; print "-" x 80,"\n"; die; }
}				# end of iniHelp

#===============================================================================
sub iniDefaults {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iniDefaults                 initialise defaults
#-------------------------------------------------------------------------------
    $par{"userName"}=	"rost";

				# --------------------
				# directories
				# --------------------
    $par{"dirHome"}=	        "/home/rost/";
    $par{"dirHome"}=            "/junk/rost/xxhome/"; # xx
    $par{"dirPerl"}=            $par{"dirHome"}."perl/";
    $par{"dirEtc"}=		$par{"dirHome"}."etc/";
    $par{"dirBin"}=             $par{"dirHome"}."bin/";
    $par{"dirDot"}=             $par{"dirHome"}."dot/";
    $par{"dirPort"}=            $par{"dirHome"}."port/";
    $par{"dirEmacs"}=           $par{"dirHome"}."emacs/";
    $par{"dirMail"}=            $par{"dirHome"}."mail/";
    $par{"dirPub"}=             $par{"dirHome"}."pub/";
    $par{"dirPubPhd"}=          $par{"dirHome"}."pub/phd/";
    $par{"dirPubTopits"}=       $par{"dirHome"}."pub/topits/";
    $par{"dirPubMax"}=          $par{"dirHome"}."pub/max/";
    $par{"dirPubPerl"}=         $par{"dirHome"}."pub/perl/";
#
    $par{"dirFssp"}=		"/data/fssp/";
    $par{"dirHssp"}=		"/data/hssp/";
    $par{"dirDssp"}=		"/data/dssp/";
    $par{"dirSwiss"}=	        "/data/swissprot/current/";
    $par{"dirPdb"}=		"/data/pdb/";
				# files
    $par{"fileBup"}=            "rost.tar";
    $par{"fileLog"}=            "LOG-port-bupHome".$$.".tmp"; # xx
    $par{"fileLog"}=            "LOG-port-bupHome.tmp";

				# file handles
    $fhout=                     "FHOUT";
    $fhoutLog=                  "FHOUT_LOG";
    $fhin=                      "FHIN";
				# --------------------
				# further
				# computing Alignment Shift

				# --------------------
				# logicals
    $Lverb=                     1; # blabla on screen
				# --------------------
				# executables
#    $par{"exe"}=                "";
				# ------------------------------
				# a.a descriptors 
				# allowed in default file
				# ------------------------------
    @kwdDef=     ("verbose",
		  "userName","perlPath","dirHome",
		  "dirPerl","dirEtc","dirDiv","dirBin","dirDot",
		  "dirPort","dirEmacs","dirMail","dirPub",
		  "dirPubPhd","dirPubTopits","dirPubMax","dirPubPerl",
		  "dirFssp","dirHssp","dirDssp","dirSwiss","dirPdb",
		  "",
		   );

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
	if    (/^verb/){$Lverb=1;}
	elsif (/^fileDefaults=(.+)$/){
	    $fileDefaults=$1;$fileDefaults=~s/\s//g;
	    if (! -e "$fileDefaults") {
		print "*** ERROR iniRdDefManager: you gave the default file by '$_'\n";
		print "***                        but file '$fileDefaults' not existing!\n";
		return(0);}
	    $Lok=1;
	    last;}}
				# ------------------------------
    foreach $_(@ARGV){		# input/work directory
	if (/^(dirIn|dirWork)=(.+)$/){$kwd=$1;$dir=$2;
				      $dir=&complete_dir($dir);	# external lib-ut.pl
				      $par{"$kwd"}=$dir;}}
				# ------------------------------
				# search default file
    if ((! defined $fileDefaults)||(! -e $fileDefaults)) { # search file with defaults
	if (defined $pwd){@tmpDir=("$pwd");}else{$#tmpDir=0;}
	foreach $des ("dirWork","dirIn"){
	    if ((defined $par{"$des"})&&(-d $par{"$des"})){push(@tmpDir,$par{"$des"});}}
				# local directory
	$fileDefaults=$scriptName.".defaults";
	if  (-e $fileDefaults) {
	    print "--- iniRdDefManager: defaults taken from file '$fileDefaults'\n";}
	foreach $dir (@tmpDir){
	    next if ((! defined $dir)||(! -d "$dir"));
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
		&iniRdDef($fileDefaults,$Lverb); 

	&iniRdDefCheckKwd($kwdRdDef,$fileDefaults);

	print "-*- WARNING content of '$fileDefaults' may overwrite hard coded parameters\n";
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
	next if ((length($_)<3)||(/^\s*\#/)); # ignore lines beginning with '#'
	next if (!/\w/);
	@tmp=split(/[ \t]+/);
	next if ($#tmp<2);	# must find 2 arguments
	foreach $tmp (@tmp) { 
	    $tmp=~s/[ \n]*$//g; } # purge end blanks
	$kwdRdDef.="$tmp[1]"."," unless (defined $defaults{"$tmp[2]"}); 
	if ($tmp[1] =~/^dir/){	# add '/' at end of directories
	    $tmp[2]=&complete_dir($tmp[2]);} # external lib-ut.pl
	$defaults{"$tmp[1]"}=$tmp[2]; 
	if ($Lverb){printf "--- read: %-22s (%s)\n",$tmp[1],$tmp[2];}
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
sub iniAskDefaults {
#    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iniAskDefaults              quest the content of the default file if missing
#-------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";}
    $sbrName="$tmp"."iniAskDefaults";$fhinLoc="FHIN"."$sbrName";

    foreach $kwd(@kwdDef){
	next if ((! defined $kwd)||(length($kwd)<1));
	next if ($kwd =~/^verb/);
	if (defined $par{"$kwd"}){
	    $def=$par{"$kwd"};}else{$def=" ";}
	$tmp=
	    &get_in_keyboard($kwd,$def);
	if (defined $tmp && (length($tmp)>0)){
	    $par{"$kwd"}=$tmp;}}
}				# end of iniAskDefaults

#===============================================================================
sub iniGetArg {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iniGetArg                   read command line arguments
#-------------------------------------------------------------------------------
    $Lokdef=0; $#fileIn=$#tmp=0;
    if ($ARGV[1] eq "auto"){
	$fileBup=$par{"fileBup"};}
    else {
	$fileBup=$ARGV[1];
	if ($#ARGV>1){
	    $fileDefaults=$ARGV[2];
	    if (! -e $fileDefaults){
		print "*** default file (2nd argument) not existing\n";
		die;}}}
    foreach $arg (@ARGV){	# key word driven input
	next if ($arg eq "auto");
	if    ($arg=~/^verb/){$Lverb=1;}
	elsif ($arg=~/not_(ver|screen)/ ) {$Lverb=0; }
	else {			# general
	    $Lok=0;
	    foreach $kwd (@kwdDef){
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
	       return(0);}}
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
				# ------------------------------
				# add directory to executables
    foreach $kwd (@kwdDef){
	if (($kwd=~/^exe/)&&(defined $par{"$kwd"})&&(! -e $par{"$kwd"})&&
	    (! -l $par{"$kwd"})){
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

#==========================================================================
sub complete_dir { local($dir)=@_; $[=1 ; 
		   if (! defined $dir){
		       return;}
		   $dir=~s/\s|\n//g; 
		   if ( (length($dir)>1)&&($dir!~/\/$/) ) {$dir.="/";} 
		   $DIR=$dir;
		   return $DIR; }

#==========================================================================
sub cp_file { @outLoc=&fileCp(@_);return(@outLoc);} # alias

#==========================================================================================
sub dirLsAll {
    local($dirLoc) = @_ ;local($sbrName,$fhinLoc,@tmp);
#--------------------------------------------------------------------------------
#   dirLsAll                    will return all directories in dirLoc (and
#                               subdirectories therof)
#       in:                     dirLoc (directory)
#       out:                    @files
#--------------------------------------------------------------------------------
    if (! -d $dirLoc){		# directory empty
	return(0);}
    $sbrName="dirLsAll";$fhinLoc="FHIN"."$sbrName";$#tmp=0;
    open($fhinLoc,"find $dirLoc -print |");
    while (<$fhinLoc>){$_=~s/\s//g;
		       if (-d $_){
			   push(@tmp,$_);}}close($fhinLoc);
    return(@tmp);
}				# end of dirLsAll

#==========================================================================
sub dirMk  { local($fhoutLoc,@dirLoc)=@_; local($tmp,@tmp,$Lok,$dirLoc);
	     if   (! defined $fhoutLoc){ $fhoutLoc=0;push(@dirLoc,$fhoutLoc);}
	     elsif(($fhoutLoc!~/[^0-9]/)&&($fhoutLoc == 1)) { $fhoutLoc="STDOUT";}
	     $Lok=1;$#tmp=0;
	     foreach $dirLoc(@dirLoc){
		 if ((! defined $dirLoc)||(length($dirLoc)<1)){
		      $tmp="-*- WARNING 'lib-ut:dirMk' '$dirLoc' pretty useless";
		      if ($fhoutLoc){print $fhoutLoc "$tmp\n";}
		      push(@tmp,$tmp);
		     next;}
		 if (-d $dirLoc){
		     $tmp="-*- WARNING 'lib-ut:dirMk' '$dirLoc' exists already";
		     if ($fhoutLoc){print $fhoutLoc "$tmp\n";}
		     push(@tmp,$tmp);
		     next;}
		 $dirLoc=~s/\/$//g; # purge trailing '/'
		 $tmp="'mkdir $dirLoc'"; push(@tmp,$tmp);
		 if ($fhoutLoc){printf $fhoutLoc "--- %-20s %-s\n","system:","$tmp";}
		 system("mkdir $dirLoc");
		 if (! -d $dirLoc){
		     $tmp="*** ERROR 'lib-ut:dirMk' '$dirLoc' not made";
		     if ($fhoutLoc){print $fhoutLoc "$tmp\n";}
		     $Lok=0; push(@tmp,$tmp);}}
	     return($Lok,@tmp);} # end of dirMk

#==========================================================================
sub file_cp { @outLoc=&fileCp(@_);return(@outLoc);} # alias

#==========================================================================
sub file_mv { @outLoc=&fileMv(@_);return(@outLoc);} # alias

#==========================================================================
sub file_rm { @outLoc=&fileRm(@_);return(@outLoc);} # alias

#==========================================================================
sub fileCp  { local($f1,$f2,$fhoutLoc)=@_; local($tmp);
	      if   (! defined $fhoutLoc){ $fhoutLoc=0;}
	      elsif($fhoutLoc eq "1")     { $fhoutLoc="STDOUT";}
	      if (! -e $f1){$tmp="*** ERROR 'lib-ut:fileCp' in=$f1, missing";
			    if ($fhoutLoc){print $fhoutLoc "$tmp\n";}
			    return(0,"$tmp");}
	      if (! defined $f2){$tmp="*** ERROR 'lib-ut:fileCp' f2=$f2, undefined";
				 if ($fhoutLoc){print $fhoutLoc "$tmp\n";}
				 return(0,"$tmp");}
				 
	      $tmp="'\\cp $f1 $f2'";
	      if ($fhoutLoc){printf $fhoutLoc "--- %-20s %-s\n","system:","$tmp";}
	      system("\\cp $f1 $f2");
	      if (! -e $f2){$tmp="*** ERROR 'lib-ut:fileCp' out=$f2, missing";
			    if ($fhoutLoc){print $fhoutLoc "$tmp\n";}
			    return(0,"$tmp");}
	      return(1,"$tmp");} # end of fileCp

#==========================================================================================
sub fileLsAll {
    local($dirLoc) = @_ ;local($sbrName,$fhinLoc,@tmp);
#--------------------------------------------------------------------------------
#   fileLsAll                  will return a list of all files in dirLoc (and
#                               subdirectories therof)
#       in:                     dirLoc (directory)
#       out:                    @files
#--------------------------------------------------------------------------------
    if (! -d $dirLoc){		# directory empty
	return(0);}
    $sbrName="fileLsAll";$fhinLoc="FHIN"."$sbrName";

    open($fhinLoc,"find $dirLoc -print |");
    while (<$fhinLoc>){$_=~s/\s//g; 
		       next if ($_=~/\~$/);
				# avoid reading subdirectories
		       $tmp=$line;$tmp=~s/$dirLoc//g;$tmp=~s/^\///g;
		       next if ($tmp=~/\//);
		       push(@tmp,$_) unless -d ;}close($fhinLoc);
    return(@tmp);
}				# end of fileLsAll

#==========================================================================================
sub fileLsAllTxt {
    local($dirLoc) = @_ ;local($sbrName,$fhinLoc,@tmp);
#--------------------------------------------------------------------------------
#   fileLsAllTxt                will return all text files in dirLoc (and
#                               subdirectories therof)
#       in:                     dirLoc (directory)
#       out:                    @files
#--------------------------------------------------------------------------------
    $sbrName="fileLsAllTxt";$fhinLoc="FHIN"."$sbrName";
    if (! -d $dirLoc){		# directory empty
	return(0);}
    open($fhinLoc,"find $dirLoc -print |");
    while (<$fhinLoc>){$line=$_; $line=~s/\s//g;
		       if (-T $line && ($line!~/\~$/)){
				# avoid reading subdirectories
			   $tmp=$line;$tmp=~s/$dirLoc//g;$tmp=~s/^\///g;
			   next if ($tmp=~/\//);
			   push(@tmp,$line);}}close($fhinLoc);
    return(@tmp);
}				# end of fileLsAllTxt

#==========================================================================
sub fileMv  { local($f1,$f2,$fhoutLoc)=@_; local($tmp);
	      if (! -e $f1){$tmp="*** ERROR 'lib-ut:fileMv' in=$f1, missing";
			    if ($fhoutLoc){print $fhoutLoc "$tmp\n";}
			    return(0,"$tmp");}
	      $tmp="'\\mv $f1 $f2'";
	      if ($fhoutLoc){printf $fhoutLoc "--- %-20s %-s\n","system:","$tmp";}
	      system("\\mv $f1 $f2");
	      if (! -e $f2){$tmp="*** ERROR 'lib-ut:fileMv' out=$f2, missing";
			    if ($fhoutLoc){print $fhoutLoc "$tmp\n";}
			    return(0,"$tmp");}
	      return(1,"$tmp");} # end of fileMv

#==========================================================================
sub fileRm  { local($fhoutLoc,@fileLoc)=@_; local($tmp,@tmp,$Lok,$fileLoc);
	      if (-e $fhoutLoc){push(@fileLoc,$fhoutLoc);$fhoutLoc=0;}
	      $Lok=1;$#tmp=0;
	      foreach $fileLoc(@fileLoc){
		  if (-e $fileLoc){
		      $tmp="'\\rm $fileLoc'"; push(@tmp,$tmp);
		      if ($fhoutLoc){printf $fhoutLoc "--- %-20s %-s\n","system:","$tmp";}
		      system("\\rm $fileLoc");}
		  if (-e $fileLoc){
		      $tmp="*** ERROR 'lib-ut:fileRm' '$fileLoc' not deleted";
		      if ($fhoutLoc){print $fhoutLoc "$tmp\n";}
		      $Lok=0; push(@tmp,$tmp);}}
	      return($Lok,@tmp);} # end of fileRm

#==========================================================================================
sub get_in_keyboard {local($des,$def)=@_;local($txt);
		     $txt="";
		     print ">>> type value for '$des' (return to end):\n";
		     if (defined $def){
			 print ">>> (current default is '$def')\n";}
		     while(<STDIN>){$txt.=$_;last if (/\n/);} $txt=~s/^\s+|\s+$//g;
		     print "--- echo '$des' -> '$txt' \t if that doesn't suit you, exit!\n";
		     return ($txt);
		 }		# end of get_in_keyboard

#==========================================================================================
sub isHelp {
    local ($argLoc) = @_ ;$[ =1 ;
#--------------------------------------------------------------------------------
#   isHelp		        returns 1 if : help,man,-h
#--------------------------------------------------------------------------------
    if ( ($argLoc eq "help") || ($argLoc eq "man") || ($argLoc eq "-h") ){
	return(1);}else{return(0);}
}				# end of isHelp

#==========================================================================================
sub lsAllDir      { @outLoc=&dirLsAll(@_);return(@outLoc);} # alias
#==========================================================================================
sub lsAllFiles    { @outLoc=&fileLsAll(@_);return(@outLoc);} # alias
#==========================================================================================
sub lsAllTxtFiles { @outLoc=&fileLsAllTxt(@_);return(@outLoc);} # alias
#======================================================================
sub myprt_array { local($sep,@A)=@_;$[=1;local($a);
		  foreach $a(@A){print"$a$sep";}print"\n";}
#======================================================================
sub myprt_empty { print "--- \n"; }
#======================================================================
sub myprt_line { print "-" x 70, "\n", "--- \n"; }
#======================================================================
sub myprt_txt { local ($string) = @_; print "--- $string \n"; }
#==========================================================================================
sub printm { local ($txtLoc,@fhLoc) = @_ ;local ($fh);$[ =1 ;
#--------------------------------------------------------------------------------
#   printm                      print on multiple filehandles (in:$txt,@fh; out:print)
#--------------------------------------------------------------------------------
	     foreach $fh (@fhLoc) { print $fh $txtLoc;}
}				# end of printm

#===============================================================================
sub systemMy {
    local($cmdLoc,$fhLoc) = @_ ;
    local($sbrName,$tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   systemMy                    runs the system command with writing onto screen
#-------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";}$sbrName="$tmp"."systemMy";
    $tmp="--- $sbrName \t '$cmdLoc'\n";
    if    (! defined $fhLoc)  {print $tmp;}
    elsif ($fhLoc ne "STDOUT"){&printm("$tmp","STDOUT","$fhLoc");}
    else                      {print $tmp;}
    system("$cmdLoc");
}				# end of systemMy

#======================================================================
sub open_file {
    local ($file_handle,$file_name,$log_file) = @_ ;
    local ($temp_name) ;

    $temp_name = $file_name ;
    $temp_name =~ s/^>>|^>//g ;
    if ( ($file_name =~ m/^>>/ ) && ( ! -e $temp_name ) ) {
	print "*** \t INFO: file $temp_name does not exist, create it\n" ;
	open ($file_handle, ">$temp_name") || ( do {
	    warn "***\t Cannot create new file: $temp_name\n" ;
	    if ( $log_file ) {
		print $log_file "***\t Cannot create new file: $temp_name\n" ;}
	    return (0);
	} );
	close ("$file_handle") ;}
  
    open ($file_handle, "$file_name") || ( do {
	warn "*** \t Cannot open file '$file_name'\n" ;
	if ( $log_file ) {
	    print $log_file "*** \t Can't create new file '$file_name'\n" ;}
	return(0);
    } );
    return(1);
}

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

