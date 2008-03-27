#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="reads all FASTA files in dir /data/derived/big/split*/\n".
    "     \t and writes one-line index kind of file\n".
    "     \t input:  <auto|file.fasta>\n".
    "     \t output: index file\n".
    "     \t \n".
    "     \t \n".
    "     \t NOTE:  USED by crontab!\n".
    "     \t \n".
    "     \t ";
#  
# 
#------------------------------------------------------------------------------#
#	Copyright				        	2001	       #
#	Burkhard Rost		rost@columbia.edu			       #
#	CUBIC (Columbia Univ)	http://cubic.bioc.columbia.edu/   	       #
#       Dept Biochemistry & Molecular Biophysics			       #
#       630 West, 168 Street						       #
#	New York, NY 10032	http://www.columbia.edu/~rost/                 #
#				version 0.1   	May,    	2001	       #
#------------------------------------------------------------------------------#
#

$[ =1 ;				# count from one

				# ------------------------------
				# defaults
$exegzip="/usr/sbin/gzip";
$exegzip="/usr/local/bin/gzip"  if (! -e $exegzip && ! -l $exegzip);
$exegzip="/bin/gzip"            if (! -e $exegzip && ! -l $exegzip);

%par=(
      'minLen',  30,
      '', "",			# 
#      'extIn',                  ".f,.fasta", # valid extensions for input files
      'fileOutDef',             "ONELINE_big.rdb",
#      'exeSysGzip',             "/usr/sbin/gzip",
      'exeSysGzip',             $exegzip,
      '', "",			# 
      );

$par{"dirDataBig"}=             "/data/derived/big/";
$par{"dirDataBig","pdb"}=       $par{"dirDataBig"}."splitPdb/";
$par{"dirDataBig","swiss"}=     $par{"dirDataBig"}."splitSwiss/";
$par{"dirDataBig","trembl"}=    $par{"dirDataBig"}."splitTrembl/";

$par{"file","big"}=             "/data/derived/big/big";
$par{"file","pdb"}=             "/data/derived/big/pdb";
$par{"file","swiss"}=           "/data/derived/big/sprot.fas";
$par{"file","trembl"}=          "/data/derived/big/trembl.fas,/data/derived/big/trembl_new.fas";

$par{"fileOutDef"}=             "ONELINE_big.rdb";
$par{"fileOutDef","swiss"}=     "ONELINE_swiss.rdb";
$par{"fileOutDef","trembl"}=    "ONELINE_trembl.rdb";
$par{"fileOutDef","pdb"}=       "ONELINE_pdb.rdb";

#$par{"db2add"}=                 "pdb,swiss,trembl";
@db2do=
    (
     "big",
#     "pdb",
#     "swiss",
#     "trembl",
     );

$par{"db2add"}=                 "";


@kwd=sort (keys %par);
$Ldebug=       0;
$Lverb=        0;
#$Lseparate=0;
$sep=          "\t";		# separator for output

				# initialise variables
$fhin="FHIN";$fhout="FHOUT";
$#fileIn=      0;
$dirOut=       0;
$Lauto=        0;
$LdoGzip=      1;
$LestimateTime=1;
				# ------------------------------
if ($#ARGV<1 ||			# help
	$ARGV[1] =~/^(-h|help|special)/){
    print  "goal: $scrGoal\n";
    print  "use:  '$scrName <auto|dir_with_fasta|file*.f|pdb|swiss|trembl>'\n";
    print  "opt:  \n";
				#      'keyword'   'value'    'description'
    printf "%5s %-15s=%-20s %-s\n","","fileOut",  "x",       "name of output file (only when running a single db)";
    printf "%5s %-15s=%-20s %-s\n","","dirOut",   "x",       "if given: name fileIn=fileOut BUT in dirOut";

#    printf "%5s %-15s %-20s %-s\n","","sep",      "no value","separate writing of different databases";
    printf "%5s %-15s=%-20s %-s\n","","db",       "swiss|trembl|pdb", "use that db ('swiss,pdb' for many)";

    printf "%5s %-15s %-20s %-s\n","","swiss",    "no value","check SWISS-PROT";
    printf "%5s %-15s %-20s %-s\n","","trembl",   "no value","check TrEMBL";
    printf "%5s %-15s %-20s %-s\n","","pdb",      "no value","check PDB";

    printf "%5s %-15s %-20s %-s\n","","time|est","no value","estimate time";
    printf "%5s %-15s %-20s %-s\n","","notime|noest","no value","do not estimate time";

    printf "%5s %-15s %-20s %-s\n","","zip|gzip", "no value","zip up output file";
    printf "%5s %-15s %-20s %-s\n","","no(zip|gzip)", "no value","do not zip up output file";

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
				# ------------------------------
				# read command line
#$#dirIn=0;
$#fileIn=0;
foreach $arg (@ARGV){
#    next if ($arg eq $ARGV[1]);
    if    ($arg=~/^fileOut=(.*)$/i)       { $fileOut=        $1;}
    elsif ($arg=~/^dirOut=(.*)$/i)        { $dirOut= $1;
					    $dirOut.="/"     if ($dirOut !~ /\/$/);}

    elsif ($arg=~/^de?bu?g$/)             { $Ldebug=         1;
					    $Lverb=          1;}
    elsif ($arg=~/^verb(ose)?$|^\-v$/)    { $Lverb=          1;}
    elsif ($arg=~/^silent$|^\-s$/)        { $Lverb=          0;}

    elsif ($arg=~/^(time|est)$/)          { $LestimateTime=  1;}
    elsif ($arg=~/^no(time|est)$/)        { $LestimateTime=  0;}

    elsif ($arg=~/^(zip|gzip)$/)          { $LdoGzip=        1;}
    elsif ($arg=~/^no(zip|gzip)$/)        { $LdoGzip=        0;}

#    elsif ($arg=~/^sep.*$/)               { $Lseparate=      1;}
    elsif ($arg=~/^auto$/)                { $Lauto=          1;}

    elsif ($arg=~/^(pdb|swiss|trembl)$/i) { $par{"db2add"}.= $1.","; 
					    $par{"db2add"}=~tr/[A-Z]/[a-z]/;}

    elsif ($arg=~/^db=(.*)$/)             { $par{"db2add"}=  $1;
					    $par{"db2add"}=~tr/[A-Z]/[a-z]/;}

#    elsif ($arg=~/^=(.*)$/){ $=$1;}
#    elsif (-d $arg)                       { push(@dirIn, $arg); }
    elsif (-e $arg)                       { push(@fileIn,$arg); }
    else {
	$Lok=0; 
	if (defined %par && $#kwd>0) { 
	    foreach $kwd (@kwd){ 
		if ($arg =~ /^$kwd=(.+)$/){$Lok=1;$par{$kwd}=$1;
					   last;}}}
	if (! $Lok){ print "*** wrong command line arg '$arg'\n";
		     exit;}}}

$#db2do=0
    if (! $Lauto);

if (defined $par{"db2add"} && length($par{"db2add"})>2){
    $par{"db2add"}=~s/^,|,$//g;
    push(@db2do,split(/,/,$par{"db2add"}));
}

				# ------------------------------
				# add output directory
if (defined $dirOut && length($dirOut) > 0 && $dirOut){
				# make dir if missing
    if (! -d $dirOut && ! -l $dirOut){
	$cmd="mkdir ".$dirOut;
	print "--- system '$cmd'\n";
	system("$cmd");
	$cmd="chmod +rx ".$dirOut;
	print "--- system '$cmd'\n";
	system("$cmd");
    }
				# add slash
    $dirOut.="/"                if ($dirOut !~ /\/$/);
}
else {
    $dirOut="";}
				# ------------------------------
				# output file name
if (! defined $fileOut || $#db2do > 1){
				# oops correct if only one wanted
    foreach $db (@db2do){
	$fileOut{$db}= $dirOut.$par{"fileOutDef"};
	$fileOut{$db}=~s/big/$db/;
    }
    $fileOut=$fileOut{$db2do[1]};
}

$timeBeg=time;

if ($#db2do < 1){
    print "*** ERROR $scrName: something went wrong, no valid input file (give argument 'auto')\n";
    exit;}

				# --------------------------------------------------
				# (1) read all input files to check stuff and time
				# --------------------------------------------------
$linesTotal=0;
foreach $db (@db2do){
				# ------------------------------
				# which input file?
    if (! defined $par{"file",$db}){
	print "*** ERROR $scrName: no input file given db=$db\n";
	exit;}

    $fileIn=$par{"file",$db};
    if ($fileIn=~/,/){
	@fileIn=split(/,/,$fileIn);}
    else {
	@fileIn=($fileIn);}

    foreach $fileIn (@fileIn){

	if (! -e $fileIn && ! -l $fileIn){
	    print "*** ERROR $scrName: input file(db=$db)=",$fileIn,", is missing!\n";
	    exit;}
				# estimate run time
	if ($LestimateTime){
	    $tmp=`wc -l $fileIn`;
	    $tmp=~s/^\s*//g;
	    $tmp=~s/\s.*$//g;
	    $tmp=~s/\D//g;
	    $linesTotal+=$tmp;
	}
    }

    if (! defined $fileOut{$db}){
	print "*** ERROR $scrName: no output file given db=$db\n";
	exit;
    }
}
				# --------------------------------------------------
				# (2) read all input files and write
				# --------------------------------------------------
$ctlines=0;
foreach $db (@db2do){
    print "--- $scrName: db=$db \n" if ($Ldebug);

				# ------------------------------
				# new output file
    $fileOut=$fileOut{$db};
    open($fhout,">".$fileOut) || warn "*** $scrName ERROR creating fileOut=$fileOut";
    print $fhout
	"id",$sep,"description",$sep,"sequence","\n";


    $fileIn=$par{"file",$db};
    if ($fileIn=~/,/){
	@fileIn=split(/,/,$fileIn);}
    else {
	@fileIn=($fileIn);
    }
				# ------------------------------
				# open fasta file for db
    foreach $fileIn (@fileIn){
	print "--- $scrName: db=$db file=$fileIn\n" if ($Ldebug);
	open($fhin,$fileIn) || die "*** $scrName ERROR opening fileIn=$fileIn!";
	$#idtmp=0;
	while (<$fhin>) {
	    ++$ctlines;
	    $_=~s/\n//g;
	    $line=$_;
				# ------------------------------
				# sequence
	    if ($line !~/^\s*\>/){
		$line=~s/\s//g;
		$seq.=$line;
		next;}
				# ------------------------------
				# write out
	    $Lskip=&asswrtentry()
		if ($#idtmp);
				# ------------------------------
				# id
	    $id=$_;
	    $id=~s/^\s*>\s*|\s*$//g;
	    $idshort=$id;
	    $idshort=~s/^(\S+)(.*)$/$1/;
	    $idname= " ";
	    $idname= $2         if (defined $2 && length($2)>0);
	    $seq="";
	    push(@idtmp,$id);
	    
				# ------------------------------
				# write note about where we are
	    if ($Lverb && $linesTotal && int($ctlines/10000)==($ctlines/10000)){
		($Lok,$tmp,$txt)=
		    &fctRunTimeFancy($db,100*(1-$ctlines/$linesTotal),1);
		$txt=~s/\n//g;
		print $txt,"\n";
		if (0){
		    printf 
			"--- $scrName: working on %-25s %4d (%4.1f perc of job)\n",
			$db,$ctlines,(100*$ctlines/$linesTotal);
		}
	    }
	    elsif ($Lverb && ! $linesTotal){
		print "--- $scrName working on file=$fileIn\n";
	    }
	}
	close($fhin);
				# ------------------------------
				# write last one (of this file)
	$Lskip=&asswrtentry()
	    if ($#fileIn ne $fileIn[1]);
    }
				# write last one for all
    $Lskip=&asswrtentry();
    close($fhout);
				# compress
    if ($LdoGzip && $fileOut !~/\.gz/){
	$tmp=$fileOut.".gz";
	$cmd=$par{"exeSysGzip"}." -f ".$fileOut;
	print "--- system '$cmd'\n" if ($Lverb);
	system("$cmd");
	$fileOut=$tmp;
    }
    push(@fileOut,$fileOut);
}

if ($Lverb){
    foreach $fileOut(@fileOut){
	print "--- output in $fileOut\n" if (-e $fileOut);
    }}

exit;


#===============================================================================
sub asswrtentry {
    local($sbrName,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   asswrtentry                 writes one entry: all global
#       out:                    1-> ok 0->skip
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."asswrtentry";
				# sequence ok?
    if (! defined $seq){
	print "--- problem id=$id (file=$fileIn)\n"
	    if ($Ldebug);
	return(0); }
				# process sequence
    $seq=~s/\s//g;
    $seq=~tr/[a-z]/[A-Z]/;
				# replace strange acids
    $seq=~s/[^ABCDEFGHJKLMNPQRSTVWXYZ]//g;
    if (length($seq) < $par{"minLen"}){
	print "--- too short id=$id, seq=",$seq,", (file=$fileIn)\n"
	    if ($Ldebug);
	return(0); }

    print $fhout
	$idshort,$sep,$idname,$sep,$seq,"\n";

    return(1);
}				# end of asswrtentry

#===============================================================================
sub errSbr    {local($txtInLoc,$sbrNameLocy) = @_ ;
#-------------------------------------------------------------------------------
#   errSbr                      simply writes '*** ERROR $sbrName: $txtInLoc'
#-------------------------------------------------------------------------------
	       $sbrNameLocy=$sbrName if (! defined $sbrNameLocy);
	       $txtInLoc.="\n"       if ($txtInLoc !~/\n$/);
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
	    $timeTotLoc=int($timeRunLoc*100/(100-$percLoc))
		if ($percLoc < 100);
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
	sprintf("%-10s %3d%-1s |".$tmpformatLoc."| %-s\n",
		substr($nameLoc,1,10),
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

