#!/usr/pub/bin/perl
#
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
#
# This script is call by the html phd_server.
# It reads the data from the html page and builds a prediction file.
# If a mail response is requested it just returns a message to html
# If an immediate response is requested, it waits for the result
# file and prints it back to html. If the prediction is too long,
# it automaticaly creates mail query file, and displays a message.
#
#----------------------------------------------------------------------

#======================================================================
# Read environment parameters
#======================================================================

# include phd_env package as define in $PPENV or default
if ($ENV{'PPENV'}) {
    $env_pack = $ENV{'PPENV'};}
else {
    $env_pack = "/home/phd/server/scr/envPackPP.pl"; } # HARD CODED

require "$env_pack";
                                # get the cgi-lib script
$cgi_lib=              &envPP'getLocal("lib_cgi"); # e.e'
if (!$cgi_lib)       { print "content-type:text/html\n\nERROR: cgi-lib not in envPP \n";
		       exit(1);}
                                # get the dir_predict
$dir_predict=          &envPP'getLocal("dir_predict"); # e.e'
if (!$dir_predict)   { print "content-type:text/html\n\nERROR: dir_predict not in envPP \n";
		       exit(1);}
                                # get the pattern of the file in dir_predict
foreach $kwd ("par_patDirPred"){
    $envPP{"$kwd"}=    &envPP'getLocal("$kwd"); # e.e'
}
                                # get the dir_result
$dir_result=           &envPP'getLocal("dir_result"); # e.e'
if (!$dir_result)    { print "content-type:text/html\n\nERROR: dir_result not in envPP \n";
		       exit(1);}
                                # get the dir_mail
$dir_mail=             &envPP'getLocal("dir_mail"); # e.e'
if (!$dir_mail)      { print "content-type:text/html\n\nERROR: dir_mail not in envPP\n";
		       exit(1);}
                                # get the html log file
$file_htmlReqLog=      &envPP'getLocal("file_htmlReqLog"); # e.e'
if (!$file_htmlReqLog){print "content-type:text/html\n\nERROR: html_srv_log not in envPP \n";
		       exit(1);}
                                # get the html timeout
$timeout_html=         &envPP'getLocal("timeout_html"); # e.e'
if (!$timeout_html)  { print "content-type:text/html\n\nERROR: html timeout not in envPP \n";
		       exit(1);}
				# ==================================================
				# correction Luca: 03-97, strange problems!
                                # get the html error format file
