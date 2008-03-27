#!/bin/env perl
#------------------------------------------------------------------------------#
# other perl environments
# EMBL
##!/usr/sbin/perl4 -w
##!/usr/sbin/perl -w
# EBI
##!/usr/bin/perl -w
#------------------------------------------------------------------------------#
# conv_hssp2daf.pl
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# usage: 	conv_hssp2daf.pl list-of-hssp-files
#
# task:		converts HSSP to DAF (optionally reads zscores from .strip
#               and extracts)
#
# subroutines   (internal):
# 
#     mergeStrip2Daf            
#     mergeStrip2Daf_rdZ        reads the zscores in a strip file
#     mergeStrip2Daf_merge      
#     dafExtrAlis               extracts the first 1-n alignments , resp.
#     dafAddTitle               adds a description title in header
#     correctLenAli             correct Reinhard's error in lenAli
# 
# subroutines   (external):
# 
#     lib-ut.pl       get_range,open_file,
#     lib-prot.pl     convHssp2Daf,hsspGetChainLength,isDaf,isDafList,is_hssp,is_hssp_list,is_strip,
# 
# system calls:
# 
#      \t 'cp $fileDaf $tmpFile'\n
#      \t 'cp $fileDaf $tmpFile'\n
#      \t 'cp $fileDaf $tmpFile'\n
# 
#----------------------------------------------------------------------#
#	Burkhard Rost		       May	,       1996           #
#			changed:       May	,    	1996           #
#			changed:       February	,    	1997           #
#	EMBL				Version 0.1                    #
#	Meyerhofstrasse 1                                              #
#	D-69117 Heidelberg		(rost@EMBL-Heidelberg.DE)      #
#----------------------------------------------------------------------#

