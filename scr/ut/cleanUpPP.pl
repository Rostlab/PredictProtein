#!/usr/bin/perl -w
##!/usr/local/bin/perl -w
##!/usr/pub/bin/perl5 -w
##!/usr/pub/bin/perl5.003 -w
##! /usr/pub/bin/perl -w
#  
# 
#------------------------------------------------------------------------------#
#	Copyright				        	1999	       #
#	Burkhard Rost		rost@EMBL-Heidelberg.DE			       #
#	CUBIC (Columbia Univ)	http://www.embl-heidelberg.de/~rost/	       #
#       Dep Biochemistry & Molecular Biophysics				       #
#       630 West, 168 Street						       #
#	New York, NY 10032	http://www.dodo.cpmc.columbia.edu/~rost/       #
#				version 0.1   	Apr,    	1999	       #
#------------------------------------------------------------------------------#
#
#    cleans up the files in the various PP_server_run_directories.
#    called by crontab, once a day
#    
#    ------------------------------
#    command line argument(s)
#    ------------------------------
#      
#    optional argument
#    * 'dbg'                        for debug mode
#                                   -> all messages onto STDOUT
#    
#    ------------------------------
#    text markers
#    ------------------------------
#
#  - 'xx'         : to do, error break
#  - 'yy'         : to do at later stage
#  - 'HARD_CODED' : explicit names
#  - 'br date'    : changed on date
#  - 'hack'       : some hack 
#
#------------------------------------------------------------------------------#
use Carp qw| cluck :DEFAULT |;

