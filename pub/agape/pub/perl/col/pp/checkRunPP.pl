#!/usr/pub/bin/perl4 -w
#
# checks log files and how many processes run where
# 
# 
$[ =1 ;

push (@INC, "/home/rost/perl","/home/phd/etc/") ;
require "ctime.pl";		# require "rs_ut.pl" ;
require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";

@machines=("alpha1","alpha2","alpha3","alpha4","alpha5",
	   "phenix");
$fileLog=  "/home/phd/server/log/phd.log";
$scriptRob="/home/phd/bin/pp_queue";
$nqueue=   3;
$LskipMach=0;
if ($#ARGV==0){
    print "--- checks log files and how many processes run where\n";
    print "--- may give 1:'skip' 2:'nppqueue' (skip machines, only 1->nppque or skip)\n";}
elsif ($#ARGV==1){
    if ($ARGV[1]=~/skip/){$LskipMach=1;}else{$nqueue=$ARGV[1];}}
elsif ($#ARGV==2){
    if    ($ARGV[1]=~/skip/){$LskipMach=1;$nqueue=$ARGV[2];}
    elsif ($ARGV[1]!~/[^0-9]/){
	$nqueue=$ARGV[1];if ($ARGV[2]=~/skip/){$LskipMach=1;}}}

				# first check processes
if (! $LskipMach){
    foreach $mach(@machines){
	if    ($mach =~/hawk|phenix/)    {$cmd="rsh $mach 'ps -ealf |grep phd'";}
	elsif ($mach =~/zinc|chrome/)    {$cmd="rsh $mach 'ps -aux |grep phd'";}
	elsif ($mach =~/copper|nu|alpha/){$cmd="rsh $mach 'ps -eaf |grep phd'";}
	else {
	    print "$mach unknown ps command\n";
	    $cmd="rsh $mach 'ps -eaf |grep phd'";}
	print "--- $mach: \n";
	system("$cmd | egrep -v 'grep|csh|rshd| ps| bash'");}
    print "--- ------------------------------ end machines ------------------------------ \n \n";
}
				# now log files and date
system("date");
system("wc -l $fileLog");
system("$scriptRob $nqueue");

exit;
