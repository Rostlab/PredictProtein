#!/usr/pub/bin/perl -w
#------------------------------------------------------------------------------#
#	Copyright				  Dec,    	 1994	       #
#	Burkhard Rost &		rost@EMBL-Heidelberg.DE			       #
#	Antoine de Daruvar	daruvar@lion-ag.de                             #
#	EMBL			http://www.embl-heidelberg.de/~rost/	       #
#	D-69012 Heidelberg						       #
#			    br  v 1.0             Mar,           1997          #
#			    br  v 2.0a            Apr,           1998          #
#------------------------------------------------------------------------------#
#
# this is the program called when a e-mail request is submitted.
#
#----------------------------------------------------------------------#

#======================================================================
# Read environment parameters
#======================================================================

				# ------------------------------
$this_file=$0;			# get the name of this file
$this_file=~s,.*/,,; $scrName=$this_file; $scrName=~s/\.pl//g;
				# --------------------------------------------------
				# include envPP package as define in $PPENV or default
if ($ENV{'PPENV'}) {$env_pack = $ENV{'PPENV'}; }
else {				# this is used by the automatic version!
    $env_pack = "/home/phd/server/scr/envPackPP.pl"; } # HARD CODDED
$Lok=
    require "$env_pack";
                    		# *** error in require env
&ctrlAbort("failed to require env_pack ($env_pack)"."\n*** err=101") if (! $Lok);
				# ------------------------------
				# read local environment var
				# ------------------------------
foreach $des ("dir_work","dir_predict","file_emailReqLog","par_patDirPred",
	      "exe_mail","pp_admin","dir_bup_errIn"){
    $envPP{"$des"}=&envPP'getLocal("$des");                      # e.e'
				# *** error in local env
    &ctrlAbort("failed to get envPP{$des} from env_pack ($env_pack)\n*** err=102") 
	if (! $envPP{"$des"});}
				# --------------------------------------------------
				# Test the Arguments
				# --------------------------------------------------
if ($#ARGV < 1) { $bad_usage= 1; }
else {$file_name= $ARGV[0];	# Name of the input file
      if (! -f $file_name) { warn "ERROR from $this_file: invalid input file $file_name\n";
			     $bad_usage= 1; }
      $user_addr= $ARGV[1];	# address of the user
      if ( !$user_addr)    { warn "ERROR from $this_file: invalid user address $user_addr\n";
			     $bad_usage= 1;}}
				# hack br 98-05: avoid loops
if ($user_addr=~/phd\@/){
    $bad_usage=1;
    $dir=$envPP{"dir_bup_errIn"};
    system("\\mv $file_name $dir") if (-d $dir);
    unlink($file_name) if (-e $file_name);}

&ctrlAbort("Usage: \n".
	   "   $this_file predict_file submitter_addr\n".
	   "like : \n".
	   "   $this_file /home/pred/pred7898 marcel\@le-tatoue.fr\n")
    if ($bad_usage);

#======================================================================
# build a file for prediction
#======================================================================

# create the prediction file in the working dir
$fileTo_pred= $envPP{"dir_work"} . "/" .$envPP{"par_patDirPred"}. "e".$$;

open (TOPRED, "> $fileTo_pred");
print TOPRED "from $user_addr\n";
print TOPRED "resp MAIL\n";
print TOPRED "orig MAIL\n";
close(TOPRED);

system "cat $file_name >> $fileTo_pred";

# set access on the file
system "chmod 666 $fileTo_pred";
#system "chown phd $fileTo_pred";

# move the file in the predict directory
$dir_predict=$envPP{"dir_predict"};
system "mv $fileTo_pred $dir_predict";

# log the request in email-logfile
$short_name= $file_name;
$short_name=~ s/.*\///;
$short_pred= $fileTo_pred;
$short_pred=~ s/.*\///;
$file_emailReqLog=$envPP{"file_emailReqLog"};
system "echo `date` $user_addr $short_name $short_pred >> $file_emailReqLog";
#system "echo `date` $user_addr $short_name $short_pred ";

# remove the input file
# xx unlink "$file_name" if (-e $file_name);
# end of the script

exit;

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
	"rost\@embl-heidelberg.de" if (! defined $envPP{"pp_admin"});
    if (! defined $envPP{"exe_mail"}){
	if (-e "/usr/sbin/Mail" ){$envPP{"exe_mail"}="/usr/sbin/Mail" ;}
	else                     {$envPP{"exe_mail"}="/usr/bin/Mail" ;}}
    $Date=localtime(time) if (! defined $Date);
				# ------------------------------
				# compose message
    $message=  "*** $scrName $Date \n"."$message\n";
    $exe_mail=$envPP{"exe_mail"}; $pp_admin=$envPP{"pp_admin"};
    $cmd="echo '$message' | $exe_mail -s PP_ERROR_emailPredPP $pp_admin";
    system("$cmd");
				# ------------------------------
				# write to trace file (file_crontabLog, resp STDOUT)
    print "$message\n";		# error message
    print "*** $scrName ctrl: did system \t ",$cmd,"\n";
    exit(1);
}				# end of ctrlAbort

