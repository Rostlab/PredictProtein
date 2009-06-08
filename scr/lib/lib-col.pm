##!/usr/local/bin/perl -w
##!/usr/pub/bin/perl5 -w
##!/usr/pub/bin/perl5.003 -w
##! /usr/pub/bin/perl -w
#================================================================================ #
#                                                                                 #
#-------------------------------------------------------------------------------- #
# Predict Protein - a secondary structure prediction and sequence analysis system # 
# Copyright (C) <2004> CUBIC, Columbia University                                 #
#                                                                                 #
# Burkhard Rost		rost@columbia.edu			                  #
# http://cubic.bioc.columbia.edu/~rost/	                                          #
# Jinfeng Liu             liu@cubic.bioc.columbia.edu  	                          #
# Guy Yachdav         yachdav@cubic.bioc.columbia.edu        	                  #
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
#---------------------------------------------------------------------------------#
#	Copyright				  May,    	 1998	          #
#	Burkhard Rost 		rost@EMBL-Heidelberg.DE			          #
#	EMBL			http://www.embl-heidelberg.de/~rost/	          #
#	D-69012 Heidelberg						          #
#			        v 1.1   	  Jan,           1999             #
#------------------------------------------------------------------------------   #
# 
#   collection of subroutines from /home/rost/perl/lib libraries
#   
#   to update frequently!
# 
# 
# -----------------------------------------------------------------------------# 
#                               ---------------------
#   tmp                         external subroutines:
#                               ---------------------
# 
#   call from br:               globeFuncFit,globeFuncJoinPhdSegIni,globeOne,globeOneCombi
#                               globeOneIni,globeProb,globeRd_phdRdb,globeWrt,ppHsspRdExtrHeader
#                               ppStripRd,ppTopitsHdWrt,topitsWrtOwn,topitsWrtOwnHdr
#                               wrt_dssp_phd,wrt_phd2msf,wrt_phd_header2pp,wrt_phd_rdb2col
#                               wrt_phd_rdb2pp,wrt_phdpred_from_string,wrt_phdpred_from_string_htm
#                               wrt_phdpred_from_string_htm_header,wrt_ppcol
# 
#   call from comp:             get_max,get_min
# 
#   call from file:             isDaf,isDafGeneral,isDafList,isDsspGeneral,isFasta
#                               isFastaMul,isFsspGeneral,isHsspGeneral,isMsf,isMsfGeneral
#                               isMsfList,isPhdAcc,isPhdHtm,isPhdSec,isPir,isPirMul
#                               isRdb,isRdbGeneral,isRdbList,isSaf,isSwiss,isSwissGeneral
#                               isSwissList,is_dssp,is_dssp_list,is_hssp,is_hssp_empty
#                               is_hssp_list,is_strip,is_strip_list,is_strip_old,open_file
#                               rdRdbAssociative,rdRdbAssociativeNum,rd_col_associative
#                               rd_rdb_associative,rdb2html,read_rdb_num,read_rdb_num2
#                               wrtRdb2HtmlBody,wrtRdb2HtmlHeader
# 
#   call from formats:          convFasta2gcg,convHssp2msf,convMsf2Hssp,convPhd2col
#                               convSeq2fasta,dsspGetFile,dsspGetFileLoop,dsspRdSeq
#                               fastaRdGuide,fastaWrt,getFileFormat,interpretSeqCol
#                               interpretSeqFastalist,interpretSeqMsf,interpretSeqPP
#                               interpretSeqPirlist,interpretSeqSaf,interpretSeqSafFillUp
#                               msfCheckFormat,msfWrt,pirRdSeq,swissGetFile,swissRdSeq
#                               write_pir,wrt_msf
# 
#   call from hssp:             get_hssp_file,hsspChopProf,hsspGetChain,hsspGetChainLength
#                               hsspGetFile,hsspGetFileLoop,hsspRdAli,hsspRdHeader
#                               hsspRdProfile,hsspRdSeqSecAcc,hsspRdSeqSecAccOneLine
#                               hsspRdStripAndHeader,hsspRdStripHeader,hssp_fil_num2txt
#                               hssp_rd_header,hssp_rd_strip_one,hssp_rd_strip_one_correct1
#                               hssp_rd_strip_one_correct2
# 
#   call from molbio:           blastpExtrId,blastpRdHdr,blastpRun,coilsRd,coilsRun
#                               fastaRun,maxhomCheckHssp,maxhomGetArg,maxhomGetArgCheck
#                               maxhomGetThresh4PP,maxhomMakeLocalDefault,maxhomRunLoop
#                               maxhomRunSelf,prodomRun,prodomWrt
# 
#   call from prot:             exposure_project_1digit,is_chain,is_pdbid
# 
#   call from scr:              errSbrMsg,get_range,get_rangeHyphen,myprt_npoints
# 
#   call from sys:              complete_dir,identify_current_user,run_program,sysCatfile
#                               sysCpfile,sysMkdir,sysMvfile,sysRunProg
# 
#   call from system:            
# 
#   call from missing:           
#                               convTopits2msf
#                               ctime
#                               ctrlAlarm
#                               ctrlDbgMsg
#                               filePurgeBlankLines
#                               filePurgeNullChar
#                               filePurgePat1Pat2
#                               get_chainlocal
#                               get_idlocal
#                               get_pdbidlocal
#                               get_sumlocal
#                               globeRdPhdRdb
#                               isDaflocal
#                               isMsflocal
#                               isRdbListlocal
#                               isRdblocal
#                               isSwisslocal
#                               is_swissprot
#                               printmlocal
#                               sendMailAlarm
#                               subx
# 
# 
# -----------------------------------------------------------------------------# 
#                               ---------------------------
#                               description of subroutines:
#                               ---------------------------
#       call br:                globeFuncFit,globeFuncJoinPhdSegIni,globeOne,globeOneCombi
#                               globeOneIni,globeProb,globeRd_phdRdb,globeWrt,ppHsspRdExtrHeader
#                               ppStripRd,ppTopitsHdWrt,topitsWrtOwn,topitsWrtOwnHdr
#                               wrt_dssp_phd,wrt_phd2msf,wrt_phd_header2pp,wrt_phd_rdb2col
#                               wrt_phd_rdb2pp,wrt_phdpred_from_string,wrt_phdpred_from_string_htm
#                               wrt_phdpred_from_string_htm_header,wrt_ppcol
#       call comp:              get_max,get_min
#       call file:              isDaf,isDafGeneral,isDafList,isDsspGeneral,isFasta
#                               isFastaMul,isFsspGeneral,isHsspGeneral,isMsf,isMsfGeneral
#                               isMsfList,isPhdAcc,isPhdHtm,isPhdSec,isPir,isPirMul
#                               isRdb,isRdbGeneral,isRdbList,isSaf,isSwiss,isSwissGeneral
#                               isSwissList,is_dssp,is_dssp_list,is_hssp,is_hssp_empty
#                               is_hssp_list,is_strip,is_strip_list,is_strip_old,open_file
#                               rdRdbAssociative,rdRdbAssociativeNum,rd_col_associative
#                               rd_rdb_associative,rdb2html,read_rdb_num,read_rdb_num2
#                               wrtRdb2HtmlBody,wrtRdb2HtmlHeader
#       call formats:           convFasta2gcg,convHssp2msf,convMsf2Hssp,convPhd2col
#                               convSeq2fasta,dsspGetFile,dsspGetFileLoop,dsspRdSeq
#                               fastaRdGuide,fastaWrt,getFileFormat,interpretSeqCol
#                               interpretSeqFastalist,interpretSeqMsf,interpretSeqPP
#                               interpretSeqPirlist,interpretSeqSaf,interpretSeqSafFillUp
#                               msfCheckFormat,msfWrt,pirRdSeq,swissGetFile,swissRdSeq
#                               write_pir,wrt_msf
#       call hssp:              get_hssp_file,hsspChopProf,hsspGetChain,hsspGetChainLength
#                               hsspGetFile,hsspGetFileLoop,hsspRdAli,hsspRdHeader
#                               hsspRdProfile,hsspRdSeqSecAcc,hsspRdSeqSecAccOneLine
#                               hsspRdStripAndHeader,hsspRdStripHeader,hssp_fil_num2txt
#                               hssp_rd_header,hssp_rd_strip_one,hssp_rd_strip_one_correct1
#                               hssp_rd_strip_one_correct2
#       call molbio:            blastpExtrId,blastpRdHdr,blastpRun,coilsRd,coilsRun
#                               fastaRun,maxhomCheckHssp,maxhomGetArg,maxhomGetArgCheck
#                               maxhomGetThresh4PP,maxhomMakeLocalDefault,maxhomRunLoop
#                               maxhomRunSelf,prodomRun,prodomWrt
#       call prot:              exposure_project_1digit,is_chain,is_pdbid
#       call scr:               errSbrMsg,get_range,get_rangeHyphen,myprt_npoints
#       call sys:               complete_dir,identify_current_user,run_program,sysCatfile
#                               sysCpfile,sysMkdir,sysMvfile,sysRunProg
# -----------------------------------------------------------------------------# 


#==============================================================================
# library collected (begin)
#==============================================================================
use Carp qw| cluck :DEFAULT |;
use File::Spec;
use Digest::MD5;
use Fcntl qw|:flock :DEFAULT|;
use File::stat qw||;
use Data::Dumper qw||;

#==============================================================================
sub blastpExtrId {
    local($fileInLoc2,$fhoutLoc,@idLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok,$Lhead,$line,$Lread,$id);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   blastpExtrId                extracts only lines with particular id from BLAST
#       in:                     $fileBlast,$fileHANDLE_OUTPUTFILE,@id_to_read
#       in:                     NOTE: if $#id==0, all are read
#       out:                    (1,'ok') + written into FILE_HANDLE
#       err:                    (0,'msg')
#-------------------------------------------------------------------------------
    $sbrName="lib-col:"."blastpExtrId";$fhinLoc="FHIN"."$sbrName";
				# ------------------------------
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc2!")     if (! defined $fileInLoc2);
    $fhoutLoc="STDOUT"                                if (! defined $fhoutLoc);
    return(0,"*** $sbrName: no in file=$fileInLoc2")  if (! -e $fileInLoc2);
				# ------------------------------
				# open BLAST output
    $Lok=       &open_file("$fhinLoc","$fileInLoc2");
    return(0,"*** ERROR $sbrName: old=$fileInLoc2, not opened\n") if (! $Lok);
				# ------------------------------
    $Lhead=1;			# read file
    while (<$fhinLoc>) {
	print $fhoutLoc $_;
	last if ($_=~/^Sequences producing High/i);}
				# ------------------------------
    while (<$fhinLoc>) {	# skip  header summary
	$_=~s/\n//g;$line=$_;
	if (length($_)<1 || $_ !~/\S/){	# skip empty line
	    print $fhoutLoc "\n";
	    next;}
	if ($_=~/^Parameters/){ # final
	    print $fhoutLoc "$_\n";
	    last;}
	$Lhead=0 if ($line=~/^\s*\>/); # now the alis start
				# --------------------
	if ($Lhead){		# .. but before the alis
	    $Lread=0;
	    foreach $id (@idLoc){ # id found?
		if ($line=~/^\s*$id/){$Lread=1;
				      last;}}
	    print $fhoutLoc "$line\n" if ($Lread);
	    next;}
				# --------------------
				# here the alis should have started
	if ($line=~/^\s*\>/){
	    $Lread=0;
	    foreach $id (@idLoc){ # id found?
		if ($line=~/^\s*\>$id/){$Lread=1;
					last;}}}
	print $fhoutLoc "$line\n" if ($Lread);}
    while(<$fhinLoc>){
	print $fhoutLoc $_;}
    close($fhinLoc);
    return(1,"ok $sbrName");
}				# end of blastpExtrId 

#==============================================================================
sub blastpRdHdr {
    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok,@idFoundLoc,
	  $Lread,$name,%hdrLoc,$Lskip,$id,$line);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   blastpRdHdr                 reads header of BLASTP output file
#       in:                     $fileBlast
#       out:                    (1,'ok',%hdrLoc)
#       out:                    $hdrLoc{"$id"}='id1,id2,...'
#       out:                    $hdrLoc{"$id","$kwd"} , with:
#                                  $kwd=(score|prob|ide|len|lali)
#       err:                    (0,'msg')
#-------------------------------------------------------------------------------
    $sbrName="lib-col:"."blastpRdHdr";$fhinLoc="FHIN-blastpRdHdr";
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc!")    if (! defined $fileInLoc);
    return(0,"*** $sbrName: no in file=$fileInLoc") if (! -e $fileInLoc);
				# ------------------------------
				# open BLAST output
    open($fhinLoc,$fileInLoc) ||
	return(0,"*** ERROR $sbrName: '$fileInLoc' not opened\n");
				# ------------------------------
    $#idFoundLoc=$Lread=0;	# read file
    while (<$fhinLoc>) {
	last if ($_=~/^\s*Sequences producing /i);}
				# ------------------------------
				# skip header summary
    while (<$fhinLoc>) {
	$_=~s/\n//g;
	next if (length($_)<1 || $_ !~/\S/); # skip empty line
	$Lread=1 if (! $Lread && $_=~/^\s*>/);
	next if (! $Lread);
	last if ($_=~/^\s*Parameters/i); # final
				# ------------------------------
	$line=$_;		# read ali paras
				# id
	if    ($line=~/^\s*>\s*(.*)/){
	    $name=$1;$id=$name;$id=~s/^([\S]+)\s+.*$/$1/g;
	    if (length($id)>0){
		push(@idFoundLoc,$id);$Lskip=0;
		$hdrLoc{"$id","name"}=$name;}
	    else              {
		$Lskip=1;}}
				# length
	elsif (! $Lskip && ! defined $hdrLoc{"$id","len"} && 
	       ($line=~/^\s*Length = (\d+)/)) {
	    $hdrLoc{"$id","len"}=$1;}
				# sequence identity
	elsif (! $Lskip && ! defined $hdrLoc{"$id","ide"} &&
	       ($line=~/^\s* Identities = \d+\/(\d+) \((\d+)/) ) {
	    $hdrLoc{"$id","lali"}=$1;
	    $hdrLoc{"ide","$id"}=$hdrLoc{"$id","ide"}=$2;}
				# score + prob (blast3)
	elsif (! $Lskip && ! defined $hdrLoc{"$id","score"} &&
	       ($line=~/ Score = [\d\.]+ bits \((\d+)\).*, Expect = \s*([\d\-\.e]+)/) ) {
	    $hdrLoc{"$id","score"}=$1;
	    $hdrLoc{"$id","prob"}= $2;}
				# score + prob (blast2)
	elsif (! $Lskip && ! defined $hdrLoc{"$id","score"} &&
	       ($line=~/ Score = (\d+)\s+[^,]*, Expect = ([^,]+), .*$/) ) {
	    $hdrLoc{"$id","score"}=$1;
	    $hdrLoc{"$id","prob"}= $2;}}close($fhinLoc);
				# ------------------------------
    $hdrLoc{"id"}="";		# arrange to pass the result
    for $id(@idFoundLoc){
	$hdrLoc{"id"}.="$id,"; } $hdrLoc{"id"}=~s/,*$//g;

    $#idFoundLoc=0;		# save space
    return(1,"ok $sbrName",%hdrLoc);
}				# end of blastpRdHdr 

#==============================================================================
sub blastpRun {
    local($niceLoc,$dirData,$dirSwissSplit,$exeBlastp,$exeBlastpFil,$envBlastpMat,
	  $envBlastpDb,$nhits,$parBlastpDb,$fileInLoc,$fileOutLoc,
	  $fileOutFilLoc,$fhTraceLoc)=@_;
    local($sbr,$command,$msg,$Lok);
#----------------------------------------------------------------------
#   blastpRun                   runs BLASTP
#       in:                     $niceLoc,$dirData,$dirSwissSplit,$exeBlastp,$exeBlastpFil,
#       in:                     $envBlastpMat,$envBlastpDb,$numHits,$parBlastpDb,
#       in:                     $fileInLoc,$fileOutLoc,$fileOutFilLoc,$fhTraceLoc
#       out:                    
#       err:                    ok=(1,'ok'), err=(0,'msg')
#----------------------------------------------------------------------
    $sbr="lib-col:blastpRun";
    $fhTraceLoc="STDOUT"                               if (! defined $fhTraceLoc);
    return(0,"*** $sbr: not def niceLoc!")          if (! defined $niceLoc);
    return(0,"*** $sbr: not def dirData!")          if (! defined $dirData);
    return(0,"*** $sbr: not def dirSwissSplit!")    if (! defined $dirSwissSplit);
    return(0,"*** $sbr: not def exeBlastp!")        if (! defined $exeBlastp);
    return(0,"*** $sbr: not def exeBlastpFil!")     if (! defined $exeBlastpFil);
    return(0,"*** $sbr: not def envBlastpMat!")     if (! defined $envBlastpMat);
    return(0,"*** $sbr: not def envBlastpDb!")      if (! defined $envBlastpDb);
    return(0,"*** $sbr: not def nhits!")            if (! defined $nhits);
    return(0,"*** $sbr: not def fileInLoc!")        if (! defined $fileInLoc);
    return(0,"*** $sbr: not def fileOutLoc!")       if (! defined $fileOutLoc);
    return(0,"*** $sbr: not def fileOutFilLoc!")    if (! defined $fileOutFilLoc);

    return(0,"*** $sbr: miss dir =$dirData!")       if (! -d $dirData);
    return(0,"*** $sbr: miss dir =$dirSwissSplit!") if (! -d $dirSwissSplit);
    return(0,"*** $sbr: miss dir =$envBlastpDb!")   if (! -d $envBlastpDb);
    return(0,"*** $sbr: miss dir =$envBlastpMat!")  if (! -d $envBlastpMat);

    return(0,"*** $sbr: miss file=$fileInLoc!")     if (! -e $fileInLoc);
    return(0,"*** $sbr: miss exe =$exeBlastp!")     if (! -e $exeBlastp);
    return(0,"*** $sbr: miss exe =$exeBlastpFil!")  if (! -e $exeBlastpFil);

				# ------------------------------
				# set environment needed for BLASTP
    $ENV{'BLASTMAT'}=$envBlastpMat;
    $ENV{'BLASTDB'}= $envBlastpDb;
                                # ------------------------------
                                # run BLASTP
                                # ------------------------------
#    $command="$niceLoc $exeBlastp $parBlastpDb $fileInLoc B=$nhits > $fileOutLoc";
    $command="$niceLoc $exeBlastp  -p blastp -d ".$ENV{'BLASTDB'}."$parBlastpDb -i $fileInLoc -B $nhits > $fileOutLoc";
    $msg="--- $sbr '$command'\n";
warn $msg;
    ($Lok,$msgSys)=
	&sysSystem("$command" ,$fhTraceLoc);
    if (! $Lok){
	return(0,"*** ERROR $sbr '$Lok'\n".$msg."\n".$msgSys);}
    if (! -e $fileOutLoc){
	return(0,"*** ERROR $sbr no output '$fileOutLoc'\n"."$msg");}
				# ------------------------------
				# extract hits from BLASTP-output
				# ------------------------------
    $dirSwissSplit=~s/\/$//g;
    if ($exeBlastpFil =~/big/) {
	$command="$niceLoc $exeBlastpFil $fileOutLoc db=$parBlastpDb > $fileOutFilLoc ";}
    else {
	$command="$niceLoc $exeBlastpFil $dirSwissSplit < $fileOutLoc > $fileOutFilLoc ";}
    $msg.="--- $sbr '$command'\n";
    print "--- ".__FILE__.':'.__LINE__." system: \t $command\n";
    
    $msg=
	system("$command");

    return(0,"*** ERROR $sbr after $exeBlastpFil no output '$fileOutFilLoc'\n")
	if (! -e $fileOutFilLoc);

    open("FHIN",$fileOutFilLoc) ||
	return(0,"*** ERROR $sbr after $exeBlastpFil no output '$fileOutFilLoc'\n");
    $firstLine=<FHIN>;
    close(FHIN);

    @tmp=stat $fileOutFilLoc;
    $size=$tmp[8];
    $first_line=system("head -1 $fileOutFilLoc");
    return(2,"none found")
	if ($size < 10 || ($size < 20 && $first_line=~/none/));
    return(1,"ok $sbr");
}				# end of blastpRun


