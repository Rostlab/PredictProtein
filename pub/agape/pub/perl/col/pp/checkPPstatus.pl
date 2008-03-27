#!/usr/pub/bin/perl4
#
# checks the Status of PredictProtein
# input: 
#       ARGV[1]= mode (normal|copy|down)
#       ARGV[2]= add_in_file (comments to append) now:
#            /home/www/htdocs/Services/sander/predictprotein/PPstatus.add
#       ARGV[3]= output file (to be read by WWW)  now: 
#            /home/www/htdocs/Services/sander/predictprotein/PPstatus.log
#
#       ARGV[4]= history     (to be put onto WWW) now: 
#            /home/www/htdocs/Services/sander/predictprotein/PPstatus.history
#
#       ARGV[5]= directory of 'to-be-predicted'   now: server/pred
#       ARGV[6]= file_phd_log                     now: server/log/phd.log
#
# alternative:
#       1='down' 2=down time
#       1='copy' 2=file-to-copy 3=file-to-be-copied-to (PPstatus.log)
#--------------------------------------------------------------------------------
$[=1;
local ($mode,$fileAdd,$fileState,$fileHistory,$dirPred,$fileLog)=@ARGV;
local ($timeX,$time,$fhout,@FL,$f,$hours,$maxhours,$req,$ctM,$ctD,$month,$day);

require "/home/phd/ut/perl/ctime.pl";
				# default
$modeDef=        "normal";
$fileAddDef=     "/home/www/htdocs/Services/sander/predictprotein/PPstatus.add"; # 
$fileStateDef=   "/home/www/htdocs/Services/sander/predictprotein/PPstatus.log"; # 
$dirPredDef=     "/home/phd/server/pred";
$fileLogDef=     "/home/phd/server/log/phd.log";
$fileHistoryDef= "/home/www/htdocs/Services/sander/predictprotein/PPstatus.flag"; # 

$minDiffHistory=20;		# minimal difference to report history
$minDiffHistory=5;		# minimal difference to report history
$minDiffHistory=10;		# minimal difference to report history

$modeDef=    $modeDefDef     if (! defined $modeDef );
$dirPred=    $dirPredDef     if (! defined $dirPred );
$fileState=  $fileStateDef   if (! defined $fileState);
$fileLog=    $fileLogDef     if (! defined $fileLog );
$fileHistory=$fileHistoryDef if (! defined $fileHistory );
$fileAdd=    $fileAddDef     if (! defined $fileAdd );
$fileFlag=   $fileFlagDef    if (! defined $fileFlag );

if    ($ARGV[1] eq "down"){&ppIsDown($ARGV[2]);
			   exit;}
elsif ($ARGV[1] eq "copy"){if (-e $ARGV[2]){&ppCpFile($ARGV[2],$ARGV[3]);
					    exit;}
			   else{
			       print "*** ERROR ($0) called missing file ($ARGV[2]) to copy\n";
			       exit;}}
if ($#ARGV<6){
    print "*** status wrong number of arguments \n";
    print "***    either: checkPPstatus.pl mode fileAdd fileOut fileHistory dirPred fileLog\n";
    print "***    xor:    checkPPstatus.pl down 'downDate'\n";
    print "***    xor:    checkPPstatus.pl copy file-to-copy file-to-be-copied-to\n";
    system("echo 'status wrong number of args in $0' >> /home/phd/server/log/Error-status.log");
    exit;}
				# ------------------------------
$fhout="FH_FILE_STATE";		# open output file
open($fhout, ">$fileState") || warn "Cannot open $fileState: $!\n"; 
				# ------------------------------
				# get date
if (defined &ctime){
    $time=&ctime(time);$time=~s/\n//g; }
else {
    $time=`date`;}
@date=split(/\s+/,$time);$month=$date[2];$day=$date[3];
$timeX=$time;
$timeX="$date[1] $month $day $date[4]" if ($date[4] =~/^19|20/);
				# ------------------------------
				# write header
printf $fhout "--- %-60s\n","-" x 50;
print  $fhout "--- State of the PredictProtein server\n--- \n";
printf $fhout "--- %-30s %19s\n","Status on",$timeX;  
printf $fhout "--- \n";
				# ------------------------------
				# get number of requests pending
opendir(X,$dirPred);@FL=readdir(X);closedir(X);$maxhours=0;
if($#FL>2){
    for $f (@FL) {next if ($f=~/^\./);
		  $hours=24.0*(-C "$dirPred/$f");
		  $maxhours=$hours if $hours>$maxhours;
		  $req++;}$maxhours=~s/\s|\n//g;
    printf $fhout "--- %-35s %-6d\n",  "Number of requests in queue",$req;
    printf $fhout 
	"--- %-35s %-3.1f\n","Estimated time in queue (hours)",
	($maxhours+($req/10)*0.1);}
else {
    printf $fhout "--- %-35s\n","No request in queue";}
				# ------------------------------
				# read log file
open(FHIN, "$fileLog") || warn "Can't open $fileLog: $!\n"; 
$ctM=$ctD=0;while(<FHIN>){++$ctM if ($_=~/ $month\:/);
			  ++$ctD if ($_=~/ $month\:$day/);}close(FHIN);

print  $fhout "--- \n";
printf $fhout "--- %-35s %-5d \n","Number of requests in $month",$ctM;
printf $fhout "--- %-35s %-5d \n","Number requests on $month, $day",$ctD;
print  $fhout "--- \n";
printf $fhout "--- %-s \n","RELOAD for latest version (update every 20 min)!";
print  $fhout "--- \n";printf $fhout "--- %-60s\n","-" x 50;

if (($req>1)&&($#ARGV>3)&&(-e $fileHistory)){
    &history; }			# get history

close($fhout);
				# ------------------------------
				# add file with Notes
if (-e $fileAdd){
    system"cat $fileAdd >> $fileState";
}
system("chmod go+r $fileState"); # make readable for WWW

exit;

# ================================================================================
sub ppIsDown {
    local ($downTime)=@_;

    $fhout="FH_FILE_STATE";
    open($fhout, ">$fileState") || warn "Cant open $fileState: $!\n"; 
    print $fhout 
	"--- --------------------------------------------------\n",
        "--- State of PredictProtein service\n",
	"--- \n",
	"--- APOLOGIES: the service is down since:\n---    $downTime\n",
	"--- \n",
	"--- Wait and/or hope, or send mail to:\n---    unixmanager\@embl-heidelberg.de\n",
	"--- \n",
	"--- --------------------------------------------------\n\n";
    close($fhout);
}				# end ppIsDown

# ================================================================================
sub ppCpFile {
    local ($fileIn,$fileOut)=@_;
    print "$0: '\\cp $fileIn $fileOut'\n";
    system("\\cp $fileIn $fileOut");
}				# end ppCpFile

# ================================================================================
sub history {

    $time=$date[4];$time=~s/\:\d+$//g;

    $#history=0;		# ------------------------------
    $Ldelete=1;			# get history
    open(FHIN, "$fileHistory") || warn "Cannot open $fileHistor: $!\n";
    while(<FHIN>){next if ($_=~/^da/);
		  $_=~s/\n//g;$line=$_;
		  @tmp=split(/\t/,$_);
		  last if ($tmp[1] ne "$day");
		  push(@history,$line);
		  $Ldelete=0;}close(FHIN);
				# delete if too old
    if ($Ldelete){print "*** history file too old, delete it\n";
		  unlink $fileHistory;}
				# ------------------------------
				# write into history file
    $fhout2="FHOUT_HISTORY";
    open("$fhout2", ">$fileHistory") || warn "Cannot open $fileHistory: $!\n";
    print $fhout2 "day\t","time\t","req\t","ctMonth\t","diff\n";
    if ($#history>0){
	@tmp=split(/\t/,$history[1]);
	$diffNow=$ctM-$tmp[4];
	if ($diffNow > $minDiffHistory){
	    print $fhout2 "$day\t","$time\t","$req\t","$ctM\t","$diffNow\n";}
	foreach $tmp(@history){
	    $tmp=~s/\n//g;
	    @tmp=split(/\t/,$tmp);
	    if (($tmp[5] eq "-")||($tmp[5]>$minDiffHistory)){
		print $fhout2 "$tmp\n";}}}
    else {
	$diffNow="-";
	print $fhout2 "$day\t","$time\t","$req\t","$ctM\t","$diffNow\n";} # start new history
    close($fhout2);
				# ------------------------------
				# write on WWW from history file
    if ($diffNow ne "-") {
	print  $fhout "--- \n";
	print  $fhout "--- Get a better estimate of what is going on today:\n";
	print  $fhout "--- \n";
	printf $fhout "--- %6s  %9s  %9s  %-s\n","time","in queue","N/month","Diff to previous";
	printf $fhout "--- %6s  %9d  %9d  %9s\n",$time,$req,$ctM,"$diffNow";
	foreach $his (@history){
	    @his2=split(/\t/,$his);
	    printf $fhout "--- %6s  %9d  %9d  %9s\n",$his2[2],$his2[3],$his2[4],$his2[5];}
	print  $fhout "--- \n";printf $fhout "--- %-60s\n","-" x 50;}
}				# end history
