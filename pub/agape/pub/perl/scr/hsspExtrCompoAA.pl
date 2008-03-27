#!/usr/bin/perl -w
##!/usr/sbin/perl4 -w
##!/usr/bin/perl
#-------------------------------------------------------------------------------
# 
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$scriptName=   "hssp_extr_compoAA";
$scriptIn=     "list of HSSP files (or *.hssp)";
$scriptTask=   "extract amino acid composition (buried, exp, all) from HSSP";
$scriptNarg=   1;
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# subroutines   (internal):  
#     ini                       initialises variables/arguments
#     iniHelp                   initialise help text
#     iniDefaults               initialise defaults
#     iniGetArg                 read command line arguments
#     iniChangePar              changing parameters according to input arguments
#     cleanUp                   deletes intermediate files
#     getCompo                  compiles the composition (for one HSSP file)
#     getLoci                   looks up the location
#     rdLoci                    reads file with locations
#     wrtCompoHeader            write out statistics for profiles
#     wrtCompoOne               write out statistics for profiles
# 
# subroutines   (external):
#     lib-ut.pl       complete_dir,dirMk,fileRm,get_in_keyboard,
#                     myprt_empty,myprt_line,myprt_txt,open_file,
#     lib-prot.pl     convert_acc,exposure_normalise_prepare,
#                     hsspGetChain,hsspRdProfile,hsspRdSeqSecAcc,isHsspGeneral,is_hssp,
#
#------------------------------------------------------------------------------#
#	Copyright				May,    	1997	       #
#	Burkhard Rost		rost@EMBL-Heidelberg.DE			       #
#	EMBL			http://www.embl-heidelberg.de/~rost/	       #
#	D-69012 Heidelberg						       #
#				version 0.1   	May,    	1997	       #
#------------------------------------------------------------------------------#
				# sets array count to start at 1, not at 0
