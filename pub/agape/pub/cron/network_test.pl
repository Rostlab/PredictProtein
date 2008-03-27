#!/usr/local/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="sends out ping and traceroute to many machines\n".
    "     \t ";
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
				# ------------------------------
				# defaults
%par=(
      'exePing',        "/usr/etc/ping -L -c 10 -q ",
      'exeTraceroute',  "/usr/etc/traceroute ",
      'exeMail',        "/usr/sbin/Mail",
      '', "",
      );
@kwd=sort (keys %par);
$Ldebug=0;
$Lverb= 0;
@machine=
    (
     "tau.embl-heidelberg.de",
     "circinus.ebi.ac.uk",
     "gredos.cnb.uam.es",

     "md2.huji.ac.il",
     "morgan.angis.su.oz.au",
     "toy.bic.nus.edu.sg",

     "butane.chem.columbia.edu",

     "cs.uchicago.edu",
     "cse.ucsc.edu",
     "sprsgi.med.harvard.edu",
     "genomes.rockefeller.edu",
     "",
     );

%Lno_ping=
    (
     "tau.embl-heidelberg.de",
     "",
     "",
     "",
     );

@people=
    (
     "rost\@dodo.cpmc.columbia.edu",
#     "alan\@columbia.edu",
     );
				# ------------------------------
if ($#ARGV<1){			# help
    print  "goal: $scrGoal\n";
    print  "use:  '$scrName <auto|machines> (separated by comma) '\n";
    print  "opt:  \n";
				#      'keyword'   'value'    'description'
#    printf "%5s %-15s=%-20s %-s\n","","",   "x", "";
#    printf "%5s %-15s %-20s %-s\n","","",   "no value","";

    printf "%5s %-15s %-20s %-s\n","","dbg",   "no value",   "debug mode";
    printf "%5s %-15s %-20s %-s\n","","silent|-s","no value","no screen output";
    printf "%5s %-15s %-20s %-s\n","","verb|-s",  "no value","verbose";
    if (defined %par && $#kwd > 0){
	$tmp= sprintf("%5s %-15s  %-20s %-s\n","","-" x 15 ,"-" x 20,"-" x 30);
	$tmp.=sprintf("%5s %-15s  %-20s %-s\n","","other:","default settings: "," ");
	$tmp2="";
	foreach $kwd (@kwd){
	    next if (! defined $par{"$kwd"} || length($par{"$kwd"})<1 );
	    if    ($par{"$kwd"}=~/^\d+$/){
		$tmp2.=sprintf("%5s %-15s= %10d %9s %-s\n","",$kwd,$par{"$kwd"}," ","(def)");}
	    elsif ($par{"$kwd"}=~/^[0-9\.]+$/){
		$tmp2.=sprintf("%5s %-15s= %10.3f %9s %-s\n","",$kwd,$par{"$kwd"}," ","(def)");}
	    else {
		$tmp2.=sprintf("%5s %-15s= %-20s %-s\n","",$kwd,$par{"$kwd"},"(def)");} 
	} 
	print $tmp, $tmp2       if (length($tmp2)>1);
    }
    exit;}
				# initialise variables
#$fhin="FHIN";$fhout="FHOUT";
				# ------------------------------
				# read command line
foreach $arg (@ARGV){
#    next if ($arg eq $ARGV[1]);
    if    ($arg=~/^fileOut=(.*)$/)        { $fileOut=        $1;}
    elsif ($arg=~/^de?bu?g$/)             { $Ldebug=         1;
					    $Lverb=          1;}
    elsif ($arg=~/^verb(ose)?$|^\-v$/)    { $Lverb=          1;}
    elsif ($arg=~/^silent$|^\-s$/)        { $Lverb=          0;}
    elsif ($arg=~/^auto$/i)               { $Lauto=          1;}
    elsif ($arg=~/^\w+\.\w+$/i)           { $tmp=            $1;
					    $tmp=~s/\s//g;
					    @machineIn=split(/,/,$tmp);}

#    elsif ($arg=~/^=(.*)$/){ $=$1;}
    else {
	$Lok=0; 
	if (defined %par && $#kwd>0) { 
	    foreach $kwd (@kwd){ 
		if ($arg =~ /^$kwd=(.+)$/){$Lok=1;$par{"$kwd"}=$1;
					   last;}}}
	if (! $Lok){ print "*** wrong command line arg '$arg'\n";
		     exit;}}}
$Date=&sysDate();
$dateConv=&date_mdy2ymd($Date);


if (! defined $fileOut){
    $fileOut="NETtst_".$dateConv;
}

if (! $Ldebug){
				# STDOUT to file_scanOut
    open (STDOUT, ">".$fileOut)
	|| warn "*** WARN $scrName cannot open new fileout=$fileOut\n";
				# STDERR to file_scanErr
    open (STDERR, ">>".$fileOut)
	|| warn "*** WARN $scrName cannot open append fileout=$fileOut\n";
				# flush output
    $| = 1; }

				# --------------------------------------------------
				# mode auto: override any machine given
if ($Lauto) {
    @machineDo=@machine;
    print "-*- WARN default list of machines taken\n"
	if (defined @machineIn && $#machineIn>1);}

				# ------------------------------
				# (1) read file(s)
				# ------------------------------
foreach $machine (@machineDo){
    next if (! defined $machine);
    next if (length($machine)<5);

    foreach $exe ($par{"exePing"},$par{"exeTraceroute"}) {
				# skip some from ping
	next if ($exe =~ /ping/ && defined $Lno_ping{$machine});
				# do
	$cmd=$exe." ".$machine;
	print "\n";
	print "--- ", "-" x 80, "\n";
	print "--- $cmd\n";
	print "--- ", "-" x 80, "\n";
	system("$cmd");
    }
}

print "--- output in $fileOut\n" if (-e $fileOut && $Ldebug);

				# ------------------------------
				# send output file per mail
				# ------------------------------
foreach $email (@people) {
    $cmd="/usr/sbin/Mail -s traceroute_$dateConv $email < $fileOut";
    system("$cmd");
}
exit;


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
sub date_mdy2ymd {
    local($dateIn) = @_ ;
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   date_mdy2ymd                converts date from 'May 4, 1999' to 1999_05_04_hour
#       in:                     $date (e.g. from &sysDate)
#       out:                    1|0,msg,$date
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."date_mdy2ymd";
    return(0,"date not defined!",0) 
	if (! defined $dateIn);
    return(0,"date not valid, must be 'Mon DD, DDDD'",0) 
	if ($dateIn !~ /\w\w\w\s*,*\s*\d\d*\s*,*\s+\d\d\d\d/);
				# dissect
    ($m,$d,$y,$tmp)=split(/[\t\s,]+/,$dateIn);
    $monthNum=&date_monthName2num($m);
    $d="0".$d                   if (length($d)<2);
    return(1,"ok",$y."_".$monthNum."_".$y."_".$tmp);
}				# end  date_mdy2ymd

#===============================================================================
sub errSbr    {local($txtInLoc,$sbrNameLocy) = @_ ;
#-------------------------------------------------------------------------------
#   errSbr                      simply writes '*** ERROR $sbrName: $txtInLoc'
#-------------------------------------------------------------------------------
	       $sbrNameLocy=$sbrName if (! defined $sbrNameLocy);
	       $txtInLoc.="\n";
	       $txtInLoc=~s/\n\n+/\n/g;
	       return(0,"*** ERROR $sbrNameLocy: $txtInLoc");
}				# end of errSbr

#===============================================================================
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

#===============================================================================
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
sub sysDate {
#    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   sysDate                     returns $Date
#       out:                    $Date (May 30, 1998 59:39:03)
#-------------------------------------------------------------------------------

    @tmp=(			# HARD_CODED
	  "/home/rost/perl/ctime.pl",           # HARD_CODED
	  "/home/rost/pub/perl/ctime.pl",       # HARD_CODED
	  "/home/phd/server/scr/lib/ctime.pm"   # HARD_CODED
	  );
    foreach $tmp (@tmp) {
	next if (! -e $tmp && ! -l $tmp);
	$exe_ctime=$tmp;	# local ctime library
	last; }

    $Lok=0;
				# ------------------------------
				# get function
    if (defined &localtime) {
				# use system standard
	$Lok=1	                if (defined &ctime && &ctime);
				# use local library
	$Lok=1                  if (! $Lok && -e $exe_ctime);

	if (! $Lok) {		# search for it
	    $Lok=
		require($exe_ctime)
		    if (-e $exe_ctime); }
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




