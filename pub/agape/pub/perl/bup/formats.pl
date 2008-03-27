#! /usr/bin/perl -w
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
#    This library contains routines related to protein db formats.             #
#    See also: file.pl (for all isHssp asf.) | hssp.pl | prot.pl               #
#                                                                              #
#------------------------------------------------------------------------------#
# 
# 
# -----------------------------------------------------------------------------# 
#                               ---------------------
#   formats                     internal subroutines:
#                               ---------------------
# 
#   checkMsfFormat              basic checking of msf file format
#   convDssp2fasta              converts DSSP to FASTA format
#   convFasta2gcg               convert fasta format to GCG format
#   convFastamul2many           1
#   convFssp2Daf                converts an HSSP file into the DAF format
#   convGcg2fasta               converts GCG to FASTA format
#   convHssp2Daf                converts an HSSP file into the DAF format
#   convHssp2msf                runs convert_seq for HSSP -> MSF
#   convHssp2seq                converts HSSP file to PIR(mul), FASTA(mul)
#   convMsf2Hssp                converts the MSF into an HSSP file
#   convMsf2saf                 converts MSF into SAF format
#   convPhd2col                 writes the prediction in column format
#   convPir2fasta               converts PIR to FASTA format
#   convSaf2many                converts SAF into many formats: saf2msf, saf2fasta, saf2pir
#   convSwiss2fasta             converts SWISS-PROT to FASTA format
#   convSeq2fasta               convert all formats to fasta
#   convSeq2fastaPerl           convert all formats to fasta (no fortran)
#   convSeq2pir                 convert all sequence formats to PIR
#   convSeq2gcg                 convert all formats to gcg
#   convSeq2seq                 convert all sequence-only formats to sequence only
#   copf2fasta                  runs copf.pl converting all input files to FASTA
#   dafRdAli                    read alignments from DAF format
#   dafWrtAli                   writes a file in output format of DAF
#   dafWrtAliHeader             writes the header for DAF file
#   dsspGetChain                extracts all chains from DSSP
#   dsspGetFile                 searches all directories for existing DSSP file
#   dsspGetFileLoop             loops over all directories
#   dsspRdSeq                   extracts the sequence from DSSP
#   fastaRdGuide                reads first sequence in list of FASTA format
#   fastaRdMul                  reads many sequences in FASTA db
#   fastaWrt                    writes a sequence in FASTA format
#   fastaWrtMul                 writes a list of sequences in FASTA format
#   fsspGetFile                 searches all directories for existing FSSP file
#   fsspGetFileLoop             loops over all directories
#   fsspRdSummary               read the summary table of an FSSP file
#   fssp_rd_ali                 reads one entire alignment for an open FSSP file
#   fssp_rd_one                 reads for a given FSSP file one particular ali+header
#   gcgRd                       reads sequence in GCG format
#   get_chain                   extracts a chain identifier from file name
#   get_in_database_files       reads command line, checks validity of format, returns array
#   getFileFormat               returns format of file
#   getFileFormatQuick          quick scan for file format: assumptions
#   interpretSeqCol             extracts the column input format and writes it
#   interpretSeqFastalist       extracts the Fasta list input format
#   interpretSeqMsf             extracts the MSF input format
#   interpretSeqPirlist         extracts the PIR list input format
#   interpretSeqPP              suppose it is old PP format: write sequenc file
#   interpretSeqSaf             extracts the SAF input format
#   interpretSeqSafFillUp       fill up with dots if sequences shorter than guide
#   msfBlowUp                   duplicates guide sequence for conversion to HSSP
#   msfCheckFormat              basic checking of msf file format
#   msfCountNali                counts the number of alignments in MSF file
#   msfRd                       reads MSF files input format
#   msfWrt                      writing an MSF formatted file of aligned strings
#   msfCheckNames               reads MSF file and checks consistency of names
#   pirRdSeq                    reads the sequence from a PIR file
#   pirRdMul                    reads the sequence from a PIR file
#   pirWrtMul                   writes a list of sequences in PIR format
#   read_dssp_seqsecacc         reads seq, secondary str and acc from DSSP file
#   read_fssp                   reads the aligned fragment ranges from fssp files
#   safRd                       reads SAF format
#   safWrt                      writing an SAF formatted file of aligned strings
#   seqGenWrt                   writes protein sequence in various output formats
#   swissGetFile                
#   swissGetKingdom             gets all species for given kingdom
#   swissGetLocation            searches in SWISS-PROT file for cell location           
#   swissGetRegexp              1
#   swissRdSeq                  reads the sequence from a SWISS-PROT file
#   write_pir                   writes protein into PIR format
#   wrt_msf                     writing an MSF formatted file of aligned strings
#   wrtMsf                      writing an MSF formatted file of aligned strings
# 
# -----------------------------------------------------------------------------# 
#                               ---------------------
#   formats                     external subroutines:
#                               ---------------------
# 
#   call from br:               wrt_dssp_phd,wrt_phd_rdb2col,wrt_ppcol
# 
#   call from comp:             get_min
# 
#   call from file:             isDaf,isDafGeneral,isDafList,isDsspGeneral,isFasta
#                               isFastaMul,isFsspGeneral,isGcg,isHsspGeneral,isMsf
#                               isMsfGeneral,isMsfList,isPhdAcc,isPhdHtm,isPhdSec,isPir
#                               isPirMul,isRdb,isRdbGeneral,isRdbList,isSaf,isSwiss
#                               isSwissGeneral,isSwissList,is_dssp,is_dssp_list,is_fssp
#                               is_fssp_list,is_hssp,is_hssp_empty,is_hssp_list,is_ppcol
#                               is_rdb_htmref,is_rdb_htmtop,is_rdb_nnDb,is_strip,open_file
#                               rd_col_associative
# 
#   call from formats:          convGcg2fasta,convHssp2msf,convPir2fasta,convSwiss2fasta
#                               dafWrtAliHeader,dsspGetFile,dsspGetFileLoop,dsspRdSeq
#                               fastaWrt,fastaWrtMul,fsspGetFile,fsspGetFileLoop,fssp_rd_ali
#                               gcgRd,interpretSeqSafFillUp,msfCheckFormat,msfRd,msfWrt
#                               pirRdMul,pirWrtMul,safRd,safWrt,swissGetFile,swissRdSeq
# 
#   call from hssp:             hsspGetChain,hsspGetFile,hsspGetFileLoop,hsspRdAli
#                               hsspRdHeader,hsspRdSeqSecAccOneLine
# 
#   call from prot:             aa3lett_to_1lett,getDistanceNewCurveIde,is_pdbid,secstr_convert_dsspto3
# 
#   call from scr:              errSbr,errSbrMsg,get_range,get_rangeHyphen,myprt_array
# 
#   call from sys:              complete_dir,run_program,sysRunProg
# 
#   call from system:            
#                               $exeConv $fileFssp $dirDsspLoc >> $fileDafTmp $exeConv $fileFssp $dirDsspLoc >> $fileDafTmp 
# 
#   call from missing:           
#                               conv_fssp2daf_lh
# 
# 
# -----------------------------------------------------------------------------# 
# 

#===============================================================================
sub checkMsfFormat {
    local ($fileMsf) = @_;
    local ($format,$tmp,$kw_msf,$kw_check,$ali_sec,$ali_des_sec,$valid_id_len,$fhLoc,
	   $uniq_id, $same_nb, $same_len, $nb_al, $seq_tmp, $seql, $ali_des_len);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   checkMsfFormat              basic checking of msf file format
#           - mandatory keywords and values (MSF: val, Check: val)
#           - alignment description start after "..", each line with the following structure:
#             Name: id Len: val Check: val Weight: val (and all ids diferents)
#           - alignment same number of line for each id (>0)
#       in:                     $fileMsf
#       out:                    return 1  if format seems OK, 0 else
#--------------------------------------------------------------------------------
    $sbrNameLoc="lib-br:checkMsfFormat";
                                # ----------------------------------------
                                # initialise the flags
                                # ----------------------------------------
    $fhLoc="FHIN_CHECK_MSF_FORMAT";
    $kw_msf=$kw_check=$ali_sec=$ali_des_sec=$ali_des_seq=$nb_al=0;
    $format=1;
    $valid_id_len=1;		# sequence name < 15 characters
    $uniq_id=1;			# id must be unique
    $same_nb=1;			# each seq must appear the same numb of time
    $same_len=1;		# each seq must have the same len
                                # ----------------------------------------
                                # read the file
                                # ----------------------------------------
    open ($fhLoc,$fileMsf)  || 
	return(0,"*** $sbrNameLoc cannot open fileMsf=$fileMsf\n");
    while (<$fhLoc>) {
	$_=~s/\n//g;
	$tmp=$_;$tmp=~ tr/a-z/A-Z/;
                                # MSF keyword and value
	$kw_msf=1    if (!$ali_des_seq && ($tmp =~ /MSF:\s*\d*\s/));
	next if (!$kw_msf);
                         	# CHECK keyword and value
	$kw_check=1  if (!$ali_des_seq && ($tmp =~ /CHECK:\s*\d*/));
	next if (!$kw_check);
                         	# begin of the alignment description section 
                         	# the line with MSF and CHECK must end with ".."
	if (!$ali_sec && $tmp =~ /MSF:\D*(\d*).*CHECK:.*\.\.\s*$/) {
	    $ali_des_len=$1;$ali_des_sec=1;}
                                # ------------------------------
                         	# the alignment description section
	if (!$ali_sec && $ali_des_sec) { 
            if ($tmp=~ /^\s*NAME:\s*(\S*).*LEN:.*\d.*CHECK:.*\d.*WEIGHT:.*\d.*/) {
		$id=$1;
		if (length($id) > 14) {	# is sequence name <= 14
		    $valid_id_len=0;}
		if ($SEQID{$id}) { # is the sequence unique?
		    $uniq_id=0;
		    last; }
		$SEQID{$id}= 1; # store seq ID
		$SEQL{$id}= 0;	# initialise seq len array
	    } }
                                # ------------------------------
                        	# begin of the alignment section
	$ali_sec=1    if ($ali_des_sec && $tmp =~ /\/\/\s*$/);
                                # ------------------------------
                        	# the alignment section
	if ($ali_sec) {
	    if ($tmp =~ /^\s*(\S+)\s+(.*)$/) {
		$id= $1;
		if ($SEQID{$id}) {++$SEQID{$id};
				  $seq_tmp= $2;$seq_tmp=~ s/\s|\n//g;
				  $seql= length($seq_tmp);
				  $SEQL{$id} += $seql; }}}
    }close($fhLoc);
                                # ----------------------------------------
                                # test if all sequences are present the 
				# same number of time with the same length
                                # ----------------------------------------
    foreach $id (keys %SEQID) {
	if (!$nb_al) {
	    $nb_al= $SEQID{$id};}
	if ($SEQID{$id} < 2 || $SEQID{$id} != $nb_al) {
	    $same_nb=0;
	    last; }}
				# TEST ALL THE FLAGS
    $msg="";
    $msg.="*** $sbrNameLoc ERROR: wrong MSF no keyword MSF\n"        if (!$kw_msf);
    $msg.="*** $sbrNameLoc ERROR: wrong MSF no keyword Check\n"      if (!$kw_check);
    $msg.="*** $sbrNameLoc ERROR: wrong MSF no ali descr section\n"  if (!$ali_des_sec);
    $msg.="*** $sbrNameLoc ERROR: wrong MSF no ali section\n"        if (!$ali_sec); 
    $msg.="*** $sbrNameLoc ERROR: wrong MSF id not unique\n"         if (!$uniq_id); 
    $msg.="*** $sbrNameLoc ERROR: wrong MSF seq name too long\n"     if (!$valid_id_len);
    $msg.="*** $sbrNameLoc ERROR: wrong MSF varying Nsequences\n"    if (!$same_nb);
    $msg.="*** $sbrNameLoc ERROR: wrong MSF varying length of seq\n" if (!$same_len);
    if (length($msg)>1){
	return(0,$msg);}
    return(1,"$sbrNameLoc ok");
}				# end checkMsfFormat

