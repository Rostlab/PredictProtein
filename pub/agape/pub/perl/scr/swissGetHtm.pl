#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="in SWISS-PROT, out HTM positions\n".
    "     \t all cocatenated into long output file(s) one with numbers, one with string\n".
    "     \t ";
#  
# 
# ============================================================
# grep on SWISSPROT:
#
# egrep "^ID|^TRANSMEM"
#
# resulting file will be analysed here:
#
# - minimal number of HTM
# - topology known
# - topology known as 'probable'
#
# ============================================================
#  
#------------------------------------------------------------------------------#
#	Copyright				        	2000	       #
#	Burkhard Rost		rost@columbia.edu			       #
#	CUBIC (Columbia Univ)	http://www.columbia.edu/~rost/   	       #
#       Dept Biochemistry & Molecular Biophysics			       #
#       630 West, 168 Street						       #
#	New York, NY 10032	http://www.columbia.edu/~rost/                 #
#				version 0.1   	Mar,    	2000	       #
#------------------------------------------------------------------------------#
#

$[ =1 ;				# count from one

				# ------------------------------
				# defaults
%par=(
      'min',  1,		# minimal number of HTM
      '', "",			# 
      '', "",			# 
      );
@kwd=sort (keys %par);
$Ldebug=0;
$Lverb= 0;
				# ------------------------------
if ($#ARGV<1){			# help
    print  "goal: $scrGoal\n";
    print  "use:  '$scrName '\n";
    print  "opt:  \n";
				#      'keyword'   'value'    'description'
    printf "%5s %-15s=%-20s %-s\n","","fileOut", "x",       "name of output file for sequence/htm";
    printf "%5s %-15s=%-20s %-s\n","","fileOut2","x",       "name of output file for numbers/stat";
    printf "%5s %-15s=%-20s %-s\n","","min",     "x",       "minimal number of HTM to take (def=".$par{"min"}.")";
#    printf "%5s %-15s=%-20s %-s\n","","",   "x", "";
#    printf "%5s %-15s %-20s %-s\n","","",        "",         "continued";
#    printf "%5s %-15s %-20s %-s\n","","",   "no value","";

    printf "%5s %-15s %-20s %-s\n","","all",   "no value",   "do not discard probable|potential";
    printf "%5s %-15s %-20s %-s\n","","all",   "no value",   "also take 'by similarity'";

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
$LisList=  0;
$#fileIn=  0;
$LtakeAll= 0;
$LtakeAll2=0;
				# ------------------------------
				# read command line
foreach $arg (@ARGV){
#    next if ($arg eq $ARGV[1]);
    if    ($arg=~/^fileOut=(.*)$/i)       { $fileOut=        $1;}
    elsif ($arg=~/^fileOut2=(.*)$/i)      { $fileOut2=       $1;}
    elsif ($arg=~/^de?bu?g$/)             { $Ldebug=         1;
					    $Lverb=          1;}
    elsif ($arg=~/^verb(ose)?$|^\-v$/)    { $Lverb=          1;}
    elsif ($arg=~/^silent$|^\-s$/)        { $Lverb=          0;}
    elsif ($arg=~/^(is)?list$/i)          { $LisList=        1;}
    elsif ($arg=~/^all$/i)                { $LtakeAll=       1;}
    elsif ($arg=~/^all2$/i)               { $LtakeAll=       1;
					    $LtakeAll2=      1;}
    elsif ($arg=~/^min=(.*)$/)            { $par{"min"}=     $1;}
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
die ("*** ERROR $scrName: missing input $fileIn\n") 
    if (! -e $fileIn);
$fileOut= "Out-swiss-htm-string.dat"   if (! defined $fileOut);
$fileOut2="Out-swiss-htm-num.dat"      if (! defined $fileOut2);
    


				# ------------------------------
				# (0) digest file (list?)
				# ------------------------------
$#fileTmp=0;
foreach $fileIn (@fileIn){
    if ( ($#fileIn==1 && $LisList) || $fileIn =~/\.list/) {
	($Lok,$msg,$file,$tmp)=
	    &fileListRd($fileIn);   if (! $Lok){ print "*** ERROR $scrName: after input list\n",$msg,"\n";
						 exit; }
	@tmpf=split(/,/,$file); 
	push(@fileTmp,@tmpf);
	next;}
    push(@fileTmp,$fileIn);
}
@fileIn= @fileTmp;
$#fileTmp=0;			# slim-is-in
				# --------------------------------------------------
				# (1) read/process file(s)
				# --------------------------------------------------
$ct=0;
$#id=0;
undef %takeid;
				# open output: sequence / htm
open($fhout,">".$fileOut) || die "*** $scrName ERROR opening fileOut=$fileOut!";
print $fhout 
    "# Perl-RDB\n",
    "id","\t",
    "len","\t","nhtm","\t","topo","\t","seq","\t","htm","\n";

foreach $fileIn (@fileIn){
    ++$ct;
    if (! -e $fileIn){print "-*- WARN $scrName: no fileIn=$fileIn\n";
		      next;}
#    print "--- $scrName: working on fileIn=$fileIn!\n";
    printf "--- $scrName: working on %-25s %4d (%4.1f perc of job)\n",$fileIn,$ct,(100*$ct/$#fileIn);
    $cthtm=$ctdom=0;
    $seq="";
				# ------------------------------
				# read
				# ------------------------------
    open($fhin,$fileIn) || die "*** $scrName ERROR opening fileIn=$fileIn!";
    while (<$fhin>) {
	$_=~s/\n//g;
	$line=$_;
				# id and length
	if ($line=~/^ID\s+(\S+)\s.*\D(\d+)\s+AA/) { 
	    $id= $1; $id=~tr/[A-Z]/[a-z]/;
	    $len=$2; 
	    push(@id,$id);
	    $res{$id,"len"}=$len;
	    next;}
				# membrane region
	if    ($line=~/FT\s+TRANSMEM\s+(\d+)\s+(\d+)/ &&
	       $line!~/POTENTIAL/     &&
	       $line!~/PROBABLE/      &&
	       $line!~/BY (SIM|HOM)/){
	    ++$cthtm;
	    $res{$id,$cthtm,"beg"}=$1;
	    $res{$id,$cthtm,"end"}=$2;
	    next; }
				# membrane region: probable
	elsif ($line=~/FT\s+TRANSMEM\s+(\d+)\s+(\d+)/ &&
	       $line!~/BY (SIM|HOM)/  &&
	       $LtakeAll){
	    ++$cthtm;
	    $res{$id,$cthtm,"beg"}=$1;
	    $res{$id,$cthtm,"end"}=$2;
	    next; }
				# membrane region: 'by similarity'
	elsif ($line=~/FT\s+TRANSMEM\s+(\d+)\s+(\d+)/ &&
	       $LtakeAll2){
	    ++$cthtm;
	    $res{$id,$cthtm,"beg"}=$1;
	    $res{$id,$cthtm,"end"}=$2;
	    next; }
	
				# non-membrane region
	if ($line=~/FT\s+DOMAIN\s+(\d+)\s+(\d+)\s+(\S.*)/){ 
	    ++$ctdom;
	    $res{$id,"dom",$ctdom,"beg"}=$1;
	    $res{$id,"dom",$ctdom,"end"}=$2;
	    $res{$id,"dom",$ctdom,"dom"}=$3;
	    next; }
				# sequence
	if ($line=~/^\s+(\S+.*)\s*$/){
	    $seq.=$1;
	    next;}
    }
    close($fhin);
    $res{$id,"nhtm"}=$cthtm;
    $res{$id,"ndom"}=$ctdom;
    $seq=~s/\s//g;
    $res{$id,"seq"}=$seq;
    if ($cthtm >= $par{"min"}){
	$takeid{$id}=1;}
				# skip, since too few HTMs!!
    else {
	$takeid{$id}=0;
	next; }
	
				# ------------------------------
				# process and write seq/htm
				# ------------------------------
    $#tmp=0;
    foreach $it (1..$res{$id,"len"}){
	$tmp[$it]="N";}
    foreach $ithtm (1..$res{$id,"nhtm"}){
	foreach $it ($res{$id,$ithtm,"beg"}..$res{$id,$ithtm,"end"}){
	    $tmp[$it]="M";
	}}
    $htm="";
    foreach $tmp (@tmp){
	next if (! defined $tmp || length($tmp)<1);
	$htm.=$tmp;}
    $#tmp=0;
				# get topology
    $topo="unk";
    if ($res{$id,"ndom"}){
	foreach $itdom (1..$res{$id,"ndom"}){
	    last if ($topo ne "unk");
				# two domains defined
	    if (defined $res{$id,"dom",$itdom,"dom"} &&
		defined $res{$id,"dom",($itdom+1),"dom"}){
				# cyto-extra -> in
		if    ($res{$id,"dom",$itdom,"dom"}=~    /CYTO/ &&
		       $res{$id,"dom",($itdom+1),"dom"}=~/EXTRA|LUMEN|PERI/){
		    $topo="in";
		    last;}
				# extra-cyto -> out
		elsif ($res{$id,"dom",$itdom,"dom"}=~    /EXTRA|LUMEN|PERI/ &&
		       $res{$id,"dom",($itdom+1),"dom"}=~/CYTO/){
		    $topo="out";
		    last;}
	    }}}
    $res{$id,"topo"}=$topo;
    print $fhout 
	$id,"\t",
	$res{$id,"len"},"\t",$res{$id,"nhtm"},"\t",$res{$id,"topo"},
	"\t",$res{$id,"seq"},"\t",$htm,"\n";
    print
	$id,"\t",
	$res{$id,"len"},"\t",$res{$id,"nhtm"},"\t",$res{$id,"topo"},
	"\t",$res{$id,"seq"},"\t",$htm,"\n"
	    if ($Ldebug);
}				# end of loop over all files
close($fhout);

				# ------------------------------
				# (3) write output for numbers
				# ------------------------------
$ctprot=0;
foreach $id (@id){
    ++$ctprot if ($takeid{$id});
}

open($fhout,">".$fileOut2) || warn "*** $scrName ERROR creating fileOut2=$fileOut2!";
print $fhout
    "# Perl-RDB\n",
    "# NPROT\t$ctprot\n",
    "id","\t",
    "len","\t","nhtm","\t","topo","\t","region","\n";
foreach $id (@id){
    next if (! $takeid{$id});
    $tmp="";
    foreach $ithtm (1..$res{$id,"nhtm"}){
	$tmp.=$res{$id,$ithtm,"beg"}."-".$res{$id,$ithtm,"end"}.",";
    }
    $tmp=~s/,$//g;

    print $fhout 
	$id,"\t",
	$res{$id,"len"},"\t",$res{$id,"nhtm"},"\t",$res{$id,"topo"},
	"\t",$tmp,"\n";
}	
close($fhout);

print "--- output strings in $fileOut\n"  if (-e $fileOut);
print "--- output numbers in $fileOut2\n" if (-e $fileOut2);
exit;


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
