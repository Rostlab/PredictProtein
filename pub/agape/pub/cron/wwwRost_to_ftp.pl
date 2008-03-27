#!/usr/local/bin/perl -w
##!/usr/sbin/perl4 -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
				# defaults (1)
$emailCurator=  "rost\@columbia.edu";
				# CUBIC
$dirFtp=        "/home/ftp/pub/rost/";
$dirCron=       "/home/rost/pub/cron/";
$dirWork=       $dirCron."tmp/";
$dirTarNew=     $dirWork."rost/";
$dirTarFin=     $dirFtp;
$dirWWWdoc=     "/home/rost/public_html/";

				# ------------------------------
				# to copy every day
				# (hotlist) links
$dirCUBIClinks= "/home/cubic/public_html/doc/";    # HARD_CODED
$preCUBIClinks= "links_";                          # HARD_CODED
$dirBRlinks=    "/home/rost/public_html/doc/";     # HARD_CODED
				# papers
$dirCUBICpapers="/home/cubic/public_html/papers/"; # HARD_CODED
$dirBRpapers=   "/home/rost/public_html/Papers/";  # HARD_CODED

				# general
$dirLog=       $dirCron;
$fileLog=      $dirLog.   "wwwMirror.log";
$fileCronLog=  $dirLog.   "crontab.log";
$fileTmpLog=   $dirWork.  "SCREEN-$scrName.log";
				# file with 'tar www.tar public_html/*' 
				#    NOTE: NO dir in www.tar, since chdir to public_html!
$fileTarOrigin=$dirTarNew."wwwRost.tar";
$fileTarNew=$dirWork.  "wwwRost.tar";
$fileTarFin=   $fileTarOrigin; $fileTarFin=~s/$dirTarNew/$dirTarFin/;

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
    if   ($_=~/^out=(.*)$/){$fileTarOrigin=$1;}
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
				# --------------------------------------------------
				# update local mirror of pages
				# --------------------------------------------------

				# update the WWW links pages
($Lok,$msg)=
    &updateCUBIClinks($dirCUBIClinks,$preCUBIClinks,$dirBRlinks);
if (! $Lok){ $txt=
		 "*** ERROR $scrName: failed on updating CUBIClinks ".
		     "($dirCUBIClinks,$preCUBIClinks,$dirBRlinks)\n".
			 $msg."\n";
	     print $txt;
	     system("echo $txt|Mail -s problem_with_rost2ftp_links $emailCurator");}
    
				# update the WWW links pages
($Lok,$msg)=
    &updateCUBICpapers($dirCUBICpapers,$dirBRpapers);
if (! $Lok){ $txt=
		 "*** ERROR $scrName: failed on updating CUBICpapers ".
		     "($dirCUBICpapers,$dirBRpapers)\n".
			 $msg."\n";
	     print $txt;
	     system("echo $txt|Mail -s problem_with_rost2ftp_papers $emailCurator");}


				# --------------------------------------------------
				# NOW back to the WWW update of PP
				# --------------------------------------------------
				# get current date
#@date=split(' ',&ctime(time)); shift(@date); 
#$dayHere=$date[2],$monHere=&month2num($date[1]);$yearHere=$date[$#date];
#$dateHere="$dayHere-$monHere-$yearHere"; # Feb-3-1998 -> '3-2-1998'

				# (1) get the path out
$dirRel=$dirIn;$dirRel=~s/^.*\/(.+)\/$/$1/g;
$dirDel=$dirIn;$dirDel=~s/$dirRel//;$dirDel=~s/\/\//\//g;

				# ------------------------------
				# go to public_html
chdir($dirIn) ||
    die "*** ERROR $sbrName: failed changing dir to $dirIn\n";
print "--- $scrName chdir to $dirIn\n";

				# ------------------------------
				# get current pages and newest file
				# out GLOBAL @FILEWWW
$LdoUpdate=
    &listNow();			# returns 1 and the file list if to update!

				# ------------------------------