$[ =1 ;
				# initialise
$ARCH=                          $ENV{'ARCH'};

#push (@INC, "/home/rost/perl", "/home/rost/pub/phd/scr");
# #require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl"; 
require "lib-ut.pl"; require "lib-br.pl";

if (defined $ARCH){
    $par{"exe_convert_seq"}=    "/home/rost/pub/phd/bin/convert_seq.$ARCH";
    $par{"ARCH"}=               $ARCH;}

$par{"title"}=                  "unk";
$par{"addTitle"}=               "unk";
$par{"fileDaf"}=                "unk";
$par{"doStrip"}=                0;
$par{"incl"}=                   "all";
$par{"dirHssp"}=                "/data/hssp/";
$LaddRmsdPred=                  0; # strange old option: you can provide MaxHom compiled
				# rmsd values for the prediction, turned off...

@desOpt=("exe_convert_seq","fileDaf","title","doStrip","ARCH","incl","addTitle",
	 "dirHssp");
$fhin="FHIN";

				# process input arguments
$fileIn=$ARGV[1];
if ( ($#ARGV<1) || ($ARGV[1]=~ /^help|^man|^-h/) ){ # help
    print"--- use:      \t 'conv_hssp2daf.pl file.hssp' (or list of HSSP files)\n";
    print"--- optional: \t ";foreach $_(@desOpt){print"$_, ";}print", or: 'strip'\n";
    print"---           \t 'incl=n1-n2' or 'n1-*' , 'n1,n2,...'\n";
    exit;}
foreach $arg (@ARGV){		# optional input keys
    $arg=~s/\s|\n//g;
    if ($arg=~/^exe.*=(.+)$/){$par{"exe_convert_seq"}=$1;}
    else {
	foreach $des (@desOpt){
	    if ($arg=~/^$des=/){$arg=~s/^$des=//g;$par{"$des"}=$arg;}}}
    if (($arg eq "strip")||($arg eq "doStrip")){$par{"doStrip"}=1;}
}
				# update ARCH
if ((! defined $ARCH) && ($par{"ARCH"} ne "unk")){
    $ARCH=$par{"ARCH"};
    if ((! defined $par{"exe_convert_seq"}) || (!-e $par{"exe_convert_seq"}) ){
	$par{"exe_convert_seq"}=    "/home/schneide/public/convert_seq.$ARCH";}}

if (! -e $fileIn){		# not existing
    print "*** ERROR: '$fileIn' (input file) missing!\n";
    exit;}
				# ------------------------------
$#fileIn=0;			# check format of input file
if   (&is_hssp($fileIn)){
    $format="hssp";
    push(@fileIn,$fileIn);}
elsif(&is_hssp_list($fileIn)) {
    $format="hssp";
    &open_file("$fhin","$fileIn");
    while(<$fhin>){$_=~s/\n|\s//g;if (-e $_){push(@fileIn,$_);}} close($fhin);}
elsif(&isDaf($fileIn)){
    $format="daf";
    push(@fileIn,$fileIn);}
elsif(&isDafList($fileIn)) {
    $format="daf";
    &open_file("$fhin","$fileIn");
    while(<$fhin>){$_=~s/\n|\s//g;if (-e $_){push(@fileIn,$_);}} close($fhin);}
else {
    print "*** ERROR: '$fileIn' must be: HSSP or list of HSSP!\n";
    exit;}
				# ------------------------------
				# loop over list
$#rmFile=0;
foreach $fileIn(@fileIn){
    if ($format eq "hssp"){
				# convert to DAF
	if ($par{"fileDaf"} ne "unk"){
	    $fileDaf=$par{"fileDaf"};}
	else {
	    $fileDaf=$fileIn;$fileDaf=~s/\.hssp/\.daf_hssp/g;$fileDaf=~s/^.*\///g;
	    $fileDaf=~s/daf_hssp_topits/daf_topits/g;}
	print "--- \t '$fileIn' -> $fileDaf\n";
	&convHssp2Daf($fileIn,$fileDaf,$par{"exe_convert_seq"});
	if (! -e $fileDaf){
	    print "*** ERROR output from convHssp2Daf '$fileDaf' missing\n";
	    exit;}}
    else{$par{"fileDaf"}=$fileDaf=$fileIn;}
				# extract zscore from strip?
    if ($par{"doStrip"}){
	$tmpFile=$fileDaf."_A".$$."";push(@rmFile,$tmpFile);
	system("cp $fileDaf $tmpFile");print"--- system \t 'cp $fileDaf $tmpFile'\n";
	$fileStrip=$fileIn;$fileStrip=~s/\.hssp|\.daf/\.strip/g;
	print "x.x do strip: strip=$fileStrip, tmp=$tmpFile,\n";
	&mergeStrip2Daf($tmpFile,$fileStrip,$fileDaf,$par{"dirHssp"});}
    else {print "x.x not do strip???\n";}	# x.x
	
				# exclude some?
    if (($par{"incl"} ne "unk")&&($par{"incl"}!~/all/)){
	$tmpFile=$fileDaf."_B".$$."";push(@rmFile,$tmpFile);
	system("cp $fileDaf $tmpFile");print"--- system \t 'cp $fileDaf $tmpFile'\n";
	&dafExtrAlis($tmpFile,$fileDaf,$par{"incl"});}
				# add title?
    if ($par{"addTitle"} ne "unk"){
	$tmpFile=$fileDaf."_C".$$."";push(@rmFile,$tmpFile);
	system("cp $fileDaf $tmpFile");print"--- system \t 'cp $fileDaf $tmpFile'\n";
	&dafAddTitle($tmpFile,$fileDaf,$par{"addTitle"});}
    print "--- output in '$fileDaf'\n";
}				# end of loop over many files

foreach $file(@rmFile){if (-e $file){print"--- system (rm $file)\n";
				     system("\\rm $file");}}
    
1;    
exit;

#==========================================================================================
sub mergeStrip2Daf {
    local ($fileDafIn,$fileStrip,$fileDafOut,$dirHssp) = @_ ;
    $[ =1 ;
#--------------------------------------------------------------------------------
#    mergeStrip2Daf		
#    GLOBAL  in:                all GLOBAL
#--------------------------------------------------------------------------------
    if (! &is_strip($fileStrip)){
	print "*** ERROR '$fileStrip' is not strip format\n";
	exit;}
    %rdStrip=			# first read strip
	&mergeStrip2Daf_rdZ($fileStrip);
				# now read/write DAF
    &mergeStrip2Daf_merge($fileDafIn,$fileDafOut,$dirHssp,%rdStrip);

    if(0){			# x.x
	print"--- mergeStrip2Daf: having read the strip stuff\n";
	print"it, VAL, ZSCORE, NAME\n";
	foreach $it (1..$rdStrip{"NROWS"}){
	    print "x.x $it=";
	    foreach $_("VAL","ZSCORE","NAME"){print $rdStrip{"$it","$_"},",";}
	    print "\n";}}
}				# end of mergeStrip2Daf

#==========================================================================================
sub mergeStrip2Daf_rdZ {
    local ($fileStripLoc) = @_ ;
    local ($fhin_rdZ,%rdStrip,$ct,@tmp,@colNames,$colNames);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    mergeStrip2Daf_rdZ		reads the zscores in a strip file
#         input:		fileStrip
#         output:		$rdStrip{"it","des"}, where 'it' labels the pair
#                               and des="NAME", "ZSCORE", "VAL"
#--------------------------------------------------------------------------------
    undef %rdStrip;
    $#posZ=$#keyZ=$#keyRms=$#posRms=0;
    $fhin_rdZ="Fhin_RdZStrip";&open_file("$fhin_rdZ","$fileStripLoc");
    while(<$fhin_rdZ>){last if (/=== SUMMARY ===/);}
    $ct=0;
    while(<$fhin_rdZ>){
	last if (/^===/);
	$_=~s/\n//g;++$ct;$ctprot=$ct-1;
				# first: get names
	if ($ct==1){$_=~s/^\s*|\s$//g;
		    @colNames=split(/\s+/,$_);$#posZ=$#keyZ=0;
		    foreach $it(1..$#colNames){
			$colNames=$colNames[$it];
			if ($colNames =~ /^VAL|^ZSCORE/){
			    push(@posZ,$it);push(@keyZ,$colNames);}
			elsif ($colNames =~ /^RMS/){
			    push(@posRms,$it);push(@keyRms,$colNames);}
			elsif ($colNames =~ /^NAME/){
			    $posName=$it;}}}
	else {			# others: read zscores
	    $_=~s/^\s*|\s$//g;
	    @tmp=split(/\s+/,$_);
	    foreach $it (1..$#posZ)  {$itRd=$posZ[$it];$keyZ=$keyZ[$it];
				      $rdStrip{"$ctprot","$keyZ"}=$tmp[$itRd];}
	    if ($LaddRmsdPred){
		foreach $it (1..$#posRms){$itRd=$posRms[$it];$keyRms=$keyRms[$it];
					  $rdStrip{"$ctprot","$keyRms"}=$tmp[$itRd];}}
	    $rdStrip{"$ctprot","NAME"}=$tmp[$posName];
	    $rdStrip{"NROWS"}=$ctprot;}
    }close($fhin_rdZ);
    return(%rdStrip);
}				# end of mergeStrip2Daf_rdZ

#==========================================================================================
sub mergeStrip2Daf_merge {
    local ($fileDafIn,$fileDafOut,$dir_hssp,%rdStrip) = @_ ;
    local ($fhin,$fhout,$tmp,@tmp,$it,$posLenAli,$posLenStr,$posIdStr,$posSeq,$posStr,
	   $ct,$idStr,$idX,$chain,$hsspX);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    mergeStrip2Daf_merge		
#    GLOBAL  in:                all GLOBAL
#         input:		
#         output:		
#--------------------------------------------------------------------------------
    $fhin="FhInDaf";$fhout="FhOutDaf";
    &open_file("$fhin","$fileDafIn");
    &open_file("$fhout",">$fileDafOut");
				# ------------------------------
    while(<$fhin>){		# header
	if (/^\# ALIGNMENTS/){
	    if ($LaddRmsdPred){
		print $fhout "\# ADDKEYS:  \t rms\n";}
	    print $fhout "\# RELKEYS:  \t zscore,energy\n";
	    print $fhout "\# RELHISTO: \t 4,3.5,3,2.5,2,1.5,1\n\# \n";}
	if (/^idSeq/) {$tmp=$_;
		       last;}
	if   (/^\#DAF/){$_=~s/^\#DAF/\# DAF/;}
	elsif(/^\# NPAITS/){$_=~s/^\# NPAITS/\# NPAIRS/;}
	print $fhout $_;}
				# ------------------------------
    $tmp=~s/\n//g;		# names
    $tmp=~s/^[\t\s]+|[\t\s]+$//g;
    @tmp=split(/\t+|\s+/,$tmp);
				# find 'lenAli' to correct (hack)
    foreach $it(1..$#tmp){if   ($tmp[$it]=~/^lenAli/){$posLenAli=$it;}
			  elsif($tmp[$it]=~/^lenStr/){$posLenStr=$it;}
			  elsif($tmp[$it]=~/^idStr/) {$posIdStr=$it;}
			  elsif($tmp[$it]=~/^seq/)   {$posSeq=$it;}
			  elsif($tmp[$it]=~/^str/)   {$posStr=$it;}}

    foreach $it (1..($#tmp-2)){	# names: except seq/str
	print $fhout $tmp[$it],"\t";}
    print $fhout "zscore\tenergy\t"; # add zscore and energy
				# add RMS
    if ($LaddRmsdPred){if (defined $rdStrip{"1","RMS"}){ 
	$Lrms=1;print $fhout "rms\t";}}
    else{$Lrms=0;}
    print $fhout $tmp[$#tmp-1],"\t",$tmp[$#tmp],"\n"; # seq/str
    
    $ct=0;			# ------------------------------
    while(<$fhin>){		# body
	$_=~s/\n//g;
	$_=~s/^[\t\s]+|[\t\s]+$//g;
	@tmp=split(/\t+|\s+/,$_);
	++$ct;
				# correct alignment length (hack)
	if ((!defined $tmp[$posSeq])||(!defined $tmp[$posStr])){
	    print"*** ERROR mergeStrip2Daf_merge: file=$fileDafIn ct=$ct, not defined \n";
	    print"*** ERROR: seq=$tmp[$posSeq],\n";
	    print"*** ERROR: str=$tmp[$posStr],\n";}
	$tmp[$posLenAli]=&correctLenAli($tmp[$posSeq],$tmp[$posStr]);
				# correct length of second (hack2)
	$idStr=$tmp[$posIdStr]; 
	if ($idStr=~/_.+$/){$chain=$idStr;$chain=~s/^.*_(.).*$/$1/g;}else{$chain="";}
	if (length($chain)>0){$idX=$idStr; $idX=~s/_.+$//g;
			      $hsspX=$dir_hssp . "$idX" . ".hssp";
			      $tmp[$posLenStr]=&hsspGetChainLength($hsspX,$chain);}
	foreach $it (1..($#tmp-2)){	# names: except seq/str
	    print $fhout $tmp[$it],"\t";}
				# add Zscore and energy
	print $fhout $rdStrip{"$ct","ZSCORE"},"\t",$rdStrip{"$ct","VAL"},"\t";
	if ($Lrms){		# add RMS
	    print $fhout $rdStrip{"$ct","RMS"},"\t";}
				# finally seq and str
	print $fhout "$tmp[$#tmp-1]\t$tmp[$#tmp]\n";
    }close($fhin);close($fhout);
    
}				# end of mergeStrip2Daf_merge

#==========================================================================================
sub dafExtrAlis {
    local ($fileDafIn,$fileDafOut,$incl) = @_ ;
    local ($fhin,$fhout,@rdHeader,@rdBody,$ct,$nalign,@incl,$Lok,$header,$body,$Lincl);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    dafExtrAlis                extracts the first 1-n alignments , resp.
#                               all specified by $incl='1,2,5-8,*'
#--------------------------------------------------------------------------------
    $fhin="FhInDaf";$fhout="FhOutDaf";
    &open_file("$fhin","$fileDafIn");
    $#rdHeader=$#rdBody=0;
    while(<$fhin>){		# header
	push(@rdHeader,$_);last if (/\# ALIGNMENTS/);}
    $ct=0;
    while(<$fhin>){		# body
	if (/^\#/ || (length($_)<5)){next;}
	++$ct;push(@rdBody,$_);}close($fhin);
    
    $nalign=$ct-1;
    if (($incl ne "unk")&&($incl !~/all/)){ 
	@incl=&get_range($incl,$nalign);} else {$#incl=0;}
    if ($#incl>0){$nalign=$#incl;}

    &open_file("$fhout",">$fileDafOut");
    $Lok=0;
    foreach $header(@rdHeader){	# write header out
	if ((!$Lok)&&($header =~/^\# ALIGNMENTS/)){ 
	    print $fhout "# NPAIRS:     $nalign\n";}
	elsif ($header =~/^\# NPAI.S/){	# change number of pairs
	    $Lok=1;$header=~s/(\s+)\d+/$1$nalign/;}
	print $fhout $header;}
    $ct=0;
    foreach $body (@rdBody){	# write body
	++$ct;
	if ($ct>1){
	    $Lincl=0;foreach $incl(@incl){if ($incl == ($ct-1)){$Lincl=1;last;}}}
	else {$Lincl=1;}
	if ($Lincl){
	    print $fhout $body;
	}}close($fhout);
}				# end of dafExtrAlis

#==========================================================================================
sub dafAddTitle {
    local ($fileDafIn,$fileDafOut,$addTitle) = @_ ;
    local ($fhin,$fhout,$Lsource);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    dafAddTitle                adds a description title in header
#--------------------------------------------------------------------------------
    $fhin="FhInDaf";$fhout="FhOutDaf";
    print"x.x entered add title with '$addTitle' in=$fileDafIn, out=$fileDafOut,\n";
    &open_file("$fhin","$fileDafIn");&open_file("$fhout",">$fileDafOut");
    $Lsource=0;
    while (<$fhin>) { 
	$_=~s/\n//g;
	if (/^\# SOURCE/){ $Lsource=1;
			   $_=~s/from\:.*$//g;
			   $_.=" $addTitle";}
	elsif ( (! $Lsource) && (/^\# ALIGNMENTS/) ){
	    print $fhout "# SOURCE:       $addTitle\n";}
	print $fhout $_,"\n";}close($fhin);close($fhout);
}				# end of dafAddTitle

#==========================================================================================
sub correctLenAli {
    local ($seq,$str) = @_ ;
    local ($ctLoc,$it);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    correctLenAli		correct Reinhard's error in lenAli
#--------------------------------------------------------------------------------
    $ctLoc=0;
    foreach $it (1..length($seq)){
	if (length($str)<$it){
	    next;}
	if ((substr($seq,$it,1) ne ".")&&(substr($str,$it,1) ne ".")){
	    ++$ctLoc;}}
    return($ctLoc);
}				# end of correctLenAli

#==========================================================================================
sub convHssp2Daf {
    local ($fileHssp,$fileDaf,$exeConv) = @_ ;local ($command,$an,$formOut);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   convHssp2Daf		converts an HSSP file into the DAF format
#         input:		fileHssp, fileDaf, exeConvHssp2Daf
#         output:		1 if converted file in DAF and existing, 0 else
#--------------------------------------------------------------------------------
    $formOut="d";
    $an=     "N";
    $command="";
				# run FORTRAN script
    eval "\$command=\"$exeConv,$fileHssp,$formOut,$an,$fileDaf,$an\"";
    &run_program("$command" ,"STDOUT","die");

    if ( (-e $fileDaf) && (&isDaf($fileDaf)) ){
	return (1);}
    else {
	return(0);}
}				# end of convHssp2Daf

#==========================================================================================
sub get_range {
    local ($range_txt,$nall) = @_;
    local (@range,@rangeLoc,$it,$range1,$range2);
    $[ =1 ;
#--------------------------------------------------------------------------------
    $#range=0;
    if ($range_txt eq "unk") {
	print "*** ERROR in get_range: argument: '$range_txt,$nall' not digestable\n"; 
	@range=(0);
	return(0);}
    if ($range_txt =~ /\,/) {
	@range=split(/,/,$range_txt);}
    elsif ($range_txt =~ /(\d*|\*)-(\d*|\*)/) { 
	@range=
	    &get_rangeHyphen($range_txt,$nall);}
    else {
	@range=(0); 
	return(0);}
				# process further elements with hyphens
    $#range2=0;
    foreach $range (@range){
	if ($range =~ /(\d*|\*)-(\d*|\*)/) {
	    @rangeLoc=
		&get_rangeHyphen($range,$nall);
	    push(@range2,@rangeLoc);}
	else {push(@range2,$range);}}
				# sort
    if ($#range2>1){
	@range=sort {$a<=>$b} @range2;}else{@range=@range2;}
    return (@range);
}				# end of get_range

#==========================================================================================
sub hsspGetChainLength {
    local ($fileIn,$chainLoc) = @_ ;
    local ($file_hssp,$ct,$tmp,$beg,$end,$pos);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   hsspGetChainLength          extracts the length of a chain in an HSSP file
#       in:                     hssp_file,chain,
#       out:                    length
#--------------------------------------------------------------------------------
    $fileIn=~s/\s//g;$fileIn=~s/\n//g;
    $file_hssp=$fileIn; if ($chainLoc eq "*"){$Lchain=0;}else{$Lchain=1;}
    if (! -e $file_hssp) { print "*** '$fileIn', the hssp file missing\n"; return(0);}
    &open_file("FHIN", "$file_hssp");
    while ( <FHIN> ) { last if (/^ SeqNo/); }
    $ct=$pos=0;
    while ( <FHIN> ) { last if (/^\#\# /);
		       ++$pos;$tmp=substr($_,13,1);
		       if    ( $Lchain && ($tmp eq $chainLoc) ) { ++$ct; }
		       elsif ( ! $Lchain )                      { ++$ct; }
		       elsif ( $ct>1 ) {
			   last;}
		       if ($ct==1){$beg=$pos;}}close(FHIN);
    $end=$pos;
    return($ct,$beg,$end);
}				# end of hsspGetChainLength

#==========================================================================================
sub is_hssp {
    local ($fileInLoc) = @_ ;local ($fh,$Lis);
#--------------------------------------------------------------------------------
#   is_hssp                     checks whether or not file is in HSSP format
#   input:                      file
#--------------------------------------------------------------------------------
    if (! -e $fileInLoc) {
	return (0);}
    $fh="FHIN_CHECK_HSSP";&open_file("$fh", "$fileInLoc");
    while ( <$fh> ) {if (/^HSSP/) {$Lis=1;}else{$Lis=0;}last; }close($fh);
    return $Lis;
}				# end of is_hssp

#==========================================================================================
sub is_hssp_empty {
    local ($fileInLoc) = @_ ;local ($fh,$Lis);
#--------------------------------------------------------------------------------
#   is_hssp_empty               checks whether or not HSSP file has NALIGN=0
#   input:                      file
#--------------------------------------------------------------------------------
    if (! -e $fileInLoc) {
	return (0);}
    $fh="FHIN_CHECK_HSSP";&open_file("$fh", "$fileInLoc");
    while ( <$fh> ) {
	if (/^NALIGN/) {if (/ 0/){ $Lis=1; } else { $Lis=0; } 
			last; } } close($fh); 
    return $Lis;
}				# end of is_hssp_empty

#==========================================================================================
sub is_hssp_list {
    local ($fileInLoc) = @_ ;local ($fh,$Lis,$fileRd,$fileLoc,$chainLoc,$LscreenLoc);
#--------------------------------------------------------------------------------
#   is_hssp_list                checks whether or not file contains a list of HSSP files
#         input:                file
#         output:               returns 1 if is HSSP list, 0 else
#--------------------------------------------------------------------------------
    $LscreenLoc=0;
    if (! -e $fileInLoc) {
	return (0);}
    $fh="FHIN_CHECK_HSSP_LIST";&open_file("$fh", "$fileInLoc");
    while ( <$fh> ) {$fileRd=$_;$fileRd=~s/\s|\n//g;
		     if (length($fileRd)<5){
			 next;}
		     ($fileLoc,$chainLoc)=&hsspGetFile($fileRd,$LscreenLoc);
		     if (&is_hssp($fileLoc)){$Lis=1;}else { $Lis=0;}
		     last; } close($fh);
    return $Lis;
}				# end of is_hssp_list

#==========================================================================================
sub is_strip {
    local ($fileInLoc) = @_ ;
    local ($fh,$Lis);
#--------------------------------------------------------------------------------
#   is_strip                    checks whether or not file is in HSSP-strip format
#   input:                      file
#--------------------------------------------------------------------------------
    if (! -e $fileInLoc) {
	return (0);}
    $fh="FHIN_CHECK_STRIP";&open_file("$fh", "$fileInLoc");
    while ( <$fh> ) {if (/===  MAXHOM-STRIP  ===/) {$Lis=1;}else{$Lis=0;}last; }close($fh);
    return $Lis;
}				# end of is_strip

#==========================================================================================
sub is_strip_list {
    local ($fileInLoc) = @_ ;local ($fh,$Lis,$fileRd,$fileLoc,$chainLoc,$LscreenLoc);
#--------------------------------------------------------------------------------
#    is_strip_list              checks whether or not file contains a list of HSSPstrip files
#         input:                file
#         output:               returns 1 if is HSSP list, 0 else
#--------------------------------------------------------------------------------
    $LscreenLoc=0;
    if (! -e $fileInLoc) {
	return (0);}
    $fh="FHIN_CHECK_STRIP_LIST";&open_file("$fh", "$fileInLoc");
    while ( <$fh> ) {$fileRd=$_;$fileRd=~s/\s|\n//g;
		     if (length($fileRd)<5){
			 next;}
		     if (&is_strip($fileLoc)){$Lis=1;}else { $Lis=0;}
		     last; } close($fh);
    return $Lis;
}				# end of is_strip_list

#==========================================================================================
sub is_strip_old {
    local ($fileInLoc)= @_ ;
    local ($fh,$Lis);
#--------------------------------------------------------------------------------
#   is_strip_old          checks whether file is old strip format
#                         (first SUMMARY, then ALIGNMENTS)
#   input:                file
#--------------------------------------------------------------------------------
    if (! -e $fileInLoc) {
	return (0);}
    $fh="FHIN_CHECK_STRIP_OLD";
    &open_file("$fh", "$fileInLoc");
    $#tmp=0;
    while(<$fh>){if (/=== ALIGNMENTS ===/){$Lok_ali=1;
					   push(@tmp,"ALIGNMENTS");}
		 elsif (/=== SUMMARY ===/){$Lok_sum=1;
					   push(@tmp,"SUMMARY");}
		 last if ($Lok_ali && $Lok_sum) ;}
    close($fh);
    if ($tmp[1] =~/ALIGNMENTS/){
	$Lis=1;}
    else {
	$Lis=0;}
    return $Lis;
}				# end of is_strip_old

#==========================================================================================
sub isDaf {local ($fileLoc) = @_ ; local ($Lok);
#--------------------------------------------------------------------------------
#   isDaf                       checks whether or not file is in DAF format
#				(i.e. the dirty ali format used for aqua)
#--------------------------------------------------------------------------------
	    &open_file("FHIN_DAF","$fileLoc");
	    while (<FHIN_DAF>){	if (/^\# DAF/){$Lok=1;}
				else            {$Lok=0;}
				last;}close(FHIN_DAF);
	    return($Lok);
}				# end of isDaf

#===============================================================================
sub isDafGeneral {
    local ($fileInLoc,@dirLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok,@tmp,$file,$chain);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   isDafGeneral                checks (and finds) DAF files
#       in:                     $file,@dir (to search)
#       out:                    $Lok,$txt,@files
#           txt='not found|empty|not open|none in list|not daf|isDaf|isDafList'
#-------------------------------------------------------------------------------
    $sbrName="lib-prot.pl:"."isDafGeneral";$fhinLoc="FHIN"."$sbrName";
				# ------------------------------
    if (&isDaf($fileInLoc))    { # file is daf
	return(1,"isDaf",$fileInLoc); } 
				# ------------------------------
    elsif (&isDafList($fileInLoc)) { # file is daf list
	$Lok=&open_file("$fhinLoc","$fileInLoc");$#tmp=0;
	if (! $Lok){print "*** ERROR $sbrName input file=$fileInLoc, not opened\n";
		    return(0,"not open",$fileInLoc);}
	while (<$fhinLoc>) {$_=~s/\n//g;$tmp=$_;
			    if (length($_)==0) { 
				next;}
			    if    ((-e $tmp) && &isDaf($tmp)) { 
				push(@tmp,$tmp);}}close($fhinLoc);
	if ($#tmp==0){return(0,"none in list",$fileInLoc);}
	else         {return(1,"isDafList",@tmp);}}
    else{
	return(0,"not daf",$fileInLoc);}
}				# end of isDafGeneral

#==========================================================================================
sub isDafList {
    local ($fileLoc) = @_ ; local ($Lok,$fhinLoc,$fileTmp);
#--------------------------------------------------------------------------------
#   isDafList                   checks whether or not file is list of Daf files
#--------------------------------------------------------------------------------
    $fhinLoc="FhIn_DafList";$Lok=0;
    &open_file("$fhinLoc","$fileLoc");
    while (<$fhinLoc>){	$fileTmp=~s/\n|\s//g;
			if (&isDaf($fileTmp)){$Lok=1;}
			last;}close($fhinLoc);
    return($Lok);
}				# end of isDafList

#======================================================================
sub open_file {
    local ($file_handle,$file_name,$log_file) = @_ ;
    local ($temp_name) ;

    $temp_name = $file_name ;
    $temp_name =~ s/^>>|^>//g ;
    if ( ($file_name =~ m/^>>/ ) && ( ! -e $temp_name ) ) {
	print "*** \t INFO: file $temp_name does not exist, create it\n" ;
	open ($file_handle, ">$temp_name") || ( do {
	    warn "***\t Cannot create new file: $temp_name\n" ;
	    if ( $log_file ) {
		print $log_file "***\t Cannot create new file: $temp_name\n" ;}
	    return (0);
	} );
	close ("$file_handle") ;}
  
    open ($file_handle, "$file_name") || ( do {
	warn "*** \t Cannot open file '$file_name'\n" ;
	if ( $log_file ) {
	    print $log_file "*** \t Can't create new file '$file_name'\n" ;}
	return(0);
    } );
    return(1);
}

