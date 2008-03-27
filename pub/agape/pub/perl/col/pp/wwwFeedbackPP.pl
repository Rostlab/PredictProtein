#!/usr/pub/bin/perl4
#------------------------------------------------------------------------------#
#	Copyright				 Dec,    	1994	       #
#	Burkhard Rost &		rost@EMBL-Heidelberg.DE			       #
#	Antoine de Daruvar	daruvar@lion-ag.de                             #
#	EMBL			http://www.embl-heidelberg.de/~rost/	       #
#	D-69012 Heidelberg						       #
#			    br  v 1.1             Sep,           1996          #
#			    br  v 1.2             Jan,           1998          #
#------------------------------------------------------------------------------#
#
# This script is call by the phd_server when a user want to send a feedback.
# It read the data from the html page and build a file.
# This file is then mailed to the administrator.
#
#----------------------------------------------------------------------#

#======================================================================
# Read environment parameters
#======================================================================

# include phd_env package as define in $PPENV or default
if ($ENV{'PPENV'}) {
    $env_pack = $ENV{'PPENV'}; }
else {$env_pack = "/home/phd/server/scr/envPackPP.pl"; } # HARD CODDED
    
require "$env_pack";

				# get the cgi-lib script
$cgi_lib=                &envPP'getLocal("lib_cgi"); #e.e'
if (!$cgi_lib)          {print "ERROR: cgi-lib not found in local env \n";
			 exit(1);}
				# get the dir_result
$dir_result=             &envPP'getLocal("dir_result");  #e.e'
if (!$dir_result)       {print "ERROR: dir_result not found in local env \n";
			 exit(1);}
				# get the Administrator address
$Admin=                  &envPP'getLocal("pp_admin");  #e.e'
if (!$Admin)            {print "ERROR: Admin address not found in local env \n";
			 exit(1);}
				# get the exe_mail
$exe_mail=               &envPP'getLocal("exe_mail"); #e.e'
if (!$exe_mail)         {print "ERROR: exe_mail not found in local env \n";
			 exit(1);}

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

				# user identity
$IN_usr_email  = "from";
$IN_usr_message= "message";

#======================================================================
# Initialise HTML mode
#======================================================================

if (&MethGet) {			# if the method is not POST exit
    print &PrintHeader, 'Invalid call (wrong method)';
    exit;}
else {				# read parameters in array %html_data
    &ReadParse(*html_data);}

#======================================================================
# Read data from html and test presence of mandatory parameters
#======================================================================
				# remove bad MAC ^M character
$usr= $html_data{$IN_usr_email};$usr=~s/\s//g;$usr=~s/
//g;

if (!$usr) {			# address is mandatory 
    print &PrintHeader;		# initialize output as html
    print "Your e-mail address appears missing (given=$usr).";
    exit(1);}
if ($usr !~ /\S+\@\S+\.\S+/) {	# make a basic address syntax control (one "@" and one ".")
    print &PrintHeader;		# initialize output as html
    print "Please check your e-mail address: format appears invalid (given=$usr).";
    exit(1);}
				# last part of the address must not be more than 4 char
if ($usr =~ /\S*\.(\S+)/ && length($1)>4){
    print &PrintHeader;	# initialize output as html
    print "Please check your e-mail address: format appears invalid (given=$usr).";
    exit(1);}

$message= $html_data{$IN_usr_message};
$message=~s/
/\n/g;		# replace bad MAC ^M character by a newline

#======================================================================
# build a file for mail
#======================================================================

$fileTo_mail= "$dir_result"; $fileTo_mail.="/" if ($fileTo_mail !~/\/$/);
$fileTo_mail.="message_".$$;

open   (TOMAIL, ">$fileTo_mail");
print   TOMAIL "from: $usr\n\n";
printf  TOMAIL "date: %s\n",`date`;
print   TOMAIL "$message\n";
close  (TOMAIL);

system "chmod 666 $fileTo_mail" if (-e $fileTo_mail); # set access on the file

#======================================================================
# Send the amil to the administrator and remove the file
#======================================================================
print &PrintHeader;		# hack 22-1-97 to avoid errors
print "\n";			# hack 22-1-97
if (-e $fileTo_mail){
    system "$exe_mail -s PP_FEEDBACK $Admin < $fileTo_mail";
    unlink ($fileTo_mail) ;
    print "Your message has been sent to the administrator of the Predictprotein server.";}
else {
    print "*** serious error during the attempt to save your request\n";
    print "*** Please, try again.\n";}
# end of the script
#####################################################################



