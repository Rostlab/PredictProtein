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
#			    br  v 2.2             Mar,          1999           #
#------------------------------------------------------------------------------#
#
# This script is called by the HTML PP_server.
# It reads the data from the HTML page and builds a prediction file.
# If a mail response is requested it just returns a message to html
# If an immediate response is requested, it waits for the result
# file and prints it back to html. If the prediction is too long,
# it automaticaly creates mail query file, and displays a message.
#
#------------------------------------------------------------------------------#
$[ =1 ;				# start counting at 1

				# --------------------------------------------------
				# initialise environment parameters
				# 
				# =====  ***************************************
				# NOTE:  also setting the keywords! 
				#        these MUST be identical to the WWW page
				#        for submission!!
				# =====  ***************************************
				# 
				# --------------------------------------------------
($Lok,$msg)=
    &ini();
				# ******************************
if (! $Lok) { $msgErr= "";	# *** error in local env
	      $msgErr.="*** err=11000\n"   if ($msg !~ /err\=/);
	      $msgErr.="*** ERROR $scrName: ini returned:\n".$msg;
	      &abortScript($msgErr."\n".
			   "Please contact: $ppAdmin with this error message!\n"); }
				# ******************************

				# --------------------------------------------------
				# initialise HTML keywords
				# 
				# =====  ***************************************
				# NOTE:  these MUST be identical to the WWW page
				#        for submission!!
				# =====  ***************************************
				# 
				# out GLOBAL
                                #   $IN_* ==> Input
				#   $TX_* ==> Textarea
				#   $SE_* ==> Select
				#   $CB_* ==> Checkbox 
				# form: $htmlDate{$keyword} will contain the data
				# 
				# --------------------------------------------------
&iniHtmlKeywords();


# --------------------------------------------------------------------------------
# process HTML data
# --------------------------------------------------------------------------------

				# --------------------------------------------------
				# Initialise HTML mode
				# --------------------------------------------------

				# ******************************
				# if the method is not POST exit
&abortScript("Invalid call (wrong CGI method), i.e. not POST")
    if (&MethGet());		# ******************************

				# --------------------------------------------------
				# read parameters in array %html_data
				# note: the input is '*main::html_data'
				#       data will be read from STDIN!
				# out:  %htmlDate{} -> keys are FORM keywords (see above)

%htmlData=&ReadParse();


				# ------------------------------
				# remove MACINTOSH end of lines
foreach $kwd (keys %htmlData) {	# 
    next if (! defined $kwd);
    next if (! defined $htmlDate{$kwd});
				# 1st MAC
    $htmlDate{$kwd}=~s/^M/\n/g;
				# 2nd double EOF
    $htmlDate{$kwd}=~s/\n\n+/\n/g;
}    
				# --------------------------------------------------
				# digest data from HTML and 
				#    test presence of mandatory parameters

				# usr related stuff
($Lok,$msg,$hdr_usr,$hdr_pwd)=
    &processHtmlUsr();          &abortScript($msg) if (! $Lok);

				# prediction options
($Lok,$msg,$hdr_prdType)=
    &processHtmlPrd();          &abortScript($msg) if (! $Lok);
                                # alignment options
($Lok,$msg,$hdr_aliType)=
    &processHtmlAli();          &abortScript($msg) if (! $Lok);

                                # alignment database
($Lok,$msg,$hdr_aliDb)=
    &processHtmlDb();           &abortScript($msg) if (! $Lok);

                                # other options
($Lok,$msg,$hdr_opt)=
    &processHtmlOpt();          &abortScript($msg) if (! $Lok);

                                # expert options
($Lok,$msg,$hdr_optExp)=
    &processHtmlOptExp();       &abortScript($msg) if (! $Lok);

                                # sequence description
				# note:  will be pasted at end of HASH line
($Lok,$msg,$hdr_seqDescr)=
    &processHtmlSeqDescr();     &abortScript($msg) if (! $Lok);

                                # sequence format
($Lok,$msg,$hdr_seqFormat,$demo)=
    &processHtmlSeqFormat();    &abortScript($msg) if (! $Lok);

				# --------------------------------------------------
				# HACK FOR DEMO (ADD 29.11.94)
if ($demo) {
    $demo= $envPP{"dir_demo"}.$demo.".pred";
    &abortScript("Sorry cannot find $demo") if (! -e $demo);
    ($Lok,$msg)=
	&doDemo($demo);         &abortScript($msg) if (! $Lok);
				# <--- <--- <--- <--- <--- <--- <--- <--- <--- <--- 
    exit(1);  }			# HAPPY END 
				# <--- <--- <--- <--- <--- <--- <--- <--- <--- <--- 

				# process sequence
($Lok,$msg,$sequence)=
    &processHtmlSequence();     &abortScript($msg) if (! $Lok);

				# response mode
($Lok,$msg,$hdr_respMode)=
    &processHtmlRespMode();     &abortScript($msg) if (! $Lok);

# --------------------------------------------------------------------------------
# build files for prediction (i.e. to exchange with the server run directory)
# OUT implicit write files:
#     $filePrd,$fileRes,$fileMail,$filePrdTmp
# --------------------------------------------------------------------------------
				# file names
$filePrd=    $envPP{"dir_prd"}  .       $envPP{"par_patDirPred"}."h".$$;
$fileRes=    $envPP{"dir_res"}  .       $envPP{"par_patDirPred"}."h".$$.$envPP{"suffix_res"};
$fileMail=   $envPP{"dir_mail"} .       $envPP{"par_patDirPred"}."h".$$.$envPP{"suffix_mail"};
$filePrdTmp= $envPP{"dir_prd"}  ."html".$envPP{"par_patDirPred"}."h".$$;

				# write files
($Lok,$msg)=
    &xchWrtFiles($filePrd,$fileRes,$fileMail,$filePrdTmp);          
                                &abortScript($msg) if (! $Lok);   

				# log of activity
system("echo `date` from $hdr_usr resp $hdr_respMode file $fileTmp >> $file_htmlReqLog");


				# --------------------------------------------------
				# if reponse mode is mail, send a message and exit
				# --------------------------------------------------
if ($hdr_respMode =~ /MAIL/) {
    $tmp= "Your query is being processed.\n\n";
    $tmp.="You will (hopefully) receive a mail response, as soon, as possible ".
	  "(check WAIT icon listed on previous page).\n\n";
    $tmp.="<UL><LI><B>Note</B>: ";
    $tmp.="waiting times of more than a day indicate errors in the system.\n";
    $tmp.="should that happen, please re-submit your query, or contact $ppAdmin\n";
    $tmp.="<LI>see the following table to check whether your information has been parsed correctly\n";
    $tmp.="</UL> ";
    $tmp.=" <HR> ";
    $tmp.="<TABLE CELLPADDING=2 BORDER=1> ";
    $lineBeg="<TR VALIGN=TOP> <TD WIDTH=100> ";
    $tmp.="";
    $tmp.=$lineBeg."<I>email address: </I>".     "<TD> <STRONG>$hdr_usr</STRONG>".    "</TR>";
    $tmp.=$lineBeg."<I>password: </I>".          "<TD> <STRONG>$hdr_pwd</STRONG>".    "</TR>"
	if ($hdr_pwd ne $envPP{"password_def"});
    $tmp.=$lineBeg."<I>prediction type: </I>".   "<TD> <STRONG>$hdr_prdType</STRONG>"."</TR>";
    $tmp.=$lineBeg."<I>alignment out: </I>".     "<TD> <STRONG>$hdr_aliType</STRONG>"."</TR>"
	if ($hdr_aliType);
    $tmp.=$lineBeg."<I>database to search: </I>"."<TD> <STRONG>$hdr_aliDb</STRONG>"."</TR>"
	if ($hdr_aliDb);
    $tmp.=$lineBeg."<I>options: </I>".           "<TD> <STRONG>$hdr_opt</STRONG>".    "</TR>"
	if ($hdr_opt);
    $tmp.=$lineBeg."<I>expert options: </I>".    "<TD> <STRONG>$hdr_optExp</STRONG>". "</TR>"
	if ($hdr_optExp);
    $tmp.=$lineBeg."<I>format of sequence: </I>"."<TD> <STRONG>$hdr_seqFormat</STRONG>". "</TR>";
    $tmp.=$lineBeg."<I>sequence: </I>".          "<TD> <STRONG><PRE>$sequence</PRE></STRONG>"   ."</TR>";
    $tmp.="</TABLE>\n";
				# announce meta
    ($Lok,$tmp_meta)=&buildMeta();	
    $tmp.=$tmp_meta             if ($Lok);
				# now write to screen
    ($Lok,$tmp)=
	&htmlPrintNormal($tmp,"STDOUT");
    exit(1); }

				# --------------------------------------------------
				# if reponse HTML: 
				#    wait until the result file becomes available
				#    if takes more then timeout, switch to email answer
				#       (mechanism, by creating a mail query file)
				# --------------------------------------------------
$startAt=    time;
$startSince= 0;

				# loop over waiting time
while (! -e $fileRes && ($startSince < $envPP{"ctrl_timeoutWeb"}) ) {
    sleep(2);
    $startSince= time - $startAt; }

				# --------------------------------------------------
				# Send the result to HTML Client (printing 
				#    prediction file) and remove the file
				# --------------------------------------------------
if (-e $fileRes) {
				# message before results
    $message= "<FONT SIZE=+1> <STRONG>";
    $message.="Note: since you requested the interactive mode, the results ";
    $message.="      will <FONT SIZE=+2>NOT </FONT> be mailed to you additionally!\n";
    $message.="      Thus, make sure you save the output in your browser...\n";
    $message.="</STRONG></FONT>\n";

    open (PRED, $fileRes);	# open result file : no warning if fails!

				# header 
    print &PrintHeader;
    if ($formatWant=~/^ASCII/i) {
	print "<PRE>";
	$LwrtMessage=1;}
    else {
	$LwrtMessage=0;}
	
				# read and mirror content of result file
    while (<PRED>) {
	$line=$_;
	if ($formatWant=~/^ASCII/i) {
	    $line=~ s/\*\*//g;
	    $line=~ s/^\*//;
	    $line=~ s/\*$//g; }
	if ($LwrtMessage) {
	    &htmlPrintNormal($message,"STDOUT");
	    $LwrtMessage=0;}

	print "$line";

	$LwrtMessage=1
	    if (! $LwrtMessage && $line=~/^<BODY>/i);
    }
	    
    print "</PRE>"              if ($formatWant=~/^ASCII/i);
    close(PRED);
    unlink($fileRes);		# delete result file
    exit(1); }

				# --------------------------------------------------
				# switch to BATCH, since time out
				# --------------------------------------------------
else {
    open (QUERY,">".$fileMail); # create a mail_query file
    print QUERY "from $hdr_usr\n";
    print QUERY "orig HTML\n";
    print QUERY "resp MAIL\n";
    close(QUERY);
                                # set access on the file
    system("chmod 666 $fileMail");
                                # display a message
    $tmp= "\n";
    $tmp.="Your query is being processed.\n";
    $tmp.="The sequence analysis has not finished before the time limit (5 min). ";
    $tmp.="Thus, we switched the processing mode from 'interactive' to 'email' response.\n";
    $tmp.="You will receive the prediction results by email, as soon as possible.\n";
    $tmp.="<P><HR><P>\n";
				# announce meta
    ($Lok,$tmp_meta)=&buildMeta();	
    $tmp.=$tmp_meta             if ($Lok);
				# now write to screen
    ($Lok,$tmp)=
	&htmlPrintNormal($tmp,"STDOUT");
    exit(1); }


exit(0);			# end with error, should have never come here!


# end of the script
#####################################################################

#==============================================================================
# library collected : cgi (begin)
#==============================================================================
# Perl Routines to Manipulate CGI input
# S.E.Brenner@bioc.cam.ac.uk
# $Header: /cys/people/seb1005/http/cgi-bin/RCS/cgi-lib.pl,v 1.6 1994/07/13 15:00:50 seb1005 Exp $
#
# Copyright 1994 Steven E. Brenner  

# MethGet
# Return true if this cgi call was using the GET request, false otherwise
# Now that cgi scripts can be put in the normal file space, it is useful
# to combine both the form and the script in one place with GET used to
# retrieve the form, and POST used to get the result.

sub MethGet {
    return ($ENV{'REQUEST_METHOD'} eq "GET") if (defined $ENV{'REQUEST_METHOD'});
    return (0,"*** env REQUEST_METHOD not defined!") ;
}

# ReadParse
# Reads in GET or POST data, converts it to unescaped text, and puts
# one key=value in each member of the list "@in"
# Also creates key/value pairs in %in, using '\0' to separate multiple
# selections

# If a variable-glob parameter (e.g., *cgi_input) is passed to ReadParse,
# information is stored there, rather than in $in, @in, and %in.

sub ReadParse {
#    local(*in)= @_ if (defined @_ && @_);
    local($i,$key,$val);
    $[ =1 ;			# start counting at 1

    # Read in text from STDIN into variable $in
    if ($ENV{'REQUEST_METHOD'} eq "GET") {
	$in = $ENV{'QUERY_STRING'};
    } elsif ($ENV{'REQUEST_METHOD'} eq "POST") {
	read(STDIN,$in,$ENV{'CONTENT_LENGTH'});
    }

				# different lines separated by '&'
				#    convert to array
    $#in=0;
    @in= split(/&/,$in);

    foreach $i (1 .. $#in) {
	# Convert plus-es to spaces
	$in[$i]=~ s/\+/ /g;

	# Split into key and value.  
	($key,$val)= split(/=/,$in[$i],2); # splits on the first =.

	# Convert %AA from hex numbers to alphanumeric
	$key=~ s/%(..)/pack("c",hex($1))/ge;
	$val=~ s/%(..)/pack("c",hex($1))/ge;

	# Associate key and value
	$in{$key}.= "\0"        if (defined($in{$key})); # \0 is the multiple separator
	$in{$key}=""            if (! defined $in{$key});
	$in{$key}.= $val;
    }

    return %in; # just for fun
}

# PrintHeader
# Returns the magic line which tells WWW that we're an HTML document

sub PrintHeader {
    return "Content-type: text/html\n\n";
}

#==============================================================================
# library collected (end)
#==============================================================================

#===============================================================================
sub ini {
    $[ =1 ;			# start counting at 1
#-------------------------------------------------------------------------------
#   ini                         gets the parameters from env, and checks
#-------------------------------------------------------------------------------
				# ------------------------------
				# get the name of this file
    $scrName=$0;$scrName=~s/^.*\/|\.pl//g;
				# --------------------------------------------------
				# include envPP package as define in $PPENV or default
    if ($ENV{'PPENV'}) {
	$env_pack = $ENV{'PPENV'}; }
    else {			# this is used by the automatic version!
	$env_pack = "/home/$ENV{USER}/server/scr/envPP.pm"; } # HARD CODDED

    $Lok=
	require $env_pack;
                    		# *** error in require env
    return(0,"*** ERROR $scrName: require env_pack=".$env_pack."\n".
	   "*** err=11001")      if (! $Lok);

				# ------------------------------
				# read local environment var
				# ------------------------------
    foreach $kwd (
				# note: br 99-03 now included in code
#		  "lib_cgi",	# cgi library (perl)
				# directories for exchanging files
		  "dir_prd","dir_res","dir_mail","dir_demo",
				# log files
		  "file_htmlReqLog","file_htmlFmtErr",
				# first characters for name of files deposited
				#    (read by scanner)
		  "par_patDirPred",
				# swissprot dir (current)
		  "dirSwissSplit",
				# extension of query and result file
		  "suffix_mail","suffix_res",
				# default password
		  "password_def",
				# default predictions
		  "para_defaultPrd",
				# time before timeout for interactive requests
		  "ctrl_timeoutWeb",
				# PP admin
		  "pp_admin",
				# meta submission HTML page
		  "fileHtmlMetaSubmit",

		  ) {
	$envPP{$kwd}=&envPP'getLocal($kwd);                      # e.e'
#	next if ($kwd=~/^para/);
				# *** error in local env
	return(0,"*** err=11002\n"."failed to get envPP{$kwd} from env_pack '$env_pack'\n") 
	    if (! defined $envPP{$kwd});
				# correct dir
	$envPP{$kwd}.="/"       if ($kwd =~/^dir/ && $envPP{$kwd} !~ /\/$/);
    }
				# ------------------------------
				# corrections to environment
				# ------------------------------
				# mail 
    $envPP{"pp_admin"}=		# HARD_CODED
	"rost\@embl-heidelberg.de" if (! defined $envPP{"pp_admin"});
	

				# ------------------------------
				# rename
    $file_htmlReqLog=$envPP{"file_htmlReqLog"};
    $ppAdmin=        $envPP{"pp_admin"}         if (defined $envPP{"pp_admin"} && 
						    $envPP{"pp_admin"});
    $ppAdmin=        "rost\@embl-heidelberg.de" if (! defined $ppAdmin);
    $ppAdmin=        "rost\@parrot.bioc.columbia.edu" if (! defined $ppAdmin);

# 				# --------------------------------------------------
# 				# correction Luca: 03-97, strange problems!
#                                 # get the html error format file
# $file_html_err_fmt=    &envPP'getLocal("file_htmlFmtErr"); # e.e'
# if(! -e $file_html_err_fmt){
#     print "content-type:text/html\n\nERROR: file_html_err_fmt not in envPP \n";
#     exit(1);}

				# --------------------------------------------------
				# include the cgi-lib (html communication)
				# --------------------------------------------------
#     $Lok=require($envPP{"lib_cgi"});
#     return(0,
# 	   "*** err=11003\n".
# 	   "failed to get envPP{lib_cgi}=".$envPP{"lib_cgi"}.", from env_pack=$env_pack!\n") 
# 	if (! $Lok);
    

				# ------------------------------
				# get the date
#    $Date=&sysDate();


    return(1,"ok");
}				# end of ini

#===============================================================================
sub iniHtmlKeywords {
    local($sbrName,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iniHtmlKeywords             assigns the default keywords to parse the WWW
#                               submission form
#       in GLOBAL:              all
#       out GLOBAL:             all
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":"; $sbrName=$tmp."iniHtmlKeywords";
    # --------------------------------------------------------------------------------
    # Define the html controls
    # 
    #   $IN ==> Input
    #   $TX ==> Textarea
    #   $SE ==> Select
    #   $CB ==> Checkbox 
    # 
    # =====  ***********************************************************
    # NOTE:  also setting the keywords! 
    #        these MUST be identical to the WWW page for submission!!
    #        
    # =====  ***********************************************************
    # 
    # --------------------------------------------------------------------------------


                                # --------------------
                                # textarea
    $IN_usr_email=        "usr-email";      # user identity
    $IN_usr_opt=          "usr-opt";	# options for experts
    $IN_usr_pwd=          "usr-pwd";	# password for commercial

                                # --------------------
				# select
                                # options for prediction and ouput
    $SE_opt_prd=          "opt-prd";	# which type of prediction?
    $SE_opt_ali=          "opt-ali";	# which ali to output?
    
				# --------------------
				# checkbox

				# to do=run options
    $CB_opt_aliNo=        "opt-no-ali";             # note: used to surpress aligning FASTA- or PIR-list
    $CB_opt_filAliNo=     "opt-no-fil-ali";         # do not filter the alignment returned
    $CB_opt_filPhdNo=     "opt-no-fil-phd";         # do not filter the alignment used for PHD

    $CB_opt_noCoils=      "opt-no-coils";
    $CB_opt_noProsite=    "opt-no-prosite";
    $CB_opt_noProdom=     "opt-no-prodom";
    $CB_opt_noSegNorm=    "opt-no-seg-norm";
    $CB_opt_noSegGlob=    "opt-no-seg-glob";

				# output options: ali
    $CB_opt_aliBlast=     "opt-ret-blast";          # also return the BLAST output
				# output options: phd
    $CB_opt_phdGraph=     "opt-ret-phd-graph";      # 
    $CB_opt_phdCol=       "opt-ret-phd-col";
    $CB_opt_phdMsf=       "opt-ret-phd-msf";
    $CB_opt_phdCasp2=     "opt-ret-phd-casp2";
    $CB_opt_phdRdb=       "opt-ret-phd-rdb";
				# output options: topits
    $CB_opt_topitsHssp=   "opt-ret-topits-hssp";
    $CB_opt_topitsStrip=  "opt-ret-topits-strip";
    $CB_opt_topitsOwn=    "opt-ret-topits-own";
				# output options: general
    $CB_opt_concise=      "opt-ret-concise";
				# output options: want HTML output
    $CB_opt_html=         "opt-ret-html";
    $CB_opt_htmlDetail=   "opt-ret-html-detail";
				# restrict characters per line (for printout)
    $CB_opt_html60=       "opt-ret-html60";
    $CB_opt_htmlDetail60= "opt-ret-html-detail60";
				# store results on public FTP site
    $CB_opt_store=        "opt-ret-store";

                                # --------------------
				# select database
    $SE_opt_db=           "opt-db";	# which database to use for alignment?
    
				# ------------------------------
				# expert options
    $CB_optExp_max=       "opt-exp-max";            # if on: read expert options
    $IN_optExp_maxIde=    "opt-exp-max-ide";        # min sequence identity   (0   <= IDE <= 100)
    $IN_optExp_maxGo=     "opt-exp-max-go";         # gap open penalty        (1   <= GO  <=  50)
    $IN_optExp_maxGe=     "opt-exp-max-ge";         # gap elongation penalty  (0.1 <= GE  <=  10)
    $IN_optExp_maxSmax=   "opt-exp-max-smax";       # max value of metric     (0.5 <= SMAX<=  50)
    $SE_optExp_maxMat=    "opt-exp-max-mat";        # comparison matrix       
    
    $CB_optExp_phdhtm=    "opt-exp-phdhtm";         # if on: read expert options
    $IN_optExp_phdhtmMin= "opt-exp-phdhtm-min";     # min HTM                 (0.0 <= MIN <=   1.0)

    $CB_optExp_topits=    "opt-exp-topits";         # if on: read expert options
    $IN_optExp_topitsMix= "opt-exp-topits-mix";     # mix str:seq             (0   <= MIX <= 100)
				                    #    (0-> only structure, 100-> only seq)
    $IN_optExp_topitsNhits="opt-exp-topits-nhits";  # number of hits returned (1   <= NHIT<=1000)
    $IN_optExp_topitsGo=  "opt-exp-topits-go";      # gap open penalty        (1   <= GO  <=  50)
    $IN_optExp_topitsGe=  "opt-exp-topits-ge";      # gap elongation penalty  (0.1 <= GE  <=  10)
    $IN_optExp_topitsSmax="opt-exp-topits-smax";    # maximal element in Mat  (0.1 <= SMAX<=  10)
    $SE_optExp_topitsMat= "opt-exp-topits-mat";     # comparison matrix

				# ------------------------------
                                # sequence
    $IN_seq_name=         "seq-name";	# name (one row)
				# --------------------
				# select
    $SE_seq_format=       "seq-format"; # format of seq (pp,msf,saf,pirlist,fastalist,col)
				# --------------------
				# textarea (10 rows)
    $TX_sequence=         "sequence"; 
                                # --------------------
				# select response mode (batch|interactive)
    $SE_resp_mode=        "resp-mode";

    # --------------------------------------------------------------------------------
    # 
    # end of defining the HTML control keywords!
    # 
    # --------------------------------------------------------------------------------

}				# end of iniHtmlKeywords

#===============================================================================
sub abortScript {
    local($errLoc) = @_ ;
    local($sbrName,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   abortScript                 send message to screen and exits
#       in:                     $msgLoc
#       out:                    NONE
#       err:                    NONE
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."abortScript";
    ($Lok,$tmp)=
	&htmlPrintNormal($errLoc,"STDOUT");

				# yy trap possible errors!

    exit(1);
}				# end of abortScript

#===============================================================================
sub buildMeta {
#    local($string) = @_ ;
#-------------------------------------------------------------------------------
#   buildMeta                   writes text and links to the META page
#       in GLOBAL:              $htmlData{}, in particular 'HTTP_REFERER'
#       in GLOBAL:              $envPP{"fileHtmlMetaSubmit"}
#       out:                    ($Lok,$string_writeout)
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------

				# ------------------------------
				# get site sending this
    $ref_page=         0;
    $meta_page=        0;
    $meta_page_origin= 0;
    $meta_page_origin_name=0;

    $meta_page_origin= $envPP{"fileHtmlMetaSubmit"} if (defined $envPP{"fileHtmlMetaSubmit"});
    $ref_page=         $ENV{'HTTP_REFERER'} if (defined $ENV{'HTTP_REFERER'});

				# respective meta page
    if ($ref_page) {
	$meta_page=$ref_page;
	$meta_page_origin_name=$meta_page_origin if (defined $meta_page_origin);
	if ($meta_page_origin_name){
	    $meta_page_origin_name=~s/^.*\///g;	# purge path
	} else {
	    $meta_page_origin_name="submit_meta.html";}
	$meta_page=~s/submit[A-Za-z\_\-0-9]*\.html.*$/$meta_page_origin/;
    }
				# ------------------------------
				# announce META
    $tmpLoc= "";
    $tmpLoc.="<P><HR><P>\n";
    $tmpLoc.="<FONT SIZE=\"+3\">Submission to META PP:</FONT>\n";
#    $tmpLoc.="<FONT SIZE=\"+1\">";
    $tmpLoc.="<UL>";
    $tmpLoc.="<LI>You may submit your sequence via a single-page interface to a";
    $tmpLoc.=" variety of other servers by using the META PP submission page.";
    if ($meta_page){
	$tmpLoc.="<LI>To access this page, click the following link:<BR>";
	$tmpLoc.=" <A HREF=\"$meta_page\">$meta_page<\/A> ";}
    else {
	$tmpLoc.="<LI>To access this page, go back to the previous page, or to the";
	$tmpLoc.=" PP home page, and select the META submission form.";}
    $tmpLoc.="</UL>\n";
#    $tmpLoc.="</FONT>\n";
    return(1,$tmpLoc);
}				# end of buildMeta

#===============================================================================
sub checkEmailAddress {
    local($userLoc) = @_ ;
    local($sbrName,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   checkEmailAddress            makes some simple checks on email address
#       in:                     $sender_name
#       out:                    (0,msg)
#                                 = 0            if not defined $userLoc
#                                 = 'strange'    if not 'name@machine.de'
#                               (1,$user_corrected)
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."checkEmailAddress";
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
    return(1,"rost\@parrot.bioc.columbia.edu") 
	if ($userLoc =~ /^rost.*parrot$/);
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
}				# end of checkEmailAddress

#===============================================================================
sub doDemo {
    local($demo) = @_ ;
    local($sbrName,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   doDemo                       
#       in:                     $demo=name of file with deme
#       in GLOBAL:              ALL others
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";$sbrName=$tmp."doDemo";

    open (PRED, "$demo");
    print &PrintHeader(); 
    print "<PRE>";
    while (<PRED>) {$_ =~ s/\*\*//g;
		    $_ =~ s/^\*//;
		    $_ =~ s/\*$//g;
		    print "$_";}
    print "</PRE>";
    close(PRED);
    
    return(1,"ok $sbrName");
}				# end of doDemo

#===============================================================================
sub htmlPrintNormal {
    local($lineInLoc,$fhOutLoc) = @_ ;
    local($sbrName,$tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   htmlPrintNormal                       
#       in:                     $txt          line to print
#       in:                     $fhOutLoc     file handle to write
#                                    default: STDOUT
#       out:                    implicit write
#       err:                    (1,$converted_text), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."htmlPrintNormal";
    return(0,"empty string")    if (! defined $lineInLoc);
    $fhOutLoc="STDOUT"          if (! defined $fhOutLoc);
    $lineInLoc=~s/\n/<BR>/g;
    $lineInLoc.="<BR>"          if ($lineInLoc !~ /<BR>$/); # add paragraph mark if missing

    print $fhOutLoc &PrintHeader,"\t",$lineInLoc;
    return(1,$lineInLoc);
}				# end of htmlPrintNormal

#===============================================================================
sub processHtmlUsr {
    local($sbrName,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   processHtmlUsr              process all user related data in $htmlData{}
#       in GLOBAL:              all
#       out:                    $hdr_usr, $hdr_pwd
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";$sbrName=$tmp."processHtmlUsr";

                                # ----------------------------------------
                                # User identity
    $hdr_usr=$hdr_pwd=0;
    if (defined $htmlData{$IN_usr_email}) {
	$hdr_usr= $htmlData{$IN_usr_email};
	$hdr_usr=~s/\s//g; }
				# password
    if (defined $htmlData{$IN_usr_pwd}) {
	$hdr_pwd= $htmlData{$IN_usr_pwd};  
	$hdr_pwd=~s/\s//g; }
    $hdr_pwd=$envPP{"password_def"} if (! $hdr_pwd);

				# check email address
    ($Lok,$msg)=
	&checkEmailAddress($hdr_usr) if ($hdr_usr);

				# ******************************
				# no email given
    return(0,"Your e-mail address is missing.",0,0)
	if ((! $Lok && ! $msg) || ! $hdr_usr);
				# ******************************
				# strange address
    return(0,"Please check your e-mail address: format seems invalid.\n".
	     "The address you gave was:\n".$hdr_usr."\n",0,0)
	if (! $Lok || ! $msg);
    
    $hdr_usr=$msg;		# replace user name
    return(1,"ok $sbrName",$hdr_usr,$hdr_pwd);
}				# end of processHtmlUsr

#===============================================================================
sub processHtmlPrd {
    local($sbrName,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   processHtmlPrd              process all user related data in $htmlData{}
#       in GLOBAL:              all
#       out:                    $hdr_prdType
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";$sbrName=$tmp."processHtmlPrd";

    $hdr_prdType=0;

				# ------------------------------
				# if usr options given
				# ------------------------------
    if (defined $htmlData{$SE_opt_prd}) {
	$tmp=        $htmlData{$SE_opt_prd};
				# default
	if ($tmp=~/ALL/) {
	    $tmp=$envPP{"para_defaultPrd"}; $tmp=~s/,/ /g;
	    $hdr_prdType="default prediction of: - ".$tmp; }
	else {
				# build up key
	    $hdr_prdType= "";
	    $hdr_prdType.="secondary structure   (PHDsec)-"  if ($tmp=~/secondary/);
	    $hdr_prdType.="solvent accessibility (PHDacc)-"  if ($tmp=~/access/);
	    $hdr_prdType.="transmembrane helices (PHDhtm)-"  if ($tmp=~/topology|membrane/);
	    $hdr_prdType.="threading             (TOPITS)-"  if ($tmp=~/threading/);
	    $hdr_prdType.="motif search          (PROSITE)-" if ($tmp=~/pros.* only/);
	    $hdr_prdType.="domain search         (ProDom)-"  if ($tmp=~/prodom.* only/);
	    $hdr_prdType.="coiled-coils          (COILS)-"   if ($tmp=~/coils only/);
	    $hdr_prdType ="eval of pred accuracy (EVALSEC)"  if ($tmp=~/eval.*acc/);}
				# use defaults
	if    (length($hdr_prdType) < 1) {
	    $tmp=$envPP{"para_defaultPrd"}; $tmp=~s/,/ /g;
	    $hdr_prdType="default prediction of: - ".$tmp; }
				# add sentence
	elsif ($hdr_prdType !~ /EVALSEC/i) {
	    $hdr_prdType="prediction of: - ".$hdr_prdType; } }
				# ------------------------------
				# if NOT defined: give defaults!!
				# ------------------------------
    else {
	$tmp=$envPP{"para_defaultPrd"}; $tmp=~s/,/ /g;
	$hdr_prdType="default prediction of: - ".$tmp; }
    return(1,"ok $sbrName",$hdr_prdType);
}				# end of processHtmlPrd

#===============================================================================
sub processHtmlAli {
    local($sbrName,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   processHtmlAli              process data about which ali to return in $htmlData{}
#       in GLOBAL:              all
#       out GLOBAL:             $hdr_aliType
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";$sbrName=$tmp."processHtmlAli";

    $hdr_aliType=0;
    if (defined $htmlData{$SE_opt_ali}) {
	$tmp= $htmlData{$SE_opt_ali};$tmp=~tr/A-Z/a-z/;
	if    ($tmp=~/no.ali/)          { $hdr_aliType=  "return no alignment"; }
	elsif ($tmp=~/msf/)             { $hdr_aliType=  "return msf format"; }
	elsif ($tmp=~/hssp.*pro/)       { $hdr_aliType=  "return hssp profile"; }
	elsif ($tmp=~/hssp/)            { $hdr_aliType=  "return hssp format"; } }

    return(1,"ok $sbrName",$hdr_aliType);
}				# end of processHtmlAli

#===============================================================================
sub processHtmlOpt {
    local($sbrName,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   processHtmlOpt              process all options in $htmlData{}
#       in GLOBAL:              all
#       out:                    $hdr_opt
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";$sbrName=$tmp."processHtmlOpt";

    $hdr_opt= "";

    $hdr_opt.="do not align\n"      if (defined $htmlData{$CB_opt_aliNo} && 
					$htmlData{$CB_opt_aliNo});
    $hdr_opt.="noFilterAli\n"       if (defined $htmlData{$CB_opt_filAliNo} && 
					$htmlData{$CB_opt_filAliNo});
    $hdr_opt.="noFilterPhd\n"       if (defined $htmlData{$CB_opt_filPhdNo} && 
					$htmlData{$CB_opt_filPhdNo});
    
    $hdr_opt.="ret no coils\n"      if (defined $htmlData{$CB_opt_noCoils} && 
					$htmlData{$CB_opt_noCoils});
    $hdr_opt.="ret no prosite\n"    if (defined $htmlData{$CB_opt_noProsite} && 
					$htmlData{$CB_opt_noProsite});
    $hdr_opt.="ret no prodom\n"     if (defined $htmlData{$CB_opt_noProdom} && 
					$htmlData{$CB_opt_noProdom});
    $hdr_opt.="ret no seg norm\n"   if (defined $htmlData{$CB_opt_noSegNorm} && 
					$htmlData{$CB_opt_noSegNorm});
    $hdr_opt.="ret no seg glob\n"   if (defined $htmlData{$CB_opt_noSegGlob} && 
					$htmlData{$CB_opt_noSegGlob});
    
    $hdr_opt.="ret blastp\n"        if (defined $htmlData{$CB_opt_aliBlast} && 
					$htmlData{$CB_opt_aliBlast});
    
    $hdr_opt.="ret graph\n"         if (defined $htmlData{$CB_opt_phdGraph} && 
					$htmlData{$CB_opt_phdGraph});
    $hdr_opt.="ret column format\n" if (defined $htmlData{$CB_opt_phdCol} && 
					$htmlData{$CB_opt_phdCol});
    $hdr_opt.="ret phd msf\n"       if (defined $htmlData{$CB_opt_phdMsf} && 
					$htmlData{$CB_opt_phdMsf});
    $hdr_opt.="ret phd casp2\n"     if (defined $htmlData{$CB_opt_phdCasp2} && 
					$htmlData{$CB_opt_phdCasp2});
    $hdr_opt.="ret phd rdb\n"       if (defined $htmlData{$CB_opt_phdRdb} && 
					$htmlData{$CB_opt_phdRdb});

    $hdr_opt.="ret topits hssp\n"   if (defined $htmlData{$CB_opt_topitsHssp} && 
					$htmlData{$CB_opt_topitsHssp});
    $hdr_opt.="ret topits strip\n"  if (defined $htmlData{$CB_opt_topitsStrip} && 
					$htmlData{$CB_opt_topitsStrip});
    $hdr_opt.="ret topits own\n"    if (defined $htmlData{$CB_opt_topitsOwn} && 
					$htmlData{$CB_opt_topitsOwn});
    
    $hdr_opt.="ret concise res\n"   if (defined $htmlData{$CB_opt_concise} && 
					$htmlData{$CB_opt_concise});

    $hdr_opt.="ret html\n"          if (defined $htmlData{$CB_opt_html} && 
					$htmlData{$CB_opt_html});
    $hdr_opt.="ret html detail\n"   if (defined $htmlData{$CB_opt_htmlDetail} && 
					$htmlData{$CB_opt_htmlDetail});

    $hdr_opt.="ret store\n"         if (defined $htmlData{$CB_opt_store} && 
					$htmlData{$CB_opt_store});
    $hdr_opt.="ret html perline=60\n"
                                    if (defined $htmlData{$CB_opt_html60} && 
					$htmlData{$CB_opt_html60});
    $hdr_opt.="ret html detail perline=60\n"        
                                    if (defined $htmlData{$CB_opt_htmlDetail60} && 
					$htmlData{$CB_opt_htmlDetail60});

    $formatWant="ASCII";
    $formatWant="HTML"              if ($hdr_opt=~/ret html/);

				# ------------------------------
				# no option given!
				# ------------------------------
    $hdr_opt=0                      if (length($hdr_opt)<2);

    return(1,"ok $sbrName",$hdr_opt);
}				# end of processHtmlOpt

#===============================================================================
sub processHtmlDb {
    local($sbrName,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   processHtmlDb               process data about which database to use for ali in $htmlData{}
#       in GLOBAL:              all
#       out GLOBAL:             $hdr_aliDb (=0 if no option selected!)
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";$sbrName=$tmp."processHtmlDb";

    $hdr_aliDb=0;

    if (defined $htmlData{$SE_opt_db}) {
	$tmp= $htmlData{$SE_opt_db};$tmp=~tr/A-Z/a-z/;
	if    ($tmp=~/pdb/ && $tmp=~/swiss/ &&
	       $tmp=~/trembl/)              { $hdr_aliDb=  "db=big"; }
	elsif ($tmp=~/pdb/)                 { $hdr_aliDb=  "db=pdb"; }
	elsif ($tmp=~/swiss/)               { $hdr_aliDb=  "db=swiss"; }
	elsif ($tmp=~/trembl/)              { $hdr_aliDb=  "db=trembl"; } }
    return(1,"ok $sbrName",$hdr_aliDb);
}				# end of processHtmlDb

#===============================================================================
sub processHtmlOptExp {
    local($sbrName,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   processHtmlOptExp           process all expert options in $htmlData{}
#       in GLOBAL:              all
#       out:                    $hdr_optExp
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";$sbrName=$tmp."processHtmlOptExp";

    $hdr_optExp=0;
				# MaxHom expert
    if (defined $htmlData{$CB_optExp_max}) {
	$build=&processHtmlOptExpMaxhom();
	$hdr_optExp=""              if (! $hdr_optExp && $build); 
	$hdr_optExp.=$build."\n"    if ($build); }

				# PHDhtm expert 
    if (defined $htmlData{$CB_optExp_phdhtm}) {
	$build=&processHtmlOptExpPhdhtm();
	$hdr_optExp=""              if (! $hdr_optExp && $build); 
	$hdr_optExp.=$build."\n"    if ($build); }

				# TOPITS expert
    if (defined $htmlData{$CB_optExp_topits}) {
	$build=&processHtmlOptExpTopits();
	$hdr_optExp=""              if (! $hdr_optExp && $build); 
	$hdr_optExp.=$build."\n"    if ($build); }

				# general, undocumented options...
    if (defined $htmlData{$IN_usr_opt}) {
	$build= $htmlData{$IN_usr_opt};   
	$build=~s/\s//g;
	$hdr_optExp=""              if (! $hdr_optExp && $build); 
	$hdr_optExp.=$build."\n"    if ($build); }

    return(1,"ok $sbrName",$hdr_optExp);
}				# end of processHtmlOptExp

#===============================================================================
sub processHtmlOptExpMaxhom {
    local($build);
#-------------------------------------------------------------------------------
#   processHtmlOptExpMaxhom     processes maxhom expert options
#       in GLOBAL:              $htmlData{}
#       out GLOBAL:             $build
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $build=     "expert maxhom ";
    if (defined $htmlData{$IN_optExp_maxIde}  && $htmlData{$IN_optExp_maxIde}) {
	$htmlData{$IN_optExp_maxIde}=~s/[^0-9\.]//g;
	$build.=" ide=". $htmlData{$IN_optExp_maxIde}; }
    if (defined $htmlData{$IN_optExp_maxGo}   && $htmlData{$IN_optExp_maxGo}) {
	$htmlData{$IN_optExp_maxGo}=~s/[^0-9\.]//g;
	$build.=" go=".  $htmlData{$IN_optExp_maxGo}; }
    if (defined $htmlData{$IN_optExp_maxGe}   && $htmlData{$IN_optExp_maxGe}) {
	$htmlData{$IN_optExp_maxGe}=~s/[^0-9\.]//g;
	$build.=" ge=".  $htmlData{$IN_optExp_maxGe}; }
    if (defined $htmlData{$IN_optExp_maxSmax} && $htmlData{$IN_optExp_maxSmax}) {
	$htmlData{$IN_optExp_maxSmax}=~s/[^0-9\.]//g;
	$build.=" smax=".$htmlData{$IN_optExp_maxSmax}; }
    if (defined $htmlData{$SE_optExp_maxMat}  && $htmlData{$SE_optExp_maxMat}) {
	$tmp=$htmlData{$SE_optExp_maxMat}; 
	$tmp=~tr/[A-Z]/[a-z]/;	# change case
	$mat=0;
	if    ($tmp=~/mclachlan/)     { $mat="McLachlan"; }
	elsif ($tmp=~/bloss?um/)      { $mat="Blosum"; }
	elsif ($tmp=~/gcg|gribskov/)  { $mat="GCG"; }
	$build.=" mat=".$mat    if ($mat); }

				# none found?
    $build=0                    if ($build=~/expert maxhom $/);

    return($build);
}				# end of processHtmlOptExpMaxhom

#===============================================================================
sub processHtmlOptExpPhdhtm {
    local($build);
#-------------------------------------------------------------------------------
#   processHtmlOptExpPhdhtm     processes phdhtm expert options
#       in GLOBAL:              $htmlData{}
#       out GLOBAL:             $build
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $build=     "expert phdhtm ";
    if (defined $htmlData{$IN_optExp_phdhtmMin}   && $htmlData{$IN_optExp_phdhtmMin}) {
	$htmlData{$IN_optExp_phdhtmMin}=~s/[^0-9\.]//g;
	$build.=" min=".  $htmlData{$IN_optExp_phdhtmMin}; }
				# none found?
    $build=0                    if ($build=~/expert phdhtm $/);

    return($build);
}				# end of processHtmlOptExpPhdhtm

#===============================================================================
sub processHtmlOptExpTopits {
    local($build);
#-------------------------------------------------------------------------------
#   processHtmlOptExpTopits     processes topits expert options
#       in GLOBAL:              $htmlData{}
#       out GLOBAL:             $build
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $build=     "expert topits ";
    if (defined $htmlData{$IN_optExp_topitsMix}   && $htmlData{$IN_optExp_topitsMix}) {
	$htmlData{$IN_optExp_topitsMix}=~s/[^0-9\.]//g;
	$build.=" mix=".  $htmlData{$IN_optExp_topitsMix}; 
    }
    if (defined $htmlData{$IN_optExp_topitsNhits} && $htmlData{$IN_optExp_topitsNhits}) {
	$htmlData{$IN_optExp_topitsNhits}=~s/[^0-9\.]//g;
	$build.=" nhits=".$htmlData{$IN_optExp_topitsNhits}; 
    }
    if (defined $htmlData{$IN_optExp_topitsGo}    && $htmlData{$IN_optExp_topitsGo}) {
	$htmlData{$IN_optExp_topitsGo}=~s/[^0-9\.]//g;
	$build.=" go=".   $htmlData{$IN_optExp_topitsGo}; 
    }
    if (defined $htmlData{$IN_optExp_topitsGe}    && $htmlData{$IN_optExp_topitsGe}) {
	$htmlData{$IN_optExp_topitsGe}=~s/[^0-9\.]//g;
	$build.=" ge=".   $htmlData{$IN_optExp_topitsGe}; 
    }
    if (defined $htmlData{$IN_optExp_topitsSmax}  && $htmlData{$IN_optExp_topitsSmax}) {
	$htmlData{$IN_optExp_topitsSmax}=~s/[^0-9\.]//g;
	$build.=" smax=". $htmlData{$IN_optExp_topitsSmax}; 
    }
    if (defined $htmlData{$SE_optExp_topitsMat}   && $htmlData{$SE_optExp_topitsMat}) {
	$tmp=$htmlData{$SE_optExp_maxMat}; 
	$tmp=~tr/[A-Z]/[a-z]/;	# change case
	$mat=0;
	if    ($tmp=~/mclachlan/)     { $mat="McLachlan"; }
	elsif ($tmp=~/bloss?um/)      { $mat="Blosum"; }
	elsif ($tmp=~/gcg|gribskov/)  { $mat="GCG"; }
	$build.=" mat=".$mat    if ($mat); 
    }
				# ------------------------------
				# none found?
    $build=0                    if ($build=~/expert topits $/);

    return($build);
}				# end of processHtmlOptExpTopits

#===============================================================================
sub processHtmlSeqDescr {
    local($sbrName,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   processHtmlSeqDescr         process sequence description in $htmlData{}
#                               note:  will be pasted at end of HASH line
#       in GLOBAL:              all
#       out:                    $hdr_seqDescr
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";$sbrName=$tmp."processHtmlSeqDescr";

    $hdr_seqDescr=0;
    $hdr_seqDescr=$htmlData{$IN_seq_name}
    if (defined $htmlData{$IN_seq_name} && $htmlData{$IN_seq_name});
	

    return(1,"ok $sbrName",$hdr_seqDescr);
}				# end of processHtmlSeqDescr

#===============================================================================
sub processHtmlSeqFormat {
    local($sbrName,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   processHtmlSeqFormat        process all user related data in $htmlData{}
#       in GLOBAL:              $hdr_seqDescr,$htmlData{}, ASF
#       out:                    $hdr_seqFormat,$demo
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";$sbrName=$tmp."processHtmlSeqFormat";

    $hdr_seqFormat=0;
    $Lnormal=0;
    $demo=0;
    if (defined $htmlData{$SE_seq_format}) {
	$tmp=            $htmlData{$SE_seq_format}; 
				# all to lower caps
	$tmp=~tr/[A-Z]/[a-z]/;
				# start with hash '#'
	$hdr_seqFormat=     "# ";

	if    ($tmp=~/saf-/)      { $hdr_seqFormat.=    "saf format"; }
	elsif ($tmp=~/msf-/)      { $hdr_seqFormat.=    "msf format"; }
	elsif ($tmp=~/fasta-/)    { $hdr_seqFormat.=    "fasta list"; }
	elsif ($tmp=~/pir-/)      { $hdr_seqFormat.=    "pir list"; }
	elsif ($tmp=~/column-/)   { $hdr_seqFormat.=    "col format"; } 
	elsif ($tmp=~/swissid/)   { $hdr_seqFormat.=    "swissid"; } 
				# demo
	elsif ($tmp=~/demo (\S+)/){ $demo=$1;}
				
				# is normal sequence:
				#    remove confusing statements here
	else                      { $hdr_seqDescr=~ s/(msf|saf|fasta|pir|column)\s//ig;
				    $hdr_seqDescr=~ s/^\s*list\s*//ig;
				    $hdr_seqFormat.=    "default: single protein sequence";
				    $Lnormal=1; }
				# add sequence description
	$hdr_seqFormat.= " description=".$hdr_seqDescr if ($hdr_seqDescr); }


    return(1,"ok $sbrName",$hdr_seqFormat,$demo);
}				# end of processHtmlSeqFormat

#===============================================================================
sub processHtmlSequence {
    local($sbrName,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   processHtmlSequence         process the sequence data in $htmlData{}
#       in GLOBAL:              all
#       out:                    $sequence
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";$sbrName=$tmp."processHtmlSequence";

                                # ----------------------------------------
                                # sequence present??
                                # ----------------------------------------
    return(0,"Your sequence appears missing!",0)
	if (! defined $htmlData{$TX_sequence} || ! $htmlData{$TX_sequence});

    $sequence= $htmlData{$TX_sequence};

				# ------------------------------
				# try to correct quickly
				# (e.g. delete HASH line)
				# ------------------------------
    $sequence=~s/^\n\s*\#[^\n]*\n/\n/g;

                                # ----------------------------------------
                                # check if the "# line was passed" 
				# OLD ==> error
                                #     Add by Antoine on Burkhard request: Jun 5 1995
				# NEW 99-03: simply correct it
                                # ----------------------------------------
#    if ($sequence =~ /^\s*\#/ || $sequence !~/[A-Za-z]+/) { 
# 	print &PrintHeader(); 
# 	open (ERR, $envPP{"file_htmlFmtErr"});
# 	print "<PRE>";
# 	while (<ERR>) {$_ =~ s/\*\*//g;
# 		       $_ =~ s/^\*//;
# 		       $_ =~ s/\*$//g;
# 		       print "$_";}
# 	print "</PRE>";
# 	close(ERR);
#       exit(1);}

				# ----------------------------------------
				# fill in SWISSPROT sequence if SWISSID
				# ----------------------------------------
    if ($hdr_seqFormat=~/swissid/) {
				# just get id
	$sequence=~s/^[^A-Za-z0-9]*([A-Za-z0-9\_]+)[^A-Za-z0-9]*$/$1/g;
	$sequence=~tr/[A-Z]/[a-z]/;

	return(0,"Your SWISSPROT identifier is too short",0)
	    if (length($sequence)<5);
	return(0,"Your SWISSPROT identifier has no '_' character in it\n".
	         "     note: should be of the form name_species",0)
	    if ($sequence !~/\_/);
				# --------------------
				# get directory
	$tmp= $sequence; $tmp=~s/^[^\_]*\_(.).*$/$1/g;
	$file=$envPP{"dirSwissSplit"}.$tmp."/".$sequence;

	return(0,"The SWISSPROT entry:<BR>"."<STRONG>$sequence</STRONG><BR>".
	         "is not in our current database.  Sorry!<BR>"."Please check spelling!",0)
	    if (! -e $file && ! -l $file);
				# --------------------
				# read sequence
	($Lok,$id,$seq)=
	    &swissRdSeq($file);
				# make nicer
	$seq=~s/([A-Z ]{50,}?)/$1\n/g;
	$hdr_seqFormat="# default: single protein sequence (from SWISSID $sequence)";
	$sequence=  $seq;  }

    return(1,"ok $sbrName",$sequence);
}				# end of processHtmlSequence

#===============================================================================
sub processHtmlRespMode {
    local($sbrName,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   processHtmlRespMode         process response mode <batch|interactive> from $htmlData{}
#       in GLOBAL:              all
#       out:                    $hdr_respMode
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";$sbrName=$tmp."processHtmlRespMode";

    $tmp= $htmlData{$SE_resp_mode};

				# changed BR 22-11-94
    $hdr_respMode= "HTML";
    $hdr_respMode= "MAIL"       if ( $tmp=~/batch/i);

    return(1,"ok $sbrName",$hdr_respMode);
}				# end of processHtmlRespMode

#===============================================================================
sub replaceMacParagraph {
    local($string) = @_ ;
#-------------------------------------------------------------------------------
#   replaceMacParagraph         removes the ^M character put there by MACs
#       in:                     $string
#       out:                    $string_corrected
#-------------------------------------------------------------------------------
    $string=~s/^M/\n/g;
    $string=~s/\n\n+/\n/g;
    return($string);
}				# end of replaceMacParagraph

#===============================================================================
sub swissRdSeq {
    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc,$msg,$Lok,$seq,$id);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   swissRdSeq                  reads the sequence from a SWISS-PROT file
#       in:                     file
#       out:                    (1,name,sequence in one string)
#-------------------------------------------------------------------------------
    $sbrName="swissRdSeq";$fhinLoc="FHIN"."$sbrName";

    $Lok=       open($fhinLoc,$fileInLoc) ||
	return(0,"*** ERROR opening file swissprot=$fileInLoc!","error");

    if (! $Lok){
	$msg="*** ERROR $sbrName: '$fileInLoc' not opened\n";
	return(0,$msg,"error");}
    $seq="";
    while (<$fhinLoc>) {
	$_=~s/\n//g;
	if ($_=~/^ID\s+(\S*)\s*.*$/){
	    $id=$1;}
	last if ($_=~/^\/\//);
	next if ($_=~/^[A-Z]/);
	$seq.=$_;}
    close($fhinLoc);

    $seq=~s/\s//g;
    return(1,$id,$seq);
}				# end of swissRdSeq

#===============================================================================
sub xchWrtFiles {
    local($filePrd,$fileRes,$fileMail,$filePrdTmp)=@_;
    local($sbrName,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   xchWrtFiles                 process data in $htmlData{}
#       in:                     names of files to write
#       in GLOBAL:              all others
#       out:                    implicit write files
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";$sbrName=$tmp."xchWrtFiles";

				# NOTE: keep syntax of header, checked by:
				#       scannerPP.pl:scannerPredict:fileExtractHeader
    $fhOut_topred="TOPRED";

    open ($fhOut_topred, ">".$filePrdTmp) ||
	do { 
	    $tmp="ERROR: The temporary file '$filePrd' could not be written!\n".
		"       this is OUR problem, please contact the PP administrator: $ppAdmin\n";
	    return(0,$tmp); };

				# header
    print $fhOut_topred "PPhdr from: $hdr_usr\n";
    print $fhOut_topred "PPhdr resp: $hdr_respMode\n";
    print $fhOut_topred "PPhdr orig: HTML\n";
    print $fhOut_topred "PPhdr want: $formatWant\n";
    print $fhOut_topred "PPhdr password($hdr_pwd)\n";
				# prediction type and options
    print $fhOut_topred "$hdr_prdType\n";
    print $fhOut_topred "$hdr_aliType\n"    if ($hdr_aliType);
    print $fhOut_topred "$hdr_aliDb\n"      if ($hdr_aliDb);
    print $fhOut_topred "$hdr_opt\n"        if ($hdr_opt);
    print $fhOut_topred "$hdr_optExp\n"     if ($hdr_optExp && length($hdr_optExp)>3);
				# format
    print $fhOut_topred "$hdr_seqFormat\n";
    print $fhOut_topred "$sequence\n";
    close($fhOut_topred);

                                # set access on the file
    system("chmod 666 $filePrdTmp");
                                # rename the file to the predict
    system("\\mv $filePrdTmp $filePrd");
                                # put a trace in the logfile
    $fileTmp= $filePrd;
    $fileTmp=~ s/^.*\///;	# purge dir

    return(1,"ok $sbrName");
}				# end of xchWrtFiles

