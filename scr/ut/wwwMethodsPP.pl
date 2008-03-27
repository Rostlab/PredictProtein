#!/usr/local/bin/perl -w
##!/usr/sbin/perl -w

# default configuration file
$PPenvDefault="/home/$ENV{USER}/server/envPP.pm";
$kwdENV=      "PPENV";

# script help asf
$scrName=$0;   $scrName=~s/^.*\/|\.pl//g;
$scrGoal=      "writes WWW page with info about methods used in PP\n".
    "      note: needs template of methods in scr/txt/www/method_about.rdb !\n".
    "      ";

#
#------------------------------------------------------------------------------#
#	Copyright				        	2000	       #
#	Burkhard Rost		rost@columbia.edu			       #
#	CUBIC (Columbia Univ)	http://www.columbia.edu/~rost/   	       #
#       Dept Biochemistry & Molecular Biophysics			       #
#       630 West, 168 Street						       #
#	New York, NY 10032	http://www.columbia.edu/~rost/                 #
#				version 0.1   	Apr,    	2000	       #
#------------------------------------------------------------------------------#
#
# updating the WWW page for PredictProtein listing all programs and versions
# 
# 
# assumptions:
# 
# - environment variable defined in 'PPENV'
#   if not: assume 'is local run'
# 
# documents needed:
# 
# - 
# 
# - $HOME/conf/           configuration file PPEnv.pm 
#                         IF LOCAL: assume is in current OR in CURRENT/conf
# 
# 
#------------------------------------------------------------------------------#

