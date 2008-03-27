#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
# merges z-score (from strip) into  hssp header
#
#
$[ =1 ;

push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
#require "ctime.pl";		# require "rs_ut.pl" ;
require "lib-ut.pl"; require "lib-br.pl";

@des=  ("fileHssp","fileStrip","fileOut","naliWrt");
				# ------------------------------
				# help
if ($#ARGV<1){print"goal:   merges z-score (from strip) into hssp header\n";
	      print"usage:  'script file.hssp_topits (or list)'\n";
	      print"note1:  you can give the list in a file or by *.hssp\n";
	      print"note2:  strip by default: file with .hssp -> .strip\n";
	      print"option: \n";
	      &myprt_array(",",@des);
	      exit;}

				# ------------------------------
				# defaults
$par{"fileOut"}=        "Out_$$.tmp";

@kwdHsspTop=  (
	       "date","db","parameter","threshold","header","compnd","source",
	       "pdbid1","len1","nchain","kchain","nali"
	       );
@kwdHsspPair= (
	       "id1","id2","pide","wsim","lali","ngap","lgap","len2",
	       "ifir","ilas","jfir","jlas",
#		"swissAcc","pdbid2"
	       );
@kwdStripPair=(
	       "energy","zscore","strh","name" 
#	       "rmsd",
	       );
@kwdWrtPair=(@kwdHsspPair,@kwdStripPair);

foreach $des ("zscore"){
    $form{"$des"}="6.3f";}
foreach $des ("energy"){
    $form{"$des"}="6.2f";}
foreach $des("pide","wsim","lali","ngap","lgap","len2","len1",
	     "ifir","ilas","jfir","jlas","strh"){
    $form{"$des"}="4d";}
foreach $des("id1","id2"){
    $form{"$des"}="-6s";}
foreach $des("name"){
    $form{"$des"}="-s";}

$fhout="FHOUT";$fhin="FHIN";
$Lverb=1;

$fileError="MissingMaxhom.list";
				# now hack to run maxhom
$fileDssp=      $ARGV[1];
$title=$fileDssp;
$title=~s/^.*\///g;
$title=~s/\.dssp//g;
$title=~s/[_\-!]//g;		# purge chain '_-'

$exeMax=        "/sander/purple1/rost/prog/".$ARCH."/maxhom_big.".$ARCH;

if (! -x $exeMax)     {print "*** maxhom executable missing '$exeMax'\n";
		       exit;}

$fileHssp=      "$title".".hssp";
$fileStrip=     "$title".".strip";
				# ------------------------------
				# run maxhom
$cmd="maxTopits0.csh $fileDssp $exeMax $fileHssp $fileStrip";
system("$cmd");
				# check file existence
if (! -e $fileHssp)   {
    print "*** after maxhom output missing '$fileHssp'\n";
    system("echo '$fileDssp' >> $fileError");
    exit;}
if (! -e $fileStrip)  {
    print "*** after maxhom output missing '$fileHssp'\n";
    system("echo '$fileDssp' >> $fileError");
    exit;}
				# ------------------------------
				# extract header
$fileOutHsspRdb="$title".".rdbMax";

$Lok=&hsspHeaderProcess();
				# 
				# check file existence
if (! -e $fileOutHsspRdb)   {
    print "*** after extract header from maxhom, output missing '$fileOutHsspRdb'\n";
    system("echo '$fileDssp' >> $fileError");
    exit;}

undef %hdr;			# save space

exit;				# 

				# ------------------------------------------------------------
				# loop over files
$ctFile=0;
foreach $it (1..$#fileHssp){
    $fileHssp= $fileHssp[$it];
    $fileStrip=$fileStrip[$it];
    $id1=$fileHssp;$id1=~s/\.*\///g;
    $id1=~s/\.hssp//g;$id1=~s/_?topits//g;

				# xx

    exit;			# xx
}				# end of loop over files
				# ------------------------------------------------------------

$nFiles=$ctFile;

&wrtMergedHeader("STDOUT",",",$nFiles,$par{"naliWrt"},@desWrt);
$fileOut=$par{"fileOut"};
print "x.x file=$fileOut,\n";
&open_file("$fhout", ">$fileOut");
&wrtMergedHeader($fhout,"\t",$nFiles,$par{"naliWrt"},@desWrt);
close($fhout);

print "x.x output in '$fileOut'\n";
exit;

#===============================================================================
sub hsspHeaderProcess {
#    local($fileInLoc,$fhErrSbr) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspHeaderProcess           reads and writes header from HSSP and STRIP
#       GLOBAL in:              all variables global !!
#-------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";}
    $sbrName="$tmp"."hsspHeaderProcess";$fhinLoc="FHIN"."$sbrName";
				# ------------------------------
				# write top of hssp header
#    $fhout="STDOUT";		# xx
#    $preLoc="--- ";		# xx
    $preLoc=" ";		# xx
    $txtMode="rdb";
    $sep=   "\t";
				# ------------------------------
				# call library subroutine to read
    ($Lok,%hdr)=
	&hsspRdStripAndHeader($fileHssp,$fileStrip,"STDOUT",
			      "hsspTop",@kwdHsspTop,
			      "hsspPair",@kwdHsspPair,
			      "strip",@kwdStripPair);
				# ------------------------------
				# open file
    &open_file("$fhout", ">$fileOutHsspRdb");
				# ------------------------------
    &wrtHsspHeaderTopFirstLine($fhout,$preLoc,$txtMode);
				# write abbreviations
    &wrtHsspHeaderTopBlabla($fhout,$preLoc,$txtMode,1,1,1);
    
    $#tmp=0;			# ------------------------------
    foreach $kwd (@kwdHsspTop){	# write info for guide
	push(@tmp,$kwd,$hdr{"$kwd"});}
    &wrtHsspHeaderTopData($fhout,$preLoc,$txtMode,@tmp);
				# only one line: identifier
    &wrtHsspHeaderTopLastLine($fhout,$preLoc,$txtMode);

    				# ------------------------------
				# write all data
    &wrtHsspHeaderWrtPairs($fhout,$sep);
    close($fhout);
    return(1);
}				# end of hsspHeaderProcess

#===============================================================================
sub wrtHsspHeaderWrtPairs {
    local($fhoutLoc2,$sepLoc2) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   wrtHsspHeaderWrtPairs      writes the HSSP + STRIP header info for all pairs
#       GLOBAL in:              all variables global !!
#-------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";}
    $sbrName="$tmp"."wrtHsspHeaderPairs";$fhinLoc="FHIN"."$sbrName";
				# ------------------------------
				# write names
    foreach $kwd(@kwdWrtPair){
	if ($kwd eq $kwdWrtPair[$#kwdWrtPair]){
	    $sepTmp="\n";}else{$sepTmp=$sepLoc2;}
	$form="%".$form{"$kwd"};$form=~s/\.\d*//g;$form=~s/[dnfe]/s/g;
	$kwdTmp=$kwd;$kwdTmp=~tr/[a-z]/[A-Z]/;	# uppercase
	printf $fhoutLoc2 "$form",$kwdTmp; print  $fhoutLoc2 "$sepTmp";}
				# ------------------------------
				# write formats
    foreach $kwd(@kwdWrtPair){
	if ($kwd eq $kwdWrtPair[$#kwdWrtPair]){
	    $sepTmp="\n";}else{$sepTmp=$sepLoc2;}
	$form="%".$form{"$kwd"};$form=~s/\.\d*//g;$form=~s/[dnfe]/s/g;
	printf $fhoutLoc2 "$form",&form_perl2rdb($form{"$kwd"}); print  $fhoutLoc2 "$sepTmp";}
				# --------------------------------------------------
				# loop over all pairs
    foreach $it (1 .. $hdr{"NROWS"}){
	$#tmp=0;
	foreach $kwd(@kwdWrtPair){
	    if ($kwd eq $kwdWrtPair[$#kwdWrtPair]){
		$sepTmp="\n";}else{$sepTmp=$sepLoc2;}
	    $form=$form{"$kwd"};$form="%".$form{"$kwd"};
	    if (($kwd =~ /^name/)&&($fhoutLoc2 eq "STDOUT")){
#		$val=substr($hdr{"$kwd","$it"},1,1);
		$val=" ";}
	    else{$val=$hdr{"$kwd","$it"};}
	    printf $fhoutLoc2 "$form",$val;print  $fhoutLoc2 "$sepTmp";}}
}				# end of wrtHsspHeaderWrtPairs

