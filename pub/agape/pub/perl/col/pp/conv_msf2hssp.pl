#!/bin/env perl
##!/usr/pub/bin/perl4 -w
#------------------------------------------------------------------------------#
# other perl environments
# EMBL
##!/usr/pub/bin/perl4 -w
##!/usr/pub/bin/perl -w
# EBI
##!/usr/bin/perl -w
#------------------------------------------------------------------------------#
$[ =1 ;

$ARCH=$ENV{'ARCH'}; 
if (! defined $ARCH){ $ARCH=$ENV{'CPUARC'};}
if (! defined $ARCH){ $ARCH="SGI64";}
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;

if ($#ARGV<1){print"goal:     convert MSF format to HSSP\n";
	      print"usage:    'script file.msf'\n";
	      print"option:   'fileHssp=x' : name of output file (default file.hssp)\n";
	      print"          'ARCH=x' x=SGI64, or x=ALPHA (default $ARCH)\n";
	      print"          'exe=convert_seq' 'fileMet=Maxhom_GCG.metric'\n";
	      exit;}
$fileHssp="unk";
$exe_convert_seq=     "/home/rost/pub/phd/bin/convert_seq.$ARCH";
$file_convert_seq_gcg="/home/rost/pub/max/mat/Maxhom_GCG.metric";

$fileMsf=$ARGV[1];

foreach$arg(@ARGV){
    if   ($arg =~/^fileHssp=/)      {$arg=~s/^fileHssp=|\s//g;$fileHssp=$arg;}
    elsif($arg =~/ARCH=/)           {$arg=~s/^ARCH=|\s//g;$ARCH=$arg;}
    elsif($arg =~/^exe.*=(.+)$/)    {$exe_convert_seq=$1;}
    elsif($arg =~/^fileMet.*=(.+)$/){$file_convert_seq_gcg=$1;}
}

if ($fileHssp eq "unk"){
    $fileHssp=$fileMsf;$fileHssp=~s/^.*\///g;$fileHssp=~s/\.msf/\.hssp/;}
				# ------------------------------
				# precheck
($Lok,$err)=
    &msfCheckNames($fileMsf);
if (! $Lok){
    print "*** ERROR in msfCheckNames ($scrName) reading $fileMsf\n";
    die ("*** ERROR from msfCheckNames ($scrName) reading $fileMsf\n");}
if ($err ne "1"){
    print "*** ERROR in msfCheckNames ($scrName) reading $fileMsf\n";
    die ("*** ERROR from msfCheckNames ($scrName) reading $fileMsf\n");}
				# ------------------------------
				# do conversion
$Lok=
    &convMsf2Hssp($fileMsf,$fileHssp,$exe_convert_seq,$file_convert_seq_gcg);
if (! $Lok){
    print "*** ERROR in perl script conv_msf2hssp '$fileHssp' empty or missing\n";}
exit;

#==========================================================================================
sub convMsf2Hssp {
    local($fileMsfLoc,$fileHsspLoc,$exeConvLoc,$fileMatGCG) = @_ ;
    local($sbrName,$fhinLoc,$form_out,$an,$command);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   convMsf2Hssp                converts the MSF into an HSSP file
#       in:                     fileMsf, fileHssp(name of output file), exeConv (convert_seq)
#       out:                    fileHssp (written by convert_seq)
#--------------------------------------------------------------------------------
    $sbrName="convMsf2Hssp";$fhinLoc="FHIN"."$sbrName";
    if (! -e $fileMsfLoc){
	print "*** ERROR $sbrName \t '$fileMsfLoc' msf file missing\n";
	return(0);}
				# input for fortran program
    $form_out= "H";
    $an1=      "N";		# gaps in master sequences treated as insertions
    $an2=      " ";		# choose name of HSSP master sequence, automatically read
    $an3=      "N";		# write another format?
    $command=  "";
				# call fortran 
    eval "\$command=\"$exeConvLoc,$fileMsfLoc,$form_out,$fileMatGCG,$an1,$fileHsspLoc,$an2,$an3\"";
    &run_program("$command" ,"LOGFILE","die"); # from external lib-ut.pl

				# check existence (and emptiness) of HSSP file
    if (! -e $fileHsspLoc){
	print "*** ERROR $sbrName \t '$fileHsspLoc' converted HSSP file missing\n";
	return(0);}
				# check existence (and emptiness) of HSSP file
    if (&is_hssp_empty($fileHsspLoc)){
	print "*** ERROR $sbrName \t '$fileHsspLoc' converted HSSP file empty\n";
	return(0);}
    return(1);
}				# end of convMsf2Hssp

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

#======================================================================
sub run_program {
    local ($cmd, $log_file, $action) = @_ ;
    local ($out_command,$cmdtmp);
    $[ =1;

    ($cmdtmp,@out_command)=split(",",$cmd) ;

    if ((! defined $Lverb)||$Lverb){print "--- running command: \t $cmdtmp"; }
    if (defined $action){print"do='$action'";}print"\n" ;

    open (TMP_CMD, "|$cmdtmp") || ( do {
	if ( $log_file ) {print $log_file "Can't run command: $cmdtmp\n" ;}
	warn "Can't run command: '$cmdtmp'\n" ;
	if (defined $action){
	    exec $action ;}
    } );
    foreach $command (@out_command) {
# delete end of line, and spaces in front and at the end of the string
	$command =~ s/\n// ;
	$command =~ s/^ *//g ;
	$command =~ s/ *$//g ; 
	print TMP_CMD "$command\n" ;
    }
    close (TMP_CMD) ;
}

#===============================================================================
sub msfCheckNames {
    local($fileInLoc,$fhErrSbr) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   msfCheckNames               reads MSF file and checks consistency of names
#       in:                     $fileMsf
#       out:                    (0,err=list of wrong names)(1,"ok")
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."msfCheckNames";$fhinLoc="FHIN"."$sbrName";

    $Lok=       &open_file("$fhinLoc","$fileInLoc");
    if (! $Lok){print $fhErrSbr "*** ERROR $sbrName: '$fileInLoc' not opened\n";
		return(0,"'$fileInLoc' not opened");}
    undef %name; $Lerr=$#name=0;
				# ------------------------------
    while (<$fhinLoc>) {	# read header
	$_=~s/\n//g;
				# read names in header
	if ($_=~/^\s*name\:\s*(\S+)/i){
	    $name{$1}=1;push(@name,$1);
	    if (length($1)>=15){
		print "*** ERROR name must be shorter than 15 characters ($1)\n";
		print "***       it is ",length($1),"\n";
		$Lerr=1;}
	    if (! defined $len){ # sequence length
		$len=$_;$len=~s/^\s*[Nn]ame:\s*\S+\s+[Ll]en:\s*(\d+)\D.*$/$1/;}
	    next;}
	last if ($_=~/\/\//);}
    $ctBlock=0;undef %ctRes;	# ------------------------------
    while (<$fhinLoc>) {	# read body
	$_=~s/\n//g;$tmp=$_;$tmp=~s/\s//g;
	next if (length($tmp)<3);
	if ($_=~/^\s+\d+\s+/ && ($_!~/[A-Za-z]/)){
	    ++$ctBlock;$ctName=0; undef %ctName;
	    next;}
	$name=$_;$name=~s/^\s*(\S+)\s*.*$/$1/;
	$seq= $_;$seq =~s/^\s*\S+\s+//;$seq=~s/\s//g;
	$ctRes{$name}+=length($seq); # sequence length
	if (! defined $name{$name}){
	    print "*** block $ctBlock, name=$name not used before\n";
	    $Lerr=1;}
	else {
	    ++$ctName; 
	    if (! defined $ctName{$name} ){
		$ctName{$name}=1;} # 
	    else {print "*** block $ctBlock, name=$name more than once\n";
		  $Lerr=1;}}}close($fhinLoc);
    foreach $name(@name){
	if ($ctRes{$name} != $len){
	    print 
		"*** name=$name, wrong no of residues, is=",
		$ctRes{$name},", should be=$len\n";
	    $Lerr=1;}}
    return (1,1) if (! $Lerr);
    return (1,0) if ($Lerr);
}				# end of msfCheckNames