$[ =1 ;				# start counting at 1
				# --------------------------------------------------
				# initialise environment parameters
				# --------------------------------------------------
($Lok,$msg)=
    &ini();
				# ******************************
				# *** error in local env
&ctrlAbort("*** ERROR $scrName: $msg",$scrName."_ini") if (! $Lok);
				# ******************************

				# --------------------------------------------------
				# redirect STDOUT and STDERR
				# --------------------------------------------------
if (! $Ldebug){
				# STDOUT to file_cleanUpLog
    open (STDOUT, ">".$envPP{"file_cleanUpLog"})
	|| warn "*** WARN $scrName cannot open new (".$envPP{"file_cleanUpLog"}.")\n";
				# STDERR to file_scanErr
    open (STDERR, ">".$envPP{"file_cleanUpLog"})
	|| warn "*** WARN $scrName cannot open new (".$envPP{"file_cleanUpLog"}.")\n";
				# flush output
    $| = 1; }
				# --------------------------------------------------
				# clean up space
				# note: may abort the scanner when errors happen..
				# --------------------------------------------------
($Lok,$msg)=
    &cleanUpDo(1);

exit;



#===============================================================================
sub ini {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   ini                         gets the parameters from env, and checks
#-------------------------------------------------------------------------------
				# ------------------------------
				# get the name of this file
    $scrName=$0;$scrName=~s/^.*\/|\.pl//g;
				# --------------------------------------------------
				# include envPP package as define in $PPENV or default
    if ($ENV{'PPENV'}) {
	$env_pack = $ENV{'PPENV'}; }
    else {				# this is used by the automatic version!
	$env_pack = "/home/$ENV{USER}/server/scr/envPP.pm"; } # HARD CODDED, HARD_CODDED

				# ------------------------------
				# debug mode
    if ($#ARGV<1) { print "goal: clean all running PP dirs\n";
		    print "use:  $scrName <auto|dbg>\n";
		    print "opt:  env=envPP.pm (i.e. the PP env pack, def=$env_pack\n";
		    exit; }

				# ------------------------------
				# require lib
    $Lok=
	require $env_pack;
                    		# *** error in require env
    return(0,"*** ERROR $scrName: require env_pack=".$env_pack."\n".
	   "*** err=9101")      if (! $Lok);

				# ------------------------------
				# read command line
    $Ldebug=0;
    foreach $arg (@ARGV){
	if    ($arg=~/^de?bu?g$/i) { $Ldebug=1; }
	elsif ($arg=~/^auto$/)     { $Ldebug=0; } }

				# ------------------------------
				# read local environment var
				# ------------------------------
    foreach $des ("dir_work",	# working
		  "file_cleanUpLog",
		  "para_status","file_statusFlag","file_statusHis","file_statusAdd",
				# input
		  "dir_inProcmail","dir_prd","par_patDirPred",
				# output
		  "dir_res","dir_mail",
		  "dir_bup_err","dir_bup_errIn","dir_bup_res","dir_trash",
		  "dir_err",
		  "dir_resPub",
				# executables: system stuff
		  "exe_nice","exe_mail","exe_tar","exe_quota","exe_ps","exe_find","exe_du",
				# executables + packages
		  "exe_scan_clean",
				# parameters
		  "pp_admin", 
		  "ctrl_timeoutQuery","ctrl_timeoutRes",
		  "ctrl_timeoutErr","ctrl_timeoutBup","ctrl_timeoutTrash",
		  "ctrl_timeoutResPub",
		  "ctrl_numFileKeep","ctrl_numLinesLog","ctrl_kbAllocated",
		  "ctrl_checkQuota","ctrl_checkDu",
				# file names
		  "prefix_prd","prefix_work","suffix_mail","suffix_res",
		  "prefix_fileBupTar",
				# log files
		  "file_crontabLog","file_errLog",
		  "file_emailReqLog","file_htmlReqLog","file_htmlCgiLog",
		  "file_licenceComLog","file_licenceNotLog",
		  "file_scanLog","file_sendLog","file_predMgrLog","file_statusLog",
		  "file_ppLog","file_procmailLog","file_procmailInLog",
		  "file_scanOut"
		  ){
	$envPP{$des}=&envPP'getLocal($des);                      # e.e'
	next if ($des=~/exe_scan_clean/); # accept missing exe_scan_clean
	next if ($des=~/exe_quota/);      # accept missing quota command
#	next if ($des=~/^para/);
				# *** error in local env
	return(0,"*** err=9102\n"."failed to get envPP{$des} from env_pack '$env_pack'\n") 
	    if (! defined $envPP{$des});
	next if ($des=~/^ctrl/); # ctrl_* can be 0
	return(0,"*** err=9102\n"."failed to get envPP{$des} from env_pack '$env_pack'\n") 
	    if (! defined $envPP{$des});}
	

				# ------------------------------
				# corrections to environment
				# ------------------------------

				# working directory
    $dirWork=          $envPP{"dir_work"};
				# file system
    $fileSys=$dirWork; $fileSys=~s/^\///;              $fileSys=~ s/\/.*//;
    $fileRundir=$dirWork;$fileRundir=~s/\/[A-Za-z0-9]+\/$//;
				# bup of all results
    $envPP{"dir_bup_res"}.="/"  if ($envPP{"dir_bup_res"} !~/\/$/);
    $dirTmp=$envPP{"dir_bup_res"};
    $dirTmp=~s/\/$//g;
				# make directory if missing
    system("mkdir $dirTmp")     if (! -d $dirTmp);
				# mail 
    $envPP{"pp_admin"}=		# HARD_CODED
	"predict_help\@columbia.edu" if (! defined $envPP{"pp_admin"});
    if (! defined $envPP{"exe_mail"}){
	if (-e "/usr/sbin/Mail" ){
	    $envPP{"exe_mail"}="/usr/sbin/Mail" ;}
	else                     {
	    $envPP{"exe_mail"}="/usr/bin/Mail" ;}}

				# ------------------------------
				# only one of the following 
				#    required!
    if ($envPP{"ctrl_checkQuota"}  && $envPP{"ctrl_checkDu"}) {
	$envPP{"ctrl_checkDu"}=0;
	print "-*- WARN $scrName: reset flag for checking du (since quota done)!\n";}

				# ------------------------------
				# ini quota stuff
    if ($envPP{"ctrl_checkQuota"}) {
	undef $Q_space_usage;    undef $Q_file_usage;  
	undef $Q_space_quota;    undef $Q_file_quota;  
	undef $Q_space_limit;    undef $Q_file_limit;  
	undef $Q_space_timeleft; undef $Q_file_timeleft;}

				# ------------------------------
				# get the date
    $Date=&sysDate();
    
    return(1,"ok");
}				# end of ini

#===============================================================================
sub cleanUpDo {
    local($LletErrorAbort)=@_;
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   cleanUpDo           cleans up space asf:
#                               (1) check file quota
#                               (2) restrict number of lines of all log files
#                               (3) clean up dead requests
#                               (4) clean up other old files
#                               (5) report status of PP server to WWW docs
#                               
#       in GLOBAL:              all
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."cleanUpDo"; $fhinLoc="FHIN_cleanUp";

				# --------------------------------------------------
				# (1) clean up error dirs
				# --------------------------------------------------
    $dirWorkLoc=$dirWork;
    $dirWorkLoc.="/"            if ($dirWorkLoc !~ /\/$/);
    foreach $kwd ("dir_inProcmail","dir_prd","dir_res","dir_mail",
		  "dir_work","dir_bup_err","dir_bup_errIn","dir_bup_res",
		  "dir_trash",
		  "dir_resPub")  {
	next if (! defined $envPP{$kwd}); # missing parameter
	next if (! -d $envPP{$kwd}); # missing dir
	$dir=$envPP{$kwd};

				# set timeouts
	if    ($kwd=~/^dir_bup/)           { $timeout=$envPP{"ctrl_timeoutBup"}; }
	elsif ($kwd=~/^dir_err/)           { $timeout=$envPP{"ctrl_timeoutErr"}; }
	elsif ($kwd=~/^dir_trash/)         { $timeout=$envPP{"ctrl_timeoutTrash"}; }
	elsif ($kwd=~/^dir_(in|prd|mail)/) { $timeout=$envPP{"ctrl_timeoutQuery"}; }
	elsif ($kwd=~/^dir_res$/)          { $timeout=$envPP{"ctrl_timeoutRes"}; }
	elsif ($kwd=~/^dir_resPub/)        { $timeout=$envPP{"ctrl_timeoutResPub"}; }
	elsif ($kwd=~/^dir_work/)          { $timeout=$envPP{"ctrl_timeoutQuery"}; }
				# ------------------------------
				# read directory:
				#    all older than timeout days
				#    written into fileTmp
	print "--- $scrName:  check dir=$dir\n" if ($Ldebug);

	$fileTmp=$dirWork."tmp_cleanUp.tmp";
	$cmd=$envPP{"exe_find"}." $dir -type f -mtime +$timeout -print >> $fileTmp";
	($Lok,$msgSys)=&sysSystem("$cmd",0);


	open($fhinLoc,$fileTmp) ||
	    do { print "*** ERROR $scrName: failed opening file $fileTmp\n";
		 print "    produced by system:\n",$cmd,"\n";
		 next; };
	while(<$fhinLoc>) {
	    $_=~s/\s//g;
	    if (! -e $_) { print "-*- WARN $scrName: failed finding file $_ (from $cmd)\n";
			   next; }
	    print "--- ",">" x length($scrName),"   deleting $_\n" if ($Ldebug);
	    &ass_unlinkSecurity($_); }
	close($fhinLoc); 
	unlink($fileTmp);	# clean up temporary file
    }

				# --------------------------------------------------
				# (2) check file quota
				# delete files if necessary
				#        *********
				# NOTE:  aborts if no files can be deleted!!!
				#        *********
				# --------------------------------------------------

				# ------------------------------
				# (1) number of files (check anyway!)
    ($Lok,$msg)=
	&ctrlSpaceNumberCheck($envPP{"exe_nice"},$envPP{"exe_tar"},$envPP{"file_cleanUpLog"},
			      $envPP{"dir_bup_res"},
			      $envPP{"dir_bup_err"},$envPP{"dir_bup_errIn"},
			      $envPP{"prefix_fileBupTar"},$envPP{"ctrl_numFileKeep"});
    if (! $Lok){ $msgErr= "";
		 $msgErr.="*** err=9210\n" if ($msg !~ /err\=/);
		 $msgErr.="*** ERROR $scrName: ctrlSpaceNumberCheck failed\n".$msg;
		 print $msgErr,"\n";
		 &ctrlAbort($msgErr,"PP_ERROR_cleanUpDo:apaceNumberCheck")
		     if ($LletErrorAbort && $msg=~/^ABORT/); }
	
				# ------------------------------
				# (3) space used
				#     note: first argument =1 ->
				#           check after deletion again!
    if ($envPP{"ctrl_checkDu"} || $envPP{"ctrl_checkQuota"}) {
	($Lok,$msg)=
	    &ctrlSpaceCheck(1,$envPP{"ctrl_checkDu"},$envPP{"ctrl_checkQuota"},
			$envPP{"exe_nice"},
			$envPP{"exe_du"},$envPP{"exe_quota"},$envPP{"exe_tar"},
			$fileSys,$fileRundir,$envPP{"file_cleanUpLog"},$Date,$Ldebug,
			$envPP{"dir_bup_res"},$envPP{"dir_trash"},
			$envPP{"dir_bup_err"},$envPP{"dir_bup_errIn"},
			$envPP{"ctrl_kbAllocated"},
			$envPP{"prefix_fileBupTar"},$envPP{"ctrl_numFileKeep"});
				# note: if repeat still over quota : error returned!
	if (! $Lok){ $msgErr= "";
		     $msgErr.="*** err=9220\n" if ($msg !~ /err\=/);
		     $msgErr.="*** ERROR $scrName: ctrlSpaceCheck failed\n".$msg;
		     print $msgErr,"\n";
		     &ctrlAbort($msgErr,"PP_ERROR_cleanUpDo")
			 if ($LletErrorAbort && $msg=~/^ABORT/); }}
				# ------------------------------
    else { $msg="ok";		# no quota check! 
	   print "-*- NOTE $scrName: no quota check!\n"; }

				# --------------------------------------------------
				# (4) restrict number of lines of all log files
				# --------------------------------------------------
    foreach $kwd ("file_crontabLog","file_procmailLog","file_scanLog",
		  "file_sendLog","file_emailReqLog","file_htmlReqLog",
		  "file_htmlCgiLog",
		  "file_licenceComLog","file_licenceNotLog",
		  "file_errLog","file_predMgrLog","file_scanOut",
		  "file_procmailInLog"
		 ){
	next if (! defined $envPP{$kwd});
	next if (! -e $envPP{$kwd});
	($Lok,$msg)=
	    &ctrlFileRestrict($envPP{$kwd}, "H", $envPP{"ctrl_numLinesLog"});
				# tolerate ERRORS here!
	if (! $Lok){ $msgErr="*** err=9270\n".
			 "*** ERROR $scrName: ctrlFileRestrict failed\n".$msg;
		     print $msgErr,"\n";
		     &ctrlSendAlarm($msgErr,"PP_WARN_scanner");}
				# set access for WWW log file
	if ($kwd=~/^(file_htmlReqLog|file_htmlCgiLog)/) {
	    $file=$envPP{$kwd};
	    ($Lok,$msgSys)=&sysSystem("chmod 666 $file"); }
    }

				# --------------------------------------------------
				# (5) clean up dead requests
				# --------------------------------------------------
    ($Lok,$msg)=
	&ctrlFileExpired($envPP{"exe_nice"},$envPP{"exe_find"},$envPP{"exe_mail"},
			 $envPP{"pp_admin"},
			 $envPP{"ctrl_timeoutQuery"},$envPP{"ctrl_timeoutRes"},
			 $envPP{"file_sorryTimeout"},
			 $dirWork,$envPP{"dir_mail"},$envPP{"dir_res"},$envPP{"dir_trash"});
    if (! $Lok){ $msgErr="*** err=9280\n".
		     "*** ERROR $scrName: ctrlFileExpired failed\n".$msg;
		 print $msgErr,"\n";
		 &ctrlAbort($msgErr,"PP_ERROR_cleanUpDo")
		     if ($LletErrorAbort && $msg=~/^ABORT/); }

				# --------------------------------------------------
				# (6) clean up other old files
				# --------------------------------------------------
    if ((-e $envPP{"exe_scan_clean"} && -x $envPP{"exe_scan_clean"})
	|| -l $envPP{"exe_scan_clean"}) {
	$cmdSystem=$envPP{"exe_nice"}." ".$envPP{"exe_scan_clean"}." auto";
	print "--- $scrName: clean up by system call ($cmdSystem)\n";
	($Lok,$msgSys)=&sysSystem("$cmdSystem"); }

    return(1,"ok $sbrName"); 
}				# end of cleanUpDo

#===============================================================================
sub ass_unlinkSecurity {
    local(@fileInLoc) = @_ ;
#-------------------------------------------------------------------------------
#   ass_unlinkSecurity          excludes some directories from unlinking a file
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."ass_unlinkSecurity";
    foreach $fileInLoc (@fileInLoc) {
	next if (! -e $fileInLoc);
	next if ($fileInLoc=~/^\/home\/phd\/server\/scr/); # HARD CODED: security 
	next if ($fileInLoc=~/^\/home\/phd\/server\/pub/); # HARD CODED: security 
	next if ($fileInLoc=~/^\/home\/phd\/server\/bin/); # HARD CODED: security 
	next if ($fileInLoc=~/\.p[lm]$/);                  # HARD CODED: security 
	unlink($fileInLoc);
    }
}				# end of ass_unlinkSecurity

#===============================================================================
sub ctrlAbort {
    local($message,$subj) = @_;
#----------------------------------------------------------------------
#   ctrlAbort                   sends alarm mail to pp_admin and exits(1)
#       in:                     $message,$subject
#       in GLOBAL:              $envPP{"exe_mail"},$envPP{"pp_admin"},
#       in GLOBAL:              $envPP{"file_errLog"},$Date,
#       out:                    EXIT(1)
#----------------------------------------------------------------------
				# ------------------------------
				# get the current date
    $DateNow=&sysDate();
				# ------------------------------
				# compose message
    $header=   "\n               $scrName "; 
    $header.=  "\n               $DateNow";
    $message=  "$header" . "\n" . "$message\n";
    $exeMail=$envPP{"exe_mail"}; 
    if (! defined $envPP{"pp_admin"}){
	print "*** ERROR $scrName: pp_admin not defined -> could NOT send:\n",$message,"\n";
	exit; }
				# ------------------------------
				# send message
    $pp_admin=$envPP{"pp_admin"};
    $subj="PP_ERROR_cleanUp" if (! defined $subj || length($subj) < 1);

    ($Lok,$msg)=
	&sysSendMail($exeMail,$message,$envPP{"pp_admin"},$subj);
    print "--- $sbrName: send mail '$msg'\n"      if ($Ldebug && $Lok);
    print "*** $sbrName: failed to send ($msg)\n" if (! $Lok);
				# write to trace file
    print "*** $scrName: message=$message\n";
    exit;
}				# end of ctrlAbort

# ================================================================================
sub ctrlFileExpired {
    local($exeNice,$exeFind,$exeMailLoc,$ppAdmin,$ctrl_timeoutQuery,$ctrl_timeoutRes,
	  $fileSorryTimeout,$dirWorkLoc,$dirMail,$dirRes,$dirTrash)=@_;
    local ($fileAlarm,$dirCheck,$msgWarn,$subjectWarn,$Lok,$ctrl_timeout);
#-------------------------------------------------------------------------------
#   ctrlFileExpired             detecting expired (ancient) files
#                               This sub detectect two type of file timeout:
#                                - query files timeout (no result for a given query)
#                                - result files timeout (pending result file)
#                               When such files are found, the list is sent to admistrator
#                               and the pending  files are just moved to trash dir
#       in:                     $dirWork
#       out:                    
#       err:                    
#-------------------------------------------------------------------------------
    $sbrName3="ctrlFileExpired";
				# create an alarm file name
    $dirWorkLoc.="/"            if ($dirWorkLoc !~ /\/$/);
    $fileAlarm=$dirWorkLoc."expired_files.tmp";

				# --------------------------------------------------
				# loop over all directories to check
				# --------------------------------------------------
    foreach $dirCheck ($dirMail,$dirRes) {
				# ------------------------------
				# (0) missing dir?
				# ------------------------------
	if (! -d $dirCheck) {
	    print "-*- WARN OR ERROR $scrName3: dir=$dirCheck missing\n";
	    next; }
				# which timout version?
	if ($dirCheck eq $dirMail) {
	    $ctrl_timeout=$ctrl_timeoutQuery; 
	    $msgWarn="--- WARN $sbrName3: pending mail query file(s) moved to $dirTrash\n"; 
	    $subjectWarn="PP_WARN_pending_mail"; }
	else {
	    $ctrl_timeout=$ctrl_timeoutRes; 
	    $msgWarn="--- WARN $sbrName3: pending result file(s) moved to $dirTrash\n"; 
	    $subjectWarn="PP_WARN_pending_results"; }
	
				# ------------------------------
				# (1) find pending query files
				# ------------------------------
	($Lok,$msgSys)=
	    &sysSystem("$exeNice $exeFind $dirCheck -type f -mtime +$ctrl_timeout -print >> $fileAlarm");

				# ------------------------------
				# (2) send mail + move to trash
				# ------------------------------
	if (-s $fileAlarm) {
	    ($Lok,$msg)=
		&sysSendMail($exeMailLoc,$fileAlarm,$ppAdmin,$subjectWarn);
	    print "--- $sbrName: send mail '$msg'\n"      if ($Lok);
	    print "*** $sbrName: failed to send ($msg)\n" if (! $Lok);
	    print $msgWarn;
				# move those files to trash dir   
	    ($Lok=open(ALARM, "<".$fileAlarm)) ||
		warn("-*- WARN $scrName3: failed to open old=$fileAlarm\n");
	    next if (! $Lok);

	    while (<ALARM>) {
		chop;
				# security hack!!
		next if ($_=~ /^\/home\/phd\/(server\/scr|scr\/server)/);
		$filePending=$_;

				# send mail to user
		if ($dirCheck eq $dirMail) {
		    ($Lok,$user)=&fileExtractHeader($filePending,"PPhdr from");
		    if (!$Lok && $user=~/\@/) {
			($Lok,$msg)=
			    &sysSendMail($exeMailLoc,$fileSorryTimeout,$user,
					 "ERROR_of_PredictProtein");}}
		
		($Lok,$msgSys)=&sysSystem("$exeNice \\mv $filePending $dirTrash"); # system call 
	    }

	    close(ALARM); }
				# delete file
	&ass_unlinkSecurity($fileAlarm) if (-e $fileAlarm);
    }				# end of loop over all directories
				# --------------------------------------------------

    return(1,"ok");
}				# ctrlFileExpired

# ================================================================================
sub ctrlFileRestrict {
    local ($fileInLoc,$cut_side,$numLinesMax) = @_;
    local ($sbrName,$msg,$numLines,$first_line_to_copy,$last_line_to_copy,$new_file_name);
#-------------------------------------------------------------------------------
#   ctrlFileRestrict            managing size of log files
#                               remove heading or trailing lines in files to avoid
#                               too big files
#                               It takes tree arguments:
#                                 - the name of the file
#                                 - the side to cut (Head or Tail)
#                                 - the number of line to keep
#       in:                     
#       out:                    
#       err:                    
#-------------------------------------------------------------------------------
    $sbrName=$scrName.":"."ctrlFileRestrict";
				# ------------------------------
				# first count number of lines in file
				# ------------------------------
    open(FILE, "<".$fileInLoc) || 
	( do { $msg="*** ERROR $sbrName: failed to open old=$fileInLoc";
	       return(0,"*** err=9271\n".$msg); } ) ;
    $numLines=0;
    while (<FILE>) {
	++$numLines; }
    close(FILE);
				# no lines to remove -> return
    return(1,"ok")              if ($numLines <= $numLinesMax);

				# --------------------------------------------------
				# there are lines to remove
				# --------------------------------------------------

				# ------------------------------
    if ( $cut_side eq 'H') {	# set first and last line to copy
	$first_line_to_copy= $numLines - $numLinesMax + 1;
	$last_line_to_copy=  $numLines; }
    else {
	$first_line_to_copy= 1;
	$last_line_to_copy=  $numLinesMax;}
				# ------------------------------
				# open again the file
    open(FILE, "<".$fileInLoc) || 
	( do { $msg="*** err=9272\n"."*** ERROR $sbrName: failed to open old=$fileInLoc";
	       return(0,$msg); } ) ;
				# ------------------------------
				# open new temporary file
    $new_file_name=$fileInLoc . ".tmp";
    open(NEW_FILE,">".$new_file_name) || 
	( do { $msg="*** err=9273\n"."*** ERROR $sbrName: failed to open new=$fileInLoc";
	       return(0,$msg);} ) ;
				# ------------------------------
				# write only few lines
    $numLines= 0;
    while (<FILE>) {
	++$numLines;
	if ($numLines >= $first_line_to_copy && $numLines <= $last_line_to_copy) {
	    print NEW_FILE $_; }}
				# close opened files
    close(FILE);close(NEW_FILE);

				# ------------------------------
				# rename the new file

    ($Lok,$msgSys)=&sysSystem("\\mv $new_file_name $fileInLoc"); # system call

				# ******************************
				# if ERROR: just delete it!
    if (! $Lok || $msgSys) {
	$DateLoc=&sysDate();
	unlink($fileInLoc);
	($Lok,$msgSys)=&sysSystem("echo '$DateLoc' >> $fileInLoc"); 
	print "--- WARN $sbrName: no clean restriction of lines for file=$fileInLoc!\n"; }

    return(1,"ok");
}				# end of ctrlFileRestrict
	
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
    if (! defined $envPP{"pp_admin"}){
	print "*** ALARM $scrName: pp_admin not defined -> could NOT send:\n",$message,"\n";
	return(); }
				# send mail
    $pp_admin=$envPP{"pp_admin"};
    ($Lok,$msg)=
	&sysSendMail($exeMail,$message,$pp_admin,$subject);
    print "--- $sbrName: send mail '$msg'\n"      if ($Lok);
    print "*** $sbrName: failed to send ($msg)\n" if (! $Lok);
    print $msgWarn;

}				# end of ctrlSendAlarm

