#!/usr/local/bin/perl -w
##!/usr/pub/bin/perl5
##!/usr/pub/bin/perl5.003 -w
##!/usr/pub/bin/perl -w
#
#  
# 
#------------------------------------------------------------------------------#
#	Copyright				        	1999	       #
#	Burkhard Rost		rost@EMBL-Heidelberg.DE			       #
#	CUBIC (Columbia Univ)	http://www.embl-heidelberg.de/~rost/	       #
#       Dep Biochemistry & Molecular Biophysics				       #
#       630 West, 168 Street						       #
#	New York, NY 10032	http://www.dodo.cpmc.columbia.edu/~rost/       #
#				version 0.1   	May,    	1999	       #
#------------------------------------------------------------------------------#
#
#
# This script is called by the pp_server when a user sends an application for a
#    license.
# It reads the data from the HTML page.
# That data are then merged with the application form and mailed to PPadmin
#
#------------------------------------------------------------------------------#
$[ =1 ;				# start counting at 1

				# --------------------------------------------------
				# initialise environment parameters
				# --------------------------------------------------
($Lok,$msg)=
    &ini();
				# ******************************
if (! $Lok) { $msgErr= "";	# *** error in local env
	      $msgErr.="*** err=11000\n"   if ($msg !~ /err\=/);
	      $msgErr.="*** ERROR $scrName: ini returned:\n".$msg;}
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
				#   $RA_* ==> Radio
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
print &PrintHeader();
				# out:  %htmlDate{} -> keys are FORM keywords (see above)
%htmlData=&ReadParse();
				# ------------------------------
				# remove MACINTOSH end of lines
foreach $kwd (keys %htmlData) {	# 
				# 1st MAC
    $htmlDate{$kwd}=~s/^M/\n/g;
				# 2nd double EOF
    $htmlDate{$kwd}=~s/\n\n+/\n/g; }

				# --------------------------------------------------
				# digest data from HTML and 
				#    test presence of mandatory parameters
($Lok,$msg,$msgErr,$msgFail)=
    &processHtml();             &abortScript($msg) if (! $Lok);
				# some input missing
&abortScript($msgFail)          if (length($msgFail) > 1);

&htmlPrintNormal("--- problems with $0\n".$msgErr."\n",
		 "STDOUT")      if ($res{"email"}=~/^rost/ && length($msgErr) > 1);

				# ------------------------------
				# write output file
				# ------------------------------
($Lok,$msg,$fileTo_mail,$license_id)=
    &wrtFileToMail();
				# ------------------------------
				# add user to file checked by
				#     server
				# ------------------------------
$Lauto_add=0;
($Lok,$msg,$password)=
    &wrtLicenseGiven();         $Lauto_add=1 if ($Lok==1);

				# ------------------------------
				# write message to screen
				# ------------------------------
($Lok,$msg,$final)=
    &wrtFinalMessage();
($Lok,$tmp)=
    &htmlPrintNormal($final,"STDOUT");

				# ------------------------------
				# send mail
				# ------------------------------
$text_to_add= "password=$password license_number=$license_id";
$text_to_add.="     pay=".$res{"pay"}."<order|check> ";
$text_to_add.=" invoice=".$res{"invoice"}."<none|email|fax|mail> ";

$subj=        "PredictProtein_license";

foreach $usr ($envPP{"pp_admin"},$res{"email"}) {
    if ($usr eq $envPP{"pp_admin"}) {
	$subj.="_invoice=".$res{"invoice"} if (defined $res{"invoice"});
	$subj.="_pay=".    $res{"pay"}     if (defined $res{"pay"});
	$subj.="_no=".     $res{"number"}  if (defined $res{"number"});
	$text_to_add.=" email=".$res{"email"}; }
    if (-e $envPP{"exe_mailHtml"}){
	$cmd= $envPP{"exe_mailHtml"}." ".$fileTo_mail." ".$usr;
	$cmd.=" subj=$subj text='$text_to_add'"; }
    else {
	$cmd= $envPP{"exe_mail"}." ".$usr." -s $subj < ";
	$cmd.=" $text_to_add $fileTo_mail"; }
    system($cmd);
}

exit;
#print &PrintHeader(),"xx after given ($msg,$password,$fileTo_mail,$license_id)\n";exit;


#==============================================================================
# library collected : cgi (begin) lll
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

#===============================================================================
sub date_monthName2num {
    local($txtIn) = @_ ;
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   date_monthName2num          converts month name to number
#       in:                     $month
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."date_monthName2num";
    return(1,"ok","01") if ($txtIn=~/^jan/i);
    return(1,"ok","02") if ($txtIn=~/^feb/i);
    return(1,"ok","03") if ($txtIn=~/^mar/i);
    return(1,"ok","04") if ($txtIn=~/^apr/i);
    return(1,"ok","05") if ($txtIn=~/^may/i);
    return(1,"ok","06") if ($txtIn=~/^jun/i);
    return(1,"ok","07") if ($txtIn=~/^jul/i);
    return(1,"ok","08") if ($txtIn=~/^aug/i);
    return(1,"ok","09") if ($txtIn=~/^sep/i);
    return(1,"ok","10") if ($txtIn=~/^oct/i);
    return(1,"ok","11") if ($txtIn=~/^nov/i);
    return(1,"ok","12") if ($txtIn=~/^dec/i);
    return(0,"month=$txtIn, is what??",0);
}				# end  date_monthName2num

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

    print $fhOutLoc 
	"<HTML><HEAD><!--- ",
	&PrintHeader,
	" ---><\/HEAD><BODY style=\"background: white\">",
	$lineInLoc;
    return(1,$lineInLoc);
}				# end of htmlPrintNormal

