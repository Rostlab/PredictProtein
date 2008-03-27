#!/usr/bin/perl -w
#!/usr/local/bin/perl -w
##!/usr/pub/bin/perl5 -w
##!/usr/pub/bin/perl4 -w
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
      @des,%ptr_form,%rd,$Lok,$des,$tmp_form,$tmp_sep,$tmp,$ct,
      $tmp_id, $remain_len, $tmp_len, $field_width);
      
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

$isHtml = 0;
if ( $#ARGV > 2 ) {
    if ( $ARGV[3] eq 'html' ) {
	$isHtml = 1;
	if (defined $ARGV[4]) {
	    $urlSrs = $ARGV[4] ;
	} else {
	    $urlSrs = "http://srs.ebi.ac.uk/srs6bin/cgi-bin/wgetz"; # HARD-CODED
	}
    }
}

				# defaults
$dirSwiss = '/data/swissprot/current/';
$fhout="FHOUT_HSSP_EXTR_HEADER";
$sep= " ";			# separater for output (between columns)
				# desired column names
@des=("ID","STRID","IDE","WSIM","LALI","NGAP","LGAP","LSEQ2","ACCNUM","OMIM","NAME");
				# perl printf formats
$ptr_form{"ID"}="%-10s";$ptr_form{"STRID"}="%-5s";$ptr_form{"IDE"}="%4d";$ptr_form{"WSIM"}="%4d";
$ptr_form{"LALI"}="%4d";$ptr_form{"NGAP"}="%4d";$ptr_form{"LGAP"}="%4d";$ptr_form{"LSEQ2"}="%5d";
$ptr_form{"ACCNUM"}="%6s";$ptr_form{"OMIM"}= "%-7s";$ptr_form{"NAME"}= "%-25s";
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
    "--- IDE          : percentage of pairwise sequence identity\n",
    "--- WSIM         : percentage of weighted similarity\n",
    "--- LALI         : number of residues aligned\n",
    "--- NGAP         : number of insertions and deletions (indels)\n",
    "--- LGAP         : number of residues in all indels\n",
    "--- LSEQ2        : length of aligned sequence\n",
    "--- ACCNUM       : SwissProt accession number\n",
    "--- OMIM         : OMIM (Online Mendelian Inheritance in Man) ID\n",
    "--- NAME         : one-line description of aligned protein\n",
    "--- \n",
    "--- MAXHOM ALIGNMENT HEADER: SUMMARY\n";

