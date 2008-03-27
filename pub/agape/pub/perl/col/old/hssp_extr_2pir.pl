#!/usr/bin/perl -w
#----------------------------------------------------------------------
# hssp_extr_2pir
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# usage: 	hssp_extr_2pir.pl file_hssp
#
# task:		1. filter_hssp 2. extract into PIR format
# 		
#----------------------------------------------------------------------#
#	Burkhard Rost		       April	,       1995           #
#			changed:       .	,    	1995           #
#	EMBL				Version 0.1                    #
#	Meyerhofstrasse 1                                              #
#	D-69117 Heidelberg		(rost@EMBL-Heidelberg.DE)      #
#----------------------------------------------------------------------#

				# --------------------------------------------------
				# sets array count to start at 1, not at 0
				# --------------------------------------------------
$[ =1 ;
				# --------------------------------------------------
				# initialise variables
				# --------------------------------------------------
&hssp_extr_2pir_ini();

# --------------------------------------------------------------------------------
# do the job (here we go)
# --------------------------------------------------------------------------------
				# ------------------------------
				# read all hits matchin range
&hssp_rd_seq($file_in,$excl_txt,$incl_txt,$symbol_ins);
				# ------------------------------
				# now write as PIR format
@file_out=&wrt_files($fhout,$title_out,$mode_out,$Lscreen,@take);

# --------------------------------------------------------------------------------
# work done
# --------------------------------------------------------------------------------
if ($Lscreen) { &myprt_empty; &myprt_line; &myprt_txt(" $script_name has ended fine .. -:\)"); 
		&myprt_empty; &myprt_txt(" output in files: "); 
		print"--- \t \t "; foreach$i(@file_out){print"$i,";} print "\n";
	    }
exit;

#==========================================================================================
sub hssp_extr_2pir_ini {
    local ($script_input,$script_goal,$script_narg,
	   @script_goal,@script_help,@script_opt_key,@script_opt_keydes,$txt,$it);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   initialises variables/arguments
#--------------------------------------------------------------------------------
#
#	$date is e.g.:		Oct:14:13:06:47:1993
#	@Date is e.g.:		Oct1413:06:471993
#	&ctime(time) is e.g.:	Thu Oct 14 13:06:47 1993
#
    @Date = split(' ',&ctime(time)) ; shift (@Date) ; 

    # ------------------------------------------------------------
    # about script
    # ------------------------------------------------------------
    $script_name=   "hssp_extr_2pir";
    $script_input=  "file_hssp";
    $script_goal=   "1. filter_hssp 2. extract into PIR format";
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
		     "out_id",
		     " ",
		     "not_screen",
		     "title_out",
		     "fileOut=",
		     "dir_in=",
		     "dir_out=",
		     "dir_work=",
		     );
    @script_opt_keydes= 
	            ("sequences n1 to n2 will be excluded: \n".
		     "--- \t \t n1-*, n1-n2, or: n1,n5,... ",
		     "sequences m1 to m2 will be included: \n".
		     "--- \t \t m1-*, m1-m2, or: m1,m5,... \n".
		     "--- \t \t or: incl=pdbid => only 2:guide and pdbid",
		     "output files named x_id.pir,\n".
		     "--- \t \t with x: x.hssp, default: x_no.pir ",
		     " ",
		     "no information written onto screen",
		     "title for output file",
		     "output file name",
		     "input dir name,   default: local",
		     "output dir names, default: local",
		     "working dir name, default: local",
		     );

    if ( ($ARGV[1]=~/^help/) || ($ARGV[1]=~/^man/) ) { 
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
				# --------------------
				# directories
    $dir_in=    "";
    $dir_out=   "";
    $dir_work=  "";
				# --------------------
				# files
				# file extensions
				# file handles
    $fhout=     "FHOUT";
    $fhin=      "FHIN";
				# --------------------
				# further
    $excl_txt=  "unk";		# n-m -> exclude positions n to m
    $incl_txt=  "unk";
    $mode_out=  "id";		# output file will be named with title_id.pir
    $mode_out=  "no";		# output file will be named with title_no.pir

    $symbol_ins="-";		# symbol used for insertions
				# --------------------
				# logicals
    $Lscreen=   1;		# blabla on screen
				# --------------------
				# executables

    # ------------------------------------------------------------
    # read input arguments
    # ------------------------------------------------------------
    $file_in=   $ARGV[1];
				# output file
    $title_out= $file_in; $title_out=~s/\.hssp.*|\s//g;

    if ($#ARGV>$script_narg) {
	for($it=($script_narg+1);$it<=$#ARGV;++$it) {
	    $_=$ARGV[$it];
	    if ( /not_screen/ ) {    $Lscreen=0; }
	    elsif ( /excl=/ ) {      $tmp=$ARGV[$it];$tmp=~s/\n|excl=//g;
				     $excl_txt=$tmp; $excl_txt=~s/\(|\)//g; }
	    elsif ( /incl=/ ) {      $tmp=$ARGV[$it];$tmp=~s/\n|incl=//g;
				     $incl_txt=$tmp; $incl_txt=~s/\(|\)//g; }
	    elsif ( /out_id/ ) {     $tmp=$ARGV[$it];$mode_out="id"; }
	    elsif ( /title_out=/ ) { $tmp=$ARGV[$it];$tmp=~s/\n|title_out=//g; 
				     $title_out=$tmp; }
	    elsif ( /fileOut=/ )   { $_=~s/^fileOut=|\s//g;$fileOut=$_;}
	    elsif ( /dir_in=/ ) {    $tmp=$ARGV[$it];$tmp=~s/\n|dir_in=//g; 
				     $dir_in=$tmp; }
	    elsif ( /dir_out=/ ) {   $tmp=$ARGV[$it];$tmp=~s/\n|dir_out=//g; 
				     $dir_out=$tmp; }
	    elsif ( /dir_work=/ ) {  $tmp=$ARGV[$it];$tmp=~s/\n|dir_work=//g; 
				     $dir_work=$tmp; }
	}
    }

    # ------------------------------------------------------------
    # assignments dependent on input read
    # ------------------------------------------------------------
    if (length($dir_in)>1) {   &complete_dir($dir_in);$dir_in=$DIR;
			       $tmp=$file_in; $file_in="$dir_in"."$tmp";}
    if (length($dir_out)>1) {  &complete_dir($dir_out);$dir_out=$DIR;
			       $tmp=$file_out; $file_out="$dir_out"."$tmp";}
    if (length($dir_work)>1) { &complete_dir($dir_work);$dir_work=$DIR; }

    if ($Lscreen) { &myprt_line; &myprt_txt("perl script that $script_goal"); 
		    &myprt_empty; &myprt_txt("file_in: \t \t $file_in"); 
		    &myprt_txt("title_out: \t \t $title_out");
		    if ($excl_txt!~/unk/) {&myprt_txt("exclude pos:\t\t$excl_txt"); }
		    if ($incl_txt!~/unk/) {&myprt_txt("include pos:\t\t$incl_txt"); }
		    &myprt_txt("end of setting up,\t let's work on it"); 
		    &myprt_empty; &myprt_line; &myprt_empty; }

    # ------------------------------------------------------------
    # check existence of file
    # ------------------------------------------------------------
    if ( (length($file_in)>0) && (! -e $file_in) ) {
	&myprt_empty;&myprt_txt("ERROR $script_name:\t file_in '$file_in' does not exist");exit;}
}				# end of hssp_extr_2pir_ini

#==========================================================================================
sub hssp_rd_seq {
    local ($file_hssp,$excl_txt,$incl_txt,$symbol_ins) = @_ ;
    local ($fhin,@excl,@incl,$nali,$len1,$beg_ali,$pos_guide_seq,
	   $tmp,@tmp,$ctres,$pos_1st,$take,@take_one);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    hssp_rd_seq                       
#         reads the HSSP file and stores the alignments to be extracted
#       GLOBAL out:             @take (positions to be written)
#                               $rd{} 
#                               guide: "len1","nali","id1",("seq","ctres")
#                               alis:  ("id2","ctali"), ("seq","ctali","ctres")
#--------------------------------------------------------------------------------
				# settings
    $fhin="FHIN_HSSP";
    $#excl=$#incl=$nali=$len1=$Lincl_id=0;
    $beg_ali=51;		# means the alignment sequences start at position
				# 52 of the HSSP file
    $pos_guide_seq=15;		# position of guide sequence in HSSP file

				# ----------------------------------------
				# read file
    &open_file("$fhin","$file_hssp");
				# --------------------
				# header
    while (<$fhin>) { if   (/^NALIGN/)   {$_=~s/NALIGN|\s//g;$rd{"nali"}=$nali=$_;}
		      elsif(/^SEQLENGTH/){$_=~s/^SEQLENGTH|\s//g;$rd{"len1"}=$len1=$_;}
		      elsif(/^PDBID/)    {$_=~s/^PDBID|\s//g;$rd{"id1"}=$_;}
		      last if (/^\#\#/); }
				# get range
    if ($incl_txt!~/unk/){
				# is PDBid
	if($incl_txt!~/-/){$incl_id=$incl_txt;$incl_id=~s/\s|\n//g;$Lincl_id=1;}
	else {             @incl=&get_range($incl_txt,$nali);} } else {$#incl=0;}
    if ($excl_txt!~/unk/){ @excl=&get_range($excl_txt,$nali);} else {$#excl=0;}
				# --------------------
				# store list
    while (<$fhin>) { last if (/^\#\#/); 
		      if (! /^\s*\d/) {next;}
		      $tmp=substr($_,1,27);
		      $tmp=~s/^\s*|\s*$|://g; # purge leading or ending blanks or ':'
		      @tmp=split(/ +/,$tmp);
		      if ($#tmp>2) {$rd{"swiss2","$tmp[1]"}=$tmp[2];
				    $rd{"id2","$tmp[1]"}=$tmp[3];}
		      else         {$rd{"id2","$tmp[1]"}=$tmp[2];} }
				# --------------------
				# search for id
    if ($Lincl_id) {  $Lok=0;$#excl=0;
		      foreach$ctres(1..$nali){
			  if($incl_id eq $rd{"id2","$ctres"}){@incl=("$ctres");$Lok=1;last;}}
		      if (!$Lok){print"*** ERROR in $script_name: want to extract '$incl_id'\n";
				 print"*** but not in list:\n";
				 foreach$ctres(1..$nali){print $rd{"id2","$ctres"},",";}
				 print"\n";exit;}}
				# --------------------
				# now alis
    $pos_1st=1;$ctres=$#take=0;
				# take the first?
    @take_one=&hssp_take_range($pos_1st); push(@take,@take_one); 
    while (<$fhin>) { 
	last if (/^\#\# SEQUENCE/);
	if (/^\#\#\s*ALIGNMENTS/) {	# get range of alis (e.g. 71-140)
	    $_=~s/^\#\#\s*ALIGNMENTS\s*|\s//g;	# purge blanks and description
	    $_=~s/(\d+)-(\d+)/$1/g; # extract first number (e.g. 71)
	    $pos_1st=$_;$ctres=0;
				# take it?
	    @take_one=&hssp_take_range($pos_1st);
	    push(@take,@take_one); } 
	elsif ( (!/^ SeqNo/) && (/^\s*\d+/) ) {
	    ++$ctres;
				# first time: get sequence of guide
	    if ($pos_1st==1) { $rd{"seq","$ctres"}=substr($_,$pos_guide_seq,1);}
	    
	    foreach $take(@take_one){
		$tmp=substr($_,($beg_ali+$take-$pos_1st+1),1);
				# rename insertions?
		if ( (length($tmp)==0)||($tmp eq " ")||($tmp eq ".") ) {$tmp=$symbol_ins;}
		$rd{"seq","$take","$ctres"}=$tmp;
	    } }
    }
    close($fhin);
}				# end of hssp_rd_seq

#==========================================================================================
sub hssp_take_range {
    local ($pos_1st) = @_ ;
    local ($Ltake_it,$it,$incl,$excl,@take);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    hssp_take_range                       
#         returns the positions of alis to be taken (for range 71-140, if pos
#         100-105 to be taken, return= 100-105
#         Take it only if @incl finds any position in current ali range (e.g. 71-140)
#         or if @excl has not all positions 71-140
#    GLOBAL in:                 @excl,@incl
#--------------------------------------------------------------------------------
    $#take=0;
				# loop over all positions
    for($it=$pos_1st;$it<=($pos_1st+69);++$it){
	$Ltake_it=1;
	if ($#excl>0) {		# check only if more than 70 have to be excluded
	    foreach$excl(@excl){if($excl==$it){$Ltake_it=0;last;}}}
	if (($#incl>0) && $Ltake_it) {
	    $Ltake_it=0;
	    foreach$incl(@incl){if($incl==$it){$Ltake_it=1;last;}}} 
	if ($Ltake_it) { 
	    push(@take,$it); }}
    return (@take);
}				# end of hssp_take_range

#==========================================================================================
sub pir_wrt {
    local ($fh,$name,$seq) = @_ ;
#--------------------------------------------------------------------------------
#    pir_wrt                       
#         writes a file in PIR format
#       in:
#         $des                  description of protein
#         $seq                  sequence
#--------------------------------------------------------------------------------
    print "x.x entering pir with fh=$fh, seq=$seq,\n";
    print $fh "\>P1\;\n";
    print $fh "$name\n";
    for($it=1;$it<=length($seq);$it+=80){
	print $fh substr($seq,$it,80),"\n";
    }
}				# end of pir_wrt

#==========================================================================================
sub wrt_files {
    local ($fhout,$title_out,$mode_out,$Lscreen,@take) = @_ ;
    local ($tmp_des,$tmp_seq,$file_out,@file_out,@fh,$fh,$ctres,$pos);
#--------------------------------------------------------------------------------
#    wrt_files                       
#         writes a file in PIR format
#       GLOBAL in:              $rd{} 
#--------------------------------------------------------------------------------
    $#file_out=0;
    @fh=($fhout); if ($Lscreen) { push(@fh,"STDOUT"); }
				# ------------------------------
				# guide sequence
    $tmp_des=$rd{"id1"};	# convert guide sequence into variables
    $tmp_seq="";foreach$ctres(1..$rd{"len1"}){$tmp_seq.=$rd{"seq","$ctres"};}
				# lower caps into Cys
    $tmp_seq=~tr/[a-z]/C/;
				# construct output file name
    if($mode_out eq "id"){$id="guide";$id=~s/\s//g;$file_out="$title_out"."_$id".".pir";}
    else { 
	if(defined $fileOut){$file_out=$fileOut;}else{$file_out="$title_out"."_0.pir";}}
    push(@file_out,$file_out);
				# write guide sequence
    foreach $fh(@fh){if($fh eq $fhout){&open_file("$fhout",">$file_out");}
		     else {     print "--- write guide into \t $file_out\n";}
		     &pir_wrt($fh,$tmp_des,$tmp_seq);if ($fh eq $fhout) {close($fhout);}}

				# ------------------------------
    foreach $pos (@take) {	# write all alis
				# convert from associative array
	$tmp_des=$rd{"id2","$pos"};
	$tmp_seq="";foreach$ctres(1..$rd{"len1"}){$tmp_seq.=$rd{"seq","$pos","$ctres"};}
				# lower case into upper case
	$tmp_seq=~tr/[a-z]/[A-Z]/;
				# construct output file name
	if($mode_out eq "id"){$id=$rd{"id2","$pos"};$id=~s/\s//g;
			      $file_out="$title_out"."_$id".".pir";}
	else { $file_out="$title_out"."_$pos".".pir";} push(@file_out,$file_out);
				# write aligned sequence
	foreach $fh(@fh){if($fh eq $fhout){&open_file("$fhout",">$file_out");}
			 else { print "--- write no '$pos' into \t $file_out\n";}
			 &pir_wrt($fh,$tmp_des,$tmp_seq);if($fh eq $fhout){close($fhout);}}
    }
    return (@file_out);
}				# end of wrt_files
