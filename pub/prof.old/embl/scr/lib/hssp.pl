#!/usr/bin/perl
##! /usr/bin/perl -w
##! /usr/sbin/perl -w
##! /usr/pub/bin/perl -w
#------------------------------------------------------------------------------#
#	Copyright				Sep,    	1998	       #
#	Burkhard Rost		rost@LION-ag.de,rost@EMBL-heidelberg.de	       #
#	Wilckensstr. 15		http://www.embl-heidelberg.de/~rost/	       #
#	D-69120 Heidelberg						       #
#				version 0.1   	Sep,    	1998	       #
#------------------------------------------------------------------------------#
#                                                                              #
# description:                                                                 #
#    PERL library with routines related to handling HSSP files.                #
#    See also: prot.pl | formats.pl | files.pl | molbio.pl                     #
#                                                                              #
#------------------------------------------------------------------------------#
# 
# -----------------------------------------------------------------------------# 
#                               ---------------------
#   hssp                        internal subroutines:
#                               ---------------------
# 
#   hssp_fil_num2txt            translates a number for percentage sequence iden-
#   hssp_rd_header              reads the header of an HSSP file for numbers 1..$#num
#   hssp_rd_strip_one           reads the alignment for one sequence from a (new) strip file
#   hssp_rd_strip_one_correct1  correct for begin and ends
#   hssp_rd_strip_one_correct2  shorten indels for begin and ends
#   hsspChopProf                chops profiles from HSSP file
#   hsspCorrectNaliMistake      corrects mistake in NALIGN (is N+1 should be N)
#   hsspfile_to_pdbid           extracts id from hssp file
#   hsspFilterGetPosExcl        flags positions (in pairs) to exclude
#   hsspFilterGetPosIncl        flags positions (in pairs) to include
#   hsspFilterGetCurveIde       flags positions (in pairs) above identity threshold
#   hsspFilterGetCurveMinMaxIde flags positions (in pairs) above maxIde and below minIde
#   hsspFilterGetCurveOld       flags positions (in pairs) above old identity threshold
#   hsspFilterGetCurveSim       flags positions (in pairs) above similarity threshold
#   hsspFilterGetCurveMinMaxSim flags positions (in pairs) above maxSim and below minSim
#   hsspFilterGetRuleBoth       flags all positions (in pairs) with:
#   hsspFilterGetRuleSgi        Sim > Ide, i.e. flags all positions (in pairs) with: 
#   hsspFilterMarkFile          marks the positions specified in command line
#   hsspGetChain                extracts all chain identifiers in HSSP file
#   hsspGetChainBreaks          extracts all chain breaks (if not labelled, or
#   hsspGetChainLength          extracts the length of a chain in an HSSP file
#   hsspGetChainNali            gets Nali for chain X (restricted to HSSP dist D)
#   hsspGetFile                 searches all directories for existing HSSP file
#   hsspGetFileLoop             loops over all directories
#   hsspRdAli                   reads and writes the sequence of HSSP + 70 alis
#   hsspRdHeader                reads a HSSP header
#   hsspRdHeader4topits         extracts the summary from HSSP header (for TOPITS)
#   hsspRdProfile               reads the HSSP profile from ifir to ilas
#   hsspRdSeqSecAcc             reads the HSSP seq/sec/acc from ifir to ilas
#   hsspRdSeqSecAccOneLine      reads begin of one HSSP line
#   hsspRdStrip4topits          reads the new strip file for PP
#   hsspRdStripAndHeader        reads the headers for HSSP and STRIP and merges them
#   hsspRdStripHeader           reads the header of a HSSP.strip file
#   hsspSkewProf                changes the HSSP profile for too few alignments
#   extract_pdbid_from_hssp     extracts all PDB ids found in the HSSP 0 header
#   get_hssp_file               searches all directories for existing HSSP file
#   pdbid_to_hsspfile           finds HSSP file for given id (old)
#   read_hssp_seqsecacc         reads sequence, secondary str and acc from HSSP file
# 
# -----------------------------------------------------------------------------# 
#                               ---------------------
#   hssp                        external subroutines:
#                               ---------------------
# 
#   call from file:             is_hssp,is_hssp_empty,open_file
# 
#   call from hssp:             get_hssp_file,hsspGetChainLength,hsspGetChainNali,hsspGetFileLoop
#                               hsspRdHeader,hsspRdSeqSecAccOneLine,hsspRdStripHeader
#                               hssp_rd_strip_one_correct1
# 
#   call from prot:             funcAddMatdb2prof,getDistanceNewCurveIde,getDistanceNewCurveSim
#                               is_chain,is_pdbid,metricRdbRd,secstr_convert_dsspto3
# 
#   call from scr:              errSbr,errSbrMsg,get_range,get_rangeHyphen
# 
#   call from sys:              complete_dir,sysCpfile
# 
# -----------------------------------------------------------------------------# 
# 
# 
#===============================================================================
sub hssp_fil_num2txt {
    local ($perc_ide) = @_ ;
    local ($txt,$tmp);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   hssp_fil_num2txt            translates a number for percentage sequence iden-
#                               tity into the input argument for MaxHom, e.g.,
#                               30% => 'FORMULA+5'
#       in:                     $perc_ide
#       out:                    $txt ("FORMULA+/-n")
#--------------------------------------------------------------------------------
    $txt="0";
    if    ($perc_ide>25) {
	$tmp=$perc_ide-25;
	$txt="FORMULA+"."$tmp"." "; }
    elsif ($perc_ide<25) {
	$tmp=25-$perc_ide;
	$txt="FORMULA-"."$tmp"." "; }
    else {
	$txt="FORMULA "; }
    return($txt);
}				# end of hssp_fil_num2txt

