#! /usr/bin/perl -w
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
#   convert_acc                 converts accessibility (acc) to relative acc
#   convert_sec                 converts 8 DSSP secondary str. into 3 (H,E,L)= default 
#   convert_secFine             takes an entire string ('HEL') and fine-tunes: ' EHH'-> '  HH'
#   exposure_normalise_prepare  normalisation weights (maximal: Schneider, Dipl)
#   exposure_normalise          normalise DSSP accessibility with maximal values
#   exposure_project_1digit     1
#   filter_hssp_curve           computes HSSP curve based on in:    ali length, seq ide
#   filter_oneprotein           reads .pred files
#   filter1_change              ??? (somehow to do with filter_oneprotein)
#   filter1_rel_lengthen        checks in N- and C-term, whether rel > cut
#   filter1_rel_shorten         checks in N- and C-term, whether rel > cut
#   funcAddMatdb2prof           combines profile read + db matrix (for nali < x)
#   get_id                      extracts an identifier from file name
#   get_pdbid                   extracts a valid PDB identifier from file name
#   get_secstr_segment_caps     returns positions of secondary str. segments in string
#   getDistanceHsspCurve        computes the HSSP curve for in:    ali length
#   getDistanceNewCurveIde      out= pide value for new curve
#   getDistanceNewCurveSim      out= psim value for new curve
#   getDistanceThresh           compiles the distance from a threshold
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
#                               char=HELB  -> H=H,I,G  E=E, B=B, L=rest
#                               char=HELT  -> H=H,I,G  E=E,B  T=T, L=rest
#                               char=HELBT -> H=H,I,G  E=E, B=B, T=T, L=rest
#         default =             HEL
#         in:                   structure-string to convert
#         out:                  (1|0,$msg,converted)
#--------------------------------------------------------------------------------
				# default
    $char="HEL"                 if (! defined $char || ! $char);
				# unused
    if    ($char eq "HL")     { $sec=~s/[IG]/H/g;  $sec=~s/[EBTS !]/L/g;
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
    else { 
	return(&errSbr("char=$char, not recognised\n",0)); }
}				# end of convert_secFine

