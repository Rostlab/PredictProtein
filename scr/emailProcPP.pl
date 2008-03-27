#!/usr/local/bin/perl -w
##!/usr/pub/bin/perl5 -w
##!/usr/pub/bin/perl5.003 -w
##!/usr/pub/bin/perl -w
#================================================================================ #
#                                                                                 #
#-------------------------------------------------------------------------------- #
# Predict Protein - a secondary structure prediction and sequence analysis system # 
# Copyright (C) <2004> CUBIC, Columbia University                                 #
#                                                                                 #
# Burkhard Rost		rost@columbia.edu			                  #
# http://cubic.bioc.columbia.edu/~rost/	                                          #
# Jinfeng Liu             liu@cubic.bioc.columbia.edu  	                          #
# Guy Yachdav         yachdav@cubic.bioc.columbia.edu        	                  #
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
#------------------------------------------------------------------------------   #
#	Copyright				        	1999	          #
#	Burkhard Rost		rost@EMBL-Heidelberg.DE			          #
#	Wilckensstr. 15		http://www.embl-heidelberg.de/~rost/	          #
#	D-69120 Heidelberg						          #
#			        v 1.0             Dec,          1994              #
#			        v 1.5             Mar,          1997              #
#			        v 2.0   	  Apr,          1998              #
#			        v 2.1             May,          1998              #
#			        v 2.2             Jan,          1999              #
#------------------------------------------------------------------------------   #
#
#    This script is called when an e-mail request is submitted.
#
#    This script processes the single mail output from PROCMAIL to make it 
#       fit as input to predictPP.pl.
#    It is called by scannerPP.pl (with the name of the file name written 
#       by PROCMAIL).
# 
#    input:  file from PROCMAIL
#    output: processed version of input file
#            -> input to predictPP.pl
#    
#    
#    ------------------------------
#    command line argument(s)
#    ------------------------------
#      
#    file_from_procmail <dbg> <fileOut=output_file>
#      
#    1st obligatory: input file (dump of mail from PROCMAIL)
#    other optional: 'dbg'     for debug mode
#                    'fileOut=file' name of output file
#   
#    note:  
#                    fileOut     is the file with the final format, read by
#                       predictPP.pl
#
#------------------------------------------------------------------------------#

				# ------------------------------