#===============================================================================
sub hssp_rd_header {
    local ($file_hssp,@num) = @_ ;
    local (@des1,@des2,%ptr,$ptr,$len_strid,$Lis_long_id,$fhin,$Lget_all,
	   %rdLoc,@tmp,$tmp,$beg,$mid,$end,$ct,$id,$strid,$des,$num,$Lok);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   hssp_rd_header              reads the header of an HSSP file for numbers 1..$#num
#       in:                     $file_hssp,@num  (numbers to read)
#       out:                    $rdLoc{} (0 for error)
#--------------------------------------------------------------------------------
				# defaults
    $fhin="FHIN_HSSP_HEADER";
    if ($#num==0){
	$Lget_all=1;}
    else {
	$Lget_all=1;}

    @des1=   ("IDE","WSIM","IFIR","ILAS","JFIR","JLAS","LALI","NGAP","LGAP","LEN2","ACCNUM");
    @des2=   ("STRID");
#    @des3=   ("LEN1");
				# note STRID, ID, NAME automatic
    $ptr{"IDE"}=1;$ptr{"WSIM"}=2;
    $ptr{"IFIR"}=3;$ptr{"ILAS"}=4;$ptr{"JFIR"}=5;$ptr{"JLAS"}=6;
    $ptr{"LALI"}=7;$ptr{"NGAP"}=8;$ptr{"LGAP"}=9;$ptr{"LEN2"}=10; $ptr{"ACCNUM"}=11;

    $len_strid=    4;		# minimal length to identify PDB identifiers

    if ( ! -e $file_hssp) {	# check existence
	return(0); }
				# ini
    $Lis_long_id=0;
				# read file
    &open_file("$fhin", "$file_hssp");
    while ( <$fhin> ) {		# is it HSSP file?
	if (! /^HSSP /) {
	    return(0); } 
	last; }
    while ( <$fhin> ) {		# length, lond-id
	last if (/^\#\# PROTEINS/); 
	if (/^PARAMETER  LONG-ID :YES/) {$Lis_long_id=1;}
	elsif (/^SEQLENGTH /) {$_=~s/\n|\s|SEQLENGTH//g;
			       $rdLoc{"LEN1"}=$_;
			       $rdLoc{"len1"}=$_; } }
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
	$rdLoc{"$ct","ID"}=$id;
	$rdLoc{"$ct","STRID"}=$strid;
	$rdLoc{"$ct","NAME"}=$end;
	++$ct_taken;
				# middle all info
	$#tmp=0;@tmp=split(/\s+/,$mid);
	foreach $_ (@tmp) {$_=~s/\s//g;}
	foreach $des (@des1){ 
	    if ( ! defined $ptr{"$des"}) {
		next; }
	    $ptr=$ptr{"$des"};
	    $rdLoc{"$ct","$des"}=$tmp[$ptr]; }
    }
    close($fhin);
    $rdLoc{"NROWS"}=$ct_taken;
    return(%rdLoc);
}				# end of hssp_rd_header

#===============================================================================
sub hssp_rd_strip_one {
    local ($fileInLoc,$pos_in,$Lscreen) = @_ ;
    local ($fhin,@des,$des,$Lok,@tmp,$tmp,$ct,$ct_guide,$ct_aligned,
	   $Ltake_it,$Lguide,$Laligned,$Lis_ali,$it,$id2,$seq2);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   hssp_rd_strip_one           reads the alignment for one sequence from a (new) strip file
#       in:                     $file, $position_of_protein_to_be_read, $Lscreen
#       out:                    %rd (returned)
#       out:                    $rd{"seq1"},$rd{"seq2"},$rd{"sec1"},$rd{"sec2"},
#       out:                    $rd{"id1"},$rd{"id2"},
#--------------------------------------------------------------------------------
				# settings
    $Lscreen=0 if (!defined $Lscreen);
    $fhin="FHIN_HSSP_RD_STRIP_ONE";

    @des=("seq1","seq2","sec1","sec2");
    foreach $des(@des){		# initialise
	$rdLoc{"$des"}="";}
    if (!-e $fileInLoc){
	print "*** ERROR hssp_rd_strip_one (lib-br): '$fileInLoc' strip file missing\n";
	exit;}
#    if (&is_strip_old($fileInLoc)){
#	print "*** ERROR hssp_rd_strip_one (lib-br): only with new strip format\n";
#	exit;}

    if ($pos_in=~/\D/){		# if PDBid given, search for position
	&open_file("$fhin","$fileInLoc");
	while(<$fhin>){last if (/=== ALIGNMENTS ===/); }
	while(<$fhin>){if (/$pos_in/){$tmp=$_;$tmp=~s/\n//g;
				      $tmp=~s/^\s+(\d+)\.\s+.+/$1/g;
				      $pos_in=$tmp;
				      last;}}
	close($fhin);}
    &open_file("$fhin","$fileInLoc");
				# header
    while (<$fhin>) {
	last if (/=== ALIGNMENTS ===/);}
				# ----------------------------------------
				# loop over all parts of the alignments
    $Lok=0;$#tmp=$ct=$ct_guide=$ct_aligned=0;$Ltake_it=$Lguide=$Laligned=0;
    while (<$fhin>) {
	next if (length($_)<2);	# ignore blank lines
	if (/=== ALIGNMENTS ===/ ){ # until next line with       "=== ALIGNMENTS ==="
	    &hssp_rd_strip_one_correct1; # correction for different beginning
	    $ct_guide=0;$Lis_ali=1;}
	elsif (/=======/){	# prepare end
	    &hssp_rd_strip_one_correct1; # correction for different beginning
	    last;}
	elsif ( /^\s*\d+ -\s+\d+ / ){ # first line for alis x-(x+100), i.e. guide
	    $Lguide=1;$Ltake_it=1;}
	elsif ( $Ltake_it && $Lguide) { # read five lines
	    ++$ct_guide; 
	    if ($ct_guide==1){	# guide sequence
		$tmp2=$_;
		$_=~s/^\s+(\S+)\s+(\S+)\s*.*\n?/$2/;
		$rdLoc{"id1"}=$1;
		$tmp=substr($tmp2,26,100);$tmp=~s/\n//g;
		$rdLoc{"seq1"}.=$tmp;}
	    elsif ($ct_guide==2){ # guide sec str
		$tmp=substr($_,26,100);$tmp=~s/\n//g;
		$tmp=~s/ /L/g;	# blank to loop
		$rdLoc{"sec1"}.=$tmp;}
	    elsif ($ct_guide>=4){
		$Lguide=0;$ct_guide=0;} }
	elsif ( /^\s*\d+\. /) { # aligned sequence: first line
	    $_=~s/\n//g;
	    $tmp2=$_;
	    $_=~s/^\s*|\s*$//g;	# purging leading blanks
	    $#tmp=0; @tmp=split(/\s+/,$_);
	    $it=  $tmp[1];$it=~s/\.//g;
	    $id2= $tmp[2];
	    $seq2=$tmp[4];
	    if ($it==$pos_in) {
		$Ltake_it=1; $Laligned=$Lok=1;
		$rdLoc{"id2"}=$id2;
		$tmp=substr($tmp2,26,100);$tmp=~s/\n//g;$tmp=~s/ /./g;
		$rdLoc{"seq2"}.=$tmp;} }
	elsif ( $Ltake_it && $Laligned) { # aligned sequence: other lines
	    $tmp=substr($_,26,100);$tmp=~s/\n//g;$tmp=~s/ /\./g;
	    $rdLoc{"sec2"}.=$tmp;
	    $Laligned=0;$ct_aligned=0;}
    }
    close($fhin);
#    &hssp_rd_strip_one_correct2;
				# ------------------------------
				# write onto screen?
    if ($Lscreen) { print"--- lib-br.pl:hssp_rd_strip_one \t read in from '$fileInLoc'\n";
		    foreach $des(@des){
			print "$des:",$rdLoc{"$des"},"\n";}}
    return (%rdLoc);
}				# end of hssp_rd_strip_one 

#===============================================================================
sub hssp_rd_strip_one_correct1 {
#-------------------------------------------------------------------------------
#   hssp_rd_strip_one_correct1  correct for begin and ends
#-------------------------------------------------------------------------------
    $diff=(length($rdLoc{"seq1"})-length($rdLoc{"seq2"}));
    if ($diff!=0){
	foreach $it (1..$diff){
	    $rdLoc{"seq2"}.=".";$rdLoc{"sec2"}.="."; }}
}				# end of hssp_rd_strip_one_correct1

#===============================================================================
sub hssp_rd_strip_one_correct2 {
#-------------------------------------------------------------------------------
#   hssp_rd_strip_one_correct2  shorten indels for begin and ends
#-------------------------------------------------------------------------------
    $tmp=$rdLoc{"seq2"};$tmp=~s/^\.*//; # N-term insertions
    $diff=(length($rdLoc{"seq2"})-length($tmp));
    if ($diff!=0){
	foreach $des(@des){ $tmp=substr($rdLoc{"$des"},($diff+1),length($tmp)); 
			    $rdLoc{"$des"}=$tmp; }}
    $tmp=$rdLoc{"seq2"};$tmp=~s/\.*$//; # C-term insertions
    $diff=(length($rdLoc{"seq2"})-length($tmp));
    if ($diff!=0){
	foreach $des(@des){ $tmp=substr($rdLoc{"$des"},1,length($tmp));
			    $rdLoc{"$des"}=$tmp;}}
}				# end of hssp_rd_strip_one_correct2
 
#===============================================================================
sub hsspChopProf {
    local($fileIn,$fileOut)=@_;
    local($sbr);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspChopProf                chops profiles from HSSP file
#       in:                     $fileIn,$fileOut
#       out:                    
#       err:                    ok=(1,'ok','blabla'), err=(0,errNumber,'msg')
#-------------------------------------------------------------------------------
    $sbr="lib-br:hsspChopProf";
    return(0,"*** $sbr: not def fileIn!")    if (! defined $fileIn);
    return(0,"*** $sbr: not def fileOut!")   if (! defined $fileOut);
    return(0,"*** $sbr: miss file=$fileIn!") if (! -e $fileIn);
#   --------------------------------------------------
#   open files
#   --------------------------------------------------
    open(FILEIN,$fileIn)  || 
	return(0,"*** $sbr: failed to open in=$fileIn");
    open(FILEOUT,"> $fileOut")  || 
	return(0,"*** $sbr: failed to open out=$fileOut");

#   --------------------------------------------------
#   write everything before "## SEQUENCE PROFILE"
#   --------------------------------------------------
    while( <FILEIN> ) {
	last if ( /^\#\# SEQUENCE PROFILE/ );
	print FILEOUT "$_"; }
    print FILEOUT "--- \n","--- Here, in HSSP files usually the profiles are listed. \n";
    print FILEOUT "--- We decided to chop these off in order to spare bytes. \n","--- \n";
    while( <FILEIN> ) {
	print FILEOUT "$_ "; 
				# changed br 20-02-97 (keep insertions)
#	last if ( /^\#\# INSERTION/ ); 
    }
    while( <FILEIN> ) {
	print FILEOUT "$_ "; }
    print FILEOUT "\n";
    close(FILEIN);close(FILEOUT);
    return(1,"ok $sbr: wrote $fileOut");
}				# end of hsspChopProf

#===============================================================================
sub hsspCorrectNaliMistake {
    local($fileInLoc,$filetmp) = @_ ;
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspCorrectNaliMistake      corrects mistake in NALIGN (is N+1 should be N)
#                               
#                               ==============================
#                         NOTE: overrides input file!
#                               ==============================
#                               
#       in:                     $fileInLoc: HSSP file
#       in:                     $filetmp:   temporary file
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."hsspCorrectNaliMistake";
    $fhinLoc="FHIN_"."hsspCorrectNaliMistake";$fhoutLoc="FHOUT_"."hsspCorrectNaliMistake";
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
    $filetmp="TMP_CORRECT_HSSP_".$$.".tmp"         if (! defined $filetmp);
#    return(&errSbr("not def !"))          if (! defined $);

    return(&errSbr("no fileIn=$fileInLoc!"))  if (! -e $fileInLoc);

				# ------------------------------
				# (1) check whether wrong or not
				# ------------------------------
    open($fhinLoc,$fileInLoc) || return(&errSbr("fileInLoc=$fileInLoc, not opened"));
    while (<$fhinLoc>) {	# read file
	last if ($_=~/^\#\# ALIGN/);
	if ($_=~/^NALIGN\s+(\d+)/){
	    $nalign=$1;
	    next; }
	$tmp=$_;
    }
    close($fhinLoc);
    $tmp=~s/^\s*(\d+) .*$/$1/;
    $nalign_actual=$tmp;
				# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
				# NOTHING to do, IS fine!
    return(1,"no action") 
	if ($nalign_actual == $nalign);
				# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

    print "--- $sbrName: IS mistake in HSSP=$fileInLoc hdr=$nalign, really $nalign_actual\n"
	if (defined $par{"debug"} && $par{"debug"});
				# ------------------------------
				# (2) CORRECT mistake
				# ------------------------------
    open($fhinLoc,$fileInLoc)    || return(&errSbr("fileInLoc=$fileInLoc, not opened"));
    open($fhoutLoc,">".$filetmp) || return(&errSbr("fileOutLoc=$filetmp, not created"));
    while (<$fhinLoc>) {	# BEFORE event
	if ($_=~/^NALIGN\s+(\d+)/){
	    $nalign=$1;
	    $tmp=sprintf("NALIGN %8d\n",
			 $nalign_actual);
	    print $fhoutLoc $tmp;
	    last; }
	print $fhoutLoc $_; }
    while (<$fhinLoc>) {	# AFTER event
	print $fhoutLoc $_; }
    close($fhinLoc);
    close($fhoutLoc);
				# check existence of file
    return(&errSbr("missing output file=$filetmp!"))
	if (! -e $filetmp);
				# move old to new

    $cmd="\\mv $filetmp $fileInLoc";
    system($cmd);
    print "--- $sbrName: system '$cmd'\n"
	if ((defined $par{"debug"}   && $par{"debug"}) ||
	    (defined $par{"verbose"} && $par{"verbose"}));
    
    return(2,"ok $sbrName");
}				# end of hsspCorrectNaliMistake

#===============================================================================
sub hsspfile_to_pdbid {
    local ($name_in) = @_; local ($tmp);
#--------------------------------------------------------------------------------
#   hsspfile_to_pdbid           extracts id from hssp file
#--------------------------------------------------------------------------------
    $tmp=  "$name_in";$tmp=~s/\/data\/hssp\///g;$tmp=~s/\.hssp//g;$tmp=~s/\s//g;
    $hsspfile_to_pdbid = $tmp;
}				# end of hsspfile_to_pdbid

#===============================================================================
sub hsspFilterGetPosExcl {
    local($exclTxtLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok,@notLoc,@exclLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspFilterGetPosExcl        flags positions (in pairs) to exclude
#       in:                     e.g. excl=1-5,9,15 
#       out:                    @notLoc
#   GLOBAL in /out:             $rd{"NALIGN"},$rd{"NROWS"},$rd{"NR","$it"}
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."hsspFilterGetPosExcl";
				# text '1-5,7,12' to array (1,2,3,4,5,7,12)
    $#exclLoc=$#notLoc=0;
    if ($exclTxtLoc=~/\*$/){	# replace wild card
	$exclTxtLoc=~s/\*$/$rd{"NALIGN"}/;}
    @exclLoc=&get_range($exclTxtLoc);   # external lib-br.pl
				# all pairs
    foreach $it (1..$rd{"NROWS"}){
	foreach $i (@exclLoc) { 
	    if ($i == $rd{"NR","$it"}) { 
		$notLoc[$it]=1;
		last;}}}
    return(@notLoc);
}				# end of hsspFilterGetPosExcl

#===============================================================================
sub hsspFilterGetPosIncl {
    local($inclTxtLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok,@takeLoc,@inclLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspFilterGetPosIncl        flags positions (in pairs) to include
#       in:                     e.g. incl=1-5,9,15 
#       out:                    @takeLoc
#   GLOBAL in /out:             $rd{"NALIGN"},$rd{"NROWS"},$rd{"NR","$it"}
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."hsspFilterGetPosExIn";
				# text '1-5,7,12' to array (1,2,3,4,5,7,12)
    $#inclLoc=$#takeLoc=0;
    if ($inclTxtLoc=~/\*$/){	# replace wild card
	$inclTxtLoc=~s/\*$/$rd{"NALIGN"}/;}
    @inclLoc=&get_range($inclTxtLoc);  # external lib-br.pl
				# all pairs
    foreach $it (1..$rd{"NROWS"}){
	foreach $i (@inclLoc) { 
	    if ($i == $rd{"NR","$it"}) { 
		$takeLoc[$it]=1;
		last;}}}
    return(@takeLoc);
}				# end of hsspFilterGetPosIncl

#===============================================================================
sub hsspFilterGetCurveIde {
    local($threshLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok,@takeLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspFilterGetCurveIde       flags positions (in pairs) above identity threshold
#       in:                     $threshLoc= distance from HSSP (new ide) threshold
#       out:                    @takeLoc
#   GLOBAL in /out:             $rd{"NR","$it"},$rd{"LALI","$it"}
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."hsspFilterGetCurveIde";
    $#takeLoc=0;
    foreach $it (1..$rd{"NROWS"}){ # loop over all pairs
	$dist=100*$rd{"IDE","$it"} - &getDistanceNewCurveIde($rd{"LALI","$it"});
	if ($dist >= $threshLoc){
	    $takeLoc[$it]=1;}
	else { 
	    $takeLoc[$it]=0;}}
    return(@takeLoc);
}				# end of hsspFilterGetCurveIde

#===============================================================================
sub hsspFilterGetCurveMinMaxIde {
    local($minLoc,$maxLoc,$fhSbr) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok,@notLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspFilterGetCurveMinMaxIde flags positions (in pairs) above maxIde and below minIde
#       in:                     $minLoc,$maxLoc = distances from HSSP (new ide) threshold
#       in:                     $fhSbr: if not defined, no output written
#       out:                    @notLoc
#   GLOBAL in /out:             $rd{"NR","$it"},$rd{"LALI","$it"}
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."hsspFilterGetCurveMinMaxIde";
    $#notLoc=0;
    foreach $it (1..$rd{"NROWS"}){ # loop over all pairs
	$dist=100*$rd{"IDE","$it"} - &getDistanceNewCurveIde($rd{"LALI","$it"});
	if    ($dist > $maxLoc){
	    $notLoc[$it]=1;}
	elsif ($dist < $minLoc){
	    $notLoc[$it]=1;}
	else {
	    printf 
		"--- %3d: %5.2f < %5.2f < %5.2f i=%5.2f (%5d)\n",
		$it,$minLoc,$dist,$maxLoc,(100*$rd{"IDE","$it"}),$rd{"LALI","$it"}
	    if (defined $fhSbr);}
    }
    return(@notLoc);
}				# end of hsspFilterGetCurveMinMaxIde

#==============================================================================
sub hsspFilterGetCurveOld {
    local($threshLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok,@takeLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspFilterGetCurveOld       flags positions (in pairs) above old identity threshold
#       in:                     $threshLoc= distance from HSSP (old ide) threshold
#       out:                    @takeLoc
#   GLOBAL in /out:             $rd{"NR","$it"},$rd{"LALI","$it"}
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."hsspFilterGetCurveOld";
    $LscreenTmp=0;
#    $LscreenTmp=1;

    $#takeLoc=0;
    foreach $it (1..$rd{"NROWS"}){ # loop over all pairs
	($oldIdeThresh,$msg)=
	    &getDistanceOldCurveIde($rd{"LALI","$it"});
	return(&errSbrMsg("failed getDistanceOldCurveIde for it=$it, lali=".
			  $rd{"LALI","$it"}.", ide=".$rd{"IDE","$it"},
			  $msg)) if ($msg !~/^ok/);
	$dist=
	    100 * $rd{"IDE","$it"} - $oldIdeThresh;
	if ($dist >= $threshLoc){
	    printf 
		"TMP: %3d +  d=%5.1f ide=%3d t=%3d\n",
		$it,$dist,int(100*$rd{"IDE","$it"}),int($threshLoc) if ($LscreenTmp);
	    $takeLoc[$it]=1;}
	else { 
	    printf 
		"TMP: %3d  - d=%5.1f ide=%3d t=%3d\n",
		$it,$dist,int(100*$rd{"IDE","$it"}),int($threshLoc) if ($LscreenTmp);
	    $takeLoc[$it]=0;}
    }
    return(@takeLoc);
}				# end of hsspFilterGetCurveOld

#===============================================================================
sub hsspFilterGetCurveSim {
    local($threshLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok,@takeLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspFilterGetCurveSim       flags positions (in pairs) above similarity threshold
#       in:                     $threshLoc= distance from HSSP (new sim) threshold
#       out:                    @take
#   GLOBAL in /out:             @take,$rd{"NR","$it"}
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."hsspFilterGetCurveSim";
    $#takeLoc=0;
    foreach $it (1..$rd{"NROWS"}){ # loop over all pairs
	$dist=100*$rd{"WSIM","$it"} - &getDistanceNewCurveSim($rd{"LALI","$it"});
	if ($dist >= $threshLoc){
	    $takeLoc[$it]=1;}
	else { 
	    $takeLoc[$it]=0;}}
    return(@takeLoc);
}				# end of hsspFilterGetCurveSim

#===============================================================================
sub hsspFilterGetCurveMinMaxSim {
    local($minLoc,$maxLoc,$fhSbr) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok,@notLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspFilterGetCurveMinMaxSim flags positions (in pairs) above maxSim and below minSim
#       in:                     $minLoc,$maxLoc = distances from HSSP (new sim) threshold
#       in:                     $fhSbr: if not defined, no output written
#       out:                    @notLoc
#   GLOBAL in /out:             $rd{"NR","$it"}
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."hsspFilterGetCurveMinMaxSim";
    $#notLoc=0;
    foreach $it (1..$rd{"NROWS"}){ # loop over all pairs
	$dist=100*$rd{"WSIM","$it"} - &getDistanceNewCurveSim($rd{"LALI","$it"});
	if    ($dist > $maxLoc){
	    $notLoc[$it]=1;}
	elsif ($dist < $minLoc){
	    $notLoc[$it]=1;}
	else {
	    printf 
                "--- %3d: %5.2f < %5.2f < %5.2f i=%5.2f (%5d)\n",
                $it,$minLoc,$dist,$maxLoc,(100*$rd{"WSIM","$it"}),$rd{"LALI","$it"}
	    if (defined $fhSbr);}
    }
    return(@notLoc);
}				# end of hsspFilterGetCurveMinMaxSim

#===============================================================================
sub hsspFilterGetRuleBoth {
    local($threshLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok,@notLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspFilterGetRuleBoth       flags all positions (in pairs) with:
#                               ide > thresh, and  similarity > thresh
#       in:                     $threshLoc= distance from HSSP (new ide) threshold
#       out:                    @notLoc
#   GLOBAL in /out:             $rd{"NR","$it"},$rd{"LALI","$it"},$rd{"IDE","$it"},$rd{"WSIM","$it"}
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."hsspFilterGetRuleBoth";
    $threshLoc="-100" if (! defined $threshLoc);

    $#okLoc=0;
    foreach $it (1..$rd{"NROWS"}){ # loop over all pairs
	if ($threshLoc > -100){
	    $distSim=100*$rd{"WSIM","$it"} - 
		&getDistanceNewCurveSim($rd{"LALI","$it"}); # external lib-br
	    next if ($distSim < $threshLoc);
	    $distIde=100*$rd{"IDE","$it"}  - 
		&getDistanceNewCurveIde($rd{"LALI","$it"});	# external lib-br
	    next if ($distIde < $threshLoc);}
	push(@okLoc,$it);}
    return(@okLoc);
}				# end of hsspFilterGetRuleBoth

#===============================================================================
sub hsspFilterGetRuleSgi {
    local($threshLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok,@okLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspFilterGetRuleSgi        Sim > Ide, i.e. flags all positions (in pairs) with: 
#                                  sim > ide, and both above thresh (optional)
#       in:                     $threshLoc distance from HSSP (new) threshold (optional),
#       in:                     if not defined thresh -> take all
#       out:                    @okLoc
#   GLOBAL in /out:             $rd{"NR","$it"},$rd{"LALI","$it"},$rd{"IDE","$it"},$rd{"WSIM","$it"}
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."hsspFilterGetRuleBoth";
    $threshLoc="-100" if (! defined $threshLoc);

    $#okLoc=0;
    foreach $it (1..$rd{"NROWS"}){ # loop over all pairs
	$simLoc=$rd{"WSIM","$it"};$ideLoc=$rd{"IDE","$it"};
	next if ($simLoc < $ideLoc);
	if ($threshLoc > -100){ # threshold given
	    $distSim=100*$rd{"WSIM","$it"} - 
		&getDistanceNewCurveSim($rd{"LALI","$it"}); # external lib-br
	    next if ($distSim < $threshLoc);
	    $distIde=100*$rd{"IDE","$it"}  - 
		&getDistanceNewCurveIde($rd{"LALI","$it"});	# external lib-br
	    next if ($distIde < $threshLoc);}
	push(@okLoc,$it);}
    return(@okLoc);
}				# end of hsspFilterGetRuleSgi

#===============================================================================
sub hsspFilterMarkFile {
    local($fileInLoc,$fileOutLoc,@takeLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspFilterMarkFile          marks the positions specified in command line
#       in:                     $fileIn,$fileOut,@num = number to mark
#       out:                    implicit: fileMarked
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."hsspFilterMarkFile";$fhinLoc="FHIN_"."$sbrName";$fhoutLoc="FHOUT_"."$sbrName";
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc!")          if (! defined $fileInLoc);
    return(0,"*** $sbrName: not def fileOutLoc!")         if (! defined $fileOutLoc);
    return(0,"*** $sbrName: not def \@takeLoc!")          if (! defined @takeLoc || $#takeLoc<1);
    return(0,"*** $sbrName: miss in file '$fileInLoc'!")  if (! -e $fileInLoc);
				# open files
    &open_file("$fhinLoc","$fileInLoc") ||
	return(0,"*** ERROR $sbrName: in=$fileInLoc not opened\n");
    &open_file("$fhoutLoc", ">$fileOutLoc") ||
	return(0,"*** ERROR $sbrName: out=$fileOutLoc not opened\n");
				# ------------------------------
    while ( <$fhinLoc> ) {	# read/write HSSP header
	$tmp=$_;
	print $fhoutLoc $tmp;
	last if (/^  NR\./); }	# last when header info start
    $ct=0;			# ------------------------------
    while ( <$fhinLoc> ) {	# read/write each pair (header)
	$tmp=$_;$tmp=~s/\n//g; $tmpx=$tmp;$tmpx=~s/\s//g;
	$line=$_;
	next if ( length($tmpx)==0 );
	if (/^\#\#/) { 
	    print $fhoutLoc $line; 
	    last;}		# now alignments start 
	++$ct;
	$tmppos=substr($tmp,1,7);	# get first 7 characters of line
	$tmprest=$tmp;$tmprest=~s/$tmppos//g; # extract rest
	$pos=$tmppos;$pos=~s/\s|\://g;

	if    (defined $takeLoc[$ct] && $takeLoc[$ct]) { 
	    print $fhoutLoc $line;}
	elsif (defined $takeLoc[$ct] &&! $takeLoc[$ct]) { 
	    $tmppos=~s/ \:/\*\:/g; 
	    print $fhoutLoc "$tmppos","$tmprest\n"; }
	else { print "*** ERROR for ct=$ct, $tmppos","$tmprest\n"; }}
				# ------------------------------
    while ( <$fhinLoc> ) {	# read/write remaining file (alis asf)
        print $fhoutLoc $_;}
    close($fhinLoc);close($fhoutLoc);
    return(1,"ok $sbrName");
}				# end of hsspFilterMarkFile

#===============================================================================
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
    return(0,"*** missing fileHssp=$fileIn!") if (! -e $fileIn);
    open($fhin,$fileIn) || return(0,"*** failed opening hssp=$fileIn!\n");
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
	$rdLoc{$ctLoc,"chain"}=$cLoc[$itLoc];
	$rdLoc{$ctLoc,"ifir"}= $tmp1;
	$rdLoc{$ctLoc,"ilas"}= $tmp2;}
    $chainLoc=~s/,//g;
    return($chainLoc,%rdLoc);
}				# end of hsspGetChain

#===============================================================================
sub hsspGetChainBreaks {
    local ($fileInLoc) = @_ ;
    local ($fhinLoc,$ifirLoc,$ilasLoc,$tmp1,$tmp2,
	   $chainLoc,$posLoc,$posRd,$chainRd,@cLoc,@pLoc);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   hsspGetChainBreaks          extracts all chain breaks (if not labelled, or
#                               if within labelled chain: _a-z added to chain,
#                               e.g. 1a0i_abc, or 1cse_E_ab
#       in:                     $file
#       out:                    1|0,msg,$tmp{}
#       out:                       $tmp{"NROWS"}=        number of chains
#                                  $tmp{"chains"}=       $chains (a,b,Ea,Eb,c,d,Ia..) ,
#                                  $tmp{"chain","$ct"}   chain $ct
#                                  $tmp{"ifir","$ct"}    first residue for chain $ct
#                                  $tmp{"ilas","$ct"}    last for chain $ct
#       err:                    1|0, error message
#--------------------------------------------------------------------------------
    $sbrName="lib-br::hsspGetChainBreaks"; $fhinLoc="FHIN_hsspGetChainBreaks";
				# ------------------------------
				# checck existenc
    return(0,"no file ($fileInLoc)",0,0) if (! -e $fileInLoc);
				# ------------------------------
				# open file
    &open_file("$fhinLoc","$fileIn") || return(&errSbr("failed opening old=$fileInLoc,"));

				# ------------------------------
    while (<$fhinLoc>){		# until start of data
	last if ($_=~/^ SeqNo/);}

    $#chainLoc=$#ifirLoc=$#ilasLoc=0;
    $beg=$end=$chain=0;
				# ------------------------------
    while (<$fhinLoc>){		# read first sequence-ali section
	last if ($_=~/^\#/);	# fin when ali begins
	$chainRd=substr($_,13,1);
	$aaRd=   substr($_,15,1);
	$posRd=  substr($_,1,6);$posRd=~s/\s//g;
	$beg=$posRd             if (! $beg);
	$chain=$chainRd         if (! $chain);
	$chain="*"              if ($chain eq " ");
				# found a chain break
	if ($aaRd eq "!") {
	    $end=$posRd-1;
	    if (($end-$beg) > 1){ # take only those longer than 1 residue
		push(@chainLoc,$chain);
		push(@ifirLoc,$beg);    push(@ilasLoc,$end); }
	    $beg=$chain=0;	# reset
	}
    } close($fhinLoc);
				# ------------------------------
				# final one
    $end=$posRd;
    push(@chainLoc,$chain);push(@ifirLoc,$beg);push(@ilasLoc,$end); 
    
				# ------------------------------
				# set up new names
    $alphabet="abcdefghijklmnopqrstuvwxyz";
    @alphabet=split(//,$alphabet);
				# ------------------------------
				# process
				# ------------------------------
    undef %tmp; 
    $tmp{"chains"}=""; 
    $ct=0;
    foreach $it (1..$#chainLoc) {
	$chain=$chainLoc[$it];
	$chain.="1";
				# is unique -> add
	if (! defined $tmp{"$chain"}){
	    ++$ct;
	    $tmp{"$chain"}=$ct;               $tmp{"$ct"}=$chain;
	    $tmp{"ifir","$ct"}=$ifirLoc[$it]; $tmp{"ilas","$ct"}=$ilasLoc[$it]; 
	    next; }
				# is not -> add letters
	$ctalpha=1; $Lok=0;
	$chain=~s/(.)\d*/$1/;
	while (! $Lok){		# loop over alphabet
	    ++$ctalpha;
	    if ($ctalpha > 26){return(&errSbr("ctalpha > 26, for it=$it, ".
					      "chain=$chain (file=$fileInLoc)"));}
	    $chain2="$chain"."$ctalpha";
	    next if (defined $tmp{"$chain2"});
				# is new
	    $Lok=1;$chain=$chain2;
	    ++$ct;
	    $tmp{"$chain"}=$ct;               $tmp{"$ct"}=$chain;
	    $tmp{"ifir","$ct"}=$ifirLoc[$it]; $tmp{"ilas","$ct"}=$ilasLoc[$it]; 
	    last; }
    }

    $tmp{"NROWS"}= $ct;
				# ------------------------------
				# only one: fin
    if ($ct == 1){
	$tmp{"1"}=~s/(.)\d*/$1/; # remove number
	$tmp{"chains"}=$tmp{"1"}; 
	return(1,"ok $sbrName",%tmp); }
				# ------------------------------
				# final: remove '*' '1..26' -> 'a-z'
				# ------------------------------
    foreach $it (1..$ct) {
	$num=       substr($tmp{"$it"},2);
	$tmp{"$it"}=substr($tmp{"$it"},1,1).$alphabet[$num];
	$tmp{"chains"}.=$tmp{"$it"}.","; }

    $tmp{"chains"}=~s/,*$//g;

    return(1,"ok $sbrName",%tmp);
}				# end of hsspgetchainbreaks

#===============================================================================
sub hsspGetChainLength {
    local ($fileIn,$chainLoc) = @_ ;
    local ($file_hssp,$ct,$tmp,$beg,$end,$pos);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   hsspGetChainLength          extracts the length of a chain in an HSSP file
#       in:                     hssp_file,chain,
#       out:                    $length,$ifir,$ilas
#--------------------------------------------------------------------------------
    $fileIn=~s/\s//g;$fileIn=~s/\n//g;
    $file_hssp=$fileIn; $Lchain=1; 
    $Lchain=0                   if ($chainLoc eq "*" || ! &is_chain($chainLoc)); 
    if (! -e $file_hssp){
	print "*** ERROR hsspGetChainLength: no HSSP=$fileIn,\n"; 
	return(0,"*** ERROR hsspGetChainLength: no HSSP=$fileIn,");}
    &open_file("FHIN", "$file_hssp") ||
	return(0,"*** ERROR hsspGetChainLength: failed opening HSSP=$fileIn,");

    while ( <FHIN> ) { 
	last if (/^ SeqNo/); }
    $ct=$pos=0;
    while ( <FHIN> ) { 
	last if (/^\#\# /);
	++$pos;$tmp=substr($_,13,1);
	if    ( $Lchain && ($tmp eq $chainLoc) ) { ++$ct; }
	elsif ( ! $Lchain )                      { ++$ct; }
	elsif ( $ct>1 ) {
	    last;}
	$beg=$pos if ($ct==1); } close(FHIN);
    $end=$pos;
    return($ct,$beg,$end);
}				# end of hsspGetChainLength

#===============================================================================
sub hsspGetChainNali {
    local($fileInLoc,$chainInLoc,$distLoc,$distModeLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspGetChainNali            gets Nali for chain X (restricted to HSSP dist D)
#       in:                     $fileInLoc   : HSSP file
#       in:                     $chainInLoc  : chain to read
#                                   '*' for omitting the test
#       in:                     $distLoc     : limiting distance from HSSP (new Ide)
#                                   '0' in NEXT variable for omitting the test
#       in:                     $distModeLoc : mode of limit ('gt|ge|lt|le')
#                                              -> if mode=gt, all with dist>distLoc
#                                                  will be counted
#                                   '0' for omitting the test
#       out:                    1|0,msg,$num,$take:
#                               $take='n,m,..': list of pairs ok
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-nn:"."hsspGetChainNali";$fhinLoc="FHIN_"."hsspGetChainNali";
				# check arguments
    return(&errSbr("not def fileInLoc!"))                if (! defined $fileInLoc);
    return(&errSbr("not def chainInLoc!"))               if (! defined $chainInLoc);
    return(&errSbr("not def distLoc!"))                  if (! defined $distLoc);
    return(&errSbr("not def distModeLoc!"))              if (! defined $distModeLoc);
    return(&errSbr("miss in file '$fileInLoc'!"))        if (! -e $fileInLoc);
    $chainInLoc="*"                                      if (! &is_chain($chainInLoc));
    undef %tmp;
    $errMsg="\n*** ERROR $sbrName local in: f=$fileInLoc,c=$chainInLoc,".
	"dist=$distLoc,mode=$distModeLoc\n";
				# ------------------------------
				# get chain
				# ------------------------------
    if ($chainInLoc ne "*"){
	($len,$ifir,$ilas)=
	    &hsspGetChainLength($fileInLoc,$chainInLoc);
	return(&errSbrMsg("chain=$chainInLoc".$errMsg,$ifir),0,0) if (! $len);
	$ifirChain=$ifir;
	$ilasChain=$ilas; }
    else {
	$ifirChain=0;
	$ilasChain=0; }
				# ------------------------------
				# read HSSP header
				# ------------------------------
    ($Lok,%tmp)=
	&hsspRdHeader($fileInLoc,"IFIR","ILAS","LALI","IDE");
    return(&errSbr("hsspGetChainNali:hsspRdHeader no hdr for $fileInLoc,".$errMsg),0,0) 
	if (! $Lok);
    $take="";
 				# translate
    foreach $it (1..$tmp{"NROWS"}){
				# ------------------------------
				# (1) is it aligned to chain?
	next if ($ifirChain && $ilasChain &&
		 ( ($tmp{"IFIR","$it"} > $ilasChain) || ($tmp{"ILAS","$it"} < $ifirChain) ));
				# ------------------------------
				# (2) is it correct distance?
	if ($distModeLoc){
	    $lali=$tmp{"LALI","$it"}; $pide=100*$tmp{"IDE","$it"};
	    return(&errSbr("pair=$it, no lali|ide ($lali,$pide)".$errMsg),0,0) 
		if (! defined $lali || ! defined $pide);
                                # compile distance to HSSP threshold (new)
	    ($pideCurve,$msg)= 
		&getDistanceNewCurveIde($lali);
	    return(&errSbrMsg("hsspGetChainNali".$errMsg,$msg),0,0)            
		if (! $pideCurve && ($msg !~ /^ok/));
	    
	    $dist=$pide-$pideCurve;
				# mode
	    next if (($distModeLoc eq "gt" && $dist <= $distLoc) ||
		     ($distModeLoc eq "ge" && $dist <  $distLoc) ||
		     ($distModeLoc eq "lt" && $dist >= $distLoc) ||
		     ($distModeLoc eq "le" && $dist >  $distLoc)); }
				# ------------------------------
				# (3) ok, take it
	$take.="$it,"; }

    $take=~s/^,*|,*$//g;
    @tmp=split(/,/,$take);
    $num=$#tmp;

    undef %tmp;			# slim-is-in!
    undef @tmp;			# slim-is-in!

    return(1,"ok $sbrName",$num,$take);
}				# end of hsspGetChainNali

#===============================================================================
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

#===============================================================================
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

#===============================================================================
sub hsspRdAli {
    local ($fileInLoc,@want) = @_ ;
    local ($sbrName,$fhinLoc,$tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspRdAli                   reads and writes the sequence of HSSP + 70 alis
#       in:                     $fileHssp (must exist), 
#         @des                  (1) =1, 2, ...,  i.e. number of sequence to be read
#                               (2) = swiss_id1, swiss_id2, i.e. identifiers to read
#                               (3) = all (or undefined)
#                               NOTE: you can give ids AND numbers ('1','paho_chick','2') ..
#                               
#                               furthermore:
#                               if @want = 'seq|seqAli|seqNoins'
#                                  only those will be returned (e.g. $tmp{"seq","$ct"})
#                               default: all 3!
#       out:                    1|0,$rd{} with: 
#       err:                    (0,$msg)
#                    overall:
#                               $rd{"NROWS"}=          : number of alis, i.e. $#want
#                               
#                               $rd{"NRES"}=N          : number of residues in guide
#                               $rd{"SWISS"}='sw1,sw2' : list of swiss-ids read
#                               $rd{"0"}='pdbid'       : id of guide sequence (in file header)
#                               $rd{"$it"}='sw$ct'     : swiss id of the it-th alignment
#                               $rd{"$id"}='$it'       : position of $id in final list
#                               $rd{"sec","$itres"}    : secondary structure for residue itres
#                               $rd{"acc","$itres"}    : accessibility for residue itres
#                               $rd{"chn","$itres"}    : chain for residue itres
#                    per prot:
#                               $rd{"seqNoins","$ct"}=sequences without insertions
#                               $rd{"seqNoins","0"}=  GUIDE sequence
#                               
#                               $rd{"seq","$ct"}=SEQW  : sequences, with all insertions
#                                                        but NOT aligned!!!
#                               $rd{"seqAli","$ct"}    : sequences, with all insertions,
#                                                        AND aligned (all, including guide
#                                                        filled up with '.' !!
#-------------------------------------------------------------------------------
    $sbrName="lib-br:hsspRdAli"; $fhinLoc="FHIN"."$sbrName"; $fhinLoc=~tr/[a-z]/[A-Z]/;
				# file existing?
    if ((! -e $fileInLoc) || (! &is_hssp($fileInLoc))){
	print "*** ERROR $sbrName no HSSP file '$fileInLoc'\n";
	return(0);}
				# ------------------------------
				# HSSP file format settings
    $regexpBegAli=        "^\#\# ALIGNMENTS"; # begin of reading
    $regexpEndAli=        "^\#\# SEQUENCE PROFILE"; # end of reading
    $regexpSkip=          "^ SeqNo"; # skip lines with pattern
    $nmaxBlocks=          100;	# maximal number of blocks considered (=7000 alis!)
    $regexpBegIns=        "^\#\# INSERTION LIST"; # begin of reading insertion list
    
    undef %tmp; undef @seqNo; undef %seqNo;
				# ------------------------------
				# pointers
    undef %ptr_id2num;		# $ptr{xyz}= N   : id=xyz is the Nth ali
    undef @ptr_num2id;		# $ptr[N]=   xyz : Nth ali has id= xyz
    undef @ptr_numWant2numFin;	# $ptr[N]=   M   : the Nth ali is the Mth one in the list
				#                  of all numbers wanted (i.e. = $want[M])
    undef @ptr_numFin2numWant;	# $ptr[M]=   N   : see previous, the other way around!

    $#want=0                    if (! defined @want);
    $LreadAll=0; 
				# ------------------------------
				# digest input
				# (1) detect keywords
    $#tmp=0; 
    undef %kwd;
    foreach $tmp (@want){
	if ($tmp=~/^(seq|seqAli|seqNoins)$/){
	    $kwd{$tmp}=1; 
	    next;}
	push(@tmp,$tmp);}

    if (($#want>0) && ($#want == $#tmp) ){ # default keyworkds
	foreach $des ("seq","seqAli","seqNoins"){
	    $kwd{"$des"}=1;}}
    @want=@tmp;
				# (2) all?
    $LreadAll=1                 if ( ! @want || ! $want[1] || ($want[1] eq "all"));
    if (! $LreadAll){		# (3) read some
	$#wantNum=$#wantId=0;
	foreach $want (@want) {
	    if ($want !~ /[^0-9]/){push(@wantNum,$want);} # is number
	    else                  {push(@wantId,$want);}}}  # is id
				# ------------------------------
				# get numbers/ids to read
    ($Lok,%rdHeader)=
	&hsspRdHeader($fileInLoc,"SEQLENGTH","PDBID","NR","ID");
    if (! $Lok){
	print "*** ERROR $sbrName reading header of HSSP file '$fileInLoc'\n";
	return(0);}
    $tmp{"NRES"}= $rdHeader{"SEQLENGTH"};$tmp{"NRES"}=~s/\s//g;
    $tmp{"0"}=    $rdHeader{"PDBID"};    $tmp{"0"}=~s/\s//g;
    $idGuide=     $tmp{"0"};

    $#locNum=$#locId=0;		# store the translation name/number
    foreach $it (1..$rdHeader{"NROWS"}){
	$num=$rdHeader{"NR","$it"}; $id=$rdHeader{"ID","$it"};
	push(@locNum,$num);push(@locId,$id);
	$ptr_id2num{"$id"}=$num;
	$ptr_num2id[$num]=$id;}
    push(@locNum,"1")           if ($#locNum==0); # nali=1
				# ------------------------------
    foreach $want (@wantId){	# CASE: input=list of names
	$Lok=0;			#    -> add to @wantNum
	foreach $loc (@locId){
	    if ($want eq $loc){$Lok=1;push(@wantNum,$ptr_id2num{"$loc"});
			       last;}}
	if (! $Lok){
	    print "-*- WARNING $sbrName wanted id '$want' not in '$fileInLoc'\n";}}
				# ------------------------------
				# NOW we have all numbers to get
				# sort the array
    @wantNum= sort bynumber (@wantNum);
				# too many wanted
    if (defined @wantNum && ($wantNum[$#wantNum] > $locNum[$#locNum])){
	$#tmp=0; 
	foreach $want (@wantNum){
	    if ($want <= $locNum[$#locNum]){
		push(@tmp,$want)}
	    else {
		print "-*- WARNING $sbrName no $want not in '$fileInLoc'\n";
		exit;
	    }}
	@wantNum=@tmp;}
		
    @wantNum=@locNum if ($LreadAll);
    if ($#wantNum==0){
	print "*** ERROR $sbrName nothing to read ???\n";
	return(0);}
				# sort the array, again
    @wantNum= sort bynumber (@wantNum);
				# ------------------------------
				# assign pointers to final output
    foreach $it (1..$#wantNum){
	$numWant=$wantNum[$it];
	$ptr_numWant2numFin[$numWant]=$it;
	$ptr_numFin2numWant[$it]=     $numWant;}

				# ------------------------------
				# get blocks to take
    $wantLast=$wantNum[$#wantNum];$#wantBlock=0;
    foreach $ctBlock (1..$nmaxBlocks){
	$beg=1+($ctBlock-1)*70;
	$end=$ctBlock*70;
	last if ($wantLast < $beg);
	$Ltake=0;
	foreach $num(@wantNum){
	    if ( ($beg<=$num)&&($num<=$end) ){
		$Ltake=1;
		last;}}
	if ($Ltake){
	    $wantBlock[$ctBlock]=1;}
	else{
	    $wantBlock[$ctBlock]=0;}}
				# writes ids read
    $tmp{"SWISS"}="";
    foreach $it (1..$#wantNum){ $num=$wantNum[$it];
				$tmp{"$it"}=   $ptr_num2id[$num];
				$tmp{"SWISS"}.="$ptr_num2id[$num]".",";} 
    $tmp{"SWISS"}=~s/,*$//g;
    $tmp{"NROWS"}=$#wantNum;

				# ------------------------------------------------------------
				#       
				# NOTATION: 
				#       $tmp{"0",$it}=  $it-th residue of guide sequnec
				#       $tmp{$itali,$it}=  $it-th residue of of ali $itali
				#       note: itali= same numbering as in 1..$#want
				#             i.e. NOT the position in the file
				#             $ptr_numFin2numWant[$itali]=5 may reveal that
				#             the itali-th ali was actually the fifth in the
				#             HSSP file!!
				#             
				# ------------------------------------------------------------

				# --------------------------------------------------
				# read the file finally
				# --------------------------------------------------
    $Lok=&open_file("$fhinLoc","$fileInLoc");
    if (! $Lok){print "*** ERROR $sbrName opening hssp file '$fileInLoc'\n";
		return(0);}
				# ------------------------------
				# move until first alis
				# ------------------------------
    $ctBlock=$Lread=$#takeTmp=0;
    while (<$fhinLoc>){ 
	last if ($_=~/$regexpEndAli/); # ending
	if ($_=~/$regexpBegAli/){ # this block to take?
	    ++$ctBlock;$Lread=0;
	    if ($wantBlock[$ctBlock]){
		$_=~s/^[^0-9]+(\d+) -\s+(\d+).*$//;
		$beg=$1;$end=$2;$Lread=1;
		$#wantTmp=0;	# local numbers
		foreach $num (@wantNum){
		    if ( ($beg<=$num) && ($num<=$end) ){
			$tmp=($num-$beg)+1; 
			print "*** $sbrName negative number $tmp,$beg,$end,\n" x 3 if ($tmp<1);
			push(@wantTmp,$tmp);}}
		next;}}
	next if (! $Lread);	# move on
	next if ($_=~/$regexpSkip/); # skip line
	$line=$_;
				# --------------------
	if (length($line)<52){	# no alis in line
	    $seqNo=substr($line,1,6);$seqNo=~s/\s//g;
	    if (! defined $seqNo{$seqNo}){
		$seqNo{$seqNo}=1;
		push(@seqNo,$seqNo);}
				# NOTE: $chn,$sec,$acc are returned per residue!
	    if (! defined $tmp{"0","$seqNo"}){
		($seqNo,$pdbNo,
		 $tmp{"chn","$seqNo"},$tmp{"0","$seqNo"},
		 $tmp{"sec","$seqNo"},$tmp{"acc","$seqNo"})=
		     &hsspRdSeqSecAccOneLine($line);}
		    
	    foreach $num(@wantTmp){ # add insertions if no alis
		$pos=                    $num+$beg-1; 
		$posFin=                 $ptr_numWant2numFin[$pos];
		$tmp{"$posFin","$seqNo"}="."; }
	    next;}
				# ------------------------------
				# everything fine, so read !
				# ------------------------------
				# --------------------
				# first the HSSP stuff
	$seqNo=substr($line,1,6);$seqNo=~s/\s//g;
	if (! defined $seqNo{$seqNo}){
	    $seqNo{$seqNo}=1;
	    push(@seqNo,$seqNo);}
				# NOTE: $chn,$sec,$acc are returned per residue!
	if (! defined $tmp{"0","$seqNo"}){
	    ($seqNo,$pdbNo,
	     $tmp{"chn","$seqNo"},$tmp{"0","$seqNo"},
	     $tmp{"sec","$seqNo"},$tmp{"acc","$seqNo"})=
		 &hsspRdSeqSecAccOneLine($line);}
				# --------------------
				# now the alignments
	$alis=substr($line,52); $alis=~s/\n//g;

				# NOTE: @wantTmp has the positions to read in current block,
				#       e.g. want no 75, block=71-90, => 75->4
	foreach $num (@wantTmp){
	    $pos=                        $num+$beg-1; # note: beg=71 in the example above
	    $id=                         $ptr_num2id[$pos];
	    $posFin=                     $ptr_numWant2numFin[$pos];
	    $tmp{"$posFin"}=             $id;
	    $takeTmp[$pos]=              1;
	    print "*** $sbrName neg number $pos,$beg,$num,\n" x 3 if ($pos<1);
	    $tmp{"seq","$posFin"}=       ""     if (! defined $tmp{"seq","$posFin"});
	    if (length($alis) < $num){
		$tmp{"seq","$posFin"}.=  ".";
		$tmp{"$posFin","$seqNo"}=".";}
	    else {
		$tmp{"seq","$posFin"}.=  substr($alis,$num,1);
		$tmp{"$posFin","$seqNo"}=substr($alis,$num,1);}}}
				# ------------------------------
    while (<$fhinLoc>){		# skip over profiles
        last if ($_=~/$regexpBegIns/); } # begin reading insertion list

				# ----------------------------------------
				# store sequences without insertions!!
				# ----------------------------------------
    if (defined $kwd{"seqNoins"} && $kwd{"seqNoins"}){
				# --------------------
	$seq="";		# guide sequence
	foreach $seqNo(@seqNo){
	    $seq.=$tmp{"0","$seqNo"};}
	$seq=~s/[a-z]/C/g;		# small caps to 'C'
	$tmp{"seqNoins","0"}=$seq;
				# --------------------
				# all others (by final count!)
	foreach $it (1..$#wantNum){
	    $seq="";
	    foreach $seqNo(@seqNo){
		$seq.=$tmp{"$it","$seqNo"};}
	    $seq=~s/\s/\./g;	    # fill up insertions
	    $seq=~tr/[a-z]/[A-Z]/;  # small caps to large
	    $tmp{"seqNoins","$it"}=$seq;}
    }
				# --------------------------------------------------
				# read insertion list
				# 
				# syntax of insertion list:  
				#    ....,....1....,....2....,....3....,....4
				#    AliNo  IPOS  JPOS   Len Sequence
				#         9    58    59     5 kQLGAEi
				# 
				# --------------------------------------------------
    undef @insMax;		# note: $insMax[$seqNo]=5 means at residue 'seqNo'
    foreach $seqNo (@seqNo){	#       the longest insertion was 5 residues
	$insMax[$seqNo]=0;}
    while (<$fhinLoc>){
	$rd=$_;
	last if ((! defined $kwd{"seqAli"} || ! $kwd{"seqAli"}) &&
		 (! defined $kwd{"seq"}    || ! $kwd{"seq"}) );
	next if ($rd =~ /AliNo\s+IPOS/);  # skip key
	last if ($rd =~ /^\//);	          # end
        next if ($rd !~ /^\s*\d+/);       # should not happen (see syntax)
        $rd=~s/\n//g; $line=$rd;
	$posIns=$rd;		# current insertion from ali $pos
	$posIns=~s/^\s*(\d+).*$/$1/;
				# takeTmp[$pos]=1 if $pos to be read
	next if (! defined $takeTmp[$posIns] || ! $takeTmp[$posIns]);
				# ok -> take
	$line=~s/^\s*|\s*$//g;	# purge leading blanks
	@tmp=split(/\s+/,$line);
	$iposIns=$tmp[2];	# residue position of insertion
	$seqIns= $tmp[5];	# sequence at insertion 'kQLGAEi'
	$nresIns=(length($seqIns) - 2); # number of residues inserted
	$posFin= $ptr_numWant2numFin[$posIns];
				# --------------------------------------------------
				# NOTE: here $tmp{"$it","$seqNo"} gets more than
				#       one residue assigned (ref=11)
				# --------------------------------------------------
				# change 'ACinK' -> 'ACINEWNK'
	$tmp{"$posFin","$iposIns"}=substr($seqIns,1,(length($seqIns)-1));
				# maximal number of insertions
	$insMax[$iposIns]=$nresIns if ($nresIns > $insMax[$iposIns]);
    } close($fhinLoc);
				# end of reading file
				# --------------------------------------------------
    
				# ------------------------------
				# final sequences (not aligned)
				# ------------------------------
    if (defined $kwd{"seq"} && $kwd{"seq"}){
	foreach $it (0..$tmp{"NROWS"}){
	    $seq="";
	    foreach $seqNo(@seqNo){
		$seq.=$tmp{"$it","$seqNo"};}
	    $seq=~s/[\s\.!]//g;	# replace insertions 
	    $seq=~tr/[a-z]/[A-Z]/; # all capitals
	    $tmp{"seq","$it"}=$seq; }}
				# ------------------------------
				# fill up insertions
				# ------------------------------
    if (defined $kwd{"seqAli"} && $kwd{"seqAli"}){
	undef %ali;		# temporary for storing sequences
	foreach $it (0..$tmp{"NROWS"}){
	    $ali{$it}="";}	# set for all alis
				# ------------------------------
	foreach $seqNo(@seqNo){	# loop over residues
	    $insMax=$insMax[$seqNo];
				# loop over all alis
	    foreach $it (0..$tmp{"NROWS"}){
				# (1) CASE: no insertion
		if    ($insMax==0){
		    $ali{$it}.=$tmp{"$it","$seqNo"};
		    next;}
				# (2) CASE: insertions
		$seqHere=$tmp{"$it","$seqNo"};
		$insHere=(1+$insMax-length($seqHere));
				# NOTE: dirty fill them in 'somewhere'
				# take first residue
		$ali{$it}.=substr($seqHere,1,1);
				# fill up with dots
		$ali{$it}.="." x $insHere ;
				# take remaining residues (if any)
		$ali{$it}.=substr($seqHere,2) if (length($seqHere)>1); }}
				# ------------------------------
				# now assign to final
	foreach $it (0..$tmp{"NROWS"}){
	    $ali{$it}=~s/\s/\./g; # replace ' ' -> '.'
	    $ali{$it}=~tr/[a-z]/[A-Z]/;	# all capital
	    $tmp{"seqAli","$it"}=$ali{$it};}
	undef %ali;		# slim-is-in! 
    }
				# ------------------------------
				# save memory
    foreach $it (0..$tmp{"NROWS"}){
	if ($it == 0){		# guide
	    $id=         $idGuide; }
	else {			# pairs
	    $posOriginal=$ptr_numFin2numWant[$it];
	    $id=         $ptr_num2id[$posOriginal]; }
	$tmp{"$id"}= $id;
        foreach $seqNo (@seqNo){
	    undef $tmp{"$it","$seqNo"};}}
    undef @seqNo;      undef %seqNo;      undef @takeTmp;    undef @idLoc;
    undef @want;       undef @wantNum;    undef @wantId;     undef @wantBlock; 
    undef %rdHeader;   undef %ptr_id2num; undef @ptr_num2id; 
    undef @ptr_numWant2numFin; undef @ptr_numFin2numWant;
    return(1,%tmp);
}				# end of hsspRdAli

#===============================================================================
sub hsspRdHeader {
    local ($fileInLoc,@kwdInLoc) = @_ ;
    local ($sbrName,$fhinLoc,$tmp,
	   @kwdDefHsspTopLoc,@kwdDefHsspHdrLoc,@kwdHsspTopLoc,@kwdHsspHdrLoc,@tmp,
	   $regexpBegHeader,$regexpEndHeader,$regexpLongId,$lenStrid,$LisLongId,
	   %ptr,$kwd,$Lok,$Lpdb,$des,$beg,$end,$mid,$ct,$id,$strid,$ptr,$tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspRdHeader                reads a HSSP header
#       in:                     $fileHssp (must exist), 
#         @kwdInLoc             = one of the default keywords 
#                               (@kwdLocHsspTop,@kwdLocHsspHeader)
#       in:                     'nopair' surpresses reading of pair information
#       out:                    for top  (e.g. NALIGN): $rd{"kwd"}
#                               for prot (e.g. LALI):   $rd{"kwd","$it"}
#                               note: for the later number of elements (it) in
#                                     $rd{"NROWS"}
#         special               ID=ID1, $rd{"kwd","$it"} existes for ID1 and ID2
#-------------------------------------------------------------------------------
    $sbrName="lib-br:hsspRdHeader";$fhinLoc="FHIN"."$sbrName";$fhinLoc=~tr/[a-z]/[A-Z]/;
				# file existing?
    if (! -e $fileInLoc || ! &is_hssp($fileInLoc) ){
	print "*** ERROR $sbrName no HSSP file '$fileInLoc'\n";
	return(0);}
				# ------------------------------
				# settings describing format
    @kwdDefHsspTopLoc= ("PDBID","DATE","SEQBASE","PARAMETER","THRESHOLD",
			"REFERENCE","HEADER","COMPND","SOURCE","AUTHOR",
			"SEQLENGTH","NCHAIN","KCHAIN","NALIGN");
    @kwdDefHsspHdrLoc= ("NR","ID","STRID","IDE","WSIM","IFIR","ILAS",
			"JFIR","JLAS","LALI","NGAP","LGAP","LSEQ2","ACCNUM","PROTEIN");
    $regexpBegHeader=   "^\#\# PROTEINS"; # begin of reading 
    $regexpEndHeader=   "^\#\# ALIGNMENTS"; # end of reading
    $regexpLongId=      "^PARAMETER  LONG-ID :YES"; # identification of long id

    $lenStrid=          4;	# minimal length to identify PDB identifiers
    $LisLongId=         0;	# long identifier names

    $ptr{"IDE"}=1;$ptr{"WSIM"}=2;$ptr{"IFIR"}=3;$ptr{"ILAS"}=4;$ptr{"JFIR"}=5;$ptr{"JLAS"}=6;
    $ptr{"LALI"}=7;$ptr{"NGAP"}=8;$ptr{"LGAP"}=9;$ptr{"LSEQ2"}=10; $ptr{"ACCNUM"}=11;

				# ------------------------------
				# check input arguments
    $#kwdHsspTopLoc=$#kwdHsspHdrLoc=$Lpdb=$LnoPair=0;
    foreach $kwd (@kwdInLoc){
	$Lok=0;
	if ($kwd eq "nopair"){
	    $LnoPair=1;
	    next;}
	$Lpdb=1 if (! $Lpdb && ($kwd =~/^PDBID/));
	foreach $des (@kwdDefHsspTopLoc)   {
	    if ($kwd eq $des){ $Lok=1; push(@kwdHsspTopLoc,$kwd);
			       last;}}
	next if ($Lok || $LnoPair);
	foreach $des (@kwdDefHsspHdrLoc){
	    if ($kwd eq $des){ $Lok=1; push(@kwdHsspHdrLoc,$kwd);
			       last;} }
	print "-*- WARNING $sbrName input kwd=$kwd, makes no sense??\n" if (! $Lok);}

				# force reading of NALI
    push(@kwdHsspTopLoc,"PDBID") if (! $Lpdb);
	
				# get column numbers to read
				# ------------------------------
				# now start to read
    $Lok=&open_file("$fhinLoc","$fileInLoc");
    if (! $Lok){print "*** ERROR $sbrName HSSP file could not be opened '$fileInLoc'\n";
		return(0);}
    undef %tmp;		# save space
				# ------------------------------
    while ( <$fhinLoc> ) {	# read top
	last if ($_ =~ /$regexpBegHeader/); 
	if ($_ =~ /$regexpLongId/) {
	    $LisLongId=1;}
	else{$_=~s/\n//g;$arg=$_;
	     foreach $des (@kwdHsspTopLoc){
		 if ($arg  =~ /^$des\s+(.+)$/){
		     if (defined $ok{"$des"}){ # multiple lines!
			 $tmp="$1"."\t";
			 if  (defined $tmp{"$des"}){
			     $tmp{"$des"}.=$tmp;}
			 else{$tmp{"$des"}=$tmp;}}
		     else {$ok{"$des"}=1;$tmp{"$des"}=$1;}
		     if ($des=~/SEQLENGTH|NCHAIN|KCHAIN|NALIGN/){
			 $tmp{"$des"}=~s/^(\d+)[^0-9]+.*$/$1/;} # purge blanks
		     last;}}}}
				# ------------------------------
    $ct=0;			# read header
    while ( <$fhinLoc> ) { 
	last if ($LnoPair);	# supress reading pair info
	last if ($_ =~ /$regexpEndHeader/); 
	next if ($_ =~ /^  NR\./); # skip descriptors
	$_=~s/\n//g;
	$lenLine=length($_);
	if ($LisLongId){
	    $maxMid=115; $maxMid=($lenLine-56) if ($lenLine < 115);
	    $maxEnd=109; $maxEnd=$lenLine  if ($lenLine < 109);
	    $beg=substr($_,1,56);
	    $end=0; $end=substr($_,109)        if ($lenLine >=109);
	    $mid=substr($_,57,115); }
	else {
	    $maxMid= 62; $maxMid=($lenLine-28) if ($lenLine <  90);
	    $beg=substr($_,1,28);
	    $end=0; $end=substr($_,90)         if ($lenLine >=90);
	    $mid=substr($_,29,90); }
	$end=~s/^\s*|\s*$//g;   # purge leading blanks
	$mid=~s/^\s*|\s*$//g;	# purge leading blanks
				# SWISS accession: hack because it may be empty!
	if ($lenLine > 86) {
	    $accnum=substr($_,81,6); $accnum=~s/(\s)\s+/$1/g ; }
	else {
	    $accnum=0;}
				# begin: counter and id
	$beg=~s/.+ \:\s*|\s*$//g;
	if (! $LisLongId) {$id=$beg;$id=~s/([^\s]+).*$/$1/;
			   $strid=$beg;$strid=~s/$id|\s//g; }
	else              {$id=$beg;$id=~s/(.+_\S+).*/$1/;
			   $strid=substr($_,49,6);$strid=~s/\s//g; }
	    $tmp=$lenStrid-1;
	if ( (length($strid)<$lenStrid) && ($id=~/^[0-9][A-Z0-9]{$tmp,$tmp}\s*/)){
	    $strid=substr($id,1,$lenStrid); }
	++$ct;

	$tmp{"ID","$ct"}=     $id;
	$tmp{"NR","$ct"}=     $ct;
	$tmp{"STRID","$ct"}=  $strid;
				# correct for ID = PDBid
	$tmp{"STRID","$ct"}=  $id if ($strid=~/^\s*$/ && 
				      $id=~/\d\w\w\w.?\w?$/);
	    
	$tmp{"PROTEIN","$ct"}=$end;
	$tmp{"ID1","$ct"}=$tmp{"PDBID"};
	$tmp{"ACCNUM","$ct"}=$accnum;
				# middle all info
	$#tmp=0;@tmp=split(/\s+/,$mid);
	foreach $_ (@tmp) {$_=~s/\s//g;}

	foreach $des (@kwdHsspHdrLoc){ 
	    next if ( ! defined $ptr{"$des"});
	    next if ( $des =~/^ACCNUM/);
	    $ptr=$ptr{"$des"};
	    $tmp{"$des","$ct"}=$tmp[$ptr]; }}close($fhinLoc);
    $tmp{"NROWS"}=$ct;
				# clean up
    $#kwdInLoc=$#kwdDefHsspHdrLoc=$#kwdHsspTopLoc=$#tmp=
	$#kwdDefHsspTopLoc=$#kwdHsspHdrLoc=0;
    undef %ptr;
    return(1,%tmp);
}				# end of hsspRdHeader

#===============================================================================
sub hsspRdHeader4topits {
    local ($file_in) = @_ ;
    local ($fhinLoc,$sbrName,$msg,$ct,$tmp,$tmp2,@tmp,$it,%rd_hssp);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   hsspRdHeader4topits         extracts the summary from HSSP header (for TOPITS)
#       in:                     $fileHssp 
#       out:                    $rd_hssp{"kwd","$ct"}, where :
#                                  $ct= number of protein
#                                  kwd= ide,ifir,jfir,ilas,jlas,lali,ngap,lgap,len2,id2
#                               number of proteins: $rd_hssp{"NROWS"}=$rd_hssp{"nali"}
#       err:                    ok=(1,'ok',$rd_hssp{}), err=(0,'msg',"error")
#--------------------------------------------------------------------------------
    $sbrName="hsspRdHeader4topits";$fhinLoc="FHIN"."$sbrName";

    return(0,"*** ERROR $sbrName: no HSSP file '$file_in'\n","error")
	if (! -e $file_in);
    $Lok=       &open_file("$fhinLoc","$file_in");
    return(0,"*** ERROR $sbrName: '$file_in' not opened\n","error")
	if (! $Lok);
    undef %rd_hssp;		# save space
				# ------------------------------
				# go off reading
    while(<$fhinLoc>){
	last if ($_=/^\#\# PROTEINS/);}	# end of header
    $ct=0;
    while(<$fhinLoc>){
	last if ($_=/^\#\# ALI/);
	next if ($_=~/^  NR/);
	next if (length($_)<27); # xx hack should not happen!!
	$tmp=substr($_,27);
	$tmp=~s/^\s*|\s$//g;	# purge leading blanks
	$#tmp=0;@tmp=split(/\s+/,$tmp);
	++$ct;
	$rd_hssp{"ide","$ct"}=$tmp[1];
	$rd_hssp{"ifir","$ct"}=$tmp[3];$rd_hssp{"jfir","$ct"}=$tmp[5];
	$rd_hssp{"ilas","$ct"}=$tmp[4];$rd_hssp{"jlas","$ct"}=$tmp[6];
	$rd_hssp{"lali","$ct"}=$tmp[7];
	$rd_hssp{"ngap","$ct"}=$tmp[8];$rd_hssp{"lgap","$ct"}=$tmp[9];
	$rd_hssp{"len2","$ct"}=$tmp[10];

	$tmp= substr($_,7,20);
	$tmp2=substr($_,20,6);
	$tmp3=$tmp2; $tmp3=~s/\s//g;
	if (length($tmp3)<3) {	# STRID empty
	    $tmp=substr($_,8,6);
	    $tmp=~s/\s//g;
	    $rd_hssp{"id2","$ct"}=$tmp;}
	else{$tmp2=~s/\s//g;
	     $rd_hssp{"id2","$ct"}=$tmp2;}}close($fhinLoc);
    $rd_hssp{"nali"}=$rd_hssp{"NROWS"}=$ct;
    return(1,"ok $sbrName",%rd_hssp);
}				# end of hsspRdHeader4topits

#===============================================================================
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

#===============================================================================
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

#===============================================================================
sub hsspRdSeqSecAccOneLine {
    local ($inLine) = @_ ;
    local ($sbrName,$fhinLoc,$seqNo,$pdbNo,$chn,$seq,$sec,$acc,$tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspRdSeqSecAccOneLine      reads begin of one HSSP line
#-------------------------------------------------------------------------------
    $sbrName="hsspRdSeqSecAccOneLine";

    $seqNo=substr($inLine,1,6);$seqNo=~s/\s//g;
    $pdbNo=substr($inLine,7,5);$pdbNo=~s/\s//g;
    $chn=  substr($inLine,13,1);
    $seq=  substr($inLine,15,1);
    $sec=  substr($inLine,18,1);
    $acc=  substr($inLine,36,4);$acc=~s/\s//g;
    return($seqNo,$pdbNo,$chn,$seq,$sec,$acc)
}				# end of hsspRdSeqSecAccOneLine

#===============================================================================
sub hsspRdStrip4topits {
    local ($file_in) = @_ ;
    local ($fhinLoc,$sbrName,$msg,@strip);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   hsspRdStrip4topits          reads the new strip file for PP
#       in:                     $fileHssp 
#       out:                    $rd_hssp{"kwd","$ct"}, where :
#       err:                    ok=(1,'ok',$rd_hssp{}), err=(0,'msg',"error")
#--------------------------------------------------------------------------------
    $sbrName="hsspRdStrip4topits";$fhinLoc="FHIN"."$sbrName";
    $Lok=       &open_file("$fhinLoc","$file_in");
    if (! $Lok){$msg="*** ERROR $sbrName: '$file_in' not opened\n";
		return(0,$msg,"error");}
    $#strip=0;
    while(<$fhinLoc>){
	push(@strip,$_);}close($fhinLoc);
    return(1,"ok $sbrName",@strip);
}				# end of hsspRdStrip4topits

#===============================================================================
sub hsspRdStripAndHeader {
    local($fileInHsspLoc,$fileInStripLoc,$fhErrSbr,@kwdInLocRd) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok,$LhsspTop,$LhsspPair,$LstripTop,$LstripPair,$kwd,$kwdRd,
	  @sbrKwdHsspTop,    @sbrKwdHsspPair,    @sbrKwdStripTop,     @sbrKwdStripPair, 
	  @sbrKwdHsspTopDo,  @sbrKwdHsspPairDo,  @sbrKwdStripTopDo,   @sbrKwdStripPairDo,
	  @sbrKwdHsspTopWant,@sbrKwdHsspPairWant,@sbrKwdStripTopWant, @sbrKwdStripPairWant,
	  %translateKwdLoc,%rdHsspLoc,%rdStripLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspRdStripAndHeader        reads the headers for HSSP and STRIP and merges them
#       in:                     $fileHssp,$fileStrip,$fhErrSbr,@keywords
#         $fhErrSbr             FILE-HANDLE to report errors
#         @keywords             "hsspTop",  @kwdHsspTop,
#                               "hsspPair", @kwdHsspPairs,
#                               "stripTop", @kwdStripTop,
#                               "stripPair",@KwdStripPair,
#                               i.e. the key words of the variables to read
#                               following translation:
#         HsspTop:              pdbid1   -> PDBID     (of fileHssp, 1pdb_C -> 1pdbC)
#                               date     -> DATE      (of file)
#                               db       -> SEQBASE   (database used for ali)
#                               parameter-> PARAMETER (lines giving the maxhom paramters)
#             NOTE:                         multiple lines separated by tabs!
#                               threshold-> THRESHOLD (i.e. which threshold was used)
#                               header   -> HEADER
#                               compnd   -> COMPND    
#                               source   -> SOURCE
#                               len1     -> SEQLENGTH (i.e. length of guide seq)
#                               nchain   -> NCHAIN    (number of chains in protein)
#                               kchain   -> KCHAIN    (number of chains in file)
#                               nali     -> NALIGN    (number of proteins aligned in file)
#         HsspPair:             pos      -> NR        (number of pair)
#                               id2      -> ID        (id of aligned seq, 1pdb_C -> 1pdbC)
#                               pdbid2   -> STRID     (PDBid of aligned seq, 1pdb_C -> 1pdbC)
#                               pide     -> IDEN      (seq identity, returned as int Perce!!)
#                               wsim     -> WSIM      (weighted simil., ret as int Percentage)
#                               ifir     -> IFIR      (first residue of guide seq in ali)
#                               ilas     -> ILAS      (last residue of guide seq in ali)
#                               jfir     -> JFIR      (first residue of aligned seq in ali)
#                               jlas     -> JLAS      (last residue of aligned seq in ali)
#                               lali     -> LALI      (number of residues aligned)
#                               ngap     -> NGAP      (number of gaps)
#                               lgap     -> LGAP      (length of all gaps, number of residues)
#                               len2     -> LSEQ2     (length of aligned sequence)
#                               swissAcc -> ACCNUM    (SWISS-PROT accession number)
#         StripTop:             nali     -> alignments (number of alis)
#                               listName -> list name (alignment list)
#                               lastName -> last name was (last aligned id)
#                               sortMode -> sort-mode (ZSCORE/asf.)
#                               weight1  -> weights 1 (sequence weights for guide: (YES|NO))
#                               weight2  -> weights 2 (sequence weights for aligned: (YES|NO))
#                               smin     -> smin      (minimal value of scoring metric)
#                               smax     -> smax      (maximal value of scoring metric)
#                               gapOpen  -> gap_open  (gap open penalty)
#                               gapElon  -> gap_elongation  (gap elongation/extension penalty)
#                               indel1   -> INDEL in sec-struc of SEQ1 (YES|NO)
#                               indel2   -> INDEL in sec-struc of SEQ2 (YES|NO)
#         StripPair:            energy   -> VAL       (Smith-Waterman score)
#                               idel     -> 
#                               ndel     -> 
#                               zscore   -> ZSCORE
#                               strh     -> STRHOM    (secStr ide Q3, , ret as int Percentage)
#                               rmsd     -> RMS
#                               name     -> NAME      (name of protein)
#       out:                    %rdHdr{""}
#                               $rdHdr{"NROWS"}       (number of pairs read)
#                               $rdHdr{"$kwd"}        kwds, only for guide sequenc
#                               $rdHdr{"$kwd","$ct"}  all values for each pair ct
#       err:                    ok=(1,'ok',$rd_hssp{}), err=(0,'msg',"error")
#-------------------------------------------------------------------------------
    $sbrName="lib-br:hsspRdStripAndHeader";$fhinLoc="FHIN"."$sbrName";
				# files existing?
    return(0,"error","*** ERROR ($sbrName) no HSSP  '$fileInHsspLoc'\n")
	if (! defined $fileInHsspLoc || ! -e $fileInHsspLoc);
	
    return(0,"error","*** ERROR ($sbrName) no STRIP '$fileInStripLoc'\n")
	if (! defined $fileInStripLoc || ! -e $fileInStripLoc);
				# ------------------------------
    @sbrKwdHsspTop=		# defaults
	("PDBID","DATE","SEQBASE","PARAMETER","THRESHOLD","HEADER","COMPND","SOURCE",
	 "SEQLENGTH","NCHAIN","KCHAIN","NALIGN");
#		   "REFERENCE","AUTHOR",
    @sbrKwdHsspPair= 
	("NR","ID","STRID","IDE","WSIM","IFIR","ILAS",
	 "JFIR","JLAS","LALI","NGAP","LGAP","LSEQ2","ACCNUM","PROTEIN");
    @sbrKwdStripPair= 
	("NR","VAL","LALI","IDEL","NDEL","ZSCORE","IDE","STRHOM","LEN2","RMSD","SIGMA","NAME");
    @sbrKwdStripTop= 
	("nali","listName","lastName","sortMode","weight1","weight2","smin","smax",
	 "gapOpen","gapElon","indel1","indel2");
    %translateKwdLoc=		# hssp top
	('id1',"ID1", 'pdbid1',"PDBID", 'date',"DATE", 'db',"SEQBASE",
	 'parameter',"PARAMETER", 'threshold',"THRESHOLD",
	 'header',"HEADER", 'compnd',"COMPND", 'source',"SOURCE",
	 'len1',"SEQLENGTH", 'nchain',"NCHAIN", 'kchain',"KCHAIN", 'nali',"NALIGN",
				# hssp pairs
	 'pos',"NR", 'id2',"ID", 'pdbid2',"STRID", 'pide',"IDE", 'wsim',"WSIM",
	 'ifir',"IFIR", 'ilas',"ILAS", 'jfir', "JFIR", 'jlas',"JLAS",
	 'lali',"LALI", 'ngap', "NGAP", 'lgap',"LGAP", 'len2',"LSEQ2", 'swissAcc',"ACCNUM",
				# strip top
				# non all as they come!
				# strip pairs
	 'energy',"VAL", 'zscore',"ZSCORE", 'rmsd',"RMSD", 'name',"NAME", 'strh',"STRHOM",
	 'idel',"IDEL", 'ndel',"NDEL", 'lali',"LALI", 'pos', "NR",'sigma',"SIGMA"
	 );
    @sbrKwdHsspTopDo=  @sbrKwdHsspTopWant=  @sbrKwdHsspTop;
    @sbrKwdHsspPairDo= @sbrKwdHsspPairWant= @sbrKwdHsspPair;
    @sbrKwdStripTopDo= @sbrKwdStripTopWant= @sbrKwdStripTop;
    @sbrKwdStripPairDo=@sbrKwdStripPairWant=@sbrKwdStripPair;
				# ------------------------------
				# process keywords
    if ($#kwdInLocRd>1){
				# ini
	$#sbrKwdHsspTopDo=$#sbrKwdHsspPairDo=$#sbrKwdStripTopDo=$#sbrKwdStripPairDo=
	    $#sbrKwdHsspTopWant=$#sbrKwdHsspPairWant=
		$#sbrKwdStripTopWant=$#sbrKwdStripPairWant=0;
	$LhsspTop=$LhsspPair=$LstripTop=$LstripPair=0;
	foreach $kwd (@kwdInLocRd){
	    next if ($kwd eq "id1"); # will be added manually
	    next if (length($kwd)<1);
	    if    ($kwd eq "hsspTop") {$LhsspTop=1; }
	    elsif ($kwd eq "hsspPair"){$LhsspPair=1; $LhsspTop=0;}
	    elsif ($kwd eq "stripTop"){$LstripTop=1; $LhsspTop=$LhsspPair=0;}
	    elsif ($kwd =~ /strip/)   {$LstripPair=1;$LhsspTop=$LhsspPair=$LstripTop=0;}
	    elsif ($LhsspTop){
		if (! defined $translateKwdLoc{"$kwd"}){
		    print $fhErrSbr "*** ERROR $sbrName HSSPtop kwd=$kwd, not understood\n";}
		else {
		    push(@sbrKwdHsspTopWant,$kwd);
		    push(@sbrKwdHsspTopDo,$translateKwdLoc{"$kwd"});}}
	    elsif ($LhsspPair){
		if (! defined $translateKwdLoc{"$kwd"}){
		    print $fhErrSbr "*** ERROR $sbrName HSSPpair kwd=$kwd, not understood\n";}
		else {
		    push(@sbrKwdHsspPairWant,$kwd);
		    push(@sbrKwdHsspPairDo,$translateKwdLoc{"$kwd"});}}
	    elsif ($LstripTop){
		if (! defined $translateKwdLoc{"$kwd"} || $kwd eq "nali"){
		    push(@sbrKwdStripTopWant,$kwd);
		    push(@sbrKwdStripTopDo,$kwd);}
		else {
		    push(@sbrKwdStripTopWant,$kwd);
		    push(@sbrKwdStripTopDo,$translateKwdLoc{"$kwd"});}}
	    elsif ($LstripPair){
		if (! defined $translateKwdLoc{"$kwd"}){
		    print $fhErrSbr "*** ERROR ($sbrName) STRIP keyword  '$kwd' not understood\n";}
		else {
		    push(@sbrKwdStripPairWant,$kwd);
		    push(@sbrKwdStripPairDo,$translateKwdLoc{"$kwd"});}}}}

    undef %tmp; undef %rdHsspLoc; undef %rdStripLoc; # save space
				# ------------------------------
				# read HSSP header
    ($Lok,%rdHsspLoc)=
	&hsspRdHeader($fileInHsspLoc,@sbrKwdHsspTopDo,@sbrKwdHsspPairDo);
    return(0,"error","*** ERROR $sbrName: hsspRdHeader erred on $fileInHsspLoc\n")
	if (! $Lok);
				# ------------------------------
				# read STRIP header
    %rdStripLoc=
	&hsspRdStripHeader($fileInStripLoc,"unk","unk","unk","unk","unk",
			   @sbrKwdStripTopDo,@sbrKwdStripPairDo);
    return(0,"error","*** ERROR $sbrName: hsspRdHeader erred on $fileInHsspLoc\n")
	if (! %rdStripLoc);
				# security check
    if ($rdStripLoc{"NROWS"} != $rdHsspLoc{"NROWS"}){
	$txt="*** ERROR ($sbrName) number of pairs differ\n".
	    "*** HSSP  =".$rdHsspLoc{"NROWS"}."\n".
		"*** STRIP =".$rdStripLoc{"NROWS"}."\n";
	return(0,"error",$txt);}
				# ------------------------------
				# merge the two
    $tmp{"NROWS"}=$rdHsspLoc{"NROWS"}; 
				# --------------------
				# hssp info guide (top)
    foreach $kwd (@sbrKwdHsspTopWant){
	$kwdRd=$translateKwdLoc{"$kwd"};
	if (! defined $rdHsspLoc{"$kwdRd"}){
	    print $fhErrSbr "-*- WARNING ($sbrName) rdHsspLoc-Top not def for $kwd->$kwdRd\n";}
	else {
	    $tmp{"$kwd"}=$rdHsspLoc{"$kwdRd"};}}
				# --------------------
				# hssp info pairs
    foreach $it (1..$rdHsspLoc{"NROWS"}){
	$tmp{"id1","$it"}= $tmp{"pdbid1"}; # add identifier for each pair
	$tmp{"len1","$it"}=$tmp{"len1"}; # add identifier for each pair
	foreach $kwd (@sbrKwdHsspPairWant){
	    $kwdRd=$translateKwdLoc{"$kwd"};
	    if (! defined $rdHsspLoc{"$kwdRd","$it"}){
		print $fhErrSbr "-*- WARNING ($sbrName) HsspLoc not for $kwd->$kwdRd ($it)\n";}
	    else {
		$tmp{"$kwd","$it"}=$rdHsspLoc{"$kwdRd","$it"};}}}
				# --------------------
				# strip pairs
    foreach $kwd (@sbrKwdStripPairWant){
	$kwdRd=$translateKwdLoc{"$kwd"};
	foreach $it (1..$rdStripLoc{"NROWS"}){
	    if (! defined $rdStripLoc{"$kwdRd","$it"}){
		print $fhErrSbr "-*- WARNING ($sbrName) StripLoc not for $kwd->$kwdRd ($it)\n";}
	    else {
		$tmp{"$kwd","$it"}=$rdStripLoc{"$kwdRd","$it"};}}}
				# --------------------
				# purge blanks
    foreach $kwd (@sbrKwdHsspPairWant,@sbrKwdStripPairWant){
	next if ($kwd =~/^name$|^protein/);
	foreach $it (1..$tmp{"NROWS"}){
	    $tmp{"$kwd","$it"}=~s/\s//g;}}
				# correction for 'pide','wsim'
    foreach $it (1..$rdHsspLoc{"NROWS"}){
	$tmp{"pide","$it"}*=100   if (defined $tmp{"pide","$it"});
	$tmp{"wsim","$it"}*=100   if (defined $tmp{"wsim","$it"});
	$tmp{"strh","$it"}*=100   if (defined $tmp{"strh","$it"});
	$tmp{"id1","$it"}=~s/_//g if (defined $tmp{"id1","$it"});
	$tmp{"id2","$it"}=~s/_//g if (defined $tmp{"id2","$it"});
    }
				# --------------------
    undef @kwdInLocRd;		# save space!
    undef @sbrKwdHsspTop;     undef @sbrKwdHsspPair;     undef @sbrKwdStripPair; 
    undef @sbrKwdHsspTopDo;   undef @sbrKwdHsspPairDo;   undef @sbrKwdStripPairDo; 
    undef @sbrKwdHsspTopWant; undef @sbrKwdHsspPairWant; undef @sbrKwdStripPairWant; 
    undef %rdHsspLoc; undef %rdStripLoc; undef %translateKwdLoc; 
    return(1,"ok $sbrName",%tmp);
}				# end of hsspRdStripAndHeader

#===============================================================================
sub hsspRdStripHeader {
    local($fileInLoc,$exclTxt,$inclTxt,$minZ,$lowIde,$upIde,@kwdInStripLoc)=@_ ;
    local($sbrName,$fhinLoc,$Lok,$tmp,@excl,@incl,$nalign,$des,$kwd,$kwdRd,$info,
	  @kwdDefStripTopLoc,@kwdDefStripHdrLoc,%ptr,$posIde,$posZ,$ct,$i,
	  @kwdStripTopLoc,@kwdStripHdrLoc,%LtakeLoc,$rdBeg,$rdEnd,$Ltake);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   hsspRdStripHeader           reads the header of a HSSP.strip file
#       in:                     fileStrip
#                               exclTxt="n1-n2", or "*-n2", or "n1,n3,...", or 'none|all'
#                               inclTxt="n1-n2", or "*-n2", or "n1,n3,...", or 'none|all'
#                               minimal Z-score; minimal and maximal seq ide
#         neutral:  'unk'       for all non-applicable variables!
#         @kwdInLoc             = one of the default keywords 
#                               (@kwdLocHsspTop,@kwdLocHsspHeader)
#       out:                    for top  (e.g. NALIGN): $rd{"kwd"}
#                               for prot (e.g. LALI):   $rd{"kwd","$it"}
#                               note: for the later number of elements (it) in
#                                     $rd{"NROWS"}
#                               $rd{"$des","$ct"} = column $des for pair no $ct
#                               $des=
#                                   IAL,VAL,LEN1,IDEL,NDEL,ZSCORE,IDE,STRHOM,LEN2,RMS,NAME
#                               -------------------------------
#                               ALTERNATIVE keywords for HEADER
#                               -------------------------------
#                               nali     -> alignments (number of alis)
#                               listName -> list name (alignment list)
#                               lastName -> last name was (last aligned id)
#                               sortMode -> sort-mode (ZSCORE/asf.)
#                               weight1  -> weights 1 (sequence weights for guide: (YES|NO))
#                               weight2  -> weights 2 (sequence weights for aligned: (YES|NO))
#                               smin     -> smin      (minimal value of scoring metric)
#                               smax     -> smax      (maximal value of scoring metric)
#                               gapOpen  -> gap_open  (gap open penalty)
#                               gapElon  -> gap_elongation  (gap elongation/extension penalty)
#                               indel1   -> INDEL in sec-struc of SEQ1 (YES|NO)
#                               indel2   -> INDEL in sec-struc of SEQ2 (YES|NO)
#--------------------------------------------------------------------------------
    $sbrName="lib-br:hsspRdStripHeader";$fhinLoc="FHIN"."$sbrName";
				# ------------------------------
				# defaults
    @kwdDefStripTopLoc=("test sequence","list name","last name was","seq_length",
			"alignments","sort-mode","weights 1","weights 1","smin","smax",
			"maplow","maphigh","epsilon","gamma",
			"gap_open","gap_elongation",
			"INDEL in sec-struc of SEQ 1","INDEL in sec-struc of SEQ 2",
			"NBEST alignments","secondary structure alignment");
    @kwdDefStripHdrLoc=("NR","VAL","LALI","IDEL","NDEL",
			"ZSCORE","IDE","STRHOM","LEN2","RMSD","SIGMA","NAME");
    $ptr{"IAL"}= 1;$ptr{"VAL"}= 2;$ptr{"LALI"}= 3;$ptr{"IDEL"}= 4;$ptr{"NDEL"}= 5;
    $ptr{"ZSCORE"}=6;$ptr{"IDE"}=7;$ptr{"STRHOM"}=8;
    $ptr{"LEN2"}=9;$ptr{"RMSD"}=10;$ptr{"SIGMA"}=11;$ptr{"NAME"}=12;
    $posIde=$ptr{"IDE"};$posZ=$ptr{"ZSCORE"};

    @kwdOutTop=("nali","listName","lastName","sortMode","weight1","weight2","smin","smax",
		"gapOpen","gapElon","indel1","indel2");

    %translateKwdStripTop=	# strip top
	('nali',"alignments",
	 'listName',"list name",'lastName',"last name was",'sortMode',"sort-mode",
	 'weight1',"weights 1",'weight2',"weights 2",'smin',"smin",'smax',"smax",
	 'gapOpen',"gap_open",'gapElon',"gap_elongation",
	 'indel1',"INDEL in sec-struc of SEQ 1",'indel2',"INDEL in sec-struc of SEQ 2");
	 
				# ------------------------------
				# check input arguments
    undef %addDes;
    $#kwdStripTopLoc=$#kwdStripHdrLoc=0;
    foreach $kwd (@kwdInStripLoc){
	$Lok=0;
	foreach $des (@kwdDefStripHdrLoc)   {
	    if ($kwd eq $des){ $Lok=1; push(@kwdStripHdrLoc,$kwd);
			       last;}}
	next if ($Lok);
	foreach $des (@kwdDefStripTopLoc){
	    if ($kwd eq $des){ $Lok=1; push(@kwdStripTopLoc,$kwd);
			       foreach $desOut(@kwdOutTop){
				   if ($kwd eq $translateKwdStripTop{"$desOut"}){
				       $addDes{"$des"}=$desOut;
				       last;}}
			       last;} }
	next if ($Lok);
	if (defined $translateKwdStripTop{"$kwd"}){
	    $addDes=$translateKwdStripTop{"$kwd"};
	    $Lok=1; push(@kwdStripTopLoc,$addDes);
	    $addDes{"$addDes"}=$kwd;}
	next if ($Lok);
	print "-*- WARNING $sbrName input kwd=$kwd, makes no sense??\n" 
	    if (! $Lok);}
    undef %LtakeLoc;		# logicals to decide what to read
    foreach $kwd (@kwdStripTopLoc){
	$LtakeLoc{$kwd}=1;}	# 
				# force reading of NALI
    if (! defined $LtakeLoc{"alignments"}){push(@kwdStripTopLoc,"alignments");
					   $LtakeLoc{"alignments"}=1;}

    $#excl=$#incl=0;		# set zero
				# --------------------------------------------------
				# now start to read
				# open file
    $Lok=       &open_file("$fhinLoc","$fileInLoc");
    if (! $Lok){print "*** ERROR $sbrName: '$fileInLoc' not opened\n";
		return(0);}
				# --------------------------------------------------
				# file type:
				# '==========  MAXHOM-STRIP  ==========='
    $_=<$fhinLoc>;		# first line
    if ($_!~/^[= ]+MAXHOM-STRIP[= ]+/){ # file recognised?
	print "*** ERROR ($sbrName) not maxhom.STRIP file! (?)\n";
	return(0);}
    undef %tmp;		# save space
				# --------------------------------------------------
    while (<$fhinLoc>) {	# read file TOP (global info)
				# stop if next key:
				# '============= SUMMARY ==============='
	last if ($_ =~/^[= ]+SUMMARY[= ]+/);
	$_=~s/\n//g;$_=~s/^\s*|\s*$//g;
	next if ($_ !~ /\:/);	# skip if ':' missing (=> error!)
	($kwdRd,$info)=split(/:/,$_);
	if ($kwdRd=~/seq_length/){
	    $len1=$info;$len1=~s/\D//g;}
	$kwdRd=~s/\s*$//g;	# purge blanks at end
	if ($LtakeLoc{$kwdRd}){	# want the info?
	    $info=~s/^\s*|\s*$//g;
	    $tmp{"$kwdRd"}=$info;
				# add short names for header
	    if (defined $addDes{"$kwdRd"}){
		$kwdRdAdd=$addDes{"$kwdRd"};
		$tmp{"$kwdRdAdd"}=$info;}
	    next;}}
    $nalign=$tmp{"alignments"};
				# ------------------------------
				# get range to be in/excluded
    if ($inclTxt ne "unk"){ @incl=&get_range($inclTxt,$nalign);} 
    if ($exclTxt ne "unk"){ @excl=&get_range($exclTxt,$nalign);} 
    $ct=0;			# --------------------------------------------------
    while (<$fhinLoc>) {	# read PAIR information
				# '=========== ALIGNMENTS =============='
	last if ($_ =~ /^[= ]+ALIGNMENTS[= ]+/);
	next if ($_ =~ /^\s*IAL\s+VAL/); # skip line with names
	$_=~s/\n//g; 
	next if (length($_)<5);	# another format error if occurring

	$rdBeg=substr($_,1,69);$rdBeg=~s/^\s*|\s*$//g;
	$rdEnd=substr($_,70);  $rdEnd=~s/^\s*|\s*$//g;
	$rdEnd=~s/(\s)\s*/$1/g; # 2 blank to 2

	@tmp=(split(/\s+/,$rdBeg),"$rdEnd");

	$pos=$tmp[1];		# ------------------------------
	$Ltake=1;		# exclude pair because of RANK?
	if ($#excl>0){foreach $i (@excl){if ($i eq $pos){$Ltake=0;
							 last;}}}
	if (($#incl>0)&&$Ltake){ 
	    $Ltake=0; foreach $i (@incl){if ($i eq $pos){$Ltake=1; 
							 last;}}}
	next if (! $Ltake);	# exclude
				# exclude because of identity?
	next if ((( $upIde ne "unk") && (100*$tmp[$posIde]>$upIde))||
		 (($lowIde ne "unk") && (100*$tmp[$posIde]<$lowIde)));
				# exclude because of zscore?
	next if ((  $minZ  ne "unk") && ($tmp[$posZ]<$minZ));

	++$ct;
#....,....1....,....2....,....3....,....4....,....5....,....6....,....7....,....8
# IAL    VAL   LEN IDEL NDEL  ZSCORE   %IDEN  STRHOM  LEN2   RMS SIGMA NAME

	$tmp{"LEN1","$ct"}=$len1;
	foreach $kwd (@kwdStripHdrLoc){
	    $pos=$ptr{"$kwd"};
	    if (($pos>$#tmp)||($pos<1)){
		print "*** ERROR in $sbrName ct=$ct, kwd=$kwd, pos should be $pos\n";
		print "***          however \@tmp not defined for that\n";
		return(0);}
	    if ($kwd eq "IDE"){$tmp=100*$tmp[$pos];}else{$tmp=$tmp[$pos];}
	    $tmp{"$kwd","$ct"}=$tmp;}
    } close($fhinLoc);
    $tmp{"NROWS"}=$ct;
				# clean up
    undef @kwdInLoc;undef @kwdDefStripTopLoc;undef @kwdDefStripHdrLoc;undef %ptr; 
    undef @kwdStripTopLoc; undef @kwdStripHdrLoc; undef %LtakeLoc;
    
    return (%tmp);
}				# end of hsspRdStripHeader

#===============================================================================
sub hsspSkewProf {
    local($fileInLoc,$chainInLoc,$fileOutLoc,$fileMatdbLoc,$naliSatLoc,$distLoc,$distMode) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspSkewProf                changes the HSSP profile for too few alignments
#       in:                     $fileInLoc    : HSSP file (chain ignored!)
#       in:                     $chainInLoc   : chain to read
#                                   '*' for omitting the test
#       in:                     $fileOutLoc   : HSSP file with skewed profiles to write
#       in:                     $fileMatdbLoc : RDB file with substitution matrix to skew
#       in:                     $naliSatLoc   : number of alignments when no db taken
#       in:                     $distLoc      : limiting distance from HSSP (new Ide)
#                                   '0' in NEXT variable for omitting the test
#       in:                     $distModeLoc  : mode of limit ('gt|ge|lt|le')
#                                              -> if mode=gt, all with dist>distLoc
#                                                 will be counted
#                                   '0' for omitting the test
#       out:                    1|0,msg,  implicit: file
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."hsspSkewProf"; 
    $fhinLoc="FHIN_"."hsspSkewProf"; $fhoutLoc="FHOUT_"."hsspSkewProf";
				# ------------------------------
				# check arguments
    return(&errSbr("not def fileInLoc!"))             if (! defined $fileInLoc);
    return(&errSbr("not def chainInLoc!"))            if (! defined $chainInLoc);
    return(&errSbr("not def fileOutLoc!"))            if (! defined $fileOutLoc);
    return(&errSbr("not def fileMatdbLoc!"))          if (! defined $fileMatdbLoc);
    return(&errSbr("not def naliSatLoc!"))           if (! defined $naliSatLoc);
    return(&errSbr("not def distLoc!"))               if (! defined $distLoc);
    return(&errSbr("not def distMode!"))              if (! defined $distMode);
#    return(&errSbr("not def !"))            if (! defined $);

    return(&errSbr("miss in file '$fileInLoc'!"))     if (! -e $fileInLoc);
    return(&errSbr("miss in file '$fileMatdbLoc'!"))  if (! -e $fileMatdbLoc);
    $errMsg="*** ERROR $sbrName in local: f=$fileInLoc, c=$chainInLoc, fileout=$fileOutLoc,".
	"fileMat=$fileMatdbLoc, dist=$distLoc, mode=$distMode\n";

    @aaLoc= split(//,"VLIMFWYGAPSTCHRKQEND"); # note: IS HSSP succession
    undef %aaLoc;
    foreach $tmp (@aaLoc){
	$aaLoc{"$tmp"}=1; }	# logical array of all known amino acids

				# ------------------------------
				# read substitution matrix
    if (! defined %matdb) {	# (only if not defined to save time)
	($Lok,$msg,%matdb)=
	    &metricRdbRd($fileMatdbLoc);
	                        return(&errSbrMsg("skew prof failed reading metri".
						  $errMsg,$msg)) if (! $Lok); 
	foreach $aa1 (@aaLoc){	# dissect into lists ( $prof{R}='R->V,R->L,R->I,...,R->D' )
	    $tmp=""; 
	    foreach $aa2 (@aaLoc){ 
		$tmp.=$matdb{"$aa1","$aa2"}.","; }
	    $profTmp{"$aa1"}=$tmp; } }

				# ------------------------------
    ($Lok,$msg,$nali,$tmp)=	# find number of alis in HSSP header
	&hsspGetChainNali($fileInLoc,$chainInLoc,$distLoc,$distMode);
                                return(&errSbrMsg("failed on hsspGetChainNali".
						  $errMsg,$msg)) if (! $Lok);
				# ------------------------------
				# simple copy if saturation
    if ($nali >= $naliSatLoc) {
	($Lok,$msg)=
	    &sysCpfile($fileInLoc,$fileOutLoc);
	                        return(&errSbrMsg("failed system 'cp $fileInLoc $fileOutLoc'".
						  $errMsg,$msg)) if (! $Lok);
				 # ******************************
	return(1,"ok $sbrName"); # DONE
    }				 # ******************************

				# --------------------------------------------------
				# read and write
				# --------------------------------------------------
				# open file (old)
    &open_file("$fhinLoc","$fileInLoc")    || return(&errSbr("fileInLoc=$fileInLoc, not opened"));
				# open file (new)
    &open_file("$fhoutLoc",">$fileOutLoc") || return(&errSbr("fileOut=$fileOutLoc, not created"));
	
    $LrdAli=$LrdFin=0; $seq="";
				# ------------------------------
    while (<$fhinLoc>) {	# all before prof: no change
	print $fhoutLoc $_; $rd=$_;
	last if ($_ =~ /^\#\# SEQUENCE PROFILE AND ENTROPY/); 
				# the following to read sequence
	if (! $LrdAli && ($_=~/^\#\# ALI/) ) {
	    $LrdAli=1;		# start of 1st ali section
	    next; }
	if ($LrdAli   && ($_=~/^\#\# ALI/) ) {
	    $LrdFin=1;
	    next; }
	next if (! $LrdAli);	# not started, yet
	next if ($LrdAli && $LrdFin); # finished sequence
	next if ($LrdAli && $_=~/^ Seq/); # skip 
	$seqRd=substr($rd,15,1);
	$seqRd=~s/[a-z]/C/;	# cysteins
	$seq.=$seqRd; 
    }
    @seq=split(//,$seq);	# HSSP sequence

    $ctres=0;			# ------------------------------
    while (<$fhinLoc>) {	# PROFILE => change
	$rd=$_;
	if ($_=~/^(\/|\#)/){	# FINAL
	    print $fhoutLoc $rd;
	    last; }
	if ($_=~/^ SeqNo/) {	# NAMES 
	    print $fhoutLoc $rd;
	    next; }
	++$ctres;		# count residues
	$res=$seq[$ctres];
				# aa = unk: take prof read
	if (! defined $aaLoc{"$res"}){ 
	    print $fhoutLoc $rd; 
	    next; }
				# --------------------
	$rd=~s/\n//g;		# profiles
	$begLine=substr($rd,1, 12);
	$midLine=substr($rd,13,80); $midLine=~s/^\s*|\s*$//g; # purge leading blanks
	$endLine=substr($rd,93);    
	@tmpLine=split(/\s+/,$midLine);
	$prof=join(',',@tmpLine[1..20]);

	($Lok,$msg,$profNew)=
	    &funcAddMatdb2prof($prof,$profTmp{"$res"},$nali,$naliSatLoc);
	                        return(&errSbrMsg("failed on new prof ($prof,".$profTmp{"$res"}
						  .") nali=$nali, sat=$naliSatLoc".
						  $errMsg,$msg)) if (! $Lok);
	$new=      sprintf("%-s",$begLine);
	foreach $tmp (split(/,/,$profNew)) {
	    $new.= sprintf("%4d",int($tmp)); }
	$new.=     sprintf("%-s\n",$endLine);
	print $fhoutLoc $new;
    }
				# ------------------------------
    while (<$fhinLoc>) {	# all after prof (ins): no change
	print $fhoutLoc $; }
    close($fhinLoc);close($fhoutLoc);

				# ------------------------------
				# slim-is-in !
    undef %tmp; undef @tmp;
    return(1,"ok $sbrName");
}				# end of hsspSkewProf

#===============================================================================
sub extract_pdbid_from_hssp {
    local ($idloc) = @_;
    local ($fhssp,$tmp,$id);
    $[=1;
#----------------------------------------------------------------------
#   extract_pdbid_from_hssp     extracts all PDB ids found in the HSSP 0 header
#                               note: existence of HSSP file assumed
#   GLOBAL
#   -  $PDBIDS_IN_HSSP "1acx,2bdy,3cez,"...
#----------------------------------------------------------------------
    $idloc=~tr/[A-Z]/[a-z]/;
    $fhssp="/data/hssp+0/"."$idloc".".hssp";
    if (!-e $fhssp) { 
	print "***  ERROR in sbr extract_pdbid_from_hssp:$fhssp, not existing\n"; exit;}
    &open_file("FHINTMP1", "$fhssp");
    while (<FHINTMP1>) { last if (/^  NR.    ID/); }

    while (<FHINTMP1>) { 
	last if (/^\#\# ALI/);
	$tmp=$_;$tmp=~s/\n//g;
	$id=substr($_,21,4); $id=~tr/[A-Z]/[a-z]/; $id=~s/\s//g;
	if (length($id)>0) {$PDBIDS_IN_HSSP.="$id".",";}
    }
    close (FHINTMP1);return($PDBIDS_IN_HSSP);
}				# end of extract_pdbid_from_hssp

#===============================================================================
sub get_hssp_file { 
    local($fileInLoc,$Lscreen,@dir) = @_ ; 
    local($hssp_file,$dir,$tmp,$chain,$Lis_endless,@dir2);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   get_hssp_file               searches all directories for existing HSSP file
#       in:                     $fileInLoc,$Lscreen,@dir
#       out:                    $file,$chain (sometimes)
#--------------------------------------------------------------------------------
    $#dir2=0;$Lis_endless=0;$chain="";
    foreach $dir(@dir){		# avoid endless loop when calling itself
	if ($dir !~ /is_endless/){push(@dir2,$dir);}else {$Lis_endless=1;}}
    @dir=@dir2;
    
    if ($Lscreen !~ /[01]/){push(@dir,$Lscreen);$Lscreen=0;}
    $hssp_file=$fileInLoc;$hssp_file=~s/\s|\n//g;
    foreach $dir (@dir) {
	$dir=&complete_dir($dir); # add slash at end?
	$tmp="$dir"."$hssp_file"; # try directory
	if ($Lscreen)           { print "--- get_hssp_file: \t trying '$tmp'\n";}
	if (-e $tmp) { $hssp_file=$tmp;
		       last;}
	if ($tmp!~/\.hssp/) {	# missing extension?
	    $tmp.=".hssp";
	    if ($Lscreen)       { print "--- get_hssp_file: \t trying '$tmp'\n";}
	    if (-e $tmp) { $hssp_file=$tmp;
			   last;}}}
    $hssp_file=~s/\s|\n//g;	# security..
    if ( (! -e $hssp_file) && (! $Lis_endless) ) { # still not: cut
	$tmp_file=$fileInLoc; $tmp_file=~s/^([A-Za-z0-9]+).*(\.hssp.*)$/$1$2/g;
	$hssp_file=&get_hssp_file($tmp_file,$Lscreen,"is_endless",@dir); }
    if ( (! -e $hssp_file) && (! $Lis_endless) ) { # still now assume = chain
	$tmp1=substr($fileInLoc,1,4);$chain=substr($fileInLoc,5,1);
	$tmp_file=$fileInLoc; $tmp_file=~s/^($tmp1).*(\.hssp.*)$/$1$2/;
	$hssp_file=&get_hssp_file($tmp_file,$Lscreen,"is_endless",@dir); }
    if (length($chain)>0) {
	return($hssp_file,$chain);}
    else {
	return($hssp_file);}
}				# end of get_hssp_file

#===============================================================================
sub pdbid_to_hsspfile {
    local ($name_in,$dir_hssp,$ext_hssp) = @_; 
    local ($tmp);
    $[=1;
#--------------------------------------------------------------------------------
#   pdbid_to_hsspfile           finds HSSP file for given id (old)
#--------------------------------------------------------------------------------
    if    (length($dir_hssp)==0){ $tmp = "/data/hssp/"; }
    elsif ($dir_hssp =~ /here/) { $tmp = ""; }
    else                        { $tmp = "$dir_hssp"; $tmp=~s/\s|\n//g; }
    if (length($ext_hssp)==0)   { $ext_hssp=".hssp"; }
    $name_in =~ s/\s//g;
    $pdbid_to_hsspfile = "$tmp" . "$name_in" . "$ext_hssp";
}				# end of pdbid_to_hsspfile 

#===============================================================================
sub read_hssp_seqsecacc {
    local ($fh_in, $chain_in, $beg_in, $end_in, $length ) = @_ ;
    local ($Lread, $sbrName);
    local ($tmpchain, $tmpseq, $tmpsecstr, $tmpexp, $tmppospdb, $tmpseq2, $tmpsecstr2);
    $[=1;
#----------------------------------------------------------------------
#   read_hssp_seqsecacc          reads sequence, secondary str and acc from HSSP file
#                               (file expected to be open handle = $fh_in).  
#                               The reading is restricted by:
#                                  chain_in, beg_in, end_in, 
#                               which are passed in the following manner:
#                               (say chain = A, begin = 2 (PDB pos), end = 10 (PDB pos):
#                                  "A 2 10"
#                               Wild cards allowed for any of the three.
#       in:                     file_handle, chain, begin, end
#       out:                    SEQHSSP, SECHSSP, ACCHSSP, PDBPOS
#       out GLOBAL:             all output stuff is assumed to be global
#----------------------------------------------------------------------
    $sbrName = "read_hssp_seqsecacc" ;

#----------------------------------------
#   setting to zero
#----------------------------------------
    $#SEQHSSP=$#SECHSSP=$#ACCHSSP=$#PDBPOS=0; 

#----------------------------------------
#   extract input
#----------------------------------------
    if ( ! defined $chain_in ){$chain_in="*";}else{$chain_in=~tr/[a-z]/[A-Z]/;}
    if ( ! defined $beg_in )  {$beg_in= "*" ; }
    if ( ! defined $end_in )  {$end_in= "*" ; }
    $fh_in=~s/\s//g; $chain_in=~s/\s//g; $beg_in=~s/\s//g; $end_in=~s/\s//g; 
#--------------------------------------------------
#   read in file
#--------------------------------------------------

#   skip anything before data...
    while ( <$fh_in> ) { last if ( /^\#\# ALIGNMENTS/ ); }
#   read sequence
    $Lfirst=1;
    while ( <$fh_in> ) {
	$Lread=0;
	if ( ! / SeqNo / ) { 
	    $Lread=1;
	    last if ( /^\#\# / ) ;
	    $tmpchain = substr($_,13,1); 
	    $tmppospdb= substr($_,8,4); $tmppospdb=~s/\s//g;
#        check chain
	    if ( ($tmpchain ne "$chain_in") && ($chain_in ne "*") ) { $Lread=0; }
#        check begin
	    if ( $beg_in ne "*" ) {
		if ( $tmppospdb < $beg_in ) { $Lread=0; } }
	    elsif ( $Lfirst && ($end_in eq "*") && (defined $length) ) {
		$end_in=($tmppospdb+$length);}
	    $Lfirst=0;
#        check end
	    if ( $end_in ne "*" ) {
		if ( $tmppospdb > $end_in ) { $Lread=0; }}}
	if ($Lread) {
	    $tmpseq    = substr($_,15,1);
	    $tmpsecstr = substr($_,18,1);
	    $tmpexp    = substr($_,37,3);
#        lower case letter to C
	    $tmpseq2 = $tmpseq;
	    if ($tmpseq2 =~ /[a-z]/) { $tmpseq2 = "C"; }

#        convert secondary structure to 3
	    &secstr_convert_dsspto3($tmpsecstr);
	    $tmpsecstr2= $secstr_convert_dsspto3;
#        consistency check
	    if ( ($tmpseq2 !~ /[A-Z]/) && ($tmpseq2 !~ /!/) ) { 
		print "*** $sbrName: ERROR: $fileInLoc \n";
		print "*** small cap sequence: $tmpseq2 ! exit 15-11-93b \n" , "$_"; 
		exit; }
	    push(@SEQHSSP,$tmpseq); push(@SECHSSP,$tmpsecstr2); push(@ACCHSSP,$tmpexp);
	    push(@PDBPOS,$tmppospdb);}}
}                               # end of: read_hssp_seqsecacc 

1;
