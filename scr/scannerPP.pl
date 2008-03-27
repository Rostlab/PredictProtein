#!/usr/bin/perl -w
##!/usr/local/bin/perl -w
##!/usr/pub/bin/perl5 -w
##!/usr/pub/bin/perl5.003 -w
##! /usr/pub/bin/perl -w
#
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
#                                                                                 #
#	Copyright				  Dec,    	1994	          #
#	Burkhard Rost &		rost@EMBL-Heidelberg.DE			          #
#	Antoine de Daruvar	daruvar@lion-ag.de                                #
#	Guy Yachdav             yachdav@cubic.bioc.columbia.edu  	          #
#	EMBL			http://www.embl-heidelberg.de/~rost/	          #
#	D-69012 Heidelberg						          #
#			    br  v 1.5	          Nov,          1996              #
#			    br  v 2.0	          Feb,          1998              #
#			    br  v 2.1	          Feb,          1998              #
#			    br  v 2.3	          May,          1998              #
#			    br  v 2.4	          Jul,          1998              #
#			    br  v 2.5	          Sep,          1998              #
#			    br  v 2.6	          Oct,          1998              #
#			    br  v 2.7	          Nov,          1998              #
#			    br  v 2.8             Jan,          1999              #
#			    br  v 2.9             Feb,          1999              #
#			    br  v 3.0             Apr,          1999              #
#------------------------------------------------------------------------------   #
# 
#    This script does all the work required to run the PredictProtein server.
#    It is started by scannerPPctrl.pl, which in turn is restarted by a
#       cron-job (i.e. whenever machine went down).
#    It runs an endless loop.
#    
#    
#    ------------------------------
#    to stop the scanner:
#    ------------------------------
# 
#       to let the scanner die, you simply have to delete the file
#       $envPP{'file_scanFlag'} (e.g. PP_SCAN_RUN.flag)
#       the scanner runs the infinite loop only while this file exists!
#    
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
#    action(s)
#    ------------------------------
#    
#    Once = done at startup:
#    * checks space quota, frees space
#    * detects dead requests
#    * writes status report to WWW  (wwwStatusPP.pl)
#    
#    Loop = done in infinite loop (while flag file $envPP{'file_scanFlag'} exists):
#    * scans the file(s) generated by:
#      (a) procmail                 (procmailPP.pl)
#      (b) cgi-script from WWW      (submitPP.pl)
#      see 'assumptions'
#      see 'file format'
#    * runs the predictions         (predictPP.pl)
#    * sends mail to user           ()
#    *        ()
#    *        ()
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
#    ------------------------------
#    assumptions
#    ------------------------------
#
#    The following assumption are made:
#    * the name of the file to predict must start with the string "pred_"
#    * the resulting file has the same name with an additional "_done"
#      extension and it will be put:
#       => in the same dir as the input file if response_mode = "html"
#       => send to the submitter as a mail if response_mode = "mail"
#       (see here after the input file format...)
#
#    ------------------------------
#    action(s) details
#    ------------------------------
#
#    The complete mechanism is:
#    - file "pred_jobid" is found in the scan dir (/server/pred/)
#    - it is moved in the work dir and rename as "predict_jobid" (/server/work/)
#    - if the response is mail, a mail_query file is created to remember
#      the user address and have a trace of the request (/server/mail/)
#    - prediction is run and result put in the file "pred_[eh]\d*_done" 
#      in scan directory (html response) or mail directory (mail response)
#      (/server/result/)
#    - The mail directory is also scaned and when a result file
#      is found a mail is send using the query file
#
#    ------------------------------
#    file formats
#    ------------------------------
#
#    The input file must contain the folowing lines:
#    - from user_addr     (the e-mail address of the submitter)
#    - ...password(my_pwd)... ()
#    - orig MAIL|HTML     (the origin of the server call)
#    - resp MAIL|HTML     (the response mode: via email or immediate)
#
#    ------------------------------
#    missing (to be done one day)
#    ------------------------------
#
#    detect and send an alarm in the following cases:
#    - a mail query file is more than "max pred time" old --> send sorry mail
#    - a mail result file has no query file  ---> remove it
#    - a not mail result file is old ---> remove it
#
#------------------------------------------------------------------------------#

