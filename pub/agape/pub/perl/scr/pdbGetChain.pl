#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="reads PDB chains \n".
    "     \t note 1: chains with strange symbols to (i) numbers (ii) small cap letters\n".
    "     \t \n";
#  
# 
#------------------------------------------------------------------------------#
#	Copyright				        	1999	       #
#	Burkhard Rost		rost@EMBL-Heidelberg.DE			       #
#	CUBIC (Columbia Univ)	http://www.embl-heidelberg.de/~rost/	       #
#       Dep Biochemistry & Molecular Biophysics				       #
#       630 West, 168 Street						       #
#	New York, NY 10032	http://www.dodo.cpmc.columbia.edu/~rost/       #
#				version 0.1   	Apr,    	1999	       #
#------------------------------------------------------------------------------#
#

$[ =1 ;
				# ------------------------------
				# defaults
%par=(
      'extOut',         ".txt",
      '', "",			# 
      );
@kwd=sort (keys %par);
$Ldebug=0;
$Lverb= 1;
$chainAlternative="0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
@chainAlternative=split(//,$chainAlternative);

				# ------------------------------
if ($#ARGV<1){			# help
    print  "goal: $scrGoal\n";
    print  "use:  '$scrName file*.pdb' (or list with keyword 'list')\n";
    print  "opt:  \n";
				#      'keyword'   'value'    'description'
    printf "%5s %-15s=%-20s %-s\n","","fileOut",     "x",   "name of fasta output file";
    printf "%5s %-15s=%-20s %-s\n","","dirOut",  "x",       "directory of output files";
#    printf "%5s %-15s=%-20s %-s\n","","",   "x", "";
#    printf "%5s %-15s %-20s %-s\n","","",   "no value","";

    printf "%5s %-15s %-20s %-s\n","","list",     "no value","if input file is list of FASTA files".
	                                                     " note: automatic if extension *.list!!";
    printf "%5s %-15s %-20s %-s\n","","dbg",   "no value",   "debug mode";
    printf "%5s %-15s %-20s %-s\n","","silent|-s","no value","no screen output";
    printf "%5s %-15s %-20s %-s\n","","verb|-s",  "no value","verbose";
#    printf "%5s %-15s %-20s %-s\n","","noScreen", "no value","";
#    printf "%5s %-15s=%-20s %-s\n","","",   "x", "";
#    printf "%5s %-15s %-20s %-s\n","","",   "no value","";
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
$fhout="FHOUT"; 
$LisList=$dir=$LwrtSplit=$LwrtNochn=0;
$LwrtMerge=1;
$dirOut=   "";
$chain=    "*";
$Lunique=  0;
$#fileIn=0;

				# ------------------------------
				# read command line
foreach $arg (@ARGV){
#    next if ($arg eq $ARGV[1]);
    if    ($arg=~/^fileOut=(.*)$/i)       { $fileOutFasta=   $1;}
    elsif ($arg=~/^dirOut=(.*)$/)         { $dirOut=         $1; 
					    $dirOut.=        "/" if ($dirOut !~/\/$/);}

    elsif ($arg=~/^de?bu?g$/)             { $Ldebug=         1;}
    elsif ($arg=~/^verb(ose)?$|^\-v$/)    { $Lverb=          1;}
    elsif ($arg=~/^silent$|^\-s$/)        { $Lverb=          0;}

    elsif ($arg=~/^dir=(.*)$/)            { $dir=            $1;}
    elsif ($arg=~/^db=(.*)$/)             { $databaseId=     $1;
					    if    ($databaseId=~/^(none|0)$/){
						$databaseId= "";}
					    elsif ($databaseId !~/\|$/){
						$databaseId.="|";}}
    
#    elsif ($arg=~/^=(.*)$/){ $=$1;}
    elsif ($arg=~/^list$/i)               { $LisList=        1;}
    elsif (-e $arg)                       { push(@fileIn,$arg); push(@chainIn,"*");
					    # automatic detection of list
					    $LisList=        1 if ($arg =~ /\.list/); }
    elsif ($arg=~/^\.(pdb|brk)\_([A-Z0-9])/) { push(@fileIn,$1);   push(@chainIn,$2);}
    else {
	$Lok=0; 
	if (defined %par && $#kwd>0) { 
	    foreach $kwd (@kwd){ 
		if ($arg =~ /^$kwd=(.+)$/){$Lok=1;$par{"$kwd"}=$1;
					   last;}}}
	if (! $Lok){ print "*** wrong command line arg '$arg'\n";
		     exit;}}}

				# ------------------------------
				# read directory
    if ($dir) {
    $dir=~s/\/$//g;		# purge final slash
    if (! -d $dir) { print "*** $scrName: you want to read the non-existing directory=$dir!\n";
		     exit; }
    opendir(DIR,$dir) || die ("-*- ERROR $scrName: failed opening dir(pred)=$dir!\n");
    @tmp=readdir(DIR);  closedir(DIR);
				# filter subdirectories
    $#tmp2=0;
    foreach $tmp (@tmp) { $tmp2=$dir."/".$tmp;
			  next if (-d $tmp2);
			  next if (! -e $tmp2);
				# hack around the HONIG people
			  next if ($tmp2 !~/pdb$/);
			  push(@tmp2,$tmp2); }
    push(@fileIn,@tmp2); 	# add to (may be alread) existing input files
				# add chains
    foreach $it (1..$#tmp2){
	push(@chainIn,"*");}
    $#tmp2=$#tmp=0;		# slim-is-in
}

				# ------------------------------
$timeBeg=     time;		# date and time
$Date=        &sysDate();
$date="??-??-????";		# ini
($Lok,$date)= &date_monthDayYear2num($Date);
$par{"Date"}=               $Date;
$par{"date"}=               $date;



$fileIn=$fileIn[1];
die ("missing input $fileIn\n") if (! -e $fileIn);
$fileOut="pdbGetChain.tmp"      if (! defined $fileOut);

				# ------------------------------
				# (0) digest file (list?)
				# ------------------------------
if ($LisList || $fileIn =~/\.list/) {
    $#fileTmp=$#chainTmp=0;
    foreach $fileIn (@fileIn){
	($Lok,$msg,$file,$tmp)=
	    &fileListRd($fileIn);   if (! $Lok){ print "*** ERROR $scrName: after input list\n",$msg,"\n";
						 exit; }

	@tmpf=split(/,/,$file); push(@fileTmp,@tmpf);
	@tmpc=split(/,/,$tmp);
	if ($#tmpc>0) { push(@chainTmp,@tmpc);}
	else { foreach $it (1..$#tmpf){push(@chainTmp,"*");}} }
    @fileIn= @fileTmp; @chainIn=@chainTmp; 
    $#fileTmp=$#chainTmp=0;	# slim-is-in
}

				# --------------------------------------------------
				# read file(s)
				# --------------------------------------------------
undef %taken;
$ctfile=0;
$ctwritten=0;
$nfileIn=$#fileIn;

$cterr=0;
foreach $fileIn (@fileIn){
    ++$ctfile;
    if (! -e $fileIn){print "-*- WARN $scrName: no fileIn=$fileIn\n";
		      next;}

				# runtime estimate
    &assFctRunTimeLeft($timeBeg,$nfileIn,$ctfile,$fileIn,$chainIn);

    printf 
	"--- $scrName: working on %-6s %-1s %4d (%4.1f perc of job)\n",
	$id," ",$ctfile,(100*$ctfile/$#fileIn) if ($Lverb);
				# ------------------------------
				# read sequence for PDB
				# ------------------------------
    die"xx not working\n";
    ($Lok,$msg,$rh_pdb)=
	&pdbExtrChain($fileIn,1);

    if (! $Lok)    { 
	print "*** $scrName: error in reading PDB $fileIn:\n",$msg,"\n";
	exit; }
				# ------------------------------
				# skip nucleic acids!
    if ($Lok==2){
	print "--- $fileIn claimed to be nucleic\n" if ($Ldebug);
	next; }
				# ------------------------------
				# skip too many unknown
    if ($Lok==3){
	print "--- $fileIn too many unknown residues\n" if ($Ldebug);
	next; }

    if (! defined $rh_pdb->{"chains"}) { 
	print "*** $scrName: not defined 'chains' in PDB $fileIn:\n",$msg,"\n";
	++$cterr;
	print $fhoutError
	    $fileIn,"\n";
	next; }

    @chainTmp=split(/,/,$rh_pdb->{"chains"});

				# ------------------------------
				# merge all chains
    if ($LwrtNochn){
	$seqRd="";
	foreach $chainTmp (@chainTmp) {
	    $seqRd.=$rh_pdb->{$chainTmp};
	}
	$chainAll="none";
	$rh_pdb->{$chainAll}=$seqRd;
	push(@chainTmp,$chainAll);
    }
				# ------------------------------
				# loop over all chains
				# ------------------------------
    undef %chainTaken;
    undef %idTaken;
    $#seqTaken=0;		# keep those in mind we took

    foreach $chainTmp (@chainTmp) {
				# ------------------------------
				#  build up write 
	$Lskip=0;
	next if ($LwrtNochn && $chainTmp ne "none");

	if ($chainTmp eq "none"){
	    $chainWrt="";}
	else {
				# change strange chains
	    if ($chainTmp=~/[^A-Z0-9]/){
		foreach $tmp (@chainAlternative){
		    next if (defined $chainTaken{$tmp});
		    $chainTmp=$tmp;
		    $chainTaken{$tmp}=1;
		    last;}}
	    else {
		$chainTaken{$chainTmp}=1;}
				# error?
	    if ($chainTmp=~/[^A-Z0-9a-z]/){
		print $fhoutError
		    "*** ERROR currently want to write chain=$chainTmp (file=$fileIn)\n";
		$Lskip=1;}
	    else {
		$chainWrt="_".$chainTmp; }}
	next if ($Lskip);
		
				# first line: id
	$tmpWrt=         ">".$databaseId.$id.$chainWrt;
	$tmpWrt.=        " ".$rh_pdb->{"header"} if (defined $rh_pdb->{"header"});
	$tmpWrt.=        " ".$rh_pdb->{"compnd"} if (defined $rh_pdb->{"compnd"});
	$tmpWrt.=        " source=".$rh_pdb->{"source"} if (defined $rh_pdb->{"source"});
	$tmpWrt.=        "\n";
				# next lines: sequence
	$seqRd=$rh_pdb->{$chainTmp};
	if (! defined $seqRd){
	    print $fhoutError
		"*** ERROR no sequence for id=$id, file=$fileIn,  chain=$chainTmp, allchain=",
		join(',',@chainTmp),"\n";
	    next;
#	    die;
	}
	$seqRd=~s/\s//g;
	$len=length($seqRd);

				# discard too short
	next if ($len < $par{"minLen"});

				# discard nucleic stuff
	next if ($rh_pdb->{"percentage_strange"} < $par{"minAcids"});

				# kick out those identical to previous chain
	if ($Lunique){
	    $Lok=1;
	    foreach $seqbefore (@seqTaken){
		if ($seqRd eq $seqbefore){
		    print "--- identical chain $chainTmp ignored!\n";
		    print $fhoutRedundant
			$id."_".$chainTmp,"\t",$idPrev,"\n";
		    $Lok=0;
		    last;}}
	    next if (! $Lok);
				# keep this
	    push(@seqTaken,$seqRd);
	    $idPrev=$id."_".$chainTmp;
	}
	else {
	    $idPrev=$id."_".$chainTmp;}

				# write in strings of 10: 'AAAAAAAAAA CCCCCC'
	for ($it=1; $it<=$len; $it+=50) {
	    for ($it2=$it; $it2< ($it+50); $it2+=10) {
		last if ($it2 > $len);
		$tmp=10; $tmp=($len - $it2 + 1) if (($len - $it2)<10);
		$tmpWrt.=substr($seqRd,$it2,$tmp)." "; }
	    $tmpWrt.=    "\n"; }
				# ------------------------------
				# write into merged db file
	if ($LwrtMerge) {
	    print $fhoutMerge $tmpWrt; }
				# ------------------------------
				# IS protein: write 
				#    note: only once
	if (! defined $taken{$fileIn}){
	    print $fhoutProt $fileIn,"\n";
	    $taken{$fileIn}=1;}
				# ------------------------------
				# write id
	if (! defined $idTaken{$id.$chainWrt}){
	    print $fhoutId "$id$chainWrt\n";
	    $idTaken{$id.$chainWrt}=1;}

	++$ctwritten;
				# ------------------------------
				# write into split files
	if ($LwrtSplit) {
	    $fileOutTmp=$dirOut.$id.$chainWrt.$par{"extOut"};
	    open($fhout,">".$fileOutTmp); 
	    print $fhout      $tmpWrt;	# write new
	    close($fhout); 
	    print "--- wrote $fileOutTmp\n" if ($Lverb);
	    print "*** ERROR failed to write $fileOutTmp\n" if (! -e $fileOutTmp &&
								$Lverb); }
    }				# end of loop over chains
}
close($fhoutProt);		# close file with all proteins
close($fhoutError);		# close file with all proteins
unlink($fileOutError) if ($cterr<1);

unlink($fileOutFasta) if (-e $fileOutFasta && ! $ctwritten);

close($fhoutRedundant) if ($Lunique);
    
if ($Lverb){
    print "--- $ctwritten proteins written (from $ctfile wanted)\n";
    print "--- output with all FASTA in $fileOutFasta\n"    if (-e $fileOutFasta);
#    print "--- output in file missing ??\n"  if (! -e $fileOut);
    print "--- list of all proteins in: $fileOutProt\n";
    print "--- list of all ids in: $fileOutId\n";
    print "--- chains skipped since redundant $fileOutRedundant\n" if ($Lunique);
    print "--- Errors for files in $fileOutError (check it out!)\n" if (-e $fileOutError);
    print "--- $scrName ended\n";
}
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
    $FHTRACE="STDOUT"           if (! defined $FHTRACE);
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
	      if ($Lok){
		  $tmpFile.="$fileTmp,";
		  $tmpChain.="*,"          if (! defined $chainTmp || $chainTmp eq "unk");
		  $tmpChain.="$chainTmp,"  if (defined $chainTmp && $chainTmp ne "unk"); }
	      else { 
		  print $fhErrSbr "-*- WARN $sbrName missing file=$_,\n";}}
    }close($fhinLoc);
    $tmpFile=~s/^,*|,*$//g;$tmpChain=~s/^,*|,*$//g;
    return(1,"ok $sbrName",$tmpFile,$tmpChain);
}				# end of fileListRd

#===============================================================================
sub pdbExtrChain {
    local($fileInLoc,$LskipNucleic) = @_ ;
    local($sbrName);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   pdbExtrChain                reads chains in a PDB file
#                               FROM SEQRES LINE in header
#       in:                     $fileInLoc=    PDB file
#       in:                     $LskipNucleic= skip if nucleic acids
#       out:                    0,$msg         ERROR
#       out:                    2,$msg,        NUCLEIC
#       out:                    3,$msg,        too many unknown residues
#       out:                    1,"ok",%pdb as implicit reference with:
#       out:                    $pdb{"chains"}="A,B" -> all chains found ('none' for not specified)
#                               $pdb{$chain}=  sequence for chain $chain 
#                                              (='none' for not specified chain)
#                               NOTE: 'X' used for hetero-atoms, or for symbol 'U'
#                               $pdb{"header"}
#                               $pdb{"compnd"}
#                               $pdb{"source"}
#                               $pdb{"percentage_strange"}= 
#                                              percentage (0-100) of 'strange' acids ('!X')
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."pdbExtrSequence";
    $fhinLoc="FHIN_"."pdbExtrSequence";$fhoutLoc="FHOUT_"."pdbExtrSequence";
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
    return(&errSbr("not def LskipNucleic!"))       if (! defined $LskipNucleic);
    $maxUnkLoc=100                                 if (! defined $maxUnkLoc);

    return(&errSbr("no fileIn=$fileInLoc!"))       if (! -e $fileInLoc);

				# open file
    open($fhinLoc,$fileInLoc) || return(&errSbr("fileInLoc=$fileInLoc, not opened"));
    undef %pdb;			# security
    $#chainLoc=0;
    $ctLine=0;			# count lines in file (for error)
    $ctStrange=0;		# count amino acids (non ACGT)
    $ctRes=0;
    $Lflag=0;			# set to 1 as soon as sequence found

				# ------------------------------
    while (<$fhinLoc>) {	# read file
				# ------------------------------
	++$ctLine;
				# skip anything before sequence
	if ($_!~/^SEQRES/) {

#HEADER    HYDROLASE (SERINE PROTEINASE)           24-APR-89   1P06      1P06   3
	    if ($_=~/^HEADER\s+(.*)\d\d\-[A-Z][A-Z][A-Z]\-\d\d\s*\d\w\w\w\s+/){
		$pdb{"header"}=$1;
		$pdb{"header"}=~s/^\s*|\s*$//g;
		$pdb{"header"}=~s/^\s\s+|\s//g;
		next; }
#COMPND    ALPHA-LYTIC PROTEASE (E.C.3.4.21.12) COMPLEX WITH             1P06   4
#COMPND   2 METHOXYSUCCINYL-*ALA-*ALA-*PRO-*PHENYLALANINE BORONIC ACID   1P06   5
	    if ($_=~/^COMPND\s+(.*)\s+\d\w\w\w\s+\d+\s*$/) {
		$pdb{"compnd"}="" if (! defined $pdb{"compnd"});
		$pdb{"compnd"}.=$1;
		$pdb{"compnd"}=~s/^\s*|\s*$//g;
		$pdb{"compnd"}=~s/\s\s+/ /g; # purge many blanks
		next; }
#SOURCE    (LYSOBACTER $ENZYMOGENES 495)                                 1P06   6
	    if ($_=~/^SOURCE\s+(.*)\s+\d\w\w\w\s+\d+\s*$/) {
		$pdb{"source"}=$1; $pdb{"source"}=~s/[\(\)\$]//g;
		$pdb{"source"}=~s/^\s*|\s*$//g;
		$pdb{"source"}=~s/\s\s+/ /g; # purge many blanks
		next; }
	    last if ($Lflag);	# end after read
	    next; }
				# delete stuff at ends
#....,....1....,....2....,....3....,....4....,....5....,....6....,....7....,....8
#SEQRES   1 A  198  ALA ASN ILE VAL GLY GLY ILE GLU TYR SER ILE ASN ASN  1P06  74
	$Lflag=1;			# sequence found
	$_=~s/\n//g;
	$line=substr($_,11);
	$line=substr($line,1,60);
	$chainRd=$line; $chainRd=~s/^\s*(\D*)\d+.*$/$1/g; $chainRd=~s/\s//g;
	$chainRd="*"            if (! defined $chainRd || length($chainRd)<1);
				# skip if wrong chain
	next if ($chainInLoc ne "*" && $chainRd ne $chainInLoc);
				# rename chain for non-specified
	$chainRd="none"         if ($chainRd eq "*");

				# get sequence part
	$seqRd3= $line; $seqRd3=~s/^\D*\d+(\D+).*$/$1/g;
	$seqRd3=~s/^\s*|\s*$//g; # purge trailing spaces
				# strange
	next if (! defined $seqRd3 || length($seqRd3)<3);
				# non acids
	next if ($seqRd3=~/^(FOR)/);
				# split into array of 3-letter residues
	@tmp=split(/\s+/,$seqRd3);

				# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
				# skip if is nucleic that was
				# NOT wanted !
	next if ($LskipNucleic && $tmp[1]=~/^[ACGT]$/);
				# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

	$seqRd1="";		# 3 letter to 1 letter
	foreach $tmp (@tmp) {
	    ($Lok,$msg,$oneletter)=&amino_acid_convert_3_to_1($tmp);
				# HETERO atom?
	    if    (! $Lok && $oneletter eq "unk") {
		print "-*- WARN $fileInLoc ($ctLine) residue =$tmp\n";
		$oneletter="X";}
	    elsif (! $Lok || $oneletter !~/^[A-Z]$/) { 
		$msgErr="*** $sbrName ($fileInLoc): line=$ctLine, problem with conversion to 1 letter:\n";
		print "xx ".$msgErr.$msg."\n"; exit; # xx
		return(0,$msgErr.$msg); }
	    $seqRd1.=$oneletter; }
				# first
	if (! defined $pdb{$chainRd}) {
	    push(@chainLoc,$chainRd);
	    $pdb{$chainRd}=""; }
				# append to current chain
	$pdb{$chainRd}.=$seqRd1;
				# count non ACGT
	@tmp=split(//,$seqRd1);
	$ctRes+=$#tmp;		# count residues
	foreach $tmp (@tmp) {
	    next if ($tmp!~/^[ABCDEFGHIKLMNPQRSTVWXYZ]$/); # exclude strange stuff
	    ++$ctStrange;}
    } close($fhinLoc);

    return(2,"nucleic","") if ($LskipNucleic && $ctRes < 1);

				# ------------------------------
				# check number of unknown residues
    if ($maxUnkLoc<100){
	$#tmp=0;
	foreach $chain (@chainLoc){
	    $ct=$ctx=0;
	    foreach $tmp (split(//,$pdb{$chain})){
		++$ctx          if ($tmp=~/x/i);
		++$ct;
	    }
				# take
	    if (! $ctx || 100*($ctx/$ct) <= $maxUnkLoc){
		push(@tmp,$chain); # take
	    }}
				# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
				# none found
	return(3,"too unk","")  if ($#tmp<1);
				# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
	@chainLoc=@tmp;}
    $pdb{"chains"}=join(',',@chainLoc);
    $pdb{"percentage_strange"}=0;
    $pdb{"percentage_strange"}=100*int($ctStrange/$ctRes) if ($ctStrange && $ctRes);
    return(1,"ok $sbrName",\%pdb);
}				# end of pdbExtrSequence

#===============================================================================
sub pdbExtrSequenceATOM {
    local($fileInLoc,$chainInLoc,$LskipNucleic,$maxUnkLoc) = @_ ;
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   pdbExtrSequenceATOM         reads the sequence in a PDB file
#                               FROM ATOM LINE
#       in:                     $fileInLoc=    PDB file
#       in:                     $chainInLoc=   chains to read ('A,B,C' for many)
#                                  ='*'        to read all
#       in:                     $LskipNucleic= skip if nucleic acids
#       in:                     $maxUnkLoc=    maximal percentage of unknown residues
#       out:                    0,$msg         ERROR
#       out:                    2,$msg,        NUCLEIC
#       out:                    3,$msg,        too many unknown residues
#       out:                    1,"ok",%pdb as implicit reference with:
#       out:                    $pdb{"chains"}="A,B" -> all chains found ('none' for not specified)
#                               $pdb{$chain}=  sequence for chain $chain 
#                                              (='none' for not specified chain)
#                               NOTE: 'X' used for hetero-atoms, or for symbol 'U'
#                               $pdb{"header"}
#                               $pdb{"compnd"}
#                               $pdb{"source"}
#                               $pdb{"percentage_strange"}= 
#                                              percentage (0-100) of 'strange' acids ('!X')
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."pdbExtrSequenceATOM";
    $fhinLoc="FHIN_"."pdbExtrSequenceATOM";$fhoutLoc="FHOUT_"."pdbExtrSequenceATOM";
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
    return(&errSbr("not def chainInLoc!"))         if (! defined $chainInLoc);
    return(&errSbr("not def LskipNucleic!"))       if (! defined $LskipNucleic);
    $maxUnkLoc=100                                 if (! defined $maxUnkLoc);

    $chainInLoc="*"                                if (length($chainInLoc) < 1 || 
						       $chainInLoc =~/\s/);
    return(&errSbr("no fileIn=$fileInLoc!"))       if (! -e $fileInLoc);

				# open file
    open($fhinLoc,$fileInLoc) || return(&errSbr("fileInLoc=$fileInLoc, not opened"));
    undef %pdb;			# security
    $#chainLoc=0;
    $ctLine=0;			# count lines in file (for error)
    $ctStrange=0;		# count amino acids (non ACGT)
    $ctRes=0;
    $Lflag=0;			# set to 1 as soon as sequence found

    $noprev=0;
    undef %tmpdone;
				# ------------------------------
    while (<$fhinLoc>) {	# read file
				# ------------------------------

				# avoid duplication for NMR
	last if ($_=~/^MODEL   \s+(\d+)/ && $1 > 1);

	++$ctLine;
				# skip anything before sequence
	if (! $Lflag && $_ !~ /^ATOM/) {

#HEADER    HYDROLASE (SERINE PROTEINASE)           24-APR-89   1P06      1P06   3
	    if ($_=~/^HEADER\s+(.*)\d\d\-[A-Z][A-Z][A-Z]\-\d\d\s*\d\w\w\w\s+/){
		$pdb{"header"}=$1;
		$pdb{"header"}=~s/^\s*|\s*$//g;
		$pdb{"header"}=~s/^\s\s+|\s//g;
		next; }
#COMPND    ALPHA-LYTIC PROTEASE (E.C.3.4.21.12) COMPLEX WITH             1P06   4
#COMPND   2 METHOXYSUCCINYL-*ALA-*ALA-*PRO-*PHENYLALANINE BORONIC ACID   1P06   5
	    if ($_=~/^COMPND\s+(.*)\s+\d\w\w\w\s+\d+\s*$/) {
		$pdb{"compnd"}="" if (! defined $pdb{"compnd"});
		$pdb{"compnd"}.=$1;
		$pdb{"compnd"}=~s/^\s*|\s*$//g;
		$pdb{"compnd"}=~s/\s\s+/ /g; # purge many blanks
		next; }
#SOURCE    (LYSOBACTER $ENZYMOGENES 495)                                 1P06   6
	    if ($_=~/^SOURCE\s+(.*)\s+\d\w\w\w\s+\d+\s*$/) {
		$pdb{"source"}=$1; $pdb{"source"}=~s/[\(\)\$]//g;
		$pdb{"source"}=~s/^\s*|\s*$//g;
		$pdb{"source"}=~s/\s\s+/ /g; # purge many blanks
		next; }
	    next; }

				# delete stuff at ends
#....,....1....,....2....,....3....,....4....,....5....,....6....,....7....,....8
#ATOM      1  N   GLY     1       2.296  -9.636  18.253  1.00  0.00      1PPT  65
#ATOM      2  CA  GLY     1       1.470  -9.017  17.255  1.00  0.00      1PPT  66
#ATOM      3  C   GLY     1        .448  -9.983  16.703  1.00  0.00      1PPT  67
#ATOM      4  O   GLY     1        .208 -11.066  17.345  1.00  0.00      1PPT  68
#ATOM   2596  C   LYS C 332
	next if ($_ !~/^ATOM/);

	$Lflag=1;		# sequence found
	$_=~s/\n//g;
	$seqRd3= substr($_,18,4);$seqRd3=~s/\s//g;
	$no=     substr($_,22,5);$no=~s/\s//g;
				# skip if same residue as before
	next if ($no eq $noprev);
				# avoid duplication for NMR
	next if (defined $tmpdone{$no});

	$noprev=$no;
	$tmpdone{$no}=1;	# avoid duplication for NMR

	$chainRd=substr($_,22,1);
	$chainRd="*"            if ($chainRd eq " " || length($chainRd)<1);
				# skip if wrong chain
	next if ($chainInLoc ne "*" && $chainRd ne $chainInLoc);
				# rename chain for non-specified
	$chainRd="none"         if ($chainRd eq "*");

				# get sequence part

				# HACK strange: skip
	next if (! defined $seqRd3 || length($seqRd3)<3);
				# split into array of 3-letter residues

				# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
				# skip if is nucleic that was
				# NOT wanted !
	next if ($LskipNucleic && $seqRd3=~/^[ACGT]$/);
				# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

	$seqRd1="";		# 3 letter to 1 letter
	($Lok,$msg,$oneletter)=&amino_acid_convert_3_to_1($seqRd3);
#	print "xx seqRd3=$seqRd3 ch=$chainRd $oneletter\n";
				# HETERO atom?
	if    (! $Lok && $oneletter eq "unk") {
	    print "-*- WARN $fileInLoc ($ctLine) residue =$tmp\n";
	    $oneletter="X";}
	elsif (! $Lok || $oneletter !~/^[A-Z]$/) { 
	    $msgErr="*** $sbrName ($fileInLoc): line=$ctLine, problem with conversion to 1 letter:\n";
	    print "xx ".$msgErr.$msg."\n"; exit; # xx
	    return(0,$msgErr.$msg); }
	$seqRd1.=$oneletter; 
				# first
	if (! defined $pdb{$chainRd}) {
	    push(@chainLoc,$chainRd);
	    $pdb{$chainRd}=""; }
				# append to current chain
	$pdb{$chainRd}.=$seqRd1;
    }
    close($fhinLoc);
    $ctRes=0;
    foreach $chain (@chainLoc){
				# count non ACGT
	@tmp=split(//,$pdb{$chain});
	$ctRes+=$#tmp;		# count residues
	foreach $tmp (@tmp) {
	    next if ($tmp!~/^[ABCDEFGHIKLMNPQRSTVWXYZ]$/); # exclude strange stuff
	    ++$ctStrange;
	}
    } 

    return(2,"nucleic","") if ($LskipNucleic && $ctRes < 1);

				# ------------------------------
				# check number of unknown residues
    if ($maxUnkLoc<100){
	$#tmp=0;
	foreach $chain (@chainLoc){
	    $ct=$ctx=0;
	    foreach $tmp (split(//,$pdb{$chain})){
		++$ctx          if ($tmp=~/x/i);
		++$ct;
	    }
				# take
	    if (! $ctx || 100*($ctx/$ct) <= $maxUnkLoc){
		push(@tmp,$chain); # take
	    }}
				# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
				# none found
	return(3,"too unk","")  if ($#tmp<1);
				# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
	@chainLoc=@tmp;}
    $pdb{"chains"}=join(',',@chainLoc);
    $pdb{"percentage_strange"}=0;
    $pdb{"percentage_strange"}=100*int($ctStrange/$ctRes) if ($ctStrange && $ctRes);
    return(1,"ok $sbrName",\%pdb);
}				# end of pdbExtrSequenceATOM

#===============================================================================
sub pdbExtrSequenceSEQRES {
    local($fileInLoc,$chainInLoc,$LskipNucleic,$maxUnkLoc) = @_ ;
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   pdbExtrSequenceSEQRES       reads the sequence in a PDB file
#                               FROM SEQRES LINE in header
#       in:                     $fileInLoc=    PDB file
#       in:                     $chainInLoc=   chains to read ('A,B,C' for many)
#                                  ='*'        to read all
#       in:                     $LskipNucleic= skip if nucleic acids
#       in:                     $maxUnkLoc=    maximal percentage of unknown residues
#       out:                    0,$msg         ERROR
#       out:                    2,$msg,        NUCLEIC
#       out:                    3,$msg,        too many unknown residues
#       out:                    1,"ok",%pdb as implicit reference with:
#       out:                    $pdb{"chains"}="A,B" -> all chains found ('none' for not specified)
#                               $pdb{$chain}=  sequence for chain $chain 
#                                              (='none' for not specified chain)
#                               NOTE: 'X' used for hetero-atoms, or for symbol 'U'
#                               $pdb{"header"}
#                               $pdb{"compnd"}
#                               $pdb{"source"}
#                               $pdb{"percentage_strange"}= 
#                                              percentage (0-100) of 'strange' acids ('!X')
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."pdbExtrSequenceSEQRES";
    $fhinLoc="FHIN_"."pdbExtrSequenceSEQRES";$fhoutLoc="FHOUT_"."pdbExtrSequenceSEQRES";
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
    return(&errSbr("not def chainInLoc!"))         if (! defined $chainInLoc);
    return(&errSbr("not def LskipNucleic!"))       if (! defined $LskipNucleic);
    $maxUnkLoc=100                                 if (! defined $maxUnkLoc);

    $chainInLoc="*"                                if (length($chainInLoc) < 1 || 
						       $chainInLoc =~/\s/);
    return(&errSbr("no fileIn=$fileInLoc!"))       if (! -e $fileInLoc);

				# open file
    open($fhinLoc,$fileInLoc) || return(&errSbr("fileInLoc=$fileInLoc, not opened"));
    undef %pdb;			# security
    $#chainLoc=0;
    $ctLine=0;			# count lines in file (for error)
    $ctStrange=0;		# count amino acids (non ACGT)
    $ctRes=0;
    $Lflag=0;			# set to 1 as soon as sequence found

				# ------------------------------
    while (<$fhinLoc>) {	# read file
				# ------------------------------
	++$ctLine;
				# skip anything before sequence
	if ($_!~/^SEQRES/) {

#HEADER    HYDROLASE (SERINE PROTEINASE)           24-APR-89   1P06      1P06   3
	    if ($_=~/^HEADER\s+(.*)\d\d\-[A-Z][A-Z][A-Z]\-\d\d\s*\d\w\w\w\s+/){
		$pdb{"header"}=$1;
		$pdb{"header"}=~s/^\s*|\s*$//g;
		$pdb{"header"}=~s/^\s\s+|\s//g;
		next; }
#COMPND    ALPHA-LYTIC PROTEASE (E.C.3.4.21.12) COMPLEX WITH             1P06   4
#COMPND   2 METHOXYSUCCINYL-*ALA-*ALA-*PRO-*PHENYLALANINE BORONIC ACID   1P06   5
	    if ($_=~/^COMPND\s+(.*)\s+\d\w\w\w\s+\d+\s*$/) {
		$pdb{"compnd"}="" if (! defined $pdb{"compnd"});
		$pdb{"compnd"}.=$1;
		$pdb{"compnd"}=~s/^\s*|\s*$//g;
		$pdb{"compnd"}=~s/\s\s+/ /g; # purge many blanks
		next; }
#SOURCE    (LYSOBACTER $ENZYMOGENES 495)                                 1P06   6
	    if ($_=~/^SOURCE\s+(.*)\s+\d\w\w\w\s+\d+\s*$/) {
		$pdb{"source"}=$1; $pdb{"source"}=~s/[\(\)\$]//g;
		$pdb{"source"}=~s/^\s*|\s*$//g;
		$pdb{"source"}=~s/\s\s+/ /g; # purge many blanks
		next; }
	    last if ($Lflag);	# end after read
	    next; }
				# delete stuff at ends
#....,....1....,....2....,....3....,....4....,....5....,....6....,....7....,....8
#SEQRES   1 A  198  ALA ASN ILE VAL GLY GLY ILE GLU TYR SER ILE ASN ASN  1P06  74
	$Lflag=1;			# sequence found
	$_=~s/\n//g;
	$line=substr($_,11);
	$line=substr($line,1,60);
	$chainRd=$line; $chainRd=~s/^\s*(\D*)\d+.*$/$1/g; $chainRd=~s/\s//g;
	$chainRd="*"            if (! defined $chainRd || length($chainRd)<1);
				# skip if wrong chain
	next if ($chainInLoc ne "*" && $chainRd ne $chainInLoc);
				# rename chain for non-specified
	$chainRd="none"         if ($chainRd eq "*");

				# get sequence part
	$seqRd3= $line; $seqRd3=~s/^\D*\d+(\D+).*$/$1/g;
	$seqRd3=~s/^\s*|\s*$//g; # purge trailing spaces
				# strange
	next if (! defined $seqRd3 || length($seqRd3)<3);
				# split into array of 3-letter residues
	@tmp=split(/\s+/,$seqRd3);

				# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
				# skip if is nucleic that was
				# NOT wanted !
	next if ($LskipNucleic && $tmp[1]=~/^[ACGT]$/);
				# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

	$seqRd1="";		# 3 letter to 1 letter
	foreach $tmp (@tmp) {
	    ($Lok,$msg,$oneletter)=&amino_acid_convert_3_to_1($tmp);
				# HETERO atom?
	    if    (! $Lok && $oneletter eq "unk") {
		print "-*- WARN $fileInLoc ($ctLine) residue =$tmp\n";
		$oneletter="X";}
	    elsif (! $Lok || $oneletter !~/^[A-Z]$/) { 
		$msgErr="*** $sbrName ($fileInLoc): line=$ctLine, problem with conversion to 1 letter:\n";
		print "xx ".$msgErr.$msg."\n"; exit; # xx
		return(0,$msgErr.$msg); }
	    $seqRd1.=$oneletter; }
				# first
	if (! defined $pdb{$chainRd}) {
	    push(@chainLoc,$chainRd);
	    $pdb{$chainRd}=""; }
				# append to current chain
	$pdb{$chainRd}.=$seqRd1;
				# count non ACGT
	@tmp=split(//,$seqRd1);
	$ctRes+=$#tmp;		# count residues
	foreach $tmp (@tmp) {
	    next if ($tmp!~/^[ABCDEFGHIKLMNPQRSTVWXYZ]$/); # exclude strange stuff
	    ++$ctStrange;}
    } close($fhinLoc);

    return(2,"nucleic","") if ($LskipNucleic && $ctRes < 1);

				# ------------------------------
				# check number of unknown residues
    if ($maxUnkLoc<100){
	$#tmp=0;
	foreach $chain (@chainLoc){
	    $ct=$ctx=0;
	    foreach $tmp (split(//,$pdb{$chain})){
		++$ctx          if ($tmp=~/x/i);
		++$ct;
	    }
				# take
	    if (! $ctx || 100*($ctx/$ct) <= $maxUnkLoc){
		push(@tmp,$chain); # take
	    }}
				# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
				# none found
	return(3,"too unk","")  if ($#tmp<1);
				# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
	@chainLoc=@tmp;}
    $pdb{"chains"}=join(',',@chainLoc);
    $pdb{"percentage_strange"}=0;
    $pdb{"percentage_strange"}=100*int($ctStrange/$ctRes) if ($ctStrange && $ctRes);
    return(1,"ok $sbrName",\%pdb);
}				# end of pdbExtrSequenceSEQRES

#===============================================================================
sub amino_acid_convert_3_to_1 {
    local($three_letter_acid) = @_ ;
    local($sbrName3);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   amino_acid_convert_3_to_1   converts 3 letter alphabet to single letter alphabet
#       in:                     $three_letter_acid
#       out:                    1|0,msg,$one_letter_acid
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName3="amino_acid_convert_3_to_1";
    return(0,"no input to $sbrName3") if (! defined $three_letter_acid);
				# initialise translation table
    &amino_acid_convert_3_to_1_ini()  
	if (! defined %amino_acid_convert_3_to_1);
				# not found
    return(0,"no conversion for acid=$three_letter_acid!","unk") 
	if (! defined $amino_acid_convert_3_to_1{$three_letter_acid});
				# ok
    return(1,"ok",$amino_acid_convert_3_to_1{$three_letter_acid});
}				# end of amino_acid_convert_3_to_1

#===============================================================================
sub amino_acid_convert_3_to_1_ini {
#-------------------------------------------------------------------------------
#   amino_acid_convert_3_to_1_ini returns GLOBAL array with 3 letter acid -> 1 letter
#       out GLOBAL:             %amino_acid_convert_3_to_1
#-------------------------------------------------------------------------------
    %amino_acid_convert_3_to_1=
	(
				# amino
	 'ALA',"A",
	 'ARG',"R",
	 'ASN',"N",
	 'ASP',"D",
	 'CYS',"C",
	 'GLN',"Q",
	 'GLU',"E",
	 'GLY',"G",
	 'HIS',"H",
	 'ILE',"I",
	 'LEU',"L",
	 'LYS',"K",
	 'MET',"M",
	 'PHE',"F",
	 'PRO',"P",
	 'SER',"S",
	 'THR',"T",
	 'TRP',"W",
	 'TYR',"Y",
	 'VAL',"V",
				# nucleic
	 'A',  "A",
	 'C',  "C",
	 'G',  "G",
	 'T',  "T",
	 );
}				# end of amino_acid_convert3_to_1

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