$[ =1 ;				# start counting with 1

				# ------------------------------
($Lok,$msg)=			# get environment parameters
    &ini();

				# NOTE errors in ini!
$fileTrace=  "/home/$ENV{USER}/PANICK_emailProc.log.tmp" if (! defined $fileTrace);

if (! $Lok){ $msg="*** err=1\n".$msg if ($msg !~ /err\=help/);
				# no MAIL!!
#	     &ctrlAbort($msg);
	     ($Lok=open(APPEND,">>".$fileTrace)) ||
		 system("echo '$msg' >> $fileTrace");
	     if ($Lok) {
		 print APPEND $msg,"\n";
		 close(APPEND); }
	     print $msg,"\n";
	     die("$msg"); }
				# ------------------------------
				# in case of errors: move input
				#    file here!
				# ------------------------------
$dirErrMail=$envPP{"dir_bup_errMail"};
if (! -d $dirErrMail) {
    system("mkdir $dirErrMail");
    print "--- $scrName: system 'mkdir $dirErrMail' (dirErrMail)\n" if ($Ldebug); }

				# --------------------------------------------------
				# (1) read PROCMAIL file
				#     out GLOBAL : @procmailIn = full file read
				# --------------------------------------------------
if (! -e $fileIn) {		# security: check existence of file
    $msg="*** ERROR $scrName: input file=$fileIn (from PROCMAIL) missing!\n";
    print $msg;
    &ctrlAbort($msg); }

open ($fhin,$fileIn) || 
    do {     $msg="*** ERROR $scrName: failed to open input file=$fileIn (from PROCMAIL)!\n";
	     print $msg;
	     &ctrlAbort($msg); } ;
while (<$fhin>) {
    $_=~s/\n$//g;
    next if (! defined $_ || length($_)<1);
    push(@procmailIn,$_); }
close($fhin);

				# --------------------------------------------------
				# (2) process input
				# --------------------------------------------------
undef $user; undef $subj; undef $dateMail; undef $mach;
$user=$mach=$subj=$dateMail=$formatWant=0;

$#procmailProcess=0;
$Lbody=0;

foreach $line (@procmailIn){
    next if (! defined $line || length($line)<1);
				# ------------------------------
				# error: system sent: not known
    if ($line=~/[mM]essage\s.*undeliverable/){
	print "--- emailProcPP: (0) system error 'user unknown':",$line,"\n";
	&ctrlAbort("system sent 'user unknown'",0);}

				# ------------------------------
    $line=~s/\n//;		# purge EOF
				# ------------------------------
				# process header
    
				# (1) assume is line 'from=user, date=Sep 99,'
    if    ($line =~/^from=([^\s,]+\@[^\s,]+)[,\s]*(.*)$/) {
	$user=$1; 
	$tmp= $2; $tmp=~s/^\s*,\s*|\s*,*\s*$//g;
	@tmp=split(/,/,$tmp);
	foreach $tmp (@tmp) {
	    if    ($tmp=~/date=([^,]+)/) {
		$dateMail=$1; }
	    elsif ($tmp=~/subj=([^,]+)/) {
		$subj=$1; }
	    elsif ($tmp=~/mach=([^,]+)/) {
		$mach=$1; }}
				# failure ending with '.*'
	$user=0                 if ($user=~/\..$/);
				# failure ending with '.****'
	$user=0                 if ($user=~/\.[^\.][^\.][^\.][^\.]$/);
	print "--- emailProcPP: (1) user=$user\n" if ($Ldebug);
	next;}
				# real procmail entry 'From: <user>'
    elsif (! $user && $line =~/From\: .*\s?\<([^\>]*)\>/){
	$user=$1;
	print "--- emailProcPP: (2) user=$user\n" if ($Ldebug);
	next;}
				# for security first 'From user date'
    elsif (! $user && $line =~/^From[\s:]+\s*([^\s]+) (.+)$/){
	$user1=$1; $dateMail=$2;
	print "--- emailProcPP: (3) user=$user, date=$dateMail\n" if ($Ldebug);
	next;}
    elsif (! $mach && $line =~/Message-Id\:\s*\<[^\@]*\@([^\>]*)\>/i){
	$mach=$1;
	print "--- emailProcPP: (4) mach=$mach\n" if ($Ldebug);
	next;}
    elsif (! $subj && $line =~/Subject\:\s*(.*)$/){
	$subj=$1;
	$Lbody=1;
	print "--- emailProcPP: (5) subj=$subj\n" if ($Ldebug);
	next;}
    elsif ($line =~/^\s*Content\-/){
	$Lbody=1;
	next;}
				# br 99-03: hack begin after following
#    elsif ($line =~/^\s*To[\s:]*(phd|pp|predictprotein|predict\-help)[@|\s*$]/){
    elsif ($line =~/^\s*To[\s:]*(phd|pp|predictprotein|predict\-help)/){
	$Lbody=1;
	next;}
				# br 98-11: hack begin of content after following
    elsif (! $Lbody && $line =~/^\s*Apparently\-/){
	$Lbody=1;
	next;}
				# br 98-11: hack begin of content after following
#    elsif (! $Lbody && $line !~/^\s*[A-Za-z0-9\-]\s*:/){
#	$Lbody=1; }
    $tmp=$line;$tmp=~s/\s//g;
    next if (length($tmp)<1);	# empty line
    next if (! $Lbody);		# not info, yet
    print "--- $scrName: body in=$line\n" if ($Ldebug);
				# ------------------------------
				# process body
    push(@procmailProcess,$line);

				# requested to return HTML formatted output ?
    $formatWant="HTML"          if (! $formatSent && $line=~/ret html/i);
}

## Spam Block Code - GY 2003_09_05
## xx TODO needs to be fixed to allow options to be speicifed
#my $tmpCount = 1; my $flgValid=-1;
#foreach my $tmp(@procmailProcess){
#  if ($tmp=~s/^\W*(\w+\@\w+\.[a-z][a-z][a-z]*)\W/$1/g){
#    if (unpack("A1" , $procmailProcess[$tmpCount+1]) eq "#"){ 
#      $flgValid=0;
#      print  "--- $scrName: This is a valid message flagValid is $flgValid\n" if ($Ldebug);
#      last;
#    }
#  }
#  $tmpCount++;
#}

#if (( $flgValid !=0 ) || (!defined $flgValid)){
#    $msg="*** ERROR $scrName: email contents not formatted correctly. Probably spam\n";
#    print $msg if ($Ldebug);
#    system("\\mv $fileIn $dirErrMail") if (-d $dirErrMail); # xx
#    unlink($fileIn)             if (-e $fileIn && ! $Ldebug);
#    &ctrlAbort($msg);		
#}

#undef $tmpCount;  undef $flgValid;
## GY

				# default: send ASCII file
$formatWant="ASCII"             if (! $formatSent);


				# subject
$subj="no subject found"        if (! defined $subj);
if (! defined $dateMail) {
    $dateMail=$Date; 
    $dateMail=~s/\s/_/g; }
    $mach="no machine found"        if (! defined $mach);

				# --------------------------------------------------
				# (3) check email address (security)
				# --------------------------------------------------
$user=~s/\s//g                  if (defined $user);
				# use first from (mailer error?)
    $user=$user1                    if (! defined $user || length($user)<3);


if ($user =~ /^rost\@(localhost|parrot|dodo)$/) { 
    $user="rost\@columbia.edu";
    print "xxx sender rost -> rost.columbia (by force)!!!\n"; }

if ($user =~ /^rost_parrot/) { 
    $user="rost\@columbia.edu";
    print "xx $0 sender rost -> rost.columbia (by force)!!!\n"; }

				# local machines

$user.="\@columbia.edu"         if ($user !~/\@/ && $mach =~/embl/i);
$user.="\@columbia.edu"         if ($user !~/\@/ && 
				    $mach =~/(bb2rost|parrot).*\.columbia/i);
$user.="\@columbia.edu"         if ($user !~/\@/ && $mach =~/\.cpmc\.columbia/i);

				# ------------------------------
				# skip mailing errors
if ($user=~/^(phd|pp|predict|MAILER-DAEMON)/) {
    unlink($fileIn);
    &ctrlAbort("user ($user) is phd?? ($scrName)",0);}
    

				# search in file
if (! defined $user || $user !~/\@/){
    foreach $procmailProcess(@procmailProcess){
	if ($procmailProcess =~ /\@/){
	    $procmailProcess=~tr/[A-Z]/[a-z]/; # to lower caps
	    $tmp=$procmailProcess;$tmp=~s/^\W*(\w+\@\w+\.[a-z][a-z][a-z]*)\W/$1/g;
	    $user=$tmp;
	    last;}}}
				# ******************************
				# panick honkong 
				# ******************************
#if (defined $user && $user =~/\@.*ust\.hk/){
#    unlink($fileInLoc);
#    exit;}

				# ******************************
				# hack around crontab messages
				# ******************************
if (defined $user && $user =~/root\@/){
#    print "xx emailProc: 1 user=$user, (dirErrMail=$dirErrMail)\n";
    unlink($fileIn)             if (! $Ldebug);
    exit(1);}
				# ******************************
				# no correct address -> abort
				# ******************************
if (! defined $user || $user !~/\@/){
    $msg="*** $scrName unrecognised user from=$user, mach=$mach, err=2, READ:";
    foreach $it (1..10){	# write first 10 lines
	$msg.=$procmailIn[$it]."\n";}
    system("echo '$msg' >> $fileTrace");
				# error trace 
    system("\\mv $fileIn $dirErrMail") if (-d $dirErrMail); # xx
#    print "xx $0: 2 user=$user, (dirErrMail=$dirErrMail)\n";
    unlink($fileIn)             if (-e $fileIn && ! $Ldebug);
    &ctrlAbort($msg); }

				# ------------------------------
				# hack br 98-05: avoid loops
				# ------------------------------
if (! defined $user || $user =~/^phd\@/){
    $msg="*** $scrName input from user PHD???";
#    print "xx $0: 3 user=$user, (dirErrMail=$dirErrMail)\n";
    system("echo '$msg' >> $fileTrace");
				# trace of error
    system("\\mv $fileIn $dirErrMail") if (-d $dirErrMail); # xx
    unlink($fileIn)             if (-e $fileIn && ! $Ldebug);
    &ctrlAbort($msg); }
				# ------------------------------
				# hack br 99-04: hidden char?
				# ------------------------------
if ($user=~/[,\/]/) {
    $msg="*** $scrName input from user ($user)???";
    system("echo '$msg' >> $fileTrace");
				# trace of error
    system("\\mv $fileIn $dirErrMail") if (-d $dirErrMail); # xx
    unlink($fileIn)             if (-e $fileIn && ! $Ldebug);
    &ctrlAbort($msg); }
    
$user=~s/[^A-Z0-9a-z\.\-_\@]//g;
				# --------------------------------------------------
				# (4) build a new file for prediction
				#     MUST be in the working dir ..
				# --------------------------------------------------

if (! $fileOut) {		# name output file (only if not given on command line)
    $dirWork= $envPP{"dir_work"};
    $dirWork= $dirWork . "/"    if ($dirWork =~ /[^\/]$/ );
    $jobid=$fileIn; $jobid=~s/^.*\///g;$jobid=~s/\.pro.*$//g;
    $fileOut=$dirWork.$envPP{"par_patDirPred"}."e".$jobid; }

				# open new file
open($fhout,">".$fileOut) || 
    die ("*** ERROR $scrName: failed opening fileOut=$fileOut!\n");

				# security: if opening failed

				# NOTE: keep syntax of header, checked by:
				#       scannerPP.pl:scannerPredict:fileExtractHeader
print $fhout "PPhdr info: from=$user, date=$dateMail, mach=$mach, subj=$subj,\n";
				# sender
print $fhout "PPhdr from: $user\n";
				# response mode (MAIL|HTML)
print $fhout "PPhdr resp: MAIL\n";
				# origin of request
print $fhout "PPhdr orig: MAIL\n";
				# mirror mail subject, if given (def=unk)
print $fhout "PPhdr subj: $subj\n";
				# requested format of result
print $fhout "PPhdr want: $formatWant";

				# field for priority (one day!)
print $fhout "PPhdr prio: B\n";

foreach $line (@procmailProcess) {
    print $fhout $line,"\n"; 
}
close($fhout)                   if ($fhout ne "STDOUT"); 

				# ------------------------------
				# set access on the file
				# ------------------------------
system("chmod 666 $fileOut");	# system call
#system("chown phd $fileOut");	# system call

				# ------------------------------
				# move file into predict dir
				# ------------------------------
if (! $LfileNameGiven) {
    $dirPrd=$envPP{"dir_prd"};
    system("mkdir $dirPrd")         if (! -d $dirPrd);
    system("\\mv $fileOut $dirPrd"); } # system call

				# ------------------------------
				# log request in email-logfile
				# ------------------------------
$file_emailReqLog=$envPP{"file_emailReqLog"};

$short_name= $fileIn;   $short_name=~ s/.*\///;
$short_pred= $fileOut;  $short_pred=~ s/.*\///;

$msg="$Date $user $short_name $short_pred";
				# append to log file
($Lok=open(APPEND,">>".$file_emailReqLog)) ||
    system("echo '$msg' >> $file_emailReqLog");
if ($Lok) { print APPEND $msg,"\n";
	    close(APPEND); }

				# ------------------------------
				# remove input file
				# ------------------------------
				# xx temporary
#system("cp $fileIn /home/$ENV{USER}/server/bup/tmp-mail-in/");

unlink($fileIn)|| print " --- $scrName: unlink of fileIn=$fileIn falied.\n --- got this error $_\n"
    if (-e $fileIn);


exit(1);


#===============================================================================
sub ini {
    $[ =1 ;			# start counting at 1
#-------------------------------------------------------------------------------
#   ini                       
#-------------------------------------------------------------------------------
				# ------------------------------
				# get the name of this file
    $scrName=$0;$scrName=~s/^.*\/|\.pl//g;
				# --------------------------------------------------
				# process input arguments
				# --------------------------------------------------
    if ($#ARGV < 1) {
	$msg= "*** ERROR $scrName: wrong number of command line arguments:\n";
	$msg.="    in:   reads mail file written by PROCMAIl\n";
	$msg.="          NOTE: if no fileOut=name given, output file will be moved dir dir_pred!!\n";
	$msg.="    out:  writes processed version to be passed to predictPP.pl\n";    
	$msg.="          1st arg MUST be the mail file (written by procmailPP-stork.pl)\n";
	$msg.="          any arg may be 'dbg' for debug mode\n";
	$msg.="          any arg may be 'fileOut=file' to specify name of output file\n";
	$msg.="    NOTE: if no fileOut=name given, output file will be moved dir dir_pred!!\n";
	return(0,$msg."\n*** err=help"); }

    $fileIn=$ARGV[1];
				# ------------------------------
    $Ldebug=0;			# default parameters
    $fileOut=0;			# will be named by script 
    $LfileNameGiven=0;		# is the output file name given?
				#    if so : will NOT move to dirPred

				# input arguments
    foreach $it (2..$#ARGV) {
	if    ($ARGV[$it]=~/^de?bu?g$/i)          { $Ldebug= 1; }
	elsif ($ARGV[$it]=~/^fileOut=(\S*)$/i)    { $fileOut=$1;
						    $LfileNameGiven=1; }
    }

				# --------------------------------------------------
				# include envPP package as define in $PPENV or default
    if ($ENV{'PPENV'}) {
	$env_pack = $ENV{'PPENV'}; }
    else {				# this is used by the automatic version!
	$env_pack = "/home/$ENV{USER}/server/scr/envPP.pm"; } # HARD CODDED

    $Lok=
	require $env_pack;
				# ******************************
    if (! $Lok){		# *** error in require env
				# ******************************
	$envPP{"pp_admin"}= "rost\@columbia.edu";
	if (-e "/usr/sbin/Mail" ){
	    $envPP{"exe_mail"}="/usr/sbin/Mail" ;}
	else {
	    $envPP{"exe_mail"}="/usr/bin/Mail" ;}
	return(0,"*** $scrName failed to require env_pack ($env_pack) err=101");}

				# ------------------------------
				# read local environment var
				# ------------------------------
    foreach $des ("exe_mail","lib_pp",
		  "dir_work","dir_prd","dir_bup_errMail","dir_bup_errIn",
		  "file_emailReqLog","file_emailProcLog","par_patDirPred",
		  "pp_admin","pp_admin_sendWarn"){
	$envPP{"$des"}=&envPP'getLocal("$des");                      # e.e'
				# ******************************
	if (! $envPP{"$des"}){	# *** error in local env
	    if (! defined $envPP{"exe_mail"}){
		if (-e "/usr/sbin/Mail" ){$envPP{"exe_mail"}="/usr/sbin/Mail" ;}
		else                     {$envPP{"exe_mail"}="/usr/bin/Mail" ;}}
	    return(0,"*** $scrName failed to get envPP{$des} from env_pack ($env_pack)"
		   ." err=102");}}

				# ------------------------------
				# include libraries
				# ------------------------------
    foreach $lib("lib_pp",
#		 "lib_ctime"
		 ){
	$tmpLib=$envPP{"$lib"};
	$Lok=require $tmpLib;
				# ******************************
				# *** error in require
	return(0,"*** $scrName failed to require lib $lib ($tmpLib)"." err=103")
	    if (! $Lok);}

				# ------------------------------
				# set other local parameters
				# ------------------------------
    $fhout=      "FHOUT_".$scrName;
    $fhin=       "FHIN_".$scrName;
    
    $fileTrace=  $envPP{"file_emailProcLog"};

				# ------------------------------
				# get date
    $Date=&sysDate();
    $date=$Date; $date=~s/\s/_/g;
    return(1,"ok");
}				# end of ini

#===============================================================================
sub ctrlAbort {
    local ($message,$LdoSend) = @_;
#----------------------------------------------------------------------
#   ctrlAbort                   sends alarm mail to pp_admin
#       in:                     $message
#          GLOBAL               $envPP{"exe_mail"},$envPP{"ppAdmin"},
#                               $File_name,$User_name,$Origin,$Date,
#----------------------------------------------------------------------
				# ------------------------------
				# surpress sending warnings ?
				# ------------------------------
    $pp_admin_sendWarn=1;
    $pp_admin_sendWarn=0        if (! defined $envPP{"pp_admin_sendWarn"} || 
				    ! $envPP{"pp_admin_sendWarn"} ||
				    $envPP{"pp_admin_sendWarn"} eq "no");
    $LdoSend=1                  if (! defined $LdoSend);
				# NO MAIL -> return
    exit(1)                     if (! $pp_admin_sendWarn || ! $LdoSend);

				# ------------------------------
				# send mail
				# ------------------------------
    $header=   "\n              $Date\n";
    $message=                   $header.$message."\n";

    $exe_mail=$envPP{"exe_mail"}; $pp_admin=$envPP{"pp_admin"};
    $cmd="echo '$message' | $exe_mail -s PP_ERROR_PROCMAIL $pp_admin";
    system("$cmd");
    exit(1);
}				# end of ctrlAbort

# ================================================================================
sub ctrlSendAlarm {
    local ($message,$subject) = @_;
    local ($header);
#-------------------------------------------------------------------------------
#   ctrlSendAlarm               send an ctrlSendAlarm mail to the system administrator
#       in:                     $message
#       out:                    
#       err:                    
#-------------------------------------------------------------------------------
				# ------------------------------
				# get the current date
    $DateNow=&sysDate();
				# ------------------------------
				# compose message
    $header=   "\n".            " \t ".$scrName; 
    $header.=  "\n".            " \t ".$DateNow;
    $message=  $header . "\n" . $message."\n";
    $exeMail=$envPP{"exe_mail"}; 
    if (defined $envPP{"pp_admin"}){
	$pp_admin=$envPP{"pp_admin"};
	$cmd="echo '$message' | $exeMail -s $subject $pp_admin";
	system("$cmd");		# system call
    } else {
	print "*** ALARM $scrName: pp_admin not defined -> could NOT send:\n",$message,"\n";}

}				# end of ctrlSendAlarm


#==============================================================================
# library collected (begin)
#==============================================================================

#===============================================================================
sub sysDate {
#    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   sysDate                     returns $Date
#       out:                    $Date (May 30, 1998 59:39:03)
#-------------------------------------------------------------------------------

    @tmp=(			# HARD_CODED
	  "/home/$ENV{USER}/perl/",
	  "/home/$ENV{USER}/server/scr/lib/"
	  );
    $exe_ctime="ctime.pl";	# local ctime library

    $Lok=0;
				# ------------------------------
				# get function
    if (defined &localtime) {
				# use system standard
	$Lok=1	                if (defined &ctime && &ctime);
				# use local library
	$Lok=1                  if (! $Lok && -e $exe_ctime);

	if (! $Lok) {		# search for it
	    foreach $tmp (@tmp){
		$exe_tmp=$tmp.$exe_ctime;
		if (-e $tmp){
		    $Lok=
			require("$exe_tmp");
		    last;}}}
				# ------------------------------
				# found one: use it
	if ($Lok && 
	    defined &ctime && &ctime && defined &localtime && &localtime){
#       	$date is e.g.:		Oct:14:13:06:47:1993
#       	@Date is e.g.:		Oct1413:06:471993
#        	&ctime(time) is e.g.:	Thu Oct 14 13:06:47 1993
	    @Date = split(' ',&ctime(time)) ; shift (@Date) ; 
	    $Date="$Date[2] $Date[3], $Date[$#Date]  $Date[4]";
	    return($Date);} }
				# ------------------------------
	 			# found none: take system
    if (! $Lok) {
	$localtime=`date`;
	@Date=split(/\s+/,$localtime);
	$Date="$Date[2] $Date[3], $Date[$#Date] $Date[4]"; }
    return($Date);
}				# end of sysDate

#==============================================================================
# library collected (end)
#==============================================================================







