#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="compiles statistics about HTM lengths\n".
    "     \t input:  tab separated columns  with names 'id' 'seq' 'sec' (H HTM, L none)\n".
    "     \t output: stat\n".
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
#				version 0.1   	Apr,    	2001	       #
#------------------------------------------------------------------------------#
#

$[ =1 ;				# count from one

				# ------------------------------
				# defaults
%par=(
      'extOut',                 ".dat",
      'minLenHtm',              2, # technical hack: just the way the split is done
      'minLenNon',              1, # technical hack: just the way the split is done
      'lenBinHtm',              2, # binning for final output (e.g. for val=3 bins: 1-3,4-6,..)
      'lenBinNon',              3, # binning for final output (e.g. for val=3 bins: 1-3,4-6,..)
      'htmShortReport',	       17, # report all ids numbers for HTMs shorter than this
      'htmLongReport',	       32, # report all ids numbers for HTMs shorter than this
      '', "",			# 
      );
$aa2do="WY";
@aa2do=split(//,$aa2do);
$aa2do_grep=join("|",@aa2do);

@kwd=sort (keys %par);
$Ldebug=0;
$Lverb= 0;
$sep=   "\t";
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

    printf "%5s %-15s %-20s %-s\n","","bin",   "no value",   "bin length of HTM/non-htm (".$par{"lenBinHtm"}.",".$par{"lenBinNon"}.")";
    printf "%5s %-15s %-20s %-s\n","","seq",   "no value",   "do also stat on W and Y";

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
				# ------------------------------
				# read command line
$LdobinLen=0;
$LdoSeq=   0;
foreach $arg (@ARGV){
#    next if ($arg eq $ARGV[1]);
    if    ($arg=~/^fileOut=(.*)$/i)       { $fileOut=        $1;}
    elsif ($arg=~/^dirOut=(.*)$/i)        { $dirOut= $1;
					    $dirOut.="/"     if ($dirOut !~ /\/$/);}

    elsif ($arg=~/^de?bu?g$/)             { $Ldebug=         1;
					    $Lverb=          1;}
    elsif ($arg=~/^verb(ose)?$|^\-v$/)    { $Lverb=          1;}
    elsif ($arg=~/^silent$|^\-s$/)        { $Lverb=          0;}

    elsif ($arg=~/^bin/)                  { $LdobinLen=      1;}
    elsif ($arg=~/^seq/)                  { $LdoSeq=         1;}
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

if (! defined $fileOut){
    $tmp=$fileIn;
    $tmp=~s/^.*\///g;		# dir
    $tmp=~s/\..*$//g;		# extension
    if ($dirOut){
	$fileOut=$dirOut."Out-".$tmp;}
    else {
	$fileOut="Out-".$tmp;}
    $fileOut.=$par{"extOut"};
}

				# ------------------------------
				# (1) read file(s)
				# ------------------------------
$ctfile=0;
foreach $fileIn (@fileIn){
    ++$ctfile;
    if (! -e $fileIn){print "-*- WARN $scrName: no fileIn=$fileIn\n";
		      next;}
    print "--- $scrName: working on fileIn=$fileIn!\n";
#    printf "--- $scrName: working on %-25s %4d (%4.1f perc of job)\n",$fileIn,$ctfile,(100*$ctfile/$#fileIn);
    open($fhin,$fileIn) || die "*** $scrName ERROR opening fileIn=$fileIn!";
#    if (! $Lok){print "*** $scrName: failed to open fileIn=$fileIn\n";
#		next;}
				# ------------------------------
				# header
    $ctline=0;
    while (<$fhin>) {
	++$ctline;
	$_=~s/\n//g;
	next if ($_=~/^\#/);	# skip comments
				# names
	@tmp=split(/[\s\t]+/,$_);  
	foreach $it (1..$#tmp){
	    if    ($tmp[$it]=~/^id/)       { $ptr_id= $it;}
	    elsif ($tmp[$it]=~/^seq/)      { $ptr_seq=$it;}
	    elsif ($tmp[$it]=~/^(sec|htm)/){ $ptr_sec=$it;}
	}
	if (! defined $ptr_id){
	    print "-*- WARN missing id column in $fileIn\n";}
	if (! defined $ptr_seq){
	    print "-*- WARN missing 'seq' column in $fileIn\n";
	    exit;}
	if (! defined $ptr_sec){
	    print "-*- WARN missing 'sec' or 'htm' column in $fileIn\n";
	    exit;}
	last;}
				# ------------------------------
				# data
    $ct=0;
    while (<$fhin>) {
	++$ctline;
	$_=~s/\n//g;
	next if ($_=~/^\#/);	# skip comments
	@tmp=split(/[\s\t]+/,$_);  
	++$ct;
	if (! defined $ptr_id){
	    $id=$ct;}
	else {
	    $id=$tmp[$ptr_id];}
	if (defined $res{$id,"sec"} || defined $res{$id,"seq"}){
	    print "*** WARN strong: id=$id is repeated in line=$ctline\n";
	}
	else {
	    push(@id,$id);}

	$res{$id,"seq"}=$tmp[$ptr_seq] if (defined $ptr_seq);
	$res{$id,"sec"}=$tmp[$ptr_sec] if (defined $ptr_sec);
    }
    close($fhin);
}
				# --------------------------------------------------
				# (2) stat on HTM length
				# --------------------------------------------------
$nhtm_max=$lhtm_max=$nhtm_tot=$lhtm_tot=0;
$nnon_max=$lnon_max=$nnon_tot=$lnon_tot=0;
$#short=$#long=0;
foreach $id (@id){
    $sec=$res{$id,"sec"};
    $seq=$res{$id,"seq"};
    $sec=~s/\s|\t//g;
    $seq=~s/\s|\t//g;
				# ------------------------------
				# stat on helices
    @tmp=split(/[^HMT]+/,$sec);
				# filter
    $#tmp2=0;
    foreach $tmp (@tmp){
	next if (length($tmp)<$par{"minLenHtm"});
	push(@tmp2,$tmp);
    }
    @tmp=@tmp2;
    $res{$id,"nhtm"}=$#tmp;
				# ------------------------------
				# keep position
    $sec2=$sec;
    $lenseq=length($sec);
    foreach $ithtm (1..$#tmp){
	$htm=$tmp[$ithtm];
				# begins with it
	if    ($sec2=~/^$htm/){
	    $beg=$lenseq+1-length($sec2);
	    $sec2=~s/^$htm(.*)$/$1/;
	    $end=$lenseq-length($sec2);
	}
				# somewhere in the middle
	elsif ($sec2=~/^([^HM]+)$htm(.*)$/){
	    $sec2=~s/^([^HM]+)$htm(.*)$/$2/;
	    $end=$lenseq-length($sec2);
	    $beg=1+$end-length($htm);
	}
	else {
	    print "xx big problem no match ithtm=$ithtm, lenhtm=",length($htm),"!\n";
	    $tmp=$sec2;
	    $tmp=~s/^([^HM]+)[HM].*$/$1/;
	    print "xx htm ="," " x length($tmp) , "$htm\n";
	    print "xx sec2=$sec2\n";
	    die;
	    $sec2=~s/^([^HM+])$htm(.*)$/$2/;
	    $end=$lenseq-length($sec2);
	    $beg=1+$end-length($htm);
	}
	$res{$id,$ithtm,"beg"}=$beg;
	$res{$id,$ithtm,"end"}=$end;
#	print "xx htm=$htm\n";
#	print "xx seq=",substr($seq,$res{$id,$ithtm,"beg"},
#			       (1+$res{$id,$ithtm,"end"}-$res{$id,$ithtm,"beg"})),"\n";
    }
#    ($Lok,$msg,$tmp)=&myprt_strings(50,1,($seq,$sec));
#    print "$tmp\n";
#    die if ($id eq $id[3]);

				# stat on number of HTM
    $nhtm=$#tmp;
    if (! defined $stat{"nhtm",$nhtm}){
	$stat{"nhtm",$nhtm}=0;
	$nhtm_max=$nhtm         if ($nhtm > $nhtm_max);}
    ++$stat{"nhtm",$nhtm};
    $nhtm_tot+=$nhtm;
				# length of HTM
    $#tmp2=0;
    foreach $ithtm (1..$#tmp){
	$htm=$tmp[$ithtm];
	$len=length($htm);
	if ($len < $par{"minLenHtm"}){
	    print "*** ERROR for id=$id segment=$ithtm, serious problem HTM len=$len, too short!\n"; # 
	    exit;}
	if (! defined $stat{"lhtm",$len}){
	    $stat{"lhtm",$len}=0;
	    $lhtm_max=$len      if ($len > $lhtm_max);}
	if ($len < $par{"htmShortReport"}){
	    push(@short,
		 $id."\t".$len."\t".$ithtm.
		 "\t".$res{$id,$ithtm,"beg"}."-".$res{$id,$ithtm,"end"}.
		 "\t".substr($seq,$res{$id,$ithtm,"beg"},
			     (1+$res{$id,$ithtm,"end"}-$res{$id,$ithtm,"beg"})));
	}
	if ($len > $par{"htmLongReport"}){
	    push(@long,
		 $id."\t".$len."\t".$ithtm.
		 "\t".$res{$id,$ithtm,"beg"}."-".$res{$id,$ithtm,"end"}.
		 "\t".substr($seq,$res{$id,$ithtm,"beg"},
			     (1+$res{$id,$ithtm,"end"}-$res{$id,$ithtm,"beg"})));
	}
	++$stat{"lhtm",$len};
	$lhtm_tot+=$len;
	push(@tmp2,$len);
    }
    if ($Ldebug){
	print "--- $id nhtm=$nhtm, nhtm_tot=$nhtm_tot,len=".join(',',sort bynumber_high2low(@tmp2)),"\n";
	print "--- $id htm=",join('|',@tmp,"\n");
    }

				# ------------------------------
				# stat on non-helix regions
    @tmp=split(/[HMT]+/,$sec);

				# filter
    $#tmp2=0;
    foreach $tmp (@tmp){
	next if (length($tmp)<$par{"minLenNon"});
	push(@tmp2,$tmp);
    }
    @tmp=@tmp2;
				# stat on number of NON
    $nnon=$#tmp;
    if (! defined $stat{"nnon",$nnon}){
	$stat{"nnon",$nnon}=0;
	$nnon_max=$nnon         if ($nnon > $nnon_max);}
    ++$stat{"nnon",$nnon};
    $nnon_tot+=$nnon;
				# length of NON
    $cttmp=0;
    $#tmp2=0;
    foreach $tmp (@tmp){
	$len=length($tmp);
	++$cttmp;
	if ($len < $par{"minLenNon"}){
	    print "*** ERROR for id=$id segment=$cttmp, serious problem NON len=$len, too short!\n"; # 
	    exit;}
	if (! defined $stat{"lnon",$len}){
	    $stat{"lnon",$len}=0;
	    $lnon_max=$len      if ($len > $lnon_max);}
	++$stat{"lnon",$len};
	$lnon_tot+=$len;
	push(@tmp2,$len);
    }
    if ($Ldebug){
	print "--- $id nnon=$nnon, nnon_tot=$nnon_tot,len=".join(',',sort bynumber_high2low(@tmp2)),"\n";
	print "--- $id non=",join('|',@tmp,"\n");}
}
				# ------------------------------
				# (3a) write output for Num HTM
				# ------------------------------
$tmpwrth= sprintf("# NPROT: %5d\n",$#id);
$tmpwrth.=sprintf("# NHTM : %5d  number of residues in HTM    : %6d\n",$nhtm_tot,$lhtm_tot);
$tmpwrth.=sprintf("# Nnon : %5d  number of residues not in HTM: %6d\n",$nnon_tot,$lnon_tot);

$fileOutNhtm=$fileOut; $fileOutNhtm=~s/$par{"extOut"}/nhtm$par{"extOut"}/;
open($fhout,">".$fileOutNhtm) || die "*** $scrName ERROR creating fileOutNhtm=$fileOutNhtm";
$tmpwrt= $tmpwrth;
$tmpwrt.=
    "nhtm".$sep."Number of proteins".$sep."Cumulative number of proteins".
    $sep."Percentage of proteins".$sep."Cumulative percentage of proteins"."\n";
foreach $nhtmx (1..$nhtm_max){
    $nhtm=$nhtm_max-$nhtmx +1;
    next if (! defined $stat{"nhtm",$nhtm});
    $sum+=$stat{"nhtm",$nhtm};
    $tmpwrt.=sprintf("%5d$sep%5d$sep%5d$sep%6.1f$sep%6.1f\n",
		     $nhtm,$stat{"nhtm",$nhtm},$sum,
		     (100*$stat{"nhtm",$nhtm}/$#id),(100*$sum/$#id));
}
print $tmpwrt                   if ($Ldebug);
print $fhout
    $tmpwrt;
close($fhout);

				# ------------------------------
				# (3b) write output for Num NON
				# ------------------------------
$tmpwrth= sprintf("# NPROT: %5d\n",$#id);
$tmpwrth.=sprintf("# NHTM : %5d  number of residues in HTM    : %6d\n",$nhtm_tot,$lhtm_tot);
$tmpwrth.=sprintf("# Nnon : %5d  number of residues not in HTM: %6d\n",$nnon_tot,$lnon_tot);

$fileOutNnon=$fileOut; $fileOutNnon=~s/$par{"extOut"}/nnon$par{"extOut"}/;
open($fhout,">".$fileOutNnon) || die "*** $scrName ERROR creating fileOutNnon=$fileOutNnon";
$tmpwrt= $tmpwrth;
$tmpwrt.=
    "nnon".$sep."Number of proteins".$sep."Cumulative number of proteins".
    $sep."Percentage of proteins".$sep."Cumulative percentage of proteins"."\n";
$sum=0;
foreach $nnonx (1..$nnon_max){
    $nnon=$nnon_max-$nnonx +1;
    next if (! defined $stat{"nnon",$nnon});
    $sum+=$stat{"nnon",$nnon};
    $tmpwrt.=sprintf("%5d$sep%5d$sep%5d$sep%6.1f$sep%6.1f\n",
		     $nnon,$stat{"nnon",$nnon},$sum,
		     (100*$stat{"nnon",$nnon}/$#id),(100*$sum/$#id));
}
print $tmpwrt                   if ($Ldebug);
print $fhout
    $tmpwrt;
close($fhout);
				# ------------------------------
				# (3c) write output for Len HTM
				# ------------------------------
$tmpwrth= sprintf("# NPROT: %5d\n",$#id);
$tmpwrth.=sprintf("# NHTM : %5d  number of residues in HTM    : %6d\n",$nhtm_tot,$lhtm_tot);
$tmpwrth.=sprintf("# Nnon : %5d  number of residues not in HTM: %6d\n",$nnon_tot,$lnon_tot);

if ($LdobinLen){
    $fileOutLhtm=$fileOut; $fileOutLhtm=~s/$par{"extOut"}/lhtmbin$par{"extOut"}/;}
else {
    $fileOutLhtm=$fileOut; $fileOutLhtm=~s/$par{"extOut"}/lhtm$par{"extOut"}/;}

open($fhout,">".$fileOutLhtm) || die "*** $scrName ERROR creating fileOutLhtm=$fileOutLhtm";
$tmpwrt= $tmpwrth;
$tmpwrt.=
    "Length htm".$sep."Number of HTM".$sep."Cumulative number of HTM".
    $sep."Percentage of HTM".$sep."Cumulative percentage of HTM"."\n";
$sum=0;
$lenbin=1;
$lenbin=$par{"lenBinHtm"}       if ($LdobinLen);
undef %tmp;
foreach $lhtmx (1..$lhtm_max){
    $lhtm=$lhtm_max-$lhtmx +1;
				# for bin
    next if (! defined $stat{"lhtm",$lhtm} || ! $stat{"lhtm",$lhtm});
    next if (defined $tmp{$lhtm});
    $sumnum=$sumper=0;
    $ctred=0;
    $lhtm2=$lhtm+1;
    while ($ctred <= $lenbin){
	++$ctred;
	--$lhtm2;
	next if (! defined $stat{"lhtm",$lhtm2} || ! $stat{"lhtm",$lhtm2});
	$sum+=   $stat{"lhtm",$lhtm2};
	$sumnum+=$stat{"lhtm",$lhtm2};
	$sumper+=100*$stat{"lhtm",$lhtm2}/$nhtm_tot;
	$tmp{$lhtm2}=1;
    }
    $tmpwrt.=sprintf("%5d$sep%5d$sep%5d$sep%6.1f$sep%6.1f\n",
		     $lhtm,$sumnum,$sum,$sumper,(100*$sum/$nhtm_tot));
}
print $tmpwrt                   if ($Ldebug);
print $fhout
    $tmpwrt;
close($fhout);
				# ------------------------------
				# (3d) write output for Len NON
				# ------------------------------
$tmpwrth= sprintf("# NPROT: %5d\n",$#id);
$tmpwrth.=sprintf("# NHTM : %5d  number of residues in HTM    : %6d\n",$nhtm_tot,$lhtm_tot);
$tmpwrth.=sprintf("# Nnon : %5d  number of residues not in HTM: %6d\n",$nnon_tot,$lnon_tot);

if ($LdobinLen){
    $fileOutLnon=$fileOut; $fileOutLnon=~s/$par{"extOut"}/lnonbin$par{"extOut"}/;}
else{
    $fileOutLnon=$fileOut; $fileOutLnon=~s/$par{"extOut"}/lnon$par{"extOut"}/;}

open($fhout,">".$fileOutLnon) || die "*** $scrName ERROR creating fileOutLnon=$fileOutLnon";
$tmpwrt= $tmpwrth;
$tmpwrt.=
    "Length non".$sep."Number of NON".$sep."Cumulative number of NON".
    $sep."Percentage of NON".$sep."Cumulative percentage of NON"."\n";
$sum=0;
$lenbin=1;
$lenbin=$par{"lenBinNon"}       if ($LdobinLen);
undef %tmp;
foreach $lnonx (1..$lnon_max){
#    $lnon=$lnon_max-$lnonx +1;
    $lnon=$lnonx;
				# for bin
    next if (! defined $stat{"lnon",$lnon} || ! $stat{"lnon",$lnon});
    next if (defined $tmp{$lnon});
    $sumnum=$sumper=0;
    $ctred=0;
    $lnon2=$lnon+1;
    while ($ctred <= $lenbin){
	++$ctred;
	--$lnon2;
	next if (! defined $stat{"lnon",$lnon2} || ! $stat{"lnon",$lnon2});
	$sum+=   $stat{"lnon",$lnon2};
	$sumnum+=$stat{"lnon",$lnon2};
	$sumper+=100*$stat{"lnon",$lnon2}/$nnon_tot;
	$tmp{$lnon2}=1;
    }
    $tmpwrt.=sprintf("%5d$sep%5d$sep%5d$sep%6.1f$sep%6.1f\n",
		     $lnon,$sumnum,$sum,$sumper,(100*$sum/$nnon_tot));
}
print $tmpwrt                   if ($Ldebug);
print $fhout
    $tmpwrt;
close($fhout);

				# --------------------------------------------------
				# (4) stat on HTM residue statistics
				# --------------------------------------------------
if ($LdoSeq){
    ($Lok,$msg)=
	&statSeq();		if (! $Lok){ print "*** ERROR $scrName: after statSeq msg=\n$msg";
					     exit;}}
#open($fhout,">".$fileOut) || die "*** $scrName ERROR creating fileOut=$fileOut";
#close($fhout);

				# ------------------------------
				# (5) report short ones
if ($#short >= 1){
    $fileOutShort=$fileOut; $fileOutShort=~s/$par{"extOut"}/short$par{"extOut"}/;
    open($fhout,">".$fileOutShort) || die "*** $scrName ERROR creating fileOutShort=$fileOutShort";
    print $fhout 
	"# helices shorter than ",$par{"htmShortReport"}," residues\n";
    print $fhout
	"id"."\t"."lenHTM"."\t"."# HTM"."\t"."beg-end"."\t"."sequence"."\n";
    foreach $short (@short){
	print $fhout
	    $short,"\n";
    }
    close($fhout);}


if ($#long >= 1){
    $fileOutLong=$fileOut; $fileOutLong=~s/$par{"extOut"}/long$par{"extOut"}/;
    open($fhout,">".$fileOutLong) || die "*** $scrName ERROR creating fileOutLong=$fileOutLong";
    print $fhout 
	"# helices longer than ",$par{"htmLongReport"}," residues\n";
    print $fhout
	"id"."\t"."lenHTM"."\t"."# HTM"."\t"."beg-end"."\t"."sequence"."\n";
    foreach $long (@long){
	print $fhout
	    $long,"\n";
    }
    close($fhout);}


foreach $filetmp ($fileOutNhtm,$fileOutLhtm,$fileOutNnon,$fileOutLnon,
		  $fileOutShort,$fileOutLong,$fileOutShtm){
    print "--- output in $filetmp\n" if (defined $filetmp && -e $filetmp);
}
exit;


#===============================================================================
sub statSeq {
#    local($fileInLoc,$fhErrSbr) = @_ ;
    local($sbrName,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   statSeq                       
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."statSeq";

    $seqhtm="";
    $seqnon="";
    foreach $id (@id){
	$sec=$res{$id,"sec"};
	$sec=~s/\s|\t//g;
	$seq=$res{$id,"seq"};
	$seq=~s/\s|\t//g;
	if (length($seq) != length($sec)){
	    print "*** ERROR id=$id, seq and structure not same length!\n";
	    print "seq=$seq\n";
	    print "sec=$sec\n";
	    exit;}
	@seq=split(//,$seq);
	@sec=split(//,$sec);
	foreach $itres (1..$#seq){
				# not HTM
	    if ($sec[$itres] !~/^[HTM]$/){
		$seqnon.=$seq[$itres];
		next;}
	    $seqhtm.=$seq[$itres];
				# not wanted
	    next if ($seq[$itres] !~/$aa2do_grep/);

				# general statistic
	    if (! defined $stat{$seq[$itres]}){
		$stat{$seq[$itres]}=0;}
	    ++$stat{$seq[$itres]};
				# position specific
	    $Lok=0;
	    foreach $it (1,2,3,4){
		if (defined $sec[$itres-$it] && $sec[$itres-$it] !~ /^[HTM]$/){
		    ++$stat{$seq[$itres],($it-1)};
		    $Lok=1;
		    last;}}
	    ++$stat{$seq[$itres],"cen"} if (! $Lok);
	}
    
    }

				# overall statistics
    foreach $aa (@aa2do){
	$tmp=$seqhtm;
	$tmp=~s/[^$aa]//g;
	$stat{"htm",$aa}=length($tmp);
	$tmp=$seqnon;
	$tmp=~s/[^$aa]//g;
	$stat{"non",$aa}=length($tmp);
	$stat{"all",$aa}=$stat{"htm",$aa}+$stat{"non",$aa};
    }
    $stat{"htm","res"}=length($seqhtm);
    $stat{"non","res"}=length($seqnon);
    $stat{"all","res"}=length($seqnon)+length($seqhtm);
    foreach $aa (@aa2do){
	$stat{$aa,"phtm"}=100*($stat{"htm",$aa}/$stat{"htm","res"});
	$stat{$aa,"pnon"}=100*($stat{"non",$aa}/$stat{"non","res"});
	$stat{$aa,"pall"}=100*($stat{"htm",$aa}/$stat{"all","res"});
    }
				# ------------------------------
				# (4a) write output for seq stat
				# ------------------------------
    $fileOutShtm=$fileOut; $fileOutShtm=~s/$par{"extOut"}/shtm$par{"extOut"}/;

    open($fhout,">".$fileOutShtm) || die "*** $scrName ERROR creating fileOutShtm=$fileOutShtm";
    $tmpwrt= "";
    foreach $aa (@aa2do){
	$tmpwrt.= 
	    "# ".$aa." nhtm=".$stat{"htm",$aa}." nnon=".$stat{"non",$aa}."\n";
	$tmpwrt.= 
	    "# ".$aa." phtm=".int(100*$stat{"htm",$aa}/$stat{"all",$aa}).
		" pnon=".int(100*$stat{"non",$aa}/$stat{"all",$aa})."\n";
    }
    $tmpwrt.="Position htm";
    foreach $aa (@aa2do){
	$tmpwrt.=
	    $sep."N".$aa.$sep."P".$aa."_of_$aa".$sep."P".$aa."_htm".$sep."P".$aa."_tot".
		$sep."DPhtm".$aa.$sep."DPnon".$aa.$sep."DPall".$aa;
    }
    $tmpwrt.="\n";


    $sum=0;
    foreach $pos ("cen",0,1,2,3){
	$tmpwrt.=$pos;

	foreach $aa (@aa2do){
	    $num=    0;
	    $perc=   0;
	    $perctot=0;
	    $perchtm=0;
	    if (defined $stat{$aa,$pos}){
		$perctot=(100*$stat{$aa,$pos}/$stat{"all","res"});
		$perchtm=(100*$stat{$aa,$pos}/$stat{"htm",$aa});
		$perc=   (100*$stat{$aa,$pos}/$stat{"all",$aa});
		$num=    $stat{$aa,$pos};}
	    
	    $tmpwrt.=sprintf("$sep%5d$sep%6.1f$sep%6.1f$sep%6.1f$sep%6.1f$sep%6.1f$sep%6.1f",
			     $num,$perc,$perchtm,$perctot,
			     ($perc-$stat{$aa,"phtm"}),($perc-$stat{$aa,"pnon"}),($perc-$stat{$aa,"pall"}));
	}
	$tmpwrt.="\n";
    }
    print $tmpwrt                   if ($Ldebug);
    print $fhout
	$tmpwrt;
    close($fhout);

    return(1,"ok $sbrName");
}				# end of statSeq

#===============================================================================
sub bynumber { 
#-------------------------------------------------------------------------------
#   bynumber                    function sorting list by number
#-------------------------------------------------------------------------------
    $a<=>$b; 
}				# end of bynumber

#===============================================================================
sub bynumber_high2low { 
#-------------------------------------------------------------------------------
#   bynumber_high2low           function sorting list by number (start with high)
#-------------------------------------------------------------------------------
    $b<=>$a; 
}				# end of bynumber_high2low

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
sub myprt_npoints {
    local ($npoints,$num_in) = @_; 
    local ($num,$beg,$ctprev,$ct,$numprev, $tmp,$tmp1,$tmp2, $out, $ct, $i);
    $[=1;
#-------------------------------------------------------------------------------
#   myprt_npoints               writes line with N dots of the form '....,....1....,....2' 
#       in:                     $number_of_points_per_line,$number_to_end_with
#       out:                    $line
#------------------------------------------------------------------------------
    $npoints=10*(1+int($npoints/10))
	if ( int($npoints/10)!=($npoints/10) );

    $ct=int(($num_in-1)/$npoints);
    $beg=$ct*$npoints; $num=$beg;
    for ($i=1;$i<=($npoints/10);++$i) {
	$numprev=$num; $num=$beg+($i*10);
	$ctprev=$numprev/10;
	if    ( $i==1 )                        {
	    $tmp=substr($num,1,1); $out="....,....".$tmp; }
	elsif ( $ctprev<10 )                   {
	    $tmp=substr($num,1,1); $out.="....,....".$tmp; }
	elsif ($i==($npoints/10) && $ctprev>=9){
	    $tmp1=substr($ctprev,2);$tmp2="." x (4-length($tmp1));
	    $out.=$tmp1.$tmp2.",....".substr(($num/10),1); }
	else                                   {
	    $tmp1=substr($ctprev,2);$tmp2="." x (4-length($tmp1));
	    $out.=$tmp1.$tmp2.",....".substr($num,1,1); }
	last if ($num>$num_in);
    }
    $myprt_npoints=$out;
    return ($out);
}				# end of myprt_npoints

#===============================================================================
sub myprt_strings {
    local($nperlineLoc,$LnumLoc,@tmpLoc) = @_ ;
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   myprt_strings                       
#       in:                     $nperlineLoc :  number of points per line
#       in:                     $Lnum :         write numbers if 1
#       in:                     @tmpLoc=($string1,$string2): strings
#                                               note: name1=string1,name2=string2
#                               e.g.      ....,....1
#                                   name1 ABCDAAAAAA
#                                   name2 KKKKKKKKKK
#                                         ....,....2
#                                   name1 YYYYYY
#                                   name2 KKKKKK
#                               
#                               
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."myprt_strings";
    $fhinLoc="FHIN_"."myprt_strings";$fhoutLoc="FHOUT_"."myprt_strings";
				# check arguments
    return(&errSbr("not def nperlineLoc!"))      if (! defined $nperlineLoc);
    return(&errSbr("not def LnumLoc!"))          if (! defined $LnumLoc);
    return(&errSbr("not def ARRAYtmpLoc!"))      if (! defined @tmpLoc);
    return(&errSbr("empty ARRAYtmpLoc!"))        if (! $#tmpLoc);
#    return(&errSbr("not def !"))          if (! defined $);
    
    $#tmpValLoc=0;
    $#tmpKwdLoc=0;
				# any names given?
    foreach $tmp (@tmpLoc){
	if ($tmp=~/^(.+)=(.+)$/){
	    $tmp_kwd=$1;
	    $tmp_val=$2;
	    push(@tmpValLoc,$tmp_val);
	    push(@tmpKwdLoc,$tmp_kwd);}
	else {
	    push(@tmpValLoc,$tmp);
	}}
    if (! $#tmpKwdLoc){
	foreach $it (1..$#tmpLoc){
	    push(@tmpKwdLoc,sprintf("%3d",$it));
	}}
				# now do it 
    $tmp_len=   length($tmpValLoc[1]);
    $tmp_numrow=int($tmp_len/$nperlineLoc)+1;
    $tmp_wrt=   "";
    foreach $ittmp_block (1..$tmp_numrow){
	$tmp_beg=($ittmp_block-1)*$nperlineLoc+1;
	$tmp_end= $ittmp_block   *$nperlineLoc;
	$tmp_end= $tmp_len      if ($tmp_end > $tmp_len);
				# numbers
	if ($LnumLoc){
	    $tmp_wrt.=sprintf("%-5s: "," ");
	    $tmp_wrt.=&myprt_npoints($nperlineLoc,$tmp_end)."\n";
	}
	    
				# data
	foreach $ittmp_data (1..$#tmpValLoc){
	    $tmp_wrt.=sprintf("%-5s: ",$tmpKwdLoc[$ittmp_data]);
	    $tmp_wrt.=substr($tmpValLoc[$ittmp_data],$tmp_beg,(1+$tmp_end-$tmp_beg))."\n";
	}
				# finish if ended
	last if ($tmp_end == $tmp_len);
    }
				# slim-is-in
    $#tmpKwdLoc=$#tmpValLoc=0;
    return(1,"ok $sbrName",$tmp_wrt);
}				# end of myprt_strings