#===============================================================================
sub ctrlSpaceCheck {
    local ($Lrepeat,$Lctrl_checkDu,$Lctrl_checkQuota,
	   $exeNice,$exeDu,$exeQuota,$exeTar,
	   $fileSys,$fileRundirLoc,$fileScanOut,$DateLoc,$LdebugLoc,
	   $dirSavePred,$dirTrash,$dirBupErr,$dirBupErrIn,
	   $kbAllocated,$prefixFileBupTar,$spaceNumFileKeep)=@_;
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   ctrlSpaceCheck              compares allocated and used space
#       in:                     ... $Lrepeat =1|0 if 1: check quota after deletion
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."ctrlSpaceCheck";

				# --------------------------------------------------
				# (1a) UNIX du (disk usage) command
				# --------------------------------------------------
    if ($Lctrl_checkDu) {
	($Lok,$msg)=
	    &ctrlSpaceDuCheck($exeDu,$exeNice,$fileRundirLoc,$DateLoc,$LdebugLoc,
			      $dirSavePred,$dirTrash,$kbAllocated);
	if (! $Lok){ $msgErr= "ABORT\n";
		     $msgErr.="*** err=9220\n" if ($msg !~ /err\=/);
		     $msgErr.="*** ERROR $scrName: ctrlSpaceDuCheck failed (1)\n".$msg;
		     return(0,$msgErr); }
				# ------------------------------
				# (1b) run again for security
	if ($Lrepeat && $msg=~/^over (space|file)/) {
	    ($Lok,$msg)=
		&ctrlSpaceDuCheck($exeDu,$exeNice,$fileRundirLoc,$DateLoc,$LdebugLoc,
				  $dirSavePred,$dirTrash,$kbAllocated);
	    if (! $Lok){ $msgErr= "ABORT\n";
			 $msgErr.="*** err=9222\n" if ($msg !~ /err\=/);
			 $msgErr.="*** ERROR $scrName: ctrlSpaceDuCheck failed (2)\n".$msg;
			 return(0,$msgErr);}}

				# ==============================
				# <--- <--- <--- <--- <--- <--- 
				# (1c) still over: RETURN!!!
	if ($Lrepeat && $msg=~/^over (space|file)/) {
	    return(0,"*** err=9223\n"."overflow ! $sbrName failed to allocate space");}}
				# <--- <--- <--- <--- <--- <--- 
				# ==============================

				# --------------------------------------------------
				# (2) UNIX quota command
				# --------------------------------------------------
    elsif ($Lctrl_checkQuota) {
				# ------------------------------
				# (2b) declare and initialise variables
	if (! defined $Q_space_usage) {
	    ($Lok,$msg)=
		&ctrlSpaceQuotaInit($exeQuota);
	    if (! $Lok){ $msgErr= "ABORT\n";
			 $msgErr.="*** err=9230\n" if ($msg !~ /err\=/);
			 $msgErr.="*** ERROR $scrName: ctrlSpaceQuotaInit failed\n".$msg;
			 print $msgErr,"\n";
			 return(0,$msgErr);}}
				# (2c) run quota
	($Lok,$msg)=
	    &ctrlSpaceQuotaCheck($exeQuota,$exeNice,$exeTar,
				 $fileSys,$fileScanOut,$DateLoc,$LdebugLoc,
				 $dirSavePred,$dirBupErr,$dirBupErrIn,$dirTrash,
				 $prefixFileBupTar,$spaceNumFileKeep);
	if (! $Lok){ $msgErr= "ABORT\n";
		     $msgErr.="*** err=9235\n" if ($msg !~ /err\=/);
		     $msgErr.="*** ERROR $scrName: ctrlSpaceQuotaCheck failed\n".$msg;
		     print $msgErr,"\n";
		     return(0,$msgErr);}
				# ------------------------------
				# (2d) run again for security
	if ($Lrepeat && $msg=~/^over (space|file)/) {
	    ($Lok,$msg)=
		&ctrlSpaceQuotaCheck($exeQuota,$exeNice,$exeTar,
				     $fileSys,$fileScanOut,$DateLoc,$LdebugLoc,
				     $dirSavePred,$dirBupErr,$dirBupErrIn,$dirTrash,
				     $prefixFileBupTar,$spaceNumFileKeep);
	    if (! $Lok){ $msgErr= "ABORT\n";
			 $msgErr.="*** err=9236\n" if ($msg !~ /err\=/);
			 $msgErr.="*** ERROR $scrName: ctrlSpaceQuotaCheck failed (2)\n".$msg;
			 print $msgErr,"\n";
			 return(0,$msgErr);} }
				# ==============================
				# <--- <--- <--- <--- <--- <--- 
				# (1c) still over: RETURN!!!
	return(0,"*** err=9237\n"."overflow ! $sbrName failed to allocate space")
	    if ($Lrepeat && $msg=~/^over (space|file)/);}
				# <--- <--- <--- <--- <--- <--- 
				# ==============================
    return(1,"ok $sbrName");
}				# end of ctrlSpaceCheck