$file_html_err_fmt=    &envPP'getLocal("file_htmlFmtErr"); # e.e'
$file_html_err_fmt=    "/home/phd/ut/txt/appWrgFormatHtml";
if(! -e $file_html_err_fmt){
    print "content-type:text/html\n\nERROR: file_html_err_fmt not in envPP \n";
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
                                # --------------------
                                # textarea
$IN_usr_email=      "usr-email"; # user identity
$IN_usr_opt=        "usr-opt";	# options for experts
$IN_usr_pwd=        "usr-pwd";	# password for commercial
#$TX_usr_addr=       "usr-addr";	# commented out 20.1.97 (not processed)
                                # options for prediction and ouput

                                # --------------------
				# select
$SE_opt_pred=       "opt-pred";	# which type of prediction?
$SE_opt_ali=        "opt-ali";	# which ali to output?

                                # --------------------
				# checkbox
$CB_opt_aliBlast=   "opt-ret-blastp";
$CB_opt_phdGraph=   "opt-ret-phd-graph";
$CB_opt_phdCol=     "opt-ret-phd-col";
$CB_opt_phdMsf=     "opt-ret-phd-msf";
$CB_opt_phdCasp2=   "opt-ret-phd-casp2";
$CB_opt_phdRdb=     "opt-ret-phd-rdb";
$CB_opt_topitsHssp= "opt-ret-topits-hssp";
$CB_opt_topitsStrip="opt-ret-topits-strip";
$CB_opt_topitsOwn=  "opt-ret-topits-own";
$CB_opt_noCoils=    "opt-ret-no-coils";
$CB_opt_noProsite=  "opt-ret-no-prosite";
$CB_opt_noProdom=   "opt-ret-no-prodom";
$CB_opt_concise=    "opt-ret-concise";
				# ------------------------------
                                # sequence
$IN_seq_name=       "seq-name";	# name (one row)
				# --------------------
				# select
$SE_seq_format=     "seq-format"; # format of seq (pp,msf,saf,pirlist,fastalist,col)
				# --------------------
				# textarea (10 rows)
$TX_sequence=       "sequence"; 
                                # --------------------
				# select
                                # --------------------------------------------------
$SE_resp_mode=      "resp-mode"; # response mode (batch|interactive)
                                # --------------------------------------------------

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
                                # ----------------------------------------
                                # User identity
$usr= $html_data{$IN_usr_email};$usr=~s/\s//g;$usr=~s/
//g;
$pwd= $html_data{$IN_usr_pwd};  $pwd=~s/\s//g;$pwd=~s/
//g;

# print &PrintHeader, 'sorry I am still trying to make PP run.... burkhard ';exit;  #xxx

$usr.="\@embl-heidelberg.de" if (defined $usr && ($usr eq "rost" || $usr eq "vriend"));
                                # ----------------------------------------
if (!$usr) {			# address is mandatory 
    print &PrintHeader; 
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
                                # ----------------------------------------
                                # address (for what ???)
#$Title = $html_data{$TX_addr};
                                # ----------------------------------------
                                # prediction options
                                # ----------------------------------------
$optExp= $html_data{$IN_usr_opt};   $optExp=~s/\s//g;$opt=~s/
//g;

$_ =  $html_data{$SE_opt_pred};
$prediction= "prediction of: -";

if ($_=~/secondary/)                {$prediction.="secondary structure   (PHDsec)-"; }
if ($_=~/access|solvent acc/)       {$prediction.="solvent accessibility (PHDacc)-"; }
#if ($_=~/default/)                  {$prediction.="transmembrane helices (PHDhtm)-"; }
if ($_=~/topology|membrane/)        {$prediction.="transmembrane helices (PHDhtm)-"; }
if ($_=~/threading/)                {$prediction.="threading             (TOPITS)-"; }
if ($_=~/pros.* only/)              {$prediction.="motif search          (PROSITE)=";}
if ($_=~/prodom.* only/)            {$prediction.="domain search         (ProDom)=";}
if ($_=~/coils only/)               {$prediction.="coiled-coils          (COILS)=";}
if ($_=~/eval.*acc/)                {$prediction ="evaluation of prediction accuracy (EVALSEC)-"; }
                                # ----------------------------------------
                                # alignment options
                                # ----------------------------------------
$_= $html_data{$SE_opt_ali};$_=~tr/A-Z/a-z/;
if    ($_=~/no.ali/)                {$alignment=  "return no alignment"; }
elsif ($_=~/msf/)                   {$alignment=  "return msf format"; }
elsif ($_=~/hssp.*pro/)             {$alignment=  "return hssp profile"; }
elsif ($_=~/hssp/)                  {$alignment=  "return hssp format"; }
                                # ----------------------------------------
                                # other options
                                # ----------------------------------------
$options="";
if ($html_data{$CB_opt_aliBlast})   {$options.=   "return blastp\n "; }
if ($html_data{$CB_opt_phdGraph})   {$options.=   "return graph\n "; }
if ($html_data{$CB_opt_phdCol})     {$options.=   "return column format\n "; }
if ($html_data{$CB_opt_phdMsf})     {$options.=   "return phd msf\n ";}
if ($html_data{$CB_opt_phdCasp2})   {$options.=   "return phd casp2\n ";}
if ($html_data{$CB_opt_phdRdb})     {$options.=   "return phd rdb\n ";}
if ($html_data{$CB_opt_topitsHssp}) {$options.=   "return topits hssp\n ";}
if ($html_data{$CB_opt_topitsStrip}){$options.=   "return topits strip\n ";}
if ($html_data{$CB_opt_topitsOwn})  {$options.=   "return topits own\n ";}
if ($html_data{$CB_opt_noCoils})    {$options.=   "return no coils\n ";}
if ($html_data{$CB_opt_noProsite})  {$options.=   "return no prosite\n ";}
if ($html_data{$CB_opt_noProdom})   {$options.=   "return no prodom\n ";}
if ($html_data{$CB_opt_concise})    {$options.=   "return concise result\n ";}
                                # ----------------------------------------
                                # sequence description
                                # ----------------------------------------
if (!$html_data{$IN_seq_name})      {$description="no description"; }
else                                {$description=$html_data{$IN_seq_name};
				     $description=~ s/
/\n/g; }
                                # ----------------------------------------
                                # sequence format
                                # ----------------------------------------
$_ = $html_data{$SE_seq_format}; $_=~tr/[A-Z]/[a-z]/;
$format= "# ";
if    ($_=~/saf-/)                  {$format.=    "saf format"; }
elsif ($_=~/msf-/)                  {$format.=    "msf format"; }
elsif ($_=~/fasta-/)                {$format.=    "fasta list"; }
elsif ($_=~/pir-/)                  {$format.=    "pir list"; }
elsif ($_=~/column-/)               {$format.=    "col format"; }
else {				# append seq description to # 
				# (after removing possible unwanted keyword)
    $description=~ s/[Mm][Ss][Ff]//g;
    $description=~ s/[Pp][Ii][Rr].+[Ll][Ii][Ss][Tt]//g;
    $format.= $description;
				# ##############################
				# HACK FOR DEMO (ADD 29.11.94)
    if ($description=~ m/[Dd][Ee][Mm][Oo] \S/){
        $demo= $description;
        $demo=~ s/.*[Dd][Ee][Mm][Oo] (\S*).*/$1/;
        $demo= "/home/phd/server/demo/$demo" . ".pred";
        if (! -e $demo) {print &PrintHeader; 
			 print "Sorry cannot find $demo\n";
			 exit; }
        open (PRED, "$demo");
	print &PrintHeader; 
        print "<PRE>";
        while (<PRED>) {$_ =~ s/\*\*//g;
			$_ =~ s/^\*//;
			$_ =~ s/\*$//g;
			print "$_";}
        print "</PRE>";
        close(PRED);
        exit(1)	; }		# END OF HACK FOR DEMO
}				# ##############################

                                # ----------------------------------------
                                # sequence
                                # ----------------------------------------
if (!$html_data{$TX_sequence}) {print &PrintHeader; 
				print "Your sequence appears missing!";
				exit(1);}

$sequence= $html_data{$TX_sequence};
$sequence=~ s/
/\n/g;
                                # ----------------------------------------
                                # check if the "# line was past" ==> error
                                # Add by Antoine on Burkhard request: Jun 5 1995
                                # ----------------------------------------
if ($sequence =~ /^\s*\#/) {
    print &PrintHeader; 
    open (ERR, "$file_html_err_fmt");
    print "<PRE>";
    while (<ERR>) {$_=~s/\*\*//g;
		   $_=~s/^\*//;
		   $_=~s/\*$//g;
		   print "$_";}
    print "</PRE>";close(ERR);
    exit(1);}
                                # ----------------------------------------
                                # response mode
                                # ----------------------------------------
$_= $html_data{$SE_resp_mode};
				# changed BR 22-11-94
if ( $_=~/batch/) { $resp_mode= "MAIL"; }
else              { $resp_mode= "HTML"; }

#======================================================================
# build a file for prediction
#======================================================================

$fileTo_pred=      $dir_predict . "/".       $envPP{"par_patDirPred"}."h".$$;
$file_result=      $dir_result  . "/".       $envPP{"par_patDirPred"}."h".$$."_done";
$fileMail_query=   $dir_mail    . "/".       $envPP{"par_patDirPred"}."h".$$."_query";
$fileTo_pred_tmp=  $dir_predict . "/"."html".$envPP{"par_patDirPred"}."h".$$;

open (TOPRED, "> $fileTo_pred_tmp");
print TOPRED "from $usr\n";
print TOPRED "password($pwd)\n";
print TOPRED "resp $resp_mode\n";
print TOPRED "orig HTML\n";
print TOPRED "$prediction\n";
print TOPRED "$optExp\n"         if (length($optExp)>3);
print TOPRED "$alignment\n"      if ($alignment);
print TOPRED "$options\n"        if ($options);
print TOPRED "$format\n";
print TOPRED "$sequence\n";
close(TOPRED);

                                # set access on the file
system("chmod 666 $fileTo_pred_tmp");
                                # rename the file to the predict
system("mv $fileTo_pred_tmp $fileTo_pred");
                                # put a trace in the logfile
$fileTmp= $fileTo_pred;
$fileTmp=~ s/^.*\///;
system("echo `date` from $usr resp $resp_mode file $fileTmp >> $file_htmlReqLog");

#======================================================================
# if reponse mode is mail, send a message and exit
#======================================================================
if ($resp_mode =~ /MAIL/) {
    print &PrintHeader;
    print "Your query is being processed.<P>";
    print "You will receive a mail response, as soon, as possible (check WAIT icon).";
    exit(1); }

#======================================================================
# if reponse is html, wait until the result file become available
# If if takes more then timeout, just switch to email answer
# mechanism, by creating a mail query file
#======================================================================

$startAt=    time;
$startSince= 0;

while (! -e $file_result && ($startSince < $timeout_html) ) {
    sleep(2);
    $startSince= time - $startAt; }
print &PrintHeader;		# hack 22-1-97 to avoid errors
print "\n";			# hack 22-1-97

#======================================================================
# Send the result to HTML Client (printing prediction file)
# and remove the file
#======================================================================
if (-e $file_result) {
    open (PRED, "$file_result");
    print "<PRE>";
    while (<PRED>) {$_ =~ s/\*\*//g;
		    $_ =~ s/^\*//;
		    $_ =~ s/\*$//g;
		    print "$_";}
    print "</PRE>";
    close(PRED);
    unlink($file_result); }
else {
    open (QUERY,">$fileMail_query"); # create a mail_query file
    print QUERY "from $usr\n";
    print QUERY "orig HTML\n";
    print QUERY "resp MAIL\n";
    close(QUERY);
                                # set access on the file
    system("chmod 666 $fileMail_query");
                                # display a message
    print " Your query is being processed.<P>";
    print " The prediction has not been finished before the timeout. ",
          " Thus, we switched the processing mode from 'interactive'",
          " to 'email' response.  <P>";
    print " You will receive the prediction results by e-mail as soon as possible.";
}

# end of the script
#####################################################################
