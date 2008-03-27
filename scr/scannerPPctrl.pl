#!/usr/bin/perl -w
##!/usr/local/bin/perl -w
##!/usr/pub/bin/perl5
##!/usr/pub/bin/perl5.003 -w
##!/usr/pub/bin/perl -w
#!/usr/pub/bin/perl5.003 -w
##! /usr/pub/bin/perl
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
#			    br  v 1.5             Nov,          1996              #
#			    br  v 2.0   	  Jan,          1998              #
#			    br  v 2.1   	  Feb,          1998              #
#			    br  v 2.2   	  Mar,          1998              #
#			    br  v 2.3   	  May,          1998              #
#			    br  v 2.4             Jan,          1999              #
#------------------------------------------------------------------------------   #
# 
#    * controlling the PP scanner   (scannerPP.pl):
#      two modes: <start|stop>
# 
#    * called by the crontab        (cronStopStart.sh)
#      STDOUT appended to crontab.log (by cronStopStart.sh)
#      
#    ------------------------------
#    command line arguments
#    ------------------------------
#      
#    <start|stop> debug
#    
#    * 'start'                      starts the scanner (scannerPP.pl)
#    * 'stop'                       stops the scanner (scannerPP.pl)
#                                   and removes flag file ($envPP{'file_scanFlag'})
#    optional argument
#      
#    * 'dbg'                        for debug mode
#                                   -> all messages onto STDOUT
#    
#    
#    --------------------
#    START
#    --------------------
#      
#    * command argument 'start'  
#      ->  the scanner is started
#      (1) check environment parameters defined in envPP.pm
#          ABORT if error
#      (2) check whether or not scanner running already
#          ABORT if running
#      (3) run 'scannerPP.pl >> file_scanScreen'
#      
#      optional: 2nd command line argument 'dbg'
#      ->  output of scanner not parsed into log file!
#      
#    --------------------
#    STOP
#    --------------------
#      
#    * command argument 'stop'  
#      -> the scanner is stopped
#      -> flag file ($envPP{'file_scanFlag'}) removed
#      
#------------------------------------------------------------------------------#
				# ------------------------------
				# iniScannerPPctrltialise environment parameters
($Lok,$msg)=
    &iniScannerPPctrl();
				# ------------------------------
				# trace file handle
				# note: there are 2 trace files:
				# (1) fhTrace        -> local
				# (2) fhTraceCrontab -> crontab.log
$fhTrace="STDOUT";
				# ******************************
				# *** ERROR in local env
if (! $Lok){ print $fhTrace "*** ERROR $scrName: after ini msg=\n",$msg,"\n";
				# send message (if not help)
	     &ctrlAbort("*** $scrName: \n".$msg) if ($msg !~/need help/);
	     exit(1); }

				# --------------------------------------------------
				# stop scanner
				# --------------------------------------------------
if (! $LmodeStart) {
				# ------------------------------
                                # test if the flag file was there
				# LEAVE IF NOT RUNNING!
				# note: 'already' keyword for ctrlAbort!!
    &ctrlAbort("--- NOTE PHD scanner already stopped !!!!!!!!") 
	if (! -e $file_scanFlag);
				# ------------------------------
				# create flag file
				# hack 20-02-97 (avoid removing important bits)
    unlink ($file_scanFlag)     if ($file_scanFlag !~ /\/nfs\/data5\/users\/$ENV{USER}\/scr/);
				# ------------------------------
				# write to trace file
    $arg="--- $scrName (stop): PHD scanner ($scrName) stop $Date"; 
    system("echo '$arg' >> $file_crontabLog");
    print $fhTrace "$arg\n";

				# ------------------------------
				# write status file (hack end of 96)
#    $cmd= "$exe_status down '$Date'";
#    system("$cmd");
}				# end of stopping the scanner


				# --------------------------------------------------
				# start scanner
				# --------------------------------------------------
