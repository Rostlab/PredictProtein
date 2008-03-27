#!/usr/bin/perl -w
##!/usr/local/bin/perl -w
##!/usr/pub/bin/perl5 -w
##!/usr/local/bin/perl -w
##!/usr/pub/bin/perl5.003 -w
##!/usr/pub/bin/perl -w
##!/usr/pub/bin/perl -w
##!/usr/pub/bin/perl5.00404 -w
#===============================================================================
#                                                                              #
#------------------------------------------------------------------------------#
#	Copyright				        	1999	       #
#	Burkhard Rost		rost@EMBL-Heidelberg.DE			       #
#	Wilckensstr. 15		http://www.embl-heidelberg.de/~rost/	       #
#	D-69120 Heidelberg						       #
#                                                                              #
#	Copyright				  Dec,    	1994	       #
#	Burkhard Rost &		rost@EMBL-Heidelberg.DE			       #
#	Antoine de Daruvar	daruvar@lion-ag.de                             #
#	Guy Yachdav             yachdav@cubic.bioc.columbia.edu  	       #
#	EMBL			http://www.embl-heidelberg.de/~rost/	       #
#	D-69012 Heidelberg						       #
#			    br  v 0.5   	  Mar,          1996           #
#			    br  v 1.5             Jun,          1997           #
#			    br  v 2.0a            Jan,          1998           #
#			    br  v 2.0b            Feb,          1998           #
#			    br  v 2.0c            Apr,          1998           #
#			    br  v 2.1             Apr,          1999           #
#------------------------------------------------------------------------------#
# 
# this program run phd prediction on a given input file
# 
#------------------------------------------------------------------------------#

				# ------------------------------
$this_file=$0;			# get the name of this file
$this_file=~s,.*/,,; $scrName=$this_file; $scrName=~s/\.pl//g;

				# ------------------------------
