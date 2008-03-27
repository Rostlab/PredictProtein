#!/usr/sbin/perl -w
#------------------------------------------------------------------------------#
# other perl environments
##!/bin/env perl
# EMBL
##!/usr/sbin/perl -w
# EBI
##!/usr/bin/perl -w
#----------------------------------------------------------------------
# hssp2fasta
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# usage: 	hssp2fasta.pl file_hssp
#
# task:		runs hssp2fasta without editor
# 		
#----------------------------------------------------------------------#
#	Burkhard Rost		       March	,       1995           #
#			changed:       October,      	1995           #
#			changed:       May,      	1997           #
#			changed:       .	,    	1995           #
#	EMBL				Version 0.1                    #
#	Meyerhofstrasse 1                                              #
#	D-69117 Heidelberg		(br@EMBL-Heidelberg.DE)      #
#----------------------------------------------------------------------#

				# --------------------------------------------------
				# sets array count to start at 1, not at 0
				# --------------------------------------------------
$[ =1 ;

				# --------------------------------------------------
				# include libraries
				# --------------------------------------------------
push (@INC, "/home/rost/perl") ;
require "lib-ut.pl"; require "lib-br.pl";
				# --------------------------------------------------
				# initialise variables
				# --------------------------------------------------
&ini;

# --------------------------------------------------------------------------------
# do the job (here we go)
# --------------------------------------------------------------------------------
				# ------------------------------
				# read HSSP header
($Lok,%rd)=&hsspRdHeader($fileInHssp,@kwdRdHeader);
if (! $Lok){print "*** ERROR hssp2fasta: reading header for $fileInHssp\n";
	    print "***       wanted to read:";&myprt_array(",",@kwdRdHeader);print "\n";
	    die;}
				# ------------------------------
				# marke those to be excluded
				# (written into temporary file)

$#takePos=$#notPos=0;
				# get include ranges (position labelled incl=1-5,7)
if ((length($inclTxt)>0)&&($inclTxt!~/unk/)) {
    @takePos=     &getPosIncl($inclTxt); }
				# get exclude ranges (position labelled excl=1-5,7)
if ((length($exclTxt)>0)&&($exclTxt!~/unk/)) {
    @notPos=      &getPosExcl($exclTxt); }
				# ------------------------------
				# hierarchy
$#take=$ctTake=0;
foreach $it (@takePos){$take[$it]=1;++$ctTake;}
foreach $it (@notPos) {$take[$it]=0;}
    
foreach $it (1..$rd{"NROWS"}){
    if    (($#takePos>0)&&(! defined $take[$it])){$take[$it]=0;}
    elsif (($#notPos>0) &&(! defined $take[$it])){$take[$it]=1;++$ctTake;}}
$#takePos=0;
foreach $it (1..$rd{"NROWS"}){
    if ($take[$it]){push(@takePos,$it);}}

				# print onto screen
print  "--- take no:";foreach $it (1..$rd{"NROWS"}){if ($take[$it]){print "$it,";}}print"\n";
printf "---         =%5d alignments\n",$ctTake;

				# ------------------------------
				# read HSSP file
($Lok,%rd)=
    &hsspRdAli($fileInHssp,@takePos);

				# ------------------------------
				# write new files
@idTmp=split(/,/,$rd{"SWISS"});
$idHssp=$fileInHssp;$idHssp=~s/^.*\///g;$idHssp=~s/\.hssp//g;
$#fileOut=0;
foreach $id (@idTmp){
    $fileOut=$dir_out."$idHssp"."-"."$id".".f";
    $Lok=
	&open_file("$fhout",">$fileOut"); 
    if (! $Lok){print "*** ERROR main: '$fileOut' not opened\n";
		next;}
    $len=length($rd{"seq","$id"});

    if (! $Laligned){		# take full sequence, unaligned, but with insertions filled
	$seq=$rd{"seq","$id"}; }
    else {			# take aligned sequence, insertions ignored
	$seq=$rd{"seqNoins","$id"}; }
	
    print "--- write output '$fileOut'\n"; push(@fileOut,$fileOut);

    print $fhout ">$id $len aa";
    for ($it=1;$it<=$len;$it+=50){
	print $fhout "\n",substr($seq,$it,50);}print $fhout "*\n";close($fhout);}


# --------------------------------------------------------------------------------
# work done
# --------------------------------------------------------------------------------
if ($Lverb) { &myprt_txt(" $script_name has ended fine .. -:\)"); 
	      &myprt_txt(" output in files: "); 
	      foreach $fileOut(@fileOut){
		  if (-e $fileOut){print "$fileOut,";}}print"\n";}
exit;

#==========================================================================================
sub ini {
    local ($script_input,$script_goal,$script_narg,
	   @script_goal,@script_help,@script_opt_key,@script_opt_keydes,$txt,$it);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   initialises variables/arguments
#--------------------------------------------------------------------------------
#
    # ------------------------------------------------------------
    # about script
    # ------------------------------------------------------------
    $script_name=   "hssp2fasta";
    $script_input=  "file_hssp";
    $script_goal=   "extracts sequences from HSSP file";
    $script_narg=   1;
    @script_goal=   (" ",
		     "Task: \t $script_goal",
		     " ",
		     "Input:\t $script_input",
		     " ",
		     "Done: \t ");
    @script_help=   ("Help: \t For further information on input options asf., please  type:",
		     "      \t '$script_name help'",
		     "      \t ............................................................",
		     );
    @script_opt_key=("excl=n1-n2 ",
		     "incl=m1-m2 ",
		     "aligned",
		     " ",
		     "not_screen",
		     "dir_in=",
		     "dir_out=",
		     "dir_work=",
		     );
    @script_opt_keydes= 
	            ("sequences n1 to n2 will be excluded: n1-*, n1-n2, or: n1,n5,... ",
		     "sequences m1 to m2 will be included: m1-*, m1-m2, or: m1,m5,... ",
		     "will spit out the aligned sequences (i.e. deletions NOT filled!!!)",
		     " ",
		     "no information written onto screen",
		     "input dir name,   default: local",
		     "output dir name,  default: local",
		     "working dir name, default: local",
		     );

    if ( ($#ARGV<1)|| ($ARGV[1]=~/^help/) || ($ARGV[1]=~/^man/) ) { 
	print "-" x 80, "\n", "--- \n"; &myprt_txt("Perl script"); 
	foreach $txt (@script_goal) { &myprt_txt("$txt"); } &myprt_empty; 
	&myprt_txt("usage: \t $script_name $script_input"); 
	&myprt_empty;&myprt_txt("optional:");
	for ($it=1; $it<=$#script_opt_key; ++$it) {
	    printf"--- %-12s %-s\n",$script_opt_key[$it],$script_opt_keydes[$it]; }
	&myprt_empty; print "-" x 80, "\n"; exit; }
    elsif ( $#ARGV < $script_narg ) {
	print "-" x 80, "\n", "--- \n";&myprt_txt("Perl script "); 
	foreach $txt (@script_goal){&myprt_txt("$txt");}
	foreach $txt (@script_help){&myprt_txt("$txt");}
	&myprt_empty;print"-" x 80,"\n";exit;}
    
    # ------------------------------------------------------------
    # defaults 
    # ------------------------------------------------------------
    $ARCH=                      $ENV{'ARCH'};
    if (! defined $ARCH){
	foreach $_(@ARGV){
	    if ($_=~/ARCH=(.+)$/){$ARCH=$1;$ARCH=~s/\s//g;
				  last;}}}
    if (! defined $ARCH){
	$ARCH=                  "SGI64";}
				# --------------------
				# directories
    $dir_in=                    "";
    $dir_out=                   "";
    $dir_work=                  "";
				# --------------------
				# files
    $molbio_metric=             "/home/rost/pub/max/mat/Maxhom_GCG.metric";
				# file extensions
				# file handles
    $fhout=                     "FHOUT";
#    $fhin=                      "FHIN";

    $exclTxt=                   "unk";
    $inclTxt=                   "unk";
    $thresh=                    "ALL";
    $mode=                      "old"; # mode for threshold: understands 'old' 'ide' 'sim'

    $minIde=                    ""; # minimal distance from new IDE curve
    $maxIde=                    ""; # maximal distance from new IDE curve
    $minSim=                    ""; # minimal distance from new SIM curve
    $maxSim=                    ""; # maximal distance from new SIM curve
    $Laligned=                  0;  # if = 1, the output will be the aligned sequences, i.e.
				    #         insertions will NOT be filled

				# --------------------
				# logicals
    $Lverb=                     1;		# blabla on screen
    $Lclean=                    0;		# clean identical alis?
				# --------------------
				# executables
    $exe_filter_hssp=           "/home/rost/pub/phd/bin/filter_hssp.$ARCH";
    if (! -e $exe_filter_hssp){
	$exe_filter_hssp=       "/home/rost/pub/phd/bin/filter_hssp.SGI64";}

    # ------------------------------------------------------------
    # read input arguments
    # ------------------------------------------------------------
    $fileInHssp=                   $ARGV[1];
				# output file
    $fileOut=                  $fileInHssp."_extr"; $fileOut=~s/^\/.*\///g;
    $fileOut_tmp=              "XHSSP2FASTA" .$$.".tmp"; 

    if ($#ARGV>$script_narg) {
	for($it=($script_narg+1);$it<=$#ARGV;++$it) {
	    $_=$ARGV[$it];
	    if    ($_=~/exe_filter_hssp=/){ $tmp=$ARGV[$it];$tmp=~s/\n|exe_filter_hssp=//g;
					    $exe_filter_hssp=$tmp; }
	    elsif ($_=~/molbio_metric=/)  { $tmp=$ARGV[$it];$tmp=~s/\n|.*metric=/$1/g;
					    $molbio_metric=$tmp; $molbio_metric=~s/\(|\)//g;}
	    elsif ($_=~/thresh=/)         { $tmp=$ARGV[$it];$tmp=~s/\n|thresh=//g;
					    $thresh=$tmp; $thresh=~s/\(|\)//g;}
	    elsif ($_=~/excl=/ )          { $tmp=$ARGV[$it];$tmp=~s/\n|excl=//g;
					    $exclTxt=$tmp; $exclTxt=~s/\(|\)//g; }
	    elsif ($_=~/incl=/ )          { $tmp=$ARGV[$it];$tmp=~s/\n|incl=//g;
					    $inclTxt=$tmp; $inclTxt=~s/\(|\)//g; }
	    elsif ($_=~/^align/)          { $Laligned=1; }
	    elsif ($_=~/minIde=(.+)$/ )   { $minIde=$1;} # minimal distance from new IDE curve
	    elsif ($_=~/maxIde=(.+)$/ )   { $maxIde=$1;} # maximal distance from new IDE curve
	    elsif ($_=~/minSim=(.+)$/ )   { $minSim=$1;} # minimal distance from new SIM curve
	    elsif ($_=~/maxSim=(.+)$/ )   { $maxSim=$1;} # maximal distance from new SIM curve
	    elsif ($_=~/min=(.+)$/ )      { $minIde=$minSim=$1;} # minimal dis for both
	    elsif ($_=~/max=(.+)$/ )      { $maxIde=$maxSim=$1;} # maximal dis from both
	    elsif ($_=~/not_?[Ss]creen/ ) { $Lverb=0; }
	    elsif ($_=~/^verb/ )          { $Lverb=1; }
#	    elsif ( /^mode=(.+)$/) { $mode=$1;$mode=~s/\s//g; }
	    elsif ($_=~/fileOut=/ )       { $tmp=$ARGV[$it];$tmp=~s/\n|fileOut=//g; 
					    $fileOut=$tmp; }
	    elsif ($_=~/dir_in=/ )        { $tmp=$ARGV[$it];$tmp=~s/\n|dir_in=//g; 
					    $dir_in=$tmp; }
	    elsif ($_=~/dir_out=/ )       { $tmp=$ARGV[$it];$tmp=~s/\n|dir_out=//g; 
					    $dir_out=$tmp; }
	    elsif ($_=~/dir_work=/ )      { $tmp=$ARGV[$it];$tmp=~s/\n|dir_work=//g; 
					    $dir_work=$tmp; }
	    elsif ($_=~/^clean/)          { $Lclean=1;}
	}}
				# ------------------------------
				# a.a to be read
				# ------------------------------
    @kwdRdHeader=("NALIGN","NR","ID","STRID","IDE","WSIM","LALI"
		  );
    # ------------------------------------------------------------
    # assignments dependent on input read
    # ------------------------------------------------------------
				# ------------------------------
				# interpret input
				# min/max given
    if ((((length($minIde)>0)&&($minIde!~/unk/)) || ((length($maxIde)>0)&&($maxIde!~/unk/)))&&
	(((length($minSim)>0)&&($minSim!~/unk/)) || ((length($maxSim)>0)&&($maxSim!~/unk/)))){
	$mode="is";}
    elsif (((length($minIde)>0)&&($minIde!~/unk/)) || ((length($maxIde)>0)&&($maxIde!~/unk/))){
	$mode="ide";}
    elsif (((length($minSim)>0)&&($minSim!~/unk/)) || ((length($maxSim)>0)&&($maxSim!~/unk/))){
	$mode="sim";}
				# threshold give
    if    ($thresh=~/^ide/){
	$mode="ide";$thresh=~s/^ide//g;$thresh=~s/[^\-0-9\.]//g; # only number
	if (length($thresh)<1){$thresh=0;}}	# default = 0
    elsif ($thresh=~/^sim/){
	$mode="sim";$thresh=~s/^sim//g;$thresh=~s/[^\-0-9\.]//g; # only number
	if (length($thresh)<1){$thresh=0;}}	# defauult = 0
    elsif ($thresh=~/^is/) {
	$mode="is";$thresh=~s/^is//g;$thresh=~s/[^\-0-9\.]//g; # only number
	if (length($thresh)<1){$thresh=0;}}	# defauult = 0
    elsif ($thresh=~/^rule/) {
	$mode="rule";$thresh=~s/^rule//g;$thresh=~s/[^\-0-9\.]//g; # only number
	if (length($thresh)<1){$thresh=0;}}	# defauult = 0
				# consistency
    if ($mode !~/^old|^ide|^sim|^is|^rule/){
	print "*** hssp2fasta.pl: mode=$mode not recognised (old,ide,sim,is,rule)\n";
	die ; }

    if (length($dir_in)>1) {   &complete_dir($dir_in);$dir_in=$DIR;
			       $tmp=$fileInHssp; $fileInHssp="$dir_in"."$tmp";}
    if (length($dir_out)>1) {  &complete_dir($dir_out);$dir_out=$DIR;
			       $tmp=$fileOut; $fileOut="$dir_out"."$tmp";}
    if (length($dir_work)>1) { &complete_dir($dir_work);$dir_work=$DIR; 
			       $fileOut_tmp="$dir_work".$fileOut_tmp;}

    if ($Lverb) { &myprt_line; &myprt_txt("perl script that $script_goal"); 
		  &myprt_empty; &myprt_txt("fileInHssp: \t \t $fileInHssp"); 
		  &myprt_txt("fileOut: \t \t $fileOut");
		  if ($thresh!~/ALL/){   &myprt_txt("threshold: \t\t $thresh"); }
		  if ($exclTxt!~/unk/) {&myprt_txt("exclude pos:\t\t$exclTxt"); }
		  if ($inclTxt!~/unk/) {&myprt_txt("include pos:\t\t$inclTxt"); }
		  &myprt_txt("end of setting up,\t let's work on it"); 
		  &myprt_empty; &myprt_line; &myprt_empty; }

    # ------------------------------------------------------------
    # check existence of file
    # ------------------------------------------------------------
    if ( (length($fileInHssp)>0) && (! -e $fileInHssp) ) {
	&myprt_txt("ERROR $script_name:\t fileInHssp '$fileInHssp' does not exist");
	die;}
}				# end of ini

#===============================================================================
sub getPosExcl {
    local($exclTxtLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok,@notLoc,@exclLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getPosExcl                  flags positions (in pairs) to exclude
#       in:                     e.g. excl=1-5,9,15 
#       out:                    @notLoc
#   GLOBAL in /out:             $rd{"NALIGN"},$rd{"NROWS"},$rd{"NR","$it"}
#-------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";}$sbrName="$tmp"."getPosExcl";
				# text '1-5,7,12' to array (1,2,3,4,5,7,12)
    $#exclLoc=$#notLoc=0;
    if ($exclTxtLoc=~/\*$/){	# replace wild card
	$exclTxtLoc=~s/\*$/$rd{"NALIGN"}/;}
    @exclLoc=&get_range($exclTxtLoc);   # external lib-ut.pl
				# all pairs
    foreach $it (1..$rd{"NROWS"}){
	foreach $i (@exclLoc) { 
	    if ($i == $rd{"NR","$it"}) { 
		$notLoc[$it]=1;
		last;}}}
    return(@notLoc);
}				# end of getPosExcl

#===============================================================================
sub getPosIncl {
    local($inclTxtLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok,@takeLoc,@inclLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getPosIncl                  flags positions (in pairs) to include
#       in:                     e.g. incl=1-5,9,15 
#       out:                    @takeLoc
#   GLOBAL in /out:             $rd{"NALIGN"},$rd{"NROWS"},$rd{"NR","$it"}
#-------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";}
    $sbrName="$tmp"."getPosIncl";
				# text '1-5,7,12' to array (1,2,3,4,5,7,12)
    $#inclLoc=$#takeLoc=0;
    if ($inclTxtLoc=~/\*$/){	# replace wild card
	$inclTxtLoc=~s/\*$/$rd{"NALIGN"}/;}
    @inclLoc=&get_range($inclTxtLoc);  # external lib-ut.pl
    return(@inclLoc);
}				# end of getPosIncl

#===============================================================================
sub getIdeCurve {
    local($threshLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok,@takeLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getIdeCurve                 flags positions (in pairs) above identity threshold
#       out:                    @takeLoc
#   GLOBAL in /out:             $rd{"NR","$it"}
#-------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";}
    $sbrName="$tmp"."getIdeCurve";
    $#takeLoc=0;
    foreach $it (1..$rd{"NROWS"}){ # loop over all pairs
	$dist=100*$rd{"IDE","$it"} - &getDistanceNewCurveIde($rd{"LALI","$it"});
	if ($dist >= $threshLoc){
	    $takeLoc[$it]=1;}
	else { 
	    $takeLoc[$it]=0;}}
    return(@takeLoc);
}				# end of getIdeCurve

#===============================================================================
sub getIdeCurveMinMax {
    local($minLoc,$maxLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok,@notLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getIdeCurveMinMax           flags positions (in pairs) above maxIde and below minIde
#       out:                    @notLoc
#   GLOBAL in /out:             $rd{"NR","$it"}
#-------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";}
    $sbrName="$tmp"."getIdeCurveMinMax";
    $#notLoc=0;
    foreach $it (1..$rd{"NROWS"}){ # loop over all pairs
	$dist=100*$rd{"IDE","$it"} - &getDistanceNewCurveIde($rd{"LALI","$it"});
	if    ($dist > $maxLoc){
	    $notLoc[$it]=1;}
	elsif ($dist < $minLoc){
	    $notLoc[$it]=1;}
	else {
	    printf "xx %3d: %5.2f < %5.2f < %5.2f i=%5.2f (%5d)\n",
	    $it,$minLoc,$dist,$maxLoc,(100*$rd{"IDE","$it"}),$rd{"LALI","$it"};}
    }
    return(@notLoc);
}				# end of getIdeCurveMinMax

#===============================================================================
sub getSimCurve {
    local($threshLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok,@takeLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getSimCurve                 flags positions (in pairs) above similarity threshold
#       out:                    @take
#   GLOBAL in /out:             @take,$rd{"NR","$it"}
#-------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";}
    $sbrName="$tmp"."getSimCurve";
    $#takeLoc=0;
    foreach $it (1..$rd{"NROWS"}){ # loop over all pairs
	$dist=100*$rd{"WSIM","$it"} - &getDistanceNewCurveSim($rd{"LALI","$it"});
	if ($dist >= $threshLoc){
	    $takeLoc[$it]=1;}
	else { 
	    $takeLoc[$it]=0;}}
    return(@takeLoc);
}				# end of getSimCurve

#===============================================================================
sub getSimCurveMinMax {
    local($minLoc,$maxLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok,@notLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getSimCurveMinMax           flags positions (in pairs) above maxSim and below minSim
#       out:                    @notLoc
#   GLOBAL in /out:             $rd{"NR","$it"}
#-------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";}
    $sbrName="$tmp"."getSimCurveMinMax";
    $#notLoc=0;
    foreach $it (1..$rd{"NROWS"}){ # loop over all pairs
	$dist=100*$rd{"WSIM","$it"} - &getDistanceNewCurveSim($rd{"LALI","$it"});
	if    ($dist > $maxLoc){
	    $notLoc[$it]=1;}
	elsif ($dist < $minLoc){
	    $notLoc[$it]=1;}
	else {
	    printf "xx %3d: %5.2f < %5.2f < %5.2f i=%5.2f (%5d)\n",
	    $it,$minLoc,$dist,$maxLoc,(100*$rd{"WSIM","$it"}),$rd{"LALI","$it"};}
    }
    return(@notLoc);
}				# end of getSimCurveMinMax

#===============================================================================
sub getRule {
    local($threshLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok,@notLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getRule                     flags all positions (in pairs) with:
#                               ide < minIde, and  similarity < identity
#       out:                    @notLoc
#   GLOBAL in /out:             $rd{"NR","$it"}
#-------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";}
    $sbrName="$tmp"."getRule";
    $#notLoc=0;
    foreach $it (1..$rd{"NROWS"}){ # loop over all pairs
	$distSim=100*$rd{"WSIM","$it"} - 
	    &getDistanceNewCurveSim($rd{"LALI","$it"}); # external lib-prot
	$distIde=100*$rd{"IDE","$it"}  - 
	    &getDistanceNewCurveSim($rd{"LALI","$it"});	# external lib-prot
	next if ($distIde>$threshLoc);
	if ($distSim < $distIde){
	    $notLoc[$it]=1;}}
    return(@notLoc);
}				# end of getRule

#===============================================================================
sub subx {
#    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   subx                       
#                               c
#       in:                     
#         A                     A
#       out:                    
#         A                     A
#-------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";}
    $sbrName="$tmp"."subx";$fhinLoc="FHIN"."$sbrName";

    $Lok=       &open_file("$fhinLoc","$fileInLoc");
    if (! $Lok){print "*** ERROR $sbrName: '$fileInLoc' not opened\n";
		return(0);}
    while (<$fhinLoc>) {
	$_=~s/\n//g;
	next if (length($_)==0);
    } close($fhinLoc);

}				# end of subx

