#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="takes sec and acc and writes from DSSP file into HSSP file\n";
#  
#

$[ =1 ;
				# ------------------------------
				# defaults
%par=(
      'dirDssp', "/data/dssp/",
      'dirHssp', "/home/rost/data/hsspFil/",

      'dirDssp', "/data/dssp/",

      'extDssp', ".dssp",
      'extHssp', ".hssp",
      '', "",
      );
@kwd=sort (keys %par);

				# ------------------------------
if ($#ARGV<1){			# help
    print  "goal: $scrGoal\n";
    print  "use:  '$scrName *hssp (or list)' (pass DSSP files by dirDssp=x, or have in same dir)\n";
    print  "      default in: HSSP files and DSSP expected local or in dirDssp (kwd chn-> purge chain)\n";
    print  "opt:  \n";
				#      'keyword'   'value'    'description'
    printf "%5s %-15s=%-20s %-s\n","","fileOut",  "x",       "";
    printf "%5s %-15s=%-20s %-s\n","","dirOut",   "x",       "if given: name fileIn=fileOut BUT in dirOut";
    printf "%5s %-15s %-20s %-s\n","","dbg",   "no value",   "debug mode";
    printf "%5s %-15s %-20s %-s\n","","silent|-s","no value","no screen output";
    printf "%5s %-15s %-20s %-s\n","","verb|-s",  "no value","verbose";

    print  "\n";
    printf "%5s %-15s %-20s %-s\n","","isid",     "no value","list of ids (dir[DH]ssp,ext[DH]ssp filled in)";
#    printf "%5s %-15s=%-20s %-s\n","","",   "x", "";
#    printf "%5s %-15s %-20s %-s\n","","",   "no value","";

    printf "%5s %-15s %-20s %-s\n","","list",     "no value","if input file is list of FASTA files".
	                                                     " note: automatic if extension *.list!!";
    printf "%5s %-15s %-20s %-s\n","","chn",      "no value","purge chain from HSSP name (9ame_A.hssp or 9ame.hssp_A)";

    printf "%5s %-15s=%-20s %-s\n","","dssp",     "x.dssp,y.dssp", "to give corresponding dssp files (same succession!!!)";

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
$fhin="FHIN";$fhout="FHOUT";
$LisList=0;
$LisId=  0;
$LisChn= 0;
$#fileIn=$#chainIn=0;
$Ldebug=0;
$Lverb= 0;
$dirOut=0;
				# ------------------------------
				# read command line
foreach $arg (@ARGV){
#    next if ($arg eq $ARGV[1]);
    if    ($arg=~/^fileOut=(.*)$/)        { $fileOut=$1;}
    elsif ($arg=~/^dirOut=(.*)$/)         { $dirOut= $1;
					    $dirOut.="/"     if ($dirOut !~ /\/$/);}
    elsif ($arg=~/^isid$/i)               { $LisId=  1;}
    elsif ($arg=~/^ch.*n$/i)              { $LisChn= 1;}

    elsif ($arg=~/^dssp=(.*)$/)           { push(@fileDssp,split(/,/,$1));}
    elsif ($arg=~/^fileDssp=(.*)$/i)      { push(@fileDssp,split(/,/,$1));}
    elsif ($arg=~/^dir=(.*)$/)            { $par{"dirDssp"}= $1;}
#    elsif ($arg=~/^=(.*)$/){ $=$1;}
    elsif ($arg=~/^list$/i)               { $LisList=        1;}

    elsif ($arg=~/^de?bu?g$/)             { $Ldebug=         1;
					    $Lverb=          1;}
    elsif ($arg=~/^verb(ose)?$|^\-v$/)    { $Lverb=          1;}
    elsif ($arg=~/^silent$|^\-s$/)        { $Lverb=          0;}

    elsif (-e $arg)                       { push(@fileIn,$arg); push(@chainIn,"*");
					    # automatic detection of list
					    $LisList=        1 if ($arg =~ /\.list/); }
    elsif ($arg=~/^(\.hssp)\_([A-Z0-9])/) { push(@fileIn,$1);   push(@chainIn,$2);}
    elsif (defined %par && $#kwd>0)       { 
	$Lok=0; 
	foreach $kwd (@kwd){ if ($arg =~ /^$kwd=(.+)$/){$Lok=1;$par{"$kwd"}=$1;
							last;}}
	if (! $Lok){ print "*** wrong command line arg '$arg'\n";
		     exit;}}
    else { print "*** wrong command line arg '$arg'\n"; 
	   exit;}}

$Lverb=1                        if ($Ldebug);
$par{"debug"}=                  $Ldebug;

$fileIn=$fileIn[1];
die ("missing input $fileIn\n") if (! -e $fileIn);

				# ------------------------------
				# directories: add '/'
foreach $kwd (keys %par) {
    next if ($kwd !~/^dir/);
    next if (length($par{"$kwd"})==0 || $par{"$kwd"} eq "unk" );
    $par{"$kwd"}.="/"          if ($par{"$kwd"} !~ /\/$/);}


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
				# ------------------------------
				# get chain
if ($LisChn){
    foreach $it (1..$#fileIn){
	$file=$fileIn[$it];
	if    ($file =~ /_(.)$par{"extHssp"}/ && 
	    defined $1 && length($1)==1){
	    $chainIn[$it]=$1;
	}
	elsif ($file =~ /$par{"extHssp"}_(.)/ && 
	    defined $1 && length($1)==1){
	    $chainIn[$it]=$1;
	}
    }}
else {
    $chn2read="*";}
				# --------------------------------------------------
				# (1) read file(s)
				# --------------------------------------------------
$ctFile=0;
foreach $fileIn (@fileIn){
    ++$ctFile;
				# ------------------------------
				# get file name
				# ------------------------------
    if ($LisId || 
	($fileIn !~ /$par{"extDssp"}/ && $fileIn !~ /$par{"extHssp"}/)) {
	print "--- $scrName: assumed is id $fileIn\n";
	$id=$fileIn;
	$fileDssp=$par{"dirDssp"}.$id.$par{"extDssp"}; 
	$fileHssp=$par{"dirHssp"}.$id.$par{"extHssp"};  }
    elsif ( &is_hssp($fileIn)) {
	print "--- $scrName: assumed $fileIn is HSSP file\n";
	$fileHssp=$fileIn;

	$id=$fileIn; 
	$id=~s/^.*\///g; 
	$id=~s/$par{"extHssp"}//g; 
	if ($LisChn){
	    $id=~s/(1[a-z].*)[_:]$chainIn[$ctFile]/$1/;
	}
	if (defined @fileDssp){
	    $fileDssp=$fileDssp[$ctFile];}
	else {
	    $fileDssp=$fileHssp;
	    $fileDssp=~s/$par{"extHssp"}/$par{"extDssp"}/;
	    $chn2read="*";}

	$fileDsspNochn=$fileDssp;
				# try to purge the chain
	if (! -e $fileDssp && $LisChn){
#	    $fileDssp=~s/([1-9][a-z0-9][a-z0-9][a-z0-9])_$chainIn[$ctFile]/$1/;
	    $fileDsspNochn=~s/_$chainIn[$ctFile]//;
	    $chn2read=$chainIn[$ctFile];}
				# try to add directory
	if (! -e $fileDsspNochn && 
	    defined $par{"dirDssp"} && 
	    -d $par{"dirDssp"}){
	    $fileDssptmp=$par{"dirDssp"}.$fileDsspNochn;
	    if (-e $fileDssptmp){
		$fileDssp=     $fileDssptmp;
		$fileDsspNochn=$fileDssptmp;}}
				# try dir WITH chain
	if (! -e $fileDsspNochn){
	    $fileDssp=$par{"dirDssp"}.$id.$par{"extDssp"}; }
    }
    else {
	print "--- $scrName: assumed $fileIn is DSSP file\n";
	$fileDssp=$fileIn;
	$id=$fileIn; 
	$id=~s/^.*\///g; 
	$id=~s/$par{"extDssp"}//g; 
	$fileHssp=$par{"dirHssp"}.$id.$par{"extHssp"};  }

    if (! defined $fileOut || $ctFile > 1){
	if (! $dirOut){
	    if ($LisChn && $chn2read ne "*" && $id !~ /$chn2read/){
		$fileOut=$id."_".$chn2read."-new".$par{"extHssp"};  }
	    else {
		$fileOut=   $id."-new".$par{"extHssp"};  }}
	else {
	    $fileOut=$fileHssp;
	    $fileOut=~s/^.*\///g;
	    $fileOut=$dirOut.$fileOut;
	    $fileOut.="New"         if ($fileOut eq $fileHssp);
	}}
    die ("*** strange name for output file $fileOut!\n") if ($fileOut !~ /^[\\a-z0-9A-Z]/);

    $chn2read="*"               if (! $LisChn || ! defined $chn2read);

    if (! -e $fileDssp && ! -e $fileDsspNochn){
	print "-*- WARN $scrName: no fileDssp=$fileDssp\n";
	$id=$fileDssp;$id=~s/^.*\///g;$id=~s/\..*$//g;
	$id=~s/_.$//g;
	$tmp="/data/pdb/".$id.".pdb ".$id.".dssp";
	system("echo '$tmp' >> DO_dssp.tmp");
	next;}
    next if (! -e $fileHssp);	# xx hack

    $#dssp=$#hssp=0;
				# ------------------------------
				# read DSSP
				# ------------------------------
    printf 
	"--- $scrName: working on %-25s %4d (%4.1f%-1s)\n",
	$fileDssp,$ctFile,(100*$ctFile/$#fileIn),"%";
    open($fhin, $fileDsspNochn) || die "*** ERROR $scrName: failed opening dsspNochn=$fileDsspNochn";

    undef %dssp_hdr;
    while (<$fhin>) {
				# skip everything before sequence
	last if ($_=~/^\s+\#\s+RESIDUE/); 
	chop;
	if    ($_=~/^HEADER\s*(\S+.*)\s\d\d\-\w\w\w\-\d\d.*[\s\.]*$/){
	    $dssp_hdr{"HEADER"}=$1;}
	elsif ($_=~/^COMPND\s*(\S+.*)[\s\.]*$/){
	    $dssp_hdr{"COMPND"}=$1;}
	elsif ($_=~/^SOURCE\s*(\S+.*)[\s\.]*$/){
	    $dssp_hdr{"SOURCE"}=$1;}
	elsif ($_=~/^AUTHOR\s*(\S+.*)[\s\.]*$/){
	    $dssp_hdr{"AUTHOR"}=$1;}
    }
    $chnDssp=$seqDssp="";
    while (<$fhin>) {
	$_=~s/\n//g;
	$chn=substr($_,12,1);
	$seq=substr($_,14,1);
				# skip chain identifiers
#	next if ($seq eq "!");
				# wants chain?
	next if ($chn2read ne "*"  &&
		 $chn ne $chn2read && 
		 $chn ne " ");
	push(@dssp,substr($_,1,50));
	$chnDssp.=$chn;
	$seqDssp.=$seq;
    }close($fhin);
				# ------------------------------
				# read HSSP
				# ------------------------------
    print "--- \t reading HSSP '$fileHssp'\n";
    open($fhin, $fileHssp) || die "*** ERROR $scrName: failed opening hssp=$fileHssp";
				# header HSSP
    while (<$fhin>) {
	$_=~s/\n//g;
	push(@hssp,$_);
	last if ($_=~/^ SeqNo/);
    }
				# sequence + chain
    $seqHssp=$chnHssp="";
    while (<$fhin>) {
	$_=~s/\n//g;
	push(@hssp,$_);
	last if ($_=~/^\#\#/);	# read only one round of alignments
	$chn=substr($_,13,1);
	$seq=substr($_,15,1);
				# wants chain?
	next if ($chn2read ne "*"  &&
		 $chn ne $chn2read &&
		 $chn ne " ");
	$chnHssp.=$chn;
	$seqHssp.=$seq;
    }
				# all other HSSP
    while (<$fhin>) {
	$_=~s/\n//g;
	push(@hssp,$_);
    }
    close($fhin);
				# --------------------------------------------------
				# find corresponding sequence
				#    out GLOBAL: %tmp
				#    with: $tmp{'1','nres'},$tmp{'1','nres'}
				#    $tmp{'1',$itres}=$corresponding_position_in_2
				#    $tmp{'2',$itres}=$corresponding_position_in_1
				#    
    $#trans_hssp2dssp=0;
    $seqHssp=~s/[a-z]/C/g;	# replace cysteine bridges
    $seqDssp=~s/[a-z]/C/g;	# replace cysteine bridges
    if ($seqHssp ne $seqDssp){
	if ($Ldebug){
	    print "dbg dssp seq=$seqDssp\n";
	    print "dbg hssp seq=$seqHssp\n";}
	($Lok,$msg)=
	    &sequenceAlign
		($seqDssp,$seqHssp);     
	if (! $Lok){
	    print 
		"*** ERROR $scrName: different sequences fileDssp=$fileDssp, fileHssp=$fileHssp\n".
		    " hssp=$seqHssp\n".
			" dssp=$seqDssp\n".
			    " ERROR message from sequenceAlign:\n".$msg."\n";
	    system("echo '$fileHssp' >> ERROR_differ.tmp");
	    next; }
	    
	foreach $itres (1..$loc{"2","nres"}){
	    next if (! defined $loc{"2",$itres});
	    $trans_hssp2dssp[$itres]=$loc{"2",$itres};
#	    print "xx hssp $itres 2 dssp ",$loc{"2",$itres}," (seqhssp=",substr($seqHssp,$itres,1),", seqdssp=",substr($seqDssp,$loc{"2",$itres},1),"), dssp=",$dssp[$loc{"2",$itres}],",\n";
	}
	undef %loc;
    }
				# identical sequences
    else {
	foreach $itres (1..length($seqHssp)){
	    $trans_hssp2dssp[$itres]=$itres;
	}
	
	print "dbg are identical\n" if ($Ldebug);
    }

				# ------------------------------
				# write new
				# ------------------------------
    print "--- \t writing new HSSP '$fileOut'\n";
    open($fhout, ">".$fileOut) || die "*** ERROR $scrName: failed creating out=$fileOut";

    $Lhead=1;$Lbottom=0;
    foreach $hssp (@hssp){
#	print "dbg read '$hssp'\n"  if ($Ldebug);
	if ($hssp=~/^ SeqNo/){
	    $Lhead=0;
	    $ct=0;
	    print $fhout $hssp."\n";}
	elsif ($hssp=~/^\#\# SEQUENCE/){
	    $Lbottom=1;
	    print $fhout $hssp."\n";}
	elsif ($hssp=~/^\#\# ALIGN/){
	    print $fhout $hssp."\n";}
	elsif ($Lhead)   {
	    foreach $kwd ("HEADER","COMPND","SOURCE","AUTHOR"){
		next if (! defined $dssp_hdr{$kwd});
		next if ($hssp !~/^$kwd/);
		$hssp=$kwd."     ".$dssp_hdr{$kwd};
		$hssp=~s/[\s\.\,]*$//g;
		last;}
	    print $fhout $hssp."\n";}
	elsif ($Lbottom) {
	    print $fhout $hssp."\n";}
	else {
	    ++$ct;
	    $seqHssp=substr($hssp,15,1);          
	    $seqHssp="C" if ($seqHssp=~/[a-z]/);
	    $Lskip=0;
	    if    (! defined $trans_hssp2dssp[$ct] && $seqHssp ne "!") {
		print "dbg not defined trans($ct)\n"  if ($Ldebug);
		$Lskip=1;
		system("echo '$fileHssp' >> ERROR_differ.tmp");
#		close($fhout);
#		unlink($fileOut);
#		$#hssp=0;
#		last;
	    }
	    elsif (! defined $trans_hssp2dssp[$ct] && $seqHssp eq "!") {
		$Lskip=1;}

	    if ($Lskip){
		print $fhout $hssp,"\n";
		next; }
		
	    $ctDssp= $trans_hssp2dssp[$ct];
	    $seqDssp=substr($dssp[$ctDssp],14,1); $seqDssp="C" if ($seqDssp=~/[a-z]/);
				# check sequences
	    if ($seqHssp ne $seqDssp){
		print "*** difference ctHssp=$ct, ctDssp=$ctDssp, seqDssp=$seqDssp, hssp=$seqHssp\n";
		system("echo '$fileHssp' >> ERROR_differ0.tmp");
		close($fhout);
		$#hssp=0;
		last;}
	    $dssp= substr($dssp[$ctDssp],17,22);
	    if (length($dssp[$ctDssp]) < 49) {
		print "*** ERROR $scrName: fileDssp=$fileDssp, fileHssp=$fileHssp\n";
		print "***       ct=$ct, ctDssp=$ctDssp, line dssp too short:\n";
		print "     ", "." x 16 , "-" x 22 ,"\n";
		print "dssp=$dssp[$ctDssp]\n"; 
		system("echo '$fileHssp' >> ERROR_differ1.tmp");
		close($fhout);
		$#hssp=0;
		last;}

	    $tmp1=substr($hssp,1,17);
	    $tmp2=substr($hssp,40);
				# fill in chain
	    if ($LisChn && $chn2read ne "*"){
		$tmp1a=substr($tmp1,1,12);
		$tmp1b=substr($tmp1,14);
		$tmp1=$tmp1a.$chn2read.$tmp1b;}

	    $hsspN=$tmp1.$dssp.$tmp2;

	    if (length($hssp) < 17) {
		print "*** ERROR $scrName: fileDssp=$fileDssp, fileHssp=$fileHssp\n";
		print "***       ct=$ct, ctDssp=$ctDssp, line hssp too short (<17):\n";
		print "     ", "-" x 17 , "\n";
		print "hssp=$hssp\n"; 
		system("echo '$fileHssp' >> ERROR_differ2.tmp");
		close($fhout);
		$#hssp=0;
		last;}

	    if (length($hssp) < 40) {
		print "*** ERROR $scrName: fileDssp=$fileDssp, fileHssp=$fileHssp\n";
		print "***       ct=$ct, ctDssp=$ctDssp, line hssp too short (<40):\n";
		print "     ", "-" x 40 , "\n";
		print "hssp=$hssp\n"; 
		system("echo '$fileHssp' >> ERROR_differ3.tmp");
		close($fhout);
		$#hssp=0;
		last;}
		
	    print $fhout $hsspN."\n";
	}
    }
    close($fhout);
}

exit;

#===============================================================================
sub sequenceAlign {
    local(@seqLoc) = @_ ;
    local($sbrName,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   sequenceAlign               supposed to find corresponding residues
#                   ASSUMPTION: differ only by
#                               - begin / end of sequence
#                               - chain break symbols '!'
#                               - insertions '.'
#                               - 
#                               
#                               
#       in:                     @seqLoc=($seq1,$seq2)
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."sequenceAlign";
    
    undef %loc;

				# length
    $lenLoc[1]=$loc{"1","nres"}=length($seqLoc[1]);
    $lenLoc[2]=$loc{"2","nres"}=length($seqLoc[2]);

				# ------------------------------
				# (1) are identical
    if ($seqLoc[1] eq $seqLoc[2]){
	foreach $it (1..$lenLoc[1]){
	    $loc{"1",$it}=$it;
	    $loc{"2",$it}=$it; }
				# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
	$#seqLoc=0;		# slim-is-in
	return(1,"ok");		# problem solved
				# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    }

				# ------------------------------
				# purge chain breaks or '.'
    if ($seqLoc[1] =~ /[!\.]/ || $seqLoc[2] =~ /[!\.]/){
	$seqTmp[1]=$seqLoc[1];
	$seqTmp[2]=$seqLoc[2];
	$seqTmp[1]=~s/[!\.]//g;
	$seqTmp[2]=~s/[!\.]//g; }
    else {
	$seqTmp[1]=$seqLoc[1];
	$seqTmp[2]=$seqLoc[2];}
				# start with shorter one
    $posShorter=1; $posLonger= 2;
    if ($lenLoc[1] > $lenLoc[2]){
	$posShorter=2; $posLonger=1;}
#     print "  ","-" x 202 ,"\n";
#     print "1=$seqTmp[1]\n";
#     print "2=$seqTmp[2]\n";
#     print "xx differ\n" if ($seqTmp[1] ne $seqTmp[2]);
#     @tmp1=split(//,$seqTmp[1]);
#     @tmp2=split(//,$seqTmp[2]);
#     foreach $it (1..$#tmp1){
# 	next if ($tmp1[$it] eq $tmp2[$it]);
# 	print "xx $it 1=$tmp1[$it] 2=$tmp2[$it]\n";
#     }
	
#     die;
				# ------------------------------
				# (2) identical without '.' '!'
    if ($seqTmp[1] eq $seqTmp[2]            ||
	$seqTmp[$posShorter] =~ /$seqTmp[$posLonger]/){
				# (2a) 1-> 2
	$del1=$del2=0;
	foreach $it (1..length($seqTmp[1])){
	    $it1=$it+$del1;
	    $it2=$it+$del2;
	    last if ($it1 > $lenLoc[1]);
	    last if ($it2 > $lenLoc[2]);
				# break in 1: count up
	    while ($it1 < $lenLoc[1] && substr($seqLoc[1],$it1,1) =~ /[!\.]/){
		++$del1; ++$it1; }
				# break in 2: count up
	    while ($it2 < $lenLoc[2] && substr($seqLoc[2],$it2,1) =~ /[!\.]/){
		++$del2; ++$it2; }
				# ERROR
	    return(0,"ERROR $sbrName(2a): residues for it=$it do not match!\n".
		   "  seqTmp1=$seqTmp[1]\n".
		   "  seqTmp2=$seqTmp[2]\n".
		   "  it1=$it1, it2=$it2, it=$it, del1=$del1, del2=$del2\n") 
		if (substr($seqLoc[1],$it1,1) ne substr($seqLoc[2],$it2,1));
	    $loc{"1",$it1}=$it2;
	}
				# (2b) 2-> 1
	$del1=$del2=0;
	foreach $it (1..length($seqTmp[2])){
	    $it1=$it+$del1;
	    $it2=$it+$del2;
	    last if ($it1 > $lenLoc[1]);
	    last if ($it2 > $lenLoc[2]);
				# break in 1: count up
	    while ($it1 < $lenLoc[1] && substr($seqLoc[1],$it1,1) =~ /[!\.]/){
		++$del1; ++$it1; }
				# break in 2: count up
	    while ($it2 < $lenLoc[2] && substr($seqLoc[2],$it2,1) =~ /[!\.]/){
		++$del2; ++$it2; }
				# ERROR
	    return(0,"*** ERROR $sbrName(2b): residues for it=$it do not match!\n".
		   "  seq1tmp=$seqTmp[1]\n".
		   "  seq2tmp=$seqTmp[2]\n".
		   "  it1=$it1, it2=$it2, it=$it, del1=$del1, del2=$del2\n") 
		if (substr($seqLoc[1],$it1,1) ne substr($seqLoc[2],$it2,1));
	    $loc{"2",$it2}=$it1;
	}
				# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
	$#seqTmp=$#seqLoc=0;	# slim-is-in
	return(1,"ok");		# problem solved
				# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    }
				# --------------------------------------------------
				# (3) still differ: find fragment!
				# 
				# reduce word length scanned in intervals of 10
				#       starting from lenghtShorter - 10
    $max=int($lenLoc[$posShorter]/10);
    if (defined $par{"debug"} && $par{"debug"}){
	print "dbg shorter=$lenLoc[$posShorter], $posShorter\n";
	print "dbg longer =$lenLoc[$posLonger], $posLonger\n";}
    foreach $itreduce (0 .. $max){
	$wordLenLoc=$lenLoc[$posShorter]-10*$itreduce;
	$it=1; $match=$itmatch=0;
	print "dbg itreduce=$itreduce, wordlne=$wordLenLoc,\n" 
	    if (defined $par{"debug"} && $par{"debug"});

	while (($it+$wordLenLoc-1) <= $lenLoc[$posShorter]){
	    $match=substr($seqTmp[$posShorter],$it,$wordLenLoc);
				# (3a)  DOES match -> expand from here
	    if ($seqTmp[$posLonger] =~ /$match/){
		$itmatch=$it;
		$ittmp=  0;
				#       expand ONE at a time BEFORE
		while ($ittmp > 0 && $match =~ /$seqTmp[$posLonger]/) {
		    $match=substr($seqTmp[$posShorter],($itmatch-$ittmp),1).$match;
		    ++$ittmp;}
		$itmatch=$itmatch-$ittmp;
		$ittmp=  0;
				#       expand ONE at a time AFTER
		$itmax=$lenLoc[$posShorter]-$wordLenLoc;
		while ($ittmp < $itmax && $match =~ /$seqTmp[$posLonger]/) {
		    $match=$match.substr($seqTmp[$posShorter],($itmatch-$ittmp),1);
		    ++$ittmp;}
		$itmatch=$itmatch+$ittmp;
		last;		# finish if one was found!
	    }
				# count up by ONE, since it did NOT match

	    if (defined $par{"debug"} && $par{"debug"}){
#		print "dbg 1:$seqTmp[$posShorter]\n";
#		print "dbg 2:$seqTmp[$posLonger]\n";
#		print "dbg m:$match\n";
#		print "dbg does NOT match for $it \n";
	    }
	    $match=0;
	    ++$it; 
	}
				# found match
	last if ($match);
    }				# end of loop over word length intervals
				# --------------------------------------------------

				# ******************************
				# ERROR never found one
    return(0,"*** ERROR $sbrName: never found a match!\n".
	   "  seq1tmp=$seqTmp[1]\n".
	   "  seq2tmp=$seqTmp[2]\n".
	   "  seq1 in=$seqLoc[1]\n".
	   "  seq2 in=$seqLoc[2]\n")
	if (! $match);
				# ok: fill in
    if (defined $par{"debug"} && $par{"debug"}){
	print "dbg found a match at residue=$itmatch, length=",length($match),"\n";
	print "dbg match is=$match\n";
	print "dbg     1 is=$seqLoc[1]\n";
	print "dbg     2 is=$seqLoc[2]\n";}

				# find out where that match is in 1
    $tmp=$seqTmp[1]; 
    $tmp=~s/^(.*)($match)/$2/;
    if (defined $1){
	$begLoc[1]=length($1);} else {$begLoc[1]=0;}
    $tmp=~s/($match)(.*)$/$1/;
    if (defined $2){
	$endLoc[1]=length($2);} else {$endLoc[1]=0;}
				# find out where that match is in 2
    $tmp=$seqTmp[2]; 
    $tmp=~s/^(.*)($match)/$2/;
    if (defined $1){
	$begLoc[2]=length($1);} else {$begLoc[2]=0;}
    $tmp=~s/($match)(.*)$/$1/;
    if (defined $2){
	$endLoc[2]=length($2);} else {$endLoc[2]=0;}

				# count insertions before
    foreach $itpos (1..2){
	foreach $it (1..$begLoc[$itpos]){
	    ++$begLoc[$itpos]   if (substr($seqLoc[$itpos],$it,1) =~ /[!\.]/);
	}}

    print "dbg 1=$begLoc[1]-$endLoc[1], 2=$begLoc[2]-$endLoc[2]\n" 
	if (defined $par{"debug"} && $par{"debug"});

				# (3a) 1-> 2
    $it1=1;
    $it2=1+$begLoc[2];
    while ($it1 <= $lenLoc[1]){
				# skip all to ignore before
	if ($it1 <= $begLoc[1]){
	    ++$it1;
	    next; }
	
				# finish if end
	last if ($it1 > ($lenLoc[1] - $endLoc[1]) );
	last if ($it2 > ($lenLoc[2] - $endLoc[2]) );
				# break in 1: count up
	while ($it1 < ($lenLoc[1] - $endLoc[1]) &&
	       substr($seqLoc[1],$it1,1) =~ /[!\.]/){
	    ++$it1; }
				# break in 2: count up
	while ($it2 < ($lenLoc[2] - $endLoc[2]) &&
	       substr($seqLoc[2],$it2,1) =~ /[!\.]/){
	    ++$it2; }
				# ERROR
	return(0,"ERROR $sbrName(3a): residues for it=$it do not match !\n".
	       "1(10)=".substr($seqLoc[1],$it1,10).", 2(10)=".substr($seqLoc[2],$it2,10)."!\n".
	       "  seqTmp1=$seqTmp[1]\n".
	       "  seqTmp2=$seqTmp[2]\n".
	       " it1=$it1, it2=$it2, it=$it, del1=$del1, del2=$del2\n") 
	    if (substr($seqLoc[1],$it1,1) ne substr($seqLoc[2],$it2,1));
	$loc{"1",$it1}=$it2;
	++$it1; ++$it2;
    }
				# (3b) 2-> 1
    $del1=$del2=0; 
    $it1=1+$begLoc[1]; 
    $it2=1;
    while ($it2 <= $lenLoc[2]){
				# skip all to ignore before
	if ($it2 <= $begLoc[2]){
	    ++$it2;
	    next; }
				# finish if end
	last if ($it1 > ($lenLoc[1] - $endLoc[1]) );
	last if ($it2 > ($lenLoc[2] - $endLoc[2]) );
				# break in 1: count up
	while ($it1 < ($lenLoc[1] - $endLoc[1]) &&
	       substr($seqLoc[1],$it1,1) =~ /[!\.]/){
	    ++$it1; }
				# break in 2: count up
	while ($it2 < ($lenLoc[2] - $endLoc[2]) &&
	       substr($seqLoc[2],$it2,1) =~ /[!\.]/){
	    ++$it2; }
				# ERROR
	return(0,"ERROR $sbrName(3b): residues for it=$it do not match ".
	       "1=".substr($seqLoc[1],$it1,1).", 2=".substr($seqLoc[2],$it2,1)."!\n".
	       "  1:".." 2:\n".
	       "  seqTmp1=$seqTmp[1]\n".
	       "  seqTmp2=$seqTmp[2]\n".
	       " it1=$it1, it2=$it2, it=$it, del1=$del1, del2=$del2\n") 
	    if (substr($seqLoc[1],$it1,1) ne substr($seqLoc[2],$it2,1));
	$loc{"2",$it2}=$it1;
	++$it1; ++$it2;
    }

    $match="";
    $#seqTmp=$#seqLoc=0;	# slim-is-in
    return(1,"ok");
}				# end of sequenceAlign

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
	       $msgInLoc.="\n";
	       $msgInLoc=~s/\n\n+/\n/g;
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
    &open_file("$fhinLoc","$fileInLoc") ||
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
	      else { 
		  print $fhErrSbr "-*- WARN $sbrName missing file=$_,\n";}}
    }close($fhinLoc);
    $tmpFile=~s/^,*|,*$//g;$tmpChain=~s/^,*|,*$//g;
    return(1,"ok $sbrName",$tmpFile,$tmpChain);
}				# end of fileListRd

#===============================================================================
sub is_dssp {
    local ($fileInLoc) = @_ ;
    local ($fh,$Lis);
#--------------------------------------------------------------------------------
#   is_dssp                     checks whether or not file is in DSSP format
#       in:                     $file
#       out:                    1 if is dssp; 0 else
#--------------------------------------------------------------------------------
    return (0) if (! defined $fileInLoc || ! -e $fileInLoc);
    $fh="FHIN_CHECK_DSSP";&open_file("$fh","$fileInLoc");
    while ( <$fh> ) {
	if (/SECONDARY STRUCTURE DEFINITION BY THE PROGRAM DSSP/i){$Lis=1;}else{$Lis=0;}
	last; }close($fh);
    return $Lis;
}				# end of is_dssp

#===============================================================================
sub is_hssp {
    local ($fileInLoc) = @_ ;local ($fh,$Lis);
#--------------------------------------------------------------------------------
#   is_hssp                     checks whether or not file is in HSSP format
#       in:                     $file
#       out:                    1 if is hssp; 0 else
#--------------------------------------------------------------------------------
    return (0)                  if (! defined $fileInLoc || ! -e $fileInLoc) ;
    $fh="FHIN_CHECK_HSSP";
    &open_file("$fh", "$fileInLoc") || return(0);
    $Lis=0;
    while ( <$fh> ) {$Lis=1 if (/^HSSP/) ; 
		     last; }close($fh);
    return $Lis;
}				# end of is_hssp

#===============================================================================
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

