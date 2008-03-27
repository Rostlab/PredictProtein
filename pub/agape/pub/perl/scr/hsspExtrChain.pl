#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="extracts a chain from an HSSP file\n".
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
#				version 0.1   	May,    	2000	       #
#------------------------------------------------------------------------------#
#

$[ =1 ;				# count from one

				# ------------------------------
				# defaults
%par=(
      'extHssp',    ".hssp",	# 
      'minOverlap', 10,		# minimal overlap with chain wanted to take alignment
      '', "",			# 
      );
@kwd=sort (keys %par);
$Ldebug=0;
$Lverb= 0;
				# ------------------------------
if ($#ARGV<1 ||			# help
	$ARGV[1] =~/^(-h|help|special)/){
    print  "goal: $scrGoal\n";
    print  "use:  '$scrName *hssp_C' (or 'file.hssp C,A')\n";
    print  "opt:  \n";
				#      'keyword'   'value'    'description'
    printf "%5s %-15s=%-20s %-s\n","","fileOut", "x",       "name of output file";
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
$fhin="FHIN";$fhout="FHOUT";
$#fileIn=0;

				# ------------------------------
				# read command line
$chains="";
$LisList=0;
foreach $arg (@ARGV){
#    next if ($arg eq $ARGV[1]);
    if    ($arg=~/^fileOut=(.*)$/i)       { $fileOut=        $1;}
    elsif ($arg=~/^de?bu?g$/)             { $Ldebug=         1;
					    $Lverb=          1;}
    elsif ($arg=~/^verb(ose)?$|^\-v$/)    { $Lverb=          1;}
    elsif ($arg=~/^silent$|^\-s$/)        { $Lverb=          0;}

    elsif ($arg=~/^([0-9a-zA-Z,]+)$/)     { $chains=         $1;}
    elsif ($arg=~/^(.*$par{"extHssp"})_([A-Za-z0-9])$/){ push(@fileIn,$1);
							 $chainIn{$1}=$2;}
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

				# --------------------------------------------------
				# loop file(s)
				# --------------------------------------------------
$ctfile=0;
foreach $fileIn (@fileIn){
    ++$ctfile;
    if (! -e $fileIn){print "-*- WARN $scrName: no fileIn=$fileIn\n";
		      next;}
				# which chain to get
    if    (defined $chainIn{$fileIn}){
	$chainWant=$chainIn{$fileIn};}
    elsif (length($chains) > 0){
	$chainWant=$chains;}
    else {
	print "*** $scrName: no chain found for $fileIn\n";
	die;}
    @tmp=split(/,/,$chainWant);
    $nchainWant=$#tmp;

    printf 
	"--- $scrName: working on %-25s %-s %4d (%4.1f perc of job)\n",
	$fileIn.":".$chainWant,$ctfile,(100*$ctfile/$#fileIn);

				# ------------------------------
				# (1)  get location of chains
				# out: $chain='A,B,C'
				#      $tmp{"NROWS"}= no of chains
				#      $tmp{$ct,"chain"},$tmp{$ct,"ifir"},$tmp{$ct,"ilas"}
				#      
				#      
    ($chainrd,%tmp)=
	&hsspGetChain($fileIn);

				# ------------------------------
				# (2)  which ones to take now?
    @tmp=split(//,$chainrd);
    $ctok=0;
    $ctres_taken=0;
    undef %ptr_no2new;
    foreach $itchn (1..$#tmp){
	$chaintmp=$tmp[$itchn];
				# chain not wanted
	next if ($chainWant !~ /$chaintmp/);
	foreach $it ($tmp{$itchn,"ifir"} .. $tmp{$itchn,"ilas"}){
	    $tmp{$it}=1;
	    ++$ctok;
	    $ptr_no2new{$it}=$ctok;
	}
    }
				# none found !!
    if (! $ctok){ 
	print "-*- WARN $scrName: $fileIn want chain=$chainWant, however only found ",$chainrd,"!\n";
	next; }
    $ctres_taken=$ctok;
	
				# ------------------------------
				# (3a) first pass: just cut
    $fileOutTmp="TMP_hsspExtrChain.tmp";
    open($fhin,$fileIn)          || die "*** $scrName ERROR opening fileIn=$fileIn!";
    open($fhout,">".$fileOutTmp) || die "*** $scrName ERROR creating fileOut=$fileOutTmp";

				# before pairs
    while (<$fhin>) {
	if    ($_ =~ /^SEQLENGTH/){
	    printf $fhout "%-9s%6d\n","SEQLENGTH",$ctres_taken;
	    next; }
	print $fhout $_;
	last if ($_ =~ /^  NR\./); }

				# pairs
    $ctali_taken=0;
    $ctali_orig= 0;
    undef %cut;
    while (<$fhin>) {
	if ($_ =~ /^\#\# ALIGNMENTS\s+(\d+)\s*\-\s*(\d+).*/){
	    $blockbeg=$1;
	    $blockend=$2;
				# change count on block
	    if ($blockend > $ctali_taken){
		$blockend=$ctali_taken;
	    }
	    printf $fhout "%-13s %4d - %4d\n","## ALIGNMENTS",$blockbeg,$blockend;
	    last; }
	$_=~s/\n//g;
	$line=$_;
	$ifir=substr($line,40,4); $ifir=~s/\s//g;
	$ilas=substr($line,45,4); $ilas=~s/\s//g;
	++$ctali_orig;
				# at least 10 residues MUST overlap
	$ctok=0;
	foreach $it ($ifir .. $ilas){
	    ++$ctok             if (defined $tmp{$it});
	    last if ($ctok >= $par{"minOverlap"});
	}
				# skip if too few overlapping
	if ($ctok < $par{"minOverlap"}){
	    $cut{$ctali_orig}=1;
	    next; }
	$ifir_new=$ptr_no2new{$ifir};
	$ilas_new=$ptr_no2new{$ilas};
				# ok: write
				# replace ifir - ilas by new positions
	$beg=substr($line,1,38);
	$end=substr($line,50);
	    
	printf $fhout "%-s %4d %4d %-s\n",$beg,$ifir_new,$ilas_new,$end;

	++$ctali_taken;
#	print "xx ok orig=$ctali_orig, taken=$ctali_taken!\n";
				# keep pointer to old numbers
	$tmp{"orig2new",$ctali_orig}=$ctali_taken;
    }

				# alignments
    while (<$fhin>) {
	if ($_ =~ /^\#\# ALIGNMENTS\s+(\d+)\s*\-\s*(\d+).*/){
	    $blockbeg=$1;
	    $blockend=$2;
				# skip entire block, since nali reduced!!
	    if ($blockbeg > $ctali_taken){
		while(<$fhin>){
		    if ($_ =~ /^\#\# SEQUENCE/){
			print $fhout $_;
			last; 
		    }}}
				# change count on block
	    if ($blockend > $ctali_taken){
		$blockend=$ctali_taken;
	    }
	    printf $fhout "%-13s %4d - %4d\n","## ALIGNMENTS",$blockbeg,$blockend;
	    next; }
	if ($_ =~ /^ SeqNo/){
	    print $fhout $_;
	    next; }
	if ($_ =~ /^\#\# SEQUENCE/){
	    print $fhout $_;
	    last; }
	$_=~s/\n//g;
	$line=$_;
	$pos=substr($line,1,6);
	$pos=~s/\s//g;
				# skip since not part of chain wanted
	next if (! defined $tmp{$pos});
				# change alignments
	$beg=substr($line,7,51);
	$ali=substr($line,52);
	$new="";
	@tmp=split(//,$ali);
	foreach $it (1..$#tmp){
	    $num=($blockbeg-1)+$it;
				# ali to skip?
	    next if (defined $cut{$num});
	    $new.=$tmp[$it];
	}
	$pos_new=$ptr_no2new{$pos};
	printf $fhout "%6d%-s%-s\n",$pos_new,$beg,$new;
    }

    $#insertions=0;		# buffer insertion list (may not be needed anymore!)

				# profiles
    while (<$fhin>) {
	if ($_ =~ /^ SeqNo/){
	    print $fhout $_;
	    next; }
	if ($_ =~ /^\#\# INSERTION/){
	    $_=~s/\n//g;
	    push(@insertions,$_);
	    last; }
				# final reached without insertions
	if ($_ =~ /^\//){
	    print $fhout $_;
	    last; }
	$_=~s/\n//g;
	$line=$_;
	$pos=substr($line,1,5);
	$pos=~s/\s//g;
				# skip since not part of chain wanted
	next if (! defined $tmp{$pos});
	$pos_new=$ptr_no2new{$pos};
	$end=substr($line,6);
	print "xx pos=$pos, new=$pos_new, line=$line\n";
	printf $fhout "%5d%-s\n",$pos_new,$end;
    }

				# insertion list
    while (<$fhin>) {
	$_=~s/\n//g;
	if ($_ =~ /^ AliNo/){
	    push(@insertions,$_);
	    next; }
	if ($_ =~ /^\//){
	    if ($#insertions > 2){
		foreach $tmp (@insertions){
		    print $fhout $tmp ,"\n";
		}}
	    print $fhout $_,"\n";
	    last; }
	$_=~s/\n//g;
	$line=$_;
	$alino=substr($line,1,6);
	$alino=~s/\s//g;
				# skip since was cut from alignment list
	next if (! defined $tmp{"orig2new",$alino});
	$newno=$tmp{"orig2new",$alino};
	push(@insertions,sprintf("%6d%-s\n",$newno,substr($line,7)));
    }
    close($fhin);
    close($fhout);


				# ------------------------------
				# (3a) first pass: just cut
    $fileOut=$fileIn;
    $fileOut=~s/^.*\///g;
    if ($chainWant =~ /,/){
	$fileOut=~s/$par{"extHssp"}/-cut$par{"extHssp"}/;}
    else {
	$fileOut=~s/$par{"extHssp"}/_$chainWant$par{"extHssp"}/;}
    $fileOut="out-".$fileOut if ($fileOut eq $fileIn);
	
    open($fhin,$fileOutTmp)   || die "*** $scrName ERROR opening fileOutTmp(in)=$fileOutTmp!";
    open($fhout,">".$fileOut) || die "*** $scrName ERROR creating fileOut=$fileOut";
				# find NALIGN

    while (<$fhin>) {
	if    ($_ =~ /^NALIGN/){
	    printf $fhout "%-10s%5d\n","NALIGN",$ctali_taken;
	    last; }
	elsif ($_ =~ /^NCHAIN/){
	    $tmp=$_; $tmp=~s/\n//g;
	    $tmp=~s/^NCHAIN\s+\d+//g;
	    printf $fhout "%-10s%5d%-s\n","NCHAIN",$nchainWant,$tmp;
	    next; }
	elsif ($_ =~ /^KCHAIN/){
	    $tmp=$_; $tmp=~s/\n//g;
	    $tmp=~s/^KCHAIN\s+\d+//g;
	    $tmp=~s/(: \s*)[A-Za-z0-9].*$/$1/;
	    printf $fhout "%-10s%5d%-s%-s\n","KCHAIN",$nchainWant,$tmp,$chainWant;
	    next; }
	print $fhout $_;
    }
				# all others: simply mirror
    while (<$fhin>) {
	print $fhout $_;
    }
    close($fhin);
    close($fhout);
    print "--- $scrName wrote $fileOut\n" if ($Lverb);

#....,....1....,....2....,....3....,....4....,....5....,
#NALIGN      484
#    1 : rfa3_human          1.00  1.00  124  237
#    1 : kac_mouse           1.00  1.00  110  213
### ALIGNMENTS    1 -   70
#     1    1 E A              0   0  108   19   21  A
#    1 : rfa3_human          1.00  1.00     0    0    3  1
#  124    
#
#

}
unlink($fileOutTmp)             if (! $Ldebug);

print "--- output in $fileOut\n" if (-e $fileOut);
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
				# NOTE: may not be existing
	if ($file =~ /^(.*$par{"extHssp"})_([A-Za-z0-9])$/ &&
	    -e $1){ 
	    $tmpFile.=   $1.",";
	    $chainIn{$1}=$2;}
	else {
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
	}
    }close($fhinLoc);
    $tmpFile=~s/^,*|,*$//g;$tmpChain=~s/^,*|,*$//g;
    return(1,"ok $sbrName",$tmpFile,$tmpChain);
}				# end of fileListRd

#===============================================================================
sub hsspGetChain {
    local ($fileIn) = @_ ;
    local ($fhin,$ifirLoc,$ilasLoc,$tmp1,$tmp2,
	   $chainLoc,$posLoc,$posRd,$chainRd,@cLoc,@pLoc,%rdLoc);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   hsspGetChain                extracts all chain identifiers in HSSP file
#       in:                     $file
#       out:                    $chains (ABC) ,%rdLoc
#                      no chain -> $chains=' '
#       out                        $rdLoc{"NROWS"},$rdLoc{"$ct","chain"},
#       out                        $rdLoc{"$ct","ifir"},$rdLoc{"$ct","ilas"}
#--------------------------------------------------------------------------------
    $fhin="FhInHssp";
    return(0,"*** missing fileHssp=$fileIn!") if (! -e $fileIn);
    open($fhin,$fileIn) || return(0,"*** failed opening hssp=$fileIn!\n");
    while(<$fhin>){		# until start of data
	last if ($_=~/^ SeqNo/);}
    $chainLoc=$posLoc="";
    while(<$fhin>){
	if ($_=~/^\#/ && (length($chainLoc)>1) ) {
	    $posLoc.="$ifirLoc-$ilasLoc".",";
	    last;}
	$chainRd=substr($_,13,1);
	$aaRd=   substr($_,15,1);
	$posRd=  substr($_,1,6);$posRd=~s/\s//g;
	next if ($aaRd eq "!") ;  # skip over chain break
	if ($chainLoc !~/$chainRd/){	# new chain?
	    $posLoc.=         "$ifirLoc-$ilasLoc"."," if (length($chainLoc)>1);
	    $chainLoc.=       "$chainRd".",";
	    $ifirLoc=$ilasLoc=$posRd;}
	else { 
	    $ilasLoc=$posRd;}
    }close($fhin);
    $chainLoc=~s/^,|,$//g;
    $posLoc=~s/\s//g;$posLoc=~s/^,|,$//g; # purge leading ','
				# now split chains read
    undef %rdLoc; 
    $ctLoc=0;
    @cLoc=split(/,/,$chainLoc);
    @pLoc=split(/,/,$posLoc);

    foreach $itLoc(1..$#cLoc){
	($tmp1,$tmp2)=split(/-/,$pLoc[$itLoc]);
	next if ($tmp2 == $tmp1); # exclude chains of length 1
	++$ctLoc;
	$rdLoc{"NROWS"}=         $ctLoc;
	$rdLoc{$ctLoc,"chain"}=$cLoc[$itLoc];
	$rdLoc{$ctLoc,"ifir"}= $tmp1;
	$rdLoc{$ctLoc,"ilas"}= $tmp2;}
    $chainLoc=~s/,//g;
    return($chainLoc,%rdLoc);
}				# end of hsspGetChain

