##!/usr/bin/perl -w
##!/usr/pub/bin/perl5
##------------------------------------------------------------------------------#
#	Copyright				May,    	1998	       #
#	Burkhard Rost		rost@LION-ag.de,rost@EMBL-heidelberg.de	       #
#	Wilckensstr. 15		http://www.embl-heidelberg.de/~rost/	       #
#	D-69120 Heidelberg						       #
#				version 2.0   	May,    	1998	       #
#------------------------------------------------------------------------------#
#  
#  all lib-ut needed to run PHD (hopefully)
#  
#  in case routines are missing: search through lib-ut.pl
#  
# 
# -----------------------------------------------------------------------------# 
#                               ---------------------
#   lib-phd-br                  internal subroutines:
#                               ---------------------
# 
#                               ---------------------
#   lib-col                     internal subroutines:
#                               ---------------------
# 
#   bynumber                    function sorting list by number
#   bynumber_high2low           function sorting list by number (start with high)
#   complete_dir                
#   completeDir                 
#   convHssp2msf                runs convert_seq for HSSP -> MSF
#   convMsf2Hssp                converts the MSF into an HSSP file
#   dsspGetFile                 searches all directories for existing DSSP file
#   dsspGetFileLoop             loops over all directories
#   exposure_normalise_prepare  normalisation weights (maximal: Schneider, Dipl)
#   exposure_normalise          normalise DSSP accessibility with maximal values
#   exposure_project_1digit     1
#   errSbr                      simply writes '*** ERROR $sbrName: $txtInLoc'
#   errSbrMsg                   simply writes '*** ERROR $sbrName: $txtInLoc\n'.$msg
#   fctRunTimeLeft              estimates the time the job still needs to run
#   fctSeconds2time             converts seconds to hours:minutes:seconds
#   fsspGetFile                 searches all directories for existing FSSP file
#   fsspGetFileLoop             loops over all directories
#   getFileFormat               returns format of file
#   getFileFormatQuick          quick scan for file format: assumptions
#   getPhdSubset                subset from string with PHDsec|acc|htm + rel index
#   get_id                      extracts an identifier from file name
#   hsspGetChain                extracts all chain identifiers in HSSP file
#   hsspGetFile                 searches all directories for existing HSSP file
#   hsspGetFileLoop             loops over all directories
#   hsspRdAli                   reads and writes the sequence of HSSP + 70 alis
#   hsspRdHeader                reads a HSSP header
#   hsspRdSeqSecAcc             reads the HSSP seq/sec/acc from ifir to ilas
#   hsspRdSeqSecAccOneLine      reads begin of one HSSP line
#   is_chain                    checks whether or not a PDB chain
#   is_dssp                     checks whether or not file is in DSSP format
#   is_dssp_list                checks whether or not file is a list of DSSP files
#   is_fssp                     checks whether or not file is in FSSP format
#   is_fssp_list                1
#   is_hssp                     checks whether or not file is in HSSP format
#   is_hssp_empty               checks whether or not HSSP file has NALIGN=0
#   is_hssp_list                checks whether or not file contains a list of HSSP files
#   is_list                     returns 1 if list of existing files
#   is_nndb_rdb                 
#   is_nninFor                  is input for FORTRAN input
#   is_odd_number               checks whether number is odd
#   is_pdbid                    checks whether or not id is a valid PDBid (number 3 char)
#   is_pdbid_list               checks whether id is list of valid PDBids (number 3 char)
#   is_ppcol                    checks whether or not file is in RDB format
#   is_rdb                      checks whether or not file is in RDB format
#   is_rdbf                     checks whether or not file is in RDB format
#   is_rdb_acc                  checks whether or not file is in RDB format from PHDacc
#   is_rdb_htm                  checks whether or not file is in RDB format from PHDhtm
#   is_rdb_htmref               checks whether or not file is RDB from PHDhtm_ref
#   is_rdb_htmtop               checks whether or not file is RDB from PHDhtm_top
#   is_rdb_nnDb                 checks whether or not file is in RDB format for NN.pl
#   is_rdb_sec                  checks whether or not file is RDB from PHDsec
#   is_strip                    checks whether or not file is in HSSP-strip format
#   is_strip_list               checks whether or not file contains a list of HSSPstrip files
#   is_strip_old                checks whether file is old strip format
#   is_swissprot                
#   is_swissid                  1
#   is_swissid_list             1
#   isDaf                       checks whether or not file is in DAF format
#   isDafGeneral                checks (and finds) DAF files
#   isDafList                   checks whether or not file is list of Daf files
#   isDsspGeneral               checks (and finds) DSSP files
#   isFasta                     checks whether or not file is in FASTA format 
#   isFastaMul                  checks whether more than 1 sequence in FASTA found
#   isFsspGeneral               checks (and finds) FSSP files
#   isGcg                       checks whether or not file is in Gcg format (/# SAF/)
#   isHelp                      returns 1 if : help,man,-h
#   isHsspGeneral               checks (and finds) HSSP files
#   isMsf                       checks whether or not file is in MSF format
#   isMsfGeneral                checks (and finds) MSF files
#   isMsfList                   checks whether or not file is list of Msf files
#   isPhdAcc                    checks whether or not file is in MSF format
#   isPhdHtm                    checks whether or not file is in MSF format
#   isPhdSec                    checks whether or not file is in MSF format
#   isPir                       checks whether or not file is in Pir format 
#   isPirMul                    checks whether or not file contains many sequences 
#   isRdb                       checks whether or not file is in RDB format
#   isRdbGeneral                checks (and finds) RDB files
#   isRdbList                   checks whether or not file is list of Rdb files
#   isSaf                       checks whether or not file is in SAF format (/# SAF/)
#   isSwiss                     checks whether or not file is in SWISS-PROT format (/^ID   /)
#   isSwissGeneral              checks (and finds) SWISS files
#   isSwissList                 checks whether or not file is list of Swiss files
#   msfWrt                      writing an MSF formatted file of aligned strings
#   myprt_empty                 writes line with '--- \n'
#   myprt_line                  prints a line with 70 '-'
#   myprt_npoints               writes line with N dots of the form '....,....1....,....2' 
#   myprt_txt                   adds '---' and '\n' for writing text
#   open_file                   opens file, writes warning asf
#   phdAliWrt                   converts PHD.rdb to SAF format (including ali)
#   phdHtmIsit                  returns best HTM
#   phdHtmGetBest               returns position (begin) and average val for best HTM
#   phdRdbMerge                 manages merging two PHD *.rdb files ('name'= acc + sec + htm)
#   phdRdbMergeDef              sets defaults for phdRdbMerg
#   phdRdbMergeDo               merging two PHD *.rdb files ('name'= acc + sec)
#   phdRdbMergeHdr              writes the merged RDB header
#   phdRun                      runs all 3 FORTRAN programs PHD
#   phdRun1                     runs the FORTRAN program PHD once (sec XOR acc XOR htm) 
#   phdRunIniFileNames          assigns names to intermediate files for FORTRAN PHD
#   phdRunPost1                 
#   phdRunWrt                   merges 2-3 RDB files (sec,acc,htm?)
#   rdRdbAssociative            reads content of an RDB file into associative array
#   rdRdbAssociativeNum         reads from a file of Michael RDB format:
#   rd_rdb_associative          reads the content of an RDB file into an associative
#   rdbphd_to_dotpred           converts RDB files of PHDsec,acc,htm (both/3)
#   rdbphd_to_dotpred_getstring transform $rdb{"osec","1..n"} to $STRING{"osec"}
#   rdbphd_to_dotpred_getsubset assigns subsets:
#   rdbphd_to_dotpred_head_htmtop writes the header for htmtop
#   read_rdb_num                reads from a file of Michael RDB format:
#   read_rdb_num2               reads from a file of Michael RDB format:
#   run_program                 1
#   safWrt                      writing an SAF formatted file of aligned strings
#   sysCpfile                   system call '\\cp file1 file2' (or to dir)
#   sysDate                     returns $Date
#   sysMvfile                   system call '\\mv file'
#   sysRunProg                  pipes arguments into $prog, and cats the output
#   swissGetFile                
#   wrt_phdpred_from_string     write body of PHD.pred files from global array %STRING{}
#   wrt_phdpred_from_string_htm body of PHD.pred files from global array %STRING{} for HTM
#   wrt_phdpred_from_string_htm_header 
#   wrt_phdpred_from_string_htmHdr writes the header for PHDhtm ref and top
# 
# -----------------------------------------------------------------------------# 
#                               ---------------------
#   lib-col                     external subroutines:
#                               ---------------------
# 
#   call from system:            
#                               echo '$tmpWrt' >> stat-htm-glob.tmp
#                               echo '$tmpWrt' >> stat-htm-htm.tmp
# 
#   call from missing:           
#                               ctime
#                               localtime
#                               phd_htmfil
#                               phd_htmref
#                               phd_htmtop
# 
# 
# -----------------------------------------------------------------------------# 
# 
#===============================================================================
sub bynumber { 
#-------------------------------------------------------------------------------
#   bynumber                    function sorting list by number
#-------------------------------------------------------------------------------
    $a<=>$b; 
}				# end of bynumber

#===============================================================================
sub bynumber_high2low { 
#-------------------------------------------------------------------------------
#   bynumber_high2low           function sorting list by number (start with high)
#-------------------------------------------------------------------------------
    $b<=>$a; 
}				# end of bynumber_high2low

#==============================================================================
sub complete_dir { return(&completeDir(@_)); } # alias


