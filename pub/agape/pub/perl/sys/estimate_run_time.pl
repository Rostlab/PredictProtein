#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="reads list gets stat: how many files done not\n".
    "     \t input: *list dir=dir_with_output ext=ext_for_output\n".
    "     \t \n".
    "     \t ";
#  
# 
#------------------------------------------------------------------------------#
#	Copyright				        	2000	       #
#	Burkhard Rost		rost@columbia.edu			       #
#	CUBIC (Columbia Univ)	http://cubic.bioc.columbia.edu/   	       #
#       Dept Biochemistry & Molecular Biophysics			       #
#       630 West, 168 Street						       #
#	New York, NY 10032	http://www.columbia.edu/~rost/                 #
#				version 0.1   	Sep,    	2000	       #
#------------------------------------------------------------------------------#
#

$[ =1 ;				# count from one

#$par{"dirData"}=         "/home/eva/server/data/";
				# ------------------------------
				# defaults
%par=(
      '', "",			# 
      );
@kwd=sort (keys %par);
$Ldebug=0;
$Lverb= 1;

				# ------------------------------
if ($#ARGV<3 ||			# help
	$ARGV[1] =~/^(-h|help|special)/){
    print  "goal: $scrGoal\n";
    print  "use:  '$scrName '\n";
    print  "opt:  \n";
				#      'keyword'   'value'    'description'
    printf "%5s %-15s=%-20s %-s\n","","fileOut", "x",       "name of output file";
#    printf "%5s %-15s=%-20s %-s\n","","",   "x", "";
#    printf "%5s %-15s %-20s %-s\n","","",        "",         "continued";
#    printf "%5s %-15s %-20s %-s\n","","",   "no value","";

    printf "%5s %-15s %-20s %-s\n","","loop",  "no value","either loop only or loop=N (sec to loop)";
    printf "%5s %-15s %-20s %-s\n","","wrt",   "no value","write out list of missing";

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
$fhin=    "FHIN";
$fhout=   "FHOUT";
$#fileIn= 0;
$dirOut=$extOut=0;
				# ------------------------------
				# read command line
$Lloop=        0;
$timeLoop=   300;
$timeLoop=   300;
$numLoop=     12;
$Lwrtmissing=  0;

foreach $arg (@ARGV){
#    next if ($arg eq $ARGV[1]);
    if    ($arg=~/^fileOut=(.*)$/i)       { $fileOut=        $1;}
    elsif ($arg=~/^de?bu?g$/)             { $Ldebug=         1;
					    $Lverb=          1;}
    elsif ($arg=~/^verb(ose)?$|^\-v$/)    { $Lverb=          1;}
    elsif ($arg=~/^silent$|^\-s$/)        { $Lverb=          0;}
    elsif ($arg=~/^dir=(.*)$/)            { $dirOut=         $1;}
    elsif ($arg=~/^ext=(.*)$/)            { $extOut=         $1;}
    elsif ($arg=~/^loop$/)                { $Lloop=          1;}
    elsif ($arg=~/^(wrt|missi?n?g?)$/)    { $Lwrtmissing=    1;}
    elsif ($arg=~/^loop=(.*)$/)           { $timeLoop=       $1;
					    $Lloop=          1;}
#    elsif ($arg=~/^=(.*)$/){ $=$1;}
    elsif (-e $arg)                       { push(@fileIn,$arg); }
    else {
	$Lok=0; 
	if (defined %par && $#kwd>0) { 
	    foreach $kwd (@kwd){ 
		if ($arg =~ /^$kwd=(.+)$/){$Lok=1;$par{$kwd}=$1;
					   last;}}}
	if (! $Lok){ print "*** wrong command line arg '$arg'\n";
		     exit;}}}

$fileIn=$fileIn[1];
die ("*** ERROR $scrName: missing input $fileIn!\n") 
    if (! -e $fileIn);
if (! defined $fileOut){
    $tmp=$fileIn;
    $tmp=~s/^.*\///g;
    $fileOutMissing="Outmissing-".$tmp;}
else {
    $fileOutMissing=$fileOut;}

die ("*** ERROR $scrName: didnt understand dirOut(where will the output go)\n") if (! $dirOut);
die ("*** ERROR $scrName: didnt understand extOut(extension of output file)\n") if (! $extOut);

				# ------------------------------
				# (1) read file(s)
				# ------------------------------

$dirOut.="/"                     if ($dirOut !~/\/$/);

$ctfile=0;
$ctwant=$ctok=0;
$#fileAll=0;
undef %missing;
foreach $fileIn (@fileIn){
    ++$ctfile;
    if (! -e $fileIn){print "-*- WARN $scrName: no fileIn=$fileIn\n";
		      next;}
    if ($Lverb){
	print "--- $scrName: working on fileIn=$fileIn!\n";
#	printf 
#	    "--- $scrName: working on %-25s %4d (%4.1f perc of job)\n",
#	    $fileIn,$ctfile,(100*$ctfile/$#fileIn);
    }
    open($fhin,$fileIn) || die "*** $scrName ERROR opening fileIn=$fileIn!";
#    if (! $Lok){print "*** $scrName: failed to open fileIn=$fileIn\n";
#		next;}
    while (<$fhin>) {
	$_=~s/\n//g;
#	$_=~s/^.*\///g;		# purge directories

#	next if ($_=~/^\#/);	# skip comments
#	next if ($_=~/^id/);	# skip names

#	$_=~s/\#.*$//g;		# purge after comment
	$_=~s/\s//g;		# purge blanks
	$file=$_;
	push(@fileAll,$file);
	++$ctwant;
	$id=$_;
	$id=~s/^.*\///g;
	$id=~s/\..*$//g;
	$fileOut=$dirOut.$id.$extOut;
	$fileOutGzip=$fileOut.".gz";
	if    (-e $fileOut || -l $fileOut  ||
	       -e $fileOutGzip || -l $fileOutGzip){
	    ++$ctok;
	}
	elsif ($Lwrtmissing){
	    $missing{$file}=1;
	}
	if ($Lloop){
	    $fileOut{$file}=    $fileOut;
	    $fileOutGzip{$file}=$fileOutGzip;
	}
    }
    close($fhin);
}

if ($Lloop && $ctok < $ctwant){
    $timebeg=time();
    printf 
	"--- run %3d (%6d s) okP=%6.1f cumN=%5d\n",
	1,0,100*$ctok/$ctwant,$ctok if ($Lverb);
    $ctok[1]=   $ctok;
    $ctokcum[1]=$ctok;
    undef %missing;
    foreach $it (2..$numLoop){
	sleep($timeLoop);
	$ctok=0;
	foreach $file (@fileAll){
	    if (-e $fileOut{$file}     || -l $fileOut{$file} ||
		-e $fileOutGzip{$file} || -l $fileOutGzip{$file}){
		++$ctok;
	    }
	    elsif ($Lwrtmissing){
		$missing{$file}=1;
	    }
	}
	$ctokcum[$it]=$ctok;
	$ctok[$it]=   $ctok-$ctokcum[$it-1];
	$ctokcum=     $ctokcum[$it]-$ctokcum[1];
	$timedifnow=  time()-$timebeg;
	printf 
	    "--- run %3d (%6d s) okP=%6.1f +N=%3d ave1=%6.3f cumN=%5d cumAve=%6.3f\n",
	    $it,($it-1)*$timeLoop,100*$ctokcum[$it]/$ctwant,$ctok[$it],($ctok[$it]/$timeLoop),
	    $ctokcum,($ctokcum/$timedifnow)
		if ($Lverb);
	last if ($ctokcum[$it]>=$ctwant);
    }
    $timeend=time();
    $timedif=$timeend-$timebeg;
				# done in time checked
    $ctdone=            $ctokcum[$numLoop]-$ctokcum[1];
    $time_need_per=     $timedif/$ctdone;
    $ct2do=             $ctwant-$ctokcum[$numLoop];
    $time_remain=       int($time_need_per*$ct2do);
    $hours_remain=      &fctSeconds2time($time_remain);
}

				# ------------------------------
				# (2) write list of missing
				# ------------------------------
if ($Lwrtmissing){
    open($fhout,">".$fileOutMissing) || warn "*** $scrName ERROR creating fileOutMissing=$fileOutMissing";
    foreach $file (@fileAll){
	next if (! defined $missing{$file});
	print $fhout $file,"\n";
    }
    close($fhout);
}
				# ------------------------------
				# (3) stat
				# ------------------------------
if (! $Lloop){
    system("date");
    printf "--- wanted: %6d\n",    $ctwant;
    printf "--- found:  %6d %-s\n",$ctok,"(dir=".$dirOut.", ext=".$extOut.")";
    printf "--- percok: %6.1f\n",  100*($ctok/$ctwant);
    printf "--- missing:%-s\n",    $fileOutMissing if ($Lwrtmissing);
}
else {
    system("date");
    printf "--- wanted:     %6d\n",      $ctwant;
    printf "--- found:      %6d %-s\n",  $ctokcum[$numLoop],"(dir=".$dirOut.", ext=".$extOut.")";
    printf "--- missing:    %6d\n",      $ct2do;
    printf "--- done:       %6d %-s\n",  $ctdone,"(in ".$timedif." secs)";
    
    
    printf "--- percok beg: %6.1f\n",    100*($ctokcum[1]/$ctwant);
    printf "--- percok end: %6.1f\n",    100*($ctokcum[$numLoop]/$ctwant);
    printf "--- test ran:   %6d\n",      $timedif;
    printf "--- time4one:   %6.3f\n",    $time_need_per;
    printf "--- time2do:    %10s %d s\n",$hours_remain,$time_remain;
    printf "--- missing:    %-s\n",      $fileOutMissing if ($Lwrtmissing);
}

exit;


#==============================================================================
sub fctSeconds2time {
    local($secIn) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   fctSeconds2time             converts seconds to hours:minutes:seconds
#       in:                     seconds
#       out:                    05:13:50
#-------------------------------------------------------------------------------
    $sbrName="lib-comp:"."fctSeconds2time";$fhinLoc="FHIN"."$sbrName";
    $minTmp=  int($secIn/60);
    $seconds= ($secIn - $minTmp*60); $seconds=int($seconds);
    $hours=   int($minTmp/60);       $hours=  int($hours);
    $minutes= ($minTmp - $hours*60); $minutes=int($minutes);

    $seconds="0".$seconds if (length($seconds)==1);
    $minutes="0".$minutes if (length($minutes)==1);
    $hours=  "0".$hours   if (length($hours)==1);
    return($hours.":".$minutes.":".$seconds);
}				# end of fctSeconds2time

#===============================================================================
sub htmlIndex {
    local($dirInLoc,$dirPublic_html_loc) = @_ ;
    local($SBR3,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   htmlIndex                   makes index of WWW directory: output in HTML
#       in:                     $dirInLoc:           full path to directory
#       in:                     $dirPublic_html_loc: full path to HOME dir, 
#                                                    needed to find icons
#                               
#       in GLOBAL:              $par{"dirXchDo"."eval".$type}
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
#    $SBR3=$packName.":"."htmlIndex";
    $SBR3="htmlIndex";
    $fhinLoc="FHIN_"."htmlIndex";$fhoutLoc="FHOUT_"."htmlIndex";
				# check arguments
    return(&errSbr("not def dirInLoc!",  $SBR3)) if (! defined $dirInLoc);
#    return(&errSbr("not def !",$SBR3)) if (! defined $);

    return(&errSbr("no dirIn=$dirInLoc!",$SBR3)) if (! -d $dirInLoc && 
						     ! -l $dirInLoc && 
						     ! -e $dirInLoc);

				# ------------------------------
				# find icon dir
    if (! defined $dirPublic_html_loc){
	$dirPublic_html_loc=$dirInLoc;
	$dirPublic_html_loc=~s/(eva\/).*$/$1/g;
    }
    $dirTmp=$dirInLoc;
    $dirTmp.="/"                if ($dirTmp !~ /\/$/);
    $dirTmp=~s/$dirPublic_html_loc//g;
    $dirTmp=substr($dirTmp,2)   if ($dirTmp =~ /^\//);
    $dirTmp=~s/[^\/]*(\/)/..$1/g;
    $dirTmp.="Dicon/";
				# ------------------------------
				# read directory
    opendir ($fhinLoc,$dirInLoc) || return(&errSbr("failed opening dirInLoc=$dirInLoc!",$SBR3));
    @tmp=readdir($fhinLoc);
    closedir($fhinLoc);
    $#tmp2=0;
    foreach $tmp (@tmp){
	next if ($tmp =~ /^\./);        # starting with '.'
	push(@tmp2,$tmp);
    }
    @tmp=@tmp2; $#tmp2=0;
				# open output file
    $dirInLoc.="/"              if (length($dirInLoc)>1 && $dirInLoc !~ /\/$/);

    $fileOutLoc=$dirInLoc."index.html";
				# ------------------------------
				# write header for index file
    open($fhoutLoc,">".$fileOutLoc) || return(&errSbr("fileOutLoc=$fileOutLoc, not created",$SBR3));
    $dirRelative=$dirInLoc;
    $dirRelative=~s/\/$//g;
    $dirRelative=~s/^.*\///g;
    print $fhoutLoc
	"<HTML>\n",
	"<HEAD><TITLE>INDEX ".$dirRelative."</TITLE></HEAD>\n",
	"<BODY>\n",
	"<H1>Index for directory ".$dirRelative."</H1>\n",
	"<BR>",
	"<IMG SRC=\"".$dirTmp."mis_hand_up.gif\">","&nbsp\;",
	"<STRONG><A HREF=\"../\">move one level up</A></STRONG><BR>\n",
	"<P>";
				# sort
    @tmp=sort(@tmp);
				# ------------------------------
				# write data for index file
    foreach $tmp (@tmp){
	next if ($tmp=~/^index.html/);
	if    (-d $dirInLoc.$tmp){
	    print $fhoutLoc
		"<IMG SRC=\"".$dirTmp."mis_dir.gif\">","&nbsp\;",
		"<A HREF=\"$tmp\">".$tmp."</A><BR>\n";}
	elsif (-e $dirInLoc.$tmp){
	    print $fhoutLoc
		"<IMG SRC=\"".$dirTmp."mis_file.gif\">","&nbsp\;",
		"<A HREF=\"$tmp\">".$tmp."</A><BR>\n";}
	else {
	    print $fhoutLoc
		"<IMG SRC=\"".$dirTmp."mis_link.gif\">","&nbsp\;",
		"<A HREF=\"$tmp\">".$tmp."</A><BR>\n";}
    }
    print $fhoutLoc
	"<P>\n",
	"<IMG SRC=\"".$dirTmp."mis_back.gif\">","&nbsp\;",
	       "<STRONG><A HREF=\"../\">move one level up</A></STRONG><BR>\n",
	"</BODY>\n",
	"</HTML>\n";
    close($fhoutLoc);
				# ------------------------------
				# make sure it is readable
    $cmd="chmod +r $fileOutLoc";
    ($Lok,$msg)=
	&sysRunProg($cmd,0,
		    0);         &assPrtWarn("failed system '$cmd'\n".$msg,$SBR3) if (! $Lok);

    return(1,"ok $SBR3");
}				# end of htmlIndex

#======================================================================
sub sysRunProg {
    local ($cmd,$fileScrLoc,$fhErrLoc) = @_ ;
    $[ =1;
#-------------------------------------------------------------------------------
#   sysRunProg                  pipes arguments into $prog, and cats the output
#                               from $prog into a file
#       in:                     $cmd,$fileScrLoc,$fhError
#       in:                     $cmd='prog,arg1,arg2' 
#       in:                          where prog is the program, e.g. 'wc -l, file1,file2'
#       in:                     $fileScrLoc     is the output file
#       in:                        NOTE: if not defined: buffered to STDOUT
#       in:                      = 0            to surpress writing
#       in:                     $fhError        filehandle for ERROR writing
#                                  NOTE: to STDOUT if not defined
#       in:                      = 0            to surpress writing
#       out:                    0|1,message
#       err:                    ok -> 1,ok | err -> 0,message
#-------------------------------------------------------------------------------
    $sbrName="lib-sys:sysRunProg";
    return(0,"*** ERROR $sbrName: argument program ($cmd) not defined\n") 
	if (! defined $cmd || length($cmd)<1);
    $fhErrLoc=0                 if (! defined $fhErrLoc);
    $fileScrLoc=0               if (! defined $fileScrLoc);

				# ------------------------------
				# dissect arguments
    ($prog,@arg)=split(/,/,$cmd);
    if ($fhErrLoc) {
	print $fhErrLoc 
	    "--- $sbrName: system fileOut=$fileScrLoc, cmd=\n$prog\n";}
				# ------------------------------
				# pipe output into file?
    $Lpipe=0;
    $Lpipe=1                    if ($fileScrLoc);
				# hack br: 08-98 to avoid pipe pipe, i.e.
				#          prog="cmd > file" -> 'cmd > file | cat >> filescreen' fails
    $Lpipe=0                    if ($prog =~ /\s+>>?\s+\S+\s*$/);
    $prog.=" | cat >> $fileScrLoc " if ($Lpipe);
#    print "$cmd\n";exit;
				# ------------------------------
				# opens cmdtmp into pipe
    open (CMD, "|$prog") || 
	warn "*** $sbrName cannot run program '$prog $arg'";
				# get input arguments (< arg)
    foreach $tmp (@arg) {
	$tmp=~s/\n|^\s*|\s*$//; # delete end of line, and leading blanks 
	print CMD "$tmp\n" ;}
    close (CMD) ;		# upon closing: cmdtmp < @out_command executed    
    return(1,"ok $sbrName");
}				# end of sysRunProg

#===============================================================================
sub wrtRankHtml_indexOld {
    local($typeLoc) = @_ ;
    local($SBR5,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   wrtRankHtml_indexOld                       
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR5=    "wrtRankHtml_indexOld";
    $fhinLoc= "FHIN_".$SBR5;
    $fhoutLoc="FHOUT_".$SBR5;

				# ------------------------------
				# read directory with all old common
				# ------------------------------

    $dir=$par{"dirWebResBupCommon".$typeLoc};

    opendir ($fhinLoc,$dir) ||
	return(&errSbr("failed opening dirWebResBupCommon$typeLoc=".$dir."!",$SBR5));
    @tmp=readdir($fhinLoc);
    closedir($fhinLoc);

				# expected file:
    $filecommon=$par{"fileOutWebResRank".$typeLoc.1};
    $filecommon=~s/^.*\///g;
    $#tmp2=0;
    $dir.="/"                   if ($dir !~ /\/$/);
    foreach $tmp (@tmp){
	next if ($tmp =~ /^\./);        # starting with '.'
	next if ($tmp=~/index/);
	$tmp2=$dir.$tmp."/".$filecommon;
	$tmp3=$tmp."/".$filecommon;
				# WATCH it: here some existence required!!!
	push(@tmp2,$dir.$tmp3)
	    if (-e $tmp2);
    }

				# ------------------------------
				# now write index file
				# ------------------------------

    $fileOutLoc= $par{"dirWebResBupCommon".$typeLoc};
    $fileOutLoc.="/"            if ($fileOutLoc !~ /\/$/);
    $fileOutLoc.="index.html";

    open($fhoutLoc,">".$fileOutLoc) ||
	return(&errSbr("fileOutLoc=$fileOutLoc, not opened",$SBR5));

    $titleLoc=  "EVA".$typeLoc." old common\n";
    $titleH1Loc="EVA".$typeLoc." old common index\n";
    $dirRelIcon="../../Dicon/";
    
    print $fhoutLoc
	"<HTML>",
	"<HEAD><TITLE>".$titleLoc."</TITLE></HEAD>",
	"<BODY bgcolor=#FFFFFF>",
	"<H1>".$titleH1Loc."</H1>\n";

    print $fhoutLoc
	"<BR>",
	"<IMG SRC=\"".$dirRelIcon."mis_hand_up.gif\">","&nbsp\;",
	"<STRONG><A HREF=\"../\">move one level up</A></STRONG><BR>\n",
	"<P>";

    @tmp2=sort(@tmp2);
    foreach $tmp (@tmp2){
	print "xx in $tmp\n";
				# purge dir
	$tmp=~s/^$par{"dirWebResBupCommon".$typeLoc}//g;
	$tmp2=$tmp;
	$tmp2=~s/.common.*$//g;
	print "xx nw $tmp\n";

	print $fhoutLoc
	    "<IMG SRC=\"".$dirRelIcon."mis_link.gif\">","&nbsp\;",
	    "<A HREF=\"$tmp\">".$tmp2."</A><BR>\n";
    }
    print $fhoutLoc
	"<P>\n",
	"<IMG SRC=\"".$dirRelIcon."mis_back.gif\">","&nbsp\;",
	       "<STRONG><A HREF=\"../\">move one level up</A></STRONG><BR>\n",
	"</BODY>\n",
	"</HTML>\n";
    print $fhoutLoc
	"</BODY></HTML>\n";
    close($fhoutLoc);

    $#tmp2=$#tmp=0;
    return(1,"ok $SBR5");
}				# end of wrtRankHtml_indexOld

#===============================================================================
sub month2num {
    local($nameIn) = @_ ;
    local($sbrName,%tmp);
#-------------------------------------------------------------------------------
#   month2num                   converts name of month to number
#       in:                     Jan (or january)
#       out:                    1
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."month2num";$fhinLoc="FHIN"."$sbrName";
    return(0) if (! defined $nameIn);
    $nameIn=~tr/[A-Z]/[a-z]/;	# all small letters
    $nameIn=substr($nameIn,1,3);
    %tmp=('jan',1,'feb',2,'mar',3,'apr', 4,'may', 5,'jun',6,
	  'jul',7,'aug',8,'sep',9,'oct',10,'nov',11,'dec',12);
    return($tmp{"$nameIn"});
}				# end of month2num

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

#==============================================================================
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
    $date=$Date; $date=~s/(199\d|200\d)\s*.*$/$1/g;
    return($Date,$date);
}				# end of sysDate

############################################################
#    
#    reads the index file: 
#    
#    NOTE: only ONE single ID is allowed to speed up
#    
sub rdIndex {

#    local($Ldebug) = 1;
#    local($Ldebug) = 0;
    local($fhin)=     "FHIN";

    $[ =1 ;			# count from one

				# check existence of file
    return(0,"missing index file=".$par{"fileIndex"}."!")
	if (! defined $par{"fileIndex"} && ! -e $par{"fileIndex"});

    open($fhin,$par{"fileIndex"}) ||
	return(0,"failed to open index file=".$par{"fileIndex"}."!");

    print "<BR>xx wants to read file=".$par{"fileIndex"}."<BR>";

				# header (names)
    while(<$fhin>){
	chop;
	next if ($_=~/^\#/);
	if ($_=~/^id/){
	    @tmp=split(/\s*\t\s*/,$_);
	    foreach $it (2..$#tmp){
		if    ($tmp[$it]=~/mview/)    {$ptr{"blastpgp_mview"}=$it;}
		elsif ($tmp[$it]=~/blastpgp/) {$ptr{"blastpgp_ascii"}=$it;}
		elsif ($tmp[$it]=~/dssp/)     {$ptr{"dssp"}=          $it;}
		elsif ($tmp[$it]=~/pdb_eva/)  {$ptr{"pdb"}=           $it;}
		elsif ($tmp[$it]=~/fasta/)    {$ptr{"fasta"}=         $it;}
		elsif ($tmp[$it]=~/text/)     {$ptr{"pdbtxt"}=        $it;}
#		elsif ($tmp[$it]=~//) {$ptr{""}=$it;}
	    }
	    last;}}

				# ------------------------------
				# BODY: find all similar ids
    $idWantGrep=join("|",@idWant);
				# ALLOW only one to speed up!
    $idWantGrep=$idWant[1];
    if ($idWant[1]=~/^(.*)[_:].$/){
	$nochn=$1;
	$idWantGrep.="|".$nochn;
    }
    if ($idWant[1]=~/^[1-9](\w\w\w)[_:]?.?$/){
	$nonum=$1;
	$idWantGrep.="|".$nonum;
    }

    
    $#idfound=0;
    undef %line;
    while(<$fhin>){
	chop;
	$line=$_;
	$id=$_;
	$id=~s/^(\S+)\s*\t.*$/$1/;
	if ($id!~/$idWantGrep/){
	    $line{$id}=$line;
	    push(@idfound,$id);}
    }
    close($fhin);
				# ------------------------------
				# process the ones found
    foreach $id (sort (@idfound)){
	print "<BR>xx found $id<BR>\n";
    }
    if (! $#idfound){
	print "<BR>xx**xx none found for idgrep=$idWantGrep</BR>";
    }
    return(1,"ok");
}				# rdIndex

