#!/usr/bin/perl
##!/usr/bin/perl -w

foreach $arg (@ARGV){
    $kwd="";
    if (! -e $arg){
	$arg=~s/_(.)//g;
	$kwd="chn=$1"; }
    if (! -e $arg){
	print "--- hack $0: usage '$0 file.hssp file.hssp_A'\n";
	print "xx mising file=$arg\n";}

    ($Lok,$msg)=
	&hsspRd($arg,$kwd);
    print "xx in=$arg,$kwd -> ret=($Lok,$msg)\n";
}
exit;



#==============================================================================
# library collected (begin) lll
#==============================================================================


#==============================================================================
sub errSbr    {local($txtInLoc,$sbrNameLocy) = @_ ;
#-------------------------------------------------------------------------------
#   errSbr                      simply writes '*** ERROR $sbrName: $txtInLoc'
#-------------------------------------------------------------------------------
	       $sbrNameLocy=$sbrName if (! defined $sbrNameLocy);
	       $txtInLoc.="\n";
	       $txtInLoc=~s/\n\n+/\n/g;
	       return(0,"*** ERROR $sbrNameLocy: $txtInLoc");
}				# end of errSbr



#==============================================================================
# library collected (end)   lll
#==============================================================================



#===============================================================================
sub hsspRd {
    local ($fileInLoc,$kwdInLoc) = @_ ;
    local ($SBR2,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspRd                       
#       in:                     $fileHssp (must exist), 
#       in:                     $kwdInLoc:  default keywords separated by comma, also
#       in:           kwd=~/nohead/     surpresses reading header information
#       in:           kwd=~/nopair/     surpresses reading pair information
#       in:           kwd=~/noseq/      surpresses reading sequence
#       in:           kwd=~/nosec/      surpresses reading secondary structure
#       in:           kwd=~/noacc/      surpresses reading accessibility
#       in:           kwd=~/noali/      surpresses reading alignments
#       in:           kwd=~/noalifill/  surpresses writing full aligned sequences (no ins!)
#       in:           kwd=~/chn=A,B/    read chains A,B
#       in:           kwd=~/ali=1-5,7/   read alis of seq1-5 and 7
#       in:           kwd=~/ali=id1,id2/ read alis of id1 and id2 (note: no '-' here!)
#       in:           kwd=~/noprof/     surpresses reading profiles
#       in:           kwd=~/no/ surpresses reading of  information
#       in:           kwd=~/no/ surpresses reading of  information
#       in GLOBAL:              from hsspRd_ini:
#       in GLOBAL:              %hsspRd_ini
#       in GLOBAL:              @hsspRd_iniKwdHdr,@hsspRd_iniKwdPair,
#       in GLOBAL:              @hsspRd_iniKwdAli,
#                               
#       out GLOBAL:   %hssp:
#                     $hssp{$kwd}          for all keywords in HEADER (@hsspRd_iniKwdHdr)
#                     $hssp{$kwd,$ctali}   for all pair keywords, data for ali no $ctali
#                     $hssp{'[chain|seq|sec|acc]',$ctres} 
#                     $hssp{'chain'}        e.g. A,B,
#                     $hssp{'chain',$chain,'beg'} first residue of chain $chain
#                     $hssp{'chain',$chain,'end'} last residue of chain $chain
#                     $hssp{'ali',  $numali,$ctres} residue aliged at $ctres residue for ali=$numali
#                               NOTE: can be more than one residue for insertions!
#                     $hssp{'prof',$kwd,$ctres} kwd like in PROF (@hsspRd_iniKwdProf)
#                     $hssp{'fin',$numali}= full sequence (NOTE: guide=$numali=0)          
#                               
#                               
#                               
#         special               ID=ID1, $rd{"kwd",$it} existes for ID1 and ID2
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $SBR2=$tmp."hsspRd";
    $fhinLoc="FHIN_"."hsspRd";$fhoutLoc="FHOUT_"."hsspRd";
				# check arguments
    return(&errSbr("not def fileInLoc!",$SBR2))     if (! defined $fileInLoc);
    $kwdInLoc=0                                     if (! defined $kwdInLoc);
#    return(&errSbr("not def !"))          if (! defined $);

    return(&errSbr("no fileIn=$fileInLoc!",$SBR2))  if (! -e $fileInLoc);

				# ------------------------------
				# initialis pointers and keywords
    $Lok=1;
    ($Lok,$msg)=
	&hsspRd_ini()           if (! defined %hsspRd_ini);
    return(&errSbr("failed in hsspRd_ini \n".$msg,$SBR2)) if (! $Lok);
    
				# ------------------------------
				# check input arguments
    $LnoHead=$LnoPair=$LnoAli=$LnoProf=$LnoIns=0;
    $LnoHead=1                  if ($kwdInLoc && $kwdInLoc=~/nohead/);
    $LnoPair=1                  if ($kwdInLoc && $kwdInLoc=~/nopair/);
    $LnoAli= 1                  if ($kwdInLoc && $kwdInLoc=~/noali/);
    $LnoSeq= 1                  if ($kwdInLoc && $kwdInLoc=~/noseq/);
    $LnoSec= 1                  if ($kwdInLoc && $kwdInLoc=~/nosec/);
    $LnoAcc= 1                  if ($kwdInLoc && $kwdInLoc=~/noacc/);
    $LnoProf=1                  if ($kwdInLoc && $kwdInLoc=~/noprof/);
    $LnoIns=1                   if ($kwdInLoc && $kwdInLoc=~/noins/);
    $LnoAliFill=1               if ($kwdInLoc && $kwdInLoc=~/noalifill/);

				# conflicting stuff
    $LnoSeq=0                   if (! $LnoAliFill && $LnoSeq);

				# ------------------------------
				# open file
    open($fhinLoc,$fileInLoc) || return(&errSbr("fileInLoc=$fileInLoc, not opened",$SBR2));
    undef %hssp;
    undef %tmp;
    undef %tmp_chain;
				# ------------------------------------------------------------
				# read header
				# note: all variable global!
				# ------------------------------------------------------------
    ($Lok,$msg)=
	&hsspRd_head();         return(&errSbr("file=$fileInLoc: problem with hsspRd_head:".
					       $msg."\n",$SBR2)) if (! $Lok);

				# ------------------------------------------------------------
				# read pairs
				# note: all variable global!
				# ------------------------------------------------------------
    ($Lok,$msg)=
	&hsspRd_pair();         return(&errSbr("file=$fileInLoc: problem with hsspRd_pair:".
					       $msg."\n",$SBR2)) if (! $Lok);

				# ------------------------------------------------------------
				# read alignments
				# ------------------------------------------------------------

				# digest what to read
    undef %tmp;
				# in  GLOBAL: $hssp{"ali",$num}
				# out GLOBAL: $tmp{"chain",$chain}=1 -> read chain, undefined else
				# out GLOBAL: $tmp{"ali",$num}=1     -> read protein, undefined else
				# out GLOBAL: @wantNum=   numbers for alignments to read
				# out GLOBAL: @wantBlock= num of blocks with alignments to read
    ($Lok,$msg)=
	&hsspRd_aliPre();       return(&errSbr("file=$fileInLoc: problem with hsspRd_aliPre:".
					       $msg."\n",$SBR2)) if (! $Lok);

				# finally go off reading
				# in GLOBAL: $tmp{"chain",$chain}=1 -> read chain, undefined else
				# in GLOBAL: $tmp{"ali",$num}=1     -> read protein, undefined else
				# in GLOBAL: @wantNum=   numbers for alignments to read
				# in GLOBAL: @wantBlock= num of blocks with alignments to read
    ($Lok,$msg)=
	&hsspRd_ali();          return(&errSbr("file=$fileInLoc: problem with hsspRd_ali:".
					       $msg."\n",$SBR2)) if (! $Lok);

    $#exclLoc=0;		# correct number of alis for chains 
				#    see end of routine

    if (! $LnoAli){		# correct missing parts
	foreach $itali (1..$hssp{"NALIGN"}){
	    $tmp="";
	    foreach $it (1..$hssp{"ali","numres"}){
		if    (! defined $hssp{"ali",$itali,$it}){
		    $hssp{"ali",$itali,$it}=$hsspRd_ini{"symbolInsertion"};}
		elsif ($hssp{"ali",$itali,$it} eq " "){
		    $hssp{"ali",$itali,$it}=$hsspRd_ini{"symbolInsertion"};}
		$tmp.=$hssp{"ali",$itali,$it};
	    }
				# not aligned to chain
	    $exclLoc[$itali]=1
		if (($hsspRd_ini{"symbolInsertion"} eq "." && $tmp=~/^\.+$/) ||
		    ($hsspRd_ini{"symbolInsertion"} ne "." && 
		     $tmp=~/^$hsspRd_ini{"symbolInsertion"}+$/));
	}}
				# ------------------------------------------------------------
				# read profiles
				# ------------------------------------------------------------
    ($Lok,$msg,$LisEOF)=
	&hsspRd_prof();         return(&errSbr("file=$fileInLoc: problem with hsspRd_prof:".
					       $msg."\n",$SBR2)) if (! $Lok);
				# ------------------------------------------------------------
				# read insertions
				# ------------------------------------------------------------
    if (! $LnoIns){
	($Lok,$msg,@insMax)=
	    &hsspRd_ins();      return(&errSbr("file=$fileInLoc: problem with hsspRd_ins:".
					       $msg."\n",$SBR2)) if (! $Lok);
    }

    close($fhinLoc);		# finally close the file

				# ------------------------------------------------------------
				# fill in insertions asf
				# ------------------------------------------------------------
    if (! $LnoIns && ! $LnoAli && $#wantNum){
	($Lok,$msg)=
	    &hsspRd_fill(@insMax); return(&errSbr("file=$fileInLoc: problem with hsspRd_fill:".
						  $msg."\n",$SBR2)) if (! $Lok);
    }

				# ------------------------------
				# which alis wanted?
				# ------------------------------
    if (! $LnoAli && $#wantNum){
	$hssp{"ali","numbers_wanted"}="";
	foreach $numAli (@wantNum){
	    $hssp{"ali","numbers_wanted"}.=$numAli.",";
	}
	$hssp{"ali","numbers_wanted"}=~s/,*$//g;
    }
				# --------------------------------------------------
				# correct number of alis if chain to be read
				# --------------------------------------------------
				# correct alignment (for chains)
    if ($#exclLoc>=1){
	$ctali=0;
				# pair info
	foreach $itali (1..$hssp{"NALIGN"}){
	    next if (defined $exclLoc[$itali]);
	    ++$ctali;
				# pair info
	    if (! $LnoPair){
		foreach $kwd (@hsspRd_iniKwdPair){
		    $hssp{$kwd,$ctali}=$hssp{$kwd,$itali};}}
				# ali info
	    if (! $LnoAli){
		foreach $kwd ("ali"){
		    foreach $itres (1..$hssp{"ali","numres"}){
			$hssp{$kwd,$ctali,$itres}=$hssp{$kwd,$itali,$itres};}}}
				# fill 
	    if (! $LnoAliFill){
		foreach $kwd ("fin"){
		    $hssp{$kwd,$ctali}=$hssp{$kwd,$itali};}}
	}
				# CHANGE number of alis!!!
	$hssp{"numali"}=$hssp{"NALIGN"}=$ctali;
    }
				# clean up
    $#wantNum=$#wantBlock=$#wantNumLoc=
	$#insMax=$#tmp=0;	# slim-is-in

    return(1,"ok $SBR2");
}				# end of hsspRd

#===============================================================================
sub hsspRd_ini {
#    local($fileInLoc,$fhErrSbr) = @_ ;
    local($SBR3,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspRd_ini                  initialises stuff necessary to read HSSP
#       out GLOBAL:             %hsspRd_ini
#       out GLOBAL:             @hsspRd_iniKwdHdr,@hsspRd_iniKwdPair,
#       out GLOBAL:             @hsspRd_iniKwdAli,@hsspRd_iniKwdPair,
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $SBR3=$tmp."hsspRd_ini";

    undef %hsspRd_ini;
				# settings describing format HEADER
    @hsspRd_iniKwdHdr= 
	(
	 "PDBID","DATE","SEQBASE","PARAMETER","THRESHOLD",
	 "REFERENCE","HEADER","COMPND","SOURCE","AUTHOR",
	 "SEQLENGTH","NCHAIN","KCHAIN","NALIGN"
	 );
    foreach $kwd (@hsspRd_iniKwdHdr){
	$hsspRd_ini{"head",$kwd}=1;
    }
    
				# HEADER pair information
    @hsspRd_iniKwdPair= 
	(
	 "NR","ID","STRID","IDE","WSIM","IFIR","ILAS",
	 "JFIR","JLAS","LALI","NGAP","LGAP","LSEQ2","ACCNUM","PROTEIN"
	 );
    foreach $kwd (@hsspRd_iniKwdPair){
	$hsspRd_ini{"pair",$kwd}=1;
    }
				# ALI information
    @hsspRd_iniKwdAli= 
	(
	 "PDBNo","SeqNo","chain","seq","sec","acc","ali"
	 );
    foreach $kwd (@hsspRd_iniKwdAli){
	$hsspRd_ini{"ali",$kwd}=1;
    }
				# PROF information
    @hsspRd_iniKwdProf= 
	(
#	 "SeqNo","PDBNo",
	 "V","L","I","M","F","W","Y","G","A","P",
	 "S","T","C","H","R","K","Q","E","N","D",
	 "NOCC","NDEL","NINS","ENTROPY","RELENT","WEIGHT"
	 );
    foreach $kwd (@hsspRd_iniKwdProf){
	$hsspRd_ini{"prof",$kwd}=1;
    }


    $hsspRd_ini{"regexpBegPair"}=   "^\#\# PROTEINS";           # begin of reading 
    $hsspRd_ini{"regexpEndPair"}=   "^\#\# ALIGNMENTS";         # end of reading

    $hsspRd_ini{"regexpLongId"}=    "^PARAMETER  LONG-ID :YES"; # identification of long id

    $hsspRd_ini{"regexpBegAli"}=    "^\#\# ALIGNMENTS";         # begin of reading
    $hsspRd_ini{"regexpEndAli"}=    "^\#\# SEQUENCE PROFILE";   # end of reading
    $hsspRd_ini{"regexpSkip"}=      "^ SeqNo";                  # skip lines with pattern
    $hsspRd_ini{"nmaxBlocks"}=      100;	                # maximal number of blocks considered (=7000 alis!)
    $hsspRd_ini{"regexpProfNames"}= "^ SeqNo";                  # lines with description of profile columns 
    $hsspRd_ini{"nmaxRes"}=       10000;	                # maximal number of residues (only if ONLY prof to read)

    $hsspRd_ini{"regexpBegIns"}=    "^\#\# INSERTION LIST";     # begin of reading insertion list
    $hsspRd_ini{"regexpInsNames"}=  "^ AliNo  IPOS";            # lines with description of profile columns 

    $hsspRd_ini{"regexpEndIns"}=    "^\/\/";                    # end of reading insertion list
    

    $hsspRd_ini{"lenStrid"}=          4;	# minimal length to identify PDB identifiers
    $hsspRd_ini{"LisLongId"}=         0;	# long identifier names

    $hsspRd_ini{"symbolInsertion"}= ".";        # symbol used for insertions

				# pointers
    $hsspRd_ini{"ptr","IDE"}=       1;
    $hsspRd_ini{"ptr","WSIM"}=      2;
    $hsspRd_ini{"ptr","IFIR"}=      3;
    $hsspRd_ini{"ptr","ILAS"}=      4;
    $hsspRd_ini{"ptr","JFIR"}=      5;
    $hsspRd_ini{"ptr","JLAS"}=      6;
    $hsspRd_ini{"ptr","LALI"}=      7;
    $hsspRd_ini{"ptr","NGAP"}=      8;
    $hsspRd_ini{"ptr","LGAP"}=      9;
    $hsspRd_ini{"ptr","LSEQ2"}=    10;
    $hsspRd_ini{"ptr","ACCNUM"}=   11;
    $hsspRd_ini{"ptr","PROTEIN"}=  12;

    $hsspRd_ini{"ptr","SeqNo"}=     1;
    $hsspRd_ini{"ptr","PDBNo"}=     7;
    $hsspRd_ini{"ptr","chain"}=    13;
    $hsspRd_ini{"ptr","seq"}=      15;
    $hsspRd_ini{"ptr","sec"}=      18;
    $hsspRd_ini{"ptr","acc"}=      37;
    $hsspRd_ini{"ptr","ali"}=      52;

    $hsspRd_ini{"ptr","prof"}=     14;
    $hsspRd_ini{"ptr","profchain"}=12;

    $hsspRd_ini{"ptr","ins","alino"}=1;
    $hsspRd_ini{"ptr","ins","ipos"}= 2;
    $hsspRd_ini{"ptr","ins","jpos"}= 3;
    $hsspRd_ini{"ptr","ins","len"}=  4;
    $hsspRd_ini{"ptr","ins","seq"}=  5;


    $modeSec="HETL";
    $modeSec=$par{"modeSec"} if (defined $par{"modeSec"});

    return(1,"ok $SBR3");
}				# end of hsspRd_ini

#===============================================================================
sub hsspRd_debug {
    local($modeDebugLoc)=@_;
    local($SBR5);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspRd_debug             writes debug and dies
#       in:                     $modeDebugLoc=[all|head|pair|seq|ali|prof|ins|nfar]
#                                           if any set: will write info, and stop!
#       in GLOBAL:              ALL (%hssp= results)
#       out GLOBAL:             ALL
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR5="hsspRd_debug";
    if ($modeDebugLoc && $modeDebugLoc=~/head/){
	foreach $kwd (@hsspRd_iniKwdHdr){
	    print $FHTRACE2 "dbg $SBR5: $kwd=",$hssp{$kwd},"\n";
	}}
    if ($modeDebugLoc && $modeDebugLoc=~/pair/){
	foreach $it (1..$hssp{"NALIGN"}){
	    printf "dbg $SBR5: %3d ",$it;
	    foreach $kwd (@hsspRd_iniKwdPair){
		if (! defined $hssp{$kwd,$it}){
		    print $FHTRACE2 "-*- WARN not defined it=$it, kwd=$kwd\n";
		    next;}
		print $FHTRACE2 $hssp{$kwd,$it}," ";
	    }
	    print $FHTRACE2 "\n";
	}}
    if ($modeDebugLoc && $modeDebugLoc=~/ali/){
	print $FHTRACE2 "dbg $SBR5:seq,sec,acc\n";
	foreach $it(1..$hssp{"SEQLENGTH"}){
	    foreach $kwd (@hsspRd_iniKwdAli){
		next if ($kwd eq "ali");
		next if ($kwd eq "seq" && $LnoSeq);
		next if ($kwd eq "sec" && $LnoSec);
		next if ($kwd eq "acc" && $LnoAcc);
		print $FHTRACE2 $hssp{$kwd,$it},"\t";
	    }
	    print"\n";
	}
	if (! $LnoAli){
	    print $FHTRACE2 "dbg $SBR5:ali\n";
	    foreach $itali (1..$hssp{"NALIGN"}){
		$seq="";
		foreach $it (1..$hssp{"ali","numres"}){
		    if    (! defined $hssp{"ali",$itali,$it}){
			$hssp{"ali",$itali,$it}=$hsspRd_ini{"symbolInsertion"};}
		    elsif ($hssp{"ali",$itali,$it} eq " "){
			$hssp{"ali",$itali,$it}=$hsspRd_ini{"symbolInsertion"};}
		    $seq.=$hssp{"ali",$itali,$it};
		}
		printf "dbg %3d %-s\n",$itali,substr($seq,1,80);}
	    print $FHTRACE2 "dbg $SBR5: seq restricted to 80 residues!\n";
	}}
    
    if ($modeDebugLoc && $modeDebugLoc=~/prof/){
	print $FHTRACE2 "dbg $SBR5:prof\n";
	foreach $itRes (1..$hssp{"ali","numres"}){
	    printf "dbg: %4d prof:",$itRes;
	    foreach $kwd (@hsspRd_iniKwdProf){
		$tmp=3; $tmp=1+length($hssp{"prof",$kwd,$itRes}) if (length($hssp{"prof",$kwd,$itRes})>3);
		printf "%".$tmp."s",$hssp{"prof",$kwd,$itRes};}
	    print $FHTRACE2 "\n";
	}}

    if ($modeDebugLoc && $modeDebugLoc=~/ins/){
	print $FHTRACE2 "dbg $SBR5:ins\n";
	foreach $itali (1..$hssp{"NALIGN"}){
	    $seq="";
	    foreach $it (1..$hssp{"ali","numres"}){
		if    (! defined $hssp{"ali",$itali,$it}){
		    $hssp{"ali",$itali,$it}=$hsspRd_ini{"symbolInsertion"};}
		elsif ($hssp{"ali",$itali,$it} eq " "){
		    $hssp{"ali",$itali,$it}=$hsspRd_ini{"symbolInsertion"};}
		$seq.=$hssp{"ali",$itali,$it};
	    }
	    printf "dbg %3d %-s\n",$itali,substr($seq,1,80);}
	print $FHTRACE2 "dbg $SBR5: seq restricted to 80 residues!\n"; }

    if ($modeDebugLoc && $modeDebugLoc=~/nfar/){
	print $FHTRACE2 "dbg $SBR5: nfar ($distCount,$distCountMode) ndist=",$hssp{"ndist"},",\n";
	if (! defined $distCount || ! defined $distCountMode){
	    print "*** ERROR $SBR5: missing distCount=$distCount, or distCountMode=$distCountMode\n";
	    exit;}
	foreach $tmp (@tmpChain){
	    print $FHTRACE2 "dbg $SBR5: chain=$tmp, number of members=",$hssp{"ndist",$tmp},"\n";
	}}

    if ($modeDebugLoc && $modeDebugLoc=~/fill/){
	print $FHTRACE2 "dbg $SBR5:fill\n";
	foreach $itali (0..$hssp{"NALIGN"}){
	    printf "dbg %3d %-s\n",$itali,substr($hssp{"fill",$itali},1,80);
	}}

    return(1,"ok $SBR5");
}				# end of hsspRd_debug

#===============================================================================
sub hsspRd_getNfar {
    local($distLoc,$distModeLoc)=@_;
    local($SBR3);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspRd_getNfar              
#       in:                     $chainInLoc  : chain to read
#                                   '*' for omitting the test
#       in:                     $distLoc     : limiting distance from HSSP (new Ide)
#                                   '0' in NEXT variable for omitting the test
#       in:                     $chainInLoc:  current chain
#       in:                     $distModeLoc: [gt|ge|lt|le]: if mode=gt: all with
#                                             dist > distLoc counted
#                                   '0' for omitting the test
#       in GLOBAL:              ALL (%hssp= results)
#       out GLOBAL:             ALL
#       in:                     $fileInLoc
#       out:                    1|0,msg,$num,$take:
#                               $num= number of alis in chain and below $distLoc
#                               $take='n,m,..': list of pairs ok
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR3="hsspRd_getNfar";

				# ------------------------------
				# get chains
    $take="";
    if ($Lchain){
	$tmp=$hssp{'chain'};
	$tmp=~s/,*$//g;
	$tmp=~s/\s//g;
	@tmpChain=split(/,/,$tmp);}
    else {
	@tmpChain=("*");
    }
				# --------------------------------------------------
				# get number of distant alignments
				# --------------------------------------------------
    foreach $chainInLoc (@tmpChain){
	next if (length($chainInLoc)<1);
	foreach $itali (1..$hssp{"pair","numali"}){
				# ------------------------------
				# (1) is it aligned to chain?
	    next if ($Lchain &&
		     (($hssp{"IFIR",$itali} > $hssp{"chain",$chainInLoc,"endSeqNo"}) ||
		      ($hssp{"ILAS",$itali} < $hssp{"chain",$chainInLoc,"begSeqNo"}) ));
				# ------------------------------
				# (2) is it correct distance?
	    if ($distModeLoc){
		$lali= $hssp{"LALI",$itali}; 
		$pide= 100*$hssp{"IDE",$itali};
		return(&errSbr("distModeLoc=$distModeLoc, pair=$itali, no lali|ide ($lali,$pide)",$SBR3))
		    if (! defined $lali || ! defined $pide);
                                # compile distance to HSSP threshold (new)
		($pideCurve,$msg)= 
		    &getDistanceNewCurveIde($lali);
		return(&errSbrMsg("failed on getDistanceNewCurveIde($lali)\n".$msg."\n",$SBR3))
		    if (! $pideCurve && ($msg !~ /^ok/));
	    
		$dist=$pide-$pideCurve;
				# mode
		next if (($distModeLoc eq "gt" && $dist <= $distLoc) ||
			 ($distModeLoc eq "ge" && $dist <  $distLoc) ||
			 ($distModeLoc eq "lt" && $dist >= $distLoc) ||
			 ($distModeLoc eq "le" && $dist >  $distLoc)); }
				# ------------------------------
				# (3) ok, take it
	    $take.="$itali,"; 
	}

	$num=0;
	if ($take=~/,/){
	    $take=~s/^,*|,*$//g;
	    @tmp=split(/,/,$take);
	    $num=$#tmp;}
	$hssp{"ndist",$chainInLoc}= $num;
	$hssp{"ndist"}=             0 if (! defined $hssp{"ndist"});
	$hssp{"ndist"}+=            $num;
    }

    undef @tmp;		# slim-is-in!

    return(1,"ok $SBR3");
}				# end of hsspRd_getNfar

#===============================================================================
sub hsspRd_head {
    local($SBR3);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspRd_head                 read section with HEADER info
#       in GLOBAL:              $fhinLoc: filehandle from open HSSP file
#       out GLOBAL:             ALL (%hssp= results)
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR3="hsspRd_head";
				# ------------------------------------------------------------
				# read header
				# ------------------------------------------------------------
    $ctRd=0;			# force reading "NALIGN" "SEQLENGTH"
    $ctMinRead=2;
    $hsspRd_ini{"head","SEQLENGTH"}=1;
    $hsspRd_ini{"head","NALIGN"}=   1;

    while ( <$fhinLoc> ) {
				# finish this part if pairs start
	last if ($_=~ /$hsspRd_ini{"regexpBegPair"}/); 
				# skip reading
	next if ($LnoHead && $ctRd < $ctMinRead);
	chop; $line=$_;
	$kwd=$_; $kwd=~s/^(\S+)\s+(.*)$/$1/;
	undef $remain;
	$remain=$2              if (defined $2);
				# line to read
	if (defined $hsspRd_ini{"head",$kwd}){
	    next if (! defined $remain);
	    $tmp=$remain;
	    $tmp=~s/^\s*|\s*$//g;
				# purge non digits
	    if ($kwd=~/SEQLENGTH/ ||
		$kwd=~/NCHAIN/ ||
		$kwd=~/NALIGN/){
		$tmp=~s/(\d+)\D*.*$/$1/;}
	    $hssp{$kwd}=$tmp;
	    ++$ctRd;
	    next;}
				# is long id
	if ($line =~ /$hsspRd_ini{"regexpLongId"}/) {
	    $LisLongId=1;
	    next; }
    }				# end of HEADER
    
				# ------------------------------
				# correct errors (holm)
    if (defined $hsspRd_ini{"head","KCHAIN"} &&
	! defined $hssp{"KCHAIN"}){
	$hssp{"KCHAIN"}=1;
    }

    return(1,"ok $SBR3");
}				# end of hsspRd_head

#===============================================================================
sub hsspRd_pair {
    local($SBR3);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspRd_pair                 read HEADER pair info
#       in GLOBAL:              $fhinLoc: filehandle from open HSSP file
#       out GLOBAL:             ALL (%hssp= results)
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR3="hsspRd_pair";

				# switch on reading ids if to read ali
    $LwantAliById=0;
    if ($LnoPair && ! $LnoAli &&
	$kwdInLoc && $kwdInLoc=~/ali=[A-Za-z0-9][A-Za-z0-9]+/){
	$LnoPair=0;
	$hsspRd_ini{"pair","ID"}=1;
	$LwantAliById=1;}
				# now read
    $ctAli=0;
    while ( <$fhinLoc> ) { 
				# finish this part if end of pair (begin of ali)
	last if ($_ =~ /$hsspRd_ini{"regexpEndPair"}/); 
				# supress reading pair info
	next if ($LnoPair);
				# skip descriptors
	next if ($_ =~ /^  NR\./);
	$_=~s/\n//g;
	$lenLine=length($_);
	if ($LisLongId){
	    $maxMid=115; $maxMid=($lenLine-56) if ($lenLine < 115);
	    $maxEnd=109; $maxEnd=$lenLine      if ($lenLine < 109);
	    $beg=substr($_,1,56);
	    $end=0; $end=substr($_,109)        if ($lenLine >=109);
	    $mid=substr($_,57,115); }
	else {
	    $maxMid= 62; $maxMid=($lenLine-28) if ($lenLine <  90);
	    $beg=substr($_,1,28);
	    $end=0; $end=substr($_,90)         if ($lenLine >=90);
	    $mid=substr($_,29,90); }
	$end=~s/^\s*|\s*$//g;   # purge leading blanks
	$mid=~s/^\s*|\s*$//g;	# purge leading blanks
				# SWISS accession: hack because it may be empty!
	if ($lenLine > 86) {
	    $accnum=substr($_,81,6); $accnum=~s/(\s)\s+/$1/g ; }
	else {
	    $accnum=0;}
				# begin: counter and id
	$beg=~s/.+ \:\s*|\s*$//g;
	if (! $LisLongId) {
	    $id=$beg;$id=~s/([^\s]+).*$/$1/;
	    $strid=$beg;$strid=~s/$id|\s//g;
	    $strid=0            if ($strid=~/^\s*$/);}
	else              {
	    $id=$beg;$id=~s/(.+_\S+).*/$1/;
	    $strid=substr($line,$hsspRd_ini{"pos","STRIDlong"},6);$strid=~s/\s//g; 
	    $strid=0            if ($strid=~/^\s*$/);}
	if ($strid){
	    $tmp=$hsspRd_ini{"lenStrid"}-1;
	    if ( (length($strid)<$hsspRd_ini{"lenStrid"}) && 
		($id=~/^[0-9][A-Z0-9]{$tmp,$tmp}\s*/)){
		$strid=substr($id,1,$hsspRd_ini{"lenStrid"}); }}
	++$ctAli;
	$hssp{"numali"}=$hssp{"pair","numali"}=$ctAli;

	if (defined $hsspRd_ini{"pair","ID"}){
	    $hssp{"ID",$ctAli}=     $id;}
	if (defined $hsspRd_ini{"pair","STRID"}){
	    $strid=""           if (! $strid);
	    $hssp{"STRID",$ctAli}=  $strid;
				# correct for ID = PDBid
	    $hssp{"STRID",$ctAli}=  $id if ($strid=~/^\s*$/ && 
					 $id=~/\d\w\w\w.?\w?$/);}
	if (defined $hsspRd_ini{"pair","PROTEIN"}){
	    $hssp{"PROTEIN",$ctAli}=$end; }
	if (defined $hssp{"PDBID"}){
	    $hssp{"ID1",$ctAli}=    $hssp{"PDBID"};}
				# middle all info
	$#tmp=0;@tmp=split(/\s+/,$mid);
	foreach $_ (@tmp) {
	    $_=~s/\s//g;}

	foreach $kwd (@hsspRd_iniKwdPair){
	    next if (! defined $hsspRd_ini{"ptr",$kwd});
	    next if (! defined $hsspRd_ini{"pair",$kwd});
	    $ptr=$hsspRd_ini{"ptr",$kwd};
	    $val=$tmp[$ptr]; 
	    $val=~s/\s//g if ($kwd !~/PROTEIN/);
	    $hssp{$kwd,$ctAli}=$val;
				# store for 'want ali by id'
	    $hssp{"ali",$val}=$ctAli if ($LwantAliById);
	}
    }				# end of PAIRS

    return(1,"ok $SBR3");
}				# end of hsspRd_pair

#===============================================================================
sub hsspRd_aliPre {
    local($SBR3);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspRd_aliPre               finds out what to read
#       in GLOBAL:              $hssp{"ali",$num}
#       out GLOBAL:             $tmp{"chain",$chain}=1 if that chain to read 
#                                   else: undefined
#       out GLOBAL:             $tmp{"ali",$num}=1 if that protein to read (by number)
#                                   else: undefined
#       out GLOBAL:             @wantNum=   numbers for alignments to read
#       out GLOBAL:             @wantBlock= numbers of blocks which contain alignments to read
#       out GLOBAL:             
#       in GLOBAL:              $fhinLoc: filehandle from open HSSP file
#       out GLOBAL:             ALL (%hssp= results)
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR3="hsspRd_aliPre";

				# ------------------------------
				# read particular chain?
    $Lchain=0;

    if ($kwdInLoc && $kwdInLoc=~/(chain|chn)=(.+)/){
	if (! defined $2){
	    print $FHTRACE2 "-*- WARN $SBR2: kwdInLoc=$kwdInLoc, missing chain?\n";}
	else { $tmp=$2;
	       $tmp=~s/([A-Z0-9,\*]+)(no|ali|seq|sec|acc)*.*$/$1/g;
	       if ($tmp !~/[A-Z0-9\*]/){
		   print $FHTRACE2 "-*- WARN $SBR2: kwdInLoc=$kwdInLoc, chain=$tmp?\n";}
	       else {
		   $tmp=~s/^,|,$//g;
		   foreach $tmp (split(/,/,$tmp)){
		       $tmp{"chain",$tmp}=1;
		   }
		   $Lchain=1;
	       }}}
				# ------------------------------
				# read particular ali?
    $LaliNo= 0;
    if (! $LnoAli && $kwdInLoc && $kwdInLoc=~/ali=(.+)/){
	if (! defined $1){
	    print $FHTRACE2 "-*- WARN $SBR2: kwdInLoc=$kwdInLoc, missing ali=?\n";}
	else { $tmp=$1;
				# mode 1: given by number
	       if ($tmp=~/^\d+$/    || 
		   $tmp=~/^\d+[\-,]/){
		   @tmp2=split(/[,]/,$tmp);
		   $#tmp=0;
		   foreach $tmp (@tmp2){
				# finish if not number
		       last if ($tmp !~/^\d+$/ && 
				$tmp !~/^\d+\-\d+/);
				# is range
		       if ($tmp=~/^(\d+)\-(\d+)$/){
			   foreach $it ($1..$2){
			       push(@tmp,$it);
			   }}
				# is single number
		       else {
			   push(@tmp,$tmp);}}
		   if ($#tmp > 0){
		       $LaliNo=1;
		       foreach $tmp (@tmp){
			   $tmp{"ali",$tmp}=1;
		       }}}
				# mode 2: given id
	       else {
		   $#tmp=0;
		   @tmp2=split(/[,]/,$tmp);
		   foreach $tmp (@tmp2){
				# finish if not id
		       last if ($tmp !~ /^[A-Za-z0-9][A-Za-z0-9][A-Za-z0-9]/);
		       next if (! defined $hssp{"ali",$tmp} ||
				$hssp{"ali",$tmp}!~/^\d+$/);
		       $it=$hssp{"ali",$tmp};
		       push(@tmp,$it);}
		   if ($#tmp > 0){
		       $LaliNo=1;
		       foreach $tmp (@tmp){
			   $tmp{"ali",$tmp}=1;
		       }}
	       }
	       if ($LaliNo && $#tmp > 0){
				# get numbers to take
		   @wantNum=sort bynumber (@tmp);
		   $#tmp=0;
				# get blocks to take
		   $wantLast=$wantNum[$#wantNum];$#wantBlock=0;
		   foreach $ctBlock (1..$hsspRd_ini{"nmaxBlocks"}){
		       $beg=1+($ctBlock-1)*70;
		       $end=$ctBlock*70;
		       last if ($wantLast < $beg);
		       $Ltake=0;
		       foreach $num (@wantNum){
			   if ( ($beg<=$num) && ($num<=$end) ){
			       $Ltake=1;
			       last;}}
		       if ($Ltake){
			   $wantBlock[$ctBlock]=1;}
		       else{
			   $wantBlock[$ctBlock]=0;}}
	       }
	   }}
				# read all blocks
    elsif (! $LnoAli){
	foreach $ctBlock (1..$hsspRd_ini{"nmaxBlocks"}){
	    $wantBlock[$ctBlock]=1;}
	$#wantNum=0;
	foreach $ctAli (1..$hssp{"NALIGN"}){
	    push(@wantNum,$ctAli);}
    }

    $#tmp=$#tmp2=0;		# slim-is-in
    return(1,"ok $SBR3");
}				# end of hsspRd_aliPre

#===============================================================================
sub hsspRd_ali {
    local($SBR3);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspRd_ali                       
#       in GLOBAL:              $fhinLoc: filehandle from open HSSP file
#       in GLOBAL:              $tmp{"chain",$chain}=1 if that chain to read 
#                                   else: undefined
#       in GLOBAL:              $tmp{"ali",$num}=1 if that protein to read (by number)
#                                   else: undefined
#       in GLOBAL:              @wantNum=   numbers for alignments to read
#       in GLOBAL:              @wantBlock= numbers of blocks which contain alignments to read
#       out GLOBAL:             ALL (%hssp= results)
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR3="hsspRd_ali";

    $ctRes=  0;
    $ctBlock=1;
				# ------------------------------
				# check what to read of first block
    if (! $LnoAli && $wantBlock[$ctBlock]){
				# out GLOBAL: @wantNumLoc: relative position of ali to read
	($Lok,$msg,$LreadBlock,$numFirstAli,$numLastAli)=
	    &hsspRd_aliBlockIni(0); return(&errSbr("file=$fileInLoc: problem with hsspRd_aliBlockIni:".
						   $msg."\n",$SBR3)) if (! $Lok); }

				# ------------------------------------------------------------
				# read ALIGNMENT section
				# ------------------------------------------------------------
    while (<$fhinLoc>) {
	$line=$_; $line=~s/\n//g;
				# ------------------------------
				# end of alignments
	last if ($line=~/$hsspRd_ini{"regexpEndAli"}/); 

				# skip line
	next if ($line=~/$hsspRd_ini{"regexpSkip"}/);
				# ------------------------------
				# new alignment block 
	if (! $LnoAli && $line=~/$hsspRd_ini{"regexpBegAli"}/){
	    ++$ctBlock;
	    $numLastAli=0;
	    $LreadBlock=0;
	    $ctRes=     0;	# reset counting of residues!

	    if ($wantBlock[$ctBlock]) {
				# out GLOBAL: @wantNumLoc: relative position of ali to read
		($Lok,$msg,$LreadBlock,$numFirstAli,$numLastAli)=
		    &hsspRd_aliBlockIni($line); 
		return(&errSbr("file=$fileInLoc: problem with hsspRd_aliBlockIni:".
			       $msg."\n",$SBR3)) if (! $Lok);}
	    next;		# skip rest of line
	}
	elsif ($line=~/$hsspRd_ini{"regexpBegAli"}/){
	    $ctRes=     0;	# reset counting of residues!
	    next; }
				# ------------------------------
				# chain
        $chainRd=substr($line,$hsspRd_ini{"ptr","chain"},1);  # grep out chain identifier
	next if ( $Lchain && ! defined $tmp{"chain",$chainRd});
	++$ctRes;
	$hssp{"ali","numres",$ctBlock}=$ctRes;
				# ------------------------------
				# mark begin and end of chain
	if ($Lchain) { $hssp{"chain"}=""            if (! defined $hssp{"chain"});
		       if (! defined $hssp{"chain",$chainRd,"beg"}){
			   $hssp{"chain"}.=              $chainRd.",";
			   $hssp{"chain",$chainRd,"beg"}=$ctRes;}
		       $hssp{"chain",$chainRd,"end"}=    $ctRes; }
	$hssp{"chain",$ctRes}=$chainRd if (defined $hsspRd_ini{"ali","chain"});
				# ------------------------------
				# read sequence, sec str, acc
				# only for first block!
	if ($ctBlock==1){
	    $hssp{"ali","numres"}=$hssp{"numres"}=$hssp{"NROWS"}=$ctRes;
	    ($Lok,$msg)=
		&hsspRd_aliSeqSecAcc($line); 
	    return(&errSbr("file=$fileInLoc: problem with hsspRd_aliSeqSecAcc:".
			   $msg."\n",$SBR3)) if (! $Lok); }

				# ------------------------------
				# now to the alignments
				# ------------------------------
	next if ($LnoAli);
				# skip block
	next if (! $LreadBlock);
				# skip since no alis
	next if (length($line)<$hsspRd_ini{"ptr","ali"});

				# DEFAULT insertions for all positions
	foreach $numAliLoc (@wantNumLoc){
	    $hssp{"ali",($numAliLoc+$numFirstAli-1),$ctRes}=$hsspRd_ini{"symbolInsertion"};
	}
				# now the alignments
	$tmp=substr($line,$hsspRd_ini{"ptr","ali"}); 
	@tmp=split(//,$tmp);
				# NOTE: @wantNumLoc has the positions to read in current block,
				#       e.g. want no 75, block=71-90, => 75->4
	foreach $numAliLoc (@wantNumLoc){
				# missing ?
	    next if ($numAliLoc > $#tmp);
				# note: numFirstAli=71 in the example above
	    $numAli= $numAliLoc+$numFirstAli-1; 
	    $hssp{"ali",$numAli,$ctRes}=$tmp[$numAliLoc];
	    $hssp{"ali",$numAli}=1 if (! defined $hssp{"ali",$numAli});
	}
    }				# end of reading the alignments and seq,sec,acc,chain

				# clean up
    $#wantNumLoc=0;		# slim-is-in

    return(1,"ok $SBR3");
}				# end of hsspRd_ali

#===============================================================================
sub hsspRd_aliBlockIni {
    local($line)=@_;
    local($SBR4);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspRd_aliBlockIni          new block to read?
#       in GLOBAL:              $fhinLoc: filehandle from open HSSP file
#       out GLOBAL:             @wantNumLoc: relative position of ali to read
#       out GLOBAL:             ALL (%hssp= results)
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR4="hsspRd_aliBlockIni";
    $LreadBlock=0;
				# which numbers are in this block?
				# first block
    if (! $line){ 
	$beg=1;
	$end=70; 
	$end=$hssp{"NALIGN"} if ($hssp{"NALIGN"}<70);}
    else {
	$tmp=$line; $tmp=~s/^[^0-9]+(\d+) -\s+(\d+).*$//;
	$beg=$1;$end=$2;}
    $LreadBlock=1;
    $#wantNumLoc=0;		# local numbers
    foreach $num (@wantNum){
	if ( ($beg<=$num) && ($num<=$end) ){
	    $tmp=($num-$beg)+1; 
	    if ($tmp<1){
		print $FHTRACE2 
		    "-*- WARN $SBR2: negative local alignment number !\n",
		    "-*-             tmp=$tmp,$beg,$end,\n";}
	    else {
		push(@wantNumLoc,$tmp);
	    }
	}
    }
    return(1,"ok $SBR4",$LreadBlock,$beg,$end);
}				# end of hsspRd_aliBlockIni

#===============================================================================
sub hsspRd_aliSeqSecAcc {
    local($line)=@_;
    local($SBR4);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspRd_aliSeqSecAcc                       
#       in GLOBAL:              $fhinLoc: filehandle from open HSSP file
#       out GLOBAL:             ALL (%hssp= results)
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR4="hsspRd_aliSeqSecAcc";
				# get numbers
    if (defined $hsspRd_ini{"ali","SeqNo"}) {
	$SeqNo=  substr($line,$hsspRd_ini{"ptr","SeqNo"},6);
	exit if (! defined $SeqNo || length($SeqNo)<1);
	$SeqNo=~s/\s//g;
	$hssp{"SeqNo",$ctRes}=$SeqNo;
	$hssp{"chain",$chainRd,"begSeqNo"}=$SeqNo if (! defined $hssp{"chain",$chainRd,"begSeqNo"});
	$hssp{"chain",$chainRd,"endSeqNo"}=$SeqNo;}
    
    if (defined $hsspRd_ini{"ali","PDBNo"}) {
	$PDBNo=  substr($line,$hsspRd_ini{"ptr","PDBNo"},6);
	$PDBNo=~s/\s//g;
	$hssp{"PDBNo",$ctRes}=$PDBNo;}
				# for later: restrict to fragment yy
#	    next if ( $ifirLoc  && ($SeqNo < $ifirLoc));
#	    next if ( $ilasLoc  && ($SeqNo > $ilasLoc));
				# sequence
    if (! $LnoSeq && defined $hsspRd_ini{"ali","seq"}) {
	$hssp{"seq",$ctRes}=  substr($line,$hsspRd_ini{"ptr","seq"},1);}
				# secondary structure
    if (! $LnoSec && defined $hsspRd_ini{"ali","sec"}) {	    
	$hssp{"sec",$ctRes}=  substr($line,$hsspRd_ini{"ptr","sec"},1);}
				# solvent accessibility
    if (! $LnoAcc && defined $hsspRd_ini{"ali","acc"}) {	    
	$hssp{"acc",$ctRes}=  substr($line,$hsspRd_ini{"ptr","acc"},3);
	$hssp{"acc",$ctRes}=~s/\D//g; }

    return(1,"ok $SBR4");
}				# end of hsspRd_aliSeqSecAcc

#===============================================================================
sub hsspRd_prof {
    local($SBR3);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspRd_prof                       
#       in GLOBAL:              $fhinLoc: filehandle from open HSSP file
#       out GLOBAL:             ALL (%hssp= results)
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR3="hsspRd_prof";
				# ------------------------------
				# read the profile
				# ------------------------------
    $LisEOF=0;
    $ctRes=0;
    while (<$fhinLoc>) {	# 
	$line=$_; $line=~s/\n//g;
				# no insertions will follow: is END of file
        if ($_=~/^$hsspRd_ini{"regexpEndIns"}/){
	    $LisEOF=1;
	    last;}
				# finish reading
	last if ($line=~/^$hsspRd_ini{"regexpBegIns"}/);
				# skip reading until end
	next if ($LnoProf);
				# ------------------------------
				# is line with column names
	if ($line=~/^$hsspRd_ini{"regexpProfNames"}/){
				# skip part with 'SeqNo PDBNo ' (including chain)
	    $tmp=substr($line,$hsspRd_ini{"ptr","prof"});
	    $tmp=~s/^\s*|\s*$//g;
	    @tmp=split(/\s+/,$tmp);
	    $#tmp_wantCol=$#tmp_kwdCol=0;
	    foreach $it (1..$#tmp){
				# not to be read
		next if (! defined $hsspRd_ini{"prof",$tmp[$it]});
		push(@tmp_kwdCol,$tmp[$it]);
		push(@tmp_wantCol,$it);
	    }
	    $#tmp=0;
	    next;}
				# seems to be an error
	next if (length($line)<$hsspRd_ini{"ptr","prof"});

				# check out chain
	if ($Lchain){
	    $chainRd=substr($line,$hsspRd_ini{"ptr","profchain"},1);
				# chain, in fact not to be read
	    next if (! defined $hssp{"chain",$chainRd,"beg"}); }

				# yy allow for fragment selection later yy
#	next if ( $ifirLoc  && ($SeqNo < $ifirLoc));
#	next if ( $ilasLoc  && ($SeqNo > $ilasLoc));

				# skip part with 'SeqNo PDBNo ' (including chain)
	$tmp=substr($line,$hsspRd_ini{"ptr","prof"});
	$tmp=~s/^\s*|\s*$//g;
	@tmp=split(/\s+/,$tmp);

	++$ctRes;
	$hssp{"prof","numres"}=$ctRes;
	foreach $it (1..$#tmp_wantCol){
	    $it_wantCol=$tmp_wantCol[$it];
	    $hssp{"prof",$tmp_kwdCol[$it_wantCol],$ctRes}=
		$tmp[$it_wantCol];
	}
    }				# end of reading profiles

				# clean up
    $#tmp=$#tmp_wantCol=$#tmp_kwdCol=0;	# slim-is-in
    return(1,"ok $SBR3",$LisEOF);
}				# end of hsspRd_prof

#===============================================================================
sub hsspRd_ins {
    local($SBR3);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspRd_ins                       
#       in GLOBAL:              $fhinLoc: filehandle from open HSSP file
#       out GLOBAL:             ALL (%hssp= results)
#       out:                    $insMax[$itres]= maximal number of insertions
#                               for residue $itres
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR3="lib-prof:hsspRd_ins";

    undef @insMax;		# note: $insMax[$SeqNo]=5 means at residue 'SeqNo'
    $numres=0;
    $numres=$hssp{"ali","numres",1}  if (! $numres && defined $hssp{"ali","numres",1});
    $numres=$hssp{"SEQLENGTH"}       if (! $numres && defined $hssp{"SEQLENGTH"});
    $numres=$hsspRd_ini{"nmaxRes"}   if (! $numres);

				# set number of maximal insertions to 0
    foreach $itRes (1..$numres){
	$insMax[$itRes]=0;
    }

				# ------------------------------
				# read the insertions
    while (<$fhinLoc>){
				# end reading insertion list
        last if ($_=~/^$hsspRd_ini{"regexpEndIns"}/); 

				# --------------------------------------------------
				# read insertion list
				# 
				# syntax of insertion list:  
				#    ....,....1....,....2....,....3....,....4
				#    AliNo  IPOS  JPOS   Len Sequence
				#         9    58    59     5 kQLGAEi
				# 
				# --------------------------------------------------
	$line=$_; $line=~s/\n//;

				# skip line with names
	next if ($line=~/^$hsspRd_ini{"regexpInsNames"}/);
				# --------------------------------------------------
				# continuation of previous line
	if ($line=~/^\s+\+\s*(\S+)$/){ 
	    $seqIns.=$1;
				# number of residues inserted
	    $nresIns=(length($seqIns) - 2);
				# increase count of maximally inserted residues
	    $insMax[$ipos]=$nresIns if ($nresIns > $insMax[$ipos]);

				# NOTE: here $tmp{$it,$SeqNo} gets more than
				#       one residue assigned (ref=11)
				# change 'ACinK' -> 'ACINEWNK'
	    $hssp{"ali",$alino,$ipos}=substr($seqIns,1,(length($seqIns)-1));
	    next; }
	    
				# --------------------------------------------------
				# ERROR should not happen (see syntax)
        if ($line !~ /^\s*\d+/) {
	    print "-*- WARN $SBR3: problem with line=$line, insertion list!\n";
	    next;}
	$tmp=$line;
				# purge leading blanks
	$tmp=~s/^\s*\+*|\s*$//g;
				# note written into columns ' AliNo  IPOS  JPOS   Len Sequence'
	@tmp=split(/\s+/,$tmp);

	$alino=$tmp[$hsspRd_ini{"ptr","ins","alino"}];
				# skip since it did NOT want that one, anyway
	next if (! defined $hssp{"ali",$alino});

				# ok -> take
				# residue position in insertion
	$ipos=   $tmp[$hsspRd_ini{"ptr","ins","ipos"}];
				# sequence at insertion 'kQLGAEi'
	$seqIns= $tmp[$hsspRd_ini{"ptr","ins","seq"}];
				# number of residues inserted
	$nresIns=(length($seqIns) - 2);
				# increase count of maximally inserted residues
	$insMax[$ipos]=$nresIns if (! defined $insMax[$ipos] ||
				    $nresIns > $insMax[$ipos]);

				# --------------------------------------------------
				# NOTE: here $tmp{$it,$SeqNo} gets more than
				#       one residue assigned (ref=11)
				# --------------------------------------------------
				# change 'ACinK' -> 'ACINEWNK'
	$hssp{"ali",$alino,$ipos}=substr($seqIns,1,(length($seqIns)-1));
    }				# end of reading insertions

    @tmp=@insMax;
    $#insMax=0;			# slim-is-in
    return(1,"ok $SBR3",@tmp);
}				# end of hsspRd_ins

#===============================================================================
sub hsspRd_fill {
    local(@insMax)=@_;
    local($SBR3);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspRd_fill                 fills the insertion list asf out: final alignment
#       in GLOBAL:              $fhinLoc: filehandle from open HSSP file
#       out GLOBAL:             ALL (%hssp= results)
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $SBR3=$tmp."hsspRd_fill";

    $numres=0;
    $numres=$hssp{"ali","numres",1}  if (! $numres && defined $hssp{"ali","numres",1});
    $numres=$hssp{"SEQLENGTH"}       if (! $numres && defined $hssp{"SEQLENGTH"});
    $numres=$hsspRd_ini{"nmaxRes"}   if (! $numres);

				# set to ''
    foreach $itAli (0,@wantNum){
	$hssp{"fin",$itAli}="";
    }
				# --------------------------------------------------
				# loop over residues
				# --------------------------------------------------
    foreach $itRes (1..$numres){
	$insMax=$insMax[$itRes];
				# ------------------------------
				# guide sequence
	$hssp{"fin",0}.=$hssp{"seq",$itRes};
				# dirty: fill in the end
	$hssp{"fin",0}.="." x $insMax if ($insMax);

				# ------------------------------
				# loop over all alis
	foreach $itAli (@wantNum){
	    $hssp{"fin",$itAli}.=$hssp{"ali",$itAli,$itRes};
	    $hssp{"fin",$itAli}.="." x (1 + $insMax - length($hssp{"ali",$itAli,$itRes}));
	}
    }
				# ------------------------------
				# now assign to final
    foreach $itAli (0,@wantNum){
				# replace ' ' -> '.'
	$hssp{"fin",$itAli}=~s/\s/\./g;
	next if ($itAli==0);
				# all capital for aligned (NOT for sequence)
	$hssp{"fin",$itAli}=~tr/[a-z]/[A-Z]/;
    }
				# clean up
    $#tmp=0;

    return(1,"ok $SBR3");
}				# end of hsspRd_fill