if (! $LdoUpdate){		# nothing to do ...
    $txt=  "----\\\n-----> UP-TO-DATE, already, it seems!\n----/";
    print "--- $txt\n";
    if (! $Lverb){		# to log file only if not verbose flag
	system("echo '$txt' >> $fileCronLog");}
    exit(1);}
				# ------------------------------
				# make directory for temporary 
				#    tar /home/rost/pub/cron/tmp/rost
if (! -d $dirTarNew) { 
    $cmd="mkdir $dirTarNew";
    system("$cmd");
    print "--- $scrName: system '$cmd'\n";}

				# --------------------------------------------------
				# update the public tar file with WWW pages
				#    NOTE: still in $dirIn (public_html)!
				# --------------------------------------------------
print "--- $scrName \t do the update on $dirIn\n";
				# in GLOBAL @FILEWWW
($Lok,$msg)=
    &tarMakeOriginal($cmdTar,$fileTarOrigin,$nfilesMax,$dirWork,$dirTarNew);
				# ******   fatal ERROR    ******
die ("*** ERROR $scrName: failed on tarMakeOriginal (dirIn=$dirIn, fileTar=$fileTarOrigin)\n",
     "*** msg=\n",$msg,"\n")    if (! $Lok);

				# ------------------------------
				# go to temporary dir (pub/cron/tmp/rost)
chdir($dirTarNew) ||
    die "*** ERROR $scrName: failed changing dir to $dirTarNew\n";
print "--- $scrName chdir to $dirTarNew\n";
				# --------------------------------------------------
				# untar and tar again
print "--- $scrName \t do the update on $dirTarNew\n";
($Lok,$msg)=
    &tarExtrTmp($cmdTar,$fileTarOrigin);
				# ******   fatal ERROR    ******
die ("*** ERROR $scrName: failed on tarExtrTmp (dirTarNew=$dirTarNew, fileTar=$fileTarOrigin)\n",
     "*** msg=\n",$msg,"\n")    if (! $Lok);

				# ------------------------------
				# delete temporary tar file
if (-e $fileTarOrigin){		# actually: should exist
    unlink($fileTarOrigin);     print "-*- WARN $scrName: removing $fileTarOrigin\n";}
				# security also new one
if (-e $fileTarNew) {
    unlink($fileTarNew);        print "-*- WARN $scrName: removing $fileTarNew\n";}

				# ------------------------------
				# go to working dir (pub/cron/tmp)
chdir($dirWork) ||
    die "*** ERROR $scrName: failed changing dir to dirWork=$dirWork\n";
print "--- $scrName chdir to $dirWork\n";

($Lok,$msg)=
    &tarMakeNew($cmdTar,$fileTarNew,$nfilesMax,$dirWork,$dirTarNew);
				# ******   fatal ERROR    ******
die ("*** ERROR $scrName: failed on tarMakeNew (dirWork=$dirWork, fileTar=$fileTarNew)\n",
     "*** msg=\n",$msg,"\n")    if (! $Lok);

				# ------------------------------
				# finally zip
				# ------------------------------
if ($Lzip){
    $fileZip=   $fileTarNew.".gz";
    $fileZipFin=$fileTarFin.".gz";
    unlink($fileZip)            if (-e $fileZip);
    unlink($fileZipFin)         if (-e $fileZipFin);
    $command="$cmdZip $fileTarNew"; print "--- $scrName system \t '$command'\n";
    $Lok=`$command`;
    print "--- $scrName after zip name=$fileZip,\n"; }