$[ =1 ;				# start counting at 1
				# --------------------------------------------------
				# initialise environment parameters
				# --------------------------------------------------
($Lok,$msg)=
    &ini();

				# ******************************
				# *** error in local env
&ctrlAbort("*** ERROR $scrName: $msg","PP_ERROR_scanner_ini") if (! $Lok);
				# ******************************

				# --------------------------------------------------
				# redirect STDOUT and STDERR
				# --------------------------------------------------
if (! $Ldebug){
				# STDOUT to file_scanOut
    open (STDOUT, ">>".$envPP{"file_scanOut"})
	|| warn "*** WARN $scrName cannot open new (".$envPP{"file_scanOut"}.")\n";
				# STDERR to file_scanErr
    open (STDERR, ">>".$envPP{"file_scanErr"})
	|| warn "*** WARN $scrName cannot open new (".$envPP{"file_scanErr"}.")\n";
				# flush output
    $| = 1; }
				# ==================================================
				# security: exit if scanner running already!
				# ==================================================

				# hack br 98-04
				# check whether scanner is running (envPP.pm)
$scrNameFull=$0; $scrNameFull=~s/^.*\///g;
($Lok,$njobs)=
    &envPP'isRunningEnv($scrNameFull,$envPP{"exe_ps"},"STDOUT");      # e.e'

				# NOTE: number > 1 since one comes from current job!
if ($Lok && $njobs > 1 ||! $Lok) { 
    $msgErr="*** ERROR $scrName: Nscanners running=$njobs!\n".
	    "***            you need it again???\n";
    print $msgErr,"\n";
    &ctrlAbort($msgErr,"PP_ERROR_scanner_ini2"); }
				# --------------------------------------------------
				# clean up space
				# note: may abort the scanner when errors happen..
				# --------------------------------------------------
($Lok,$msg)=
    &scannerBeforeLoop();
				# tolerate errors here
if (! $Lok) { $msgErr= "";
	      $msgErr.="*** err=9200\n" if ($msg !~ /err\=/);
	      $msgErr.="*** ERROR $scrName: Nscanners running=$njobs!\n";
	      $msgErr.="***            you need it again???\n".$msg."\n";
	      print $msgErr;
	      &ctrlSendAlarm($msgErr,"PP_WARN_before_loop"); }


# ================================================================================
#                              ----------------------
# = infinite scanning loop =   INFINITE SCANNING LOOP   = infinite scanning loop = 
#                              ----------------------
# ================================================================================


while (-e $envPP{"file_scanFlag"}) {
				# --------------------------------------------------
				# rest a while before going into next loop
    sleep(2);


				# -------------------------------------------------
				# (1) PROCMAIL INPUT SCANNING
				#     - scan PROCMAIL input directory (server/inProc) 
				#  -> start procmail.pl FILE when FILE detected 
				# --------------------------------------------------
    ($Lok,$msg)=		# 
	&scannerProcessInputMail($envPP{"exe_ppEmailproc"},$envPP{"dir_inProcmail"},
				 $envPP{"file_procmailInLog"},$Ldebug);

				# tolerate errors (!)
    if (! $Lok) { $msgErr= "";
		  $msgErr.="*** err=9400\n" if ($msg !~ /err\=/);
		  $msgErr.="*** ERROR $scrName: after processing PROCMAIL input ";
		  $msgErr.="(scannerProcessInputMail)\n".$msg."\n";
		  print $msgErr;
		  &ctrlSendAlarm($msgErr,"PP_ERROR_scanner_inputMail"); } # 
    

				# --------------------------------------------------
				# (2) PREDICTION SCANNING
				#     - scan predict dir: any file to predict found?
                                #       <--- RETURN ok, if none found !
				#     - check quota
				#       <--- RETURN error, if not enough space
				#     - determine which machine to use
				#       <--- LOOP until machine free !!!
				#     - build names of :
				#       file_found:      input file
				#       file_new:        name of file in work dir (the one to run)
				#       file_result:     file with the result (server/res)
				#       file__mailQuery: file with
				#                           user,orig,response_mode (server/mail)
				#     - SUBMIT the prediction JOB
				#       >>>>>>
                                #  NOTE: for debug mode (LdbgLoc) screen dump into locally named file
				#        >>>>>>
				# --------------------------------------------------

    ($Lok,$msg)=
	&scannerPredict($predictScrName,$envPP{"exe_nice"},$envPP{"exe_ppPredict"},
			$envPP{"exe_du"},$envPP{"exe_quota"},$envPP{"exe_tar"},
			$fileSys,$fileRundir,$dirWork,$envPP{"dir_prd"},$envPP{"dir_trash"},
			$envPP{"dir_res"},$envPP{"dir_mail"},$envPP{"dir_bup_res"},
			$envPP{"dir_bup_err"},$envPP{"dir_bup_errIn"},$envPP{"par_patDirPred"},
			$envPP{"prefix_prd"},$envPP{"prefix_work"},
			$envPP{"suffix_res"},$envPP{"suffix_mail"},$envPP{"suffix_lock"},
			$envPP{"ctrl_checkDu"},$envPP{"ctrl_checkQuota"},$envPP{"ctrl_kbAllocated"},
			$envPP{"prefix_fileBupTar"},$envPP{"ctrl_numFileKeep"},
			$envPP{"file_scanLog"},$envPP{"file_scanMach"},$envPP{"file_scanFlag"},
			$envPP{"password_def"},$Ldebug);
    if    (! $Lok)  { $msgErr= "";
		      $msgErr.="*** err=9600\n";
		      $msgErr.="*** ERROR $scrName: after trying to predict (scannerPredict)\n";
		      $msgErr.=$msg."\n";
		      print $msgErr;
		      &ctrlSendAlarm($msgErr,"PP_ERROR_scanner_predict"); }
				# no user|origin
    elsif ($Lok==2) { $msgErr= "";
		      $msgErr.="*** err=9602\n";
		      $msgErr.="-*- WARN $scrName: after trying to get prediction\n".$msg."\n";
		      print $msgErr; }

				# --------------------------------------------------
				# (3) MAIL RESPONSE SCANNING
				# we no longer run this on dodo
				# 
				# Scanning of the mail directory: when a prediction is complete
				# send a mail using address stored in the mail query file
				# --------------------------------------------------


				# --------------------------------------------------
				# (4) delete dead results
				# 
				# Scanning the directory server/res, throw away garbage!
				# we no longer run this on dodo
				# --------------------------------------------------


				# --------------------------------------------------
				# (5) handle license requests
				# we no longer run this on dodo
				# --------------------------------------------------
}
# ================================================================================
# end of infinite scanning loop (while file_scanFlag)
# ================================================================================

exit(1);



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
	$env_pack = "/nfs/data5/users/$ENV{USER}/server/scr/envPP.pm"; } # HARD CODDED, HARD_CODDED

    $Lok=
	require $env_pack;
                    		# *** error in require env
    return(0,"*** ERROR $scrName: require env_pack=".$env_pack."\n".
	   "*** err=9101")      if (! $Lok);
				# ------------------------------
				# debug mode
    $Ldebug=0;
    foreach $arg (@ARGV){
	next if ($arg!~/^de?bu?g$/i);
	$Ldebug=1;
	last;}
				# ------------------------------
				# read local environment var
				# ------------------------------
    foreach $des ("dir_work",	# working
		  "file_scanOut","file_scanMach","file_scanErr","file_scanFlag",
		  "para_status","file_statusFlag","file_statusHis","file_statusAdd",
				# input
		  "dir_inProcmail","dir_prd","par_patDirPred",
				# output
		  "dir_res","dir_mail","dir_lic",
		  "dir_bup_err","dir_bup_errIn","dir_bup_errMail","dir_bup_res","dir_trash",
		  "dir_bup_lic",
				# executables: system stuff
		  "exe_nice","exe_mail","exe_tar","exe_quota","exe_ps","exe_find","exe_du",
				# executables + packages
		  "exe_mailHtml",

		  "exe_ppPredict",
		  "exe_ppEmailproc", # script processing the file created by procmail
		  "exe_scan_clean",
		  #"exe_status",
				# parameters
		  "machines", "pp_admin", "password_def",
		  "ctrl_timeoutQuery","ctrl_timeoutRes",
		  "ctrl_numFileKeep","ctrl_numLinesLog","ctrl_kbAllocated",
		  "ctrl_checkQuota","ctrl_checkDu",
				# file names
		  "prefix_prd","prefix_work","suffix_mail","suffix_res",
		  "prefix_fileBupTar","suffix_lock",
				# log files
		  "file_crontabLog","file_errLog",
		  "file_emailReqLog","file_htmlReqLog",
		  "file_licenceComLog","file_licenceNotLog",
		  "file_scanLog","file_sendLog","file_predMgrLog","file_statusLog",
		  "file_ppLog","file_procmailLog","file_procmailInLog",
		  "file_sorryTimeout",
		  "file_licence","file_licFlag","file_licNew",
		  "file_htmlCgiLog","file_releaseLockLog",
		  "prefix_lic","pattern_lic",
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
	"rost\@columbia.edu" if (! defined $envPP{"pp_admin"});
    if (! defined $envPP{"exe_mail"}){
	if (-e "/usr/sbin/Mail" ){
	    $envPP{"exe_mail"}="/usr/sbin/Mail" ;}
	else                     {
	    $envPP{"exe_mail"}="/usr/bin/Mail" ;}}

				# remove path to extract process name
    $predictScrName=$envPP{"exe_ppPredict"}; $predictScrName=~ s/^.*\///;

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
				# get machines
    $machines=         $envPP{"machines"};
    @Candidate_machine=split(";",$machines);
				# no rsh for same machine!!
    $Lone_machine=     0;
    $Lone_machine=     1        if ($#Candidate_machine==1);

				# security hack: only ONE on parrot!!!
    $Candidate_machine[1]=~s/\d+\s*$/1/
	if ($Lone_machine && $Candidate_machine[1]=~/parrot/);

    $LscanCleanUp=1;   $LscanCleanUp=0 if (! $envPP{"exe_scan_clean"});

				# ------------------------------
				# get the date
    $Date=&sysDate();
    
    return(1,"ok");
}				# end of ini

#===============================================================================
sub scannerBeforeLoop {
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   scannerBeforeLoop           cleans up space asf:
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
    $sbrName=$tmp."scannerBeforeLoop";

				# --------------------------------------------------
				# (1) check file quota
				# delete files if necessary
				#        *********
				# NOTE:  aborts if no files can be deleted!!!
				#        *********
				# --------------------------------------------------

				# ------------------------------
				# (1) number of files (check anyway!)
    ($Lok,$msg)=
	&ctrlSpaceNumberCheck($envPP{"exe_nice"},$envPP{"exe_tar"},$envPP{"file_scanOut"},
			      $envPP{"dir_bup_res"},
			      $envPP{"dir_bup_err"},$envPP{"dir_bup_errIn"},
			      $envPP{"prefix_fileBupTar"},$envPP{"ctrl_numFileKeep"});
    if (! $Lok){ $msgErr= "";
		 $msgErr.="*** err=9210\n" if ($msg !~ /err\=/);
		 $msgErr.="*** ERROR $scrName: ctrlSpaceNumberCheck failed\n".$msg;
		 print $msgErr,"\n";
		 &ctrlAbort($msgErr,"PP_ERROR_scannerBeforeLoop"); }
	
				# ------------------------------
				# (2) space used
				#     note: first argument =1 ->
				#           check after deletion again!
    if ($envPP{"ctrl_checkDu"} || $envPP{"ctrl_checkQuota"}) {
	($Lok,$msg)=
	    &ctrlSpaceCheck(1,$envPP{"ctrl_checkDu"},$envPP{"ctrl_checkQuota"},
			    $envPP{"exe_nice"},
			    $envPP{"exe_du"},$envPP{"exe_quota"},$envPP{"exe_tar"},
			    $fileSys,$fileRundir,$envPP{"file_scanOut"},$Date,$Ldebug,
			    $envPP{"dir_bup_res"},$envPP{"dir_trash"},
			    $envPP{"dir_bup_err"},$envPP{"dir_bup_errIn"},
			    $envPP{"ctrl_kbAllocated"},
			    $envPP{"prefix_fileBupTar"},$envPP{"ctrl_numFileKeep"});
				# note: if repeat still over quota : error returned!
	if (! $Lok){ $msgErr= "";
		     $msgErr.="*** err=9220\n" if ($msg !~ /err\=/);
		     $msgErr.="*** ERROR $scrName: ctrlSpaceCheck failed\n".$msg;
		     print $msgErr,"\n";
		     &ctrlAbort($msgErr,"PP_ERROR_scannerBeforeLoop"); }}
				# ------------------------------
    else { $msg="ok";		# no quota check! 
	   print "-*- NOTE $scrName: no quota check!\n"; }

				# --------------------------------------------------
				# (2) restrict number of lines of all log files
				# --------------------------------------------------
    foreach $kwd ("file_scanErr","file_scanLog","file_scanFlag","file_scanOut","file_scanMach",
		  "file_crontabLog","file_procmailLog",
		  "file_sendLog","file_emailReqLog","file_htmlReqLog",
		  "file_licenceComLog","file_licenceNotLog",
		  "file_errLog","file_predMgrLog","file_releaseLockLog",
		  "file_htmlCgiLog",
		 ){
	next if (! -e $envPP{$kwd});
	($Lok,$msg)=
	    &ctrlFileRestrict($envPP{$kwd}, "H", $envPP{"ctrl_numLinesLog"},$kwd);
	print "xx kwd=$kwd, file=",$envPP{$kwd},", returned ($Lok,$msg)\n";
				# tolerate ERRORS here!
	if (! $Lok){ $msgErr="*** err=9270\n".
			 "*** ERROR $scrName: ctrlFileRestrict failed\n".$msg;
		     print $msgErr,"\n";
		     &ctrlSendAlarm($msgErr,"PP_WARN_scanner");}
				# set access for WWW log file
	if ($kwd=~/^file_htmlReqLog/) {
	    $file=$envPP{$kwd};
	    ($Lok,$msgSys)=&sysSystem("chmod 666 $file"); }
    }

				# --------------------------------------------------
				# (3) clean up dead requests
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
		 &ctrlAbort($msgErr,"PP_ERROR_scannerBeforeLoop"); }

				# --------------------------------------------------
				# (4) clean up other old files
				# --------------------------------------------------
    if ((-e $envPP{"exe_scan_clean"} && -x $envPP{"exe_scan_clean"})
	|| -l $envPP{"exe_scan_clean"}) {
	$cmdSystem=$envPP{"exe_nice"}." ".$envPP{"exe_scan_clean"}." auto";
	print "--- $scrName: clean up by system call ($cmdSystem)\n";
	($Lok,$msgSys)=&sysSystem("$cmdSystem"); }

				# --------------------------------------------------
				# (5) report status of PP server to WWW docs
				# 
				# not done on dodo anymore
				# --------------------------------------------------

    return(1,"ok $sbrName"); 
}				# end of scannerBeforeLoop


