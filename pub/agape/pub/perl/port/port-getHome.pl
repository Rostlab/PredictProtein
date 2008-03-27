#!/usr/pub/bin/perl -w
##!/bin/env perl
##!/usr/bin/perl
#-------------------------------------------------------------------------------
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$scriptName=   "port-getHome";	# name of script
$scriptIn=     "auto (or: rost.tar defaults.port-getHome)";		# input
$scriptTask=   "unpacks the enire home directory (preferably in a work dir),  \n".
               "--- \t \t and builds up appropriate environment, incl. dot-files\n".	# task
               "--- \t \t working directory is dirPort";	# task
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

$dirNewHome=$par{"dirNewHome"};
$dirSave=   $dirNewHome."savePort/";
$dirSaveDot=$dirNewHome."saveDot/";

$fileLog=$par{"fileLog"};

$gunzip=$par{"exeGunzip"};

#-------------------------------------------------------------------------------
# do the job (here we go)
#-------------------------------------------------------------------------------
&open_file("$fhoutLog",">$fileLog"); # log file

if (! -d $dirSave){
    &systemMy("mkdir $dirSave","$fhoutLog");}
				# ------------------------------
				# unzip and untar
&printm("--- $scriptName \t unzip and untar\n","$fhoutLog","STDOUT");
				# unzip