#==============================================================================
sub blastpsiRun {
    local($niceLoc,$exeBlastPsi,$exeBlast2Saf,
	  $envBlastPsiDb,$argBlast,$argBlastBig,$blastTile,$parBlastPsiDb,
	  $parBlastPsiDbBig,$blastFilThre,$blastMaxAli,
	  $fileInLoc,$fileFasta,$fileOutLoc,$fileOutRdb,$fileOutCheck,
	  $fileOutTmp,$fileOutSaf,
	  $fileOutMat,$fileTraceBlast,$fileBlastMatTmb,$fhTraceLoc)=@_;
    local($sbr,$dbBlastPsi,$dbBlastBig,$command,$msg,$msgSys,$timeNow,$Lok);
#----------------------------------------------------------------------
#   blastpsiRun                   runs Psi-BLASTP
#       in:                     $niceLoc,$dirData,$dirSwissSplit,$exeBlastPsi
#       in:                     $envBlastpMat,$envBlastpDb,$numHits,$parBlastpDb,
#       in:                     $fileInLoc,$fileOutLoc,$fileOutFilLoc,$fhTraceLoc
#       out:                    
#       err:                    ok=(1,'ok'), err=(0,'msg')
#----------------------------------------------------------------------
    $[ =1 ;				# count from one
    $sbr="lib-col:blastpsiRun";
    $fhTraceLoc="STDOUT"                             if (! defined $fhTraceLoc);
    return(0,"*** $sbr: not def niceLoc!")           if (! defined $niceLoc);
    return(0,"*** $sbr: not def exeBlastPsi!")       if (! defined $exeBlastPsi);
    #return(0,"*** $sbr: not def envBlastPsiMat!")    if (! defined $envBlastPsiMat);
    return(0,"*** $sbr: not def envBlastPsiDb!")     if (! defined $envBlastPsiDb);
    return(0,"*** $sbr: not def argBlast!")          if (! defined $argBlast);
    return(0,"*** $sbr: not def blastTile!")         if (! defined $blastTile);
    return(0,"*** $sbr: not def parBlastPsiDb!")     if (! defined $parBlastPsiDb);
    return(0,"*** $sbr: not def blastFilThre!")      if (! defined $blastFilThre);
    return(0,"*** $sbr: not def blastMaxAli!")       if (! defined $blastMaxAli);
    return(0,"*** $sbr: not def fileInLoc!")         if (! defined $fileInLoc);
    return(0,"*** $sbr: not def fileOutLoc!")        if (! defined $fileOutLoc);
    return(0,"*** $sbr: not def fileOutRdb!")        if (! defined $fileOutRdb);
    return(0,"*** $sbr: not def fileOutCheck!")        if (! defined $fileOutCheck);
    return(0,"*** $sbr: not def fileOutTmp!")        if (! defined $fileOutTmp);
    return(0,"*** $sbr: not def fileOutSaf!")        if (! defined $fileOutSaf);
    return(0,"*** $sbr: not def fileOutMat!")        if (! defined $fileOutMat);
    return(0,"*** $sbr: not def fileTraceBlast!")    if (! defined $fileTraceBlast);

    return(0,"*** $sbr: miss dir =$envBlastPsiDb!")  if (! -d $envBlastPsiDb);
    return(0,"*** $sbr: miss file=$fileInLoc!")      if (! -e $fileInLoc   && ! -l $fileInLoc);
    return(0,"*** $sbr: miss exe =$exeBlastPsi!")    if (! -e $exeBlastPsi && ! -l $exeBlastPsi);
    return(0,"*** $sbr: miss exe =$exeBlast2Saf!")    if (! -e $exeBlast2Saf && ! -l $exeBlast2Saf);

				# ------------------------------
				# finally run 'real' script
				# ------------------------------
    $envBlastPsiDb .= "/"       if ( $envBlastPsiDb !~ /\/$/ );
    $dbBlastPsi = $envBlastPsiDb.$parBlastPsiDb;

    ## this will do an rsync to a local file system to speed blast a bit
    ## TODO TO COMPLETE THIS SECTION FIND OUT WHICH FILES ARE NECESSARY FOR A BLAST RUN
# 	$envBlastPsiDbTmp = "/tmp/";
# 	$dbBlastPsiTmp = $envBlastPsiDbTmp.$parBlastPsiDb;
# 	 $dirBlast = "/data/blast/";
# 	 $dirDest= "/tmp/";
# 	@ext = ('phr','pin','psq');
# 	@db = ('big_80','big.00','big.01');
# 	
# 	$sizeOk = 1;
# 	for $d(@db){			   
# 		for $e(@ext){
# 			$file = "$dirBlast/$d.".$e;
# 			$fileDest = "$dirDest/$d.".$e;
# 			$cmd = "/usr/bin/rsync $file $fileDest";
# 			($Lok,$msgSys)=
# 				&sysSystem("$cmd" ,$fhTraceLoc);
# 			return(0,"*** ERROR $sbr '$Lok'\n".$msg."\n".$msgSys)
# 				if (! $Lok);
# 			return(0,"*** ERROR $sbr no output '$fileOutTmp'\n"."$msg")
# 				if (! -e $fileOutTmp);
# 			if (-s $file != -s $fileDest){
# 				$sizeOk = 0;
# 			}
# 		}		
# 	}
# 	$dbBlastPsi = $dbBlastPsiTmp if ($sizeOk);
# 
#     
    
    ###

    my $command_base = "$exeBlastPsi $argBlast $dbBlastPsi";
    $command=qq|$niceLoc $command_base -i "$fileInLoc" |.
	qq| -o "$fileOutTmp" -C "$fileOutCheck"  |;
    # GY - added 3/18/2004
    # Prof Tmb needs this added to the 
    if( $fileBlastMatTmb )
    {
	$command .=" -Q $fileBlastMatTmb";
    }
    # end additions
    $msg="--- $sbr '$command'\n";

    # We need the sequence out of $fileInLoc in order to generate the right UUID for our cache:
    my $inseq = Bio::SeqIO->new( -file => $fileInLoc, -format => 'Fasta' )->next_seq();
    if( !$inseq ) { confess("failed to read FASTA sequence from ``$fileInLoc''"); }
    
    ($Lok,$msgSys)=
	&cachedBlastCall( $command, $fhTraceLoc, { md5string => "$command_base -o -C".( $fileBlastMatTmb ? ' -Q' : '' )." --seq=".$inseq->seq(), md5files => [], cache_files => {
                'blres' => $fileOutTmp, 'checkpoint' => $fileOutCheck, ( $fileBlastMatTmb ? ( 'matrix' => $fileBlastMatTmb ) : () ) } } );
        #&sysSystem( $command, $fhTraceLoc );
    return(0,"*** ERROR $sbr '$Lok'\n".$msg."\n".$msgSys)
	if (! $Lok);
    return(0,"*** ERROR $sbr no output '$fileOutTmp'\n"."$msg")
	if (! -e $fileOutTmp);

				# ------------------------------
				# Now the second run against big DB
				# ---------------------------------
    $dbBlastBig = $envBlastPsiDb.$parBlastPsiDbBig;
    $command_base = "$exeBlastPsi $argBlastBig $dbBlastBig";
    $command="$niceLoc $exeBlastPsi $argBlastBig $dbBlastBig -i $fileInLoc ".
	" -o $fileOutLoc -R $fileOutCheck -Q $fileOutMat";
    

    $msg="--- $sbr '$command'\n";
    ($Lok,$msgSys)=
	&cachedBlastCall( $command, $fhTraceLoc, { md5string => "$command_base -o -Q --seq=".$inseq->seq(), md5files => [ $fileOutCheck ], cache_files => {
                'blres' => $fileOutLoc, 'matrix' => $fileOutMat } } );
        #&sysSystem( $command, $fhTraceLoc );
    return(0,"*** ERROR $sbr '$Lok'\n".$msg."\n".$msgSys)
	if (! $Lok);
    return(0,"*** ERROR $sbr no output '$fileOutLoc'\n"."$msg")
	if (! -e $fileOutLoc);

				# ------------------------------
				# convert blast output to SAF
				# ------------------------------
  
    $command="$niceLoc $exeBlast2Saf fileInBlast=$fileOutLoc fileInQuery=$fileFasta ".
	"fileOutRdb=$fileOutRdb fileOutSaf=$fileOutSaf red=$blastFilThre ".
	    "maxAli=$blastMaxAli tile=$blastTile fileOutErr=$fileTraceBlast ";
    

    $msg.="--- $sbr '$command'\n";

    ($Lok,$Lsystem)=
	&sysSystem("$command" ,$fhTraceLoc);

    if ( -f $fileTraceBlast and -s $fileTraceBlast ) {
	$msgSys = `cat $fileTraceBlast`;
    } else {
	$msgSys ="";
    }

    return(0, "*** ERROR $sbr '$Lok'\n".$msg."\n".$msgSys)
	if (!$Lok || $Lsystem);
    return(0,"*** ERROR $sbr no output '$fileOutSaf'\n".$msg."\n".$msgSys)
	if (! -e $fileOutSaf);

    return (2,"none found")	# no hits found
	if ( $msgSys =~ /no hits found/i );	
    return(1,"ok $sbr");
}				# end of blastpsiRun

#==============================================================================
sub coilsRd {
    local($fileInLoc,$fhErrSbr) = @_ ;
    local($sbrName,$fhinLoc,@tmp,$numCoil,$maxCoil,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   coilsRd                     reads the column format of coils
#       in:                     $fileInLoc,$fileOutLoc,$probMinLoc,$fhErrSbr
#         $fileInLoc            file with COILS output (column format expected)
#         $probMinLoc           minimal probability (otherwise returns '2,$msg')
#       out:                    fileOut
#       err:                    (0,$err), (1,'ok '), (2,'info...') -> not Coils
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."coilsRd";$fhinLoc="FHOUT"."$sbrName";$fhoutLoc="FHOUT"."$sbrName";
				# ------------------------------
				# open COILS output
    $Lok=       &open_file("$fhinLoc","$fileInLoc");

    $maxCoil = 0;
    $fileTmpOutLoc = $fileInLoc.'_tmp';
    return(0,"*** ERROR $sbrName: '$fileInLoc' not opened\n") if (! $Lok);

#    $seq=$win[1]=$win[2]=$win[3]="";
#    $max[1]=$max[2]=$max[3]=0;
#    $sum[1]=$sum[2]=$sum[3]=0;
#    $ptr[1]=14;$ptr[2]=21;$ptr[3]=28;
#    while (<$fhinLoc>) {
#	last if ($_=~/^\s*[\.]+/);}

    while (<$fhinLoc>) {	# 

#	$_=~s/\n//g;$_=~s/^\s*|\s*$//g; # 
#	@tmp=split(/\s+/,$_);
#	next if ($#tmp<11);
#	$seq.="$tmp[2]";
##	$sum[1]+=$tmp[5]; $sum[2]+=$tmp[8];  $sum[3]+=$tmp[11];  
#	$win[1].="$tmp[5],";  $max[1]=$tmp[5]  if ($tmp[5]> $max[1]);
#	$win[2].="$tmp[8],";  $max[2]=$tmp[8]  if ($tmp[8]> $max[2]);
#	$win[3].="$tmp[11],"; $max[3]=$tmp[11] if ($tmp[11]>$max[3]);
	if ( /^window/ ) {
	    @tmp = split /\s+/;
	    $numCoil = $tmp[5];
	    if ($numCoil > $maxCoil) {
		$maxCoil = $numCoil;
	    }
	} else {
	    next;
	}
    }
    close($fhinLoc);
				# ------------------------------
				# none above threshold
    return (2,"none above threshold \n")
	if ( $maxCoil == 0 );  
				# ------------------------------
				# find ma
#    ($max,$pos)=&get_max($max[1],$max[2],$max[3]);
#    foreach $itw (1..3){
#	@tmp=split(/,/,$win[$itw]);
#	return(0,"*** ERROR $sbrName: couldnt read coils format $fileInLoc\n")
#	    if ($#tmp>length($seq));
#	$val[$itw]="";
#	foreach $it(1..$#tmp){	# prob to 0-9
#	    $tmp=int(10*$tmp[$it]); $tmp=9 if ($tmp>9);$tmp=0 if ($tmp<0);
#	    $val[$itw].="$tmp";}}
				# ------------------------------
				# write new output file
    $Lok=       &open_file("$fhoutLoc",">$fileTmpOutLoc");
    return(0,"*** ERROR $sbrName: new '$fileTmpOutLoc' not opened\n") if (! $Lok);
    print $fhoutLoc  "\n";
    print $fhoutLoc  "--- COILS HEADER: SUMMARY\n\n";
    print $fhoutLoc "COILS version 2.2: R.B. Russell, A.N. Lupas, 1999\n";
    print $fhoutLoc "using MTIDK matrix.\n";
    print $fhoutLoc "weights: a,d=2.5 and b,c,e,f,g=1.0\n\n";
    print $fhoutLoc "For the threshold of 5 ( probability > 0.5):\n";
#    print $fhoutLoc  "--- best window has width of $ptr[$pos]\n";
#    print $fhoutLoc  "--- \n";
#    print $fhoutLoc  "--- COILS: SYMBOLS AND EXPLANATIONS ABBREVIATIONS\n";
#    printf $fhoutLoc "--- %-12s : %-s\n","seq","one-letter amino acid sequence";
#    printf $fhoutLoc 
#	"--- %-12s : %-s\n","normWin14","window=14, normalised prob [0-9], 9=high, 0=low";
#    printf $fhoutLoc 
#	"--- %-12s : %-s\n","normWin21","window=21, normalised prob [0-9], 9=high, 0=low";
#    printf $fhoutLoc 
#	"--- %-12s : %-s\n","normWin28","window=28, normalised prob [0-9], 9=high, 0=low";
#    print $fhoutLoc "--- \n";
#    for ($it=1;$it<=length($seq);$it+=50){
#	printf $fhoutLoc "COILS %-10s %-s\n","   ",  &myprt_npoints(50,$it);
#	printf $fhoutLoc "COILS %-10s %-s\n","seq",  substr($seq,$it,50);
#	foreach $itw(1..3){
#	    printf $fhoutLoc
#	
#	"COILS %-10s %-s\n","normWin".$ptr[$itw],substr($val[$itw],$it,50);}}
	
    close $fhoutLoc; 

    system ("cat $fileInLoc >> $fileTmpOutLoc") and 
	return( 0, "*** ERROR $sbrName: cannot append output file to summary\n");
    rename ($fileTmpOutLoc, $fileInLoc) or 
	return( 0, "*** ERROR $sbrName: cannot move tmp_summary to summary.\n");
    return(1,"ok $sbrName");
}				# end of coilsRd

#==============================================================================
sub coilsRun {
    local($fileInLoc,$fileOutLoc,$fileRawLoc,$exeCoilsLoc,$metricLoc,$weightLoc,
	  $fhErrSbr,$fileScreenLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   coilsRun                    runs the COILS program from Andrei Lupas
#       in:                     $fileIn,$exeCoils,$metric,$optOut,$fileOut,$fhErrSbr
#       in:                     NOTE if not defined arg , or arg=" ", then defaults
#       out:                    write into file (0,$err), (1,'ok ')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."coilsRun";$fhinLoc="FHIN"."$sbrName";

    return(0,"*** $sbrName: not def fileInLoc!")      if (! defined $fileInLoc);
    return(0,"*** $sbrName: not def fileOutLoc!")     if (! defined $fileOutLoc);
    return(0,"*** $sbrName: not def exeCoilsLoc!")    if (! defined $exeCoilsLoc);
    return(0,"*** $sbrName: not def metricLoc!")      if (! defined $metricLoc);
#    return(0,"*** $sbrName: not def optOutLoc!")      if (! defined $optOutLoc);
    $fhErrSbr="STDOUT"                                if (! defined $fhErrSbr);
    $fileScreenLoc=0                                  if (! defined $fileScreenLoc);

    return(0,"*** $sbrName: no in file $fileInLoc")   if (! -e $fileInLoc);
    $exeCoilsLoc="/home/$ENV{USER}/bin/".$ARCH."/coils"      if (! -e $exeCoilsLoc && defined $ARCH);
    $exeCoilsLoc="/home/$ENV{USER}/bin/SGI64/coils"          if (! -e $exeCoilsLoc && ! defined $ARCH); # HARD_CODED
    return(0,"*** $sbrName: no in exe  $exeCoilsLoc") if (! -e $exeCoilsLoc);
    $metricLoc=  "MTIDK"                                if (! -e $metricLoc); # metric 1
    $metricLoc= " -m ".$metricLoc." ";
    
#    $metricLoc=  "MTIDK"                              if (! -e $metricLoc); # metric 2
#    $optOutLoc=  "col"                                if (! -e $optOutLoc);
#    $optOutLoc=  "row"                                if (! -e $optOutLoc);
#    $optOutLoc=  "row"                                if (! -e $optOutLoc);

				# metric
#    if    ($metricLoc eq "MTK")  {$met="1";}
#    elsif ($metricLoc eq "MTIDK"){$met="2";}
#    else  {
#	return(0,"*** ERROR $scrName metric=$metricLoc, must be 'MTK' or 'MTIDK' \n");}
#				# output option
#    if    ($optOutLoc eq "col")  {$opt="p";}
#    elsif ($optOutLoc eq "row")  {$opt="a";}
#    elsif ($optOutLoc =~/cut/)   {
#	$opt="b";
#	return(0,"-*- ERROR $scrName optOut=$optOut, not yet implemented\n");}
#    elsif ($optOutLoc =~/win/)   {
#	$opt="c";
#	return(0,"-*- ERROR $scrName optOut=$optOut, not yet implemented\n");}
#    else {
#	return(0,"*** ERROR $scrName optOut=$optOut no known\n");}
#    $an=                       "N"; # no weight for position a & d
#    $an=                       "Y"; # weight for position a & d

    if ( $weightLoc eq "Y" ) {
	$weightLoc = " -w ";
    } else {
	$weightLoc = "";
    }
    eval "\$cmd=\"$exeCoilsLoc $metricLoc $weightLoc -i $fileInLoc -o $fileOutLoc -r $fileRawLoc \"";
    ($Lok,$msg)=
	&sysRunProg($cmd,$fileScreenLoc,$fhErrSbr);

    return(0,"*** ERROR $sbrName: failed to create $fileOutLoc\n".$msg)
	if (! $Lok || ! -e $fileOutLoc);
    return(1,"ok $sbrName");
}				# end of coilsRun

#==============================================================================
sub complete_dir { return(&completeDir(@_)); } # alias

#===============================================================================
sub completeDir {local($DIR)=@_; $[=1 ; 
		 return(0) if (! defined $DIR);
		 return($DIR) if ($DIR =~/\/$/);
		 return($DIR."/");} # end of completeDir

#==============================================================================
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

#==============================================================================
sub convHssp2msf {
    local($exeConvLoc,$file_in_loc,$file_out_loc,$LdoExpandLoc,$fhErrSbr,$fileScreenLoc)=@_;
    local($form_out,$an,$command);
#----------------------------------------------------------------------
#   convHssp2msf                runs convert_seq for HSSP -> MSF
#       in:                     $exeConvLoc,$file_in_loc,$file_out_loc,$fhErrSbr
#       in:                     FORTRAN file.hssp, file.msf (name output), errorHandle
#       out:                    fileHssp (written by convert_seq)
#       err:                    ok=(1,'ok'), err=(0,'msg')
#----------------------------------------------------------------------
    $sbrName="lib-col:convHssp2msf";
    $fhErrSbr="STDOUT"                                if (! defined $fhErrSbr);
    return(0,"*** $sbrName: not def exeConvLoc!")     if (! defined $exeConvLoc);
    return(0,"*** $sbrName: not def file_in_loc!")    if (! defined $file_in_loc);
    return(0,"*** $sbrName: not def file_out_loc!")   if (! defined $file_out_loc);
    return(0,"*** $sbrName: not def=LdoExpandLoc!")   if (! defined $LdoExpandLoc);
				# check existence of files
    return(0,"*** $sbrName: miss file=$file_in_loc!") if (! -e $file_in_loc);
    return(0,"*** $sbrName: miss exe =$exeConvLoc!")  if (! -e $exeConvLoc);
    $fhErrSbr=0                                       if (! defined $fhErrSbr);
    $fileScreenLoc=0                                  if (! defined $fileScreenLoc);
				# ------------------------------
				# input for fortran program
    $form_out= 	 "M";
    $anExpand=   "N";
    $anExpand=   "Y"            if ($LdoExpandLoc);
    $anNew=      "N";
    $command=    "";
				# --------------------------------------------------
				# call fortran 
    eval "\$command=\"$exeConvLoc,$file_in_loc,$form_out,$an,$file_out_loc,$anExpand,$anNew\"";
    ($Lok,$msg)=
	&sysRunProg($command,$fileScreenLoc,$fhErrSbr);
#    $Lok=&run_program("$command" ,"$fhErrSbr","warn");

#    $command="echo '$file_in_loc\n".
#	"$form_out\n"."$an\n"."$file_out_loc\n"."$an\n"."$an\n".
#	    "' | $exeConvLoc";
#    $fhErrSbr=`$command`;

    return(0,"*** $sbrName ERROR: no output $file_out_loc ($exeConvLoc,$file_in_loc)\n")
	if (!$Lok || (! -e $file_out_loc));
    return(1,"$sbrName ok");
}				# end of convHssp2msf

#===============================================================================
sub convMsf2HsspNew {
    local($fileMsfLoc,$fileHsspLoc,$fileCheck,
	  $exeCopfLoc,$exeConvertSeqLoc,$matGCG,
	  $dirWorkLoc,$fileJobIdLoc,$niceLoc,$LdebugLoc,$fhErrSbrx) = @_ ;
    local($sbrName2,$Lok,$fhinLoc,$form_out,$an,$cmd,$msgHereLoc);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   convMsf2HsspNew             converts the MSF into an HSSP file
#       in:                     fileMsf, fileHssp(output), exeCopf,exeConv (convert_seq), matGCG
#       out:                    fileHssp (written by convert_seq)
#       err:                    ok=(1,'ok'), err=(0,'msg')
#--------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName2=$tmp.":convMsf2Hssp";$fhinLoc="FHIN"."$sbrName";
				# check definitions
    return(0,"*** $sbrName: not def fileMsfLoc!")       if (! defined $fileMsfLoc);
    return(0,"*** $sbrName: not def fileHsspLoc!")      if (! defined $fileHsspLoc);
    return(0,"*** $sbrName: not def fileCheck!")        if (! defined $fileCheck);
    return(0,"*** $sbrName: not def exeCopfLoc!")       if (! defined $exeCopfLoc);
    return(0,"*** $sbrName: not def exeConvertSeqLoc!") if (! defined $exeConvertSeqLoc);
    return(0,"*** $sbrName: not def matGCG!")           if (! defined $matGCG);
    return(0,"*** $sbrName: not def dirWorkLoc!")       if (! defined $dirWorkLoc);
    return(0,"*** $sbrName: not def fileJobIdLoc!")     if (! defined $fileJobIdLoc);
    return(0,"*** $sbrName: not def niceLoc!")          if (! defined $niceLoc);
    return(0,"*** $sbrName: not def LdebugLoc!")        if (! defined $LdebugLoc);
    $fhErrSbrx="STDOUT"                                 if (! defined $fhErrSbrx);
				# check existence of files
    return(0,"*** $sbrName: no in file=$fileMsfLoc!")       if (! -e $fileMsfLoc);
    return(0,"*** $sbrName: no in  exe=$exeConvertSeqLoc!") if (! -e $exeConvertSeqLoc);
    return(0,"*** $sbrName: no in file=$matGCG!")           if (! -e $matGCG);
    $msgHereLoc="";

				# ------------------------------
				# screen file names
    $titleTmp=$dirWorkLoc.$fileJobIdLoc; 
    $titleTmp="tmp_convMsf2HsspNew" if (length($titleTmp) < 1);
    $file_copfScreenFor=        $titleTmp.".copfScreenFor";
    $file_copfTrace=            $titleTmp.".copfTrace";    
    $file_copfScreen=           $titleTmp.".copfScreen";   
				# build up command
    $cmd= $niceLoc." ".$exeCopfLoc;
    $cmd.=" ".$fileMsfLoc." "."hssp"." fileOut=".$fileHsspLoc;
    $cmd.=" exeConvertSeq=".$exeConvertSeqLoc." fileMatGcg=$matGCG";
    $cmd.=" fileOutScreen=".$file_copfScreen." fileOutTrace=".$file_copfTrace." dbg";
    $cmd.=" >> ".$file_copfScreen;
#    $msgHereLoc="\n--- $sbr \t $cmd\n";
    print $fhErrSbrx "--- $sbrName2 system \t",$cmd,"\n" if ($LdebugLoc);
				# system call
    system("$cmd");

    $Lok=1;
    $Lok=0                      if (! -e $fileHsspLoc);
    $Lok=-1                     if ($Lok && &is_hssp_empty($fileHsspLoc));
				# ------------------------------
				# conversion failed!
    if ($Lok < 1) {
				# trace file
	if (-e $file_copfTrace)     { 
	    $msgHereLoc.="--- $sbrName2 copf trace file $file_copfTrace\n";
	    open(FHINTMP,$file_copfTrace); $msgHereLoc.=<FHINTMP>; close(FHINTMP); }
				# screen dump from COPF
	if (-e $file_copfScreenFor) { 
	    $msgHereLoc.="--- $sbrName2 copf screen file $file_copfScreenFor\n";
	    open(FHINTMP,$file_copfScreenFor); $msgHereLoc.=<FHINTMP>; close(FHINTMP); } }
				# dump screen output in any case!
    $msgHereLoc.="--- $sbrName2 copf screen out $file_copfScreen\n";
    open(FHINTMP,$file_copfScreen);   
    while(<FHINTMP>){
	print $_                if (! $LdebugLoc);
	$msgHereLoc.=$_;}close(FHINTMP);  
    if ($Lok < 1) {
	$tmpError= "*** ERROR $sbrName: failed conversion (copf) of MSF 2 HSSP\n";
	$tmpError.="***       \t no output file ($fileHsspLoc)\n"    if ($Lok == 0);
	$tmpError.="***       \t empty output file ($fileHsspLoc)\n" if ($Lok < 0);
	return(0,"*** ERROR $sbrName: failed conversion (copf) of MSF 2 HSSP\n".
	       $tmpError,$msgHereLoc."\n"); }

				# --------------------------------------------------
                                # reconvert MSF -> HSSP
				# --------------------------------------------------
    $msgHere.="$sbrName2: reconverting HSSP ($fileHsspLoc) -> MSF for check\n";

    $file_copfScreenFor=        $titleTmp.".copfScreenFor";
    $file_copfTrace=            $titleTmp.".copfTrace";    
    $file_copfScreen=           $titleTmp.".copfScreen";   
				# build up command
    $cmd= $niceLoc." ".$exeCopfLoc;
    $cmd.=" ".$fileHsspLoc." "."msf"." fileOut=".$fileCheck;
    $cmd.=" exeConvertSeq=".$exeConvertSeqLoc;
    $cmd.=" fileOutScreen=".$file_copfScreen." fileOutTrace=".$file_copfTrace." dbg";
    $cmd.=" >> ".$file_copfScreen;
#    $msgHereLoc="\n--- $sbr \t $cmd\n";
    print $fhErrSbrx "--- $sbrName2 system \t",$cmd,"\n" if ($LdebugLoc);
				# system call
    system("$cmd");

    $Lok=1;
    $Lok=0                      if (! -e $fileCheck);
				# ------------------------------
				# conversion failed!
    if (! $Lok) {
				# trace file
	if (-e $file_copfTrace)     { 
	    $msgHereLoc.="--- $sbrName2 copf trace file $file_copfTrace\n";
	    open(FHINTMP,$file_copfTrace); $msgHereLoc.=<FHINTMP>; close(FHINTMP); }
				# screen dump from COPF
	if (-e $file_copfScreenFor) { 
	    $msgHereLoc.="--- $sbrName2 copf screen file $file_copfScreenFor\n";
	    open(FHINTMP,$file_copfScreenFor); $msgHereLoc.=<FHINTMP>; close(FHINTMP); } }
				# dump screen output in any case!
    $msgHereLoc.="--- $sbrName2 copf screen out $file_copfScreen\n";
    open(FHINTMP,$file_copfScreen);   
    while(<FHINTMP>){
	$msgHereLoc.=$_;}close(FHINTMP);  
    if (! $Lok) {
	$tmpError= "*** ERROR $sbrName: failed conversion (copf) of HSSP 2 MSF\n";
	return(0,$tmpError,$msgHereLoc."\n"); }

				# ------------------------------
				# delete files
    foreach $file ($file_copfScreenFor,$file_copfTrace,$file_copfScreen) {
	next if (! defined $file || ! -e $file);
	print $fhErrSbrx "--- $sbrName2 unlink ($file)\n" if ($LdebugLoc);
	unlink($file); }
		
				# --------------------------------------------------
                                # comparing the two files
				# --------------------------------------------------
    open(FILE1,$fileMsfLoc)  ||  warn "-*- $sbrName2: cannot open 1 $fileMsfLoc: $!\n";
    open(FILE2,$fileCheck)   ||  warn "-*- $sbrName2: cannot open 1 $fileCheck: $!\n";
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
		$msgHere.="*** $sbrName2 ERROR: during re-converting comparison\n".
		    "tmp2=$tmp2,count_error=$count_error\n";}}}
    if ( $count_error gt 3 ) {
	$msgHere.="conversion: MSF -> HSSP failed, \n".$msgHere;
	return(0,$msgHere); }
    return(1,"$sbrName2 ok");
}				# end convMsf2HsspNew

#==============================================================================
sub convMsf2Hssp {
    local($fileMsfLoc,$fileHsspLoc,$fileCheck,$exeConvLoc,$matGCG,$fhErrSbrx) = @_ ;
    local($sbrName,$Lok,$fhinLoc,$form_out,$an,$command);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   convMsf2Hssp                converts the MSF into an HSSP file
#                               NOTE: use McLachlan for similarity!!!
#       in:                     fileMsf, fileHssp(output), exeConv (convert_seq), matGCG
#       out:                    fileHssp (written by convert_seq)
#       err:                    ok=(1,'ok'), err=(0,'msg')
#--------------------------------------------------------------------------------
    $sbrName="lib-col:convMsf2Hssp";$fhinLoc="FHIN"."$sbrName";
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
    $LdoExpandLoc=0;
    ($Lok,$msg)=
	&convHssp2msf($exeConvLoc,$fileHsspLoc,$fileCheck,$LdoExpandLoc);

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
}				# end convMsf2Hssp

#==============================================================================
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
    $sbrName="lib-col:convPhd2col";
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
				# lib-col
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

#==============================================================================
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
    $sbrName="lib-col:convSeq2Fasta";
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
sub date_monthName2num {
    local($txtIn) = @_ ;
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   date_monthName2num          converts month name to number
#       in:                     $month
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."date_monthName2num";
    return(1,"ok","01") if ($txtIn=~/^jan/i);
    return(1,"ok","02") if ($txtIn=~/^feb/i);
    return(1,"ok","03") if ($txtIn=~/^mar/i);
    return(1,"ok","04") if ($txtIn=~/^apr/i);
    return(1,"ok","05") if ($txtIn=~/^may/i);
    return(1,"ok","06") if ($txtIn=~/^jun/i);
    return(1,"ok","07") if ($txtIn=~/^jul/i);
    return(1,"ok","08") if ($txtIn=~/^aug/i);
    return(1,"ok","09") if ($txtIn=~/^sep/i);
    return(1,"ok","10") if ($txtIn=~/^oct/i);
    return(1,"ok","11") if ($txtIn=~/^nov/i);
    return(1,"ok","12") if ($txtIn=~/^dec/i);
    return(0,"month=$txtIn, is what??",0);
}				# end  date_monthName2num

#==============================================================================
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

#==============================================================================
sub dsspGetFileLoop { 
    local ($fileInLoop,$Lscreen,@dir) = @_ ; 
    local ($dir,$tmp);
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

#==============================================================================
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
    $sbrName = "lib-col:dsspRdSeq" ;$fhin="fhinDssp";
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

#==============================================================================
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
				# SQRT
    $exp_out= int ( sqrt ($exp_in) );
                                # saturation: limit to 9
    $exp_out= 9  if ( $exp_out >= 10 );
    $exposure_project_1digit = $exp_out;
    return($exp_out);
}				# end of exposure_project_1digit

#==============================================================================
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

#==============================================================================
sub fastaRun {
    local($niceLoc,$dirData,$exeFasta,$exeFastaFil,$envFastaLibs,$numHits,
	  $parFastaThresh,$parFastaScore,$parFastaSort,
	  $fileInLoc,$fileOutLoc,$fileOutFilLoc,$fhTraceLoc)=@_;
    local($sbr,$command,$msg,$Lok);
#----------------------------------------------------------------------
#   fastaRun                    runs FASTA
#       in:                     $niceLoc,$dirData,$exeFasta,$exeFastaFil,$envFastaLibs,
#       in:                     $numHits,$parFastaThresh,$parFastaScore,$parFastaSort,
#       in:                     $fileInLoc,$fileOutLoc,$fileOutFilLoc,$fhTraceLoc
#       out:                    
#       err:                    ok=(1,'ok'), err=(0,'msg')
#----------------------------------------------------------------------
    $sbr="lib-col:fastaRun";
    $fhTraceLoc="STDOUT"                              if (! defined $fhTraceLoc);
    return(0,"*** $sbr: not def niceLoc!")         if (! defined $niceLoc);
    return(0,"*** $sbr: not def dirData!")         if (! defined $dirData);
    return(0,"*** $sbr: not def exeFasta!")        if (! defined $exeFasta);
    return(0,"*** $sbr: not def exeFastaFil!")     if (! defined $exeFastaFil);
    return(0,"*** $sbr: not def envFastaLibs!")    if (! defined $envFastaLibs);
    return(0,"*** $sbr: not def numHits!")         if (! defined $numHits);
    return(0,"*** $sbr: not def parFastaThresh!")  if (! defined $parFastaThresh);
    return(0,"*** $sbr: not def parFastaScore!")   if (! defined $parFastaScore);
    return(0,"*** $sbr: not def parFastaSort!")    if (! defined $parFastaSort);
    return(0,"*** $sbr: not def fileInLoc!")       if (! defined $fileInLoc);
    return(0,"*** $sbr: not def fileOutLoc!")      if (! defined $fileOutLoc);
    return(0,"*** $sbr: not def fileOutFilLoc!")   if (! defined $fileOutFilLoc);

    return(0,"*** $sbr: miss dir =$dirData!")      if (! -d $dirData);

    return(0,"*** $sbr: miss file=$fileInLoc!")    if (! -e $fileInLoc);
    return(0,"*** $sbr: miss file=$envFastaLibs!") if (! -e $envFastaLibs);
    return(0,"*** $sbr: miss exe =$exeFasta!")     if (! -e $exeFasta);
    return(0,"*** $sbr: miss exe =$exeFastaFil!")  if (! -e $exeFastaFil);

				# ------------------------------
				# set environment needed for FASTA
    $ENV{'FASTLIBS'}=$envFastaLibs;
    $ENV{'LIBTYPE'}= "0";
                                # ------------------------------
                                # run FASTA
                                # ------------------------------
    eval "\$command=\"$niceLoc $exeFasta -b 500 -d 500 -o > $fileOutLoc ,
                       $fileInLoc , S , 1 , $fileOutLoc , $numHits , 0 , \"";
    $msg="--- $sbr '$command'\n";

    $Lok=
	&run_program("$command" ,"$fhTraceLoc","warn");
    if (!$Lok){
	return(0,"*** ERROR $sbr '$Lok'\n"."$msg");}
    if (! -e $fileOutLoc){
	return(0,"*** ERROR $sbr no output '$fileOutLoc'\n"."$msg");}
                                # ----------------------------------------
                                # extract possible hits from fasta-output
                                # ----------------------------------------
    eval "\$command=\"$niceLoc $exeFastaFil  ,$fileOutLoc,$fileOutFilLoc
                      $parFastaThresh,$parFastaScore,$parFastaSort, \"";
    $Lok=
	&run_program("$command" ,"$fhTraceLoc","warn");
    if (!$Lok){
	return(0,"*** ERROR $sbr '$Lok'\n"."$msg");}
    if (! -e $fileOutFilLoc){
	return(0,"*** ERROR $sbr no output '$fileOutFilLoc'\n"."$msg");}
    return(1,"ok $sbr");
}				# end of fastaRun

#==============================================================================
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
    $sbrName="lib-col:fastaWrt";$fhoutLoc="FHOUT_"."$sbrName";
#   print "yy into write seq=$seqLoc,\n"x10;

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
#       out:                    $Lok,$msg,%fileFound
#                               $fileFound{"NROWS"}=      number of files found
#                               $fileFound{"ct"}=         name-of-file-ct
#                               $fileFound{"format","ct"}=format
#                               $fileFound{"chain","ct"}= chain
#-------------------------------------------------------------------------------
    $sbrName="lib-col:"."getFileFormat";$fhinLoc="FHIN"."$sbrName";
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
	$fileLoc{"$it"}=$fileLoc[$it];
	$fileLoc{"format","$it"}=$formatLoc[$it];
	if ((defined $chainLoc[$it])&&
	    (length($chainLoc[$it])>0)&&($chainLoc[$it]=~/[A-Za-z0-9]/)){
	    $fileLoc{"chain","$it"}=$chainLoc[$it];}}
    $fileLoc{"NROWS"}=$#fileLoc;
    return(1,"ok",%fileLoc);
}				# end of getFileFormat

#==============================================================================
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

