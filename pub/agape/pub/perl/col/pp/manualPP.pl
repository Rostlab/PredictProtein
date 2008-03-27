#! /usr/pub/bin/perl -w
#
#------------------------------------------------------------------------------#
#	Copyright				  Dec,    	 1994	       #
#	Burkhard Rost &		rost@EMBL-Heidelberg.DE			       #
#	Antoine de Daruvar	daruvar@lion-ag.de                             #
#	EMBL			http://www.embl-heidelberg.de/~rost/	       #
#	D-69012 Heidelberg						       #
#			    br  v 2.0a            Apr,           1998          #
#------------------------------------------------------------------------------#
#==================================================================
#
# this program run phd prediction on a given input file
# for the default user "test" with  origin "manual" and flag debug
#
#==================================================================

#======================================================================
# Read environment parameters
#======================================================================

# include phd_env package as define in $PPENV or default
if ($ENV{'PPENV'}) {
    $env_pack = $ENV{'PPENV'}; }
else {
    $env_pack = "/home/phd/server/scr/envPackPP.pl";  } # HARD CODDED

				# ------------------------------
$this_file= $0;			# get the name of this file
$this_file=~ s,.*/,,; $scrName=$this_file; $scrName=~s/\.pl//g;

				# ------------------------------
				# require local environment package
$Lok=                     require "$env_pack";
if (!$Lok)               {print "*** ERROR ($scrName): require env_pack=$env_pack returned 0\n";
			  exit(1);}
foreach $kwd ("pp_pred","password_def"){
    $envPP{"$kwd"}=       &envPP'getLocal("$kwd");          # e.e'
    if (! $envPP{"$kwd"}){print "*** ERROR ($scrName): '$kwd' not found in local env\n";
			  exit(1);}}
				# ------------------------------
				# Initialize some constant
				# ------------------------------
				# Test the Arguments
$mode="Manual";
$mode="testPP";			# xx change default!!

if ($#ARGV < 0 || $#ARGV > 2) {
    $bad_usage=1; }
else {
    $fileTo_pred= $ARGV[0];	# Name of the input file
    if (! -f $fileTo_pred) {
	warn "ERROR ($scrName): invalid input fileTo_pred $fileTo_pred\n";
	$bad_usage= 1; }
    if ($#ARGV > 0) {		# Name of the user (email-addr)
	$usr= $ARGV[1];  
	if    ($usr =~ /test|tst|^pp/){
	    $mode="testPP";
	    $debug=1;
	    $usr= "rost\@embl-heidelberg.de"; }
	elsif ($usr =~ /^loc/){
	    $debug=1;
	    $usr="local";
	    $mode=$ARGV[2];}}
    else   {$usr= "usr\@test.tst";
	    $usr= "rost\@embl-heidelberg.de"; }
    if ($#ARGV > 1) {		# Password
	$pwd= $ARGV[2]; }
    else {$pwd= $envPP{"password_def"}; }}

if ($bad_usage) {
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
    
# run the prediction in background
if ($ARGV[$#ARGV] eq "-s"){$debug="-s";}else{$debug="-d";}
$pp_pred=$envPP{"pp_pred"};

print "--- $scrName: '$pp_pred $fileTo_pred $file_result $usr $pwd $mode $debug'\n";

system "$pp_pred $fileTo_pred $file_result $usr $pwd $mode $debug";

exit;