if (($fileBup =~ /z$/)||(-e "$fileBup".".gz")){
    &systemMy("$gunzip $fileBup*","$fhoutLog");
    if ($fileBup =~/gz$/){$fileBup=~s/\.gz//g;} } # purge *gz from file naem
				# untar
&systemMy("tar -xvf $fileBup","$fhoutLog");
&systemMy("\\mv $fileBup $dirSave","$fhoutLog"); # save the ported bup
				# ------------------------------
				# unzip and untar all single ones
&printm("--- -------------------------------------------------------\n","$fhoutLog","STDOUT");
&printm("--- $scriptName \t unzip and untar all single files \n","$fhoutLog","STDOUT");

&systemMy("$gunzip *z","$fhoutLog");
foreach $kwd ("dirPerl","dirEtc","dirDiv","dirBin","dirDot",
	      "dirPort","dirEmacs","dirMail","dirPub"){
    $dir=$kwd;
    $file=$kwd;$file=~s/dir//g;$file.=".tar";
    if (! -e $file){&printm("--- $scriptName \t missing file=$file,\n","$fhoutLog","STDOUT");
		    next;}
    &systemMy("tar -xvf $file"); # untar (e.g. Pub.tar -> pub)
    &systemMy("\\mv $file $dirSave"); # move the tared file
}
				# move mail directory out of way
if (-e "mail"){$mail="mailImport";
	       &systemMy("mv mail $mail","$fhoutLog");
	       &systemMy("mv $mail ../","$fhoutLog");}

				# --------------------------------------------------
				# now change names
				# --------------------------------------------------
&printm("--- -------------------------------------------------------\n","$fhoutLog","STDOUT");
&printm("--- $scriptName \t now change file names\n","$fhoutLog","STDOUT");
&printm("--- -------------------------------------------------------\n","$fhoutLog","STDOUT");
				# security backup
@allTxtFiles=&fileLsAllTxt($PWD); # list all text files

$#old=$#new=0;			# new/old regular expressions
foreach $kwd("dirNewPerl","dirNewEtc","dirNewDiv","dirNewBin",
	     "dirNewPort","dirNewEmacs","dirNewMail",
	     "dirNewPub","dirNewHome","userNameNew","perlPathNew",
	     "dirNewFssp","dirNewHssp","dirNewDssp","dirNewSwiss","dirNewPdb"){
    $kwdOld=$kwd;$kwdOld=~s/New/Old/g;
    next if ((!defined $par{"$kwd"})||(!defined $par{"$kwdOld"}));
    push(@old,$par{"$kwdOld"});
    push(@new,$par{"$kwd"});}
				# ------------------------------
&portAdopt;			# change regular expressions in all files

				# ------------------------------
				# change mode of all binaries
&printm("--- $scriptName \t chmod of all binary files\n","$fhoutLog","STDOUT");

@allBinFiles=&fileLsAllBin($PWD); # list all binary files
foreach $file(@allBinFiles){
    next if ( (! -e $file) || (-x $file) || ($file =~/\.tar$/) );
    &systemMy("chmod +x $file","$fhoutLog");}

				# ------------------------------
				# change mode of all perl files
&printm("--- $scriptName \t chmod of all perl files\n","$fhoutLog","STDOUT");
foreach $file(@allTxtFiles){
    next if ( (! -e $file) || ($file !~/\.pl$/) );
    &systemMy("chmod +x $file","$fhoutLog");}
				# --------------------------------------------------
				# handle dot files
&printm("--- -------------------------------------------------------\n","$fhoutLog","STDOUT");
&printm("--- $scriptName \t \n","$fhoutLog","STDOUT");
&printm("--- -------------------------------------------------------\n","$fhoutLog","STDOUT");
# check whether or not the dot files have been changed at this stage
@dot=(".cshrc",".bashrc",".alias",".login",".logout",
      );

$dir=$dirSaveDot;$dir=~s/\/$//g;
&systemMy("mkdir $dir","$fhoutLog");

foreach $dot (@dot){
    $fileDef=   $par{"dirNewHome"}.$dot;
    $dirOldHome=$par{"dirOldHome"};
    $dirOldDot= $par{"dirOldDot"};$dirOldDot=~s/$dirOldHome//g;
    $fileOld=$dirOldDot .$dot;
    next if (! -e $fileOld);	# if none there forget it
    if (! -e $fileDef){		# move to current home if none there
	$cmd="\\mv $fileOld $dirNewHome";
	&systemMy("$cmd","$fhoutLog"); 
	next;}
				# else make backup
    $cmd="\\cp $fileDef $dirSaveDot"; # make backup of dot files
    &systemMy("$cmd","$fhoutLog"); 
				# ------------------------------
				# read default file
    $Lok=&open_file("$fhin","$fileDef");
    if (! $Lok){print "*** reading default dot file $fileDef (from $dot) failed\n";
		close($fhin);
		next;}
    $#contentOriginal=0;
    while (<$fhin>) {$_=~s/\n//g;
		     next if (length($_)==0);
		     push(@contentOriginal,$_);}close($fhin);
				# ------------------------------
				# read old file
    $Lok=&open_file("$fhin","$fileOld");
    if (! $Lok){print "*** reading old dot file $fileOld (from $dot) failed\n";
		close($fhin);}
    else {$#contentOld=0;
	  while (<$fhin>) {$_=~s/\n//g;
			   next if (length($_)==0);
			   push(@contentOld,$_);}close($fhin);}
				# ------------------------------
    $Ldiff=0;			# difference in files?
    if ($#contentOld == $#contentNew){
	foreach $it (1..$#contentOriginal){
	    if ($contentOriginal[$it] ne $contentOld[$it]){
		$Ldiff=1;
		last;}}}
    else {$Ldiff=1;}
				# ------------------------------
				# write new file
    if ($Ldiff){
	$#tmp=0;undef %tmp;	# find unique lines
	foreach $tmp (@contentOriginal,@contentOld){
	    if (! defined $tmp{"$tmp"}){
		$tmp{"$tmp"}=1;
		push(@tmp,$tmp);}}
	$Lok=&open_file("$fhout",">$dot");
	if (! $Lok){
	    print "*** opening (writing) new  dot file '$dot' failed\n";}
	else {
	    foreach $txt (@tmp){
		print $fhout "$txt\n";}
	    close($fhout);}
				# move new file to home directory
	if ($pwd ne $dirNewHome){
	    $cmd="\\mv $dot $dirNewHome";
	    &systemMy("$cmd","$fhoutLog"); }}
}

#-------------------------------------------------------------------------------
# work done, go home
#-------------------------------------------------------------------------------
&myprt_txt("logfile      \t $fileLog ");

print "--- is everything ok at your new home??\n";
print "---    certainly you would have to move all directories from the working one...\n";
print "---    but then?  good luck chap!\n";
 
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
    if (!defined $PWD) {
        $PWD=&get_in_keyboard("PWD"," undefined (no slash in end)");}

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
		    next if ($kwd =~/Old/);
		    if    (! defined $par{"$kwd"}){$tmp="!! UNDEF !!";}
		    elsif (length($par{"$kwd"})<2){
			next;}
		    else                          {$tmp=$par{"$kwd"};}
		    $kwdOld=$kwd;$kwdOld=~s/New/Old/;$tmpOld=$par{"$kwdOld"};
		    printf "--- %-20s '%-s'\n",$kwd,$tmp;
		    printf "--- %-20s '%-s'\n","   old",$tmpOld;
		}&myprt_line;}

    # ------------------------------------------------------------
    # check existence of file
    # ------------------------------------------------------------
    $Lmiss=0;
    foreach $kwd(@kwdDef){
	next if (! defined $par{"$kwd"});
	next if (length($par{"$kwd"})<2);
	if    ($kwd =~/^fileIn/){
	    if ((! -e $par{"$kwd"})&&(! -l $par{"$kwd"})){
		printf "*** %-20s '%-s'\n","MISSING $kwd",$par{"$kwd"};$Lmiss=1;}}
	elsif ($kwd =~/^exe/){
	    if ((! -e $par{"$kwd"})&&(! -x $par{"$kwd"})){
		printf "*** %-20s '%-s'\n","MISSING $kwd",$par{"$kwd"};$Lmiss=1;}}}
    if ($Lmiss){
	print "*** try to locate the missing files/executables before continuing!\n";
	print "*** left script '$scriptName' after ini\n";
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
	&myprt_empty; print"-" x 80,"\n";die;}
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
    $par{"userNameOld"}=	"rost";
    $par{"perlPathOld"}=	"/usr/pub/bin/perl";

				# --------------------
				# directories
				# --------------------
    $par{"dirOldHome"}=         "/home/rost/";
    $par{"dirOldPerl"}=         $par{"dirOldHome"}."perl/";
    $par{"dirOldEtc"}=          $par{"dirOldHome"}."etc/";
    $par{"dirOldDiv"}=          $par{"dirOldHome"}."div/";
    $par{"dirOldBin"}=          $par{"dirOldHome"}."bin/";
    $par{"dirOldDot"}=          $par{"dirOldHome"}."dot/";
    $par{"dirOldPort"}=         $par{"dirOldHome"}."port/";
    $par{"dirOldEmacs"}=        $par{"dirOldHome"}."emacs/";
    $par{"dirOldMail"}=         $par{"dirOldHome"}."mail/";
    $par{"dirOldPub"}=          $par{"dirOldHome"}."pub/";