$[ =1 ;				# count from one

				# --------------------------------------------------
				# initialise environment parameters
				# GLOBAL out: @methodlist
				# GLOBAL out: @methodtype
				# GLOBAL out: $ra_methods
				# --------------------------------------------------
($Lok,$msg)=
    &ini();			&ctrlAbort("*** ERROR $scrName: $msg",$scrName."_ini") if (! $Lok);

# --------------------------------------------------------------------------------
# run it now
# --------------------------------------------------------------------------------

         			# ------------------------------
				# sort types
undef %tmp;
foreach $type (@methodtype){
    $#tmp2=0;
	
    foreach $method (@methodlist){
	next if (! defined %{$ra_methods->{$method}}->{"taskabbr"});
	next if (%{$ra_methods->{$method}}->{"taskabbr"} ne $type);
	push(@tmp2,$method);
    }
    $methodsLoc{$type}=join(',',@tmp2);
}

				# ------------------------------
				# out GLOBL %template
($Lok,$msg)=
    &rdFileMethTemplate
    ($envPP{"file_methodTemplate"}
     );				&ctrlAbort("*** ERROR $scrName: $msg",$scrName."_rdFile=".
					   $envPP{"file_methodTemplate"}) if (! $Lok);


				# --------------------------------------------------
				# final update on central DOC/explain page
				# GLOBAL in: @methodlist
				# GLOBAL in: @methodtype
				# GLOBAL in: $ra_methods
				# GLOBAL in: %methodsLoc
				# --------------------------------------------------
$fileOutLoc="TMP_doc_method.html";

($Lok,$msg)=
    &wrtDocMethod(
		  $fileOutLoc); &ctrlAbort("*** ERROR $scrName: $msg",$scrName."_wrtDocMethod") if (! $Lok);


$cmd="\\mv $fileOutLoc ".$envPP{"file_methodwwwDoc"};
print "--- STILL TO DO:\n$cmd\n";

exit;

#===============================================================================
sub ini {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   ini                         gets the parameters from env, and checks
#-------------------------------------------------------------------------------
				# ------------------------------
				# get the name of this file
    $scrName=$0;$scrName=~s/^.*\/|\.pl//g;
				# --------------------------------------------------
				# include envPP package as define in $PPENV or default
    if    ($ENV{'PPENV'}) {
	$env_pack = $ENV{'PPENV'}; }
    elsif (defined $kwdENV && -e $ENV{$kwdENV}) {
	$env_pack = $ENV{$kwdENV}; }
    elsif (defined $PPenvDefault && -e $PPenvDefault) {
	$env_pack = $PPenvDefault; }
    else {				# this is used by the automatic version!
	$env_pack = "/home/$ENV{USER}/server/scr/envPP.pm"; } # HARD CODDED, HARD_CODDED

				# ------------------------------
				# debug mode
    if ($#ARGV<1) { print "goal: $scrGoal\n";
		    print "use:  $scrName <auto|dbg>\n";
		    print "opt:  env=envPP.pm (i.e. the PP env pack, def=$env_pack\n";
		    exit; }
				# avoid warning

				# ------------------------------
				# require lib
    $Lok=
	require $env_pack;
                    		# *** error in require env
    return(0,"*** ERROR $scrName: require env_pack=".$env_pack."\n".
	   "*** err=9101")      if (! $Lok);

				# ------------------------------
				# set methods env
    ($Lok,$msg,$ra_methods)=
	&envPP::envMethods();
                    		# *** error in require env
    return(0,"*** ERROR $scrName: require env_pack=".$env_pack.", porblem with envMethods=\n".
	   "msg\n".
	   "*** err=9102")      if (! $Lok);

				# ------------------------------
				# read command line
    $Ldebug=0;
    foreach $arg (@ARGV){
	if    ($arg=~/^de?bu?g$/i) { $Ldebug=1; }
	elsif ($arg=~/^auto$/)     { $Ldebug=0; } }


    @methodlist=@{$ra_methods->{"list"}};
    @methodtype=@{$ra_methods->{"type"}};
				# ------------------------------
				# get the date
				# ------------------------------

    $DATE=                &sysDate();
    $DATE=~s/(200\d) .*$/$1/;
    $Date=$DATE;
				# ------------------------------
				# read local environment var
				# ------------------------------
    foreach $des (
		  "pp_admin","pp_url",

		  "file_methodwwwDoc",
		  "file_methodTemplate",

		  "file_methodMetaRel"
		  ) {
	$envPP{$des}=&envPP::getLocal($des);                      
				# *** error in local env
	return(0,"*** err=9103\n"."failed to get envPP{$des} from env_pack '$env_pack'\n") 
	    if (! defined $envPP{$des});
    }

    return(1,"ok");
}				# end of ini

#===============================================================================
sub assPrt {
    local($txtLoc,$sbrLoc) = @_ ;
    local($SBR1,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   assPrt                      just print dbg and verbose stuff
#       in:                     $txtLoc:   text to print
#       in:                     $sbrLoc:   name of routine writing
#       in:                     $levelLoc: detail level (or blabla level, 2 for dbg)
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="assPrt";

#xx    print $FHTRACE
#    print 
#	"--- $DATE_SORT ",$sbrLoc,": ",$txtLoc,"\n";
    print 
	"--- ",$txtLoc," (",$sbrLoc,")\n";
	
    return(1,"ok $sbrName");
}				# end of assPrt

#===============================================================================
sub assPrtWarn {
    local($txtLoc,$sbrLoc) = @_ ;
    local($SBR1,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   assPrtWarn                  just print dbg and verbose stuff
#       in:                     $txtLoc:   text to print
#       in:                     $sbrLoc:   name of routine writing
#       in:                     $levelLoc: detail level (or blabla level, 2 for dbg)
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="assPrt";

    print 
	"--- $sbrLoc: ",$txtLoc,"\n";
	
    return(1,"ok $sbrName");
}				# end of assPrtWarn

#===============================================================================
sub ctrlAbort {
    local($message,$where) = @_;
#----------------------------------------------------------------------
#   ctrlAbort                   sends alarm mail to pp_admin and exits(1)
#       in:                     $message,$subject
#       in GLOBAL:              $envPP{"exe_mail"},$envPP{"pp_admin"},
#       in GLOBAL:              $envPP{"file_errLog"},$Date,
#       out:                    EXIT(1)
#----------------------------------------------------------------------
    print "*** $scrName: message=$message\n";
    print "*** ". " " x length($scrName) ." failed at $where\n";
    exit;
}				# end of ctrlAbort

#==============================================================================
sub errSbr    {local($txtInLoc,$sbrNameLocy) = @_ ;
#-------------------------------------------------------------------------------
#   errSbr                      simply writes '*** ERROR $sbrName: $txtInLoc'
#-------------------------------------------------------------------------------
	       $sbrNameLocy=$sbrName if (! defined $sbrNameLocy);
	       $txtInLoc.="\n";
	       $txtInLoc=~s/\n\n+/\n/g;
	       return(0,"*** ERROR $sbrNameLocy: $txtInLoc");
}				# end of errSbr

#==============================================================================
sub errSbrMsg {local($txtInLoc,$msgInLoc,$sbrNameLocy) = @_ ;
#-------------------------------------------------------------------------------
#   errSbrMsg                   simply writes '*** ERROR $sbrName: $txtInLoc\n'.$msg
#-------------------------------------------------------------------------------
	       $sbrNameLocy=$sbrName if (! defined $sbrNameLocy);
	       $txtInLoc.="\n";
	       $txtInLoc=~s/\n\n+/\n/g;
	       $msgInLoc.="\n";
	       $msgInLoc=~s/\n\n+/\n/g;
	       return(0,"*** ERROR $sbrNameLocy: $txtInLoc".$msgInLoc);
}				# end of errSbrMsg

#==============================================================================
sub errScrMsg {local($txtInLoc,$msgInLoc,$scrNameLocy) = @_ ;
#-------------------------------------------------------------------------------
#   errScrMsg                   writes message and EXIT!!
#-------------------------------------------------------------------------------
	       $scrNameLocy=$scrName if (! defined $scrNameLocy);
	       $txtInLoc.="\n";
	       $txtInLoc=~s/\n\n+/\n/g;
	       if (defined $msgInLoc) {
		   $msgInLoc.="\n";
		   $msgInLoc=~s/\n\n+/\n/g;}
	       else {
		   $msgInLoc="";}
	       print "*** ERROR $scrNameLocy: $txtInLoc".$msgInLoc;
	       exit; 
}				# end of errScrMsg

#===============================================================================
sub htmlFootPP {
    local($fhoutLoc,$dirRelDiconLoc,$dateLoc,$emailLoc,$wwwLoc,
	  $indexLoc,$prevLoc,$nextLoc,$LtopLoc,$LbotLoc,$linkOtherLoc) = @_ ;
    local($SBR7,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   htmlFootPP                  writes the <HEAD> for HTML
#       in:                     $fhoutLoc:       filehandle
#       in:                     $dirRelDiconLoc: location of directory with icons 
#       in:                                      relative to current file!!
#       in:                     $dateLoc:        full current date (for version)
#       in:                     $emailLoc:       email for final contact
#       in:                     $wwwLoc:         www for final contact
#       in:                     $indexLoc:   used to locate index
#       in:                     $prevLoc:    for navigate buttons (=0 -> skipped)
#       in:                     $nextLoc:    for navigate buttons (=0 -> skipped)
#       in:                     $LtopLoc:    for navigate buttons (=0 -> skipped)
#       in:                     $LbotLoc:    for navigate buttons (=0 -> skipped)
#       in:                     $linkOther   "explanations to xyz=URL,bla=URL2"
#       in:                     $:
#                               
#       in GLOBAL:              $par{"dirXchDo"."PPl".$type}
#       in GLOBAL:              $par{"debug"}
#       in GLOBAL:              $par{}
#       in GLOBAL:              
#                               
#       out GLOBAL              
#       out GLOBAL              
#                               
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
#    $SBR7=$packName.":"."htmlFootPP";
    $SBR7="htmlFootPP";
    $linkOtherLoc=0             if (! defined $linkOtherLoc);

    $dirRelDiconLoc.="/"        if (length($dirRelDiconLoc)>1 &&
				    $dirRelDiconLoc !~/\/$/);
    $dirTmp=$dirRelDiconLoc;
    $dirTmp=~s/Dicon/res/;
    push(@tmpwrt,
	 "<UL>",
	 "<LI>Last update: ".$dateLoc. "</LI>",
	 "<LI>Contact:     "."<A HREF=\"mailto:".$emailLoc."\">".$emailLoc."</A></LI>",
	 "<LI>WWW:         "."<A HREF=\"".$wwwLoc."\">".$wwwLoc."</A></LI>",
	 "</UL>",
	 " ");

				# ------------------------------
				# navigation buttoms
    if ($LtopLoc || $LbotLoc || $prevLoc || $nextLoc){
	push(@tmpwrt,
	     "<!-- -------------------------------------------------------------------------------- -->",
	     "<!-- beg navigation   -->",
	     "<CENTER><A NAME=\"BOTTOM\">");
	$tmpwrt="";
	if ($linkOtherLoc){
	    @tmp1=split(/,/,$linkOtherLoc);
	    foreach $tmp (@tmp1){
		($kwd,$val)=split(/[=]+/,$tmp);
		next if (! defined $kwd);
		next if (! defined $val);
		$tmpwrt.="<A HREF=\"".$val."\">".$kwd."</A> - ";
	    }}
	$tmpwrt.="<A HREF=\"".$indexLoc."\">Home</A> - " if ($indexLoc);
	$tmpwrt.="<A HREF=\"".$prevLoc."\">Prev</A> - "  if ($prevLoc);
	$tmpwrt.="<A HREF=\"".$nextLoc."\">Next</A> - "  if ($nextLoc);
	$tmpwrt.="<A HREF=\"\#TOP\">Top</A> "            if ($LtopLoc);
	$tmpwrt=~s/\-\s*$//g;
	push(@tmpwrt,
	     $tmpwrt,
	     "</A></CENTER>",
	     "<!-- end navigation   -->",
	     "<!-- -------------------------------------------------------------------------------- -->");
    }

    push(@tmpwrt,
	 "</BODY>",
	 "</HTML>"
	 );

				# ------------------------------
				# write
    foreach $tmp (@tmpwrt){
	print $fhoutLoc $tmp,"\n";
    }

    return(1,"ok $SBR7");
}				# end of htmlFootPP

#===============================================================================
sub htmlHeadPP {
    local($fhoutLoc,$titleLoc,$titleH1Loc,$LstyleLoc,
	  $indexLoc,$prevLoc,$nextLoc,$LtopLoc,$LbotLoc,$rh_tocLoc,$linkOtherLoc) = @_ ;
    local($SBR7,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   htmlHeadPP                 writes the <HEAD> for HTML
#       in:                     $fhoutLoc:   filehandle
#       in:                     $titleLoc:   title of file (<TITLE>)
#       in:                     $titleH1Loc: title used in H1 heading
#       in:                     $Lstyle:     if 1: will write colour style 
#                                            NOTE: only for secondary structure
#                                                  at the moment!!
#       in:                     $indexLoc:   used to locate index
#       in:                     $prevLoc:    for navigate buttons (=0 -> skipped)
#       in:                     $nextLoc:    for navigate buttons (=0 -> skipped)
#       in:                     $LtopLoc:    for navigate buttons (=0 -> skipped)
#       in:                     $LbotLoc:    for navigate buttons (=0 -> skipped)
#                               
#       in:                     $tocLoc:     Table of contents    (=0 -> skipped)
#       in:                     %tocLoc:       Table of contents    (=0 -> skipped)
#       in:                     $toc{"kwd"}    'kwd1,kwd2'  all keywords
#       in:                     $toc{$kwd,"level"}: level > 1 to have sub-lists
#       in:                     $toc{$kwd,"link"}:  explicit link (default= "#$kwd")
#                               
#       in:                     $linkOther   "explanations to xyz=URL,bla=URL2"
#       in:                     $:
#                               
#       in GLOBAL:              $par{"dirXchDo"."PPl".$type}
#       in GLOBAL:              $par{"debug"}
#       in GLOBAL:              $par{}
#       in GLOBAL:              
#                               
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
#    $SBR7=$packName.":"."htmlHeadPP";
    $SBR7="htmlHeadPP";
				# check variables
    return(&errSbr("not def fhoutLoc!",  $SBR7)) if (! defined $fhoutLoc);
    return(&errSbr("not def titleLoc!",  $SBR7)) if (! defined $titleLoc);
    return(&errSbr("not def titleH1Loc!",$SBR7)) if (! defined $titleH1Loc);
    return(&errSbr("not def LstyleLoc!", $SBR7)) if (! defined $LstyleLoc);
    return(&errSbr("not def indexLoc!",  $SBR7)) if (! defined $indexLoc);
    return(&errSbr("not def prevLoc!",   $SBR7)) if (! defined $prevLoc);
    return(&errSbr("not def nextLoc!",   $SBR7)) if (! defined $nextLoc);
    return(&errSbr("not def LtopLoc!",   $SBR7)) if (! defined $LtopLoc);
    return(&errSbr("not def LbotLoc!",   $SBR7)) if (! defined $LbotLoc);
    return(&errSbr("not def tocLoc!",    $SBR7)) if (! defined $rh_tocLoc);
#    return(&errSbr("not def !",$SBR7)) if (! defined $);
#    return(&errSbr("not def !",$SBR7)) if (! defined $);
    $linkOtherLoc=0                              if (! defined $linkOtherLoc);

    @tmpwrt=
	("<HTML>",
	 "<HEAD>",
	 "<TITLE>",
	 "\t ".$titleLoc,
	 "</TITLE>",
	 "<META NAME=\"FirstName\" value=\"Rost Group\">",
	 "<META NAME=\"LastName\" value=\"CUBIC:PP\">"
	 );

    $style= "<STYLE TYPE=\"text/css\">";
    $style.="<!-- ";
				# subtoc
    $style.="DIV.subtoc  { padding: 1em\; margin: 1em 0\;border: thick inset \;background: silver\;}"."\n";
    $style.=" -->"."\n";
    $style.="</STYLE>"."\n";

    push(@tmpwrt,
	 $style)
	if ($LstyleLoc || $rh_tocLoc);

    push(@tmpwrt,
	 "<LINK rel=\"Index\" HREF=\"".$indexLoc."\">") if ($indexLoc);
    push(@tmpwrt,
	 "<LINK rel=\"Prev\"  HREF=\"".$prevLoc."\">")  if ($prevLoc);
    push(@tmpwrt,
	 "<LINK rel=\"Next\"  HREF=\"".$nextLoc."\">")  if ($nextLoc);
    push(@tmpwrt,
	 "</HEAD>",
	 " ",
	 "<BODY bgcolor=#FFFFFF>",
#	 "<BODY>",
	 " ");
				# ------------------------------
				# navigation buttoms
    if ($LtopLoc || $LbotLoc || $prevLoc || $nextLoc || $linkOtherLoc){
	push(@tmpwrt,
	     "<!-- -------------------------------------------------------------------------------- -->",
	     "<!-- beg navigation   -->",
	     "<CENTER><A NAME=\"TOP\">");
	
	$tmpwrt="";
	$tmpwrt.="<A HREF=\"".$indexLoc."\">Home</A> - " if ($indexLoc);
	$tmpwrt.="<A HREF=\"".$prevLoc."\">Prev</A> - "  if ($prevLoc);
	$tmpwrt.="<A HREF=\"".$nextLoc."\">Next</A> - "  if ($nextLoc);
	$tmpwrt.="<A HREF=\"\#BOTTOM\">Bottom</A> - "    if ($LbotLoc);
	if ($linkOtherLoc){
	    @tmp1=split(/,/,$linkOtherLoc);
	    foreach $tmp (@tmp1){
		($kwd,$val)=split(/[=]+/,$tmp);
		next if (! defined $kwd);
		next if (! defined $val);
		$tmpwrt.="<A HREF=\"".$val."\">".$kwd."</A> - ";
	    }}
	$tmpwrt=~s/\-\s*$//g;
	push(@tmpwrt,
	     $tmpwrt,
	     "</A></CENTER>",
	     "<!-- end navigation   -->",
	     "<!-- -------------------------------------------------------------------------------- -->");}

				# ------------------------------
				# title summary
    push(@tmpwrt,
	 "<H1>".$titleH1Loc."</H1>",
	 "<P>",
	 " ");
				# ------------------------------
				# TOC:
    if ($rh_tocLoc){
	push(@tmpwrt,
	     "<!-- -------------------------------------------------------------------------------- -->",
	     "<!-- beg toc  -->",
	     "<DIV class=\"subtoc\">",
	     "<STRONG>Contents</STRONG>",
	     "<BR>",
	     "<UL>");
	$levelNow=1;
	foreach $kwd (split(/\t/,$rh_tocLoc->{"kwd"})){
				# missing
	    next if (! defined $rh_tocLoc->{$kwd,"txt"});
				# get link: default = local
	    $link="\#".$kwd;
				# given
	    if (defined $rh_tocLoc->{$kwd,"link"}){
		$link="";
		$link.="\#"     if ($rh_tocLoc->{$kwd,"link"} !~ /\./);
		$link=$rh_tocLoc->{$kwd,"link"}; }

				# get level of list
	    if    (defined $rh_tocLoc->{$kwd,"level"} && 
		   $rh_tocLoc->{$kwd,"level"} > $levelNow){
		push(@tmpwrt,"\t <UL>");
		$levelNow=$rh_tocLoc->{$kwd,"level"};}
	    elsif (defined $rh_tocLoc->{$kwd,"level"} && 
		   $rh_tocLoc->{$kwd,"level"} < $levelNow){
		push(@tmpwrt,"\t </UL>");
		$levelNow=$rh_tocLoc->{$kwd,"level"};}
	    elsif (! defined $rh_tocLoc->{$kwd,"level"} && 
		   $levelNow > 1){
		push(@tmpwrt,"\t </UL>");
		$levelNow=1;}
	    $tmp="";
	    $tmp="\t " if ($levelNow > 1);
	    push(@tmpwrt,
		 $tmp."<LI><A HREF=\"".$link."\"> ".$rh_tocLoc->{$kwd,"txt"}."</A></LI>");
	}
				# close level 2 lists
	push(@tmpwrt,
	     "\t "."</UL>\n") if ($levelNow > 1);

	push(@tmpwrt,
	     "</UL>",
	     "</DIV>",
	     "<!-- end toc  -->",
	     "<!-- -------------------------------------------------------------------------------- -->",
	     "<BR><P>",
	     " ",
	     );
    }

				# ------------------------------
				# write
    foreach $tmp (@tmpwrt){
	print $fhoutLoc $tmp,"\n";
    }

    return(1,"ok $SBR7");
}				# end of htmlHeadPP

#===============================================================================
sub rdFileMethTemplate {
    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   rdFileMethTemplate          reads the method rdb file (template_methods.rdb)
#       in GLOBAL:              @kwd_methods
#       out GLOBAL:             %servicesTemplate, with
#                               $servicesTemplate{"name_of_method",$kwd}
#                               where $kwd = any of those in @kwd_methods
#                               =0 if empty in file
#                               
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="rdFileMethTemplate";
    $fhinLoc="FHIN_"."rdFileMethTemplate";
				# check arguments
    return(&errSbr("not def fileInLoc!"))      if (! defined $fileInLoc);
    return(&errSbr("no fileIn=$fileInLoc!"))   if (! -e $fileInLoc);

    @kwd_methods=
	(
	 "about"
#	 "how_use",
#	 "options"
	 );

				# open file
    open($fhinLoc,$fileInLoc) || return(&errSbr("fileInLoc=$fileInLoc, not opened"));

    undef %template;
    
    while (<$fhinLoc>) {
	$line=$_;
	next if ($line=~/^\s*\#/ ||
		 $line=~/^[\s\t\n]*$/);
				# too few fields: skip
	next if ($line!~/.*\t.*\t/);
				# split (three fields: name of method, keyword, value)
	($name,$key,$val)=split(/\s*\t\s*/,$line);
				# initialise expected fields
	if (! defined $template{$name,"about"}){
	    foreach $kwd (@kwd_methods){
		$template{$name,$kwd}=0;
	    }}

				# empty -> move on
	next if (! defined $val   ||
		 $val=~/^[\s]*$/  ||
		 length($val) < 1);
				# case: first
	if (! $template{$name,$key}) {
	    $template{$name,$key}=$val;}
				# case: second, or nth
	else {
	    $template{$name,$key}.="XYZ\tXYZ".$val;}
    }
    close($fhinLoc);
    return(1,"ok $sbrName");
}				# end of rdFileMethTemplate

#===============================================================================
sub sysDate {
#    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   sysDate                     returns $Date
#       out:                    $Date (May 30, 1998 59:39:03)
#-------------------------------------------------------------------------------

    @tmp=(			# HARD_CODED
	  "/home/$ENV{USER}/perl/",
	  "/home/$ENV{USER}/server/scr/lib/"
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

#===============================================================================
sub wrtDocMethod {
    local($fileOutLoc) = @_ ;
    local($SBR4,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   wrtDocMethod         writes all methods into the explanation file:
#                               public_html/doc/explain_method.html
#                               
#       in:                     $fileInLoc:
#       in:                     $:
#                               
#       in GLOBAL:              $par{"dirXchDo"."PPl".$type}
#       in GLOBAL:              $par{"debug"}
#       in GLOBAL:              $par{}
#       in GLOBAL:              
#                               
#       out GLOBAL              
#       out GLOBAL              
#                               
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
#    $SBR4=$packName.":"."wrtDocMethod";
    $SBR4="wrtDocMethod";
    $fhinLoc="FHIN_"."wrtDocMethod";$fhoutLoc="FHOUT_"."wrtDocMethod";
				# ------------------------------
				# local settings
    $index="../index.html";
    $prev= "../index.html";
    $next= "help_01.html";
    $Ltop=  1;
    $Lbot=  1;

    $toc{"kwd"}=                "list"."\t"."types"."\t"."methods";
    foreach $type (@methodtype){
	$toc{"kwd"}.=           "\t"."types_".$type;
    }
    $toc{"list","link"}=         "#list";
    $toc{"list","txt"}=          "List of all prediction categories";
    $toc{"types","link"}=        "#types";
    $toc{"types","txt"}=         "Methods applied to your sequence";

    foreach $kwd ("server","db","ali","motif","toolin","struc","toolex"){
	$toc{"type_".$kwd,"level"}= 2;
	$toc{"type_".$kwd,"txt"}=   %{$ra_methods->{"typetrans"}}->{$kwd};
	$toc{"kwd"}.=            "\t"."type_".$kwd;
    }
    $toc{"kwd"}.=                "\t"."meta";
    $toc{"meta","link"}=         $envPP{"file_methodMetaRel"}."#list";
    $toc{"meta","txt"}=          "Prediction methods available through META-PP";

				# ------------------------------
				# open file
    &assPrt("write fileOutLoc (docMethod)=$fileOutLoc",$SBR4);

    open($fhoutLoc,">".$fileOutLoc) || return(&errSbr("fileOutLoc=$fileOutLoc, not created"));
				# ------------------------------
				# header
    ($Lok,$msg)=
	&htmlHeadPP
	    ($fhoutLoc,"PP: methods","PP: details for methods used",0,
	     $index,$prev,$next,$Ltop,$Lbot,
	     \%toc);            &assPrtWarn("after htmlHeadPP ($fhoutLoc)\n".$msg,$SBR4) if (! $Lok);

				# ------------------------------
				# top: list of services
    ($Lok,$msg)=
	&wrtMethodTypes
	    ($fhoutLoc);	&assPrtWarn("after webWrtType ($fhoutLoc)\n".$msg,$SBR4) if (! $Lok);


				# ------------------------------
				# all tasks
    print $fhoutLoc
	"<BR><BR>\n",
	"<!-- ================================================================================ -->\n",
	"<!-- beg: methods  -->\n",
				# TOC entry with colour!
	"<TABLE WIDTH=\"100%\">\n",
	"<TR><TD VALIGN=TOP ALIGN=CENTER BGCOLOR=\"\#000080\">",
	"\t \t <STRONG><FONT COLOR=\"\#FFFFFF\" SIZE=\"+3\">\n",
	"\t \t <A NAME=\"types\">Categories of prediction methods PPluated</A>\n",
	"\t \t </FONT></STRONG>\n",
	"    </TD></TR>\n",
	"</TABLE>\n",
	" \n",
	"<BR>\n",
	"\n";

    foreach $type (@methodtype){
	next if (! defined $methodsLoc{$type});

	next if (! defined %{$ra_methods->{"typetrans"}}->{$type});
	$description=%{$ra_methods->{"typetrans"}}->{$type};
	print $fhoutLoc
	    "<BR>\n",
	    "<H3><A NAME=\"type_".$type."\">",
	         $description."</A></H3>\n",
	    "<TABLE COLS=2 CELLPADDING=2 WIDTH=\"100%\">\n\n";


	foreach $method (split(/,/,$methodsLoc{$type})){
	    $methodAbbr=$method;
	    $methodAbbr=
		%{$ra_methods->{$method}}->{"abbr"} if (defined 
							%{$ra_methods->{$method}}->{"abbr"});
	    ($Lok,$msg,$html)=
		&wrtMethodDetail
		    ($fhoutLoc,
		     $method);	&assPrtWarn(" after wrtMethodDetail ($fhoutLoc,$method)\n".
					    $msg,$SBR4) if (! $Lok);
				# WRITE
	    print $fhoutLoc
		$html,"\n"      if ($Lok);
	}
	print $fhoutLoc
	    "</TABLE><P>\n",
	    "<BR><HR><P>\n";
    }
    print $fhoutLoc
	"<!-- end: methods  -->\n",
	"<!-- ================================================================================ -->\n",
	"<BR><BR>\n",
	"\n";

				# ------------------------------
				# footer
    ($Lok,$msg)=
	&htmlFootPP
	    ($fhoutLoc,"../Dicon/",$DATE,$envPP{"pp_admin"},$envPP{"pp_url"},
	     $index,$prev,$next,
	     $Ltop,$Lbot);	&assPrtWarn("after htmlFootPP($fhoutLoc)\n".$msg,$SBR4) if (! $Lok);

    close($fhoutLoc);

    return(1,"ok $SBR4");
}				# end of wrtDocMethod

#===============================================================================
sub wrtMethodDetail {
    local($fhoutLoc,$methodLoc) = @_ ;
    local($SBR7,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   wrtMethodDetail      writes the details for each method
#       in:                     $fhoutLoc: filehandle
#                               
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
#    $SBR7=$packName.":"."wrtMethodDetail";
    $SBR7="wrtMethodDetail";

    $html="";
				# ------------------------------
				# comment
    $html= "<!-- ".$methodLoc. " " x (30-length($methodLoc)) . "." x 20 . "-->\n";
				# ------------------------------
				# empty line
    $html.="<TR VALIGN=TOP><TD VALIGN=TOP WIDTH=\"15\%\"> </TD>";
    $html.="<TD VALIGN=TOP WIDTH=\"85\%\"> &nbsp;</TD>\n";
				# ------------------------------
				# name
    $html.="<TR VALIGN=TOP>\n";
    $html.="<TD VALIGN=TOP BGCOLOR=\"\#0000FF\" WIDTH=\"15\%\">\n";
    $html.="     <A NAME=\".PX_about_".$methodLoc."\">";
    $html.="     <STRONG><FONT COLOR=\"\#FFFFFF\">Server</FONT></STRONG>";
    $html.="     </A>";
    $html.="     </TD>\n";
    $html.="<TD VALIGN=TOP WIDTH=\"85\%\">\n";
    $abbr=$methodLoc; 
    $abbr=%{$ra_methods->{$methodLoc}}->{"abbr"} if (defined 
						     %{$ra_methods->{$methodLoc}}->{"abbr"});
    $html.="<A NAME=\"PX_about_".$methodLoc."\">\n";
    $html.="     <STRONG>".$abbr."</STRONG>\n";
    $html.="</A>\n";
    $html.="     </TD></TR>\n";
    $html.="\n";
				# ------------------------------
				# site (URL)
    $html.="<TR VALIGN=TOP>\n";
    $html.="<TD VALIGN=TOP BGCOLOR=\"\#0000FF\" WIDTH=\"15\%\">\n";
    $html.="     <STRONG><FONT COLOR=\"\#FFFFFF\">Site (URL)</FONT></STRONG></TD>\n";
    $html.="<TD VALIGN=TOP WIDTH=\"85\%\">\n";
    $tmp= %{$ra_methods->{$methodLoc}}->{"url"};
    if ($tmp =~ /^local/){
	$html.="     local at CUBIC</TD></TR>\n"; }
    else{
	$html.="     <A HREF=\"".$tmp."\">".$tmp."</A></TD></TR>\n"; }
    $html.="\n";
				# ------------------------------
				# about
    $tmp="no information given";
    $tmp="";
    $Lskip=1;
    $tmphtml="";
				# DES
    if (defined %{$ra_methods->{$methodLoc}}->{"des"} && 
	length(%{$ra_methods->{$methodLoc}}->{"des"}) > 1){ 

	$tmphtml.="<TR VALIGN=TOP>\n";
	$tmphtml.="<TD VALIGN=TOP BGCOLOR=\"\#0000FF\" WIDTH=\"15\%\">\n";
	$tmphtml.="     <STRONG><FONT COLOR=\"\#FFFFFF\">About</FONT></STRONG></TD>\n";
	$tmphtml.="<TD VALIGN=TOP WIDTH=\"85\%\" ALIGN=JUSTIFY>\n";

	$tmp="";
	$tmp=%{$ra_methods->{$methodLoc}}->{"des"} if (defined 
						       %{$ra_methods->{$methodLoc}}->{"des"});
	$Lskip=0;
	$Lskip=1                if (length($tmp)<5);
	$tmp=~s/[\s\.]*$//g;
	$tmp.=".<P ALIGN=JUSTIFY>";
	$tmphtml.=$tmp;
	if ($Lskip){
	    $tmp=$tmphtml="";
	}
    }
				# ABOUT
    if (defined $template{$methodLoc,"about"} &&
	length($template{$methodLoc,"about"}) > 1){
	if (length($tmphtml)<2){
	    $tmphtml= "<TR VALIGN=TOP>\n";
	    $tmphtml.="<TD VALIGN=TOP BGCOLOR=\"\#0000FF\" WIDTH=\"15\%\">\n";
	    $tmphtml.="     <STRONG><FONT COLOR=\"\#FFFFFF\">About</FONT></STRONG></TD>\n";
	    $tmphtml.="<TD VALIGN=TOP WIDTH=\"85\%\" ALIGN=JUSTIFY>\n";
	}
	$tmp="";
	$tmp=$template{$methodLoc,"about"}       if (defined $template{$methodLoc,"about"});
	$Lskip=0;
	$Lskip=1                if (length($tmp)<5);
	@tmp=split(/XYZ\tXYZ/,$tmp);
	$tmp="";
	$tmp.="   <UL>\n"      if ($#tmp > 1);
	$ct=0;
	foreach $txt (@tmp){
	    $txt=~s/^\s*|\s*$//g;$txt=~s/<BR>/\n<BR>     /g;
	    if ($#tmp>1) {
		$tmp.="   <LI>$txt</LI>\n";}
	    else {
		$tmp.="   $txt\n";}
	    ++$ct;
	}
	$tmp.="</UL>\n"        if ($#tmp > 1);
	$tmp=~s/<P>/<P ALIGN=JUSTIFY>/g;
	$tmphtml.=$tmp;
    }
    $html.=$tmphtml."\n".
	"</TD></TR>\n" if (! $Lskip);
    $html.="\n";

				# quote
    $html.="<TR VALIGN=TOP>\n";
    $html.="<TD VALIGN=TOP BGCOLOR=\"\#0000FF\" WIDTH=\"15\%\">\n";
    $html.="     <STRONG><FONT COLOR=\"\#FFFFFF\">Quote</FONT></STRONG></TD>\n";
    $html.="<TD VALIGN=TOP WIDTH=\"85\%\">\n";
    $tmp="no information given";
				# many papers ..
    if (%{$ra_methods->{$methodLoc}}->{"quote"}) {
	$tmp=%{$ra_methods->{$methodLoc}}->{"quote"};
	@tmp=split(/\s*\\n\s*/,$tmp);
#	$tmp=~s/^\s*|\s*$//g;$tmp=~s/<BR>/\n<BR>     /g;
	$tmp= "   <CITE>\n";
	$tmp.="   <OL type=\"i\">\n";
	foreach $paper (@tmp){
	    $paper=~s/::/:/g;
	    $tmp.="   <LI>$paper</LI>\n"; }
	$tmp.="   </OL>\n";
	$tmp.="   </CITE>\n";
    }
    $html.="     ".$tmp."</TD></TR>\n";
    $html.="\n";
				# done by
    $html.="<TR VALIGN=TOP>\n";
    $html.="<TD VALIGN=TOP BGCOLOR=\"\#0000FF\" WIDTH=\"15\%\">\n";
    $html.="     <STRONG><FONT COLOR=\"\#FFFFFF\">Authors</FONT></STRONG></TD>\n";
    $html.="<TD VALIGN=TOP WIDTH=\"85\%\">\n";
    $tmp="no information";
    if (%{$ra_methods->{$methodLoc}}->{"doneby"}){
	$tmp=%{$ra_methods->{$methodLoc}}->{"doneby"};
	$tmp="$tmp\n";}
    $html.="     ".$tmp."</TD></TR>\n";
    $html.="\n";
				# admin
    $html.="<TR VALIGN=TOP>\n";
    $html.="<TD VALIGN=TOP BGCOLOR=\"\#0000FF\" WIDTH=\"15\%\">\n";
    $html.="     <STRONG><FONT COLOR=\"\#FFFFFF\">Contact</FONT></STRONG></TD>\n";
    $html.="<TD VALIGN=TOP WIDTH=\"85\%\">\n";
    $tmp="   no information";
    if (%{$ra_methods->{$methodLoc}}->{"admin"}){
	$tmp=%{$ra_methods->{$methodLoc}}->{"admin"};
	if ($tmp=~/,/){
	    ($name,$mail)=split(/,/,$tmp);
	    $mail=~s/\\//g;
	    $tmp="   $name (<A HREF=\"mailto:$mail\">$mail</A>)\n";}
	else {
	    $tmp="   $tmp\n";}}
    $html.="     ".$tmp."</TD></TR>\n";
    $html.="\n";

				# version
    $html.="<TR VALIGN=TOP>\n";
    $html.="<TD VALIGN=TOP BGCOLOR=\"\#0000FF\" WIDTH=\"15\%\">\n";
    $html.="     <STRONG><FONT COLOR=\"\#FFFFFF\">Version</FONT></STRONG></TD>\n";
    $html.="<TD VALIGN=TOP WIDTH=\"85\%\">\n";
    $tmp="no information";
    if (%{$ra_methods->{$methodLoc}}->{"version"}){
	$tmp=%{$ra_methods->{$methodLoc}}->{"version"};
	$tmp="$tmp\n";}
    $html.="     ".$tmp."</TD></TR>\n";
    $html.="\n";

    return(1,"ok $SBR7",$html);
}				# end of wrtMethodDetail

#===============================================================================
sub wrtMethodTypes {
    local($fhoutLoc) = @_ ;
    local($SBR7,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   wrtMethodTypes             writes a summary of all method types (with local
#                               links
#                               
#       in:                     $fhoutLoc: filehandle
#                               
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
#    $SBR7=$packName.":"."wrtMethodTypes";
    $SBR7="wrtMethodTypes";

    $#tmpwrt=0;
				# ------------------------------
				# build up
    @tmpwrt=
	("<BR><BR>",
	 "<!-- ================================================================================ -->",
	 "<!-- beg: types  -->",
				# TOC entry with colour!
	 "<TABLE WIDTH=\"100%\">",
	 "<TR><TD VALIGN=TOP ALIGN=CENTER BGCOLOR=\"\#000080\">",
	 "<STRONG><FONT COLOR=\"\#FFFFFF\" SIZE=\"+3\">",
	 "<A NAME=\"list\"> List of all available prediction types</A>",
	 "</FONT></STRONG>",
	 "</TD></TR>",
	 "</TABLE>",
	 " ",
	 "<BR>",
	 "<TABLE CELLPADDING=2  WIDTH=\"100%\">",
	 "<TR>",
	 "<TD VALIGN=CENTER BGCOLOR=\"\#C0C0C0\" ALIGN=RIGHT>Type</TD>",
	 "<TD VALIGN=CENTER BGCOLOR=\"\#C0C0C0\" ALIGN=LEFT> Methods</TD>",
	 "</TR>\n"
	 );
    undef %tmp;
				# ------------------------------
				# for all categories
    foreach $type (@methodtype){
	$tmp="";
	$ct=0;
	foreach $method (split(/,/,$methodsLoc{$type})){
	    $methodAbbr=$method;
	    $methodAbbr=
		%{$ra_methods->{$method}}->{"abbr"} if (defined %{$ra_methods->{$method}}->{"abbr"});
	    ++$ct;
	    if ($ct>5 || $method eq "phd" || $method eq "prof"){
		$ct=1;
		$tmp.="<BR>";}

	    $tmp.="<A HREF=\"\#PX_about_".$method."\">".$methodAbbr."</A> \&nbsp\; ";
	}

	push(@tmpwrt,
	     "<TR>",
#	     "<TD VALIGN=CENTER BGCOLOR=\"\#0000FF\" ALIGN=RIGHT WIDTH=\"35\%\">",
	     "<TD VALIGN=CENTER BGCOLOR=\"\#0000FF\" ALIGN=RIGHT>",
	     "<STRONG><FONT COLOR=\"\#FFFFFF\">".%{$ra_methods->{"typetrans"}}->{$type},
	     "</FONT></STRONG></TD>",
	     "<TD> ".$tmp."</TD></TR>\n")   if (length($tmp)>0);
    }

				# ------------------------------
				# finish off
    push(@tmpwrt,
	 "</TABLE>",
	 "<!-- end: types  -->",
	 "<!-- ================================================================================ -->",
	 "<BR>"
	 );
    undef %tmp2; undef %tmp;
	    
				# ------------------------------
				# write
    foreach $tmp (@tmpwrt){
	print $fhoutLoc $tmp,"\n";
    }

    return(1,"ok $SBR7");
}				# end of wrtMethodTypes


#================================================================================ #
#                                                                                 #
#-------------------------------------------------------------------------------- #
# Predict Protein - a secondary structure prediction and sequence analysis system #
# Copyright (C) <2004> CUBIC, Columbia University                                 #
#                                                                                 #
# Burkhard Rost         rost@columbia.edu                                         #
# http://cubic.bioc.columbia.edu/~rost/                                           #
# Jinfeng Liu             liu@cubic.bioc.columbia.edu                             #
# Guy Yachdav         yachdav@cubic.bioc.columbia.edu                             #
#                                                                                 #
# This program is free software; you can redistribute it and/or modify it under   #
# the terms of the GNU General Public License as published by the Free Software   #
# Foundation; either version 2 of the License, or (at your option)                #
# any later version.                                                              #
#                                                                                 #
# This program is distributed in the hope that it will be useful,                 #
# but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY  #
# or FITNESS FOR A PARTICULAR PURPOSE.                                            #
# See the GNU General Public License for more details.                            #
#                                                                                 #
# You should have received a copy of the GNU General Public License along with    #
# this program; if not, write to the Free Software Foundation, Inc.,              #
# 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA                         #
#                                                                                 #
# Contact Information:                                                            #
#                                                                                 #
# predict_help@columbia.edu                                                       #
#                                                                                 #
# CUBIC   Columbia University                                                     #
# Department of Biochemistry & Molecular Biophysics                               #
# 630 West, 168 Street, BB217                                                     #
# New York, N.Y. 10032 USA                                                        #
# Tel +1-212-305 4018 / Fax +1-212-305 7932                                       #
#================================================================================ #