else {	
				# ------------------------------
    if (! -e $file_scanFlag) {	# create the flag file
	print $fhTrace  "--- $scrName: scanner started at $Date\n";
	system "echo '--- $scrName: scanner started at $Date' > $file_scanFlag"; 

#	if ($LrunCheck) {	# check status and report to WWW
#	    ($Lok,$msg)=
#		&wwwStatusReport($envPP{"file_statusFlag"},$scrName,
#				 $envPP{"exe_status"},$envPP{"para_status"},
#				 $envPP{"file_statusAdd"},$envPP{"file_statusLog"},
#				 $envPP{"file_statusHis"},
#				 $envPP{"dir_prd"},$envPP{"file_ppLog"},
#				 $envPP{"pp_admin"});
#	    print $fhTrace 
#		"*** ERROR $scrName: failed executing the status control (",
#		$envPP{"exe_status"},") msg=",$msg,"\n" 
#		    if (! $Lok); } }
				# ------------------------------
#    else {			# exit if the process runs

#	if ($LrunCheck) {	# report status to WWW
#	    ($Lok,$msg)=
#		&wwwStatusReport($envPP{"file_statusFlag"},$scrName,
#				 $envPP{"exe_status"},$envPP{"para_status"},
#				 $envPP{"file_statusAdd"},$envPP{"file_statusLog"},
#				 $envPP{"file_statusHis"},
#				 $envPP{"dir_prd"},$envPP{"file_ppLog"},
#				 $envPP{"pp_admin"});
#	    print $fhTrace 
#		"*** ERROR $scrName: failed executing the status control (",
#		$envPP{"exe_status"},") msg=",$msg,"\n" 
#		    if (! $Lok); }

				# hack br 98-04
	$exe_ppScanner=~s/\s*$//g; # purge final blanks

				# --------------------------------------------------
				# check whether scanner is running (envPP.pm)
	($Lok,$njobs)=
	    &envPP'isRunningEnv($exe_ppScanner,$exe_ps,$fhTrace);      # e.e'

	($Lok,$njobs1)=
	    &envPP'isRunningEnv($exe_ppScannerDB,$exe_ps,$fhTrace);      # e.e'


				# ------------------------------
				# was dead
	if ($Lok && $njobs == 0 || $njobs1 == 0 ) {
	        print $fhTrace
		    "--- WARN $scrName: PHD scanner ($exe_ppScanner or $exe_ppScannerDB) was dead!\n"; }
				# ------------------------------
				# is running
	else {
	    if (! $Lok || ($Lok && $njobs >= 1 && $njobs1 >= 1)) {
		print $fhTrace
		    "--- WARN $scrName: PHD scanner ($exe_ppScanner) already started!\nExiting\n";
		exit(1); }
	    print $fhTrace
		"*** ERROR $scrName: too many PHD scanners ($exe_ppScanner) ?!\n";
	    &ctrlAbort("*** ERROR $scrName Nscanners ($exe_ppScanner) running=$njobs ??"); }}

				# ------------------------------
				# run scanner
				# ------------------------------

				# ------------------------------
				# store action in log file
    $arg="--- $scrName (start): PHD scanner ($exe_ppScanner) started $Date"; 
    $arg="--- $scrName (start): PHD scanner ($exe_ppScannerDB) started $Date"; 
    system("echo '$arg' >> $file_crontabLog");
    print $fhTrace "$arg\n";


   


    # ================================================================================
    if (! $Ldebug) {		# the '>> $file_scanScreen' is to monitor output 
				# from programs such as maxhom, convert_seq
				# that are started with : run_program
	system("$exe_nice $exe_ppScanner >> $file_scanScreen &") if ( $njobs == 0 );
	system("$exe_nice $exe_ppScannerDB >> $file_scanScreen &")  if ( $njobs1 == 0 );
	print("$exe_nice $exe_ppScannerDB >> $file_scanScreen \n") ;
    }
    else {
				# output onto standard out
	system("$exe_ppScanner dbg"); }
    # ================================================================================

}				# end of starting the scanner

exit(1);

