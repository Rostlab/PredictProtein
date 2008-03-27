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
#       out:                    len,nexp,nfit,diff,explanation
#       err:                    ok=(1,'ok',len,nexp,nfit,diff,explanation), err=(0,'msg')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."globe";$fhinLoc="FHIN"."$sbrName";
				# check arguments
    return(0,"*** $sbrName: not def fileLoc!")          if (! defined $fileLoc);
    $fhErrSbr="STDOUT"                                  if (! defined $fhErrSbr);
    return(0,"*** $sbrName: not def fileLoc!")          if (! defined $fileLoc);

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
	     "fit2Ave100","fit2Sig100","fit2Add100","fit2Fac100");
				# read command line
    foreach $_(@passLoc){
	$Lok=0;
	if   ($_=~/^isPred/)       {$parSbr{"isPred"}=  1;$Lok=1;}
	elsif($_=~/^fix/)          {$parSbr{"doFixPar"}=1;$Lok=1;}
	elsif($_=~/^[r]eturn/)     {$parSbr{"doReturn"}=1;$Lok=1;}
	foreach $kwd (@par){
	    if ($_=~/^$kwd=(.*)$/) {$parSbr{"$kwd"}=$1;$Lok=1;}}
	return(0,"*** $sbrName: wrong command line arg '$_'\n") if (! $Lok);}
    $exposed=$parSbr{"exposed"};
				# ------------------------------
				# (1) read file
    ($len,$numExposed)=
	&globeRdPhdRdb($fileInLoc,$fhErrSbr);
				# ERROR
    return(0,$numExposed) if (! $len || ! defined $numExposed || $numExposed =~/\D/);
    
				# ------------------------------
				# get the expected number of res
    if (! $parSbr{"doFixPar"} && ($len < 100)){
	$fit2Add=$parSbr{"fit2Add100"};$fit2Fac=$parSbr{"fit2Fac100"};}
    else {
	$fit2Add=$parSbr{"fit2Add"};   $fit2Fac=$parSbr{"fit2Fac"};}

    ($Lok,$numExpect)=
	&globeFuncFit($len,$fit2Add,$fit2Fac,$parSbr{"exposed"});
				# ------------------------------
				# evaluate the result
    $diff=$numExposed-$numExpect;
    if    ($diff > 20){
	$evaluation="your protein may be globular, but it is not as compact as a domain";}
    elsif ($diff > (-5)){
	$evaluation="your protein appears as compact, as a globular domain";}
    elsif ($diff > (-10)){
	$evaluation="your protein appears not as globular, as a domain";}
    else {
	$evaluation="your protein appears not to be globular";}
	
    return($len,$numExposed,$numExpect,$diff,"$evaluation");
}				# end of globeOne

#===============================================================================
sub globeFuncFit {
    local($lenIn,$add,$fac,$expLoc) = @_ ;local($tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   globeFuncFit_16             length to number of surface molecules fitted to PHD error 
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
    else{ print "*** ERROR in $scrName globeFuncFit only defined for exp=16 or 9\n";
	  return(0,"*** ERROR in $scrName globeFuncFit only defined for exp=16 or 9\n";}
}				# end of globeFuncFit

#===============================================================================
sub globeRdPhdRdb {
    local($fileInLoc2,$fhErrSbr2) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok,@tmp,$msgErr,
	  $ctTmp,$Lboth,$Lsec,$len,$numExposed,$lenRd,$rel);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   globeRdPhdRdb               read PHD rdb file with ACC
#       in:                     $fileInLoc,$fhErrSbr2
#       out:                    $len,$numExposed
#       err:                    0,'msg'
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."globeRdPhdRdb";$fhinLoc="FHIN"."$sbrName";
				# check arguments
    return(0,"*** $sbrName: not def fileLoc2!")          if (! defined $fileLoc2);
    return(0,"*** $sbrName: miss in file '$fileLoc2'!")  if (! -e $fileLoc2);

    $Lok=       &open_file("$fhinLoc","$fileInLoc2");
    if (! $Lok){print $fhErrSbr2 "*** ERROR $sbrName: '$fileInLoc2' not opened\n";
		return(0);}
				# reading file
    $ctTmp=$Lboth=$Lsec=$len=$numExposed=0;
    while (<$fhinLoc>) {
	++$ctTmp;
	if ($_=~/^\# LENGTH\s+\:\s*(\d+)/){
	    $lenRd=$1;}
	if ($ctTmp<3){if    ($_=~/^\# PHDsec\+PHDacc/){$Lboth=1;}
		      elsif ($_=~/^\# PHDacc/)        {$Lboth=0;}
		      elsif ($_=~/^\# PHDsec/)        {$Lsec=1;}}
				# ******************************
	last if ($Lsec);	# ERROR is not PHDacc, at all!!!
				# ******************************
	next if ($_=~/^\#|^No|^4N/); # skip comments and first line
	$_=~s/\n//g;
	@tmp=split(/\t/,$_);	# $id,$chain,$len,$nali,$seq,$sec,$acc,$rel
	
	return(0,"*** ERROR $sbrName: too few elements in id=$id, line=$_\n") if ($#tmp<6);

	foreach $tmp(@tmp){$tmp=~s/\s//g;} # skip blanks
	if    ($Lboth){		# PHDsec+acc
	    $pos=9; $pos=12 if (! $parSbr{"isPred"});} # correct for pred+obs
	else          {		# PHDacc
	    $pos=4; $pos=6  if (! $parSbr{"isPred"});} # correct for pred+obs
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
    return($len,$numExposed);
}				# end of globeRdPhdRdb

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
    print $fhoutTmp
	"# Perl-RDB generated by:$scrName on:$date\n",
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