else{
    $fileZip=$fileTarNew;
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

				# ------------------------------
				# clean up entire temporary
				#    directory
$cmd="\\rm -r $dirTarNew";      print "--- $scrName: $cmd\n";
system("$cmd");


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
#    local($dirInLoc)=@_;
    local($sbrName);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   listNow                     lists all FILEWWWs in current dir
#       in:                     $dirDelLoc=  path to delete from file (/home/rost/)
#       in:                     $dirInLoc=   path of original input (/home/rost/public_html/)
#       out GLOBAL:             @FILEWWW
#                               ($dateNew,$dayNew,$monNew,$yearNew,$fileNew)
#-------------------------------------------------------------------------------
    $sbrName="listNow";
    $fhinLoc="FHIN_DIR";

    undef %filewww;		# avoid duplication
    $#FILEWWW=0;
				# ------------------------------
                  		# read directory (now is local:
				#    see chdir before calling!
    open($fhinLoc,"find . -print |");
    while (<$fhinLoc>){
	$_=~s/\s|\n//g;
				# purge dirIn
	$file=$_;
	next if (length($file) <= 1);
				# skip emacs temporary
	next if ($file=~/[~]$/);
				# purge path
	$file=~s/^\s*\.\///g;
				# exclude some
	next if ($file=~/^(aw|stat|mis|Var|Djunk|Local|MAT|tmp)/);
				# exclude wwwServices (is redirect, anyway)
	next if ($file=~/^wwwService/);
				# exclude pp and cubic
	next if ($file=~/^(cubic|pp)\//);
				# exclude links
	next if (-l $file);

	$tmp=$file;$tmp=~s/^(.*\/)[^\/]*$/$1/g;
				# exclude linked dirs
	next if (-l $tmp);

#	next if (-d $file);
	next if ($file eq ".");
				# avoid duplication
	next if (defined $filewww{$file});
	$filewww{$file}=1;
	push(@FILEWWW,$file);}
    close($fhinLoc);
				# ------------------------------
				# find newest
    if (-e $fileLog){		# ini
	$age=   -M $fileLog;
	$newest=$age;}
    else {
	$age=   -M $FILEWWW[1]; 
	$newest=$FILEWWW[1];}

    for $file (@FILEWWW) {
	$fileLocation=$file;
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
sub tarMakeOriginal {
    local($cmdTarLoc,$fileTarLoc,$nfilesMax,$dirWorkLoc,$dirTarNewLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   tarMakeOriginal                     cd-s to dirLoc and makes tar fileTarLoc from @file
#       in:                     $cmdTar=     command to run tar
#       in:                     $dirDelLoc=  path to delete from file (/home/rost/)
#       in:                     $dirInLoc=   path of original input (/home/rost/public_html/)
#       in:                     $fileTarLoc= name of output tar file
#       in:                     $nfilesMax=  maximal number of files to tar in one go
#       in:                     $dirWorkLoc= dir in which everything will be done
#       in:                     $dirTarNewLoc= dir into which everything will be written
#       in GLOBAL:              @FILEWWW=    all files from WWWdoc dir
#       out:                    
#-------------------------------------------------------------------------------
    $sbrName="tarMakeOriginal";$fhinLoc="FHIN"."$sbrName";
				# ------------------------------
    if (-e $fileTarLoc){	# if existing: remove
	print "-*- WARN $scrName existing file $fileTarLoc\n";
	unlink($fileTarLoc);	} # delete old

				# ------------------------------
				# create tar archive
    $numRepeat=1+int($#FILEWWW/$nfilesMax);
    $cmdTarRepeat=$cmdTarLoc;$cmdTarRepeat=~s/\-c/\-r/;

    foreach $it (1..$numRepeat){
	$itBeg=1+($it-1)*$nfilesMax;
	$itEnd=$itBeg+$nfilesMax-1; 
	$itEnd=$#FILEWWW        if ($#FILEWWW<$itEnd);
	
	$tmp=join(' ',@FILEWWW[$itBeg..$itEnd]);

	if ($it==1){                # first time: generate tar
	    print "--- $scrName $cmdTarLoc $fileTarLoc (files $itBeg - $itEnd)\n";
	    $command="$cmdTarLoc $fileTarLoc $tmp";
	    $Lok=`$command`;
	}
	else {                      # then: append
	    die 
		"*** ERROR $scrName: want to run:\n",
		"    $cmdTarRepeat $fileTarLoc (files $itBeg - $itEnd)\n",
		"*** however, fileTarLoc=$fileTarLoc NOT existing!!\n"
		    if (! -e $fileTarLoc);
	    print "--- $scrName $cmdTarRepeat $fileTarLoc (files $itBeg - $itEnd)\n";
	    $command="$cmdTarRepeat $fileTarLoc $tmp";
	    $Lok=`$command`;
	}
    }
    
    return(0,"*** ERROR $sbrName: tar failed\n")
	if (! -e $fileTarLoc);

    print "--- $scrName: output in $fileTarLoc\n";
				# ------------------------------
				# verify reading
    @tmp=`/usr/bin/tar -tf $fileTarLoc`;
    print "--- $scrName: verify found $#tmp files, expected was: ",$#FILEWWW," (is ok ..)\n";

    return(1,"ok $sbrName");
}				# end of tarMakeOriginal

#===============================================================================
sub tarExtrTmp {
    local($cmdTarLoc,$fileTarLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   tarExtrTmp                  cd-s to dirLoc and makes tar fileTarLoc from @file
#       in:                     $cmdTar=     command to run tar
#       in:                     $dirDelLoc=  path to delete from file (/home/rost/)
#       in:                     $dirInLoc=   path of original input (/home/rost/public_html/)
#       in:                     $fileTarLoc= name of output tar file
#       in:                     $nfilesMax=  maximal number of files to tar in one go
#       in:                     $dirWorkLoc= dir in which everything will be done
#       in:                     $dirTarNewLoc= dir into which everything will be written
#       in GLOBAL:              @FILEWWW=    all files from WWWdoc dir
#       out:                    
#-------------------------------------------------------------------------------
    $sbrName="tarExtrTmp";
    $cmdTarLoc=~s/\-c/\-x/;
    print "--- $cmdTarLoc $fileTarLoc\n";

    $command="$cmdTarLoc $fileTarLoc";
    $Lok=`$command`;
    
    return(0,"*** ERROR $sbrName: tar failed\n")
	if (! -e $fileTarLoc);
    return(1,"ok $sbrName");
}				# end of tarExtrTmp

#===============================================================================
sub tarMakeNew {
    local($cmdTarLoc,$fileTarLoc,$nfilesMax,$dirWorkLoc,$dirTarNewLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   tarMakeNew                  cd-s to dirLoc and makes tar fileTarLoc from @file
#       in:                     $cmdTar=     command to run tar
#       in:                     $dirDelLoc=  path to delete from file (/home/rost/)
#       in:                     $dirInLoc=   path of original input (/home/rost/public_html/)
#       in:                     $fileTarLoc= name of output tar file
#       in:                     $nfilesMax=  maximal number of files to tar in one go
#       in:                     $dirWorkLoc= dir in which everything will be done
#       in:                     $dirTarNewLoc= dir into which everything will be written
#       in GLOBAL:              @FILEWWW=    all files from WWWdoc dir
#       out:                    
#-------------------------------------------------------------------------------
    $sbrName="tarMakeNew";$fhinLoc="FHIN"."$sbrName";

				# purge '/home/rost/pub/cron/tmp/' from path
    $dirRelative=$dirTarNewLoc; 
    $dirRelative=~s/$dirWorkLoc//g;
				# ------------------------------
    $#file=0;			# read directory (now is local:
				#    see chdir before calling!
    open($fhinLoc,"find $dirRelative -print |");
    while (<$fhinLoc>){
	$_=~s/\s//g;
	push(@file,$_);}
    close($fhinLoc);
				# ------------------------------
				# create tar archive
    $numRepeat=1+int($#file/$nfilesMax);
    $cmdTarRepeat=$cmdTarLoc;$cmdTarRepeat=~s/\-c/\-r/;

    foreach $it (1..$numRepeat){
	$itBeg=1+($it-1)*$nfilesMax;
	$itEnd=$itBeg+$nfilesMax-1; 
	$itEnd=$#file           if ($#file<$itEnd);
	
	$tmp=join(' ',@file[$itBeg..$itEnd]);

	if ($it==1){                # first time: generate tar
	    print "--- $cmdTarLoc $fileTarLoc (files $itBeg - $itEnd)\n";
	    $command="$cmdTarLoc $fileTarLoc $tmp";
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

    print "--- output in $fileTarLoc (now with relative dir=$dirRelative)\n";
				# ------------------------------
				# verify reading
    @tmp=`/usr/bin/tar -tf $fileTarLoc`;
    print "--- verify found $#tmp files, expected was: ",$#file,"\n";

    $#tmp=$#file=0;
    return(1,"ok $sbrName");
}				# end of tarMakeNew 

#===============================================================================
sub updateCUBIClinks {
    local($dirCUBIClinksLoc,$preCUBIClinksLoc,$dirBRlinksLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   updateCUBIClinks            copies the CUBIC www links html pages to BR
#       in:                     dirCUBIClinksLoc: directory where to get the CUBIC links
#       in:                     preCUBIClinksLoc: names of files start with 'pre'
#       in:                     dirBRlinksLoc:    directory where to put the CUBIC links
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."updateCUBIClinks";
				# check arguments
    return(&errSbr("not def dirCUBIClinksLoc!")) if (! defined $dirCUBIClinksLoc);
    return(&errSbr("not def preCUBIClinksLoc!")) if (! defined $preCUBIClinksLoc);
    return(&errSbr("not def dirBRlinksLoc!"))    if (! defined $dirBRlinksLoc);

    $dirCUBIClinksLoc=~s/\/$//g;
    $dirBRlinksLoc.="/"         if ($dirBRlinksLoc !~/\/$/);

    $fhinLoc="FHIN_DIR";
				# ------------------------------
    $#cubic=0;			# read directory CUBIC
    open($fhinLoc,"find $dirCUBIClinksLoc -follow -print |");
    while (<$fhinLoc>){
	next if ($_!~/$preCUBIClinksLoc/);
	$_=~s/\s//g;
	push(@cubic,$_);
    }
    close($fhinLoc);
    foreach $file (@cubic){
	$naked=$file; $naked=~s/^.*\///g; # purge path
	$fileBR=$dirBRlinksLoc.$naked;
				# do not copy if exist or same date
	next if (-e $fileBR &&
		 (-M $fileBR) <= (-M $file));
				# otherwise: update
	system("\\cp $file $fileBR");
    }

    return(1,"ok $sbrName");
}				# end of updateCUBIClinks


#===============================================================================
sub updateCUBICpapers {
    local($dirCUBICpaperLoc,$dirBRpaperLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   updateCUBICpapers           copies the CUBIC www paper html pages to BR
#       in:                     dirCUBICpaperLoc: directory where to get the CUBIC paper
#       in:                     dirBRpaperLoc:    directory where to put the CUBIC paper
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."updateCUBICpapers";
				# check arguments
    return(&errSbr("not def dirCUBICpaperLoc!")) if (! defined $dirCUBICpaperLoc);
    return(&errSbr("not def dirBRpaperLoc!"))    if (! defined $dirBRpaperLoc);

    $dirCUBICpaperLoc=~s/\/$//g;
    $dirBRpaperLoc=~s/\/$//g;

    $fhinLoc="FHIN_DIR";
				# ------------------------------
    $#cubic=0;			# read directory CUBIC
    open($fhinLoc,"find $dirCUBICpaperLoc -follow -print |");
    while (<$fhinLoc>){
	$_=~s/\s//g;
	next if (! -e $_);
				# purge temporary stuff
	next if ($_ !~ /abstract/ &&
		 $_ !~ /19\d\d/ &&
		 $_ !~ /20\d\d/);
	push(@cubic,$_);
    }
    close($fhinLoc);
    foreach $file (@cubic){
				# directory (make if missing)
	if (-d $file) {
	    $dirBR=$file;
	    $dirBR=~s/$dirCUBICpaperLoc/$dirBRpaperLoc/;
	    $dirBR=~s/\/$//g;
	    next if (-d $dirBR);
	    $dirBR=~s/\/$//g;
	    print "--- $sbrName: system 'mkdir $dirBR'\n";
	    system("mkdir $dirBR"); }
				# is file: copy if newer
	else {
	    $fileBR=$file; $fileBR=~s/$dirCUBICpaperLoc/$dirBRpaperLoc/;
				# do not copy if exist or same date
	    next if (-e $fileBR &&
		     (-M $fileBR) <= (-M $file));
				# otherwise: update
	    print "--- $sbrName: system 'cp $file $fileBR'\n";
	    system("\\cp $file $fileBR");
	}
    }
    return(1,"ok $sbrName");
}				# end of updateCUBICpapers