#==============================================================================
sub get_max { $[=1;local($ct,$pos,$max);$max=-1000000;$ct=$pos=0; 
#----------------------------------------------------------------------
#   get_max                     returns the maximum of all elements of @in
#       in:                     @in
#       out:                    returned $max,$pos (position of maximum)
#----------------------------------------------------------------------
	      foreach $_(@_){if(defined $_){
		  ++$ct; 
		  if($_>$max){$max=$_;$pos=$ct;}}}
	      return ($max,$pos); } # end of get_max


#==============================================================================
sub get_min { $[=1;local($ct,$pos,$min);$min=100000; $ct=0; 
#----------------------------------------------------------------------
#   get_min                     returns the minimum of all elements of @in
#       in:                     @in
#       out:                    returned $min,$pos (position of minimum)
#----------------------------------------------------------------------
	      foreach $_(@_){++$ct; if($_<$min){$min=$_;$pos=$ct;}}
	      return ($min,$pos); } # end of get_min


#==============================================================================
sub get_range {
    local ($range_txt,$nall) = @_;
    local (@range,@rangeLoc,$it,$range1,$range2);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   get_range                   converts range=n1-n2 into @range (1,2)
#       in:                     'n1-n2' NALL: e.g. incl=1-5,9,15 
#                               n1= begin, n2 = end, * for wild card
#                               NALL = number of last position
#       out:                    @takeLoc: begin,begin+1,...,end-1,end
#--------------------------------------------------------------------------------
    $#range=0;
    if (! defined $range_txt || length($range_txt)<1 || $range_txt eq "unk" 
	|| $range_txt !~/\d/ ) {
	print "*** ERROR in get_range: argument: range=$range_txt, nall=$nall, not digestable\n"; 
	return(0);}
    $range_txt=~s/\s//g;	# purge blanks
    $nall=0                     if (! defined $nall);
				# already only a number
    return($range_txt)          if ($range_txt !~/[^0-9]/);
    
    if ($range_txt !~/[\-,]/) {	# no range given
	print "*** ERROR in get_range: argument: '$range_txt,$nall' not digestable\n"; 
	return(0);}
				# ------------------------------
				# dissect commata
    if    ($range_txt =~ /\,/) {
	@range=split(/,/,$range_txt);}
				# ------------------------------
				# dissect hyphens
    elsif ($range_txt =~ /(\d*|\*)-(\d*|\*)/) { 
	@range=&get_rangeHyphen($range_txt,$nall);}

				# ------------------------------
				# process further elements with hyphens
    $#range2=0;
    foreach $range (@range){
	if ($range =~ /(\d*|\*)-(\d*|\*)/) {
	    push(@range2,&get_rangeHyphen($range,$nall));}
	else {
            push(@range2,$range);}}
    @range=@range2; $#range2=0;
				# ------------------------------
    if ($#range>1){		# sort
	@range=sort {$a<=>$b} @range;}
    return (@range);
}				# end of get_range

#==============================================================================
sub get_rangeHyphen {
    local ($range_txt,$nall) = @_ ;
    local (@rangeLoc,$it,$range1,$range2);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   get_rangeHyphen             reads 'n1-n2'  
#       in:                     'n1-n2', NALL (n1= begin, n2 = end, * for wild card)
#                               NALL = number of last position
#       out:                    begin,begin+1,...,end-1,end
#--------------------------------------------------------------------------------
    if ($range_txt =~ /(\d*|\*)-(\d*|\*)/) { 
	($range1,$range2)=split(/-/,$range_txt);
	if ($range1=~/\*/) {$range1=1;}
	if ($range2=~/\*/) {$range2=$nall;} 
	for($it=$range1;$it<=$range2;++$it) {push(@rangeLoc,$it);} }
    else { @rangeLoc=($range_txt);}
    return(@rangeLoc);
}				# end of get_rangeHyphen

#===============================================================================
sub getFileFromArray {
    local($kwdInLoc,$LcaseIndependent,$fileListInLoc,$dirListInLoc) = @_ ;
    local($sbrName,@fileInLoc,@dirInLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getFileFromArray            finds the file associated to 'keyword' from the
#                               array of files (return 1,'ok',0 if none found!)
#       in:                     $keyword        name of file to find 
#                                               e.g. blosum in Maxhom_Blosum.metr
#       in:                     $LcaseIndependent=<1|0> if 1: search case independent
#                                               blosum matches BLOSum ..
#       in:                     $fileList       files to search, many=
#                                  'file1,file2'
#       in:                     $dirList        directories to try: 
#                                  'dir1,dir2,dir3'
#       out:                    1|0,msg,($file|0=>none found!)
#       err:                    (1,'ok',$file), (0,'message',0)
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";$sbrName=$tmp."getFileFromArray";
				# check arguments
    return(&errSbr("not def kwdInLoc!"))         if (! defined $kwdInLoc);
    return(&errSbr("not def LcaseIndependent!")) if (! defined $LcaseIndependent);
    return(&errSbr("not def fileListInLoc!"))    if (! defined $fileListInLoc);
    $dirListInLoc=""                             if (! defined $dirListInLoc);
				# set 0
    $fileFoundLoc=$#fileInLoc=$#dirInLoc=0;
    $fileListInLoc=~s/^,|,$//g;
    $dirListInLoc=~s/^,|,$//g   if (defined $dirListInLoc);
				# search case independent!
    $kwdInLoc=~tr/[A-Z]/[a-z]/  if ($LcaseIndependent);

				# ------------------------------
				# (1) split file and dir list
    @fileInLoc=split(/,/,$fileListInLoc);
    @dirInLoc=("");		# first one empty: no dir search
    push(@dirInLoc,split(/,/,$dirListInLoc)) if (defined $dirListInLoc);
				# <--- <--- <--- <---
				# none found
    return(1,"none found",0)    if (! @fileInLoc);
				# <--- <--- <--- <---

				# ------------------------------
				# (2) loop over all 
    foreach $file (@fileInLoc) {
	foreach $dir (@dirInLoc) {
	    $file=~s/^.*\///g   if (length($dir)>=1);                # strip dir from file
	    $dir.="/"           if (length($dir)>=1 && $dir!~/\/$/); # append slash
	    $fileTmp=$dir.$file; # file to take
	    $fileTmp2=$fileTmp;
				# skip non-existing files
	    next if (! -e $fileTmp);
				# search case independent!
	    $fileTmp2=~tr/[A-Z]/[a-z]/  if ($LcaseIndependent);
	    if ($fileTmp2=~/$kwdInLoc/) {
				# (-: (-: (-: (-: (-: 
				# ok one found, go home
		return(1,"ok",$fileTmp); }
	}}
				# ------------------------------
				# (3) note: coming here means:
				#           none FOUND!!
    return(1,"ok $sbrName",$fileFoundLoc);
}				# end of getFileFromArray

#==============================================================================
sub globeFuncFit {
    local($lenIn,$add,$fac,$expLoc) = @_ ;local($tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   globeFuncFit                length to number of surface molecules fitted to PHD error 
#                               out=(N ^ 1/3 - 2) ^ 3
#       in:                     len, acc-cut-off (allowed: 9, 16)
#       out:                    1,NsurfacePhdFit2
#       err:                    0,'msg'
#-------------------------------------------------------------------------------
    $expLoc=16 if (! defined $expLoc); # default
    if   ($expLoc == 9) {
	return(1,$lenIn - $fac*(($lenIn**(1/3)) - $add)**3);}
    elsif($expLoc == 16) {
	return(1,$lenIn - $fac*(($lenIn**(1/3)) - $add)**3);}
    else{ 
	return(0,"*** ERROR in $scrName globeFuncFit only defined for exp=16 or 9\n");}
}				# end of globeFuncFit

#==============================================================================
sub globeFuncJoinPhdSegIni {
    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   globeFuncJoinPhdSegIni      initialises the function used to apply the rule
#                               SEE globeFuncJoinPhdSeg for explanation! 
#       out GLOBAL:             $FUNC_LO_FAC,$FUNC_LO_ADD,$FUNC_HI_FAC,$FUNC_HI_ADD,
#                               $PHD_LO_NO,$PHD_HI_NO,$PHD_LO_OK,$PHD_HI_OK
#-------------------------------------------------------------------------------
    $sbrName="lib-col:"."globeFuncJoinPhdSegIni";
				# ------------------------------
				# PHD saturation
    $PHD_LO_NO= -0.10;		# if PHDnorm < $phdLoSat -> not globular
    $PHD_HI_NO=  0.20;		# if PHDnorm > $phdHiSat -> not globular

				# ------------------------------
				# PHD OK
    $PHD_LO_OK= -0.03;		# if $PHD_LO_OK < PHDnorm < $PHD_HI_OK -> IS globular
    $PHD_HI_OK=  0.15;		# if $PHD_LO_OK < PHDnorm < $PHD_HI_OK -> IS globular

				# ------------------------------
				# anchor points: SEG
    $segLo1=   50;
    $segLo2=  100;
    $segHi1=   80;
    $segHi2=  100;
				# ------------------------------
				# avoid warnings
    $FUNC_LO_FAC=$FUNC_LO_ADD=$FUNC_HI_FAC=$FUNC_HI_ADD=0;

				# ------------------------------
				# empirical function
				# ------------------------------
				# FAC = (y1 - y2) / (x1 - x2)
				# ADD = y1 - x1 * FAC
    $FUNC_LO_FAC= ($segLo2-$segLo1) / ($PHD_LO_NO-$PHD_LO_OK);
    $FUNC_LO_ADD= $segLo1 - $FUNC_LO_FAC * $PHD_LO_NO;

    $FUNC_HI_FAC= ($segHi2-$segHi1) / ($PHD_HI_NO-$PHD_HI_OK);
    $FUNC_HI_ADD= $segHi1 - $FUNC_HI_FAC * $PHD_HI_NO;
}				# end of globeFuncJoinPhdSegIni

#==============================================================================
sub globeOne {
    local($fileInLoc,$fhErrSbr,@passLoc)= @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   globe                       compiles the globularity for a PHD file
#       in:                     file.phdRdb, $fhErrSbr, (with ACC!!)
#       in:                     options as $kwd=value
#       in:                     logicals 'doFixPar', 'doReturn' will set the 
#       in:                        respective parameters to 1
#                               kwd=(lenMin|exposed|isPred|doFixPar
#                                    fit2Ave   |fit2Sig   |fit2Add   |fit2Fac|
#                                    fit2Ave100|fit2Sig100|fit2Add100|fit2Fac100)
#       in:                     doSeg=0       to ommit running SEG
#       in:                     fileSeg=file  to keep the SEG output
#       out:                    1,'ok',$len,$nexp,$nfit,$diff,$evaluation,
#                                      $globePhdNorm,$globePhdProb,
#                                      $segRatio,$LisGlobularCombi,$evaluationCombi
#                         note: $segRatio=         -1 if SEG did not run!
#                               $LisGlobularCombi= -1 if SEG did not run!
#                               $evaluationCombi=   0 if SEG did not run!
#       err:                    0,message
#-------------------------------------------------------------------------------
    $sbrName="lib-col:"."globe";$fhinLoc="FHIN"."$sbrName";
				# ------------------------------
				# (0) digest input arguments
    ($Lok,$msg)=
	&globeOneIni(@_); 
    return(&errSbrMsg("failed parsing input arguments\n",$msg)) if (! $Lok);
				# ------------------------------
				# (1) read file
    ($len,$numExposed,$seq)=
	&globeRd_phdRdb($fileInLoc,$fhErrSbr);
				# ERROR
    return(0,"*** ERROR $sbrName: numExposed=$numExposed (file=$fileInLoc)\n") 
	if (! $len || ! defined $numExposed || $numExposed =~/\D/);
    
				# ------------------------------
				# (2) get the expected number of res
    if (! $parSbr{"doFixPar"} && ($len < 100)){
	$fit2Add=$parSbr{"fit2Add100"};$fit2Fac=$parSbr{"fit2Fac100"};}
    else {
	$fit2Add=$parSbr{"fit2Add"};   $fit2Fac=$parSbr{"fit2Fac"};}

    ($Lok,$numExpect)=
	&globeFuncFit($len,$fit2Add,$fit2Fac,$parSbr{"exposed"});
				# reduce accuracy
    $numExpect=int($numExpect);
    $globePhdDiff=$numExposed-$numExpect;
				# reduce accuracy
    $globePhdDiff=~s/(\.\d\d).*$/$1/;
				# ------------------------------
				# (3) normalise
    $globePhdNorm=$globePhdDiff/$len;
				# reduce accuracy
    $globePhdNorm=~s/(\.\d\d\d).*$/$1/;

				# ------------------------------
				# (4) compile probability
    ($Lok,$msg,$globePhdProb)=
	&globeProb($globePhdNorm);
    return(&errSbrMsg("file=$fileInLoc, diff=$globePhdDiff, norm=$globePhdNorm\n".
		      "failed compiling probability\n",$msg)) if (! $Lok);
				# reduce accuracy
    $globePhdProb=~s/(\.\d\d\d).*$/$1/;
				# ------------------------------
				# (5) run SEG
				# ------------------------------
    if (length($seq) > 0 && $parSbr{"doSeg"} && -e $parSbr{"exeSeg"} && 
	(-x $parSbr{"exeSeg"} ||-l $parSbr{"exeSeg"} )) {
				# all variables in GLOBAL!
	($Lok,$msg,$segRatio,$LisGlobular,$evaluationCombi)=
	    &globeOneCombi();
				# no ERROR, just write!
	if (! $Lok) { print "*** ERROR globeOne: failed on globeOneCombi\n",$msg,"\n";
		      print "***      input file was=$fileInLoc,\n";
		      print "***      will return BAD values for SEG and combi!!\n";
		      $segRatio=      -1;
		      $LisGlobular=   -1;
		      $evaluationCombi=0; }}
    else { $segRatio=      -1;
	   $LisGlobular=   -1;
	   $evaluationCombi=0;
	   &globeFuncJoinPhdSegIni(); # get: $PHD_LO_NO,$PHD_HI_NO,$PHD_LO_OK,$PHD_HI_OK
    }

				# ------------------------------
				# evaluate the result (PHD only)
    if    ($PHD_HI_NO    >  $globePhdNorm && $globePhdNorm >  $PHD_HI_OK){
	$evaluation="your protein may be globular, but it is not as compact as a domain";}
    elsif ($PHD_LO_OK    <= $globePhdNorm && $globePhdNorm <= $PHD_HI_OK){
	$evaluation="your protein appears as compact, as a globular domain";}
    elsif ($globePhdNorm <= $PHD_LO_NO    || $globePhdNorm >= $PHD_HI_NO){
	$evaluation="your protein appears not to be globular";}
    else {
	$evaluation="your protein appears not as globular, as a domain";}

    return(1,"ok $sbrName",
	   $len,$numExposed,$numExpect,$globePhdDiff,$evaluation,
	   $globePhdNorm,$globePhdProb,$segRatio,$LisGlobular,$evaluationCombi);
}				# end of globeOne

#==============================================================================
sub globeOneCombi {
    local($sbrName);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   globeOneCombi               runs SEG and combines results with PHDglobeNorm
#       in|out GLOBAL:          all (from globeOne)
#                               in particular: $fileInLoc,$globePhdNorm
#       out:                    1|0,msg,$segRatio,$LisGlobular,$evaluationCombi  
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-col:"."globeOneCombi";
				# ------------------------------
				# intermediate FASTA of sequence
    $fileFastaTmp=    "GLOBE-TMP".$$."_fasta.tmp";
    if (! $parSbr{"fileSeg"}) {
	$fileSegTmp=  "GLOBE-SEG".$$."_seg.tmp";}
    else {			# file passed as argumnet -> do NOT delete
	$fileSegTmp=  $parSbr{"fileSeg"};}
    $id=$fileInLoc;$id=~s/^.*\/|\..*$//g;
    ($Lok,$msg)=
	&fastaWrt($fileFastaTmp,$id,$seq);

    return(&errSbrMsg("writing fasta ($fileFastaTmp) globeOne ($fileInLoc)")) if (! $Lok);
				# ------------------------------
				# do SEG
    ($Lok,$msg)=
	&segRun($fileFastaTmp,$fileSegTmp,$parSbr{"exeSeg"},0,0,$parSbr{"winSeg"},
		$parSbr{"locutSeg"}, $parSbr{"hicutSeg"},$parSbr{"optSeg"},$fhErrSbr);
    return(&errSbrMsg("failed SEG (".$parSbr{"exeSeg"}.") on $fileFastaTmp",$msg)) if (! $Lok);

    unlink($fileFastaTmp);	# remove temporary file

				# ------------------------------
				# digest SEG output (out=length of entire, lenght of comp)
    ($Lok,$msg,$lenSeq,$lenCom)=
	&segInterpret($fileSegTmp);
    return(&errSbrMsg("failed interpreting SEG file=$fileSegTmp",$msg)) if (! $Lok);

    if (! $parSbr{"fileSeg"}) {
	unlink($fileSegTmp); }	# remove temporary file

    $segRatio=-1;
    $segRatio=100*($lenCom/$lenSeq) if ($lenSeq > 0);
				# reduce accuracy
    $segRatio=~s/(\.\d\d).*$/$1/;

				# ------------------------------
				# combine SEG + PHD
    ($Lok,$msg,$LisGlobular)=
	&globeFuncJoinPhdSeg($globePhdNorm,$segRatio);
    return(&errSbrMsg("failed to join PHD+SEG ($globePhdNorm,$segRatio)",
		      $msg)) if (! $Lok);

				# ------------------------------
				# evaluate
    if    ($PHD_LO_OK    <= $globePhdNorm && 
	   $globePhdNorm <= $PHD_HI_OK &&
	   $segRatio     <= 50) {
	$evaluationCombi="your protein is very likely to be globular (SEG + GLOBE)";}
    elsif ($LisGlobular) {
	$evaluationCombi="your protein appears to be globular (SEG + GLOBE)";}
    elsif ($segRatio     <= 50) {
	$evaluationCombi="according to SEG your protein may be globular";}
    else {
	$evaluationCombi="according to SEG + GLOBE your protein appears non-globular";}

    return(1,"ok $sbrName",$segRatio,$LisGlobular,$evaluationCombi);
}				# end of globeOneCombi 

#==============================================================================
sub globeOneIni {
    local($fileInLoc,$fhErrSbr,@passLoc)= @_ ;
    local($sbrName);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   globeOneIni                 interprets input arguments
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-col:"."globeOneIni";
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc!")   if (! defined $fileInLoc);
    $fhErrSbr="STDOUT"                             if (! defined $fhErrSbr);
    return(0,"*** $sbrName: not def fileInLoc!")   if (! defined $fileInLoc);

				# ------------------------------
				# default settings
    $parSbr{"lenMin"}=   30;	$parSbr{"expl","lenMin"}=  "minimal length of protein";
    $parSbr{"exposed"}=  16;	$parSbr{"expl","exposed"}= "exposed if relAcc > this";
    $parSbr{"isPred"}=    1;	$parSbr{"expl","isPred"}=  "file without observed columns";

				# fit: (N- $fit2Fac*(N^1/3-$fit2Add)^3) 
    $parSbr{"fit2Ave"}=   1.4;	$parSbr{"expl","fit2Ave"}=  "average of fit for data base";
    $parSbr{"fit2Sig"}=   9.9;	$parSbr{"expl","fit2Sig"}=  "1 sigma of fit for data base";
    $parSbr{"fit2Add"}=   0.78; $parSbr{"expl","fit2Add"}=  "add of fit= 'N - fac*(N1/3-add)^3";
    $parSbr{"fit2Fac"}=   0.84;	$parSbr{"expl","fit2Fac"}=  "fac of fit= 'N - fac*(N1/3-add)^3";

    $parSbr{"fit2Ave100"}=0.1;
    $parSbr{"fit2Sig100"}=6.2;
    $parSbr{"fit2Add100"}=0.41;
    $parSbr{"fit2Fac100"}=0.64;
    $parSbr{"doFixPar"}=  0;	$parSbr{"expl","doFixPar"}=
	                                "do NOT change the fit para if length<100";
    @parSbr=("lenMin","exposed","isPred","doFixPar",
	     "fit2Ave",   "fit2Sig",   "fit2Add",   "fit2Fac",
	     "fit2Ave100","fit2Sig100","fit2Add100","fit2Fac100",
	     "fileSeg","doSeg","winSeg","locutSeg","hicutSeg","optSeg","exeSeg");

    $parSbr{"fileSeg"}=   0;	# =0 -> will be deleted!
    $parSbr{"doSeg"}=     1;	# will run SEG (if exe exists)
    $parSbr{"winSeg"}=   30;	# window size, 0 for mode 'glob'
    $parSbr{"locutSeg"}=  3.5;
    $parSbr{"hicutSeg"}=  3.75;

    $parSbr{"optSeg"}=    "x";	# pass the output print options as comma separated list
				#    NO '-' needed, see below
    if (defined $ARCH) {
	$ARCHTMP=$ARCH; }
    else {
	print "-*- WARN $sbrName: no ARCH defined set it (default = SGI64)!\n";
	$ARCHTMP=$ENV{'ARCH'} || "SGI64"; }

    $parSbr{"exeSeg"}=    "/home/rost/pub/molbio/bin/seg".$ARCHTMP; # executable of SEG
				# ------------------------------
				# avoid warnings
    $exposed=0;

				# ------------------------------
				# read command line
    foreach $arg (@passLoc){
	if    ($arg=~/^isPred/)               { $parSbr{"isPred"}=  1;$Lok=1;}
	elsif ($arg=~/^fix/)                  { $parSbr{"doFixPar"}=1;$Lok=1;}
	elsif ($arg=~/^[r]eturn/)             { $parSbr{"doReturn"}=1;$Lok=1;}

	elsif ($arg=~/^win=(.*)$/)            { $parSbr{"winSeg"}=$1;}
	elsif ($arg=~/^locut=(.*)$/)          { $parSbr{"locutSeg"}=$1;}
	elsif ($arg=~/^hicut=(.*)$/)          { $parSbr{"hicutSeg"}=$1;}
	elsif ($arg=~/^opt=(.*)$/)            { $parSbr{"optSeg"}=$1;}
	elsif ($arg=~/^exe=(.*)$/)            { $parSbr{"exeSeg"}=$1;}
	elsif ($arg=~/^fileSeg=(.*)$/i)       { $parSbr{"fileSeg"}=$1;}
	elsif ($arg=~/^fileOutSeg=(.*)$/i)    { $parSbr{"fileSeg"}=$1;}

	elsif ($arg=~/^noseg$/i)              { $parSbr{"noSeg"}=0;}
	else {
	    $Lok=0;
	    foreach $kwd (@parSbr){
		if ($arg=~/^$kwd=(.*)$/) {
		    $parSbr{"$kwd"}=$1;$Lok=1;}}
	    return(0,"*** $sbrName: wrong command line arg '$arg'\n") if (! $Lok);} }

    $exposed=$parSbr{"exposed"};

    return(1,"ok $sbrName");
}				# end of globeOneIni

#==============================================================================
sub globeProb {
    local($globePhdNormInLoc) = @_ ;
    local($sbrName);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   globeProb                   translates normalised diff in exp res to prob
#       in:                     $(norm = DIFF / length)
#       out:                    1|0,$msg,$prob (lookup table!)
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-col:"."globeProb";
				# check arguments
    return(&errSbr("globePhdNormInLoc not defined")) 
	if (! defined $globePhdNormInLoc);
    return(&errSbr("globePhdNormInLoc ($globePhdNormInLoc) not number")) 
	if ($globePhdNormInLoc !~ /^[0-9\.\-]+$/);
    return(&errSbr("normalised phdGlobe should be between -1 and 1, is=$globePhdNormInLoc")) 
	if ($globePhdNormInLoc < -1 || $globePhdNormInLoc > 1);

				# ------------------------------
				# avoid warnings
    $GLOBE_PROB_TABLE_MIN=$GLOBE_PROB_TABLE_NUM=$GLOBE_PROB_TABLE_ITRVL=
	$GLOBE_PROB_TABLE_MAX=$#GLOBE_PROB_TABLE=0;

				# ------------------------------
				# ini if table not defined yet!
    &globeProbIni()             if (! defined $GLOBE_PROB_TABLE_MIN || ! defined $GLOBE_PROB_TABLE[1]);

				# ------------------------------
				# normalise
				# too low
    return(1,"ok",0)            if ($globePhdNormInLoc <= $GLOBE_PROB_TABLE_MIN);
				# too high
    return(1,"ok",0)		if ($globePhdNormInLoc >= $GLOBE_PROB_TABLE_MAX);
				# in between: find interval
    $val=$GLOBE_PROB_TABLE_MIN;
    foreach $it (1..$GLOBE_PROB_TABLE_NUM) {
	$val+=$GLOBE_PROB_TABLE_ITRVL;
	last if ($val > $GLOBE_PROB_TABLE_MAX);	# note: should not happen
	return(1,"ok",$GLOBE_PROB_TABLE[$it])
	    if ($globePhdNormInLoc <= $val);
    }
				# none found (why?)
    return(1,"ok",0);
}				# end of globeProb

#===============================================================================
sub globeProbIni {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   globeProbIni           sets the values for the probability assignment
#       out GLOBAL:             
#-------------------------------------------------------------------------------
    $sbrName="lib-col:"."globeProbIni";

    $GLOBE_PROB_TABLE_MIN=  -0.280;
    $GLOBE_PROB_TABLE_MAX=   0.170;
    $GLOBE_PROB_TABLE_ITRVL= 0.010;
    $GLOBE_PROB_TABLE_NUM=   46;

    $GLOBE_PROB_TABLE[1]= 0.005; # val= -0.280  occ=   6  prob=   0.021
    $GLOBE_PROB_TABLE[2]= 0.008; # val= -0.270  occ=   0  prob=   0.014
    $GLOBE_PROB_TABLE[3]= 0.010; # val= -0.260  occ=   4  prob=   0.014
    $GLOBE_PROB_TABLE[4]= 0.015; # val= -0.250  occ=   6  prob=   0.021
    $GLOBE_PROB_TABLE[5]= 0.021; # val= -0.240  occ=   0  prob=   0.021
    $GLOBE_PROB_TABLE[6]= 0.025; # val= -0.230  occ=   0  prob=   0.021
    $GLOBE_PROB_TABLE[7]= 0.026; # val= -0.220  occ=   1  prob=   0.003
    $GLOBE_PROB_TABLE[8]= 0.028; # val= -0.210  occ=   0  prob=   0.021
    $GLOBE_PROB_TABLE[9]= 0.030; # val= -0.200  occ=   0  prob=   0.021
    $GLOBE_PROB_TABLE[10]=0.032; # val= -0.190  occ=   0  prob=   0.021
    $GLOBE_PROB_TABLE[11]=0.034; # val= -0.180  occ=   0  prob=   0.021
    $GLOBE_PROB_TABLE[12]=0.036; # val= -0.170  occ=   0  prob=   0.021
    $GLOBE_PROB_TABLE[13]=0.040; # val= -0.160  occ=  13  prob=   0.045
    $GLOBE_PROB_TABLE[14]=0.045; # val= -0.150  occ=  11  prob=   0.038
    $GLOBE_PROB_TABLE[15]=0.065; # val= -0.140  occ=  19  prob=   0.065
    $GLOBE_PROB_TABLE[16]=0.070; # val= -0.130  occ=   6  prob=   0.021
    $GLOBE_PROB_TABLE[17]=0.075; # val= -0.120  occ=   7  prob=   0.024
    $GLOBE_PROB_TABLE[18]=0.080; # val= -0.110  occ=  22  prob=   0.075
    $GLOBE_PROB_TABLE[19]=0.130; # val= -0.100  occ=  71  prob=   0.243
    $GLOBE_PROB_TABLE[20]=0.240; # val= -0.090  occ=  38  prob=   0.130
    $GLOBE_PROB_TABLE[21]=0.312; # val= -0.080  occ=  91  prob=   0.312
    $GLOBE_PROB_TABLE[22]=0.329; # val= -0.070  occ=  96  prob=   0.329
    $GLOBE_PROB_TABLE[23]=0.350; # val= -0.060  occ= 111  prob=   0.380
    $GLOBE_PROB_TABLE[24]=0.380; # val= -0.050  occ= 183  prob=   0.627
    $GLOBE_PROB_TABLE[25]=0.435; # val= -0.040  occ= 104  prob=   0.356
    $GLOBE_PROB_TABLE[26]=0.600; # val= -0.030  occ= 132  prob=   0.452
    $GLOBE_PROB_TABLE[27]=0.700; # val= -0.020  occ= 127  prob=   0.435
    $GLOBE_PROB_TABLE[28]=0.800; # val= -0.010  occ= 151  prob=   0.517
    $GLOBE_PROB_TABLE[29]=0.999; # val=  0.000  occ= 453  prob=   0.959
    $GLOBE_PROB_TABLE[30]=0.950; # val=  0.010  occ= 245  prob=   0.839
    $GLOBE_PROB_TABLE[31]=0.900; # val=  0.020  occ= 292  prob=   1.000
    $GLOBE_PROB_TABLE[32]=0.800; # val=  0.030  occ= 211  prob=   0.723
    $GLOBE_PROB_TABLE[33]=0.750; # val=  0.040  occ= 156  prob=   0.534
    $GLOBE_PROB_TABLE[34]=0.700; # val=  0.050  occ= 224  prob=   0.767
    $GLOBE_PROB_TABLE[35]=0.650; # val=  0.060  occ= 161  prob=   0.551
    $GLOBE_PROB_TABLE[36]=0.600; # val=  0.070  occ= 129  prob=   0.442
    $GLOBE_PROB_TABLE[37]=0.550; # val=  0.080  occ= 103  prob=   0.353
    $GLOBE_PROB_TABLE[38]=0.500; # val=  0.090  occ= 171  prob=   0.586
    $GLOBE_PROB_TABLE[39]=0.200; # val=  0.100  occ=  45  prob=   0.154
    $GLOBE_PROB_TABLE[40]=0.150; # val=  0.110  occ=  17  prob=   0.058
    $GLOBE_PROB_TABLE[41]=0.110; # val=  0.120  occ=  32  prob=   0.110
    $GLOBE_PROB_TABLE[42]=0.050; # val=  0.130  occ=   5  prob=   0.017
    $GLOBE_PROB_TABLE[43]=0.040; # val=  0.140  occ=   1  prob=   0.003
    $GLOBE_PROB_TABLE[44]=0.030; # val=  0.150  occ=   2  prob=   0.007
    $GLOBE_PROB_TABLE[45]=0.020; # val=  0.160  occ=   9  prob=   0.031
    $GLOBE_PROB_TABLE[46]=0.005; # val=  0.170  occ=   2  prob=   0.007
}				# end of globeProbIni

#==============================================================================
sub globeRd_phdRdb {
    local($fileInLoc2,$fhErrSbr2) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok,@tmp,$msgErr,
	  $ctTmp,$Lboth,$Lsec,$len,$numExposed,$lenRd,$rel);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   globeRd_phdRdb              read PHD rdb file with ACC
#       in:                     $fileInLoc,$fhErrSbr2
#       out:                    $len,$numExposed
#       err:                    0,'msg'
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="lib-col:"."globeRd_phdRdb";$fhinLoc="FHIN"."$sbrName";
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc2!")        if (! defined $fileInLoc2);
    $fhErrSbr2="STDOUT"                                  if (! defined $fhErrSbr);
    return(0,"*** $sbrName: no in file '$fileInLoc2'!")  if (! -e $fileInLoc2);

    open($fhinLoc,$fileInLoc2) ||
	do { print $fhErrSbr2 "*** ERROR $sbrName: '$fileInLoc2' not opened\n";
	     return(0);}; 
				# reading file
    $ctTmp=$Lboth=$Lsec=$len=$numExposed=0;
    $seq="";
    undef $names;
    while (<$fhinLoc>) {
	++$ctTmp;
	$lenRd=$1               if ($_=~/^\# LENGTH\s+\:\s*(\d+)/);
	if ($ctTmp<3){ 
	    if    ($_=~/^\# PHDsec\+PHDacc/)  {$Lboth=1;}
	    elsif ($_=~/^\# PHDacc/)          {$Lboth=0;}
	    elsif ($_=~/^\# PHDsec/)          {$Lsec=1;}
	    elsif ($_=~/^\# PROFboth/)        {$Lboth=1;}
	    elsif ($_=~/^\# PROFsec\+PROFacc/){$Lboth=1;}
	    elsif ($_=~/^\# PROFacc/)         {$Lboth=0;}
	    elsif ($_=~/^\# PROFsec/)         {$Lsec=1;}
	}
				# ******************************
	last if ($Lsec);	# ERROR is not PHDacc, at all!!!
				# ******************************

				# ------------------------------
				# names
	if (! defined $names && $_ !~ /^\s*\#/){
	    $_=~s/\n//g;
	    $names=$_;
	    @names=split(/\s*\t\s*/,$_);
	    $pos=0;
	    foreach $it (1..$#names){
		$tmp=$names[$it];
		if    ($tmp =~ /^AA/){
		    $posSeq=$it;
		    next; }
		elsif ($tmp =~ /PREL/){
		    $pos=$it;
		    last; }}
	    return(0,"$sbrName missing column name PREL (names=$names)")
		if (! $pos);
	    next; }
		
	next if ($_=~/^\#|^No|^4N/); # skip comments and first line
	$_=~s/\n//g;
	@tmp=split(/\t/,$_);	# $id,$chain,$len,$nali,$seq,$sec,$acc,$rel
	
	return(0,"*** ERROR $sbrName: too few elements in id=$id, line=$_\n") 
	    if ($#tmp<6);

				# ------------------------------
				# read sequence (second column)
	$tmp=$tmp[$posSeq]; $tmp=~s/\s//g;
	$seq.=$tmp;
				# ------------------------------
				# read ACC
	foreach $tmp (@tmp) {
	    $tmp=~s/\s//g;}	# skip blanks

	$rel=$tmp[$pos];

	if ($rel =~/[^0-9]/){	# xx hack out, somewhere error
	    $msgErr="*** error rel=$rel, ";
	    if ($parSbr{"isPred"}){$msgErr.="isPred ";}else{$msgErr.="isPrd+Obs ";}
	    if ($Lboth)        {$msgErr.="isBoth ";}else{$msgErr.="isPHDacc ";}
	    $msgErr.="line=$_,\n";
	    close($fhinLoc);
	    return(0,$msgErr);}
	++$len;
	++$numExposed if ($rel>=$exposed);
	$_=~s/\n//g;
	next if (length($_)==0);
    } close($fhinLoc);
    return(0,"$sbrName some variables strange len=$len, numExposed=$numExposed\n")
	if (! defined $len || $len==0 || ! defined $numExposed || $numExposed==0);
    return($len,$numExposed,$seq);
}				# end of globeRd_phdRdb

#==============================================================================
sub globeWrt {
    local($fhoutTmp,$parLoc,%resLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok,@tmp,@idLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   globeWrt                    writes output for GLOBE
#       in:                     FILEHANDLE to print,$par=par1,par2,par3,%res
#       in:                     $res{"id"}          = 'id1,id2', i.e. list of names 
#       in:                     $res{"par1"}        = setting of parameter 1
#       in:                     $res{"expl","par1"} = explain meaning of parameter 1
#       in:                     $res{"$id","$kwd"}  = value for name $id
#       in:                         kwd=len|nexp|nfit|diff|interpret
#       out:                    write file
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."globeWrt";$fhinLoc="FHIN"."$sbrName";
				# interpret arguments
    if (defined $parLoc){
	$parLoc=~s/^,*|,*$//g;
	@tmp=split(/,/,$parLoc);}
    if (defined $resLoc{"id"}){
	$resLoc{"id"}=~s/^,*|,*$//g;
	@idLoc=split(/,/,$resLoc{"id"});}
				# ------------------------------
				# write header
    if (defined $date) {
	$dateTmp=$date; }
    else {
	$tmp=`date`; $tmp=~s/\n//g if (defined $tmp);
	$dateTmp=$tmp || "before year 2000"; }

    print $fhoutTmp
	"# Perl-RDB generated by:$scrName on:$dateTmp\n",
	"# --------------------------------------------------------------------------------\n",
	"# FORMAT   begin\n",
	"# FORMAT   general:    - lines starting with hashes contain comments or PARAMETERS\n",
	"# FORMAT   general:    - columns are delimited by tabs\n",
	"# FORMAT   parameters: '# PARA:tab     keyword =tab value tab (further-information)'\n",
	"# FORMAT   notation:   '# NOTATION:tab keyword tab explanation'\n",
	"# FORMAT   info:       '# INFO:tab     text'\n",
	"# FORMAT   blocks 0:   '# BLOCK        keyword'\n",
	"# FORMAT   blocks 1:    column names (tab delimited)\n",
	"# FORMAT   blocks n>1:  column data  (tab delimited)\n",
	"# FORMAT   file end:   '//' is the end of a complete file\n",
	"# FORMAT   end\n",
	"# --------------------------------------------------------------------------------\n";
				# ------------------------------
				# write parameters
    print $fhoutTmp
	"# PARA     begin\n",
	"# PARA     $scrName HEADER: PARAMETERS\n";
    foreach $des (@tmp){
	$expl="";$expl=$resLoc{"expl","$des"} if (defined $resLoc{"expl","$des"});
	next if ($des eq "doFixPar" && (! $resLoc{"doFixPar"}));
	printf $fhoutTmp 
	    "# PARA:\t%-10s =\t%-6s\t%-s\n",$des,$resLoc{"$des"},$expl;}
    print $fhoutTmp
	"# PARA     end\n",
	"# --------------------------------------------------------------------------------\n";
				# ------------------------------
				# explanations
    print $fhoutTmp
	"# NOTATION begin\n",
	"# NOTATION HEADER: ABBREVIATIONS COLUMN NAMES\n";
    printf $fhoutTmp 
	"# NOTATION:\t%-12s:\t%s\n","id",        "protein identifier";
    printf $fhoutTmp 
	"# NOTATION:\t%-12s:\t%s\n","len",       "length of protein";
    printf $fhoutTmp 
	"# NOTATION:\t%-12s:\t%s\n","nexp",      "number of predicted exposed residues (PHDacc)";
    printf $fhoutTmp 
	"# NOTATION:\t%-12s:\t%s\n","nfit",      "number of expected exposed res";
    printf $fhoutTmp 
	"# NOTATION:\t%-12s:\t%s\n","diff",      "nExposed - nExpect";
    printf $fhoutTmp 
	"# NOTATION:\t%-12s:\t%s\n","interpret",
	                            "comment about globularity predicted for your protein";
    print $fhoutTmp
	"# NOTATION end\n",
	"# --------------------------------------------------------------------------------\n";
    print $fhoutTmp
	"# COMMENTS begin\n",
	"# COMMENTS You may find a preliminary description of the method in the following\n",
	"# COMMENTS preprint:\n",
	"# COMMENTS    http://www.columbia.edu/~rost/Papers/98globe.html\n",
	"# COMMENTS \n",
	"# COMMENTS end\n",
	"# --------------------------------------------------------------------------------\n";
				# column names
    printf $fhoutTmp 
	"%-s\t%8s\t%8s\t%8s\t%8s\t%-s\n",
	"id","len","nexp","nfit","diff","interpret";

				# data
    foreach $id (@idLoc){
	printf $fhoutTmp 
	    "%-s\t%8d\t%8d\t%8.2f\t%8.2f\t%-s\n",
	    $id,$resLoc{"$id","len"},$resLoc{"$id","nexp"},$resLoc{"$id","nfit"},
	    $resLoc{"$id","diff"},$resLoc{"$id","interpret"};}
}				# end of globeWrt

#==============================================================================
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
    $sbr="lib-col:hsspChopProf";
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

#==============================================================================
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

#==============================================================================
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

#==============================================================================
sub hsspGetFile { 
    local ($fileInLoc,$Lscreen,@dir) = @_ ; 
    local ($fileHssp,$dir,$tmp,$chainLoc,@dir2,$idLoc);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   hsspGetFile                 searches all directories for existing HSSP file
#       in:                     $file,$Lscreen,@dir
#       out:                    returned file,chain ($hssp,$chain), (if chain in file)
#       watch:                  loop onto itself:
#                               1prcH.hssp not found -> try 1prc.hssp
#--------------------------------------------------------------------------------
    $#dir2=$Lok=0;
    return(0,"no input file")   if (! defined $fileInLoc);
    $chainLoc="";$idLoc=$fileInLoc;$idLoc=~s/^.*\///g;
    $#dir=0                     if (! defined @dir);
    $Lscreen=0                  if (! defined $Lscreen);
				# passed dir instead of Lscreen
    if (-d $Lscreen) { @dir=($Lscreen,@dir);
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

#==============================================================================
sub hsspGetFileLoop { 
    local ($fileInLoop,$Lscreen,@dir) = @_ ; 
    local ($dir,$tmp);
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
#                                  only those will be returned (e.g. $tmp{"seq","$ct"})
#                               default: all 3!
#       out:                    1|0,$rd{} with: 
#       err:                    (0,$msg)
#                    overall:
#                               $rd{"NROWS"}=          : number of alis, i.e. $#want
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
#                               $rd{"seq","$ct"}=SEQW  : sequences, with all insertions
#                                                        but NOT aligned!!!
#                               $rd{"seqAli","$ct"}    : sequences, with all insertions,
#                                                        AND aligned (all, including guide
#                                                        filled up with '.' !!
#-------------------------------------------------------------------------------
    $sbrName="lib-col:hsspRdAli"; $fhinLoc="FHIN"."$sbrName"; $fhinLoc=~tr/[a-z]/[A-Z]/;
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

#==============================================================================
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
    $sbrName="lib-col:hsspRdHeader";$fhinLoc="FHIN"."$sbrName";$fhinLoc=~tr/[a-z]/[A-Z]/;
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
	$tmp{"STRID","$ct"}=  $id if ($strid=~/^\s*$/ && &is_pdbid($id));
	    
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

#==============================================================================
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
    $sbrName="lib-col:hsspRdProfile";$fhinLoc="FHIN"."$sbrName";
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

#==============================================================================
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
    $sbrName="lib-col:hsspRdSeqSecAcc";$fhinLoc="FHIN"."$sbrName";$fhinLoc=~tr/[a-z]/[A-Z]/;
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

#==============================================================================
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

#==============================================================================
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
    $sbrName="lib-col:hsspRdStripAndHeader";$fhinLoc="FHIN"."$sbrName";
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

#==============================================================================
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
    $sbrName="lib-col:hsspRdStripHeader";$fhinLoc="FHIN"."$sbrName";
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

#==============================================================================
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

#==============================================================================
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

#==============================================================================
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
	print "*** ERROR hssp_rd_strip_one (lib-col): '$fileInLoc' strip file missing\n";
	exit;}
#    if (&is_strip_old($fileInLoc)){
#	print "*** ERROR hssp_rd_strip_one (lib-col): only with new strip format\n";
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
    if ($Lscreen) { print"--- lib-col.pl:hssp_rd_strip_one \t read in from '$fileInLoc'\n";
		    foreach $des(@des){
			print "$des:",$rdLoc{"$des"},"\n";}}
    return (%rdLoc);
}				# end of hssp_rd_strip_one 

#==============================================================================
sub hssp_rd_strip_one_correct1 {
#-------------------------------------------------------------------------------
#   hssp_rd_strip_one_correct1  correct for begin and ends
#-------------------------------------------------------------------------------
    $diff=(length($rdLoc{"seq1"})-length($rdLoc{"seq2"}));
    if ($diff!=0){
	foreach $it (1..$diff){
	    $rdLoc{"seq2"}.=".";$rdLoc{"sec2"}.="."; }}
}				# end of hssp_rd_strip_one_correct1

#==============================================================================
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

#==============================================================================
sub identify_current_user { $identify_current_user=&sysGetUser; }


#==============================================================================
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

#==============================================================================
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
    $sbrName="lib-col:"."isDafGeneral";$fhinLoc="FHIN"."$sbrName";
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

#==============================================================================
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

#==============================================================================
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
    $sbrName="lib-col:"."isDsspGeneral";$fhinLoc="FHIN"."$sbrName";
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

#==============================================================================
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
    close($fhinLoc2);
    $two=~s/\s|\n//g            if (defined $two);

    return(0)                   if (! defined $two || ! defined $one);
    return(1)                   if (($one =~ /^\s*>\s*\w+/) && 
				    $two !~/[^ABCDEFGHIKLMNPQRSTVWXYZ\.~_!]/);
    return(0);
}				# end of isFasta

#==============================================================================
sub isFastaMul {
    local ($fileLoc) = @_ ; local ($Lok);
#--------------------------------------------------------------------------------
#   isFastaMul                  checks whether more than 1 sequence in FASTA found
#                               (first line /^>\w/, second (non white) = AA *2 
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
    $fhinLoc2="FHIN_FASTA";
    &open_file("$fhinLoc2","$fileLoc") || return(0);
    $one=(<$fhinLoc2>);
    $two=(<$fhinLoc2>);
    $two=~s/\s//g               if (defined $two);

    return (0)                  if (! defined $two || ! defined $one);
    return (0)                  if (($one !~ /^\s*\>\s*\w+/) || 
				    ($two =~ /[^ABCDEFGHIKLMNPQRSTVWXYZ\.~_!]/i));
    $Lok=0;
    while (<$fhinLoc2>) {next if ($_ !~ /^\s*>\s*\w+/);
			 $Lok=1;
			 last;}close($fhinLoc2);
    return($Lok);
}				# end of isFastaMul

#==============================================================================
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
    $sbrName="lib-col:"."isFsspGeneral";$fhinLoc="FHIN"."$sbrName";
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

#==============================================================================
sub isHsspGeneral {
    local ($fileInLoc,@dirLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok,@tmpFile,@tmpChain,@tmp,$file,$chain);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   isHsspGeneral               checks (and finds) HSSP files
#       in:                     $file,@dir (to search)
#       out:                    $Lok,$txt,@files (if chains: file1,file2,chain,chain1,chain2)
#           txt='not found|empty|not open|none in list|not hssp|isHssp|isHsspList'
#-------------------------------------------------------------------------------
    $sbrName="lib-col:"."isHsspGeneral";$fhinLoc="FHIN"."$sbrName";
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

#==============================================================================
sub isMsf {
    local ($fileLoc) = @_ ; local ($Lok);
#--------------------------------------------------------------------------------
#   isMsf                       checks whether or not file is in MSF format
#   &open_file("FHIN_MSF","$fileLoc");(i.e. the dirty ali format used for aqua)
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
    open("FHIN_MSF","$fileLoc");
    $ct=0;
    while (<FHIN_MSF>){ $Lok=0;
			$Lok=1  if ($_=~/\s*MSF[\s:]+/ ||
				    # new PileUp shit
				    $_=~/\s*PileUp|^\s*\!\!AA_MULTIPLE_ALIGNMENT/);
			last;}
    close(FHIN_MSF);
    return($Lok);
}				# end of isMsf

#==============================================================================
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
    $sbrName="lib-col:"."isMsfGeneral";$fhinLoc="FHIN"."$sbrName";
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

#==============================================================================
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

#==============================================================================
sub isPhdAcc {
    local ($fileLoc) = @_ ; local ($Lok);
#--------------------------------------------------------------------------------
#   isPhdAcc                    checks whether or not file is in PHD.rdb_acc format
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
    &open_file("FHIN_RDB_PHDACC","$fileLoc") || return(0);
    $ctLoc=0;
    while (<FHIN_RDB_PHDACC>){ 
	$_=~s/^[\#\s]//g;
	next if (length($_)<5);
	++$ctLoc;
	last if ($ctLoc>3);
	if    ($ctLoc==1 && $_=~/^\s*Perl-RDB/){$Lok=1;}
	elsif ($ctLoc==1)                  { close(FHIN_RDB_PHDACC); 
					  return(0);}
	elsif ($_=~/PHDacc/)            { close(FHIN_RDB_PHDACC); 
					  return(1);}}
    close(FHIN_RDB_PHDACC);
    return(0);
}				# end of isPhdAcc

#==============================================================================
sub isPhdHtm {
    local ($fileLoc) = @_ ; local ($Lok);
#--------------------------------------------------------------------------------
#   isPhdHtm                    checks whether or not file is in PHD.rdb_htm format
#				(i.e. the dirty ali format used for aqua)
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
    &open_file("FHIN_RDB_PHDHTM","$fileLoc") || return(0);
    $ctLoc=0;
    while (<FHIN_RDB_PHDHTM>){ 
	$_=~s/^[\#\s]//g;
	next if (length($_)<5);
	++$ctLoc;
	last if ($ctLoc>3);
	if    ($ctLoc==1 && $_=~/^\s*Perl-RDB/){$Lok=1;}
	elsif ($ctLoc==1) { close(FHIN_RDB_PHDHTM); 
			 return(0);}
	elsif ($_=~/PHDhtm/){close(FHIN_RDB_PHDHTM); 
			 return(1);}}
    close(FHIN_RDB_PHDHTM);
    return(0);
}				# end of isPhdHtm

#==============================================================================
sub isPhdSec {
    local ($fileLoc) = @_ ; local ($Lok);
#--------------------------------------------------------------------------------
#   isPhdSec                    checks whether or not file is in PHD.rdb_sec format
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
    &open_file("FHIN_RDB_PHDSEC","$fileLoc") || return(0);
    $ctLoc=0;
    while (<FHIN_RDB_PHDSEC>){ 
	$_=~s/^[\#\s]//g;
	next if (length($_)<5);
	++$ctLoc;
	last if ($ctLoc>3);
	if    ($ctLoc==1 && $_=~/^\s*Perl-RDB/) { $Lok=1;}
	elsif ($ctLoc==1)                       { close(FHIN_RDB_PHDSEC); 
					       return(0); }
	elsif ($_=~/PHDsec/)                 { close(FHIN_RDB_PHDSEC); 
					       return(1);}}
    close(FHIN_RDB_PHDSEC);
    return(0);
}				# end of isPhdSec

#==============================================================================
sub isPir {
    local ($fileLoc) = @_ ; local ($Lok);
#--------------------------------------------------------------------------------
#    isPir                    checks whether or not file is in Pir format 
#                               (first line /^>P1\;/, second (non white) = AA
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
    &open_file("FHIN_PIR","$fileLoc") || return(0);
    $one=(<FHIN_PIR>);close(FHIN_PIR);
    return(1)                   if (defined $one && $one =~ /^\>P1\;/i);
    return(0);
}				# end of isPir

#==============================================================================
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
    $ctLoc=0;
    while(<FHIN_PIR>){++$ctLoc if ($_=~/^>P1\;/i);
                      last if ($ctLoc>1);}close(FHIN_PIR);
    return(1)                   if ($ctLoc>1);
    return(0);
}				# end of isPirMul

#==============================================================================
sub isRdb {local ($fileInLoc) = @_ ;local ($fh);
#--------------------------------------------------------------------------------
#   isRdb                       checks whether or not file is in RDB format
#       in:                     file
#       out:                    returns 1 if is RDB, 0 else
#--------------------------------------------------------------------------------
	   return (0) if (! -e $fileInLoc);$fh="FHIN_CHECK_RDB";
	   &open_file("$fh", "$fileInLoc") || return(0);
	   $tmp=<$fh>;close($fh);
	   return(1)            if (defined $tmp && $tmp =~/^\# .*RDB/);
	   return 0; }	# end of isRdb


#==============================================================================
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
    $sbrName="lib-col:"."isRdbGeneral";$fhinLoc="FHIN"."$sbrName";
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

#==============================================================================
sub isRdbList {local ($fileInLoc) = @_ ; local ($Lok,$fhinLoc,$fileTmp);
#--------------------------------------------------------------------------------
#   isRdbList                   checks whether or not file is list of Rdb files
#       in:                     file
#       out:                    returns 1 if is RDB, 0 else
#--------------------------------------------------------------------------------
	       return(0) if (! -e $fileInLoc); $fhinLoc="FHIN_RDBLIST";$Lok=0;
	       $Lok=&open_file("$fhinLoc","$fileInLoc");
	       if (! $Lok){ print "*** ERROR in lib-col.pl:isRdbList, opening '$fileInLoc'\n";
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


#==============================================================================
sub isSaf {local ($fileLoc) = @_ ; 
#--------------------------------------------------------------------------------
#    isSaf                      checks whether or not file is in SAF format (/# SAF/)
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
           return(0)            if (! defined $fileLoc || ! -e $fileLoc);
	   $fhinLoc="FHIN_SAF";
           &open_file("$fhinLoc","$fileLoc") || return (0);
           $tmp=<$fhinLoc>; close("$fhinLoc");
           return(1)            if (defined $tmp && $tmp =~ /^\#.*SAF/);
           return(0);
}				# end of isSaf

#==============================================================================
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

#==============================================================================
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
    $sbrName="lib-col:isSwissGeneral";$fhinLoc="FHIN"."$sbrName";
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

#==============================================================================
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

#==============================================================================
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

#==============================================================================
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

#==============================================================================
sub is_hssp {
    local ($fileInLoc) = @_ ;local ($fh,$Lis);
#--------------------------------------------------------------------------------
#   is_hssp                     checks whether or not file is in HSSP format
#       in:                     $file
#       out:                    1 if is hssp; 0 else
#--------------------------------------------------------------------------------
    return (0)                  if (! defined $fileInLoc || ! -e $fileInLoc) ;
    $fh="FHIN_CHECK_HSSP";
    &open_file("$fh", "$fileInLoc") || return(0);
    $Lis=0;
    while ( <$fh> ) {$Lis=1 if (/^HSSP/) ; 
		     last; }close($fh);
    return $Lis;
}				# end of is_hssp

#==============================================================================
sub is_hssp_empty {
    local ($fileInLoc) = @_ ;local ($fh,$Lis);
#--------------------------------------------------------------------------------
#   is_hssp_empty               checks whether or not HSSP file has NALIGN=0
#       in:                     $file
#       out:                    1 if is empty; 0 else
#--------------------------------------------------------------------------------
    return (0)                  if (! defined $fileInLoc || ! -e $fileInLoc);
    $fh="FHIN_CHECK_HSSP";
    &open_file("$fh", "$fileInLoc") || return(0);
    while ( <$fh> ) {
	if ($_=~/^NALIGN\s+(\d+)/){
	    if ($1 eq "0"){
		close($fh); return(1);}
	    last; }}close($fh); 
    return 0;
}				# end of is_hssp_empty

#==============================================================================
sub is_hssp_list {
    local ($fileInLoc) = @_ ;local ($fh,$Lis,$fileRd,$fileLoc,$chainLoc,$LscreenLoc);
#--------------------------------------------------------------------------------
#   is_hssp_list                checks whether or not file contains a list of HSSP files
#       in:                     $file
#       out:                    returns 1 if is HSSP list, 0 else
#--------------------------------------------------------------------------------
    $LscreenLoc=0;
    return (0)                  if (! defined $fileInLoc || ! -e $fileInLoc);
    $fh="FHIN_CHECK_HSSP_LIST";
    &open_file("$fh", "$fileInLoc") || return(0);
    $Lis=0;
    while ( <$fh> ) {$fileRd=$_;$fileRd=~s/\s|\n//g;
		     next if (length($fileRd)<5);
		     ($fileLoc,$chainLoc)= 
			 &hsspGetFile($fileRd,$LscreenLoc);
		     $Lis=1 if (&is_hssp($fileLoc));
		     last; } close($fh);
    return $Lis;
}				# end of is_hssp_list

#==============================================================================
sub is_pdbid {
    local ($id) = @_ ;
#--------------------------------------------------------------------------------
#   is_pdbid                    checks whether or not id is a valid PDBid (number 3 char)
#       in:                     $file
#       out:                    1 if is DBid, 0 else
#--------------------------------------------------------------------------------
    return 1
	if ((length($id) <= 6) &&
	    ($id=~/^[0-9][0-9a-z]{3,3}[^0-9a-z]?/));
    return 0;
}				# end of is_pdbid

#==============================================================================
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

#==============================================================================
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

#==============================================================================
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

#==============================================================================
sub maxhomCheckHssp {
    local ($file_in,$laliPdbMin)=@_;
    local ($sbrName,$len_strid,$Llong_id,$msgHere,$tmp,$found,$posPdb,$posLali,$pdb,$len);
    $[ =1;
#----------------------------------------------------------------------
#   maxhomCheckHssp             checks: (1) any ali? (2) PDB?
#       in:                     $fileHssp,$laliMin (minimal ali length to report PDB)
#       out:                    $Lok,$LisEmpty,$LisSelf,$IsIlyaPdb,$pdbidFound
#       out:                    1 error: (0,'error','error message')
#       out:                    1 ok   : (1,'ok',   'message')
#       out:                    2 empty: (2,'empty','message')
#       out:                    3 self : (3,'self', 'message')
#       out:                    4 pdbid: (4,'pdbid','message')
#----------------------------------------------------------------------
    $sbrName="lib-col:maxhomCheckHssp";
    return(0,"error","*** $sbrName: not def file_in!")            if (! defined $file_in);
    return(0,"error","*** $sbrName: not def laliPdbMin!")         if (! defined $laliPdbMin);
    return(0,"error","*** $sbrName: miss input file '$file_in'!") if (! -e $file_in &&
								      ! -l $file_in);
				# defaults for reading
    $len_strid= 4;		# minimal length to identify PDB identifiers
    $Llong_id=  0;

    $msgHere="--- $sbrName \t in=$file_in\n";
				# open HSSP file
    open(FILEIN,$file_in)  || 
	return(0,"error","*** $sbrName cannot open '$file_in'\n");
				# ----------------------------------------
				# skip everything before "## PROTEINS"
    $Lempty=1;			# ----------------------------------------
    while( <FILEIN> ) {
	if ($_=~/^PARAMETER  LONG-ID :YES/) { # is long id?
	    $Llong_id=1;}
	if ($_=~/^\#\# PROTEINS/ ) {
	    $Lempty=0;
	    last;}}

    if ($Lempty){		# exit if no homology found
	$msgHere.="no homologue found in $file_in!";
	close(FILEIN);
	return(1,"empty",$msgHere); }
				# ----------------------------------------
				# now search for PDB identifiers
				# ----------------------------------------
    if ($Llong_id){ $posPdb=47; $posLali=86;} else { $posPdb=21; $posLali=60;}
    $found="";
    while ( <FILEIN> ) {
	next if ($_ !~ /^\s*\d+ \:/);
	$pdb=substr($_,$posPdb,4);  $pdb=~ s/\s//g;
	$len=substr($_,$posLali,4); $len=~ s/\s//g;
	if ( (length($pdb) > 1) && ($len>$laliPdbMin) ) { # global parameter
	    $found.=$pdb.", ";} 
	last if ($_=~ /\#\# ALIGNMENT/ ); }
    close(FILEIN);

    if (length($found) > 2) {
	return(1,"pdbid","pdbid=".$found."\n$msgHere"); }

    return(1,"ok",$msgHere);
}				# end of maxhomCheckHssp

#==============================================================================
sub maxhomGetArg {
    local($niceLoc,$exeMaxLoc,$fileDefaultLoc,$jobid,$fileMaxIn,$fileMaxList,$Lprofile,
	  $fileMaxMetric,$paraMaxSmin,$paraMaxSmax,$paraMaxGo,$paraMaxGe,
	  $paraMaxWeight1,$paraMaxWeight2,$paraMaxIndel1,$paraMaxIndel2,
	  $paraMaxNali,$paraMaxThresh,$paraMaxSort,$fileHsspOut,$dirMaxPdb,
	  $paraMaxProfileOut,$fileStripOut)=@_;
    local ($command);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   maxhomGetArg                gets the input arguments to run MAXHOM
#       in:                     
#         $niceLoc              level of nice (nice -n)
#         $exeMaxLoc            fortran executable for MaxHom
#         $fileDefaultLoc       local copy of maxhom default file
#         $jobid                number which will be added to files :
#                               MAXHOM_ALI.jobid, MAXHOM.LOG_jobid, maxhom.default_jobid
#                               filter.list_jobid, blast.x_jobid
#         $fileMaxIn            query sequence (should be FASTA, here)
#         $fileMaxList          list of db to align against
#         $Lprofile             NO|YES                  (2nd is profile)
#         $fileMaxMetric        metric
#         $paraMaxSmin          minimal value of metric (typical -0.5)
#         $paraMaxSmax          maximal value of metric (typical  1.0)
#         $paraMaxGo            gap open penalty        (typical  3.0)
#         $paraMaxGe            gap extension/elongation penalty (typ 0.3)
#         $paraMaxWeight1       YES|NO                  (typ yes)
#         $paraMaxWeight2       YES|NO                  (typ NO)
#         $paraMaxIndel1        YES|NO                  (typ yes)
#         $paraMaxIndel2        YES|NO                  (typ yes)
#         $paraMaxNali          maximal number of alis reported (was 500)
#         $paraMaxThresh              
#         $paraMaxSort          DISTANCE|    
#         $fileHsspOut          NO|name of output file (.hssp)
#         $dirMaxPdb            path of PDB directory
#         $paraMaxProfileOut    NO| ?
#         $fileStripOut         NO|file name of strip file
#       out:                    $command
#--------------------------------------------------------------------------------
    $tmpNice=$niceLoc;
    if ($tmpNice =~ /\d/ || $tmpNice eq "nice"){
	$tmpNice=~s/nice|[ -]//g; 
	$tmpNice=19 if (length($tmpNice)<1);
	if ($exeMaxLoc =~/ALPHA/){$tmpNice="nice -".$tmpNice;}
	else                     {$tmpNice="nice -".$tmpNice;}}
    eval "\$command=\"$tmpNice $exeMaxLoc -d=$fileDefaultLoc -nopar ,
         COMMAND NO ,
         BATCH ,
         PID:          $jobid ,
         SEQ_1         $fileMaxIn ,      
         SEQ_2         $fileMaxList ,
         PROFILE       $Lprofile ,
         METRIC        $fileMaxMetric ,
         NORM_PROFILE  DISABLED , 
         MEAN_PROFILE  0.0 ,
         FACTOR_GAPS   0.0 ,
         SMIN          $paraMaxSmin , 
         SMAX          $paraMaxSmax ,
         GAP_OPEN      $paraMaxGo ,
         GAP_ELONG     $paraMaxGe ,
         WEIGHT1       $paraMaxWeight1 ,
         WEIGHT2       $paraMaxWeight2 ,
         WAY3-ALIGN    NO ,
         INDEL_1       $paraMaxIndel1,
         INDEL_2       $paraMaxIndel2,
         RELIABILITY   NO ,
         FILTER_RANGE  10.0,
         NBEST         1,
         MAXALIGN      $paraMaxNali ,
         THRESHOLD     $paraMaxThresh ,
         SORT          $paraMaxSort ,
         HSSP          $fileHsspOut ,
         SAME_SEQ_SHOW YES ,
         SUPERPOS      NO ,
         PDB_PATH      $dirMaxPdb ,
         PROFILE_OUT   $paraMaxProfileOut ,
         STRIP_OUT     $fileStripOut ,
         LONG_OUT      NO ,
         DOT_PLOT      NO ,
         RUN ,\"";
    return ($command);
}				# end maxhomGetArg

#==============================================================================
sub maxhomGetArgCheck {
    local($exeMaxLoc,$fileDefLoc,$fileMaxIn,$fileMaxList,$fileMaxMetric)=@_;
    local($msg,$warn,$pre);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   maxhomGetArgCheck           performs some basic file-existence-checks
#                               before Maxhom arguments are built up
#       in:                     $exeMaxLoc,$fileDefLoc,$fileMaxIn,$fileMaxList,$fileMaxMetric
#       out:                    msg,warn
#--------------------------------------------------------------------------------
    $msg="";$warn="";$pre="*** maxhomGetArgCheck missing ";
    if    (! -e $exeMaxLoc     && ! -l $exeMaxLoc )   {$msg.="$pre"."$exeMaxLoc=    for exe\n";}
    elsif (! -e $fileDefLoc    && ! -l $fileDefLoc)   {$msg.="$pre"."$fileDefLoc=   default file\n";}
    elsif (! -e $fileMaxIn     && ! -l $fileMaxIn )   {$msg.="$pre"."$fileMaxIn=    query seq\n";}
    elsif (! -e $fileMaxList   && ! -l $fileMaxList)  {$msg.="$pre"."$fileMaxList=  ali DB\n";}
    elsif (! -e $fileMaxMetric && ! -l $fileMaxMetric){$msg.="$pre"."$fileMaxMetric=metric\n";}
    return ($msg,$warn);
}				# end maxhomGetArgCheck

#==============================================================================
sub maxhomGetCsh {
    local($niceLoc,$exeMaxLoc,$fileDefaultLoc,$jobid,$fileMaxIn,$fileMaxList,$Lprofile,
	  $fileMaxMetric,$paraMaxSmin,$paraMaxSmax,$paraMaxGo,$paraMaxGe,
	  $paraMaxWeight1,$paraMaxWeight2,$paraMaxIndel1,$paraMaxIndel2,
	  $paraMaxNali,$paraMaxThresh,$paraMaxSort,$fileHsspOut,$dirMaxPdb,
	  $paraMaxProfileOut,$fileStripOut,$fileMaxhomCshTmp,$fileMaxhomCsh)=@_;
    local ($command);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   maxhomGetCsh                gets the input arguments to run MAXHOM
#       in:                     
#         $niceLoc              level of nice (nice -n)
#         $exeMaxLoc            fortran executable for MaxHom
#         $fileDefaultLoc       local copy of maxhom default file
#         $jobid                number which will be added to files :
#                               MAXHOM_ALI.jobid, MAXHOM.LOG_jobid, maxhom.default_jobid
#                               filter.list_jobid, blast.x_jobid
#         $fileMaxIn            query sequence (should be FASTA, here)
#         $fileMaxList          list of db to align against
#         $Lprofile             NO|YES                  (2nd is profile)
#         $fileMaxMetric        metric
#         $paraMaxSmin          minimal value of metric (typical -0.5)
#         $paraMaxSmax          maximal value of metric (typical  1.0)
#         $paraMaxGo            gap open penalty        (typical  3.0)
#         $paraMaxGe            gap extension/elongation penalty (typ 0.3)
#         $paraMaxWeight1       YES|NO                  (typ yes)
#         $paraMaxWeight2       YES|NO                  (typ NO)
#         $paraMaxIndel1        YES|NO                  (typ yes)
#         $paraMaxIndel2        YES|NO                  (typ yes)
#         $paraMaxNali          maximal number of alis reported (was 500)
#         $paraMaxThresh              
#         $paraMaxSort          DISTANCE|    
#         $fileHsspOut          NO|name of output file (.hssp)
#         $dirMaxPdb            path of PDB directory
#         $paraMaxProfileOut    NO| ?
#         $fileStripOut         NO|file name of strip file
#       out:                    $command
#--------------------------------------------------------------------------------
    $tmpNice=$niceLoc;
    if ($tmpNice =~ /\d/ || $tmpNice eq "nice"){
	$tmpNice=~s/nice|[ -]//g; 
	$tmpNice=19 if (length($tmpNice)<1);
	if ($exeMaxLoc =~/ALPHA/){$tmpNice="nice -".$tmpNice;}
	else                     {$tmpNice="nice -".$tmpNice;}}

    $file="#!\/bin\/csh\n";
    $file.="#==================================================\n";
    $file.="# build up command file to run MAXHOM\n";
    $file.="#==================================================\n";
    $file.="echo \"COMMAND NO\"                    >> $fileMaxhomCshTmp\n";
    $file.="echo \"BATCH\"                         >> $fileMaxhomCshTmp\n";
    $file.="echo \"PID:          $jobid\"          >> $fileMaxhomCshTmp\n";
    $file.="echo \"SEQ_1         $fileMaxIn\"      >> $fileMaxhomCshTmp\n";
    $file.="echo \"SEQ_2         $fileMaxList\"    >> $fileMaxhomCshTmp\n";
    $file.="echo \"PROFILE       $Lprofile\"       >> $fileMaxhomCshTmp\n";
    $file.="echo \"METRIC        $fileMaxMetric\"  >> $fileMaxhomCshTmp\n";
    $file.="echo \"NORM_PROFILE  DISABLED\"        >> $fileMaxhomCshTmp\n";
    $file.="echo \"MEAN_PROFILE  0.0\"             >> $fileMaxhomCshTmp\n";
    $file.="echo \"FACTOR_GAPS   0.0\"             >> $fileMaxhomCshTmp\n";
    $file.="echo \"SMIN          $paraMaxSmin\"    >> $fileMaxhomCshTmp\n";
    $file.="echo \"SMAX          $paraMaxSmax\"    >> $fileMaxhomCshTmp\n";
    $file.="echo \"GAP_OPEN      $paraMaxGo\"      >> $fileMaxhomCshTmp\n";
    $file.="echo \"GAP_ELONG     $paraMaxGe\"      >> $fileMaxhomCshTmp\n";
    $file.="echo \"WEIGHT1       $paraMaxWeight1\" >> $fileMaxhomCshTmp\n";
    $file.="echo \"WEIGHT2       $paraMaxWeight2\" >> $fileMaxhomCshTmp\n";
    $file.="echo \"WAY3-ALIGN    NO\"              >> $fileMaxhomCshTmp\n";
    $file.="echo \"INDEL_1       $paraMaxIndel1\"  >> $fileMaxhomCshTmp\n";
    $file.="echo \"INDEL_2       $paraMaxIndel2\"  >> $fileMaxhomCshTmp\n";
    $file.="echo \"RELIABILITY   NO\"              >> $fileMaxhomCshTmp\n";
    $file.="echo \"FILTER_RANGE  10.0\"            >> $fileMaxhomCshTmp\n";
    $file.="echo \"NBEST         1\"               >> $fileMaxhomCshTmp\n";
    $file.="echo \"MAXALIGN      $paraMaxNali\"    >> $fileMaxhomCshTmp\n";
    $file.="echo \"THRESHOLD     $paraMaxThresh\"  >> $fileMaxhomCshTmp\n";
    $file.="echo \"SORT          $paraMaxSort\"    >> $fileMaxhomCshTmp\n";
    $file.="echo \"HSSP          $fileHsspOut\"    >> $fileMaxhomCshTmp\n";
    $file.="echo \"SAME_SEQ_SHOW YES\"             >> $fileMaxhomCshTmp\n";
    $file.="echo \"SUPERPOS      NO\"              >> $fileMaxhomCshTmp\n";
    $file.="echo \"PDB_PATH      $dirMaxPdb\"      >> $fileMaxhomCshTmp\n";
    $file.="echo \"PROFILE_OUT   $paraMaxProfileOut\"  >> $fileMaxhomCshTmp\n";
    $file.="echo \"STRIP_OUT     $fileStripOut\"   >> $fileMaxhomCshTmp\n";
    $file.="echo \"LONG_OUT      NO\"              >> $fileMaxhomCshTmp\n";
    $file.="echo \"DOT_PLOT      NO\"              >> $fileMaxhomCshTmp\n";
    $file.="echo \"RUN\"                           >> $fileMaxhomCshTmp\n";

    $file.="#==================================================\n";
    $file.="# part for running MAXHOM\n";
    $file.="#==================================================\n";
    $file.="$tmpNice $exeMaxLoc -d=$fileDefaultLoc -nopar < $fileMaxhomCshTmp\n";
    $file.="\n";
    $file.="#==================================================\n";
    $file.="# clean up\n";
    $file.="#==================================================\n";
    $file.="rm -f $fileMaxhomCshTmp\n";
    $file.="rm -f MAXHOM_ALI.$jobid\n";
    $file.="rm -f filter.list_$jobid\n";
    $file.="\n";
    $file.="exit\n";

    $fhoutTmp="FHOUT_maxhomGetCsh";
    open("$fhoutTmp",">".$fileMaxhomCsh) || return(0,"*** maxhomGetCsh failed to open new $fileMaxhomCsh");
    print $fhoutTmp $file;
    close($fhoutTmp);
    $file="";

    if (-e $fileMaxhomCsh) {
	system("chmod +x $fileMaxhomCsh");
	return(1,"ok");}

    return(0,"*** maxhomGetCsh fileMaxhomCsh missing (maxhom csh)");
}				# end maxhomGetCsh

#==============================================================================
sub maxhomGetThresh4PP {
    local($minIdeRdLoc)=@_;
    local($thresh_now,$tmp,$thresh_txt);
    $[ =1 ;
#----------------------------------------------------------------------
#   maxhomGetThresh4PP          translates cut-off ide into text input for MAXHOM csh
#       note:                   special for PP, as assumptions about upper/lower
#       in:                     ($LisExpert,$expertMinIde,$minIde,$minIdeRd
#       out:                    $txt 'FORMULA+/-n'
#----------------------------------------------------------------------
    $thresh_now=$minIdeRdLoc;
				# final txt for MAXHOM cshell (FORMULA,FORMULA-n,FORMULA+n)
    if   ($thresh_now>25) {$tmp=$thresh_now-25;
			   $thresh_txt="FORMULA+"."$tmp"; }
    elsif($thresh_now<25) {$tmp=25-$thresh_now;
			   $thresh_txt="FORMULA-"."$tmp"; }
    else                  {$thresh_txt="FORMULA"; }
    return($thresh_txt);
}				# end of maxhomGetThresh4PP

#==============================================================================
sub maxhomMakeLocalDefault {
    local($fileInDef,$fileLocDef,$dirWorkLoc)=@_;
    local($sbrName);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   maxhomMakeLocalDefault      build local maxhom default file, and set PATH!!
#       in:                     $fileInDef,$fileLocDef,$dirWorkLoc
#       out:                    
#       err:                    ok=(1,'ok'), err=(0,'msg')
#-------------------------------------------------------------------------------
    $sbrName="lib-col:maxhomMakeLocDef";
				#---------------------------------------------------------
				# build local maxhom default file, set COREPATH=Dir_work
				#---------------------------------------------------------
    open(MAX_DEF,  "$fileInDef")   || 
	return(0,"*** $sbrName: cannot open input file '$fileInDef'!");
    open(MAX_N_DEF,">$fileLocDef") || 
	return(0,"*** $sbrName: cannot open output file '$fileLocDef'!");
    while (<MAX_DEF>) {
	chop;
	next if ($_=~/^\#/);
	if    ($_=~/COREPATH/ && $_ !~ /$dirWorkLoc/){
	    $_="COREPATH                  :   ".$dirWorkLoc;}
	elsif ($_=~/COREFILE/ && $_ =~ /$dirWorkLoc/){
	    $_="COREFILE                  :   MAXHOM_ALI.";}
#	    $_="COREFILE                  :   $dirWorkLoc/MAXHOM_ALI.";}
	print MAX_N_DEF "$_\n"; }
    close (MAX_DEF) ;
    close (MAX_N_DEF) ;
    return(1,"ok $sbrName");
}				# end of maxhomMakeLocalDefault

#==============================================================================
sub maxhomRunLoop {
    local ($date,$niceL,$exeMaxL,$fileMaxDefL,$fileJobIdL,$dirWorkLoc,
	   $fileHsspInL,$fileHsspAliListL,$fileHsspOutL,$fileMaxMetricL,$dirMaxPdbL,
	   $LprofileL,$paraSminL,$paraSmaxL,$paraGoL,$paraGeL,$paraW1L,$paraW2L,
	   $paraIndel1L,$paraIndel2L,$paraNaliL,$paraThreshL,$paraSortL,$paraProfOutL,
	   $fileStripOutL,$fileFlagNoHsspL,$paraMinLaliPdbL,
	   $paraTimeOutL,$fhTraceLoc,$fileScreenLoc)=@_;
    local ($maxCmdL,$start_at,$alarm_sent,$alarm_timer,$thresh_txt);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   maxhomRunLoop               loops over a maxhom run (until paraTimeOutL = 3hrs)
#       in:                     see program...
#       out:                    (0,'error message',0), (1,'error in pdbid',1), 
#       out:                    (1,0|pdbidFound,0|1) last arg=0 if self, =1 if ali
#       err:                    ok=(1,'ok|pdbid',0|1), err=(0,'msg',0)
#--------------------------------------------------------------------------------
    $sbrName="maxhomRunLoop";
    return(0,"*** $sbrName: not def date!",0)             if (! defined $date);
    return(0,"*** $sbrName: not def niceL!",0)            if (! defined $niceL);
    return(0,"*** $sbrName: not def exeMaxL!",0)          if (! defined $exeMaxL);
    return(0,"*** $sbrName: not def fileMaxDefL!",0)      if (! defined $fileMaxDefL);
    return(0,"*** $sbrName: not def fileJobIdL!",0)       if (! defined $fileJobIdL);
    return(0,"*** $sbrName: not def dirWorkLoc!",0)       if (! defined $dirWorkLoc);
    return(0,"*** $sbrName: not def fileHsspInL!",0)      if (! defined $fileHsspInL);
    return(0,"*** $sbrName: not def fileHsspAliListL!",0) if (! defined $fileHsspAliListL);
    return(0,"*** $sbrName: not def fileHsspOutL!",0)     if (! defined $fileHsspOutL);
    return(0,"*** $sbrName: not def fileMaxMetricL!",0)   if (! defined $fileMaxMetricL);
    return(0,"*** $sbrName: not def dirMaxPdbL!",0)       if (! defined $dirMaxPdbL);
    return(0,"*** $sbrName: not def LprofileL!",0)        if (! defined $LprofileL);
    return(0,"*** $sbrName: not def paraSminL!",0)        if (! defined $paraSminL);
    return(0,"*** $sbrName: not def paraSmaxL!",0)        if (! defined $paraSmaxL);
    return(0,"*** $sbrName: not def paraGoL!",0)          if (! defined $paraGoL);
    return(0,"*** $sbrName: not def paraGeL!",0)          if (! defined $paraGeL);
    return(0,"*** $sbrName: not def paraW1L!",0)          if (! defined $paraW1L);
    return(0,"*** $sbrName: not def paraW2L!",0)          if (! defined $paraW2L);
    return(0,"*** $sbrName: not def paraIndel1L!",0)      if (! defined $paraIndel1L);
    return(0,"*** $sbrName: not def paraIndel2L!",0)      if (! defined $paraIndel2L);
    return(0,"*** $sbrName: not def paraNaliL!",0)        if (! defined $paraNaliL);
    return(0,"*** $sbrName: not def paraThreshL!",0)      if (! defined $paraThreshL);
    return(0,"*** $sbrName: not def paraSortL!",0)        if (! defined $paraSortL);
    return(0,"*** $sbrName: not def paraProfOutL!",0)     if (! defined $paraProfOutL);
    return(0,"*** $sbrName: not def fileStripOutL!",0)    if (! defined $fileStripOutL);
    return(0,"*** $sbrName: not def fileFlagNoHsspL!",0)  if (! defined $fileFlagNoHsspL);
    return(0,"*** $sbrName: not def paraMinLaliPdbL!",0)  if (! defined $paraMinLaliPdbL);

    return(0,"*** $sbrName: not def paraTimeOutL!",0)     if (! defined $paraTimeOutL);
    $fhTraceLoc="STDOUT"                                  if (! defined $fhTraceLoc);
    $fileScreenLoc=0                                      if (! defined $fileScreenLoc);
				# check existence of files
    return(0,"*** $sbrName: miss input file '$fileHsspInL'!",0)      if (! -e $fileHsspInL &&
									 ! -l $fileHsspInL);
    return(0,"*** $sbrName: miss input exe  '$exeMaxL'!",0)          if (! -e $exeMaxL &&
									 ! -l $exeMaxL);
    return(0,"*** $sbrName: miss input file '$fileMaxDefL'!",0)      if (! -e $fileMaxDefL &&
									 ! -l $fileMaxDefL);
    return(0,"*** $sbrName: miss input file '$fileHsspAliListL'!",0) if (! -e $fileHsspAliListL &&
									 ! -l $fileHsspAliListL);
    return(0,"*** $sbrName: miss input file '$fileMaxMetricL'!",0)   if (! -e $fileMaxMetricL &&
									 ! -l $fileMaxMetricL);
    $pdbidFound="";
    $LisSelf=0;			# is PDBid in HSSP? / are homologues?

				# ------------------------------
				# set the elapse time in seconds before an alarm is sent
#    $paraTimeOutL= 1;	# ~ 3 heures
    $msgHere="";
				# ------------------------------
				# (1) build up MaxHom input
    ($msg,$warn)=		# check existence of files asf
	&maxhomGetArgCheck($exeMaxL,$fileMaxDefL,$fileHsspInL,$fileHsspAliListL,
			   $fileMaxMetricL);
    if (length($msg)>1){
	return(0,"$msg",0);} $msgHere.="--- $sbrName $warn\n";
    
#     $maxCmdL=			# get command line argument for starting MaxHom
# 	&maxhomGetArg($niceL,$exeMaxL,$fileMaxDefL,$fileJobIdL,$fileHsspInL,$fileHsspAliListL,
# 		      $LprofileL,$fileMaxMetricL,$paraSminL,$paraSmaxL,$paraGoL,$paraGeL,
# 		      $paraW1L,$paraW2L,$paraIndel1L,$paraIndel2L,$paraNaliL,$paraThreshL,
# 		      $paraSortL,$fileHsspOutL,$dirMaxPdbL,$paraProfOutL,$fileStripOutL);

    $fileMaxhomCsh=   $dirWorkLoc."maxhom_".$fileJobIdL.".csh";
    $fileMaxhomCshTmp=$dirWorkLoc."MAXHOM_".$jobid.".temp";


    ($Lok,$msg)=		# get command line argument for starting MaxHom
	&maxhomGetCsh($niceL,$exeMaxL,$fileMaxDefL,$fileJobIdL,$fileHsspInL,$fileHsspAliListL,
		      $LprofileL,$fileMaxMetricL,$paraSminL,$paraSmaxL,$paraGoL,$paraGeL,
		      $paraW1L,$paraW2L,$paraIndel1L,$paraIndel2L,$paraNaliL,$paraThreshL,
		      $paraSortL,$fileHsspOutL,$dirMaxPdbL,$paraProfOutL,$fileStripOutL,
		      $fileMaxhomCshTmp,$fileMaxhomCsh);

    $maxCmdL= $fileMaxhomCsh;
    $maxCmdL.=" >> $fileScreenLoc" if ($fileScreenLoc && length($fileScreenLoc)>1);

				# --------------------------------------------------
				# the thing that does IT!
				# --------------------------------------------------
#    while ( ! -f $fileHsspOutL ) { 
#	$msgHere.="--- $sbrName \t first trial to get $fileHsspOutL, run:\n";
#	$msgHere.="$maxCmdL\n";

#	$Lok=
#	    &run_program($maxCmdL,$fhTraceLoc); # its running!
#	($Lok,$msg)=
#	    &sysRunProg($maxCmdL,$fileScreenLoc,$fhTraceLoc);

				# ------------------------------
				# no HSSP file -> loop
#	if ( ! -f $fileHsspOutL ) {
#	    if (! $start_at) {	# switch a timer on
#		$start_at= time(); }
				# test if an alarm is needed
#	    if (! $alarm_sent && (time() - $start_at) > $paraTimeOutL) {
				# **************************************************
				# NOTE this SBR is PP specific
				# **************************************************
#		&ctrlAlarm("SUICIDE: In max_loop for more than $alarm_timer... (killer!)".
#			   "$msgHere");
#		$alarm_sent=1;
#		return(0,"maxhom SUICIDE on $fileHsspOutL".$msgHere,0); 
#	    }
				# create a trace file
#	    open("NOHSSP","> $fileFlagNoHsspL") || 
#		warn "-*- $sbrName WARNING cannot open $fileFlagNoHsspL: $!\n";
#	    print NOHSSP " problem with maxhom ($fileHsspOutL)\n"," $date\n";
#	    print NOHSSP `ps -ela`;
#	    sleep 10;
#	    close(NOHSSP);
#	unlink ($fileFlagNoHsspL); }
#    }				# end of loop 

				# --------------------------------------------------
    if (-e $fileHsspOutL){	# is HSSP file -> check
	($Lok,$kwd,$msg)=
	    &maxhomCheckHssp($fileHsspOutL,$paraMinLaliPdbL);
	return(0,"*** $sbrName ERROR after 'maxhomCheckHssp: ".
	       "kwd=$kwd, msg=$msg'\n".$msgHere,0) if (! $Lok);}
    else {return(0,"*** $sbrName ERROR after loop: no HSSP $fileHsspOutL".
		 $msgHere,0);}
				# --------------------------------------------------
				# maxhom against itself (no homologues found)
    if ($kwd eq "empty") {	# => no ali
	$LisSelf=1;$LisPdb=0;$pdbidFound=" ";
	($Lok,$msg)=
	    &maxhomRunSelf($niceL,$exeMaxL,$fileMaxDefL,$fileJobIdL,$fileHsspInL,
			   $fileHsspOutL,$fileMaxMetricL,$fhTraceLoc,$fileScreenLoc);
	return(0,"*** ERROR $sbrName 'maxhomRunSelf' wrong".
	       $msg."\n".$msgHere,0) if (! $Lok || ! -e $fileHsspOutL);}
    elsif ($kwd eq "self"){ # is self already
	$LisSelf=1;$LisPdb=0;$pdbidFound=" ";}
    elsif ($kwd eq "pdbid"){
	$tmp=$msg;$tmp=~s/^pdbid=([^\n]*)\n.*$/$1/;
	$LisSelf=0;$LisPdb=1;$pdbidFound=$tmp;}
    elsif ($kwd eq "ok"){
	$LisSelf=0;$LisPdb=0;$pdbidFound=" ";}
    else {
	return(0,"*** $sbrName ERROR after 'maxhomCheckHssp: kwd=$kwd, unclear\n".
	       "msg=$msg\n".$msgHere,0) if (! $Lok);}

    if    ($LisPdb){
	if    (! defined $pdbidFound || length($pdbidFound)<4){
	    return(1,"error in pdbid",0);} # error
	elsif (defined $pdbidFound && length($pdbidFound)>4 && ! $LisSelf){
	    return(1,"$pdbidFound",0);}	# PDBid + ali
	return(1,"$pdbidFound",1);} # appears to be PDB but no ali
    elsif ($LisSelf){
	return(1,0,1);}		# no ali
    return(1,0,0);		# ok
}				# end maxhomRunLoop

#==============================================================================
sub maxhomRunSelf {
    local($niceLoc,$exeMaxLoc,$fileMaxDefLoc,$fileJobIdLoc,$fileHsspInLoc,
	  $fileHsspOutLoc,$fileMaxMetrLoc,$fhTraceLoc,$fileScreenLoc)=@_;
    local($sbrName,$msgHere,$msg,$tmp,$Lok,$LprofileLoc,$dirMaxPdbLoc,$paraMaxProfOutLoc,
	  $paraMaxSminLoc,$paraMaxSmaxLoc,$paraMaxGoLoc,$paraMaxGeLoc,
	  $paraMaxW1Loc,$paraMaxW2Loc,$paraMaxIndel1Loc,$paraMaxIndel2Loc,
	  $paraMaxNaliLoc,$paraMaxThreshLoc,$paraMaxSortLoc,$fileStripOutLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   maxhomRunSelf               runs a MaxHom: search seq against itself
#                               NOTE: needs to run convert_seq to make sure
#                                     that 'itself' is in FASTA format
#       in:                     many
#       out:                    
#       err:                    ok=(1,'ok'), err=(0,'msg')
#-------------------------------------------------------------------------------
    $sbrName="lib-col:maxhomRunSelf";
    return(0,"*** $sbrName: not def niceLoc!")            if (! defined $niceLoc);
    return(0,"*** $sbrName: not def exeMaxLoc!")          if (! defined $exeMaxLoc);
    return(0,"*** $sbrName: not def fileMaxDefLoc!")      if (! defined $fileMaxDefLoc);
    return(0,"*** $sbrName: not def fileJobIdLoc!")       if (! defined $fileJobIdLoc);
    return(0,"*** $sbrName: not def fileHsspInLoc!")      if (! defined $fileHsspInLoc);
    return(0,"*** $sbrName: not def fileHsspOutLoc!")     if (! defined $fileHsspOutLoc);
    return(0,"*** $sbrName: not def fileMaxMetrLoc!")     if (! defined $fileMaxMetrLoc);
    $fhTraceLoc="STDOUT"                                  if (! defined $fhTraceLoc);
    $fileScreenLoc=0                                      if (! defined $fileScreenLoc);
				# check existence of files
    return(0,"*** $sbrName: miss input file '$fileHsspInLoc'!")  if (! -e $fileHsspInLoc &&
								     ! -l $fileHsspInLoc);
    return(0,"*** $sbrName: miss input exe  '$exeMaxLoc'!")      if (! -e $exeMaxLoc &&
								     ! -l $exeMaxLoc);
    return(0,"*** $sbrName: miss input file '$fileMaxDefLoc'!")  if (! -e $fileMaxDefLoc &&
								     ! -l $fileMaxDefLoc);
    return(0,"*** $sbrName: miss input file '$fileMaxMetrLoc'!") if (! -e $fileMaxMetrLoc &&
								     ! -l $fileMaxMetrLoc);
    $msgHere="";
				# ------------------------------
				# security check: is FASTA?
#    $Lok=&isFasta($fileHsspInLoc);
#    if (!$Lok){
#	return(0,"*** $sbrName: input must be FASTA '$fileHsspInLoc'!");}
				# ------------------------------
				# prepare MaxHom
    ($msg,$warn)=		# check existence of files asf
	&maxhomGetArgCheck($exeMaxLoc,$fileMaxDefLoc,$fileHsspInLoc,$fileHsspInLoc,
			   $fileMaxMetrLoc);
    return(0,"$msg")            if (length($msg)>1);
    $msgHere.="--- $sbrName $warn\n";	

    $LprofileLoc=      "NO";	# build up argument
    $paraMaxSminLoc=   "-0.5";     $paraMaxSmaxLoc=   "1";
    $paraMaxGoLoc=     "3.0";      $paraMaxGeLoc=     "0.1";
    $paraMaxW1Loc=     "YES";      $paraMaxW2Loc=     "NO";
    $paraMaxIndel1Loc= "NO";       $paraMaxIndel2Loc= "NO";
    $paraMaxNaliLoc=   "5";        $paraMaxThreshLoc= "ALL";
    $paraMaxSortLoc=   "DISTANCE"; $dirMaxPdbLoc=     "/data/pdb/";
    $paraMaxProfOutLoc="NO";       $fileStripOutLoc=  "NO";
				# --------------------------------------------------
    $maxCmdLoc=			# get command line argument for starting MaxHom
	&maxhomGetArg($niceLoc,$exeMaxLoc,$fileMaxDefLoc,$fileJobIdLoc,
		      $fileHsspInLoc,$fileHsspInLoc,$LprofileLoc,$fileMaxMetrLoc,
		      $paraMaxSminLoc,$paraMaxSmaxLoc,$paraMaxGoLoc,$paraMaxGeLoc,
		      $paraMaxW1Loc,$paraMaxW2Loc,$paraMaxIndel1Loc,$paraMaxIndel2Loc,
		      $paraMaxNaliLoc,$paraMaxThreshLoc,$paraMaxSortLoc,
		      $fileHsspOutLoc,$dirMaxPdbLoc,$paraMaxProfOutLoc,$fileStripOutLoc);
				# --------------------------------------------------
				# run maxhom self
#    $Lok=
#	&run_program($maxCmdLoc,$fhTraceLoc,"warn");

    ($Lok,$msg)=
	&sysRunProg($maxCmdLoc,$fileScreenLoc,$fhTraceLoc);

    return(0,"*** $sbrName: fault in maxhom ($exeMaxLoc)\n")
	if (! $Lok || ! -e $fileHsspOutLoc); # output file missing

    return(1,"ok $sbrName");
}				# end of maxhomRunSelf

#==============================================================================
sub msfCheckFormat {
    local ($fileMsf) = @_;
    local ($format,$tmp,$kw_msf,$kw_check,$ali_sec,$ali_des_sec,$valid_id_len,$fhLoc,
	   $uniq_id, $same_len, $nb_al, $seq_tmp, $ali_des_len);
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
	$kw_msf=1    if (! $ali_des_seq && ($tmp =~ /MSF:\s*\d*\s/));
	next if (! $kw_msf);
                         	# CHECK keyword and value
	$kw_check=1  if (!$ali_des_seq && ($tmp =~ /CHECK:\s*\d*/));
	next if (! $kw_check);
                         	# begin of the alignment description section 
                         	# the line with MSF and CHECK must end with ".."
	if (! $ali_sec && $tmp =~ /MSF:\D*(\d*).*CHECK:.*\.\.\s*$/) {
	    $ali_des_len=$1;
	    $ali_des_sec=1;}
                                # ------------------------------
                         	# the alignment description section
	if (! $ali_sec && $ali_des_sec) { 
            if ($tmp=~ /^\s*NAME:\s*(\S*).*LEN:.*\d.*CHECK:.*\d.*WEIGHT:.*\d.*/) {
		$id=$1;
		$valid_id_len=0 if (length($id) > 14);	# is sequence name <= 14
		if ($SEQID{$id}) { # is the sequence unique?
		    $uniq_id=0; $ali_sec=1;
		    last; }
		$lenRd=$tmp;$lenRd=~s/^.*LEN\:\s*(\d+)\s*CHEC.*$/$1/;
		$SEQID{$id}=1;  # store seq ID
		$SEQL{$id}= 0;	# initialise seq len array
	    } }
                                # ------------------------------
                        	# begin of the alignment section
	$ali_sec=1    if ($ali_des_sec && $tmp =~ /\/\/\s*$/);
                                # ------------------------------
                        	# the alignment section
	next if (! $ali_sec);
	if ($tmp =~ /^\s*(\S+)\s+(.*)$/) {
	    $id= $1;
	    next if (! defined $SEQID{$id} || ! $SEQID{$id});
	    ++$SEQID{$id};
	    $seq_tmp= $2;$seq_tmp=~ s/\s|\n//g;
	    $SEQUENCE{$id}=$seq_tmp;
	    $SEQL{$id}+= length($seq_tmp);}
	
    }
    close($fhLoc);
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
		$idError=$id;
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
    $msg.="*** $sbrNameLoc wrong MSF: length given and real differ (problem for $idError)!\n" 
	if (!$lenok);
    return(0,$msg) if (length($msg)>1);
    return(1,"$sbrNameLoc ok");
}				# end msfCheckFormat

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
    $TO=~ s/.*\///g;
				# ------------------------------
				# write into file
    print $fhoutLoc 
	"MSF of: ",$FROM," from:    1 to:   ",length($stringLoc[1])," \n",
	$TO," MSF: ",length($stringLoc[1]),
	"  Type: P 11-Nov-98 14:00 Check: 1933 ..\n \n \n";

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
	print "*** ERROR in myprt_npoints (lib-col.pl): \n";
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
	warn "*** ERROR lib-col:open_file: Cannot open file '$file_name'\n" ;
	if ( $log_file ) {
	    print $log_file "*** lib-col:open_file: Cannot create new file '$file_name'\n" ;}
	return(0);
    } );
    return(1);
}				# end of open_file

#==============================================================================
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
    $sbrName="lib-col:pirRdSeq";$fhinLoc="FHIN"."$sbrName";

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

#==============================================================================
sub ppHsspRdExtrHeader {
    local ($file_in) = @_ ;
    local ($fhinLoc,$sbrName,$msg,$ct,$tmp,$tmp2,@tmp,$it);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   ppHsspRdExtrHeader          extracts the summary from HSSP header (for PP)
#       out (GLOBAL):           $rd_hssp{} (for ppTopitsHdWrt!!!)
#--------------------------------------------------------------------------------
    $sbrName="ppHsspRdExtrHeader";$fhinLoc="FHIN"."$sbrName";

    $Lok=       &open_file("$fhinLoc","$file_in");
    if (! $Lok){$msg="*** ERROR $sbrName: '$file_in' not opened\n";
		return(0,$msg,"error");}

    while(<$fhinLoc>){
	last if ($_=/^\#\# PROTEINS/);}
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
    $rd_hssp{"nali"}=$ct;
    return(1,"ok $sbrName",%rd_hssp);
}				# end of ppHsspRdExtrHeader

#==============================================================================
sub ppStripRd {
    local ($file_in) = @_ ;
    local ($fhinLoc,$sbrName,$msg,@strip);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    ppStripRd                   reads the new strip file generated for PP
#--------------------------------------------------------------------------------
    $sbrName="ppStripRd";$fhinLoc="FHIN"."$sbrName";

    $Lok=       &open_file("$fhinLoc","$file_in");
    if (! $Lok){$msg="*** ERROR $sbrName: '$file_in' not opened\n";
		return(0,$msg,"error");}

    $#strip=0;
    while(<$fhinLoc>){
	push(@strip,$_);}close($fhinLoc);
    return(1,"ok $sbrName",@strip);
}				# end of ppStripRd

#==============================================================================
sub ppTopitsHdWrt {
    local ($file_in,$mixLoc,@strip) = @_ ;
    local ($sbrName,$msg,$fhout,$Lwatch,$Lrest,$strip,$it);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    ppTopitsHdWrt              writes the final PP TOPITS output file
#       in:                     $file_in,$mixLoc,@strip
#       in:                     output file, ratio str/seq (100=only struc), 
#       in:                        content of strip file
#       out:                    file written ($file_in)
#       err:                    (0,$err) (1,'ok')
#--------------------------------------------------------------------------------
    $sbrName="ppStripRd";$fhout="FHOUT"."$sbrName";

    $Lok=       &open_file("$fhout",">$file_in");
    if (! $Lok){$msg="*** ERROR $sbrName: '$file_in' not opened (output file)\n";
		return(0,$msg);}

    $Lwatch=$Lrest=0;
    foreach $strip (@strip) {
	$strip=~s/\n//g;
	if ( $Lrest ) {
	    print $fhout "$strip\n"; }
	elsif ( $Lwatch && ($strip=~/^---/) ){
	    print $fhout "--- \n";
	    print $fhout "--- TOPITS ALIGNMENTS HEADER: PDB_POSITIONS FOR ALIGNED PAIR\n";
	    printf 
		$fhout "%5s %4s %4s %4s %4s %4s %4s %4s %-6s\n",
		"RANK","PIDE","IFIR","ILAS","JFIR","JLAS","LALI","LEN2","ID2";
	    foreach $it (1 .. $rd_hssp{"nali"}){
		printf 
		    $fhout "%5d %4d %4d %4d %4d %4d %4d %4d %-6s\n",
		    $it,int(100*$rd_hssp{"ide","$it"}),
		    $rd_hssp{"ifir","$it"},$rd_hssp{"ilas","$it"},
		    $rd_hssp{"jfir","$it"},$rd_hssp{"jlas","$it"},
		    $rd_hssp{"lali","$it"},$rd_hssp{"len2","$it"},
		    $rd_hssp{"id2","$it"};
	    }
	    $Lrest=1; 
	    print $fhout "$strip\n"; }
	elsif ($strip =~ /^--- .* SUMMARY/){ 
	    $Lwatch=1; 
	    print $fhout "$strip\n"; }
	elsif ($strip =~ /^--- NAME2/) { # abbreviations
	    print $fhout "$strip\n";
	    print $fhout "--- IFIR         : position of first residue of search sequence\n";
	    print $fhout "--- ILAS         : position of last residue of search sequence\n";
	    print $fhout "--- JFIR         : PDB position of first residue of remote homologue\n";
	    print $fhout "--- JLAS         : PDB position of last residue of remote homologue\n";}
	elsif ($strip =~ /^--- .* PARAMETER/) { # parameter
	    print $fhout "$strip\n";
				# hack br 98-05 do clean some day!
	    if (! defined $mixLoc){ print "-*- WARN $sbrName mixLoc not defined \n";
				    $mixLoc=50;}
	    $mixLoc=~s/\D//g; $mixLoc=50 if (length($mixLoc)<1); # hack br 98-05 
	    printf $fhout 
		"--- str:seq= %3d : structure (sec str, acc)=%3d%1s, sequence=%3d%1s\n",
		int($mixLoc),int($mixLoc),"%",int(100-$mixLoc),"%"; }
	else {
	    print $fhout "$strip\n"; }
    }
    close($fhout);
    return(1,"ok $sbrName");
}				# end of ppTopitsHdWrt

#===============================================================================
sub prodomRun {
    local($fileInLoc,$fileOutTmpLoc,$fileOutLoc,$fhErrSbr,$niceLoc,
	  $exeBlast,$envBlastDb,$envBlastMat,$parBlastDb,$parBlastN,$parBlastE,$parBlastP)=@_;
    local($sbrName,$fhinLoc,$tmp,$Lok,$dbTmp,$cmd,$msg,%head,@idRd,@idTake);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   prodomRun                   runs a BLASTP against the ProDom db
#       in:                     many
#       out:                    (1,'ok',$nhits_below_threshold)
#       err:                    (0,'msg')
#       err:                    (2,'msg' -> no result found)
#-------------------------------------------------------------------------------
    $sbrName="lib-col:prodomRun";$fhinLoc="FHIN"."$sbrName";
				# ------------------------------
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc!")          if (! defined $fileInLoc);
    return(0,"*** $sbrName: not def fileOutTmpLoc!")      if (! defined $fileOutTmpLoc);
    return(0,"*** $sbrName: not def fileOutLoc!")         if (! defined $fileOutLoc);
    $fhErrSbr=   "STDOUT"                                 if (! defined $fhErrSbr);
    $niceLoc=    " "                                      if (! defined $niceLoc);
    $exeBlast=   "/usr/pub/bin/molbio/blastp"             if (! defined $exeBlast);
    $envBlastDb= "/home/rost/pub/ncbi/db/"                if (! defined $envBlastDb);
    $envBlastMat="/home/pub/molbio/blast/blastapp/matrix" if (! defined $envBlastMat);
    $parBlastDb= "/home/rost/pub/ncbi/db/prodom"          if (! defined $parBlastDb);
    $parBlastN=  "500"                                    if (! defined $parBlastN);
    $parBlastE=    "0.1"                                  if (! defined $parBlastE);
    $parBlastP=    "0.1"                                  if (! defined $parBlastP);
    
    return(0,"*** $sbrName: no in file '$fileInLoc'!")    if (! -e $fileInLoc &&
							      ! -l $fileInLoc);
				# ------------------------------
				# set env
    $ENV{'BLASTMAT'}=$envBlastMat;
    $ENV{'BLASTDB'}= $envBlastDb;
				# ------------------------------
				# security erase
    unlink($fileOutTmpLoc)      if (-e $fileOutTmpLoc);
				# ------------------------------
				# run BLAST
    $dbTmp=$parBlastDb;$dbTmp=~s/\/$//g;
#    $cmd=  "$niceLoc $exeBlast $dbTmp $fileInLoc E=$parBlastE B=$parBlastN >> $fileOutTmpLoc ";
#    $cmd=  "$exeBlast -p blastp -d $dbTmp -i $fileInLoc -E $parBlastE -B $parBlastN >> $fileOutTmpLoc ";
    $cmd=  "$exeBlast -p blastp -d $dbTmp -i $fileInLoc -B $parBlastN >> $fileOutTmpLoc ";
    print $fhErrSbr "--- $sbrName: system \t $cmd\n";
    system("$cmd");
				# ------------------------------
				# read BLAST header
    ($Lok,$msg,%head)=
	&blastpRdHdr($fileOutTmpLoc,$fhErrSbr);

    return(0,"*** ERROR $sbrName: after blastpRdHdr msg=$msg") if (! $Lok);
    return(2,"*** ERROR $sbrName: after blastpRdHdr no id head{id} defined") 
	if (! defined $head{"id"} || length($head{"id"})<2);
				# ------------------------------
				# select id below threshold
    @idRd=split(/,/,$head{"id"});$#idTake=0;
    foreach $id (@idRd){
	push(@idTake,$id) if (defined $head{"$id","prob"} && 
			      $head{"$id","prob"} <= $parBlastP);}
    undef %head;		# save space
    $#idRd=0;			# save space
    return(0,"--- $sbrName: no hit below threshold P=".$parBlastP."\n",0)
	if ($#idTake==0);
				# ------------------------------
				# write PRODOM output
    $ctOk=$#idTake;
    ($Lok,$msg)=
	&prodomWrt($fileOutTmpLoc,$fileOutLoc,@idTake);
    return(0,"*** ERROR $sbrName: after prodomWrt msg=$msg") if (! $Lok);
    return(1,"ok $sbrName",$ctOk);
}				# end of prodomRun

#==============================================================================
sub prodomWrt {
    local($fileInLoc,$fileOutLoc,@idTake) = @_ ;
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   prodomWrt                   write the PRODOM data + BLAST ali
#       in:                     $fileBlast,$fileHANDLE_OUTPUTFILE,@id_to_read
#       in:                     NOTE: if $#id==0, none written!
#       out:                    (1,'ok') + written into FILE_HANDLE
#       err:                    (0,'msg')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."prodomWrt";$fhinLoc="FHIN"."$sbrName";$fhoutLoc="FHOUT"."$sbrName";
				# ------------------------------
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc!")        if (! defined $fileInLoc);
    return(0,"*** $sbrName: not def fileOutLoc!")       if (! defined $fileOutLoc);
    return(0,"*** $sbrName: no in file '$fileInLoc'!")  if (! -e $fileInLoc);
				# ------------------------------
				# open file and write header
    $Lok=       &open_file("$fhoutLoc",">$fileOutLoc");
    return(0,"*** ERROR $sbrName: new=$fileOutLoc not opened\n") if (! $Lok);
    print $fhoutLoc 
	"--- ------------------------------------------------------------\n",
	"--- Results from running BLAST against PRODOM domains\n",
	"--- \n",
	"--- PLEASE quote: \n",
	"---       F Corpet, J Gouzy, D Kahn (1998).  The ProDom database\n",
	"---       of protein domain families. Nucleic Ac Res 26:323-326.\n",
	"--- \n",
	"--- BEGIN of BLASTP output\n";
				# ------------------------------
				# extract those below threshold
    ($Lok,$msg)=
	&blastpExtrId($fileOutTmpLoc,$fhoutLoc,@idTake);

    return(0,"*** ERROR $sbrName: after blastpExtrId msg=$msg") if (! $Lok);
				# ------------------------------
				# links to ProDom
    print $fhoutLoc 
	"--- END of BLASTP output\n",
	"--- ------------------------------------------------------------\n",
	"--- \n",
	"--- Again: these results were obtained based on the domain data-\n",
	"--- base collected by Daniel Kahn and his coworkers in Toulouse.\n",
	"--- \n",
	"--- PLEASE quote: \n",
	"---       F Corpet, J Gouzy, D Kahn (1998).  The ProDom database\n",
	"---       of protein domain families. Nucleic Ac Res 26:323-326.\n",
	"--- \n",
	"--- The general WWW page is on:\n",
	"----      ---------------------------------------\n",
	"---       http://prodom.prabi.fr                 \n",
	"----      ---------------------------------------\n",
	"--- \n",
	"--- For WWW graphic interfaces to PRODOM, in particular for your\n",
	"--- protein family, follow the following links (each line is ONE\n",
	"--- single link for your protein!!):\n",
	"--- \n";
				# ------------------------------
				# define keywords
#    $txt1a="http://www.toulouse.inra.fr/prodom/cgi-bin/ReqProdomII.pl?id_dom1=";
    $txt1a="http://prodom.prabi.fr/prodom/current/cgi-bin/request.pl?question=DBEN&query=";
    $txt1b=" ==> multiple alignment, consensus, PDB and PROSITE links of domain ";
    $txt2a="http://prodom.prabi.fr/prodom/current/cgi-bin/request.pl?question=DBEN&query=";
#    $txt2a="http://www.toulouse.inra.fr/prodom/cgi-bin/ReqProdomII.pl?id_dom2=";
    $txt2b=" ==> graphical output of all proteins having domain ";
				# ------------------------------
				# establish links
    $ct=0;
    foreach $id (@idTake){
	$id=~s/\s//g;
	next if ($id !~/PD\d+/ || length($id)<1);
	++$ct;
	print $fhoutLoc "$txt1a".$id."$txt1b".$id."\n";
	print $fhoutLoc "$txt2a".$id."$txt2b".$id."\n";
    }
    if (! $ct) {
	print $fhoutLoc
	    "--- \n",
	    "--- no links found!\n";}
    else {
	print $fhoutLoc
	    "--- \n",
	    "--- NOTE: if you want to use the link, make sure the entire line\n",
	    "---       is pasted as URL into your browser!\n"}

    print $fhoutLoc
	"--- \n",
	"--- END of PRODOM\n",
	"--- ------------------------------------------------------------\n";
    close($fhoutLoc);
    return(1,"ok $sbrName");
}				# end of prodomWrt

#===============================================================================
sub ranGetString {
    local($seedLoc) = @_ ;
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   ranGetString                produces a random string 
#       in:                     $seedLoc=       seed (may be anything if the
#                                               command srand() has been executed!)
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."ranGetString";

    $ranMaxNum=    10000;	# highest number to pick from
    $ranNumLet=    2;		# number of letters (before and after number

				# letters to use
    $ranLetters=   "abcdefghijklmnopqrstuvwxyz";
    @ranLetters=   split(//,$ranLetters);

    $ranMaxNumLet= length($ranLetters);

				# seed random
    #srand(time^$$)
#	if (!defined $seedLoc);

    $res="";
				# get some character string
    $tmp="";
    foreach $itl (1..$ranNumLet) {
	$poslet=int(rand($ranMaxNumLet))+1; # randomly select sample 
	next if (! defined $ranLetters[$poslet]);
	$let=$ranLetters[$poslet];
	$tmp.=$let;}
    $res.=$tmp;
				# get some number
    $num=int(rand($ranMaxNum))+1; # randomly select sample 
    $res.="$num";

				# get some character string again
    $tmp="";
    foreach $itl (1..$ranNumLet) {
	$poslet=int(rand($ranMaxNumLet))+1; # randomly select sample 
	next if (! defined $ranLetters[$poslet]);
	$let=$ranLetters[$poslet];
	$tmp.=$let;}
    $res.=$tmp;

    return(1,$res);
}				# end of ranGetString

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
	    $rdrdb{"$des_in","$it"}=$tmp[$it];
	    $rdrdb{"$des_in","$it"}=~s/\s//g;}
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

#==============================================================================
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
		    $readnum[$it]=$it;
		    $READCOL[$it]=""; }}
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
sub rd_col_associative {
    local ($file_in,@des_in) = @_ ;
    local ($sbr_name,$fhin,$it,@tmp,$tmp,$des_in,%ptr,%rdcol);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    rd_col_associative         reads the content of a comma separated file
#       in:                     Names used for columns in perl file, e.g.,
#--------------------------------------------------------------------------------
				# avoid warning
    $READHEADER="";
				# set some defaults
    $fhin="FHIN_COL";
    $sbr_name="rd_col_associative";
    undef %rdcol; undef %ptr;
				# --------------------------------------------------
				# read RDB file
				# --------------------------------------------------
    &open_file("$fhin","$file_in");
    $ctLoc=0;
    while(<$fhin>){
	$_=~s/\n//g;
	next if (/^\#/);	# ignore RDB header
	++$ctLoc;			# delete leading blanks, commatas and tabs
	$_=~s/^\s*|\s*$|^,|,$|^\t|\t$//g;
	$#tmp=0;@tmp=split(/[,\t ]+/,$_);
	if ($ctLoc==1){
	    $Lok=0;
	    foreach $des (@des_in) {
		foreach $it (1..$#tmp) {
		    if ($des =~ /$tmp[$it]/){
			$ptr{$des}=$it;
			$Lok=1;
			last;}}}
	    if (!$Lok){print"*** ERROR in reading col format ($sbr_name), none found\n";
		       exit;}}
	else {
	    foreach $des (@des_in){
		if (defined $ptr{$des}){
		    $tmp=$ctLoc-1;
		    $rdcol{"$des","$tmp"}=$tmp[$ptr{$des}];}}}
    }close($fhin);
    $rdcol{"NROWS"}=$ctLoc-1;
    return (%rdcol);
}				# end of rd_col_associative

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
	    $rdrdb{"$des_in","$it"}=$tmp[$it];}
    }
    $rdrdb{"NROWS"}=$nrow_rd;
    $names=~s/,$//g;$rdrdb{"names"}=$names;
    return (%rdrdb);
}				# end of rd_rdb_associative

#==============================================================================
sub rdb2html {
    local ($fileRdb,$fileHtml,$fhout,$Llink,$scriptName) = @_ ;
    local (@headerRd,$tmp,@tmp,@colNames,$colNames,%body,$des,$ct,$fhin);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   rdb2html                    convert an RDB file to HTML
#       in:		        $fileRdb,$fileHtml,$fhout,$Llink 
#                               (Llink=1 -> links from column names to Notation in header)
#       ext                     open_file, 
#       ext                     wrtRdb2HtmlHeader,wrtRdb2HtmlBody
#       ext GLOBULAR:           wrtRdb2HtmlBodyColNames,wrtRdb2HtmlBodyAve
#--------------------------------------------------------------------------------
    $fhin="FHinRdb2html";
    &open_file("$fhin", "$fileRdb");

    $#headerRd=0;
				# ------------------------------
    while (<$fhin>) {		# read header of RDB file
	$tmp=$_;
	$_=~s/\n//g;
	last if (! /^\#/);
	push(@headerRd,$_);}
				# ------------------------------
				# get column names
    $tmp=~s/\n//g;$tmp=~s/^\t*|\t*$//g;
    @colNames=split(/\t/,$tmp);

    $body{"COLNAMES"}="";
    foreach $des (@colNames){	# store column names
	$body{"COLNAMES"}.="$des".",";}
	
				# ------------------------------
    while (<$fhin>) {		# skip formats
	$tmp=$_;
	last;}
				# ------------------------------
				# read body
    $ct=0;$Lave=0;
    while (<$fhin>) {
	$_=~s/\n//g;
	$_=~s/^\t*|\t*$//g;
	if (length($_)<1){
	    next;}
	@tmp=split(/\t/,$_);
	++$ct;
	foreach $it (1..$#tmp){	# store body
	    $key=$colNames[$it];
	    $body{"$ct","$key"}=$tmp[$it];}
	if ($tmp[1] =~ "^ave"){$Lave=1;}
    }
    
    $body{"NROWS"}=$ct;
				# end of reading RDB file
				# ------------------------------

				# ------------------------------
				# write output file
    if ($fhout ne "STDOUT"){
	&open_file("$fhout", ">$fileHtml");}

    @tmp=			# write header
	&wrtRdb2HtmlHeader($fhout,$scriptName,$fileRdb,$Llink,$Lave,$body{"COLNAMES"},@headerRd);
				# mark keys to be linked
    foreach $col (@colNames){
	$body{"link","$col"}=0;}
    foreach $col (@tmp){
	$body{"link","$col"}=1;}
				# write body
    &wrtRdb2HtmlBody($fhout,$Llink,%body);

				# add icons
    print $fhout 
	"<P><P><HR><P><P>\n",
	"<A HREF=\"http:\/\/www.columbia.edu\/~rost\/\">",
              "<IMG ALIGN=MIDDLE SRC=",
	      "\"http:\/\/www.columbia.edu\/~rost\/Dfig\/icon-br-home.gif\" ",
	       "ALT=\"Rost Home\"><\/A>\n",
	"<A HREF=\"mailto\:rost\@columbia.edu\">",
              "<IMG ALIGN=MIDDLE SRC=",
	      "\"http:\/\/www.columbia.edu\/~rost\/Dfig\/icon-br-home-mail.gif\" ",
	       "ALT=\"Mail to Rost\"><\/A>\n",
	"<A HREF=\"http:\/\/dodo.bioc.columbia.edu\/predictprotein\/\">",
              "<IMG ALIGN=MIDDLE SRC=",
	      "\"http:\/\/dodo.bioc.columbia.edu\/predictprotein\/Dicon\/icon-ppWorld.gif\" ",
	      "ALT=\"PredictProtein\"><\/A>\n",
	"<\/BODY>\n","<\/HTML>\n";
    print $fhout "\n";
    close($fhin);close($fhout);
}				# end of rdb2html

#==============================================================================
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

#==============================================================================
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
	    print "-*- WARN lib-col.pl:read_rdb_num2: READFORMAT for it=$it not defined\n";
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
sub segInterpret {
    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   segInterpret                reads FASTA-formatted output from SEG, counts 'x'
#       in:                     $fileInLoc
#       out:                    1|0,msg,$len(all),$lenComposition(only the 'x')
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="segInterpret";$fhinLoc="FHIN_"."segInterpret";
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
    return(&errSbr("miss in file '$fileInLoc'!"))  if (! -e $fileInLoc);

				# ------------------------------
				# read FASTA formatted file
				# ------------------------------
    open($fhinLoc,$fileInLoc) || return(&errSbr("fileInLoc=$fileInLoc, not opened"));
    $seq="";			# ------------------------------
    while (<$fhinLoc>) {	# read file
	$_=~s/\n//g;
	next if ($_=~/^\s*>/);	# skip id
	$seq.=$_;
    } close($fhinLoc);

				# ------------------------------
				# count 'x'
				# ------------------------------
    $seq=~s/\s//g;
    $seq=~tr/[a-z]/[A-Z]/;
				# count 'normal residues'
    $tmp=$seq;
    $tmp=~s/[^ABCDEFGHIKLMNPQRSTVWYZ]//g;
    $lenSeq=length($tmp);
				# count 'x'
    $tmp=$seq;
    $tmp=~s/[^X]//g;
    $lenCom=length($tmp);

    return(1,"ok $sbrName",($lenSeq+$lenCom),$lenCom);
}				# end of segInterpret

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

				# add species sub_directory
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

#==============================================================================
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

#==============================================================================
sub sysCatfile {
    local($niceLoc,$LdebugLoc,$fileToCatTo,@fileToCat) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   sysCatfile                  system call 'cat < file1 >> file2'
#       in:                     $niceLoc,$fileToCatTo,@fileToCat
#                               if not nice pass niceLoc=no (or nonice)
#       out:                    ok=(1,'cat a b') , else=(0,msg)
#-------------------------------------------------------------------------------
    $sbrName="sysCatfile";
    $niceLoc="" if (! defined $niceLoc ||
		    $niceLoc =~ /^no/ || $niceLoc eq " " || length($niceLoc)==0 );
				# check
    return(0,"*** $sbrName: needs 2 arg 'fToCopy fToCatTo'!")     if (! defined $fileToCatTo);
    return(0,"*** $sbrName: missing input file '$fileToCat[1]'!") if (! -e $fileToCat[1]);
				# loop over all files
    $msg="";
    foreach $fileToCat (@fileToCat){
	$Lok= system("$niceLoc cat < $fileToCat >> $fileToCatTo");
	$msg.="$sbrName \t '$niceLoc cat < $fileToCat >> $fileToCatTo'\n";
	if ($Lok != 0 || ! -e $fileToCatTo){
	    print "*** $sbrName ERROR: '$fileToCat -> $fileToCatTo' ($Lok)!"."$msg";
	    return(0,"*** $sbrName ERROR: '$fileToCat -> $fileToCatTo' ($Lok)!"."$msg");}}
    print "--- $sbrName: $msg"  if ($LdebugLoc);
    return(1,"$msg");
}				# end of sysCatfile

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
    $niceLoc=""                 if (! defined $niceLoc || $niceLoc =~/^no/);
				# check
    return(0,"*** $sbrName: missing input file '$fileToCopy'!") if (! -e $fileToCopy);
    return(0,"*** $sbrName: needs 2 arg 'fToCopy fToCopyTo'!") if (! defined $fileToCopyTo);

    if (-d $fileToCopyTo){	# is directory
	$fileToCopyTo.="/"      if ($fileToCopyTo !~/\/$/);}

    $Lok= system("$niceLoc \\cp $fileToCopy $fileToCopyTo");
#    return(0,"*** $sbrName: fail copy '$fileToCopy -> $fileToCopyTo' ($Lok)!") if (! $Lok);
    if    (-d $fileToCopyTo){	# is directory
	$tmp=$fileToCopy;$tmp=~s/^.*\///g;$tmp=$fileToCopyTo.$tmp;
	$Lok=0 if (! -e $tmp);}
    elsif (! -e $fileToCopyTo){ $Lok=0; }
    elsif (-e $fileToCopyTo)  { $Lok=1; }

    return(0,"*** $sbrName: fail copy '$fileToCopy -> $fileToCopyTo' ($Lok)!") if (! $Lok);
    
    return(1,"$niceLoc \\cp $fileToCopy $fileToCopyTo");
}				# end of sysCpfile

#===============================================================================
sub sysDate {
#    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   sysDate                     returns $Date
#       out:                    $Date (May 30, 1998 59:39:03)
#-------------------------------------------------------------------------------

    @tmp=(			# HARD_CODED
	  "/home/$ENV{USER}/server/scr/lib/",
	  "/home/$ENV{USER}/perl/"
	  );
    $exe_ctime="ctime.pl";	# local ctime library

    $Lok=0;
				# ------------------------------
				# get function
    if (defined &localtime) {
				# use system standard
	$Lok=1	                if (defined &ctime && &ctime);
				# use local library
	$Lok=1                  if (! $Lok && -e $exe_ctime);

	if (! $Lok) {		# search for it
	    foreach $tmp (@tmp){
		$exe_tmp=$tmp.$exe_ctime;
		if (-e $tmp){
		    $Lok=
			require("$exe_tmp");
		    last;}}}
				# ------------------------------
				# found one: use it
	if ($Lok && 
	    defined &ctime && &ctime && defined &localtime && &localtime){
#       	$date is e.g.:		Oct:14:13:06:47:1993
#       	@Date is e.g.:		Oct1413:06:471993
#        	&ctime(time) is e.g.:	Thu Oct 14 13:06:47 1993
	    @Date = split(' ',&ctime(time)) ; shift (@Date) ; 
	    $Date="$Date[2] $Date[3], $Date[$#Date]  $Date[4]";
	    return($Date);} }
				# ------------------------------
	 			# found none: take system
    if (! $Lok) {
	$localtime=`date`;
	@Date=split(/\s+/,$localtime);
	$Date="$Date[2] $Date[3], $Date[$#Date] $Date[4]"; }
    return($Date);
}				# end of sysDate

#==============================================================================
sub sysMkdir {
    local($argIn,$niceLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   sysMkdir                    system call 'mkdir'
#                               note: system call returns 0 if ok
#       in:                     directory, nice value (nice -19)
#       out:                    ok=(1,'mkdir a') , else=(0,msg)
#-------------------------------------------------------------------------------
    $sbrName="sysMkdir";
    $argIn=~s/\/$//             if ($argIn=~/\/$/);
    $niceLoc=""                 if (! defined $niceLoc || $niceLoc =~/^no/);
    $argIn=~s/\/$//g            if ($argIn =~/\/$/); # chop last '/'
				# exists already
    return(1,"already existing: $argIn");

				# ------------------------------
				# make dir
    $Lok= mkdir ($argIn, "770");
    system("chmod u+rwx $argIn");
    system("chmod go+rx $argIn");

    return(0,"*** $sbrName: couldnt find or make dir '$argIn' ($Lok)!") if (! $Lok);
    return(1,"$niceLoc mkdir $argIn");
}				# end of sysMkdir

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
    $niceLoc=""                 if (! defined $niceLoc || $niceLoc =~/^no/);
				# check
    return(0,"*** $sbrName: missing input file '$fileToCopy'!") if (! -e $fileToCopy);
    return(0,"*** $sbrName: needs 2 arg 'fToCopy fToCopyTo'!")  if (! defined $fileToCopyTo);

    system("$niceLoc \\mv $fileToCopy $fileToCopyTo");

    return(0,"*** $sbrName: couldnt copy '$fileToCopy -> $fileToCopyTo' ($Lok)!")
	if (! -e $fileToCopyTo);
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
    $sbrName="lib-sys:sysRunProg";
    return(0,"*** ERROR $sbrName: argument program (cmd) not defined\n") 
	if (! defined $cmd || length($cmd)<1);
    $fhErrLoc=0                 if (! defined $fhErrLoc);
    $fileScrLoc=0               if (! defined $fileScrLoc);

				# ------------------------------
				# dissect arguments

    ($prog,@arg)=split(/,/,$cmd);
    if    ($fhErrLoc && ! @arg) {
	print $fhErrLoc "-*- WARN $sbrName: no arguments to pipe into:\n$prog\n";
    }
    elsif ($fhErrLoc) {
	print $fhErrLoc 
	    "--- $sbrName: system cmd=\n$prog\n--- $sbrName: fileOut=$fileScrLoc cmd IN:\n$cmd\n";}
				# ------------------------------
				# pipe output into file?
    $Lpipe=0;
    $Lpipe=1                    if ($fileScrLoc);
				# hack br: 08-98 to avoid pipe pipe, i.e.
				#          prog="cmd > file" -> 'cmd > file | cat >> filescreen' fails
    $Lpipe=0                    if ($prog =~ /\s+>>?\s+\S+\s*$/);
    $prog.=" | cat >> $fileScrLoc " if ($Lpipe);
#    print "$cmd\n";exit;
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
sub sysSystem {
    local($cmdLoc,$fhLoc) = @_ ;
    local($sbrName,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   sysSystem                   simple way of running system command + documenting them
#       in:                     $cmd:   will do system($cmd)
#       in:                     $fhLoc: will write trace onto fhLoc
#                                 =<! defined> -> STDOUT
#                                 =0           -> no output
#       out:                    <1|0>,<"value from system"|$errorMessag>
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";$sbrName=$tmp."sysSystem";
				# no argument given
    return(0,"*** ERROR $sbrName: no input argument (system command)")
	if (! defined $cmdLoc || ! $cmdLoc);

				# default
    $fhLoc="STDOUT"             if (! defined $fhLoc);
    
				# ------------------------------
				# write
    if ($fhLoc)
    {
	print $fhLoc "---  system: \t $cmdLoc\n";
	#cluck( "---  system: \t $cmdLoc" );
    }

				# ------------------------------
				# run system
    $Lsystem=
	system("$cmdLoc");

    return(1,$Lsystem);
}				# end of sysSystem

#==============================================================================
sub cachedBlastCall {
    my( $cmdLoc, $fhLoc, $__p ) = @_;
    my($sbrName,$Lok);
    %$__p = ( md5string => '', md5files => [], cache_files => {}, %$__p );
    $[ =1 ;
#-------------------------------------------------------------------------------
#   cachedBlastCall             read cached Blast results if any, otherwise run
#                               Blast, store results
#       in:                     $cmdLoc: will do system($cmd)
#       in:                     $fhLoc:  will write trace onto fhLoc
#                                 =<! defined> -> STDOUT
#                                 =0           -> no output
#       __p => {
#               md5string => string_to_md5_to_create_UUID,
#               md5files => [ files_to_md5_to_create_UUID, ... ],
#               cache_files => { filename_in_cache0 => filepath0, ... }
#       }
#       filename_in_cache0 must be of: [[:alnum:]_], other characters are deleted
#
#       out:                    <1|0>,<"value from system"|$errorMessag>
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";$sbrName=$tmp."sysSystem";
				# no argument given
    return(0,"*** ERROR $sbrName: no input argument (system command)")
	if (! defined $cmdLoc || ! $cmdLoc);

				# default
    $fhLoc="STDOUT"             if (! defined $fhLoc);
    
				# ------------------------------
				# write
    if ($fhLoc)
    {
	print $fhLoc "---  cachedBlastCall: \t $cmdLoc";
	#cluck( "---  cachedBlastCall: \t $cmdLoc" );
    }

				# ------------------------------
				# run system
    # cmdLoc example:
    # >  /nfs/data5/users/ppuser/server/bin/blastpgp.LINUX  -j 3 -b 2000 -e 1 -F F -h 1e-3 -d  /nfs/data5/users/ppuser/server/data/blast/big_80 -i /nfs/data5/users/ppuser/server/work/tquick.fasta  -o /nfs/data5/users/ppuser/server/work/tquick.blastPsiOutTmp -C /nfs/data5/users/ppuser/server/work/tquick.blastPsiCheck   -Q /nfs/data5/users/ppuser/server/work/tquick.blastPsiMatTmb   <
    # >  /nfs/data5/users/ppuser/server/bin/blastpgp.LINUX  -b 1000 -e 1 -F F -d  /nfs/data5/users/ppuser/server/data/blast/big -i /nfs/data5/users/ppuser/server/work/tquick.fasta  -o /nfs/data5/users/ppuser/server/work/tquick.blastPsiAli -R /nfs/data5/users/ppuser/server/work/tquick.blastPsiCheck -Q /nfs/data5/users/ppuser/server/work/tquick.blastPsiMat  <
    # -C: Output File for PSI-BLAST Checkpointing
    # -Q: Output File for PSI-BLAST Matrix in ASCII
    # -R: Input File for PSI-BLAST Restart

    my $rerun = 1;
    my $cache_dir = undef;
    my $cmd_cache_dir = undef;
    my $Lsystem = undef;

    my $blastcmdmd5 = Digest::MD5->new();
    $blastcmdmd5->add( $__p->{md5string} );
    foreach my $md5file ( @{$__p->{md5files}} ) { my $fh; open( $fh, '<', $md5file ) || confess( $! ); $blastcmdmd5->addfile( $fh ); close( $fh ); }

    # Sanitize $__p->{cache_files}:
    if( keys(%{$__p->{cache_files}}) )
    {
        my $tmp = {}; %$tmp = %{$__p->{cache_files}}; %{$__p->{cache_files}} = ();
        foreach my $key (keys(%$tmp)) { my $val = $tmp->{$key}; $key =~ s/[^[:alnum:]_]//go; $__p->{cache_files}->{$key} = $val; }
    }
#warn(Data::Dumper::Dumper( $__p->{cache_files} ));

    if( $ENV{PP_ROOT} && keys(%{$__p->{cache_files}}) )
    {
        $cache_dir = "$ENV{PP_ROOT}/blastcache";
        if( -d $cache_dir )
        {
            $cmd_cache_dir = $cache_dir.'/'.$blastcmdmd5->hexdigest();
            if( -d $cmd_cache_dir )
            {
                $rerun = 0;
                foreach my $cachedfilename (keys(%{$__p->{cache_files}}))
                {
                    my $cachefilepath = $cmd_cache_dir.'/'.$cachedfilename.'.gz';
                    if( !-e $cachefilepath || -z $cachefilepath ) { $rerun = 1; last; }
                }
            }
        }
        else { warn("no cache dir ``$cache_dir''"); }
    }
    else { warn("no \$ENV{PP_ROOT}"); }

    if( $rerun )
    {
        ( undef, $Lsystem ) = sysSystem( $cmdLoc, $fhLoc );

        if( $cache_dir && -d $cache_dir && keys(%{$__p->{cache_files}}) )
        {
            if( $fhLoc ){ print $fhLoc " caching into $cmd_cache_dir"; }
        
            my @cmd = ( '/bin/mkdir', '-p', $cmd_cache_dir ); system( @cmd ) == 0 or confess( join(' ', @cmd).": $!" );

#warn(Data::Dumper::Dumper( $__p->{cache_files} ));
            foreach my $cachedfilename (keys(%{$__p->{cache_files}}))
            {
                my $path = $__p->{cache_files}->{$cachedfilename};
                my $cachefilepath = $cmd_cache_dir.'/'.$cachedfilename;
                { my @cmd = ( '/bin/cp', '-a', $path, $cachefilepath ); system( @cmd ) == 0 or cluck( join(' ', @cmd).": $!" ); }
#warn("*** zipping: $path $cachefilepath");
                { my @cmd = ( '/bin/gzip', '--force', $cachefilepath ); system( @cmd ) == 0 or cluck( join(' ', @cmd).": $!" ); }
            }
        }
    }
    else
    {
        if( $fhLoc ){ print $fhLoc " cache hit ($cmd_cache_dir)"; }

        foreach my $cachedfilename (keys(%{$__p->{cache_files}}))
        {
            my $path = $__p->{cache_files}->{$cachedfilename};
            my $cachefilepath = $cmd_cache_dir.'/'.$cachedfilename.'.gz';
            { utime undef, undef, $cachefilepath; } # extend cache lifetime
            { my @cmd = ( '/bin/cp', '-a', $cachefilepath, $path.'.gz' ); system( @cmd ) == 0 or confess( join(' ', @cmd).": $!" ); }
            { my @cmd = ( '/bin/gunzip', '--force', $path.'.gz' ); system( @cmd ) == 0 or confess( join(' ', @cmd),": $!" ); }
        }
        $Lsystem = 0;
    }

    if( -d $cache_dir ) {
        # this should take place after utime (touch)
        remove_old_files({ root => $cache_dir, mmin => '+2880' }); # 48 hours
    }

    if( $fhLoc ){ print $fhLoc "\n"; }
    return(1,$Lsystem);
}				# end of cachedBlastCall

#==============================================================================
sub remove_old_files
{
    # Careful here!: we do not want more than one find here, and we do not want
    # finds too often either.
    my( $__p ) = @_;
    # { root => look_for_files_under_this_root, mmin => find_mmin_condition }
    %$__p = ( mmin => '+1440', %$__p );
    if( !$__p->{root} ) { cluck("no ``root''"); return; }

    # do not blow up if this fails - what we implement here is quite unimportant
    eval {
        my $lockfile = $__p->{root}."/.remove_lock";

        if( !-e $lockfile || time() - File::stat::stat($lockfile)->mtime() > 3600 )
        {
            my $lh = undef;
            open( $lh, '>>', $lockfile ) || confess( $! );
            if( flock( $lh, LOCK_EX | LOCK_NB ) )
            {
                # we got the lock
                seek( $lh, 0, 0 ); truncate( $lh, 0 ); print $lh $$, "\n";
                
                my @cmd = ( '/usr/bin/find', $__p->{root}, '-mmin', $__p->{mmin}, '-exec', '/bin/rm', '-rf', '{}', ';' );
                system( @cmd ); # we get a 1 when we delete directories and the contents also vanish (/usr/bin/find: ...: No such file or directory), but that is all right.
                #
                flock( $lh, LOCK_UN ); close( $lh );
            }
        }
    };
    if( $@ ){ warn; }
}


#==============================================================================
sub topitsWrtOwn {
    local($fileHsspLoc,$fileStripLoc,$fileOutLoc,$mix,$fhErrSbr) = @_ ;
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok,$txt,$kwd,$it,$wrtTmp,$wrtTmp2,
	  %rdHdr,@kwdLoc,@kwdOutTop2,@kwdOutSummary2,%wrtLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   topitsWrtOwn                writes the TOPITS format
#       in:                     $fileHsspLoc,$fileStripLoc,$fileOutLoc,$mix,$fhErrSbr
#       out:                    file written ($fileOutLoc)
#       err:                    ok=(1,'ok'), err=(0,'msg')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."topitsWrtOwn";
    $fhinLoc= "FHIN". "$sbrName";
    $fhoutLoc="FHOUT"."$sbrName";
    $sep="\t";
				# ------------------------------
				# check arguments
    return(0,"*** $sbrName: not def fileHsspLoc!")          if (! defined $fileHsspLoc);
    return(0,"*** $sbrName: not def fileStripLoc!")         if (! defined $fileStripLoc);
    return(0,"*** $sbrName: not def fileOutLoc!")           if (! defined $fileOutLoc);
    $fhErrSbr="STDOUT"                                      if (! defined $fhErrSbr);
    return(0,"*** $sbrName: miss in file '$fileHsspLoc'!")  if (! -e $fileHsspLoc);
    return(0,"*** $sbrName: miss in file '$fileStripLoc'!") if (! -e $fileStripLoc);
    @kwdOutTop2=
	("len1","nali","listName","sortMode","weight1","weight2",
	 "smin","smax","gapOpen","gapElon","indel1","indel2","threshold");
    @kwdOutSummary2=
	("id2","pide","lali","ngap","lgap","len2",
	 "Eali","Zali","strh","ifir","ilas","jfir","jlas","name");
				# ------------------------------
				# set up keywords
    @kwdLoc=
	 (
	  "hsspTop",   "threshold","len1",
	  "hsspPair",  "id2","pdbid2","pide","ifir","ilas","jfir","jlas",
	               "lali","ngap","lgap","len2",
	  "stripTop",  "nali","listName","sortMode","weight1","weight2",
	               "smin","smax","gapOpen","gapElon","indel1","indel2",
	  "stripPair", "energy","zscore","strh","name");

    $des_expl{"mix"}=      "weight structure:sequence";
    $des_expl{"nali"}=     "number of alignments in file";
    $des_expl{"listName"}= "fold library used for threading";
    $des_expl{"sortMode"}= "mode of ranking the hits";
    $des_expl{"weight1"}=  "YES if guide sequence weighted by residue conservation";
    $des_expl{"weight2"}=  "YES if aligned sequence weighted by residue conservation";
    $des_expl{"smin"}=     "minimal value of alignment metric";
    $des_expl{"smax"}=     "maximal value of alignment metric";
    $des_expl{"gapOpen"}=  "gap open penalty";
    $des_expl{"gapElon"}=  "gap elongation penalty";
    $des_expl{"indel1"}=   "YES if insertions in sec str regions allowed for guide seq";
    $des_expl{"indel2"}=   "YES if insertions in sec str regions allowed for aligned seq";
    $des_expl{"len1"}=     "length of search sequence, i.e., your protein";
    $des_expl{"threshold"}="hits above this threshold included (ALL means no threshold)";

    $des_expl{"rank"}=     "rank in alignment list, sorted according to sortMode";
    $des_expl{"Eali"}=     "alignment score";
    $des_expl{"Zali"}=     "alignment zcore;  note: hits with z>3 more reliable";
    $des_expl{"strh"}=     "secondary str identity between guide and aligned protein";
    $des_expl{"pide"}=     "percentage of pairwise sequence identity";
    $des_expl{"lali"}=     "length of alignment";
    $des_expl{"lgap"}=     "number of residues inserted";
    $des_expl{"ngap"}=     "number of insertions";
    $des_expl{"len2"}=     "length of aligned protein structure";
    $des_expl{"id2"}=      "PDB identifier of aligned structure (1pdbC -> C = chain id)";
    $des_expl{"name"}=     "name of aligned protein structure";
    $des_expl{"ifir"}=     "position of first residue of search sequence";
    $des_expl{"ilas"}=     "position of last residue of search sequence";
    $des_expl{"jfir"}=     "pos of first res of remote homologue (e.g. DSSP number)";
    $des_expl{"jlas"}=     "pos of last res of remote homologue  (e.g. DSSP number)";
    $des_expl{""}=    "";

				# ------------------------------
    undef %rdHdr;		# read HSSP + STRIP header

    ($Lok,$txt,%rdHdr)=
	  &hsspRdStripAndHeader($fileHsspLoc,$fileStripLoc,$fhErrSbr,@kwdLoc);
    return(0,"$sbrName: returned 0\n$txt\n") if (! $Lok);
				# ------------------------------
				# write output in TOPITS format
    $Lok=&open_file("$fhoutLoc",">$fileOutLoc"); 
    return(0,"$sbrName: couldnt open new file $fileOut") if (! $Lok);
				# corrections
    $rdHdr{"threshold"}=~s/according to\s*\:\s*//g if (defined $rdHdr{"threshold"});
    foreach $it (1..$rdHdr{"NROWS"}){
	$rdHdr{"Eali","$it"}=$rdHdr{"energy","$it"} if (defined $rdHdr{"energy","$it"});
	$rdHdr{"Zali","$it"}=$rdHdr{"zscore","$it"} if (defined $rdHdr{"zscore","$it"});
    }
#    $rdHdr{"name","$it"}=$rdHdr{"zscore","$it"} if (defined $rdHdr{"zscore","$it"});
				# ------------------------------
    $wrtTmp=$wrtTmp2="";	# build up for communication with subroutine
    undef %wrtLoc;
    foreach $kwd(@kwdOutTop2){
	$wrtLoc{"$kwd"}=       $rdHdr{"$kwd"};
	$wrtLoc{"expl"."$kwd"}=$des_expl{"$kwd"};$wrtTmp.="$kwd,";}
    if (defined $mix && $mix ne "unk" && length($mix)>1){
	$kwd="mix";
	$wrtLoc{"$kwd"}=       $mix;
	$wrtLoc{"expl"."$kwd"}=$des_expl{"$kwd"};$wrtTmp.="$kwd,";}
    foreach $kwd(@kwdOutSummary2){
	$wrtLoc{"expl"."$kwd"}=$des_expl{"$kwd"};$wrtTmp2.="$kwd,";}
				# ------------------------------
				# write header
    ($Lok,$txt)=
	&topitsWrtOwnHdr($fhoutLoc,$wrtTmp,$wrtTmp2,%wrtLoc);
    undef %wrtLoc;
				# ------------------------------
				# write names of first block
    print $fhoutLoc 
	"# BLOCK    TOPITS HEADER: SUMMARY\n";
    printf $fhoutLoc "%-s","rank";
    foreach $kwd(@kwdOutSummary2){
#	$sepTmp="\n" if ($kwd eq $kwdOutTop2[$#kwdOutTop2]);
	printf $fhoutLoc "$sep%-s",$kwd;}
    print $fhoutLoc "\n";
				# ------------------------------
				# write first block of data
    foreach $it (1..$rdHdr{"NROWS"}){
	printf $fhoutLoc "%-s",$it;
	foreach $kwd(@kwdOutSummary2){
	    printf $fhoutLoc "$sep%-s",$rdHdr{"$kwd","$it"};}
	print $fhoutLoc "\n";
    }
				# ------------------------------
				# next block (ali)
#    print $fhoutLoc
#	"# --------------------------------------------------------------------------------\n",
#	;
				# ------------------------------
				# correct file end
    print $fhoutLoc "//\n";
    close($fhoutLoc);
    undef %rdHdr;		# read HSSP + STRIP header
    return(1,"ok $sbrName");
}				# end of topitsWrtOwn

#==============================================================================
sub topitsWrtOwnHdr {
    local($fhoutTmp,$desLoc,$desLoc2,%wrtLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   topitsWrtOwnHdr             writes the HEADER for the TOPITS specific format
#       in:                     FHOUT,"kwd1,kwd2,kwd3",%wrtLoc
#                               $wrtLoc{"$kwd"}=result of paramter
#                               $wrtLoc{"expl$kwd"}=explanation of paramter
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";$sbrName="$tmp"."topitsWrtOwnHdr";
				# ------------------------------
				# keywords to write
    $desLoc=~s/^,*|,*$//g;      $desLoc2=~s/^,*|,*$//g;
    @kwdHdr=split(/,/,$desLoc); @kwdCol=split(/,/,$desLoc2);
    
				# ------------------------------
				# begin
    print $fhoutTmp
	"# TOPITS (Threading One-D Predictions Into Three-D Structures)\n",
	"# --------------------------------------------------------------------------------\n",
	"# FORMAT   begin\n",
	"# FORMAT   general:    - lines starting with hashes contain comments or PARAMETERS\n",
	"# FORMAT   general:    - columns are delimited by tabs\n",
	"# FORMAT   general:    - the data are given in BLOCKS, each introduced by a line\n",
	"# FORMAT   general:      beginning with a hash and a keyword\n",
	"# FORMAT   parameters: '# PARA:tab     keyword =tab value tab (further-information)'\n",
	"# FORMAT   notation:   '# NOTATION:tab keyword tab explanation'\n",
	"# FORMAT   info:       '# INFO:tab     text'\n",
	"# FORMAT   blocks 0:   '# BLOCK        keyword'\n",
	"# FORMAT   blocks 1:    column names (tab delimited)\n",
	"# FORMAT   blocks n>1:  column data  (tab delimited)\n",
	"# FORMAT   file end:   '//' marks the end of a complete file\n",
	"# FORMAT   end\n",
	"# --------------------------------------------------------------------------------\n";
				# ------------------------------
				# write parameters
    print $fhoutTmp
	"# PARA     begin\n",
	"# PARA     TOPITS HEADER: PARAMETERS\n";
    foreach $des (@kwdHdr){
	next if (! defined $wrtLoc{"$des"});
	$tmp1=$wrtLoc{"expl"."$des"};$tmp2=length($tmp1);$tmp="$tmp2"."s";
	$wrtLoc{"$des"}=~s/\s//g; # purge blanks
	if ($des eq "mix"){
	    $mix=~s/\D//g;
	    printf $fhoutTmp 
		"# PARA:\t%-10s =\t%-6d\t(i.e. str=%3d%1s, seq=%3d%1s)\n",
		"str:seq",int($mix),int($mix),"%",int(100-$mix),"%";}
	else {
	    printf $fhoutTmp 
		"# PARA:\t%-10s =\t%-6s\n",$des,$wrtLoc{"$des"};}}
    print $fhoutTmp
	"# PARA     end\n",
	"# --------------------------------------------------------------------------------\n";
				# ------------------------------
				# explanations
    print $fhoutTmp
	"# NOTATION begin\n",
	"# NOTATION TOPITS HEADER: ABBREVIATIONS PARAMETERS\n";
    foreach $des (@kwdHdr){
	$tmp1=$wrtLoc{"expl"."$des"};$tmp2=length($tmp1);$tmp="$tmp2"."s";
	$tmp=length($wrtLoc{"expl"."$des"});$tmp.="s";
	$des2=$des;  # $des2=~tr/[a-z]/[A-Z]/;
	$des2="str:seq" if ($des2 eq "mix");
	printf $fhoutTmp "# NOTATION:\t%-12s:\t%-$tmp\n",$des2,$tmp1;}
    print $fhoutTmp
	"# NOTATION TOPITS HEADER: ABBREVIATIONS SUMMARY\n";
    foreach $des (@kwdCol){
	$tmp1=$wrtLoc{"expl"."$des"};$tmp2=length($tmp1);$tmp="$tmp2"."s";
	$tmp=length($wrtLoc{"expl"."$des"});$tmp.="s";
	$des2=$des;  # $des2=~tr/[a-z]/[A-Z]/;
	printf $fhoutTmp "# NOTATION:\t%-12s:\t%-$tmp\n",$des2,$tmp1;}
	
    print $fhoutTmp
	"# NOTATION end\n",
	"# --------------------------------------------------------------------------------\n";
				# ------------------------------
				# information about method
    print $fhoutTmp 
	"# INFO     begin\n",
	"# INFO     TOPITS HEADER: ACCURACY\n",
	"# INFO:\t Tested on 80 proteins, TOPITS found the correct remote homologue in about\n",
	"# INFO:\t 30%of the cases.  Detection accuracy was higher for higher z-scores:\n",
	"# INFO:\t ZALI>0   => 1st hit correct in 33% of cases\n",
	"# INFO:\t ZALI>3   => 1st hit correct in 50% of cases\n",
	"# INFO:\t ZALI>3.5 => 1st hit correct in 60% of cases\n",
	"# INFO     end\n",
	"# --------------------------------------------------------------------------------\n";
}				# end of topitsWrtOwnHdr

#==============================================================================
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

#==============================================================================
sub wrtRdb2HtmlBody {
    local ($fhout,$LlinkLoc,%bodyLoc) = @_ ;
    $[ =1 ;
#--------------------------------------------------------------------------------
#   wrtRdb2HtmlBody		writes the body for a RDB->HTML file
#       in:	                $fhout,$LlinkLoc,%bodyLoc
#                               where $body{"it","colName"} contains the columns
#--------------------------------------------------------------------------------
    print $fhout 
	"<P><P><HR><P><P>\n\n",
	"<A NAME=\"BODY\"><H2>RDB table</H2><\/A>\n",
	"<P><P>\n";
				# get column names
    $bodyLoc{"COLNAMES"}=~s/^,*|,*$//g;
    @colNames=split(/,/,$bodyLoc{"COLNAMES"});

    print $fhout "<TABLE BORDER>\n";
				# ------------------------------
    				# write column names with links
    &wrtRdb2HtmlBodyColNames($fhout,@colNames);

				# ------------------------------
				# write body
    $LfstAve=0;
    foreach $it (1..$body{"NROWS"}){
	print $fhout "<TR>   ";
	foreach $itdes (1..$#colNames){
				# break for Averages
	    if ( ($itdes==1) && (! $LfstAve) &&
		($body{"$it","$colNames[1]"} =~ /^ave/) ){
		$LfstAve=1;
		&wrtRdb2HtmlBodyAve($fhout,@colNames);}
		    
	    if (defined $body{"$it","$colNames[$itdes]"}) {
	    	print $fhout "<TD>",$body{"$it","$colNames[$itdes]"};}
	    else {
		print $fhout "<TD>"," ";}}
	print $fhout "\n";}

    print $fhout "</TABLE>\n";
}				# end of wrtRdb2HtmlBody

#==============================================================================
sub wrtRdb2HtmlHeader {
    local ($fhout,$scriptNameLoc,$fileLoc,$LlinkLoc,$LaveLoc,$colNamesLoc,@headerLoc) = @_ ;
    local (@colNamesLoc,$Lnotation,$LlinkHere,$col,@namesLink);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   wrtRdb2HtmlHeader		write the HTML header
#       in:	                $fhout,$fileLoc,$LlinkLoc,$colNamesLoc,@headerLoc
#                               where colName="name1,name2,"
#                               and @headerLoc contains all lines in header
#       out:                  @nameLinks : names of columns with links (i.e.
#                               found as NOTATION in header line
#--------------------------------------------------------------------------------
    $#namesLink=0;

    $colNamesLoc=~s/^,*|,*$//g;
    @colNamesLoc=split(/,/,$colNamesLoc);

    print $fhout 
	"<HTML>\n",
	"<TITLE>Extracted from $fileLoc </TITLE>\n",
	"<BODY>\n",
	"<H1>Results from $scriptNameLoc</H1>\n",
	"<H3>Extraction of data from RDB file '$fileLoc' </H3>\n",
	"<P><P>\n",
	"<UL>\n",
	"<LI><A HREF=\"\#HEADER\">RDB header<\/A>\n",
	"<LI><A HREF=\"\#BODY\">RDB table<\/A>\n";
    if ($LaveLoc){
	print $fhout "<LI><A HREF=\"\#AVERAGES\">Averages over columns<\/A>\n";}
	    
    print $fhout 
	"<\/UL>\n",
	"<P><P>\n",
	"<HR>\n",
	"<P><P>\n",
	"<A NAME=\"HEADER\"><H2>RDB header</H2><\/A>\n",
	"<P><P>\n";

    print $fhout "<PRE>\n";
    $Lnotation=0;
    foreach $_(@headerLoc){
	$LlinkHere=0;
	if (/NOTATION/){ $Lnotation=1;}
	if ($Lnotation){
	   foreach $col(@colNamesLoc){
		if (/^\#\s*$col\W/){ 
		    $colFound=$col;$LlinkHere=1;
		    push(@namesLink,$col);
		    last;}}
	   if ($LlinkLoc && $LlinkHere){ 
		print $fhout "<A NAME=\"$colFound\">";}}
	print $fhout "$_";
	if ($LlinkHere){
	   print $fhout "</A>";}
	print $fhout "\n";}
    print $fhout "\n</PRE>\n";
    print $fhout "<BR>\n";
    return(@namesLink);
}				# end of wrtRdb2HtmlHeader

#==============================================================================
sub wrt_dssp_phd {
    local ($fhoutLoc,$id_in)=@_;
    local ($it);
    $[ =1 ;
#----------------------------------------------------------------------
#   wrt_dssp_phd                writes DSSP format for
#       in:                     $fhoutLoc,$id_in
#       in GLOBAL:              @NUM, @SEQ, @SEC(HE ), @ACC, @RISEC, @RIACC
#       out:                    1 if ok
#----------------------------------------------------------------------
    if (! defined @NUM || $#NUM == 0 || ! defined @SEQ || $#SEQ == 0 ||
	! defined @SEC || $#SEC == 0 || ! defined @ACC || $#ACC == 0 || 
	! defined @RISEC || $#RISEC == 0 || 
	! defined @RIACC || $#RIACC == 0 ) {
	print "*** ERROR in wrt_dssp_phd: not all arguments defined!!\n";
	print "*** missing NUM\n"   if (! defined @NUM || $#NUM == 0);
	print "*** missing SEQ\n"   if (! defined @SEQ || $#SEQ == 0 );
	print "*** missing SEC\n"   if (! defined @SEC || $#SEC == 0);
	print "*** missing ACC\n"   if (! defined @ACC || $#ACC == 0);
	print "*** missing RISEC\n" if (! defined @RISEC || $#RISEC == 0);
	print "*** missing RIACC\n" if (! defined @RIACC || $#RIACC == 0);
	return(0);}
	
    print $fhoutLoc 
	"**** SECONDARY STRUCTURE DEFINITION BY THE PROGRAM DSSP, here PHD prediction\n",
	"REFERENCE  ROST & SANDER,PROTEINS,19,1994,55-72; ".
	    "ROST & SANDER,PROTEINS,20,1994,216-26\n",
	    "HEADER     $id_in \n",
	    "COMPND        \n",
	    "SOURCE        \n",
	    "AUTHOR        \n",
	    "  \#  RESIDUE AA STRUCTURE BP1 BP2  ACC   N-H-->O  ".
		"O-->H-N  N-H-->O  O-->H-N    TCO  KAPPA ALPHA  PHI   ".
		    "PSI    X-CA   Y-CA   Z-CA  \n";
				# for security
    $CHAIN=" "                  if (! defined $CHAIN);
    for ($it=1; $it<=$#NUM; ++$it) {
	printf $fhoutLoc 
	    " %4d %4d %1s %1s  %1s           0   0  %3d    %1d  %1d\n",
	    $NUM[$it], $NUM[$it], $CHAIN, $SEQ[$it], $SEC[$it], 
	    $ACC[$it], $RISEC[$it], $RIACC[$it];}
    return(1);
}				# end wrt_dssp_phd

#==============================================================================
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

#==============================================================================
sub wrt_phd2msf {
    local ($fileHssp,$fileMsfTmp,$filePhdRdb,$fileOut,$exeConvSeq,$LoptExpand,
	   $exePhd2Msf,$riSecLoc,$riAccLoc,$riSymLoc,$charPerLine,$Lscreen,$Lscreen2) = @_ ;
#    local ($fileLog);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   wrt_phd2msf                 converts HSSP to MSF and merges the PHD prediction
#                               into the MSF file (Pred + Ali)
#       in:                     * existing HSSP file, 
#                               * to be written temporary MSF file (hssp->MSF)
#                               * existing PHD.rdb_phd file
#                               * name of output file (id.msf_phd)
#                               * executables for converting HSSP to MSF (fortran convert_seq)
#                               * $Lexpand =1 means insertions in HSSP will be filled in
#                               * perl hack to convert id.rdb_phd + id.msf to id.msf_phd
#                               * reliability index to choose SUBSET for secondary structure
#                                 prediction (taken: > riSecLoc)
#                               * reliability index for SUBacc
#                               * character used to mark regions with ri <= riSecLoc
#                               * number of characters per line of MSF file
#       out:                    writes file and reports status (0,$text), or (1," ")
#--------------------------------------------------------------------------------
				# ------------------------------
				# security checks
    if (!-e $fileHssp){
	return(0,"HSSP file '$fileHssp' missing (wrt_phd2msf)");}
    if (!-e $filePhdRdb){
	return(0,"phdRdb file '$filePhdRdb' missing (wrt_phd2msf)");}
    if ($LoptExpand){
	$optExpand="expand";}else{$optExpand=" ";}
				# ------------------------------
				# convert HSSP file to MSF format
    if ($Lscreen){ 
	print "--- wrt_phd2msf \t ";
	print "'\&convHssp2msf($fileHssp,$fileMsfTmp,$exeConvSeq,$optExpand,$Lscreen2)'\n";}
    $Lok=
	&convHssp2msf($fileHssp,$fileMsfTmp,$exeConvSeq,$optExpand,$Lscreen2);
    if (!$Lok){
	return(0,"conversion Hssp2Msf failed '$fileMsfTmp' missing (wrt_phd2msf)");}
				# ------------------------------
				# now merge PHD file into MSF
    $arg=  "$fileMsfTmp filePhd=$filePhdRdb fileOut=$fileOut ";
    $arg.= " riSec=$riSecLoc riAcc=$riAccLoc riSym=$riSymLoc charPerLine=$charPerLine ";
    if ($Lscreen2){$arg.=" verbose ";}else{$arg.=" not_screen ";}

    if ($Lscreen) {print "--- wrt_phd2msf \t 'system ($exePhd2Msf $arg)'\n";}

    system("$exePhd2Msf $arg");
    return(1," ");
}				# end of wrt_phd2msf

#==============================================================================
sub wrt_phd_header2pp {
    local ($file_out) = @_ ;
    local ($fhout,$header,@header);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   wrt_phd_header2pp           header for phd2pp
#       in:                     $file_out, i.e. file to write header to
#       out:                    @header
#-------------------------------------------------------------------------------
    $#header=0;
    push(@header,
	 "--- \n",
	 "--- ------------------------------------------------------------\n",
	 "--- PHD  profile based neural network predictions \n",
	 "--- ------------------------------------------------------------\n",
	 "--- \n");
    if ( (defined $file_out) && ($file_out ne "STDOUT") ) {
	$fhout="FHOUT_PHD_HEADER2PP";
	open($fhout, ">$file_out") || warn "Can't open '$file_out' (wrt_phd_header2pp)\n"; 
	foreach $header(@header){
	    print $fhout "$header";}
	close($fhout);}
    else {
	return(@header);}
}				# end of wrt_phd_header2pp

#==============================================================================
sub wrt_phd_rdb2col {
    local ($file_out,%rdrdb) = @_ ;
    local (@des,@des2,$fhout,$itdes,$it,%string,$subsec,$subacc,$points,
	   $des,$desout,$tmp,$tmpf,$dessec,$desacc,%Lok);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    wrt_phd_rdb2col             writes out the PP send format
#--------------------------------------------------------------------------------
    @des= ("AA","PSEC","RI_S","pH","pE","pL","PACC","PREL","RI_A","Pbie");
                                # ----------------------------------------
                                # first converting OtH (output) to prH (probability)
                                # ----------------------------------------
    $Lis_E=$Lis_H=0;
    foreach $it (1..$rdrdb{"NROWS"}){
	if (defined $rdrdb{"pH","$it"}) { $pH=$rdrdb{"pH","$it"}; $Lis_H=1;} else {$pH=0;}
	if (defined $rdrdb{"pE","$it"}) { $pE=$rdrdb{"pE","$it"}; $Lis_E=1;} else {$pE=0;}
	if (defined $rdrdb{"pL","$it"}) { $pL=$rdrdb{"pL","$it"}; }          else {$pL=0;}
	$sum=$pH+$pE+$pL; 
	if ($sum>0){
	    ($rdrdb{"pH","$it"},$tmp)=&get_min(9,int(10*$pH/$sum));
	    ($rdrdb{"pE","$it"},$tmp)=&get_min(9,int(10*$pE/$sum));
	    ($rdrdb{"pL","$it"},$tmp)=&get_min(9,int(10*$pL/$sum)); }
	else {
	    $rdrdb{"pH","$it"}=$rdrdb{"pE","$it"}=$rdrdb{"pL","$it"}=0;}}
    
				# ------------------------------
				# check whether or not all there
    foreach $des (@des) {
	if (defined $rdrdb{"$des","1"}) {$Lok{"$des"}=1;}
	else {$Lok{"$des"}=0;} }

    $fhout="FHOUT_PHD_RDB2COL";
    open($fhout, ">$file_out") || warn "Can't open '$file_out' (wrt_phd_rdb2col)\n"; 
				# ------------------------------
				# header
    print $fhout "--- \n";
    print $fhout "--- PHD PREDICTION COLUMN FORMAT HEADER: ABBREVIATIONS\n";
    if ($Lok{"AA"}){
	printf $fhout "--- %-10s: %-s\n","AA","one-letter code for amino acid sequence"; }
    if ($Lok{"PSEC"}){
	printf $fhout "--- %-10s: %-s\n","PSEC","secondary structure prediction in 3 states:";
	printf $fhout "--- %-10s: %-s\n","    ","H=helix, E=extended (sheet), L=rest (loop)";
	printf $fhout "--- %-10s: %-s\n","RI_S","reliability of secondary structure prediction";
	printf $fhout "--- %-10s: %-s\n","    ","scaled from 0 (low) to 9 (high)";
	printf $fhout "--- %-10s: %-s\n","pH  ","'probability' for assigning helix";
	printf $fhout "--- %-10s: %-s\n","pE  ","'probability' for assigning strand";
	printf $fhout "--- %-10s: %-s\n","pL  ","'probability' for assigning rest";
	printf $fhout "--- %-10s: %-s\n","       ",
	"Note:   the 'probabilities' are scaled onto 0-9,";
	printf $fhout "--- %-10s: %-s\n","       ",
	"        i.e., prH=5 means that the value of the";
	printf $fhout "--- %-10s: %-s\n","       ","        first output unit is 0.5-0.6"; }
	
    if ($Lok{"PACC"}){
	printf $fhout "--- %-10s: %-s\n","PACC",
	"predicted solvent accessibility in square Angstrom";
	printf $fhout "--- %-10s: %-s\n","PREL","relative solvent accessibility in percent";
	printf $fhout "--- %-10s: %-s\n","RI_A","reliability of accessibility prediction (0-9)";
	printf $fhout "--- %-10s: %-s\n","Pbie","predicted relative accessibility in 3 states:";
	printf $fhout "--- %-10s: %-s\n","       ","b=0-9%, i=9-36%, e=36-100%"; }

    print $fhout "--- \n","--- PHD PREDICTION COLUMN FORMAT \n";
				# --------------------------------------------------
				# now the prediction in 60 per line
				# --------------------------------------------------
    printf $fhout "%4s","No"; 
    foreach $des (@des){
	if ($Lok{"$des"}) { printf $fhout "%4s ",$des;} }
    print $fhout "\n"; 
    foreach $it (1..$rdrdb{"NROWS"}){
	printf $fhout "%4d",$it;
	foreach $des (@des){
	    if ($Lok{"$des"}) { printf $fhout "%4s ",$rdrdb{"$des","$it"}; } }
	print $fhout "\n" }
    print $fhout "--- \n","--- PHD PREDICTION COLUMN FORMAT END\n","--- \n";
    close($fhout);
}				# end of wrt_phd_rdb2col

#==============================================================================
sub wrt_phd_rdb2pp {
    local ($file_out,$cut_subsec,$cut_subacc,$sub_symbol,%rdrdb) = @_ ;
    local (@des,@des2,$fhout,$itdes,$it,%string,$subsec,$subacc,$points,
	   $des,$desout,$tmp,$tmpf,$dessec,$desacc);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    wrt_phd_rdb2pp             writes out the PP send format
#--------------------------------------------------------------------------------
    @des= ("AA","PHEL","RI_S","OtH","OtE","OtL","PACC","PREL","RI_A","Pbie");
    @des2=("AA","PHD", "Rel", "prH","prE","prL","PACC","PREL","RI_A","Pbie");

    $fhout="FHOUT_PHD_RDB2PP";
    open($fhout, ">$file_out") || warn "Can't open '$file_out' (wrt_phd_rdb2pp)\n"; 
				# ------------------------------
				# header
    @header=&wrt_phd_header2pp();
    foreach $header(@header){
	print $fhout "$header"; }
    print $fhout "--- PHD PREDICTION HEADER: ABBREVIATIONS\n";
    printf $fhout "--- %-10s: %-s\n","AA","one-letter code for amino acid sequence";
    printf $fhout "--- %-10s: %-s\n","PHD sec","secondary structure prediction in 3 states:";
    printf $fhout "--- %-10s: %-s\n","       ","H=helix, E=extended (sheet), blank=rest (loop)";
    printf $fhout "--- %-10s: %-s\n","Rel sec","reliability of secondary structure prediction";
    printf $fhout "--- %-10s: %-s\n","SUB sec","subset of residues for which the reliability";
    printf $fhout "--- %-10s: %-s\n","       ","index (Rel sec) is >= 5";
    printf $fhout "--- %-10s: %-s\n","       ","Note 1: this corresponds to an expected pre-";
    printf $fhout "--- %-10s: %-s\n","       ","        diction accuracy > 82% ";
    printf $fhout "--- %-10s: %-s\n","       ","Note 2: 'L': is loop (for which above ' ' is used)";
    printf $fhout "--- %-10s: %-s\n","       ","        '.': means no prediction is made for this";
    printf $fhout "--- %-10s: %-s\n","       ","             residue, i.e., Rel sec < 5";
    printf $fhout "--- %-10s: %-s\n","prH sec","'probability' for assigning helix";
    printf $fhout "--- %-10s: %-s\n","prE sec","'probability' for assigning strand";
    printf $fhout "--- %-10s: %-s\n","prL sec","'probability' for assigning rest";
    printf $fhout "--- %-10s: %-s\n","       ","Note:   the 'probabilities' are scaled onto 0-9,";
    printf $fhout "--- %-10s: %-s\n","       ","        i.e., prH=5 means that the value of the";
    printf $fhout "--- %-10s: %-s\n","       ","        first output unit is 0.5-0.6";
    printf $fhout "--- %-10s: %-s\n","P_3 acc","predicted relative accessibility in 3 states:";
    printf $fhout "--- %-10s: %-s\n","       ","b=0-9%, blank=9-36%, e=36-100%";
    printf $fhout "--- %-10s: %-s\n","PHD acc","predicted solvent accessibility in 10 states:";
    printf $fhout "--- %-10s: %-s\n","       ","acc=n implies a relative accessibility of n*n%";
    printf $fhout "--- %-10s: %-s\n","Rel acc","reliability of accessibility prediction (0-9)";
    printf $fhout "--- %-10s: %-s\n","SUB acc","subset of residues for which the reliability";
    printf $fhout "--- %-10s: %-s\n","       ","index (Rel acc) is >= 4";
    printf $fhout "--- %-10s: %-s\n","       ","Note 1: this corresponds to an expected corre-";
    printf $fhout "--- %-10s: %-s\n","       ","        lation coeeficient > 0.69 ";
    printf $fhout "--- %-10s: %-s\n","       ","Note 2: 'I': is intermediate (for which above a";
    printf $fhout "--- %-10s: %-s\n","       ","             blank ' ' is used)";
    printf $fhout "--- %-10s: %-s\n","       ","        '.': means no prediction is made for this";
    printf $fhout "--- %-10s: %-s\n","       ","             residue, i.e., Rel acc < 4";
    printf $fhout "--- %-10s: %-s\n","       ","";
    printf $fhout "--- %-10s: %-s\n","       ","";
    print $fhout "--- \n";
    print $fhout "--- PHD PREDICTION \n";
                                # ----------------------------------------
                                # first converting OtH (output) to prH (probability)
                                # ----------------------------------------
    foreach $it (1..$rdrdb{"NROWS"}){
	$sum=$rdrdb{"OtH","$it"}+$rdrdb{"OtE","$it"}+$rdrdb{"OtL","$it"};
	($rdrdb{"prH","$it"},$tmp)=&get_min(9,int(10*$rdrdb{"OtH","$it"}/$sum));
	($rdrdb{"prE","$it"},$tmp)=&get_min(9,int(10*$rdrdb{"OtE","$it"}/$sum));
	($rdrdb{"prL","$it"},$tmp)=&get_min(9,int(10*$rdrdb{"OtL","$it"}/$sum));
    }
				# --------------------------------------------------
				# now the prediction in 60 per line
				# --------------------------------------------------
    foreach $itdes (1..$#des){
	$string{"$des2[$itdes]"}="";
	foreach $it (1..$rdrdb{"NROWS"}){
	    if   ($des[$itdes]=~/PREL/){
		$string{"$des2[$itdes]"}.=
		    &exposure_project_1digit($rdrdb{"$des[$itdes]","$it"}); }
	    elsif($des[$itdes]=~/Ot/) {
		$desout=$des[$itdes];$desout=~s/Ot/pr/;
		$string{"$desout"}.=$rdrdb{"$desout","$it"}; }
	    else {
		$string{"$des2[$itdes]"}.=$rdrdb{"$des[$itdes]","$it"}; }
	}
    }
				# correct symbols
    $string{"PHD"}=~s/L/ /g;
    $string{"PSEC"}=~s/L/ /g;
    $string{"Pbie"}=~s/i/ /g;
				# select subsets
    $subsec=$subacc="";
    foreach $it (1..$rdrdb{"NROWS"}){
				# sec
	if ($rdrdb{"RI_S","$it"}>$cut_subsec){$subsec.=$rdrdb{"PSEC","$it"};}
	else{$subsec.="$sub_symbol";}
				# acc
	if ($rdrdb{"RI_A","$it"}>$cut_subacc){$subacc.=$rdrdb{"Pbie","$it"};}
	else {$subacc.="$sub_symbol";}
    }

    $tmp=$string{"AA"};$nres=length($tmp); # length

    for($it=1;$it<=$nres;$it+=60){
	$points=&myprt_npoints (60,$it);	
	printf $fhout "%-16s  %-60s\n"," ",$points;
				# residues
	$des="AA";$desout="AA     ";
	$tmp=substr($string{"$des"},$it,60);$tmpf=length($tmp)."s";
	printf $fhout "%8s %-6s |%-$tmpf|\n"," ","$desout",$tmp;
				# secondary structure
	foreach $dessec("PHD","Rel","prH","prE","prL"){
	    $desout="$dessec sec ";
	    $tmp=substr($string{"$dessec"},$it,60);$tmpf=length($tmp)."s";
	    printf $fhout "%8s %-6s|%-$tmpf|\n"," ","$desout",$tmp;
	    if ($dessec=~/Rel/){
		printf $fhout " detail:\n";
	    }
	}
	printf $fhout "%15s|%-$tmpf|\n"," subset: SUB sec ",$tmp;
	printf $fhout " \n";
				# accessibility
	printf $fhout " ACCESSIBILITY\n";
	foreach $desacc("Pbie","PREL","RI_A"){
	    if ($desacc=~/Pbie/)   {$desout=" 3st:    P_3 acc ";}
	    elsif ($desacc=~/PREL/){$desout=" 10st:   PHD acc ";}
	    elsif ($desacc=~/RI_A/){$desout="         Rel acc ";}
	    $tmp=substr($string{"$desacc"},$it,60);$tmpf=length($tmp)."s";
	    printf $fhout "%-15s|%-$tmpf|\n","$desout",$tmp; }
	$tmp=substr($subacc,$it,60);$tmpf=length($tmp)."s";
	printf $fhout "%15s|%-$tmpf|\n"," subset: SUB acc ",$tmp;
	printf $fhout " \n";}
    print $fhout "--- \n";
    print $fhout "--- PHD PREDICTION END\n";
    print $fhout "--- \n";
    close($fhout);
}				# end of wrt_phd_rdb2pp

#==============================================================================
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
    $tmp= $STRING{"$des"};
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

#==============================================================================
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
	    printf $fh "--- %-13s: %-s\n",$des,$sym{"$des"};}
	print $fh "--- \n--- PhdTopology REFINEMENT AND TOPOLOGY PREDICTION\n";}
    for($it=1;$it<=$nres_tmp;$it+=$nres_per_row) {
	$tmp=&myprt_npoints($nres_per_row,$it);
	printf $fh "%-17s %-s\n"," ",$tmp;
	foreach $_ (@des_loc) {
	    next if (length($STRING{"$_"})<$it);
	    $tmp=substr($STRING{"$_"},$it,$nres_per_row);
	    next if ((! defined $tmp) || (length($tmp)==0));
#	    $format="%-".length($tmp)."s";$len=length($tmp);
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

#==============================================================================
sub wrt_phdpred_from_string_htm_header {&wrt_phdpred_from_string_htmHdr(@_);} # alias


#==============================================================================
sub wrt_ppcol {
    local ($fhoutLoc,%rd)= @_ ;
    local (@des,$ct,$tmp,@tmp,$sep,$des,$des_tmp);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   wrt_ppcol                   writes out the PP column format
#       in:                     $fhoutLoc,%rd
#       out:                    1 or 0
#--------------------------------------------------------------------------------
    return(0,"error rd(des) not defined") if ( ! defined $rd{"des"});
    $tmp=$rd{"des"}; $tmp=~s/^\s*|\s*$//g; # purge leading blanks
    @des=split(/\s+/,$tmp);
    $sep="\t";                  # separator
				# ------------------------------
				# header
    print $fhoutLoc "# PP column format\n";
				# ------------------------------
    foreach $des (@des) {	# descriptor
	if ($des ne $des[$#des]) { 
	    print $fhoutLoc "$des$sep";}
	else {
	    print $fhoutLoc "$des\n";} }
				# ------------------------------
    $des_tmp=$des[1];		# now the prediction in 60 per line
    $ct=1;
    while (defined $rd{"$des_tmp","$ct"}) {
	foreach $des (@des) {
	    if ($des ne $des[$#des]) { 
		print $fhoutLoc $rd{"$des","$ct"},"$sep";}
	    else {
		print $fhoutLoc $rd{"$des","$ct"},"\n";}  }
	++$ct; }
    return(1,"ok");
}				# end of wrt_ppcol

#==============================================================================
# library collected (end)
#==============================================================================

1;

# vim:ai:et:syntax=perl:
