#! /usr/pub/bin/perl4
##! /usr/pub/bin/perl
#----------------------------------------------------------------------

#==========================================================================
sub bynumber { $a<=>$b; }

#==========================================================================
sub bynumber_high2low { $b<=>$a; }

#==========================================================================
sub aa3lett_to_1lett {
    local($aain) = @_; 
    local($tmpin,$tmpout);
    $[ =1;

#----------------------------------------------------------------------
#   converts 3 letter code for amino acids into 1 letter
#   GLOBAL: $aa3lett_to_1lett
#----------------------------------------------------------------------

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
	print "*** ERROR in sub (lib-prot) aa3lett_to_1lett:\n";
	print "***       AA in =$aain, doesn't correspond to known acid.\n";
	$tmpout="X";
    }
    $aa3lett_to_1lett=$tmpout;
}                               # end of aa3lett_to_1lett 

#==========================================================================
sub complete_dir {local($dir)=@_; $[=1 ; 
		  if(defined $dir) {$dir=~s/\s|\n//g;}
		  else {
		      return ; }
		  if((defined $dir)&&(length($dir)>1)&&($dir!~/\/$/)){$DIR=$dir."/";}
				    else{$DIR=$dir;} 
		  return $DIR; }

#==========================================================================================
sub convert_acc {
    local ($aa,$acc,$char,$mode) = @_ ;
    local (@tmp1,@tmp2,@tmp,$nio,$it,$tmpacc,$valreturn);
    $[=1;
#--------------------------------------------------------------------------------
#    convert_acc2rel            converts solvent accessibility (acc) to relative 
#                               accessbility
#                               default output is just relative percentage (char = 'unk')
#         input:                AA, (one letter symbol), acc (Angstroem)
#                    note:      output is relative percentage, default if char empty or='unk'
#                                    ============
#                               char='15:100_b:e' -> returns symbols 
#                                    ============
#                                    b for relacc <15, e for relacc>=15
#                                    ===============
#                               char='4:15:100_b:i:e' -> returns symbols 
#                                    ===============
#                                    b for relacc <4, i: 4<=relacc<15, e for relacc>=15
#                               mode=''=default, '3ang', '5ang', '07ang' -> different water
#                                    radius, 'RS' then X=0
#         output:               converted (with return)
#--------------------------------------------------------------------------------

				# default (3 states)
    if ( (length($char)==0)||($char eq "unk")) {
	if (! %NORM_EXP){print "-*- WARNING in convert_acc: NORM_EXP empty \n*** please,";
			 print "    do initialise with exposure_normalise_prepare\n";
			 &exposure_normalise_prepare($mode);}
	$tmp= &exposure_normalise($acc,$aa);
	$valreturn=$tmp;}
				# optional e.g. char='15:100_b:e'
    elsif ($char =~ /\d:\d/) {
	if (! %NORM_EXP ){print "*** ERROR in convert_acc: NORM_EXP empty \n*** please,",
			  print "    do initialise with exposure_normalise_prepare\n";exit;}
	$tmpacc= &exposure_normalise($acc,$aa);

	@tmp=split(/_/,$char);@tmp1=split(/:/,$tmp[1]);@tmp2=split(/:/,$tmp[2]);
	if   ($tmpacc<$tmp1[1])      {$valreturn=$tmp2[1];}
	elsif($tmpacc>=$tmp1[$#tmp1-1]){$valreturn=$tmp2[$#tmp1];}
	else { for ($it=2;$it<$#tmp1;++$it) {
	    if ( ($tmpacc>=$tmp1[$it-1]) && ($tmpacc<$tmp1[$it+1]) ) {
		$valreturn=$tmp2[$it]; last; }}} }
    else {
	print "*** ERROR calling convert_acc (lib-prot) \n";
	print "***       acc=$acc, aa=$aa, char passed (eg. 15:100_b:4)=$char, not ok\n";exit;}

    return $valreturn;

}				# end of convert_acc

#==========================================================================================
sub convert_sec {
    local ($sec,$char) = @_ ;
#--------------------------------------------------------------------------------
#    convert_sec                converts the 8 DSSP secondary structures into 3 (H,E,L) = default 
#                               char=HL    -> H=H,I,G  L=rest
#                               char=HELB  -> H=H,I,G  E=E, B=B, L=rest
#                               char=HELT  -> H=H,I,G  E=E,B  T=T, L=rest
#                               char=HELBT -> H=H,I,G  E=E, B=B, T=T, L=rest
#         input:                structure to convert
#         output:               converted (with return)
#--------------------------------------------------------------------------------
				# default (3 states)
    if ( (length($char)==0)||($char eq "HEL")) {
	if($sec=~/[HIG]/){return"H";}elsif($sec=~/[EB]/){return"E";}else{return"L";} }
				# optional
    elsif ($char eq "HL") {
	if("HIG"=~$sec){return"H";}else{return"L";} }
    elsif ($char eq "HELB") {
	if("HIG"=~$sec){return"H";}elsif("EB"=~$sec){return"$sec";}else{return"L";} }
    elsif ($char eq "HELT") {
	if("HIG"=~$sec){return"H";}elsif("EB"=~$sec){return"E";}elsif("T"=~$sec){return"T";}
	else{return"L";} }
    elsif ($char eq "HELBT") {
	if("HIG"=~$sec){return"H";}elsif("EBT"=~$sec){return"$sec";}else{return"L";} }
    else {
	print "*** ERROR calling convert_sec (lib-prot), sec=$sec, or char=$char, not ok\n";
	exit;}
}				# end of convert_sec

#==========================================================================
sub evalseg_oneprotein {
    local ($sec,$prd)=@_;
    local ($ctseg, $ct, $tmp, $it, $it2, $sym, $symprev, $ctnotloop);
    local (@seg, @ptr, @segbeg);
    $[ =1;
#--------------------------------------------------
#   evaluates the prediction accuracy in terms of 
#   segments for HTM
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
            if ($sym ne " ") { ++$ctnotloop; }
        } else { $seg[$ctseg].=$sym; $ptr[$ctseg].="$it"."-";}
    }
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
    $NOBSH=$#atmp1;$NOBSL=$#atmp2;$NOBS=$NOBSH+$NOBSL;
    $NPRDH=$ctnotloop;$NPRD=$#seg;$NPRDL=$NPRD-$NPRDH;

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
	    else {++$NOP;--$NCP;--$NCPL;}

#       ------------------------------
#       predicted non-helix
	} else {
	    $tmp=substr($sec,$segbeg[$it],length($seg[$it]));
#           ------------------------                   #----------------------
#           correctly predicted loop                   # under-predicted helix
	    if ($tmp!~/HHHHHHHHHHH/) {++$NCP;++$NCPL;} else{++$NUP;}
	}
    }

}                               # end of evalseg_oneprotein

#==========================================================================
sub exposure_normalise_prepare {
    local ($mode) = @_;
    $[=1;
#----------------------------------------------------------------------
#   sets the normalisation weights (maximal: Schneider, Dipl)
#----------------------------------------------------------------------

#   --------------------------------------------------
#   Reinhard
#   --------------------------------------------------
    if ( length($mode) <= 1 ) {
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
}
				# end of exposure_normalise_prepare 

#==========================================================================
sub exposure_normalise {
    local ($exp_in, $aa_in) = @_;
    $[=1;
#----------------------------------------------------------------------
#   normalise DSSP accessibility with maximal values (taken from Schneider)
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
}
				# end of exposure_normalise


#==========================================================================
sub exposure_project_1digit {
    local ($exp_in) = @_;
    local ($exp_out);
    $[=1;
#----------------------------------------------------------------------
#   project the percentage value of exposure (relative) onto numbers 0-9
#   by using: n = max ( 9 , int(sqrt (rel_exp)) )
#----------------------------------------------------------------------
    if ( $exp_in < 0 ) {        # check input
        print "*** ERROR exposure_project_1digit: exposure in = $exp_in \n"; exit;
    }

    $exp_out = int ( sqrt ($exp_in) );
                                # limit to 9
    if ( $exp_out >= 10 ) { $exp_out = 9; }
    $exposure_project_1digit = $exp_out;
    return($exposure_project_1digit);
}
				# end of exposure_project_1digit


#==========================================================================
sub extract_pdbid_from_hssp {
    local ($idloc) = @_;
    local ($fhssp,$tmp,$id);
    $[=1;

#----------------------------------------------------------------------
#   extracts all PDB ids found in the HSSP 0 header
#   note: existence of HSSP file assumed
#   GLOBAL
#   -  $PDBIDS_IN_HSSP "1acx,2bdy,3cez,"...
#----------------------------------------------------------------------

    $idloc=~tr/[A-Z]/[a-z]/;
    $fhssp="/data/hssp+0/"."$idloc".".hssp";
    if (!-e $fhssp) { 
	print "***  ERROR in sub extract_pdbid_from_hssp:$fhssp, not existing\n"; exit;}
    &open_file("FHINTMP1", "$fhssp");
    while (<FHINTMP1>) { last if (/^  NR.    ID/); }

    while (<FHINTMP1>) { 
	last if (/^\#\# ALI/);
	$tmp=$_;$tmp=~s/\n//g;
	$id=substr($_,21,4); $id=~tr/[A-Z]/[a-z]/; $id=~s/\s//g;
	if (length($id)>0) {$PDBIDS_IN_HSSP.="$id".",";}
    }
    close (FHINTMP1);
}

#==========================================================================
sub file_cp { local($f1,$f2,$Lscreen)=@_; $[=1 ;
	      if ($Lscreen){printf "--- %-20s %-s\n","system:","'\\cp $f1 $f2'";}
	      system("\\cp $f1 $f2");}
#==========================================================================
sub file_mv { local($f1,$f2,$Lscreen)=@_; $[=1 ;
	      if ($Lscreen){printf "--- %-20s %-s\n","system:","'\\cp $f1 $f2'";}
	      system("\\mv $f1 $f2");}
#==========================================================================================
sub file_rm {local ($fh,@file) = @_ ;local ($Lscreen,$i) ;$[ =1 ;
	     if (!-e $fh){$Lscreen=1;}else{$Lscreen=0;push(@file,$fh);}
	     foreach $i (@file) { if(-e $i){
		 if($Lscreen){printf $fh "--- %-20s %-s\n","system:","'\\rm $i'";}
		 system("\\rm $i");} } }

#==========================================================================================
sub filter_hssp_curve {
    local ($lali,$ide,$thresh) = @_ ;
    local ($hssp_line);
    $[=1;
#--------------------------------------------------------------------------------
#   computes the HSSP curve based on the input: ali length, seq ide
#   input:               $lali,$ide,$thresh  
#                        note1: ide=percentage!
#                        note2: thresh=0 for HSSP, 5 for 30%, -5 for 20% ..
#   output GLOBAL:
#      $LABOVE_HSSP_CURVE =1 if ($ide,$lali)>HSSP-line +$thresh
#                        HSSP-curve  according to t(L)=(290.15 * L ** -0.562)
#--------------------------------------------------------------------------------
    if (length($thresh)==0) {$thresh=0;}
    $lali=~s/\s//g;
    if ($lali>80){$hssp_line=25.0;}else{ $hssp_line= 290.15*($lali **(-0.562) );}
    if ( $ide >= ($hssp_line+$thresh) ) {$LABOVE_HSSP_CURVE=1;}else{$LABOVE_HSSP_CURVE=0;}

    return ($LABOVE_HSSP_CURVE);
}				# end of filter_hssp_curve

#==========================================================================
sub fileCp  { local($f1,$f2,$fhoutLoc)=@_; local($tmp);
	      if   (! defined $fhoutLoc){ $fhoutLoc=0;}
	      elsif($fhoutLoc eq "1")     { $fhoutLoc="STDOUT";}
	      if (! -e $f1){$tmp="*** ERROR 'lib-ut:fileCp' in=$f1, missing";
			    if ($fhoutLoc){print $fhoutLoc "$tmp\n";}
			    return(0,"$tmp");}
	      if (! defined $f2){$tmp="*** ERROR 'lib-ut:fileCp' f2=$f2, undefined";
				 if ($fhoutLoc){print $fhoutLoc "$tmp\n";}
				 return(0,"$tmp");}
				 
	      $tmp="'\\cp $f1 $f2'";
	      if ($fhoutLoc){printf $fhoutLoc "--- %-20s %-s\n","system:","$tmp";}
	      system("\\cp $f1 $f2");
	      if (! -e $f2){$tmp="*** ERROR 'lib-ut:fileCp' out=$f2, missing";
			    if ($fhoutLoc){print $fhoutLoc "$tmp\n";}
			    return(0,"$tmp");}
	      return(1,"$tmp");} # end of fileCp

#==========================================================================
sub fileMv  { local($f1,$f2,$fhoutLoc)=@_; local($tmp);
	      if (! -e $f1){$tmp="*** ERROR 'lib-ut:fileMv' in=$f1, missing";
			    if ($fhoutLoc){print $fhoutLoc "$tmp\n";}
			    return(0,"$tmp");}
	      $tmp="'\\mv $f1 $f2'";
	      if ($fhoutLoc){printf $fhoutLoc "--- %-20s %-s\n","system:","$tmp";}
	      system("\\mv $f1 $f2");
	      if (! -e $f2){$tmp="*** ERROR 'lib-ut:fileMv' out=$f2, missing";
			    if ($fhoutLoc){print $fhoutLoc "$tmp\n";}
			    return(0,"$tmp");}
	      return(1,"$tmp");} # end of fileMv

#==========================================================================
sub fileRm  { local($fhoutLoc,@fileLoc)=@_; local($tmp,@tmp,$Lok,$fileLoc);
	      if (-e $fhoutLoc){push(@fileLoc,$fhoutLoc);$fhoutLoc=0;}
	      $Lok=1;$#tmp=0;
	      foreach $fileLoc(@fileLoc){
		  if (-e $fileLoc){
		      $tmp="'\\rm $fileLoc'"; push(@tmp,$tmp);
		      if ($fhoutLoc){printf $fhoutLoc "--- %-20s %-s\n","system:","$tmp";}
		      system("\\rm $fileLoc");}
		  if (-e $fileLoc){
		      $tmp="*** ERROR 'lib-ut:fileRm' '$fileLoc' not deleted";
		      if ($fhoutLoc){print $fhoutLoc "$tmp\n";}
		      $Lok=0; push(@tmp,$tmp);}}
	      return($Lok,@tmp);} # end of fileRm

#==========================================================================
sub filter_oneprotein {
    local ($cutshort,$cutshort_single,$cutrel_single,$cutrelav_single,
           $splitlong,$splitlong2,$splitrel,$splitmaxflip,$splitlong_low,$splitlong_lowrel,
	   $shorten_len,$shorten_rel,$PRD,$REL)=@_;
    local ($ctseg,$ct,$tmp,$it,$it2,$itsplit,$sym,$symprev,$ctnotloop,$tl,
	   $splitn,$splitw,$tmp_isplit,$tmp_min,$tmp_imin,$tmp_i,$tmp_min1,$tmp_minseg,
	   @prev,@next,@seg,@ptr,@segbeg,@iflip,@iflip_beg,$tmpbeg, $tmpend,$Lshorten,$Lsplit,
	   $lenseg,$tmprel,$tmprel2,$splitloc,$nflip_bef,$nflip_aft,$add);
    $[=1;
#--------------------------------------------------
#   reads .pred files
#   GLOBAL:
#   in : - ($PRD, $REL)
#   out:   $LNOT_MEMBRANE, $FIL, $RELFIL,
#--------------------------------------------------
				# --------------------------------------------------
				# extract segments
    @symh=("H","T","M");
    foreach $symh (@symh){
	%seg=&get_secstr_segment_caps($PRD,$symh);
	if ($seg{"$symh","NROWS"}>=1) {$tmp=$symh;
				       last;}}
    $symh=$tmp;			# --------------------------------------------------
				# none found? 
    $nseg=$seg{"$symh","NROWS"};
    if ($nseg<1) {
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
		    &filter1_change($pos); # all GLOBAL
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
		&filter1_change($it); # all GLOBAL
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

#==========================================================================================
sub filter1_change {
    local ($it_htm)=@_;
    $[ =1 ;
#--------------------------------------------------------------------------------
#    filter1_change                       
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

#==========================================================================================
sub filter1_rel_lengthen {
    local ($rel,$cut,$Ncap,$Ccap,$nmax) = @_ ; local ($num,$ct);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    filter1_rel_lengthen   checks in N- and C-term, whether rel > cut
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

#==========================================================================================
sub filter1_rel_shorten {
    local ($rel,$cut,$Ncap,$Ccap,$nmax) = @_ ; local ($num,$ct);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    filter1_rel_shorten   checks in N- and C-term, whether rel > cut
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

#==========================================================================================
sub form_perl2rdb {
    local ($format) = @_ ;
#--------------------------------------------------------------------------------
#    form_perl2rdb                       
#         converts the printf perl format (d,f,s) into RDB format (N,F, ) 
#--------------------------------------------------------------------------------
    $format=~s/[%-]//g;$format=~s/f/F/;$format=~s/d/N/;$format=~s/[s]//;
    return $format;
}				# end of form_perl2rdb

#==========================================================================================
sub form_rdb2perl {
    local ($format) = @_ ;
    local ($tmp);
#--------------------------------------------------------------------------------
#    form_perl2rdb                       
#         converts RDB format (N,F, ) to printf perl format (d,f,s)
#--------------------------------------------------------------------------------
    $format=~s/F/f/;$format=~s/N/d/;$format=~s/(\d+)$/$1s/;
    $tmp=$format; $format="%-"."$tmp";
    return $format;
}				# end of form_perl2rdb

#==========================================================================================
sub get_chain { local ($file) = @_ ; local($chain);$[ =1 ;
#--------------------------------------------------------------------------------
#    get_chain                  extracts a chain identifier from file name
#                               note: assume: '_X' where X is the chain (return upper)
#--------------------------------------------------------------------------------
		$chain=$file;$chain=~s/\n//g;$chain=~s/^.*_(.)$/$1/;$chain=~tr/[a-z]/[A-Z]/;
		return($chain);
}				# end of get_chain

#==========================================================================================
sub get_hssp_file { 
    local ($file_in,$Lscreen,@dir) = @_ ; 
    local($hssp_file,$dir,$tmp,$chain,$Lis_endless,@dir2);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    get_hssp_file              searches all directories for existing HSSP file
#--------------------------------------------------------------------------------
    $#dir2=0;$Lis_endless=0;$chain="";
    foreach $dir(@dir){		# avoid endless loop when calling itself
	if ($dir !~ /is_endless/){push(@dir2,$dir);}else {$Lis_endless=1;}}
    @dir=@dir2;
    
    if ($Lscreen !~ /[01]/){push(@dir,$Lscreen);$Lscreen=0;}
    $hssp_file=$file_in;$hssp_file=~s/\s|\n//g;
    foreach $dir (@dir) {
	$dir=&complete_dir($dir); # add slash at end?
	$tmp="$dir"."$hssp_file"; # try directory
	if ($Lscreen)           { print "--- get_hssp_file: \t trying '$tmp'\n";}
	if (-e $tmp) { $hssp_file=$tmp;
		       last;}
	if ($tmp!~/\.hssp/) {	# missing extension?
	    $tmp.=".hssp";
	    if ($Lscreen)       { print "--- get_hssp_file: \t trying '$tmp'\n";}
	    if (-e $tmp) { $hssp_file=$tmp;
			   last;}}}
    $hssp_file=~s/\s|\n//g;	# security..
    if ( (! -e $hssp_file) && (! $Lis_endless) ) { # still not: cut
	$tmp_file=$file_in; $tmp_file=~s/^([A-Za-z0-9]+).*(\.hssp.*)$/$1$2/g;
	$hssp_file=&get_hssp_file($tmp_file,$Lscreen,"is_endless",@dir); }
    if ( (! -e $hssp_file) && (! $Lis_endless) ) { # still now assume = chain
	$tmp1=substr($file_in,1,4);$chain=substr($file_in,5,1);
	$tmp_file=$file_in; $tmp_file=~s/^($tmp1).*(\.hssp.*)$/$1$2/;
	$hssp_file=&get_hssp_file($tmp_file,$Lscreen,"is_endless",@dir); }
    if (length($chain)>0) {
	return($hssp_file,$chain);}
    else {
	return($hssp_file);}
}				# end of get_hssp_file

#==========================================================================================
sub get_id { local ($file) = @_ ; local($id);$[ =1 ;
#--------------------------------------------------------------------------------
#    get_id                     extracts an identifier from file name
#                               note: assume anything before '.' or '-'
#--------------------------------------------------------------------------------
	     $id=$file;$id=~s/\s|\n//g;$id=~s/.*\///g;$id=~s/\W*(\w+)[.-].*/$1/;
	     return($id);
}				# end of get_id

#================================================================================
sub get_max { $[=1;local($ct,$pos,$max);$max=-1000000;$ct=$pos=0; 
	      foreach $_(@_){if(defined $_){
		  ++$ct; 
		  if($_>$max){$max=$_;$pos=$ct;}}}
	      return ($max,$pos); }

#================================================================================
sub get_min { $[=1;local($ct,$pos,$min);$min=100000; $ct=0; 
	      foreach $_(@_){++$ct; if($_<$min){$min=$_;$pos=$ct;}}
	      return ($min,$pos); }

#==========================================================================================
sub get_pdbid { local ($file) = @_ ; local($id);$[ =1 ;
#--------------------------------------------------------------------------------
#    get_pdbid                  extracts a valid PDB identifier from file name
#                               note: assume \w\w\w\w
#--------------------------------------------------------------------------------
		$id=$file;$id=~s/\s|\n//g;$id=~s/.*\///g;$id=~s/\W*(\w\w\w\w).*/$1/;
		return($id);
}				# end of get_pdbid

#==========================================================================================
sub get_range {
    local ($range_txt,$nall) = @_;
    local (@range,$it,$range1,$range2);
    $[ =1 ;
#--------------------------------------------------------------------------------
    $#range=0;
    if ($range_txt !~ /unk/) {
	if ($range_txt =~ /(\d*|\*)-(\d*|\*)/) { 
	    ($range1,$range2)=split(/-/,$range_txt);
	    if ($range1=~/\*/) {$range1=1;}
	    if ($range2=~/\*/) {$range2=$nall;} 
	    for($it=$range1;$it<=$range2;++$it) {push(@range,$it);} }
	elsif ($range_txt =~ /\,/) {@range=split(/,/,$range_txt);}
	else {print 
		  "*** ERROR in get_range: argument: '$range_txt,$nall' not digestable\n";} 
    } 
    return (@range);
}				# end of get_range


#==========================================================================================
sub get_secstr_segment_caps {
    local ($string,@des) = @_ ;
    local ($des,$it,@beg,@end,%segment);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    get_secstr_segment_caps    returns the positions of secondary structure seg-
#                               ments in a string
#    output:                    $segment{"H","beg",1}= first residue in first helix
#                               $segment{"H","end",1}= last residue in first helix
#--------------------------------------------------------------------------------
    substr($string,0,1)="#";
    foreach $des (@des) {
	$#beg=$#end=0;		# loop over all residues
	foreach $it ( 1 .. (length($string)) ){
	    if   ((substr($string,$it,1) ne "$des")&&(substr($string,($it-1),1) eq "$des")){
		push(@end,($it-1)); }
	    elsif((substr($string,$it,1) eq "$des")&&(substr($string,($it-1),1) ne "$des")){
		push(@beg,$it); }  }
				# consistency check!
	if ($#end != $#beg) {
	    print "*** get_secstr_segment_caps: Nend=",$#end,", Nbeg=",$#beg,",\n";
	    exit;}
	foreach $it (1..$#end){
	    $segment{"$des","beg","$it"}=$beg[$it];
	    $segment{"$des","end","$it"}=$end[$it]; } 
	$segment{"$des","NROWS"}=$#beg;
    }
    return(%segment);
}				# end of get_secstr_segment_caps

#==========================================================================================
sub get_zscore { local ($score,@data) = @_ ; local ($ave,$var,$sig,$zscore);
		 $[ =1 ;
#--------------------------------------------------------------------------------
#    get_zscore                 returns the zscore: (score-ave)/sigma
#--------------------------------------------------------------------------------
		 ($ave,$var)=&stat_avevar(@data);
		 $sig=sqrt($var);
		 if ($sig != 0){ $zscore=($score-$ave)/$sig; }
		 else          { print"x.x get_zscore: sig=$sig,=0?\n";$zscore=0; }
		 return ($zscore);
}				# end of get_zscore

#==========================================================================================
sub hssp_fil_num2txt {
    local ($perc_ide) = @_ ;
    local ($txt,$tmp);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   hssp_fil_num2txt            translates a number for percentage sequence iden-
#                               tity into the input argument for MaxHom, e.g.,
#                               30% => 'FORMULA+5'
#--------------------------------------------------------------------------------
    $txt="0";
    if    ($perc_ide>25) {
	$tmp=$perc_ide-25;
	$txt="FORMULA+"."$tmp"." "; }
    elsif ($perc_ide<25) {
	$tmp=25-$perc_ide;
	$txt="FORMULA-"."$tmp"." "; }
    else {
	$txt="FORMULA "; }
    return($txt);
}				# end of hssp_fil_num2txt

#==========================================================================================
sub hssp_rd_header {
    local ($file_hssp,@num) = @_ ;
    local (@des1,@des2,%ptr,$ptr,$len_strid,$Lis_lon_id,$fhin,
	   %rd,@tmp,$tmp,$beg,$mid,$end,$ct,$id,$strid,$des,$num,$Lok);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    hssp_rd_header             reads the header of an HSSP file for numbers 1..$#num
#--------------------------------------------------------------------------------
				# defaults
    $fhin="FHIN_HSSP_HEADER";

    @des1=         ("IDE","WSIM","IFIR","ILAS","JFIR","JLAS",
		    "LALI","NGAP","LGAP","LEN2");
#    @des2=         ("ID","STRID","NAME");
    @des2=         ("STRID");
    @des3=         ("LEN1");
    $ptr{"IDE"}=   1;
    $ptr{"WSIM"}=  2;
    $ptr{"IFIR"}=  3;
    $ptr{"ILAS"}=  4;
    $ptr{"JFIR"}=  5;
    $ptr{"JLAS"}=  6;
    $ptr{"LALI"}=  7;
    $ptr{"NGAP"}=  8;
    $ptr{"LGAP"}=  9;
    $ptr{"LEN2"}= 10;
#    $ptr{"ACCNUM"}=11;

    $len_strid=    4;		# minimal length to identify PDB identifiers

    if ( ! -e $file_hssp) {	# check existence
	return(0); }
				# ini
    $Lis_long_id=0;
				# read file
    &open_file("$fhin", "$file_hssp");
    while ( <$fhin> ) {		# is it HSSP file?
	if (! /^HSSP /) {
	    return(0); } last; 
    }
    while ( <$fhin> ) {		# length, lond-id
	last if (/^\#\# PROTEINS/); 
	if (/^PARAMETER  LONG-ID :YES/) {$Lis_long_id=1;}
	elsif (/^SEQLENGTH /) {$_=~s/\n|\s|SEQLENGTH//g;
			       $rd{"LEN1"}=$_; }
    }
    while ( <$fhin> ) { 
	last if (/^\#\# ALIGNMENTS/); 
	if (/^  NR\./){next;}	# skip describtors
	if ($Lis_long_id){$beg=substr($_,1,56);$end=substr($_,109);$mid=substr($_,57,115); }
	else {$beg=substr($_,1,28);$end=substr($_,80);$mid=substr($_,29,90); }
	$end=~s/^\s*|\s*$|\n//g; # purge leading blanks
	$mid=~s/^\s*|\s*$//g;	# purge leading blanks

				# begin: counter and id
	$ct=$beg;$ct=~s/\s*(\d+)\s+\:.*/$1/;$ct=~s/\s//g;
				# ------------------------------
	$Lok=0;			# read it?
	foreach $num (@num) {
	    if ($ct eq "$num"){$Lok=1;last;}
	}
	if (! $Lok){next;}

	$beg=~s/.+ \:\s*|\s*$//g;
	if ($Lis_long_id) {
	    $id=$beg;$id=~s/(.+_\S+).*/$1/;
	    $strid=$beg;$strid=~s/$id|\s//g;
	} else {
	    $id=$beg;$id=~s/(.+_\S+).*/$1/;
	    $strid=substr($_,49,6);$strid=~s/\s//g;
	}
	$tmp=$len_strid-1;
	if ( (length($strid)<$len_strid) && 
	    ($id=~/^[0-9][A-Z0-9]{$tmp,$tmp}\s*/) ){
	    $strid=substr($id,1,$len_strid); }
	$rd{"$ct","ID"}=$id;
	$rd{"$ct","STRID"}=$strid;
	$rd{"$ct","NAME"}=$end;
				# middle all info
	$#tmp=0;@tmp=split(/\s+/,$mid);
	foreach $_ (@tmp) {$_=~s/\s//g;}
	foreach $des (@des1){ if ( ! defined $ptr{"$des"}) {next;}
			      $ptr=$ptr{"$des"};
			      $rd{"$ct","$des"}=$tmp[$ptr]; }
    }
    close($fhin);
    return(%rd);
}				# end of hssp_rd_header

#==========================================================================================
sub hsspGetFile { 
    local ($fileInLoc,$Lscreen,@dir) = @_ ; 
    local ($fileHssp,$dir,$tmp,$chainLoc,@dir2,$idLoc);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    hsspGetFile                searches all directories for existing HSSP file
#         input:                $file,$Lscreen,@dir
#         output:               returned file,chain ($hssp,$chain), (if chain in file)
#         watch:                loop onto itself:
#                               1prcH.hssp not found -> try 1prc.hssp
#--------------------------------------------------------------------------------
    $#dir2=$Lok=0;$chainLoc="";$idLoc=$fileInLoc;$idLoc=~s/^.*\///g;
    foreach $dir(@dir){		# avoid endless loop when calling itself
	if ($dir =~ /\/data\/hssp/) { $Lok=1;}
	push(@dir2,$dir);}
    @dir=@dir2;  if (!$Lok){push(@dir,"/data/hssp/");} # give default
    
    if    (! defined $Lscreen){$Lscreen=0;}
    elsif ($Lscreen !~ /[01]/){push(@dir,$Lscreen);$Lscreen=0;}
    $hsspFileTmp=$fileInLoc;$hsspFileTmp=~s/\s|\n//g;
				# loop over all directories
    $fileHssp=&hsspGetFileLoop($hsspFileTmp,$Lscreen,@dir);
    if ( ! -e $fileHssp ) {	# still not: cut
	$tmp_file=$fileInLoc; $tmp_file=~s/^([A-Za-z0-9]+).*(\.hssp.*)$/$1$2/g;
	$fileHssp=&hsspGetFileLoop($tmp_file,$Lscreen,@dir);}
    if ( ! -e $fileHssp ) {	# still not: assume = chainLoc
	$tmp=$fileInLoc;$tmp=~s/^.*\/|\.hssp|_//g;
	$tmp1=substr($tmp,1,4);$chainLoc=substr($tmp,5,1);
	$tmp_file=$tmp1.".hssp";
	$fileHssp=&hsspGetFileLoop($tmp_file,$Lscreen,@dir);}
    if ( ! -e $fileHssp || &is_hssp_empty($fileHssp)) {	# still not: version up
	$tmp1=substr($idLoc,2,3);
	foreach $it(1..9){$tmp_file="$it"."$tmp1".".hssp";
			  $fileHssp=&hsspGetFileLoop($tmp_file,$Lscreen,@dir);}}
    if ( ! -e $fileHssp || &is_hssp_empty($fileHssp))  { 
	return(0);}
    return($fileHssp,$chainLoc);
}				# end of hsspGetFile

#==========================================================================================
sub hsspGetFileLoop { 
    local ($fileInLoop,$Lscreen,@dir) = @_ ; 
    local ($fileOutLoop,$dir,$tmp);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    hsspGetFileLoop            loops over all directories
#         input:                $file,$Lscreen,@dir
#         output:               returned file
#--------------------------------------------------------------------------------
    $fileOutLoop="unk";
    foreach $dir (@dir) {
	$dir=&complete_dir($dir); # add slash at end?
	$tmp="$dir"."$fileInLoop"; # try directory
	if ($Lscreen)           { print "--- hsspGetFileLoop: \t trying '$tmp'\n";}
	if (-e $tmp) { 
	    return($tmp);}
	if ($tmp!~/\.hssp/) {	# missing extension?
	    $tmp.=".hssp";
	    if ($Lscreen)       { print "--- hsspGetFileLoop: \t trying '$tmp'\n";}
	    if (-e $tmp) { 
		return($tmp);}}}
    $fileOutLoop=~s/\s|\n//g;	# security..
    return($fileOutLoop);
}				# end of hsspGetFileLoop

#======================================================================
#    sub: hsspfile_to_pdbid
#======================================================================
sub hsspfile_to_pdbid {
   local ($name_in) = @_; 
   local ($tmp);
   $[=1;

   $tmp =  "$name_in";
   $tmp =~ s/\/data\/hssp\///g;
   $tmp =~ s/\.hssp//g;
   $tmp =~ s/\s//g;
   $hsspfile_to_pdbid = $tmp;
}                               # end of hsspfile_to_pdbid

#==========================================================================================
sub is_dssp {
    local ($file_in) = @_ ;
    local ($fh,$Lis);
#--------------------------------------------------------------------------------
#   checks whether or not file is in DSSP format
#   input:                file
#--------------------------------------------------------------------------------
    if (! -e $file_in) {
	return (0);}
    $fh="FHIN_CHECK_DSSP";&open_file("$fh","$file_in");
    while ( <$fh> ) {
	if (/SECONDARY STRUCTURE DEFINITION BY THE PROGRAM DSSP/){$Lis=1;}else{$Lis=0;}
	last; }
    close($fh);
    return $Lis;
}				# end of is_dssp

#==========================================================================================
sub is_fssp {
    local ($file_in) = @_ ;
    local ($fh,$Lis);
#--------------------------------------------------------------------------------
#   checks whether or not file is in FSSP format
#   input:                file
#--------------------------------------------------------------------------------
    if (! -e $file_in) {
	return (0);}
    $fh="FHIN_CHECK_FSSP";&open_file("$fh", "$file_in");
    while ( <$fh> ) {if (/^FSSP/) {$Lis=1;}else{$Lis=0;}last; }close($fh);
    return $Lis;
}				# end of is_fssp

#==========================================================================================
sub is_hssp {
    local ($file_in) = @_ ;
    local ($fh,$Lis);
#--------------------------------------------------------------------------------
#   checks whether or not file is in HSSP format
#   input:                file
#--------------------------------------------------------------------------------
    if (! -e $file_in) {
	return (0);}
    $fh="FHIN_CHECK_HSSP";&open_file("$fh", "$file_in");
    while ( <$fh> ) {if (/^HSSP/) {$Lis=1;}else{$Lis=0;}last; }close($fh);
    return $Lis;
}				# end of is_hssp

#==========================================================================================
sub is_hssp_empty {
    local ($file_in) = @_ ;
    local ($fh,$Lis);
#--------------------------------------------------------------------------------
#   checks whether or not HSSP file has NALIGN=0
#   input:                file
#--------------------------------------------------------------------------------
    if (! -e $file_in) {
	return (0);}
    $fh="FHIN_CHECK_HSSP";&open_file("$fh", "$file_in");
    while ( <$fh> ) {if (/^NALIGN/) {
	if (/ 0/){ $Lis=1; } else { $Lis=0; } 
	last; } } close($fh); 
    return $Lis;
}				# end of is_hssp_empty

#==========================================================================================
sub is_hssp_list {
    local ($file_in) = @_ ;
    local ($fh,$Lis);
#--------------------------------------------------------------------------------
#   checks whether or not file is a list of HSSP files
#   input:                file
#--------------------------------------------------------------------------------
    if (! -e $file_in) {
	return (0);}
    $fh="FHIN_CHECK_HSSP_LIST";&open_file("$fh", "$file_in");
    while ( <$fh> ) {
	$_=~s/\s|\n//g;
	if ( -e $_ ) {		# is existing file?
	    if (&is_hssp($_)) {$Lis=1; }
	    else { $Lis=0; } }
	else {$Lis=0; } } 
    close($fh);
    return $Lis;
}				# end of is_hssp_list

#==========================================================================================
sub is_odd_number {
    local ($num) = @_ ;local ($fh,$Lis);
#--------------------------------------------------------------------------------
#   checks whether number is odd
#--------------------------------------------------------------------------------
    if (int($num/2) == ($num/2)){
	return 0;}
    else {
	return 1;}
}				# end of is_odd_number

#==========================================================================================
sub is_ppcol {
    local ($file_in) = @_ ;
    local ($fh,$Lis);
#--------------------------------------------------------------------------------
#   checks whether or not file is in RDB format
#   input:                file
#--------------------------------------------------------------------------------
    if (! -e $file_in) {
	return (0);}
    $fh="FHIN_CHECK_HSSP";&open_file("$fh", "$file_in");
    while ( <$fh> ) {$_=~tr/[A-Z]/[a-z]/;
		     if (/^\# pp.*col/) {$Lis=1;}else{$Lis=0;}last; }
    close($fh);
    return $Lis;
}				# end of is_ppcol

#==========================================================================================
sub is_rdb {
    local ($fh_in) = @_ ;
#--------------------------------------------------------------------------------
#   checks whether or not file is in RDB format
#   input:                filehandle
#   output (GLOBAL):      $LIS_RDB
#--------------------------------------------------------------------------------
    if (! -e $file_in) {
	return (0);}
    while ( <$fh_in> ) {
	if (/^\# Perl-RDB/) {$LIS_RDB=1;}else{$LIS_RDB=0;}
	last;
    }
    return $LIS_RDB ;
}				# end of is_rdb

#==========================================================================================
sub is_rdbf {
    local ($file_in) = @_ ;
    local ($fh,$Lis);
#--------------------------------------------------------------------------------
#   checks whether or not file is in RDB format
#   input:                file
#--------------------------------------------------------------------------------
    if (! -e $file_in) {
	return (0);}
    $fh="FHIN_CHECK_RDB";&open_file("$fh", "$file_in");
    while ( <$fh> ) {if (/^\# Perl-RDB/) {$Lis=1;}else{$Lis=0;}last; }close($fh);
    return $Lis;
}				# end of is_rdbf

#==========================================================================================
sub is_rdb_acc {
    local ($file_in) = @_ ;
    local ($fh,$Lisrdb,$Lisacc);
#--------------------------------------------------------------------------------
#   checks whether or not file is in RDB format from PHDacc
#   input:                file
#--------------------------------------------------------------------------------
    if (! -e $file_in) {
	return (0);}
    $fh="FHIN_CHECK_RDB_PHDACC";$Lisrdb=$Lisacc=0;
    &open_file("$fh", "$file_in");
    while ( <$fh> ) {if (/^\# Perl-RDB/) {$Lisrdb=1;}
		     if (! $Lisrdb) {last;}
		     if (/^\# PHD\s*acc/){$Lisacc=1;last;}
		     if (! /^\#/) {last;} }
    close($fh);
    return ($Lisacc);
}				# end of is_rdb_acc

#==========================================================================================
sub is_rdb_htm {
    local ($file_in) = @_ ;
    local ($fh,$Lisrdb,$Lishtm);
#--------------------------------------------------------------------------------
#   checks whether or not file is in RDB format from PHDhtm
#   input:                file
#--------------------------------------------------------------------------------
    if (! -e $file_in) {
	return (0);}
    $fh="FHIN_CHECK_RDB_PHDHTM";$Lisrdb=$Lishtm=0;
    &open_file("$fh", "$file_in");
    while ( <$fh> ) {if (/^\# Perl-RDB/) {$Lisrdb=1;}
		     if (! $Lisrdb) {last;}
		     if (/^\# PHD\s*htm/){$Lishtm=1;last;}
		     if (! /^\#/) {last;} }
    close($fh);
    return ($Lishtm);
}				# end of is_rdb_htm

#==========================================================================================
sub is_rdb_htmref {
    local ($file_in) = @_ ;local ($fh,$Lisrdb,$Lishtm);
#--------------------------------------------------------------------------------
#   checks whether or not file is in RDB format from PHDhtm_ref
#--------------------------------------------------------------------------------
    if (! -e $file_in) {
	return (0);}
    $fh="FHIN_CHECK_RDB_PHDHTM_REF";$Lisrdb=$Lishtm=0;
    &open_file("$fh", "$file_in");
    while ( <$fh> ) {if (/^\# Perl-RDB/) {$Lisrdb=1;}
		     if (! $Lisrdb) {last;}
		     if (/^\# PHD\s*htm_ref/){$Lishtm=1;last;}
		     if (! /^\#/) {last;} }
    close($fh);
    return ($Lishtm);
}				# end of is_rdb_htmref

#==========================================================================================
sub is_rdb_htmtop {
    local ($file_in) = @_ ;local ($fh,$Lisrdb,$Lishtm);
#--------------------------------------------------------------------------------
#   checks whether or not file is in RDB format from PHDhtm_top
#--------------------------------------------------------------------------------
    if (! -e $file_in) {
	return (0);}
    $fh="FHIN_CHECK_RDB_PHDHTM_TOP";$Lisrdb=$Lishtm=0;
    &open_file("$fh", "$file_in");
    while ( <$fh> ) {if (/^\# Perl-RDB/) {$Lisrdb=1;}
		     if (! $Lisrdb) {last;}
		     if (/^\# PHD\s*htm_top/){$Lishtm=1;last;}
		     if (! /^\#/) {last;} }
    close($fh);
    return ($Lishtm);
}				# end of is_rdb_htmtop

#==========================================================================================
sub is_rdb_sec {
    local ($file_in) = @_ ;
    local ($fh,$Lisrdb,$Lissec);
#--------------------------------------------------------------------------------
#   checks whether or not file is in RDB format from PHDsec
#   input:                file
#--------------------------------------------------------------------------------
    if (! -e $file_in) {
	return (0);}
    $fh="FHIN_CHECK_RDB_PHDSEC";$Lisrdb=$Lissec=0;
    &open_file("$fh", "$file_in");
    while ( <$fh> ) {if (/^\# Perl-RDB/) {$Lisrdb=1;}
		     if (! $Lisrdb) {last;}
		     if (/^\# PHD\s*sec/){$Lissec=1;last;}
		     if (! /^\#/) {last;} }
    close($fh);
    return ($Lissec);
}				# end of is_rdb_sec

#==========================================================================================
sub is_strip {
    local ($file_in) = @_ ;
    local ($fh,$Lis);
#--------------------------------------------------------------------------------
#   checks whether or not file is in HSSP-strip format
#   input:                file
#--------------------------------------------------------------------------------
    if (! -e $file_in) {
	return (0);}
    $fh="FHIN_CHECK_STRIP";&open_file("$fh", "$file_in");
    while ( <$fh> ) {if (/===  MAXHOM-STRIP  ===/) {$Lis=1;}else{$Lis=0;}last; }close($fh);
    return $Lis;
}				# end of is_strip

#================================================================================
sub max { $[=1;local($ct,$max,$pos);$max=(-1000000); $ct=0;
	  foreach $_(@_){++$ct;if ($_>$max){$max=$_;$pos=$ct;}}
	  return ($max,$pos); }

#================================================================================
sub min { $[=1;local($ct,$min,$pos);$min=100000; $ct=0;
	  foreach $_(@_){++$ct;if ($_<$min){$min=$_;$pos=$ct;}}
	  return ($min,$pos); }

#======================================================================
sub open_file {
    local ($file_handle, $file_name, $log_file) = @_ ;
    local ($temp_name) ;

    $temp_name = $file_name ;
    $temp_name =~ s/^>>|^>//g ;
    if ( ($file_name =~ m/^>>/ ) && ( ! -e $temp_name ) ) {
       print "*** \t INFO: file $temp_name does not exist; create it\n" ;
       open ($file_handle, ">$temp_name") || ( do {
             warn "***\t Can't create new file: $temp_name\n" ;
             if ( $log_file ) {
                print $log_file "***\t Can't create new file: $temp_name\n" ;
             }
       } );
       close ("$file_handle") ;
    }
  
    open ($file_handle, "$file_name") || ( do {
             warn "*** \t Can't open file '$file_name'\n" ;
             if ( $log_file ) {
                print $log_file "*** \t Can't create new file '$file_name'\n" ;
             }
             return (0) ;
       } );
}

#======================================================================
sub myprt_line { print "-" x 70, "\n", "--- \n"; }
#======================================================================
sub myprt_empty { print "--- \n"; }
#======================================================================
sub myprt_txt { local ($string) = @_; print "--- $string \n"; }

#======================================================================
#    sub: myprt_points
#======================================================================
sub myprt_npoints {
   local ($npoints,$num_in) = @_; 
   local ($num,$beg,$ctprev,$ct,$numprev, $tmp,$tmp1,$tmp2, $out, $ct, $i);
   $[=1;

   if ( int($npoints/10)!=($npoints/10) ) {
       print "*** ERROR in myprt_npoints (lib-prot.pl): \n";
       print "***       number of points passed should be multiple of 10!\n"; exit;
   }


   $ct=int(($num_in-1)/$npoints);
   $beg=$ct*$npoints; $num=$beg;
   for ($i=1;$i<=($npoints/10);++$i) {
       $numprev=$num; $num=$beg+($i*10);
       $ctprev=$numprev/10;
       if ( $i==1 ) { $tmp=substr($num,1,1); $out="....,....".$tmp; 
       } elsif ( $ctprev<10 ) {  $tmp=substr($num,1,1); $out.="....,....".$tmp; 
       } elsif ( ($i==($npoints/10))&&($ctprev>=9) ) { 
           $tmp1=substr($ctprev,2);$tmp2="." x (4-length($tmp1));
           $out.=$tmp1.$tmp2.",....".substr(($num/10),1); 
       } else {
           $tmp1=substr($ctprev,2);$tmp2="." x (4-length($tmp1));
           $out.=$tmp1.$tmp2.",....".substr($num,1,1); 
       }
   }

   $myprt_npoints=$out;
   return ($myprt_npoints);
} 
# end of myprt_npoints

#======================================================================
#    sub: myprt_points80
#======================================================================
sub myprt_points80 {
   local ($num_in) = @_; 
   local ($tmp9, $tmp8, $tmp7, $tmp, $out, $ct, $i);
   $[=1;

   $tmp9 = "....,...."; $tmp8 =  "...,...."; $tmp7 =   "..,....";
   $ct   = (  int ( ($num_in -1 ) / 80 )  *  8  );
   $out  = "$tmp9";
   if ( $ct == 0 ) {
       for( $i=1; $i<8; $i++ ) {
	   $out .= "$i" . "$tmp9" ;
       }
       $out .= "8";
   } elsif ( $ct == 8 ) {
       $out .= "9" . "$tmp9";
       for( $i=2; $i<8; $i++ ) {
	   $tmp = $ct+$i;
	   $out .= "$tmp" . "$tmp8" ;
       }
       $out .= "16";
   } elsif ( ($ct>8) && ($ct<96) ) {
       for( $i=1; $i<8; $i++ ) {
	   $tmp = $ct+$i;
	   $out .= "$tmp" . "$tmp8" ;
       }
       $tmp = $ct+8;
       $out .= "$tmp";
   } elsif ( $ct == 96 ) {
       for( $i=1; $i<=3; $i++ ) {
	   $tmp = $ct+$i;
	   $out .= "$tmp" . "$tmp8" ;
       }
       for( $i=4; $i<8; $i++ ) {
	   $tmp = $ct+$i;
	   $out .= "$tmp" . "$tmp7" ;
       }
       $tmp = $ct+8;
       $out .= "$tmp" ;
   } else {
       for( $i=1; $i<8 ; $i++ ) {
	   $tmp = $ct+$i;
	   $out .= "$tmp" . "$tmp7" ;
       }
       $tmp = $ct+8;
       $out .= "$tmp" ;
   }
   $myprt_points80=$out;
}
				# end of myprt_points80
#==========================================================================
sub numerically { $a<=>$b; }

#======================================================================
#    sub: pdbid_to_hsspfile 
#======================================================================
sub pdbid_to_hsspfile {
   local ($name_in,$dir_hssp,$ext_hssp) = @_; 
   local ($tmp);
   $[=1;

   if (length($dir_hssp)==0)     { $tmp = "/data/hssp/";
   } elsif ($dir_hssp =~ /here/) { $tmp = "";
   } else                        { $tmp = "$dir_hssp"; $tmp=~s/\s|\n//g;
   }
   if (length($ext_hssp)==0)     { $ext_hssp=".hssp"; }

   $name_in =~ s/\s//g;
   $pdbid_to_hsspfile = "$tmp" . "$name_in" . "$ext_hssp";
}
				# end of pdbid_to_hsspfile 

#==========================================================================================
sub printm { local ($txt,@fh) = @_ ;local ($fh);
	     $[ =1 ;
#--------------------------------------------------------------------------------
#    sub: printm                print on multiple filehandles (in:$txt,@fh; out:print)
#--------------------------------------------------------------------------------
	     foreach $fh (@fh) { 
		 if ( (! eof($fh)) || ($fh eq "STDOUT") ) { 
		     print $fh $txt;}}
}				# end of printm

#==========================================================================================
sub rd_hssp_extr_header {
    local ($file_in) = @_ ;
    local ($fhin,$ct,$tmp,$tmp2,@tmp,$it);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    hssp_extr_header           extracts the summary from HSSP header         
#       out (GLOBAL):           $rd_hssp{}
#--------------------------------------------------------------------------------
    $fhin="FHIN_HSSP_TOPITS";
    open($fhin, "$file_in") || warn "Can't open '$file_in' (hssp_extr_header)\n"; 
    while(<$fhin>){
	last if (/^\#\# PROTEINS/);}
    $ct=0;
    while(<$fhin>){
	last if (/^\#\# ALI/);
	$tmp=substr($_,27);
	$tmp=~s/^\s*|\s$//g;	# purge leading blanks
	$#tmp=0;@tmp=split(/\s+/,$tmp);
	if (! /^  NR/) {	# is NOT descriptor line
	    ++$ct;
	    $rd_hssp{"ide","$ct"}=$tmp[1];
	    $rd_hssp{"ifir","$ct"}=$tmp[3];
	    $rd_hssp{"ilas","$ct"}=$tmp[4];
	    $rd_hssp{"jfir","$ct"}=$tmp[5];
	    $rd_hssp{"jlas","$ct"}=$tmp[6];
	    $rd_hssp{"lali","$ct"}=$tmp[7];
	    $rd_hssp{"ngap","$ct"}=$tmp[8];
	    $rd_hssp{"lgap","$ct"}=$tmp[9];
	    $rd_hssp{"len2","$ct"}=$tmp[10];

	    $tmp= substr($_,7,20);
	    $tmp2=substr($_,20,7);
	    $tmp3=$tmp2; $tmp3=~s/\s//g;
	    if (length($tmp3)<3) {	# STRID empty
		$tmp=substr($_,8,6);
		$tmp=~s/\s//g;
		$rd_hssp{"id2","$ct"}=$tmp;
	    }else{
		$tmp2=~s/\s//g;
		$rd_hssp{"id2","$ct"}=$tmp2;
	    }
	}
    }
    close($fhin);
    $rd_hssp{"nali"}=$ct;
    return(%rd_hssp);
}				# end of rd_hssp_extr_header


#==========================================================================================
sub rd_col_associative {
    local ($file_in,@des_in) = @_ ;
    local ($sbr_name,$fhin,$it,@tmp,$tmp,$des_in,
	   %ptr,%rdcol);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    rd_rdb_associative         reads the content of a comma separated file
#       in:                     Names used for columns in perl file, e.g.,
#--------------------------------------------------------------------------------
				# avoid warning
    $READHEADER="";
				# set some defaults
    $fhin="FHIN_COL";
    $sbr_name="rd_col_associative";
				# --------------------------------------------------
				# read RDB file
				# --------------------------------------------------
    &open_file("$fhin","$file_in");
    $ct=0;
    while(<$fhin>){
	$_=~s/\n//g;
	if (/^\#/){next;}	# ignore RDB header
	++$ct;			# delete leading blanks, commatas and tabs
	$_=~s/^\s*|\s*$|^,|,$|^\t|\t$//g;
	$#tmp=0;@tmp=split(/[,\t ]+/,$_);
	if ($ct==1){
	    $Lok=0;
	    foreach $des (@des_in) {
		foreach $it (1..$#tmp) {
		    if ($des =~ /$tmp[$it]/){
			$ptr{$des}=$it;
			$Lok=1;last;}}}
	    if (!$Lok){print"*** ERROR in reading col format ($sbr_name), none found\n";
		       exit;}
	} else {
	    foreach $des (@des_in){
		if (defined $ptr{$des}){
		    $tmp=$ct-1;
		    $rdcol{"$des","$tmp"}=$tmp[$ptr{$des}];
		}}
	}
    }
    close($fhin);
    $rdcol{"NROWS"}=$ct-1;
    return (%rdcol);
}				# end of rd_col_associative

#==========================================================================================
sub rd_rdb_associative {
    local ($file_in,@des_in) = @_ ;
    local ($sbr_name,$fhin,$Lhead,$Lbody,$Lfound,$it,$itrd,@tmp,$tmp,$des_in,$rd,
	   @des_head,@des_headin,@des_bodyin,@des_body,%ptr_rd2des,$nrow_rd,%rdrdb,
	   $Lscreen);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    rd_rdb_associative         reads the content of an RDB file into an associative
#                               array
#       in:                     Names used for columns in perl file, e.g.,
#                               "header,NALIGN,body,POS,NPROT" as arguments passed
#                               would result in:
#                               reading anything in file header using the keyword 'NALIGN'
#                               reading the columns named POS and NPROT
#       out:                    rdrdb{"NALIGN"},rdrdb{"POS","ct"},rdrdb{"NPROT","ct"},
#                               where ct counts the rows read,
#                               rdrdb{"NROWS"} returns the numbers of rows read
#--------------------------------------------------------------------------------
				# avoid warning
    $READHEADER="";
    $Lscreen=1;
				# set some defaults
    $fhin="FHIN_RDB";
    $sbr_name="rd_rdb_associative";
				# get input
    $Lhead=$Lbody=$#des_headin=$#des_bodyin=0;
    foreach $des_in(@des_in){
	if   (!$Lhead&&($des_in=~/head/)){$Lhead=1;$Lhead_all=1;}
	elsif(!$Lbody&&($des_in=~/body/)){$Lbody=1;$Lhead=0; }
	elsif($Lhead)  { push(@des_headin,$des_in);}
	elsif($Lbody)  { $des_in=~s/\n|\s//g;;push(@des_bodyin,$des_in);}
	elsif($des_in=~/not_screen/){$Lscreen=0;}
	else {print "*** WARNING $sbr_name: input '$des_in' not recognised.\n";} }
    if ($Lscreen) { print "--- $sbr_name: header \t ";
		    foreach $it (@des_headin){print"$it,";}print"\n"; 
		    print "--- $sbr_name: body   \t ";
		    foreach $it (@des_bodyin){print"$it,";}print"\n"; }
				# --------------------------------------------------
				# read RDB file
				# --------------------------------------------------
    &open_file("$fhin","$file_in");
				# out: $READHEADER :whole header, one string
				#      @READCOL    : all columns
				#      @READNAME   :names of columns
    &read_rdb_num2($fhin,0);
    close($fhin);
				# ------------------------------
				# process header
    $#des_head=0;
    @tmp=split(/\#\s?/,$READHEADER);
    if ($#des_headin>=1){
	foreach $des_in (@des_headin) {
	    $Lfound=0;
	    foreach $rd (@tmp){
		if ($rd =~ /^$des_in[ :,\;]/){
		    $tmp=$rd;$tmp=~s/\n|\s$//g;
		    $tmp=~s/$des_in//g;$tmp=~s/^\s*//g;
		    if (defined $rdrdb{"$des_in"}){
			$rdrdb{"$des_in"}.="\t".$tmp;}
		    else {
			$rdrdb{"$des_in"}=$tmp;}
		    push(@des_head,$des_in);
		    $Lfound=1;}
#				       last;}
	    }
	    if(!$Lfound && $Lscreen){
		print"--- $sbr_name: \t expected to find in header key word:\n";
		print"---            \t '$des_in', but not in file '$file_in'\n";}
	}}
    elsif ($Lhead_all) {		# whole header into $rdrdb{"header"}
	$rdrdb{"header"}="";
	foreach $rd (@tmp) { 
	    $rd=~s/^\s?|\n//g;
	    $rdrdb{"header"}.="# ".$rd."\n"; }}
				# ------------------------------
				# get column numbers to be read
    $#des_body=0;
    foreach $des_in (@des_bodyin) {
	$Lfound=0;
	for($it=1;$it<=$#READNAME;++$it) {
	    $rd=$READNAME[$it];
	    if ($rd =~ /$des_in/) {$ptr_rd2des{"$des_in"}=$it;push(@des_body,$des_in);
				   $Lfound=1;last;} }
	if(!$Lfound&&$Lscreen){
	    print"--- $sbr_name: \t expected to find column name:\n";
	    print"---            \t '$des_in', but not in file '$file_in'\n";}
    }
				# ------------------------------
				# get format
    foreach $des_in(@des_bodyin) {
	$it=$ptr_rd2des{"$des_in"};
	if ( (defined $it) && (defined $READFORMAT[$it]) ) {
	    $rdrdb{"$des_in","format"}=$READFORMAT[$it];}
	else {
	    $rdrdb{"$des_in","format"}="8";}}

    $nrow_rd=0;
    foreach $des_in(@des_body) {
	$itrd=$ptr_rd2des{"$des_in"};
	@tmp=split(/\t/,$READCOL[$itrd]);
	if ($nrow_rd==0){$nrow_rd=$#tmp;}
	elsif($nrow_rd!=$#tmp){print "*** WARNING $sbr_name: different number of rows\n";
			       print "*** WARNING in RDB file '$file_in' for rows with ".
				   "key= $des_in and previous column no=$itrd,\n";}
	for($it=1;$it<=$#tmp;++$it){$rdrdb{"$des_in","$it"}=$tmp[$it];}
    }
    $rdrdb{"NROWS"}=$rdrdb{"NROWS"}=$nrow_rd;
    return (%rdrdb);
}				# end of rd_rdb_associative

#==========================================================================================
sub rd_strip_pp {
    local ($file_in) = @_ ;
    local ($fhin,@strip);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    rd_strip_pp                reads the new strip file generated for PP
#            output             full file as array @strip
#--------------------------------------------------------------------------------
    $fhin="FHIN_STRIP_TOPITS";
    open($fhin, "$file_in") || warn "Can't open '$file_in' (rd_strip_pp)\n"; 
    while(<$fhin>){
	$_=~s/\n//g;
	push(@strip,$_);
    }
    return(@strip);
}				# end of rd_strip_pp

#==========================================================================================
sub rdbphd_to_dotpred {
    local($Lscreen,$nres_per_row,$thresh_acc,$thresh_htm,$thresh_sec,
	  $opt_phd,$file_out,$protname,$Ldo_htmref,$Ldo_htmtop,@file) = @_ ;
    local($fhin,@des,@des_rd,@des_sec,@des_rd_sec,@des_acc,@des_rd_acc,@des_htm,@des_rd_htm,
	  %rdb_rd,%rdb,$file,$it,$ct,$mode_wrt,$fhout);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    rdbphd_to_dotpred          converts RDB files of PHDsec,acc,htm (both/3)
#                               to .pred files as used for PP server
#--------------------------------------------------------------------------------
    $fhin= "FHIN_RDBPHD_TO_DOTPRED";
    $fhout="FHOUT_RDBPHD_TO_DOTPRED";
				# note: @des same succession as @des_rd !!
    @des_rd_0 =   ("No", "AA");
    @des_0=       ("pos","aa");
    @des_rd_acc=  ("Obie","Pbie","OREL","PREL","RI_A");
    @des_acc=     ("obie","pbie","oacc","pacc","riacc");
    if    ($Ldo_htmref && $Ldo_htmtop) {
	@des_rd_htm=("OHL", "PHL", "RI_S", "pH",    "pL"    ,"PFHL", "PRHL", "PiTo" );
	@des_htm=   ("ohtm","phtm","rihtm","prHhtm","prLhtm","pfhtm","prhtm","pthtm");}
    elsif ($Ldo_htmref) {
	@des_rd_htm=("OHL", "PHL", "RI_S", "pH",    "pL"    ,"PFHL", "PRHL");
	@des_htm=   ("ohtm","phtm","rihtm","prHhtm","prLhtm","pfhtm","prhtm");}
    elsif ($Ldo_htmtop) {
	@des_rd_htm=("OHL", "PHL", "RI_S", "pH",    "pL"    ,"PFHL" ,"PiTo" );
	@des_htm=   ("ohtm","phtm","rihtm","prHhtm","prLhtm","pfhtm","pthtm");}
    else {
	@des_rd_htm=("OHL", "PHL", "RI_S", "pH",    "pL"    ,"PFHL" );
	@des_htm=   ("ohtm","phtm","rihtm","prHhtm","prLhtm","pfhtm");}
    @des_rd_sec=  ("OHEL","PHEL","RI_S", "pH",    "pE",    "pL");
    @des_sec=     ("osec","psec","risec","prHsec","prEsec","prLsec");
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
	if (! -e $file) { next; }
	++$ct;%rdb_rd=0;
	if ($ct==1) {
	    @des_rd=@des_rd_0;@des=@des_0;@deshd_rd=@deshd_rd_0;}
	else {
	    $#des_rd=$#des=$#deshd_rd=0;}
				# find out whether from PHDsec, PHDacc, or PHDhtm
	if   (&is_rdb_sec($file)){$phd="sec";push(@des_rd,@des_rd_sec);push(@des,@des_sec);}
	elsif(&is_rdb_acc($file)){$phd="acc";push(@des_rd,@des_rd_acc);push(@des,@des_acc);}
	elsif(&is_rdb_htm($file)||&is_rdb_htmref($file)||&is_rdb_htmtop($file)){
	    $phd="htm";push(@des,@des_htm);
	    push(@des_rd,@des_rd_htm);push(@deshd_rd,@deshd_rd_htm);}
	else {
	    print "*** ERROR rdbphd_to_dotpred: no RDB format recognised\n";
	    exit; }
	%rdb_rd=
	    &rd_rdb_associative($file,"not_screen","header",@deshd_rd,"body",@des_rd); 
	foreach $it (1 .. $#des_rd) { # rename data (separate for PHDsec,acc,htm)
	    $ct=1;
	    while (defined $rdb_rd{"$des_rd[$it]","$ct"}) {
		$rdb{"$des[$it]","$ct"}=$rdb_rd{"$des_rd[$it]","$ct"}; 
		++$ct; }}
	foreach $deshd (@deshd_rd){ # rename header
	    if (defined $rdb_rd{"$deshd"}) {$rdb{"$deshd"}=$rdb_rd{"$deshd"};} 
	    else                           {$rdb{"$deshd"}="UNK";}}
    }
				# ------------------------------
				# now transform to strings
				# ------------------------------
    &rdbphd_to_dotpred_getstring(@des_0,@des_sec,@des_acc,@des_htm);
				# now subsets
    &rdbphd_to_dotpred_getsubset;
				# convert symbols
    if (defined $STRING{"osec"}) { $STRING{"osec"}=~s/L/ /g; }
    if (defined $STRING{"psec"}) { $STRING{"psec"}=~s/L/ /g; }
    if (defined $STRING{"obie"}) { $STRING{"obie"}=~s/i/ /g; }
    if (defined $STRING{"pbie"}) { $STRING{"pbie"}=~s/i/ /g; }
    if (defined $STRING{"ohtm"}) { 
	$STRING{"ohtm"}=~s/L/ /g;  if ($opt_phd !~ /htm/){
	    $STRING{"ohtm"}=~s/H/T/g;$STRING{"ohtm"}=~s/E/ /g; }}
    if (defined $STRING{"phtm"}) { 
	$STRING{"phtm"}=~s/L/ /g;  if ($opt_phd !~ /htm/){
	    $STRING{"phtm"}=~s/H/T/g;$STRING{"phtm"}=~s/E/ /g; }}
    if (defined $STRING{"pfhtm"}) { 
	$STRING{"pfhtm"}=~s/L/ /g; if ($opt_phd !~ /htm/){
	    $STRING{"pfhtm"}=~s/H/T/g;$STRING{"pfhtm"}=~s/E/ /g; }}
    if (defined $STRING{"prhtm"}) { 
	$STRING{"prhtm"}=~s/L/ /g; if ($opt_phd !~ /htm/){
	    $STRING{"prhtm"}=~s/H/T/g;$STRING{"prhtm"}=~s/E/ /g; }}

    @des_wrt=@des_0;
    $#htm_header=0;
    if    ( (length($STRING{"psec"})>3) && (length($STRING{"pacc"})>3) && 
	    (length($STRING{"phtm"})>3) ) { 
	push(@des_wrt,@des_sec,"subsec",@des_acc,"subacc",@des_htm,"subhtm"); $mode_wrt="3";}
    elsif ( (length($STRING{"psec"})>3) && (length($STRING{"pacc"})>3) ) {
	push(@des_wrt,@des_sec,"subsec",@des_acc,"subacc"); $mode_wrt="both"; }
    elsif ( length($STRING{"psec"})>3 ) { 
	push(@des_wrt,@des_sec,"subsec");                   $mode_wrt="sec"; }
    elsif ( length($STRING{"pacc"})>3 ) { 
	push(@des_wrt,@des_acc,"subacc");                   $mode_wrt="acc"; }
    elsif ( length($STRING{"phtm"})>3 ) { 
	push(@des_wrt,"ohtm","phtm","rihtm","prHhtm","prLhtm","subhtm","pfhtm");
	if ($Ldo_htmref){ push(@des_wrt,"prhtm");}
	if ($Ldo_htmtop){ push(@des_wrt,"pthtm");}
	$mode_wrt="htm"; 
	if ($Ldo_htmref || $Ldo_htmtop){
	    @htm_header=&rdbphd_to_dotpred_head_htmtop(@deshd_rd_htm);}}
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
    return(%phd_fin);
}				# end of rdbphd_to_dotpred

#==========================================================================================
sub rdbphd_to_dotpred_getstring {
    local (@des) = @_ ;
    local ($des,$ct);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    rdbphd_to_dotpred_getstring transform $rdb{"osec","1..n"} to $STRING{"osec"}
#    GLOBAL                     %STRING, %rdb
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

#==========================================================================================
sub rdbphd_to_dotpred_getsubset {
    local ($des,$ct,$desout,$thresh,$desphd,$desrel);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    rdbphd_to_dotpred_getsubset assigns subsets:
#    GLOBAL                     %STRING, %rdb,$thresh_*,
#--------------------------------------------------------------------------------
    foreach $des ("sec","acc","htm"){
	$desout="sub"."$des";
				# assign thresholds
	if    ($des eq "sec") { $thresh=$thresh_sec; }
	elsif ($des eq "acc") { $thresh=$thresh_acc; }
	elsif ($des eq "htm") { $thresh=$thresh_htm; }
	$STRING{"$desout"}="";$ct=1; # initialise
				# note: for PHDacc subset on three states (b,e,i)
	if ($des eq "acc") {$desphd="p"."bie";} else { $desphd="p"."$des"; }
	$desrel="ri"."$des";
	while ( defined $rdb{"$desphd","$ct"}) {
	    if ($rdb{"$desrel","$ct"}>=$thresh) {
		$STRING{"$desout"}.=$rdb{"$desphd","$ct"}; }
	    else {
		$STRING{"$desout"}.=".";}
	    ++$ct; }}
}				# end of rdbphd_to_dotpred_getsubset

#==========================================================================================
sub rdbphd_to_dotpred_head_htmtop {
    local (@des)= @_ ;  local ($des,$tmp,@tmp,@out);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    rdbphd_to_dotpred_head_htmtop: writes the header for htmtop
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

#==========================================================================
sub read_dssp_seqsecacc {
    local ($fh_in, $chain_in, $beg_in, $end_in ) = @_ ;
    local ($Lread, $sub_name);
    local ($tmpchain, $tmpseq, $tmpsecstr, $tmpexp, $tmppospdb, $tmpseq2, $tmpsecstr2);
   $[=1;

#----------------------------------------------------------------------
#   reads sequence, secondary structure and accessibility from DSSP file
#   (file expected to be open handle = $fh_in).  The reading is restricted
#   by: chain_in, beg_in, end_in, which are passed in the following manner:
#   (say chain = A, begin = 2 (PDB position), end = 10 (PDB position):
#   "A 2 10"
#   Wild cards allowed for any of the three.
#         input:  file_handle, chain, begin, end
#         output: SEQDSSP, SECDSSP, ACCDSSP, PDBPOS
#   GLOBAL:       all output stuff is assumed to be global
#----------------------------------------------------------------------
    $sub_name = "read_dssp_seqsecacc" ;

#----------------------------------------
#   setting to zero
#----------------------------------------
    $#SEQDSSP=0; $#SECDSSP=0; $#ACCDSSP=0; $#PDBPOS=0; 

#----------------------------------------
#   extract input
#----------------------------------------
    if ( length($chain_in) == 0 ) { $chain_in = "*" ; }
    else { $chain_in =~tr/[a-z]/[A-Z]/; }

    if ( length($beg_in) == 0 )   { $beg_in = "*" ; }
    if ( length($end_in) == 0 )   { $end_in = "*" ; }
    $fh_in=~s/\s//g; $chain_in=~s/\s//g; $beg_in=~s/\s//g; $end_in=~s/\s//g; 

#--------------------------------------------------
#   read in file
#--------------------------------------------------

#----------------------------------------
#   skip anything before data...
#----------------------------------------
    while ( <$fh_in> ) { last if ( /^  \#  RESIDUE/ ); }
 
#----------------------------------------
#   read sequence
#----------------------------------------
    while ( <$fh_in> ) {
	$Lread=1;
	$tmpchain = substr($_,12,1); 
	$tmppospdb= substr($_,7,5); $tmppospdb=~s/\s//g;

#     check chain
	if ( ($tmpchain ne "$chain_in") && ($chain_in ne "*") ) { $Lread=0; }
#     check begin
	if ( $beg_in ne "*" ) {
	    if ( $tmppospdb < $beg_in ) { $Lread=0; }
	}
#     check end
	if ( $end_in ne "*" ) {
	    if ( $tmppospdb > $end_in ) { $Lread=0; }
	}

	if ($Lread) {
	    $tmpseq    = substr($_,14,1);
	    $tmpsecstr = substr($_,17,1);
	    $tmpexp    = substr($_,36,3);

#        lower case letter to C
	    $tmpseq2 = $tmpseq;
	    if ($tmpseq2 =~ /[a-z]/) { $tmpseq2 = "C"; }

#        convert secondary structure to 3
	    &secstr_convert_dsspto3($tmpsecstr);
	    $tmpsecstr2= $secstr_convert_dsspto3;
#	    print"x.x sec in=$tmpsecstr,out=$tmpsecstr2\n";

#        consistency check
	    if ( ($tmpseq2 !~ /[A-Z]/) && ($tmpseq2 !~ /!/) ) { 
		print "*** $sub_name: ERROR: $file_in \n";
		print "*** small cap sequence: $tmpseq2 ! exit 15-11-93b \n" , "$_"; exit; 
	    }

	    push(@SEQDSSP,$tmpseq); push(@SECDSSP,$tmpsecstr2); push(@ACCDSSP,$tmpexp);
	    push(@PDBPOS,$tmppospdb);
	} 
    } 
}                               # end of: read_dssp_seqsecacc 

#==========================================================================
sub read_fssp {
    local ($file_in, $Lreversed) = @_ ;
    local ($Lexit, $tmp, $nalign, $it, $it2, $aain, $Lprint);
   $[=1;

#--------------------------------------------------
#   reads the aligned fragment ranges from fssp files
#   GLOBAL: @ID1/2, POSBEG1/2, POSEND1/2, SEQBEG1/2, SEQEND1/2
#--------------------------------------------------

    if (length($Lreversed)==0) { $Lreversed=1;}

    &open_file("FILE_FSSP", "$file_fssp");

#   ----------------------------------------
#   skip everything before "## FRAGMENTS"
#   plus: read NALIGN
#   ----------------------------------------
    $Lexit=0;
    while ( <FILE_FSSP> ) {
	if ( /^NALIGN/ ) {
	    $tmp=$_; $tmp=~s/\n|NALIGN|\s//g;
	    $nalign=$tmp;
	}
	if ($Lexit) { last if (/^  NR/); }
	if (/^\#\# FRAGMENTS/) { $Lexit=1; }
    }

#   ----------------------------------------
#   read in fragment ranges
#   ----------------------------------------
    $it=0;
    while ( <FILE_FSSP> ) {
	$Lprint =0;
	$tmp=substr($_,1,4); $tmp=~s/\s//g; 
	if ( (($_=~/REVERSED/)||($_=~/PERMUTED/)) && $Lreversed && ($tmp<=$nalign) ) { $Lprint = 1; }
	elsif ( ($_!~/REVERSED/) && ($_!~/PERMUTED/) && ($tmp<=$nalign) ) { $Lprint = 1; }
	
	if ( $Lprint ) {

#           ------------------------------
#           new pair?
#           ------------------------------
	    if ($tmp != $it) { 
		$it=$tmp;
		$SEQBEG1[$it]=""; $SEQEND1[$it]=""; $SEQBEG2[$it]=""; $SEQEND2[$it]=""; 
		$POSBEG1[$it]=""; $POSEND1[$it]=""; $POSBEG2[$it]=""; $POSEND2[$it]=""; 

#               ------------------------------
#               extract IDs and ranges
#               ------------------------------
		$ID1[$it]=substr($_,7,6);$ID1[$it]=~s/\s//g;$ID1[$it]=~s/(\w\w\w\w)-(\w)/$1_$2/;
		$ID2[$it]=substr($_,14,6);$ID2[$it]=~s/\s//g;$ID2[$it]=~s/(\w\w\w\w)-(\w)/$1_$2/;
	    }

	    $tmp=$_;$tmp=~s/.*:\s*(.*)\s*\n/$1/; $tmp=~s/  / /g;$tmp=~s/    +//g;
#	    print "x.x read: $tmp\n"; 

#           ------------------------------
#           extract 1st and last residues
#           ------------------------------
#                                  ---------------------
#                                  convert 3 letter to 1
	    $aain=substr($_,25,3); &aa3lett_to_1lett($aain); 
	    $SEQBEG1[$it].="$aa3lett_to_1lett".",";
	    $aain=substr($_,42,3); &aa3lett_to_1lett($aain); 
	    $SEQEND1[$it].="$aa3lett_to_1lett".",";
	    $aain=substr($_,62,3); &aa3lett_to_1lett($aain); 
	    $SEQBEG2[$it].="$aa3lett_to_1lett".",";
	    $aain=substr($_,79,3); &aa3lett_to_1lett($aain); 
	    $SEQEND2[$it].="$aa3lett_to_1lett".",";

#           ------------------------------
#           extract ranges
#           ------------------------------
	    $tmp=substr($_,30,4); $tmp=~s/\s//g; $POSBEG1[$it].="$tmp".",";
	    $tmp=substr($_,47,4); $tmp=~s/\s//g; $POSEND1[$it].="$tmp".",";
	    $tmp=substr($_,67,4); $tmp=~s/\s//g; $POSBEG2[$it].="$tmp".",";
	    $tmp=substr($_,84,4); $tmp=~s/\s//g; $POSEND2[$it].="$tmp".",";
	} else {
	    $tmp=$_;$tmp=~s/.*:\s*(.*)\s*\n/$1/; $tmp=~s/  / /g;$tmp=~s/    +//g;
#	    print "x.x excluded: $tmp\n"; 
	}

    }
    close(FILE_FSSP);
}				# end of SUB read_fssp

#==========================================================================
sub read_hssp_seqsecacc {
    local ($fh_in, $chain_in, $beg_in, $end_in, $length ) = @_ ;
    local ($Lread, $sub_name);
    local ($tmpchain, $tmpseq, $tmpsecstr, $tmpexp, $tmppospdb, $tmpseq2, $tmpsecstr2);
   $[=1;

#----------------------------------------------------------------------
#   reads sequence, secondary structure and accessibility from HSSP file
#   (file expected to be open handle = $fh_in).  The reading is restricted
#   by: chain_in, beg_in, end_in, which are passed in the following manner:
#   (say chain = A, begin = 2 (PDB position), end = 10 (PDB position):
#   "A 2 10"
#   Wild cards allowed for any of the three.
#         input:  file_handle, chain, begin, end
#         output: SEQHSSP, SECHSSP, ACCHSSP, PDBPOS
#   GLOBAL:       all output stuff is assumed to be global
#----------------------------------------------------------------------
    $sub_name = "read_hssp_seqsecacc" ;

#----------------------------------------
#   setting to zero
#----------------------------------------
    $#SEQHSSP=$#SECHSSP=$#ACCHSSP=$#PDBPOS=0; 

#----------------------------------------
#   extract input
#----------------------------------------
    if ( ! defined $chain_in ){$chain_in="*";}else{$chain_in=~tr/[a-z]/[A-Z]/;}

    if ( ! defined $beg_in )  {$beg_in= "*" ; }
    if ( ! defined $end_in )  {$end_in= "*" ; }
    $fh_in=~s/\s//g; $chain_in=~s/\s//g; $beg_in=~s/\s//g; $end_in=~s/\s//g; 

#--------------------------------------------------
#   read in file
#--------------------------------------------------

#----------------------------------------
#   skip anything before data...
#----------------------------------------
    while ( <$fh_in> ) { last if ( /^\#\# ALIGNMENTS/ ); }

#----------------------------------------
#   read sequence
#----------------------------------------
    $Lfirst=1;
    while ( <$fh_in> ) {
	$Lread=0;
	if ( ! / SeqNo / ) { 
	    $Lread=1;
	    last if ( /^\#\# / ) ;
	    $tmpchain = substr($_,13,1); 
	    $tmppospdb= substr($_,8,4); $tmppospdb=~s/\s//g;

#        check chain
	    if ( ($tmpchain ne "$chain_in") && ($chain_in ne "*") ) { $Lread=0; }
#        check begin
	    if ( $beg_in ne "*" ) {
		if ( $tmppospdb < $beg_in ) { $Lread=0; }
	    } elsif ( $Lfirst && ($end_in eq "*") && (defined $length) ) {
		$end_in=($tmppospdb+$length);
	    }
	    $Lfirst=0;
		     
#        check end
	    if ( $end_in ne "*" ) {
		if ( $tmppospdb > $end_in ) { $Lread=0; }
	    }
	}

	if ($Lread) {
	    $tmpseq    = substr($_,15,1);
	    $tmpsecstr = substr($_,18,1);
	    $tmpexp    = substr($_,37,3);

#        lower case letter to C
	    $tmpseq2 = $tmpseq;
	    if ($tmpseq2 =~ /[a-z]/) { $tmpseq2 = "C"; }

#        convert secondary structure to 3
	    &secstr_convert_dsspto3($tmpsecstr);
	    $tmpsecstr2= $secstr_convert_dsspto3;
#	    print"x.x sec in=$tmpsecstr,out=$tmpsecstr2\n";

#        consistency check
	    if ( ($tmpseq2 !~ /[A-Z]/) && ($tmpseq2 !~ /!/) ) { 
		print "*** $sub_name: ERROR: $file_in \n";
		print "*** small cap sequence: $tmpseq2 ! exit 15-11-93b \n" , "$_"; exit; 
	    }

	    push(@SEQHSSP,$tmpseq); push(@SECHSSP,$tmpsecstr2); push(@ACCHSSP,$tmpexp);
	    push(@PDBPOS,$tmppospdb);
	} 
    } 
}                               # end of: read_hssp_seqsecacc 


#==========================================================================
sub read_exp80 {
    local ($file_in,$des_seq,$Lseq,$des_sec,$Lsec,$des_exp,$Lexp,$des_phd,$Lphd,$des_rel,$Lrel)=@_ ;
    local ($tmp,$id);
   $[=1;

#--------------------------------------------------------------------------------
#   reads a secondary structure 80lines file
#
#   input: $file_in: input file
#          $des_seq, *sec, *phd, *rel: 
#          descriptions for sequence, obs sec str, pred sec str reliability index
#          e.g. "AA ", "Obs", "Prd", "Rel"
#          $Lseq/sec/phd/rel: flags =0/1 read or don't read stuff
#   
#   GLOBAL
#   output:
#          @NAME, %SEQ, %SEC, %EXP, %PHDEXP, %RELEXP (key = name)
#          
#--------------------------------------------------------------------------------
    $#NAME=$#SEQ=$#EXP=$#SEC=$#PHDEXP=$#RELEXP=0;

    &open_file("FHIN", "$file_in");
    while ( <FHIN> ) {		# jump to first protein
	last if ( /^nos/ );
    }
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
#	    else {
#		print"nothing:$tmp\n"; }

	}
    }
    close(FHIN);

}				# end of read_exp80
#==========================================================================
sub read_rdb_num2 {
    local ($fh, @readnum) = @_ ;
    local ($ct, @tmpar, $it, $ipos, $tmp, $it3);
    $[ =1 ;
#----------------------------------------------------------------------
#   reads from a file of Michael RDB format:
#   local ($fh, @readnum, $readheader, @readcol, @readname, @readformat) = @_ ;
#
#   $fh:           file handle for reading
#   @readnum:      vector containing the number of columns to be read, if empty,
#                  then all columns will be read!
#   $READHEADER:   returns the complete header as one string
#   @READCOL:      returns all columns to be read
#   @READNAME:     returns the names of the columns
#   @READFORMAT:   returns the format of each column
#----------------------------------------------------------------------

    $READHEADER=""; $#READCOL=$#READNAME=$#READFORMAT= 0;
    for ($it=1; $it<=$#readnum; ++$it) { $READCOL[$it]=""; }
    $ct = 0;
    while ( <$fh> ) {
	if ( /^\#/ ) {		              # header  
	    $READHEADER.= "$_";
	} else {		              # rest:
	    ++$ct;
	    if ( $ct >= 3 ) {	              # col content
		@tmpar=split(/\t/);
		for ($it=1; $it<=$#readnum; ++$it) {
		    $READCOL[$it].=$tmpar[$readnum[$it]] . "\t"; }

	    } elsif ( $ct==1 ) {	      # col name
		$_=~s/\t$//g;@tmpar=split(/\t/);
				# --------------------
				# care about wild card
				# --------------------
		if ( ($#readnum==0)||($readnum[1]==0) ) {
		                for ($it=1;$it<=$#tmpar;++$it) {$readnum[$it]=$it;}
				for ($it=1;$it<=$#tmpar;++$it) {$READCOL[$it]=""; } }

		for ($it=1; $it<=$#readnum; ++$it) {$READNAME[$it]="$tmpar[$readnum[$it]]";}

	    } elsif ( $ct==2 ) {	      # col format
		@tmpar=split(/\t/);
		for ($it=1; $it<=$#readnum; ++$it) {
		    $ipos=$readnum[$it];$tmp=$tmpar[$ipos]; $tmp=~s/\s//g;
		    $READFORMAT[$it]=$tmp; }
	    }
	}
    } 
    for ($it=1; $it<=$#READNAME; ++$it) {
	$READFORMAT[$it]=~ s/^\s+//g;
	if ($#readname>0) { $readname[$it] =~ s/^\s+//g;}
	$READCOL[$it] =~ s/\t$|\n//g;	      # correction: last not return!
	$READFORMAT[$it]=~ s/\t$|\n//g;$READNAME[$it]=~s/\t|\n//g;
	if ($#readname>0) { $readname[$it]=~s/\n//g; }
    }

				# ------------------------------
				# convert format to printf
				# ------------------------------
#    foreach $i (@READFORMAT) { 
#	if ($i=~/\dN/) {$i=~s/(.+)N/\%$1d/;}
#	elsif ($i=~/\dF/) {$i=~s/(.+)F/\%$1f/;}
#	else  {$i=~s/(\d+)/\%$1s/;}
#	$i=~s/\s//g; }


}				# end of sub read_rdb_num2

#==========================================================================
sub read_sec80 {
    local ($file_in,$des_seq,$Lseq,$des_sec,$Lsec,$des_phd,$Lphd,$des_rel,$Lrel) = @_ ;
    local ($tmp,$id);
   $[=1;
#--------------------------------------------------------------------------------
#   reads a secondary structure 80lines file
#
#   input: $file_in: input file
#          $des_seq, *sec, *phd, *rel: 
#          descriptions for sequence, obs sec str, pred sec str reliability index
#          e.g. "AA ", "Obs", "Prd", "Rel"
#          $Lseq/sec/phd/rel: flags =0/1 read or don't read stuff
#   
#   GLOBAL
#   output:
#          @NAME, %SEQ, %SEC, %PHD, %REL (key = name)
#          
#--------------------------------------------------------------------------------
    $#NAME=$#SEQ=$#SEC=$#PHDSEC=$#RELSEC=0;

    &open_file("FHIN", "$file_in");
    while ( <FHIN> ) {		# jump to first protein
	last if ( /^nos/ );
    }
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
#	    else {
#		print"nothing:$tmp\n"; }

	}
    }
    close(FHIN);

}				# end of read_sec80

#==========================================================================
sub run_program {
    local ($cmd,$log_file,$action) = @_ ;
    local ($out_command);
# ===========================================================
# Submit a command to the system
# ===========================================================

    ($cmd, @out_command) = split(",",$cmd) ;

    print "--- run_program command: '$cmd'\n";
    open (TMP_CMD, "|$cmd") || ( do {
	if ( $log_file ) {
	    print $log_file "Can't run command: $cmd\n"; }
	warn "Can't run command: $cmd\n";
	$action;
    } );
    foreach $command (@out_command) {
	# delete end of line, and spaces in front and at the end of the string
	$command=~ s/\n|^ *//; $command=~ s/ *$//g;
	print TMP_CMD "$command\n"; }
    close (TMP_CMD) ;
}				# end run_program

#==========================================================================
sub runSys {
    local ($cmdIn,$log_file,$action) = @_ ;
    local ($out_command,$cmd,$cmdLineLoc);
# ===========================================================
# Submit a command to the system
# ===========================================================

    ($cmd, @out_command) = split(",",$cmdIn) ;

    $tmpFileLoc="SYSTEM_TMP_".$$.".tmp";$fhTmpLoc="FH_runSys";
    $Lok=&open_file("$fhTmpLoc",">$tmpFileLoc");
    if (! $Lok){
	print "*** ERROR in runSys (lib) '$cmdIn'\n";
	return(0);}
    foreach $cmdLineLoc (@out_command,@out_command) {
	# delete end of line, and spaces in front and at the end of the string
	$cmdLineLoc=~ s/\n|^ *// ;$cmdLineLoc=~ s/ *$//g ;
	print $fhTmpLoc "$cmdLineLoc\n" ; }
    close($fhTmpLoc);
				# ------------------------------
				# now run
    print "--- run_program command: '$cmd < $tmpFileLoc'\n" ; 
    system("$cmd < $tmpFileLoc $tmpFileLoc $tmpFileLoc $tmpFileLoc");
    if (-e $tmpFileLoc){
	system("\\rm $tmpFileLoc");}
    return(1);
}				# end run_program

#==========================================================================
sub secstr_convert_dsspto3 {
    local ($sec_in) = @_;
    local ($sec_out);
    $[=1;
#----------------------------------------------------------------------
#   converts DSSP 8 into 3
#----------------------------------------------------------------------

    if ( $sec_in eq "T" ) { $sec_out = " "; 
    } elsif ( $sec_in eq "S" ) { $sec_out = " "; 
    } elsif ( $sec_in eq " " ) { $sec_out = " "; 
    } elsif ( $sec_in eq "B" ) { $sec_out = " "; 
#    } elsif ( $sec_in eq "B" ) { $sec_out = "B"; 
    } elsif ( $sec_in eq "E" ) { $sec_out = "E"; 
    } elsif ( $sec_in eq "H" ) { $sec_out = "H"; 
    } elsif ( $sec_in eq "G" ) { $sec_out = "H"; 
    } elsif ( $sec_in eq "I" ) { $sec_out = "H"; 
    } else { $sec_out = " "; }
    if ( length($sec_out) == 0 ) { 
	print "*** ERROR in sub: secstr_convert_dsspto3, out: -$sec_out- \n";
	exit;
    }
    $secstr_convert_dsspto3 = $sec_out;
}
				# end of secstr_convert_dsspto3 

#==========================================================================================
sub sort_by_pdbid {
    local (@id) = @_ ;
    local ($id,$t1,$t2,$des,%id);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    sort_by_pdbid                       
#         sorts a list of ids by alphabet (first number opressed)
#--------------------------------------------------------------------------------
    foreach $id (@id) {$t1=substr($id,1,1);$t2=substr($id,2);$des="$t2"."$t1";
		       $id{"$des"}=$id; }
    $#id=0;
    foreach $keyid (sort keys(%id)){push(@id,$id{"$keyid"});}
    return (@id);
}				# end of sort_by_pdbid

#================================================================================
sub stat_avevar {
    local(@data)=@_;
    local($i, $ave, $var);
    $[=1;
#----------------------------------------------------------------------
#   compiles the variance and average of the vector @data
#   GLOBAL: AVE, VAR (returned)
#----------------------------------------------------------------------
    $ave=$var=0;
    foreach $i (@data) { $ave+=$i; } 
    if ($#data > 0) { $AVE=($ave/$#data); } else { $AVE="0"; }
    foreach $i (@data) { $tmp=($i-$AVE); $var+=($tmp*$tmp); } 
    if ($#data > 1) { $VAR=($var/($#data-1)); } else { $VAR="0"; }
    return ($AVE,$VAR);
}

#==========================================================================
#    sub: write80_data_prepdata
#==========================================================================
sub write80_data_prepdata {
    local ( @data_in) = @_;
    local ( $i);
    $[=1;

#----------------------------------------------------------------------
#   writes input into array called @write80_data
#----------------------------------------------------------------------
    $#write80_data = 0;
    for ( $i=1; $i <=$#data_in ; $i ++ ) {
	$write80_data[$i] = $data_in[$i];
    }
}				# end of: write80_data_prepare_data


#==========================================================================
sub write80_data_preptext {
    local (@data_in) = @_;
    local ( $i, $it2);
    $[=1;

#----------------------------------------------------------------------
#   writes input into array called @write80_data
#----------------------------------------------------------------------
    $#write80_text = 0;
    for ( $i=1; $i <= $#data_in ; $i ++ ) {
	$write80_text[$i] = $data_in[$i];
    }
}				# end of: write80_data_prepare_data


#==========================================================================
sub write80_data_do {
    local ( $fh_out) = @_;
    local ( $seq_intmp, $i, $it2);
    $[=1;

#----------------------------------------------------------------------
#   writes hssp seq + sec str + exposure(projected onto 1 digit) into 
#   file with 80 characters per line
#----------------------------------------------------------------------
    $seq_intmp =  "$write80_data[1]";
    $seq_intmp =~ s/\s//g;
    if ( length($seq_intmp) != length($write80_data[1]) ) {
	print "*** ERROR in write_hssp_..: passed: sequence with spaces! \n";
	print "*** in: \t |$write80_data[1]| \n";
	exit;
    }

    for( $i=1; $i <= length($seq_intmp) ; $i += 80 ) {
	&myprt_points80 ($i);	
	print $fh_out "    $myprt_points80 \n";
	for ( $it2=1; $it2<=$#write80_data; $it2 ++) {
	    print $fh_out "$write80_text[$it2]", "|", substr($write80_data[$it2],$i,80), "|\n";
	}

#	print $fh_out "AA |", substr($seq_in,$i,80), "|\n";
#	print $fh_out "DSP|", substr($secstr_in,$i,80), "|\n";
#	print $fh_out "Exp|", substr($exp_in,$i,80), "|\n";
    } 
}				# end of: write80_data

#======================================================================
#    sub: write_pir
#======================================================================
sub write_pir {
    local ($name,$seq,$file_handle,$seq_char_per_line) = @_;
    local ($i);
    $[=1;

#--------------------------------------------------
#   writes protein into PIR format
#--------------------------------------------------

    if ( length($seq_char_per_line) == 0 ) { $seq_char_per_line = 80; }
    if ( length($file_handle) == 0 ) { $file_handle = "STDOUT"; }

    print $file_handle ">P1\; \n"; print $file_handle "$name \n";
    for ( $i=1; $i < length($seq) ;$i += $seq_char_per_line){
       print $file_handle substr($seq,$i,$seq_char_per_line), "\n";
    }
}
				# end of write_pir

#==========================================================================
sub wrt_dssp_phd {
    local ($fhout,$id_in)=@_;
    local ($it);
    $[ =1 ;
#--------------------------------------------------
#   writes DSSP format for
#   GLOBAL
#   @NUM, @SEQ, @SEC(HE ), @ACC, @RISEC, @RIACC
#--------------------------------------------------
    print $fhout "**** SECONDARY STRUCTURE DEFINITION BY THE PROGRAM DSSP, here PHD prediction\n";
    print $fhout "REFERENCE  ROST & SANDER,PROTEINS,19,1994,55-72; ROST & SANDER,PROTEINS,20,1994,216-26\n";
    print $fhout "HEADER     $id_in \n";
    print $fhout "COMPND        \n";
    print $fhout "SOURCE        \n";
    print $fhout "AUTHOR        \n";
    print $fhout "  \#  RESIDUE AA STRUCTURE BP1 BP2  ACC   N-H-->O  O-->H-N  N-H-->O  O-->H-N    TCO  KAPPA ALPHA  PHI   PSI    X-CA   Y-CA   Z-CA  \n";

				# for security
    if (! defined $CHAIN){$CHAIN=" ";}
    for ($it=1; $it<=$#NUM; ++$it) {
	printf $fhout " %4d %4d %1s %1s  %1s           0   0  %3d    %1d  %1d\n",
	$NUM[$it], $NUM[$it], $CHAIN, $SEQ[$it], $SEC[$it], $ACC[$it], $RISEC[$it], $RIACC[$it];
    }

}				# end wrt_dssp_phd

#==========================================================================================
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
	if (defined $rdrdb{"pL","$it"}) { $pL=$rdrdb{"pL","$it"}; } else {$pL=0;}
	$sum=$pH+$pE+$pL; 
	if ($sum>0){
	    ($rdrdb{"pH","$it"},$tmp)=&min(9,int(10*$pH/$sum));
	    ($rdrdb{"pE","$it"},$tmp)=&min(9,int(10*$pE/$sum));
	    ($rdrdb{"pL","$it"},$tmp)=&min(9,int(10*$pL/$sum)); }
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


#==========================================================================================
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
    printf $fhout "--- %-10s: %-s\n","       ","scaled from 0 (low) to 9 (high)";
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
	$rdrdb{"prH","$it"}=&min(9,int(10*$rdrdb{"OtH","$it"}/$sum));
	$rdrdb{"prE","$it"}=&min(9,int(10*$rdrdb{"OtE","$it"}/$sum));
	$rdrdb{"prL","$it"}=&min(9,int(10*$rdrdb{"OtL","$it"}/$sum));
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
	$tmp=substr($subsec,$it,60);$tmpf=length($tmp)."s";
	printf $fhout "%15s|%-$tmpf|\n"," subset: SUB sec ",$tmp;
	printf $fhout " \n";
				# accessibility
	printf $fhout " ACCESSIBILITY\n";
	foreach $desacc("Pbie","PREL","RI_A"){
	    if ($desacc=~/Pbie/)   {$desout=" 3st:    P_3 acc ";}
	    elsif ($desacc=~/PREL/){$desout=" 10st:   PHD acc ";}
	    elsif ($desacc=~/RI_A/){$desout="         Rel acc ";}
	    $tmp=substr($string{"$desacc"},$it,60);$tmpf=length($tmp)."s";
	    printf $fhout "%-15s|%-$tmpf|\n","$desout",$tmp;
	}
	$tmp=substr($subacc,$it,60);$tmpf=length($tmp)."s";
	printf $fhout "%15s|%-$tmpf|\n"," subset: SUB acc ",$tmp;
	printf $fhout " \n";
    }
    print $fhout "--- \n";
    print $fhout "--- PHD PREDICTION END\n";
    print $fhout "--- \n";
    close($fhout);
}				# end of wrt_phd_rdb2pp

#==========================================================================================
sub wrt_phd_header2pp {
    local ($file_out) = @_ ;
    local ($fhout,$header,@header);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    wrt_phd_header2pp                    
#--------------------------------------------------------------------------------
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

#==========================================================================================
sub wrt_phdpred_from_string {
    local ($fh,$nres_per_row,$mode,$Ldo_htmref,@des) = @_ ;
    local (@des_loc,@header_loc,$Lheader);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    wrt_phdpred_from_string    writes the body of the PHD.pred files from the
#                               global array %STRING{}
#       in (GLOBAL)
#         A                     %STRING, i.e., one line string with prediction,
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
	$tmp=&myprt_npoints($nres_per_row,$it);
	printf $fh "%-17s %-s\n"," ",$tmp;
	foreach $_ (@des_loc) {
	    if (length($STRING{"$_"})<=$it) {next;}
	    $tmp=substr($STRING{"$_"},$it,$nres_per_row);
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
	    elsif($_=~/obie/)  {if($mode=~/both|3/){print $fh " \n"," ACCESSIBILITY \n"; }
				printf $fh "%-8s %-7s |%-s|\n"," 3st:","O_3 acc",$tmp;}
	    elsif($_=~/pbie/)  {if (length($STRING{"obie"})>1){$txt=" ";} 
				else{if($mode=~/both|3/){print $fh " \n"," ACCESSIBILITY \n";}
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
	&wrt_phdpred_from_string_htm($fh,$nres_tmp,$nres_per_row,$symh,$Ldo_htmref,@des_loc);}
}				# end of wrt_phdpred_from_string

#==========================================================================================
sub wrt_phdpred_from_string_htm {
    local ($fh,$nres_tmp,$nres_per_row,$symh,$Ldo_htmref,@des_loc) = @_ ;
    local ($Lfil,$it,$tmp);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    wrt_phdpred_from_string_htm  writes body of the PHD.pred files from the
#                               global array %STRING{} for HTM
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
	      "subset","SUB htm","other","PHDFhtm","PHDRhtm","PHDThtm");
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
	    $tmp=substr($STRING{"$_"},$it,$nres_per_row);
	    if (length($tmp)==0) {next;}else{$len=length($tmp);}
				# helical transmembrane regions
	    if   ($_=~/aa/)    {printf $fh "%8s %-7s |%-s|\n"," ","AA ",$tmp; }
	    elsif($_=~/ohtm/)  {printf $fh "%8s %-7s |%-s|\n"," ","OBS htm",$tmp; }
	    elsif($_=~/phtm/)  {printf $fh "%8s %-7s |%-s|\n"," ","PHD htm",$tmp; }
	    elsif($_=~/pfhtm/) {printf $fh "%8s %-7s |%$len-s|\n"," other:"," "," "; 
		                printf $fh "%8s %-7s |%-s|\n"," ","PHDFhtm",$tmp; }
	    elsif($_=~/rihtm/) {printf $fh "%8s %-7s |%-s|\n"," ","Rel htm",$tmp; }
	    elsif($_=~/prHhtm/){printf $fh "%8s %-7s |%$len-s|\n"," detail:"," "," "; 
				printf $fh "%8s %-7s |%-s|\n"," ","prH htm",$tmp; }
	    elsif($_=~/prLhtm/){printf $fh "%8s %-7s |%-s|\n"," ","prL htm",$tmp; }
	    elsif($_=~/subhtm/){printf $fh "%-8s %-7s |%$len-s|\n"," subset:"," "," ";
				printf $fh "%-8s %-7s |%-s|\n"," ","SUB htm",$tmp;}
	    elsif($_=~/prhtm/) {printf $fh "%8s %-7s |%-s|\n"," ","PHDRhtm",$tmp; }
	    elsif($_=~/pthtm/) {printf $fh "%8s %-7s |%-s|\n"," ","PHDThtm",$tmp; }
	}}
    if ($Ldo_htmref) {
	print $fh
	    "--- \n",
	    "--- PhdTopology REFINEMENT AND TOPOLOGY PREDICTION END\n",
	    "--- \n";}
}				# end of wrt_phdpred_from_string

#==========================================================================================
sub wrt_phdpred_from_string_htm_header {
    local ($fh,@header) = @_ ;
    local ($header,$header_txt,$des,%txt,@des,%dat);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    wrt_phdpred_from_string_htmheader: writes the header for PHDhtm ref and top
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
	"--- PhdTopology  REFINEMENT AND TOPOLOGY HEADER: ABBREVIATIONS\n",
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
	    $#tmp=0;@tmp=split(/,/,$header_txt);
	    printf $fh " %8d %8.3f %8.3f %-s\n",@tmp;}}
    print $fh
	"--- \n",
	"--- PhdTopology REFINEMENT AND TOPOLOGY HEADER: SUMMARY\n";
    foreach $des (@des){	# writing info: now rest
	if ($des ne "MODEL_DAT"){
	    $tmp_des=$des;$tmp_des=~s/_DPROJ|\s//g;
	    printf $fh "--- %-13s: %-s\n",$tmp_des,$dat{"$des"};}}
}				# end of wrt_phdpred_from_string_htm_header

#==========================================================================================
sub wrt_ppcol {
    local ($fhout,%rd)= @_ ;
    local (@des,$ct,$tmp,@tmp,$sep,$des,$des_tmp);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    wrt_phd_rdb2pp             writes out the PP column format
#--------------------------------------------------------------------------------
    $tmp=$rd{"des"}; 
    $tmp=~s/$\s*|\s*$//g;
    @des=split(/\s+/,$tmp);
    $sep="\t";                  # separator

				# header
    print $fhout "# PP column format\n";
				# descriptor
    foreach $des (@des) {
	if ($des ne $des[$#des]) { print $fhout "$des$sep";}
	else {print $fhout "$des\n";} }
				# now the prediction in 60 per line
    $des_tmp=$des[1];
    $ct=1;
    while (defined $rd{"$des_tmp","$ct"}) {
	foreach $des (@des) {
	    if ($des ne $des[$#des]) { print $fhout $rd{"$des","$ct"},"$sep";}
	    else {print $fhout $rd{"$des","$ct"},"\n";}  }
	++$ct; }
    return 1;
}				# end of wrt_ppcol

#==========================================================================================
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
	elsif ($strip =~ /^--- .* PARAMETERS/){ 
	    print $fhout "$strip\n"; 
	    print $fhout 
		"--- fold library : given in\n",
		"---              : http://www.embl-heidelberg.de/".
		    "predictprotein/Dtab/topits_lib849.html\n";}
#		    "predictprotein/Dtab/topits_lib1213.html\n";}
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

#==========================================================================================
sub wrtMsf {
    local($fileOutMsfLoc,%input) = @_ ;
    local(@nameLoc,@stringLoc,$tmp,$fhoutLoc,$sbrName,$Lok);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   wrtMsf                      writing an MSF formatted file of aligned strings
#         input:                $file_msf,$input{}
#                               $input{"NROWS"}  number of alignments
#                               $input{"FROM"}   name of input file
#                               $input{"TO"}     name of output file
#                               $input{"$it"}    sequence identifier ($name)
#                               $input{"$name"}  sequence for $name
#--------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";}
    $sbrName="$tmp"."wrtMsf";$fhoutLoc="FHOUT"."$sbrName";
				# open MSF file
    $Lok=       &open_file("$fhoutLoc",">$fileOutMsfLoc");
    if (! $Lok){print "*** ERROR $sbrName: '$fileOutMsfLoc' not opened\n";
		return(0);}
				# ------------------------------
				# process input
    $#nameLoc=$#tmp=0;
    foreach $it (1..$input{"NROWS"}){$name=$input{"$it"};
				     push(@nameLoc,$name);	# store the names
				     push(@stringLoc,$input{"$name"}); } # store sequences
				# ------------------------------
				# write into file
    print $fhoutLoc 
	"MSF of: ",$input{"FROM"}," from:    1 to:   ",length($stringLoc[1])," \n",
	$input{"TO"}," MSF: ",length($stringLoc[1]),
	"  Type: N  November 09, 1918 14:00 Check: 1933 ..\n \n \n";
    foreach $it (1..$#stringLoc){
	printf 
	    $fhoutLoc "Name: %-20s Len: %-5d Check: 2222 Weight: 1.00\n",
	    $nameLoc[$it],length($stringLoc[$it]); 
    }
    print $fhoutLoc " \n";
    print $fhoutLoc "\/\/\n";
    print $fhoutLoc " \n";

    for($it=1;$it<=length($stringLoc[1]);$it+=50){
	foreach $it2 (1..$#stringLoc){
	    printf $fhoutLoc 
		"%-20s %-10s %-10s %-10s %-10s %-10s\n",$nameLoc[$it2],
		substr($stringLoc[$it2],$it,10),substr($stringLoc[$it2],($it+10),10),
		substr($stringLoc[$it2],($it+20),10),substr($stringLoc[$it2],($it+30),10),
		substr($stringLoc[$it2],($it+40),10); }
	print $fhoutLoc "\n"; }
    print $fhoutLoc "\n";
    close($fhoutLoc);
}				# end of wrtMsf

1;