#===============================================================================
sub iniScannerPPctrl {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iniScannerPPctrl            gets the parameters from env, and checks
#-------------------------------------------------------------------------------
				# ------------------------------
				# get the name of this file
    $scrName=$0;$scrName=~s/^.*\/|\.pl//g;
				# ------------------------------
				# check input argument
    return(0,
	   "*** $scrName: need help?\n".
	   "*** ERROR $scrName: command line argument MUST be <start|stop> (may be <dbg>)!\n".
	   "*** err=100")       if ($#ARGV < 1 || $ARGV[1]!~/start|stop/i);

    $LmodeStart=0;
    $LmodeStart=1               if ($ARGV[1]!~/stop/i);

				# ------------------------------
				# debug mode
    $Ldebug=0;
    foreach $it (2..$#ARGV){
	next if ($ARGV[$it]!~/^de?bu?g$/i);
	$Ldebug=1;
	last;}
				# --------------------------------------------------
				# include envPP package as define in $PPENV or default
    if ($ENV{'PPENV'}) {
	$envPack = $ENV{'PPENV'}; }
    else {			# this is used by the automatic version!
	$envPack = "/nfs/data5/users/$ENV{USER}/server/scr/envPP.pm"; } # HARD CODDED

				# package with environment
    $Lok=
	require "$envPack";
                    		# *** error in require env
    return(0,"*** ERROR $scrName: failed to require envPack '$envPack'".
	   "\n*** err=101") if (! $Lok);

				# ------------------------------
				# read local environment var
				# ------------------------------
				# for start AND stop
    foreach $des ("file_scanErr","file_scanFlag","file_crontabLog",
		  "exe_mail","pp_admin"){
	$envPP{$des}=&envPP'getLocal($des);                            # e.e'
				# *** error in local env
	return(0,"failed to get envPP{$des} from envPack '$envPack'\n*** err=102 a") 
	    if (! $envPP{$des}); }

				# for start
    if ($LmodeStart) {
	foreach $des ("file_scanOut",
		      "exe_nice","exe_ppScanner","exe_ppScannerDB", "exe_ps") {
	    $envPP{$des}=&envPP'getLocal($des);                        # e.e'
				# *** error in local env
	    return(0,"start: failed on envPP{$des} from envPack ($envPack)\n*** err=102 b") 
		if (! $envPP{$des});}}

				# for stop 
    if (! $LmodeStart) {
	foreach $des ("exe_status"){
	    $envPP{"$des"}=&envPP'getLocal($des);                      # e.e'
				# *** error in local env
	    return(0,"stop: failed on envPP{$des} from envPack ($envPack)\n*** err=102 c") 
		if (! $envPP{"$des"});}}

				# ------------------------------
				# local names (start)
				# both
    $file_scanFlag=     $envPP{"file_scanFlag"};
				# start
    $file_scanScreen=   $envPP{"file_scanOut"};
    $file_crontabLog=   $envPP{"file_crontabLog"};
    $exe_ppScanner=     $envPP{"exe_ppScanner"};
    $exe_ppScannerDB=     $envPP{"exe_ppScannerDB"};
    $exe_ps=            $envPP{"exe_ps"};
    $exe_nice=          $envPP{"exe_nice"};
				# stop
    $exe_status=        $envPP{"exe_status"};
				# flag file for reporting status of PP to WWW
    $envPP{"flag_status"}=0     if (! defined $envPP{"flag_status"} ||
				    length($envPP{"flag_status"}) < 2);

				# ------------------------------
				# get the date
    $Date=&sysDate();
				# ------------------------------
				# ini check status (for start)
				# ------------------------------
    $LrunCheck=0;
    if ($LmodeStart) {
	$LrunCheck=1;		# controls whether or not the scanner will
				#   be switched off independent of its current
				#   state (if running: switch off first!)
	foreach $kwd("exe_status","file_statusLog",
		     "para_status","file_statusFlag","file_statusHis","file_statusAdd",
		     "dir_prd","file_ppLog"){
	    $envPP{$kwd}=   &envPP'getLocal($kwd);                     # e.e'
	    next if ($kwd =~ /^para/);
	    next if (defined $envPP{$kwd});
				# error -> no panick, minor problem
	    print $fhTrace "-*- WARN $scrName: failed to get envPP{$des} from envPack '$envPack'\n";
	    print $fhTrace "-*- WARN           err=104\n";
	    $LrunCheck=0; }}
    return(1,"ok");
}				# end of iniScannerPPctrl

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
	  "/nfs/data5/users/$ENV{USER}/server/scr/lib/",
	  );
    $exe_ctime="ctime.pm";	# local ctime library

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

