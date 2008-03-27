#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="takes fasta, runs PSI-BLAST, converts to SAF->HSSP (includes DSSP if wanted)\n".
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

				# ------------------------------
				# defaults
$par{"dirProf"}=                "/home/rost/pub/prof/";
$par{"dirProfPub"}=             $par{"dirProf"}. "pub/";
$par{"dirProfScr"}=             $par{"dirProf"}. "scr/";

$par{"dirProfPubBlast"}=        $par{"dirProfPub"}. "blast/";

$par{"dirDssp"}=                "";
$par{"extBlastpgp"}=            ".blastpgp";
$par{"extBlastmat"}=            ".blastmat";
$par{"extBlastsaf"}=            ".blastsaf";
$par{"extHssp"}=                ".hssp";
$par{"extHssp_nostr"}=          ".hssp_nostr";
$par{"extDssp"}=                ".dssp";


$par{"exeBlastpgp"}=            $par{"dirProfPubBlast"}."blastpgp.pl";
$par{"exeMergeDssp"}=           $par{"dirProfScr"}.     "dsspMerge2hssp.pl";
$par{"exeCopf"}=                $par{"dirProfScr"}.     "copf.pl";


$par{"doDssp"}=                 0;
$par{"doMat"}=                  1;
$par{"doRed"}=                  1;
$par{"doSkip"}=                 1; # skip if existing

$par{"optRed"}=                 80;

$par{"dirOut"}=                 "";
$par{"fileTrace"}=              "BLASTtrace_".$$.".tmp";

$par{"fileErrorBlast"}=         "error.log"; # default name of BLAST
      

@kwd=sort (keys %par);
$Ldebug=0;
$Lverb= 0;
				# ------------------------------
