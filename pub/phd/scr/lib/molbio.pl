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
#    PERL library with routines related to molbio programs:                    #
#    - blast | coils | fasta | maxhom | prodom | seg                           #
#                                                                              #
#------------------------------------------------------------------------------#
# 
# 
# -----------------------------------------------------------------------------# 
#                               ---------------------
#   molbio                      internal subroutines:
#                               ---------------------
# 
#   blast3Formatdb              formats a db for BLAST (blast 3 = new PSI blast)
#   blast3RunSimple             simply runs BLASTALL (blast3)
#   blastGetSummary             BLAST out -> summary: IDE,LALI,LEN,PROB,DISTANCE-to-hssp-curve
#   blastpExtrId                extracts only lines with particular id from BLAST
#   blastpRdHdr                 reads header of BLASTP output file
#   blastpRun                   runs BLASTP
#   blastpRunSimple             simply runs BLASTP (blast2)
#   blastpFormatdb              formats a db for BLASTP (blast 2)
#   blastpsiMatRead             reads the PSI-BLAST matrix file
#   blastSetenv                 sets environment for BLASTP runs
#   blastWrtSummary             writes summary for blast results (%ide,len,distance HSSP)
#   coilsRd                     reads the column format of coils
#   coilsRun                    runs the COILS program from Andrei Lupas
#   dsspCheck                   check whether or not DSSP ok
#   dsspRdSeqSecAcc             reads DSSP file
#   dsspRun                     run DSSP
#   fastaRun                    runs FASTA
#   maxhomCheckHssp             checks: (1) any ali? (2) PDB?
#   maxhomGetArg                gets the input arguments to run MAXHOM
#   maxhomGetArg2               gets the input arguments to run MAXHOM
#   maxhomGetArgCheck           performs some basic file-existence-checks
#   maxhomGetThresh             translates cut-off ide into text input for MAXHOM csh
#   maxhomGetThresh4PP          translates cut-off ide into text input for MAXHOM csh
#   maxhomMakeLocalDefault      build local maxhom default file, and set PATH!!
#   maxhomRun                   runs Maxhom (looping for many trials + self)
#   maxhomRunLoop               loops over a maxhom run (until paraTimeOutL = 3hrs)
#   maxhomRunSelf               runs a MaxHom: search seq against itself
#   mviewRun                    runs MView (Nigel Brown) on an alignment
#   prodomRun                   runs a BLASTP against the ProDom db
#   prodomWrt                   write the PRODOM data + BLAST ali
#   segInterpret                reads FASTA-formatted output from SEG, counts 'x'
#   segRun                      runs the Wootton program SEG on one FASTA sequence
#   sequenceAlign               supposed to find corresponding residues
#   strideCheck                 check whether or not STRIDE ok
#   strideRun                   run STRIDE
# 
# -----------------------------------------------------------------------------# 
#                               ---------------------
#   molbio                      external subroutines:
#                               ---------------------
# 
#   call from comp:             get_max
# 
#   call from file:             isFasta,open_file,rdbGenWrtHdr
# 
#   call from formats:          convSeq2fasta
# 
#   call from molbio:           blastpExtrId,blastpRdHdr,blastpRun,maxhomCheckHssp
#                               maxhomGetArg,maxhomGetArgCheck,maxhomGetThresh,maxhomRunLoop
#                               maxhomRunSelf,prodomWrt
# 
#   call from prot:             getDistanceNewCurveIde
# 
#   call from scr:              errSbr,errSbrMsg,myprt_npoints
# 
#   call from sys:              fileCp,run_program,sysCpfile,sysRunProg
# 
#   call from system:            
#                                call
#                                call call
#                               $cmd$cmd
#                               \\rm MAX*$jobid\\rm MAX*$jobid
#                               setenv BLASTDB $tmpsetenv BLASTDB $tmp
# 
#   call from missing:           
#                               ctime
#                               ctrlAlarm
# 
# 
# -----------------------------------------------------------------------------# 
# 

#===============================================================================
sub blast3Formatdb {
    local($fileInLoc,$titleLoc,$exeFormatdbLoc,$fileOutScreenLoc,$fhSbrErr) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   blast3Formatdb              formats a db for BLAST (blast 3 = new PSI blast)
#                               NOTE: automatically sets environment !!!
#                                  syntax 'formatdb -t TITLE -i DIR/fasta-file -l logfile'
#                                  note:  files will be created in DIR !
#       in:                     $fileInLoc     : FASTAmul formatted db file
#       in:                     $fileOutLoc    : BLASTP output                if = 0: onto screen
#       in:                     $exeBlastLoc   : FORTRAN exe BLASTP           if = 0: default
#       in:                     $fileOutScreen : screen dumpb of system call  if = 0: 0 -> STDOUT
#       in:                     $fhSbrErr      : error file handle
#       out:                    1|0,msg,$title : name of formatted db
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."blast3Formatdb";$fhinLoc="FHIN_"."blast3Formatdb";
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
    return(&errSbr("miss in file '$fileInLoc'!"))  if (! -e $fileInLoc);
                                # ------------------------------
				# local defaults
    $exeFormatdbLocDef=            "/nfs/data5/users/ppuser/server/pub/molbio/formatdb.$ARCH";
                                # ------------------------------
				# check arguments
    $titleLoc=0                 if (! defined $titleLoc);
    $exeFormatdbLoc=$exeFormatdbLocDef 
                                if (! defined $exeFormatdbLoc || ! $exeFormatdbLoc);

    $fhSbrErr="STDOUT"          if (! defined $fhSbrErr || ! $fhSbrErr);
    $fileOutScreenLoc=0         if (! defined $fileOutScreenLoc || ! $fileOutScreenLoc);

    $cmdSys="";
				# ------------------------------
				# title and setenv BLASTDB
    if (! $titleLoc)     {	# ------------------------------
	$titleLoc=$fileInLoc;
	$titleLoc=~s/^.*\///g;}
    $tmp=$fileInLoc; $tmp=~s/^(.*)\/.*$/$1/g;
    if (length($tmp)<1 && defined $ENV{'PWD'})  { 
	$tmp=$ENV{'PWD'};}
    if (length($tmp) > 1){
	$tmp=~s/\/$//g;
	system("setenv BLASTDB $tmp");}
				# ------------------------------
				# run formatdb (for BLASTP)
				# ------------------------------

                                # syntax 'formatdb -t TITLE -i DIR/fasta-file -l logfile'
                                # note:  files will be created in DIR !
    $cmd= $exeFormatdbLoc." -t $titleLoc -i".$fileInLoc;
    $cmd.="-l $fileOutScreenLoc" if ($fileOutScreenLoc);

    eval "\$cmdSys=\"$cmd\"";
    ($Lok,$msg)=
	&sysRunProg($cmdSys,$fileOutScreenLoc,$fhSbrErr);
    return(&errSbrMsg("failed to run FORMATDB on ($fileInLoc)",$msg)) 
        if (! $Lok || ($fileOutLoc && ! -e $fileOutLoc));

    return(1,"ok $sbrName",$titleLoc);
}				# end of blast3Formatdb

#===============================================================================
sub blast3RunSimple {
    local($fileInLoc,$fileOutLoc,$exeBlast3Loc,$dbBlastLoc,$parELoc,$parBLoc,
	  $fileOutScreenLoc,$fhSbrErr) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   blast3RunSimple             simply runs BLASTALL (blast3)
#                               NOTE: for security call &blastSetenv before running
#       in:                     $fileInLoc     : FASTA formatted input file
#       in:                     $fileOutLoc    : BLASTP output                if = 0: onto screen
#       in:                     $exeBlastLoc   : FORTRAN exe BLASTP           if = 0: default
#       in:                     $dbBlastLoc    : BLASTP db to run             if = 0: swiss
#       in:                     $parELoc       : BLASTP para E                if = 0: default
#       in:                     $parBLoc       : BLASTP para B                if = 0: default
#       in:                     $fileOutScreen : screen dumpb of system call  if = 0: 0 -> STDOUT
#       in:                     $fhSbrErr      : error file handle
#       out:                    1|0,msg,  implicit: file
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."blast3RunSimple";$fhinLoc="FHIN_"."blast3RunSimple";
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
    return(&errSbr("miss in file '$fileInLoc'!"))  if (! -e $fileInLoc);
                                # ------------------------------
				# local defaults
    $exeBlast3LocDef=           "/nfs/data5/users/ppuser/server/pub/molbio/blastall.$ARCH";
    $dbBlastLocDef=             "swiss";
    $parELocDef=             1000;
    $parBLocDef=             2000;
                                # ------------------------------
				# check arguments
    $fileOutLoc=0               if (! defined $fileOutLoc);
    $exeBlast3Loc=$exeBlast3LocDef  if (! defined $exeBlast3Loc || ! $exeBlast3Loc);
    $dbBlastLoc=$dbBlastLocDef  if (! defined $dbBlastLoc || ! $dbBlastLoc);
    $parELoc=$parELocDef        if (! defined $parELoc || ! $parELoc);
    $parBLoc=$parBLocDef        if (! defined $parBLoc || ! $parBLoc);

    $fhSbrErr="STDOUT"          if (! defined $fhSbrErr || ! $fhSbrErr);
    $fileOutScreenLoc=0         if (! defined $fileOutScreenLoc || ! $fileOutScreenLoc);

    $cmdSys="";
				# ------------------------------
				# run BLAST
				# ------------------------------
                                    
    $cmd= $exeBlast3Loc." -i $fileInLoc -p blastp -d $dbBlastLoc -F F -e $parELoc -b $parBLoc";
    $cmd.=" -o $fileOutLoc"      if ($fileOutLoc);

    eval "\$cmdSys=\"$cmd\"";
    ($Lok,$msg)=
	&sysRunProg($cmdSys,$fileOutScreenLoc,$fhSbrErr);
    return(&errSbrMsg("failed to run BLAST3 on ($fileInLoc)",$msg)) 
        if (! $Lok || ($fileOutLoc && ! -e $fileOutLoc));

    return(1,"ok $sbrName");
}				# end of blast3RunSimple

#===============================================================================
sub blastGetSummary {
    local($fileInLoc,$minLaliLoc,$minDistLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok,%hdrLoc,@idtmp,%tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   blastGetSummary             BLAST out -> summary: IDE,LALI,LEN,PROB,DISTANCE-to-hssp-curve
#       in:                     $fileInLoc    : file with BLAST output
#       in:                     $minLaliLoc   : take those with LALI > x      (=0: all)
#       in:                     $minDistLoc   : take those with $pide>HSSP+X  (=0: all)
#       out:                    1|0,msg,$tmp{}, with
#                               $tmp{"NROWS"}     : number of pairs
#                               $tmp{"id",$it}    : name of protein it
#                               $tmp{"len",$it}   : length of protein it
#                               $tmp{"lali",$it}  : length of alignment for protein it
#                               $tmp{"prob",$it}  : BLAST probability for it
#                               $tmp{"score",$it} : BLAST score for it
#                               $tmp{"pide",$it}  : pairwise percentage sequence identity
#                               $tmp{"dist",$it}  : distance from HSSP-curve
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."blastGetSummary";$fhinLoc="FHIN_"."blastGetSummary";
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
    return(&errSbr("miss in file '$fileInLoc'!"))  if (! -e $fileInLoc);
                                # adjust
    $minLaliLoc=0               if (! defined $minLaliLoc || ! $minLaliLoc);
    $minDistLoc=-100            if (! defined $minDistLoc || ! $minDistLoc);
                                # ------------------------------
                                # read file
                                # ------------------------------
    undef %hdrLoc;
    ($Lok,$msg,%hdrLoc)=   
        &blastpRdHdr($fileInLoc);
    return(&errSbrMsg("failed reading blast header ($fileInLoc)",$msg)) if (! $Lok);

    $hdrLoc{"id"}=~s/,*$//g;       # interpret
    @idtmp=split(/,/,$hdrLoc{"id"});
                                # ------------------------------
                                # loop over all pairs found
                                # ------------------------------
    undef %tmp; 
    $ct=0;
    foreach $idtmp (@idtmp) {
        next if ($hdrLoc{"$idtmp","lali"} < $minLaliLoc);
                                # compile distance to HSSP threshold (new)
        ($pideCurve,$msg)= 
#            &getDistanceHsspCurve($hdrLoc{"$idtmp","lali"});
            &getDistanceNewCurveIde($hdrLoc{"$idtmp","lali"});
        return(&errSbrMsg("failed getDistanceNewCurveIde",$msg))  
            if ($msg !~ /^ok/);
            
        $dist=$hdrLoc{"$idtmp","ide"}-$pideCurve;
        next if ($dist < $minDistLoc);
                                # is ok -> TAKE it
        ++$ct;
        $tmp{"id","$ct"}=       $idtmp;
	foreach $kwd ("len","lali","prob","score"){
	    $tmp{"$kwd","$ct"}= $hdrLoc{"$idtmp","$kwd"}; }
        $tmp{"pide","$ct"}=     $hdrLoc{"$idtmp","ide"};
        $tmp{"dist","$ct"}=     $dist;
    } 
    $tmp{"NROWS"}=$ct;

    undef %hdrLoc;                 # slim-is-in !
    return(1,"ok $sbrName",%tmp);
}				# end of blastGetSummary

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
    $sbrName="lib-br:"."blastpExtrId";$fhinLoc="FHIN"."$sbrName";
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
    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok,@idFoundLoc,
	  $Lread,$name,%hdrLoc,$Lskip,$id,$line);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   blastpRdHdr                 reads header of BLASTP output file
#       in:                     $fileBlast
#       out:                    (1,'ok',%hdrLoc)
#       out:                    $hdrLoc{$id}='id1,id2,...'
#       out:                    $hdrLoc{$id,"$kwd"} , with:
#                                  $kwd=(score|prob|ide|len|lali)
#       err:                    (0,'msg')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."blastpRdHdr";$fhinLoc="FHIN-blastpRdHdr";
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
		$hdrLoc{$id,"name"}=$name;}
	    else              {
		$Lskip=1;}}
				# length
	elsif (! $Lskip && ! defined $hdrLoc{$id,"len"} && 
	       ($line=~/^\s*Length = (\d+)/)) {
	    $hdrLoc{$id,"len"}=$1;}
				# sequence identity
	elsif (! $Lskip && ! defined $hdrLoc{$id,"ide"} &&
	       ($line=~/^\s* Identities = \d+\/(\d+) \((\d+)/) ) {
	    $hdrLoc{$id,"lali"}=$1;
	    $hdrLoc{"ide",$id}=$hdrLoc{$id,"ide"}=$2;}
				# score + prob (blast3)
	elsif (! $Lskip && ! defined $hdrLoc{$id,"score"} &&
	       ($line=~/ Score = [\d\.]+ bits \((\d+)\).*, Expect = \s*([\d\-\.e]+)/) ) {
	    $hdrLoc{$id,"score"}=$1;
	    $hdrLoc{$id,"prob"}= $2;}
				# score + prob (blast2)
	elsif (! $Lskip && ! defined $hdrLoc{$id,"score"} &&
	       ($line=~/ Score = (\d+)\s+[^,]*, Expect = ([^,]+), .*$/) ) {
	    $hdrLoc{$id,"score"}=$1;
	    $hdrLoc{$id,"prob"}= $2;}}close($fhinLoc);
				# ------------------------------
    $hdrLoc{"id"}="";		# arrange to pass the result
    for $id(@idFoundLoc){
	$hdrLoc{"id"}.="$id,"; } $hdrLoc{"id"}=~s/,*$//g;

    $#idFoundLoc=0;		# save space
    return(1,"ok $sbrName",%hdrLoc);
}				# end of blastpRdHdr 

#===============================================================================
sub blastpRun {
    local($niceLoc,$dirData,$dirSwissSplit,$exeBlastp,$exeBlastpFil,$envBlastpMat,
	  $envBlastpDb,$nhits,$parBlastpDb,$fileInLoc,$fileOutLoc,$fileOutFilLoc,$fhTraceLoc)=@_;
    local($sbr,$command,$msg,$Lok);
#----------------------------------------------------------------------
#   blastpRun                   runs BLASTP
#       in:                     $niceLoc,$dirData,$dirSwissSplit,$exeBlastp,$exeBlastpFil,
#       in:                     $envBlastpMat,$envBlastpDb,$numHits,$parBlastpDb,
#       in:                     $fileInLoc,$fileOutLoc,$fileOutFilLoc,$fhTraceLoc
#       out:                    
#       err:                    ok=(1,'ok'), err=(0,'msg')
#----------------------------------------------------------------------
    $sbr="lib-br:blastpRun";
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
    $command="$niceLoc $exeBlastp $parBlastpDb $fileInLoc B=$nhits > $fileOutLoc";
    $msg="--- $sbr '$command'\n";

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
    print "--- system: \t $command\n";
    
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
sub blastpRunSimple {
    local($fileInLoc,$fileOutLoc,$exeBlastpLoc,$dbBlastLoc,$parELoc,$parBLoc,
	  $fileOutScreenLoc,$fhSbrErr,$argBlastpLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   blastpRunSimple             simply runs BLASTP (blast2)
#                               NOTE: for security call &blastSetenv before running
#       in:                     $fileInLoc     : FASTA formatted input file
#       in:                     $fileOutLoc    : BLASTP output                if = 0: onto screen
#       in:                     $exeBlastLoc   : FORTRAN exe BLASTP           if = 0: default
#       in:                     $dbBlastLoc    : BLASTP db to run             if = 0: swiss
#       in:                     $parELoc       : BLASTP para E                if = 0: default
#       in:                     $parBLoc       : BLASTP para B                if = 0: default
#       in:                     $fileOutScreen : screen dumpb of system call  if = 0: 0 -> STDOUT
#       in:                     $fhSbrErr      : error file handle
#       in:                     $argBlastpLoc  : full BLAST argument
#       out:                    1|0,msg,  implicit: file
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."blastpRunSimple";$fhinLoc="FHIN_"."blastpRunSimple";
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
    return(&errSbr("miss in file '$fileInLoc'!"))  if (! -e $fileInLoc);
                                # ------------------------------
				# local defaults
    $exeBlastpLocDef=           "/nfs/data5/users/ppuser/server/pub/molbio/blastp.$ARCH";
    $dbBlastLocDef=             "swiss";
    $parELocDef=             1000;
    $parBLocDef=             2000;
    $argBlastpLoc=              0 if (! defined $argBlastpLoc);
                                # ------------------------------
				# check arguments
    $fileOutLoc=0               if (! defined $fileOutLoc);
    $exeBlastpLoc=$exeBlastpLocDef  if (! defined $exeBlastpLoc || ! $exeBlastpLoc);
    $dbBlastLoc=$dbBlastLocDef  if (! defined $dbBlastLoc || ! $dbBlastLoc);

    $parELoc=$parELocDef        if (! defined $parELoc    || ! $parELoc);
    $parBLoc=$parBLocDef        if (! defined $parBLoc    || ! $parBLoc);

				# full argument passed: correct
    if ($argBlastpLoc && $argBlastpLoc =~ /E=/){
	$parELoc=0;}
    if ($argBlastpLoc && $argBlastpLoc =~ /B=/){
	$parBLoc=0;}
				    

    $fhSbrErr="STDOUT"          if (! defined $fhSbrErr   || ! $fhSbrErr);
    $fileOutScreenLoc=0         if (! defined $fileOutScreenLoc || 
				    ! $fileOutScreenLoc   ||
				    ! $fileOutLoc);
    $cmdSys="";
				# ------------------------------
				# run BLAST
				# ------------------------------
    $cmd= $exeBlastpLoc." ".$dbBlastLoc." ".$fileInLoc;
    $cmd.=" E=$parELoc"         if ($parELoc);
    $cmd.=" B=$parBLoc"         if ($parBLoc);
    $cmd.=" ".$argBlastpLoc     if ($argBlastpLoc);
    $cmd.=" >> $fileOutLoc"     if ($fileOutLoc);

    eval "\$cmdSys=\"$cmd\"";
    ($Lok,$msg)=
	&sysRunProg($cmdSys,$fileOutScreenLoc,$fhSbrErr);
    return(&errSbrMsg("failed to run BLASTP on ($fileInLoc)",$msg)) 
	if (! $Lok || ($fileOutLoc && ! -e $fileOutLoc));

    return(1,"ok $sbrName");
}				# end of blastpRunSimple

#===============================================================================
sub blastpFormatdb {
    local($fileInLoc,$titleLoc,$exeFormatdbLoc,$fileOutScreenLoc,$fhSbrErr) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   blastpFormatdb              formats a db for BLASTP (blast 2)
#                               NOTE: automatically sets environment !!!
#       in:                     $fileInLoc     : FASTAmul formatted db file
#       in:                     $fileOutLoc    : BLASTP output                if = 0: onto screen
#       in:                     $exeBlastLoc   : FORTRAN exe BLASTP           if = 0: default
#       in:                     $fileOutScreen : screen dumpb of system call  if = 0: 0 -> STDOUT
#       in:                     $fhSbrErr      : error file handle
#       out:                    1|0,msg,$title : name of formatted db
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."blastpFormatdb";$fhinLoc="FHIN_"."blastpFormatdb";
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
    return(&errSbr("miss in file '$fileInLoc'!"))  if (! -e $fileInLoc);
                                # ------------------------------
				# local defaults
    $exeFormatdbLocDef=         "/nfs/data5/users/ppuser/server/pub/molbio/setdb.$ARCH";
                                # ------------------------------
				# check arguments
    $titleLoc=0                 if (! defined $titleLoc);
    $exeFormatdbLoc=$exeFormatdbLocDef 
                                if (! defined $exeFormatdbLoc || ! $exeFormatdbLoc);

    $fhSbrErr="STDOUT"          if (! defined $fhSbrErr || ! $fhSbrErr);
    $fileOutScreenLoc=0         if (! defined $fileOutScreenLoc || ! $fileOutScreenLoc);

    $cmdSys="";
				# ------------------------------
				# title and setenv BLASTDB
    if (! $titleLoc)     {	# ------------------------------
	$titleLoc=$fileInLoc;
	$titleLoc=~s/^.*\///g;}
    $tmp=$fileInLoc; $tmp=~s/^(.*)\/.*$/$1/g;
    if (length($tmp)<1 && defined $ENV{'PWD'})  { 
	$tmp=$ENV{'PWD'};}
    if (length($tmp) > 1){
	$tmp=~s/\/$//g;
	system("setenv BLASTDB $tmp");}
				# ------------------------------
				# run setdb (for BLASTP)
				# ------------------------------

                                # syntax 'formatdb.SGI32 -t TITLE DIR/fasta-file'
                                # note:  files will be created in DIR !
    $cmd= $exeFormatdbLoc." -t $titleLoc -i ".$fileInLoc;
    $cmd.=" >> $fileOutScreenLoc"     if ($fileOutScreenLoc);

    eval "\$cmdSys=\"$cmd\"";
    ($Lok,$msg)=
	&sysRunProg($cmdSys,$fileOutScreenLoc,$fhSbrErr);
    return(&errSbrMsg("failed to run FORMATDB on ($fileInLoc)",$msg)) 
        if (! $Lok || ($fileOutLoc && ! -e $fileOutLoc));

    return(1,"ok $sbrName",$titleLoc);
}				# end of blastpFormatdb

#===============================================================================
sub blastpsiMatRead {
    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   blastpsiMatRead             reads the PSI-BLAST matrix file
#       in:                     $fileInLoc
#                               
#       out GLOBAL:             %BLASTMAT with 
#                               $BLASTMAT{"NROWS"}= number of residues
#                               $BLASTMAT{"aa"}=    'ARNDCQEG...' all amino acids read
#                               $BLASTMAT{$itres,"seq"}= sequence read
#                               $BLASTMAT{$itres,$aa}=   profile for amino acid $aa
#                               
#                               
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."blastpsiMatRead";
    $fhinLoc="FHIN_"."blastpsiMatRead";
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
    return(&errSbr("no fileIn=$fileInLoc!"))  if (! -e $fileInLoc);
				# open file
    open($fhinLoc,$fileInLoc) || return(&errSbr("fileInLoc=$fileInLoc, not opened"));

				# ------------------------------
				# read file
    undef %tmp;
    $errMsg="";
    $ctline=0;
    $#aa=0;
    while (<$fhinLoc>) {	# 
	++$ctline;
	$_=~s/\n//g;
				# skip unused stuff
	next if ($_ =~ /^\s*$/     ||
		 $_ =~ /^Last/     ||
		 $_ =~ /^PSI/      ||
		 $_ =~ /^Standard/ ||
		 $_ =~ /^\s*K.*Lam/);
		 
				# line with amino acids used
				# '           A  R  N  D  C  Q  E  G  H  I  L  K  M  F  P  S  T  W  Y  V'
	if (! $#aa && $_=~/^\s+(A .*)$/){
	    $tmp=$1;
	    $tmp=~s/^s*|\s*$//g;
	    @aa=split(/\s+/,$tmp);
	    next; }
				# lines with info
				# '    1 G    0 -2  0 -1 -3 -2 -2  6 -2 -4 -4 -2 -3 -3 -2  0 -2 -2 -3 -3 '
	$_=~s/^\s*|\s*$//g;
	($num,$res,@tmp)=split(/\s+/,$_);
				# wrong number of columns found
	if ($#tmp != $#aa){
	    $errMsg="lineno=$ctline, naa expect=".$#aa.", columns read=".$#tmp.": ".join(',',@tmp,"\n");
	    next; }
	$tmp{$num,"seq"}=$res;
	print "xx line=$ctline, fine\n";
	foreach $it (1..$#tmp){
	    $tmp{$num,$aa[$it]}=$tmp[$it];
	}
    } close($fhinLoc);
				# ------------------------------
				# ERROR
    return(0,"*** ERROR $sbrName: failed reading BLAST matrix file=$fileInLoc!\n".
	   "   error messages:\n".$errMsg) if (length($errMsg)>2);

				# ------------------------------
				# ok
    $tmp{"NROWS"}=$num;
    $tmp{"aa"}=join('',@aa);
    %BLASTMAT=%tmp;
    undef %tmp;

    return(1,"ok $sbrName");
}				# end of blastpsiMatRead

#===============================================================================
sub blastSetenv {
    local($BLASTMATloc,$BLASTDBloc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   blastSetenv                 sets environment for BLASTP runs
#       in:                     $BLASTMAT,$BLASTDB (or default)
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."blastSetenv";$fhinLoc="FHIN_"."blastSetenv";
				# defaults
    $BLASTMATdef="/home/rost/oub/molbio/blast/blastapp/matrix";
    $BLASTDBdef= "/nfs/data5/users/ppuser/server/pub/molbio/db";
				# check arguments
    $BLASTMATloc=$BLASTMATdef   if (! defined $BLASTMATloc);
    $BLASTDBloc=$BLASTDBdef     if (! defined $BLASTDBloc);
				# existence
    if (! -d $BLASTMATloc && ($BLASTMATloc ne $BLASTMATdef)){
	print "-*- WARN $sbrName: changed env BLASTMAT from $BLASTMATloc to $BLASTMATdef\n" x 5;
	$BLASTMATloc=$BLASTMATdef; }
    if (! -d $BLASTDBloc  && ($BLASTDBloc ne $BLASTDBdef)){
	print "-*- WARN $sbrName: changed env BLASTDB from $BLASTDBloc to $BLASTDBdef\n" x 5;
	$BLASTDBloc=$BLASTDBdef; }
    return(&errSbr("BLASTMAT $BLASTMATloc not existing")) if (! -d $BLASTMATloc);
    return(&errSbr("BLASTDB  $BLASTDBloc not existing"))  if (! -d $BLASTDBloc);
				# ------------------------------
				# set env
#    system("setenv BLASTMAT $BLASTMATloc"); # system call
    $ENV{'BLASTMAT'}=$BLASTMATloc;

#    system("setenv BLASTDB $BLASTDBloc"); # system call
    $ENV{'BLASTDB'}=$BLASTDBloc;

    return(1,"ok $sbrName");
}				# end of blastSetenv

#===============================================================================
sub blastWrtSummary {
    local($fileOutLoc,%tmp) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   blastWrtSummary             writes summary for blast results (%ide,len,distance HSSP)
#       in:                     $fileOutLoc   (if = 0, written to STDOUT)
#       in:                     $tmp{} :
#                    HEADER:
#                               $tmp{"para","expect"}='para1,para2' 
#                               $tmp{"para","paraN"}   : value for parameter paraN
#                               $tmp{"form","paraN"}   : output format for paraN (default '%-s')
#                    DATA gen:
#                               $tmp{"NROWS"}        : number of proteins (it1)
#                               
#                               $tmp{$it1}             : number of pairs for it1
#                               $tmp{"id",$it1}        : name of protein it1
#                    DATA rows:
#                               $tmp{$it1,"id",$it2}   : name of protein it2 aligned to it1
#                               $tmp{$it1,"len",$it2}  : length of protein it2
#                               $tmp{$it1,"lali",$it2} : alignment length for it1/it2
#                               $tmp{$it1,"pide",$it2} : perc sequence identity for it1/it2
#                               $tmp{$it1,"dist",$it2} : distance from HSSP-curve for it1/it2
#                               $tmp{$it1,"prob",$it2} : BLAST prob for it1/it2
#                               $tmp{$it1,"score",$it2}: BLAST score for it1/it2
#                               
#                               $tmp{"form",$kwd}    : perl format for keyword $kwd
#                               $tmp{"sep"}            : separator for output columns
#                               
#       out:                    1|0,msg,  implicit: file
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."blastWrtSummary";$fhoutLoc="FHOUT_"."blastWrtSummary";
				# ------------------------------
				# defaults
				# ------------------------------
    $form{"id"}=   "%-15s";
    $form{"len"}=  "%5d";
    $form{"lali"}= "%4d";
    $form{"pide"}= "%5.1f";
    $form{"dist"}= "%5.1f";
    $form{"prob"}= "%6.3f";
    $form{"score"}="%5.1f";
    $sepLoc="\t";
    $sepLoc=$tmp{"sep"}         if (defined $tmp{"sep"});
				# ------------------------------
				# what do we have?
				# ------------------------------
    $#kwdtmp=0;
    push(@kwdtmp,"id")          if (defined $tmp{"1","id","1"});
    push(@kwdtmp,"len")         if (defined $tmp{"1","len","1"});
    push(@kwdtmp,"lali")        if (defined $tmp{"1","lali","1"});
    push(@kwdtmp,"pide")        if (defined $tmp{"1","pide","1"});
    push(@kwdtmp,"dist")        if (defined $tmp{"1","dist","1"});
    push(@kwdtmp,"prob")        if (defined $tmp{"1","prob","1"});
    push(@kwdtmp,"score")       if (defined $tmp{"1","score","1"});
				# ------------------------------
                                # format defaults
                                # ------------------------------
    foreach $kwd (@kwdtmp){
        $form{"$kwd"}=$tmp{"form","$kwd"} if (defined $tmp{"form","$kwd"}); }

				# ------------------------------
				# header defaults
				# ------------------------------
    $tmp2{"nota","id1"}=        "guide sequence";
    $tmp2{"nota","id2"}=        "aligned sequence";
    $tmp2{"nota","len"}=        "length of aligned sequence";
    $tmp2{"nota","lali"}=       "alignment length";
    $tmp2{"nota","pide"}=       "percentage sequence identity";
    $tmp2{"nota","dist"}=       "distance from new HSSP curve";
    $tmp2{"nota","prob"}=       "BLAST probability";
    $tmp2{"nota","score"}=      "BLAST raw score";

    $tmp2{"nota","expect"}="";
    foreach $kwd (@kwdtmp) {
        $tmp2{"nota","expect"}.="$kwd,";}
    $tmp2{"nota","expect"}=~s/,*$//g;

    $tmp2{"para","expect"}= "";
    $tmp2{"para","expect"}.=$tmp{"para","expect"}  if (defined $tmp{"para","expect"});
    foreach $kwd (split(/,/,$tmp2{"para","expect"})){	# import
	$tmp2{"para","$kwd"}=$tmp{"para","$kwd"};}
    $tmp2{"para","expect"}.=",PROTEINS";
    $tmp2{"para","PROTEINS"}=""; $tmp2{"form","PROTEINS"}="%-s";
    foreach $it1 (1..$tmp{"NROWS"}) {
        $tmp2{"para","PROTEINS"}.=$tmp{"id","$it1"}.",";}
    $tmp2{"para","PROTEINS"}=~s/,*$//g;
                                # --------------------------------------------------
                                # now write it
                                # --------------------------------------------------
    
				# open file
    if (! $fileOutLoc || $fileOutLoc eq "STDOUT"){
	$fhoutLoc="STDOUT";}
    else { &open_file("$fhoutLoc",">$fileOutLoc") || 
               return(&errSbr("fileOutLoc=$fileOutLoc, not created")); }
	    
				# ------------------------------
				# write header
				# ------------------------------
    if ($fhoutLoc ne "STDOUT"){
        ($Lok,$msg)=
	    &rdbGenWrtHdr($fhoutLoc,%tmp2);
	return(&errSbrMsg("failed writing RDB header (lib-br:rdbGenWrtHdr)",$msg)) if (! $Lok); }
    undef %tmp2;                # slim-is-in!

				# ------------------------------
				# write names
				# ------------------------------

    $formid=$form{"id"};
    $fin=""; $form=$formid;   $form=~s/(\d+)\.*\d*[dfs].*/$1/;$form.="s";
    $fin.= sprintf ("$form$sepLoc","id1"); 
    foreach $kwd (@kwdtmp) {$form=$form{"$kwd"}; 
			    $form=~s/(\d+)\.*\d*[dfs].*/$1/;$form.="s";
			    $kwd2=$kwd;
			    $kwd2="id2" if ($kwd eq "id");
                            $fin.= sprintf ("$form$sepLoc",$kwd2); }
    $fin=~s/$sepLoc$//;
    print $fhoutLoc "$fin\n";
				# ------------------------------
                                # write data
				# ------------------------------
    foreach $it1 (1..$tmp{"NROWS"}){
        $fin1=         sprintf ( "$formid$sepLoc",$tmp{"id","$it1"}) 
	    if (defined $tmp{"id","$it1"});

				# none above threshold
        if (! defined $tmp{"$it1"} || $tmp{"$it1"} == 0) {
	    $fin=$fin1;
	    $fin.=     sprintf ("$formid$sepLoc","none"); 
            foreach $kwd (@kwdtmp) { 
		next if ($kwd eq $kwdtmp[1]);
                $form=$form{"$kwd"}; $form=~s/(\.\d+)[FND]$|d$//gi;$form.="s";
                $fin.= sprintf ("$form$sepLoc",""); }
	    print $fhoutLoc $fin,"\n";
	    next;}
				# loop over all above
	foreach $it2 (1..$tmp{"$it1"}){
	    $fin=$fin1;
            $Lerror=0;
            foreach $kwd (@kwdtmp) { 
                if (! defined $tmp{"$it1","$kwd","$it2"}) {
                    $Lerror=1;
                    last; }
                $form=$form{"$kwd"};
                $fin.= sprintf ("$form$sepLoc",$tmp{"$it1","$kwd","$it2"}); }
            next if ($Lerror);
            $fin=~s/$sepLoc$//;
            print $fhoutLoc $fin,"\n";}}

    close($fhoutLoc)            if ($fhoutLoc ne "STDOUT");
    undef %form; undef %tmp;    # slim-is-in!
    return(1,"ok $sbrName");
}				# end of blastWrtSummary

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

#==============================================================================
sub coilsRun {
    local($fileInLoc,$fileOutLoc,$exeCoilsLoc,$metricLoc,$optOutLoc,
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
    return(0,"*** $sbrName: not def optOutLoc!")      if (! defined $optOutLoc);
    $fhErrSbr="STDOUT"                                if (! defined $fhErrSbr);
    $fileScreenLoc=0                                  if (! defined $fileScreenLoc);

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
    $an=                       "Y"; # weight for position a & d

    eval "\$cmd=\"$exeCoilsLoc,$fileInLoc,$fileOutLoc,$met,$an,$opt\"";

    ($Lok,$msg)=
	&sysRunProg($cmd,$fileScreenLoc,$fhErrSbr);

    return(0,"*** ERROR $sbrName: failed to create $fileOutLoc\n".$msg)
	if (! $Lok || ! -e $fileOutLoc);
    return(1,"ok $sbrName");
}				# end of coilsRun

#===============================================================================
sub dsspCheck {
    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   dsspCheck                   check whether or not DSSP ok
#       in:                     $fileInLoc:    DSSP file
#       out:                    1|0,msg,$Lok=1(if file ok) | 0 (if not)
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."dsspCheck";
    $fhinLoc="FHIN_"."dsspCheck";
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
    return(&errSbr("no fileIn=$fileInLoc!"))       if (! -e $fileInLoc && 
						       ! -l $fileInLoc );
				# ------------------------------
				# check DSSP file
    $Lok=0;
    open($fhinLoc,$fileInLoc) ||
	return(0,"*** ERROR $sbrName: fileIn=$fileInLoc, not opened\n",0);
    $len=0;
    while (<$fhinLoc>) {
	if ($_ =~ /^\s*(\d+).*NUMBER OF RESIDUES/){
	    $len=$1;
	    last; }
    }
    close($fhinLoc);

    return(1,"ok $sbrName",$len);
}				# end of dsspCheck

#===============================================================================
sub dsspRdSeqSecAcc {
    local($fileInLoc,$chnInLoc,$kwdInLoc) = @_ ;
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   dsspRdSeqSecAcc             reads DSSP file
#                               NOTE: chain breaks are skipped!!
#                               
#       in:                     $fileInLoc:  DSSP file
#       in:                     $chnInLoc:   chain to read (' ' if all)
#       in:                     $kwdInLoc:   seq,sec,acc(nodssp,nopdb): directs what to read!
#       out:                    1|0,msg
#                               
#       out GLOBAL:             %tmp{"NROWS"}=number of residues
#       out GLOBAL:             $tmp{$ct,"chn|seq|sec|acc|nodssp|nopdb"} respective values
#       out GLOBAL:             $tmp{<header|compnd|source|author>}
#                               
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."dsspRdSeqSecAcc";
    $fhinLoc="FHIN_"."dsspRdSeqSecAcc";$fhoutLoc="FHOUT_"."dsspRdSeqSecAcc";
				# ------------------------------
				# check arguments
    return(&errSbr("not def fileInLoc!"))     if (! defined $fileInLoc);
    return(&errSbr("not def chnInLoc!"))      if (! defined $chnInLoc);
    $kwdInLoc="seq,sec,acc"                   if (! defined $kwdInLoc);
				# ------------------------------
				# file existing?
    return(&errSbr("no fileIn=$fileInLoc!"))  if (! -e $fileInLoc && ! -l $fileInLoc);
				# ------------------------------
				# local settings
    $#kwdTmp=0;
    push(@kwdTmp,"seq")         if ($kwdInLoc=~/seq/);
    push(@kwdTmp,"sec")         if ($kwdInLoc=~/sec/);
    push(@kwdTmp,"acc")         if ($kwdInLoc=~/acc/);
    push(@kwdTmp,"nodssp")      if ($kwdInLoc=~/nodssp/);
    push(@kwdTmp,"nopdb")       if ($kwdInLoc=~/nopdb/);

				# ------------------------------
				# open file
    open($fhinLoc,$fileInLoc) || return(&errSbr("fileInLoc=$fileInLoc, not opened"));

    undef %tmp;
				# ------------------------------
				# read HEADER
    while (<$fhinLoc>) {
				# stop header
	last if ($_=~/^\s*\#\s*RESIDUE/);

	$line=$_; $line=~s/\n//g;

	if ($line=~/HEADER\s+(\S.+)$/){
	    $tmp{"header"}=$1;
				# remove '  16-JAN-81   1PPT '
	    $tmp{"header"}=~s/\s+\d\d....\-\d+\s+\d...\s*$//g;
	    next; }

	if ($line=~/COMPND\s+(\S.+)$/){
	    $tmp{"compnd"}=$1;
	    $tmp{"compnd"}=~s/^\s*|\s*$//g;
	    next; }
	if ($line=~/SOURCE\s+(\S.+)$/){
	    $tmp{"source"}=$1;
	    $tmp{"source"}=~s/^\s*|\s*$//g;
	    next; }
	if ($line=~/AUTHOR\s+(\S.+)$/){
	    $tmp{"author"}=$1;
	    $tmp{"author"}=~s/^\s*|\s*$//g;
	    next; }
	if ($line=~/^\s*(\d+)\s*(\d+).*TOTAL NUMBER OF RESIDUES/){
	    $tmp{"NROWS"}= $1;
	    $tmp{"nres"}=  $tmp{"NROWS"};
	    $tmp{"nchn"}=  $2;
	    next; }
    }

				# ------------------------------
				# read file body
    $ctres=0;
    while (<$fhinLoc>) {	# 
	$line=$_; $line=~s/\n//g;
				# all we need in first 40
	undef %tmp2;
	$line=          substr($line,1,40);
	$chn=           substr($line,12,1);

				# skip since chain not wanted?
	next if ($chnInLoc ne " " && 
		 $chn ne $chnInLoc);

	$tmp2{"seq"}=   substr($line,14,1);
				# skip chain breaks
	next if ($tmp2{"seq"} eq "!");

	$tmp2{"nodssp"}=substr($line,1,5); $tmp2{"nodssp"}=~s/\s//g;
	$tmp2{"nopdb"}= substr($line,6,5); $tmp2{"nopdb"}=~s/\s//g;

	$tmp2{"sec"}=   substr($line,17,1);$tmp2{"sec"}=~s/ /L/;
	$tmp2{"acc"}=   substr($line,36,3);$tmp2{"acc"}=~s/\s//g;
	++$ctres;
	foreach $kwd (@kwdTmp){
	    $tmp{$ctres,$kwd}=$tmp2{$kwd};
	}
	$tmp{$ctres,"chn"}=   $chn;
    }

				# correct number of residues
    $tmp{"nres"}=  
	$tmp{"NROWS"}=
	    $ctres;
				# clean up
    undef %tmp2;		# slim-is-in
    $#kwdTmp=0;			# slim-is-in
    
    return(1,"ok $sbrName");
}				# end of dsspRdSeqSecAcc

#===============================================================================
sub dsspRun {
    local($fileInLoc,$fileOutLoc,$exeDsspLoc,$optNiceLoc) = @_ ;
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   dsspRun                     run DSSP
#       in:                     $fileInLoc:    PDB input file
#       in:                     $fileOutLoc:   DSSP output file
#       in:                     exeDsspLoc:    DSSP binary
#       in:                     optNiceLoc:    nice value (nice -19)
#       in:                     
#       in:                     
#       out:                    1|0,msg,$Lok=1(if file ok) | 0 (if not)
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."dsspRun";
    $fhinLoc="FHIN_"."dsspRun";$fhoutLoc="FHOUT_"."dsspRun";
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
    return(&errSbr("not def fileOutLoc!"))         if (! defined $fileOutLoc);
    return(&errSbr("not def exeDsspLoc!"))         if (! defined $exeDsspLoc);
    $optNiceLoc=""                                 if (! defined $optNiceLoc ||
						       $optNiceLoc =~ /nice\S/);
#    return(&errSbr("not def !"))          if (! defined $);

    return(&errSbr("no fileIn=$fileInLoc!"))       if (! -e $fileInLoc && 
						       ! -l $fileInLoc );

				# local settings
    $exeDsspDef="/home/rost/molbio/bin/dssp.SGI64";
    $exeDsspLoc=$exeDsspDef     if (! -e $exeDsspLoc && ! -l $exeDsspLoc);

				# ------------------------------
				# missing executable
    return(&errSbr("no exeDsspLoc=$exeDsspLoc!"))       
	if (! -e $exeDsspLoc && ! -l $exeDsspLoc);

    $fileOutScreenLoc=0         if (! defined $fileOutScreenLoc);
    $fileOutScreenLoc=
	$par{"fileOutScreen"}   if (! $fileOutScreenLoc && defined $par{"fileOutScreen"});
    $FHTRACE="STDOUT"           if (! defined $FHTRACE);

    $cmd=$optNiceLoc." ".$exeDsspLoc." ".$fileInLoc." ".$fileOutLoc;
    ($Lok,$msg)=
	&sysRunProg($cmd,$fileOutScreenLoc,
		    $FHTRACE);  return(&errSbrMsg("failed on system '$cmd'",$msg)) if (! $Lok);

    return(0,"*** ERROR $sbrName: missing $fileOutLoc (from $fileInLoc)")
	if (! -e $fileOutLoc);

    return(1,"ok $sbrName");
}				# end of dsspRun

#===============================================================================
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
    $sbr="lib-br:fastaRun";
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

#===============================================================================
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
    $sbrName="lib-br:maxhomCheckHssp";
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

#===============================================================================
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

#===============================================================================
sub maxhomGetArg2 {
    local($niceLoc,$exeMaxLoc,$fileDefaultLoc,$jobid,$fileMaxIn,$fileMaxList,$Lprofile,
	  $fileMaxMetric,$paraMaxSmin,$paraMaxSmax,$paraMaxGo,$paraMaxGe,
	  $paraMaxWeight1,$paraMaxWeight2,$paraMaxIndel1,$paraMaxIndel2,
	  $paraMaxNali,$paraMaxThresh,$paraMaxSort,$paraMaxProfileOut,
	  $paraMaxSuperpos,$dirMaxPdb,$fileHsspOut,$fileStripOut,$fileHsspOutX)=@_;
    local ($command);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   maxhomGetArg2                gets the input arguments to run MAXHOM
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
#         $paraMaxProfileOut    NO| ?
#         $paraMaxSuperpos      NO|YES  : also computes r.m.s.d. values
#         $dirMaxPdb            path of PDB directory
#                               
#         $fileHsspOut          NO|name of output file (.hssp)
#         $fileStripOut         NO|file name of strip file
#         $fileHsspOutX         NO|file name of long output file (.x)
#       out:                    $command
#--------------------------------------------------------------------------------
				# ------------------------------
				# digest nice level
				# ------------------------------
    $tmpNice=$niceLoc;
    if ($tmpNice =~ /\d/ || $tmpNice eq "nice"){
	$tmpNice=~s/nice|[ -]//g; 
	$tmpNice=19 if (length($tmpNice)<1);
	if ($exeMaxLoc =~/ALPHA/){ $tmpNice="nice -".$tmpNice;}
	else                     { $tmpNice="nice -".$tmpNice;}}
				# ------------------------------
				# digest input options
				# ------------------------------
    $Lprofile=          "NO"    if ($Lprofile eq "0");
    $Lprofile=         "YES"    if ($Lprofile eq "1");

    $paraMaxWeight1=    "NO"    if ($paraMaxWeight1 eq "0");
    $paraMaxWeight1=   "YES"    if ($paraMaxWeight1 eq "1");
    $paraMaxWeight2=    "NO"    if ($paraMaxWeight2 eq "0");
    $paraMaxWeight2=   "YES"    if ($paraMaxWeight2 eq "1");

    $paraMaxIndel1=     "NO"    if ($paraMaxIndel1 eq "0");
    $paraMaxIndel1=    "YES"    if ($paraMaxIndel1 eq "1");
    $paraMaxIndel2=     "NO"    if ($paraMaxIndel2 eq "0");
    $paraMaxIndel2=    "YES"    if ($paraMaxIndel2 eq "1");

    $paraMaxProfileOut= "NO"    if ($paraMaxProfileOut eq "0");
    $paraMaxProfileOut="YES"    if ($paraMaxProfileOut eq "1");

    $paraMaxSuperpos=   "NO"    if ($paraMaxSuperpos eq "0");
    $paraMaxSuperpos=  "YES"    if ($paraMaxSuperpos eq "1");

    $fileStripOut=      "NO"    if (! $fileStripOut);
    $fileHsspOutX=      "NO"    if (! $fileHsspOutX);

				# ------------------------------
				# maxhom command
				# ------------------------------

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
         SUPERPOS      $paraMaxSuperpos ,
         PDB_PATH      $dirMaxPdb ,
         PROFILE_OUT   $paraMaxProfileOut ,
         STRIP_OUT     $fileStripOut ,
         LONG_OUT      $fileHsspOutX ,
         DOT_PLOT      NO ,
         RUN ,\"";
    return ($command);
}				# end maxhomGetArg2

#===============================================================================
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

#===============================================================================
sub maxhomGetThresh {
    local($ideIn)=@_;
    local($tmp,$thresh_txt);
    $[ =1 ;
#----------------------------------------------------------------------
#   maxhomGetThresh             translates cut-off ide into text input for MAXHOM csh
#       in:                     $ideIn (= distance to FORMULA, old)
#       out:                    $txt 'FORMULA+/-n'
#----------------------------------------------------------------------
				# final txt for MAXHOM cshell (FORMULA,FORMULA-n,FORMULA+n)
    if   ($ideIn>25) {
	$tmp=$ideIn-25;
	$thresh_txt="FORMULA+"."$tmp"; }
    elsif($ideIn<25) {
	$tmp=25-$ideIn;
	$thresh_txt="FORMULA-"."$tmp"; }
    else {
	$thresh_txt="FORMULA"; }
    return($thresh_txt);
}				# end of maxhomGetThresh

#===============================================================================
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
    $sbrName="lib-br:maxhomMakeLocDef";
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

#===============================================================================
sub maxhomRun {
    local($date,$nice,$LcleanUpLoc,$fhErrSbr,
	  $fileSeqLoc,$fileSeqFasta,$fileBlast,$fileBlastFil,$fileHssp,
	  $dirData,$dirSwiss,$dirPdb,$exeConvSeq,$exeBlastp,$exeBlastpFil,$exeMax,
	  $envBlastpMat,$envBlastpDb,$parBlastpNhits,$parBlastpDb,
	  $fileMaxDef,$fileMaxMetr,$Lprof,$parMaxThresh,$parMaxSmin,$parMaxSmax,
	  $parMaxGo,$parMaxGe,$parMaxW1,$parMaxW2,$parMaxI1,$parMaxI2,$parMaxNali,
	  $parMaxSort,$parMaxProfOut,$parMaxStripOut,$parMinLaliPdb,$parMaxTimeOut,
	  $fileScreenLoc)=@_;
    local($sbrName,$tmp,$Lok,$jobid,$msgHere,$msg,$thresh,@fileTmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   maxhomRun                   runs Maxhom (looping for many trials + self)
#       in:                     give 'def' instead of argument for default settings
#       out:                    (0,'error','txt') OR (1,'ok','name')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."maxhomRun";

    $date=&sysDate()            if (! defined $date);
	
    $nice=" "                                              if (! defined $nice || $nice eq "def");
    $fhTraceLoc="STDOUT"                                   if (! defined $fhTraceLoc);
    return(0,"*** $sbrName: not def GLOBAL: ARCH!")        if (! defined $ARCH);
				# ------------------------------
				# input file names
    return(0,"*** $sbrName: not def fileSeqLoc!")          if (! defined $fileSeqLoc);
    return(0,"*** $sbrName: not def LcleanUpLoc!")         if (! defined $LcleanUpLoc);
				# ------------------------------
				# temporary files (defaults)
    $jobid=$$;$id=$fileSeqLoc;$id=~s/^.*\///g;$id=~s/\..*$//g;$id=~s/\s//g;
    $fileSeqFasta="MAX-".$jobid."-".$id.".seqFasta"
	                              if (! defined $fileSeqFasta   || $fileSeqFasta   eq "def");
    $fileBlast=   "MAX-".$jobid."-".$id.".blast"
	                              if (! defined $fileBlast      || $fileBlast      eq "def");
    $fileBlastFil="MAX-".$jobid."-".$id.".blastFil"
	                              if (! defined $fileBlastFil   || $fileBlastFil   eq "def");
    $fileHssp=    "MAX-".$jobid."-".$id.".hssp"
	                              if (! defined $fileHssp       || $fileHssp       eq "def");
				# ------------------------------
				# default settings
    $dirData=       "/data"           if (! defined $dirData        || $dirData        eq "def");
    $dirSwiss=      "/data/swissprot" if (! defined $dirSwiss       || $dirSwiss       eq "def");
    $dirPdb=        "/data/pdb"       if (! defined $dirPdb         || $dirPdb         eq "def");
    $exeConvSeq=    "/nfs/data5/users/ppuser/server/pub/phd/bin/convert_seq.".$ARCH 
	                              if (! defined $exeConvSeq     || $exeConvSeq     eq "def");
    $exeBlastp=     "/home/phd/bin/".  $ARCH."/blastp"
	                              if (! defined $exeBlastp      || $exeBlastp      eq "def");
    $exeBlastpFil=  "/nfs/data5/users/ppuser/server/pub/max/scr/filter_blastp" 
                                      if (! defined $exeBlastpFil   || $exeBlastpFil   eq "def");
    $exeMax=        "/nfs/data5/users/ppuser/server/pub/max/bin/maxhom.".$ARCH
                                      if (! defined $exeMax         || $exeMax         eq "def");
    $envBlastpMat=  "/home/pub/molbio/blast/blastapp/matrix"  
                                      if (! defined $envBlastpMat   || $envBlastpMat   eq "def");
    $envBlastpDb=   "/data/db/"       if (! defined $envBlastpDb    || $envBlastpDb    eq "def");
    $parBlastpNhits="2000"            if (! defined $parBlastpNhits || $parBlastpNhits eq "def");
    $parBlastpDb=   "swiss"           if (! defined $parBlastpDb    || $parBlastpDb    eq "def");
    $fileMaxDef=    "/nfs/data5/users/ppuser/server/pub/max/maxhom.default" 
	                              if (! defined $fileMaxDef     || $fileMaxDef     eq "def");
    $fileMaxMetr=   "/nfs/data5/users/ppuser/server/pub/max/mat/Maxhom_GCG.metric" 
	                              if (! defined $fileMaxMetr    || $fileMaxMetr    eq "def");
    $Lprof=         "NO"              if (! defined $Lprof          || $Lprof          eq "def");
    $parMaxThresh= 30                 if (! defined $parMaxThresh   || $parMaxThresh   eq "def");
    $parMaxSmin=   -0.5               if (! defined $parMaxSmin     || $parMaxSmin     eq "def");
    $parMaxSmax=    1.0               if (! defined $parMaxSmax     || $parMaxSmax     eq "def");
    $parMaxGo=      3.0               if (! defined $parMaxGo       || $parMaxGo       eq "def");
    $parMaxGe=      0.1               if (! defined $parMaxGe       || $parMaxGe       eq "def");
    $parMaxW1=      "YES"             if (! defined $parMaxW1       || $parMaxW1       eq "def");
    $parMaxW2=      "NO"              if (! defined $parMaxW2       || $parMaxW2       eq "def");
    $parMaxI1=      "YES"             if (! defined $parMaxI1       || $parMaxI1       eq "def");
    $parMaxI2=      "NO"              if (! defined $parMaxI2       || $parMaxI2       eq "def");
    $parMaxNali=  500                 if (! defined $parMaxNali     || $parMaxNali     eq "def");
    $parMaxSort=    "DISTANCE"        if (! defined $parMaxSort     || $parMaxSort     eq "def");
    $parMaxProfOut= "NO"              if (! defined $parMaxProfOut  || $parMaxProfOut  eq "def");
    $parMaxStripOut="NO"              if (! defined $parMaxStripOut || $parMaxStripOut eq "def");
    $parMinLaliPdb=30                 if (! defined $parMinLaliPdb  || $parMinLaliPdb  eq "def");
    $parMaxTimeOut= "50000"           if (! defined $parMaxTimeOut  || $parMaxTimeOut  eq "def");
				# ------------------------------
				# check existence of files/dirs
    return(0,"*** $sbrName: miss in dir '$dirData'!")      if (! -d $dirData);
    return(0,"*** $sbrName: miss in dir '$dirSwiss'!")     if (! -d $dirSwiss);
    return(0,"*** $sbrName: miss in dir '$dirPdb'!")       if (! -d $dirPdb);
    return(0,"*** $sbrName: miss in dir '$envBlastpMat'!") if (! -d $envBlastpMat);
    return(0,"*** $sbrName: miss in dir '$envBlastpDb'!")  if (! -d $envBlastpDb);

    return(0,"*** $sbrName: miss in file '$fileSeqLoc'!")  if (! -e $fileSeqLoc &&
							       ! -l $fileSeqLoc);
    return(0,"*** $sbrName: miss in file '$exeConvSeq'!")  if (! -e $exeConvSeq &&
							       ! -l $exeConvSeq);
    return(0,"*** $sbrName: miss in file '$exeBlastp'!")   if (! -e $exeBlastp &&
							       ! -l $exeBlastp);
    return(0,"*** $sbrName: miss in file '$exeBlastpFil'!")if (! -e $exeBlastpFil &&
							       ! -l $exeBlastpFil);
    return(0,"*** $sbrName: miss in file '$fileMaxDef'!")  if (! -e $fileMaxDef &&
							       ! -l $fileMaxDef);
    return(0,"*** $sbrName: miss in file '$fileMaxMetr'!") if (! -e $fileMaxMetr &&
							       ! -l $fileMaxMetr);
    $fileScreenLoc=0                                       if (! defined $fileScreenLoc);

    print "\n"."*** WARN $sbrName: fileBlastFilter=$fileBlastFil must end with 'list'\n"."\n" x 50, "\n"
	if ($fileBlastFil !~ /list$/);
    $msgHere="--- $sbrName started\n";
    $#fileTmp=0;
				# ------------------------------
				# security convert_seq -> FASTA
    if (! &isFasta($fileSeqLoc)){
	$msgHere.="\n--- $sbrName \t call fortran convert_seq ($exeConvSeq,".
	    $fileSeqLoc.",".$fileSeqFasta.",$fhErrSbr)\n";
	($Lok,$msg)=		# call FORTRAN shit to convert to FASTA
	    &convSeq2fasta($exeConvSeq,$fileSeqLoc,$fileSeqFasta,$fhErrSbr);
				# conversion failed!
	return(0,"wrong conversion (convSeq2fasta)\n".
	       "*** $sbrName: fault in convert_seq ($exeConvSeq)\n$msg\n"."$msgHere")
	    if    ( ! $Lok || ! -e $fileSeqFasta);
	push(@fileTmp,$fileSeqFasta) if ($LcleanUpLoc); }
    else {
	$fileSeqFasta=$fileSeqLoc; }

# 	($Lok,$msg)=
# 	    &fileCp($fileSeqLoc,$fileSeqFasta,$fhErrSbr);
# 	return(0,"*** ERROR $sbrName '&fileCp($fileSeqLoc,$fileSeqFasta,$fhErrSbr)'\n".
# 	       "*** $sbrName: fault in convert_seq ($exeConvSeq)\n"."$msg\n"."$msgHere") 
# 	    if (! $Lok);}
				# --------------------------------------------------
                                # pre-filter to speed up MaxHom (BLAST)
				# --------------------------------------------------
    $msgHere.="\n--- $sbrName \t run BLASTP ($dirData,$dirSwiss,$exeBlastp,$exeBlastpFil,".
	"$envBlastpMat,$envBlastpDb,$parBlastpNhits,$parBlastpDb,".
	    $fileSeqLoc.",".$fileBlast.",".$fileBlastFil.",$fhErrSbr)\n";

    ($Lok,$msg)=
	&blastpRun($nice,$dirData,$dirSwiss,$exeBlastp,$exeBlastpFil,
		   $envBlastpMat,$envBlastpDb,$parBlastpNhits,$parBlastpDb,
		   $fileSeqFasta,$fileBlast,$fileBlastFil,$fhErrSbr);
    

    return(0,"*** $sbrName: after blastpRun $msg"."\n"."$msgHere")
	if (! $Lok || ! -e $fileBlastFil);

    push(@fileTmp,$fileBlast,$fileBlastFil) if ($LcleanUpLoc);

				# --------------------------------------------------
				# now run MaxHom
				# --------------------------------------------------
    $thresh=
	&maxhomGetThresh($parMaxThresh); # get the threshold
				# ------------------------------
				# get the arguments for the MAXHOM csh
#    $msgHere.="\n--- $sbrName \t run maxhomRunLoop($date,$nice,$exeMax,$fileMaxDef,$jobid,".
    $msgHere2="\n--- $sbrName \t run maxhomRunLoop($date,$nice,$exeMax,$fileMaxDef,$jobid,".
	"$jobid,$fileSeqFasta,$fileBlastFil,$fileHssp,$fileMaxMetr,$dirPdb,$Lprof,$parMaxSmin,".
	    "$parMaxSmax,$parMaxGo,$parMaxGe,$parMaxW1,$parMaxW2,$parMaxI1,$parMaxI2,".
		"$parMaxNali,$thresh,$parMaxSort,$parMaxProfOut,$parMaxStripOut,".
		    "$parMinLaliPdb,parMaxTimeOut,$fhErrSbr,$fileScreenLoc)\n";
				# ------------------------------------------------------------
				# now run it (will also run Self if missing output
				# note: if pdbidFound = 0, then none found!
    ($Lok,$pdbidFound)=
	&maxhomRunLoop($date,$nice,$exeMax,$fileMaxDef,$jobid,$fileSeqFasta,$fileBlastFil,$fileHssp,
		       $fileMaxMetr,$dirPdb,$Lprof,$parMaxSmin,$parMaxSmax,$parMaxGo,$parMaxGe,
		       $parMaxW1,$parMaxW2,$parMaxI1,$parMaxI2,$parMaxNali,$thresh,$parMaxSort,
		       $parMaxProfOut,$parMaxStripOut,$parMinLaliPdb,
		       $parMaxTimeOut,$fhErrSbr,$fileScreenLoc);
				# enf of Maxhom
				# ------------------------------------------------------------
    
    return(0,"error","*** ERROR $sbrName maxhomRunLoop failed, pdbidFound=$pdbidFound\n".
	   $msgHere2."\n")      if (! $Lok);
    
    return(0,"error","*** ERROR $sbrName maxhomRunLoop no $fileHssp, ".
	   "pdbidFound=$pdbidFound\n".$msgHere2."\n") if (! -e $fileHssp);
    if ($LcleanUpLoc){
	foreach $file(@fileTmp){
	    next if (! -e $file);
	    unlink ($file) ; $msgHere.="--- $sbrName: unlink($file)\n";}
	system("\\rm MAX*$jobid");
	$msgHere.="--- $sbrName: system '\\rm MAX*$jobid'\n" ;}
    return(1,"ok","$sbrName\n".$msgHere);
}				# end of maxhomRun

#===============================================================================
sub maxhomRunLoop {
    local ($date,$niceL,$exeMaxL,$fileMaxDefL,$fileJobIdL,
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

#	$Lok=
#	    &run_program($maxCmdL,$fhTraceLoc); # its running!

	($Lok,$msg)=
	    &sysRunProg($maxCmdL,$fileScreenLoc,$fhTraceLoc);

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

#===============================================================================
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
    $sbrName="lib-br:maxhomRunSelf";
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

#===============================================================================
sub mviewRun {
    local($fileInLoc,$chainInLoc,$exeMviewLoc,$parStandard,
	  $fileOut,$optOut,$fhoutSbr)=@_;
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   mviewRun                    runs MView (Nigel Brown) on an alignment
#            COPYRIGHT          Nigel Brown
#            QUOTE              N P Brown, C Leroy, C Sander (1998), Bioinformatics. 14(4):380-381
#                               (MView: A Web compatible database search or multiple alignment viewer)
#       in:                     $fileInLoc=       file with alignment (format recognised by extension)
#       in:                     $chainInLoc=      chain for HSSP format (otherwise=0)
#                                  =0             not used
#       in:                     $exeMview=        executable (perl)
#       in:                     $paraStandard=    standard parameters
#                                   =0            for standard setting
#       in:                     $fileOut=         name of output file
#                                  =0             -> will name it
#       in:                     $optOut=          HTML option <body|data|title>
#                                  =0             full HTML page
#       in:                     $fhoutSbr=        file handle to write system call
#                                  =0             no output reported
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."mviewRun";
    $fhinLoc="FHIN_"."mviewRun";$fhoutLoc="FHOUT_"."mviewRun";
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
    return(&errSbr("not def chainInLoc!"))         if (! defined $chainInLoc);
    return(&errSbr("not def exeMviewLoc!"))        if (! defined $exeMviewLoc);
    return(&errSbr("not def parStandard!"))        if (! defined $parStandard);
    return(&errSbr("not def fileOut!"))            if (! defined $fileOut);
    $optOut=0                                      if (! defined $optOut);
    $fhoutSbr=0                                    if (! defined $fhoutSbr);
#    return(&errSbr("not def !"))          if (! defined $);

    return(&errSbr("no fileIn=$fileInLoc!"))       if (! -e $fileInLoc);
    return(&errSbr("no fileIn=$exeMviewLoc!"))     if (! -e $exeMviewLoc && !-l $exeMviewLoc);
				# local defaults
    if (! $parStandard) {
	$parStandard= "-css on -srs on";
	$parStandard.=" -html head -ruler on";
	$parStandard.=" -coloring consensus -threshold 50 -consensus on -con_coloring any";}

    $LisHssp=0;
    $LisHssp=1                  if ($fileInLoc=~/\.hssp/);

    $cmd= $exeMviewLoc." ".$parStandard." ";

				# ------------------------------
				# HSSP input
    if    ($LisHssp) {
	$cmd.=" -in hssp"; 
	$cmd.=" -chain $chainInLoc"
	    if (defined $chainInLoc && $chainInLoc && $chainInLoc =~ /^[0-9A-Z]$/); }
				# MSF input
    elsif ($fileIn=~/\.msf/) {
	$cmd.=" -in msf"; }
				# unk input format
    else {
	return(0,"*** WARN $scrName: skipped $fileInLoc, since format unk\n"); }

				# ------------------------------
				# output
    if (! $fileOutLoc) {
	$fileOutLoc=$fileInLoc; 
				# purge dirs for data bases asf
	$fileOutLoc=~s/^.*\///g if (! -w $fileInLoc);

	$fileOutLoc=~s/\.(hssp|msf).*$//g;
	$fileOutLoc.=".html_mview"; }

				# security 1: same as input?
    $fileOut="mview_of".$fileInLoc.".html" if ($fileOutLoc eq $fileInLoc);
				# security 2: delete if exists
    if (-e $fileOutLoc) { 
	print "-*- WARN $sbrName deletes file $fileOutLoc\n";
	unlink($fileOutLoc); }
				# full HTML page?
    $cmd.=" -html $optOut"
	if ($optOut);
				# finally add input file
    $cmd.=" $fileInLoc";
				# past into output file!
    $cmd.=" >> $fileOutLoc";

				# ------------------------------
				# run program
    ($Lok,$msg)=
	&sysSystem("$cmd",$fhoutSbr);

    return(0,"*** ERROR $scrName: failed on mview (from $fileIn):\n".$msg."\n")
	if (! $Lok);
		  
    return(1,$fileOutLoc);
}				# end of mviewRun

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
    $sbrName="lib-br:prodomRun";$fhinLoc="FHIN"."$sbrName";
				# ------------------------------
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc!")          if (! defined $fileInLoc);
    return(0,"*** $sbrName: not def fileOutTmpLoc!")      if (! defined $fileOutTmpLoc);
    return(0,"*** $sbrName: not def fileOutLoc!")         if (! defined $fileOutLoc);
    $fhErrSbr=   "STDOUT"                                 if (! defined $fhErrSbr);
    $niceLoc=    " "                                      if (! defined $niceLoc);
    $exeBlast=   "/usr/pub/bin/molbio/blastp"             if (! defined $exeBlast);
    $envBlastDb= "/nfs/data5/users/ppuser/server/pub/ncbi/db/"                if (! defined $envBlastDb);
    $envBlastMat="/home/pub/molbio/blast/blastapp/matrix" if (! defined $envBlastMat);
    $parBlastDb= "/nfs/data5/users/ppuser/server/pub/ncbi/db/prodom"          if (! defined $parBlastDb);
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
    $cmd=  "$niceLoc $exeBlast $dbTmp $fileInLoc E=$parBlastE B=$parBlastN >> $fileOutTmpLoc ";
    $cmd=  "$exeBlast $dbTmp $fileInLoc E=$parBlastE B=$parBlastN >> $fileOutTmpLoc ";
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
	push(@idTake,$id) if (defined $head{$id,"prob"} && 
			      $head{$id,"prob"} <= $parBlastP);}
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
    return(0,"*** $sbrName: no in file '$fileInLoc'!")  if (! -e $fileInLoc &&
							    ! -l $fileInLoc);
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
sub segRun {
    local($fileInLoc,$fileOutLoc,$exeSegLoc,$cmdSegLoc,
	  $modeSegLoc,$winSegLoc,$locutSegLoc,$hicutSegLoc,$optSegLoc,$fhSbrErr)=@_;
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   segRun                      runs the Wootton program SEG on one FASTA sequence
#                               the following parameters can be set:
#
#         <window> - OPTIONAL window size (default 12) 
#         <locut>  - OPTIONAL low (trigger) complexity (default 2.2) 
#         <hicut>  - OPTIONAL high (extension) complexity (default 2.5) 
#         <options> 
#            -x  each input sequence is represented by a single output 
#                sequence with low-complexity regions replaced by 
#                strings of 'x' characters 
#            -c <chars> number of sequence characters/line (default 60)
#            -m <size> minimum length for a high-complexity segment 
#                (default 0).  Shorter segments are merged with adjacent 
#                low-complexity segments 
#            -l  show only low-complexity segments (fasta format) 
#            -h  show only high-complexity segments (fasta format) 
#            -a  show all segments (fasta format) 
#            -n  do not add complexity information to the header line 
#            -o  show overlapping low-complexity segments (default merge) 
#            -t <maxtrim> maximum trimming of raw segment (default 100) 
#            -p  prettyprint each segmented sequence (tree format) 
#            -q  prettyprint each segmented sequence (block format) 
#                               e.g. globular W=45 3.4 3.75  (for coiled-coil)
#                                    globular W=25 3.0 3.30  (for histones)
#                               
#       NOTE: for input options give '0' to take defaults!                       
#                               
#       in:                     $fileInLoc : input sequence (FASTA format!)
#       in:                     $fileOutLoc: output of SEG
#                          NOTE: = 0 -> STDOUT!
#       in:                     $exeSegLoc : executable for SEG
#       in:                     $cmdSegLoc : =0 or entire command line to run SEG.ARCH!!
#       in:                     $modeSegLoc: 'norm|glob'
#                                            norm  -> win = 12
#                                            glob-> win = 30
#       in:                     $winSegLoc : window (default = 12, or see above)
#       in:                     $locutSegLoc
#       in:                     $hicutSegloc
#       in:                     $optSegLoc : any of the following as a comma separated list:
#                                            x,c,m,l,h,a,n,o,t,p,q
#                                            default: -x 
#       in:                     $fhSbrErr  : file handle for error messages
#       out:                    1|0,msg   implicit: fileOutLoc
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."segRun";$fhinLoc="FHIN_"."segRun";$fhoutLoc="FHIN_"."segRun";
    
				# ------------------------------
				# defaults
    $exeSegDef=          "/nfs/data5/users/ppuser/server/pub/molbio/bin/seg".".".$ARCH;
    $modeSegDef=         "glob";
    $winSegGlobDef=    30;
    $locutGlobDef=      3.5;
    $hicutGlobDef=      3.75;

    $winSegNormDef=    12;
    $locutNormDef=      2.2;
    $hicutNormDef=      2.5;


    $optSegDef=          "x";
				# ------------------------------
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
    return(&errSbr("not def fileOutLoc!"))         if (! defined $fileOutLoc);
    return(&errSbr("not def exeSegLoc!"))          if (! defined $exeSegLoc);
    return(&errSbr("not def cmdSegLoc!"))          if (! defined $cmdSegLoc);
    return(&errSbr("not def modeSegLoc!"))         if (! defined $modeSegLoc);
    return(&errSbr("not def winSegLoc!"))          if (! defined $winSegLoc);
    return(&errSbr("not def locutSegLoc!"))        if (! defined $locutSegLoc);
    return(&errSbr("not def hicutSegLoc!"))        if (! defined $hicutSegLoc);
    return(&errSbr("not def optSegLoc!"))          if (! defined $optSegLoc);
    return(&errSbr("not def fhSbrErr!"))           if (! defined $fhSbrErr);
#    return(&errSbr("not def !"))          if (! defined $);

    return(&errSbr("miss in file '$fileInLoc'!"))  if (! -e $fileInLoc);
				# ------------------------------
				# adjust input
    $modeSegLoc="glob"          if ($modeSegLoc =~ /^glob/i);
    $modeSegLoc="norm"          if ($modeSegLoc =~ /^norm/i);
    $modeSegLoc=$modeSegDef     if (! $modeSegLoc);
    $winSegLoc= $winSegGlobDef  if (! $winSegLoc   && $modeSegLoc eq "glob"); 
    $locutSegLoc=$locutGlobDef  if (! $locutSegLoc && $modeSegLoc eq "glob"); 
    $hicutSegLoc=$hicutGlobDef  if (! $hicutSegLoc && $modeSegLoc eq "glob"); 

    $winSegLoc= $winSegNormDef  if (! $winSegLoc   && $modeSegLoc eq "norm"); 
    $locutSegLoc=$locutNormDef  if (! $locutSegLoc && $modeSegLoc eq "norm"); 
    $hicutSegLoc=$hicutNormDef  if (! $hicutSegLoc && $modeSegLoc eq "norm"); 

    $optSegLoc= $optSegDef      if (! $optSegLoc);

    $fhSbrErr="STDOUT"          if (! defined $fhSbrErr   || ! $fhSbrErr);
    $cmdSys="";			# avoid warnings

    $exeSegLoc=$exeSegDef       if (! $exeSegLoc);
    return(&errSbr("miss exe '$exeSegLoc'!"))     if (! -e $exeSegLoc && ! -l $exeSegLoc);
    return(&errSbr("not executable:$exeSegLoc!")) if (! -x $exeSegLoc);

                                # ------------------------------
                                # security erase
    unlink($fileOutLoc)         if (-e $fileOutLoc);

				# ------------------------------
				# build up input
    $cmd= $exeSegLoc." ".$fileInLoc;
    if (! $cmdSegLoc) {
	@optSegLoc=split(/,/,$optSegLoc);
	$cmd.=" ".$winSegLoc;
	$cmd.=" ".$locutSegLoc      if ($locutSegLoc);
	$cmd.=" ".$hicutSegLoc      if ($hicutSegLoc);
	foreach $tmp (@optSegLoc) {
	    $cmd.=" -".$tmp; } }
    else {
	$cmd.=" ".$cmdSegLoc;}
    $cmd.=" >> $fileOutLoc"     if ($fileOutLoc); # otherwise to STDOUT !

				# ------------------------------
				# run SEG
    eval "\$cmdSys=\"$cmd\"";
#    print "xx cmd=$cmd\n";


    ($Lok,$msg)=
	&sysRunProg($cmdSys,0,$fhSbrErr);
    return(&errSbrMsg("failed to run SEG on ($fileInLoc)",$msg)) 
	if (! $Lok || ($fileOutLoc && ! -e $fileOutLoc));
    return(1,"ok $sbrName");
}				# end of segRun

#===============================================================================
sub sequenceAlign {
    local(@seqLoc) = @_ ;
    local($sbrName,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   sequenceAlign               supposed to find corresponding residues
#                   ASSUMPTION: differ only by
#                               - begin / end of sequence
#                               - chain break symbols '!'
#                               - insertions '.'
#                               - 
#                               
#                               
#       in:                     @seqLoc=($seq1,$seq2)
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."sequenceAlign";
    
    undef %loc;

				# length
    $lenLoc[1]=$loc{"1","nres"}=length($seqLoc[1]);
    $lenLoc[2]=$loc{"2","nres"}=length($seqLoc[2]);

				# ------------------------------
				# (1) are identical
    if ($seqLoc[1] eq $seqLoc[2]){
	foreach $it (1..$lenLoc[1]){
	    $loc{"1",$it}=$it;
	    $loc{"2",$it}=$it; }
				# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
	$#seqLoc=0;		# slim-is-in
	return(1,"ok");		# problem solved
				# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    }

				# ------------------------------
				# purge chain breaks or '.'
    if ($seqLoc[1] =~ /[!\.]/ || $seqLoc[2] =~ /[!\.]/){
	$seqTmp[1]=$seqLoc[1];
	$seqTmp[2]=$seqLoc[2];
	$seqTmp[1]=~s/[!\.]//g;
	$seqTmp[2]=~s/[!\.]//g; }
    else {
	$seqTmp[1]=$seqLoc[1];
	$seqTmp[2]=$seqLoc[2];}
				# start with shorter one
    $posShorter=1; $posLonger= 2;
    if ($lenLoc[1] > $lenLoc[2]){
	$posShorter=2; $posLonger=1;}

				# ------------------------------
				# (2) identical without '.' '!'
    if ($seqTmp[1] eq $seqTmp[2] =~ /$seqTmp[$posLonger]/){
				# (2a) 1-> 2
	$del1=$del2=0;
	foreach $it (1..length($seqTmp[1])){
	    $it1=$it+$del1;
	    $it2=$it+$del2;
	    last if ($it1 > $lenLoc[1]);
	    last if ($it2 > $lenLoc[2]);
				# break in 1: count up
	    while ($it1 < $lenLoc[1] && substr($seqLoc[1],$it1,1) =~ /[!\.]/){
		++$del1; ++$it1; }
				# break in 2: count up
	    while ($it2 < $lenLoc[2] && substr($seqLoc[2],$it2,1) =~ /[!\.]/){
		++$del2; ++$it2; }
				# ERROR
	    return(0,"ERROR $sbrName(2a): residues for it=$it do not match!\n".
		   "  seqTmp1=$seqTmp[1]\n".
		   "  seqTmp2=$seqTmp[2]\n".
		   "  it1=$it1, it2=$it2, it=$it, del1=$del1, del2=$del2\n") 
		if (substr($seqLoc[1],$it1,1) ne substr($seqLoc[2],$it2,1));
	    $loc{"1",$it1}=$it2;
	}
				# (2b) 2-> 1
	$del1=$del2=0;
	foreach $it (1..length($seqTmp[2])){
	    $it1=$it+$del1;
	    $it2=$it+$del2;
	    last if ($it1 > $lenLoc[1]);
	    last if ($it2 > $lenLoc[2]);
				# break in 1: count up
	    while ($it1 < $lenLoc[1] && substr($seqLoc[1],$it1,1) =~ /[!\.]/){
		++$del1; ++$it1; }
				# break in 2: count up
	    while ($it2 < $lenLoc[2] && substr($seqLoc[2],$it2,1) =~ /[!\.]/){
		++$del2; ++$it2; }
				# ERROR
	    return(0,"*** ERROR $sbrName(2b): residues for it=$it do not match!\n".
		   "  seq1tmp=$seqTmp[1]\n".
		   "  seq2tmp=$seqTmp[2]\n".
		   "  it1=$it1, it2=$it2, it=$it, del1=$del1, del2=$del2\n") 
		if (substr($seqLoc[1],$it1,1) ne substr($seqLoc[2],$it2,1));
	    $loc{"2",$it2}=$it1;
	}
				# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
	$#seqTmp=$#seqLoc=0;	# slim-is-in
	return(1,"ok");		# problem solved
				# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    }
				# --------------------------------------------------
				# (3) still differ: find fragment!
				# 
				# reduce word length scanned in intervals of 10
				#       starting from lenghtShorter - 10
    $max=int($lenLoc[$posShorter]/10);
#     print "xx shorter=$lenLoc[$posShorter], $posShorter\n";
#     print "xx longer =$lenLoc[$posLonger], $posLonger\n";
    foreach $itreduce (0 .. $max){
	$wordLenLoc=$lenLoc[$posShorter]-10*$itreduce;
	$it=1; $match=$itmatch=0;
#	print "xx itreduce=$itreduce, wordlne=$wordLenLoc,\n";

	while (($it+$wordLenLoc-1) <= $lenLoc[$posShorter]){
	    $match=substr($seqTmp[$posShorter],$it,$wordLenLoc);
				# (3a)  DOES match -> expand from here
	    if ($seqTmp[$posLonger] =~ /$match/){
		$itmatch=$it;
		$ittmp=  0;
				#       expand ONE at a time BEFORE
		while ($ittmp > 0 && $match =~ /$seqTmp[$posLonger]/) {
		    $match=substr($seqTmp[$posShorter],($itmatch-$ittmp),1).$match;
		    ++$ittmp;}
		$itmatch=$itmatch-$ittmp;
		$ittmp=  0;
				#       expand ONE at a time AFTER
		$itmax=$lenLoc[$posShorter]-$wordLenLoc;
		while ($ittmp < $itmax && $match =~ /$seqTmp[$posLonger]/) {
		    $match=$match.substr($seqTmp[$posShorter],($itmatch-$ittmp),1);
		    ++$ittmp;}
		$itmatch=$itmatch+$ittmp;
		last;		# finish if one was found!
	    }
				# count up by ONE, since it did NOT match
#	    print "xx 1:$seqTmp[$posShorter]\n";
#	    print "xx 2:$seqTmp[$posLonger]\n";
#	    print "xx m:$match\n";
#	    print "xx does NOT match for $it \n";
	    $match=0;
	    ++$it; 
	}
				# found match
	last if ($match);
    }				# end of loop over word length intervals
				# --------------------------------------------------

				# ******************************
				# ERROR never found one
    return(0,"*** ERROR $sbrName: never found a match!\n".
	   "  seq1tmp=$seqTmp[1]\n".
	   "  seq2tmp=$seqTmp[2]\n".
	   "  seq1 in=$seqLoc[1]\n".
	   "  seq2 in=$seqLoc[2]\n")
	if (! $match);
				# ok: fill in
#     print "xx found a match at residue=$itmatch, length=",length($match),"\n";
#     print "xx match is=$match\n";
#     print "xx     1 is=$seqLoc[1]\n";
#     print "xx     2 is=$seqLoc[2]\n";

				# find out where that match is in 1
    $tmp=$seqTmp[1]; 
    $tmp=~s/^(.*)($match)/$2/;
    if (defined $1){
	$begLoc[1]=length($1);} else {$begLoc[1]=0;}
    $tmp=~s/($match)(.*)$/$1/;
    if (defined $2){
	$endLoc[1]=length($2);} else {$endLoc[1]=0;}
				# find out where that match is in 2
    $tmp=$seqTmp[2]; 
    $tmp=~s/^(.*)($match)/$2/;
    if (defined $1){
	$begLoc[2]=length($1);} else {$begLoc[2]=0;}
    $tmp=~s/($match)(.*)$/$1/;
    if (defined $2){
	$endLoc[2]=length($2);} else {$endLoc[2]=0;}

#    print "xx 1=$begLoc[1]-$endLoc[1], 2=$begLoc[2]-$endLoc[2]\n";

				# (3a) 1-> 2
    $del1=$del2=0; 
    $it1=1;
    $it2=1+$begLoc[2]; 
    while ($it1 <= $lenLoc[1]){
				# skip all to ignore before
	if ($it1 <= $begLoc[1]){
	    ++$it1;
	    next; }
				# finish if end
	last if ($it1 > ($lenLoc[1] - $endLoc[1]) );
	last if ($it2 > ($lenLoc[2] - $endLoc[2]) );
				# break in 1: count up
	while ($it1 < ($lenLoc[1] - $endLoc[1]) &&
	       substr($seqLoc[1],$it1,1) =~ /[!\.]/){
	    ++$it1; }
				# break in 2: count up
	while ($it2 < ($lenLoc[2] - $endLoc[2]) &&
	       substr($seqLoc[2],$it2,1) =~ /[!\.]/){
	    ++$it2; }
				# ERROR
	return(0,"ERROR $sbrName(3a): residues for it=$it do not match!\n".
	       "  seqTmp1=$seqTmp[1]\n".
	       "  seqTmp2=$seqTmp[2]\n".
	       " it1=$it1, it2=$it2, it=$it, del1=$del1, del2=$del2\n") 
	    if (substr($seqLoc[1],$it1,1) ne substr($seqLoc[2],$it2,1));
	$loc{"1",$it1}=$it2;
	++$it1; ++$it2;
    }
				# (3b) 2-> 1
    $del1=$del2=0; 
    $it1=1+$begLoc[1]; 
    $it2=1;
    while ($it2 <= $lenLoc[2]){
				# skip all to ignore before
	if ($it2 <= $begLoc[2]){
	    ++$it2;
	    next; }
				# finish if end
	last if ($it1 > ($lenLoc[1] - $endLoc[1]) );
	last if ($it2 > ($lenLoc[2] - $endLoc[2]) );
				# break in 1: count up
	while ($it1 < ($lenLoc[1] - $endLoc[1]) &&
	       substr($seqLoc[1],$it1,1) =~ /[!\.]/){
	    ++$it1; }
				# break in 2: count up
	while ($it2 < ($lenLoc[2] - $endLoc[2]) &&
	       substr($seqLoc[2],$it2,1) =~ /[!\.]/){
	    ++$it2; }
				# ERROR
	return(0,"ERROR $sbrName(3b): residues for it=$it do not match!\n".
	       "  seqTmp1=$seqTmp[1]\n".
	       "  seqTmp2=$seqTmp[2]\n".
	       " it1=$it1, it2=$it2, it=$it, del1=$del1, del2=$del2\n") 
	    if (substr($seqLoc[1],$it1,1) ne substr($seqLoc[2],$it2,1));
	$loc{"2",$it2}=$it1;
	++$it1; ++$it2;
    }

    $match="";
    $#seqTmp=$#seqLoc=0;	# slim-is-in
    return(1,"ok");
}				# end of sequenceAlign

#===============================================================================
sub strideCheck {
    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   strideCheck                   check whether or not STRIDE ok
#       in:                     $fileInLoc:    STRIDE file
#       out:                    1|0,msg,$Lok=1(if file ok) | 0 (if not)
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."strideCheck";
    $fhinLoc="FHIN_"."strideCheck";
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
    return(&errSbr("no fileIn=$fileInLoc!"))       if (! -e $fileInLoc && 
						       ! -l $fileInLoc );
    return(1,"ok",0)            if (-z $fileInLoc);
    return(1,"ok $sbrName",1);

				# ------------------------------
				# check STRIDE file
    $Lok=0;
    open($fhinLoc,$fileInLoc) ||
	return(0,"*** ERROR $sbrName: fileIn=$fileInLoc, not opened\n",0);
    $len=0;
    while (<$fhinLoc>) {
	if ($_ =~ /^\s*(\d+).*NUMBER OF RESIDUES/){
	    $len=$1;
	    last; }
    }
    close($fhinLoc);

    return(1,"ok $sbrName",$len);
}				# end of strideCheck

#===============================================================================
sub strideRun {
    local($fileInLoc,$fileOutLoc,$exeStrideLoc,$optNiceLoc) = @_ ;
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   strideRun                     run STRIDE
#       in:                     $fileInLoc:    PDB input file
#       in:                     $fileOutLoc:   STRIDE output file
#       in:                     exeStrideLoc:    STRIDE binary
#       in:                     optNiceLoc:    nice value (nice -19)
#       in:                     
#       in:                     
#       out:                    1|0,msg,$Lok=1(if file ok) | 0 (if not)
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."strideRun";
    $fhinLoc="FHIN_"."strideRun";$fhoutLoc="FHOUT_"."strideRun";
				# check arguments
    return(&errSbr("not def fileInLoc!"))          if (! defined $fileInLoc);
    return(&errSbr("not def fileOutLoc!"))         if (! defined $fileOutLoc);
    return(&errSbr("not def exeStrideLoc!"))         if (! defined $exeStrideLoc);
    $optNiceLoc=""                                 if (! defined $optNiceLoc ||
						       $optNiceLoc =~ /nice\S/);
#    return(&errSbr("not def !"))          if (! defined $);

    return(&errSbr("no fileIn=$fileInLoc!"))       if (! -e $fileInLoc && 
						       ! -l $fileInLoc );

				# local settings
    $exeStrideDef="/home/rost/molbio/bin/stride.SGI64";
    $exeStrideLoc=$exeStrideDef if (! -e $exeStrideLoc && ! -l $exeStrideLoc);

				# ------------------------------
				# missing executable
    return(&errSbr("no exeStrideLoc=$exeStrideLoc!"))       
	if (! -e $exeStrideLoc && ! -l $exeStrideLoc);

    $fileOutScreenLoc=0         if (! defined $fileOutScreenLoc);
    $fileOutScreenLoc=
	$par{"fileOutScreen"}   if (! $fileOutScreenLoc && defined $par{"fileOutScreen"});
    $FHTRACE="STDOUT"           if (! defined $FHTRACE);

    $cmd=$optNiceLoc." ".$exeStrideLoc." ".$fileInLoc." >> ".$fileOutLoc;
    ($Lok,$msg)=
	&sysRunProg($cmd,$fileOutScreenLoc,
		    $FHTRACE);  return(&errSbrMsg("failed on system '$cmd'",$msg)) if (! $Lok);

    return(0,"*** ERROR $sbrName: missing $fileOutLoc (from $fileInLoc)")
	if (! -e $fileOutLoc);

    return(1,"ok $sbrName");
}				# end of strideRun

1;
