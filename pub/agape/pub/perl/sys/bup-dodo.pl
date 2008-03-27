#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrIn=  "[auto|def|no_arg|dir_in]";
$scrGoal="backup of stuff from dodo\n".
    "     \t input:  ".$scrIn."\n".
    "     \t output: \n".
    "     \t need:   full path for input directories (NO Links)\n".
    "     \t \n".
    "     \t NOTE:  USED by crontab!\n".
    "     \t \n".
    "     \t ";
#  
# 
#------------------------------------------------------------------------------#
#	Copyright				        	2002	       #
#	Burkhard Rost		rost@columbia.edu			       #
#	CUBIC (Columbia Univ)	http://cubic.bioc.columbia.edu/   	       #
#       Dept Biochemistry & Molecular Biophysics			       #
#       650 West, 168 Street, BB217					       #
#	New York, NY 10032	http://www.columbia.edu/~rost/                 #
#				version 0.1   	Sep,    	2002	       #
#------------------------------------------------------------------------------#
#

$[ =1 ;				# count from one

				# ------------------------------
				# defaults
%par=(
      'dirWork',   "/dodo9/rost/bup/",
      '', "",			# 
      'extTar',    ".tar",
      'extGzip',   ".gz",
      '', "",			# 
      'exeSysTar',  "/sbin/tar",
      'exeSysGzip', "/usr/sbin/gzip",
      '', "",			# 
      '', "",			# 
      );
@kwd=sort (keys %par);

$Ldebug=0;
$Lverb= 1;
#$sep=   "\t";

$HOME="/home/rost/";

@dir2do=
    (
     $HOME."env/",

     $HOME."bin/",
     $HOME."etc/",
     $HOME."for/",
     $HOME."var/",

     $HOME."lion/",

     $HOME."nn/",
     $HOME."perl/",
     $HOME."phd/",
     $HOME."prof/",
     $HOME."topits/",
     $HOME."pub/",

     $HOME."mis/",
     $HOME."molbio/",
     
     "/dodo3/rost/current/",
     "/dodo3/rost/w/",

     );
    
				# ------------------------------
if ($#ARGV<1 ||			# help
	$ARGV[1] =~/^(-h|help|special)/){
    print  "goal: $scrGoal\n";
    print  "use:  '$scrName $scrIn'\n";
    print  "opt:  \n";
				#      'keyword'   'value'    'description'
    printf "%5s %-15s %-20s %-s\n","","auto",    "no value","uses default settings (does them all)";

    printf "%5s %-15s %-20s %-s\n","","def",     "no value","shows default settings";

    printf "%5s %-15s %-20s %-s\n","","time|est","no value","estimate time";
    printf "%5s %-15s %-20s %-s\n","","notime|noest","no value","do not estimate time";

    printf "%5s %-15s %-20s %-s\n","","zip(nozip)","no value","gzip it (or not)";
#    printf "%5s %-15s=%-20s %-s\n","","",   "x", "";
#    printf "%5s %-15s %-20s %-s\n","","",        "",         "continued";
#    printf "%5s %-15s %-20s %-s\n","","",   "no value","";

    printf "%5s %-15s %-20s %-s\n","","dbg",   "no value",   "debug mode";
    printf "%5s %-15s %-20s %-s\n","","silent|-s","no value","no screen output";
    printf "%5s %-15s %-20s %-s\n","","verb|-s",  "no value","verbose";
#    printf "%5s %-15s %-20s %-s\n","","noScreen", "no value","";
#    printf "%5s %-15s=%-20s %-s\n","","",   "x", "";
#    printf "%5s %-15s %-20s %-s\n","","",   "no value","";
				# special
    if (($#ARGV==1 && $ARGV[1]=~/^special/) ||
	($#ARGV>1 && $ARGV[1] =~/^(-h|help)/ && $ARGV[2]=~/^spe/)){
    }

    if (defined %par && $#kwd > 0){
	$tmp= sprintf("%5s %-15s  %-20s %-s\n","","-" x 15 ,"-" x 20,"-" x 30);
	$tmp.=sprintf("%5s %-15s  %-20s %-s\n","","other:","default settings: "," ");
	$tmp2="";
	foreach $kwd (@kwd){
	    next if (! defined $par{$kwd});
	    next if ($kwd=~/^\s*$/);
	    if    ($par{$kwd}=~/^\d+$/){
		$tmp2.=sprintf("%5s %-15s= %10d %9s %-s\n","",$kwd,$par{$kwd}," ","(def)");}
	    elsif ($par{$kwd}=~/^[0-9\.]+$/){
		$tmp2.=sprintf("%5s %-15s= %10.3f %9s %-s\n","",$kwd,$par{$kwd}," ","(def)");}
	    else {
		$tmp2.=sprintf("%5s %-15s= %-20s %-s\n","",$kwd,$par{$kwd},"(def)");} 
	} 
	print $tmp, $tmp2       if (length($tmp2)>1);
    }
    exit;}
				# initialise variables
#$fhin="FHIN";$fhout="FHOUT";
$#fileIn=      0;
$#dirIn=       0;
#$dirOut=       0;
$LshowDef=     0;
$Lauto=        0;
$LestimateTime=0;
$Ldozip=       1;
				# ------------------------------
				# read command line
foreach $arg (@ARGV){
#    next if ($arg eq $ARGV[1]);
    if    ($arg=~/^auto$/)                { $Lauto=          1;}

    elsif ($arg=~/^(def|set)$/)           { $LshowDef=       1;}
    elsif ($arg=~/^(time|est)$/)          { $LestimateTime=  1;}
    elsif ($arg=~/^no(time|est)$/)        { $LestimateTime=  0;}
    elsif ($arg=~/^(zip|gzip)$/)          { $Ldozip=         1;}
    elsif ($arg=~/^no(zip|gzip)$/)        { $Ldozip=         0;}

    elsif ($arg=~/^de?bu?g$/)             { $Ldebug=         1;
					    $Lverb=          1;}
    elsif ($arg=~/^verb(ose)?$|^\-v$/)    { $Lverb=          1;}
    elsif ($arg=~/^silent$|^\-s$/)        { $Lverb=          0;}
#    elsif ($arg=~/^=(.*)$/){ $=$1;}
    elsif (-d $arg)                       { push(@dirIn, $arg); }
    elsif (-e $arg)                       { push(@fileIn,$arg); }
    else {
	$Lok=0; 
	if (defined %par && $#kwd>0) { 
	    foreach $kwd (@kwd){ 
		if ($arg =~ /^$kwd=(.+)$/){$Lok=1;$par{$kwd}=$1;
					   last;}}}
	if (! $Lok){ print "*** wrong command line arg '$arg'\n";
		     exit;}}}

if ($LshowDef){
    printf "--- %-15s %-s\n","parameters",":";
    foreach $kwd (keys %par){
	next if (length($kwd)<1);
	printf "PAR %-15s %-s\n",$kwd,$par{$kwd};
    }
    printf "--- %-15s %-s\n","directories 2 do",":";
    print join("\n",@dir2do);
#    print join("\n",@dir2do,"\n");
    exit;
}

if (! $Lauto){
    if    (! $#dirIn){
	print "*** ERROR $scrName: no 'auto' no valid input directory!";
	print "$scrIn\n";
	exit;}
    elsif ($#dirIn==1 && ! -d $dirIn[1]){
	print "*** ERROR $scrName: no 'auto' no valid input directory($dirIn[1] missing)!";
	print "$scrIn\n";
	exit;}
}
else {
    @dirIn=@dir2do;
}
				# ------------------------------
				# (1) estimate time
				# ------------------------------
if ($LestimateTime){
    $timeBeg=time;
    $res{"size","total"}=0;
    foreach $dirIn (@dirIn){
	$tmp=`du -k $dirIn`;
	@tmp=split(/\n/,$tmp);
	$#tmpdir=$#tmpsize=0;
	$ct=0;
	foreach $tmp (@tmp){
	    @tmp2=split(/[\s\t]+/,$tmp);
	    next if ($dirIn ne $tmp2[2]);
	    push(@tmpdir, $tmp2[2]);
	    push(@tmpsize,$tmp2[1]);
	}
	$res{"size",$dirIn}=0;
	foreach $size (@tmpsize){
	    $size=~s/\D//g;
	    $res{"size",$dirIn}+=$size;
	}
	$res{"size","total"}+=$res{"size",$dirIn};
	print "--- dirin=$dirIn, size=",$res{"size",$dirIn},"\n"
	    if ($Ldebug);
    }
    print "--- total size=",$res{"size","total"},"\n"
	if ($Ldebug);
}

				# ------------------------------
				# (2) tar directories
				# ------------------------------
$ctdir=0;
$sizeTotal=$res{"size","total"} if ($LestimateTime);
$sizesofar=0;

if (! -d $par{"dirWork"} && ! -l $par{"dirWork"}){
    $cmd="mkdir ".$par{"dirWork"};
    print "--- system '$cmd'\n" if ($Ldebug);
    system("$cmd");
}
$par{"dirWork"}.="/"            if ($par{"dirWork"}!~/\/$/);

@fileOut=();
foreach $dirIn (@dirIn){
    ++$ctdir;

    if ($LestimateTime){
	$size=$res{"size",$dirIn};
	$sizesofar+=$size;
	$perc=100*(1-$sizesofar/$sizeTotal);
	$perc=~s/(\...).*$/$1/g;
	($Lok,$tmp,$txt)=
	    &fctRunTimeFancy($dirIn,$perc,1);
	print $txt;
    }
    elsif ($Lverb){
	print "--- $scrName: working on dirIn=$dirIn!\n";
    }
				# go to parent of dir
    $dirparent=$dirIn;
    $dirparent=~s/\/$//g;
    $dirparent=~s/[^\/]*$//g;
#    $dirthis=$1;
    $dirthis=$dirIn;
    $dirthis=~s/$dirparent//;
    $dirthis=~s/^\/|\/$//g;
    $dirparent=~s/\/$//g;
    
    if ($dirthis=~/\// || length($dirthis)<1){
	print "*** ERROR $scrName dirthis=$dirthis, dirin=$dirIn, dirparent=$dirparent\n";
	exit;
    }
#    print "xx in=$dirIn, this=$dirthis, parent=$dirparent\n";

    $Lok=chdir($dirparent);
    if (! $Lok) { 
	print "-*- WARN Failed to cd to directory '$dirparent' (parent for $dirIn)\n";
	next; }

    $filetar=$par{"dirWork"}.$dirthis.$par{"extTar"};
    $cmd= $par{"exeSysTar"}." -cf ".$filetar." ";
    $cmd.=$dirthis."/";
    print "--- system '$cmd'\n" if ($Ldebug);
    system("$cmd");

    if (! -e $filetar){
	print "*** ERROR $scrName: did not produce $filetar\n";
	print "dirIn=$dirIn, dirthis=$dirthis, dirparent=$dirparent\n";
	exit;}
    $filetmp=$filetar;
    if ($Ldozip){
	$filetmp=$filetar.$par{"extGzip"};
	$cmd= $par{"exeSysGzip"}." -f ".$filetar;
	print "--- system '$cmd'\n" if ($Ldebug);
	system("$cmd");
	if (! -e $filetmp){
	    print "-*- WARN did not produce zipped version of $filetar\n";
	    $filetmp=$filetar;
	}
    }
    push(@fileOut,$filetmp);
}

if ($LestimateTime){
    $perc=0;
    ($Lok,$tmp,$txt)=
	&fctRunTimeFancy($scrName,$perc,1);
    print $txt;
}
				# ------------------------------
				# (3) write output
				# ------------------------------
if ($Lverb){
    $ct=0;
    print "--- ".$#fileOut." tar files produced, they are:\n";
    $sum=0;
    foreach $file (@fileOut){
	++$ct;
	@tmp=stat $file;
	$sizek=$sizem=0;
	$size= int($tmp[8]);
	$sizek=int($tmp[8]/1000)    if ($size > 1000);
	$sizem=int($sizek/1000)     if ($size > 1000000); 
	if    ($sizek && $sizem){
	    $sizek=$sizek-$sizem*1000;
	    $sizek="0" x (3-length($sizek)) .$sizek;
	    printf "--- %3s %3s,%3s K   %-s\n",$ct,$sizem,$sizek,$file;}
	elsif ($sizek){
	    printf "--- %3s %3s %3s K   %-s\n",$ct," ",$sizek,$file;}
	else {
	    printf "--- %3s %3s %3s %3d %-s\n",$ct," "," ",$size,$file;}
	$sum+=$size;
    }
    $size=$sum;
    $sizek=int($size/1000)    if ($size > 1000);
    $sizem=int($sizek/1000)     if ($size > 1000000); 
    if    ($sizek && $sizem){
	$sizek=$sizek-$sizem*1000;
	$sizek="0" x (3-length($sizek)) .$sizek;
	printf "--- %3s %3s,%3s K   %-s\n"," ",$sizem,$sizek,"SUM";}
    elsif ($sizek){
	printf "--- %3s %3s %3s K   %-s\n"," "," ",$sizek,"SUM";}
    else {
	printf "--- %3s %3s %3s %3d %-s\n"," "," "," ",$size,"SUM";}
}
exit;


#===============================================================================
sub fctRunTimeFancy {
    local($nameLoc,$percLoc,$LdoTimeLoc) = @_ ;
    local($sbrName,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   fctRunTimeFancy             fancy way to write run time estimate
#       NEED:                   &fctSeconds2time
#       GLOBAL in/out:          $timeBegLoc
#                               
#       in:                     $nameLoc=    name of directory or file or job
#       in:                     $percLoc=    percentage of job done so far
#       in:                     $LdoTimeLoc= 1-> estimate remaining runtime
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."fctRunTimeFancy";
				# check arguments
    return(&errSbr("not def nameLoc!")) if (! defined $nameLoc);
    return(&errSbr("not def percLoc!")) if (! defined $percLoc);
    $LdoTimeLoc=0                       if (! defined $LdoTimeLoc);
#    return(&errSbr("not def !"))          if (! defined $);

				# local parameter
#    $par{"fctRunTimeFancy","maxdot"}=72 if (! defined $par{"fctRunTimeFancy","maxdot"});
    $par{"fctRunTimeFancy","maxdot"}=60 if (! defined $par{"fctRunTimeFancy","maxdot"});
    $tmpformatLoc="%-".$par{"fctRunTimeFancy","maxdot"}."s"
	if (! defined $tmpformatLoc);

    $nameLoc=~s/\/$//g;
    $nameLoc=~s/^.*\///g;
    $tmpdots=int((100-$percLoc)*$par{"fctRunTimeFancy","maxdot"}/100);

				# estimate remaining run time?
    if ($LdoTimeLoc){
	$timeNowLoc=time;
	$timeBegLoc=$timeBeg    if (! defined $timeBegLoc && defined $timeBeg);
	$timeBegLoc=0           if (! defined $timeBegLoc);
	$timeRunLoc=$timeNowLoc-$timeBegLoc;

	if ($percLoc>0 && $timeNowLoc ne $timeBegLoc) {
	    $timeTotLoc=int($timeRunLoc*100/(100-$percLoc));
	    $timeLeftLoc=$timeTotLoc-$timeRunLoc;
	    $timeTxtLoc=
		&fctSeconds2time($timeLeftLoc); 
				# remove leading 0h 0m if perc < 20
	    if    ($percLoc > 80 && $timeTxtLoc=~/^0+\:0+\:/){
		$Lpurge_timehm_loc=1;
		$timeTxtLoc=~s/^0+\:0+\://g;}
				# remove leading 0h 0m if perc < 20
	    elsif ($percLoc > 80 && $timeTxtLoc=~/^0+\:/){
		$Lpurge_timeh_loc=1;
		$timeTxtLoc=~s/^0+\://g;}
	    elsif (defined $Lpurge_timehm_loc && $Lpurge_timehm_loc){
		$timeTxtLoc=~s/^0+\:0+\://g;}
	    elsif (defined $Lpurge_timeh_loc && $Lpurge_timeh_loc){
		$timeTxtLoc=~s/^0+\://g;}

	    @tmpLoc=split(/:/,$timeTxtLoc); 
	    foreach $tmp (@tmpLoc){
		$tmp=~s/^0//g;}
	    if    ($#tmpLoc==3){
		$tmptime=sprintf("%3s %3s%3s",
				 $tmpLoc[1]."h",$tmpLoc[2]."m",$tmpLoc[3]."s");}
	    elsif ($#tmpLoc==2){
		$tmptime=sprintf("%3s%3s",
				 $tmpLoc[1]."m",$tmpLoc[2]."s");}
	    elsif ($#tmpLoc==1){
		$tmptime=sprintf("%3s",
				 $tmpLoc[1]."s");}
	    else {
		$tmptime=$timeTxtLoc;}
	}
	elsif ($percLoc==0) {
	    $tmptime="done";
	}
	else {
	    $tmptime="??";
	}
    }
    else {
	$tmptime="";}
				# write
    $tmp=
	sprintf("%-15s %3d%-1s |".$tmpformatLoc."| %-s\n",
		substr($nameLoc,1,15),
		int($percLoc),
		"%",
		"*" x $tmpdots,
		$tmptime
		);
    return(1,"ok $sbrName",$tmp);
}				# end of fctRunTimeFancy

#===============================================================================
sub fctSeconds2time {
    local($secIn) = @_ ;
    local($SBR9,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   fctSeconds2time             converts seconds to hours:minutes:seconds
#       in:                     seconds
#       out:                    05:13:50
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $SBR9=$tmp."fctSeconds2time";

    $minTmp=  int($secIn/60);
    $seconds= ($secIn - $minTmp*60); $seconds=int($seconds);
    $hours=   int($minTmp/60);       $hours=  int($hours);
    $minutes= ($minTmp - $hours*60); $minutes=int($minutes);

    $seconds="0".$seconds if (length($seconds)==1);
    $minutes="0".$minutes if (length($minutes)==1);
    $hours=  "0".$hours   if (length($hours)==1);

    return("$hours".":".$minutes.":".$seconds);
}				# end of fctSeconds2time

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

