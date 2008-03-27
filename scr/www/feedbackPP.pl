#!/usr/local/bin/perl -w
##!/usr/pub/bin/perl5
##!/usr/local/bin/perl -w
##!/usr/pub/bin/perl5.003 -w
##!/usr/pub/bin/perl -w
#------------------------------------------------------------------------------#
#	Copyright				        	1999	       #
#	Burkhard Rost		rost@EMBL-Heidelberg.DE			       #
#	Wilckensstr. 15		http://www.embl-heidelberg.de/~rost/	       #
#	D-69120 Heidelberg						       #
#                                                                              #
#	Copyright				 Dec,    	1994	       #
#	Burkhard Rost &		rost@EMBL-Heidelberg.DE			       #
#	Antoine de Daruvar	daruvar@lion-ag.de                             #
#			    br  v 1.1             Sep,          1996           #
#			    br  v 1.2             Jan,          1998           #
#			    br  v 2.0   	  May,          1998           #
#			    br  v 2.1             Jan,          1999           #
#------------------------------------------------------------------------------#
#
# This script is call by the phd_server when a user want to send a feedback.
# It read the data from the html page and build a file.
# This file is then mailed to the administrator.
#
#------------------------------------------------------------------------------#

				# --------------------------------------------------
				# read environment parameters
				# --------------------------------------------------

				# include phd_env package as define in $PPENV or default
if ($ENV{'PPENV'}) {
    $env_pack = $ENV{'PPENV'}; }
else {
    $env_pack = "/home/$ENV{USER}/server/scr/envPP.pm"; } # HARD CODDED

require "$env_pack";

				# get the cgi-lib script
$cgi_lib=         &envPP'getLocal("lib_cgi"); #e.e'
if (!$cgi_lib)          {print "ERROR: cgi-lib not found in local env \n";
			 exit(1);}
				# get the dir_res
$dir_res=      &envPP'getLocal("dir_res");  #e.e'
if (!$dir_res)       {print "ERROR: dir_res not found in local env \n";
			 exit(1);}
				# get the Administrator address
$Admin=           &envPP'getLocal("pp_admin");  #e.e'
if (!$Admin)            {print "ERROR: Admin address not found in local env \n";
			 exit(1);}
				# get the exe_mail
$exe_mail=        &envPP'getLocal("exe_mail"); #e.e'
if (!$exe_mail)         {print "ERROR: exe_mail not found in local env \n";
			 exit(1);}

				# --------------------------------------------------
				# include the cgi-lib (html communication)
				# --------------------------------------------------
require "$cgi_lib";
				# --------------------------------------------------
				# Defines the html controls
				#   $IN ==> Input
				#   $TX ==> Textarea
				#   $SE ==> Select
				#   $CB ==> Checkbox 
				# --------------------------------------------------
				# user identity
$IN_usr_email  = "from";
$IN_usr_message= "message";

				# --------------------------------------------------
				# Initialise HTML mode
				# --------------------------------------------------

if (&MethGet()) {		# if the method is not POST exit
    print &PrintHeader(), 'Invalid call (wrong method)';
    exit;}
else {				# read parameters in array %html_data
    &ReadParse(*html_data);}

				# --------------------------------------------------
				# Read data from HTML and test presence of 
				#    mandatory parameters
				# --------------------------------------------------
$user= $html_data{$IN_usr_email};
$user=~ s/\s//g; 
$user=~ s///g;		# remove bad MAC ^M character

				# ------------------------------
				# check email address
($Lok,$msg)=
    &emailCheckSender($user);

if (! $Lok && ! $msg) {		# no email given
    print &PrintHeader();	# initialise output as html
    print "Your e-mail address is missing.";
    exit(1);}
if (! $Lok && ! $msg) {		# strange address
    print &PrintHeader();	# initialise output as html
    print "Please check your e-mail address: format is invalid.";
    exit(1);}

$user=$msg;			# replace user name

$message= $html_data{$IN_usr_message};

$message=~ s//\n/g;		# replace bad MAC ^M character by a newline

				# --------------------------------------------------
				# build a file for mail
				# --------------------------------------------------
$fileTo_mail= "$dir_res" . "/message_".$$;

open (TOMAIL, "> $fileTo_mail");
print TOMAIL "from: $user\n\n";
printf (TOMAIL "date: %s\n", `date`);
print TOMAIL "$message\n";
close(TOMAIL);

system "chmod 666 $fileTo_mail"; # set access on the file

				# --------------------------------------------------
				# Send a mail to the administrator and remove file
				# --------------------------------------------------
system "$exe_mail -s PP_FEEDBACK $Admin < $fileTo_mail";
system "\\rm $fileTo_mail";

print "Your message has been sent to the administrator of the Predictprotein server.<p><br>";

# end of the script
#####################################################################

#===============================================================================
sub emailCheckSender {
    local($userLoc) = @_ ;
    local($sbrName,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   emailCheckSender            makes some simple checks on email address
#       in:                     $sender_name
#       out:                    (0,msg)
#                                 = 0            if not defined $userLoc
#                                 = 'strange'    if not 'name@machine.de'
#                               (1,$user_corrected)
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."emailCheckSender";
				# ------------------------------
				# no argument passed
    return(0,0)                 if (! defined $userLoc || ! $userLoc);
				# ------------------------------
				# security: purge blanks
    $userLoc=~s/\s//g;
				# ------------------------------
				# is me?
    return(1,"rost\@columbia.edu") 
	if ($userLoc =~ /^rost$/ && $userLoc !~ /\@/);
				# ------------------------------
				# correct format?
				# ------------------------------
    return(0,"strange")         if ($userLoc !~ /\S+\@\S+\.\S\S+$/);
	
				# last part of the address must not be more than 4 char
    return(0,"strange")         if ($userLoc =~ /\S+\@\S+\.(\S\S+)$/ && length($1) > 4);
	
				# ------------------------------
				# correct (WATCH IT!!!!)
				# edu
    return(1,$1.".edu")         if ($userLoc =~ /(\S+\@\S+)\.(ed|eu|du)$/);
				# UK
    return(1,$1.".ac.uk")       if ($userLoc =~ /(\S+\@\S+)\.uk\.ac$/);
    
				# ------------------------------
				# assume: it is ok
    return(1,$userLoc);
}				# end of emailCheckSender


