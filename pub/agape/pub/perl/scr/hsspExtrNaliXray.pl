#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="greps 'NALIGN|SEQLENGTH' from HSSP file, and resolution from resp. PDB\n";
#  
#
$[ =1 ;
				# ------------------------------
				# defaults
%par=(
      'dirPdb', "/home/rost/data/pdb/",		# directory of PDB
      'extPdb', ".brk",		# extension of PDB

      'dirPdb', "/data/pdb/",	# directory of PDB
      'extPdb', ".pdb",		# extension of PDB
      '', "", 
      '', "", 
      );
$sep=" ";
$resMax=1107;

$timeBeg=time;
				# ------------------------------
if ($#ARGV<1){			# help
    print "goal:\t $scrGoal\n";
    print "use: \t '$scrName list.hssp (or *.hssp)'\n";
    print "opt: \t \n";
    print "     \t nali=(ge|gt|le|lt)x : only those with nali    >=,>,<=,< x\n";
    print "     \t len=(ge|gt|le|lt)x  : only those with length  >=,>,<=,< x\n";
    print "     \t res=(ge|gt|le|lt)x  : only those with respective X-ray resolution\n";
    print "     \t fileOut=x\n";
    print "     \t noali               -> don NOT look up NALIGN\n";
    print "     \t nolen               -> don NOT look up SEQLENGTH\n";
    print "     \t nores               -> don NOT look up PDB resolution\n";
#    print "     \t \n";
    if (defined %par){
	foreach $kwd (@kwd){
	    printf "     \t %-20s=%-s (def)\n",$par{"$kwd"};}}
    exit;}
				# initialise variables
$fhin="FHIN";$fhout="FHOUT";
$Lnoali=$Lnolen=$Lnores=    0;
$modeNali=$modeLen=$modeRes=0;
				# ------------------------------
$#fileIn=0;			# read command line
foreach $arg (@ARGV){
    if    ($arg=~/^fileOut=(.*)$/)            { $fileOut=$1;}
    elsif ($arg=~/^nali=([glet]+)(\d+)$/)     { $naliExcl=$2; $modeNali=$1;}
    elsif ($arg=~/^len=([glet]+)(\d+)$/)      { $lenExcl=$2;  $modeLen= $1;}
    elsif ($arg=~/^res=([glet]+)([\d\.]+)$/)  { $resExcl=$2;  $modeRes= $1;}
    elsif ($arg=~/^noali$/)                   { $Lnoali=1;}
    elsif ($arg=~/^nolen$/)                   { $Lnolen=1;}
    elsif ($arg=~/^nores$/)                   { $Lnores=1;}
#    elsif ($arg=~/^=(.*)$/) { $=$1;}
    else  {$Lok=0;
	   if (-e $arg){$Lok=1;
			push(@fileIn,$arg);}
	   if (! $Lok && defined %par){
	       foreach $kwd (keys %par){
		   if ($arg =~ /^$kwd=(.+)$/){$Lok=1;$par{"$kwd"}=$1;
					      last;}}}
	   if (! $Lok){print"*** wrong command line arg '$arg'\n";
		       die;}}}
$fileIn=$fileIn[1];
$par{"dirPdb"}.="/"               if ($par{"dirPdb"}!~/\/$/);
$par{"extPdb"}=".".$par{"extPdb"} if ($par{"extPdb"}!~/^\./);

die ("missing input $fileIn\n") if (! -e $fileIn);
				# ------------------------------
				# output file name
if (! defined $fileOut){
    $tmp=$fileIn;$tmp=~s/^.*\///g;
    $tmp2="";
    if (defined $naliExcl){$tmp2.="nali-";
			   $tmp2="gt".$naliExcl."-"  if ($modeNali eq "gt");
			   $tmp2="ge".$naliExcl."-"  if ($modeNali eq "ge");
			   $tmp2="lt".$naliExcl."-"  if ($modeNali eq "lt");
			   $tmp2="le".$naliExcl."-"  if ($modeNali eq "le"); }
    if (defined $lenExcl) {$tmp2.="len-";
			   $tmp2="gt".$lenExcl."-"   if ($modeLen eq "gt");
			   $tmp2="ge".$lenExcl."-"   if ($modeLen eq "ge");
			   $tmp2="lt".$lenExcl."-"   if ($modeLen eq "lt");
			   $tmp2="le".$lenExcl."-"   if ($modeLen eq "le"); }
    if (defined $resExcl) {$tmp2.="res-";
			   $tmp2="gt".$resExcl."-"   if ($modeRes eq "gt");
			   $tmp2="ge".$resExcl."-"   if ($modeRes eq "ge");
			   $tmp2="lt".$resExcl."-"   if ($modeRes eq "lt");
			   $tmp2="le".$resExcl."-"   if ($modeRes eq "le"); }
    $fileOut="Out-".$tmp2.$tmp;}

				# ------------------------------
				# read list (if list)
if (! &is_hssp($fileIn)){
    print "--- $scrName: read list '$fileIn'\n";
    $#fileIn=0;
    &open_file("$fhin", "$fileIn") || die '*** $scrName ERROR opening file $fileIn';
    while (<$fhin>) {$_=~s/\n|\s//g;
		     next if (length($_)<5);
		     if ($_=~/\.hssp_[A-Z0-9]/){ # purge change 
			 $_=~s/(\.hssp)_[A-Z0-9]/$1/;}
		     push(@fileIn,$_); } close($fhin);}

				# --------------------------------------------------
				# (1) read file(s)
				# --------------------------------------------------
$nfileIn= $#fileIn; 
$ctfileIn=0;

foreach $fileIn (@fileIn){
    if (! -e $fileIn){print "-*- WARN $scrName: no fileIn=$fileIn\n";
		      next;}
    $Lok=1;
    ++$ctfileIn;
				# ------------------------------
    if (! $Lnoali){             # grep NALIGN
	($Lok,$msg,$nali)=
	    &hsspGrepNali($fileIn,$naliExcl,$modeNali);
	print "*** ERROR $scrName: failed on grepping NALI from $fileIn ($msg)\n" if (! $Lok);
	$Lok=0                  if (! $nali); }
    next if (! $Lok);
				# ------------------------------
    if (! $Lnolen){             # grep SEQLENGTH
	($Lok,$msg,$len)=
	    &hsspGrepLen($fileIn,$lenExcl,$modeLen);
	print "*** ERROR $scrName: failed on grepping LEN from $fileIn ($msg)\n" if (! $Lok);
	$Lok=0                  if (! $len); }
    next if (! $Lok);
				# ------------------------------
    if (! $Lnores){             # grep PDB resolution
	$id=$fileIn;$id=~s/^.*\///g;$id=~s/\.hssp.*$//g;
	$filePdb=$par{"dirPdb"}.$id.$par{"extPdb"};
	if (! -e $filePdb) { print "*** file=$fileIn, pdb=$filePdb, (id=$id) missing\n";
			     next;
			     exit;}
	($Lok,$msg,$res)=
	    &pdbGrepResolution($filePdb,$lenExcl,$modeRes,$resMax);
	print "*** ERROR $scrName: failed to grep PDBres from $filePdb ($msg)\n" if (! $Lok);
	$Lok=0                  if (! $res); }
    next if (! $Lok);


    $prtTmp="";
    if (! $Lnoali && defined $nali && $nali) { 
	$ok{"nali",$fileIn}=$nali;
	$tmp= " nali=$nali ";
	$tmp.=" ($modeNali $naliExcl), " if (defined $naliExcl);
	$prtTmp.=$tmp;}
    if (! $Lnolen && defined $len && $len) { 
	$ok{"len",$fileIn}=$len;
	$tmp= " nlen=$len ";
	$tmp.=" ($modeLen $lenExcl), "   if (defined $lenExcl);
	$prtTmp.=$tmp;}
    if (! $Lnores && defined $res && $res) { 
	$ok{"res",$fileIn}=$res;
	$tmp= " res=$res ";
	$tmp.=" ($modeRes $resExcl), "   if (defined $resExcl);
	$prtTmp.=$tmp;}
				# ------------------------------
				# estimate time
    $estimate=&fctRunTimeLeft($timeBeg,$nfileIn,$ctfileIn);
    $estimate="?"           if ($ctfileIn < 5);
    printf 
	"--- ok %-50s %4d (%4.1f%-1s), time left=%-s\n",
	$fileIn.$prtTmp,$ctfileIn,(100*$ctfileIn/$nfileIn),"%",$estimate;


}
				# ------------------------------
				# (2) write output
&open_file("$fhout",">$fileOut"); 
foreach $fileIn(@fileIn){
    next if (! defined $ok{"nali","$fileIn"} &&
	     ! defined $ok{"len","$fileIn"} &&
	     ! defined $ok{"res","$fileIn"});
    $tmp= sprintf("%-40s",$fileIn);
    $tmp.=sprintf("$sep%5d",$ok{"nali","$fileIn"})   if (! $Lnoali);
    $tmp.=sprintf("$sep%5d",$ok{"len","$fileIn"})    if (! $Lnolen);
    $tmp.=sprintf("$sep%8.2f",$ok{"res","$fileIn"})  if (! $Lnores);
    $tmp.="\n";
    
    print $tmp;
    printf $fhout $tmp; 
    
}
close($fhout);

print "--- output in $fileOut\n";
exit;


#==============================================================================
# library collected (begin) lll
#==============================================================================


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
    $sbrName="lib-br:"."fctRunTimeLeft";

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
    $sbrName="lib-comp:"."fctSeconds2time";$fhinLoc="FHIN"."$sbrName";
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
sub hsspGrepLen {
    local($fileInLoc,$exclLoc,$modeLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspGrepLen                 greps the 'SEQLENGTH  ddd' line from HSSP files
#       in:                     $fileInLoc=  file
#       in:                     $exclLoc=    limit for LEN  (0 to avoid checkin)
#       in:                     $modeLoc=    mode of to exclude 'gt|ge|lt|le'  (0 to avoid checkin)
#       out:                    1|0,msg,$len (0 if condition not fulfilled)
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."hsspGrepLen";$fhinLoc="FHIN_"."hsspGrepLen";
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
    return(&errSbr("miss in file '$fileInLoc'!"))  if (! -e $fileInLoc);
    $exclLoc=$modeLoc=0                            if (! defined $exclLoc || ! defined $modeLoc);
				# ------------------------------
				# system call
				# ------------------------------
    $tmp=`grep '^SEQLENGTH' $fileInLoc`; 
				# process output

    $tmp=~s/^SEQLENGTH\s*(\d+).*$/$1/g; $tmp=~s/\n|\s//g;
    $Lok=1;
				# restrict?
    if ($modeLoc && $exclLoc) { 
	return(1,"len=$tmp (<= $exclLoc)",0)  if (($modeLoc eq "gt")  && ($tmp <= $exclLoc) );
	return(1,"len=$tmp (<  $exclLoc)",0)  if (($modeLoc eq "ge")  && ($tmp <  $exclLoc) );
	return(1,"len=$tmp (>= $exclLoc)",0)  if (($modeLoc eq "lt")  && ($tmp >= $exclLoc) );
	return(1,"len=$tmp (>  $exclLoc)",0)  if (($modeLoc eq "le")  && ($tmp >  $exclLoc) ); }

    return(1,"ok $sbrName",$tmp);
}				# end of hsspGrepLen

#==============================================================================
sub hsspGrepNali {
    local($fileInLoc,$exclLoc,$modeLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspGrepNali                greps the 'NALIGN  ddd' line from HSSP files
#       in:                     $fileInLoc=  file
#       in:                     $exclLoc=    limit for NALI (0 to avoid checkin)
#       in:                     $modeLoc=    mode of to exclude 'gt|ge|lt|le'  (0 to avoid checkin)
#       out:                    1|0,msg,$nali (0 if condition not fulfilled)
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."hsspGrepNali";$fhinLoc="FHIN_"."hsspGrepNali";
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
    return(&errSbr("miss in file '$fileInLoc'!"))  if (! -e $fileInLoc);
    $exclLoc=$modeLoc=0                            if (! defined $exclLoc || ! defined $modeLoc);
				# ------------------------------
				# system call
				# ------------------------------
    $tmp=`grep '^NALIGN' $fileInLoc`; 
				# process output
    $tmp=~s/^NALIGN\s*(\d+).*$/$1/g; $tmp=~s/\n|\s//g;
    $Lok=1;
				# restrict?
    if ($modeLoc && $exclLoc) { 
	$Lok=0  if (($modeLoc eq "gt")  && ($tmp <= $exclLoc) );
	$Lok=0  if (($modeLoc eq "ge")  && ($tmp <  $exclLoc) );
	$Lok=0  if (($modeLoc eq "lt")  && ($tmp >= $exclLoc) );
	$Lok=0  if (($modeLoc eq "le")  && ($tmp >  $exclLoc) ); }
    $tmp=0                      if (! $Lok);
    return(1,"ok $sbrName",$tmp);
}				# end of hsspGrepNali

#==============================================================================
sub is_hssp {
    local ($fileInLoc) = @_ ;local ($fh,$tmp);
#--------------------------------------------------------------------------------
#   is_hssp                     checks whether or not file is in HSSP format
#       in:                     $file
#       out:                    1 if is hssp; 0 else
#--------------------------------------------------------------------------------
				# highest priority: has to exist
    return (0)                  if (! -e $fileInLoc);
    $fh="FHIN_CHECK_HSSP";
    open($fh, $fileInLoc) || 
	do { print "*** ERROR is_hssp $fileInLoc not opened to $fh\n";
	     return (0) ;};	# missing file -> 0
    $tmp=<$fh>;			# first line
    close($fh);
				# is HSSP
    return(1)                   if (defined $tmp && $tmp=~/^HSSP/);
    return(0);
}				# end of is_hssp

#==============================================================================
sub open_file {
    local ($file_handle,$file_name,$log_file) = @_ ;
    local ($temp_name) ;
#-------------------------------------------------------------------------------
#   open_file                  opens file, writes warning asf
#-------------------------------------------------------------------------------
    $temp_name = $file_name ;
    $temp_name =~ s/^>>|^>//g ;
    if ( ($file_name =~ /^>>/ ) && ( ! -e $temp_name ) ) {
	print "*** INFO (open_file): append file=$temp_name, does not exist-> create it\n" ;
	open ($file_handle, ">$temp_name") || ( do {
	    warn "***\t Cannot create new file: $temp_name\n" ;
	    if ( $log_file ) {
		print $log_file "***\t Cannot create new file: $temp_name\n" ;}
	    return (0);
	} );
	close ("$file_handle") ;}
  
    open ($file_handle, "$file_name") || ( do {
	warn "*** ERROR lib-br:open_file: Cannot open file '$file_name'\n" ;
	if ( $log_file ) {
	    print $log_file "*** lib-br:open_file: Cannot create new file '$file_name'\n" ;}
	return(0);
    } );
    return(1);
}				# end of open_file

#==============================================================================
sub pdbGrepResolution {
    local($fileInLoc,$exclLoc,$modeLoc,$resMaxLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   pdbGrepResolution           greps the 'RESOLUTION' line from PDB files
#       in:                     $fileInLoc=  file
#       in:                     $exclLoc=    limit for RESOLUTION  (0 to avoid checkin)
#       in:                     $modeLoc=    mode of to exclude 'gt|ge|lt|le'  (0 to avoid checkin)
#       in:                     $resMaxLoc=  resolution assigned if none found
#       out:                    1|0,msg,$res (0 if condition not fulfilled)
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."pdbGrepResolution";$fhinLoc="FHIN_"."pdbGrepResolution";
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
    return(&errSbr("miss in file '$fileInLoc'!"))  if (! -e $fileInLoc);
    $exclLoc=$modeLoc=0                            if (! defined $exclLoc || ! defined $modeLoc);
    $resMaxLoc=1107                                if (! defined $resMaxLoc);
				# ------------------------------
				# system call
				# ------------------------------
    $tmp=`grep 'RESOLUTION\. ' $fileInLoc`; 
				# process output
    $tmp=~s/\n//g;
    if ($tmp=~/^.*RESOLUTION\.\s*([\d\.]+) .*$/){
	$tmp=~s/^.*RESOLUTION\.\s*([\d\.]+) .*$/$1/g; $tmp=~s/\n|\s//g;}
    else {
	$tmp=$resMaxLoc;}
    $Lok=1;
				# restrict?
    if ($modeLoc && $exclLoc) { 
	$Lok=0  if (($modeLoc eq "gt")  && ($tmp <= $exclLoc) );
	$Lok=0  if (($modeLoc eq "ge")  && ($tmp <  $exclLoc) );
	$Lok=0  if (($modeLoc eq "lt")  && ($tmp >= $exclLoc) );
	$Lok=0  if (($modeLoc eq "le")  && ($tmp >  $exclLoc) ); }
    $tmp=0                      if (! $Lok);
    return(1,"ok $sbrName",$tmp);
}				# end of pdbGrepResolution



#==============================================================================
# library collected (end)   lll
#==============================================================================