#===============================================================================
sub completeDir {local($DIR)=@_; $[=1 ; 
		 return(0) if (! defined $DIR);
		 return($DIR) if ($DIR =~/\/$/);
		 return($DIR."/");} # end of completeDir

#==============================================================================
sub convHssp2msf {
    local($exeConvLoc,$file_in_loc,$file_out_loc,$fhErrSbr)=@_;
    local($form_out,$an,$command);
#----------------------------------------------------------------------
#   convHssp2msf                runs convert_seq for HSSP -> MSF
#       in:                     $exeConvLoc,$file_in_loc,$file_out_loc,$fhErrSbr
#       in:                     FORTRAN file.hssp, file.msf (name output), errorHandle
#       out:                    fileHssp (written by convert_seq)
#       err:                    ok=(1,'ok'), err=(0,'msg')
#----------------------------------------------------------------------
    $sbrName="lib-br:convHssp2msf";
    $fhErrSbr="STDOUT"                                if (! defined $fhErrSbr);
    return(0,"*** $sbrName: not def exeConvLoc!")     if (! defined $exeConvLoc);
    return(0,"*** $sbrName: not def file_in_loc!")    if (! defined $file_in_loc);
    return(0,"*** $sbrName: not def file_out_loc!")   if (! defined $file_out_loc);
				# check existence of files
    return(0,"*** $sbrName: miss file=$file_in_loc!") if (! -e $file_in_loc);
    return(0,"*** $sbrName: miss exe =$exeConvLoc!")  if (! -e $exeConvLoc);
				# ------------------------------
				# input for fortran program
    $form_out= 	 "M";
    $an=         "N";
    $command=    "";
				# --------------------------------------------------
				# call fortran 
    eval "\$command=\"$exeConvLoc,$file_in_loc,$form_out,$an,$file_out_loc,$an,$an\"";
    $Lok=&run_program("$command" ,"$fhErrSbr","warn");

#    $command="echo '$file_in_loc\n".
#	"$form_out\n"."$an\n"."$file_out_loc\n"."$an\n"."$an\n".
#	    "' | $exeConvLoc";
#    $fhErrSbr=`$command`;

    return(0,"*** $sbrName ERROR: no output $file_out_loc ($exeConvLoc,$file_in_loc)\n")
	if (!$Lok || (! -e $file_out_loc));
    return(1,"$sbrName ok");
}				# end of convHssp2msf

#==============================================================================
sub convMsf2Hssp {
    local($fileMsfLoc,$fileHsspLoc,$fileCheck,$exeConvLoc,$matGCG,$fhErrSbrx) = @_ ;
    local($sbrName,$Lok,$fhinLoc,$form_out,$an,$command);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   convMsf2Hssp                converts the MSF into an HSSP file
#       in:                     fileMsf, fileHssp(output), exeConv (convert_seq), matGCG
#       out:                    fileHssp (written by convert_seq)
#       err:                    ok=(1,'ok'), err=(0,'msg')
#--------------------------------------------------------------------------------
    $sbrName="lib-br:convMsf2Hssp";$fhinLoc="FHIN"."$sbrName";
				# check definitions
    return(0,"*** $sbrName: not def fileMsfLoc!")  if (! defined $fileMsfLoc);
    return(0,"*** $sbrName: not def fileHsspLoc!") if (! defined $fileHsspLoc);
    return(0,"*** $sbrName: not def fileCheck!")   if (! defined $fileCheck);
    return(0,"*** $sbrName: not def exeConvLoc!")  if (! defined $exeConvLoc);
    return(0,"*** $sbrName: not def matGCG!")      if (! defined $matGCG);
    $fhErrSbrx="STDOUT"                            if (! defined $fhErrSbrx);
				# check existence of files
    return(0,"*** $sbrName: miss input file '$fileMsfLoc'!") if (! -e $fileMsfLoc);
    return(0,"*** $sbrName: miss input exe  '$exeConvLoc'!") if (! -e $exeConvLoc);
    return(0,"*** $sbrName: miss input file '$matGCG'!")     if (! -e $matGCG);
    $msgHere="";
				# ------------------------------
				# input for fortran program
    $form_out= "H";		# output format
    $an=       "N";		# answers: (1)=treat gaps? (2)=other formats
    $command=  "";		# the empty one: which one is guide (return for default)

				# --------------------------------------------------
				# call fortran 
    eval "\$command=\"$exeConvLoc, $fileMsfLoc, $form_out,$matGCG,$an,$fileHsspLoc, ,$an \"";
    $Lok=&run_program("$command" ,$fhErrSbrx,"die");

#    $command="echo '$fileMsfLoc\n$form_out\n$matGCG\n$an\n$fileHsspLoc\n \n$an\n' | $exeConvLoc";
#    $fhErrSbrx=`$command`;
				# --------------------------------------------------
    if (! -e $fileHsspLoc){	# check existence (and emptiness) of HSSP file
	$msg= "*** ERROR $sbrName \t '$fileHsspLoc' converted HSSP file missing\n";
	return(0,"$msg");}	# **************************************************
				# check existence (and emptiness) of HSSP file
    if (&is_hssp_empty($fileHsspLoc)){
	$msg="*** ERROR $sbrName \t '$fileHsspLoc' converted HSSP file empty\n";
	return(0,"$msg");}	# **************************************************

				# --------------------------------------------------
                                # reconvert MSF -> HSSP
				# --------------------------------------------------
    $msgHere.="$sbrName: reconverting HSSP ($fileHsspLoc) -> MSF for check\n";
    ($Lok,$msg)=
	&convHssp2msf($exeConvLoc,$fileHsspLoc,$fileCheck);

    if (!$Lok || (! -e $fileHsspLoc)){
	$msgHere.="$msg";
	return(0,"$msgHere");}	# **************************************************

				# --------------------------------------------------
                                # comparing the two files
    open(FILE1,$fileMsfLoc)  ||  warn "-*- $sbrName: cannot open 1 $fileMsfLoc: $!\n";
    open(FILE2,$fileCheck)   ||  warn "-*- $sbrName: cannot open 1 $fileCheck: $!\n";
    $#ali1=$#ali2=0;
                                # ----------------------------------------
    while( <FILE1> ) {		# read file1
	last if ($_=~/^.+\/\// ); }
    while( <FILE1> ) {
	if ($_=~/[a-zA-Z]/ ) {($litter,$alignment)= split (' ',$_,2);
			      $alignment=~ s/[\s]//g;
			      push (@ali1,$alignment); }}close (FILE1); 
                                # ----------------------------------------
    while( <FILE2> ) {		# read file2
	last if ($_=~/^.+\/\/+/ ); }
    while( <FILE2> ) {
	if ($_=~/[a-zA-Z]/ ) {($litter,$alignment)= split (' ',$_,2);
			      $alignment=~ s/[\s]//g; $alignment =~ s/\*/\./g;
			      push (@ali2,$alignment); } } close (FILE2);
    $iter=$count_error=0;	# ----------------------------------------
    foreach $i (@ali1) {	# compare line by line
	++$iter;
	$tmp1= substr($i,2,(length($i)-2));
	$tmp1=~ tr/\*/\./;
	if ( $tmp1 !~ /[^acdefghiklmnopqrstvwxyACDEFGHIKLMNOPQRSTVWXY]/ ) {
	    $tmp2= $ali2[$iter];
	    $tmp2=~ tr/\*/\./; $tmp2 =~ tr/\(|\)/ /;
	    $tmp2=~ s/(.*)$tmp1(.*)/$1$2/;
	    if ( length($tmp2) gt 3 ) {
		++$count_error;
		$msgHere.="*** $sbrName ERROR: during re-converting comparison\n".
		    "tmp2=$tmp2,count_error=$count_error\n";}}}
    if ( $count_error gt 3 ) {
	$msgHere.="conversion: MSF -> HSSP failed, \n".$msgHere;
	return(0,"$msgHere"); }
    return(1,"$sbrName ok");
}				# end convMsf2hssp

#===============================================================================
sub dsspGetFile { 
    local ($fileInLoc,$Lscreen,@dir) = @_ ; 
    local ($fileDssp,$dir,$tmp,$chainLoc,@dir2,$idLoc);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   dsspGetFile                 searches all directories for existing DSSP file
#       in:                     $file,$Lscreen,@dir
#       out:                    returned file,chain ($dssp,$chain), (if chain in file)
#       watch:                  loop onto itself:
#                               1prcH.dssp not found -> try 1prc.dssp
#--------------------------------------------------------------------------------
    $#dir2=$Lok=0;
    return(0,"no input file")   if (! defined $fileInLoc);
    $chainLoc="";$idLoc=$fileInLoc;$idLoc=~s/^.*\///g;
    $#dir=0                     if (! defined @dir);
    $Lscreen=0                  if (! defined $Lscreen);
    if (-d $Lscreen) { 
	@dir=($Lscreen,@dir);
	$Lscreen=0;}
    $dsspFileTmp=$fileInLoc;$dsspFileTmp=~s/\s|\n//g;
				# ------------------------------
				# is DSSP ok
    return($dsspFileTmp," ")    if (-e $dsspFileTmp && &is_dssp($dsspFileTmp));

				# ------------------------------
				# purge chain?
    if ($dsspFileTmp=~/^(.*\.dssp)_?([A-Za-z0-9])$/){
	$file=$1; $chain=$2;
	return($file,$chain)    if (-e $file && &is_dssp($file)); }

				# ------------------------------
				# try adding directories

    foreach $dir(@dir){		# avoid endless loop when calling itself
	$Lok=1                  if ($dir =~ /\/data\/dssp/);
	push(@dir2,$dir);}
    @dir=@dir2;  push(@dir,"/data/dssp/") if (!$Lok); # give default

				# loop over all directories
    $fileDssp=
	&dsspGetFileLoop($dsspFileTmp,$Lscreen,@dir);

				# ------------------------------
    if ( ! -e $fileDssp ) {	# still not: dissect into 'id'.'chain'
	$tmp_file=$fileInLoc; $tmp_file=~s/^([A-Za-z0-9]+).*(\.dssp.*)$/$1$2/g;
	$fileDssp=
	    &dsspGetFileLoop($tmp_file,$Lscreen,@dir);}

				# ------------------------------
				# change version of file (1sha->2sha)
    if ( ! -e $fileDssp) {
	$tmp1=substr($idLoc,2,3);
	foreach $it (1..9) {
	    $tmp_file=$it."$tmp1".".dssp";
	    $fileDssp=
		&dsspGetFileLoop($tmp_file,$Lscreen,@dir);}}
    return (0)                  if ( ! -e $fileDssp);

    return($fileDssp,$chainLoc);
}				# end of dsspGetFile

#===============================================================================
sub dsspGetFileLoop { 
    local ($fileInLoop,$Lscreen,@dir) = @_ ; 
    local ($fileOutLoop,$dir,$tmp);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   dsspGetFileLoop             loops over all directories
#       in:                     $file,$Lscreen,@dir
#       out:                    returned file
#--------------------------------------------------------------------------------
				# already ok 
    return($fileInLoop)         if (&is_dssp($fileInLoop));
				# missing extension
    $fileInLoop.=".dssp"        if ($fileInLoop !~ /\.dssp/);
				# already ok 
    return($fileInLoop)         if (&is_dssp($fileInLoop));
				# do NOT continue if starting with dir!!
    return(0)                   if ($fileInLoop =~ /^\//);

				# ------------------------------
    foreach $dir (@dir) {	# search through dirs
	$tmp=&complete_dir($dir) . $fileInLoop; # try directory
	print "--- dsspGetFileLoop: \t trying '$tmp'\n" if ($Lscreen);
	return($tmp)            if (-e $tmp && &is_dssp($tmp) );
    }
    return(0);			# none found
}				# end of dsspGetFileLoop

#==========================================================================
sub exposure_normalise_prepare {
    local ($mode) = @_;
    $[=1;
#----------------------------------------------------------------------
#   exposure_normalise_prepare  normalisation weights (maximal: Schneider, Dipl)
#----------------------------------------------------------------------
#   --------------------------------------------------
#   Reinhard
#   --------------------------------------------------
    if ((!defined $mode)||(length($mode) <= 1)) {
	$NORM_EXP{"A"} =106;  $NORM_EXP{"B"} =160;         # D or N
	$NORM_EXP{"C"} =135;  $NORM_EXP{"D"} =163;  $NORM_EXP{"E"} =194;
	$NORM_EXP{"F"} =197;  $NORM_EXP{"G"} = 84;  $NORM_EXP{"H"} =184;
	$NORM_EXP{"I"} =169;  $NORM_EXP{"K"} =205;  $NORM_EXP{"L"} =164;
	$NORM_EXP{"M"} =188;  $NORM_EXP{"N"} =157;  $NORM_EXP{"P"} =136;
	$NORM_EXP{"Q"} =198;  $NORM_EXP{"R"} =248;  $NORM_EXP{"S"} =130;
	$NORM_EXP{"T"} =142;  $NORM_EXP{"V"} =142;  $NORM_EXP{"W"} =227;
	$NORM_EXP{"X"} =180;         # undetermined (deliberate)
	$NORM_EXP{"Y"} =222;  $NORM_EXP{"Z"} =196;         # E or Q

#   --------------------------------------------------
#   maximal 3 Angstrom water
#   --------------------------------------------------
    } elsif ($mode =~ /3ang/ ) {
	$NORM_EXP{"A"} =179;  $NORM_EXP{"B"} =255;         # D or N
	$NORM_EXP{"C"} = 99;  $NORM_EXP{"D"} =249;  $NORM_EXP{"E"} =279;
	$NORM_EXP{"F"} =199;  $NORM_EXP{"G"} =169;  $NORM_EXP{"H"} =219;
	$NORM_EXP{"I"} =189;  $NORM_EXP{"K"} =309;  $NORM_EXP{"L"} =209;
	$NORM_EXP{"M"} =189;  $NORM_EXP{"N"} =259;  $NORM_EXP{"P"} =189;
	$NORM_EXP{"Q"} =259;  $NORM_EXP{"R"} =299;  $NORM_EXP{"S"} =209;
	$NORM_EXP{"T"} =209;  $NORM_EXP{"V"} =189;  $NORM_EXP{"W"} =239;
	$NORM_EXP{"X"} =200;         # undetermined (deliberate)
	$NORM_EXP{"Y"} =239;  $NORM_EXP{"Z"} =269;         # E or Q

#   --------------------------------------------------
#   maximal 5 Angstrom water
#   --------------------------------------------------
    } elsif ($mode =~ /5ang/ ) {
	$NORM_EXP{"A"} =209;  $NORM_EXP{"B"} =295;         # D or N
	$NORM_EXP{"C"} =139;  $NORM_EXP{"D"} =289;  $NORM_EXP{"E"} =349;
	$NORM_EXP{"F"} =199;  $NORM_EXP{"G"} =219;  $NORM_EXP{"H"} =229;
	$NORM_EXP{"I"} =189;  $NORM_EXP{"K"} =399;  $NORM_EXP{"L"} =239;
	$NORM_EXP{"M"} =189;  $NORM_EXP{"N"} =299;  $NORM_EXP{"P"} =189;
	$NORM_EXP{"Q"} =309;  $NORM_EXP{"R"} =309;  $NORM_EXP{"S"} =259;
	$NORM_EXP{"T"} =239;  $NORM_EXP{"V"} =189;  $NORM_EXP{"W"} =259;
	$NORM_EXP{"X"} =230;         # undetermined (deliberate)
	$NORM_EXP{"Y"} =259;  $NORM_EXP{"Z"} =329;         # E or Q

#   --------------------------------------------------
#   maximal 0.7 Angstrom water
#   --------------------------------------------------
    } elsif ($mode =~ /07ang/ ) {
	$NORM_EXP{"A"} =119;  $NORM_EXP{"B"} =169;         # D or N
	$NORM_EXP{"C"} = 99;  $NORM_EXP{"D"} =169;  $NORM_EXP{"E"} =179;
	$NORM_EXP{"F"} =169;  $NORM_EXP{"G"} =109;  $NORM_EXP{"H"} =173;
	$NORM_EXP{"I"} =159;  $NORM_EXP{"K"} =206;  $NORM_EXP{"L"} =159;
	$NORM_EXP{"M"} =159;  $NORM_EXP{"N"} =169;  $NORM_EXP{"P"} =149;
	$NORM_EXP{"Q"} =169;  $NORM_EXP{"R"} =209;  $NORM_EXP{"S"} =139;
	$NORM_EXP{"T"} =149;  $NORM_EXP{"V"} =149;  $NORM_EXP{"W"} =169;
	$NORM_EXP{"X"} =230;         # undetermined (deliberate)
	$NORM_EXP{"Y"} =189;  $NORM_EXP{"Z"} =175;         # E or Q

#   --------------------------------------------------
#   RS (X=0, from Reinhard
#   --------------------------------------------------
    } elsif ($mode =~/RS/) {
	$NORM_EXP{"A"} =106;  $NORM_EXP{"B"} =157;         # D or N
	$NORM_EXP{"C"} =135;  $NORM_EXP{"D"} =163;  $NORM_EXP{"E"} =194;
	$NORM_EXP{"F"} =197;  $NORM_EXP{"G"} = 84;  $NORM_EXP{"H"} =184;
	$NORM_EXP{"I"} =169;  $NORM_EXP{"K"} =205;  $NORM_EXP{"L"} =164;
	$NORM_EXP{"M"} =188;  $NORM_EXP{"N"} =157;  $NORM_EXP{"P"} =136;
	$NORM_EXP{"Q"} =198;  $NORM_EXP{"R"} =248;  $NORM_EXP{"S"} =130;
	$NORM_EXP{"T"} =142;  $NORM_EXP{"V"} =142;  $NORM_EXP{"W"} =227;
	$NORM_EXP{"X"} =180;         # undetermined (deliberate)
	$NORM_EXP{"Y"} =222;  $NORM_EXP{"Z"} =194;         # E or Q

#   --------------------------------------------------
#   Reinhard
#   --------------------------------------------------
    } else {
	$NORM_EXP{"A"} =106;  $NORM_EXP{"B"} =160;         # D or N
	$NORM_EXP{"C"} =135;  $NORM_EXP{"D"} =163;  $NORM_EXP{"E"} =194;
	$NORM_EXP{"F"} =197;  $NORM_EXP{"G"} = 84;  $NORM_EXP{"H"} =184;
	$NORM_EXP{"I"} =169;  $NORM_EXP{"K"} =205;  $NORM_EXP{"L"} =164;
	$NORM_EXP{"M"} =188;  $NORM_EXP{"N"} =157;  $NORM_EXP{"P"} =136;
	$NORM_EXP{"Q"} =198;  $NORM_EXP{"R"} =248;  $NORM_EXP{"S"} =130;
	$NORM_EXP{"T"} =142;  $NORM_EXP{"V"} =142;  $NORM_EXP{"W"} =227;
	$NORM_EXP{"X"} =180;         # undetermined (deliberate)
	$NORM_EXP{"Y"} =222;  $NORM_EXP{"Z"} =196;         # E or Q
    }
}				# end of exposure_normalise_prepare 

#===============================================================================
sub exposure_normalise {
    local ($exp_in, $aa_in) = @_;
    $[=1;
#----------------------------------------------------------------------
#   exposure_normalise          normalise DSSP accessibility with maximal values
#                               (taken from Schneider)
#----------------------------------------------------------------------
    if ( $aa_in !~ /[ABCDEFGHIKLMNPQRSTUVWXYZ]/ ) {
	if ( $aa_in=~/[!.]/ ) { $aa_in = "X"; }
	else { print "*** ERROR in exposure_normalise: aa passed wrong: '$aa_in' \n";
	       exit; }}

    if ($NORM_EXP{$aa_in}>0) { $exp_normalise= 100 * ($exp_in / $NORM_EXP{$aa_in});}
    else { print "*** \n*** exposure_normalise, division by zero:aa=$aa_in,acc=$exp_in,norm=",
	   $NORM_EXP{$aa_in},"\n***\n";
	   $exp_normalise=$exp_in/1.8; # ugly ...
	   if ($exp_normalise>100){$exp_normalise=100;}}
    return $exp_normalise;
}				# end of exposure_normalise

#===============================================================================
sub exposure_project_1digit {
    local ($exp_in) = @_;
    local ($exp_out);
    $[=1;
#----------------------------------------------------------------------
#   exposure_project_1digi      project relative exposure (relative) onto numbers 0-9
#                               by: n = max ( 9 , int(sqrt (rel_exp)) )
#----------------------------------------------------------------------
    if ( $exp_in < 0 ) {        # check input
        print "*** ERROR exposure_project_1digit: exposure in = $exp_in \n"; 
	exit;}
    $exp_out = int ( sqrt ($exp_in) );
                                # limit to 9
    if ( $exp_out >= 10 ) { $exp_out = 9; }
    $exposure_project_1digit = $exp_out;
    return($exp_out);
}				# end of exposure_project_1digit

#==============================================================================
sub errSbr    {local($txtInLoc,$sbrNameLocy) = @_ ;
#-------------------------------------------------------------------------------
#   errSbr                      simply writes '*** ERROR $sbrName: $txtInLoc'
#-------------------------------------------------------------------------------
	       $sbrNameLocy=$sbrName if (! defined $sbrNameLocy);
	       $txtInLoc.="\n";
	       $txtInLoc=~s/\n\n+/\n/g;
	       return(0,"*** ERROR $sbrNameLocy: $txtInLoc");
}				# end of errSbr

#==============================================================================
sub errSbrMsg {local($txtInLoc,$msgInLoc,$sbrNameLocy) = @_ ;
#-------------------------------------------------------------------------------
#   errSbrMsg                   simply writes '*** ERROR $sbrName: $txtInLoc\n'.$msg
#-------------------------------------------------------------------------------
	       $sbrNameLocy=$sbrName if (! defined $sbrNameLocy);
	       $txtInLoc.="\n";
	       $txtInLoc=~s/\n\n+/\n/g;
	       $msgInLoc.="\n";
	       $msgInLoc=~s/\n\n+/\n/g;
	       return(0,"*** ERROR $sbrNameLocy: $txtInLoc".$msgInLoc);
}				# end of errSbrMsg

#===============================================================================
sub fctRunTimeLeft {
    local($timeBegLoc,$num_to_run,$num_did_run) = @_ ;
    local($sbrName);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   fctRunTimeLeft              estimates the time the job still needs to run
#       in:                     $timeBegLoc : time (time) when job began
#       in:                     $num_to_run : number of things to do
#       in:                     $num_did_run: number of things that are done, so far
#       out:                    $_string_time-still (hour:min:sec)
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."fctRunTimeLeft";

    $timeNow=time;
    $timeRun=$timeNow-$timeBegLoc;

    $percLoc=0;
    $percLoc=100*($num_did_run/$num_to_run) if ($num_to_run > 0);

    if ($percLoc) {
	$timeTot=int(100*($timeRun/$percLoc));
	$timeLeft=$timeTot-$timeRun;
	$tmp=&fctSeconds2time($timeLeft); 
	@tmp=split(/:/,$tmp); foreach $tmp (@tmp){$tmp=~s/^0//g;}
	$estimateLoc= "";
	$estimateLoc.=$tmp[1]." h "   if ($tmp[1] > 0);
	$estimateLoc.=$tmp[2]." min " if ($tmp[2] > 0);
	$estimateLoc.=$tmp[3]." sec " if ($tmp[3] > 0);
	$estimateLoc= "done"         if (length($estimateLoc) < 1);}
    else {
	$estimateLoc="?";}
    return($estimateLoc);
}				# end of fctRunTimeLeft

#==============================================================================
sub fctSeconds2time {
    local($secIn) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   fctSeconds2time             converts seconds to hours:minutes:seconds
#       in:                     seconds
#       out:                    05:13:50
#-------------------------------------------------------------------------------
    $sbrName="lib-comp:"."fctSeconds2time";$fhinLoc="FHIN"."$sbrName";
    $minTmp=  int($secIn/60);
    $seconds= ($secIn - $minTmp*60);
    $hours=   int($minTmp/60);
    $minutes= ($minTmp - $hours*60);
    $seconds="0".$seconds if (length($seconds)==1);
    $minutes="0".$minutes if (length($minutes)==1);
    $hours=  "0".$hours   if (length($hours)==1);
    return("$hours".":".$minutes.":".$seconds);
}				# end of fctSeconds2time

#===============================================================================
sub fsspGetFile { 
    local ($fileInLoc,$Lscreen,@dir) = @_ ; 
    local ($fileFssp,$dir,$tmp,$chain,@dir2,$idLoc,$fileHssp,$chainHssp,$it,@chainHssp);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   fsspGetFile                 searches all directories for existing FSSP file
#       in:                     $file,$Lscreen,@dir
#       out:                    returned file,chain ($fssp,$chain), (if chain in file)
#       watch:                  loop onto itself:
#                               1prcH.fssp not found -> try 1prc.fssp
#--------------------------------------------------------------------------------
    $#dir2=$Lok=0;$chain="";$idLoc=$fileInLoc;$idLoc=~s/^.*\///g;
    foreach $dir(@dir){		# avoid endless loop when calling itself
	if ($dir =~ /\/data\/fssp/) { $Lok=1;}
	push(@dir2,$dir);}
    @dir=@dir2;  if (!$Lok){push(@dir,"/data/fssp/");} # give default
    
    if    (! defined $Lscreen){$Lscreen=0;}
    elsif ($Lscreen !~ /[01]/){push(@dir,$Lscreen);$Lscreen=0;}
    $title=$fileInLoc;$title=~s/^.*\/|\.fssp.*$//g;
    $fsspFileTmp=$fileInLoc;$fsspFileTmp=~s/\s|\n//g;
				# loop over all directories
    $fileFssp=&fsspGetFileLoop($fsspFileTmp,$Lscreen,@dir);

    if ( ! -e $fileFssp ) {	# still not: cut non [A-Za-z0-9]
	$tmp_file=$fileInLoc; $tmp_file=~s/^([A-Za-z0-9]+).*(\.fssp.*)$/$1$2/g;
	$fileFssp=&fsspGetFileLoop($tmp_file,$Lscreen,@dir);}
    if ( ! -e $fileFssp ) {	# still not: assume = chain
	$tmp1=substr($fileInLoc,1,4);$chain=substr($fileInLoc,5,1);
	$tmp_file=$fileInLoc; $tmp_file=~s/^($tmp1).*(\.fssp.*)$/$1$2/;
	$fileFssp=&fsspGetFileLoop($tmp_file,$Lscreen,@dir);}
    if ( ! -e $fileFssp ) {	# still not: version up
	$tmp1=substr($idLoc,2,3);
	foreach $it(1..9){$tmp_file=$it."$tmp1".".fssp";
			  $fileFssp=&fsspGetFileLoop($tmp_file,$Lscreen,@dir);}}
				# still not: try to add chain
    if ( (! -e $fileFssp) && (length($title)==4) ) {
	$fileHssp=$fileInLoc;$fileHssp=~s/\.fssp/\.hssp/;$fileHssp=~s/^.*\///g;
	$fileHssp= &hsspGetFile($fileHssp,0);
	$chainHssp=&hsspGetChain($fileHssp);$#chainHssp=0;
	if ($chainHssp ne " "){
	    foreach $it(1..length($chainHssp)){push(@chainHssp,substr($chainHssp,$it,1));}
	    foreach $chainHssp(@chainHssp){
		$tmp=$fileInLoc; $tmp=~s/\.fssp/$chainHssp\.fssp/;
		$fileFssp=&fsspGetFileLoop($tmp,$Lscreen,@dir); 
		last if (-e $fileFssp);}}}

    if ( ! -e $fileFssp) { return(0);}
    if (length($chain)>0) { return($fileFssp,$chain);}
    else                  { return($fileFssp);}
}				# end of fsspGetFile

#===============================================================================
sub fsspGetFileLoop { 
    local ($fileInLoop,$Lscreen,@dir) = @_ ; 
    local ($fileOutLoop,$dir,$tmp);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   fsspGetFileLoop             loops over all directories
#       in:                     $file,$Lscreen,@dir
#       out:                    returned file
#--------------------------------------------------------------------------------
    $fileOutLoop="unk";
    foreach $dir (@dir) {
	$dir=&complete_dir($dir); # add slash at end?
	$tmp="$dir"."$fileInLoop"; # try directory
	if ($Lscreen)           { print "--- fsspGetFileLoop: \t trying '$tmp'\n";}
	if (-e $tmp) { $fileOutLoop=$tmp;
		       last;}
	if ($tmp!~/\.fssp/) {	# missing extension?
	    $tmp.=".fssp";
	    if ($Lscreen)       { print "--- fsspGetFileLoop: \t trying '$tmp'\n";}
	    if (-e $tmp) { $fileOutLoop=$tmp;
			   last;}}}
    $fileOutLoop=~s/\s|\n//g;	# security..
    return($fileOutLoop);
}				# end of fsspGetFileLoop

#==============================================================================
sub getFileFormat {
    local ($fileInLoc,$kwdLoc,@dirLoc) = @_ ;
    local ($sbrName,$fhinLoc,$tmp,@tmpFile,@tmpChain,
	   @formatLoc,@fileLoc,@chainLoc,%fileLoc,@fileRdLoc,$Lok,$txtLoc,$file);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getFileFormat               returns format of file
#       in:                     $file
#                               $kwd = any|HSSP|DSSP|FSSP|SWISS|DAF|MSF|RDB|FASTA|PIR
#                               @dir = directories to search for files
#                               kwd  = noSearch -> no DB search
#                               
#       out:                    $Lok,$msg,%fileFound
#                               $fileFound{"NROWS"}=      number of files found
#                               $fileFound{"ct"}=         name-of-file-ct
#                               $fileFound{"format","ct"}=format
#                               $fileFound{"chain","ct"}= chain
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."getFileFormat";$fhinLoc="FHIN"."$sbrName";
    undef %fileLoc;
    $LnoSearch=0;
    if ($#dirLoc > 0 ){$#tmp=0;	# include existing directories only
		       foreach $dirLoc (@dirLoc){
			   $LnoSearch=1 if ($dirLoc =~ /noSearch/i);
			   $dirLoc=~s/\s//g;
			   push(@tmp,$dirLoc) if (-d $dirLoc)}
		       @dirLoc=@tmp;}
				# check whether keyword understood
    $kwdLoc="any"               if (! defined $kwdLoc);
    if ($kwdLoc !~/^(any|HSSP|DSSP|SWISS|DAF|MSF|RDB|FASTA|PIR)/i){
	print 
	    "-*- WARNING $sbrName wrong input keyword, is=$kwdLoc, \n",
	    "-*-         must be any of: 'any|HSSP|DSSP|SWISS|DAF|RDB|FASTA|PIR'\n";
	return(0,"err","$kwdLoc, wrong keyword",%fileLoc);}

    $#fileLoc=$#chainLoc=$#formatLoc=0;
				# --------------------------------------------------
				# databases
				# --------------------------------------------------
				# ------------------------------
    if ($kwdLoc=~ /HSSP|any/i){	# HSSP
	($Lok,$txtLoc,@fileRdLoc)=
	    &isHsspGeneral($fileInLoc,1,@dirLoc);
	if ($Lok){
	    $#tmpFile=$#tmpChain=$Lchain=0;
	    if    ($txtLoc eq "isHsspList"){
		$Lchain=0;
		foreach $tmp (@fileRdLoc){
		    if   ($tmp eq "chain"){$Lchain=1;}
		    elsif(! $Lchain)      {push(@tmpFile,$tmp);
					   push(@formatLoc,"HSSP");}
		    else                  {push(@tmpChain,$tmp);}}}
				# is single file
	    elsif ($txtLoc eq "isHssp"){
		if ($#fileRdLoc>1){ # one file with chain
		    push(@tmpFile,$fileRdLoc[1]);
		    push(@formatLoc,"HSSP");
		    push(@tmpChain,$fileRdLoc[2]);}
		else {
		    push(@tmpFile,$fileRdLoc[1]);push(@formatLoc,"HSSP");}}
	    elsif ($txtLoc =~ /^no/){ #
		print "*** $sbrName ERROR in HSSP read\n";}
	    elsif ($txtLoc =~ /empty/){
		print "*** $sbrName HSSP read, $fileRdLoc[1] is empty\n";}
	    push(@fileLoc,@tmpFile);
	    push(@chainLoc,@tmpChain);}}

				# ------------------------------
    if ($kwdLoc=~ /DSSP|any/i){	# DSSP
	($Lok,$txtLoc,@fileRdLoc)=
	    &isDsspGeneral($fileInLoc,@dirLoc);
	if ($Lok){
	    $#tmpFile=$#tmpChain=$Lchain=0;
	    if    ($txtLoc eq "isDsspList"){
		$Lchain=0;
		foreach $tmp (@fileRdLoc){
		    if   ($tmp eq "chain"){$Lchain=1;}
		    elsif(! $Lchain)      {push(@tmpFile,$tmp);
					   push(@formatLoc,"DSSP");}
		    else                  {push(@tmpChain,$tmp);}}}
				# is single file
	    elsif ($txtLoc eq "isDssp"){
		if ($#fileRdLoc>1){ # one file with chain
		    push(@tmpFile,$fileRdLoc[1]);
		    push(@formatLoc,"DSSP");
		    push(@tmpChain,$fileRdLoc[2]);}
		else {
		    push(@tmpFile,$fileRdLoc[1]);push(@formatLoc,"DSSP");}}
	    elsif ($txtLoc =~ /^no/){ #
		print "*** $sbrName ERROR in DSSP read\n";}
	    elsif ($txtLoc =~ /empty/){
		print "*** $sbrName DSSP read, $fileRdLoc[1] is empty\n";}
	    push(@fileLoc,@tmpFile);
	    push(@chainLoc,@tmpChain);}}

				# ------------------------------
				# FSSP
    if (!$Lok && ($kwdLoc =~ /FSSP|any/i)){
	($Lok,$txtLoc,@fileRdLoc)=
	    &isFsspGeneral($fileInLoc,@dirLoc);
	if ($Lok){$#tmpFile=$#tmpChain=$Lchain=0;
		  if    ($txtLoc eq "isFsspList"){ # is list
		      $Lchain=0;
		      foreach $tmp (@fileRdLoc){
			  if   ($tmp eq "chain"){$Lchain=1;}
			  elsif(! $Lchain)      {push(@tmpFile,$tmp);push(@formatLoc,"FSSP");}
			  else                  {push(@tmpChain,$tmp);}}}
		  elsif ($txtLoc eq "isFssp"){ # is single
		      if ($#fileRdLoc>1){ # one file with chain
			  push(@tmpFile,$fileRdLoc[1]);push(@formatLoc,"FSSP");
			  push(@tmpChain,$fileRdLoc[2]);}
		      else {push(@tmpFile,$fileRdLoc[1]);push(@formatLoc,"FSSP");}}
		  elsif ($txtLoc =~ /^no/){print "*** $sbrName ERROR in FSSP read\n";}
		  push(@fileLoc,@tmpFile);
		  push(@chainLoc,@tmpChain);}}
				# --------------------------------------------------
				# sequence formats
				# --------------------------------------------------
    if (!$Lok && ($kwdLoc =~ /SWISS|any/i)){
	($Lok,$txtLoc,@fileRdLoc)=&isSwissGeneral($fileInLoc,@dirLoc);
	if ($Lok){push(@fileLoc,@fileRdLoc);
		  foreach (@fileRdLoc){push(@formatLoc,"SWISS");
				       push(@chainLoc," ");}}}
    if (!$Lok && ($kwdLoc =~ /PIR\w*|any/i)){
	($Lok,$txtLoc,@fileRdLoc)=&isPirMul($fileInLoc);
	if ($Lok){push(@fileLoc,@fileRdLoc);
		  foreach (@fileRdLoc){push(@formatLoc,"PIR_MUL");
				       push(@chainLoc," ");}}}
    if (!$Lok && ($kwdLoc =~ /PIR|any/i)){
	($Lok,$txtLoc,@fileRdLoc)=&isPir($fileInLoc);
	if ($Lok){push(@fileLoc,@fileRdLoc);
		  foreach (@fileRdLoc){push(@formatLoc,"PIR");
				       push(@chainLoc," ");}}}
    if (!$Lok && ($kwdLoc =~ /FASTA|any/i)){
	($Lok,$txtLoc,@fileRdLoc)=&isFastaMul($fileInLoc);
	if ($Lok){push(@fileLoc,@fileRdLoc);
		  foreach (@fileRdLoc){push(@formatLoc,"FASTA");
				       push(@chainLoc," ");}}}
    if (!$Lok && ($kwdLoc =~ /FASTA|any/i)){
	($Lok,$txtLoc,@fileRdLoc)=&isFasta($fileInLoc);
	if ($Lok){push(@fileLoc,@fileRdLoc);
		  foreach (@fileRdLoc){push(@formatLoc,"FASTA");
				       push(@chainLoc," ");}}}
				# --------------------------------------------------
				# RDB
				# --------------------------------------------------
    if (!$Lok && ($kwdLoc =~ /RDB|any/i)){
	($Lok,$txtLoc,@fileRdLoc)=&isRdbGeneral($fileInLoc,@dirLoc);
	if ($Lok){push(@fileLoc,@fileRdLoc);
		  foreach (@fileRdLoc){push(@formatLoc,"RDB");
				       push(@chainLoc," ");}}}
				# --------------------------------------------------
				# other alignment formats
				# --------------------------------------------------
    if (!$Lok && ($kwdLoc =~ /MSF|any/i)){
	($Lok,$txtLoc,@fileRdLoc)=&isMsfGeneral($fileInLoc,@dirLoc);
	if ($Lok){push(@fileLoc,@fileRdLoc);
		  foreach (@fileRdLoc){push(@formatLoc,"MSF");
				       push(@chainLoc," ");}}}
    if (!$Lok && ($kwdLoc =~ /DAF|any/i)){
	($Lok,$txtLoc,@fileRdLoc)=&isDafGeneral($fileInLoc,@dirLoc);
	if ($Lok){push(@fileLoc,@fileRdLoc);
		  foreach (@fileRdLoc){push(@formatLoc,"DAF");
				       push(@chainLoc," ");}}}
    if (!$Lok && ($kwdLoc =~ /SAF|any/i)){
	($Lok,$txtLoc,@fileRdLoc)=&isSaf($fileInLoc);
	if ($Lok){push(@fileLoc,@fileRdLoc);
		  foreach (@fileRdLoc){push(@formatLoc,"SAF");
				       push(@chainLoc," ");}}}
    
    return(0,"*** ERROR $sbrName: kwd=$kwdLoc, no file '$fileInLoc' found\n",%fileLoc)
	if (!$Lok || ($#fileLoc<1));

    foreach $it (1..$#fileLoc){
	$fileLoc{$it}=$fileLoc[$it];
	$fileLoc{"format",$it}=$formatLoc[$it];
	if ((defined $chainLoc[$it])&&
	    (length($chainLoc[$it])>0)&&($chainLoc[$it]=~/[A-Za-z0-9]/)){
	    $fileLoc{"chain",$it}=$chainLoc[$it];}}
    $fileLoc{"NROWS"}=$#fileLoc;
    return(1,"ok",%fileLoc);
}				# end of getFileFormat

#===============================================================================
sub getFileFormatQuick {
    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getFileFormatQuick          quick scan for file format: assumptions
#                               file exists
#                               file is db format (i.e. no list)
#       in:                     file
#       out:                    0|1,format
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."getFileFormatQuick";$fhinLoc="FHIN_"."getFileFormatQuick";
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc!")          if (! defined $fileInLoc);
    return(0,"*** $sbrName: miss in file '$fileInLoc'!")  if (! -e $fileInLoc);
                                # alignments (EMBL 1)
    return(1,"HSSP")         if (&is_hssp($fileInLoc));
    return(1,"STRIP")        if (&is_strip($fileInLoc));
#    return(1,"STRIPOLD")     if (&is_strip_old($fileInLoc));
    return(1,"DSSP")         if (&is_dssp($fileInLoc));
    return(1,"FSSP")         if (&is_fssp($fileInLoc));
                                # alignments (EMBL 1)
    return(1,"DAF")          if (&isDaf($fileInLoc));
    return(1,"SAF")          if (&isSaf($fileInLoc));
                                # alignments other
    return(1,"MSF")          if (&isMsf($fileInLoc));
    return(1,"FASTAMUL")     if (&isFastaMul($fileInLoc));
    return(1,"PIRMUL")       if (&isPirMul($fileInLoc));
                                # sequences
    return(1,"SWISS")        if (&isSwiss($fileInLoc));
    return(1,"PIR")          if (&isPir($fileInLoc));
    return(1,"FASTA")        if (&isFasta($fileInLoc));
    return(1,"GCG")          if (&isGcg($fileInLoc));
                                # PP
    return(1,"PPCOL")        if (&is_ppcol($fileInLoc));
				# NN
    return(1,"NNDB")         if (&is_rdb_nnDb($fileInLoc));
                                # PHD
    return(1,"PHDRDBACC")    if (&isPhdAcc($fileInLoc));
    return(1,"PHDRDBHTM")    if (&isPhdHtm($fileInLoc));
    return(1,"PHDRDBHTMREF") if (&is_rdb_htmref($fileInLoc));
    return(1,"PHDRDBHTMTOP") if (&is_rdb_htmtop($fileInLoc));
    return(1,"PHDRDBSEC")    if (&isPhdSec($fileInLoc));
                                # RDB
    return(1,"RDB")          if (&isRdb($fileInLoc));
    return(1,"unk");
}				# end of getFileFormatQuick

#==============================================================================
sub getPhdSubset {
    local($stringPhdLoc,$stringRelLoc,$relThreshLoc,$relSymLoc) = @_ ;
    local($sbrName);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getPhdSubset                subset from string with PHDsec|acc|htm + rel index
#       in:                     $stringPhdLoc : PHDsec|acc|htm
#       in:                     $stringRelLoc : reliability index (string of numbers [0-9])
#       in:                     $relThreshLoc : >= this -> write to 'subset' row
#       in:                     $relSymLoc    : use this symbol for 'not pred' in subset
#       out:                    1|0,msg,$subset
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."getPhdSubset";$fhinLoc="FHIN_"."getPhdSubset";
				# check arguments
    return(&errSbr("not def stringPhdLoc!"))      if (! defined $stringPhdLoc);
    return(&errSbr("not def stringRelLoc!"))      if (! defined $stringRelLoc);
    return(&errSbr("not def relThreshLoc!"))      if (! defined $relThreshLoc);
    return(&errSbr("not def relSymLoc!"))         if (! defined $relSymLoc);

    @tmpPhd=split(//,$stringPhdLoc);
    @tmpRel=split(//,$stringRelLoc);
    return(&errSbr("stringPhdLoc ne stringRelLoc\n".
		   "phd=$stringPhdLoc\n".
		   "rel=$stringRelLoc\n"))        if ($#tmpPhd != $#tmpRel);

				# ------------------------------
    $out="";			# loop over all residues
    foreach $it (1..$#tmpPhd) {
				# high reliability -> take
	if ($tmpRel[$it] >= $relThreshLoc ) {
	    $out.=$tmpPhd[$it];
	    next; }
	$out.=    $relSymLoc;	# low  reliability -> dot
    }

    $#tmpPhd=$#tmpRel=$#tmp=0;	# slim-is-in!
    return(1,"ok $sbrName",$out);
}				# end of getPhdSubset

#==============================================================================
sub get_id { local ($file) = @_ ; local($id);$[ =1 ;
#--------------------------------------------------------------------------------
#   get_id                      extracts an identifier from file name
#                               note: assume anything before '.' or '-'
#       in:                     $file
#       out:                    $id
#--------------------------------------------------------------------------------
#	     $id=$file;$id=~s/\s|\n//g;$id=~s/.*\///g;$id=~s/\W*(\w+)[.-].*/$1/;
	     $id=$file;$id=~s/\s|\n//g;$id=~s/.*\///g;$id=~s/\W*([\w_\-]+)[.].*/$1/;
	     return($id);
}				# end of get_id

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
#       out                        $rdLoc{"NROWS"},$rdLoc{$ct,"chain"},
#       out                        $rdLoc{$ct,"ifir"},$rdLoc{$ct,"ilas"}
#--------------------------------------------------------------------------------
    $fhin="FhInHssp";
    return(0,"no file") if (! -e $fileIn);
    &open_file("$fhin","$fileIn");
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
    undef %rdLoc; $ctLoc=0;
    @cLoc=split(/,/,$chainLoc);
    @pLoc=split(/,/,$posLoc);

    foreach $itLoc(1..$#cLoc){
	($tmp1,$tmp2)=split(/-/,$pLoc[$itLoc]);
	next if ($tmp2 == $tmp1); # exclude chains of length 1
	++$ctLoc;
	$rdLoc{"NROWS"}=         $ctLoc;
	$rdLoc{"$ctLoc","chain"}=$cLoc[$itLoc];
	$rdLoc{"$ctLoc","ifir"}= $tmp1;
	$rdLoc{"$ctLoc","ilas"}= $tmp2;}
    $chainLoc=~s/,//g;
    return($chainLoc,%rdLoc);
}				# end of hsspGetChain

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
        $tmp_file=$it."$tmp1".".hssp";
        $fileHssp=
            &hsspGetFileLoop($tmp_file,$Lscreen,@dir);}
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
	print "--- hsspGetFileLoop: \t trying '$tmp'\n" if ($Lscreen);
	return($tmp)            if (-e $tmp && &is_hssp($tmp) );
    }
    return(0);			# none found
}				# end of hsspGetFileLoop

#==============================================================================
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
#                               furthermore:
#                               if @want = 'seq|seqAli|seqNoins'
#                                  only those will be returned (e.g. $tmp{"seq",$ct})
#                               default: all 3!
#       out:                    1|0,$rd{} with: 
#       err:                    (0,$msg)
#                    overall:
#                               $rd{"NROWS"}=          : number of alis, i.e. $#want
#                               $rd{"NRES"}=N          : number of residues in guide
#                               $rd{"SWISS"}='sw1,sw2' : list of swiss-ids read
#                               $rd{"0"}='pdbid'       : id of guide sequence (in file header)
#                               $rd{$it}='sw$ct'     : swiss id of the it-th alignment
#                               $rd{"$id"}='$it'       : position of $id in final list
#                               $rd{"sec","$itres"}    : secondary structure for residue itres
#                               $rd{"acc","$itres"}    : accessibility for residue itres
#                               $rd{"chn","$itres"}    : chain for residue itres
#                    per prot:
#                               $rd{"seqNoins",$ct}=sequences without insertions
#                               $rd{"seqNoins","0"}=  GUIDE sequence
#                               $rd{"seq",$ct}=SEQW  : sequences, with all insertions
#                                                        but NOT aligned!!!
#                               $rd{"seqAli",$ct}    : sequences, with all insertions,
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
    $#tmp=0; undef %kwd;	# (1) detect keywords
    foreach $tmp (@want){
	if ($tmp=~/^(seq|seqAli|seqNoins)$/){
	    $kwd{$tmp}=1; 
	    next;}
	push(@tmp,$tmp);}

    if (($#want>0) && ($#want == $#tmp) ){ # default keyworkds
	foreach $des ("seq","seqAli","seqNoins"){
	    $kwd{$des}=1;}}
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
	$num=$rdHeader{"NR",$it}; $id=$rdHeader{"ID",$it};
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
				$tmp{$it}=   $ptr_num2id[$num];
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
		$seq.=$tmp{$it,"$seqNo"};}
	    $seq=~s/\s/\./g;	    # fill up insertions
	    $seq=~tr/[a-z]/[A-Z]/;  # small caps to large
	    $tmp{"seqNoins",$it}=$seq;}
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
				# NOTE: here $tmp{$it,"$seqNo"} gets more than
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
		$seq.=$tmp{$it,"$seqNo"};}
	    $seq=~s/[\s\.!]//g;	# replace insertions 
	    $seq=~tr/[a-z]/[A-Z]/; # all capitals
	    $tmp{"seq",$it}=$seq; }}
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
		    $ali{$it}.=$tmp{$it,"$seqNo"};
		    next;}
				# (2) CASE: insertions
		$seqHere=$tmp{$it,"$seqNo"};
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
	    $tmp{"seqAli",$it}=$ali{$it};}
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
	    undef $tmp{$it,"$seqNo"};}}
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
#                               for prot (e.g. LALI):   $rd{"kwd",$it}
#                               note: for the later number of elements (it) in
#                                     $rd{"NROWS"}
#         special               ID=ID1, $rd{"kwd",$it} existes for ID1 and ID2
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
		     if (defined $ok{$des}){ # multiple lines!
			 $tmp="$1"."\t";
			 if  (defined $tmp{$des}){
			     $tmp{$des}.=$tmp;}
			 else{$tmp{$des}=$tmp;}}
		     else {$ok{$des}=1;$tmp{$des}=$1;}
		     if ($des=~/SEQLENGTH|NCHAIN|KCHAIN|NALIGN/){
			 $tmp{$des}=~s/^(\d+)[^0-9]+.*$/$1/;} # purge blanks
		     last;}}}}
				# ------------------------------
    $ct=0;			# read header
    while ( <$fhinLoc> ) { 
	last if ($LnoPair);	# supress reading pair info
	last if ($_ =~ /$regexpEndHeader/); 
	next if ($_ =~ /^  NR\./); # skip descriptors
	if ($LisLongId){
	    $beg=substr($_,1,56);$end=substr($_,109);$mid=substr($_,57,115); }
	else {
	    $beg=substr($_,1,28);$end=substr($_,90);$mid=substr($_,29,90); }
	$end=~s/^\s*|\s*$|\n//g; # purge leading blanks
	$mid=~s/^\s*|\s*$//g;	# purge leading blanks
				# SWISS accession: hack because it may be empty!
	$accnum=substr($_,81,6); $accnum=~s/(\s)\s+/$1/g;
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

	$tmp{"ID",$ct}=$id;
	$tmp{"NR",$ct}=$ct;
	$tmp{"STRID",$ct}=$strid;
	$tmp{"PROTEIN",$ct}=$end;
	$tmp{"ID1",$ct}=$tmp{"PDBID"};
	$tmp{"ACCNUM",$ct}=$accnum;
				# middle all info
	$#tmp=0;@tmp=split(/\s+/,$mid);
	foreach $_ (@tmp) {$_=~s/\s//g;}

	foreach $des (@kwdHsspHdrLoc){ 
	    next if ( ! defined $ptr{$des});
	    next if ( $des =~/^ACCNUM/);
	    $ptr=$ptr{$des};
	    $tmp{$des,$ct}=$tmp[$ptr]; }}close($fhinLoc);
    $tmp{"NROWS"}=$ct;
				# clean up
    $#kwdInLoc=$#kwdDefHsspHdrLoc=$#kwdHsspTopLoc=$#tmp=
	$#kwdDefHsspTopLoc=$#kwdHsspHdrLoc=0;
    undef %ptr;
    return(1,%tmp);
}				# end of hsspRdHeader

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
        if (defined $tmp{"chain"}) { $tmp{"chain",$ct}=$chainRd; }
        if (defined $tmp{"seq"})   { $tmp{"seq",$ct}=  substr($_,15,1); }
	if (defined $tmp{"sec"})   { $tmp{"sec",$ct}=  substr($_,18,1); }
	if (defined $tmp{"acc"})   { $tmp=               substr($_,37,3); $tmp=~s/\s//g;
				     $tmp{"acc",$ct}=  $tmp; }
	if (defined $tmp{"seqNo"}) { $tmp{"seqNo",$ct}=$seqNo; }
	if (defined $tmp{"pdbNo"}) { $tmp{"pdbNo",$ct}=$pdbNo; }
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
sub is_chain {
    local($tmp) = @_ ;
#-------------------------------------------------------------------------------
#   is_chain                    checks whether or not a PDB chain
#       in:                     character
#       out:                    1,0
#-------------------------------------------------------------------------------
    return(0) if (! defined $tmp);
    return(1) if ($tmp=~/[A-Z0-9]/);
    return(0);
}				# end of is_chain

#===============================================================================
sub is_dssp {
    local ($fileInLoc) = @_ ;
    local ($fh,$Lis);
#--------------------------------------------------------------------------------
#   is_dssp                     checks whether or not file is in DSSP format
#       in:                     $file
#       out:                    1 if is dssp; 0 else
#--------------------------------------------------------------------------------
    return (0) if (! defined $fileInLoc || ! -e $fileInLoc);
    $fh="FHIN_CHECK_DSSP";&open_file("$fh","$fileInLoc");
    while ( <$fh> ) {
	if (/SECONDARY STRUCTURE DEFINITION BY THE PROGRAM DSSP/i){$Lis=1;}else{$Lis=0;}
	last; }close($fh);
    return $Lis;
}				# end of is_dssp