# ================================================================================
sub ctrlSpaceFreeFile {
    local ($exeNice,$exeTar,$fileScanOut,$dirSavePred,
	   $prefixFileBupTar,$spaceNumFileKeep,$LisQuotaError,@fileListLoc) = @_;
    local ($chardate,$fileTar);
#----------------------------------------------------------------------
#   ctrlSpaceFreeFile           tar the save prediction file in a tar file
#                               NOTE: aborts if $LisQuotaError!!!
#       in:                     $is_error,@fileList: the latter all files to tar
#----------------------------------------------------------------------
    $sbrName=$scrName.":"."ctrlSpaceFreeFile"; 
				# ------------------------------
				# local para
    $nmaxFile=    200;		# because of SGI limitation in handling many files
    $cmdTar=      $exeNice." ".$exeTar." -cvf";
    $cmdTarRepeat=$cmdTar;$cmdTarRepeat=~s/\-c/\-r/;

				# ------------------------------
				# system call: get date as '99_02_12'
    $chardate=     
	`date +%d_%m_%y`;	# system call
    chop($chardate);
				# ------------------------------
				# build the tar file name
    $dirSavePredHere=$dirSavePred;
    $dirSavePredHere.="/"       if ($dirSavePred !~/\/$/);
    $fileTar=   $dirSavePredHere . $prefixFileBupTar . $chardate . ".tar";

				# ------------------------------
				# nothing to be tared
    if ($#fileListLoc < $spaceNumFileKeep){
				# ******************************
				# serious problem: over quota,
				#    but NO file found!
	if ($LisQuotaError) {
	    $msgHere="*** err=9250\n".
		"*** $sbrName: over quota but no file ($dirSavePred*gz) found!!";
	    print $msgHere,"\n";
				# EXIT for bad !!
	    &ctrlAbort($msgHere,"PP_ERROR_scanner_spaceFile"); }
	print 
	    "--- $sbrName:",
	    "nothing to be tared into fileTar=$fileTar, (to_tar=$dirSavePred*gz)";
	return(1,"ok"); }
				# security delete if Tar file existing
    unlink($fileTar)            if (-e $fileTar);

				# write note of action into log file
    print "-*- WARN $sbrName: create tar file=$fileTar";
	
				# --------------------------------------------------
				# quota error: be cruel = delete everything
				# --------------------------------------------------
    if ($LisQuotaError) {
	print "-*- WARN $sbrName: over quota -> radical deletion!!\n";
	foreach $file (@fileListLoc) {
	    &ass_unlinkSecurity($file) if (-e $file); }
	return(1,"all deleted");}
	    
				# --------------------------------------------------
				# not bad, simply tar it up
				# --------------------------------------------------

				# watch for SGI problem with
				#    limited number of files to tar
    $numRepeat=1+int($#fileListLoc/$nmaxFile);
    foreach $it (1..$numRepeat){
	$itBeg=1+($it-1)*$nmaxFile;
	$itEnd=$itBeg+$nmaxFile-1; 
	$itEnd=$#fileListLoc    if ($#fileListLoc<$itEnd);

	$tmp=join(' ',@fileListLoc[$itBeg..$itEnd]);

				# first time: generate tar
	if ($it==1 || ! -e $fileTar){ # k
	    $cmd= "$cmdTar $fileTar $tmp ";
	    $cmd.=">> $fileScanOut" if (length($fileScanOut) >1); }
				# then: append
	else {
	    $cmd= "$cmdTarRepeat  $fileTar $tmp ";
	    $cmd.=">> $fileScanOut" if (length($fileScanOut) >1); }
	    
	($Lok,$msgSys)=&sysSystem("$cmd");
    }

				# ------------------------------
				# remove the file tared
    foreach $file (@fileListLoc){
	print "xx rm $file ??\n";
	&ass_unlinkSecurity($file) if (-e $file); }
    #exit;
    return(1,"ok");
}				# end of ctrlSpaceFreeFile

# ================================================================================
sub ctrlSpaceFreeSpace {
    local($exeNice,$dirSavePred,$dirTrash,$LdebugLoc)=@_;
    local($sbrNameLoc,$Lremove,$tarFiles,$msgSerious,$msg);
#----------------------------------------------------------------------
#   ctrlSpaceFreeSpace         move older tar files to dir_trash, send alarm
#                              note: dirTrash=0 if in /run/trash !
#----------------------------------------------------------------------
    $sbrNameLoc=$scrName.":"."ctrlSpaceFreeSpace";
    $Lremove=0;
				# tar files
    $tarFiles=$dirSavePred."*.tar";
    $msgSerious= "\n";
    $msgSerious.="*************         *********************         ****************\n";
    $msgSerious.="*** ALARM ***  -----  *** SERIOUS ALARM ***  -----  *** ACT NOW! ***\n";
    $msgSerious.="*************         *********************         ****************\n";
    $msgSerious.="\n";

				# ------------------------------
				# now get older ones
    $#fileList=0;
    opendir(DIR,$dirSavePred) ||
	warn("-*- WARN $sbrNameLoc: failed opening dirSavePred=$dirSavePred!\n");
    @fileList=grep(/tar$/, readdir(DIR));
    closedir(DIR);
				# ------------------------------
				# remove old ones
    if ($#fileList > 0) {
				# move to trash (if existing)
	if ($dirTrash && -d $dirTrash) {
	    print "--- $sbrNameLoc: move from $dirSavePred to $dirTrash\n" if ($LdebugLoc);
	    foreach $file (@fileList) {
		($Lok,$msgSys)=&sysSystem("\\mv $file $dirTrash"); }}
	else {			# remove since no trash found
	    foreach $file (@fileList) {
		&ass_unlinkSecurity($file) if (-e $file); }}}

				# ******************************
				# serious: tar failed
				# ******************************
    else {
	$msg= "*** err=9241\n".$msgSerious;
	$msg.="*** ALARM $sbrNameLoc: space quota violation\n";
	$msg.="***       "." " x length($scrName).": cannot list (tar) file to remove!!!\n";
	$msg.=$msgSerious;
	&ctrlSendAlarm($msg,"PP_ERROR_scanner");
	&ctrlAbort($msg); }
}				# end of ctrlSpaceFreeSpace

# ================================================================================
sub ctrlSpaceDuCheck {
    local ($exeDu,$exeNice,$fileSysLoc,$DateLoc,$LdebugLoc,$dirSavePred,$dirTrash,$kbAllocated)=@_;
    local ($spaceUsage);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   ctrlSpaceDuCheck            checks system disk usage (unix du), deletes, or moves run stuff
#       in:                     
#       in GLOBAL:              $scrName
#       out:                    implicit: tar file 
#       err:                    (1,ok) || (0,"error message")
#-------------------------------------------------------------------------------
    $sbrName=$scrName.":"."ctrlSpaceDuCheck";
				# --------------------------------------------------
				# check if we exceed the disk and/or file quota
				# if files exeeded call ctrlSpaceFreeFile
				# if space exeeded call ctrlSpaceFreeSpace
				# --------------------------------------------------
    open(QUOTA, $exeDu." $fileSysLoc |") || 
	return(0,"*** err=9221\n"."*** ERROR $sbrName: failed to execute du ($exeDu)");

    $spaceUsage=0;
    while (<QUOTA>) {
				# skip du for dir
	next if ($_ !~ /$fileSysLoc/);
				# line e.g. '86044   /home/$ENV{USER}/scr'
	$tmp=$_;
	$tmp=~s/^\s*(\d+)[\s\t]+(\S+).*$//;
	$spaceUsage=   $1;	# disk usage
	$fileSysRd= $2;	# file system
	print "-*- WARN $sbrName: du read=$fileSysRd, wanted=$fileSysLoc!\n"
	    if ($fileSysRd !~ $fileSysLoc);
    }
    close(QUOTA);
				# ------------------------------
				# more space allocated than used
				#    -> return
    return(1,"no action")
	if ($spaceUsage < $kbAllocated);

				# ------------------------------
				# more space used than allocated
				#    -> delete
    printf "-*- WARN $sbrName: space quota violation on $fileSysLoc : %s",$DateLoc;
    printf "            usage=$spaceUsage, quota=$kbAllocated\n";
				# ------------------------------
				# set trash to 0 if part of the 
				#    stuff over space!
    $dirTrashTmp=$dirTrash;
    $dirTrashTmp=0              if ($dirTrash =~/$fileSysLoc/);
				# **************************************************
				# note: no error state, since sbr will abort program
				#       in case of an ERROR!!!
				# **************************************************
    &ctrlSpaceFreeSpace($exeNice,$dirSavePred,$dirTrashTmp,$LdebugLoc); 
    return(1,"over space");
}				# end of ctrlSpaceDuCheck

# ================================================================================
sub ctrlSpaceNumberCheck {
    local ($exeNice,$exeTar,$fileScanOut,$dirSavePred,$dirBupErr,$dirBupErrIn,
	   $prefixFileBupTar,$spaceNumFileKeep)=@_;
    local ($dir,$dir2,$tmp,@fileList,@fileList2,$LisDuError);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   ctrlSpaceNumberCheck        checks numbers of files used
#       in:                     
#       in GLOBAL:              $scrName
#       out:                    implicit: tar file 
#       err:                    (1,ok) || (0,"error message")
#-------------------------------------------------------------------------------
    $sbrName=$scrName.":"."ctrlSpaceNumberCheck";
				# ------------------------------
				# list all files in bup dir
				# NOTE: they are all compressed!
    $dirSavePredTmp=$dirSavePred;$dirSavePredTmp=~s/\/$//g;
    $#fileList=0;
    opendir(DIR,$dirSavePredTmp) ||
	warn("-*- WARN $sbrName: failed opening dirSavePred=$dirSavePredTmp!\n");
    @fileList=grep(/gz$/, readdir(DIR));
    closedir(DIR);
				# ------------------------------
				# tar files, as there are too many
    if ($#fileList > $spaceNumFileKeep) {
	$#tmp=0;
	$dirTmp=$dirSavePredTmp;
	$dirTmp.="/"            if ($dirTmp !~/\/$/);

				# add dir
	foreach $file (@fileList){
	    next if (-e $file);
	    $file=$dirSavePredTmp."/".$file; 
	    $file=~s/(\/)\/+/$1/g; # security
	    next if (! -e $file);
	    push(@tmp,$file); }
	@fileList=@tmp; $#tmp=0;
				# check
	$LisDuError=0;
	foreach $file (@fileList){
	    next if ($file !~ /$dirSavePredTmp/);
	    next if (-e $file);
	    $file=$dirSavePredTmp."/".$file; }
	($Lok,$msg)=
	    &ctrlSpaceFreeFile($exeNice,$exeTar,$fileScanOut,$dirSavePred,
			       $prefixFileBupTar,$spaceNumFileKeep,$LisDuError,@fileList); 
	if (! $Lok) { $msgErr="ABORT\n"."*** err=9211\n".
			  "*** ERROR $sbrName: ctrlSpaceFreeFile failed\n".$msg;
		      return(0,$msgErr); } }

				# ------------------------------
				# list all files in dir_bup_err
    $#fileList2=0;
    $dir2=$dirBupErr;$dir2=~s/\/$//g;
    opendir(DIR,$dir2) ||
	warn("-*- WARN $sbrName: failed opening dirBupErr=$dir2!\n");
    @fileList2=grep(/gz$/, readdir(DIR));
    closedir(DIR);
				# delete files as too many
    if ($#fileList2 > $spaceNumFileKeep) {
	foreach $file (@fileList2){
	    $tmp=$dir2."/".$file;
	    &ass_unlinkSecurity($tmp) if (-e $tmp); }}

				# ------------------------------
				# list all files in dir_bup_errIn dir
    $#fileList2=0;
    $dir2=$dirBupErrIn;$dir2=~s/\/$//g;
    opendir(DIR,$dir2) ||
	warn("-*- WARN $sbrName: failed opening dirBupErrIn=$dir2!\n");
    @fileList2=grep(/gz$/, readdir(DIR));
    closedir(DIR);
				# delete files as too many
    if ($#fileList2 > $spaceNumFileKeep) {
	foreach $file(@fileList2){
	    $tmp=$dir2."/".$file;
	    &ass_unlinkSecurity($tmp) if (-e $tmp); }}

    $#fileList2=$#fileList=0;	# slim is in

    return(1,"ok");
}				# end of ctrlSpaceNumberCheck

# ================================================================================
sub ctrlSpaceQuotaCheck {
    local ($exeQuota,$exeNice,$exeTar,$fileSys,$fileScanOut,$DateLoc,$LdebugLoc,
	   $dirSavePred,$dirBupErr,$dirBupErrIn,$dirTrash,
	   $prefixFileBupTar,$spaceNumFileKeep)=@_;
    local ($spaceUsage,$spaceQuota,$fileUsage,$fileQuota,$LisQuotaError,$i,@fileList,@fileList2);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   ctrlSpaceQuotaCheck        checks system quota, deletes, or moves run stuff
#       in:                     
#       in GLOBAL:              Q_* from init_quota
#       in GLOBAL:              $scrName
#       out:                    implicit: tar file 
#       err:                    (1,ok) || (0,"error message")
#-------------------------------------------------------------------------------
    $sbrName=$scrName.":"."ctrlSpaceQuotaCheck";
				# --------------------------------------------------
				# check if we exceed the disk and/or file quota
				# if files exeeded call ctrlSpaceFreeFile
				# if space exeeded call ctrlSpaceFreeSpace
				# --------------------------------------------------
    open(QUOTA, $exeQuota." |") || 
	return(0,"*** err=9232\n"."*** ERROR $sbrName: failed to execute quota ($exeQuota)");

    $LtooManyFiles=0;
    $LtooManyBytes=0;

    while (<QUOTA>) {
				# skip quota for different file systems
	next if ($_ !~ /\/$fileSys/);

	chop $_;		# ------------------------------
				# get the quota values
	$_=~s/\s*$//g;
	$spaceUsage=substr($_,1,$Q_space_usage);   $spaceUsage=~s/\s*$//g;$spaceUsage=~s/^.* //;
	$spaceQuota=substr($_,1,$Q_space_quota);   $spaceQuota=~s/\s*$//g;$spaceQuota=~s/^.* //;
	$spaceTime= substr($_,1,$Q_space_timeleft);$spaceTime=~s/\s*$//g; $spaceTime=~s/^.* //;
	$fileUsage= substr($_,1,$Q_file_usage);    $fileUsage=~s/\s*$//g; $fileUsage=~s/^.* //;
	$fileQuota= substr($_,1,$Q_file_quota);    $fileQuota=~s/\s*$//g; $fileQuota=~s/^.* //;
	$fileTime=  substr($_,1,$Q_file_timeleft); $fileTime=~s/\s*$//g;  $fileTime=~s/^.* //;
				# ------------------------------
	$LisQuotaError= 0;	# check file quota
	if ( $fileUsage > $fileQuota ) {
	    $LtooManyFiles=1;
	    $LisQuotaError=0;	# error: only if no time left!!
				# (yy) check this!!
	    $LisQuotaError=1    if (length($fileTime) == 0);
	    printf "-*- WARN $sbrName: file quota violation on $fileSys :%s",$DateLoc;
	    print  "-*-         usage: $fileUsage, quota: $fileQuota\n";
				# **************************************************
				# note: aborts if $LisQuotaError
				# **************************************************
	    ($Lok,$msg)=
		&ctrlSpaceFreeFile($exeNice,$exeTar,$fileScanOut,$dirSavePred,
			       $prefixFileBupTar,$spaceNumFileKeep,$LisQuotaError,@fileList); 
	                        if (! $Lok) {
				    $msgErr="*** err=9233\n".
					"*** ERROR $sbrName: ctrlSpaceFreeFile failed\n".$msg;
				    print $fhTraceLoc $msgErr,"\n";
				    &ctrlAbort($msgErr,"PP_ERROR_scanner_sbrQuota"); } }
				# ------------------------------
	else {			# check the number of files $dirSavePred
	    $#fileList=0;
	    opendir(DIR,$dirSavePredTmp) ||
		warn("-*- WARN $sbrName: failed opening dirSavePredTmp=$dirSavePredTmp!\n");
	    @fileList=grep(/gz$/, readdir(DIR));
	    closedir(DIR);
	    if ($#fileList > $fileQuota) {
		$LtooManyFiles=1;
		$LisQuotaError=0; # error: only if no time left!!
		foreach $file(@fileList){
		    $file=$dirSavePredTmp."/".$file if ($file !~ /$dirSavePredTmp/);}
				# **************************************************
				# note: aborts if $LisQuotaError
				# **************************************************
		($Lok,$msg)=
		    &ctrlSpaceFreeFile($exeNice,$exeTar,$fileScanOut,$dirSavePred,
				   $prefixFileBupTar,$spaceNumFileKeep,$LisQuotaError,@fileList); 
	                        if (! $Lok) {
				    $msgErr="*** err=9234\n".
					"*** ERROR $sbrName: ctrlSpaceFreeFile failed\n".$msg;
				    print $fhTraceLoc $msgErr,"\n";
				    &ctrlAbort($msgErr,"PP_ERROR_scanner_sbrQuota2"); } } }
				# ------------------------------
				# check space quota
	if ($spaceUsage > $spaceQuota) {
	    $LtooManyBytes=1;
	    printf "-*- WARN $sbrName: space quota violation on $fileSys : %s",$DateLoc;
	    printf "            usage=$spaceUsage, quota=$spaceQuota\n";
				# **************************************************
				# note: no error state, since sbr will abort program
				#       in case of an ERROR!!!
				# **************************************************
	    &ctrlSpaceFreeSpace($exeNice,$dirSavePred,$dirTrash,$LdebugLoc); }
	last; }
    close(QUOTA);

    $#fileList=$#fileList2=0;	# small is in
    return(1,"over space")      if ($LtooManyBytes);
    return(1,"over files")      if ($LtooManyFiles);
    return(1,"ok");
}				# end of ctrlSpaceQuotaCheck

# ================================================================================
sub ctrlSpaceQuotaInit {
    local($exeQuota)=@_;
    local($i);
#-------------------------------------------------------------------------------
#   ctrlSpaceQuotaInit         get the position of colum from quota command
#                              NOTE: $Q_* undefined in ini!
#-------------------------------------------------------------------------------
    $sbrName=$scrName.":"."ctrlSpaceQuotaInit";

    open(QUOTA, $exeQuota." |") ||
	return(0,"*** err=9231\n"."*** ERROR $sbrName: failed to execute quota ($exeQuota)");
				# get end position of colums in result string of quota command
    while (<QUOTA>) {
				# all but ALPHA
	if    ($_=~/usage/) {
	    $Q_space_usage=   index($_, "usage")    + 5;
	    $Q_space_quota=   index($_, "quota")    + 5;
	    $Q_space_limit=   index($_, "limit")    + 5; 
	    $Q_space_timeleft=index($_, "timeleft") + 5; 
	    $Q_file_usage=    index($_, "files",    $Q_space_usage)    + 5;
	    $Q_file_quota=    index($_, "quota",    $Q_space_quota)    + 5; 
	    $Q_file_limit=    index($_, "limit",    $Q_space_limit)    + 5; 
	    $Q_file_timeleft= index($_, "timeleft", $Q_space_timeleft) + 5; }
				# DEC ALPHA
	elsif ($_=~/blocks/) {
	    $Q_space_usage=   index($_, "blocks")   + 5;
	    $Q_space_quota=   index($_, "quota")    + 5;
	    $Q_space_limit=   index($_, "limit")    + 5; 
	    $Q_space_timeleft=index($_, "grace")    + 5; 
	    $Q_file_usage=    index($_, "files",    $Q_space_usage)    + 5;
	    $Q_file_quota=    index($_, "quota",    $Q_space_quota)    + 5; 
	    $Q_file_limit=    index($_, "limit",    $Q_space_limit)    + 5; 
	    $Q_file_timeleft= index($_, "grace",    $Q_space_timeleft) + 5; }
    }
    close(QUOTA);
    return(1,"ok");
}				# end of ctrlSpaceQuotaInit

#===============================================================================
sub sysSendMail {
    local($exeMailLoc,$fileInLoc,$receiverLoc,$subjLoc) = @_ ;
    local($sbrName,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   sysSendMail                 sends mail
#       in:                     $exeMailLoc : exe mail (/usr/sbin/Mail)
#       in:                     $fileInLoc :  file with text to mail 
#                                             if ! file: just echo 'txt'
#       in:                     $receiverLoc: 
#       in:                     $subjLoc :    optional
#       out:                    <1|0>,<'system command'|$errorMsg>, (0 if sending failed)
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."sysSendMail";
    $fhinLoc="FHIN_"."sysSendMail";$fhoutLoc="FHOUT_"."sysSendMail";
				# check arguments
    return(&errSbr("not def fileInLoc!"))       if (! defined $fileInLoc);
    return(&errSbr("not def exeMailLoc!"))      if (! defined $exeMailLoc);
    return(&errSbr("not def receiverLoc!"))     if (! defined $receiverLoc);
    $subjLoc="NO_SUBJECT"                       if (! defined $subjLoc);
#    return(&errSbr("miss fileIn=$fileInLoc!"))  if (! -e $fileInLoc &&
#						    ! -l $fileInLoc);
    return(&errSbr("miss fileIn=$exeMailLoc!")) if (! -e $exeMailLoc &&
						    ! -l $exeMailLoc);
				# (1) is file 
    if (-e $fileInLoc || -l $fileInLoc) {
#	$cmd="cat $fileInLoc | rsh parrot '$exeMailLoc -s $subjLoc $receiverLoc'";}
	$cmd="cat $fileInLoc | $exeMailLoc -s '$subjLoc' $receiverLoc";}
				# (2) is text string
    else {
#	$cmd="echo $fileInLoc | rsh parrot '$exeMailLoc -s $subjLoc $receiverLoc'";}
	$cmd="echo $fileInLoc | $exeMailLoc -s '$subjLoc' $receiverLoc";}

				# (3) send now
    ($Lok,$msgSys)=&sysSystem($cmd);
    return(1,$cmd);
}				# end of sysSendMail

#==============================================================================
# library collected (begin)
#==============================================================================

#===============================================================================
sub errSbr    {local($txtInLoc,$sbrNameLocy) = @_ ;
#-------------------------------------------------------------------------------
#   errSbr                      simply writes '*** ERROR $sbrName: $txtInLoc'
#-------------------------------------------------------------------------------
	       $sbrNameLocy=$sbrName if (! defined $sbrNameLocy);
	       $txtInLoc.="\n";
	       $txtInLoc=~s/\n\n+/\n/g;
	       return(0,"*** ERROR $sbrNameLocy: $txtInLoc");
}				# end of errSbr

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

#===============================================================================
sub sysSystem {
    local($cmdLoc,$fhLoc) = @_ ;
    local($sbrName,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   sysSystem                   simple way of running system command + documenting them
#       in:                     $cmd:   will do system($cmd)
#       in:                     $fhLoc: will write trace onto fhLoc
#                                 =<0|! defined> -> STDOUT
#       out:                    <1|0>,<"value from system"|$errorMessag>
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";$sbrName=$tmp."sysSystem";
				# no argument given
    return(0,"*** ERROR $sbrName: no input argument (system command)")
	if (! defined $cmdLoc || ! $cmdLoc);

				# default
    $fhLoc="STDOUT"             if (! defined $fhLoc);
    
				# ------------------------------
				# write
    if( $fhLoc )
    {
    	print $fhLoc "---  system: \t $cmdLoc\n";
	#cluck( "---  system: \t $cmdLoc" );
    }

				# ------------------------------
				# run system
    $Lsystem=
	system("$cmdLoc");

    return(1,$Lsystem);
}				# end of sysSystem

#==============================================================================
# library collected (end)
#==============================================================================




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
# vim:et:
