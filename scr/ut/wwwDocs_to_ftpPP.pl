#!/usr/local/bin/perl -w
##!/usr/sbin/perl4 -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
				# defaults (1)
				# CUBIC
$dirFtp=       "/home/ftp/pub/phd/";             # HARD_CODED
$dirWork=      "/home/$ENV{USER}/server/work/";         # HARD_CODED
$dirPPdoc=     "/home/$ENV{USER}/public_html/";         # HARD_CODED
$dirPPdoc=     "/home/$ENV{USER}/predictprotein/";      # HARD_CODED

				# to copy every day
$dirCUBIClinks="/home/cubic/public_html/doc/";   # HARD_CODED
$preCUBIClinks="links_";                         # HARD_CODED
$dirPPlinks=   "/home/$ENV{USER}/public_html/doc/";     # HARD_CODED

				# EMBL
#$dirFtp=       "/usr/people/ftp/pub/exchange/rost/pp/";
#$dirWork=      "/junk/rost/bup/";
#$dirPPdoc=     "/home/www/htdocs/Services/sander/predictprotein/";
				# general
$dirLog=       "/home/$ENV{USER}/server/log/";          # HARD_CODED
$fileLog=      $dirLog. "wwwMirrorHtdoc.log";    # HARD_CODED
$fileCronLog=  $dirLog. "cronExe.log";           # HARD_CODED
$fileTmpLog=   $dirLog. "SCREEN-$scrName.log";   # HARD_CODED
$fileTar=      $dirWork."wwwPP.tar";             # HARD_CODED
$fileTarFin=   $fileTar; $fileTarFin=~s/$dirWork/$dirFtp/;

$scrGoal=
    "copy PP home pages to ftp-able site (DO ON parrot)\n".
    "     \t note: currently to parrot: $fileTarFin\n".
    "     \t       log files of action: $dirLog\n";
