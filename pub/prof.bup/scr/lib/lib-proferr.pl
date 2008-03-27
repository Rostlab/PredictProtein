#!/usr/bin/perl
##!/usr/bin/perl -w
#------------------------------------------------------------------------------#
#	Copyright				Sep,    	1998	       #
#	Burkhard Rost		rost@LION-ag.de,rost@EMBL-heidelberg.de	       #
#	Wilckensstr. 15		http://www.embl-heidelberg.de/~rost/	       #
#	D-69120 Heidelberg						       #
#				version 0.1   	Sep,    	1998	       #
#				version 0.2   	Oct,    	1998	       #
#				version 0.3   	Dec,    	1999	       #
#				version 0.4   	Feb,    	2000	       #
#------------------------------------------------------------------------------#
#                                                                              #
# description:                                                                 #
#    PERL library with routines related to compiling prediction error.         #
#    Note: is very rudimentary!                                                #
#                                                                              #
#------------------------------------------------------------------------------#
# 
# 

#===============================================================================
sub accSecInfo {
    local($nstateLoc,%mat) = @_ ;
    local($sbrName,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   accSecInfo                  compiles information index for
#                               secondary structure prediction:
#                               B Rost & C Sander (1993) JMB, 232, 584-599
#                               
#                               formula:
#                               
#    
#            SUM/i,1-3[PRDi*ln(PRDi)] - SUM/ij [Aij * ln Aij]
#    I = 1 - ------------------------------------------------
#                NRES*ln(NRES) - SUM/i [OBSi*ln(OBSi)
#    
#                               with:
#                               PRDi = number of residues predicted in state i
#                               OBSi = number of residues observed in state i
#                               NRES = number of residues (protein length)
#                               
#                               note: I%obs and I%prd (PRD <-> OBS for the later)
#                               
#                               
#       in:                     $nstateLoc: number of states
#       in:                     %mat{i,j}:  number of residues observed in i, predicted in j
#                               $mat{"nres"}= sum /ij MATij
#                               
#       out:                    1|0,msg,@info(1..$nstateLoc)
#			                info[1]=%obs info[2]=%prd
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."accSecInfo";
				# check arguments
    return(&errSbr("not def nstateLoc!"))                if (! defined $nstateLoc);
    return(&errSbr("not def mat!"))                      if (! defined %mat);
    return(&errSbr("not def mat{nres}!"))                if (! defined $mat{"nres"});
    return(&errSbr("mat{nres}=".$mat{"nres"}."no num!")) if ($mat{"nres"}=~/\D/);
    return(&errSbr("mat{nres} <=0!"))                    if ($mat{"nres"} <= 0);

				# set zero
    $#sumobs=$#sumprd=0;
    foreach $it (1..$nstateLoc){
	$sumobs[$it]=$sumprd[$it]=0;
    }
				# general sums
    foreach $itobs (1..$nstateLoc){
	foreach $itprd (1..$nstateLoc){
	    $sumobs[$itobs]+=$mat{$itobs,$itprd};
	    $sumprd[$itprd]+=$mat{$itobs,$itprd}; }}

				# nres * ln(nres)
    $prod_nres=0;
    $prod_nres=$mat{"nres"} * log ($mat{"nres"}) if ($mat{"nres"} > 0);

				# SUM/i OBSi*ln(OBSi)
				# SUM/i PRDi*ln(PRDi)
    $prod_sumobs=$prod_sumprd=0;
    foreach $it (1..$nstateLoc){
	$prod_sumobs+=$sumobs[$it] * log ($sumobs[$it]) if ($sumobs[$it] > 0);
	$prod_sumprd+=$sumprd[$it] * log ($sumprd[$it]) if ($sumprd[$it] > 0); }

				# SUM/ij Aij * ln Aij
    $prod_aij=0;
    foreach $itobs (1..$nstateLoc){
	foreach $itprd (1..$nstateLoc){
	    $prod_aij+=$mat{$itobs,$itprd} * log ($mat{$itobs,$itprd}) if ($mat{$itobs,$itprd} > 0);
	}}
				# --------------------------------------------------
				# now info info[1]=%obs info[2]=%prd
				# --------------------------------------------------
    $divide_obs=$prod_nres - $prod_sumobs;
    $divide_prd=$prod_nres - $prod_sumprd;
    $info[1]=$info[2]=0;
    $info[1]=1- ($prod_sumprd - $prod_aij) / $divide_obs if ($divide_obs > 0);
    $info[2]=1- ($prod_sumobs - $prod_aij) / $divide_prd if ($divide_prd > 0);
    return(1,"ok $sbrName",@info);
}				# end of accSecInfo

#===============================================================================
sub accSecMatthews {
    local($nstateLoc,%mat) = @_ ;
    local($sbrName,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   accSecMatthews              compiles Matthews correlation for secondary
#                               structure prediction:
#                               B W Matthews (1975) Biochim. Biophys. Acta 405, 442-451
#                               
#                               formula:
#                               
#                                          p(i)*n(i) - u(i)*o(i)
#                c(i) = -------------------------------------------------------
#                       sqrt{ (p(i)+u(i))*(p(i)+o(i))*(n(i)+u(i))*(n(i)+o(i)) }
#                               
#                               
#       in:                     $nstateLoc:      number of states
#       in:                     %mat{i,j}:       number of residues observed in i, predicted in j
#                               
#       out:                    1|0,msg,@matthews(1..$nstateLoc)
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."accSecMatthews";
				# check arguments
    return(&errSbr("not def nstateLoc!"))        if (! defined $nstateLoc);
    return(&errSbr("not def mat!"))         if (! defined %mat);

				# p(i): true positives (correctly predicted in state i)
    foreach $it (1..$nstateLoc){
	$p[$it]=$mat{$it,$it}; }
				# n(i): true negatives (correctly predicted NOT in state i)
    foreach $it (1..$nstateLoc){
	$n[$it]=0;
	foreach $itobs (1..$nstateLoc){
	    next if ($itobs==$it);
	    foreach $itprd (1..$nstateLoc){
		next if ($itprd==$it);
		$n[$it]+=$mat{$itobs,$itprd};}}}
				# u(i): underpredicted (observed in i, predicted in i ne j)
    foreach $it (1..$nstateLoc){
	$u[$it]=0;
	foreach $itprd (1..$nstateLoc){
	    next if ($itprd==$it);
	    $u[$it]+=$mat{$it,$itprd};}}
				# o(i): overpredicted (obs in j ne i, prd in i)
    foreach $it (1..$nstateLoc){
	$o[$it]=0;
	foreach $itobs (1..$nstateLoc){
	    next if ($itobs==$it);
	    $o[$it]+=$mat{$itobs,$it};}}
				# ------------------------------
				# now get correlation indices
				# ------------------------------
    $#matthews=0;
    foreach $it (1..$nstateLoc){
	$sum= ($p[$it]+$u[$it])*($p[$it]+$o[$it])*($n[$it]+$u[$it])*($n[$it]+$o[$it]);
	if    ($p[$it]==0 && $sum==0){
	    $matthews[$it]=1;}
	elsif ($sum==0){
	    $matthews[$it]=0;}
	else {
	    $matthews[$it]=$p[$it]*$n[$it] - $u[$it]*$o[$it];
	    $matthews[$it]=$matthews[$it] / sqrt($sum);}
    }
    return(1,"ok $sbrName",@matthews);
}				# end of accSecMatthews

#===============================================================================
sub convert_secFine {
    local ($sec,$char) = @_ ;
#--------------------------------------------------------------------------------
#    convert_secFine            takes an entire string ('HEL') and fine-tunes: ' EHH'-> '  HH'
#                               char=HL    -> H=H,I,G  L=rest
#                               char=EL    -> E=E,B    L=rest
#                               char=TL    -> T=T, single B  L=rest
#                               char=HELB  -> H=H,I,G  E=E, B=B, L=rest
#                               char=HELT  -> H=H,I,G  E=E,B  T=T, L=rest
#                               char=HELBT -> H=H,I,G  E=E, B=B, T=T, L=rest
#         default =             HEL
#         in:                   structure-string to convert
#         out:                  (1|0,$msg,converted)
#--------------------------------------------------------------------------------
    $sbrName="lib-prot:"."convert_secFine";
				# default
    $char="HEL"                 if (! defined $char || ! $char);
				# unused
    if    ($char eq "HL")     { $sec=~s/[IG]/H/g;  $sec=~s/[EBTS !]/L/g;
				return(1,"ok",$sec); }
    elsif ($char eq "EL")     { $sec=~s/[EB]/E/g;  $sec=~s/[HIGTS !]/L/g;
				return(1,"ok",$sec); }
    elsif ($char eq "TL")     { $sec=~s/[^B]B[^B]/T/g; 
				$sec=~s/[^T]/L/g;
				return(1,"ok",$sec); }
    elsif ($char eq "HEL")    { $sec=~s/[IG]/H/g;  $sec=~s/[TS !]/L/g;
				$sec=~s/B/E/g;
				$sec=~s/LEH/LLH/g; $sec=~s/HEL/HLL/g; # <-- fine
				return(1,"ok",$sec); }
    elsif ($char eq "HELT")   { $sec=~s/[IG]/H/g;  $sec=~s/[S !]/L/g;
				$sec=~s/B/E/g;
				$sec=~s/LEH/LLH/g; $sec=~s/HEL/HLL/g; # <-- fine
				return(1,"ok",$sec); }
    elsif ($char eq "HELB")   { $sec=~s/[IG]/H/g;  $sec=~s/[TS !]/L/g;
				return(1,"ok",$sec); }
    elsif ($char eq "HELBT")  { $sec=~s/[IG]/H/g;  $sec=~s/[S !]/L/g;
				return(1,"ok",$sec); }
    elsif ($char eq "Hcap")   { $sec=~s/[IG]/H/g;
				$sec=~s/[^H]HH[^H]/LLLL/g;    # too short (< 3)
				$sec=~s/^HH[^H]/LLL/g;        # too short (< 3)
				$sec=~s/[^H]HH$/LLL/g;        # too short (< 3)
				$sec=~s/[^H]H(H+)/Ln$1/g;     # N-cap -> 'n'
				$sec=~s/([nH]H+)H[^H]/$1cL/g; # C-cap -> 'c'
				$sec=~s/[^ncH]/L/g;           # others -> L
				$sec=~s/(Hc)(L+)c/$1$2u/g;    # correct 'cLLc'
				$sec=~s/n(L+n)/u$1/g;         # correct 'nLLn'
				return(1,"ok",$sec); }
    elsif ($char eq "Ecap")   { $sec=~s/B/E/g;
				$sec=~s/[^E]E[^E]/LLL/g;      # too short (< 2)
				$sec=~s/^E[^E]/LL/g;          # too short (< 2)
				$sec=~s/[^E]E$/LL/g;          # too short (< 2)
				$sec=~s/[^E]E(E+)/Ln$1/g;     # N-cap -> 'n'
				$sec=~s/([nE]E*)E[^E]/$1cL/g; # C-cap -> 'c'
				$sec=~s/[^ncE]/L/g;           # others -> L
				$sec=~s/(Ec)(L+)c/$1$2u/g;    # correct 'cLLc'
				$sec=~s/n(L+n)/u$1/g;         # correct 'nLLn'
				return(1,"ok",$sec); }
    elsif ($char eq "HEcap")  { $sec=~s/B/E/g;
				$sec=~s/[IG]/H/g;
				$sec=~s/[^HE]/L/g;               # nonH, nonE -> L

				$sec=~s/([^H])HH([^H])/$1LL$2/g; # too short (< 3)
				$sec=~s/^HH([^H])/LL$1/g;        # too short (< 3)
				$sec=~s/([^H])HH$/$1LL/g;        # too short (< 3)

				$sec=~s/([^E])E([^E])/$1L$2/g;   # too short (< 2)
				$sec=~s/^E([^E])/L$1/g;          # too short (< 2)
				$sec=~s/([^E])E$/$1L/g;          # too short (< 2)

				$sec=~s/([^H])H(H+)/$1n$2/g;     # N-cap H -> 'n'
				$sec=~s/([nH]H+)H([^H])/$1c$2/g; # C-cap H -> 'c'

				$sec=~s/([^E])E(E+)/$1n$2/g;     # N-cap E -> 'n'
				$sec=~s/([nE]E*)E([^E])/$1c$2/g; # C-cap E -> 'c'

				$sec=~s/([EH]c)(L+)c/$1$2u/g;    # correct 'cLLc'
				$sec=~s/n(L+n)/u$1/g;            # correct 'nLLn'
				return(1,"ok",$sec); }
    else { 
	return(&errSbr("char=$char, not recognised\n")); }
}				# end of convert_secFine

#================================================================================
sub correlation {
    local($ncol, @data) = @_;
    local($it, $av1, $av2, $av11, $av22, $av12);
    local(@v1,@v2,@v11,@v12,@v22, $den, $dentmp, $nom);
    $[ =1;
#----------------------------------------------------------------------
#   correlation                 compiles the correlation between x and y
#       in:                     ncol,@data, where $data[1..ncol] =@x, rest @y
#       out:                    returned $COR=correlation
#       out GLOBAL:             COR, AVE, VAR
#----------------------------------------------------------------------

    $#v1=0;$#v2=0;
    for ($it=1;$it<=$#data;++$it) {
	if ($it<=$ncol) { push(@v1,$data[$it]); }
	else            { push(@v2,$data[$it]); }
    }
#   ------------------------------
#   <1> and <2>
#   ------------------------------
    ($av1,$tmp)=&stat_avevar(@v1); 
    ($av2,$tmp)=&stat_avevar(@v2);

#   ------------------------------
#   <11> and <22> and <12y>
#   ------------------------------
    for ($it=1;$it<=$#v1;++$it) { $v11[$it]=$v1[$it]*$v1[$it];} ($av11,$tmp)=&stat_avevar(@v11);
    for ($it=1;$it<=$#v2;++$it) { $v22[$it]=$v2[$it]*$v2[$it];} ($av22,$tmp)=&stat_avevar(@v22);
    for ($it=1;$it<=$#v1;++$it) { $v12[$it]=$v1[$it]*$v2[$it];} ($av12,$tmp)=&stat_avevar(@v12);

#   --------------------------------------------------
#   nom = <12> - <1><2>
#   den = sqrt ( (<11>-<1><1>)*(<22>-<2><2>) )
#   --------------------------------------------------
    $nom=($av12-($av1*$av2));
    $dentmp=( ($av11 - ($av1*$av1)) * ($av22 - ($av2*$av2)) );
    $den="NN";
    $COR="NN";
    $den=sqrt($dentmp)          if ($dentmp>0);
    return($COR)                if ($den eq "NN");
    $COR=$nom/$den              if ($den<-0.00000000001 || $den>0.00000000001);
    return($COR);
}				# end of correlation

#===============================================================================
sub dsspRdSeqSecAcc {
    local($fileInLoc,$chnInLoc,$kwdInLoc) = @_ ;
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   dsspRdSeqSecAcc             reads DSSP file
#                               NOTE: chain breaks are skipped!!
#                               
#       in:                     $fileInLoc:  DSSP file
#       in:                     $chnInLoc:   chain to read (' ' if all)
#       in:                     $kwdInLoc:   seq,sec,acc(nodssp,nopdb): directs what to read!
#       out:                    1|0,msg
#                               
#       out GLOBAL:             %tmp{"NROWS"}=number of residues
#       out GLOBAL:             $tmp{$ct,"chn|seq|sec|acc|nodssp|nopdb"} respective values
#       out GLOBAL:             $tmp{<header|compnd|source|author>}
#                               
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."dsspRdSeqSecAcc";
    $fhinLoc="FHIN_"."dsspRdSeqSecAcc";$fhoutLoc="FHOUT_"."dsspRdSeqSecAcc";
				# ------------------------------
				# check arguments
    return(&errSbr("not def fileInLoc!"))     if (! defined $fileInLoc);
    return(&errSbr("not def chnInLoc!"))      if (! defined $chnInLoc);
    $kwdInLoc="seq,sec,acc"                   if (! defined $kwdInLoc);
				# ------------------------------
				# file existing?
    return(&errSbr("no fileIn=$fileInLoc!"))  if (! -e $fileInLoc && ! -l $fileInLoc);
				# ------------------------------
				# local settings
    $#kwdTmp=0;
    push(@kwdTmp,"seq")         if ($kwdInLoc=~/seq/);
    push(@kwdTmp,"sec")         if ($kwdInLoc=~/sec/);
    push(@kwdTmp,"acc")         if ($kwdInLoc=~/acc/);
    push(@kwdTmp,"nodssp")      if ($kwdInLoc=~/nodssp/);
    push(@kwdTmp,"nopdb")       if ($kwdInLoc=~/nopdb/);

				# ------------------------------
				# open file
    open($fhinLoc,$fileInLoc) || return(&errSbr("fileInLoc=$fileInLoc, not opened"));

    undef %tmp;
				# ------------------------------
				# read HEADER
    while (<$fhinLoc>) {
				# stop header
	last if ($_=~/^\s*\#\s*RESIDUE/);

	$line=$_; $line=~s/\n//g;

	if ($line=~/HEADER\s+(\S.+)$/){
	    $tmp{"header"}=$1;
				# remove '  16-JAN-81   1PPT '
	    $tmp{"header"}=~s/\s+\d\d....\-\d+\s+\d...\s*$//g;
	    next; }

	if ($line=~/COMPND\s+(\S.+)$/){
	    $tmp{"compnd"}=$1;
	    $tmp{"compnd"}=~s/^\s*|\s*$//g;
	    next; }
	if ($line=~/SOURCE\s+(\S.+)$/){
	    $tmp{"source"}=$1;
	    $tmp{"source"}=~s/^\s*|\s*$//g;
	    next; }
	if ($line=~/AUTHOR\s+(\S.+)$/){
	    $tmp{"author"}=$1;
	    $tmp{"author"}=~s/^\s*|\s*$//g;
	    next; }
	if ($line=~/^\s*(\d+)\s*(\d+).*TOTAL NUMBER OF RESIDUES/){
	    $tmp{"NROWS"}= $1;
	    $tmp{"nres"}=  $tmp{"NROWS"};
	    $tmp{"nchn"}=  $2;
	    next; }
    }

				# ------------------------------
				# read file body
    $ctres=0;
    while (<$fhinLoc>) {	# 
	$line=$_; $line=~s/\n//g;
				# all we need in first 40
	undef %tmp2;
	$line=          substr($line,1,40);
	$chn=           substr($line,12,1);

				# skip since chain not wanted?
	next if ($chnInLoc ne " " && 
		 $chn ne $chnInLoc);

	$tmp2{"seq"}=   substr($line,14,1);
				# skip chain breaks
	next if ($tmp2{"seq"} eq "!");

	$tmp2{"nodssp"}=substr($line,1,5); $tmp2{"nodssp"}=~s/\s//g;
	$tmp2{"nopdb"}= substr($line,6,5); $tmp2{"nopdb"}=~s/\s//g;

	$tmp2{"sec"}=   substr($line,17,1);$tmp2{"sec"}=~s/ /L/;
	$tmp2{"acc"}=   substr($line,36,3);$tmp2{"acc"}=~s/\s//g;
	++$ctres;
	foreach $kwd (@kwdTmp){
	    $tmp{$ctres,$kwd}=$tmp2{$kwd};
	}
	$tmp{$ctres,"chn"}=   $chn;
    }

				# correct number of residues
    $tmp{"nres"}=  
	$tmp{"NROWS"}=
	    $ctres;
				# clean up
    undef %tmp2;		# slim-is-in
    $#kwdTmp=0;			# slim-is-in
    
    return(1,"ok $sbrName");
}				# end of dsspRdSeqSecAcc

#===============================================================================
sub getSegment {
    local($stringInLoc) = @_ ;
    local($sbrName,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getSegment                  takes string, writes segments and boundaries
#       in:                     $stringInLoc=  '  HHH  EE HHHHHHHHHHH'
#       out:                    1|0,msg,%segment (as reference!)
#                               $segment{"NROWS"}=   number of segments
#                               $segment{$it}=       type of segment $it (e.g. H)
#                               $segment{"beg",$it}= first residue of segment $it 
#                               $segment{"end",$it}= last residue of segment $it 
#                               $segment{"ct",$it}=  count segment of type $segment{$it}
#                                                    e.g. (L)1,(H)1,(L)2,(E)1,(H)2
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."getSegment";
    $fhinLoc="FHIN_"."getSegment";$fhoutLoc="FHOUT_"."getSegment";
				# check arguments
    return(&errSbr("not def stringInLoc!"))          if (! defined $stringInLoc);
    return(&errSbr("too short stringInLoc!"))        if (length($stringInLoc)<1);

				# set zero
    $prev=""; undef %segment; $ctSegment=0; undef %ctSegment;
				# into array
    @tmp=split(//,$stringInLoc);
    foreach $it (1..$#tmp) {	# loop over all 'residues'
	$sym=$tmp[$it];
				# continue segment
	next if ($prev eq $sym);
				# finish off previous
	$segment{"end",$ctSegment}=($it-1)
	    if ($it > 1);
				# new segment
	$prev=$sym;
	++$ctSegment;
	++$ctSegment{$sym};
	$segment{$ctSegment}=      $sym;
	$segment{"beg",$ctSegment}=$it;
	$segment{"seg",$ctSegment}=$ctSegment{$sym};
    }
				# finish off last
    $segment{"end",$ctSegment}=$#tmp;
				# store number of segments
    $segment{"NROWS"}=$ctSegment;

    $#tmp=0;			# slim-is-in

    return(1,"ok",%segment);
}				# end of getSegment

#===============================================================================
sub errPrdFin {
    local($nfileInLoc,$fileOutLoc,$modeprofLoc,$rh_mode) = @_ ;
    local($SBR1);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   errPrdFin                   compiles rudimentary prediction accuracy over
#                               list of proteins
#       in:                     $nfileInLoc:   number of proteins
#       in:                     $fileOutLoc:   generic name of output file
#                                              will replace extension by e.g. '_acc$ext'
#       in:                     $modeprofLoc:   mode of prof (from &iniDef)
#       in:                     $rh_mode:      pointer to hash array 
#                                              "secKwdRi","secKwdPrd","secKwdObs","secnumout" 
#                               
#       in GLOBAL:              %error{} (from &errPrdOneProt
#                               
#                               
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR1=""."errPrdFin";
				# check arguments
    return(&errSbr("not def nfileInLoc!",$SBR1))   if (! defined $nfileInLoc);
    return(&errSbr("not def fileOutLoc!",$SBR1))   if (! defined $fileOutLoc);
    return(&errSbr("not def modeprofLoc!",$SBR1))   if (! defined $modeprofLoc);
    return(&errSbr("not def rh_mode!",   $SBR1))   if (! defined $rh_mode);
#    return(&errSbr("not def !",$SBR1))          if (! defined $);

				# local parameters (may be to include into main)
    $#kwdOutAcc=$#kwdOutSec=$#kwdOutHtm=0;
				# acc
    if (defined $rh_mode->{"accKwdRi"}){
	@kwdOutAcc=
	    ("nres","nali","ri","zri",
	     "q2","n2o1","n2o2","q2o1","q2o2","q2p1","q2p2",
	     "q3","n3o1","n3o3","q3o1","q3o2","q3o3","q3p1","q3p2","q3p3",
	     "q10","corr");}
				# sec 3 (HEL)
    if    (defined $rh_mode->{"secKwdRi"} && $rh_mode->{"secnumout"} == 3){
	@kwdOutSec=
	    (
	     "nres","nali", 
	     "ri","zri",
	     "q3","n3o1","n3o3","q3o1","q3o2","q3o3","q3p1","q3p2","q3p3"
	     );
	push(@kwdOutSec,"sov","sovH","sovE","sovL")
	    if (defined $par{"errPrd_dosov"} && 
		$par{"errPrd_dosov"}         && 
		defined $error{1,"sec","sov"});
    }
				# sec 6 (HELBGT)
    elsif (defined $rh_mode->{"secKwdRi"} && $rh_mode->{"secnumout"} == 6){
	@kwdOutSec=
	    ("nres","nali","ri","zri",
	     "qN");
	@outnum2sym=split(/,/,$rh_mode->{"outnum2sym"});
	foreach $sym (@outnum2sym){
	    push(@kwdOutSec,"nN".$sym);}
	foreach $sym (@outnum2sym){
	    push(@kwdOutSec,"qNo".$sym);}
	foreach $sym (@outnum2sym){
	    push(@kwdOutSec,"qNp".$sym);}
    }
				# sec otheer
    elsif (defined $rh_mode->{"secKwdRi"}){
	@kwdOutSec=
	    ("nres","nali","ri","zri",
	     "q2","n2o1","n2o2","q2o1","q2o2","q2p1","q2p2");
    }
				# HTM
    elsif (defined $rh_mode->{"htmKwdRi"}){
	@kwdOutHtm=
	    ("nres","nali","ri","zri",
	     "q2","n2o1","n2o2","q2o1","q2o2","q2p1","q2p2");
	@kwdOutSec=@kwdOutHtm   if ($modeprofLoc =~ /htm/);
	push(@kwdOutSec,"sov","sovH","sovE","sovL")
	    if (defined $par{"errPrd_dosov"} && 
		$par{"errPrd_dosov"}         && 
		defined $error{1,"sec","sov"});
    }

				# zz dirty hack
    if (defined @kwdRdHeadNfar && $#kwdRdHeadNfar){
	push(@kwdOutSec,@kwdRdHeadNfar);}

    $fhoutLoc=   "FHOUT_".$SBR1;
    if (defined $par{"extRidet"} && $par{"extRidet"}){
	$extridetloc=$par{"extRidet"};}
    else {
	$extridetloc=".dat_ri";}

    if (defined $par{"extLen"} && $par{"extLen"}){
	$extlenloc=$par{"extLen"};}
    else {
	$extrlenloc=".dat_len";}
	

				# ------------------------------
				# accessibility
				# ------------------------------
    if ($modeprofLoc =~/^(3|both|acc)$/){
	$fileOutTmp=$fileOutLoc;
	$fileOutTmp=~s/(\..*)$/_acc$1/g if ($modeprofLoc=~/3|both/);
# 	($Lok,$msg)=
# 	    &errPrd_postAcc($nfileInLoc,
# 			    );  &errScrMsg("failed to errPrd_postAcc",$msg,$SBR1) if (! $Lok);
	($Lok,$msg)=
	    &errPrd_wrtAcc($nfileInLoc,$fileOutTmp
			   );   &errScrMsg("failed to errPrd_wrtAcc (file=$fileOutTmp)",$msg,
					   $SBR1) if (! $Lok);
    }

				# ------------------------------
				# secondary structure (<= 3 states)
				# ------------------------------
    if ($modeprofLoc =~/^(3|both|htm|sec)$/){
	$fileOutTmp=$fileOutLoc;
	$fileOutTmp=~s/(\..*)$/_sec$1/g if ($modeprofLoc=~/3|both/);
	$fileOutTmp=~s/(\..*)$/_htm$1/g if ($modeprofLoc=~/htm/);
	$#outnum2symSec=0;
	foreach $kwd ("HEL","HL","EL","TL","CL","MN"){
	    if (defined $rdb{1,"P".$kwd}){
		@outnum2symSec=split(//,$kwd);
		last;}}
				# cap stuff
	if (! @outnum2symSec){
	    if    (defined $rdb{1,"OEcapS"} || defined $rdb{1,"OEcapH"}) {
		@outnum2symSec=("e","n");}
	    elsif (defined $rdb{1,"OHcapS"} || defined $rdb{1,"OHcapH"}) {
		@outnum2symSec=("h","n");}
	    elsif (defined $rdb{1,"OHEcapS"} || defined $rdb{1,"OHEcapH"}) {
		@outnum2symSec=("p","n");}
	    else{
		&errScrMsg("failed getting symbols for current mode (file=$fileOutTmp)",
			   $SBR1);}}
	$modetmp="sec";
	$modetmp="htm"          if ($modeprofLoc =~ /htm/);
	($Lok,$msg)=
	    &errPrd_wrtSec($nfileInLoc,$fileOutTmp,$modetmp,\@outnum2symSec
			   );   &errScrMsg("failed to errPrd_wrtSec (file=$fileOutTmp)",$msg,
					   $SBR1) if (! $Lok);

				# ------------------------------
				# length
	if (defined $par{"errPrd_dolength"} && $par{"errPrd_dolength"}){
	    print "--- $SBR1 does a detailed analysis of length!\n"
		if (defined $par{"verbose"} && $par{"verbose"});
	    $fileOutTmplen=$fileOutTmp;
	    $fileOutTmplen=~s/\..*$/$extlenloc/;
	    ($Lok,$msg)=
		&errPrd_wrtLength
		    ($nfileInLoc,$fileOutTmplen,$modetmp,\@outnum2symSec
		     );         &errScrMsg("failed to errPrd_wrtLength (file=$fileOutTmplen)",$msg,
					   $SBR1) if (! $Lok);
	}
    }
				# ------------------------------
				# secondary structure (> 3 states)
				# ------------------------------
    elsif ($modeprofLoc =~/^(sec6)$/){
	$fileOutTmp=$fileOutLoc;
	$#outnum2symSec=0;
	@outnum2symSec=@outnum2sym;
	$modetmp="sec6";
	($Lok,$msg)=
	    &errPrd_wrtSecmany
		($nfileInLoc,$fileOutTmp,$modetmp,\@outnum2symSec
		 );             &errScrMsg("failed to errPrd_wrtSecmany (file=$fileOutTmp)",$msg,
					   $SBR1) if (! $Lok);
    }

				# ------------------------------
				# reliability index, detail
				# ------------------------------
    if (defined $par{"errPrd_doridetail"} && $par{"errPrd_doridetail"}){
	print "--- $SBR1 does a detailed analysis of reliability indices!\n"
	    if (defined $par{"verbose"} && $par{"verbose"});
	$fileOutTmpri=$fileOutTmp;
	$fileOutTmpri=~s/\..*$/$extridetloc/;
	($Lok,$msg)=
	    &errPrd_wrtRidet
		($nfileInLoc,$fileOutTmpri,$modetmp,\@outnum2symSec
		 );             &errScrMsg("failed to errPrd_wrtRidet (file=$fileOutTmpri)",$msg,
					   $SBR1) if (! $Lok);
    }

    return(1,"ok $SBR1");
}				# end of errPrdFin

#===============================================================================
sub errPrdOneProt {
    local($idLoc_ctfile,$modeprofLoc,$rh_mode,@outnum2symLoc)=@_;
    local($SBR6);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   errPrdOneProt               compiles error for one protein
#       in:                     $idLoc_ctfile:  counts protein input files (used as key for %error)
#       in:                     $modepred:      short description of what the job is about
#       in:                     $modeout:       some unique description of output coding (HEL)
#       in:                     $numoutLoc      number of output units read so far
#       in:                     $kwdRiLoc:      should be 'RI_A|S|H'
#       in:                     $acc2Thresh:    threshold for 2-state acc, b: acc<=thresh, e: else
#       in:                     $acc3Thresh:    'T1,T2' threshold for 3-state acc, 
#                                               b: acc<=T1, i: T1<acc<=T2, e: acc>T2
#       in:                     $accBuriedSat:  2|3-state model if accPrd < -> 0
#       in:                     $kwdRiAccLoc:   keyword for reliability index of acc
#       in:                     $kwdRiSecLoc:   keyword for reliability index of sec
#       in:                     $kwdRiHtmLoc:   keyword for reliability index of htm
#       in:                     $kwdPrdSecLoc:  should be 'P(HEL|HL|HL)'
#       in:                     $kwdObsSecLoc:  should be 'O(HEL|HL|HL)'
#       in:                     $kwdPrdHtmLoc:  should be 'PMN'
#       in:                     $kwdObsHtmLoc:  should be 'OMN'
#       in:                     @outnum2sym:    symbol for output units (structure units)
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR6=""."errPrdOneProt";
				# check arguments
    return(&errSbr("not def idLoc_ctfile!",$SBR6))     if (! defined $idLoc_ctfile);
    return(&errSbr("not def modeprofLoc!",  $SBR6))     if (! defined $modeprofLoc);
    return(&errSbr("not def rh_mode!",     $SBR6))     if (! defined $rh_mode);
    return(&errSbr("not def outnum2sym!",  $SBR6))     if (! defined @outnum2symLoc ||
							   ! $#outnum2symLoc);
#    return(&errSbr("not def !",$SBR6))          if (! defined $);

				# ------------------------------
				# analyse accessibility
    if ($modeprofLoc =~/^(3|both|acc)$/){
	$acc2Thresh= $rh_mode->{"acc2Thresh"};
	$acc3Thresh1=$rh_mode->{"acc3Thresh1"};
	$acc3Thresh2=$rh_mode->{"acc3Thresh2"};
	$kwdRiLoc=   $rh_mode->{"accKwdRi"};
	($Lok,$msg)=
	    &errPrd_analyseAcc($idLoc_ctfile,$kwdRiLoc,$acc2Thresh,$acc3Thresh1,$acc3Thresh2
			       );&errSbrMsg("failed to errPrd_analyseAcc for ctfile=$idLoc_ctfile",
					    $msg,$SBR6) if (! $Lok); }
				# ------------------------------
				# analyse secondary structure
    if ($modeprofLoc =~/^(3|both|sec)$/){
	$kwdRiLoc= $rh_mode->{"secKwdRi"};
	$kwdObsLoc=$rh_mode->{"secKwdObs"};
	$kwdPrdLoc=$rh_mode->{"secKwdPrd"};
	($Lok,$msg)=
	    &errPrd_analyseSec($idLoc_ctfile,"sec",$kwdRiLoc,$kwdPrdLoc,$kwdObsLoc,@outnum2symLoc
			       );&errSbrMsg("failed to errPrd_analyseSec for ctfile=$idLoc_ctfile",
					    $msg,$SBR6) if (! $Lok); }
				# ------------------------------
				# analyse membrane helices
    if ($modeprofLoc =~/^(3|both|htm)$/){
	$kwdRiLoc= $rh_mode->{"htmKwdRi"};
	$kwdObsLoc=$rh_mode->{"htmKwdObs"};
	$kwdPrdLoc=$rh_mode->{"htmKwdPrd"};
	($Lok,$msg)=
	    &errPrd_analyseSec($idLoc_ctfile,"htm",$kwdRiLoc,$kwdPrdLoc,$kwdObsLoc,@outnum2symLoc
			       );&errSbrMsg("failed to errPrd_analyseSec for ctfile=$idLoc_ctfile",
					    $msg,$SBR6) if (! $Lok); }
    
    return(1,"ok $SBR6");
}				# end of errPrdOneProt

#===============================================================================
sub errPrd_analyseAcc {
    local($ctfileLoc,$kwdRiLoc,$acc2Thresh,$acc3Thresh1,$acc3Thresh2)=@_;
    local($SBR7,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   errPrd_analyseAcc           compiles accuracy for solvent accessibility
#       in:                     $ctfileLoc:     counts input files (used for $error{$ctfileLoc,$kwd}
#       in:                     $kwdRiLoc:      should be 'RI_A'
#       in:                     $acc2Thresh:    threshold for 2-state acc, b: acc<=thresh, e: else
#       in:                     $acc3Thresh:    'T1,T2' threshold for 3-state acc, 
#                                               b: acc<=T1, i: T1<acc<=T2, e: acc>T2
#       in:                     $accBuriedSat:  2|3-state model if accPrd < -> 0
#       in GLOBAL:              %rdb
#       out GLOBAL:             %error
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR7=""."errPrd_analyseAcc";
				# check arguments
    return(&errSbr("not def ctfileLoc!",  $SBR7))   if (! defined $ctfileLoc);
    return(&errSbr("not def kwdRiLoc!",   $SBR7))   if (! defined $kwdRiLoc);
    return(&errSbr("not def acc2Thresh!", $SBR7))   if (! defined $acc2Thresh);
    return(&errSbr("not def acc3Thresh1!",$SBR7))   if (! defined $acc3Thresh1);
    return(&errSbr("not def acc3Thresh2!",$SBR7))   if (! defined $acc3Thresh2);

    $modeLoc="acc";

    $error{$ctfileLoc,$modeLoc,"nres"}=$rdb{"NROWS"};
    $error{$ctfileLoc,$modeLoc,"nali"}="?";
    $error{$ctfileLoc,$modeLoc,"nali"}=$prot{"nali"}   if (defined $prot{"nali"});
    $error{$ctfileLoc,$modeLoc,"nfar"}=$prot{"nfar"}   if (defined $prot{"nfar"});
    $error{$ctfileLoc,$modeLoc,"nali"}=$rdb{"nali"}    if (defined $rdb{"nali"});
    $error{$ctfileLoc,$modeLoc,"nfar"}=$rdb{"nfar"}    if (defined $rdb{"nfar"});

    $error{$ctfileLoc,$modeLoc,"id"}=  $ctfileLoc;
    $error{$ctfileLoc,$modeLoc,"id"}=  $prot{"id"}     if (defined $prot{"id"});
    $error{$ctfileLoc,$modeLoc,"id"}=  $rdb{"id"}      if (defined $rdb{"id"});

    return(&errSbr("empty??? nres=0 for file=$fileInLoc",$SBR7)) if (! defined $rdb{"NROWS"} ||
								     $rdb{"NROWS"} < 1);
				# --------------------------------------------------
				# sum reliability index
    $sum=0;
    foreach $itres (1..$error{$ctfileLoc,$modeLoc,"nres"}){
	next if (! defined $rdb{$itres,$kwdRiLoc}  ||
		 $rdb{$itres,"AA"} eq "!"          ||
		 $rdb{$itres,$kwdRiLoc}=~/\D/      ||
		 length($rdb{$itres,$kwdRiLoc})< 1 );
	$sum+=$rdb{$itres,$kwdRiLoc}; }

    $error{$ctfileLoc,$modeLoc,"ri"}=$sum/$error{$ctfileLoc,$modeLoc,"nres"};

				# --------------------------------------------------
				# get prediction and observation
    $#obs=$#prd;
				# get relative accessibility values
    foreach $itres (1..$error{$ctfileLoc,$modeLoc,"nres"}){
				# skip chain breaks
	next if (! defined $rdb{$itres,"OREL"} ||
		 $rdb{$itres,"AA"} eq "!");
	$obs="?";$prd="?";
	$obs=$rdb{$itres,"OREL"} if (defined $rdb{$itres,"OREL"} && 
				     $rdb{$itres,"OREL"}!~/\D/);
	$prd=$rdb{$itres,"PREL"} if (defined $rdb{$itres,"PREL"} && 
				     $rdb{$itres,"PREL"}!~/\D/);
	push(@obs,$obs);push(@prd,$prd);
    }
				# ------------------------------
				# ini error matrix
    if    ($par{"errPrd_doq2"}){
	$nstatePrimary=2;}
    elsif ($par{"errPrd_doq3"}){
	$nstatePrimary=3;}
    elsif ($par{"errPrd_doq10"}){
	$nstatePrimary=10;}
    else {
	$nstatePrimary=2;}

    foreach $stateobs (1..$nstatePrimary){
	foreach $stateprd (1..$nstatePrimary){
	    $error{$ctfileLoc,$modeLoc,"mat",$stateobs,$stateprd}=0;
	}}

				# --------------------------------------------------
                                # recompile Q2,Q3,Q10,corr
				# --------------------------------------------------
    $cttmp=$#tmpobs=$#tmpprd=0;
    undef %tmperr;
    foreach $it (1..$#prd){
	next if ($prd[$it] =~/\D/    || $obs[$it] =~/\D/ ||
		 length($prd[$it])<1 || length($obs[$it])<1);
				# ------------------------------
				# 10 state
	($Lok,$msg,$prd10)=    &convert_accRel2oneDigit($prd[$it]);
	$stateprd=$prd10        if ($nstatePrimary==10);
	if ($prd10 !~/\D/){
	    ($Lok,$msg,$obs10)=&convert_accRel2oneDigit($obs[$it]);
	    $stateprd=$obs10    if ($nstatePrimary==10);
	    ++$tmperror{"q10"}  if ($obs10 !~/\D/ && $prd10 == $obs10); 
	    ++$tmperror{"n10"}; }
				# ------------------------------
				# 2 state
	++$tmperror{"n2"};	# count all resctfileLoc,$modeLocues for which acc was ok
				# buried
	if ($prd[$it]<= $acc2Thresh){
	    ++$tmperror{"n2p",1};
	    $stateprd=1         if ($nstatePrimary==2);
	    if ($obs[$it] <= $acc2Thresh){
		$stateobs=1     if ($nstatePrimary==2);
		++$tmperror{"n2o",1};
		++$tmperror{"q2"};
		++$tmperror{"q2",1};}
	    else {
		$stateobs=2     if ($nstatePrimary==2);
		++$tmperror{"n2o",2};}}
				# exposed
	else {
	    $stateprd=2         if ($nstatePrimary==2);
	    ++$tmperror{"n2p",2};
	    if ($obs[$it] >  $acc2Thresh) {
		$stateobs=2     if ($nstatePrimary==2);
		++$tmperror{"n2o",2};
		++$tmperror{"q2"};
		++$tmperror{"q2",2};}
	    else {
		$stateobs=1     if ($nstatePrimary==2);
		++$tmperror{"n2o",1};}}
		
				# ------------------------------
				# 3 state
	++$tmperror{"n3"};	# count all resctfileLoc,$modeLocues for which acc was ok
				# buried
	if    ($prd[$it] <= $acc3Thresh1){
	    ++$tmperror{"n3p",1};
	    $stateprd=1         if ($nstatePrimary==3);
	    if    ($obs[$it] <= $acc3Thresh1){
		$stateobs=1     if ($nstatePrimary==3);
		++$tmperror{"n3o",1};
		++$tmperror{"q3"};
		++$tmperror{"q3",1};}
	    elsif ($obs[$it] >  $acc3Thresh2){
		$stateobs=3     if ($nstatePrimary==3);
		++$tmperror{"n3o",3};}
	    else {
		$stateobs=2     if ($nstatePrimary==3);
		++$tmperror{"n3o",2};}}
				# exposed
	elsif ($prd[$it] >  $acc3Thresh2){
	    ++$tmperror{"n3p",3};
	    $stateprd=3         if ($nstatePrimary==3);
	    if    ($obs[$it] >  $acc3Thresh2){
		$stateobs=3     if ($nstatePrimary==3);
		++$tmperror{"n3o",3};
		++$tmperror{"q3"};
		++$tmperror{"q3",3};}
	    elsif ($obs[$it] <= $acc3Thresh1){
		$stateobs=1     if ($nstatePrimary==3);
		++$tmperror{"n3o",1};}
	    else {
		$stateobs=2     if ($nstatePrimary==3);
		++$tmperror{"n3o",2};}}
				# intermediate
	else {
	    $stateprd=2         if ($nstatePrimary==3);
	    ++$tmperror{"n3p",2};
	    if    ($obs[$it] <= $acc3Thresh1){
		$stateobs=1     if ($nstatePrimary==3);
		++$tmperror{"n3o",1};}
	    elsif ($obs[$it] >  $acc3Thresh2){
		$stateobs=3     if ($nstatePrimary==3);
		++$tmperror{"n3o",3};}
	    else {
		$stateobs=2     if ($nstatePrimary==3);
		++$tmperror{"n3o",2};
		++$tmperror{"q3"};
		++$tmperror{"q3",2};}}
	++$cttmp;
	push(@tmpobs,($obs[$it]/100));
	push(@tmpprd,($prd[$it]/100));
				# count for matrix
	++$error{$ctfileLoc,$modeLoc,"mat",$stateobs,$stateprd};
    }

    $#obs=$#prd=0;		# slim-is-in

		 		# ------------------------------
    if ($par{"errPrd_doq2"}){	# percentages two-states
	foreach $kwd ("q2","n2o","n2o1","n2o2","q2o1","q2o2","q2p1","q2p2"){
	    $error{$ctfileLoc,$modeLoc,$kwd}=0;
	}
	$error{$ctfileLoc,$modeLoc,"q2"}=  
	    sprintf("%8.3f",100*($tmperror{"q2"}/$tmperror{"n2"}))
		if (defined $tmperror{"q2"} && $tmperror{"q2"}!~/[^\d\.]/);
	$error{$ctfileLoc,$modeLoc,"n2o",1}=
	    sprintf("%8.3f",100*($tmperror{"n2o",1}/$tmperror{"n2"}))
		if (defined $tmperror{"n2o",1} && $tmperror{"n2o",1}!~/[^\d\.]/);
	$error{$ctfileLoc,$modeLoc,"n2o",2}=
	    sprintf("%8.3f",100*($tmperror{"n2o",2}/$tmperror{"n2"}))
		if (defined $tmperror{"n2o",2} && $tmperror{"n2o",2}!~/[^\d\.]/);
	$error{$ctfileLoc,$modeLoc,"q2o",1}=
	    sprintf("%8.3f",100*($tmperror{"q2",1}/$tmperror{"n2o",1}))
		if (defined $tmperror{"q2",1} && $tmperror{"q2",1}!~/[^\d\.]/);
	$error{$ctfileLoc,$modeLoc,"q2o",2}=
	    sprintf("%8.3f",100*($tmperror{"q2",2}/$tmperror{"n2o",2}))
		if (defined $tmperror{"q2",2} && $tmperror{"q2",2}!~/[^\d\.]/);
	$error{$ctfileLoc,$modeLoc,"q2p",1}=
	    sprintf("%8.3f",100*($tmperror{"q2",1}/$tmperror{"n2p",1}))
		if (defined $tmperror{"q2",1} && $tmperror{"q2",1}!~/[^\d\.]/);
	$error{$ctfileLoc,$modeLoc,"q2p",2}=
	    sprintf("%8.3f",100*($tmperror{"q2",2}/$tmperror{"n2p",2}))
		if (defined $tmperror{"q2",2} && $tmperror{"q2",2}!~/[^\d\.]/);
    }				# end of Q2
    
				# ------------------------------
				# percentages three states
    if ($par{"errPrd_doq3"}){
	foreach $kwd ("q3","n3o","n3o1","n3o2","n3o3",
		      "q3o1","q3o2","q3o3","q3p1","q3p2","q3p3"){
	    $error{$ctfileLoc,$modeLoc,$kwd}=0;
	}
	$error{$ctfileLoc,$modeLoc,"q3"}=  
	    sprintf("%8.3f",  100*($tmperror{"q3"}/$tmperror{"n3"}))
		if (defined $tmperror{"q3"} && $tmperror{"q3"}!~/[^\d\.]/);
	foreach $it (1..3){
	    $error{$ctfileLoc,$modeLoc,"n3o",$it}=
		sprintf("%8.3f",100*($tmperror{"n3o",$it}/$tmperror{"n3"}))
		    if (defined $tmperror{"n3o",$it} && $tmperror{"n3o",$it}!~/[^\d\.]/);
	    $error{$ctfileLoc,$modeLoc,"q3o",$it}=
		sprintf("%8.3f",100*($tmperror{"q3",$it}/$tmperror{"n3o",$it}))
		    if (defined $tmperror{"q3",$it} && $tmperror{"q3",$it}!~/[^\d\.]/);
	    $error{$ctfileLoc,$modeLoc,"q3p",$it}=
		sprintf("%8.3f",100*($tmperror{"q3",$it}/$tmperror{"n3p",$it}))
		    if (defined $tmperror{"q3",$it} && $tmperror{"q3",$it}!~/[^\d\.]/);
	}
    }				# end of Q3

				# ------------------------------
				# percentages ten states
    if ($par{"errPrd_doq10"}){
	$error{$ctfileLoc,$modeLoc,"q10"}=0;
	$error{$ctfileLoc,$modeLoc,"q10"}= 
	    sprintf("%8.3f", 100*($tmperror{"q10"}/$tmperror{"n10"}))
		if (defined $tmperror{"q10"} && $tmperror{"q10"}!~/[^\d\.]/);
    }
				# ------------------------------
				# get correlation
    $error{$ctfileLoc,$modeLoc,"corr"}=
	&correlation($cttmp,@tmpobs,@tmpprd);
    $error{$ctfileLoc,$modeLoc,"corr"}=0  if ($error{$ctfileLoc,$modeLoc,"corr"}=~/[^\d\.]/);

    $#tmpobs=$#tmpprd=0;	# slim-is-in
    undef %tmperror;		# slim-is-in
    
    return(1,"ok $SBR7");
}				# end of errPrd_analyseAcc

#===============================================================================
sub errPrd_analyseSec {
    local($ctfileLoc,$modeLoc,$kwdRiLoc,$kwdPrdLoc,$kwdObsLoc,@outnum2symLoc)=@_;
    local($SBR7,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   errPrd_analyseSec           compiles accuracy for secondary structure
#       in:                     $ctfileLoc:     counts input files (used for $error{$ctfileLoc,$kwd}
#       in:                     $modeLoc:       <sec|htm>
#       in:                     $kwdRiLoc:      should be 'RI_S|H'
#       in:                     $kwdPrdLoc:     should be 'P(HEL|HL|HL|MN)'
#       in:                     $kwdObsLoc:     should be 'O(HEL|HL|HL|MN)'
#       in:                     @outnum2sym:    symbol for output units (structure units)
#       in GLOBAL:              %rdb
#       out GLOBAL:             %error
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR7=""."errPrd_analyseSec";
				# check arguments
    return(&errSbr("not def ctfileLoc!", $SBR7))     if (! defined $ctfileLoc);
    return(&errSbr("not def modeLoc!",   $SBR7))     if (! defined $modeLoc);
    return(&errSbr("not def kwdRiLoc!",  $SBR7))     if (! defined $kwdRiLoc);
    return(&errSbr("not def kwdPrdLoc!", $SBR7))     if (! defined $kwdPrdLoc);
    return(&errSbr("not def kwdObsLoc!", $SBR7))     if (! defined $kwdObsLoc);
    return(&errSbr("not def outnum2sym!",$SBR7))     if (! defined @outnum2symLoc ||
							 ! $#outnum2symLoc);

				# protein wide: done already?
    $error{$ctfileLoc,$modeLoc,"nres"}=$rdb{"NROWS"};
    $error{$ctfileLoc,$modeLoc,"nali"}="?";
    $error{$ctfileLoc,$modeLoc,"nfar"}="?";
    $error{$ctfileLoc,$modeLoc,"nali"}=$prot{"nali"}  if (defined $prot{"nali"});
    $error{$ctfileLoc,$modeLoc,"nfar"}=$prot{"nfar"}  if (defined $prot{"nfar"});
    $error{$ctfileLoc,$modeLoc,"nali"}=$rdb{"nali"}   if (defined $rdb{"nali"});
    $error{$ctfileLoc,$modeLoc,"nfar"}=$rdb{"nfar"}   if (defined $rdb{"nfar"});
				# zz dirty hack
    if (defined @kwdRdHeadNfar && $#kwdRdHeadNfar){
	foreach $kwdtmp (@kwdRdHeadNfar){
	    $error{$ctfileLoc,$modeLoc,$kwdtmp}=$rdb{$kwdtmp} if (defined $rdb{$kwdtmp});
	}}

    $error{$ctfileLoc,$modeLoc,"id"}=  $ctfileLoc;
    $error{$ctfileLoc,$modeLoc,"id"}=  $prot{"id"}    if (defined $prot{"id"});
    $error{$ctfileLoc,$modeLoc,"id"}=  $rdb{"id"}     if (defined $rdb{"id"});
	
    return(&errSbr("empty??? nres=0 for file=$fileInLoc",$SBR7)) if (! defined $rdb{"NROWS"} ||
								     $rdb{"NROWS"} < 1);
    
				# ------------------------------
				# ini error matrix
    $nstatePrimary=$#outnum2symLoc;
    foreach $stateobs (1..$nstatePrimary){
	foreach $stateprd (1..$nstatePrimary){
	    $error{$ctfileLoc,$modeLoc,"mat",$stateobs,$stateprd}=0;
	}}

				# --------------------------------------------------
				# sum reliability index
    $sum=0;
    $#ri=$#riocc=0;undef %ri;
    foreach $itres (1..$error{$ctfileLoc,$modeLoc,"nres"}){
	next if (! defined $rdb{$itres,$kwdRiLoc}  ||
		 $rdb{$itres,"AA"} eq "!"          ||
		 $rdb{$itres,$kwdRiLoc}=~/\D/      ||
		 length($rdb{$itres,$kwdRiLoc})< 1 );
	$ri=        $rdb{$itres,$kwdRiLoc}; 
	$sum+=      $ri;
	$ri[$itres]=$ri;
				# which indices occurred?
	if (! defined $ri{$ri}){
	    $ri{$ri}=1;
	    push(@riocc,$ri);}
	if (! defined $error{$modeLoc,"rimax"}){
	    $error{$modeLoc,"rimax"}=$ri;}
	if ($ri > $error{$modeLoc,"rimax"}){
	    $error{$modeLoc,"rimax"}=$ri;}
	++$error{"nres"};
    }
    $error{$modeLoc,"rimax"}=10; # yy: hard coded to avoid differences ...

    $error{$ctfileLoc,$modeLoc,"ri"}=   $sum/$error{$ctfileLoc,$modeLoc,"nres"};
    $error{$ctfileLoc,$modeLoc,"riocc"}=join(',',@riocc);
    undef %ri;
				# --------------------------------------------------
				# get prediction and observation
    $#obs=$#prd;
				# get relative accessibility values
    foreach $itres (1..$error{$ctfileLoc,$modeLoc,"nres"}){
				# skip chain breaks
	next if (! defined $rdb{$itres,$kwdObsLoc} ||
		 $rdb{$itres,"AA"} eq "!");
	$obs="?";$prd="?";
	$obs=$rdb{$itres,$kwdObsLoc} if (defined $rdb{$itres,$kwdObsLoc});
	$prd=$rdb{$itres,$kwdPrdLoc} if (defined $rdb{$itres,$kwdPrdLoc});
	push(@obs,$obs);push(@prd,$prd);
    }
    if (defined $par{"debug"}){
	for ($it=1; $it<=$#obs; $it+=80){
	    $last=$it+80;
	    $last=$it+($#obs-$it)        if ($last > $#obs);
	    printf " %4s obs=%-s\n",$it,join('',@obs[$it .. $last]);
	    printf " %4s prd=%-s\n",$it,join('',@prd[$it .. $last]);
	}}
				# ------------------------------
				# ini error matrix
    foreach $stateobs (1..$#outnum2symLoc){
	foreach $stateprd (1..$#outnum2symLoc){
	    $error{$ctfileLoc,$modeLoc,"mat",$stateobs,$stateprd}=0;
	}}

				# --------------------------------------------------
                                # recompile Q3
				# --------------------------------------------------
    $cttmp=$#tmpobs=$#tmpprd=0;
    undef %tmperror;		# slim-is-in
    if ($kwdObsLoc=~/HEL$/){
	foreach $itres (1..$#prd){
	    ++$tmperror{"n3"};	# count all resctfileLocues for which acc was ok
	    $stateobs=$stateprd=0;
	    foreach $itout (1..$#outnum2symLoc){
		if ($prd[$itres] eq $outnum2symLoc[$itout]){
		    $stateprd=$itout;
		    $tmpprd=$itout;
		    ++$tmperror{"n3p",$itout};}
		if ($obs[$itres] eq $outnum2symLoc[$itout]){
		    $stateobs=$itout;
		    $tmpobs=$itout;
		    ++$tmperror{"n3o",$itout};}
		if ($prd[$itres] eq $outnum2symLoc[$itout] &&
		    $obs[$itres] eq $outnum2symLoc[$itout]){
		    $stateobs=$itout;
		    $stateprd=$itout;
		    ++$tmperror{"q3"};
		    ++$tmperror{"q3",$itout};}}
	    ++$error{$ctfileLoc,$modeLoc,"mat",$stateobs,$stateprd};
				# bin reliability index
	    if (defined $ri[$itres]){
		++$error{$ctfileLoc,$modeLoc,$ri[$itres],"ok"} if ($stateobs eq $stateprd);
		++$error{$ctfileLoc,$modeLoc,$ri[$itres],"no"};}
	    else {
		print "-*- WARN SBR7: itres=$itres, ri not defined\n" 
		    if (defined $par{"debug"} && $par{"debug"});}
	}}
				# --------------------------------------------------
                                # compile QN
				# --------------------------------------------------
    elsif ($#outnum2symLoc > 3){
	foreach $itres (1..$#prd){
	    ++$tmperror{"nN"};	# count all resctfileLocues for which acc was ok
	    $stateobs=$stateprd=0;
	    foreach $itout (1..$#outnum2symLoc){
		if ($prd[$itres] eq $outnum2symLoc[$itout]){
		    $stateprd=$itout;
		    $tmpprd=$itout;
		    ++$tmperror{"nNp",$itout};}
		if ($obs[$itres] eq $outnum2symLoc[$itout]){
		    $stateobs=$itout;
		    $tmpobs=$itout;
		    ++$tmperror{"nNo",$itout};}
		if ($prd[$itres] eq $outnum2symLoc[$itout] &&
		    $obs[$itres] eq $outnum2symLoc[$itout]){
		    $stateobs=$itout;
		    $stateprd=$itout;
		    ++$tmperror{"qN"};
		    ++$tmperror{"qN",$itout};}}
	    ++$error{$ctfileLoc,$modeLoc,"mat",$stateobs,$stateprd};
				# bin reliability index
	    if (defined $ri[$itres]){
		++$error{$ctfileLoc,$modeLoc,$ri[$itres],"ok"} if ($stateobs eq $stateprd);
		++$error{$ctfileLoc,$modeLoc,$ri[$itres],"no"};}
	    else {
		print "-*- WARN SBR7: itres=$itres, ri not defined\n" 
		    if (defined $par{"debug"} && $par{"debug"});
	    }
	}}
				# --------------------------------------------------
                                # recompile Q2
				# --------------------------------------------------

    else {
	foreach $itres (1..$#prd){
	    ++$tmperror{"n2"};	# count all resctfileLocues for which acc was ok
				# 1st state
	    if ($prd[$itres] eq $outnum2symLoc[1]){
		$stateprd=1;
		++$tmperror{"n2p",1};
		if ($obs[$itres] eq $outnum2symLoc[1]){
		    $stateobs=1;
		    ++$tmperror{"n2o",1};
		    ++$tmperror{"q2"};
		    ++$tmperror{"q2",1};}
		else {
		    $stateobs=2;
		    ++$tmperror{"n2o",2};}}
				# 2nd state
	    else {
		$stateprd=2;
		++$tmperror{"n2p",2};
		if ($obs[$itres] eq $outnum2symLoc[2]) {
		    $stateobs=2;
		    ++$tmperror{"n2o",2};
		    ++$tmperror{"q2"};
		    ++$tmperror{"q2",2};}
		else {
		    $stateobs=1;
		    ++$tmperror{"n2o",1};}}

	    ++$error{$ctfileLoc,$modeLoc,"mat",$stateobs,$stateprd};
				# bin reliability index
	    die "yyxy missing obs($itres)\n" if (! defined $obs[$itres]);
	    die "yyxy missing prd($itres)\n" if (! defined $prd[$itres]);
	    warn "yyxy missing ri($itres)\n"  if (! defined $ri[$itres]);
				# terrible hack br 2001-08
	    if (! defined $ri[$itres]){
		foreach $itres (1..$#prd){
		    $ri[$itres]=1;
		}}


	    ++$error{$ctfileLoc,$modeLoc,$ri[$itres],"ok"} if ($obs[$itres] eq $prd[$itres]);
	    ++$error{$ctfileLoc,$modeLoc,$ri[$itres],"no"};
	}}
#     print "xyy n2p1=",$tmperror{"n2p",1},"\n";
#     print "xyy n2p2=",$tmperror{"n2p",2},"\n";
#     print "xyy   q2=",$tmperror{"q2"},"\n";
#     print "xyy  q21=",$tmperror{"q2",1},"\n";
#     print "xyy  q22=",$tmperror{"q2",2},"\n";

				# ------------------------------
				# two-state percentages
    if ($par{"errPrd_doq2"}){
	$error{$ctfileLoc,$modeLoc,"q2"}=
	    sprintf("%8.3f",100*($tmperror{"q2"}/$tmperror{"n2"}))
		if (defined $tmperror{"q2"} && $tmperror{"q2"}!~/[^\d\.]/);
	$error{$ctfileLoc,$modeLoc,"n2o",1}=
	    sprintf("%8.3f",100*($tmperror{"n2o",1}/$tmperror{"n2"}))
		if (defined $tmperror{"n2o",1} && $tmperror{"n2o",1}!~/[^\d\.]/);
	$error{$ctfileLoc,$modeLoc,"n2o",2}=
	    sprintf("%8.3f",100*($tmperror{"n2o",2}/$tmperror{"n2"}))
		if (defined $tmperror{"n2o",2} && $tmperror{"n2o",2}!~/[^\d\.]/);
	$error{$ctfileLoc,$modeLoc,"q2o",1}=
	    sprintf("%8.3f",100*($tmperror{"q2",1}/$tmperror{"n2o",1}))
		if (defined $tmperror{"q2",1} && $tmperror{"q2",1}!~/[^\d\.]/);
	$error{$ctfileLoc,$modeLoc,"q2o",2}=
	    sprintf("%8.3f",100*($tmperror{"q2",2}/$tmperror{"n2o",2}))
		if (defined $tmperror{"q2",2} && $tmperror{"q2",2}!~/[^\d\.]/);
	$error{$ctfileLoc,$modeLoc,"q2p",1}=
	    sprintf("%8.3f",100*($tmperror{"q2",1}/$tmperror{"n2p",1}))
		if (defined $tmperror{"q2",1} && $tmperror{"q2",1}!~/[^\d\.]/);
	$error{$ctfileLoc,$modeLoc,"q2p",2}=
	    sprintf("%8.3f",100*($tmperror{"q2",2}/$tmperror{"n2p",2}))
		if (defined $tmperror{"q2",2} && $tmperror{"q2",2}!~/[^\d\.]/);
    }				# end of Q2

				# ------------------------------
				# three-state percentages
    if ($par{"errPrd_doq3"}){
	$error{$ctfileLoc,$modeLoc,"q3"}=
	    sprintf("%8.3f",  100*($tmperror{"q3"}/$tmperror{"n3"}))
		if (defined $tmperror{"q3"} && $tmperror{"q3"}!~/[^\d\.]/);
				# ini
	foreach $kwd ("n3o","q3o","q3p"){
	    foreach $it (1..3){
		$error{$ctfileLoc,$modeLoc,$kwd,$it}=0;}}

	foreach $it (1..3){
	    $error{$ctfileLoc,$modeLoc,"n3o",$it}=
		sprintf("%8.3f",100*($tmperror{"n3o",$it}/$tmperror{"n3"}))
		    if (defined $tmperror{"n3o",$it} && $tmperror{"n3o",$it}!~/[^\d\.]/);
	    $error{$ctfileLoc,$modeLoc,"q3o",$it}=
		sprintf("%8.3f",100*($tmperror{"q3",$it}/$tmperror{"n3o",$it}))
		    if (defined $tmperror{"q3",$it} && $tmperror{"q3",$it}!~/[^\d\.]/);
	    $error{$ctfileLoc,$modeLoc,"q3p",$it}=
		sprintf("%8.3f",100*($tmperror{"q3",$it}/$tmperror{"n3p",$it}))
		    if (defined $tmperror{"q3",$it} && $tmperror{"q3",$it}!~/[^\d\.]/);
	}
    }				# end of Q3

				# ------------------------------
				# many-state percentages
    if ($par{"errPrd_doqN"}){
	$error{$ctfileLoc,$modeLoc,"qN"}=
	    sprintf("%8.3f",  100*($tmperror{"qN"}/$tmperror{"nN"}))
		if (defined $tmperror{"qN"} && $tmperror{"qN"}!~/[^\d\.]/);
				# ini
	foreach $kwd ("nNo","qNo","qNp"){
	    foreach $it (1..$#outnum2symLoc){
		$error{$ctfileLoc,$modeLoc,$kwd,$it}=0;}}

	foreach $it (1..$#outnum2symLoc){
	    $error{$ctfileLoc,$modeLoc,"nNo",$it}=
		sprintf("%8.3f",100*($tmperror{"nNo",$it}/$tmperror{"nN"}))
		    if (defined $tmperror{"nNo",$it} && $tmperror{"nNo",$it}!~/[^\d\.]/);
	    $error{$ctfileLoc,$modeLoc,"qNo",$it}=
		sprintf("%8.3f",100*($tmperror{"qN",$it}/$tmperror{"nNo",$it}))
		    if (defined $tmperror{"qN",$it} && $tmperror{"qN",$it}!~/[^\d\.]/);
	    $error{$ctfileLoc,$modeLoc,"qNp",$it}=
		sprintf("%8.3f",100*($tmperror{"qN",$it}/$tmperror{"nNp",$it}))
		    if (defined $tmperror{"qN",$it} && $tmperror{"qN",$it}!~/[^\d\.]/);
	}
    }				# end of QN

    if (0){			# xx
	$maxstate=3;
	$maxstate=2 if (! $par{"errPrd_doq3"});
#	$obs=join('',@obs);$obs=~s/L/ /g;$prd=join('',@prd);$prd=~s/L/ /g;
#	print "obs=",$obs,"\n";print "prd=",$prd,"\n";
	printf "%-10s\t","prd\\obs";
	foreach $itobs (1..$maxstate){
	    printf "%5d\t",$itobs;}
	printf "%5s\n","sum";
	$sum=$#sumprd=0;
	foreach $itobs (1..$maxstate){
	    printf "%10s\t",$itobs;$sumobs=0;
	    foreach $itprd (1..$maxstate){
		$sum+=$error{$ctfileLoc,$modeLoc,"mat",$itobs,$itprd};
		$sumobs+=$error{$ctfileLoc,$modeLoc,"mat",$itobs,$itprd};
		$sumprd[$itprd]+=$error{$ctfileLoc,$modeLoc,"mat",$itobs,$itprd};
		printf "%5d\t",$error{$ctfileLoc,$modeLoc,"mat",$itobs,$itprd};}
	    printf "%5d\n",$sumobs;}
	printf "%10s\t","sum";
	foreach $itobs (1..$maxstate){
	    printf "%5d\t",$sumprd[$itobs];}
	printf "%5d\n",$sum;
    }
				# ------------------------------
				# Matthews correlation and info
    if ($par{"errPrd_domatthews"} || $par{"errPrd_doinfo"} || $par{"errPrd_dobad"}){
	undef %mat;
	foreach $itobs (1..$nstatePrimary){
	    foreach $itprd (1..$nstatePrimary){
		if (defined $error{$ctfileLoc,$modeLoc,"mat",$itobs,$itprd}){
		    $mat{$itobs,$itprd}=$error{$ctfileLoc,$modeLoc,"mat",$itobs,$itprd};}
		else {
		    $mat{$itobs,$itprd}=0;}
	    }}
	$mat{"nres"}=$error{$ctfileLoc,$modeLoc,"nres"};
				# Matthews
	if ($par{"errPrd_domatthews"}){
	    ($Lok,$msg,@matthews)=
		&accSecMatthews
		    ($nstatePrimary,
		     %mat);     return(&errSbrMsg("failed on matthews (nstate=$nstatePrimary)",
						  $msg,$SBR7)) if (! $Lok);
	    foreach $it (1..$#matthews){
		$error{$ctfileLoc,$modeLoc,"matthews",$it}=$matthews[$it];
				# accuracy = 8.3f
		$error{$ctfileLoc,$modeLoc,"matthews",$it}=~s/(\....).*$/$1/g;
	    }}
				# info
	if ($par{"errPrd_doinfo"}){
	    ($Lok,$msg,@info)=
		&accSecInfo
		    ($nstatePrimary,
		     %mat);     return(&errSbrMsg("failed on INFO (nstate=$nstatePrimary)",
						  $msg,$SBR7)) if (! $Lok);
	    $error{$ctfileLoc,$modeLoc,"info","obs"}=$info[1];
	    $error{$ctfileLoc,$modeLoc,"info","prd"}=$info[2];
				# accuracy = 8.3f
	    $error{$ctfileLoc,$modeLoc,"info","obs"}=~s/(\....).*$/$1/g;
	    $error{$ctfileLoc,$modeLoc,"info","prd"}=~s/(\....).*$/$1/g;
	}}

				# BAD predictions
    if    ($par{"errPrd_dobad"} && $par{"errPrd_doq3"} && defined %mat ){
	$error{$ctfileLoc,$modeLoc,"bad"}=($mat{1,2}+$mat{2,1});
	$error{$ctfileLoc,$modeLoc,"bad"}= (100/$mat{"nres"}) * 
	    $error{$ctfileLoc,$modeLoc,"bad"};
				# trim
	$error{$ctfileLoc,$modeLoc,"bad"}=~s/(\.\d).*$/$1/;
    }
    elsif ($par{"errPrd_dobad"}){
	print "-*- WARN $SBR: you want the score BAD, but no 3state nor mat{} are defined -> skipped!\n";
    }

				# --------------------------------------------------
				# get sec str content: only for 3 states
    if ($par{"errPrd_docontent"} && $nstatePrimary == 3){
	foreach $it1 (1..3){
	    $cont_prd=$cont_obs=0;
	    foreach $it2 (1..3){
		$cont_prd+=$error{$ctfileLoc,$modeLoc,"mat",$it2,$it1};
		$cont_obs+=$error{$ctfileLoc,$modeLoc,"mat",$it1,$it2};
	    }
				# normalise
	    $cont_prd=$cont_prd/$rdb{"NROWS"};
	    $cont_obs=$cont_obs/$rdb{"NROWS"};
				# diff
	    $delta=   int(100*($cont_obs-$cont_prd));
				# absolute
	    $delta=   -1*$delta if ($delta < 0);
	    $error{$ctfileLoc,$modeLoc,"contD".$it1}=   $delta;
	    $error{$ctfileLoc,$modeLoc,"cont".$it1."o"}=int(100*$cont_obs);
	    $error{$ctfileLoc,$modeLoc,"cont".$it1."p"}=int(100*$cont_prd);
	}

				# get sec str class: only for 3 states
	$obs=$prd=$par{"class",4};

				# OBSERVED
	if ($rdb{"NROWS"} > 60                           && 
	    defined $error{$ctfileLoc,$modeLoc,"cont1o"} &&
	    defined $error{$ctfileLoc,$modeLoc,"cont2o"}     ){
				# obs: all-alpha
	    if    ($error{$ctfileLoc,$modeLoc,"cont1o"} > 45    &&
		   $error{$ctfileLoc,$modeLoc,"cont2o"} <  5       ){
		$obs=$par{"class",1};}
				# obs: all-beta
	    elsif ($error{$ctfileLoc,$modeLoc,"cont1o"} <  5 &&
		   $error{$ctfileLoc,$modeLoc,"cont2o"} > 45){
		$obs=$par{"class",2};}
				# obs: alpha-beta
	    elsif ($error{$ctfileLoc,$modeLoc,"cont1o"} > 30 &&
		   $error{$ctfileLoc,$modeLoc,"cont2o"} > 20){
		$obs=$par{"class",3};}
	}
				# PREDICTED
	if ($rdb{"NROWS"} > 60                           && 
	    defined $error{$ctfileLoc,$modeLoc,"cont1p"} &&
	    defined $error{$ctfileLoc,$modeLoc,"cont2p"}     ){
				# prd: all-alpha
	    if    ($error{$ctfileLoc,$modeLoc,"cont1p"} > 45 &&
		   $error{$ctfileLoc,$modeLoc,"cont2p"} <  5){
		$prd=$par{"class",1};}
				# prd: all-beta
	    elsif ($error{$ctfileLoc,$modeLoc,"cont1p"} <  5 &&
		   $error{$ctfileLoc,$modeLoc,"cont2p"} > 45){
		$prd=$par{"class",2};}
				# prd: alpha-beta
	    elsif ($error{$ctfileLoc,$modeLoc,"cont1p"} > 30 &&
		   $error{$ctfileLoc,$modeLoc,"cont2p"} > 20){
		$prd=$par{"class",3};}
	}

	$error{$ctfileLoc,$modeLoc,"class"}=    0;
	$error{$ctfileLoc,$modeLoc,"class"}=  100 
	    if ($obs eq $prd);
	$error{$ctfileLoc,$modeLoc,"class"."o"}=$obs;
	$error{$ctfileLoc,$modeLoc,"class"."p"}=$prd;
    }
				# ------------------------------
				# get segments
				# ------------------------------
    if ($par{"errPrd_dolength"}){
	$prd=join('',@prd);
	$obs=join('',@obs);
				# --------------------
				# predicted segments
	($Lok,$msg,%segment)=
	    &getSegment($prd);
	$error{$ctfileLoc,$modeLoc,"segprd"."no"}=$segment{"NROWS"};
	$#tmpsym=0;
	foreach $itseg (1..$segment{"NROWS"}){
	    $sym=$segment{$itseg};
	    $len=1 + $segment{"end",$itseg} - $segment{"beg",$itseg};
	    if (! defined $error{$ctfileLoc,$modeLoc,"segprd"."no".$sym}){
		$error{$ctfileLoc,$modeLoc,"segprd"."sym"}.=$sym;
		$error{$ctfileLoc,$modeLoc,"segprd"."nres".$sym}=$len;
		push(@tmpsym,$sym);
		$error{$ctfileLoc,$modeLoc,"segprd"."no".$sym}=1;
		$error{$ctfileLoc,$modeLoc,"segprd"."len".$sym}="";}
	    else {
		$error{$ctfileLoc,$modeLoc,"segprd"."nres".$sym}+=$len;
		++$error{$ctfileLoc,$modeLoc,"segprd"."no".$sym};}
	    $error{$ctfileLoc,$modeLoc,"segprd"."len".$sym}.=$len.",";
	}
				# correct predicted
	foreach $sym (@tmpsym){
	    $error{$ctfileLoc,$modeLoc,"segprd"."len".$sym}=~s/,$//g;}

				# --------------------
				# observed segments
	($Lok,$msg,%segment)=
	    &getSegment($obs);
	$error{$ctfileLoc,$modeLoc,"segobs"."no"}=$segment{"NROWS"};
	$#tmpsym=0;
	foreach $itseg (1..$segment{"NROWS"}){
	    $sym=$segment{$itseg};
	    $len=1 + $segment{"end",$itseg} - $segment{"beg",$itseg};
	    if (! defined $error{$ctfileLoc,$modeLoc,"segobs"."no".$sym}){
		$error{$ctfileLoc,$modeLoc,"segobs"."sym"}.=$sym;
		$error{$ctfileLoc,$modeLoc,"segobs"."nres".$sym}=$len;
		push(@tmpsym,$sym);
		$error{$ctfileLoc,$modeLoc,"segobs"."no".$sym}=1;
		$error{$ctfileLoc,$modeLoc,"segobs"."len".$sym}="";}
	    else {
		$error{$ctfileLoc,$modeLoc,"segobs"."nres".$sym}+=$len;
		++$error{$ctfileLoc,$modeLoc,"segobs"."no".$sym};}
	    $error{$ctfileLoc,$modeLoc,"segobs"."len".$sym}.=$len.",";
	}
				# correct observed
	foreach $sym (@tmpsym){
	    $error{$ctfileLoc,$modeLoc,"segobs"."len".$sym}=~s/,$//g;}
    }

    undef %tmperror;		# slim-is-in
    $#obs=$#prd=0;		# slim-is-in

    return(1,"ok $SBR7");
}				# end of errPrd_analyseSec

#===============================================================================
sub errPrd_wrtAcc {
    local($nfileInLoc,$fileOutLoc) = @_ ;
    local($SBR2,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   errPrd_wrtAcc               write accessibility results
#       in:                     $nfileInLoc:      number of rows (i.e. files) of %error
#       in:                     $fileOutLoc:      output file
#       in GLOBAL:              %error,@kwdRes,
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR2=""."errPrd_wrtout";   $fhoutLoc="FHOUT_"."errPrd_wrtAcc";
    
    return(&errSbr("not def nfileInLoc!",$SBR2)) if (! defined $nfileInLoc);
    return(&errSbr("not def fileOutLoc!",$SBR2)) if (! defined $fileOutLoc);

    $modeLoc="acc";
				# ------------------------------
				# local settings
    $FHTRACE="STDOUT"           if (! defined $FHTRACE);

    $tmp{"dori"}=$tmp{"doq2"}=$tmp{"doq3"}=$tmp{"doq10"}=$tmp{"docorr"}=$tmp{"dodetail"}=0;
    $tmp{"dori"}=  1            if ($par{"errPrd_dori"}   && defined $error{1,$modeLoc,"ri"});
    $tmp{"doq2"}=  1            if ($par{"errPrd_doq2"}   && defined $error{1,$modeLoc,"q2"});
    $tmp{"doq3"}=  1            if ($par{"errPrd_doq3"}   && defined $error{1,$modeLoc,"q3"});
    $tmp{"doq10"}= 1            if ($par{"errPrd_doq10"}  && defined $error{1,$modeLoc,"q10"});
    $tmp{"docorr"}=1            if ($par{"errPrd_docorr"} && defined $error{1,$modeLoc,"corr"});
    $tmp{"dodetail"}=1          if ($par{"errPrd_dodetail"});

    if (! $ra_outnum2symLoc){
	@outnum2sym2Loc=("b","e");
	@outnum2sym3Loc=("b","i","e");}
    else {
	foreach $it (1..$#{$ra_outnum2symLoc}){
	    if ($#{$ra_outnum2symLoc}>2){
		$outnum2sym3[$it]=$ra_outnum2symLoc->[$it];}
	    else {
		$outnum2sym2[$it]=$ra_outnum2symLoc->[$it];}}}

				# ------------------------------
				# ini error matrix
    if    ($par{"errPrd_doq2"}){
	$nstatePrimary=2;}
    elsif ($par{"errPrd_doq3"}){
	$nstatePrimary=3;}
    elsif ($par{"errPrd_doq10"}){
	$nstatePrimary=10;}
    else {
	$nstatePrimary=2;}
				# ------------------------------
				# compile z-score for reliability index
    $#tmp=0;
    foreach $itfile (1..$nfileInLoc){
	push(@tmp,$error{$itfile,$modeLoc,"ri"});
    }
				# average and variation
    ($ave,$var)=&stat_avevar(@tmp);
    $sig=sqrt($var);
				# problem
    if ($sig == 0){ 
	foreach $itfile (1..$nfileInLoc){
	    $error{$itfile,$modeLoc,"zri"}="0";}}
    else {
	foreach $itfile (1..$nfileInLoc){
	    $error{$itfile,$modeLoc,"zri"}=($error{$itfile,$modeLoc,"ri"}-$ave)/$sig;
	}}
				# ------------------------------
				# sums to 0
    foreach $kwd (@kwdOutAcc){
	next if (! defined $kwd || length($kwd)<1);
	$error{"sum",$modeLoc,$kwd}=0; }

				# ------------------------------
				# open file
    open($fhoutLoc,">".$fileOutLoc) || return(&errSbr("fileOutLoc=$fileOutLoc, not created",$SBR2));

				# ------------------------------
				# header
    $title=$par{"errPrd_title"};
    $title=$title               if (length($title)>1);

				# protein
    $tmp= sprintf("%-s$sep"."%4s$sep"."%4s$sep",
		  "id".$title,"nres".$title,"nali".$title);
				# reliability index
    $tmp.=sprintf("%6s$sep"."%6s$sep",
		  "<ri>".$title,"z<ri>".$title)    if ($tmp{"dori"});
				# 2 states
    $tmp.=sprintf("%4s$sep"."%4s$sep"."%5s$sep",
		  "ob".$title,"oe".$title,
		  "Q2".$title)                     if ($tmp{"doq2"});
    $tmp.=sprintf("%4s$sep"."%4s$sep"."%4s$sep"."%4s$sep",
		  "Q2b\%o".$title,"Q2b\%p".$title,
		  "Q2e\%o".$title,"Q2e\%p".$title) if ($tmp{"doq2"} && $tmp{"dodetail"});
				# 3 states
    $tmp.=sprintf("%4s$sep"."%4s$sep"."%4s$sep"."%5s$sep",
		  "ob".$title,"oi".$title,"oe".$title,
		  "Q3".$title)                     if ($tmp{"doq3"});
    $tmp.=sprintf("%4s$sep"."%4s$sep"."%4s$sep"."%4s$sep"."%4s$sep"."%4s$sep",
		  "Q3b\%o".$title,"Q3b\%p".$title,
		  "Q3i\%o".$title,"Q3i\%p".$title,
		  "Q3e\%o".$title,"Q3e\%p".$title) if ($tmp{"doq3"} && $tmp{"dodetail"});
				# 10 states
    $tmp.=sprintf("%5s$sep","Q10",
		  $title)                          if ($tmp{"doq10"});
				# correlation
    $tmp.=sprintf("%6s$sep","corr",
		  $title)                          if ($tmp{"docorr"});
    $tmp=~s/$sep$//;
    $tmp.="\n";

    print $FHTRACE  $tmp        if ($par{"verbose"});
    print $fhoutLoc $tmp;

				# --------------------------------------------------
				# body
				# --------------------------------------------------
    foreach $itfile (1..$nfileInLoc,"sum"){
				# no sum if only one
	next if ($itfile eq "sum" && $nfileInLoc==1);
				# get sums 
				#    out GLOBAL: $error{"sum",$modeLoc,$kwd}
	($Lok,$msg)=
	    &errPrd_wrtGetsum($itfile,$nfileInLoc,$modeLoc
			      ); return(&errSbrMsg("itfile=$itfile, failed on sums",
						   $msg,$SBR2)) if (! $Lok);
				# print 
	($Lok,$msg,$tmp)=
	    &errPrd_wrtOneProt($itfile,$nfileInLoc,$modeLoc
			       ); return(&errSbrMsg("itfile=$itfile, failed on writing",
						   $msg,$SBR2)) if (! $Lok);
	$tmp=~s/$sep$/\n/;

	print $FHTRACE  $tmp    if ($par{"verbose"});
	print $fhoutLoc $tmp;
    }

    close($fhoutLoc);

    return(1,"ok $sbrName");
}				# end of errPrd_wrtAcc

#===============================================================================
sub errPrd_wrtLength {
    local($nfileInLoc,$fileOutLoc,$modeLoc,$ra_outnum2symLoc) = @_ ;
    local($SBR2,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   errPrd_wrtLength            write details of secondary structure segment lengths
#       in:                     $nfileInLoc:      number of rows (i.e. files) of %error
#       in:                     $fileOutLoc:      output file
#       in:                     $modeLoc:       <sec|htm>
#       in:                     $ra_outnum2sym:pointer to e.g. 'H,E,L' 
#                               
#       in GLOBAL:              %error,@kwdRes,
#       in GLOBAL:              $sep
#       in GLOBAL:              
#                               
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR2=""."errPrd_wrtout";   $fhoutLoc="FHOUT_"."errPrd_wrtLength";
    
    return(&errSbr("not def nfileInLoc!",$SBR2)) if (! defined $nfileInLoc);
    return(&errSbr("not def fileOutLoc!",$SBR2)) if (! defined $fileOutLoc);
    return(&errSbr("not def modeLoc!",   $SBR2)) if (! defined $modeLoc);
    $ra_outnum2symLoc=0                          if (! defined $ra_outnum2symLoc);

				# ------------------------------
				# local settings
    $FHTRACE="STDOUT"           if (! defined $FHTRACE);

				# ------------------------------
				# open file
    open($fhoutLoc,">".$fileOutLoc) || return(&errSbr("fileOutLoc=$fileOutLoc, not created",$SBR2));

				# --------------------------------------------------
				# header
				# --------------------------------------------------

    $title=$par{"errPrd_title"} || "";
    $title=$title               if (length($title)>1);

				# find all symbols used
				# predicted
    @tmpsymprd= split(//,$error{"sum",$modeLoc,"segprd"."sym"});
    undef %tmp;
    @tmpsym=@tmpsymprd;
    $lenmax=0;
    foreach $sym (@tmpsymprd){ 
	$tmp{$sym}=1;
	if ($error{"sum",$modeLoc,"segprd"."lenmax".$sym} > $lenmax){
	    $lenmax=$error{"sum",$modeLoc,"segprd"."lenmax".$sym};}
    }
				# observed
    @tmpsymobs=split(//,$error{"sum",$modeLoc,"segobs"."sym"});
    foreach $sym (@tmpsymobs){
	if ($error{"sum",$modeLoc,"segobs"."lenmax".$sym} > $lenmax){
	    $lenmax=$error{"sum",$modeLoc,"segobs"."lenmax".$sym};}
	next if (defined $tmp{$sym});
	push(@tmpsym,$sym);
    }
				# change name
    @tmpsym=("H","E","L") if ($#tmpsym == 3);



				# ------------------------------
				# number observed/predicted
    $tmpwrt="";
				# numbers overall
    $tmpwrt.=    sprintf("%-10s ","# Nseg");
    foreach $sym (@tmpsym){
	$tmpwrt.=" ".$sym."(o,p):";
	foreach $kwdop ("obs","prd"){
	    $tmp=0;
	    if (defined $error{"sum",$modeLoc,"seg".$kwdop."no".$sym}){
		$tmp=$error{"sum",$modeLoc,"seg".$kwdop."no".$sym};}
	    $tmpwrt.=","        if ($kwdop=~/prd/);
	    $tmpwrt.=int($tmp);}}
    $tmpwrt.="\n";
				# percentages overall
    $tmpwrt.=    sprintf("%-10s ","# Pseg");
    foreach $sym (@tmpsym){
	$tmpwrt.=" ".$sym."(o,p):";
	foreach $kwdop ("obs","prd"){
	    $tmp=0;
	    if (defined $error{"sum",$modeLoc,"seg".$kwdop."no".$sym} &&
		defined $error{"sum",$modeLoc,"seg".$kwdop."no"}      &&
		$error{"sum",$modeLoc,"seg".$kwdop."no"}){
		$tmp=100*$error{"sum",$modeLoc,"seg".$kwdop."no".$sym}/
		    $error{"sum",$modeLoc,"seg".$kwdop."no"};}
	    $tmpwrt.=","        if ($kwdop=~/prd/);
	    $tmpwrt.=int($tmp);}}
    $tmpwrt.="\n";
				# average overall observed/predicted
    $tmpwrt.=    sprintf("%-10s ","# <seg>");
    foreach $sym (@tmpsym){
	$tmpwrt.=" ".$sym."(o,p):";
	foreach $kwdop ("obs","prd"){
	    $tmp=0;
	    if (defined $error{"sum",$modeLoc,"seg".$kwdop."no".$sym} &&
		$error{"sum",$modeLoc,"seg".$kwdop."no".$sym}){
		$tmp=$error{"sum",$modeLoc,"seg".$kwdop."nres".$sym}/
		    $error{"sum",$modeLoc,"seg".$kwdop."no".$sym};}
	    $tmpwrt.=","        if ($kwdop=~/prd/);
	    $tmpwrt.=sprintf("%6.1f",$tmp);}}
    $tmpwrt.="\n";
    print $FHTRACE  $tmpwrt     if ($par{"verbose"});
    print $fhoutLoc $tmpwrt;

				# ------------------------------
				# names:
				# protein
    $tmpwrt=      sprintf("%-s",
			  "len".$title);
    foreach $sym (@tmpsym){
	$tmpwrt.= sprintf($sep."%-6s".$sep."%-6s",
			  $sym."obs".$title,
			  $sym."prd".$title);}
    foreach $sym (@tmpsym){
	$tmpwrt.= sprintf($sep."%-6s".$sep."%-6s",
			  $sym."Pobs".$title,
			  $sym."Pprd".$title);}
    $tmpwrt.="\n";

    print $FHTRACE  $tmpwrt     if ($par{"verbose"});
    print $fhoutLoc $tmpwrt;

				# --------------------------------------------------
				# body histogram of length
				# --------------------------------------------------
    $itfile="sum";
    $tmpwrt="";
    foreach $len (1..$lenmax){
	$tmpwrt.=        sprintf("%6d",$len);
	foreach $sym (@tmpsym){
	    foreach $kwdop ("obs","prd"){
		if (defined $error{"sum",$modeLoc,"seg".$kwdop."len".$sym.$len}){
		    $tmp=$error{"sum",$modeLoc,"seg".$kwdop."len".$sym.$len};
		    $tmpwrt.=sprintf($sep."%6d",$tmp);}
		else {
		    $tmpwrt.=sprintf($sep."%6s","");}
	    }}
				# percentages
	foreach $sym (@tmpsym){
	    foreach $kwdop ("obs","prd"){
		if (defined $error{"sum",$modeLoc,"seg".$kwdop."len".$sym.$len} &&
		    defined $error{"sum",$modeLoc,"seg".$kwdop."no".$sym}  &&
		    $error{"sum",$modeLoc,"seg".$kwdop."no".$sym}){
		    $tmp=100*$error{"sum",$modeLoc,"seg".$kwdop."len".$sym.$len}/
			$error{"sum",$modeLoc,"seg".$kwdop."no".$sym};
		    $tmpwrt.=sprintf($sep."%6.1f",$tmp);}
		else {
		    $tmpwrt.=sprintf($sep."%6s","");}
		    
	    }}
	$tmpwrt.="\n";
    }
    
    print $FHTRACE  $tmpwrt     if ($par{"verbose"});
    print $fhoutLoc $tmpwrt;

    close($fhoutLoc);

    return(1,"ok $SBR2");
}				# end of errPrd_wrtLength

#===============================================================================
sub errPrd_wrtRidet {
    local($nfileInLoc,$fileOutLoc,$modeLoc,$ra_outnum2symLoc) = @_ ;
    local($SBR2,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   errPrd_wrtRidet             write details of reliability analysis
#       in:                     $nfileInLoc:      number of rows (i.e. files) of %error
#       in:                     $fileOutLoc:      output file
#       in:                     $modeLoc:       <sec|htm>
#       in:                     $ra_outnum2sym:pointer to e.g. 'H,E,L' 
#                               
#       in GLOBAL:              %error,@kwdRes,
#       in GLOBAL:              $sep
#       in GLOBAL:              
#                               
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR2=""."errPrd_wrtout";   $fhoutLoc="FHOUT_"."errPrd_wrtRidet";
    
    return(&errSbr("not def nfileInLoc!",$SBR2)) if (! defined $nfileInLoc);
    return(&errSbr("not def fileOutLoc!",$SBR2)) if (! defined $fileOutLoc);
    return(&errSbr("not def modeLoc!",   $SBR2)) if (! defined $modeLoc);
    $ra_outnum2symLoc=0                          if (! defined $ra_outnum2symLoc);

				# ------------------------------
				# local settings
    $FHTRACE="STDOUT"           if (! defined $FHTRACE);

				# ------------------------------
				# open file
    open($fhoutLoc,">".$fileOutLoc) || return(&errSbr("fileOutLoc=$fileOutLoc, not created",$SBR2));

				# --------------------------------------------------
				# header
				# --------------------------------------------------
    $title=$par{"errPrd_title"} || "";
    $title=$title               if (length($title)>1);

				# protein
    $tmpwrt=      sprintf("%-3s",
			  "ri".$title);
    $tmp="";
    foreach $kwd ("Nok","Nno",
		  "Pok","Pno",
		  "cumNok","cumNno",
		  "cumPok","cumPno"){
	$tmpwrt.= sprintf($sep."%-5s",
			  $kwd.$title);
    }
    $tmpwrt.="\n";

    print $FHTRACE  $tmpwrt     if ($par{"verbose"});
    print $fhoutLoc $tmpwrt;

				# --------------------------------------------------
				# body
				# --------------------------------------------------
    $itfile="sum";
				# purge blanks from sprintf()
    foreach $kwd (keys %error){
	next if (! defined $error{$kwd});
	$error{$kwd}=~s/\s//g;
    }
				# compile sums
    undef %tmp;
    foreach $ri (0..$error{$modeLoc,"rimax"}){
	$tmp{$ri,"cumNok"}=$tmp{$ri,"cumNno"}=0;
	$tmp{$ri,"cumPok"}=$tmp{$ri,"cumPno"}=0;
	$tmp{$ri,"Pok"}=$tmp{$ri,"Pno"}=0;
	$tmp{$ri,"Nok"}=$tmp{$ri,"Nno"}=0;
    }
    $nres=0;
    foreach $ri (0 .. $error{$modeLoc,"rimax"}){
	foreach $ri2 ($ri .. $error{$modeLoc,"rimax"}){
	    $tmp{$ri,"cumNok"}+=
		$error{"sum",$modeLoc,$ri2,"ok"} if (defined $error{"sum",$modeLoc,$ri2,"ok"});
	    $tmp{$ri,"cumNno"}+=
		$error{"sum",$modeLoc,$ri2,"no"} if (defined $error{"sum",$modeLoc,$ri2,"no"});
	}
	$nres+=$error{"sum",$modeLoc,$ri,"no"} if (defined $error{"sum",$modeLoc,$ri,"no"});
	$tmp{$ri,"Nok"}=
	    $error{"sum",$modeLoc,$ri,"ok"} if (defined $error{"sum",$modeLoc,$ri,"ok"});
	$tmp{$ri,"Nno"}=
	    $error{"sum",$modeLoc,$ri,"no"} if (defined $error{"sum",$modeLoc,$ri,"no"});
    }
				# compile percentage
    foreach $ri (0 .. $error{$modeLoc,"rimax"}){
	$tmp{$ri,"cumPok"}=
	    100*($tmp{$ri,"cumNok"}/$tmp{$ri,"cumNno"}) if (defined $tmp{$ri,"cumNno"} &&
							    $tmp{$ri,"cumNno"});
	$tmp{$ri,"Pok"}=   
	    100*($tmp{$ri,"Nok"}/$tmp{$ri,"Nno"})       if (defined $tmp{$ri,"Nno"} &&
							    $tmp{$ri,"Nno"});
	$tmp{$ri,"cumPno"}=100*($tmp{$ri,"cumNno"}/$nres);
	$tmp{$ri,"Pno"}=   100*($tmp{$ri,"Nno"}/$nres);
    }
    
				# ------------------------------
				# write
    $tmpwrt="";
    foreach $ri (0..$error{$modeLoc,"rimax"}){
	$tmpwrt.=     sprintf("%3d",$ri);

				# simple numbers first
	

	foreach $kwd ("Nok","Nno"){
	    $tmpwrt.= sprintf($sep."%5d",  $tmp{$ri,$kwd});
	}
	foreach $kwd ("Pok","Pno"){
	    $tmpwrt.= sprintf($sep."%5.1f",$tmp{$ri,$kwd});
	}
	foreach $kwd ("cumNok","cumNno"){
	    $tmpwrt.= sprintf($sep."%5d",  $tmp{$ri,$kwd});
	}
	foreach $kwd ("cumPok","cumPno"){
	    $tmpwrt.= sprintf($sep."%5.1f",$tmp{$ri,$kwd});
	}
	$tmpwrt.="\n";
    }
    
    print $FHTRACE  $tmpwrt     if ($par{"verbose"});
    print $fhoutLoc $tmpwrt;

    close($fhoutLoc);

    return(1,"ok $SBR2");
}				# end of errPrd_wrtRidet

#===============================================================================
sub errPrd_wrtSec {
    local($nfileInLoc,$fileOutLoc,$modeLoc,$ra_outnum2symLoc) = @_ ;
    local($SBR2,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   errPrd_wrtSec               write secondary structure results
#       in:                     $nfileInLoc:      number of rows (i.e. files) of %error
#       in:                     $fileOutLoc:      output file
#       in:                     $modeLoc:       <sec|htm>
#       in:                     $ra_outnum2sym:pointer to e.g. 'H,E,L' 
#       in GLOBAL:              %error,@kwdRes,
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR2=""."errPrd_wrtout";   $fhoutLoc="FHOUT_"."errPrd_wrtSec";
    
    return(&errSbr("not def nfileInLoc!",$SBR2)) if (! defined $nfileInLoc);
    return(&errSbr("not def fileOutLoc!",$SBR2)) if (! defined $fileOutLoc);
    return(&errSbr("not def modeLoc!",   $SBR2)) if (! defined $modeLoc);
    $ra_outnum2symLoc=0                          if (! defined $ra_outnum2symLoc);

				# ------------------------------
				# local settings
    $FHTRACE="STDOUT"           if (! defined $FHTRACE);

    foreach $kwd ("dori","doridetail",
		  "doq2","doq3","dobad",
		  "dosov",
		  "domatthews","doinfo","domatrix",
		  ""
		  ){
	next if (length($kwd)<1);
	$tmp{$kwd}=0;}

    $tmp{"dori"}=       1       if ($par{"errPrd_dori"}      && defined $error{1,$modeLoc,"ri"});
    $tmp{"doridetail"}= 1       if ($par{"errPrd_dori"}      && defined $error{1,$modeLoc,"ri"} &&
				    $par{"errPrd_doridetail"});
    $tmp{"doq2"}=       1       if ($par{"errPrd_doq2"}      && defined $error{1,$modeLoc,"q2"});
    $tmp{"doq3"}=       1       if ($par{"errPrd_doq3"}      && defined $error{1,$modeLoc,"q3"});
    $tmp{"dodetail"}=   1       if ($par{"errPrd_dodetail"});
    $tmp{"dobad"}=      1       if ($par{"errPrd_dobad"}     && defined $error{1,$modeLoc,"bad"});
    $tmp{"dosov"}=      1       if ($par{"errPrd_dosov"}     && defined $error{1,$modeLoc,"sov"});
    $tmp{"docontent"}=  1       if ($par{"errPrd_docontent"});

    foreach $kwd ("domatthews","doinfo","domatrix"){
	$tmp{$kwd}=1            if ($par{"errPrd_".$kwd}  && defined $error{1,$modeLoc,"mat",1,1});
    }

    if (! $ra_outnum2symLoc){
	@outnum2sym2Loc=("b","e");
	@outnum2sym3Loc=("b","i","e");}
    else {
	foreach $it (1..$#{$ra_outnum2symLoc}){
	    if ($#{$ra_outnum2symLoc}>2){
		$outnum2sym3[$it]=$ra_outnum2symLoc->[$it];}
	    else {
		$outnum2sym2[$it]=$ra_outnum2symLoc->[$it];}}}

				# ------------------------------
				# ini error matrix
    if    ($par{"errPrd_doq2"}){
	$nstatePrimary=2;}
    elsif ($par{"errPrd_doq3"}){
	$nstatePrimary=3;}
    elsif ($par{"errPrd_doq10"}){
	$nstatePrimary=10;}
    else {
	$nstatePrimary=2;}
    
				# ------------------------------
				# compile z-score for reliability index
    $#tmp=0;
    foreach $itfile (1..$nfileInLoc){
	push(@tmp,$error{$itfile,$modeLoc,"ri"});
    }
				# average and variation
    ($ave,$var)=
	&stat_avevar(@tmp);
    $sig=sqrt($var);
				# problem
    if ($sig == 0){ 
	foreach $itfile (1..$nfileInLoc){
	    $error{$itfile,$modeLoc,"zri"}="0";}}
    else {
	foreach $itfile (1..$nfileInLoc){
	    $error{$itfile,$modeLoc,"zri"}=($error{$itfile,$modeLoc,"ri"}-$ave)/$sig;
	}}
				# ------------------------------
				# sums to 0
    foreach $kwd (@kwdOutSec){
	next if (! defined $kwd || length($kwd)<1);
	$error{"sum",$modeLoc,$kwd}=0; 
    }

				# ------------------------------
				# open file
    open($fhoutLoc,">".$fileOutLoc) || return(&errSbr("fileOutLoc=$fileOutLoc, not created",$SBR2));

				# --------------------------------------------------
				# header
				# --------------------------------------------------
    $title=$par{"errPrd_title"} || "";
    $title=$title               if (length($title)>1);

				# protein
    $tmpwrt= sprintf("%-s$sep"."%4s$sep"."%4s$sep",
		     "id".$title,"nres".$title,"nali".$title);
				# zz dirty hack
    if (defined @kwdRdHeadNfar && $#kwdRdHeadNfar){
	$tmpwrt.=sprintf("%4s$sep" x $#kwdRdHeadNfar , @kwdRdHeadNfar);
    }
				# reliability index
    $tmpwrt.=sprintf("%6s$sep"."%6s$sep",
		     "<ri>".$title,"z<ri>".$title)    
	if ($tmp{"dori"});
				# 2 states
    $tmpwrt.=sprintf("%4s$sep"."%4s$sep"."%5s$sep",
		     "o".$outnum2sym2[1].$title,"o".$outnum2sym2[2].$title,"Q2".$title)
	if ($tmp{"doq2"});
    $tmpwrt.=sprintf("%4s$sep"."%4s$sep"."%4s$sep"."%4s$sep",
		     "Q2".$outnum2sym2[1]."\%o".$title,"Q2".$outnum2sym2[1]."\%p".$title,
		     "Q2".$outnum2sym2[2]."\%o".$title,"Q2".$outnum2sym2[2]."\%p".$title) 
	if ($tmp{"doq2"} && $tmp{"dodetail"});
				# 3 states
    $tmpwrt.=sprintf("%4s$sep"."%4s$sep"."%4s$sep"."%5s$sep",
		     "o".$outnum2sym3[1].$title,"o".$outnum2sym3[2].$title,"o".$outnum2sym3[3].$title,
		     "Q3".$title)
	if ($tmp{"doq3"});
				# 3 states: details
    $tmpwrt.=sprintf("%4s$sep"."%4s$sep"."%4s$sep"."%4s$sep"."%4s$sep"."%4s$sep",
		     "Q3".$outnum2sym3[1]."\%o".$title,"Q3".$outnum2sym3[1]."\%p".$title,
		     "Q3".$outnum2sym3[2]."\%o".$title,"Q3".$outnum2sym3[2]."\%p".$title,
		     "Q3".$outnum2sym3[3]."\%o".$title,"Q3".$outnum2sym3[3]."\%p".$title) 
	if ($tmp{"doq3"} && $tmp{"dodetail"});

				# SOV (2)
    $tmpwrt.=sprintf("%4s$sep"."%4s$sep"."%5s$sep",
		     "sov".$title,
		     "sov".$outnum2sym2[1].$title,"sov".$outnum2sym2[2].$title)
	if ($tmp{"dosov"} && $tmp{"doq2"} && ! $tmp{"doq3"});
				# SOV (3)
    $tmpwrt.=sprintf("%4s$sep"."%4s$sep"."%4s$sep"."%5s$sep",
		     "sov".$title,
		     "sov".$outnum2sym3[1].$title,"sov".$outnum2sym3[2].$title,"sov".$outnum2sym3[3].$title)
	if ($tmp{"dosov"} && $tmp{"doq3"});
				# BAD predictions
    $tmpwrt.=sprintf("%4s$sep",
		     "BAD")
	if ($tmp{"dobad"});
				# information
    $tmpwrt.=sprintf("%5s$sep" x 3,
                     "info".$title,"infoO".$title,"infoP".$title)
	if ($tmp{"doinfo"} && $tmp{"dodetail"});
				# prepare Matthews and matrix
    if ($tmp{"domatthews"} || $tmp{"domatrix"}){
	@tmp3=@outnum2sym2      if ($tmp{"doq2"});
	@tmp3=@outnum2sym3      if ($tmp{"doq3"});}
				# Matthews correlation
    if ($tmp{"domatthews"} && $tmp{"dodetail"}){
	$#tmp2=0; 
	foreach $tmp (@tmp3){
	    push(@tmp2,"corr".$tmp);}
	$tmpwrt.=sprintf("%4s$sep" x $#tmp2,
			 @tmp2);}
				# secondary structure content + class
    if ($tmp{"docontent"}){
				# (a) : difference correlation for content (only HE)
	$tmpwrt.=sprintf("%5s$sep" x 2,
			 "contDH".$title,"contDE".$title);
				# (b) : class
	if (! $tmp{"doq2"}){
	    $tmpwrt.=sprintf("%5s$sep"."%10s$sep" x 2,
			     "class".$title,"classO".$title,"classP".$title);
	}
    }
	
				# numbers (matrix)
    $tmp="";
    if ($tmp{"domatrix"} && $tmp{"dodetail"}){
	foreach $itobs (1..$#tmp2){
	    foreach $itprd (1..$#tmp2){
		$tmp.=sprintf("%4s,",
			      "o$itobs"."p$itprd");
	    }
	}
	$tmp=~s/\,$/$sep/;
	$tmpwrt.=$tmp;}
				# detailed reliability index ri cov acc
    if ($tmp{"dori"} && $tmp{"doridetail"}){
	$tmp="";
	foreach $ri (0..$error{$modeLoc,"rimax"}){
	    $tmp.=$ri.","; }
	$tmp=~s/\,$/$sep/;
	$tmpwrt.="rino:".$tmp."riok:".$tmp;}


    $tmpwrt=~s/$sep$//;
    $tmpwrt.="\n";

    print $FHTRACE  $tmpwrt     if ($par{"verbose"});
    print $fhoutLoc $tmpwrt;
    print "RES=",$tmpwrt        if (defined $par{"casp1"} && $par{"casp1"});

				# --------------------------------------------------
				# body
				# --------------------------------------------------
    foreach $itfile (1..$nfileInLoc,"sum"){
				# no sum if only one
	next if ($itfile eq "sum" && $nfileInLoc==1);

				# purge blanks from sprintf()
	foreach $kwd (keys %error){
	    next if (! defined $error{$kwd});
	    $error{$kwd}=~s/\s//g;}

				# get sums 
				#    out GLOBAL: $error{"sum",$modeLoc,$kwd}
	($Lok,$msg)=
	    &errPrd_wrtGetsum($itfile,$nfileInLoc,$modeLoc
			      ); return(&errSbrMsg("itfile=$itfile, failed on sums",
						   $msg,$SBR2)) if (! $Lok);
				# print 
	($Lok,$msg,$tmp)=
	    &errPrd_wrtOneProt($itfile,$nfileInLoc,$modeLoc
			       ); return(&errSbrMsg("itfile=$itfile, failed on writing",
						   $msg,$SBR2)) if (! $Lok);
	$tmp=~s/$sep$/\n/;

	print $FHTRACE  $tmp    if ($par{"verbose"});
	print $fhoutLoc $tmp;
	print "RES=",$tmp       if (defined $par{"casp1"} && $par{"casp1"});
    }
    close($fhoutLoc);

    return(1,"ok $SBR2");
}				# end of errPrd_wrtSec

#===============================================================================
sub errPrd_wrtSecmany {
    local($nfileInLoc,$fileOutLoc,$modeLoc,$ra_outnum2symLoc) = @_ ;
    local($SBR2,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   errPrd_wrtSecmany           write secondary structure results for many states
#       in:                     $nfileInLoc:      number of rows (i.e. files) of %error
#       in:                     $fileOutLoc:      output file
#       in:                     $modeLoc:       <sec|htm>
#       in:                     $ra_outnum2sym:pointer to e.g. 'H,E,L' 
#       in GLOBAL:              %error,@kwdRes,
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR2=""."errPrd_wrtout";   $fhoutLoc="FHOUT_"."errPrd_wrtSecmany";
    
    return(&errSbr("not def nfileInLoc!",$SBR2)) if (! defined $nfileInLoc);
    return(&errSbr("not def fileOutLoc!",$SBR2)) if (! defined $fileOutLoc);
    return(&errSbr("not def modeLoc!",   $SBR2)) if (! defined $modeLoc);
    $ra_outnum2symLoc=0                          if (! defined $ra_outnum2symLoc);

				# ------------------------------
				# local settings
    $FHTRACE="STDOUT"           if (! defined $FHTRACE);

    $tmp{"dori"}=       1       if ($par{"errPrd_dori"}      && defined $error{1,$modeLoc,"ri"});
    $tmp{"doridetail"}= 1       if ($par{"errPrd_dori"}      && defined $error{1,$modeLoc,"ri"} &&
				    $par{"errPrd_doridetail"});
    $tmp{"doq2"}=       1       if ($par{"errPrd_doq2"}      && defined $error{1,$modeLoc,"q2"});
    $tmp{"doq3"}=       1       if ($par{"errPrd_doq3"}      && defined $error{1,$modeLoc,"q3"});
    $tmp{"doqN"}=       1       if ($par{"errPrd_doqN"}      && defined $error{1,$modeLoc,"qN"});
    $tmp{"dodetail"}=   1       if ($par{"errPrd_dodetail"});
    $tmp{"dobad"}=      1       if ($par{"errPrd_dobad"}     && defined $error{1,$modeLoc,"bad"});
    $tmp{"dosov"}=      1       if ($par{"errPrd_dosov"}     && defined $error{1,$modeLoc,"sov"});
    $tmp{"docontent"}=  1       if ($par{"errPrd_docontent"});
    $tmp{"doclass"}=    1       if ($par{"errPrd_doclass"});


    foreach $it (1..$#{$ra_outnum2symLoc}){
	$outnum2sym[$it]=$ra_outnum2symLoc->[$it];}


				# ------------------------------
				# ini error matrix
    $nstatePrimary=$1           if ($modeLoc=~/sec(\d+)/);
    
				# ------------------------------
				# compile z-score for reliability index
    $#tmp=0;
    foreach $itfile (1..$nfileInLoc){
	push(@tmp,$error{$itfile,$modeLoc,"ri"});
    }

				# average and variation
    ($ave,$var)=
	&stat_avevar(@tmp);
    $sig=sqrt($var);
				# problem
    if ($sig == 0){ 
	foreach $itfile (1..$nfileInLoc){
	    $error{$itfile,$modeLoc,"zri"}="0";}}
    else {
	foreach $itfile (1..$nfileInLoc){
	    $error{$itfile,$modeLoc,"zri"}=($error{$itfile,$modeLoc,"ri"}-$ave)/$sig;
	}}
				# ------------------------------
				# sums to 0
    foreach $kwd (@kwdOutSec){
	next if (! defined $kwd || length($kwd)<1);
	$error{"sum",$modeLoc,$kwd}=0; 
    }

				# ------------------------------
				# open file
    open($fhoutLoc,">".$fileOutLoc) || return(&errSbr("fileOutLoc=$fileOutLoc, not created",$SBR2));

				# --------------------------------------------------
				# header
				# --------------------------------------------------
    $title=$par{"errPrd_title"} || "";
    $title=$title               if (length($title)>1);

				# protein
    $tmpwrt= sprintf("%-s$sep"."%4s$sep"."%4s$sep",
		     "id    ".$title,"nres".$title,"nali".$title);
				# reliability index
    $tmpwrt.=sprintf("%6s$sep"."%6s$sep",
		     "<ri>".$title,"z<ri>".$title)    
	if ($tmp{"dori"});

				# N states
    if ($tmp{"doqN"}){
	foreach $it (1..$nstatePrimary){
	    $tmpwrt.=sprintf("%3s$sep",
			     "o".$outnum2sym[$it].$title,
			     );
	}
	$tmpwrt.=sprintf("%5s$sep",
			 "Q".$nstatePrimary.$title);}
	
				# 3 states: details
    if ($tmp{"doqN"} && $tmp{"dodetail"}){
	foreach $itout (1..$#outnum2sym){
	    $tmpwrt.=
		sprintf("%4s$sep"."%4s$sep",
			"Q".$nstatePrimary.$outnum2sym[$itout]."o".$title,
			"Q".$nstatePrimary.$outnum2sym[$itout]."p".$title
			);
	}}

				# numbers (matrix)
    $tmp="";
    if ($tmp{"domatrix"} && $tmp{"dodetail"}){
	foreach $itobs (1..$#tmp2){
	    foreach $itprd (1..$#tmp2){
		$tmp.=sprintf("%4s,",
			      "o$itobs"."p$itprd");
	    }
	}
	$tmp=~s/\,$/$sep/;
	$tmpwrt.=$tmp;}
				# detailed reliability index ri cov acc
    if ($tmp{"dori"} && $tmp{"doridetail"}){
	$tmp="";
	foreach $ri (0..$error{$modeLoc,"rimax"}){
	    $tmp.=$ri.","; }
	$tmp=~s/\,$/$sep/;
	$tmpwrt.="rino:".$tmp."riok:".$tmp;}


    $tmpwrt=~s/$sep$//;
    $tmpwrt.="\n";

    print $FHTRACE  $tmpwrt     if ($par{"verbose"});
    print $fhoutLoc $tmpwrt;
    print "RES=",$tmpwrt        if (defined $par{"casp1"} && $par{"casp1"});

				# --------------------------------------------------
				# body
				# --------------------------------------------------
    foreach $itfile (1..$nfileInLoc,"sum"){
				# no sum if only one
	next if ($itfile eq "sum" && $nfileInLoc==1);

				# purge blanks from sprintf()
	foreach $kwd (keys %error){
	    next if (! defined $error{$kwd});
	    $error{$kwd}=~s/\s//g;}

				# get sums 
				#    out GLOBAL: $error{"sum",$modeLoc,$kwd}
	($Lok,$msg)=
	    &errPrd_wrtGetsum($itfile,$nfileInLoc,$modeLoc
			      ); return(&errSbrMsg("itfile=$itfile, failed on sums",
						   $msg,$SBR2)) if (! $Lok);
				# print 
	($Lok,$msg,$tmp)=
	    &errPrd_wrtOneProt($itfile,$nfileInLoc,$modeLoc
			       ); return(&errSbrMsg("itfile=$itfile, failed on writing",
						   $msg,$SBR2)) if (! $Lok);
	$tmp=~s/$sep$/\n/;

	print $FHTRACE  $tmp    if ($par{"verbose"});
	print $fhoutLoc $tmp;
	print "RES=",$tmp       if (defined $par{"casp1"} && $par{"casp1"});
    }
    close($fhoutLoc);

    return(1,"ok $SBR2");
}				# end of errPrd_wrtSecmany

#===============================================================================
sub errPrd_wrtGetsum {
    local($itfileLoc,$nfileInLoc2,$modeLoc) = @_ ;
    local($SBR3);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   errPrd_wrtGetsum            compiles sums over all proteins
#       in:                     $itfileLoc:     current file/protein counter
#       in:                     $nfileInLoc2:   number of files
#       in:                     $modeLoc:       <acc|sec|htm>
#       in GLOBAL:              %tmp{"do<ri|q2|q3|q10|corr>"}
#       in / out GLOBAL:        %error
#            out GLOBAL:        in particular $error{"sum",
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR3=""."errPrd_wrtGetsum";
				# check arguments
    return(&errSbr("not def itfileLoc!",  $SBR3)) if (! defined $itfileLoc);
    return(&errSbr("not def nfileInLoc2!",$SBR3)) if (! defined $nfileInLoc2);
    return(&errSbr("not def modeLoc!",    $SBR3)) if (! defined $modeLoc);

    $numoutMany=$1              if ($modeLoc=~/sec(\d+)/);
    $#kwdRdHeadNfarLoc=0;
    @kwdRdHeadNfarLoc=@kwdRdHeadNfar if (defined @kwdRdHeadNfar && $#kwdRdHeadNfar);
				# length, nali asf
    foreach $kwd ("nres","nali",
				# zz dirty hack
		  @kwdRdHeadNfarLoc
		  ){
	next if (length($kwd)<1);
	next if (! defined $error{$itfileLoc,$modeLoc,$kwd} || 
		 $error{$itfileLoc,$modeLoc,$kwd}!~/^[\s\d\.]+$/);
	$error{$itfileLoc,$modeLoc,$kwd}=~s/\s//g;
	if ($itfileLoc ne "sum"){
	    $error{"sum",$modeLoc,$kwd}+=$error{$itfileLoc,$modeLoc,$kwd};}
	else {
	    $error{"sum",$modeLoc,$kwd}=int($error{"sum",$modeLoc,$kwd}/$nfileInLoc2);
				# trim
#	    if ($error{"sum",$modeLoc,$kwd} < 1){
#		$error{"sum",$modeLoc,$kwd}=~s/^([\-\d]+\.\d\d).*$/$1/;}
#	    else {
#		$error{"sum",$modeLoc,$kwd}=~s/^([\-\d]+\.\d).*$/$1/;}
	}}
    
				# reliability
    if ($tmp{"dori"}){
	foreach $kwd ("ri","zri"){
	    next if (! defined $error{$itfileLoc,$modeLoc,$kwd} || 
		     $error{$itfileLoc,$modeLoc,$kwd}!~/^[\-\s\d\.]+$/);
	    $error{$itfileLoc,$modeLoc,$kwd}=~s/\s//g;
	    if ($itfileLoc ne "sum"){
		$error{"sum",$modeLoc,$kwd}+=$error{$itfileLoc,$modeLoc,$kwd};}
	    else {
		$error{"sum",$modeLoc,$kwd}=$error{"sum",$modeLoc,$kwd}/$nfileInLoc2;
				# trim
		$error{"sum",$modeLoc,$kwd}=~s/^([\-\d]+\.\d).*$/$1/;}
	}

	if ($tmp{"doridetail"} && defined $error{$itfileLoc,$modeLoc,"riocc"}){
	    foreach $ri (0..$error{$modeLoc,"rimax"}){
		if ($itfileLoc ne "sum"){
		    if (defined $error{$itfileLoc,$modeLoc,$ri,"ok"}){
			$error{"sum",$modeLoc,$ri,"ok"}+=$error{$itfileLoc,$modeLoc,$ri,"ok"};}
		    if (defined $error{$itfileLoc,$modeLoc,$ri,"no"}){
			$error{"sum",$modeLoc,$ri,"no"}+=$error{$itfileLoc,$modeLoc,$ri,"no"};}}
		else {
		    $error{"sum",$modeLoc,$ri,"ok"}=0;
		    $error{"sum",$modeLoc,$ri,"no"}=0;
		    if (defined $error{"sum",$modeLoc,$ri,"no"}){
			$error{"sum",$modeLoc,$ri,"no"}=
			    100*$error{"sum",$modeLoc,$ri,"no"}/$error{"nres"};
				# trim
			$error{"sum",$modeLoc,$ri,"no"}=~s/(\.\d).*$/$1/g;}

		    if (defined $error{"sum",$modeLoc,$ri,"ok"}){
			$error{"sum",$modeLoc,$ri,"ok"}=
			    100*$error{"sum",$modeLoc,$ri,"ok"}/$error{"sum",$modeLoc,$ri,"no"};
				# trim
			$error{"sum",$modeLoc,$ri,"ok"}=~s/(\.\d).*$/$1/g;}
		}
	    }
	}}

				# 2 states
    if ($tmp{"doq2"}){
	foreach $kwd ("q2","n2o"){
	    next if (! defined $error{$itfileLoc,$modeLoc,$kwd} || 
		     $error{$itfileLoc,$modeLoc,$kwd}!~/^[\d\.]+$/);
	    if ($itfileLoc ne "sum"){
		$error{"sum",$modeLoc,$kwd}+=$error{$itfileLoc,$modeLoc,$kwd};}
	    else {
		$error{"sum",$modeLoc,$kwd}=$error{"sum",$modeLoc,$kwd}/$nfileInLoc2;
				# trim
		$error{"sum",$modeLoc,$kwd}=~s/(\.\d).*$/$1/g;}
	}

				# get QH QL %o%p from matrix
	foreach $it1 (1..2){
	    $cto[$it1]=0;$ctp[$it1]=0;$oko[$it1]=0;$okp[$it1]=0;
	    foreach $it2 (1..2){
				# perc of observed
		if (defined $error{$itfileLoc,$modeLoc,"mat",$it1,$it2} &&
		    $error{$itfileLoc,$modeLoc,"mat",$it1,$it2} =~ /\d/){
		    $cto[$it1]+=$error{$itfileLoc,$modeLoc,"mat",$it1,$it2};
		    $oko[$it1]+=$error{$itfileLoc,$modeLoc,"mat",$it1,$it2} if ($it1 == $it2);}
				# perc of predicted
		if (defined $error{$itfileLoc,$modeLoc,"mat",$it2,$it1} &&
		    $error{$itfileLoc,$modeLoc,"mat",$it2,$it1} =~ /\d/){
		    $ctp[$it1]+=$error{$itfileLoc,$modeLoc,"mat",$it2,$it1};
		    $okp[$it1]+=$error{$itfileLoc,$modeLoc,"mat",$it2,$it1} if ($it1 == $it2);}
	    }}
				# now all states
	foreach $it (1..2){
	    if ($cto[$it]){
		$error{"sum",$modeLoc,"q2o",$it}=int(100*($oko[$it]/$cto[$it]));
		if ($itfileLoc ne "sum"){
		    $error{"sum",$modeLoc,"n2o",$it}=0;
		    $error{"sum",$modeLoc,"n2o",$it}=int(100*$cto[$it]/$error{"nres"})
			if (defined $error{"nres"} && $error{"nres"} > 0);}
		else {
		    $error{"sum",$modeLoc,"n2o",$it}=($cto[$it]/$nfileInLoc2);
				# trim
		    $error{"sum",$modeLoc,"n2o",$it}=~s/(\.\d).*$/$1/g;}}
	    if ($ctp[$it]){
		$error{"sum",$modeLoc,"q2p",$it}=int(100*($okp[$it]/$ctp[$it]));}
	}}

				# 3 states
    if ($tmp{"doq3"}){
	foreach $kwd ("q3","n3o"){
	    next if (! defined $error{$itfileLoc,$modeLoc,$kwd} || 
		     $error{$itfileLoc,$modeLoc,$kwd}!~/^[\d\.]+$/);
	    if ($itfileLoc ne "sum"){
		$error{"sum",$modeLoc,$kwd}+=$error{$itfileLoc,$modeLoc,$kwd};}
	    else {
		$error{"sum",$modeLoc,$kwd}=$error{"sum",$modeLoc,$kwd}/$nfileInLoc2;
				# trim
		$error{"sum",$modeLoc,$kwd}=~s/(\.\d).*$/$1/g;}
	}
				# get QH QE QL %o%p from matrix
	foreach $it1 (1..3){
	    $cto[$it1]=0;$ctp[$it1]=0;$oko[$it1]=0;$okp[$it1]=0;
	    foreach $it2 (1..3){
				# perc of observed
		if (defined $error{$itfileLoc,$modeLoc,"mat",$it1,$it2} &&
		    $error{$itfileLoc,$modeLoc,"mat",$it1,$it2} =~ /\d/){
		    $cto[$it1]+=$error{$itfileLoc,$modeLoc,"mat",$it1,$it2};
		    $oko[$it1]+=$error{$itfileLoc,$modeLoc,"mat",$it1,$it2} if ($it1 == $it2);}
				# perc of predicted
		if (defined $error{$itfileLoc,$modeLoc,"mat",$it2,$it1} &&
		    $error{$itfileLoc,$modeLoc,"mat",$it2,$it1} =~ /\d/){
		    $ctp[$it1]+=$error{$itfileLoc,$modeLoc,"mat",$it2,$it1};
		    $okp[$it1]+=$error{$itfileLoc,$modeLoc,"mat",$it2,$it1} if ($it1 == $it2);}
	    }}
				# now all states
	foreach $it (1..3){
	    if ($cto[$it]){
		$error{"sum",$modeLoc,"q3o",$it}=int(100*($oko[$it]/$cto[$it]));
		if ($itfileLoc ne "sum"){
		    $error{"sum",$modeLoc,"n3o",$it}=0;
		    $error{"sum",$modeLoc,"n3o",$it}=int(100*$cto[$it]/$error{"nres"})
			if (defined $error{"nres"} && $error{"nres"} > 0);}
		else {
		    $error{"sum",$modeLoc,"n3o",$it}=($cto[$it]/$nfileInLoc2);
				# trim
		    $error{"sum",$modeLoc,"n3o",$it}=~s/(\.\d).*$/$1/g;}}
	    if ($ctp[$it]){
		$error{"sum",$modeLoc,"q3p",$it}=int(100*($okp[$it]/$ctp[$it]));}
	}}

				# many states
    if ($tmp{"doqN"}){
	foreach $kwd ("qN"){
	    next if (! defined $error{$itfileLoc,$modeLoc,$kwd} || 
		     $error{$itfileLoc,$modeLoc,$kwd}!~/^[\d\.]+$/);
	    if ($itfileLoc ne "sum"){
		$error{"sum",$modeLoc,$kwd}+=$error{$itfileLoc,$modeLoc,$kwd};}
	    else {
		$error{"sum",$modeLoc,$kwd}=$error{"sum",$modeLoc,$kwd}/$nfileInLoc2;
				# trim
		$error{"sum",$modeLoc,$kwd}=~s/(\.\d).*$/$1/g;
	    }
	}
				# get QH QE QL %o%p from matrix
	foreach $it1 (1..$numoutMany){
	    $cto[$it1]=$ctp[$it1]=$oko[$it1]=$okp[$it1]=0;
	    foreach $it2 (1..$numoutMany){
				# perc of observed
		if (defined $error{$itfileLoc,$modeLoc,"mat",$it1,$it2} &&
		    $error{$itfileLoc,$modeLoc,"mat",$it1,$it2} =~ /\d/){
		    $cto[$it1]+=$error{$itfileLoc,$modeLoc,"mat",$it1,$it2};
		    $oko[$it1]+=$error{$itfileLoc,$modeLoc,"mat",$it1,$it2} if ($it1 == $it2);}
				# perc of predicted
		if (defined $error{$itfileLoc,$modeLoc,"mat",$it2,$it1} &&
		    $error{$itfileLoc,$modeLoc,"mat",$it2,$it1} =~ /\d/){
		    $ctp[$it1]+=$error{$itfileLoc,$modeLoc,"mat",$it2,$it1};
		    $okp[$it1]+=$error{$itfileLoc,$modeLoc,"mat",$it2,$it1} if ($it1 == $it2);}
	    }
	}

				# now all states
	$sumxx=0;
	foreach $it (1..$numoutMany){
	    if ($cto[$it]){
		$sumxx+=$cto[$it];
		$error{"sum",$modeLoc,"qNo",$it}=int(100*($oko[$it]/$cto[$it]));
		if ($itfileLoc ne "sum"){
		    $error{"sum",$modeLoc,"nNo",$it}=0;
		    $error{"sum",$modeLoc,"nNo",$it}=int(100*$cto[$it]/$error{"nres"})
			if (defined $error{"nres"} && $error{"nres"} > 0);}
		else {
		    $error{"sum",$modeLoc,"nNo",$it}=int(100*($cto[$it]/$error{"nres"}));
#		    $error{"sum",$modeLoc,"nNo",$it}=($cto[$it]/$nfileInLoc2);
				# trim
		    $error{"sum",$modeLoc,"nNo",$it}=~s/(\.\d).*$/$1/g;}

	    }
	    if ($ctp[$it]){
		$error{"sum",$modeLoc,"qNp",$it}=int(100*($okp[$it]/$ctp[$it]));}
	}
				# temporary: write confusion matrix
	if ($itfileLoc =~ /sum/){
	    print "--- confusion matrix for $itfileLoc\n";
	    print "  p/o |";
	    foreach $it (1..$numoutMany){
		printf "%5s ",$it.":".$outnum2sym[$it]; }
	    printf " | %5s | ","Sobs";
	    foreach $it (1..$numoutMany){
		printf "%4s ","p".$outnum2sym[$it];}
	    printf "| %5s\n","Pobs";
	    
	    printf "%6s+","+-----";foreach $it1 (1..$numoutMany){printf "%5s-","-----";}printf "-+-%5s-+-","-----";foreach $it1 (1..$numoutMany){printf "%4s-","----";}printf "+-%5s-+\n","-----";
	    $sumxx=0;
	    foreach $it1 (1..$numoutMany){
		printf "%5s |",$it1.":".$outnum2sym[$it1];
		foreach $it2 (1..$numoutMany){
		    printf "%5d ",$error{$itfileLoc,$modeLoc,"mat",$it1,$it2};
		}
		printf " | %5d | ",$cto[$it1];
		$sumxx+=$cto[$it1];
				# percentages
		foreach $it2 (1..$numoutMany){
		    printf "%4d ",int(100*$error{$itfileLoc,$modeLoc,"mat",$it1,$it2}/$error{"nres"});
		}
		printf "| %5.1f\n",100*($cto[$it1]/$error{"nres"});
	    }

	    printf "%6s+","+-----";foreach $it1 (1..$numoutMany){printf "%5s-","-----";}printf "-+-%5s-+-","-----";foreach $it1 (1..$numoutMany){printf "%4s-","----";}printf "+-%5s-+\n","-----";

	    printf "%5s |","Sprd";
	    foreach $it1 (1..$numoutMany){
		printf "%5d ",$ctp[$it1];
	    }
	    printf " | %5d | ",$sumxx;
	    $sumxxp=0;
	    foreach $it1 (1..$numoutMany){
		printf "%4.1f ",100*($ctp[$it1]/$error{"nres"});
		$sumxxp+=100*($ctp[$it1]/$error{"nres"});
	    }
	    printf "| %5.1f\n",$sumxxp;
	}
    }

				# SOV
    if ($tmp{"dosov"}){
	foreach $kwd ("sov","sovH","sovE","sovL"){
	    next if ($tmp{$kwd});
	    next if (! defined $error{$itfileLoc,$modeLoc,$kwd} ||
		     $error{$itfileLoc,$modeLoc,$kwd}!~/^[\-\s\d\.]+$/);
	    $error{$itfileLoc,$modeLoc,$kwd}=~s/\s//g;
	    if ($itfileLoc ne "sum"){
		$error{"sum",$modeLoc,$kwd}+=$error{$itfileLoc,$modeLoc,$kwd};
	    }
	    else {
		$error{"sum",$modeLoc,$kwd}= 
		    sprintf ("%5.1f",$error{"sum",$modeLoc,$kwd}/$nfileInLoc2);
		$error{"sum",$modeLoc,$kwd}=~s/\s//g; 
	    }
	}}

				# BAD predictions
    foreach $kwd ("bad"){
	next if ($tmp{$kwd});
	next if (! defined $error{$itfileLoc,$modeLoc,$kwd} ||
		 $error{$itfileLoc,$modeLoc,$kwd}!~/^[\-\s\d\.]+$/);
	$error{$itfileLoc,$modeLoc,$kwd}=~s/\s//g;
	if ($itfileLoc ne "sum"){
	    $error{"sum",$modeLoc,$kwd}+=$error{$itfileLoc,$modeLoc,$kwd};
	}
	else {
	    $error{"sum",$modeLoc,$kwd}= 
		sprintf ("%5.1f",$error{"sum",$modeLoc,$kwd}/$nfileInLoc2);
	    $error{"sum",$modeLoc,$kwd}=~s/\s//g; 
	}
    }

				# 10 states + correlation
    foreach $kwd ("q10","corr"){
	next if ($tmp{$kwd});
	next if (! defined $error{$itfileLoc,$modeLoc,$kwd} ||
		 $error{$itfileLoc,$modeLoc,$kwd}!~/^[\-\s\d\.]+$/);
	$error{$itfileLoc,$modeLoc,$kwd}=~s/\s//g;
	if ($itfileLoc ne "sum"){
	    $error{"sum",$modeLoc,$kwd}+=$error{$itfileLoc,$modeLoc,$kwd};}
	else {
	    $error{"sum",$modeLoc,$kwd}= $error{"sum",$modeLoc,$kwd}/$nfileInLoc2;
				# trim
	    $error{"sum",$modeLoc,$kwd}= ~s/(\.\d\d\d).*$/$1/g;}
    }

				# Matthews
    if ($tmp{"domatthews"} && $tmp{"dodetail"}){
	foreach $it (1..$nstatePrimary){
	    if ($itfileLoc ne "sum"){
		$error{"sum",$modeLoc,"matthews",$it}+=
		    $error{$itfileLoc,$modeLoc,"matthews",$it};}
            else {
                $error{"sum",$modeLoc,"matthews",$it}=
                    $error{"sum",$modeLoc,"matthews",$it}/$nfileInLoc2;
				# trim
                $error{"sum",$modeLoc,"matthews",$it}=~s/(\.\d\d\d).*$/$1/g;}
        }}

				# information
    if ($tmp{"doinfo"}     && $tmp{"dodetail"}){
	foreach $kwd ("obs","prd"){
            if ($itfileLoc ne "sum"){
                $error{"sum",$modeLoc,"info",$kwd}+=
                    $error{$itfileLoc,$modeLoc,"info",$kwd};}
            else {
                $error{"sum",$modeLoc,"info",$kwd}=
                    $error{"sum",$modeLoc,"info",$kwd}/$nfileInLoc2;
				# trim
                $error{"sum",$modeLoc,"info",$kwd}=~s/(\.\d\d\d).*$/$1/g;}
	}}
				# matrix
    if ($tmp{"dodetail"}){
	foreach $itobs (1..$nstatePrimary){
	    foreach $itprd (1..$nstatePrimary){
		if ($itfileLoc ne "sum"){
		    $error{"sum",$modeLoc,"mat",$itobs,$itprd}+=
			$error{$itfileLoc,$modeLoc,"mat",$itobs,$itprd};}
            }
	}}
				# content
    if ($tmp{"docontent"} && $nstatePrimary == 3){
				# difference in content
				# note: restrict to H,E !
	foreach $it (1 .. 2){
	    if ($itfileLoc ne "sum"){
		$error{"sum",$modeLoc,"contD".$it}+=
		    $error{$itfileLoc,$modeLoc,"contD".$it};
	    }
	    else {
		$error{"sum",$modeLoc,"contD".$it}=
		    $error{"sum",$modeLoc,"contD".$it}/$nfileInLoc2;
				# trim
		$error{"sum",$modeLoc,"contD".$it}=~s/(\.\d).*$/$1/;
	    }
	}
	if (! $tmp{"doq2"}){
				# class
	    if ($itfileLoc ne "sum"){
		$error{"sum",$modeLoc,"class"}+=
		    $error{$itfileLoc,$modeLoc,"class"};
	    }
	    else {
		$error{"sum",$modeLoc,"class"}=$error{"sum",$modeLoc,"class"}/$nfileInLoc2;
				# trim
		$error{"sum",$modeLoc,"class"}=~s/(\.\d).*$/$1/g;
	    }
	    
				# separate out
	    if ($itfileLoc ne "sum"){
		if ($error{$itfileLoc,$modeLoc,"classo"} eq
		    $error{$itfileLoc,$modeLoc,"classp"}){
		    foreach $itclass (1..4){
			next if ($error{$itfileLoc,$modeLoc,"classo"} ne $par{"class",$itclass});
			next if ($error{$itfileLoc,$modeLoc,"classp"} ne $par{"class",$itclass});
			++$error{"sum",$modeLoc,"class".$itclass};
			last; 
		    }
		}
				# get sum of observed
		foreach $itclass (1..4){
		    next if ($error{$itfileLoc,$modeLoc,"classo"} ne $par{"class",$itclass});
		    ++$error{"sum",$modeLoc,"class".$itclass."obsno"}; }
				# get sum of predicted
		foreach $itclass (1..4){
		    next if ($error{$itfileLoc,$modeLoc,"classp"} ne $par{"class",$itclass});
		    ++$error{"sum",$modeLoc,"class".$itclass."prdno"}; }
	    }
				# --------------------
				# SUMS
	    else {
		foreach $itclass (1..4){
				# percentage of observed
		    if (! defined $error{"sum",$modeLoc,"class".$itclass."obsno"} ||
			! defined $error{"sum",$modeLoc,"class".$itclass}         ||
			$error{"sum",$modeLoc,"class".$itclass."obsno"} < 1){
			$error{"sum",$modeLoc,"class".$itclass."obs"}=0;}
		    else {
			$error{"sum",$modeLoc,"class".$itclass."obs"}=
			    $error{"sum",$modeLoc,"class".$itclass}/
				$error{"sum",$modeLoc,"class".$itclass."obsno"};
				# trim
			$error{"sum",$modeLoc,"class".$itclass."obs"}=
			    100*(int($error{"sum",$modeLoc,"class".$itclass."obs"}));}
				# percentage of predicted
		    if (! defined $error{"sum",$modeLoc,"class".$itclass."prdno"} ||
			! defined $error{"sum",$modeLoc,"class".$itclass}         ||
			$error{"sum",$modeLoc,"class".$itclass."prdno"} < 1){
			$error{"sum",$modeLoc,"class".$itclass."prd"}=0;}
		    else {
			$error{"sum",$modeLoc,"class".$itclass."prd"}=
			    $error{"sum",$modeLoc,"class".$itclass}/
				$error{"sum",$modeLoc,"class".$itclass."prdno"};
				# trim
			$error{"sum",$modeLoc,"class".$itclass."prd"}=
			    100*(int($error{"sum",$modeLoc,"class".$itclass."prd"}));}
		}
	    }
	}
    }
				# ------------------------------
				# get sum for segments
				# ------------------------------
    if ($par{"errPrd_dolength"} && $itfileLoc ne "sum"){
	foreach $kwdop ("obs","prd"){
	    $error{"sum",$modeLoc,"seg".$kwdop."no"}=
		0 if (! defined $error{"sum",$modeLoc,"seg".$kwdop."no"});
	    @tmpsym=split(//,$error{$itfileLoc,$modeLoc,"seg".$kwdop."sym"});
	    foreach $sym (@tmpsym){
		$error{"sum",$modeLoc,"seg".$kwdop."no"}+=
		    $error{$itfileLoc,$modeLoc,"seg".$kwdop."no".$sym};
		if (! defined $error{"sum",$modeLoc,"seg".$kwdop."no".$sym}){
		    $error{"sum",$modeLoc,"seg".$kwdop."sym"}.=$sym;
		    $error{"sum",$modeLoc,"seg".$kwdop."no".$sym}=
			$error{$itfileLoc,$modeLoc,"seg".$kwdop."no".$sym};
		    $error{"sum",$modeLoc,"seg".$kwdop."nres".$sym}=
			$error{$itfileLoc,$modeLoc,"seg".$kwdop."nres".$sym};}
		else {
		    $error{"sum",$modeLoc,"seg".$kwdop."no".$sym}+=
			$error{$itfileLoc,$modeLoc,"seg".$kwdop."no".$sym};
		    $error{"sum",$modeLoc,"seg".$kwdop."nres".$sym}+=
			$error{$itfileLoc,$modeLoc,"seg".$kwdop."nres".$sym};}
		@tmplen=split(/,/,$error{$itfileLoc,$modeLoc,"seg".$kwdop."len".$sym});
		$error{"sum",$modeLoc,"seg".$kwdop."lenmax".$sym}=0
		    if (! defined $error{"sum",$modeLoc,"seg".$kwdop."lenmax".$sym});
		foreach $len (@tmplen){
		    if (! defined $error{"sum",$modeLoc,"seg".$kwdop."len".$sym.$len}){
				# longer?
			$error{"sum",$modeLoc,"seg".$kwdop."lenmax".$sym}=
			    $len if ($len > $error{"sum",$modeLoc,"seg".$kwdop."lenmax".$sym});
			$error{"sum",$modeLoc,"seg".$kwdop."len".$sym.$len}=1;}
		    else {
			++$error{"sum",$modeLoc,"seg".$kwdop."len".$sym.$len};}
		}
	    }}}

    return(1,"ok $SBR2");
}				# end of errPrd_wrtGetsum

#===============================================================================
sub errPrd_wrtOneProt {
    local($itfileLoc,$nfileInLoc2,$modeLoc) = @_ ;
    local($SBR3);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   errPrd_wrtOneProt           finally writes the error for one protein
#       in:                     $itfileLoc:     current file/protein counter
#       in:                     $nfileInLoc2:   number of files
#       in:                     $modeLoc:       <acc|sec|htm>
#       in GLOBAL:              %tmp{"do<ri|q2|q3|q10|corr>"}
#       in / out GLOBAL:        %error
#            out GLOBAL:        in particular $error{"sum",
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR3=""."errPrd_wrtOneProt";
				# check arguments
    return(&errSbr("not def itfileLoc!",  $SBR3)) if (! defined $itfileLoc);
    return(&errSbr("not def nfileInLoc2!",$SBR3)) if (! defined $nfileInLoc2);
    return(&errSbr("not def modeLoc!",    $SBR3)) if (! defined $modeLoc);
    
    $numoutMany=$1              if ($modeLoc=~/sec(\d+)/);

				# ------------------------------
				# protein info
				# update id
    $idtmp=$error{$itfile,$modeLoc,"id"};
    if ($itfile =~/^sum$/i){
	if (defined $par{"errPrd_title"}  &&
	    length($par{"errPrd_title"}) > 1){
	    $idtmp=$itfile."(".$par{"errPrd_title"}.")=".$nfileInLoc;
	}
	else {
	    $idtmp=$itfile.$nfileInLoc;}
	$idtmp.=" " x (6-length($idtmp));}

    @tmp2=($idtmp);
    foreach $kwd ("nres","nali"){
	if (! defined $error{$itfile,$modeLoc,$kwd}){
	    push(@tmp2,0);}
	else {
	    push(@tmp2,$error{$itfile,$modeLoc,$kwd});}}
    $tmpWrt= sprintf("%-s$sep"."%4s$sep"."%4s$sep",@tmp2);
				# zz dirty hack
    if (defined @kwdRdHeadNfar && $#kwdRdHeadNfar){
	$#tmp2=0;
	foreach $kwd (@kwdRdHeadNfar){
	    if (! defined $error{$itfile,$modeLoc,$kwd}){
		push(@tmp2,0);}
	    else {
		push(@tmp2,$error{$itfile,$modeLoc,$kwd});}}
	$tmpWrt.= sprintf("%4s$sep" x $#tmp2 ,@tmp2);
    }
    
				# ------------------------------
				# reliability index
    if ($tmp{"dori"}){
	$#tmp2=0;
	foreach $kwd ("ri","zri"){
	    if (! defined $error{$itfile,$modeLoc,$kwd}){
		push(@tmp2,0);}
	    else {
		push(@tmp2,$error{$itfile,$modeLoc,$kwd});}}
	$tmpWrt.=sprintf("%5.2f$sep"."%6.3f$sep",@tmp2);}

				# ------------------------------
				# 2 states
    if ($tmp{"doq2"}){
	$#tmp2=0;
				# N2
	foreach $kwd ("n2o"){
	    foreach $it (1..2){
		if (! defined $error{$itfile,$modeLoc,$kwd,$it}){
		    push(@tmp2,0);}
		else {
		    push(@tmp2,$error{$itfile,$modeLoc,$kwd,$it});}}}
	$kwd="q2";		# Q2
	if (! defined $error{$itfile,$modeLoc,$kwd}){
	    push(@tmp2,0);}
	else { 
	    push(@tmp2,$error{$itfile,$modeLoc,$kwd});}
	$tmpWrt.=sprintf("%4d$sep"."%4d$sep"."%5.1f$sep",@tmp2);

				# detail
	if ($tmp{"dodetail"}){
	    $#tmp2=0;
	    foreach $it (1..2){
		foreach $kwd ("q2o","q2p"){
		    if (! defined $error{$itfile,$modeLoc,$kwd,$it}){
			push(@tmp2,0);}
		    else {
			push(@tmp2,$error{$itfile,$modeLoc,$kwd,$it});
		    }
		}
	    }
	    $tmpWrt.=sprintf("%4d$sep"."%4d$sep"."%4d$sep"."%4d$sep",@tmp2);
	}}

				# ------------------------------
				# 3 states
    if ($tmp{"doq3"}){
	$#tmp2=0;
				# N3
	foreach $kwd ("n3o"){
	    foreach $it (1..3){
		if (! defined $error{$itfile,$modeLoc,$kwd,$it}){
		    push(@tmp2,0);}
		else {
		    push(@tmp2,$error{$itfile,$modeLoc,$kwd,$it});}
	    }}
	$tmpWrt.=sprintf("%4d$sep"."%4d$sep"."%4d$sep",@tmp2);
	$kwd="q3";		# Q3
	$val=0;
	$val=$error{$itfile,$modeLoc,$kwd} if (defined $error{$itfile,$modeLoc,$kwd});
	$tmpWrt.=sprintf("%5.1f$sep",$val);

				# detail
	if ($tmp{"dodetail"}){
	    foreach $it (1..3){	# loop over 3 states
		$#tmp2=0;
		foreach $kwd ("q3o","q3p"){
		    if (! defined $error{$itfile,$modeLoc,$kwd,$it}){
			push(@tmp2,0);}
		    else {
			push(@tmp2,$error{$itfile,$modeLoc,$kwd,$it});
		    }
		}
		$tmpWrt.=sprintf("%4d$sep"."%4d$sep",@tmp2);
	    }
	}}

				# ------------------------------
				# many states
    if ($tmp{"doqN"}){
	$#tmp2=0;
				# NN (count observed states)
	foreach $kwd ("nNo"){
	    foreach $it (1..$numoutMany){
		if (! defined $error{$itfile,$modeLoc,$kwd,$it}){
		    push(@tmp2,0);}
		else {
		    push(@tmp2,int($error{$itfile,$modeLoc,$kwd,$it}));}}}
	$kwd="qN";		# QN
	$valqN=0;
	$valqN=$error{$itfile,$modeLoc,$kwd} if (defined $error{$itfile,$modeLoc,$kwd});

	$tmpWrt.=sprintf("%3d$sep" x $#tmp2 ."%5.1f$sep",
			 @tmp2,$valqN);

				# detail
	if ($tmp{"dodetail"}){
	    foreach $it (1..$numoutMany){
		$#tmp2=0;
		foreach $kwd ("qNo","qNp"){
		    if (! defined $error{$itfile,$modeLoc,$kwd,$it}){
			push(@tmp2,0);}
		    else {
			push(@tmp2,int($error{$itfile,$modeLoc,$kwd,$it}));}
		}
		$tmpWrt.=sprintf("%4d$sep"."%4d$sep",
				 @tmp2);
	    }}
    }
    


				# ------------------------------
				# SOV segment score
    if ($tmp{"dosov"}){
	$#tmp2=0;
	foreach $kwd ("sov","sovH","sovE","sovL"){
	    if (! defined $error{$itfile,$modeLoc,$kwd}){
		push(@tmp2,0);}
	    else {
		push(@tmp2,$error{$itfile,$modeLoc,$kwd});}
	}
	$tmpWrt.=sprintf("%5.1f$sep%4d$sep%4d$sep%4d$sep",
			 $tmp2[1],int($tmp2[2]),int($tmp2[3]),int($tmp2[4]));
    }

				# ------------------------------
				# BAD predictions
    if ($tmp{"dobad"}){
	$#tmp2=0;
	$kwd="bad";
	if (! defined $error{$itfile,$modeLoc,$kwd}){
	    push(@tmp2,0);}
	else {
	    push(@tmp2,$error{$itfile,$modeLoc,$kwd});}
	$tmpWrt.=sprintf("%5.1f$sep",@tmp2);}

				# ------------------------------
				# 10 states + correlation
    if ($tmp{"doq10"}){
	$#tmp2=0;
	$kwd="q10";
	if (! defined $error{$itfile,$modeLoc,$kwd}){
	    push(@tmp2,0);}
	else {
	    push(@tmp2,$error{$itfile,$modeLoc,$kwd});}
	$tmpWrt.=sprintf("%5.1f$sep",@tmp2);}

				# ------------------------------
				# correlation
    if ($tmp{"docorr"}){
	$#tmp2=0;
	$kwd="corr";
	if (! defined $error{$itfile,$modeLoc,$kwd}){
	    push(@tmp2,0);}
	else {
	    push(@tmp2,$error{$itfile,$modeLoc,$kwd});}
	$tmpWrt.=sprintf("%5.3f$sep",@tmp2);}
				# ------------------------------
				# info
    if ($tmp{"doinfo"} && $tmp{"dodetail"}){
	$#tmp2=0;
	$kwd="info";
	$sum=0;
	foreach $kwd2 ("obs","prd"){
	    if (! defined $error{$itfile,$modeLoc,$kwd,$kwd2}){
		push(@tmp2,0);}
	    else {
		push(@tmp2,$error{$itfile,$modeLoc,$kwd,$kwd2});
		$sum+=$error{$itfile,$modeLoc,$kwd,$kwd2};
	    }}
	
	$tmpWrt.=sprintf("%5.3f$sep". "%5.2f$sep" x $#tmp2,
			 ($sum/2),@tmp2);}
				# ------------------------------
				# Matthews
    if ($tmp{"domatthews"} && $tmp{"dodetail"}){
	$#tmp2=0;
	$kwd="matthews";
	foreach $it (1..$nstatePrimary){
	    if (! defined $error{$itfile,$modeLoc,$kwd,$it}){
		push(@tmp2,0);}
	    else {
		push(@tmp2,$error{$itfile,$modeLoc,$kwd,$it});}}
	$tmpWrt.=sprintf("%5.3f$sep" x $#tmp2,
			 @tmp2);}
				# ------------------------------
				# sec str content
    if ($tmp{"docontent"}){
				# content difference (2 states = HE)
	$kwd="contD";
	$#tmp2=0;
	foreach $it (1,2){
	    if (! defined $error{$itfile,$modeLoc,$kwd.$it}){
		push(@tmp2,0);}
	    else {
		push(@tmp2,$error{$itfile,$modeLoc,$kwd.$it});}
	}
	$tmpWrt.=sprintf("%5.2f$sep" x $#tmp2,
			 @tmp2);
	if ($tmp{"doclass"} && ! $tmp{"doq2"}){
				# class (4 states)
	    $kwd="class";
				# class : obs - prd
	    if ($itfile !~ /^sum/){
		$tmpWrt.=sprintf("%5.1f$sep",
				 $error{$itfile,$modeLoc,$kwd});
		$tmpWrt.=sprintf("%-s$sep%-s$sep",
				 $error{$itfile,$modeLoc,$kwd."o"},
				 $error{$itfile,$modeLoc,$kwd."p"});
	    }
				# sum
	    else {
		$tmpWrt.=sprintf("%5.1f$sep",
				 $error{$itfile,$modeLoc,$kwd});
		$tmpo=$tmpp="";
		foreach $itclass (1..4){
		    if (defined $error{$itfile,$modeLoc,$kwd.$itclass."obs"}){
			$tmpo.=$error{$itfile,$modeLoc,$kwd.$itclass."obs"}.",";
		    } else { $tmpo.=" ,";}
		    if (defined $error{$itfile,$modeLoc,$kwd.$itclass."prd"}){
			$tmpp.=$error{$itfile,$modeLoc,$kwd.$itclass."prd"}.",";
		    } else { $tmpp.=" ,";}
				# 
		}
		$tmpo=~s/\s//g;
		$tmpp=~s/\s//g;
				# all into one column
		$tmpWrt.=sprintf("%-s$sep%-s$sep",
				 $tmpo,$tmpp);
	    }
	}
    }
				# ------------------------------
				# matrix
    if ($tmp{"domatrix"} && $tmp{"dodetail"}){
	$kwd="mat";
	$tmp="";
	foreach $itobs (1..$nstatePrimary){
	    foreach $itprd (1..$nstatePrimary){
		if (! defined $error{$itfile,$modeLoc,$kwd,$itobs,$itprd}){
		    $tmp.="0,";}
		else {
		    $tmp.=$error{$itfile,$modeLoc,$kwd,$itobs,$itprd}.",";}
	    }}
	$tmp=~s/,$/$sep/;
	$tmpWrt.=$tmp;
    }
				# ------------------------------
				# detailed reliability index
    if ($tmp{"dori"} && $tmp{"doridetail"}){
	$tmpcov="";
	$tmpacc="";
	foreach $ri (0..$error{$modeLoc,"rimax"}){
	    $tmp=0;
	    if (defined $error{$itfileLoc,$modeLoc,$ri,"no"}){
		$tmp=$error{$itfileLoc,$modeLoc,$ri,"no"};}
	    $tmpcov.=$tmp.",";
	    $tmp=0;
	    if (defined $error{$itfileLoc,$modeLoc,$ri,"ok"}){
		$tmp=$error{$itfileLoc,$modeLoc,$ri,"ok"};}
	    $tmpacc.=$tmp.",";
	}
	$tmpcov=~s/,$/$sep/;
	$tmpacc=~s/,$/$sep/;

	$tmpWrt.=$tmpcov.$tmpacc;
    }

#    @tmp=split(/[\s\t]+/,$tmpWrt);printf "xx"."%-6s" x $#tmp . "\n",@tmp;die;
    return(1,"ok $SBR3",$tmpWrt);
}				# end of errPrd_wrtOneProt

#===============================================================================
sub stat_avevar {
    local(@data)=@_;
    local($i, $ave, $var);
    $[=1;
#----------------------------------------------------------------------
#   stat_avevar                 computes average and variance
#       in:                     @data (vector)
#       out:                    $AVE, $VAR
#          GLOBAL:              $AVE, $VAR (returned as list)
#----------------------------------------------------------------------
    $ave=$var=0;
    foreach $i (@data) { 
	$ave+=$i; } 
    $AVE="0";
    $AVE=($ave/$#data)          if ($#data > 0);
    foreach $i (@data) { 
	$tmp=($i-$AVE); $var+=($tmp*$tmp); } 
    $VAR="0";
    $VAR=($var/($#data-1))      if ($#data > 1);
    return ($AVE,$VAR);
}				# end of stat_avevar

1;