#===============================================================================
sub convDssp2fasta {
    local($fileInLoc,$fileOutLoc,$fragLoc,$chainLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   convDssp2fasta              converts DSSP to FASTA format
#       in:                     $fileInLoc,$fileOutLoc,$fragLoc,$chainLoc
#       in:                     $fragLoc=n-m    fragment to extract (optional)
#                               = 0 for no action
#       in:                     $chainLoc=[A-Z0-9] chain to extract
#                               = "*" for all
#       out:                    implicit: file out
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."convDssp2fasta";$fhinLoc="FHIN_"."convDssp2fasta";
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc!")          if (! defined $fileInLoc);
    return(0,"*** $sbrName: not def fileOutLoc!")         if (! defined $fileOutLoc);
    $fragLoc=0                                            if (! defined $fragLoc);
    $chainLoc="*"                                         if (! defined $chainLoc);

    return(0,"*** $sbrName: miss in file '$fileInLoc'!")  if (! -e $fileInLoc);

                                # ------------------------------
    ($Lok,$id,$seq)=            # read DSSP
        &dsspRdSeq($fileInLoc,$chainLoc);
    return(0,"*** ERROR $sbrName: failed to read DSSP ($fileInLoc)\n".
             "***                 found id=$id\n") 
        if (! $Lok || length($seq)<1);

    undef %tmp;
    $tmp{"id","1"}= $id;
    $tmp{"seq","1"}=$seq;
    $tmp{"NROWS"}=1;
                                # ------------------------------
                                # extract?
    if ($fragLoc){($beg,$end)=split(/-/,$frag);
                  foreach $it (1..$tmp{"NROWS"}){
                      $tmp{"seq","$it"}=substr($tmp{"seq","$it"},$beg,($end-$beg+1));}}
                                # ------------------------------
                                # write output
    ($Lok,$msg)=
        &fastaWrtMul($fileOutLoc,%tmp);
    return(0,"*** ERROR $sbrName: failed to write FASTAmul ($fileOutLoc)\n".
           "***                 msg=$msg\n") if (! $Lok);
    return(2,"-*- WARN $sbrName: wrong number written\n$msg\n") if ($Lok != 1);
    return(1,"ok $sbrName");
}				# end of convDssp2fasta

#===============================================================================
sub convFasta2gcg {
    local($exeConvSeqLoc,$file_in_loc,$file_out_loc,$fhTraceLoc)=@_;
    local($outformat,$an,$commandLoc);
#----------------------------------------------------------------------
#   convFasta2gcg               convert fasta format to GCG format
#       in:                     $exeConvSeqLoc,$file_in_loc,$file_out_loc,$fhTraceLoc
#       out:                    
#       err:                    ok=(1,'ok'), err=(0,'msg')
#----------------------------------------------------------------------
    $sbrName="convFasta2gcg";
    return(0,"*** $sbrName: not def file_in_loc!")    if (! defined $file_in_loc);
    return(0,"*** $sbrName: not def file_out_loc!")   if (! defined $file_out_loc);
    return(0,"*** $sbrName: not def exeConvSeqLoc!")  if (! defined $exeConvSeqLoc);
    $fhTraceLoc="STDOUT"                                       if (! defined $fhTraceLoc);
				# check existence of files
    return(0,"*** $sbrName: no file '$file_in_loc'!")   if (! -e $file_in_loc);
    return(0,"*** $sbrName: no exe  '$exeConvSeqLoc'!") if (! -e $exeConvSeqLoc);
				# ------------------------------
				# call FORTRAN program
    $outformat=                 "G";
    $an=                        "N";
    eval "\$commandLoc=\"$exeConvSeqLoc,$file_in_loc,$outformat,$an,$file_out_loc,$an,\"";
    $Lok=
	&run_program("$commandLoc" ,"$fhTraceLoc","warn"); 
    if (! $Lok){
	return(0,"*** $sbrName: couldnt run_program cmd=$commandLoc\n");}
    return(1,"ok $sbrName");
}				# end of convFasta2gcg

#===============================================================================
sub convFastamul2many {
    local($fileInLoc,$fileOutLoc,$formOutLoc,$fragLoc,$extrLoc,$fhErrSbr) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   convFastamul2msf            converts FASTAmul into many formats: FASTA,MSF,PIR,SAF,PIRmul
#       in:                     $fileInLoc,$fileOutLoc,$formOutLoc,$fragLoc,$extrLoc,$fhErrSbr
#       in:                     $formOutLoc     format MSF|FASTA|PIR
#       in:                     $fragLoc=n-m    fragment to extract (optional)
#       in:                     $extrLoc=i,j,k  take only sequences i,j,k from PIRmul
#       in:                     NOTE: to leave blank =0, e.g. 
#       in:                           'file.fastamul,file.f,0,5' would get fifth sequence
#       out:                    implicit: file written
#       err:                    (1,'ok'), (0,'message')
#       err:                    e: (1,msg) -> ok
#       err:                    a: (0,msg) -> some arguments missing/files not opened
#       err:                    b: (2,msg) -> no output file written 
#       err:                    b: (3,msg) -> ERROR from msfCheckFormat
#   specification of format     see interpretSeqFastamul
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."convFastamul2msf";$fhinLoc="FHIN_"."convFastamul2msf";
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc!")          if (! defined $fileInLoc);
    return(0,"*** $sbrName: not def fileOutLoc!")         if (! defined $fileOutLoc);
    return(0,"*** $sbrName: not def formOutLoc!")         if (! defined $formOutLoc);
    $fragLoc=0                                            if (! defined $fragLoc);
    $extrLoc=0                                            if (! defined $extrLoc);
    return(0,"*** $sbrName: miss in file '$fileInLoc'!")  if (! -e $fileInLoc);
                                # interpret input
    $formOutLoc=~tr/[A-Z]/[a-z]/;
    if ($fragLoc){$fragLoc=~s/\s//g;
		  return(0,"*** $sbrName: syntax of fragLoc ($fragLoc) must be :\n".
			 "    'ifir-ilas', where ifir,ilas are integers (or 1-*)\n")
		      if ($fragLoc && $fragLoc !~/[\d\*]\-[\d\*]/);}
    if ($extrLoc){$extrLoc=~s/\s//g;
		  return(0,"*** $sbrName: syntax of extrLoc ($extrLoc) must be :\n".
			 "    'n1,n2,n3-n4', where n* are integers\n")
		      if ($extrLoc && $extrLoc =~/[^0-9\-,]/);
		  @extr=&get_range($extrLoc); 
                  undef %take;
                  foreach $it(@extr){
                      $take{$it}=1;}}
				# open file
    &open_file("$fhinLoc","$fileInLoc") ||
	return(0,"*** ERROR $sbrName: fileIn=$fileInLoc, not opened\n");

                                # ------------------------------
    undef %fasta; $ct=$#id=0;   # read file
    while (<$fhinLoc>) {
	$_=~s/\n//g;
        if ($_=~/^\s*\>(.*)$/){ # is id
            $name=$1;$name=~s/[\s\t]+/ /g; # purge too many blanks
            $name=~s/^\s*|\s*$//g; # purge leading blanks
            $id=$name;$id=~s/^(\S+).*$/$1/; # shorter identifier
            ++$ct;
            $id="$ct" if (length($id)<1);
            push(@id,$id);
            $fasta{"id","$ct"}=$name;$fasta{"seq","$ct"}="";}
        else {                  # is sequence
            $_=~s/\s|\t//g;
            $fasta{"seq","$ct"}.=$_;}}
				# ------------------------------
    undef %tmp; $ctTake=0;	# store names for passing variables
    foreach $it (1..$#id){ 
        next if ($extrLoc && (! defined $take{$it} || ! $take{$it}));
        ++$ctTake; 
        $tmp{"id","$ctTake"}= $fasta{"id","$ct"};
        $tmp{"seq","$ctTake"}=$fasta{"seq","$ct"};}
    $tmp{"NROWS"}=$ctTake;
    %fasta=%tmp; undef %tmp;
				# ------------------------------
				# select subsets
				# ------------------------------
    if ($fragLoc){
	($beg,$end)=split('-',$fragLoc);$len=length($fasta{"seq","1"});
	$beg=1 if ($beg eq "*"); $end=$len if ($end eq "*");
	if ($len< ($end-$beg+1)){
	    print "-*- WARN $sbrName: $beg-$end not possible, as length of protein=$len\n";}
	else {
	    foreach $it (1..$fasta{"NROWS"}){
		$fasta{"seq","$it"}=substr($fasta{"seq","$it"},$beg,($end-$beg+1));}}}
				# --------------------------------------------------
				# write output
				# --------------------------------------------------
                                # ------------------------------
				# write an MSF formatted file
    if    ($formOutLoc eq "msf"){
        undef %tmp; undef %tmp2; 
        foreach $it (1..$fasta{"NROWS"}){
	    $name=        $fasta{"id","$ct"};$name=~s/^\s*|\s*$//g;$name=~s/^(\S+).*$/$1/g;
	    $name=substr($name,1,14) if (length($name)>14); # yy hack for convert_seq
	    if (defined $tmp2{$name}){ # avoid duplication
		$ct=0;while (defined $tmp2{$name}){
		    ++$ct;$name=substr($name,1,12).$ct;}}$tmp2{$name}=1;
	    $tmp{"$it"}=  $name;$tmp{"$name"}=$fasta{"seq","$ct"};}
	$tmp{"NROWS"}=$fasta{"NROWS"};
        $tmp{"FROM"}=$fileInLoc; 
        $tmp{"TO"}=  $fileOutLoc;
        $fhout="FHOUT_MSF_FROM_SAF";
        open("$fhout",">$fileOutLoc")  || # open file
            return(0,"*** $sbrName cannot open fileOutLoc=$fileOutLoc\n");
        $Lok=&msfWrt("$fhout",%tmp); # write the file
        close("$fhout");
        return(0,"*** ERROR $sbrName: failed in MSF format ($fileOutLoc)\n") if (! $Lok);}

                                # ------------------------------
				# write a SAF,PIR,FASTA, formatted file
    elsif ($formOutLoc eq "saf"   || $formOutLoc eq "fastamul" || $formOutLoc eq "pirmul" || 
	   $formOutLoc eq "fasta" || $formOutLoc eq "pir"){
        if    ($formOutLoc =~ /^fasta/){
            ($Lok,$msg)=&fastaWrtMul($fileOutLoc,%fasta);}
        elsif ($formOutLoc =~ /^pir/){
            ($Lok,$msg)=&pirWrtMul($fileOutLoc,%fasta);}
        elsif ($formOutLoc eq "saf"){
            ($Lok,$msg)=&safWrt($fileOutLoc,%fasta);}
        return(0,"*** ERROR $sbrName: failed in SAF format ($fileOutLoc)\n".$msg."\n") if (! $Lok);}
				# ------------------------------
				# file existing??
    return(2,"*** $sbrName ERROR after write, missing fileOutLoc=$fileOutLoc\n") 
	if (! -e $fileOutLoc);
				# ------------------------------
				# make a basic test of msf format
    if    ($formOutLoc eq "msf"){
        ($Lok,$msg)=
            &msfCheckFormat($fileOutLoc);
        return(3,"$msg"."*** $sbrName ERROR from msfCheckFormat fileOutLoc=$fileOutLoc\n") if (! $Lok);}
				# ------------------------------
    $#fasta=$#nameLoc=0;        # save space
    undef %fasta; undef %nameInBlock; undef %tmp;
    return(1,"$sbrName ok");
}				# end of convFastamul2many

#===============================================================================
sub convFssp2Daf {
    local ($fileFssp,$fileDaf,$fileDafTmp,$exeConv,$dirDsspLoc) = @_ ;
    local ($fhinLoc,$fhoutLoc,$tmp,@tmp);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   convFssp2Daf		converts an HSSP file into the DAF format
#         in:   		fileHssp, fileDaf, execonvFssp2Daf
#         out:   		1 if converted file in DAF and existing, 0 else
#--------------------------------------------------------------------------------
    $sbrName="lib-br:convFssp2Daf";
    return(0,"*** ERROR $sbrName: fileFssp=$fileFssp missing\n") 
        if (! defined $fileFssp || ! -e $fileFssp);
    $dirDsspLoc=""              if (! defined $dirDsspLoc || ! -d $dirDsspLoc);
				# ------------------------------
				# run via system call:
				# ------------------------------
    if ($exeConv=~/\.pl/){
	system("$exeConv $fileFssp $dirDsspLoc >> $fileDafTmp"); }
				# ------------------------------
				# include as package
				# ------------------------------
    else {
	&conv_fssp2daf_lh'conv_fssp2daf_lh($fileFssp,$dirDsspLoc,"fileOut=$fileDafTmp"); } # e.e' 

				# ------------------------------
				# as Liisa cannot do it: clean up!
    $fhinLoc= "FhInconvFssp2Daf"; $fhoutLoc="FhOutconvFssp2Daf";
    &open_file("$fhinLoc","$fileDafTmp") || 
	return(0,"*** ERROR $sbrName failed to open temp=$fileDafTmp (piped from $exeConv)\n");
    &open_file("$fhoutLoc",">$fileDaf")  ||
	return(0,"*** ERROR $sbrName failed to open new=$fileDaf\n");
				# ------------------------------
    while(<$fhinLoc>){		# header
	$tmp=$_;
	last if (/^\# idSeq/);print $fhoutLoc $tmp; }
    $tmp=~s/^\# //g;		# correct error 1 (names)
    $tmp=~s/\n//g;$tmp=~s/^[\t\s]*|[\t\s]*$//g;
    @tmp=split(/[\t\s]+/,$tmp); 
    foreach $tmp(@tmp){
	print $fhoutLoc "$tmp\t";}print $fhoutLoc "\n";
	
				# ------------------------------
    while(<$fhinLoc>){		# body
	$_=~s/\n//g;$_=~s/^[\s\t]*|[\s\t]*$//g;	# purge trailing blanks
	@tmp=split(/[\t\s]+/,$_);
	$seq=$tmp[$#tmp-1];$str=$tmp[$#tmp];
				# consistency
	return(0,"*** ERROR in $sbrName: lenSeq ne lenStr!\n".
	       "***       seq=$seq,\n","***       str=$str,\n","***       line=$_,\n")
	    if (length($seq) != length($str));

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
	foreach $tmp(@tmp){print $fhoutLoc "$tmp\t";}print $fhoutLoc "\n";
    } close($fhinLoc);close($fhoutLoc);

    return(1,"ok $sbrName") if ( (-e $fileDaf) && (&isDaf($fileDaf)));
    return(0,"*** ERROR $sbrName output $fileDaf missing or not DAF format\n");
}				# end of convFssp2Daf

#===============================================================================
sub convGcg2fasta {
    local($fileInLoc,$fileOutLoc,$fragLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   convGcg2fasta               converts GCG to FASTA format
#       in:                     $fileInLoc,$fileOutLoc,$fragLoc
#       in:                     $fragLoc=n-m    fragment to extract (optional)
#       out:                    implicit: file out
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."convGcg2fasta";$fhinLoc="FHIN_"."convGcg2fasta";
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc!")          if (! defined $fileInLoc);
    return(0,"*** $sbrName: not def fileOutLoc!")         if (! defined $fileOutLoc);
    $fragLoc=0                                            if (! defined $fragLoc);

    return(0,"*** $sbrName: miss in file '$fileInLoc'!")  if (! -e $fileInLoc);

                                # ------------------------------
    ($Lok,$id,$seq)=            # read GCG
        &gcgRd($fileInLoc);
    return(0,"*** ERROR $sbrName: failed to read SWISS ($fileInLoc)\n".
             "***                 found id=$id\n") 
        if (! $Lok || length($seq)<1);

    undef %tmp;
    $tmp{"id","1"}= $id;
    $tmp{"seq","1"}=$seq;
    $tmp{"NROWS"}=1;
                                # ------------------------------
                                # extract?
    if ($fragLoc){($beg,$end)=split(/-/,$frag);
                  foreach $it (1..$tmp{"NROWS"}){
                      $tmp{"seq","$it"}=substr($tmp{"seq","$it"},$beg,($end-$beg+1));}}
                                # ------------------------------
                                # write output
    ($Lok,$msg)=
        &fastaWrtMul($fileOutLoc,%tmp);
    return(0,"*** ERROR $sbrName: failed to write FASTAmul ($fileOutLoc)\n".
           "***                 msg=$msg\n") if (! $Lok);
    return(2,"-*- WARN $sbrName: wrong number written\n$msg\n") if ($Lok != 1);
    return(1,"ok $sbrName");
}				# end of convGcg2fasta

#===============================================================================
sub convHssp2Daf {
    local ($fileHssp,$fileDaf,$exeConv) = @_ ;local ($command,$an,$formOut);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   convHssp2Daf		converts an HSSP file into the DAF format
#       in:      		fileHssp, fileDaf, exeConvHssp2Daf
#       out:    		1 if converted file in DAF and existing, 0 else
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

#===============================================================================
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

#===============================================================================
sub convHssp2seq {
    local($fileInLoc,$chainInLoc,$fileOutLoc,$formOutLoc,$extOutLoc,
          $doExpand,$fragLoc,$extrLoc,$lenMin,$laliMin,$distMin,$pideMax,$fhErrSbr) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   convHssp2seq                converts HSSP file to PIR(mul), FASTA(mul)
#       in:                     $fileInLoc   file.hssp, file.out, format_of_output_file
#       in:                     $fileOutLoc  output file with converted sequence(s)
#       in:                     $formOut     output format (lower caps)
#                                 = 'fasta|pir' (or pirmul/fastamul)
#       in:                     $extOutLoc   extension of expected output 
#                                            (fragments into _beg_end$extension)
#       in:                     $doExpand    do expand the deletions? (only for MSF)
#       in:                     $frag        fragment e.g. '1-5','10-100'
#                                 = 0        for any
#                                            NOTE: only ONE fragment allowed, here
#       in:                     $extrIn      number of protein(s) to extract
#                                 = 'p1-p2,p3' -> extract proteins p1-p2,p3
#                                 = 0        for all
#                      NOTE:      = guide    to write only the guide sequence!!
#       in:                     $lenMin      minimal length of sequence to write 
#                                 = 0        for any
#       in:                     $laliMin     minimal alignment length (0 for wild card)
#                                 = 0        for any
#       in:                     $distMin     minimal distance from HSSP threshold
#                                 = 0        for any
#       in:                     $pideMAx !!  maximal sequence identity
#                                 = 0        for any
#       in:                     $fhSbr       ERRORs of convert_seq
#       out:                    1|0,msg,implicit: converted file
#       err:                    0,$msg -> unspecified error 
#       err:                    1,$msg -> ok
#       err:                    2,$msg -> conversion option not supported
#-------------------------------------------------------------------------------
    $sbrName="lib-br::"."convHssp2seq"; $fhinLoc="FHIN_"."convHssp2seq";
                                # ------------------------------
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc!")           if (! defined $fileInLoc);
    $chainInLoc="*"                                        if (! defined $chainInLoc);
    return(0,"*** $sbrName: not def fileOutLoc!")          if (! defined $fileOutLoc);
    return(0,"*** $sbrName: not def formOutLoc!")          if (! defined $formOutLoc);
    return(0,"*** $sbrName: not def extOutLoc!")           if (! defined $extOutLoc);
    return(0,"*** $sbrName: not def doExpand!")            if (! defined $doExpand);
    return(0,"*** $sbrName: not def fragLoc!")             if (! defined $fragLoc);
    return(0,"*** $sbrName: not def extrLoc!")             if (! defined $extrLoc);
    $lenMin=0                                              if (! defined $lenMin);
    $laliMin=0                                             if (! defined $laliMin);
    $distMin=0                                             if (! defined $distMin);
    $pideMax=0                                             if (! defined $pideMax);
    $fhErrSbr="STDOUT"                                     if (! defined $fhErrSbr);
				# existence of file
    return(0,"*** $sbrName: miss in file '$fileInLoc'!")   if (! -e $fileInLoc);

                                # ------------------------------
                                # supported output options
    return(&errSbr("output format $formOutLoc not supported by this sbr"))
	if ($formOutLoc !~ /^(pir|fasta)/);

				# ------------------------------
    if ($fragLoc) {		# fragment of proteins
	return(&errSbr("frag MUST be 'N1-N2', only ONE!")) if ($fragLoc !~/\d+\-\d+/);
	($ifirFrag,$ilasFrag)=split(/\-/,$fragLoc); }
    else {
	$ifirFrag=$ilasFrag=0; }

    $LextrGuideOnly=0;		# ------------------------------
    undef %extr;		# extraction of proteins
    if ($extrLoc eq "guide"){	# only guide
	$LextrGuideOnly=1;}
    elsif ($extrLoc) {		# get numbers to extract
	return(&errSbr("extr MUST be of the form:\n".
		       "'extr=n1-n2', or 'extr=n1,n2,n3-n4,n5'"))
	    if ($extr !~ /\d/);
	@extr=&get_range($extr);
	return(&errSbr("you gave the argument 'extr=$extr', not valid!\n".
		       "***   Ought to be of the form:\n".
		       "'extr=n1-n2', or 'extr=n1,n2,n3-n4,n5'\n")) if ($#extr==0);
	foreach $tmp (@extr) {
	    if ($tmp=~/\D/){ 
		return(&errSbr("you gave the argument 'extr=$extr', not valid!\n".
			       "***   Ought to be of the form:\n".
			       "'extr=n1-n2', or 'extr=n1,n2,n3-n4,n5'\n")); }
	    $extr{"$tmp"}=1; }}
				# ------------------------------
				# determine id
    $pdbid= $fileInLoc;$pdbid=~s/^.*\/|\.hssp//g; 
    $pdbid.="_".$chainInLoc     if ($chainInLoc ne "*");
    undef %tmp;			# ------------------------------
    if ($chainInLoc ne "*"){	# get chain positions
        ($Lok,%tmp)= 
	    &hsspGetChain($fileInLoc);
                                return(&errSbr("failed on getchain($fileInLoc)")) if (! $Lok);
	foreach $it (1..$tmp{"NROWS"}){
	    next if ($chainInLoc ne $tmp{"$it","chain"});
	    $ifirChain=$tmp{"$it","ifir"}; $ilasChain=$tmp{"$it","ilas"}; }}
    else {
	$ifirChain=$ilasChain=0;}
				# ------------------------------
    undef %tmp;			# read header of HSSP
    ($Lok,%tmp)=
	&hsspRdHeader($fileInLoc,"SEQLENGTH","ID","IDE","LALI","IFIR","ILAS");
                                return(&errSbr("failed on $fileInLoc")) if (! $Lok);
                                # ------------------------------
                                # too short -> skip
    return(1,"too short=".$tmp{"SEQLENGTH"})  if ($tmp{"SEQLENGTH"} < $lenMin);

    $#numTake=0;		# ------------------------------
				# process data

    if ($LextrGuideOnly){	# guide, only -> skip the following
	push(@numTake,1);
	$tmp{"NROWS"}=0; }

    foreach $it (1..$tmp{"NROWS"}){ # loop over all alis
				# not to include 
	next if ($extrLoc && ! defined $extr{"$it"});
				# not chain -> skip
	next if ($ifir && $ilas && 
		 ( ($tmp{"IFIR","$it"} > $ilas) || ($tmp{"ILAS","$it"} < $ifir) ));
				# lali too short
	next if ($laliMin > $tmp{"LALI","$it"} );
				# pide too high
	next if ($pideMax && $pideMax < 100*$tmp{"IDE","$it"} );
				# distance from threshold too high
	if ($distMin){
                                # compile distance to HSSP threshold (new)
	    ($pideCurve,$msg)= 
		&getDistanceNewCurveIde($tmp{"LALI","$it"});
	    next if ($msg !~ /^ok/);
	    $dist=100*$tmp{"IDE","$it"} - $pideCurve;
	    next if ($dist < $distMin); }

        push(@numTake,$it);     # ok -> take
    }
                                # ------------------------------
    undef %tmp;			# read alignments
    $kwdSeq="seqNoins";                         # default: read ali without insertions
    $kwdSeq="seqAli"            if ($doExpand);	# wanted:  read ali with insertions
	
    ($Lok,%tmp)=
	&hsspRdAli($fileInLoc,@numTake,$kwdSeq);
                                return(&errSbrMsg("failed reading alis for $fileInLoc, num=".
						  join(',',@numTake),$msg)) if (! $Lok);
    $nali=$tmp{"NROWS"};
    undef %tmp2;
				# ------------------------------
    if (defined $fragLoc){	# adjust for extraction (arg: frag=N1-n2)
				# additional complication if expand: change numbers
	if ($kwdSeq eq "seqAli"){ 
	    $seq=$tmp{"$kwdSeq","0"};
	    @tmp=split(//,$seq); $ct=0;
	    foreach $it (1..$#tmp){
		next if ($tmp[$it] eq ".");             # skip insertions
		++$ct;                                  # count no-insertions
		next if ($ct > $ifirFrag);              # outside of range to read
		next if ($ct < $ilasFrag);              # outside of range to read
		$ifirFrag=$it if ($ct == $ifirFrag);    # change begin !!  WARN  !!
		$ilasFrag=$it if ($ct == $ilasFrag);}}} # change end   !!  WARN  !!

				# ----------------------------------------
				# cut out non-chain, and not to read parts
				# ----------------------------------------
    foreach $it (0..$nali){
				# guide, only -> skip the following
	last if ($LextrGuideOnly && $it>0);
				# chain restricts reading
	if ($ifirChain && $ilasChain){
	    $tmp{"$kwdSeq","$it"}=
		substr($tmp{"$kwdSeq","$it"},$ifirChain,($ilasChain-$ifirChain+1));}
				# wanted fragment restricts reading
	if ($ifirFrag && $ilasFrag){
	    $len=length($tmp{"$kwdSeq","$it"});
	    return(&errSbr(" : sequence outside (f=$fileInLoc, c=$chainInLoc)\n".
			   "itNali=$it, ifirFrag=$ifirFrag, len=$len, kwdSeq=$kwdSeq,\n".
			   "seq=".$tmp{"$kwdSeq","$it"}))
		if ( $len < $ifirFrag);
	    $lenWrt=($ilasFrag-$ifirFrag+1);
	    $lenWrt=$len-$ifirFrag+1  if ($lenWrt < $len);
	    $tmp{"$kwdSeq","$it"}=
		substr($tmp{"$kwdSeq","$it"},$ifirFrag,$len); }
	$ct=$it+1;
	$tmp2{"seq","$ct"}=$tmp{"$kwdSeq","$it"};
	undef  $tmp{"$kwdSeq","$it"}; # slim-is-in !
	$tmp2{"id","$ct"}= $tmp{"$it"};
	$tmp2{"id","$ct"}.="_".$chainInLoc if ($ct==1 && $chainInLoc ne "*");
    }
    $tmp2{"NROWS"}=$nali+1;
    $tmp2{"NROWS"}=1            if ($LextrGuideOnly);
    undef %tmp;			# slim-is-in!
				# ------------------------------
    undef %tmp;			# slim-is-in !
    undef @numTake;		# slim-is-in !

				# --------------------------------------------------
				# write output file
				# --------------------------------------------------
    if ($formOutLoc =~ /^pir/){ # PIR, PIRmul
        ($Lok,$msg)=
            &pirWrtMul($fileOutLoc,%tmp2); }
    else {                      # FASTA, FASTAmul
        ($Lok,$msg)=
            &fastaWrtMul($fileOutLoc,%tmp2); }
        
    return(&errSbrMsg("failed writing out=$fileOutLoc, for in=$fileInLoc",$msg)) if (! $Lok);
    print $fhErrSbr		# warning if returned Lok==2
	"-*- WARN $sbrName: outformat=$formOutLoc, not enough written:\n",$msg,"\n" 
	    if ($Lok==2);
    undef %tmp2;		# slim-is-in !
    return(1,"ok $sbrName");
}				# end of convHssp2seq

#===============================================================================
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
sub convMsf2saf {
    local($fileInLoc,$fileOutLoc) = @_ ;
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   convMsf2saf                 converts MSF into SAF format
#       in:                     fileMsf,fileSaf
#       out:                    0|1,$msg 
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:convMsf2saf";$fhinLoc="FHIN_"."convMsf2saf";$fhoutLoc="FHOUT_"."convMsf2saf";
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc!")          if (! defined $fileInLoc);
    return(0,"*** $sbrName: not def fileOutLoc!")         if (! defined $fileInLoc);
    return(0,"*** $sbrName: miss in file '$fileInLoc'!")  if (! -e $fileInLoc);

    &open_file("$fhinLoc","$fileInLoc") ||
	return(0,"*** ERROR $sbrName: fileIn=$fileInLoc, not opened\n");
    $#tmp=$ct=$Lname=$LMsf=$LSeq=0;
				# ------------------------------
    while (<$fhinLoc>) {	# read MSF file
	$_=~s/\n//g;
				# --------------------
				# find sequence
        if    (! $LSeq && $_=~/^\/\// && $Lname && $LMsf){
            $LSeq=1;}
				# --------------------
	elsif (! $LSeq){	# header
            $LMsf=1       if (! $LMsf  && $_=~/msf\s*of\s*\:/i);
            $Lname=1      if (! $Lname && $_=~/name\s*:/i);
	    push(@tmp,$_) if (! $Lname); } # store header
				# --------------------
        elsif ($LSeq){		# sequence
				# first open file
            if ($ct==0){&open_file("$fhoutLoc",">$fileOutLoc") || 
			    return(0,"*** ERROR $sbrName: failed opening new $fileOutLoc\n");
			print $fhoutLoc "# SAF (Simple Alignment Format)\n";
			foreach $tmp(@tmp){
			    print $fhoutLoc "# $tmp\n";}}
	    ++$ct;
	    print $fhoutLoc "$_\n";	# simply mirror file
	}} close($fhinLoc); close($fhoutLoc) if ($ct>0); 
    $#tmp=0;			# save memory
    return(0,"*** ERROR $sbrName: $fileInLoc no valid MSF file\n") if ($ct==0);
    return(1,"ok $sbrName");
}				# end of convMsf2saf

#===============================================================================
sub convPhd2col {
    local ($file_in,$file_out,$opt_phd_loc)=@_;
    local ($sbrName,@des,@des2,%rdcol,$Lis_rdbformat,$it,$ct,$des,$itdes);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    convPhd2col                writes the prediction in column format
#       in:                     $file_in,$file_out,$opt_phd_loc
#       out:                    result into file
#       err:                    err=(0,$err), ok=(1,ok) 
#--------------------------------------------------------------------------------
    $sbrName="lib-br:convPhd2col";
    if    ($opt_phd_loc =~/^3|^both/) {
	@des= ("AA","PSEC","RI_S","pH", "pE", "pL", "PACC","PREL","RI_A","Pbie");
	@des2=("AA","PHEL","RI_S","OtH","OtE","OtL","PACC","PREL","RI_A","Pbie"); }
    elsif ($opt_phd_loc eq "sec") {
	@des= ("AA","PSEC","RI_S","pH", "pE", "pL");
	@des2=("AA","PHEL","RI_S","OtH","OtE","OtL"); }
    elsif ($opt_phd_loc eq "acc") {
	@des= ("AA","PACC","PREL","RI_A","Pbie");
	@des2=("AA","PACC","PREL","RI_A","Pbie"); }
    elsif ($opt_phd_loc eq "htm") {
	@des= ("AA","PSEC","RI_H","pH", "pL");
	@des2=("AA","PFHL","RI_H","OtH","OtL"); }
#	@des2=("AA","PFHL","RI_S","OtH","OtL"); }
    elsif ($opt_phd_loc eq "htmtop") {
	@des= ("AA","PSEC","RI_H","pH", "pL");
	@des2=("AA","PFHL","RI_S","OtH","OtL"); }
#	@des2=("AA","PFHL","RI_H","OtH","OtL"); }
				# lib-br
    %rdcol=&rd_col_associative($file_in,@des2); 
				# format line included?
    $Lis_rdbformat=0;
    if ( defined $rdcol{"AA","1"} && $rdcol{"AA","1"} eq "1" ) {
	$Lis_rdbformat=1;; 
	foreach $it(2..$rdcol{"NROWS"}){
	    foreach $des(@des2){
		$ct=$it-1;
		$rdcol{"$des","$ct"}=$rdcol{"$des","$it"}; }}
	$rdcol{"NROWS"}=($rdcol{"NROWS"} - 1 ); }
				# rename
    foreach $it(1..$rdcol{"NROWS"}){
	foreach $itdes(1..$#des){
	    $rdcol{"$des[$itdes]","$it"}=$rdcol{"$des2[$itdes]","$it"}; }}
				# write PHD.rdb ->  PP output format
    &wrt_phd_rdb2col($file_out,%rdcol);
    undef %rdcol;		# slim-is-in !
    return(1,"ok $sbrName");
}				# end of convPhd2col

#===============================================================================
sub convPir2fasta {
    local($fileInLoc,$fileOutLoc,$fragLoc,$extrLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   convPir2fasta               converts PIR to FASTA format
#       in:                     $fileInLoc,$fileOutLoc,$fragLoc,$extrLoc
#       in:                     $fragLoc=n-m    fragment to extract (optional)
#       in:                     $extrLoc=i,j,k  take only sequences i,j,k from PIRmul
#                               NOTE: to leave blank =0, e.g. 
#                               'file.pir,file.f,0,5' would get fifth sequence
#       out:                    implicit: file out
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."convPir2fasta";$fhinLoc="FHIN_"."convPir2fasta";
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc!")          if (! defined $fileInLoc);
    return(0,"*** $sbrName: not def fileOutLoc!")         if (! defined $fileOutLoc);
    $fragLoc=0                                            if (! defined $fragLoc);
    $extrLoc=0                                            if (! defined $extrLoc);

    return(0,"*** $sbrName: miss in file '$fileInLoc'!")  if (! -e $fileInLoc);

                                # interpret input
    $num=$extrLoc;# $num=1 if (! $extrLoc);
                                # ------------------------------
    ($Lok,$id,$seq)=            # read PIR
        &pirRdMul($fileInLoc,$num);

    return(0,"*** ERROR $sbrName: failed to read PIRmul ($fileInLoc,$num)\n".
             "***                 found id=$id\n") 
        if (! $Lok || length($seq)<1);
                                # ------------------------------
                                # interpret info
    @id=split(/\n/,$id);@seq=split(/\n/,$seq);
    return(0,"*** ERROR $sbrName: seq=$seq, and id=$id, not matching (differing number)\n") 
        if ($#id != $#seq);
    $tmp{"NROWS"}=$#id;
    foreach $it (1..$#id){$tmp{"id","$it"}= $id[$it];
                          $tmp{"seq","$it"}=$seq[$it];}
                                # ------------------------------
                                # extract?
    if ($fragLoc){($beg,$end)=split(/-/,$frag);
                  foreach $it (1..$tmp{"NROWS"}){
                      $tmp{"seq","$it"}=substr($tmp{"seq","$it"},$beg,($end-$beg+1));}}
                                # ------------------------------
                                # write output
    ($Lok,$msg)=
        &fastaWrtMul($fileOutLoc,%tmp);
    return(0,"*** ERROR $sbrName: failed to write FASTAmul ($fileOutLoc)\n".
           "***                 msg=$msg\n") if (! $Lok);
    return(2,"-*- WARN $sbrName: wrong number written\n$msg\n") if ($Lok != 1);
    return(1,"ok $sbrName");
}				# end of convPir2fasta

#===============================================================================
sub convSaf2many {
    local($fileInLoc,$fileOutLoc,$formOutLoc,$fragLoc,$extrLoc,$fhErrSbr) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   convSaf2many                converts SAF into many formats: saf2msf, saf2fasta, saf2pir
#       in:                     $fileInLoc,$fileOutLoc,$formOutLoc,$fragLoc,$extrLoc,$fhErrSbr
#       in:                     $formOutLoc     format MSF|FASTA|PIR
#       in:                     $fragLoc=n-m    fragment to extract (optional)
#       in:                     $extrLoc=i,j,k  take only sequences i,j,k from PIRmul
#       in:                     NOTE: to leave blank =0, e.g. 
#       in:                           'file.saf,file.f,0,5' would get fifth sequence
#       out:                    implicit: file written
#       err:                    (1,'ok'), (0,'message')
#       err:                    e: (1,msg) -> ok
#       err:                    a: (0,msg) -> some arguments missing/files not opened
#       err:                    b: (2,msg) -> no output file written 
#       err:                    b: (3,msg) -> ERROR from msfCheckFormat
#   specification of format     see interpretSeqSaf
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."convSaf2many";$fhinLoc="FHIN_"."convSaf2many";
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc!")          if (! defined $fileInLoc);
    return(0,"*** $sbrName: not def fileOutLoc!")         if (! defined $fileOutLoc);
    return(0,"*** $sbrName: not def formOutLoc!")         if (! defined $formOutLoc);
    $fragLoc=0                                            if (! defined $fragLoc);
    $extrLoc=0                                            if (! defined $extrLoc);
    return(0,"*** $sbrName: miss in file '$fileInLoc'!")  if (! -e $fileInLoc);
                                # interpret input
    $formOutLoc=~tr/[A-Z]/[a-z]/;
    if ($fragLoc){$fragLoc=~s/\s//g;
		  return(0,"*** $sbrName: syntax of fragLoc ($fragLoc) must be :\n".
			 "    'ifir-ilas', where ifir,ilas are integers (or 1-*)\n")
		      if ($fragLoc && $fragLoc !~/[\d\*]\-[\d\*]/);}
    if ($extrLoc){$extrLoc=~s/\s//g;
		  return(0,"*** $sbrName: syntax of extrLoc ($extrLoc) must be :\n".
			 "    'n1,n2,n3-n4', where n* are integers\n")
		      if ($extrLoc && $extrLoc =~/[^0-9\-,]/);
		  @extr=&get_range($extrLoc); 
                  undef %take;
                  foreach $it(@extr){
                      $take{$it}=1;}}
                                # ------------------------------
                                # read file
    ($Lok,$msg,%safIn)=
        &safRd($fileInLoc);

    @nameLoc=split(/,/,$safIn{"names"});
				# ------------------------------
    undef %tmp; $ctTake=0;	# store names for passing variables
    foreach $it (1..$#nameLoc){ 
        next if ($extrLoc && (! defined $take{$it} || ! $take{$it}));
        ++$ctTake; 
	$tmp{"id","$ctTake"}= $nameLoc[$it];
        $tmp{"seq","$ctTake"}=$safIn{"seq","$it"};}
    $tmp{"NROWS"}=$ctTake;
    %safIn=%tmp; undef %tmp;
				# ------------------------------
				# select subsets
				# ------------------------------
    if ($fragLoc){
	($beg,$end)=split("-",$fragLoc);$name=$safIn{"1"};$len=length($safIn{"$name"});
	$beg=1 if ($beg eq "*"); $end=$len if ($end eq "*");
	if ($len < ($end-$beg+1)){
	    print "-*- WARN $sbrName: $beg-$end not possible, as length of protein=$len\n";}
	else {
	    foreach $it (1..$safIn{"NROWS"}){
		$name=$safIn{"id","$it"};
		$safIn{"seq","$it"}=substr($safIn{"seq","$it"},$beg,($end-$beg+1));}}}
				# --------------------------------------------------
				# write output
				# --------------------------------------------------
				# write an MSF formatted file
    if    ($formOutLoc eq "msf"){
				# reconvert to what MSF wants...
	foreach $it (1..$safIn{"NROWS"}){$name=$safIn{"id","$it"};
					 $tmp{"$it"}=$name;
					 $tmp{"$name"}=$safIn{"seq","$it"};}
	$tmp{"NROWS"}=$safIn{"NROWS"};
        $tmp{"FROM"}= $fileInLoc; 
        $tmp{"TO"}=   $fileOutLoc;
        $fhout="FHOUT_MSF_FROM_SAF";
        open("$fhout",">$fileOutLoc")  || # open file
            return(0,"*** $sbrName cannot open fileOutLoc=$fileOutLoc\n");
        $Lok=&msfWrt("$fhout",%tmp); # write the file
        close("$fhout"); undef %tmp;}
				# write a FASTA or PIR formatted file
    elsif ($formOutLoc eq "fasta"  || $formOutLoc eq "fastamul" || $formOutLoc eq "saf" || 
	   $formOutLoc eq "pirmul" || $formOutLoc eq "pir"){
        if    ($formOutLoc =~ /^fasta/){
            ($Lok,$msg)=&fastaWrtMul($fileOutLoc,%safIn);}
        elsif ($formOutLoc =~ /^pir/){
            ($Lok,$msg)=&pirWrtMul($fileOutLoc,%safIn);}
        elsif ($formOutLoc eq "saf"){
            ($Lok,$msg)=&safWrt($fileOutLoc,%safIn);}
        return(0,"*** ERROR $sbrName: failed in $formOutLoc ($fileOutLoc)\n".$msg."\n") if (! $Lok);}
    else {
        return(0,"*** $sbrName: output format $formOutLoc not supported\n");}
				# ------------------------------
				# file existing??
    return(2,"*** $sbrName ERROR after write, missing fileOutLoc=$fileOutLoc\n") 
	if (! -e $fileOutLoc);
				# ------------------------------
				# make a basic test of msf format
    if    ($formOutLoc eq "msf"){
        ($Lok,$msg)=
            &msfCheckFormat($fileOutLoc);
        return(3,"$msg"."*** $sbrName ERROR from msfCheckFormat fileOutLoc=$fileOutLoc\n") if (! $Lok);}
				# ------------------------------
    $#safIn=$#nameLoc=0;        # save space
    undef %safIn; undef %nameInBlock; undef %tmp;
    return(1,"$sbrName ok");
}				# end of convSaf2many

#===============================================================================
sub convSwiss2fasta {
    local($fileInLoc,$fileOutLoc,$fragLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   convSwiss2fasta             converts SWISS-PROT to FASTA format
#       in:                     $fileInLoc,$fileOutLoc,$fragLoc
#       in:                     $fragLoc=n-m    fragment to extract (optional)
#       out:                    implicit: file out
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."convSwiss2fasta";$fhinLoc="FHIN_"."convSwiss2fasta";
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc!")          if (! defined $fileInLoc);
    return(0,"*** $sbrName: not def fileOutLoc!")         if (! defined $fileOutLoc);
    $fragLoc=0                                            if (! defined $fragLoc);

    return(0,"*** $sbrName: miss in file '$fileInLoc'!")  if (! -e $fileInLoc);

                                # ------------------------------
    ($Lok,$id,$seq)=            # read SWISS
        &swissRdSeq($fileInLoc);
    return(0,"*** ERROR $sbrName: failed to read SWISS ($fileInLoc)\n".
             "***                 found id=$id\n") 
        if (! $Lok || length($seq)<1);

    undef %tmp;
    $tmp{"id","1"}= $id;
    $tmp{"seq","1"}=$seq;
    $tmp{"NROWS"}=1;
                                # ------------------------------
                                # extract?
    if ($fragLoc){($beg,$end)=split(/-/,$frag);
                  foreach $it (1..$tmp{"NROWS"}){
                      $tmp{"seq","$it"}=substr($tmp{"seq","$it"},$beg,($end-$beg+1));}}
                                # ------------------------------
                                # write output
    ($Lok,$msg)=
        &fastaWrtMul($fileOutLoc,%tmp);
    return(0,"*** ERROR $sbrName: failed to write FASTAmul ($fileOutLoc)\n".
           "***                 msg=$msg\n") if (! $Lok);
    return(2,"-*- WARN $sbrName: wrong number written\n$msg\n") if ($Lok != 1);
    return(1,"ok $sbrName");
}				# end of convSwiss2fasta

#===============================================================================
sub convSeq2fasta {
    local($exeConvSeqLoc,$file_in_loc,$file_out_loc,$fhTraceLoc,$frag)=@_;
    local($outformat,$an,$commandLoc);
#----------------------------------------------------------------------
#   convSeq2fasta               convert all formats to fasta
#       in:                     $exeConvSeqLoc,$file_in_loc,$file_out_loc,$fhTraceLoc
#       in:                     $frage = 1-5, fragment from 1 -5 
#       out:                    
#       err:                    ok=(1,'ok'), err=(0,'msg')
#----------------------------------------------------------------------
    $sbrName="lib-br:convSeq2Fasta";
    return(0,"*** $sbrName: not def file_in_loc!")      if (! defined $file_in_loc);
    return(0,"*** $sbrName: not def file_out_loc!")     if (! defined $file_out_loc);
    return(0,"*** $sbrName: not def exeConvSeqLoc!")    if (! defined $exeConvSeqLoc);
    $fhTraceLoc="STDOUT"                                   if (! defined $fhTraceLoc);
    $frag=0                                             if (! defined $frag);
				# check existence of files
    return(0,"*** $sbrName: no file '$file_in_loc'!")   if (! -e $file_in_loc);
    return(0,"*** $sbrName: no exe  '$exeConvSeqLoc'!") if (! -e $exeConvSeqLoc);

    $frag=0 if ($frag !~ /\-/);
                                # ------------------------------
    if ($frag){                 # extract fragments?
        $frag=~s/\s//g;
        ($beg,$end)=split('-',$frag);
        $frag=0 if ($beg =~/\D/ || $end =~ /\D/);}
				# ------------------------------
				# call FORTRAN program
    $cmd=              "";      # eschew warnings
    $outformat=        "F";     # output format FASTA
    $an2=              "N";     # write another format?
    if ($frag){
        $an1=          "Y";     # do fragment
        $anF=          "$beg $end"; # answer for fragment
        eval "\$cmd=\"$exeConvSeqLoc,$file_in_loc,$outformat,$an1,$anF,$file_out_loc,$an2,\"";
        &run_program("$cmd" ,"$fhTraceLoc","warn"); }
    else {
        $an1=          "N";     # no fragment
        eval "\$cmd=\"$exeConvSeqLoc,$file_in_loc,$outformat,$an1,$file_out_loc,$an2,\"";
        &run_program("$cmd" ,"$fhTraceLoc","warn"); }

    return(0,"*** ERROR $sbrName: no output from FORTRAN convert_seq, couldnt run_program cmd=$cmd\n")
        if (! -e $file_out_loc);
    return(1,"ok $sbrName");
}				# end of convSeq2fasta

#===============================================================================
sub convSeq2fastaPerl {
    local($fileInLoc,$fileOutLoc,$formInLoc,$fragLoc)=@_;
    local($outformat,$an,$commandLoc);
#----------------------------------------------------------------------
#   convSeq2fastaPerl           convert all formats to fasta (no fortran)
#       in:                     $fileInLoc,$fileOutLoc,$formInLoc,$fragLoc
#       in:                     $formInLoc: pir, pirmul, gcg, swiss, dssp
#       in:                     $fragLoce = 1-5, fragment from 1 -5 
#       out:                    
#       err:                    ok=(1,'ok'), err=(0,'msg')
#----------------------------------------------------------------------
    $sbrName="lib-br:convSeq2fastaPerl";
    return(0,"*** $sbrName: not def fileInLoc!")      if (! defined $fileInLoc);
    return(0,"*** $sbrName: not def fileOutLoc!")     if (! defined $fileOutLoc);
    return(0,"*** $sbrName: not def formInLoc!")      if (! defined $formInLoc);
    $fragLoc=0                                        if (! defined $fragLoc);
				# check existence of files
    return(0,"*** $sbrName: no file '$fileInLoc'!")   if (! -e $fileInLoc);

    $fragLoc=0                  if ($fragLoc !~ /\-/);

				# ------------------------------
				# do conversion
				# ------------------------------
    if    ($formInLoc=~ /^pir/){   # PIR
	($Lok,$msg)=
	    &convPir2fasta($fileInLoc,$fileOutLoc,$fragLoc,1);}
    elsif ($formInLoc=~ /^swiss/){ # SWISS-PROT
	($Lok,$msg)=
	    &convSwiss2fasta($fileInLoc,$fileOutLoc,$fragLoc);}
    elsif ($formInLoc eq "gcg"){   # GCG
	($Lok,$msg)=
	    &convGcg2fasta($fileInLoc,$fileOutLoc,$fragLoc);}
    else {
	return(&errSbr("format $formInLoc to FASTA not supported"));}
    return(&errSbrMsg("failed converting format=$formInLoc ($fileInLoc,$fileOutLoc,$fragLoc)",
		      $msg))    if (! $Lok);

    return(1,"ok $sbrName");
}				# end of convSeq2fastaPerl

#===============================================================================
sub convSeq2pir {
    local($exeConvSeqLoc,$file_in_loc,$file_out_loc,$fhTraceLoc,$frag,$fileScreenLoc)=@_;
    local($outformat,$an,$commandLoc);
#----------------------------------------------------------------------
#   convSeq2pir                 convert all sequence formats to PIR
#       in:                     $exeConvSeqLoc,$file_in_loc,$file_out_loc,$fhTraceLoc
#       in:                     $frage = 1-5, fragment from 1 -5 
#       err:                    ok=(1,'ok'), err=(0,'msg')
#----------------------------------------------------------------------
    $sbrName="lib-br:convSeq2Pir";
    return(0,"*** $sbrName: not def file_in_loc!")      if (! defined $file_in_loc);
    return(0,"*** $sbrName: not def file_out_loc!")     if (! defined $file_out_loc);
    return(0,"*** $sbrName: not def exeConvSeqLoc!")    if (! defined $exeConvSeqLoc);
    $fhTraceLoc="STDOUT"                                   if (! defined $fhTraceLoc);
    $frag=0                                             if (! defined $frag);
    $fileScreenLoc=0                                    if (! defined $fileScreenLoc);
				# check existence of files
    return(0,"*** $sbrName: no file '$file_in_loc'!")   if (! -e $file_in_loc);
    return(0,"*** $sbrName: no exe  '$exeConvSeqLoc'!") if (! -e $exeConvSeqLoc);

    $frag=0 if ($frag !~ /\-/);
                                # ------------------------------
    if ($frag){                 # extract fragments?
        $frag=~s/\s//g;
        ($beg,$end)=split('-',$frag);
        $frag=0 if ($beg =~/\D/ || $end =~ /\D/);}
				# ------------------------------
				# call FORTRAN program
    $cmd=              "";      # eschew warnings
    $outformat=        "P";     # output format PIR
    $an2=              "N";     # write another format?
    if ($frag){
        $an1=          "Y";     # do fragment
        $anF=          "$beg $end"; # answer for fragment
        eval "\$cmd=\"$exeConvSeqLoc,$file_in_loc,$outformat,$an1,$anF,$file_out_loc,$an2,\"";
        ($Lok,$msg)=
            &sysRunProg($cmd,$fileScreenLoc,$fhTraceLoc);}
    else {
        $an1=          "N";     # no fragment
        eval "\$cmd=\"$exeConvSeqLoc,$file_in_loc,$outformat,$an1,$file_out_loc,$an2,\"";
        ($Lok,$msg)=
            &sysRunProg($cmd,$fileScreenLoc,$fhTraceLoc);}

    return(0,"*** ERROR $sbrName: no output from FORTRAN convert_seq, couldnt run_program cmd=$cmd\n".
           $msg."\n") if (! $Lok || ! -e $file_out_loc);
    return(1,"ok $sbrName");
}				# end of convSeq2pir

#===============================================================================
sub convSeq2gcg {
    local($exeConvSeqLoc,$file_in_loc,$file_out_loc,$fhTraceLoc,$frag,$fileScreenLoc)=@_;
    local($outformat,$an,$commandLoc);
#----------------------------------------------------------------------
#   convSeq2gcg               convert all formats to gcg
#       in:                     $exeConvSeqLoc,$file_in_loc,$file_out_loc,$fhTraceLoc
#       in:                     $frage = 1-5, fragment from 1 -5 
#       out:                    
#       err:                    ok=(1,'ok'), err=(0,'msg')
#----------------------------------------------------------------------
    $sbrName="lib-br:convSeq2Gcg";
    return(0,"*** $sbrName: not def file_in_loc!")      if (! defined $file_in_loc);
    return(0,"*** $sbrName: not def file_out_loc!")     if (! defined $file_out_loc);
    return(0,"*** $sbrName: not def exeConvSeqLoc!")    if (! defined $exeConvSeqLoc);
    $fhTraceLoc="STDOUT"                                   if (! defined $fhTraceLoc);
    $frag=0                                             if (! defined $frag);
    $fileScreenLoc=0                                    if (! defined $fileScreenLoc);
				# check existence of files
    return(0,"*** $sbrName: no file '$file_in_loc'!")   if (! -e $file_in_loc);
    return(0,"*** $sbrName: no exe  '$exeConvSeqLoc'!") if (! -e $exeConvSeqLoc);

    $frag=0 if ($frag !~ /\-/);
                                # ------------------------------
    if ($frag){                 # extract fragments?
        $frag=~s/\s//g;
        ($beg,$end)=split('-',$frag);
        $frag=0 if ($beg =~/\D/ || $end =~ /\D/);}
				# ------------------------------
				# call FORTRAN program
    $cmd=              "";      # eschew warnings
    $outformat=        "G";     # output format GCG
    $an2=              "N";     # write another format?
    if ($frag){
        $an1=          "Y";     # do fragment
        $anF=          "$beg $end"; # answer for fragment
        eval "\$cmd=\"$exeConvSeqLoc,$file_in_loc,$outformat,$an1,$anF,$file_out_loc,$an2,\"";
        ($Lok,$msg)=
            &sysRunProg($cmd,$fileScreenLoc,$fhTraceLoc);}
    else {
        $an1=          "N";     # no fragment
        eval "\$cmd=\"$exeConvSeqLoc,$file_in_loc,$outformat,$an1,$file_out_loc,$an2,\"";
        ($Lok,$msg)=
            &sysRunProg($cmd,$fileScreenLoc,$fhTraceLoc);}

    return(&errSbrMsg("no output from FORTRAN convert_seq, couldnt run_program cmd=$cmd",
		      $msg)) if (! $Lok || ! -e $file_out_loc);
    return(1,"ok $sbrName");
}				# end of convSeq2gcg

#===============================================================================
sub convSeq2seq {
    local($exeConvSeqLoc,$fileInLoc,$fileOutLoc,$formOutLoc,$frag,$fileScreenLoc,$fhTraceLoc)=@_;
    local($outformat,$an,$commandLoc);
#----------------------------------------------------------------------
#   convSeq2seq                 convert all sequence-only formats to sequence only
#       in:                     $exeConvSeq,$fileIn,$fileOut,$formOutLoc,$frag,$fileScreen,$fhTraceLoc
#       in:                     $formOutLoc=  'FASTA|GCG|PIR'
#       in:                     $frage = 1-5, fragment from 1 -5 
#       out:                    file
#       err:                    ok=(1,'ok'), err=(0,'msg')
#----------------------------------------------------------------------
    $sbrName="lib-br:convSeq2Seq";
    $allow="fasta|pir|gcg";
    return(0,"*** $sbrName: not def exeConvSeqLoc!")    if (! defined $exeConvSeqLoc);
    return(0,"*** $sbrName: not def fileInLoc!")        if (! defined $fileInLoc);
    return(0,"*** $sbrName: not def fileOutLoc!")       if (! defined $fileOutLoc);
    return(0,"*** $sbrName: not def formOutLoc!")       if (! defined $formOutLoc);
    $fileScreenLoc=0                                    if (! defined $fileScreenLoc);
    $frag=0                                             if (! defined $frag);
    $fhTraceLoc="STDOUT"                                   if (! defined $fhTraceLoc);
				# check existence of files
    return(0,"*** $sbrName: no exe  '$exeConvSeqLoc'!") if (! -e $exeConvSeqLoc);
    return(0,"*** $sbrName: no file '$fileInLoc'!")     if (! -e $fileInLoc);
                                # check format
    $formOutLoc=~tr/[A-Z]/[a-z]/;
    return(0,"*** $sbrName: output format $formOutLoc not supported\n")
        if ($formOutLoc !~ /$allow/);
    $anFormOut=substr($formOutLoc,1,1);$anFormOut=~tr/[a-z]/[A-Z]/;
    $frag=0 if ($frag !~ /\-/);
                                # ------------------------------
    if ($frag){                 # extract fragments?
        $frag=~s/\s//g;
        ($beg,$end)=split('-',$frag);
        $frag=0 if ($beg =~/\D/ || $end =~ /\D/);}
				# ------------------------------
				# call FORTRAN program
    $cmd=              "";      # eschew warnings
    $an2=              "N";     # write another format?
    if ($frag){
        $an1=          "Y";     # do fragment
        $anF=          "$beg $end"; # answer for fragment
        eval "\$cmd=\"$exeConvSeqLoc,$fileInLoc,$anFormOut,$an1,$anF,$fileOutLoc,$an2,\"";
        ($Lok,$msg)=
            &sysRunProg($cmd,$fileScreenLoc,$fhTraceLoc);}
    else {
        $an1=          "N";     # no fragment
        eval "\$cmd=\"$exeConvSeqLoc,$fileInLoc,$anFormOut,$an1,$fileOutLoc,$an2,\"";
        ($Lok,$msg)=
            &sysRunProg($cmd,$fileScreenLoc,$fhTraceLoc);}

    return(&errSbrMsg("no output from FORTRAN convert_seq, could not run_program cmd=$cmd\n",
		      $msg)) if (! $Lok || ! -e $fileOutLoc);
    return(1,"ok $sbrName");
}				# end of convSeq2seq

#===============================================================================
sub copf2fasta {
    local($exeCopfLoc,$exeConvertSeqLoc,$extrLoc,$titleLoc,$extLoc,$dirWorkLoc,
	  $fileOutScreenLoc,$fhSbrErr,@fileInLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   copf2fasta                  runs copf.pl converting all input files to FASTA
#       in:                     $exeCopf       : perl script copf.pl          if = 0: default
#       in:                     $exeConvertSeq : FORTRAN exe convert_seq
#       in:                     $extrLoc       : number of file to extract from FASTAmul ..
#                                                                             if = 0: 1
#       in:                     $titleLoc      : title for temporary files    if = 0: 'TMP-$$'
#       in:                     $extLoc        : extension of output files    if = 0: '.fasta'
#       in:                     $dirWorkLoc    : working dir (for temp files) if = 0: ''
#       in:                     $fileOutScreen : screen dumpb of system call  if = 0: 0 -> STDOUT
#       in:                     $fhSbrErr      : error file handle
#       in:                     @fileInLoc     : array of input files
#       out:                    1|0,msg,@fileWritten
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."copf2fasta";$fhinLoc="FHIN_"."copf2fasta";
                                # ------------------------------
				# local defaults
    $exeCopfLocDef=             "/home/rost/perl/scr/copf.pl";

    if (defined $ARCH) {
	$ARCHTMP=$ARCH; }
    else {
	print "-*- WARN $sbrName: no ARCH defined set it!\n";
	$ARCHTMP=$ENV{'ARCH'} || "SGI32"; }

    $exeConvLocDef=             "/home/rost/pub/bin/convert_seq98.".$ARCHTMP;

                                # ------------------------------
				# check arguments
    $exeCopfLoc=$exeCopfLocDef  if (! defined $exeCopfLoc || ! $exeCopfLoc);
    $exeConvertSeqLoc=$exeConvLocDef 
	                        if (! defined $exeConvertSeqLoc || ! $exeConvertSeqLoc);
    $extrLoc=1                  if (! defined $extrLoc || ! $extrLoc);
    $titleLoc=  "TMP-".$$       if (! defined $titleLoc && ! $titleLoc);
    $extLoc=  ".fasta"          if (! defined $extLoc && ! $extLoc);
    $dirWorkLoc=  ""            if (! defined $dirWorkLoc && ! $dirWorkLoc);
    $dirWorkLoc.="/"            if ($dirWorkLoc !~/\/$/ && length($dirWorkLoc)>=1);
    $fhSbrErr="STDOUT"          if (! defined $fhSbrErr || ! $fhSbrErr);
    $fileOutScreenLoc=0         if (! defined $fileOutScreenLoc || ! $fileOutScreenLoc);

    $#fileTmp=0;
    $cmdSys="";
				# ------------------------------
				# loop over input files
				# ------------------------------
    foreach $fileLoc (@fileInLoc) {
	if (! -e $fileLoc){	# file missing
	    print $fhSbrErr 
		"-*- WARN $sbrName: missing file=$fileLoc\n";
	    next; }
	if (($extrLoc && ! &isFastaMul($fileLoc)) ||
	    &isFasta($fileLoc)){ # already FASTA format
	    push(@fileTmp,$fileLoc);
	    next; }
	$idIn=$fileLoc;$idIn=~s/^.*\/|\..*$//g;
				# ------------------------------
				# ... else RUN copf
	$fileOutTmp=$dirWorkLoc.$titleLoc.$idIn.$extLoc;

	$cmd= $exeCopfLoc." $fileLoc fasta extr=$extrLoc"."exeConvertSeq=".$exeConvertSeqLoc;
	$cmd.=" fileOut=$fileOutTmp";
	eval "\$cmdSys=\"$cmd\"";
	($Lok,$msg)=
	    &sysRunProg($cmdSys,$fileOutScreenLoc,$fhSbrErr);
	return(&errSbrMsg("failed convert $fileIn to FASTA ($fileOutTmp)",$msg)) 
	    if (! $Lok || ! -e $fileOutTmp);
	push(@fileTmp,$fileOutTmp);
    }
    return(1,"ok $sbrName",@fileTmp);
}				# end of copf2fasta

#===============================================================================
sub dafRdAli {
    local ($fileInLoc,$desHeader,$desExpect) = @_ ;
    local ($fhin,$tmp,$des,$Lend_ok,$ctPairs,$tmp2,$tmp1,@tmp,$idSeq,$idStr,$idxLoc,
	   $it,%Ldone,@colNames,$col,@desExpect,@desHeader,@colNamesRd,%rdLoc);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   dafRdAli                    read alignments from DAF format
#       in:
#				desHeader="key1,key2,...,keyn", where 'keyn' is the
#				key of one of the parameters used in header of file,
#				i.e. in the '#' section
#				desExpect="key1,key2,...,keyn", where 'keyn' is the
#				key of the n'th column with predefined name (others
#				e.g. zscore optionally named by user)
#       out:
#         $rd{} des_header: 	information from Header of file
#               "SOURCE"        name of original file (e.g. /data/hssp/1atf.hssp)
#         	"NPAIRS"  	number of pairs
#		"ALISYM" 	symbols allowed in alignment
#               "NSEARCH"       number of search proteins
#               "RELKEYS"       name of z-scores (separated by blanks)
#               "RELHISTO"      values for z-score intevalls
#               "ADDKEYS"       other key-names
# 
#		"COLNAMES"	names of columns used (separated by commata):
#				idSeq, idStr, lenSeq, lenStr, lenAli, pide, zscore,
#				seq, str, weightSeq
#         	"$id1,$id2"=$idx identifier of pair (1=seq, 2=str)
#         	"$n"		n'th id pair (idx="idSeq,idStr")
#         	"nZscore"	number of zscore's used
#         	"$idx","zscore","$n": 	n'th zscore for idx
#         	"$idx","seq"	sequence of 'sequence' (object of prediction) pair idx
#         	"$idx","str"	sequence of 'structure'(target of prediction)
#         	"$idx","seqLen"	length of entire 'sequence' (object of prediction) pair idx
#         	"$idx","strLen"	length of entire 'structure'(target of prediction)
#--------------------------------------------------------------------------------
    $desHeader=~s/^,|,$//g;@desHeader=split(/,/,$desHeader);
    $desExpect=~s/^,|,$//g;@desExpect=split(/,/,$desExpect);

    $fhin="FH_dafRdAli";
    &open_file("$fhin", "$fileInLoc");
				# ------------------------------
				# scan header
    while(<$fhin>){
	if ( (! /^\#/) || (/^\# ALIGNMENTS/) ) {
	    last;}
	foreach $des (@desHeader){
	    $desLower=$des;$desLower=~tr/[A-Z]/[a-z]/;
	    $lineRead=$_;$lineRead=~tr/[A-Z]/[a-z]/;
	    if ($lineRead=~/^\# $desLower/){ 
		$_=~s/\n//g;
		$_=~s/^#\s*\w+[\s|\t]*\:?[\s|\t]*|[\s|\t]*$//g;
		$rdLoc{"$des"}=$_;}}}
				# ------------------------------
				# additional columns defined?
    if (defined $rdLoc{"ADDKEYS"}){$tmp=$rdLoc{"ADDKEYS"};$tmp=~s/^\s*|^\t*|\s*$|\t*$//g;
				@tmp=split(/,/,$tmp);
				push(@desExpect,@tmp);}
				# ------------------------------
				# zscores given?
    if (defined $rdLoc{"RELKEYS"}){$tmp=$rdLoc{"RELKEYS"};$tmp=~s/^\s*|^\t*|\s*$|\t*$//g;
				@tmp=split(/,/,$tmp);
				push(@desExpect,@tmp);}

				# ------------------------------
    while(<$fhin>){		# read keys for column names 
	$_=~s/\n//g;		# = first line after '# ALIGNMENTS'
	$_=~s/^\t|^\s|\t$|\s$//g; # trailing tabs at ends
	@colNamesRd=split(/\t+|\s+/,$_);
	foreach $col(@colNamesRd){$col=~s/\s|\n//g;} # cut blanks
	last;}

    $#colNames=$#notFound=0;	# ------------------------------
    foreach $col(@colNamesRd){	# names read -> names expected
	$Lok=0;
	foreach $des(@desExpect){ 
	    $col2=$col;$col2=~tr/[A-Z]/[a-z]/;$des2=$des;$des2=~tr/[A-Z]/[a-z]/;
	    if ($col2 eq $des2){
		$Lok=1;push(@colNames,$des);
		last;}}
	if (!$Lok){push(@notFound,$col);}}

    $rdLoc{"COLNAMES"}="";		# append into string (',' separated)
    foreach $_ (@colNames){$rdLoc{"COLNAMES"}.="$_".","};$rdLoc{"COLNAMES"}=~s/^,*|,*$//g;

    if ($#notFound>0){		# consistency: all names valid?
	print "-*- WARNING dafRdAli: unexpected column names:\n";
	print "-*-                   ";&myprt_array(",",@notFound);}

				# allowed alignment symbols
    if (defined $rdLoc{"ALISYM"}){$ali_sym=$rdLoc{"ALISYM"};}
    else {$ali_sym=$rdLoc{"ALISYM"}="ACDEFGHIKLMNPQRSTVWY.acdefghiklmnpqrstvwy";}

    $Lend_ok=$ctPairs=0;
    %Ldone=0;
    				# --------------------------------------------------
    while(<$fhin>){		# read main data
	if (/^\#/) {		# ignore comments
	    next;}
	$_=~s/^\t|^\s|\t$|\s$//g; # trailing tabs at ends
	$_=~s/\n//g;
	@tmp=split(/\t+|\s+/,$_);	# split columns
				# process identifiers (first 2 columns)
	$idSeq=$tmp[1];$idSeq=~s/\s//g;
	$idStr=$tmp[2];$idStr=~s/\s//g;
	$idxLoc="$idSeq".","."$idStr";
				# ignore second event of same pair
	if ((! defined $Ldone{"$idxLoc"}) || (! $Ldone{"$idxLoc"}) ) {
	    $Ldone{"$idxLoc"}=1;}
        else {
	    next;}
	++$ctPairs;
	$rdLoc{"$ctPairs"}="$idxLoc";
				# read columns 3 - all
	foreach $it (3..$#colNames) {
	    $tmp[$it]=~tr/[a-z]/[A-Z]/;	# lower case to upper case
	    if (defined $tmp[$it]) {
	    	$rdLoc{"$idxLoc","$colNames[$it]"}=$tmp[$it];}
	    else {
		$rdLoc{"$idxLoc","$colNames[$it]"}=$tmp[$it];}}
    }
    $rdLoc{"NPAIRS"}=$ctPairs;
    close($fhin);
#    @keys=keys %rdLoc;
    return (%rdLoc);
}				# end of dafRdAli

#===============================================================================
sub dafWrtAli {
    local ($file,$sep,$desHeader,$colNames,%wrt) = @_ ;
    local ($idSeq,$idStr,$idxLoc,@colNames,$fhout,$ct,$tmp);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   dafWrtAli                   writes a file in output format of DAF
#       in:
#         $wrt{}des_header: 	information from Header of file (passed "des1,des2")
#         	"NPAIRS"  	number of pairs
#		"ALISYM" 	symbols allowed in alignment
#               "NSEARCH"       number of search proteins
#               "RELKEYS"       name of z-scores (separated by blanks)
#               "RELHISTO"      values for z-score intevalls
#               "ADDKEYS"       other key-names
# 
#		"COLNAMES"	names of columns used (separated by commata):
#				idSeq, idStr, lenSeq, lenStr, lenAli, pide, zscore,
#				seq, str, weightSeq
#         	"$id1,$id2"=$idx identifier of pair (1=seq, 2=str)
#         	"$n"		n'th id pair (idx="idSeq,idStr")
#         	"nZscore"	number of zscore's used
#         	"$idx","zscore","$n": 	n'th zscore for idx
#         	"$idx","seq"	sequence of 'sequence' (object of prediction) pair idx
#         	"$idx","str"	sequence of 'structure'(target of prediction)
#         	"$idx","seqLen"	length of entire 'sequence' (object of prediction) pair idx
#         	"$idx","strLen"	length of entire 'structure'(target of prediction)
#--------------------------------------------------------------------------------
    $fhout="FH_dafWrtAli";	# ini
    &open_file("$fhout",">$file");

    @colNames=			# write header
    	&dafWrtAliHeader($fhout,$sep,$desHeader,$colNames);

    $ct=1;			# ----------------------------------------
    while (defined $wrt{"$ct"}){ # write all columns 
	$idxLoc=$wrt{"$ct"};
	($idSeq,$idStr)=split(/,/,$wrt{"$ct"});
	print $fhout "$idSeq$sep$idStr$sep";
	foreach $col (@colNames){
	    if (defined $wrt{"$idxLoc","$col"}){
		print $fhout $wrt{"$idxLoc","$col"};}
	    else {
		print $fhout "";}
	    if ($col eq $colNames[$#colNames]){ $tmp="\n";}else{$tmp=$sep;}
	    print $fhout $tmp;}
	++$ct;}
    print $fhout "\n";
    close($fhout);
}				# end of dafWrtAli

#===============================================================================
sub dafWrtAliHeader {
    local ($fhout,$sep,$desHeader,$colNames) = @_ ;
    local (@desHeader,@colNames);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   dafWrtAliHeader             writes the header for DAF file
#--------------------------------------------------------------------------------
    $desHeader=~s/^,|,$//g;	# process header
    @desHeader=split(/,/,$desHeader);
    $colNames=~s/^,|,$//g;	# process column names
    @colNames=split(/,/,$colNames);
				# variables
    print $fhout "# DAF (dirty alignment format for exchange with Aqua)\n# \n";
    foreach $des (@desHeader){
	if ($des =~ /^COLNAMES/) {
	    next;}
	printf $fhout "# %-8s: \t %-s\n",$des,$wrt{"$des"}; }
				# column names
    printf $fhout "# %-8s:\t %-s\n","COLNAMES",$colNames;
				# notations
    print $fhout 
 	"# \n",
	"# NOTATION:\t ALISYM  symbols allowed in alignments\n",
	"# NOTATION:\t NPAIRS  number of pairs aligned\n",
	"#\n",
	"# NOTATION:\t idSeq   identifier of 'Sequence', i.e. the search protein\n",
	"# NOTATION:\t idStr   identifier of 'Structure', i.e. the template which you aligned\n",
	"# NOTATION:\t lenSeq  length of protein (or chain, or domain) of 'Sequence'\n",
	"# NOTATION:\t lenStr  length of protein (or chain, or domain) of 'Structure'\n",
	"# NOTATION:\t lenAli  number of residues aligned\n",
	"# NOTATION:\t pide    percentage of sequence identity = Nidentical/Naligned residues\n",
	"# NOTATION:\t zscore  your score describing the significance of the hit \n",
	"# NOTATION:\t         (more than 1 column, and any key allowed)\n",
	"# NOTATION:\t seq     sequence of 'Sequence'\n",
	"# NOTATION:\t str     sequence of 'Structure'\n",
	"# NOTATION:\t weightSeq residue specific weight you may attach to the alignment\n",
	"# NOTATION:\t \n",
	"#\n";   
    print $fhout "# ALIGNMENTS\n";
    foreach $it(1..($#colNames-1)){ print $fhout $colNames[$it],"$sep";} 
    print $fhout $colNames[$#colNames],"\n";
    return(@colNames);
}				# end of dafWrtAliHeader

#===============================================================================
sub dsspGetChain {
    local ($fileIn,$chainIn,$begIn,$endIn) = @_ ;
    local ($Lread,$sbrName,$fhin,$aa,$aa2,$seq,$seqC,$chainRd,$pos);
    $[=1;
#----------------------------------------------------------------------
#   dsspGetChain                extracts all chains from DSSP
#       in:                     $file
#       out:                    $Lok,$tmp{"chains"}='C,D,...'
#       out:                         $tmp{"$chain","beg"},$tmp{"$chain","end"},
#----------------------------------------------------------------------
    $sbrName = "lib-br:dsspGetChain" ;$fhin="fhinDssp";
    &open_file("$fhin","$fileIn") ||
        return(0,"*** ERROR $sbrName: failed to open input $fileIn\n");
				#--------------------------------------------------
    while ( <$fhin> ) {		# read in file
	last if ( /^  \#  RESIDUE/ ); }	# skip anything before data...
    undef %tmp;
    $chainNow=$chains="";
    while ( <$fhin> ) {		# read chain
	$Lread=1;
	$chainRd=substr($_,12,1); $chainRd="*" if ($chainRd eq " ");
	$pos=    substr($_,7,5); $pos=~s/\s//g;
	if ($chainRd ne $chainNow){$chainNow=$chainRd;
				   $chains.=$chainRd.",";
				   $tmp{"$chainRd","beg"}=$pos;}
	else                      {$tmp{"$chainRd","end"}=$pos;}}close($fhin);
    $chains=~s/^,*|,*$//g;$tmp{"chains"}=$chains;
    return(1,%tmp);
}                               # end of: dsspGetChain 

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
	    $tmp_file="$it"."$tmp1".".dssp";
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

#===============================================================================
sub dsspRdSeq {
    local ($fileIn,$chainIn,$begIn,$endIn) = @_ ;
    local ($Lread,$sbrName,$fhin,$aa,$aa2,$seq,$seqC,$chainRd,$pos);
    $[=1;
#----------------------------------------------------------------------
#   dsspRdSeq                   extracts the sequence from DSSP
#       in:                     $file,$chain,$beg,$end
#       in:                     for wild cards beg="", end=""
#       out:                    $Lok,$seq,$seqC (second replaced a-z to C)
#----------------------------------------------------------------------
    $sbrName = "lib-br:dsspRdSeq" ;$fhin="fhinDssp";
    &open_file("$fhin","$fileIn") ||
        return(0,"*** ERROR $sbrName: failed to open input $fileIn\n");
				#----------------------------------------
				# extract input
    if (defined $chainIn && length($chainIn)>0 && $chainIn=~/[A-Z0-9]/){
	$chainIn=~s/\s//g;$chainIn =~tr/[a-z]/[A-Z]/; }else{$chainIn = "*" ;}
    $begIn = "*" if (! defined $begIn || length($begIn)==0); $begIn=~s/\s//g;;
    $endIn = "*" if (! defined $endIn || length($endIn)==0); $endIn=~s/\s//g;;
				#--------------------------------------------------
				# read in file
    while ( <$fhin> ) { 
	last if ( /^  \#  RESIDUE/ ); }	# skip anything before data...
    $seq=$seqC="";
    while ( <$fhin> ) {		# read sequence
	$Lread=1;
	$chainRd=substr($_,12,1); 
	$pos=    substr($_,7,5); $pos=~s/\s//g;

	next  if (($chainRd ne "$chainIn" && $chainIn ne "*" ) || # check chain
                  ($begIn ne "*"  && $pos < $begIn) || # check begin
                  ($endIn ne "*"  && $pos > $endIn)) ; # check end

	$aa=substr($_,14,1);
	$aa2=$aa;if ($aa2=~/[a-z]/){$aa2="C";}	# lower case to C
	$seq.=$aa;$seqC.=$aa2; } close ($fhin);
    return(1,$seq,$seqC) if (length($seq)>0);
    return(0);
}                               # end of: dsspRdSeq 

#===============================================================================
sub fastaRdGuide {
    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   fastaRdGuide                reads first sequence in list of FASTA format
#       in:                     $fileInLoc,$fhErrSbr
#       out:                    0|1,$id,$seq
#       err:                    ok=(1,id,seq), err=(0,'msg',)
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."fastaRdGuide";$fhinLoc="FHIN"."$sbrName";

    $Lok=       &open_file("$fhinLoc","$fileInLoc");
    return(0,"*** ERROR $sbrName: old '$fileInLoc' not opened\n"," ") if (! $Lok);
    $ct=0;$seq="";
    while (<$fhinLoc>) {
	$_=~s/\n//g;
	if ($_=~/^\s*>\s*(.+)$/){
	    ++$ct;
	    last if ($ct>1);
	    $id=$1;$id=~s/[\s\t]+/ /g;
#	    $id=~s/^[^A-Za-z0-9]*|[^A-Za-z0-9]*$//g;
	    next;}
	$seq.="$_";}
    $seq=~s/\s//g;
    return(0,"*** ERROR $sbrName: no guide sequence found\n"," ") if (length($seq)<1);
    return(1,$id,$seq);
}				# end of fastaRdGuide

#===============================================================================
sub fastaRdMul {
    local($fileInLoc,$rd) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   fastaRdMul                  reads many sequences in FASTA db
#       in:                     $fileInLoc,$rd with:
#                               $rd = '1,5,6',   i.e. list of numbers to read
#                               $rd = 'id1,id2', i.e. list of ids to read
#                               NOTE: numbers faster!!!
#       out:                    1|0,$id,$seq (note: many ids/seq separated by '\n'
#       err:                    ok=(1,id,seq), err=(0,'msg')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:fastaRdMul";$fhinLoc="FHIN_"."$sbrName";

    &open_file("$fhinLoc","$fileInLoc") ||
	return(0,"*** ERROR $sbrName: old '$fileInLoc' not opened\n"," ");

    undef %tmp;
    if (! defined $rd) {
	$LisNumber=1;
	$rd=0;}
    elsif ($rd !~ /[^0-9\,]/){ 
	@tmp=split(/,/,$rd); 
	$LisNumber=1;
	foreach $tmp(@tmp){$tmp{$tmp}=1;}}
    else {$LisNumber=0;
	  @tmp=split(/,/,$rd); }
    
    $ct=$ctRd=0;
    while (<$fhinLoc>) {
	$_=~s/\n//g;
	if ($_=~/^\s*>\s*(.+)$/){ # line with id
	    ++$ct;$Lread=0;
	    last if ($rd && $ctRd==$#tmp); # fin if all found
	    next if ($rd && $LisNumber && ! defined $tmp{$ct});
	    $id=$1;$id=~s/\s\s*/ /g;$id=~s/^[^A-Za-z0-9]*|[^A-Za-z0-9]*$//g;
	    $Lread=1 if ( ($LisNumber && defined $tmp{$ct})
			 || $rd == 0);

	    if (! $Lread){	# go through all ids
		foreach $tmp(@tmp){
		    next if ($tmp !~/$id/);
		    $Lread=1;	# does match, so take
		    last;}}
	    next if (! $Lread);

	    ++$ctRd;
	    $tmp{"$ctRd","id"}=$id;
	    $tmp{"$ctRd","seq"}="";}
	elsif ($Lread) {	# line with sequence
	    $tmp{"$ctRd","seq"}.="$_";}}

    $seq=$id="";		# join to long strings
    foreach $it (1..$ctRd) { $id.= $tmp{"$it","id"}."\n";
			     $tmp{"$it","seq"}=~s/\s//g;
			     $seq.=$tmp{"$it","seq"}."\n";}
    $#tmp=0;undef %tmp;		# save memory
    return(0,"*** ERROR $sbrName: file=$fileInLoc, nali=$ct, wanted: (rd=$rd)\n"," ") 
        if (length($seq)<1);
    return(1,$id,$seq);
}				# end of fastaRdMul

#===============================================================================
sub fastaWrt {
    local($fileOutLoc,$id,$seqLoc) = @_ ;
    local($sbrName,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   fastaWrt                    writes a sequence in FASTA format
#       in:                     $fileOut,$id,$seq (one string)
#       out:                    
#       err:                    ok=(1,'ok'), err=(0,'msg')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:fastaWrt";$fhoutLoc="FHOUT_"."$sbrName";
#    print "yy into write seq=$seqLoc,\n";

    &open_file("$fhoutLoc",">$fileOutLoc") ||
        return(0,"*** ERROR $sbrName: '$fileOutLoc' not opened for write\n");
    print $fhoutLoc ">$id\n";
    for($it=1;$it<=length($seqLoc);$it+=50){
	foreach $it2 (0..4){
	    last if (($it+10*$it2)>=length($seqLoc));
	    printf $fhoutLoc " %-10s",substr($seqLoc,($it+10*$it2),10);}
	print $fhoutLoc "\n";}
    close($fhoutLoc);
    return(1,"ok $sbrName");
}				# end of fastaWrt

#===============================================================================
sub fastaWrtMul {
    local($fileOutLoc,%tmp) = @_ ;
    local($sbrName,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   fastaWrtMul                 writes a list of sequences in FASTA format
#       in:                     $fileOut,$tmp{} with:
#       in:                     $tmp{"NROWS"}      number of sequences
#       in:                     $tmp{"id","$ct"}   id for sequence $ct
#       in:                     $tmp{"seq","$ct"}  seq for sequence $ct
#       out:                    file
#       err:                    err  -> 0,message
#       err:                    ok   -> 1,ok
#       err:                    warn -> 2,not enough written
#-------------------------------------------------------------------------------
    $sbrName="lib-br:fastaWrtMul";$fhoutLoc="FHOUT_"."$sbrName";

    return(0,"*** ERROR $sbrName: no tmp{NROWS} defined\n") if (! defined $tmp{"NROWS"});
    &open_file("$fhoutLoc",">$fileOutLoc") ||
        return(0,"*** ERROR $sbrName: '$fileOutLoc' not opened for write\n");

    $ctOk=0; 
    foreach $itPair (1..$tmp{"NROWS"}){
        next if (! defined $tmp{"id","$itPair"} || ! defined $tmp{"seq","$itPair"});
        ++$ctOk;
                                # some massage
        $tmp{"id","$itPair"}=~s/[\s\t\n]+/ /g;
        $tmp{"seq","$itPair"}=~s/[\s\t\n]+//g;
                                # write
        print $fhoutLoc ">",$tmp{"id","$itPair"},"\n";
	$lenHere=length($tmp{"seq","$itPair"});
        for($it=1; $it<=$lenHere; $it+=50){
	    $tmpWrt=      "";
            foreach $it2 (0..4){
		$itHere=($it + 10*$it2);
                last if ( $itHere >= $lenHere);
		$nchunk=10; 
		$nchunk=1+($lenHere-$itHere)  if ( (10 + $itHere) > $lenHere);
		$tmpWrt.= sprintf(" %-10s",substr($tmp{"seq","$itPair"},$itHere,$nchunk)); 
	    }
	    print $fhoutLoc $tmpWrt,"\n";
	}
    }
    close($fhoutLoc);
    return(0,"*** ERROR $sbrName: no sequence written\n")               
	if (! $ctOk);
    return(2,"-*- WARN $sbrName: wrote fewer sequences than expected\n") 
	if ($ctOk!=$tmp{"NROWS"});
    return(1,"ok $sbrName");
}				# end of fastaWrtMul

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
	foreach $it(1..9){$tmp_file="$it"."$tmp1".".fssp";
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

#===============================================================================
sub fsspRdSummary {
    local ($fileLoc,$desLoc) = @_ ;local (%rdLoc);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   fsspRdSummary               read the summary table of an FSSP file
#       in:                     $fileLoc,$desLoc
#       des                     "header,desH1,desH2,body,desB1,desB2"
#       headers:		PDBID,HEADER,SOURCE,SEQLENGTH,NALIGN
#       body:			NR,STRID1,ST  RID2,Z,RMSD,LALI,LSEG2,%IDE,
#				REVERS,PERMUT,NFRAG,TOPO,PROTEIN
#       out:   		header  : $rd{"$des"}, body: %rd{"$des","$ct"}
#--------------------------------------------------------------------------------
				# ini
    $fhinLoc="FhFsspRdSummary";
				# read argument: desired keys
    @des=split(/,/,$desLoc);
    $#desHeader=$#desBody=0;
    foreach $_(@des){
	$_=~s/\n|\s//g;
	if   (/^header/){$Lheader=1;}
	elsif(/^body/)  {$Lheader=0;}
	elsif ($Lheader){push(@desHeader,$_);}
	else            {push(@desBody,$_);}}

    &open_file("$fhinLoc", "$fileLoc");
				#--------------------------------------------------
				# read header
    while(<$fhinLoc>){
	last if (/^\#\# SUMMARY/);
	$_=~s/\n//g;		# purge new line
    	foreach $des(@desHeader){
	    if (/^$des/){
		$_=~s/^$des\s+//g;
		$rdLoc{"$des"}=$_;
		last;}}}
				#--------------------------------------------------
				# read body
    $ctPairs=0;
    while(<$fhinLoc>){
	last if (/^\#\# ALIGNMENTS/);
	$_=~s/\n//g;		# purge new line
	$_=~s/^\s*|\s*$//g;	# trail leading blanks
				# ------------------------------
	if (/^\s*NR/){		# read names (first line)
	    @names=split(/\s+/,$_);
	    foreach $names(@names){$names=~s/\.//g;}
	    $ct=0;
	    foreach $it(1..$#names){foreach $des(@desBody){
		if ($des eq $names[$it]){ $point{"$des"}=$it;++$ct;
					  last;}}}
				# consistency check
	    if ( $ct != $#desBody ) {
		print "-*- WARNING fsspRdSummary: not all names found:\n";
		print "-*-         read (names)  :";&myprt_array(",",@names);
		print "-*-         want (desBody):";&myprt_array(",",@desBody);
		print "-*-         ok            :";
		foreach $des (@desBody){if (defined $point{"$des"}){print"$des,";}}
		print "\n";}
	    next;}
				# ------------------------------
	@tmp=split(/\s+/,$_);	# read rest
    	foreach $des(@desBody){
	    if (defined $point{"$des"}){
		$tmp=$point{"$des"};
		if   (($des eq $desBody[1])&&(defined $tmp[$tmp])){
		    ++$ctPairs;}
		elsif($des eq $desBody[1]){
		    last;}
		$rdLoc{"$des","$ctPairs"}=$tmp[$tmp]; } }
    }close($fhinLoc);
    $rdLoc{"NROWS"}=$rdLoc{"NPAIRS"}=$ctPairs;
    return(%rdLoc);
}				# end of fsspRdSummary

#===============================================================================
sub fssp_rd_ali {
    local($line_ali,@pos)=@_;
    local(%rd_ali,@des1,@des2,%ptr,%len,$des,$pos,@line,$tmp,$beg,$end,$Lok,$ptr,$postmp);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   fssp_rd_ali                 reads one entire alignment for an open FSSP file
#       in:
#         $line_ali             all lines with FSSP alis in one string (separated
#                               by newlines (\n) )
#         @pos                  positions to be read
#       out:
#         $rd{seq1},$rd{sec1},$rd{acc1},$rd{seq2,pos},$rd{sec2,pos}
#                               note: acc="n1,n2,"
#--------------------------------------------------------------------------------
    $#tmp=0;$Lis_old=0;
    foreach $pos(@pos){
	if ($pos=~/is_old/){
	    $Lis_old=1;}
	else {
	    push(@tmp,$pos);}}
				# ----------------------------------------
				# defaults (pointers to column numbers
				#           in FSSP)
				# ----------------------------------------
    @des1=("seq1","sec1","acc1");
    @des2=("seq2","sec2");
    $len{"seq1"}=1;$len{"sec1"}=1;$len{"acc1"}=3;$len{"seq2"}=1;$len{"sec2"}=1;
    if ($Lis_old){
	$ptr{"seq1"}=14;$ptr{"sec1"}=17;$ptr{"acc1"}=35;
	$ptr{"seq2"}=46;$ptr{"sec2"}=47;}
    else {
	$ptr{"seq1"}=13;$ptr{"sec1"}=16;$ptr{"acc1"}=35;
	$ptr{"seq2"}=43;$ptr{"sec2"}=44;}
				# initialise
    %rd_ali=$#line=0;
    foreach $des (@des1) { $rd_ali{"$des"}="";}
    foreach $des (@des2) { foreach $pos (@pos) { $rd_ali{"$des","$pos"}="";} }
    @line=split(/\n/,$line_ali);
				# ----------------------------------------
				# read the alis
				# ----------------------------------------
    foreach $_ (@line){
	if (/^\#\# ALIGNMENTS/) {
	    $tmp=$_;$tmp=~s/.*ALIGNMENTS\s*(\d+)\s*-\s*(\d+)/$1-$2/g;
	    ($beg,$end)=split(/-/,$tmp);
	    $Lok=0;
	    foreach $pos (@pos) {
		if ( ($pos>=$beg) && ($pos<=$end) ) { $Lok=1; last; }} }
				# ------------------------------
				# within range?
	if ($Lok) {
	    if (! /^\s*\d+/){next;}
				# read sequence 1 (guide)
	    foreach $des (@des1) {
		$rd_ali{"$des"}.=substr($_,$ptr{"$des"},$len{"$des"}); 
		if ($des=~/acc/){$rd_ali{"$des"}.=",";}}
				# read all aligned sequences
	    foreach $pos (@pos) {
		if ( ($pos>=$beg) && ($pos<=$end) ) { 
		    foreach $des (@des2) { 
			$postmp=$pos-($beg-1);
			$ptr=($postmp-1)*3+$ptr{"$des"};
			$rd_ali{"$des","$pos"}.=substr($_,$ptr,$len{"$des"});
			if ($des=~/acc/){$rd_ali{"$des","$pos"}.=",";}
		    } } } }
    }
				# upper case sec str for aligned
    foreach $pos (@pos){ $rd_ali{"sec2","$pos"}=~tr/[a-z]/[A-Z]/; }
    return %rd_ali;
}				# end of fssp_rd_ali

#===============================================================================
sub fssp_rd_one {
    local ($fileInLoc,$id_in,@des_in) = @_ ;
    local ($fhin,$tmpline,$tmp,@tmp,$tmp1,$it,$id2_col,$nr_col,$des,$id2,$nr_search,
	   %rdLoc,%rd_tmp,$Lread_alis,$nr1,$nr2,$line_ali,$Lok,@des,@des_ali);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   fssp_rd_one                 reads for a given FSSP file one particular ali+header
#       in:                     $fssp_file,$id_to_be_read,
#                               @des  = e.g. STRID2, i.e., FSSP column names for summary table
#                                       + seq,sec,acc (if all 3 to be returned)
#       out:                    returned:
#                               $rd{STRID2} ...
#                               $rd{seq1},$rd{sec1},$rd{acc1},$rd{seq2,pos},$rd{sec2,pos}
#                               note: acc="n1,n2,"
#--------------------------------------------------------------------------------
				# defaults
    $fhin="FHIN_FSSP";
    $Lread_alis=1;
    $#des=$#des_ali=0;
    foreach $des(@des_in){
	if ($des!~/seq|sec|acc/){
	    push(@des,$des);}
	else {
	    push(@des_ali,$des);}}
				# check existence
    if (! -e $fileInLoc){
	print "*** ERROR fssp_rd_one: fssp file '$fileInLoc' missing\n";
	exit;}
				# read file
    $Lis_old=0;
    &open_file("$fhin", "$fileInLoc");
    while ( <$fhin> ) { 
	if (/NOTATION/) {
	    $Lis_old=1;}
	last if (/^\#\# PROTEINS|^\#\# SUMMARY/); }
    while ( <$fhin> ) {
	$_=~s/^\s*//g;
	if ( (length($_)<2) || (/^\#\# ALI/) ) { # store and out
	    $tmpline=$_;
	    last;}
	if ( /^NR\./ ) { # read header
	    $tmp1=substr($_,1,70); 
	    $_=~s/^\s*|\s*$//g;	# purge leading blanks
	    $#tmp=0;
	    @tmp=split(/\s+/,$_);
	    $it=0;
	    foreach $tmp (@tmp){
		++$it;
		if ($tmp=~/STRID2|PDBID2/){ # search STRID2 (pdbid of 2nd protein)
		    $id2_col=$it;}
		if ($tmp=~/NR/){ # search column for number of hit
		    $nr_col=$it;}
		foreach $des (@des) {if ($tmp =~ /$des/) { $ptr_rd2des{"$des"}=$it; last; }}
	    } }
				# read protein info in header
	else {
	    $_=~s/^\s*|\:|\s*$//g;	# purge leading blanks
	    $#tmp=0;
	    @tmp=split(/\s+/,$_);
	    $id2=$tmp[$id2_col];
	    $id2=~s/-//g;	# correct chain
	    if ($id2=~/$id_in/) {
		$nr_search=$tmp[$nr_col];
		foreach $des (@des) {
		    if (defined $ptr_rd2des{"$des"}){
			$tmp=$ptr_rd2des{"$des"};
			$rdLoc{"$des"}=$tmp[$tmp];$rdLoc{"$des"}=~s/\s|://g;}
		    else {
			print "*-* WARNING: fssp_rd_one not defined des=$des,\n";} }
	    } }
    }
    if ($Lread_alis) {		# read alignments
	$Lok=0;$line_ali="";
	while ( <$fhin> ) {
	    last if ( /^\#\# EQUI/ );
	    if ( ($tmpline =~ /\#/) || (/\#/) ) { # extract range
		if ($Lok){
		    last;}
		if ($tmpline=~/\#/){
		    $tmp=$tmpline;
		    $tmpline=" ";}
		else {
		    $tmp=$_;}
		$tmp=~s/^.+ALIGNMENTS\s+//g;
		$tmp=~s/\s//g;
		$tmp=~s/(\d+)-(\d+)//g;
		$nr1=$1;$nr2=$2;
		if ( ($nr1<=$nr_search) && ($nr_search<=$nr2) ) { # correct range?
		    $Lok=1; } }
	    if ($Lok && (length($_)>3)) {
		$line_ali.="$_"; }
	}
	if (!$Lok){
	    print "*** ERROR fssp_rd_one: didn't read any ali\n";
	    print "***       desired id2=$id_in, nr=$nr_search,\n";
	    exit; }
	%rdLoc=0;
	if ($Lis_old){
	    %rd_tmp=&fssp_rd_ali($line_ali,$nr_search,"is_old");}
	else {
	    %rd_tmp=&fssp_rd_ali($line_ali,$nr_search);}
    }				# end of reading alignments
    close($fhin);
    foreach $des(@des_ali){
	$tmp=$des."1";
	$rdLoc{"$tmp"}=$rd_tmp{"$tmp"};
	$tmp=$des."2";
	$rdLoc{"$tmp"}=$rd_tmp{"$tmp","$nr_search"};}
    return(%rdLoc);
}				# end of fssp_rd_one

#===============================================================================
sub gcgRd {
    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   gcgRd                       reads sequence in GCG format
#       in:                     $fileInLoc
#       out:                    1|0,$id,$seq 
#       err:                    ok=(1,id,seq), err=(0,'msg')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:gcgRd";$fhinLoc="FHIN_"."$sbrName";

    &open_file("$fhinLoc","$fileInLoc") ||
	return(0,"*** ERROR $sbrName: old '$fileInLoc' not opened\n"," ");

    $seq="";
    while (<$fhinLoc>) {
	$_=~s/\n//g;$line=$_;
	if ($line=~/^\s*(\S+)\s*from\s*:/){
	    $id=$1;
	    next;}
	next if ($line !~ /^\s*\d+\s+(.*)$/);
	$tmp=$1;$tmp=~s/\s//g;
	$seq.=$tmp;}close($fhinLoc);

    return(0,"*** ERROR $sbrName: file=$fileInLoc, no sequence found\n") if (length($seq)<1);
    return(1,$id,$seq);
}				# end of gcgRd

#===============================================================================
sub get_chain { local ($file) = @_ ; local($chain);$[ =1 ;
#--------------------------------------------------------------------------------
#   get_chain                   extracts a chain identifier from file name
#                               note: assume: '_X' where X is the chain (return upper)
#       in:                     $file
#       out:                    $chain
#--------------------------------------------------------------------------------
		$chain=$file;
		$chain=~s/\n//g;
		$chain=~s/^.*_(.)$/$1/;
		$chain=~tr/[a-z]/[A-Z]/;
		return($chain);
}				# end of get_chain

#===============================================================================
sub get_in_database_files {
    local ($database,@argLoc) = @_ ;
    local ($fhinLoc,@fileLoc,$rd,$argLoc);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   get_in_database_files       reads command line, checks validity of format, returns array
#       in:                     $opt,@arg, : $opt="HSSP","DSSP","FSSP,"DAF","MSF","RDB",
#       out:                    @files
#--------------------------------------------------------------------------------
    $fhinLoc="FHIN_get_in_files";
    $#fileLoc=0;
    foreach $argLoc(@argLoc){
	$argLoc=~s/\n|\s//g;if (length($argLoc)<5){next;}if (! -e $argLoc){next;}
				# ------------------------------
				# HSSP or DSSP 
	if     (($database eq "HSSP")||($database eq "DSSP")){
	    if ((($database eq "HSSP")&&(&is_hssp_list($argLoc))) || 
		(($database eq "DSSP")&&(&is_dssp_list($argLoc)))){
		$file=$argLoc; &open_file("$fhinLoc","$file");
		while(<$fhinLoc>){$rd=$_;$rd=~s/\s|\n//g;
				  if (length($rd)<5){next;}$rdChain=$rd;
				  if(! -e $rd){$rd=~s/_.$//;} # purge chain
				  if (! -e $rd){next;}
				  push(@fileLoc,$rdChain);}close($fhin);}
	    elsif ((($database eq "HSSP")&&(&is_hssp($argLoc))) || 
		   (($database eq "DSSP")&&(&is_dssp($argLoc)))){
		push(@fileLoc,$tmp);}}
				# ------------------------------
				# FSSP
	elsif ($database eq "FSSP"){
	    if (&is_fssp_list($argLoc)){$file=$argLoc; &open_file("$fhinLoc","$file");
					while(<$fhinLoc>){
					    $rd=$_;$rd=~s/\s|\n//g;if (! -e $rd){next;}
					    push(@fileLoc,$rd);}close($fhin);}
	    elsif (&is_fssp($tmp))  {push(@fileLoc,$tmp);}}
	else {
	    print "*** ERROR get_in_database_files: database '$database' not digestable yet\n";
	    exit;}}
    return(@fileLoc);
}				# end of get_in_database_files

#===============================================================================
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
#       out:                    $Lok,$msg,%fileFound
#                               $fileFound{"NROWS"}=      number of files found
#                               $fileFound{"ct"}=         name-of-file-ct
#                               $fileFound{"format","ct"}=format
#                               $fileFound{"chain","ct"}= chain
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."getFileFormat";$fhinLoc="FHIN"."$sbrName";
    undef %fileLoc;
    if ($#dirLoc >0){$#tmp=0;	# include existing directories only
		     foreach $dirLoc(@dirLoc){
			 push(@tmp,$dirLoc) if (-d $dirLoc)}
		     @dirLoc=@tmp;}
				# check whether keyword understood
    if (! defined $kwdLoc){$kwdLoc="any";}
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
	$fileLoc{"$it"}=$fileLoc[$it];
	$fileLoc{"format","$it"}=$formatLoc[$it];
	if ((defined $chainLoc[$it])&&
	    (length($chainLoc[$it])>0)&&($chainLoc[$it]=~/[A-Za-z0-9]/)){
	    $fileLoc{"chain","$it"}=$chainLoc[$it];}}
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
    return(1,"FASTA")        if (&isFasta($fileInLoc));
    return(1,"SWISS")        if (&isSwiss($fileInLoc));
    return(1,"PIR")          if (&isPir($fileInLoc));

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

#===============================================================================
sub interpretSeqCol {
    local ($fileOutLoc,$fileOutGuideLoc,$nameFileIn,$Levalsec,$fhErrSbr,@seqIn) = @_ ;
    local ($sbrName,$Lok,$msg,$tmp,@tmp,$fhout,$fhout2,$LfirstLine,$Lhead,$ct,$ctok,
	   $it,$des,$Lptr,$Lguide,$seqGuide,$nameGuide,@des_column_format,@des_evalsec,
	   $sec,$acc,$itx,%rd,%ptrkey2,%ptr2rd);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   interpretSeqCol             extracts the column input format and writes it
#       in:                     $fileOutLoc,$fileOutGuideLoc,$nameFileIn,$Levalsec,
#       in:                     $fhErrSbr,@seqIn
#       out:                    either write for EVALSEC or DSSP format and guide in FASTA
#       in/out GLOBAL:          @NUM,@SEQ,@SEC(HE ),@ACC,@RISEC,@RIACC (for wrt_dssp_phd)
#       err:                    e: (1,msg) -> ok
#       err:                    a: (0,msg) -> some arguments missing/files not opened
#       err:                    b: (2,msg) -> ERROR while writing output
#       err:                    c: (3,msg) -> guide sequence not written
#--------------------------------------------------------------------------------
    $sbrName="interpretSeqCol";
    return(0,"*** $sbrName: not def fileOutLoc!") if (! defined $fileOutLoc);
    return(0,"*** $sbrName: not def fileOutGuideLoc!") if (! defined $fileOutGuideLoc);
    return(0,"*** $sbrName: not def nameFileIn!") if (! defined $nameFileIn);
    return(0,"*** $sbrName: not def Levalsec!")   if (! defined $Levalsec);
    return(0,"*** $sbrName: not def fhErrSbr!")   if (! defined $fhErrSbr);
    return(0,"*** $sbrName: not def seqIn[1]!")   if (! defined $seqIn[1]);
				# desired column names for COLUMN format (make non-local)
#    @des_column_all=("AA","PHEL","OHEL","RI_S","OTH","OTE","OTL","PACC","PREL","RI_A","PBIE",
#		     "OT0","OT1","OT2","OT3","OT4","OT5","OT6","OT7","OT8","OT9","NAME");

    @des_column_format=("AA","PHEL","RI_S","PACC","RI_A","OHEL","NAME");
    @des_evalsec=      ("NAME","AA","PHEL","OHEL");
    %ptrkey2=('AA',   "AA",     'NAME', "NAME",
	      'PHEL', "PSEC",   'OHEL', "OSEC",   'PACC', "PACC", 
	      'RI_S', "RI_SEC", 'RI_A', "RI_ACC");
    $fhout="FHOUT_".$sbrName;$fhout2="FHOUT2_".$sbrName;
    $ct=0;			# initialise arrays asf
    $#SEQ=$#SEC=$#ACC=$#RISEC=$#RIACC=$#OSEC=$#NAME=0; # GLOBAL for wrt_dssp_phd
                                # ----------------------------------------
                                # continue reading open file
                                # ----------------------------------------
    foreach $_(@seqIn){
	next if (/^\#/);	# ignore second hash, br: 10-9-96
	next if (length($_)==0);
	$tmp=$_;$tmp=~s/\n//g;
	$tmp=~tr/[a-z]/[A-Z]/;	# lower to upper
	++$ct;
	last if ($_ !~/[\s\t]*\d+/ && $ct>1);
	$tmp=~s/^[ ,\t]*|[ ,\t]*$//g; # purge leading blanks begin and end
	$#tmp=0;@tmp=split(/[\s\t,]+/,$tmp); # split spaces, tabs, or commata
	if ($ct==1){		# first line: check identifiers passed
	    undef %ptr2rd;$ctok=$Lok=0;
	    foreach $des (@des_column_format){
		foreach $it (1..$#tmp) {
		    if ($des eq $tmp[$it]) {
			++$ctok;$Lok=1;$ptr2rd{"$des"}=$it; 
			last; }
				# alternative key?
		    elsif ((defined $ptrkey2{"$des"})&&($ptrkey2{"$des"} eq $tmp[$it])) {
			++$ctok;$Lok=1;$ptr2rd{"$des"}=$it; 
			last; } }
		if (! $Lok) {
		    if ($des=~/AA|PHEL|PACC/){$ctok=0;
					      last;}
		    print $fhErrSbr
			"*** $sbrName ERROR: names in columns, des=$des, not found\n";} }
	    $Lptr=1 if ($ctok>=3);} # at least 3 found?
	elsif($ct>1) {		# for all others read
	    if (! $Lptr){	# stop if no amino acid
		print $fhErrSbr "*** $sbrName ERROR: not Lptr error? (30.6.95) \n";
		next;}
	    if(defined $ptr2rd{"AA"})  {$tmp=$tmp[$ptr2rd{"AA"}];
					if ($tmp !~ /[ABCDEFGHIKLMNPQRSTUVWXYZ\.\- ]/){
					    $Lptr=0;
					    last;}
					push(@SEQ,  $tmp[$ptr2rd{"AA"}]);}
	    if(defined $ptr2rd{"PHEL"}){push(@SEC,  $tmp[$ptr2rd{"PHEL"}]);}
	    if(defined $ptr2rd{"PACC"}){push(@ACC,  $tmp[$ptr2rd{"PACC"}]);}
	    if(defined $ptr2rd{"OHEL"}){push(@OSEC, $tmp[$ptr2rd{"OHEL"}]);}
	    if(defined $ptr2rd{"RI_S"}){push(@RISEC,$tmp[$ptr2rd{"RI_S"}]);}
	    if(defined $ptr2rd{"RI_A"}){push(@RIACC,$tmp[$ptr2rd{"RI_A"}]);}
	    if(defined $ptr2rd{"NAME"}){push(@NAME, $tmp[$ptr2rd{"NAME"}]);}}}
                                # ----------------------------------------
				# error checks
                                # ----------------------------------------
    $Lok=1;
    foreach $sec(@SEC){
	if ($sec=~/[^HEL \.]/){
	$Lok=0;			# wrong secondary structure symbol
	$msg="wrong secStr: allowed H,E,L ($sec)";print $fhErrSbr "*** $sbrName ERROR: $msg\n";
	last;}}
    if ($Lok && ($#ACC>0)){foreach $acc(@ACC){if (($acc=~/[^0-9]/) || (int($acc)>500) ){
	$Lok=0;		# wrong values for accessibility
	$msg="wrong acc: allowed 0-500 ($acc)";print $fhErrSbr "*** $sbrName ERROR: $msg\n";
	last;}}}
    if ($Lok && ($#SEQ<1)){
	$Lok=0;			# not enough sequences
	$msg="sequence array empty";print $fhErrSbr "*** $sbrName ERROR: $msg\n";}
    if ($Lok && ( $Levalsec && ($#OSEC<1))){
	$Lok=0;			# EVALSEC: must have observed sec str
	$msg="for EVALSEC OSEC must be defined\n";print $fhErrSbr "*** $sbrName ERROR: $msg\n";}
				# ******************************
				# error: read/write col format
    return(0,"*** $sbrName ERROR $msg") if (!$Lok);
				# ******************************

                                # ----------------------------------------
				# write output file
                                # ----------------------------------------
				# added br may 96, as noname crushed!
    $itx=0;			# to avoid warnings
    if ($#NAME==0){foreach $itx(1..$#SEC){push(@NAME,"unk");}}
				# open file
    open("$fhout",">$fileOutLoc")  || 
	return(0,"*** $sbrName cannot open fileOutLoc=$fileOutLoc\n");
				# avoid warning
    $#NUM=0                     if (! defined @NUM);

				# ------------------------------
    if ($Levalsec){		# write PP2dotpred format 
	undef %rd;
	$rd{"des"}="";		# convert to global
	foreach $des(@des_evalsec){
	    $rd{"des"}.="$des"."  ";
	    if   ($des=~/AA/)  {foreach $it(1..$#SEQ){$rd{"$des","$it"}=$SEQ[$it];}}
	    elsif($des=~/PHEL/){foreach $it(1..$#SEC){$rd{"$des","$it"}=$SEC[$it];}}
	    elsif($des=~/OHEL/){foreach $it(1..$#OSEC){$rd{"$des","$it"}=$OSEC[$it];}}
	    elsif($des=~/NAME/){foreach $it(1..$#NAME){$rd{"$des","$it"}=$NAME[$it];} }}
	($Lok,$msg)=
	    &wrt_ppcol("$fhout",%rd); }
				# ------------------------------
    else {			# write DSSP file
	foreach $it (1..$#SEQ){
	    push(@NUM,$it);}	# convert to global
	$Lok=
	    &wrt_dssp_phd("$fhout",$nameFileIn);}
    close("$fhout");
				# ------------------------------
				# file existing??
    return(2,"*** $sbrName ERROR after write, missing fileOutLoc=$fileOutLoc\n")
	if (! -e $fileOutLoc);
				# ******************************
				# error: read/write col format
    return(2,"*** $sbrName internal error while writing fileOutLoc=$fileOutLoc\n")
	if (! $Lok);
				# ------------------------------
				# write guide sequence in FASTA
    if (! $Levalsec){
	if (defined $NAME[1]){$nameGuide=$NAME[1];}
	else {$nameGuide=$fileOutGuideLoc;$nameGuide=~s/^.*\/|\..*$//g;}
	$seqGuide="";foreach $tmp(@seq){$seqGuide.="$tmp";}
	$seqGuide=~s/[^ABCDEFGHIKLMNPQRSTVWXYZ]//g; # delete non amino acid characters!
	($Lok,$msg)=
	    &fastaWrt($fileOutGuideLoc,$nameGuide,$seqGuide);
	return(3,"*** $sbrName cannot write fasta of guide\n".
	       "*** fileout=$fileOutGuideLoc, id=$nameGuide, seq=$seqGuide\n".
	       "*** ERROR message: $msg\n") if (! $Lok || ! -e $fileOutGuideLoc);}
				# ------------------------------
    undef %rd; $#seqIn=0;	# save space
    $#SEQ=$#SEC=$#ACC=$#RISEC=$#RIACC=$#OSEC=$#NAME=0;
    $seqGuide="";		# save space

    return(1,"$sbrName ok");
}				# end of interpretSeqCol

#===============================================================================
sub interpretSeqFastalist {
    local ($fileOutLocGuide,$fileOutLocOther,$lenMinLoc,$fhErrSbr,@seqIn)=@_;
    local (@seq,$ct,$ctprot,$fhout_guide,$fhout_other,$sbrName,$name,@name,%seq,%name);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   interpretSeqFastalist       extracts the Fasta list input format
#       in:                     $fileOutLocGuide,$fileOutLocOther,$lenMinLoc,$fhErrSbr,@seqIn
#       out:                    writes 2 Fasta files for guide and to-be-aligned
#       err:                    a: (0,msg) -> some arguments missing/files not opened
#       err:                    b: (2,msg) -> wrong format 
#       err:                    c: (3,msg) -> too few alis 
#       err:                    d: (4,msg) -> seq too short
#       err:                    e: (1,msg) -> ok
#--------------------------------------------------------------------------------
    $sbrName="interpretSeqFastalist";
    return(0,"*** $sbrName: not def fileOutLocGuide!") if (! defined $fileOutLocGuide);
    return(0,"*** $sbrName: not def fileOutLocOther!") if (! defined $fileOutLocOther);
    return(0,"*** $sbrName: not def fhErrSbr!")        if (! defined $fhErrSbr);
    return(0,"*** $sbrName: not def lenMinLoc!")       if (! defined $lenMinLoc);
    return(0,"*** $sbrName: not def seqIn[1]!")        if (! defined $seqIn[1]);

    $fhout_guide="FILEFASTALIST_GUIDE";
    $fhout_other="FILEFASTALIST_OTHER";
    $ct=$#name=0; undef %seq; undef %name;
				# --------------------------------------------------
    while(@seqIn) {		# first: check format by correctness of first tag '>'
	$_ = shift @seqIn;
	next if ($_=~/^\#/);	# ignore second hash, br: 10-9-96
	next if ($_!~/^\s*\>/);	# search first '>' = guide sequence
	$_=~s/\n//g;
	$_=~s/^\s*\>\s*//g;$_=~s/\s*$//g; # purge blanks asf
	$_=~s/\s|\./_/g;	# blanks, dots to '_'
	$_=~s/^\_|\_$//g;	# purge off leading '_'
	$_=~s/^.*\|//g;		# purge all before first '|'
	$_=~s/,.*$//g;		# purge all after comma
	$name=substr($_,1,15);	# shorten
	$name=~s/__/_/g;	# '__' -> '_'
	$name=~s/,//g;		# purge comma
	last;}
    return(2,"*** $sbrName ERROR no tag '>' found\n") if (length($name)<2 || ! defined $name);

    $name{"$name"}=1;push(@name,$name);$seq{"$name"}=""; # for guide sequence
    $ctprot=0;			# --------------------------------------------------
    while(@seqIn) {		# now extract the guide sequence, and all others
	$_ = shift @seqIn;$_=~s/\n//g;
				# ------------------------------
	if ($_=~/^\s*\>/ ) {	# name
	    ++$ctprot;$ct=1;$#seq=0;
	    $_=~s/^\s*\>\s*//g;$_=~s/\s*$//g; # purge blanks asf
	    $_=~s/\s|\./_/g;	# blanks, dots to '_'
	    $_=~s/^\_|\_$//g;	# purge off leading '_'
	    $_=~s/^.*\|//g;	# purge all before first '|'
	    $_=~s/,.*$//g;	# purge all after comma
	    $name=substr($_,1,14); # shorten
	    $name=~s/__/_/g;	# '__' -> '_'
	    $name=~s/,//g;	# purge comma
	    if (defined $name{"$name"}){
		$ctTmp=1;$name=substr($name,1,13); # shorten further
		while(defined $name{"$name"."$ctTmp"}){
		    $name=substr($name,1,12) if ($ctTmp==9);
		    ++$ctTmp;}
		$name.=$ctTmp;}
	    $name{"$name"}=1;
	    $name.=$tmp."_$ctprot" if (length($name)<5);
	    $seq{"$name"}="";push(@name,$name);}
				# ------------------------------
	else {			# sequence
	    $_=~s/^[\d\s]*(.)/$1/g; # purge leading blanks/numbers
	    $_=~s/\s//g;	# purge all blanks
	    $_=~tr/a-z/A-Z/;	# upper case
	    if (! /[^ABCDEFGHIKLMNPQRSTVWXYZ]/) {
		$seq{"$name"}.=$_ . "\n";}}
    }				# end of loop over input array
				# --------------------------------------------------
				# print new file in FASTA format
				# ------------------------------
				# guide sequence in FASTA format
    open("$fhout_guide",">$fileOutLocGuide") ||
	return(0,"*** $sbrName cannot open new fileOutLocGuide=$fileOutLocGuide\n");
    print $fhout_guide ">$name[1]\n".$seq{"$name[1]"}."\n" ;
    close($fhout_guide);
				# ------------------------------
				# others in FASTA format (as list)
#********************************************************************************x.1
#   set to 1, 2 ... if you want to allow alignments with at least 2, 3, .. sequences
#********************************************************************************x.1
    if ( $#name < 1) {		# too few alis
	return(3,"*** ERROR $sbrName wrong format in seq to pir list (too few alis)!\n");}
    if ( length($seq{"$name[1]"}) <= $lenMinLoc) { # seq too short
	$len=length($seq{"$name[1]"});
	return(4,"*** ERROR $sbrName len=$len, i.e. too few residues in $name[1]!\n");}

    open("$fhout_other",">$fileOutLocOther") ||
	return(0,"*** ERROR $sbrName cannot open new fileOutLocOther=$fileOutLocOther\n");
    foreach $it (1..$#name){
	print $fhout_other ">$name[$it]\n",$seq{"$name[$it]"};
	print $fhout_other "\n" if ($seq{"$name[$it]"} !~/\n$/);}
    close($fhout_other);
    return(1,"$sbrName ok");
}				# end of interpretSeqFastalist

#===============================================================================
sub interpretSeqMsf {
    local ($fileOutLoc,$fileOutGuideLoc,$fhErrSbr,@seqIn) = @_ ;
    local ($sbrName,$Lok,$msg,$tmp,$fhout,$LfirstLine,$Lhead,
	   $Lguide,$seqGuide,$nameGuide);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   interpretSeqMsf             extracts the MSF input format
#       in:                     $fileOutLoc,$fileOutGuideLoc,$fhErrSbr,@seqIn
#       out:                    write alignment in MSF format and guide seq in FASTA
#       err:                    e: (1,msg) -> ok
#       err:                    a: (0,msg) -> some arguments missing/files not opened
#       err:                    b: (2,msg) -> chechMsfFormat returned ERROR
#       err:                    c: (3,msg) -> guide sequence not written
#--------------------------------------------------------------------------------
    $sbrName="interpretSeqMsf";
    return(0,"*** $sbrName: not def fileOutLoc!")      if (! defined $fileOutLoc);
    return(0,"*** $sbrName: not def fileOutGuideLoc!") if (! defined $fileOutGuideLoc);
    return(0,"*** $sbrName: not def fhErrSbr!")        if (! defined $fhErrSbr);
    return(0,"*** $sbrName: not def seqIn[1]!")        if (! defined $seqIn[1]);
				# open output files
    $fhout="FHOUT_".$sbrName;
    open("$fhout",">$fileOutLoc")  || 
	return(0,"*** $sbrName cannot open new fileOutLoc=$fileOutLoc\n");
    $Lhead=1;
    $LfirstLine=0;		# hack 2-98: add first line 'MSF of: xyz from: 1 to: 600'
    $Lguide=0;$seqGuide="";	# for extracting guide sequence

    $ctName=$LisAli=0;		# hack 98-05 to prevent only one protein
				# goebel= error if only one in MSF!!
				# ------------------------------
    foreach $_(@seqIn){		# write MSF
				# yet another hack around Goebel, 9-95, br
	next if ($_=~/^\#/);	# ignore second hash, br: 10-9-96
				# allow for 'PileUp' asf before first line
	if ($_=~/\s*MSF.*\:.*heck|\s*MSF\s*of\s*\:/){
	    $Lhead=0;}
	next if ($Lhead);	# skip all before line with 'MSF .*:'
	if    ($_=~/\sMSF\s*of\s*\:\s*.*from\s*\:\s*\d/){
	    $LfirstLine=1;}
	elsif (($_=~/\s+MSF\s*\:\s*(\d+).*[cC]heck\:/)&&! $LfirstLine){
	    $_="MSF of: yyy from: 1 to: $1\n".$_;}
	$tmp=$_;
	$tmp=~tr/[A-Z]/[a-z]/;	# and another (\t -> '  ') ; 3-96 br
	$tmp=~s/\t/   /g;	# tab to '   '
	if ($tmp=~ /name\:/){
	    $tmp=~s/name\:/Name\:/;$tmp=~s/len\:/Len\:/;$tmp=~s/check\:/Check\:/;
	    ++$ctName;		# hack 98-05
				# only to extract guide sequence
	    if (!$Lguide){$nameGuide=$tmp;$nameGuide=~s/\s*Name\:\s*(\S+)\s.*$/$1/g;
			  $Lguide=1;}
	    $nameRemember=$tmp;$nameRemember=~s/$nameGuide/117REPEAT/;
	    $_=$tmp;}
	$_=~s/[~-]/\./g;	# '~' and '-' to '.' for insertions
	last if ($_=~/^[^a-zA-Z0-9\.\*\_\- \n\b\\\/]/);
				# hack 98-05: if only one repeat!!
	if    ($_=~/\/\// && $ctName==1){ # now repeat name
	    print $fhout "$nameRemember\n";}
	elsif ($LisAli && $ctName==1){ # now repeat sequence part
	    $tmp2=$_;$tmp2=~s/$nameGuide/117REPEAT/i;
	    print $fhout "$tmp2\n";}
				# end hack 98-05: if only one repeat!!

	print $fhout "$_\n";  
	print $fhout " \n" if ($LisAli && $ctName==1); # hack 98-05 security additional column

	$LisAli=1 if ($_=~/\/\//); # for hack 98-05: if only one repeat!!

				# only to extract guide sequence
	next if (! $Lguide || $_=~/name|\/\//i || $_!~/^\s*$nameGuide/i);
	$_=~s/$nameGuide//ig;$_=~s/\s//g;$seqGuide.="$_";
    }
    print $fhout "\n";
    close("$fhout");
    $#seqIn=0;			# save space
				# ------------------------------
    return(0,"*** $sbrName ERROR after write, missing fileOutLoc=$fileOutLoc\n") 
	if (! -e $fileOutLoc);	# file existing??
				# ------------------------------
				# make a basic test of msf format
    ($Lok,$msg)=
	&msfCheckFormat($fileOutLoc);
    return(2,"$msg"."*** $sbrName ERROR from msfCheckFormat fileOutLoc=$fileOutLoc\n") 
	if (! $Lok);
				# ------------------------------
				# write guide sequence in FASTA
    $seqGuide=~s/[^ABCDEFGHIKLMNPQRSTVWXYZ]//g; # delete non amino acid characters!
    ($Lok,$msg)=
	&fastaWrt($fileOutGuideLoc,$nameGuide,$seqGuide);
    $seqGuide="";		# save space
    
    return(3,"*** $sbrName cannot write fasta of guide\n".
	   "*** fileout=$fileOutGuideLoc, id=$nameGuide, seq=$seqGuide\n".
	   "*** ERROR message: $msg\n") if (! $Lok || (! -e $fileOutGuideLoc));
    return(1,"$sbrName ok");
}				# end of interpretSeqMsf

#===============================================================================
sub interpretSeqPirlist {
    local ($fileOutLocGuide,$fileOutLocOther,$lenMinLoc,$fhErrSbr,@seqIn)=@_;
    local (@seq,$ct,$ctprot,$fhout_guide,$fhout_other,$sbrName,$name,@name,%seq,%name);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   interpretSeqPirlist         extracts the PIR list input format
#       in:                     $fileOutLocGuide,$fileOutLocOther,$lenMinLoc,$fhErrSbr,@seqIn
#       out:                    writes 2 PIR files for guide and to-be-aligned
#       err:                    a: (0,msg) -> some arguments missing/files not opened
#       err:                    b: (2,msg) -> wrong format 
#       err:                    c: (3,msg) -> too few alis 
#       err:                    d: (4,msg) -> seq too short
#       err:                    e: (1,msg) -> ok
#--------------------------------------------------------------------------------
    $sbrName="interpretSeqPirlist";
    return(0,"*** $sbrName: not def fileOutLocGuide!") if (! defined $fileOutLocGuide);
    return(0,"*** $sbrName: not def fileOutLocOther!") if (! defined $fileOutLocOther);
    return(0,"*** $sbrName: not def fhErrSbr!")        if (! defined $fhErrSbr);
    return(0,"*** $sbrName: not def lenMinLoc!")       if (! defined $lenMinLoc);
    return(0,"*** $sbrName: not def seqIn[1]!")        if (! defined $seqIn[1]);

    $fhout_guide="FILEPIRLIST_GUIDE";
    $fhout_other="FILEPIRLIST_OTHER";
    $ct=$#name=0; undef %seq; undef %name;
				# --------------------------------------------------
    while (@seqIn){		# first: check format by correctness of first tag 'P1;'
	$_ = shift @seqIn;
	next if ($_=~/^\#/);	# ignore second hash, br: 10-9-96
	$_=~s/\n//g;$_=~tr/a-z/A-Z/; # upper case
	return(2,"*** $sbrName ERROR first tag not '>P1\;' but ($_)\n") 
	    if ($_!~ /P.?\;/ ); # wrong format
	$_=~ s/\>.*P.*\;//;
	return(2,"*** $sbrName ERROR first tag not '>P1\;' but ($_)\n") 
	    if ($_=~/\S/ );	# wrong format
	last;}
    
    $ct=1;$ctprot=0;		# --------------------------------------------------
    while(@seqIn) {		# now extract the guide sequence, and all others
	$_ = shift @seqIn;$_=~s/\n//g;
	if ($_=~/\>.*P1.*\;|\>.*p1.*\;/ ) {
	    ++$ctprot;$ct=1; $#seq=0;
	    next;}
	++$ct;
	if  ($ct==2) {		# 2nd: name (1st = tag, ignored here)
	    $_=~s/\s+/_/g;	# replace spaces by '_'
	    $_=~s/^\_|\_$//g;	# purge off leading blanks
	    $tmp=substr($_,1,15); # extr first 15
	    $name="$tmp";
	    if (defined $name{"$name"}){
		$ctTmp=1;
		while(defined $name{"$name"."$ctTmp"}){
		    ++$ctTmp;}
		$name.=$ctTmp;}
	    $name{"$name"}=1;
	    if (length($name)<5){
		$name.=$tmp."_$ctprot"; }
	    $seq{"$name"}="";push(@name,$name);}
	elsif ($ct> 2){
	    $_=~s/^\s(.)/$1/g;
	    $_=~s/\s//g;	# purge blanks
	    $_=~tr/a-z/A-Z/;	# upper case
	    if (! /[^ABCDEFGHIKLMNPQRSTVWXYZ]/) {
		$seq{"$name"}.=$_ . "\n";} }
    }				# end of loop over input array
				# --------------------------------------------------
				# print new file in FASTA format
				# ------------------------------
				# guide sequence in FASTA format
    open("$fhout_guide",">$fileOutLocGuide") ||
	return(0,"*** $sbrName cannot open new fileOutLocGuide=$fileOutLocGuide\n");
    print $fhout_guide ">$name[1]\n".$seq{"$name[1]"}."\n" ;
    close($fhout_guide);
				# ------------------------------
				# others in FASTA format (as list)
#********************************************************************************x.1
#   set to 1, 2 ... if you want to allow alignments with at least 2, 3, .. sequences
#********************************************************************************x.1
    if ( $#name < 1) {		# too few alis
	return(3,"*** ERROR $sbrName wrong format in seq to pir list (too few alis)!\n");}
    if ( length($seq{"$name[1]"}) <= $lenMinLoc) { # seq too short
	$len=length($seq{"$name[1]"});
	return(4,"*** ERROR $sbrName len=$len, i.e. too few residues in $name[1]!\n");}

    open("$fhout_other",">$fileOutLocOther") ||
	return(0,"*** ERROR $sbrName cannot open new fileOutLocOther=$fileOutLocOther\n");
    foreach $it (1..$#name){
	print $fhout_other ">$name[$it]\n",$seq{"$name[$it]"};
	print $fhout_other "\n" if ($seq{"$name[$it]"} !~/\n$/);}
    close($fhout_other);
    return(1,"$sbrName ok");
}				# end of interpretSeqPirlist

#===============================================================================
sub interpretSeqPP {
    local($fileOutLoc,$nameLoc,$charPerLine,$lenMinLoc,$lenMaxLoc,$geneLoc,@seqIn) = @_ ;
    local($sbrName,$seq,$len,$ct);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   interpretSeqPP              suppose it is old PP format: write sequenc file
#       in:                     $fileOutLoc,$nameLoc,$charPerLine,
#       in:                     $lenMinLoc,$lenMaxLoc,$geneLoc,@seqIn
#       out:                    err:   0,msg
#       out:                    short: 2,msg
#       out:                    long:  3,msg
#       out:                    gene:  4,msg
#       out:                    ok:    1,ok
#-------------------------------------------------------------------------------
    $sbrName="interpretSeqPP";
    return(0,"*** $sbrName: not def fileOutLoc!")  if (! defined $fileOutLoc);
    return(0,"*** $sbrName: not def nameLoc!")     if (! defined $nameLoc);
    return(0,"*** $sbrName: not def lenMinLoc!")   if (! defined $lenMinLoc);
    return(0,"*** $sbrName: not def lenMaxLoc!")   if (! defined $lenMaxLoc);
    return(0,"*** $sbrName: not def geneLoc!")     if (! defined $geneLoc);
    return(0,"*** $sbrName: not def charPerLine!") if (! defined $charPerLine);
    return(0,"*** $sbrName: not def seqIn[1]!")    if (! defined $seqIn[1]) ;
				# ------------------------------
				# read sequence
    $seq="";$Lswiss=0;
    foreach $_ (@seqIn){
				# allow for SWISS-PROT files
	if ($_=~/^ID\s+[A-Z0-9]+_/){ # recognise SWISS-PROT by 'ID  PAHO_CHICK' in 1st line
	    $Lswiss=1;$Lread=0;
	    next;}
	elsif ($Lswiss && ($_=~/^SQ\s+/)){
	    $Lread=1;		# start reading after line 'SQ  SEQUENCE'
	    next;}
	next if ($Lswiss && (! $Lread));
				# ------------------------------
				# normal sequence now?
	$_=~ tr/a-z/A-Z/;	# lower case -> upper
	$_=~ s/^[\s\d]+//g;	# purge numbers and leading blanks
	$_=~ s/[\s]//g;		# purge off blanks *!*
	$_=~ s/[\.]//g;		# purge dots (may be insertions)
	$_=~ s/\*$|^\*//g;	# purge leading / ending star
	last if ( /[^ABCDEFGHIKLMNPQRSTVWXYZ]/ );
	$seq.= $_; }
    $len=length($seq);
				# ******************************
    if ($len < $lenMinLoc ) {	# exit : too short
	return(2,"*** $sbrName ERROR: too short  len=$len, min=$lenMinLoc");}
				# ******************************
    if ($len > $lenMaxLoc ) {	# exit : too long
	return(3,"*** $sbrName ERROR: too long   len=$len, min=$lenMaxLoc");}
				# ******************************
				# exit : gene sequence
    $tmp=$seq; $tmp=~ s/[^ACTG]//g;
    $tmp=100*(length($tmp)/length($seq));
    if ( $tmp > $geneLoc ) {
	return(4,"*** $sbrName ERROR: too ACGT   ratio=$tmp, maxGCGT=$geneLoc");}

				# ------------------------------
				# appears fine -> write file in pir
    $fhout="FHOUT_SEQ_PP";
    open("$fhout","> $fileOutLoc") ||
	return(0,"*** $sbrName cannot open fileOutLoc=$fileOutLoc\n");
    print $fhout ">prot (#) $nameLoc\n";
    for($ct=1; $ct<=length($seq); $ct+=$charPerLine){
	print $fhout substr($seq,$ct,$charPerLine), "\n"; 
    }
    close("$fhout");
    return(1,"$sbrName ok");
}				# end of interpretSeqPP

#===============================================================================
sub interpretSeqSaf {
    local ($fileOutLoc,$fileOutGuideLoc,$fhErrSbr,@safIn) = @_ ;
    local ($sbrName,$Lok,$msg,$tmp,$fhout,$fhout2,$LfirstLine,$Lhead,
	   $name,$seq,$nameFirst,$lenFirstBeforeThis,
	   %nameInBlock,$ctBlocks,$line,$Lguide,$seqGuide,$nameGuide);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   interpretSeqSaf             extracts the SAF input format
#       in:                     $fileOutLoc,$fileOutGuideLoc,$fhErrSbr output file (for MSF),
#       in:                     @safInLoc=lines read from file
#       out:                    write alignment in MSF format
#       in/out GLOBAL:          $safIn{"$name"}=seq, @nameLoc: names (first is guide)
#       err:                    e: (1,msg) -> ok
#       err:                    a: (0,msg) -> some arguments missing/files not opened
#       err:                    b: (2,msg) -> no output file written (msfWrt)
#       err:                    b: (3,msg) -> ERROR from msfCheckFormat
#       err:                    c: (3,msg) -> guide sequence not written
#   
#   specification of format
#   ------------------------------
#   EACH ROW
#   ------------
#   two columns: 1. name (protein identifier, shorter than 15 characters)
#                2. one-letter sequence (any number of characters)
#                   insertions: dots (.), or hyphens (-)
#   ------------
#   EACH BLOCK
#   ------------
#   rows:        1. row must be guide sequence (i.e. always the same name,
#                   this implies, in particular, that this sequence shold
#                   not have blanks
#                2, ..., n the aligned sequences
#
#   comments:    *  rows beginning with a '#' will be ignored
#                *  rows containing only blanks, dots, numbers will also be ignored
#                   (in particular numbering is possible)
#   
#   unspecified: *  order of sequences 2-n can differ between the blocks,
#                *  not all 2-n sequences have to occur in each block,
#                *  
#                *  BUT: whenever a sequence is present, it should have
#                *       dots for insertions rather than blanks
#                *  
#   ------------
#   NOTE
#   ------------
#                The 'freedom' of this format has various consequences:
#                *  identical names in different rows of the same block
#                   are not identified.  Instead, whenever this applies,
#                   the second, (third, ..) sequences are ignored.
#                   e.g.   
#                      t2_11751 EFQEDQENVN 
#                      name-1   ...EDQENvk
#                      name-1   GGAPTLPETL
#                   will be interpreted as:
#                      t2_11751 EFQEDQENVN 
#                      name-1   ...EDQENvk
#                   wheras:
#                      t2_11751 EFQEDQENVN 
#                      name-1   ...EDQENvk
#                      name_1   GGAPTLPETL
#                   has three different names.
#   ------------
#   EXAMPLE 1
#   ------------
#     t2_11751 EFQEDQENVN PEKAAPAQQP RTRAGLAVLR AGNSRGAGGA PTLPETLNVA
#     name_1   EFQEDQENVN PEKAAPAQQP RTRAGLAVLR AGNSRGAGGA PTLPETLNVA
#     name_2   ...EDQENvk PEKAAPAQQP RTRAGLAVLR AGNSRG.... ...PETLNV.
#     name_22  ...EDQENvk PEKAAPAQQP RTRAGLAVLR AGNSRG.... ...PETLNV.
#
#     t2_11751 GGAPTLPETL NVAGGAPTLP ETLNVAGGAP TLPETLNV
#     name_1   GGAPTLPETL NVAGGAPTLP ETLNVAGGAP TLPETLNV
#   
#   ------------
#   EXAMPLE 2
#   ------------
#                         10         20         30         40         
#     t2_11751 EFQEDQENVN PEKAAPAQQP RTRAGLAVLR AGNSRGAGGA PTLPETLNVA
#     name_1   EFQEDQENVN PEKAAPAQQP RTRAGLAVLR AGNSRGAGGA PTLPETLNVA
#     name_2   ...EDQENvk PEKAAPAQQP RTRAGLAVLR AGNSRG.... ...PETLNV.
#     name_22  ...EDQENvk PEKAAPAQQP RTRAGLAVLR AGNSRG.... ...PETLNV.
#
#              50         60         70         80         90
#
#     t2_11751 GGAPTLPETL NVAGGAPTLP ETLNVAGGAP TLPETLNV
#     name_22  .......... .......... .......... ........
#     name_1   GGAPTLPETL NVAGGAPTLP ETLNVAGGAP TLPETLNV
#     name_2   .......... NVAGGAPTLP 
#   
#--------------------------------------------------------------------------------
    $sbrName="interpretSeqSaf";
    return(0,"*** $sbrName: not def fileOutLoc!") if (! defined $fileOutLoc);
    return(0,"*** $sbrName: not def fileOutGuideLoc!") if (! defined $fileOutGuideLoc);
    return(0,"*** $sbrName: not def fhErrSbr!")   if (! defined $fhErrSbr);
    return(0,"*** $sbrName: not def safIn[1]!")   if (! defined $safIn[1]);
				# ------------------------------
				# extr blocks
    $#nameLoc=0;$ctBlocks=0;undef %safIn;
    foreach $_(@safIn){
	next if ($_=~/\#/);	# ignore comments
	last if ($_!~/\#/ && $_=~/^\s*[\-\_]+\s*$/); # stop when address
	$line=$_;
	$tmp=$_;$tmp=~s/[^A-Za-z]//g;
	next if (length($tmp)<1); # ignore lines with numbers, blanks, points only
	$line=~s/^\s*|\s*$//g;	# purge leading blanks
	$name=$line;$name=~s/^\s*([^\s\t]+)\s+.*$/$1/;
	$name=substr($name,1,14); # maximal length: 14 characters (because of MSF2Hssp)
#	$seq=$line;$seq=~s/^\s*//;$seq=~s/^$name//;$seq=~s/\s//g;
	$seq=$line;$seq=~s/^\s*//;$seq=~s/^[^\s\t]+//;$seq=~s/\s//g;
# 	next if ($seq =~/^ACDEFGHIKLMNPQRSTVWXYZ/i);  # check this!!
#	print "--- interpretSeqSaf: name=$name, seq=$seq,\n";
	$nameFirst=$name if ($#nameLoc==0);	# detect first name
	if ($name eq "$nameFirst"){ # count blocks
	    ++$ctBlocks; undef %nameInBlock;
	    if ($ctBlocks==1){$lenFirstBeforeThis=0;}
	    else{$lenFirstBeforeThis=length($safIn{"$nameFirst"});}
	    &interpretSeqSafFillUp if ($ctBlocks>1);} # manage proteins that did not appear
	next if (defined $nameInBlock{"$name"}); # avoid identical names
	if (! defined ($safIn{"$name"})){
	    push(@nameLoc,$name);
#	    print "--- interpretSeqSaf: new name=$name,\n";
	    if ($ctBlocks>1){	# fill up with dots
#		print "--- interpretSeqSaf: file up for $name, with :$lenFirstBeforeThis\n";
		$safIn{"$name"}="." x $lenFirstBeforeThis;}
	    else{
		$safIn{"$name"}="";}}
	$seq=~s/[^A-Za-z]/\./g; # any non-character to dot
	$seq=~tr/[a-z]/[A-Z]/;
	$safIn{"$name"}.=$seq;
	$nameInBlock{"$name"}=1; # avoid identical names
    } 
    &interpretSeqSafFillUp;	# fill up ends
				# store names for passing variables
    foreach $it (1..$#nameLoc){
	$safIn{"$it"}=$nameLoc[$it];}
    $safIn{"NROWS"}=$#nameLoc;

    $safIn{"FROM"}="PP_"."$nameLoc[1]";
    $safIn{"TO"}=$fileOutLoc;
				# ------------------------------
				# write an MSF formatted file
    $fhout="FHOUT_MSF_FROM_SAF";
    open("$fhout",">$fileOutLoc")  || # open file
	return(0,"*** $sbrName cannot open fileOutLoc=$fileOutLoc\n");
    $Lok=
	&msfWrt("$fhout",%safIn); # write the file
    close("$fhout");
				# ------------------------------
				# file existing??
    return(2,"*** $sbrName ERROR after write, missing fileOutLoc=$fileOutLoc\n") 
	if (! -e $fileOutLoc);
				# ------------------------------
				# make a basic test of msf format
    ($Lok,$msg)=
	&msfCheckFormat($fileOutLoc);
    return(3,"$msg"."*** $sbrName ERROR from msfCheckFormat fileOutLoc=$fileOutLoc\n")
	if (! $Lok);
				# ------------------------------
				# write guide sequence in FASTA
    if (defined $nameLoc[1]){$nameGuide=$nameLoc[1];}
    else {$nameGuide=$fileOutGuideLoc;$nameGuide=~s/^.*\/|\..*$//g;}
    $seqGuide=$safIn{"$nameGuide"};
    $seqGuide=~s/[^ABCDEFGHIKLMNPQRSTVWXYZ]//g; # delete non amino acid characters!
    ($Lok,$msg)=
	&fastaWrt($fileOutGuideLoc,$nameGuide,$seqGuide);
    return(4,"*** $sbrName cannot write fasta of guide\n".
	   "*** fileout=$fileOutGuideLoc, id=$nameGuide, seq=$seqGuide\n".
	   "*** ERROR message: $msg\n") if (! $Lok || ! -e $fileOutGuideLoc);
				# ------------------------------
    $#safIn=$#nameLoc=0;			# save space
    undef %safIn; undef %nameInBlock;
    
    return(1,"$sbrName ok");
}				# end of interpretSeqSaf

#===============================================================================
sub interpretSeqSafFillUp {
    local($tmpName,$lenLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   interpretSeqSafFillUp       fill up with dots if sequences shorter than guide
#     all GLOBAL
#       in GLOBAL:              $safIn{"$name"}=seq
#                               @nameLoc: names (first is guide)
#       out GLOBAL:             $safIn{"$name"}
#-------------------------------------------------------------------------------
    foreach $tmpName(@nameLoc){
	if ($tmpName eq "$nameLoc[1]"){ # guide sequence
	    $lenLoc=length($safIn{"$tmpName"});
	    next;}
	$safIn{"$tmpName"}.="." x ($lenLoc-length($safIn{"$tmpName"}));
    }
}				# end of interpretSeqSafFillUp

#===============================================================================
sub msfBlowUp {
    local($fileInLoc,$fileOutLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   msfBlowUp                   duplicates guide sequence for conversion to HSSP
#       in:                     $fileInLoc,$fileOutLoc
#       out:                    1|0, msg, 
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."msfBlowUp";
    $fhinLoc="FHIN_"."msfBlowUp";$fhoutLoc="FHOUT_"."msfBlowUp";
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc!")          if (! defined $fileInLoc);
    return(0,"*** $sbrName: not def fileOutLoc!")         if (! defined $fileOutLoc);

    return(0,"*** $sbrName: miss in file '$fileInLoc'!")  if (! -e $fileInLoc);

    ($Lok,$msg,%msfIn)=&msfRd($fileInLoc);
    return(0,"*** ERROR $sbrName: msfRd \n".$msg."\n") if (! $Lok);
    
    &open_file("$fhoutLoc",">$fileOutLoc") ||
	return(0,"*** ERROR $sbrName: fileNew=$fileOutLoc, not opened\n");

    $name=$msfIn{"id","1"};
    $namex=substr($name,1,(length($name)-1))."x";
    $tmp{"1"}=$name;
    $tmp{"2"}=$namex;
    $tmp{$name}=    $msfIn{"seq","1"};
    $tmp{$namex}=   $msfIn{"seq","1"};
    $tmp{"NROWS"}=  2;
    $tmp{"FROM"}=   $fileInLoc;
    $tmp{"TO"}=     $fileOutLoc;
    undef %msfIn;		# save memory
				# write msf
    open ("$fhoutLoc",">$fileOutLoc") ||
        return(0,"*** ERROR $sbrName: failed opening new '$fileOutLoc'\n") ;
    ($Lok,$msg)=&msfWrt($fhoutLoc,%tmp);close($fhoutLoc);

    return(0,"*** ERROR $sbrName: failed to write $fileOutLoc, \n".$msg."\n") 
	if (! $Lok || ! -e $fileOutLoc);
    return(1,"ok $sbrName");
}				# end of msfBlowUp

#===============================================================================
sub msfCheckFormat {
    local ($fileMsf) = @_;
    local ($format,$tmp,$kw_msf,$kw_check,$ali_sec,$ali_des_sec,$valid_id_len,$fhLoc,
	   $uniq_id, $same_nb, $same_len, $nb_al, $seq_tmp, $seql, $ali_des_len);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   msfCheckFormat              basic checking of msf file format
#           - mandatory keywords and values (MSF: val, Check: val)
#           - alignment description start after "..", each line with the following structure:
#             Name: id Len: val Check: val Weight: val (and all ids diferents)
#           - alignment same number of line for each id (>0)
#       in:                     $fileMsf
#       out:                    return 1  if format seems OK, 0 else
#--------------------------------------------------------------------------------
    $sbrNameLoc="msfCheckFormat";
                                # ----------------------------------------
                                # initialise the flags
                                # ----------------------------------------
    $fhLoc="FHIN_CHECK_MSF_FORMAT";
    $kw_msf=$kw_check=$ali_sec=$ali_des_sec=$ali_des_seq=$nb_al=0;
    $format=1;
    $valid_id_len=1;		# sequence name < 15 characters
    $uniq_id=1;			# id must be unique
    $same_len=1;		# each seq must have the same len
    $lenok=1;			# length in header and of sequence differ
                                # ----------------------------------------
                                # read the file
                                # ----------------------------------------
    open ($fhLoc,$fileMsf)  || 
	return(0,"*** $sbrNameLoc cannot open fileMsf=$fileMsf\n");
    while (<$fhLoc>) {
	$_=~s/\n//g;
	$tmp=$_;$tmp=~ tr/a-z/A-Z/;
                                # MSF keyword and value
	$kw_msf=1    if (!$ali_des_seq && ($tmp =~ /MSF:\s*\d*\s/));
	next if (!$kw_msf);
                         	# CHECK keyword and value
	$kw_check=1  if (!$ali_des_seq && ($tmp =~ /CHECK:\s*\d*/));
	next if (!$kw_check);
                         	# begin of the alignment description section 
                         	# the line with MSF and CHECK must end with ".."
	if (!$ali_sec && $tmp =~ /MSF:\D*(\d*).*CHECK:.*\.\.\s*$/) {
	    $ali_des_len=$1;$ali_des_sec=1;}
                                # ------------------------------
                         	# the alignment description section
	if (!$ali_sec && $ali_des_sec) { 
            if ($tmp=~ /^\s*NAME:\s*(\S*).*LEN:.*\d.*CHECK:.*\d.*WEIGHT:.*\d.*/) {
		$id=$1;
		$valid_id_len=0 if (length($id) > 14);	# is sequence name <= 14
		if ($SEQID{$id}) { # is the sequence unique?
		    $uniq_id=0; $ali_sec=1;
		    last; }
		$lenRd=$tmp;$lenRd=~s/^.*LEN\:\s*(\d+)\s*CHEC.*$/$1/;
		$SEQID{$id}=1; # store seq ID
		$SEQL{$id}= 0;	# initialise seq len array
	    } }
                                # ------------------------------
                        	# begin of the alignment section
	$ali_sec=1    if ($ali_des_sec && $tmp =~ /\/\/\s*$/);
                                # ------------------------------
                        	# the alignment section
	if ($ali_sec) {
	    if ($tmp =~ /^\s*(\S+)\s+(.*)$/) {
		$id= $1;
		if ($SEQID{$id}) {++$SEQID{$id};
				  $seq_tmp= $2;$seq_tmp=~ s/\s|\n//g;
				  $SEQL{$id}+= length($seq_tmp);}}}
    }close($fhLoc);
                                # ----------------------------------------
                                # test if all sequences are present the 
				# same number of time with the same length
                                # ----------------------------------------
    if ($kw_msf && $kw_check && $ali_des_sec && $uniq_id && $valid_id_len){
	foreach $id (keys %SEQID) {
	    $nb_al= $SEQID{$id} if (!$nb_al);
	    if ($SEQID{$id} < 2 || $SEQID{$id} != $nb_al) {
		$same_len=0;
		last; }
	    if ($SEQL{$id} != $lenRd){
		$lenok=0;
		last;}}}
				# TEST ALL THE FLAGS
    $msg="";
    $msg.="*** $sbrNameLoc wrong MSF: no keyword MSF!\n"               if (!$kw_msf);
    $msg.="*** $sbrNameLoc wrong MSF: no keyword Check!\n"             if (!$kw_check);
    $msg.="*** $sbrNameLoc wrong MSF: no ali descr section!\n"         if (!$ali_des_sec);
    $msg.="*** $sbrNameLoc wrong MSF: no ali section!\n"               if (!$ali_sec); 
    $msg.="*** $sbrNameLoc wrong MSF: id not unique!\n"                if (!$uniq_id); 
    $msg.="*** $sbrNameLoc wrong MSF: seq name too long!\n"            if (!$valid_id_len);
    $msg.="*** $sbrNameLoc wrong MSF: varying length of seq!\n"        if (!$same_len);
    $msg.="*** $sbrNameLoc wrong MSF: length given and real differ!\n" if (!$lenok);
    return(0,$msg) if (length($msg)>1);
    return(1,"$sbrNameLoc ok");
}				# end msfCheckFormat


#===============================================================================
sub msfCountNali {
    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   msfCountNali                counts the number of alignments in MSF file
#       in:                     file
#       out:                    $nali,$msg if error
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."msfCountNali";$fhinLoc="FHIN_"."msfCountNali";
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc!")          if (! defined $fileInLoc);
    return(0,"*** $sbrName: miss in file '$fileInLoc'!")  if (! -e $fileInLoc);

    &open_file("$fhinLoc","$fileInLoc") ||
	return(0,"*** ERROR $sbrName: fileIn=$fileInLoc, not opened\n");

    $ct=0;                      # ------------------------------
    while (<$fhinLoc>) {        # read MSF
        ++$ct if ($_=~ /^\s*NAME:\s*(\S*).*LEN:.*\d.*CHECK:.*\d.*WEIGHT:.*\d.*/i);
        last if ($_=~/^\s*\//);
        next;} close($fhinLoc);
    return($ct);
}				# end of msfCountNali

#===============================================================================
sub msfRd {
    local ($fileInLoc) = @_ ;
    local ($sbrName,$Lok,$msg,$tmp,$fhout,$LfirstLine,$Lhead,
	   $Lguide,$seqGuide,$nameGuide);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   msfRd                       reads MSF files input format
#       in:                     $fileInLoc
#       out:                    ($Lok,$msg,$msfIn{}) with:
#       out:                    $msfIn{"NROWS"}  number of alignments
#       out:                    $msfIn{"id", "$it"} name for $it
#       out:                    $msfIn{"seq","$it"} sequence for $it
#       err:                    ok-> 1,ok | error -> 0,message
#-------------------------------------------------------------------------------
    $sbrName="lib-br:msfRd"; $fhinLoc="FHIN_"."msfRd";
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc!")          if (! defined $fileInLoc);
    return(0,"*** $sbrName: miss in file '$fileInLoc'!")  if (! -e $fileInLoc);

    &open_file("$fhinLoc","$fileInLoc") ||
	return(0,"*** ERROR $sbrName: fileIn=$fileInLoc, not opened\n");

    undef %msfIn;               # ------------------------------
    while (<$fhinLoc>) {	# read file
        last if ($_=~/^\s*\//); # skip everything before ali sections
    } undef %tmp;$ct=0;
    while (<$fhinLoc>) {	# read file
	$_=~s/\n//g;
        $_=~s/^\s*|\s*$//g;     # purge leading blanks
        $tmp=$_;$tmp=~s/\d//g;
        next if (length($tmp)<1); # skip lines empty or with numbers, only
                                # --------------------
				# from here on: 'id sequence'
        $id= $_; $id =~s/^\s*(\S+)\s*.*$/$1/;
        $seq=$_; $seq=~s/^\s*(\S+)\s+(\S.*)$/$2/;
        $seq=~s/\s//g;
        if (! defined $tmp{$id}){ # new
            ++$ct;$tmp{$id}=$ct;
            $msfIn{"id","$ct"}= $id;
            $msfIn{"seq","$ct"}=$seq;}
        else {
            $ptr=$tmp{$id};
            $msfIn{"seq","$ptr"}.=$seq;}}close($fhinLoc);

    $msfIn{"NROWS"}=$ct;
    return(1,"ok $sbrName",%msfIn);
}				# end of msfRd

#===============================================================================
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
#                               $input{"$it"}    sequence identifier ($name)
#                               $input{"$name"}  sequence for $name
#--------------------------------------------------------------------------------
    $sbrName="msfWrt";
				# ------------------------------
    $#nameLoc=$#tmp=0;		# process input
    foreach $it (1..$input{"NROWS"}){
	$name=$input{"$it"};
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
		return(0);}
    undef %name; $Lerr=$#name=0;
				# ------------------------------
    while (<$fhinLoc>) {	# read header
	$_=~s/\n//g;
				# read names in header
	if ($_=~/^\s*name\:\s*(\S+)/i){
	    $name{$1}=1;push(@name,$1);
				# ******************************
	    if (length($1)>=15){ # current GOEBEL limit!!!
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

#===============================================================================
sub pirRdSeq {
    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc,$msg,$Lok,$seq,$id);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   pirRdSeq                    reads the sequence from a PIR file
#       in:                     file
#       out:                    (1,name,sequence in one string)
#       err:                    ok=(1,'ok'), err=(0,'msg')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:pirRdSeq";$fhinLoc="FHIN"."$sbrName";

    $Lok=       &open_file("$fhinLoc","$fileInLoc");
    if (! $Lok){$msg="*** ERROR $sbrName: '$fileInLoc' not opened\n";
		return(0,$msg,"error");}
    $seq=$id="";$ct=0;
    while (<$fhinLoc>) {$_=~s/\n//g;++$ct;
			if   ($ct==1){
			    $id=$_;$id=~s/^\s*\>\s*P1\s*\;\s*(\S+)[\s\n]*.*$/$1/g;}
			elsif($ct==2){$id.=", $_";}
			else {$_=~s/[\s\*]//g;
			      $seq.="$_";}}close($fhinLoc);
    $seq=~s/\s//g;$seq=~s/\*$//g;
    return(1,$id,$seq);
}				# end of pirRdSeq

#===============================================================================
sub pirRdMul {
    local($fileInLoc,$extr) = @_ ;
    local($sbrName,$fhinLoc,$msg,$Lok,$seq,$id);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   pirRdMul                    reads the sequence from a PIR file
#       in:                     file,$extr with:
#                               $extr = '1,5,6',   i.e. list of numbers to read
#       out:                    1|0,$id,$seq (note: many ids/seq separated by '\n'
#       err:                    ok=(1,'ok'), err=(0,'msg')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:pirRdMul";$fhinLoc="FHIN_"."$sbrName";

    &open_file("$fhinLoc","$fileInLoc") ||
        return(0,"*** ERROR $sbrName: fileIn=$fileInLoc not opened\n");

    $extr=~s/\s//g  if (defined $extr);
    $extr=0         if (! defined $extr || $extr =~ /[^0-9\,]/);
    if ($extr){@tmp=split(/,/,$extr); undef %tmp;
	       foreach $tmp(@tmp){
		   $tmp{$tmp}=1;}}

    $ct=$ctRd=$ctProt=0;        # ------------------------------
    while (<$fhinLoc>) {        # read the file
	$_=~s/\n//g;
	if ($_ =~ /^\s*>/){	# (1) = id (>P1;)
            $Lread=0;
	    ++$ctProt;
	    $id=$_;$id=~s/^\s*>\s*P1?\s*\;\s*//g;$id=~s/(\S+)[\s\n]*.*$/$1/g;$id=~s/^\s*|\s*$//g;
	    $id.="_";

	    $id.=<$fhinLoc>;	# (2) still id in second line
	    $id=~s/[\s\t]+/ /g;
	    $id=~s/_\s*$/g/;
	    $id=~s/^[\s\t]*|[\s\t]*$//g;
            if (! $extr || ($extr && defined $tmp{$ctProt} && $tmp{$ctProt})){
                ++$ctRd;$Lread=1;
		$tmp{"$ctRd","id"}=$id;
		$tmp{"$ctRd","seq"}="";}}
        elsif($Lread){		# (3+) sequence
            $_=~s/[\s\*]//g;
            $tmp{"$ctRd","seq"}.="$_";}}close($fhinLoc);
                                # ------------------------------
    $seq=$id="";		# join to long strings
    if ($ctRd > 1) {
	foreach $it(1..$ctRd){
	    $id.= $tmp{"$it","id"}."\n";
	    $tmp{"$it","seq"}=~s/\s//g;$tmp{"$it","seq"}=~s/\*$//g;
	    $seq.=$tmp{"$it","seq"}."\n";} }
    else { $it=1;
	   $id= $tmp{"$it","id"};
	   $tmp{"$it","seq"}=~s/\s//g;$tmp{"$it","seq"}=~s/\*$//g;
	   $seq=$tmp{"$it","seq"}; }
	
    $#tmp=0;undef %tmp;		# save memory
    return(0,"*** ERROR $sbrName: file=$fileInLoc, nali=$ct, wanted: (rd=$rd)\n"," ") 
        if (length($seq)<1);
    return(1,$id,$seq);
}				# end of pirRdMul

#===============================================================================
sub pirWrtMul {
    local($fileOutLoc,%tmp) = @_ ;
    local($sbrName,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   pirWrtMul                   writes a list of sequences in PIR format
#       in:                     $fileOut,$tmp{} with:
#       in:                     $tmp{"NROWS"}      number of sequences
#       in:                     $tmp{"id","$ct"}   id for sequence $ct
#       in:                     $tmp{"seq","$ct"}  seq for sequence $ct
#       out:                    file
#       err:                    err  -> 0,message
#       err:                    ok   -> 1,ok
#       err:                    warn -> 2,not enough written
#-------------------------------------------------------------------------------
    $sbrName="lib-br:pirWrtMul";$fhoutLoc="FHOUT_"."$sbrName";

    return(0,"*** ERROR $sbrName: no tmp{NROWS} defined\n") if (! defined $tmp{"NROWS"});
    &open_file("$fhoutLoc",">$fileOutLoc") ||
        return(0,"*** ERROR $sbrName: '$fileOutLoc' not opened for write\n");

    $ctOk=0;
    foreach $itPair (1..$tmp{"NROWS"}){
        next if (! defined $tmp{"id","$itPair"} || ! defined $tmp{"seq","$itPair"});
        ++$ctOk;
                                # some massage
        $tmp{"id","$itPair"}=~s/[\s\t\n]+/ /g;
        $tmp{"seq","$itPair"}=~s/[\s\t\n]+//g;
                                # write
        print $fhoutLoc ">P1\; ",$tmp{"id","$itPair"},"\n";
        print $fhoutLoc $tmp{"id","$itPair"},"\n";
        $tmp{"seq","$itPair"}.="*";
	$lenHere=length($tmp{"seq","$itPair"});
        for($it=1; $it<=$lenHere; $it+=50){
	    $tmpWrt=      "";
            foreach $it2 (0..4){
		$itHere=($it + 10*$it2);
                last if ( $itHere >= $lenHere);
		$nchunk=10; 
		$nchunk=1+($lenHere-$itHere)  if ( (10 + $itHere) > $lenHere);
		$tmpWrt.= sprintf(" %-10s",substr($tmp{"seq","$itPair"},$itHere,$nchunk)); 
	    }
	    print $fhoutLoc $tmpWrt,"\n";
	}
    }
    close($fhoutLoc);
    return(0,"*** ERROR $sbrName: no sequence written\n")               
	if (! $ctOk);
    return(2,"-*- WARN $sbrName: wrote fewere sequences than expected\n") 
	if ($ctOk!=$tmp{"NROWS"});
    return(1,"ok $sbrName");
}				# end of pirWrtMul

#===============================================================================
sub read_dssp_seqsecacc {
    local ($fh_in, $chain_in, $beg_in, $end_in ) = @_ ;
    local ($Lread, $sbrName);
    local ($tmpchain, $tmpseq, $tmpsecstr, $tmpexp, $tmppospdb, $tmpseq2, $tmpsecstr2);
    $[=1;
#----------------------------------------------------------------------
#   read_dssp_seqsecacc         reads seq, secondary str and acc from DSSP file
#                               (file expected to be open handle = $fh_in).  
#                               The reading is restricted by:
#                                  chain_in, beg_in, end_in, 
#                               which are passed in the following manner:
#                               (say chain = A, begin = 2 (PDB pos), end = 10 (PDB pos):
#                                  "A 2 10"
#                               Wild cards allowed for any of the three.
#       in:                     file_handle, chain, begin, end
#       out:                    SEQDSSP, SECDSSP, ACCDSSP, PDBPOS
#       in / out GLOBAL:        all output stuff is assumed to be global
#----------------------------------------------------------------------
    $sbrName = "read_dssp_seqsecacc" ;

#----------------------------------------
#   setting to zero
#----------------------------------------
    $#SEQDSSP=0; $#SECDSSP=0; $#ACCDSSP=0; $#PDBPOS=0; 

#----------------------------------------
#   extract input
#----------------------------------------
    if ( length($chain_in) == 0 ) { $chain_in = "*" ; }
    else { $chain_in =~tr/[a-z]/[A-Z]/; }

    if ( length($beg_in) == 0 )   { $beg_in = "*" ; }
    if ( length($end_in) == 0 )   { $end_in = "*" ; }
    $fh_in=~s/\s//g; $chain_in=~s/\s//g; $beg_in=~s/\s//g; $end_in=~s/\s//g; 

#--------------------------------------------------
#   read in file
#--------------------------------------------------

#----------------------------------------
#   skip anything before data...
#----------------------------------------
    while ( <$fh_in> ) { last if ( /^  \#  RESIDUE/ ); }
 
#----------------------------------------
#   read sequence
#----------------------------------------
    while ( <$fh_in> ) {
	$Lread=1;
	$tmpchain = substr($_,12,1); 
	$tmppospdb= substr($_,7,5); $tmppospdb=~s/\s//g;

#     check chain
	if ( ($tmpchain ne "$chain_in") && ($chain_in ne "*") ) { $Lread=0; }
#     check begin
	if ( $beg_in ne "*" ) {
	    if ( $tmppospdb < $beg_in ) { $Lread=0; } }
#     check end
	if ( $end_in ne "*" ) {
	    if ( $tmppospdb > $end_in ) { $Lread=0; } }

	if ($Lread) {
	    $tmpseq    = substr($_,14,1);
	    $tmpsecstr = substr($_,17,1);
	    $tmpexp    = substr($_,36,3);

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
	    push(@SEQDSSP,$tmpseq); push(@SECDSSP,$tmpsecstr2); push(@ACCDSSP,$tmpexp);
	    push(@PDBPOS,$tmppospdb); }}
}                               # end of: read_dssp_seqsecacc 

#===============================================================================
sub read_fssp {
    local ($fileInLoc, $Lreversed) = @_ ;
    local ($Lexit, $tmp, $nalign, $it, $it2, $aain, $Lprint);
   $[=1;
#--------------------------------------------------
#   read_fssp                   reads the aligned fragment ranges from fssp files
#       in /out GLOBAL:         @ID1/2, POSBEG1/2, POSEND1/2, SEQBEG1/2, SEQEND1/2
#--------------------------------------------------
    if (length($Lreversed)==0) { $Lreversed=1;}
    &open_file("FILE_FSSP", "$fileInLoc");
#   ----------------------------------------
#   skip everything before "## FRAGMENTS"
#   plus: read NALIGN
#   ----------------------------------------
    $Lexit=0;
    while ( <FILE_FSSP> ) {
	if ( /^NALIGN/ ) {$tmp=$_; $tmp=~s/\n|NALIGN|\s//g;
			  $nalign=$tmp;}
	if ($Lexit) { last if (/^  NR/); }
	if (/^\#\# FRAGMENTS/) { $Lexit=1; } }

#   ----------------------------------------
#   read in fragment ranges
#   ----------------------------------------
    $it=0;
    while ( <FILE_FSSP> ) {
	$Lprint =0;
	$tmp=substr($_,1,4); $tmp=~s/\s//g; 
	if ( (($_=~/REVERSED/)||($_=~/PERMUTED/)) && $Lreversed && ($tmp<=$nalign) ) { $Lprint = 1; }
	elsif ( ($_!~/REVERSED/) && ($_!~/PERMUTED/) && ($tmp<=$nalign) ) { $Lprint = 1; }
	
	if ( $Lprint ) {
#           ------------------------------
#           new pair?
#           ------------------------------
	    if ($tmp != $it) { 
		$it=$tmp;
		$SEQBEG1[$it]=""; $SEQEND1[$it]=""; $SEQBEG2[$it]=""; $SEQEND2[$it]=""; 
		$POSBEG1[$it]=""; $POSEND1[$it]=""; $POSBEG2[$it]=""; $POSEND2[$it]=""; 
#               ------------------------------
#               extract IDs and ranges
#               ------------------------------
		$ID1[$it]=substr($_,7,6);$ID1[$it]=~s/\s//g;$ID1[$it]=~s/(\w\w\w\w)-(\w)/$1_$2/;
		$ID2[$it]=substr($_,14,6);$ID2[$it]=~s/\s//g;$ID2[$it]=~s/(\w\w\w\w)-(\w)/$1_$2/;
	    }

	    $tmp=$_;$tmp=~s/.*:\s*(.*)\s*\n/$1/; $tmp=~s/  / /g;$tmp=~s/    +//g;

#           ------------------------------
#           extract 1st and last residues
#           ------------------------------
#                                  ---------------------
#                                  convert 3 letter to 1
	    $aain=substr($_,25,3); &aa3lett_to_1lett($aain); 
	    $SEQBEG1[$it].="$aa3lett_to_1lett".",";
	    $aain=substr($_,42,3); &aa3lett_to_1lett($aain); 
	    $SEQEND1[$it].="$aa3lett_to_1lett".",";
	    $aain=substr($_,62,3); &aa3lett_to_1lett($aain); 
	    $SEQBEG2[$it].="$aa3lett_to_1lett".",";
	    $aain=substr($_,79,3); &aa3lett_to_1lett($aain); 
	    $SEQEND2[$it].="$aa3lett_to_1lett".",";

#           ------------------------------
#           extract ranges
#           ------------------------------
	    $tmp=substr($_,30,4); $tmp=~s/\s//g; $POSBEG1[$it].="$tmp".",";
	    $tmp=substr($_,47,4); $tmp=~s/\s//g; $POSEND1[$it].="$tmp".",";
	    $tmp=substr($_,67,4); $tmp=~s/\s//g; $POSBEG2[$it].="$tmp".",";
	    $tmp=substr($_,84,4); $tmp=~s/\s//g; $POSEND2[$it].="$tmp".",";
	} else {
	    $tmp=$_;$tmp=~s/.*:\s*(.*)\s*\n/$1/; $tmp=~s/  / /g;$tmp=~s/    +//g;
	}

    }
    close(FILE_FSSP);
}				# end of read_fssp

#===============================================================================
sub safRd {
    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   safRd                       reads SAF format
#       in:                     $fileOutLoc,
#       out:                    ($Lok,$msg,$tmp{}) with:
#       out:                    $tmp{"NROWS"}  number of alignments
#       out:                    $tmp{"id", "$it"} name for $it
#       out:                    $tmp{"seq","$it"} sequence for $it
#       err:                    ok-> 1,ok | error -> 0,message
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."safRd";$fhinLoc="FHIN_"."safRd";
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc!")          if (! defined $fileInLoc);
    return(0,"*** $sbrName: miss in file '$fileInLoc'!")  if (! -e $fileInLoc);

    $LverbLoc=0;

    &open_file("$fhinLoc","$fileInLoc") ||
	return(0,"*** ERROR $sbrName: fileIn=$fileInLoc, not opened\n");

    $ctBlocks=$ctRd=$#nameLoc=0;  undef %nameInBlock; 
    undef %tmp;			# --------------------------------------------------
				# read file
    while (<$fhinLoc>) {	# --------------------------------------------------
	$_=~s/\n//g;
	next if ($_=~/\#/);	# ignore comments
	last if ($_!~/\#/ && $_=~/^\s*[\-\_]+\s*$/); # stop when address
	$line=$_;
				# ignore lines with numbers, blanks, points only
	$tmp=$_; $tmp=~s/[^A-Za-z]//g;
	next if (length($tmp)<1);

	$line=~s/^\s*|\s*$//g;	# purge leading blanks
				# ------------------------------
				# names
	$name=$line; $name=~s/^([^\s\t]+)[\s\t]+.*$/$1/;
				# maximal length: 14 characters (because of MSF2Hssp)
	$name=substr($name,1,14);
				# ------------------------------
				# sequences
	$seq=$line;$seq=~s/^\s*//;$seq=~s/^[^\s\t]+//;$seq=~s/\s//g;
# 	next if ($seq =~/^ACDEFGHIKLMNPQRSTVWXYZ/i);  # check this!!
	print "--- $sbrName: name=$name, seq=$seq,\n" if ($LverbLoc);
				# ------------------------------
				# guide sequence: determine length
				# NOTE: no 'left-outs' allowed here
				# ------------------------------
	$nameFirst=$name        if ($#nameLoc==0);	# detect first name
	if ($name eq "$nameFirst"){
	    ++$ctBlocks;	# count blocks
	    undef %nameInBlock;
	    if ($ctBlocks == 1){
		$lenFirstBeforeThis=0;}
	    else {
		$lenFirstBeforeThis=length($tmp{"seq","1"});}

	    if ($ctBlocks>1) {	# manage proteins that did not appear
		$lenLoc=length($tmp{"seq","1"});
		foreach $itTmp (1..$#nameLoc){
		    $tmp{"seq","$itTmp"}.="." x ($lenLoc-length($tmp{"seq","$itTmp"}));}
	    }}
				# ------------------------------
				# ignore 2nd occurence of same name
	next if (defined $nameInBlock{"$name"}); # avoid identical names

				# ------------------------------
				# new name
	if (! defined ($tmp{"$name"})){
	    push(@nameLoc,$name); ++$ctRd;
	    $tmp{"$name"}=$ctRd; $tmp{"id","$ctRd"}=$name;
	    print "--- $sbrName: new name=$name,\n"   if ($LverbLoc);

	    if ($ctBlocks>1){	# fill up with dots
		print "--- $sbrName: file up for $name, with :$lenFirstBeforeThis\n" if ($LverbLoc);
		$tmp{"seq","$ctRd"}="." x $lenFirstBeforeThis;}
	    else{
		$tmp{"seq","$ctRd"}="";}}
				# ------------------------------
				# finally store
	$seq=~s/[^A-Za-z]/\./g; # any non-character to dot
	$seq=~tr/[a-z]/[A-Z]/;
	$ptr=$tmp{"$name"};    
	$tmp{"seq","$ptr"}.=$seq;
	$nameInBlock{"$name"}=1; # avoid identical names
    } close($fhinLoc);
				# ------------------------------
				# fill up ends
    $lenLoc=length($tmp{"seq","1"});
    foreach $itTmp (1..$#nameLoc){
	$tmp{"seq","$itTmp"}.="." x ($lenLoc-length($tmp{"seq","$itTmp"}));}
    $tmp{"NROWS"}=$ctRd;
    $tmp{"names"}=join (',',@nameLoc);  $tmp{"names"}=~s/^,*|,*$//;

    $#nameLoc=0; undef %nameInBlock;

    return(1,"ok $sbrName",%tmp);
}				# end of safRd

#===============================================================================
sub safWrt {
    local($fileOutLoc,%tmp) = @_ ;
    local(@nameLoc,@stringLoc,$tmp,$sbrName,$Lok);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   safWrt                      writing an SAF formatted file of aligned strings
#       in:                     $fileOutLoc       output file
#                                   = "STDOUT"    -> write to screen
#       in:                     $tmp{"NROWS"}     number of alignments
#       in:                     $tmp{"id", "$it"} name for $it
#       in:                     $tmp{"seq","$it"} sequence for $it
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

#===============================================================================
sub seqGenWrt {
    local($seqInLoc,$idInLoc,$formOutLoc,$fileOutLoc,$fhErrSbr) = @_ ;
    local($sbrName,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   seqGenWrt                   writes protein sequence in various output formats
#       in:                     $seq,$id,$formOut,$fileOut,$fhErrSbr
#       out:                    implicit: fileOut
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="lib-br:"."seqGenWrt"; $fhoutLoc="FHOUT_"."seqGenWrt";
				# check arguments
    return(0,"*** $sbrName: not def seqInLoc!")         if (! defined $seqInLoc);
    return(0,"*** $sbrName: not def idInLoc!")          if (! defined $idInLoc);
    return(0,"*** $sbrName: not def formOutLoc!")       if (! defined $formOutLoc);
    return(0,"*** $sbrName: not def fileOutLoc!")       if (! defined $fileOutLoc);
    $fhErrSbr="STDOUT"                                  if (! defined $fhErrSbr);

    return(0,"*** $sbrName: sequence missing")          if (length($seqInLoc)<1);

    undef %tmp;
				# ------------------------------
    $tmp{"seq","1"}=$seqInLoc;	# intermediate variable for seq
    $tmp{"NROWS"}=  1;
    $tmp{"id","1"}= $idInLoc;
    $Lok=0;
				# ------------------------------
				# write output
    if    ($formOutLoc =~ /^fasta/){ ($Lok,$msg)=&fastaWrtMul($fileOutLoc,%tmp);}
    elsif ($formOutLoc =~ /^pir/)  { ($Lok,$msg)=&pirWrtMul($fileOutLoc,%tmp);}
    elsif ($formOutLoc eq "saf")   { ($Lok,$msg)=&safWrt($fileOutLoc,%tmp);}
    elsif ($formOutLoc eq "msf")   { $tmp{"FROM"}="unk";$tmp{"TO"}=$fileOutLoc;
				     $tmp{"1"}=$idInLoc;$tmp{"$idInLoc"}=$seqInLoc;
				     &open_file("$fhoutLoc",">$fileOutLoc") ||
					 return(&errSbr("failed creating $fileOutLoc"));
				     $Lok=
					 &msfWrt($fhoutLoc,%tmp);
				     close($fhoutLoc);
				     return(&errSbr("failed writing msf=$fileOutLoc (msfWrt)"))
					 if (! $Lok);}
    else {
	return(0,"*** ERROR $sbrName output format $formOutLoc not supported\n");}

    return(0,"*** ERROR $sbrName: failed to write $formOutLoc into $fileOutLoc\n")
	if (! $Lok || ! -e $fileOutLoc);

    return(1,"ok $sbrName");
}				# end of seqGenWrt

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
    return($idLoc)  if (-e $idLoc); # already existing directory
    $#dirLoc=0      if (! defined @dirLoc);
    if    (! defined $LscreenLoc){
	$LscreenLoc=0;}
    elsif (-d $Lscreen)       {
	@dirLoc=($LscreenLoc,@dirLoc);
	$LscreenLoc=0;}
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
sub swissGetKingdom {
    local($fileLoc,$kingdomLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,@specLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   swissGetKingdom             gets all species for given kingdom
#       in:                     $kingdom (all,euka,proka,virus,archae)
#       out:                    @species
#-------------------------------------------------------------------------------
    $sbrName="swissKingdom2Species";$fhinLoc="FHIN"."$sbrName";$fhinLoc=~tr/[a-z]/[A-Z]/;
				# assign search pattern
    if    ($kingdomLoc eq "all")   { $tmp="EPAV";}
    elsif ($kingdomLoc eq "euka")  { $tmp="E";}
    elsif ($kingdomLoc eq "proka") { $tmp="P";}
    elsif ($kingdomLoc eq "virus") { $tmp="V";}
    elsif ($kingdomLoc eq "archae"){ $tmp="A";}
				# read SWISS-PROT file (/data/swissprot/speclist.txt)
    $#specLoc=0;
    $Lok=&open_file("$fhinLoc","$fileLoc");
    if ($Lok){			# notation 'SPECIES V|P|E|A\d+ ..'
	while (<$fhinLoc>) {last if /^Code  Taxon: N=Official name/;}
	while (<$fhinLoc>) {if (! /^[A-Z].*[$tmp][0-9a-z:]+ /){next;}
			    @tmp=split(/\s+/,$_);
			    $tmp[1]=~tr/[A-Z]/[a-z]/;
			    push(@specLoc,$tmp[1]);}close($fhinLoc);}
    else {
	return(@specLoc,"file missing");}
    return(@specLoc);

}				# end of swissGetKingdom

#===============================================================================
sub swissGetLocation {
    local ($regexpLoc,$fhLoc,@fileInLoc) = @_ ;
    local($sbrName,$fhoutLoc,$LverbLoc,@outLoc,@rdLoc);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   swissGetLocation            searches in SWISS-PROT file for cell location           
#       in:                     $regexp,$handle,@file
#                               $regexp e.g. = "^CC .*SUBCELLULAR LOCATION:"
#                               $fhLoc  = 0,1,FHOUT (file handle for blabla)
#                               @file   = swissprot files to read
#       out:                    @lines_with_expression
#--------------------------------------------------------------------------------
    $sbrName="swissGetLocation";$fhinLoc="FHIN_$sbrName";
    if    ($fhLoc eq "0"){$fhoutLoc=0;$LverbLoc=0;}	# file handle
    elsif ($fhLoc eq "1"){$fhoutLoc="STDOUT";$LverbLoc=0;}
    else                 {$fhoutLoc=$fhLoc;$LverbLoc=0;}
				# ------------------------------
				# read swiss-prot files
    $#finLoc=0;
    foreach $fileTmp (@fileInLoc){
	if (! -e $fileTmp){
	    next;}
	&open_file("$fhinLoc", "$fileTmp");$Lok=$Lfin=0;$loci="";
	while (<$fhinLoc>) {$_=~s/\n//g;
			    if (/$regexpLoc/) {	# find first line (CC )
				$_=~s/$regexpLoc//g; # purge keywords
				$Lok=1;$loci="$_"." ";}
			    elsif ($Lok && /^[^C]|^CC\s+-\!-/){	# end if new expression
				$Lfin=1;}
			    elsif ($Lok){
				$_=~s/^CC\s+//;
				$loci.="$_"." ";}
			    last if ($Lfin);}close($fhinLoc);
	if (length($loci)<5){
	    next;}
	$loci=~s/\t+/\s/g; 
	if ($LverbLoc){print $fhoutLoc "--- '$regexpLoc' in $fileTmp:$loci\n";}
	$id=$fileTmp;$id=~s/^.*\///g;$id=~s/\n|\s//g;
	$tmp="$loci"."\t"."$id";
	push(@finLoc,"$tmp");}
    return(@finLoc);
}				# end of swissGetLocation

#===============================================================================
sub swissGetRegexp {
    local ($fileLoc,$regexpLoc) = @_ ;
    local($sbrName,$fhinLoc,@outLoc);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   swissGetregexp              searches in SWISS-PROT file for regular expression           
#       in:                     file name
#       out:                    @lines_with_expression
#--------------------------------------------------------------------------------
    $sbrName="swissGetregexp";$fhinLoc="FHIN"."$sbrName";
    &open_file("$fhinLoc", "$fileLoc");
    while (<$fhinLoc>) {
	$_=~s/\n//g;
	if (/$regexpLoc/){
	    push(@outLoc,$_);}}close($fhinLoc);
    if ($#outLoc>0){
	return(@outLoc);}
    else {
	return(0);}
}				# end of swissGetRegexp

#===============================================================================
sub swissRdSeq {
    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc,$msg,$Lok,$seq,$id);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   swissRdSeq                  reads the sequence from a SWISS-PROT file
#       in:                     file
#       out:                    (1,name,sequence in one string)
#-------------------------------------------------------------------------------
    $sbrName="swissRdSeq";$fhinLoc="FHIN"."$sbrName";

    $Lok=       &open_file("$fhinLoc","$fileInLoc");
    if (! $Lok){$msg="*** ERROR $sbrName: '$fileInLoc' not opened\n";
		return(0,$msg,"error");}
    $seq="";
    while (<$fhinLoc>) {$_=~s/\n//g;
			if ($_=~/^ID\s+(\S*)\s*.*$/){
			    $id=$1;}
			last if ($_=~/^\/\//);
			next if ($_=~/^[A-Z]/);
			$seq.="$_";}close($fhinLoc);
    $seq=~s/\s//g;
    return(1,$id,$seq);
}				# end of swissRdSeq

#===============================================================================
sub write_pir {
    local ($name,$seq,$file_handle,$seq_char_per_line) = @_;
    local ($i);
    $[=1;
#--------------------------------------------------
#   write_pir                   writes protein into PIR format
#--------------------------------------------------
    if ( length($seq_char_per_line) == 0 ) { $seq_char_per_line = 80; }
    if ( length($file_handle) == 0 ) { $file_handle = "STDOUT"; }

    print $file_handle ">P1\; \n"; print $file_handle "$name \n";
    for ( $i=1; $i < length($seq) ;$i += $seq_char_per_line){
	print $file_handle substr($seq,$i,$seq_char_per_line), "\n";}
}				# end of write_pir

#===============================================================================
sub wrt_msf {
    local ($file_out,@string) = @_ ;
    $[ =1 ;
#--------------------------------------------------------------------------------
#   wrt_msf                     writing an MSF formatted file of aligned strings
#         in:                   $file_msf,@string,
#                               where file_msf is the name of the output MSF file,
#                               and @string contains all strings to be used (to pass
#                               the names, use first: des=name1, des=name2, string1, string2
#--------------------------------------------------------------------------------
    $fhout="FHOUT_WRT_MSF";
    $#name=$#tmp=0;
    foreach $it (1..$#string){
	if ($string[$it]=~ /des=/){
	    $string[$it]=~s/des=//g; push(@name,$string[$it]); }
	else {
	    push(@tmp,$string[$it]);}}
    if ($#name>1) {@string=@tmp;}
    else          {$#name=0;
		   foreach $it(1..$#string){$tmp="seq"."$it";
					    push(@name,$tmp);} }

    &open_file("$fhout",">$file_out");
    print $fhout 
	"MSF of: 1ppt.hssp from:    1 to:   ",length($string[1])," \n",
	"$file_out MSF: ",length($string[1]),
	"  Type: N  November 09, 1918 14:00 Check: 1933 ..\n \n \n";
    foreach $it (1..$#string){
	printf 
	    $fhout "Name: %-20s Len: %-5d Check: 2222 Weight: 1.00\n",
	    $name[$it],length($string[$it]); }
    print $fhout " \n//\n \n";
    for($it=1;$it<=length($string[1]);$it+=50){
	foreach $it2 (1..$#string){
	    printf 
		$fhout "%-20s %-10s %-10s %-10s %-10s %-10s\n",$name[$it2],
		substr($string[$it2],$it,10),substr($string[$it2],($it+10),10),
		substr($string[$it2],($it+20),10),substr($string[$it2],($it+30),10),
		substr($string[$it2],($it+40),10); }
	print $fhout "\n"; }
    print $fhout "\n";
    close($fhout);
}				# end of wrt_msf

#===============================================================================
sub wrtMsf {
    local($fileOutMsfLoc,%input) = @_ ;
    local(@nameLoc,@stringLoc,$tmp,$fhoutLoc,$sbrName,$Lok);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   wrtMsf                      writing an MSF formatted file of aligned strings
#         in:                   $file_msf,$input{}
#                               $input{"NROWS"}  number of alignments
#                               $input{"FROM"}   name of input file
#                               $input{"TO"}     name of output file
#                               $input{"$it"}    sequence identifier ($name)
#                               $input{"$name"}  sequence for $name
#--------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";}
    $sbrName="$tmp"."wrtMsf";$fhoutLoc="FHOUT"."$sbrName";
				# open MSF file
    $Lok=       &open_file("$fhoutLoc",">$fileOutMsfLoc");
    if (! $Lok){print "*** ERROR $sbrName: '$fileOutMsfLoc' not opened\n";
		return(0);}
				# ------------------------------
				# process input
    $#nameLoc=$#tmp=0;
    foreach $it (1..$input{"NROWS"}){$name=$input{"$it"};
				     push(@nameLoc,$name);	# store the names
				     push(@stringLoc,$input{"$name"}); } # store sequences
				# ------------------------------
				# write into file
    print $fhoutLoc 
	"MSF of: ",$input{"FROM"}," from:    1 to:   ",length($stringLoc[1])," \n",
	$input{"TO"}," MSF: ",length($stringLoc[1]),
	"  Type: N  November 09, 1918 14:00 Check: 1933 ..\n \n \n";
    foreach $it (1..$#stringLoc){
	printf 
	    $fhoutLoc "Name: %-20s Len: %-5d Check: 2222 Weight: 1.00\n",
	    $nameLoc[$it],length($stringLoc[$it]); }
    print $fhoutLoc " \n";
    print $fhoutLoc "\/\/\n";
    print $fhoutLoc " \n";

    for($it=1;$it<=length($stringLoc[1]);$it+=50){
	foreach $it2 (1..$#stringLoc){
	    printf $fhoutLoc 
		"%-20s %-10s %-10s %-10s %-10s %-10s\n",$nameLoc[$it2],
		substr($stringLoc[$it2],$it,10),substr($stringLoc[$it2],($it+10),10),
		substr($stringLoc[$it2],($it+20),10),substr($stringLoc[$it2],($it+30),10),
		substr($stringLoc[$it2],($it+40),10); }
	print $fhoutLoc "\n"; }
    print $fhoutLoc "\n";
    close($fhoutLoc);
}				# end of wrtMsf

1;
