#!/usr/local/bin/perl -w
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

				# ------------------------------
if ($#ARGV<1){			# help
    print  "goal: $scrGoal\n";
    print  "use:  $0 template_file.html\n";
    print  " or:  $0 template_*.html\n";
    print  "note: nedss envMeta.pm to set parameters!\n";
    print  "opt:  \n";
				#      'keyword'   'value'    'description'
    printf "%5s %-10s=%-10s %-s\n","","fileOut", "x",       "name of output file (def=file.html from template_file.html)";
#    printf "%5s %-10s=%-10s %-s\n","","",   "x", "";
#    printf "%5s %-10s %-10s %-s\n","","",   "no value","";

    printf "%5s %-10s %-10s %-s\n","","dbg",   "no value",   "debug mode";
    printf "%5s %-10s %-10s %-s\n","","silent|-s","no value","no screen output";
    printf "%5s %-10s %-10s %-s\n","","verb|-s",  "no value","verbose";
    exit;}

				# ------------------------------
				# initialise variables

require "envMeta.pm";		# HARD_CODED

				# ------------------------------
				# define parameters
&iniEnv();
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
#    elsif ($arg=~/^=(.*)$/){ $=$1;}
    elsif (-e $arg)                       { push(@fileIn,$arg); }
    else { print "*** wrong command line arg '$arg'\n";
	   exit;}}

$fileIn=$fileIn[1];
die ("missing input $fileIn\n") if (! -e $fileIn);

				# ------------------------------
				# (1) read file(s)
				# ------------------------------
foreach $fileIn (@fileIn){
    if (! defined $fileOut || $#fileIn > 1) {
	$fileOut=$fileIn; $fileOut=~s/^.*\///g;
	$fileOut=~s/template[_\-\.]?//g;
	if (-e $fileOut) {
	    $tmp=$fileOut."_".$$;
	    print "-*- WARN fileOut=$fileOut exists, is moved to $tmp\n";
	    system("\\mv $fileOut $tmp");}}
    print "--- $scrName: now in=$fileIn->$fileOut\n" if ($Lverb);
    
    open($fhin,$fileIn)       || die "*** $scrName ERROR opening in=$fileIn";
    open($fhout,">".$fileOut) || die "*** $scrName ERROR opening out=$fileOut";
    
    while (<$fhin>) {
	$line=$_;
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
		    print "xx1  old=$old, new=$new, line=$line\n";
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
			print "xx2  old=$old, new=$new, line=$line\n";
			$line=~s/$old/$new/ig;
			print "--- change line to=$line\n" if ($Ldebug); }}}}
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
		    "<TR><TD ALIGN=RIGHT><STRONG>$method</STRONG></TD>",
		    "<TD>   </TD>",
		    "$tmp\n"
			if (length($tmp)>0);
	    }
	    $line="";
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
