#!/usr/bin/perl
##!/usr/bin/perl -w
##!/usr/sbin/perl
##!/bin/env perl
##!/usr/pub/bin/perl
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
$|=1;
$[=1;
($fsspfile,$DSSPDIR)=@ARGV;

$par{"dirPdbSplit"}="/data/derived/big/pdbSplit/";
$par{"extFasta"}=   ".f";

$gap='.';
if (! defined $DSSPDIR){
#$location='EBI';
    $location='EMBL-HD';
    $location='CUBIC';
    if   ($location eq 'EBI')     { $DSSPDIR='/data/research/dssp/';}
    elsif($location eq 'EMBL-HD') { $DSSPDIR='/data/dssp/';}
    elsif($location eq 'CUBIC')   { $DSSPDIR='/data/dssp/';}
    else { die "$0 is not installed at this site\n"; }}
die '$0 NO DSSP found ! ' if (! -d $DSSPDIR);

# daft header
print '# DAF (dirty alignment format for exchange with Aqua)',"\n";
print '# SOURCE ',"$fsspfile\n";
print '# ALIGNMENTS',"\n";
print '# idSeq idStr lenSeq lenStr zDali rmsDali lenAli seq str',"\n";

# slurp in fssp file
open(IN,"<$fsspfile") || die "$fsspfile not found\n"; (@lines)=<IN>; close(IN);

#extract cd1,nres1
foreach(@lines) { if(/^SEQLENGTH\s+(\d+)/) { $lenSeq=$1; last; } }
$_=$fsspfile; 
($idSeq)=/(\w+)\.fssp/; 
$cd=substr($idSeq,$[,4);
$chain=' ';
$chain=substr($idSeq,$[+4,1)
    if(length($idSeq) > 4);
$dsspfile=$DSSPDIR.$cd.'.dssp';

($seq1)=&slurp_dssp($dsspfile,$chain);

if(!$seq1) { 
	warn "$dsspfile not found -- no sequence! (printing $lenSeq X's)\n"; 
	foreach(1..$lenSeq) { $seq1.='X'; }
}
(@seq1)=split(//,$seq1);

# remember z-scores etc.
$flag=0;
foreach(@lines) {
	if($flag) {
		next if(/^  NR/); 
		last if(!/\w/);
		($i,$idStr,$zDali,$rmsDali,$lenAli,$lenStr)=
			/(\d+):\s+[\w\-]+\s+([\w\-]+)\s*(\d+\.\d)\s*(\d+\.\d)\s+(\d+)\s+(\d+)/;
		# print "$_ gave $i,$idStr,$zDali,$rmsDali,$lenAli,$lenStr\n";
		$idStr=~s/\-//;
		$idStr[$i]=$idStr;
		$zDali[$i]=$zDali;
		$rmsDali[$i]=$rmsDali;
		$lenAli[$i]=$lenAli;
		$lenStr[$i]=$lenStr;
	} elsif (/^## SUMMARY/) { $flag=1; }
}

# parse equivalences block, fetch sequence2 and print out alignment
$flag=0; 
$iold=0;
foreach(@lines) { 
	if($flag) {
		last if(/^## /);
		##next if(!/\:/); # to print last match too
#   1: 1ppt   1ppt       1 -  36 <=>    1 -  36   (GLY     1 - TYR    36 <=> GLY     1 - TYR    36)                          
		($i,$cd2,$from1,$to1,$from2,$to2)=
/^\s+(\d+):\s+[\w\-]+\s+([\w\-]+)\s+(\d+) -\s+(\d+) <=>\s+(\d+) -\s+(\d+)/;
		$_=$cd2; 
		if(/^(\w+)\-(\w)/) { $cd=$1; $chain=$2; $cd2=$cd.$chain; }
		else { ($cd)=/^(\w+)/; $chain=' '; $cd2=$cd; }
		# print "got $i,$cd2,$from1,$to1,$from2,$to2,$cd,$chain\n";
		if($i!=$iold) { # fetch sequence2, update iold
			# print old buffer; append C-terminus
			if($iold>0) { 
				foreach ($ires+1..$lenSeq) { $a.=$seq1[$_]; $b.=$gap; } 
				foreach ($jres+1..$lenStr[$iold]) { $b.=$seq2[$_]; $a.=$gap; } 
				print "$idSeq $idStr[$iold] $lenSeq $lenStr[$iold] $zDali[$iold] $rmsDali[$iold] $lenAli[$iold] $a $b\n"; 
#				print "$idSeq $idStr[$iold] $lenSeq $lenStr[$iold] $zDali[$iold] $rmsDali[$iold] $lenAli[$iold]\n$a\n$b\n"; 
			}
			if($i) { # not on last line
				$iold=$i;
				$ires=0;
				$jres=0;
				$a='';
				$b='';
				$id2=$cd; 
				if (length($id2)>4){
				    $id2=  substr($cd,1,4);
				    $chain=substr($cd,5,1);}
				else {
				    $chain=' ';}
				$dsspfile=$DSSPDIR.$id2.'.dssp';
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
	elsif (/^## EQUIVALENCES/) { $flag=1; }
}


#===============================================================================
sub fastaRdGuide {
    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   fastaRdGuide                reads first sequence in list of FASTA format
#       in:                     $fileInLoc,$fhErrSbr
#       out:                    0|1,$id,$seq
#       err:                    ok=(1,id,seq), err=(0,'msg',)
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."fastaRdGuide";$fhinLoc="FHIN"."$sbrName";
    
    $Lok=open($fhinLoc,$fileInLoc);
    return(0,"*** ERROR $sbrName: old '$fileInLoc' not opened\n"," ") if (! $Lok);
    $ct=0;$seq="";
    while (<$fhinLoc>) {
	$_=~s/\n//g;
	if ($_=~/^\s*>\s*(.+)$/){
	    ++$ct;
	    last if ($ct>1);
	    $id=$1;$id=~s/[\s\t]+/ /g;
#	    $id=~s/^[^A-Za-z0-9]*|[^A-Za-z0-9]*$//g;
	    next;}
	$seq.="$_";}
    $seq=~s/\s//g;
    return(0,"*** ERROR $sbrName: no guide sequence found\n"," ") if (length($seq)<1);
    return(1,$id,$seq);
}				# end of fastaRdGuide

###############################################################################

sub slurp_dssp {
        local ($dsspfile,$chain)=@_;
        local ($ipos,@resno,@chn,@seq,@str,@acc,$ires,$nres1);
        if(!$chain) { $chain=' '; } # select chain!
        open(IN,$dsspfile); 
        # header block
        while(<IN>) { last if(/^  #  RESIDUE/); } 
        while(<IN>) {
		next if(/\!/);
		($ipos,$resno,$chn,$seq,$str,$acc,$x,$y,$z)=
        /^\s+(\d+)\s+(\S+) (.) (.)  (.).{18}\s*(\d+).*\s+([\-\d\.]+)\s*([\-\d\.]+)\s*([\-\d\.]+)\s*$/;
		next if($chn ne $chain); $ires++;
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
