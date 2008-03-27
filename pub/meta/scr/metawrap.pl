#!/usr/local/bin/perl -w

# the MetaServer [w]rapper
# basic responsibilies
# 1. identify incoming messages (request/result)
# 2. update request logs
# 3. request: who requests? which service? input? (input validation is done in the handlers)
# 4. distribute to handlers
#
# ------------------------------
# comments
# 
#  - 'xx'         : to do, error break
#  - 'yy'         : to do at later stage
#  - 'HARD_CODED' : explicit names
#  - 'br date'    : changed on date
#  - 'hack'       : some hack 
#  - 
# 
#------------------------------------------------------------------------------#
#	Copyright				        	1999	       #
#	Volker Eyrich		eyrich@dodo.cpmc.columbia.edu		       #
#	CUBIC (Columbia Univ)	http://dodo.cpmc.columbia.edu/cubic/	       #
#       Dep Biochemistry & Molecular Biophysics				       #
#       630 West, 168 Street						       #
#	New York, NY 10032						       #
#				version 0.1   	May,    	1999	       #
#------------------------------------------------------------------------------#
#
# 


#$\ = "\n";

#$dbg = 1;
select(STDERR);

############################################################
# establish the correct output channels for messages and debug info
#

#open(MSG,"> msg.log");
#$msglogunit = MSG;
$msglogunit = STDERR; #default messagelog is STDERR (not buffered)

if(1) {
    $DBG="DBG";
    open($DBG,"> /dev/null");
    $dbglogunit=$DBG;
} else {
    $dbglogunit="STDERR"; #default debug log is STDERR
}
#
############################################################

############################################################
#  INITIALIZATION

				# ------------------------------
				# local parameter definition
require "/home/meta/server/scr/envMeta.pm";		# HARD_CODED

				# ------------------------------
				# define parameters
				# GLOBAL out:
				# %services_test{"cgi_".$name_of_service}
				# %services{$kwd."_".$name_of_service}, 
				#    with $kwd=<url|cgi|admin|quote>
				# @services= list of all services
				# %par{$kwd},
				#    with $kwd=<exe_*|lib_*|opt_*>
&iniEnv();


$Ltest=0;			# note: set to 0 for real runs!!
#$Ltest=1;			# note: set to 0 for real runs!!

&dbglog('IS TEST run!!') if ($Ltest);
     
#
############################################################

############################################################
#cache the message (and determine whether this is a request or a result)
#
#@msg=<STDIN>; #the quick way
@msg = ();
$lrequest=0;

while(<STDIN>) {
    $_=~s/^[\s\t]*|[\s\t]*$//g;
				# skip empty lines
    next if (! defined $_   ||
	     length($_) < 1 ||
	     $_=~/^[\n\t\s\.\-_=]*$/);
    push(@msg,$_);
    $lrequest=1
	if ($_ =~ /META-REQUEST/);
}

if ($lrequest) {
    &msglog('received meta-request');
    &handle_request(@msg);
}

else {
    &dbglog('received result from service'); 
}

############################################################

&msglog('METAWRAP EXIT');
exit(0);

#===============================================================================
sub abort {
    my   ($msg) = @_ ;
    $[ =1 ;
#-------------------------------------------------------------------------------
#   abort                       end program
#       in:                     $error_message
#-------------------------------------------------------------------------------
    &dbglog("abort: $msg");
				# yy send email to admin!
    die ("$msg");
}				# end of abort

#===============================================================================
sub dbglog {
#-------------------------------------------------------------------------------
#   msglog                      the debug message log
#       in:                     $message
#       in GLOBAL:              $dbglogunit (file handle to write message)
#-------------------------------------------------------------------------------
    $dbglogunit="STDOUT"        if (! defined $dbglogunit);
    print $dbglogunit "<DBG>",join(',',@_),"</DBG>\n";
#    print $dbglogunit "<DBG>",@_,"</DBG>\n";
}				# end of dbglog

#===============================================================================
sub msglog {
#-------------------------------------------------------------------------------
#   msglog                      the standard message log
#       in:                     $message
#-------------------------------------------------------------------------------
    print $msglogunit "<MSG>",join(',',@_),"</MSG>\n";
}				# end of msglog



