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
#    PERL library with routines related to proteins, in general.               #
#    See also: formats.pl | file.pl  | molbio.pl                               #
#                                                                              #
#------------------------------------------------------------------------------#
# 
# 
# -----------------------------------------------------------------------------# 
#                               ---------------------
#   prot                        internal subroutines:
#                               ---------------------
# 
#   aa3lett_to_1lett            converts AA 3 letter code into 1 letter
#   align_a_la_blast            finds longest common word between string 1 and 2
#   amino_acid_convert_3_to_1   converts 3 letter alphabet to single letter alphabet
#   amino_acid_convert_3_to_1_ini returns GLOBAL array with 3 letter acid -> 1 letter
#   convert_acc                 converts accessibility (acc) to relative acc
#   convert_accRel2acc          converts relative accessibility (accRel) to full acc
#   convert_accRel2oneDigit     project relative acc to numbers 0-9
#   convert_sec                 converts 8 DSSP secondary str. into 3 (H,E,L)= default 
#   convert_secFine             takes an entire string ('HEL') and fine-tunes: ' EHH'-> '  HH'
#   exposure_normalise_prepare  normalisation weights (maximal: Schneider, Dipl)
#   exposure_normalise          normalise DSSP accessibility with maximal values
#   exposure_project_1digit     project relative exposure (relative) onto numbers 0-9
#   filter_hssp_curve           computes HSSP curve based on in:    ali length, seq ide
#   funcAddMatdb2prof           combines profile read + db matrix (for nali < x)
#   get_id                      extracts an identifier from file name
#   get_pdbid                   extracts a valid PDB identifier from file name
#   get_secstr_segment_caps     returns positions of secondary str. segments in string
#   getDistanceHsspCurve        computes the HSSP curve for in:    ali length
#   getDistanceNewCurveIde      out= pide value for new curve
#   getDistanceNewCurveSim      out= psim value for new curve
#   getDistanceThresh           compiles the distance from a threshold
#   getSegment                  takes string, writes segments and boundaries
#   hydrophobicity_scales       assigns values to various hydrophobicity scales
#   is_chain                    checks whether or not a PDB chain
#   is_pdbid                    checks whether or not id is a valid PDBid (number 3 char)
#   is_pdbid_list               checks whether id is list of valid PDBids (number 3 char)
#   is_swissid                  1
#   is_swissid_list             1
#   metric_ini                  initialise the metric reading ($string_aa returned=)
#   metric_norm_minmax          converting profiles (min <0, max>0) to percentages (0,1)
#   metric_rd                   reads a Maxhom formatted sequence metric
#   metricRdbRd                 reads an RDB formatted substitution metric, e.g.
#   profile_count               computes the profile for two sequences
#   secstr_convert_dsspto3      converts DSSP 8 into 3
#   seqide_compute              returns pairwise seq identity between 2 strings
#   seqide_exchange             exchange matrix res type X in seq 1 -> res type Y in seq 2
#   seqide_weighted             1
#   sort_by_pdbid               sorts a list of ids by alphabet (first number opressed)
#   wrt_strings                 writes several strings with numbers..
# 
# -----------------------------------------------------------------------------# 
#                               ---------------------
#   prot                        external subroutines:
#                               ---------------------
# 
#   call from comp:             equal_tolerance
# 
#   call from file:             open_file
# 
#   call from prot:             exposure_normalise,exposure_normalise_prepare,filter1_change
#                               filter1_rel_lengthen,filter1_rel_shorten,getDistanceHsspCurve
#                               getDistanceNewCurveIde,getDistanceNewCurveSim,get_secstr_segment_caps
#                               is_pdbid,is_swissid,metric_ini
# 
#   call from scr:              errSbr,errSbrMsg,myprt_npoints
# 
# -----------------------------------------------------------------------------# 
# 

