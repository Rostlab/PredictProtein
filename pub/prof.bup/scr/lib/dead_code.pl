#!/usr/bin/perl
##===============================================================================
sub nnJurySigma {
    local(@fileOutNetLoc) = @_;
    local($SBR4,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   nnJurySigma                 reads output files and compiles average
#       in:                     @fileOutNetLoc: fortran output files
#       out:                    1|0,msg,$numnet
#       out GLOBAL:             %prd, with $prd{'NUMOUT'},$prd{'NROWS'}, $prd{$ctres,$itout}
#       out GLOBAL:                        $prd{$ctres,'win'}
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR4=""."nnJury";          $fhinLoc="FHIN_"."nnJury";$fhoutLoc="FHOUT_"."nnJury";
				# check arguments
    return(&errSbr("not def fileOutNetLoc!",$SBR4)) if (! defined @fileOutNetLoc ||
							! @fileOutNetLoc);
				# --------------------------------------------------
				# loop over all output files
				# --------------------------------------------------
    $ctnet=0;
				# buffer output
    undef %tmpout;
    foreach $file (@fileOutNetLoc){
	++$ctnet;
				# buffer output
	$sumri=0;
	open($fhinLoc,$file) || return(&errSbr("file=$file, not opened",$SBR4));
				# ------------------------------
				# read file out
	while (<$fhinLoc>) {
				# skip comments
	    next if ($_=~/^\#/ ||
		     $_=~/^\*/ ||
		     $_=~/^\-/   );
	    $_=~s/\n//g;
	    $line=$_;
	    $line=~s/^\s*|\s*$//g; # leading blanks
	    next if (length($line)==0); # skip empty
	    ($ctres,@tmp)=split(/[\t\s]+/,$line);
	    $numout=$#tmp       if (! defined $numout);
	    foreach $itout (1..$#tmp){
		$tmpout{$ctnet,$ctres,$itout}=$tmp[$itout];
	    }
				# get ri
	    if ($par{"optJury"}=~/^sigma/ || 
		$par{"optJury"}=~/^best/  ){
		($Lok,$msg,$ri)=
		    &get_ri
			($modepredLoc,$par{"bitacc"},
			 @tmp); return(&errSbrMsg("file=$file, ctres=$ctres, ri problem, out=".
						  join(',',@tmp),$msg,$SBR4)) if (! $Lok);
		$sumri+=$ri;}
	}
	close($fhinLoc);
	$tmpout{$ctnet,"sumri"}=$sumri;
    }				# end of loop over output files
				# --------------------------------------------------

    $prd{"NROWS"}=$ctres;
    $numnet=$ctnet;
    $numres=$ctres;

				# ------------------------------
				# now check which ones to take
    if ($par{"optJury"}=~/^sigma/ ||
	$par{"optJury"}=~/^best/     ){
				# local para
	$numsig=2;
				# first sort by quality
	$#ri=0; undef %tmp;
	foreach $itnet (1..$#fileOutNetLoc){
	    $tmp=$tmpout{$itnet,"sumri"};
	    if (! defined $tmp{$tmp}){
		push(@ri,$tmp);
		$tmp{$tmp}=$itnet;}
	    else {
		$tmp{$tmp}.=",".$itnet;}}
	@tmp=sort bynumber_high2low (@ri);
	$tmp2="";
	foreach $tmp (@tmp){
	    $tmp2.=",".$tmp{$tmp};}
	$#tmp=$#ri=0;
	$tmp2=~s/(,),*$/$1/g;
	$tmp2=~s/^,*|,*$//g;
	@sorted_by_ri=split(/,/,$tmp2);
				# normalise
	foreach $itnet (1..$#fileOutNetLoc){
	    $tmpout{$itnet,"sumri"}=$tmpout{$itnet,"sumri"}/$numres;
	}}
				# ------------------------------
				# mode: best
    if ($par{"optJury"}=~/best=(\d+)/){
	$npick=$1;
	$#take=0;
	foreach $itnet (1..$npick){
	    push(@take,$sorted_by_ri[$itnet]);
	}}
	
				# ------------------------------
				# mode: sigma
    elsif ($par{"optJury"}=~/^sigma/){
				# now get bad ones
	$Lfinish=0;
	foreach $itsig (1..$numsig){
	    last if ($Lfinish);
	    next if ($par{"optJury"}!~/min$itsig=(\d+)/);
	    $min_numnet[$itsig]= $1;
	    $lastsig=$itsig;
	    $ntake=0; $take="";
	    foreach $itnet (1..$#fileOutNetLoc){
		if ($tmpout{$itnet,"sumri"} >=
		    ($run{"ri_ave",$itnet}-$itsig*$run{"ri_sig",$itnet})){
		    $take.=$itnet.",";
		    ++$ntake;}}
	    if ($ntake >= $min_numnet[$itsig]){
		$take=~s/,$//g;
		@take=split(/,/,$take);
		$Lfinish=1;}}
				# last did NOT find enough
	if (! $Lfinish){
	    $#take=0;
	    foreach $itnet (1..$min_numnet[$lastsig]){
		push(@take,$sorted_by_ri[$itnet]);}}}
    else {
	foreach $itnet (1..$#fileOutNetLoc){
	    push(@take,$itnet);
	}}

				# ------------------------------
				# add up output
    foreach $itnet (@take){
				# less than 1 sigma
	foreach $itres (1..$numres){
				# ini
	    if (! defined $prd{$itres,1}){
		foreach $itout (1..$numout){
		    $prd{$itres,$itout}=0;
		}}
				# add up
	    foreach $itout (1..$numout){
		$prd{$itres,$itout}+=$tmpout{$itnet,$itres,$itout};
	    }
	}}


    $prd{"NROWS"}= $numres;
    $prd{"NUMOUT"}=$numout;
    $numnet=$#take;

    return(&errSbr("numnet=$numnet??",$SBR4)) if ($numnet<1);

				# ------------------------------
				# normalise
				# ------------------------------
    if ($numnet > 1){
	foreach $itres (1..$ctres){
	    $max=0;
	    foreach $itout (1..$prd{"NUMOUT"}){
		$prd{$itres,$itout}=int($prd{$itres,$itout}/$numnet);
		if ($max<$prd{$itres,$itout}){
		    $max=$prd{$itres,$itout};
		    $pos=$itout;}
	    }
				# winner: error
	    if ($pos<1 || $pos>$prd{"NUMOUT"}){
		$#tmp=0;
		foreach $itout (1..$prd{"NUMOUT"}){
		    push(@tmp,$prd{$itres,$itout});}
		return(&errSbr("no winner?? itres=$itres, out=".join(',',@tmp,"\n"),$SBR4));}
	    $prd{$itres,"win"}=$pos;
	}}
    else {
	foreach $itres (1..$ctres){
	    $max=0;
	    foreach $itout (1..$prd{"NUMOUT"}){
		if ($max<$prd{$itres,$itout}){
		    $max=$prd{$itres,$itout};
		    $pos=$itout;}
	    }
				# winner: error
	    if ($pos<1 || $pos>$prd{"NUMOUT"}){
		$#tmp=0;
		foreach $itout (1..$prd{"NUMOUT"}){
		    push(@tmp,$prd{$itres,$itout});}
		return(&errSbr("no winner?? itres=$itres, out=".join(',',@tmp,"\n"),$SBR4));}
	    $prd{$itres,"win"}=$pos;
	}}

				# ------------------------------
				# temporary output file
				# ------------------------------
    if ($par{"debug"}){
	$run{$itpar,"fileout"}=
	    $fileout=
		$par{"dirWork"}.$par{"titleNetOut"}.
		    $itpar."-"."jury".$par{"extNetOut"};
				# security erase existing file
	unlink($fileout)        if (-e $fileout);
	push(@FILE_REMOVE,$fileout);
	open($fhoutLoc,">".$fileout)||
	    do { print "-*- WARN $SBR4: failed opening fileout=$fileout!\n";
		 $fileout=0;}; 
	foreach $itres (1..$ctres){
	    $#tmp=0;
	    foreach $itout (1..$prd{"NUMOUT"}){
		push(@tmp,$prd{$itres,$itout});}
	    printf $fhoutLoc
		"%8d ". "%4d" x $prd{"NUMOUT"} . "\n",
		$itres,@tmp;
	}
	close($fhoutLoc); }
				# clean up
    undef %tmp;			# slim-is-in
    undef %tmpout;
    $#sorted_by_ri=$#take=$#tmp=$#ri=0;

    return(1,"ok $SBR4");
}				# end of nnJurySigma

#===============================================================================
sub assVecSpeed_normalGeneral {
    local($itWin,$itsamLoc,$modeinLoc,$numaaLoc) = @_ ;
    local($SBR6);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   assVecSpeed_normalGeneral                       
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR6=""."assVecSpeed_normalGeneral";

				# --------------------------------------------------
				# ---> sequence
    if ($modeinLoc=~/aa/){
				# normalGeneral residue
	if (defined $aa{$prot{"seq",$itWin}}){
	    foreach $itaa(1..($numaaLoc-1)){
		$aaTmp=$aa[$itaa];
		push(@vecIn,	                          # all AAs to profVal i=1..20 => prof/100
		     int($par{"bitacc"}*($prot{$aaTmp,$itWin}/100)));
	    }
	    push(@vecIn,0);                               # spacer to 0        i=21    =>   0

				# unknown residue
	}else{
	    foreach $itaa(1..($numaaLoc-1)){
		push(@vecIn,	                          # all AAs to dbAve   i=1..20 => occ (0..1)
		    int($par{"bitacc"}*$aaXprof[$itaa])); 
	    }
	    push(@vecIn,0);                               # spacer to 0        i=21    =>   0
	}}
				# --------------------------------------------------
				# ---> conservation weight
    if ($modeinLoc=~/cw/){
				# normalGeneral residue
	if (defined $aa{$prot{"seq",$itWin}}){
	    push(@vecIn,int($par{"bitacc"}* 0.5*$prot{"cons",$itWin}));
	}else{			# unknown residue
	    push(@vecIn,0);
	}}

				# --------------------------------------------------
				# ---> number of deletions
    if ($modeinLoc=~/ndel/){
				# normalGeneral residue
	if (defined $prot{"nocc",$itWin} && $prot{"nocc",$itWin}){
	    $tmp=int($par{"bitacc"}*($prot{"ndel",$itWin}/$prot{"nocc",$itWin}));
				# note: may exceed 100% (by definition!)
	    $tmp=$par{"bitacc"} if ($tmp > $par{"bitacc"});
	    push(@vecIn,$tmp);
	}
				# problem
	else {
	    push(@vecIn,0);
	}}
				# --------------------------------------------------
				# ---> number of insertions
    if ($modeinLoc=~/nins/){
				# normalGeneral residue
	if (defined $prot{"nocc",$itWin} && $prot{"nocc",$itWin}){
	    $tmp=int($par{"bitacc"}*($prot{"nins",$itWin}/$prot{"nocc",$itWin}));
				# note: may exceed 100% (by definition!)
	    $tmp=$par{"bitacc"} if ($tmp > $par{"bitacc"});
	    push(@vecIn,$tmp);
	}
				# problem
	else {
	    push(@vecIn,0);
	}}

    return(1,"ok $SBR6");
}				# end of assVecSpeed_normalGeneral

#===============================================================================
sub assVecSpeed_normalGeneralAcc {
    local($itWin,$itsamLoc,$modeinLoc,$numaaLoc) = @_ ;
    local($SBR6);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   assVecSpeed_normalGeneralAcc                       
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR6=""."assVecSpeed_normalGeneralAcc";

				# --------------------------------------------------
				# ---> sequence
    if ($modeinLoc=~/aa/){
				# normalGeneralAcc residue
	if (defined $aa{$prot{"seq",$itWin}}){
	    foreach $itaa(1..($numaaLoc-1)){
		$aaTmp=$aa[$itaa];
		push(@vecIn,	                          # all AAs to profVal i=1..20 => prof/100
		     int($par{"bitacc"}*($protacc{$aaTmp,$itWin}/100)));
	    }
	    push(@vecIn,0);                               # spacer to 0        i=21    =>   0

				# unknown residue
	}else{
	    foreach $itaa(1..($numaaLoc-1)){
		push(@vecIn,	                          # all AAs to dbAve   i=1..20 => occ (0..1)
		    int($par{"bitacc"}*$aaXprof[$itaa])); 
	    }
	    push(@vecIn,0);                               # spacer to 0        i=21    =>   0
	}}
				# --------------------------------------------------
				# ---> conservation weight
    if ($modeinLoc=~/cw/){
				# normalGeneral residue
	if (defined $aa{$prot{"seq",$itWin}}){
	    push(@vecIn,int($par{"bitacc"}* 0.5*$protacc{"cons",$itWin}));
	}else{			# unknown residue
	    push(@vecIn,0);
	}}

				# --------------------------------------------------
				# ---> number of deletions
    if ($modeinLoc=~/ndel/){
				# normalGeneral residue
	if (defined $prot{"nocc",$itWin} && $protacc{"nocc",$itWin}){
	    $tmp=int($par{"bitacc"}*($protacc{"ndel",$itWin}/$protacc{"nocc",$itWin}));
				# note: may exceed 100% (by definition!)
	    $tmp=$par{"bitacc"} if ($tmp > $par{"bitacc"});
	    push(@vecIn,$tmp);
	}
				# problem
	else {
	    push(@vecIn,0);
	}}
				# --------------------------------------------------
				# ---> number of insertions
    if ($modeinLoc=~/nins/){
				# normalGeneral residue
	if (defined $protacc{"nocc",$itWin} && $protacc{"nocc",$itWin}){
	    $tmp=int($par{"bitacc"}*($protacc{"nins",$itWin}/$protacc{"nocc",$itWin}));
				# note: may exceed 100% (by definition!)
	    $tmp=$par{"bitacc"} if ($tmp > $par{"bitacc"});
	    push(@vecIn,$tmp);
	}
				# problem
	else {
	    push(@vecIn,0);
	}}

    return(1,"ok $SBR6");
}				# end of assVecSpeed_normalGeneralAcc

#===============================================================================
sub assVecSpeed_spacerGeneral {
    local($itWin,$itsamLoc,$modeinLoc,$numaaLoc) = @_ ;
    local($SBR6);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   assVecSpeed_spacerGeneral                       
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR6=""."assVecSpeed_spacerGeneral";

				# --------------------------------------------------
				# ---> sequence
    if ($modeinLoc=~/aa/){
	foreach $itaa (1 .. ($numaaLoc-1)){
	    push(@vecIn,0);	                          # all AAs to zero    i=1..20 =>   0 
	}
	push(@vecIn,$par{"bitacc"});                      # spacer to 1,       i=21    =>   1
    }
				# --------------------------------------------------
				# ---> conservation weight
    if ($modeinLoc=~/cw/){
	push(@vecIn,int($par{"bitacc"}*0.25));	          # all AAs to zero    i=1..20 =>   0 
    }
				# --------------------------------------------------
				# ---> number of deletions
    if ($modeinLoc=~/ndel/){
	push(@vecIn,0);
    }
				# --------------------------------------------------
				# ---> number of insertions
    if ($modeinLoc=~/nins/){
	push(@vecIn,0);
    }

    return(1,"ok $SBR6");
}				# end of assVecSpeed_spacerGeneral

#===============================================================================
sub assVecSpeed_spacerSeqCwNinsNdel {
    local($itWin,$itsamLoc,$numaaLoc) = @_ ;
    local($SBR6);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   assVecSpeed_spacerSeqCwNinsNdel                       
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR6=""."assVecSpeed_spacerSeqCwNinsNdel";

				# --------------------------------------------------
				# ---> sequence
    foreach $itaa (1 .. ($numaaLoc-1)){
	push(@vecIn,0);                               # all AAs to zero    i=1..20 =>   0 
    }
    push(@vecIn,$par{"bitacc"});                      # spacer to 1,       i=21    =>   1

				# ---> conservation weight
    push(@vecIn,int($par{"bitacc"}*0.25));

				# ---> number of deletions
    push(@vecIn,0);

				# ---> number of insertions
    push(@vecIn,0);

    return(1,"ok $SBR6");
}				# end of assVecSpeed_spacerSeqCwNinsNdel

#===============================================================================
sub assVecSpeed_normalSeqCwNinsNdelAcc {
    local($itWin,$itsamLoc,$numaaLoc) = @_ ;
    local($SBR6);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   assVecSpeed_normalSeqCwNinsNdelAcc                       
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR6=""."assVecSpeed_normalSeqCwNinsNdelAcc";

				# ------------------------------
				# normal residue
    if (defined $aa{$prot{"seq",$itWin}}){
				# ---> sequence
	foreach $itaa(1..($numaaLoc-1)){
	    $aaTmp=$aa[$itaa];
	    push(@vecIn,	                          # all AAs to profVal i=1..20 => prof/100
		 int($par{"bitacc"}*($protacc{$aaTmp,$itWin}/100)));
	    }
	    push(@vecIn,0);                               # spacer to 0        i=21    =>   0

				# ---> conservation weight
	push(@vecIn,int($par{"bitacc"}* 0.5*$protacc{"cons",$itWin}));
    }
				# ------------------------------
				# unknown residue
    else{
				# ---> sequence
	foreach $itaa(1..($numaaLoc-1)){
	    push(@vecIn,	                          # all AAs to dbAve   i=1..20 => occ (0..1)
		 int($par{"bitacc"}*$aaXprof[$itaa])); 
	    }
	    push(@vecIn,0);                               # spacer to 0        i=21    =>   0
				# ---> conservation weight
	push(@vecIn,0);                                   # spacer to 0        i=21    =>   0
    }

				# --------------------------------------------------
				# normal residue
    if (defined $protacc{"nocc",$itWin} && $protacc{"nocc",$itWin}){
				# ---> number of deletions
	$tmp=int($par{"bitacc"}*($protacc{"ndel",$itWin}/$protacc{"nocc",$itWin}));
				# note: may exceed 100% (by definition!)
	$tmp=$par{"bitacc"} if ($tmp > $par{"bitacc"});
	push(@vecIn,$tmp);

				# ---> number of insertions
	$tmp=int($par{"bitacc"}*($protacc{"nins",$itWin}/$protacc{"nocc",$itWin}));
				# note: may exceed 100% (by definition!)
	$tmp=$par{"bitacc"} if ($tmp > $par{"bitacc"});
	push(@vecIn,$tmp);
    }
				# ------------------------------
				# problem
    else {
	push(@vecIn,
	     0,
	     0);
    }

    return(1,"ok $SBR6");
}				# end of assVecSpeed_normalSeqCwNinsNdelAcc

#===============================================================================
sub assVecSpeed_normalSeqCwNinsNdel {
    local($itWin,$itsamLoc,$numaaLoc) = @_ ;
    local($SBR6);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   assVecSpeed_normalSeqCwNinsNdel                       
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR6=""."assVecSpeed_normalSeqCwNinsNdel";

				# ------------------------------
				# normal residue
    if (defined $aa{$prot{"seq",$itWin}}){
				# ---> sequence
	foreach $itaa(1..($numaaLoc-1)){
	    $aaTmp=$aa[$itaa];
	    push(@vecIn,	                          # all AAs to profVal i=1..20 => prof/100
		 int($par{"bitacc"}*($prot{$aaTmp,$itWin}/100)));
	    }
	    push(@vecIn,0);                               # spacer to 0        i=21    =>   0

				# ---> conservation weight
	push(@vecIn,int($par{"bitacc"}* 0.5*$prot{"cons",$itWin}));
    }
				# ------------------------------
				# unknown residue
    else{
				# ---> sequence
	foreach $itaa(1..($numaaLoc-1)){
	    push(@vecIn,	                          # all AAs to dbAve   i=1..20 => occ (0..1)
		 int($par{"bitacc"}*$aaXprof[$itaa])); 
	    }
	    push(@vecIn,0);                               # spacer to 0        i=21    =>   0
				# ---> conservation weight
	push(@vecIn,0);                                   # spacer to 0        i=21    =>   0
    }

				# --------------------------------------------------
				# normal residue
    if (defined $prot{"nocc",$itWin} && $prot{"nocc",$itWin}){
				# ---> number of deletions
	$tmp=int($par{"bitacc"}*($prot{"ndel",$itWin}/$prot{"nocc",$itWin}));
				# note: may exceed 100% (by definition!)
	$tmp=$par{"bitacc"} if ($tmp > $par{"bitacc"});
	push(@vecIn,$tmp);

				# ---> number of insertions
	$tmp=int($par{"bitacc"}*($prot{"nins",$itWin}/$prot{"nocc",$itWin}));
				# note: may exceed 100% (by definition!)
	$tmp=$par{"bitacc"} if ($tmp > $par{"bitacc"});
	push(@vecIn,$tmp);
    }
				# ------------------------------
				# problem
    else {
	push(@vecIn,
	     0,
	     0);
    }

    return(1,"ok $SBR6");
}				# end of assVecSpeed_normalSeqCwNinsNdel

#===============================================================================
sub assData_vecIn1stNOThydro_bup {
    local($winHalf,$BEG,$END,$LEN,$numaaLoc,$numinLoc,$modepredLoc) = @_ ;
    local($SBR5);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   assData_vecIn1stNOThydro_bup    loops over all residues in one chain and writes vecIn
#                               all input sequence stuff EXCEPT hydro_bup
#                               
#                               ==================================================
#                               expected input modein:
#                               loc=aa-cw-nins-ndel,glob=nali-nfar-len-dis-comp
#                               ==================================================
#                               
#       in:                     $winHalf:      half window length (($par{"numwin"}-1)/2)
#       in:                     $BEG:          begin of current chain
#       in:                     $END:          end of current chain
#       in:                     $LEN:          length of current chain
#       in:                     $numaaLoc:     number of amino acids
#       in:                     $numinLoc= number of input units
#       in:                     $modepredLoc=  prediction mode [sec|acc|htm]
#                               
#       in GLOBAL:              $par{"numresMin|symbolPrdShort|doCorrectSparse|verbForSam"}
#       in GLOBAL:              %prot
#       in GLOBAL:              @break from &assData_countChainBreaks
#       in GLOBAL:              $break[1]="n1-n2" : range for first fragment
#       in GLOBAL:              %nnout from &assData_nnout
#                               
#       out GLOBAL:             %prot{"phd_skip",$itres}=<0|1>
#       out GLOBAL:             
#                               
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR5=""."assData_vecIn1stNOThydro_bup";

    $errMsg=
	"\n*** ERROR $SBR5: called with: ".
	    "winHalf=$winHalf, GLOBAL BEG=$BEG, END=$END, modein=$modeinLoc\n";
				# ------------------------------
				# check
    return(&errSbr("prof did NOT define ARRAYaa21",$SBR3))    if ($#aa21    < 20);
    return(&errSbr("prof did NOT define ARRAYaaXprof",$SBR3)) if ($#aaXprof < 20);


				# --------------------------------------------------
				# all residues in current chain!
				# --------------------------------------------------
    foreach $itres ($BEG..$END){
	$#vecIn=0;
				# ----------------------------------------
				# for each residue
				# ----------------------------------------
	$SEQ_CURRENT_SAMPLE=$prot{"seq",$itres};
	    
	$SEQ_CURRENT_SAMPLE= "X" if (! defined $SEQ_CURRENT_SAMPLE);

				# ------------------------------
				# local info from window
				# in/out GLOBAL: $itVec AND %vecIn
				#       go through window
	if ($modepredLoc ne "acc"){
	    foreach $itWin (($itres-$winHalf) .. ($itres+$winHalf)){
				# spacer: also before and after chain break
		$Lspacer=0;
		$Lspacer=1      if (! defined $prot{"seq",$itWin} || 
				    $prot{"seq",$itWin} eq "!"    ||
				    ($itWin < $BEG) || ($itWin > $END) );

				# no spacer
				#    out GLOBAL @vecIn
		if (! $Lspacer){
		    ($Lok,$msg)=
			&assVecSpeed_normalSeqCwNinsNdel
			    ($itWin,$itres,$numaaLoc
			     ); return(&errSbrMsg("after call assVecSpeed_normalSeqCwNinsNdel($itWin,".
						  "$itres)",$msg,$SBR5)) if (! $Lok); }
				# spacer
		else {
		    ($Lok,$msg)=
			&assVecSpeed_spacerSeqCwNinsNdel
			    ($itWin,$itres,$numaaLoc
			     ); return(&errSbrMsg("after call assVecSpeed_spacerSeqCwNinsNdel($itWin,".
						  "$itres)",$msg,$SBR5)) if (! $Lok); }
	    }}
				# ------------------------------
				# DO for ACC
	else {
	    foreach $itWin (($itres-$winHalf) .. ($itres+$winHalf)){
				# spacer: also before and after chain break
		$Lspacer=0;
		$Lspacer=1      if (! defined $prot{"seq",$itWin} || 
				    $prot{"seq",$itWin} eq "!"    ||
				    ($itWin < $BEG) || ($itWin > $END) );

				# no spacer
				#    out GLOBAL @vecIn
		if (! $Lspacer){
		    ($Lok,$msg)=
			&assVecSpeed_normalSeqCwNinsNdelAcc
			    ($itWin,$itres,$numaaLoc
			     ); return(&errSbrMsg("after call assVecSpeed_normalSeqCwNinsNdelAcc($itWin,".
						  "$itres)",$msg,$SBR5)) if (! $Lok); }
				# spacer
		else {
		    ($Lok,$msg)=
			&assVecSpeed_spacerSeqCwNinsNdel
			    ($itWin,$itres,$numaaLoc
			     ); return(&errSbrMsg("after call assVecSpeed_spacerSeqCwNinsNdel($itWin,".
						  "$itres)",$msg,$SBR5)) if (! $Lok); }
	    }}


				# ------------------------------
				# global info from outside window
	foreach $vecGlob (@vecGlob){
	    push(@vecIn,int($par{"bitacc"}*$vecGlob));
	}

	$#vecDis=0;		# distance of window from ends
	&assVec_seqGlobDisN($itres,$winHalf);      # distance from N-term
	&assVec_seqGlobDisC($itres,$winHalf,$END); # distance from C-term
	foreach $vecDis  (@vecDis){
	    push(@vecIn,int($par{"bitacc"}*$vecDis));
	}
				# ------------------------------
				# security check
	return(&errSbr("itres=$itres, vecIn{NUMIN}=".$#vecIn." ne =$numinLoc, \n".
		       "beg=$BEG, end=$END, livel=$itlevel, itpar=$itpar, modein=$modeinLoc\n".
		       $errMsg,$SBR5)) if ($#vecIn != $numinLoc);

				# ------------------------------
				# write input vectors
				#      GLOBAL in:  @vecIn
				#      GLOBAL in:  @codeUnitIn1st
	($Lok,$msg)=
	    &vecInWrt($itres,$fhoutLoc,$numinLoc
		      );        return(&errSbrMsg("after vecInWrt ($itres)",$msg,$SBR5)) if (! $Lok); 
    }				# end of loop over residues for one break!

				# count up samples
    $ctSamTot+=$LEN;

    return(1,"ok $SBR5");
}				# end of assData_vecIn1stNOThydro_bup

#===============================================================================
sub assData_countChainBreaks {
    my($SBR3,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   assData_countChainBreaks     simple function to assData_ in previous: count chain breaks
#                               also correct accessibility and sec for breaks
#   in GLOBAL:                  %prot
#-------------------------------------------------------------------------------
    $SBR3=""."assData_countChainBreaks";$fhinLoc="FHIN_"."assData_countChainBreaks";
    $#tmp=0;
    $ibeg=1;
    foreach $itTmp (1..$prot{"nres"}){
                                # if break detected, store: ibeg-iend
        if ($prot{"seq",$itTmp} eq "!") {
				# ------------------------------
				# correct accessibility for chain
#	    $prot{"acc",$itTmp}=100; # set to maximum

                                # through too short ones
            $iend=$itTmp;	# include chain break in end !!
            push(@tmp,$ibeg."-".$iend)
		if ((1+$iend-$ibeg) >=1);
            $ibeg=0; }
        elsif (! $ibeg){
            $ibeg=$itTmp;}
    }
                                # final end: note if no break detected, just 1-length
    push(@tmp,$ibeg."-".$prot{"nres"});

				# notify of problems with short breaks!
				# yy correct one day
    if ($#tmp > 1) {
	foreach $itBreak (1..$#tmp) {
	    ($beg,$end)=split(/\-/,$tmp[$itBreak]);
	    $len=1+$end-$beg;
	    $tmp="itbreak=$itBreak $tmp[$itBreak] too short";
	    if ($len < 25) {
		open("FHOUT",">>".$par{"fileOutErrorChain"}) || 
		    warn "-*- $SBR3: failed appending to file=".$par{"fileOutErrorChain"}."\n";
		print FHOUT $tmp,"\n";
		close("FHOUT");}
	}}

    return(@tmp);
}				# end of assData_countChainBreaks

#===============================================================================
sub assData_globVecIn {
    local($modeinLoc,$modepredLoc,$BEG,$END,$LEN) = @_ ;
    local($SBR6);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   assData_globVecIn           get GLOBAL parts for input factors
#                               NOTE: independent of residue!
#                               
#       out GLOBAL              @vecGlob
#                               
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR6=""."assData_globVecIn";
				# --------------------------------------------------
				# sec, acc, htm
				# --------------------------------------------------
    if ($modepredLoc=~/^sec/ || $modepredLoc=~/^acc/ || $modepredLoc=~/^htm/){
				# ------------------------------
				# determine global values
				#    GLOBAL out: @vecGlob
	$#vecGlob=0;
	&assVec_seqGlobComp($winHalfLoc,$BEG,$END,$LEN
			    )   if ($modeinLoc=~/comp/); # global AA composition
	&assVec_seqGlobLen ($winHalfLoc,$LEN
			    )   if ($modeinLoc=~/len/ ); # length of protein
	&assVec_seqGlobNali($winHalfLoc,$LEN
			    )   if ($modeinLoc=~/nali/); # no of homologues
	&assVec_seqGlobNfar($winHalfLoc,$LEN
			    )   if ($modeinLoc=~/nfar/); # no of distant homologues
    }

    else {
	&errSbr("modepred (",$modepredLoc,") not understood",
		$SBR6);}

    return(1,"ok $SBR6");
}				# end of assData_globVecIn

#===============================================================================
sub assData_vecIn2ndAllXX {
    local($winHalf,$BEG,$END,$LEN,$modeinLoc,$numinLoc) = @_ ;
    local($SBR5);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   assData_vecIn2ndAllXX            loops over all residues in one chain and writes vecIn
#                               GENERAL version for specialists, see below
#                               
#       in:                     $winHalf:      half window length (($par{"numwin"}-1)/2)
#       in:                     $BEG:          begin of current chain
#       in:                     $END:          end of current chain
#       in:                     $LEN:          length of current chain
#       in:                     $modeinLoc=    input mode 
#                                    'win=17,loc=aa-cw-nins-ndel,glob=nali-nfar-len-dis-comp'
#       in:                     $numinLoc= number of input units
#                               
#       in GLOBAL:              $par{"numresMin|symbolPrdShort|doCorrectSparse|verbForSam"}
#       in GLOBAL:              %prot
#                               
#       in GLOBAL:              @break from &assData_countChainBreaks
#       in GLOBAL:              $break[1]="n1-n2" : range for first fragment
#                               
#       in GLOBAL:              %nnout from &assData_nnout
#                               
#       out GLOBAL:             %prot{"phd_skip",$itres}=<0|1>
#       out GLOBAL:             
#                               
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR5=""."assData_vecIn2ndAllXX";

				# --------------------------------------------------
				# all residues in current chain!
				# --------------------------------------------------

    foreach $itres ($BEG..$END){
	$#vecIn=0;
				# ------------------------------
				# (1)  write higher level data: 
				#      out GLOBAL %vecIn(for one sample)
				#      out GLOBAL @vecIn
				# ------------------------------
				# spacer
	$begWin=($itres-$winHalf);
	$endWin=($itres+$winHalf);
				# spacer before
	$ctbefore=$ctafter=0;
	if ($begWin < 1){
	    foreach $itWin ($begWin .. 0){
		++$ctbefore;
				# ---> in: predictions
		foreach $itout (1..$nnout{"outNum"}){
		    push(@vecIn,0);                     # all str to zero        i=1..3  =>   0 
		}
		push(@vecIn,$par{"bitacc"});            # spacer to 1,           i=4     =>   100
				# ---> in: winner pred (repeat)
		foreach $itout (1..$nnout{"outNum"}){
		    push(@vecIn,0);                     # all str to zero        i=1..3  =>   0 
		}
				# ---> in: reliability index
		push(@vecIn,0); }}
				# spacer after
	if ($endWin > $END){
	    foreach $itWin (($END+1) .. $endWin){
		++$ctafter;
				# ---> in: predictions
		foreach $itout (1..$nnout{"outNum"}){
		    push(@vecIn,0);                     # all str to zero        i=1..3  =>   0 
		}
		push(@vecIn,$par{"bitacc"});            # spacer to 1,           i=4     =>   100
				# ---> in: winner pred (repeat)
		foreach $itout (1..$nnout{"outNum"}){
		    push(@vecIn,0);                     # all str to zero        i=1..3  =>   0 
		}
				# ---> in: reliability index
		push(@vecIn,0); }}
	print "xx itres=$itres, begwin=$begWin, ctbefore=$ctbefore, endwin=$endWin, ctafter=$ctafter, end=$END\n";
	print "xx begin now=",($ctbefore+$itres-$winHalf),", end now=",($itres+$winHalf-$ctafter),",\n";

				# normal residue prediction
	foreach $itWin (($ctbefore+$itres-$winHalf) .. ($itres+$winHalf-$ctafter)){ # 
				# ---> in: predictions
	    foreach $itout (1..$nnout{"outNum"}){
		push(@vecIn,
		     $nnout{"prob",$itout,$itWin}); # all AAs to prediction  i=1..3  =>   prof
	    }
	    push(@vecIn,0);	                    # spacer to 0             i=4    =>   0
				# ---> in: winner pred (repeat)
				#      winner to 100, all others to 0
	    foreach $itout (1..$nnout{"outNum"}){
		$tmp=0;
		$tmp=$par{"bitacc"} if ($itout == $nnout{"iwin",$itWin});
		push(@vecIn,$tmp);
	    }
				# ---> in: reliability index
	    $ri=0;
				# unit: bitacc * ri / 10
	    $ri= int($par{"bitacc"} * ($nnout{"ri",$itWin}/10)) 
		if (defined $nnout{"ri",$itWin});
	    push(@vecIn,$ri);
	}			# end of loop over window
				# ------------------------------

				# ------------------------------
				# (2)  write sequence part
				#      out GLOBAL %vecIn(for one sample)
				#      out GLOBAL @vecIn
				# ------------------------------

	$SEQ_CURRENT_SAMPLE=$prot{"seq",$itres};
	    
	$SEQ_CURRENT_SAMPLE= "X" if (! defined $SEQ_CURRENT_SAMPLE);

				# ------------------------------
				# local info from window
				# in/out GLOBAL: $itVec AND %vecIn
				#       go through window
	foreach $itWin (($itres-$winHalf) .. ($itres+$winHalf)){
				# spacer: also before and after chain break
	    $Lspacer=0;
	    $Lspacer=1          if (! defined $prot{"seq",$itWin} || 
				    $prot{"seq",$itWin} eq "!"    ||
				    ($itWin < $BEG) || ($itWin > $END) );

				# ---> conservation weight
				# no spacer
	    if (! $Lspacer){
				# normalCw residue
		if (defined $aa{$prot{"seq",$itWin}}){
		    push(@vecIn,int($par{"bitacc"}* 0.5*$prot{"cons",$itWin}));
		}
		else{	# unknown residue
		    push(@vecIn,0);
		}}
				# spacer
	    else {
		push(@vecIn,int($par{"bitacc"}*0.25));
	    }
	}
				# ------------------------------
				# global info from outside window
	foreach $vecGlob (@vecGlob){
	    push(@vecIn,int($par{"bitacc"}*$vecGlob));
	}

	$#vecDis=0;		# distance of window from ends
	if ($modeinLoc =~/dis/) {                              
	    &assVec_seqGlobDisN($itres,$winHalf);      # distance from N-term
	    &assVec_seqGlobDisC($itres,$winHalf,$END); # distance from C-term
	}
	foreach $vecDis  (@vecDis){
	    push(@vecIn,int($par{"bitacc"}*$vecDis));
	}
				# ------------------------------
				# security check
	return(&errSbr("itres=$itres, vecIn{NUMIN}=".$#vecIn." ne =$numinLoc, \n".
		       "beg=$BEG, end=$END, livel=$itlevel, itpar=$itpar, modein=$modeinLoc\n".
		       $errMsg,$SBR5)) if ($#vecIn != $numinLoc);

				# ------------------------------
				# write input vectors
				#      GLOBAL in:  @vecIn
				#      GLOBAL in:  @codeUnitIn1st
	($Lok,$msg)=
	    &vecInWrt($itres,$fhoutLoc,$numinLoc
		      );        return(&errSbrMsg("after vecInWrt ($itres)",$msg,$SBR5)) if (! $Lok); 
    }				# end of loop over residues for one break!
				# ------------------------------------------------------------

				# count up samples
    $ctSamTot+=$LEN;

    return(1,"ok $SBR5");
}				# end of assData_vecIn2ndAllXX

#===============================================================================
sub assVec_seqLocRes {
    local($itRes,$itWin,$BEG,$END,$numaaLoc)=@_;
    $[ =1 ;
#-------------------------------------------------------------------------------
#   assVec_seqLocRes            writes residue profile
#       in:                     $itWin=    current window position
#       in:                     $itRes=    current residue number
#       in:                     $BEG=      begin of current chain
#       in:                     $END=      end of current chain
#       in:                     $numaaLoc= 21
#                               
#       in GLOBAL:              $par{$kwd},  $kwd=<bitacc|verbForVec>
#       in GLOBAL:              $prot{<nins|nocc>,$it}
#                               
#       in GLOBAL:              @aaXprof=  database distribution of 20 AAs
#       in GLOBAL:              @aa21=     residue names (' ' for spacer)
#       in GLOBAL:              @aa=       residue names (no spacer)
#       in GLOBAL:              $aa{aa}=   1 for all 20 known residues
#                               
#       in && OUT GLOBAL:       $itVec=    counting vector components
#       in && OUT GLOBAL:       %vecIn{}
#                               
#-------------------------------------------------------------------------------
    $itVecTmp=$itVec;

				# --------------------------------------------------
				# spacer: also for before, after chain break
    if    (! defined $prot{"seq",$itWin} || 
	   $prot{"seq",$itWin} eq "!"    ||
	   ($itWin < $BEG)               ||
	   ($itWin > $END) ) {
	foreach $itaa (1 .. ($numaaLoc-1)){
	    ++$itVec;$vecIn{$itRes,$itVec}=0;          # all AAs to zero    i=1..20 =>   0 
	}
	++$itVec;$vecIn{$itRes,$itVec}=$par{"bitacc"}; # spacer to 1,       i=21    =>   1
    }
				# --------------------------------------------------
				# unknown residue
    elsif (! defined $aa{$prot{"seq",$itWin}}){
	foreach $itaa(1..($numaaLoc-1)){
	    ++$itVec;$vecIn{$itRes,$itVec}=            # all AAs to dbAve   i=1..20 => occ (0..1)
		int($par{"bitacc"}*$aaXprof[$itaa]); 
	}
	++$itVec;$vecIn{$itRes,$itVec}=0;              # spacer to 0        i=21    =>   0 
    }
				# --------------------------------------------------
    else {			# normal residue
	foreach $itaa(1..($numaaLoc-1)){
	    $aaTmp=$aa[$itaa];
	    ++$itVec;$vecIn{$itRes,$itVec}=            # all AAs to profVal i=1..20 => prof/100
		int($par{"bitacc"}*($prot{$aaTmp,$itWin}/100));
	}
	++$itVec;$vecIn{$itRes,$itVec}=0;              # spacer to 0        i=21    =>   0
    }
				# ------------------------------
				# final count
    $vecIn{"NUMIN"}=$itVec;
				# ------------------------------
    if ($par{"verbForVec"}){	# debug write
	$tmpWrt= sprintf("%-8s(%4d%3d%4d):","LocRes",$itRes,$itWin,$itRes);
	$ctTmp=0;
	foreach $itTmp (($itVecTmp+1)..$itVec){
	    ++$ctTmp;
	    $tmpWrt.= sprintf("|%1s%2d",$aa21[$ctTmp],$vecIn{$itRes,$itTmp}); }
	$tmpWrt.="\n";
	print $FHTRACE $tmpWrt; }
}				# end of assVec_seqLocRes

#===============================================================================
sub assVec_seqLocCons {
    local($itRes,$itWin,$BEG,$END)=@_;
    $[ =1 ;
#-------------------------------------------------------------------------------
#   assVec_seqLocCons           writes conservation weight
#       in:                     $itWin=    current window position
#       in:                     $itRes=    current residue number
#       in:                     $BEG=      begin of current chain
#       in:                     $END=      end of current chain
#                               
#       in GLOBAL:              $par{"bitacc|verbForVec"}
#       in GLOBAL:              $prot{<seq|cons>,$it}
#       in GLOBAL:              $aa{aa}=   1 for all 20 known residues
#                               
#       in && OUT GLOBAL:       $itVec=    counting vector components
#       in && OUT GLOBAL:       %vecIn{}
#                               
#-------------------------------------------------------------------------------
				# --------------------------------------------------
				# spacer= 0.25: also for before, after chain break
    if    (! defined $prot{"seq",$itWin} || 
	   $prot{"seq",$itWin} eq "!"    ||
	   ($itWin < $BEG)               ||
	   ($itWin > $END) ) {
	++$itVec;$vecIn{$itRes,$itVec}=int($par{"bitacc"}*0.25) ; }
				# --------------------------------------------------
				# unknown residue = 0
    elsif (! defined $aa{$prot{"seq",$itWin}}){
	++$itVec;$vecIn{$itRes,$itVec}=0    ; }
				# --------------------------------------------------
    else {			# normal residue = 0.5 * MaxHom weight
	++$itVec;$vecIn{$itRes,$itVec}=
            int($par{"bitacc"}* 0.5*$prot{"cons",$itWin}); }

				# ------------------------------
				# final count
    $vecIn{"NUMIN"}=$itVec;
				# ------------------------------
    if ($par{"verbForVec"}){	# debug write
	$tmpWrt=  sprintf("%-8s(%4d%3d%4d):","LocCons",$itRes,$itWin,$itRes);
	$tmpWrt.= sprintf("%1s=%4d ","c",$vecIn{$itRes,$itVec}); 
	$tmpWrt.="\n";
	print $FHTRACE $tmpWrt; }
}				# end of assVec_seqLocCons

#===============================================================================
sub assVec_seqLocNins {
    local($itRes,$itWin,$BEG,$END)=@_;
    $[ =1 ;
#-------------------------------------------------------------------------------
#   assVec_seqLocNins           writes number of insertions
#                  WATCH IT:    may exceed 100% ! (set back to 100!)
#                               
#       in:                     $itWin=    current window position
#       in:                     $itRes=    current residue number
#       in:                     $BEG=      begin of current chain
#       in:                     $END=      end of current chain
#                               
#       in GLOBAL:              $par{$kwd}, $kwd=<bitacc|verbForVec>
#       in GLOBAL:              $prot{<seq|nins|nocc>,$it}
#                               
#       in && OUT GLOBAL:       $itVec=    counting vector components
#       in && OUT GLOBAL:       %vecIn{}
#                               
#-------------------------------------------------------------------------------
				# --------------------------------------------------
				# spacer= 0: also for before, after chain break
    if    (! defined $prot{"seq",$itWin}     || 
	   $prot{"seq",$itWin} eq "!"        ||
	   ($itWin < $BEG)                   || 
	   ($itWin > $END)                   ||
	   ! defined $prot{"nocc",$itWin}    ||
	   $prot{"nocc",$itWin} <=0 ) {
	++$itVec;$vecIn{$itRes,$itVec}=0;}
				# --------------------------------------------------
    else {			# normal residue = nins/nocc
	++$itVec;$vecIn{$itRes,$itVec}=
            int($par{"bitacc"}*($prot{"nins",$itWin}/$prot{"nocc",$itWin}));
				# note: may exceed 100% (by definition!)
	$vecIn{$itRes,$itVec}=$par{"bitacc"} if ($vecIn{$itRes,$itVec} > $par{"bitacc"}); }
	    
				# ------------------------------
				# final count
    $vecIn{"NUMIN"}=$itVec;
				# ------------------------------
    if ($par{"verbForVec"}){	# debug write
	$tmpWrt=  sprintf("%-8s(%4d%3d%4d):","LocNins",$itRes,$itWin,$itRes);
	$tmpWrt.= sprintf("%1s=%4d ","i",$vecIn{$itRes,$itVec}); 
	$tmpWrt.="\n";
	print $FHTRACE $tmpWrt; }
}				# end of assVec_seqLocNins

#===============================================================================
sub assVec_seqLocNdel {
    local($itRes,$itWin,$BEG,$END)=@_;
    $[ =1 ;
#-------------------------------------------------------------------------------
#   assVec_seqLocNdel           writes number of deletions
#                  WATCH IT:    may exceed 100% ! (set back to 100!)
#                               
#       in:                     $itWin=    current window position
#       in:                     $itRes=    current residue number
#       in:                     $BEG=      begin of current chain
#       in:                     $END=      end of current chain
#                               
#       in GLOBAL:              $par{$kwd}, $kwd=<bitacc|verbForVec>
#       in GLOBAL:              $prot{<seq|ndel|nocc>,$it}
#                               
#       in && OUT GLOBAL:       $itVec=    counting vector components
#       in && OUT GLOBAL:       %vecIn{}
#-------------------------------------------------------------------------------
				# --------------------------------------------------
				# spacer= 0: also for before, after chain break
    if    (! defined $prot{"seq",$itWin}     || 
	   $prot{"seq",$itWin} eq "!"        ||
	   ($itWin < $BEG)                   ||
	   ($itWin > $END)                   ||
	   ! defined $prot{"nocc",$itWin}    ||
	   $prot{"nocc",$itWin} <=0 ) {
	++$itVec;$vecIn{$itRes,$itVec}=0;}
				# --------------------------------------------------
    else {			# normal residue = ndel/nocc
	++$itVec;$vecIn{$itRes,$itVec}=
            int($par{"bitacc"}*($prot{"ndel",$itWin}/$prot{"nocc",$itWin}));
				# note: may exceed 100% (by definition!)
	$vecIn{$itRes,$itVec}=$par{"bitacc"} if ($vecIn{$itRes,$itVec} > $par{"bitacc"}); }

				# ------------------------------
				# final count
    $vecIn{"NUMIN"}=$itVec;
				# ------------------------------
    if ($par{"verbForVec"}){	# debug write
	$tmpWrt=  sprintf("%-8s(%4d%3d%4d):","LocNdel",$itRes,$itWin,$itRes);
	$tmpWrt.= sprintf("%1s=%4d ","d",$vecIn{$itRes,$itVec}); 
	$tmpWrt.="\n";
	print $FHTRACE $tmpWrt; }
}				# end of assVec_seqLocNdel


#===============================================================================
sub assVec_strLocStr {
    local($itRes,$itWin,$itVec) = @_ ;
    $[ =1 ;
#-------------------------------------------------------------------------------
#   assVec_strLocStr            writes prediction: iwin,prob[1..numout]
#                               
#       in GLOBAL:              $par{"bitacc|verbForVec"}
#                               
#       in GLOBAL:              from &nnRdOut
#       in GLOBAL:              %nnout{"NROWS"} = 1..itsam
#       in GLOBAL:              $nnout{"iwin","$itWin"} itout=1,..,NUMOUT = 
#                                    $bitacc * out(i) / sum over all out
#                                    NOTE:     integers
#       in GLOBAL:              $nnout{"outNum"}  NUMOUT
#                               
#       in:                     $itRes=    current residue number
#       in:                     $itWin=    current window position
#       in:                     $itVec=    counting vector components
#-------------------------------------------------------------------------------
				# only for dbg write
    $itVecTmp=$itVec;
				# --------------------------------------------------
				# spacer: also for before, after chain break
    if    (! defined $nnout{"iwin",$itWin} || 
	   ($itWin < 1) || ($itWin > $nnout{"NROWS"}) ) {
	foreach $itout (1..$nnout{"outNum"}){
	    ++$itVec;$vecIn{$itRes,$itVec}=0; # all str to zero        i=1..3  =>   0 
	}
	++$itVec;$vecIn{$itRes,$itVec}=
	    $par{"bitacc"};                   # spacer to 1,           i=4     =>   100
    }
				# --------------------------------------------------
    else {			# normal residue prediction
	foreach $itout (1..$nnout{"outNum"}){
	    ++$itVec;$vecIn{$itRes,$itVec}=   # all AAs to prediction  i=1..3  =>   prof
		$nnout{"prob",$itout,$itWin};
	}
	++$itVec;$vecIn{$itRes,$itVec}=0;     # spacer to 0             i=4    =>   0
    }
				# ------------------------------
    if ($par{"verbForVec"}){	# debug write
	$tmpWrt= sprintf("%-8s(%4d%3d%4d):","LocStr",$itRes,$itWin,$itRes);
	$ctTmp=0;
	foreach $itTmp (($itVecTmp+1)..$itVec){
	    ++$ctTmp;
	    $#tmp=0;foreach $itout (1..$nnout{"outNum"}){push(@tmp,$nnout{"prob",$itout,$itWin});}
	    
	    $tmpWrt.= sprintf("|"."%3s" x $nnout{"outNum"} . "%2d",
			      @tmp,$vecIn{$itRes,$itTmp});
	}
	    
	$tmpWrt.="\n";
	print $FHTRACE $tmpWrt; }
    return($itVec);
}				# end of assVec_strLocStr

#===============================================================================
sub assVec_strLocWin {
    local($itRes,$itWin,$itVec) = @_ ;
    $[ =1 ;
#-------------------------------------------------------------------------------
#   assVec_strLocWin            writes prediction: only winner
#                               
#       in GLOBAL:              $par{"bitacc|verbForVec"}
#                               
#       in GLOBAL:              from &nnRdOut
#       in GLOBAL:              %nnout{"NROWS"} = 1..itsam
#       in GLOBAL:              $nnout{"iwin","$itWin"} itout=1,..,NUMOUT = 
#                                    $bitacc * out(i) / sum over all out
#                                    NOTE:     integers
#       in GLOBAL:              $nnout{"outNum"}  NUMOUT
#                               
#       in:                     $itRes=    current residue number
#       in:                     $itWin=    current window position
#       in:                     $itVec=    counting vector components
#                               
#-------------------------------------------------------------------------------
				# only for dbg write
    $itVecTmp=$itVec;
				# --------------------------------------------------
				# spacer: also for before, after chain break
    if    (! defined $nnout{"iwin",$itWin} || 
	   ($itWin < 1) || ($itWin > $nnout{"NROWS"}) ) {
	foreach $itout (1..$nnout{"outNum"}){
	    ++$itVec;$vecIn{$itRes,$itVec}=0; # all str to zero        i=1..3  =>   0 
	}
    }
				# --------------------------------------------------
    else {			# normal residue prediction
				# winner to 100, all others to 0
	foreach $itout (1..$nnout{"outNum"}){
	    $tmp=0;
	    $tmp=$par{"bitacc"} if ($itout == $nnout{"iwin",$itWin});
	    ++$itVec;$vecIn{$itRes,$itVec}=$tmp; 
	}
    }
				# ------------------------------
    if ($par{"verbForVec"}){	# debug write
	$tmpWrt= sprintf("%-8s(%4d%3d%4d):","locWin",$itRes,$itWin,$itRes);
	$ctTmp=0;
	foreach $itTmp (($itVecTmp+1)..$itVec){
	    ++$ctTmp;
	    $tmpWrt.= sprintf("|"."%2s %2d",
			      $nnout{"iwin",$itWin},$vecIn{$itRes,$itTmp});
	}
	$tmpWrt.="\n";
	print $FHTRACE $tmpWrt; }
    return($itVec);
}				# end of assVec_strLocWin

#===============================================================================
sub assVec_strLocRel {
    local($itRes,$itWin,$itVec) = @_ ;
    $[ =1 ;
#-------------------------------------------------------------------------------
#   assVec_strLocRel            writes reliability index of prediction
#                               
#       in GLOBAL:              $par{"bitacc|verbForVec"}
#                               
#       in GLOBAL:              from &nnRdOut
#       in GLOBAL:              %nnout{"NROWS"} = 1..itsam
#       in GLOBAL:              $nnout{"ri","$itWin"} itout=1,..,NUMOUT = 
#       in GLOBAL:              $nnout{"outNum"}  NUMOUT
#                               
#       in:                     $itRes=    current residue number
#       in:                     $itWin=    current window position
#       in:                     $itVec=    counting vector components
#-------------------------------------------------------------------------------
				# only for dbg write
    $itVecTmp=$itVec;
    
    $ri=0;
				# unit: bitacc * ri / 10
    $ri= int($par{"bitacc"} * ($nnout{"ri",$itWin}/10)) 
	if (defined $nnout{"ri",$itWin});

    ++$itVec;$vecIn{$itRes,$itVec}=$ri;

				# ------------------------------
    if ($par{"verbForVec"}){	# debug write
	$tmpWrt= sprintf("%-8s(%4d%3d%4d):|%3d\n","locRel",$itRes,$itWin,$itRes,$ri);
	print $FHTRACE $tmpWrt; }
    return($itVec);
}				# end of assVec_strLocRel