#===============================================================================
sub ranGetString {
    local($seedLoc) = @_ ;
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   ranGetString                produces a random string (\w\d\d\d\w)
#       in:                     $seedLoc=       seed (may be anything if the
#                                               command srand() has been executed!)
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."ranGetString";

    $ranMaxNum=    10000;	# highest number to pick from
    $ranNumLet=    1;		# number of letters (before and after number

				# letters to use
    $ranLetters=   "abcdefghijklmnopqrstuvwxyz";
    @ranLetters=   split(//,$ranLetters);

    $ranMaxNumLet= length($ranLetters);

				# seed random
    srand(time|$$)
	if (!defined $seedLoc);

    $res="";
				# get some character string
    $tmp="";
    foreach $itl (1..$ranNumLet) {
	$poslet=int(rand($ranMaxNumLet))+1; # randomly select sample 
	next if (! defined $ranLetters[$poslet]);
	$let=$ranLetters[$poslet];
	$tmp.=$let;}
    $res.=$tmp;
				# get some number
    $num=int(rand($ranMaxNum))+1; # randomly select sample 
    if (length($num)>3) {
	$num=substr($num,1,3); }
    else {
	$num="0" x (3-length($num)).$num;}
    $res.="$num";

				# get some character string again
    $tmp="";
    foreach $itl (1..$ranNumLet) {
	$poslet=int(rand($ranMaxNumLet))+1; # randomly select sample 
	next if (! defined $ranLetters[$poslet]);
	$let=$ranLetters[$poslet];
	$tmp.=$let;}
    $res.=$tmp;

    return(1,$res);
}				# end of ranGetString

#===============================================================================
sub sysDate {
#    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   sysDate                     returns $Date
#       out:                    $Date (May 30, 1998 59:39:03)
#-------------------------------------------------------------------------------

    @tmp=(			# HARD_CODED
	  "/home/$ENV{USER}/server/scr/lib/",
	  "/home/$ENV{USER}/perl/"
	  );
    $exe_ctime="ctime.pl";	# local ctime library

    $Lok=0;
				# ------------------------------
				# get function
    if (defined &localtime) {
				# use system standard
	$Lok=1	                if (defined &ctime && &ctime);
				# use local library
	$Lok=1                  if (! $Lok && -e $exe_ctime);

	if (! $Lok) {		# search for it
	    foreach $tmp (@tmp){
		$exe_tmp=$tmp.$exe_ctime;
		if (-e $tmp){
		    $Lok=
			require("$exe_tmp");
		    last;}}}
				# ------------------------------
				# found one: use it
	if ($Lok && 
	    defined &ctime && &ctime && defined &localtime && &localtime){
#       	$date is e.g.:		Oct:14:13:06:47:1993
#       	@Date is e.g.:		Oct1413:06:471993
#        	&ctime(time) is e.g.:	Thu Oct 14 13:06:47 1993
	    @Date = split(' ',&ctime(time)) ; shift (@Date) ; 
	    $Date="$Date[2] $Date[3], $Date[$#Date]  $Date[4]";
	    return($Date);} }
				# ------------------------------
	 			# found none: take system
    if (! $Lok) {
	$localtime=`date`;
	@Date=split(/\s+/,$localtime);
	$Date="$Date[2] $Date[3], $Date[$#Date] $Date[4]"; }
    return($Date);
}				# end of sysDate

#==============================================================================
# library collected (end) lll
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
		  "dir_lic",
		  "pp_admin",
		  "exe_mail","exe_mailHtml",
		  "file_licence",
		  "file_htmlLicCond",
		  "file_licFlag","file_licNew",
		  "prefix_lic","pattern_lic",
		  ) {
	$envPP{$kwd}=&envPP::getLocal($kwd);
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
	"rost\@dodo.cpmc.columbia.edu" if (! defined $envPP{"pp_admin"});

				# ------------------------------
				# get the date
    $Date=&sysDate();
    $date=$Date; $date=~s/(1999|20\d\d).*$/$1/g;
    @tmp=split(/\s+/,$Date);
    $d=$tmp[2]; $d=~s/\D//g;
    $m=$tmp[1]; $m=~s/[^a-zA-Z]//g; 
    $y=$tmp[3]; $y=~s/\D//g;
    $m=&date_monthName2num($m); 
    $date_ymd=$y."_".$m."_".$d; 
    $date_dmy=$d."-".$m."-".substr($y,3);
    $date_month=$m;
    $date_year= $y;
    $date_day=  $d;
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
    #   $RA ==> Radio
    # 
    # =====  ***********************************************************
    # NOTE:  also setting the keywords! 
    #        these MUST be identical to the WWW page for submission!!
    #        
    # =====  ***********************************************************
    # 
    # --------------------------------------------------------------------------------

                                # who is it
    %IN=
	(
	 'name',    "name",
	 'email',   "email",
	 'company', "company",
	 'address', "address",
	 'phone',   "phone",
	 'fax',     "fax",
	 );
    %RA=
	(
	 'invoice', "invoice",
	 'number',  "number",
	 'pay',     "pay",
	 );
    %TX=
	(
	 'comments',"comments",
	 );

    @kwdUsr=
	(
	 "name","email",
	 "company","address",
	 "phone","fax"
	 );
    @kwdPay=
	(
	 "invoice",
	 "number",
	 "pay"
	 );
    @kwdMis=
	(
	 "comments"
	 );
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
				# add address
    $errLoc.="\n".
	"If you do not understand this message, feel free to contact: ".
	    "<A HREF=\"mailto:".$envPP{"pp_admin"}."\">".$envPP{"pp_admin"}."<\/A>".
		" with this error!\n";
	
    ($Lok,$tmp)=
	&htmlPrintNormal($errLoc,"STDOUT");
				# yy trap possible errors!
    exit(1);
}				# end of abortScript

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
    return(1,"rost\@columbia.edu") 
	if ($userLoc =~ /^rost$/ && $userLoc !~ /\@/);
    return(1,"rost\@columbia.edu") 
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
sub processHtml {
    local($sbrName,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   processHtml                 process all user related data in $htmlData{}
#       in GLOBAL:              all
#       out GLOBAL:             $res{}
#       out:                    $msgErr=  problems with script
#       out:                    $msgFail= failure if length($msgFail) > 0!
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";$sbrName=$tmp."processHtmlUsr";

				# set zero
    foreach $kwd (@kwdUsr) {
	$res{$kwd}=0; }
    $msgErr="";
				# ------------------------------
                                # User identity
    foreach $kwd (@kwdUsr) {
	if (! defined $IN{$kwd}) {
	    $msgErr.="*** ERROR missing tag for IN{$kwd}\n";
	    next; }
	$tag=$IN{$kwd};
	if (! defined $htmlData{$tag}) {
	    $msgErr.="-*- WARN  no info for kwd=$kwd (tag=$tag)\n";
	    next; }
	$res{$kwd}=$htmlData{$tag}; 
				# special : address '\n' -> '\t'
	$res{$kwd}=~s/\n/\t/g
	    if ($kwd eq "address");
	$res{$kwd}=~s/\s+/ /g;
	$res{$kwd}=~s/^[\s\t]*|[\s\t]$//g;
    }

				# --------------------------------------------------
				# check obligatory stuff
				# --------------------------------------------------
				# check email address
    ($Lok,$msg)=
	&checkEmailAddress($res{"email"});
    $msgFail="";
				# ******************************
				# email problem
    if    ((! $Lok && ! $msg) || ! $res{"email"}) {
	$msgFail.="Please fill in your e-mail address.";}
    elsif (! $Lok && ! $msg) {	# strange address
	$msgFail.=	
	    "Please check your e-mail address: format seems invalid.\n".
		"The address you gave was:\n".$res{"email"}."\n";}

				# others
    foreach $kwd ("company","address") {
	$msgFail.=
	    "Please fill in the field '$kwd'.\n".
		".. or contact ".$envPP{"pp_admin"}." if you did!\n"
		    if (! defined $res{$kwd} || ! $res{$kwd}); }

				# --------------------------------------------------
				# number of predictions
				# --------------------------------------------------
    foreach $kwd (@kwdPay) {
	if (! defined $RA{$kwd}) {
	    $msgErr.="*** ERROR missing tag for RA{$kwd}\n";
	    next; }
	$tag=$RA{$kwd};
	if (! defined $htmlData{$tag}) {
	    $msgErr.="-*- WARN  no info for kwd=$kwd, tag=$tag!\n"
		if ($kwd !~/name|phone|fax/);
	    next; }
	$res{$kwd}=$htmlData{$tag}; }
    $msgFail.=
	"Please check either 50 or 250 predictions!\n"
	    if (! defined $res{"number"});

    $res{"invoice"}=
	"none"
	    if (! defined $res{"invoice"});

    foreach $kwd (@kwdMis) {
	if (! defined $TX{$kwd}) {
	    $msgErr.="*** ERROR missing tag for RA{$kwd}\n";
	    next; }
	$tag=$TX{$kwd};
	if (! defined $htmlData{$tag}) {
	    $msgErr.="-*- WARN  no info for kwd=$kwd, tag=$tag!\n"
		if ($kwd !~/comments/);
	    next; }
	$res{$kwd}=$htmlData{$tag}; }

    return(1,"ok $sbrName",$msgErr,$msgFail);
}				# end of processHtml

#===============================================================================
sub wrtFileToMail {
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   wrtFileToMail                       
#       in GLOBAL:              all
#       out:                    (1|0,msg,file_name,license_number)  implicit: file
#       err:                    0,message,file_name -> error
#       err:                    1,'ok',file_name    -> ok
#       err:                    2,msg,0             -> output file not opened
#       err:                    3,msg,0             -> input file not opened
#       err:                    4,msg,0             -> input file missing
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."wrtFileToMail";
    $fhinLoc="FHIN_"."wrtFileToMail";$fhoutLoc="FHOUT_"."wrtFileToMail";

				# --------------------------------------------------
				# build up name of output file (to be mailed)
				# --------------------------------------------------
    $dir_lic="";
    $dir_lic=$envPP{"dir_lic"}      if (defined $envPP{"dir_lic"} && 
					-d $envPP{"dir_lic"});
    $dir_lic.="/"                   if (length($dir_lic)>1 && $dir_lic !~/\/$/);

    $num=1;
    $file=$dir_lic.$envPP{"prefix_lic"}.$date_year."_".$date_month."_".$num;
    while (-e $file) {
	++$num;
	$file=$dir_lic.$envPP{"prefix_lic"}.$date_year."_".$date_month."_".$num;
	if ($num==100) {
	    $file=$dir_lic.$envPP{"prefix_lic"}.$$;
	    last; }}
    $fileTo_mail=$file;
				# unique identifier for license
    $license_id=$fileTo_mail; 
    $license_id=~s/$dir_lic//g  if (length($dir_lic)>1);
    $license_id=~s/$envPP{"prefix_lic"}//g;
				# --------------------------------------------------
				# write file
				# --------------------------------------------------
    open ($fhoutLoc,">".$fileTo_mail) || 
	return(2,"*** $sbrName: failed opening output file ($fileTo_mail)",
	       $fileTo_mail,0);

				# ------------------------------
				# header info
				# ------------------------------
    print $fhoutLoc
	"<HTML>\n",
	"<HEADER>\n";
    foreach $kwd (@kwdUsr,@kwdPay,@kwdMis) {
	next if (! defined $res{$kwd});
	printf $fhoutLoc 
	    "%-s=%-s\n",
	    $envPP{"pattern_lic"}." ".$kwd,$res{$kwd};}
    print $fhoutLoc 
	$envPP{"pattern_lic"}." "."END</HEADER><BODY style=\"background:white\">";

    open ($fhinLoc,$envPP{"file_htmlLicCond"}) ||
	do { print $fhoutLoc "</BODY>\n","</HTML>\n";
	     close($fhoutLoc);
	     return(3,"*** $sbrName: failed opening input file (file_htmlLicOrd=".
		    $envPP{"file_htmlLicCond"}.")",0,0); };
				# ------------------------------
				# read and write
				# ------------------------------
    while (<$fhinLoc>) {
	$line=$_;
				# skip line if wrong number
	next if ($_=~/FILL_IN_NUMBER/ &&
		 $_!~/FILL_IN_NUMBER=\s*$res{"number"}/);
				# finding the region with the address
	if    ($_=~/FILL_IN_LICENSEE_([A-Z]+)/){
	    $kwd=$1; $kwd=~tr/[A-Z]/[a-z]/;
	    next if (! defined $res{$kwd});
	    $tmp=$res{$kwd};
	    $tmp=~s/\t/<BR>/g;
	    $line=~s/FILL_IN_LICENSEE_([A-Z]+)/$tmp/; }
				# finding the date part
	elsif ($_=~/FILL_IN_DATE/) {
	    $line=~s/FILL_IN_DATE/$date/;}
	print $fhoutLoc $line;
    }
    close($fhinLoc);
    close($fhoutLoc);
				# set access on the file
    if (-e $fileTo_mail) {
	system("chmod 666 $fileTo_mail");
	return(1,"ok $sbrName",$fileTo_mail,$license_id); }
    else {
	return(5,"no output file $fileTo_mail",0,$license_id);
    }
}				# end of wrtFileToMail

#===============================================================================
sub wrtLicenseGiven {
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   wrtLicenseGiven             add info to file checked by server
#       in GLOBAL:              all
#       out:                    (1|0,msg,password)  implicit: appended to file
#       err:                    (1,'ok'), (0,'message')
#       err:                    1,'ok',file_name    -> ok
#       err:                    2,msg,0             -> user_licence file not opened
#       err:                    3,msg,0             -> no automatic password!!!
#       err:                    4,msg,0             -> someone else is writing
#       err:                    5,msg,0             -> user_licence file not appended
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."wrtLicenseGiven";
    $fhinLoc= "FHIN_". "wrtLicenseGiven";
    $fhoutLoc="FHOUT_"."wrtLicenseGiven";
				# --------------------------------------------------
				# (1) read file checked by the server
    open($fhinLoc,$envPP{"file_licence"}) || 
	return(2,"*** failed reading file with licence details=".
	       $envPP{"file_licence"});
    undef %tmp;
    while(<$fhinLoc>){
	next if ($_=~/^\#/);
	$_=~s/[\s\t]+.*$//g;
	$_=~s/[\s\t]//g;
	next if (length($_)<1);
	$tmp{$_}=1; }
    close($fhinLoc);

				# --------------------------------------------------
				# (2) read new license file
    if (-e $envPP{"file_licNew"}) {
	open($fhinLoc,$envPP{"file_licNew"}) || 
	    return(2,"*** failed reading new file with licence details file_licNew=".
		   $envPP{"file_licNew"});
	while(<$fhinLoc>){
	    next if ($_=~/^\#/);
	    $_=~s/[\s\t]+.*$//g;
	    $_=~s/[\s\t]//g;
	    next if (length($_)<1);
	    $tmp{$_}=1; }
	close($fhinLoc);}

				# --------------------------------------------------
				# (3) new password
    ($Lok,$password)=
	&ranGetString(time);
    if (defined %tmp) {
	$ct=0;
	while (defined $tmp{$password}) {
	    ($Lok,$password)=&ranGetString(time);
	    ++$ct;
	    if ($ct > 10) {	# avoid endless
		$password="error_in_password_generation";
		return(3,"*** error in password generation!",$password);
	    }}}
				# --------------------------------------------------
				# (4) append to file checked by the server
    $file_licFlag=$envPP{"file_licFlag"};
    $file_licFlag="tmp_writing_license.flag" 
	if (length($file_licFlag)<1 || -d $file_licFlag);
    $ct=0;
    while (-e $file_licFlag) {
	sleep(5);
	++$ct;
	last if ($ct > 10);}
    unlink($file_licFlag)       if (-e $file_licFlag);
    system("echo 'is writing' > $file_licFlag");
	
    open($fhoutLoc,">>".$envPP{"file_licNew"}) || 
	return(5,"*** failed appending file with licence details=".
	       $envPP{"file_licNew"},$password);

				# build up info
    $beg=$date_dmy;		# begin of license
    $m=$date_month;
    $m=~s/^0//g; $m+=13; 
    $y=$date_year;
				# watch date
    if ($m > 12) {
	++$y; 
	$m=$m-12;
	$m="0".$m if ($m < 10);}
				# end of license
    $end="01"."-".$m."-".substr($y,3);
    $num=$res{"number"};	# number of predictions
    $txt= $res{"company"}." (email=".$res{"email"};


    foreach $kwd (@kwdUsr) {
	next if ($kwd =~/company|email/);
	next if (! defined $res{$kwd});
	next if (length($res{$kwd})<2);
	next if ($res{$kwd}=~/^\s*\n*$/);
	$tmp=$res{$kwd}; $tmp=~s/\t/ /g; $tmp=~s/\s+/\s/; $tmp=~s/\n//g;
	$txt.=" $kwd=".$tmp;
    }
    $txt.=")";
    print $fhoutLoc
	$password,"\t",$res{"number"},"\t",$beg,"\t",$end,"\t",$txt,"\n";
    close($fhoutLoc);
    system("chmod 666 ".$envPP{"file_licNew"}) if (-e $envPP{"file_licNew"});
				# delete flag!
    unlink($file_licFlag) if (-e $file_licFlag);
    return(1,"ok $sbrName",$password);
}				# end of wrtLicenseGiven

#===============================================================================
sub wrtFinalMessage {
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   wrtFinalMessage                       
#       in GLOBAL:              all
#       out:                    1|0,msg,formatted_message
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."wrtFinalMessage";
				# general info
    $tmp= "";
    $tmp.="<H1><I>Thank you for your order<\/I><\/H1>";
    $tmp.="<P><BR><P>";
    $tmp.="<H2>Your PredictProtein Password is ".$password."<\/H2>";
    $tmp.="<UL>";
    $tmp.="<LI>please use this password when requesting predictions.";
    $tmp.="<\/UL>";
    $tmp.="<P><BR><P>";
    $tmp.="<H2>Your PredictProtein Order \# is ".$license_id."<\/H2>";
    $tmp.="<UL>";
    $tmp.="<LI>Please make sure you include this number in all your inquiries regarding your order.\n";
    $tmp.="<LI>Make checks and Purchase Orders payable to:";
    $tmp.="<I><P>";
    $tmp.="    <BR>Dep of Biochemistry (and Molecular Biophysics)";
    $tmp.="    <BR>Columbia University, New York City";
    $tmp.="<P><\/I>";
    $tmp.="<LI>Bank information:";
    $tmp.="    <BR>First Union National Bank";
    $tmp.="    <BR>PO Box 7618, PA4822";
    $tmp.="    <BR>Philadelphia, PA 19101-7618";
    $tmp.="    <BR>ABA Routing: ACH#: 031000503 (Clearing House)";
    $tmp.="    <BR>Account (checking): 01295058";
    $tmp.="    <BR>Account title: The Trustees of COLUMBIA UNIVERSITY";
    $tmp.="    <BR>Information needed: Burkhard Rost (PredictProtein) account 0-19719";
    $tmp.="    <P>";
    $tmp.="<LI>.. and send checks to:";
    $tmp.="<I><P>";
    $tmp.="    <BR>PredictProtein Licensing";
    $tmp.="    <BR>Dep of Biochemistry and Molecular Biophysics (Rm 211)";
    $tmp.="    <BR>Columbia University (Box 36)";
    $tmp.="    <BR>630 West, 168th Street";
    $tmp.="    <BR>New York, N.Y. 10032";
    $tmp.="    <BR>U.S.A.";
    $tmp.="<P><\/I>";
    $tmp.="<LI>You may also fax your Purchase Order to +1 (212) 305-7932 ";
    $tmp.="<LI>If you have questions concerning your order you may call +1 (212) 305-3773";
    $tmp.="<LI>.. or write email to <A HREF=\"mailto:".
	$envPP{"pp_admin"}."\">".$envPP{"pp_admin"}."<\/A>";
    $tmp.="<\/UL>";
    $tmp.="<P><BR><P>";
    $tmp.="<HR>";
    $tmp.="<P><BR><P>";
    $tmp.="<UL>";
    $tmp.="<LI>You will (hopefully) receive an email confirming your request";
    $tmp.="<LI>PLEASE contact the PredictProtein administrator (<A HREF=\"mailto:".
	$envPP{"pp_admin"}."\">".$envPP{"pp_admin"}."<\/A><BR>".
	    " <STRONG>if you do NOT receive that email <\/STRONG>".
		"(this indicates that something went wrong)!";
    $tmp.="<\/UL>";
    
				# their info
    $tmp.="<P><HR><BR>";
    $tmp.="The information provided by you has been interpreted as:";
    $tmp.="<TABLE CELLPADDING=2 BORDER=1> ";
    $lineBeg="<TR VALIGN=TOP> <TD WIDTH=100> ";
    $tmp.="";
    foreach $kwd (@kwdUsr,@kwdPay,@kwdMis) {
	next if (! defined $res{$kwd});
	next if ($res{$kwd}=~/^\s*\n*$/);
	next if (length($res{$kwd})<2);
	$tmp.=$lineBeg."<I>$kwd<\/I></TD>"."<TD><STRONG>".$res{$kwd}."<\/STRONG><\/TD><\/TR>";
    }
    $tmp.="</TABLE>";
				# append license agreement
    if (-e $fileTo_mail) {
	$tmp.="<P><HR><BR>";
	$tmp.="For your information, you signed the following license agreement:";
	$tmp.="<P>";
	open("FHIN",$fileTo_mail);
	while(<FHIN>) {
	    next if ($_=~/<HTML>/);
	    next if ($_=~/<BODY>/);
	    next if ($_=~/^HEADER/);
	    $_=~s/\n//g;
	    $tmp.=$_; 
	}
	close(FHIN);}
    
    return(1,"ok $sbrName",$tmp);
}				# end of wrtFinalMessage

