#!/usr/local/bin/perl -w
##!/usr/sbin/perl4 -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
				# defaults (1)
				# CUBIC
$dirFtp=     "/home/ftp/pub/rost/";
$dirCron=    "/home/rost/pub/cron/";
$dirWork=    $dirCron."tmp/";
$dirTarTmp=  $dirWork."rost/";
$dirTarFin=  $dirFtp;
$dirWWWdoc=  "/home/rost/public_html/";

				# general
$dirLog=     $dirCron;
$fileLog=    $dirLog.   "wwwMirror.log";
$fileCronLog=$dirLog.   "crontab.log";
$fileTmpLog= $dirWork.  "SCREEN-$scrName.log";
$fileTar=    $dirTarTmp."wwwRost.tar";
$fileTarFin= $fileTar; $fileTarFin=~s/$dirTarTmp/$dirTarFin/;

$scrGoal=
    "copy PP br home pages to ftp-able site\n".
    "     \t note: currently to parrot: $fileTarFin\n".
    "     \t       log files of action: $dirLog\n";
#  
#
$[ =1 ;
				# ------------------------------
if ($#ARGV<1){			# help
    print "goal:\t $scrGoal\n";
    print "use: \t '$scrName <dir_with_pp_www_docs|auto>'\n";
    print "     \t           'auto' assumes directory is $dirWWWdoc\n";
    print "opt: \t log=x   name of log file to report the action\n";
    print "     \t out=x   name of tared pages\n";
    print "     \t nozip   (default will gzip on final tar)\n" ;
    print "     \t verbose (dont redirect output)\n";
    print "     \t dbg     all messages to STDOUT\n";
    exit;}
				# ------------------------------
				# initialise variables

#$cmdTar=     "/usr/bin/tar -cvfL";
$cmdTar=     "/usr/bin/tar -cf";
#$cmdTar=     "/usr/local/bin/tar -cvf";
#$cmdUntar=   "tar -xvf";
#$cmdRsh=     "rsh phenix";	# note: ftp only on phenix!
$cmdRsh=     0;			# no rsh
$cmdZip=     "gzip";
$Lzip=       1;
$Lverb=      0;
$Ldebug=     0;
#$Lverb=      1;
$nfilesMax=  500;		# problem with long file lists on tar

				# ------------------------------
$dirIn=$ARGV[1];		# read command line
$dirIn=$dirWWWdoc               if ($dirIn =~/^auto$/i);
$dirIn.="/"                     if ($dirIn !~/\/$/);

foreach $_(@ARGV){
    next if ($_ eq $ARGV[1]);
    if   ($_=~/^out=(.*)$/){$fileTar=$1;}
    elsif($_=~/^log=(.*)$/){$fileLog=$1;}
    elsif($_=~/^nozip/)    {$Lzip=   0;}
    elsif($_=~/^verb/)     {$Lverb=  1;}
    elsif($_=~/^de?bu?g/i) {$Ldebug= 1;}
    else {print"*** wrong command line arg '$_'\n";
	  die;}}

if (! $Lverb && ! $Ldebug){
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

				# (1) get the path out
$dirRel=$dirIn;$dirRel=~s/^.*\/(.+)\/$/$1/g;
$dirDel=$dirIn;$dirDel=~s/$dirRel//;$dirDel=~s/\/\//\//g;

				# ------------------------------
				# get current pages and newest file
				# out GLOBAL @FILEWWW
$Lis_old_way=0;

$LdoUpdate=
    &listNow($dirDel,$dirIn);	# returns 1 and the file list if to update!

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
				# in GLOBAL @FILEWWW
($Lok,$msg)=
    &makeTar($cmdTar,$dirDel,$dirIn,$fileTar,$nfilesMax,
	     $dirWork,$dirTarTmp);
				# ******************************
				# fatal ERROR
if (! $Lok) { print "*** ERROR $scrName: failed on makeTar (dirDel=$dirDel, fileTar=$fileTar)\n";
	      print "*** msg=\n",$msg,"\n";
	      die; }

				# ------------------------------
				# zip
if ($Lzip){
    $fileZip=   $fileTar.".gz";
    $fileZipFin=$fileTarFin.".gz";
    unlink($fileZip)            if (-e $fileZip);
    unlink($fileZipFin)         if (-e $fileZipFin);
    $command="$cmdZip $fileTar"; print "--- $scrName system \t '$command'\n";
    $Lok=`$command`;
#    $fileZip=`ls $fileTar*`;
    print "--- $scrName after zip name=$fileZip,\n"; }
else{
    $fileZip=$fileTar;
    $fileZipFin=$fileTarFin;}

				# ------------------------------
				# finally move to ftp site!
if ($dirFtp =~/ftp\/pub\/exchange/ && 
    $cmdRsh && length($cmdRsh) > 4){
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

print "--- output in $fileTarFin ($fileZipFin) right? \n";
exit(1);



#==============================================================================
# library collected (begin)
#==============================================================================


#==============================================================================
sub completeDir {local($DIR)=@_; $[=1 ; 
		 return(0) if (! defined $DIR);
		 return($DIR) if ($DIR =~/\/$/);
		 return($DIR."/");} # end of completeDir



#==============================================================================
# library collected (end)
#==============================================================================

#===============================================================================
sub listNow {
    local($dirInLoc)=@_;
    local($sbrName);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   listNow                     lists all FILEWWWs in current dir
#       in:                     $dirDelLoc=  path to delete from file (/home/rost/)
#       in:                     $dirInLoc=   path of original input (/home/rost/public_html/)
#       out GLOBAL:             @FILEWWW
#                               ($dateNew,$dayNew,$monNew,$yearNew,$fileNew)
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";$sbrName="$tmp"."listNow";
    $fhinLoc="FHIN_DIR";

				# ------------------------------
				# go to public_html
    $Lok=chdir($dirInLoc);
    if (! $Lok) {
	print "*** ERROR $sbrName: failed changing dir to $dirInLoc\n";
	exit; }
				# ------------------------------
    $#FILEWWW=0;		# read directory
    if ($Lis_old_way){
	open($fhinLoc,"find $dirInLoc -print |");}
    else {
	open($fhinLoc,"find . -print |");
    }
    while (<$fhinLoc>){
	$_=~s/\s//g;
				# purge dirIn
	if ($Lis_old_way){
	    $_=~s/$dirDelLoc//g;}
	else {
	    $_=~s/\.\///g;
	}
	$file=$_;
	next if (length($file) < 1);
				# skip emacs temporary
	next if ($file=~/[~]$/);

	if ($Lis_old_way){
				# skip local dir
	    next if (-d $file || $file=~/\/$/);
				# exclude some
	    next if ($file=~/^(.*\/)?(aw|mis|Var|Djunk|Local|MAT|tmp)/);
				# avoid links
	    next if (-l $file);
	    $tmp=$file;$tmp=~s/^(.*\/)[^\/]*$/$1/g;
	    next if (-l $tmp);
	    if (-d $tmp) {print "xx dir=$file, $tmp\n";}
	    next if (-d $file);
	    next if ($file=~/Res|Paper|Dicon|Dfig/);}
	else {
	    next if ($file=~/^(aw|stat|mis|Var|Djunk|Local|MAT|tmp)/);
	    next if (-l $file);
	    $tmp=$file;$tmp=~s/^(.*\/)[^\/]*$/$1/g;
	    next if (-l $tmp);
	    next if (-d $file);
	}
	push(@FILEWWW,$file);}
    close($fhinLoc);
				# ------------------------------
				# find newest
    if (-e $fileLog){		# ini
	$age=   -M $fileLog;
	$newest=$age;}
    else {
	$age=   -M $dirDelLoc.$FILEWWW[1]; 
	$newest=$FILEWWW[1];}

    for $file (@FILEWWW) {
	if ($Lis_old_way){
	    $fileLocation=$dirDelLoc.$file;
	    if (! -e $fileLocation) {
		print '-*- WARN: $sbrName: missing file '.$file.' in dir '.$dirDelLoc,"\n";
		next; }
	}
	else {
	    $fileLocation=$file;
	}
	if (-M $fileLocation < $age) {
	    $age= -M $fileLocation;
	    $newest=$fileLocation; }}
    printf "--- $sbrName newest file is '%8.3f' old: %-s\n",$age,$newest;

    return(1)                   if (! -e $fileLog);
	
    printf "--- $sbrName log file   is '%8.3f' old: %-s\n",-M $fileLog,$fileLog;
				# no action if no change
    return (0)                  if ($newest eq $fileLog);
    return (1);
}				# end of listNow

#===============================================================================
sub makeTar {
    local($cmdTar,$dirDelLoc,$dirInLoc,$fileTarLoc,$nfilesMax,
	  $dirWorkLoc,$dirTarTmpLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   makeTar                     cd-s to dirLoc and makes tar fileTarLoc from @file
#       in:                     $cmdTar=     command to run tar
#       in:                     $dirDelLoc=  path to delete from file (/home/rost/)
#       in:                     $dirInLoc=   path of original input (/home/rost/public_html/)
#       in:                     $fileTarLoc= name of output tar file
#       in:                     $nfilesMax=  maximal number of files to tar in one go
#       in GLOBAL:              @FILEWWW=    all files from WWWdoc dir
#       out:                    
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."makeTar";$fhinLoc="FHIN"."$sbrName";

    print "--- $scrName \t cd to $dirDelLoc\n";
    if ($Lis_old_way){
	$Lok=chdir($dirDelLoc);
	return(0,"*** ERROR $scrName couldnot change dir to $dirDelLoc\n") if (! $Lok);}
    else {
	$Lok=chdir($dirWorkLoc);
	return(0,"*** ERROR $scrName couldnot change dir to $dirWorkLoc\n") if (! $Lok);
    }

				# ------------------------------
    if (-e $fileTarLoc){	# if existing: remove
	print "-*- WARNING $scrName existing file $fileTarLoc\n";
	unlink($fileTarLoc);	} # delete old

				# ------------------------------
				# create tar archive
    $numRepeat=1+int($#FILEWWW/$nfilesMax);
    $cmdTarRepeat=$cmdTar;$cmdTarRepeat=~s/\-c/\-r/;

    foreach $it (1..$numRepeat){
	$itBeg=1+($it-1)*$nfilesMax;
	$itEnd=$itBeg+$nfilesMax-1; 
	$itEnd=$#FILEWWW        if ($#FILEWWW<$itEnd);
	
	$tmp=join(' ',@FILEWWW[$itBeg..$itEnd]);

	if ($it==1){                # first time: generate tar
	    print "--- $cmdTar $fileTarLoc (files $itBeg - $itEnd)\n";
	    $command="$cmdTar $fileTarLoc $tmp";
	    $Lok=`$command`;
	}
	else {                      # then: append
	    print "--- $cmdTarRepeat $fileTarLoc (files $itBeg - $itEnd)\n";
	    $command="$cmdTarRepeat $fileTarLoc $tmp";
	    $Lok=`$command`;
	}
    }
    
    return(0,"*** ERROR $sbrName: tar failed\n")
	if (! -e $fileTarLoc);

    print "--- output in $fileTarLoc\n";
				# ------------------------------
				# verify reading
    @tmp=`/usr/bin/tar -tf $fileTarLoc`;
    print "--- verify found $#tmp files, expected was: ",$#FILEWWW,"\n";

    return(1,"ok $sbrName");
}				# end of makeTar