if ($#ARGV<1 ||			# help
	$ARGV[1] =~/^(-h|help|special)/){
    print  "goal: $scrGoal\n";
    print  "use:  '$scrName '\n";
    print  "opt:  \n";
				#      'keyword'   'value'    'description'
    printf "%5s %-15s=%-20s %-s\n","","fileOut", "x",       "name of output file";

    printf "%5s %-15s %-20s %-s\n","","dssp",    "no value","use DSSP file to read known structure";
    printf "%5s %-15s %-20s %-s\n","","mat",     "no value","write out BLAST matrix";
    printf "%5s %-15s=%-20s %-s\n","","red",     "x",       "redundancy reduction (highly recommended!)";
    printf "%5s %-15s %-20s %-s\n","","skip",    "no value","skip if files exist";
    printf "%5s %-15s %-20s %-s\n","","new|noskip", "no value","do NOT skip if files exist";

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
$FHPROG=       "STDOUT";
$FHTRACE=      "STDOUT";
$fileOutScreen=0;
$LisList=0;

$#fileIn=0;
				# ------------------------------
				# read command line
foreach $arg (@ARGV){
#    next if ($arg eq $ARGV[1]);
    if    ($arg=~/^fileOut=(.*)$/i)       { $fileOut=        $1;}
    elsif ($arg=~/^de?bu?g$/)             { $Ldebug=         1;
					    $Lverb=          1;}
    elsif ($arg=~/^verb(ose)?$|^\-v$/)    { $Lverb=          1;}
    elsif ($arg=~/^silent$|^\-s$/)        { $Lverb=          0;}

    elsif ($arg=~/^(is)?list$/i)          { $LisList=        1;}

    elsif ($arg=~/^dssp$/i)               { $par{"doDssp"}=  1;}
    elsif ($arg=~/^mat$/i)                { $par{"doMat"}=   1;}
    elsif ($arg=~/^skip$/i)               { $par{"doSkip"}=  1;}
    elsif ($arg=~/^(noskip|new)$/i)       { $par{"doSkip"}=  0;}

#    elsif ($arg=~/^=(.*)$/){ $=$1;}
    elsif (-e $arg)                       { push(@fileIn,$arg); }
    else {
	$Lok=0; 
	if (defined %par && $#kwd>0) { 
	    foreach $kwd (@kwd){ 
		if ($arg =~ /^$kwd=(.+)$/){
		    $Lok=1;$par{$kwd}=$1;
		    $par{"doDssp"}=1      if ($kwd =~/dirDssp/);
		    last;}
	    }}
	if (! $Lok){ print "*** wrong command line arg '$arg'\n";
		     exit;}}}

$fileIn=$fileIn[1];
die ("*** ERROR $scrName: missing input $fileIn!\n") 
    if (! -e $fileIn);
$par{"dirOut"}.="/"  if (defined $par{"dirOut"} && length($par{"dirOut"})>1 &&
			 $par{"dirOut"}!~/\/$/);
if (! defined $fileOut){
    $tmp=$fileIn;$tmp=~s/^.*\///g;$fileOut="Out-".$tmp;}

				# ------------------------------
				# (0) digest file (list?)
				# ------------------------------
$#fileTmp=0;
foreach $fileIn (@fileIn){
    if ( ($#fileIn==1 && $LisList) || $fileIn =~/\.list/) {
	($Lok,$msg,$file,$tmp)=
	    &fileListRd($fileIn);if (! $Lok){ print "*** ERROR $scrName: input list\n",$msg,"\n";
					      exit; }
	@tmpf=split(/,/,$file); 
	push(@fileTmp,@tmpf);
	next;}
    push(@fileTmp,$fileIn);
}
@fileIn= @fileTmp;
$#fileTmp=0;			# slim-is-in

				# ------------------------------
$timeBeg=     time;		# date and time
#$Date=        &sysDate();


				# ------------------------------
				# (1) read file(s)
				# ------------------------------
$ctfileIn=0; $nfileIn=$#fileIn;
foreach $fileIn (@fileIn){
    ++$ctfileIn;
    if (! -e $fileIn){print "-*- WARN $scrName: no fileIn=$fileIn\n";
		      next;}
#    print "--- $scrName: working on fileIn=$fileIn!\n";
#    printf "--- $scrName: working on %-25s %4d (%4.1f perc of job)\n",$fileIn,$ctfile,(100*$ctfile/$#fileIn);

				# runtime estimate
    &assFctRunTimeLeft($timeBeg,$nfileIn,$ctfileIn,$fileIn,"unk");


				# ------------------------------
				# file names
    $title=     $fileIn; 
    $title=~s/^.*\///g;		# purge dir
    $title=~s/\.f.*$//g;	# purge ext
    
				# ------------------------------
				# run PSI-BLAST
				# ------------------------------
    $fileOutPgp=$par{"dirOut"}.$title.$par{"extBlastpgp"};
    $fileOutSaf=$par{"dirOut"}.$title.$par{"extBlastsaf"};

    $cmd=$par{"exeBlastpgp"}. " " . $fileIn . " fileOut=".$fileOutPgp." saf=".$fileOutSaf;
    if ($par{"doMat"}){
	$fileOutMat=$par{"dirOut"}.$title.$par{"extBlastmat"};
	$cmd.=" mat=".$fileOutMat;
    }
    if ($par{"doRed"}){
	$cmd.=" red=".$par{"optRed"};
    }

    if (! $par{"doSkip"} || ! -e $fileOutSaf){
	($Lok,$msg)=	
	    &sysRunProg($cmd,$par{"fileTrace"},$FHPROG); print "--- system '$cmd'\n" if ($Ldebug);
	if (! $Lok){
	    print "-*- WARN $scrName: failed system '$cmd'\n";
	    next; }
	if (! -e $fileOutSaf){
	    print "*** ERROR $scrName: failed to get SAF ($fileOutSaf) from cmd=$cmd\n";
	    next } }

				# ------------------------------
				# run SAF -> HSSP
				# ------------------------------
    $fileOutHssp=$par{"dirOut"}.$title.$par{"extHssp"};
    $cmd=$par{"exeCopf"} . " ". $fileOutSaf . " hssp fileOut=".$fileOutHssp;
    
    if (! $par{"doSkip"} || ! -e $fileOutHssp){
	($Lok,$msg)=
	    &sysRunProg($cmd,$par{"fileTrace"},$FHPROG);print "--- system '$cmd'\n" if ($Ldebug);
	if (! $Lok){
	    print "-*- WARN $scrName: failed system '$cmd'\n";
	    next; }
	if (! -e $fileOutHssp){
	    print "*** ERROR $scrName: failed to get HSSP ($fileOutHssp) from cmd=$cmd\n";
	    next }}
				# ------------------------------
				# run HSSP + DSSP -> HSSP
				# ------------------------------
    if ($par{"doDssp"}){
	$fileOutHssp_nostr=$par{"dirOut"}. $title.$par{"extHssp_nostr"};
	$fileOutHssp_nostr.="x" if ($fileOutHssp_nostr eq $fileOutHssp);
	$chain=0;
	if ($title =~ /([_:][a-zA-Z0-9])$/){
	    $chain=$1;
	    $id=$title; $id=~s/$chain//g;
	    $fileDssp=         $par{"dirDssp"}.$id.$par{"extDssp"};
	    $fileInDssp=       $par{"dirDssp"}.$id.$par{"extDssp"}.$chain; }
	else {
	    $fileDssp=         $par{"dirDssp"}.$title.$par{"extDssp"}; 
	    $fileInDssp=       $par{"dirDssp"}.$title.$par{"extDssp"}; }
	if (! -e $fileDssp){
	    print 
		"-*- you want DSSP, no file found (dir=",$par{"dirDssp"},
		") fileIn=$fileInDssp, file=$fileDssp!\n";
	    next; }
				# move HSSP file
	$cmd="\\mv $fileOutHssp $fileOutHssp_nostr";
	($Lok,$msg)=	
	    &sysRunProg($cmd,$par{"fileTrace"},$FHPROG);print "--- system '$cmd'\n" if ($Ldebug);
	if (! $Lok){
	    print "-*- WARN $scrName: failed system '$cmd'\n";
	    next; }
	if (! -e $fileOutHssp_nostr){
	    print "*** ERROR $scrName: failed to get HSSP ($fileOutHssp_nostr) from cmd=$cmd\n";
	    next }

				# merge files!
	$cmd=$par{"exeMergeDssp"} ." " . $fileOutHssp_nostr . " fileDssp=".$fileInDssp;
	$cmd.=" chn"            if ($chain);
	$cmd.=" fileOut=".$fileOutHssp;
	($Lok,$msg)=	
	    &sysRunProg($cmd,$par{"fileTrace"},$FHPROG);print "--- system '$cmd'\n" if ($Ldebug);
	if (! $Lok){
	    print "-*- WARN $scrName: failed system '$cmd'\n";
	    next; }
    }				# end of DSSP
}				# end of list over files!


				# ------------------------------
				# finally clean up BLAST shit
				# ------------------------------
if (-e $par{"fileErrorBlast"}){
    unlink($par{"fileErrorBlast"});
    print "--- cleaning up fileErrorBlast=".$par{"fileErrorBlast"}."\n" if ($Ldebug);
}
#print "--- output in $fileOut\n" if (-e $fileOut);
exit;


#===============================================================================
sub assFctRunTimeLeft {
    local($timeBeg,$nfileIn,$ctfileIn,$fileIn,$chainIn) = @_ ;
    local($SBR2);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   assFctRunTimeLeft           
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR2=""."assFctRunTimeLeft";

    return(1,"ok") if ($nfileIn < 1);
				# ------------------------------
				# estimate time
    $estimate=&fctRunTimeLeft($timeBeg,$nfileIn,$ctfileIn);
    $estimate="?"               if ($ctfileIn < 5);
    $tmp=$fileIn; 
    $tmp.="_".$chainIn          if ($chainIn ne "unk" && $chainIn ne "*");
    if ($par{"debug"}){
	printf $FHTRACE
	    "--- %-40s %4d (%4.1f%-1s), time left=%-s\n",
	    $tmp,$ctfileIn,(100*$ctfileIn/$nfileIn),"%",$estimate;}
    else {
	printf $FHTRACE
	    "--- %-40s %4d (%4.1f%-1s), time left=%-s \n",
	    $tmp,$ctfileIn,(100*$ctfileIn/$nfileIn),"%",$estimate;}
}				# end of assFctRunTimeLeft

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
sub fctRunTime {
    local($timeBegLoc) = @_ ;
    local($sbrName);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   fctRunTimeLeft              estimates the run time of the job
#       in:                     $timeBegLoc : time (time) when job began
#       out:                    $_string_time-still (hour:min:sec)
#-------------------------------------------------------------------------------
    $sbrName="lib-col:"."fctRunTimeLeft";

    $timeNow=time;
    $timeRun=$timeNow-$timeBegLoc;

    $tmp=
	&fctSeconds2time($timeRun); 
    @tmp=split(/:/,$tmp); foreach $tmp (@tmp){$tmp=~s/^0//g;}
    $estimateLoc= "";
    $estimateLoc.=    $tmp[1]."h " if ($tmp[1] > 9);
    $estimateLoc.=" ".$tmp[1]."h " if (9 >= $tmp[1] && $tmp[1] > 0);
    $estimateLoc.=    $tmp[2]."m " if ($tmp[2] > 9);
    $estimateLoc.=" ".$tmp[2]."m " if (9 >= $tmp[2] && $tmp[2] > 0);
    $estimateLoc.=" "." ".    "  " if ($tmp[2] <= 0 && $tmp[1] > 0);
    $estimateLoc.=    $tmp[3]."s " if ($tmp[3] > 9);
    $estimateLoc.=" ".$tmp[3]."s " if (9 >= $tmp[3] && $tmp[3] > 0);
    $estimateLoc.=" "." ".    "  " if ($tmp[3] <= 0 && ($tmp[1] > 0 || $tmp[2] > 0));

    return($estimateLoc);
}				# end of fctRunTimeLeft

#===============================================================================
sub fctRunTimeLeft {
    local($timeBegLoc,$num_to_run,$num_did_run) = @_ ;
    local($sbrName);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   fctRunTimeLeft              estimates the time the job still needs to run
#       in:                     $timeBegLoc : time (time) when job began
#       in:                     $num_to_run : number of things to do
#       in:                     $num_did_run: number of things that are done, so far
#       out:                    $_string_time-still (hour:min:sec)
#-------------------------------------------------------------------------------
    $sbrName="lib-col:"."fctRunTimeLeft";

    $timeNow=time;
    $timeRun=$timeNow-$timeBegLoc;

    $percLoc=0;
    $percLoc=100*($num_did_run/$num_to_run) if ($num_to_run > 0);

    if ($percLoc) {
	$timeTot=int(100*($timeRun/$percLoc));
	$timeLeft=$timeTot-$timeRun;
	$tmp=
	    &fctSeconds2time($timeLeft); 
	@tmp=split(/:/,$tmp); foreach $tmp (@tmp){$tmp=~s/^0//g;}
	$estimateLoc= "";
	$estimateLoc.=    $tmp[1]."h " if ($tmp[1] > 9);
	$estimateLoc.=" ".$tmp[1]."h " if (9 >= $tmp[1] && $tmp[1] > 0);
	$estimateLoc.=    $tmp[2]."m " if ($tmp[2] > 9);
	$estimateLoc.=" ".$tmp[2]."m " if (9 >= $tmp[2] && $tmp[2] > 0);
	$estimateLoc.=" "." ".    "  " if ($tmp[2] <= 0 && $tmp[1] > 0);
	$estimateLoc.=    $tmp[3]."s " if ($tmp[3] > 9);
	$estimateLoc.=" ".$tmp[3]."s " if (9 >= $tmp[3] && $tmp[3] > 0);
	$estimateLoc.=" "." ".    "  " if ($tmp[3] <= 0 && ($tmp[1] > 0 || $tmp[2] > 0));
	$estimateLoc= "done"        if (length($estimateLoc) < 1);}
    else {
	$estimateLoc="?";}
    return($estimateLoc);
}				# end of fctRunTimeLeft

#===============================================================================
sub fctSeconds2time {
    local($secIn) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   fctSeconds2time             converts seconds to hours:minutes:seconds
#       in:                     seconds
#       out:                    05:13:50
#-------------------------------------------------------------------------------
    $sbrName="lib-col:"."fctSeconds2time";$fhinLoc="FHIN"."$sbrName";
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
sub fileListRd {
    local($fileInLoc,$fhErrSbr,$extForChain,$dirLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   fileListRd                  reads a list of files
#       in:                     file_list=     file with filenames
#       in:                     $fhErrSbr=     file handle to report missing files 
#                                              (0 to surpress warnings!)
#       in:                     $extForChain=  'ext1,ext2' : extensions to check for chains,
#                                              i.e. if not existing purge ext_[A-Z0-9]
#       in:                     $dirLoc=       'dir1,dir2' : directories to scan for file
#       out:                    1|0,msg
#       out:                    $list=         'file1,file2,...'
#       out:                    $chain=        'c1,c2,...' : if chains found
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."fileListRd";$fhinLoc="FHIN_"."fileListRd";
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc!",0)         if (! defined $fileInLoc);
    $fhErrSbr="STDOUT"                                     if (! defined $fhErrSbr);
    $extForChain=0                                         if (! defined $extForChain);
    return(0,"*** $sbrName: miss in file '$fileInLoc'!",0) if (! -e $fileInLoc);
    @extLoc=split(/,/,$extForChain)                        if ($extForChain);
    @dirLoc=split(/,/,$dirLoc)                             if ($dirLoc);
				# ------------------------------
				# open file
    open($fhinLoc,$fileInLoc) ||
	return(0,"*** ERROR $sbrName: fileIn=$fileInLoc, not opened\n",0);

    $tmpChain=$tmpFile="";	# ------------------------------
    while (<$fhinLoc>) {	# read list
	$_=~s/\n|\s//g; $file=$_;
	next if (length($_)==0);
	if    (-e $file) {
	    $tmpFile.="$file,";$tmpChain.="*,";} # file ok 
	else {$Lok=0;$chainTmp="unk";
	      foreach $ext (@extLoc){ # check chain
		  foreach $dir ("",@dirLoc){ # check dir (first: local!)
		      $fileTmp=$file; $dir.="/"  if (length($dir)>0 && $dir !~/\/$/);
		      $fileTmp=~s/^(.*$ext)\_([A-Z0-9])$/$1/;
		      $chainTmp=$2               if (defined $2);
		      $fileTmp=$dir.$fileTmp; 
		      $Lok=1  if (-e $fileTmp);
		      last if $Lok;}
		  last if $Lok;}
	      if ($Lok){$tmpFile.="$fileTmp,";
			$tmpChain.="*,"          if (! defined $chainTmp || $chainTmp eq "unk");
			$tmpChain.="$chainTmp,"  if (defined $chainTmp && $chainTmp ne "unk"); }
	      else { print $fhErrSbr "-*- WARN $sbrName missing file=$_,\n";}}
    }close($fhinLoc);
    $tmpFile=~s/^,*|,*$//g;$tmpChain=~s/^,*|,*$//g;
    return(1,"ok $sbrName",$tmpFile,$tmpChain);
}				# end of fileListRd

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
    $sbrName="lib-col:sysRunProg";
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

