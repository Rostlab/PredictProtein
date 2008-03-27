#!/usr/bin/perl -w

#!bin/env perl
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="\n";
#!/usr/sbin/perl -w
##!/bin/env perl
##!/usr/bin/perl
##!/usr/pub/bin/perl -w
#-------------------------------------------------------------------------------
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$scrName=$0; $scrName=~s/^.*\/|\.pl//g;
$scrGoal=    "installs programs (now: PHD)";
$scrIn=      "do|auto|file.tar";
$scrNarg=    1;                  # minimal number of input arguments
$scrHelpTxt= " \n";
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# comments
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# 
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# text markers
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#  - 'xx'         : to do, error break
#  - 'yy'         : to do at later stage
#  - 'HARD_CODED' : explicit names
#  - 'br date'    : changed on date
#  - 'hack'       : some hack 
#  - 
#  
#  
#  - $par{"kwd"}  : global parameters, available on command line by 'kwd=value'
# 
#------------------------------------------------------------------------------#
#	Copyright				        	1998	       #
#	Burkhard Rost		rost@EMBL-Heidelberg.DE			       #
#	Wilckensstr. 15		http://www.embl-heidelberg.de/~rost/	       #
#	D-69120 Heidelberg						       #
#				version 0.1   	May,    	1998	       #
#------------------------------------------------------------------------------#
$[ =1 ;				# sets array count to start at 1, not at 0
				# ------------------------------
				# initialise variables
#@ARGV=split(/\s+/,&get_in_keyboard("command line"));	# x.x mac specific

				# ------------------------------
($Lok,$msg)=			# initialise variables
    &ini;			# 
if (! $Lok) { print "*** ERROR $scrName after ini\n",$msg,"\n";
	      die '*** during initialising $scrName   ';}

#-------------------------------------------------------------------------------
# do the job (here we go)
#-------------------------------------------------------------------------------

				# ------------------------------
				# find perl
				# ------------------------------
$Lok=0;
foreach $perl ("/usr/bin/perl",
	       "/usr/pub/bin/perl",
	       "/usr/sbin/perl"){
    $Lok=1 if (-e $perl && (-l $perl || -x $perl));
    next if (! $Lok);
    $perlPath=$perl;
    $perlPath.="/"              if ($perlPath !~ /\/$/); 
    last if ($Lok); }

if (! $Lok){ 
    ($Lok,$perl)=
	&queryExe("give your perl executable + path","/usr/bin/perl",$scrPrompt); 
    $perlPath=$perl; 
    $perlPath.="/"              if ($perlPath !~/\/$/); }

if (! $Lok){ 
    print "*** installing of $prog not possible without a local version of PERL\n";
    print "*** -> either: find your local version\n";
    print "*** -> or:     let your system manager find it for you!\n";
    die; }
print "--- \n";
				# ------------------------------
				# where to install
				# ------------------------------
$pwd=$ENV{'PWD'} || `pwd`;
$pwd.="/"                       if (defined $pwd && $pwd !~ /\/$/); 
$pwd=""                         if (! defined $pwd);

print "--- --------------------------------------------------------------------\n";
print "--- $prog is installed by default into the local directory, i.e. the one\n";

print "---     in which you run this script ($pwd).\n";
($Lok,$dir)=
    &queryDir($pwd,"install directory (FULL path!)",$scrPrompt);

$dir.="/"                       if ($dir !~/\/$/); 


if (! $Lok){ 
    print "-*- WARN interaction failed -> will be unpacked into local dir\n";
    $dir="";}
else       { 
    print "--- \n";
    print "--- $fileIn will be unpacked into '$dir'\n"; }
print "--- \n";

$dirInstall=$dir;
				# ------------------------------
				# now to install dir
				# ------------------------------
if (length($dirInstall)>=1){
    system("\\cp $fileIn $dirInstall");
    $dir=$dirInstall; $dir.="/" if ($dir!~/\/$/);
    $fileIn=~s/^.*\///g; 
    $fileIn=$dir.$fileIn;
    $Lok=1                      if (-e $fileIn);
    if (! $Lok) { print "-*- WARN File ($prog.tar) was expected in dirInstall=$dirInstall.\n";
		  print "-*-      However, that action failed. \n";
		  print "-*-      Thus, installing continues in the local dir $pwd.\n"; }
    else {
	$Lok=chdir($dirInstall); }
    if (! $Lok) { print "-*- WARN Failed to change directory to $dirInstall.\n";
		  print "-*-      Thus, installing continues in the local dir $pwd.\n";
		  $dirInstall=$pwd; }
}
				# ------------------------------
				# untar
				# ------------------------------
$cmd=$par{"cmdTar"};
if (! -l $cmd && ! -x $cmd) {
    print "*** ERROR tar not found (give cmdTar=YOUR_LOCAL_TAR on the command line)\n";
    die; }
$fileIn=~s/^.*\///g;		# remove path from input file (should be local after chdir)

$cmd=$par{"cmdUntar"}." $fileIn";
print "--- now untar \t $cmd\n";

`tar -xvf  $fileIn`;		# untar system call

print "--- \n";
print "--- --------------------------------------------------------------------\n";
print "--- \n";
print "--- $scrName about to change the files that have now been unpacked\n";
print "--- \n";
				# ------------------------------
				# change all perl scripts
				# ------------------------------
$dirProg=$dirInstall; 
$dirProg.="/"                   if ($dirProg !~/\/$/);
$dirProg.=$prog;
@fileList=&fileLsAll($dirProg);

print "--- All perl scripts will be changed now.\n";

foreach $file (@fileList) { 
    next if ($file !~ /\.p[lm]$/);
    $Lok= &open_file("$fhin","$file");
    next if (! $Lok);
    $fileNew="TMP-INSTALL".$$.".tmp";
    $Lok= &open_file("$fhout",">$fileNew"); 
    next if (! $Lok);
    print "--- changing perl path to $perlPath for file=$file\n";

    print $fhout "#!".$perlPath."\n";
    print $fhout "#".<$fhin>;
    while (<$fhin>) {
	print $fhout $_;} close($fhin); close($fhout);
				# 
    if ($fileNew ne $file){
	print "--- system \t '\\mv $fileNew $file'\n";
	`\\mv $fileNew $file`; }
    if (-e $file){
	`chmod +x $file`; }	# change mode
}

print "--- \n";
print "--- done with the perl\n";
print "--- \n";
				# ------------------------------
				# change all names
				# ------------------------------
print "--- All paths will be updated now.\n";
print "--- \n";

if (length($dirInstall)<1) {
    print "--- *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-\n";
    print "-*- \n";
    print "-*- SORRY We have a problem, here...\n";
    print "-*-       Firstly, you never typed the install directory.   Fair enough.\n";
    print "-*-       Secondly, your machine does not know 'pwd'.               Bad!\n";
    print "-*-       -> In tandem these two problems result in that you will not be\n";
    print "-*-          able to run $prog straight away.\n";
    print "-*-          Nothing you can do at the moment.  Sorry, for interrupting.\n";
    print "-*- \n";
    print "--- *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-\n";
    $dirInstall="XXX_CHANGE_THIS/"; }

print "--- \n";

$dirProg=$dirInstall; 
$dirProg.="/"                   if ($dirProg !~/\/$/);
$dirProg.=$prog;
				# GLOBAL in: @old,@new
				#            $old[it] -> $new[it]
$#old=$#new=0;
$dirScr=$dirProg."scr/";
if (-d $dirScr){ push(@old,"/home/rost/perl/scr/");
		 push(@new,$dirScr);}
push(@old, ("/home/rost/perl/","/home/rost/pub/phd/",$par{"dirHomeOld"},"home/rost/"));
push(@new, ($dirProg,          $dirInstall,          $dirInstall,       $dirInstall);

&portAdopt(@fileList);

print "--- \n";
				# ------------------------------
				# make executable (chmod)
				# ------------------------------
foreach $file (@fileList){
    next if ($file !~ /\.p[lm]$/ && 
	     $file !~ /\.c?sh$/  &&
	     $file !~ /\.[SGI|ALPHA|SUN][A-Z0-9]*$/);
    `chmod +x $file`; }

				# ------------------------------
				# final
				# ------------------------------
print "--- \n";
print "--- --------------------------------------------------------------------\n";
print "--- \n";
$Lok=$exeProg=$doRunProg=0;
if ($dirInstall !~ /XXX_CHANGE_THIS/){
    $Lok=1;
    $dirProg.="/"               if ($dirProg !~/\/$/);
    $exeProg=$dirProg."$prog".".pl";
    if ($exeProg && ! -l $exeProg && ! -x $exeProg){
	system("chmod +x $exeProg"); } }

if    (! $Lok) { 
    $tmp="";
    $tmp.= "--- The installation was  not as successful, as anticipated, but it will\n"; 
    $tmp.= "---    be coming to its end, anyway\n";
    $tmp.= "--- What remains to be done for you:\n";
    $tmp.= "---    (1) locate the new directory $prog\n";
    $tmp.= "---      - change in all file '$dirInstall' to the  directory  where you\n";
    $tmp.= "---        will eventually move all the stuff in the $prog directory to.\n";
    $tmp.= "---      - you may have to change in all perl files the perl path\n";
    $tmp.= "---    (2) you may have to do the following for all executables:\n";
    $tmp.= "---        chmod + x\n";
    $tmp.= "---      - executables may be in the directories  \n";
    $tmp.= "---        $prog/bin\n";
    $tmp.= "---        $prog/scr\n";
    $tmp.= "---    (3) finally, locate the file $prog.pl\n";
    $tmp.= "---        \n";
    $tmp.= "---  ... and run it by:\n";
    $tmp.= "---        \n";
    $tmp.= "---        $prog.pl\n";
    $tmp.= "--- \n";
    $tmp.= "--- Hopefully, that will be IT ...\n";
    $tmp.= "--- \n"; 
    print $tmp; 

    $fileNew="ERROR-INSTALL".$$.".tmp";
    print "--- note: the last message will also be written into the file $fileNew\n";

    $Lok= &open_file("$fhout",">$fileNew"); 
    print $tmp; 
    close($fhout);  }
elsif (! $exeProg){
    $tmp="";
    $tmp.= "--- --------------------------------------------------------------------\n";
    $tmp.= "--- The installation was  not entirely successful...             Sorry. \n"; 
    $tmp.= "--- Here is, what remains to be done for you:\n";
    $tmp.= "---    (1) locate the new directory $dirProg\n";
    $tmp.= "---    (2) you may have to do the following for all executables:\n";
    $tmp.= "---        chmod + x\n";
    $tmp.= "---      - executables may be in the directories  \n";
    $tmp.= "---        $dirProg"."bin\n";
    $tmp.= "---        $dirProg"."scr\n";
    $tmp.= "---    (3) finally, locate the file $dirProg"."$prog.pl\n";
    $tmp.= "---        \n";
    $tmp.= "---  ... and run it by:\n";
    $tmp.= "---        \n";
    $tmp.= "---        $dirProg"."$prog.pl\n";
    $tmp.= "--- \n";
    $tmp.= "--- Hopefully, that will be IT ...\n";
    $tmp.= "--- \n"; 
    print $tmp; 

    $fileNew="ERROR-INSTALL".$$.".tmp";
    print "--- note: the last message will also be written into the file $fileNew\n";

    $Lok= &open_file("$fhout",">$fileNew"); 
    print $tmp; 
    close($fhout);  }
else {
    print "--- \n";
    print "--- --------------------------------------------------------------------\n";
    print "--- Seems the installation is coming to a happy end ...\n"; 
    print "--- \n";
    $alias="$prog $exeProg";
    $Lok=0;
    if (defined $ENV{"HOME"}) {
	$dir=  $ENV{"HOME"}; $dir.="/" if ($dir !~/\/$/);
	$cshrc=$dir.".cshrc";
	if (! -e $cshrc){
	    $cshrc="~/.cshrc"; }
	if (-e $cshrc) {
	    print "--- do you want to automatically put the alias '$alias' to\n";
	    print "---      your .cshrc file ($cshrc) ?\n";
	    $an=
		&get_in_keyboard("put alias? (yes or no [y|n]))","yes",$scrPrompt); 
	    if ($an =~ /^y/){
		$cmd="echo '$alias' >> $cshrc";
		print "xx cmd=$cmd\n";
		`$cmd`;
		$Lok=1;}}}
    if (! $Lok){
	print "--- you may add the alias '$alias' to your local .cshrc file\n";
	print "--- \n";}
    else {
#	`source $cshrc`; 
	print "--- before the alias will be active you may have to re-login\n";
	print "--- may be not, just try it out ...\n"; }
    print "--- \n";
    print "--- you may now be able to run $prog by typing\n";
    print "--- \n";
    print "$exeProg\n";
    print "--- \n";
    print "--- GOOD luck!!\n";
    print "--- \n";

    print "--- want me to try it for you?\n";
    $an=
	&get_in_keyboard("start $prog? (yes or no [y|n]))","yes",$scrPrompt); 
    if ($an =~ /^y/){
	$doRunProg=$exeProg;}
}

#-------------------------------------------------------------------------------
# work done, go home
#-------------------------------------------------------------------------------
                                # ------------------------------
                                # deleting intermediate files
&cleanUp() if (! $par{"debug"}); 
                                # ------------------------------
                                # final words
if ($Lverb) { 
    print "--- $scrName ended fine .. -:\)\n";
                                # ------------------------------
    $timeEnd=time;		# runtime , run time
    $timeRun=$timeEnd-$timeBeg;
    print 
	"--- date     \t \t $Date \n",
	"--- run time \t \t ",&fctSeconds2time($timeRun)," (hour:min:sec)\n";
}

if ($doRunProg){
    print "--- ------------------------------------------------------------\n";
    print "--- now execute $prog by: \n".$doRunProg."\n";
    print "--- \n";
    print "--- the following ( after the vvvvv line) will be from $prog:\n";
    print "--- \n";
    print "||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||\n";
    print "vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv\n";

    system("$doRunProg"); }

exit;

#===============================================================================
sub ini {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   initialises variables/arguments
#-------------------------------------------------------------------------------
    $sbrName="$scrName".":ini";
    $par{"dirPerl"}=            "/home/rost/perl/"; # directory for perl scripts needed
    $dir=0;			# ------------------------------
    foreach $arg(@ARGV){	# highest priority arguments
	next if ($arg !~/=/);
	if    ($arg=~/dirLib=(.*)$/){$dir=$1;}
	elsif ($arg=~/ARCH=(.*)$/)  {$ARCH=$1;}
	elsif ($arg=~/PWD=(.*)$/)   {$PWD=$1;}}
    $ARCH=$ENV{'ARCH'}      if (! defined $ARCH && defined $ENV{'ARCH'});
    $PWD= $ENV{'PWD'}       if (! defined $PWD  && defined $ENV{'PWD'}); 
    $PWD=~s/\/$//           if ($PWD=~/\/$/);
    $pwd= $PWD              if (defined $PWD);
    $pwd.="/"               if (defined $pwd && $pwd !~ /\/$/);
    $dir=$dir || "/home/rost/perl/" || $ENV{'PERLLIB'} || 
	$par{"dirPerlLib"} || $par{"dirPerlLib"} || $par{"dirPerl"};
    $dir.="/" if (-d $dir && $dir !~/\/$/);
    $dir= ""  if (! defined $dir || ! -d $dir);

				# ------------------------------
    $timeBeg=     time;		# date and time
    $Date=        &sysDate;
				# ------------------------------
				# first settings for parameters 
    &iniDef;			# NOTE: may be overwritten by comand line

				# ------------------------------
				# HELP stuff

				# standard help
    $tmp=$0; $tmp=~s/^\.\///    if ($tmp=~/^\.\//);
    %tmp=('sourceFile', $tmp, 'scrName',$scrName, 'scrIn',$scrIn, 'scrGoal', $scrGoal, 
	  'scrNarg',$scrNarg, 'scrHelpTxt', $scrHelpTxt);
				# special help

    ($Lok,$msg)=		# want help?
	&brIniHelp(%tmp);       return(&errSbrMsg("after lib:brIniHelp".$msg)) if (! $Lok);
    if ($msg eq "fin") {
	print "--- Suggest to type:\n";
	die $scrName.'.pl phd.tar          '; 
    }
				# ------------------------------
				# read command line input
    @argUnk=			# standard command line handler
	&brIniGetArg;
    foreach $arg (@argUnk){     # interpret specific command line arguments
        if    ($arg=~/^list$/i)               { $par{"isList"}=1;}
	elsif ($arg=~/^nice-(\d+)$/)          { $par{"optNice"}="nice -".$1;}
	elsif ($arg=~/^(do|auto)$/)           { $par{"isInteractive"}=1;}
	elsif ($arg eq "nonice")              { $par{"optNice"}=" ";}
	elsif ($arg eq "debug")               { $par{"debug"}=1;}
	else  {
	    return(0,"*** ERROR $sbrName: kwd '$arg' not understood\n");}}
    print "-*- WARNING iniGetArg: command line arguments overwrite '".$par{"fileDefaults"}."\n" 
	if ($par{"verbose"} && defined %defaults && %defaults);
        
                                # --------------------------------------------------
                                # digest input file formats
                                # --------------------------------------------------
    if ($#fileIn>0){
	$fileIn=$fileIn[1];}
    else {
	$fileIn="phd.tar";}
				# find the package to install
    if ($par{"isInteractive"}){
	($Lok,$fileIn)=
	    &queryFile($fileIn,"name of program.tar to install",$scrPrompt);
	die "$fileIn\n".'*** please locate the tar file of the package imported (e.g. phd.tar)' 
	    if (! $Lok); }
    else {
	print "--- $scrName: assumed you want to install $fileIn\n";}
    $prog=$fileIn; $prog=~s/^.*\/|\.tar//g;
				# ------------------------------
				# final settings
    $Lok=			# standard settings
	&brIniSet;              return(&errSbr("after lib:brIniSet\n")) if (! $Lok);
    return(0,"*** ERROR $sbrName: no input file given!!\n") if ($#fileIn==0);

    $par{"cmdUntar"}=           $par{"cmdTar"}." -xvf";


				# ------------------------------
				# check errors
    $exclude="exe,fileDefaults"; # to exclude from error check
    ($Lok,$msg)=
        &brIniErr($exclude);    return(&errSbrMsg("after lib:brIniErr\n".$msg)) if (! $Lok);  
				# ------------------------------
				# write settings
    if ($par{"verb2"}){
	($Lok,$msg)=
	    &brIniWrt;		return(&errSbrMsg("after lib:brIniWrt\n".$msg)) if (! $Lok); }

				# ------------------------------
                                # trace file
    if (defined $par{"fileOutTrace"} && $par{"fileOutTrace"} ne "unk" && 
	length($par{"fileOutTrace"})>0 &&
	! $par{"debug"}){
        print "--- \t open $fhTrace for trace file ",$par{"fileOutTrace"}," \n" if ($Lverb2);
        &open_file("$fhTrace",">".$par{"fileOutTrace"}) || 
            return(&errSbr("failed to open new file for trace : ".$par{"fileOutTrace"}));}
    else { $fhTrace="STDOUT";
	   $par{"fileOutScreen"}=0;}

                                # ------------------------------
    undef %tmp;			# clean memory

    return(1,"ok $sbrName");
}				# end of ini

#===============================================================================
sub iniDef {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iniDef                      initialise defaults
#-------------------------------------------------------------------------------
                                # d.d
                                # ------------------------------
                                # default file
#    $par{"fileDefaults"}=       "/home/rost/nn/src/nn.defaults";
#    $par{"fileDefaults"}=       ""; # file with defaults
				# --------------------
				# directories
    $par{"dirHome"}=            "/home/rost/";     # expected
    $par{"dirHomeOld"}=         "/home/rost/pub/"; # expected root to replace by 'dirInstall'
    
    $par{"dirPerl"}=            $par{"dirHome"}. "perl/" # perl libraries
        if (! defined $par{"dirPerl"});
    $par{"dirPerlScr"}=         $par{"dirPerl"}. "scr/"; # perl scripts needed
    $par{"dirBin"}=             "/home/rost/pub/phd/bin/"; # FORTRAN binaries of programs needed

    $par{"dirOut"}=            ""; # directory for output files
    $par{"dirWork"}=           ""; # working directory
#    $par{""}=                   "";
                                # further on work
				# --------------------
				# files
    $par{"title"}=              "unk";                           # output files may be called 'Pre-title.ext'
    $par{"titleTmp"}=           "TMP-INSTALL-";                    # title for temporary files

    $par{"fileOut"}=            "unk";
    $par{"fileOutTrace"}=       "INSTALL-TRACE"."jobid".".tmp"; # file tracing some warnings and errors
    $par{"fileHelpMan"}=        "unk"; # file with manual
    $par{"fileHelpOpt"}=        "unk"; # file with options
    $par{"fileHelpHints"}=      "unk"; # file with hints, note: also passed as par{scrHelpHints}
    $par{"fileHelpProblems"}=   "unk"; # file with known problems, also passed as par{scrHelpProblems}
#    $par{""}=                   "";
				# file extensions
    $par{"preOut"}=             "Out-";
    $par{"extOut"}=             ".tmp";
				# file handles
    $fhout=                     "FHOUT";
    $fhin=                      "FHIN";
    $fhTrace=                   "FHTRACE";
                                # --------------------
                                # job control
    $par{"jobid"}=              "jobid"; # unique job identifier (set to $$ if not defined)
    $par{"debug"}=              0; # if 1 : keep (most) temporary files
    $par{"verbose"}=$Lverb=     1; # blabla on screen
    $par{"verb2"}=$Lverb2=      0; # more verbose blabla

    $par{"optNice"}=            "nice -15";
#    $par{""}=                   "";
				# --------------------
				# parameters
    $par{"isInteractive"}=      0;
    $par{"cmdTar"}=             "tar";
    $par{"cmdTar"}=             "/sbin/tar"      if (! -l $par{"cmdTar"} && ! -x $par{"cmdTar"});
    $par{"cmdTar"}=             "/bin/tar"       if (! -l $par{"cmdTar"} && ! -x $par{"cmdTar"});
    $par{"cmdTar"}=             "/usr/bin/tar"   if (! -l $par{"cmdTar"} && ! -x $par{"cmdTar"});

#    $par{""}=                   "";
#    $par{""}=                   "";
#    $par{""}=                   "";
				# --------------------
				# executables
#    $par{"exe"}=                "";
#    $par{""}=                   "";

    $scrPrompt=                 "INSTALL";
}				# end of iniDef

#===============================================================================
sub cleanUp {
    local($sbrName,@tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#    cleanUp                    deletes intermediate files
#-------------------------------------------------------------------------------
    if ($scrName){$tmp="$scrName".":";}else{$tmp="";} $sbrName="$tmp"."cleanUp";
    if ($#kwdRm>0){		# remove intermediate files
	foreach $kwd (@kwdRm){
	    next if (! defined $file{"$kwd"} || ! -e $file{"$kwd"});
	    print "--- $sbrName unlink '",$file{"$kwd"},"'\n" if ($Lverb2);
	    unlink($file{"$kwd"});}}
    foreach $kwd ("fileOutTrace","fileOutScreen"){
        next if (! defined $par{"$kwd"} || ! -e $par{"$kwd"});
        print "--- $sbrName unlink '",$par{"$kwd"},"'\n" if ($Lverb2);
        unlink($par{"$kwd"});}
}				# end of cleanUp

#===============================================================================
sub queryDir {
    local($dirInLoc,$desLoc,$promptLoc) = @_ ;
    $[ =1 ;
#-------------------------------------------------------------------------------
#   queryDir                       
#-------------------------------------------------------------------------------
    $dirTmp=
	&get_in_keyboard($desLoc,$dirInLoc,$promptLoc); 
    if (! -d $dirTmp){
	$ct=0;
	while ($ct < 5 && ! -d $dirTmp){
	    print "*** ERROR \n";
	    print "*** ERROR     "."~" x length($dirTmp)."\n";
	    print "*** ERROR dir '$dirTmp' not existing \n";
	    print "*** ERROR     "."~" x length($dirTmp)."\n";
	    print "*** ERROR                             (did you give the full path???)\n";
	    ++$ct;
	    $dirTmp=
		&get_in_keyboard($desLoc,$dirInLoc,$promptLoc); 
	}
	return(&errSbr("no valid dir: found")) if (! -e $dirTmp); }
    return(1,$dirTmp);
}				# end of queryDir

#===============================================================================
sub queryExe {
    local($fileInLoc,$desLoc,$promptLoc) = @_ ;
    $[ =1 ;
#-------------------------------------------------------------------------------
#   queryExe                       
#-------------------------------------------------------------------------------
    $fileTmp=
	&get_in_keyboard($desLoc,$fileInLoc,$promptLoc); 
    if (-e $fileTmp && ! (-l $fileTmp || -x $fileTmp)){
	print "--- executable $fileTmp does exist, but is NOT executable\n";
	system("chmod +x $fileTmp");
	if (! -l $fileTmp && ! -x $fileTmp){
	    print "-*- WARN: the attempt to automatically do 'chmod +x $fileTmp' failed!\n";
	    print "-*-    -> please do it manually before running $prog\n"; }
	return(1,$fileTmp); }

    if (! -e $fileTmp){
	$ct=0;
	while ($ct < 5 && (! -e $fileTmp && ! -l $fileTmp && ! -x $fileTmp)){
	    print "*** ERROR \n";
	    print "*** ERROR      "."~" x length($fileTmp)."\n";
	    print "*** ERROR exe  '$fileTmp' not existing \n";
	    print "*** ERROR      "."~" x length($fileTmp)."\n";
	    print "*** ERROR                             (did you give the full path???)\n";
	    ++$ct;
	    $fileTmp=
		&get_in_keyboard($desLoc,$fileInLoc,$promptLoc); 
	}
	return(&errSbr("no valid file: found")) if (! -e $fileTmp); }
    print "--- executable $fileTmp does exist, but is NOT executable\n";

    system("chmod +x $fileTmp");
    if (! -l $fileTmp && ! -x $fileTmp){
	print "-*- WARN: the attempt to automatically do 'chmod +x $fileTmp' failed!\n";
	print "-*-    -> please do it manually before running $prog\n"; }
    return(1,$fileTmp);
}				# end of queryExe

#===============================================================================
sub queryFile {
    local($fileInLoc,$desLoc,$promptLoc) = @_ ;
    $[ =1 ;
#-------------------------------------------------------------------------------
#   queryFile                       
#-------------------------------------------------------------------------------
    $fileTmp=
	&get_in_keyboard($desLoc,$fileInLoc,$promptLoc); 
    if (! -e $fileTmp){
	$ct=0;
	while ($ct < 5 && ! -e $fileTmp){
	    print "*** ERROR \n";
	    print "*** ERROR      "."~" x length($fileTmp)."\n";
	    print "*** ERROR file '$fileTmp' not existing \n";
	    print "*** ERROR      "."~" x length($fileTmp)."\n";
	    print "*** ERROR                             (did you give the full path???)\n";
	    ++$ct;
	    $fileTmp=
		&get_in_keyboard($desLoc,$fileInLoc,$promptLoc); 
	}
	return(&errSbr("no valid file: found")) if (! -e $fileTmp); }
    return(1,$fileTmp);
}				# end of queryFile


#===============================================================================
sub portAdopt {
    local(@fileTmp)=@_;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   portAdopt                   changes keywords in all local files
#   in GLOBAL:                  @old, @new
#                               $old[it] -> $new[it]
#-------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";}
    $sbrName="$tmp"."portAdopt";$fhinLoc="FHIN"."$sbrName";
				# ------------------------------
				# all text files
    $fileNew="TMP-INSTALL".$$.".tmp";
    foreach $file (@fileTmp){
	next if (! -e $file || -z $file || -l $file || -d $file || -B $file);
	print "--- $sbrName: now check \t '$file'\n";

	&open_file("$fhin","$file");
        &open_file("$fhout",">$fileNew");$Ldiff=0;

	while(<$fhin>){
	    $line=$_;
	    foreach $it (1..$#old){
		if ($line=~ /$old[$it]/){
		    $line=~s/$old[$it]/$new[$it]/g;
		    $Ldiff=1;}}
	    print $fhout $line;}
	close($fhin);close($fhout);
				# ------------------------------
	if ($Ldiff){		# if differ move new file to old
	    $fileTmp=$file;$fileTmp=~s/^.*\///g;
	    print "--- changed $file\n";
	    `\\mv $fileNew $file`; }
        else{ 
	    unlink($fileNew); }
    }	
}				# end of portAdopt

#==============================================================================
# 
# xx yy libraries
# 
#==============================================================================
sub brIniErr {
    local($local)=@_;
    $[ =1 ;
#-------------------------------------------------------------------------------
#   brIniErr                    error check for initial parameters
#       in GLOBAL:              $par{},@ARGV
#       in:                     $exceptions = 'kwd1,kwd2'
#                                  key words not to check for file existence
#       out:                    ($Lok,$msg)
#-------------------------------------------------------------------------------
    $sbrName="$scrName:"."brIniErr";
    @kwd= keys (%par)       if (defined %par && %par);
				# ------------------------------
    undef %tmp; $#excl=0;	# exclude some keyword from check?
    @excl=split(/,/,$local) if (defined $local);
    if ($#excl>0){
	foreach $kwd(@excl){
	    $tmp{"$kwd"}=1;}}
    $msgHere="";
				# ------------------------------
    foreach $kwd (@kwd){	# file existence
	next if ($kwd =~ /^file(Out|Help|Def)/i);
	next if (defined $tmp{"$kwd"});
	if   ($kwd=~/^exe/) { 
	    $msgHere.="*** ERROR executable ($kwd) '".$par{"$kwd"}."' missing!\n"
		if (! -e $par{"$kwd"} && ! -l $par{"$kwd"});
	    $msgHere.="*** ERROR executable ($kwd) '".$par{"$kwd"}."' not executable!\n".
                "***       do the following \t 'chmod +x ".$par{"$kwd"}."'\n"
                    if (! -x $par{"$kwd"});}
	elsif($kwd=~/^file/){
	    next if ($par{"$kwd"} eq "unk" || length($par{"$kwd"})==0 || !$par{"$kwd"});
	    $msgHere.="*** ERROR file ($kwd) '".$par{"$kwd"}."' missing!\n"
		if (! -e $par{"$kwd"} && ! -l $par{"$kwd"});} # 
    }
    return(0,$msgHere) if ($msgHere=~/ERROR/);
    return(1,"ok $sbrName");
}				# end of brIniErr

#==============================================================================
sub brIniGetArg {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   brIniGetArg                 standard reading of command line arguments
#       in GLOBAL:              @ARGV,$defaults{},$par{}
#       out GLOBAL:             $par{},@fileIn
#       out:                    @arg_not_understood (i.e. returns 0 if everything ok!)
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."brIniGetArg";
    $#argUnk=0;                 # ------------------------------
				# (1) get input directory
    foreach $arg(@ARGV){	# search in command line
	if ($arg=~/^dirIn=(.+)$/){$par{"dirIn"}=$1;
				  last;}}
				# search in defaults
    if ((! defined $par{"dirIn"} || ! -d $par{"dirIn"}) && defined %defaults && %defaults){ # 
	if (defined $defaults{"dirIn"}){
	    $par{"dirIn"}=$defaults{"dirIn"};
	    $par{"dirIn"}=$PWD    
		if (defined $PWD && ($par{"dirIn"}=~/^(local|unk)$/ || length($par{"dirIn"})==0));}}
    $par{"dirIn"}.="/" if (defined $par{"dirIn"} && -d $par{"dirIn"} && $par{"dirIn"}!~/\/$/); #  slash
    $par{"dirIn"}=""   if (! defined $par{"dirIn"} || ! -d $par{"dirIn"}); # empty
                                # ------------------------------
    if (defined %par && %par){  # all keywords used in script
        @tmp=sort keys (%par);}
    else{
	$#tmp=0;}

    $Lverb3=0 if (! defined $Lverb3);
    $Lverb2=0 if (! defined $Lverb2);
    $#fileIn=0;                 # ------------------------------
    foreach $arg (@ARGV){	# (2) key word driven input
	if    ($arg=~/^verb\w*3=(\d)/)          {$par{"verb3"}=$Lverb3=$1;}
	elsif ($arg=~/^verb\w*3/)               {$par{"verb3"}=$Lverb3=1;}
	elsif ($arg=~/^verb\w*2=(\d)/)          {$par{"verb2"}=$Lverb2=$1;}
	elsif ($arg=~/^verb\w*2/)               {$par{"verb2"}=$Lverb2=1;}
	elsif ($arg=~/^verbose=(\d)/)           {$par{"verbose"}=$Lverb=$1;}
	elsif ($arg=~/^verbose/)                {$par{"verbose"}=$Lverb=1;}
	elsif ($arg=~/not_?([vV]er|[sS]creen)/) {$par{"verbose"}=$Lverb=0; }
	else  {$Lok=0;		# general
               if (-e $arg){	# is it file?
                   $Lok=1;push(@fileIn,$arg);}
               if (! $Lok && length($par{"dirIn"})>1 && -e $par{"dirIn"}.$arg){
                   $Lok=1;push(@fileIn,$par{"dirIn"}.$arg);}
               if (! $Lok){
                   foreach $kwd (@tmp){
                       if ($arg=~/^$kwd=(.+)$/){$Lok=1;$par{"$kwd"}=$1;
                                                last;}}}
               push(@argUnk,$arg) if (! $Lok);}}
    return(@argUnk);
}				# end of brIniGetArg

#==============================================================================
sub brIniHelp {
    local(%tmp)=@_;
    $[ =1 ;
#-------------------------------------------------------------------------------
#   brIniHelp                   initialise help text
#       out:                    \d,txt
#       err:                    0,$msg  -> error
#       err:                    1,'fin' -> wanted help, given help
#       err:                    1,$msg  -> continue, was just trying
#       in:                     $tmp{} with
#                               $tmp{sourceFile}=  name and path of calling script
#                               $tmp{scrName}=     name of calling script (no .pl)
#                               $tmp{scrIn}=       input arguments for script
#                               $tmp{scrGoal}=     what script does
#                               $tmp{scrNarg}=     number of argument needed for script
#                               $tmp{scrHelpTxt}=  long blabla about script
#                                   separate by '\n'
#                               $tmp{scrAddHelp}=  help option other than standard
#                                   e.g.: "help xyz     : explain .xyz "
#                                   many: '\n' separated
#                                   NOTE: this will be an entry to $tmp{$special},
#                                   -> $special =  'help xyz' will give explanation 
#                                      $tmp{$special}
#                               $tmp{special}=     'kwd1,kwd2,...' special keywords
#                               $tmp{$special}=    explanation for $special
#                                   syntax: print flat lines (or '--- $line'), separate by '\n'
#                               $tmp{scrHelpHints}= hints (tab separated)
#                               $tmp{scrHelpProblems}= known problems (tab separated)
#       in GLOBULAR:            @ARGV
#                               $par{fileHelpOpt}
#                               $par{fileHelpMan}
#                               $par{fileHelpHints}
#                               $par{fileHelpProblems}
#                               $par{fileDefautlts}
#       in unk:                 leave undefined, or give value = 'unk'
#-------------------------------------------------------------------------------
    $sbrName="lib-br:brIniHelp"; 
				# ------------------------------
				# check input
    if (0){
	foreach $kwd ("sourceFile","scrName","scrIn","scrGoal","scrNarg","scrAddHelp","special"){
	    print "--- input to $sbrName kwd=$kwd, val=",$tmp{"$kwd"},",\n";}
    }
    @scrTask=
        ("--- Task:  ".$tmp{"scrGoal"},
         "--- ",
         "--- ==================================================",
         "--- Input: ".$tmp{"scrIn"},
         "--- ==================================================",
         "--- ");
				# ------------------------------
				# additional help keywords?
				# ------------------------------
    $#tmpAdd=0;
    if (defined $tmp{"scrAddHelp"} && $tmp{"scrAddHelp"} ne "unk"){
	@tmp=split(/\n/,$tmp{"scrAddHelp"});$Lerr=0;
	foreach $tmp(@tmp){
	    push(@tmpAdd,$tmp{"scrName"}.".pl ".$tmp);
	    $tmp2=$tmp;$tmp2=~s/^(.+)\s+\:.*$/$1/;$tmp2=~s/\s*$//g;
	    if (!defined $tmp{"$tmp2"}){
		$Lerr=1;
		print "-*- WARN $sbrName: miss \$tmp{\$special}  for '$tmp2'\n";}}
	if ($Lerr){
	    print  
		"-*- " x 20,"\n","-*- WARN $sbrName: HELP on HELP\n",
		"-*-      if you provide special help in tmp{scrAddHelp}, then\n",
		"-*-      provide also the respective explanation in tmp{\$special},\n",
		"-*-      where \$special is e.g. 'help xyz' in \n",
		"-*-      scrAddHelp='help xyz : what to do'\n","-*- " x 20,"\n";}}
				# ------------------------------
				# build up help standard
				# ------------------------------
    @scrHelp=
	("--- Help:  For further information on input options type:",
	 "--- "." " x length($tmp{"scrName"}).
	 "              ........................................");
    @scrHelpLoop=
	($tmp{"scrName"}.".pl help          : lists all options",
	 $tmp{"scrName"}.".pl def           : writes default settings",
	 $tmp{"scrName"}.".pl def keyword   : settings for keyword",
	 $tmp{"scrName"}.".pl help keyword  : explain key, how for 'how' and 'howie'");
    push(@scrHelp,@scrHelpLoop,
	 "--- "." " x length($tmp{"scrName"}).
	        "              ........................................");
				# ------------------------------
				# no input
				# ------------------------------
    if ($#ARGV < 1) {
	print "-" x 80, "\n"; print "--- Perl script $scrName.pl (",$tmp{"sourceFile"},")\n"; 
	foreach $txt (@scrTask) {print "$txt\n";}
	if (defined $tmp{"scrHelpTxt"}){@tmp=split(/\n/,$tmp{"scrHelpTxt"});
					foreach $txt (@tmp){
					    print "--- $txt\n";}}
	foreach $txt (@scrHelp) {
	    print "$txt\n";} 
	return(1,"fin");}
				# ------------------------------
				# help request
				# ------------------------------
    elsif ($#ARGV<2 && $ARGV[1] =~ /^(help|man|-m|-h)$/){
	print "-" x 80, "\n"; print "--- Perl script $scrName.pl (",$tmp{"sourceFile"},")\n"; 
	foreach $txt (@scrTask) {
	    print "$txt\n";}
	if (defined $tmp{"scrHelpTxt"}) {
	    @tmp=split(/\n/,$tmp{"scrHelpTxt"});
	    foreach $txt (@tmp){
		print "--- $txt\n";}}
	if (defined $tmp{"special"}) {
	    @kwdLoc=split(/,/,$tmp{"special"});
	    if ($#kwdLoc>1){
		print "-" x 80,"\n","---    'special' keywords:\n";
		foreach $kwd(@kwdLoc){$tmp=" "; $tmp=$tmp{"$kwd"} if (defined $tmp{"$kwd"});
				      printf "---   %-15s %-s\n",$kwd,$tmp;}}}
        if (defined %par) {
	    @kwdLoc=sort keys (%par);
	    if ($#kwdLoc>1){
		print 
		    "-" x 80,"\n",
		    "---    Syntax used to set parameters by command line:\n",
		    "---       'keyword=value'\n",
		    "---    where 'keyword' is one of the following keywords:\n";
		$ct=0;print "OPT \t ";
		foreach $kwd(@kwdLoc){++$ct;
				      printf "%-20s ",$kwd;
				      if ($ct==4){$ct=0;print "\nOPT \t ";}}print "\n";}
            print 
                "--- \n",
                "---    you may (or may not) get further explanations on a particular keyword\n",
                "---    by typing:\n",
                $tmp{"scrName"}.".pl help keyword\n",
                "---    this could explain the key.  Type 'how' for info on 'how,howie,show'.\n",
                "--- \n";}
        else { print "--- no other options enabled by \%par\n";}
	return(1,"fin loop?");}
				# ------------------------------
				# wants manual
				# ------------------------------
    elsif ($#ARGV<2  && $ARGV[1] eq "manual"){
	print "-" x 80, "\n"; print "--- Perl script $scrName.pl (",$tmp{"sourceFile"},")\n"; 
	if (defined $par{"fileHelpMan"} &&  -e $par{"fileHelpMan"}){
	    open("FHIN",$par{"fileHelpOpt"}) || 
		warn "*** $sbrName: could NOT open file".$par{"fileHelpOpt"};
	    while(<FHIN>){print $_;}close(FHIN);}
	else {
	    print "no manual in \%par{'fileHelpMan'}!!\n";}
	return(1,"fin");}
				# ------------------------------
				# wants hints
				# ------------------------------
    elsif ($#ARGV<2  && $ARGV[1] eq "hints"){
	print "-" x 80, "\n"; print "--- Perl script $scrName.pl (",$tmp{"sourceFile"},")\n"; 
	print "--- Hints for users:\n";$ct=0;
	if (defined $par{"fileHelpHints"} && -e $par{"fileHelpHints"}){
	    open("FHIN",$par{"fileHelpHints"}) || 
		warn "*** $sbrName: could NOT open file".$par{"fileHelpHints"};
	    while(<FHIN>){
		print $_; ++$ct;}close(FHIN);}
	if (defined $par{"scrHelpHints"}){
	    @tmp=split(/\n/,$par{"scrHelpHints"});
	    foreach $txt(@tmp){print "--- $txt\n";++$ct;}}
	if ($ct==0){
	    print "--- the only hint to give: try another help option!\n";
            print "---                        sorry ...\n";}
	return(1,"fin loop?");}
				# ------------------------------
				# wants problems
				# ------------------------------
    elsif ($#ARGV<2  && $ARGV[1] eq "problems"){
	print "-" x 80, "\n"; print "--- Perl script $scrName.pl (",$tmp{"sourceFile"},")\n"; 
	print "--- Known problems with script:\n";$ct=0;
	if (defined $par{"fileHelpProblems"} && -e $par{"fileHelpProblems"}){
	    open("FHIN",$par{"fileHelpProblems"}) || 
		warn "*** $sbrName: could NOT open file".$par{"fileHelpProblems"};
	    while(<FHIN>){
		print $_; ++$ct;}close(FHIN);}
	if (defined $par{"scrHelpProblems"}){
	    @tmp=split(/\n/,$par{"scrHelpProblems"});
	    foreach $txt(@tmp){print "--- $txt\n";++$ct;}}
	if ($ct==0){
	    print "--- One problem is: there is no problem annotated.\n";
            print "---                 sorry ...\n";}
	return(1,"fin loop?");}
				# ------------------------------
				# wants default settings
				# ------------------------------
    elsif ($#ARGV<2 && $ARGV[1] eq "def"){
	print "-" x 80, "\n"; print "--- Perl script $scrName.pl (",$tmp{"sourceFile"},")\n"; 
        if (defined %par){
            @kwdLoc=sort keys (%par);
            if ($#kwdLoc>1){
                print  "---    the default settings are:\n";
                printf "--- %-20s   %-s\n","." x 20,"." x 20;
                printf "--- %-20s = %-s\n","keyword","value";
                printf "--- %-20s   %-s\n","." x 20,"." x 20;
                foreach $kwd(@kwdLoc){
                    printf "--- %-20s = %-s\n",$kwd,$par{"$kwd"};}
                printf "--- %-20s   %-s\n","." x 20,"." x 20;
                print 
                    "--- \n",
                    "---    to get settings for particular keywords use:\n",
                    $scrName,".pl def keyword'\n \n";}}
        else { print "--- no setting defined in \%par\n";
	       print "---                       sorry...\n";}
	return(1,"fin loop?");}
				# ------------------------------
				# help for particular keyword
				# ------------------------------
    elsif ($#ARGV>=2 && $ARGV[1] eq "help"){
	print "-" x 80, "\n"; print "--- Perl script $scrName.pl (",$tmp{"sourceFile"},")\n"; 
	$kwdHelp=$ARGV[2]; 
	$tmp="help $kwdHelp";	# special?
	$tmp=~tr/[A-Z]/[a-z]/;	# make special keywords case independent 
        $tmp2=$tmp;$tmp2=~s/help //;
	$tmpSpecial=$tmp{"$tmp"}  if (defined $tmp{"$tmp"});
	$tmpSpecial=$tmp{"$tmp2"} if (! defined $tmp{"$tmp"} && defined $tmp{"$tmp2"});

        $#kwdLoc=$#expLoc=0;    # (1) get all respective keywords
        if (defined %par){
            @kwdLoc=keys (%par);$#tmp=0;
            foreach $kwd (@kwdLoc){
                push(@tmp,$kwd) if ($kwd =~/$kwdHelp/i);}
            @kwdLoc=sort @tmp;}
                                # (2) is there a 'help option file' ?
        if (defined $par{"fileHelpOpt"} && -e $par{"fileHelpOpt"} ){
	    print 
		"-" x 80,"\n",
		"---    Syntax used to set parameters by command line:\n",
		"---       'keyword=value'\n",
		"---    where 'keyword' is one of the following keywords:\n";
	    open("FHIN",$par{"fileHelpOpt"}) || 
		warn "*** $sbrName: could NOT open file".$par{"fileHelpOpt"};
	    while(<FHIN>){
		next if ($_=~/^\#/);
		$line=$_;
		$tmp=$_;$tmp=~s/\s//g;
		next if (length($tmp)<2);
		next if ($_=~/^\s/ && ! $Lok);	   
		if    ($Lok && $_=~/^\s/){
		    print $_;
		    next;}
		elsif ($Lok && $_!~/^\s/){
		    $Lok=0;}
		if (! $Lok && $_ !~ /^[\s\t]+/){
		    $line=$_;
		    ($tmp1,$tmp2)=split(/[\s\t]+/,$_);
		    $Lok=1 if (length($tmp1)>1 && $tmp1 =~ /$kwdHelp/i);
		    print $line if ($Lok);}}close(FHIN);
	    print "-" x 80, "\n";}
                                # (3) is there a default file?
        elsif (defined $par{"fileDefaults"} && -e $par{"fileDefaults"} ){
	    ($Lok,$msg,%def)=&brIniRdDef($par{"fileDefaults"});
	    $def{"kwd"}="" if (! $Lok); # hack: short cut error
	    @kwdLoc=split(/,/,$def{"kwd"});$#tmp=0;
	    foreach $kwd (@kwdLoc){
		if ($kwd =~/$kwdHelp/i){
		    push(@tmp,$kwd); 
		    if (defined $def{"$kwd","expl"}){
			$def{"$kwd","expl"}=~s/\n/\n---                        /g;
			push(@expLoc,$def{"$kwd","expl"});}
		    else {push(@expLoc," ");}}}
	    @kwdLoc=@tmp;}
        else {                  # (3) else: read itself
            ($Lok,$msg,%def)=
		&brIniHelpRdItself($tmp{"sourceFile"});
            die '.....   verrry sorry the option blew up ... ' if (! $Lok);
	    $def{"kwd"}="" if (! $Lok); # hack: short cut error
            @kwdLoc=split(/,/,$def{"kwd"});$#tmp=0;
            foreach $kwd (@kwdLoc){
                if ($kwd =~/$kwdHelp/i){
                    push(@tmp,$kwd); 
                    if (defined $def{"$kwd"}){
                        $def{"$kwd"}=~s/\n[\t\s]*/\n---                        /g;
                        push(@expLoc,$def{"$kwd"});}
                    else {push(@expLoc," ");}}}
            @kwdLoc=@tmp;}
	$Lerr=1;
        if ($#kwdLoc>0){        # (4) write the stuff
            printf "--- %-20s   %-s\n","." x 20,"." x 53;
            printf "--- %-20s   %-s\n","keyword","explanation";
            printf "--- %-20s   %-s\n","." x 20,"." x 53;
            foreach $it(1..$#kwdLoc){
                $tmp=" "; $tmp=$expLoc[$it] if (defined $expLoc[$it]);
                printf "--- %-20s   %-s\n",$kwdLoc[$it],$tmp;}
            printf "--- %-20s   %-s\n","." x 20,"." x 53;
            print "--- \n";$Lerr=0;}

				# (5) special help?
	if (defined $tmpSpecial){
            print  "---    Special help for '$kwdHelp':\n";
            foreach $txt (split(/\n/,$tmpSpecial)) { 
		print "--- $txt\n";}
	    $Lerr=0;}
	print "--- sorry, no explanations found for keyword '$kwdHelp'\n" if ($Lerr);
	return(1,"fin loop?");}
				# ------------------------------
				# wants settings for keyword
				# ------------------------------
    elsif ($#ARGV>=2  && $ARGV[1] eq "def"){
	$kwdHelp=$ARGV[2];
	print "-" x 80, "\n"; print "--- Perl script $scrName.pl (",$tmp{"sourceFile"},")\n"; 
        if (defined %par){
            @kwdLoc=sort keys (%par);
            if ($#kwdLoc>1){
                print  "---    the default settings are:\n";
                printf "--- %-20s   %-s\n","." x 20,"." x 53;
                printf "--- %-20s = %-s\n","keyword","value";
                printf "--- %-20s   %-s\n","." x 20,"." x 53;
                foreach $kwd(@kwdLoc){
                    next if ($kwd !~ /$kwdHelp/);
                    printf "--- %-20s = %-s\n",$kwd,$par{"$kwd"};}
                printf "--- %-20s   %-s\n","." x 20,"." x 53;
                print  " \n";}}
	else { print "--- sorry, no setting defined in \%par\n";}
	return(1,"fin loop?");}

    return(1,"ok $sbrName");
}				# end of brIniHelp

#==============================================================================
sub brIniHelpRdItself {
    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   brIniHelpRdItself           reads the calling perl script (scrName),
#                               searches for 'sub\siniDef', and gets comment lines
#       in:                     perl-script-source
#       out:                    (Lok,$msg,%tmp), with:
#                               $tmp{"kwd"}   = 'kwd1,kwd2'
#                               $tmp{"$kwd1"} = explanations for keyword 1
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."brIniHelpRdItself";$fhinLoc="FHIN_"."brIniHelpRdItself";

    $Lok=       &open_file("$fhinLoc","$fileInLoc");
    return(0,"*** ERROR $sbrName: old '$fileInLoc' not opened\n") if (! $Lok);
                                # read file
    while (<$fhinLoc>) {        # search for initialising subroutine
        last if ($_=/^su[b] iniDef.* \{/);}
    $Lis=0;undef %tmp; $#tmp=0;
    while (<$fhinLoc>) {        # read lines with '   %par{"kwd"}= $val  # comment '
        $_=~s/\n//g;
        last if ($_=~/^su[b] .*\{/ && $_!~/^su[b] iniDef.* \{/);
        if    ($_=~/[\s\t]+\$par\{[\"\']?([^\"\'\}]+)[\"\']?\}[^\#]* \# (.*)$/){
            $Lis=1;$kwd=$1; push(@tmp,$kwd);$tmp{"$kwd"}=$2 if (defined $2);}
        elsif ($Lis && defined $tmp{"$kwd"} && $_=~/^[\s\t]+\# ?\-+/){
            $Lis=0;}
        elsif ($Lis && defined $tmp{"$kwd"} && $_=~/^[\s\t]*\# (.*)$/){
            $tmp{"$kwd"}.="\n".$1;}
        elsif ($Lis){
            $Lis=0;}}close($fhinLoc);
    $tmp{"kwd"}=join(',',@tmp);
    return(1,"ok $sbrName",%tmp);
}				# end of brIniHelpRdItself

#==============================================================================
sub brIniRdDef {
    local ($fileLoc)=@_;
    $[ =1 ;
#-------------------------------------------------------------------------------
#   brIniRdDef                  reads defaults for initialsing parameters
#       in GLOBAL:              $par{},@ARGV
#       out GLOBAL:             $par{} (i.e. changes settings automatically)
#       in:                     file_default
#       out:                    ($Lok,$msg,%defaults) with:
#                               $defaults{"kwd"}=         'kwd1,kwd2,...,'
#                               $defaults{"$kwd1"}=       val1
#                               $defaults{"$kwd1","expl"}=explanation for kwd1
#                               note: long explanations split by '\n'
#-------------------------------------------------------------------------------
    $sbrName="lib-br:brIniRdDef"; $fhin="FHIN_brIniRdDef";

    &open_file("$fhin","$fileLoc") ||
	return(0,"*** ERROR $sbrName: failed to open in '$fileLoc'\n");

    undef %defaults; $#kwd=0; $Lis=0;
				# ------------------------------
    while (<$fhin>){		# read file
	next if (length($_)<3 || $_=~/^\#/ || $_!~/\t/); # ignore lines beginning with '#'
	$_=~s/\n//g;
	$line=$_;
	$tmp=$line; $tmp=~s/[\s\#\-\*\.\=\t]//g;
	next if (length($tmp)<1); # ignore lines with only spaces or '-|#|*|='
	$line=~s/^[\s\t]*|[\s\t]*$//g; # purge leading blanks and tabs
				# ------------------------------
				# (1) case 'kwd  val  # comment'
	if    ($line=~/^([^\s\t]+)[\s\t]+([^\s\t]+)[\s\t]+\# ?(.*)$/){
	    $kwd=$1; push(@kwd,$kwd); $defaults{"$kwd"}=$2; 
            $defaults{"$kwd","expl"}=$3 if (defined $3 && length($3)>1); $Lis=1;}
				# (2) case 'kwd  val'
	elsif ($line=~/^([^\s\t]+)[\s\t]+([^\s\t]+)[\s\t]*$/){
	    $kwd=$1; $defaults{"$kwd"}=$2; $Lis=1; $defaults{"$kwd","expl"}=""; }
				# (3) case '          # ----'
	elsif ($Lis && $line =~ /^\#\s*[\-\=\_\.\*]+/){
	    $Lis=0;}
	elsif ($Lis && defined $defaults{"$kwd","expl"} && $line =~ /^\#\s*(.*)$/){
	    $defaults{"$kwd","expl"}.="\n".$1;}}
    close($fhin);
				# ------------------------------
    foreach $kwd (@kwd){        # fill in wild cards
        $defaults{"$kwd"}=$ARCH if ($defaults{"$kwd"}=~/ARCH/);}
                                # ------------------------------
    foreach $kwd (@kwd){        # complete it
	$defaults{"$kwd","expl"}=" " if (! defined $defaults{"$kwd","expl"});}
    $defaults{"kwd"}=join(',',@kwd);
				# ------------------------------
				# check the defaults read
				# AND OVERWRITE $par{} !!
    @kwdDef=keys %par; foreach $kwd (@kwdDef){ $tmp{$kwd}=1;}
    $Lok=1;
    foreach $kwd (@kwd){
	if (! defined $tmp{$kwd}){
	    $Lok=0;
	    print 
		"*** ERROR $sbrName: wrong keyword ($kwd) in defaults file ",$par{"fileDefaults"},"\n";}
				# ******************************
	else {			# overwrite
				# ******************************
	    $par{"$kwd"}=$defaults{"$kwd"};}}
    return(0,"*** ERROR $sbrName failed finishing to read defaults file\n");

    return(1,"ok $sbrName",%defaults);
}				# end of brIniRdDef

#==============================================================================
sub brIniSet {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   brIniSet                    changing parameters according to input arguments
#                               e.g. adding directories to file names asf
#-------------------------------------------------------------------------------
    $sbrName="lib-br:brIniSet";
    @kwd=sort keys(%par) if (defined %par && %par);
				# ------------------------------
    $#tmp=0;			# purge empty keywords
    foreach $kwd (@kwd){
        if (defined $kwd && length($kwd)>=1 && defined $par{"$kwd"}){
            push(@tmp,$kwd);}
	else { print "-*- WARN $sbrName: for kwd '$kwd', par{kwd} not defined!\n";}}
    @kwd=@tmp;
				# jobId
    $par{"jobid"}=$$ 
	if (! defined $par{"jobid"} || $par{"jobid"} eq 'jobid' || length($par{"jobid"})<1);
				# ------------------------------
				# add jobid
    foreach $kwd (@kwd){
	$par{"$kwd"}=~s/jobid/$par{"jobid"}/;}
                                # ------------------------------
                                # WATCH it for file lists: add dirIn
    if (defined $par{"dirIn"} && $par{"dirIn"} ne "unk" && $par{"dirIn"} ne "local" 
        && length($par{"dirIn"})>1){
	foreach $fileIn(@fileIn){
	    $fileIn=$par{"dirIn"}.$fileIn if (! -e $fileIn);
	    if (! -e $fileIn){ print "*** $sbrName: no fileIn=$fileIn, dir=",$par{"dirIn"},",\n";
			       return(0);}}} 
    $#kwdFileOut=0;		# ------------------------------
    foreach $kwd (@kwd){	# add 'pre' 'title' 'ext' to output files not specified
	next if ($kwd !~ /^fileOut/);
	push(@kwdFileOut,$kwd);
	next if (defined $par{"$kwd"} && $par{"$kwd"} ne "unk" && length($par{"$kwd"})>0);
	$kwdPre=$kwd; $kwdPre=~s/file/pre/;  $kwdExt=$kwd; $kwdExt=~s/file/ext/; 
	$pre="";$pre=$par{"$kwdPre"} if (defined $par{"$kwdPre"});
	$ext="";$ext=$par{"$kwdExt"} if (defined $par{"$kwdExt"});
	if (! defined $par{"title"} || $par{"title"} eq "unk"){
	    $par{"title"}=$scrName;$par{"title"}=~tr/[a-z]/[A-Z]/;} # capitalize title
	$par{"$kwd"}=$pre.$par{"title"}.$ext;}
				# ------------------------------
				# add output directory
    if (defined $par{"dirOut"} && $par{"dirOut"} ne "unk" && $par{"dirOut"} ne "local" 
        && length($par{"dirOut"})>1){
	if (! -d $par{"dirOut"}){ # make directory
	    print "--- $sbrName mkdir ",$par{"dirOut"},"\n" if ($par{"verb2"});
            $tmp=$par{"dirOut"};$tmp=~s/\/$// if ($tmp=~/\/$/);
	    $Lok= mkdir ($tmp,umask);
	    print "*** $sbrName failed making directory '",$par{"dirOut"},"'\n" if (! $Lok);}
	$par{"dirOut"}.="/" if (-d $par{"dirOut"} && $par{"dirOut"} !~/\/$/); # add slash
	foreach $kwd (@kwdFileOut){
	    next if ($par{"$kwd"} =~ /^$par{"dirOut"}/);
	    $par{"$kwd"}=$par{"dirOut"}.$par{"$kwd"} if (-d $par{"dirOut"});}}
				# ------------------------------
				# push array of output files
    $#fileOut=0 if (! defined @fileOut);
    foreach $kwd (@kwdFileOut){
	push(@fileOut,$par{"$kwd"});}
				# ------------------------------
				# temporary files: add work dir
    if (defined $par{"dirWork"} && $par{"dirWork"} ne "unk" && $par{"dirWork"} ne "local" 
	&& length($par{"dirWork"})>1) {
	if (! -d $par{"dirWork"}){ # make directory
	    print "--- $sbrName mkdir ",$par{"dirWork"},"\n" if ($par{"verb2"});
            $tmp=$par{"dirWork"};$tmp=~s/\/$// if ($tmp=~/\/$/);
	    $Lok= mkdir ($tmp,umask);
	    print "*** $sbrName failed making directory '",$par{"dirWork"},"'\n" if (! $Lok);}
	$par{"dirWork"}.="/" if (-d $par{"dirWork"} && $par{"dirWork"} !~/\/$/); # add slash
	foreach $kwd (@kwd){
	    next if ($kwd !~ /^file/);
	    next if ($kwd =~ /^file(In|Out|Help|Def)/i);
            $par{"$kwd"}=~s/jobid/$par{"jobid"}/ ;
	    next if ($par{"$kwd"} =~ /^$par{"dirWork"}/);
	    $par{"$kwd"}=$par{"dirWork"}.$par{"$kwd"};}}
				# ------------------------------
				# blabla
    $Lverb=1  if (defined $par{"verbose"} && $par{"verbose"});
    $Lverb2=1 if (defined $par{"verb2"}   && $par{"verb2"});
    $Lverb3=1 if (defined $par{"verb3"}   && $par{"verb3"});
				# ------------------------------
				# add ARCH
    if (defined $ARCH || defined $par{"ARCH"}){
	$ARCH=$par{"ARCH"}      if (! defined $ARCH &&   defined $par{"ARCH"});
	$par{"ARCH"}=$ARCH      if (  defined $ARCH && ! defined $par{"ARCH"});
	foreach $kwd (@kwd){	# add directory to executables
	    next if ($kwd !~ /^exe/);
	    next if ($par{"$kwd"} !~ /ARCH/);
	    $par{"$kwd"}=~s/ARCH/$ARCH/;}}

				# ------------------------------
    foreach $kwd (@kwd){	# add directory to executables
	next if ($kwd !~/^exe/);
	next if (-e $par{"$kwd"} || -l $par{"$kwd"});
				# try to add perl script directory
	next if (! defined $par{"dirPerl"} || ! -d $par{"dirPerl"});
	next if ($par{"$kwd"}=~/$par{"dirPerl"}/); # did already, no result
	$tmp=$par{"dirPerl"}; $tmp.="/" if ($tmp !~ /\/$/);
	$tmp=$tmp.$par{"$kwd"};
	next if (! -e $tmp && ! -l $tmp);
	$par{"$kwd"}=$tmp; }

				# ------------------------------
				# priority
    if (defined $par{"optNice"} && $par{"optNice"} ne " " && length($par{"optNice"})>0){
	$niceNum="";
	if    ($par{"optNice"}=~/nice\s*-/){
	    $par{"optNice"}=~s/nice-/nice -/;
	    $niceNum=$par{"optNice"};$niceNum=~s/\s|nice|\-|\+//g; }
	elsif ($par{"optNice"}=~/^\d+$/){
	    $niceNum=$par{"optNice"};}
	$niceNum=~s/\D//g;
	setpriority(0,0,$niceNum) if (length($niceNum)>0); }

    return(1);
}				# end of brIniSet

#==============================================================================
sub brIniWrt {
    local($exclLoc,$fhTraceLoc)=@_;
    $[ =1 ;
#-------------------------------------------------------------------------------
#   brIniWrt                    write initial settings on screen
#       in:                     $excl     : 'kwd1,kwd2,kw*' exclude from writing
#                                            '*' for wild card
#       in:                     $fhTrace  : file handle to write
#                                  = 0, or undefined -> STDOUT
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."brIniWrt";
    
    return(0,"*** $sbrName: no settings defined in %par\n") if (! defined %par || ! %par);
    $fhTraceLoc="STDOUT"        if (! defined $fhTraceLoc || ! $fhTraceLoc);

    print $fhTraceLoc "--- ","-" x 80, "\n";
    print $fhTraceLoc "--- Initial settings for $scrName ($0) on $Date:\n";
    @kwd= sort keys (%par);
				# ------------------------------
				# to exclude
    @tmp= split(/,/,$exclLoc)   if (defined $exclLoc);
    $#exclLoc=0; undef %exclLoc;
    foreach $tmp (@tmp) {
	if   ($tmp !~ /\*/) {	# exact match
	    $exclLoc{"$tmp"}=1; }
	else {			# wild card
	    $tmp=~s/\*//g;
	    push(@exclLoc,$tmp); } }
    if ($#exclLoc > 0) {
	$exclLoc2=join('|',@exclLoc); }
    else {
	$exclLoc2=0; }
	
    
	    
    $#kwd2=0;			# ------------------------------
    foreach $kwd (@kwd) {	# parameters
	next if (! defined $par{"$kwd"});
	next if ($kwd=~/expl$/);
	next if (length($par{"$kwd"})<1);
	if ($kwd =~/^fileOut/) {
	    push(@kwd2,$kwd);
	    next;}
	next if ($par{"$kwd"} eq "unk");
	next if (defined $exclLoc{"$kwd"}); # exclusion required
	next if ($exclLoc2 && $kwd =~ /$exclLoc2/);
	printf $fhTraceLoc "--- %-20s '%-s'\n",$kwd,$par{"$kwd"};}
				# ------------------------------
    if ($#kwd2>0){		# output files
	print $fhTraceLoc "--- \n","--- Output files:\n";
	foreach $kwd (@kwd2) {
	    next if ($par{"$kwd"} eq "unk"|| ! $par{"$kwd"});
	    next if (defined $exclLoc{"$kwd"}); # exclusion required
	    next if ($exclLoc2 && $kwd =~ /$exclLoc2/);
	    printf $fhTraceLoc "--- %-20s '%-s'\n",$kwd,$par{"$kwd"};}}
				# ------------------------------
				# input files
    if    (defined @fileIn && $#fileIn>1){
				# get dirs
	$#tmpdir=0; undef %tmpdir;
	foreach $file (@fileIn){
	    if ($file =~ /^(.*\/)[^\/]/){
		$tmp=$1;$tmp=~s/\/$//g;
		if (! defined $tmpdir{$tmp}){push(@tmpdir,$tmp);
					     $tmpdir{$tmp}=1;}}}
				# write
	print  $fhTraceLoc "--- \n";
	printf $fhTraceLoc "--- %-20s number =%6d\n","Input files:",$#fileIn;
	printf $fhTraceLoc "--- %-20s dirs   =%-s\n","Input dir:", join(',',@tmpdir) 
	    if ($#tmpdir == 1);
	printf $fhTraceLoc "--- %-20s dirs   =%-s\n","Input dirs:",join(',',@tmpdir) 
	    if ($#tmpdir > 1);
	for ($it=1;$it<=$#fileIn;$it+=5){
	    print $fhTraceLoc "--- IN: "; 
	    $it2=$it; 
	    while ( $it2 <= $#fileIn && $it2 < ($it+5) ){
		$tmp=$fileIn[$it2]; $tmp=~s/^.*\///g;
		printf $fhTraceLoc "%-18s ",$tmp;++$it2;}
	    print $fhTraceLoc "\n";}}
    elsif ((defined @fileIn && $#fileIn==1) || (defined $fileIn && -e $fileIn)){
	$tmp=0;
	$tmp=$fileIn    if (defined $fileIn && $fileIn);
	$tmp=$fileIn[1] if (! $tmp && defined @fileIn && $#fileIn==1);
	print $fhTraceLoc "--- \n";printf $fhTraceLoc "--- %-20s '%-s'\n","Input file:",$tmp;}
    print  $fhTraceLoc "--- \n";
    printf $fhTraceLoc "--- %-20s %-s\n","excluded from write:",$exclLoc;
    print  $fhTraceLoc "--- \n","--- ","-" x 80, "\n","--- \n";
	
    return(1,"ok $sbrName");
}				# end of brIniWrt

#==============================================================================
sub errSbr    {local($txtInLoc,$sbrNameLocy) = @_ ;
#-------------------------------------------------------------------------------
#   errSbr                      simply writes '*** ERROR $sbrName: $txtInLoc'
#-------------------------------------------------------------------------------
	       $sbrNameLocy=$sbrName if (! defined $sbrNameLocy);
	       $txtInLoc.="\n";
	       $txtInLoc=~s/\n\n+/\n/g;
	       return(0,"*** ERROR $sbrNameLocy: $txtInLoc");
}				# end of errSbr

#==============================================================================
sub errSbrMsg {local($txtInLoc,$msgInLoc,$sbrNameLocy) = @_ ;
#-------------------------------------------------------------------------------
#   errSbrMsg                   simply writes '*** ERROR $sbrName: $txtInLoc\n'.$msg
#-------------------------------------------------------------------------------
	       $sbrNameLocy=$sbrName if (! defined $sbrNameLocy);
	       $txtInLoc.="\n";
	       $txtInLoc=~s/\n\n+/\n/g;
	       $msgInLoc.="\n";
	       $msgInLoc=~s/\n\n+/\n/g;
	       return(0,"*** ERROR $sbrNameLocy: $txtInLoc".$msgInLoc);
}				# end of errSbrMsg

#==============================================================================
sub get_in_keyboard {
    local($des,$def,$pre,$Lmirror)=@_;local($txt);
#--------------------------------------------------------------------------------
#   get_in_keyboard             gets info from keyboard
#       in:                     $des :    keyword to get
#       in:                     $def :    default settings
#       in:                     $pre :    text string beginning screen output
#                                         default '--- '
#       in:                     $Lmirror: if true, the default is mirrored
#       out:                    $val : value obtained
#--------------------------------------------------------------------------------
    $pre= "---"                 if (! defined $pre);
    $Lmirror=0                  if (! defined $Lmirror || ! $Lmirror);
    $txt="";			# ini
    printf "%-s %-s\n",          $pre,"-" x (79 - length($pre));
    printf "%-s %-15s:%-s\n",    $pre,"type value for",$des; 
    if (defined $def){
	printf "%-s %-15s:%-s\n",$pre,"type RETURN to enter value, or to keep default";
	printf "%-s %-15s>%-s\n",$pre,"default value",$def;}
    else {
	printf "%-s %-15s>%-s\n",$pre,"type RETURN to enter value"; }

    $txt=$def                    if ($Lmirror);	# mirror it
    printf "%-s %-15s>%-s",      $pre,"type",$txt; 

    while(<STDIN>){
	$txt.=$_;
	last if ($_=~/\n/);}     $txt=~s/^\s+|\s+$//g;
    $txt=$def                   if (length($txt) < 1);
    printf "%-s %-15s>%-s\n",    $pre,"--> you chose",$txt;
    return ($txt);
}				# end of get_in_keyboard

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
sub sysDate {
#    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   sysDate                     returns $Date
#       out:                    $Date (May 30, 1998 59:39:03)
#-------------------------------------------------------------------------------
    @tmp=("/home/rost/perl/ctime.pl","/home/rost/pub/perl/ctime.pl");
				# ------------------------------
				# get function
    if (defined &localtime) {
	foreach $tmp(@tmp){
	    if (-e $tmp){$Lok=require("$tmp");
			 last;}}
	if (defined &ctime && &ctime && defined &localtime && &localtime){
#       	$date is e.g.:		Oct:14:13:06:47:1993
#       	@Date is e.g.:		Oct1413:06:471993
#        	&ctime(time) is e.g.:	Thu Oct 14 13:06:47 1993
#	    print "xx enter\n";
	    @Date = split(' ',&ctime(time)) ; shift (@Date) ; 
	    $Date="$Date[2] $Date[3], $Date[$#Date]  $Date[4]";
	    return($Date);}
    }
				# ------------------------------
				# or get system time
    $localtime=`date`;
    @Date=split(/\s+/,$localtime);
    $Date="$Date[2] $Date[3], $Date[$#Date] $Date[4]";
    return($Date);
}				# end of sysDate

