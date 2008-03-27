#!/usr/local/bin/perl -w
##!/usr/pub/bin/perl5 -w
##!/usr/pub/bin/perl5.003 -w
##! /usr/pub/bin/perl -w
#
#------------------------------------------------------------------------------#
#	Copyright				        	1999	       #
#	Burkhard Rost		rost@EMBL-Heidelberg.DE			       #
#	Wilckensstr. 15		http://www.embl-heidelberg.de/~rost/	       #
#	D-69120 Heidelberg						       #
#                                                                              #
#	Copyright				  Dec,    	1994	       #
#	Burkhard Rost &		rost@EMBL-Heidelberg.DE			       #
#	Antoine de Daruvar	daruvar@lion-ag.de                             #
#			    br  v 2.0             May,          1998           #
#			    br  v 2.1             Jan,          1999           #
#------------------------------------------------------------------------------#
#
#  This program runs PHD prediction on a given input file
#  for the default user "test" with  origin "manual" and flag debug
#
#------------------------------------------------------------------------------#
$[ =1 ;

				# --------------------------------------------------
				# Read environment parameters
				# --------------------------------------------------

				# include phd_env package as define in $PPENV or default
if ($ENV{'PPENV'}) {
    $env_pack = $ENV{'PPENV'}; }
else {
    $env_pack = "/home/$ENV{USER}/server/scr/envPP.pm";  } # HARD CODDED

				# ------------------------------
$this_file= $0;			# get the name of this file
$this_file=~ s,.*/,,; $scrName=$this_file; $scrName=~s/\.pl//g;

				# ------------------------------
				# require local environment package
$Lok=                     require "$env_pack";
if (!$Lok)               {print "*** ERROR ($scrName): require env_pack=$env_pack returned 0\n";
			  exit(1);}
foreach $kwd ("exe_ppPredict","password_def"){
    $envPP{"$kwd"}=       &envPP'getLocal("$kwd");          # e.e'
    if (! $envPP{"$kwd"}){print "*** ERROR ($scrName): '$kwd' not found in local env\n";
			  exit(1);}}
				# ------------------------------
				# Initialise some constants
				# ------------------------------
				# Test the Arguments
$mode="Manual";
$mode="testPP";			# xx change default!!
$Ldebug=0;
$Lbad_usage=0;          

$Lbad_usage=1                   if ($#ARGV < 1);

$usr= "rost\@columbia.edu";
$pwd= $envPP{"password_def"}; 
    
if (! $bad_usage) {
    $fileTo_pred= $ARGV[1];	# Name of the input file
    if    (! defined $fileTo_pred){
	warn "ERROR ($scrName): missing input fileTo_pred \n";
	$Lbad_usage= 1; } 
    elsif (! -f $fileTo_pred) {
	warn "ERROR ($scrName): invalid input fileTo_pred $fileTo_pred\n";
	$Lbad_usage= 1; } 
}

if (! $bad_usage) {
    foreach $arg (@ARGV) {
	next if ($arg eq $ARGV[1]);
	if    ($arg=~/^\-d$/) { 
	    $Ldebug=1; }
	elsif ($arg=~/^\-s$/) { 
	    $Ldebug=0; }
	elsif ($arg=~/\@/ || $arg=~/^(test|tst|pp|unk|rost)/) { 
	    $usr=$arg;
	    if    ($usr =~ /test|tst|^pp|^rost$/){
		$mode="testPP";
		$Ldebug=1;
		$usr= "rost\@columbia.columbia.edu"; }
	    elsif ($usr =~ /^loc/){
		$Ldebug=1;
		$usr="local";}
	    elsif ($usr =~/^unk/){
		$mode="testPP";
		$Ldebug=0;
		$usr= "rost\@columbia.edu"; }
	    else {
		$mode="MAIL";
		$Ldebug=0;}}
	elsif (length($arg)==5 && $arg=~/\w\d\d\d\w/) {
	    $pwd=$arg;}
	else {
	    print "*** $0 argument $arg not recognised\n";
	    $Lbad_usage=1;}}}

if (! $Lbad_usage){
    $Ldebug=0 if ($usr !~/^(rost|loc)/);}

if ($Lbad_usage) {
    print 
	"   Usage: \n",
	"$this_file predict_file [user_name [password]]\n",
	"   like : \n",
	"$this_file /home/pred/pred7898 \n",
	"$this_file /home/pred/pred7898 marcel\@site1.com\n",
	"$this_file /home/pred/pred7898 marcel\@site1.com x83yzq\n",
	"\n",
	"           (result of prediction will be in predict_file.pred)\n";
    exit(1);
}

if ($usr eq "local"){
    $tmp=$fileTo_pred;$tmp=~s/\.(pir|hssp|f|y|msf|dssp|phd).*$//g;
    $file_result=$tmp.".pred";}
else {
    $file_result= $fileTo_pred . ".pred";}
    
				# ------------------------------
				# run the prediction in background
				# ------------------------------
				# default = debug
$debug="-d";

				# silent mode
$debug="-s"                     if (! $Ldebug);
    
$exe_ppPredict=$envPP{"exe_ppPredict"};

print "--- $scrName: '$exe_ppPredict $fileTo_pred $file_result $usr $pwd $mode $debug'\n";
				# ------------------------------
				# delete if result there already
				# ------------------------------
if (-e $file_result) {
    $file_resultOld=$file_result.".tmp";
    print "--- note: the result $file_result exists, moved to $file_resultOld\n";
    system("\\mv $file_result $file_resultOld");}

				# ------------------------------
				# run it (system call)
				# ------------------------------
$cmd="$exe_ppPredict $fileTo_pred $file_result $usr $pwd $mode $debug";
system("$cmd");

exit;








