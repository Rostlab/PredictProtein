#!/usr/local/bin/perl -w
##!/usr/pub/bin/perl5
##!/usr/pub/bin/perl5.003 -w
##!/usr/pub/bin/perl -w
#
#------------------------------------------------------------------------------#
#	Copyright				        	1999	       #
#	Burkhard Rost		rost@EMBL-Heidelberg.DE			       #
#	Wilckensstr. 15		http://www.embl-heidelberg.de/~rost/	       #
#	D-69120 Heidelberg						       #
#                                                                              #
#	Copyright				 Dec,    	1994	       #
#	Burkhard Rost &		rost@EMBL-Heidelberg.DE			       #
#	Antoine de Daruvar	daruvar@lion-ag.de                             #
#			    br  v 1.1             Aug,          1995           #
#			    br  v 1.2             Jan,          1996           #
#			    br  v 1.5             Jun,          1997           #
#			    br  v 2.0   	  May,          1998           #
#			    br  v 2.1             Jan,          1999           #
#------------------------------------------------------------------------------#
#
# This script is called by the pp_server when a user sends an application for a
#    license.
# It reads the data from the HTML page.
# That data are then merged with the application form and mailed to PPadmin
#
#------------------------------------------------------------------------------#

				# --------------------------------------------------
				# read environment parameters
				# --------------------------------------------------
				# include phd_env package as define in $PPENV or default
if ($ENV{'PPENV'}) {
    $env_pack= $ENV{'PPENV'}; }
else {
    $env_pack= "/home/$ENV{USER}/server/scr/envPP.pm"; } # HARD CODDED

require "$env_pack";
				# get the cgi-lib script
$cgi_lib=          &envPP'getLocal("lib_cgi");  #e.e'
if (!$cgi_lib) {
    print "content-type:text/html\n\n","ERROR: cgi-lib not found in local env\n";
    exit(1);}
				# get the dir_res
$dir_res=       &envPP'getLocal("dir_res");  #e.e'
if (!$dir_res) {
    print "content-type:text/html\n\n","ERROR: dir_res not found in local env \n";
    exit(1);}
				# get the Administrator address
$Admin=            &envPP'getLocal("pp_admin");  #e.e'
if (!$Admin) {
    print "content-type:text/html\n\n","ERROR: Admin address not found in local env \n";
    exit(1);}
				# get the exe_mail
$exe_mail=         &envPP'getLocal("exe_mail");  #e.e'
if (!$exe_mail) {
    print "content-type:text/html\n\n","ERROR: exe_mail not found in local env \n";
    exit(1); }
				# get the html application form file
$file_htmlLicOrd=  &envPP'getLocal("file_htmlLicOrd");  #e.e'
if (! -e $file_htmlLicOrd) {
    print "content-type:text/html\n\n","ERROR: file_htmlLicOrd not found in local env \n";
    exit(1); }

				# --------------------------------------------------
				# include the cgi-lib (html communication)
				# --------------------------------------------------
require "$cgi_lib";
				# --------------------------------------------------
				# Define the html controls
				#   $IN ==> Input
				#   $TX ==> Textarea
				#   $SE ==> Select
				#   $CB ==> Checkbox 
				# --------------------------------------------------
$TX_company=      "Company";
$IN_usr_email=    "email-address";
$IN_date=         "date";
$IN_signature=    "signature";
$SE_nwant=        "Nprediction";

				# --------------------------------------------------
				# Initialise HTML mode
				# --------------------------------------------------

if (&MethGet()) {		# if the method is not POST exit
    print &PrintHeader(), 'Invalid call (wrong method)';
    exit(1);}
else {				# read parameters in array %html_data
    &ReadParse(*html_data);}

				# --------------------------------------------------
				# Read data from HTML and 
				#    test presence of mandatory parameters
				# --------------------------------------------------
$usr= $html_data{$IN_usr_email};
$usr=~s/\s//g; 
$usr=~s///g;			# remove bad MAC ^M character


				# ------------------------------
				# check email address
($Lok,$msg)=
    &emailCheckSender($usr);

if (! $Lok && ! $msg) {		# no email given
    print &PrintHeader();	# initialise output as html
    print "Your e-mail address is missing.";
    exit(1);}
if (! $Lok && ! $msg) {		# strange address
    print &PrintHeader();	# initialise output as html
    print "Please check your e-mail address: format is invalid.";
    exit(1);}

$usr=$msg;			# replace user name

				# ------------------------------
				# Company
$company= $html_data{$TX_company};
$company=~ s//\n/g;		# remove bad MAC ^M character

				# ------------------------------
				# number of predictions
$nwant =  $html_data{$SE_nwant};
$nwant = " 50";			# default = 50 predictions
$nwant = "250"                  if ($nwant =~ /250/);
    
				# ------------------------------
				# date an signature
$date=       $html_data{$IN_date};
$date=~      s///g;		# remove bad MAC ^M character
$signature=  $html_data{$IN_signature};
$signature=~ s///g;		# remove bad MAC ^M character

#======================================================================
# build the application file 
#======================================================================

$fileTo_mail= $dir_res . "/message_".$$;

open (TOMAIL,    ">$fileTo_mail");
open (ORDERFORM, "<$file_htmlLicOrd");
$copy=0;
while (<ORDERFORM>) {
				# finding the region with the address
    if ($_=~/\<PRE\>/)      {$copy=1; next; }
    if ($_=~/\<\/PRE\>/)    {$copy=0; next; }
    next if (!$copy);
				# find company name
    if   ($_=~/Company/)    {print TOMAIL "$_","$company\n";
			     next; }
    elsif($_=~/e-mail/)     {chop;$_=~s/\s*$//;
			     print TOMAIL "$_: $usr\n";
			     next; }
    elsif($_=~/$nwant pred/){$_=~s/\|  \|/\|XX\|/;
			     print TOMAIL "$_";
			     next; }
    elsif($_=~/_______/)     {$date .= "                                                       ";
			      $date= substr($date,0,50) . "$signature";
			      print TOMAIL "$date\n","$_";
			      next; }
    print TOMAIL "$_";
}
close(ORDERFORM);
close(TOMAIL);
				# set access on the file
system "chmod 666 $fileTo_mail";

				# --------------------------------------------------
				# Send mail to PPadmin and remove file
				# --------------------------------------------------

system "$exe_mail -s PP_LICENCE_ORDER $Admin < $fileTo_mail";
system "\\rm $fileTo_mail";

print 
    "content-type:text/html\n\n",
    "Your order has been sent to the administrator of the Predictrotein server.<p><br>";
exit;

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
    return(1,"rost\@embl-heidelberg.de") 
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