$[ =1 ;

#@ARGV=split(/\s+/,&get_in_keyboard("command line"));	# x.x mac specific

				# ------------------------------
$Lok=&ini;			# initialise variables
if (! $Lok){ die; }
				# ------------------------------
				# file with list or list of files?
if (($#fileIn == 1)&&(! &is_hssp($fileIn[1]))){
    $fileIn=$fileIn[1];
    $#fileIn=$Lerror=0;
    &open_file("$fhin","$fileIn");
    while(<$fhin>){$_=~s/\s//g;
		   next if (! -e $_);
		   $file=$_;
		   ($Lok,$txt,$fileTmp,$chain)=&isHsspGeneral($file);
		   if ($txt eq "isHssp"){
		       push(@fileIn,$file);}
		   else {print "*** expected HSSP file '$file' txt=$txt (returned $fileTmp)\n";
			 $Lerror=1;}}close($fhin);
    if ($Lerror){die '*** unwanted exit after extract HSSP files';}}

#-------------------------------------------------------------------------------
# do the job (here we go)
#-------------------------------------------------------------------------------
				# ------------------------------
				# read locations from file
if (-e $par{"fileInLoci"}){
    $Lok=&rdLoci($par{"fileInLoci"});
    if (! $Lok){ print "*** ERROR $scriptName read locations ",$par{"fileInLoci"},",\n";
		 die '*** unwanted after trying to read locations';}}

				# ------------------------------
				# write output headers
&wrtCompoHeader();		# will open all files

				# --------------------------------------------------
				# loop over all HSSP files
				# --------------------------------------------------
$ctProt=0;
foreach $fileIn (@fileIn){
    undef %rdChain; undef %rdHssp; undef %rdProf;
    $id=$fileIn;$id=~s/^.*\///g;$id=~s/\.hssp.*$//g;
    ($chain,%rdChain)=&hsspGetChain($fileIn); # get chain identifiers
				# ------------------------------
				# loop over all chains
    foreach $itChain (1..$rdChain{"NROWS"}){
	$ifir=$rdChain{"$itChain","ifir"};$ilas=$rdChain{"$itChain","ilas"};
	$chain=$rdChain{"$itChain","chain"};
	if ($chain ne " "){$idChain=$id."_".$chain;}else{$idChain=$id;}
	$lenChain=($ilas-$ifir+1);
	if ($lenChain<$par{"statMinLen1"}){ # protein shorter than minimal length?
	    next;}
				# ------------------------------
				# read HSSP sequence, secondary structure, and accessibility
	if ($Lverb){printf 
			"--- reading %-20s: chain=%1s:%3d-%3d\n",$fileIn,$chain,$ifir,$ilas;}
	($Lok,%rdHssp)=&hsspRdSeqSecAcc($fileIn,$ifir,$ilas);
	if (! $Lok){ print "*** ERROR $scriptName read HSSP $fileIn, chn=$chain:$ifir-$ilas\n";
		     die '*** unwanted after trying to read HSSP';}
				# ------------------------------
				# read HSSP profile
	if ($Lverb){printf 
			"--- reading %-20s: profiles:%3d-%3d\n",$fileIn,$ifir,$ilas;}
	($Lok,%rdProf)=&hsspRdProfile($fileIn,$ifir,$ilas);
	if (! $Lok){ print "*** ERROR $scriptName rd HSSPprof $fileIn, c=$chain:$ifir-$ilas\n";
		     die '*** unwanted after trying to read HSSPprof';}
				# ------------------------------
				# consistency check: same length?
	if ($rdHssp{"NROWS"} != $rdHssp{"NROWS"}){
	    print "*** ERROR $scriptName($fileIn) length HSSP (",$rdHssp{"NROWS"},
	          ") and HSSPprof(",$rdHssp{"NROWS"},", don't match\n";
	    next;}
				# ------------------------------
	$Lok=&getCompo;		# compile composition
	if (! $Lok){
	    next;}
	++$ctProt;
	$loci=&getLoci($id);
	print "xx loci=$loci, (for id=$id)\n";
				# ------------------------------
				# write composition
	&wrtCompoOne($ctProt,$idChain,$lenChain,$loci);
    }
}
close($fhoutProfE);close($fhoutProfB);close($fhoutProfA);
close($fhoutSingE);close($fhoutSingB);close($fhoutSingA);

#-------------------------------------------------------------------------------
# work done, go home
#-------------------------------------------------------------------------------
if (! $par{"debug"}){		# deleting intermediate files
    &cleanUp();}
if ($Lverb) { &myprt_empty; &myprt_line; &myprt_txt("$scriptName ended fine .. -:\)"); 
	      &myprt_txt("output files  \t ");
	      foreach $_(@fileOut){
		  if (-e $_){
		      printf "--- %-20s %-s\n"," ",$_;}}}
exit;



#==============================================================================
# library collected (begin) lll
#==============================================================================


#==============================================================================
sub complete_dir { local($DIR)=@_; $[=1 ; 
		   return(0) if (! defined $DIR);
		   return($DIR) if ($DIR =~/\/$/);
		   return($DIR."/");} # end of complete_dir


#==============================================================================
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

#==============================================================================
sub dirMk  { 
    local($fhoutLoc,@dirLoc)=@_; local($tmp,@tmp,$Lok,$dirLoc);
    $[ =1 ;
    if   (! defined $fhoutLoc){ 
	$fhoutLoc=0;push(@dirLoc,$fhoutLoc);}
    elsif(($fhoutLoc!~/[^0-9]/)&&($fhoutLoc == 1)) { 
	$fhoutLoc="STDOUT";}
    $Lok=1;$#tmp=0;
    foreach $dirLoc(@dirLoc){
	if ((! defined $dirLoc)||(length($dirLoc)<1)){
	    $tmp="-*- WARNING 'lib-sys:dirMk' '$dirLoc' pretty useless";
	    if ($fhoutLoc){print $fhoutLoc "$tmp\n";}
	    push(@tmp,$tmp);
	    next;}
	if (-d $dirLoc){
	    $tmp="-*- WARNING 'lib-sys:dirMk' '$dirLoc' exists already";
	    if ($fhoutLoc){print $fhoutLoc "$tmp\n";}
	    push(@tmp,$tmp);
	    next;}
	$dirLoc=~s/\/$//g; # purge trailing '/'
	$tmp="'mkdir $dirLoc'"; push(@tmp,$tmp);
	printf $fhoutLoc "--- %-20s %-s\n","fct:","$tmp" if ($fhoutLoc);
	$Lok= mkdir ($dirLoc,umask);
	if (! -d $dirLoc){
	    $tmp="*** ERROR 'lib-sys:dirMk' '$dirLoc' not made";
	    if ($fhoutLoc){print $fhoutLoc "$tmp\n";}
	    $Lok=0; push(@tmp,$tmp);}}
    return($Lok,@tmp);
}				# end of dirMk

#==============================================================================
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

#==============================================================================
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

#==============================================================================
sub fileRm  { local($fhoutLoc,@fileLoc)=@_; local($tmp,@tmp,$Lok,$fileLoc);
	      if (-e $fhoutLoc){push(@fileLoc,$fhoutLoc);$fhoutLoc=0;}
	      $Lok=1;$#tmp=0;
	      foreach $fileLoc(@fileLoc){
		  if (-e $fileLoc){
		      $tmp="'\\rm $fileLoc'"; push(@tmp,$tmp);
		      printf $fhoutLoc "--- %-20s %-s\n","unlink ","$tmp" if ($fhoutLoc);
                      unlink($fileLoc);}
		  if (-e $fileLoc){
		      $tmp="*** ERROR 'lib-sys:fileRm' '$fileLoc' not deleted";
		      if ($fhoutLoc){print $fhoutLoc "$tmp\n";}
		      $Lok=0; push(@tmp,$tmp);}}
	      return($Lok,@tmp);} # end of fileRm


#==============================================================================
sub hsspGetChain {
    local ($fileIn) = @_ ;
    local ($fhin,$ifirLoc,$ilasLoc,$tmp1,$tmp2,
	   $chainLoc,$posLoc,$posRd,$chainRd,@cLoc,@pLoc,%rdLoc);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   hsspGetChain                extracts all chain identifiers in HSSP file
#       in:                     $file
#       out:                    $chains (ABC) ,%rdLoc
#                      no chain -> $chains=' '
#       out                        $rdLoc{"NROWS"},$rdLoc{"$ct","chain"},
#       out                        $rdLoc{"$ct","ifir"},$rdLoc{"$ct","ilas"}
#--------------------------------------------------------------------------------
    $fhin="FhInHssp";
    return(0,"no file") if (! -e $fileIn);
    &open_file("$fhin","$fileIn");
    while(<$fhin>){		# until start of data
	last if ($_=~/^ SeqNo/);}
    $chainLoc=$posLoc="";
    while(<$fhin>){
	if ($_=~/^\#/ && (length($chainLoc)>1) ) {
	    $posLoc.="$ifirLoc-$ilasLoc".",";
	    last;}
	$chainRd=substr($_,13,1);
	$aaRd=   substr($_,15,1);
	$posRd=  substr($_,1,6);$posRd=~s/\s//g;
	next if ($aaRd eq "!") ;  # skip over chain break
	if ($chainLoc !~/$chainRd/){	# new chain?
	    $posLoc.=         "$ifirLoc-$ilasLoc"."," if (length($chainLoc)>1);
	    $chainLoc.=       "$chainRd".",";
	    $ifirLoc=$ilasLoc=$posRd;}
	else { 
	    $ilasLoc=$posRd;}
    }close($fhin);
    $chainLoc=~s/^,|,$//g;
    $posLoc=~s/\s//g;$posLoc=~s/^,|,$//g; # purge leading ','
				# now split chains read
    undef %rdLoc; 
    $ctLoc=0;
    @cLoc=split(/,/,$chainLoc);
    @pLoc=split(/,/,$posLoc);

    foreach $itLoc(1..$#cLoc){
	($tmp1,$tmp2)=split(/-/,$pLoc[$itLoc]);
	next if ($tmp2 == $tmp1); # exclude chains of length 1
	++$ctLoc;
	$rdLoc{"NROWS"}=         $ctLoc;
	$rdLoc{"$ctLoc","chain"}=$cLoc[$itLoc];
	$rdLoc{"$ctLoc","ifir"}= $tmp1;
	$rdLoc{"$ctLoc","ilas"}= $tmp2;}
    $chainLoc=~s/,//g;
    return($chainLoc,%rdLoc);
}				# end of hsspGetChain

#==============================================================================
sub hsspGetFile { 
    local ($fileInLoc,$Lscreen,@dir) = @_ ; 
    local ($fileHssp,$dir,$tmp,$chainLoc,@dir2,$idLoc);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   hsspGetFile                 searches all directories for existing HSSP file
#       in:                     $file,$Lscreen,@dir
#                               kwd  = noSearch -> no DB search
#       out:                    returned file,chain ($hssp,$chain), (if chain in file)
#       watch:                  loop onto itself:
#                               1prcH.hssp not found -> try 1prc.hssp
#--------------------------------------------------------------------------------
    $#dir2=$Lok=0;
    return(0,"no input file")   if (! defined $fileInLoc);
    $chainLoc="";$idLoc=$fileInLoc;$idLoc=~s/^.*\///g;
    $#dir=0                     if (! defined @dir);
    $Lscreen=0                  if (! defined $Lscreen);
    if (-d $Lscreen) { 
	@dir=($Lscreen,@dir);
	$Lscreen=0;}
    $fileInLoc=~s/\s|\n//g;
				# ------------------------------
				# is HSSP ok
    return($fileInLoc," ")      if (-e $fileInLoc && &is_hssp($fileInLoc));

				# ------------------------------
				# purge chain?
    if ($fileInLoc=~/^(.*\.hssp)_?([A-Za-z0-9])$/){
	$file=$1; $chainLoc=$2;
	return($file,$chainLoc) if (-e $file && &is_hssp($file)); }

				# ------------------------------
				# try adding directories
    foreach $dir(@dir){		# avoid endless loop when calling itself
	$Lok=1                  if ($dir =~ /\/data\/hssp/);
	push(@dir2,$dir);}
    @dir=@dir2;  push(@dir,"/data/hssp/") if (!$Lok); # give default

				# ------------------------------
				# before trying: purge chain
    $file=$fileInLoc; $chainLoc=" ";
    $file=~s/^(.*\.hssp)_?([A-Za-z0-9])$/$1/; 
    $chainLoc=$2 if (defined $2);
				# loop over all directories
    $fileHssp=
	&hsspGetFileLoop($file,$Lscreen,@dir);
    return($fileHssp,$chainLoc) if (-e $fileHssp && &is_hssp($fileHssp));

				# ------------------------------
                                # still not: dissect into 'id'.'chain'
    $tmp_file=$fileInLoc; $tmp_file=~s/^([A-Za-z0-9]+).*(\.hssp.*)$/$1$2/g;
    $fileHssp=
        &hsspGetFileLoop($tmp_file,$Lscreen,@dir);
    return($fileHssp,$chainLoc)    if (-e $fileHssp && &is_hssp($fileHssp));

				# ------------------------------
				# change version of file (1sha->2sha)
    $tmp1=substr($idLoc,2,3);
    foreach $it (1..9) {
        $tmp_file="$it"."$tmp1".".hssp";
        $fileHssp=
            &hsspGetFileLoop($tmp_file,$Lscreen,@dir);
	last if ($fileHssp ne "0");}
    return (0)                  if ( ! -e $fileHssp || &is_hssp_empty($fileHssp));
    return($fileHssp,$chainLoc);
}				# end of hsspGetFile

#==============================================================================
sub hsspGetFileLoop { 
    local ($fileInLoop,$Lscreen,@dir) = @_ ; 
    local ($fileOutLoop,$dir,$tmp);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   hsspGetFileLoop             loops over all directories
#       in:                     $file,$Lscreen,@dir
#       out:                    returned file
#--------------------------------------------------------------------------------
				# already ok 
    return($fileInLoop)         if (&is_hssp($fileInLoop));
				# missing extension
    $fileInLoop.=".hssp"        if ($fileInLoop !~ /\.hssp/);
				# already ok 
    return($fileInLoop)         if (&is_hssp($fileInLoop));
				# do NOT continue if starting with dir!!
    return(0)                   if ($fileInLoop =~ /^\//);

				# ------------------------------
    foreach $dir (@dir) {	# search through dirs
	$tmp=&complete_dir($dir) . $fileInLoop; # try directory
	$tmp=~s/\/\//\//g;	# '//' -> '/'
	print "--- hsspGetFileLoop: \t trying '$tmp'\n" if ($Lscreen);
	return($tmp)            if (-e $tmp && &is_hssp($tmp) );
    }
    return(0);			# none found
}				# end of hsspGetFileLoop

#==============================================================================
sub hsspRdProfile {
    local($fileInLoc,$ifirLoc,$ilasLoc,$chainLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$line,$seqNo,$pdbNo,$chainRd,$ifirRd,$ilasRd);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspRdProfile               reads the HSSP profile from ifir to ilas
#       in:                     file.hssp_C ifir ilas $chainLoc (* for all numbers and chain) 
#       out:                    %prof{"kwd","it"}
#                   @kwd=       ("seqNo","pdbNo","V","L","I","M","F","W","Y","G","A","P",
#				 "S","T","C","H","R","K","Q","E","N","D",
#				 "NOCC","NDEL","NINS","ENTROPY","RELENT","WEIGHT");
#-------------------------------------------------------------------------------
    $sbrName="lib-br:hsspRdProfile";$fhinLoc="FHIN"."$sbrName";
    undef %tmp;

    if (! -e $fileInLoc){print "*** $sbrName: HSSP file '$fileInLoc' missing\n";
			 return(0);}
    $chainLoc=0          if (! defined $chainLoc || ! &is_chain($chainLoc));
    $ifirLoc=0           if (! defined $ifirLoc || $ifirLoc eq "*" );
    $ilasLoc=0           if (! defined $ilasLoc || $ilasLoc eq "*" );
				# read profile
    &open_file("$fhinLoc","$fileInLoc") || return(0);
				# ------------------------------
    while (<$fhinLoc>) {	# skip before profile
	last if ($_=~ /^\#\# SEQUENCE PROFILE AND ENTROPY/);}
    $name=<$fhinLoc>;
    $name=~s/\n//g;$name=~s/^\s+|\s+$//g; # trailing blanks
    ($seqNo,$pdbNo,@name)=split(/\s+/,$name);
    $ct=0;			# ------------------------------
    while (<$fhinLoc>) {	# now the profile
	$line=$_; $line=~s/\n//g;
	last if ($_=~/^\#\#/);
	next if (length($line)<13);
	$seqNo=  substr($line,1,5);$seqNo=~s/\s//g;
	$pdbNo=  substr($line,6,5);$pdbNo=~s/\s//g;
	$chainRd=substr($line,12,1); # grep out chain identifier
	next if ( $chainLoc && ($chainRd ne $chainLoc));
	next if ( $ifirLoc  && ($seqNo < $ifirLoc));
	next if ( $ilasLoc  && ($seqNo > $ilasLoc));
	$line=substr($line,13);
	$line=~s/^\s+|\s+$//g; # trailing blanks
	@tmp=split(/\s+/,$line);
	++$ct;
	$tmp{"seqNo","$ct"}=$seqNo;
	$tmp{"pdbNo","$ct"}=$pdbNo;
	foreach $it (1..$#name){
	    $tmp{"$name[$it]","$ct"}=$tmp[$it]; }
	$tmp{"NROWS"}=$ct; }close($fhinLoc);
    return(1,%tmp);
}				# end of hsspRdProfile

#==============================================================================
sub hsspRdSeqSecAcc {
    local($fileInLoc,$ifirLoc,$ilasLoc,$chain,@kwdRd) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$line,$chainLoc,$seqNo,$pdbNo,$chainRd,$ifirRd,$ilasRd);
    $[=1;
#----------------------------------------------------------------------
#   hsspRdSeqSecAcc             reads the HSSP seq/sec/acc from ifir to ilas
#       in:                     file.hssp_C ifir ilas (* for all numbers, ' ' or '*' for chain)
#                               @kwdRd (which to read) = 0 for all
#       out:                    %rdLoc{"kwd","it"}
#                 @kwd=         ("seqNo","pdbNo","seq","sec","acc")
#                                'chain'
#----------------------------------------------------------------------
    $sbrName="lib-br:hsspRdSeqSecAcc";$fhinLoc="FHIN"."$sbrName";$fhinLoc=~tr/[a-z]/[A-Z]/;
				# file existing?
    $chainLoc=0;
    if    (defined $chain){
	$chainLoc=$chain;}
    elsif ($fileInLoc =~/\.hssp.*_(.)/){
	$chainLoc=$fileInLoc;$chainLoc=~s/^.+.hssp.*_(.)$/$1/;
	$fileInLoc=~s/^(.+.hssp.*)_(.)$/$1/;}

    if (! -e $fileInLoc){
	print "*** $sbrName: HSSP file '$fileInLoc' missing\n";
	return(0);}
    $ifirLoc=0  if (! defined $ifirLoc  || ($ifirLoc eq "*") );
    $ilasLoc=0  if (! defined $ilasLoc  || ($ilasLoc eq "*") );
    $chainLoc=0 if (! defined $chainLoc || ($chainLoc eq "*") );
    $#kwdRd=0   if (! defined @kwdRd);
    undef %tmp;
    if ($#kwdRd>0){
	foreach $tmp(@kwdRd){
	    $tmp{"$tmp"}=1;}}
				# ------------------------------
				# open file
    $Lok=&open_file("$fhinLoc","$fileInLoc");
    if (! $Lok){print "*** ERROR $sbrName could not open HSSP '$fileInLoc'\n";
		return(0);}
				# ------------------------------
    while (<$fhinLoc>) {	# header
	last if ( $_=~/^\#\# ALIGNMENTS/ ); }
    $tmp=<$fhinLoc>;		# skip 'names'
    $ct=0;
				# ------------------------------
				# read seq/sec/acc
    while (<$fhinLoc>) {
	$line=$_; $line=~s/\n//g;
	last if ( $_=~/^\#\# / ) ;
        $seqNo=  substr($line,1,6);$seqNo=~s/\s//g;
        $pdbNo=  substr($line,7,6);$pdbNo=~s/\s//g;
        $chainRd=substr($line,13,1);  # grep out chain identifier
	next if ( $chainLoc && ($chainRd ne $chainLoc));
	next if ( $ifirLoc  && ($seqNo < $ifirLoc));
	next if ( $ilasLoc  && ($seqNo > $ilasLoc));
	++$ct;$tmp{"NROWS"}=$ct;
        if (defined $tmp{"chain"}) { $tmp{"chain","$ct"}=$chainRd; }
        if (defined $tmp{"seq"})   { $tmp{"seq","$ct"}=  substr($_,15,1); }
	if (defined $tmp{"sec"})   { $tmp{"sec","$ct"}=  substr($_,18,1); }
	if (defined $tmp{"acc"})   { $tmp=               substr($_,37,3); $tmp=~s/\s//g;
				     $tmp{"acc","$ct"}=  $tmp; }
	if (defined $tmp{"seqNo"}) { $tmp{"seqNo","$ct"}=$seqNo; }
	if (defined $tmp{"pdbNo"}) { $tmp{"pdbNo","$ct"}=$pdbNo; }
    }
    close($fhinLoc);
            
    return(1,%tmp);
}                               # end of: hsspRdSeqSecAcc 

#==============================================================================
sub isHsspGeneral {
    local ($fileInLoc,@dirLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok,@tmpFile,@tmpChain,@tmp,$file,$chain);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   isHsspGeneral               checks (and finds) HSSP files
#       in:                     $file,@dir (to search)
#       out:                    $Lok,$txt,@files (if chains: file1,file2,chain,chain1,chain2)
#           txt='not found|empty|not open|none in list|not hssp|isHssp|isHsspList'
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."isHsspGeneral";$fhinLoc="FHIN"."$sbrName";
				# ------------------------------
    if (! -e $fileInLoc){	# search for HSSP
	($file,$chain)=
	    &hsspGetFile($fileInLoc,@dirLoc);
	return(1,"isHssp",$file,$chain) if ((-e $file) && &is_hssp($file));
	return(0,"empty", $file)    	if ((-e $file) && &is_hssp_empty($file));
	return(0,"not hssp",$fileInLoc); }
				# ------------------------------
    if (&is_hssp($fileInLoc)){	# file is hssp
	return(0,"empty hssp",$fileInLoc)
	    if (&is_hssp_empty($fileInLoc));
	return(1,"isHssp",$fileInLoc); } 
				# ------------------------------
				# file is hssp list
    elsif (&is_hssp_list($fileInLoc)) {
	$Lok=&open_file("$fhinLoc","$fileInLoc");$#tmp=0;
	if (! $Lok){print "*** ERROR $sbrName input file=$fileInLoc, not opened\n";
		    return(0,"not open",$fileInLoc);}
	undef @tmpFile; undef @tmpChain;
	while (<$fhinLoc>) {
	    $_=~s/\n|\s//g;$rd=$_;
	    next if (length($_)==0);
				# file exists ...
	    if    (-e $rd) {
		if (&is_hssp($rd)) { # ... and is HSSP       -> bingo
		    push(@tmpFile,$rd); 
		    push(@tmpChain," "); }
		next; }		     # ... may just be empty -> skip
				# file does NOT exist (chain? dir?)
	    ($file,$chain)=	# search again
		&hsspGetFile($rd,1,@dirLoc);
				# ... bingo
	    if    (-e $file && &is_hssp($file)) { 
		push(@tmpFile,$file);
		push(@tmpChain,$chain); }
	    next;		# GIVE UP ...
	} close($fhinLoc);
				# ... none in list ??
	return(0,"none in list",$fileInLoc) if ($#tmpFile==0);
				# ok -> go home
	return(1,"isHsspList",@tmpFile,"chain",@tmpChain);}
    
				# ------------------------------
    else {			# search for HSSP
	($file,$chain)=
	    &hsspGetFile($fileInLoc,@dirLoc);
	return(1,"isHssp",$file,$chain)     if (-e $file && &is_hssp($file));
	return(0,"empty" ,$file,"err")      if (-e $file && &is_hssp_empty($file));
	return(0,"not hssp",$fileInLoc); 
    }
}				# end of isHsspGeneral

#==============================================================================
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

#==============================================================================
sub is_hssp {
    local ($fileInLoc) = @_ ;local ($fh,$Lis,$tmp);
#--------------------------------------------------------------------------------
#   is_hssp                     checks whether or not file is in HSSP format
#       in:                     $file
#       out:                    1 if is hssp; 0 else
#--------------------------------------------------------------------------------
				# highest priority: has to exist
    return (0)                  if (! -e $fileInLoc);
    $fh="FHIN_CHECK_HSSP";
    open($fh, $fileInLoc) || 
	do { print "*** ERROR is_hssp $fileInLoc not opened to $fh\n";
	     return (0) ;};	# missing file -> 0
    $tmp=<$fh>;			# first line
    close($fh);
				# is HSSP
    return(1)                   if (defined $tmp && $tmp=~/^HSSP/);
    return(0);
}				# end of is_hssp

#==============================================================================
sub is_hssp_empty {
    local ($fileInLoc) = @_ ;local ($fh,$Lis);
#--------------------------------------------------------------------------------
#   is_hssp_empty               checks whether or not HSSP file has NALIGN=0
#       in:                     $file
#       out:                    1 if is empty; 0 else
#--------------------------------------------------------------------------------
    return (0)                  if (! defined $fileInLoc || ! -e $fileInLoc);
    $fh="FHIN_CHECK_HSSP";
    &open_file("$fh", "$fileInLoc") || return(0);
    while ( <$fh> ) {
	if ($_=~/^NALIGN\s+(\d+)/){
	    if ($1 eq "0"){
		close($fh); return(1);}
	    last; }}close($fh); 
    return 0;
}				# end of is_hssp_empty

#==============================================================================
sub is_hssp_list {
    local ($fileInLoc) = @_ ;local ($fh,$Lis,$fileRd,$fileLoc,$chainLoc,$LscreenLoc);
#--------------------------------------------------------------------------------
#   is_hssp_list                checks whether or not file contains a list of HSSP files
#       in:                     $file
#       out:                    returns 1 if is HSSP list, 0 else
#--------------------------------------------------------------------------------
    $LscreenLoc=0;
    return (0)                  if (! defined $fileInLoc || ! -e $fileInLoc);
    $fh="FHIN_CHECK_HSSP_LIST";
    &open_file("$fh", "$fileInLoc") || return(0);
    $Lis=0;
    while ( <$fh> ) {$fileRd=$_;$fileRd=~s/\s|\n//g;
		     next if (length($fileRd)<5);
		     ($fileLoc,$chainLoc)= 
			 &hsspGetFile($fileRd,$LscreenLoc);
		     $Lis=1 if (&is_hssp($fileLoc));
		     last; } close($fh);
    return $Lis;
}				# end of is_hssp_list

#==============================================================================
sub myprt_empty {
    local($fhx)=@_;
#   myprt_empty                 writes line with '--- \n'
    $fhx="STDOUT" if (! defined $fhx);print $fhx "--- \n"; 
}				# end of myprt_empty

#==============================================================================
sub myprt_line  {
    local($fhx)=@_;
#   myprt_line                  prints a line with 70 '-'
    $fhx="STDOUT" if (! defined $fhx);print $fhx "-" x 70,"\n","--- \n";
}				# end of myprt_line

#==============================================================================
sub myprt_txt  {
    local($tmp,$fhx)=@_; 
#-------------------------------------------------------------------------------
#   myprt_txt                   adds '---' and '\n' for writing text
#-------------------------------------------------------------------------------
    $fhx="STDOUT" if(! defined $fhx);
    print $fhx "--- $tmp \n"; 
}				# end of myprt_txt

#==============================================================================
sub open_file {
    local ($file_handle,$file_name,$log_file) = @_ ;
    local ($temp_name) ;
#-------------------------------------------------------------------------------
#   open_file                  opens file, writes warning asf
#-------------------------------------------------------------------------------
    $temp_name = $file_name ;
    $temp_name =~ s/^>>|^>//g ;
    if ( ($file_name =~ /^>>/ ) && ( ! -e $temp_name ) ) {
	print "*** INFO (open_file): append file=$temp_name, does not exist-> create it\n" ;
	open ($file_handle, ">$temp_name") || ( do {
	    warn "***\t Cannot create new file: $temp_name\n" ;
	    if ( $log_file ) {
		print $log_file "***\t Cannot create new file: $temp_name\n" ;}
	    return (0);
	} );
	close ("$file_handle") ;}
  
    open ($file_handle, "$file_name") || ( do {
	warn "*** ERROR lib-br:open_file: Cannot open file '$file_name'\n" ;
	if ( $log_file ) {
	    print $log_file "*** lib-br:open_file: Cannot create new file '$file_name'\n" ;}
	return(0);
    } );
    return(1);
}				# end of open_file



#==============================================================================
# library collected (end)   lll
#==============================================================================


1;
#===============================================================================
sub ini {
    local (@scriptTask,@scriptHelp,@scriptKwd,@scriptKwdDescr,$txt);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   ini                        initialises variables/arguments
#-------------------------------------------------------------------------------
#	$date is e.g.:		Thu Oct 14, 1993 13:06:47
#	@Date is e.g.:		Oct,14,13:06:47,1993
#	&ctime(time) is e.g.:	Thu Oct 14 13:06:47 1993
#
    @Date = split(' ',&ctime(time)) ; 
    $date="$Date[1] $Date[2] $Date[3], $Date[5] $Date[4]"; shift (@Date) ; 
    
#    $PWD=                       $ENV{'PWD'}; $pwd=&complete_dir($PWD);
    $ARCH=                      $ENV{'ARCH'}; 
    if (!defined $ARCH)         {print "-*- WARNING \t no architecture defined\n";}

    &iniDefaults;               # first settings for parameters (may be overwritten by
				# default file and command line input)
    &iniHelp;

    $Lok=&iniGetArg;		# read command line input
    if (! $Lok){print "*** ini ($scriptName) ERROR in  iniGetArg\n";
		return(0);}

    $Lok=&iniChangePar;
    if (! $Lok){print "*** ini ($scriptName) ERROR in  iniChangePar\n";
		return(0);}

    if ($Lverb){&myprt_line; 
		print "--- Settings of $scriptName are:\n--- \n"; 
		if ($#fileIn==1) {printf "--- %-20s '%-s'\n","fileIn:",$fileIn[1]; }
		else {&myprt_txt("input files:  \t ");
		      foreach $_(@fileIn){printf "--- %-20s '%-s'\n"," ",$_;}}
		if ($#fileOut==1){printf "--- %-20s '%-s'\n","fileOut:",$fileOut[1]; }
		else {&myprt_txt("output files:  \t ");
		      foreach $_(@fileOut){if (!  $_){next;}
					   printf "--- %-20s '%-s'\n"," ",$_;}}
		foreach $kwd (@kwdDef) {
		    if ($kwd=~/^fileOut|^fileIn/){
			next;}
		    if (! defined $par{"$kwd"}){$tmp="!! UNDEF !!";}else{$tmp=$par{"$kwd"};}
		    if ((length($tmp)<1)||($tmp eq "unk")){
			next;}
		    printf "--- %-20s '%-s'\n",$kwd,$tmp;}&myprt_line;}

    # ------------------------------------------------------------
    # check existence of file
    # ------------------------------------------------------------
    $Lmiss=0;
    foreach $kwd(@kwdDef){
	if ($kwd =~/^(fileIn|exe)/){
	    if ((! defined  $par{"$kwd"})||(length($par{"$kwd"})<1)){
		next;}
	    if (! -e $par{"$kwd"}){
		printf "*** %-20s '%-s'\n","MISSING $kwd",$par{"$kwd"};$Lmiss=1;}}}
    if ($Lmiss){
	print "*** try to locate the missing files/executables before continuing!\n";
	print "*** left script '$scriptName' after ini date: $date\n";
	return(0);}
    return(1);
}				# end of ini

#===============================================================================
sub iniHelp {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iniHelp                     initialise help text
#-------------------------------------------------------------------------------
    @scriptTask=   (" ",
		     "Task: \t $scriptTask",
		     " ",
		     "Input:\t $scriptIn",
		     " ",
		     "Done: \t ");
    @scriptHelp=   ("Help: \t For further information on input options asf., please  type:",
		     "      \t '$scriptName help'",
		     "      \t ............................................................");
    @scriptKwd=     ("fileInLoci=",
		     "title=",
		     " ",
		     "not_screen",
		     "dirIn=",
		     "dirOut=",
		     "dirWork=",
		     );
    @scriptKwdDescr=("RDB file(s) (commata with locations (Euka2-allLociTransl.rdb,Proka2-.)", 
		     "title of output files",
		     " ",
		     "no information written onto screen",
		     "input directory        default: local",
		     "output directory       default: local",
		     "working directory      default: local ",
		     );

    if ( ($ARGV[1]=~/^help|^man|^-h/) ) { 
	print "-" x 80,"\n"; &myprt_txt("Perl script"); 
	foreach $txt (@scriptTask) {if($txt !~ /Done:/){&myprt_txt("$txt");}} 
	&myprt_txt("Optional:");
	foreach $kwdOpt(@kwdDef){
	    if (! defined $par{"$kwdOpt"}){$tmp="undef";}else{$tmp=$par{"$kwdOpt"};}
	    printf "--- %-12s=x \t (def:=%-s) \n",$kwdOpt,$tmp;}
	&myprt_empty; print "-" x 80,"\n"; die; }
    elsif ( $#ARGV < $scriptNarg ) {
	print "-" x 80,"\n"; &myprt_txt("Perl script"); 
	foreach $txt (@scriptTask) {if($txt !~ /Done:/){&myprt_txt("$txt");}} 
	&myprt_txt("Optional:");
	foreach $txt (@scriptHelp){&myprt_txt("$txt");}
	&myprt_empty;print"-" x 80,"\n";die;}
}				# end of iniHelp

#===============================================================================
sub iniDefaults {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iniDefaults                 initialise defaults
#-------------------------------------------------------------------------------
				# --------------------
				# directories
    $par{"dirIn"}=              ""; # directory with input files
    $par{"dirOut"}=             ""; # directory for output files
    $par{"dirWork"}=            ""; # working directory
				# databases
    $par{"dirHssp"}=            "/data/hssp/";
    $par{"dirLoci"}=            "/home/rost/pub/data/swiss/";
				# --------------------
				# files
    $par{"fileInLoci"}=         ""; # file with locations (RDB: no\tid\tlocation\tsource)

    $par{"title"}=              "Loci3Pdb-";
#    $par{"title"}=              "Loci3Pred-";
#    $par{"title"}=              "PhdLoci-";
    $par{"extOut"}=             ".rdb";
				# read title and extension from command line
    @tmp=@ARGV;
    foreach $_ (@tmp){if   ($_ =~ /^title=(.+)/) {$par{"title"}=$1;}
		      elsif($_ =~ /^extOut=(.+)/){$par{"extOut"}=$1;}}

    $par{"fileOutProfE"}=   $par{"title"}."profExp".$par{"extOut"}; # general
    $par{"fileOutProfB"}=   $par{"title"}."profBur".$par{"extOut"}; # general
    $par{"fileOutProfA"}=   $par{"title"}."profAll".$par{"extOut"}; # irrespective of acc
    $par{"fileOutSingE"}=   $par{"title"}."singExp".$par{"extOut"}; # only AAs from pdb
    $par{"fileOutSingB"}=   $par{"title"}."singBur".$par{"extOut"}; # only AAs from pdb
    $par{"fileOutSingA"}=   $par{"title"}."singAll".$par{"extOut"}; # only AAs from pdb
				# file extensions
    $par{"extOut"}=             ".tmp";
				# file handles
#    $fhout=                     "FHOUT";
    $fhin=                      "FHIN";
				# --------------------
				# logicals
    $Lverb=                     1; # blabla on screen
    $Lverb2=                    0; # more verbose blabla
    $Lverb3=                    0; # more verbose blabla
    $par{"verbose"}=$Lverb;$par{"verbose2"}=$Lverb2;$par{"verbose3"}=$Lverb3;
				# --------------------
				# other
    $par{"statExposed"}=        25; # acids with relative accessibility higher than that
				# regarded as exposed
    $par{"statMinLen1"}=        30; # minimal length of protein
    $par{"lociUnk"}=            "?"; # name used for unknown locations
				# ------------------------------
				# a.a descriptors 
				# allowed in default file
				# ------------------------------
    @kwdDef=     ("debug","verbose","verbose2","verbose3",
		  "dirIn","dirOut","dirWork","dirHssp","dirLoci",

		  "title","extOut",
		  "fileInLoci",
		  "fileOutProfE","fileOutProfB","fileOutProfA",
		  "fileOutSingE","fileOutSingB","fileOutSingA",

		  "statExposed","statMinLen1","lociUnk"
		  );

    @aaNamesHssp= ("V","L","I","M","F","W","Y","G","A","P",
		   "S","T","C","H","R","K","Q","E","N","D");
#    @aaNamesAbcd= ("A","C","D","E","F","G","H","I","K","L",
#		   "M","N","P","Q","R","S","T","V","W","Y")
#    $lociUnk=       "?";
#    %lociInterpret= ('cytoplasmic',  "cyt", 
#		     'extracellular',"ext",
#		     'nuclear',      "nuc",
#		     'all-other',    "$lociUnk",);
#    %LlociInterpret=('cytoplasmic',"1",
#		     'extracellular',"1",
#		     'nuclear',      "1",);
}				# end of iniDefaults

#===============================================================================
sub iniGetArg {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iniGetArg                   read command line arguments
#-------------------------------------------------------------------------------
    $Lokdef=0; $#fileIn=$#tmp=0;
    foreach $arg (@ARGV){	# key word driven input
	if    ( $arg=~ /verbose3/ )    { $Lverb3=1; }
	elsif ( $arg=~ /verbose2/ )    { $Lverb2=1; }
	elsif ( $arg=~ /verbose/ )     { $Lverb=1; }
	elsif ( $arg=~ /not_verbose/ ) { $Lverb=0; }
	else {			# general
	    $Lok=0;
	    foreach $kwd (@kwdDef){ # 
		if ($arg=~/^$kwd=(.+)$/){$tmp=$1;$tmp=~s/\s//g;
					 if ($kwd =~/^dir/){ # add '/' at end of directories
					     $tmp=&complete_dir($tmp);}	# external lib-ut.pl
					 $par{"$kwd"}=$tmp; $Lok=1;$Lokdef=1;
					 last;}}
	    if    ((! $Lok)&&($arg=~/=/)){
		print "*** iniGetArg: unrecognised argument: $arg\n";
		return(0);}
	    elsif ((! $Lok)&&(-e "$arg")){ # input file?
		push(@fileIn,$arg);}
	    elsif (!$Lok){	# possibly add dirIn
		print "x.x still missing '$arg'\n";
		push(@tmp,$arg);}}}
    foreach $tmp (@tmp){	# check unrecognised input arguments
	$tmp1=$par{"dirIn"}.$tmp;
	if (-e "$tmp1"){push(@fileIn,$tmp1);}
	else { print "*** iniGetArg: unrecognised argument(2): '$tmp'\n";
	       return(0);}}	# 
    return(1);
}				# end of iniGetArg

#===============================================================================
sub iniChangePar {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   iniChangePar                changing parameters according to input arguments
#                               e.g. adding directories to file names asf
#-------------------------------------------------------------------------------
    $#tmp=0;			# purge empty keywords
    foreach $kwd (@kwdDef){
	push(@tmp,$kwd) unless ((! defined $kwd)||(length($kwd)<1));}
    @kwdDef=@tmp;
				# ------------------------------
				# add input directory
    if ((defined $par{"dirIn"})&&($par{"dirIn"} ne "unk")&&($par{"dirIn"} ne "local")&&
	(length($par{"dirIn"})>1)){
	foreach $fileIn(@fileIn){
	    if (! -e "$fileIn"){
		$fileIn=$par{"dirIn"}.$fileIn;}
	    if (! -e "$fileIn"){
		print "*** iniChangePar: no in file=$fileIn, dirIn=",$par{"dirIn"},",\n";
		return(0);}}}
				# ------------------------------
    foreach $kwd (@kwdDef){	# add 'pre' 'title' 'ext'
	if ($kwd=~/^fileOut/){
	    if ((defined $par{"$kwd"})&&($par{"$kwd"} eq "no")){
		$par{"$kwd"}=0;
		next;}
	    if ((!defined $par{"$kwd"})||($par{"$kwd"} eq "unk")){
		$kwdPre=$kwd; $kwdPre=~s/file/pre/; 
		if (defined $par{"$kwdPre"}){$pre=$par{"$kwdPre"};}else{$pre="";}
		$kwdExt=$kwd; $kwdExt=~s/file/ext/; 
		if (defined $par{"$kwdExt"}){$ext=$par{"$kwdExt"};}else{$ext="";}
		if ((! defined $par{"title"})||($par{"title"} eq "unk")){
		    $par{"title"}=$scriptName;}
		$par{"$kwd"}=$pre.$par{"title"}.$ext;}}}
				# ------------------------------
				# add output directory
    if ((defined $par{"dirOut"})&&($par{"dirOut"} ne "unk")&&($par{"dirOut"} ne "local")&&
	(length($par{"dirOut"})>1)){
	if (! -d $par{"dirOut"}){ # make directory
	    if ($verb){@tmp=("STDOUT",$par{"dirOut"});}else{@tmp=($par{"dirOut"});}
	    ($Lok,$txt)=&dirMk(@tmp); } # external lib-ut.pl
	foreach $kwd (@kwdDef){
	    if ($kwd=~/^fileOut/){
		if ($par{"$kwd"} !~ /^$par{"dirOut"}/){
		    $par{"$kwd"}=$par{"dirOut"}.$par{"$kwd"};}}}}
				# ------------------------------
				# push array of output files
    if (! defined @fileOut){$#fileOut=0;}
    foreach $kwd (@kwdDef){
	if ($kwd=~/^fileOut/){
	    push(@fileOut,$par{"$kwd"});}}
				# ------------------------------
				# add working directory
    if ((defined $par{"dirWork"})&&($par{"dirWork"} ne "unk")&&($par{"dirWork"} ne "local")&&
	(length($par{"dirWork"})>1)){
	if (! -d $par{"dirWork"}){ # make directory
	    if ($verb){@tmp=("STDOUT",$par{"dirWork"});}else{@tmp=($par{"dirWork"});}
	    ($Lok,$txt)=&dirMk(@tmp); } # external lib-ut.pl
	foreach $kwd (@kwdDef){
	    if (($kwd=~/^file/)&&($kwd!~/^fileIn/)&&($kwd!~/^fileOut/)){
		if ($par{"$kwd"} !~ /^$par{"dirWork"}/){
		    $par{"$kwd"}=$par{"dirWork"}.$par{"$kwd"};}}}}
				# ------------------------------
				# array of Work files
    if (! defined @fileWork){$#fileWork=0;}
    foreach $kwd (@kwdDef){
	if (($kwd=~/^file/)&&($kwd!~/^fileIn/)&&($kwd!~/^fileOut/)){
	    push(@fileWork,$par{"$kwd"});}}
				# ------------------------------
				# blabla
    if ((defined $par{"verbose"}) &&($par{"verbose"})) {$Lverb=1; }
    if ((defined $par{"verbose2"})&&($par{"verbose2"})){$Lverb2=1;}
    if ((defined $par{"verbose3"})&&($par{"verbose3"})){$Lverb3=1;}
				# ------------------------------
				# add directory to executables
    foreach $kwd (@kwdDef){
	if (($kwd=~/^exe/)&&(defined $par{"$kwd"})&&(! -e $par{"$kwd"})){
	    $par{"$kwd"}=$par{"dirPerl"}.$par{"$kwd"};}}

    return(1);
}				# end of iniChangePar

#===============================================================================
sub cleanUp {
    local($sbrName,$fhinLoc,@tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#    cleanUp                    deletes intermediate files
#-------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";} $sbrName="$tmp"."cleanUp";
    if ($#fileWork>0){		# remove intermediate files
	if ($Lverb){@tmp=("STDOUT",@fileWork);}else{@tmp=(@fileWork);}
	($Lok,@tmp)=
	    &fileRm(@tmp);}	# external lib-ut.pl
}				# end of cleanUp

#===============================================================================
sub getCompo {
    local($sbrName,$fhinLoc,$tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getCompo                    compiles the composition (for one HSSP file)
#   variables are GLOBAL        %rdHssp,%rdProf
#-------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";}
    $sbrName="$tmp"."getCompo";$fhinLoc="FHIN"."$sbrName";
				# normalise accessibility 
    &exposure_normalise_prepare("RS"); # external lib-prot.pl
				# ------------------------------
				# postprocess sequence, get relAcc
    foreach $itRes (1..$rdHssp{"NROWS"}){
	$rdHssp{"seq","$itRes"}=~tr/[a-z]/C/; # lower cap to C
	$rdHssp{"relAcc","$itRes"}=	# relative acc (convert_acc: external lib-prot.pl)
	    &convert_acc($rdHssp{"seq","$itRes"},$rdHssp{"acc","$itRes"},"unk","RS"); }
				# ------------------------------
				# normalise profile by counts
    foreach $itRes (1..$rdHssp{"NROWS"}){
	foreach $aa (@aaNamesHssp){
	    $profNocc{"$aa","$itRes"}=
		int((1/100)*$rdProf{"$aa","$itRes"}*$rdProf{"NOCC","$itRes"});}}
				# ------------------------------
    $nresProfE=$nresProfB=$nresProfA=0; # set zero
    $nresSingE=$nresSingB=$nresSingA=0;
    foreach $aa (@aaNamesHssp){$ctProfE{$aa}=$ctProfB{$aa}=$ctProfA{$aa}=0;
			       $ctSingE{$aa}=$ctSingB{$aa}=$ctSingA{$aa}=0;}
				# ------------------------------
				# get protein averages (single)
    foreach $itRes (1..$rdHssp{"NROWS"}){
	$aa=$rdHssp{"seq","$itRes"};
	if    ($rdHssp{"relAcc","$itRes"}<$par{"statExposed"}){ # buried
	    ++$nresSingB;++$ctSingB{$aa};}
	else {		# exposed
	    ++$nresSingE;++$ctSingE{$aa};}
	++$nresSingA;++$ctSingA{$aa};}
				# ------------------------------
				# get protein averages
    foreach $itRes (1..$rdHssp{"NROWS"}){
	foreach $aa (@aaNamesHssp){
	    if    ($rdHssp{"relAcc","$itRes"}<$par{"statExposed"}){ # buried
		$nresProfB+=$profNocc{"$aa","$itRes"};
		$ctProfB{$aa}+=$profNocc{"$aa","$itRes"};}
	    else {		# exposed
		$nresProfE+=$profNocc{"$aa","$itRes"};
		$ctProfE{$aa}+=$profNocc{"$aa","$itRes"};}
	    $nresProfA+=$profNocc{"$aa","$itRes"};
	    $ctProfA{$aa}+=$profNocc{"$aa","$itRes"};}}
    return(1);
}				# end of getHsspProf

#===============================================================================
sub getLoci {
    local($idInLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getLoci                     returns the location for the given id
#-------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";}
    $sbrName="$tmp"."getLoci";$fhinLoc="FHIN"."$sbrName";

    if (defined $loci{$idInLoc}){
	return ($loci{$idInLoc});}
    else {
	return ($par{"lociUnk"});}
}				# end of getLoci

#===============================================================================
sub rdLoci {
    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   rdLoci                      read file with locations
#-------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";}
    $sbrName="$tmp"."rdLoci";$fhinLoc="FHIN"."$sbrName";

    $fileInLoc=~s/^,|,$//g;
    @fileInLoc=split(/,/,$fileInLoc);
    $Lok=0;			# loop over many files
    foreach $fileInLoc (@fileInLoc){
	if (! -e $fileInLoc){
	    $fileInLoc=$par{"dirLoci"}.$fileInLoc;}
	if (! -e $fileInLoc){
	    next;}
	$Lok=       &open_file("$fhinLoc","$fileInLoc");
	if (! $Lok){print "*** ERROR $sbrName: '$fileInLoc' not opened\n";
		    return(0);}
	while (<$fhinLoc>) {if(/^\#|^\s*lineNo|^\s*5S/){next;}
			    $_=~s/\n//g;$_=~s/^\s*|\s*$//g;
			    @tmp=split(/\t/,$_);
			    $tmp[2]=~s/\s//g;$tmp[3]=~s/\s//g;
			    $loci{$tmp[2]}=$tmp[3];}close($fhinLoc);
    }
    return($Lok);
}				# end of rdLoci

#===============================================================================
sub wrtCompoHeader {
    local($sbrName,$fhinLoc,$tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   wrtCompoHeader           write out statistics for profiles
#-------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";}
    $sbrName="$tmp"."wrtCompoHeader";$fhinLoc="FHIN"."$sbrName";
				# file names
    $fileOutProfE=$par{"fileOutProfE"};$fileOutSingE=$par{"fileOutSingE"};
    $fileOutProfB=$par{"fileOutProfB"};$fileOutSingB=$par{"fileOutSingB"};
    $fileOutProfA=$par{"fileOutProfA"};$fileOutSingA=$par{"fileOutSingA"};
				# file handles
    $fhoutProfE="FHOUT_PROF_E";$fhoutProfB="FHOUT_PROF_B";$fhoutProfA="FHOUT_PROF_A";
    $fhoutSingE="FHOUT_SING_E";$fhoutSingB="FHOUT_SING_B";$fhoutSingA="FHOUT_SING_A";
				# open files
    &open_file("$fhoutProfB",">$fileOutProfB");&open_file("$fhoutSingE",">$fileOutSingE");
    &open_file("$fhoutProfE",">$fileOutProfE");&open_file("$fhoutSingB",">$fileOutSingB");
    &open_file("$fhoutProfA",">$fileOutProfA");&open_file("$fhoutSingA",">$fileOutSingA");

    $accExposed=$par{"statExposed"}; # RDB header
    foreach $fh ("$fhoutProfE","$fhoutProfB","$fhoutProfA",
		 "$fhoutSingE","$fhoutSingB","$fhoutSingA"){
	print $fh "\# Perl-RDB\n","\# \n","\# Profile-compositionss for HSSP files\n";
	if    ($fh =~ /$fhoutProfE|$fhoutSingB/){
	    print $fh "\# PARAMETER Accessibility:  0 - $accExposed \% rel. accessibil.\n";}
	elsif ($fh =~ /$fhoutProfB|$fhoutSingE/){
	    print $fh "\# PARAMETER Accessibility:  $accExposed - 100 \% rel. accessibil.\n";}
	elsif ($fh =~ /$fhoutProfA|$fhoutSingA/){
	    print $fh "\# PARAMETER Accessibility:  0-100 \% rel. accessibility\n";}
	print $fh 
	    "\# NOTATION ------------------------------------------------------------\n",
	    "\# NOTATION COLUMN-NAMES\n",
	    "\# NOTATION loci:  sub-cellular locations taken from SWISS-PROT\n",
	    "\# NOTATION id:    PDB identifier\n",
	    "\# NOTATION nres:  number of residues used for composition (i.e. in chain)\n",
	    "\# NOTATION AA:    percentage of amino acids per protein\n",
	    "\# NOTATION ------------------------------------------------------------\n";}

    foreach $fh ("$fhoutProfE","$fhoutProfB","$fhoutProfA",
		 "$fhoutSingE","$fhoutSingB","$fhoutSingA"){
	printf $fh		# names
	    "%5s\t%-15s\t%-10s\t%6s","no","loci","id1","nres";
	foreach $aa (@aaNamesHssp){
	    printf $fh "\t%5s",$aa;}
	printf $fh "\t%5s\n","sum";
	printf $fh		# formats
	    "%5s\t%-15s\t%-10s\t%6s","5N","15S","10S","6N";
	foreach $_ (1..20){printf $fh "\t%5s","5.2F";}
	printf $fh "\t%5s\n","5.2F";}
}				# end of wrtCompoHeader

#===============================================================================
sub wrtCompoOne {
    local($itLoc,$idLoc,$lenChainLoc,$lociLoc)=@_;
    local($sbrName,$fhinLoc,$tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   wrtCompoOne              write out statistics for profiles
#-------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";}
    $sbrName="$tmp"."wrtCompo";$fhinLoc="FHIN"."$sbrName";
				# ------------------------------
				# for easy looping
    $nres{"$fhoutProfE"}=$nresProfE;$nres{"$fhoutSingE"}=$nresSingE;
    $nres{"$fhoutProfB"}=$nresProfB;$nres{"$fhoutSingB"}=$nresSingB;
    $nres{"$fhoutProfA"}=$nresProfA;$nres{"$fhoutSingA"}=$nresSingA;
				# ------------------------------
				# loop over all files
    foreach $fhLoc("$fhoutProfE","$fhoutProfB","$fhoutProfA",
		   "$fhoutSingE","$fhoutSingB","$fhoutSingA"){
	if (! $nres{"$fhLoc"}){
	    print "xx too few (wrtCompoOne, id=$idLoc) fhLoc=$fhLoc,\n";
	    next;}
	printf $fhLoc	# RDB general
	    "%5d\t%-15s\t%-10s\t%6d",$itLoc,$lociLoc,$idLoc,$lenChainLoc;
	$sum=0;			# RDB per residue counts
	if    ($fhLoc eq "FHOUT_PROF_E"){ # exposed (prof)
	    foreach $aa (@aaNamesHssp){
		$sum+=100*($ctProfE{$aa}/$nres{"$fhLoc"});
		printf $fhLoc "\t%5.2f",100*($ctProfE{$aa}/$nres{"$fhLoc"});}}
	elsif ($fhLoc eq "FHOUT_PROF_B"){ # buried (prof)
	    foreach $aa (@aaNamesHssp){
		$sum+=100*($ctProfB{$aa}/$nres{"$fhLoc"});
		printf $fhLoc "\t%5.2f",100*($ctProfB{$aa}/$nres{"$fhLoc"});}}
	elsif ($fhLoc eq "FHOUT_PROF_A"){ # all (prof)
	    foreach $aa (@aaNamesHssp){ 
		$sum+=100*($ctProfA{$aa}/$nres{"$fhLoc"});
		printf $fhLoc "\t%5.2f",100*($ctProfA{$aa}/$nres{"$fhLoc"});}}
	elsif ($fhLoc eq "FHOUT_SING_E"){ # exposed (sing)
	    foreach $aa (@aaNamesHssp){
		$sum+=100*($ctSingE{$aa}/$nres{"$fhLoc"});
		printf $fhLoc "\t%5.2f",100*($ctSingE{$aa}/$nres{"$fhLoc"});}}
	elsif ($fhLoc eq "FHOUT_SING_B"){ # buried (sing)
	    foreach $aa (@aaNamesHssp){
		$sum+=100*($ctSingB{$aa}/$nres{"$fhLoc"});
		printf $fhLoc "\t%5.2f",100*($ctSingB{$aa}/$nres{"$fhLoc"});}}
	elsif ($fhLoc eq "FHOUT_SING_A"){ # all (sing)
	    foreach $aa (@aaNamesHssp){ 
		$sum+=100*($ctSingA{$aa}/$nres{"$fhLoc"});
		printf $fhLoc "\t%5.2f",100*($ctSingA{$aa}/$nres{"$fhLoc"});}}
	printf $fhLoc "\t%5.2f\n",$sum;}
}				# end of wrtCompoOne