#===============================================================================

sub scannerProcessInputMail {
    local($exe_ppEmailprocLoc,$dirInProcmailLoc,$file_procmailInLogLoc,$LdbgLoc)= @_ ;
    local($sbrName,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   scannerProcessInputMail     scans the dir written by PROCMAIL,
#                               processes procmail output, moving it to the prediction
#                               directory (server/prd)
#       in:                     
#         $dir_inProcmail       dir into which PROCMAIL writes        (server/inProc)
#         $exe_ppEmailproc      executable to process PROCMAIL output (scr/procmail.pl)
#                               RESULT: write file prd/pred_ID
#         $file_procmailInLog   log file                              (log/procmail-in.log)
#         $LdbgLoc              debug flag (if =1 write onto screen!)
#       out:                    note to $file_procmailInLog           (log/procmail-in.log)
#       err:                    ok=(1,'ok','blabla'), err=(0,errNumber,'msg')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;
    $sbrName="$tmp:"."scannerProcessInputMail";
    $errMsg="*** err=9401\n"."*** $sbrName: ";
				# beg xx br1:99-04-09: temporary to spot what happens
#    $dirLogTmpxx=   "/home/phd/server/bup/tmp-mail-in/";
#    $fileLogInputxx="/home/phd/server/bup/Log-of-mail-in.tmp";
#    $fhoutTmpLogxx= "FHOUT_TMP_LOG";
#    open($fhoutTmpLogxx,">".$fileLogInputxx);
				# end xx br1:99-04-09: temporary to spot what happens

				# ------------------------------
				# check arguments
    return(0,$errMsg."miss dir_inProcmailLoc!")     if (! defined $dirInProcmailLoc);
    return(0,$errMsg."miss $exe_ppEmailprocLoc!")   if (! defined $exe_ppEmailprocLoc);
    return(0,$errMsg."miss file_procmailInLogLoc!") if (! defined $file_procmailInLogLoc);
    $LdbgLoc=0                                      if (! defined $LdbgLoc);

    return(0,$errMsg."no exe exe_ppEmailprocLoc=$exe_ppEmailprocLoc!") 
	if (! -e $exe_ppEmailprocLoc && ! -l $exe_ppEmailprocLoc && ! -x $exe_ppEmailprocLoc);

				# security: purge final slash
    $dirInProcmailLoc=~s/\/$//g if ($dirInProcmailLoc =~/\/$/);

				# --------------------------------------------------
				# read content of directory into which all procmails
				#    are written by PROCMAIL
				# --------------------------------------------------
    $#INPROC=0;			# set 0
    opendir(DIR,$dirInProcmailLoc) ||
	warn("-*- WARN $sbrName: failed opening dirInProcmail=$dirInProcmailLoc!");
    @INPROC=grep(/procmail/, readdir(DIR));
    closedir(DIR);

				# ------------------------------
				# none found -> return
    return(1,"none found in $dirInProcmailLoc") 
	if ($#INPROC < 1);
	
				# --------------------------------------------------
				# process procmails results
				# --------------------------------------------------
				# add slash to dir
    $dirInProcmailLoc.="/"      if ($dirInProcmailLoc !~/\/$/);

				# loop over all files
    foreach $file (@INPROC) {
				# rename if no directory given
	$file=$dirInProcmailLoc.$file  if ($file !~ /^$dirInProcmailLoc/);

	print "--- $sbrName: do '$exe_ppEmailprocLoc $file'\n" if ($LdbgLoc);

				# ERROR...
	next if (! -e $file);
				# ------------------------------
				# extract the info from file
				# ------------------------------
	($Lok,$msgSys)=&sysSystem("$exe_ppEmailprocLoc $file");
#	($Lok,$msgSys)=&sysSystem("$exe_ppEmailprocLoc $file dbg");
				# ------------------------------
				# write trace of action
	($Lok,$msgSys)=&sysSystem("echo '$exe_ppEmailprocLoc $file' >> $file_procmailInLogLoc");
    }			# end of loop over all procmail input

    return(1,"ok $sbrName");
}				# end of scannerProcessInputMail

#===============================================================================


sub scannerPredict {
    local($predictScrNameLoc,$exeNiceLoc,$exePredictLoc,$exeDuLoc,$exeQuotaLoc,$exeTarLoc,
	  $fileSysLoc,$fileRundirLoc,$dirWorkLoc,$dirPredLoc,$dirTrashLoc,
	  $dirResLoc,$dirMailLoc,$dirSavePredLoc,$dirBupErrLoc,$dirBupErrInLoc,
	  $parPatDirPredLoc,$prefixPrdLoc,$prefixWorkLoc,$suffixResLoc,$suffixMailLoc,
	  $suffixLockLoc,$ctrlCheckDuLoc,$ctrlCheckQuotaLoc,
	  $ctrlKbAllocatedLoc,$prefixFileBupTarLoc,$ctrlNumFileKeepLoc,
	  $fileScanLogLoc,$fileScanMachLoc,$fileScanFlag,$passwordDef,$LdbgLoc) = @_ ;
    local($sbrName2,$tmp,$Lok,$errMsg,$fileFound,$fileResult,$fileMailQuery,
	  $user,$password,$orig,$resp,$cmd);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   scannerPredict              RUNS the prediction job:
#                               
#                               - finds oldest file in server/prd
#                                 <--- RETURN ok, if none found !
#                               - checks quota
#                                 <--- RETURN error, if not enough space
#                               - determines which machine to use
#                                 <--- LOOP until machine free !!!
#                               - builds names of :
#                                 fileFound:      input file
#                                 fileNew:        name of file in working dir (the one to run)
#                                 fileResult:     file with the result (server/res)
#                                 fileMailQuery:  file with 
#                                                     user,orig,response_mode (server/mail)
#                               - SUBMITS THE JOB  <--- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#----------------------------->>>
#                                 note: for debug mode (LdbgLoc) screen dump into locally named file
#----------------------------->>>
#       in:                     
#         $predictScrNameLoc    name of process running the prediction
#         $dirPredLoc           dir with files to be predicted (server/prd)
#         $parPatDirPredLoc     prefix of files in previous    (pred_)
#         $fileSysLoc        filessystem where all jobs run (home)
#         $fileRundirLoc        dir path where all jobs run    (/home/$ENV{USER}/run/)
#         $dirWorkLoc           working dir                    (server/work)
#         $dirTrashLoc          trash dir, to move stuff to    (/scrap/phd/err)
#         $dirResLoc            dir with final result files    (server/res)
#         $dirMailLoc           dir with mail query info       (server/mail)
#         $prefixPrdLoc         files in server/prd  called $prefixPrdLoc.'_'.ID_
#         $prefixWorkLoc        files in server/work called $prefixWorkLoc.'_'.ID_
#         $suffixResLoc        files in server/res  called $prefixWorkLoc.'_'.ID.$suffix
#         $suffixMailLoc       files in server/mail called $prefixWorkLoc.'_'.ID.$suffix
#         $exeNiceLoc         
#         $exe_ppPredictLoc     executable to run prediction   (predictPP.pl)
#         $fileScanLogLoc       log file for scanner output
#         $fileScanMachLoc      log file for prediction job 
#         $LdbgLoc              debug flag (if =1 write onto screen!)
#       err:                    (0,msg) -> some ERROR
#                               (1,msg) -> OK
#                               (2,msg) -> no user address found!
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName2="$tmp"."scannerPredict";
    $errMsg="*** err=9601\n"."*** $sbrName2: ";
				# ------------------------------
				# check arguments
    return(0,$errMsg."not def predictScrNameLoc!")   if (! defined $predictScrNameLoc);
    $exeNiceLoc=" "                                  if (! defined $exeNiceLoc);
    return(0,$errMsg."not def exePredictLoc!")       if (! defined $exePredictLoc);
    return(0,$errMsg."not def exeDuLoc!")            if (! defined $exeDuLoc);
    return(0,$errMsg."not def exeQuotaLoc!")         if (! defined $exeQuotaLoc);
    return(0,$errMsg."not def exeTarLoc!")           if (! defined $exeTarLoc);
    return(0,$errMsg."not def fileSystemLoc!")       if (! defined $fileSysLoc);
    return(0,$errMsg."not def fileRundirLoc!")       if (! defined $fileRundirLoc);
    return(0,$errMsg."not def dirWorkLoc!")          if (! defined $dirWorkLoc);
    return(0,$errMsg."not def dirPredLoc!")          if (! defined $dirPredLoc);
    return(0,$errMsg."not def dirTrashLoc!")         if (! defined $dirTrashLoc);
    return(0,$errMsg."not def dirResLoc!")           if (! defined $dirResLoc);
    return(0,$errMsg."not def dirMailLoc!")          if (! defined $dirMailLoc);
    return(0,$errMsg."not def dirSavePredLoc!")      if (! defined $dirSavePredLoc);
    return(0,$errMsg."not def dirBupErrLoc!")        if (! defined $dirBupErrLoc);
    return(0,$errMsg."not def dirBupErrInLoc!")      if (! defined $dirBupErrInLoc);
    return(0,$errMsg."not def parPatDirPredLoc!")    if (! defined $parPatDirPredLoc);
    return(0,$errMsg."not def prefixPrdLoc!")        if (! defined $prefixPrdLoc);
    return(0,$errMsg."not def prefixWorkLoc!")       if (! defined $prefixWorkLoc);
    return(0,$errMsg."not def suffixResLoc!")        if (! defined $suffixResLoc);
    return(0,$errMsg."not def suffixMailLoc!")       if (! defined $suffixMailLoc);
    return(0,$errMsg."not def suffixLockLoc!")       if (! defined $suffixLockLoc);
    return(0,$errMsg."not def ctrlCheckDuLoc!")      if (! defined $ctrlCheckDuLoc);
    return(0,$errMsg."not def ctrlCheckQuotaLoc!")   if (! defined $ctrlCheckQuotaLoc);
    return(0,$errMsg."not def ctrlKbAllocatedLoc!")  if (! defined $ctrlKbAllocatedLoc);
    return(0,$errMsg."not def prefixFileBupTarLoc!") if (! defined $prefixFileBupTarLoc);
    return(0,$errMsg."not def ctrlNumFileKeepLoc!")  if (! defined $ctrlNumFileKeepLoc);
    return(0,$errMsg."not def fileScanLogLoc!")      if (! defined $fileScanLogLoc);
    return(0,$errMsg."not def fileScanMachLoc!")     if (! defined $fileScanMachLoc);
    $LdbgLoc=0                                       if (! defined $LdbgLoc);
    return(0,$errMsg."no exe=exePredictLoc!")        if (! -e $exePredictLoc &&
							 ! -x $exePredictLoc &&
							 ! -l $exePredictLoc);


    undef $fileFound; undef $fileNew; undef $fileResult; undef $fileMailQuery;
				# --------------------------------------------------
				# find oldest file
    do {
	($Lok,$fileFound)=
	    &sysFileGetOldest($dirPredLoc,"^".$parPatDirPredLoc);
    } while ( $fileFound =~ /$suffixLockLoc$/ );

    $dirPredLoc=~s/\/$//g       if ($dirPredLoc=~/\/$/); # purge final slash
    $dirWorkLoc=~s/\/$//g       if ($dirWorkLoc=~/\/$/); # purge final slash
	    

				# add directory
    $fileLock = $dirPredLoc."/".$fileFound.$suffixLockLoc;



				# ==============================
				# <--- <--- <--- <--- <--- <--- 
				# RETURN: no request found
				# or lock file exists
    return(1,"no request found")
	if (! defined $fileFound or ! $fileFound or -f $fileLock);


				# <--- <--- <--- <--- <--- <--- 
				# ==============================

#    print  "--- $sbrName2: FOUND A REQUEST ($fileFound)\n";
				# --------------------------------------------------
				# check the space
				# delete files if necessary
				#        *********
				# NOTE:  aborts if no files can be deleted!!!
				#        *********
				#     note: first argument =1 ->
				#           check after deletion again!
				# --------------------------------------------------
    $dateTmp=&sysDate();
    if ($ctrlCheckDuLoc || $ctrlCheckQuotaLoc) { 
	($Lok,$msg)=
	    &ctrlSpaceCheck(0,$ctrlCheckDuLoc,$ctrlCheckQuotaLoc,
			    $exeNiceLoc,$exeDuLoc,$exeQuotaLoc,$exeTarLoc,
			    $fileSysLoc,$fileRundirLoc,$fileScanLogLoc,$dateTmp,$LdbgLoc,
			    $dirSavePredLoc,$dirTrashLoc,$dirBupErrLoc,$dirBupErrInLoc,
			    $ctrlKbAllocatedLoc,$prefixFileBupTarLoc,$ctrlNumFileKeepLoc);
				# note: if repeat still over quota : error returned!
	if (! $Lok){ $msgErr= "";
		     $msgErr.="*** err=9610\n" if ($msg !~ /err\=/);
		     $msgErr.="*** ERROR $scrName: ctrlSpaceCheck failed\n".$msg;
		     print $msgErr,"\n";
		     &ctrlAbort($msgErr,"PP_ERROR_scannerPredict_space"); }}

				# --------------------------------------------------
				# get a free machine
				# out: $machine_name and 
				#      $number_of_jobs_allowed_on_that_machine
				# --------------------------------------------------
    ($Lok,$machine,$numjobs_allowed)=
	&sysWhoWantsToWork($predictScrNameLoc,$fileScanFlag,$fileScanLogLoc);

				# note: usually repeated until machine found...
    if (! $Lok){ $msgErr= "";
		 $msgErr.="*** err=9620\n" if ($msg !~ /err\=/);
		 $msgErr.="*** ERROR $scrName: sysWhoWantsToWork failed\n".$machine;
		 print $msgErr,"\n";
		 &ctrlAbort($msgErr,"PP_ERROR_scannerPredict_machine"); }

				# --------------------------------------------------
				# run many jobs if many free!
				# --------------------------------------------------
    @fileFoundHere=($fileFound);
				# ------------------------------
				# get oldest files
    if ($numjobs_allowed > 1) {
	($Lok,@tmp)=
	    &sysFileGetOldestnn($dirPredLoc,"^".$parPatDirPredLoc,($numjobs_allowed-1));
	print "*** ERROR $sbrName2: after sysFileGetOldestnn msg=\n".$tmp[1]."\n" if (! $Lok); 
	push(@fileFoundHere,@tmp)   if ($Lok && $#tmp > 0); }
	    

    while (@fileFoundHere) {
	$fileFound=pop @fileFoundHere; 
				# add directory
	$fileFound=$dirPredLoc."/".$fileFound;

	next if (! -e $fileFound);
				# ------------------------------
				# prepare pred file from file found
	($Lok,$msg,$fileNew,$fileResult,$user,$orig,$password, $dbid)=
	    &scannerPredict_prepare($fileFound,
				    $dirWorkLoc,$dirPredLoc,$dirTrashLoc,$dirResLoc,$dirMailLoc,
				    $prefixPrdLoc,$prefixWorkLoc,$suffixResLoc,$suffixMailLoc,
				    $fileScanLogLoc,$passwordDef);

				# ----------------------------------
				# create a lock file for result first
				# in case the result is moved to cubic
				# before it's done.
	$fileResultLock = $fileResult.$suffixLockLoc;
	($Lok,$msgSys)=&sysSystem("touch $fileResultLock");
	return (0,"cannot create a lock file for the result\n".$msgSys)
	    if ( ! $Lok);

	
	



	# ************************************************************
	# this is IT, here the jobs are run  zzz
				# option '-s' redirect output to file
#	$cmd= "$exeNiceLoc $exePredictLoc $fileNew $fileResult $user $password $orig -s  >> $fileScanLogLoc";
	$cmd= "$exeNiceLoc $exePredictLoc $fileNew $fileResult $user $password $orig $dbid -s ";
				# write trace

				# do it with rsh!
				# note Lone_machine is GLOBAL
#	$cmd="rsh $machine '$cmd' " if (! $Lone_machine);

				# store trace of machine
#	($Lok,$msgSys)=&sysSystem("echo '$machine $fileNew' >> $fileScanMachLoc",0);

				# send to back, output to screen
#	$LdbgLoc2=$LdbgLoc;
#	$LdbgLoc2=0;		# xx
#	if (! $LdbgLoc2) { 
	#    $cmd.=" &"; }
#	else {			# send to back, output to file
#	    $cmd.=" >> $fileScanLogLoc & "; }

#	print "xx cmd=$cmd\n";
#	$cmd="manualPP.pl $fileNew pp";
#
#	print "xx cmd=$cmd";exit;
#	print "==> do $cmd\n";



	# get PID
	$filePID=      $fileNew;	
	# remove path and extensions
	$filePID=~s/^.*\///;$filePID=~s/\..*//;



########### cputorrent integration
#	$pending_jobs = `qstat -s p |wc -l`;
#	if ($pending_jobs > 10 ){
#	    # send to cpu torrent give job id : 	$filePID
#	}


###########








################ GY added 2003_10_12
##############  prep submission to SGE
	local $sgeFileHandle = "FHPREDICTSUBMIT";
	local $sgeSubmitFileName ="";
	$sgeSubmitFileName = $dirWorkLoc."/";      

#	$qsubBin = "/usr/local/sge/bin/glinux/qsub";
	$qsubBin = "/opt/gridengine/bin/lx26-amd64/qsub";
#	$qsubBin = "qsub";
#	$sgeExe = "$qsubBin -o \\\$HOME/server/tmp -e \\\$HOME/server/tmp -S /bin/bash -p -500 ";
	
#	$prmPriority = " -p -250 "; 
	$prmPriority = " -p -250 "; 
	$prmPriority = " -p -500 " if ($fileNew=~/_l/ );

	# xx GY hack for conblast GET RID AFTER OCTOBER 06
#	$tmpHack =`grep conblast $fileNew`; $prmPriority = " -p 0 "   if ($tmpHack);
	# == END TMP HACK

# 	$sgeExe = "$qsubBin -o /tmp -e /tmp -S /bin/bash "; 
# 	$sgeExe = "$qsubBin -S /bin/bash "; 
	$sgeExe = "$qsubBin -o /dev/null -e /dev/null -S /bin/bash  "; 
#	$sgeExe = "$qsubBin ";
#	$sgeExe .= $prmPriority;


	$sgeSubmitFileName .= $filePID.".sge.sh";
	open ($sgeFileHandle,">$sgeSubmitFileName");
	print $sgeFileHandle "#!/bin/bash\n";
	print  $sgeFileHandle "$cmd\n";
	close $sgeFileHandle;  
	$cmd = "$sgeExe $sgeSubmitFileName"; 

# END of qeueue submission

	#submissions to the SGE are logged in the scanner.log file
	# the email address of the user is loged as well for lookup 
	# purposes later
#	($Lok,$msgSys)=&sysSystem("$cmd");
	# using a direct pipe to copy system response.
	$msgSys=`$cmd`;	chomp($msgSys);
	# xx TODO add safety mechnism in case of failure
	$qID = $msgSys;

	$msgSys=`echo '$msgSys $user' >> $fileScanLogLoc`;
	$tStr = '("';
	$rPtr= index($qID,$tStr);
	$lPtr= length "your job ";
	$gap = $rPtr - $lPtr;
	$qID = substr($qID,$lPtr, $gap);
	$qID =~ s/ //g;


	# build a mapping file predict_XXX.map.qID;
	$qIdMapFileName =   $dirWorkLoc."/".$filePID.".map.".$qID;
	$cmd = "touch $qIdMapFileName"; 
	($Lok,$msgSys) = &sysSystem("$cmd");
	if (!$Lok){
	    $msg=  "*** ERROR $sbrName3:Could not create job to queue id filename = $qIdMapFileName. System message $msgSys";
	    # system call
	    ($Lok,$msgSys)=&sysSystem("echo $msg >> $fileScanLogLoc");
	    print "-*- WARN could not perform echo $msg >> $fileScanLogLoc"      if (! $Lok);
	}
	
				# --------------------------------------
				# remove the lock file after we are done
				# 
	unlink $fileResultLock or 
	    return (0,"cannot remove lock file $fileResultLock:$!");

	# this WAS it ...
	# ************************************************************
    }				# end of looping over 'many jobs one machine'

				# --------------------------------------------------
				# submit the job to the batch queue
				# 
				# next section comment due to batch queue usage 
				# run the job in background (Antoine 22.11.95)
				# --------------------------------------------------
#     $arg="$file_batchLog $exe_ppPredict $fileNew $fileResult $user $password $origin";
#     $cmd1="exe_batch_queue -q phd -o ";
#     $cmd2=" -s";
#     print "batch queue: '$cmd1 $arg $cmd2'\n";
#    ($Lok,$msgSys)=&sysSystem("$cmd1 $arg $cmd2");

    return(1,"ok $sbrName2");
}				# end of scannerPredict

#===============================================================================
sub scannerPredict_prepare {
    local($fileFound,$dirWorkLoc,$dirPredLoc,$dirTrashLoc,$dirResLoc,$dirMailLoc,
	  $prefixPrdLoc,$prefixWorkLoc,$suffixResLoc,$suffixMailLoc,
	  $fileScanLogLoc,$passwordDef)=@_;
    local($sbrName3,$errMsg,$fileResult,$fileMailQuery,
	  $user,$password,$orig,$resp,$cmd);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   scannerPredict_prepare      prepares running the file
#                               - builds names of :
#                                 fileFound:      input file
#                                 fileNew:        name of file in working dir (the one to run)
#                                 fileResult:     file with the result (server/res)
#                                 fileMailQuery:  file with 
#       in:                     $fileInLoc, *
#       out:                    (1|0,$msg,$fileNew,$fileResult,$user,$orig,$password
#       out:                    $fileNew=         input file to predict.pm
#       out:                    $fileResult=      output from predict.pm
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";$sbrName3=$tmp."scannerPredict_prepare";

    undef $fileNew; undef $fileResult; undef $fileMailQuery;

    $dirPredLoc=~s/\/$//g       if ($dirPredLoc=~/\/$/); # purge final slash
    $dirWorkLoc=~s/\/$//g       if ($dirWorkLoc=~/\/$/); # purge final slash

				# ------------------------------
				# build full name of files
    $fileNew=  $fileFound;

    $fileFound=~s/^.*\///g;	# strip directories
    $fileNew=~s/^.*\///g;	# strip directories
				# rename file prefix
    $fileNew=~s/^($prefixPrdLoc)/$prefixWorkLoc/;
    $fileFound=$dirPredLoc."/".$fileFound;
    $fileFound=~s/\/\//\//g;	# security '//' -> '/'
    $fileNew=  $dirWorkLoc."/".$fileNew;
    $fileNew=~s/(\/)\/*/$1/g;	# security '//' -> '/'

				# ------------------------------
				# move the input file in work dir
				#    system call
    ($Lok,$msgSys)=&sysSystem("\\mv $fileFound $fileNew");

				# -----------------------------------
				# we actually don't have to do this
				# since it's done on cubic
				# ------------------------------
				# remove any null char from the input file


				# ------------------------------
				# extract data from input file
    ($Lok,$user)=       &fileExtractHeader($fileNew,"PPhdr from");
    print "-*- WARN $sbrName3: getting user ($fileNew)\n".  $user."\n"       if (! $Lok);
    ($Lok,$orig)=       &fileExtractHeader($fileNew,"PPhdr orig");
    print "-*- WARN $sbrName3: getting orig ($fileNew)\n"  .$orig."\n"       if (! $Lok);
    ($Lok,$resp)=       &fileExtractHeader($fileNew,"PPhdr resp");
    print "-*- WARN $sbrName3: getting resp ($fileNew)\n".  $resp."\n"       if (! $Lok);
    ($Lok,$dbid)=       &fileExtractHeader($fileNew,"PPhdr dbref");
    print "-*- WARN $sbrName3: getting dbref ($fileNew)\n".  $resp."\n"       if (! $Lok);
				# note: returns password given || default password!
    ($Lok,$password)=   &fileExtractPasswordAndHide($fileNew,$passwordDef);
    print "-*- WARN $sbrName3: getting password ($fileNew)\n".$password."\n" if (! $Lok);




				# ******************************
				# no user|origin -> return
				# ******************************
    if (! $user || ! $orig ) {
	$msg=    "*** err=9640\n".
	    "*** ERROR $sbrName3: bad format in $fileFound (user=$user, orig=$orig)";
				# system call
	($Lok,$msgSys)=&sysSystem("echo $msg >> $fileScanLogLoc");
	&ctrlSendAlarm($msg."\n"."*** moved to trash=$dirTrashLoc!\n","PP_ERROR_scanner");
	($Lok,$msgSys)=&sysSystem("\\mv $fileNew $dirTrashLoc"); 
				# <--- <--- <--- <--- <--- <--- 
				# RETURN: ERROR no user | origin
	return(0,"bad format in $fileFound user=$user, orig=$orig,"); }
				# <--- <--- <--- <--- <--- <--- 
				# ******************************

				# ------------------------------
				# ok so far ->
				# (A) get requested mail format
    ($Lok,$want)=       &fileExtractHeader($fileNew,"PPhdr want");
    print "-*- WARN $sbrName3: getting want ($fileNew)\n".  $want."\n"       if (! $Lok);
				# ------------------------------
				# (B) store trace of job
    $dateTmp=&sysDate();
    $msg=  "--- predict: $dateTmp from=$user orig=$orig resp=$resp dbid=$dbid file=$fileFound";
    $cmd="echo '$msg'";
    ($Lok,$msgSys)=&sysSystem("$cmd >> $fileScanLogLoc");
				# ------------------------------
    				# build name of result file 
    $fileFoundTmp=$fileFound;
    $fileFoundTmp=~s/^.*\///g;	# purge dir
    $dirResLoc=~s/\/$//g        if ($dirResLoc=~/\/$/);  # purge final slash
    $fileResult=   $dirResLoc."/".$fileFoundTmp . $suffixResLoc;
    $fileResult=~s/\/\//\//g;	# security '//' -> '/'

				# --------------------------------------------------
				# if response mode is mail, create a mail query file
				# 
				# no longer done on dodo
				# --------------------------------------------------

    return(1,"ok",$fileNew,$fileResult,$user,$orig,$password, $dbid);
}				# end of scannerPredict_prepare




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
	next if ($fileInLoc=~/^\/home\/$ENV{USER}\/server\/scr/); # HARD CODED: security 
	next if ($fileInLoc=~/^\/home\/$ENV{USER}\/server\/pub/); # HARD CODED: security 
	next if ($fileInLoc=~/^\/home\/$ENV{USER}\/server\/bin/); # HARD CODED: security 
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
				# define missing variables
    if (defined $envPP{"file_scanErr"}){
	$fileTrace=$envPP{"file_scanErr"};}
    else {
	$fileTrace=		# HARD_CODED
	    "/home/$ENV{USER}/server/log/ERROR-scannerPP";}
				# ------------------------------
				# compose message
    $header=   "\n               $scrName "; 
    $header.=  "\n               $DateNow";
    $message=  "$header" . "\n" . "$message\n";
    $exeMail=$envPP{"exe_mail"}; 
    if (defined $envPP{"pp_admin"}){
	$pp_admin=$envPP{"pp_admin"};
	$subj="PP_ERROR_scannerPP" if (! defined $subj || length($subj) < 1);

	($Lok,$msg)=
	    &sysSendMail($exeMail,$message,$envPP{"pp_admin"},$subj);
	print "--- $sbrName: send mail '$msg'\n"      if ($LdbgLoc && $Lok);
	print "*** $sbrName: failed to send ($msg)\n" if (! $Lok);
				# write to trace file
	print "*** $scrName: message=$message\n";
#	($Lok,$msgSys)=&sysSystem("echo '$scrName: message=$message' >> $fileTrace");
#	($Lok,$msgSys)=&sysSystem("echo '$scrName: cmd    =$cmd'     >> $fileTrace");
    } else {
	print "*** ERROR $scrName: pp_admin not defined -> could NOT send:\n",$message,"\n";}
    exit(1);
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
		next if ($_=~ /^\/home\/$ENV{USER}\/(server\/scr|scr\/server)/);
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
	next if (! -e $fileAlarm);
	&ass_unlinkSecurity($fileAlarm);
    }				# end of loop over all directories
				# --------------------------------------------------

    return(1,"ok");
}				# ctrlFileExpired

# ================================================================================
sub ctrlFileRestrict {
    local ($fileInLoc,$cut_side,$numLinesMax,$kwdInLoc) = @_;
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
    $kwdInLoc=0                 if (! defined $kwdInLoc);
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
    if (! $Lok || ! $msgSys) {
	$DateLoc=&sysDate();
	&ass_unlinkSecurity($fileInLoc);
	($Lok,$msgSys)=&sysSystem("echo '$DateLoc' >> $fileInLoc"); 
	print "--- WARN $sbrName: no clean restriction of lines for file=$fileInLoc!\n"; }

				# for CGI.log file change permission
    if ($kwdInLoc && $kwdInLoc =~/file_htmlCgiLog/i){
	($Lok,$msgSys)=&sysSystem("chmod o+w $fileInLoc");
	&ctrlSendAlarm("*** failed changing permissiong of cgi.log file ($fileInLoc)".
		       $msgSys."\n","PP_WARN_scanner")
	    if (! $Lok);}

    return(1,"ok");
}				# end of ctrlFileRestrict
	
# ================================================================================
sub ctrlReportStatus {
    local($exeNice,$exeStatus,$flag,$mode,$fileAdd,$fileOut,$fileHisto,$dirPred,
	  $fileLog,$LdebugLoc)=@_;
#-------------------------------------------------------------------------------
#   ctrlReportStatus            checks PP status, and reports to WWW docs
#       in:                     
#         $LdbgLoc              debug flag (if =1 write onto screen!)
#       out:                    note to $file_sendLog
#       err:                    ok=(1,'ok','blabla'), err=(0,errNumber,'msg')
#-------------------------------------------------------------------------------
				# ------------------------------
				# is already running (flag file there)
				# ------------------------------
    if (-e $flag){ 
	$msg="*** err=9291\n".
	    "-*- $scrName:ctrlReportStatus: $exeStatus appears running (-e $flag)";
	print $msg,"\n";
	return(0,$msg);}
				# ------------------------------
				# problem with executable
				# ------------------------------
    if (! -e $exeStatus && ! -l $exeStatus) {
	$msg="*** err=9292\n".
	    "-*- $scrName:ctrlReportStatus: exeStatus=$exeStatus, missing?";
	print $msg,"\n";
	return(0,$msg);}
	
				# ------------------------------
				# run it, write flag file
				# ------------------------------
    ($Lok,$msgSys)=&sysSystem("echo 'writing just now!' >> $flag");
    $arg= "$exeNice $exeStatus $mode $fileAdd $fileOut $fileHisto $dirPred $fileLog";
    $arg.=" dbg"                if ($LdebugLoc);
    print "--- $scrName:ctrlReportStatus: system call ($arg)\n";
    ($Lok,$msgSys)=&sysSystem("$arg");

    unlink($flag);		# security: erase to prevent double writing

    return(1,"ok");
}				# end ctrlReportStatus

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
    $sbrName=$scrName.":ctrlSendAlarm";
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
	($Lok,$msg)=
	    &sysSendMail($exeMail,$message,$pp_admin,$subject);
	print "--- $sbrName: send mail '$msg'\n"      if ($Lok);
	print "*** $sbrName: failed to send ($msg)\n" if (! $Lok); }
    else {
	print 
	    "*** ALARM $sbrName: pp_admin not defined -> could NOT send:\n",
	    $message,"\n";}
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
	if (! $Lok){ $msgErr= "";
		     $msgErr.="*** err=9220\n" if ($msg !~ /err\=/);
		     $msgErr.="*** ERROR $scrName: ctrlSpaceDuCheck failed\n".$msg;
		     print $msgErr,"\n";
		     &ctrlAbort($msgErr,"PP_ERROR_scanner_space"); } 
				# ------------------------------
				# (1b) run again for security
	if ($Lrepeat && $msg=~/^over (space|file)/) {
	    ($Lok,$msg)=
		&ctrlSpaceDuCheck($exeDu,$exeNice,$fileRundirLoc,$DateLoc,$LdebugLoc,
				  $dirSavePred,$dirTrash,$kbAllocated);
	    if (! $Lok){ $msgErr= "";
			 $msgErr.="*** err=9222\n" if ($msg !~ /err\=/);
			 $msgErr.="*** ERROR $scrName: ctrlSpaceDuCheck failed 2nd\n".$msg;
			 print $msgErr,"\n";
			 &ctrlAbort($msgErr,"PP_ERROR_scanner_space2"); } }
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
	    if (! $Lok){ $msgErr= "";
			 $msgErr.="*** err=9230\n" if ($msg !~ /err\=/);
			 $msgErr.="*** ERROR $scrName: ctrlSpaceQuotaInit failed\n".$msg;
			 print $msgErr,"\n";
			 &ctrlAbort($msgErr,"PP_ERROR_scanner_quota"); } }
				# (2c) run quota
	($Lok,$msg)=
	    &ctrlSpaceQuotaCheck($exeQuota,$exeNice,$exeTar,
				 $fileSys,$fileScanOut,$DateLoc,$LdebugLoc,
				 $dirSavePred,$dirBupErr,$dirBupErrIn,$dirTrash,
				 $prefixFileBupTar,$spaceNumFileKeep);
	if (! $Lok){ $msgErr= "";
		     $msgErr.="*** err=9235\n" if ($msg !~ /err\=/);
		     $msgErr.="*** ERROR $scrName: ctrlSpaceQuotaCheck failed\n".$msg;
		     print $msgErr,"\n";
		     &ctrlAbort($msgErr,"PP_ERROR_scanner_quota2"); }
				# ------------------------------
				# (2d) run again for security
	if ($Lrepeat && $msg=~/^over (space|file)/) {
	    ($Lok,$msg)=
		&ctrlSpaceQuotaCheck($exeQuota,$exeNice,$exeTar,
				     $fileSys,$fileScanOut,$DateLoc,$LdebugLoc,
				     $dirSavePred,$dirBupErr,$dirBupErrIn,$dirTrash,
				     $prefixFileBupTar,$spaceNumFileKeep);
	    if (! $Lok){ $msgErr= "";
			 $msgErr.="*** err=9236\n" if ($msg !~ /err\=/);
			 $msgErr.="*** ERROR $scrName: ctrlSpaceQuotaCheck failed (2)\n".$msg;
			 print $msgErr,"\n";
			 &ctrlAbort($msgErr,"PP_ERROR_scanner_quota3"); } }
				# ==============================
				# <--- <--- <--- <--- <--- <--- 
				# (1c) still over: RETURN!!!
	if ($Lrepeat && $msg=~/^over (space|file)/) {
	    return(0,"*** err=9237\n"."overflow ! $sbrName failed to allocate space");}}
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
    $nmaxFile=    500;		# because of SGI limitation in handling many files
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
	    next if (! -e $file);
	    &ass_unlinkSecurity($file); }
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

	if ($it==1){		# first time: generate tar
	    ($Lok,$msgSys)=&sysSystem("$cmdTar $fileTar $tmp >> $fileScanOut"); }
	else {			# then: append
	    ($Lok,$msgSys)=&sysSystem("$cmdTarRepeat $fileTar $tmp >> $fileScanOut"); }
    }

				# ------------------------------
				# remove the file tared
    foreach $file(@fileListLoc){
	&ass_unlinkSecurity($file) if (-e $file);}
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
    @fileList=grep(/gz$/, readdir(DIR));
    closedir(DIR);
				# ------------------------------
				# remove old ones
    $dir=$dirSavePred;
    $dir.="/"                   if ($dir !~/\/$/);
    if ($#fileList > 0) {
				# move to trash (if existing)
# 	if ($dirTrash && -d $dirTrash) {
# 	    print "--- $sbrNameLoc: move from $dirSavePred to $dirTrash\n" if ($LdebugLoc);
# 	    foreach $file (@fileList) {
# 		($Lok,$msgSys)=&sysSystem("\\mv $file $dirTrash"); }}
# 	else {			# remove since no trash found
	foreach $file (@fileList) {
	    $file=$dirSavePred.$file;
	    &ass_unlinkSecurity($file) if (-e $file);
	}
#	}
    }
				# ******************************
				# serious: tar failed
				# ******************************
    else {
	$msg= "*** err=9241\n".$msgSerious;
	$msg.="*** ALARM $sbrNameLoc: space quota violation\n";
	$msg.="***       "." " x length($scrName).": cannot list (tar) file to remove!!!\n";
	$msg.=$msgSerious;
	&ctrlSendAlarm($msg,"PP_ERROR_scanner");
	&ctrlAbort($msg); 
    }
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
#    print "spaceUsage= $spaceUsage\tkbAllocated=$kbAllocated\n"x10;

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
	                        if (! $Lok) {
				    $msgErr="*** err=9211\n".
					"*** ERROR $sbrName: ctrlSpaceFreeFile failed\n".$msg;
				    print $fhTraceLoc $msgErr,"\n";
				    &ctrlAbort($msgErr,"PP_ERROR_scanner_spaceNumber"); } }

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
	    &ass_unlinkSecurity($tmp) if (-e $tmp);}}

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
	    &ass_unlinkSecurity($tmp) if (-e $tmp);}}

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

# ================================================================================
sub fileExtractHeader {
    local($file_name,$pattern) = @_;
    local($user);
#-------------------------------------------------------------------------------
#   fileExtractHeader           extract header of input file, expected syntax of
#                               this file is:
#                               
#                               ------------------------------------------------
#                               PPhdr from:   rost@columbia.edu
#                               PPhdr resp:   <MAIL|HTML>
#                               PPhdr orig:   <MAIL|HTML|TEST| ..
#                               PPhdr want:   <ASCII|HTML>
#                               PPhdr prio:   priority [0-9]
#                               ------------------------------------------------
#                               
#                      NOTE:    this format is touched by:
#                               * EmailprocPP
#                               * www/submitPP.pl
#                      NOTE2:   is greedy, i.e., first match finishes!
#                               
#       in:                     $file_to_predict,$pattern (<from|resp|orig|prio>)
#       out:                    (1,$data) || (0,'error message')
#       err:                    (1,$data) || (0,'error message')
#-------------------------------------------------------------------------------
    $line=0;			# ini
				# open file
    open(FILE, $file_name) ||
	return(0,"*** $scrName:fileExtractHeader cannot open old=$file_name\n");
				# read file
    while (<FILE>) {
	next if ($_ !~ /^\s*$pattern/);
	$line=$_; $line=~s/^\s*$pattern\s*[:]*\s*(\S+).*$/$1/g;
	$line=~s/\n//g;$line=~s/\s//g;
	last;}
    close(FILE); 
    $line="$pattern unknown"    if (! $line);
    return(1,$line);
}				# end of fileExtractHeader

# ================================================================================
sub fileExtractPasswordAndHide {
    local ($file_name,$passwordDef) = @_;
    local ($pwd,$fileTmp,$tmp,$dateTmp);
#-------------------------------------------------------------------------------
#   fileExtractPasswordAndHide  extract password from input file and hide it
#                               and add the file name in the file (as server reference)
#       in:                     $fileInput,$passwordDefault
#       out:                    (1,$password) || (0,'error message')
#       err:                    (1,$password) || (0,'error message')
#-------------------------------------------------------------------------------
    $line=0;			# ini
				# temporary file
    $fileTmp= $file_name . "_pwd";

    open(FILE,$file_name) ||
	return(0,"*** $scrName:fileExtractPasswordAndHide cannot open old=$file_name!\n");
    open(FILETMP, ">".$fileTmp) ||
	return(0,"*** $scrName:fileExtractPasswordAndHide cannot open new=$fileTmp!\n");

				# ------------------------------
				# put date and reference file name
				#    at the begining of the file
				# ------------------------------
    $dateTmp=&sysDate();
    $tmp= $file_name; $tmp=~ s/^.*\///;
    print FILETMP "reference $tmp ($dateTmp)\n";
    while (<FILE>) {
				# search for the keyword "password" in upper or lower case followed by
				# any number of space and an opening parenthesis
	if ($_=~/[Pp][Aa][Ss][Ss][Ww][Oo][Rr][Dd] *\(.*\)/) {
	    $_=~s/[Pp][Aa][Ss][Ss][Ww][Oo][Rr][Dd] *\(/password\(/;
				# extract password and replace it by "***" in $_
	    $_=~ s/(.*password\()(.*)(\).*)/$1###$3/;
	    $pwd= $2;
	    $pwd=~ s/[\W]//g;}
	print FILETMP $_; }
    close(FILE);
    close(FILETMP);
				# ------------------------------
				# overwrite the input file with 
				#    temp file
    ($Lok,$msgSys)=&sysSystem("\\mv $fileTmp $file_name");
				# ------------------------------
				# set the default password
    $pwd=$passwordDef           if (! $pwd);
    return(1,$pwd);
}				# end of fileExtractPasswordAndHide

# ================================================================================
sub fileRemoveNullChar {
    local($file_name) = @_;
    local($fileNew);
#-------------------------------------------------------------------------------
#   fileRemoveNullChar          remove null char from a file
#       in:                     $file_input_to_predict
#       out:                    implicitly moves new to old file!
#       err:                    (1,'ok') || (0,'error message')
#-------------------------------------------------------------------------------
    $fileNew= $file_name;
    $fileNew=~ s/$/00/;
				# open input and output file
    open(FILEIN, "<".$file_name)
	|| return(0,"*** $scrName:fileRemoveNullChar cannot open old=$file_name!\n");
    open(FILEOUT,">".$fileNew)
	|| return(0,"*** $scrName:fileRemoveNullChar cannot open new=$fileNew!\n");

				# ------------------------------
				# read file
    $Ldiff=0;
    while (<FILEIN>) {
	$line=$lineOrig=$_;
	$line=~s/\0//g;		# remove null character
	$Ldiff=1                if (! $Ldiff && $line ne $lineOrig);
	print FILEOUT $_;}
    close(FILEIN);
    close(FILEOUT);
				# ------------------------------
				# if differs
    ($Lok,$msgSys)=
	&sysSystem("\\mv $fileNew $file_name")
	    if ($Ldiff);
    unlink($fileNew)            if (-e $fileNew); # note: only existing if no difference!
    return(1,"ok");
}				# end of fileRemoveNullChar

# ================================================================================
sub sysFileGetOldest {
    local ($dir,$pattern,$number_wanted) = @_;
    local (@FILLIST, $file, $maxage, $oldest);
    $[ =1 ;			# start counting at 1
#-------------------------------------------------------------------------------
#   sysFileGetOldest            get the oldest file matching a pattern in a given
#                               directory
#       in:                     $dir=          directory to search
#       in:                     $number_wanted number of files wanted
#       out:                    (1,$oldest_file) || (1,'none') || (0,'error message')
#       err:                    (1,$oldest_file) || (1,'none') || (0,'error message')
#-------------------------------------------------------------------------------
    $sbrNameLoc="sysFileGetOldest";

    $dir=~s/\/$//g;		# security delete of final slash
				# read the directory
    $#FILLIST=0;
    opendir(DIR,$dir) ||
	do { warn ("-*- WARN $sbrNameLoc: failed opening dir(pred)=$dir!\n");
	     return(0,"*** FAILED opening dir(pred)=$dir!"); } ;
		 

    @FILLIST=grep(/$pattern/, readdir(DIR));
    closedir(DIR);
				# <--- <--- <--- <--- <--- <--- 
				# return as none found
    return(1,0)                 if  (! defined @FILLIST ||
				     $#FILLIST < 1);
				# <--- <--- <--- <--- <--- <--- 

				# ------------------------------
				# initialise $maxage
    $file=    $FILLIST[1];
    $maxage=  -M "$dir/$file";	# age of first file in list
    $oldest=  $file;
				# ------------------------------
				# get the older
    foreach $file (@FILLIST) {
	next if (! -e "$dir/$file"); # skip missing files
	$ageThis= -M "$dir/$file";
				# if system time in two machine is
				# different, we may get some problems
	$ageThis= 0 if ( ! defined $ageThis ); 
	next if ($ageThis <= $maxage);
	$maxage= $ageThis;
	$oldest= $file; }
    return(1,$oldest);
}				# end of sysFileGetOldest

# ================================================================================
sub sysFileGetOldestnn {
    local ($dir,$pattern,$number_wanted) = @_;
    local (@FILLIST, $file, $maxage, $oldest,%tmp,@oldest);
    $[ =1 ;			# start counting at 1
#-------------------------------------------------------------------------------
#   sysFileGetOldestnn          get the oldest nn files matching a pattern in a given
#                               directory
#       in:                     $dir=          directory to search
#       in:                     $pattern=      regular expression matching files to find
#       in:                     $number_wanted number of files wanted
#       out:                    (1,$oldest_file) || (1,'none') || (0,'error message')
#       err:                    (1,$oldest_file) || (1,'none') || (0,'error message')
#-------------------------------------------------------------------------------
    $sbrNameLoc="sysFileGetOldestnn";

    $dir=~s/\/$//g;		# security delete of final slash
				# read the directory
    $#FILLIST=0;
    opendir(DIR,$dir) ||
	do { warn ("-*- WARN $sbrNameLoc: failed opening dir(pred)=$dir!\n");
	     return(0,"*** FAILED opening dir(pred)=$dir!"); } ;

    @FILLIST=grep(/$pattern/, readdir(DIR));
    closedir(DIR);
				# <--- <--- <--- <--- <--- <--- 
				# return as none found
    return(1,0)                 if  (! defined @FILLIST ||
				     $#FILLIST < 1);
				# <--- <--- <--- <--- <--- <--- 

				# ------------------------------
				# initialise $maxage
    $file=    $FILLIST[1];
    $maxage=  -M "$dir/$file";	# age of first file in list
    $oldest=  $file;
				# ------------------------------
				# get the first oldest
    undef %tmp;
    $#tmp=0;
    while (@FILLIST) {
	$file=pop  @FILLIST;

				# skip missing files
	next if (! -e "$dir/$file");
				# get age
	$ageThis= -M "$dir/$file";
	$tmp{$file}=$ageThis;	# store age
	push(@tmp,$file);	# store file

	next if ($ageThis <= $maxage); # too young
	$maxage= $ageThis;
	$oldest= $file; }
    @oldest=($oldest);		# store oldes

				# <--- <--- <--- <--- <--- <--- 
				# return since not enough there
    if ($number_wanted == 1 || $#tmp < 2) {
	$#oldest=$#tmp=0;
	undef %tmp;
	
	return(1,$oldest); 
    }				# <--- <--- <--- <--- <--- <--- 


				# ------------------------------
				# get the next oldest
    foreach $it (1..($number_wanted-1)){
	@FILLIST=@tmp;
	$#tmp=0; 
	while (@FILLIST) {
	    $file=pop @FILLIST;
				# skip the previous oldes
	    next if ($file eq $oldest);
	    $ageThis=$tmp{$file};
	    push(@tmp,$file); # store file
	    next if ($ageThis <= $maxage); # too young
	    $maxage= $ageThis;
	    $oldest= $file; }
	push(@oldest,$oldest);
				# none left (i.e. only the oldest)
	last if ($#FILLIST==1); } 
	    
    $#tmp=$#FILLIST=0;		# slim-is-in
    undef %tmp;			# slim-is-in
    
    return(1,@oldest);
}				# end of sysFileGetOldestnn

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
    if ($fileInLoc !~ /\s/ &&
	(-e $fileInLoc || -l $fileInLoc)) {
#	$cmd="cat $fileInLoc | rsh parrot '$exeMailLoc -s $subjLoc $receiverLoc'";}
	$cmd="cat $fileInLoc | $exeMailLoc -s '$subjLoc' $receiverLoc";}
				# (2) is text string
    else {
#	$cmd="echo $fileInLoc | rsh parrot '$exeMailLoc -s $subjLoc $receiverLoc'";}
	$cmd="echo $fileInLoc | $exeMailLoc -s '$subjLoc' $receiverLoc";}

				# (3) ERROR
    if ($cmd eq "256" || length($cmd) < 10) {
	&ctrlSendAlarm("something weired with sending mail:\n".
		       "user=$receiverLoc\n".
		       "subj=$subjLoc\n".
		       "exe =$exeMailLoc\n".
		       "file=$fileInLoc\n","PP_ERROR_send_mail");
	$dir=$envPP{"dir_bup_errMail"};
	($Lok,$msgSys)=&sysSystem("\\cp $fileInLoc $dir");
	return(1,$cmd);}
	
				# (4) send now
    ($Lok,$msgSys)=&sysSystem($cmd);
    return(1,$cmd);
}				# end of sysSendMail

# ================================================================================
sub sysWhoWantsToWork {
    local ($predictScrNameLoc,$fileScanFlag,$fileScanOut)=@_;
    local ($sbrName3,$envMachine,$candidate,
	   $ps_cmd,$authorised_pred,$nb_occur,$ps_ok,$Lbusy,$tooLoaded,$wcmd,
	   $tmpDate);
#-------------------------------------------------------------------------------
#   sysWhoWantsToWork           determines free machine 
#                               - wait until it find a system for prediction
#                               - return the name of the system
#       in:                     $predictScrNameLoc: name of script running prediction
#                                                   e.g. predictPP.pl
#       in:                     $fileScanFlag:      flag file controlling scanner
#       in:                     $fileScanOut:       log file to write onto
#       ABORT:                  ABORT program if flag file (fileScanFlag) missing
#       ABORT:                  ABORT program if flag file (fileScanFlag) missing
#       ABORT:                  ABORT program if flag file (fileScanFlag) missing
#       ABORT:                  ABORT program if flag file (fileScanFlag) missing
#       in GLOBAL:              @Candidate_machine = 
#                                  ("mach1:ps command1:nb1" "mach2:ps command1:nb2"...)
#       out:                    (1,$machine_ready,$njobs_on_free_machine),(0,'error message')
#       err:                    (1,$machine_ready),(0,'error message') || ABORT
#-------------------------------------------------------------------------------
    $sbrName3=$scrName.":"."sysWhoWantsToWork";
    $fhoutLoc="FHOUTLOG_sysWhoWantsToWork";
				# ------------------------------
				# open log file for append
				# ------------------------------
    ($LokFile=open($fhoutLoc,">>".$fileScanOut)) ||
	warn("-*- WARN $sbrName3: failed opening log file=$fileScanOut, for append\n");
    $fhoutLoc="STDOUT"          if (! $LokFile);

    $Lbusy=0;

				# ==================================================
				# endless LOOP !!
				# ==================================================
    while ( 1 == 1) {
				# ******************************
				# SERIOUS: missing scannerFlag
				# ******************************
	if (! -e $fileScanFlag) {
	    $msgErr= "*** err=9280\n";
	    $msgErr.="*** ERROR $sbrName3: stopped searching for machine (no $fileScanFlag)\n";
	    print $msgErr,"\n";
	    close($fhout);
	    &ctrlAbort($msgErr,"PP_ERROR_scanner_machine"); }
				# --------------------------------------------------
				# loop to search a free machine
				# --------------------------------------------------
	foreach $envMachine (@Candidate_machine) {
				# 'machineName:ps_cmd:number of jobs'
	    ($candidate,$ps_cmd,$authorised_pred)=split (":",$envMachine);

				# ini
	    $nb_occur= 0;
	    $ps_ok=    0;
	    $tooLoaded=0;
				# ------------------------------
				# hack 98-06 hack around loaded alphas:
	    if ($candidate =~/alpha/){ # first check load on machine
		$wcmd=`rsh $candidate w |grep 'load average'`; 
		$wcmd=~s/^.*load average:\s*(\S+)\s.*$/$1/; $wcmd=~s/[^\d\.]//g;
		if ($wcmd > 3){print $fhoutLoc "--- $candidate too loaded ($wcmd)\n";
			       $tooLoaded=1;}}
	    if (! $tooLoaded){
		$cmd= "$ps_cmd | grep $predictScrNameLoc";
				# no rsh 
				# note Lone_machine is GLOBAL
		$cmd= "rsh $candidate '$cmd'" if (! $Lone_machine);

		$ps_ok=
#		    open (SYST, "$ps_cmd | grep $predictScrNameLoc | ");
#		    open (SYST, "rsh $candidate '$ps_cmd | grep $predictScrNameLoc' | ");
		    open (SYST, "$cmd | ");
		while (<SYST>) {chop;
				++$nb_occur if ($_ !~ /grep / && 
						$_ !~ /emacs/ &&
						$_ !~ /rsh / && 
						$_ !~ /csh /); }
		close (SYST);}
	    else {
		$ps_ok=0; }

	    $tmpDate=&sysDate();
				# ------------------------------
				# machine is ready to work
	    if ($ps_ok && ($nb_occur < $authorised_pred)) {
				# number of jobs possible on machine
		$nb_possible=$authorised_pred-$nb_occur;
		printf $fhoutLoc "> $candidate $nb_possible free: %s\n",$tmpDate;
		$Lbusy=0;
		close($fhoutLoc);
		return (1,$candidate,$nb_possible);}
				# ------------------------------
				# machine is busy -> continue ..
	    elsif (! $Lbusy) {
		printf $fhoutLoc "> $candidate busy ($authorised_pred used): %s\n",$tmpDate;
		$Lbusy=1;}
				# ------------------------------
				# machine is busy -> continue ..
	    else {
		printf $fhoutLoc "> $candidate Busy ($authorised_pred used): %s\n",$tmpDate;
		$Lbusy= 1;}
	}
				# ==================================================
				# if no system is free sleep for a while
				# ==================================================
	sleep(30); }
				# end of endless loop
				#     terminated when machine found!
    close($fhout);
    return(0,"never found a machine",0);
}				# end of sysWhoWantsToWork

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
    print $fhLoc "--- system: \t $cmdLoc\n" if ($fhLoc);
    

				# ------------------------------
				# run system
    $Lsystem=
	system("$cmdLoc");

    return(1,$Lsystem);
}				# end of sysSystem

#==============================================================================
# library collected (end)
#==============================================================================