#
    $par{"dirOldFssp"}=         "/data/fssp/";
    $par{"dirOldHssp"}=         "/data/hssp/";
    $par{"dirOldDssp"}=         "/data/dssp/";
    $par{"dirOldSwiss"}=        "/data/swissprot/current/";
    $par{"dirOldPdb"}=          "/data/pdb/";
				# files
    $par{"fileBup"}=            "rost.tar";
    $par{"fileLog"}=            "LOG-port-getHome".$$.".tmp"; # xx
    $par{"fileLog"}=            "LOG-port-getHome.tmp";
#    $par{"fileOut"}=            "OUT-port-getHome".$$.".tmp";

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
    $par{"verbose"}=            $Lverb;
				# --------------------
				# executables
    $par{"exeGunzip"}=          "/usr/pub/bin/gunzip";
    $par{"exe"}=                "";
				# ------------------------------
				# a.a descriptors 
				# allowed in default file
				# ------------------------------
    @kwdDef=     ("verbose",
		  "userNameNew","perlPathNew","dirNewHome",
		  "dirNewPerl","dirNewEtc","dirNewBin","dirNewDot","dirNewPub",
#xx		  "dirNewPort","dirNewEmacs","dirNewMail","dirNewDiv",
#xx		  "dirNewFssp","dirNewHssp","dirNewDssp","dirNewSwiss","dirNewPdb",
		  "userNameOld","perlPathOld","dirOldHome",
		  "dirOldPerl","dirOldEtc","dirOldBin","dirOldDot","dirOldPub",
#xx		  "dirOldPort","dirOldEmacs","dirOldMail","dirOldDiv",
#xx		  "dirOldFssp","dirOldHssp","dirOldDssp","dirOldSwiss","dirOldPdb",
		  "exeGunzip","exe",
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
				# default file given on command line?
    if (($#ARGV>1)&&(-e $ARGV[2])&&($ARGV[2]=~/default/)){
	$fileDefaults=$ARGV[2];}
    else {
	foreach $_(@ARGV){
	    if    (/^verb/)    {$Lverb=1;}
	    elsif (/^fileDefaults=(.+)$/){
		$fileDefaults=$1;$fileDefaults=~s/\s//g;
		if (! -e "$fileDefaults") {
		    print "*** ERROR iniRdDefManager: you gave default file by '$_'\n";
		    print "***                        but '$fileDefaults' not existing!\n";
		    return(0);}
		$Lok=1;
		last;}}}
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
	return(0);}
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
	next if ((length($_)<3)||($_=~/^\s*\#/)); # ignore lines beginning with '#'
	next if (!/\w/);
	@tmp=split(/[ \t]+/);
	next if ($#tmp<2);	# must find 2 arguments
	foreach $tmp (@tmp) { 
	    $tmp=~s/[ \n]*$//g; } # purge end blanks
	next if (defined $defaults{"$tmp[2]"});
	$kwdRdDef.="$tmp[1]"."," ; 
	if ($tmp[1]=~/^dir/){	# add '/' at end of directories
	    $tmp[2]=&complete_dir($tmp[2]);} # external lib-ut.pl
	$defaults{"$tmp[1]"}=$tmp[2]; 
	if ($Lverb){printf "--- read: %-22s (%s)\n",$tmp[1],$tmp[2];}}
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
	$kwdOld=$kwd;$kwdOld=~s/New/Old/g;
	if ($kwd=~/^exe/){	# executable
	    if (((defined $par{"$kwd"})&&(length($par{"$kwd"})>=1)&&(! -x $par{"$kwd"}))||
		(!defined $par{"$kwd"})){
		$Lask=1;}
	    else{$Lask=0;}}
	else {			# directory/file
	    if (defined($par{"$kwd"})){	# dont bother to ask again, when defined
		$Lask=0;}
	    else {
		$Lask=1;}}
	next if (!$Lask);
	if (defined $par{"$kwdOld"}){ # fill in the one for the old settings?
	    $def=$par{"$kwdOld"};}
	else{$def="undefined";}
	$tmp=
	    &get_in_keyboard($kwd,$def);
	$Lok=$LisOther=$LisExe=0;
	if    (defined $tmp && (length($tmp)>0)){
				# add home directory (if lazy and fill in only relative path)
	    if (($kwd=~/^dir|^perlPath/)&&($tmp !~/^\//)){
		if (($kwd=~/dir.*Perl|dir.*Etc|dir.*Emacs|dir.*Div|dir.*Bin/)||
                    ($kwd=~/dir.*Dot|dir.*Port|dir.*Mail|dir.*Pub/)){
		    $tmp=$par{"dirNewHome"}.$tmp; 
		    $par{"$kwd"}=&complete_dir($tmp);
		    $Lok=1;$LisOther=0;}
		else {print "*** $sbrName: give entire path for keyword '$kwd'\n";
		      $Lok=0;$LisOther=1;}}
	    else {		# query appears ok
		$par{"$kwd"}=$tmp;$Lok=1;}}
	if ($Lok && ($kwd=~/^exe/)){ # for executables check whether executable
	    $LisExe=1;
	    if (! -x $par{"$kwd"}){$Lok=0;}}
	if (!$Lok){$ct=0;$tmpPrev=$tmp;$tmp="";
		   while (length($tmp)<1){
		       ++$ct;
		       if ($ct>5){print "*** EEJITT: type something reasonable!!\n";
				  die;}
		       if ($kwd =~/^exe/){
			   print "--- is $tmpPrev executable? try ROUND $ct\n";}
		       else {
			   print "--- $tmpPrev contains full path? try ROUND $ct\n";}
		       $tmp=&get_in_keyboard($kwd,$def);
		       if (($LisOther && ($tmp !~ /^\//))||
			   ($LisExe && (! -x $tmp))){
			   $tmpPrev=$tmp;$tmp="";}}
		   $par{"$kwd"}=$tmp;$Lok=1;}}
    return($Lok);
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
	if    ($arg=~/^verb/){$Lverb=1;}
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
	next if ((! defined $par{"$kwd"})||(length($par{"$kwd"})<1));
	if (($kwd=~/^exe/)&&(defined $par{"$kwd"})
	    &&(! -e $par{"$kwd"})&&(! -l $par{"$kwd"})){
	    $par{"$kwd"}=$par{"dirPerl"}.$par{"$kwd"};}}
    return(1);
}				# end of iniChangePar

#==========================================================================
sub complete_dir { local($dir)=@_; $[=1 ; 
		   if (! defined $dir){
		       return;}
		   $dir=~s/\s|\n//g; 
		   if ( (length($dir)>1)&&($dir!~/\/$/) ) {$dir.="/";} 
		   $DIR=$dir;
		   return $DIR; }
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
#==========================================================================================
sub fileLsAllBin {
    local($dirLoc) = @_ ;local($sbrName,$fhinLoc,@tmp);
#--------------------------------------------------------------------------------
#   fileLsAllTxt                will return all binary files in dirLoc (and
#                               subdirectories therof)
#       in:                     dirLoc (directory)
#       out:                    @files
#--------------------------------------------------------------------------------
    $sbrName="fileLsAllTxt";$fhinLoc="FHIN"."$sbrName";
    if (! -d $dirLoc){		# directory empty
	return(0);}
    open($fhinLoc,"find $dirLoc -print |");
    while (<$fhinLoc>){$line=$_; $line=~s/\s//g;
		       if (-B $line && ($line!~/\~$/)){
				# avoid reading subdirectories
			   $tmp=$line;$tmp=~s/$dirLoc//g;$tmp=~s/^\///g;
			   next if ($tmp=~/\//);
			   push(@tmp,$line);}}close($fhinLoc);
    return(@tmp);
}				# end of fileLsAllTxt
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
#==========================================================================================
sub get_in_keyboard {local($des,$def)=@_;local($txt);
		     $txt="";
		     print ">>> type value for '$des' (return to enter value):\n";
		     if (defined $def){
			 print "--- $def (current default)\n";}
		     while(<STDIN>){$txt.=$_;
				    last if (/\n/);} $txt=~s/^\s+|\s+$//g;
		     if (length($txt)<1){$txt=$def;}
		     print "--- echo '$des' set to '$txt'\n";
		     return ($txt);
		 }		# end of get_in_keyboard

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
    $sbrName="systemMy";
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
sub portAdopt {
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   portAdopt                   changes keywords in all local files
#-------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";}
    $sbrName="$tmp"."portAdopt";$fhinLoc="FHIN"."$sbrName";
				# ------------------------------
				# all text files
    $fileNew=$$."x.tmp";
    foreach $file (@allTxtFiles){
	if ($file =~/\.tar/){	# exclude tar files
	    next;}
	if ($file =~/^$dirSave/){ # exclude save files
	    next;}
	print "--- $sbrName: now check \t '$file'\n";

	&open_file("$fhin","$file");
        &open_file("$fhout",">$fileNew");$Ldiff=0;

	while(<$fhin>){$line=$_;
		       foreach $it (1..$#old){
			   if ($line=~ /$old[$it]/){
			       $line=~s/$old[$it]/$new[$it]/g;$Ldiff=1;}}
		       print $fhout $line;}close($fhin);close($fhout);
				# ------------------------------
	if ($Ldiff){		# if differ move new file to old
	    $fileTmp=$file;$fileTmp=~s/^.*\///g;
	    $fileSave=$dirSave."/".$fileTmp; 
	    $cmd1="\\cp $file $fileSave";
	    $cmd2="\\mv $fileNew $file";
	    foreach $cmd ($cmd1,$cmd2){
		&systemMy("$cmd","$fhoutLog")} }
        else{$cmd="\\rm $fileNew";
             system("$cmd");}
    }	
    if (-e $fileNew){
	&systemMy("\\rm $fileNew","$fhoutLog");}
}				# end of portAdopt

