#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="fills in URL asf for files 'submit_meta.html' and 'explain_meta.html'";
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

$[ =1 ;

$Ldebug=  0;
$Lverb=   0;
$#methods=0;			# just to avoid warnings...
$fileRdb= "template_methods.rdb";
				# keywords expected in file template_methods.rdb
@kwd_methods=
    ("about",
     "how_use",
     "options");

				# ------------------------------
if ($#ARGV<1){			# help
    print  "goal: $scrGoal\n";
    print  "use:  $0 template_file.html\n";
    print  " or:  $0 template_*.html\n";
    print  "note 1: nedss envMeta.pm to set parameters!\n";
    print  "note 2: the new version also NEEDS a local version of the file template_methods.rdb\n";
    print  "        if not local, provide location by 'rdb=whatever_your_file_is_called'\n";
    print  "opt:  \n";
				#      'keyword'   'value'    'description'
    printf "%5s %-10s=%-10s %-s\n","","fileOut", "x",       "name of output file (def=file.html from template_file.html)";
#    printf "%5s %-10s=%-10s %-s\n","","",   "x", "";
#    printf "%5s %-10s %-10s %-s\n","","",   "no value","";

    printf "%5s %-10s %-10s %-s\n","","dbg",   "no value",   "debug mode";
    printf "%5s %-10s %-10s %-s\n","","silent|-s","no value","no screen output";
    printf "%5s %-10s %-10s %-s\n","","verb|-s",  "no value","verbose";
    printf "%5s %-10s=%-10s %-s\n","","rdb",   "path/name",  "file with method explanations (not in env)";
    exit;}

				# ------------------------------
				# initialise variables

require "envMeta.pm";		# HARD_CODED

				# ------------------------------
				# define parameters
&iniEnv();			# called from envMeta.pm!
$fhin="FHIN";$fhout="FHOUT";

				# ------------------------------
				# read command line
foreach $arg (@ARGV){
#    next if ($arg eq $ARGV[1]);
    if    ($arg=~/^fileOut=(.*)$/)        { $fileOut=        $1;}
    elsif ($arg=~/^de?bu?g$/)             { $Ldebug=         1;
					    $Lverb=          1;}
    elsif ($arg=~/^verb(ose)?$|^\-v$/)    { $Lverb=          1;}
    elsif ($arg=~/^silent$|^\-s$/)        { $Lverb=          0;}

    elsif ($arg=~/^rdb=(.*)$/)            { $fileRdb=        $1;}

#    elsif ($arg=~/^=(.*)$/){ $=$1;}
    elsif (-e $arg && $arg=~/methods/)    { $fileRdb=        $arg;}
    elsif (-e $arg)                       { push(@fileIn,$arg); }
    else { print "*** wrong command line arg '$arg'\n";
	   exit;}}

$fileIn=$fileIn[1];
die ("missing input $fileIn\n")          if (! -e $fileIn);
die ("missing RDB templates $fileRdb\n") if (! -e $fileRdb);

				# --------------------------------------------------
				# (1) read template.html file(s)
				# --------------------------------------------------
foreach $fileIn (@fileIn){
    if (! defined $fileOut || $#fileIn > 1) {
	$fileOut=$fileIn; $fileOut=~s/^.*\///g;
	$fileOut=~s/template[_\-\.]?//g;
	if (-e $fileOut) {
	    $tmp=$fileOut."_".$$;
	    print "-*- WARN fileOut=$fileOut exists, is moved to $tmp\n";
	    system("\\mv $fileOut $tmp");}}
    print "--- $scrName: now in=$fileIn->$fileOut\n" if ($Lverb);
    
				# ------------------------------
				# if explain: read methods first
    if ($fileIn =~ /explain/i ||
	$fileIn !~ /submit/i) {
	$Lis_file_explain=1;
				# out GLOBL %servicesRd
	($Lok,$msg)=
	    &rdFileMethods($fileRdb);
				# unhappy end
	if (! $Lok) { print "*** ERROR $scrName: failed reading fileRdb=$fileRdb\n",$msg,"\n";
		      exit; }}
    else {
	$Lis_file_explain=0;}


				# ------------------------------
				# now back to re
    open($fhin,$fileIn)       || die "*** $scrName ERROR opening in=$fileIn";
    open($fhout,">".$fileOut) || die "*** $scrName ERROR opening out=$fileOut";

    $ctLine=0;
    
    while (<$fhin>) {
	$line=$_;
	++$ctLine;
				# add URL
	if ($line=~/(URL|QUOTE|EMAIL|ADMIN|DONEBY)_4_([a-z0-9\-_\.]+)/i) { 
	    $name=   $2; $name=~tr/[A-Z]/[a-z]/;
	    $kwdOrig=$1; $kwd=$kwdOrig; $kwd=~tr/[A-Z]/[a-z]/; 
	    if    ($kwd =~/(url|quote|doneby)/){
		if (defined $services{$kwd."_".$name}) {
		    $old=$kwdOrig."_4_".$name;
		    $new=$services{$kwd."_".$name};
				# additional formatting for quotes
		    if ($kwd=~/quote/) {
			$new=~s/\n/<LI>/g; # make all list items
			$new=~s/::\s*/:<BR>/g; # title on new line
		    }
		    $new=~s/^\s*|\s*$//g;
		    $line=~s/$old/$new/g;
		    print "--- change line to=$line\n" if ($Ldebug); 
		}}
	    elsif ($kwd =~/(email|admin)/) {
		$value=$services{"admin_".$name};
		if (defined $value) {
		    ($admin_name,$admin_email)=
			split(/,/,$value);
		    $here=$admin_name;
		    $here=$admin_email if ($kwd=~/email/);
		    if (defined $here && length($here) > 1) {
			$old=$kwdOrig."_4_".$name;
			$new=$here;
			$new=~s/\n/<BR>/g;
			$new=~s/^\s*|\s*$//g;
			$line=~s/$old/$new/ig;
			print "--- change line to=$line\n" if ($Ldebug); }}}}
				# top table of all services (for explain)
	elsif ($line=~/LIST_OF_SERVICES/){
	    undef %tmp;
	    foreach $method (@methods) {
		$tmp="";
		foreach $service (@services){
		    next if ($services{"task_".$service} ne $method);
		    $name=$service;
		    $name=$services{"abbr_".$service} if (defined $services{"abbr_".$service});
		    $tmp.=
			"<TD><A HREF=\"\#PX_about_$service\">$name</A></TD>";
		}
		print $fhout 
#		    "<TR><TD ALIGN=RIGHT><STRONG>$method</STRONG></TD>",
		    "<TR><TD VALIGN=TOP BGCOLOR=\"\#0000FF\" ALIGN=RIGHT>",
		    "<STRONG><FONT COLOR=\"\#FFFFFF\">$method<\/FONT><\/STRONG><\/TD>",
		    "<TD> &nbsp\;<\/TD>",
		    "$tmp\n"
			if (length($tmp)>0);
	    }
	    $line="";}
				# fill in method information for methods (for explain)
	elsif ($line=~/METHODS_(\S+)/){
	    $task=$1;
	    if (! defined $task){
		print "*** problem in line=$line, no task defined \n*** $fileIn ctLine=$ctLine\n";
		exit;}
				# go through all services we have
	    foreach $service (@services) {
				# different cattle of fish (e.g. threading in the secondary section)
		next if ($services{"task_".$service} !~ /$task/);
		$line="";	# delete line!
		($Lok,$msg,$text)=
		    &buildExplainMethod($service);
		if (! $Lok) {
		    print "*** problem service=$service, line=$line,\n$msg\n*** $fileIn ctLine=$ctLine\n";
		    exit;}
		print $fhout $text,"\n";
	    }
	}
		
				# skip unfilled in stuff
	next if ($line=~/(URL|QUOTE|EMAIL|ADMIN)_4_/);

				# replace name of server by 'correct' abbreviation
	if ($line=~/Server: ([a-z0-9]*)\</i){
	    $service=$1;
	    $name=0;
	    $name=$services{"abbr_".$service} if (defined $service &&
						  defined $services{"abbr_".$service});
	    $line=~s/Server: $service/Server: $name/
		if ($name);}
				# finally write
	print $fhout $line;
    }
    close($fhin);
    close($fhout);
    push(@fileOut,$fileOut);
}
				# ------------------------------
				# (3) write output
				# ------------------------------
foreach $fileOut (@fileOut) {
    print "--- output in $fileOut\n" if (-e $fileOut);
    print "*** missing output file=$fileOut\n" if (! -e $fileOut);}
exit;


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
sub buildExplainMethod {
    local($service) = @_ ;
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   buildExplainMethod          builds HTML source for one method
#       in:                     $service name (as used in envMeta.pm @services)
#       out:                    1|0,msg,$txt (HTML text)
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="buildExplainMethod";
				# check arguments
    return(&errSbr("not def service!"))    if (! defined $service || length($service)<=1);
    $html="";
    
				# comment
    $html= "<!-- ".$service. " " x (30-length($service)) . "." x 20 . "-->\n";
				# empty line
#    $html.="<TR VALIGN=TOP><TD VALIGN=TOP WIDTH=\"15\%\"><HR><\/TD>";
#    $html.="<TD VALIGN=TOP WIDTH=\"85\%\"><HR><\/TD>\n";
    $html.="<TR VALIGN=TOP><TD VALIGN=TOP WIDTH=\"15\%\"> <\/TD>";
    $html.="<TD VALIGN=TOP WIDTH=\"85\%\"> &nbsp;<\/TD>\n";

				# name
    $html.="<TR VALIGN=TOP>\n";
    $html.="<TD VALIGN=TOP BGCOLOR=\"\#0000FF\" WIDTH=\"15\%\">\n";
    $html.="     <STRONG><FONT COLOR=\"\#FFFFFF\">Server<\/FONT><\/STRONG><\/TD>\n";
    $html.="<TD VALIGN=TOP WIDTH=\"85\%\">\n";
    $abbr=$service; 
    $abbr=$services{"abbr_".$service} if (defined $services{"abbr_".$service});
    $html.="<A NAME=\"PX_about_".$service."\">\n";
    $html.="     <STRONG>".$abbr."<\/STRONG>\n";
    $html.="<\/A>\n";
    $html.="     <\/TD><\/TR>\n";
    $html.="\n";
				# site (URL)
    $html.="<TR VALIGN=TOP>\n";
    $html.="<TD VALIGN=TOP BGCOLOR=\"\#0000FF\" WIDTH=\"15\%\">\n";
    $html.="     <STRONG><FONT COLOR=\"\#FFFFFF\">Site (URL)<\/FONT><\/STRONG><\/TD>\n";
    $html.="<TD VALIGN=TOP WIDTH=\"85\%\">\n";
    $tmp=$services{"url_".$service};
    $html.="     <A HREF=\"".$tmp."\">".$tmp."<\/A><\/TD><\/TR>\n";
    $html.="\n";
				# about
    $html.="<TR VALIGN=TOP>\n";
    $html.="<TD VALIGN=TOP BGCOLOR=\"\#0000FF\" WIDTH=\"15\%\">\n";
    $html.="     <STRONG><FONT COLOR=\"\#FFFFFF\">About<\/FONT><\/STRONG><\/TD>\n";
    $html.="<TD VALIGN=TOP WIDTH=\"85\%\">\n";
    $tmp="no information given";
    if ($servicesRd{"about_".$service}) {
	$tmp=$servicesRd{"about_".$service};

	@tmp=split(/XYZ\tXYZ/,$tmp);
	$tmp="";
	$tmp.="   <UL>\n"       if ($#tmp > 1);
	$ct=0;
	foreach $txt (@tmp){
	    $txt=~s/^\s*|\s*$//g;$txt=~s/<BR>/\n<BR>     /g;
	    if ($#tmp>1) {
		$tmp.="   <LI>$txt<\/LI>\n";}
	    else {
		$tmp.="   $txt\n";}
	    ++$ct;
	}
	$tmp.="<\/UL>\n"        if ($#tmp > 1);
    }
    $html.="     ".$tmp."<\/TD><\/TR>\n";
    $html.="\n";
				# instructions (how_use)
    if ($servicesRd{"how_use_".$service}){
	$html.="<TR VALIGN=TOP>\n";
	$html.="<TD VALIGN=TOP BGCOLOR=\"\#0000FF\" WIDTH=\"15\%\">\n";
	$html.="     <STRONG><FONT COLOR=\"\#FFFFFF\">Help<\/FONT><\/STRONG><\/TD>\n";
	$html.="<TD VALIGN=TOP WIDTH=\"85\%\">\n";

	$tmp=$servicesRd{"how_use_".$service};
	@tmp=split(/XYZ\tXYZ/,$tmp);
	$tmp="";
	$tmp.="   <UL>\n"       if ($#tmp > 1);
	$ct=0;
	foreach $option (@tmp){
	    $option=~s/^\s*|\s*$//g;$option=~s/<BR>/<BR>\n     /g;
	    if ($#tmp>1) {
		$tmp.="   <LI>$option<\/LI>\n";}
	    else {
		$tmp.="   $option\n";}
	    ++$ct; }
	$tmp.="<\/UL>\n"        if ($#tmp > 1);
	$html.="     ".$tmp     if ($ct);
	$html.="<\/TD><\/TR>\n";
	$html.="\n";
    }

				# options
    if ($servicesRd{"options_".$service}) {
	$html.="<TR VALIGN=TOP>\n";
	$html.="<TD VALIGN=TOP BGCOLOR=\"\#0000FF\" WIDTH=\"15\%\">\n";
	$html.="     <STRONG><FONT COLOR=\"\#FFFFFF\">Options<\/FONT><\/STRONG><\/TD>\n";
	$html.="<TD VALIGN=TOP WIDTH=\"85\%\">\n";

	$tmp=$servicesRd{"options_".$service};
	@tmp=split(/XYZ\tXYZ/,$tmp);
	$tmp="";
	$tmp.="   <UL>\n"       if ($#tmp > 1);
	$ct=0;
	foreach $option (@tmp){
	    $option=~s/^\s*|\s*$//g;$option=~s/<BR>/\n<BR>     /g;
	    if ($#tmp>1) {
		$tmp.="   <LI>$option<\/LI>\n";}
	    else {
		$tmp.="   $option\n";}
	    ++$ct;}
	$tmp.="<\/UL>\n"        if ($#tmp > 1);
	$html.="     ".$tmp     if ($ct);
	$html.="<\/TD><\/TR>\n";
	$html.="\n";
    }
				# quote
    $html.="<TR VALIGN=TOP>\n";
    $html.="<TD VALIGN=TOP BGCOLOR=\"\#0000FF\" WIDTH=\"15\%\">\n";
    $html.="     <STRONG><FONT COLOR=\"\#FFFFFF\">Quote<\/FONT><\/STRONG><\/TD>\n";
    $html.="<TD VALIGN=TOP WIDTH=\"85\%\">\n";
    $tmp="no information given";
				# many papers ..
    if ($services{"quote_".$service}) {
	$tmp=$services{"quote_".$service};
	@tmp=split(/\n/,$tmp);
#	$tmp=~s/^\s*|\s*$//g;$tmp=~s/<BR>/\n<BR>     /g;
	$tmp= "   <CITE>\n";
	$tmp.="   <OL type=\"i\">\n" if ($#tmp > 1);
	foreach $paper (@tmp){
	    $paper=~s/::/:/g;
	    if ($#tmp>1) {
		$tmp.="   <LI>$paper<\/LI>\n";}
	    else {
		$tmp.="   $paper\n";}}
	$tmp.="<\/OL>\n"        if ($#tmp>1);
	$tmp.="<\/CITE>\n";
    }
    $html.="     ".$tmp."<\/TD><\/TR>\n";
    $html.="\n";
				# done by
    $html.="<TR VALIGN=TOP>\n";
    $html.="<TD VALIGN=TOP BGCOLOR=\"\#0000FF\" WIDTH=\"15\%\">\n";
    $html.="     <STRONG><FONT COLOR=\"\#FFFFFF\">Authors<\/FONT><\/STRONG><\/TD>\n";
    $html.="<TD VALIGN=TOP WIDTH=\"85\%\">\n";
    $tmp="no information";
    if (defined $services{"doneby_".$service}){
	$tmp=$services{"doneby_".$service};
	$tmp="$tmp\n";}
    $html.="     ".$tmp."<\/TD><\/TR>\n";
    $html.="\n";
				# admin
    $html.="<TR VALIGN=TOP>\n";
    $html.="<TD VALIGN=TOP BGCOLOR=\"\#0000FF\" WIDTH=\"15\%\">\n";
    $html.="     <STRONG><FONT COLOR=\"\#FFFFFF\">Contact<\/FONT><\/STRONG><\/TD>\n";
    $html.="<TD VALIGN=TOP WIDTH=\"85\%\">\n";
    $tmp="   no information";
    if (defined $services{"admin_".$service}){
	$tmp=$services{"admin_".$service};
	if ($tmp=~/,/){
	    ($name,$mail)=split(/,/,$tmp);
	    $tmp="   $name (<A HREF=\"mailto:$mail\">$mail<\/A>)\n";}
	else {
	    $tmp="   $tmp\n";}}
    $html.="     ".$tmp."<\/TD><\/TR>\n";
    $html.="\n";

    return(1,"ok $sbrName",$html);
}				# end of buildExplainMethod

#===============================================================================
sub dbglog {
#-------------------------------------------------------------------------------
#   msglog                      the debug message log
#       in:                     $message
#       in GLOBAL:              $dbglogunit (file handle to write message)
#-------------------------------------------------------------------------------
    print  "<DBG>",@_,"</DBG>";
}				# end of dbglog

#===============================================================================
sub msglog {
#-------------------------------------------------------------------------------
#   msglog                      the standard message log
#       in:                     $message
#-------------------------------------------------------------------------------
    print  "<MSG>",@_,"</MSG>";
}				# end of msglog

#===============================================================================
sub rdFileMethods {
    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   rdFileMethods               reads the method rdb file (template_methods.rdb)
#       in GLOBAL:              @kwd_methods
#       out GLOBAL:             %servicesRd, with
#                               $servicesRd{"name_of_method",$kwd}
#                               where $kwd = any of those in @kwd_methods
#                               =0 if empty in file
#                               
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="rdFileMethods";
    $fhinLoc="FHIN_"."rdFileMethods";
				# check arguments
    return(&errSbr("not def fileInLoc!"))      if (! defined $fileInLoc);
    return(&errSbr("no fileIn=$fileInLoc!"))   if (! -e $fileInLoc);
				# open file
    open($fhinLoc,$fileInLoc) || return(&errSbr("fileInLoc=$fileInLoc, not opened"));

    undef %servicesRd;
    
    while (<$fhinLoc>) {
	$line=$_;
	next if ($line=~/^\s*\#/ ||
		 $line=~/^[\s\t\n]*$/);
				# too few fields: skip
	next if ($line!~/.*\t.*\t/);
				# split (three fields: name of method, keyword, value)
	($name,$key,$val)=split(/\s*\t\s*/,$line);
				# initialise expected fields
	if (! defined $servicesRd{"about_".$name}){
	    foreach $kwd (@kwd_methods){
		$servicesRd{$kwd."_".$name}=0;}}

				# empty -> move on
	next if (! defined $val   ||
		 $val=~/^[\s]*$/  ||
		 length($val) < 1);
				# case: first
	if (! $servicesRd{$key."_".$name}) {
	    $servicesRd{$key."_".$name}=$val;}
				# case: second, or nth
	else {
	    $servicesRd{$key."_".$name}.="XYZ\tXYZ".$val;}
    }
    close($fhinLoc);
    return(1,"ok $sbrName");
}				# end of rdFileMethods

