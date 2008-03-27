#!/usr/bin/perl
##! /usr/bin/perl -w
##! /usr/sbin/perl -w
##! /usr/pub/bin/perl -w
#------------------------------------------------------------------------------#
#	Copyright				Sep,    	1998	       #
#	Burkhard Rost		rost@LION-ag.de,rost@EMBL-heidelberg.de	       #
#	Wilckensstr. 15		http://www.embl-heidelberg.de/~rost/	       #
#	D-69120 Heidelberg						       #
#				version 0.1   	Sep,    	1998	       #
#------------------------------------------------------------------------------#
#                                                                              #
# description:                                                                 #
#    PERL library with routines related to 'my' stuff:                         #
#    -  PHD|TOPITS|PP|GLOBE                                                    #
#                                                                              #
#------------------------------------------------------------------------------#
# 
# 
# -----------------------------------------------------------------------------# 
#                               ---------------------
#   br                          internal subroutines:
#                               ---------------------
# 
#   evalsecTableqils2syn        greps the final summary from TABLEQILS (xevalsec.f)
#   evalseg_oneprotein          evaluates the pred accuracy as HTM segments
#   filter_oneprotein           reads .pred files
#   filter1_change              ??? (somehow to do with filter_oneprotein)
#   filter1_rel_lengthen        checks in N- and C-term, whether rel > cut
#   filter1_rel_shorten         checks in N- and C-term, whether rel > cut
#   getPhdSubset                subset from string with PHDsec|acc|htm + rel index
#   globeFuncFit                length to number of surface molecules fitted to PHD error 
#   globeFuncJoinPhdSeg         applies ad-hoc rule to join PHDglobe  and SEG
#   globeFuncJoinPhdSegIni      initialises the function used to apply the rule
#   globeOne                    1
#   globeOneIni                 interprets input arguments
#   globeOneCombi               runs SEG and combines results with PHDglobeNorm
#   globeProb                   translates normalised diff in exp res to prob
#   globeProbIni                sets the values for the probability assignment
#   globeRd_phdRdb              read PHD rdb file with ACC
#   globeWrt                    writes output for GLOBE
#   phdAliWrt                   converts PHD.rdb to SAF format (including ali)
#   phdHtmIsit                  returns best HTM
#   phdHtmGetBest               returns position (begin) and average val for best HTM
#   phdPredWrt                  writes into file readable by EVALSEC|ACC
#   phdRdbMerge                 manages merging two PHD *.rdb files ('name'= acc + sec + htm)
#   phdRdbMergeDef              sets defaults for phdRdbMerg
#   phdRdbMergeDo               merging two PHD *.rdb files ('name'= acc + sec)
#   phdRdbMergeHdr              writes the merged RDB header
#   phdRun                      runs all 3 FORTRAN programs PHD
#   phdRun1                     runs the FORTRAN program PHD once (sec XOR acc XOR htm) 
#   phdRunIniFileNames          assigns names to intermediate files for FORTRAN PHD
#   phdRunPost1                 
#   phdRunWrt                   merges 2-3 RDB files (sec,acc,htm?)
#   ppHsspRdExtrHeader          extracts the summary from HSSP header (for PP)
#   ppStripRd                   reads the new strip file generated for PP
#   ppTopitsHdWrt               writes the final PP TOPITS output file
#   ranGetString                produces a random string 
#   ranPickFast                 selects succesion of numbers 1..$numSamLoc at 
#   ranPickGood                 selects succesion of numbers 1..$numSamLoc at 
#   rdbphd_to_dotpred           converts RDB files of PHDsec,acc,htm (both/3)
#   rdbphd_to_dotpred_getstring transform $rdb{"osec","1..n"} to $STRING{"osec"}
#   rdbphd_to_dotpred_getsubset assigns subsets:
#   rdbphd_to_dotpred_head_htmtop writes the header for htmtop
#   read_exp80                  reads a secondary structure 80lines file
#   read_sec80                  reads a secondary structure 80lines file
#   topitsCheckLibrary          truncates fold library to existing files
#   topitsMakeMetric            makes the BIG MaxHom metric to compare sequence
#   topitsRunMaxhom             runs MaxHom in TOPITS fashion (no profile)
#   topitsWrtOwn                writes the TOPITS format
#   topitsWrtOwnHdr             writes the HEADER for the TOPITS specific format
#   write80_data_prepdata       writes input into array called @write80_data
#   write80_data_preptext       writes input into array called @write80_data
#   write80_data_do             writes hssp seq + sec str + exposure
#   wrt_dssp_phd                writes DSSP format for
#   wrt_phd_header2pp           header for phd2pp
#   wrt_phd_rdb2col             writes out the PP send format
#   wrt_phd_rdb2pp              writes out the PP send format
#   wrt_phd2msf                 converts HSSP to MSF and merges the PHD prediction
#   wrt_phdpred_from_string     write body of PHD.pred files from global array %STRING{}
#   wrt_phdpred_from_string_htm body of PHD.pred files from global array %STRING{} for HTM
#   wrt_phdpred_from_string_htm_header 
#   wrt_phdpred_from_string_htmHdr writes the header for PHDhtm ref and top
#   wrt_ppcol                   writes out the PP column format
#   wrt_strip_pp2               writes the final PP output file
#   wrtHsspHeaderTopBlabla      writes header for HSSP RDB (or simlar) output file
#   wrtHsspHeaderTopData        write DATA for new header of HSSP (or simlar)
#   wrtHsspHeaderTopFirstLine   writes first line for HSSP+STRIP header (perl-rdb)
#   wrtHsspHeaderTopLastLine    writes last line for top of header (to recognise next)
# 
# -----------------------------------------------------------------------------# 
#                               ---------------------
#   br                          external subroutines:
#                               ---------------------
# 
#   call from br:               getPhdSubset,globeFuncFit,globeFuncJoinPhdSeg,globeFuncJoinPhdSegIni
#                               globeOneCombi,globeOneIni,globeProb,globeProbIni,globeRd_phdRdb
#                               phdHtmGetBest,phdHtmIsit,phdRdbMerge,phdRdbMergeDef
#                               phdRdbMergeDo,phdRdbMergeHdr,phdRun1,phdRunIniFileNames
#                               phdRunPost1,phdRunWrt,rdbphd_to_dotpred_getstring,rdbphd_to_dotpred_getsubset
#                               rdbphd_to_dotpred_head_htmtop,topitsWrtOwnHdr,wrt_phd_header2pp
#                               wrt_phdpred_from_string,wrt_phdpred_from_string_htm
#                               wrt_phdpred_from_string_htm_header
# 
#   call from comp:             get_min
# 
#   call from file:             is_hssp,is_hssp_empty,is_rdb_acc,is_rdb_htm,is_rdb_htmref
#                               is_rdb_htmtop,is_rdb_sec,open_file,rdRdbAssociative
#                               rdRdbAssociativeNum,rd_rdb_associative,read_rdb_num2
# 
#   call from formats:          convHssp2msf,fastaWrt,msfWrt,safWrt
# 
#   call from hssp:             hsspRdAli,hsspRdHeader,hsspRdSeqSecAccOneLine,hsspRdStripAndHeader
#                               hsspRdStripHeader
# 
#   call from molbio:           segInterpret,segRun
# 
#   call from prot:             exposure_project_1digit
# 
#   call from scr:              errSbr,errSbrMsg,is_rdbf,myprt_npoints
# 
#   call from sys:              run_program,sysCpfile,sysDate,sysRunProg
# 
#   call from system:            
#                               $exePhd2Msf $arg$exePhd2Msf $arg
#                               echo '$tmpWrt' >> stat-htm-glob.tmp
#                               echo '$tmpWrt' >> stat-htm-htm.tmp
#                               echo '$tmpWrt' >> stat-htm-htm.tmpecho '$tmpWrt' >> stat-htm-glob.tmp
# 
#   call from missing:           
#                               ctime
#                               localtime
#                               phd_htmfil
#                               phd_htmref
#                               phd_htmtop
# 
# 
# -----------------------------------------------------------------------------# 
# 
#===============================================================================
sub evalsecTableqils2syn {
    local($fileInLoc,$optLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   evalsecTableqils2syn        greps the final summary from TABLEQILS (xevalsec.f)
#       in:                     $fileInLoc
#       in:                     $optLoc='noClass|noSetAve|noCorr'
#       out:                    1|0,msg, $tmpWrt (sprintf)
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."evalsecTableqils2syn";$fhinLoc="FHIN_"."evalsecTableqils2syn";
				# ------------------------------
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
#    return(&errSbr("not def !"))          if (! defined $);

    return(&errSbr("miss in file '$fileInLoc'!"))  if (! -e $fileInLoc);

    $LdoClass=1;		# do include statistics on class, content
    $LdoCorr=1;			# do include Matthews correlation
    $LdoSetAve=1;		# do include averages over many proteins

    $LdoClass=0                 if (defined $optLoc && $optLoc =~ /noClass/);
    $LdoCorr=0                  if (defined $optLoc && $optLoc =~ /noCorr/);
    $LdoSetAve=0                if (defined $optLoc && $optLoc =~ /noSetAve/);
				# ------------------------------
				# open file
    open($fhinLoc,$fileInLoc) || return(&errSbr("fileInLoc=$fileInLoc, not opened"));
				# ------------------------------
    while (<$fhinLoc>) {	# read until ' --- \s for all '
	$tmp=$_;
	last if ($_=~/^ \-+\s+for all\s+/); }
				# build up wrt
    $tmpWrt1=      "$tmp";
				# ------------------------------
    while (<$fhinLoc>) {	# read until blank line
	last if ($_!~/^ [\+\|]/); 
	$tmpWrt1.= "$_"; }
				# ------------------------------
    while (<$fhinLoc>) {	# read until correlation
	$_=~s/\n//g; $rd=$_;
	if ($rd=~/^.*Q3mean =\s+([0-9\.]+)\s+/){
	    $aveProtQ3=$1;
	    next; }
	if ($rd=~/^.*sqrt\( Q3var \) =\s+([0-9\.]+)\s+/){
	    $aveProtSig=$1;
	    next; }
	$tmp=$rd; $tmp=~s/^\s\-+\s*//g;
	next if (length($tmp)<1);
	if ($rd=~/all.* contav .([HE])\s*=\s*([0-9\.]+)\s.*=\s*([0-9\.]+)/){
	    if    ($1 eq "H"){
		$contHdel=$2; $contHsig=$3; }
	    elsif ($1 eq "E"){
		$contEdel=$2; $contEsig=$3; }
	    next; }
	last if ($rd=~/Correlation coeffi/); }

    $tmpWrt2=      "$rd\n"; 
				# ------------------------------
    while (<$fhinLoc>) {	# read class
	$_=~s/\n//g; $rd=$_;
	$tmp=$rd; $tmp=~s/^\s\-+\s*//g;
	next if (length($tmp)<1);
	$tmpWrt2.= "$rd\n"; }
    close($fhinLoc);
				# ------------------------------
				# process
    $tmpWrt= $tmpWrt2;
    $tmpWrt.=$tmpWrt1;
				# overall table 
    @tmp=split(/\n/,$tmpWrt1);
    foreach $tmp (@tmp){
	if ($tmp =~ /\|                                    \|(.*)$/){
	    $tmp=$1;
	    $tmp=~s/\|                   \|.*$//g;
	    $tmp=~s/\|/ /g;
	    @num=split(/\s+/,$tmp);
	    @cor[1..3]=@num[1..3];
	    $q3=$num[4]; 
	    next; }
	if ($tmp =~ /^\s*\|\s*SOV\s*\|\s*(.+)$/){
	    $tmp=$1; $tmp=~s/\|/ /g;
	    $tmp=~s/^\s*|\s*$//g;
	    @num=split(/\s+/,$tmp);
	    $sovObs=$num[4];
	    $sovPrd=$num[8];
	    $info=$num[9]; $info=~s/\s([0-9\.]+)\s*.*$/$1/g;
	}}
				# class acc
    @tmp=split(/\n/,$tmpWrt2);
    foreach $tmp (@tmp){
	if ($tmp=~/.*SUM\s*\|\s*(.*)$/){
	    $tmp=$1; $tmp=~s/\|/ /g;
	    $tmp=~s/^\s*|\s*$//g;
	    @num=split(/\s+/,$tmp);
	    $classObs=$num[4]; $classPrd=$num[5];
	}
    }
				# ------------------------------
				# formats
    $fcor= "%5.2f,%5.2f,%5.2f";
    $fcont="%5.1f,%5.1f";
				# ------------------------------
				# sec str content
    if ($LdoClass) {
	$tmpWrt.=sprintf("%-30s %5.1f,%5.1f\n",       
			 "SYN Q4class  obs,prd:",$classObs,$classPrd);
	$tmpWrt.=sprintf("%-30s $fcont ($fcont)\n",   "SYN DcontH,E   (sig):",
			 $contHdel,$contEdel,$contHsig,$contEsig);}
				# ------------------------------
				# protein averages
    if ($LdoCorr) {
	$tmpWrt.=sprintf("%-30s %6.2f %-4s ($fcor)\n",
			 "SYN I     (corH,E,L):",$info," ",@cor);}
    $tmpWrt.=    sprintf("%-30s %5.1f,%5.1f\n",       "SYN SOV      obs,prd:",
			 $sovObs,$sovPrd);
    if ($LdoSetAve) {
	$tmpWrt.=sprintf("%-30s %5.1f %-5s (%5.1f)\n","SYN Q3prot     (sig):",
			 $aveProtQ3," ",$aveProtSig);}
    $tmpWrt.=    sprintf("%-30s %5.1f \n",            "SYN Q3res           :",$q3);
		     
    return(1,"ok $sbrName",$tmpWrt);
}				# end of evalsecTableqils2syn 

#===============================================================================
sub evalseg_oneprotein {
    local ($sec,$prd)=@_;
    local ($ctseg, $ct, $tmp, $it, $it2, $sym, $symprev, $ctnotloop);
    local (@seg, @ptr, @segbeg);
    $[ =1;
#--------------------------------------------------
#   evalseg_oneprotein          evaluates the pred accuracy as HTM segments
#   GLOBAL:
#   out:   $NOBS, $NOBSH, $NOBSL, $NPRD, $NPRDH, $NPRDL
#          $NCP, $NCPH, $NCPL, $NUP, $NOP, $NLONG
#--------------------------------------------------

#   ----------------------------------------
#   extract segments into @seg
#   ----------------------------------------
    $ctseg=0; $symprev=")"; $#seg=$#ptr=$#segbeg=$ctnotloop=0;
    for($it=1;$it<=length($prd);++$it) {
        $sym=substr($prd,$it,1); 
        if ( $sym ne $symprev ) { 
            ++$ctseg; $symprev=$sym;
            $seg[$ctseg]=$sym; $ptr[$ctseg]="$it"."-"; $segbeg[$ctseg]=$it;
            if ($sym ne " ") { ++$ctnotloop; }}
	else { $seg[$ctseg].=$sym; $ptr[$ctseg].="$it"."-";}}

#   ----------------------------------------
#   count observed segments
#   ----------------------------------------
    @atmp1=split(/\s+/,$sec); @atmp2=split(/H+/,$sec);

#   --------------------
#   splice empty
    $#atmp=0;
    for($it=1;$it<=$#atmp1;++$it) {if (length($atmp1[$it])>=1) {push(@atmp,$atmp1[$it]);}}
    $#atmp1=0;@atmp1=@atmp;

    $#atmp=0;
    for($it=1;$it<=$#atmp2;++$it) {if (length($atmp2[$it])>=1) {push(@atmp,$atmp2[$it]);}}
    $#atmp2=0;@atmp2=@atmp;
	
#   --------------------
#   counts
    $NOBS=$NPRDL=0;		# satisfy -w
    $NOBSH=$#atmp1;$NOBSL=$#atmp2;  $NOBS=$NOBSH+$NOBSL;
    $NPRDH=$ctnotloop;$NPRD=$#seg;  $NPRDL=$NPRD-$NPRDH;

#   ----------------------------------------
#   count correct, over-, underprediction
#   and segments merged (n->1)
#   ----------------------------------------
    $NCP=$NUP=$NOP=$NLONG=$NCPH=$NCPL=0;
    for ($it=1;$it<=$#seg;++$it) {

#       ------------------------------
#       predicted helix
	if ($seg[$it]=~/H/) {
	    $tmp=substr($sec,$segbeg[$it],length($seg[$it]));
#           -------------------------
#           correctly predicted helix
	    if ( ($tmp=~/HHH/)&&($tmp!~/H+\s+H+/) ) {++$NCP;++$NCPH;}
		
#           -------------------------
#           too long helix correct 
	    elsif ( $tmp=~/H+\s+H+/ ) {++$NLONG;}

#           ---------------------
#           over-predicted helix
	    else {++$NOP;--$NCP;--$NCPL;} }

#       ------------------------------
#       predicted non-helix
	else {
	    $tmp=substr($sec,$segbeg[$it],length($seg[$it]));
#           ------------------------                   #----------------------
#           correctly predicted loop                   # under-predicted helix
	    if ($tmp!~/HHHHHHHHHHH/) {++$NCP;++$NCPL;} else{++$NUP;} }
    }
}                               # end of evalseg_oneprotein

#===============================================================================
sub filter_oneprotein {
    local ($cutshort,$cutshort_single,$cutrel_single,$cutrelav_single,
           $splitlong,$splitlong2,$splitrel,$splitmaxflip,$shorten_len,$shorten_rel,
	   $PRD,$REL)=@_;
				# called by phd_htmfil.pl only!
    local ($ct,$tmp,$it,$it2,$itsplit,@ptr,$Lsplit,$splitloc);
    $[=1;
#--------------------------------------------------------------------------------
#   filter_oneprotein           reads .pred files
#       in GLOBAL:              ($PRD, $REL)
#       out GLOBAL:             $LNOT_MEMBRANE, $FIL, $RELFIL,
#--------------------------------------------------------------------------------
				# --------------------------------------------------
    @symh=("H","T","M");	# extract segments
    foreach $symh (@symh){
	%seg=&get_secstr_segment_caps($PRD,$symh);
	if ($seg{"$symh","NROWS"}>=1) {$tmp=$symh;
				       last;}}
    $symh=$tmp;			# --------------------------------------------------
				# none found? 
    if ((defined $symh) && (defined $seg{"$symh","NROWS"})) {
	$nseg=$seg{"$symh","NROWS"};
	if ($nseg<1) {
	    return(1,$PRD,$REL);} }
    else {
	return(1,$PRD,$REL);}
    $nres=length($PRD);		# ini
    $#Lflip=0;foreach $it(1..$nres){$Lflip[$it]=0;}
				# --------------------------------------------------
				# first long helices with rel ="000" split!
    $prdnew=$PRD;
    foreach $ct (1..$nseg) {
	$len=$seg{"$symh","end","$ct"}-$seg{"$symh","beg","$ct"}+1;
	if ( $len > $splitlong2 ) {
	    foreach $it ($seg{"$symh","beg","$ct"} .. 
			 ($seg{"$symh","end","$ct"}-$splitlong) ) {
		if (substr($REL,$it,3) eq "000") {
		    foreach $it2 ($it .. ($it+2)) {
			$Lflip[$it2]=1;}
		    substr($prdnew,$it,3)="LLL";}}}}
    if ($prdnew ne $PRD) {	# redo
	%seg=&get_secstr_segment_caps($prdnew,$symh);}
    $nseg=$seg{"$symh","NROWS"};
				# --------------------------------------------------
				# delete all < 11 , store len
				# --------------------------------------------------
    $#ptr_ok=0;
    foreach $ct (1..$nseg) {
	$seg{"len","$ct"}=($seg{"$symh","end","$ct"}-$seg{"$symh","beg","$ct"}+1);
				# first shorten if < 17
	if (($nseg>1) && ($seg{"len","$ct"}<$cutshort_single)){
	    $Ncap=$seg{"$symh","beg","$ct"};
	    $Ccap=$seg{"$symh","end","$ct"};
	    ($Ntmp,$Ctmp)=
		&filter1_rel_shorten($REL,($shorten_rel-1),$Ncap,$Ccap,$shorten_len);
	    $len=$Ctmp-$Ntmp+1;
	    if ($len<$cutshort) {
		foreach $it2 ( $Ncap .. $Ccap ){
		    $Lflip[$it2]=1;}} 
	    else {
		push(@ptr_ok,$ct);}}
	elsif ($seg{"len","$ct"}>$cutshort){
	    push(@ptr_ok,$ct);}}
    if ($#ptr_ok<1){
	print "********* HTMfil: filter_one_protein: no region > $cutshort\n";
	return(1,$PRD,$REL);}
				# --------------------------------------------------
				# only one and < 17?
				# --------------------------------------------------
    if ($#ptr_ok == 1) {
	$pos=$ptr_ok[1];
	$len=$seg{"len","$pos"};
	if ($len<$cutshort_single){
	    $Ncap=$seg{"$symh","beg","$pos"};
	    $Ccap=$seg{"$symh","end","$pos"};
	    $ave=0;		# average reliability
	    foreach $it ( $Ncap .. $Ccap){$ave+=substr($REL,$it,1);}
	    $ave=$ave/$len;	# average reliability > thresh -> elongate
	    if ($ave>=$cutrelav_single) { # add no more than 2 = HARD coded
				# add to N and C-term
		($Ntmp,$Ctmp)=
		    &filter1_rel_lengthen($REL,$cutrel_single,$Ncap,$Ccap,2);
		$Lchange=
		    &filter1_change(); # all GLOBAL
#		    &filter1_change($pos); # all GLOBAL
		if ($Lchange){
		    $seg{"$symh","beg","$pos"}=$Ncap;
		    $seg{"$symh","end","$pos"}=$Ccap;}}
	    else {
		print "********* HTM: filter_one_protein: single region, too short ($len)\n";
		return(1,$PRD,$REL);} }}
				# --------------------------------------------------
				# too long segments: shorten, split, ..
				# --------------------------------------------------
    foreach $it (@ptr_ok){
	$len=$seg{"len","$it"};
	$Ncap=$seg{"$symh","beg","$it"};
	$Ccap=$seg{"$symh","end","$it"};
				# ----------------------------------------
				# is it too long ? -> first try to shorten
	if ( ($len > 2*$splitlong) || ($len >= $splitlong2) ) {
				# cut fro N and C-term
	    ($Ntmp,$Ctmp)=
		&filter1_rel_shorten($REL,$shorten_rel,$Ncap,$Ccap,$shorten_len);
	    $Lchange=
		&filter1_change(); # all GLOBAL
#		&filter1_change($it); # all GLOBAL
	    if ($Lchange) {
		$len=$Ccap-$Ncap+1;} 
	}
				# ----------------------------------------
                                # still too long ? -> now split 
	$Lsplit=0;
                                # direct
	if    ( $len > ($splitlong+$splitlong2) ) {
	    $Lsplit=1;$splitloc=$splitlong; }
                                # only two segments => different cut-off
	elsif ( $len > $splitlong2 ) {
	    $Lsplit=1;$splitloc=$len/2; }
				# ----------------------------------------
                                # do split the HAIR
	if ($Lsplit) {
	    $splitN=int($len/$splitloc);
				# correction 9.95: add if e.g. > 50+11, eg. 65->3 times
	    if ($len>($splitN*$splitloc)+$cutshort_single){++$splitN;} # 9.95
				# correction 9.95: one less eg. > 100 , 
				#                  now: =4 times, but 100< 3*25+36 -> 4->3
	    if ( ($splitN>3) && ($len<($splitN-2)*$splitlong+$splitlong2+17) ) {
		--$splitN;}
	    if ($splitN>1){
		$splitL=int($len/$splitN);
				# --------------------
                                # loop over all splits
				# --------------------
		foreach $itsplit (1..($splitN-1)) {
		    $pos=$Ncap+$itsplit*$splitL; 
		    $min=substr($REL,$pos,1);
                                # in area +/-3 around split lower REL?
		    foreach $it2 (($pos-3)..($pos+3)){
			if (substr($REL,$it2,1)<$min){$min=substr($REL,$it2,1);
						      $pos=$it2;}}	
                                # flip 1,2, or 3 residues?
		    foreach $it2 (($pos-$splitmaxflip)..($pos+$splitmaxflip)){
			if   ( ($it2==$pos-1)||($it2==$pos)||($it2==$pos+1)) { 
			    $Lflip[$it2]=1; }
			elsif(substr($REL,$it2,1)<$splitrel){
			    $Lflip[$it2]=1;}} 
		}}		# end loop over splits
	}
    }				# end of loop over all HTM's
				# ----------------------------------------
				# now join segments to filtered version
    $PRD=~s/ |E/L/g;
    $FIL="";
    foreach $it (1..$nres) {
	if (! $Lflip[$it]) { 
	    $FIL.=substr($PRD,$it,1);}
	else {
	    if (substr($PRD,$it,1) eq $symh){
		$FIL.="L";}
	    else {
		$FIL.=$symh;}}}
				# ----------------------------------------
				# correct reliability index
    $RELFIL="";
    for ($it=1;$it<=length($FIL);++$it) {
	if (substr($FIL,$it,1) ne substr($PRD,$it,1)) {$RELFIL.="0";}
	else {$RELFIL.=substr($REL,$it,1);} }

    return(0,$FIL,$RELFIL);
}                               # end of filter_oneprotein

#===============================================================================
sub filter1_change {
    $[ =1 ;
#--------------------------------------------------------------------------------
#   filter1_change              ??? (somehow to do with filter_oneprotein)
#--------------------------------------------------------------------------------
    $Lchanged=0;  
    if    ($Ntmp < $Ncap){ 
	$Lchanged=1;
	foreach $_( $Ntmp .. ($Ncap-1)){
	    $Lflip[$_]=1; } }
    elsif ($Ntmp > $Ncap){ 
	$Lchanged=1;
	foreach $_( $Ncap .. ($Ntmp-1) ){
	    $Lflip[$_]=1; } }
    if    ($Ctmp < $Ccap){ 
	$Lchanged=1;
	foreach $_( ($Ctmp+1) .. $Ccap ){
	    $Lflip[$_]=1; } }
    elsif ($Ctmp > $Ccap){ 
	$Lchanged=1;
	foreach $_( ($Ccap+1) .. $Ctmp){
	    $Lflip[$_]=1; } }
    if ($Lchanged)     {	# if changed update counters
	$Ncap=$Ntmp;
	$Ccap=$Ctmp;}
    return($Lchanged);
}				# end of filter1_change

#===============================================================================
sub filter1_rel_lengthen {
    local ($rel,$cut,$Ncap,$Ccap,$nmax) = @_ ; local ($num,$ct);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   filter1_rel_lengthen        checks in N- and C-term, whether rel > cut
#--------------------------------------------------------------------------------
    $ct=$Ncap-1;		# Ncap
    $num=0;
    while ((defined substr($rel,$ct,1)) && 
	   (substr($rel,$ct,1)<$cut)){
	++$num;
	$Ncap=$ct; 
	last if ($num==$nmax);	# not more than nmax changes
	--$ct;}
    $num=0;
    $ct=$Ccap+1;	# Ccap
    while ((defined substr($rel,$ct,1)) && 
	   (substr($rel,$ct,1)<$cut)){
	++$num;
	$Ccap=$ct; 
	last if ($num==$nmax);	# not more than nmax changes
	++$ct;}
    return($Ncap,$Ccap);
}				# end of filter1_rel_lengthen

#===============================================================================
sub filter1_rel_shorten {
    local ($rel,$cut,$Ncap,$Ccap,$nmax) = @_ ; local ($num,$ct);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   filter1_rel_shorten         checks in N- and C-term, whether rel > cut
#--------------------------------------------------------------------------------
    $ct=$Ncap;			# Ncap
    $num=0;
    while ((defined substr($rel,$ct,1)) && 
	   (substr($rel,$ct,1)<$cut)){
	++$num;
	$Ncap=($ct+1); 
	last if ($num==$nmax);	# not more than nmax changes
	++$ct;}
    $num=0;
    $ct=$Ccap;			# Ccap
    while ((defined substr($rel,$ct,1)) && 
	   (substr($rel,$ct,1)<$cut)){
	++$num;
	$Ccap=($ct-1); 
	last if ($num==$nmax);	# not more than nmax changes
	--$ct;}
    return($Ncap,$Ccap);
}				# end of filter1_rel_shorten

#===============================================================================
sub getPhdSubset {
    local($stringPhdLoc,$stringRelLoc,$relThreshLoc,$relSymLoc) = @_ ;
    local($sbrName);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getPhdSubset                subset from string with PHDsec|acc|htm + rel index
#       in:                     $stringPhdLoc : PHDsec|acc|htm
#       in:                     $stringRelLoc : reliability index (string of numbers [0-9])
#       in:                     $relThreshLoc : >= this -> write to 'subset' row
#       in:                     $relSymLoc    : use this symbol for 'not pred' in subset
#       out:                    1|0,msg,$subset
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."getPhdSubset";$fhinLoc="FHIN_"."getPhdSubset";
				# check arguments
    return(&errSbr("not def stringPhdLoc!"))      if (! defined $stringPhdLoc);
    return(&errSbr("not def stringRelLoc!"))      if (! defined $stringRelLoc);
    return(&errSbr("not def relThreshLoc!"))      if (! defined $relThreshLoc);
    return(&errSbr("not def relSymLoc!"))         if (! defined $relSymLoc);

    @tmpPhd=split(//,$stringPhdLoc);
    @tmpRel=split(//,$stringRelLoc);
    return(&errSbr("stringPhdLoc ne stringRelLoc\n".
		   "phd=$stringPhdLoc\n".
		   "rel=$stringRelLoc\n"))        if ($#tmpPhd != $#tmpRel);

				# ------------------------------
    $out="";			# loop over all residues
    foreach $it (1..$#tmpPhd) {
				# high reliability -> take
	if ($tmpRel[$it] >= $relThreshLoc ) {
	    $out.=$tmpPhd[$it];
	    next; }
	$out.=    $relSymLoc;	# low  reliability -> dot
    }

    $#tmpPhd=$#tmpRel=$#tmp=0;	# slim-is-in!
    return(1,"ok $sbrName",$out);
}				# end of getPhdSubset

#===============================================================================
sub globeFuncFit {
    local($lenIn,$add,$fac,$expLoc) = @_ ;local($tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   globeFuncFit                length to number of surface molecules fitted to PHD error 
#                               out=(N ^ 1/3 - 2) ^ 3
#       in:                     len, acc-cut-off (allowed: 9, 16)
#       out:                    1,NsurfacePhdFit2
#       err:                    0,'msg'
#-------------------------------------------------------------------------------
    $expLoc=16 if (! defined $expLoc); # default
    if   ($expLoc == 9) {
	return(1,$lenIn - $fac*(($lenIn**(1/3)) - $add)**3);}
    elsif($expLoc == 16) {
	return(1,$lenIn - $fac*(($lenIn**(1/3)) - $add)**3);}
    else{ 
	return(0,"*** ERROR in $scrName globeFuncFit only defined for exp=16 or 9\n");}
}				# end of globeFuncFit

#===============================================================================
sub globeFuncJoinPhdSeg {
    local($globPhd,$globSeg) = @_ ;
    local($sbrName);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   globeFuncJoinPhdSeg         applies ad-hoc rule to join PHDglobe  and SEG
#       
#      !   /|   |\   !          - between the vertical lines => IS  globular
#      !  / |   | \  !          - left and right of '!'      => NOT globular
#      ! /  |   |  \ !          ELSE function:
#       lo    0    hi           - everything left of lo      => NON globular
#                               - everything right of hi     => NON globular
#                               - ELSE                       => IS  globular
#                               
#                               lower cut-off   /
#                               y (SEG) = $funcLoAdd + $funcLoFac x (PHD)
#                               higher cut-off  \
#                               y (SEG) = $funcHiAdd + $funcHiFac x (PHD)
#                               
#       in:                     $fileInLoc
#       out:                    1|0,$msg,(yes_is_globular=1|no_is_not_globular=0)
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."globeFuncJoinPhdSeg";
				# check arguments
    return(&errSbr("not def globPhd!"))          if (! defined $globPhd);
    return(&errSbr("not def globSeg!"))          if (! defined $globSeg);
#    return(&errSbr("not def !"))          if (! defined $);
				# check variables
    return(&errSbr("value for globSEG should be percentage [0-100], is $globSeg\n"))
	if (100 < $globSeg || $globSeg < 0);

				# ini the functions
				# out GLOBAL: 
				#     $FUNC_LO_FAC,$FUNC_LO_ADD,$FUNC_HI_FAC,$FUNC_HI_ADD
				#     $PHD_LO_NO,$PHD_HI_NO,$PHD_LO_OK,$PHD_HI_OK
    &globeFuncJoinPhdSegIni()   if (! defined $FUNC_LO_FAC || ! defined $FUNC_LO_ADD || 
				    ! defined $FUNC_HI_FAC || ! defined $FUNC_HI_ADD ||
				    ! defined $PHD_LO_NO   || ! defined $PHD_HI_NO   ||
				    ! defined $PHD_LO_OK   || ! defined $PHD_HI_OK );

    $funcLo=    $FUNC_LO_ADD + $FUNC_LO_FAC * $globPhd;
    $funcHi=    $FUNC_HI_ADD + $FUNC_HI_FAC * $globPhd;

				# PHD hard include:
    return(1,"ok",1)            if ($PHD_LO_OK  <= $globPhd  && $globPhd <= $PHD_HI_OK );
				# PHD hard exclude:
    return(1,"ok",0)            if ($globPhd  <  $PHD_LO_NO  || $globPhd  > $PHD_HI_NO );

				# left fit:
    return(1,"ok",0)            if ($globPhd < 0 && $globSeg > $funcLo);
				# right fit:
    return(1,"ok",0)            if ($globPhd > 0 && $globSeg > $funcHi);
				# all others : ok
    return(1,"ok $sbrName",1);
}				# end of globeFuncJoinPhdSeg

#===============================================================================
sub globeFuncJoinPhdSegIni {
    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   globeFuncJoinPhdSegIni      initialises the function used to apply the rule
#                               SEE globeFuncJoinPhdSeg for explanation! 
#       out GLOBAL:             $FUNC_LO_FAC,$FUNC_LO_ADD,$FUNC_HI_FAC,$FUNC_HI_ADD,
#                               $PHD_LO_NO,$PHD_HI_NO,$PHD_LO_OK,$PHD_HI_OK
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."globeFuncJoinPhdSegIni";
				# ------------------------------
				# PHD saturation
    $PHD_LO_NO= -0.10;		# if PHDnorm < $phdLoSat -> not globular
    $PHD_HI_NO=  0.20;		# if PHDnorm > $phdHiSat -> not globular

				# ------------------------------
				# PHD OK
    $PHD_LO_OK= -0.03;		# if $PHD_LO_OK < PHDnorm < $PHD_HI_OK -> IS globular
    $PHD_HI_OK=  0.15;		# if $PHD_LO_OK < PHDnorm < $PHD_HI_OK -> IS globular

				# ------------------------------
				# anchor points: SEG
    $segLo1=   50;
    $segLo2=  100;
    $segHi1=   80;
    $segHi2=  100;
				# ------------------------------
				# empirical function
				# ------------------------------
				# FAC = (y1 - y2) / (x1 - x2)
				# ADD = y1 - x1 * FAC
    $FUNC_LO_FAC= ($segLo2-$segLo1) / ($PHD_LO_NO-$PHD_LO_OK);
    $FUNC_LO_ADD= $segLo1 - $FUNC_LO_FAC * $PHD_LO_NO;

    $FUNC_HI_FAC= ($segHi2-$segHi1) / ($PHD_HI_NO-$PHD_HI_OK);
    $FUNC_HI_ADD= $segHi1 - $FUNC_HI_FAC * $PHD_HI_NO;
}				# end of globeFuncJoinPhdSegIni

#===============================================================================
sub globeOne {
    local($fileInLoc,$fhErrSbr,@passLoc)= @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   globe                       compiles the globularity for a PHD file
#       in:                     file.phdRdb, $fhErrSbr, (with ACC!!)
#       in:                     options as $kwd=value
#       in:                     logicals 'doFixPar', 'doReturn' will set the 
#       in:                        respective parameters to 1
#                               kwd=(lenMin|exposed|isPred|doFixPar
#                                    fit2Ave   |fit2Sig   |fit2Add   |fit2Fac|
#                                    fit2Ave100|fit2Sig100|fit2Add100|fit2Fac100)
#       in:                     doSeg=0       to ommit running SEG
#       in:                     fileSeg=file  to keep the SEG output
#       out:                    1,'ok',$len,$nexp,$nfit,$diff,$evaluation,
#                                      $globePhdNorm,$globePhdProb,
#                                      $segRatio,$LisGlobularCombi,$evaluationCombi
#                               
#                         note: $segRatio=         -1 if SEG did not run!
#                               $LisGlobularCombi= -1 if SEG did not run!
#                               $evaluationCombi=   0 if SEG did not run!
#       err:                    0,message
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."globe";$fhinLoc="FHIN"."$sbrName";
				# ------------------------------
				# (0) digest input arguments
    ($Lok,$msg)=
	&globeOneIni(@_); 
    return(&errSbrMsg("failed parsing input arguments\n",$msg)) if (! $Lok);
				# ------------------------------
				# (1) read file
    ($len,$numExposed,$seq)=
	&globeRd_phdRdb($fileInLoc,$fhErrSbr);
				# ERROR
    return(0,"*** ERROR $sbrName: numExposed=$numExposed (file=$fileInLoc)\n") 
	if (! $len || ! defined $numExposed || $numExposed =~/\D/);
    
				# ------------------------------
				# (2) get the expected number of res
    if (! $parSbr{"doFixPar"} && ($len < 100)){
	$fit2Add=$parSbr{"fit2Add100"};$fit2Fac=$parSbr{"fit2Fac100"};}
    else {
	$fit2Add=$parSbr{"fit2Add"};   $fit2Fac=$parSbr{"fit2Fac"};}

    ($Lok,$numExpect)=
	&globeFuncFit($len,$fit2Add,$fit2Fac,$parSbr{"exposed"});
				# reduce accuracy
    $numExpect=int($numExpect);
    $globePhdDiff=$numExposed-$numExpect;
				# reduce accuracy
    $globePhdDiff=~s/(\.\d\d).*$/$1/;
				# ------------------------------
				# (3) normalise
    $globePhdNorm=$globePhdDiff/$len;
				# reduce accuracy
    $globePhdNorm=~s/(\.\d\d\d).*$/$1/;

				# ------------------------------
				# (4) compile probability
    ($Lok,$msg,$globePhdProb)=
	&globeProb($globePhdNorm);
    return(&errSbrMsg("file=$fileInLoc, diff=$globePhdDiff, norm=$globePhdNorm\n".
		      "failed compiling probability\n",$msg)) if (! $Lok);
				# reduce accuracy
    $globePhdProb=~s/(\.\d\d\d).*$/$1/;
				# ------------------------------
				# (5) run SEG
				# ------------------------------
    if (length($seq) > 0 && $parSbr{"doSeg"} && -e $parSbr{"exeSeg"} && 
	(-x $parSbr{"exeSeg"} ||-l $parSbr{"exeSeg"} )) {
				# all variables in GLOBAL!
	($Lok,$msg,$segRatio,$LisGlobular,$evaluationCombi)=
	    &globeOneCombi();
				# no ERROR, just write!
	if (! $Lok) { print "*** ERROR globeOne: failed on globeOneCombi\n",$msg,"\n";
		      print "***      input file was=$fileInLoc,\n";
		      print "***      will return BAD values for SEG and combi!!\n";
		      $segRatio=      -1;
		      $LisGlobular=   -1;
		      $evaluationCombi=0; }}
    else { $segRatio=      -1;
	   $LisGlobular=   -1;
	   $evaluationCombi=0;
	   &globeFuncJoinPhdSegIni(); # get: $PHD_LO_NO,$PHD_HI_NO,$PHD_LO_OK,$PHD_HI_OK
    }

				# ------------------------------
				# evaluate the result (PHD only)
    if    ($PHD_HI_NO    >  $globePhdNorm && $globePhdNorm >  $PHD_HI_OK){
	$evaluation="your protein may be globular, but it is not as compact as a domain";}
    elsif ($PHD_LO_OK    <= $globePhdNorm && $globePhdNorm <= $PHD_HI_OK){
	$evaluation="your protein appears as compact, as a globular domain";}
    elsif ($globePhdNorm <= $PHD_LO_NO    || $globePhdNorm >= $PHD_HI_NO){
	$evaluation="your protein appears not to be globular";}
    else {
	$evaluation="your protein appears not as globular, as a domain";}

    return(1,"ok $sbrName",
	   $len,$numExposed,$numExpect,$globePhdDiff,$evaluation,
	   $globePhdNorm,$globePhdProb,$segRatio,$LisGlobular,$evaluationCombi);
}				# end of globeOne

#===============================================================================
sub globeOneIni {
    local($fileInLoc,$fhErrSbr,@passLoc)= @_ ;
    local($sbrName);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   globeOneIni                 interprets input arguments
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."globeOneIni";
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc!")   if (! defined $fileInLoc);
    $fhErrSbr="STDOUT"                             if (! defined $fhErrSbr);
    return(0,"*** $sbrName: not def fileInLoc!")   if (! defined $fileInLoc);

				# ------------------------------
				# default settings
    $parSbr{"lenMin"}=   30;	$parSbr{"expl","lenMin"}=  "minimal length of protein";
    $parSbr{"exposed"}=  16;	$parSbr{"expl","exposed"}= "exposed if relAcc > this";
    $parSbr{"isPred"}=    1;	$parSbr{"expl","isPred"}=  "file without observed columns";

				# fit: (N- $fit2Fac*(N^1/3-$fit2Add)^3) 
    $parSbr{"fit2Ave"}=   1.4;	$parSbr{"expl","fit2Ave"}=  "average of fit for data base";
    $parSbr{"fit2Sig"}=   9.9;	$parSbr{"expl","fit2Sig"}=  "1 sigma of fit for data base";
    $parSbr{"fit2Add"}=   0.78; $parSbr{"expl","fit2Add"}=  "add of fit= 'N - fac*(N1/3-add)^3";
    $parSbr{"fit2Fac"}=   0.84;	$parSbr{"expl","fit2Fac"}=  "fac of fit= 'N - fac*(N1/3-add)^3";

    $parSbr{"fit2Ave100"}=0.1;
    $parSbr{"fit2Sig100"}=6.2;
    $parSbr{"fit2Add100"}=0.41;
    $parSbr{"fit2Fac100"}=0.64;
    $parSbr{"doFixPar"}=  0;	$parSbr{"expl","doFixPar"}=
	                                "do NOT change the fit para if length<100";
    @parSbr=("lenMin","exposed","isPred","doFixPar",
	     "fit2Ave",   "fit2Sig",   "fit2Add",   "fit2Fac",
	     "fit2Ave100","fit2Sig100","fit2Add100","fit2Fac100",
	     "fileSeg","doSeg","winSeg","locutSeg","hicutSeg","optSeg","exeSeg");

    $parSbr{"fileSeg"}=   0;	# =0 -> will be deleted!
    $parSbr{"doSeg"}=     1;	# will run SEG (if exe exists)
    $parSbr{"winSeg"}=   30;	# window size, 0 for mode 'glob'
    $parSbr{"locutSeg"}=  3.5;
    $parSbr{"hicutSeg"}=  3.75;

    $parSbr{"optSeg"}=    "x";	# pass the output print options as comma separated list
				#    NO '-' needed, see below
    if (defined $ARCH) {
	$ARCHTMP=$ARCH; }
    else {
	print "-*- WARN $sbrName: no ARCH defined set it!\n";
	$ARCHTMP=$ENV{'ARCH'} || "SGI32"; }

    $parSbr{"exeSeg"}=    "/nfs/data5/users/ppuser/server/pub/molbio/bin/seg".$ARCHTMP; # executable of SEG

				# ------------------------------
				# read command line
    foreach $arg (@passLoc){
	if    ($arg=~/^isPred/)               { $parSbr{"isPred"}=  1;$Lok=1;}
	elsif ($arg=~/^fix/)                  { $parSbr{"doFixPar"}=1;$Lok=1;}
	elsif ($arg=~/^[r]eturn/)             { $parSbr{"doReturn"}=1;$Lok=1;}

	elsif ($arg=~/^win=(.*)$/)            { $parSbr{"winSeg"}=$1;}
	elsif ($arg=~/^locut=(.*)$/)          { $parSbr{"locutSeg"}=$1;}
	elsif ($arg=~/^hicut=(.*)$/)          { $parSbr{"hicutSeg"}=$1;}
	elsif ($arg=~/^opt=(.*)$/)            { $parSbr{"optSeg"}=$1;}
	elsif ($arg=~/^exe=(.*)$/)            { $parSbr{"exeSeg"}=$1;}
	elsif ($arg=~/^fileSeg=(.*)$/i)       { $parSbr{"fileSeg"}=$1;}
	elsif ($arg=~/^fileOutSeg=(.*)$/i)    { $parSbr{"fileSeg"}=$1;}

	elsif ($arg=~/^noseg$/i)              { $parSbr{"noSeg"}=0;}
	else {
	    $Lok=0;
	    foreach $kwd (@parSbr){
		if ($arg=~/^$kwd=(.*)$/) {
		    $parSbr{"$kwd"}=$1;$Lok=1;}}
	    return(0,"*** $sbrName: wrong command line arg '$arg'\n") if (! $Lok);} }

    $exposed=$parSbr{"exposed"};

    return(1,"ok $sbrName");
}				# end of globeOneIni

#===============================================================================
sub globeOneCombi {
    local($sbrName);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   globeOneCombi               runs SEG and combines results with PHDglobeNorm
#       in|out GLOBAL:          all (from globeOne)
#                               in particular: $fileInLoc,$globePhdNorm
#       out:                    1|0,msg,$segRatio,$LisGlobular,$evaluationCombi  
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."globeOneCombi";
				# ------------------------------
				# intermediate FASTA of sequence
    $fileFastaTmp=    "GLOBE-TMP".$$."_fasta.tmp";
    if (! $parSbr{"fileSeg"}) {
	$fileSegTmp=  "GLOBE-SEG".$$."_seg.tmp";}
    else {			# file passed as argumnet -> do NOT delete
	$fileSegTmp=  $parSbr{"fileSeg"};}
    $id=$fileInLoc;$id=~s/^.*\/|\..*$//g;
    ($Lok,$msg)=
	&fastaWrt($fileFastaTmp,$id,$seq);

    return(&errSbrMsg("writing fasta ($fileFastaTmp) globeOne ($fileInLoc)")) if (! $Lok);
				# ------------------------------
				# do SEG
    ($Lok,$msg)=
	&segRun($fileFastaTmp,$fileSegTmp,$parSbr{"exeSeg"},0,0,$parSbr{"winSeg"},
		$parSbr{"locutSeg"}, $parSbr{"hicutSeg"},$parSbr{"optSeg"},$fhErrSbr);
    return(&errSbrMsg("failed SEG (".$parSbr{"exeSeg"}.") on $fileFastaTmp",$msg)) if (! $Lok);

    unlink($fileFastaTmp);	# remove temporary file

				# ------------------------------
				# digest SEG output (out=length of entire, lenght of comp)
    ($Lok,$msg,$lenSeq,$lenCom)=
	&segInterpret($fileSegTmp);
    return(&errSbrMsg("failed interpreting SEG file=$fileSegTmp",$msg)) if (! $Lok);

    if (! $parSbr{"fileSeg"}) {
	unlink($fileSegTmp); }	# remove temporary file

    $segRatio=-1;
    $segRatio=100*($lenCom/$lenSeq) if ($lenSeq > 0);
				# reduce accuracy
    $segRatio=~s/(\.\d\d).*$/$1/;

				# ------------------------------
				# combine SEG + PHD
    ($Lok,$msg,$LisGlobular)=
	&globeFuncJoinPhdSeg($globePhdNorm,$segRatio);
    return(&errSbrMsg("failed to join PHD+SEG ($globePhdNorm,$segRatio)",
		      $msg)) if (! $Lok);

				# ------------------------------
				# evaluate
    if    ($PHD_LO_OK    <= $globePhdNorm && 
	   $globePhdNorm <= $PHD_HI_OK &&
	   $segRatio     <= 50) {
	$evaluationCombi="your protein is very likely to be globular (SEG + GLOBE)";}
    elsif ($LisGlobular) {
	$evaluationCombi="your protein appears to be globular (SEG + GLOBE)";}
    elsif ($segRatio     <= 50) {
	$evaluationCombi="according to SEG your protein may be globular";}
    else {
	$evaluationCombi="according to SEG + GLOBE your protein appears non-globular";}

    return(1,"ok $sbrName",$segRatio,$LisGlobular,$evaluationCombi);
}				# end of globeOneCombi 

#===============================================================================
sub globeProb {
    local($globePhdNormInLoc) = @_ ;
    local($sbrName);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   globeProb                   translates normalised diff in exp res to prob
#                               
#       in:                     $(norm = DIFF / length)
#       out:                    1|0,$msg,$prob (lookup table!)
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."globeProb";
				# check arguments
    return(&errSbr("globePhdNormInLoc not defined")) 
	if (! defined $globePhdNormInLoc);
    return(&errSbr("globePhdNormInLoc ($globePhdNormInLoc) not number")) 
	if ($globePhdNormInLoc !~ /^[0-9\.\-]+$/);
    return(&errSbr("normalised phdGlobe should be between -1 and 1, is=$globePhdNormInLoc")) 
	if ($globePhdNormInLoc < -1 || $globePhdNormInLoc > 1);
				# ------------------------------
				# ini if table not defined yet!
    &globeProbIni()             if (! defined $GLOBE_PROB_TABLE_MIN || ! defined $GLOBE_PROB_TABLE[1]);

				# ------------------------------
				# normalise
				# too low
    return(1,"ok",0)            if ($globePhdNormInLoc <= $GLOBE_PROB_TABLE_MIN);
				# too high
    return(1,"ok",0)		if ($globePhdNormInLoc >= $GLOBE_PROB_TABLE_MAX);
				# in between: find interval
    $val=$GLOBE_PROB_TABLE_MIN;
    foreach $it (1..$GLOBE_PROB_TABLE_NUM) {
	$val+=$GLOBE_PROB_TABLE_ITRVL;
	last if ($val > $GLOBE_PROB_TABLE_MAX);	# note: should not happen
	return(1,"ok",$GLOBE_PROB_TABLE[$it])
	    if ($globePhdNormInLoc <= $val);
    }
				# none found (why?)
    return(1,"ok",0);
}				# end of globeProb

#===============================================================================
sub globeProbIni {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   globeProbIni           sets the values for the probability assignment
#       out GLOBAL:             
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."globeProbIni";

    $GLOBE_PROB_TABLE_MIN=  -0.280;
    $GLOBE_PROB_TABLE_MAX=   0.170;
    $GLOBE_PROB_TABLE_ITRVL= 0.010;
    $GLOBE_PROB_TABLE_NUM=   46;

    $GLOBE_PROB_TABLE[1]= 0.005; # val= -0.280  occ=   6  prob=   0.021
    $GLOBE_PROB_TABLE[2]= 0.008; # val= -0.270  occ=   0  prob=   0.014
    $GLOBE_PROB_TABLE[3]= 0.010; # val= -0.260  occ=   4  prob=   0.014
    $GLOBE_PROB_TABLE[4]= 0.015; # val= -0.250  occ=   6  prob=   0.021
    $GLOBE_PROB_TABLE[5]= 0.021; # val= -0.240  occ=   0  prob=   0.021
    $GLOBE_PROB_TABLE[6]= 0.025; # val= -0.230  occ=   0  prob=   0.021
    $GLOBE_PROB_TABLE[7]= 0.026; # val= -0.220  occ=   1  prob=   0.003
    $GLOBE_PROB_TABLE[8]= 0.028; # val= -0.210  occ=   0  prob=   0.021
    $GLOBE_PROB_TABLE[9]= 0.030; # val= -0.200  occ=   0  prob=   0.021
    $GLOBE_PROB_TABLE[10]=0.032; # val= -0.190  occ=   0  prob=   0.021
    $GLOBE_PROB_TABLE[11]=0.034; # val= -0.180  occ=   0  prob=   0.021
    $GLOBE_PROB_TABLE[12]=0.036; # val= -0.170  occ=   0  prob=   0.021
    $GLOBE_PROB_TABLE[13]=0.040; # val= -0.160  occ=  13  prob=   0.045
    $GLOBE_PROB_TABLE[14]=0.045; # val= -0.150  occ=  11  prob=   0.038
    $GLOBE_PROB_TABLE[15]=0.065; # val= -0.140  occ=  19  prob=   0.065
    $GLOBE_PROB_TABLE[16]=0.070; # val= -0.130  occ=   6  prob=   0.021
    $GLOBE_PROB_TABLE[17]=0.075; # val= -0.120  occ=   7  prob=   0.024
    $GLOBE_PROB_TABLE[18]=0.080; # val= -0.110  occ=  22  prob=   0.075
    $GLOBE_PROB_TABLE[19]=0.130; # val= -0.100  occ=  71  prob=   0.243
    $GLOBE_PROB_TABLE[20]=0.240; # val= -0.090  occ=  38  prob=   0.130
    $GLOBE_PROB_TABLE[21]=0.312; # val= -0.080  occ=  91  prob=   0.312
    $GLOBE_PROB_TABLE[22]=0.329; # val= -0.070  occ=  96  prob=   0.329
    $GLOBE_PROB_TABLE[23]=0.350; # val= -0.060  occ= 111  prob=   0.380
    $GLOBE_PROB_TABLE[24]=0.380; # val= -0.050  occ= 183  prob=   0.627
    $GLOBE_PROB_TABLE[25]=0.435; # val= -0.040  occ= 104  prob=   0.356
    $GLOBE_PROB_TABLE[26]=0.600; # val= -0.030  occ= 132  prob=   0.452
    $GLOBE_PROB_TABLE[27]=0.700; # val= -0.020  occ= 127  prob=   0.435
    $GLOBE_PROB_TABLE[28]=0.800; # val= -0.010  occ= 151  prob=   0.517
    $GLOBE_PROB_TABLE[29]=0.999; # val=  0.000  occ= 453  prob=   0.959
    $GLOBE_PROB_TABLE[30]=0.950; # val=  0.010  occ= 245  prob=   0.839
    $GLOBE_PROB_TABLE[31]=0.900; # val=  0.020  occ= 292  prob=   1.000
    $GLOBE_PROB_TABLE[32]=0.800; # val=  0.030  occ= 211  prob=   0.723
    $GLOBE_PROB_TABLE[33]=0.750; # val=  0.040  occ= 156  prob=   0.534
    $GLOBE_PROB_TABLE[34]=0.700; # val=  0.050  occ= 224  prob=   0.767
    $GLOBE_PROB_TABLE[35]=0.650; # val=  0.060  occ= 161  prob=   0.551
    $GLOBE_PROB_TABLE[36]=0.600; # val=  0.070  occ= 129  prob=   0.442
    $GLOBE_PROB_TABLE[37]=0.550; # val=  0.080  occ= 103  prob=   0.353
    $GLOBE_PROB_TABLE[38]=0.500; # val=  0.090  occ= 171  prob=   0.586
    $GLOBE_PROB_TABLE[39]=0.200; # val=  0.100  occ=  45  prob=   0.154
    $GLOBE_PROB_TABLE[40]=0.150; # val=  0.110  occ=  17  prob=   0.058
    $GLOBE_PROB_TABLE[41]=0.110; # val=  0.120  occ=  32  prob=   0.110
    $GLOBE_PROB_TABLE[42]=0.050; # val=  0.130  occ=   5  prob=   0.017
    $GLOBE_PROB_TABLE[43]=0.040; # val=  0.140  occ=   1  prob=   0.003
    $GLOBE_PROB_TABLE[44]=0.030; # val=  0.150  occ=   2  prob=   0.007
    $GLOBE_PROB_TABLE[45]=0.020; # val=  0.160  occ=   9  prob=   0.031
    $GLOBE_PROB_TABLE[46]=0.005; # val=  0.170  occ=   2  prob=   0.007
}				# end of globeProbIni

#==============================================================================
sub globeRd_phdRdb {
    local($fileInLoc2,$fhErrSbr2) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok,@tmp,$msgErr,
	  $ctTmp,$Lboth,$Lsec,$len,$numExposed,$lenRd,$rel);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   globeRd_phdRdb              read PHD rdb file with ACC
#       in:                     $fileInLoc,$fhErrSbr2
#       out:                    $len,$numExposed
#       err:                    0,'msg'
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="lib-br:"."globeRd_phdRdb";$fhinLoc="FHIN"."$sbrName";
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc2!")        if (! defined $fileInLoc2);
    $fhErrSbr2="STDOUT"                                  if (! defined $fhErrSbr);
    return(0,"*** $sbrName: no in file '$fileInLoc2'!")  if (! -e $fileInLoc2);

    $Lok=       &open_file("$fhinLoc","$fileInLoc2");
    if (! $Lok){print $fhErrSbr2 "*** ERROR $sbrName: '$fileInLoc2' not opened\n";
		return(0);}
				# reading file
    $ctTmp=$Lboth=$Lsec=$len=$numExposed=0;
    $seq="";
    while (<$fhinLoc>) {
	++$ctTmp;
	$lenRd=$1               if ($_=~/^\# LENGTH\s+\:\s*(\d+)/);
	if ($ctTmp<3){ 
	    if    ($_=~/^\# PHDsec\+PHDacc/)  {$Lboth=1;}
	    elsif ($_=~/^\# PHDacc/)          {$Lboth=0;}
	    elsif ($_=~/^\# PHDsec/)          {$Lsec=1;}
	    elsif ($_=~/^\# PROFboth/)        {$Lboth=1;}
	    elsif ($_=~/^\# PROFsec\+PROFacc/){$Lboth=1;}
	    elsif ($_=~/^\# PROFacc/)         {$Lboth=0;}
	    elsif ($_=~/^\# PROFsec/)         {$Lsec=1;}
	}
				# ******************************
	last if ($Lsec);	# ERROR is not PHDacc, at all!!!
				# ******************************

				# ------------------------------
				# names
	if (! defined $names && $_ !~ /^\s*\#/){
	    $_=~s/\n//g;
	    $names=$_;
	    @names=split(/\s*\t\s*/,$_);
	    $pos=0;
	    foreach $it (1..$#names){
		$tmp=$names[$it];
		if ($tmp =~ /^AA/){
		    $posSeq=$it;
		    next; }
		if ($tmp =~ /PREL/){
		    $pos=$it;
		    last; }}
	    return(0,"$sbrName missing column name PREL (names=$names)")
		if (! $pos);
	    next; }
		
	next if ($_=~/^\#|^No|^4N/); # skip comments and first line
	$_=~s/\n//g;
	@tmp=split(/\t/,$_);	# $id,$chain,$len,$nali,$seq,$sec,$acc,$rel
	
	return(0,"*** ERROR $sbrName: too few elements in id=$id, line=$_\n") 
	    if ($#tmp<6);
				# ------------------------------
				# read sequence (second column)
	$tmp=$tmp[$posSeq]; $tmp=~s/\s//g;
	$seq.=$tmp;
				# ------------------------------
				# read ACC
	foreach $tmp (@tmp) {
	    $tmp=~s/\s//g;}	# skip blanks

	$rel=$tmp[$pos];

	if ($rel =~/[^0-9]/){	# xx hack out, somewhere error
	    $msgErr="*** error rel=$rel, ";
	    if ($parSbr{"isPred"}){$msgErr.="isPred ";}else{$msgErr.="isPrd+Obs ";}
	    if ($Lboth)        {$msgErr.="isBoth ";}else{$msgErr.="isPHDacc ";}
	    $msgErr.="line=$_,\n";
	    close($fhinLoc);
	    return(0,$msgErr);}
	++$len;
	++$numExposed if ($rel>=$exposed);
	$_=~s/\n//g;
	next if (length($_)==0);
    } close($fhinLoc);
    return(0,"$sbrName some variables strange len=$len, numExposed=$numExposed\n")
	if (! defined $len || $len==0 || ! defined $numExposed || $numExposed==0);
    return($len,$numExposed,$seq);
}				# end of globeRd_phdRdb

#===============================================================================
sub globeWrt {
    local($fhoutTmp,$parLoc,%resLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok,@tmp,@idLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   globeWrt                    writes output for GLOBE
#       in:                     FILEHANDLE to print,$par=par1,par2,par3,%res
#       in:                     $res{"id"}          = 'id1,id2', i.e. list of names 
#       in:                     $res{"par1"}        = setting of parameter 1
#       in:                     $res{"expl","par1"} = explain meaning of parameter 1
#       in:                     $res{"$id","$kwd"}  = value for name $id
#       in:                         kwd=len|nexp|nfit|diff|interpret
#       out:                    write file
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."globeWrt";$fhinLoc="FHIN"."$sbrName";
				# interpret arguments
    if (defined $parLoc){
	$parLoc=~s/^,*|,*$//g;
	@tmp=split(/,/,$parLoc);}
    if (defined $resLoc{"id"}){
	$resLoc{"id"}=~s/^,*|,*$//g;
	@idLoc=split(/,/,$resLoc{"id"});}
				# ------------------------------
				# write header
    if (defined $date) {
	$dateTmp=$date; }
    else {
	$tmp=`date`; $tmp=~s/\n//g if (defined $tmp);
	$dateTmp=$tmp || "before year 2000"; }

    print $fhoutTmp
	"# Perl-RDB generated by:$scrName on:$dateTmp\n",
	"# --------------------------------------------------------------------------------\n",
	"# FORMAT   begin\n",
	"# FORMAT   general:    - lines starting with hashes contain comments or PARAMETERS\n",
	"# FORMAT   general:    - columns are delimited by tabs\n",
	"# FORMAT   parameters: '# PARA:tab     keyword =tab value tab (further-information)'\n",
	"# FORMAT   notation:   '# NOTATION:tab keyword tab explanation'\n",
	"# FORMAT   info:       '# INFO:tab     text'\n",
	"# FORMAT   blocks 0:   '# BLOCK        keyword'\n",
	"# FORMAT   blocks 1:    column names (tab delimited)\n",
	"# FORMAT   blocks n>1:  column data  (tab delimited)\n",
	"# FORMAT   file end:   '//' is the end of a complete file\n",
	"# FORMAT   end\n",
	"# --------------------------------------------------------------------------------\n";
				# ------------------------------
				# write parameters
    print $fhoutTmp
	"# PARA     begin\n",
	"# PARA     $scrName HEADER: PARAMETERS\n";
    foreach $des (@tmp){
	$expl="";$expl=$resLoc{"expl","$des"} if (defined $resLoc{"expl","$des"});
	next if ($des eq "doFixPar" && (! $resLoc{"doFixPar"}));
	printf $fhoutTmp 
	    "# PARA:\t%-10s =\t%-6s\t%-s\n",$des,$resLoc{"$des"},$expl;}
    print $fhoutTmp
	"# PARA     end\n",
	"# --------------------------------------------------------------------------------\n";
				# ------------------------------
				# explanations
    print $fhoutTmp
	"# NOTATION begin\n",
	"# NOTATION HEADER: ABBREVIATIONS COLUMN NAMES\n";
    printf $fhoutTmp 
	"# NOTATION:\t%-12s:\t%s\n","id",        "protein identifier";
    printf $fhoutTmp 
	"# NOTATION:\t%-12s:\t%s\n","len",       "length of protein";
    printf $fhoutTmp 
	"# NOTATION:\t%-12s:\t%s\n","nexp",      "number of predicted exposed residues (PHDacc)";
    printf $fhoutTmp 
	"# NOTATION:\t%-12s:\t%s\n","nfit",      "number of expected exposed res";
    printf $fhoutTmp 
	"# NOTATION:\t%-12s:\t%s\n","diff",      "nExposed - nExpect";
    printf $fhoutTmp 
	"# NOTATION:\t%-12s:\t%s\n","interpret",
	                            "comment about globularity predicted for your protein";
    print $fhoutTmp
	"# NOTATION end\n",
	"# --------------------------------------------------------------------------------\n";
    print $fhoutTmp
	"# COMMENTS begin\n",
	"# COMMENTS You may find a preliminary description of the method in the following\n",
	"# COMMENTS preprint:\n",
	"# COMMENTS    http://www.embl-heidelberg.de/~rost/Papers/98globe.html\n",
	"# COMMENTS \n",
	"# COMMENTS end\n",
	"# --------------------------------------------------------------------------------\n";
				# column names
    printf $fhoutTmp 
	"%-s\t%8s\t%8s\t%8s\t%8s\t%-s\n",
	"id","len","nexp","nfit","diff","interpret";

				# data
    foreach $id (@idLoc){
	printf $fhoutTmp 
	    "%-s\t%8d\t%8d\t%8.2f\t%8.2f\t%-s\n",
	    $id,$resLoc{"$id","len"},$resLoc{"$id","nexp"},$resLoc{"$id","nfit"},
	    $resLoc{"$id","diff"},$resLoc{"$id","interpret"};}
}				# end of globeWrt

#==============================================================================
sub phdAliWrt {
    local ($fileInHsspLoc,$chainInLoc,$fileInPhdLoc,$fileOutLoc,$formOutLoc,
	   $LoptExpandLoc,$riSecLoc,$riAccLoc,$riSymLoc,$charPerLineLoc) = @_ ;
    local($sbrName,$fhinLoc,$fhoutLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   phdAliWrt                 converts PHD.rdb to SAF format (including ali)
#       in:                     $fileInHssp  : HSSP file
#       in:                     $chainIn     : chain identifier ([0-9A-Z])
#       in:                     $fileInPhd   : PHD.rdb file
#       in:                     $fileOutLoc  : output *.msf file
#       in:                     $formOutLoc  : format of output file (msf|saf)
#       in:                     $LoptExpand  : do expand insertions in HSSP ?
#       in:                     $riSecLoc    : >= this -> write sec|htm to 'subset' row
#       in:                     $riAccLoc    : >= this -> write acc to 'subset' row
#       in:                     $riSymLoc    : use this symbol for 'not pred' in subset
#       in:                     $charPerLine : number of residues per line of output
#       in:                     $  :
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."phdAliWrt"; 
    $fhinLoc="FHIN_phdAliWrt";  $fhoutLoc="FHOUT_phdAliWrt"; 
				# ------------------------------
				# check arguments
    return(&errSbr("not def fileInHsspLoc!"))          if (! defined $fileInHsspLoc);
    return(&errSbr("not def chainInLoc!"))             if (! defined $chainInLoc);
    return(&errSbr("not def fileInPhdLoc!"))           if (! defined $fileInPhdLoc);
    return(&errSbr("not def fileOutLoc!"))             if (! defined $fileOutLoc);
    return(&errSbr("not def formOutLoc!"))             if (! defined $formOutLoc);
    return(&errSbr("not def LoptExpandLoc!"))          if (! defined $LoptExpandLoc);
    return(&errSbr("not def riSecLoc!"))               if (! defined $riSecLoc);
    return(&errSbr("not def riAccLoc!"))               if (! defined $riAccLoc);
    return(&errSbr("not def riSymLoc!"))               if (! defined $riSymLoc);
    return(&errSbr("not def charPerLineLoc!"))         if (! defined $charPerLineLoc);
				# ------------------------------
				# file existence
    return(&errSbr("miss in hssp=$fileInHsspLoc!"))    if (! -e $fileInHsspLoc);
    return(&errSbr("not HSSP format=$fileInHsspLoc!")) if (! &is_hssp($fileInHsspLoc));
    return(&errSbr("empty HSSP=$fileInHsspLoc!"))      if (&is_hssp_empty($fileInHsspLoc));
	
    return(&errSbr("miss in phd=$fileInPhdLoc!"))      if (! -e $fileInPhdLoc);
    return(&errSbr("not PHD.rdb=$fileInPhdLoc!"))      if (! &is_rdbf($fileInPhdLoc));
				# ------------------------------
				# syntax
    $formOutLoc=~tr/[A-Z]/[a-z]/;
    return(&errSbr("now only MSF|SAF ($formOutLoc)"))  if ($formOutLoc !~/^(msf|saf)$/);
    $LoptExpandLoc=0            if ($LoptExpandLoc !~ /^[01]$/);
    $chainInLoc="*"             if ($chainInLoc !~ /^[A-Za-z0-9]$/);
    $kwdSeq="seqNoins";
    $kwdSeq="seqAli"            if ($LoptExpandLoc); # do expand
				# --------------------------------------------------
				# defaults
				# @kwdPhd: keywords read + written
				# - not read but written: SUBsec, SUBacc
				# - explicit surpressor towards end for
				#   "OBSacc","PHDacc"
				# - 
				# note: @kwdPhdRd and @kwdPhdOut 
				#       correspond in that:
				# --------------------------------------------------
    @kwdPhd=
	("AA",    
	 "OHEL",  "PHEL",  "RI_S",  "SUBsec",
	 "Obie",  "Pbie",  "RI_A",  "SUBacc",   "OREL",   "PREL", 
	 "OHL",   "PHL",            "PFHN",     "PRHN",   "PiTo",   
	 "OTN",   "PTN",   "PRTN", # security
	                   "RI_H",  "PFTN",     
	 );
    $kwdAli=  "ALIGNMENT:";
    $kwdPhd=  "PHD:";
    $symEmpty=" ";
    %ptr=
	('AA',   "AApred",
	 'OHEL', "OBSsec", 'PHEL', "PHDsec", 'RI_S', "RELsec", 
	 'Obie', "O_3acc", 'Pbie', "P_3acc", 'RI_A', "RELacc",
	 'OTN',  "OBShtm", 'PTN',  "PHDhtm", 'RI_H', "RELhtm",
	 'OHL',  "OBShtm", 'PHL',  "PHDhtm", # security
	 'PFTN', "PHDhtmfil", 'PRTN', "PHDhtmref", 'PiTo', "PHDhtmtop",
	 'PFHL', "PHDhtmfil", 'PRHL', "PHDhtmref", 'PiTo', "PHDhtmtop",
	 );
				# explain subset
    $tmp="# NOTATION "." " x 10 ."   ";
    @tmpSec=
	(     "subset of the prediction, for all residues with an expected\n",
	 $tmp."average accuracy > 82% (tables in header)\n",
	 $tmp."NOTE: '$riSymLoc' means that for this residue the reliabilty\n",
	 $tmp."      was below a value of Rel=$riSecLoc.");
    @tmpAcc=
	(     "a subset of the prediction, for all residues with an expected\n",
	 $tmp."average correlation > 0.69 (tables in header)\n",
	 $tmp."NOTE: '$riSymLoc' means that for this residue the reliabilty\n",
	 $tmp."      was below a value of Rel=$riAccLoc.");
    $notationSubsec=join('',@tmpSec);
    $notationSubacc=join('',@tmpAcc);

    $warnMsg="";
    $errMsg= "*** ERROR $sbrName: \n";
    $errMsg.="in: hssp=$fileInHsspLoc, chain=$chainInLoc, phdrdb=$fileInPhdLoc, \n";
    $errMsg.="in: out=$fileOutLoc, form=$formOutLoc, expand=$LoptExpandLoc, \n";
    $errMsg.="in: riSec=$riSecLoc, riAcc=$riAccLoc, sym=$riSymLoc, per=$charPerLineLoc\n";
				# ------------------------------
				# read HSSP alignments
				# ------------------------------
    ($Lok,%tmp)=
	&hsspRdAli($fileInHsspLoc,$kwdSeq);
    return(&errSbr("after hsspRdAli ($fileInHsspLoc,$kwdSeq)".$errMsg)) if (! $Lok);
    return(&errSbr("after hsspRdAli ($fileInHsspLoc,NRES < 1)".$errMsg))
	if (! defined $tmp{"NRES"} || $tmp{"NRES"} < 1);
				# --------------------------------------------------
				# rename -> 
				#    $fin{"seq","1"}=  ... numbers
				#    $fin{"seq","2"}=  guide sequence
				#    $fin{"seq","it"}= pair it-2
				#    $fin{"id","it"}=  identifier for it
				# --------------------------------------------------
    undef %fin;			
    $beg=$end=0;		# find chain
    foreach $itres (1..$tmp{"NRES"}) {
	next if ($chainInLoc ne "*" && $tmp{"chn","$itres"} ne $chainInLoc);
	$beg=$itres             if (! $beg);
	$end=$itres; }
    return(&errSbr("after hsspRdAli beg=$beg, end=$end".$errMsg)) 
	if ($beg < 0 || $beg > length($tmp{"$kwdSeq","0"}) || 
	    $end < 0 || $end > length($tmp{"$kwdSeq","0"}));
				# guide sequence
    $fin{"seq","2"}=         substr($tmp{"$kwdSeq","0"},$beg,(1+$end-$beg)); # sequence
    $fin{"id","2"}=          $tmp{"0"};                 # name

    $ctali=2;			# first 2 = emtpy + guide
				# loop over all pairs
    foreach $itpair (1..$tmp{"NROWS"}) {
	$seq=substr($tmp{"$kwdSeq","$itpair"},$beg,(1+$end-$beg));
	$tmp=$seq;$tmp=~s/\.//g; # delete insertions
				# skip pairs not aligned to chain
	next if (length($tmp) < 1);
	++$ctali;
	$fin{"seq","$ctali"}=$seq;            # sequence
	$fin{"id","$ctali"}= $tmp{"$itpair"}; # name
    }
				# empty line
    $len=length($fin{"seq","2"}); $numpoints=10*(int($len/10))+10;
    $line=&myprt_npoints($numpoints,$len); 
    $fin{"id","1"}= $kwdAli;
    $fin{"seq","1"}=$line;
				# ------------------------------
				# read PHD rdb file
				# ------------------------------
    undef %tmp; undef %tmp2;
    %tmp=
	&rdRdbAssociative($fileInPhdLoc,"not_screen","body",@kwdPhd);

    return(&errSbr("after rdRdbAssociative ($fileInPhdLoc), no NROWS".$errMsg))
	if (! defined $tmp{"NROWS"});
    
				# --------------------------------------------------
				# digest the stuff read
				# * $tmp2{"kwd"} = strings with kwd = @kwdPhdOut
				# --------------------------------------------------
    $len=0;			# all keywords of PHD to write
    foreach $kwd (@kwdPhd) {
				# skip if no READ_RDB for key word 
	next if (! defined $tmp{"$kwd","1"});
	$tmp2{"$kwd"}=          "";
				# loop over all residues (strings from array)
	foreach $itres (1..$tmp{"NROWS"}){ # 
	    $tmp2{"$kwd"}.=     $tmp{"$kwd","$itres"}; }
	$len=length($tmp2{"$kwd"})  if (! $len);
	if ($kwd=~/^[OP]HEL/) {	# convert 'L' -> ' '
	    $tmp2{"$kwd"}=~s/L/L/g ;
	    next; }
	if ($kwd=~/^[PO]bie/){	# convert 'i' -> ' '
	    $tmp2{"$kwd"}=~s/i/i/g;
	    next; }		# convert HTM
	if ($kwd=~/^[PO]H[LN]/ || $kwd=~/^P[RF]H[LN]/){
	    $tmp2{"$kwd"}=~s/H/T/g;
	    $tmp2{"$kwd"}=~s/L/L/g;
	    next; } 
    }
				# ------------------------------
				# check identity HSSP / PHD seq
    $ctres=$ctsum=$ctok=0;	# ------------------------------
    $guideAli=$fin{"seq","2"}; 
    $guidePhd=$tmp2{"AA"};
    while (($ctres < length($guideAli)) && ($ctres < length($guidePhd))) {
	++$ctres;
				# skip non aa 
	$aliRes=substr($guideAli,$ctres,1);
	$phdRes=substr($guidePhd,$ctres,1);
	next if ($aliRes !~ /[A-Za-z]/);  # ali
	next if ($phdRes !~ /[A-Za-z]/);  # phd
				# count identical
	++$ctok                 if ($aliRes eq $phdRes);
	++$ctsum; }		# count all
    if ($ctsum < $ctok) { $warnMsg.="*** WARN $sbrName (hssp=$fileInHsspLoc,chn=$chainInLoc,".
			      "phd=$fileInPhdLoc) not identical seq(hssp) and seq(phd) ".
				  "tot=$ctsum, ok=$ctok\n";
			  $warnMsg.="hssp seq=".$guideAli.",\n";
			  $warnMsg.="phd  seq=".$guidePhd. ",\n"; }

				# ------------------------------
				# add the 'subset' stuff
    foreach $kwd ("SUBsec","SUBacc"){
	if    ($kwd=~/sec/) { $kwdPred="PHEL"; 
			      $kwdRi="RI_S";
			      $riThresh=$riSecLoc; }
	elsif ($kwd=~/acc/) { $kwdPred="Pbie"; 
			      $kwdRi="RI_A";
			      $riThresh=$riAccLoc; }
	next if (! defined $tmp2{"$kwdPred"} || length($tmp2{"$kwdPred"})<1);

	($Lok,$msg,$tmp)=	# get subset
	    &getPhdSubset($tmp2{"$kwdPred"},$tmp2{"$kwdRi"},$riThresh,$riSymLoc);
	return(&errSbrMsg("failed writing subset from\n".$errMsg.$warnMsg,$msg)) if (! $Lok);
	$tmp2{"$kwd"}=$tmp;  }

				# empty line
    $ctkwd=$ctali;		# ctali = number of HSSP alis
    ++$ctkwd;
    $fin{"id","$ctkwd"}=        $kwdPhd;
    $fin{"seq","$ctkwd"}=       $symEmpty x $len;
    
    undef %Lok;			# ------------------------------
    foreach $kwd (@kwdPhd) {	# final correction: 
	next if (! defined $tmp2{"$kwd"});
				# hack: explicit surpressor for "OBSacc","PHDacc"
	next if ($kwd =~/^[OP]REL$/);
	++$ctkwd;
	$fin{"seq","$ctkwd"}=   $tmp2{"$kwd"}; # $tmp2{$kwd} -> $fin{'seq','$it'}
				# rename rows
	$kwdOut=$kwd;
	$kwdOut=$ptr{"$kwd"}    if (defined $ptr{"$kwd"});
	$fin{"id","$ctkwd"}=    $kwdOut;       # $kwd        -> $fin{'id','$it'}
	$Lok{"$kwd"}=           $ctkwd;
    }
    $fin{"NROWS"}=              $ctkwd;
    $fin{"PER_LINE"}=           $charPerLineLoc;
				# ------------------------------
				# read header/notation
    if ($formOutLoc eq "saf"){
				# open file
	$Lok=open($fhinLoc,$fileInPhdLoc);
	if ($Lok){		# read file
	    $tmpWrt="";
	    while (<$fhinLoc>) {
		$_=~s/\n//g;
		next if ($_ !~/\#.*NOTATION/);
		last if ($_ !~/\#/);
		$kwd=$_; $rd=$_;
		$kwd=~s/^\#.*NOTATION\s*(\S+)\s*:\s*(.*)$/$1/;
		$txt=$2;
		next if (! defined $Lok{"$kwd"});
		next if (! defined $ptr{"$kwd"});
		$kwdOut=$ptr{"$kwd"};
		$tmpWrt.=       sprintf("# NOTATION %-10s : %-s\n",$kwdOut,$txt); 
	    } close($fhinLoc);
				# add for subsets
	    $tmpWrt.=           sprintf("# NOTATION %-10s : %-s\n",
					"SUBsec",$notationSubsec) 
		if ($Lok{"PHEL"} && $Lok{"RI_S"} );
	    $tmpWrt.=           sprintf("# NOTATION %-10s : %-s\n",
					"SUBacc",$notationSubacc) 
		if ($Lok{"Pbie"} && $Lok{"RI_A"} );
	    $fin{"HEADER"}=$tmpWrt."\# \n";
	} }
				# --------------------------------------------------
				# finally write PHD + Ali
				# --------------------------------------------------
    if ($formOutLoc eq "msf") {	# MSF
	undef %tmp;		# build up anew
	$tmp{"NROWS"}=$fin{"NROWS"};
	$tmp{"FROM"}= $fileInHsspLoc;
	$tmp{"TO"}=   $fileOutLoc;
	foreach $it (1..$fin{"NROWS"}) {
	    $id=        $fin{"id","$it"};
	    $tmp{"$it"}=$id;
	    $tmp{"$id"}=$fin{"seq","$it"}; }
                                # open new file
	open($fhoutLoc,">".$fileOutLoc) ||
	    return(0,"*** ERROR $sbrName: failed opening fileOut=$fileOutLoc\n"); 
				# call
	($Lok)=
	    &msfWrt($fhoutLoc,%tmp);
	close($fhoutLoc);

	return(&errSbr("failed writing MSF from PHD".$errMsg.$warnMsg)) if (! $Lok); }
				# ------------------------------
    else {			# SAF = default
	($Lok,$msg)=
	    &safWrt($fileOutLoc,%fin);
	return(&errSbrMsg("failed writing SAF".$errMsg.$warnMsg,$msg)) if (! $Lok); }

				# ------------------------------
				# clean up
    undef %tmp; undef %tmp2; undef %fin; undef %Lok; undef %ptr; # slim-is-in!

    return(&errSbrMsg("failed writing output".$errMsg.$warnMsg,$msg)) 
	if (! -e $fileOutLoc);
    
    return(1,"ok $sbrName");
}				# end of phdAliWrt

#===============================================================================
sub phdHtmIsit {
    local($fileInLoc,$minValLoc,$minLenLoc,$doStatLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   phdHtmIsit                  returns best HTM
#       in:                     $fileInLoc        : PHD rdb file
#       in:                     $minValLoc        : average value of minimal helix (0.8)
#                                  undefined|0    -> defaults
#       in:                     $minLenLoc        : length of best helix (18)
#                                  undefined|0    -> defaults
#       in:                     $doStatLoc        : compute further statistics
#                                  undefined|0    -> defaults
#       out:                    1|0,msg,$LisMembrane (1=yes, 0=no),%tmp:
#                               $tmp{"valBest"}   : value of best HTM
#                               $tmp{"posBest"}   : first residue of best HTM
#                   if doStat:
#                               $tmp{"len"}       : length of protein
#                               $tmp{"nhtm"}      : number of membrane helices
#                               $tmp{"seqHtm"}    : sequence of all HTM (string)
#                               $tmp{"seqHtmBest"}: sequence of best HTM (string) 
#                                            (note: may be shorter than minLenLco)
#                               $tmp{"aveLenHtm"} : average length of HTM
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."phdHtmIsit";$fhinLoc="FHIN_"."phdHtmIsit";
				# ------------------------------
				# defaults
    $minValDefLoc= 0.8;		# average value of best helix (required)
    $minLenDefLoc= 18;		# length of best helix (18)
    $doStatDefLoc=0;		# compile further statistics on residues, avLength asf

				# ------------------------------
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
    $minValLoc=$minValDefLoc                       if (! defined $minValLoc || $minValLoc == 0);
    $minLenLoc=$minLenDefLoc                       if (! defined $minLenLoc || $minLenLoc == 0);
    $doStatLoc=$doStatDefLoc                       if (! defined $doStatLoc);

    $kwdNetHtm="OtH";		# name of column with network output for helix (0..100)
    $kwdPhdHtm="PHL";		# name of column with final prediction
    $kwdSeq=   "AA";		# name of column with sequence

    return(&errSbr("miss in file '$fileInLoc'!"))  if (! -e $fileInLoc);
    return(&errSbr("not RDB (htm) '$fileInLoc'!")) if (! &is_rdbf($fileInLoc));

    undef %tmp;
				# ------------------------------
				# read RDB file
    @kwdLoc=($kwdNetHtm);
    push(@kwdLoc,$kwdPhdHtm,$kwdSeq)    if ($doStatLoc);

    %tmp=
	&rdRdbAssociative($fileInLoc,"not_screen","header","PDBID","body",@kwdLoc); 
    return(&errSbr("failed reading $fileInLoc (rd_rdb_associative), kwd=".
		   join(',',@kwdLoc))) if (! defined $tmp{"NROWS"} || ! $tmp{"NROWS"});

				# ------------------------------
				# get network output values
    $#htm=0; 
    foreach $it (1..$tmp{"NROWS"}) {
	push(@htm,$tmp{"$kwdNetHtm","$it"}); }
				# ------------------------------
				# get best
    ($Lok,$msg,$valBest,$posBest)=
	&phdHtmGetBest($minLenLoc,@htm);
    return(&errSbrMsg("failed getting best HTM ($fileInLoc, minLenLoc=$minLenLoc,\n".
		      "htm=".join(',',@htm,"\n"),$msg)) if (! $Lok);
				# ------------------------------
				# IS or IS_NOT, thats the question
    $LisMembrane=0;
    $LisMembrane=1              if ($valBest >= $minValLoc);

    undef @htm;			# slim-is-in!

    undef %tmp2;
    $tmp2{"valBest"}=    $valBest;
    $tmp2{"posBest"}=    $posBest;

				# ------------------------------
				# no statics -> this is ALL!!
    if (! $doStatLoc) {		# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
	undef %tmp;
	return(1,"ok $sbrName",$LisMembrane,%tmp2);
    }				# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


				# --------------------------------------------------
				# now: do statistics
				# --------------------------------------------------
    $lenProt=$tmp{"NROWS"}; 
				# prediction -> string
    $seqHtm=$seqHtmBest=$phd="";
    foreach $it (1..$tmp{"NROWS"}) {
	$phd.=       $tmp{"$kwdPhdHtm","$it"}; 
				# subset of residues in HTM
	next if ($tmp{"$kwdPhdHtm","$it"} ne "H");
	$seqHtm.=    $tmp{"$kwdSeq","$it"};
				# subset of residues for best HTM
	next if ($posBest > $it || $it >  ($posBest + $minLenLoc));
	$seqHtmBest.=$tmp{"$kwdSeq","$it"};
    }
	
				# ------------------------------
				# average length
    $tmp=$phd;
    $tmp=~s/^[^H]*|[^H]$//g;	# purge non-HTM begin and end
    @tmp=split(/[^H]+/,$tmp);
    $nhtm=$#tmp;		# number of helices
    $htm=join('',@tmp);		# only helices
    $nresHtm=length($htm);	# total number of residues in helices

    $aveLenHtm=0;
    $aveLenHtm=($nresHtm/$nhtm) if ($nhtm > 0);


    $tmp2{"len"}=        $lenProt;
    $tmp2{"nhtm"}=       $nhtm;
    $tmp2{"seqHtm"}=     $seqHtm;
    $tmp2{"seqHtmBest"}= $seqHtmBest;
    $tmp2{"aveLenHtm"}=  $aveLenHtm;

				# ------------------------------
				# temporary write to file xxx
    if (0){			# xx
	$id=$tmp{"PDBID"};$id=~tr/[A-Z]/[a-z]/;
	$tmpWrt= sprintf("%-s\t%6.2f\t%5d\t%5d\t%5d\t%6.1f",
			 $id,$tmp2{"valBest"},$tmp2{"posBest"},
		     $tmp2{"len"},$tmp2{"nhtm"},$tmp2{"aveLenHtm"});
#	system("echo '$tmpWrt' >> stat-htm-glob.tmp");
#	system("echo '$tmpWrt' >> stat-htm-htm.tmp");
    }

    undef %tmp;			# slim-is-in

    return(1,"ok $sbrName",$LisMembrane,%tmp2);
}				# end of phdHtmIsit


#===============================================================================
sub phdHtmGetBest {
    local($minLenLoc,@tmp) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   phdHtmGetBest               returns position (begin) and average val for best HTM
#       in:                     $minValLoc        : average value of minimal helix (0.8)
#                                  = 0    -> defaults (18)
#       in:                     @tmp=             network output HTM unit (0 <= OtH <= 100)
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."phdHtmGetBest";$fhinLoc="FHIN_"."phdHtmGetBest";
				# check arguments
    return(&errSbr("no input!")) if (! defined @tmp || $#tmp==0);
    $minLenLoc=18                if ($minLenLoc == 0);

    $max=0;
				# loop over all residues
    foreach $it (1 .. ($#tmp + 1 - $minLenLoc)) {
				# loop over minLenLoc adjacent residues
	$htm=0;
	foreach $it2 ($it .. ($it + $minLenLoc - 1 )) {
	    $htm+=$tmp[$it2];}
				# store 
	if ($max < $htm) { $pos=$it;
			   $max=$htm; } }
				# normalise
    $val=$max/$minLenLoc;
    $val=$val/100;		# network written to 0..100

    return(1,"ok $sbrName",$val,$pos);
}				# end of phdHtmGetBest

#==========================================================================================
sub phdPredWrt {
    local ($fileOutLoc,$idvec,$desvec,$opt_phd,$nres_per_row,%all) = @_ ;
    local ($fh,@des,@id,$tmp,@tmp,$id,$it);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    phdPredWrt                 writes into file readable by EVALSEC|ACC
#       in:                     $fileOutLoc:     output file name
#                  alternative: STDOUT           -> write to STDOUT
#       in:                     $idvec:          'id1,id2,..' i.e. all ids to write
#       in:                     $desvec:         'AA,OHEL,PHEL,RI_S'
#       in:                     $opt_phd:        sec|acc|htm|?
#       in:                     $nres_per_row:   number of residues per row (80!)
#       in:                     $all{} with
#                               $all{'$id','NROWS'}= number of residues of protein $id
#                               $all{'$id','$des'}=  string for $des=
#                                   sec: AA|OHEL|PHEL|RI_S
#                                   acc: AA|OHEL|OREL|PREL|RI_A
#                                   htm: AA|OHL|PHL|PFHL|PRHL|PR2HL|RI_S|H
#       out:                    1|0,msg ; implicit: file_out
#       err:                    (1,'ok'), (0,'message')
#--------------------------------------------------------------------------------
    $sbrName="lib-br:"."phdPredWrt";$fh="FHOUT_"."phdPredWrt";
				# ------------------------------
				# check arguments
    return(0,"*** $sbrName: not def fileOutLoc!")       if (! defined $fileOutLoc);
    return(0,"*** $sbrName: not def idvec!")            if (! defined $idvec);
    return(0,"*** $sbrName: not def desvec!")           if (! defined $desvec);
    return(0,"*** $sbrName: not def opt_phd!")          if (! defined $opt_phd);
    return(0,"*** $sbrName: not def nres_per_row!")     if (! defined $nres_per_row);
				# ------------------------------
				# vector to array
    @des=split(/[\t,]/,$desvec);
    @id= split(/[\t,]/,$idvec);
    %translate=
	# sequence       observed struc   predicted struc    reliability
	('AA_sec',"AA", 'OHEL_sec',"DSP", 'PHEL_sec', "PRD", 'RI_S_sec',"Rel", # sec
	 'AA_acc',"AA", 'OHEL_acc',"SS", 
	                'OREL_acc',"Obs", 'PREL_acc', "Prd", 'RI_A_acc',"Rel", # acc
	 'AA_htm',"AA", 'OHL_htm', "OBS", 'PHL_htm',  "PHD", 'RI_H_htm',"Rel", # htm
	                'OTN_htm', "OBS", 'PTN_htm',  "PHD", 'RI_S_htm',"Rel",
	                                  'PfhL_htm', "FIL",
	                                  'PRHL_htm', "PHD",
	                                  'PR2HL_htm',"PHD");

                                # ------------------------------
                                # open file
    if ($fileOutLoc eq "STDOUT"){
	$fh="STDOUT";}
    else {
	open($fh, ">".$fileOutLoc) || return(&errSbr("fileOut=$fileOutLoc, not created"));}

				# ------------------------------
				# write header
    print $fh  "* PHD_DOTPRED_8.95 \n"; # recognised key word!
    print $fh  "*" x 80, "\n","*"," " x 78, "*\n";
    if   ($opt_phd eq "sec"){$tmp="PHDsec: secondary structure prediction by neural network";}
    elsif($opt_phd eq "acc"){$tmp="PHDacc: solvent accessibility prediction by neural network";}
    elsif($opt_phd eq "htm"){$tmp="PHDhtm: helical transmembrane prediction by neural network";}
    else                    {$tmp="PHD   : Profile prediction by system of neural networks";}
    printf $fh "*    %-72s  *\n",$tmp;
    printf $fh "*    %-72s  *\n","~" x length($tmp);
    printf $fh "*    %-72s  *\n"," ";
    if   ($desvec =~/PRHL/) {$tmp="VERSION: REFINE: best model";}
    elsif($desvec =~/PR2HL/){$tmp="VERSION: REFINE: 2nd best model";}
    elsif($desvec =~/PFHL/ ){$tmp="VERSION: FILTER: old stupid filter of HTM";}
    elsif($desvec =~/PHL/ ) {$tmp="VERSION: probably no HTM filter, just network";}
    printf $fh "*    %-72s  *\n",$tmp;
    print  $fh "*"," " x 78, "*\n";
    @tmp=("Burkhard Rost, EMBL, 69012 Heidelberg, Germany",
	  "(Internet: rost\@EMBL-Heidelberg.DE)");
    foreach $tmp (@tmp) {
	printf $fh "*    %-72s  *\n",$tmp;}
    print  $fh "*"," " x 78, "*\n";
    $tmp=&sysDate();
    printf $fh "*    %-72s  *\n",substr($tmp,1,70);
    print  $fh "*"," " x 78, "*\n";
    print  $fh "*" x 80, "\n";
				# numbers
    $tmp=$#id;
    printf $fh "num %4d\n",$tmp;
    if ($opt_phd eq "acc"){print $fh "nos(ummary)\n";}
				# --------------------------------------------------
				# loop over all proteins
    foreach $it (1..$#id) {     # --------------------------------------------------
	$id=  $id[$it];
        $nres=$all{"$id","NROWS"};
                                # ------------------------------
				# header (name, length)
        printf $fh "    %-6s %5d\n",substr($id,1,6),$nres   if ($opt_phd eq "acc");
        printf $fh "    %10d %-s\n",$nres,$id               if ($opt_phd ne "acc");
                                # ------------------------------
				# phd/obs for each protein
        for ($itres=1; $itres<=$nres; $itres+=$nres_per_row) {
                                # points
            printf $fh "%-3s %-s\n"," ",&myprt_npoints($nres_per_row,$itres);
            foreach $des (@des) {
                                # translate description
		$desTranslate= $des."_".substr($opt_phd,1,3);
		$txt=          $translate{"$desTranslate"};
                                # skip if shorter than current
                next if (! defined $all{"$id","$des"}  || length($all{"$id","$des"})<$it);
                                # finally: write the shit
                printf $fh 
                    "%-3s|%-s|\n",$txt,substr($all{"$id","$des"},$itres,$nres_per_row); }
        }                       # end of loop over all residues
    }                           # end of loop over all proteins
    print $fh "END\n"; 
    close($fh)                  if ($fh ne "STDOUT");

    undef %all;			# slim-is-in!

    return(1,"ok $sbrName");
}				# end of phdPredWrt

#===============================================================================
sub phdRdbMerge {
    local ($fileOutRdbLoc,$fileAbbrRdb,@fileRdbLoc) = @_ ;
    local ($SBR1,$fhoutLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   phdRdbMerge                 manages merging two PHD *.rdb files ('name'= acc + sec + htm)
#       in:                     $fileOutRdbLoc : name of RDB output
#       in:                     $fileAbbrRdb   : file explaining the abbreviations in RDB file
#       in:                     @fileRdbLoc=
#       in:                        $fileSec    : PHD rdb with sec output
#       in:                        $fileAcc    : PHD rdb with acc output
#       in:                        $fileHtm    : PHD RDB with HTM output
#       out:                    1|0,$ERROR_msg|$WARNING_MESSAGE  implicit: file
#       err:                    (1,'ok warning message'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR1="lib-br:phdRdbMerge"; $fhoutLoc="FHOUT_".$SBR1;
				# ------------------------------
				# arguments given ?
    return(&errSbr("not def fileOutRdbLoc!",$SBR1))  if (! defined $fileOutRdbLoc);
    return(&errSbr("not def fileAbbrRdb!",$SBR1))    if (! defined $fileAbbrRdb);
				# ------------------------------
				# syntax check
    return(&errSbr("too few files (<2):".join(',',@fileRdbLoc),$SBR1))
	if ($#fileRdbLoc < 2);
				# ------------------------------
				# input files existing ?
    foreach $it (1..$#fileRdbLoc){
        return(&errSbr("no file($it)=$fileRdbLoc[$it]!",$SBR1)) 
            if (! -e $fileRdbLoc[$it]); }

                                # ------------------------------
				# set defaults
    &phdRdbMergeDef;
				# --------------------------------------------------
				# merge files (immediately write)
				# --------------------------------------------------
    open($fhoutLoc, ">".$fileOutRdbLoc);
    ($Lok,$msg)=
        &phdRdbMergeDo($fileAbbrRdb,$fhoutLoc,@fileRdbLoc);
    close($fhoutLoc);
    return(&errSbrMsg("failed on phdRdbMergeDo (fh=$fhoutLoc,ARRAY=".
                      join(',',@fileRdbLoc),$msg,$SBR1))
        if (! $Lok);

    return(1,"ok $SBR1\n"."warn message from phdRdbMergeDo (into $SBR1):\n".$msg);

}				# end of phdRdbMerge

#===============================================================================
sub phdRdbMergeDef {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   phdRdbMergeDef              sets defaults for phdRdbMerg
#       in/out GLOBAL:          all
#-------------------------------------------------------------------------------
    @desSec=
        ("No","AA","OHEL","PHEL","RI_S","pH","pE","pL","OtH","OtE","OtL");
    @desAcc=
        ("OACC","PACC","OREL","PREL","RI_A","Obie","Pbie");
    for $it (0..9){
        push(@desAcc,"Ot".$it); }
    @desHtm=
        ("OHL","PHL","PFHL","PRHL","PiTo","RI_H","pH","pL","OtH","OtL");

    @desOutG=
        ("No","AA","OHEL","PHEL","RI_S","OtH","OtE","OtL",
         "OACC","PACC","OREL","PREL","RI_A","Obie","Pbie");
    @formOut=
        ("4N","1" ,"1"   ,"1"   ,"1N",  "3N", "3N", "3N",
         "3N"  ,"3N"  ,"3N",  "3N",  "1N",  "1",   "1");
    for $it (0..9){
        push(@desOutG,"Ot".$it); 
        push(@formOut,"3N");}
    push(@desOutG, 
         "OTN","PTN","PFTN","PRTN","PiTo","RI_H","OtT","OtN");
    push(@formOut,
         "1"  ,"1"  ,"1"   ,"1"   ,"1"   ,"1N"  ,"3N" ,"3N");

    foreach $it (1..$#desOutG){
        $tmp=$formOut[$it];
        if   ($tmp=~/N$/) {$tmp=~s/N$/d/;$formOutPrintf{"$desOutG[$it]"}=$tmp;}
        elsif($tmp=~/F$/) {$tmp=~s/F$/f/;$formOutPrintf{"$desOutG[$it]"}=$tmp;}
        else              {$tmp.="s";    $formOutPrintf{"$desOutG[$it]"}=$tmp;} }
    $sep="\t";                  # separator

}				# end of phdRdbMergeDef

#===============================================================================
sub phdRdbMergeDo {
    local ($fileAbbrRdb,$fhoutLoc,@fileRdbLoc) = @_ ;
    local ($fhinLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   phdRdbMergeDo               merging two PHD *.rdb files ('name'= acc + sec)
#       in GLOBAL:              @desSec,@desAcc,@headerHtm,@desHtm
#       in:                     $fileAbbrRdb   : file explaining the abbreviations in RDB file
#       in:                     $fhoutLoc      : file handle for RDB output file
#       in:                     @fileRdbLoc=
#       in:                        $fileSec    : PHD rdb with sec output
#       in:                        $fileAcc    : PHD rdb with acc output
#       in:                        $fileHtm    : PHD RDB with HTM output
#       out:                    1|0,$ERROR_msg|$WARNING_MESSAGE  implicit: file
#       err:                    (1,'ok warning message'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR2="lib-br:phdRdbMerge"; $fhinLoc="FHIN_".$SBR2;
                                # --------------------------------------------------
                                # reading files
                                # --------------------------------------------------
    $LisAccLoc=$LisHtmLoc=$LisSecLoc=
        $#headerSec=$#headerAcc=$#headerHtm=0;
    foreach $file (@fileRdbLoc){
				# secondary structure
	if    (&is_rdb_sec($file)){
            open($fhinLoc, $file) || return(&errSbr("sec failed in=$file",$SBR2));
	    while (<$fhinLoc>){
                $rd=$_;
                push(@headerSec,$rd) if (($rd=~/^\#/) && ($rd !~ /^\# NOTATION/));
                last if ($rd !~ /^\#/);}
	    close($fhinLoc);$LisSecLoc=1;
	    %rdSec=
                &rd_rdb_associative($file,"not_screen","body",@desSec); }
				# accessibility
	elsif (&is_rdb_acc($file)){
            open($fhinLoc, $file) || return(&errSbr("acc failed in=$file",$SBR2));
	    while(<$fhinLoc>){
                $rd=$_;
                push(@headerAcc,$rd) if (($rd=~/^\#/) && ($rd !~ /^\# NOTATION/));
                last if ($rd !~ /^\#/);}
	    close($fhinLoc);$LisAccLoc=1;
	    %rdAcc=
                &rd_rdb_associative($file,"not_screen","body",@desAcc);}
				# htm
	elsif (&is_rdb_htmtop($file) || &is_rdb_htmref($file) || &is_rdb_htm($file) ){ 
	    open($fhinLoc, $file) || return(&errSbr("htm failed in=$file",$SBR2));
	    while(<$fhinLoc>){
                $rd=$_;
                push(@headerHtm,$rd) if (($rd=~/^\#/) && ($rd !~ /^\# NOTATION/));
                last if ($rd !~ /^\#/);}
	    close($fhinLoc);$LisHtmLoc=1;
	    %rdHtm=
                &rd_rdb_associative($file,"not_screen","body",@desHtm);
	    foreach $ct (1..$rdHtm{"NROWS"}){
		$rdHtm{"OTN","$ct"}= $rdHtm{"OHL","$ct"};
		$rdHtm{"PTN","$ct"}= $rdHtm{"PHL","$ct"};
		$rdHtm{"PFTN","$ct"}=$rdHtm{"PFHL","$ct"};
		$rdHtm{"PRTN","$ct"}=$rdHtm{"PRHL","$ct"};
		$rdHtm{"OtT","$ct"}= $rdHtm{"OtH","$ct"};
		$rdHtm{"OtN","$ct"}= $rdHtm{"OtL","$ct"};} }
	else {
	    return(&errSbr("file=$file not recognised format",$SBR2));} 
    }                           # end of all 2-3 input files

                                # ------------------------------
				# decide when to break the line
    if ($LisHtmLoc){
        $desNewLine="OtN";}
    else{
        $desNewLine="Ot9";}
				# ------------------------------
				# read abbreviations
				# ------------------------------
    $#header=0;
    if (defined $fileAbbrRdb && $fileAbbrRdb && -e $fileAbbrRdb){
	open($fhinLoc, $fileAbbrRdb)  || 
	    return(&errSbr("abbr failed in=$fileAbbrRdb",$SBR2));
	while(<$fhinLoc>){
	    $rd=$_;$rd=~s/\n//g;
	    push(@header,$rd)   if($rd=~/^\# NOTATION/);}
	close($fhinLoc); }
				# --------------------------------------------------
				# write header into file
				# --------------------------------------------------
    $warnMsg=
        &phdRdbMergeHdr($fhoutLoc);
				# --------------------------------------------------
				# write selected columns
				# --------------------------------------------------
                                # names
    foreach $des (@desOutG) {
        if (defined $rdSec{"$des","1"} || defined $rdAcc{"$des","1"} || 
	    defined $rdHtm{"$des","1"}) {
	    $sep_tmp=$sep; 
            $sep_tmp="\n"       if ($des eq $desNewLine);
            print $fhoutLoc "$des","$sep_tmp"; }}
                                # ------------------------------
                                # formats
    foreach $it (1..$#format_out) {
        if (defined $rdSec{"$desOutG[$it]","1"} || defined $rdAcc{"$desOutG[$it]","1"} ||
	    defined $rdHtm{"$desOutG[$it]","1"}) {
	    $sep_tmp=$sep; 
            $sep_tmp="\n"       if ($desOutG[$it] eq $desNewLine);
            print $fhoutLoc "$format_out[$it]","$sep_tmp"; } }
                                # ------------------------------
                                # data
    foreach $mue (1..$rdSec{"NROWS"}){
                                # sec
        foreach $des("No","AA","OHEL","PHEL","RI_S","OtH","OtE","OtL") {
            next if (! defined $rdSec{"$des","$mue"} );
            $tmp="%".$formOutPrintf{"$des"};
            $rd=$rdSec{"$des","$mue"};
            $rd=~s/\s|\n//g;
            printf $fhoutLoc "$tmp$sep",$rd; }
                                # acc
        foreach $des("OACC","PACC","OREL","PREL","RI_A","Obie","Pbie",
                   "Ot0","Ot1","Ot2","Ot3","Ot4","Ot5","Ot6","Ot7","Ot8","Ot9") {
            next if (! defined $rdAcc{"$des","$mue"});
            $tmp="%".$formOutPrintf{"$des"};
	    $sep_tmp=$sep; 
            $sep_tmp="\n"       if ($des eq $desNewLine);
            $rd=$rdAcc{"$des","$mue"};
            $rd=~s/\s|\n//g;
            printf $fhoutLoc "$tmp$sep_tmp",$rd; }
	next if (! $LisHtmLoc);
                                # htm
        foreach $des ("OTN","PTN","PFTN","PRTN","PiTo","RI_H","OtT","OtN"){
            next if (! defined $rdHtm{"$des","$mue"});
            $tmp="%".$formOutPrintf{"$des"};
	    $sep_tmp=$sep; 
            $sep_tmp="\n"       if ($des eq $desNewLine);
            $rd=$rdHtm{"$des","$mue"};
            $rd=~s/\s|\n//g;
            printf $fhoutLoc "$tmp$sep_tmp",$rd; }
    }
				# all fine
    return(1,"ok $SBR2")        if (! defined $warnMsg || ! $warnMsg ||
				    $warnMsg !~ /WARN/);
				# warning in hdr
    return(1,"ok $SBR2 warn=\n".$warnMsg."\n");
}				# end of phdRdbMergeDo

#===============================================================================
sub phdRdbMergeHdr {
    local($fhoutLoc) = @_ ;
    local($SBR3);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   phdRdbMergeHdr              writes the merged RDB header
#-------------------------------------------------------------------------------
    $SBR3="lib-br:phdRdbMergHdr";
                                # ------------------------------
                                # keyword
    print $fhoutLoc "\# Perl-RDB\n";
    if ($LisSecLoc && $LisAccLoc && $LisHtmLoc){ 
	print  $fhoutLoc 
	    "\# PHDsec+PHDacc+PHDhtm\n",
	    "\# Prediction of secondary structure, accessibility, and transmembrane helices\n";}
    elsif ($LisSecLoc && $LisAccLoc){ 
	print  $fhoutLoc 
	    "\# PHDsec+PHDacc\n",
	    "\# Prediction of secondary structure, and accessibility\n";}
                                # ------------------------------
				# special information from header
    foreach $rd (@headerSec){
        $tmp=$rd;$tmp=~s/^\# ([A-Za-z0-9_]+).*$/$1/g;
        next if ($rd =~/^\# (NOTATION|Perl|PHD)/i);
        $Lok{"$tmp"}=1;         # to avoid duplication of information
        print $fhoutLoc $rd;}
    foreach $rd (@headerAcc){
        $tmp=$rd;$tmp=~s/^\# ([A-Za-z0-9_]+).*$/$1/g;
        next if ($rd =~/^\# (NOTATION|Perl|PHD)/i);
        next if (defined $Lok{"$tmp"});
        $Lok{"$tmp"}=1;         # to avoid duplication of information
        print $fhoutLoc $rd;}
    foreach $rd (@headerHtm){
        $tmp=$rd;$tmp=~s/^\# ([A-Za-z0-9_]+).*$/$1/g;
        next if ($rd =~/^\# (NOTATION|Perl|PHD)/i);
        next if (defined $Lok{"$tmp"});
				# to avoid duplication of information
        $Lok{"$tmp"}=1 if ($rd !~/MODEL_DAT/); # exception!
        print $fhoutLoc $rd;}
                                # ------------------------------
    foreach $desOut(@desOutG){	# notation
	$Lok=0;
                                # special case accessibility net out (skip 1-9)
	next if ($desOut =~ /^Ot[1-9]/);
                                # special case accessibility net out (write 0)
	if ($desOut =~ /^Ot0/){
	    foreach $rd(@header){
		next if ($rd !~/^Ot\(n\)/);
                $Lok=1;
                print $fhoutLoc "$rd\n";
                last; }
	    next;}
	foreach $rd (@header){
	    next if ($rd !~/$desOut/);
            $Lok=1;
            print $fhoutLoc "$rd\n";
            last; } 
        $errMsg3="-*- WARNING rdbMergeDo \t missing description for desOut=$desOut\n"
            if (! $Lok); }
    print $fhoutLoc "\# \n";

    return($errMsg3);
}				# end of phdRdbMergeHdr

#==============================================================================
sub phdRun {                    # input files/modes
    local ($fileHssp,$chainHssp,$fileParaSec,$fileParaAcc,$fileParaHtm,$fileAbbrRdb,
           $optPhd3,$optRdbLoc,
                                # executables
           $exePhdLoc,$exeHtmfilLoc,$exeHtmrefLoc,$exeHtmtopLoc,
                                # modes FORTRAN
	   $optMachLoc,$optKgLoc,$useridLoc,$optIsDecLoc,$optNiceInLoc,
                                # modes HTM post
           $optDoHtmfilLoc,$optDoHtmisitLoc,$optHtmisitMinLoc,$optDoHtmrefLoc,$optDoHtmtopLoc,
                                # output files
	   $fileOutPhdLoc,$fileOutRdbLoc,$fileOutNotLoc,
                                # temporary stuff
	   $dirLib,$dirWorkLoc,$titleTmpLoc,$jobidLoc,
           $LdebugLoc,$fileOutScreenLoc,$fhSbrErr) = @_;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   phdRun                      runs all 3 FORTRAN programs PHD
#            input files/modes
#       in:                     $fileHssp      : HSSP file to run it on
#       in:                     $chainHssp     : name of chain
#       in:                     $filePara*     : name of file with phd.f network parameters
#                                                for modes sec,acc,htm
#                                   = 0          to surpress
#       in:                     $optPhd3       : mode = 3|both|sec|acc|htm  (else -> ERROR)
#       in:                     $optRdbLoc     : write RDB, or not (ancient)
#       in:                     $fileAbbrRdb   : file explaining the abbreviations in RDB file
#            executables
#       in:                     $exePhd        : FORTRAN executable for PHD
#       in:                     $exeHtmfilLoc  : Perl executable for HTMfil
#       in:                     $exeHtmrefLoc  : Perl executable for HTMref
#       in:                     $exeHtmtopLoc  : Perl executable for HTMtop
#            modes FORTRAN
#       in:                     $optMachLoc    : for tim
#       in:                     $optKgLoc      : for KG format
#       in:                     $useridLoc     : user name         (for PP/non-pp)
#       in:                     $optIsDecLoc   : machin is DEC     (ancient)
#            modes HTM
#       in:                     $optDoHtmfil   : 1|0 do or do NOT run
#       in:                     $optDoHtmisit  : 1|0 do or do NOT run
#       in:                     $optHtmisitMin : strength of minimal HTM (default 0.8|0.7)
#                                   = >0 && <1 , real
#       in:                     $optDoHtmref   : 1|0 do or do NOT run
#       in:                     $optDoHtmtop   : 1|0 do or do NOT run
#            output files
#       in:                     $fileOutPhdLoc : human readable file
#       in:                     $fileOutRdbLoc : RDB formatted output
#       in:                     $fileOutNotLoc : file flagging that no HTM was detected
#            PERL libraries
#       in:                     $dirLib        : directory of PERL libs
#                                   = 0          to surpress (and believe scripts will run...)
#            temporary stuff
#       in:                     $dirWork       : working dir
#       in:                     $titleTmpLoc   : temporary files 'dirWork.titleTmp.jobid.extX'
#       in:                     $jobidLoc      : temporary files 'dirWork.titleTmp.jobid.extX'
#       in:                     $LdebugLoc     : =1 -> keep temporary files, =0 -> delete them
#       in:                     $fileOutScreen : screen dumpb of system call  if = 0: 0 -> STDOUT
#       in:                     $fhSbrErr      : error file handle
#                NOTE:              = 0          to surpress writing
#       out:                    1|0,msg,%tmpFiles(list='f1,f2,f3')  implicit: files
#       out:                    
#       out:                    $fileTmp{$kwd} : with
#                               $fileTmp{kwd}= 'kwd1,kwd2,kwd3,...'
#                               $fileTmp{$kwd}  file, e.g.:
#                               $fileTmp{"sec|acc|htm|both|3","phd|rdb"}
#                NOTE:                  tmpFiles='' if ! debug (all deleted, already)
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."phdRun";
				# ------------------------------
				# arguments given ?
    return(&errSbr("not def fileHssp!"))             if (! defined $fileHssp);
    return(&errSbr("not def chainHssp!"))            if (! defined $chainHssp);
    return(&errSbr("not def fileParaSec!"))          if (! defined $fileParaSec);
    return(&errSbr("not def fileParaAcc!"))          if (! defined $fileParaAcc);
    return(&errSbr("not def fileParaHtm!"))          if (! defined $fileParaHtm);
    return(&errSbr("not def optPhd3!"))              if (! defined $optPhd3);
    return(&errSbr("not def optRdbLoc!"))            if (! defined $optRdbLoc);
    return(&errSbr("not def fileAbbrRdb!"))          if (! defined $fileAbbrRdb);

    return(&errSbr("not def exePhdLoc!"))            if (! defined $exePhdLoc);
    return(&errSbr("not def exeHtmfilLoc!"))         if (! defined $exeHtmfilLoc);
    return(&errSbr("not def exeHtmrefLoc!"))         if (! defined $exeHtmrefLoc);
    return(&errSbr("not def exeHtmtopLoc!"))         if (! defined $exeHtmtopLoc);

    return(&errSbr("not def optMachLoc!"))           if (! defined $optMachLoc);
    return(&errSbr("not def optKgLoc!"))             if (! defined $optKgLoc);
    return(&errSbr("not def useridLoc!"))            if (! defined $useridLoc);
    return(&errSbr("not def optIsDecLoc!"))          if (! defined $optIsDecLoc);
    return(&errSbr("not def optNiceInLoc!"))         if (! defined $optNiceInLoc);

    return(&errSbr("not def optDoHtmfilLoc!"))       if (! defined $optDoHtmfilLoc);
    return(&errSbr("not def optDoHtmisitLoc!"))      if (! defined $optDoHtmisitLoc);
    return(&errSbr("not def optHtmisitMinLoc!"))     if (! defined $optHtmisitMinLoc);
    return(&errSbr("not def optDoHtmrefLoc!"))       if (! defined $optDoHtmrefLoc);
    return(&errSbr("not def optDoHtmtopLoc!"))       if (! defined $optDoHtmtopLoc);

    return(&errSbr("not def fileOutPhdLoc!"))        if (! defined $fileOutPhdLoc);
    return(&errSbr("not def fileOutRdbLoc!"))        if (! defined $fileOutRdbLoc);
    return(&errSbr("not def fileOutNotLoc!"))        if (! defined $fileOutNotLoc);

    return(&errSbr("not def dirLib!"))               if (! defined $dirLib);

    return(&errSbr("not def dirWorkLoc!"))           if (! defined $dirWorkLoc);
    return(&errSbr("not def titleTmpLoc!"))          if (! defined $titleTmpLoc);
    return(&errSbr("not def jobidLoc!"))             if (! defined $jobidLoc);
    return(&errSbr("not def LdebugLoc!"))            if (! defined $LdebugLoc);
#    return(&errSbr("not def !"))           if (! defined $);
				# ------------------------------
				# input files existing ?
    return(&errSbr("miss in file '$fileHssp'!"))     if (! -e $fileHssp);
    return(&errSbr("not HSSP file '$fileHssp'!"))    if (! &is_hssp($fileHssp));
    return(&errSbr("empty HSSP file '$fileHssp'!"))  if (&is_hssp_empty($fileHssp));
                                # ------------------------------
                                # executables ok?
    foreach $exe ($exePhdLoc,$exeHtmfilLoc,$exeHtmrefLoc,$exeHtmtopLoc){
        return(&errSbr("miss in file '$exe'!"))      if (! -e $exe && ! -l $exe);
        return(&errSbr("not executable '$exe'!"))    if (! -x $exePhdLoc ); }
				# ------------------------------
				# syntax check
    return(&errSbr("ini: FORTRAN PHD optPhd ($optPhd3) has to be '3|both|sec|acc|htm'"))
	if ($optPhd3 !~ /^(3|both|sec|acc|htm)$/);
    return(&errSbr("ini: PHD parameter (sec) file=$fileParaSec, missing"))
	if ($fileParaSec && ! -e $fileParaSec);
    return(&errSbr("ini: PHD parameter (acc) file=$fileParaAcc, missing"))
	if ($fileParaAcc && ! -e $fileParaAcc);
    return(&errSbr("ini: PHD parameter (acc) file=$fileParaAcc, missing"))
	if ($fileParaAcc && ! -e $fileParaAcc);

				# ------------------------------
				# other input
    $fhSbrErr="STDOUT"          if (! defined $fhSbrErr);
    $fileOutScreenLoc=0         if (! defined $fileOutScreenLoc || ! $fileOutScreenLoc);

    $errMsg= "*** ERROR $sbrName: in:\n";

    undef %Lok;                 # for results from PHD
    foreach $des ("sec","acc","htm") {
        $Lok{$des}=1; }
                                # ------------------------------
                                # temporary files
                                # ------------------------------
    ($Lok,$msg)=
	&phdRunIniFileNames($optPhd3,$dirWorkLoc,$titleTmpLoc,$jobidLoc);
    return(&errSbr("ini: build up of temporary files (phdRunIniFileNames) failed\n".
		   $msg."\n"))
        if (! $Lok || ! defined $fileTmp{"kwd"} || length($fileTmp{"kwd"}) < 3);

                                # --------------------------------------------------
                                # running all 3 FORTRAN programs
                                # --------------------------------------------------

                                 # ------------------------------
    if ($optPhd3=~/sec|3|both/){ # running PHDsec
                                 # ------------------------------
	$optPhd="sec";
	($Lok{"sec"},$msg)=
	    &phdRun1($fileHssp,$chainHssp,$par{"exePhd"},$optPhd,$fileParaSec,$optRdbLoc,
                     $optMachLoc,$optKgLoc,$useridLoc,$optIsDecLoc,$optNiceInLoc,
                     $fileTmp{$optPhd,"phd"},$fileTmp{$optPhd,"rdb"},
                     $dirWorkLoc,$fileOutScreenLoc,$fhSbrErr);
        $errMsg.=$msg."\n"      if (! $Lok{$optPhd}); }

                                 # ------------------------------
    if ($optPhd3=~/acc|3|both/){ # running PHDacc
                                 # ------------------------------
	$optPhd="acc";
	($Lok{"acc"},$msg)=
	    &phdRun1($fileHssp,$chainHssp,$par{"exePhd"},$optPhd,$fileParaAcc,$optRdbLoc,
                     $optMachLoc,$optKgLoc,$useridLoc,$optIsDecLoc,$optNiceInLoc,
                     $fileTmp{$optPhd,"phd"},$fileTmp{$optPhd,"rdb"},
                     $dirWorkLoc,$fileOutScreenLoc,$fhSbrErr);
        $errMsg.=$msg."\n"      if (! $Lok{$optPhd}); }

				# ------------------------------
    if ($optPhd3=~/htm|3/){     # running PHDhtm
                                # ------------------------------
	$optPhd="htm";          # FORTRAN
	($Lok{"htm"},$msg)=
	    &phdRun1($fileHssp,$chainHssp,$par{"exePhd"},$optPhd,$fileParaHtm,$optRdbLoc,
                     $optMachLoc,$optKgLoc,$useridLoc,$optIsDecLoc,$optNiceInLoc,
                     $fileTmp{$optPhd,"phd"},$fileTmp{$optPhd,"rdb"},
                     $dirWorkLoc,$fileOutScreenLoc,$fhSbrErr);
        $errMsg.=$msg."\n"      if (! $Lok{$optPhd}); 
                                # ------------------------------
				# post-processing PHDhtm
        if (-e $fileTmp{"htm","phd"} &&
            ($optDoHtmisitLoc || $optDoHtmrefLoc || $optDoHtmtopLoc || $optDoHtmfilLoc) ) {
                                # delete FLAG file if existing
            if (-e $fileOutNotLoc){
                unlink ($fileOutNotLoc);
                print $fhSbrErr 
                    "*** WATCH! flag file '$fileOutNotLoc' (flag for NOT htm) existed!\n"
                        if ($fhSbrErr); }

            ($Lok{$optPhd},$msg,$LisHtm)=
                &phdRunPost1($fileHssp,$chainHssp,$fileTmp{"htm","rdb"},$dirLib,$optNiceInLoc,
			     $exeHtmfilLoc,$exeHtmrefLoc,$exeHtmtopLoc,
			     $optDoHtmfilLoc,$optDoHtmisitLoc,$optHtmisitMinLoc,
			     $optDoHtmrefLoc,$optDoHtmtopLoc,
			     $fileOutNotLoc,$fileTmp{"htmfin","rdb"},
			     $fileTmp{"htmfil","rdb"},
			     $fileTmp{"htmref","rdb"},$fileTmp{"htmtop","rdb"},
			     $fileOutScreenLoc,$fhSbrErr);
            $errMsg.=$msg."\n"  if (! $Lok{$optPhd}); }
                                # skip post-processing
        elsif (-e $fileTmp{"htm","phd"}) {
            $LisHtm=1;
            $fileTmp{"htmfin","rdb"}=$fileTmp{"htm","rdb"}; } 
        else {
            $LisHtm=0; } }
				# -------------------------------------------------
				# error check
				# -------------------------------------------------
    $Lerr=0;
    foreach $des ("sec","acc","htm"){
	if (! $Lok{"$des"}){ 
	    $Lerr=1;
	    $errMsg.="*** ERROR $scrName: PHD$des: no pred file (in=$fileHssp)\n";}}
    return(&errSbrMsg("after all 3",$errMsg)) if ($Lerr);
                
				# -------------------------------------------------
				# now writing output for one file
				# -------------------------------------------------
    if ($optPhd3 =~/^(3|both)$/){
	$optPhd3Tmp=$optPhd3;
        if ($optPhd3 eq "both" || ! $LisHtm){
				# reduce mode if NOT htm
            $optPhd3Tmp="both";
				# delete file
	    unlink($fileTmp{"htmfin","rdb"}) 
		if (defined $fileTmp{"htmfin","rdb"} && -e $fileTmp{"htmfin","rdb"});
				# dummy
            $fileTmp{"htmfin","rdb"}=0; }

                                # ------------------------------
                                # call writer
                                # 
                                # ++++++++++++++++++++++++++++++
                                # NOTE: not writing file.phd, yet yy
                                # ++++++++++++++++++++++++++++++
        ($Lok,$msg)=
            &phdRunWrt($optPhd3Tmp,$optRdbLoc,$fileAbbrRdb,$fileTmp{"sec","rdb"},
                       $fileTmp{"acc","rdb"},$fileTmp{"htmfin","rdb"},
                       $fileOutPhdLoc,$fileOutRdbLoc);
        return(&errSbrMsg("phdRunWrt failed",$msg)) if (! $Lok);
        print $fhSbrErr "-*- WARN $sbrName: phdRunWrt returned warn:\n",$msg,"\n"
            if ($fhSbrErr && $msg =~ /WARN/); }
                                # ------------------------------
    else {                      # simply copy
        foreach $des("sec","acc","htm"){
            next if ($optPhd3 ne $des);
	    $desrdb=$des;
	    $desrdb="htmfin"   if ($des eq "htm"); # take refined one!
            $filePhd=$fileTmp{"$des","phd"};
            $fileRdb=$fileTmp{"$desrdb","rdb"}; 
            last; }
	($Lok,$msg)=
            &sysCpfile($filePhd,$fileOutPhdLoc) if (-e $filePhd);
        return(&errSbr("fin: failed copy ($filePhd->$fileOutPhdLoc)\n".
		       "msg=\n$msg\n")) if (! $Lok);
        ($Lok,$msg)=
            &sysCpfile($fileRdb,$fileOutRdbLoc) if (-e $fileRdb);
        return(&errSbr("fin: failed copy ($fileRdb->$fileOutRdbLoc)\n".
		       "msg=\n$msg\n")) if (! $Lok); }

				# -------------------------------------------------
                                # clean up?
				# -------------------------------------------------
    if (! $LdebugLoc){
        @tmp=split(/,/,$fileTmp{"kwd"});
        foreach $kwd (@tmp){
	    $file=$fileTmp{$kwd};
            next if (! -e $file);
	    next if ($file eq $fileOutPhdLoc ||
		     $file eq $fileOutRdbLoc ||
		     $file eq $fileOutNotLoc ||
		     $file eq $fileAbbrRdb);
            unlink($file);
            print $fhSbrErr "--- $sbrName: rm temp file '$file'\n" if ($fhSbrErr); }
        $fileTmp{"kwd"}=0; }

    return(1,"ok $sbrName",%fileTmp);
}				# end of phdRun

#==============================================================================
sub phdRun1 {
    local ($fileHssp,$chainIn,$exePhdLoc,$optPhdLoc,$optParaLoc,$optRdbLoc,
	   $optMachLoc,$optKgLoc,$useridLoc,$optIsDecLoc,$optNiceInLoc,
	   $fileOutPhdLoc,$fileOutRdbLoc,$dirWorkLoc,$fileOutScreenLoc,$fhSbrErr) = @_;
    local ($tmp,$fileHssp_loc,$optPath_work_loc,$optPhd_loc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   phdRun1                     runs the FORTRAN program PHD once (sec XOR acc XOR htm) 
#       in:                     $fileHssp      : HSSP file to run it on
#       in:                     $chainIn       : name of chain
#       in:                     $exePhd        : FORTRAN executable for PHD
#       in:                     $optPhd        : mode = sec|acc|htm  (else -> ERROR)
#       in:                     $optPara       : name of file with phd.f network parameters
#       in:                     $optRdbLoc     : write RDB, or not (ancient)
#       in:                     $optMachLoc    : for tim
#       in:                     $optKgLoc      : for KG format
#       in:                     $useridLoc     : user name         (for PP/non-pp)
#       in:                     $optIsDecLoc   : machin is DEC     (ancient)
#       in:                     $fileOutPhdLoc : human readable file
#       in:                     $fileOutRdbLoc : RDB formatted output
#       in:                     $dirWork       : working dir
#       in:                     $
#       in:                     $fileOutScreen : screen dumpb of system call  if = 0: 0 -> STDOUT
#       in:                     $fhSbrErr      : error file handle
#                NOTE:              = 0          to surpress writing
#       out:                    1|0,msg, implicit: files
#       err:                    ok -> (1,"ok sbr"), err -> (0,"msg")
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."phdRun1";
				# ------------------------------
				# arguments given ?
    return(&errSbr("not def fileHssp!"))             if (! defined $fileHssp);
    return(&errSbr("not def chainIn!"))              if (! defined $chainIn);
    return(&errSbr("not def exePhdLoc!"))            if (! defined $exePhdLoc);
    return(&errSbr("not def optPhdLoc!"))            if (! defined $optPhdLoc);
    return(&errSbr("not def optParaLoc!"))           if (! defined $optParaLoc);
    return(&errSbr("not def optRdbLoc!"))            if (! defined $optRdbLoc);
    return(&errSbr("not def optMachLoc!"))           if (! defined $optMachLoc);
    return(&errSbr("not def optKgLoc!"))             if (! defined $optKgLoc);
    return(&errSbr("not def useridLoc!"))            if (! defined $useridLoc);
    return(&errSbr("not def optIsDecLoc!"))          if (! defined $optIsDecLoc);
    return(&errSbr("not def optNiceInLoc!"))         if (! defined $optNiceInLoc);
    return(&errSbr("not def fileOutPhdLoc!"))        if (! defined $fileOutPhdLoc);
    return(&errSbr("not def fileOutRdbLoc!"))        if (! defined $fileOutRdbLoc);
    return(&errSbr("not def dirWorkLoc!"))           if (! defined $dirWorkLoc);
				# ------------------------------
				# input files existing ?
    return(&errSbr("miss in file '$fileHssp'!"))     if (! -e $fileHssp);
    return(&errSbr("miss in file '$exePhdLoc'!"))    if (! -e $exePhdLoc && ! -l $exePhdLoc);
    return(&errSbr("not executable '$exePhdLoc'!"))  if (! -x $exePhdLoc );

				# ------------------------------
				# syntax check
    return(&errSbr("ini: FORTRAN PHD optPhd has to be 'sec,acc,htm', is=$optPhdLoc,"))
	if ($optPhdLoc !~ /^(sec|acc|htm)$/);
    return(&errSbr("ini: PHD parameter file=$optParaLoc, missing"))
	if ( ! -e $optParaLoc);
				# ------------------------------
				# other input
    $fhSbrErr="STDOUT"          if (! defined $fhSbrErr);
    $fileOutScreenLoc=0         if (! defined $fileOutScreenLoc || ! $fileOutScreenLoc);

				# ------------------------------
				# build up input arguments
				# ------------------------------
				# working directory
    $optPath_work_loc=$dirWorkLoc;
    if ( length($dirWorkLoc)<3 || $dirWorkLoc eq "unk" ){
        if ( defined $PWD && length($PWD)>1 ) { 
	    $optPath_work_loc=$PWD;  }
        else {
	    $optPath_work_loc="no"; }}

    $optPhd_loc= $optPhdLoc;	# run option
    $optPhd_loc= "exp"          if ($optPhdLoc eq "acc"); # correct acc->exp

    $optUserPhd= 0;		# PP option
    $optUserPhd= "phd"          if ($useridLoc eq "phd");

    @arg=($optMachLoc,		# for tim
	  $optKgLoc,		# for KG format
	  $optPhd_loc,		# mirror            (acc -> exp)
	  $optUserPhd,		# user name         (for PP/non-pp)
	  $optParaLoc,		# Para-file
	  $optRdbLoc,		# write RDB, or not (ancient)
	  $optIsDecLoc,		# machin is DEC     (ancient)
	  $optPath_work_loc,	# working dir
	  $fileOutPhdLoc);	# human readable file

    push(@arg,$fileOutRdbLoc)	# write RDB file ?
	if ($optRdbLoc !~ /no/ && defined $fileOutRdbLoc && $fileOutRdbLoc ne "unk");

				# ------------------------------
				# massage input HSSP file
    $fileHssp_loc=$fileHssp;
				# add dir
    $fileHssp_loc=$optPath_work_loc."/".$fileHssp
	if ($fileHssp=~/\// && $fileHssp !~/^\// && -d $optPath_work_loc);
				# add chain
    $fileHssp_loc.="_\!_".$chainIn
	if ($chainIn ne "unk" && length($chainIn)>0 && $chainIn ne " ");

				# ------------------------------
				# which option for nice? (job priority)
    if    ($optNiceInLoc =~ /no/)   { 
	$optNice_loc="";}
    elsif ($optNiceInLoc =~ /nice/) { 
	$optNice_loc=$optNiceInLoc; 
	$optNice_loc=~s/\s//g;
	$optNice_loc=~s/.*nice.*(-\d+)$/nice $1/; }
    else                              { 
	$optNice_loc="";}

    $cmd=$cmdSys="";		# avoid warnings

				# --------------------------------------------------
				# now run it
				# --------------------------------------------------

    # *************************
    $arg=join(' ',@arg);	# final argument to run
    $cmd=$optNice_loc." ".	# final command
	$exePhdLoc." ".
	    $fileHssp_loc." ".$arg;
    eval  "\$cmdSys=\"$cmd\"";
    # *************************

    print $fhSbrErr "--- run PHD\n$cmd\n" if ($fhSbrErr);

#   ************************************************************

    ($Lok,$msg)=
	&sysRunProg($cmdSys,$fileOutScreenLoc,$fhSbrErr); # system call PHD

#   ************************************************************

				# ------------------------------
				# system ERROR
    return(&errSbrMsg("failed on PHDfor ($exePhdLoc):\n",$msg)) if (! $Lok);

				# ------------------------------
				# ok !
    return(1,"ok $sbrName") 
	if (($optRdbLoc !~/no/ && -e $fileOutRdbLoc && -e $fileOutPhdLoc) ||
	    ($optRdbLoc =~/no/ && -e $fileOutPhdLoc) );

				# ------------------------------
				# other ERRORS:
    $msg= "*** ERROR $sbrName: failed on system call to FORTRAN ($exePhdLoc):\n";
    $msg.="***                 no pred file ',".$fileOutPhdLoc."'\n"
	if (! -e $fileOutPhdLoc);
    $msg.="***                 no RDB  file ',".$fileOutRdbLoc."'\n"
	if ($optRdbLoc !~ /no/ && ! -e $fileOutRdbLoc);

    print $fhSbrErr "$msg"      if ($fhSbrErr);

    return(0,$msg);
}				# end of phdRun1

#==============================================================================
sub phdRunIniFileNames {
    local($optPhdLoc,$dirWorkLoc,$titleTmpLoc,$jobidLoc)=@_;
    $[ =1 ;
#-------------------------------------------------------------------------------
#   phdRunIniFileNames          assigns names to intermediate files for FORTRAN PHD
#       in:                     $optPhdLoc     : mode = 3|both|sec|acc|htm
#       in:                     $dirWork       : working dir
#       in:                     $titleTmpLoc   : temporary files 'dirWork.titleTmp.jobid.extX'
#       in:                     $jobidLoc      : temporary files 'dirWork.titleTmp.jobid.extX'
#       out:                    $fileTmp{$kwd} : with
#                               $fileTmp{kwd}= 'kwd1,kwd2,kwd3,...'
#                               $fileTmp{$kwd}  file, e.g.:
#                               $fileTmp{"sec|acc|htm|both|3","phd|rdb"}
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName3="phdRunIniFileNames";
    undef %fileTmp;
				# check arguments
    return(&errSbr("not def optPhdLoc!",$sbrName3))         if (! defined $optPhdLoc);
    return(&errSbr("not def dirWorkLoc!",$sbrName3))        if (! defined $dirWorkLoc);
    return(&errSbr("not def titleTmpLoc!",$sbrName3))       if (! defined $titleTmpLoc);
    return(&errSbr("not def jobidLoc!",$sbrName3))          if (! defined $jobidLoc);

    $titleTmpLoc2=$titleTmpLoc;
    $titieTmpLoc2=~s/$dirWorkLoc//g      if ($titleTmpLoc2=~/$dirWorkLoc/);
    
    $pre= $dirWorkLoc.$titleTmpLoc2;
    $pre.=$jobidLoc                      if ($pre !~ /$jobidLoc/);
				# ------------------------------
				# intermediate files
				# ------------------------------
    if ($optPhdLoc=~/sec|both|3/){
	$fileTmp{"sec","phd"}=   $pre.".phdSec";
	$fileTmp{"sec","rdb"}=   $pre.".rdbSec"; }
    if ($optPhdLoc=~/acc|both|3/){
	$fileTmp{"acc","phd"}=   $pre.".phdAcc";    
	$fileTmp{"acc","rdb"}=   $pre.".rdbAcc"; }
    if ($optPhdLoc=~/htm|3/){
	$fileTmp{"htm","phd"}=   $pre.".phdHtm";    
	$fileTmp{"htm","rdb"}=   $pre.".rdbHtm";    
	$fileTmp{"htmfin","rdb"}=$pre.".rdbHtmfin"; 
	$fileTmp{"htmfil","rdb"}=$pre.".rdbHtmfil"; 
	$fileTmp{"htmref","rdb"}=$pre.".rdbHtmref"; 
	$fileTmp{"htmtop","rdb"}=$pre.".rdbHtmtop"; }
    if  ($optPhdLoc=~/both|3/){ # note 3 also both for the case that no HTM detected!
	$fileTmp{"both","phd"}=  $pre.".phdBoth";   
	$fileTmp{"both","rdb"}=  $pre.".rdbBoth"; }
    if  ($optPhdLoc=~/3/){
	$fileTmp{"3","phd"}=     $pre.".phdAll3";   
	$fileTmp{"3","rdb"}=     $pre.".rdbAll3"; }
    @tmp=sort keys %fileTmp;
    $fileTmp{"kwd"}=join(',',@tmp);
    $fileTmp{"kwd"}=~s/,*$//g;
}				# phdRunIniFileNames

#==============================================================================
sub phdRunPost1 {
    local($fileHssp,$chainHssp,$fileInRdbLoc,$dirLib,$optNiceInLoc,
	  $exeHtmfilLoc,$exeHtmrefLoc,$exeHtmtopLoc,
          $LdoHtmfilLoc,$LdoHtmisitLoc,$optHtmMinValLoc,$LdoHtmrefLoc,$LdoHtmtopLoc,
          $fileOutNotLoc,$fileOutRdbLoc,$fileTmpFil,$fileTmpRef,$fileTmpTop,
	  $fileOutScreenLoc,$fhSbrErr) = @_;
    local($SBR);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   phdRunPost1                       
#       in:                     $fileHssp      : HSSP file to run it on
#       in:                     $chainHssp     : name of chain
#       in:                     $fileInRdbLoc  : RDB file from PHD fortran
#       in:                     $dirLib        : directory of PERL libs
#                                   = 0          to surpress
#       in:                     $optNiceLoc    : priority 'nonice|nice|nice-n'
#       in:                     $exeHtmfilLoc  : Perl executable for HTMfil
#       in:                     $exeHtmrefLoc  : Perl executable for HTMref
#       in:                     $exeHtmtopLoc  : Perl executable for HTMtop
#       in:                     $LdoHtmfil     : 1|0 do or do NOT run
#       in:                     $LdoHtmisit    : 1|0 do or do NOT run
#       in:                     $optHtmMinVal  : strength of minimal HTM (default 0.8|0.7)
#                                   = >0 && <1 , real
#       in:                     $LdoHtmref     : 1|0 do or do NOT run
#       in:                     $LdoHtmtop     : 1|0 do or do NOT run
#       in:                     $fileOutNotLoc : file flagging that no HTM was detected
#       in:                     $fileOutRdbLoc : final RDB file
#       in:                     $fileTmpFil    : temporary file from htmfil
#       in:                     $fileTmpIsit   : temporary file from htmfil
#       in:                     $fileTmpRef    : temporary file from htmfil
#       in:                     $fileTmpTop    : temporary file from htmfil
#       in:                     $LdebugLoc     : =1 -> keep temporary files, =0 -> delete them
#       in:                     $fileOutScreen : screen dumpb of system call  if = 0: 0 -> STDOUT
#       in:                     $fhSbrErr      : error file handle
#                NOTE:              = 0          to surpress writing
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR="lib-br:"."phdRunPost1"; 
    $fhinLoc="FHIN_"."$SBR"; $fhoutLoc="FHOUT_".$SBR;
				# ------------------------------
				# arguments given ?
    return(&errSbr("not def fileHssp!",$SBR))             if (! defined $fileHssp);
    return(&errSbr("not def chainHssp!",$SBR))            if (! defined $chainHssp);
    return(&errSbr("not def fileInRdbLoc!",$SBR))         if (! defined $fileInRdbLoc);
    return(&errSbr("not def dirLib!",$SBR))               if (! defined $dirLib);
    return(&errSbr("not def optNiceInLoc!",$SBR))         if (! defined $optNiceInLoc);

    return(&errSbr("not def exeHtmfilLoc!",$SBR))         if (! defined $exeHtmfilLoc);
    return(&errSbr("not def exeHtmrefLoc!",$SBR))         if (! defined $exeHtmrefLoc);
    return(&errSbr("not def exeHtmtopLoc!",$SBR))         if (! defined $exeHtmtopLoc);

    return(&errSbr("not def LdoHtmfilLoc!",$SBR))         if (! defined $LdoHtmfilLoc);
    return(&errSbr("not def LdoHtmisitLoc!",$SBR))        if (! defined $LdoHtmisitLoc);
    return(&errSbr("not def optHtmisitMinLoc!",$SBR))     if (! defined $optHtmisitMinLoc);
    return(&errSbr("not def LdoHtmrefLoc!",$SBR))         if (! defined $LdoHtmrefLoc);
    return(&errSbr("not def LdoHtmtopLoc!",$SBR))         if (! defined $LdoHtmtopLoc);

    return(&errSbr("not def fileOutNotLoc!",$SBR))        if (! defined $fileOutNotLoc);
    return(&errSbr("not def fileOutRdbLoc!",$SBR))        if (! defined $fileOutRdbLoc);
    return(&errSbr("not def fileTmpFil!",$SBR))           if (! defined $fileTmpFil);
    return(&errSbr("not def fileTmpRef!",$SBR))           if (! defined $fileTmpRef);
    return(&errSbr("not def fileTmpTop!",$SBR))           if (! defined $fileTmpTop);
				# ------------------------------
				# input files existing ?
#    return(&errSbr("miss in file '$fileHssp'!"))     if (! -e $fileHssp);
#    return(&errSbr("not HSSP file '$fileHssp'!"))    if (! &is_hssp($fileHssp));
#    return(&errSbr("empty HSSP file '$fileHssp'!"))  if (! &is_hssp_empty($fileHssp));
    return(&errSbr("no rdb '$fileInRdbLoc'!",$SBR))   if (! -e $fileInRdbLoc);

                                # ------------------------------
                                # executables ok?
    foreach $exe ($exeHtmfilLoc,$exeHtmrefLoc,$exeHtmtopLoc){
        return(&errSbr("miss in exe '$exe'!",$SBR))      if (! -e $exe && ! -l $exe);
        return(&errSbr("not executable '$exe'!",$SBR))   if (! -x $exePhdLoc ); }

				# ------------------------------
				# defaults

				# xx
				# xx PASS!!!!
				# xx 
    
    $minLenDefLoc= 18;		# length of best helix (18)
    $doStatDefLoc=1;		# compile further statistics on residues, avLength asf

				# ------------------------------
				# other input
    $fhSbrErr="STDOUT"          if (! defined $fhSbrErr);
    $fileOutScreenLoc=0         if (! defined $fileOutScreenLoc || ! $fileOutScreenLoc);

				# xx
				# xx PASS!!!!
				# xx 
    
    $minLenLoc=$minLenDefLoc    if (! defined $minLenLoc || $minLenLoc == 0);
    $doStatLoc=$doStatDefLoc    if (! defined $doStatLoc);


				# ------------------------------
				# which option for nice? (job priority)
    if    ($optNiceInLoc =~ /no/)   { 
	$optNiceTmp="";}
    elsif ($optNiceInLoc =~ /nice/) { 
	$optNiceTmp=$optNiceInLoc; 
	$optNiceTmp=~s/\s//g;
	$optNiceTmp=~s/.*nice.*(-\d+)$/nice $1/; }
    else                              { 
	$optNiceTmp="";}

				# --------------------------------------------------
                                # is HTM ?
    if ($LdoHtmisitLoc) {       # --------------------------------------------------


	($Lok,$msg,$LisHtm,%tmp)=
	    &phdHtmIsit($fileInRdbLoc,$optHtmMinValLoc,$minLenLoc,$doStatLoc);
	return(&errSbrMsg("failed on phdHtmIsit (file=$fileInRdbLoc,".
			  "minVal=$optHtmMinValLoc,, minLen=$minLenLoc, ".
			  "stat=$doStatLoc",$msg,$SBR)) if (! $Lok);
                                # copy to final RDB
        ($Lok,$msg)=
            &sysCpfile($fileInRdbLoc,$fileOutRdbLoc);
	return(&errSbrMsg("htmisit copy",$msg,$SBR),0)  if (! $Lok);

	if (! $LisHtm){
	    open($fhoutLoc,">".$fileOutNotLoc) ||
		return(&errSbr("failed creating flag file '$fileOutNotLoc'",$SBR));
	    print $fhoutLoc
		"value of best=",$tmp{"valBest"},
		", min=$optHtmMinValLoc, posBest=",$tmp{"posBest"},",\n";
	    close($fhoutLoc); 
                                # **********************
				# NOT MEMBRANE -> return
	    return(1,"none after htmisit ($SBR)",0); }}

				# --------------------------------------------------
    if ($LdoHtmfilLoc) {        # old hand waving filter ?
				# --------------------------------------------------
                                # build up argument
        @tmp=($fileInRdbLoc,$fileTmpFil,$fileOutNotLoc);
        push(@tmp,"dirLib=".$dirLib)                       if ($dirLib && -d $dirLib);
        push(@tmp,"not_screen")                            if (! $fhSbrErr && 
							       $fhSbrErr ne "STDOUT");
        $arg=join(' ',@tmp); 
                                # run system call
        if ($exeHtmfilLoc =~ /\.pl/) {
            $cmd="$optNiceTmp $exeHtmfilLoc $arg";
            eval "\$command=\"$cmd\"";
	    ($Lok,$msg)=
                &sysRunProg($command,$fileOutScreenLoc,$fhSbrErr);
	    return(&errSbrMsg("htmfil=$exeHtmfilLoc, msg=",$msg,$SBR)) if (! $Lok); }
        else {                  # include package
            &phd_htmfil'phd_htmfil(@tmp);                        # e.e'
            $tmp=$exeHtmfilLoc;$tmp=~s/\.pm/\.pl/; $cmd="$tmp $arg";
            print $fhSbrErr "$cmd\n"                       if ($fhSbrErr); }
        print $fhSbrErr "--- ","-" x 50,"\n"               if ($fhSbrErr);
                                # copy to final RDB
        ($Lok,$msg)=
            &sysCpfile($fileTmpFil,$fileOutRdbLoc)         if (-e $fileTmpFil);}
                
				# --------------------------------------------------
    if ($LdoHtmrefLoc) {        # do refinement ?
				# --------------------------------------------------
                                # build up argument
#        @tmp=($fileInRdbLoc,"nof file_out=$fileTmpRef");
        @tmp=($fileInRdbLoc,"file_out=$fileTmpRef");
        push(@tmp,"dirLib=".$dirLib)                       if ($dirLib && -d $dirLib);
        push(@tmp,"not_screen")                            if (! $fhSbrErr && 
							       $fhSbrErr ne "STDOUT");
        $arg=join(' ',@tmp);
                                # run system call
        if ($exeHtmrefLoc=~/\.pl/){
            $cmd="$optNiceTmp $exeHtmrefLoc $fileInRdbLoc $arg";
            eval "\$command=\"$cmd\"";
	    ($Lok,$msg)=
                &sysRunProg($command,$fileOutScreenLoc,$fhSbrErr);
	    return(&errSbrMsg("htmref=$exeHtmrefLoc, msg=",$msg,$SBR),0) if (! $Lok); }
        else {                  # include package
            &phd_htmref'phd_htmref(@tmp);                        # e.e'
            $tmp=$exeHtmrefLoc;$tmp=~s/\.pm/\.pl/; $cmd="$tmp $arg";
            print $fhSbrErr "$cmd\n"                       if ($fhSbrErr); }
        print $fhSbrErr "--- ","-" x 50,"\n"               if ($fhSbrErr);
        return(&errSbr("after htmref=$exeHtmrefLoc, no out=$fileTmpRef",$SBR),0) 
            if (! -e $fileTmpRef);
        ($Lok,$msg)=            # copy to final RDB
            &sysCpfile($fileTmpRef,$fileOutRdbLoc);
	return(&errSbrMsg("htmref copy",$msg,$SBR),0)      if (! $Lok); }

				# --------------------------------------------------
    if ($LdoHtmtopLoc) {        # do the topology prediction ?
				# --------------------------------------------------
                                # build up argument
	if    (-e $fileTmpRef){ $file_tmp=$fileTmpRef;   $arg=" ref"; }
	elsif (-e $fileTmpFil){ $file_tmp=$fileTmpFil;   $arg=" fil"; }
        else                  { $file_tmp=$fileInRdbLoc; $arg=" nof"; }
	$tmp= "file_out=$fileTmpTop file_hssp=$fileHssp";
	$tmp.="_".$chainHssp                               if (defined $chainHssp && 
                                                               $chainHssp=~/^[0-9A-Z]$/);
	@tmp=($file_tmp,$tmp);
        push(@tmp,"dirLib=".$dirLib)                       if ($dirLib && -d $dirLib);
        push(@tmp,"not_screen")                            if (! $fhSbrErr && 
							       $fhSbrErr ne "STDOUT");
        $arg=join(' ',@tmp);
                                # run system call
        if ($exeHtmtopLoc=~/\.pl/){
            $cmd="$optNiceTmp $exeHtmtopLoc $arg";
            eval "\$command=\"$cmd\"";
	    ($Lok,$msg)=
                &sysRunProg($command,$fileOutScreenLoc,$fhSbrErr);
	    return(&errSbrMsg("htmtop=$exeHtmtopLoc, msg=",$msg,$SBR),0) if (! $Lok); }
        else {                  # include package
            &phd_htmtop'phd_htmtop(@tmp);                        # e.e'
            $tmp=$exeHtmtopLoc;$tmp=~s/\.pm/\.pl/; $cmd="$tmp $arg";
            print $fhSbrErr "$cmd\n"                       if ($fhSbrErr); }
        print $fhSbrErr "--- ","-" x 50,"\n"               if ($fhSbrErr);
	return(&errSbr("after htmtop=$exeHtmtopLoc, no out=$fileTmpTop",$SBR),0) 
            if (! -e $fileTmpTop);

        ($Lok,$msg)=            # copy to final RDB
            &sysCpfile($fileTmpTop,$fileOutRdbLoc);
	return(&errSbrMsg("htmtop copy",$msg,$SBR),0)      if (! $Lok); }
    
    return(1,"ok $SBR",1);
}				# end of phdRunPost1

#===============================================================================
sub phdRunWrt {
    local($optPhd3Loc,$optRdbLoc,$fileAbbrRdb,$fileTmpSec,$fileTmpAcc,$fileTmpHtm,
          $fileOutPhdLoc,$fileOutRdbLoc) = @_ ;
    local($SBR);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   phdRunWrt                   merges 2-3 RDB files (sec,acc,htm?)
#
                                # ++++++++++++++++++++++++++++++
                                # NOTE: not writing file.phd, yet yy
                                # ++++++++++++++++++++++++++++++
#
#       in:                     $optPhd3       : mode = 3|both|sec|acc|htm  (else -> ERROR)
#       in:                     $optRdbLoc     : write RDB, or not (ancient)
#       in:                     $fileAbbrRdb   : file explaining the abbreviations in RDB file
#       in:                     $fileTmpSec    : PHD rdb with sec output
#       in:                     $fileTmpAcc    : PHD rdb with acc output
#       in:                     $fileTmpHtm    : PHD RDB with HTM output
#                                  = 0           if mode 'both' !!
#       in:                     $fileOutPhdLoc : name of ouptput file for human readable stuff
#       in:                     $fileOutRdbLoc : name of RDB output
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR="lib-br:"."phdRunWrt"; $fhinLoc="FHIN_".$SBR;$fhoutLoc="FHOUT_".$SBR;
    $errMsg="*** ERROR $SBR: \n".
	"in: opt=$optPhd3Loc,rdb=$optRdbLoc,fileAbbr=$fileAbbrRdb,\n".
	    "in: sec=$fileTmpSec,acc=$fileTmpAcc,htm=$fileTmpHtm,\n".
		"in: outPhd=$fileOutPhdLoc,outRdb=$fileOutRdbLoc,\n";
				# ------------------------------
				# arguments given ?
    return(&errSbr("not def optPhd3Loc!\n".$errMsg,$SBR))    if (! defined $optPhd3Loc);
    return(&errSbr("not def optRdbLoc!\n".$errMsg,$SBR))     if (! defined $optRdbLoc);
    return(&errSbr("not def fileAbbrRdb!\n".$errMsg,$SBR))   if (! defined $fileAbbrRdb);
    return(&errSbr("not def fileTmpSec!\n".$errMsg,$SBR))    if (! defined $fileTmpSec);
    return(&errSbr("not def fileTmpAcc!\n".$errMsg,$SBR))    if (! defined $fileTmpAcc);
    return(&errSbr("not def fileTmpHtm!\n".$errMsg,$SBR))    if (! defined $fileTmpHtm);
    return(&errSbr("not def fileOutPhdLoc!\n".$errMsg,$SBR)) if (! defined $fileOutPhdLoc);
    return(&errSbr("not def fileOutRdbLoc!\n".$errMsg,$SBR)) if (! defined $fileOutRdbLoc);
				# ------------------------------
				# syntax check
    return(&errSbr("ini: FORTRAN PHD optPhd ($optPhd3) has to be '3|both'\n".$errMsg))
	if ($optPhd3Loc !~ /^(3|both)$/);
				# ------------------------------
				# input files existing ?
    return(&errSbr("not def fileTmpSec!\n".$errMsg,$SBR))    if (! defined $fileTmpSec);
    return(&errSbr("not def fileTmpAcc!\n".$errMsg,$SBR))    if (! defined $fileTmpAcc);
    return(&errSbr("not def fileTmpHtm!\n".$errMsg,$SBR))    if (! defined $fileTmpHtm);

				# --------------------------------------------------
                                # RDB -> .phd files
				# --------------------------------------------------

                                # ++++++++++++++++++++++++++++++
                                # NOTE: not writing file.phd, yet yy
                                # ++++++++++++++++++++++++++++++

    if (0){                     # NOTE ONE DAY TO ADD!!!
        open($fhoutLoc,">".$fileOutPhdLoc) || 
            return(&errSbr("could not open new=$fileOutPhdLoc\n".$errMsg,$SBR));
    }

				# --------------------------------------------------
				# now merge RDB files
				# --------------------------------------------------
                                # merge 3 (sec, acc, htm)
    if    ($optPhd3Loc eq "3" && $fileTmpHtm) {
        @fileTmp=($fileTmpSec,$fileTmpAcc,$fileTmpHtm); }
                                # merge 2 (sec,acc)
    else {
        @fileTmp=($fileTmpSec,$fileTmpAcc); }
                                # ------------------------------
                                # do merge
    ($Lok,$msg)=
        &phdRdbMerge($fileOutRdbLoc,$fileAbbrRdb,@fileTmp);

    return(&errSbrMsg("after phdRdbMerg on:".join(',',@fileTmp)." to $fileOutRdbLoc\n".
                      $errMsg,$msg,$SBR)) if (! $Lok);

    return(1,"ok $SBR");
}				# end of phdRunWrt

#===============================================================================
sub ppHsspRdExtrHeader {
    local ($file_in) = @_ ;
    local ($fhinLoc,$sbrName,$msg,$ct,$tmp,$tmp2,@tmp,$it);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   ppHsspRdExtrHeader          extracts the summary from HSSP header (for PP)
#       out (GLOBAL):           $rd_hssp{} (for ppTopitsHdWrt!!!)
#--------------------------------------------------------------------------------
    $sbrName="ppHsspRdExtrHeader";$fhinLoc="FHIN"."$sbrName";

    open($fhinLoc,$file_in) ||
	return(0,"*** ERROR $sbrName: '$file_in' not opened\n","error");

    while(<$fhinLoc>){
	last if ($_=/^\#\# PROTEINS/);}
    $ct=0;
    while(<$fhinLoc>){
	last if ($_=/^\#\# ALI/);
	next if ($_=~/^  NR/);
	next if (length($_)<27); # xx hack should not happen!!
	$tmp=substr($_,27);
	$tmp=~s/^\s*|\s$//g;	# purge leading blanks
	$#tmp=0;@tmp=split(/\s+/,$tmp);
	++$ct;
	$rd_hssp{"ide","$ct"}=$tmp[1];
	$rd_hssp{"ifir","$ct"}=$tmp[3];$rd_hssp{"jfir","$ct"}=$tmp[5];
	$rd_hssp{"ilas","$ct"}=$tmp[4];$rd_hssp{"jlas","$ct"}=$tmp[6];
	$rd_hssp{"lali","$ct"}=$tmp[7];
	$rd_hssp{"ngap","$ct"}=$tmp[8];$rd_hssp{"lgap","$ct"}=$tmp[9];
	$rd_hssp{"len2","$ct"}=$tmp[10];

	$tmp= substr($_,7,20);
	$tmp2=substr($_,20,6);
	$tmp3=$tmp2; $tmp3=~s/\s//g;
	if (length($tmp3)<3) {	# STRID empty
	    $tmp=substr($_,8,6);
	    $tmp=~s/\s//g;
	    $rd_hssp{"id2","$ct"}=$tmp;}
	else{$tmp2=~s/\s//g;
	     $rd_hssp{"id2","$ct"}=$tmp2;}}close($fhinLoc);
    $rd_hssp{"nali"}=$ct;
    return(1,"ok $sbrName",%rd_hssp);
}				# end of ppHsspRdExtrHeader

#===============================================================================
sub ppStripRd {
    local ($file_in) = @_ ;
    local ($fhinLoc,$sbrName,$msg,@strip);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    ppStripRd                   reads the new strip file generated for PP
#--------------------------------------------------------------------------------
    $sbrName="ppStripRd";$fhinLoc="FHIN"."$sbrName";

    open($fhinLoc,$file_in) ||
	return(0,"*** ERROR $sbrName: '$file_in' not opened\n","error");

    $#strip=0;
    while(<$fhinLoc>){
	push(@strip,$_);}close($fhinLoc);
    return(1,"ok $sbrName",@strip);
}				# end of ppStripRd

#===============================================================================
sub ppTopitsHdWrt {
    local ($file_in,$mixLoc,@strip) = @_ ;
    local ($sbrName,$msg,$fhout,$Lwatch,$Lrest,$strip,$it);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    ppTopitsHdWrt              writes the final PP TOPITS output file
#       in:                     $file_in,$mixLoc,@strip
#       in:                     output file, ratio str/seq (100=only struc), 
#       in:                        content of strip file
#       out:                    file written ($file_in)
#       err:                    (0,$err) (1,'ok')
#--------------------------------------------------------------------------------
    $sbrName="ppStripRd";$fhout="FHOUT"."$sbrName";

    open($fhout,">".$file_in) ||
	return(0,"*** ERROR $sbrName: '$file_in' not opened (output file)\n");

    $Lwatch=$Lrest=0;
    foreach $strip (@strip) {
	$strip=~s/\n//g;
	if ( $Lrest ) {
	    print $fhout "$strip\n"; }
	elsif ( $Lwatch && ($strip=~/^---/) ){
	    print $fhout "--- \n";
	    print $fhout "--- TOPITS ALIGNMENTS HEADER: PDB_POSITIONS FOR ALIGNED PAIR\n";
	    printf 
		$fhout "%5s %4s %4s %4s %4s %4s %4s %4s %-6s\n",
		"RANK","PIDE","IFIR","ILAS","JFIR","JLAS","LALI","LEN2","ID2";
	    foreach $it (1 .. $rd_hssp{"nali"}){
		printf 
		    $fhout "%5d %4d %4d %4d %4d %4d %4d %4d %-6s\n",
		    $it,int(100*$rd_hssp{"ide","$it"}),
		    $rd_hssp{"ifir","$it"},$rd_hssp{"ilas","$it"},
		    $rd_hssp{"jfir","$it"},$rd_hssp{"jlas","$it"},
		    $rd_hssp{"lali","$it"},$rd_hssp{"len2","$it"},
		    $rd_hssp{"id2","$it"};
	    }
	    $Lrest=1; 
	    print $fhout "$strip\n"; }
	elsif ($strip =~ /^--- .* SUMMARY/){ 
	    $Lwatch=1; 
	    print $fhout "$strip\n"; }
	elsif ($strip =~ /^--- NAME2/) { # abbreviations
	    print $fhout "$strip\n";
	    print $fhout "--- IFIR         : position of first residue of search sequence\n";
	    print $fhout "--- ILAS         : position of last residue of search sequence\n";
	    print $fhout "--- JFIR         : PDB position of first residue of remote homologue\n";
	    print $fhout "--- JLAS         : PDB position of last residue of remote homologue\n";}
	elsif ($strip =~ /^--- .* PARAMETER/) { # parameter
	    print $fhout "$strip\n";
				# hack br 98-05 do clean some day!
	    if (! defined $mixLoc){ print "-*- WARN $sbrName mixLoc not defined \n";
				    $mixLoc=50;}
	    $mixLoc=~s/\D//g; $mixLoc=50 if (length($mixLoc)<1); # hack br 98-05 
	    printf $fhout 
		"--- str:seq= %3d : structure (sec str, acc)=%3d%1s, sequence=%3d%1s\n",
		int($mixLoc),int($mixLoc),"%",int(100-$mixLoc),"%";
	} else {print $fhout "$strip\n"; }
    }
    close($fhout);
    return(1,"ok $sbrName");
}				# end of ppTopitsHdWrt

#===============================================================================
sub ranGetString {
    local($seedLoc) = @_ ;
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   ranGetString                produces a random string 
#       in:                     $seedLoc=       seed (may be anything if the
#                                               command srand() has been executed!)
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."ranGetString";

    $ranMaxNum=    10000;	# highest number to pick from
    $ranNumLet=    2;		# number of letters (before and after number

				# letters to use
    $ranLetters=   "abcdefghijklmnopqrstuvwxyz";
    @ranLetters=   split(//,$ranLetters);

    $ranMaxNumLet= length($ranLetters);

				# seed random
    srand(time|$$)
	if (!defined $seedLoc);

    $res="";
				# get some character string
    $tmp="";
    foreach $itl (1..$ranNumLet) {
	$poslet=int(rand($ranMaxNumLet))+1; # randomly select sample 
	next if (! defined $ranLetters[$poslet]);
	$let=$ranLetters[$poslet];
	$tmp.=$let;}
    $res.=$tmp;
				# get some number
    $num=int(rand($ranMaxNum))+1; # randomly select sample 
    $res.="$num";

				# get some character string again
    $tmp="";
    foreach $itl (1..$ranNumLet) {
	$poslet=int(rand($ranMaxNumLet))+1; # randomly select sample 
	next if (! defined $ranLetters[$poslet]);
	$let=$ranLetters[$poslet];
	$tmp.=$let;}
    $res.=$tmp;

    return(1,$res);
}				# end of ranGetString

#===============================================================================
sub ranPickFast {
    local($numPicksLoc,$numSamLoc,$maxNumPerSamLoc,$minNumPerSamLoc)=@_;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   ranPickFast                 selects succesion of numbers 1..$numSamLoc at 
#                               random (faster than ranPickGood)
#       in:                     $numPicks        = number of total picks
#       in:                     $numSamLoc       = number of samples to pick from (pool)
#       in:                     $maxNumPerSamLoc = maximal number of picks per pattern
#       in:                     $minNumPerSamLoc = minimal number of picks per pattern
#       out:                    1|0,msg,@ransuccession
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."ranPickFast";$fhinLoc="FHIN_"."ranPickFast";
				# ------------------------------
				# random numbers
#xx    srand(time|$$);             # seed random
    srand(100010);             # seed random

				# ------------------------------
				# initialise sample counts
    undef @ct;
    foreach $it (1..$numSamLoc){
	$ct[$it]=0;}
    
    $ct=0;$fin="";		# --------------------------------------------------
    while ($ct < $numPicksLoc){	# loop over counts
#        $it=int(rand($numSamLoc-1))+1;                # randomly select sample 
        $it=int(rand($numSamLoc))+1;                  # randomly select sample 
	$it=$numSamLoc          if ($it> $numSamLoc); # upper bound (security)
	$it=1                   if ($it<=1);          # upper/lower bounds (security)
				# ------------------------------
	$Lfound=0;		# (1) not often -> take it
        if    ($ct[$it] < $maxNumPerSamLoc){ 
	    ++$ct;++$ct[$it];$fin.="$it,";$Lfound=1;}
				# ------------------------------
				# (2) too often -> count up
	while ($it < $numSamLoc && ! $Lfound) {
	    ++$it;
	    if ($ct[$it] < $maxNumPerSamLoc){ 
		++$ct;++$ct[$it];$fin.="$it,";$Lfound=1;}}
				# ------------------------------
	$it=0;			# (3) too often -> restart count up
	while ($it < $numSamLoc && ! $Lfound) {
	    ++$it;
	    if ($ct[$it] < $maxNumPerSamLoc){ 
		++$ct;++$ct[$it];$fin.="$it,";$Lfound=1;}}
	if (! $Lfound && $ct < $numPicksLoc){
            $#tmp=0;foreach $it (1..$numSamLoc){
		$tmp=sprintf ("itSam=%4d occ=%4d\n",$it,$ct[$it]);push(@tmp,$tmp);}
            return(&errSbr("none found, but ct too small=$ct (numSam=$numSamLoc)\n".
#                           $fin."\n"."statistics\n".join("\n",@tmp).
			   "\n"),0);
	}}
				# ------------------------------
    if (! $minNumPerSamLoc){	# no minimum -> go home
	$fin=~s/^,*|,*$//g;$fin=~s/,,*/,/g;
				# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
	return(1,"ok $sbrName",$fin); }
				# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
	
				# --------------------------------------------------
				# correct those that did not reach minimal number
				#    NOTE: come here only if minNumPerSamLoc

				# ------------------------------
				# find those with low counts
    $max=0;$minSam="";
    foreach $it (1..$numSamLoc){
	if    ($ct[$it] < $minNumPerSamLoc) {
	    $minSam.="$it," x ($minNumPerSamLoc-$ct[$it]); }
	elsif ($ct[$it] > $max) {
	    $max=$ct[$it];} }
    $minSam=~s/,$//g; 
    @min=split(/,/,$minSam); undef @Lmin;
    $ctMinLoc=$#min;
    foreach $min (@min) {
	$Lmin[$min]=1;}

				# ------------------------------
    if ($ctMinLoc == 0){	# all above minimum -> go home
	$fin=~s/^,*|,*$//g;$fin=~s/,,*/,/g;
				# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
	return(1,"ok $sbrName",$fin); }
				# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
	
				# --------------------------------------------------
				# do indeed correct, if $#min > 1
				# 'end'less loop over all samples
				#    NOTE: come here only if some below minimum!
				# --------------------------------------------------
    $#max=0;
    while ($#max < $ctMinLoc){
	++$it;
				# skip those with minimal counts
	next if (defined $Lmin[$it]);
				# --------------------
				# start again (reduce max)
	if ($it > $numSamLoc){
	    $it=1; --$max;
				# ------------------------------
				# ERROR: maxVal < minWanted!
	    if ($max <= $minNumPerSamLoc){
		$#tmp=0;
		foreach $it (1..$numSamLoc){
		    $tmp=sprintf ("itSam=%4d occ=%4d\n",$it,$ct[$it]);
		    push(@tmp,$tmp);}
		return(&errSbr("max=$max, too small already...\n".
			       "so far maxSam=".join(',',@max[1..10]).
			       " min=".join(',',@min[1..10])."\nstat:\n".
			       join("\n",@tmp[1..10])."\n"."WATCH first 10!\n"),0); }}
				# ------------------------------
				# candidate for max
	if ($ct[$it] == $max){ 
	    push(@max,$it);
	    --$ct[$it];}}
				# --------------------------------------------------
				# now correct
				# --------------------------------------------------
    $fin=",".$fin.",";
    foreach $itTmp (1..$#min){ 
	++$ct[$min[$itTmp]];
	$fin=~s/\,$max[$itTmp]\,/\,$min[$itTmp]\,/; 
    }

    $sum=$#tmp=0;
    foreach $it (1..$numSamLoc){
	$sum+=$ct[$it];
	$tmp=sprintf ("itSam=%4d occ=%4d\n",$it,$ct[$it]);
	push(@tmp,$tmp);}
				# you may print @tmp here
    return(&errSbr("sum after correction=$sum, but numpick=$numPicksLoc"))
	if ($sum != $numPicksLoc);

    $fin=~s/^,*|,*$//g;$fin=~s/,,*/,/g;
    return(1,"ok $sbrName",$fin);
}				# end of ranPickFast

#===============================================================================
sub ranPickGood {
    local($numPicksLoc,$numSamLoc,$maxNumPerSamLoc,$minNumPerSamLoc)=@_;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   ranPickGood                 selects succesion of numbers 1..$numSamLoc at 
#                               random  (slower but more Gaussian than ranPickFast)
#       in:                     $numPicks        = number of total picks
#       in:                     $numSamLoc       = number of samples to pick from (pool)
#       in:                     $maxNumPerSamLoc = maximal number of picks per pattern
#       in:                     $minNumPerSamLoc = minimal number of picks per pattern
#       out:                    1|0,msg,@ransuccession
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."ranPickGood";$fhinLoc="FHIN_"."ranPickGood";
				# ------------------------------
				# random numbers
    srand(time|$$);             # seed random
				# ------------------------------
    foreach $it (1..$numSamLoc){ # initialise sample counts
	$ct[$it]=0;}
    
    $ct=0;$fin="";		# --------------------------------------------------
    while ($ct < $numPicksLoc){	# loop over counts
        $it=int(rand($numSamLoc))+1;                  # randomly select sample 
	$it=$numSamLoc          if ($it> $numSamLoc); # upper bound (security)
	$it=1                   if ($it<=1);          # upper/lower bounds (security)
				# ------------------------------
	$Lfound=0;		# (1) not often -> take it
        if    ($ct[$it] < $maxNumPerSamLoc){ 
	    ++$ct;++$ct[$it];$fin.="$it,";$Lfound=1;}
    }
                                # --------------------------------------------------
    if ($minNumPerSamLoc){	# correct those that didnt reach minimal number
        $max=0;$minSam="";
        foreach $it (1..$numSamLoc){$minSam.="$it,"     if ($ct[$it] < $minNumPerSamLoc);
				    $max=$ct[$it]       if ($ct[$it] > $max);}
	if (length($minSam)>1){	# to correct
	    $maxSam="";$it=0;
	    while (length($maxSam) < length($minSam)){
		++$it;
		if ($it > $numSamLoc){
		    $it=1; --$max;
		    if ($max<$minNumPerSamLoc){
			$#tmp=0;foreach $it (1..$numSamLoc){
			    $tmp=sprintf ("itSam=%4d occ=%4d\n",$it,$ct[$it]);push(@tmp,$tmp);}
			return(&errSbr("max=$max, too small already...\n".
				       "so far maxSam=$maxSam, minSam=$minSam\n"."stat:\n".
#				       join("\n",@tmp).
				       "\n"),0);
		    }}
		if ($ct[$it] == $max){ $maxSam.="$it,";
				       --$ct[$it];}}
				# now correct
	    $maxSam=~s/,$//g;$minSam=~s/,$//g;
	    @min=split(/,/,$minSam);@max=split(/,/,$maxSam);
	    $fin=",".$fin.",";
	    foreach $itTmp (1..$#min){ ++$ct[$min[$itTmp]];
				       $fin=~s/\,$max[$itTmp]\,/\,$min[$itTmp]\,/;}}}
    $fin=~s/^,*|,*$//g;$fin=~s/,,*/,/g;
    return(1,"ok $sbrName",$fin);
}				# end of ranPickGood

#===============================================================================
sub rdbphd_to_dotpred {
    local($Lscreen,$nres_per_row,$thresh_acc,$thresh_htm,$thresh_sec,
	  $opt_phd,$file_out,$protname,$Ldo_htmref,$Ldo_htmtop,@file) = @_ ;
    local($fhin,@des,@des_rd,@des_sec,@des_rd_sec,@des_acc,@des_rd_acc,@des_htm,@des_rd_htm,
	  %rdb_rd,%rdb,$file,$it,$ct,$mode_wrt,$fhout);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   rdbphd_to_dotpred           converts RDB files of PHDsec,acc,htm (both/3)
#                               to .pred files as used for PP server
#--------------------------------------------------------------------------------
    $fhin= "FHIN_RDBPHD_TO_DOTPRED";
    $fhout="FHOUT_RDBPHD_TO_DOTPRED";
				# note: @des same succession as @des_rd !!
    @des_rd_0 =     ("No", "AA");
    @des_0=         ("pos","aa");
    @des_rd_acc=    ("Obie","Pbie","OREL","PREL","RI_A");
    @des_acc=       ("obie","pbie","oacc","pacc","riacc");
				# horrible hack 20-01-98
    $fhinLoc="FHIN_rdbphd_to_dotpred";
    &open_file("$fhinLoc",$file[1]);
				# get RI for first file
    while(<$fhinLoc>){
	next if ($_=~/^\#/);
	if    ($_=~/RI\_S/){$riTmp="RI_S";}
	elsif ($_=~/RI\_H/){$riTmp="RI_H";}
	elsif ($_=~/RI\_A/){$riTmp="RI_A";}
	else  {print "*** '$_'\n";print "*** ERROR in RDB header $file[1]\n";}
	last;}close($fhinLoc);
	
    if    ($Ldo_htmref && $Ldo_htmtop) {
	@des_rd_htm=("OHL", "PHL", "RI_H", "pH",    "pL"    ,"PFHL", "PRHL", "PiTo" );
	@des_htm=   ("ohtm","phtm","rihtm",  "prHhtm","prLhtm","pfhtm","prhtm","pthtm");}
    elsif ($Ldo_htmref) {
	@des_rd_htm=("OHL", "PHL", "RI_H", "pH",    "pL"    ,"PFHL", "PRHL");
	@des_htm=   ("ohtm","phtm","rihtm",  "prHhtm","prLhtm","pfhtm","prhtm");}
    elsif ($Ldo_htmtop) {
	@des_rd_htm=("OHL", "PHL", "RI_H", "pH",    "pL"    ,"PFHL" ,"PiTo" );
	@des_htm=   ("ohtm","phtm","rihtm",  "prHhtm","prLhtm","pfhtm","pthtm");}
    else {
	@des_rd_htm=("OHL", "PHL", "$riTmp", "pH",    "pL"    ,"PFHL" );
	@des_htm=   ("ohtm","phtm","rihtm",  "prHhtm","prLhtm","pfhtm");}
    @des_rd_sec=    ("OHEL","PHEL","$riTmp", "pH",    "pE",    "pL");
    @des_sec=       ("osec","psec","risec",  "prHsec","prEsec","prLsec");
				# headers
    @deshd_rd_0=  ();
    if    ($Ldo_htmref && $Ldo_htmtop) {
	@deshd_rd_htm=("NHTM_BEST","NHTM_2ND_BEST",
#		       "REL_BEST","REL_BEST_DIFF",
		       "REL_BEST_DPROJ","MODEL","MODEL_DAT",
		       "HTMTOP_PRD","HTMTOP_RID","HTMTOP_RIP");}
    elsif ($Ldo_htmref) {
	@deshd_rd_htm=("NHTM_BEST","NHTM_2ND_BEST",
		       "REL_BEST_DPROJ","MODEL","MODEL_DAT");}
    elsif ($Ldo_htmtop) {
	@deshd_rd_htm=("HTMTOP_PRD","HTMTOP_RID","HTMTOP_RIP");}
    else {
	$#deshd_rd_htm=0;}
				# ------------------------------
				# read RDB files
				# ------------------------------
    $ct=0;
    foreach $file (@file){
	next if (! -e $file);
	++$ct;
	undef %rdb_rd;
	if ($ct==1) {
	    @des_rd=@des_rd_0;@des=@des_0;@deshd_rd=@deshd_rd_0;}
	else {
	    $#des_rd=$#des=$#deshd_rd=0;}
				# find out whether from PHDsec, PHDacc, or PHDhtm
	if   (&is_rdb_sec($file)){
	    $phd="sec";push(@des_rd,@des_rd_sec);push(@des,@des_sec);}
	elsif(&is_rdb_acc($file)){
	    $phd="acc";push(@des_rd,@des_rd_acc);push(@des,@des_acc);}
	elsif(&is_rdb_htmtop($file) || &is_rdb_htmref($file) || &is_rdb_htm($file)){
	    $phd="htm";push(@des,@des_htm);
	    push(@des_rd,@des_rd_htm);push(@deshd_rd,@deshd_rd_htm);}
	else {
	    print "*** ERROR rdbphd_to_dotpred: no RDB format recognised (file=$file)\n";
	    die; }
#	print "--- rdbphd_to_dotpred reading '$file' (phd=$phd)\n";
	%rdb_rd=
	    &rd_rdb_associative($file,"not_screen","header",@deshd_rd,"body",@des_rd); 
				# rename data (separate for PHDsec,acc,htm)
	foreach $it (1 .. $#des_rd) {
	    $ct=1;
	    while (defined $rdb_rd{"$des_rd[$it]","$ct"}) {
		$rdb{"$des[$it]","$ct"}=$rdb_rd{"$des_rd[$it]","$ct"}; 
		++$ct; }}
	foreach $deshdr (@deshd_rd){ # rename header
	    $rdb{"$deshdr"}="UNK";
	    $rdb{"$deshdr"}=$rdb_rd{"$deshdr"} if (defined $rdb_rd{"$deshdr"});}
    }
				# ------------------------------
				# now transform to strings
				# ------------------------------
    &rdbphd_to_dotpred_getstring(@des_0,@des_sec,@des_acc,@des_htm);
				# now subsets
    &rdbphd_to_dotpred_getsubset;
				# convert symbols
    $STRING{"osec"}=~s/L/ /g    if (defined $STRING{"osec"});
    $STRING{"psec"}=~s/L/ /g    if (defined $STRING{"psec"});
    $STRING{"obie"}=~s/i/ /g    if (defined $STRING{"obie"});
    $STRING{"pbie"}=~s/i/ /g    if (defined $STRING{"pbie"});
    if (defined $STRING{"ohtm"}) { 
	$STRING{"ohtm"}=~s/L/ /g;  
	if ($opt_phd !~ /htm/){
	    $STRING{"ohtm"}=~s/H/T/g;$STRING{"ohtm"}=~s/E/ /g; }}
    if (defined $STRING{"phtm"}) { 
	$STRING{"phtm"}=~s/L/ /g;  
	if ($opt_phd !~ /htm/){
	    $STRING{"phtm"}=~s/H/T/g;$STRING{"phtm"}=~s/E/ /g; }}
    if (defined $STRING{"pfhtm"}) { 
	$STRING{"pfhtm"}=~s/L/ /g; 
	if ($opt_phd !~ /htm/){
	    $STRING{"pfhtm"}=~s/H/T/g;$STRING{"pfhtm"}=~s/E/ /g; }}
    if (defined $STRING{"prhtm"}) { 
	$STRING{"prhtm"}=~s/L/ /g; 
	if ($opt_phd !~ /htm/){
	    $STRING{"prhtm"}=~s/H/T/g;$STRING{"prhtm"}=~s/E/ /g; }}

    @des_wrt=@des_0;
    $#htm_header=0;
    if    ( (length($STRING{"psec"})>3) && (length($STRING{"pacc"})>3) && 
	    (length($STRING{"phtm"})>3) ) { 
	push(@des_wrt,@des_sec,"subsec",@des_acc,"subacc",@des_htm,"subhtm"); 
	$mode_wrt="3";}
    elsif ( (length($STRING{"psec"})>3) && (length($STRING{"pacc"})>3) ) {
	push(@des_wrt,@des_sec,"subsec",@des_acc,"subacc"); 
	$mode_wrt="both"; }
    elsif ( length($STRING{"psec"})>3 ) { 
	push(@des_wrt,@des_sec,"subsec");                   
	$mode_wrt="sec"; }
    elsif ( length($STRING{"pacc"})>3 ) { 
	push(@des_wrt,@des_acc,"subacc");                   
	$mode_wrt="acc"; }
    elsif ( length($STRING{"phtm"})>3 ) { 
	push(@des_wrt,"ohtm","phtm","rihtm","prHhtm","prLhtm","subhtm","pfhtm");
	push(@des_wrt,"prhtm")  if ($Ldo_htmref);
	push(@des_wrt,"pthtm")  if ($Ldo_htmtop);
	$mode_wrt="htm"; 
	@htm_header=
	    &rdbphd_to_dotpred_head_htmtop(@deshd_rd_htm)
		if ($Ldo_htmref || $Ldo_htmtop); }
    else {
	print "*** ERROR rdbphd_to_dotpred: no \%STRING defined recognised\n";
	exit; }

    if ($Lscreen) {
	print "--- rdbphd_to_dotpred read from conversion:\n";
	&wrt_phdpred_from_string("STDOUT",$nres_per_row,$mode_wrt,$Ldo_htmref,
				 @des_wrt,"header",@htm_header); }
    &open_file("$fhout",">$file_out");
    &wrt_phdpred_from_string($fhout,$nres_per_row,$mode_wrt,$Ldo_htmref,
			     @des_wrt,"header",@htm_header); 
    close($fhout);
				# --------------------------------------------------
				# now collect for final file
				# --------------------------------------------------
    foreach $des ("aa","osec","psec","risec","oacc","pacc","riacc",
		  "ohtm","phtm","pfhtm","rihtm","prhtm","pthtm") {
	if (defined $STRING{"$des"}) {
	    if   ($des eq "aa") { 
		$nres=length($STRING{"$des"}); }
	    elsif(($des=~/^p/)&&(length($STRING{"$des"})>$nres)){
		$nres=length($STRING{"$des"}); }
	    $phd_fin{"$protname","$des"}=$STRING{"$des"}; }}
    $phd_fin{"$protname","nres"}=$nres;
				# ------------------------------
				# save memory
    undef %STRING; undef %rdb_rd; undef %rdb;
    return(%phd_fin);
}				# end of rdbphd_to_dotpred

#===============================================================================
sub rdbphd_to_dotpred_getstring {
    local (@des) = @_ ;
    local ($des,$ct);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   rdbphd_to_dotpred_getstring transform $rdb{"osec","1..n"} to $STRING{"osec"}
#       in::                     file
#       in / out GLOBAL:         %STRING, %rdb,$thresh_*,
#--------------------------------------------------------------------------------
    foreach $des (@des) {
	$STRING{"$des"}="";$ct=1;
	if ($des !~ /oacc|pacc/ ){
	    while (defined $rdb{"$des","$ct"}) {
		$STRING{"$des"}.=$rdb{"$des","$ct"};
		++$ct; } }
	else {
	    while (defined $rdb{"$des","$ct"}) {
		$STRING{"$des"}.=&exposure_project_1digit($rdb{"$des","$ct"});
		++$ct; } } }
}				# end of rdbphd_to_dotpred_getstring

#===============================================================================
sub rdbphd_to_dotpred_getsubset {
    local ($des,$ct,$desout,$thresh,$kwdPhd,$desrel);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   rdbphd_to_dotpred_getsubset assigns subsets:
#       in:                     file
#       in / out GLOBAL:        %STRING, %rdb,$thresh_*,
#--------------------------------------------------------------------------------
    foreach $des ("sec","acc","htm"){
				# assign thresholds
	if    ($des eq "sec") { $thresh=$thresh_sec; }
	elsif ($des eq "acc") { $thresh=$thresh_acc; }
	elsif ($des eq "htm") { $thresh=$thresh_htm; }

	$desphd="p"."$des";
				# note: for PHDacc subset on three states (b,e,i)
	$desphd="p"."bie"       if ($des eq "acc");
				# ignore different modes, than existing
	next if (! defined $rdb{"$desphd","1"});
	$desout="sub"."$des";
	$desrel="ri"."$des";
	$STRING{"$desout"}="";$ct=1; # initialise

	while ( defined $rdb{"$desphd","$ct"}) {
	    if (defined $rdb{"$desrel","$ct"} && 
		$rdb{"$desrel","$ct"} >= $thresh) {
		$STRING{"$desout"}.=$rdb{"$desphd","$ct"}; }
	    else {
		$STRING{"$desout"}.=".";}
	    ++$ct; }
    }
}				# end of rdbphd_to_dotpred_getsubset

#===============================================================================
sub rdbphd_to_dotpred_head_htmtop {
    local (@des)= @_ ;  local ($des,$tmp,@tmp,@out);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   rdbphd_to_dotpred_head_htmtop writes the header for htmtop
#--------------------------------------------------------------------------------
    $#out=0;
    foreach $des (@des){
	if (defined $rdb_rd{"$des"}){
	    $tmp=$rdb_rd{"$des"};$tmp=~s/^:*|:*$//g;
	    if ($tmp=~/\:/){
		$#tmp=0;@tmp=split(/:/,$tmp);} else {@tmp=("$tmp");}
	    if ($des !~/MODEL/){ # purge blanks and comments
		foreach $tmp (@tmp) {$tmp=~s/\(.*//g;$tmp=~s/\s//g;}}
	    foreach $tmp (@tmp) {
		push(@out,"$des:$tmp");}}}
    return(@out);
}				# end of rdbphd_to_dotpred_head_htmtop

#===============================================================================
sub read_exp80 {
    local ($fileInLoc,$des_seq,$Lseq,$des_sec,$Lsec,
	   $des_exp,$Lexp,$des_phd,$Lphd,$des_rel,$Lrel)=@_ ;
    local ($tmp,$id);
    $[=1;
#--------------------------------------------------------------------------------
#   read_exp80                  reads a secondary structure 80lines file
#
#       in:                     $fileInLoc: input file
#                               $des_seq, *sec, *phd, *rel: 
#                               descrip for seq, obs sec str, pred sec str reliability index
#                               e.g. "AA ", "Obs", "Prd", "Rel"
#                               $Lseq/sec/phd/rel: flags =0/1 read or don't read stuff
#       out GLOBAL:             @NAME, %SEQ, %SEC, %EXP, %PHDEXP, %RELEXP (key = name)
#          
#          
#--------------------------------------------------------------------------------
    $#NAME=$#SEQ=$#EXP=$#SEC=$#PHDEXP=$#RELEXP=0;

    &open_file("FHIN", "$fileInLoc");
    while ( <FHIN> ) {		# jump to first protein
	last if ( /^nos/ ); }
    while ( <FHIN> ) {
	$tmp=$_;$tmp=~s/\n//g;
	last if ($tmp=~/^END/);
	if (length($tmp)>0) {
				# ------------------------------
				# protein name, length
	    if ( $tmp =~ /^. . \w/ )  { 
		$tmp=~s/^....(\w+) *\d.*/$1/g; $tmp=~s/\n|\s//g;
		$id=$tmp;
		$SEQ{$id}=$SEC{$id}=$EXP{$id}=$PHDEXP{$id}=$RELEXP{$id}="";
		push(@NAME,$tmp); }
				# ------------------------------
				# sequence
	    elsif ( $Lseq && ($tmp =~ /^$des_seq/) ) {
		$tmp=~s/^$des_seq\s?\|//g; $tmp=~s/\s*\|$//g;
		$SEQ{$id}.=$tmp; }
				# ------------------------------
				# observed sec str
	    elsif ( $Lsec && ($tmp =~ /^$des_sec/) ) {
		$tmp=~s/^$des_sec\s?\|//g; $tmp=~s/\s*\|$//g;
		$SEC{$id}.=$tmp; }
				# ------------------------------
				# observed accessibility
	    elsif ( $Lexp && ($tmp =~ /^$des_exp/) ) {
		$tmp=~s/^$des_exp\|//g; $tmp=~s/\s*\|$//g;
		$EXP{$id}.=$tmp; }
				# ------------------------------
				# predicted accessibility
	    elsif ( $Lphd && ($tmp =~ /^$des_phd/) ) {
		$tmp=~s/^$des_phd\|//g; $tmp=~s/\s*\|$//g;
		$PHDEXP{$id}.=$tmp; }
				# ------------------------------
				# observed sec str
	    elsif ( $Lrel && ($tmp =~ /^$des_rel/) ) {
		$tmp=~s/^$des_rel\|//g; $tmp=~s/\s*\|$//g;
		$RELEXP{$id}.=$tmp; }
	}
    }
    close(FHIN);
}				# end of read_exp80

#===============================================================================
sub read_sec80 {
    local ($fileInLoc,$des_seq,$Lseq,$des_sec,$Lsec,$des_phd,$Lphd,$des_rel,$Lrel) = @_ ;
    local ($tmp,$id);
    $[=1;
#--------------------------------------------------------------------------------
#   read_sec80                  reads a secondary structure 80lines file
#       in:                     $fileInLoc: input file
#                               $des_seq, *sec, *phd, *rel: 
#                               descr for seq, obs sec str, pred sec str reliability index
#                               e.g. "AA ", "Obs", "Prd", "Rel"
#                               $Lseq/sec/phd/rel: flags =0/1 read or don't read stuff
#       out GLOBAL:             @NAME, %SEQ, %SEC, %PHD, %REL (key = name)
#--------------------------------------------------------------------------------
    $#NAME=$#SEQ=$#SEC=$#PHDSEC=$#RELSEC=0;

    &open_file("FHIN", "$fileInLoc");
    while ( <FHIN> ) {		# jump to first protein
	last if ( /^nos/ );}
    while ( <FHIN> ) {
	$tmp=$_;$tmp=~s/\n//g;
	last if ($tmp=~/^END/);
	if (length($tmp)>0) {
				# ------------------------------
				# protein name, length
	    if ( $tmp =~ /^. . \w/ )  { 
		$tmp=~s/^....(\w+) *\d.*/$1/g; $tmp=~s/\n|\s//g;
		$id=$tmp;
		$SEQ{$id}=$SEC{$id}=$PHDSEC{$id}=$RELSEC{$id}="";
		push(@NAME,$tmp); }
				# ------------------------------
				# sequence
	    elsif ( $Lseq && ($tmp =~ /^$des_seq/) ) {
		$tmp=~s/^$des_seq\s?\|//g; $tmp=~s/\s*\|$//g;
		$SEQ{$id}.=$tmp; }
				# ------------------------------
				# observed sec str
	    elsif ( $Lsec && ($tmp =~ /^$des_sec/) ) {
		$tmp=~s/^$des_sec\|//g; $tmp=~s/\|$//g;
		$SEC{$id}.=$tmp; }
				# ------------------------------
				# predicted sec str
	    elsif ( $Lphd && ($tmp =~ /^$des_phd/) ) {
		$tmp=~s/^$des_phd\|//g; $tmp=~s/\|$//g;
		$PHDSEC{$id}.=$tmp; }
				# ------------------------------
				# observed sec str
	    elsif ( $Lrel && ($tmp =~ /^$des_rel/) ) {
		$tmp=~s/^$des_rel\|//g; $tmp=~s/\s*\|$//g;
		$RELSEC{$id}.=$tmp; }
	}
    }
    close(FHIN);

}				# end of read_sec80

#===============================================================================
sub topitsCheckLibrary {
    local($fileInLoc,$fileOutLoc,$dirDsspLoc) = @_ ;
    local($SBR,$fhinLoc,$fhoutLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   topitsCheckLibrary          truncates fold library to existing files
#       in:                     $fileInLoc:    current fold library
#       in:                     $fileOutLoc:   truncated version (if some missing)
#       in:                     $dirDsspLoc:   where to search for DSSP
#                                              syntax '/dir1/dssp,/dir2/x'
#       out:                    1|0,$msg,$ctOk,$ctMissing
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR="topitsCheckLibrary";  
    $fhinLoc="FHIN_"."topitsCheckLibrary";$fhoutLoc="FHOUT_"."topitsCheckLibrary";
    
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
    return(&errSbr("not def fileOutLoc!"))         if (! defined $fileOutLoc);

    return(&errSbr("miss in file '$fileInLoc'!"))  if (! -e $fileInLoc);
				# ------------------------------
				# open file
    open($fhinLoc,$fileInLoc) || 
	return(&errSbr("fileInLoc=$fileInLoc, not opened",$SBR));

				# ------------------------------
				# directory for DSSP given?
    $dirDsspLoc=0               if (! defined $dirDsspLoc || length($dirDsspLoc)<=1 );
    $#dirDsspLoc=0;
    if    ($dirDsspLoc && $dirDsspLoc=~/\,/) {
	@dirDsspLoc=split(/,/,$dirDsspLoc) 
	    if ($dirDsspLoc && $dirDsspLoc=~/\,/); }
    elsif ($dirDsspLoc) {
	@dirDsspLoc=($dirDsspLoc);}
				# append slashes
    foreach $dir (@dirDsspLoc) {
	$dir.="/"              if ($dir !~/\/$/);}

    $#tmp=$ctMissing=$ctOk=0;
    $dirAdded=0;
				# ------------------------------
    while (<$fhinLoc>) {	# read file
				# skip comments
	next if ($_=~/^[\s\t]*\#/);
	$_=~s/\n//g;
	next if (length($_)<1); # skip empty
				# purge chain
	$file=$_; $chain="";
	if ($_=~/(_?\!?_[A-Za-z0-9])/) {
	    $chain=$1;
	    $file=~s/$chain//g; } 
				# replace variable
	$file=~s/\$dirDssp\///g if ($file=~/\$dirDssp\// );
				# add dir (only if NOT existing)
	if ($dirDsspLoc && ! -e $file) {
	    $Lok=0;
	    foreach $dir (@dirDsspLoc) {
		$fileNew=$dir;
		$fileNew.="/"   if (length($fileNew) > 1 && $fileNew !~/\/$/);
		$fileNew.=$file;
		next if (! -e $fileNew);
		$dirAdded=$dir  if (! $dirAdded);
		$Lok=1;
		last; }
	    $file=$fileNew      if ($Lok); }

	if (! -e $file) {
	    ++$ctMissing;
	    print "-*- WARN $SBR: missing=".$file.$chain."\n";
	    next; }
	++$ctOk;
	$file.=$chain           if (length($chain)>0);
	push(@tmp,$file); 
    } close($fhinLoc);
				# ------------------------------
				# none missing, no dir to add?
    return(1,"ok $SBR",$ctOk,0)	# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
        if ($ctMissing == 0 && ! $dirAdded);

				# --------------------------------------------------
				# some missing, or data dir to add
    				#      -> new file
				# --------------------------------------------------
    $dirAdded.="/"              if ($dirAdded && $dirAdded !~/\/$/);
    open($fhoutLoc,">".$fileOutLoc) || 
	return(&errSbr("fileOutLoc=$fileOutLoc, not created",$SBR));
    foreach $file (@tmp) {
	$file=$dirAdded.$file if ($dirAdded && 
				  $file !~ $dirAdded);
	print $fhoutLoc "$file\n";}
    close($fhoutLoc);

    return(1,"ok $SBR",$ctOk,$ctMissing,$dirAdded);
}				# end of topitsCheckLibrary

#===============================================================================
sub topitsMakeMetric {
    local($fileMetricInLoc,$fileMetricInSeqLoc,$fileMetricOutLoc,
	  $mixStrSeqLoc,$doMixStrSeqLoc,$exeMakeMetricLoc,
	  $pwdLoc,$dirWorkLoc,$titleTmpLoc,$jobidLoc,$LdebugLoc,$fileOutScreenLoc,$fhTraceLoc) = @_ ;
    local($SBR);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   topitsMakeMetric            makes the BIG MaxHom metric to compare sequence
#                               and secondary structure
#                               
#       in:                     $fileMetricIn:       TOPITS metric (only structure)
#       in:                     $fileMetricInSeqLoc: MaxHom sequence metric (Blosum,McLachlan)
#       in:                     $fileMetricOutLoc:   final output metric
#       in:                     $mixStrSeqLoc:       integer percentage (0-100) 
#                                                    giving the ratio of structure to sequence:
#                               =100 -> structure, only
#                               = 50 -> half structure, half sequence
#                               =  0 -> sequence, only
#                               
#       in:                     $doMixStrSeqLoc:     redo the mix (default: take standard files)
#       in:                     $exeMakeMetricLoc:   FORTRAN executable to make metric
#       in:                     $dirWorkLoc:         working directory
#       in:                     $titleTmpLoc:        title for temporary files
#       in:                     $jobidLoc:           jobid
#       in:                     $LdebugLoc:          if 1: add temp files to-to-delete-array
#       in:                     $fileOutScreenLoc:   file getting output from system commands
#       in:                     $fhTraceLoc:         file handle to trace system errors
#                               
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR="topitsMakeMetric";
    $fhinLoc="FHIN_"."topitsMakeMetric";$fhoutLoc="FHIN_"."topitsMakeMetric";
				# ------------------------------
				# check arguments
    return(&errSbr("not def fileMetricInLoc!",$SBR))    if (! defined $fileMetricInLoc);
    return(&errSbr("not def fileMetricInSeqLoc!",$SBR)) if (! defined $fileMetricInSeqLoc);
    return(&errSbr("not def fileMetricOutLoc!",$SBR))   if (! defined $fileMetricOutLoc);
    return(&errSbr("not def mixStrSeqLoc!",$SBR))       if (! defined $mixStrSeqLoc);
    return(&errSbr("not def doMixStrSeqLoc!",$SBR))     if (! defined $doMixStrSeqLoc);
    return(&errSbr("not def exeMakeMetricLoc!",$SBR))   if (! defined $exeMakeMetricLoc);
    return(&errSbr("not def pwdLoc!",$SBR))             if (! defined $pwdLoc);
    return(&errSbr("not def dirWorkLoc!",$SBR))         if (! defined $dirWorkLoc);
    return(&errSbr("not def titleTmpLoc!",$SBR))        if (! defined $titleTmpLoc);
    return(&errSbr("not def jobidLoc!",$SBR))           if (! defined $jobidLoc);
    return(&errSbr("not def LdebugLoc!",$SBR))          if (! defined $LdebugLoc);
    return(&errSbr("not def fileOutScreenLoc!",$SBR))   if (! defined $fileOutScreenLoc);
    return(&errSbr("not def fhTraceLoc!",$SBR))         if (! defined $fhTraceLoc);
				# ------------------------------
				# file existence
    return(&errSbr("miss in file '$fileMetricInLoc'!",$SBR))  if (! -e $fileMetricInLoc);

    $screen="--- $SBR: came in with:\n";
				# ------------------------------
				# metric file (GIVE full path)
				# ------------------------------
    if (length($dirWorkLoc) > 0) {
	$dir=$dirWorkLoc;}
    else {
	$dir=$pwdLoc;}
    $fileMetricInLocTmp=  $dir.$titleTmpLoc."METRIC_".$jobidLoc.".input";
    $fileMetricOutLocTmp= $dir.$titleTmpLoc."METRIC_".$jobidLoc.".output"; 

				# ------------------------------
				# cp file to working directory
    ($Lok,$msg)=
	&sysCpfile($fileMetricInLoc,$fileMetricInLocTmp);
		                return(&errSbrMsg("failed to copy: $fileMetricInLoc->".
						  "$fileMetricInLocTmp",$msg,$SBR)) if (! $Lok); 
				# ------------------------------
				# temporary files to delete
    $#tmpFiles=0;
    push(@tmpFiles,$fileMetricInLocTmp)  if (! $LdebugLoc );
    push(@tmpFiles,$fileMetricOutLocTmp) if (! $LdebugLoc );
	    

				# --------------------------------------------------
				# append new ratio (FAC_STR=dd) to default input file
				# --------------------------------------------------
    if ($doMixStrSeqLoc) {
				# structure only
	if    ($mixStrSeqLoc==100) { 
	    $tmp_mix="FAC_STR=10"; }
				# sequence only
	elsif ($mixStrSeqLoc==50) { 
	    $tmp_mix="FAC_STR= 0"; }
				# half half
	elsif ($mixStrSeqLoc==50) { 
	    $tmp_mix="FAC_STR= 5"; }
				# somewhere in between
	else { 
	    $tmp_mix="FAC_STR= ".int($mixStrSeqLoc/10); }

				# ------------------------------
				# append new mix to temporary file
	($Lok,$msg,$tmp)=
	    &sysEchofile($tmp_mix,$fileMetricInLocTmp);
	                        return(&errSbrMsg("failed to echo ($tmp)",$msg)) if (! $Lok);
	$screen.=$tmp; }	# for screen message

	
				# --------------------------------------------------
				# do it: make the new metric
				# --------------------------------------------------
    $cmd=  $exeMakeMetricLoc." ".$fileMetricInLocTmp." ".$fileMetricOutLocTmp;
    $cmd.= " ".$fileMetricSeqLoc if ($fileMetricSeqLoc);
    $cmdEval="";		# avoid warnings
    eval      "\$cmdEval=\"$cmd\""; 

    ($Lok,$msg)=
	&sysRunProg($cmdEval,$fileOutScreenLoc,$fhTraceLoc);
                                 return(&errSbrMsg("failed making metric ($cmd)",
						   $msg,$SBR)) if (! $Lok); 

				# got it?
    return(&errSbrMsg("no metric $fileMetricOutLocTmp from system:\n".
		      $cmd."\n",$msg,$SBR)) if (! -e $fileMetricOutLocTmp);

				# --------------------------------------------------
				# keep or delete?
				# --------------------------------------------------
				# if metric file local, delete it in the end
    if (($fileMetricOutLoc !~ /home\/(phd|rost)/) &&
	$fileMetricOutLoc =~ /$dirWorkLoc/ ||
	$fileMetricOutLoc =~ /$jobidLoc/){
	push(@tmpFiles,$fileMetricOutLoc); }
				# ------------------------------
				# cp file to working directory
    ($Lok,$msg)=
	&sysCpfile($fileMetricOutLocTmp,fileMetricOutLoc);
		                return(&errSbrMsg("failed to copy: $fileMetricOutLocTmp->".
						  "$fileMetricOutLoc",$msg,$SBR)) if (! $Lok); 
    return(1,"ok $SBR",@tmpFiles);
}				# end of topitsMakeMetric

#===============================================================================
sub topitsRunMaxhom {
    local ($fileHsspInLoc,$fileOutHssp,$fileOutStrip,$fileOutHsspX,
	   $exeMaxLoc,$fileMaxDefLoc,$fileAliListLoc,$fileMetricLoc,$dirPdbLoc,$paraSuperposLoc,
	   $LprofileLoc,$paraSminLoc,$paraSmaxLoc,$paraGoLoc,$paraGeLoc,$paraW1Loc,$paraW2Loc,
	   $paraIndel1Loc,$paraIndel2Loc,$paraNaliLoc,$paraThreshLoc,$paraSortLoc,$paraProfOutLoc,
	   $dateLoc,$niceLoc,$jobidLoc,$fileScreenLoc,$fhTraceLoc)=@_;
    local ($SBR,$maxCmd);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   topitsRunMaxhom             runs MaxHom in TOPITS fashion (no profile)
#                               
#       typical combinations:   
#                               Mc100: smin=-1.0, smax=3.0, go=3.0, ge=0.3
#                               Mc 50: smin=-1.0, smax=1.0, go=2.0, ge=0.2
#                               Mc  0: smin=-0.5, smax=1.0, go=3.0, ge=0.1
#                               
#                               Bl 50: smin=-1.0, smax=2.0, go=2.0, ge=0.2
#                               
#       in:                     $fileInLoc:     input file
#       in:                     $fileOutHssp:   output file.hssp
#       in:                     $fileOutStrip:  output file.strip
#                             =0  ->            no strip
#       in:                     $fileOutHsspX:  output file.x
#                             =0  ->            no X
#                               
#       in:                     $exeMaxLoc:     FORTRAN executable
#       in:                     $fileMaxDefLoc: maxhom defaults file
#       in:                     $fileAliList:   file with fold library (list of file names)
#                                               (now: must be DSSP format)
#       in:                     $fileMetricLoc: comparison metric
#       in:                     $dirPdbLoc:     PDB directory
#       in:                     $paraSuperpos:  compiles RMSd values
#                               
#       in:                     $LprofileLoc:   <1|0>                   (2nd is profile)
#       in:                     $paraSminLoc:   minimal value of metric (typical -1 )
#       in:                     $paraSmaxLoc:   maximal value of metric (typical  2 )
#                                               
#       in:                     $paraGoLoc:     gap open penalty        (typical  3.0)
#       in:                     $paraGeLoc:     gap extension/elongation penalty (typ 0.3)
#       in:                     $paraW1Loc:     weight seq 1            (typ yes)
#       in:                     $paraW2Loc:     weight seq 1            (typ yes)
#       in:                     $paraIndel1Loc: allow insertions/del in seq 1
#       in:                     $paraIndel2Loc: allow insertions/del in seq 1
#       in:                     $paraNaliLoc:   maximal number of alis reported (was 500)
#       in:                     $paraThreshLoc: thresholding reported alignments?
#       in:                     $paraSortLoc:   how to sort results
#       in:                     $paraProfOut:   
#       in:                     $dateLoc:       
#       in:                     $niceLoc:       
#       in:                     $jobidLoc:      number of current process
#       in:                     $fileScreenLoc: system calls dumped to this file
#       in:                     $fhTraceLoc:    handle for errors
#                               
#       out:                    <1|0>,$msg
#       err:                    ok=(1,'ok'), err=(0,'msg')
#--------------------------------------------------------------------------------

    $SBR="topitsRunMaxhom";
				# ------------------------------
				# check arguments
				# ------------------------------
    return(0,"*** $SBR: not def fileHsspInLoc!")    if (! defined $fileHsspInLoc);
    return(0,"*** $SBR: not def fileOutHssp!")      if (! defined $fileOutHssp);
    return(0,"*** $SBR: not def fileOutStrip!")     if (! defined $fileOutStrip);
    return(0,"*** $SBR: not def fileOutHsspX!")     if (! defined $fileOutHsspX);

    return(0,"*** $SBR: not def exeMaxLoc!")        if (! defined $exeMaxLoc);
    return(0,"*** $SBR: not def fileMaxDefLoc!")    if (! defined $fileMaxDefLoc);
    return(0,"*** $SBR: not def fileAliListLoc!")   if (! defined $fileAliListLoc);
    return(0,"*** $SBR: not def fileMetricLoc!")    if (! defined $fileMetricLoc);
    return(0,"*** $SBR: not def dirPdbLoc!")        if (! defined $dirPdbLoc);
    return(0,"*** $SBR: not def paraSuperposLoc!")  if (! defined $paraSuperposLoc);

    return(0,"*** $SBR: not def LprofileLoc!")      if (! defined $LprofileLoc);
    return(0,"*** $SBR: not def paraSminLoc!")      if (! defined $paraSminLoc);
    return(0,"*** $SBR: not def paraSmaxLoc!")      if (! defined $paraSmaxLoc);
    return(0,"*** $SBR: not def paraGoLoc!")        if (! defined $paraGoLoc);
    return(0,"*** $SBR: not def paraGeLoc!")        if (! defined $paraGeLoc);
    return(0,"*** $SBR: not def paraW1Loc!")        if (! defined $paraW1Loc);
    return(0,"*** $SBR: not def paraW2Loc!")        if (! defined $paraW2Loc);
    return(0,"*** $SBR: not def paraIndel1Loc!")    if (! defined $paraIndel1Loc);
    return(0,"*** $SBR: not def paraIndel2Loc!")    if (! defined $paraIndel2Loc);
    return(0,"*** $SBR: not def paraNaliLoc!")      if (! defined $paraNaliLoc);
    return(0,"*** $SBR: not def paraThreshLoc!")    if (! defined $paraThreshLoc);
    return(0,"*** $SBR: not def paraSortLoc!")      if (! defined $paraSortLoc);
    return(0,"*** $SBR: not def paraProfOutLoc!")   if (! defined $paraProfOutLoc);

    return(0,"*** $SBR: not def dateLoc!")          if (! defined $dateLoc);
    return(0,"*** $SBR: not def niceLoc!")          if (! defined $niceLoc);
    return(0,"*** $SBR: not def jobidLoc!")         if (! defined $jobidLoc);

    $fileScreenLoc=0                                      if (! defined $fileScreenLoc);
    $fhTraceLoc="STDOUT"                                  if (! defined $fhTraceLoc);
				# check existence of files
    return(0,"*** $SBR: miss in file '$fileInLoc'!")      if (! -e $fileHsspInLoc);
    return(0,"*** $SBR: miss in exe  '$exeMaxLoc'!")      if (! -e $exeMaxLoc);
    return(0,"*** $SBR: miss in file '$fileMaxDefLoc'!")  if (! -e $fileMaxDefLoc);
    return(0,"*** $SBR: miss in file '$fileAliListLoc'!") if (! -e $fileAliListLoc);
    return(0,"*** $SBR: miss in file '$fileMetricLoc'!")  if (! -e $fileMetricLoc);

    $msgHere="--- $SBR: came to run TOPITS ($fileHsspInLoc,$fileOutHssp)\n";
                                # --------------------------------------------------
                                # get command line argument for starting MaxHom
                                # --------------------------------------------------
    $maxCmd=
	&maxhomGetArg2($niceLoc,$exeMaxLoc,$fileMaxDefLoc,$jobidLoc,
		       $fileHsspInLoc,$fileAliListLoc,$LprofileLoc,$fileMetricLoc,
		       $paraSminLoc,$paraSmaxLoc,$paraGoLoc,$paraGeLoc,
		       $paraW1Loc,$paraW2Loc,$paraIndel1Loc,$paraIndel2Loc,
		       $paraNaliLoc,$paraThreshLoc,$paraSortLoc,$paraProfOutLoc,$paraSuperposLoc,
		       $dirPdbLoc,$fileOutHssp,$fileOutStrip,$fileOutHsspX);
				# --------------------------------------------------
				# the thing that does IT!
				# --------------------------------------------------
    $msgHere.="--- $SBR: running MaxHom-Topits:\n".$maxCmd."\n";

    ($Lok,$msg)=
	&sysRunProg($maxCmd,$fileScreenLoc,$fhTraceLoc);
                                return(&errSbrMsg("failed on MaxHom \n".$maxCmd."\n".
						  "msgHere=\n".$msgHere."\n".
						  "*** msg from sys=",$msg,$SBR)) if (! $Lok);

    $tmp=  "--- ^\n"."--- | \n"."--- + comment from Dr. Maxhom\n"; $tmp.="." x 50 ."\n";
    ($Lok,$msg)=
        &sysEchofile($tmp,$fileScreenLoc)     if ($fileScreenLoc);
    print $tmp                  if (! $fileScreenLoc);

				# ------------------------------
				# output ok?
				# ------------------------------
    return(&errSbr("failed making hssp $fileOutHssp, msgHere=\n".
		   $msgHere."\n",$SBR)) if (! -e $fileOutHssp);
    return(&errSbr("empty hssp $fileOutHssp, msgHere=\n".
		   $msgHere."\n",$SBR)) if (&is_hssp_empty($fileOutHssp));
    return(&errSbr("failed making strip $fileOutHssp, msgHere=\n".
		   $msgHere."\n",$SBR)) if (! -e $fileOutStrip);
    return(1,"ok $SBR");
}				# end topitsRunMaxhom


#===============================================================================
sub topitsWrtOwn {
    local($fileHsspLoc,$fileStripLoc,$fileOutLoc,$mix,$fhErrSbr) = @_ ;
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok,$txt,$kwd,$it,$wrtTmp,$wrtTmp2,
	  %rdHdr,@kwdLoc,@kwdOutTop2,@kwdOutSummary2,%wrtLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   topitsWrtOwn                writes the TOPITS format
#       in:                     $fileHsspLoc,$fileStripLoc,$fileOutLoc,$mix,$fhErrSbr
#       out:                    file written ($fileOutLoc)
#       err:                    ok=(1,'ok'), err=(0,'msg')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."topitsWrtOwn";
    $fhinLoc= "FHIN". "$sbrName";
    $fhoutLoc="FHOUT"."$sbrName";
    $sep="\t";
				# ------------------------------
				# check arguments
    return(0,"*** $sbrName: not def fileHsspLoc!")          if (! defined $fileHsspLoc);
    return(0,"*** $sbrName: not def fileStripLoc!")         if (! defined $fileStripLoc);
    return(0,"*** $sbrName: not def fileOutLoc!")           if (! defined $fileOutLoc);
    $fhErrSbr="STDOUT"                                      if (! defined $fhErrSbr);
    return(0,"*** $sbrName: miss in file '$fileHsspLoc'!")  if (! -e $fileHsspLoc);
    return(0,"*** $sbrName: miss in file '$fileStripLoc'!") if (! -e $fileStripLoc);
    @kwdOutTop2=
	("len1","nali","listName","sortMode","weight1","weight2",
	 "smin","smax","gapOpen","gapElon","indel1","indel2","threshold");
    @kwdOutSummary2=
	("id2","pide","lali","ngap","lgap","len2",
	 "Eali","Zali","strh","ifir","ilas","jfir","jlas","name");
				# ------------------------------
				# set up keywords
    @kwdLoc=
	 (
	  "hsspTop",   "threshold","len1",
	  "hsspPair",  "id2","pdbid2","pide","ifir","ilas","jfir","jlas",
	               "lali","ngap","lgap","len2",
	  "stripTop",  "nali","listName","sortMode","weight1","weight2",
	               "smin","smax","gapOpen","gapElon","indel1","indel2",
	  "stripPair", "energy","zscore","strh","name");

    $des_expl{"mix"}=      "weight structure:sequence";
    $des_expl{"nali"}=     "number of alignments in file";
    $des_expl{"listName"}= "fold library used for threading";
    $des_expl{"sortMode"}= "mode of ranking the hits";
    $des_expl{"weight1"}=  "YES if guide sequence weighted by residue conservation";
    $des_expl{"weight2"}=  "YES if aligned sequence weighted by residue conservation";
    $des_expl{"smin"}=     "minimal value of alignment metric";
    $des_expl{"smax"}=     "maximal value of alignment metric";
    $des_expl{"gapOpen"}=  "gap open penalty";
    $des_expl{"gapElon"}=  "gap elongation penalty";
    $des_expl{"indel1"}=   "YES if insertions in sec str regions allowed for guide seq";
    $des_expl{"indel2"}=   "YES if insertions in sec str regions allowed for aligned seq";
    $des_expl{"len1"}=     "length of search sequence, i.e., your protein";
    $des_expl{"threshold"}="hits above this threshold included (ALL means no threshold)";

    $des_expl{"rank"}=     "rank in alignment list, sorted according to sortMode";
    $des_expl{"Eali"}=     "alignment score";
    $des_expl{"Zali"}=     "alignment zcore;  note: hits with z>3 more reliable";
    $des_expl{"strh"}=     "secondary str identity between guide and aligned protein";
    $des_expl{"pide"}=     "percentage of pairwise sequence identity";
    $des_expl{"lali"}=     "length of alignment";
    $des_expl{"lgap"}=     "number of residues inserted";
    $des_expl{"ngap"}=     "number of insertions";
    $des_expl{"len2"}=     "length of aligned protein structure";
    $des_expl{"id2"}=      "PDB identifier of aligned structure (1pdbC -> C = chain id)";
    $des_expl{"name"}=     "name of aligned protein structure";
    $des_expl{"ifir"}=     "position of first residue of search sequence";
    $des_expl{"ilas"}=     "position of last residue of search sequence";
    $des_expl{"jfir"}=     "pos of first res of remote homologue (e.g. DSSP number)";
    $des_expl{"jlas"}=     "pos of last res of remote homologue  (e.g. DSSP number)";
    $des_expl{""}=    "";

				# ------------------------------
    undef %rdHdr;		# read HSSP + STRIP header

    ($Lok,$txt,%rdHdr)=
	  &hsspRdStripAndHeader($fileHsspLoc,$fileStripLoc,$fhErrSbr,@kwdLoc);
    return(0,"$sbrName: returned 0\n$txt\n") if (! $Lok);
				# ------------------------------
				# write output in TOPITS format
    open($fhoutLoc,">".$fileOutLoc) ||
	return(0,"$sbrName: couldnt open new file $fileOut");
				# corrections
    $rdHdr{"threshold"}=~s/according to\s*\:\s*//g if (defined $rdHdr{"threshold"});
    foreach $it (1..$rdHdr{"NROWS"}){
	$rdHdr{"Eali","$it"}=$rdHdr{"energy","$it"} if (defined $rdHdr{"energy","$it"});
	$rdHdr{"Zali","$it"}=$rdHdr{"zscore","$it"} if (defined $rdHdr{"zscore","$it"});
    }
#    $rdHdr{"name","$it"}=$rdHdr{"zscore","$it"} if (defined $rdHdr{"zscore","$it"});
				# ------------------------------
    $wrtTmp=$wrtTmp2="";	# build up for communication with subroutine
    undef %wrtLoc;
    foreach $kwd(@kwdOutTop2){
	$wrtLoc{"$kwd"}=       $rdHdr{"$kwd"};
	$wrtLoc{"expl"."$kwd"}=$des_expl{"$kwd"};$wrtTmp.="$kwd,";}
    if (defined $mix && $mix ne "unk" && length($mix)>1){
	$kwd="mix";
	$wrtLoc{"$kwd"}=       $mix;
	$wrtLoc{"expl"."$kwd"}=$des_expl{"$kwd"};$wrtTmp.="$kwd,";}
    foreach $kwd(@kwdOutSummary2){
	$wrtLoc{"expl"."$kwd"}=$des_expl{"$kwd"};$wrtTmp2.="$kwd,";}
				# ------------------------------
				# write header
    ($Lok,$txt)=
	&topitsWrtOwnHdr($fhoutLoc,$wrtTmp,$wrtTmp2,%wrtLoc);
    undef %wrtLoc;
				# ------------------------------
				# write names of first block
    print $fhoutLoc 
	"# BLOCK    TOPITS HEADER: SUMMARY\n";
    printf $fhoutLoc "%-s","rank";
    foreach $kwd(@kwdOutSummary2){
#	$sepTmp="\n" if ($kwd eq $kwdOutTop2[$#kwdOutTop2]);
	printf $fhoutLoc "$sep%-s",$kwd;}
    print $fhoutLoc "\n";
				# ------------------------------
				# write first block of data
    foreach $it (1..$rdHdr{"NROWS"}){
	printf $fhoutLoc "%-s",$it;
	foreach $kwd(@kwdOutSummary2){
	    printf $fhoutLoc "$sep%-s",$rdHdr{"$kwd","$it"};}
	print $fhoutLoc "\n";
    }
				# ------------------------------
				# next block (ali)
#    print $fhoutLoc
#	"# --------------------------------------------------------------------------------\n",
#	;
				# ------------------------------
				# correct file end
    print $fhoutLoc "//\n";
    close($fhoutLoc);
    undef %rdHdr;		# read HSSP + STRIP header
    return(1,"ok $sbrName");
}				# end of topitsWrtOwn

#===============================================================================
sub topitsWrtOwnHdr {
    local($fhoutTmp,$desLoc,$desLoc2,%wrtLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   topitsWrtOwnHdr             writes the HEADER for the TOPITS specific format
#       in:                     FHOUT,"kwd1,kwd2,kwd3",%wrtLoc
#                               $wrtLoc{"$kwd"}=result of paramter
#                               $wrtLoc{"expl$kwd"}=explanation of paramter
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";$sbrName="$tmp"."topitsWrtOwnHdr";
				# ------------------------------
				# keywords to write
    $desLoc=~s/^,*|,*$//g;      $desLoc2=~s/^,*|,*$//g;
    @kwdHdr=split(/,/,$desLoc); @kwdCol=split(/,/,$desLoc2);
    
				# ------------------------------
				# begin
    print $fhoutTmp
	"# TOPITS (Threading One-D Predictions Into Three-D Structures)\n",
	"# --------------------------------------------------------------------------------\n",
	"# FORMAT   begin\n",
	"# FORMAT   general:    - lines starting with hashes contain comments or PARAMETERS\n",
	"# FORMAT   general:    - columns are delimited by tabs\n",
	"# FORMAT   general:    - the data are given in BLOCKS, each introduced by a line\n",
	"# FORMAT   general:      beginning with a hash and a keyword\n",
	"# FORMAT   parameters: '# PARA:tab     keyword =tab value tab (further-information)'\n",
	"# FORMAT   notation:   '# NOTATION:tab keyword tab explanation'\n",
	"# FORMAT   info:       '# INFO:tab     text'\n",
	"# FORMAT   blocks 0:   '# BLOCK        keyword'\n",
	"# FORMAT   blocks 1:    column names (tab delimited)\n",
	"# FORMAT   blocks n>1:  column data  (tab delimited)\n",
	"# FORMAT   file end:   '//' marks the end of a complete file\n",
	"# FORMAT   end\n",
	"# --------------------------------------------------------------------------------\n";
				# ------------------------------
				# write parameters
    print $fhoutTmp
	"# PARA     begin\n",
	"# PARA     TOPITS HEADER: PARAMETERS\n";
    foreach $des (@kwdHdr){
	next if (! defined $wrtLoc{"$des"});
	$tmp1=$wrtLoc{"expl"."$des"};$tmp2=length($tmp1);$tmp="$tmp2"."s";
	$wrtLoc{"$des"}=~s/\s//g; # purge blanks
	if ($des eq "mix"){
	    $mix=~s/\D//g;
	    printf $fhoutTmp 
		"# PARA:\t%-10s =\t%-6d\t(i.e. str=%3d%1s, seq=%3d%1s)\n",
		"str:seq",int($mix),int($mix),"%",int(100-$mix),"%";}
	else {
	    printf $fhoutTmp 
		"# PARA:\t%-10s =\t%-6s\n",$des,$wrtLoc{"$des"};}}
    print $fhoutTmp
	"# PARA     end\n",
	"# --------------------------------------------------------------------------------\n";
				# ------------------------------
				# explanations
    print $fhoutTmp
	"# NOTATION begin\n",
	"# NOTATION TOPITS HEADER: ABBREVIATIONS PARAMETERS\n";
    foreach $des (@kwdHdr){
	$tmp1=$wrtLoc{"expl"."$des"};$tmp2=length($tmp1);$tmp="$tmp2"."s";
	$tmp=length($wrtLoc{"expl"."$des"});$tmp.="s";
	$des2=$des;  # $des2=~tr/[a-z]/[A-Z]/;
	$des2="str:seq" if ($des2 eq "mix");
	printf $fhoutTmp "# NOTATION:\t%-12s:\t%-$tmp\n",$des2,$tmp1;}
    print $fhoutTmp
	"# NOTATION TOPITS HEADER: ABBREVIATIONS SUMMARY\n";
    foreach $des (@kwdCol){
	$tmp1=$wrtLoc{"expl"."$des"};$tmp2=length($tmp1);$tmp="$tmp2"."s";
	$tmp=length($wrtLoc{"expl"."$des"});$tmp.="s";
	$des2=$des;  # $des2=~tr/[a-z]/[A-Z]/;
	printf $fhoutTmp "# NOTATION:\t%-12s:\t%-$tmp\n",$des2,$tmp1;}
	
    print $fhoutTmp
	"# NOTATION end\n",
	"# --------------------------------------------------------------------------------\n";
				# ------------------------------
				# information about method
    print $fhoutTmp 
	"# INFO     begin\n",
	"# INFO     TOPITS HEADER: ACCURACY\n",
	"# INFO:\t Tested on 80 proteins, TOPITS found the correct remote homologue in about\n",
	"# INFO:\t 30%of the cases.  Detection accuracy was higher for higher z-scores:\n",
	"# INFO:\t ZALI>0   => 1st hit correct in 33% of cases\n",
	"# INFO:\t ZALI>3   => 1st hit correct in 50% of cases\n",
	"# INFO:\t ZALI>3.5 => 1st hit correct in 60% of cases\n",
	"# INFO     end\n",
	"# --------------------------------------------------------------------------------\n";
}				# end of topitsWrtOwnHdr

#===============================================================================
sub write80_data_prepdata {
    local ( @data_in) = @_;
    local ( $i);
    $[=1;
#----------------------------------------------------------------------
#   write80_data_prepdata       writes input into array called @write80_data
#----------------------------------------------------------------------
    $#write80_data = 0;
    for ( $i=1; $i <=$#data_in ; $i ++ ) {
	$write80_data[$i] = $data_in[$i];
    }
}				# end of: write80_data_prepare_data

#===============================================================================
sub write80_data_preptext {
    local (@data_in) = @_;
    local ( $i, $it2);
    $[=1;
#----------------------------------------------------------------------
#   write80_data_preptext       writes input into array called @write80_data
#----------------------------------------------------------------------
    $#write80_text = 0;
    for ( $i=1; $i <= $#data_in ; $i ++ ) {
	$write80_text[$i] = $data_in[$i];
    }
}				# end of: write80_data_prepare_data

#===============================================================================
sub write80_data_do {
    local ( $fh_out) = @_;
    local ( $seq_intmp, $i, $it2);
    $[=1;

#----------------------------------------------------------------------
#   write80_data_do             writes hssp seq + sec str + exposure
#                               (projected onto 1 digit) into 
#                               file with 80 characters per line
#----------------------------------------------------------------------
    $seq_intmp =  "$write80_data[1]";
    $seq_intmp =~ s/\s//g;
    if ( length($seq_intmp) != length($write80_data[1]) ) {
	print "*** ERROR in write_hssp_..: passed: sequence with spaces! \n";
	print "*** in: \t |$write80_data[1]| \n";
	exit;}

    for( $i=1; $i <= length($seq_intmp) ; $i += 80 ) {
	&myprt_points80 ($i);	
	print $fh_out "    $myprt_points80 \n";
	for ( $it2=1; $it2<=$#write80_data; $it2 ++) {
	    print $fh_out 
		"$write80_text[$it2]", "|", substr($write80_data[$it2],$i,80), "|\n";}}
}				# end of: write80_data_do

#===============================================================================
sub wrt_dssp_phd {
    local ($fhoutLoc,$id_in)=@_;
    local ($it);
    $[ =1 ;
#----------------------------------------------------------------------
#   wrt_dssp_phd                writes DSSP format for
#       in:                     $fhoutLoc,$id_in
#       in GLOBAL:              @NUM, @SEQ, @SEC(HE ), @ACC, @RISEC, @RIACC
#       out:                    1 if ok
#----------------------------------------------------------------------
    if (! defined @NUM || $#NUM == 0 || ! defined @SEQ || $#SEQ == 0 ||
	! defined @SEC || $#SEC == 0 || ! defined @ACC || $#ACC == 0 || 
	! defined @RISEC || $#RISEC == 0 || 
	! defined @RIACC || $#RIACC == 0 ) {
	print "*** ERROR in wrt_dssp_phd: not all arguments defined!!\n";
	print "*** missing NUM\n"   if (! defined @NUM || $#NUM == 0);
	print "*** missing SEQ\n"   if (! defined @SEQ || $#SEQ == 0 );
	print "*** missing SEC\n"   if (! defined @SEC || $#SEC == 0);
	print "*** missing ACC\n"   if (! defined @ACC || $#ACC == 0);
	print "*** missing RISEC\n" if (! defined @RISEC || $#RISEC == 0);
	print "*** missing RIACC\n" if (! defined @RIACC || $#RIACC == 0);
	return(0);}
	
    print $fhoutLoc 
	"**** SECONDARY STRUCTURE DEFINITION BY THE PROGRAM DSSP, here PHD prediction\n",
	"REFERENCE  ROST & SANDER,PROTEINS,19,1994,55-72; ".
	    "ROST & SANDER,PROTEINS,20,1994,216-26\n",
	    "HEADER     $id_in \n",
	    "COMPND        \n",
	    "SOURCE        \n",
	    "AUTHOR        \n",
	    "  \#  RESIDUE AA STRUCTURE BP1 BP2  ACC   N-H-->O  ".
		"O-->H-N  N-H-->O  O-->H-N    TCO  KAPPA ALPHA  PHI   ".
		    "PSI    X-CA   Y-CA   Z-CA  \n";
				# for security
    $CHAIN=" "                  if (! defined $CHAIN);
    for ($it=1; $it<=$#NUM; ++$it) {
	printf $fhoutLoc 
	    " %4d %4d %1s %1s  %1s           0   0  %3d    %1d  %1d\n",
	    $NUM[$it], $NUM[$it], $CHAIN, $SEQ[$it], $SEC[$it], 
	    $ACC[$it], $RISEC[$it], $RIACC[$it];}
    return(1);
}				# end wrt_dssp_phd

#===============================================================================
sub wrt_phd_header2pp {
    local ($file_out) = @_ ;
    local ($fhout,$header,@header);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   wrt_phd_header2pp           header for phd2pp
#       in:                     $file_out, i.e. file to write header to
#       out:                    @header
#-------------------------------------------------------------------------------
    $#header=0;
    push(@header,
	 "--- \n",
	 "--- ------------------------------------------------------------\n",
	 "--- PHD  profile based neural network predictions \n",
	 "--- ------------------------------------------------------------\n",
	 "--- \n");
    if ( (defined $file_out) && ($file_out ne "STDOUT") ) {
	$fhout="FHOUT_PHD_HEADER2PP";
	open($fhout, ">$file_out") || warn "Can't open '$file_out' (wrt_phd_header2pp)\n"; 
	foreach $header(@header){
	    print $fhout "$header";}
	close($fhout);}
    else {
	return(@header);}
}				# end of wrt_phd_header2pp

#===============================================================================
sub wrt_phd_rdb2col {
    local ($file_out,%rdrdb) = @_ ;
    local (@des,@des2,$fhout,$itdes,$it,%string,$subsec,$subacc,$points,
	   $des,$desout,$tmp,$tmpf,$dessec,$desacc,%Lok);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    wrt_phd_rdb2col             writes out the PP send format
#--------------------------------------------------------------------------------
    @des= ("AA","PSEC","RI_S","pH","pE","pL","PACC","PREL","RI_A","Pbie");
                                # ----------------------------------------
                                # first converting OtH (output) to prH (probability)
                                # ----------------------------------------
    $Lis_E=$Lis_H=0;
    foreach $it (1..$rdrdb{"NROWS"}){
	if (defined $rdrdb{"pH","$it"}) { $pH=$rdrdb{"pH","$it"}; $Lis_H=1;} else {$pH=0;}
	if (defined $rdrdb{"pE","$it"}) { $pE=$rdrdb{"pE","$it"}; $Lis_E=1;} else {$pE=0;}
	if (defined $rdrdb{"pL","$it"}) { $pL=$rdrdb{"pL","$it"}; }          else {$pL=0;}
	$sum=$pH+$pE+$pL; 
	if ($sum>0){
	    ($rdrdb{"pH","$it"},$tmp)=&get_min(9,int(10*$pH/$sum));
	    ($rdrdb{"pE","$it"},$tmp)=&get_min(9,int(10*$pE/$sum));
	    ($rdrdb{"pL","$it"},$tmp)=&get_min(9,int(10*$pL/$sum)); }
	else {
	    $rdrdb{"pH","$it"}=$rdrdb{"pE","$it"}=$rdrdb{"pL","$it"}=0;}}
    
				# ------------------------------
				# check whether or not all there
    foreach $des (@des) {
	if (defined $rdrdb{"$des","1"}) {$Lok{"$des"}=1;}
	else {$Lok{"$des"}=0;} }

    $fhout="FHOUT_PHD_RDB2COL";
    open($fhout, ">$file_out") || warn "Can't open '$file_out' (wrt_phd_rdb2col)\n"; 
				# ------------------------------
				# header
    print $fhout "--- \n";
    print $fhout "--- PHD PREDICTION COLUMN FORMAT HEADER: ABBREVIATIONS\n";
    if ($Lok{"AA"}){
	printf $fhout "--- %-10s: %-s\n","AA","one-letter code for amino acid sequence"; }
    if ($Lok{"PSEC"}){
	printf $fhout "--- %-10s: %-s\n","PSEC","secondary structure prediction in 3 states:";
	printf $fhout "--- %-10s: %-s\n","    ","H=helix, E=extended (sheet), L=rest (loop)";
	printf $fhout "--- %-10s: %-s\n","RI_S","reliability of secondary structure prediction";
	printf $fhout "--- %-10s: %-s\n","    ","scaled from 0 (low) to 9 (high)";
	printf $fhout "--- %-10s: %-s\n","pH  ","'probability' for assigning helix";
	printf $fhout "--- %-10s: %-s\n","pE  ","'probability' for assigning strand";
	printf $fhout "--- %-10s: %-s\n","pL  ","'probability' for assigning rest";
	printf $fhout "--- %-10s: %-s\n","       ",
	"Note:   the 'probabilities' are scaled onto 0-9,";
	printf $fhout "--- %-10s: %-s\n","       ",
	"        i.e., prH=5 means that the value of the";
	printf $fhout "--- %-10s: %-s\n","       ","        first output unit is 0.5-0.6"; }
	
    if ($Lok{"PACC"}){
	printf $fhout "--- %-10s: %-s\n","PACC",
	"predicted solvent accessibility in square Angstrom";
	printf $fhout "--- %-10s: %-s\n","PREL","relative solvent accessibility in percent";
	printf $fhout "--- %-10s: %-s\n","RI_A","reliability of accessibility prediction (0-9)";
	printf $fhout "--- %-10s: %-s\n","Pbie","predicted relative accessibility in 3 states:";
	printf $fhout "--- %-10s: %-s\n","       ","b=0-9%, i=9-36%, e=36-100%"; }

    print $fhout "--- \n","--- PHD PREDICTION COLUMN FORMAT \n";
				# --------------------------------------------------
				# now the prediction in 60 per line
				# --------------------------------------------------
    printf $fhout "%4s","No"; 
    foreach $des (@des){
	if ($Lok{"$des"}) { printf $fhout "%4s ",$des;} }
    print $fhout "\n"; 
    foreach $it (1..$rdrdb{"NROWS"}){
	printf $fhout "%4d",$it;
	foreach $des (@des){
	    if ($Lok{"$des"}) { printf $fhout "%4s ",$rdrdb{"$des","$it"}; } }
	print $fhout "\n" }
    print $fhout "--- \n","--- PHD PREDICTION COLUMN FORMAT END\n","--- \n";
    close($fhout);
}				# end of wrt_phd_rdb2col

#===============================================================================
sub wrt_phd_rdb2pp {
    local ($file_out,$cut_subsec,$cut_subacc,$sub_symbol,%rdrdb) = @_ ;
    local (@des,@des2,$fhout,$itdes,$it,%string,$subsec,$subacc,$points,
	   $des,$desout,$tmp,$tmpf,$dessec,$desacc);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    wrt_phd_rdb2pp             writes out the PP send format
#--------------------------------------------------------------------------------
    @des= ("AA","PHEL","RI_S","OtH","OtE","OtL","PACC","PREL","RI_A","Pbie");
    @des2=("AA","PHD", "Rel", "prH","prE","prL","PACC","PREL","RI_A","Pbie");

    $fhout="FHOUT_PHD_RDB2PP";
    open($fhout, ">$file_out") || warn "Can't open '$file_out' (wrt_phd_rdb2pp)\n"; 
				# ------------------------------
				# header
    @header=&wrt_phd_header2pp();
    foreach $header(@header){
	print $fhout "$header"; }
    print $fhout "--- PHD PREDICTION HEADER: ABBREVIATIONS\n";
    printf $fhout "--- %-10s: %-s\n","AA","one-letter code for amino acid sequence";
    printf $fhout "--- %-10s: %-s\n","PHD sec","secondary structure prediction in 3 states:";
    printf $fhout "--- %-10s: %-s\n","       ","H=helix, E=extended (sheet), blank=rest (loop)";
    printf $fhout "--- %-10s: %-s\n","Rel sec","reliability of secondary structure prediction";
    printf $fhout "--- %-10s: %-s\n","SUB sec","subset of residues for which the reliability";
    printf $fhout "--- %-10s: %-s\n","       ","index (Rel sec) is >= 5";
    printf $fhout "--- %-10s: %-s\n","       ","Note 1: this corresponds to an expected pre-";
    printf $fhout "--- %-10s: %-s\n","       ","        diction accuracy > 82% ";
    printf $fhout "--- %-10s: %-s\n","       ","Note 2: 'L': is loop (for which above ' ' is used)";
    printf $fhout "--- %-10s: %-s\n","       ","        '.': means no prediction is made for this";
    printf $fhout "--- %-10s: %-s\n","       ","             residue, i.e., Rel sec < 5";
    printf $fhout "--- %-10s: %-s\n","prH sec","'probability' for assigning helix";
    printf $fhout "--- %-10s: %-s\n","prE sec","'probability' for assigning strand";
    printf $fhout "--- %-10s: %-s\n","prL sec","'probability' for assigning rest";
    printf $fhout "--- %-10s: %-s\n","       ","Note:   the 'probabilities' are scaled onto 0-9,";
    printf $fhout "--- %-10s: %-s\n","       ","        i.e., prH=5 means that the value of the";
    printf $fhout "--- %-10s: %-s\n","       ","        first output unit is 0.5-0.6";
    printf $fhout "--- %-10s: %-s\n","P_3 acc","predicted relative accessibility in 3 states:";
    printf $fhout "--- %-10s: %-s\n","       ","b=0-9%, blank=9-36%, e=36-100%";
    printf $fhout "--- %-10s: %-s\n","PHD acc","predicted solvent accessibility in 10 states:";
    printf $fhout "--- %-10s: %-s\n","       ","acc=n implies a relative accessibility of n*n%";
    printf $fhout "--- %-10s: %-s\n","Rel acc","reliability of accessibility prediction (0-9)";
    printf $fhout "--- %-10s: %-s\n","SUB acc","subset of residues for which the reliability";
    printf $fhout "--- %-10s: %-s\n","       ","index (Rel acc) is >= 4";
    printf $fhout "--- %-10s: %-s\n","       ","Note 1: this corresponds to an expected corre-";
    printf $fhout "--- %-10s: %-s\n","       ","        lation coeeficient > 0.69 ";
    printf $fhout "--- %-10s: %-s\n","       ","Note 2: 'I': is intermediate (for which above a";
    printf $fhout "--- %-10s: %-s\n","       ","             blank ' ' is used)";
    printf $fhout "--- %-10s: %-s\n","       ","        '.': means no prediction is made for this";
    printf $fhout "--- %-10s: %-s\n","       ","             residue, i.e., Rel acc < 4";
    printf $fhout "--- %-10s: %-s\n","       ","";
    printf $fhout "--- %-10s: %-s\n","       ","";
    print $fhout "--- \n";
    print $fhout "--- PHD PREDICTION \n";
                                # ----------------------------------------
                                # first converting OtH (output) to prH (probability)
                                # ----------------------------------------
    foreach $it (1..$rdrdb{"NROWS"}){
	$sum=$rdrdb{"OtH","$it"}+$rdrdb{"OtE","$it"}+$rdrdb{"OtL","$it"};
	($rdrdb{"prH","$it"},$tmp)=&get_min(9,int(10*$rdrdb{"OtH","$it"}/$sum));
	($rdrdb{"prE","$it"},$tmp)=&get_min(9,int(10*$rdrdb{"OtE","$it"}/$sum));
	($rdrdb{"prL","$it"},$tmp)=&get_min(9,int(10*$rdrdb{"OtL","$it"}/$sum));
    }
				# --------------------------------------------------
				# now the prediction in 60 per line
				# --------------------------------------------------
    foreach $itdes (1..$#des){
	$string{"$des2[$itdes]"}="";
	foreach $it (1..$rdrdb{"NROWS"}){
	    if   ($des[$itdes]=~/PREL/){
		$string{"$des2[$itdes]"}.=
		    &exposure_project_1digit($rdrdb{"$des[$itdes]","$it"}); }
	    elsif($des[$itdes]=~/Ot/) {
		$desout=$des[$itdes];$desout=~s/Ot/pr/;
		$string{"$desout"}.=$rdrdb{"$desout","$it"}; }
	    else {
		$string{"$des2[$itdes]"}.=$rdrdb{"$des[$itdes]","$it"}; }
	}
    }
				# correct symbols
    $string{"PHD"}=~s/L/ /g;
    $string{"PSEC"}=~s/L/ /g;
    $string{"Pbie"}=~s/i/ /g;
				# select subsets
    $subsec=$subacc="";
    foreach $it (1..$rdrdb{"NROWS"}){
				# sec
	if ($rdrdb{"RI_S","$it"}>$cut_subsec){$subsec.=$rdrdb{"PSEC","$it"};}
	else{$subsec.="$sub_symbol";}
				# acc
	if ($rdrdb{"RI_A","$it"}>$cut_subacc){$subacc.=$rdrdb{"Pbie","$it"};}
	else {$subacc.="$sub_symbol";}
    }

    $tmp=$string{"AA"};$nres=length($tmp); # length

    for($it=1;$it<=$nres;$it+=60){
	$points=&myprt_npoints (60,$it);	
	printf $fhout "%-16s  %-60s\n"," ",$points;
				# residues
	$des="AA";$desout="AA     ";
	$tmp=substr($string{"$des"},$it,60);$tmpf=length($tmp)."s";
	printf $fhout "%8s %-6s |%-$tmpf|\n"," ","$desout",$tmp;
				# secondary structure
	foreach $dessec("PHD","Rel","prH","prE","prL"){
	    $desout="$dessec sec ";
	    $tmp=substr($string{"$dessec"},$it,60);$tmpf=length($tmp)."s";
	    printf $fhout "%8s %-6s|%-$tmpf|\n"," ","$desout",$tmp;
	    if ($dessec=~/Rel/){
		printf $fhout " detail:\n";
	    }
	}
	printf $fhout "%15s|%-$tmpf|\n"," subset: SUB sec ",$tmp;
	printf $fhout " \n";
				# accessibility
	printf $fhout " ACCESSIBILITY\n";
	foreach $desacc("Pbie","PREL","RI_A"){
	    if ($desacc=~/Pbie/)   {$desout=" 3st:    P_3 acc ";}
	    elsif ($desacc=~/PREL/){$desout=" 10st:   PHD acc ";}
	    elsif ($desacc=~/RI_A/){$desout="         Rel acc ";}
	    $tmp=substr($string{"$desacc"},$it,60);$tmpf=length($tmp)."s";
	    printf $fhout "%-15s|%-$tmpf|\n","$desout",$tmp; }
	$tmp=substr($subacc,$it,60);$tmpf=length($tmp)."s";
	printf $fhout "%15s|%-$tmpf|\n"," subset: SUB acc ",$tmp;
	printf $fhout " \n";}
    print $fhout "--- \n";
    print $fhout "--- PHD PREDICTION END\n";
    print $fhout "--- \n";
    close($fhout);
}				# end of wrt_phd_rdb2pp

#===============================================================================
sub wrt_phd2msf {
    local ($fileHssp,$fileMsfTmp,$filePhdRdb,$fileOut,$exeConvSeq,$LoptExpand,
	   $exePhd2Msf,$riSecLoc,$riAccLoc,$riSymLoc,$charPerLine,$Lscreen,$Lscreen2) = @_ ;
#    local ($fileLog);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   wrt_phd2msf                 converts HSSP to MSF and merges the PHD prediction
#                               into the MSF file (Pred + Ali)
#       in:                     * existing HSSP file, 
#                               * to be written temporary MSF file (hssp->MSF)
#                               * existing PHD.rdb_phd file
#                               * name of output file (id.msf_phd)
#                               * executables for converting HSSP to MSF (fortran convert_seq)
#                               * $Lexpand =1 means insertions in HSSP will be filled in
#                               * perl hack to convert id.rdb_phd + id.msf to id.msf_phd
#                               * reliability index to choose SUBSET for secondary structure
#                                 prediction (taken: > riSecLoc)
#                               * reliability index for SUBacc
#                               * character used to mark regions with ri <= riSecLoc
#                               * number of characters per line of MSF file
#       out:                    writes file and reports status (0,$text), or (1," ")
#--------------------------------------------------------------------------------
				# ------------------------------
				# security checks
    if (!-e $fileHssp){
	return(0,"HSSP file '$fileHssp' missing (wrt_phd2msf)");}
    if (!-e $filePhdRdb){
	return(0,"phdRdb file '$filePhdRdb' missing (wrt_phd2msf)");}
    if ($LoptExpand){
	$optExpand="expand";}else{$optExpand=" ";}
				# ------------------------------
				# convert HSSP file to MSF format
    if ($Lscreen){ 
	print "--- wrt_phd2msf \t ";
	print "'\&convHssp2msf($fileHssp,$fileMsfTmp,$exeConvSeq,$optExpand,$Lscreen2)'\n";}
    $Lok=
	&convHssp2msf($fileHssp,$fileMsfTmp,$exeConvSeq,$optExpand,$Lscreen2);
    if (!$Lok){
	return(0,"conversion Hssp2Msf failed '$fileMsfTmp' missing (wrt_phd2msf)");}
				# ------------------------------
				# now merge PHD file into MSF
    $arg=  "$fileMsfTmp filePhd=$filePhdRdb fileOut=$fileOut ";
    $arg.= " riSec=$riSecLoc riAcc=$riAccLoc riSym=$riSymLoc charPerLine=$charPerLine ";
    if ($Lscreen2){$arg.=" verbose ";}else{$arg.=" not_screen ";}

    if ($Lscreen) {print "--- wrt_phd2msf \t 'system ($exePhd2Msf $arg)'\n";}

    system("$exePhd2Msf $arg");
    return(1," ");
}				# end of wrt_phd2msf

#===============================================================================
sub wrt_phdpred_from_string {
    local ($fh,$nres_per_row,$mode,$Ldo_htmref,@des) = @_ ;
    local (@des_loc,@header_loc,$Lheader);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   wrt_phdpred_from_string     write body of PHD.pred files from global array %STRING{}
#       in (GLOBAL)             %STRING, i.e., one line string with prediction,
#                               e.g., $STRING{"osec"} observed secondary structure
#--------------------------------------------------------------------------------
    if (! %STRING) { 
	print "*** ERROR wrt_phdpred_from_string: associative array \%STRING must be global\n";
	exit; }
    $#des_loc=$#header_loc=0;$Lheader=0;
    foreach $des(@des){
	if ($des eq "header"){ 
	    $Lheader=1;
	    next;}
	if (! $Lheader){push(@des_loc,$des);}
	else           {push(@header_loc,$des);}}
				# get length of proteins (number of residues)
    $des= $des_loc[2];		# hopefully always AA!
    $tmp= $STRING{"$des"};
    $nres=length($tmp);
				# --------------------------------------------------
				# now write out for 'both','acc','sec'
				# --------------------------------------------------
    if ($mode=~/3|both|sec|acc/){
	$nres_tmp=$nres;}
    else {
	$nres_tmp=0;}
    for($it=1;$it<=$nres_tmp;$it+=$nres_per_row) {
	print  $fh " \n \n";	# print empty before each PHD block
	$tmp=&myprt_npoints($nres_per_row,$it);
	printf $fh "%-17s %-s\n"," ",$tmp;
	foreach $_ (@des_loc) {
	    next if (! defined $STRING{"$_"});
	    next if (length($STRING{"$_"})<$it);
	    $tmp=substr($STRING{"$_"},$it,$nres_per_row);
	    next if (length($tmp)==0) ;
				# secondary structure
	    if   ($_=~/aa/)    {printf $fh "%8s %-7s |%-s|\n"," ","AA ",$tmp; }
	    elsif($_=~/osec/)  {printf $fh "%8s %-7s |%-s|\n"," ","OBS sec",$tmp; }
	    elsif($_=~/psec/)  {printf $fh "%8s %-7s |%-s|\n"," ","PHD sec",$tmp; }
	    elsif($_=~/risec/) {printf $fh "%8s %-7s |%-s|\n"," ","Rel sec",$tmp; }
	    elsif($_=~/prHsec/){print  $fh " detail: \n";
				printf $fh "%8s %-7s |%-s|\n"," ","prH sec",$tmp; }
	    elsif($_=~/prEsec/){printf $fh "%8s %-7s |%-s|\n"," ","prE sec",$tmp; }
	    elsif($_=~/prLsec/){printf $fh "%8s %-7s |%-s|\n"," ","prL sec",$tmp; }
	    elsif($_=~/subsec/){printf $fh "%-8s %-7s |%-s|\n"," subset:","SUB sec",$tmp;}
				# solvent accessibility
	    elsif($_=~/obie/)  {if($mode=~/both|3/){print $fh " accessibility: \n"; }
				printf $fh "%-8s %-7s |%-s|\n"," 3st:","O_3 acc",$tmp;}
	    elsif($_=~/pbie/)  {if (length($STRING{"obie"})>1){$txt=" ";} 
				else{if($mode=~/both|3/){print $fh " accessibility \n";}
				     $txt=" 3st: ";}
				printf $fh "%-8s %-7s |%-s|\n",$txt,"P_3 acc",$tmp; }
	    elsif($_=~/oacc/)  {printf $fh "%-8s %-7s |%-s|\n"," 10st:","OBS acc",$tmp;}
	    elsif($_=~/pacc/)  {if (length($STRING{"oacc"})>1){$txt=" ";}else{$txt=" 10st: ";}
				printf $fh "%-8s %-7s |%-s|\n",$txt,"PHD acc",$tmp; }
	    elsif($_=~/riacc/) {printf $fh "%8s %-7s |%-s|\n"," ","Rel acc",$tmp; }
	    elsif($_=~/subacc/){printf $fh "%-8s %-7s |%-s|\n"," subset:","SUB acc",$tmp; }
	}
    }
				# --------------------------------------------------
				# now write out for '3','htm'
				# --------------------------------------------------
    if ($mode=~/3|htm/){
	if ($mode=~/3/) {
	    $symh="T";
	    print $fh 
		" \n",
		"************************************************************\n",
		"*    PHDhtm Helical transmembrane prediction\n",
		"*           note: PHDacc and PHDsec are reliable for water-\n",
		"*                 soluble globular proteins, only.  Thus, \n",
		"*                 please take the  predictions above with \n",
		"*                 particular caution wherever transmembrane\n",
		"*                 helices are predicted by PHDhtm!\n",
		"************************************************************\n",
		" \n",
		" PHDhtm\n";
	} else {
	    $symh="H";}
	$nres_tmp=$nres;}
    else {
	$nres_tmp=0;}
				# ------------------------------
				# print header for topology asf
    if ($nres_tmp>0){
	if ($#header_loc>0){
	    &wrt_phdpred_from_string_htm_header($fh,@header_loc);}
	&wrt_phdpred_from_string_htm($fh,$nres_tmp,$nres_per_row,$symh,
				     $Ldo_htmref,@des_loc);}
}				# end of wrt_phdpred_from_string

#===============================================================================
sub wrt_phdpred_from_string_htm {
    local ($fh,$nres_tmp,$nres_per_row,$symh,$Ldo_htmref,@des_loc) = @_ ;
    local ($it,$tmp);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   wrt_phdpred_from_string_htm body of PHD.pred files from global array %STRING{} for HTM
#       in (GLOBAL)             %STRING, i.e., one line string with prediction,
#                               e.g., $STRING{"osec"} observed secondary structure
#--------------------------------------------------------------------------------
    @des=("AA");
    if (defined $STRING{"ohtm"}){
	$tmp=$STRING{"ohtm"}; $tmp=~s/L|\s//g;
	if (length($tmp)==0) {
	    $STRING{"ohtm"}="";}
	else {
	    push(@des,"OBS htm");}}
    push(@des,"PHD htm","Rel htm","detail","prH htm","prL htm",
	      "subset","SUB htm","other","PHDFhtm");
    if (defined $STRING{"prhtm"}){ push(@des,"PHDRhtm");}
    if (defined $STRING{"pthtm"}){ push(@des,"PHDThtm");}
    $sym{"AA"}=     "amino acid in one-letter code";
    $sym{"OBS htm"}="HTM's observed ($symh=HTM, ' '=not HTM)";
    $sym{"PHD htm"}="HTM's predicted by the PHD neural network\n".
	"---                system ($symh=HTM, ' '=not HTM)";
    $sym{"Rel htm"}="Reliability index of prediction (0-9, 0 is low)";
    $sym{"detail"}= "Neural network output in detail";
    $sym{"prH htm"}="'Probability' for assigning a helical trans-\n".
	"---                membrane region (HTM)";
    $sym{"prL htm"}="'Probability' for assigning a non-HTM region\n".
	"---          note: 'Probabilites' are scaled to the interval\n".
	"---                0-9, e.g., prH=5 means, that the first \n".
	"---                output node is 0.5-0.6";
    $sym{"subset"}= "Subset of more reliable predictions";
    $sym{"SUB htm"}="All residues for which the expected average\n".
	"---                accuracy is > 82% (tables in header).\n".
	"---          note: for this subset the following symbols are used:\n".
	"---             L: is loop (for which above ' ' is used)\n".
	"---           '.': means that no prediction is made for this,\n".
	"---                residue as the reliability is:  Rel < 5";
    $sym{"other"}=  "predictions derived based on PHDhtm";
    $sym{"PHDFhtm"}="filtered prediction, i.e., too long HTM's are\n".
	"---                split, too short ones are deleted";
    $sym{"PHDRhtm"}="refinement of neural network output ";
    $sym{"PHDThtm"}="topology prediction based on refined model\n".
	"---                symbols used:\n".
	"---             i: intra-cytoplasmic\n".
	"---             T: transmembrane region\n".
	"---             o: extra-cytoplasmic";
				# write symbols
    if ($Ldo_htmref) {
	print $fh "--- \n--- PhdTopology REFINEMENT AND TOPOLOGY PREDICTION: SYMBOLS\n";
	foreach $des(@des){
	    printf $fh "--- %-13s: %-s\n",$des,$sym{"$des"};}
	print $fh "--- \n--- PhdTopology REFINEMENT AND TOPOLOGY PREDICTION\n";}
    for($it=1;$it<=$nres_tmp;$it+=$nres_per_row) {
	$tmp=&myprt_npoints($nres_per_row,$it);
	printf $fh "%-17s %-s\n"," ",$tmp;
	foreach $_ (@des_loc) {
	    next if (length($STRING{"$_"})<$it);
	    $tmp=substr($STRING{"$_"},$it,$nres_per_row);
	    next if ((! defined $tmp) || (length($tmp)==0));
#	    $format="%-".length($tmp)."s";$len=length($tmp);
				# helical transmembrane regions
	    if   ($_=~/aa/)    {printf $fh "%8s %-7s |%-s|\n"," ","AA ",$tmp; }
	    elsif($_=~/ohtm/)  {printf $fh "%8s %-7s |%-s|\n"," ","OBS htm",$tmp; }
	    elsif($_=~/phtm/)  {printf $fh "%8s %-7s |%-s|\n"," ","PHD htm",$tmp; }
	    elsif($_=~/pfhtm/) {printf $fh "%8s %-7s |%-s|\n"," ","other"," "; 
				printf $fh "%8s %-7s |%-s|\n"," ","PHDFhtm",$tmp; }
	    elsif($_=~/rihtm/) {printf $fh "%8s %-7s |%-s|\n"," ","Rel htm",$tmp; }
	    elsif($_=~/prHhtm/){print  $fh " detail: \n";
				printf $fh "%8s %-7s |%-s|\n"," ","prH htm",$tmp; }
	    elsif($_=~/prLhtm/){printf $fh "%8s %-7s |%-s|\n"," ","prL htm",$tmp; }
	    elsif($_=~/subhtm/){printf $fh "%-8s %-7s |%-s|\n"," subset:","SUB htm",$tmp;}

	    elsif($_=~/prhtm/) {printf $fh "%8s %-7s |%-s|\n"," ","PHDRhtm",$tmp; }
	    elsif($_=~/pthtm/) {printf $fh "%8s %-7s |%-s|\n"," ","PHDThtm",$tmp; }}}
    if ($Ldo_htmref) {
	print $fh
	    "--- \n",
	    "--- PhdTopology REFINEMENT AND TOPOLOGY PREDICTION END\n",
	    "--- \n";}
}				# end of wrt_phdpred_from_string

#===============================================================================
sub wrt_phdpred_from_string_htm_header {&wrt_phdpred_from_string_htmHdr(@_);} # alias

#===============================================================================
sub wrt_phdpred_from_string_htmHdr {
    local ($fh,@header) = @_ ;
    local ($header,$header_txt,$des,%txt,@des,%dat);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   wrt_phdpred_from_string_htmHdr writes the header for PHDhtm ref and top
#       in: header with (x1:x2), where x1 is the key and x2 the result
#--------------------------------------------------------------------------------
				# define notations
    $txt{"NHTM_BEST"}=     "number of transmembrane helices best model";
    $txt{"NHTM_2ND_BEST"}= "number of transmembrane helices 2nd best model";
    $txt{"REL_BEST_DPROJ"}="reliability of best model (0 is low, 9 high)";
    $txt{"MODEL"}=         "";
    $txt{"MODEL_DAT"}=     "";
    $txt{"HTMTOP_PRD"}=    "topology predicted ('in': intra-cytoplasmic)";
    $txt{"HTMTOP_RID"}=    "difference between positive charges";
    $txt{"HTMTOP_RIP"}=    "reliability of topology prediction (0-9)";
    $txt{"MOD_NHTM"}=      "number of transmembrane helices of model";
    $txt{"MOD_STOT"}=      "score for all residues";
    $txt{"MOD_SHTM"}=      "score for HTM added at current iteration step";
    $txt{"MOD_N-C"}=       "N  -  C  term of HTM added at current step";
    print  $fh			# first write header
	"--- \n",
	"--- ", "-" x 60, "\n",
	"--- PhdTopology prediction of transmembrane helices and topology\n",
	"--- ", "-" x 60, "\n",
	"--- \n",
	"--- PhdTopology REFINEMENT AND TOPOLOGY HEADER: ABBREVIATIONS\n",
	"--- \n";
				# ------------------------------
    $#des=0;			# extracting info
    foreach $header (@header_loc){
	($des,$header_txt)=split(/:/,$header);
	if ($des !~ /MODEL/){
	    push(@des,$des);
	    $dat{"$des"}=$header_txt;}}
				# writing notation
    foreach $des (@des,"MOD_NHTM","MOD_STOT","MOD_SHTM","MOD_N-C"){
	if ($des eq "MODEL_DAT") { # skip
	    next;}
	$tmp_des=$des;$tmp_des=~s/\_DPROJ//g;$tmp_des=~s/\s//g;
	printf $fh "--- %-13s: %-s\n",$tmp_des,$txt{"$des"};}
				# explaining algorithm
    print $fh 
	"--- \n",
	"--- ALGORITHM REF: The refinement is performed by a dynamic pro-\n",
	"--- ALGORITHM    : gramming-like procedure: iteratively the best\n",
	"--- ALGORITHM    : transmembrane helix (HTM) compatible with the\n",
	"--- ALGORITHM    : network output is added (starting from the  0\n",
	"--- ALGORITHM    : assumption, i.e.,  no HTM's  in the protein).\n",
	"--- ALGORITHM TOP: Topology is predicted by the  positive-inside\n",
	"--- ALGORITHM    : rule, i.e., the positive charges are compiled\n",
	"--- ALGORITHM    : separately  for all even and all odd  non-HTM\n",
	"--- ALGORITHM    : regions.  If the difference (charge even-odd)\n",
	"--- ALGORITHM    : is < 0, topology is predicted as 'in'.   That\n",
	"--- ALGORITHM    : means, the protein N-term starts on the intra\n",
	"--- ALGORITHM    : cytoplasmic side.\n",
	"--- \n";
    print $fh
	"--- PhdTopology REFINEMENT HEADER: SUMMARY\n";
				# writing info: first iteration
    printf $fh 
	" %-8s %-8s %-8s %-s \n","MOD_NHTM","MOD_STOT","MOD_SHTM","MOD_N-C";
    foreach $header (@header_loc){
	if ($header =~ /^MODEL_DAT/){
	    ($des,$header_txt)=split(/:/,$header);
	    @tmp=split(/,/,$header_txt);
	    printf $fh " %8d %8.3f %8.3f %-s\n",@tmp;}}
    print $fh
	"--- \n",
	"--- PhdTopology REFINEMENT AND TOPOLOGY HEADER: SUMMARY\n";
    foreach $des (@des){	# writing info: now rest
	if ($des ne "MODEL_DAT"){
	    $tmp_des=$des;$tmp_des=~s/_DPROJ|\s//g;
	    printf $fh "--- %-13s: %-s\n",$tmp_des,$dat{"$des"};}}
}				# end of wrt_phdpred_from_string_htmHdr

#===============================================================================
sub wrt_ppcol {
    local ($fhoutLoc,%rd)= @_ ;
    local (@des,$ct,$tmp,@tmp,$sep,$des,$des_tmp);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   wrt_ppcol                   writes out the PP column format
#       in:                     $fhoutLoc,%rd
#       out:                    1 or 0
#--------------------------------------------------------------------------------
    return(0,"error rd(des) not defined") if ( ! defined $rd{"des"});
    $tmp=$rd{"des"}; $tmp=~s/^\s*|\s*$//g; # purge leading blanks
    @des=split(/\s+/,$tmp);
    $sep="\t";                  # separator
				# ------------------------------
				# header
    print $fhoutLoc "# PP column format\n";
				# ------------------------------
    foreach $des (@des) {	# descriptor
	if ($des ne $des[$#des]) { 
	    print $fhoutLoc "$des$sep";}
	else {
	    print $fhoutLoc "$des\n";} }
				# ------------------------------
    $des_tmp=$des[1];		# now the prediction in 60 per line
    $ct=1;
    while (defined $rd{"$des_tmp","$ct"}) {
	foreach $des (@des) {
	    if ($des ne $des[$#des]) { 
		print $fhoutLoc $rd{"$des","$ct"},"$sep";}
	    else {
		print $fhoutLoc $rd{"$des","$ct"},"\n";}  }
	++$ct; }
    return(1,"ok");
}				# end of wrt_ppcol

#===============================================================================
sub wrt_strip_pp2 {
    local ($file_in,@strip) = @_ ;
    local ($fhout,$Lwatch,$Lrest,$strip,$it);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    wrt_strip_pp2              writes the final PP output file
#--------------------------------------------------------------------------------
    $fhout="FHOUT_STRIP_TOPITS";
    open($fhout, ">$file_in") || warn "Can't open '$file_in' (wrt_strip_pp2. lib-pp.pl)\n"; 
    $Lwatch=$Lrest=0;
    foreach $strip (@strip) {
	if ( $Lrest ) {
	    print $fhout "$strip\n"; }
	elsif ( $Lwatch && ($strip=~/^---/) ){
	    print $fhout "--- \n";
	    print $fhout "--- TOPITS ALIGNMENTS HEADER: PDB_POSITIONS FOR ALIGNED PAIR\n";
	    printf 
		$fhout "%5s %4s %4s %4s %4s %4s %4s %4s %-6s\n",
		"RANK","PIDE","IFIR","ILAS","JFIR","JLAS","LALI","LEN2","ID2";
	    foreach $it (1 .. $rd_hssp{"nali"}){
		printf 
		    $fhout "%5d %4d %4d %4d %4d %4d %4d %4d %-6s\n",
		    $it,int(100*$rd_hssp{"ide","$it"}),
		    $rd_hssp{"ifir","$it"},$rd_hssp{"ilas","$it"},
		    $rd_hssp{"jfir","$it"},$rd_hssp{"jlas","$it"},
		    $rd_hssp{"lali","$it"},$rd_hssp{"len2","$it"},
		    $rd_hssp{"id2","$it"};
	    }
	    $Lrest=1; 
	    print $fhout "$strip\n"; }
	elsif ($strip =~ /^--- .* SUMMARY/){ 
	    $Lwatch=1; 
	    print $fhout "$strip\n"; }
	elsif ($strip =~ /^--- NAME2/) { # abbreviations
	    print $fhout "$strip\n";
	    print $fhout "--- IFIR         : position of first residue of search sequence\n";
	    print $fhout "--- ILAS         : position of last residue of search sequence\n";
	    print $fhout "--- JFIR         : PDB position of first residue of remote homologue\n";
	    print $fhout "--- JLAS         : PDB position of last residue of remote homologue\n";
	} else {
	    print $fhout "$strip\n"; }
    }
    close($fhout);
}				# end of wrt_strip_pp2

#===============================================================================
sub wrtHsspHeaderTopBlabla {
    local ($fhoutLoc,$preLoc,$txtMode,$Lzscore,$Lenergy,$Lifir)=@_;
    $[ =1 ;
#--------------------------------------------------------------------------------
#   wrtHsspHeaderTopBlabla      writes header for HSSP RDB (or simlar) output file
#       in:                     $fhoutLoc,$preLoc,$txtMode,$Lzscore,$Lenergy,$Lifir
#         $fhErrSbr             FILE-HANDLE to report errors
#         $fhoutLoc             file handle print output
#         $preLoc               first letters to write
#         $txtMode = 'RDB'      write RDB file, note: by default #
#         $Lzscore              write zscore description
#         $Lenergy              write energy description
#         $Lifir                write ifir,ilas,jfir,jlas description
#--------------------------------------------------------------------------------
    if (defined $txtMode && ($txtMode  =~ /^rdb$/i)){
	$preLoc="\#".$preLoc;}

    print $fhoutLoc
	"$preLoc","------------------------------------------------------------\n",
	"$preLoc","MAXHOM multiple sequence alignment\n",
	"$preLoc","------------------------------------------------------------\n",
	"$preLoc","\n",
	"$preLoc","MAXHOM ALIGNMENT HEADER: ABBREVIATIONS FOR SUMMARY\n",
	"$preLoc","ID1          : identifier of guide (or search) protein\n",
	"$preLoc","ID2          : identifier of aligned (homologous) protein\n",
	"$preLoc","STRID        : PDB identifier (only for known structures)\n",
	"$preLoc","PIDE         : percentage of pairwise sequence identity\n",
	"$preLoc","WSIM         : percentage of weighted similarity\n";
    if ($Lenergy){		# use energy?
	print $fhoutLoc
	    "$preLoc","ENERGY       : value from Smith-Waterman algorithm\n";}
    if ($Lzscore){		# use zscore? 
	print $fhoutLoc
	    "$preLoc","ZSCORE       : zscore compiled from ENERGY\n";}
    print $fhoutLoc		# general points
	"$preLoc","LALI         : number of residues aligned\n",
	"$preLoc","LEN1         : length of guide (or search) sequence\n",
	"$preLoc","LEN2         : length of aligned sequence\n",
	"$preLoc","NGAP         : number of insertions and deletions (indels)\n",
	"$preLoc","LGAP         : number of residues in all indels\n";
    if ($Lifir){		# print beg and end of both sequences
	print $fhoutLoc
	    "$preLoc","IFIR         : position of first residue of search sequence\n",
	    "$preLoc","ILAS         : position of last residue of search sequence\n",
	    "$preLoc","JFIR         : PDB position of first residue of remote homologue\n",
	    "$preLoc","JLAS         : PDB position of last residue of remote homologue\n";}
    print $fhoutLoc
	"$preLoc","ACCNUM       : SwissProt accession number\n",
	"$preLoc","NAME         : one-line description of aligned protein\n",
	"$preLoc","\n";
}				# end of wrtHsspHeaderTopBlabla

#===============================================================================
sub wrtHsspHeaderTopData {
    local ($fhoutLoc,$preLoc,$txtMode,@dataLoc)=@_;
    $[ =1 ;
#--------------------------------------------------------------------------------
#  wrtHsspHeaderTopData         write DATA for new header of HSSP (or simlar)
#       in:                     $fhoutLoc,$prexLoc,$txtMode,@data:List:($kwd,$val)
#         $fhoutLoc             file handle print output
#         $preLoc               first letters to write
#         $txtMode = 'RDB'      write RDB file, note: by default #
#--------------------------------------------------------------------------------
    if (defined $txtMode && ($txtMode  =~ /^rdb$/i)){
	$preLoc="\#".$preLoc;}

    print $fhoutLoc
	"$preLoc","MAXHOM ALIGNMENT HEADER: INFORMATION ABOUT GUIDE SEQUENCE\n";
    while ($#dataLoc){
	$kwd=shift @dataLoc; $kwd=~tr/[a-z]/[A-Z]/;
	$val=shift @dataLoc;
	if ($kwd =~/^PARA/){@tmp=split(/\t/,$val);}else{@tmp=("$val");}
	foreach $tmp(@tmp){
	    printf $fhoutLoc "$preLoc"."%-12s : %-s\n",$kwd,$tmp;}}
    print $fhoutLoc
	"$preLoc","\n";
}				# end of wrtHsspHeaderTopData

#===============================================================================
sub wrtHsspHeaderTopFirstLine {
    local ($fhoutLoc,$preLoc,$txtMode)=@_;
    $[ =1 ;
#--------------------------------------------------------------------------------
#   wrtHsspHeaderTopFirstLine   writes first line for HSSP+STRIP header (perl-rdb)
#       in:                     $fhoutLoc,$txtMode
#         $fhoutLoc             file handle print output
#         $txtMode = 'RDB'      write RDB file, note: by default #
#--------------------------------------------------------------------------------
    if (defined $txtMode && ($txtMode =~ /^rdb$/i)){
	print $fhoutLoc 
	    "\# Perl-RDB      (HSSP_STRIP_MERGER)\n",
	    "\# \n";}
}				# end of wrtHsspHeaderTopFirstLine

#===============================================================================
sub wrtHsspHeaderTopLastLine {
    local ($fhoutLoc,$preLoc,$txtMode,@dataLoc)=@_;
    $[ =1 ;
#--------------------------------------------------------------------------------
#   wrtHsspHeaderTopLastLine    writes last line for top of header (to recognise next)
#       in:                     $fhoutLoc,$preLoc,$txtMode
#         $fhoutLoc             file handle print output
#         $preLoc               first letters to write
#         $txtMode = 'RDB'      write RDB file, note: by default #
#--------------------------------------------------------------------------------
    if (defined $txtMode && ($txtMode  =~ /^rdb$/i)){
	$preLoc="\#".$preLoc;}

    print $fhoutLoc
	"$preLoc","MAXHOM ALIGNMENT HEADER: INFORMATION ABOUT GUIDE SEQUENCE\n";
}				# end of wrtHsspTopLastLine

1;
