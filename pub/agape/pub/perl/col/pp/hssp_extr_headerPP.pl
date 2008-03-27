#!/usr/pub/bin/perl4 -w
#----------------------------------------------------------------------
# hssp_extr_header
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# usage: 	hssp_extr_header.pl file_hssp
#
# task:		extracts the header of an HSSP file
# 		
# subroutines   hssp_rd_header_loc
#
#----------------------------------------------------------------------#
#	Burkhard Rost		       November,        1995           #
#			changed:       .	,    	1995           #
#	EMBL				Version 0.1                    #
#	Meyerhofstrasse 1                                              #
#	D-69117 Heidelberg		(rost@EMBL-Heidelberg.DE)      #
#----------------------------------------------------------------------#

local($file_in,$file_out,$fhout,$sep,
      @des,%ptr_form,%rd,$Lok,$des,$tmp_form,$tmp_sep,$tmp,$ct);
      
$[ =1 ;				# sets array count to start at 1, not at 0

if ($#ARGV<1){			# error if insufficient input argument
    print "*** input ERROR, call with 'hssp_extr_header file_hssp' (2nd arg = output)\n";
    exit;}
				# input
$file_in=$ARGV[1];
if ($#ARGV <2){
    $file_out=$file_in;$file_out=~s/^.*\///g;$file_out.="_header";}
else {
    $file_out=$ARGV[2];}
				# defaults
$fhout="FHOUT_HSSP_EXTR_HEADER";
$sep= " ";			# separater for output (between columns)
				# desired column names
@des=("ID","STRID","IDE","WSIM","LALI","NGAP","LGAP","LEN2","ACCNUM","NAME");
				# perl printf formats
$ptr_form{"ID"}="%-10s";$ptr_form{"STRID"}="%-5s";$ptr_form{"IDE"}="%4d";$ptr_form{"WSIM"}="%4d";
$ptr_form{"LALI"}="%4d";$ptr_form{"NGAP"}="%4d";$ptr_form{"LGAP"}="%4d";$ptr_form{"LEN2"}="%4d";
$ptr_form{"ACCNUM"}="%6s";$ptr_form{"NAME"}= "%-25s";
				# --------------------------------------------------
				# call reader
				# --------------------------------------------------
%rd=&hssp_rd_header_loc($file_in);
				# --------------------------------------------------
				# write output file
				# --------------------------------------------------
$Lok=1;
open ("$fhout", ">$file_out") || 
    (do {warn "*** hssp_extr_header: Can't create new file: $file_out\n"; 
	 $Lok=0;
     });
if (!$Lok){
    exit;}
				# write notation into header
print $fhout 
    "--- ------------------------------------------------------------\n",
    "--- MAXHOM multiple sequence alignment\n",
    "--- ------------------------------------------------------------\n",
    "--- \n",
    "--- MAXHOM ALIGNMENT HEADER: ABBREVIATIONS FOR SUMMARY\n",
    "--- ID           : identifier of aligned (homologous) protein\n",
    "--- STRID        : PDB identifier (only for known structures)\n",
    "--- PIDE         : percentage of pairwise sequence identity\n",
    "--- WSIM         : percentage of weighted similarity\n",
    "--- LALI         : number of residues aligned\n",
    "--- NGAP         : number of insertions and deletions (indels)\n",
    "--- LGAP         : number of residues in all indels\n",
    "--- LSEQ2        : length of aligned sequence\n",
    "--- ACCNUM       : SwissProt accession number\n",
    "--- NAME         : one-line description of aligned protein\n",
    "--- \n",
    "--- MAXHOM ALIGNMENT HEADER: SUMMARY\n";

foreach $des (@des){		# print $fhout descriptors
    $tmp_form=$ptr_form{"$des"};
    $tmp_form=~s/d|\.\d+f/s/g;
    if ($des eq $des[$#des]) {
	$tmp_sep="\n";}
    else {
	$tmp_sep="$sep";}
    printf $fhout "$tmp_form$tmp_sep",$des; }

foreach $ct (1..$rd{"NROWS"}){	# print data
    foreach $des (@des){
	if (! defined $rd{"$ct","$des"}) {
	    next;}
	$tmp_form=$ptr_form{"$des"};
	if ($des eq "NAME"){
	    $tmp=substr($rd{"$ct","$des"},1,25);
	    $tmp_sep="\n"; }
	else {
	    if ($des =~ /IDE|WSIM/){
		$tmp=int(100*$rd{"$ct","$des"}); }
	    else {
		$tmp=$rd{"$ct","$des"}; }
	    $tmp_sep=$sep;}
	printf $fhout "$tmp_form$tmp_sep",$tmp; }}
print $fhout
    "--- \n",
    "--- MAXHOM ALIGNMENT: IN MSF FORMAT\n";
close($fhout); 
exit;

#==========================================================================================
sub hssp_rd_header_loc {
    local ($file_hssp,@num) = @_ ;
    local (@des1,@des2,%ptr,$ptr,$len_strid,$Lis_long_id,$fhin,$Lget_all,
	   %rd,@tmp,$tmp,$beg,$mid,$end,$ct,$id,$strid,$des,$num,$Lok);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    hssp_rd_header_loc             reads the header of an HSSP file for numbers 1..$#num
#--------------------------------------------------------------------------------
				# defaults
    $fhin="FHIN_HSSP_HEADER";
    if ($#num==0){
	$Lget_all=1;}
    else {
	$Lget_all=1;}

    @des1=   ("IDE","WSIM","IFIR","ILAS","JFIR","JLAS","LALI","NGAP","LGAP","LEN2","ACCNUM");
    @des2=   ("STRID");
    $ptr{"IDE"}=1;$ptr{"WSIM"}=2;
    $ptr{"IFIR"}=3;$ptr{"ILAS"}=4;$ptr{"JFIR"}=5;$ptr{"JLAS"}=6;
    $ptr{"LALI"}=7;$ptr{"NGAP"}=8;$ptr{"LGAP"}=9;$ptr{"LEN2"}=10; $ptr{"ACCNUM"}=11;

    $len_strid=    4;		# minimal length to identify PDB identifiers

    if ( ! -e $file_hssp) {	# check existence
	return(0); }
				# ini
    $Lis_long_id=0;
				# read file
    open ("$fhin", "$file_hssp") || 
	(do {warn "*** hssp_extr_header: Can't create new file: $file_hssp\n"; });
    while ( <$fhin> ) {		# is it HSSP file?
	if (! /^HSSP /) {
	    return(0); } 
	last; }
    while ( <$fhin> ) {		# length, lond-id
	last if (/^\#\# PROTEINS/); 
	if (/^PARAMETER  LONG-ID :YES/) {$Lis_long_id=1;}
	elsif (/^SEQLENGTH /) {$_=~s/\n|\s|SEQLENGTH//g;
			       $rd{"len1"}=$_; } }
    $ct_taken=0;
    while ( <$fhin> ) { 
	last if (/^\#\# ALIGNMENTS/); 
	if (/^  NR\./){next;}	# skip describtors
	if ($Lis_long_id){
	    $beg=substr($_,1,56);$end=substr($_,109);$mid=substr($_,57,115); }
	else {
	    $beg=substr($_,1,28);$end=substr($_,90);$mid=substr($_,29,90); }
	$end=~s/^\s*|\s*$|\n//g; # purge leading blanks
	$mid=~s/^\s*|\s*$//g;	# purge leading blanks

				# begin: counter and id
	$ct=$beg;$ct=~s/\s*(\d+)\s+\:.*/$1/;$ct=~s/\s//g;
				# ------------------------------
	$Lok=0;			# read it?
	if (! $Lget_all) {
	    foreach $num (@num) {if ($ct eq "$num"){
		$Lok=1;
		last;}}
	    if (! $Lok){
		next;} }
	$beg=~s/.+ \:\s*|\s*$//g;
	if (! $Lis_long_id) {
	    $id=$beg;$id=~s/(.+_\S+).*/$1/;
	    $strid=$beg;$strid=~s/$id|\s//g; }
	else {
	    $id=$beg;$id=~s/(.+_\S+).*/$1/;
	    $strid=substr($_,49,6);$strid=~s/\s//g; }
	$tmp=$len_strid-1;
	if ( (length($strid)<$len_strid) && 
	    ($id=~/^[0-9][A-Z0-9]{$tmp,$tmp}\s*/) ){
	    $strid=substr($id,1,$len_strid); }
	$rd{"$ct","ID"}=$id;
	$rd{"$ct","STRID"}=$strid;
	$rd{"$ct","NAME"}=$end;
	++$ct_taken;
				# middle all info
	$#tmp=0;@tmp=split(/\s+/,$mid);
	foreach $_ (@tmp) {$_=~s/\s//g;}
	foreach $des (@des1){ 
	    if ( ! defined $ptr{"$des"}) {
		next; }
	    $ptr=$ptr{"$des"};
	    $rd{"$ct","$des"}=$tmp[$ptr]; }
    }
    close($fhin);
    $rd{"NROWS"}=$ct_taken;
    return(%rd);
}				# end of hssp_rd_header_loc

