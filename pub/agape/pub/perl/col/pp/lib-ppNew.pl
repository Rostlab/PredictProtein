#! /usr/pub/bin/perl -w
##! /usr/pub/bin/perl
#------------------------------------------------------------------------------#
#	Copyright				  Apr,    	 1998	       #
#	Burkhard Rost 		rost@EMBL-Heidelberg.DE			       #
#	EMBL			http://www.embl-heidelberg.de/~rost/	       #
#	D-69012 Heidelberg						       #
#			        v 1.1   	  ,           1998          #
#------------------------------------------------------------------------------#

#===============================================================================
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
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."blastpExtrId";$fhinLoc="FHIN"."$sbrName";
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

#===============================================================================
sub blastpRdHdr {
    local($fileInLoc2,$fhErrSbr2) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok,@idFound,$Lread,$name,%head,$Lskip,$id,$line);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   blastpRdHdr                 reads header of BLASTP output file
#       in:                     $fileBlast,$filhandle_for_output
#       out:                    (1,'ok',%head)
#       out:                    $head{"$id"}='id1,id2,...'
#       out:                    $head{"$id","$kwd"} , with:
#                                  $kwd=(score|prob|ide|len)
#       err:                    (0,'msg')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."blastpRdHdr";$fhinLoc="FHIN"."$sbrName";
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc2!")    if (! defined $fileInLoc2);
    $fhErrSbr2="STDOUT"                              if (! defined $fhErrSbr);
    return(0,"*** $sbrName: no in file=$fileInLoc2") if (! -e $fileInLoc2);
				# ------------------------------
				# open BLAST output
    $Lok=       &open_file("$fhinLoc","$fileInLoc2");
    return(0,"*** ERROR $sbrName: '$fileInLoc2' not opened\n") if (! $Lok);
				# ------------------------------
    $#idFound=$Lread=0;		# read file
    while (<$fhinLoc>) {
	last if ($_=~/^Sequences producing High/i);}
				# ------------------------------
    while (<$fhinLoc>) {	# skip  header summary
	$_=~s/\n//g;
	next if (length($_)<1 || $_ !~/\S/); # skip empty line
	$Lread=1 if (! $Lread && $_=~/^\>/);
	next if (! $Lread);
	last if ($_=~/^Parameters/); # final
				# ------------------------------
	$line=$_;		# read ali paras
	if    ($line=~/^\>\s*(.*)/){
	    $name=$1;$id=$name;$id=~s/^([\S]+)\s+.*$/$1/g;
	    if (length($id)>0){push(@idFound,$id);$Lskip=0;
			       $head{"$id","name"}=$name;}
	    else              {$Lskip=1;}}
	elsif (! $Lskip && ($line=~/^\s*Length = (\d+)/) && (! defined $head{"$id","len"})){
	    $head{"$id","len"}=$1;}
	elsif (! $Lskip && ($line=~/ Identities = \d+\/\d+ \((\d+)/)&&
	       (! defined $head{"$id","ide"})){
	    $head{"ide","$id"}=$1;}
	elsif (! $Lskip && ($line=~/ Score = (\d+)\s+[^,]*, Expect = ([^,]+), .*$/)&&
	       (! defined $head{"$id","score"})){
	    $head{"$id","score"}=$1;
	    $head{"$id","prob"}= $2;}}close($fhinLoc);
				# ------------------------------
    $head{"id"}="";		# arrange to pass the result
    for $id(@idFound){
	$head{"id"}.="$id,";}$head{"id"}=~s/,$//g;
    $#idFound=0;		# save space
    return(1,"ok $sbrName",%head);
}				# end of blastpRdHdr 

#==========================================================================
sub blastpRun {
    local($niceLoc,$dirData,$dirSwissSplit,$exeBlastp,$exeBlastpFil,$envBlastpMat,
	  $envBlastpDb,$nhits,$parBlastpDb,$fileInLoc,$fileOutLoc,$fileOutFilLoc,$fhTrace)=@_;
    local($sbr,$command,$msg,$Lok);
#----------------------------------------------------------------------
#   blastpRun                   runs BLASTP
#       in:                     $niceLoc,$dirData,$dirSwissSplit,$exeBlastp,$exeBlastpFil,
#       in:                     $envBlastpMat,$envBlastpDb,$numHits,$parBlastpDb,
#       in:                     $fileInLoc,$fileOutLoc,$fileOutFilLoc,$fhTrace
#       out:                    
#       err:                    ok=(1,'ok'), err=(0,'msg')
#----------------------------------------------------------------------
    $sbr="blastpRun";
    $fhTrace="STDOUT"                               if (! defined $fhTrace);
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
    $command="$niceLoc $exeBlastp $parBlastpDb $fileInLoc B=$nhits > $fileOutLoc";
    $msg="--- $sbr '$command'\n";

    $Lok=
	&run_program("$command" ,"$fhTrace","warn");
    if (!$Lok){
	return(0,"*** ERROR $sbr '$Lok'\n"."$msg");}
    if (! -e $fileOutLoc){
	return(0,"*** ERROR $sbr no output '$fileOutLoc'\n"."$msg");}
				# ------------------------------
				# extract hits from BLASTP-output
				# ------------------------------
    $dirSwissSplit=~s/\/$//g;
    $command="$niceLoc $exeBlastpFil $dirSwissSplit < $fileOutLoc > $fileOutFilLoc";
    $msg.="--- $sbr '$command'\n";

    $Lok=
	&run_program("$command" ,"$fhTrace","warn");
    if (!$Lok){
	return(0,"*** ERROR $sbr '$Lok'\n"."$msg");}
    if (! -e $fileOutFilLoc){
	return(0,"*** ERROR $sbr no output '$fileOutFilLoc'\n"."$msg");}
    return(1,"ok $sbr");
}				# end of blastpRun