#===============================================================================
sub aa3lett_to_1lett {
    local($aain) = @_; 
    local($tmpin,$tmpout);
    $[ =1;
#-------------------------------------------------------------------------------
#   aa3lett_to_1lett            converts AA 3 letter code into 1 letter
#       out GLOBAL:             $aa3lett_to_1lett
#-------------------------------------------------------------------------------
    $tmpin=$aain; $tmpin=~tr/[a-z]/[A-Z]/;
    if    ($tmpin eq "ALA") { $tmpout="A"; }
    elsif ($tmpin eq "CYS") { $tmpout="C"; }
    elsif ($tmpin eq "ASP") { $tmpout="D"; }
    elsif ($tmpin eq "GLU") { $tmpout="E"; }
    elsif ($tmpin eq "PHE") { $tmpout="F"; }
    elsif ($tmpin eq "GLY") { $tmpout="G"; }
    elsif ($tmpin eq "HIS") { $tmpout="H"; }
    elsif ($tmpin eq "ILE") { $tmpout="I"; }
    elsif ($tmpin eq "LYS") { $tmpout="K"; }
    elsif ($tmpin eq "LEU") { $tmpout="L"; }
    elsif ($tmpin eq "MET") { $tmpout="M"; }
    elsif ($tmpin eq "ASN") { $tmpout="N"; }
    elsif ($tmpin eq "PRO") { $tmpout="P"; }
    elsif ($tmpin eq "GLN") { $tmpout="Q"; }
    elsif ($tmpin eq "ARG") { $tmpout="R"; }
    elsif ($tmpin eq "SER") { $tmpout="S"; }
    elsif ($tmpin eq "THR") { $tmpout="T"; }
    elsif ($tmpin eq "VAL") { $tmpout="V"; }
    elsif ($tmpin eq "TRP") { $tmpout="W"; }
    elsif ($tmpin eq "TYR") { $tmpout="Y"; }
    elsif ($tmpin eq "UNK") { $tmpout="X"; }
    else { 
	print "*** ERROR in (lib-br) aa3lett_to_1lett:\n";
	print "***       AA in =$aain, doesn't correspond to known acid.\n";
	$tmpout="X";
    }
    $aa3lett_to_1lett=$tmpout;
}				# end of aa3lett_to_1lett 

#===============================================================================
sub align_a_la_blast {
    local($seq1Loc,$seq2Loc) = @_ ;
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   align_a_la_blast            finds longest common word between string 1 and 2
#       in:                     $string1
#       in:                     $string2
#       out:                    1|0,msg,$lali,$beg1,$beg2
#                               $lali      length of common substring
#                               $beg1      first matching residue in string1
#                               $beg2      first matching residue in string2
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."align_a_la_blast";
    $fhinLoc="FHIN_"."align_a_la_blast";$fhoutLoc="FHOUT_"."align_a_la_blast";
				# ------------------------------
				# check arguments
    return(&errSbr("not def seq1Loc!"))          if (! defined $seq1Loc);
    return(&errSbr("not def seq2Loc!"))          if (! defined $seq2Loc);
#    return(&errSbr("not def !"))          if (! defined $);

#    return(&errSbr("no fileIn=$fileInLoc!"))  if (! -e $fileInLoc);

				# ------------------------------
				# local defaults
    $wordlenLoc=               10;
    $wordlenLoc=$par{"wordlen"} if (defined $par{"wordlen"});

				# ------------------------------
				# all upper
    $seq1Loc=~tr/[a-z]/[A-Z]/;
    $seq2Loc=~tr/[a-z]/[A-Z]/;

				# long enough
    $len1=length($seq1Loc);
    if ($len1 < $wordlenLoc){
	return(2,"sequence 1 too short (is $len1, should be > $wordlenLoc)");
    }
				# chop up sequence 1
    $#tmpbeg=$#tmpend=0;
    
    @seq1Loc=split(//,$seq1Loc);
    $it=0;
    while ($it <= ($len1-$wordlenLoc)){
	++$it;
	$word1=substr($seq1Loc,$it,$wordlenLoc);
				# DOES match: try to extend
	if ($seq2Loc=~/$word1/){
	    $it2=$it+$wordlenLoc-1;
	    while ($seq2Loc=~/$word1/ && 
		   ($it2 < $len1)){
		++$it2;
		$word1.=$seq1Loc[$it2];
	    }
				# last did not match anymore
	    chop($word1)        if ($seq2Loc!~/$word1/);
	    $beg=$it;
	    $end=$it+length($word1)-1;
	    $it=$end;
	    push(@tmpbeg,$beg);
	    push(@tmpend,$end);
	}
    }
				# ------------------------------
				# find longest
    $max=$pos=0;
    foreach $it (1..$#tmpbeg){
	$len=1+$tmpend[$it]-$tmpbeg[$it];
	if ($max < $len){
	    $max=$len;
	    $pos=$it;}
    }
				# ------------------------------
				# find out where it matches
    
    $word1=substr($seq1Loc,$tmpbeg[$pos],$max);
    $beg1=$tmpbeg[$pos];
    $#seq1Loc=$#tmpbeg=$#tmpend=0;

    $tmp=$seq2Loc;
    $pre="";
    if ($tmp=~/^(.*)$word1/){
	$tmp=~s/^(.*)($word1)/$2/;
	$pre=$1                 if (defined $1);}
    $beg2=1;
    $beg2=length($pre)+1       if (length($pre)>0);
    return(1,"ok $sbrName",$max,$beg1,$beg2);
}				# end of align_a_la_blast

#===============================================================================
sub amino_acid_convert_3_to_1 {
    local($three_letter_acid) = @_ ;
    local($sbrName3);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   amino_acid_convert_3_to_1   converts 3 letter alphabet to single letter alphabet
#       in:                     $three_letter_acid
#       out:                    1|0,msg,$one_letter_acid
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName3="amino_acid_convert_3_to_1";
    return(0,"no input to $sbrName3") if (! defined $three_letter_acid);
				# initialise translation table
    &amino_acid_convert_3_to_1_ini()  
	if (! defined %amino_acid_convert_3_to_1);
				# not found
    return(0,"no conversion for acid=$three_letter_acid!","unk") 
	if (! defined $amino_acid_convert_3_to_1{$three_letter_acid});
				# ok
    return(1,"ok",$amino_acid_convert_3_to_1{$three_letter_acid});
}				# end of amino_acid_convert_3_to_1

#===============================================================================
sub amino_acid_convert_3_to_1_ini {
#-------------------------------------------------------------------------------
#   amino_acid_convert_3_to_1_ini returns GLOBAL array with 3 letter acid -> 1 letter
#       out GLOBAL:             %amino_acid_convert_3_to_1
#-------------------------------------------------------------------------------
    %amino_acid_convert_3_to_1=
	(
				# amino
	 'ALA',"A",
	 'ARG',"R",
	 'ASN',"N",
	 'ASP',"D",
	 'CYS',"C",
	 'GLN',"Q",
	 'GLU',"E",
	 'GLY',"G",
	 'HIS',"H",
	 'ILE',"I",
	 'LEU',"L",
	 'LYS',"K",
	 'MET',"M",
	 'PHE',"F",
	 'PRO',"P",
	 'SER',"S",
	 'THR',"T",
	 'TRP',"W",
	 'TYR',"Y",
	 'VAL',"V",

	 'MSE',"X",		# selenoMethionin

				# nucleic
	 'A',  "A",
	 'C',  "C",
	 'G',  "G",
	 'T',  "T",
	 );
}				# end of amino_acid_convert3_to_1

#===============================================================================
sub convert_acc {
    local ($aa,$acc,$char,$mode) = @_ ;
    local (@tmp1,@tmp2,@tmp,$it,$tmpacc,$valreturn);
#--------------------------------------------------------------------------------
#    convert_acc                converts accessibility (acc) to relative acc
#                               default output is just relative percentage (char = 'unk')
#         in:                   AA, (one letter symbol), acc (Angstroem),char (unk or:
#                    note:      output is relative percentage, default if char empty or='unk'
#                                    ============
#                               char='15:100_b:e' -> returns symbols 
#                                    ============
#                                    b for relacc <15, e for relacc>=15
#                                    ===============
#                               char='4:15:100_b:i:e' -> returns symbols 
#                                    ===============
#                                    b for relacc <4, i: 4<=relacc<15, e for relacc>=15
#         in:                   .... $mode:
#                               mode=''=default, '3ang', '5ang', '07ang' -> different water
#                                    radius, 'RS' then X=0
#         out:                  converted (with return)
#--------------------------------------------------------------------------------

    &exposure_normalise_prepare($mode) if (! %NORM_EXP);
				# default (3 states)
    if ( ! defined $char || $char eq "unk") {
	$valreturn=  &exposure_normalise($acc,$aa);}
				# optional e.g. char='15:100_b:e'
    elsif ($char =~ /\d:\d/) {
	if (! %NORM_EXP ){print "*** ERROR in convert_acc: NORM_EXP empty \n*** please,",
			  print "    do initialise with exposure_normalise_prepare\n";
			  exit;}
	$tmpacc= &exposure_normalise($acc,$aa);

	@tmp=split(/_/,$char);@tmp1=split(/:/,$tmp[1]);@tmp2=split(/:/,$tmp[2]);
	if   ($tmpacc<$tmp1[1])      {
	    $valreturn=$tmp2[1];}
	elsif($tmpacc>=$tmp1[$#tmp1-1]){
	    $valreturn=$tmp2[$#tmp1];}
	else { 
	    for ($it=2;$it<$#tmp1;++$it) {
		if ( ($tmpacc>=$tmp1[$it-1]) && ($tmpacc<$tmp1[$it+1]) ) {
		    $valreturn=$tmp2[$it]; 
		    last; }}} }
    else {print "*** ERROR calling convert_acc (lib-br) \n";
	  print "***       acc=$acc, aa=$aa, char passed (eg. 15:100_b:4)=$char, not ok\n";
	  exit;}
    $valreturn=100 if ($valreturn>100);	# saturation (shouldnt happen, should it?)
    return $valreturn;
}				# end of convert_acc

#===============================================================================
sub convert_accRel2acc {
    local ($accRel,$aaLoc) = @_ ;
    local ($sbrName);
#--------------------------------------------------------------------------------
#    convert_accRel2acc         converts relative accessibility (accRel) to full acc
#       in:                     AA, (one letter symbol), accRel (0-100), char (unk or:
#                    note:      output is accessibility in Angstroem if char empty or='unk'
#       out:                    converted (with return, max=248)
#       out:                    1|0,converted
#       err:                    (1,'ok'), (0,'message')
#--------------------------------------------------------------------------------
    $sbrName="";
				# check arguments
    return(&errSbr("not def accRel!"))  if (! defined $accRel);
    $aaLoc="A"                          if (! defined $aaLoc);
                                # convert case
    $aaLoc=~tr/[a-z]/[A-Z]/             if ($aaLoc=~/[a-z]/);

    if (defined $NORM_EXP{$aaLoc}){
        $valreturn=$accRel*$NORM_EXP{$aaLoc};}
    else {
        return(0,"*** ERROR $sbrName: accRel=$accRel, aa=$aaLoc, not converted\n");}
        
                                # saturation (shouldnt happen, should it?)
    $valreturn=$NORM_EXP{"max"} if ($valreturn>$NORM_EXP{"max"});
    
    return(1,$valreturn);
}				# end of convert_accRel2acc

#===============================================================================
sub convert_accRel2oneDigit {
    local ($accRelLoc) = @_;
    $[=1;
#----------------------------------------------------------------------
#   convert_accRel2oneDigit     project relative acc to numbers 0-9
#                               by: n = max ( 9 , int(sqrt (rel_exp)) )
#       in:                     $naliSatLoc   : number of alignments when no db taken
#       out:                    1|0,msg,$converted_acc
#       err:                    (1,'ok'), (0,'message')
#----------------------------------------------------------------------
				# check input
    return(0,"*** ERROR convert_accRel2oneDigit: relAcc=$accRelLoc???\n")
	if ( $accRelLoc < 0 );
				# SQRT
    $out= int ( sqrt ($accRelLoc) );
                                # saturation: limit to 9
    $out= 9  if ( $out >= 10 );
    return(1,"ok",$out);
}				# end of convert_accRel2oneDigit

#===============================================================================
sub convert_sec {
    local ($sec,$char) = @_ ;
#--------------------------------------------------------------------------------
#    convert_sec                converts 8 DSSP secondary str. into 3 (H,E,L)= default 
#                               char=HL    -> H=H,I,G  L=rest
#                               char=HELB  -> H=H,I,G  E=E, B=B, L=rest
#                               char=HELT  -> H=H,I,G  E=E,B  T=T, L=rest
#                               char=HELBT -> H=H,I,G  E=E, B=B, T=T, L=rest
#         default =             HEL
#         in:                   structure to convert
#         out:                  converted (with return)
#--------------------------------------------------------------------------------
				# default (3 states)
    if ( !defined $char || length($char)==0 || $char eq "HEL" || ! $char) {
	return "H" if ($sec=~/[HIG]/);
	return "E" if ($sec=~/[EB]/);
	return "L";}
				# optional
    elsif ($char eq "HL")    { return "H" if ($sec=~/[HIG]/);
			       return "L";}
    elsif ($char eq "HELT")  { return "H" if ($sec=~/[HIG]/);
			       return "E" if ($sec=~/[EB]/);
			       return "T" if ($sec=~/[T]/);
			       return "L";}
    elsif ($char eq "HELB")  { return "H" if ($sec=~/HIG/);
			       return "E" if ($sec=~/[E]/);
			       return "B" if ($sec=~/[B]/);
			       return "L";}
    elsif ($char eq "HELBT") { return "H" if ($sec=~/[HIG]/);
			       return "E" if ($sec=~/[EB]/);
			       return "B" if ($sec=~/[E]/);
			       return "T" if ($sec=~/[T]/);
			       return "L";}
    else { print "*** ERROR calling convert_sec (lib-br), sec=$sec, or char=$char, not ok\n";
	   return(0);}
}				# end of convert_sec

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

#==========================================================================
sub exposure_normalise_prepare {
    local ($mode) = @_;
    $[=1;
#----------------------------------------------------------------------
#    exposure_normalise_prepare normalisation weights (maximal: Schneider, Dipl)
#----------------------------------------------------------------------
#   --------------------------------------------------
#   Reinhard
#   --------------------------------------------------
    if ((!defined $mode)||(length($mode) <= 1)) {
	$NORM_EXP{"A"} = 106;  $NORM_EXP{"B"} =160;         # D or N
	$NORM_EXP{"C"} = 135;  $NORM_EXP{"D"} =163;  $NORM_EXP{"E"} =194;
	$NORM_EXP{"F"} = 197;  $NORM_EXP{"G"} = 84;  $NORM_EXP{"H"} =184;
	$NORM_EXP{"I"} = 169;  $NORM_EXP{"K"} =205;  $NORM_EXP{"L"} =164;
	$NORM_EXP{"M"} = 188;  $NORM_EXP{"N"} =157;  $NORM_EXP{"P"} =136;
	$NORM_EXP{"Q"} = 198;  $NORM_EXP{"R"} =248;  $NORM_EXP{"S"} =130;
	$NORM_EXP{"T"} = 142;  $NORM_EXP{"V"} =142;  $NORM_EXP{"W"} =227;
	$NORM_EXP{"X"} = 180;         # undetermined (deliberate)
	$NORM_EXP{"Y"} = 222;  $NORM_EXP{"Z"} =196;         # E or Q
        $NORM_EXP{"max"}=248;

#   --------------------------------------------------
#   maximal 3 Angstrom water
#   --------------------------------------------------
    } elsif ($mode =~ /3ang/ ) {
	$NORM_EXP{"A"} = 179;  $NORM_EXP{"B"} =255;         # D or N
	$NORM_EXP{"C"} =  99;  $NORM_EXP{"D"} =249;  $NORM_EXP{"E"} =279;
	$NORM_EXP{"F"} = 199;  $NORM_EXP{"G"} =169;  $NORM_EXP{"H"} =219;
	$NORM_EXP{"I"} = 189;  $NORM_EXP{"K"} =309;  $NORM_EXP{"L"} =209;
	$NORM_EXP{"M"} = 189;  $NORM_EXP{"N"} =259;  $NORM_EXP{"P"} =189;
	$NORM_EXP{"Q"} = 259;  $NORM_EXP{"R"} =299;  $NORM_EXP{"S"} =209;
	$NORM_EXP{"T"} = 209;  $NORM_EXP{"V"} =189;  $NORM_EXP{"W"} =239;
	$NORM_EXP{"X"} = 200;         # undetermined (deliberate)
	$NORM_EXP{"Y"} = 239;  $NORM_EXP{"Z"} =269;         # E or Q
        $NORM_EXP{"max"}=309;

#   --------------------------------------------------
#   maximal 5 Angstrom water
#   --------------------------------------------------
    } elsif ($mode =~ /5ang/ ) {
	$NORM_EXP{"A"} = 209;  $NORM_EXP{"B"} =295;         # D or N
	$NORM_EXP{"C"} = 139;  $NORM_EXP{"D"} =289;  $NORM_EXP{"E"} =349;
	$NORM_EXP{"F"} = 199;  $NORM_EXP{"G"} =219;  $NORM_EXP{"H"} =229;
	$NORM_EXP{"I"} = 189;  $NORM_EXP{"K"} =399;  $NORM_EXP{"L"} =239;
	$NORM_EXP{"M"} = 189;  $NORM_EXP{"N"} =299;  $NORM_EXP{"P"} =189;
	$NORM_EXP{"Q"} = 309;  $NORM_EXP{"R"} =309;  $NORM_EXP{"S"} =259;
	$NORM_EXP{"T"} = 239;  $NORM_EXP{"V"} =189;  $NORM_EXP{"W"} =259;
	$NORM_EXP{"X"} = 230;         # undetermined (deliberate)
	$NORM_EXP{"Y"} = 259;  $NORM_EXP{"Z"} =329;         # E or Q
        $NORM_EXP{"max"}=399;

#   --------------------------------------------------
#   maximal 0.7 Angstrom water
#   --------------------------------------------------
    } elsif ($mode =~ /07ang/ ) {
	$NORM_EXP{"A"} = 119;  $NORM_EXP{"B"} =169;         # D or N
	$NORM_EXP{"C"} =  99;  $NORM_EXP{"D"} =169;  $NORM_EXP{"E"} =179;
	$NORM_EXP{"F"} = 169;  $NORM_EXP{"G"} =109;  $NORM_EXP{"H"} =173;
	$NORM_EXP{"I"} = 159;  $NORM_EXP{"K"} =206;  $NORM_EXP{"L"} =159;
	$NORM_EXP{"M"} = 159;  $NORM_EXP{"N"} =169;  $NORM_EXP{"P"} =149;
	$NORM_EXP{"Q"} = 169;  $NORM_EXP{"R"} =209;  $NORM_EXP{"S"} =139;
	$NORM_EXP{"T"} = 149;  $NORM_EXP{"V"} =149;  $NORM_EXP{"W"} =169;
	$NORM_EXP{"X"} = 230;         # undetermined (deliberate)
	$NORM_EXP{"Y"} = 189;  $NORM_EXP{"Z"} =175;         # E or Q
        $NORM_EXP{"max"}=230;

#   --------------------------------------------------
#   RS (X=0, from Reinhard
#   --------------------------------------------------
    } elsif ($mode =~/RS/) {
	$NORM_EXP{"A"} = 106;  $NORM_EXP{"B"} =157;         # D or N
	$NORM_EXP{"C"} = 135;  $NORM_EXP{"D"} =163;  $NORM_EXP{"E"} =194;
	$NORM_EXP{"F"} = 197;  $NORM_EXP{"G"} = 84;  $NORM_EXP{"H"} =184;
	$NORM_EXP{"I"} = 169;  $NORM_EXP{"K"} =205;  $NORM_EXP{"L"} =164;
	$NORM_EXP{"M"} = 188;  $NORM_EXP{"N"} =157;  $NORM_EXP{"P"} =136;
	$NORM_EXP{"Q"} = 198;  $NORM_EXP{"R"} =248;  $NORM_EXP{"S"} =130;
	$NORM_EXP{"T"} = 142;  $NORM_EXP{"V"} =142;  $NORM_EXP{"W"} =227;
	$NORM_EXP{"X"} = 180;         # undetermined (deliberate)
	$NORM_EXP{"Y"} = 222;  $NORM_EXP{"Z"} =194;         # E or Q
        $NORM_EXP{"max"}=248;

#   --------------------------------------------------
#   Reinhard
#   --------------------------------------------------
    } else {
	$NORM_EXP{"A"} = 106;  $NORM_EXP{"B"} =160;         # D or N
	$NORM_EXP{"C"} = 135;  $NORM_EXP{"D"} =163;  $NORM_EXP{"E"} =194;
	$NORM_EXP{"F"} = 197;  $NORM_EXP{"G"} = 84;  $NORM_EXP{"H"} =184;
	$NORM_EXP{"I"} = 169;  $NORM_EXP{"K"} =205;  $NORM_EXP{"L"} =164;
	$NORM_EXP{"M"} = 188;  $NORM_EXP{"N"} =157;  $NORM_EXP{"P"} =136;
	$NORM_EXP{"Q"} = 198;  $NORM_EXP{"R"} =248;  $NORM_EXP{"S"} =130;
	$NORM_EXP{"T"} = 142;  $NORM_EXP{"V"} =142;  $NORM_EXP{"W"} =227;
	$NORM_EXP{"X"} = 180;         # undetermined (deliberate)
	$NORM_EXP{"Y"} = 222;  $NORM_EXP{"Z"} =196;         # E or Q
        $NORM_EXP{"max"}=248;
    }
}				# end of exposure_normalise_prepare 

#===============================================================================
sub exposure_normalise {
    local ($exp_in, $aa_in) = @_;
    $[=1;
#----------------------------------------------------------------------
#   exposure_normalise          normalise DSSP accessibility with maximal values
#                               (taken from Schneider)
#----------------------------------------------------------------------
    if ( $aa_in !~ /[ABCDEFGHIKLMNPQRSTUVWXYZ]/ ) {
	if ( $aa_in=~/[!.]/ ) { 
	    $aa_in = "X"; }
	else { 
	    print "*** ERROR in exposure_normalise: aa passed wrong: '$aa_in' \n";
	    exit; }}

    if ($NORM_EXP{$aa_in}>0) { 
	$exp_normalise= int(100 * ($exp_in / $NORM_EXP{$aa_in}));
	$exp_normalise= 100 if ($exp_normalise > 100);
    }
    else { 
	print "*** \n*** exposure_normalise, division by zero:aa=$aa_in,acc=$exp_in,norm=",
	$NORM_EXP{$aa_in},"\n***\n";
	$exp_normalise=$exp_in/1.8; # ugly ...
	if ($exp_normalise>100){$exp_normalise=100;}
    }
    return $exp_normalise;
}				# end of exposure_normalise

#===============================================================================
sub exposure_project_1digit {
    local ($exp_in) = @_;
    local ($exp_out);
    $[=1;
#----------------------------------------------------------------------
#   exposure_project_1digit     project relative exposure (relative) onto numbers 0-9
#                               by: n = max ( 9 , int(sqrt (rel_exp)) )
#----------------------------------------------------------------------
    if ( $exp_in < 0 ) {        # check input
        print "*** ERROR exposure_project_1digit: exposure in = $exp_in \n"; 
	exit;}
				# SQRT
    $exp_out = int ( sqrt ($exp_in) );
                                # limit to 9
    if ( $exp_out >= 10 ) { $exp_out = 9; }
    $exposure_project_1digit = $exp_out;
    return($exp_out);
}				# end of exposure_project_1digit

#===============================================================================
sub filter_hssp_curve {
    local ($lali,$ide,$thresh) = @_ ;
    local ($hssp_line);
    $[=1;
#--------------------------------------------------------------------------------
#   filter_hssp_curve           computes HSSP curve based on in:    ali length, seq ide
#       in:                     $lali,$ide,$thresh  
#                               note1: ide=percentage!
#                               note2: thresh=0 for HSSP, 5 for 30%, -5 for 20% ..
#       out GLOBAL:             $LABOVE_HSSP_CURVE =1 if ($ide,$lali)>HSSP-line +$thresh
#                               HSSP-curve  according to t(L)=(290.15 * L ** -0.562)
#--------------------------------------------------------------------------------
    if (length($thresh)==0) {$thresh=0;}
    $lali=~s/\s//g;
    if ($lali>80){$hssp_line=25.0;}else{ $hssp_line= 290.15*($lali **(-0.562) );}
    if ( $ide >= ($hssp_line+$thresh) ) {$LABOVE_HSSP_CURVE=1;}else{$LABOVE_HSSP_CURVE=0;}

    return ($LABOVE_HSSP_CURVE);
}				# end of filter_hssp_curve

#===============================================================================
sub funcAddMatdb2prof {
    local($profRdLoc,$profDbLoc,$naliLoc,$naliSatLoc) = @_ ;
    local($sbrName);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   funcAddMatdb2prof           combines profile read + db matrix (for nali < x)
#                               two cases:
#                               
#                               (1) nali >= naliSat:
#        NEWprof = READprof 
#                               
#                               (2) nali < naliSat
#                      1                                                       
#        NEWprof = ---------  * ( naliNorm * READprof + (naliSat - naliNorm) * DBprof )
#                   naliSat                                                 
#                               with naliNorm = nali - 1
#                               
#       in:                     $profRd       : the profile read in HSSP
#                                   ='R->V,R->L,R->I,...,R->D' 
#       in:                     $profDb       : one row of the substitution matrix
#                                   ='R->V,R->L,R->I,...,R->D' 
#       in:                     $naliLoc      : number of alignments (drives mixture)
#       in:                     $naliSatLoc   : number of alignments when no db taken
#       out:                    1|0,msg,$profNew
#                                   ='R->V,R->L,R->I,...,R->D' 
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."funcAddMatdb2prof"; 
				# ------------------------------
				# check arguments
    return(&errSbr("not def profRdLoc!"))            if (! defined $profRdLoc);
    return(&errSbr("not def profDbLoc!"))            if (! defined $profDbLoc);
    return(&errSbr("not def naliLoc!"))              if (! defined $naliLoc);
    return(&errSbr("not def naliSatLoc!"))           if (! defined $naliSatLoc);
    return(&errSbr("naliSatLoc=$naliSatLoc, b.s.!")) if ($naliSatLoc < 1);
	
#    return(&errSbr("not def !"))          if (! defined $);
				# ------------------------------
				# saturation
    return(1,"ok saturation",$profRdLoc) if ($naliLoc >= $naliSatLoc);
#    $naliNorm=$naliLoc - 1;  
#    $naliNorm=0                 if ($naliNorm < 0);
    $naliNorm=$naliLoc;  
    $naliNorm=1                 if ($naliNorm < 1);
				# ------------------------------
				# digest input
    $profRdLoc=~s/^,*|,*$//g;   @profRdLoc=split(/,/,$profRdLoc);
    $profDbLoc=~s/^,*|,*$//g;   @profDbLoc=split(/,/,$profDbLoc);

				# ------------------------------
				# mix
    $fac=(1/$naliSatLoc); $#tmp=0; 
    foreach $itTmp (1..$#profRdLoc) {
	$new=$fac * ( $naliNorm * $profRdLoc[$itTmp] +
		     ($naliSatLoc - $naliNorm) * $profDbLoc[$itTmp] ); 
	push(@tmp,$new); }
    $mix=join(',',@tmp); 
				# ------------------------------
				# output
    return(1,"ok $sbrName",$mix);
}				# end of funcAddMatdb2prof

#===============================================================================
sub get_id { local ($file) = @_ ; local($id);$[ =1 ;
#--------------------------------------------------------------------------------
#   get_id                      extracts an identifier from file name
#                               note: assume anything before '.' or '-'
#       in:                     $file
#       out:                    $id
#--------------------------------------------------------------------------------
#	     $id=$file;$id=~s/\s|\n//g;$id=~s/.*\///g;$id=~s/\W*(\w+)[.-].*/$1/;
	     $id=$file;$id=~s/\s|\n//g;$id=~s/.*\///g;$id=~s/\W*([\w_\-]+)[.].*/$1/;
	     return($id);
}				# end of get_id

#===============================================================================
sub get_pdbid { local ($file) = @_ ; local($id);$[ =1 ;
#--------------------------------------------------------------------------------
#   get_pdbid                   extracts a valid PDB identifier from file name
#                               note: assume \w\w\w\w
#       in:                     $file
#       out:                    $id
#--------------------------------------------------------------------------------
		$id=$file;$id=~s/\s|\n//g;$id=~s/.*\///g;$id=~s/\W*(\w\w\w\w).*/$1/;
		return($id);
}				# end of get_pdbid

#===============================================================================
sub get_secstr_segment_caps {
    local ($string,@des) = @_ ;
    local ($des,$it,@beg,@end,%segment);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   get_secstr_segment_caps     returns positions of secondary str. segments in string
#       out:                    $segment{"H","beg",1}= first residue in first helix
#                               $segment{"H","end",1}= last residue in first helix
#--------------------------------------------------------------------------------
				# convert vector to array (begin and end different)
    @aa=("#");push(@aa,split(//,$string)); push(@aa,"#");

    foreach $des (@des) {
	$#beg=$#end=0;		# loop over all residues
	foreach $it ( 2 .. $#aa ){ # note 1st and last ="#"
	    if   ( ($aa[$it] ne "$des") && ($aa[$it-1] eq "$des") ){
		push(@end,($it-2)); }
	    elsif( ($aa[$it] eq "$des") && ($aa[$it-1] ne "$des") ){
		push(@beg,($it-1)); }  }
	if ($#end != $#beg) {	# consistency check!
	    print "*** get_secstr_segment_caps: des=$des, Nend=",$#end,", Nbeg=",$#beg,",\n";
	    exit;}
	foreach $it (1..$#end){	# store segment begins (Ncap) and ends (Ccap)
	    $segment{"$des","beg","$it"}=$beg[$it];
	    $segment{"$des","end","$it"}=$end[$it]; } 
	$segment{"$des","NROWS"}=$#beg;
    }
    return(%segment);
}				# end of get_secstr_segment_caps

#===============================================================================
sub getDistanceHsspCurve {
    local ($laliLoc,$laliMaxLoc) = @_ ;
    $[=1;
#--------------------------------------------------------------------------------
#   getDistanceHsspCurve        computes the HSSP curve for in:    ali length
#       in:                     $lali,$lailMax
#                               note1: thresh=0 for HSSP, 5 for 30%, -5 for 20% ..
#                               note2: saturation at 100
#       out:                    value curve (i.e. percentage identity)
#                               HSSP-curve  according to t(L)=(290.15 * L ** -0.562)
#--------------------------------------------------------------------------------
    $sbrName="lib-br:getDistanceHsspCurve";
    return(0,"*** ERROR $sbrName: lali not defined \n") if (! defined $laliLoc);
    return(0,"*** ERROR $sbrName: '$laliLoc' = alignment length??\n") 
	if (length($laliLoc)<1 || $laliLoc=~/[^0-9.]/);
    $laliMaxLoc=100             if (! defined $laliMaxLoc);
    $laliLoc=~s/\s//g;

    $laliLoc=$laliMaxLoc        if ($laliLoc > $laliMaxLoc);	# saturation
    $val= 290.15*($laliLoc **(-0.562)); 
    $val=100                    if ($val > 100);
    $val=25                     if ($val < 25);
    return ($val,"ok $sbrName");
}				# end getDistanceHsspCurve

#===============================================================================
sub getDistanceNewCurveIde {
    local($laliLoc)=@_; local($expon,$loc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getDistanceNewCurveIde      out= pide value for new curve
#                               br 2003-08: mistake corrected
#                               
#       in:                     $lali
#       out:                    $pide
#                               
#                   OLD         pide= 510 * L ^ { -0.32 (1 + e ^-(L/1000)) }
#                   NEW         pide= 480 * L ^ { -0.32 (1 + e ^-(L/1000)) }
#-------------------------------------------------------------------------------
    $sbrName="lib-br:getDistanceNewCurveIde";
    return(0,"*** ERROR $sbrName: lali not defined \n") if (! defined $laliLoc);
    return(0,"*** ERROR $sbrName: '$laliLoc' = alignment length??\n") 
	if (length($laliLoc)<1 || $laliLoc=~/[^0-9.]/);


				# saturation short: <=11
    return(100,"ok $sbrName saturation short") 
	if ($laliLoc<=11);
				# saturation long: >450
    return(19.5,"ok $sbrName saturation long") 
	if ($laliLoc>450);

    $expon= - 0.32 * ( 1 + exp (-$laliLoc/1000) );
#    $loc= 510 * $laliLoc ** ($expon);
    $loc= 480 * $laliLoc ** ($expon);
    $loc=100   if ($loc > 100);	 # saturation short
    $loc=19.5  if ($loc < 19.5); # saturation long

    return($loc,"ok $sbrName");
}				# end of getDistanceNewCurveIde

#===============================================================================
sub getDistanceNewCurveSim {
    local($laliLoc)=@_; local($expon,$loc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getDistanceNewCurveSim      out= psim value for new curve
#       in:                     $lali
#       out:                    $sim
#                               psim= 420 * L ^ { -0.335 (1 + e ^-(L/2000)) }
#-------------------------------------------------------------------------------
    $sbrName="lib-br:getDistanceNewCurveSim";
    return(0,"*** ERROR $sbrName: lali not defined \n") if (! defined $laliLoc);
    return(0,"*** ERROR $sbrName: '$laliLoc' = alignment length??\n") 
	if (length($laliLoc)<1 || $laliLoc=~/[^0-9.]/);

    $expon= - 0.335 * ( 1 + exp (-$laliLoc/2000) );
    $loc= 420 * $laliLoc ** ($expon);
    $loc=100 if ($loc>100);     # saturation
    return($loc,"ok $sbrName");
}				# end of getDistanceNewCurveSim

#===============================================================================
sub getDistanceThresh {
    local($modeLoc,$laliLoc,$pideLoc) = @_ ;
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getDistanceThresh           compiles the distance from a threshold
#       in:                     $modeLoc: which filter ('old|new|newIde|newSim')
#       in:                     $laliLoc: alignment length
#       in:                     $pideLoc: percentages sequence identity/similarity
#       out:                    1|0,msg,$dist
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR="lib-br:"."getDistanceThresh";$fhinLoc="FHIN_"."getDistanceThresh";
				# check arguments
    return(&errSbr("not def modeLoc!",$SBR))          if (! defined $modeLoc);
    return(&errSbr("not def laliLoc!",$SBR))          if (! defined $laliLoc);
    return(&errSbr("not def pideLoc!",$SBR))          if (! defined $pideLoc);

    return(&errSbr("mode must be 'old|new|newSim' is '$modeLoc'",$SBR))
	if ($modeLoc !~ /^(old|new|newIde|newSim)$/i);
    return(&errSbr("lali must be integer is '$laliLoc'",$SBR)) if ($laliLoc !~ /^\d+$/);
    return(&errSbr("pide must be number 0..100 is '$pideLoc'",$SBR)) 
	if ($pideLoc !~ /^[\d\.]+$/ || $pideLoc < 0 || $pideLoc > 100);
	
				# ------------------------------
				# distance from threshold:
    if    ($modeLoc eq "old"){
	($pideCurve,$msg)= 
	    &getDistanceHsspCurve($laliLoc); 
	return(&errSbrMsg("failed getDistanceHsspCurve",$msg,$SBR))  if ($msg !~ /^ok/); }
    elsif ($modeLoc =~ /^newSim$/i){
	($pideCurve,$msg)= &getDistanceNewCurveSim($laliLoc); 
	return(&errSbrMsg("failed getDistanceNewCurveSim",$msg,$SBR))  if ($msg !~ /^ok/); }
    else {
	($pideCurve,$msg)= &getDistanceNewCurveIde($laliLoc); 
	return(&errSbrMsg("failed getDistanceNewCurveIde",$msg,$SBR))  if ($msg !~ /^ok/); }

    $dist=$pideLoc - $pideCurve;
    return(1,"ok $sbrName",$dist);
}				# end of getDistanceThresh

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

    return(1,"ok",\%segment);
}				# end of getSegment

#===============================================================================
sub hydrophobicity_scales {
    local($scaleWanted) = @_ ;
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hydrophobicity_scales       assigns values to various hydrophobicity scales
#       in:                     $scaleWanted: scale=ges|eisen|kydo|ooi|heijne|htm
#                                             0 to get all scales
#                                             'ges,kydo' for many
#                                             
#                  GES:         D Engelman, T Steitz & A Goldman ()
#                                      theory & exp
#                  EISEN:       D Eisenberg, & AD McLachlan ()
#                                      Solvation free energy   
#                  KYDO:        J Kyte & RF Doolittle
#                                      theory & stat
#                  OOI:         K Nishikawa & T Ooi
#                                      14 A contact number, occupancy numbers
#                  HEIJNE:      G von Heijne & C Blomberg
#                                      exp + theoretical HTM/non-htm
#                  HTM:         WC Wimley & S White:
#                                      experimental HTM/non-htm
#       in:                     $fileInLoc
#       note:                   URL:   http://www.genome.ad.jp/dbget/aaindex.html
#                               QUOTE: S Kawashima, H Ogata, and M Kanehisa:
#                               QUOTE: AAindex: amino acid index database. 
#                               QUOTE: Nucleic Acids Res. 27, 368-369, 1999
# 
#       out:                    (1|0,msg,%HYDRO)  implicit:
#                               $HYDRO{$kwd,$aa}=        raw score
#                               $HYDRO{$kwd,$aa,"norm"}= normalised 0-100
#       out GLOBAL:             %HYDRO
#       err:                    (1,'ok'), (0,'message')
# 
# 
#      +---------------------------------------+-----------------------------------+
#      |        RAW SCORES                     |     NORMALISED scores (0 - 100)   |
# +----+---------------------------------------+-----------------------------------+------+
# | aa | GES  EISEN   KYDO    OOI HEIJNE   HTM | GES EISEN  KYDO   OOI HEIJNE  HTM | sum  |
# +----+---------------------------------------+-----------------------------------+------+
# |                                            |                                   |      |
# | A  -6.70   0.67   1.80  -0.22 -12.04   4.08| 13.1  58.9  70.0  40.6  16.2  47.8| 41.1 |
# | R  51.50  -2.10  -4.50  -0.93  39.23   3.91|100.0   0.0   0.0  33.3 100.0  43.4| 46.1 |
# | N  20.10  -0.60  -3.50  -2.65   4.25   3.83| 53.1  31.9  11.1  15.7  42.9  41.3| 32.7 |
# | D  38.50  -1.20  -3.50  -4.12  23.22   3.02| 80.6  19.1  11.1   0.6  73.8  20.4| 34.3 |
# | C  -8.40   0.38   2.50   4.66   3.95   4.49| 10.6  52.8  77.8  90.6  42.4  58.4| 55.4 |
# | Q  17.20  -0.22  -3.50  -2.76   2.16   3.67| 48.8  40.0  11.1  14.5  39.4  37.2| 31.9 |
# | E  34.30  -0.76  -3.50  -3.64  16.81   2.23| 74.3  28.5  11.1   5.5  63.4   0.0| 30.5 |
# | G  -4.20   0.00  -0.40  -1.62  -7.85   4.24| 16.9  44.7  45.6  26.2  23.1  51.9| 34.7 |
# | H  12.60   0.64  -3.20   1.28   6.28   4.08| 41.9  58.3  14.4  55.9  46.2  47.8| 44.1 |
# | I -13.00   1.90   4.50   5.58 -18.32   4.52|  3.7  85.1 100.0 100.0   6.0  59.2| 59.0 |
# | L -11.70   1.90   3.80   5.01 -17.79   4.81|  5.7  85.1  92.2  94.2   6.8  66.7| 58.4 |
# | K  36.80  -0.57  -3.90  -4.18   9.71   3.77| 78.1  32.6   6.7   0.0  51.8  39.8| 34.8 |
# | M -14.20   2.40   1.90   3.51  -8.86   4.48|  1.9  95.7  71.1  78.8  21.4  58.1| 54.5 |
# | F -15.50   2.30   2.80   5.27 -21.98   5.38|  0.0  93.6  81.1  96.8   0.0  81.4| 58.8 |
# | P   0.80   1.20  -1.60  -3.03   5.82   3.80| 24.3  70.2  32.2  11.8  45.4  40.6| 37.4 |
# | S  -2.50   0.01  -0.80  -2.84  -1.54   4.12| 19.4  44.9  41.1  13.7  33.4  48.8| 33.6 |
# | T  -5.00   0.52  -0.70  -1.20  -4.15   4.11| 15.7  55.7  42.2  30.5  29.1  48.6| 37.0 |
# | W  -7.90   2.60  -0.90   5.20 -16.19   6.10| 11.3 100.0  40.0  96.1   9.5 100.0| 59.5 |
# | Y   2.90   1.60  -1.30   2.15  -1.51   5.19| 27.5  78.7  35.6  64.9  33.4  76.5| 52.8 |
# | V -10.90   1.50   4.20   4.45 -16.22   4.18|  6.9  76.6  96.7  88.4   9.4  50.4| 54.7 |
# +----+---------------------------------------+-----------------------------------+------+
# 
# 
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."hydrophobicity_scales";
    $scaleWanted=0              if (! defined $scaleWanted ||
				    $scaleWanted=~/all/);

    undef %HYDRO;
				# ------------------------------
				# direct for HYDRO-GES
				#    D Engelman, T Steitz & A Goldman
				#    Annu. Rev. Biophys. Chem. 15, 321-353, 1986
				# ------------------------------
    if (! $scaleWanted || $scaleWanted=~/ges/){
	$HYDRO{"ges","A"}=             -6.70;
	$HYDRO{"ges","R"}=             51.50;
	$HYDRO{"ges","N"}=             20.10;
	$HYDRO{"ges","D"}=             38.50;
	$HYDRO{"ges","C"}=             -8.40;
	$HYDRO{"ges","Q"}=             17.20;
	$HYDRO{"ges","E"}=             34.30;
	$HYDRO{"ges","G"}=             -4.20;
	$HYDRO{"ges","H"}=             12.60;
	$HYDRO{"ges","I"}=            -13.00;
	$HYDRO{"ges","L"}=            -11.70;
	$HYDRO{"ges","K"}=             36.80;
	$HYDRO{"ges","M"}=            -14.20;
	$HYDRO{"ges","F"}=            -15.50;
	$HYDRO{"ges","P"}=              0.80;
	$HYDRO{"ges","S"}=             -2.50;
	$HYDRO{"ges","T"}=             -5.00;
	$HYDRO{"ges","W"}=             -7.90;
	$HYDRO{"ges","Y"}=              2.90;
	$HYDRO{"ges","V"}=            -10.90;
				# normalised (0,100)for HYDRO-GES
	$HYDRO{"ges","A","norm"}=      13.1;
	$HYDRO{"ges","R","norm"}=     100.0;
	$HYDRO{"ges","N","norm"}=      53.1;
	$HYDRO{"ges","D","norm"}=      80.6;
	$HYDRO{"ges","C","norm"}=      10.6;
	$HYDRO{"ges","Q","norm"}=      48.8;
	$HYDRO{"ges","E","norm"}=      74.3;
	$HYDRO{"ges","G","norm"}=      16.9;
	$HYDRO{"ges","H","norm"}=      41.9;
	$HYDRO{"ges","I","norm"}=       3.7;
	$HYDRO{"ges","L","norm"}=       5.7;
	$HYDRO{"ges","K","norm"}=      78.1;
	$HYDRO{"ges","M","norm"}=       1.9;
	$HYDRO{"ges","F","norm"}=       0.0;
	$HYDRO{"ges","P","norm"}=      24.3;
	$HYDRO{"ges","S","norm"}=      19.4;
	$HYDRO{"ges","T","norm"}=      15.7;
	$HYDRO{"ges","W","norm"}=      11.3;
	$HYDRO{"ges","Y","norm"}=      27.5;
	$HYDRO{"ges","V","norm"}=       6.9;
    }
				# ------------------------------
				# direct for HYDRO-EISEN
				#    D Eisenberg, & AD McLachlan
				#    Solvation energy in protein folding and binding
				#    Nature 319, 199-203 (1986)
				# ------------------------------
    if (! $scaleWanted || $scaleWanted=~/eisen/){
	$HYDRO{"eisen","A"}=            0.67;
	$HYDRO{"eisen","R"}=           -2.10;
	$HYDRO{"eisen","N"}=           -0.60;
	$HYDRO{"eisen","D"}=           -1.20;
	$HYDRO{"eisen","C"}=            0.38;
	$HYDRO{"eisen","Q"}=           -0.22;
	$HYDRO{"eisen","E"}=           -0.76;
	$HYDRO{"eisen","G"}=            0.00;
	$HYDRO{"eisen","H"}=            0.64;
	$HYDRO{"eisen","I"}=            1.90;
	$HYDRO{"eisen","L"}=            1.90;
	$HYDRO{"eisen","K"}=           -0.57;
	$HYDRO{"eisen","M"}=            2.40;
	$HYDRO{"eisen","F"}=            2.30;
	$HYDRO{"eisen","P"}=            1.20;
	$HYDRO{"eisen","S"}=            0.01;
	$HYDRO{"eisen","T"}=            0.52;
	$HYDRO{"eisen","W"}=            2.60;
	$HYDRO{"eisen","Y"}=            1.60;
	$HYDRO{"eisen","V"}=            1.50;
				# normalised (0,100)for HYDRO-EISEN
	$HYDRO{"eisen","A","norm"}=    58.9;
	$HYDRO{"eisen","R","norm"}=     0.0;
	$HYDRO{"eisen","N","norm"}=    31.9;
	$HYDRO{"eisen","D","norm"}=    19.1;
	$HYDRO{"eisen","C","norm"}=    52.8;
	$HYDRO{"eisen","Q","norm"}=    40.0;
	$HYDRO{"eisen","E","norm"}=    28.5;
	$HYDRO{"eisen","G","norm"}=    44.7;
	$HYDRO{"eisen","H","norm"}=    58.3;
	$HYDRO{"eisen","I","norm"}=    85.1;
	$HYDRO{"eisen","L","norm"}=    85.1;
	$HYDRO{"eisen","K","norm"}=    32.6;
	$HYDRO{"eisen","M","norm"}=    95.7;
	$HYDRO{"eisen","F","norm"}=    93.6;
	$HYDRO{"eisen","P","norm"}=    70.2;
	$HYDRO{"eisen","S","norm"}=    44.9;
	$HYDRO{"eisen","T","norm"}=    55.7;
	$HYDRO{"eisen","W","norm"}=   100.0;
	$HYDRO{"eisen","Y","norm"}=    78.7;
	$HYDRO{"eisen","V","norm"}=    76.6;
    }
				# ------------------------------
				# direct for HYDRO-KYDO
				#    J Kyte & RF Doolittle
				#    A simple method for displaying the 
                                #    hydropathic character of a protein
				#    J. Mol. Biol. 157, 105-132 (1982)
				# ------------------------------
    if (! $scaleWanted || $scaleWanted=~/kydo/){
	$HYDRO{"kydo","A"}=             1.80;
	$HYDRO{"kydo","R"}=            -4.50;
	$HYDRO{"kydo","N"}=            -3.50;
	$HYDRO{"kydo","D"}=            -3.50;
	$HYDRO{"kydo","C"}=             2.50;
	$HYDRO{"kydo","Q"}=            -3.50;
	$HYDRO{"kydo","E"}=            -3.50;
	$HYDRO{"kydo","G"}=            -0.40;
	$HYDRO{"kydo","H"}=            -3.20;
	$HYDRO{"kydo","I"}=             4.50;
	$HYDRO{"kydo","L"}=             3.80;
	$HYDRO{"kydo","K"}=            -3.90;
	$HYDRO{"kydo","M"}=             1.90;
	$HYDRO{"kydo","F"}=             2.80;
	$HYDRO{"kydo","P"}=            -1.60;
	$HYDRO{"kydo","S"}=            -0.80;
	$HYDRO{"kydo","T"}=            -0.70;
	$HYDRO{"kydo","W"}=            -0.90;
	$HYDRO{"kydo","Y"}=            -1.30;
	$HYDRO{"kydo","V"}=             4.20;
				# normalised (0,100)for HYDRO-KYDO
	$HYDRO{"kydo","A","norm"}=     70.0;
	$HYDRO{"kydo","R","norm"}=      0.0;
	$HYDRO{"kydo","N","norm"}=     11.1;
	$HYDRO{"kydo","D","norm"}=     11.1;
	$HYDRO{"kydo","C","norm"}=     77.8;
	$HYDRO{"kydo","Q","norm"}=     11.1;
	$HYDRO{"kydo","E","norm"}=     11.1;
	$HYDRO{"kydo","G","norm"}=     45.6;
	$HYDRO{"kydo","H","norm"}=     14.4;
	$HYDRO{"kydo","I","norm"}=    100.0;
	$HYDRO{"kydo","L","norm"}=     92.2;
	$HYDRO{"kydo","K","norm"}=      6.7;
	$HYDRO{"kydo","M","norm"}=     71.1;
	$HYDRO{"kydo","F","norm"}=     81.1;
	$HYDRO{"kydo","P","norm"}=     32.2;
	$HYDRO{"kydo","S","norm"}=     41.1;
	$HYDRO{"kydo","T","norm"}=     42.2;
	$HYDRO{"kydo","W","norm"}=     40.0;
	$HYDRO{"kydo","Y","norm"}=     35.6;
	$HYDRO{"kydo","V","norm"}=     96.7;
    }
				# ------------------------------
				# direct for HYDRO-OOI
				#    K Nishikawa & T Ooi
				#    Radial locations of amino acid residues in a globular protein:
				#    J. Biochem. 100, 1043-1047 (1986)
				# ------------------------------

    if (! $scaleWanted || $scaleWanted=~/ooi/){
	$HYDRO{"ooi","A"}=             -0.22;
	$HYDRO{"ooi","R"}=             -0.93;
	$HYDRO{"ooi","N"}=             -2.65;
	$HYDRO{"ooi","D"}=             -4.12;
	$HYDRO{"ooi","C"}=              4.66;
	$HYDRO{"ooi","Q"}=             -2.76;
	$HYDRO{"ooi","E"}=             -3.64;
	$HYDRO{"ooi","G"}=             -1.62;
	$HYDRO{"ooi","H"}=              1.28;
	$HYDRO{"ooi","I"}=              5.58;
	$HYDRO{"ooi","L"}=              5.01;
	$HYDRO{"ooi","K"}=             -4.18;
	$HYDRO{"ooi","M"}=              3.51;
	$HYDRO{"ooi","F"}=              5.27;
	$HYDRO{"ooi","P"}=             -3.03;
	$HYDRO{"ooi","S"}=             -2.84;
	$HYDRO{"ooi","T"}=             -1.20;
	$HYDRO{"ooi","W"}=              5.20;
	$HYDRO{"ooi","Y"}=              2.15;
	$HYDRO{"ooi","V"}=              4.45;
				# normalised (0,100)for HYDRO-OOI
	$HYDRO{"ooi","A","norm"}=      40.6;
	$HYDRO{"ooi","R","norm"}=      33.3;
	$HYDRO{"ooi","N","norm"}=      15.7;
	$HYDRO{"ooi","D","norm"}=       0.6;
	$HYDRO{"ooi","C","norm"}=      90.6;
	$HYDRO{"ooi","Q","norm"}=      14.5;
	$HYDRO{"ooi","E","norm"}=       5.5;
	$HYDRO{"ooi","G","norm"}=      26.2;
	$HYDRO{"ooi","H","norm"}=      55.9;
	$HYDRO{"ooi","I","norm"}=     100.0;
	$HYDRO{"ooi","L","norm"}=      94.2;
	$HYDRO{"ooi","K","norm"}=       0.0;
	$HYDRO{"ooi","M","norm"}=      78.8;
	$HYDRO{"ooi","F","norm"}=      96.8;
	$HYDRO{"ooi","P","norm"}=      11.8;
	$HYDRO{"ooi","S","norm"}=      13.7;
	$HYDRO{"ooi","T","norm"}=      30.5;
	$HYDRO{"ooi","W","norm"}=      96.1;
	$HYDRO{"ooi","Y","norm"}=      64.9;
	$HYDRO{"ooi","V","norm"}=      88.4;
    }
				# ------------------------------
				# direct for HYDRO-HEIJNE
				#    G von Heijne & C Blomberg
				#    Trans-membrane translocation of proteins: 
                                #    The direct transfer model
				#    Eur. J. Biochem. 97, 175-181 (1979)
				# ------------------------------
    if (! $scaleWanted || $scaleWanted=~/heijne/){
	$HYDRO{"heijne","A"}=         -12.04;
	$HYDRO{"heijne","R"}=          39.23;
	$HYDRO{"heijne","N"}=           4.25;
	$HYDRO{"heijne","D"}=          23.22;
	$HYDRO{"heijne","C"}=           3.95;
	$HYDRO{"heijne","Q"}=           2.16;
	$HYDRO{"heijne","E"}=          16.81;
	$HYDRO{"heijne","G"}=          -7.85;
	$HYDRO{"heijne","H"}=           6.28;
	$HYDRO{"heijne","I"}=         -18.32;
	$HYDRO{"heijne","L"}=         -17.79;
	$HYDRO{"heijne","K"}=           9.71;
	$HYDRO{"heijne","M"}=          -8.86;
	$HYDRO{"heijne","F"}=         -21.98;
	$HYDRO{"heijne","P"}=           5.82;
	$HYDRO{"heijne","S"}=          -1.54;
	$HYDRO{"heijne","T"}=          -4.15;
	$HYDRO{"heijne","W"}=         -16.19;
	$HYDRO{"heijne","Y"}=          -1.51;
	$HYDRO{"heijne","V"}=         -16.22;
				# normalised (0,100)for HYDRO-HEIJNE
	$HYDRO{"heijne","A","norm"}=    16.2;
	$HYDRO{"heijne","R","norm"}=   100.0;
	$HYDRO{"heijne","N","norm"}=    42.9;
	$HYDRO{"heijne","D","norm"}=    73.8;
	$HYDRO{"heijne","C","norm"}=    42.4;
	$HYDRO{"heijne","Q","norm"}=    39.4;
	$HYDRO{"heijne","E","norm"}=    63.4;
	$HYDRO{"heijne","G","norm"}=    23.1;
	$HYDRO{"heijne","H","norm"}=    46.2;
	$HYDRO{"heijne","I","norm"}=     6.0;
	$HYDRO{"heijne","L","norm"}=     6.8;
	$HYDRO{"heijne","K","norm"}=    51.8;
	$HYDRO{"heijne","M","norm"}=    21.4;
	$HYDRO{"heijne","F","norm"}=     0.0;
	$HYDRO{"heijne","P","norm"}=    45.4;
	$HYDRO{"heijne","S","norm"}=    33.4;
	$HYDRO{"heijne","T","norm"}=    29.1;
	$HYDRO{"heijne","W","norm"}=     9.5;
	$HYDRO{"heijne","Y","norm"}=    33.4;
	$HYDRO{"heijne","V","norm"}=     9.4;
    }
				# ------------------------------
				# direct for HYDRO-HTM
				#    WC Wimley & S White
				#    Experimentally determined hydrophobicity 
                                #    scale for proteins at membrane
				#    Nature Structual biol. 3, 842-848 (1996)
				# ------------------------------
    if (! $scaleWanted || $scaleWanted=~/htm/){
	$HYDRO{"htm","A"}=              4.08;
	$HYDRO{"htm","R"}=              3.91;
	$HYDRO{"htm","N"}=              3.83;
	$HYDRO{"htm","D"}=              3.02;
	$HYDRO{"htm","C"}=              4.49;
	$HYDRO{"htm","Q"}=              3.67;
	$HYDRO{"htm","E"}=              2.23;
	$HYDRO{"htm","G"}=              4.24;
	$HYDRO{"htm","H"}=              4.08;
	$HYDRO{"htm","I"}=              4.52;
	$HYDRO{"htm","L"}=              4.81;
	$HYDRO{"htm","K"}=              3.77;
	$HYDRO{"htm","M"}=              4.48;
	$HYDRO{"htm","F"}=              5.38;
	$HYDRO{"htm","P"}=              3.80;
	$HYDRO{"htm","S"}=              4.12;
	$HYDRO{"htm","T"}=              4.11; 
	$HYDRO{"htm","W"}=              6.10;
	$HYDRO{"htm","Y"}=              5.19;
	$HYDRO{"htm","V"}=              4.18;
				# normalised (0,100)for HYDRO-HTM
	$HYDRO{"htm","A","norm"}=      47.8;
	$HYDRO{"htm","R","norm"}=      43.4;
	$HYDRO{"htm","N","norm"}=      41.3;
	$HYDRO{"htm","D","norm"}=      20.4;
	$HYDRO{"htm","C","norm"}=      58.4;
	$HYDRO{"htm","Q","norm"}=      37.2;
	$HYDRO{"htm","E","norm"}=       0.0;
	$HYDRO{"htm","G","norm"}=      51.9;
	$HYDRO{"htm","H","norm"}=      47.8;
	$HYDRO{"htm","I","norm"}=      59.2;
	$HYDRO{"htm","L","norm"}=      66.7;
	$HYDRO{"htm","K","norm"}=      39.8;
	$HYDRO{"htm","M","norm"}=      58.1;
	$HYDRO{"htm","F","norm"}=      81.4;
	$HYDRO{"htm","P","norm"}=      40.6;
	$HYDRO{"htm","S","norm"}=      48.8;
	$HYDRO{"htm","T","norm"}=      48.6;
	$HYDRO{"htm","W","norm"}=     100.0;
	$HYDRO{"htm","Y","norm"}=      76.5;
	$HYDRO{"htm","V","norm"}=      50.4;
    }
    return(1,"ok $sbrName",%HYDRO);
}				# end of hydrophobicity_scales

#===============================================================================
sub is_chain {
    local($tmp) = @_ ;
#-------------------------------------------------------------------------------
#   is_chain                    checks whether or not a PDB chain
#       in:                     character
#       out:                    1,0
#-------------------------------------------------------------------------------
    return(0) if (! defined $tmp);
    return(1) if ($tmp=~/[A-Z0-9]/);
    return(0);
}				# end of is_chain

#===============================================================================
sub is_pdbid {
    local ($id) = @_ ;
#--------------------------------------------------------------------------------
#   is_pdbid                    checks whether or not id is a valid PDBid (number 3 char)
#       in:                     $file
#       out:                    1 if is DBid, 0 else
#--------------------------------------------------------------------------------
    return 1
	if ((length($id) <= 6) &&
	    ($id=~/^[0-9][0-9a-z]{3,3}[^0-9a-z]?/));
    return 0;
}				# end of is_pdbid

#===============================================================================
sub is_pdbid_list {
    local ($fileInLoc) = @_ ;local ($fh,$Lis);
#--------------------------------------------------------------------------------
#   is_pdbid_list               checks whether id is list of valid PDBids (number 3 char)
#       in:                     $file
#       out:                    1 if is DBid, 0 else
#--------------------------------------------------------------------------------
    if (! -e $fileInLoc) {
	return (0);}
    $fh="FHIN_CHECK_PDBID_LIST";&open_file("$fh", "$fileInLoc");
    while ( <$fh> ) {$tmp=$_;$tmp=~s/\s|\n//g;
		     if (length($tmp)<5){next;}
		     if (! -e $tmp)     {$tmp=~s/_.$//;} # purge chain
		     if ( -e $tmp )     { # is existing file?
			 if (&is_pdbid($_)) {$Lis=1; }
			 else { $Lis=0; } }
		     else {$Lis=0; } 
		     last; } close($fh);
    return $Lis;
}				# end of is_pdbid_list

#===============================================================================
sub is_swissid {
    local ($id) = @_ ;
#--------------------------------------------------------------------------------
#    sub: is_pdbid              checks whether id is a valid SWISSid (char{3,5}_char{3,5})
#                               note: letters have to be lower case
#         input:                id
#         output:               returns 1 if is SWISSid, 0 else
#--------------------------------------------------------------------------------
    if (length($id) <= 12){
	if ($id=~/^[0-9a-z]{3,5}_[0-9a-z]{3,5}/){
	    return 1;}}
    return 0;
}				# end of is_swissid

#===============================================================================
sub is_swissid_list {
    local ($fileLoc) = @_ ;
    local ($fhLoc);
#--------------------------------------------------------------------------------
#    sub: is_swissid_list       checks whether list of valid SWISSid's (char{3,5}_char{3,5})
#         input:                file
#         output:               returns 1 if is Swissid, 0 else
#--------------------------------------------------------------------------------
    if (! -e $fileLoc) {
	return (0);}
    $fhLoc="FHIN_CHECK_SWISSID_LIST";
    &open_file("$fhLoc", "$fileLoc") || return(0);
    while ( <$fhLoc> ) {
	$tmp=$_;$tmp=~s/\s|\n//g; $tmp=~s/^.*\///g; # purge directories
	next if (length($tmp)<5);
	if (&is_swissid($tmp)){ close($fhLoc);
				return(1);}}close($fhLoc);
    return(0);
}				# end of is_swissid_list

#===============================================================================
sub metric_ini {
#--------------------------------------------------------------------------------
#   metric_ini                  initialise the metric reading ($string_aa returned=)
#--------------------------------------------------------------------------------
    $string_aa="VLIMFWYGAPSTCHRKQENDBZ";
    return $string_aa;
}				# end of metric_ini

#===============================================================================
sub metric_norm_minmax {
    local ($min_out,$max_out,$aa,%metric) = @_ ;
    local (@key,$key,$min,$max,$fac,$sub,$Lscreen,%metricnorm,$Lerr,$aa1,$aa2,@aa);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   metric_norm_minmax          converting profiles (min <0, max>0) to percentages (0,1)
#--------------------------------------------------------------------------------
    $Lscreen=0;
    @aa=split(//,$aa);
				# ------------------------------
				# figuring out current min/max
				# ------------------------------
    $min=$max=0;
    foreach $aa1(@aa){foreach $aa2(@aa){
	if    ($metric{"$aa1","$aa2"} < $min) { $min=$metric{"$aa1","$aa2"};}
	elsif ($metric{"$aa1","$aa2"} > $max) { $max=$metric{"$aa1","$aa2"};}
    }}
				# ------------------------------
				# normalising
				# x' = D*x - ( D*xmax - maxout ), D=(maxout-minout)/(xmax-xmin)
				# ------------------------------
    $fac= ($max_out-$min_out) / ($max-$min);
    $sub= ($fac*$max) - $max_out;
    if ($Lscreen) { print  "--- in get_metricnorm\t ";
		    printf "min=%5.2f, max=%5.2f, desired min_out=%5.2f, max_out=%5.2f\n",
		    $min,$max,$min_out,$max_out;
		    print  "--- normalise by: \t x' = f * x - ( f * xmax -max_out ) \n";
		    printf "--- where: \t \t fac=%5.2f, and (f*xmax-max_out)=%5.2f\n",$fac,$sub; }

    $min=$max=0;		# for error check
    foreach $aa1(@aa){foreach $aa2(@aa){
	$metricnorm{"$aa1","$aa2"}=($fac*$metric{"$aa1","$aa2"}) - $sub;
	if    ($metricnorm{"$aa1","$aa2"}<$min) {$min=$metricnorm{"$aa1","$aa2"};}
	elsif ($metricnorm{"$aa1","$aa2"}>$max) {$max=$metricnorm{"$aa1","$aa2"};}
    }}
				# --------------------------------------------------
				# error check
				# --------------------------------------------------
    $Lerr=0;
    if ( ! &equal_tolerance($min,$min_out,0.0001) ){$Lerr=1;
		     print"*** ERROR get_metricnorm: after min=$min, but desired is=$min_out,\n";}
    if ( ! &equal_tolerance($max,$max_out,0.0001) ){$Lerr=1;
		     print"*** ERROR get_metricnorm: after max=$max, but desired is=$max_out,\n";}
    if ($Lerr) {exit;}
    return %metricnorm;
}				# end of metric_norm_minmax

#===============================================================================
sub metric_rd {
    local ($file_metric) = @_ ;
    local (@tmp,$aa1,$aa2,$fhin,$tmp,$string_aa,@aa,%metric);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   metric_rd                   reads a Maxhom formatted sequence metric
#--------------------------------------------------------------------------------
    $fhin="FHIN_RD_METRIC";
    $string_aa=&metric_ini;
    if (-e $file_metric){
	&open_file("$fhin","$file_metric");
	while(<$fhin>){$tmp=$_;last if (/^AA /);}
				# ------------------------------
				# read acid symbol
	$tmp=~s/\n//g;
	$tmp=~s/^\s*|\s*$//g;	# deleting leading blanks
	$#tmp=0;@tmp=split(/\s+/);
	$#aa=0;
	foreach $it (4 .. $#tmp){
	    push(@aa,$tmp[$it]);
	}
	while(<$fhin>){
	    $_=~s/\n//g;
	    $_=~s/^\s*|\s*$//g;	# deleting leading blanks
	    $#tmp=0;@tmp=split(/\s+/);
	    foreach $it (1 .. $#aa){
		$metric{"$tmp[1]","$aa[$it]"}=$tmp[$it+1];
	    }
	}
	close($fhin);}
    else {
	print"*** ERROR in metric_rd (lib-br): '$file_metric' missing\n"; }
				# ------------------------------
				# identity metric
    if (0){
	@tmp=split(//,$string_aa);
	foreach $aa1 (@tmp){ foreach $aa2 (@tmp){ 
	    if ($aa1 eq $aa2){ $metric{"$aa1","$aa2"}=1;}
	    else {$metric{"$aa1","$aa2"}=0;}
	}}
    }
    return(%metric);
}				# end of metric_rd

#===============================================================================
sub metricRdbRd {
    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   metricRdbRd                 reads an RDB formatted substitution metric, e.g.
#                               written by: lib-br:stat2DarrayWrt
#       in:                     $fileInLoc
#       out:                    1|0,msg,$tmp{}
#                               $tmp{"aa1","aa2"} = mat for aa1 -> aa2
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."metricRdbRd";$fhinLoc="FHIN_"."metricRdbRd";
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
#    return(&errSbr("not def !"))          if (! defined $);

    return(&errSbr("miss in file '$fileInLoc'!"))  if (! -e $fileInLoc);

    undef %tmp; undef %ptrLoc;
    @aaLoc=split(//,"VLIMFWYGAPSTCHRKQEND");
				# ------------------------------
				# open file
    &open_file("$fhinLoc","$fileInLoc") || return(&errSbr("fileInLoc=$fileInLoc, not opened"));
    $ct=0;			# ------------------------------
    while (<$fhinLoc>) {	# read file
	$_=~s/\n//g;
	next if ($_ =~ /^\#/);	# skip comments
				# names
	if (! defined %ptrLoc){ $_=~s/^\s*|\s*$//g;	# purge leading blanks
				@tmp=split(/[\s\t]+/,$_);
				foreach $it (1..$#tmp) {
				    next if ($tmp[$it] !~ /^aa$/ && $tmp[$it] !~ /^[A-Z]$/);
				    if ($tmp[$it] =~ /^aa$/) { $ptrLoc{"aa"}=$it;
							       next; }
				    $ptrLoc{"$tmp[$it]"}=$it; } # amino acid pointer
				next; }
				# formats, if so: skip
	next if (! $ct && $_ =~ /\d+[NSF][\t]|[\t]\d+[NSF]/);
				# --------------------
				# now data
	$_=~s/^\s*|\s*$//g;	# purge leading blanks
	@tmp=split(/[\s\t]+/,$_);
	$res=$tmp[$ptrLoc{"aa"}];
	foreach $it (1..20)  {  $ptr=$ptrLoc{"$aaLoc[$it]"}; # from aa to column number
				$tmp[$ptr]=~s/\s//g; # purge blanks from number
				$tmp{"$res","$aaLoc[$it]"}=$tmp[$ptr]; } # now get into final
    } close($fhinLoc);

    return(1,"ok $sbrName",%tmp);
}				# end of metricRdbRd


#===============================================================================
sub profile_count {
    local ($s1,$s2)=@_;
    local ($aa1,$aa2,$string_aa,@aa);
    $[=1;
#--------------------------------------------------------------------------------
#   profile_count               computes the profile for two sequences
#--------------------------------------------------------------------------------
				# initialise profile counts
    $string_aa=&metric_ini;
    @aa=split(//,$string_aa);
    foreach $aa1(@aa){ foreach $aa2(@aa){
	$profile{"$aa1","$aa2"}=0;
    }}
				# get minimum length
    if (length($s1)>length($s2)){$len=length($s2);}else{$len=length($s1);}
    foreach $it (1..$len){
	$aa1=substr($s1,$it,1);
	$aa2=substr($s2,$it,1);
	++$profile{"$aa1","$aa2"};
    }
    return(%profile);
}				# end of profile_count

#===============================================================================
sub secstr_convert_dsspto3 {
    local ($sec_in) = @_;
    local ($sec_out);
    $[=1;
#----------------------------------------------------------------------
#   secstr_convert_dsspto3      converts DSSP 8 into 3
#----------------------------------------------------------------------

    if ( $sec_in eq "T" ) { $sec_out = " "; }
    elsif ( $sec_in eq "S" ) { $sec_out = " "; }
    elsif ( $sec_in eq " " ) { $sec_out = " "; }
    elsif ( $sec_in eq "B" ) { $sec_out = " "; } 
#    elsif ( $sec_in eq "B" ) { $sec_out = "B"; }
    elsif ( $sec_in eq "E" ) { $sec_out = "E"; }
    elsif ( $sec_in eq "H" ) { $sec_out = "H"; } 
    elsif ( $sec_in eq "G" ) { $sec_out = "H"; }
    elsif ( $sec_in eq "I" ) { $sec_out = "H"; }
    else { $sec_out = " "; } 
    if ( length($sec_out) == 0 ) { 
	print "*** ERROR in sub: secstr_convert_dsspto3, out: -$sec_out- \n";
	exit;}
    $secstr_convert_dsspto3 = $sec_out;
}				# end of secstr_convert_dsspto3 

#===============================================================================
sub seqide_compute {
    local ($s1,$s2) = @_ ;
    local ($ide,$len,$len2,$it);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   seqide_compute              returns pairwise seq identity between 2 strings
#                               (identical length, if not only identity of the first N,
#                               where N is the length of the shorter string, returned)
#       in:                     string1,string2
#       out:                    identity,length
#--------------------------------------------------------------------------------
				# get minimum length
    if (length($s1)>length($s2)){$len=length($s2);}else{$len=length($s1);}
    $ide=$len2=0;		# sum identity
    foreach $it (1..$len){
	$aa1=substr($s1,$it,1);$aa2=substr($s2,$it,1);
				# exclude insertions
	if ( ($aa1=~/[A-Z]/) && ($aa2=~/[A-Z]/) ) {
	    ++$len2;
	    if ($aa1 eq $aa2) {
		++$ide;}}
    }
    return($ide,$len2);
}				# end of seqide_compute

#===============================================================================
sub seqide_exchange {
    local ($s1,$s2,$aa) = @_ ;
    local ($ide,$len,$len2,$it,$aa1,$aa2,%mat);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   seqide_exchange             exchange matrix res type X in seq 1 -> res type Y in seq 2
#       in:                     string1,string2
#       out:                    matrix
#--------------------------------------------------------------------------------
    $#aa=0;@aa=split(//,$aa);
    foreach $it1(@aa){		# ini
	foreach $it2(@aa){
	    $mat{"$it1","$it2"}=0;}}
				# get minimum length
    if (length($s1)>length($s2)){$len=length($s2);}else{$len=length($s1);}
    $ide=$len2=0;		# sum identity
    foreach $it (1..$len){
	$aa1=substr($s1,$it,1);$aa2=substr($s2,$it,1);
				# exclude insertions
	if ( ($aa1=~/[A-Z]/) && ($aa2=~/[A-Z]/) ) {
	    ++$len2;
	    ++$mat{"$aa1","$aa2"}; }}
    return(%mat);
}				# end of seqide_exchange

#===============================================================================
sub seqide_weighted {
    local ($s1,$s2,%metric)=@_;
    local ($aa1,$aa2,$ide,$it,$len,$len2);
    $[=1;
#--------------------------------------------------------------------------------
#   profile_count               computes the weighted similarity
#--------------------------------------------------------------------------------
				# get minimum length
    if (length($s1)>length($s2)){$len=length($s2);}else{$len=length($s1);}
    $ide=$len2=0;
    foreach $it (1..$len){
	$aa1=substr($s1,$it,1);
	$aa2=substr($s2,$it,1);
	next if (! defined $metric{"$aa1","$aa2"});
	if ( ($aa1=~/[A-Z]/) && ($aa2=~/[A-Z]/) ) {
	    ++$len2;
	    $ide+=$metric{"$aa1","$aa2"};}}
    return($ide,$len2);
}				# end of seqide_weighted

#===============================================================================
sub sort_by_pdbid {
    local (@idLoc) = @_ ;
    local ($id,$des,%tmp);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   sort_by_pdbid               sorts a list of ids by alphabet (first number opressed)
#--------------------------------------------------------------------------------
    undef %tmp;
    foreach $id (@idLoc) {
	$des=substr($id,2).substr($id,1,1);
	$tmp{"$des"}=$id; }
    $#idLoc=0;
    foreach $keyid (sort keys(%tmp)){
	push(@idLoc,$id{"$keyid"});}
    undef %tmp;
    return (@idLoc);
}				# end of sort_by_pdbid

#===============================================================================
sub wrt_strings {
    local ($fhout,$num_per_line,$Lspace,@string)=@_;
    $[ =1 ;
#--------------------------------------------------------------------------------
#   wrt_strings                 writes several strings with numbers..
#       in:                     $fhout,$num_per_line,$Lspace,@string , with:
#                               $string[1]= "descriptor 1"
#                               $string[2]= "string 1"
#       out:                    print onto filhandle
#--------------------------------------------------------------------------------
    $it=0;
    $nrows=int($#string/2);
    $len=  length($string[2]);
    while( $it <= $len ){
	$beg=$it+1;
	$it+=$num_per_line;
#	$end=$it;
	print $fhout " " x length($string[1])," ",&myprt_npoints($num_per_line,$beg),"\n";;
	foreach $row(1..$nrows){
	    print $fhout "$string[($row*2)-1]:",substr($string[$row*2],$beg,$num_per_line),"\n";}
	if ($Lspace){
	    print $fhout " \n";}
    }
}				# end of wrt_strings

1;