#==========================================================================
sub exposure_normalise_prepare {
    local ($mode) = @_;
    $[=1;
#----------------------------------------------------------------------
#   exposure_normalise_prepare  normalisation weights (maximal: Schneider, Dipl)
#----------------------------------------------------------------------
#   --------------------------------------------------
#   Reinhard
#   --------------------------------------------------
    if ((!defined $mode)||(length($mode) <= 1)) {
	$NORM_EXP{"A"} =106;  $NORM_EXP{"B"} =160;         # D or N
	$NORM_EXP{"C"} =135;  $NORM_EXP{"D"} =163;  $NORM_EXP{"E"} =194;
	$NORM_EXP{"F"} =197;  $NORM_EXP{"G"} = 84;  $NORM_EXP{"H"} =184;
	$NORM_EXP{"I"} =169;  $NORM_EXP{"K"} =205;  $NORM_EXP{"L"} =164;
	$NORM_EXP{"M"} =188;  $NORM_EXP{"N"} =157;  $NORM_EXP{"P"} =136;
	$NORM_EXP{"Q"} =198;  $NORM_EXP{"R"} =248;  $NORM_EXP{"S"} =130;
	$NORM_EXP{"T"} =142;  $NORM_EXP{"V"} =142;  $NORM_EXP{"W"} =227;
	$NORM_EXP{"X"} =180;         # undetermined (deliberate)
	$NORM_EXP{"Y"} =222;  $NORM_EXP{"Z"} =196;         # E or Q

#   --------------------------------------------------
#   maximal 3 Angstrom water
#   --------------------------------------------------
    } elsif ($mode =~ /3ang/ ) {
	$NORM_EXP{"A"} =179;  $NORM_EXP{"B"} =255;         # D or N
	$NORM_EXP{"C"} = 99;  $NORM_EXP{"D"} =249;  $NORM_EXP{"E"} =279;
	$NORM_EXP{"F"} =199;  $NORM_EXP{"G"} =169;  $NORM_EXP{"H"} =219;
	$NORM_EXP{"I"} =189;  $NORM_EXP{"K"} =309;  $NORM_EXP{"L"} =209;
	$NORM_EXP{"M"} =189;  $NORM_EXP{"N"} =259;  $NORM_EXP{"P"} =189;
	$NORM_EXP{"Q"} =259;  $NORM_EXP{"R"} =299;  $NORM_EXP{"S"} =209;
	$NORM_EXP{"T"} =209;  $NORM_EXP{"V"} =189;  $NORM_EXP{"W"} =239;
	$NORM_EXP{"X"} =200;         # undetermined (deliberate)
	$NORM_EXP{"Y"} =239;  $NORM_EXP{"Z"} =269;         # E or Q

#   --------------------------------------------------
#   maximal 5 Angstrom water
#   --------------------------------------------------
    } elsif ($mode =~ /5ang/ ) {
	$NORM_EXP{"A"} =209;  $NORM_EXP{"B"} =295;         # D or N
	$NORM_EXP{"C"} =139;  $NORM_EXP{"D"} =289;  $NORM_EXP{"E"} =349;
	$NORM_EXP{"F"} =199;  $NORM_EXP{"G"} =219;  $NORM_EXP{"H"} =229;
	$NORM_EXP{"I"} =189;  $NORM_EXP{"K"} =399;  $NORM_EXP{"L"} =239;
	$NORM_EXP{"M"} =189;  $NORM_EXP{"N"} =299;  $NORM_EXP{"P"} =189;
	$NORM_EXP{"Q"} =309;  $NORM_EXP{"R"} =309;  $NORM_EXP{"S"} =259;
	$NORM_EXP{"T"} =239;  $NORM_EXP{"V"} =189;  $NORM_EXP{"W"} =259;
	$NORM_EXP{"X"} =230;         # undetermined (deliberate)
	$NORM_EXP{"Y"} =259;  $NORM_EXP{"Z"} =329;         # E or Q

#   --------------------------------------------------
#   maximal 0.7 Angstrom water
#   --------------------------------------------------
    } elsif ($mode =~ /07ang/ ) {
	$NORM_EXP{"A"} =119;  $NORM_EXP{"B"} =169;         # D or N
	$NORM_EXP{"C"} = 99;  $NORM_EXP{"D"} =169;  $NORM_EXP{"E"} =179;
	$NORM_EXP{"F"} =169;  $NORM_EXP{"G"} =109;  $NORM_EXP{"H"} =173;
	$NORM_EXP{"I"} =159;  $NORM_EXP{"K"} =206;  $NORM_EXP{"L"} =159;
	$NORM_EXP{"M"} =159;  $NORM_EXP{"N"} =169;  $NORM_EXP{"P"} =149;
	$NORM_EXP{"Q"} =169;  $NORM_EXP{"R"} =209;  $NORM_EXP{"S"} =139;
	$NORM_EXP{"T"} =149;  $NORM_EXP{"V"} =149;  $NORM_EXP{"W"} =169;
	$NORM_EXP{"X"} =230;         # undetermined (deliberate)
	$NORM_EXP{"Y"} =189;  $NORM_EXP{"Z"} =175;         # E or Q

#   --------------------------------------------------
#   RS (X=0, from Reinhard
#   --------------------------------------------------
    } elsif ($mode =~/RS/) {
	$NORM_EXP{"A"} =106;  $NORM_EXP{"B"} =157;         # D or N
	$NORM_EXP{"C"} =135;  $NORM_EXP{"D"} =163;  $NORM_EXP{"E"} =194;
	$NORM_EXP{"F"} =197;  $NORM_EXP{"G"} = 84;  $NORM_EXP{"H"} =184;
	$NORM_EXP{"I"} =169;  $NORM_EXP{"K"} =205;  $NORM_EXP{"L"} =164;
	$NORM_EXP{"M"} =188;  $NORM_EXP{"N"} =157;  $NORM_EXP{"P"} =136;
	$NORM_EXP{"Q"} =198;  $NORM_EXP{"R"} =248;  $NORM_EXP{"S"} =130;
	$NORM_EXP{"T"} =142;  $NORM_EXP{"V"} =142;  $NORM_EXP{"W"} =227;
	$NORM_EXP{"X"} =180;         # undetermined (deliberate)
	$NORM_EXP{"Y"} =222;  $NORM_EXP{"Z"} =194;         # E or Q

#   --------------------------------------------------
#   Reinhard
#   --------------------------------------------------
    } else {
	$NORM_EXP{"A"} =106;  $NORM_EXP{"B"} =160;         # D or N
	$NORM_EXP{"C"} =135;  $NORM_EXP{"D"} =163;  $NORM_EXP{"E"} =194;
	$NORM_EXP{"F"} =197;  $NORM_EXP{"G"} = 84;  $NORM_EXP{"H"} =184;
	$NORM_EXP{"I"} =169;  $NORM_EXP{"K"} =205;  $NORM_EXP{"L"} =164;
	$NORM_EXP{"M"} =188;  $NORM_EXP{"N"} =157;  $NORM_EXP{"P"} =136;
	$NORM_EXP{"Q"} =198;  $NORM_EXP{"R"} =248;  $NORM_EXP{"S"} =130;
	$NORM_EXP{"T"} =142;  $NORM_EXP{"V"} =142;  $NORM_EXP{"W"} =227;
	$NORM_EXP{"X"} =180;         # undetermined (deliberate)
	$NORM_EXP{"Y"} =222;  $NORM_EXP{"Z"} =196;         # E or Q
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
	if ( $aa_in=~/[!.]/ ) { $aa_in = "X"; }
	else { print "*** ERROR in exposure_normalise: aa passed wrong: '$aa_in' \n";
	       exit; }}

    if ($NORM_EXP{$aa_in}>0) { $exp_normalise= 100 * ($exp_in / $NORM_EXP{$aa_in});}
    else { print "*** \n*** exposure_normalise, division by zero:aa=$aa_in,acc=$exp_in,norm=",
	   $NORM_EXP{$aa_in},"\n***\n";
	   $exp_normalise=$exp_in/1.8; # ugly ...
	   if ($exp_normalise>100){$exp_normalise=100;}}
    return $exp_normalise;
}				# end of exposure_normalise

#===============================================================================
sub exposure_project_1digit {
    local ($exp_in) = @_;
    local ($exp_out);
    $[=1;
#----------------------------------------------------------------------
#   exposure_project_1digi      project relative exposure (relative) onto numbers 0-9
#                               by: n = max ( 9 , int(sqrt (rel_exp)) )
#----------------------------------------------------------------------
    if ( $exp_in < 0 ) {        # check input
        print "*** ERROR exposure_project_1digit: exposure in = $exp_in \n"; 
	exit;}
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
	     $id=$file;$id=~s/\s|\n//g;$id=~s/.*\///g;$id=~s/\W*(\w+)[.-].*/$1/;
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
#       in:                     $lali
#       out:                    $pide
#                               pide= 510 * L ^ { -0.32 (1 + e ^-(L/1000)) }
#-------------------------------------------------------------------------------
    $sbrName="lib-br:getDistanceNewCurveIde";
    return(0,"*** ERROR $sbrName: lali not defined \n") if (! defined $laliLoc);
    return(0,"*** ERROR $sbrName: '$laliLoc' = alignment length??\n") 
	if (length($laliLoc)<1 || $laliLoc=~/[^0-9.]/);

    $expon= - 0.32 * ( 1 + exp (-$laliLoc/1000) );
    $loc= 510 * $laliLoc ** ($expon);
    $loc=100 if ($loc>100);     # saturation
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
	    &getDistanceHsspCurve($lali); 
	return(&errSbrMsg("failed getDistanceHsspCurve",$msg,$SBR))  if ($msg !~ /^ok/); }
    elsif ($modeLoc =~ /^newSim$/i){
	($pideCurve,$msg)= &getDistanceNewCurveSim($lali); 
	return(&errSbrMsg("failed getDistanceNewCurveSim",$msg,$SBR))  if ($msg !~ /^ok/); }
    else {
	($pideCurve,$msg)= &getDistanceNewCurveIde($lali); 
	return(&errSbrMsg("failed getDistanceNewCurveIde",$msg,$SBR))  if ($msg !~ /^ok/); }

    $dist=$pideLoc - $pideCurve;
    return(1,"ok $sbrName",$dist);
}				# end of getDistanceThresh

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