#  
#
$[ =1 ;
				# ------------------------------
if ($#ARGV<1){			# help
    print "goal:\t $scrGoal\n";
    print "use: \t '$scrName <dir_with_pp_www_docs|auto>'\n";
    print "     \t           'auto' assumes directory is $dirPPdoc\n";
    print "opt: \t log=x   name of log file to report the action\n";
    print "     \t out=x   name of tared pages\n";
    print "     \t nozip   (default will gzip on final tar)\n" ;
    print "     \t verbose (dont redirect output)\n";
    print "     \t dbg     all messages to STDOUT\n";
    exit;}
				# ------------------------------
				# initialise variables

#$cmdTar=     "/usr/bin/tar -cvfL";
$cmdTar=     "/usr/bin/tar -cvfL";
#$cmdUntar=   "tar -xvf";
#$cmdRsh=     "rsh phenix";	# note: ftp only on phenix!
$cmdRsh=     0;			# no rsh
$cmdZip=     "gzip";
$Lzip=       1;
$Lverb=      0;
$Ldebug=     0;
#$Lverb=      1;
				# ------------------------------
$dirIn=$ARGV[1];		# read command line
$dirIn=$dirPPdoc                if ($dirIn =~/^auto$/i);
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
				# --------------------------------------------------
				# update the WWW links pages
				# --------------------------------------------------
($Lok,$msg)=
    &updateWWWlinks($dirCUBIClinks,$preCUBIClinks,$dirPPlinks);

				# --------------------------------------------------
				# NOW back to the WWW update of PP
				# --------------------------------------------------

				# get current date
#@date=split(' ',&ctime(time)); shift(@date); 
#$dayHere=$date[2],$monHere=&month2num($date[1]);$yearHere=$date[$#date];
#$dateHere="$dayHere-$monHere-$yearHere"; # Feb-3-1998 -> '3-2-1998'

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
($Lok,$msg)=
    &makeTar($dirDel,$fileTar,@filePP);
				# ******************************
				# fatal ERROR
if (! $Lok) { print "*** ERROR $scrName: failed on makeTar (dirDel=$dirDel, fileTar=$fileTar)\n";
	      print "*** msg=\n",$msg,"\n";
	      die; }

				# ------------------------------
				# zip
if ($Lzip){
    $fileZip=$fileTar.".gz";
    unlink($fileZip)            if (-e $fileZip);
    $command="$cmdZip $fileTar"; print "--- $scrName system \t '$command'\n";
    $Lok=`$command`;
#    $fileZip=`ls $fileTar*`;
    print "--- $scrName after zip name=$fileZip,\n";}
else{
    $fileZip=$fileTar;}
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

print "--- output in $fileTar ($fin) right? \n";
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
    open($fhinLoc,"find $dirIn -follow -print |");
    while (<$fhinLoc>){
	$_=~s/\s//g;$_=~s/$dirDel//g;$file=$_;
#	$_=~s/\s//g;$_=~s/$dirIn//g;
	$_=~s/$dirRel//;$_=~s/^\///;
				# exclude br stuff
	next if ($_=~/br\/(Res|Pap|Dicon|Var|tmp)/);
				# avoid dirs
	next if ($_=~/(br|casp|Var|scr|style|doc)$/);
				# excl MAT
	next if ($_=~/MAT|STAT/);
				# exclude wwwServices (is redirect, anyway)
	next if ($file=~/^wwwService/);

	next if ($_=~/^D/ && $_!~/\//);
	next if (length($_)<2 || $_=~/^[\.]|~$/ || 
		 (! -e $dirDel.$file && ! -l $dirDel.$file) ||
		 ($_=~/(old|new|STAT|wusage|tmp|bup|xx|READ|List|PP|hack)/
		  && $_ !~/icon/));
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

    return(0,"*** ERROR $scrName couldnot change dir to $dirLoc\n")
	if (! $Lok);
				# ------------------------------
    if (-e $fileTarLoc){	# if existing: remove
	print "-*- WARNING $scrName existing file $fileTarLoc\n";
	unlink("$fileTarLoc");	} # delete old

				# ------------------------------
				# create tar archive
    $files= join (' ',@fileLoc);
    
    $command="$cmdTar $fileTarLoc $files\n";
    print "--- $sbrName system \t '$command'\n";
    $Lok=`$command`;
    return(0,"*** ERROR $sbrName: tar failed\n")
	if (! -e $fileTarLoc);
    return(1,"ok $sbrName");
}				# end of makeTar

#===============================================================================
sub updateWWWlinks {
    local($dirCUBIClinksLoc,$preCUBIClinksLoc,$dirPPlinksLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   updateWWWlinks              copies the CUBIC www links html pages to PP
#       in:                     dirCUBIClinksLoc: directory where to get the CUBIC links
#       in:                     preCUBIClinksLoc: names of files start with 'pre'
#       in:                     dirPPlinksLoc:    directory where to put the CUBIC links
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."updateWWWlinks";
				# check arguments
    return(&errSbr("not def dirCUBIClinksLoc!")) if (! defined $dirCUBIClinksLoc);
    return(&errSbr("not def preCUBIClinksLoc!")) if (! defined $preCUBIClinksLoc);
    return(&errSbr("not def dirPPlinksLoc!"))    if (! defined $dirPPlinksLoc);

    $dirCUBIClinksLoc=~s/\/$//g;
    $dirPPlinksLoc.="/"         if ($dirPPlinksLoc !~/\/$/);

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
	$filePP=$dirPPlinksLoc.$naked;
				# do not copy if exist or same date
	next if (-e $filePP &&
		 (-M $filePP) <= (-M $file));
				# otherwise: update
	system("\\cp $file $filePP");
    }

    return(1,"ok $sbrName");
}				# end of updateWWWlinks


#================================================================================ #
#                                                                                 #
#-------------------------------------------------------------------------------- #
# Predict Protein - a secondary structure prediction and sequence analysis system #
# Copyright (C) <2004> CUBIC, Columbia University                                 #
#                                                                                 #
# Burkhard Rost         rost@columbia.edu                                         #
# http://cubic.bioc.columbia.edu/~rost/                                           #
# Jinfeng Liu             liu@cubic.bioc.columbia.edu                             #
# Guy Yachdav         yachdav@cubic.bioc.columbia.edu                             #
#                                                                                 #
# This program is free software; you can redistribute it and/or modify it under   #
# the terms of the GNU General Public License as published by the Free Software   #
# Foundation; either version 2 of the License, or (at your option)                #
# any later version.                                                              #
#                                                                                 #
# This program is distributed in the hope that it will be useful,                 #
# but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY  #
# or FITNESS FOR A PARTICULAR PURPOSE.                                            #
# See the GNU General Public License for more details.                            #
#                                                                                 #
# You should have received a copy of the GNU General Public License along with    #
# this program; if not, write to the Free Software Foundation, Inc.,              #
# 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA                         #
#                                                                                 #
# Contact Information:                                                            #
#                                                                                 #
# predict_help@columbia.edu                                                       #
#                                                                                 #
# CUBIC   Columbia University                                                     #
# Department of Biochemistry & Molecular Biophysics                               #
# 630 West, 168 Street, BB217                                                     #
# New York, N.Y. 10032 USA                                                        #
# Tel +1-212-305 4018 / Fax +1-212-305 7932                                       #
#================================================================================ #
