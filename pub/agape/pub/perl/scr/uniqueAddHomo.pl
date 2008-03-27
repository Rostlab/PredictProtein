#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="takes list of ids, finds pairs of good resolution\n".
    "     \t in  : file_with_ids file_from_blastProcess.pl (as used in uniqueList.pl)\n".
    "     \t out : new list of ids\n".
    "     \t note: id-file MUST have '.list'  OR be first\n".
    "     \t       pair-file MUST have '.rdb' OR be second\n".
    "     \t ";
#  
# 
#------------------------------------------------------------------------------#
#	Copyright				        	1999	       #
#	Burkhard Rost		rost@columbia.edu			       #
#	CUBIC (Columbia Univ)	http://www.columbia.edu/~rost/   	       #
#       Dept Biochemistry & Molecular Biophysics			       #
#       630 West, 168 Street						       #
#	New York, NY 10032	http://www.columbia.edu/~rost/                 #
#				version 0.1   	Dec,    	1999	       #
#------------------------------------------------------------------------------#
#

$[ =1 ;				# count from one

				# ------------------------------
				# defaults
%par=(
      'fileIncl', "",		# file with ids of proteins to include
      'fileExcl', "",		# file with ids of proteins to exclude
      'fileRes',  "",		# file with resolution of PDB
				#      format:
				#      'id \t no_family \t length \t resolution'
				#      note: 1107 = undefined
      'dis',      0,		# minimal threshold to include = distance from HSSP
      'disMax',   90,		# maximal threshold to include = distance from HSSP
      
      'res',      2.5,		# cut-off in resolution (not used if no file 'fileRes'!)
      'resMax',   1107,		# used to mark that there is no resolution for current
#      '', "",			# 
#      '', "",			# 
      'dirHssp', "/data/hssp/",	# needed in the mode of checking whether or not HSSP file exists
      'extHssp', ".hssp",	# needed in the mode of checking whether or not HSSP file exists
      
      );
@kwd=sort (keys %par);
$Ldebug=      0;
$Lverb=       0;
$Lverb2=      0;
$LcheckHssp=  0;
$LcheckChain= 0;
$LcheckRes=   1;

				# ------------------------------
if ($#ARGV<1){			# help
    print  "goal: $scrGoal\n";
    print  "use:  '$scrName list_of_ids blastPost.rdb'\n";
    print  "opt:  \n";
				#      'keyword'   'value'    'description'
    printf "%5s %-15s=%-20s %-s\n","","fileOut", "x",       "name of output file";
#    printf "%5s %-15s=%-20s %-s\n","","dirOut",  "x",       "directory of output files";
#    printf "%5s %-15s=%-20s %-s\n","","",   "x", "";
#    printf "%5s %-15s %-20s %-s\n","","",   "no value","";
    printf "%5s %-15s=%-20s %-s\n","","incl",    "x",       "file with ids of proteins to include";
    printf "%5s %-15s=%-20s %-s\n","","excl",    "x",       "file with ids of proteins to exclude";
    printf "%5s %-15s=%-20s %-s\n","","dis",     "x",       "min distance (HSSP thresh) to take homologues";
    printf "%5s %-15s=%-20s %-s\n","","max",     "x",       "max distance (HSSP thresh) to take homologues";
    printf "%5s %-15s=%-20s %-s\n","","res",     "x",       "resolution threshold to take homologues";
    printf "%5s %-15s %-20s %-s\n","","   ",     " ",       "NOTE: no cut-off if no valid file with res!";
    printf "%5s %-15s=%-20s %-s\n","","fileRes", "x",       "file with PDB resolution";
    printf "%5s %-15s %-20s %-s\n","","   ",     " ",       "format of file:";
    printf "%5s %-15s %-20s %-s\n","","   ",     " ",       "  1:";
    printf "%5s %-15s %-20s %-s\n","","   ",     " ",       "id \t no_family \t length \t resolution";
    printf "%5s %-15s %-20s %-s\n","","   ",     " ",       "  2:";
    printf "%5s %-15s %-20s %-s\n","","   ",     " ",       "id \t resolution";
    printf "%5s %-15s %-20s %-s\n","","   ",     " ",       "  ";
    printf "%5s %-15s %-20s %-s\n","","   ",     " ",       "   note: '1107' means undefined resolution";

    printf "%5s %-15s=%-20s %-s\n","","nores",   "no value","do NOT check resolution";
    printf "%5s %-15s %-20s %-s\n","","nochn",   "no value","do NOT check chain";

    printf "%5s %-15s %-20s %-s\n","","check",   "no value","exclude if hssp file not existing";
    printf "%5s %-15s %-20s %-s\n","","hssp",    "no value","as above";
    printf "%5s %-15s %-20s %-s\n","","checkChn","no value","exclude if chain not in hssp file";
    printf "%5s %-15s %-20s %-s\n","","chain",   "no value","as above";
    printf "%5s %-15s=%-20s %-s\n","","dirHssp", "x",       "dir of HSSP (default /data/hssp)";
    printf "%5s %-15s=%-20s %-s\n","","extHssp", "x",       "ext of HSSP (default .hssp)";

    printf "%5s %-15s %-20s %-s\n","","dbg",     "no value","debug mode";
    printf "%5s %-15s %-20s %-s\n","","silent|-s","no value","no screen output";
    printf "%5s %-15s %-20s %-s\n","","verb|-s",  "no value","verbose";
    printf "%5s %-15s %-20s %-s\n","","verb2",   "no value","more verbose";
#    printf "%5s %-15s %-20s %-s\n","","noScreen", "no value","";
#    printf "%5s %-15s=%-20s %-s\n","","",   "x", "";
#    printf "%5s %-15s %-20s %-s\n","","",   "no value","";
    printf "%5s %-15s %-20s %-s\n","","   ",     " ",       "";
    printf "%5s %-15s %-20s %-s\n","","   ",     " ",       "";

    if (defined %par && $#kwd > 0){
	$tmp= sprintf("%5s %-15s  %-20s %-s\n","","-" x 15 ,"-" x 20,"-" x 30);
	$tmp.=sprintf("%5s %-15s  %-20s %-s\n","","other:","default settings: "," ");
	$tmp2="";
	foreach $kwd (@kwd){
	    next if (! defined $par{$kwd} || length($par{$kwd})<1 );
	    if ($par{$kwd}=~/^\d+$/){
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
foreach $arg (@ARGV){
#    next if ($arg eq $ARGV[1]);
    if    ($arg=~/^fileOut=(.*)$/)        { $fileOut=        $1;}
    elsif ($arg=~/^dirOut=(.*)$/)         { $dirOut=         $1; 
					    $dirOut.=        "/" if ($dirOut !~/\/$/);}
    elsif ($arg=~/^de?bu?g$/)             { $Ldebug=         1;
					    $Lverb=          1;}
    elsif ($arg=~/^verb(ose)?$|^\-v$/)    { $Lverb=          1;}
    elsif ($arg=~/^verb2$/)               { $Lverb2=         1;}
    elsif ($arg=~/^silent$|^\-s$/)        { $Lverb=          0;}

    elsif ($arg=~/^incl=(.*)$/)           { $par{"fileIncl"}=$1;}
    elsif ($arg=~/^excl=(.*)$/)           { $par{"fileExcl"}=$1;}
    elsif ($arg=~/^fres=(.*)$/)           { $par{"fileRes"}= $1;}
    elsif ($arg=~/^fileRes=(.*)$/)        { $par{"fileRes"}= $1;}

    elsif ($arg=~/^dis.*=(.*)$/)          { $par{"dis"}=     $1;}
    elsif ($arg=~/^max=(.*)$/)            { $par{"disMax"}=  $1;}
    elsif ($arg=~/^res=(.*)$/)            { $par{"res"}=     $1;}

    elsif ($arg=~/^dirHssp=(.*)$/)        { $par{"dirHssp"}= $1;}
    elsif ($arg=~/^extHssp=(.*)$/)        { $par{"extHssp"}= $1;}

    elsif ($arg=~/^nores$/i)              { $LcheckRes=      0;}
    elsif ($arg=~/^(nochn|nochain)$/i)    { $LcheckChain=    0;}

    elsif ($arg=~/^(check|hssp)$/)        { $LcheckHssp=     1;}
    elsif ($arg=~/^(checkCh|chain)/i)     { $LcheckChain=    1;
					    $LcheckHssp=     1;}
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

$par{"dirHssp"}.="/"            if (defined $par{"dirHssp"} &&
				    length($par{"dirHssp"})>1 &&
				    $par{"dirHssp"}!~/\/$/);
				    
$Lverb=$Lverb2=1                if ($Ldebug);

				# ------------------------------
				# sort out which is which
if ($#fileIn < 2) {
    print "*** ERROR $scrName: MUST have two input files, read the help the hack!\n";
    die;}
if ($fileIn[2] !~/\.list/ && $fileIn[1] !~/\.rdb/){
    $fileInList= $fileIn[1];
    $fileInPairs=$fileIn[2];}
else {
    $fileInList= $fileIn[2];
    $fileInPairs=$fileIn[1];}

die ("missing fileInList=$fileInList\n")   if (! -e $fileInList);
die ("missing fileInPairs=$fileInPairs\n") if (! -e $fileInPairs);

if (! defined $fileOut){
    $tmp=$fileInList;$tmp=~s/^.*\///g;
    $fileOut=   "Out-".$tmp;
    $fileOutAdd="Out-add-".$tmp;
    $fileOutFam="Out-fam-".$tmp;}
else {
    $fileOutAdd=$fileOut."_add";
    $fileOutFam=$fileOut."_fam";}
    

				# ------------------------------
				# directories: add '/'
foreach $kwd (keys %par) {
    next if ($kwd !~/^dir/);
    next if (length($par{$kwd})==0 || $par{$kwd} eq "unk" );
    $par{$kwd}.="/"          if ($par{$kwd} !~ /\/$/);}


				# ------------------------------
				# (1a) read file(s) with id
				# ------------------------------
$#idOrig=0; undef %idOrig;
undef %idTakenNochn; undef %idTaken;
print "--- $scrName: working on idlist=$fileInList!\n";
($Lok,$msg,@idOrig)=
    &fileRd($fileInList);       if (! $Lok){ print "*** ERROR $scrName: fileRd($fileInList) failed:",$msg;
					     exit; }
die("*** ERROR $scrName: no ids (idOrig) found in file!") if (! $#idOrig);
foreach $id (@idOrig){
    $id2=substr($id,1,4);
    $id2=$id                    if (! $LcheckChain);
    $idOrig_nochain{$id2}=1;	# avoid taking chains of same protein
    $idOrig{$id}=         1;
    $idTaken{$id}=        1;
    $idTakenNochn{$id2}=  1;
}
				# ------------------------------
				# (1b) read file with exclude id
				# ------------------------------
$#idExcl=0; undef %excl;
if (length($par{"fileExcl"}) > 0 && -e $par{"fileExcl"}){
    $fileIn=$par{"fileExcl"}; print "--- $scrName: working on excl=$fileIn!\n";
    ($Lok,$msg,@idExcl)=
	&fileRd($fileIn);       if (! $Lok){ print "*** ERROR $scrName: fileRd($fileIn) failed:",$msg;
					     exit; }
    foreach $id (@idExcl){
	$excl{$id}=1; }
}

				# ------------------------------
				# (1c) read file with include id
				# ------------------------------
$#idIncl=0;
if (length($par{"fileIncl"}) > 0 && -e $par{"fileIncl"}){
    $fileIn=$par{"fileIncl"};print "--- $scrName: working on incl=$fileIn!\n";
    ($Lok,$msg,@idIncl)=
	&fileRd($fileIn);       if (! $Lok){ print "*** ERROR $scrName: fileRd($fileIn) failed:",$msg;
					     exit; }}
				# ------------------------------
				# (1d) read file with resolution
				# ------------------------------
undef %res; $Lres=0; $#tmp=0;
if ($LcheckRes &&
    length($par{"fileRes"}) > 0 && -e $par{"fileRes"}){
    $fileIn=$par{"fileRes"}; print "--- $scrName: working on fileRes=$fileIn!\n";
    open($fhin,$fileIn) || die "*** $scrName ERROR opening file $fileIn";
    $Lres=1;
    while (<$fhin>) {
	$_=~s/\n//g;
	next if ($_=~/^\#/);	# skip comments
	next if ($_=~/^id/);	# skip names
	$_=~s/\#.*$//g;		# purge after comment
	@tmp=split(/\s+|\s*\t\s*/,$_); 
	$id= $tmp[1]; $id=~s/^.*\/|\s//g; # purge directories and blanks
	$res=$tmp[$#tmp]; $res=~s/\s//g;
	if ($res=~/[^0-9\.]/){
	    print "*** ERROR $scrName: fileRes=$fileIn, id=$id, res=$res?\n";
	    exit;}
				# skip those with too low resolution
	if (defined $par{"res"} && $par{"res"} &&
	    $res <= $par{"res"}){
	    $res{$id}=$res;}
    } close($fhin); }
				# ------------------------------
				# (2) process file with pairs
				#     and construct NEW
				# ------------------------------
$#add=0;undef %add; 
print "--- $scrName: working on fileInPairs=$fileInPairs!\n";
open($fhin,$fileInPairs) || die "*** $scrName ERROR opening filePairs=$fileInPairs";
while (<$fhin>) {
    $_=~s/\n//g;
    next if ($_=~/^\#/);	# skip comments
				# get position
    if ($_=~/^id/){
	@tmp=split(/\s*\t\s*/,$_); 
	foreach $it (1..$#tmp){
	    if    ($tmp[$it] =~ /^id1/) { $pos_id1=$it; }
	    elsif ($tmp[$it] =~ /^id2/) { $pos_id2=$it; }
#	    elsif ($tmp[$it] =~ /^res/) { $pos_res=$it; }
#	    elsif ($tmp[$it] =~ /^len/) { $pos_len=$it; }
	    elsif ($tmp[$it] =~ /^dis/) { $pos_dis=$it; }
	}
	next; }
	
    $_=~s/\#.*$//g;		# purge after comment
    @tmp=split(/\s*\t\s*/,$_); 

    $id1=$tmp[$pos_id1]; $id1=~s/^.*\/|\s//g; # purge directories and blanks
				# skip if not in list of original ids
    if (! defined $idOrig{$id1}){
	print "--- $scrName: $id1 skipped since in not in fileList\n"
	    if ($Lverb2);
	next;}
				# no homologues found
    if (! defined $tmp[$pos_id2]){
	print "--- $scrName: $id1 skipped since no homologues found\n"
	    if ($Lverb2);
	next;}
	

    $id2=$tmp[$pos_id2]; $id2=~s/\s//g;$id2=~s/^,|,$//g;
    $dis=$tmp[$pos_dis]; $dis=~s/\s//g;$dis=~s/^,|,$//g;
    @id2=split(/,/,$id2);
    @dis=split(/,/,$dis);
    foreach $it (1..$#id2){
	$id2=$id2[$it];
	$id2_nochain=substr($id2,1,4);
	$id2_nochain=$id2       if (! $LcheckChain);

				# 1: already known to be excluded
	if (defined $excl{$id2_nochain} || defined $excl{$id2}){
	    print "--- $scrName: $id2_nochain excluded since ($id2|$id2_nochain) taken\n"
		if ($Lverb2);
	    next;}
				# 2: different chain of protein already taken
	if (defined $idOrig_nochain{$id2_nochain}) {
	    $excl{$id2_nochain}=1;
	    print "--- $scrName: $id2_nochain excluded since different chain already\n"
		if ($Lverb2);
	    next;}
				# 3: avoid duplication
	if (defined $idTaken{id2}){
	    print "--- $scrName: $id2_nochain excluded since already\n"
		if ($Lverb2);
	    $excl{$id2}=1;
	    next;}
				# 4: avoid duplication, even if other chain
	if (defined $idTakenNochn{$id2_nochain}) {
	    print "--- $scrName: $id2_nochain excluded since already (may be other chain)\n"
		if ($Lverb2);
	    $excl{$id2_nochain}=1;
	    next;}
				# 5: missing HSSP?
	if ($LcheckHssp &&
	    ! -e $par{"dirHssp"}.$id2_nochain.$par{"extHssp"}){
	    print "--- $scrName: $id2_nochain excluded since no hssp?\n"
		if ($Lverb2);
	    $excl{$id2_nochain}=1;
	    next;}

	if ($Lres){		# 5: is resolution ok?
	    $res=0; 
	    $id2_nochain=substr($id2,1,4); 
	    $id2_nochain=$id2   if (! $LcheckChain);

	    if    (defined $res{$id2}) {
		$res=$res{$id2}; }
	    elsif (defined $res{$id2_nochain}) {
		$res=$res{$id2_nochain}; }
	    else {
		$res=$par{"resMax"}+1;}
	    if ($res > $par{"resMax"}){
		$excl{$id2_nochain}=1;
		print 
		    "--- $scrName: $id2_nochain excluded since too low res=$res (",
		    $par{"resMax"},")\n"
			if ($Lverb);
		next;}}
				# 6: too distant

	if ($dis[$it] <  $par{"dis"}){
	    print 
		"--- $scrName: $id2_nochain excluded since too distant (is=$dis[$it] parDis=",
		$par{"dis"},")\n"
		    if ($Lverb2);
	    next; }

				# 7: too close
	if ($dis[$it] >= $par{"disMax"}){
	    print 
		"--- $scrName: $id2_nochain excluded since too close (is=$dis[$it] disMax=",
		$par{"disMax"},")\n"
		    if ($Lverb2);
	    $excl{$id2}=1;
	    next;}
				# 8: check HSSP chain for existence?
	if ($LcheckChain && 
	    (length($id2)>4)){
	    $fileTmp=$par{"dirHssp"}.$id2_nochain.$par{"extHssp"};
	    $chainHere=substr($id2,length($id2),1);
	    $tmp=`grep KCHAIN $fileTmp`;
	    if (! defined $tmp || length($tmp)<3 || $tmp !~ /chain/) {
				# grep again (HOLM error seems to happen for single chains)
		open(FHIN_TMP,$fileTmp)||
		    warn("*** WARN $scrName failed opening fileTmp=$fileTmp\n");
		while(<FHIN_TMP>){
		    next if ($_!~/^\s+\d+\s+\d+ (.)/);
		    $tmp2=$1;
		    last;}close(FHIN_TMP);
				# 8a  -> DO exclude
		if ($tmp2 ne $chainHere) {
		    $excl{$id2}=1;
		    next;}}
				# 8b  -> DO exclude
	    elsif ($tmp !~/$chainHere/){
		$excl{$id2}=1;
		next;}
	}

				# --------------------
				# finally one found
	print "--- $scrName: $id2 taken!\n" if ($Lverb);
	
	$idTaken{$id2}=             1;
	$idTakenNochn{$id2_nochain}=1;
	$add{$id2}=                 $id1; # origin
	push(@add,$id2);
    }
} close($fhin); 
				# end of processing pairs
				# ------------------------------

				# ------------------------------
				# (3) nothing to do?
if (! $#add){
    print "-*- RESULT $scrName: NOTHING to add (really??)\n";
    exit;}

				# ------------------------------
				# (4) write output
				# ------------------------------
				# all ids
open($fhout,">".$fileOut) || warn "*** $scrName ERROR creating fileOut=$fileOut";
foreach $id (@idOrig,@add){
    print $fhout $id,"\n";
}
close($fhout);
				# all new ids
open($fhout,">".$fileOutAdd) || warn "*** $scrName ERROR creating fileOutAdd=$fileOutAdd";
foreach $id (@add){
    print $fhout $id,"\n";
}
close($fhout);
				# all ids
open($fhout,">".$fileOutFam) || warn "*** $scrName ERROR creating fileOutFam=$fileOutFam";
print $fhout "id2","\t","similar to original","\n";
foreach $id (@add){
    print $fhout $id,"\t",$add{$id},"\n";
}
close($fhout);

print "--- original  no=    ",sprintf("%5d",$#idOrig)," $fileInList\n";
print "--- all ids (new):   ",sprintf("%5d",($#add+$#idOrig)),"  $fileOut\n"    if (-e $fileOut);
print "--- family relations:",sprintf("%5d",$#add),"  $fileOutFam\n" if (-e $fileOutFam);
print "--- ids added:       ",sprintf("%5d",$#add),"  $fileOutAdd\n" if (-e $fileOutAdd);
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
sub fileRd {
    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   fileRd                    reads ids in file (returns all in array)
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."fileRd";
    $fhinLoc="FHIN_"."fileRd";$fhoutLoc="FHOUT_"."fileRd";
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
    return(&errSbr("no fileIn=$fileInLoc!"))  if (! -e $fileInLoc);
				# open file
    open($fhinLoc,$fileInLoc) || return(&errSbr("fileInLoc=$fileInLoc, not opened"));
    $#tmp=0;
				# ------------------------------
    while (<$fhinLoc>) {	# read file
	$_=~s/\n//g;
	$_=~s/^.*\///g;		# purge directories
	next if ($_=~/^\#/);	# skip comments
	next if ($_=~/^id/);	# skip names
	$_=~s/\#.*$//g;		# purge after comment
	$_=~s/\s//g;		# purge blanks
	push(@tmp,$_);
    } close($fhinLoc);
    return(1,"ok $sbrName",@tmp);
}				# end of fileRd

#===============================================================================
sub subx {
#    local($fileInLoc,$fhErrSbr) = @_ ;
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   subx                       
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."subx";
    $fhinLoc="FHIN_"."subx";$fhoutLoc="FHOUT_"."subx";
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
#    return(&errSbr("not def !"))          if (! defined $);

    return(&errSbr("no fileIn=$fileInLoc!"))  if (! -e $fileInLoc);
				# open file
    open($fhinLoc,$fileInLoc) || return(&errSbr("fileInLoc=$fileInLoc, not opened"));
    open($fhoutLoc,">".$fileOutLoc) || return(&errSbr("fileOutLoc=$fileOutLoc, not created"));
				# ------------------------------
    while (<$fhinLoc>) {	# read file
				# skip comments
	next if ($_=~/^[\s\t]*\#/);
	$_=~s/\n//g;
	next if (length($_)==0); # skip empty


    } close($fhinLoc);
    return(1,"ok $sbrName");
}				# end of subx