#===============================================================================
sub ctrlAbort {
    local ($message) = @_;
#----------------------------------------------------------------------
#   ctrlAbort                   sends alarm mail to pp_admin and exits(1)
#       in:                     $message
#       in GLOBAL:              $envPP{"exe_mail"},$envPP{"pp_admin"},
#       in GLOBAL:              $envPP{"file_errLog"},$Date,
#       out:                    EXIT(1)
#----------------------------------------------------------------------
				# ------------------------------
				# define missing variables
    $envPP{"pp_admin"}=		# HARD_CODED
	"predit_help\@columbia.edu" if (! defined $envPP{"pp_admin"});

    if (! defined $envPP{"exe_mail"}){
	if (-e "/usr/sbin/Mail" ){ $envPP{"exe_mail"}="/usr/sbin/Mail" ;}
	else                     { $envPP{"exe_mail"}="/usr/bin/Mail" ;}}
    $Date=localtime(time)       if (! defined $Date);
				# ------------------------------
				# compose message for ERRORS
				#    reported to PPadmin
    if ($message=~/ERROR/) {
	$message=  "*** $scrName $Date \n".$message;
	$subject= "PP_ERROR_scanner_";
	$subject.="start" if ($LmodeStart);
	$subject.="stop"  if (! $LmodeStart);
    
	$cmdMail=$envPP{"exe_mail"}." -s $subject ".$envPP{"pp_admin"};
	system("echo '$message' | $cmdMail"); 
	print $fhTrace "*** $scrName ctrl: did system \n","sys\t".$cmdMail,"\n"; }
				# ------------------------------
				# write to trace file (file_crontabLog, resp STDOUT)
    print $fhTrace "$message\n"; # error message
    exit(1);
}				# end of ctrlAbort

#===============================================================================
sub wwwStatusReport {
    local($file_flag,$scrNameLoc,
	  $exe,$mode,$fileAdd,$fileOut,$fileHisto,$dirPred,$fileLog,
	  $ppAdminLoc)=@_;
#-------------------------------------------------------------------------------
#   wwwStatusReport             report the status of PP to the WWW documents
#       in:                     $file_flag  : file flagging that scanner started
#                               $scrNameLoc : name of this script
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
#   
    if (-e $file_flag){
	print $fhTrace "--- WARN $scrNameLoc:wwwStatusReport: already running ($file_flag)";
	unlink($file_flag);}
				# make trace of this process
				#    (append to log file)
    if    ($file_flag && -e $file_flag) {
	open(FHOUT,">>".$file_flag) || 
	    return(0,"*** $scrName:wwwStatusReport: appending to file_flag=$file_flag!\n"); }
    elsif ($file_flag && ! -e $file_flag) {
	open(FHOUT,">".$file_flag) || 
	    return(0,"*** $scrName:wwwStatusReport: opening file_flag=$file_flag!\n"); }
    else {
	return(0,"*** $scrName:wwwStatusReport: not defined file_flag=$file_flag!\n"); }
	
    print FHOUT "--- $scrName: sorry, already writing just now!\n";
    close(FHOUT);

				# ------------------------------
				# executing wwwStatusPP.pl
				#    i.e. the status report
				# ------------------------------
    $arg="$exe $mode $fileAdd $fileOut $fileHisto $dirPred $fileLog $ppAdminLoc";
    print $fhTrace "--- $scrName: sys \t",$arg,"\n";
    system("$arg"); 

    unlink($file_flag);		# security: erase to prevent double writing

    return(1,"ok");
}				# end wwwStatusReport

