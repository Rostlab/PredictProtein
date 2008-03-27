#!/usr/pub/bin/perl4
#----------------------------------------------------------------------
#------------------------------------------------------------------------------#
#	Copyright				 Dec,    	1994	       #
#	Burkhard Rost &		rost@EMBL-Heidelberg.DE			       #
#	Antoine de Daruvar	daruvar@lion-ag.de                             #
#	EMBL			http://www.embl-heidelberg.de/~rost/	       #
#	D-69012 Heidelberg						       #
#			    br  v 1.1             Aug,           1995          #
#			    br  v 1.2             Jan,           1996          #
#			    br  v 1.5             Jun,           1997          #
#			    br  v 2.0a   	  Apr,           1998          #
#------------------------------------------------------------------------------#
# This script is call by the phd_server when a user want to send 
# an application for a licence.
# It read the data from the html page.
# those data are then merge with the application form
# and mail to the administrator.
#----------------------------------------------------------------------#


#======================================================================
# Read environment parameters
#======================================================================
				# include phd_env package as define in $PPENV or default
if ($ENV{'PPENV'}) {
    $env_pack= $ENV{'PPENV'}; }
else {
    $env_pack= "/home/phd/server/scr/envPackPP.pl"; } # HARD CODDED

require "$env_pack";
				# get the cgi-lib script
$cgi_lib=          &envPP'getLocal("lib_cgi");  #e.e'
if (!$cgi_lib) {
    print "content-type:text/html\n\n","ERROR: cgi-lib not found in local env\n";
    exit(1);}
				# get the dir_result
$dir_result=       &envPP'getLocal("dir_result");  #e.e'
if (!$dir_result) {
    print "content-type:text/html\n\n","ERROR: dir_result not found in local env \n";
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
$file_htmlLicOrd=&envPP'getLocal("file_htmlLicOrd");  #e.e'
if (! -e $file_htmlLicOrd) {
    print "content-type:text/html\n\n","ERROR: file_htmlLicOrd not found in local env \n";
    exit(1); }

#======================================================================
# include the cgi-lib (html communication)
#======================================================================

require "$cgi_lib";

#======================================================================
# Defines the html controls
#   $IN ==> Input
#   $TX ==> Textarea
#   $SE ==> Select
#   $CB ==> Checkbox
#======================================================================

$TX_company=      "Company";
$IN_usr_email=    "email-address";
$IN_date=         "date";
$IN_signature=    "signature";
$SE_nwant=        "Nprediction";

#======================================================================
# Initialise HTML mode
#======================================================================

if (&MethGet) {			# if the method is not POST exit
    print &PrintHeader, 'Invalid call (wrong method)';
    exit(1);}
else {				# read parameters in array %html_data
    &ReadParse(*html_data);}

#======================================================================
# Read data from html and test presence of mandatory parameters
#======================================================================

$user= "$html_data{$IN_usr_email}";
$user=~ s/\s//g; 
$user=~ s/
//g;
if (!$user) {			# address is mandatory 
    print &PrintHeader;		# initialize output as html
    print "Your e-mail address is missing. \n";
    exit(1);}
if ($user !~ /\S+\@\S+\.\S+/) {	# make a basic address syntax control (one "@" and one ".")
    print &PrintHeader;		# initialize output as html
    print "Please check your e-mail address: format is invalid. \n";
    exit(1);}
                                # ---------------------------------------- 
if ($user =~ /\S*\.(\S+)/) {	# last part of the address must not be more than 4 char
    if (length($1) > 4) {
	print &PrintHeader;	# initialize output as HTML
	print "Please check your e-mail address: format appears invalid. \n";
	exit(1);}}
				# Company
$company= "$html_data{$TX_company}";
$company=~ s/
/\n/g;
				# Nb of predictions
$nwant =  "$html_data{$SE_nprediction}";
if ($nwant =~ /250/) {
    $nwant = "250";}
else {
    $nwant = " 50";}
				# date an signature
$date=       "$html_data{$IN_date}";
$date=~      s/
//g;
$signature=  "$html_data{$IN_signature}";
$signature=~ s/
//g;

#======================================================================
# build the application file 
#======================================================================

$fileTo_mail= "$dir_result" . "/message_".$$;
$fileTo_mail= "$dir_result" . "/message_22197";

open (TOMAIL,    ">$fileTo_mail");
open (ORDERFORM, "<$file_htmlLicOrd");
$copy=0;
while (<ORDERFORM>) {
				# finding the region with the address
    if ($_=~/\<PRE\>/)      {$copy=1;next; }
    if ($_=~/\<\/PRE\>/)    {$copy=0;next; }
    next if (!$copy);
				# find company name
    if   ($_=~/Company/)    {print TOMAIL "$_","$company\n";
			     next; }
    elsif($_=~/e-mail/)     {chop;$_=~s/\s*$//;
			     print TOMAIL "$_: $user\n";
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

#======================================================================
# Send the mail to the administrator and remove the file
#======================================================================

system "$exe_mail -s PP_LICENCE_ORDER $Admin < $fileTo_mail";
system "\\rm $fileTo_mail";

print 
    "content-type:text/html\n\n",
    "Your order has been sent to the administrator of the Predictrotein server.<p><br>";
exit;

# end of the script
#####################################################################



