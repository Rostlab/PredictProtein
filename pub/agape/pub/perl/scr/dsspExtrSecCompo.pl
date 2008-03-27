#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="gets sec str composition from DSSP file\n".
    "     \t \n".
    "     \t ";
#  
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

$[ =1 ;				# count from one

				# ------------------------------
				# defaults
%par=(
      'want', "seq,sec,acc",
      '', "",			# 
      '', "",			# 
      );
@kwd=sort (keys %par);
$Ldebug= 0;
$Lverb=  0;
				# ------------------------------
if ($#ARGV<1 ||			# help
	$ARGV[1] =~/^(-h|help|special)/){
    print  "goal: $scrGoal\n";
    print  "use:  '$scrName *.dssp (or list)'\n";
    print  "note: chain as chn=C, or for many file.dssp_C\n";
    print  "opt:  \n";
				#      'keyword'   'value'    'description'

    printf "%5s %-15s %-20s %-s\n","","split", "no value",  "split into all chains";
    printf "%5s %-15s %-20s %-s\n","","nofile","no value",  "dumps result to screen -> NOT output file!";

    printf "%5s %-15s=%-20s %-s\n","","fileOut", "x",       "name of output file";
    printf "%5s %-15s=%-20s %-s\n","","sep",     "x",       "separator (space|blank|tab|..)";

    printf "%5s %-15s %-20s %-s\n","","HEL",   "no value",  "only 3 states (def: 8 + 3)";
    printf "%5s %-15s %-20s %-s\n","","HGIEBTSL|8","no value",  "only 8 DSSP states";

#    printf "%5s %-15s=%-20s %-s\n","","",   "x", "";
#    printf "%5s %-15s %-20s %-s\n","","",        "",         "continued";
#    printf "%5s %-15s %-20s %-s\n","","",   "no value","";

    printf "%5s %-15s %-20s %-s\n","","dbg",   "no value",   "debug mode";
    printf "%5s %-15s %-20s %-s\n","","silent|-s","no value","no screen output";
    printf "%5s %-15s %-20s %-s\n","","verb|-s",  "no value","verbose";

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
#$fhin="FHIN";
$fhout="FHOUT";
$#fileIn=0;
$LisList=0;
$kwdWant="HGIEBTSL".","."HEL";
$sep=    "\t";
$Lnochnwrt=0;
$Lsplit=   0;
$Lnofile=  0;
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

    elsif ($arg=~/^split$/i)              { $Lsplit=         1;}

    elsif ($arg=~/^chn=(.*)$/)            { $chn=            $1;}
    elsif ($arg=~/^nofile$/i)             { $Lnofile=        1;}

    elsif ($arg=~/^(HEL|HGIEBTSL)$/i)     { $kwdWant=        $1;}
    elsif ($arg=~/^8$/i)                  { $kwdWant=        "HGIEBTSL";}
    elsif ($arg=~/^sep=(.*)$/)            { $sep=            $1;
					    $sep=            "\t" if ($sep=~/tab/i);
					    $sep=            " "  if ($sep=~/blank|space/i);}

    elsif ($arg=~/^nochn$/i)              { $Lnochnwrt=      1;}

#    elsif ($arg=~/^=(.*)$/){ $=$1;}
    elsif (-e $arg)                       { push(@fileIn,$arg); 
					    $LisList=        1 if ($arg=~/\.list/);}
    elsif ($arg =~ /\.dssp_./)            { push(@fileIn,$arg); 
					    $LisList=        1 if ($arg=~/\.list/);}
    else {
	$Lok=0; 
	if (defined %par && $#kwd>0) { 
	    foreach $kwd (@kwd){ 
		if ($arg =~ /^$kwd=(.+)$/){$Lok=1;$par{$kwd}=$1;
					   last;}}}
	if (! $Lok){ print "*** wrong command line arg '$arg'\n";
		     exit;}}}

$par{"verbose"}=$Lverb;
$par{"debug"}=  $Ldebug;

$fileIn=$fileIn[1];
die ("*** ERROR $scrName: missing input $fileIn!\n") 
    if (! -e $fileIn && $fileIn !~ /_.$/);
if (! $Lnofile && ! defined $fileOut){
    $tmp=$fileIn;$tmp=~s/^.*\///g;$fileOut="Out-".$tmp;}

$kwdWant=~s/,*$//g;
@kwdWant=   split(/,/,$kwdWant);
@sec8=split(//,"HGIEBSTL");
@sec3=split(//,"HEL");

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

				# --------------------------------------------------
				# (1) read file(s)
				# --------------------------------------------------
if ($Lnofile){
    $fhout="STDOUT";}
else {
    open($fhout,">".$fileOut) || warn "*** $scrName ERROR creating fileOut=$fileOut";
}
				# header
$tmp="id".$sep."len";
foreach $kwd (@kwdWant){
    if    ($kwdWant eq "HEL"){
	@sec=@sec3;
	$kwd{$kwd}=join(",",@sec);
    }
    elsif ($kwdWant eq "HGIEBTSL"){
	@sec=@sec8;
	$kwd{$kwd}=join(",",@sec);
    }    
    else {
	@sec=split(//,$kwd);
	$kwd{$kwd}=join(",",@sec);
    }
    foreach $sec (@sec){
	$tmp.=$sep.$sec."_".$kwd;
	$sum{$kwd,$sec}=0;
    }
}

print $fhout $tmp,"\n";
print "--- \t ",$tmp,"\n" if ($par{"verbose"});


$ctfile=0;
$ctfileok=0;
$sumlen=0;
foreach $fileIn (@fileIn){
    ++$ctfile;
    $fileInLoc=$fileIn;
				# handle chains
    if    ($#fileIn==1 && defined $chn){
	$chntmp=$chn;}
    elsif ($fileIn !~ /_.$/){
	$chntmp=" ";}
    else {
	$tmp=   $fileIn;
	$tmp=~s/^.*\_(.)$/$1/g;
	$fileInLoc=~s/\_.$//g;
	$chntmp=$tmp; }
	

    if (! -e $fileInLoc){ print "-*- WARN $scrName: no fileInLoc=$fileInLoc\n";
			  next;}

    printf 
	"--- $scrName: working on %-25s %4d (%4.1f perc of job)\n",
	$fileInLoc.":".$chntmp,$ctfile,(100*$ctfile/$#fileIn)
	    if ($par{"debug"});

				# ------------------------------
				# read DSSP
    				#       out GLOBAL:
    				#       %tmp{"NROWS"}=number of residues
    				#       $tmp{$ct,"chn|seq|sec|acc|nodssp|nopdb"} respective values
    				#       $tmp{<header|compnd|source|author>}
				# ------------------------------
    ($Lok,$msg)=
	&dsspRdSeqSecAcc
	    ($fileInLoc,$chntmp,
	     "sec");	        die("*** ERROR $scrName: failed dsspRdSeqSecAcc for f=$fileIn,$chntmp!\n".
				    $msg."\n") if (! $Lok);

    $id=$fileIn;
    $id=~s/^.*\///g; 
    $id=~s/\.dssp.*$//g;
    
				# ------------------------------
				# compile sec
    $sec="";
    foreach $itres (1..$tmp{"nres"}){
	if ($tmp{$itres,"sec"} eq " "){
	    $sec.="L";}
	else {
	    $sec.=$tmp{$itres,"sec"};
	}
    }
    $len=length($sec);
    next if ($len < 30);	# HARD_CODED

    ++$ctfileok;
    $sumlen+=$len;
    foreach $kwdWant (@kwdWant){
	if    ($kwdWant eq "HEL"){
	    @sec=@sec3;
	    $sec2=$sec;
	    $sec2=~s/[ST]/L/g;
	    $sec2=~s/[IG]/H/g;
	    $sec2=~s/[B]/E/g;
	}
	elsif ($kwdWant eq "HGIEBTSL"){
	    @sec=@sec8;
	    $sec2=$sec;
	}    
	else {
	    @sec=split(//,$kwdWant);
	    $sec2=$sec;
	}
	$sum=0;
	foreach $state (@sec){
	    $sec3=$sec2;
	    $sec3=~s/[^$state]//g;
	    $tmp{$kwdWant,$state}=100*(length($sec3)/$len);
	    $sum+=$tmp{$kwdWant,$state};
	    $sum{$kwdWant,$state}+=$tmp{$kwdWant,$state};
	}
	$tmp{$kwdWant}=$sum;
    }

				# write strings
    $idtmp=$id;
    $idtmp.="_".$chntmp     if (defined $chntmp && length($chntmp)==1);
    $tmp= $idtmp;
    $tmpwrt= $tmp;
    $tmpwrt.=$sep.$len;
    foreach $kwdWant (@kwdWant){
	@tmp=split(/,/,$kwd{$kwdWant});
	foreach $state (@tmp){
	    $tmpwrt.=$sep.sprintf("%6.2f",$tmp{$kwdWant,$state});
	    if (! defined $kwdWant){print "xx kwdWant=$kwdWant\n";die;}
	    if (! defined $state)  {print "xx state=$state\n";die;}
	    if (! defined $tmp{$kwdWant,$state})  {print "xx tmp for kwd=$kwdWant, state=$state\n";die;}
	}
    }
    $tmpwrt.="\n";
    print $fhout $tmpwrt;
    print $tmpwrt           if ($par{"debug"});
}
				# ------------------------------
				# sum
$id="sum=".$ctfileok;
$tmpwrt= $id.$sep.sprintf("%6.2f",($sumlen/$ctfileok));

foreach $kwdWant (@kwdWant){
    @tmp=split(/,/,$kwd{$kwdWant});
    foreach $state (@tmp){
	$tmpwrt.=$sep.sprintf("%6.2f",$sum{$kwdWant,$state}/$ctfileok);
    }
}
$tmpwrt.="\n";
print $fhout $tmpwrt;
print $tmpwrt                  if ($par{"debug"});



close($fhout)                   if ($fhout ne "STDOUT");

print "--- output in $fileOut\n" 
    if (defined $fileOut && -e $fileOut && $par{"debug"});
exit;

#===============================================================================
sub dsspRdSeqSecAcc {
    local($fileInLoc,$chnInLoc,$kwdInLoc) = @_ ;
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   dsspRdSeqSecAcc             reads DSSP file
#                               NOTE: chain breaks are skipped!!
#                               
#       in:                     $fileInLoc:  DSSP file
#       in:                     $chnInLoc:   chain to read (' ' if all)
#       in:                     $kwdInLoc:   seq,sec,acc(nodssp,nopdb): directs what to read!
#                                            also: split -> will split into different chains
#       out:                    1|0,msg
#                               
#       out GLOBAL:             NOTE: two different versions:
#       out GLOBAL:             (1) kwdInLoc does NOT contain 'split':
#       out GLOBAL:             
#       out GLOBAL:                 %tmp{"NROWS"}=number of residues
#       out GLOBAL:                 $tmp{$ct,"chn|seq|sec|acc|nodssp|nopdb"} respective values
#       out GLOBAL:                 $tmp{<header|compnd|source|author>}
#       out GLOBAL:             
#       out GLOBAL:             (2) kwdInLoc does contain 'split' -> split into chains
#       out GLOBAL:             
#       out GLOBAL:                 %tmp{"chains"}=     all chains
#       out GLOBAL:                 %tmp{$chain,"nres"}=nres of that chain
#       out GLOBAL:                 $tmp{$chain,$ct,"chn|seq|sec|acc|nodssp|nopdb"} respective values
#       out GLOBAL:                 $tmp{<header|compnd|source|author>}
#       out GLOBAL:             
#       out GLOBAL:             
#                               
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."dsspRdSeqSecAcc";
    $fhinLoc="FHIN_"."dsspRdSeqSecAcc";$fhoutLoc="FHOUT_"."dsspRdSeqSecAcc";
				# ------------------------------
				# check arguments
    return(&errSbr("not def fileInLoc!"))     if (! defined $fileInLoc);
    return(&errSbr("not def chnInLoc!"))      if (! defined $chnInLoc);
    $kwdInLoc="seq,sec,acc"                   if (! defined $kwdInLoc);
				# ------------------------------
				# file existing?
    return(&errSbr("no fileIn=$fileInLoc!"))  if (! -e $fileInLoc && ! -l $fileInLoc);
				# ------------------------------
				# local settings
    $#kwdTmp=0;
    push(@kwdTmp,"seq")         if ($kwdInLoc=~/seq/);
    push(@kwdTmp,"sec")         if ($kwdInLoc=~/sec/);
    push(@kwdTmp,"acc")         if ($kwdInLoc=~/acc/);
    push(@kwdTmp,"nodssp")      if ($kwdInLoc=~/nodssp/);
    push(@kwdTmp,"nopdb")       if ($kwdInLoc=~/nopdb/);
    $LsplitLoc=0;  
    $LsplitLoc=1                if ($kwdInLoc=~/split/);

				# ------------------------------
				# open file
    open($fhinLoc,$fileInLoc) || return(&errSbr("fileInLoc=$fileInLoc, not opened"));

    undef %tmp;
				# ------------------------------
				# read HEADER
    while (<$fhinLoc>) {
				# stop header
	last if ($_=~/^\s*\#\s*RESIDUE/);

	$line=$_; $line=~s/\n//g;

	if ($line=~/HEADER\s+(\S.+)$/){
	    $tmp{"header"}=$1;
				# remove '  16-JAN-81   1PPT '
	    $tmp{"header"}=~s/\s+\d\d....\-\d+\s+\d...\s*$//g;
	    next; }

	if ($line=~/COMPND\s+(\S.+)$/){
	    $tmp{"compnd"}=$1;
	    $tmp{"compnd"}=~s/^\s*|\s*$//g;
	    next; }
	if ($line=~/SOURCE\s+(\S.+)$/){
	    $tmp{"source"}=$1;
	    $tmp{"source"}=~s/^\s*|\s*$//g;
	    next; }
	if ($line=~/AUTHOR\s+(\S.+)$/){
	    $tmp{"author"}=$1;
	    $tmp{"author"}=~s/^\s*|\s*$//g;
	    next; }
	if ($line=~/^\s*(\d+)\s*(\d+).*TOTAL NUMBER OF RESIDUES/){
	    $tmp{"NROWS"}= $1;
	    $tmp{"nres"}=  $tmp{"NROWS"};
	    $tmp{"nchn"}=  $2;
	    next; }
    }

				# ------------------------------
				# read file body
    $ctres=0;
    undef %chnLoc; $chnLoc{"chains"}="";
    $chnprev=0;
    
    while (<$fhinLoc>) {	# 
	$line=$_; $line=~s/\n//g;
				# all we need, are the first 40 characters of the line!
	undef %tmp2;
	$line=          substr($line,1,40);
	$chn=           substr($line,12,1);

				# skip since chain not wanted?
	next if ($chnInLoc ne " " && 
		 $chn ne $chnInLoc);

	$tmp2{"seq"}=   substr($line,14,1);

				# skip chain breaks
	next if ($tmp2{"seq"} eq "!");

	$tmp2{"nodssp"}=substr($line,1,5); $tmp2{"nodssp"}=~s/\s//g;
	$tmp2{"nopdb"}= substr($line,6,5); $tmp2{"nopdb"}=~s/\s//g;

	$tmp2{"sec"}=   substr($line,17,1);$tmp2{"sec"}=~s/ /L/;
	$tmp2{"acc"}=   substr($line,36,3);$tmp2{"acc"}=~s/\s//g;

				# split into chains
	if ($LsplitLoc && ! defined $chnLoc{$chn}){
	    $chnLoc{$chn}=1;
	    $chnLoc{"chains"}.=$chn.","; 
				# store nres
	    $tmp{$chnprev,"nres"}=
		$ctres          if ($chnprev);
	    $chnprev=$chn;
	    $ctres=0; }

	++$ctres;
	if ($LsplitLoc){
	    foreach $kwd (@kwdTmp){
		$tmp{$chn,$ctres,$kwd}=$tmp2{$kwd};
	    }}
	else {
	    foreach $kwd (@kwdTmp){
		$tmp{$ctres,$kwd}=$tmp2{$kwd};
	    }
	    $tmp{$ctres,"chn"}=   $chn;}
    }

				# correct number of residues
    $tmp{"nres"}=  
	$tmp{"NROWS"}=
	    $ctres;
    if ($LsplitLoc) {
	$tmp{$chnprev,"nres"}=$ctres;
	$chnLoc{"chains"}=~s/,*$//g;}
    if ($chnInLoc ne " " && 
	(! defined $chnLoc{"chains"} || length($chnLoc{"chains"}) < 1) ) {
	$chnLoc{"chains"}=$chnInLoc;}
    $tmp{"chains"}=$chnLoc{"chains"};
    
    
				# clean up
    undef %tmp2;		# slim-is-in
    $#kwdTmp=0;			# slim-is-in
    undef %chnLoc;		# slim-is-in
    
    return(1,"ok $sbrName");
}				# end of dsspRdSeqSecAcc

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

#==========================================================================
sub exposure_normalise_prepare {
    local ($mode) = @_;
    $[=1;
#----------------------------------------------------------------------
#    exposure_normalise_prepare normalisation weights (maximal: Schneider, Dipl)
#----------------------------------------------------------------------
#   --------------------------------------------------
#   Reinhard
#   --------------------------------------------------
    if ((!defined $mode)||(length($mode) <= 1)) {
	$NORM_EXP{"A"} = 106;  $NORM_EXP{"B"} =160;         # D or N
	$NORM_EXP{"C"} = 135;  $NORM_EXP{"D"} =163;  $NORM_EXP{"E"} =194;
	$NORM_EXP{"F"} = 197;  $NORM_EXP{"G"} = 84;  $NORM_EXP{"H"} =184;
	$NORM_EXP{"I"} = 169;  $NORM_EXP{"K"} =205;  $NORM_EXP{"L"} =164;
	$NORM_EXP{"M"} = 188;  $NORM_EXP{"N"} =157;  $NORM_EXP{"P"} =136;
	$NORM_EXP{"Q"} = 198;  $NORM_EXP{"R"} =248;  $NORM_EXP{"S"} =130;
	$NORM_EXP{"T"} = 142;  $NORM_EXP{"V"} =142;  $NORM_EXP{"W"} =227;
	$NORM_EXP{"X"} = 180;         # undetermined (deliberate)
	$NORM_EXP{"Y"} = 222;  $NORM_EXP{"Z"} =196;         # E or Q
        $NORM_EXP{"max"}=248;

#   --------------------------------------------------
#   maximal 3 Angstrom water
#   --------------------------------------------------
    } elsif ($mode =~ /3ang/ ) {
	$NORM_EXP{"A"} = 179;  $NORM_EXP{"B"} =255;         # D or N
	$NORM_EXP{"C"} =  99;  $NORM_EXP{"D"} =249;  $NORM_EXP{"E"} =279;
	$NORM_EXP{"F"} = 199;  $NORM_EXP{"G"} =169;  $NORM_EXP{"H"} =219;
	$NORM_EXP{"I"} = 189;  $NORM_EXP{"K"} =309;  $NORM_EXP{"L"} =209;
	$NORM_EXP{"M"} = 189;  $NORM_EXP{"N"} =259;  $NORM_EXP{"P"} =189;
	$NORM_EXP{"Q"} = 259;  $NORM_EXP{"R"} =299;  $NORM_EXP{"S"} =209;
	$NORM_EXP{"T"} = 209;  $NORM_EXP{"V"} =189;  $NORM_EXP{"W"} =239;
	$NORM_EXP{"X"} = 200;         # undetermined (deliberate)
	$NORM_EXP{"Y"} = 239;  $NORM_EXP{"Z"} =269;         # E or Q
        $NORM_EXP{"max"}=309;

#   --------------------------------------------------
#   maximal 5 Angstrom water
#   --------------------------------------------------
    } elsif ($mode =~ /5ang/ ) {
	$NORM_EXP{"A"} = 209;  $NORM_EXP{"B"} =295;         # D or N
	$NORM_EXP{"C"} = 139;  $NORM_EXP{"D"} =289;  $NORM_EXP{"E"} =349;
	$NORM_EXP{"F"} = 199;  $NORM_EXP{"G"} =219;  $NORM_EXP{"H"} =229;
	$NORM_EXP{"I"} = 189;  $NORM_EXP{"K"} =399;  $NORM_EXP{"L"} =239;
	$NORM_EXP{"M"} = 189;  $NORM_EXP{"N"} =299;  $NORM_EXP{"P"} =189;
	$NORM_EXP{"Q"} = 309;  $NORM_EXP{"R"} =309;  $NORM_EXP{"S"} =259;
	$NORM_EXP{"T"} = 239;  $NORM_EXP{"V"} =189;  $NORM_EXP{"W"} =259;
	$NORM_EXP{"X"} = 230;         # undetermined (deliberate)
	$NORM_EXP{"Y"} = 259;  $NORM_EXP{"Z"} =329;         # E or Q
        $NORM_EXP{"max"}=399;

#   --------------------------------------------------
#   maximal 0.7 Angstrom water
#   --------------------------------------------------
    } elsif ($mode =~ /07ang/ ) {
	$NORM_EXP{"A"} = 119;  $NORM_EXP{"B"} =169;         # D or N
	$NORM_EXP{"C"} =  99;  $NORM_EXP{"D"} =169;  $NORM_EXP{"E"} =179;
	$NORM_EXP{"F"} = 169;  $NORM_EXP{"G"} =109;  $NORM_EXP{"H"} =173;
	$NORM_EXP{"I"} = 159;  $NORM_EXP{"K"} =206;  $NORM_EXP{"L"} =159;
	$NORM_EXP{"M"} = 159;  $NORM_EXP{"N"} =169;  $NORM_EXP{"P"} =149;
	$NORM_EXP{"Q"} = 169;  $NORM_EXP{"R"} =209;  $NORM_EXP{"S"} =139;
	$NORM_EXP{"T"} = 149;  $NORM_EXP{"V"} =149;  $NORM_EXP{"W"} =169;
	$NORM_EXP{"X"} = 230;         # undetermined (deliberate)
	$NORM_EXP{"Y"} = 189;  $NORM_EXP{"Z"} =175;         # E or Q
        $NORM_EXP{"max"}=230;

#   --------------------------------------------------
#   RS (X=0, from Reinhard
#   --------------------------------------------------
    } elsif ($mode =~/RS/) {
	$NORM_EXP{"A"} = 106;  $NORM_EXP{"B"} =157;         # D or N
	$NORM_EXP{"C"} = 135;  $NORM_EXP{"D"} =163;  $NORM_EXP{"E"} =194;
	$NORM_EXP{"F"} = 197;  $NORM_EXP{"G"} = 84;  $NORM_EXP{"H"} =184;
	$NORM_EXP{"I"} = 169;  $NORM_EXP{"K"} =205;  $NORM_EXP{"L"} =164;
	$NORM_EXP{"M"} = 188;  $NORM_EXP{"N"} =157;  $NORM_EXP{"P"} =136;
	$NORM_EXP{"Q"} = 198;  $NORM_EXP{"R"} =248;  $NORM_EXP{"S"} =130;
	$NORM_EXP{"T"} = 142;  $NORM_EXP{"V"} =142;  $NORM_EXP{"W"} =227;
	$NORM_EXP{"X"} = 180;         # undetermined (deliberate)
	$NORM_EXP{"Y"} = 222;  $NORM_EXP{"Z"} =194;         # E or Q
        $NORM_EXP{"max"}=248;

#   --------------------------------------------------
#   Reinhard
#   --------------------------------------------------
    } else {
	$NORM_EXP{"A"} = 106;  $NORM_EXP{"B"} =160;         # D or N
	$NORM_EXP{"C"} = 135;  $NORM_EXP{"D"} =163;  $NORM_EXP{"E"} =194;
	$NORM_EXP{"F"} = 197;  $NORM_EXP{"G"} = 84;  $NORM_EXP{"H"} =184;
	$NORM_EXP{"I"} = 169;  $NORM_EXP{"K"} =205;  $NORM_EXP{"L"} =164;
	$NORM_EXP{"M"} = 188;  $NORM_EXP{"N"} =157;  $NORM_EXP{"P"} =136;
	$NORM_EXP{"Q"} = 198;  $NORM_EXP{"R"} =248;  $NORM_EXP{"S"} =130;
	$NORM_EXP{"T"} = 142;  $NORM_EXP{"V"} =142;  $NORM_EXP{"W"} =227;
	$NORM_EXP{"X"} = 180;         # undetermined (deliberate)
	$NORM_EXP{"Y"} = 222;  $NORM_EXP{"Z"} =196;         # E or Q
        $NORM_EXP{"max"}=248;
    }
}				# end of exposure_normalise_prepare 

#===============================================================================
sub exposure_normalise {
    local ($exp_in, $aa_in) = @_;
    $[=1;
#----------------------------------------------------------------------
#   exposure_normalise          normalise DSSP accessibility with maximal values
#                               (taken from Schneider)
#----------------------------------------------------------------------
    if ( $aa_in !~ /[ABCDEFGHIKLMNPQRSTUVWXYZ]/ ) {
	if ( $aa_in=~/[!.]/ ) { 
	    $aa_in = "X"; }
	else { 
	    print "*** ERROR in exposure_normalise: aa passed wrong: '$aa_in' \n";
	    exit; }}

    if ($NORM_EXP{$aa_in}>0) { 
	$exp_normalise= int(100 * ($exp_in / $NORM_EXP{$aa_in}));
	$exp_normalise= 100 if ($exp_normalise > 100);
    }
    else { 
	print "*** \n*** exposure_normalise, division by zero:aa=$aa_in,acc=$exp_in,norm=",
	$NORM_EXP{$aa_in},"\n***\n";
	$exp_normalise=$exp_in/1.8; # ugly ...
	if ($exp_normalise>100){$exp_normalise=100;}
    }
    return $exp_normalise;
}				# end of exposure_normalise

#===============================================================================
sub exposure_project_1digit {
    local ($exp_in) = @_;
    local ($exp_out);
    $[=1;
#----------------------------------------------------------------------
#   exposure_project_1digit     project relative exposure (relative) onto numbers 0-9
#                               by: n = max ( 9 , int(sqrt (rel_exp)) )
#----------------------------------------------------------------------
    if ( $exp_in < 0 ) {        # check input
        print "*** ERROR exposure_project_1digit: exposure in = $exp_in \n"; 
	exit;}
				# SQRT
    $exp_out = int ( sqrt ($exp_in) );
                                # limit to 9
    if ( $exp_out >= 10 ) { $exp_out = 9; }
    $exposure_project_1digit = $exp_out;
    return($exp_out);
}				# end of exposure_project_1digit

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
	    $tmpFile.="$file,";$tmpChain.="*,"; # file ok 
	    next;}
				# chain?
	if ($file =~ /\.dssp[_:](.)$/){
	    $chn=$1;
	    $file_nochn=$file;
	    $file_nochn=~s/[_:].$//g;
	    if (-e $file_nochn){
#		$tmpFile.= $file_nochn.",";
		$tmpFile.= $file.",";
		$tmpChain.=$chn.",";
		next;}}

				# chain id appended
	    
	$Lok=0;$chainTmp="unk";
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
	else { print $fhErrSbr "-*- WARN $sbrName missing file=$_,\n";}
    }close($fhinLoc);
    $tmpFile=~s/^,*|,*$//g;$tmpChain=~s/^,*|,*$//g;
    return(1,"ok $sbrName",$tmpFile,$tmpChain);
}				# end of fileListRd
