#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrIn=  "file.rdbProf file.hssp";
$scrGoal="writes PROF prediction into HSSP file\n".
    "     \t input:  ".$scrIn."\n".
    "     \t output: \n".
    "     \t need:   either 1=prof 2=hssp, or extensions *.rdb* *.hssp* \n".
    "     \t need:   sec str AND accessibility in PROF as PHEL PACC\n".
    "     \t need:   SAME sequences in file.rdbProf and file.hssp!\n".
    "     \t \n".
    "     \t ";
#  
# FIXME:
#------------------------------------------------------------------------------#
#	Copyright				        	2004	       #
#	Burkhard Rost		rost@columbia.edu			       #
#	CUBIC (Columbia Univ)	http://cubic.bioc.columbia.edu/   	       #
#       Dept Biochemistry & Molecular Biophysics			       #
#       650 West, 168 Street, BB217					       #
#	New York, NY 10032	http://www.cubic.bioc.edu/                     #
#				version 0.1   	Jan,    	2004	       #
#------------------------------------------------------------------------------#
#

$[ =1 ;				# count from one

				# ------------------------------
				# defaults
%par=(
      'extOutadd', "PROF",
      );
@kwd=sort (keys %par);


@kwdHead=();
@kwdBody=(
	  "AA",
	  "PHEL",
	  "PACC"
	  );
$ptr{"seq"}="AA";
$ptr{"sec"}="PHEL";
$ptr{"acc"}="PACC";


if (! $Lok) {
    $localtime=`date`;
    @Date=split(/\s+/,$localtime);
    $Date="$Date[2] $Date[3], $Date[$#Date] $Date[4]"; }
$date=$Date; 
$date=~s/(199\d|200\d)\s*.*$/$1/g;

$Ldebug=0;
$Lverb= 1;
#$sep=   "\t";


				# ------------------------------
if ($#ARGV<1 ||			# help
	$ARGV[1] =~/^(-h|help|special)/){
    print  "goal: $scrGoal\n";
    print  "use:  '$scrName $scrIn'\n";
    print  "opt:  \n";
				#      'keyword'   'value'    'description'
    printf "%5s %-15s=%-20s %-s\n","","fileOut", "x",       "name of output file";
    printf "%5s %-15s=%-20s %-s\n","","dirOut",   "x",       "if given: name fileIn=fileOut BUT in dirOut";
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
#$fhin="FHIN";
#$fhout="FHOUT";
$#fileIn=0;
$dirOut=0;
				# ------------------------------
				# read command line
foreach $arg (@ARGV){
#    next if ($arg eq $ARGV[1]);
    if    ($arg=~/^fileOut=(.*)$/i)       { $fileOut=        $1;}
    elsif ($arg=~/^dirOut=(.*)$/i)        { $dirOut= $1;
					    $dirOut.="/"     if ($dirOut !~ /\/$/);}

    elsif ($arg=~/^de?bu?g$/)             { $Ldebug=         1;
					    $Lverb=          1;}
    elsif ($arg=~/^verb(ose)?$|^\-v$/)    { $Lverb=          1;}
    elsif ($arg=~/^silent$|^\-s$/)        { $Lverb=          0;}
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
				# 
$dirOut.="/"                    if ($dirOut && $dirOut !~ /\/$/);


				# now which is which
if ($fileIn[2]=~/\.rdb/i){
    $fileInProf=$fileIn[2];
    $fileInHssp=$fileIn[1];}
else{
    $fileInProf=$fileIn[1];
    $fileInHssp=$fileIn[2];}

if (! defined $fileOut){
    $tmp=$fileInHssp;
    $tmp=~s/^.*\///g;
    $fileOut="";
    $fileOut=$dirOut if ($dirOut);
    $fileOut.=$tmp.$par{"extOutadd"};
    $fileOut.=".tmp" if ($fileOut eq $fileInHssp);
}

				# ------------------------------
				# (1) read file(s)
				# ------------------------------
$id=$fileInProf;
$id=~s/^.*\///g;
$id=~s/\..*$//g;
				# 1: PROF
($Lok,$msg)=
    &rdRdb_here
    (
     $fileInProf,\@kwdHead,\@kwdBody
     );                         &errScrMsg("failed rdRdb_her(in_prof=$fileInProf)",$msg,$scrName) if (! $Lok);
	   
				# 2: HSSP
($Lok,$msg)=
    &rdHssp
    (
     $fileInHssp
     );                         &errScrMsg("failed rdHssp(in_hssp=$fileInHssp)",$msg,$scrName) if (! $Lok);


				# ------------------------------
				# (2) write new HSSP
				# ------------------------------

($Lok,$msg)=
    &wrtHsspProf
    (
     $fileOut
     );				&errScrMsg("failed wrtHsspProf(out=$fileOut)",$msg,$scrName) if (! $Lok);

if ($Lverb){
    print "--- output in $fileOut\n" if (-e $fileOut);
}
exit;


#===============================================================================
sub rdHssp {
    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   rdHssp                      reads the HSSP file (all lines)
#-------------------------------------------------------------------------------
    $tmp="";
    $tmp=$scrName.":" if ($scrName);

    $sbrName=$tmp."rdHssp";
    $fhinLoc="FHIN_"."$sbrName";

    if (! -e $fileInLoc){
	print "*** $sbrName missing input '$fileInLoc'\n";
	return(0);}

    open($fhinLoc,$fileInLoc) 
	|| return(0,"ERROR $sbrName: could not read HSSP=$fileInLoc!");

    $#HSSP=$kchain=0;
    while (<$fhinLoc>) {
	$_=~s/\n//g;
	if ($_=~/^SEQLENGTH/){	# store sequence length
	    $len=$_;
	    $len=~s/^SEQLENGTH|\s//g;}
	elsif ($_=~/^KCHAIN/){	# store number of chains
	    $kchain=$_;$kchain=~s/^KCHAIN\s+(\d+)\s.*$/$1/;
	    if (($len+$kchain-1) != $#SEC){
		print"*** $sbrName: different length (HSSP=$len, kchain=$kchain,PHD=",$#SEC,")\n";
		close($fhinLoc); 
		return(0);}}
	push(@HSSP,$_);}close($fhinLoc);
    return(1);
}				# end of rdHssp

#===============================================================================
sub rdRdb_here {
    local ($fileInLoc,$ra_kwdRdHead,$ra_kwdRdBody) = @_ ;
    local ($sbr_name);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   rdRdb_here                  reads content of an RDB file into associative array
#       in:                     Names used for columns in perl file, e.g.,
#                               $ra_kwdRdHead: $ra_kwdRdHead->[1]  = $kwdRdHead[1]
#       out:                    $rdb{"NROWS"} returns the numbers of rows read
#                               $rdb{$itres,$kwd}
#--------------------------------------------------------------------------------
				# avoid warning
    $sbr_name="rdRdb_here";
				# set some defaults
    $fhinLoc="FHIN_RDB";
				# get input
				# --------------------------------------------------
				# read RDB file
				# --------------------------------------------------
    open($fhinLoc,$fileInLoc) || return(&errSbr("failed opening fileIn=$fileInLoc!\n",$sbr_name));
    undef %rdb;
    $#ptr_num2name=$#col2read=0;

				# ------------------------------
				# for quick finding
    if (! defined %kwdRdBody){
	foreach $kwd (@$ra_kwdRdBody){
	    $kwdRdBody{$kwd}=1;}}

	
    $ctLoc=$ctrow=0;
				# ------------------------------
				# header  
    while ( <$fhinLoc> ) {	# 
	$_=~s/\n//g;
	$line=$_;
	if ( $_=~/^\#/ ) { 
	    if ($_=~/PARA|VALUE/){
		foreach $kwd (@$ra_kwdRdHead){
		    next if (defined $rdb{$kwd});
		    if ($_=~/^.*(PARA\S*|VAL\S*)\s*:?\s*$kwd\s*[ :,\;=]+(\S+)/i){
			$rdb{$kwd}=$2;
			next; }}}
	    next; }
	last; }
				# ------------------------------
				# names
    @tmp=split(/\s*\t\s*/,$line);
    foreach $it (1..$#tmp){
	$kwd=$tmp[$it];
	next if (! defined $kwdRdBody{$kwd});
	$ptr_num2name[$it]=$kwd;
	push(@col2read,$it); }

    $ctLoc=2;
    while ( <$fhinLoc> ) {	# 
	$_=~s/\n//g;
	$line=$_;
				# ------------------------------
				# skip format?
	if    ($ctLoc==2 && $line!~/\d+[SNF]\t|\t\d+[SNF]/){
	    ++$ctLoc;}
	elsif ($ctLoc==2){
	    next; }
				# ------------------------------
				# data
	if ($ctLoc>2){
	    ++$ctrow;
	    @tmp=split(/\s*\t\s*/,$line);
	    foreach $it (@col2read){
		$rdb{$ctrow,$ptr_num2name[$it]}=$tmp[$it];
	    }
	}
    }
    close($fhinLoc);
    $rdb{"NROWS"}=$ctrow;

    $#col2read=0; 
    undef %ptr_num2name;

    return (1,"ok");
}				# end of rdRdb_here

#==========================================================================
sub wrtHsspProf {
    local ($fileOutLoc)=@_;
    local ($it);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   wrtHsspProf                  writes the PHD prediction into HSSP format
#-------------------------------------------------------------------------------
    $tmp="";
    $tmp="$scrName".":" if ($scrName);

    $sbrName=$tmp."wrtHsspProf";
    $fhoutLoc="FHOUT_".$sbrName;

    open($fhoutLoc,">".$fileOutLoc)
	|| return(0,"ERROR $sbrName: could not write HSSPout=$fileOutLoc!");

    				# first preprocess the PROF stuff
    $#SEQ=$#SEC=$#ACC=0;
    foreach $it (1..$rdb{"NROWS"}){
				# skip breaks and stuff
	next if ($rdb{$it,$ptr{"seq"}}=~/^[! \.]$/);
	push(@SEQ,$rdb{$it,$ptr{"seq"}});
	if ($rdb{$it,$ptr{"sec"}} eq "L"){
	    push(@SEC," ");}
	else {
	    push(@SEC,$rdb{$it,$ptr{"sec"}});
	}
	push(@ACC,$rdb{$it,$ptr{"acc"}});
    }
				# ------------------------------
				# loop over HSSP 
    $ctHssp=0;
    foreach $hssp(@HSSP){
	++$ctHssp;
				# add annotation of change
	if    ($hssp=~/^DATE/) {
	    $hssp=~s/on.*$//g;$hssp.="on $date (merged: PROFphd prediction)";
	}
	print $fhoutLoc $hssp,"\n";
	last if ($hssp=~/^ SeqNo /);  # finish when alis start
    }

    $ct=0;$LrdSeq=1;$LrdProf=0;
    foreach $itHssp(($ctHssp+1)..$#HSSP){
	$hssp=$HSSP[$itHssp];
				# ------------------------------
				# no sequence stuff
	if ($hssp =~ /^\#\# SEQUENCE/){
	    $LrdSeq=0;$LrdProf=1;}
	elsif ($hssp =~ /^\#\# ALIGNMENT/){
	    $LrdSeq=0;}
	elsif (($hssp=~/^ SeqNo /)&&(! $LrdProf)){
	    $ct=0;$LrdSeq=1;
	    $ctmiss=0;
	    print $fhoutLoc $hssp,"\n"; 
	    next;}
	if (! $LrdSeq) { 
	    print $fhoutLoc $hssp,"\n"; 
	    next;	        # write last stuff (profiles + insertion)
	}
				# --------------------------------------------------
				# sequences
				#        HERE is where everything happens
				# --------------------------------------------------
	$aaHssp=substr($hssp,15,1);
	++$ct;

				# chain breaks and stuff
	if ($aaHssp=~/[!.]/){
	    print $fhoutLoc $hssp,"\n";
	    next; }
				# no chain break, regular sequence but lower
				#        now we need to begin counting
	while (($ct<$#SEQ) &&
	       ($SEQ[$ct] ne $aaHssp)){
	    print "xx AAhssp=$aaHssp, AAprof=$SEQ[$ct], linehssp=$hssp\n";
	    ++$ctmiss;
	    ++$ct;}
	$acc=$ACC[$ct]; while(length($acc)<3){$acc=" $acc";}
	if (length($hssp)<40){
	    print "xx line(<40):$hssp:\n";
	    die;}
	$new=substr($hssp,1,17).$SEC[$ct].substr($hssp,19,18).$acc.substr($hssp,40);
	print $fhoutLoc "$new\n";
	if ($Ldebug){
	    print "--- old  =",substr($hssp,1,45),"\n";
	    print "---   new=",substr($new,1,45),"\n";}
    }
    close($fhoutLoc);
    return(1,"ok");
}				# wrtHsspProf



#==============================================================================
# library collected (begin) lllbeg
#==============================================================================


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
# library collected (end)   lllend
#==============================================================================
