#!/usr/pub/bin/perl4 -w
#
# VAX:      cleans up files 'mail_*.com' *.header *.text 
#           for some reason left on VAX
#
# UNIX:     cleans up /home/phd/work/
# 
# NOTE:     input date (day!): 
#           EVERYTHING differing from date number will be deleted
#
$[ =1 ;

require "/home/phd/ut/perl/ctime.pl";		# require "rs_ut.pl" ;
require "/home/phd/ut/perl/lib-ut.pl"; 
require "/home/phd/ut/perl/lib-prot.pl"; 
require "/home/phd/ut/perl/lib-comp.pl";

if (($#ARGV<1) || ($ARGV[1] ne "auto")){
    print "VAX:    remove mail_*.com|.header|.text from VAX and all files in server/work\n";
    print "UNIX:   remove all files in /home/phd/server/work/\n";
    print "\n";
    print "in:     date ('day_number'=1,..,31 or 'Jan' ...)\n";

    @Date = split(' ',&ctime(time)) ; shift (@Date) ; 
    $dateIn=$Date[2];		# day number (1-31)
    print "NOW:    ==========================\n";
    print "NOW:    TAKE as default today =$dateIn\n";
    print "NOW:    ==========================\n";

    print "option: 'unix' or 'vax' (default both)\n\n";
    print "        'screen'  to print onto screen\n";}
else{
    $dateIn=$ARGV[1];}

$Lunix=$Lvax=$Lscreen=0;
foreach $_ (@ARGV){if   (/^unix/)   {$Lunix=1;}
		   elsif(/^vax/)    {$Lvax=1;}
		   elsif(/^screen/) {$Lscreen=1;}}
if ((! $Lunix) && (! $Lvax)) { $Lunix=$Lvax=1; }

$dirVax=      "/vms/u/phd/";
$dirUnix=     "/home/phd/server/work/";
if    (-d "/home/phd/server/err"){
    $dirUnixError="/home/phd/server/err/" ;}
elsif (-d "/home/phd/server/error"){
    $dirUnixError="/home/phd/server/error/" ;}
else {
    $dirUnixError="/home/phd/server/err/" ;
    system("mkdir $dirUnixError");}
				# all VAX files with mail_* and *.sequence deleted
$preDel= "mail_";
$extDel= "sequence";

$fileTmpVax= "/junk/phd/DelVAX".$$.".tmp";
$fileTmpUnix="/junk/phd/DelUNIX".$$.".tmp";
$fhin="FHIN";
				# ------------------------------
				# list files
if ($Lvax) {
    if ($Lscreen){print "--- system \t 'ls -l $dirVax >> $fileTmpVax'\n";}
    system("ls -l $dirVax >> $fileTmpVax");}
if ($Lunix){
    if ($Lscreen){print "--- system \t 'ls -l $dirUnix >> $fileTmpUnix'\n";}
    system("ls -l $dirUnix >> $fileTmpUnix");
    if ($Lscreen){print "--- system \t 'ls -l $dirUnixError >> $fileTmpUnix'\n";}
    system("ls -l $dirUnixError >> $fileTmpUnix");}
	    
				# --------------------------------------------------
				# VAX: grep older (and newer, i.e. checks
				# only whether or not day is EXACTLy the same)
if ($Lvax){
    &open_file("$fhin", "$fileTmpVax");
    while (<$fhin>) {
	if (! /phd/){		# no list
	    next;}
	$_=~s/\n//g;
	@tmp=split(/\s+/,$_);
	$month=$tmp[6];$day=$tmp[7];$file=$tmp[9];
	if ($Lscreen){
	    printf "--- reading: %-3s %3d %-s\n",$month, $day,$file;}
	if (($file !~ /^$preDel/)&&($file !~ /$extDel$/)){ # not file 'mail_*'
	    next;}
	if    (($dateIn =~/[A-Z][a-z][a-z]/)&&($month eq $dateIn)){
	    $fileDel=$dirVax."$file";
	    if ($Lscreen){
		print "--- system \t '\\rm $fileDel'\n";}
	    system("\\rm $fileDel");}
	elsif (($dateIn =~/\d+/)&&($day != $dateIn)){
	    $fileDel=$dirVax."$file";
	    if ($Lscreen){
		print "--- system \t '\\rm $fileDel'\n";}
	    system("\\rm $fileDel");}
	else {
	    if ($Lscreen){
		print "--- keep \t '$file' (from today)\n";}
	}
    }close($fhin);}
				# --------------------------------------------------
				# UNIX: grep older (and newer, i.e. checks
				# only whether or not day is EXACTLy the same)
if ($Lunix){
    &open_file("$fhin", "$fileTmpUnix");
    while (<$fhin>) {
	$_=~s/\n//g;
	@tmp=split(/\s+/,$_);
	$month=$tmp[6];$day=$tmp[7];$file=$tmp[9];
	next if ( (! defined $month)||(! defined $day)||(! defined $file));
	if ($Lscreen){
	    printf "--- reading: %-3s %3d %-s\n",$month, $day,$file;}
	if    (($dateIn =~/[A-Z][a-z][a-z]/)&&($month eq $dateIn)){
	    $fileDel=$dirUnix."$file";
	    if (! -e $fileDel){
		$fileDel=$dirUnixError."$file";}
	    next if (-d $fileDel); # skip if directory
	    if (-e $fileDel){
		if ($Lscreen){
		    print "--- system \t '\\rm $fileDel'\n";}
		system("\\rm $fileDel");}}
	elsif (($dateIn =~/\d+/)&&($day != $dateIn)){
	    $fileDel=$dirUnix."$file";
	    if (! -e $fileDel){
		$fileDel=$dirUnixError."$file";}
	    next if (-d $fileDel); # skip if directory
	    if (-e $fileDel){
		if ($Lscreen){
		    print "--- system \t '\\rm $fileDel'\n";}
		system("\\rm $fileDel");}}
	else {
	    if ($Lscreen){
		print "--- keep \t '$file' (from today)\n";}
	}
    }close($fhin);
}
exit;