#===============================================================================
sub coilsRd {
    local($fileInLoc,$fileOutLoc,$probMinLoc,$fhErrSbr) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
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
    return(0,"*** ERROR $sbrName: '$fileInLoc' not opened\n") if (! $Lok);

    $seq=$win[1]=$win[2]=$win[3]="";
    $max[1]=$max[2]=$max[3]=0;
#    $sum[1]=$sum[2]=$sum[3]=0;
    $ptr[1]=14;$ptr[2]=21;$ptr[3]=28;
    while (<$fhinLoc>) {
	last if ($_=~/^\s*[\.]+/);}
    while (<$fhinLoc>) {
	$_=~s/\n//g;$_=~s/^\s*|\s*$//g; # 
	@tmp=split(/\s+/,$_);
	next if ($#tmp<11);
	$seq.="$tmp[2]";
#	$sum[1]+=$tmp[5]; $sum[2]+=$tmp[8];  $sum[3]+=$tmp[11];  
	$win[1].="$tmp[5],";  $max[1]=$tmp[5]  if ($tmp[5]> $max[1]);
	$win[2].="$tmp[8],";  $max[2]=$tmp[8]  if ($tmp[8]> $max[2]);
	$win[3].="$tmp[11],"; $max[3]=$tmp[11] if ($tmp[11]>$max[3]);
    }close($fhinLoc);
				# ------------------------------
				# none above threshold
    return (2,"maxProb ($ptr[1]=$max[1], $ptr[2]=$max[2], $ptr[3]=$max[3]) < $probMinLoc")
	if ( ($max[1]<$probMinLoc) && ($max[1]<$probMinLoc) && ($max[3]<$probMinLoc) );
				# ------------------------------
				# find ma
    ($max,$pos)=&get_max($max[1],$max[2],$max[3]);
    foreach $itw (1..3){
	@tmp=split(/,/,$win[$itw]);
	return(0,"*** ERROR $sbrName: couldnt read coils format $fileInLoc\n")
	    if ($#tmp>length($seq));
	$val[$itw]="";
	foreach $it(1..$#tmp){	# prob to 0-9
	    $tmp=int(10*$tmp[$it]); $tmp=9 if ($tmp>9);$tmp=0 if ($tmp<0);
	    $val[$itw].="$tmp";}}
				# ------------------------------
				# write new output file
    $Lok=       &open_file("$fhoutLoc",">$fileOutLoc");
    return(0,"*** ERROR $sbrName: new '$fileOutLoc' not opened\n") if (! $Lok);
    print $fhoutLoc  "\n";
    print $fhoutLoc  "--- COILS HEADER: SUMMARY\n";
    print $fhoutLoc  "--- best window has width of $ptr[$pos]\n";
    print $fhoutLoc  "--- \n";
    print $fhoutLoc  "--- COILS: SYMBOLS AND EXPLANATIONS ABBREVIATIONS\n";
    printf $fhoutLoc "--- %-12s : %-s\n","seq","one-letter amino acid sequence";
    printf $fhoutLoc 
	"--- %-12s : %-s\n","normWin14","window=14, normalised prob [0-9], 9=high, 0=low";
    printf $fhoutLoc 
	"--- %-12s : %-s\n","normWin21","window=21, normalised prob [0-9], 9=high, 0=low";
    printf $fhoutLoc 
	"--- %-12s : %-s\n","normWin28","window=28, normalised prob [0-9], 9=high, 0=low";
    print $fhoutLoc "--- \n";
    for ($it=1;$it<=length($seq);$it+=50){
	printf $fhoutLoc "COILS %-10s %-s\n","   ",  &myprt_npoints(50,$it);
	printf $fhoutLoc "COILS %-10s %-s\n","seq",  substr($seq,$it,50);
	foreach $itw(1..3){
	    printf $fhoutLoc
		"COILS %-10s %-s\n","normWin".$ptr[$itw],substr($val[$itw],$it,50);}}
    close($fhoutLoc);
    return(1,"ok $sbrName");
}				# end of coilsRd

#===============================================================================
sub coilsRun {
    local($fileInLoc,$fileOutLoc,$exeCoilsLoc,$metricLoc,$optOutLoc,$fhErrSbr) = @_ ;
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
    return(0,"*** $sbrName: not def optOutLoc!")      if (! defined $optOutLoc);
    $fhErrSbr="STDOUT"                                if (! defined $fhErrSbr);

    return(0,"*** $sbrName: no in file $fileInLoc")   if (! -e $fileInLoc);
    $exeCoilsLoc="/home/phd/bin/".$ARCH."/coils"      if (! -e $exeCoilsLoc && defined $ARCH);
    $exeCoilsLoc="/home/phd/bin/SGI64/coils"          if (! -e $exeCoilsLoc && ! defined $ARCH); # HARD_CODED
    return(0,"*** $sbrName: no in exe  $exeCoilsLoc") if (! -e $exeCoilsLoc);
    $metricLoc=  "MTK"                                if (! -e $metricLoc); # metric 1
#    $metricLoc=  "MTIDK"                              if (! -e $metricLoc); # metric 2
    $optOutLoc=  "col"                                if (! -e $optOutLoc);
#    $optOutLoc=  "row"                                if (! -e $optOutLoc);
#    $optOutLoc=  "row"                                if (! -e $optOutLoc);

				# metric
    if    ($metricLoc eq "MTK")  {$met="1";}
    elsif ($metricLoc eq "MTIDK"){$met="2";}
    else  {
	return(0,"*** ERROR $scrName metric=$metricLoc, must be 'MTK' or 'MTIDK' \n");}
				# output option
    if    ($optOutLoc eq "col")  {$opt="p";}
    elsif ($optOutLoc eq "row")  {$opt="a";}
    elsif ($optOutLoc =~/cut/)   {
	$opt="b";
	return(0,"-*- ERROR $scrName optOut=$optOut, not yet implemented\n");}
    elsif ($optOutLoc =~/win/)   {
	$opt="c";
	return(0,"-*- ERROR $scrName optOut=$optOut, not yet implemented\n");}
    else {
	return(0,"*** ERROR $scrName optOut=$optOut no known\n");}
    $an=                       "N"; # no weight for position a & d

    eval "\$cmd=\"$exeCoilsLoc,$fileInLoc,$fileOutLoc,$met,$an,$opt\"";

    $Lok=&run_program("$cmd","$fhErrSbr","warn"); 
    if (! $Lok || ! -e $fileOutLoc){
	return(0,"$sbrName failed to create $fileOutLoc");}
    return(1,"ok $sbrName");
}				# end of coilsRun

#===============================================================================
sub complete_dir { 
    local($dir)=@_; $[=1 ; 
#----------------------------------------------------------------------
#   complete_dir                adds a '/' to directory name if required
#----------------------------------------------------------------------
    if (! defined $dir){
	return;}
    $dir=~s/\s|\n//g; 
    if ( (length($dir)>1)&&($dir!~/\/$/) ) {$dir.="/";} 
    $DIR=$dir;
    return $DIR; 
}				# env of complete_dir

#===============================================================================
sub convFasta2gcg {
    local($exeConvSeqLoc,$file_in_loc,$file_out_loc,$fhTrace)=@_;
    local($outformat,$an,$commandLoc);
#----------------------------------------------------------------------
#   convFasta2gcg               convert fasta format to GCG format
#       in:                     $exeConvSeqLoc,$file_in_loc,$file_out_loc,$fhTrace
#       out:                    
#       err:                    ok=(1,'ok'), err=(0,'msg')
#----------------------------------------------------------------------
    $sbrName="convFasta2gcg";
    return(0,"*** $sbrName: not def file_in_loc!")    if (! defined $file_in_loc);
    return(0,"*** $sbrName: not def file_out_loc!")   if (! defined $file_out_loc);
    return(0,"*** $sbrName: not def exeConvSeqLoc!")  if (! defined $exeConvSeqLoc);
    $fhTrace="STDOUT"                                       if (! defined $fhTrace);
				# check existence of files
    return(0,"*** $sbrName: no file '$file_in_loc'!")   if (! -e $file_in_loc);
    return(0,"*** $sbrName: no exe  '$exeConvSeqLoc'!") if (! -e $exeConvSeqLoc);
				# ------------------------------
				# call FORTRAN program
    $outformat=                 "G";
    $an=                        "N";
    eval "\$commandLoc=\"$exeConvSeqLoc,$file_in_loc,$outformat,$an,$file_out_loc,$an,\"";
    $Lok=
	&run_program("$commandLoc" ,"$fhTrace","warn"); 
    if (! $Lok){
	return(0,"*** $sbrName: couldnt run_program cmd=$commandLoc\n");}
    return(1,"ok $sbrName");
}				# end of convFasta2gcg

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
    $sbrName="convHssp2msf";
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
    $sbrName="convMsf2Hssp";$fhinLoc="FHIN"."$sbrName";
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
	return(0,"$msg");}	# **************************************************

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
    $sbrName="convPhd2col";
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
				# lib-ut
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
    return(1,"ok $sbr");
}				# end of convPhd2col

#===============================================================================
sub convSeq2fasta {
    local($exeConvSeqLoc,$file_in_loc,$file_out_loc,$fhTrace)=@_;
    local($outformat,$an,$commandLoc);
#----------------------------------------------------------------------
#   convSeq2fasta               convert all formats to fasta
#       in:                     $exeConvSeqLoc,$file_in_loc,$file_out_loc,$fhTrace
#       out:                    
#       err:                    ok=(1,'ok'), err=(0,'msg')
#----------------------------------------------------------------------
    $sbrName="convSeq2Fasta";
    return(0,"*** $sbrName: not def file_in_loc!")    if (! defined $file_in_loc);
    return(0,"*** $sbrName: not def file_out_loc!")   if (! defined $file_out_loc);
    return(0,"*** $sbrName: not def exeConvSeqLoc!")  if (! defined $exeConvSeqLoc);
    $fhTrace="STDOUT"                                       if (! defined $fhTrace);
				# check existence of files
    return(0,"*** $sbrName: no file '$file_in_loc'!")   if (! -e $file_in_loc);
    return(0,"*** $sbrName: no exe  '$exeConvSeqLoc'!") if (! -e $exeConvSeqLoc);
				# ------------------------------
				# call FORTRAN program
    $outformat=                 "F";
    $an=                        "N";
    eval "\$commandLoc=\"$exeConvSeqLoc,$file_in_loc,$outformat,$an,$file_out_loc,$an,\"";
    $Lok=
	&run_program("$commandLoc" ,"$fhTrace","warn"); 
    if (! $Lok){
	return(0,"*** $sbrName: couldnt run_program cmd=$commandLoc\n");}
    return(1,"ok $sbrName");
}				# end of convSeq2fasta

#===============================================================================
sub convTopits2msf {
    local($exeConvSeq,$fileInTopitsHssp,$fileOutTopitsMsf,$fhTrace)=@_;
    local($sbrName,$msg);
#----------------------------------------------------------------------
#   convTopits2msf              converts the HSSP file from TOPITS
#       in:                     $fileInLoc,$fileOutLoc,$fileOutFilLoc,$fhTrace
#       out:                    
#       err:                    ok=(1,'ok'), err=(0,'msg')
#----------------------------------------------------------------------
    $sbrName="convTopits2msf";
				# check arguments
    $fhTrace="STDOUT"                                  if (! defined $fhTrace);
    return(0,"*** $sbr: not def exeConvSeq!")          if (! defined $exeConvSeq);
    return(0,"*** $sbr: not def fileInTopitsHssp!")    if (! defined $fileInTopitsHssp);
    return(0,"*** $sbr: not def fileOutTopitsMsf!")    if (! defined $fileOutTopitsMsf);
    return(0,"*** $sbr: miss exe =$exeConvSeq!")       if (! -e $exeConvSeq);
    return(0,"*** $sbr: miss file=$fileInTopitsHssp!") if (! -e $fileInTopitsHssp);
				# convert the sequence
    ($Lok,$msg)=
	&convHssp2msf($exeConvSeq,$fileInTopitsHssp,$fileOutTopitsMsf,$fhTrace);
    if (! $Lok) {
	return(0,"*** ERROR $sbrName convHssp2msf: \n".$msg); }
    if (! -e $fileOutTopitsMsf){
	return(0,"*** ERROR $sbrName no outfile ($fileOutTopitsMsf) after convHssp2msf"); }
    return(1,"ok $sbrName");
}				# end of convTopits2msf

#===============================================================================
sub ctime {
    local($time) = @_;
    local($[) = 0;
    local($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst);
#----------------------------------------------------------------------
# ctime.pl is a simple Perl emulation for the well known ctime(3C) function.
#
# Waldemar Kebsch, Federal Republic of Germany, November 1988
# kebsch.pad@nixpbe.UUCP
# Modified March 1990, Feb 1991 to properly handle timezones
#  $RCSfile: ctime.pl,v $$Revision: 4.0.1.1 $$Date: 92/06/08 13:38:06 $
#   Marion Hakanson (hakanson@cse.ogi.edu)
#   Oregon Graduate Institute of Science and Technology
#
# usage:
#
#     #include <ctime.pl>          # see the -P and -I option in perl.man
#     $Date = &ctime(time);
#----------------------------------------------------------------------
    @DoW = ('Sun','Mon','Tue','Wed','Thu','Fri','Sat');
    @MoY = ('Jan','Feb','Mar','Apr','May','Jun',
	    'Jul','Aug','Sep','Oct','Nov','Dec');

    # Determine what time zone is in effect.
    # Use GMT if TZ is defined as null, local time if TZ undefined.
    # There's no portable way to find the system default timezone.

    $TZ = defined($ENV{'TZ'}) ? ( $ENV{'TZ'} ? $ENV{'TZ'} : 'GMT' ) : '';
    ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) =
        ($TZ eq 'GMT') ? gmtime($time) : localtime($time);

    # Hack to deal with 'PST8PDT' format of TZ
    # Note that this can't deal with all the esoteric forms, but it
    # does recognize the most common: [:]STDoff[DST[off][,rule]]

    if($TZ=~/^([^:\d+\-,]{3,})([+-]?\d{1,2}(:\d{1,2}){0,2})([^\d+\-,]{3,})?/){
        $TZ = $isdst ? $4 : $1;
    }
    $TZ .= ' ' unless $TZ eq '';

    $year += ($year < 70) ? 2000 : 1900;
    sprintf("%s %s %2d %2d:%02d:%02d %s%4d\n",
	    $DoW[$wday], $MoY[$mon], $mday, $hour, $min, $sec, $TZ, $year);
}

#===============================================================================
sub ctrlDbgMsg {
    local ($message,$fhOutLoc,$debugLoc) = @_;
#----------------------------------------------------------------------
#   ctrlDbgMsg                  print a message to STDOUT if debug flag is on
#       in:                     message
#       out:                    DEBUG:
#----------------------------------------------------------------------
    $message= "     DEBUG: $message\n";
    print $fhOutLoc $message; 
#    print $fhOutLoc $message; if ($debugLoc);

}				# end of ctrlDbgMsg

#===============================================================================
sub dsspGetFile { 
    local ($fileInLoc,$Lscreen,@dir) = @_ ; 
    local ($fileDssp,$dir,$tmp,$chain,@dir2,$idLoc);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   dsspGetFile                 searches all directories for existing DSSP file
#       in:                     $file,$Lscreen,@dir
#       out:                    returned file,chain ($dssp,$chain), (if chain in file)
#       watch:                  loop onto itself:
#                               1prcH.dssp not found -> try 1prc.dssp
#--------------------------------------------------------------------------------
    $#dir2=$Lok=0;$chain="";$idLoc=$fileInLoc;$idLoc=~s/^.*\///g;
    foreach $dir(@dir){		# avoid endless loop when calling itself
	if ($dir =~ /\/data\/dssp/) { $Lok=1;}
	push(@dir2,$dir);}
    @dir=@dir2;  if (!$Lok){push(@dir,"/data/dssp/");} # give default
    
    if    (! defined $Lscreen){$Lscreen=0;}
    elsif ($Lscreen !~ /[01]/){push(@dir,$Lscreen);$Lscreen=0;}
    $dsspFileTmp=$fileInLoc;$dsspFileTmp=~s/\s|\n//g;
				# loop over all directories
    $fileDssp=&dsspGetFileLoop($dsspFileTmp,$Lscreen,@dir);
    if ( ! -e $fileDssp ) {	# still not: cut
	$tmp_file=$fileInLoc; $tmp_file=~s/^([A-Za-z0-9]+).*(\.dssp.*)$/$1$2/g;
	$fileDssp=&dsspGetFileLoop($tmp_file,$Lscreen,@dir);}
    if ( ! -e $fileDssp ) {	# still not: assume = chain
	$tmp=$fileInLoc;$tmp=~s/^.*\/|\.dssp|_//g;
	$tmp1=substr($tmp,1,4);$chainLoc=substr($tmp,5,1);
	$tmp_file=$tmp1.".dssp";
	$fileDssp=&dsspGetFileLoop($tmp_file,$Lscreen,@dir);}
    if ( ! -e $fileDssp ) {	# still not: version up
	$tmp1=substr($idLoc,2,3);
	foreach $it(1..9){$tmp_file="$it"."$tmp1".".dssp";
			  $fileDssp=&dsspGetFileLoop($tmp_file,$Lscreen,@dir);}}
    if ( ! -e $fileDssp)     { 
	return(0);}
    if (defined $chainLoc && (length($chainLoc)>0)) { 
	return($fileDssp,$chainLoc);}
    else                     { 
	return($fileDssp);}
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
    $fileOutLoop="unk";
    if (&is_dssp($fileInLoop)){
	return($fileInLoop);}

    foreach $dir (@dir) {
	$dir=&complete_dir($dir); # add slash at end?
	$tmp="$dir"."$fileInLoop"; # try directory
	if ($Lscreen)           { print "--- dsspGetFileLoop: \t trying '$tmp'\n";}
	if (-e $tmp) { $fileOutLoop=$tmp;
		       last;}
	if ($tmp!~/\.dssp/) {	# missing extension?
	    $tmp.=".dssp";
	    if ($Lscreen)       { print "--- dsspGetFileLoop: \t trying '$tmp'\n";}
	    if (-e $tmp)   { $fileOutLoop=$tmp;
			     last;}}}
    $fileOutLoop=~s/\s|\n//g;	# security..
    return($fileOutLoop);
}				# end of dsspGetFileLoop

#===============================================================================
sub dsspRdSeq {
    local ($fileIn,$chainIn,$begIn,$endIn ) = @_ ;
    local ($Lread,$sub_name,$fhin,$aa,$aa2,$seq,$seqC,$chainRd,$pos);
    $[=1;
#----------------------------------------------------------------------
#   dsspRdSeq                   extracts the sequence from DSSP
#       in:                     $file,$chain,$beg,$end
#       out:                    $Lok,$seq,$seqC (second replaced a-z to C)
#----------------------------------------------------------------------
    $sub_name = "dsspRdSeq" ;
    $fhin="fhinDssp";
    &open_file("$fhin","$fileIn");
				#----------------------------------------
				# extract input
    if ((defined $chainIn)&&(length($chainIn)>0)&&($chainIn=~/[A-Z0-9]/)){
	$chainIn=~s/\s//g;$chainIn =~tr/[a-z]/[A-Z]/; }else{$chainIn = "*" ;}
    if ((! defined $begIn)||(length($begIn)==0) ) { $begIn = "*" ; }else{$begIn=~s/\s//g;};
    if ((! defined $endIn)||(length($endIn)==0) ) { $endIn = "*" ; }else{$endIn=~s/\s//g;};

				#--------------------------------------------------
				# read in file
    while ( <$fhin> ) { 
	last if ( /^  \#  RESIDUE/ ); }	# skip anything before data...
    $seq=$seqC="";
    while ( <$fhin> ) {		# read sequence
	$Lread=1;
	$chainRd=substr($_,12,1); 
	$pos=    substr($_,7,5); $pos=~s/\s//g;
				# check chain
	if ( ($chainRd ne "$chainIn") && ($chainIn ne "*") ) { $Lread=0; }
				# check begin
	if ( $begIn ne "*" ) { if ( $pos < $begIn ) { $Lread=0; }}
				# check end
	if ( $endIn ne "*" ) { if ( $pos > $endIn ) { $Lread=0; }}
	if (! $Lread) {		# skip
	    next;}

	$aa=substr($_,14,1);
	$aa2=$aa;if ($aa2=~/[a-z]/){$aa2="C";}	# lower case to C
	$seq.=$aa;$seqC.=$aa2; } close ($fhin);

    if (length($seq)>0){
	return(1,$seq,$seqC);}
    else {
	return(0);}
}                               # end of: dsspRdSeq 

#===============================================================================
sub fastaRdGuide {
    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   fastaRdGuide                reads first sequence in list of FASTA format
#       in:                     $fileInLoc,$fhErrSbr
#       out:                    $id,$seq
#       err:                    ok=(1,'ok'), err=(0,'msg')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."fastaRdGuide";$fhinLoc="FHIN"."$sbrName";

    $Lok=       &open_file("$fhinLoc","$fileInLoc");
    return(0,"*** ERROR $sbrName: old '$fileInLoc' not opened\n"," ") if (! $Lok);
    $ct=0;$seq="";
    while (<$fhinLoc>) {
	$_=~s/\n//g;
	if ($_=~/^\s*>\s*(.+)$/){++$ct;
				 last if ($ct>1);
				 $id=$1;$id=~s/\s//g;$id=~s/^[^A-Za-z0-9]*|[^A-Za-z0-9]*$//g;
				 next;}
	$seq.="$_";}
    $seq=~s/\s//g;
    return(0,"*** ERROR $sbrName: no guide sequence found\n"," ") if (length($seq)<1);
    return(1,$id,$seq);
}				# end of fastaRdGuide

#==========================================================================
sub fastaRun {
    local($niceLoc,$dirData,$exeFasta,$exeFastaFil,$envFastaLibs,$numHits,
	  $parFastaThresh,$parFastaScore,$parFastaSort,
	  $fileInLoc,$fileOutLoc,$fileOutFilLoc,$fhTrace)=@_;
    local($sbr,$command,$msg,$Lok);
#----------------------------------------------------------------------
#   fastaRun                    runs FASTA
#       in:                     $niceLoc,$dirData,$exeFasta,$exeFastaFil,$envFastaLibs,
#       in:                     $numHits,$parFastaThresh,$parFastaScore,$parFastaSort,
#       in:                     $fileInLoc,$fileOutLoc,$fileOutFilLoc,$fhTrace
#       out:                    
#       err:                    ok=(1,'ok'), err=(0,'msg')
#----------------------------------------------------------------------
    $sbr="fastaRun";
    $fhTrace="STDOUT"                              if (! defined $fhTrace);
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
	&run_program("$command" ,"$fhTrace","warn");
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
	&run_program("$command" ,"$fhTrace","warn");
    if (!$Lok){
	return(0,"*** ERROR $sbr '$Lok'\n"."$msg");}
    if (! -e $fileOutFilLoc){
	return(0,"*** ERROR $sbr no output '$fileOutFilLoc'\n"."$msg");}
    return(1,"ok $sbr");
}				# end of fastaRun

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
    $sbrName="fastaWrt";$fhoutLoc="FHOUT"."$sbrName";

    $Lok=       &open_file("$fhoutLoc",">$fileOutLoc");
    if (! $Lok){$msg="*** ERROR $sbrName: '$fileOutLoc' not opened for write\n";
		return(0,$msg);}
    print $fhoutLoc ">$id\n";
    for($it=1;$it<=length($seqLoc);$it+=50){
	foreach $it2 (1..5){
	    last if (($it+10*$it2)>=length($seqLoc));
	    printf $fhoutLoc "%-10s ",substr($seqLoc,($it+10*$it2),10);}
	print $fhoutLoc "\n";}
    close($fhoutLoc);
    return(1,"ok $sbrName");
}				# end of fastaWrt

#===============================================================================
sub filePurgeBlankLines {
    local ($fileTo_filter,$file_filtered,$fileTmp) = @_;
    local ($fhin,$tmp,@tmp,$fhout,$fileOutLoc);
#--------------------------------------------------------------------------------
#   filePurgeBlankLines         removes all blank lines from a file
#       in:                     fileTo_be_filtered
#       out:                    
#                               filtered_file (will have same name)
#                               if no specific filename is defined
#           NOTE:               temporary write into fileTmp for security
#       err:                    ok=(1,'ok'), err=(0,'msg')
#--------------------------------------------------------------------------------
    $sbrName="filePurgeBlankLines";
    return(0,"*** $sbrName: not def fileTo_filter!") if (! defined $fileTo_filter);
    return(0,"*** $sbrName: not def file_filtered!") if (! defined $file_filtered);
    return(0,"*** $sbrName: not def fileTmp!")       if (! defined $fileTmp);
    return(0,"*** $sbrName ERROR missing input file ($fileTo_filter)")
	if (! -e $fileTo_filter );
				# ------------------------------
    $fhin="FHIN_FILTER";	# open file
    open ("$fhin","$fileTo_filter");
				# ------------------------------
    $#tmp=0;			# read file
    while (<$fhin>) {$_=~s/\n//g;$line=$_;$_=~s/\s//g;
		     next if (length($_)<1);
		     push(@tmp,$line)}
    close($fhin);

    $fhout="FHOUT_filePurgeBlankLines";
				# ------------------------------
				# write new output
    if ($fileTo_filter eq $file_filtered){
	$fileOutLoc=$fileTmp;}	# security: temporary file
    else {$fileOutLoc=$file_filtered;}

    open ("$fhout", ">$fileOutLoc")  ||
	return(0,"*** $sbrName ERROR opening output file ($fileOutLoc)");
    foreach $tmp(@tmp){
	print $fhout "$tmp\n";}
    close("$fhout");
    $#tmp=0;			# save space
    if (! -e $fileOutLoc){
	return(0,"*** $sbrName ERROR missing output file ($fileOutLoc)");}
				# ------------------------------
				# delete file
    if ($fileTo_filter eq $file_filtered){
	unlink $fileTo_filter;
	($Lok,$msg)=
	    &sysMvfile($fileOutLoc,$file_filtered);
	return(0,"\n*** $sbrName ERROR mv file error\n"."$msg") if (! $Lok);}
    if (! -e $file_filtered){
	return(0,"*** $sbrName ERROR missing output file ($file_filtered)");}
    return(1,"$sbrName ok");
}				# end filePurgeBlankLines 

#===============================================================================
sub filePurgeNullChar {
    local ($fileTo_filter,$file_filtered,$fileTmp) = @_;
    local ($fhin,$tmp,@tmp,$fhout);
#--------------------------------------------------------------------------------
#   filePurgeNullChar           removes all null characters
#       in:                     fileTo_be_filtered
#       out:                    
#                               filtered_file (will have same name)
#                               if no specific filename is defined
#                               NOTE: temporary write into fileTmp for security
#       err:                    ok=(1,'ok'), err=(0,'msg')
#--------------------------------------------------------------------------------
    $sbrName="filePurgeNullChar";
    return(0,"*** $sbrName: not def fileTo_filter!") if (! defined $fileTo_filter);
    return(0,"*** $sbrName: not def file_filtered!") if (! defined $file_filtered);
    return(0,"*** $sbrName: not def fileTmp!")       if (! defined $fileTmp);
    return(0,"*** $sbrName ERROR missing input file ($fileTo_filter)")
	if (! -e $fileTo_filter );
				# open file
    $fhin="FHIN_purgeNullChar";
    open ("$fhin","$fileTo_filter");
				# ------------------------------
    $#tmp=0;			# read file
    while (<$fhin>) {$_=~s/\0//g;
		     push(@tmp,$_);}
    close($fhin);
				# ------------------------------
				# write new output
    $fhout="FHOUT_filePurgeNullChar";	
    if ($fileTo_filter eq $file_filtered){
	$fileOutLoc=$fileTmp;}	# security: temporary file
    else {$fileOutLoc=$file_filtered;}

    open ("$fhout", ">$fileOutLoc")  ||
	return(0,"*** $sbrName ERROR opening output file ($fileOutLoc)");
    foreach $tmp(@tmp){
	print $fhout "$tmp\n";}
    close("$fhout");

    $#tmp=0;			# save space
    if (! -e $fileOutLoc){
	return(0,"*** $sbrName ERROR missing output file ($fileOutLoc)");}
				# ------------------------------
				# delete file
    if ($fileTo_filter eq $file_filtered){
	unlink $fileTo_filter;
	($Lok,$msg)=
	    &sysMvfile($fileOutLoc,$file_filtered);
	return(0,"\n*** $sbrName ERROR mv file error='"."$msg'\n") if (! $Lok);}
    if (! -e $file_filtered){
	return(0,"*** $sbrName ERROR missing output file ($file_filtered)");}
    return(1,"$sbrName ok");
}				# end filePurgeNullChar

#===============================================================================
sub filePurgePat1Pat2 {
    local ($fileTo_filter,$file_filtered,$fileTmp,$pattern1,$pattern2) = @_;
    local ($hide,$fhin,);
#--------------------------------------------------------------------------------
#   filePurgePat1Pat2           remove from input file all lines between the line 
#                               with pattern1 (include) and the line with pattern2 (exclude)
#                               pattern search is case insensitive
#                               if pattern2 = "EOF" then remove till end
#       in:                     $fileTo_filter,$file_filtered,$fileTmp,$pattern1,$pattern2
#       out:                    
#       err:                    ok=(1,'ok'), err=(0,'msg')
#--------------------------------------------------------------------------------
    $sbrName="filePurgePat1Pat2";
    return(0,"*** $sbrName: not def fileTo_filter!") if (! defined $fileTo_filter);
    return(0,"*** $sbrName: not def file_filtered!")  if (! defined $file_filtered);
    return(0,"*** $sbrName: not def fileTmp!")       if (! defined $fileTmp);
    return(0,"*** $sbrName: not def pattern1!")       if (! defined $pattern1);
    return(0,"*** $sbrName: not def pattern2!")       if (! defined $pattern2);
    return(0,"*** $sbrName ERROR missing input file ($fileTo_filter)")
	if (! -e $fileTo_filter );
				# ------------------------------
    $pattern1=~ tr/a-z/A-Z/;	# comparison done in upper case
    $pattern2=~ tr/a-z/A-Z/;
				# open file
    $fhin="FHIN_purgeNullChar";
    open ("$fhin","$fileTo_filter");
				# ------------------------------
    $#tmp=$hide=0;		# read file
    while (<$fhin>) {$tmp= $_;
		     $tmp=~tr/a-z/A-Z/;
		     if ($tmp =~ /$pattern1/) { $hide=1;}
		     if ($tmp =~ /$pattern2/) { $hide=0;}
		     if (!$hide) {
			 push(@tmp,$_);}}
    close($fhin);
				# ------------------------------
                                # if we miss the second pattern
                                #    do not apply filter
    if (!$hide || $pattern2 eq "EOF") {
                            	# overwrite the input file with the temp file
#	system "mv $fileTmp $fileTo_filter"; 
				# br: should be the other way around!
				# just don't touch file
    }
    else {			# remove the temp file
				# ------------------------------
				# write new output
	$fhout="FHOUT_filePurgePat1Pat2";	
	if ($fileTo_filter eq $file_filtered){
	    $fileOutLoc=$fileTmp;}	# security: temporary file
	else {
	    $fileOutLoc=$file_filtered;}
	
	open ("$fhout", ">$fileOutLoc")  ||
	    return(0,"*** $sbrName ERROR opening output file ($fileOutLoc)");
	foreach $tmp(@tmp){
	    print $fhout "$tmp\n";}
	close("$fhout");
	
	$#tmp=0;		# save space
	
	if (! -e $fileOutLoc){
	    return(0,"*** $sbrName ERROR missing output file ($fileOutLoc)");}
				# ------------------------------
				# delete file
	if ($fileTo_filter eq $file_filtered){
	    unlink $fileTo_filter;
	    ($Lok,$msg)=
		&sysMvfile($fileOutLoc,$file_filtered);
	    return(0,"\n*** $sbrName ERROR mv file error\n"."$msg") if (! $Lok);}
	if (! -e $file_filtered){
	    return(0,"*** $sbrName ERROR missing output file ($file_filtered)");}
    }
    return(1,"$sbrName ok");

}				# end filePurgePat1Pat2

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
sub get_id { local ($file) = @_ ; local($id);$[ =1 ;
#--------------------------------------------------------------------------------
#   get_id                      extracts an identifier from file name
#                               note: assume anything before '.' or '-'
#       in:                     $file
#       out:                    $id
#--------------------------------------------------------------------------------
	     $id=$file;$id=~s/\s|\n//g;$id=~s/.*\///g;$id=~s/\W*(\w+)[.-].*/$1/;
	     return($id);
}				# end of get_id

#================================================================================
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

#================================================================================
sub get_min { $[=1;local($ct,$pos,$min);$min=100000; $ct=0; 
#----------------------------------------------------------------------
#   get_min                     returns the minimum of all elements of @in
#       in:                     @in
#       out:                    returned $min,$pos (position of minimum)
#----------------------------------------------------------------------
	      foreach $_(@_){++$ct; if($_<$min){$min=$_;$pos=$ct;}}
	      return ($min,$pos); } # end of get_min

#===============================================================================
sub get_pdbid { local ($file) = @_ ; local($id);$[ =1 ;
#--------------------------------------------------------------------------------
#   get_pdbid                   extracts a valid PDB identifier from file name
#                               note: assume \w\w\w\w
#       in:                     $file
#       out:                    $id
#--------------------------------------------------------------------------------
		$id=$file;$id=~s/\s|\n//g;$id=~s/.*\///g;$id=~s/\W*(\w\w\w\w).*/$1/;
		return($id);
}				# end of get_pdbid

#===============================================================================
sub get_range {
    local ($range_txt,$nall) = @_;
    local (@range,@rangeLoc,$it,$range1,$range2);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   get_range                   flags positions (in pairs) to include
#       in:                     e.g. incl=1-5,9,15 
#       out:                    @takeLoc
#--------------------------------------------------------------------------------
    $#range=0;
    if ($range_txt eq "unk") {
	print "*** ERROR in get_range: argument: '$range_txt,$nall' not digestable\n"; 
	@range=(0);
	return(0);}
    if ($range_txt =~ /\,/) {
	@range=split(/,/,$range_txt);}
    elsif ($range_txt =~ /(\d*|\*)-(\d*|\*)/) { 
	@range=
	    &get_rangeHyphen($range_txt,$nall);}
    else {
	@range=(0); 
	return(0);}
				# process further elements with hyphens
    $#range2=0;
    foreach $range (@range){
	if ($range =~ /(\d*|\*)-(\d*|\*)/) {
	    @rangeLoc=
		&get_rangeHyphen($range,$nall);
	    push(@range2,@rangeLoc);}
	else {push(@range2,$range);}}
				# sort
    if ($#range2>1){
	@range=sort {$a<=>$b} @range2;}else{@range=@range2;}
    return (@range);
}				# end of get_range

#===============================================================================
sub get_rangeHyphen {
    local ($range_txt,$nall) = @_ ;
    local (@rangeLoc,$it,$range1,$range2);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   get_rangeHyphen             reads 'n1-n2'  
#       in:                     $range_txt,$nall (number of all)
#       out:                    @rangeLoc ("1,2,5,7")
#--------------------------------------------------------------------------------
    if ($range_txt =~ /(\d*|\*)-(\d*|\*)/) { 
	($range1,$range2)=split(/-/,$range_txt);
	if ($range1=~/\*/) {$range1=1;}
	if ($range2=~/\*/) {$range2=$nall;} 
	for($it=$range1;$it<=$range2;++$it) {push(@rangeLoc,$it);} }
    else { @rangeLoc=($range_txt);}
    return(@rangeLoc);
}				# end of get_rangeHyphen

#================================================================================
sub get_sum { local(@data)=@_;local($it,$ave,$var,$sum);$[=1;
#----------------------------------------------------------------------
#   get_sum                     computes the sum over input data
#       in:                     @data
#       out:                    $sum,$ave,$var
#----------------------------------------------------------------------
	      $sum=0;foreach $_(@_){if(defined $_){$sum+=$_;}}
	      ($ave,$var)=&stat_avevar(@data);
	      return ($sum,$ave,$var); } # end of get_sum

#===============================================================================
sub getFileFormat {
    local ($fileInLoc,$kwdLoc,@dirLoc) = @_ ;
    local ($sbrName,$fhinLoc,$tmp,@tmpFile,@tmpChain,
	   @formatLoc,@fileLoc,@chainLoc,%fileLoc,@fileRdLoc,$Lok,$txtLoc,$file);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getFileFormat               returns format of file
#       in:                     $file
#                               $kwd = any|HSSP|DSSP|SWISS|DAF|MSF|RDB|FASTA|PIR
#                               @dir = directories to search for files
#       out:                    $Lok,%fileFound
#                               $fileFound{"NROWS"}=      number of files found
#                               $fileFound{"ct"}=         name-of-file-ct
#                               $fileFound{"format","ct"}=format
#-------------------------------------------------------------------------------
    $sbrName="lib-pp.pl:"."getFileFormat";$fhinLoc="FHIN"."$sbrName";
    undef %fileLoc;
    if ($#dirLoc >0){$#tmp=0;	# include existing directories only
		     foreach $dirLoc(@dirLoc){if (-d $dirLoc){push(@tmp,$dirLoc);}}
		     @dirLoc=@tmp;}
				# check whether keyword understood
    if (! defined $kwdLoc){$kwdLoc="any";}
    if ($kwdLoc !~/^(any|HSSP|DSSP|SWISS|DAF|MSF|RDB|FASTA|PIR)/i){
	print 
	    "-*- WARNING $sbrName wrong input keyword, is=$kwdLoc, \n",
	    "-*-         must be any of: 'any|HSSP|DSSP|SWISS|DAF|RDB|FASTA|PIR'\n";
	return(0,"err","$kwdLoc, wrong keyword",%fileLoc);}

    $#fileLoc=$#chainLoc=$#formatLoc=0;
				# ------------------------------
				# databases
    if ($kwdLoc =~ /^HSSP|^any/i){
	($Lok,$txtLoc,@fileRdLoc)=&isHsspGeneral($fileInLoc,@dirLoc);
	if ($Lok){
	    $#tmpFile=$#tmpChain=$Lchain=0;
	    if    ($txtLoc eq "isHsspList"){
		$Lchain=0;
		foreach $tmp (@fileRdLoc){
		    if   ($tmp eq "chain"){$Lchain=1;}
		    elsif(! $Lchain)      {push(@tmpFile,$tmp);push(@formatLoc,"HSSP");}
		    else                  {push(@tmpChain,$tmp);}}}
				# is single file
	    elsif ($txtLoc eq "isHssp"){
		if ($#fileRdLoc>1){ # one file with chain
		    push(@tmpFile,$fileRdLoc[1]);push(@formatLoc,"HSSP");
		    push(@tmpChain,$fileRdLoc[2]);}
		else {
		    push(@tmpFile,$fileRdLoc[1]);push(@formatLoc,"HSSP");}}
	    elsif ($txtLoc =~ /^no/){ #
		print "*** $sbrName ERROR in HSSP read\n";}
	    elsif ($txtLoc =~ /empty/){
		print "*** $sbrName HSSP read, $fileRdLoc[1] is empty\n";}
	    push(@fileLoc,@tmpFile);
	    push(@chainLoc,@tmpChain);}}
    if (!$Lok && ($kwdLoc =~ /^DSSP|^any/i)){
	($Lok,$txtLoc,@fileRdLoc)=&isDsspGeneral($fileInLoc,@dirLoc);
	if ($Lok){
	    $#tmpFile=$#tmpChain=$Lchain=0;
				# is list
	    if    ($txtLoc eq "isDsspList"){
		$Lchain=0;
		foreach $tmp (@fileRdLoc){
		    if   ($tmp eq "chain"){$Lchain=1;}
		    elsif(! $Lchain)      {push(@tmpFile,$tmp);push(@formatLoc,"DSSP");}
		    else                  {push(@tmpChain,$tmp);}}}
				# is single file
	    elsif ($txtLoc eq "isDssp"){
		if ($#fileRdLoc>1){ # one file with chain
		    push(@tmpFile,$fileRdLoc[1]);push(@formatLoc,"DSSP");
		    push(@tmpChain,$fileRdLoc[2]);}
		else {
		    push(@tmpFile,$fileRdLoc[1]);push(@formatLoc,"DSSP");}}
	    elsif ($txtLoc =~ /^no/){ # 
		print "*** $sbrName ERROR in DSSP read\n";}
	    push(@fileLoc,@tmpFile);
	    push(@chainLoc,@tmpChain);}}
				# ------------------------------
				# sequence formats
    if (!$Lok && ($kwdLoc =~ /^SWISS|^any/i)){
	($Lok,$txtLoc,@fileRdLoc)=&isSwissGeneral($fileInLoc,@dirLoc);
	if ($Lok){push(@fileLoc,@fileRdLoc);
		  foreach (@fileRdLoc){push(@formatLoc,"SWISS");
				       push(@chainLoc," ");}}}
    if (!$Lok && ($kwdLoc =~ /^PIR\w*|^any/i)){
	($Lok,$txtLoc,@fileRdLoc)=&isPirMul($fileInLoc);
	if ($Lok){push(@fileLoc,@fileRdLoc);
		  foreach (@fileRdLoc){push(@formatLoc,"PIR_MUL");
				       push(@chainLoc," ");}}}
    if (!$Lok && ($kwdLoc =~ /^PIR|^any/i)){
	($Lok,$txtLoc,@fileRdLoc)=&isPir($fileInLoc);
	if ($Lok){push(@fileLoc,@fileRdLoc);
		  foreach (@fileRdLoc){push(@formatLoc,"PIR");
				       push(@chainLoc," ");}}}
    if (!$Lok && ($kwdLoc =~ /^FASTA|^any/i)){
	($Lok,$txtLoc,@fileRdLoc)=&isFastaMul($fileInLoc);
	if ($Lok){push(@fileLoc,@fileRdLoc);
		  foreach (@fileRdLoc){push(@formatLoc,"FASTA");
				       push(@chainLoc," ");}}}
    if (!$Lok && ($kwdLoc =~ /^FASTA|^any/i)){
	($Lok,$txtLoc,@fileRdLoc)=&isFasta($fileInLoc);
	if ($Lok){push(@fileLoc,@fileRdLoc);
		  foreach (@fileRdLoc){push(@formatLoc,"FASTA");
				       push(@chainLoc," ");}}}
				# ------------------------------
				# RDB
    if (!$Lok && ($kwdLoc =~ /^RDB|^any/i)){
	($Lok,$txtLoc,@fileRdLoc)=&isRdbGeneral($fileInLoc,@dirLoc);
	if ($Lok){push(@fileLoc,@fileRdLoc);
		  foreach (@fileRdLoc){push(@formatLoc,"RDB");
				       push(@chainLoc," ");}}}
				# ------------------------------
				# alignment formats
    if (!$Lok && ($kwdLoc =~ /^MSF|^any/i)){
	($Lok,$txtLoc,@fileRdLoc)=&isMsfGeneral($fileInLoc,@dirLoc);
	if ($Lok){push(@fileLoc,@fileRdLoc);
		  foreach (@fileRdLoc){push(@formatLoc,"MSF");
				       push(@chainLoc," ");}}}
    if (!$Lok && ($kwdLoc =~ /^DAF|^any/i)){
	($Lok,$txtLoc,@fileRdLoc)=&isDafGeneral($fileInLoc,@dirLoc);
	if ($Lok){push(@fileLoc,@fileRdLoc);
		  foreach (@fileRdLoc){push(@formatLoc,"DAF");
				       push(@chainLoc," ");}}}

    if (!$Lok || ($#fileLoc<1)){
	return(0,"*** ERROR $sbrName: kwd=$kwdLoc, no file '$fileInLoc' found\n",%fileLoc);}

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
#       out:                    1,'ok',len,nexp,nfit,diff,explanation
#       err:                    0,message
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."globe";$fhinLoc="FHIN"."$sbrName";
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
	     "fit2Ave100","fit2Sig100","fit2Add100","fit2Fac100");
				# read command line
    foreach $_(@passLoc){
	$Lok=0;
	if   ($_=~/^isPred/)       {$parSbr{"isPred"}=  1;$Lok=1;}
	elsif($_=~/^fix/)          {$parSbr{"doFixPar"}=1;$Lok=1;}
	elsif($_=~/^[r]eturn/)     {$parSbr{"doReturn"}=1;$Lok=1;}
	foreach $kwd (@par){
	    if ($_=~/^$kwd=(.*)$/) {$parSbr{"$kwd"}=$1;$Lok=1;}}
	return(0,"*** $sbrName: wrong command line arg '$_'\n") if (! $Lok);}
    $exposed=$parSbr{"exposed"};
				# ------------------------------
				# (1) read file
    ($len,$numExposed)=
	&globeRdPhdRdb($fileInLoc,$fhErrSbr);
				# ERROR
    return(0,"*** ERROR $sbrName: $numExposed\n") 
	if (! $len || ! defined $numExposed || $numExposed =~/\D/);
    
				# ------------------------------
				# get the expected number of res
    if (! $parSbr{"doFixPar"} && ($len < 100)){
	$fit2Add=$parSbr{"fit2Add100"};$fit2Fac=$parSbr{"fit2Fac100"};}
    else {
	$fit2Add=$parSbr{"fit2Add"};   $fit2Fac=$parSbr{"fit2Fac"};}

    ($Lok,$numExpect)=
	&globeFuncFit($len,$fit2Add,$fit2Fac,$parSbr{"exposed"});
				# ------------------------------
				# evaluate the result
    $diff=$numExposed-$numExpect;
    if    ($diff > 20){
	$evaluation="your protein may be globular, but it is not as compact as a domain";}
    elsif ($diff > (-5)){
	$evaluation="your protein appears as compact, as a globular domain";}
    elsif ($diff > (-10)){
	$evaluation="your protein appears not as globular, as a domain";}
    else {
	$evaluation="your protein appears not to be globular";}
	
    return(1,"ok $sbrName",$len,$numExposed,$numExpect,$diff,"$evaluation");
}				# end of globeOne

#===============================================================================
sub globeFuncFit {
    local($lenIn,$add,$fac,$expLoc) = @_ ;local($tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   globeFuncFit_16             length to number of surface molecules fitted to PHD error 
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
    else{ return(0,"*** ERROR in $scrName globeFuncFit only defined for exp=16 or 9\n");}
}				# end of globeFuncFit

#===============================================================================
sub globeRdPhdRdb {
    local($fileInLoc2,$fhErrSbr2) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok,@tmp,$msgErr,
	  $ctTmp,$Lboth,$Lsec,$len,$numExposed,$lenRd,$rel);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   globeRdPhdRdb               read PHD rdb file with ACC
#       in:                     $fileInLoc,$fhErrSbr2
#       out:                    $len,$numExposed
#       err:                    0,'msg'
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."globeRdPhdRdb";$fhinLoc="FHIN"."$sbrName";
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc2!")        if (! defined $fileInLoc2);
    $fhErrSbr2="STDOUT"                                  if (! defined $fhErrSbr);
    return(0,"*** $sbrName: no in file '$fileInLoc2'!")  if (! -e $fileInLoc2);

    $Lok=       &open_file("$fhinLoc","$fileInLoc2");
    if (! $Lok){print $fhErrSbr2 "*** ERROR $sbrName: '$fileInLoc2' not opened\n";
		return(0);}
				# reading file
    $ctTmp=$Lboth=$Lsec=$len=$numExposed=0;
    while (<$fhinLoc>) {
	++$ctTmp;
	if ($_=~/^\# LENGTH\s+\:\s*(\d+)/){
	    $lenRd=$1;}
	if ($ctTmp<3){if    ($_=~/^\# PHDsec\+PHDacc/){$Lboth=1;}
		      elsif ($_=~/^\# PHDacc/)        {$Lboth=0;}
		      elsif ($_=~/^\# PHDsec/)        {$Lsec=1;}}
				# ******************************
	last if ($Lsec);	# ERROR is not PHDacc, at all!!!
				# ******************************
	next if ($_=~/^\#|^No|^4N/); # skip comments and first line
	$_=~s/\n//g;
	@tmp=split(/\t/,$_);	# $id,$chain,$len,$nali,$seq,$sec,$acc,$rel
	
	return(0,"*** ERROR $sbrName: too few elements in id=$id, line=$_\n") if ($#tmp<6);

	foreach $tmp(@tmp){$tmp=~s/\s//g;} # skip blanks
	if    ($Lboth){		# PHDsec+acc
	    $pos=9; $pos=12 if (! $parSbr{"isPred"});} # correct for pred+obs
	else          {		# PHDacc
	    $pos=4; $pos=6  if (! $parSbr{"isPred"});} # correct for pred+obs
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
    return($len,$numExposed);
}				# end of globeRdPhdRdb

#===============================================================================
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
    print $fhoutTmp
	"# Perl-RDB generated by:$scrName on:$date\n",
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
	"# COMMENTS    http://www.embl-heidelberg.de/~rost/Papers/98globe.html\n",
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
    if (!defined $Lscreen){
	$Lscreen=0;}
    $fhin="FHIN_HSSP_RD_STRIP_ONE";

    @des=("seq1","seq2","sec1","sec2");
    foreach $des(@des){		# initialise
	$rdLoc{"$des"}="";}
    if (!-e $fileInLoc){
	print "*** ERROR hssp_rd_strip_one (lib-pp): '$fileInLoc' strip file missing\n";
	exit;}
#    if (&is_strip_old($fileInLoc)){
#	print "*** ERROR hssp_rd_strip_one (lib-pp): only with new strip format\n";
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
    while (<$fhin>) {last if (/=== ALIGNMENTS ===/);}
				# ----------------------------------------
				# loop over all parts of the alignments
    $Lok=0;$#tmp=$ct=$ct_guide=$ct_aligned=0;$Ltake_it=$Lguide=$Laligned=0;
    while (<$fhin>) {
	if (length($_)<2) {	# ignore blank lines
	    next;}
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
    if ($Lscreen) { print"--- lib-pp.pl:hssp_rd_strip_one \t read in from '$fileInLoc'\n";
		    foreach $des(@des){
			print "$des:",$rdLoc{"$des"},"\n";}}
    return (%rdLoc);
}				# end of hssp_rd_strip_one

#===============================================================================
sub hssp_rd_strip_one_correct1 {
#   correct for begin and ends
    $diff=(length($rdLoc{"seq1"})-length($rdLoc{"seq2"}));
    if ($diff!=0){
	foreach $it (1..$diff){
	    $rdLoc{"seq2"}.=".";$rdLoc{"sec2"}.="."; }}
}				# end of hssp_rd_strip_one_correct1

#===============================================================================
sub hssp_rd_strip_one_correct2 {
#   shorten indels for begin and ends
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
 
#==========================================================================
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
    $sbr="hsspChopProf";
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
sub hsspGetChain {
    local ($fileIn) = @_ ;
    local ($fhin,$ifirLoc,$ilasLoc,$tmp1,$tmp2,
	   $chainLoc,$posLoc,$posRd,$chainRd,@cLoc,@pLoc,%rdLoc);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   hsspGetChain                extracts all chain identifiers in HSSP file
#       in:                     $file
#       out:                    $chains (ABC) ,%rdLoc
#       out                        $rdLoc{"NROWS"},$rdLoc{"ct","chain"},
#       out                        $rdLoc{"ct","ifir"},$rdLoc{"ct","ilas"}
#--------------------------------------------------------------------------------
    $fhin="FhInHssp";
    &open_file("$fhin","$fileIn");
    while(<$fhin>){		# until start of data
	last if (/^ SeqNo/);}
    $chainLoc=$posLoc="";
    while(<$fhin>){if (/^\#/){if (length($chainLoc)>1){$posLoc.="$ifirLoc-$ilasLoc".",";}
			      last;}
		   $chainRd=substr($_,13,1);$aaRd=substr($_,15,1);
		   $posRd=substr($_,1,6);$posRd=~s/\s//g;
		   if ($aaRd eq "!") { # skip over chain break
		       next;}
		   elsif ($chainLoc !~/$chainRd/){	# new chain?
		       if (length($chainLoc)>1){$posLoc.="$ifirLoc-$ilasLoc".",";}
		       $chainLoc.="$chainRd".",";$ifirLoc=$ilasLoc=$posRd;}
		   else { $ilasLoc=$posRd;}}close($fhin);
    $chainLoc=~s/^,|,$//g;$posLoc=~s/\s//g;$posLoc=~s/^,|,$//g; # purge leading ','
				# now split chains read
    undef %rdLoc; $ctLoc=0;@cLoc=split(/,/,$chainLoc);@pLoc=split(/,/,$posLoc);
    foreach $itLoc(1..$#cLoc){
	($tmp1,$tmp2)=split(/-/,$pLoc[$itLoc]);
	if ($tmp2>$tmp1){	# exclude chains of length 1
	    ++$ctLoc;$rdLoc{"NROWS"}=$ctLoc;$rdLoc{"$ctLoc","chain"}=$cLoc[$itLoc];
	    $rdLoc{"$ctLoc","ifir"}=$tmp1;$rdLoc{"$ctLoc","ilas"}=$tmp2;}}
    $chainLoc=~s/,//g;
    return($chainLoc,%rdLoc);
}				# end of hsspGetChain

#===============================================================================
sub hsspGetChainLength {
    local ($fileIn,$chainLoc) = @_ ;
    local ($file_hssp,$ct,$tmp,$beg,$end,$pos);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   hsspGetChainLength          extracts the length of a chain in an HSSP file
#       in:                     hssp_file,chain,
#       out:                    length
#--------------------------------------------------------------------------------
    $fileIn=~s/\s//g;$fileIn=~s/\n//g;
    $file_hssp=$fileIn; if ($chainLoc eq "*"){$Lchain=0;}else{$Lchain=1;}
    if (! -e $file_hssp) { print "*** '$fileIn', the hssp file missing\n"; return(0);}
    &open_file("FHIN", "$file_hssp");
    while ( <FHIN> ) { last if (/^ SeqNo/); }
    $ct=$pos=0;
    while ( <FHIN> ) { last if (/^\#\# /);
		       ++$pos;$tmp=substr($_,13,1);
		       if    ( $Lchain && ($tmp eq $chainLoc) ) { ++$ct; }
		       elsif ( ! $Lchain )                      { ++$ct; }
		       elsif ( $ct>1 ) {
			   last;}
		       if ($ct==1){$beg=$pos;}}close(FHIN);
    $end=$pos;
    return($ct,$beg,$end);
}				# end of hsspGetChainLength

#===============================================================================
sub hsspGetFile { 
    local ($fileInLoc,$Lscreen,@dir) = @_ ; 
    local ($fileHssp,$dir,$tmp,$chainLoc,@dir2,$idLoc);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   hsspGetFile                 searches all directories for existing HSSP file
#       in:                     $file,$Lscreen,@dir
#       out:                    returned file,chain ($hssp,$chain), (if chain in file)
#         watch:                loop onto itself:
#                               1prcH.hssp not found -> try 1prc.hssp
#--------------------------------------------------------------------------------
    $#dir2=$Lok=0;$chainLoc="";$idLoc=$fileInLoc;$idLoc=~s/^.*\///g;
    foreach $dir(@dir){		# avoid endless loop when calling itself
	if ($dir =~ /\/data\/hssp/) { $Lok=1;}
	push(@dir2,$dir);}
    @dir=@dir2;  if (!$Lok){push(@dir,"/data/hssp/");} # give default
    
    if    (! defined $Lscreen){$Lscreen=0;}
    elsif ($Lscreen !~ /[01]/){push(@dir,$Lscreen);$Lscreen=0;}
    $hsspFileTmp=$fileInLoc;$hsspFileTmp=~s/\s|\n//g;
				# loop over all directories
    $fileHssp=&hsspGetFileLoop($hsspFileTmp,$Lscreen,@dir);
    if ( ! -e $fileHssp ) {	# still not: cut
	$tmp_file=$fileInLoc; $tmp_file=~s/^([A-Za-z0-9]+).*(\.hssp.*)$/$1$2/g;
	$fileHssp=&hsspGetFileLoop($tmp_file,$Lscreen,@dir);}
    if ( ! -e $fileHssp ) {	# still not: assume = chainLoc
	$tmp=$fileInLoc;$tmp=~s/^.*\/|\.hssp|_//g;
	$tmp1=substr($tmp,1,4);$chainLoc=substr($tmp,5,1);
	$tmp_file=$tmp1.".hssp";
	$fileHssp=&hsspGetFileLoop($tmp_file,$Lscreen,@dir);}
    if ( ! -e $fileHssp || &is_hssp_empty($fileHssp)) {	# still not: version up
	$tmp1=substr($idLoc,2,3);
	foreach $it(1..9){$tmp_file="$it"."$tmp1".".hssp";
			  $fileHssp=&hsspGetFileLoop($tmp_file,$Lscreen,@dir);}}
    if ( ! -e $fileHssp || &is_hssp_empty($fileHssp))  { 
	return(0);}
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
    $fileOutLoop="unk";
    if (&is_hssp($fileInLoop)){
	return($fileInLoop);}

    foreach $dir (@dir) {
	$dir=&complete_dir($dir); # add slash at end?
	$tmp="$dir"."$fileInLoop"; # try directory
	if ($Lscreen)           { print "--- hsspGetFileLoop: \t trying '$tmp'\n";}
	if (-e $tmp) { 
	    return($tmp);}
	if ($tmp!~/\.hssp/) {	# missing extension?
	    $tmp.=".hssp";
	    if ($Lscreen)       { print "--- hsspGetFileLoop: \t trying '$tmp'\n";}
	    if (-e $tmp) { 
		return($tmp);}}}
    $fileOutLoop=~s/\s|\n//g;	# security..
    return($fileOutLoop);
}				# end of hsspGetFileLoop

#==========================================================================
sub hsspRdAli {
    local ($fileInLoc,@want) = @_ ;
    local ($sbrName,$fhinLoc,$tmp,%rdLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspRdAli                   reads and writes the sequence of HSSP + 70 alis
#       in:                     $fileHssp (must exist), 
#         @des                  a) =1, 2, ...,  i.e. number of sequence to be read
#                               b) = swiss_id1, swiss_id2, i.e. identifiers to read
#                               c) = all (or undefined)
#       out:                    $rd{"swiss_id","ct"}="X"
#                                   where ct is the HSSP number (SeqNo)
#                                   X the sequence of 'swiss_id'
#                                   " " empty if not aligned
#                               $rd{"SWISS"}="swiss_id1,swiss_id2"
#                                   i.e. list of all proteins read
#                               $rd{"NRES"} = number or residues
#-------------------------------------------------------------------------------
    $sbrName="hsspRdAli";$fhinLoc="FHIN"."$sbrName";$fhinLoc=~tr/[a-z]/[A-Z]/;
				# file existing?
    if ((! -e $fileInLoc)||(! &is_hssp($fileInLoc))){
	print "*** ERROR $sbrName no HSSP file '$fileInLoc'\n";
	return(0);}
				# ------------------------------
				# HSSP file format settings
    $regexpBegAli=        "^\#\# ALIGNMENTS"; # begin of reading
    $regexpEndAli=        "^\#\# SEQUENCE PROFILE"; # end of reading
    $regexpSkip=          "^ SeqNo"; # skip lines with pattern
    $nmaxBlocks=          100;	# maximal number of blocks considered (=7000 alis!)
    $regexpBegIns=        "^\#\# INSERTION LIST"; # begin of reading insertion list
    $regexpEndIns=        "^\#\#"; # end of reading insertion list

    undef %rdLoc;
    undef @seqNo;
    undef %seqNo;
				# ------------------------------
				# digest input
    if ((! defined $want[1])||($want[1] eq "all")){
	$LreadAll=1;}
    else {
	$LreadAll=0;$#wantNum=$#wantId=0;
	foreach $want(@want){
	    if ($want !~ /[^0-9]/){push(@wantNum,$want);} # is number
	    else                  {push(@wantId,$want);}}}  # is id
				# ------------------------------
				# get numbers/ids to read
    ($Lok,%rdHeader)=
	&hsspRdHeader($fileInLoc,"SEQLENGTH","NR","ID"); # external lib-pp.pl
    if (! $Lok){
	print "*** ERROR $sbrName reading header of HSSP file '$fileInLoc'\n";
	return(0);}
    $rdLoc{"NRES"}=$rdHeader{"SEQLENGTH"};$rdLoc{"NRES"}=~s/\s//g;
    $#locNum=$#locId=0;		# store the translation name/number
    foreach $it (1..$rdHeader{"NROWS"}){
	$num=$rdHeader{"NR","$it"}; $id=$rdHeader{"ID","$it"};
	push(@locNum,$num);push(@locId,$id);
	$ptr{"$id"}=$num;$ptr[$num]=$id;}
    foreach $want (@wantId){	# check names found / wanted
	$Lok=0;
	foreach $loc (@locId){
	    if ($want eq $loc){$Lok=1;push(@wantNum,$ptr{"$loc"});
			       last;}}
	if (! $Lok){
	    print "-*- WARNING $sbrName wanted id '$want' not in '$fileInLoc'\n";}}
				# sort the array
    @wantNum= sort bynumber (@wantNum);
				# too many wanted
    if ($wantNum[$#wantNum]>$locNum[$#locNum]){
	$#tmp=0; 
	foreach $want (@wantNum){
	    if ($want <= $locNum[$#locNum]){push(@tmp,$want)}
	    else {print "-*- WARNING $sbrName no $want not in '$fileInLoc'\n";}}
	@wantNum=@tmp;}
		
    if ($LreadAll){@wantNum=@locNum;}
    if ($#wantNum==0){
	print "*** ERROR $sbrName nothing to read ???\n";
	return(0);}
				# sort the array
    @wantNum= sort bynumber (@wantNum);
				# get blocks to take
    $wantLast=$wantNum[$#wantNum];$#wantBlock=0;
    foreach $ctBlock (1..$nmaxBlocks){
	$beg=1+($ctBlock-1)*70;$end=$ctBlock*70;
	if ($wantLast<$beg){
	    last;}
	$Ltake=0;
	foreach $num(@wantNum){
	    if ( ($beg<=$num)&&($num<=$end) ){$Ltake=1;
					      last;}}
	if ($Ltake){$wantBlock[$ctBlock]=1;}else{$wantBlock[$ctBlock]=0;}}
				# writes ids read
    $rdLoc{"SWISS"}="";
    foreach $num (@wantNum){$rdLoc{"SWISS"}.="$ptr[$num]".",";}

				# --------------------------------------------------
				# read the file finally
    $Lok=&open_file("$fhinLoc","$fileInLoc");
    if (! $Lok){print "*** ERROR $sbrName opening hssp file '$fileInLoc'\n";
		return(0);}
				# move until first alis
    $ctBlock=$Lread=$#takeTmp=0;
    while (<$fhinLoc>){ 
	last if (/$regexpEndAli/); # ending
	if (/$regexpBegAli/){ # this block to take?
	    ++$ctBlock;$Lread=0;
	    if ($wantBlock[$ctBlock]){
		$_=~s/^[^0-9]+(\d+) -\s+(\d+).*$//;
		$beg=$1;$end=$2;$Lread=1;
		$#wantTmp=0;	# local numbers
		foreach $num(@wantNum){
		    if ( ($beg<=$num)&&($num<=$end) ){
			$tmp=($num-$beg)+1; 
			if ($tmp<1){
			    print "*** $sbrName negative number $tmp,$beg,$end,\n" x 3;}
			push(@wantTmp,$tmp);}}
		next;}}
	if (! $Lread){		# move on
	    next;}
	if (/$regexpSkip/){	# skip line
	    next;}
	$line=$_;
	if (length($line)<52){	# no alis in line
	    $seqNo=substr($line,1,6);$seqNo=~s/\s//g;
	    if (! defined $seqNo{$seqNo}){
		$seqNo{$seqNo}=1;push(@seqNo,$seqNo);}
	    if (! defined $rdLoc{"seq","$seqNo"}){
		($seqNo,$pdbNo,$rdLoc{"chn","$seqNo"},
		 $rdLoc{"seq","$seqNo"},$rdLoc{"sec","$seqNo"},$rdLoc{"acc","$seqNo"})=
		     &hsspRdSeqSecAccOneLine($line);}
	    foreach $num(@wantTmp){$pos=$num+$beg-1; $id=$ptr[$pos];
				   $rdLoc{"$id","$seqNo"}=" ";}
	    next;}

				# ------------------------------
				# everything fine, so read !
				# first the HSSP stuff
	$seqNo=substr($line,1,6);$seqNo=~s/\s//g;
	if (! defined $seqNo{$seqNo}){
	    $seqNo{$seqNo}=1;push(@seqNo,$seqNo);}
	if (! defined $rdLoc{"seq","$seqNo"}){
	    ($seqNo,$pdbNo,$rdLoc{"chn","$seqNo"},
	     $rdLoc{"seq","$seqNo"},$rdLoc{"sec","$seqNo"},$rdLoc{"acc","$seqNo"})=
		 &hsspRdSeqSecAccOneLine($line);}
				# now the alignments
	$alis=substr($line,52);$alis=~s/\n//g;
	foreach $num(@wantTmp){$pos=$num+$beg-1; $id=$ptr[$pos];
			       $rdLoc{"no","$id"}=$pos;$takeTmp[$pos]=1;
			       if ($pos<1){
				   print "*** $sbrName neg number $pos,$beg,$num,\n" x 3;}
			       if (! defined $rdLoc{"seq","$id"}){
				   $rdLoc{"seq","$id"}="";}
			       if (length($alis)<$num){
				   $rdLoc{"seq","$id"}.=" ";
				   $rdLoc{"$id","$seqNo"}=" ";}
			       else {
				   $rdLoc{"seq","$id"}.=substr($alis,$num,1);
				   $rdLoc{"$id","$seqNo"}=substr($alis,$num,1);}}}
    while (<$fhinLoc>){ last if (/$regexpBegIns/); } # begin reading insertion list
    while (<$fhinLoc>){ last if (/$regexpEndIns/); # ending
			next if (! /^\s*\d+/);
			$_=~s/\n//g;$tmp=$_;$tmp=~s/^\s*(\d+).*$/$1/;
			if ($takeTmp[$tmp]){
			    $_=~s/^\s*|\s*$//g;
			    @tmp=split(/\s+/,$_);$id=$ptr[$tmp];
			    $rdLoc{"$id","$tmp[2]"}=substr($tmp[5],1,(length($tmp[5])-1));}}
    close($fhinLoc);
    $rdLoc{"SWISS"}=~s/^,|,$//g;
    @idLoc=split(/,/,$rdLoc{"SWISS"});
				# fill up insertions
    foreach $id (@idLoc){$seq="";
			 foreach $seqNo(@seqNo){$seq.=$rdLoc{"$id","$seqNo"};}
			 $rdLoc{"seqAli","$id"}=$seq;
			 $seq=~s/\.|\s//g;$seq=~tr/[a-z]/[A-Z]/;
			 $rdLoc{"seq","$id"}=$seq;
			 $seqNo=$rdLoc{"no","$id"};
			 $rdLoc{"$seqNo"}=$id;}
    $seq="";foreach $seqNo(@seqNo){$seq.=$rdLoc{"seq","$seqNo"};}$rdLoc{"seqAli","0"}=$seq;
    return(1,%rdLoc);
}				# end of hsspRdAli

#==========================================================================================
sub hsspRdHeader {
    local ($fileInLoc,@kwdInLoc) = @_ ;
    local ($sbrName,$fhinLoc,$tmp,
	   @kwdDefHsspTopLoc,@kwdDefHsspHdrLoc,@kwdHsspTopLoc,@kwdHsspHdrLoc,@tmp,
	   $regexpBegHeader,$regexpEndHeader,$regexpLongId,$lenStrid,$LisLongId,
	   %ptr,$kwd,$Lok,$Lpdb,$des,$beg,$end,$mid,$ct,$id,$strid,$ptr,$tmp,%rdLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspRdHeader                reads a HSSP header
#       in:                     $fileHssp (must exist), 
#         @kwdInLoc             = one of the default keywords 
#                               (@kwdLocHsspTop,@kwdLocHsspHeader)
#       out:                    for top  (e.g. NALIGN): $rd{"kwd"}
#                               for prot (e.g. LALI):   $rd{"kwd","$it"}
#                               note: for the later number of elements (it) in
#                                     $rd{"NROWS"}
#         special               ID=ID1, $rd{"kwd","$it"} existes for ID1 and ID2
#-------------------------------------------------------------------------------
    $sbrName="hsspRdHeader";$fhinLoc="FHIN"."$sbrName";$fhinLoc=~tr/[a-z]/[A-Z]/;
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
    $#kwdHsspTopLoc=$#kwdHsspHdrLoc=$Lpdb=0;
    foreach $kwd (@kwdInLoc){
	$Lok=0;
	if ((!$Lpdb)&&($kwd =~/^PDBID/)){
	    $Lpdb=1;}
	foreach $des (@kwdDefHsspTopLoc)   {
	    if ($kwd eq $des){ $Lok=1; push(@kwdHsspTopLoc,$kwd);
			       last;}}
	if ($Lok){ next;}
	foreach $des (@kwdDefHsspHdrLoc){
	    if ($kwd eq $des){ $Lok=1; push(@kwdHsspHdrLoc,$kwd);
			       last;} }
	if (! $Lok){print "-*- WARNING $sbrName input kwd=$kwd, makes no sense??\n";}}

    if (! $Lpdb){		# force reading of NALI
	push(@kwdHsspTopLoc,"PDBID");}
				# get column numbers to read
				# ------------------------------
				# now start to read
    $Lok=&open_file("$fhinLoc","$fileInLoc");
    if (! $Lok){print "*** ERROR $sbrName HSSP file couldn't be opened '$fileInLoc'\n";
		return(0);}
    undef %rdLoc;		# save space
				# ------------------------------
				# read top
    while ( <$fhinLoc> ) {
	last if (/$regexpBegHeader/); 
	if (/$regexpLongId/) {$LisLongId=1;}
	else{$_=~s/\n//g;
	     foreach $des (@kwdHsspTopLoc){
		 if (/^$des\s+(.+)$/){
		     if (defined $ok{"$des"}){ # multiple lines!
			 $tmp="$1"."\t";
			 if  (defined $rdLoc{"$des"}){
			     $rdLoc{"$des"}.=$tmp;}
			 else{$rdLoc{"$des"}=$tmp;}}
		     else {$ok{"$des"}=1;$rdLoc{"$des"}=$1;}
		     if ($des=~/SEQLENGTH|NCHAIN|KCHAIN|NALIGN/){
			 $rdLoc{"$des"}=~s/^(\d+)[^0-9]+.*$/$1/;} # purge blanks
		     last;}}}}
				# ------------------------------
    $ct=0;			# read header
    while ( <$fhinLoc> ) { 
	last if (/$regexpEndHeader/); 
	if (/^  NR\./){		# skip descriptors
	    next;}
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

	$rdLoc{"ID","$ct"}=$id;
	$rdLoc{"NR","$ct"}=$ct;
	$rdLoc{"STRID","$ct"}=$strid;
	$rdLoc{"PROTEIN","$ct"}=$end;
	$rdLoc{"ID1","$ct"}=$rdLoc{"PDBID"};
	$rdLoc{"ACCNUM","$ct"}=$accnum;
				# middle all info
	$#tmp=0;@tmp=split(/\s+/,$mid);
	foreach $_ (@tmp) {$_=~s/\s//g;}

	foreach $des (@kwdHsspHdrLoc){ 
	    next if ( ! defined $ptr{"$des"});
	    next if ( $des =~/^ACCNUM/);
	    $ptr=$ptr{"$des"};
	    $rdLoc{"$des","$ct"}=$tmp[$ptr]; }}close($fhinLoc);
    $rdLoc{"NROWS"}=$ct;
				# clean up
    undef @kwdInLoc; undef @kwdDefHsspHdrLoc; undef @kwdHsspTopLoc;
    undef @kwdDefHsspTopLoc; undef @kwdHsspHdrLoc; undef @tmp; undef %ptr;

    return(1,%rdLoc);
}				# end of hsspRdHeader

#===============================================================================
sub hsspRdProfile {
    local($fileInLoc,$ifirLoc,$ilasLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$line,$chainLoc,$seqNo,$pdbNo,
	  %rdLoc,$chainRd,$ifirRd,$ilasRd);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   hsspRdProfile               reads the HSSP profile from ifir to ilas
#       in:                     file.hssp_C ifir ilas (* for all numbers)
#       out:                    %prof{"kwd","it"}
#                   @kwd=       ("seqNo","pdbNo","V","L","I","M","F","W","Y","G","A","P",
#				 "S","T","C","H","R","K","Q","E","N","D",
#				 "NOCC","NDEL","NINS","ENTROPY","RELENT","WEIGHT");
#-------------------------------------------------------------------------------
    $sbrName="hsspRdProfile";$fhinLoc="FHIN"."$sbrName";$fhinLoc=~tr/[a-z]/[A-Z]/;

    $chainLoc=0;
#    if ($fileInLoc =~/\.hssp.*_(.)/){
#	$chainLoc=$fileInLoc;$chainLoc=~s/^.+.hssp.*_(.)$/$1/;
#	$fileInLoc=~s/^(.+.hssp.*)_(.)$/$1/;}else{$chainLoc=0;}
    if (! -e $fileInLoc){
	print "*** $sbrName: HSSP file '$fileInLoc' missing\n";
	return(0);}
    if ((! defined $ifirLoc)||($ifirLoc eq "*")){$ifirLoc=0;}
    if ((! defined $ilasLoc)||($ifirLoc eq "*")){$ifirLoc=0;}
				# read profile
    $Lok=&open_file("$fhinLoc","$fileInLoc");
    if ($Lok){
	while (<$fhinLoc>) {last if /^\#\# SEQUENCE PROFILE AND ENTROPY/;}
	$name=<$fhinLoc>;
	$name=~s/\n//g;$name=~s/^\s+|\s+$//g; # trailing blanks
	($seqNo,$pdbNo,@name)=split(/\s+/,$name);
	$ct=0;
	while (<$fhinLoc>) {$line=$_; $line=~s/\n//g;
			    last if (/^\#\#/);
			    if (length($line)<13){
				next;}
			    $seqNo=  substr($line,1,5);$seqNo=~s/\s//g;
			    $pdbNo=  substr($line,6,5);$pdbNo=~s/\s//g;
			    $chainRd=substr($line,12,1); # grep out chain identifier
			    if ( $chainLoc && ($chainRd ne $chainLoc)){
				next;}
			    if ( $ifirLoc && ($seqNo < $ifirLoc)){
				next;}
			    if ( $ilasLoc && ($seqNo > $ilasLoc)){
				next;}
			    $line=substr($line,13,length($line)-13);
			    $line=~s/^\s+|\s+$//g; # trailing blanks
			    @tmp=split(/\s+/,$line);
			    ++$ct;
			    $rdLoc{"seqNo","$ct"}=$seqNo;
			    $rdLoc{"pdbNo","$ct"}=$pdbNo;
			    foreach $it (1..$#name){
				$rdLoc{"$name[$it]","$ct"}=$tmp[$it];
			    }
			    $rdLoc{"NROWS"}=$ct;
			}
	close($fhinLoc);}
    else {
	print "*** ERROR $sbrName couldn't open HSSP '$fileInLoc'\n";
	return(0);}
    return(1,%rdLoc);
}				# end of hsspRdProfile

#==========================================================================
sub hsspRdSeqSecAcc {
    local($fileInLoc,$ifirLoc,$ilasLoc,$chain) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$line,$chainLoc,$seqNo,$pdbNo,
	  %rdLoc,$chainRd,$ifirRd,$ilasRd);
    $[=1;
#----------------------------------------------------------------------
#   hsspRdSeqSecAcc             reads the HSSP seq/sec/acc from ifir to ilas
#       in:                     file.hssp_C ifir ilas (* for all numbers)
#       out:                    %rdLoc{"kwd","it"}
#                 @kwd=         ("seqNo","pdbNo","seq","sec","acc")
#----------------------------------------------------------------------
    $sbrName="hsspRdSeqSecAcc";$fhinLoc="FHIN"."$sbrName";$fhinLoc=~tr/[a-z]/[A-Z]/;
				# file existing?
    $chainLoc=0;
#    if ($fileInLoc =~/\.hssp.*_(.)/){
#	$chainLoc=$fileInLoc;$chainLoc=~s/^.+.hssp.*_(.)$/$1/;
#	$fileInLoc=~s/^(.+.hssp.*)_(.)$/$1/;}}
    if (! -e $fileInLoc){
	print "*** $sbrName: HSSP file '$fileInLoc' missing\n";
	return(0);}
    if ((! defined $ifirLoc)||($ifirLoc eq "*")){$ifirLoc=0;}
    if ((! defined $ilasLoc)||($ifirLoc eq "*")){$ifirLoc=0;}
				# ------------------------------
				# read seq/sec/acc
    $Lok=&open_file("$fhinLoc","$fileInLoc");
    if (! $Lok){
	print "*** ERROR $sbrName couldn't open HSSP '$fileInLoc'\n";
	return(0);}

    while (<$fhinLoc>) {last if ( /^\#\# ALIGNMENTS/ ); }
    $tmp=<$fhinLoc>;
    $ct=0;
    while (<$fhinLoc>) {$line=$_; $line=~s/\n//g;
			last if ( /^\#\# / ) ;
			$seqNo=  substr($line,1,6);$seqNo=~s/\s//g;
			$pdbNo=  substr($line,7,6);$pdbNo=~s/\s//g;
			$chainRd=substr($line,13,1); # grep out chain identifier
			if ( $chainLoc && ($chainRd ne $chainLoc)){
			    next;}
			if ( $ifirLoc && ($seqNo < $ifirLoc)){
			    next;}
			if ( $ilasLoc && ($seqNo > $ilasLoc)){
			    next;}
			++$ct;$rdLoc{"NROWS"}=$ct;
			$rdLoc{"seq","$ct"}=substr($_,15,1);
			$rdLoc{"sec","$ct"}=substr($_,18,1);
			$rdLoc{"acc","$ct"}=substr($_,37,3);$rdLoc{"acc","$ct"}=~s/\s//g;
			$rdLoc{"seqNo","$ct"}=$seqNo;
			$rdLoc{"pdbNo","$ct"}=$pdbNo;}close($fhinLoc);
    return(1,%rdLoc);
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
sub hsspRdStripAndHeader {
    local($fileInHsspLoc,$fileInStripLoc,$fhErrSbr,@kwdInLocRd) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok,$LhsspTop,$LhsspPair,$LstripTop,$LstripPair,$kwd,$kwdRd,
	  @sbrKwdHsspTop,    @sbrKwdHsspPair,    @sbrKwdStripTop,     @sbrKwdStripPair, 
	  @sbrKwdHsspTopDo,  @sbrKwdHsspPairDo,  @sbrKwdStripTopDo,   @sbrKwdStripPairDo,
	  @sbrKwdHsspTopWant,@sbrKwdHsspPairWant,@sbrKwdStripTopWant, @sbrKwdStripPairWant,
	  %translateKwdLoc,%rdHsspLoc,%rdStripLoc,%rdLoc);
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
    $sbrName="lib-prot:hsspRdStripAndHeader";$fhinLoc="FHIN"."$sbrName";
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

    undef %rdLoc; undef %rdHsspLoc; undef %rdStripLoc; # save space
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
    $rdLoc{"NROWS"}=$rdHsspLoc{"NROWS"}; 
				# --------------------
				# hssp info guide (top)
    foreach $kwd (@sbrKwdHsspTopWant){
	$kwdRd=$translateKwdLoc{"$kwd"};
	if (! defined $rdHsspLoc{"$kwdRd"}){
	    print $fhErrSbr "-*- WARNING ($sbrName) rdHsspLoc-Top not def for $kwd->$kwdRd\n";}
	else {
	    $rdLoc{"$kwd"}=$rdHsspLoc{"$kwdRd"};}}
				# --------------------
				# hssp info pairs
    foreach $it (1..$rdHsspLoc{"NROWS"}){
	$rdLoc{"id1","$it"}= $rdLoc{"pdbid1"}; # add identifier for each pair
	$rdLoc{"len1","$it"}=$rdLoc{"len1"}; # add identifier for each pair
	foreach $kwd (@sbrKwdHsspPairWant){
	    $kwdRd=$translateKwdLoc{"$kwd"};
	    if (! defined $rdHsspLoc{"$kwdRd","$it"}){
		print $fhErrSbr "-*- WARNING ($sbrName) HsspLoc not for $kwd->$kwdRd ($it)\n";}
	    else {
		$rdLoc{"$kwd","$it"}=$rdHsspLoc{"$kwdRd","$it"};}}}
				# --------------------
				# strip pairs
    foreach $kwd (@sbrKwdStripPairWant){
	$kwdRd=$translateKwdLoc{"$kwd"};
	foreach $it (1..$rdStripLoc{"NROWS"}){
	    if (! defined $rdStripLoc{"$kwdRd","$it"}){
		print $fhErrSbr "-*- WARNING ($sbrName) StripLoc not for $kwd->$kwdRd ($it)\n";}
	    else {
		$rdLoc{"$kwd","$it"}=$rdStripLoc{"$kwdRd","$it"};}}}
				# --------------------
				# purge blanks
    foreach $kwd (@sbrKwdHsspPairWant,@sbrKwdStripPairWant){
	next if ($kwd =~/^name$|^protein/);
	foreach $it (1..$rdLoc{"NROWS"}){
	    $rdLoc{"$kwd","$it"}=~s/\s//g;}}
				# correction for 'pide','wsim'
    foreach $it (1..$rdHsspLoc{"NROWS"}){
	$rdLoc{"pide","$it"}*=100   if (defined $rdLoc{"pide","$it"});
	$rdLoc{"wsim","$it"}*=100   if (defined $rdLoc{"wsim","$it"});
	$rdLoc{"strh","$it"}*=100   if (defined $rdLoc{"strh","$it"});
	$rdLoc{"id1","$it"}=~s/_//g if (defined $rdLoc{"id1","$it"});
	$rdLoc{"id2","$it"}=~s/_//g if (defined $rdLoc{"id2","$it"});
    }
				# --------------------
    undef @kwdInLocRd;		# save space!
    undef @sbrKwdHsspTop;     undef @sbrKwdHsspPair;     undef @sbrKwdStripPair; 
    undef @sbrKwdHsspTopDo;   undef @sbrKwdHsspPairDo;   undef @sbrKwdStripPairDo; 
    undef @sbrKwdHsspTopWant; undef @sbrKwdHsspPairWant; undef @sbrKwdStripPairWant; 
    undef %rdHsspLoc; undef %rdStripLoc; undef %translateKwdLoc; 
    return(1,"ok $sbrName",%rdLoc);
}				# end of hsspRdStripAndHeader

#==========================================================================================
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
    $sbrName="lib-prot:hsspRdStripHeader";$fhinLoc="FHIN"."$sbrName";
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
    undef %rdLoc;		# save space
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
	    $rdLoc{"$kwdRd"}=$info;
				# add short names for header
	    if (defined $addDes{"$kwdRd"}){
		$kwdRdAdd=$addDes{"$kwdRd"};
		$rdLoc{"$kwdRdAdd"}=$info;}
	    next;}}
    $nalign=$rdLoc{"alignments"};
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

	$rdLoc{"LEN1","$ct"}=$len1;
	foreach $kwd (@kwdStripHdrLoc){
	    $pos=$ptr{"$kwd"};
	    if (($pos>$#tmp)||($pos<1)){
		print "*** ERROR in $sbrName ct=$ct, kwd=$kwd, pos should be $pos\n";
		print "***          however \@tmp not defined for that\n";
		return(0);}
	    if ($kwd eq "IDE"){$tmp=100*$tmp[$pos];}else{$tmp=$tmp[$pos];}
	    $rdLoc{"$kwd","$ct"}=$tmp;}
    } close($fhinLoc);
    $rdLoc{"NROWS"}=$ct;
				# clean up
    undef @kwdInLoc;undef @kwdDefStripTopLoc;undef @kwdDefStripHdrLoc;undef %ptr; 
    undef @kwdStripTopLoc; undef @kwdStripHdrLoc; undef %LtakeLoc;
    
    return (%rdLoc);
}				# end of hsspRdStripHeader

#======================================================================
sub identify_current_user { 
    local ($arch)=@_;
#----------------------------------------------------------------------
#   identify_current_user       gets a user name (by 'whoami')
#       in:                     $arch
#       out:                    user_name
#----------------------------------------------------------------------
    if ($arch !=/sparc-sun-solaris2/) {
	system("whoami >> id.tmp"); }
    else {
	system("who am i >> id.tmp"); }

    &open_file("TMP", "id.tmp");
    while ( <TMP> ) {
	$identify_current_user = $_; $identify_current_user =~ s/\s|\n//g;
    } close(TMP); 
    system("rm -f id.tmp");
    return($identify_current_user);
}				# end of identify_current_user

#==========================================================================================
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
					if ($tmp !~ /[ABCDEFGHIKLMNPQRSTVWXYZ\.\- ]/){
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
	foreach $it (1..$#SEQ){push(@NUM,$it);}	# convert to global
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

#==========================================================================================
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

#==========================================================================================
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
    $LfirstLine=0;		# hack 2-98: add first line 'MSF of: xx from: 1 to: 600'
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

#==========================================================================================
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

#==========================================================================================
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
#       out:                    write alignment in SAF format
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
	$seq=~s/[^ABCDEFGHIKLMNPQRSTVWXYZ]//g;
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

#==========================================================================================
sub is_dssp {
    local ($fileInLoc) = @_ ;
    local ($fh,$Lis);
#--------------------------------------------------------------------------------
#   is_dssp                     checks whether or not file is in DSSP format
#       in:                     $file
#       out:                    1 if is dssp; 0 else
#--------------------------------------------------------------------------------
    if (! -e $fileInLoc) {
	return (0);}
    $fh="FHIN_CHECK_DSSP";&open_file("$fh","$fileInLoc");
    while ( <$fh> ) {
	if (/SECONDARY STRUCTURE DEFINITION BY THE PROGRAM DSSP/){$Lis=1;}else{$Lis=0;}
	last; }close($fh);
    return $Lis;
}				# end of is_dssp

#==========================================================================================
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

#==========================================================================================
sub is_hssp {
    local ($fileInLoc) = @_ ;local ($fh,$Lis);
#--------------------------------------------------------------------------------
#   is_hssp                     checks whether or not file is in HSSP format
#       in:                     $file
#       out:                    1 if is hssp; 0 else
#--------------------------------------------------------------------------------
    if (! -e $fileInLoc) {
	return (0);}
    $fh="FHIN_CHECK_HSSP";&open_file("$fh", "$fileInLoc");
    while ( <$fh> ) {if (/^HSSP/) {$Lis=1;}else{$Lis=0;}last; }close($fh);
    return $Lis;
}				# end of is_hssp

#==========================================================================================
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
	if (/^NALIGN\s+(\d+)/){
	    if ($1 eq "0"){
		close($fh); return(1);}
	    last; }}close($fh); 
    return 0;
}				# end of is_hssp_empty

#==========================================================================================
sub is_hssp_list {
    local ($fileInLoc) = @_ ;local ($fh,$Lis,$fileRd,$fileLoc,$chainLoc,$LscreenLoc);
#--------------------------------------------------------------------------------
#   is_hssp_list                checks whether or not file contains a list of HSSP files
#       in:                     $file
#       out:                    1 if is list; 0 else
#--------------------------------------------------------------------------------
    $LscreenLoc=0;
    if (! -e $fileInLoc) {
	return (0);}
    $fh="FHIN_CHECK_HSSP_LIST";&open_file("$fh", "$fileInLoc");
    while ( <$fh> ) {$fileRd=$_;$fileRd=~s/\s|\n//g;
		     if (length($fileRd)<5){
			 next;}
		     ($fileLoc,$chainLoc)=&hsspGetFile($fileRd,$LscreenLoc);
		     if (&is_hssp($fileLoc)){$Lis=1;}else { $Lis=0;}
		     last; } close($fh);
    return $Lis;
}				# end of is_hssp_list

#==========================================================================================
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

#==========================================================================================
sub is_strip_list {
    local ($fileInLoc) = @_ ;local ($fh,$Lis,$fileRd,$fileLoc,$chainLoc,$LscreenLoc);
#--------------------------------------------------------------------------------
#    is_strip_list              checks whether or not file contains a list of HSSPstrip files
#       in:                     $file
#       out:                    1 if is strip; 0 else
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

#==========================================================================================
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

#==========================================================================================
sub is_swissprot {return(&isSwiss(@_));}

#==========================================================================================
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
    $sbrName="lib-pp.pl:"."isDafGeneral";$fhinLoc="FHIN"."$sbrName";
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

#==========================================================================================
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
    $sbrName="lib-pp.pl:"."isDsspGeneral";$fhinLoc="FHIN"."$sbrName";
				# ------------------------------
    if (&is_dssp($fileInLoc))    { # file is dssp
	return(1,"isDssp",$fileInLoc); } 
				# ------------------------------
    elsif (&is_dssp_list($fileInLoc)) { # file is dssp list
	$Lok=&open_file("$fhinLoc","$fileInLoc");$#tmp=0;
	if (! $Lok){print "*** ERROR $sbrName input file=$fileInLoc, not opened\n";
		    return(0,"not open",$fileInLoc);}
	undef @tmpFile; undef @tmpChain;
	while (<$fhinLoc>) {$_=~s/\n//g;
			    next if (length($_)==0);
			    $tmp=$_; 
			    if    ((-e $tmp) && &is_dssp($tmp))       { 
				push(@tmpFile,$tmp);
				push(@tmpChain," ");}
			    else {		# search for valid DSSP file
				($file,$chain)=&dsspGetFile($tmp,@dirLoc);
				if    ((-e $file) && &is_dssp($file)) { 
				    push(@tmpFile,$file);
				    push(@tmpChain,$chain);}
				next;}}close($fhinLoc);
	if ($#tmpFile==0){return(0,"none in list",$fileInLoc);}
	else             {return(1,"isDsspList",@tmpFile,"chain",@tmpChain);}}
				# ------------------------------
    else {			# search for DSSP
	($file,$chain)=&dsspGetFile($fileInLoc,@dirLoc);
	if    ((-e $file) && &is_dssp($file)){ 
	    return(1,"isDssp",$file,$chain); }
	else {
	    return(0,"not dssp",$fileInLoc); }}
}				# end of isDsspGeneral

#==========================================================================================
sub isFasta {
    local ($fileLoc) = @_ ; local ($Lok);
#--------------------------------------------------------------------------------
#   isFasta                     checks whether or not file is in FASTA format 
#                               (first line /^>\w/, second (non white) = AA
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
    &open_file("FHIN_FASTA","$fileLoc");
    $one=(<FHIN_FASTA>);
    $two=(<FHIN_FASTA>);$two=~s/\s//g;close(FHIN_FASTA);
    if (($one =~ /^\>\w+/) && ($two !~/[^ABCDEFGHIKLMNPQRSTVWXYZ\.~_]/)){
	return(1);}
    else {return(0);}
}				# end of isFasta

#==========================================================================================
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
    return (0) if (($one !~ /^\>\w+/) || ($two =/[^ABCDEFGHIKLMNPQRSTVWXYZ\.~_]/));
    $Lok=0;
    while(<FHIN_FASTA>){
	if ($_=~/^\>\w+/){$Lok=1;
			  last;}}close(FHIN_FASTA);
    return($Lok);
}				# end of isFastaMul

#===============================================================================
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
    $sbrName="lib-pp.pl:"."isHsspGeneral";$fhinLoc="FHIN"."$sbrName";
				# ------------------------------
    if (! -e $fileInLoc){	# search for HSSP
	($file,$chain)=&hsspGetFile($fileInLoc,@dirLoc);
	if    ((-e $file) && &is_hssp($file))        { 
	    return(1,"isHssp",$file,$chain); } 
	elsif ((-e $file) && &is_hssp_empty($file))  { 
	    return(0,"empty",$file); }
	else {
	    return(0,"not hssp",$fileInLoc); }}
				# ------------------------------
    if (&is_hssp($fileInLoc)){	# file is hssp
	if (&is_hssp_empty($fileInLoc)) {
	    return(0,"empty hssp",$fileInLoc);}
	return(1,"isHssp",$fileInLoc); } 
				# ------------------------------
    elsif (&is_hssp_list($fileInLoc)) { # file is hssp list
	$Lok=&open_file("$fhinLoc","$fileInLoc");$#tmp=0;
	if (! $Lok){print "*** ERROR $sbrName input file=$fileInLoc, not opened\n";
		    return(0,"not open",$fileInLoc);}
	undef @tmpFile; undef @tmpChain;
	while (<$fhinLoc>) {$_=~s/\n//g;
			    next if (length($_)==0);
			    $tmp=$tmp2=$_;
			    if    ((-e $tmp) && &is_hssp($tmp2))        { 
				push(@tmpFile,$tmp);
				push(@tmpChain," ");}
			    elsif ((-e $tmp) && &is_hssp_empty($tmp2))  { 
				next;}
			    else {		# search for valid HSSP file
				($file,$chain)=&hsspGetFile($tmp,@dirLoc);
				if    ((-e $file) && &is_hssp($file))        { 
				    push(@tmpFile,$file);
				    push(@tmpChain,$chain);}
				elsif ((-e $file) && &is_hssp_empty($file))  { 
				    next;}
				next;}}close($fhinLoc);
	if ($#tmpFile==0){return(0,"none in list",$fileInLoc);}
	else             {return(1,"isHsspList",@tmpFile,"chain",@tmpChain);}}
    
				# ------------------------------
    else {			# search for HSSP
	($file,$chain)=&hsspGetFile($fileInLoc,@dirLoc);
	if    ((-e $file) && &is_hssp($file))        { 
	    return(1,"isHssp",$file,$chain); } 
	elsif ((-e $file) && &is_hssp_empty($file))  { 
	    return(0,"empty",$file); }
	else {
	    return(0,"not hssp",$fileInLoc); }}
}				# end of isHsspGeneral

#==========================================================================================
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
    $sbrName="lib-pp.pl:"."isMsfGeneral";$fhinLoc="FHIN"."$sbrName";
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

#==========================================================================================
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

#==========================================================================================
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

#==========================================================================================
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

#==========================================================================================
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

#==========================================================================================
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
    if ($one =~ /^\>P1\;/i){
	return(1);}
    else {return(0);}
}				# end of isPir

#==========================================================================================
sub isPirMul {
    local ($fileLoc) = @_ ; local ($Lok);
#--------------------------------------------------------------------------------
#   isPirMul                    checks whether or not file contains many sequences 
#                               in PIR format 
#                               more than once: first line /^>P1\;/
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
    &open_file("FHIN_PIR","$fileLoc");
    $ct=0;
    while(<FHIN_PIR>){
	if ($_=~/^\>P1\;/i){++$ct;}
	last if ($ct>1);}close(FHIN_PIR);
    if ($ct>1){
	return(1);}
    else {return(0);}
}				# end of isPirMul

#==========================================================================================
sub isRdb {local ($fileInLoc) = @_ ;local ($fh,$Lis);
#--------------------------------------------------------------------------------
#   isRdb                       checks whether or not file is in RDB format
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
	   if (! -e $fileInLoc) {
	       return (0);}$fh="FHIN_CHECK_RDB";
	   $Lok=&open_file("$fh", "$fileInLoc"); 
	   if (! $Lok){ print "*** ERROR in lib-pp.pl:isRdb, while opening '$fileInLoc'\n";
			return(0);}
	   while ( <$fh> ) {if (/^\# Perl-RDB/) {$Lis=1;}else{$Lis=0;}
			    last; }close($fh);
	   return $Lis; }	# end of isRdb

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
    $sbrName="lib-pp.pl:"."isRdbGeneral";$fhinLoc="FHIN"."$sbrName";
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

#==========================================================================================
sub isRdbList {local ($fileInLoc) = @_ ; local ($Lok,$fhinLoc,$fileTmp);
#--------------------------------------------------------------------------------
#   isRdbList                   checks whether or not file is list of Rdb files
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
	       if (! -e $fileInLoc) {
		   return (0);}$fhinLoc="FHIN_RDBLIST";$Lok=0;
	       $Lok=&open_file("$fhinLoc","$fileInLoc");
	       if (! $Lok){ print "*** ERROR in lib-pp.pl:isRdbList, opening '$fileInLoc'\n";
			    return(0);}
	       while (<$fhinLoc>){ $fileTmp=$_;$fileTmp=~s/\n|\s//g;
				   if (&isRdb($fileTmp)&&(-e $fileTmp)){$Lok=1;}
				   last;}close($fhinLoc);
	       return($Lok); }	# end of isRdbList

#===============================================================================
sub isRunning{
    local ($process,$ps_cmd,$fhLoc) = @_;
    local ($sbrName,$ctJobs,@result);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   isRunning                   test if a program runs (returns nr of occ found)
#       in:                     $process,$ps_cmd,$fhLoc
#       out:                    number of jobs running
#-------------------------------------------------------------------------------
    $sbrName="isRunning";
    return(0,"*** $sbrName: no process given!")    if (! defined $process);
    return(0,"*** $sbrName: no ps_comand given!")  if (! defined $ps_cmd) ;
				# remove path
    $process=~ s/^.*\///;	# 
    if (defined $fhLoc){
	print $fhLoc "ps=$ps_cmd "."|"." grep $process "."|"." grep -v 'grep'\n";}
				# run a ps command
    @result= `$ps_cmd | grep $process | grep -v 'grep' `;
#    @result= `$ps_cmd | grep $process | grep -v 'grep' | grep -v '$process\.\.'`;

    $ctJobs=$#result;
    print "lib-pp:$sbrName: #result=$ctJobs (xx)\n";

    return (1,$ctJobs);		# return the number of processes found 
}				# end of isRunning

#==========================================================================================
sub isSwiss {local ($fileLoc) = @_ ; local ($Lok);
#--------------------------------------------------------------------------------
#    isSwiss                    checks whether or not file is in SWISS-PROT format (/^ID   /)
#       in:                     $file
#       out:                    1 if is yes; 0 else
#--------------------------------------------------------------------------------
	     &open_file("FHIN_SWISS","$fileLoc");
	     while (<FHIN_SWISS>){ if (/^ID   /){$Lok=1;}else{$Lok=0;}
				   last;}close(FHIN_SWISS);
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
    $sbrName="lib-pp.pl:"."isSwissGeneral";$fhinLoc="FHIN"."$sbrName";
				# ------------------------------
    if (&isSwiss($fileInLoc))    { # file is swiss
	return(1,"isSwiss",$fileInLoc); } 
				# ------------------------------
    elsif (&isSwissList($fileInLoc)) { # file is swiss list
	$Lok=&open_file("$fhinLoc","$fileInLoc");$#tmp=0;
	if (! $Lok){print "*** ERROR $sbrName input file=$fileInLoc, not opened\n";
		    return(0,"not open",$fileInLoc);}
	while (<$fhinLoc>) {$_=~s/\n//g;if (length($_)==0)             { 
	    next;}
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
	($file,$chain)=&swissGetFile($fileInLoc,@dirLoc);
	if    ((-e $file) && &isSwiss($file))        { 
	    return(1,"isSwiss",$file); } 
	else {
	    return(0,"not swiss",$fileInLoc); }}
}				# end of isSwissGeneral

#==========================================================================================
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

#==========================================================================
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
    $sbrName="maxhomCheckHssp";
    return(0,"error","*** $sbrName: not def file_in!")            if (! defined $file_in);
    return(0,"error","*** $sbrName: not def laliPdbMin!")         if (! defined $laliPdbMin);
    return(0,"error","*** $sbrName: miss input file '$file_in'!") if (! -e $file_in);
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

#==========================================================================
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
#         $Lprofile             NO|YES
#         $fileMaxMetric        metric
#         $paraMaxSmin          minimal value of metric (typical -0.5)
#         $paraMaxSmax          maximal value of metric (typical  1.0)
#         $paraMaxGo            gap open penalty        (typical  3.0)
#         $paraMaxGe            gap extension/elongation penalty (typ 
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
    eval "\$command=\"$niceLoc $exeMaxLoc -d=$fileDefaultLoc -nopar ,
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
         DOT_PLOT      NO ,
         RUN ,\"";
    return ($command);
}				# end maxhomGetArg

#==========================================================================
sub maxhomGetArgCheck {
    local($exeMaxLoc,$fileDefLoc,$fileMaxIn,$fileMaxList,$fileMaxMetric)=@_;
    local($msg,$warn,$pre);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   maxhomGetArg                performs some basic file-existence-checks
#                               before Maxhom arguments are built up
#       in:                     $exeMaxLoc,$fileDefLoc,$fileMaxIn,$fileMaxList,$fileMaxMetric
#       out:                    msg,warn
#--------------------------------------------------------------------------------
    $msg="";$warn="";$pre="*** maxhomGetArgCheck missing ";
    if    (! -e $exeMaxLoc)    {$msg.="$pre"."$exeMaxLoc=    for exe\n";}
    elsif (! -e $fileDefLoc)   {$msg.="$pre"."$fileDefLoc=   default file\n";}
    elsif (! -e $fileMaxIn)    {$msg.="$pre"."$fileMaxIn=    query seq\n";}
    elsif (! -e $fileMaxList)  {$msg.="$pre"."$fileMaxList=  ali DB\n";}
    elsif (! -e $fileMaxMetric){$msg.="$pre"."$fileMaxMetric=metric\n";}
    return ($msg,$warn);
}				# end maxhomGetArg

#==========================================================================
sub maxhomGetThresh4PP {
    local($LisExpert,$expertMinIde,$minIde,$minIdeRd)=@_;
    local($thresh_now,$thresh_up,$tmp,$thresh_txt);
    $[ =1 ;
#----------------------------------------------------------------------
#   maxhomGetThresh4PP          translates cut-off ide into text input for MAXHOM csh
#       note:                   special for PP, as assumptions about upper/lower
#       in:                     ($LisExpert,$expertMinIde,$minIde,$minIdeRd
#       out:                    $txt 'FORMULA+/-n'
#----------------------------------------------------------------------
    if ($LisExpert) { # upper seq ide
	$thresh_up=$expertMinIde; }
    else { 
	$thresh_up=$minIde; }
                                # value passed ('maxhom expert number')?
    if ( (defined $minIdeRd) && ($minIdeRd>=$thresh_up) ) {
	$thresh_now=$minIdeRd;}
    else { 
	$thresh_now=$thresh_up;}
				# final txt for MAXHOM cshell (FORMULA,FORMULA-n,FORMULA+n)
    if   ($thresh_now>25) {$tmp=$thresh_now-25;
			   $thresh_txt="FORMULA+"."$tmp"; }
    elsif($thresh_now<25) {$tmp=25-$thresh_now;
			   $thresh_txt="FORMULA-"."$tmp"; }
    else                  {$thresh_txt="FORMULA"; }
    return($thresh_txt);
}				# end of maxhomGetThresh4PP

#===============================================================================
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
    $sbrName="maxhomMakeLocDef";
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

#==========================================================================
sub maxhomRunLoop {
    local ($date,$niceL,$exeMaxL,$fileMaxDefL,$fileJobIdL,
	   $fileHsspInL,$fileHsspAliListL,$fileHsspOutL,$fileMaxMetricL,$dirMaxPdbL,
	   $LprofileL,$paraSminL,$paraSmaxL,$paraGoL,$paraGeL,$paraW1L,$paraW2L,
	   $paraIndel1L,$paraIndel2L,$paraNaliL,$paraThreshL,$paraSortL,$paraProfOutL,
	   $fileStripOutL,$fileFlagNoHsspL,$paraMinLaliPdbL,$paraTimeOutL,$fhTrace)=@_;
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
    return(0,"*** $sbrName: not def niceL!",0)            if (! defined $niceL);
    return(0,"*** $sbrName: not def exeMaxL!",0)          if (! defined $exeMaxL);
    return(0,"*** $sbrName: not def fileMaxDefL!",0)      if (! defined $fileMaxDefL);
    return(0,"*** $sbrName: not def fileJobIdL!",0)       if (! defined $fileJobIdL);
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
    $fhTrace="STDOUT"                                     if (! defined $fhTrace);
				# check existence of files
    return(0,"*** $sbrName: miss input file '$fileHsspInL'!",0)      if (! -e $fileHsspInL);
    return(0,"*** $sbrName: miss input exe  '$exeMaxL'!",0)          if (! -e $exeMaxL);
    return(0,"*** $sbrName: miss input file '$fileMaxDefL'!",0)      if (! -e $fileMaxDefL);
    return(0,"*** $sbrName: miss input file '$fileHsspAliListL'!",0) if (! -e $fileHsspAliListL);
    return(0,"*** $sbrName: miss input file '$fileMaxMetricL'!",0)   if (! -e $fileMaxMetricL);
    $pdbidFound="";
    $LisPdbid=$LisSelf=0;	# is PDBid in HSSP? / are homologues?

				# ------------------------------
				# set the elapse time in seconds before an alarm is sent
#    $paraTimeOutL= 10000;	# ~ 3 heures
    $msgHere="";
				# ------------------------------
				# (1) build up MaxHom input
    ($msg,$warn)=		# check existence of files asf
	&maxhomGetArgCheck($exeMaxL,$fileMaxDefL,$fileHsspInL,$fileHsspAliListL,
			   $fileMaxMetricL);
    if (length($msg)>1){
	return(0,"$msg",0);} $msgHere.="--- $sbrName $warn\n";
    
    $maxCmdL=			# get command line argument for starting MaxHom
	&maxhomGetArg($niceL,$exeMaxL,$fileMaxDefL,$fileJobIdL,$fileHsspInL,$fileHsspAliListL,
		      $LprofileL,$fileMaxMetricL,$paraSminL,$paraSmaxL,$paraGoL,$paraGeL,
		      $paraW1L,$paraW2L,$paraIndel1L,$paraIndel2L,$paraNaliL,$paraThreshL,
		      $paraSortL,$fileHsspOutL,$dirMaxPdbL,$paraProfOutL,$fileStripOutL);
				# --------------------------------------------------
				# the thing that does IT!
				# --------------------------------------------------
    while ( ! -f $fileHsspOutL ) { 
	$msgHere.="--- $sbrName \t first trial to get $fileHsspOutL\n";
	$Lok=
	    &run_program("$maxCmdL",$fhTrace); # its running!
#	if (! $Lok){
#	    return(0,"*** $sbrName no maxhom on \n$maxCmdL\n"."$msgHere",0);} 
				# ------------------------------
				# no HSSP file -> loop
	if ( ! -f $fileHsspOutL ) {
	    if (!$start_at) {	# switch a timer on
		$start_at= time(); }
				# test if an alarm is needed
	    if (!$alarm_sent && (time() - $start_at) > $paraTimeOutL) {
				# **************************************************
				# NOTE this SBR is PP specific
				# **************************************************
		&ctrlAlarm("SUICIDE: In max_loop for more than $alarm_timer... (killer!)".
			   "$msgHere");
		$alarm_sent=1;
		return(0,"maxhom SUICIDE on $fileHsspOutL".$msgHere,0); }
				# create a trace file
	    open("NOHSSP","> $fileFlagNoHsspL") || 
		warn "-*- $sbrName WARNING cannot open $fileFlagNoHsspL: $!\n";
	    print NOHSSP " problem with maxhom ($fileHsspOutL)\n"," $date\n";
	    print NOHSSP `ps -ela`;
	    sleep 10;
	    close(NOHSSP);
	    unlink ($fileFlagNoHsspL); }
    }				# end of loop 

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
			   $fileMaxMetricL,$fileHsspOutL,$fhTrace);
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

#===============================================================================
sub maxhomRunSelf {
    local($niceLoc,$exeMaxLoc,$fileMaxDefLoc,$fileJobIdLoc,$fileHsspInLoc,
	  $fileMaxMetrLoc,$fileHsspOutLoc,$fhTrace)=@_;
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
    $sbrName="maxhomRunSelf";
    return(0,"*** $sbrName: not def niceLoc!")            if (! defined $niceLoc);
    return(0,"*** $sbrName: not def exeMaxLoc!")          if (! defined $exeMaxLoc);
    return(0,"*** $sbrName: not def fileMaxDefLoc!")      if (! defined $fileMaxDefLoc);
    return(0,"*** $sbrName: not def fileJobIdLoc!")       if (! defined $fileJobIdLoc);
    return(0,"*** $sbrName: not def fileHsspInLoc!")      if (! defined $fileHsspInLoc);
    return(0,"*** $sbrName: not def fileHsspOutLoc!")     if (! defined $fileHsspOutLoc);
    return(0,"*** $sbrName: not def fileMaxMetrLoc!")     if (! defined $fileMaxMetrLoc);
    $fhTrace="STDOUT"                                     if (! defined $fhTrace);
				# check existence of files
    return(0,"*** $sbrName: miss input file '$fileHsspInLoc'!")  if (! -e $fileHsspInLoc);
    return(0,"*** $sbrName: miss input exe  '$exeMaxLoc'!")      if (! -e $exeMaxLoc);
    return(0,"*** $sbrName: miss input file '$fileMaxDefLoc'!")  if (! -e $fileMaxDefLoc);
    return(0,"*** $sbrName: miss input file '$fileMaxMetrLoc'!") if (! -e $fileMaxMetrLoc);
    $msgHere="";
				# ------------------------------
				# security check: is FASTA?
    $Lok=&isFasta($fileHsspInLoc);
    if (!$Lok){
	return(0,"*** $sbrName: input must be FASTA '$fileHsspInLoc'!");}
				# ------------------------------
				# prepare MaxHom
    ($msg,$warn)=		# check existence of files asf
	&maxhomGetArgCheck($exeMaxLoc,$fileMaxDefLoc,$fileHsspInLoc,$fileHsspInLoc,
			   $fileMaxMetrLoc);
    if (length($msg)>1){
	return(0,"$msg");} $msgHere.="--- $sbrName $warn\n";

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
    $Lok=
	&run_program("$maxCmdLoc",$fhTrace,"warn");
    if (! $Lok || ! -e $fileHsspOutLoc){ # output file missing
	return(0,"*** $sbrName: fault in maxhom ($exeMaxLoc)\n");}
    return(1,"ok $sbrName");
}				# end of maxhomRunSelf

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

#==========================================================================================
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
				# ------------------------------
				# write into file
    print $fhoutLoc 
	"MSF of: ",$input{"FROM"}," from:    1 to:   ",length($stringLoc[1])," \n",
	$input{"TO"}," MSF: ",length($stringLoc[1]),
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

#======================================================================
sub myprt_npoints {
    local ($npoints,$num_in) = @_; 
    local ($num,$beg,$ctprev,$ct,$numprev, $tmp,$tmp1,$tmp2, $out, $ct, $i);
    $[=1;
    if ( int($npoints/10)!=($npoints/10) ) {
	print "*** ERROR in myprt_npoints (lib-prot.pl): \n";
	print "***       number of points should be multiple of 10 (is $npoints)!\n"; exit; }

    $ct=int(($num_in-1)/$npoints);
    $beg=$ct*$npoints; $num=$beg;
    for ($i=1;$i<=($npoints/10);++$i) {
	$numprev=$num; $num=$beg+($i*10);
	$ctprev=$numprev/10;
	if ( $i==1 ) { $tmp=substr($num,1,1); $out="....,....".$tmp; }
	elsif ( $ctprev<10 ) {  $tmp=substr($num,1,1); $out.="....,....".$tmp; }
	elsif ( ($i==($npoints/10))&&($ctprev>=9) ) { 
	    $tmp1=substr($ctprev,2);$tmp2="." x (4-length($tmp1));
	    $out.=$tmp1.$tmp2.",....".substr(($num/10),1); }
	else {
           $tmp1=substr($ctprev,2);$tmp2="." x (4-length($tmp1));
           $out.=$tmp1.$tmp2.",....".substr($num,1,1); }}
    $myprt_npoints=$out;
    return ($out);
}				# end of myprt_npoints

#======================================================================
sub open_file {
    local ($file_handle,$file_name,$log_file) = @_ ;
    local ($temp_name) ;
#----------------------------------------------------------------------
#   open_file                   opens a file
#       in:                     $file_handle,$file_name,$log_file
#       out:                    0 or 1
#----------------------------------------------------------------------
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
}				# open_file

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
    $sbrName="pirRdSeq";$fhinLoc="FHIN"."$sbrName";

    $Lok=       &open_file("$fhinLoc","$fileInLoc");
    if (! $Lok){$msg="*** ERROR $sbrName: '$fileInLoc' not opened\n";
		return(0,$msg,"error");}
    $seq=$id="";$ct=0;
    while (<$fhinLoc>) {$_=~s/\n//g;++$ct;
			if   ($ct==1){
			    $id=$_;$id=~s/^\>P1\;\s*(\S+)[\s\n]*.*$/$1/g;}
			elsif($ct==2){$id.=", $_";}
			else {$_=~s/[\s\*]//g;
			      $seq.="$_";}}close($fhinLoc);
    $seq=~s/\s//g;
    return(1,$id,$seq);
}				# end of pirRdSeq

#==========================================================================================
sub ppHsspRdExtrHeader {
    local ($file_in) = @_ ;
    local ($fhinLoc,$sbrName,$msg,$ct,$tmp,$tmp2,@tmp,$it);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    hssp_extr_header           extracts the summary from HSSP header (for PP)
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

#==========================================================================================
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

#==========================================================================================
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
		"--- str:seq= %3d : structure (sec str, acc)=%3d\%, sequence=%3d\%\n",
		int($mixLoc),int($mixLoc),int(100-$mixLoc);
	} else {print $fhout "$strip\n"; }
    }
    close($fhout);
    return(1,"ok $sbrName");
}				# end of ppTopitsHdWrt

#==========================================================================================
sub printm { local ($txt,@fh) = @_ ;local ($fh);$[ =1 ;
#--------------------------------------------------------------------------------
#   printm                      print on multiple filehandles (in:$txt,@fh; out:print)
#       in:                     $txt,@fh
#--------------------------------------------------------------------------------
	     foreach $fh (@fh) { if ((! eof($fh))||($fh eq "STDOUT")) { print $fh $txt;}}
}				# end of printm

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
#-------------------------------------------------------------------------------
    $sbrName="lib-ppNew:"."prodomRun";$fhinLoc="FHIN"."$sbrName";
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
    
    return(0,"*** $sbrName: no in file '$fileInLoc'!")    if (! -e $fileInLoc);
				# ------------------------------
				# set env
    $ENV{'BLASTMAT'}=$envBlastMat;
    $ENV{'BLASTDB'}= $envBlastDb;
				# ------------------------------
				# run BLAST
    $dbTmp=$parBlastDb;$dbTmp=~s/\/$//g;
    $cmd=  "$niceLoc $exeBlast $dbTmp $fileInLoc E=$parBlastE B=$parBlastN >> $fileOutTmpLoc ";
    system("$cmd");
				# ------------------------------
				# read BLAST header
    ($Lok,$msg,%head)=
	&blastpRdHdr($fileOutTmpLoc,$fhErrSbr);

    return(0,"*** ERROR $sbrName: after blastpRdHdr msg=$msg") if (! $Lok);
    return(0,"*** ERROR $sbrName: after blastpRdHdr no id head{id} defined") 
	if (! defined $head{"id"} || length($head{"id"})<2);
				# ------------------------------
				# select id below threshold
    @idRd=split(/,/,$head{"id"});$#idTake=0;
    foreach $id (@idRd){
	push(@idTake,$id) if (defined $head{"$id","prob"} && 
			      $head{"$id","prob"} <= $parBlastP);}
    undef %head; $#idRd=0;	# save space
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

#===============================================================================
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
	"---       http://www.toulouse.inra.fr/prodom.html\n",
	"----      ---------------------------------------\n",
	"--- \n",
	"--- For WWW graphic interfaces to PRODOM, in particular for your\n",
	"--- protein family, follow the following links (each line is ONE\n",
	"--- single link for your protein!!):\n",
	"--- \n";
				# ------------------------------
				# define keywords
    $txt1a="http://www.toulouse.inra.fr/prodom/cgi-bin/ReqProdomII.pl?id_dom1=";
    $txt1b=" ==> multiple alignment, consensus, PDB and PROSITE links of domain ";
    $txt2a="http://www.toulouse.inra.fr/prodom/cgi-bin/ReqProdomII.pl?id_dom2=";
    $txt2b=" ==> graphical output of all proteins having domain ";
				# ------------------------------
				# establish links
    foreach $id (@idTake){$id=~s/\s//g;
			  next if ($id =~/\D/ || length($id)<1);
			  print $fhoutLoc "$txt1a".$id."$txt1b".$id."\n";
			  print $fhoutLoc "$txt2a".$id."$txt2b".$id."\n";}
    print $fhoutLoc
	"--- \n",
	"--- NOTE: if you want to use the link, make sure the entire line\n",
	"---       is pasted as URL into your browser!\n",
	"--- \n",
	"--- END of PRODOM\n",
	"--- ------------------------------------------------------------\n";
    close($fhoutLoc);
    return(1,"ok $sbrName");
}				# end of prodomWrt

#==========================================================================================
sub rd_col_associative {
    local ($file_in,@des_in) = @_ ;
    local ($sbr_name,$fhin,$it,@tmp,$tmp,$des_in,
	   %ptr,%rdcol);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    rd_rdb_associative         reads the content of a comma separated file
#       in:                     Names used for columns in perl file, e.g.,
#--------------------------------------------------------------------------------
				# avoid warning
    $READHEADER="";
				# set some defaults
    $fhin="FHIN_COL";
    $sbr_name="rd_col_associative";
				# --------------------------------------------------
				# read RDB file
				# --------------------------------------------------
    &open_file("$fhin","$file_in");
    $ct=0;
    while(<$fhin>){
	$_=~s/\n//g;$line=$_;
	next if (/^\#/);	# ignore RDB header
	next if ($line =~/\dN[\t\n]|\d\.F\d[\t\n]/); # skip format
	++$ct;			# delete leading blanks, commatas and tabs
	$_=~s/^\s*|\s*$|^,|,$|^\t|\t$//g;
	$#tmp=0;@tmp=split(/[\t]/,$_);
	if ($ct==1){$Lok=0;
		    foreach $des (@des_in) {
			foreach $it (1..$#tmp) {
			    if ($des =~ /$tmp[$it]/){
				$ptr{$des}=$it;
				$Lok=1;last;}}}
		    die ("*** ERROR in $sbr_name: reading col format, none found") 
			if (! $Lok);
		    next;}
	foreach $des (@des_in){
	    if (defined $ptr{$des}){
		$tmp=$ct-1;
		$rdcol{"$des","$tmp"}=$tmp[$ptr{$des}];
	    }}
    }close($fhin);
    $rdcol{"NROWS"}=$ct-1;
    return (%rdcol);
}				# end of rd_col_associative

#==========================================================================================
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
#       out:                    rdrdb{"NALIGN"},rdrdb{"POS","ct"},rdrdb{"NPROT","ct"},
#                               where ct counts the rows read,
#                               rdrdb{"NROWS"} returns the numbers of rows read
#--------------------------------------------------------------------------------
				# avoid warning
    $READHEADER="";
    $Lscreen=1;
				# set some defaults
    $fhin="FHIN_RDB";
    $sbr_name="rd_rdb_associative";
				# get input
    $Lhead=$Lbody=$#des_headin=$#des_bodyin=0;
    foreach $des_in(@des_in){
	if   ($des_in=~/^not_screen/)        {$Lscreen=0;}
	elsif((!$Lhead) && ($des_in=~/head/)){$Lhead=1;$Lhead_all=1;}
	elsif((!$Lbody) && ($des_in=~/body/)){$Lbody=1;$Lhead=0; }
	elsif($Lhead)                        {push(@des_headin,$des_in);}
	elsif($Lbody)                        {$des_in=~s/\n|\s//g;;
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
    foreach $des_in (@des_bodyin) {
	$Lfound=0;
	for($it=1;$it<=$#READNAME;++$it) {
	    $rd=$READNAME[$it];
	    if ($rd eq $des_in) {$ptr_rd2des{"$des_in"}=$it;push(@des_body,$des_in);
				 $Lfound=1;last;} }
	if((!$Lfound) && $Lscreen){
	    print"--- $sbr_name: \t expected to find column name:\n";
	    print"---            \t '$des_in', but not in file '$file_in'\n";}
    }
				# ------------------------------
				# get format
    foreach $des_in(@des_bodyin) {
	$it=$ptr_rd2des{"$des_in"};
	if ( (defined $it) && (defined $READFORMAT[$it]) ) {
	    $rdrdb{"$des_in","format"}=$READFORMAT[$it];}
	else {
	    $rdrdb{"$des_in","format"}="8";}}

    $nrow_rd=0;
    foreach $des_in(@des_body) {
	$itrd=$ptr_rd2des{"$des_in"};
	@tmp=split(/\t/,$READCOL[$itrd]);
	if ($nrow_rd==0){$nrow_rd=$#tmp;}
	elsif($nrow_rd!=$#tmp){print "*** WARNING $sbr_name: different number of rows\n";
			       print "*** WARNING in RDB file '$file_in' for rows with ".
				   "key= $des_in and previous column no=$itrd,\n";}
	for($it=1;$it<=$#tmp;++$it){$rdrdb{"$des_in","$it"}=$tmp[$it];}
    }
    $rdrdb{"NROWS"}=$rdrdb{"NROWS"}=$nrow_rd;
    return (%rdrdb);
}				# end of rd_rdb_associative

#==========================================================================================
sub rdb2html {
    local ($fileRdb,$fileHtml,$fhout,$Llink,$scriptName) = @_ ;
    local (@headerRd,$tmp,@tmp,@colNames,$colNames,%body,$des,$ct,$fhin);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   rdb2html                    convert an RDB file to HTML
#         in:		        $fileRdb,$fileHtml,$fhout,$Llink 
#                               (Llink=1 -> links from column names to Notation in header)
#         ext                   open_file, 
#         ext                   wrtRdb2HtmlHeader,wrtRdb2HtmlBody
#         ext (implicit)        wrtRdb2HtmlBodyColNames,wrtRdb2HtmlBodyAve
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
	"<A HREF=\"http:\/\/www.embl-heidelberg.de\/\">",
              "<IMG ALIGN=MIDDLE SRC=",
	      "\"http:\/\/www.embl-heidelberg.de\/icons\/embl_home.gif\" ",
	      "ALT=\"EMBL Home\"><\/A>\n",
	"<A HREF=\"http:\/\/www.sander.embl-heidelberg.de\/descr\/\">",
              "<IMG ALIGN=MIDDLE SRC=",
	      "\"http:\/\/www.sander.embl-heidelberg.de\/sander-icon.gif\" ",
	      "ALT=\"Sander Group\"><\/A>\n",
	"<A HREF=\"http:\/\/www.embl-heidelberg.de\/~rost\/\">",
              "<IMG ALIGN=MIDDLE SRC=",
	      "\"http:\/\/www.embl-heidelberg.de\/~rost\/Dfig\/icon-br-home.gif\" ",
	       "ALT=\"Rost Home\"><\/A>\n",
	"<A HREF=\"mailto\:rost\@embl-heidelberg.de\">",
              "<IMG ALIGN=MIDDLE SRC=",
	      "\"http:\/\/www.embl-heidelberg.de\/~rost\/Dfig\/icon-br-home-mail.gif\" ",
	       "ALT=\"Mail to Rost\"><\/A>\n",
	"<A HREF=\"http:\/\/www.embl-heidelberg.de\/predictprotein\/\">",
              "<IMG ALIGN=MIDDLE SRC=",
	      "\"http:\/\/www.embl-heidelberg.de\/~rost\/Dfig\/icon-pp.gif\" ",
	      "ALT=\"PredictProtein\"><\/A>\n",
	"<\/BODY>\n","<\/HTML>\n";
    print $fhout "\n";
    close($fhin);close($fhout);
}				# end of rdb2html

#==========================================================================================
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
    foreach $des_in(@des_in){
	if   ($des_in=~/^not_screen/)        {$Lscreen=0;}
	elsif((!$Lhead) && ($des_in=~/head/)){$Lhead=1;$Lhead_all=1;}
	elsif((!$Lbody) && ($des_in=~/body/)){$Lbody=1;$Lhead=0; }
	elsif($Lhead)                        {push(@des_headin,$des_in);}
	elsif($Lbody)                        {$des_in=~s/\n|\s//g;;
					      push(@des_bodyin,$des_in);}
	else {print "*** WARNING $sbr_name: input '$des_in' not recognised.\n";} }
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
		if ($rd =~ /^$des_in[ :,\;]/){
		    $tmp=$rd;$tmp=~s/\n|\s$//g;$tmp=~s/$des_in//g;$tmp=~s/^\s*//g;
		    if (defined $rdrdb{"$des_in"}){
			$rdrdb{"$des_in"}.="\t".$tmp;}
		    else {
			$rdrdb{"$des_in"}=$tmp;}
		    push(@des_head,$des_in);$Lfound=1;} }
	    if(!$Lfound && $Lscreen){
		print"--- $sbr_name: \t expected to find in header key word:\n";
		print"---            \t '$des_in', but not in file '$fileInLoc'\n";}
	}}
    elsif ($Lhead_all) {		# whole header into $rdrdb{"header"}
	$rdrdb{"header"}="";
	foreach $rd (@tmp) { $rd=~s/^\s?|\n//g;
			     $rdrdb{"header"}.="# ".$rd."\n"; }}
				# ------------------------------
    $#des_body=0;		# get column numbers to be read
    foreach $des_in (@des_bodyin) {
	$Lfound=0;
	for($it=1;$it<=$#READNAME;++$it) {
	    $rd=$READNAME[$it];$rd=~s/\s//g;
	    if ($rd eq $des_in) {$ptr_rd2des{"$des_in"}=$it;push(@des_body,$des_in);$Lfound=1;
				 last;} }
	if((!$Lfound) && $Lscreen){
	    print"--- $sbr_name: \t expected to find column name:\n";
	    print"---            \t '$des_in', but not in file '$fileInLoc'\n";}}
				# ------------------------------
				# get format
    foreach $des_in(@des_bodyin) {
	$it=$ptr_rd2des{"$des_in"};
	if ( (defined $it) && (defined $READFORMAT[$it]) ) {
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
	for($it=1;$it<=$#tmp;++$it){$rdrdb{"$des_in","$it"}=$tmp[$it];
				    $rdrdb{"$des_in","$it"}=~s/\s//g;}
    }
    $rdrdb{"NROWS"}=$rdrdb{"NROWS"}=$nrow_rd;
    return (%rdrdb);
}				# end of rdRdbAssociative

#==========================================================================
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
	if ( /^\#/ ) { 	$READHEADER.= "$_";
			next;}
	$rd=$_;$rd=~s/^\s+|\s+$//g;
	if (length($rd)<2){
	    next;}
				# ------------------------------
	++$ctLoc;		# rest
	if ( $ctLoc >= 3 ) {	# col content
	    $rd=$_;$rd=~s/^\t+|\t$//g;@tmpar=split(/\t/,$rd);
	    foreach $it (1..$#readnum){
		if (defined $tmpar[$readnum[$it]]) {
		    $READCOL[$it].=$tmpar[$readnum[$it]] . "\t"; }} }
	elsif ( $ctLoc==1 ) {	      # col name
	    $rd=$_;$rd=~s/^\t+|\t$//g;@tmpar=split(/\t/,$rd);
				# process wild card
	    if ($#readnum==0 || $readnum[1]==0 ||
		$readnum[1] !~ /[0-9]/ || ! defined $readnum[1] ) {
		foreach $it (1..$#tmpar){$readnum[$it]=$it;$READCOL[$it]=""; }}
	    foreach $it (1..$#readnum){
		$tmp_name=$tmpar[$readnum[$it]];$tmp_name=~s/\s|\n//g;
		$READNAME[$it]="$tmp_name";} }
	elsif ( $ctLoc==2 ) {	# col format
	    $rd=$_;$rd=~s/^\t+|\t$//g;@tmpar=split(/\t/,$rd);
	    foreach $it (1..$#readnum){
		$ipos=$readnum[$it];$tmp=$tmpar[$ipos]; $tmp=~s/\s//g;
		$READFORMAT[$it]=$tmp; } }}
    for ($it=1; $it<=$#READNAME; ++$it) {
	$READFORMAT[$it]=~ s/^\s+//g;
	if ($#READNAME>0) { $READNAME[$it]=~ s/^\s+//g;}
	$READCOL[$it] =~ s/\t$|\n//g; # correction: last not return!
	$READFORMAT[$it]=~ s/\t$|\n//g;$READNAME[$it]=~s/\t|\n//g;
	if ($#READNAME>0) { $READNAME[$it]=~s/\n//g; }
    }
}				# end of rdRdbAssociativeNum

#==========================================================================
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

#==========================================================================
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
	    print "WARNING lib-ut.pl:read_rdb_num2: READFORMAT for it=$it not defined\n";
	    $READFORMAT[$it]=" ";}
	$READFORMAT[$it]=~ s/^\s+//g;
	if ($#READNAME>0) { $READNAME[$it]=~ s/^\s+//g;}
	$READCOL[$it] =~ s/\t$|\n//g;	      # correction: last not return!
	$READFORMAT[$it]=~ s/\t$|\n//g;$READNAME[$it]=~s/\t|\n//g;
	if ($#READNAME>0) { $READNAME[$it]=~s/\n//g; }
    }
}				# end of read_rdb_num2

#======================================================================
sub run_program {
    local ($cmd,$log_file,$action) = @_ ;
    local ($out_command,$cmdtmp);
    $[ =1;
#----------------------------------------------------------------------
#   run_program                 runs system command (system"$cmd")
#       in:                     $cmd,$log_file,$action
#       out:                    0 or 1
#----------------------------------------------------------------------
    ($cmdtmp,@out_command)=split(",",$cmd) ;

    $log_file="STDOUT" if (!defined $log_file);

    print $log_file "--- running command: \t $cmdtmp\n" if ((! defined $Lverb)||$Lverb);
    print $log_file "do='$action'\n" if (defined $action);
    open (TMP_CMD, "|$cmdtmp") || 
	(do {
	    print $log_file "Can not run command: $cmdtmp\n" if ( $log_file );
	    warn "Can not run command: '$cmdtmp'\n" ;
	    exec $action if (defined $action);
	});
    foreach $command (@out_command) {
# delete end of line, and spaces in front and at the end of the string
	$command =~ s/\n// ;
	$command =~ s/^ *//g ;
	$command =~ s/ *$//g ; 
	print TMP_CMD "$command\n" ;
    }close (TMP_CMD) ;
    return(1,"ok run_program");
}				# end of run_program

#===============================================================================
sub sendMailAlarm {
    local($messageLoc,$userLoc,$exe_mailLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok,$dateLoc,@dateLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   sendMailAlarm               sends alarm mail to user
#       in:                     $message, $user, $exe_mail
#       err:                    ok=(1,'ok'), err=(0,'msg')
#-------------------------------------------------------------------------------
    $sbrName="sendMailAlarm";
    return(0,"*** $sbrName: not def messageLoc!")          if (! defined $messageLoc);
    return(0,"*** $sbrName: not def userLoc!")             if (! defined $userLoc);
    return(0,"*** $sbrName: not def exe_mailLoc!")          if (! defined $exe_mailLoc);
    return(0,"*** $sbrName: mail executable '$exe_mailLoc'!") if (! -e $exe_mailLoc);

    @dateLoc = split(' ',&ctime(time));
    shift (@dateLoc); $dateLoc = join(':',@dateLoc);

    $message=  "\n"."*** $date\n"."*** from sendMailAlarm (lib-x.pl)\n"."***$message\n";
    system("echo '$messageLoc' | $exe_mailLoc -s PP_ERROR $userLoc");
    return(1,"ok $sbrName");
}				# end of sendMailAlarm

#==========================================================================================
sub swissGetFile { 
    local ($idLoc,$LscreenLoc,@dirLoc) = @_ ; 
    local ($fileLoc,$dirLoc,$tmp,@dirSwissLoc);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   swissprotGetFile            returns SWISS-PROT file for given filename
#       in:                     $id,$LscreenLoc,@dirLoc
#       out:                    $file (id or 0 for error)
#--------------------------------------------------------------------------------
    if (-e $idLoc){		# already existing directory
	return($idLoc);}
    @dirSwissLoc=("/data/swissprot/current/"); # swiss dir's
    if ((defined $LscreenLoc) && (-d $LscreenLoc)){ # case: second argument directory
	if ($#dirLoc){
	    push(@dirLoc,$LscreenLoc);}else { $dirLoc[1]=$LscreenLoc;}
	$LscreenLoc=0;}
    if ($#dirLoc>0){push(@dirSwissLoc,@dirLoc);}
	
				# go through all directories
    foreach $dirLoc(@dirSwissLoc){
	if (! defined $dirLoc){
	    next;}
	if (! -d $dirLoc){	# directory not existing
	    next;}
	$fileLoc=&complete_dir($dirLoc)."$idLoc";
	if (-e $fileLoc){
	    return($fileLoc);}
	$tmp=$idLoc;$tmp=~s/^.*\///g; # purge directory
	$tmp=~s/^.*_(.).*$/$1/;$tmp=~s/\n//g; # get species
	$fileLoc=&complete_dir($dirLoc).$tmp."/"."$idLoc";
	if (-e $fileLoc){
	    return($fileLoc);}}
    return(0);
}				# end of swissGetFile

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
    $niceLoc="" if ($niceLoc =~ /^no/ || $niceLoc eq " " || length($niceLoc)==0 );
    return(0,"*** $sbrName: needs 2 arg 'fToCopy fToCatTo'!")     if (! defined $fileToCatTo);
    return(0,"*** $sbrName: missing input file '$fileToCat[1]'!") if (! -e $fileToCat[1]);

    $msg="";
    foreach $fileToCat(@fileToCat){
	$Lok= system("$niceLoc cat < $fileToCat >> $fileToCatTo");
	$msg.="$sbrName \t '$niceLoc cat < $fileToCat >> $fileToCatTo'\n";
	if (($Lok != 0)||(! -e $fileToCatTo)){
	    print "*** $sbrName ERROR: '$fileToCat -> $fileToCatTo' ($Lok)!"."$msg";
	    return(0,"*** $sbrName ERROR: '$fileToCat -> $fileToCatTo' ($Lok)!"."$msg");}}
    if ($LdebugLoc){
	print "--- $sbrName: $msg";}
    return(1,"$msg");
}				# end of sysCatfile

#===============================================================================
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
    $niceLoc="" if (! defined $niceLoc);
    if (! -d $argIn){
	$Lok= system("$niceLoc mkdir $dirWorkLoc");
	if ($Lok != 0){
	    return(0,"*** $sbrName: couldnt find or make dir '$argIn' ($Lok)!");}}
    return(1,"$niceLoc mkdir $dirWorkLoc");
}				# end of sysMkdir

#===============================================================================
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

#===============================================================================
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

#===============================================================================
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
	"# FORMAT   file end:   '//' is the end of a complete file\n",
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

#======================================================================
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

#==========================================================================
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
    if (! defined $CHAIN){$CHAIN=" ";}
    for ($it=1; $it<=$#NUM; ++$it) {
	printf $fhoutLoc 
	    " %4d %4d %1s %1s  %1s           0   0  %3d    %1d  %1d\n",
	    $NUM[$it], $NUM[$it], $CHAIN, $SEQ[$it], $SEC[$it], 
	    $ACC[$it], $RISEC[$it], $RIACC[$it];}
    return(1);
}				# end wrt_dssp_phd

#==========================================================================================
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

#==========================================================================================
sub wrt_phd_header2pp {
    local ($file_out) = @_ ;
    local ($fhout,$header,@header);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    wrt_phd_header2pp                    
#--------------------------------------------------------------------------------
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

#==========================================================================================
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
	if (defined $rdrdb{"pL","$it"}) { $pL=$rdrdb{"pL","$it"}; } else {$pL=0;}
#	next if ($pH =~/[^0-9\.]/ || $pE =~/[^0-9\.]/  || $pL =~/[^0-9\.]/ );
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

#==========================================================================================
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
    printf $fhout "--- %-10s: %-s\n","       ","scaled from 0 (low) to 9 (high)";
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
	$rdrdb{"prH","$it"}=&min(9,int(10*$rdrdb{"OtH","$it"}/$sum));
	$rdrdb{"prE","$it"}=&min(9,int(10*$rdrdb{"OtE","$it"}/$sum));
	$rdrdb{"prL","$it"}=&min(9,int(10*$rdrdb{"OtL","$it"}/$sum));
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
	$tmp=substr($subsec,$it,60);$tmpf=length($tmp)."s";
	printf $fhout "%15s|%-$tmpf|\n"," subset: SUB sec ",$tmp;
	printf $fhout " \n";
				# accessibility
	printf $fhout " ACCESSIBILITY\n";
	foreach $desacc("Pbie","PREL","RI_A"){
	    if ($desacc=~/Pbie/)   {$desout=" 3st:    P_3 acc ";}
	    elsif ($desacc=~/PREL/){$desout=" 10st:   PHD acc ";}
	    elsif ($desacc=~/RI_A/){$desout="         Rel acc ";}
	    $tmp=substr($string{"$desacc"},$it,60);$tmpf=length($tmp)."s";
	    printf $fhout "%-15s|%-$tmpf|\n","$desout",$tmp;
	}
	$tmp=substr($subacc,$it,60);$tmpf=length($tmp)."s";
	printf $fhout "%15s|%-$tmpf|\n"," subset: SUB acc ",$tmp;
	printf $fhout " \n";
    }
    print $fhout "--- \n";
    print $fhout "--- PHD PREDICTION END\n";
    print $fhout "--- \n";
    close($fhout);
}				# end of wrt_phd_rdb2pp

#==========================================================================================
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
	print "'\&convHssp2Msf($fileHssp,$fileMsfTmp,$exeConvSeq,$optExpand,$Lscreen2)'\n";}
    $Lok=
	&convHssp2Msf($fileHssp,$fileMsfTmp,$exeConvSeq,$optExpand,$Lscreen2);
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

#==========================================================================================
sub wrt_phdpred_from_string {
    local ($fh,$nres_per_row,$mode,$Ldo_htmref,@des) = @_ ;
    local (@des_loc,@header_loc,$Lheader);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   wrt_phdpred_from_string     writes the body of the PHD.pred files from the
#                               global array %STRING{}
#       in (GLOBAL)
#         A                     %STRING, i.e., one line string with prediction,
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
	    if (length($STRING{"$_"})<$it){
		next;}
	    $tmp=substr($STRING{"$_"},$it,$nres_per_row);
	    if (length($tmp)==0) {next;}
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

#==========================================================================================
sub wrt_phdpred_from_string_htm {
    local ($fh,$nres_tmp,$nres_per_row,$symh,$Ldo_htmref,@des_loc) = @_ ;
    local ($it,$tmp);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   wrt_phdpred_from_string_htm writes body of the PHD.pred files from the
#                               global array %STRING{} for HTM
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
	    $format="%-".length($tmp)."s";$len=length($tmp);
				# helical transmembrane regions
	    if   ($_=~/aa/)    {printf $fh "%8s %-7s |%-s|\n"," ","AA ",$tmp; }
	    elsif($_=~/ohtm/)  {printf $fh "%8s %-7s |%-s|\n"," ","OBS htm",$tmp; }
	    elsif($_=~/phtm/)  {printf $fh "%8s %-7s |%-s|\n"," ","PHD htm",$tmp; }
	    elsif($_=~/pfhtm/) {printf $fh "%8s %-7s |%$len-s|\n"," other:"," "," "; 
		                printf $fh "%8s %-7s |%-s|\n"," ","PHDFhtm",$tmp; }
	    elsif($_=~/rihtm/) {printf $fh "%8s %-7s |%-s|\n"," ","Rel htm",$tmp; }
	    elsif($_=~/prHhtm/){printf $fh "%8s %-7s |%$len-s|\n"," detail:"," "," "; 
				printf $fh "%8s %-7s |%-s|\n"," ","prH htm",$tmp; }
	    elsif($_=~/prLhtm/){printf $fh "%8s %-7s |%-s|\n"," ","prL htm",$tmp; }
	    elsif($_=~/subhtm/){printf $fh "%-8s %-7s |%$len-s|\n"," subset:"," "," ";
				printf $fh "%-8s %-7s |%-s|\n"," ","SUB htm",$tmp;}
	    elsif($_=~/prhtm/) {printf $fh "%8s %-7s |%-s|\n"," ","PHDRhtm",$tmp; }
	    elsif($_=~/pthtm/) {printf $fh "%8s %-7s |%-s|\n"," ","PHDThtm",$tmp; }}}
    if ($Ldo_htmref) {
	print $fh
	    "--- \n",
	    "--- PhdTopology REFINEMENT AND TOPOLOGY PREDICTION END\n",
	    "--- \n";}
}				# end of wrt_phdpred_from_string

#==========================================================================================
sub wrt_phdpred_from_string_htm_header {
    local ($fh,@header) = @_ ;
    local ($header,$header_txt,$des,%txt,@des,%dat);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   wrt_phdpred_from_string_htmheader: writes the header for PHDhtm ref and top
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
	    $dat{"$des"}=$header_txt;}}
				# writing notation
    foreach $des (@des,"MOD_NHTM","MOD_STOT","MOD_SHTM","MOD_N-C"){
	if ($des eq "MODEL_DAT") { # skip
	    next;}
	$tmp_des=$des;$tmp_des=~s/\_DPROJ//g;$tmp_des=~s/\s//g;
	printf $fh "--- %-13s: %-s\n",$tmp_des,$txt{"$des"};}
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
	    printf $fh "--- %-13s: %-s\n",$tmp_des,$dat{"$des"};}}
}				# end of wrt_phdpred_from_string_htm_header

#==========================================================================================
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

#===============================================================================
sub subx {
#    local($fileInLoc,$fhErrSbr) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   subx                       
#       in:                     
#       out:                    
#       err:                    ok=(1,'ok'), err=(0,'msg')
#-------------------------------------------------------------------------------
    $sbrName="subx";
    return(0,"*** $sbrName: !") if (! defined );
}				# end of subx

1;
