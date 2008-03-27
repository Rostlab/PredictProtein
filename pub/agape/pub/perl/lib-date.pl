				# ------------------------------
$timeBeg=     time;		# date and time
$Date=        &sysDate();
$date="??-??-????";		# ini
($Lok,$date)= &date_monthDayYear2num($Date);
$par{"Date"}=               $Date;
$par{"date"}=               $date;


				# runtime estimate
    &assFctRunTimeLeft($timeBeg,$nfileIn,$ctfileIn,$fileIn,$chainIn);



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

    $FHTRACE="STDOUT"           if (! defined $FHTRACE);
				# ------------------------------
				# estimate time
    $estimate=&fctRunTimeLeft($timeBeg,$nfileIn,$ctfileIn);
    $estimate="?"               if ($ctfileIn < 5);
    $tmp=$fileIn; 
    $tmp.="_".$chainIn          if (defined $chainIn && $chainIn ne "unk" && $chainIn ne "*");
    if ($par{"debug"}){
	printf $FHTRACE
	    "--- %-40s %4d (%4.1f%-1s), time left=%-s\n",
	    $tmp,$ctfileIn,(100*$ctfileIn/$nfileIn),"%",$estimate;}
    else {
	printf $FHTRACE
	    "--- %-40s %4d (%4.1f%-1s), time left=%-s\n",
	    $tmp,$ctfileIn,(100*$ctfileIn/$nfileIn),"%",$estimate;}
}				# end of assFctRunTimeLeft

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
sub date_monthDayYear2num {
    local($datein) = @_ ;
    local($sbrName);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   date_monthDayYear2num       converts date from 'Feb 14, 1999' -> 14-02-1999
#       in:                     $date
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."date_monthDayYear2num";
    return(0,"no input")        if (! defined $datein);
    return(0,"no valid input")  
	if ($datein !~ /([a-zA-z][a-zA-z][a-zA-z])[\s\-_\.,]+(\d+)[\s\-_\.,]+(\d+)/);
    $month=$1;
    $day=  $2;
    $year= $3;
				# convert month
    ($Lok,$msg,$num)=&date_monthName2num($month);
    return(0,"failed converting month=$month! msg=\n".$msg) if (! $Lok);
    $out=$day."-".$num."-".$year;
    return(1,$out);
}				# end of date_monthDayYear2num

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

