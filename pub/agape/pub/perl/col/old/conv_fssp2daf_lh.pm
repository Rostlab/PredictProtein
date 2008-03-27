###############################################################################
#
# (c) L. Holm, 29 October 1996
#
# daft.perl 1ppt.fssp > 1ppt.daft
#
# read ranges from fsspfile, sequences from hssp
# print all in uppercase, gaps on one side only, i.e.,
# ABC....EDF....IJK
# ...KGFFEDFKFRT...
#
###############################################################################

package conv_fssp2daf_lh;

#===============================================================================
sub conv_fssp2daf_lh {
#-------------------------------------------------------------------------------
#   conv_fssp2daf_lh            package version of script
#-------------------------------------------------------------------------------
    $|=1;
    $[=1;
    ($fsspfile,$DSSPDIR,@tmp)=@_;
    $gap='.';
    if (! defined $DSSPDIR){
#$location='EBI';
	$location='EMBL-HD';
	if($location eq 'EBI')        { $DSSPDIR='/data/research/dssp/';}
	elsif($location eq 'EMBL-HD') { $DSSPDIR='/data/dssp/';}
	else { die "$0 is not installed at this site\n"; }}
    die ("$0 NO DSSP found ($DSSPDIR)! ") if (! -d $DSSPDIR);
				# ------------------------------
				# other arguments given?
    foreach $tmp (@tmp) {
	if ($tmp=~/^fileOut=(.*)/){$fileOut=$1;}}
    if (defined $fileOut){ $Lerr=0;
			   $fhout="FHOUT_CONV_FSSP2DAF"; 
			   open("$fhout",">$fileOut") ||  ( do { $Lerr=1; } ) ;
			   $fhout="STDOUT"; }
    else                 { $fhout="STDOUT"; }
    
    
# daft header
    print $fhout '# DAF (dirty alignment format for exchange with Aqua)',"\n";
    print $fhout '# SOURCE ',"$fsspfile\n";
    print $fhout '# ALIGNMENTS',"\n";
    print $fhout '# idSeq idStr lenSeq lenStr zDali rmsDali lenAli seq str',"\n";

# slurp in fssp file
    open(IN,"<$fsspfile") || die "$fsspfile not found\n"; (@lines)=<IN>; close(IN);

#extract cd1,nres1
    foreach(@lines) { 
	if ($_=~/^SEQLENGTH\s+(\d+)/) { $lenSeq=$1; last; } }
    $_=$fsspfile; 
    ($idSeq)=/(\w+)\.fssp/; 
    $cd=substr($idSeq,$[,4);
    if(length($idSeq) > 4) { $chain=substr($idSeq,$[+4,1); } else { $chain=' '; }
    $dsspfile=$DSSPDIR.$cd.'.dssp';
    ($seq1)=&slurp_dssp($dsspfile,$chain);
    if(!$seq1) { 
	warn "$dsspfile not found -- no sequence! (printing $lenSeq X's)\n"; 
	foreach(1..$lenSeq) { $seq1.='X'; } # 
    }
    (@seq1)=split(//,$seq1);
    
# remember z-scores etc.
    $flag=0;
    foreach(@lines) {
	if ($flag) {
	    next if($_=~/^  NR/); 
	    last if($_!~/\w/);
	    ($i,$idStr,$zDali,$rmsDali,$lenAli,$lenStr)=
		/(\d+):\s+[\w\-]+\s+([\w\-]+)\s*(\d+\.\d)\s*(\d+\.\d)\s+(\d+)\s+(\d+)/;
	    # print $fhout "$_ gave $i,$idStr,$zDali,$rmsDali,$lenAli,$lenStr\n";
	    $idStr=~s/\-//;
	    $idStr[$i]=  $idStr;
	    $zDali[$i]=  $zDali;
	    $rmsDali[$i]=$rmsDali;
	    $lenAli[$i]= $lenAli;
	    $lenStr[$i]= $lenStr; }
	elsif ($_=~/^\#\# SUMMARY/) { 
	    $flag=1;  } }
	
# parse equivalences block, fetch sequence2 and print $fhout out alignment
    $flag=0; 
    $iold=0;
    foreach(@lines) { 
	if($flag) {
	    last if($_=~/^\#\# /);
	    ##next if(!/\:/); # to print last match too
#   1: 1ppt   1ppt       1 -  36 <=>    1 -  36   (GLY     1 - TYR    36 <=> GLY     1 - TYR    36)                          
	    ($i,$cd2,$from1,$to1,$from2,$to2)=
		/^\s+(\d+):\s+[\w\-]+\s+([\w\-]+)\s+(\d+) -\s+(\d+) <=>\s+(\d+) -\s+(\d+)/;
	    $_=$cd2; 
	    if($_=~/^(\w+)\-(\w)/) { $cd=$1; $chain=$2; $cd2=$cd.$chain; }
	    else { ($cd)=/^(\w+)/; $chain=' '; $cd2=$cd; }
		# print "got $i,$cd2,$from1,$to1,$from2,$to2,$cd,$chain\n";
	    if($i!=$iold) { # fetch sequence2, update iold
			# print old buffer; append C-terminus
		if($iold>0) { 
		    foreach ($ires+1..$lenSeq) { $a.=$seq1[$_]; $b.=$gap; } 
		    foreach ($jres+1..$lenStr[$iold]) { $b.=$seq2[$_]; $a.=$gap; } 
		    print $fhout 
			"$idSeq $idStr[$iold] $lenSeq $lenStr[$iold] $zDali[$iold] ".
			    "$rmsDali[$iold] $lenAli[$iold] $a $b\n"; 
#				print $fhout "$idSeq $idStr[$iold] $lenSeq $lenStr[$iold] $zDali[$iold] $rmsDali[$iold] $lenAli[$iold]\n$a\n$b\n"; 
		}
		if($i) { # not on last line
		    $iold=$i;
		    $ires=0; # 
		    $jres=0; # 
		    $a=''; # 
		    $b=''; # 
		    $dsspfile=$DSSPDIR.$cd.'.dssp';
		    ($seq2)=&slurp_dssp($dsspfile,$chain);
		    if(!$seq2) {
			warn "$dsspfile ($cd) not found -- no sequence! (printing $lenStr[$iold] X's)\n"; 
			foreach (1..$lenStr[$iold]) { $seq2.='X'; }
		    } elsif($lenStr[$iold] != length($seq2)) {
			warn "lenStr mismatch $lenStr[$iold] ne ",length($seq2)," $iold  $idSeq $idStr[$iold] $lenSeq $lenStr[$iold] $zDali[$iold] $rmsDali[$iold] $lenAli[$iold] \n$seq2\n";
			$lenStr[$iold]=length($seq2);	
		    }
		    (@seq2)=split(//,$seq2);
		}
	    }
				# append alignment upto to1,to2
	    foreach ($ires+1..$from1-1) { $a.=$seq1[$_]; $b.=$gap; }
	    foreach ($jres+1..$from2-1) { $b.=$seq2[$_]; $a.=$gap; }
				# append alignment in block
	    foreach ($from1..$to1) { $a.=$seq1[$_]; }
	    foreach ($from2..$to2) { $b.=$seq2[$_]; }
				# update position
	    $ires=$to1;
	    $jres=$to2;
	}
	elsif ($_=~/^\#\# EQUIVALENCES/) { $flag=1; }
    }
    return(1,"ok $sbrName");
}				# end of conv_fssp2daf_lh

###############################################################################
sub slurp_dssp {
    local ($dsspfile,$chain)=@_;
    local ($ipos,@resno,@chn,@seq,@str,@acc,$ires,$nres1);
    if(!$chain) { $chain=' '; } # select chain!
    open(IN,$dsspfile); 
				# header block
    while(<IN>) { 
	last if ($_=~/^  \#  RESIDUE/); } 
    while(<IN>) {
	next if ($_=~/\!/);
	($ipos,$resno,$chn,$seq,$str,$acc,$x,$y,$z)=
	    /^\s+(\d+)\s+(\S+) (.) (.)  (.).{18}\s*(\d+).*\s+([\-\d\.]+)\s*([\-\d\.]+)\s*([\-\d\.]+)\s*$/;
	next if ($chn ne $chain); $ires++;
	$ires[$ipos]=$ires;
	$resno[$ires]=$resno; $chn[$ires]=$chn; $seq[$ires]=$seq;
	$str[$ires]=$str; $acc[$ires]=$acc; $var[$ires]=$var;
	push(@xyz,$x,$y,$z);
				# print "$ires $seq[$ires] $resno[$ires]\n";
	$nres1=$ires;
    }
    $templseq=join('',@seq);
    $templseq=~tr/[a-z]/C/; # disulphides->Cys
#	print "slurp_dssp returns $dsspfile $chain\n$templseq\n@xyz\n";
    return($templseq);
}

###############################################################################

1;

