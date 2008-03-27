#!/usr/pub/bin/perl -w
#
#------------------------------------------------------------------------------#
#	Copyright				  Apr,    	 1998	       #
#	Burkhard Rost 		rost@EMBL-Heidelberg.DE			       #
#	EMBL			http://www.embl-heidelberg.de/~rost/	       #
#	D-69012 Heidelberg						       #
#			        v 1.0   	  Apr,           1998          #
#------------------------------------------------------------------------------#
#
# processes the procmail output (activated by /home/phd/etc/procmail/pp-procmail)
#
#----------------------------------------------------------------------#
				# ------------------------------
$[ =1 ;				# start counting with 1

				# ------------------------------
($Lok,$msg)=			# read environment parameters
    &ini;

$fileTrace=  $envPP{"file_procmailLog"};
$dirErrMail= $envPP{"dir_bup_errMail"};
$fileTrace="/home/phd/server/log/procmail-logTrace.tmp" 
    if (! defined $fileTrace);

if (! $Lok){
    $msg.="\n*** err=1";
				# no MAIL!!
#    &ctrlAlarm("$msg");
    system("echo '$msg' >> $fileTrace");
    die("$msg");}

$fhout="FHOUT_".$scrName;
$fhin= "FHIN_".$scrName;
				# --------------------------------------------------
				# read information
				# first: read
				# --------------------------------------------------
$fileIn=$ARGV[1];
if (! -e $fileIn){
    $txt="*** $scrName missing input $fileIn\n";
    system("echo '$txt' >> $fileTrace");
    die("$txt");}

open ("$fhin","$fileIn") || 
    system("echo '*** $scrName no input $fileIn' >> $fileTrace");

while (<$fhin>) {
    $_=~s/\n+$//g;
    next if (! defined $_ || length($_)<1);
    push(@line,$_);
}close($fhin);
				# --------------------------------------------------
				# process input
				# --------------------------------------------------
$#content=0;$Lbody=0;
foreach $line(@line){
    next if (! defined $line || length($line)<1);
    $line=~s/\n*//;		# purge EOF
				# ------------------------------
				# process header
    if    ($line =~/^From ([^\s]+) (.+)$/){ # for security first 'From rost date'
	$from1=$1; $date=$2;
	next;}
    elsif ($line =~/From\: .*\s?\<([^\>]*)\>/){ # real procmail entry 'From: <rost>'
	$from=$1;
	next;}
    elsif ($line =~/Message-Id\:\s*\<[^\@]*\@([^\>]*)\>/i){
	$mach=$1;
	next;}
    elsif ($line =~/Subject\:\s*(.*)$/){
	$subj=$1;
	$Lbody=1;
	next;}
    elsif ($line =~/^\s*Content\-/){
	$Lbody=1;
	next;}
    $tmp=$line;$tmp=~s/\s//g;
    next if (length($tmp)<1);	# empty line
    next if (! $Lbody);		# not info, yet
				# ------------------------------
				# process body
    push(@content,$line);
}
				# ------------------------------
				# check email 
				# ------------------------------
$from=~s/\s//g if (defined $from);
$from=$from1   if (! defined $from || length($from)<3); # use first from (mailer error??)
				# is embl
$from.="\@embl-heidelberg.de" if ($from !~/\@/ && $mach =~/embl/);

if (! defined $from || $from !~/\@/){		# search in file
    foreach $content(@content){
	if ($content =~ /\@/){
	    $content=~tr/[A-Z]/[a-z]/; # to lower caps
	    $tmp=$content;$tmp=~s/^\W*(\w+\@\w+\.[a-z][a-z][a-z]*)\W/$1/g;
	    $from=$tmp;
	    last;}}}
if (! defined $from || $from !~/\@/){		# no correct address -> abort
    $msg="*** $scrName unrecognised user from=$from, mach=$mach, err=2, READ:";
    foreach $it (1..10){$msg.="$line[$it]\n";} # write first 10 lines
    system("echo '$msg' >> $fileTrace");
				# no MAIL!!
#    &ctrlAlarm("$msg");
    
    if (-d $dirErrMail){system("\\mv $fileIn $dirErrMail");} # xx
    unlink($fileIn) if (-e $fileIn);
    die("$msg");}
if (! defined $from || $from =~/^phd\@/){ # hack br 98-05: avoid loops
    $msg="*** $scrName input from user PHD???";
    system("echo '$msg' >> $fileTrace");
    &ctrlAlarm("$msg");
    if (-d $dirErrMail){system("\\mv $fileIn $dirErrMail");} # xx
    unlink($fileIn) if (-e $fileIn);
    die("$msg");}
				# --------------------------------------------------
				# write output file
				# --------------------------------------------------
$dirWork= $envPP{"dir_work"};
$dirWork= $dirWork . "/" if ($dirWork =~ /[^\/]$/ );
$jobid=$fileIn; $jobid=~s/^.*\///g;$jobid=~s/\.pro.*$//g;
$fileOut=$dirWork.$jobid.".procmail-out";

open ("$fhout",">$fileOut");
$date=`date`       if (! defined $date);
$subj="no subject" if (! defined $subj);
print $fhout "from=$from, date=$date, mach=$mach, subj=$subj,\n";
foreach $content(@content){
    print $fhout "$content\n";
}close($fhout);

#system("echo 'xx ($subj) arrived 5, after fileOut=$fileOut' >> $fileTrace");

if (! -e $fileOut){
    $msg="*** $scrName $fileOut not written (err=3)";
    $msg.="\n*** err=3";
    system("echo '$msg' >> $fileTrace");
				# no MAIL!!
#    &ctrlAlarm("$msg");
    if (-d $dirErrMail){system("\\mv $fileIn $dirErrMail");} # xx
    unlink($fileIn) if (-e $fileIn);
    die("$msg");}
				# --------------------------------------------------
				# call script for further processing
				# --------------------------------------------------
$cmd=$envPP{"pp_emailPred"}." $fileOut $from";
system("echo 'xx ok procmail.pl: pp_emailPred $fileOut $from $date' >> $fileTrace");
system("$cmd");
				# clean up
unlink($fileOut) if (! defined $LisLocal || ! $LisLocal);
unlink($fileIn)  if (! defined $LisLocal || ! $LisLocal);
exit;


#===============================================================================
sub ini {
#    $[ =1 ;
#-------------------------------------------------------------------------------
#   ini                       
#-------------------------------------------------------------------------------
				# ------------------------------
    $scrName=$0;		# get the name of this file
    $scrName=~s,.*/,,; $scrName=~s/\.pl//g;
				# --------------------------------------------------
                                # include phd_env package as define in $PPENV or default
				# --------------------------------------------------
    if ($ENV{'PPENV'}) {
	$env_pack= $ENV{'PPENV'}; }
    else {			# this is used by the automatic version!
	$env_pack= "/home/phd/server/scr/envPackPP.pl"; } # HARD CODDED
    $Lok=
	require "$env_pack";
				# ******************************
    if (!$Lok){			# *** error in require
	$envPP{"pp_admin"}= "rost\@embl-heidelberg.de";
	if (-e "/usr/sbin/Mail" ){
	    $envPP{"exe_mail"}="/usr/sbin/Mail" ;}
	else {
	    $envPP{"exe_mail"}="/usr/bin/Mail" ;}
	$Date=localtime(time);
	return(0,"*** $scrName failed to require env_pack ($env_pack) err=101");}
				# ------------------------------
				# read local environment var
				# ------------------------------
    foreach $des ("dir_work","pp_emailPred","file_emailReqLog","file_procmailLog","lib_pp",
		  "pp_admin","exe_mail","dir_bup_errMail"){
	$envPP{"$des"}=&envPP'getLocal("$des");                      # e.e'
				# ******************************
	if (! $envPP{"$des"}){	# *** error in local env
	    if (! defined $envPP{"exe_mail"}){
		if (-e "/usr/sbin/Mail" ){$envPP{"exe_mail"}="/usr/sbin/Mail" ;}
		else                     {$envPP{"exe_mail"}="/usr/bin/Mail" ;}}
	    $Date=localtime(time);
	    return(0,"*** $scrName failed to get envPP{$des} from env_pack ($env_pack)"
		   ." err=102");}}
				# ------------------------------
				# include libraries
				# ------------------------------
    foreach $lib("lib_pp",
#		 "lib_ctime"
		 ){
	$tmpLib=$envPP{"$lib"};
	$Lok=require "$tmpLib";
				# ******************************
	if (!$Lok){		# *** error in require
	    $Date=localtime(time);
	    return(0,"*** $scrName failed to require lib $lib ($tmpLib)"." err=103");}}
				# ------------------------------
				# get the date
    @Date= split(' ',&ctime(time));
    shift (@Date); $Date = join(':',@Date);
    return(1,"ok");
}				# end of ini

#===============================================================================
sub ctrlAlarm {
    local ($message) = @_;
#----------------------------------------------------------------------
#   ctrlAlarm                   sends alarm mail to pp_admin
#       in:                     $message
#          GLOBAL               $envPP{"exe_mail"},$envPP{"ppAdmin"},
#                               $File_name,$User_name,$Origin,$Date,
#----------------------------------------------------------------------
    $header=   "\n              $Date";
#    $header .= "\n input file : $File_name";
#    $header .= "\n send by    : $User_name";
#    $header .= "\n origin     : $Origin";
    $message=  "$header" . "\n" . "$message\n";
    $exe_mail=$envPP{"exe_mail"}; $pp_admin=$envPP{"pp_admin"};
    $cmd="echo '$message' | $exe_mail -s PP_ERROR_PROCMAIL $pp_admin";
#    system("echo '$message' | $exe_mail -s PP_ERROR_PROCMAIL $pp_admin");
    system("$cmd");
}				# end of ctrlAlarm

