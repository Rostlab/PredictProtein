#!/usr/local/bin/perl -w
##!/usr/pub/bin/perl5 -w
##!/usr/pub/bin/perl4 -w
#----------------------------------------------------------------------
# blastPsi_rdb4pp
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# usage: 	blastPsi_rdb4pp.pl file_rdb
#
# task:	        convert PsiBlast-rdb file to ascii and html format for PP
# 		
# subroutines   rd_rdb
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
    print 
	"*** input ERROR, call with 'blastPsi_rdb4pp.pl file_rdb' (2nd arg = output) or\n",
	"'blastPsi_rdb4pp.pl file_rdb html url_srs'\n";
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
	if ( defined $ARGV[4] ) {
	    $urlSrs = $ARGV[4];
	} else {
	    $urlSrs = "http://srs6.ebi.ac.uk/srs6bin/cgi-bin/wgetz"; # HARD-coded
	}
    }
}

				# defaults
$dirSwiss = '/data/swissprot/current/';
$fhout="FHOUT_BLASTPSI_RDB";
$sep= " ";			# separater for output (between columns)
				# desired column names
@des=("ID","LSEQ2","IDE","SIM","LALI","LGAP","BSCORE","BEXPECT","OMIM","PROTEIN");
				# perl printf formats
$ptr_form{"ID"}="%-27s";$ptr_form{"LSEQ2"}="%5d";$ptr_form{"IDE"}="%4d";$ptr_form{"SIM"}="%4d";
$ptr_form{"LALI"}="%4d";$ptr_form{"LGAP"}="%4d";$ptr_form{"BSCORE"}="%6d";
$ptr_form{"BEXPECT"}="%7s";$ptr_form{"OMIM"}= "%-7s";$ptr_form{"PROTEIN"}= "%-25s";
				# --------------------------------------------------
				# call reader
				# --------------------------------------------------
%rd=&rd_rdb($file_in);
				# --------------------------------------------------
				# write output file
				# --------------------------------------------------
$Lok=1;
open ("$fhout", ">$file_out") || 
    (do {warn "*** blastPsi_rdb4pp: Can't create new file: $file_out\n"; 
	 $Lok=0;
     });
if (!$Lok){
    exit;}
                               # write notation into header
print $fhout 
    "--- ------------------------------------------------------------\n",
    "--- PSI-BLAST multiple sequence alignment\n",
    "--- ------------------------------------------------------------\n",
    "--- \n",
    "--- PSI-BLAST ALIGNMENT HEADER: ABBREVIATIONS FOR SUMMARY\n",
    "--- SEQLENGTH    : $rd{'len1'}\n",
    "--- ID           : identifier of aligned (homologous) protein\n",
    "--- LSEQ2        : length of aligned sequence\n",
    "--- IDE          : percentage of pairwise sequence identity\n",
    "--- SIM          : percentage of similarity\n",
    "--- LALI         : number of residues aligned\n",
    "--- LGAP         : number of residues in all indels\n",
    "--- BSCORE       : blast score (bits)\n",
    "--- BEXPECT      : blast expectation value\n",
    "--- OMIM         : OMIM (Online Mendelian Inheritance in Man) ID\n",
    "--- PROTEIN      : one-line description of aligned protein\n",
    "--- '!'          : indicates lower scoring alignment that is combined\n",
    "                   with the higher scoring adjacent one\n",
    "--- \n",
    "--- PSI-BLAST ALIGNMENT HEADER: SUMMARY\n\n";


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
	if ($des eq "PROTEIN"){
	    $tmp=substr($rd{"$ct","$des"},1,25);
	    $tmp_sep="\n"; }
	else {
	    if ($des =~ /IDE|SIM/){
		$tmp=int($rd{"$ct","$des"}); }
	    else {
		$tmp=$rd{"$ct","$des"}; }
	    $tmp_sep=$sep;}
	if ( $isHtml and $des =~ /^(ID|OMIM)$/ ) {
	    $tmp = "";
	    $tmp_id = $rd{"$ct","$des"};
	    $tmp_len = length ( $tmp_id );
	    $short_id = $tmp_id;
	    $short_id =~ s/^.*\|//g;
	    $tmp = "<A HREF=$urlSrs"."?-id+-e+-e+[";
	    if ( $des eq "ID" ) {
		if ( $tmp_id =~ /^(\w+)\|/ ) {
		    $database = uc($1);
		    $database="SWISSPROT" if ($database eq "SWISS");
		    $database="SPTREMBLE" if ($database eq "TREMBL");
		    $short_id =~ s/\_\w+$// if ($database eq "PDB");
		} else {
		    $database = "SWISSPROT";
		}
		$tmp .= "$database-ID";
	    } elsif ( $des eq "OMIM" ) {
		$tmp .= "omim-ID";
	    }
	    $tmp .= ":'$short_id"."']>$tmp_id"."</A>";
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
    "--- \n\n";
close($fhout); 
exit;

#==========================================================================================
sub rd_rdb {
    local ($file_rdb) = @_ ;
    local (@des1,$fhin,
	   %rd,@tmp,$tmp,$ct,$id,$idOmim,$hasOmim,$ctDes);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    rd_rdb             reads the PSI-BLAST RDB file 
#--------------------------------------------------------------------------------
				# defaults
    $fhin="FHIN_RDB";
    return(0)                   if ( ! -e $file_rdb);	# check existence
   
				# read file
    open ("$fhin", "$file_rdb") || 
	(do {warn "*** rd_rdb ($0): Cannot read file: $file_rdb\n"; });

    while ( <$fhin> ) {		# length
	if ($_=~/^\/\//) {
	    last;
	}
	if ($_=~/^\#SEQLENGTH/) {
	    $_=~s/\n|\s|SEQLENGTH|\#//g;
	    $rd{"len1"}=$_; } 
    }

    $hasOmim = 0;
    $ct=0;
    while ( <$fhin> ) { 
	next if ( $_ !~ /\w+/ ); # skip empty lines if any
	s/^\s+|\s+$//g;
	s/\%//g;
	if ( /^\#ID/ ) {	# header
	    s/\#//g;
	    @des1 = split/\t/;
	    $ctDes = scalar(@des1);
	    next;
	}

	@tmp=split /\t/;
	return (0) if ( scalar(@tmp) != $ctDes );
	$ct++;
	for $i (1..$ctDes) {
	    $rd{"$ct","$des1[$i]"}=$tmp[$i];
	}

	$id = $rd{"$ct","ID"};
	if ( $id =~ /^swiss/ ) { # only get OMIM from SWISSPROT
	    $idOmim = &getOmim($id);
	} else {
	    $idOmim = "";
	}
	$rd{"$ct","OMIM"}= $idOmim;
	$hasOmim = 1 if ( $idOmim );  
    }
    close($fhin);
    $rd{"NROWS"}=$ct;
    return(%rd);
}				# end of rd_rdb


sub getOmim {
    local ( $id ) = @_;
    local ( $subDir, $fileSwiss, $idOmim );

    $id =~ s/^.*\|//g;
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
