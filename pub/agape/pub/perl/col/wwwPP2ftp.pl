#!/usr/sbin/perl4 -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal=
    "copy PP home pages to ftp-able site (DO ON PHENIX)\n".
    "     \t note: currently to phenix: ~ftp/pub/exchange/rost/wwwPP.tar\n".
    "     \t       log file of action : /home/rost/pub/pp/log/wwwMirror.log";
#  
#
$[ =1 ;
				# include libraries
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
$Lok=require "ctime.pl"   ;  die("*** ERROR no successful require $scrName") if (! $Lok);
$Lok=require "lib-ut.pl"  ;  die("*** ERROR no successful require $scrName") if (! $Lok);
$Lok=require "lib-prot.pl";  die("*** ERROR no successful require $scrName") if (! $Lok);
$Lok=require "lib-comp.pl";  die("*** ERROR no successful require $scrName") if (! $Lok);
				# ------------------------------
if ($#ARGV<1){			# help
    print "goal:\t $scrGoal\n";
    print "use: \t '$scrName dir'\n";
    print "opt: \t log=x   name of log file to report the action\n";
    print "     \t out=x   name of tared pages\n";
    print "     \t nozip   (default will gzip on final tar)\n" ;
    print "     \t verbose (dont redirect output)\n";
    exit;}
				# ------------------------------
				# initialise variables
$dirFtp=     "/usr/people/ftp/pub/exchange/rost/pp/";
#$dirFtp=    "";
$dirLog=     "/home/rost/pub/pp/log/";
$dirWork=    "/junk/rost/bup/";
#$dirMy=      "/home/rost/public_html/";
$fileLog=    $dirLog. "wwwMirror.log";
$fileCronLog=$dirLog. "crontab.log";
$fileTmpLog= $dirWork."screen-wwwPP2ftp.tmp";
#$fileTarPP=  $dirWork."wwwPP.tar";
#$fileTarBR=  $dirWork."wwwBR.tar";
$fileTar=    $dirWork."www.tar";

$cmdTar=     "tar -cvf";
#$cmdUntar=   "tar -xvf";
$cmdRsh=     "rsh phenix";		# note: ftp only on phenix!
$cmdRsh=     "";			# note: ftp only on phenix!
$cmdZip=     "gzip";
$Lzip=       1;
$Lverb=      0;
#$Lverb=      1;
				# ------------------------------
$dirIn=$ARGV[1];		# read command line
foreach $_(@ARGV){
    next if ($_ eq $ARGV[1]);
    if   ($_=~/^out=(.*)$/){$fileTar=$1;}
    elsif($_=~/^log=(.*)$/){$fileLog=$1;}
    elsif($_=~/^nozip/)    {$Lzip=0;}
    elsif($_=~/^verb/)     {$Lverb=1;}
    else {print"*** wrong command line arg '$_'\n";
	  die;}}

if (! $Lverb){
    open(STDOUT, ">$fileTmpLog") ||
	warn "-*- cannot open file=$fileTmpLog: $!\n";
    open(STDERR, ">>$fileTmpLog") ||
	warn "-*- cannot open file=$fileTmpLog: $!\n";
    $| = 1;			# flush output
}
				# get current date
#@date=split(' ',&ctime(time)); shift(@date); 
#$dayHere=$date[2],$monHere=&month2num($date[1]);$yearHere=$date[$#date];
#$dateHere="$dayHere-$monHere-$yearHere"; # Feb-3-1998 -> '3-2-1998'

$dirIn=&completeDir($dirIn);	# appends '/'

				# ------------------------------
$LdoUpdate=			# get current pages and newest file
    &listNow($dirIn);		# returns 1 and the file list if to update!
				# GLOBAL:  @filePP

				# ------------------------------
if (! $LdoUpdate){		# nothing to do ...
    $txt=  "----\\\n-----> UP-TO-DATE, already, it seems!\n----/";
    print "--- $txt\n";
    if (! $Lverb){		# to log file only if not verbose flag
	system("echo '$txt' >> $fileCronLog");}
    exit(1);}
				# --------------------------------------------------
				# update the public tar file with WWW pages
				# --------------------------------------------------
print "--- $scrName \t do the update on $dirIn\n";
				# (1) get the path out
$dirRel=$dirIn;$dirRel=~s/^.*\/(.+)\/$/$1/g;
$dirDel=$dirIn;$dirDel=~s/$dirRel//;$dirDel=~s/\/\//\//g;
&makeTar($dirDel,$fileTar,@filePP);
				# ------------------------------
				# zip
if ($Lzip){
    $fileZip=$fileTar.".gz";
    if (-e $fileZip){unlink($fileZip);}
    $command="$cmdZip $fileTar"; print "--- $scrName system \t '$command'\n";
    $Lok=`$command`;
#    $fileZip=`ls $fileTar*`;
    print "--- $scrName after zip name=$fileZip,\n";}
else{
    $fileZip=$fileTar;}
				# ------------------------------
				# finally move to ftp site!
if (($dirFtp =~/ftp\/pub\/exchange/)&& (length($cmdRsh)>4)){
				# for rsh get absolute path
    $path=$ENV{'PWD'};$path=&completeDir($path);
    $tmp=$path.$fileZip;
    $command="$cmdRsh '\\mv $tmp $dirFtp'";print "--- $scrName system \t '$command'\n";
    $Lok=`$command`;
    $fin=$dirFtp.$fileZip;}
elsif (length($dirFtp)>0){
    $command="\\mv $fileZip $dirFtp";print "--- $scrName system \t '$command'\n";
    $Lok=`$command`;
    $fin=$dirFtp.$fileZip;}
else {
    $fin=$fileZip;}
print "--- update log file $fileLog\n";

unlink $fileLog;
system("echo `date` >> $fileLog");

print "--- output in $fileTar ($fileZip) right? \n";
exit;

#===============================================================================
sub listNow {
    local($sbrName);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   listNow                     lists all files in current dir
#       in:                     GLOBAL
#       out:                    GLOBAL 
#                               ($dateNew,$dayNew,$monNew,$yearNew,$fileNew)
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";$sbrName="$tmp"."listNow";
    $fhinLoc="FHIN_DIR";
				# get the path out
    $dirRel=$dirIn;$dirRel=~s/^.*\/(.+)\/$/$1/g;
    $dirDel=$dirIn;$dirDel=~s/$dirRel//;$dirDel=~s/\/\//\//g;
				# ------------------------------
    $#filePP=0;			# read directory
    open($fhinLoc,"find $dirIn -print |");
    while (<$fhinLoc>){
	$_=~s/\s//g;$_=~s/$dirDel//g;$file=$_;
#	$_=~s/\s//g;$_=~s/$dirIn//g;
	$_=~s/$dirRel//;$_=~s/^\///;
	next if (($_ =~/^D/)&&($_!~/\//));
	next if ((length($_)<2) || ($_=~/^[\.]|~$/) || (! -e $dirDel.$file) ||
		 (/(old|new|wusage|tmp|bup|xx|READ|List|PP|hack)/));
	push(@filePP,$file);}close($fhinLoc);
				# ------------------------------
				# find newest
    if (-e $fileLog){		# ini
	$age=  -M $fileLog;}
    else {$age= -M $dirDel.$filePP[1]; $newest=$filePP[1];}

    for $file (@filePP) {
	die 'missing file '.$file.' in dir '.$dirDel if (! -e $dirDel.$file);
	if (-M $dirDel.$file < $age) {
	    $age= -M $dirDel.$file;
	    $newest=$file; }}
    printf "--- $sbrName newest file is '%8.3f' old: %-s\n",$age,$newest;

    return(1) if (! -e $fileLog);
	
    printf "--- $sbrName log file   is '%8.3f' old: %-s\n",-M $fileLog,$fileLog;
    return (0) if ($newest eq $fileLog); # no action if no change
    return (1);
}				# end of listNow

#===============================================================================
sub makeTar {
    local($dirLoc,$fileTarLoc,@fileLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   makeTar                     cd-s to dirLoc and makes tar fileTarLoc from @file
#       in:                     
#       out:                    
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."makeTar";$fhinLoc="FHIN"."$sbrName";

    print "--- $scrName \t cd to $dirLoc\n";
    $Lok=chdir($dirLoc);
    if (! $Lok){return(0,"*** ERROR $scrName couldnot change dir to $dirLoc\n");
		die;}
				# ------------------------------
    if (-e $fileTarLoc){	# if existing: remove
	print "-*- WARNING $scrName existing file $fileTarLoc\n";
	unlink("$fileTarLoc");	} # delete old

				# ------------------------------
				# create tar archive
    $files= join (' ',@fileLoc);
    
    $command="$cmdTar $fileTarLoc $files\n";print "--- $sbrName system \t '$command'\n";
    $Lok=`$command`;
    if (! -e $fileTarLoc){
	print "*** ERROR $sbrName: tar failed\n";
	die;}
}				# end of makeTar

