#!/usr/bin/perl -w
##!/usr/sbin/perl -w
##!/usr/bin/perl -w
#----------------------------------------------------------------------
# hssp_extr_strip
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# usage: 	conv_fssp2daf.pl list-of-fssp-files
#
# task:		converts FSSP to DAF (optionally excludes all not in list)
# 		
#
#----------------------------------------------------------------------#
#	Burkhard Rost		       May	,       1996           #
#			changed:       May	,    	1996           #
#	EMBL				Version 0.1                    #
#	Meyerhofstrasse 1                                              #
#	D-69117 Heidelberg		(rost@EMBL-Heidelberg.DE)      #
#----------------------------------------------------------------------#

$[ =1 ;
				# initialise
#$ARCH=                          $ENV{'ARCH'};

$dir=$0;
$dir=~s/^(.*\/)[^\/]*$/$1/g;
$dir.="/"                       if ($dir !~/\/$/);
$par{"exeConvFssp2Daf"}=        "/home/holm/4Dali/daft.perl";
$par{"exeConvFssp2Daf"}=        $dir."conv_fssp2daf_lh.pl";

$par{"title"}=                  "unk";
$par{"fileDaf"}=                "unk";
$par{"fileIncl"}=               "unk";
$par{"debug"}=                  0;

@desOpt=("exeConvFssp2Daf","fileDaf","title","debug","fileIncl");

				# process input arguments
$fileIn=$ARGV[1];
if ( ($#ARGV<1) || ($ARGV[1]=~ /^help|^man|^-h/) ){ # help
    print"--- use:      \t 'conv_fssp2daf.pl file.fssp' (or list of FSSP files)\n";
    print"--- optional: \t ";foreach $_(@desOpt){print"$_, ";}print"\n";
    print"--- note:     \t fileIncl contains PDBid's + chain 1pdbC (or h|f|dssp files)\n";
    exit;}
foreach $arg (@ARGV){		# optional input keys
    $arg=~s/\s|\n//g;
    if ($arg=~/exe=(.*)/){ $par{"exeConvFssp2Daf"}=$1;}
    else {
	foreach $des (@desOpt){
	    next if ($arg !~ /^$des=(.*)$/);
	    $par{$des}=$1;
	}
    }
}
#foreach $des (@desOpt){print "x.x in: des=$des, par=",$par{"$des"},",\n";}exit;
if (! -e $fileIn){		# not existing
    print "*** ERROR: '$fileIn' (input file) missing!\n";
    exit;}
$fileX=$fileIn;$fileX=~s/^.*\///g;
$fileDbg="Dbg_".$fileX;$fileDbg=~s/\..*$//g;$fhoutDbg="FHOUT_DEBUG";
$fhin="FHIN_CONV_FSSP2DAF";
				# ------------------------------
$#fileIn=0;			# check format of input file
if (&is_fssp($fileIn)){
    push(@fileIn,$fileIn);}
elsif(&is_fssp_list($fileIn)) {
    &open_file("$fhin","$fileIn");
    while(<$fhin>){$_=~s/\n|\s//g;if (-e $_){push(@fileIn,$_);}} close($fhin);}
else {
    print "*** ERROR: '$fileIn' must be: FSSP or list of FSSP!\n";
    exit;}
if ($par{"fileIncl"} ne "unk"){
    $fileTmp=$par{"fileIncl"}; 
    if (! -e $fileTmp){print"*** ERROR include file '$fileTmp' missing\n";exit;}
    &open_file("$fhin","$fileTmp");
    $#incl=0;$incl="";
    while(<$fhin>){if (/^\#/){next;}
		   $_=~s/\n|\s//g;if (length($_)<3){next;}
		   $_=~s/^.*\///g;$_=~s/\.[dhf]ssp[_!]*//g;
		   push(@incl,$_);$incl.="$_,";}close($fhin);
    $incl=~s/,$//g;}
else {
    $#incl=0;$incl="unk";}

$#fileTmp=0;			# intermediate files
&open_file("$fhoutDbg",">$fileDbg");

				# ------------------------------
				# loop over list
foreach $fileIn(@fileIn){
				# convert to DAF
    if ($par{"fileDaf"} ne "unk"){
	$fileDaf=$par{"fileDaf"};}
    else {
	$fileX=$fileIn;
	$fileX=~s/^.*\///g;
	$fileDaf=$fileX;
	$fileDaf=~s/\.fssp/\.daf_fssp/g;}
				# security: same name?
    if ($fileDaf eq $fileIn){
	$fileDaf.=".tmp"; 
	print"*** ERROR daf same name as FSSP\n";}
    $fileDafTmp="x".$$.""."_".$fileDaf;
    push(@fileTmp,$fileDafTmp);

    print "--- \t '$fileIn' -> $fileDaf (via $fileDafTmp)\n";
    $Lok=
	&convFssp2Daf($fileIn,$fileDaf,$fileDafTmp,$par{"exeConvFssp2Daf"},$incl);
    if ( (! -e $fileDaf) || (! $Lok) ){
	print $fhoutDbg "$fileDaf: *** ERROR\n";}
    print "--- \t output: '$fileDaf'\n";
}				# end of loop over many files

if (! $par{"debug"}){
    foreach $file (@fileTmp){
	next if (! -e $file);
	unlink($file);
    }
    unlink($fileDbg);
    unlink($fileX);
}

close($fhoutDbg);
exit;

#==========================================================================================
sub convFssp2Daf {
    local ($fileFssp,$fileDaf,$fileDafTmp,$exeConv,$incl) = @_ ;
    local ($fhinLoc,$fhoutLoc,$tmp,@tmp);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    convFssp2Daf		converts an HSSP file into the DAF format
#         input:		fileHssp, fileDaf, execonvFssp2Daf
#         output:		1 if converted file in DAF and existing, 0 else
#--------------------------------------------------------------------------------
				# run converter
    $cmd="$exeConv $fileFssp >> $fileDafTmp";
    print "--- system '$cmd'\n";
    system("$cmd");
				# as Liisa cannot do it: clean up!
    $fhinLoc= "FhInconvFssp2Daf";$fhoutLoc="FhOutconvFssp2Daf";
    &open_file("$fhinLoc","$fileDafTmp");
    $#headerLoc=$#bodyLoc=0;	# ------------------------------
    while(<$fhinLoc>){		# header
	$tmp=$_;
	last if (/^\#?\s?idSeq/);
	push(@headerLoc,$tmp);}
				# ------------------------------
    $tmp=~s/^\# //g;		# correct error 1 (names)
    $tmp=~s/\n//g;$tmp=~s/^[\t\s]*|[\t\s]*$//g;
    @nameLoc=split(/[\t\s]+/,$tmp); $ptrIdStr=0;
    foreach $itname (1..$#nameLoc){if ($nameLoc[$itname] eq "idStr"){$ptrIdStr=$itname;last;}}
    if ($ptrIdStr==0){print"*** ERROR convFssp2Daf key 'idStr' not found in '$tmp'\n";
		      exit;}
				# ------------------------------
    while(<$fhinLoc>){		# body
	$_=~s/\n//g;$_=~s/^[\s\t]*|[\s\t]*$//g;	# purge trailing blanks
	@tmp=split(/[\t\s]+/,$_);
	$seq=$tmp[$#tmp-1];$str=$tmp[$#tmp];
				# consistency
	if (length($seq) != length($str)){
	    print 
		"*** ERROR convFssp2Daf (lib-aqua): lenSeq ne lenStr!\n",
		"***       seq=$seq,\n","***       str=$str,\n","***       line=$_,\n";
	    exit;}
	$seqOut=$strOut="";	# expand small caps
	foreach $it (1..length($seq)){
	    $seq1=substr($seq,$it,1);$str1=substr($str,$it,1);
	    if    ( ($seq1=~/[a-z]/) && ($str1=~/[a-z]/) ){
		$seq1=~tr/[a-z]/[A-Z]/;$str1=~tr/[a-z]/[A-Z]/;$seqOut.=$seq1;$strOut.=$str1;}
	    elsif ($seq1=~/[a-z]/){
		$seq1=~tr/[a-z]/[A-Z]/;$seqOut.=$seq1;$strOut.=".";}
	    elsif ($str1=~/[a-z]/){
		$str1=~tr/[a-z]/[A-Z]/;$seqOut.=".";$strOut.=$str1;}
	    else {$seqOut.=$seq1;$strOut.=$str1;}}
				# print
	$tmp[$#tmp-1]=$seqOut;$tmp[$#tmp]=$strOut;
	$tmpOut="";foreach $tmp(@tmp){$tmpOut.="$tmp\t";}$tmpOut=~s/\t$/\n/;
	push(@bodyLoc,$tmpOut);
    }close($fhinLoc);
				# write new
    &open_file("$fhoutLoc",">$fileDaf");
    $Lok=0;
    foreach $header(@headerLoc){ # write header out
	print $fhoutLoc $header;}
    foreach $it (1..($#nameLoc-1)){ # write names
	print $fhoutLoc $nameLoc[$it],"\t";}print $fhoutLoc $nameLoc[$#nameLoc],"\n";
    foreach $body (@bodyLoc){	# write body
	if ((length($incl)>=3)&&($incl ne "unk")){
	    @tmp=split(/\t/,$body);$idStr=$tmp[$ptrIdStr];
	    if ($incl =~ /$idStr/){ $Lincl=1; } else {$Lincl=0;}}
	else {$Lincl=1;}
	if ($Lincl){
	    print $fhoutLoc $body;
	    print substr($body,1,50),"\n";
	}
	else {
	    print"x.x excluded: '$idStr'\n";}
    }close($fhoutLoc);

    if ( (-e $fileDaf) && (&isDaf($fileDaf)) ){
	return (1);}
    else {
	return(0);}
}				# end of convFssp2Daf

#==========================================================================================
sub isDaf {local ($file) = @_ ; local ($Lok);
#--------------------------------------------------------------------------------
#    isDaf                     checks whether or not file is in DAF format
#				(i.e. the dirty ali format used for aqua)
#--------------------------------------------------------------------------------
	   &open_file("FHIN_DAF","$file");
	   while (<FHIN_DAF>){	
	       if (/^\# DAF/){$Lok=1;}
	       else            {$Lok=0;}
	       last;}close(FHIN_DAF);
	   return($Lok);
}				# end of isDaf

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
sub is_fssp_list {
    local ($file_in) = @_ ;
    local ($fh,$Lis);
#--------------------------------------------------------------------------------
#   checks whether or not file is a list of FSSP files
#   input:                file
#--------------------------------------------------------------------------------
    if (! -e $file_in) {
	return (0);}
    $fh="FHIN_CHECK_FSSP_LIST";&open_file("$fh", "$file_in");
    while ( <$fh> ) {
	$_=~s/\s|\n//g;
	if ( -e $_ ) {		# is existing file?
	    if (&is_fssp($_)) {$Lis=1; }
	    else { $Lis=0; } }
	else {$Lis=0; } } 
    close($fh);
    return $Lis;
}				# end of is_fssp_list

#======================================================================
sub open_file {
    local ($file_handle, $file_name, $log_file)=@_ ; local($temp_name); $[=1;
# --------------------------------------------------
    $temp_name=$file_name; $temp_name=~ s/^>>|^>//g;
    if ( ($file_name =~ m/^>>/ ) && ( ! -e $temp_name ) ) {
       print "*** \t INFO: file $temp_name does not exist; create it\n" ;
       open ($file_handle, ">$temp_name") || ( do {
             warn "***\t Can't create new file: $temp_name\n" ;
             if ( $log_file ) {print $log_file "***\t Can't create new file: $temp_name\n" ;}
	 } );close ("$file_handle");}
    
    open ($file_handle, "$file_name") || ( do {
             warn "*** \t Can't open file '$file_name'\n" ;
             if ( $log_file ){print $log_file "*** \t Can't create new file '$file_name'\n";}
             return(0);
	 } );
}