foreach $des (@des){		# print $fhout descriptors
    next if ( $des eq "OMIM" and ! $hasOmim);
    $tmp_form=$ptr_form{"$des"};
    $tmp_form=~s/d|\.\d+f/s/g;
    if ($des eq $des[$#des]) {
	$tmp_sep="\n";}
    else {
	$tmp_sep="$sep";}
    printf $fhout "$tmp_form$tmp_sep",$des; }

foreach $ct (1..$rd{"NROWS"}){	# print data
    foreach $des (@des){
	next if ( $des eq "OMIM" and ! $hasOmim);
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
	if ( $isHtml and $des =~ /^(ID|OMIM)$/ ) {
	    $tmp = "";
	    $tmp_id = $rd{"$ct","$des"};
	    $tmp_len = length ( $tmp_id );
	    $tmp = "<A HREF=$urlSrs"."?-e+[";
	    if ( $des eq "ID" ) {
		$tmp .= "SWISSPROT-ID";
	    } elsif ( $des eq "OMIM" ) {
		$tmp .= "omim-ID";
	    }
	    $tmp .= ":'$tmp_id"."'] TARGET=_blank >$tmp_id"."</A>";
	    if ( $tmp_form =~ /\D+(\d+)\D+/ ) {
		$field_width = $1;
	    }
	    $remain_len = $field_width - $tmp_len + 1;
	    if ( $tmp_id ) {
		$tmp .= " "x$remain_len;
	    } else {
		$tmp = " "x$remain_len;
	    }
	    print $fhout $tmp;
	} else {
	    printf $fhout "$tmp_form$tmp_sep",$tmp;
	}
    }
}
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

    @des1=   ("IDE","WSIM","IFIR","ILAS","JFIR","JLAS","LALI","NGAP","LGAP","LSEQ2","ACCNUM");
    @des2=   ("STRID");
    $ptr{"IDE"}=1;$ptr{"WSIM"}=2;
    $ptr{"IFIR"}=3;$ptr{"ILAS"}=4;$ptr{"JFIR"}=5;$ptr{"JLAS"}=6;
    $ptr{"LALI"}=7;$ptr{"NGAP"}=8;$ptr{"LGAP"}=9;$ptr{"LSEQ2"}=10; $ptr{"ACCNUM"}=11;

    $len_strid=    4;		# minimal length to identify PDB identifiers

    return(0)                   if ( ! -e $file_hssp);	# check existence
				# ini
    $Lis_long_id=0;
				# read file
    open ("$fhin", "$file_hssp") || 
	(do {warn "*** hssp_rd_header_loc ($0): Cannot create new file: $file_hssp\n"; });

    while ( <$fhin> ) {		# is it HSSP file?
	return(0)               if ($_ !~ /^HSSP /);
	last; }
    while ( <$fhin> ) {		# length, lond-id
	last if ($_=~/^\#\# PROTEINS/); 
	if    ($_=~/^PARAMETER  LONG-ID :YES/) {
	    $Lis_long_id=1;}
	elsif ($_=~/^SEQLENGTH /) {
	    $_=~s/\n|\s|SEQLENGTH//g;
	    $rd{"len1"}=$_; } }
    $ct_taken=0;
    $hasOmim = 0;
    while ( <$fhin> ) { 
	last if ($_=~/^\#\# ALIGNMENTS/); 
	next if ($_=~/^  NR\./); # skip describtors
	$end="";
	if ($Lis_long_id){
	    $beg=substr($_,1,56);
	    $mid=substr($_,57,115); 
	    $end=substr($_,109) if (length($_) > 109); }
	else {			# 
	    $beg=substr($_,1,28);
	    $mid=substr($_,29,90);
	    $end=substr($_,90)  if (length($_) > 90); }
	$end=~s/^\s*|\s*$|\n//g; # purge leading blanks
	$mid=~s/^\s*|\s*$//g;	# purge leading blanks

				# begin: counter and id
	$ct=$beg;$ct=~s/\s*(\d+)\s+\:.*/$1/;$ct=~s/\s//g;
				# ------------------------------
	$Lok=0;			# read it?
	if (! $Lget_all) {
	    foreach $num (@num) {if ($ct eq "$num"){
		$Lok=1;
		last;}}		# 
	    next if (! $Lok); }	
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
	$idOmim = &getOmim($id);
	$rd{"$ct","OMIM"}= $idOmim;
	$hasOmim = 1 if ( $idOmim );
	++$ct_taken;
				# middle all info
	$#tmp=0;@tmp=split(/\s+/,$mid);
	foreach $_ (@tmp) {$_=~s/\s//g;}
	foreach $des (@des1){ 
	    next if ( ! defined $ptr{"$des"}) ;
	    $ptr=$ptr{"$des"};
	    $rd{"$ct","$des"}=$tmp[$ptr]; }
    }
    close($fhin);
    $rd{"NROWS"}=$ct_taken;
    return(%rd);
}				# end of hssp_rd_header_loc


sub getOmim {
    local ( $id ) = @_;
    local ( $subDir, $fileSwiss, $idOmim );

    if ( $id =~ /[1-9a-zA-Z]+_(\w)/ ) {
	$subDir = $1.'/';
    } else {
	$subDir = '';
    }
    $fileSwiss = $dirSwiss.$subDir.$id;
    return "" if ( ! -e $fileSwiss );
    open ( SWISS, $fileSwiss ) or return "";
    $idOmim = "";
    while ( <SWISS> ) {
	if ( /^DR\s+MIM\;\s*(\d+)\D+/ ) {
	    $idOmim = $1;
	    last;
	}
	last if ( /^SQ/ );
    }
    return $idOmim;
}











#================================================================================ #
#                                                                                 #
#-------------------------------------------------------------------------------- #
# Predict Protein - a secondary structure prediction and sequence analysis system #
# Copyright (C) <2004> CUBIC, Columbia University                                 #
#                                                                                 #
# Burkhard Rost         rost@columbia.edu                                         #
# http://cubic.bioc.columbia.edu/~rost/                                           #
# Jinfeng Liu             liu@cubic.bioc.columbia.edu                             #
# Guy Yachdav         yachdav@cubic.bioc.columbia.edu                             #
#                                                                                 #
# This program is free software; you can redistribute it and/or modify it under   #
# the terms of the GNU General Public License as published by the Free Software   #
# Foundation; either version 2 of the License, or (at your option)                #
# any later version.                                                              #
#                                                                                 #
# This program is distributed in the hope that it will be useful,                 #
# but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY  #
# or FITNESS FOR A PARTICULAR PURPOSE.                                            #
# See the GNU General Public License for more details.                            #
#                                                                                 #
# You should have received a copy of the GNU General Public License along with    #
# this program; if not, write to the Free Software Foundation, Inc.,              #
# 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA                         #
#                                                                                 #
# Contact Information:                                                            #
#                                                                                 #
# predict_help@columbia.edu                                                       #
#                                                                                 #
# CUBIC   Columbia University                                                     #
# Department of Biochemistry & Molecular Biophysics                               #
# 630 West, 168 Street, BB217                                                     #
# New York, N.Y. 10032 USA                                                        #
# Tel +1-212-305 4018 / Fax +1-212-305 7932                                       #
#================================================================================ #