$bad_usage=0;			# Test the Arguments
$debug=0;
if ($#ARGV < 4 || $#ARGV > 6) {
    $msg="number of input arguments must be 4-6, is=".$#ARGV; $bad_usage=1; }
else {
    $fileTo_pred= $ARGV[0];	# Name of the input file
    if (! -f $fileTo_pred) {warn "ERROR ($scrName): invalid input file $fileTo_pred\n";
			    $msg="invalid input file $fileTo_pred";$bad_usage= 1;}
    $file_result= $ARGV[1];	# Name of the result file
    if ( -f $file_result)  {warn "ERROR ($scrName): result file exists $file_result\n";
			    $msg="result file exists $file_result";$bad_usage= 1;}
    $submitter=   $ARGV[2];	# Name of the submitter
    if (!$submitter)       {warn "ERROR ($scrName): invalid submitter $submitter\n";
			    $msg="invalid submitter $submitter";$bad_usage= 1;}
    $password=    $ARGV[3];	# Password of the submitter
    if (!$password)        {warn "ERROR ($scrName): invalid password $password\n";
			    $msg="invalid password $password";$bad_usage= 1;}
    $origin=      $ARGV[4];	# origin of the submitter
    if (!$origin)          {warn "ERROR ($scrName): invalid origin $origin\n";
			    $msg="invalid origin $origin";$bad_usage= 1;}

    $dbid=      $ARGV[5];	# id refernce to request table in the db 
    if (!$dbid)          {warn "ERROR ($scrName): invalid dbid $dbid\n";
			    $msg="invalid dbid $dbid";$bad_usage= 1;}

				# --------------------
    if ($#ARGV == 6) {		# options
	$option=  $ARGV[6];
	if ($option !~ /^-[sdl]*/ ) {
	    warn "ERROR ($scrName): invalid option $option (last argument not right match)\n";
	    $msg="invalid option $option (last argument not right match)";$bad_usage= 1;}
	else {
	    $silence= 1  if ($option =~ /s/);
	    $debug=   1  if ($option =~ /d/);
	    $local=   1  if ($option =~ /l/);}}}

#$debug=1;			# xxxxx


if ($bad_usage) {
    $msg= "*** ERROR $scrName\n*** msg=$msg\n";
    $msg.="Usage: \n";
    $msg.="   $this_file predict_file result_file submitter password origin [-sld]\n";
    $msg.="like : \n";
    $msg.="   $this_file /home/pred/pred7898 /home/res/7898.res Marcel\@yy.fr x007 html\n";
    $msg.=" \n";
    $msg.="       (with option s ==> silence : STDOUT and STDERR are redirected to files\n";
    $msg.="                    l ==> debug   : use local default as working directory\n";
    $msg.="                    d ==> debug   : the working files are not removed)\n";
    exit(1);}
				# no mail here, written onto screen anyway!
#    &ctrlAbort("$msg\n*** err=1");}

				# --------------------------------------------------
				# set working directory if -l flag is set
				# --------------------------------------------------
if ($local) {$local_dir= `pwd`;
	     chop($local_dir);
	     $ENV{'PPWORKDIR'}= $local_dir;} # HARD_CODED
 
				# --------------------------------------------------
				# Read environment parameters
				# --------------------------------------------------
				# include phd_env package as define in $PPENV or default
if ($ENV{'PPENV'}) {
    $env_pack = $ENV{'PPENV'}; }
else {				# this is used by the automatic version!
    $env_pack = "/nfs/data5/users/$ENV{USER}/server/scr/envPP.pm"; } # HARD CODDED

				# ------------------------------
$Lok=				# require local environment
    require "$env_pack";
				# ******************************
                    		# *** error in require
&ctrlAbort("*** $scrName failed to require env_pack ($env_pack)"."\n*** err=2") 
    if (! $Lok);
				# ------------------------------
				# read local environment var
				# ------------------------------
foreach $des ("pack_predict","dir_work","file_errLog","file_predMgrLog",
	      "exe_mail","pp_admin","pp_admin_sendWarn",
	      "lib_pp","lib_ctime"){
    $envPP{"$des"}=&envPP'getLocal("$des");                      # e.e'

				# ******************************
    if (! $envPP{"$des"}){	# *** error in local env
	&ctrlAbort("*** $scrName failed to get envPP{$des} from env_pack ($env_pack)\n".
		   "*** err=3");}}
				# ------------------------------
				# include phd prediction package
foreach $libKwd ("pack_predict","lib_ctime"){
    $Lok=0;
    $Lok=require $envPP{"$libKwd"};
				# ******************************
    if (!$Lok){			# *** error in require

	&ctrlAbort("*** $scrName failed to get envPP{$libKwd} from env_pack ($env_pack)\n".
		   "*** err=4");}}
				# get date
if (defined &ctime){@Date= split(' ',&ctime(time));
		    shift (@Date); $Date = join(':',@Date);}
else               {$Date=`date`;}
				# ------------------------------
				# Is the silence option on
				# ------------------------------
if ($silence) {			# redirect STDOUT and STDERR
#    open (STDOUT, "> $filePred_out");
#    open (STDERR, "> $filePred_err");
#    printf "\n=====> START PREDICTION: PID %-s at %s" , $$,`date`;
#    print  "--- predict (predPackPP.pl) ".
#	"args: '$fileTo_pred,$file_result,$submitter,$password,$origin,$debug'\n";
				# build the trace file names
#    $dir_work=   $envPP{"dir_work"};
#    $filePred_out=$dir_work . "/" . "out" . "_" . $$;
#    $filePred_err=$dir_work . "/" . "err" . "_" . $$;

    $txt= "=====> START PREDICTION: PID ".$$." date=$Date\n";
    $txt.="--- predict (predPackPP.pl) ".
	"args: '$fileTo_pred,$file_result,$submitter,$password,$origin,$debug, $dbid'";
    $filePredManagerLog=$envPP{"file_predMgrLog"};
    system("echo '$txt' >> $filePredManagerLog");
}

#======================================================================
# run prediction
#======================================================================

$hname= `hostname`;open (FO, ">$fileTo_pred.$hname");close FO;


($Lok,$txt)=
    &predictPP'predict($fileTo_pred,$file_result,$submitter,$password,$origin,$dbid, $debug); # '

&ctrlAbort("*** $scrName failed to return 1\n***        instead gave ok=$Lok, txt=$txt\n".
	   "*** err=5") 
    if (! $Lok);
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
	"predict_help\@columbia.edu" if (! defined $envPP{"pp_admin"});
#	"rost\@columbia.edu" if (! defined $envPP{"pp_admin"});
    if (! defined $envPP{"exe_mail"}){
	if (-e "/usr/sbin/Mail" ){$envPP{"exe_mail"}="/usr/sbin/Mail" ;}
	else                     {$envPP{"exe_mail"}="/usr/bin/Mail" ;}}
    

    $Date=localtime(time) if (! defined $Date);
				# ------------------------------
				# compose message
    $header=   "*** $scrName: $Date"; 
    $message=  "$header" . "\n" . "$message, fileIn=$fileTo_pred res=$file_result\n";
				# ------------------------------
				# surpress sending warnings ?
				# ------------------------------
    $pp_admin_sendWarn=1;
    $pp_admin_sendWarn=0        if (! defined $envPP{"pp_admin_sendWarn"} || 
				    $envPP{"pp_admin_sendWarn"} eq "no");
    $pp_admin=0;
    $exe_mail=0;
    if ($pp_admin_sendWarn) {
	$exe_mail=$envPP{"exe_mail"} if (-e $envPP{"exe_mail"} || 
					 -l $envPP{"exe_mail"});
	$pp_admin=$envPP{"pp_admin"};
	system("echo '$message' | $exe_mail -s PP_ERROR_$scrName $pp_admin"); }
				# ------------------------------
				# write to trace file
    print "*** $scrName message=$message\n";
				# send mail ?
    print "*** $scrName system call \t".
	"echo '$message' | $exe_mail -s PP_ERROR_$scrName $pp_admin"."\n"
	    if ($pp_admin && $exe_mail);
    exit(1);
}				# end of ctrlAbort
