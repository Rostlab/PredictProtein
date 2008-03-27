#!/usr/local/bin/perl -w
##!/usr/pub/bin/perl4
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="reports status of scanner on PP www site\n";
#
#------------------------------------------------------------------------------#
#	Copyright				        	1999	       #
#	Burkhard Rost		rost@EMBL-Heidelberg.DE			       #
#	Wilckensstr. 15		http://www.embl-heidelberg.de/~rost/	       #
#	D-69120 Heidelberg						       #
#			    br  v 1.0             Nov,          1996           #
#			    br  v 1.1   	  Jan,          1998           #
#			    br  v 1.2   	  Mar,          1998           #
#			    br  v 1.3   	  May,          1998           #
#			    br  v 1.4             Feb,          1999           #
#------------------------------------------------------------------------------#
# 
# reports the Status of PredictProtein to the WWW documents
# input: 
#       ARGV[1]= mode (normal|copy|down|auto)
#       ARGV[2]= add_in_file (comments to append) now:
#            /home/www/htdocs/Services/sander/predictprotein/PPstatus.add
#        OR: 'down time date'
#       ARGV[3]= output file (to be read by WWW)  now: 
#            /home/www/htdocs/Services/sander/predictprotein/PPstatus.log
#
#       ARGV[4]= history     (to be put onto WWW) now: 
#            /home/www/htdocs/Services/sander/predictprotein/PPstatus.history
#
#       ARGV[5]= directory of 'to-be-predicted'   now: server/pred
#       ARGV[6]= file_phd_log                     now: server/log/phd.log
#       ARGV[7] OR
#        any   = ppAdmin                          optional
#
# alternative:
#       1='down' 2=down time
#       1='copy' 2=file-to-copy 3=file-to-be-copied-to (PPstatus.log)
#       1='auto' will simply use the standard setting for PP
# optional:
#       7th or any:
#          ppAdmin
#
#--------------------------------------------------------------------------------
$[=1;
local ($modeJob,$fileAdd,$fileState,$fileHistory,$dirPred,$fileLog,$ppAdmin)=@ARGV;
local ($timeX,$time,$fhout,@FL,$hours,$maxhours,$numReq,$ctM,$ctD,$month,$day);

				# --------------------------------------------------
				# defaults (for missing command line arguments)
				# --------------------------------------------------
$dppWWWdoc=      "/home/www/htdocs/pp/Dlog/";
$dppWWWdoc=      "/home/$ENV{USER}/server/www_doc/Dlog/";
$dppRun=         "/home/$ENV{USER}/server/";

$modeDef=        "normal";
$fileAddDef=     $dppWWWdoc."PPstatus.add";
$fileStateDef=   $dppWWWdoc."PPstatus.log";

$dirPredDef=     $dppRun.   "xch/prd/";
$fileLogDef=     $dppRun.   "log/phd.log";
#$fileHistoryDef= $dppWWWdoc."PPstatus.flag";
$fileHistoryDef= $dppWWWdoc."PPstatus.history";

$fileErrorHere=  $dppRun.   "log/Error-status.log";

$minDiffHistory=20;		# minimal difference to report history
$minDiffHistory=5;		# minimal difference to report history
$minDiffHistory=10;		# minimal difference to report history

$ppAdminDef=     "pp_admin\@columbia.edu";

				# ------------------------------
				# help
if ($#ARGV < 1  ||
    ($#ARGV != 1 && $modeJob eq "auto") ||
    ($#ARGV < 2  && $modeJob eq "down") ||
    ($#ARGV < 3  && $modeJob eq "copy") ){
    print  "--- goal: $scrGoal\n";
    print  "--- use:  '$scrName '\n";
    print  "--- \n";
    print  "*** status wrong number of arguments \n";
    print  "***    either: checkPPstatus.pl mode fileAdd fileOut fileHistory dirPred fileLog\n";
    print  "***    xor:    checkPPstatus.pl down 'downDate'\n";
    print  "***    xor:    checkPPstatus.pl auto (for standard setttings)\n";
    print  "***    xor:    checkPPstatus.pl copy file-to-copy file-to-be-copied-to\n";
    print  "--- opt:  any argument (or last in 6+1): email of PPadmin\n";

    $arg="*** ERROR $scrName: status wrong number of args (".`date`.")\n";
    system("echo '$arg' >> /home/$ENV{USER}/run/log/Error-status.log");

    exit(1); }

				# --------------------------------------------------
				# take arguments passed on command line
				# --------------------------------------------------
$modeJob=    $modeDef           if (! defined $modeJob );
$dirPred=    $dirPredDef        if (! defined $dirPred );
$fileState=  $fileStateDef      if (! defined $fileState);
$fileLog=    $fileLogDef        if (! defined $fileLog );
$fileHistory=$fileHistoryDef    if (! defined $fileHistory );
$fileAdd=    $fileAddDef        if (! defined $fileAdd );
$fileHistory=$fileHistoryDef    if (! defined $fileHistory );
$ppAdmin=    $ppAdminDef        if (! defined $ppAdmin);

				# default PP manager 
				#    0 -> no address written into status report!
$ppAdmin=        0              if (! defined $ppAdmin);
if (! $ppAdmin) {		# search for address of PPadmin
    foreach $arg (@ARGV){
	next if ($arg !~ /\@/);	# no address -> no ppAdmin
	$ppAdmin=$arg;
	last; } }
				# --------------------------------------------------
				# determine action
				# --------------------------------------------------
if    ($modeJob eq "down"){	# report: is down
    $Lok=
	&ppIsDown($fileAdd,$fileState,$ppAdmin);
    print "*** ERROR $scrName: wants to report that PP is down, failed writing file=$fileState!\n"
	if (! $Lok);
				# note: fileAdd='date' for mode 'down'!
    print "--- $scrName: PP down ($fileAdd) reported to fileState=$fileState!\n"
	if ($Lok);
				# br 99-02: error status of sbr NOT checked here!
    exit(1);}
				# --------------------
elsif ($modeJob eq "copy"){	# update report file
    if (-e $fileAdd){ 
	$cmd="\\cp $fileAdd $fileState";
	print "--- $scrName: sys \t $cmd\n";
	system("$cmd"); 
	if (! -e $fileState) {
	    print "*** ERROR $scrName: failed copying $fileAdd to $fileState\n";
	    $arg= "*** ERROR $scrName: failed copying $fileAdd to $fileState";
	    system("echo '$arg' >> $fileErrorHere");}
	exit(1);}
    else{
	print "*** ERROR $scrName: called missing file ($fileAdd) to copy\n";
	$arg= "*** ERROR $scrName: called missing file ($fileAdd) to copy";
	system("echo '$arg' >> $fileErrorHere");
	exit(1);}}
				# --------------------
				# ELSE -> all others see below!!

				# --------------------------------------------------
				# now write new status file!
				# --------------------------------------------------

				# ------------------------------
$fhout="FH_FILE_STATE";		# open output file
open($fhout, ">".$fileState) || do { warn "*** ERROR $scrName: cannot open new=$fileState: $!\n"; 
				     $arg="*** ERROR $scrName: failed opening new=$fileState:";
				     system("echo '$arg' >> $fileErrorHere");
				     exit; } ;
				# ------------------------------
				# get date
$dateFull=`date`;

@date=split(/\s+/,$dateFull);$month=$date[2];$day=$date[3];
$timeX=$time;
$timeX="$date[1] $month $day $date[4]" if ($date[4] =~/^19|20/);

				# ------------------------------
				# write header
				# ------------------------------
$tmp=(60			# line length
      -9			# 'status on'
      -1			# space
      -length($dateFull));

$txt= sprintf("--- %-60s\n","-" x 50);
$txt.=        "--- State of the PredictProtein server\n";
$txt.=        "--- \n";
$txt.=sprintf("--- %-".$tmp."s %-s\n","Status on",$dateFull);
$txt.=        "--- \n";
print $fhout $txt;
				# ------------------------------
				# get number of requests pending
				# ------------------------------
$dirPred=~s/\/$//g              if ($dirPred=~/\/$/); # purge final slash
$numReq=0;

opendir(X,$dirPred);
@FL=readdir(X);
closedir(X);$maxhours=0;

if($#FL>2){
    for $file (@FL) { next if ($file=~/^\./);
		      $hours=24.0*(-C $dirPred."/".$file);
		  $maxhours=$hours if $hours>$maxhours;
		  $numReq++;}$maxhours=~s/\s|\n//g;
    printf $fhout "--- %-35s %-6d\n",  "Number of requests in queue",$numReq;
    printf $fhout 
	"--- %-35s %-3.1f\n","Estimated time in queue (hours)",
	($maxhours+($numReq/10)*0.1);}
else {
    printf $fhout "--- %-35s\n","No request in queue (i.e. waiting time < 20 min)";}
				# ------------------------------
				# read log file
open(FHIN, $fileLog) ||         do { warn "*** ERROR $scrName: cannot open log=$fileLog: $!\n"; 
				     $arg="*** ERROR $scrName: failed open log=$fileLog:";
				     system("echo '$arg' >> $fileErrorHere");
				     exit; }; 
$ctM=$ctD=0;
while(<FHIN>){
    ++$ctM if ($_=~/ $month[: ]/);
    ++$ctD if ($_=~/ $month[: ]$day/);
}
close(FHIN);

$txt=         "--- \n";
$txt.=sprintf("--- %-35s %-5d \n","Number of requests in $month",$ctM);
$txt.=sprintf("--- %-35s %-5d \n","Number requests on $month, $day",$ctD);
$txt.=        "--- \n";
$txt.=sprintf("--- %-s \n","RELOAD for latest version (update every 20 min)!");
$txt.=        "--- \n";
$txt.=sprintf("--- %-60s\n","-" x 50);

print $fhout $txt;

if ($numReq>1 && $#ARGV>3 && -e $fileHistory){
    $Lok=
	&history(); }		# get history
close($fhout);
				# ------------------------------
				# add file with Notes
system("cat $fileAdd >> $fileState")
    if (-e $fileAdd);

system("chmod go+r $fileState"); # make readable for WWW

exit;

# ================================================================================
sub ppIsDown {
    local ($downTime,$fileStateLoc,$ppAdminLoc)=@_;

    $fhout="FH_FILE_STATE";
    open($fhout, ">".$fileStateLoc) || 
	do { warn  "*** ERROR $scrName:ppIsDown cannot open new=$fileStateLoc: $!\n"; 
	     print "*** ERROR $scrName:ppIsDown cannot open new=$fileStateLoc: $!\n"; 
	     return(0); } ;
    print $fhout 
	"--- ------------------------------------------------------------\n",
        "--- Status of PredictProtein service (Columbia Univ, NYC)\n",
	"--- \n",
	"--- APOLOGIES: the service is down since:\n",
	"---    $downTime\n",
	"--- \n",
	"--- Wait and/or hope .... (sorry)\n";
    print $fhout 
	"--- ... or: send mail to:\n",
	"--- $ppAdminLoc\n" if (defined $ppAdminLoc && $ppAdminLoc);
    print $fhout
	"--- \n",
	"--- --------------------------------------------------\n\n";
    close($fhout);
    return(1);
}				# end ppIsDown

# ================================================================================
sub history {			# determine history of recent requests to PP

    $time=$date[4];$time=~s/\:\d+$//g;

    $#history=0;		# ------------------------------
    $Ldelete=1;			# get history
    open(FHIN,$fileHistory) ||  do { warn "*** $scrName: Cannot open old=$fileHistor: $!\n";
				     return(0); };

    while(<FHIN>){ next if ($_=~/^da/);
		   $_=~s/\n//g;$line=$_;
		   @tmp=split(/\t/,$_);
		   last if ($tmp[1] ne "$day");
		   push(@history,$line);
		   $Ldelete=0;}
    close(FHIN);
				# ------------------------------
				# delete if too old
    if ($Ldelete) { print "*** history file too old, delete it\n";
		    unlink $fileHistory;}
				# ------------------------------
				# write into history file
    $fhout2="FHOUT_HISTORY";
    open($fhout2, ">".$fileHistory) || do { warn "*** $scrName: cannot open new=$fileHistor: $!\n";
					    return(0); };
    print $fhout2 "day\t","time\t","req\t","ctMonth\t","diff\n";
    if ($#history>0){
	@tmp=split(/\t/,$history[1]);
	$diffNow=$ctM-$tmp[4];
	print $fhout2 "$day\t","$time\t","$numReq\t","$ctM\t","$diffNow\n"
	    if ($diffNow > $minDiffHistory);
	foreach $tmp(@history){
	    $tmp=~s/\n//g;
	    @tmp=split(/\t/,$tmp);
	    print $fhout2 "$tmp\n"
		if ($tmp[5] eq "-" || $tmp[5] > $minDiffHistory);}}
    else {
	$diffNow="-";
	print $fhout2 "$day\t","$time\t","$numReq\t","$ctM\t","$diffNow\n";} # start new history
    close($fhout2);
				# ------------------------------
				# write on WWW from history file
    if ($diffNow ne "-") {
	print  $fhout "--- \n";
	print  $fhout "--- Get a better estimate of what is going on today:\n";
	print  $fhout "--- \n";
	printf $fhout "--- %6s  %9s  %9s  %-s\n","time","in queue","N/month","Diff to previous";
	printf $fhout "--- %6s  %9d  %9d  %9s\n",$time,$numReq,$ctM,"$diffNow";
	foreach $his (@history){
	    @his2=split(/\t/,$his);
	    printf $fhout "--- %6s  %9d  %9d  %9s\n",$his2[2],$his2[3],$his2[4],$his2[5];}
	print  $fhout "--- \n";printf $fhout "--- %-60s\n","-" x 50;}

    return(1);
}				# end history


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