#===============================================================================
sub is_dssp_list {
    local ($fileInLoc) = @_ ;local ($fh,$Lis);
#--------------------------------------------------------------------------------
#   is_dssp_list                checks whether or not file is a list of DSSP files
#       in:                     $file
#       out:                    1 if is dssp; 0 else
#--------------------------------------------------------------------------------
    if (! -e $fileInLoc) {
	return (0);}
    $fh="FHIN_CHECK_DSSP_LIST";&open_file("$fh", "$fileInLoc");
    while ( <$fh> ) {$tmp=$_;$tmp=~s/\s|\n//g;
		     if (length($tmp)<5){next;}
		     if (! -e $tmp)     {$tmp=~s/_.$//;} # purge chain
		     if ( -e $tmp )     { # is existing file?
			 if (&is_dssp($tmp)) {$Lis=1; }
			 else { $Lis=0; } }
		     else {$Lis=0; } 
		     last; } close($fh);
    return $Lis;
}				# end of is_dssp_list

#===============================================================================
sub is_fssp {
    local ($fileInLoc) = @_ ;
#--------------------------------------------------------------------------------
#   is_fssp                     checks whether or not file is in FSSP format
#       in:                     $file
#       out:                    1 if is fssp; 0 else
#--------------------------------------------------------------------------------
    return(0) if (! defined $fileInLoc || ! -e $fileInLoc);
    $fh="FHIN_CHECK_FSSP";
    &open_file("$fh", "$fileInLoc");
    $tmp=<$fh> ;close($fh);
    return(1) if ($tmp=~/^FSSP/);
    return(0);
}				# end of is_fssp

#===============================================================================
sub is_fssp_list {
    local ($fileInLoc) = @_ ;
    local ($fh,$Lis);
#--------------------------------------------------------------------------------
#   is_fssp_lis                 checks whether or not file is a list of FSSP files
#       in:                     $file
#       out:                    1 if is list of fssp files; 0 else
#--------------------------------------------------------------------------------
    if (! -e $fileInLoc) {
	return (0);}
    $fh="FHIN_CHECK_FSSP_LIST";&open_file("$fh", "$fileInLoc");
    while ( <$fh> ) {
	$_=~s/\s|\n//g;
	if ( -e $_ ) {		# is existing file?
	    if (&is_fssp($_)) {$Lis=1; }
	    else { $Lis=0; } }
	else {$Lis=0; } } 
    close($fh);
    return $Lis;
}				# end of is_fssp_list

#===============================================================================
sub is_hssp {
    local ($fileInLoc) = @_ ;local ($fh,$Lis,$tmp);
#--------------------------------------------------------------------------------
#   is_hssp                     checks whether or not file is in HSSP format
#       in:                     $file
#       out:                    1 if is hssp; 0 else
#--------------------------------------------------------------------------------
				# highest priority: has to exist
    return (0)                  if (! -e $fileInLoc);
	
    $fh="FHIN_CHECK_HSSP";
    &open_file("$fh", "$fileInLoc") || 
	do {print "*** ERROR is_hssp $fileInLoc not opened to $fh\n";
	    return (0) ;};	# missing file -> 0
    $tmp=<$fh>;			# first line
    close($fh);
				# is HSSP
    return(1) if ($tmp=~/^HSSP/);
    return(0);
}				# end of is_hssp

#===============================================================================
sub is_hssp_empty {
    local ($fileInLoc) = @_ ;local ($fh,$Lis);
#--------------------------------------------------------------------------------
#   is_hssp_empty               checks whether or not HSSP file has NALIGN=0
#       in:                     $file
#       out:                    1 if is empty; 0 else
#--------------------------------------------------------------------------------
    if (! -e $fileInLoc) {
	return (0);}
    $fh="FHIN_CHECK_HSSP";&open_file("$fh", "$fileInLoc");
    while ( <$fh> ) {
	if ($_=~/^NALIGN\s+(\d+)/){
	    if ($1 eq "0"){
		close($fh); return(1);}
	    last; }}close($fh); 
    return 0;
}				# end of is_hssp_empty

#===============================================================================
sub is_hssp_list {
    local ($fileInLoc) = @_ ;local ($fh,$Lis,$fileRd,$fileLoc,$chainLoc,$LscreenLoc);
#--------------------------------------------------------------------------------
#   is_hssp_list                checks whether or not file contains a list of HSSP files
#       in:                     $file
#       out:                    returns 1 if is HSSP list, 0 else
#--------------------------------------------------------------------------------
    $LscreenLoc=0;
    if (! -e $fileInLoc) {
	return (0);}
    $fh="FHIN_CHECK_HSSP_LIST";
    &open_file("$fh", "$fileInLoc") || return(0);
    $Lis=0;
    while ( <$fh> ) {$fileRd=$_;$fileRd=~s/\s|\n//g;
		     next if (length($fileRd)<5);
		     ($fileLoc,$chainLoc)= &hsspGetFile($fileRd,$LscreenLoc);
		     $Lis=1 if (&is_hssp($fileLoc));
		     last; } close($fh);
    return $Lis;
}				# end of is_hssp_list

#===============================================================================
sub is_list {
    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   is_list                     returns 1 if list of existing files
#       in:                     $fileInLoc
#       out:                    1|0,msg,$LisList
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."is_list"; $fhinLoc="FHIN_"."is_list";
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
    return(&errSbr("miss in file '$fileInLoc'!"))  if (! -e $fileInLoc);
				# open file
    &open_file("$fhinLoc","$fileInLoc") || 
	return(&errSbr("fileInLoc=$fileInLoc, not opened"));
    $ct=$LisList=0;		# ------------------------------
    while (<$fhinLoc>) {	# read file
	$_=~s/\n|\s//g;
	next if ($_=~/^\#/);
	++$ct;
	$LisList=1              if (-e $_);
	last if ($LisList || $ct==2); # 2 not existing files -> say NO!
	$tmp=$_; $tmp=~s/_?[A-Z0-9]$//g; # purge chain
	$LisList=1              if (-e $tmp);
    } close($fhinLoc);
    return(1,"ok $sbrName",$LisList);
}				# end of is_list

#===============================================================================
sub is_nndb_rdb { return(&is_rdb_nnDb(@_)); } # alias

#===============================================================================
sub is_nninFor {
    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   is_nninFor                  is input for FORTRAN input
#       in:                     $fileInLoc
#       out:                    1|0,msg,$Lis_nninFor
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."is_nninFor";$fhinLoc="FHIN_"."is_nninFor";
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
    return(&errSbr("miss in file '$fileInLoc'!"))  if (! -e $fileInLoc);
				# open file
    &open_file("$fhinLoc","$fileInLoc") || 
	return(&errSbr("fileInLoc=$fileInLoc, not opened"));
    $Lis=0;
    $lineFirst=<$fhinLoc>;
    close($fhinLoc);
    $Lis=1 if ($lineFirst =~/NNin_in/i);
    return(1,"ok $sbrName",$Lis);
}				# end of is_nninFor

#===============================================================================
sub is_odd_number {
    local($num)=@_ ;
#--------------------------------------------------------------------------------
#   is_odd_number               checks whether number is odd
#       in:                     number
#       out:                    returns 1 if is odd, 0 else
#--------------------------------------------------------------------------------
    return 0 if (int($num/2) == ($num/2));
    return 1;
}				# end of is_odd_number

#===============================================================================
sub is_pdbid {
    local ($id) = @_ ;
#--------------------------------------------------------------------------------
#   is_pdbid                    checks whether or not id is a valid PDBid (number 3 char)
#       in:                     $file
#       out:                    1 if is DBid, 0 else
#--------------------------------------------------------------------------------
    if (length($id) <= 6){
	if ($id=~/^[0-9][0-9a-z]{3,3}[^0-9a-z]?/){
	    return 1;}}
    return 0;
}				# end of is_pdbid

#===============================================================================
sub is_pdbid_list {
    local ($fileInLoc) = @_ ;local ($fh,$Lis);
#--------------------------------------------------------------------------------
#   is_pdbid_list               checks whether id is list of valid PDBids (number 3 char)
#       in:                     $file
#       out:                    1 if is DBid, 0 else
#--------------------------------------------------------------------------------
    if (! -e $fileInLoc) {
	return (0);}
    $fh="FHIN_CHECK_PDBID_LIST";&open_file("$fh", "$fileInLoc");
    while ( <$fh> ) {$tmp=$_;$tmp=~s/\s|\n//g;
		     if (length($tmp)<5){next;}
		     if (! -e $tmp)     {$tmp=~s/_.$//;} # purge chain
		     if ( -e $tmp )     { # is existing file?
			 if (&is_pdbid($_)) {$Lis=1; }
			 else { $Lis=0; } }
		     else {$Lis=0; } 
		     last; } close($fh);
    return $Lis;
}				# end of is_pdbid_list

#===============================================================================
sub is_ppcol {
    local ($fileInLoc) = @_ ;
    local ($fh,$Lis);
#--------------------------------------------------------------------------------
#   is_ppcol                    checks whether or not file is in RDB format
#       in:                     $file
#       out:                    1 if is ppcol, 0 else
#--------------------------------------------------------------------------------
    if (! -e $fileInLoc) {
	return (0);}
    $fh="FHIN_CHECK_HSSP";&open_file("$fh", "$fileInLoc");
    while ( <$fh> ) {$_=~tr/[A-Z]/[a-z]/;
		     if (/^\# pp.*col/) {$Lis=1;}else{$Lis=0;}last; }
    close($fh);
    return $Lis;
}				# end of is_ppcol

#===============================================================================
sub is_rdb {
    local ($fh_in) = @_ ;
#--------------------------------------------------------------------------------
#   is_rdb                      checks whether or not file is in RDB format
#       in:                     filehandle
#       out (GLOBAL):           $LIS_RDB
#--------------------------------------------------------------------------------
    if (! -e $file_in) {
	return (0);}
    while ( <$fh_in> ) {
	if (/^\# Perl-RDB/) {$LIS_RDB=1;}else{$LIS_RDB=0;}
	last;
    }
    return $LIS_RDB ;
}				# end of is_rdb

#===============================================================================
sub is_rdbf {
    local ($file_in) = @_ ;
    local ($fh,$Lis);
#--------------------------------------------------------------------------------
#   is_rdbf                     checks whether or not file is in RDB format
#       in:                     file
#       out:                    returns 1 if is RDB, 0 else
#--------------------------------------------------------------------------------
    if (! -e $file_in) {
	return (0);}
    $fh="FHIN_CHECK_RDB";&open_file("$fh", "$file_in");
    while ( <$fh> ) {if (/^\# Perl-RDB/) {$Lis=1;}else{$Lis=0;}last; }close($fh);
    return $Lis;
}				# end of is_rdbf

#===============================================================================
sub is_rdb_acc {
    local ($fileInLoc) = @_ ;
    local ($fh,$Lisrdb,$Lisacc);
#--------------------------------------------------------------------------------
#   is_rdb_acc                  checks whether or not file is in RDB format from PHDacc
#       in:                     $file
#       out:                    1 if is rdb_acc; 0 else
#--------------------------------------------------------------------------------
    if (! -e $fileInLoc) {
	return (0);}
    $fh="FHIN_CHECK_RDB_PHDACC";$Lisrdb=$Lisacc=0;
    &open_file("$fh", "$fileInLoc");
    while ( <$fh> ) {if (/^\# Perl-RDB/) {$Lisrdb=1;}
		     if (! $Lisrdb) {last;}
		     if (/^\# PHD\s*acc/){$Lisacc=1;last;}
		     if (! /^\#/) {last;} }
    close($fh);
    return ($Lisacc);
}				# end of is_rdb_acc

#===============================================================================
sub is_rdb_htm {
    local ($fileInLoc) = @_ ;
    local ($fh,$Lisrdb,$Lishtm);
#--------------------------------------------------------------------------------
#   is_rdb_htm                  checks whether or not file is in RDB format from PHDhtm
#       in:                     $file
#       out:                    1 if is .; 0 else
#--------------------------------------------------------------------------------
    if (! -e $fileInLoc) {
	return (0);}
    $fh="FHIN_CHECK_RDB_PHDHTM";$Lisrdb=$Lishtm=0;
    &open_file("$fh", "$fileInLoc");
    $ct=$Lishtm=0;
    while ( <$fh> ) { ++$ct;
		      $Lisrdb=1       if (/^\# Perl-RDB/);
		      last if (! $Lisrdb);
		      $Lishtm=1       if (/^\#\s*PHD\s*htm\:/);
		      last if ($Lishtm);
		      last if ($_ !~/^\#/);
		      last if ($ct > 5); }close($fh);
    return ($Lishtm);
}				# end of is_rdb_htm

#===============================================================================
sub is_rdb_htmref {
    local ($fileInLoc) = @_ ;local ($fh,$Lisrdb,$Lishtm);
#--------------------------------------------------------------------------------
#   is_rdb_htmref               checks whether or not file is RDB from PHDhtm_ref
#       in:                     $file
#       out:                    1 if is .; 0 else
#--------------------------------------------------------------------------------
    if (! -e $fileInLoc) {
	return (0);}
    $fh="FHIN_CHECK_RDB_PHDHTM_REF";$Lisrdb=$Lishtm=0;
    &open_file("$fh", "$fileInLoc") || return(0); 
    $ct=$Lishtm=0;
    while ( <$fh> ) { ++$ct;
		      $Lisrdb=1       if (/^\# Perl-RDB/);
		      last if (! $Lisrdb);
		      $Lishtm=1       if (/^\#\s*PHD\s*htm.*ref\:/);
		      last if ($Lishtm);
		      last if ($_ !~/^\#/);
		      last if ($ct > 5); }close($fh);
    return ($Lishtm);
}				# end of is_rdb_htmref

#===============================================================================
sub is_rdb_htmtop {
    local ($fileInLoc) = @_ ;local ($fh,$Lisrdb,$Lishtm);
#--------------------------------------------------------------------------------
#   is_rdb_htmtop               checks whether or not file is RDB from PHDhtm_top
#       in:                     $file
#       out:                    1 if is .; 0 else
#--------------------------------------------------------------------------------
    if (! -e $fileInLoc) {
	return (0);}
    $fh="FHIN_CHECK_RDB_PHDHTM_TOP";$Lisrdb=$Lishtm=0;
    &open_file("$fh", "$fileInLoc") || return(0); 
    $ct=$Lishtm=0;
    while ( <$fh> ) { ++$ct;
		      $Lisrdb=1       if (/^\# Perl-RDB/);
		      last if (! $Lisrdb);
		      $Lishtm=1       if (/^\#\s*PHD\s*htm.*top\:/);
		      last if ($Lishtm);
		      last if ($_ !~/^\#/);
		      last if ($ct > 5); }close($fh);
    return ($Lishtm);
}				# end of is_rdb_htmtop

#===============================================================================
sub is_rdb_nnDb {
    local ($fileInLoc) = @_ ;
    local ($fh,$Lisrdb,$Lisacc);
#--------------------------------------------------------------------------------
#   is_rdb_nnDb                 checks whether or not file is in RDB format for NN.pl
#       in:                     $file
#       out:                    1 if is rdb_nn; 0 else
#--------------------------------------------------------------------------------
    return (0) if (! -e $fileInLoc);
    $fh="FHIN_CHECK_RDB_RDBNN";
    &open_file("$fh", "$fileInLoc") || return(0);
    $tmp=(<$fh>);close($fh);
    return(1) if ($tmp=~/^\# Perl-RDB.*NNdb/i);
    return (0);
}				# end of is_rdb_nnDb

#===============================================================================
sub is_rdb_sec {
    local ($fileInLoc) = @_ ;
    local ($fh,$Lisrdb,$Lissec);
#--------------------------------------------------------------------------------
#   is_rdb_sec                  checks whether or not file is RDB from PHDsec
#       in:                     $file
#       out:                    1 if is .; 0 else
#--------------------------------------------------------------------------------
    if (! -e $fileInLoc) {
	return (0);}
    $fh="FHIN_CHECK_RDB_PHDSEC";$Lisrdb=$Lissec=0;
    &open_file("$fh", "$fileInLoc");
    while ( <$fh> ) {if (/^\# Perl-RDB/) {$Lisrdb=1;}
		     if (! $Lisrdb) {last;}
		     if (/^\# PHD\s*sec/){$Lissec=1;last;}
		     if (! /^\#/) {last;} }
    close($fh);
    return ($Lissec);
}				# end of is_rdb_sec

#===============================================================================
sub is_strip {
    local ($fileInLoc) = @_ ;
    local ($fh,$Lis);
#--------------------------------------------------------------------------------
#   is_strip                    checks whether or not file is in HSSP-strip format
#       in:                     $file
#       out:                    1 if is strip; 0 else
#--------------------------------------------------------------------------------
    if (! -e $fileInLoc) {
	return (0);}
    $fh="FHIN_CHECK_STRIP";&open_file("$fh", "$fileInLoc");
    while ( <$fh> ) {if (/===  MAXHOM-STRIP  ===/) {$Lis=1;}else{$Lis=0;}last; }close($fh);
    return $Lis;
}				# end of is_strip

#===============================================================================
sub is_strip_list {
    local ($fileInLoc) = @_ ;local ($fh,$Lis,$fileRd,$fileLoc,$chainLoc,$LscreenLoc);
#--------------------------------------------------------------------------------
#    is_strip_list              checks whether or not file contains a list of HSSPstrip files
#       in:                     $file
#       out:                    1 if is .; 0 else
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

#===============================================================================
sub is_strip_old {
    local ($fileInLoc)= @_ ;
    local ($fh,$Lis);
#--------------------------------------------------------------------------------
#   is_strip_old                checks whether file is old strip format
#                               (first SUMMARY, then ALIGNMENTS)
#       in:                     $file
#       out:                    1 if is strip; 0 else
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

#===============================================================================
sub is_swissprot {return(&isSwiss(@_));} # alias

#===============================================================================
sub is_swissid {
    local ($id) = @_ ;
#--------------------------------------------------------------------------------
#    sub: is_pdbid              checks whether id is a valid SWISSid (char{3,5}_char{3,5})
#                               note: letters have to be lower case
#         input:                id
#         output:               returns 1 if is SWISSid, 0 else
#--------------------------------------------------------------------------------
    if (length($id) <= 12){
	if ($id=~/^[0-9a-z]{3,5}_[0-9a-z]{3,5}/){
	    return 1;}}
    return 0;
}				# end of is_swissid

#===============================================================================
sub is_swissid_list {
    local ($fileLoc) = @_ ;
    local ($fhLoc);
#--------------------------------------------------------------------------------
#    sub: is_swissid_list       checks whether list of valid SWISSid's (char{3,5}_char{3,5})
#         input:                file
#         output:               returns 1 if is Swissid, 0 else
#--------------------------------------------------------------------------------
    if (! -e $fileLoc) {
	return (0);}
    $fhLoc="FHIN_CHECK_SWISSID_LIST";
    &open_file("$fhLoc", "$fileLoc") || return(0);
    while ( <$fhLoc> ) {
	$tmp=$_;$tmp=~s/\s|\n//g; $tmp=~s/^.*\///g; # purge directories
	next if (length($tmp)<5);
	if (&is_swissid($tmp)){ close($fhLoc);
				return(1);}}close($fhLoc);
    return(0);
}				# end of is_swissid_list

#===============================================================================
sub isDaf {local ($fileLoc) = @_ ; local ($Lok);
#--------------------------------------------------------------------------------
#   isDaf                       checks whether or not file is in DAF format
#				(i.e. the dirty ali format used for aqua)
#       in:                     $file
#       out:                    1 if is DAF; 0 else
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
    $sbrName="lib-br:"."isDafGeneral";$fhinLoc="FHIN"."$sbrName";
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

#===============================================================================
sub isDafList {
    local ($fileLoc) = @_ ; local ($Lok,$fhinLoc,$fileTmp);
#--------------------------------------------------------------------------------
#   isDafList                   checks whether or not file is list of Daf files
#       in:                     $file
#       out:                    1 if is DAF; 0 else
#--------------------------------------------------------------------------------
    $fhinLoc="FhIn_DafList";$Lok=0;
    &open_file("$fhinLoc","$fileLoc");
    while (<$fhinLoc>){	$fileTmp=~s/\n|\s//g;
			if (&isDaf($fileTmp)){$Lok=1;}
			last;}close($fhinLoc);
    return($Lok);
}				# end of isDafList

#===============================================================================
sub isDsspGeneral {
    local ($fileInLoc,@dirLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok,@tmpFile,@tmpChain,@tmp,$file,$chain);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   isDsspGeneral               checks (and finds) DSSP files
#       in:                     $file,@dir (to search)
#       out:                    $Lok,$txt,@files (if chains: file1,file2,chain,chain1,chain2)
#           txt='not found|empty|not open|none in list|not dssp|isDssp|isDsspList'
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."isDsspGeneral";$fhinLoc="FHIN"."$sbrName";
				# ------------------------------
    if (! -e $fileInLoc){	# search for DSSP
	($file,$chain)=
	    &dsspGetFile($fileInLoc,@dirLoc);
	return(1,"isDssp",$file,$chain) if ((-e $file) && &is_dssp($file));
	return(0,"not dssp",$fileInLoc); }
				# ------------------------------
    if (&is_dssp($fileInLoc)){	# file is dssp
	return(1,"isDssp",$fileInLoc); } 	
				# ------------------------------
				# file is dssp list
    elsif (&is_dssp_list($fileInLoc)) {
	$Lok=&open_file("$fhinLoc","$fileInLoc");$#tmp=0;
	if (! $Lok){print "*** ERROR $sbrName input file=$fileInLoc, not opened\n";
		    return(0,"not open",$fileInLoc);}
	undef @tmpFile; undef @tmpChain;
	while (<$fhinLoc>) {
	    $_=~s/\n|\s//g;$rd=$_;
	    next if (length($_)==0);
				# file exists ...
	    if    (-e $rd) {
		if (&is_dssp($rd)) { # ... and is DSSP       -> bingo
		    push(@tmpFile,$rd); 
		    push(@tmpChain," "); }
		next; }		     # ... may just be empty -> skip
				# file does NOT exist (chain? dir?)
	    ($file,$chain)=	# search again
		&dsspGetFile($rd,1,@dirLoc);
				# ... bingo
	    if    (-e $file && &is_dssp($file)) { 
		push(@tmpFile,$file);
		push(@tmpChain,$chain); }
	    next;		# GIVE UP ...
	} close($fhinLoc);
				# ... none in list ??
	return(0,"none in list",$fileInLoc) if ($#tmpFile==0);
				# ok -> go home
	return(1,"isDsspList",@tmpFile,"chain",@tmpChain);}
    
				# ------------------------------
    else {			# search for DSSP
	($file,$chain)=
	    &dsspGetFile($fileInLoc,@dirLoc);
	return(1,"isDssp",$file,$chain)     if (-e $file && &is_dssp($file));
	return(0,"not dssp",$fileInLoc); 
    }
}				# end of isDsspGeneral

#===============================================================================
sub isFasta {
    local ($fileLoc) = @_ ; local ($Lok);
#--------------------------------------------------------------------------------
#   isFasta                     checks whether or not file is in FASTA format 
#                               (first line /^>\w/, second (non white) = AA
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
    $fhinLoc2="FHIN_FASTA";
    open($fhinLoc2,$fileLoc) || return(0);
    $one=(<$fhinLoc2>);
    $two=(<$fhinLoc2>);
    $two=~s/\s|\n//g            if (defined $two);
    close($fhinLoc2);

    return(0)                   if (! defined $two || ! defined $one);
    return(1)                   if ($one =~ /^\s*>\s*\w+/ && 
				    $two !~/[^ABCDEFGHIKLMNPQRSTVWXYZx\.~_!]/);
    return(0);
}				# end of isFasta

#===============================================================================
sub isFastaMul {
    local ($fileLoc) = @_ ; local ($Lok);
#--------------------------------------------------------------------------------
#   isFastaMul                  checks whether more than 1 sequence in FASTA found
#                               (first line /^>\w/, second (non white) = AA *2 
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
    &open_file("FHIN_FASTA","$fileLoc");
    $one=(<FHIN_FASTA>);$two=(<FHIN_FASTA>);$two=~s/\s//g;
    return (0) if (($one !~ /^\s*\>\s*\w+/) || ($two =~ /[^ABCDEFGHIKLMNPQRSTVWXYZ\.~_]/));
    $Lok=0;
    while(<FHIN_FASTA>){
	if ($_=~/^\>\w+/){$Lok=1;
			  last;}}close(FHIN_FASTA);
    return($Lok);
}				# end of isFastaMul

#===============================================================================
sub isFsspGeneral {
    local ($fileInLoc,@dirLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok,@tmp,$file,$chain);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   isFsspGeneral               checks (and finds) FSSP files
#       in:                     $file,@dir (to search)
#       out:                    $Lok,$txt,@files
#           txt='not found|empty|not open|none in list|not fssp|isFssp|isFsspList'
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."isFsspGeneral";$fhinLoc="FHIN"."$sbrName";
				# ------------------------------
    if (&is_fssp($fileInLoc))    { # file is fssp
	return(1,"isFssp",$fileInLoc); } 
				# ------------------------------
    elsif (&is_fssp_list($fileInLoc)) { # file is fssp list
	$Lok=&open_file("$fhinLoc","$fileInLoc");$#tmp=0;
	if (! $Lok){print "*** ERROR $sbrName input file=$fileInLoc, not opened\n";
		    return(0,"not open",$fileInLoc);}
	while (<$fhinLoc>) {$_=~s/\n//g;if (length($_)==0)             { next;}
			    $tmp=$_;
			    if    ((-e $tmp) && &is_fssp($tmp))        { push(@tmp,$tmp);}
			    else { # search for valid FSSP file
				($file,$chain)=&fsspGetFile($fileInLoc,@dirLoc);
				if    ((-e $file) && &is_fssp($file))        { push(@tmp,$file);}
				next;}}close($fhinLoc);
	if ($#tmp==0){return(0,"none in list",$fileInLoc);}
	else         {return(1,"isFsspList",@tmp);}}
				# ------------------------------
    else {			# search for FSSP
	($file,$chain)=&fsspGetFile($fileInLoc,@dirLoc);
	if    ((-e $file) && &is_fssp($file))        { 
	    return(1,"isFssp",$file); } 
	else {
	    return(0,"not fssp",$fileInLoc); }}
}				# end of isFsspGeneral

#===============================================================================
sub isGcg {local ($fileLoc) = @_ ; $[ =1 ;
#--------------------------------------------------------------------------------
#    isGcg                      checks whether or not file is in Gcg format (/# SAF/)
#       in:                     $file
#       out:                    1 if is yes; 0 else
# EXA: paho_chick from:    1 to:   80
# EXA: PANCREATIC HORMONE PRECURSOR (PANCREATIC POLYPEPTIDE) (PP).
# EXA:  paho_chick.gcg          Length:   80   31-May-98  Check: 8929 ..
# EXA:        1  MPPRWASLLL LACSLLLLAV PPGTAGPSQP TYPGDDAPVE DLIRFYNDLQ
# EXA:       51  QYLNVVTRHR YGRRSSSRVL CEEPMGAAGC
#--------------------------------------------------------------------------------
           return(0) if (! defined $fileLoc || ! -e $fileLoc);
           $fhinLoc="FHIN_GCG";
           &open_file("$fhinLoc","$fileLoc") || return(0);
           @tmp=<$fhinLoc>; 
           close("$fhinLoc");
           $ctFlag=0;
           foreach $tmp(@tmp){
	       last if ($tmp=~/^\#/); # avoid being too friendly to GCG!
               if   ($tmp =~ /from\s*:\s*\d+\s*to:\s*\d+/i){++$ctFlag;}
               elsif($tmp =~ /length\s*:\s*\d+/i)          {++$ctFlag;}
               elsif($tmp =~ /[\s\t]*\d+\s+[A-Z]+/i)       {++$ctFlag;}
               last if ($ctFlag==3);}
           return(1) if ($ctFlag==3);
           return(0) ;
}				# end of isGcg

#===============================================================================
sub isHelp {
    local ($argLoc) = @_ ;$[ =1 ;
#--------------------------------------------------------------------------------
#   isHelp		        returns 1 if : help,man,-h
#       in:                     argument
#       out:                    returns 1 if is help, 0 else
#--------------------------------------------------------------------------------
    if ( ($argLoc eq "help") || ($argLoc eq "man") || ($argLoc eq "-h") ){
	return(1);}else{return(0);}
}				# end of isHelp

#===============================================================================
sub isHsspGeneral {
    local ($fileInLoc,@dirLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok,@tmpFile,@tmpChain,@tmp,$file,$chain);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   isHsspGeneral               checks (and finds) HSSP files
#       in:                     $file,@dir (to search)
#                               kwd  = noSearch -> no DB search
#       out:                    $Lok,$txt,@files (if chains: file1,file2,chain,chain1,chain2)
#           txt='not found|empty|not open|none in list|not hssp|isHssp|isHsspList'
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."isHsspGeneral";$fhinLoc="FHIN"."$sbrName";
				# ------------------------------
    if (! -e $fileInLoc){	# search for HSSP
	($file,$chain)=
	    &hsspGetFile($fileInLoc,@dirLoc);
	return(1,"isHssp",$file,$chain) if ((-e $file) && &is_hssp($file));
	return(0,"empty", $file)    	if ((-e $file) && &is_hssp_empty($file));
	return(0,"not hssp",$fileInLoc); }
				# ------------------------------
    if (&is_hssp($fileInLoc)){	# file is hssp
	return(0,"empty hssp",$fileInLoc)
	    if (&is_hssp_empty($fileInLoc));
	return(1,"isHssp",$fileInLoc); } 
				# ------------------------------
				# file is hssp list
    elsif (&is_hssp_list($fileInLoc)) {
	$Lok=&open_file("$fhinLoc","$fileInLoc");$#tmp=0;
	if (! $Lok){print "*** ERROR $sbrName input file=$fileInLoc, not opened\n";
		    return(0,"not open",$fileInLoc);}
	undef @tmpFile; undef @tmpChain;
	while (<$fhinLoc>) {
	    $_=~s/\n|\s//g;$rd=$_;
	    next if (length($_)==0);
				# file exists ...
	    if    (-e $rd) {
		if (&is_hssp($rd)) { # ... and is HSSP       -> bingo
		    push(@tmpFile,$rd); 
		    push(@tmpChain," "); }
		next; }		     # ... may just be empty -> skip
				# file does NOT exist (chain? dir?)
	    ($file,$chain)=	# search again
		&hsspGetFile($rd,1,@dirLoc);
				# ... bingo
	    if    (-e $file && &is_hssp($file)) { 
		push(@tmpFile,$file);
		push(@tmpChain,$chain); }
	    next;		# GIVE UP ...
	} close($fhinLoc);
				# ... none in list ??
	return(0,"none in list",$fileInLoc) if ($#tmpFile==0);
				# ok -> go home
	return(1,"isHsspList",@tmpFile,"chain",@tmpChain);}
    
				# ------------------------------
    else {			# search for HSSP
	($file,$chain)=
	    &hsspGetFile($fileInLoc,@dirLoc);
	return(1,"isHssp",$file,$chain)     if (-e $file && &is_hssp($file));
	return(0,"empty" ,$file,"err")      if (-e $file && &is_hssp_empty($file));
	return(0,"not hssp",$fileInLoc); 
    }
}				# end of isHsspGeneral

#===============================================================================
sub isMsf {local ($fileLoc) = @_ ; local ($Lok);
#--------------------------------------------------------------------------------
#   isMsf                       checks whether or not file is in MSF format
#				(i.e. the dirty ali format used for aqua)
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
	   &open_file("FHIN_MSF","$fileLoc");
	   while (<FHIN_MSF>){ if (/^\s*MSF/){$Lok=1;}
			       else          {$Lok=0;}
			       last;}close(FHIN_MSF);
	   return($Lok);
}				# end of isMsf

#===============================================================================
sub isMsfGeneral {
    local ($fileInLoc,@dirLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok,@tmp,$file,$chain);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   isMsfGeneral                checks (and finds) MSF files
#       in:                     $file,@dir (to search)
#       out:                    $Lok,$txt,@files
#           txt='not found|empty|not open|none in list|not msf|isMsf|isMsfList'
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."isMsfGeneral";$fhinLoc="FHIN"."$sbrName";
    if (! -e $fileInLoc){
	return(0,"not existing",$fileInLoc);}
				# ------------------------------
    if (&isMsf($fileInLoc))    { # file is msf
	return(1,"isMsf",$fileInLoc); } 
				# ------------------------------
    elsif (&isMsfList($fileInLoc)) { # file is msf list
	$Lok=&open_file("$fhinLoc","$fileInLoc");$#tmp=0;
	if (! $Lok){print "*** ERROR $sbrName input file=$fileInLoc, not opened\n";
		    return(0,"not open",$fileInLoc);}
	while (<$fhinLoc>) {$_=~s/\n//g;$tmp=$_;
			    if (length($_)==0) { 
				next;}
			    if    ((-e $tmp) && &isMsf($tmp)) { 
				push(@tmp,$tmp);}}close($fhinLoc);
	if ($#tmp==0){return(0,"none in list",$fileInLoc);}
	else         {return(1,"isMsfList",@tmp);}}
    else{
	return(0,"not msf",$fileInLoc);}
}				# end of isMsfGeneral

#===============================================================================
sub isMsfList {
    local ($fileLoc) = @_ ; local ($Lok,$fhinLoc,$fileTmp);
#--------------------------------------------------------------------------------
#   isMsfList                   checks whether or not file is list of Msf files
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
    $fhinLoc="FhIn_MsfList";$Lok=0;
    &open_file("$fhinLoc","$fileLoc");
    while (<$fhinLoc>){	$fileTmp=$_;$fileTmp=~s/\n|\s//g;
			if (&isMsf($fileTmp)&&(-e $fileTmp)){$Lok=1;}
			last;}close($fhinLoc);
    return($Lok);
}				# end of isMsfList

#===============================================================================
sub isPhdAcc {
    local ($fileLoc) = @_ ; local ($Lok);
#--------------------------------------------------------------------------------
#   isPhdAcc                    checks whether or not file is in MSF format
#				(i.e. the dirty ali format used for aqua)
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
    &open_file("FHIN_RDB_PHDACC","$fileLoc");
    $ct=0;
    while (<FHIN_RDB_PHDACC>){ $_=~s/^[\#\s]//g;
                               if (length($_)<5){
                                   next;}
			       ++$ct;
			       last if ($ct>3);
                               if   (($ct==1)&& /^\s*Perl-RDB/){$Lok=1;}
                               elsif ($ct==1) { close(FHIN_RDB_PHDACC); 
                                                return(0);}
			       elsif (/PHDacc/){close(FHIN_RDB_PHDACC); 
                                                return(1);}}close(FHIN_RDB_PHDACC);
    return(0);
}				# end of isPhdAcc

#===============================================================================
sub isPhdHtm {
    local ($fileLoc) = @_ ; local ($Lok);
#--------------------------------------------------------------------------------
#   isPhdHtm                    checks whether or not file is in MSF format
#				(i.e. the dirty ali format used for aqua)
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
    &open_file("FHIN_RDB_PHDHTM","$fileLoc");
    $ct=0;
    while (<FHIN_RDB_PHDHTM>){ $_=~s/^[\#\s]//g;
                               if (length($_)<5){
                                   next;}
			       ++$ct;
			       last if ($ct>3);
                               if   (($ct==1)&& /^\s*Perl-RDB/){$Lok=1;}
                               elsif ($ct==1) { close(FHIN_RDB_PHDHTM); 
                                                return(0);}
			       elsif (/PHDhtm/){close(FHIN_RDB_PHDHTM); 
                                                return(1);}}close(FHIN_RDB_PHDHTM);
    return(0);
}				# end of isPhdHtm

#===============================================================================
sub isPhdSec {
    local ($fileLoc) = @_ ; local ($Lok);
#--------------------------------------------------------------------------------
#   isPhdSec                    checks whether or not file is in MSF format
#				(i.e. the dirty ali format used for aqua)
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
    &open_file("FHIN_RDB_PHDSEC","$fileLoc");
    $ct=0;
    while (<FHIN_RDB_PHDSEC>){ $_=~s/^[\#\s]//g;
                               if (length($_)<5){
                                   next;}
			       ++$ct;
			       last if ($ct>3);
                               if   (($ct==1)&& /^\s*Perl-RDB/){$Lok=1;}
                               elsif ($ct==1) { close(FHIN_RDB_PHDSEC); 
                                                return(0);}
			       elsif (/PHDsec/){close(FHIN_RDB_PHDSEC); 
                                                return(1);}}close(FHIN_RDB_PHDSEC);
    return(0);
}				# end of isPhdSec

#===============================================================================
sub isPir {
    local ($fileLoc) = @_ ; local ($Lok);
#--------------------------------------------------------------------------------
#    isPir                    checks whether or not file is in Pir format 
#                               (first line /^>P1\;/, second (non white) = AA
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
    &open_file("FHIN_PIR","$fileLoc");
    $one=(<FHIN_PIR>);close(FHIN_PIR);
    return(1) if ($one =~ /^\>P1\;/i);
    return(0);
}				# end of isPir

#===============================================================================
sub isPirMul {
    local ($fileLoc) = @_ ; local ($Lok);
#--------------------------------------------------------------------------------
#   isPirMul                    checks whether or not file contains many sequences 
#                               in PIR format 
#                               more than once: first line /^>P1\;/
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
    &open_file("FHIN_PIR","$fileLoc") || return(0);
    $ct=0;
    while(<FHIN_PIR>){++$ct if ($_=~/^>P1\;/i);
                      last if ($ct>1);}close(FHIN_PIR);
    return(1) if ($ct>1);
    return(0);
}				# end of isPirMul

#===============================================================================
sub isRdb {local ($fileInLoc) = @_ ;local ($fh);
#--------------------------------------------------------------------------------
#   isRdb                       checks whether or not file is in RDB format
#       in:                     file
#       out:                    returns 1 if is RDB, 0 else
#--------------------------------------------------------------------------------
	   return (0) if (! -e $fileInLoc);$fh="FHIN_CHECK_RDB";
	   &open_file("$fh", "$fileInLoc") || return(0);
	   $tmp=<$fh>;close($fh);
	   return(1) if ($tmp =~/^\# .*RDB/);
	   return 0; }	# end of isRdb

#===============================================================================
sub isRdbGeneral {
    local ($fileInLoc,@dirLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok,@tmp,$file,$chain);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   isRdbGeneral                checks (and finds) RDB files
#       in:                     $file,@dir (to search)
#       out:                    $Lok,$txt,@files
#           txt='not found|empty|not open|none in list|not rdb|isRdb|isRdbList'
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."isRdbGeneral";$fhinLoc="FHIN"."$sbrName";
				# ------------------------------
    if (&isRdb($fileInLoc))    { # file is rdb
	return(1,"isRdb",$fileInLoc); } 
				# ------------------------------
    elsif (&isRdbList($fileInLoc)) { # file is rdb list
	$Lok=&open_file("$fhinLoc","$fileInLoc");$#tmp=0;
	if (! $Lok){print "*** ERROR $sbrName input file=$fileInLoc, not opened\n";
		    return(0,"not open",$fileInLoc);}
	while (<$fhinLoc>) {$_=~s/\n//g;$tmp=$_;
			    if (length($_)==0) { 
				next;}
			    if    ((-e $tmp) && &isRdb($tmp)) { 
				push(@tmp,$tmp);}}close($fhinLoc);
	if ($#tmp==0){return(0,"none in list",$fileInLoc);}
	else         {return(1,"isRdbList",@tmp);}}
    else{
	return(0,"not rdb",$fileInLoc);}
}				# end of isRdbGeneral

#===============================================================================
sub isRdbList {local ($fileInLoc) = @_ ; local ($Lok,$fhinLoc,$fileTmp);
#--------------------------------------------------------------------------------
#   isRdbList                   checks whether or not file is list of Rdb files
#       in:                     file
#       out:                    returns 1 if is RDB, 0 else
#--------------------------------------------------------------------------------
	       return(0) if (! -e $fileInLoc); $fhinLoc="FHIN_RDBLIST";$Lok=0;
	       $Lok=&open_file("$fhinLoc","$fileInLoc");
	       if (! $Lok){ print "*** ERROR in lib-br.pl:isRdbList, opening '$fileInLoc'\n";
			    return(0);}
	       while (<$fhinLoc>){ 
                   $_=~s/\s|\n//g;
                   if ($_=~/^\#/ || ! -e $_){close($fhinLoc);
                                             return(0);}
                   $fileTmp=$_;
                   if (&isRdb($fileTmp)&&(-e $fileTmp)){
                       close($fhinLoc);
                       return(1);}
                   last;}close($fhinLoc);
	       return(0); }	# end of isRdbList

#===============================================================================
sub isSaf {local ($fileLoc) = @_ ; 
#--------------------------------------------------------------------------------
#    isSaf                      checks whether or not file is in SAF format (/# SAF/)
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
           return(0) if (! defined $fileLoc || ! -e $fileLoc);
	   $fhinLoc="FHIN_SAF";
           &open_file("$fhinLoc","$fileLoc");
           $tmp=<$fhinLoc>; close("$fhinLoc");
           return(1) if ($tmp =~ /^\#.*SAF/);
           return(0);
}				# end of isSaf

#===============================================================================
sub isSwiss {local ($fileLoc) = @_ ; local ($Lok);
#--------------------------------------------------------------------------------
#    isSwiss                    checks whether or not file is in SWISS-PROT format (/^ID   /)
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
             $fhinLoc="FHIN_SWISS";
	     &open_file("$fhinLoc","$fileLoc");
	     while (<$fhinLoc>){ if (/^ID   /){$Lok=1;}else{$Lok=0;}
                                 last;}close($fhinLoc);
	     return($Lok);
}				# end of isSwiss

#===============================================================================
sub isSwissGeneral {
    local ($fileInLoc,@dirLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok,@tmp,$file,$chain);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   isSwissGeneral              checks (and finds) SWISS files
#       in:                     $file,@dir (to search)
#       out:                    $Lok,$txt,@files
#           txt='not found|empty|not open|none in list|not swiss|isSwiss|isSwissList'
#-------------------------------------------------------------------------------
    $sbrName="lib-br:isSwissGeneral";$fhinLoc="FHIN"."$sbrName";
    return(1,"isSwiss",$fileInLoc) if (&isSwiss($fileInLoc)) ;  # file is swiss
				# ------------------------------
    if (&isSwissList($fileInLoc)) { # file is swiss list
	$Lok=&open_file("$fhinLoc","$fileInLoc");$#tmp=0;
	if (! $Lok){print "*** ERROR $sbrName input file=$fileInLoc, not opened\n";
		    return(0,"not open",$fileInLoc);}
	while (<$fhinLoc>) {$_=~s/\n//g;	    
			    next if (length($_)==0);
			    $tmp=$_;
			    if    ((-e $tmp) && &isSwiss($tmp))        { 
				push(@tmp,$tmp);}
			    else {		# search for valid SWISS file
				($file,$chain)=&swissGetFile($fileInLoc,@dirLoc);
				if    ((-e $file) && &isSwiss($file))        { 
				    push(@tmp,$file);}
				next;}}close($fhinLoc);
	if ($#tmp==0){return(0,"none in list",$fileInLoc);}
	else         {return(1,"isSwissList",@tmp);}}
				# ------------------------------
    else {			# search for SWISS
	($file,$chain)=
	    &swissGetFile($fileInLoc,@dirLoc);
	return(1,"isSwiss",  $file) if ((-e $file) && &isSwiss($file));
	return(0,"not swiss",$fileInLoc);}
}				# end of isSwissGeneral

#===============================================================================
sub isSwissList {
    local ($fileLoc) = @_ ; local ($Lok,$fhinLoc,$fileTmp);
#--------------------------------------------------------------------------------
#   isSwissList                 checks whether or not file is list of Swiss files
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
    $fhinLoc="FhIn_SwissList";$Lok=0;
    &open_file("$fhinLoc","$fileLoc");
    while (<$fhinLoc>){	$fileTmp=$_;$fileTmp=~s/\n|\s//g;
			if (! -e $fileTmp){return(0);}
			if (&isSwiss($fileTmp)&&(-e $fileTmp)){$Lok=1;}
			last;}close($fhinLoc);
    return($Lok);
}				# end of isSwissList

#==============================================================================
sub msfWrt {
    local($fhoutLoc,%input) = @_ ;
    local(@nameLoc,@stringLoc,$tmp,$sbrName,$Lok);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   msfWrt                      writing an MSF formatted file of aligned strings
#         in:                   $fileMsf,$input{}
#                               $input{"NROWS"}  number of alignments
#                               $input{"FROM"}   name of input file
#                               $input{"TO"}     name of output file
#                               $input{$it}    sequence identifier ($name)
#                               $input{"$name"}  sequence for $name
#--------------------------------------------------------------------------------
    $sbrName="msfWrt";
				# ------------------------------
    $#nameLoc=$#tmp=0;		# process input
    foreach $it (1..$input{"NROWS"}){
	$name=$input{$it};
	push(@nameLoc,$name);	# store the names
	push(@stringLoc,$input{"$name"}); } # store sequences

    $FROM=$input{"FROM"}        if (defined $input{"FROM"});
    $TO=  $input{"TO"}          if (defined $input{"TO"});

				# ------------------------------
				# write into file
    print $fhoutLoc 
	"MSF of: ",$FROM," from:    1 to:   ",length($stringLoc[1])," \n",
	$TO," MSF: ",length($stringLoc[1]),
	"  Type: N  November 09, 1918 14:00 Check: 1933 ..\n \n \n";
    foreach $it (1..$#stringLoc){
	printf 
	    $fhoutLoc "Name: %-20s Len: %-5d Check: 2222 Weight: 1.00\n",
	    $nameLoc[$it],length($stringLoc[$it]); 
    }
    print $fhoutLoc " \n","\/\/\n"," \n";

    for($it=1;$it<=length($stringLoc[1]);$it+=50){
	foreach $it2 (1..$#stringLoc){
	    printf $fhoutLoc "%-20s",$nameLoc[$it2];
	    foreach $it3 (1..5){
		last if (length($stringLoc[$it2])<($it+($it3-1)*10));
		printf $fhoutLoc 
		    " %-10s",substr($stringLoc[$it2],($it+($it3-1)*10),10);}
	    print $fhoutLoc "\n";}
	print $fhoutLoc "\n"; }
    print $fhoutLoc "\n";
    close($fhoutLoc);
    $#nameLoc=$#stringLoc=0;	# save space
    return(1);
}				# end of msfWrt

#==============================================================================
sub myprt_empty {
    local($fhx)=@_;
#   myprt_empty                 writes line with '--- \n'
    $fhx="STDOUT" if (! defined $fhx);print $fhx "--- \n"; 
}				# end of myprt_empty

#==============================================================================
sub myprt_line  {
    local($fhx)=@_;
#   myprt_line                  prints a line with 70 '-'
    $fhx="STDOUT" if (! defined $fhx);print $fhx "-" x 70,"\n","--- \n";
}				# end of myprt_line

#==============================================================================
sub myprt_npoints {
    local ($npoints,$num_in) = @_; 
    local ($num,$beg,$ctprev,$ct,$numprev, $tmp,$tmp1,$tmp2, $out, $ct, $i);
    $[=1;
#-------------------------------------------------------------------------------
#   myprt_npoints               writes line with N dots of the form '....,....1....,....2' 
#       in:                     $number_of_points_per_line,$number_to_end_with
#       out:                    $line
#------------------------------------------------------------------------------
    if ( int($npoints/10)!=($npoints/10) ) {
	print "*** ERROR in myprt_npoints (lib-br.pl): \n";
	print "***       number of points should be multiple of 10 (is $npoints)!\n"; 
	return(" "); }
    $ct=int(($num_in-1)/$npoints);
    $beg=$ct*$npoints; $num=$beg;
    for ($i=1;$i<=($npoints/10);++$i) {
	$numprev=$num; $num=$beg+($i*10);
	$ctprev=$numprev/10;
	if    ( $i==1 )                        {
	    $tmp=substr($num,1,1); $out="....,....".$tmp; }
	elsif ( $ctprev<10 )                   {
	    $tmp=substr($num,1,1); $out.="....,....".$tmp; }
	elsif ($i==($npoints/10) && $ctprev>=9){
	    $tmp1=substr($ctprev,2);$tmp2="." x (4-length($tmp1));
	    $out.=$tmp1.$tmp2.",....".substr(($num/10),1); }
	else                                   {
	    $tmp1=substr($ctprev,2);$tmp2="." x (4-length($tmp1));
	    $out.=$tmp1.$tmp2.",....".substr($num,1,1); }}
    $myprt_npoints=$out;
    return ($out);
}				# end of myprt_npoints

#==============================================================================
sub myprt_txt  {
    local($tmp,$fhx)=@_; 
#-------------------------------------------------------------------------------
#   myprt_txt                   adds '---' and '\n' for writing text
#-------------------------------------------------------------------------------
    $fhx="STDOUT" if(! defined $fhx);
    print $fhx "--- $tmp \n"; 
}				# end of myprt_txt

#==============================================================================
sub open_file {
    local ($file_handle,$file_name,$log_file) = @_ ;
    local ($temp_name) ;
#-------------------------------------------------------------------------------
#   open_file                  opens file, writes warning asf
#-------------------------------------------------------------------------------
    $temp_name = $file_name ;
    $temp_name =~ s/^>>|^>//g ;
    if ( ($file_name =~ /^>>/ ) && ( ! -e $temp_name ) ) {
	print "*** INFO (open_file): append file=$temp_name, does not exist-> create it\n" ;
	open ($file_handle, ">$temp_name") || ( do {
	    warn "***\t Cannot create new file: $temp_name\n" ;
	    if ( $log_file ) {
		print $log_file "***\t Cannot create new file: $temp_name\n" ;}
	    return (0);
	} );
	close ("$file_handle") ;}
  
    open ($file_handle, "$file_name") || ( do {
	warn "*** ERROR lib-br:open_file: Cannot open file '$file_name'\n" ;
	if ( $log_file ) {
	    print $log_file "*** lib-br:open_file: Cannot create new file '$file_name'\n" ;}
	return(0);
    } );
    return(1);
}				# end of open_file

#==============================================================================
sub phdAliWrt {
    local ($fileInHsspLoc,$chainInLoc,$fileInPhdLoc,$fileOutLoc,$formOutLoc,
	   $LoptExpandLoc,$riSecLoc,$riAccLoc,$riSymLoc,$charPerLineLoc) = @_ ;
    local($sbrName,$fhinLoc,$fhoutLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   phdAliWrt                 converts PHD.rdb to SAF format (including ali)
#       in:                     $fileInHssp  : HSSP file
#       in:                     $chainIn     : chain identifier ([0-9A-Z])
#       in:                     $fileInPhd   : PHD.rdb file
#       in:                     $fileOutLoc  : output *.msf file
#       in:                     $formOutLoc  : format of output file (msf|saf)
#       in:                     $LoptExpand  : do expand insertions in HSSP ?
#       in:                     $riSecLoc    : >= this -> write sec|htm to 'subset' row
#       in:                     $riAccLoc    : >= this -> write acc to 'subset' row
#       in:                     $riSymLoc    : use this symbol for 'not pred' in subset
#       in:                     $charPerLine : number of residues per line of output
#       in:                     $  :
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."phdAliWrt"; 
    $fhinLoc="FHIN_phdAliWrt";  $fhoutLoc="FHOUT_phdAliWrt"; 
				# ------------------------------
				# check arguments
    return(&errSbr("not def fileInHsspLoc!"))          if (! defined $fileInHsspLoc);
    return(&errSbr("not def chainInLoc!"))             if (! defined $chainInLoc);
    return(&errSbr("not def fileInPhdLoc!"))           if (! defined $fileInPhdLoc);
    return(&errSbr("not def fileOutLoc!"))             if (! defined $fileOutLoc);
    return(&errSbr("not def formOutLoc!"))             if (! defined $formOutLoc);
    return(&errSbr("not def LoptExpandLoc!"))          if (! defined $LoptExpandLoc);
    return(&errSbr("not def riSecLoc!"))               if (! defined $riSecLoc);
    return(&errSbr("not def riAccLoc!"))               if (! defined $riAccLoc);
    return(&errSbr("not def riSymLoc!"))               if (! defined $riSymLoc);
    return(&errSbr("not def charPerLineLoc!"))         if (! defined $charPerLineLoc);
				# ------------------------------
				# file existence
    return(&errSbr("miss in hssp=$fileInHsspLoc!"))    if (! -e $fileInHsspLoc);
    return(&errSbr("not HSSP format=$fileInHsspLoc!")) if (! &is_hssp($fileInHsspLoc));
    return(&errSbr("empty HSSP=$fileInHsspLoc!"))      if (&is_hssp_empty($fileInHsspLoc));
	
    return(&errSbr("miss in phd=$fileInPhdLoc!"))      if (! -e $fileInPhdLoc);
    return(&errSbr("not PHD.rdb=$fileInPhdLoc!"))      if (! &is_rdbf($fileInPhdLoc));
				# ------------------------------
				# syntax
    $formOutLoc=~tr/[A-Z]/[a-z]/;
    return(&errSbr("now only MSF|SAF ($formOutLoc)"))  if ($formOutLoc !~/^(msf|saf)$/);
    $LoptExpandLoc=0            if ($LoptExpandLoc !~ /^[01]$/);
    $chainInLoc="*"             if ($chainInLoc !~ /^[A-Za-z0-9]$/);
    $kwdSeq="seqNoins";
    $kwdSeq="seqAli"            if ($LoptExpandLoc); # do expand
				# --------------------------------------------------
				# defaults
				# @kwdPhd: keywords read + written
				# - not read but written: SUBsec, SUBacc
				# - explicit surpressor towards end for
				#   "OBSacc","PHDacc"
				# - 
				# note: @kwdPhdRd and @kwdPhdOut 
				#       correspond in that:
				# --------------------------------------------------
    @kwdPhd=
	("AA",    
	 "OHEL",  "PHEL",  "RI_S",  "SUBsec",
	 "Obie",  "Pbie",  "RI_A",  "SUBacc",   "OREL",   "PREL", 
	 "OHL",   "PHL",            "PFHN",     "PRHN",   "PiTo",   
	 "OTN",   "PTN",   "PRTN", # security
	                   "RI_H",  "PFTN",     
	 );
    $kwdAli=  "ALIGNMENT:";
    $kwdPhd=  "PHD:";
    $symEmpty=" ";
    %ptr=
	('AA',   "AApred",
	 'OHEL', "OBSsec", 'PHEL', "PHDsec", 'RI_S', "RELsec", 
	 'Obie', "O_3acc", 'Pbie', "P_3acc", 'RI_A', "RELacc",
	 'OTN',  "OBShtm", 'PTN',  "PHDhtm", 'RI_H', "RELhtm",
	 'OHL',  "OBShtm", 'PHL',  "PHDhtm", # security
	 'PFTN', "PHDhtmfil", 'PRTN', "PHDhtmref", 'PiTo', "PHDhtmtop",
	 'PFHL', "PHDhtmfil", 'PRHL', "PHDhtmref", 'PiTo', "PHDhtmtop",
	 );
				# explain subset
    $tmp="# NOTATION "." " x 10 ."   ";
    @tmpSec=
	(     "subset of the prediction, for all residues with an expected\n",
	 $tmp."average accuracy > 82% (tables in header)\n",
	 $tmp."NOTE: '$riSymLoc' means that for this residue the reliabilty\n",
	 $tmp."      was below a value of Rel=$riSecLoc.");
    @tmpAcc=
	(     "a subset of the prediction, for all residues with an expected\n",
	 $tmp."average correlation > 0.69 (tables in header)\n",
	 $tmp."NOTE: '$riSymLoc' means that for this residue the reliabilty\n",
	 $tmp."      was below a value of Rel=$riAccLoc.");
    $notationSubsec=join('',@tmpSec);
    $notationSubacc=join('',@tmpAcc);

    $warnMsg="";
    $errMsg= "*** ERROR $sbrName: \n";
    $errMsg.="in: hssp=$fileInHsspLoc, chain=$chainInLoc, phdrdb=$fileInPhdLoc, \n";
    $errMsg.="in: out=$fileOutLoc, form=$formOutLoc, expand=$LoptExpandLoc, \n";
    $errMsg.="in: riSec=$riSecLoc, riAcc=$riAccLoc, sym=$riSymLoc, per=$charPerLineLoc\n";
				# ------------------------------
				# read HSSP alignments
				# ------------------------------
    ($Lok,%tmp)=
	&hsspRdAli($fileInHsspLoc,$kwdSeq);
    return(&errSbr("after hsspRdAli ($fileInHsspLoc,$kwdSeq)".$errMsg)) if (! $Lok);
    return(&errSbr("after hsspRdAli ($fileInHsspLoc,NRES < 1)".$errMsg))
	if (! defined $tmp{"NRES"} || $tmp{"NRES"} < 1);
				# --------------------------------------------------
				# rename -> 
				#    $fin{"seq","1"}=  ... numbers
				#    $fin{"seq","2"}=  guide sequence
				#    $fin{"seq","it"}= pair it-2
				#    $fin{"id","it"}=  identifier for it
				# --------------------------------------------------
    undef %fin;			
    $beg=$end=0;		# find chain
    foreach $itres (1..$tmp{"NRES"}) {
	next if ($chainInLoc ne "*" && $tmp{"chn","$itres"} ne $chainInLoc);
	$beg=$itres             if (! $beg);
	$end=$itres; }
    return(&errSbr("after hsspRdAli beg=$beg, end=$end".$errMsg)) 
	if ($beg < 0 || $beg > length($tmp{$kwdSeq,"0"}) || 
	    $end < 0 || $end > length($tmp{$kwdSeq,"0"}));
				# guide sequence
    $fin{"seq","2"}=         substr($tmp{$kwdSeq,"0"},$beg,(1+$end-$beg)); # sequence
    $fin{"id","2"}=          $tmp{"0"};                 # name

    $ctali=2;			# first 2 = emtpy + guide
				# loop over all pairs
    foreach $itpair (1..$tmp{"NROWS"}) {
	$seq=substr($tmp{$kwdSeq,"$itpair"},$beg,(1+$end-$beg));
	$tmp=$seq;$tmp=~s/\.//g; # delete insertions
				# skip pairs not aligned to chain
	next if (length($tmp) < 1);
	++$ctali;
	$fin{"seq","$ctali"}=$seq;            # sequence
	$fin{"id","$ctali"}= $tmp{"$itpair"}; # name
    }
				# empty line
    $len=length($fin{"seq","2"}); $numpoints=10*(int($len/10))+10;
    $line=&myprt_npoints($numpoints,$len); 
    $fin{"id","1"}= $kwdAli;
    $fin{"seq","1"}=$line;
				# ------------------------------
				# read PHD rdb file
				# ------------------------------
    undef %tmp; undef %tmp2;
    %tmp=
	&rdRdbAssociative($fileInPhdLoc,"not_screen","body",@kwdPhd);

    return(&errSbr("after rdRdbAssociative ($fileInPhdLoc), no NROWS".$errMsg))
	if (! defined $tmp{"NROWS"});
    
				# --------------------------------------------------
				# digest the stuff read
				# * $tmp2{"kwd"} = strings with kwd = @kwdPhdOut
				# --------------------------------------------------
    $len=0;			# all keywords of PHD to write
    foreach $kwd (@kwdPhd) {
				# skip if no READ_RDB for key word 
	next if (! defined $tmp{"$kwd","1"});
	$tmp2{"$kwd"}=          "";
				# loop over all residues (strings from array)
	foreach $itres (1..$tmp{"NROWS"}){ # 
	    $tmp2{"$kwd"}.=     $tmp{"$kwd","$itres"}; }
	$len=length($tmp2{"$kwd"})  if (! $len);
	if ($kwd=~/^[OP]HEL/) {	# convert 'L' -> ' '
	    $tmp2{"$kwd"}=~s/L/L/g ;
	    next; }
	if ($kwd=~/^[PO]bie/){	# convert 'i' -> ' '
	    $tmp2{"$kwd"}=~s/i/i/g;
	    next; }		# convert HTM
	if ($kwd=~/^[PO]H[LN]/ || $kwd=~/^P[RF]H[LN]/){
	    $tmp2{"$kwd"}=~s/H/T/g;
	    $tmp2{"$kwd"}=~s/L/L/g;
	    next; } 
    }
				# ------------------------------
				# check identity HSSP / PHD seq
    $ctres=$ctsum=$ctok=0;	# ------------------------------
    $guideAli=$fin{"seq","2"}; 
    $guidePhd=$tmp2{"AA"};
    while (($ctres < length($guideAli)) && ($ctres < length($guidePhd))) {
	++$ctres;
				# skip non aa 
	$aliRes=substr($guideAli,$ctres,1);
	$phdRes=substr($guidePhd,$ctres,1);
	next if ($aliRes !~ /[A-Za-z]/);  # ali
	next if ($phdRes !~ /[A-Za-z]/);  # phd
				# count identical
	++$ctok                 if ($aliRes eq $phdRes);
	++$ctsum; }		# count all
    if ($ctsum < $ctok) { $warnMsg.="*** WARN $sbrName (hssp=$fileInHsspLoc,chn=$chainInLoc,".
			      "phd=$fileInPhdLoc) not identical seq(hssp) and seq(phd) ".
				  "tot=$ctsum, ok=$ctok\n";
			  $warnMsg.="hssp seq=".$guideAli.",\n";
			  $warnMsg.="phd  seq=".$guidePhd. ",\n"; }

				# ------------------------------
				# add the 'subset' stuff
    foreach $kwd ("SUBsec","SUBacc"){
	if    ($kwd=~/sec/) { $kwdPred="PHEL"; 
			      $kwdRi="RI_S";
			      $riThresh=$riSecLoc; }
	elsif ($kwd=~/acc/) { $kwdPred="Pbie"; 
			      $kwdRi="RI_A";
			      $riThresh=$riAccLoc; }
	next if (! defined $tmp2{"$kwdPred"} || length($tmp2{"$kwdPred"})<1);

	($Lok,$msg,$tmp)=	# get subset
	    &getPhdSubset($tmp2{"$kwdPred"},$tmp2{"$kwdRi"},$riThresh,$riSymLoc);
	return(&errSbrMsg("failed writing subset from\n".$errMsg.$warnMsg,$msg)) if (! $Lok);
	$tmp2{"$kwd"}=$tmp;  }

				# empty line
    $ctkwd=$ctali;		# ctali = number of HSSP alis
    ++$ctkwd;
    $fin{"id","$ctkwd"}=        $kwdPhd;
    $fin{"seq","$ctkwd"}=       $symEmpty x $len;
    
    undef %Lok;			# ------------------------------
    foreach $kwd (@kwdPhd) {	# final correction: 
	next if (! defined $tmp2{"$kwd"});
				# hack: explicit surpressor for "OBSacc","PHDacc"
	next if ($kwd =~/^[OP]REL$/);
	++$ctkwd;
	$fin{"seq","$ctkwd"}=   $tmp2{"$kwd"}; # $tmp2{$kwd} -> $fin{'seq','$it'}
				# rename rows
	$kwdOut=$kwd;
	$kwdOut=$ptr{"$kwd"}    if (defined $ptr{"$kwd"});
	$fin{"id","$ctkwd"}=    $kwdOut;       # $kwd        -> $fin{'id','$it'}
	$Lok{"$kwd"}=           $ctkwd;
    }
    $fin{"NROWS"}=              $ctkwd;
    $fin{"PER_LINE"}=           $charPerLineLoc;
				# ------------------------------
				# read header/notation
    if ($formOutLoc eq "saf"){
				# open file
	$Lok=&open_file("$fhinLoc","$fileInPhdLoc");
	if ($Lok){		# read file
	    $tmpWrt="";
	    while (<$fhinLoc>) {
		$_=~s/\n//g;
		next if ($_ !~/\#.*NOTATION/);
		last if ($_ !~/\#/);
		$kwd=$_; $rd=$_;
		$kwd=~s/^\#.*NOTATION\s*(\S+)\s*:\s*(.*)$/$1/;
		$txt=$2;
		next if (! defined $Lok{"$kwd"});
		next if (! defined $ptr{"$kwd"});
		$kwdOut=$ptr{"$kwd"};
		$tmpWrt.=       sprintf("# NOTATION %-10s : %-s\n",$kwdOut,$txt); 
	    } close($fhinLoc);
				# add for subsets
	    $tmpWrt.=           sprintf("# NOTATION %-10s : %-s\n",
					"SUBsec",$notationSubsec) 
		if ($Lok{"PHEL"} && $Lok{"RI_S"} );
	    $tmpWrt.=           sprintf("# NOTATION %-10s : %-s\n",
					"SUBacc",$notationSubacc) 
		if ($Lok{"Pbie"} && $Lok{"RI_A"} );
	    $fin{"HEADER"}=$tmpWrt."\# \n";
	} }
				# --------------------------------------------------
				# finally write PHD + Ali
				# --------------------------------------------------
    if ($formOutLoc eq "msf") {	# MSF
	undef %tmp;		# build up anew
	$tmp{"NROWS"}=$fin{"NROWS"};
	$tmp{"FROM"}= $fileInHsspLoc;
	$tmp{"TO"}=   $fileOutLoc;
	foreach $it (1..$fin{"NROWS"}) {
	    $id=        $fin{"id",$it};
	    $tmp{$it}=$id;
	    $tmp{"$id"}=$fin{"seq",$it}; }
                                # open new file
	&open_file("$fhoutLoc",">$fileOutLoc") ||
	    return(0,"*** ERROR $sbrName: failed opening fileOut=$fileOutLoc\n"); 
				# call
	($Lok)=
	    &msfWrt($fhoutLoc,%tmp);
	close($fhoutLoc);

	return(&errSbr("failed writing MSF from PHD".$errMsg.$warnMsg)) if (! $Lok); }
				# ------------------------------
    else {			# SAF = default
	($Lok,$msg)=
	    &safWrt($fileOutLoc,%fin);
	return(&errSbrMsg("failed writing SAF".$errMsg.$warnMsg,$msg)) if (! $Lok); }

				# ------------------------------
				# clean up
    undef %tmp; undef %tmp2; undef %fin; undef %Lok; undef %ptr; # slim-is-in!

    return(&errSbrMsg("failed writing output".$errMsg.$warnMsg,$msg)) 
	if (! -e $fileOutLoc);
    
    return(1,"ok $sbrName");
}				# end of phdAliWrt

#===============================================================================
sub phdHtmIsit {
    local($fileInLoc,$minValLoc,$minLenLoc,$doStatLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   phdHtmIsit                  returns best HTM
#       in:                     $fileInLoc        : PHD rdb file
#       in:                     $minValLoc        : average value of minimal helix (0.8)
#                                  undefined|0    -> defaults
#       in:                     $minLenLoc        : length of best helix (18)
#                                  undefined|0    -> defaults
#       in:                     $doStatLoc        : compute further statistics
#                                  undefined|0    -> defaults
#       out:                    1|0,msg,$LisMembrane (1=yes, 0=no),%tmp:
#                               $tmp{"valBest"}   : value of best HTM
#                               $tmp{"posBest"}   : first residue of best HTM
#                   if doStat:
#                               $tmp{"len"}       : length of protein
#                               $tmp{"nhtm"}      : number of membrane helices
#                               $tmp{"seqHtm"}    : sequence of all HTM (string)
#                               $tmp{"seqHtmBest"}: sequence of best HTM (string) 
#                                            (note: may be shorter than minLenLco)
#                               $tmp{"aveLenHtm"} : average length of HTM
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."phdHtmIsit";$fhinLoc="FHIN_"."phdHtmIsit";
				# ------------------------------
				# defaults
    $minValDefLoc= 0.8;		# average value of best helix (required)
    $minLenDefLoc= 18;		# length of best helix (18)
    $doStatDefLoc=0;		# compile further statistics on residues, avLength asf

				# ------------------------------
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
    $minValLoc=$minValDefLoc                       if (! defined $minValLoc || $minValLoc == 0);
    $minLenLoc=$minLenDefLoc                       if (! defined $minLenLoc || $minLenLoc == 0);
    $doStatLoc=$doStatDefLoc                       if (! defined $doStatLoc);

    $kwdNetHtm="OtH";		# name of column with network output for helix (0..100)
    $kwdPhdHtm="PHL";		# name of column with final prediction
    $kwdSeq=   "AA";		# name of column with sequence

    return(&errSbr("miss in file '$fileInLoc'!"))  if (! -e $fileInLoc);
    return(&errSbr("not RDB (htm) '$fileInLoc'!")) if (! &is_rdbf($fileInLoc));

    undef %tmp;
				# ------------------------------
				# read RDB file
    @kwdLoc=($kwdNetHtm);
    push(@kwdLoc,$kwdPhdHtm,$kwdSeq)    if ($doStatLoc);

    %tmp=
	&rdRdbAssociative($fileInLoc,"not_screen","header","PDBID","body",@kwdLoc); 
    return(&errSbr("failed reading $fileInLoc (rd_rdb_associative), kwd=".
		   join(',',@kwdLoc))) if (! defined $tmp{"NROWS"} || ! $tmp{"NROWS"});

				# ------------------------------
				# get network output values
    $#htm=0; 
    foreach $it (1..$tmp{"NROWS"}) {
	push(@htm,$tmp{$kwdNetHtm,$it}); }
				# ------------------------------
				# get best
    ($Lok,$msg,$valBest,$posBest)=
	&phdHtmGetBest($minLenLoc,@htm);
    return(&errSbrMsg("failed getting best HTM ($fileInLoc, minLenLoc=$minLenLoc,\n".
		      "htm=".join(',',@htm,"\n"),$msg)) if (! $Lok);
				# ------------------------------
				# IS or IS_NOT, thats the question
    $LisMembrane=0;
    $LisMembrane=1              if ($valBest >= $minValLoc);

    undef @htm;			# slim-is-in!

    undef %tmp2;
    $tmp2{"valBest"}=    $valBest;
    $tmp2{"posBest"}=    $posBest;

				# ------------------------------
				# no statics -> this is ALL!!
    if (! $doStatLoc) {		# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
	undef %tmp;
	return(1,"ok $sbrName",$LisMembrane,%tmp2);
    }				# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


				# --------------------------------------------------
				# now: do statistics
				# --------------------------------------------------
    $lenProt=$tmp{"NROWS"}; 
				# prediction -> string
    $seqHtm=$seqHtmBest=$phd="";
    foreach $it (1..$tmp{"NROWS"}) {
	$phd.=       $tmp{$kwdPhdHtm,$it}; 
				# subset of residues in HTM
	next if ($tmp{$kwdPhdHtm,$it} ne "H");
	$seqHtm.=    $tmp{$kwdSeq,$it};
				# subset of residues for best HTM
	next if ($posBest > $it || $it >  ($posBest + $minLenLoc));
	$seqHtmBest.=$tmp{$kwdSeq,$it};
    }
	
				# ------------------------------
				# average length
    $tmp=$phd;
    $tmp=~s/^[^H]*|[^H]$//g;	# purge non-HTM begin and end
    @tmp=split(/[^H]+/,$tmp);
    $nhtm=$#tmp;		# number of helices
    $htm=join('',@tmp);		# only helices
    $nresHtm=length($htm);	# total number of residues in helices

    $aveLenHtm=0;
    $aveLenHtm=($nresHtm/$nhtm) if ($nhtm > 0);


    $tmp2{"len"}=        $lenProt;
    $tmp2{"nhtm"}=       $nhtm;
    $tmp2{"seqHtm"}=     $seqHtm;
    $tmp2{"seqHtmBest"}= $seqHtmBest;
    $tmp2{"aveLenHtm"}=  $aveLenHtm;

				# ------------------------------
				# temporary write to file xxx
    if (0){			# xx
	$id=$tmp{"PDBID"};$id=~tr/[A-Z]/[a-z]/;
	$tmpWrt= sprintf("%-s\t%6.2f\t%5d\t%5d\t%5d\t%6.1f",
			 $id,$tmp2{"valBest"},$tmp2{"posBest"},
		     $tmp2{"len"},$tmp2{"nhtm"},$tmp2{"aveLenHtm"});
#	system("echo '$tmpWrt' >> stat-htm-glob.tmp");
	system("echo '$tmpWrt' >> stat-htm-htm.tmp");
    }

    undef %tmp;			# slim-is-in

    return(1,"ok $sbrName",$LisMembrane,%tmp2);
}				# end of phdHtmIsit


#===============================================================================
sub phdHtmGetBest {
    local($minLenLoc,@tmp) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   phdHtmGetBest               returns position (begin) and average val for best HTM
#       in:                     $minValLoc        : average value of minimal helix (0.8)
#                                  = 0    -> defaults (18)
#       in:                     @tmp=             network output HTM unit (0 <= OtH <= 100)
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."phdHtmGetBest";$fhinLoc="FHIN_"."phdHtmGetBest";
				# check arguments
    return(&errSbr("no input!")) if (! defined @tmp || $#tmp==0);
    $minLenLoc=18                if ($minLenLoc == 0);

    $max=0;
				# loop over all residues
    foreach $it (1 .. ($#tmp + 1 - $minLenLoc)) {
				# loop over minLenLoc adjacent residues
	$htm=0;
	foreach $it2 ($it .. ($it + $minLenLoc - 1 )) {
	    $htm+=$tmp[$it2];}
				# store 
	if ($max < $htm) { $pos=$it;
			   $max=$htm; } }
				# normalise
    $val=$max/$minLenLoc;
    $val=$val/100;		# network written to 0..100

    return(1,"ok $sbrName",$val,$pos);
}				# end of phdHtmGetBest

#===============================================================================
sub phdRdbMerge {
    local ($fileOutRdbLoc,$fileAbbrRdb,@fileRdbLoc) = @_ ;
    local ($SBR1,$fhoutLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   phdRdbMerge                 manages merging two PHD *.rdb files ('name'= acc + sec + htm)
#       in:                     $fileOutRdbLoc : name of RDB output
#       in:                     $fileAbbrRdb   : file explaining the abbreviations in RDB file
#       in:                     @fileRdbLoc=
#       in:                        $fileSec    : PHD rdb with sec output
#       in:                        $fileAcc    : PHD rdb with acc output
#       in:                        $fileHtm    : PHD RDB with HTM output
#       out:                    1|0,$ERROR_msg|$WARNING_MESSAGE  implicit: file
#       err:                    (1,'ok warning message'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR1="lib-br:phdRdbMerge"; $fhoutLoc="FHOUT_".$SBR1;
				# ------------------------------
				# arguments given ?
    return(&errSbr("not def fileOutRdbLoc!",$SBR1))  if (! defined $fileOutRdbLoc);
    return(&errSbr("not def fileAbbrRdb!",$SBR1))    if (! defined $fileAbbrRdb);
				# ------------------------------
				# syntax check
    return(&errSbr("too few files (<2):".join(',',@fileRdbLoc),$SBR1))
	if ($#fileRdbLoc < 2);
				# ------------------------------
				# input files existing ?
    foreach $it (1..$#fileRdbLoc){
        return(&errSbr("no file($it)=$fileRdbLoc[$it]!",$SBR1)) 
            if (! -e $fileRdbLoc[$it]); }

                                # ------------------------------
				# set defaults
    &phdRdbMergeDef();
				# --------------------------------------------------
				# merge files (immediately write)
				# --------------------------------------------------
    &open_file("$fhoutLoc", ">$fileOutRdbLoc");
    ($Lok,$msg)=
        &phdRdbMergeDo($fileAbbrRdb,$fhoutLoc,@fileRdbLoc);
    close($fhoutLoc);
    return(&errSbrMsg("failed on phdRdbMergeDo (fh=$fhoutLoc,ARRAY=".
                      join(',',@fileRdbLoc),$msg,$SBR1))
        if (! $Lok);

    return(1,"ok $SBR1\n"."warn message from phdRdbMergeDo (into $SBR1):\n".$msg);

}				# end of phdRdbMerge

#===============================================================================
sub phdRdbMergeDef {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   phdRdbMergeDef              sets defaults for phdRdbMerg
#       in/out GLOBAL:          all
#-------------------------------------------------------------------------------
    @desSec=
        ("No","AA","OHEL","PHEL","RI_S","pH","pE","pL","OtH","OtE","OtL");
    @desAcc=
        ("OACC","PACC","OREL","PREL","RI_A","Obie","Pbie");
    for $it (0..9){
        push(@desAcc,"Ot".$it); }
    @desHtm=
        ("OHL","PHL","PFHL","PRHL","PiTo","RI_H","pH","pL","OtH","OtL");

    @desOutG=
        ("No","AA","OHEL","PHEL","RI_S","OtH","OtE","OtL",
         "OACC","PACC","OREL","PREL","RI_A","Obie","Pbie");
    @formOut=
        ("4N","1" ,"1"   ,"1"   ,"1N",  "3N", "3N", "3N",
         "3N"  ,"3N"  ,"3N",  "3N",  "1N",  "1",   "1");
    for $it (0..9){
        push(@desOutG,"Ot".$it); 
        push(@formOut,"3N");}
    push(@desOutG, 
         "OTN","PTN","PFTN","PRTN","PiTo","RI_H","OtT","OtN");
    push(@formOut,
         "1"  ,"1"  ,"1"   ,"1"   ,"1"   ,"1N"  ,"3N" ,"3N");

    foreach $it (1..$#desOutG){
        $tmp=$formOut[$it];
        if   ($tmp=~/N$/) {$tmp=~s/N$/d/;$formOutPrintf{"$desOutG[$it]"}=$tmp;}
        elsif($tmp=~/F$/) {$tmp=~s/F$/f/;$formOutPrintf{"$desOutG[$it]"}=$tmp;}
        else              {$tmp.="s";    $formOutPrintf{"$desOutG[$it]"}=$tmp;} }
    $sep="\t";                  # separator

}				# end of phdRdbMergeDef

#===============================================================================
sub phdRdbMergeDo {
    local ($fileAbbrRdb,$fhoutLoc,@fileRdbLoc) = @_ ;
    local ($fhinLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   phdRdbMergeDo               merging two PHD *.rdb files ('name'= acc + sec)
#       in GLOBAL:              @desSec,@desAcc,@headerHtm,@desHtm
#       in:                     $fileAbbrRdb   : file explaining the abbreviations in RDB file
#       in:                     $fhoutLoc      : file handle for RDB output file
#       in:                     @fileRdbLoc=
#       in:                        $fileSec    : PHD rdb with sec output
#       in:                        $fileAcc    : PHD rdb with acc output
#       in:                        $fileHtm    : PHD RDB with HTM output
#       out:                    1|0,$ERROR_msg|$WARNING_MESSAGE  implicit: file
#       err:                    (1,'ok warning message'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR2="lib-br:phdRdbMerge"; $fhinLoc="FHIN_".$SBR2;
                                # --------------------------------------------------
                                # reading files
                                # --------------------------------------------------
    $LisAccLoc=$LisHtmLoc=$LisSecLoc=
        $#headerSec=$#headerAcc=$#headerHtm=0;
    foreach $file (@fileRdbLoc){
				# secondary structure
	if    (&is_rdb_sec($file)){
            &open_file("$fhinLoc", "$file") || return(&errSbr("sec failed in=$file",$SBR2));
	    while (<$fhinLoc>){
                $rd=$_;
                push(@headerSec,$rd) if (($rd=~/^\#/) && ($rd !~ /^\# NOTATION/));
                last if ($rd !~ /^\#/);}
	    close($fhinLoc);$LisSecLoc=1;
	    %rdSec=
                &rd_rdb_associative($file,"not_screen","body",@desSec); }
				# accessibility
	elsif (&is_rdb_acc($file)){
            &open_file("$fhinLoc", "$file") || return(&errSbr("acc failed in=$file",$SBR2));
	    while(<$fhinLoc>){
                $rd=$_;
                push(@headerAcc,$rd) if (($rd=~/^\#/) && ($rd !~ /^\# NOTATION/));
                last if ($rd !~ /^\#/);}
	    close($fhinLoc);$LisAccLoc=1;
	    %rdAcc=
                &rd_rdb_associative($file,"not_screen","body",@desAcc);}
				# htm
	elsif (&is_rdb_htmtop($file) || &is_rdb_htmref($file) || &is_rdb_htm($file) ){ 
	    &open_file("$fhinLoc", "$file") || return(&errSbr("htm failed in=$file",$SBR2));
	    while(<$fhinLoc>){
                $rd=$_;
                push(@headerHtm,$rd) if (($rd=~/^\#/) && ($rd !~ /^\# NOTATION/));
                last if ($rd !~ /^\#/);}
	    close($fhinLoc);$LisHtmLoc=1;
	    %rdHtm=
                &rd_rdb_associative($file,"not_screen","body",@desHtm);
	    foreach $ct (1..$rdHtm{"NROWS"}){
		$rdHtm{"OTN",$ct}= $rdHtm{"OHL",$ct};
		$rdHtm{"PTN",$ct}= $rdHtm{"PHL",$ct};
		$rdHtm{"PFTN",$ct}=$rdHtm{"PFHL",$ct};
		$rdHtm{"PRTN",$ct}=$rdHtm{"PRHL",$ct};
		$rdHtm{"OtT",$ct}= $rdHtm{"OtH",$ct};
		$rdHtm{"OtN",$ct}= $rdHtm{"OtL",$ct};} }
	else {
	    return(&errSbr("file=$file not recognised format",$SBR2));} 
    }                           # end of all 2-3 input files

                                # ------------------------------
				# decide when to break the line
    if ($LisHtmLoc){
        $desNewLine="OtN";}
    else{
        $desNewLine="Ot9";}
				# ------------------------------
				# read abbreviations
				# ------------------------------
    $#header=0;
    if (defined $fileAbbrRdb && $fileAbbrRdb && -e $fileAbbrRdb){
	&open_file("$fhinLoc", "$fileAbbrRdb")  || 
	    return(&errSbr("abbr failed in=$fileAbbrRdb",$SBR2));
	while(<$fhinLoc>){
	    $rd=$_;$rd=~s/\n//g;
	    push(@header,$rd)   if($rd=~/^\# NOTATION/);}
	close($fhinLoc); }
				# --------------------------------------------------
				# write header into file
				# --------------------------------------------------
    $warnMsg=
        &phdRdbMergeHdr($fhoutLoc);
				# --------------------------------------------------
				# write selected columns
				# --------------------------------------------------
                                # names
    foreach $des (@desOutG) {
        if (defined $rdSec{$des,"1"} || defined $rdAcc{$des,"1"} || 
	    defined $rdHtm{$des,"1"}) {
	    $sep_tmp=$sep; 
            $sep_tmp="\n"       if ($des eq $desNewLine);
            print $fhoutLoc $des,"$sep_tmp"; }}
                                # ------------------------------
                                # formats
    foreach $it (1..$#format_out) {
        if (defined $rdSec{"$desOutG[$it]","1"} || defined $rdAcc{"$desOutG[$it]","1"} ||
	    defined $rdHtm{"$desOutG[$it]","1"}) {
	    $sep_tmp=$sep; 
            $sep_tmp="\n"       if ($desOutG[$it] eq $desNewLine);
            print $fhoutLoc "$format_out[$it]","$sep_tmp"; } }
                                # ------------------------------
                                # data
    foreach $mue (1..$rdSec{"NROWS"}){
                                # sec
        foreach $des("No","AA","OHEL","PHEL","RI_S","OtH","OtE","OtL") {
            next if (! defined $rdSec{$des,$mue} );
            $tmp="%".$formOutPrintf{$des};
            $rd=$rdSec{$des,$mue};
            $rd=~s/\s|\n//g;
            printf $fhoutLoc "$tmp$sep",$rd; }
                                # acc
        foreach $des("OACC","PACC","OREL","PREL","RI_A","Obie","Pbie",
                   "Ot0","Ot1","Ot2","Ot3","Ot4","Ot5","Ot6","Ot7","Ot8","Ot9") {
            next if (! defined $rdAcc{$des,$mue});
            $tmp="%".$formOutPrintf{$des};
	    $sep_tmp=$sep; 
            $sep_tmp="\n"       if ($des eq $desNewLine);
            $rd=$rdAcc{$des,$mue};
            $rd=~s/\s|\n//g;
            printf $fhoutLoc "$tmp$sep_tmp",$rd; }
	next if (! $LisHtmLoc);
                                # htm
        foreach $des ("OTN","PTN","PFTN","PRTN","PiTo","RI_H","OtT","OtN"){
            next if (! defined $rdHtm{$des,$mue});
            $tmp="%".$formOutPrintf{$des};
	    $sep_tmp=$sep; 
            $sep_tmp="\n"       if ($des eq $desNewLine);
            $rd=$rdHtm{$des,$mue};
            $rd=~s/\s|\n//g;
            printf $fhoutLoc "$tmp$sep_tmp",$rd; }
    }
				# all fine
    return(1,"ok $SBR2")        if (! defined $warnMsg || ! $warnMsg ||
				    $warnMsg !~ /WARN/);
				# warning in hdr
    return(1,"ok $SBR2 warn=\n".$warnMsg."\n");
}				# end of phdRdbMergeDo

#===============================================================================
sub phdRdbMergeHdr {
    local($fhoutLoc) = @_ ;
    local($SBR3);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   phdRdbMergeHdr              writes the merged RDB header
#-------------------------------------------------------------------------------
    $SBR3="lib-br:phdRdbMergHdr";
                                # ------------------------------
                                # keyword
    print $fhoutLoc "\# Perl-RDB\n";
    if ($LisSecLoc && $LisAccLoc && $LisHtmLoc){ 
	print  $fhoutLoc 
	    "\# PHDsec+PHDacc+PHDhtm\n",
	    "\# Prediction of secondary structure, accessibility, and transmembrane helices\n";}
    elsif ($LisSecLoc && $LisAccLoc){ 
	print  $fhoutLoc 
	    "\# PHDsec+PHDacc\n",
	    "\# Prediction of secondary structure, and accessibility\n";}
                                # ------------------------------
				# special information from header
    foreach $rd (@headerSec){
        $tmp=$rd;$tmp=~s/^\# ([A-Za-z0-9_]+).*$/$1/g;
        next if ($rd =~/^\# (NOTATION|Perl|PHD)/i);
        $Lok{"$tmp"}=1;         # to avoid duplication of information
        print $fhoutLoc $rd;}
    foreach $rd (@headerAcc){
        $tmp=$rd;$tmp=~s/^\# ([A-Za-z0-9_]+).*$/$1/g;
        next if ($rd =~/^\# (NOTATION|Perl|PHD)/i);
        next if (defined $Lok{"$tmp"});
        $Lok{"$tmp"}=1;         # to avoid duplication of information
        print $fhoutLoc $rd;}
    foreach $rd (@headerHtm){
        $tmp=$rd;$tmp=~s/^\# ([A-Za-z0-9_]+).*$/$1/g;
        next if ($rd =~/^\# (NOTATION|Perl|PHD)/i);
        next if (defined $Lok{"$tmp"});
				# to avoid duplication of information
        $Lok{"$tmp"}=1 if ($rd !~/MODEL_DAT/); # exception!
        print $fhoutLoc $rd;}
                                # ------------------------------
    foreach $desOut(@desOutG){	# notation
	$Lok=0;
                                # special case accessibility net out (skip 1-9)
	next if ($desOut =~ /^Ot[1-9]/);
                                # special case accessibility net out (write 0)
	if ($desOut =~ /^Ot0/){
	    foreach $rd(@header){
		next if ($rd !~/^Ot\(n\)/);
                $Lok=1;
                print $fhoutLoc "$rd\n";
                last; }
	    next;}
	foreach $rd (@header){
	    next if ($rd !~/$desOut/);
            $Lok=1;
            print $fhoutLoc "$rd\n";
            last; } 
        $errMsg3="-*- WARNING rdbMergeDo \t missing description for desOut=$desOut\n"
            if (! $Lok); }
    print $fhoutLoc "\# \n";

    return($errMsg3);
}				# end of phdRdbMergeHdr

#==============================================================================
sub phdRun {                    # input files/modes
    local ($fileHssp,$fileHsspHtm,
	   $chainHssp,$fileParaSec,$fileParaAcc,$fileParaHtm,$fileAbbrRdb,
           $optPhd3,$optRdbLoc,
                                # executables
           $exePhdLoc,$exeHtmfilLoc,$exeHtmrefLoc,$exeHtmtopLoc,
                                # modes FORTRAN
	   $optMachLoc,$optKgLoc,$useridLoc,$optIsDecLoc,$optNiceInLoc,
                                # modes HTM post
           $optDoHtmfilLoc,$optDoHtmisitLoc,$optHtmisitMinLoc,$optDoHtmrefLoc,$optDoHtmtopLoc,
                                # output files
	   $fileOutPhdLoc,$fileOutRdbLoc,$fileOutNotLoc,
                                # temporary stuff
	   $dirLib,$dirWorkLoc,$titleTmpLoc,$jobidLoc,
           $LdebugLoc,$fileOutScreenLoc,$fhSbrErr) = @_;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   phdRun                      runs all 3 FORTRAN programs PHD
#            input files/modes
#       in:                     $fileHssp      : HSSP file to run it on
#       in:                     $fileHsspHtm   : HSSP file to run PHDhtm (filter more!)
#       in:                     $chainHssp     : name of chain
#       in:                     $filePara*     : name of file with phd.f network parameters
#                                                for modes sec,acc,htm
#                                   = 0          to surpress
#       in:                     $optPhd3       : mode = 3|both|sec|acc|htm  (else -> ERROR)
#       in:                     $optRdbLoc     : write RDB, or not (ancient)
#       in:                     $fileAbbrRdb   : file explaining the abbreviations in RDB file
#            executables
#       in:                     $exePhd        : FORTRAN executable for PHD
#       in:                     $exeHtmfilLoc  : Perl executable for HTMfil
#       in:                     $exeHtmrefLoc  : Perl executable for HTMref
#       in:                     $exeHtmtopLoc  : Perl executable for HTMtop
#            modes FORTRAN
#       in:                     $optMachLoc    : for tim
#       in:                     $optKgLoc      : for KG format
#       in:                     $useridLoc     : user name         (for PP/non-pp)
#       in:                     $optIsDecLoc   : machin is DEC     (ancient)
#            modes HTM
#       in:                     $optDoHtmfil   : 1|0 do or do NOT run
#       in:                     $optDoHtmisit  : 1|0 do or do NOT run
#       in:                     $optHtmisitMin : strength of minimal HTM (default 0.8|0.7)
#                                   = >0 && <1 , real
#       in:                     $optDoHtmref   : 1|0 do or do NOT run
#       in:                     $optDoHtmtop   : 1|0 do or do NOT run
#            output files
#       in:                     $fileOutPhdLoc : human readable file
#       in:                     $fileOutRdbLoc : RDB formatted output
#       in:                     $fileOutNotLoc : file flagging that no HTM was detected
#            PERL libraries
#       in:                     $dirLib        : directory of PERL libs
#                                   = 0          to surpress (and believe scripts will run...)
#            temporary stuff
#       in:                     $dirWork       : working dir
#       in:                     $titleTmpLoc   : temporary files 'dirWork.titleTmp.jobid.extX'
#       in:                     $jobidLoc      : temporary files 'dirWork.titleTmp.jobid.extX'
#       in:                     $LdebugLoc     : =1 -> keep temporary files, =0 -> delete them
#       in:                     $fileOutScreen : screen dumpb of system call  if = 0: 0 -> STDOUT
#       in:                     $fhSbrErr      : error file handle#
#                NOTE:              = 0          to surpress writing
#       out:                    1|0,msg,%tmpFiles(list='f1,f2,f3')  implicit: files
#       out:                    
#       out:                    $fileTmp{$kwd} : with
#                               $fileTmp{kwd}= 'kwd1,kwd2,kwd3,...'
#                               $fileTmp{$kwd}  file, e.g.:
#                               $fileTmp{"sec|acc|htm|both|3","phd|rdb"}
#                NOTE:                  tmpFiles='' if ! debug (all deleted, already)
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."phdRun";
       				# ------------------------------
       				# defaults

				# ------------------------------
				# arguments given ?
    return(&errSbr("not def fileHssp!"))             if (! defined $fileHssp);
    return(&errSbr("not def fileHsspHtm!"))          if (! defined $fileHsspHtm);
    return(&errSbr("not def chainHssp!"))            if (! defined $chainHssp);
    return(&errSbr("not def fileParaSec!"))          if (! defined $fileParaSec);
    return(&errSbr("not def fileParaAcc!"))          if (! defined $fileParaAcc);
    return(&errSbr("not def fileParaHtm!"))          if (! defined $fileParaHtm);
    return(&errSbr("not def optPhd3!"))              if (! defined $optPhd3);
    return(&errSbr("not def optRdbLoc!"))            if (! defined $optRdbLoc);
    return(&errSbr("not def fileAbbrRdb!"))          if (! defined $fileAbbrRdb);

    return(&errSbr("not def exePhdLoc!"))            if (! defined $exePhdLoc);
    return(&errSbr("not def exeHtmfilLoc!"))         if (! defined $exeHtmfilLoc);
    return(&errSbr("not def exeHtmrefLoc!"))         if (! defined $exeHtmrefLoc);
    return(&errSbr("not def exeHtmtopLoc!"))         if (! defined $exeHtmtopLoc);

    return(&errSbr("not def optMachLoc!"))           if (! defined $optMachLoc);
    return(&errSbr("not def optKgLoc!"))             if (! defined $optKgLoc);
    return(&errSbr("not def useridLoc!"))            if (! defined $useridLoc);
    return(&errSbr("not def optIsDecLoc!"))          if (! defined $optIsDecLoc);
    return(&errSbr("not def optNiceInLoc!"))         if (! defined $optNiceInLoc);

    return(&errSbr("not def optDoHtmfilLoc!"))       if (! defined $optDoHtmfilLoc);
    return(&errSbr("not def optDoHtmisitLoc!"))      if (! defined $optDoHtmisitLoc);
    return(&errSbr("not def optHtmisitMinLoc!"))     if (! defined $optHtmisitMinLoc);
    return(&errSbr("not def optDoHtmrefLoc!"))       if (! defined $optDoHtmrefLoc);
    return(&errSbr("not def optDoHtmtopLoc!"))       if (! defined $optDoHtmtopLoc);

    return(&errSbr("not def fileOutPhdLoc!"))        if (! defined $fileOutPhdLoc);
    return(&errSbr("not def fileOutRdbLoc!"))        if (! defined $fileOutRdbLoc);
    return(&errSbr("not def fileOutNotLoc!"))        if (! defined $fileOutNotLoc);

    return(&errSbr("not def dirLib!"))               if (! defined $dirLib);

    return(&errSbr("not def dirWorkLoc!"))           if (! defined $dirWorkLoc);
    return(&errSbr("not def titleTmpLoc!"))          if (! defined $titleTmpLoc);
    return(&errSbr("not def jobidLoc!"))             if (! defined $jobidLoc);
    return(&errSbr("not def LdebugLoc!"))            if (! defined $LdebugLoc);
#    return(&errSbr("not def !"))           if (! defined $);
				# ------------------------------
				# input files existing ?
    return(&errSbr("miss in file '$fileHssp'!"))     if (! -e $fileHssp);
    return(&errSbr("not HSSP file '$fileHssp'!"))    if (! &is_hssp($fileHssp));
    return(&errSbr("empty HSSP file '$fileHssp'!"))  if (&is_hssp_empty($fileHssp));
    return(&errSbr("miss in file '$fileHsspHtm'!"))  if (! -e $fileHsspHtm);
    return(&errSbr("not HSSP file '$fileHsspHtm'!")) if (! &is_hssp($fileHsspHtm));
    return(&errSbr("empty HSSP file '$fileHsspHtm'!")) if (&is_hssp_empty($fileHsspHtm));
                                # ------------------------------
                                # executables ok?
    foreach $exe ($exePhdLoc,$exeHtmfilLoc,$exeHtmrefLoc,$exeHtmtopLoc){
        return(&errSbr("miss in file '$exe'!"))      if (! -e $exe && ! -l $exe);
        return(&errSbr("not executable '$exe'!"))    if (! -x $exePhdLoc ); }
				# ------------------------------
				# syntax check
    return(&errSbr("ini: FORTRAN PHD optPhd ($optPhd3) has to be '3|both|sec|acc|htm'"))
	if ($optPhd3 !~ /^(3|both|sec|acc|htm)$/);
    return(&errSbr("ini: PHD parameter (sec) file=$fileParaSec, missing"))
	if ($fileParaSec && ! -e $fileParaSec);
    return(&errSbr("ini: PHD parameter (acc) file=$fileParaAcc, missing"))
	if ($fileParaAcc && ! -e $fileParaAcc);
    return(&errSbr("ini: PHD parameter (acc) file=$fileParaAcc, missing"))
	if ($fileParaAcc && ! -e $fileParaAcc);

				# ------------------------------
				# other input
    $fhSbrErr="STDOUT"          if (! defined $fhSbrErr);
    $fileOutScreenLoc=0         if (! defined $fileOutScreenLoc || ! $fileOutScreenLoc);

    $errMsg= "*** ERROR $sbrName: in:\n";

    undef %Lok;                 # for results from PHD
    foreach $des ("sec","acc","htm") {
        $Lok{$des}=1; }
                                # ------------------------------
                                # temporary files
                                # ------------------------------
    ($Lok,$msg)=
	&phdRunIniFileNames($optPhd3,$dirWorkLoc,$titleTmpLoc,$jobidLoc);
    return(&errSbr("ini: build up of temporary files (phdRunIniFileNames) failed\n".
		   $msg."\n"))
        if (! $Lok || ! defined $fileTmp{"kwd"} || length($fileTmp{"kwd"}) < 3);

                                # --------------------------------------------------
                                # running all 3 FORTRAN programs
                                # --------------------------------------------------

                                 # ------------------------------
    if ($optPhd3=~/sec|3|both/){ # running PHDsec
                                 # ------------------------------
	$optPhd="sec";
	($Lok{"sec"},$msg)=
	    &phdRun1($fileHssp,$chainHssp,$par{"exePhd"},$optPhd,$fileParaSec,$optRdbLoc,
                     $optMachLoc,$optKgLoc,$useridLoc,$optIsDecLoc,$optNiceInLoc,
                     $fileTmp{$optPhd,"phd"},$fileTmp{$optPhd,"rdb"},
                     $dirWorkLoc,$fileOutScreenLoc,$fhSbrErr);
        $errMsg.=$msg."\n"      if (! $Lok{$optPhd}); }

                                 # ------------------------------
    if ($optPhd3=~/acc|3|both/){ # running PHDacc
                                 # ------------------------------
	$optPhd="acc";
	($Lok{"acc"},$msg)=
	    &phdRun1($fileHssp,$chainHssp,$par{"exePhd"},$optPhd,$fileParaAcc,$optRdbLoc,
                     $optMachLoc,$optKgLoc,$useridLoc,$optIsDecLoc,$optNiceInLoc,
                     $fileTmp{$optPhd,"phd"},$fileTmp{$optPhd,"rdb"},
                     $dirWorkLoc,$fileOutScreenLoc,$fhSbrErr);
        $errMsg.=$msg."\n"      if (! $Lok{$optPhd}); }

				# ------------------------------
    if ($optPhd3=~/htm|3/){     # running PHDhtm

                                # ------------------------------
	$optPhd="htm";          # FORTRAN
	($Lok{"htm"},$msg)=
	    &phdRun1($fileHsspHtm,$chainHssp,$par{"exePhd"},$optPhd,$fileParaHtm,$optRdbLoc,
                     $optMachLoc,$optKgLoc,$useridLoc,$optIsDecLoc,$optNiceInLoc,
                     $fileTmp{$optPhd,"phd"},$fileTmp{$optPhd,"rdb"},
                     $dirWorkLoc,$fileOutScreenLoc,$fhSbrErr);
        $errMsg.=$msg."\n"      if (! $Lok{$optPhd}); 
                                # ------------------------------
				# post-processing PHDhtm
        if (-e $fileTmp{"htm","phd"} &&
            ($optDoHtmisitLoc || $optDoHtmrefLoc || $optDoHtmtopLoc || $optDoHtmfilLoc) ) {
                                # delete FLAG file if existing
            if (-e $fileOutNotLoc){
                unlink ($fileOutNotLoc);
                print $fhSbrErr 
                    "*** WATCH! flag file '$fileOutNotLoc' (flag for NOT htm) existed!\n"
                        if ($fhSbrErr); }

            ($Lok{$optPhd},$msg,$LisHtm)=
                &phdRunPost1($fileHssp,$chainHssp,$fileTmp{"htm","rdb"},$dirLib,$optNiceInLoc,
			     $exeHtmfilLoc,$exeHtmrefLoc,$exeHtmtopLoc,
			     $optDoHtmfilLoc,$optDoHtmisitLoc,$optHtmisitMinLoc,
			     $optDoHtmrefLoc,$optDoHtmtopLoc,
			     $fileOutNotLoc,$fileTmp{"htmfin","rdb"},
			     $fileTmp{"htmfil","rdb"},
			     $fileTmp{"htmref","rdb"},$fileTmp{"htmtop","rdb"},
			     $fileOutScreenLoc,$fhSbrErr);
            $errMsg.=$msg."\n"  if (! $Lok{$optPhd}); }
                                # skip post-processing
        elsif (-e $fileTmp{"htm","phd"}) {
            $LisHtm=1;
            $fileTmp{"htmfin","rdb"}=$fileTmp{"htm","rdb"}; } 
        else {
            $LisHtm=0; } }
				# -------------------------------------------------
				# error check
				# -------------------------------------------------
    $Lerr=0;
    foreach $des ("sec","acc","htm"){
	if (! $Lok{$des}){ 
	    $Lerr=1;
	    $errMsg.="*** ERROR $scrName: PHD$des: no pred file (in=$fileHssp)\n";}}
    return(&errSbrMsg("after all 3",$errMsg)) if ($Lerr);
                
				# -------------------------------------------------
				# now writing output for one file
				# -------------------------------------------------
    if ($optPhd3 =~/^(3|both)$/){
	$optPhd3Tmp=$optPhd3;
        if ($optPhd3 eq "both" || ! $LisHtm){
				# reduce mode if NOT htm
            $optPhd3Tmp="both";
				# delete file
	    unlink($fileTmp{"htmfin","rdb"}) 
		if (defined $fileTmp{"htmfin","rdb"} && -e $fileTmp{"htmfin","rdb"});
				# dummy
            $fileTmp{"htmfin","rdb"}=0; }

                                # ------------------------------
                                # call writer
                                # 
                                # ++++++++++++++++++++++++++++++
                                # NOTE: not writing file.phd, yet yy
                                # ++++++++++++++++++++++++++++++
        ($Lok,$msg)=
            &phdRunWrt($optPhd3Tmp,$optRdbLoc,$fileAbbrRdb,$fileTmp{"sec","rdb"},
                       $fileTmp{"acc","rdb"},$fileTmp{"htmfin","rdb"},
                       $fileOutPhdLoc,$fileOutRdbLoc);
        return(&errSbrMsg("phdRunWrt failed",$msg)) if (! $Lok);
        print $fhSbrErr "-*- WARN $sbrName: phdRunWrt returned warn:\n",$msg,"\n"
            if ($fhSbrErr && $msg =~ /WARN/); }
                                # ------------------------------
    else {                      # simply copy
        foreach $des("sec","acc","htm"){
            next if ($optPhd3 ne $des);
	    $desrdb=$des;
	    $desrdb="htmfin"   if ($des eq "htm"); # take refined one!
            $filePhd=$fileTmp{$des,"phd"};
            $fileRdb=$fileTmp{"$desrdb","rdb"}; 
            last; }
	($Lok,$msg)=
            &sysCpfile($filePhd,$fileOutPhdLoc) if (-e $filePhd);
        return(&errSbr("fin: failed copy ($filePhd->$fileOutPhdLoc)\n".
		       "msg=\n$msg\n")) if (! $Lok);
        ($Lok,$msg)=
            &sysCpfile($fileRdb,$fileOutRdbLoc) if (-e $fileRdb);
        return(&errSbr("fin: failed copy ($fileRdb->$fileOutRdbLoc)\n".
		       "msg=\n$msg\n")) if (! $Lok); }

				# -------------------------------------------------
                                # clean up?
				# -------------------------------------------------
    if (! $LdebugLoc){
        @tmp=split(/,/,$fileTmp{"kwd"});
        foreach $kwd (@tmp){
	    $file=$fileTmp{$kwd};
            next if (! -e $file);
	    next if ($file eq $fileOutPhdLoc ||
		     $file eq $fileOutRdbLoc ||
		     $file eq $fileOutNotLoc ||
		     $file eq $fileAbbrRdb);
            unlink($file);
            print $fhSbrErr "--- $sbrName: rm temp file '$file'\n" if ($fhSbrErr); }
        $fileTmp{"kwd"}=0; }

    return(1,"ok $sbrName",%fileTmp);
}				# end of phdRun

#==============================================================================
sub phdRun1 {
    local ($fileHssp,$chainIn,$exePhdLoc,$optPhdLoc,$optParaLoc,$optRdbLoc,
	   $optMachLoc,$optKgLoc,$useridLoc,$optIsDecLoc,$optNiceInLoc,
	   $fileOutPhdLoc,$fileOutRdbLoc,$dirWorkLoc,$fileOutScreenLoc,$fhSbrErr) = @_;
    local ($tmp,$fileHssp_loc,$optPath_work_loc,$optPhd_loc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   phdRun1                     runs the FORTRAN program PHD once (sec XOR acc XOR htm) 
#       in:                     $fileHssp      : HSSP file to run it on
#       in:                     $chainIn       : name of chain
#       in:                     $exePhd        : FORTRAN executable for PHD
#       in:                     $optPhd        : mode = sec|acc|htm  (else -> ERROR)
#       in:                     $optPara       : name of file with phd.f network parameters
#       in:                     $optRdbLoc     : write RDB, or not (ancient)
#       in:                     $optMachLoc    : for tim
#       in:                     $optKgLoc      : for KG format
#       in:                     $useridLoc     : user name         (for PP/non-pp)
#       in:                     $optIsDecLoc   : machin is DEC     (ancient)
#       in:                     $fileOutPhdLoc : human readable file
#       in:                     $fileOutRdbLoc : RDB formatted output
#       in:                     $dirWork       : working dir
#       in:                     $
#       in:                     $fileOutScreen : screen dumpb of system call  if = 0: 0 -> STDOUT
#       in:                     $fhSbrErr      : error file handle
#                NOTE:              = 0          to surpress writing
#       out:                    1|0,msg, implicit: files
#       err:                    ok -> (1,"ok sbr"), err -> (0,"msg")
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."phdRun1";
				# ------------------------------
				# arguments given ?
    return(&errSbr("not def fileHssp!"))             if (! defined $fileHssp);
    return(&errSbr("not def chainIn!"))              if (! defined $chainIn);
    return(&errSbr("not def exePhdLoc!"))            if (! defined $exePhdLoc);
    return(&errSbr("not def optPhdLoc!"))            if (! defined $optPhdLoc);
    return(&errSbr("not def optParaLoc!"))           if (! defined $optParaLoc);
    return(&errSbr("not def optRdbLoc!"))            if (! defined $optRdbLoc);
    return(&errSbr("not def optMachLoc!"))           if (! defined $optMachLoc);
    return(&errSbr("not def optKgLoc!"))             if (! defined $optKgLoc);
    return(&errSbr("not def useridLoc!"))            if (! defined $useridLoc);
    return(&errSbr("not def optIsDecLoc!"))          if (! defined $optIsDecLoc);
    return(&errSbr("not def optNiceInLoc!"))         if (! defined $optNiceInLoc);
    return(&errSbr("not def fileOutPhdLoc!"))        if (! defined $fileOutPhdLoc);
    return(&errSbr("not def fileOutRdbLoc!"))        if (! defined $fileOutRdbLoc);
    return(&errSbr("not def dirWorkLoc!"))           if (! defined $dirWorkLoc);
				# ------------------------------
				# input files existing ?
    return(&errSbr("miss in file '$fileHssp'!"))     if (! -e $fileHssp);
    return(&errSbr("miss in file '$exePhdLoc'!"))    if (! -e $exePhdLoc && ! -l $exePhdLoc);
    return(&errSbr("not executable '$exePhdLoc'!"))  if (! -x $exePhdLoc );

				# ------------------------------
				# syntax check
    return(&errSbr("ini: FORTRAN PHD optPhd has to be 'sec,acc,htm', is=$optPhdLoc,"))
	if ($optPhdLoc !~ /^(sec|acc|htm)$/);
    return(&errSbr("ini: PHD parameter file=$optParaLoc, missing"))
	if ( ! -e $optParaLoc);
				# ------------------------------
				# other input
    $fhSbrErr="STDOUT"          if (! defined $fhSbrErr);
    $fileOutScreenLoc=0         if (! defined $fileOutScreenLoc || ! $fileOutScreenLoc);

				# ------------------------------
				# build up input arguments
				# ------------------------------
				# working directory
    $optPath_work_loc=$dirWorkLoc;
    if ( length($dirWorkLoc)<3 || $dirWorkLoc eq "unk" ){
        if ( defined $PWD && length($PWD)>1 ) { 
	    $optPath_work_loc=$PWD;  }
        else {
	    $optPath_work_loc="no"; }}

    $optPhd_loc= $optPhdLoc;	# run option
    $optPhd_loc= "exp"          if ($optPhdLoc eq "acc"); # correct acc->exp

    $optUserPhd= 0;		# PP option
    $optUserPhd= "phd"          if ($useridLoc eq "phd");

    @arg=($optMachLoc,		# for tim
	  $optKgLoc,		# for KG format
	  $optPhd_loc,		# mirror            (acc -> exp)
	  $optUserPhd,		# user name         (for PP/non-pp)
	  $optParaLoc,		# Para-file
	  $optRdbLoc,		# write RDB, or not (ancient)
	  $optIsDecLoc,		# machin is DEC     (ancient)
	  $optPath_work_loc,	# working dir
	  $fileOutPhdLoc);	# human readable file

				# security delete
    unlink($fileOutPhdLoc)      if (-e $fileOutPhdLoc);

				# write RDB file ?
    if ($optRdbLoc !~ /no/ && defined $fileOutRdbLoc && $fileOutRdbLoc ne "unk"){
	push(@arg,$fileOutRdbLoc);
				# security delete
	unlink($fileOutRdbLoc)  if (-e $fileOutRdbLoc);}

	

				# ------------------------------
				# massage input HSSP file
    $fileHssp_loc=$fileHssp;
				# add dir
    $fileHssp_loc=$optPath_work_loc."/".$fileHssp
	if ($fileHssp=~/\// && $fileHssp !~/^\// && -d $optPath_work_loc);
				# add chain
    $fileHssp_loc.="_\!_".$chainIn
	if ($chainIn ne "unk" && length($chainIn)>0 && $chainIn ne " ");

				# ------------------------------
				# which option for nice? (job priority)
    if    ($optNiceInLoc =~ /no/)   { 
	$optNice_loc="";}
    elsif ($optNiceInLoc =~ /nice/) { 
	$optNice_loc=$optNiceInLoc; 
	$optNice_loc=~s/\s//g;
	$optNice_loc=~s/.*nice.*(-\d+)$/nice $1/; }
    else                              { 
	$optNice_loc="";}

    $cmd=$cmdSys="";		# avoid warnings

				# --------------------------------------------------
				# now run it
				# --------------------------------------------------

    # *************************
    $arg=join(' ',@arg);	# final argument to run
    $cmd=$optNice_loc." ".	# final command
	$exePhdLoc." ".
	    $fileHssp_loc." ".$arg;
    eval  "\$cmdSys=\"$cmd\"";
    # *************************

    print $fhSbrErr "--- run PHD\n$cmd\n" if ($fhSbrErr);

#   ************************************************************

    ($Lok,$msg)=
	&sysRunProg($cmdSys,$fileOutScreenLoc,$fhSbrErr); # system call PHD

#   ************************************************************

				# ------------------------------
				# system ERROR
    return(&errSbrMsg("failed on PHDfor ($exePhdLoc):\n",$msg)) if (! $Lok);

				# ------------------------------
				# ok !
    return(1,"ok $sbrName") 
	if (($optRdbLoc !~/no/ && -e $fileOutRdbLoc && -e $fileOutPhdLoc) ||
	    ($optRdbLoc =~/no/ && -e $fileOutPhdLoc) );

				# ------------------------------
				# other ERRORS:
    $msg= "*** ERROR $sbrName: failed on system call to FORTRAN ($exePhdLoc):\n";
    $msg.="***                 no pred file ',".$fileOutPhdLoc."'\n"
	if (! -e $fileOutPhdLoc);
    $msg.="***                 no RDB  file ',".$fileOutRdbLoc."'\n"
	if ($optRdbLoc !~ /no/ && ! -e $fileOutRdbLoc);

    print $fhSbrErr "$msg"      if ($fhSbrErr);

    return(0,$msg);
}				# end of phdRun1

#==============================================================================
sub phdRunIniFileNames {
    local($optPhdLoc,$dirWorkLoc,$titleTmpLoc,$jobidLoc)=@_;
    local($sbrName3);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   phdRunIniFileNames          assigns names to intermediate files for FORTRAN PHD
#       in:                     $optPhdLoc     : mode = 3|both|sec|acc|htm
#       in:                     $dirWork       : working dir
#       in:                     $titleTmpLoc   : temporary files 'dirWork.titleTmp.jobid.extX'
#       in:                     $jobidLoc      : temporary files 'dirWork.titleTmp.jobid.extX'
#       out:                    $fileTmp{$kwd} : with
#                               $fileTmp{kwd}= 'kwd1,kwd2,kwd3,...'
#                               $fileTmp{$kwd}  file, e.g.:
#                               $fileTmp{"sec|acc|htm|both|3","phd|rdb"}
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName3="phdRunIniFileNames";
    undef %fileTmp;
				# check arguments
    return(&errSbr("not def optPhdLoc!",$sbrName3))         if (! defined $optPhdLoc);
    return(&errSbr("not def dirWorkLoc!",$sbrName3))        if (! defined $dirWorkLoc);
    return(&errSbr("not def titleTmpLoc!",$sbrName3))       if (! defined $titleTmpLoc);
    return(&errSbr("not def jobidLoc!",$sbrName3))          if (! defined $jobidLoc);

    $titleTmpLoc2=$titleTmpLoc;
    $titieTmpLoc2=~s/$dirWorkLoc//g      if ($titleTmpLoc2=~/$dirWorkLoc/);
    
    $pre= $dirWorkLoc.$titleTmpLoc2;
    $pre.=$jobidLoc                      if ($pre !~ /$jobidLoc/);
				# ------------------------------
				# intermediate files
				# ------------------------------
    if ($optPhdLoc=~/sec|both|3/){
	$fileTmp{"sec","phd"}=   $pre.".phdSec";
	$fileTmp{"sec","rdb"}=   $pre.".rdbSec"; }
    if ($optPhdLoc=~/acc|both|3/){
	$fileTmp{"acc","phd"}=   $pre.".phdAcc";    
	$fileTmp{"acc","rdb"}=   $pre.".rdbAcc"; }
    if ($optPhdLoc=~/htm|3/){
	$fileTmp{"htm","phd"}=   $pre.".phdHtm";    
	$fileTmp{"htm","rdb"}=   $pre.".rdbHtm";    
	$fileTmp{"htmfin","rdb"}=$pre.".rdbHtmfin"; 
	$fileTmp{"htmfil","rdb"}=$pre.".rdbHtmfil"; 
	$fileTmp{"htmref","rdb"}=$pre.".rdbHtmref"; 
	$fileTmp{"htmtop","rdb"}=$pre.".rdbHtmtop"; }
    if  ($optPhdLoc=~/both|3/){ # note 3 also both for the case that no HTM detected!
	$fileTmp{"both","phd"}=  $pre.".phdBoth";   
	$fileTmp{"both","rdb"}=  $pre.".rdbBoth"; }
    if  ($optPhdLoc=~/3/){
	$fileTmp{"3","phd"}=     $pre.".phdAll3";   
	$fileTmp{"3","rdb"}=     $pre.".rdbAll3"; }
    @tmp=sort keys %fileTmp;
    $fileTmp{"kwd"}=join(',',@tmp);
    $fileTmp{"kwd"}=~s/,*$//g;
    return(1,"ok");
}				# phdRunIniFileNames

#==============================================================================
sub phdRunPost1 {
    local($fileHssp,$chainHssp,$fileInRdbLoc,$dirLib,$optNiceInLoc,
	  $exeHtmfilLoc,$exeHtmrefLoc,$exeHtmtopLoc,
          $LdoHtmfilLoc,$LdoHtmisitLoc,$optHtmMinValLoc,$LdoHtmrefLoc,$LdoHtmtopLoc,
          $fileOutNotLoc,$fileOutRdbLoc,$fileTmpFil,$fileTmpRef,$fileTmpTop,
	  $fileOutScreenLoc,$fhSbrErr) = @_;
    local($SBR);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   phdRunPost1                       
#       in:                     $fileHssp      : HSSP file to run it on
#       in:                     $chainHssp     : name of chain
#       in:                     $fileInRdbLoc  : RDB file from PHD fortran
#       in:                     $dirLib        : directory of PERL libs
#                                   = 0          to surpress
#       in:                     $optNiceLoc    : priority 'nonice|nice|nice-n'
#       in:                     $exeHtmfilLoc  : Perl executable for HTMfil
#       in:                     $exeHtmrefLoc  : Perl executable for HTMref
#       in:                     $exeHtmtopLoc  : Perl executable for HTMtop
#       in:                     $LdoHtmfil     : 1|0 do or do NOT run
#       in:                     $LdoHtmisit    : 1|0 do or do NOT run
#       in:                     $optHtmMinVal  : strength of minimal HTM (default 0.8|0.7)
#                                   = >0 && <1 , real
#       in:                     $LdoHtmref     : 1|0 do or do NOT run
#       in:                     $LdoHtmtop     : 1|0 do or do NOT run
#       in:                     $fileOutNotLoc : file flagging that no HTM was detected
#       in:                     $fileOutRdbLoc : final RDB file
#       in:                     $fileTmpFil    : temporary file from htmfil
#       in:                     $fileTmpIsit   : temporary file from htmfil
#       in:                     $fileTmpRef    : temporary file from htmfil
#       in:                     $fileTmpTop    : temporary file from htmfil
#       in:                     $LdebugLoc     : =1 -> keep temporary files, =0 -> delete them
#       in:                     $fileOutScreen : screen dumpb of system call  if = 0: 0 -> STDOUT
#       in:                     $fhSbrErr      : error file handle
#                NOTE:              = 0          to surpress writing
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR="lib-br:"."phdRunPost1"; 
    $fhinLoc="FHIN_"."$SBR"; $fhoutLoc="FHOUT_".$SBR;
				# ------------------------------
				# arguments given ?
    return(&errSbr("not def fileHssp!",$SBR))             if (! defined $fileHssp);
    return(&errSbr("not def chainHssp!",$SBR))            if (! defined $chainHssp);
    return(&errSbr("not def fileInRdbLoc!",$SBR))         if (! defined $fileInRdbLoc);
    return(&errSbr("not def dirLib!",$SBR))               if (! defined $dirLib);
    return(&errSbr("not def optNiceInLoc!",$SBR))         if (! defined $optNiceInLoc);

    return(&errSbr("not def exeHtmfilLoc!",$SBR))         if (! defined $exeHtmfilLoc);
    return(&errSbr("not def exeHtmrefLoc!",$SBR))         if (! defined $exeHtmrefLoc);
    return(&errSbr("not def exeHtmtopLoc!",$SBR))         if (! defined $exeHtmtopLoc);

    return(&errSbr("not def LdoHtmfilLoc!",$SBR))         if (! defined $LdoHtmfilLoc);
    return(&errSbr("not def LdoHtmisitLoc!",$SBR))        if (! defined $LdoHtmisitLoc);
    return(&errSbr("not def optHtmisitMinLoc!",$SBR))     if (! defined $optHtmisitMinLoc);
    return(&errSbr("not def LdoHtmrefLoc!",$SBR))         if (! defined $LdoHtmrefLoc);
    return(&errSbr("not def LdoHtmtopLoc!",$SBR))         if (! defined $LdoHtmtopLoc);

    return(&errSbr("not def fileOutNotLoc!",$SBR))        if (! defined $fileOutNotLoc);
    return(&errSbr("not def fileOutRdbLoc!",$SBR))        if (! defined $fileOutRdbLoc);
    return(&errSbr("not def fileTmpFil!",$SBR))           if (! defined $fileTmpFil);
    return(&errSbr("not def fileTmpRef!",$SBR))           if (! defined $fileTmpRef);
    return(&errSbr("not def fileTmpTop!",$SBR))           if (! defined $fileTmpTop);
				# ------------------------------
				# input files existing ?
#    return(&errSbr("miss in file '$fileHssp'!"))     if (! -e $fileHssp);
#    return(&errSbr("not HSSP file '$fileHssp'!"))    if (! &is_hssp($fileHssp));
#    return(&errSbr("empty HSSP file '$fileHssp'!"))  if (! &is_hssp_empty($fileHssp));
    return(&errSbr("no rdb '$fileInRdbLoc'!",$SBR))   if (! -e $fileInRdbLoc);

                                # ------------------------------
                                # executables ok?
    foreach $exe ($exeHtmfilLoc,$exeHtmrefLoc,$exeHtmtopLoc){
        return(&errSbr("miss in exe '$exe'!",$SBR))      if (! -e $exe && ! -l $exe);
        return(&errSbr("not executable '$exe'!",$SBR))   if (! -x $exePhdLoc ); }

				# ------------------------------
				# defaults

				# xx
				# xx PASS!!!!
				# xx 
    
    $minLenDefLoc= 18;		# length of best helix (18)
    $doStatDefLoc=1;		# compile further statistics on residues, avLength asf

				# ------------------------------
				# other input
    $fhSbrErr="STDOUT"          if (! defined $fhSbrErr);
    $fileOutScreenLoc=0         if (! defined $fileOutScreenLoc || ! $fileOutScreenLoc);

				# xx
				# xx PASS!!!!
				# xx 
    
    $minLenLoc=$minLenDefLoc    if (! defined $minLenLoc || $minLenLoc == 0);
    $doStatLoc=$doStatDefLoc    if (! defined $doStatLoc);


				# ------------------------------
				# which option for nice? (job priority)
    if    ($optNiceInLoc =~ /no/)   { 
	$optNiceTmp="";}
    elsif ($optNiceInLoc =~ /nice/) { 
	$optNiceTmp=$optNiceInLoc; 
	$optNiceTmp=~s/\s//g;
	$optNiceTmp=~s/.*nice.*(-\d+)$/nice $1/; }
    else                              { 
	$optNiceTmp="";}

				# --------------------------------------------------
                                # is HTM ?
    if ($LdoHtmisitLoc) {       # --------------------------------------------------


	($Lok,$msg,$LisHtm,%tmp)=
	    &phdHtmIsit($fileInRdbLoc,$optHtmMinValLoc,$minLenLoc,$doStatLoc);
	return(&errSbrMsg("failed on phdHtmIsit (file=$fileInRdbLoc,".
			  "minVal=$optHtmMinValLoc,, minLen=$minLenLoc, ".
			  "stat=$doStatLoc",$msg,$SBR)) if (! $Lok);
                                # copy to final RDB
        ($Lok,$msg)=
            &sysCpfile($fileInRdbLoc,$fileOutRdbLoc);
	return(&errSbrMsg("htmisit copy",$msg,$SBR),0)  if (! $Lok);

	if (! $LisHtm){
	    &open_file("$fhoutLoc",">$fileOutNotLoc") ||
		return(&errSbr("failed creating flag file '$fileOutNotLoc'",$SBR));
	    print $fhoutLoc
		"value of best=",$tmp{"valBest"},
		", min=$optHtmMinValLoc, posBest=",$tmp{"posBest"},",\n";
	    close($fhoutLoc); 
                                # **********************
				# NOT MEMBRANE -> return
	    return(1,"none after htmisit ($SBR)",0); }}

				# --------------------------------------------------
    if ($LdoHtmfilLoc) {        # old hand waving filter ?
				# --------------------------------------------------
                                # build up argument
        @tmp=($fileInRdbLoc,$fileTmpFil,$fileOutNotLoc);
        push(@tmp,"dirLib=".$dirLib)                       if ($dirLib && -d $dirLib);
        push(@tmp,"not_screen")                            if (! $fhSbrErr && 
							       $fhSbrErr ne "STDOUT");
        $arg=join(' ',@tmp); 
                                # run system call
        if ($exeHtmfilLoc =~ /\.pl/) {
            $cmd="$optNiceTmp $exeHtmfilLoc $arg";
            eval "\$command=\"$cmd\"";
	    ($Lok,$msg)=
                &sysRunProg($command,$fileOutScreenLoc,$fhSbrErr);
	    return(&errSbrMsg("htmfil=$exeHtmfilLoc, msg=",$msg,$SBR)) if (! $Lok); }
        else {                  # include package
            &phd_htmfil'phd_htmfil(@tmp);                        # e.e'
            $tmp=$exeHtmfilLoc;$tmp=~s/\.pm/\.pl/; $cmd="$tmp $arg";
            print $fhSbrErr "$cmd\n"                       if ($fhSbrErr); }
        print $fhSbrErr "--- ","-" x 50,"\n"               if ($fhSbrErr);
                                # copy to final RDB
        ($Lok,$msg)=
            &sysCpfile($fileTmpFil,$fileOutRdbLoc)         if (-e $fileTmpFil);}
                
				# --------------------------------------------------
    if ($LdoHtmrefLoc) {        # do refinement ?
				# --------------------------------------------------
                                # build up argument
#        @tmp=($fileInRdbLoc,"nof file_out=$fileTmpRef");
        @tmp=($fileInRdbLoc,"file_out=$fileTmpRef");
        push(@tmp,"dirLib=".$dirLib)                       if ($dirLib && -d $dirLib);
        push(@tmp,"not_screen")                            if (! $fhSbrErr && 
							       $fhSbrErr ne "STDOUT");
        $arg=join(' ',@tmp);
                                # run system call
        if ($exeHtmrefLoc=~/\.pl/){
            $cmd="$optNiceTmp $exeHtmrefLoc $fileInRdbLoc $arg";
            eval "\$command=\"$cmd\"";
	    ($Lok,$msg)=
                &sysRunProg($command,$fileOutScreenLoc,$fhSbrErr);
	    return(&errSbrMsg("htmref=$exeHtmrefLoc, msg=",$msg,$SBR),0) if (! $Lok); }
        else {                  # include package
            &phd_htmref'phd_htmref(@tmp);                        # e.e'
            $tmp=$exeHtmrefLoc;$tmp=~s/\.pm/\.pl/; $cmd="$tmp $arg";
            print $fhSbrErr "$cmd\n"                       if ($fhSbrErr); }

        print $fhSbrErr "--- ","-" x 50,"\n"               if ($fhSbrErr);
        return(&errSbr("after htmref=$exeHtmrefLoc, no out=$fileTmpRef",$SBR),0) 
            if (! -e $fileTmpRef);
        ($Lok,$msg)=            # copy to final RDB
            &sysCpfile($fileTmpRef,$fileOutRdbLoc);
	return(&errSbrMsg("htmref copy",$msg,$SBR),0)      if (! $Lok); }

				# --------------------------------------------------
    if ($LdoHtmtopLoc) {        # do the topology prediction ?
				# --------------------------------------------------
                                # build up argument
	if    (-e $fileTmpRef){ $file_tmp=$fileTmpRef;   $arg=" ref"; }
	elsif (-e $fileTmpFil){ $file_tmp=$fileTmpFil;   $arg=" fil"; }
        else                  { $file_tmp=$fileInRdbLoc; $arg=" nof"; }
	$tmp= "file_out=$fileTmpTop file_hssp=$fileHssp";
	$tmp.="_".$chainHssp                               if (defined $chainHssp && 
                                                               $chainHssp=~/^[0-9A-Z]$/);
	@tmp=($file_tmp,$tmp);
        push(@tmp,"dirLib=".$dirLib)                       if ($dirLib && -d $dirLib);
        push(@tmp,"not_screen")                            if (! $fhSbrErr && 
							       $fhSbrErr ne "STDOUT");
        $arg=join(' ',@tmp);
                                # run system call
        if ($exeHtmtopLoc=~/\.pl/){
            $cmd="$optNiceTmp $exeHtmtopLoc $arg";
            eval "\$command=\"$cmd\"";
	    ($Lok,$msg)=
                &sysRunProg($command,$fileOutScreenLoc,$fhSbrErr);
	    return(&errSbrMsg("htmtop=$exeHtmtopLoc, msg=",$msg,$SBR),0) if (! $Lok); }
        else {                  # include package
            &phd_htmtop'phd_htmtop(@tmp);                        # e.e'
            $tmp=$exeHtmtopLoc;$tmp=~s/\.pm/\.pl/; $cmd="$tmp $arg";
            print $fhSbrErr "$cmd\n"                       if ($fhSbrErr); }
        print $fhSbrErr "--- ","-" x 50,"\n"               if ($fhSbrErr);
	return(&errSbr("after htmtop=$exeHtmtopLoc, no out=$fileTmpTop",$SBR),0) 
            if (! -e $fileTmpTop);
        ($Lok,$msg)=            # copy to final RDB
            &sysCpfile($fileTmpTop,$fileOutRdbLoc);
	return(&errSbrMsg("htmtop copy",$msg,$SBR),0)      if (! $Lok); }
    
    return(1,"ok $SBR",1);
}				# end of phdRunPost1

#===============================================================================
sub phdRunWrt {
    local($optPhd3Loc,$optRdbLoc,$fileAbbrRdb,$fileTmpSec,$fileTmpAcc,$fileTmpHtm,
          $fileOutPhdLoc,$fileOutRdbLoc) = @_ ;
    local($SBR);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   phdRunWrt                   merges 2-3 RDB files (sec,acc,htm?)
                                # ++++++++++++++++++++++++++++++
                                # NOTE: not writing file.phd, yet yy
                                # ++++++++++++++++++++++++++++++
#       in:                     $optPhd3       : mode = 3|both|sec|acc|htm  (else -> ERROR)
#       in:                     $optRdbLoc     : write RDB, or not (ancient)
#       in:                     $fileAbbrRdb   : file explaining the abbreviations in RDB file
#       in:                     $fileTmpSec    : PHD rdb with sec output
#       in:                     $fileTmpAcc    : PHD rdb with acc output
#       in:                     $fileTmpHtm    : PHD RDB with HTM output
#                                  = 0           if mode 'both' !!
#       in:                     $fileOutPhdLoc : name of ouptput file for human readable stuff
#       in:                     $fileOutRdbLoc : name of RDB output
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $SBR="lib-br:"."phdRunWrt"; $fhinLoc="FHIN_".$SBR;$fhoutLoc="FHOUT_".$SBR;
    $errMsg="*** ERROR $SBR: \n".
	"in: opt=$optPhd3Loc,rdb=$optRdbLoc,fileAbbr=$fileAbbrRdb,\n".
	    "in: sec=$fileTmpSec,acc=$fileTmpAcc,htm=$fileTmpHtm,\n".
		"in: outPhd=$fileOutPhdLoc,outRdb=$fileOutRdbLoc,\n";
				# ------------------------------
				# arguments given ?
    return(&errSbr("not def optPhd3Loc!\n".$errMsg,$SBR))    if (! defined $optPhd3Loc);
    return(&errSbr("not def optRdbLoc!\n".$errMsg,$SBR))     if (! defined $optRdbLoc);
    return(&errSbr("not def fileAbbrRdb!\n".$errMsg,$SBR))   if (! defined $fileAbbrRdb);
    return(&errSbr("not def fileTmpSec!\n".$errMsg,$SBR))    if (! defined $fileTmpSec);
    return(&errSbr("not def fileTmpAcc!\n".$errMsg,$SBR))    if (! defined $fileTmpAcc);
    return(&errSbr("not def fileTmpHtm!\n".$errMsg,$SBR))    if (! defined $fileTmpHtm);
    return(&errSbr("not def fileOutPhdLoc!\n".$errMsg,$SBR)) if (! defined $fileOutPhdLoc);
    return(&errSbr("not def fileOutRdbLoc!\n".$errMsg,$SBR)) if (! defined $fileOutRdbLoc);
				# ------------------------------
				# syntax check
    return(&errSbr("ini: FORTRAN PHD optPhd ($optPhd3) has to be '3|both'\n".$errMsg))
	if ($optPhd3Loc !~ /^(3|both)$/);
				# ------------------------------
				# input files existing ?
    return(&errSbr("not def fileTmpSec!\n".$errMsg,$SBR))    if (! defined $fileTmpSec);
    return(&errSbr("not def fileTmpAcc!\n".$errMsg,$SBR))    if (! defined $fileTmpAcc);
    return(&errSbr("not def fileTmpHtm!\n".$errMsg,$SBR))    if (! defined $fileTmpHtm);

				# --------------------------------------------------
                                # RDB -> .phd files
				# --------------------------------------------------

                                # ++++++++++++++++++++++++++++++
                                # NOTE: not writing file.phd, yet yy
                                # ++++++++++++++++++++++++++++++

    if (0){                     # NOTE ONE DAY TO ADD!!!
        &open_file("$fhoutLoc",">$fileOutPhdLoc") || 
            return(&errSbr("could not open new=$fileOutPhdLoc\n".$errMsg,$SBR));
    }

				# --------------------------------------------------
				# now merge RDB files
				# --------------------------------------------------
                                # merge 3 (sec, acc, htm)
    if    ($optPhd3Loc eq "3" && $fileTmpHtm) {
        @fileTmp=($fileTmpSec,$fileTmpAcc,$fileTmpHtm); }
                                # merge 2 (sec,acc)
    else {
        @fileTmp=($fileTmpSec,$fileTmpAcc); }
                                # ------------------------------
                                # do merge
    ($Lok,$msg)=
        &phdRdbMerge($fileOutRdbLoc,$fileAbbrRdb,@fileTmp);

    return(&errSbrMsg("after phdRdbMerg on:".join(',',@fileTmp)." to $fileOutRdbLoc\n".
                      $errMsg,$msg,$SBR)) if (! $Lok);

    return(1,"ok $SBR");
}				# end of phdRunWrt

#==============================================================================
sub rdRdbAssociative {
    local ($fileInLoc,@des_in) = @_ ;
    local ($sbr_name,$fhinLoc,$Lhead,$Lbody,$Lfound,$it,$itrd,@tmp,$tmp,$des_in,$rd,
	   @des_head,@des_headin,@des_bodyin,@des_body,%ptr_rd2des,$nrow_rd,%rdrdb,
	   $Lscreen);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   rdRdbAssociative            reads content of an RDB file into associative array
#       in:                     Names used for columns in perl file, e.g.,
#                               "header,NALIGN,body,POS,NPROT" as arguments passed
#                               would result in:
#                               reading anything in file header using the keyword 'NALIGN'
#                               reading the columns named POS and NPROT
#       out:                    rdrdb{"NALIGN"},rdrdb{"POS","ct"},rdrdb{"NPROT","ct"},
#                               where ct counts the rows read,
#                               rdrdb{"NROWS"} returns the numbers of rows read
#--------------------------------------------------------------------------------
				# avoid warning
    $READHEADER="";
    $Lscreen=1;
				# set some defaults
    $fhinLoc="FHIN_RDB";$sbr_name="rdRdbAssociative";
				# get input
    $Lhead=$Lbody=$#des_headin=$#des_bodyin=0;
    foreach $des_in (@des_in){
	if   ($des_in=~/^not_screen/)        {$Lscreen=0;}
	elsif((!$Lhead) && ($des_in=~/head/)){$Lhead=1;$Lhead_all=1;}
	elsif((!$Lbody) && ($des_in=~/body/)){$Lbody=1;$Lhead=0; }
	elsif($Lhead)                        {push(@des_headin,$des_in);}
	elsif($Lbody)                        {$des_in=~s/\n|\s//g;;
					      push(@des_bodyin,$des_in);}
	else {
	    print "*** WARNING $sbr_name: input '$des_in' not recognised.\n";} }
    if ($Lscreen) { print "--- $sbr_name: header \t ";
		    foreach $it (@des_headin){print"$it,";}print"\n"; 
		    print "--- $sbr_name: body   \t ";
		    foreach $it (@des_bodyin){print"$it,";}print"\n"; }
				# --------------------------------------------------
				# read RDB file
				# --------------------------------------------------
    &open_file("$fhinLoc","$fileInLoc");
				# out: $READHEADER :whole header, one string
				#      @READCOL    : all columns
				#      @READNAME   :names of columns
    &rdRdbAssociativeNum($fhinLoc,0);
    close($fhinLoc);
				# ------------------------------
    $#des_head=0;		# process header
    @tmp=split(/\#\s?/,$READHEADER);
    if ($#des_headin>=1){
	foreach $des_in (@des_headin) {
	    $Lfound=0;
	    foreach $rd (@tmp){
		if ($rd =~ /^(PARA\s*:?\s*)?$des_in\s*[ :,\;=]/){
		    $tmp=$rd;$tmp=~s/\n|\s$//g;$tmp=~s/^.*$des_in//g;$tmp=~s/^\s*//g;
		    $tmp=~s/^[\s:\t]*//g;
		    if (defined $rdrdb{"$des_in"}){
			$rdrdb{"$des_in"}.="\t".$tmp;}
		    else {
			$rdrdb{"$des_in"}=$tmp;}
		    push(@des_head,$des_in);$Lfound=1;} }
	    print
		"--- $sbr_name: \t expected to find in header key word:\n",
		"---            \t '$des_in', but not in file '$fileInLoc'\n"
		    if (!$Lfound && $Lscreen); }}
    elsif ($Lhead_all) {		# whole header into $rdrdb{"header"}
	$rdrdb{"header"}="";
	foreach $rd (@tmp) { $rd=~s/^\s?|\n//g;
			     $rdrdb{"header"}.="# ".$rd."\n"; }}
				# ------------------------------
    $#des_body=0;		# get column numbers to be read
    foreach $des_in (@des_bodyin) {
	$Lfound=0;
	for($it=1; $it<=$#READNAME; ++$it) {
	    $rd=$READNAME[$it];$rd=~s/\s//g;
	    if ($rd eq $des_in) {
		$ptr_rd2des{"$des_in"}=$it;push(@des_body,$des_in);$Lfound=1;
		last;} }
	if((!$Lfound) && $Lscreen){
	    print"--- $sbr_name: \t expected to find column name:\n";
	    print"---            \t '$des_in', but not in file '$fileInLoc'\n";}}
				# ------------------------------
				# get format
    foreach $des_in(@des_bodyin) {
	$it=$ptr_rd2des{"$des_in"};
	if ( defined $it && defined $READFORMAT[$it] ) {
	    $rdrdb{"$des_in","format"}=$READFORMAT[$it];}
	else {
	    $rdrdb{"$des_in","format"}="8";}}
    $nrow_rd=0;
    foreach $des_in(@des_body) {
	$itrd=$ptr_rd2des{"$des_in"};
	@tmp=split(/\t/,$READCOL[$itrd]);
	if   ($nrow_rd==0)    {$nrow_rd=$#tmp;}
	elsif($nrow_rd!=$#tmp){print "*** WARNING $sbr_name: different number of rows\n";
			       print "***         in RDB file '$fileInLoc' for rows with ".
				   "key=$des_in, column=$itrd, prev=$nrow_rd, now=$#tmp,\n";}
	for ($it=1; $it<=$#tmp; ++$it){
	    $rdrdb{"$des_in",$it}=$tmp[$it];
	    $rdrdb{"$des_in",$it}=~s/\s//g;}
    }
    $rdrdb{"NROWS"}=$rdrdb{"NROWS"}=$nrow_rd;
				# ------------------------------
				# safe memory
    $READHEADER=""; $#READCOL=$#READNAME=$#READFORMAT=0;
    $#des_headin=$#des_body=$#tmp=$#des_head=0;
    undef %ptr_rd2des;
    $#des_in=0;                 # slim_is_in !
    
    return (%rdrdb);
}				# end of rdRdbAssociative

#===============================================================================
sub rdRdbAssociativeNum {
    local ($fhLoc2,@readnum) = @_ ;
    local ($ctLoc, @tmpar, $it, $ipos, $tmp);
    $[ =1 ;
#----------------------------------------------------------------------
#   rdRdbAssociativeNum         reads from a file of Michael RDB format:
#       in:                     $fhLoc,@readnum,$readheader,@readcol,@readname,@readformat
#         $fhLoc:               file handle for reading
#         @readnum:             vector containing the number of columns to be read, if empty,
#                               then all columns will be read!
#         $READHEADER:          returns the complete header as one string
#         @READCOL:             returns all columns to be read (tab separated)
#         @READNAME:            returns the names of the columns
#         @READFORMAT:          returns the format of each column
#----------------------------------------------------------------------
    $READHEADER=""; $#READCOL=$#READNAME=$#READFORMAT=0;
    for ($it=1; $it<=$#readnum; ++$it) { $READCOL[$it]=""; }
    $ctLoc= 0;
    $tmpct=0;
    while ( <$fhLoc2> ) {	# ------------------------------
	++$tmpct;		# header  
	if ( /^\#/ ) { 
	    $READHEADER.= "$_";
	    next; }
	$rd=$_;$rd=~s/^\s+|\s+$//g;
	next if (length($rd)<2);
	++$ctLoc;		# count non-comment
				# ------------------------------
				# names
	if ($ctLoc==1){
	    $rd=$_;$rd=~s/^\t+|\t$//g;@tmpar=split(/\t/,$rd);
				# process wild card
	    if ($#readnum==0 || $readnum[1]==0 ||
		$readnum[1] !~ /[0-9]/ || ! defined $readnum[1] ) {
		foreach $it (1..$#tmpar){
		    $readnum[$it]=$it;$READCOL[$it]=""; }}
	    foreach $it (1..$#readnum){
		$tmp_name=$tmpar[$readnum[$it]];$tmp_name=~s/\s|\n//g;
		$READNAME[$it]="$tmp_name"; }
	    next; }
				# ------------------------------
				# skip format?
	if ($ctLoc==2 && $rd!~/\d+[SNF]\t|\t\d+[SNF]/){
	    ++$ctLoc; }
	if ($ctLoc==2) {	# read format
	    $rd=$_;$rd=~s/^\t+|\t$//g;@tmpar=split(/\t/,$rd);
	    foreach $it (1..$#readnum){
		$ipos=$readnum[$it];$tmp=$tmpar[$ipos]; $tmp=~s/\s//g;
		$READFORMAT[$it]=$tmp; }
	    next; }
				# ------------------------------
				# data
	$rd=$_;$rd=~s/^\t+|\t$//g;@tmpar=split(/\t/,$rd);
	foreach $it (1..$#readnum){
	    next if (! defined $tmpar[$readnum[$it]]); 
	    $READCOL[$it].=$tmpar[$readnum[$it]] . "\t"; }
    }
				# ------------------------------
				# massage FORMAT/COL/NAME
    foreach $it (1..$#READCOL){
	$READFORMAT[$it]=~ s/^\s+//g   if (defined $READFORMAT[$it]);
	$READFORMAT[$it]=~ s/\t$|\n//g if (defined $READFORMAT[$it]);
	$READNAME[$it]=~ s/^\s+//g     if ($#READNAME>0);
	$READNAME[$it]=~s/\t|\n//g;
	$READNAME[$it]=~s/\n//g        if ($#READNAME>0); 
	$READCOL[$it] =~ s/\t$|\n//g;  # correction: last not return!
    }
}				# end of rdRdbAssociativeNum

#==============================================================================
sub rd_rdb_associative {
    local ($file_in,@des_in) = @_ ;
    local ($sbr_name,$fhin,$Lhead,$Lbody,$Lfound,$it,$itrd,@tmp,$tmp,$des_in,$rd,
	   @des_head,@des_headin,@des_bodyin,@des_body,%ptr_rd2des,$nrow_rd,%rdrdb,
	   $Lscreen);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   rd_rdb_associative          reads the content of an RDB file into an associative
#                               array
#       in:                     Names used for columns in perl file, e.g.,
#                               "header,NALIGN,body,POS,NPROT" as arguments passed
#                               would result in:
#                               reading anything in file header using the keyword 'NALIGN'
#                               reading the columns named POS and NPROT
#                       ALL:    'head,body'
#       out:                    rdrdb{"NALIGN"},rdrdb{"POS","ct"},rdrdb{"NPROT","ct"},
#                               where ct counts the rows read,
#                               rdrdb{"NROWS"} returns the numbers of rows read
#                       HEADER: rdrdb{"header"}
#                       NAMES:  rdrdb{"names"} 
#--------------------------------------------------------------------------------
				# avoid warning
    $READHEADER="";
    $Lscreen=1;
				# set some defaults
    $fhin="FHIN_RDB";
    $sbr_name="rd_rdb_associative";
				# get input
    $Lhead=$Lbody=$Lhead_all=$Lbody_all=$#des_headin=$#des_bodyin=0;
    foreach $des_in(@des_in){
	if   ($des_in=~/^not_screen/)        {$Lscreen=0;}
	elsif((!$Lhead) && ($des_in=~/head/)){$Lhead=1;$Lhead_all=1;}
	elsif((!$Lbody) && ($des_in=~/body/)){$Lbody=1;$Lhead=0; $Lbody_all=1;}
	elsif($Lhead)                        {push(@des_headin,$des_in); $Lhead_all=0;}
	elsif($Lbody)                        {$des_in=~s/\n|\s//g;; $Lbody_all=0;
					      push(@des_bodyin,$des_in);}
	else {print "*** WARNING $sbr_name: input '$des_in' not recognised.\n";} }
    if ($Lscreen) { print "--- $sbr_name: header \t ";
		    foreach $it (@des_headin){print"$it,";}print"\n"; 
		    print "--- $sbr_name: body   \t ";
		    foreach $it (@des_bodyin){print"$it,";}print"\n"; }
				# --------------------------------------------------
				# read RDB file
				# --------------------------------------------------
    &open_file("$fhin","$file_in");
				# out: $READHEADER :whole header, one string
				#      @READCOL    : all columns
				#      @READNAME   :names of columns
    &read_rdb_num2($fhin,0);
    close($fhin);
				# ------------------------------
				# process header
    $#des_head=0;
    @tmp=split(/\#\s?/,$READHEADER);
    if ($#des_headin>=1){
	foreach $des_in (@des_headin) {
	    $Lfound=0;
	    foreach $rd (@tmp){
		if ($rd =~ /^$des_in[ :,\;]/){
		    $tmp=$rd;$tmp=~s/\n|\s$//g;
		    $tmp=~s/$des_in//g;$tmp=~s/^\s*//g;
		    if (defined $rdrdb{"$des_in"}){
			$rdrdb{"$des_in"}.="\t".$tmp;}
		    else {
			$rdrdb{"$des_in"}=$tmp;}
		    push(@des_head,$des_in);
		    $Lfound=1;} }
	    if(!$Lfound && $Lscreen){
		print"--- $sbr_name: \t expected to find in header key word:\n";
		print"---            \t '$des_in', but not in file '$file_in'\n";}
	}}
    elsif ($Lhead_all) {		# whole header into $rdrdb{"header"}
	$rdrdb{"header"}="";
	foreach $rd (@tmp) { 
	    $rd=~s/^\s?|\n//g;
	    $rdrdb{"header"}.="# ".$rd."\n"; }}
				# ------------------------------
				# get column numbers to be read
    $#des_body=0;
    if (! $Lbody_all){
	foreach $des_in (@des_bodyin) {
	    $Lfound=0;
	    for($it=1;$it<=$#READNAME;++$it) {
		$rd=$READNAME[$it];
		if ($rd eq $des_in) {$ptr_rd2des{"$des_in"}=$it;push(@des_body,$des_in);
				     $Lfound=1;last;} }
	    if((!$Lfound) && $Lscreen){
		print"--- $sbr_name: \t expected to find column name:\n";
		print"---            \t '$des_in', but not in file '$file_in'\n";}}}
    else {
	foreach $it(1..$#READNAME){
	    $name=$READNAME[$it];$ptr_rd2des{"$name"}=$it;
	    push(@des_body,$name);}}
				# ------------------------------
				# get format
    foreach $des_in(@des_bodyin) {
	$it=$ptr_rd2des{"$des_in"};
	if ( (defined $it) && (defined $READFORMAT[$it]) ) {
	    $rdrdb{"$des_in","format"}=$READFORMAT[$it];}
	else {
	    $rdrdb{"$des_in","format"}="8";}}

    $nrow_rd=0;$names="";
    foreach $des_in(@des_body) {
	$itrd=$ptr_rd2des{"$des_in"};
	@tmp=split(/\t/,$READCOL[$itrd]);
	if ($nrow_rd==0){
	    $nrow_rd=$#tmp;}
	elsif($nrow_rd!=$#tmp){
	    print "*** WARNING $sbr_name: different number of rows\n";
	    print "*** WARNING in RDB file '$file_in' for rows with ".
		  "key= $des_in and previous column no=$itrd,\n";}
	$names.="$des_in".",";
	for($it=1;$it<=$#tmp;++$it){
	    $rdrdb{"$des_in",$it}=$tmp[$it];}
    }
    $rdrdb{"NROWS"}=$nrow_rd;
    $names=~s/,$//g;$rdrdb{"names"}=$names;
    return (%rdrdb);
}				# end of rd_rdb_associative

#==============================================================================
sub rdbphd_to_dotpred {
    local($Lscreen,$nres_per_row,$thresh_acc,$thresh_htm,$thresh_sec,
	  $opt_phd,$file_out,$protname,$Ldo_htmref,$Ldo_htmtop,@file) = @_ ;
    local($fhin,@des,@des_rd,@des_sec,@des_rd_sec,@des_acc,@des_rd_acc,@des_htm,@des_rd_htm,
	  %rdb_rd,%rdb,$file,$it,$ct,$mode_wrt,$fhout);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   rdbphd_to_dotpred           converts RDB files of PHDsec,acc,htm (both/3)
#                               to .pred files as used for PP server
#--------------------------------------------------------------------------------
    $fhin= "FHIN_RDBPHD_TO_DOTPRED";
    $fhout="FHOUT_RDBPHD_TO_DOTPRED";
				# note: @des same succession as @des_rd !!
    @des_rd_0 =     ("No", "AA");
    @des_0=         ("pos","aa");
    @des_rd_acc=    ("Obie","Pbie","OREL","PREL","RI_A");
    @des_acc=       ("obie","pbie","oacc","pacc","riacc");
				# horrible hack 20-01-98
    $fhinLoc="FHIN_rdbphd_to_dotpred";
    &open_file("$fhinLoc",$file[1]);
				# get RI for first file
    while(<$fhinLoc>){
	next if ($_=~/^\#/);
	if    ($_=~/RI\_S/){$riTmp="RI_S";}
	elsif ($_=~/RI\_H/){$riTmp="RI_H";}
	elsif ($_=~/RI\_A/){$riTmp="RI_A";}
	else  {print "*** '$_'\n";print "*** ERROR in RDB header $file[1]\n";}
	last;}close($fhinLoc);
	
    if    ($Ldo_htmref && $Ldo_htmtop) {
	@des_rd_htm=("OHL", "PHL", "RI_H", "pH",    "pL"    ,"PFHL", "PRHL", "PiTo" );
	@des_htm=   ("ohtm","phtm","rihtm",  "prHhtm","prLhtm","pfhtm","prhtm","pthtm");}
    elsif ($Ldo_htmref) {
	@des_rd_htm=("OHL", "PHL", "RI_H", "pH",    "pL"    ,"PFHL", "PRHL");
	@des_htm=   ("ohtm","phtm","rihtm",  "prHhtm","prLhtm","pfhtm","prhtm");}
    elsif ($Ldo_htmtop) {
	@des_rd_htm=("OHL", "PHL", "RI_H", "pH",    "pL"    ,"PFHL" ,"PiTo" );
	@des_htm=   ("ohtm","phtm","rihtm",  "prHhtm","prLhtm","pfhtm","pthtm");}
    else {
	@des_rd_htm=("OHL", "PHL", "$riTmp", "pH",    "pL"    ,"PFHL" );
	@des_htm=   ("ohtm","phtm","rihtm",  "prHhtm","prLhtm","pfhtm");}
    @des_rd_sec=    ("OHEL","PHEL","$riTmp", "pH",    "pE",    "pL");
    @des_sec=       ("osec","psec","risec",  "prHsec","prEsec","prLsec");
				# headers
    @deshd_rd_0=  ();
    if    ($Ldo_htmref && $Ldo_htmtop) {
	@deshd_rd_htm=("NHTM_BEST","NHTM_2ND_BEST",
#		       "REL_BEST","REL_BEST_DIFF",
		       "REL_BEST_DPROJ","MODEL","MODEL_DAT",
		       "HTMTOP_PRD","HTMTOP_RID","HTMTOP_RIP");}
    elsif ($Ldo_htmref) {
	@deshd_rd_htm=("NHTM_BEST","NHTM_2ND_BEST",
		       "REL_BEST_DPROJ","MODEL","MODEL_DAT");}
    elsif ($Ldo_htmtop) {
	@deshd_rd_htm=("HTMTOP_PRD","HTMTOP_RID","HTMTOP_RIP");}
    else {
	$#deshd_rd_htm=0;}
				# ------------------------------
				# read RDB files
				# ------------------------------
    $ct=0;
    foreach $file (@file){
	next if (! -e $file);
	++$ct;
	undef %rdb_rd;
	if ($ct==1) {
	    @des_rd=@des_rd_0;@des=@des_0;@deshd_rd=@deshd_rd_0;}
	else {
	    $#des_rd=$#des=$#deshd_rd=0;}
				# find out whether from PHDsec, PHDacc, or PHDhtm
	if   (&is_rdb_sec($file)){
	    $phd="sec";push(@des_rd,@des_rd_sec);push(@des,@des_sec);}
	elsif(&is_rdb_acc($file)){
	    $phd="acc";push(@des_rd,@des_rd_acc);push(@des,@des_acc);}
	elsif(&is_rdb_htmtop($file) || &is_rdb_htmref($file) || &is_rdb_htm($file)){
	    $phd="htm";push(@des,@des_htm);
	    push(@des_rd,@des_rd_htm);push(@deshd_rd,@deshd_rd_htm);}
	else {
	    print "*** ERROR rdbphd_to_dotpred: no RDB format recognised (file=$file)\n";
	    die; }
#	print "--- rdbphd_to_dotpred reading '$file' (phd=$phd)\n";
	%rdb_rd=
	    &rd_rdb_associative($file,"not_screen","header",@deshd_rd,"body",@des_rd); 
				# rename data (separate for PHDsec,acc,htm)
	foreach $it (1 .. $#des_rd) {
	    $ct=1;
	    while (defined $rdb_rd{"$des_rd[$it]",$ct}) {
		$rdb{"$des[$it]",$ct}=$rdb_rd{"$des_rd[$it]",$ct}; 
		++$ct; }}
	foreach $deshdr (@deshd_rd){ # rename header
	    $rdb{"$deshdr"}="UNK";
	    $rdb{"$deshdr"}=$rdb_rd{"$deshdr"} if (defined $rdb_rd{"$deshdr"});}
    }
				# ------------------------------
				# now transform to strings
				# ------------------------------
    &rdbphd_to_dotpred_getstring(@des_0,@des_sec,@des_acc,@des_htm);
				# now subsets
    &rdbphd_to_dotpred_getsubset;
				# convert symbols
    $STRING{"osec"}=~s/L/ /g    if (defined $STRING{"osec"});
    $STRING{"psec"}=~s/L/ /g    if (defined $STRING{"psec"});
    $STRING{"obie"}=~s/i/ /g    if (defined $STRING{"obie"});
    $STRING{"pbie"}=~s/i/ /g    if (defined $STRING{"pbie"});
    if (defined $STRING{"ohtm"}) { 
	$STRING{"ohtm"}=~s/L/ /g;  
	if ($opt_phd !~ /htm/){
	    $STRING{"ohtm"}=~s/H/T/g;$STRING{"ohtm"}=~s/E/ /g; }}
    if (defined $STRING{"phtm"}) { 
	$STRING{"phtm"}=~s/L/ /g;  
	if ($opt_phd !~ /htm/){
	    $STRING{"phtm"}=~s/H/T/g;$STRING{"phtm"}=~s/E/ /g; }}
    if (defined $STRING{"pfhtm"}) { 
	$STRING{"pfhtm"}=~s/L/ /g; 
	if ($opt_phd !~ /htm/){
	    $STRING{"pfhtm"}=~s/H/T/g;$STRING{"pfhtm"}=~s/E/ /g; }}
    if (defined $STRING{"prhtm"}) { 
	$STRING{"prhtm"}=~s/L/ /g; 
	if ($opt_phd !~ /htm/){
	    $STRING{"prhtm"}=~s/H/T/g;$STRING{"prhtm"}=~s/E/ /g; }}

    @des_wrt=@des_0;
    $#htm_header=0;
    if    ( (length($STRING{"psec"})>3) && (length($STRING{"pacc"})>3) && 
	    (length($STRING{"phtm"})>3) ) { 
	push(@des_wrt,@des_sec,"subsec",@des_acc,"subacc",@des_htm,"subhtm"); 
	$mode_wrt="3";}
    elsif ( (length($STRING{"psec"})>3) && (length($STRING{"pacc"})>3) ) {
	push(@des_wrt,@des_sec,"subsec",@des_acc,"subacc"); 
	$mode_wrt="both"; }
    elsif ( length($STRING{"psec"})>3 ) { 
	push(@des_wrt,@des_sec,"subsec");                   
	$mode_wrt="sec"; }
    elsif ( length($STRING{"pacc"})>3 ) { 
	push(@des_wrt,@des_acc,"subacc");                   
	$mode_wrt="acc"; }
    elsif ( length($STRING{"phtm"})>3 ) { 
	push(@des_wrt,"ohtm","phtm","rihtm","prHhtm","prLhtm","subhtm","pfhtm");
	push(@des_wrt,"prhtm")  if ($Ldo_htmref);
	push(@des_wrt,"pthtm")  if ($Ldo_htmtop);
	$mode_wrt="htm"; 
	@htm_header=
	    &rdbphd_to_dotpred_head_htmtop(@deshd_rd_htm)
		if ($Ldo_htmref || $Ldo_htmtop); }
    else {
	print "*** ERROR rdbphd_to_dotpred: no \%STRING defined recognised\n";
	exit; }

    if ($Lscreen) {
	print "--- rdbphd_to_dotpred read from conversion:\n";
	&wrt_phdpred_from_string("STDOUT",$nres_per_row,$mode_wrt,$Ldo_htmref,
				 @des_wrt,"header",@htm_header); }
    &open_file("$fhout",">$file_out");
    &wrt_phdpred_from_string($fhout,$nres_per_row,$mode_wrt,$Ldo_htmref,
			     @des_wrt,"header",@htm_header); 
    close($fhout);
				# --------------------------------------------------
				# now collect for final file
				# --------------------------------------------------
    foreach $des ("aa","osec","psec","risec","oacc","pacc","riacc",
		  "ohtm","phtm","pfhtm","rihtm","prhtm","pthtm") {
	if (defined $STRING{$des}) {
	    if   ($des eq "aa") { 
		$nres=length($STRING{$des}); }
	    elsif(($des=~/^p/)&&(length($STRING{$des})>$nres)){
		$nres=length($STRING{$des}); }
	    $phd_fin{"$protname",$des}=$STRING{$des}; }}
    $phd_fin{"$protname","nres"}=$nres;
				# ------------------------------
				# save memory
    undef %STRING; undef %rdb_rd; undef %rdb;
    return(%phd_fin);
}				# end of rdbphd_to_dotpred

#==============================================================================
sub rdbphd_to_dotpred_getstring {
    local (@des) = @_ ;
    local ($des,$ct);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   rdbphd_to_dotpred_getstring transform $rdb{"osec","1..n"} to $STRING{"osec"}
#       in::                     file
#       in / out GLOBAL:         %STRING, %rdb,$thresh_*,
#--------------------------------------------------------------------------------
    foreach $des (@des) {
	$STRING{$des}="";$ct=1;
	if ($des !~ /oacc|pacc/ ){
	    while (defined $rdb{$des,$ct}) {
		$STRING{$des}.=$rdb{$des,$ct};
		++$ct; } }
	else {
	    while (defined $rdb{$des,$ct}) {
		$STRING{$des}.=&exposure_project_1digit($rdb{$des,$ct});
		++$ct; } } }
}				# end of rdbphd_to_dotpred_getstring

#==============================================================================
sub rdbphd_to_dotpred_getsubset {
    local ($des,$ct,$desout,$thresh,$kwdPhd,$desrel);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   rdbphd_to_dotpred_getsubset assigns subsets:
#       in:                     file
#       in / out GLOBAL:        %STRING, %rdb,$thresh_*,
#--------------------------------------------------------------------------------
    foreach $des ("sec","acc","htm"){
				# assign thresholds
	if    ($des eq "sec") { $thresh=$thresh_sec; }
	elsif ($des eq "acc") { $thresh=$thresh_acc; }
	elsif ($des eq "htm") { $thresh=$thresh_htm; }

	$desphd="p".$des;
				# note: for PHDacc subset on three states (b,e,i)
	$desphd="p"."bie"       if ($des eq "acc");
				# ignore different modes, than existing
	next if (! defined $rdb{$desphd,"1"});
	$desout="sub".$des;
	$desrel="ri".$des;
	$STRING{$desout}="";$ct=1; # initialise
	while ( defined $rdb{$desphd,$ct}) {
	    if (defined $rdb{$desrel,$ct} && $rdb{$desrel,$ct} >= $thresh) {
		$STRING{$desout}.=$rdb{$desphd,$ct}; }
	    else {
		$STRING{$desout}.=".";}
	    ++$ct; }
    }
}				# end of rdbphd_to_dotpred_getsubset

#==============================================================================
sub rdbphd_to_dotpred_head_htmtop {
    local (@des)= @_ ;  local ($des,$tmp,@tmp,@out);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   rdbphd_to_dotpred_head_htmtop writes the header for htmtop
#--------------------------------------------------------------------------------
    $#out=0;
    foreach $des (@des){
	if (defined $rdb_rd{$des}){
	    $tmp=$rdb_rd{$des};$tmp=~s/^:*|:*$//g;
	    if ($tmp=~/\:/){
		$#tmp=0;@tmp=split(/:/,$tmp);} else {@tmp=("$tmp");}
	    if ($des !~/MODEL/){ # purge blanks and comments
		foreach $tmp (@tmp) {$tmp=~s/\(.*//g;$tmp=~s/\s//g;}}
	    foreach $tmp (@tmp) {
		push(@out,"$des:$tmp");}}}
    return(@out);
}				# end of rdbphd_to_dotpred_head_htmtop

#===============================================================================
sub read_rdb_num {
    local ($fh, @readnum) = @_ ;
    local ($ct, @tmpar, $it, $ipos, $tmp);
    $[=1 ; 
#----------------------------------------------------------------------
#   read_rdb_num                reads from a file of Michael RDB format:
#       in:                     $fh,@readnum,$readheader,@readcol,@readname,@readformat
#         $fh:                  file handle for reading
#         @readnum:             vector containing the number of columns to be read
#         $readheader:          returns the complete header as one string
#         @readcol:             returns all columns to be read
#         @readname:            returns the names of the columns
#         @readformat:          returns the format of each column
#----------------------------------------------------------------------
    $readheader = ""; $#readcol = 0; $#readname = 0; $#readformat = 0;

    for ($it=1; $it<=$#readnum; ++$it) { 
	$readcol[$it]=""; $readname[$it]=""; $readformat[$it]=""; }

    $ct = 0;
    while ( <$fh> ) {
	if ( /^\#/ ) {		              # header  
	    $readheader .= "$_"; }
	else {		              # rest:
	    ++$ct;
	    if ( $ct >= 3 ) {	              # col content
		@tmpar= split(/\t/);
		for ($it=1; $it<=$#readnum; ++$it) {
                    if (defined $tmpar[$readnum[$it]]){
                        $readcol[$it].= $tmpar[$readnum[$it]] . " ";}}}
	    elsif ( $ct == 1 ) {              # col name
		@tmpar= split(/\t/);
		for ($it=1; $it<=$#readnum; ++$it) {
                    if (defined $tmpar[$readnum[$it]]){
                        $readname[$it].= $tmpar[$readnum[$it]];}} }
	    elsif ( $ct == 2 ) {	      # col format
		@tmpar= split(/\t/);
		for ($it=1; $it<=$#readnum; ++$it) {
		    $ipos= $readnum[$it];
                    if (defined $tmpar[$readnum[$ipos]]){
                        $tmp= $tmpar[$ipos]; $tmp =~ s/\s//g;
                        $readformat[$it].= $tmp . " ";}}}
	}
    } 
    for ($it=1; $it<=$#readname; ++$it) {
	$readcol[$it] =~ s/^\s+//g;	      # correction, if first characters blank
	$readformat[$it] =~ s/^\s+//g; $readname[$it] =~ s/^\s+//g;
	$readcol[$it] =~ s/\n//g;	      # correction: last not return!
	$readformat[$it] =~ s/\n//g; $readname[$it] =~ s/\n//g; 
    }
}				# end of read_rdb_num

#===============================================================================
sub read_rdb_num2 {
    local ($fh, @readnum) = @_ ;
    local ($ct, @tmpar, $it, $ipos, $tmp);
    $[ =1 ;
#----------------------------------------------------------------------
#   read_rdb_num2               reads from a file of Michael RDB format:
#       in:                     $fh,@readnum,$readheader,@readcol,@readname,@readformat
#         $fh:                  file handle for reading
#         @readnum:             vector containing the number of columns to be read, if empty,
#                               then all columns will be read!
#         $READHEADER:          returns the complete header as one string
#         @READCOL:             returns all columns to be read
#         @READNAME:            returns the names of the columns
#         @READFORMAT:          returns the format of each column
#----------------------------------------------------------------------
    $READHEADER=""; $#READCOL=$#READNAME=$#READFORMAT= 0;
    for ($it=1; $it<=$#readnum; ++$it) { $READCOL[$it]=""; }
    $ct = 0;
    while ( <$fh> ) {
	if ( /^\#/ ) {$READHEADER.= "$_"; # header  
		      next;}
	++$ct;			# rest
	if ( $ct >= 3 ) {	              # col content
	    @tmpar=split(/\t/);
	    for ($it=1; $it<=$#readnum; ++$it) {
		if (defined $tmpar[$readnum[$it]]) {
		    $READCOL[$it].=$tmpar[$readnum[$it]] . "\t"; }} }
	elsif ( $ct==1 ) {	      # col name
	    $_=~s/\t$//g;@tmpar=split(/\t/);
				# care about wild card
	    if ( ($#readnum==0)||($readnum[1]==0) ) {
		for ($it=1;$it<=$#tmpar;++$it) {$readnum[$it]=$it;}
		for ($it=1;$it<=$#tmpar;++$it) {$READCOL[$it]=""; } }
	    
	    for ($it=1; $it<=$#readnum; ++$it) {$tmp_name=$tmpar[$readnum[$it]];
						$tmp_name=~s/\s|\n//g;
						$READNAME[$it]="$tmp_name";} }
	elsif ( $ct==2 ) {	      # col format
	    if ($_=~/\t\d+[NSF]|\d+[NSF]\t/){
		@tmpar=split(/\t/);
		for ($it=1; $it<=$#readnum; ++$it) {
		    $ipos=$readnum[$it];$tmp=$tmpar[$ipos]; $tmp=~s/\s//g;
		    $READFORMAT[$it]=$tmp;}}
	    else {		# no format given, read line
		@tmpar=split(/\t/);
		for ($it=1; $it<=$#readnum; ++$it) {
		    if (defined $tmpar[$readnum[$it]]) {
			$READCOL[$it].=$tmpar[$readnum[$it]] . "\t";}}}}
    }
    for ($it=1; $it<=$#READNAME; ++$it) {
	if (!defined $READFORMAT[$it]){
	    print "-*- WARN lib-br.pl:read_rdb_num2: READFORMAT for it=$it not defined\n";
	    $READFORMAT[$it]=" ";}
	$READFORMAT[$it]=~ s/^\s+//g;
	if ($#READNAME>0) { $READNAME[$it]=~ s/^\s+//g;}
	$READCOL[$it] =~ s/\t$|\n//g;	      # correction: last not return!
	$READFORMAT[$it]=~ s/\t$|\n//g;$READNAME[$it]=~s/\t|\n//g;
	if ($#READNAME>0) { $READNAME[$it]=~s/\n//g; }
    }
}				# end of read_rdb_num2

#==============================================================================
sub run_program {
    local ($cmd,$fhLogFile,$action) = @_ ;
    local ($out_command,$cmdtmp);
    $[ =1;

    ($cmdtmp,@out_command)=split(",",$cmd) ;

    print "--- running command: \t $cmdtmp"  if ((! defined $Lverb)||$Lverb);
    print " do='$action'"                    if (defined $action); 
    print "\n" ;
				# opens cmdtmp into pipe
    open (TMP_CMD, "|$cmdtmp") || 
	(do {print $fhLogFile "Cannot run command: $cmdtmp\n" if ( $fhLogFile ) || 
		 warn "Cannot run command: '$cmdtmp'\n" ;
	     exec '$action' if (defined $action);
	 });

    foreach $command (@out_command) { # delete end of line, and leading blanks
	$command=~s/\n//; $command=~s/^\s*|\s*$//g;
	print TMP_CMD "$command\n" ;
    }
    close (TMP_CMD) ;		# upon closing: cmdtmp < @out_command executed
}				# end of run_program

#==============================================================================
sub safWrt {
    local($fileOutLoc,%tmp) = @_ ;
    local(@nameLoc,@stringLoc,$tmp,$sbrName,$Lok);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   safWrt                      writing an SAF formatted file of aligned strings
#       in:                     $fileOutLoc       output file
#                                   = "STDOUT"    -> write to screen
#       in:                     $tmp{"NROWS"}     number of alignments
#       in:                     $tmp{"id", $it} name for $it
#       in:                     $tmp{"seq",$it} sequence for $it
#       in:                     $tmp{"PER_LINE"}  number of res per line (def=50)
#       in:                     $tmp{"HEADER"}    'line1\n,line2\n'..
#                                   with line1=   '# NOTATION ..'
#       out:                    1|0,msg implicit: file
#       err:                    ok-> 1,ok | error -> 0,message
#--------------------------------------------------------------------------------
    $sbrName="lib-br:safWrt"; $fhoutLoc="FHOUT_safWrt";
                                # check input
    return(0,"*** ERROR $sbrName: no acceptable output file ($fileOutLoc) defined\n") 
        if (! defined $fileOutLoc || length($fileOutLoc)<1 || $fileOutLoc !~/\w/);
    return(0,"*** ERROR $sbrName: no input given (or not input{NROWS})\n") 
        if (! defined %tmp || ! %tmp || ! defined $tmp{"NROWS"} );
    return(0,"*** ERROR $sbrName: tmp{NROWS} < 1\n") 
        if ($tmp{"NROWS"} < 1);
    $tmp{"PER_LINE"}=50         if (! defined $tmp{"PER_LINE"});
    $fhoutLoc="STDOUT"          if ($fileOutLoc eq "STDOUT");
                                # ------------------------------
                                # open new file
    if ($fhoutLoc ne "STDOUT") {
	&open_file("$fhoutLoc",">$fileOutLoc") ||
	    return(0,"*** ERROR $sbrName: failed opening fileOut=$fileOutLoc\n"); }
				# ------------------------------
				# write header
				# ------------------------------
    print $fhoutLoc "# SAF (Simple Alignment Format)\n","\# \n";
    print $fhoutLoc $tmp{"HEADER"} if (defined $tmp{"HEADER"});

				# ------------------------------
				# write data into file
				# ------------------------------
    for($itres=1; $itres<=length($tmp{"seq","1"}); $itres+=$tmp{"PER_LINE"}){
	foreach $itpair (1..$tmp{"NROWS"}){
	    printf $fhoutLoc "%-20s",$tmp{"id","$itpair"};
				# chunks of $tmp{"PER_LINE"}
	    $chunkEnd=$itres + ($tmp{"PER_LINE"} - 1);
	    foreach $itchunk ($itres .. $chunkEnd){
		last if (length($tmp{"seq","$itpair"}) < $itchunk);
		print $fhoutLoc substr($tmp{"seq","$itpair"},$itchunk,1);
				# add blank every 10
		print $fhoutLoc " " 
		    if ($itchunk != $itres && (int($itchunk/10)==($itchunk/10)));
	    }
	    print $fhoutLoc "\n"; }
	print $fhoutLoc "\n"; }
    
    print $fhoutLoc "\n";
    close($fhoutLoc);
    $#nameLoc=$#stringLoc=0;	# save space

    return(0,"*** ERROR $sbrName: failed to write file $fileOutLoc\n") if (! -e $fileOutLoc);
    return(1,"ok $sbrName");
}				# end of safWrt

#==============================================================================
sub sysCpfile {
    local($fileToCopy,$fileToCopyTo,$niceLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   sysCpfile                   system call '\\cp file1 file2' (or to dir)
#       in:                     file1,file2 (or dir), nice value (nice -19)
#       out:                    ok=(1,'cp a b') , else=(0,msg)
#-------------------------------------------------------------------------------
    $sbrName="sysCpfile";
    $niceLoc="" if (! defined $niceLoc);
    return(0,"*** $sbrName: missing input file '$fileToCopy'!") if (! -e $fileToCopy);
    return(0,"*** $sbrName: needs 2 arg 'fToCopy fToCopyTo'!") if (! defined $fileToCopyTo);

    if (-d $fileToCopyTo){	# is directory
	if ($fileToCopyTo !~/\/$/){$fileToCopyTo.="/";}}

    $Lok= system("\\cp $fileToCopy $fileToCopyTo");
#    return(0,"*** $sbrName: fail copy '$fileToCopy -> $fileToCopyTo' ($Lok)!") if (! $Lok);
    if    (-d $fileToCopyTo){	# is directory
	$tmp=$fileToCopy;$tmp=~s/^.*\///g;$tmp=$fileToCopyTo.$tmp;
	$Lok=0 if (! -e $tmp);}
    elsif (! -e $fileToCopyTo){ $Lok=0; }
    elsif (-e $fileToCopyTo)  { $Lok=1; }
    return(0,"*** $sbrName: fail copy '$fileToCopy -> $fileToCopyTo' ($Lok)!") if (! $Lok);
    return(1,"$niceLoc \\cp $fileToCopy $fileToCopyTo");
}				# end of sysCpfile

#==============================================================================
sub sysDate {
#    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   sysDate                     returns $Date
#       out:                    $Date (May 30, 1998 59:39:03)
#-------------------------------------------------------------------------------
    @tmp=("/home/phd/ut/phd99/scr/ctime.pl","/home/rost/pub/perl/ctime.pl");
				# ------------------------------
				# get function
    if (defined &localtime) {
	foreach $tmp(@tmp){
	    if (-e $tmp){$Lok=require("$tmp");
			 last;}}
	if (defined &ctime && &ctime && defined &localtime && &localtime){
#       	$date is e.g.:		Oct:14:13:06:47:1993
#       	@Date is e.g.:		Oct1413:06:471993
#        	&ctime(time) is e.g.:	Thu Oct 14 13:06:47 1993
	    @Date = split(' ',&ctime(time)) ; shift (@Date) ; 
	    $Date="$Date[2] $Date[3], $Date[$#Date]  $Date[4]";
	    return($Date);}
    }
				# ------------------------------
				# or get system time
    $localtime=`date`;
    @Date=split(/\s+/,$localtime);
    $Date="$Date[2] $Date[3], $Date[$#Date] $Date[4]";
    return($Date);
}				# end of sysDate

#==============================================================================
sub sysMvfile {
    local($fileToCopy,$fileToCopyTo,$niceLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   sysMvfile                   system call '\\mv file'
#       in:                     $fileToCopy,$fileToCopyTo (or dir),$niceLoc
#       out:                    ok=(1,'mv a b') , else=(0,msg)
#-------------------------------------------------------------------------------
    $sbrName="sysMvfile";
    $niceLoc="" if (! defined $niceLoc);
    return(0,"*** $sbrName: missing input file '$fileToCopy'!") if (! -e $fileToCopy);
    return(0,"*** $sbrName: needs 2 arg 'fToCopy fToCopyTo'!")  if (! defined $fileToCopyTo);
    system("$niceLoc \\mv $fileToCopy $fileToCopyTo");
    if (! -e $fileToCopyTo){
	return(0,"*** $sbrName: couldnt copy '$fileToCopy -> $fileToCopyTo' ($Lok)!");}
    return(1,"$niceLoc \\mv $fileToCopy $fileToCopyTo");
}				# end of sysMvfile

#==============================================================================
sub sysRunProg {
    local ($cmd,$fileScrLoc,$fhErrLoc) = @_ ;
    $[ =1;
#-------------------------------------------------------------------------------
#   sysRunProg                  pipes arguments into $prog, and cats the output
#                               from $prog into a file
#       in:                     $cmd,$fileScrLoc,$fhError
#       in:                     $cmd='prog,arg1,arg2' 
#       in:                          where prog is the program, e.g. 'wc -l, file1,file2'
#       in:                     $fileScrLoc     is the output file
#       in:                        NOTE: if not defined: buffered to STDOUT
#       in:                      = 0            to surpress writing
#       in:                     $fhError        filehandle for ERROR writing
#                                  NOTE: to STDOUT if not defined
#       in:                      = 0            to surpress writing
#       out:                    0|1,message
#       err:                    ok -> 1,ok | err -> 0,message
#-------------------------------------------------------------------------------
    $sbrName="lib-ut:sysRunProg";
    return(0,"*** ERROR $sbrName: argument program ($cmd) not defined\n") 
	if (! defined $cmd || length($cmd)<1);
    $fhErrLoc=0                 if (! defined $fhErrLoc);
    $fileScrLoc=0               if (! defined $fileScrLoc);

				# ------------------------------
				# dissect arguments
    ($prog,@arg)=split(/,/,$cmd);
    if    ($fhErrLoc && ! @arg) {
#	print $fhErrLoc "-*- WARN $sbrName: no arguments to pipe into:\n$prog\n";
    }
    elsif ($fhErrLoc) {
	print $fhErrLoc 
	    "--- $sbrName: system cmd=\n$prog\n--- $sbrName: fileOut=$fileScrLoc cmd IN:\n$cmd\n";}
				# ------------------------------
				# pipe output into file?
    $prog.=" | cat >> $fileScrLoc " if ($fileScrLoc);
				# ------------------------------
				# opens cmdtmp into pipe
    open (CMD, "|$prog") || 
	warn "*** $sbrName cannot run program '$prog $arg'";
				# get input arguments (< arg)
    foreach $tmp (@arg) {
	$tmp=~s/\n|^\s*|\s*$//; # delete end of line, and leading blanks 
	print CMD "$tmp\n" ;}
    close (CMD) ;		# upon closing: cmdtmp < @out_command executed    
    return(1,"ok $sbrName");
}				# end of sysRunProg

#===============================================================================
sub swissGetFile { 
    local ($idLoc,$LscreenLoc,@dirLoc) = @_ ; 
    local ($fileLoc,$dirLoc,$tmp,@dirSwissLoc);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   swissprotGetFile           returns SWISS-PROT file for given filename
#        in:                   $id,$LscreenLoc,@dirLoc
#        out:                  $file  (id or 0 for error)
#--------------------------------------------------------------------------------
    return($idLoc) if (-e $idLoc); # already existing directory
    $#dirLoc=0 if (! defined @dirLoc);
    if    (! defined $Lscreen){$Lscreen=0;}
    elsif (-d $Lscreen)       {@dirLoc=($Lscreen,@dirLoc);$Lscreen=0;}
    @dirSwissLoc=("/data/swissprot/current/"); # swiss dir's
#===============================================================================
				# add species sub directory
    foreach $dirLoc(@dirSwissLoc){
	next if (! defined $dirLoc || ! -d $dirLoc || $dirLoc !~/current/);
	$dirCurrent=$dirLoc;
	last;}
    $tmp=$idLoc;$tmp=~s/^[^_]+_(.).+$/$1/g;
    $dirSpecies=&complete_dir($dirCurrent)."$tmp"."/" if (defined $dirCurrent && -d $dirCurrent);
    push(@dirSwissLoc,$dirSpecies) if (defined $dirSpecies && -d $dirSpecies);
				# go through all directories
    foreach $dirLoc(@dirSwissLoc){
	next if (! defined $dirLoc);
	next if (! -d $dirLoc);	# directory not existing
	$fileLoc=&complete_dir($dirLoc)."$idLoc";
	return($fileLoc) if (-e $fileLoc);
	$tmp=$idLoc;$tmp=~s/^.*\///g; # purge directory
	$tmp=~s/^.*_(.).*$/$1/;$tmp=~s/\n//g; # get species
	$fileLoc=&complete_dir($dirLoc).$tmp."/"."$idLoc";
	return($fileLoc) if (-e $fileLoc);}
    return(0);
}				# end of swissGetFile

#===============================================================================
sub wrt_phdpred_from_string {
    local ($fh,$nres_per_row,$mode,$Ldo_htmref,@des) = @_ ;
    local (@des_loc,@header_loc,$Lheader);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   wrt_phdpred_from_string     write body of PHD.pred files from global array %STRING{}
#       in (GLOBAL)             %STRING, i.e., one line string with prediction,
#                               e.g., $STRING{"osec"} observed secondary structure
#--------------------------------------------------------------------------------
    if (! %STRING) { 
	print "*** ERROR wrt_phdpred_from_string: associative array \%STRING must be global\n";
	exit; }
    $#des_loc=$#header_loc=0;$Lheader=0;
    foreach $des(@des){
	if ($des eq "header"){ 
	    $Lheader=1;
	    next;}
	if (! $Lheader){push(@des_loc,$des);}
	else           {push(@header_loc,$des);}}
				# get length of proteins (number of residues)
    $des= $des_loc[2];		# hopefully always AA!
    $tmp= $STRING{$des};
    $nres=length($tmp);
				# --------------------------------------------------
				# now write out for 'both','acc','sec'
				# --------------------------------------------------
    if ($mode=~/3|both|sec|acc/){
	$nres_tmp=$nres;}
    else {
	$nres_tmp=0;}
    for($it=1;$it<=$nres_tmp;$it+=$nres_per_row) {
	print  $fh " \n \n";	# print empty before each PHD block
	$tmp=&myprt_npoints($nres_per_row,$it);
	printf $fh "%-17s %-s\n"," ",$tmp;
	foreach $_ (@des_loc) {
	    next if (! defined $STRING{"$_"});
	    next if (length($STRING{"$_"})<$it);
	    $tmp=substr($STRING{"$_"},$it,$nres_per_row);
	    next if (length($tmp)==0) ;
				# secondary structure
	    if   ($_=~/aa/)    {printf $fh "%8s %-7s |%-s|\n"," ","AA ",$tmp; }
	    elsif($_=~/osec/)  {printf $fh "%8s %-7s |%-s|\n"," ","OBS sec",$tmp; }
	    elsif($_=~/psec/)  {printf $fh "%8s %-7s |%-s|\n"," ","PHD sec",$tmp; }
	    elsif($_=~/risec/) {printf $fh "%8s %-7s |%-s|\n"," ","Rel sec",$tmp; }
	    elsif($_=~/prHsec/){print  $fh " detail: \n";
				printf $fh "%8s %-7s |%-s|\n"," ","prH sec",$tmp; }
	    elsif($_=~/prEsec/){printf $fh "%8s %-7s |%-s|\n"," ","prE sec",$tmp; }
	    elsif($_=~/prLsec/){printf $fh "%8s %-7s |%-s|\n"," ","prL sec",$tmp; }
	    elsif($_=~/subsec/){printf $fh "%-8s %-7s |%-s|\n"," subset:","SUB sec",$tmp;}
				# solvent accessibility
	    elsif($_=~/obie/)  {if($mode=~/both|3/){print $fh " accessibility: \n"; }
				printf $fh "%-8s %-7s |%-s|\n"," 3st:","O_3 acc",$tmp;}
	    elsif($_=~/pbie/)  {if (length($STRING{"obie"})>1){$txt=" ";} 
				else{if($mode=~/both|3/){print $fh " accessibility \n";}
				     $txt=" 3st: ";}
				printf $fh "%-8s %-7s |%-s|\n",$txt,"P_3 acc",$tmp; }
	    elsif($_=~/oacc/)  {printf $fh "%-8s %-7s |%-s|\n"," 10st:","OBS acc",$tmp;}
	    elsif($_=~/pacc/)  {if (length($STRING{"oacc"})>1){$txt=" ";}else{$txt=" 10st: ";}
				printf $fh "%-8s %-7s |%-s|\n",$txt,"PHD acc",$tmp; }
	    elsif($_=~/riacc/) {printf $fh "%8s %-7s |%-s|\n"," ","Rel acc",$tmp; }
	    elsif($_=~/subacc/){printf $fh "%-8s %-7s |%-s|\n"," subset:","SUB acc",$tmp; }
	}
    }
				# --------------------------------------------------
				# now write out for '3','htm'
				# --------------------------------------------------
    if ($mode=~/3|htm/){
	if ($mode=~/3/) {
	    $symh="T";
	    print $fh 
		" \n",
		"************************************************************\n",
		"*    PHDhtm Helical transmembrane prediction\n",
		"*           note: PHDacc and PHDsec are reliable for water-\n",
		"*                 soluble globular proteins, only.  Thus, \n",
		"*                 please take the  predictions above with \n",
		"*                 particular caution wherever transmembrane\n",
		"*                 helices are predicted by PHDhtm!\n",
		"************************************************************\n",
		" \n",
		" PHDhtm\n";
	} else {
	    $symh="H";}
	$nres_tmp=$nres;}
    else {
	$nres_tmp=0;}
				# ------------------------------
				# print header for topology asf
    if ($nres_tmp>0){
	if ($#header_loc>0){
	    &wrt_phdpred_from_string_htm_header($fh,@header_loc);}
	&wrt_phdpred_from_string_htm($fh,$nres_tmp,$nres_per_row,$symh,
				     $Ldo_htmref,@des_loc);}
}				# end of wrt_phdpred_from_string

#===============================================================================
sub wrt_phdpred_from_string_htm {
    local ($fh,$nres_tmp,$nres_per_row,$symh,$Ldo_htmref,@des_loc) = @_ ;
    local ($it,$tmp);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   wrt_phdpred_from_string_htm body of PHD.pred files from global array %STRING{} for HTM
#       in (GLOBAL)             %STRING, i.e., one line string with prediction,
#                               e.g., $STRING{"osec"} observed secondary structure
#--------------------------------------------------------------------------------
    @des=("AA");
    if (defined $STRING{"ohtm"}){
	$tmp=$STRING{"ohtm"}; $tmp=~s/L|\s//g;
	if (length($tmp)==0) {
	    $STRING{"ohtm"}="";}
	else {
	    push(@des,"OBS htm");}}
    push(@des,"PHD htm","Rel htm","detail","prH htm","prL htm",
	      "subset","SUB htm","other","PHDFhtm");
    if (defined $STRING{"prhtm"}){ push(@des,"PHDRhtm");}
    if (defined $STRING{"pthtm"}){ push(@des,"PHDThtm");}
    $sym{"AA"}=     "amino acid in one-letter code";
    $sym{"OBS htm"}="HTM's observed ($symh=HTM, ' '=not HTM)";
    $sym{"PHD htm"}="HTM's predicted by the PHD neural network\n".
	"---                system ($symh=HTM, ' '=not HTM)";
    $sym{"Rel htm"}="Reliability index of prediction (0-9, 0 is low)";
    $sym{"detail"}= "Neural network output in detail";
    $sym{"prH htm"}="'Probability' for assigning a helical trans-\n".
	"---                membrane region (HTM)";
    $sym{"prL htm"}="'Probability' for assigning a non-HTM region\n".
	"---          note: 'Probabilites' are scaled to the interval\n".
	"---                0-9, e.g., prH=5 means, that the first \n".
	"---                output node is 0.5-0.6";
    $sym{"subset"}= "Subset of more reliable predictions";
    $sym{"SUB htm"}="All residues for which the expected average\n".
	"---                accuracy is > 82% (tables in header).\n".
	"---          note: for this subset the following symbols are used:\n".
	"---             L: is loop (for which above ' ' is used)\n".
	"---           '.': means that no prediction is made for this,\n".
	"---                residue as the reliability is:  Rel < 5";
    $sym{"other"}=  "predictions derived based on PHDhtm";
    $sym{"PHDFhtm"}="filtered prediction, i.e., too long HTM's are\n".
	"---                split, too short ones are deleted";
    $sym{"PHDRhtm"}="refinement of neural network output ";
    $sym{"PHDThtm"}="topology prediction based on refined model\n".
	"---                symbols used:\n".
	"---             i: intra-cytoplasmic\n".
	"---             T: transmembrane region\n".
	"---             o: extra-cytoplasmic";
				# write symbols
    if ($Ldo_htmref) {
	print $fh "--- \n--- PhdTopology REFINEMENT AND TOPOLOGY PREDICTION: SYMBOLS\n";
	foreach $des(@des){
	    printf $fh "--- %-13s: %-s\n",$des,$sym{$des};}
	print $fh "--- \n--- PhdTopology REFINEMENT AND TOPOLOGY PREDICTION\n";}
    for($it=1;$it<=$nres_tmp;$it+=$nres_per_row) {
	$tmp=&myprt_npoints($nres_per_row,$it);
	printf $fh "%-17s %-s\n"," ",$tmp;
	foreach $_ (@des_loc) {
	    next if (length($STRING{"$_"})<$it);
	    $tmp=substr($STRING{"$_"},$it,$nres_per_row);
	    next if ((! defined $tmp) || (length($tmp)==0));
	    $format="%-".length($tmp)."s";$len=length($tmp);
				# helical transmembrane regions
	    if   ($_=~/aa/)    {printf $fh "%8s %-7s |%-s|\n"," ","AA ",$tmp; }
	    elsif($_=~/ohtm/)  {printf $fh "%8s %-7s |%-s|\n"," ","OBS htm",$tmp; }
	    elsif($_=~/phtm/)  {printf $fh "%8s %-7s |%-s|\n"," ","PHD htm",$tmp; }
	    elsif($_=~/pfhtm/) {printf $fh "%8s %-7s |%-s|\n"," ","other"," "; 
				printf $fh "%8s %-7s |%-s|\n"," ","PHDFhtm",$tmp; }
	    elsif($_=~/rihtm/) {printf $fh "%8s %-7s |%-s|\n"," ","Rel htm",$tmp; }
	    elsif($_=~/prHhtm/){print  $fh " detail: \n";
				printf $fh "%8s %-7s |%-s|\n"," ","prH htm",$tmp; }
	    elsif($_=~/prLhtm/){printf $fh "%8s %-7s |%-s|\n"," ","prL htm",$tmp; }
	    elsif($_=~/subhtm/){printf $fh "%-8s %-7s |%-s|\n"," subset:","SUB htm",$tmp;}

	    elsif($_=~/prhtm/) {printf $fh "%8s %-7s |%-s|\n"," ","PHDRhtm",$tmp; }
	    elsif($_=~/pthtm/) {printf $fh "%8s %-7s |%-s|\n"," ","PHDThtm",$tmp; }}}
    if ($Ldo_htmref) {
	print $fh
	    "--- \n",
	    "--- PhdTopology REFINEMENT AND TOPOLOGY PREDICTION END\n",
	    "--- \n";}
}				# end of wrt_phdpred_from_string

#===============================================================================
sub wrt_phdpred_from_string_htm_header {&wrt_phdpred_from_string_htmHdr(@_);} # alias

#===============================================================================
sub wrt_phdpred_from_string_htmHdr {
    local ($fh,@header) = @_ ;
    local ($header,$header_txt,$des,%txt,@des,%dat);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   wrt_phdpred_from_string_htmHdr writes the header for PHDhtm ref and top
#       in: header with (x1:x2), where x1 is the key and x2 the result
#--------------------------------------------------------------------------------
				# define notations
    $txt{"NHTM_BEST"}=     "number of transmembrane helices best model";
    $txt{"NHTM_2ND_BEST"}= "number of transmembrane helices 2nd best model";
    $txt{"REL_BEST_DPROJ"}="reliability of best model (0 is low, 9 high)";
    $txt{"MODEL"}=         "";
    $txt{"MODEL_DAT"}=     "";
    $txt{"HTMTOP_PRD"}=    "topology predicted ('in': intra-cytoplasmic)";
    $txt{"HTMTOP_RID"}=    "difference between positive charges";
    $txt{"HTMTOP_RIP"}=    "reliability of topology prediction (0-9)";
    $txt{"MOD_NHTM"}=      "number of transmembrane helices of model";
    $txt{"MOD_STOT"}=      "score for all residues";
    $txt{"MOD_SHTM"}=      "score for HTM added at current iteration step";
    $txt{"MOD_N-C"}=       "N  -  C  term of HTM added at current step";
    print  $fh			# first write header
	"--- \n",
	"--- ", "-" x 60, "\n",
	"--- PhdTopology prediction of transmembrane helices and topology\n",
	"--- ", "-" x 60, "\n",
	"--- \n",
	"--- PhdTopology REFINEMENT AND TOPOLOGY HEADER: ABBREVIATIONS\n",
	"--- \n";
				# ------------------------------
    $#des=0;			# extracting info
    foreach $header (@header_loc){
	($des,$header_txt)=split(/:/,$header);
	if ($des !~ /MODEL/){
	    push(@des,$des);
	    $dat{$des}=$header_txt;}}
				# writing notation
    foreach $des (@des,"MOD_NHTM","MOD_STOT","MOD_SHTM","MOD_N-C"){
	if ($des eq "MODEL_DAT") { # skip
	    next;}
	$tmp_des=$des;$tmp_des=~s/\_DPROJ//g;$tmp_des=~s/\s//g;
	printf $fh "--- %-13s: %-s\n",$tmp_des,$txt{$des};}
				# explaining algorithm
    print $fh 
	"--- \n",
	"--- ALGORITHM REF: The refinement is performed by a dynamic pro-\n",
	"--- ALGORITHM    : gramming-like procedure: iteratively the best\n",
	"--- ALGORITHM    : transmembrane helix (HTM) compatible with the\n",
	"--- ALGORITHM    : network output is added (starting from the  0\n",
	"--- ALGORITHM    : assumption, i.e.,  no HTM's  in the protein).\n",
	"--- ALGORITHM TOP: Topology is predicted by the  positive-inside\n",
	"--- ALGORITHM    : rule, i.e., the positive charges are compiled\n",
	"--- ALGORITHM    : separately  for all even and all odd  non-HTM\n",
	"--- ALGORITHM    : regions.  If the difference (charge even-odd)\n",
	"--- ALGORITHM    : is < 0, topology is predicted as 'in'.   That\n",
	"--- ALGORITHM    : means, the protein N-term starts on the intra\n",
	"--- ALGORITHM    : cytoplasmic side.\n",
	"--- \n";
    print $fh
	"--- PhdTopology REFINEMENT HEADER: SUMMARY\n";
				# writing info: first iteration
    printf $fh 
	" %-8s %-8s %-8s %-s \n","MOD_NHTM","MOD_STOT","MOD_SHTM","MOD_N-C";
    foreach $header (@header_loc){
	if ($header =~ /^MODEL_DAT/){
	    ($des,$header_txt)=split(/:/,$header);
	    @tmp=split(/,/,$header_txt);
	    printf $fh " %8d %8.3f %8.3f %-s\n",@tmp;}}
    print $fh
	"--- \n",
	"--- PhdTopology REFINEMENT AND TOPOLOGY HEADER: SUMMARY\n";
    foreach $des (@des){	# writing info: now rest
	if ($des ne "MODEL_DAT"){
	    $tmp_des=$des;$tmp_des=~s/_DPROJ|\s//g;
	    printf $fh "--- %-13s: %-s\n",$tmp_des,$dat{$des};}}
}				# end of wrt_phdpred_from_string_htmHdr

1;
