#!/usr/bin/perl
#
$scriptName=$0;$scriptName=~s/^.*\/|\.pl//g;
#  
#  does a tar on a directory for which argument list is too long
#
$[ =1 ;

$cmdTar="tar -cvf";
$par{"nmax"}=1000;
$par{"nmax"}=500;
				# help
if ($#ARGV<2){print "goal:    does a tar on a directory for which argument list is too long\n";
	      print "usage:   'script file.tar dir' (dir ='.' for current, files also as *file)\n";
	      print "  or:    'script [tape|dat] dir'\n";
	      print "  or:    'script [tape|dat] file_with_list.list'\n";
	      print "options: pat=x       (pattern to be matched in file list)\n";
	      print "         dev=x       (default file, alternative tape=/dev/tape, dat=/dev/dat)\n";
	      print "         nmax=x      (maximal number of files in one go: SGI specific)\n";
	      print "         dbg         (no verification and 'tar -cf' instead of 'tar -cvf')\n";
	      exit;}
				# command line
$fileList=0;
$#fileIn=0; $Ldebug=0;

$fileTar=$ARGV[1];
$dirIn=  $ARGV[2]; $dirIn=~s/^(dirIn|dir)=//i;
if (-e $dirIn && $dirIn =~/list$/){
    $fileList=$dirIn;
    $dirIn=".";}

foreach $_(@ARGV){
    next if ($_ eq $ARGV[1]);
    next if ($_ eq $ARGV[2]);
    if    ($_=~/^pat=(.*)$/)    { $pat=        $1;}
    elsif ($_=~/^dev=(.*)$/)    { $dev=        $1;}
    elsif ($_=~/^nmax=(.*)$/)   { $par{"nmax"}=$1;}
    elsif (-e $_ && $_=~/list$/){ $fileList=   $_;}

    elsif (-e $_)               { push(@fileIn,$_);}
    elsif ($_=~/^de?bu?g$/)     { $Ldebug=     1;}
    else { print"*** wrong command line arg '$_'\n";
	   die;}}

				# check
$PWD=$ENV{'PWD'}    if (defined $ENV{'PWD'});
$PWD=`pwd`          if (! defined $PWD || ! -d $PWD);

$dirIn=$PWD         if ($dirIn eq "." && defined $PWD && -d $PWD);
$pat=""             if (! defined $pat);
# 
$dev="/dev/tape"    if ((defined $dev && $dev eq "tape") || $fileTar eq "tape");
$dev="/dev/dat"     if ((defined $dev && $dev eq "dat" ) || $fileTar eq "dat");

				# correct verbose
$cmdTar=~s/cvf/cf/              if (! $Ldebug);

				# version 1: is directory
$mode="dir";
$mode="file"                    if ($fileList);

if ($mode eq "dir" &&
    ! -d $dirIn && $#fileIn < 1 ) {
    print "*** dirIn=$dirIn, not existing, and no file given on command line\n";
#    die;
}

if ($fileList){
    open($fhin,$fileList) || die "*** $scrName ERROR opening fileList=$fileList!";
    while (<$fhin>) {
	$_=~s/\n//g;
	push(@fileIn,$_);
    }
    close($fhin);}

if ($#fileIn>0){
    @file=@fileIn;}
else {				# list all files (should be local after chdir)
    @file=&fileLsAll($dirIn);
}


#$Lbeg=$Lend=0;
#if ($pat=~/[\^]/)  {$pat=~s/[\^]//;$Lbeg=1;}
#if ($pat=~/[\$]/)  {$pat=~s/[\$]//;$Lend=1;}

				# ------------------------------
				# remove path if and only if '/dir/..'
if    ($fileList){
    $LremovePath=0;}
elsif (defined $dirIn && length($dirIn)>0 && $dirIn =~ /^\//){
    $LremovePath=1;
    $dirInTmp=$dirIn; $dirInTmp.="/" if ($dirInTmp !~/\/$/);}
else {
    $LremovePath=0;}

				# ------------------------------
				# filter those not matching pattern
$#tmp=0;
foreach $file (@file){
    $tmp=$file;
    $tmp=~s/$dirInTmp//g if (defined $dirInTmp && length($dirInTmp)>0 && $LremovePath);
    next if (length($tmp)<1);
    next if ($tmp =~/\// && $LremovePath); # skip if subdirectory
    next if (length($pat)>0 && 
	     $file !~ /$pat/);
#     next if ($Lbeg && $file !~/^$pat/);
#     next if ($Lend && $file !~/$pat$/);
#     next if (! $Lbeg && ! $Lend && $file !~ /$pat/);
    push(@tmp,$tmp) if (-e $file || -l $file);
}
$#file=0;
@file=@tmp;
				# ------------------------------
				# remove path from tar file
				#    note: for list with '/dir/file'
				#          NOT for       'dir/file'
if ($LremovePath){
    $fileTar=~s/^.*\///g;
    $fileTar=$PWD."/".$fileTar      if (defined $PWD && -d $PWD);
    $fileTar="tared-file".$$.".tar" if (length($fileTar)<5);
				# go to directory to be tared
    $Lok=chdir($dirIn);
    die ("*** ERROR $scrName could not change dir to '$dirIn'\n") if (!$Lok);}

				# ------------------------------
				# do the tar
$numRepeat=1+int($#file/$par{"nmax"});
$cmdTarRepeat=$cmdTar;$cmdTarRepeat=~s/\-c/\-r/;
foreach $it (1..$numRepeat){
    $itBeg=1+($it-1)*$par{"nmax"};
    $itEnd=$itBeg+$par{"nmax"}-1; $itEnd=$#file if ($#file<$itEnd);

    $tmp=join(' ',@file[$itBeg..$itEnd]);

    if ($it==1){                # first time: generate tar
	if (1){
	    $perc=100*(1-$itBeg/$#file);
	    $perc=~s/(\...).*$/$1/g;
	    ($Lok,$tmp,$txt)=
		&fctRunTimeFancy($dirIn,$perc,1);
	    print $txt;
	}
	else {
	    print "--- $cmdTar $fileTar (files $itBeg - $itEnd)\n";
	}
        system("$cmdTar $fileTar $tmp");
    }
    else {                      # then: append
	if (1){
	    $perc=100*(1-$itBeg/$#file);
	    $perc=~s/(\...).*$/$1/g;
	    ($Lok,$tmp,$txt)=
		&fctRunTimeFancy($dirIn,$perc,1);
	    print $txt;
	}
	else {
	    print "--- $cmdTarRepeat $fileTar (files $itBeg - $itEnd)\n";
	}
        system("$cmdTarRepeat $fileTar $tmp");
    }
}

				# ------------------------------
				# end here if not debug
if (! $Ldebug) {
    print "--- no verification, since no debug mode\n";
    exit;}


print "--- output in $fileTar\n";
				# ------------------------------
				# verify reading
@tmp=`tar -tf $fileTar`;

print "--- output in $fileTar\n";
print "--- verify found $#tmp files, expected was: ",$#file,"\n";

$file="VERIFY-bup-OS2.tmp"; 
open("FHOUT",">$file");foreach $tmp(@tmp){$tmp=~s/\n|\r//g;print FHOUT "$tmp\n";}close(FHOUT);
print "--- output from verify into $file\n";


exit;


#===============================================================================
sub fctRunTimeFancy {
    local($nameLoc,$percLoc,$LdoTimeLoc) = @_ ;
    local($sbrName,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   fctRunTimeFancy             fancy way to write run time estimate
#       NEED:                   &fctSeconds2time
#       GLOBAL in/out:          $timeBegLoc
#                               
#       in:                     $nameLoc=    name of directory or file or job
#       in:                     $percLoc=    percentage of job done so far
#       in:                     $LdoTimeLoc= 1-> estimate remaining runtime
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."fctRunTimeFancy";
				# check arguments
    return(&errSbr("not def nameLoc!")) if (! defined $nameLoc);
    return(&errSbr("not def percLoc!")) if (! defined $percLoc);
    $LdoTimeLoc=0                       if (! defined $LdoTimeLoc);
#    return(&errSbr("not def !"))          if (! defined $);

				# local parameter
#    $par{"fctRunTimeFancy","maxdot"}=72 if (! defined $par{"fctRunTimeFancy","maxdot"});
    $par{"fctRunTimeFancy","maxdot"}=60 if (! defined $par{"fctRunTimeFancy","maxdot"});
    $tmpformatLoc="%-".$par{"fctRunTimeFancy","maxdot"}."s"
	if (! defined $tmpformatLoc);

    $nameLoc=~s/\/$//g;
    $nameLoc=~s/^.*\///g;
    $tmpdots=int((100-$percLoc)*$par{"fctRunTimeFancy","maxdot"}/100);

				# estimate remaining run time?
    if ($LdoTimeLoc){
	$timeNowLoc=time;
	$timeBegLoc=$timeBeg    if (! defined $timeBegLoc && defined $timeBeg);
	$timeBegLoc=0           if (! defined $timeBegLoc);
	$timeRunLoc=$timeNowLoc-$timeBegLoc;

	if ($percLoc>0 && $timeNowLoc ne $timeBegLoc) {
	    $timeTotLoc=int($timeRunLoc*100/(100-$percLoc));
	    $timeLeftLoc=$timeTotLoc-$timeRunLoc;
	    $timeTxtLoc=
		&fctSeconds2time($timeLeftLoc); 
				# remove leading 0h 0m if perc < 20
	    if    ($percLoc > 80 && $timeTxtLoc=~/^0+\:0+\:/){
		$Lpurge_timehm_loc=1;
		$timeTxtLoc=~s/^0+\:0+\://g;}
				# remove leading 0h 0m if perc < 20
	    elsif ($percLoc > 80 && $timeTxtLoc=~/^0+\:/){
		$Lpurge_timeh_loc=1;
		$timeTxtLoc=~s/^0+\://g;}
	    elsif (defined $Lpurge_timehm_loc && $Lpurge_timehm_loc){
		$timeTxtLoc=~s/^0+\:0+\://g;}
	    elsif (defined $Lpurge_timeh_loc && $Lpurge_timeh_loc){
		$timeTxtLoc=~s/^0+\://g;}

	    @tmpLoc=split(/:/,$timeTxtLoc); 
	    foreach $tmp (@tmpLoc){
		$tmp=~s/^0//g;}
	    if    ($#tmpLoc==3){
		$tmptime=sprintf("%3s %3s%3s",
				 $tmpLoc[1]."h",$tmpLoc[2]."m",$tmpLoc[3]."s");}
	    elsif ($#tmpLoc==2){
		$tmptime=sprintf("%3s%3s",
				 $tmpLoc[1]."m",$tmpLoc[2]."s");}
	    elsif ($#tmpLoc==1){
		$tmptime=sprintf("%3s",
				 $tmpLoc[1]."s");}
	    else {
		$tmptime=$timeTxtLoc;}
	}
	elsif ($percLoc==0) {
	    $tmptime="done";
	}
	else {
	    $tmptime="??";
	}
    }
    else {
	$tmptime="";}
				# write
    $tmp=
	sprintf("%-15s %3d%-1s |".$tmpformatLoc."| %-s\n",
		substr($nameLoc,1,15),
		int($percLoc),
		"%",
		"*" x $tmpdots,
		$tmptime
		);
    return(1,"ok $sbrName",$tmp);
}				# end of fctRunTimeFancy

#===============================================================================
sub fctSeconds2time {
    local($secIn) = @_ ;
    local($sbrName,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   fctSeconds2time             converts seconds to hours:minutes:seconds
#       in:                     seconds
#       out:                    05:13:50
#-------------------------------------------------------------------------------
    $sbrName="lib-comp:"."fctSeconds2time";
    $minTmp=  int($secIn/60);
    $seconds= ($secIn - $minTmp*60); $seconds=int($seconds);
    $hours=   int($minTmp/60);       $hours=  int($hours);
    $minutes= ($minTmp - $hours*60); $minutes=int($minutes);

    $seconds="0".$seconds if (length($seconds)==1);
    $minutes="0".$minutes if (length($minutes)==1);
    $hours=  "0".$hours   if (length($hours)==1);
    return("$hours".":".$minutes.":".$seconds);
}				# end of fctSeconds2time

#==========================================================================================
sub fileLsAll {
    local($dirLoc) = @_ ;local($sbrName,$fhinLoc,@tmp);
#--------------------------------------------------------------------------------
#   dirLsAll                    will return all directories in dirLoc (and
#                               subdirectories therof)
#       in:                     dirLoc (directory)
#       out:                    @files
#--------------------------------------------------------------------------------
    if (! defined $dirLoc || $dirLoc eq "." || 
	length($dirLoc)==0 || $dirLoc eq " " || ! $dirLoc){
	if (defined $ENV{'PWD'}){
	    $dirLoc=$ENV{'PWD'}; }
	else {
	    $dirLoc=`pwd`; } }
				# directory missing/empty
    return(0)                   if (! -d $dirLoc || ! defined $dirLoc || $dirLoc eq "." || 
				    length($dirLoc)==0 || $dirLoc eq " " || ! $dirLoc);
				# ok, now do
    $sbrName="fileLsAll";$fhinLoc="FHIN"."$sbrName";
				# ------------------------------
				# read dir
    open($fhinLoc,"find $dirLoc -print |");
    while (<$fhinLoc>){$_=~s/\s//g; 
		       next if ($_=~/\$/);
				# avoid reading subdirectories
		       $tmp=$_;$tmp=~s/$dirLoc//g;$tmp=~s/^\///g;
#		       next if ($tmp=~/^\//);
		       next if (-d $_);
		       push(@tmp,$_);}close($fhinLoc);
    return(@tmp);
}				# end of dirLsAll

