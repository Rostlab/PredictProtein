#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="compiles statistics on sec-str\n".
    "     \t input:  file from dsspExtrSeqSecAcc.pl file-dssp.list\n".
    "     \t output: stat\n".
    "     \t \n".
    "     \t note:   chains as 1pdb_C\n".
    "     \t note2:  file list must end with '.list'\n".
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
#				version 0.1   	Jul,    	2002	       #
#------------------------------------------------------------------------------#
#

$[ =1 ;				# count from one
#$x1="xx" ;$x2="x";
#print "12 $x1 matches $x2" if ($x1=~/$x2/);
#print "21 $x2 matches $x1" if ($x2=~/$x1/);
#die;
				# ------------------------------
				# defaults
%par=(
      'dirDssp',                "/data/dssp/",
      'extDssp',                ".dssp",
      );
@kwd=sort (keys %par);
$Ldebug=0;
$Lverb= 0;
$Lverb2=0;
				# % relative accessibility to distinguish
				# output = cumulative
#$aatxt="ACDEFGHIKLMNPQRSTVWY";
#$sstxt="HEL";
#@aa=split(//,$aatxt);
#@ss=split(//,$sstxt);

#@class=("KL","DE");
#@class=();

				# minimal length of protein
$lenMin=30;

$sep="\t";
#$sep=" ";


				# ------------------------------
if ($#ARGV<1 ||			# help
	$ARGV[1] =~/^(-h|help|special)/){
    print  "goal: $scrGoal\n";
    print  "use:  '$scrName '\n";
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
    printf "%5s %-15s %-20s %-s\n","","verb2",    "no value","more verbose";
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
$fhin="FHIN";$fhout="FHOUT";
$#fileIn=0;
$dirOut=0;
$fileList=0;
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
    elsif ($arg=~/^verb2$|^det$/)         { $Lverb2=         1;
					    $Lverb=          1;}
    elsif ($arg=~/^silent$|^\-s$/)        { $Lverb=          0;}
#    elsif ($arg=~/^=(.*)$/){ $=$1;}
    elsif (-e $arg && $arg=~/\.list$/i)   { $fileList=       $arg;}
    elsif (-e $arg)                       { push(@fileIn,$arg); }
    elsif ($arg=~/^(.*\.dssp)[_:](.)$/ &&
	   -e $1)                         { push(@fileIn,$1); 
					    $chainIn{$1}=$2;}
    else {
	$Lok=0; 
	if (defined %par && $#kwd>0) { 
	    foreach $kwd (@kwd){ 
		if ($arg =~ /^$kwd=(.+)$/){$Lok=1;$par{$kwd}=$1;
					   last;}}}
	if (! $Lok){ print "*** wrong command line arg '$arg'\n";
		     exit;}}}

				# list of files: read
if ($fileList){
    $fileIn=$fileList;
    open($fhin,$fileIn) || die "*** $scrName ERROR opening fileIn=$fileIn!";
    while (<$fhin>) {
	$_=~s/\n//g;
	$file=$_;
	if    (-e $file){
	    push(@fileIn,$file); 
	    $chainIn{$file}="*";}
	elsif ($file=~/^(.*$par{"extDssp"})[_:](.)$/ && -e $1){
	    push(@fileIn,$1); 
	    $chainIn{$1}=$2;}
				# try variety of things
	else {
	    $tmp= $file;
	    $tmpc="";
				# chain given: get id
	    if ($file=~/^(.*$par{"extDssp"})[_:](.)$/ ||
		$file=~/^(.*)[_:](.)$/){
		$tmp= $1;
		$tmpc=$2;
	    }
	    print "xx file=$file, tmp=$tmp, tmpc=$tmpc\n";
	    if    (-e $tmp || -l $tmp){
		push(@fileIn,$tmp); 
		$chainIn{$tmp}=$tmpc;}
				# add directory
	    elsif ($tmp!~/\// && 
		   (-e $par{"dirDssp"}.$tmp || -l $par{"dirDssp"}.$tmp)){
		push(@fileIn,$par{"dirDssp"}.$tmp); 
		$chainIn{$par{"dirDssp"}.$tmp}=$tmpc;}
				# add extension
	    elsif ($tmp!~/$par{"extDssp"}/ && 
		   (-e $tmp.$par{"extDssp"} || -l $tmp.$par{"extDssp"})){
		push(@fileIn,$tmp.$par{"extDssp"}); 
		$chainIn{$tmp.$par{"extDssp"}}=$tmpc;}
	    elsif ($tmp!~/\//              && 
		   $tmp!~/$par{"extDssp"}/ &&
		   (-e $par{"dirDssp"}.$tmp.$par{"extDssp"} || -l $par{"dirDssp"}.$tmp.$par{"extDssp"})){
		push(@fileIn,$par{"dirDssp"}.$tmp.$par{"extDssp"}); 
		$chainIn{$par{"dirDssp"}.$tmp.$par{"extDssp"}}=$tmpc;}
	    else {
		print "*** reading fileList=$fileIn, unclear what $file is (tmp=$tmp, tmpc=$tmpc)\n";
		exit;}
	}
    }
    close($fhin);
}
$fileIn=$fileIn[1];
die ("*** ERROR $scrName: missing input $fileIn!\n") 
    if (! -e $fileIn);
				# 
$dirOut.="/"                    if ($dirOut && $dirOut !~ /\/$/);

if (! defined $fileOut){
    if ($fileList){
	$tmp=$fileList;
	$tmp=~s/^.*\///g;
	if ($dirOut){
	    $fileOut=$dirOut."Out-".$tmp;}
	else {
	    $fileOut="Out-".$tmp;}
    }
    else {
	$tmp=$fileIn;$tmp=~s/^.*\///g;
	if ($dirOut){
	    $fileOut=$dirOut."Out-".$tmp;}
	else {
	    $fileOut="Out-".$tmp;}
    }}

				# ------------------------------
				# (1) read file(s)
				# ------------------------------
$ctfile=0;
undef %res;
$#id=0;
foreach $fileIn (@fileIn){
    ++$ctfile;
    if (! -e $fileIn){print "-*- WARN $scrName: no fileIn=$fileIn\n";
		      next;}
    $chainIn="*";
    $chainIn=$chainIn{$fileIn}  if (defined $chainIn{$fileIn});
    print "--- $scrName: working on fileIn=$fileIn, chn=$chainIn\n";
#    printf "--- $scrName: working on %-25s %4d (%4.1f perc of job)\n",$fileIn,$ctfile,(100*$ctfile/$#fileIn);

    ($Lok,$msg)=
	&dsspRdSeqSecAcc($fileIn,$chainIn,"seq,sec");

    if (! $Lok){
	print "*** ERROR $scrName: after dsspRdSeqSecAcc($fileIn,$chainIn):\n",$msg,"\n";
	exit;}

				# process DSSP
    $seq=$sec="";
    foreach $it (1..$tmp{"NROWS"}){
	$seq.=$tmp{$it,"seq"};
	$sec.=&convert_sec($tmp{$it,"sec"},"HEL");
    }
				# filter short ones
    next if (length($seq)<$lenMin);
				# now simply count numbers
    $id=$fileIn;
    $id=~s/^.*\///g;
    $id=~s/\..*$//g;
    $id.="_".$chainIn           if ($chainIn ne "*");
    $res{$id,"nres"}=length($seq);
				# number of sec str
    $sec2=$sec;
    $sec2=~s/H+/H/g;
				# remove B
    $sec2=~s/([^E])E([^E])/$1$2/g;
    $sec2=~s/E+/E/g;
    $sec2=~s/L+/L/g;
    $sec2=~s/L//g;
    $res{$id,"nsec"}=length($sec2);
    push(@id,$id);
}
				# ------------------------------------------------------------
				# (2) sum values
				# ------------------------------------------------------------
foreach $id (@id){
}		 
		 
    

				# ------------------------------
				# (3) write output
				# ------------------------------
open($fhout,">".$fileOut) || warn "*** $scrName ERROR creating fileOut=$fileOut";
print $fhout
    "id",$sep,"nres",$sep,"nsec","\n";
foreach $id (@id){
    print $fhout
	$id,$sep,$res{$id,"nres"},$sep,$res{$id,"nsec"},"\n";
}
close($fhout);


print "--- output in $fileOut\n"  if (-e $fileOut);
exit;


#===============================================================================
sub convert_sec {
    local ($sec,$char) = @_ ;
#--------------------------------------------------------------------------------
#    convert_sec                converts 8 DSSP secondary str. into 3 (H,E,L)= default 
#                               char=HL    -> H=H,I,G  L=rest
#                               char=HELB  -> H=H,I,G  E=E, B=B, L=rest
#                               char=HELT  -> H=H,I,G  E=E,B  T=T, L=rest
#                               char=HELBT -> H=H,I,G  E=E, B=B, T=T, L=rest
#         default =             HEL
#         in:                   structure to convert
#         out:                  converted (with return)
#--------------------------------------------------------------------------------
				# default (3 states)
    if ( !defined $char || length($char)==0 || $char eq "HEL" || ! $char) {
	return "H" if ($sec=~/[HIG]/);
	return "E" if ($sec=~/[EB]/);
	return "L";}
				# optional
    elsif ($char eq "HL")    { return "H" if ($sec=~/[HIG]/);
			       return "L";}
    elsif ($char eq "HELT")  { return "H" if ($sec=~/[HIG]/);
			       return "E" if ($sec=~/[EB]/);
			       return "T" if ($sec=~/[T]/);
			       return "L";}
    elsif ($char eq "HELB")  { return "H" if ($sec=~/HIG/);
			       return "E" if ($sec=~/[E]/);
			       return "B" if ($sec=~/[B]/);
			       return "L";}
    elsif ($char eq "HELBT") { return "H" if ($sec=~/[HIG]/);
			       return "E" if ($sec=~/[EB]/);
			       return "B" if ($sec=~/[E]/);
			       return "T" if ($sec=~/[T]/);
			       return "L";}
    else { print "*** ERROR calling convert_sec (lib-br), sec=$sec, or char=$char, not ok\n";
	   return(0);}
}				# end of convert_sec

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
#       out:                    1|0,msg
#                               
#       out GLOBAL:             %tmp{"NROWS"}=number of residues
#       out GLOBAL:             $tmp{$ct,"chn|seq|sec|acc|nodssp|nopdb"} respective values
#       out GLOBAL:             $tmp{<header|compnd|source|author>}
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
    while (<$fhinLoc>) {	# 
	$line=$_; $line=~s/\n//g;
				# all we need in first 40
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
	++$ctres;
	foreach $kwd (@kwdTmp){
	    $tmp{$ctres,$kwd}=$tmp2{$kwd};
	}
	$tmp{$ctres,"chn"}=   $chn;
    }

				# correct number of residues
    $tmp{"nres"}=  
	$tmp{"NROWS"}=
	    $ctres;
				# clean up
    undef %tmp2;		# slim-is-in
    $#kwdTmp=0;			# slim-is-in
    
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

